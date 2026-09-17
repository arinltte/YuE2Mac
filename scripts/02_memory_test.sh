#!/bin/zsh
# 02_memory_test.sh — measures the driver's memory story during a real generation:
#   1) free RAM before the run
#   2) peak resident memory of the Python engine (the AI model loaded)
#   3) free RAM after the process exits  → proves memory is RELEASED, not left idle.
#
# Why this matters: because YuE2Mac runs the engine as a child process, the model
# lives only while that process is alive. When generate.py finishes, the process
# terminates and macOS reclaims every byte — so the app never holds onto the model
# after the song is done, and your system doesn't stay laggy.
#
# Usage: ./scripts/02_memory_test.sh [PATH_TO_PYTHON] [ENGINE_GENERATE.PY] [MODEL_DIR]
set -e

PY="${1:-$HOME/Library/Application Support/YuE2Mac/Python/bin/python}"
ENGINE="${2:-$HOME/YuE2-Music/YuE2-3B-MLX/generate.py}"
MODEL="${3:-$(dirname "$ENGINE")/8bit}"
OUT=/tmp/yue2_memtest.wav
LOG=/tmp/yue2_memtest.log

PAGE_SIZE=$(sysctl -n hw.pagesize)
MEM_BYTES=$(sysctl -n hw.memsize)
MEM_GB=$(echo "scale=1; $MEM_BYTES/1073741824" | bc)

STYLE="English, indie pop, acoustic guitar, soft drums, warm lead vocal"
LYRICS=$'[Verse]\nGolden hour on the avenue\n[Chorus]\nStay a little longer, hold on through'

# Free memory (free + speculative pages), in MB.
free_mb() {
  vm_stat | awk -v p="$PAGE_SIZE" '
    /Pages free/       {gsub(/[^0-9]/,"",$3); f=$3}
    /Pages speculative/ {gsub(/[^0-9]/,"",$3); s=$3}
    END { printf "%d\n", (f+s)*p/1048576 }'
}

echo "Total RAM: ${MEM_GB} GB   Page size: ${PAGE_SIZE}B"
BASELINE=$(free_mb)
echo "Free RAM before:        ${BASELINE} MB"

echo "Starting generation (COT=full, ~1200 tokens, 16 steps)…"
PYTHONUNBUFFERED=1 "$PY" "$ENGINE" \
  --model "$MODEL" --style "$STYLE" --lyrics "$LYRICS" \
  --cot full --max-semantic-tokens 1200 --steps 16 --seed 7 --out "$OUT" \
  >"$LOG" 2>&1 &
PID=$!

# Poll the engine's resident size every 2s and track the peak.
PEAK=0
while kill -0 $PID 2>/dev/null; do
  RSS=$(ps -o rss= -p $PID 2>/dev/null | awk '{print int($1/1024)}')   # KB -> MB
  if [ -n "$RSS" ] && [ "$RSS" -gt "$PEAK" ]; then PEAK=$RSS; fi
  sleep 2
done
wait $PID; CODE=$?

AFTER=$(free_mb)
echo
echo "Peak engine RSS:       ${PEAK} MB   (AI model + VAE loaded into RAM)"
echo "Free RAM after exit:   ${AFTER} MB"
echo "Exit code: $CODE"

DIFF=$((AFTER - BASELINE))
echo
if [ "$CODE" -eq 0 ]; then
  if [ "$DIFF" -ge -300 ]; then
    echo "✓ GENERATION COMPLETE AND MEMORY RELEASED"
    echo "  Free RAM returned to within ${DIFF} MB of baseline → no idle model holding RAM."
  else
    echo "⚠  Memory did not fully return (${DIFF} MB below baseline) — read the log."
  fi
else
  echo "✗ Generation failed (exit $CODE). See $LOG"
  tail -20 "$LOG"
  exit 1
fi

echo
echo "== Engine timing log =="
grep -E '\[(abc|semantic|nar|vae|done)\]' "$LOG" | tail -12