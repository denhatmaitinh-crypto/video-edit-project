#!/usr/bin/env bash
# vertical.sh — Chuyển video ngang -> dọc 9:16 (TikTok/Reels/Shorts).
# Khung 1080x1920: video gốc nằm giữa, nền là chính nó được phóng to + làm mờ.
# Dùng:  ./scripts/vertical.sh <video> [output]
# Ví dụ: ./scripts/vertical.sh input/1.mp4
#
# Muốn tỉ lệ khác? đặt SIZE=WxH, ví dụ vuông 1:1:
#   SIZE=1080x1080 ./scripts/vertical.sh input/1.mp4

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
need_ffmpeg

IN="${1:-}"; OUT="${2:-$(default_out "$IN" "vertical" "mp4")}"
[[ -n "$IN" ]] || die "Dùng: ./scripts/vertical.sh <video> [output]"
need_file "$IN"; guard_not_input "$OUT"

SIZE="${SIZE:-1080x1920}"; W="${SIZE%x*}"; H="${SIZE#*x}"

ffmpeg -hide_banner -y -i "$IN" -filter_complex \
"[0:v]scale=${W}:${H}:force_original_aspect_ratio=increase,crop=${W}:${H},boxblur=20:5[bg];\
[0:v]scale=${W}:${H}:force_original_aspect_ratio=decrease[fg];\
[bg][fg]overlay=(W-w)/2:(H-h)/2,setsar=1[v]" \
  -map "[v]" -map 0:a? -c:v libx264 -preset medium -crf 20 -c:a aac -b:a 128k -movflags +faststart "$OUT"
_grn "Đã chuyển dọc ${SIZE} -> $OUT"
