#!/usr/bin/env bash
# Cắt một đoạn video bằng FFmpeg (không re-encode, rất nhanh).
#
# Usage:
#   ./scripts/trim.sh <input> <output> <start> <duration>
#
# Ví dụ (cắt từ giây thứ 5, lấy 10 giây):
#   ./scripts/trim.sh input/video.mp4 output/video-cat.mp4 00:00:05 00:00:10

set -euo pipefail

if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <input> <output> <start> <duration>" >&2
  echo "  start/duration ở dạng HH:MM:SS (vd 00:00:05)" >&2
  exit 1
fi

input="$1"
output="$2"
start="$3"
duration="$4"

if [ ! -f "$input" ]; then
  echo "Error: không tìm thấy file input: $input" >&2
  exit 1
fi

mkdir -p "$(dirname "$output")"

ffmpeg -ss "$start" -i "$input" -t "$duration" -c copy -avoid_negative_ts make_zero "$output"

echo "Done -> $output"
