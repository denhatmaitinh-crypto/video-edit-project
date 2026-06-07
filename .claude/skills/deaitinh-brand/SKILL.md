---
name: deaitinh-brand
description: Bộ nhận diện thương hiệu và design system của "Để AI Tính" (deaitinh.com) — bảng màu, typography (Fraunces + DM Sans), spacing, style component, nền section xen kẽ, kèm quy tắc giọng văn tiếng Việt và thông tin thương hiệu/social. DÙNG cho MỌI việc mang thương hiệu Để AI Tính: video/intro, ảnh social, bài viết, trang web, slide, hoặc bất kỳ sản phẩm nào gắn brand Để AI Tính. Khi dựng video bằng HyperFrames cho Để AI Tính, kết hợp skill này với skill `hyperframes`.
---

# Để AI Tính — Brand & Design System

> Nguồn sự thật cho nhận diện thương hiệu **Để AI Tính** (deaitinh.com). Áp dụng skill này trước khi chọn màu/font cho bất kỳ sản phẩm nào (video, ảnh, web, slide) thuộc thương hiệu này.

## 1. Thương hiệu

- **Website:** https://deaitinh.com
- **Chủ sở hữu:** Hoàng Nhật Mai (Nhật Mai) — Founder, chuyên gia AI ứng dụng thực chiến, 30+ năm báo chí & marketing.
- **Tagline:** "AI thực chiến cho người làm truyền thông"
- **Định vị:** Chuyên gia AI ứng dụng thực chiến cho dân marketing/PR/truyền thông (practitioner viết cho practitioner, KHÔNG phải kỹ thuật cho developer).
- **Platform web:** WordPress + Flatsome Child Theme.
- **Social:**
  - Facebook: facebook.com/deaitinh
  - Nhóm FB: facebook.com/groups/202304397219813
  - YouTube: youtube.com/@deaitinh
  - TikTok: tiktok.com/@deaitinh

> **Lưu ý quan trọng:** "Yên Lam" là một persona KOC ảo RIÊNG BIỆT (thời trang/lifestyle), KHÔNG dùng trong nội dung Để AI Tính. Hai thương hiệu tách biệt hoàn toàn.

## 2. Bảng màu (Color tokens)

| Token | HEX | Vai trò |
|-------|-----|---------|
| PRIMARY | `#0088EE` | Xanh dương chủ đạo — button, link, accent |
| PRIMARY DARK | `#0055BB` | Xanh đậm — hover, gradient |
| PRIMARY LIGHT | `#E8F4FF` | Xanh nhạt — nền badge, highlight |
| CREAM | `#F6ECD2` | Kem — nền section xen kẽ |
| CREAM DARK | `#EDD9A3` | Kem đậm — border, divider |
| WARM WHITE | `#FDFAF5` | Trắng ấm — nền chính |
| INK | `#1A1A2E` | Đen xanh — text chính, header tối |
| INK MUTED | `#5A5A7A` | Xám — text phụ, subtitle |
| SUCCESS | `#22C55E` | Xanh lá — free badge, success |
| WARNING | `#FF6B35` | Cam — new badge, highlight |

### CSS variables (copy dùng nhanh)

```css
:root{
  --primary:#0088EE; --primary-dark:#0055BB; --primary-light:#E8F4FF;
  --cream:#F6ECD2; --cream-dark:#EDD9A3; --warm-white:#FDFAF5;
  --ink:#1A1A2E; --ink-muted:#5A5A7A;
  --success:#22C55E; --warning:#FF6B35;
}
```

## 3. Typography

- **Display (heading, số liệu lớn):** `Fraunces`, serif
- **Body (text, nav, button, form):** `DM Sans`, sans-serif

| Bậc | Font | Size | Weight | Line-height | Ghi chú |
|-----|------|------|--------|-------------|---------|
| H1 | Fraunces | 52px | 600 | 1.18 | |
| H2 | Fraunces | 36px | 600 | 1.2 | |
| H3 | Fraunces | 24px | 600 | — | |
| H4 | Fraunces | 18px | 600 | — | |
| Body | DM Sans | 16px | 400 | 1.7 | |
| Small | DM Sans | 13px | 400 | — | |
| Label/Tag | DM Sans | 11px | 700 | — | UPPERCASE, letter-spacing 0.5px |

### Nạp font

```css
@import url('https://fonts.googleapis.com/css2?family=Fraunces:ital,wght@0,300;0,400;0,600;0,700;1,400;1,600&family=DM+Sans:wght@300;400;500&display=swap');
body,p,a,li,span,div,button,input,textarea{font-family:'DM Sans',sans-serif;}
h1,h2,h3,h4,h5,h6{font-family:'Fraunces',serif;}
```

> Heading dùng **viết hoa chuẩn tiếng Việt** (không Title Case kiểu Anh).

## 4. Spacing & layout

- Section padding: 80px trên/dưới · 40px trái/phải
- Container max-width: 1280px
- Card padding: 24–36px
- Border-radius card: 10–12px
- Border-radius button: 6px (chữ nhật) hoặc 100px (pill)
- Gap grid 3 cột: 24px · Gap grid 2 cột: 40px

## 5. Component style

**Button Primary:** nền `#0088EE`, chữ `#FFFFFF`, radius 6px, padding 12px 28px, DM Sans 500 / 14px. Hover: nền `#0055BB` + `translateY(-2px)`.

**Button Secondary / Ghost:** nền trong suốt, border 2px `#0088EE`, chữ `#0088EE`. Hover: nền `#E8F4FF`.

**Button Pill (CTA lớn):** radius 100px, padding 14px 32px, `box-shadow: 0 4px 16px rgba(0,136,238,0.3)`.

**Card:** nền `#FFFFFF`, border 1.5px `#E8E8E8`, radius 10px, `box-shadow: 0 4px 16px rgba(0,0,0,0.08)`. Hover: border `#0088EE` + `translateY(-4px)`.

**Section Label/Tag:** nền `#0088EE`, chữ `#FFFFFF`, padding 5px 14px, radius 4px, DM Sans 700 / 11px / UPPERCASE.

**Badge inline:** nền `#E8F4FF`, chữ `#0088EE`, border 1px `rgba(0,136,238,0.2)`, padding 6px 16px, radius 100px, 11px.

## 6. Nền section (thứ tự xen kẽ)

1. `#FDFAF5` — Warm white (default)
2. `#FFFFFF` — Trắng thuần (featured)
3. `#F6ECD2` — Cream (highlight)
4. Gradient `#0088EE → #0055BB` — Blue (khoá học, CTA)
5. `#1A1A2E` — Dark ink (video section, experience)

> Gam "tối sang trọng" cho video/intro: nền **INK `#1A1A2E`** làm chủ đạo, accent **PRIMARY `#0088EE`** và/hoặc **CREAM `#F6ECD2`** để tạo điểm nhấn ấm. Heading Fraunces, nhãn nhỏ DM Sans uppercase.

## 7. Giọng văn & quy tắc nội dung (tiếng Việt)

Khi viết nội dung mang thương hiệu Để AI Tính:

- Ngôi thứ nhất chuyên nghiệp **"tôi"** (không "mình", "anh em").
- **Không** emoji, không văn phong xuề xòa.
- Không chèn tiếng Anh tùy tiện giữa câu tiếng Việt.
- Không em dash, không bullet, không bôi đậm quá đà.
- Đoạn văn tối đa 3 câu.
- Tránh cấu trúc lộ rõ "do AI viết".
- Heading viết hoa chuẩn tiếng Việt (không Title Case).
- Bài LinkedIn không bắt đầu bằng "Tôi".
- Câu credit cố định cho nội dung sưu tầm: `(Clip sưu tầm & bình luận bởi Để AI Tính)`.
- Cuối bài viết: khối chữ ký tác giả kèm link social.

**Nguyên tắc cốt lõi:** Độ chính xác là bất di bất dịch — chủ động cảnh báo claim chưa kiểm chứng, tên tính năng bịa, hoặc số liệu phóng đại trước khi xuất bản. Mặc định xuất plain text trừ khi được yêu cầu định dạng khác.

## 8. Cách dùng skill này với HyperFrames

Khi dựng video/intro cho Để AI Tính trong `studio/`:

1. Lấy màu/font từ skill này (đừng đoán).
2. Nạp Fraunces + DM Sans bằng `@import` ở trên trong `<style>` của composition.
3. Theo skill `hyperframes` cho cấu trúc `data-*`, timeline GSAP, và quy trình lint → preview → render.
4. Render ra `output/` theo quy ước repo.
