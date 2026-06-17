# Skills đã cài vào repo

Các skill markdown dưới đây tự động được Claude Code nạp khi làm việc trong repo này
(cả phiên web lẫn local). Mỗi thư mục con có `SKILL.md` với frontmatter `name`/`description`.

## Nguồn

| Skill (thư mục) | Nguồn | Mô tả |
|---|---|---|
| `humanizer` | github.com/blader/humanizer | Nhận diện 33 pattern văn AI và viết lại tự nhiên hơn |
| `design-taste-frontend` | github.com/Leonxlnx/taste-skill | Chống "slop" thiết kế frontend (layout, typography, motion có gu) |
| `cro`, `copywriting`, `seo-audit`, `video`, `social`, ... (44 skill) | github.com/coreyhaines31/marketingskills | Bộ skill marketing: CRO, copywriting, SEO, analytics, growth |

> Đã loại thư mục `evals/` của bộ marketing để giảm dung lượng (chỉ dùng để test skill,
> không cần lúc chạy). Muốn lấy lại: clone repo gốc.

## Cách dùng

Chỉ cần mô tả việc cần làm, Claude sẽ tự chọn skill phù hợp. Ví dụ:
- "viết lại đoạn này cho tự nhiên" → `humanizer`
- "thiết kế landing page" → `design-taste-frontend`
- "tối ưu trang bán hàng / viết copy / audit SEO" → các skill marketing

---

## 2 công cụ còn lại — cài ở MÁY (không nằm trong repo)

Đây là plugin/MCP cần chạy nền nên không commit vào repo; cài trực tiếp trong
Claude Code trên máy bạn:

### Caveman (nén output token ~65%)
```bash
curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.sh | bash
# Yêu cầu Node >= 18. Kích hoạt: /caveman [lite|full|ultra]
```

### Claude-mem (trí nhớ xuyên phiên)
```
/plugin marketplace add thedotmack/claude-mem
/plugin install claude-mem
# Hoặc: npx claude-mem install   (cần Node >= 20). Khởi động lại Claude Code sau khi cài.
```
