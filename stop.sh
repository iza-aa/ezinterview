#!/bin/bash
echo "🛑 Menghentikan iza-quote..."
pkill -f "/iza-quote" 2>/dev/null || true
pkill -f "bridge.py" 2>/dev/null || true
echo "✅ iza-quote telah dihentikan."
