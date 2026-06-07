#!/usr/bin/env bash
# concat.sh — Nối nhiều clip thành một video.
# Dùng:  ./scripts/concat.sh <output> <clip1> <clip2> [clip3 ...]
# Ví dụ: ./scripts/concat.sh output/ghep.mp4 input/a.mp4 input/b.mp4 input/c.mp4
#
# Nếu các clip CÙNG codec/độ phân giải/fps -> nối nhanh không mã hóa lại.
# Nếu KHÁC nhau -> tự động chuẩn hóa rồi nối (chậm hơn nhưng chắc ăn).
# Ép chuẩn hóa: đặt biến FORCE_REENCODE=1 ở đầu lệnh.

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
need_ffmpeg

OUT="${1:-}"; shift || true
[[ -n "$OUT" && $# -ge 2 ]] || \
  die "Dùng: ./scripts/concat.sh <output> <clip1> <clip2> [clip3 ...]"
guard_not_input "$OUT"; ensure_output
for f in "$@"; do need_file "$f"; done

# Kiểm tra xem mọi clip có cùng thông số không
sig() { ffprobe -v error -select_streams v:0 -show_entries stream=codec_name,width,height -of csv=p=0 "$1" 2>/dev/null; }
first_sig="$(sig "$1")"; same=1
for f in "$@"; do [[ "$(sig "$f")" == "$first_sig" ]] || same=0; done

if [[ "$same" == "1" && "${FORCE_REENCODE:-0}" != "1" ]]; then
  list="$(mktemp)"; for f in "$@"; do printf "file '%s'\n" "$(cd "$(dirname "$f")" && pwd)/$(basename "$f")" >> "$list"; done
  ffmpeg -hide_banner -y -f concat -safe 0 -i "$list" -c copy "$OUT"
  rm -f "$list"
else
  _ylw "Các clip khác thông số -> chuẩn hóa rồi nối (1080p, 30fps)."
  inputs=(); filter=""; n=0
  for f in "$@"; do inputs+=( -i "$f" ); done
  for ((i=0;i<$#;i++)); do
    filter+="[$i:v]scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:-1:-1:color=black,setsar=1,fps=30[v$i];[$i:a]aresample=48000[a$i];"
    n=$((n+1))
  done
  for ((i=0;i<n;i++)); do filter+="[v$i][a$i]"; done
  filter+="concat=n=$n:v=1:a=1[outv][outa]"
  ffmpeg -hide_banner -y "${inputs[@]}" -filter_complex "$filter" \
    -map "[outv]" -map "[outa]" -c:v libx264 -preset medium -crf 20 -c:a aac -b:a 192k "$OUT"
fi
_grn "Đã nối -> $OUT"
