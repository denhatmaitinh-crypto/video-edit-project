#!/usr/bin/env bash
# effects.sh — Hiệu ứng hình ảnh: đổi tốc độ, lọc màu, fade hình, xoay.
# Dùng:  ./scripts/effects.sh <lệnh_con> ...
#
# Các lệnh con:
#   speed   <video> <hệ_số> [output]    Đổi tốc độ (2=nhanh gấp đôi, 0.5=chậm một nửa). Đồng bộ cả tiếng.
#   color   <video> [preset] [output]   Lọc màu: vivid | warm | cool | bw | cinematic (mặc định vivid)
#   fade    <video> [giây] [output]     Fade in/out HÌNH (đen) ở đầu & cuối (mặc định 1 giây)
#   rotate  <video> <90|180|270> [out]  Xoay video
#
# Ví dụ:
#   ./scripts/effects.sh speed input/1.mp4 1.5
#   ./scripts/effects.sh color input/1.mp4 cinematic
#   ./scripts/effects.sh fade  input/1.mp4 1.5
#   ./scripts/effects.sh rotate input/1.mp4 90

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
need_ffmpeg

CMD="${1:-}"; shift || true
case "$CMD" in
  speed)
    IN="${1:-}"; S="${2:-}"; OUT="${3:-$(default_out "$IN" "speed" "mp4")}"
    [[ -n "$IN" && -n "$S" ]] || die "Dùng: effects.sh speed <video> <hệ_số> [output]"
    need_file "$IN"; guard_not_input "$OUT"
    # video: pts chia cho hệ số; audio: atempo (ghép cho hệ số ngoài [0.5,2])
    pts=$(echo "1/$S" | bc -l)
    at="$S"; atempo=""
    # atempo chỉ nhận 0.5..2.0, tách thành chuỗi nếu vượt
    awk "BEGIN{s=$S; while(s>2.0){printf \"atempo=2.0,\"; s/=2} while(s<0.5){printf \"atempo=0.5,\"; s*=2} printf \"atempo=%g\", s}" > /tmp/_atempo.$$
    atempo=$(cat /tmp/_atempo.$$); rm -f /tmp/_atempo.$$
    ffmpeg -hide_banner -y -i "$IN" \
      -filter_complex "[0:v]setpts=${pts}*PTS[v];[0:a]${atempo}[a]" \
      -map "[v]" -map "[a]" -c:v libx264 -preset medium -crf 20 -c:a aac -b:a 192k "$OUT"
    _grn "Đã đổi tốc độ x${S} -> $OUT" ;;

  color)
    IN="${1:-}"; P="${2:-vivid}"; OUT="${3:-$(default_out "$IN" "color" "mp4")}"
    [[ -n "$IN" ]] || die "Dùng: effects.sh color <video> [vivid|warm|cool|bw|cinematic] [output]"
    need_file "$IN"; guard_not_input "$OUT"
    case "$P" in
      vivid)     VF="eq=saturation=1.4:contrast=1.1" ;;
      warm)      VF="colortemperature=temperature=5500,eq=saturation=1.1" ;;
      cool)      VF="colortemperature=temperature=8000,eq=saturation=1.05" ;;
      bw)        VF="hue=s=0,eq=contrast=1.15" ;;
      cinematic) VF="curves=preset=medium_contrast,eq=saturation=0.95:contrast=1.1,vignette" ;;
      *) die "Preset không hợp lệ: vivid|warm|cool|bw|cinematic" ;;
    esac
    ffmpeg -hide_banner -y -i "$IN" -vf "$VF" \
      -c:v libx264 -preset medium -crf 20 -c:a copy "$OUT"
    _grn "Đã lọc màu ($P) -> $OUT" ;;

  fade)
    IN="${1:-}"; D="${2:-1}"; OUT="${3:-$(default_out "$IN" "vfade" "mp4")}"
    [[ -n "$IN" ]] || die "Dùng: effects.sh fade <video> [giây] [output]"
    need_file "$IN"; guard_not_input "$OUT"
    dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$IN")
    st=$(echo "$dur - $D" | bc -l)
    ffmpeg -hide_banner -y -i "$IN" \
      -vf "fade=t=in:st=0:d=${D},fade=t=out:st=${st}:d=${D}" \
      -c:v libx264 -preset medium -crf 20 -c:a copy "$OUT"
    _grn "Đã fade hình ${D}s -> $OUT" ;;

  rotate)
    IN="${1:-}"; A="${2:-}"; OUT="${3:-$(default_out "$IN" "rotate" "mp4")}"
    [[ -n "$IN" && -n "$A" ]] || die "Dùng: effects.sh rotate <video> <90|180|270> [output]"
    need_file "$IN"; guard_not_input "$OUT"
    case "$A" in
      90)  TR="transpose=1" ;;
      180) TR="transpose=1,transpose=1" ;;
      270) TR="transpose=2" ;;
      *) die "Góc phải là 90, 180 hoặc 270" ;;
    esac
    ffmpeg -hide_banner -y -i "$IN" -vf "$TR" \
      -c:v libx264 -preset medium -crf 20 -c:a copy "$OUT"
    _grn "Đã xoay ${A}° -> $OUT" ;;

  *)
    die "Lệnh con không hợp lệ: speed | color | fade | rotate" ;;
esac
