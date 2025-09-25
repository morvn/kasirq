# kasirq



```md
# Kasirq

Kasirq adalah aplikasi kasir berbasis **Flutter** yang dirancang untuk membantu usaha kecil maupun menengah dalam mengelola transaksi penjualan, menu, laporan, dan struk secara digital.

## ✨ Fitur Utama

- Manajemen menu dan harga  
- Keranjang belanja (cart) dengan update jumlah item  
- Pencatatan pesanan dan checkout  
- Cetak/preview struk  
- Laporan harian  
- Tema dan pengaturan dasar  

## 📂 Struktur Proyek

```.
lib/
├── core/              # Koneksi database / helper
├── data/              # Model data (menu, order, cart)
├── providers/         # State management (Provider)
├── presentation/      # UI (pages, widgets, services)
└── main.dart          # Entry point aplikasi
```.

## 🚀 Getting Started

### Prasyarat

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Dart](https://dart.dev/get-dart)
- Editor seperti [VS Code](https://code.visualstudio.com/) atau Android Studio

```
### Instalasi

1. Clone repository:
   ```bash
   git clone https://github.com/morvn/kasirq.git
   cd kasirq
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Jalankan aplikasi di emulator atau perangkat:
   ```bash
   flutter run
   ```

## 📖 Dokumentasi

Beberapa referensi untuk membantu pengembangan:

- [Flutter Docs](https://docs.flutter.dev/)
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)
- [Provider State Management](https://pub.dev/packages/provider)

## 📝 Status

Proyek ini masih dalam tahap pengembangan awal.
