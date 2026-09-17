#!/bin/zsh
# 03_install_variant.sh — builds an 8-bit OR 4-bit MLX package from the original
# bf16 YuE2 checkpoint (downloaded from Hugging Face). Use this when you want a
# 4-bit model for a low-RAM Mac and it isn't already in your engine folder.
#
#   bash scripts/03_install_variant.sh        # builds 4-bit
#   bash scripts/03_install_variant.sh 8bit   # builds 8-bit
#
# NOTE: building a variant needs the UNQUANTIZED source weights (~14 GB download,
# ~16 GB free disk) and enough RAM to hold the model while quantising
# (≳ 24 GB advised). If your Mac is small, the app's own autoscan will find an
# existing 8bit/4bit folder instead — you only need this if that folder is missing.
set -e

BITS="${1:-4}"
ENGINE="${2:-$HOME/YuE2-Music/YuE2-3B-MLX}"
VENV_PY="${3:-$HOME/Library/Application Support/YuE2Mac/Python/bin/python}"

if [ ! -f "$VENV_PY" ]; then
  echo "❌ No app Python venv found at: $VENV_PY"
  echo "   Open YuE2Mac once and press 'Check & Install' first, then retry."
  exit 1
fi

# convert.py needs huggingface_hub + the model source. Install both into the app's env.
"$VENV_PY" -m pip install --quiet huggingface_hub

echo "▸ Building the ${BITS}-bit variant (downloads bf16 source + converts). This is big and slow."
echo "  Output: $ENGINE/$BITS"
cd "$ENGINE"
"$VENV_PY" convert.py --output "$ENGINE/$BITS" --quantize --bits "$BITS" "$@"

echo "▸ Done. The app's model picker will now show '$BITS'."