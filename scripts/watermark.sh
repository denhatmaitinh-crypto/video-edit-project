#!/usr/bin/env bash
# Chèn logo/watermark (PNG có nền trong suốt) vào góc video.
#
# Usage:
#   ./scripts/watermark.sh <input> <output> <logo> [position]
#
# position: tl | tr | bl | br (top-left/right, bottom-left/right). Mặc định br.
#
# Ví dụ:
#   ./scripts/watermark.sh input/video.mp4 output/branded.mp4 assets/logo.png br

set -euo pipefail

if [ "$#" -lt 3 ] || [ "$#" -gt 4 ]; then
  echo "Usage: $0 <input> <output> <logo> [position=br]" >&2
  echo "  position: tl | tr | bl | br" >&2
  exit 1
fi

input="$1"
output="$2"
logo="$3"
position="${4:-br}"

[ -f "$input" ] || { echo "Error: không tìm thấy: $input" >&2; exit 1; }
[ -f "$logo" ]  || { echo "Error: không tìm thấy: $logo"  >&2; exit 1; }
mkdir -p "$(dirname "$output")"

case "$position" in
  tl) overlay="10:10" ;;
  tr) overlay="main_w-overlay_w-10:10" ;;
  bl) overlay="10:main_h-overlay_h-10" ;;
  br) overlay="main_w-overlay_w-10:main_h-overlay_h-10" ;;
  *)  echo "Error: position phải là tl|tr|bl|br" >&2; exit 1 ;;
esac

ffmpeg -i "$input" -i "$logo" \
  -filter_complex "overlay=${overlay}" \
  -c:a copy \
  "$output"

echo "Done -> $output"
