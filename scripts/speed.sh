#!/usr/bin/env bash
# Tăng/giảm tốc độ video kèm audio. Hệ số > 1 là nhanh, < 1 là chậm.
#
# Usage:
#   ./scripts/speed.sh <input> <output> <factor>
#
# Ví dụ:
#   ./scripts/speed.sh input/video.mp4 output/fast2x.mp4 2.0
#   ./scripts/speed.sh input/video.mp4 output/slow-mo.mp4 0.5

set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <input> <output> <factor>" >&2
  echo "  factor > 1: nhanh hơn | < 1: chậm hơn" >&2
  exit 1
fi

input="$1"
output="$2"
factor="$3"

[ -f "$input" ] || { echo "Error: không tìm thấy: $input" >&2; exit 1; }
mkdir -p "$(dirname "$output")"

# atempo chỉ nhận 0.5 - 2.0. Với hệ số ngoài khoảng đó cần chain nhiều atempo.
# setpts=PTS/factor cho video, atempo=factor cho audio.
video_pts=$(awk "BEGIN {print 1/$factor}")

ffmpeg -i "$input" \
  -filter_complex "[0:v]setpts=${video_pts}*PTS[v];[0:a]atempo=${factor}[a]" \
  -map "[v]" -map "[a]" \
  -c:v libx264 -preset medium -crf 23 \
  -c:a aac -b:a 128k \
  "$output"

echo "Done -> $output"
