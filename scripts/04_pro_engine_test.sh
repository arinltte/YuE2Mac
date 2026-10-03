#!/bin/bash
# 04_pro_engine_test.sh — end-to-end test of the Pro engine add-on (yue2_pro.py).
#
#   1. Deploy the add-on next to the stock engine (exactly like the app does).
#   2. Smoke-test the CLI (generate / finish --help).
#   3. Run a REAL short generation: draft steps, saved song project (tokens.json).
#   4. "Finish" it: re-render from the saved tokens at higher steps,
#      verifying the same composition is preserved (same duration).
#   5. Verify the artifacts + a native M4A export via afconvert.
#
# The test writes into a temp folder, never into the app's Output library.
#
# Usage:  ./04_pro_engine_test.sh  [PYTHON]  [ENGINE_DIR]  [MODEL_DIR]
# Defaults point at the environment the app's one-button setup creates.

set -euo pipefail

PYTHON="${1:-$HOME/Library/Application Support/YuE2Mac/Python/bin/python}"
ENGINE_DIR="${2:-$HOME/Library/Application Support/YuE2Mac/Scripts}"
MODEL_DIR="${3:-$HOME/Library/Application Support/YuE2Mac/Models/4bit}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

pass() { printf "  ✔ %s\n" "$*"; }
fail() { printf "  ✘ %s\n" "$*"; exit 1; }
duration_of() { /usr/bin/afinfo "$1" 2>/dev/null | awk '/estimated duration/{print $3}'; }

echo "── 0. Environment"
[ -x "$PYTHON" ]       || fail "Python not found: $PYTHON"
[ -d "$ENGINE_DIR" ]   || fail "Engine dir not found: $ENGINE_DIR"
[ -d "$MODEL_DIR" ]    || fail "Model dir not found: $MODEL_DIR"
"$PYTHON" -c "import mlx.core, numpy, tiktoken" || fail "MLX/numpy/tiktoken not importable"
pass "python + MLX ready"

echo "── 1. Deploy the add-on (as the app does at launch)"
cp "$SCRIPT_DIR/YuE2Mac/yue2_pro.py" "$ENGINE_DIR/yue2_pro.py"
[ -f "$ENGINE_DIR/yue2_pro.py" ] || fail "deploy failed"
pass "yue2_pro.py deployed next to generate.py"

echo "── 2. CLI smoke test"
"$PYTHON" "$ENGINE_DIR/yue2_pro.py" generate --help >/dev/null || fail "generate --help"
"$PYTHON" "$ENGINE_DIR/yue2_pro.py" finish    --help >/dev/null || fail "finish --help"
pass "both subcommands answer"

TESTDIR="$(mktemp -d /tmp/yue2mac-pro-test.XXXXXX)"
trap 'rm -rf "$TESTDIR"' EXIT
echo "── 3. Real short generation (draft: 4 steps, 500-token cap)"
"$PYTHON" "$ENGINE_DIR/yue2_pro.py" generate \
  --model "$MODEL_DIR" \
  --style "English, lo-fi, mellow, gentle piano, vinyl warmth" \
  --lyrics "$(printf '[Verse]\nNeon rain on empty streets\nMy boots hum the city beat\n\n[Chorus]\nSlow down, let the night begin\nThe quiet pulls me further in')" \
  --cot full --seed 831001 --cfg-scale 5.0 --steps 4 \
  --max-semantic-tokens 500 \
  --temperature 1.0 --top-p 0.95 --top-k 100 --rep-penalty 1.2 \
  --out "$TESTDIR/song.wav" 2>"$TESTDIR/log.txt" \
  || { tail -5 "$TESTDIR/log.txt"; fail "generation failed"; }
grep -q "\[done\]" "$TESTDIR/log.txt" || { tail -5 "$TESTDIR/log.txt"; fail "no [done] line"; }

[ -s "$TESTDIR/song.wav" ]          || fail "song.wav missing"
[ -s "$TESTDIR/song.abc" ]         || fail "song.abc missing (cot=full must save the score)"
[ -s "$TESTDIR/song.tokens.json" ] || fail "song.tokens.json missing"
[ -s "$TESTDIR/song.latents.npy" ] || fail "song.latents.npy missing"
pass "audio + score + song project + latents all saved"

"$PYTHON" - "$TESTDIR/song.tokens.json" <<'EOF' || fail "tokens.json malformed"
import json, sys
p = json.load(open(sys.argv[1]))
assert p["version"] == 1 and p["seed"] == 831001 and p["steps"] == 4
assert len(p["codec"]) >= 100, "too few codec tokens"
assert p["abc"], "abc text missing"
assert p["sampling"]["top_k"] == 100, "sampling override not applied"
print("    tokens.json OK: %d codec tokens, sampling overrides applied" % len(p["codec"]))
EOF

DRAFT_DUR="$(duration_of "$TESTDIR/song.wav")"
echo "    draft duration: ${DRAFT_DUR}s"

echo "── 4. Finish at full quality (reuses saved tokens + seed)"
"$PYTHON" "$ENGINE_DIR/yue2_pro.py" finish \
  --model "$MODEL_DIR" --project "$TESTDIR/song.tokens.json" \
  --steps 16 --out "$TESTDIR/song-full.wav" 2>>"$TESTDIR/log.txt" \
  || { tail -5 "$TESTDIR/log.txt"; fail "finish failed"; }
[ -s "$TESTDIR/song-full.wav" ] || fail "song-full.wav missing"
grep -q "seed 831001, tokens reused" "$TESTDIR/log.txt" || fail "finish didn't reuse tokens"

FULL_DUR="$(duration_of "$TESTDIR/song-full.wav")"
echo "    finished duration: ${FULL_DUR}s (draft: ${DRAFT_DUR}s)"
"$PYTHON" - "$DRAFT_DUR" "$FULL_DUR" <<'EOF' || fail "composition changed between draft and finish"
import sys
draft, full = float(sys.argv[1]), float(sys.argv[2])
assert abs(draft - full) < 0.05, "durations diverged: %s vs %s" % (draft, full)
print("    same composition preserved (durations match to <50 ms)")
EOF
pass "finish reused the draft's composition"

echo "── 5. Native M4A export (afconvert)"
/usr/bin/afconvert -f m4af -d aac -b 256000 "$TESTDIR/song-full.wav" "$TESTDIR/song.m4a" || fail "afconvert failed"
[ -s "$TESTDIR/song.m4a" ] || fail "m4a missing"
pass "exported song.m4a"

echo "── 6. ABC score sanity (for the Vocal→Ins instrumental recipe)"
head -3 "$TESTDIR/song.abc"
grep -m1 "V:" "$TESTDIR/song.abc" || echo "    (no V: voice line in this score)"
pass "score inspectable"

echo ""
echo "ALL PRO ENGINE CHECKS PASSED"
