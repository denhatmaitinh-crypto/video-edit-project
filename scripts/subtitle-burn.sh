#!/usr/bin/env bash
# Burn (ghi cứng) phụ đề .srt vào video. Phụ đề sẽ hiện trên mọi player.
#
# Usage:
#   ./scripts/subtitle-burn.sh <input> <output> <subtitle.srt>

set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <input> <output> <subtitle.srt>" >&2
  exit 1
fi

input="$1"
output="$2"
subtitle="$3"

[ -f "$input" ]    || { echo "Error: không tìm thấy: $input"    >&2; exit 1; }
[ -f "$subtitle" ] || { echo "Error: không tìm thấy: $subtitle" >&2; exit 1; }
mkdir -p "$(dirname "$output")"

# Escape ký tự đặc biệt trong filter path
escaped_sub="${subtitle//\'/\\\'}"

ffmpeg -i "$input" \
  -vf "subtitles='${escaped_sub}'" \
  -c:v libx264 -preset medium -crf 23 \
  -c:a copy \
  "$output"

echo "Done -> $output"
