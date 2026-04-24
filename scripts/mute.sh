#!/usr/bin/env bash
# Bỏ âm thanh khỏi video (giữ nguyên video, xóa audio track).
#
# Usage:
#   ./scripts/mute.sh <input> <output>

set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <input> <output>" >&2
  exit 1
fi

input="$1"
output="$2"

[ -f "$input" ] || { echo "Error: không tìm thấy: $input" >&2; exit 1; }
mkdir -p "$(dirname "$output")"

ffmpeg -i "$input" -c:v copy -an "$output"

echo "Done -> $output"
