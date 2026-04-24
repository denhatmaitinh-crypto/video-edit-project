#!/usr/bin/env bash
# Đổi độ phân giải video. Giữ tỉ lệ khung hình (truyền -1 cho chiều tự tính).
#
# Usage:
#   ./scripts/resize.sh <input> <output> <width> <height>
#
# Ví dụ (ép xuống 720p, giữ tỉ lệ):
#   ./scripts/resize.sh input/1080p.mp4 output/720p.mp4 -1 720

set -euo pipefail

if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <input> <output> <width> <height>" >&2
  echo "  Truyền -1 cho chiều muốn tự tính theo tỉ lệ." >&2
  exit 1
fi

input="$1"
output="$2"
width="$3"
height="$4"

[ -f "$input" ] || { echo "Error: không tìm thấy: $input" >&2; exit 1; }
mkdir -p "$(dirname "$output")"

ffmpeg -i "$input" \
  -vf "scale=${width}:${height}" \
  -c:v libx264 -preset medium -crf 23 \
  -c:a copy \
  "$output"

echo "Done -> $output"
