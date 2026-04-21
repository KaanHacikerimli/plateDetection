import os
import re
import cv2
import numpy as np
import matplotlib.pyplot as plt
from ultralytics import YOLO
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing.image import ImageDataGenerator

# ============================
#  CONFIG
# ============================
OCR_MODEL_PATH = "new_character_model.h5"
YOLO_MODEL_PATH = r"C:\Users\kaanh\PycharmProjects\TrPlateswithTrain\runs\detect\train\weights\best.pt"
DATA_PATH = r'C:\Users\kaanh\PycharmProjects\SonCNN\Datasets'
TEST_IMAGE_PATHS = [
    # Cıvata sorunu olan fotoğraf ('01 FE 101')

    # TR logosu sorunu olan fotoğraf ('35 SS 224')
    r'C:\Users\kaanh\PycharmProjects\TrPlateswithTrain\adana5q.png',
]

# Regex
PLATE_REGEX = re.compile(r'^\s*\d{2}\s*[A-ZİĞÜŞÖÇ]{1,3}\s*\d{2,4}\s*$', re.IGNORECASE)


# ============================
#  UTIL (Aynı)
# ============================
def display(img_, title=''):
    img = cv2.cvtColor(img_, cv2.COLOR_BGR2RGB);
    plt.figure(figsize=(10, 6));
    plt.imshow(img);
    plt.axis('off');
    plt.title(title);
    plt.show(block=True)


def validate_plate_format(s: str) -> bool:
    s2 = s.replace('-', '').replace('_', '').replace(' ', '').upper();
    return bool(PLATE_REGEX.match(s2))


# ============================
#  YOLO DETECTION (Aynı)
# ============================
def yolo_detect_largest(img, yolo_model, conf=0.15, iou=0.45):
    results = yolo_model(img, verbose=False, conf=conf, iou=iou)
    plate_img = img.copy();
    plate_roi = None;
    largest_area = -1;
    best_coords = None
    for r in results:
        boxes = r.boxes
        if not boxes: continue
        for b in boxes:
            xy = b.xyxy[0].cpu().numpy();
            x1, y1, x2, y2 = xy.astype(int)
            area = max(0, (x2 - 1)) * max(0, (y2 - y1))
            if area > largest_area: largest_area = area; best_coords = (x1, y1, x2, y2)
    if largest_area > 0 and best_coords is not None:
        x1, y1, x2, y2 = best_coords;
        pad = 10;
        h, w, _ = img.shape
        x1_pad, y1_pad = max(0, x1 - pad), max(0, y1 - pad);
        x2_pad, y2_pad = min(w, x2 + pad), min(h, y2 + pad)
        plate_roi = img[y1_pad:y2_pad, x1_pad:x2_pad];
        bbox_original_coords = (x1, y1, x2, y2)
        cv2.rectangle(plate_img, (x1, y1), (x2, y2), (0, 255, 0), 2)
        return plate_img, plate_roi, bbox_original_coords
    return plate_img, None, None


# ============================
#  PERSPEKTİF DÜZELTME (Aynı)
# ============================
def order_points(pts):
    rect = np.zeros((4, 2), dtype="float32");
    s = pts.sum(axis=1)
    rect[0] = pts[np.argmin(s)];
    rect[2] = pts[np.argmax(s)]
    diff = np.diff(pts, axis=1);
    rect[1] = pts[np.argmin(diff)];
    rect[3] = pts[np.argmax(diff)]
    return rect


def find_corners_and_dewarp(plate_roi, target_width=333, target_height=75, debug_show=False):
    if plate_roi is None: return None
    try:
        gray_roi = cv2.cvtColor(plate_roi, cv2.COLOR_BGR2GRAY);
        blurred = cv2.GaussianBlur(gray_roi, (5, 5), 0)
        edges = cv2.Canny(blurred, 50, 150)
        if debug_show: display(edges, "Dewarping için Canny Kenarları")
        contours, _ = cv2.findContours(edges, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        if not contours: print("Dewarping (Canny): Kontur bulunamadı."); return None
        cnt = sorted(contours, key=cv2.contourArea, reverse=True)[0];
        rect = cv2.minAreaRect(cnt)
        box = cv2.boxPoints(rect);
        box = np.intp(box);
        src_points = order_points(box.astype("float32"))
        dst_points = np.array(
            [[0, 0], [target_width - 1, 0], [target_width - 1, target_height - 1], [0, target_height - 1]],
            dtype="float32")
        M = cv2.getPerspectiveTransform(src_points, dst_points);
        dewarped = cv2.warpPerspective(plate_roi, M, (target_width, target_height))
        return dewarped
    except Exception as e:
        print(f"Hata (Dewarping): {e}"); return None


# ============================
#  SEGMENTATION (HİBRİT SÜRÜM - Median Blur Eklendi)
# ============================

# clean_binary fonksiyonu artık kullanılmıyor

def extract_char_candidates(binary, min_w, max_w, min_h, max_h, max_chars=10):
    """
    Konturları bulur, FİLTRELER (boyut + GEVŞEK en-boy oranı) ve sıralar.
    Cıvataları ve TR logolarını bilerek içeri alır.
    """
    contours, _ = cv2.findContours(binary.copy(), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    candidates = [];
    for c in contours:
        x, y, w, h = cv2.boundingRect(c);
        area = w * h
        if w == 0: continue
        aspect_ratio = float(h) / w
        # GEVŞEK FİLTRE: 0.8 ile 15.0 arasındaki her şeyi al.
        if (min_w < w < max_w and min_h < h < max_h and 80 < area < 20000 and 0.8 < aspect_ratio < 15.0):
            candidates.append((x, y, w, h))
    if not candidates: return []
    candidates = sorted(candidates, key=lambda b: b[0])
    if len(candidates) > max_chars:
        candidates = sorted(candidates, key=lambda b: b[2] * b[3], reverse=True)[:max_chars]
        candidates = sorted(candidates, key=lambda b: b[0])
    return candidates


def normalize_char_image(char_img):
    """Eski, (ama modelin beklediği) 44x24 tuval yöntemine geri dönüldü."""
    try:
        resized = cv2.resize(char_img, (20, 40))
    except Exception:
        resized = np.zeros((40, 20), dtype=np.uint8)
    canvas = np.zeros((44, 24), dtype=np.uint8);
    canvas[2:42, 2:22] = resized
    return canvas


# ---
# DÜZELTİLMİŞ FONKSİYON: segment_plate_chars (Median Blur Eklendi)
# ---
def segment_plate_chars(plate_img, debug_show=False):
    """
    Segmentasyon ana fonksiyonu.
    Eşikleme öncesi Median Blur kullanır. clean_binary kaldırıldı.
    """
    if plate_img is None: print("Segmentasyon için boş plaka görüntüsü."); return []

    try:
        img_lp = cv2.resize(plate_img, (333, 75))
    except Exception as e:
        print(f"Segmentasyon resize hatası: {e}"); return []

    gray = cv2.cvtColor(img_lp, cv2.COLOR_BGR2GRAY)

    # --- YENİ ADIM: Median Blur ---
    # Tuz-biber gürültüsünü azaltmak için eşiklemeden ÖNCE uygula
    # Kernel boyutu (ksize) tek sayı olmalı (örn: 3 veya 5)
    gray_blurred = cv2.medianBlur(gray, 3)
    # --- Bitiş: Yeni Adım ---

    # Gaussian Blur hala isteğe bağlı olarak eklenebilir ama median sonrası gerekmeyebilir
    # blur = cv2.GaussianBlur(gray_blurred, (5, 5), 0)

    # Median Blur uygulanmış görüntü üzerinden eşikleme yap
    binary = cv2.adaptiveThreshold(gray_blurred, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
                                   cv2.THRESH_BINARY_INV, 21, 9)

    # --- clean_binary ÇAĞRISI KALDIRILDI ---
    # binary = clean_binary(binary)

    # Sadece kenarları temizle
    H, W = binary.shape
    binary[:4, :] = 0;
    binary[-4:, :] = 0
    binary[:, :4] = 0;
    binary[:, -4:] = 0

    if debug_show: display(cv2.cvtColor(binary, cv2.COLOR_GRAY2BGR), "Binarized Plaka (Median Blur Sonrası)")

    # Boyut filtrelerini önceki gibi gevşek tutalım
    dims = (W / 35, W / 5, H / 3.5, H * 1.1)
    min_w, max_w, min_h, max_h = dims[0], dims[1], dims[2], dims[3]

    candidates = extract_char_candidates(binary, min_w, max_w, min_h, max_h, max_chars=10)

    if not candidates:
        if debug_show: print("Segmentasyon aday karakter bulamadı.")
        return []

    chars = []
    for (x, y, w, h) in candidates:
        ch = binary[y:y + h, x:x + w];
        ch_norm = normalize_char_image(ch);
        chars.append(ch_norm)
    return chars


# --- Bitiş: Düzeltilmiş segment_plate_chars ---


# ============================
#  OCR (HİBRİT SÜRÜM - Aynı)
# ============================
def predict_plate_from_chars(char_images, ocr_model, idx_to_label_map):
    # (Kod öncekiyle aynı, değişiklik yok)
    if not char_images: return '', 0.0, []
    confs = [];
    labels = []
    for ch in char_images:
        img_in = cv2.resize(ch, (28, 28))
        img_in = np.expand_dims(img_in, axis=-1) if img_in.ndim == 2 else img_in
        if img_in.shape[-1] == 1: img_in = np.concatenate([img_in] * 3, axis=-1)
        img_in = img_in.astype('float32') / 255.0;
        img_in = img_in.reshape(1, 28, 28, 3)
        probs = ocr_model.predict(img_in, verbose=0)[0]
        top_idx = int(np.argmax(probs));
        top_conf = float(probs[top_idx])
        label = idx_to_label_map.get(top_idx, '?');
        labels.append(label);
        confs.append(top_conf)
    plate_str = ''.join(labels);
    avg_conf = float(np.mean(confs)) if confs else 0.0
    return plate_str, avg_conf, confs


# ============================
#  ANA SÜREÇ (NİHAİ SÜRÜM - KURAL TABANLI TEMİZLEME - Aynı)
# ============================
def is_valid_city_code(code_str):
    """Verilen string'in '01' ile '81' arasında bir sayı olup olmadığını kontrol eder."""
    return code_str.isdigit() and 1 <= int(code_str) <= 81


def process_image_strict(image_path, yolo_model, ocr_model, idx_to_label_map, debug=False):
    print(f"\n--- Processing: {os.path.basename(image_path)} ---")
    img = cv2.imread(image_path)
    if img is None: print("ERROR: image not read."); return None

    # 1) YOLO
    detected_img, plate_roi, bbox = yolo_detect_largest(img, yolo_model, conf=0.15, iou=0.45)
    if plate_roi is None: print("YOLO did not detect plate."); display(img, "No plate detected by YOLO"); return None
    if debug: display(plate_roi, "YOLO ROI (Eğik ve Dolgulu)")

    # 2) Dewarp
    dewarped_plate = find_corners_and_dewarp(plate_roi, debug_show=debug)
    if dewarped_plate is None:
        print("Uyarı: Dewarping başarısız oldu. Eğik görüntü kullanılıyor.")
        segment_image = plate_roi
    else:
        print("Başarılı: Plaka düzleştirildi.")
        segment_image = dewarped_plate
        if debug: display(dewarped_plate, "Düzleştirilmiş Plaka (Dewarped)")

    # 3) Segment (MEDIAN BLUR ile)
    chars = segment_plate_chars(segment_image, debug_show=debug)
    if not chars:
        if dewarped_plate is not None:
            print("Düzleştirilmiş görüntüde segmentasyon başarısız. Orijinal ROI'yi deniyor...")
            chars = segment_plate_chars(plate_roi, debug_show=debug)  # Fallback
            if not chars: print("Orijinal ROI'de de segmentasyon başarısız."); display(plate_roi,
                                                                                       "Segmentation failed on final attempt"); return None
        else:
            print("Segmentation failed."); display(plate_roi, "Segmentation failed"); return None

    # 4) OCR
    plate_text, avg_conf, confs = predict_plate_from_chars(chars, ocr_model, idx_to_label_map)

    # Kopyalarını sakla
    original_plate_text = plate_text
    original_chars = list(chars)
    original_confs = list(confs)

    # Çalışma kopyaları oluştur
    current_plate_text = plate_text
    current_confs = list(confs)
    current_chars = list(chars)

    # ---
    # ADIM 5: KURAL TABANLI TEMİZLEME (Güven Odaklı Şehir Kodu + Uzunluk/Güven)
    # ---
    CITY_CODE_CONF_THRESHOLD = 0.60
    CONF_THRESHOLD_NOISE = 0.50
    accepted_lengths = [7, 8, 9]

    # Kural 1: Şehir Kodu Kontrolü (Güven Odaklı)
    city_code_corrected = False
    if len(current_plate_text) >= 3 and len(current_confs) >= 1:
        first_two = current_plate_text[:2];
        second_third = current_plate_text[1:3]
        first_char_conf = current_confs[0]
        condition1 = (not is_valid_city_code(first_two)) and is_valid_city_code(second_third)
        condition2 = (first_char_conf < CITY_CODE_CONF_THRESHOLD) and is_valid_city_code(second_third)
        if condition1 or condition2:
            print(
                f"Kural 1 (Şehir Kodu/Güven): İlk karakter ('{current_plate_text[0]}' conf={first_char_conf:.2f}) gürültü. Atılıyor.")
            current_plate_text = current_plate_text[1:];
            current_confs = current_confs[1:];
            current_chars = current_chars[1:]
            city_code_corrected = True

            # Kural 2: Uzunluk ve Güven Kontrolü (Sondaki Gürültüyü At)
    length_adjusted = False
    if len(current_plate_text) not in accepted_lengths:
        # Beklenenden UZUNSA
        if len(current_plate_text) > max(accepted_lengths) or \
                (len(current_plate_text) == 8 and validate_plate_format(current_plate_text[:-1])) or \
                (len(current_plate_text) == 9 and validate_plate_format(current_plate_text[:-1])):
            if len(current_confs) > 0 and current_confs[-1] < CONF_THRESHOLD_NOISE:
                print(
                    f"Kural 2 (Uzunluk/Güven): Plaka çok uzun ('{current_plate_text}') ve son karakter ('{current_plate_text[-1]}') güveni düşük ({current_confs[-1]:.2f}). Atılıyor.")
                current_plate_text = current_plate_text[:-1];
                current_confs = current_confs[:-1];
                current_chars = current_chars[:-1]
                length_adjusted = True
            elif len(current_confs) > 0:
                print(
                    f"Kural 2 (Uzunluk/Güven): Plaka çok uzun ('{current_plate_text}') ancak son karakterin güveni yüksek ({current_confs[-1]:.2f}). Atılmadı.")

    # Nihai sonuçları al
    plate_text = current_plate_text;
    confs = current_confs;
    chars = current_chars
    avg_conf = float(np.mean(confs)) if confs else 0.0

    if city_code_corrected or length_adjusted:
        print(f"Kural Tabanlı Temizleme Sonrası: '{original_plate_text}' -> '{plate_text}'")
    else:
        print("Kural Tabanlı Temizleme: Değişiklik yapılmadı.")

    # --- Bitiş: Adım 5 ---

    # 6) Validate
    valid = validate_plate_format(plate_text)

    # Orijinale Geri Dönüş Mantığı
    if not valid and validate_plate_format(original_plate_text):
        print(f"Temizleme formatı bozdu veya yetersiz karakter bıraktı, orijinala dön: '{original_plate_text}'")
        plate_text = original_plate_text;
        chars = original_chars;
        confs = original_confs
        avg_conf = float(np.mean(confs)) if confs else 0.0;
        valid = True

    status = "VALID" if valid else "UNVERIFIED"
    print(f"Result: '{plate_text}' | Status: {status} | AvgConf: {avg_conf:.3f}")

    # 7) Visualize
    final_img = img.copy();
    label_text = f"{plate_text} ({status}, conf={avg_conf:.2f})"
    if bbox:
        x1, y1, x2, y2 = bbox
        cv2.rectangle(final_img, (x1, y1), (x2, y2), (0, 255, 0), 2)
        cv2.putText(final_img, label_text, (x1, max(10, y1 - 12)), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 255, 0), 2)
    display(final_img, f"Result: {plate_text} | status={status} | avg_conf={avg_conf:.2f}")

    # Karakterleri göster
    plt.figure(figsize=(12, 2))
    for i, ch in enumerate(chars):
        if i >= len(plate_text) or i >= len(confs): break
        plt.subplot(1, len(chars), i + 1)
        plt.imshow(chars[i], cmap='gray')
        if i < len(plate_text) and i < len(confs):
            lbl = plate_text[i];
            conf = confs[i];
            plt.title(f"{lbl}\n{conf:.2f}")
        plt.axis('off')
    plt.suptitle(f"Plate: {plate_text} | AvgConf: {avg_conf:.2f} | Status: {status}")
    plt.show(block=True)

    return plate_text, avg_conf, status


# ============================
#  MAIN
# ============================
if __name__ == "__main__":
    if not os.path.exists(OCR_MODEL_PATH): raise FileNotFoundError(f"OCR modeli bulunamadı: {OCR_MODEL_PATH}")
    if not os.path.exists(YOLO_MODEL_PATH): raise FileNotFoundError(f"YOLO modeli bulunamadı: {YOLO_MODEL_PATH}")
    if not os.path.exists(os.path.join(DATA_PATH, 'train')): raise FileNotFoundError(
        f"Data path (train) eksik: {DATA_PATH}/train")

    print("Loading models...")
    ocr_model = load_model(OCR_MODEL_PATH);
    yolo_model = YOLO(YOLO_MODEL_PATH)
    print("Models loaded.")

    datagen = ImageDataGenerator(rescale=1. / 255)
    generator = datagen.flow_from_directory(
        os.path.join(DATA_PATH, 'train'),
        target_size=(28, 28), batch_size=1, class_mode='sparse', shuffle=False)
    class_indices = generator.class_indices;
    idx_to_label = {v: k for k, v in class_indices.items()}
    print(f"Loaded {len(idx_to_label)} classes.")

    for p in TEST_IMAGE_PATHS:
        if os.path.exists(p):
            result = process_image_strict(p, yolo_model, ocr_model, idx_to_label, debug=True)
            print("Final Result Tuple:", result)
        else:
            print(f"Test image not found: {p}")

    print("All done.")