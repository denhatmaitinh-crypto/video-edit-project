#!/usr/bin/env bash
# Crop video theo kích thước & vị trí pixel.
#
# Usage:
#   ./scripts/crop.sh <input> <output> <width> <height> <x> <y>
#
# Ví dụ (cắt vùng 720x720 bắt đầu từ (100, 50)):
#   ./scripts/crop.sh input/video.mp4 output/cropped.mp4 720 720 100 50

set -euo pipefail

if [ "$#" -ne 6 ]; then
  echo "Usage: $0 <input> <output> <width> <height> <x> <y>" >&2
  exit 1
fi

input="$1"
output="$2"
w="$3"
h="$4"
x="$5"
y="$6"

[ -f "$input" ] || { echo "Error: không tìm thấy: $input" >&2; exit 1; }
mkdir -p "$(dirname "$output")"

ffmpeg -i "$input" \
  -vf "crop=${w}:${h}:${x}:${y}" \
  -c:a copy \
  "$output"

echo "Done -> $output"
