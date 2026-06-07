#!/usr/bin/env bash
# compress.sh — Nén/giảm dung lượng video (H.264).
# Dùng:  ./scripts/compress.sh <video> [crf] [output]
#   crf: 18 (đẹp, nặng) ... 23 (mặc định, cân bằng) ... 28 (nhẹ, mờ hơn)
# Ví dụ: ./scripts/compress.sh input/1.mp4 24
#
# Để nén mạnh hơn nữa (codec H.265/HEVC, nhẹ ~30-50%), đặt CODEC=h265:
#   CODEC=h265 ./scripts/compress.sh input/1.mp4 28

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
need_ffmpeg

IN="${1:-}"; CRF="${2:-23}"
OUT="${3:-$(default_out "$IN" "compressed" "mp4")}"
[[ -n "$IN" ]] || die "Dùng: ./scripts/compress.sh <video> [crf] [output]"
need_file "$IN"; guard_not_input "$OUT"

if [[ "${CODEC:-h264}" == "h265" ]]; then
  ffmpeg -hide_banner -y -i "$IN" -c:v libx265 -preset medium -crf "$CRF" \
    -tag:v hvc1 -c:a aac -b:a 128k "$OUT"
else
  ffmpeg -hide_banner -y -i "$IN" -c:v libx264 -preset medium -crf "$CRF" \
    -pix_fmt yuv420p -c:a aac -b:a 128k -movflags +faststart "$OUT"
fi

before=$(du -h "$IN" | cut -f1); after=$(du -h "$OUT" | cut -f1)
_grn "Đã nén -> $OUT  (trước: $before, sau: $after)"
