#!/usr/bin/env bash
# trim.sh — Cắt một đoạn video.
# Dùng:  ./scripts/trim.sh <video> <bắt_đầu> <thời_lượng> [output]
#   bắt_đầu, thời_lượng: dạng giây (90) hoặc HH:MM:SS (00:01:30)
# Ví dụ: ./scripts/trim.sh input/1.mp4 00:00:05 00:00:20
#        -> cắt từ giây thứ 5, dài 20 giây.
#
# Mặc định CẮT KHÔNG MÃ HÓA LẠI (-c copy) => rất nhanh, không giảm chất lượng.
# Nếu điểm cắt không trùng keyframe có thể lệch nhẹ; thêm "reencode" để cắt chính xác:
#   ./scripts/trim.sh input/1.mp4 5 20 output/cut.mp4 reencode

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
need_ffmpeg

IN="${1:-}"; START="${2:-}"; DUR="${3:-}"
OUT="${4:-$(default_out "$IN" "trim" "${IN##*.}")}"
MODE="${5:-copy}"

[[ -n "$IN" && -n "$START" && -n "$DUR" ]] || \
  die "Dùng: ./scripts/trim.sh <video> <bắt_đầu> <thời_lượng> [output] [copy|reencode]"
need_file "$IN"; guard_not_input "$OUT"

if [[ "$MODE" == "reencode" ]]; then
  ffmpeg -hide_banner -y -ss "$START" -i "$IN" -t "$DUR" \
    -c:v libx264 -preset medium -crf 18 -c:a aac -b:a 192k "$OUT"
else
  ffmpeg -hide_banner -y -ss "$START" -i "$IN" -t "$DUR" -c copy "$OUT"
fi
_grn "Đã cắt -> $OUT"
