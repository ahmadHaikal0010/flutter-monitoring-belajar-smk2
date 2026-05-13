# Panduan Pengembangan Project (GEMINI.md)

Dokumen ini berisi standar dan prinsip yang harus dipatuhi dalam pengembangan project **Monitoring Belajar SMK**.

## 1. Komunikasi & Bahasa
- **Bahasa:** Seluruh komunikasi, pesan error, label UI, dan dokumentasi harus menggunakan **Bahasa Indonesia**.
- **Tone:** Formal, natural, profesional, dan siap produksi (*ready-to-production*). Hindari bahasa yang terlalu kaku seperti robot, namun tetap sopan dan jelas.
- **Istilah Teknis:** Gunakan istilah teknis yang umum (misal: "Login", "Dashboard", "Logout") jika dirasa lebih natural daripada terjemahan bakunya.

## 2. Prinsip Desain (Modern Clean Design)
- **Visual:** Minimalis, bersih, dengan ruang putih (*white space*) yang cukup agar tidak terlihat sesak.
- **Warna:** Gunakan palet warna modern (misal: *Soft Blue*, *Slate Grey*, *Pure White*). Hindari warna yang terlalu kontras/norak.
- **Tipografi:** Gunakan font yang bersih (misal: Poppins atau Inter). Perhatikan *font weight* untuk membedakan hirarki informasi.
- **Komponen:**
    - Gunakan *rounded corners* (sudut membulat) pada card dan button (minimal 12-16px).
    - Berikan *subtle shadow* (bayangan tipis) untuk memberikan kesan kedalaman.
    - Gunakan ikon yang konsisten (misal: Lucide Icons atau Feather Icons jika memungkinkan, atau Material Symbols yang minimalis).

## 3. Standar Kode Flutter
- **Arsitektur:** Gunakan struktur folder berbasis layer (`core`, `data`, `logic`, `presentation`).
- **State Management:** Prioritaskan penggunaan **Provider** atau **Riverpod**.
- **Widget:**
    - Selalu gunakan `const` pada widget statis.
    - Pisahkan widget besar menjadi komponen-komponen kecil yang dapat digunakan kembali (*reusable components*).
- **Performa:** Hindari penggunaan widget yang terlalu berat di dalam list yang panjang tanpa optimasi.

## 4. Integrasi Backend (Laravel)
- **Query Builder:** Diperbolehkan untuk efisiensi, namun pastikan hasil yang dikembalikan ke API tetap konsisten.
- **Auth:** Gunakan Laravel Sanctum. Selalu sertakan `device_name` yang dinamis dari sisi mobile.
- **Error Handling:** Flutter harus menangkap dan menampilkan pesan error asli dari backend sesuai format yang ditentukan di `app.php`.

## 5. Alur Kerja Git
- **Commit Message:** Jelas dan deskriptif dalam Bahasa Indonesia atau Inggris (konsisten).
- **Branching:** Gunakan branch fitur jika mengerjakan fitur besar.
