#!/usr/bin/env bash
# Wrapper that activates the VieNeu-TTS venv and runs generate_speech.py.
# Usage: scripts/tts/generate.sh --output output/narration.wav --text "Xin chào" [--voice "Xuân Vĩnh"] [--ref-audio input/my_voice.wav]
#        scripts/tts/generate.sh --list-voices

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.venv"

if [[ ! -d "$VENV_DIR" ]]; then
  echo "Venv not found at $VENV_DIR. Run scripts/tts/setup.sh first." >&2
  exit 1
fi

# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"
python3 "$SCRIPT_DIR/generate_speech.py" "$@"
