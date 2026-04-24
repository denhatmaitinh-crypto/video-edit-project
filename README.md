# video-edit-project

Dự án chỉnh sửa video bằng **FFmpeg** trên macOS, điều khiển bằng các shell script.

## Cài đặt

```bash
brew install ffmpeg
```

## Cấu trúc

```
video-edit-project/
├── input/       # Video gốc (không sửa, không commit)
├── output/      # Kết quả xử lý (không commit)
├── scripts/     # 15 script FFmpeg có thể tái sử dụng
├── CLAUDE.md    # Hướng dẫn cho Claude Code
└── README.md
```

## Dùng nhanh

```bash
# Copy video vào input/
cp ~/Downloads/video.mp4 input/

# Xem danh sách script và cú pháp
cat scripts/README.md

# Ví dụ: cắt 10 giây đầu
./scripts/trim.sh input/video.mp4 output/cat.mp4 00:00:00 00:00:10
```

Xem [`scripts/README.md`](scripts/README.md) cho toàn bộ danh sách 15 script & ví dụ pipeline.
