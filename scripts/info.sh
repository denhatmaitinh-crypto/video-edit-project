#!/usr/bin/env bash
# info.sh — Nhận diện video: độ phân giải, fps, thời lượng, codec, bitrate, audio.
# Dùng:  ./scripts/info.sh <đường_dẫn_video>
# Ví dụ: ./scripts/info.sh input/1.mp4

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
need_ffmpeg

IN="${1:-}"
[[ -n "$IN" ]] || die "Thiếu tham số. Dùng: ./scripts/info.sh <video>"
need_file "$IN"

_grn "=== Thông tin: $IN ==="
ffprobe -v error -hide_banner \
  -show_entries format=format_long_name,duration,size,bit_rate \
  -show_entries stream=index,codec_type,codec_name,width,height,r_frame_rate,sample_rate,channels,bit_rate \
  -of default=noprint_wrappers=1 "$IN"

echo
_grn "=== Tóm tắt ==="
# Thời lượng (giây) -> phút:giây
dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$IN" 2>/dev/null || echo 0)
printf "Thời lượng : %s giây (~%d phút %02d giây)\n" "$dur" \
  "$(printf '%.0f' "$(echo "$dur/60" | bc -l 2>/dev/null || echo 0)")" \
  "$(printf '%.0f' "$(echo "$dur%60" | bc -l 2>/dev/null || echo 0)")" 2>/dev/null || true
ffprobe -v error -select_streams v:0 \
  -show_entries stream=width,height,r_frame_rate,codec_name \
  -of csv=p=0:s=' | ' "$IN" 2>/dev/null | sed 's/^/Video      : /'
ffprobe -v error -select_streams a:0 \
  -show_entries stream=codec_name,sample_rate,channels \
  -of csv=p=0:s=' | ' "$IN" 2>/dev/null | sed 's/^/Audio      : /'
