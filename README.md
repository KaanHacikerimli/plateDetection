# 🚗 AutoPlate: Automated License Plate Recognition System

AutoPlate, araç plakalarını gerçek zamanlı olarak tespit etmek ve karakterlerini tanımak için geliştirilmiş, **Flutter** ve **Python** tabanlı bir tam kapsamlı (full-stack) mobil uygulamadır.

## 🌟 Öne Çıkan Özellikler
* **Gerçek Zamanlı Tespit:** YOLOv8 mimarisi kullanılarak yüksek doğrulukla plaka konumlandırma.
* **Karakter Tanıma (OCR):** Tespit edilen plakaların özel eğitimli CNN (Convolutional Neural Networks) modelleri ile metne dönüştürülmesi.
* **Hızlı Bildirimler:** SendGrid API entegrasyonu ile plaka verilerinin anlık olarak e-posta ile iletilmesi.
* **Konum Servisleri:** Flutter `geolocator` kullanarak aracın konum bilgisini Google Maps bağlantısı olarak paylaşma.
* **Modern Arayüz:** Kullanıcı dostu ve hızlı bir Flutter mobil deneyimi.

## 🛠️ Teknoloji Yığını
| Alan | Kullanılan Teknolojiler |
| :--- | :--- |
| **Mobil** | Flutter, Dart |
| **Backend** | Python (Flask/FastAPI) |
| **Yapay Zeka** | YOLOv8 (Detection), CNN (OCR), OpenCV |
| **Veri İşleme** | NumPy, Pandas |
| **Servisler** | SendGrid API, Google Maps URL Scheme |

## 🏗️ Proje Mimarisi
Proje, görüntü ön işleme aşamasından bildirim aşamasına kadar optimize edilmiş bir boru hattı (pipeline) izler:
1.  **Görüntü Girişi:** Mobil uygulama üzerinden alınan kamera görüntüsü.
2.  **Ön İşleme:** `engine.py` üzerinden görüntü iyileştirme ve normalizasyon.
3.  **Tespit:** YOLOv8 modeli ile plaka bölgesinin kırpılması.
4.  **Tanıma:** Kırpılan bölgedeki karakterlerin CNN modeli ile okunması.
5.  **Aksiyon:** Tespit edilen plaka ve konum bilgilerinin ilgili birimlere gönderilmesi.

## 🚀 Kurulum
Projeyi yerelinizde çalıştırmak için:

1.  Depoyu klonlayın:
    ```bash
    git clone [https://github.com/KaanHacikerimli/plateDetection.git](https://github.com/KaanHacikerimli/plateDetection.git)
    ```
2.  Bağımlılıkları yükleyin:
    ```bash
    flutter pub get
    ```
3.  Uygulamayı çalıştırın:
    ```bash
    flutter run
    ```

## 📈 Gelecek Geliştirmeler
- [ ] Çoklu plaka desteğinin artırılması.
- [ ] Gece görüşü ve düşük ışık koşulları için model optimizasyonu.
- [ ] Geçmiş kayıtların tutulacağı bir Firebase entegrasyonu.

---
👤 **Kaan Hacıkelimli**
* Software Engineering Student
