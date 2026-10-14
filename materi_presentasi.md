# Materi Presentasi: TechTalk AI Harness (Knowledge Base Q&A)

> **Tentang Dokumen Ini:** Dokumen ini merupakan ringkasan komprehensif dari materi presentasi TechTalk Engineering: *"AI Harness — Menghubungkan Kecerdasan Model AI ke Lingkungan Kerja Nyata"*. Berkas ini menjadi acuan utama bagi AI Copilot untuk memberikan contekan jawaban langsung saat audiens bertanya.

---

## 1. Judul, Topik, dan Pesan Utama
- **Judul Presentasi:** TechTalk Engineering: AI Harness — Menghubungkan Kecerdasan Model AI ke Lingkungan Kerja Nyata.
- **Pesan Inti:** 
  - Model AI (LLM) hanyalah **"Otak"** (The Brain) yang memproses teks & penalaran di cloud.
  - AI Harness adalah **"Tubuh"** (The Body) di komputer lokal yang menghubungkan otak AI dengan file, terminal, compiler, dan lingkungan kerja nyata.
  - Eksperimen membuktikan: **1 Model yang sama + 1 Tugas yang sama, jika dijalankan di 3 AI Harness berbeda, akan menghasilkan arsitektur kode dan waktu eksekusi yang sangat berbeda.**
  - **Rumus Sinergi:** Otak Cerdas + Tubuh (Harness) yang Tepat = Hasil Terbaik sesuai fase kerja tim.

---

## 2. Rincian Poin per Slide Presentasi

### Slide 1 — Cover & Pengantar
- **Topik:** Context Management, AI Harness, Tools API.
- **Misi:** Menjelaskan jembatan antara kecerdasan LLM di cloud dengan komputer lokal developer.

### Slide 2 — Konsep Fundamental: Anatomi AI Harness
- **Di Cloud (Model AI / Otak):**
  - Menerima instruksi & data project.
  - Mengolah logika & merencanakan tindakan.
  - Mengembalikan jawaban atau instruksi pemanggilan fungsi (*tool call*).
- **Di Komputer Lokal (AI Harness / Tubuh):**
  1. **01. System Prompt & Rules:** Arahan peran, persona, gaya koding, batasan aksi, dan aturan arsitektur yang disuntikkan sebelum prompt dikirim.
  2. **02. Tools (Akses Komputer):** Fungsi nyata untuk membaca & menulis file, mengedit kode per baris, dan mengeksekusi shell/terminal.
  3. **03. Context Manager:** Memindai dan memilih file paling relevan di project agar tidak melebihi batas token (*token budget*) model.
  4. **04. Execution Loop:** Menentukan alur kerja agen—apakah sekali ketik langsung jadi (*single-pass*), atau wajib melewati loop verifikasi error compiler & linter dulu.

### Slide 3 & 4 — Eksperimen: 1 Model + 1 Tugas di 3 Aplikasi
- **The Brain (Identik):** Gemini 3.7 Flash High (Google DeepMind), dengan level reasoning dan token budget yang persis sama.
- **The Blueprint (Tugas Identik):** `INVOICE_STUDIO_MACOS.MD`
  - Membangun aplikasi web interaktif *InvoiceStudio for Mac*.
  - UI bertema Apple Desktop: Traffic lights header, Frosted glass (blur), segmented controls, Apple blue `#007AFF`.
  - Fitur: Live split-screen, kalkulasi PPN 11%, diskon, print A4 clean tanpa elemen UI Mac, sample data generator.
- **The Variable (3 AI Harness Berbeda):**
  1. **ZCode:** Direct buffer streaming.
  2. **OpenCode:** Terminal tool-runner.
  3. **Antigravity:** Agentic planning IDE.

### Slide 5 — Hasil ZCode ADE
- **Waktu Eksekusi:** **1 menit 31 detik (1:31)** — Paling Cepat.
- **Output File:**
  - `index.html` (48.9 KB): Form & canvas dokumen terpadu.
  - `app.js` (45.5 KB): State management & logika hitungan.
  - `styles.css` (6.3 KB, 263 baris): Styling fungsional dan rapi.
- **Mengapa Hasilnya Seperti Ini?**
  - Memakai *goal-oriented autonomous loop*, agen fokus menuntaskan tugas secepat mungkin.
  - Filosofi *zero-dependency*, langsung render di browser tanpa perlu `npm install` atau build step.

### Slide 6 — Hasil OpenCode Desktop
- **Waktu Eksekusi:** **3 menit 33 detik (3:33)** — Menengah.
- **Output File:**
  - `index.html` (61.8 KB): Markup lengkap struktur window macOS.
  - `app.js` (58.8 KB): Interaktivitas & kalkulasi invoice.
  - `style.css` (47.4 KB, **2.334 baris CSS vanilla**!): Implementasi styling detail luar biasa.
- **Mengapa Hasilnya Seperti Ini?**
  - Menggunakan *tool-calling loop* dengan engine Go di terminal.
  - Agen memiliki ruang eksplorasi lebih luas untuk merombak UI macOS secara detail dan visual.

### Slide 7 — Hasil Antigravity
- **Waktu Eksekusi:** **5 menit 02 detik (5:02)** — Paling Komprehensif & Tertib.
- **Struktur Project yang Dihasilkan:**
  - Stack modern: React 19, TypeScript 5.7, Vite 6.2, Tailwind CSS 3.4.
  - `/specs`: Berisi artefak rencana & spesifikasi arsitektur.
  - `/types`: Kontrak tipe data ketat (*strict types*).
  - 8+ Komponen modular terpisah (`Header`, `Form`, `ItemList`, `TaxSelector`, dll.).
- **Mengapa Hasilnya Seperti Ini?**
  - Mengikuti *Planning Lifecycle*: **Plan → Spec → Scaffold → Implement → Verify**.
  - Menerapkan *static type checking* & pengujian build sebelum menyatakan selesai.

### Slide 8 — Spektrum "Default Approach" (Kecepatan vs Ketertiban)
- **ZCode ADE (1:31):**
  - *Pendekatan:* Goal-oriented autonomous loop + live preview instan.
  - *Keunggulan:* Sangat cepat, tanpa setup dependensi, langsung jalan.
  - *Use Case Ideal:* Prototyping cepat, hackathon, dan eksplorasi ide baru.
- **OpenCode (3:33):**
  - *Pendekatan:* Iterative tool-calling di lingkungan terminal.
  - *Keunggulan:* Fleksibel merancang styling web/CSS native secara detail.
  - *Use Case Ideal:* UI bespoke, visual crafting, dan manipulasi file bertahap.
- **Antigravity (5:02):**
  - *Pendekatan:* Multi-phase planning, type contract, build verify.
  - *Keunggulan:* Modular, aman dengan TypeScript, siap CI/CD produksi.
  - *Use Case Ideal:* Fitur besar, sistem jangka panjang, dan codebase tim enterprise.

### Slide 9 — 4 Pilar di Balik AI Harness
1. **01. Action Space (Ruang Aksi):** Alat yang diberikan ke model—apakah *macro-tool* (menulis file utuh sekali jadi) atau *micro-tool* (edit per baris, eksekusi terminal, compile build).
2. **02. Observation & Feedback Loop:** Apa yang dilihat AI setelah bertindak. Log error compiler & linter memicu siklus perbaikan mandiri (*self-correction*) sampai kode bersih.
3. **03. Context & Memory Management:** Cara memindai codebase—apakah hanya tab aktif, atau memetakan seluruh hierarki arsitektur dengan tetap menjaga budget token.
4. **04. Execution Lifecycle & Rules:** Alur kontrol software—apakah *single-pass streaming* (sekali tulis selesai), atau *multi-phase* (Perencanaan → Spesifikasi → Koding → Verifikasi).

### Slide 10 — Otak + Tubuh = Hasil Terbaik (Kesimpulan)
- **Brain (Model AI):** Penggerak kecerdasan, pemahaman sintaks & logika (contoh: Gemini 3.7 Flash).
- **Body (AI Harness):** Jembatan eksekusi dunia nyata—menentukan kecepatan, eksplorasi, dan struktur arsitektur akhir.
- **Sinergi:** Pilih harness sesuai kebutuhan fase kerja:
  - *Cepat (ZCode)*: untuk validasi ide & prototyping.
  - *Luwes (OpenCode)*: untuk kustomisasi UI bespoke.
  - *Rapi & Kuat (Antigravity)*: untuk codebase tim enterprise siap skala besar.

---

## 3. Antisipasi Pertanyaan Audiens (FAQ Q&A Cheat-Sheet)

- **Q1: Kenapa Antigravity membutuhkan waktu paling lama (5 menit) dibandingkan ZCode (1.5 menit)?**
  - *Jawaban:* Karena Antigravity tidak langsung menulis kode sembarangan. Antigravity memiliki fase perencanaan (*planning lifecycle*): menyusun dokumen arsitektur, mendefinisikan interface TypeScript, men-setup struktur React 19 modular, dan memverifikasi build (`npm run build`) untuk memastikan tidak ada error tipe data. Waktu lebih lama ini menghasilkan kode yang siap dipakai di level enterprise.

- **Q2: Apakah prompt yang sama akan selalu menghasilkan output yang sama jika model AI-nya sama?**
  - *Jawaban:* Tidak. Eksperimen ini adalah bukti nyata bahwa dengan model yang 100% sama (Gemini 3.7 Flash High) dan spesifikasi prompt yang identik, output kodenya sangat berbeda. ZCode menghasilkan vanilla HTML/JS single-file, OpenCode menghasilkan 2.300 baris CSS detail, dan Antigravity menghasilkan project React/TypeScript modular. Bentuk akhir software sangat ditentukan oleh Harness tempat model itu bekerja.

- **Q3: Kapan kita sebaiknya memilih ZCode, OpenCode, atau Antigravity?**
  - *Jawaban:* 
    - Pilih **ZCode** saat butuh validasi cepat, demo ke stakeholder dalam hitungan menit, atau eksplorasi ide awal.
    - Pilih **OpenCode** saat fokus pada perombakan visual/CSS custom dan ingin kontrol langsung lewat terminal.
    - Pilih **Antigravity** saat membangun fitur produksi tim, codebase besar yang butuh standar typing ketat, dan integrasi pipeline CI/CD.

- **Q4: Apa yang dimaksud dengan 'Action Space' dalam konteks AI Harness?**
  - *Jawaban:* Action Space adalah kumpulan fungsi atau wewenang nyata yang diberikan sistem kepada model AI untuk berinteraksi dengan komputer developer. Contohnya: kemampuan membaca file, mengedit potongan baris kode (bukan menulis ulang seluruh file), menjalankan tes unit, atau mengecek status git.

- **Q5: Bagaimana AI Harness mengelola token agar tidak boros atau terkena limit (Context Management)?**
  - *Jawaban:* Harness menggunakan teknik seleksi cerdas: hanya mengirim file-file yang relevan dengan tugas saat ini (misalnya file yang di-import atau sedang diedit), memadatkan ringkasan simbol/fungsi, dan tidak membombardir model dengan seluruh isi folder project secara membabi buta.
