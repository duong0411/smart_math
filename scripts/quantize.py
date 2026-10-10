import os
from onnxruntime.quantization import quantize_dynamic, QuantType

def quantize_model():
    model_dir = os.path.join(os.path.dirname(__file__), "..", "models")
    model_input = os.path.join(model_dir, "face_embedding.onnx")
    model_output = os.path.join(model_dir, "face_embedding_int8.onnx")

    if not os.path.exists(model_input):
        print(f"Error: Could not find model at {model_input}")
        return

    print(f"Quantizing {model_input} to INT8...")
    
    quantize_dynamic(
        model_input=model_input,
        model_output=model_output,
        weight_type=QuantType.QInt8
    )
    
    print(f"Quantization complete! Saved to {model_output}")

if __name__ == "__main__":
    quantize_model()
