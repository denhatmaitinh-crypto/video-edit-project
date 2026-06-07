#!/usr/bin/env bash
# watermark.sh — Chèn logo/watermark (ảnh PNG, nên có nền trong suốt) lên video.
# Dùng:  ./scripts/watermark.sh <video> <logo.png> [vị_trí] [output]
#   vị_trí: tl | tr | bl | br | center   (mặc định br = góc dưới phải)
# Ví dụ: ./scripts/watermark.sh input/1.mp4 input/logo.png tr
#
# Tùy biến: SCALE (bề rộng logo theo % chiều rộng video, mặc định 15),
#           MARGIN (lề tính bằng px, mặc định 20), ALPHA (độ mờ 0-1, mặc định 1).
# Ví dụ:  SCALE=20 ALPHA=0.7 ./scripts/watermark.sh input/1.mp4 input/logo.png bl

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
need_ffmpeg

IN="${1:-}"; LOGO="${2:-}"; POS="${3:-br}"
OUT="${4:-$(default_out "$IN" "watermark" "mp4")}"
[[ -n "$IN" && -n "$LOGO" ]] || die "Dùng: ./scripts/watermark.sh <video> <logo.png> [tl|tr|bl|br|center] [output]"
need_file "$IN"; need_file "$LOGO"; guard_not_input "$OUT"

SCALE="${SCALE:-15}"; M="${MARGIN:-20}"; ALPHA="${ALPHA:-1}"

case "$POS" in
  tl) XY="${M}:${M}" ;;
  tr) XY="W-w-${M}:${M}" ;;
  bl) XY="${M}:H-h-${M}" ;;
  center) XY="(W-w)/2:(H-h)/2" ;;
  *)  XY="W-w-${M}:H-h-${M}" ;;  # br
esac

ffmpeg -hide_banner -y -i "$IN" -i "$LOGO" -filter_complex \
"[1:v]format=rgba,colorchannelmixer=aa=${ALPHA}[lg];\
[lg][0:v]scale2ref=w=main_w*${SCALE}/100:h=ow/a[wm][base];\
[base][wm]overlay=${XY}[v]" \
  -map "[v]" -map 0:a? -c:v libx264 -preset medium -crf 20 -c:a copy -movflags +faststart "$OUT"
_grn "Đã chèn logo -> $OUT"
