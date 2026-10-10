import threading
import time
import os
import cv2
import numpy as np
from fastapi import FastAPI, UploadFile, File, Form, Depends, HTTPException, WebSocket, Response, Request
from fastapi.responses import StreamingResponse
from contextlib import asynccontextmanager
import onnxruntime as ort
import asyncio
import json
import base64

from database import FaceDatabase
from frame_buffer import FrameBuffer
from vision_pipeline import VisionPipeline, MediaPipeFaceDetector, FaceMatcher

class AppState:
    latest_frame = np.zeros((480, 640, 3), dtype=np.uint8)
    latest_event = {"engine_status": "ok"}
    ws_clients = []
    frame_lock = threading.Lock()

def get_db(request: Request):
    return request.app.state.db

def get_pipeline(request: Request):
    return request.app.state.pipeline

def ai_worker_loop(app: FastAPI):
    buffer = app.state.buffer
    pipeline = app.state.pipeline
    db = app.state.db
    matcher = FaceMatcher(threshold=0.6)
    
    while True:
        frame_data = buffer.get(timeout=1.0)
        if frame_data is None:
            if buffer._stopped:
                break
            continue
            
        frame = frame_data["frame"]
        cache = db.load_cache()
        
        try:
            if pipeline:
                faces = pipeline.detector.detect(frame)
                if faces:
                    face = faces[0]
                    tensor = pipeline.preprocess(frame, face)
                    embedding = pipeline.extract_embedding(tensor)
                    person_id, score = matcher.match(embedding, cache)
                    
                    name = "Unknown"
                    if person_id is not None:
                        person = db.get_person(person_id)
                        if person:
                            name = person.name
                            
                    event = {
                        "bbox": face["bbox"],
                        "name": name,
                        "score": score,
                        "engine_status": "ok"
                    }
                else:
                    event = {"engine_status": "ok", "message": "No face detected"}
            else:
                event = {"engine_status": "error", "message": "Pipeline not initialized"}
        except Exception as e:
            event = {"engine_status": "error", "message": str(e)}
            
        # Thêm ảnh base64 vào event để gửi qua websocket
        ret, jpg_buffer = cv2.imencode('.jpg', frame, [int(cv2.IMWRITE_JPEG_QUALITY), 60])
        if ret:
            event["frame"] = base64.b64encode(jpg_buffer).decode('utf-8')

        AppState.latest_event = event
        
        with AppState.frame_lock:
            AppState.latest_frame = frame.copy()

def camera_reader_loop(app: FastAPI):
    buffer = app.state.buffer
    cap = cv2.VideoCapture(0)
    
    while not buffer._stopped:
        ret, frame = cap.read()
        if not ret:
            time.sleep(0.1)
            continue
        
        buffer.put({"frame": frame, "timestamp": time.time()})
        with AppState.frame_lock:
            AppState.latest_frame = frame.copy()
            
    cap.release()

@asynccontextmanager
async def lifespan(app: FastAPI):
    db_path = os.path.join(os.path.dirname(__file__), "data.db")
    app.state.db = FaceDatabase(db_path)
    
    mp_task_path = os.path.join(os.path.dirname(__file__), "..", "assets", "mediapipe", "face_landmarker.task")
    onnx_path = os.path.join(os.path.dirname(__file__), "..", "models", "face_embedding_int8.onnx")
    
    try:
        if os.path.exists(mp_task_path) and os.path.exists(onnx_path):
            detector = MediaPipeFaceDetector(mp_task_path)
            # Try to use OpenVINO provider, fallback to CPU
            providers = ['OpenVINOExecutionProvider', 'CPUExecutionProvider']
            session = ort.InferenceSession(onnx_path, providers=providers)
            app.state.pipeline = VisionPipeline(detector=detector, session=session)
        else:
            print("Warning: Models not found, running without AI inference.")
            app.state.pipeline = None
    except Exception as e:
        print(f"Warning: Could not load models: {e}")
        app.state.pipeline = None

    app.state.buffer = FrameBuffer(capacity=3, sample_interval=5)
    
    app.state.camera_thread = threading.Thread(target=camera_reader_loop, args=(app,), daemon=True)
    app.state.camera_thread.start()
    
    app.state.worker_thread = threading.Thread(target=ai_worker_loop, args=(app,), daemon=True)
    app.state.worker_thread.start()
    
    yield
    
    app.state.buffer.stop()
    app.state.camera_thread.join(timeout=2.0)
    app.state.worker_thread.join(timeout=2.0)
    app.state.db.close()

app = FastAPI(lifespan=lifespan)

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/persons")
def get_persons(db = Depends(get_db)):
    with db._get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT id, name FROM persons")
        rows = cursor.fetchall()
        return [{"id": row["id"], "name": row["name"]} for row in rows]

@app.post("/enroll")
async def enroll_person(
    name: str = Form(...), 
    file: UploadFile = File(...),
    db = Depends(get_db),
    pipeline = Depends(get_pipeline)
):
    contents = await file.read()
    nparr = np.frombuffer(contents, np.uint8)
    image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    
    if image is None:
        raise HTTPException(status_code=400, detail="Invalid image")
        
    if not pipeline:
        raise HTTPException(status_code=500, detail="Pipeline not available")

    try:
        embedding = pipeline.process_enrollment(image)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
        
    try:
        with db._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("INSERT INTO persons (name) VALUES (?)", (name,))
            person_id = cursor.lastrowid
            
            blob = embedding.tobytes()
            cursor.execute("INSERT INTO embeddings (person_id, vector) VALUES (?, ?)", (person_id, blob))
            conn.commit()
            
        return {"id": person_id, "name": name}
    except Exception as e:
        raise HTTPException(status_code=500, detail="Database error")

@app.delete("/persons/{person_id}")
def delete_person(person_id: int, db = Depends(get_db)):
    db.delete_person(person_id)
    return {"status": "deleted"}

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    AppState.ws_clients.append(websocket)
    try:
        while True:
            await websocket.send_json(AppState.latest_event)
            await asyncio.sleep(0.1)
    except:
        pass
    finally:
        if websocket in AppState.ws_clients:
            AppState.ws_clients.remove(websocket)

def generate_mjpeg():
    while True:
        with AppState.frame_lock:
            frame = AppState.latest_frame
        
        if frame is not None:
            ret, buffer = cv2.imencode('.jpg', frame)
            if ret:
                frame_bytes = buffer.tobytes()
                yield (b'--frame\r\n'
                       b'Content-Type: image/jpeg\r\n\r\n' + frame_bytes + b'\r\n')
        time.sleep(0.05)

@app.get("/preview")
def get_preview():
    return StreamingResponse(generate_mjpeg(), media_type="multipart/x-mixed-replace; boundary=frame")
