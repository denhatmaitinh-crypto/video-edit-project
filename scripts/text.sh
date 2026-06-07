#!/usr/bin/env bash
# text.sh — Chèn chữ (tiêu đề/chú thích) lên video.
# Dùng:  ./scripts/text.sh <video> "<nội dung>" [vị_trí] [output]
#   vị_trí: top | center | bottom   (mặc định bottom)
# Ví dụ: ./scripts/text.sh input/1.mp4 "Để AI Tính" top
#
# Tùy biến: SIZE (cỡ chữ, mặc định 48), COLOR (màu, mặc định white),
#           FONT (đường dẫn .ttf — cần font hỗ trợ tiếng Việt).
# Ví dụ:  SIZE=64 COLOR=yellow ./scripts/text.sh input/1.mp4 "Xin chào" center

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
need_ffmpeg

IN="${1:-}"; TXT="${2:-}"; POS="${3:-bottom}"
OUT="${4:-$(default_out "$IN" "text" "mp4")}"
[[ -n "$IN" && -n "$TXT" ]] || die "Dùng: ./scripts/text.sh <video> \"<nội dung>\" [top|center|bottom] [output]"
need_file "$IN"; guard_not_input "$OUT"

SIZE="${SIZE:-48}"; COLOR="${COLOR:-white}"
# Font mặc định trên macOS hỗ trợ tiếng Việt
FONT="${FONT:-/System/Library/Fonts/Supplemental/Arial Unicode.ttf}"
[[ -f "$FONT" ]] || FONT="/System/Library/Fonts/Supplemental/Arial.ttf"

case "$POS" in
  top)    Y="h*0.08" ;;
  center) Y="(h-text_h)/2" ;;
  *)      Y="h*0.85" ;;
esac

# Escape ký tự đặc biệt cho drawtext
t="${TXT//\\/\\\\}"; t="${t//:/\\:}"; t="${t//\'/\\\'}"; t="${t//%/\\%}"

ffmpeg -hide_banner -y -i "$IN" -vf \
"drawtext=fontfile='${FONT}':text='${t}':fontcolor=${COLOR}:fontsize=${SIZE}:\
box=1:boxcolor=black@0.5:boxborderw=12:x=(w-text_w)/2:y=${Y}" \
  -c:v libx264 -preset medium -crf 20 -c:a copy -movflags +faststart "$OUT"
_grn "Đã chèn chữ -> $OUT"
