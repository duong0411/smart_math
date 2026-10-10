import numpy as np
import cv2
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision
from typing import Tuple, Optional, Any, List
from database import CacheData

class InferenceError(Exception):
    pass

class MediaPipeFaceDetector:
    def __init__(self, model_path: str):
        base_options = python.BaseOptions(model_asset_path=model_path)
        options = vision.FaceLandmarkerOptions(
            base_options=base_options,
            output_face_blendshapes=False,
            output_facial_transformation_matrixes=False,
            num_faces=10)
        self.detector = vision.FaceLandmarker.create_from_options(options)

    def detect(self, image: np.ndarray) -> List[dict]:
        rgb_image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb_image)
        
        detection_result = self.detector.detect(mp_image)
        faces = []
        
        if detection_result.face_landmarks:
            for landmarks in detection_result.face_landmarks:
                x_min = min([lm.x for lm in landmarks]) * image.shape[1]
                y_min = min([lm.y for lm in landmarks]) * image.shape[0]
                x_max = max([lm.x for lm in landmarks]) * image.shape[1]
                y_max = max([lm.y for lm in landmarks]) * image.shape[0]
                
                faces.append({
                    "bbox": [int(x_min), int(y_min), int(x_max), int(y_max)],
                    "landmarks": landmarks
                })
        return faces

class VisionPipeline:
    def __init__(self, detector: Any, session: Any):
        self.detector = detector
        self.session = session
        
    def preprocess(self, image: np.ndarray, face_info: dict) -> np.ndarray:
        bbox = face_info.get("bbox")
        if bbox and len(bbox) == 4:
            x_min, y_min, x_max, y_max = bbox
            pad_x = int((x_max - x_min) * 0.1)
            pad_y = int((y_max - y_min) * 0.1)
            
            x1 = max(0, x_min - pad_x)
            y1 = max(0, y_min - pad_y)
            x2 = min(image.shape[1], x_max + pad_x)
            y2 = min(image.shape[0], y_max + pad_y)
            
            cropped = image[y1:y2, x1:x2]
            if cropped.size == 0:
                cropped = image
        else:
            cropped = image
            
        resized = cv2.resize(cropped, (112, 112))
        rgb_resized = cv2.cvtColor(resized, cv2.COLOR_BGR2RGB)
        
        tensor = rgb_resized.astype(np.float32)
        tensor = (tensor - 127.5) / 128.0
        tensor = np.transpose(tensor, (2, 0, 1))
        tensor = np.expand_dims(tensor, axis=0)
        return tensor
        
    def extract_embedding(self, tensor: np.ndarray) -> np.ndarray:
        try:
            inputs = {self.session.get_inputs()[0].name: tensor}
            outputs = self.session.run(None, inputs)
            embedding = outputs[0][0]
            
            norm = np.linalg.norm(embedding)
            if norm > 0:
                embedding = embedding / norm
                
            return embedding
        except Exception as e:
            raise InferenceError(f"ONNX Inference failed: {e}")

    def process_enrollment(self, image: np.ndarray) -> np.ndarray:
        faces = self.detector.detect(image)
        if not faces:
            raise InferenceError("No face detected")
            
        face = faces[0]
        tensor = self.preprocess(image, face)
        return self.extract_embedding(tensor)

class FaceMatcher:
    def __init__(self, threshold: float = 0.6):
        self.threshold = threshold
        
    def match(self, embedding: np.ndarray, cache: CacheData) -> Tuple[Optional[int], float]:
        if len(cache.vectors) == 0:
            return None, 0.0
            
        scores = np.dot(cache.vectors, embedding)
        best_idx = np.argmax(scores)
        max_score = scores[best_idx]
        
        if max_score >= self.threshold:
            return int(cache.person_ids[best_idx]), float(max_score)
        
        return None, float(max_score)
