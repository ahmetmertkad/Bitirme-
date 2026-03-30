from io import BytesIO
from typing import Dict, Union
import os
import uuid

import cv2
import numpy as np
import timm
import torch
import torch.nn.functional as F
import torchvision.transforms as transforms
from fastapi import FastAPI, File, HTTPException, UploadFile
from PIL import Image, ImageOps, UnidentifiedImageError

# SAM 2.1 importları
from sam2.build_sam import build_sam2
from sam2.sam2_image_predictor import SAM2ImagePredictor

app = FastAPI(title="Plant Disease Inference API")

DEVICE = "mps" if torch.backends.mps.is_available() else "cpu"
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, "best_plant_model_efficientnet_b3.pth")

# SAM 2.1 Checkpoint ve Config dosyaları
SAM2_CHECKPOINT = os.path.join(BASE_DIR, "sam2.1_hiera_large.pt")  # yerel pt dosyan
SAM2_MODEL_CFG = "configs/sam2.1/sam2.1_hiera_l.yaml"  # SAM-2 paketinin içindeki cfg
SAM_DEBUG_DIR = os.path.join(BASE_DIR, "sam_debug_outputs")

CLASS_NAMES = [
    'Apple___Apple_scab',
    'Apple___Black_rot',
    'Apple___Cedar_apple_rust',
    'Apple___healthy',
    'Cherry_(including_sour)___Powdery_mildew',
    'Cherry_(including_sour)___healthy',
    'Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot',
    'Corn_(maize)___Common_rust_',
    'Corn_(maize)___Northern_Leaf_Blight',
    'Corn_(maize)___healthy',
    'Grape___Black_rot',
    'Grape___Esca_(Black_Measles)',
    'Grape___Leaf_blight_(Isariopsis_Leaf_Spot)',
    'Grape___healthy',
    'Peach___Bacterial_spot',
    'Peach___healthy',
    'Pepper,_bell___Bacterial_spot',
    'Pepper,_bell___healthy',
    'Potato___Early_blight',
    'Potato___Late_blight',
    'Potato___healthy',
    'Strawberry___Leaf_scorch',
    'Strawberry___healthy',
    'Tomato___Bacterial_spot',
    'Tomato___Early_blight',
    'Tomato___Late_blight',
    'Tomato___Leaf_Mold',
    'Tomato___Septoria_leaf_spot',
    'Tomato___Spider_mites Two-spotted_spider_mite',
    'Tomato___Target_Spot',
    'Tomato___Tomato_Yellow_Leaf_Curl_Virus',
    'Tomato___Tomato_mosaic_virus',
    'Tomato___healthy',
]

MODEL = timm.create_model("efficientnet_b3", pretrained=False, num_classes=len(CLASS_NAMES))
MODEL.load_state_dict(torch.load(MODEL_PATH, map_location=DEVICE))
MODEL.to(DEVICE)
MODEL.eval()

# SAM 2.1 Model Yükleme
print(f"SAM 2.1 modeli yükleniyor ({DEVICE})...")
SAM2_MODEL = build_sam2(SAM2_MODEL_CFG, SAM2_CHECKPOINT, device=DEVICE)
SAM_PREDICTOR = SAM2ImagePredictor(SAM2_MODEL)
print("SAM 2.1 modeli yüklendi.")

PREPROCESS = transforms.Compose(
    [
        transforms.Resize((300, 300)),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
    ]
)

def _parse_label(raw_label: str) -> tuple[str, str]:
    if "___" not in raw_label:
        return "Unknown", raw_label.replace("_", " ").strip()

    plant_type, disease = raw_label.split("___", maxsplit=1)
    plant_type_clean = plant_type.replace("_", " ").strip()
    disease_clean = disease.replace("_", " ").strip()
    return plant_type_clean, disease_clean


def _segment_leaf_with_sam(image_array: np.ndarray) -> Union[np.ndarray, None]:
    """
    SAM 2.1 kullanarak yaprağı segmente eder ve en büyük bileşeni döndürür.
    Başarısız olursa None döndürür.
    """
    try:
        h, w = image_array.shape[:2]
        img_rgb = cv2.cvtColor(image_array, cv2.COLOR_BGR2RGB) if len(image_array.shape) == 3 else image_array

        SAM_PREDICTOR.set_image(img_rgb)

        # --- 1. DEĞİŞİKLİK: 5 Noktalı (Artı Şeklinde) Prompt Stratejisi ---
        cx, cy = w // 2, h // 2
        offset = min(w, h) // 10  # Görüntünün kısa kenarının %10'u kadar bir sapma mesafesi

        # Merkeze ve etrafına artı (+) şeklinde toplam 5 nokta atıyoruz.
        # Bu sayede hastalık lezyonları (kahverengi/sarı) ve sağlam doku (yeşil) tek bir nesne olarak algılanır.
        input_point = np.array([
            [cx, cy],                 # Merkez
            [cx + offset, cy],        # Sağ
            [cx - offset, cy],        # Sol
            [cx, cy + offset],        # Alt
            [cx, cy - offset]         # Üst
        ])
        
        # 5 noktanın da ana nesneye (yaprağa) ait olduğunu belirtiyoruz (1 = foreground)
        input_label = np.array([1, 1, 1, 1, 1])

        # --- 2. DEĞİŞİKLİK: Kutu (Box) Kaldırıldı ve 'scores' Uyarısı Çözüldü ---
        # Editördeki soluk/gri 'scores' yazısını düzeltmek için onu '_' ile değiştirdik.
        # Kutu mantığını tamamen sildik, SAM sınırları artık sadece bu 5 noktadan yola çıkarak kendisi bulacak.
        masks, _, _ = SAM_PREDICTOR.predict(
            point_coords=input_point,
            point_labels=input_label,
            multimask_output=False,
        )

        if masks.size == 0:
            return None

        binary_mask = masks[0].astype(np.uint8)

        # --- AŞAĞISI TAMAMEN SENİN YAZDIĞIN KUSURSUZ MANTIK (DOKUNULMADI) ---
        
        # Connected components - gürültü temizliği
        num_labels, labels, stats, centroids = cv2.connectedComponentsWithStats(binary_mask, connectivity=8)

        if num_labels > 1:
            areas = stats[1:, cv2.CC_STAT_AREA]
            largest_label = np.argmax(areas) + 1
            clean_binary_mask = np.zeros_like(binary_mask)
            clean_binary_mask[labels == largest_label] = 1
            binary_mask = clean_binary_mask

        # Siyah tuval + yaprak
        segmented_full = np.zeros_like(img_rgb, dtype=np.uint8)
        segmented_full[binary_mask == 1] = img_rgb[binary_mask == 1]

        # Bounding box + padding
        coords = np.column_stack(np.where(binary_mask > 0))
        if len(coords) > 0:
            y_min, x_min = coords.min(axis=0)
            y_max, x_max = coords.max(axis=0)
            pad = 20

            y_min = max(0, y_min - pad)
            x_min = max(0, x_min - pad)
            y_max = min(h, y_max + pad)
            x_max = min(w, x_max + pad)

            cropped = segmented_full[y_min:y_max, x_min:x_max]

            if cropped.size > 0 and cropped.shape[0] > 50 and cropped.shape[1] > 50:
                return cv2.cvtColor(cropped, cv2.COLOR_RGB2BGR)

        return None
    except Exception as e:
        print(f"SAM 2.1 segmentasyon hatası: {e}")
        return None


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "device": DEVICE}


@app.post("/predict")
async def predict(image: UploadFile = File(...)) -> Dict[str, Union[float, str]]:
    try:
        image_bytes = await image.read()
        if not image_bytes:
            raise HTTPException(status_code=400, detail="Yüklenen dosya boş.")

        # Görüntüyü NumPy array'e çevir (OpenCV için)
        pil_image = Image.open(BytesIO(image_bytes)).convert("RGB")
        img_cv = cv2.cvtColor(np.array(pil_image), cv2.COLOR_RGB2BGR)

        # SAM ile segmentasyon
        segmented_img = _segment_leaf_with_sam(img_cv)
        if segmented_img is None:
            # Fallback: orijinal görüntüyü kullan
            segmented_img = img_cv
            pil_image = Image.fromarray(cv2.cvtColor(segmented_img, cv2.COLOR_BGR2RGB))
        else:
            pil_image = Image.fromarray(cv2.cvtColor(segmented_img, cv2.COLOR_BGR2RGB))

            # Debug: SAM çıktı görüntüsünü diske kaydet
            try:
                os.makedirs(SAM_DEBUG_DIR, exist_ok=True)
                debug_filename = f"sam2_{uuid.uuid4().hex}.png"
                debug_path = os.path.join(SAM_DEBUG_DIR, debug_filename)
                pil_image.save(debug_path)
                print(f"SAM 2.1 debug görüntüsü kaydedildi: {debug_path}")
            except Exception as save_err:
                print(f"SAM 2.1 debug görüntüsü kaydedilemedi: {save_err}")

        # Padding ile kare yapma (run.py gibi)
        max_size = max(pil_image.size)
        pil_image = ImageOps.pad(pil_image, (max_size, max_size), color=(0, 0, 0))

        # Sınıflandırma
        input_tensor = PREPROCESS(pil_image).unsqueeze(0).to(DEVICE)

        with torch.no_grad():
            outputs = MODEL(input_tensor)
            probabilities = F.softmax(outputs[0], dim=0)

        # En iyi 3 tahmini konsola yazdır
        topk_vals, topk_indices = torch.topk(probabilities, k=3)
        print("Top-3 tahminler:")
        for rank, (p, cls_idx) in enumerate(zip(topk_vals.tolist(), topk_indices.tolist()), start=1):
            cls_name = CLASS_NAMES[cls_idx]
            print(f"  {rank}. {cls_name} -> {p * 100:.2f}%")

        # API cevabında hâlâ sadece en yüksek olasılığı döndürüyoruz
        confidence, idx = torch.max(probabilities, dim=0)
        raw_label = CLASS_NAMES[idx.item()]
        plant_type, disease = _parse_label(raw_label)

        return {
            "label": raw_label,
            "plant_type": plant_type,
            "disease": disease,
            "confidence": float(confidence.item()),
        }
    except UnidentifiedImageError as exc:
        raise HTTPException(status_code=400, detail="Yüklenen dosya bir görsel olmalı.") from exc
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Tahmin sırasında hata: {exc}") from exc