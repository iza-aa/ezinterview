#!/usr/bin/env python3
import os
import sys
import time
import json
import subprocess
import shutil
import re
import urllib.request

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
STATUS_FILE = os.path.join(BASE_DIR, "status.json")
ANSWER_FILE = os.path.join(BASE_DIR, "answer.txt")
MATERI_FILE = os.path.join(BASE_DIR, "materi_presentasi.md")
AUDIO_DIR = os.path.join(BASE_DIR, "audio")
MODEL_PATH = os.path.join(BASE_DIR, "models", "ggml-base.bin")

# Cari path binary whisper-cli
WHISPER_BIN = "/opt/homebrew/bin/whisper-cli"
if not os.path.exists(WHISPER_BIN):
    WHISPER_BIN = shutil.which("whisper-cli") or "whisper-cli"

def read_materi():
    if os.path.exists(MATERI_FILE):
        with open(MATERI_FILE, "r", encoding="utf-8") as f:
            return f.read()
    return ""

def update_answer(text, status="answered", question=""):
    with open(ANSWER_FILE, "w", encoding="utf-8") as f:
        f.write(text)
    
    if os.path.exists(STATUS_FILE):
        try:
            with open(STATUS_FILE, "r", encoding="utf-8") as f:
                data = json.load(f)
        except Exception:
            data = {}
        data["state"] = status
        data["answer"] = text
        if question:
            data["question"] = question
        data["timestamp"] = time.time()
        with open(STATUS_FILE, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)

def prepare_wav_audio(source_audio):
    """
    Memastikan audio dalam format 16kHz 16-bit Mono WAV untuk whisper-cpp.
    Menggunakan utilitas bawaan macOS 'afconvert' untuk konversi instan.
    """
    output_wav = os.path.join(AUDIO_DIR, "processed_question.wav")
    try:
        subprocess.run([
            "afconvert",
            "-f", "WAVE",
            "-d", "LEI16@16000",
            "-c", "1",
            source_audio,
            output_wav
        ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return output_wav
    except Exception as e:
        print(f"Peringatan konversi afconvert: {e}")
        return source_audio

def transcribe_local_whisper(audio_path):
    """
    Mentranskripsi suara ke teks Bahasa Indonesia secara 100% lokal
    menggunakan whisper-cli (Metal GPU accelerated).
    """
    wav_file = prepare_wav_audio(audio_path)
    if not os.path.exists(wav_file):
        return ""
    
    if not os.path.exists(MODEL_PATH):
        print(f"Error: Model Whisper tidak ditemukan di {MODEL_PATH}")
        return ""
    
    cmd = [
        WHISPER_BIN,
        "-m", MODEL_PATH,
        "-l", "id",
        "-f", wav_file,
        "--no-timestamps",
        "--no-prints"
    ]
    
    try:
        start_t = time.time()
        result = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            stdin=subprocess.DEVNULL,
            text=True,
            timeout=20
        )
        dur = time.time() - start_t
        print(f"Transkripsi Whisper selesai dalam {dur:.2f}s")
        
        # Ambil baris output dan bersihkan
        raw_output = result.stdout.strip()
        lines = [line.strip() for line in raw_output.split("\n") if line.strip()]
        
        # Filter baris log ggml jika ada
        valid_lines = [
            l for l in lines 
            if not l.startswith("load_backend:") and 
               not l.startswith("ggml_") and 
               not l.startswith("read_audio_data:")
        ]
        
        text = " ".join(valid_lines).strip()
        return text
    except Exception as e:
        print(f"Error saat menjalankan whisper-cli: {e}")
        return ""

def match_materi_locally(question_text, materi_text):
    """
    Mencocokkan pertanyaan audiens dengan materi slide secara cerdas
    berdasarkan bobot kemiripan kata kunci (keyword matching).
    """
    if not question_text:
        return "⚠️ Tidak ada suara pertanyaan yang terdeteksi (audio hening)."
    
    # Stopwords umum bahasa Indonesia
    stopwords = {
        "apa", "apakah", "bagaimana", "siapa", "mengapa", "kenapa", "berapa",
        "kapan", "dimana", "yang", "dan", "di", "ke", "dari", "ini", "itu",
        "untuk", "pada", "adalah", "bisa", "tolong", "halo", "alo", "ya",
        "saja", "soal", "tentang", "dong", "kami", "kita", "kamu", "anda",
        "saya", "dengan", "akan", "telah", "sudah", "jika", "kalau"
    }
    
    # Tokenisasi pertanyaan
    q_words = re.findall(r'\b[a-zA-Z0-9_\-\.%]+\b', question_text.lower())
    keywords = [w for w in q_words if w not in stopwords and len(w) > 2]
    
    # Pecah materi menjadi bagian-bagian berdasarkan header markdown (# atau ## atau ###)
    sections = []
    current_title = "Poin Umum"
    current_lines = []
    
    for line in materi_text.split("\n"):
        header_match = re.match(r'^(#{1,3})\s+(.+)', line)
        if header_match:
            if current_lines:
                sections.append((current_title, "\n".join(current_lines)))
                current_lines = []
            current_title = header_match.group(2).strip()
        else:
            current_lines.append(line)
            
    if current_lines:
        sections.append((current_title, "\n".join(current_lines)))
    
    # Hitung skor relevansi tiap bagian
    best_section = None
    best_score = -1
    
    for title, content in sections:
        combined = f"{title.lower()} {content.lower()}"
        score = 0
        for kw in keywords:
            # Poin ekstra jika kata kunci muncul di judul
            if kw in title.lower():
                score += 3
            # Poin jika kata kunci muncul di isi
            matches = len(re.findall(re.escape(kw), combined))
            score += matches
            
        if score > best_score:
            best_score = score
            best_section = (title, content)
            
    # Format naskah teleprompter instan (0.3s) agar pembicara bisa langsung mulai bicara
    answer_parts = [
        f"🎙️ [Pertanyaan]: \"{question_text}\"",
        "",
        "🗣️ BACA LANGSUNG KE AUDIENS:",
        "\"Baik, terima kasih atas pertanyaannya rekan-rekan sekalian."
    ]
    
    if best_section and best_score > 0:
        sec_title, sec_content = best_section
        bullets = [
            line.strip().lstrip("-•* ") for line in sec_content.split("\n") 
            if line.strip().startswith("-") or line.strip().startswith("•") or line.strip().startswith("*")
        ]
        if bullets:
            answer_parts.append(f"Mengenai hal tersebut, jika kita tinjau dari aspek {sec_title.lower()}:")
            for b in bullets[:3]:
                answer_parts.append(f"• {b}")
        else:
            cleaned_content = sec_content.strip().split("\n")[0][:200]
            answer_parts.append(f"Mengenai hal tersebut: {cleaned_content}")
    else:
        answer_parts.append("Pada dasarnya, hal tersebut berakar dari bagaimana AI Harness menjadi jembatan antara model AI cerdas dengan eksekusi nyata di komputer kita, baik dari segi kecepatan maupun kepatuhan arsitektur.")
        
    answer_parts.append("\n(Antigravity sedang menyempurnakan naskah lengkap...)\"")
    return "\n".join(answer_parts)

def call_gemini_api_text(api_key, question_text, materi_text):
    """
    Jika ada GEMINI_API_KEY, gunakan Gemini 2.5 Flash untuk menghasilkan
    contekan jawaban yang sangat natural dan ringkas berbasis teks.
    """
    prompt = f"""Kamu adalah asisten teleprompter presentasi TechTalk untuk seorang MAHASISWA TEKNIK / DEVELOPER MUDA.
Audiens Zoom baru saja mengajukan pertanyaan berikut:
"{question_text}"

Berikut adalah MATERI PRESENTASI pembicara:
---
{materi_text}
---

TUGAS SANGAT PENTING:
Tuliskan NASKAH JAWABAN KATA DEMI KATA yang BISA LANGSUNG DIBACA LISAN oleh pembicara ke audiens.
Pembicara adalah MAHASISWA yang sedang presentasi, jadi gayanya harus GAYA MAHASISWA:
- Santai, cerdas, tidak kaku, lugas, mengalir asik, dan percaya diri.
- Pakai bahasa percakapan yang natural dan akrab (misal: "Nah, pertanyaan bagus banget nih...", "Simpelnya gini temen-temen...", "Kalau kita bedah...", "Jadi intinya...").
- JANGAN pakai bahasa birokrat atau bahasa korporat yang kaku.
- Tetap akurat dengan data teknis di materi slide.
- Panjangnya pas: 3-4 kalimat berbobot yang selesai dibaca dalam 20 detik.

Format:
🎙️ [Pertanyaan]: "{question_text}"

🗣️ BACA LANGSUNG KE AUDIENS:
"... [Tulis naskah lisan gaya mahasiswa siap baca di sini] ..."
"""

    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={api_key}"
    payload = {
        "contents": [
            {
                "parts": [
                    {
                        "text": prompt
                    }
                ]
            }
        ]
    }
    
    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"}
    )
    
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            res_data = json.loads(resp.read().decode("utf-8"))
            answer = res_data["candidates"][0]["content"]["parts"][0]["text"]
            return answer
    except Exception as e:
        print(f"Fallback ke matcher lokal karena Gemini API error: {e}")
        return match_materi_locally(question_text, materi_text)

def main():
    print("=" * 60)
    print("🎙️ iza-quote Local Bridge Service (Whisper.cpp) Running...")
    print(f"Monitoring: {STATUS_FILE}")
    print(f"Model: {MODEL_PATH}")
    print(f"Whisper Bin: {WHISPER_BIN}")
    print("=" * 60)
    
    last_processed_time = 0
    api_key = os.environ.get("GEMINI_API_KEY", "").strip()
    
    while True:
        time.sleep(0.05)
        if not os.path.exists(STATUS_FILE):
            continue
            
        try:
            with open(STATUS_FILE, "r", encoding="utf-8") as f:
                status = json.load(f)
        except Exception:
            continue
            
        state = status.get("state")
        ts = status.get("timestamp", 0)
        
        if state == "analyzing" and ts > last_processed_time:
            last_processed_time = ts
            audio_path = status.get("audio", os.path.join(AUDIO_DIR, "latest_question.wav"))
            if not os.path.exists(audio_path):
                # Fallback check m4a
                audio_path = os.path.join(AUDIO_DIR, "latest_question.m4a")
                
            print(f"\n[!] Pertanyaan baru terdeteksi! File: {audio_path}")
            
            if not os.path.exists(audio_path) or os.path.getsize(audio_path) == 0:
                print("File audio kosong atau belum siap.")
                continue
                
            # 1. Transkripsi suara lokal via Whisper
            print("Mengeksekusi transkripsi lokal bahasa Indonesia dengan Whisper...")
            question_text = transcribe_local_whisper(audio_path)
            print(f"Hasil transkripsi: '{question_text}'")
            
            # 2. Update status.json dan serahkan 100% ke sesi Antigravity
            # TIDAK menyentuh answer.txt sama sekali agar tidak ada teks hardcoded / dummy
            data = {}
            if os.path.exists(STATUS_FILE):
                try:
                    with open(STATUS_FILE, "r", encoding="utf-8") as f:
                        data = json.load(f)
                except Exception:
                    data = {}
            data["state"] = "ready_for_antigravity"
            data["question"] = question_text
            data["timestamp"] = time.time()
            with open(STATUS_FILE, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2)
                
            print(f"✅ Pertanyaan diserahkan murni ke Antigravity: '{question_text}'")

if __name__ == "__main__":
    main()
