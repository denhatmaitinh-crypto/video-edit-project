#!/usr/bin/env bash
# audio.sh — Thao tác âm thanh: nhạc nền, chỉnh âm lượng, tách/bỏ tiếng, fade.
# Dùng:  ./scripts/audio.sh <lệnh_con> ...
#
# Các lệnh con:
#   music   <video> <nhac.mp3> [output] [vol]   Thêm nhạc nền, tự hạ nhạc khi có tiếng nói
#                                               vol = âm lượng nhạc (mặc định 0.3)
#   volume  <video> <hệ_số> [output]            Tăng/giảm tiếng gốc (1.0=giữ, 1.5=to hơn, 0.5=nhỏ)
#   extract <video> [output.mp3]                Tách audio ra file mp3
#   mute    <video> [output]                    Bỏ toàn bộ tiếng
#   fade    <video> [giây] [output]             Fade in/out âm thanh (mặc định 2 giây mỗi đầu)
#
# Ví dụ:
#   ./scripts/audio.sh music input/1.mp4 input/nhac.mp3
#   ./scripts/audio.sh volume input/1.mp4 1.5
#   ./scripts/audio.sh extract input/1.mp4
#   ./scripts/audio.sh mute input/1.mp4
#   ./scripts/audio.sh fade input/1.mp4 3

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
need_ffmpeg

CMD="${1:-}"; shift || true
case "$CMD" in
  music)
    IN="${1:-}"; MUS="${2:-}"; OUT="${3:-$(default_out "$IN" "music" "mp4")}"; VOL="${4:-0.3}"
    [[ -n "$IN" && -n "$MUS" ]] || die "Dùng: audio.sh music <video> <nhac.mp3> [output] [vol]"
    need_file "$IN"; need_file "$MUS"; guard_not_input "$OUT"
    # sidechaincompress: tự hạ nhạc khi có giọng nói trong video
    ffmpeg -hide_banner -y -i "$IN" -i "$MUS" -filter_complex \
"[1:a]volume=${VOL}[m];[0:a][m]sidechaincompress=threshold=0.03:ratio=6:attack=20:release=300[mix]" \
      -map 0:v -map "[mix]" -c:v copy -c:a aac -b:a 192k -shortest "$OUT"
    _grn "Đã thêm nhạc nền -> $OUT" ;;

  volume)
    IN="${1:-}"; F="${2:-}"; OUT="${3:-$(default_out "$IN" "vol" "mp4")}"
    [[ -n "$IN" && -n "$F" ]] || die "Dùng: audio.sh volume <video> <hệ_số> [output]"
    need_file "$IN"; guard_not_input "$OUT"
    ffmpeg -hide_banner -y -i "$IN" -af "volume=${F}" -c:v copy -c:a aac -b:a 192k "$OUT"
    _grn "Đã chỉnh âm lượng x${F} -> $OUT" ;;

  extract)
    IN="${1:-}"; OUT="${2:-$(default_out "$IN" "audio" "mp3")}"
    [[ -n "$IN" ]] || die "Dùng: audio.sh extract <video> [output.mp3]"
    need_file "$IN"; guard_not_input "$OUT"
    ffmpeg -hide_banner -y -i "$IN" -vn -c:a libmp3lame -q:a 2 "$OUT"
    _grn "Đã tách audio -> $OUT" ;;

  mute)
    IN="${1:-}"; OUT="${2:-$(default_out "$IN" "mute" "mp4")}"
    [[ -n "$IN" ]] || die "Dùng: audio.sh mute <video> [output]"
    need_file "$IN"; guard_not_input "$OUT"
    ffmpeg -hide_banner -y -i "$IN" -an -c:v copy "$OUT"
    _grn "Đã bỏ tiếng -> $OUT" ;;

  fade)
    IN="${1:-}"; D="${2:-2}"; OUT="${3:-$(default_out "$IN" "fade" "mp4")}"
    [[ -n "$IN" ]] || die "Dùng: audio.sh fade <video> [giây] [output]"
    need_file "$IN"; guard_not_input "$OUT"
    dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$IN")
    st=$(echo "$dur - $D" | bc -l)
    ffmpeg -hide_banner -y -i "$IN" \
      -af "afade=t=in:st=0:d=${D},afade=t=out:st=${st}:d=${D}" \
      -c:v copy -c:a aac -b:a 192k "$OUT"
    _grn "Đã fade âm thanh ${D}s -> $OUT" ;;

  *)
    die "Lệnh con không hợp lệ. Xem hướng dẫn ở đầu file: music | volume | extract | mute | fade" ;;
esac
