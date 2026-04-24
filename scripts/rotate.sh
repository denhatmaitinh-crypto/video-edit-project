#!/usr/bin/env bash
# Xoay video 90/180/270 độ (theo chiều kim đồng hồ).
#
# Usage:
#   ./scripts/rotate.sh <input> <output> <degrees>
#
# degrees: 90 | 180 | 270

set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <input> <output> <90|180|270>" >&2
  exit 1
fi

input="$1"
output="$2"
degrees="$3"

[ -f "$input" ] || { echo "Error: không tìm thấy: $input" >&2; exit 1; }
mkdir -p "$(dirname "$output")"

case "$degrees" in
  90)  transpose="transpose=1" ;;
  180) transpose="transpose=1,transpose=1" ;;
  270) transpose="transpose=2" ;;
  *) echo "Error: degrees phải là 90, 180 hoặc 270" >&2; exit 1 ;;
esac

ffmpeg -i "$input" -vf "$transpose" -c:a copy "$output"

echo "Done -> $output"
