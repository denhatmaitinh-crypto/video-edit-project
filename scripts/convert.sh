#!/usr/bin/env bash
# Đổi định dạng video. FFmpeg tự suy định dạng từ đuôi file output.
#
# Usage:
#   ./scripts/convert.sh <input> <output>
#
# Ví dụ:
#   ./scripts/convert.sh input/video.mov output/video.mp4
#   ./scripts/convert.sh input/video.mkv output/video.webm

set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <input> <output>" >&2
  exit 1
fi

input="$1"
output="$2"

[ -f "$input" ] || { echo "Error: không tìm thấy: $input" >&2; exit 1; }
mkdir -p "$(dirname "$output")"

ffmpeg -i "$input" \
  -c:v libx264 -preset medium -crf 23 \
  -c:a aac -b:a 128k \
  -movflags +faststart \
  "$output"

echo "Done -> $output"
