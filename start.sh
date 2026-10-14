#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Download whisper model if not present
if [ ! -f "$DIR/models/ggml-base.bin" ]; then
    "$DIR/download_model.sh"
fi

# Rebuild if not exists
if [ ! -f "$DIR/iza-quote" ]; then
    "$DIR/build.sh"
fi

# Stop existing instances
"$DIR/stop.sh" 2>/dev/null || true

echo "Meluncurkan iza-quote Floating HUD..."
nohup "$DIR/iza-quote" > /dev/null 2>&1 &
echo "PID: $!"

echo "Menjalankan Bridge Service di latar belakang..."
nohup python3 -u "$DIR/bridge.py" > "$DIR/bridge.log" 2>&1 &
echo "Bridge PID: $!"

echo ""
echo "iza-quote SUDAH AKTIF!"
echo "- Widget melayang sekarang muncul di layar Anda (selalu di atas, terproteksi dari Zoom share screen)."
echo "- Untuk menghentikan kapan saja: jalankan ./stop.sh"
