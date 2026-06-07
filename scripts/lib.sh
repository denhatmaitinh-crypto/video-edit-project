#!/usr/bin/env bash
# lib.sh — Hàm dùng chung cho tất cả script edit video.
# Được các script khác `source`, không chạy trực tiếp.

set -euo pipefail

# Thư mục gốc dự án (cha của thư mục scripts/)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INPUT_DIR="$PROJECT_ROOT/input"
OUTPUT_DIR="$PROJECT_ROOT/output"

# Màu cho thông báo
_red()  { printf "\033[31m%s\033[0m\n" "$*"; }
_grn()  { printf "\033[32m%s\033[0m\n" "$*"; }
_ylw()  { printf "\033[33m%s\033[0m\n" "$*"; }

die() { _red "Lỗi: $*" >&2; exit 1; }

# Kiểm tra ffmpeg/ffprobe đã cài chưa
need_ffmpeg() {
  command -v ffmpeg  >/dev/null 2>&1 || die "Chưa cài ffmpeg. Cài bằng: brew install ffmpeg"
  command -v ffprobe >/dev/null 2>&1 || die "Chưa cài ffprobe (đi kèm ffmpeg)."
}

# Kiểm tra file đầu vào tồn tại
need_file() {
  [[ -f "$1" ]] || die "Không tìm thấy file: $1"
}

# Tạo thư mục output nếu chưa có
ensure_output() { mkdir -p "$OUTPUT_DIR"; }

# Lấy tên file không kèm phần mở rộng
stem() { local b; b="$(basename "$1")"; printf "%s" "${b%.*}"; }

# Sinh đường dẫn output mặc định: output/<stem>_<suffix>.<ext>
# Dùng: out=$(default_out "$INPUT" "trim" "mp4")
default_out() {
  ensure_output
  local in="$1" suffix="$2" ext="${3:-mp4}"
  printf "%s/%s_%s.%s" "$OUTPUT_DIR" "$(stem "$in")" "$suffix" "$ext"
}

# Chặn ghi đè file trong input/ (quy ước dự án: không đụng nguồn gốc)
guard_not_input() {
  case "$(cd "$(dirname "$1")" && pwd)" in
    "$INPUT_DIR"|"$INPUT_DIR"/*) die "Không được ghi đè vào input/. Hãy xuất ra output/." ;;
  esac
}
