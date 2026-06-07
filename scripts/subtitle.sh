#!/usr/bin/env bash
# subtitle.sh — Gắn phụ đề vào video.
#   - Mặc định: GHI CHẾT phụ đề lên hình (burn-in) từ file .srt -> ai cũng xem được.
#   - Chế độ "soft": nhúng phụ đề bật/tắt được (chỉ dùng cho .mp4/.mkv).
# Dùng:  ./scripts/subtitle.sh <video> <file.srt> [output] [burn|soft]
# Ví dụ: ./scripts/subtitle.sh input/1.mp4 input/1.srt
#
# Tùy biến kiểu chữ khi burn (cỡ/màu/viền): đặt biến STYLE, ví dụ:
#   STYLE="FontSize=24,PrimaryColour=&H00FFFFFF,OutlineColour=&H00000000,Outline=2"

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
need_ffmpeg

IN="${1:-}"; SRT="${2:-}"
OUT="${3:-$(default_out "$IN" "sub" "mp4")}"
MODE="${4:-burn}"
[[ -n "$IN" && -n "$SRT" ]] || die "Dùng: ./scripts/subtitle.sh <video> <file.srt> [output] [burn|soft]"
need_file "$IN"; need_file "$SRT"; guard_not_input "$OUT"

STYLE="${STYLE:-FontSize=22,PrimaryColour=&H00FFFFFF,OutlineColour=&H00000000,Outline=2,Shadow=0}"

if [[ "$MODE" == "soft" ]]; then
  ffmpeg -hide_banner -y -i "$IN" -i "$SRT" \
    -c copy -c:s mov_text -metadata:s:s:0 language=vie "$OUT"
  _grn "Đã nhúng phụ đề mềm (bật/tắt được) -> $OUT"
else
  # burn-in: escape dấu cho filter subtitles
  esc="${SRT//\\/\\\\}"; esc="${esc//:/\\:}"; esc="${esc//\'/\\\'}"
  ffmpeg -hide_banner -y -i "$IN" \
    -vf "subtitles='${esc}':force_style='${STYLE}'" \
    -c:v libx264 -preset medium -crf 20 -c:a copy -movflags +faststart "$OUT"
  _grn "Đã ghi chết phụ đề lên hình -> $OUT"
fi
