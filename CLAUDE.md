# Video Edit Project

Dự án chỉnh sửa video sử dụng FFmpeg trên macOS.

## Cấu trúc thư mục

- `input/` — chứa các file video gốc chưa xử lý
- `output/` — chứa các file video đã qua xử lý
- `scripts/` — chứa các script (shell/FFmpeg) để thực hiện các thao tác chỉnh sửa

## Môi trường

- Hệ điều hành: macOS (Darwin)
- Công cụ chính: FFmpeg
- Shell: zsh

## Quy ước

- Không ghi đè file trong `input/` — đây là nguồn gốc cần giữ nguyên
- Kết quả xử lý luôn ghi vào `output/`
- Các script tái sử dụng được đặt trong `scripts/` và nên nhận tham số đường dẫn thay vì hardcode

---

## Cách làm việc qua Claude Code web (QUAN TRỌNG — đọc trước khi edit)

Người dùng (denhatmaitinh@gmail.com) thường ra lệnh từ app web. Môi trường cloud là
container Linux tạm thời, **không phải máy Mac**, và có các ràng buộc sau:

- **Mạng bị giới hạn:** chỉ `github.com` / `raw.githubusercontent.com` / `googleapis.com`
  truy cập được. **Google Drive (`drive.google.com`) bị chặn** → KHÔNG tải video từ Drive
  trực tiếp. Tải base64 qua MCP cũng không khả thi vì file video quá lớn cho ngữ cảnh.
- **FFmpeg chưa cài sẵn:** mỗi phiên tải bản static từ GitHub:
  `https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linux64-gpl.tar.xz`
  rồi copy `ffmpeg`/`ffprobe` vào `/usr/local/bin/`.

### Luồng chuyển file (chốt)
1. **Nhận video:** người dùng upload file vào `input/` trên GitHub (kéo–thả qua link
   `.../upload/<branch>/input`). File < 100MB là OK.
2. **Edit:** mình kéo về (`git pull`), xử lý bằng FFmpeg trong container.
3. **Trả kết quả:** `git add -f output/<file>` rồi push; đưa người dùng link
   `https://github.com/denhatmaitinh-crypto/video-edit-project/raw/<branch>/output/<file>`
   để tải về (output/ bị .gitignore nên phải `-f`).

## Tự nhận diện nhu cầu (để người dùng không phải tả lại từ đầu)

Khi người dùng thả video mới + nói ngắn (hoặc không nói gì), mặc định hiểu như sau:

- **Kênh:** "Để AI Tính" — nội dung AI thực chiến cho người làm truyền thông.
- **Định dạng mặc định:** dọc 9:16 (TikTok/Reels/Shorts). Giữ nguyên nếu video đã 9:16.
- **GÓI MẶC ĐỊNH = `scripts/reel.sh`** (người dùng đã chốt): polish (màu + nét +
  loudness −14 LUFS) + motion graphic mức "vừa phải" (tiêu đề động đầu video + thanh
  tiến trình) + **nhạc nền an toàn tự tổng hợp** (không bản quyền) + SFX whoosh + fade + faststart.
  - Lệnh: `./scripts/reel.sh input/<video> "Tiêu đề" "Phụ đề"`
- **Nhạc:** người dùng chọn "nhạc an toàn, mình tự lo" → dùng nhạc CC0/tổng hợp, KHÔNG
  dùng nhạc có bản quyền. Nếu họ gửi file nhạc riêng thì truyền vào tham số thứ 4.
- **Phông chữ:** Be Vietnam Pro (tải về `assets/`), màu nhấn DodgerBlue.
- **Giới hạn cần nói thật:** phụ đề/chữ đã "in chết" trong video gốc thì FFmpeg không sửa
  được; motion graphic FFmpeg ở mức "lite", không bằng After Effects.

### Quy trình chuẩn mỗi lần edit
1. `ffprobe`/`info.sh` để nhận diện video.
2. Trích vài khung hình bằng ffmpeg rồi tự xem để hiểu nội dung.
3. Đề xuất ngắn gọn + chạy `reel.sh` (hoặc script phù hợp).
4. Trích khung hình/so sánh để người dùng duyệt, rồi push file lên GitHub kèm link tải.

## Bộ script (xem `scripts/README.md`)
`info` · `trim` · `concat` · `compress` · `vertical` · `subtitle` · `text` ·
`watermark` · `audio` · `effects` · **`reel` (gói mặc định)**.
