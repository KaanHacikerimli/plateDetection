from ultralytics import YOLO
import torch


model = YOLO('yolov8n.pt')

if __name__ == '__main__':
    if torch.cuda.is_available():
        print("✅ GPU detected:", torch.cuda.get_device_name(0))
    else:
        print("❌ GPU not available, using CPU.")
    results = model.train(data='Datasets/data.yaml', epochs=100, imgsz=640, device='cuda')

    print("Eğitim tamamlandı! 'runs' klasörünü kontrol edin.")


