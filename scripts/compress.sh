#!/usr/bin/env bash
# Nén video (giảm dung lượng) bằng H.264 CRF. CRF càng cao -> file càng nhỏ,
# chất lượng càng giảm. Mặc định CRF=28 (giảm ~70% dung lượng, vẫn xem tốt).
#
# Usage:
#   ./scripts/compress.sh <input> <output> [crf]
#
# Ví dụ:
#   ./scripts/compress.sh input/big.mp4 output/small.mp4 28

set -euo pipefail

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
  echo "Usage: $0 <input> <output> [crf=28]" >&2
  exit 1
fi

input="$1"
output="$2"
crf="${3:-28}"

[ -f "$input" ] || { echo "Error: không tìm thấy: $input" >&2; exit 1; }
mkdir -p "$(dirname "$output")"

ffmpeg -i "$input" \
  -c:v libx264 -preset slow -crf "$crf" \
  -c:a aac -b:a 128k \
  -movflags +faststart \
  "$output"

echo "Done -> $output"
