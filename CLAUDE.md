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
