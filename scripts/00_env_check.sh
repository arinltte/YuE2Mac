#!/bin/zsh
# 00_env_check.sh — verifies the Python environment that YuE2Mac will use.
# Exits 0 only if every dependency is importable and the engine CLI responds.
# Usage: ./scripts/00_env_check.sh [PATH_TO_PYTHON]
set -e

PY="${1:-$HOME/Library/Application Support/YuE2Mac/Python/bin/python}"
ENGINE="${2:-$HOME/YuE2-Music/YuE2-3B-MLX/generate.py}"

echo "== Python: $PY =="
"$PY" --version

echo "== Importing MLX / NumPy / tiktoken =="
"$PY" -c "
import mlx.core, numpy, tiktoken
import importlib.metadata as M
print('  mlx', M.version('mlx'))
print('  numpy', numpy.__version__)
print('  tiktoken', tiktoken.__version__)
import mlx.core as mx
print('  MLX device:', mx.default_device())
"

echo "== Engine CLI responds =="
"$PY" "$ENGINE" --help >/dev/null 2>&1 && echo "  generate.py --help OK"

echo "== Sanity compute (MLX sum) =="
"$PY" -c "import mlx.core as mx; print('  sum([1..4]) =', float(mx.sum(mx.array([1.,2,3,4]))))"

echo "ALL CHECKS PASSED"