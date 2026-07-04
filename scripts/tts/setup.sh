#!/usr/bin/env bash
# Sets up a Python venv with VieNeu-TTS v3 Turbo (Vietnamese TTS).
# Usage: scripts/tts/setup.sh [--gpu] [--venv-dir <path>]

set -euo pipefail

VENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.venv"
GPU=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --gpu) GPU=1; shift ;;
    --venv-dir) VENV_DIR="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [[ ! -d "$VENV_DIR" ]]; then
  python3 -m venv "$VENV_DIR"
fi

# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"
pip install --upgrade pip

if [[ "$GPU" -eq 1 ]]; then
  pip install "vieneu[gpu]"
else
  pip install vieneu
fi

echo "VieNeu-TTS installed in $VENV_DIR"
echo "Model weights download from Hugging Face on first run — an internet connection is required then."
