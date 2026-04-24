#!/usr/bin/env bash
# Hiển thị thông tin video: độ dài, kích thước, codec, bitrate, fps...
#
# Usage: ./scripts/info.sh <input>

set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <input>" >&2
  exit 1
fi

input="$1"
[ -f "$input" ] || { echo "Error: không tìm thấy: $input" >&2; exit 1; }

ffprobe -v error -show_format -show_streams "$input"
