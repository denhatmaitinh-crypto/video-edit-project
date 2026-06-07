# video-edit-project

Chỉnh sửa và **tạo video bằng FFmpeg**. Bao gồm một renderer **HTML → video MP4**
dùng Puppeteer (Chrome headless) + FFmpeg — thay thế minh bạch, kiểm chứng được
cho các công cụ HTML→video kéo theo binary đóng không rõ nguồn.

## Cấu trúc

- `input/` — nguồn gốc (video, hoặc trang HTML/CSS để render). Không ghi đè.
- `output/` — kết quả đã xử lý (file `*.mp4` không commit vào git).
- `scripts/` — script tái sử dụng, nhận tham số đường dẫn.

## Yêu cầu

- **Node.js ≥ 20**
- **FFmpeg** — trên macOS: `brew install ffmpeg`.
  Nếu không có sẵn trong PATH, `npm install` sẽ tự kéo `ffmpeg-static` (binary dựng sẵn) để dùng thay.
- `npm install` (cài Puppeteer; Chrome headless được tải tự động).

## Renderer HTML → video

```bash
npm install                 # cài Puppeteer + ffmpeg-static
npm run example             # render input/example/scene.html → output/example.mp4
```

Hoặc gọi trực tiếp:

```bash
node scripts/html-to-video.mjs <input.html | URL> [tùy chọn]
```

| Tùy chọn | Mặc định | Ý nghĩa |
|---|---|---|
| `-o, --output <path>` | `output/<tên>.mp4` | File MP4 đầu ra |
| `--fps <n>` | `30` | Khung hình/giây |
| `--duration <giây>` | `5` | Thời lượng video |
| `--width <px>` | `1920` | Chiều rộng |
| `--height <px>` | `1080` | Chiều cao |
| `--scale <n>` | `1` | Device scale factor (dùng `2` cho retina) |
| `--crf <n>` | `18` | Chất lượng H.264 (0–51, thấp = nét hơn) |
| `--realtime` | tắt | Chụp theo thời gian thực thay vì virtual time |
| `--keep-frames` | tắt | Giữ lại PNG tạm để debug |

### Ví dụ

```bash
# Dọc 9:16 cho mạng xã hội, 60fps, 8 giây
node scripts/html-to-video.mjs input/example/scene.html \
  -o output/intro.mp4 --width 1080 --height 1920 --fps 60 --duration 8

# Render từ một URL
node scripts/html-to-video.mjs https://example.com -o output/page.mp4 --duration 6
```

### Cơ chế

Puppeteer mở trang trong Chrome headless và chụp từng khung hình bằng **virtual time**
của Chrome DevTools Protocol — render **tất định**, không phụ thuộc tốc độ máy, nên
animation luôn mượt và lặp lại y hệt. FFmpeg ghép các PNG thành MP4 (`libx264`,
`yuv420p`, `+faststart`). Dùng `--realtime` nếu animation phụ thuộc đồng hồ thực bên ngoài.

> Toàn bộ phụ thuộc là mã nguồn mở (Puppeteer — Apache-2.0; FFmpeg). Không kéo
> theo binary native đóng/không license.
