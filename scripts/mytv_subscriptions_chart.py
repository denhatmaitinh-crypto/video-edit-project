"""Biểu đồ cột số thuê bao MyTV theo tỉnh — tháng 4/2026."""

import matplotlib.pyplot as plt

provinces = ["Hà Nội", "TP HCM", "Đà Nẵng", "Hải Phòng", "Cần Thơ", "Các tỉnh khác"]
subscribers = [1_850_000, 1_420_000, 380_000, 290_000, 210_000, 1_850_000]
growth = [3.2, 2.8, 5.1, 1.9, -0.4, 2.1]

colors = ["#2ecc71" if g > 0 else "#e74c3c" for g in growth]

fig, ax = plt.subplots(figsize=(11, 6))
bars = ax.bar(provinces, subscribers, color=colors, edgecolor="black")

for bar, sub, g in zip(bars, subscribers, growth):
    ax.text(
        bar.get_x() + bar.get_width() / 2,
        bar.get_height() + 30_000,
        f"{sub:,}\n({g:+.1f}%)",
        ha="center",
        va="bottom",
        fontsize=9,
    )

ax.set_title("Thuê bao MyTV theo tỉnh — tháng 4/2026", fontsize=14, fontweight="bold")
ax.set_ylabel("Số thuê bao")
ax.set_xlabel("Tỉnh / Thành phố")
ax.yaxis.set_major_formatter(plt.FuncFormatter(lambda x, _: f"{int(x):,}"))
ax.grid(axis="y", linestyle="--", alpha=0.5)

plt.tight_layout()
plt.savefig("output/mytv_subscriptions_2026_04.png", dpi=150)
print("Đã lưu biểu đồ vào output/mytv_subscriptions_2026_04.png")
print(f"Tổng thuê bao toàn quốc: {sum(subscribers):,}")
