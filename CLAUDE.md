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

## HyperFrames — tạo video từ HTML

Dự án tích hợp [HyperFrames](https://github.com/heygen-com/hyperframes): viết HTML/CSS/animation → render ra MP4 (deterministic, cùng input → cùng output).

- **Project HyperFrames:** thư mục `studio/` (composition `index.html`, các cảnh con trong `studio/compositions/`, assets trong `studio/assets/`).
- **Skills cho AI agent:** đã cài ở `studio/.agents/skills/` và liên kết vào `.claude/skills/`. Có sẵn các slash-command như `/hyperframes`, `/hyperframes-cli`, `/hyperframes-media`, `/gsap`...
- **Yêu cầu hệ thống:** Node.js 22+, FFmpeg, và headless Chrome (`npx hyperframes browser ensure`). Kiểm tra bằng `npx hyperframes doctor`.

### Lệnh thường dùng (chạy trong `studio/`)

```bash
npm run dev                          # preview trên browser, live reload (long-running)
npm run check                        # lint + validate + inspect
npx hyperframes render . -o ../output/<ten>.mp4   # render ra output/
```

> Quy ước thư mục vẫn áp dụng: video gốc để ở `input/`, kết quả render ghi vào `output/`.

## Cách giao việc cho Claude khi cần hỗ trợ edit video

Khi cần tôi hỗ trợ, hãy mô tả theo các ý sau (càng rõ càng tốt) — tôi sẽ tự gọi skill `/hyperframes` phù hợp:

1. **Mục tiêu & nội dung:** loại video (intro, quảng cáo, giải thích, caption...), thông điệp/kịch bản chính.
2. **Thời lượng & tỉ lệ:** ví dụ "15 giây, dọc 1080×1920 cho TikTok" hoặc "30 giây ngang 1080p".
3. **Phong cách:** màu sắc, tông (corporate/neon/tối sang...), font, có nhạc/voiceover không.
4. **Nguồn liệu:** file trong `input/`, ảnh/logo, hoặc một URL website cần dựng thành video (`/website-to-hyperframes`).
5. **Đầu ra mong muốn:** tên file trong `output/`, chất lượng (draft/standard/high).

Ví dụ giao việc tốt:
> "Dùng /hyperframes tạo intro 12 giây ngang 1080p giới thiệu kênh 'ABC Studio', tông tối sang trọng, có nhạc nền nhẹ, render vào output/intro-abc.mp4."
