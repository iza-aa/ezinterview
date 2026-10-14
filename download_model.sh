#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODEL_DIR="$DIR/models"
MODEL_FILE="$MODEL_DIR/ggml-base.bin"
MODEL_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin"

mkdir -p "$MODEL_DIR"

if [ -f "$MODEL_FILE" ]; then
    echo "Model ggml-base.bin already exists in $MODEL_DIR"
    exit 0
fi

echo "Downloading ggml-base.bin from $MODEL_URL..."
curl -L -o "$MODEL_FILE" "$MODEL_URL"
echo "Model downloaded successfully to $MODEL_FILE"
