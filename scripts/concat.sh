#!/usr/bin/env bash
# Nối nhiều video thành 1. Các video phải cùng codec/độ phân giải để nối nhanh.
# Nếu khác codec, script sẽ re-encode tự động.
#
# Usage:
#   ./scripts/concat.sh <output> <input1> <input2> [input3...]
#
# Ví dụ:
#   ./scripts/concat.sh output/merged.mp4 input/a.mp4 input/b.mp4 input/c.mp4

set -euo pipefail

if [ "$#" -lt 3 ]; then
  echo "Usage: $0 <output> <input1> <input2> [input3...]" >&2
  exit 1
fi

output="$1"
shift

mkdir -p "$(dirname "$output")"
listfile="$(mktemp -t concat.XXXXXX)"
trap 'rm -f "$listfile"' EXIT

for f in "$@"; do
  [ -f "$f" ] || { echo "Error: không tìm thấy: $f" >&2; exit 1; }
  # Escape single quote cho concat demuxer
  abs="$(cd "$(dirname "$f")" && pwd)/$(basename "$f")"
  printf "file '%s'\n" "${abs//\'/\'\\\'\'}" >> "$listfile"
done

# Thử stream copy trước (rất nhanh), fallback sang re-encode nếu lỗi
if ! ffmpeg -f concat -safe 0 -i "$listfile" -c copy "$output" 2>/dev/null; then
  echo "Stream copy thất bại, re-encode..."
  ffmpeg -f concat -safe 0 -i "$listfile" \
    -c:v libx264 -preset medium -crf 23 \
    -c:a aac -b:a 128k \
    "$output"
fi

echo "Done -> $output"
