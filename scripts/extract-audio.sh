#!/usr/bin/env bash
# Tách audio từ video ra file mp3 (hoặc đuôi khác tùy file output).
#
# Usage:
#   ./scripts/extract-audio.sh <input> <output>
#
# Ví dụ:
#   ./scripts/extract-audio.sh input/video.mp4 output/audio.mp3

set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <input> <output>" >&2
  exit 1
fi

input="$1"
output="$2"

[ -f "$input" ] || { echo "Error: không tìm thấy: $input" >&2; exit 1; }
mkdir -p "$(dirname "$output")"

ffmpeg -i "$input" -vn -acodec libmp3lame -q:a 2 "$output"

echo "Done -> $output"
