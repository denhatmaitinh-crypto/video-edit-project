# Scripts

Tập hợp các script FFmpeg cho dự án. Tất cả script:

- Nhận tham số đường dẫn (không hardcode)
- Đọc từ `input/`, ghi vào `output/` (tuân theo `CLAUDE.md`)
- Tự tạo thư mục output nếu chưa có
- Báo lỗi rõ ràng khi thiếu file hoặc sai đối số

## Điều kiện tiên quyết

```bash
brew install ffmpeg
```

## Danh sách script

| Script | Chức năng | Cú pháp |
|---|---|---|
| `info.sh` | Xem thông tin video (codec, bitrate, fps, duration) | `info.sh <input>` |
| `thumbnail.sh` | Trích 1 frame làm ảnh thumbnail | `thumbnail.sh <input> <out.jpg> [time]` |
| `trim.sh` | Cắt 1 đoạn video (stream copy, rất nhanh) | `trim.sh <input> <output> <start> <duration>` |
| `compress.sh` | Nén video (H.264 CRF) | `compress.sh <input> <output> [crf=28]` |
| `resize.sh` | Đổi độ phân giải (`-1` để auto) | `resize.sh <input> <output> <width> <height>` |
| `crop.sh` | Cắt khung hình theo pixel | `crop.sh <input> <output> <w> <h> <x> <y>` |
| `rotate.sh` | Xoay 90/180/270 độ | `rotate.sh <input> <output> <degrees>` |
| `speed.sh` | Tăng/giảm tốc độ (cả audio) | `speed.sh <input> <output> <factor>` |
| `concat.sh` | Nối nhiều video | `concat.sh <output> <in1> <in2> [in3...]` |
| `convert.sh` | Đổi định dạng (mp4/mov/webm...) | `convert.sh <input> <output>` |
| `mute.sh` | Bỏ âm thanh khỏi video | `mute.sh <input> <output>` |
| `extract-audio.sh` | Tách audio ra mp3 | `extract-audio.sh <input> <output>` |
| `subtitle-burn.sh` | Ghi cứng phụ đề .srt vào video | `subtitle-burn.sh <input> <output> <sub.srt>` |
| `watermark.sh` | Chèn logo PNG vào góc | `watermark.sh <input> <output> <logo> [pos]` |
| `to-gif.sh` | Chuyển đoạn video thành GIF | `to-gif.sh <input> <output> [start] [dur] [fps] [w]` |

## Ví dụ thực tế

### Pipeline cơ bản

```bash
# 1. Xem thông tin
./scripts/info.sh input/video.mp4

# 2. Cắt 30 giây đầu
./scripts/trim.sh input/video.mp4 output/clip.mp4 00:00:00 00:00:30

# 3. Resize xuống 720p
./scripts/resize.sh output/clip.mp4 output/clip-720p.mp4 -1 720

# 4. Nén cho nhẹ để gửi Zalo/Telegram
./scripts/compress.sh output/clip-720p.mp4 output/clip-final.mp4 30
```

### Làm GIF cho tweet/blog

```bash
./scripts/to-gif.sh input/demo.mp4 output/demo.gif 5 3 15 480
# Từ giây 5, lấy 3 giây, 15fps, rộng 480px
```

### Thêm logo & phụ đề (pipeline branding)

```bash
./scripts/watermark.sh input/video.mp4 output/v1.mp4 assets/logo.png br
./scripts/subtitle-burn.sh output/v1.mp4 output/v2.mp4 assets/sub.srt
```

### Nối nhiều clip rồi nén

```bash
./scripts/concat.sh output/merged.mp4 input/a.mp4 input/b.mp4 input/c.mp4
./scripts/compress.sh output/merged.mp4 output/merged-final.mp4 25
```

## Quy ước

- Nếu cần chain nhiều bước, dùng file trung gian trong `output/`
- Không sửa file trong `input/`
- Thêm script mới: copy mẫu của `trim.sh`, giữ style xử lý arg giống nhau
