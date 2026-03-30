# plant_disease_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Model Entegrasyonu

Uygulama artık gerçek model sonucunu almak için bir HTTP tahmin servisine bağlanır:

- Varsayılan Android emulator adresi: `http://10.0.2.2:8000`
- Varsayılan iOS/macOS adresi: `http://127.0.0.1:8000`

İsterseniz endpoint'i `--dart-define=MODEL_API_URL=<adres>` ile değiştirebilirsiniz.

Backend tarafında örnek servis dosyası proje kökünde:

- `inference_api.py`
- `requirements_inference.txt`
