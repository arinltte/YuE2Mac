#!/bin/zsh
# 01_generate_test.sh — runs a SHORT generation end to end and validates the WAV.
# Proves: model loads, AR + NAR + VAE stages run, and a real audio file comes out.
# Usage: ./scripts/01_generate_test.sh [PATH_TO_PYTHON] [ENGINE_GENERATE.PY] [MODEL_DIR]
set -e

PY="${1:-$HOME/Library/Application Support/YuE2Mac/Python/bin/python}"
ENGINE="${2:-$HOME/YuE2-Music/YuE2-3B-MLX/generate.py}"
MODEL="${3:-$(dirname "$ENGINE")/8bit}"
OUT=/tmp/yue2_smoke.wav

STYLE="English, indie pop, acoustic guitar, soft drums, warm lead vocal"
LYRICS=$'[Verse]\nGolden hour on the avenue\n[Chorus]\nStay a little longer, hold on through'

echo "== Generating a short clip (~48s, 16 NAR steps, COT=full) =="
time PYTHONUNBUFFERED=1 "$PY" "$ENGINE" \
  --model "$MODEL" --style "$STYLE" --lyrics "$LYRICS" \
  --cot full --max-semantic-tokens 1200 --steps 16 --seed 7 --out "$OUT"

echo "== Validating '$OUT' =="
"$PY" - "$OUT" <<'PYEOF'
import sys, wave
p = sys.argv[1]
with wave.open(p, 'rb') as w:
    frames = w.getnframes()
    rate = w.getframerate()
    ch = w.getnchannels()
    width = w.getsampwidth()
print(f"  OK  {frames/rate:.1f}s at {rate} Hz, {ch} channel(s), {width*8}-bit")
print("  VALID WAVE FILE")
PYEOF
ls -la "$OUT"