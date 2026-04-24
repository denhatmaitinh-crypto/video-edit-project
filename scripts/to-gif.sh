#!/usr/bin/env bash
# Chuyển một đoạn video thành GIF chất lượng cao (dùng palette 2-pass).
#
# Usage:
#   ./scripts/to-gif.sh <input> <output> [start=0] [duration=5] [fps=15] [width=480]

set -euo pipefail

if [ "$#" -lt 2 ] || [ "$#" -gt 6 ]; then
  echo "Usage: $0 <input> <output> [start=0] [duration=5] [fps=15] [width=480]" >&2
  exit 1
fi

input="$1"
output="$2"
start="${3:-0}"
duration="${4:-5}"
fps="${5:-15}"
width="${6:-480}"

[ -f "$input" ] || { echo "Error: không tìm thấy: $input" >&2; exit 1; }
mkdir -p "$(dirname "$output")"

palette="$(mktemp -t palette.XXXXXX).png"
trap 'rm -f "$palette"' EXIT

# Pass 1: tạo palette
ffmpeg -ss "$start" -t "$duration" -i "$input" \
  -vf "fps=${fps},scale=${width}:-1:flags=lanczos,palettegen" \
  -y "$palette"

# Pass 2: render gif với palette
ffmpeg -ss "$start" -t "$duration" -i "$input" -i "$palette" \
  -lavfi "fps=${fps},scale=${width}:-1:flags=lanczos [x]; [x][1:v] paletteuse" \
  -y "$output"

echo "Done -> $output"
