#!/usr/bin/env bash
# Trích 1 frame tại thời điểm chỉ định làm ảnh thumbnail.
#
# Usage:
#   ./scripts/thumbnail.sh <input> <output.jpg> [time=00:00:01]

set -euo pipefail

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
  echo "Usage: $0 <input> <output.jpg> [time=00:00:01]" >&2
  exit 1
fi

input="$1"
output="$2"
time="${3:-00:00:01}"

[ -f "$input" ] || { echo "Error: không tìm thấy: $input" >&2; exit 1; }
mkdir -p "$(dirname "$output")"

ffmpeg -ss "$time" -i "$input" -frames:v 1 -q:v 2 "$output"

echo "Done -> $output"
