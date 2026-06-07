# Bộ script edit video (FFmpeg)

Các script tái sử dụng cho dự án. Tất cả **nhận tham số đường dẫn**, luôn ghi kết quả vào
`output/` và **không bao giờ đụng vào `input/`** (đúng quy ước trong `CLAUDE.md`).

## Cài đặt (chỉ làm 1 lần trên máy Mac)

```bash
brew install ffmpeg          # cài FFmpeg + ffprobe
chmod +x scripts/*.sh        # cấp quyền chạy cho các script
```

## Quy trình chung

1. Bỏ video gốc vào `input/`
2. Chạy script tương ứng — kết quả tự xuất ra `output/`
3. Không cần đặt tên output; mỗi script tự đặt `output/<tên>_<thaotac>.mp4`
   (bạn vẫn có thể truyền tên output riêng nếu muốn)

## Danh sách script

| Script | Công dụng | Ví dụ |
|--------|-----------|-------|
| `info.sh` | Nhận diện video (độ phân giải, fps, thời lượng, codec, audio) | `./scripts/info.sh input/1.mp4` |
| `trim.sh` | Cắt một đoạn | `./scripts/trim.sh input/1.mp4 00:00:05 00:00:20` |
| `concat.sh` | Nối nhiều clip | `./scripts/concat.sh output/ghep.mp4 input/a.mp4 input/b.mp4` |
| `compress.sh` | Nén/giảm dung lượng | `./scripts/compress.sh input/1.mp4 24` |
| `vertical.sh` | Chuyển dọc 9:16 (TikTok/Reels) | `./scripts/vertical.sh input/1.mp4` |
| `subtitle.sh` | Gắn phụ đề (.srt) | `./scripts/subtitle.sh input/1.mp4 input/1.srt` |
| `text.sh` | Chèn chữ lên hình | `./scripts/text.sh input/1.mp4 "Để AI Tính" top` |
| `watermark.sh` | Chèn logo | `./scripts/watermark.sh input/1.mp4 input/logo.png tr` |
| `audio.sh` | Nhạc nền / âm lượng / tách tiếng / fade | `./scripts/audio.sh music input/1.mp4 input/nhac.mp3` |
| `effects.sh` | Tốc độ / lọc màu / fade hình / xoay | `./scripts/effects.sh color input/1.mp4 cinematic` |
| `reel.sh` | **Gói mặc định**: polish + motion graphic + nhạc nền an toàn + SFX | `./scripts/reel.sh input/1.mp4 "MANUS" "AI tự động hoá công việc"` |

> Mỗi script đều có hướng dẫn chi tiết và các tùy chọn nâng cao ghi ở **đầu file**.
> Chạy script không kèm tham số để xem cú pháp.

## Ghép nhiều thao tác (pipeline)

Output của bước này là input của bước sau. Ví dụ: cắt → chuyển dọc → chèn chữ → thêm nhạc:

```bash
./scripts/trim.sh     input/1.mp4 00:00:10 00:00:30 output/b1.mp4
./scripts/vertical.sh output/b1.mp4               output/b2.mp4
./scripts/text.sh     output/b2.mp4 "Tiêu đề" top  output/b3.mp4
./scripts/audio.sh    music output/b3.mp4 input/nhac.mp3 output/final.mp4
```
