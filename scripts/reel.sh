#!/usr/bin/env bash
# reel.sh — GÓI EDIT MẶC ĐỊNH cho reel kênh "Để AI Tính".
# Gồm: polish (màu + nét + chuẩn loudness -14 LUFS) + motion graphic
#      (tiêu đề động đầu video + thanh tiến trình) + nhạc nền an toàn
#      (tự tổng hợp nếu không có file) + SFX whoosh + fade mượt + faststart.
#
# Dùng:  ./scripts/reel.sh <video> ["Tiêu đề"] ["Phụ đề"] [nhac.mp3] [output]
# Ví dụ: ./scripts/reel.sh input/1.mp4 "MANUS" "AI tự động hoá công việc"
#        ./scripts/reel.sh input/1.mp4 "" "" input/nhac_cua_toi.mp3   # dùng nhạc riêng, không tiêu đề
#
# Bỏ qua tiêu đề: để chuỗi rỗng "" -> chỉ polish + progress bar + nhạc.
# Không nhạc:     đặt NO_MUSIC=1 ở đầu lệnh.

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
need_ffmpeg

IN="${1:-}"; TITLE="${2:-}"; SUB="${3:-}"; MUSIC="${4:-}"
OUT="${5:-$(default_out "$IN" "reel" "mp4")}"
[[ -n "$IN" ]] || die "Dùng: ./scripts/reel.sh <video> [\"Tiêu đề\"] [\"Phụ đề\"] [nhac.mp3] [output]"
need_file "$IN"; guard_not_input "$OUT"

ASSETS="$PROJECT_ROOT/assets"; mkdir -p "$ASSETS"
FONT_B="$ASSETS/BeVietnamPro-Bold.ttf"
FONT_S="$ASSETS/BeVietnamPro-SemiBold.ttf"
# Tải font đẹp (OFL) nếu chưa có; nếu mạng chặn thì fallback font hệ thống
if [[ ! -f "$FONT_B" ]]; then
  curl -sL -o "$FONT_B" "https://raw.githubusercontent.com/google/fonts/main/ofl/bevietnampro/BeVietnamPro-Bold.ttf" || true
  curl -sL -o "$FONT_S" "https://raw.githubusercontent.com/google/fonts/main/ofl/bevietnampro/BeVietnamPro-SemiBold.ttf" || true
fi
[[ -s "$FONT_B" ]] || FONT_B="/System/Library/Fonts/Supplemental/Arial Unicode.ttf"
[[ -f "$FONT_B" ]] || FONT_B="/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
[[ -s "$FONT_S" ]] || FONT_S="$FONT_B"

DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$IN")
FO=$(awk "BEGIN{printf \"%.2f\", $DUR-0.5}")   # mốc fade out

# --- Nhạc nền ---
TMPM="$(mktemp --suffix=.wav)"; TMPW="$(mktemp --suffix=.wav)"
if [[ "${NO_MUSIC:-0}" != "1" ]]; then
  if [[ -n "$MUSIC" && -f "$MUSIC" ]]; then
    cp "$MUSIC" "$TMPM"
  else
    # Ambient pad tổng hợp (CC0/an toàn), dài bằng video
    ffmpeg -hide_banner -loglevel error -y \
      -f lavfi -i "sine=frequency=220:duration=$DUR" \
      -f lavfi -i "sine=frequency=261.63:duration=$DUR" \
      -f lavfi -i "sine=frequency=329.63:duration=$DUR" \
      -filter_complex "[0][1][2]amix=inputs=3:normalize=0,tremolo=f=0.2:d=0.4,aecho=0.8:0.7:80:0.3,lowpass=f=900,highpass=f=80,volume=0.35,afade=t=in:d=2,afade=t=out:st=$(awk "BEGIN{print $DUR-2}"):d=2[a]" \
      -map "[a]" "$TMPM"
  fi
fi
# SFX whoosh cho tiêu đề
ffmpeg -hide_banner -loglevel error -y -f lavfi -i "anoisesrc=d=0.6:c=pink:a=0.6" \
  -af "highpass=f=250,lowpass=f=7000,afade=t=in:d=0.08,afade=t=out:st=0.3:d=0.3,volume=0.5" "$TMPW"

# --- Lớp motion graphic (video) ---
ALPHA='if(lt(t\,0.35)\,t/0.35\,if(lt(t\,2.25)\,1\,max(0\,(2.6-t)/0.35)))'
VF="eq=contrast=1.05:saturation=1.07,unsharp=5:5:0.4:5:5:0.0"
VF="$VF,drawbox=x=0:y=ih-10:w=iw*t/$DUR:h=10:color=DodgerBlue@0.9:t=fill"
if [[ -n "$TITLE" ]]; then
  VF="$VF,drawtext=fontfile=$FONT_B:text='$TITLE':fontcolor=white:fontsize=96:x=(w-text_w)/2:y=180:box=1:boxcolor=black@0.35:boxborderw=24:alpha=$ALPHA:enable=lt(t\,2.7)"
  [[ -n "$SUB" ]] && VF="$VF,drawtext=fontfile=$FONT_S:text='$SUB':fontcolor=0x9FE0FF:fontsize=44:x=(w-text_w)/2:y=300:alpha=$ALPHA:enable=lt(t\,2.7)"
fi
VF="$VF,fade=t=in:st=0:d=0.3,fade=t=out:st=$FO:d=0.5,format=yuv420p"

# --- Trộn âm thanh ---
if [[ "${NO_MUSIC:-0}" != "1" ]]; then
  ffmpeg -hide_banner -loglevel error -y -i "$IN" -i "$TMPM" -i "$TMPW" \
    -filter_complex "[0:v]$VF[v];[1:a]volume=1.0[mus];[0:a]asplit=2[voice][key];[mus][key]sidechaincompress=threshold=0.02:ratio=8:attack=15:release=400[musd];[2:a]adelay=100|100,volume=0.6[wh];[voice][musd][wh]amix=inputs=3:normalize=0:duration=first,loudnorm=I=-14:TP=-1.5:LRA=11,afade=t=in:st=0:d=0.3,afade=t=out:st=$FO:d=0.5[a]" \
    -map "[v]" -map "[a]" -c:v libx264 -preset slow -crf 19 -c:a aac -b:a 192k -movflags +faststart "$OUT"
else
  ffmpeg -hide_banner -loglevel error -y -i "$IN" \
    -filter_complex "[0:v]$VF[v];[0:a]loudnorm=I=-14:TP=-1.5:LRA=11,afade=t=in:st=0:d=0.3,afade=t=out:st=$FO:d=0.5[a]" \
    -map "[v]" -map "[a]" -c:v libx264 -preset slow -crf 19 -c:a aac -b:a 192k -movflags +faststart "$OUT"
fi
rm -f "$TMPM" "$TMPW"
_grn "Đã xuất reel (motion + nhạc + SFX + polish) -> $OUT"
