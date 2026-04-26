# Ngũ Hành Sơn — Đà Nẵng (p5.js)

Cảnh đường phố Đà Nẵng vẽ bằng p5.js: 5 ngọn núi đá vôi, biển Đông phía sau,
phố phường nhiều cây xanh, ô tô chạy hai chiều, đèn giao thông hoạt động,
người đi bộ trên vỉa hè và sang đường khi đèn đỏ.

## Chạy thử

Mở `p5/index.html` bằng trình duyệt. Không cần build hay server tĩnh nào — file
p5.js được tải trực tiếp từ CDN.

```sh
open p5/index.html      # macOS
```

## Tuỳ biến nhanh

Mọi thứ nằm trong `p5/sketch.js`:

- `mountains` — vị trí, chiều cao và sắc độ 5 ngọn núi
- `cars` / `spawnCar()` — màu xe, tốc độ, kiểu xe (`sedan` / `suv`)
- `trafficLight.durations` — thời lượng từng pha đèn (đơn vị frame, 60fps)
- `trees` — số lượng/kích thước cây xanh hai bên đường và phía xa
- `pedestrians` — người đi bộ trên vỉa hè và người sang đường
