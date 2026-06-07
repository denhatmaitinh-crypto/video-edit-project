#!/usr/bin/env bash
# render-example.sh — Render scene HTML mẫu thành output/example.mp4.
# Dùng để kiểm tra nhanh rằng renderer HTML→video hoạt động.
set -euo pipefail

# Thư mục gốc dự án (cha của scripts/)
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

node "$ROOT/scripts/html-to-video.mjs" \
  "$ROOT/input/example/scene.html" \
  --output "$ROOT/output/example.mp4" \
  --width 1280 --height 720 --fps 30 --duration 4

echo "✔ Đã tạo: $ROOT/output/example.mp4"
