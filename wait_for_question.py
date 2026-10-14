#!/usr/bin/env python3
import os
import time
import json

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
STATUS_FILE = os.path.join(BASE_DIR, "status.json")

import sys

# Baca timestamp terakhir yang sudah diproses agar tidak mendeteksi pertanyaan lama
initial_ts = 0
if os.path.exists(STATUS_FILE):
    try:
        with open(STATUS_FILE, "r") as f:
            data = json.load(f)
            initial_ts = data.get("timestamp", 0)
    except Exception:
        pass

while True:
    time.sleep(0.05)
    if os.path.exists(STATUS_FILE):
        try:
            with open(STATUS_FILE, "r") as f:
                data = json.load(f)
            
            ts = data.get("timestamp", 0)
            state = data.get("state")
            question = data.get("question", "").strip()
            
            if ts > initial_ts and state in ["ready_for_antigravity", "answered"] and question:
                print(f"PERTANYAAN_BARU: {question}", flush=True)
                sys.stdout.flush()
                break
        except Exception:
            pass

