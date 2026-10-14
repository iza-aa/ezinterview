# ezinterview

Live Presentation and Interview Q&A Assistant with Stealth Floating HUD for macOS.

ezinterview adalah asisten cerdas untuk presentasi live dan wawancara (Zoom, Google Meet, dll.) di macOS. Dirancang khusus agar presenter atau kandidat dapat merekam audio penanya, mentranskripsikannya secara lokal via Whisper, dan melihat contekan jawaban secara instan di layar melayang (Floating Chat) yang aman dari tangkapan Zoom Share Screen.

---

## Fitur Utama dan Keamanan

1. Anti-Bocor Share Screen (`window.sharingType = .none`)
   - Jendela floating chat menerapkan proteksi native macOS.
   - Bahkan jika Anda membuka contekan jawaban di tengah layar saat share screen di Zoom, audiens hanya melihat aplikasi presentasi atau browser Anda, bukan jendela contekan ini.

2. Always on Top (`window.level = .floating`)
   - Jendela contekan selalu berada di atas aplikasi lain di layar sehingga dapat dilirik tanpa perlu alt-tab.

3. Transkripsi Suara Cepat (Speech to Text)
   - Rekaman audio 16kHz WAV diproses secara lokal menggunakan whisper-cpp (Metal GPU accelerated) tanpa perlu dependensi cloud.
   - Dapat diintegrasikan dengan Gemini API jika menginginkan sintesis AI lebih mendalam.

4. Floating HUD Fleksibel
   - Mode Ringkas: Menghemat ruang layar saat sesi berlangsung.
   - Mode Melebar: Menampilkan poin-poin jawaban yang padat begitu pertanyaan selesai diproses.

---

## Struktur File

- `FloatingChatApp.swift`: Source code antarmuka overlay floating HUD macOS.
- `AudioRecorder.swift`: Perekam audio native macOS (Linear PCM 16kHz mono WAV).
- `bridge.py`: Service backend pengelola STT lokal dan pencocokan materi.
- `download_model.sh`: Skrip pengunduh model whisper ggml-base.bin.
- `materi_presentasi.md`: Dokumen catatan materi, FAQ, dan konteks presentasi.
- `answer.txt`: Output jawaban aktif yang terbaca oleh widget floating HUD.
- `start.sh`: Skrip untuk menjalankan antarmuka dan bridge service.
- `stop.sh`: Skrip untuk menghentikan seluruh service.
- `build.sh`: Skrip kompilasi Swift native binary.

---

## Prasyarat

- macOS (Apple Silicon direkomendasikan)
- Swift / Xcode Command Line Tools (`xcode-select --install`)
- Python 3
- whisper-cpp (opsional via Homebrew: `brew install whisper-cpp`)

---

## Cara Menjalankan

### 1. Siapkan Materi
Edit file `materi_presentasi.md` dan masukkan materi presentasi, FAQ wawancara, atau konteks yang dibutuhkan.

### 2. Unduh Model Whisper
```bash
./download_model.sh
```

### 3. Kompilasi dan Jalankan
```bash
./start.sh
```
Widget melayang akan muncul di layar.

### 4. Menghentikan Aplikasi
```bash
./stop.sh
```
