#!/usr/bin/env node
/**
 * html-to-video.mjs — Render một trang HTML/CSS (file cục bộ hoặc URL) thành video MP4.
 *
 * Cơ chế: Puppeteer mở trang trong Chrome headless, chụp từng khung hình bằng
 * "virtual time" của Chrome DevTools Protocol (render tất định, không phụ thuộc
 * tốc độ máy), rồi FFmpeg ghép các khung hình thành MP4 (libx264, yuv420p).
 *
 * Toàn bộ phụ thuộc đều là mã nguồn mở, kiểm chứng được:
 *   - puppeteer      (Apache-2.0) — điều khiển Chrome
 *   - ffmpeg-static  (tùy chọn)   — binary FFmpeg dựng sẵn; nếu không có sẽ dùng
 *                                   ffmpeg trong PATH của hệ thống.
 *
 * Quy ước dự án (CLAUDE.md):
 *   - Nguồn (HTML) nằm trong input/, không ghi đè.
 *   - Kết quả luôn ghi ra output/.
 *   - Script nhận tham số đường dẫn, không hardcode.
 *
 * Dùng:
 *   node scripts/html-to-video.mjs <input.html | URL> [tùy chọn]
 *
 * Tùy chọn:
 *   -o, --output <path>   File MP4 đầu ra        (mặc định: output/<tên>.mp4)
 *   --fps <n>             Khung hình/giây         (mặc định: 30)
 *   --duration <giây>     Thời lượng video        (mặc định: 5)
 *   --width <px>          Chiều rộng              (mặc định: 1920)
 *   --height <px>         Chiều cao               (mặc định: 1080)
 *   --scale <n>           Device scale factor     (mặc định: 1; dùng 2 cho retina)
 *   --crf <n>             Chất lượng H.264 (0–51, thấp = nét hơn, mặc định: 18)
 *   --realtime           Chụp theo thời gian thực thay vì virtual time
 *                        (dùng khi animation phụ thuộc thời gian thực bên ngoài)
 *   --keep-frames        Giữ lại thư mục PNG tạm (để debug)
 *   -h, --help           In trợ giúp
 *
 * Ví dụ:
 *   node scripts/html-to-video.mjs input/example/scene.html
 *   node scripts/html-to-video.mjs input/example/scene.html -o output/intro.mp4 \
 *        --width 1080 --height 1920 --fps 60 --duration 8
 */

import { promises as fs } from "node:fs";
import path from "node:path";
import os from "node:os";
import { spawn } from "node:child_process";
import { pathToFileURL } from "node:url";

const ROOT = path.resolve(path.dirname(new URL(import.meta.url).pathname), "..");

function parseArgs(argv) {
  const opts = {
    input: null,
    output: null,
    fps: 30,
    duration: 5,
    width: 1920,
    height: 1080,
    scale: 1,
    crf: 18,
    realtime: false,
    keepFrames: false,
    help: false,
  };
  const rest = argv.slice(2);
  for (let i = 0; i < rest.length; i++) {
    const a = rest[i];
    switch (a) {
      case "-h":
      case "--help": opts.help = true; break;
      case "-o":
      case "--output": opts.output = rest[++i]; break;
      case "--fps": opts.fps = Number(rest[++i]); break;
      case "--duration": opts.duration = Number(rest[++i]); break;
      case "--width": opts.width = Number(rest[++i]); break;
      case "--height": opts.height = Number(rest[++i]); break;
      case "--scale": opts.scale = Number(rest[++i]); break;
      case "--crf": opts.crf = Number(rest[++i]); break;
      case "--realtime": opts.realtime = true; break;
      case "--keep-frames": opts.keepFrames = true; break;
      default:
        if (a.startsWith("-")) throw new Error(`Tùy chọn không hợp lệ: ${a}`);
        if (opts.input === null) opts.input = a;
        else throw new Error(`Tham số dư thừa: ${a}`);
    }
  }
  return opts;
}

const HELP = `html-to-video — render HTML/CSS thành MP4 (Puppeteer + FFmpeg)

  node scripts/html-to-video.mjs <input.html | URL> [tùy chọn]

  -o, --output <path>   File MP4 đầu ra (mặc định: output/<tên>.mp4)
  --fps <n>             Khung hình/giây (mặc định 30)
  --duration <giây>     Thời lượng (mặc định 5)
  --width <px>          Chiều rộng (mặc định 1920)
  --height <px>         Chiều cao (mặc định 1080)
  --scale <n>           Device scale factor (mặc định 1)
  --crf <n>             Chất lượng H.264 0–51 (mặc định 18)
  --realtime            Chụp theo thời gian thực
  --keep-frames         Giữ PNG tạm
  -h, --help            Trợ giúp
`;

/** Resolve input thành URL điều hướng được (file:// hoặc http(s)://). */
function resolveInputUrl(input) {
  if (/^https?:\/\//i.test(input)) return input;
  const abs = path.resolve(process.cwd(), input);
  return pathToFileURL(abs).href;
}

/** Tìm binary ffmpeg: ưu tiên ffmpeg-static, fallback PATH hệ thống. */
async function resolveFfmpeg() {
  try {
    const mod = await import("ffmpeg-static");
    const bin = mod.default || mod;
    if (bin && typeof bin === "string") return bin;
  } catch {
    /* ffmpeg-static chưa cài — dùng PATH */
  }
  return "ffmpeg";
}

function pad(n) {
  return String(n).padStart(6, "0");
}

async function main() {
  const opts = parseArgs(process.argv);
  if (opts.help || !opts.input) {
    process.stdout.write(HELP);
    process.exit(opts.input ? 0 : 1);
  }

  if (!Number.isFinite(opts.fps) || opts.fps <= 0) throw new Error("--fps phải > 0");
  if (!Number.isFinite(opts.duration) || opts.duration <= 0) throw new Error("--duration phải > 0");

  const totalFrames = Math.max(1, Math.round(opts.fps * opts.duration));
  const url = resolveInputUrl(opts.input);

  // Mặc định output ra output/<tên-input>.mp4
  let outPath = opts.output;
  if (!outPath) {
    const base = /^https?:/i.test(opts.input)
      ? "render"
      : path.basename(opts.input).replace(/\.[^.]+$/, "");
    outPath = path.join(ROOT, "output", `${base}.mp4`);
  }
  outPath = path.resolve(process.cwd(), outPath);
  await fs.mkdir(path.dirname(outPath), { recursive: true });

  const framesDir = await fs.mkdtemp(path.join(os.tmpdir(), "h2v-frames-"));
  const ffmpegBin = await resolveFfmpeg();

  console.log(`▶ Nguồn      : ${url}`);
  console.log(`▶ Đầu ra     : ${outPath}`);
  console.log(`▶ Kích thước : ${opts.width}x${opts.height} @ ${opts.scale}x`);
  console.log(`▶ Khung hình : ${totalFrames} (${opts.fps} fps × ${opts.duration}s)`);
  console.log(`▶ Chế độ     : ${opts.realtime ? "realtime" : "virtual time (tất định)"}`);
  console.log(`▶ FFmpeg     : ${ffmpegBin}`);

  const puppeteer = (await import("puppeteer")).default;
  const browser = await puppeteer.launch({
    headless: true,
    args: ["--no-sandbox", "--disable-setuid-sandbox", "--hide-scrollbars"],
  });

  try {
    const page = await browser.newPage();
    await page.setViewport({
      width: opts.width,
      height: opts.height,
      deviceScaleFactor: opts.scale,
    });

    const frameMs = 1000 / opts.fps;

    if (opts.realtime) {
      await page.goto(url, { waitUntil: "networkidle0", timeout: 60000 });
      for (let i = 0; i < totalFrames; i++) {
        await page.screenshot({ path: path.join(framesDir, `frame-${pad(i)}.png`) });
        await new Promise((r) => setTimeout(r, frameMs));
        if ((i + 1) % opts.fps === 0 || i === totalFrames - 1) {
          process.stdout.write(`\r  chụp ${i + 1}/${totalFrames}`);
        }
      }
    } else {
      // Virtual time qua CDP: render tất định, không phụ thuộc tốc độ máy.
      const client = await page.createCDPSession();
      let resolveBudget = null;
      client.on("Emulation.virtualTimeBudgetExpired", () => {
        const r = resolveBudget;
        resolveBudget = null;
        if (r) r();
      });
      const advance = (budget) => {
        const p = new Promise((res) => { resolveBudget = res; });
        return client
          .send("Emulation.setVirtualTimePolicy", {
            policy: "pauseIfNetworkFetchesPending",
            budget,
          })
          .then(() => p);
      };

      // Điều hướng + chờ tải xong theo thời gian thực (không đóng băng đồng hồ
      // trước goto, nếu không trang sẽ không bao giờ load xong). Sau khi tải
      // xong mới chuyển sang bước virtual time để chụp tất định.
      await page.goto(url, { waitUntil: "load", timeout: 60000 });

      for (let i = 0; i < totalFrames; i++) {
        await page.screenshot({ path: path.join(framesDir, `frame-${pad(i)}.png`) });
        await advance(frameMs);
        if ((i + 1) % opts.fps === 0 || i === totalFrames - 1) {
          process.stdout.write(`\r  chụp ${i + 1}/${totalFrames}`);
        }
      }
    }
    process.stdout.write("\n");
  } finally {
    await browser.close();
  }

  // Ghép PNG → MP4 bằng FFmpeg.
  console.log("▶ Ghép video bằng FFmpeg…");
  await runFfmpeg(ffmpegBin, [
    "-y",
    "-framerate", String(opts.fps),
    "-i", path.join(framesDir, "frame-%06d.png"),
    "-vf", "scale=trunc(iw/2)*2:trunc(ih/2)*2",
    "-c:v", "libx264",
    "-pix_fmt", "yuv420p",
    "-crf", String(opts.crf),
    "-movflags", "+faststart",
    outPath,
  ]);

  if (!opts.keepFrames) {
    await fs.rm(framesDir, { recursive: true, force: true });
  } else {
    console.log(`▶ Giữ khung hình tạm tại: ${framesDir}`);
  }

  console.log(`✔ Xong: ${outPath}`);
}

function runFfmpeg(bin, args) {
  return new Promise((resolve, reject) => {
    const ff = spawn(bin, args, { stdio: ["ignore", "ignore", "inherit"] });
    ff.on("error", (err) => {
      if (err.code === "ENOENT") {
        reject(new Error(
          `Không tìm thấy FFmpeg ("${bin}"). Cài FFmpeg (macOS: brew install ffmpeg) ` +
          `hoặc chạy "npm install" để lấy ffmpeg-static.`
        ));
      } else reject(err);
    });
    ff.on("close", (code) => {
      if (code === 0) resolve();
      else reject(new Error(`FFmpeg thoát với mã ${code}`));
    });
  });
}

main().catch((err) => {
  console.error(`\n✖ Lỗi: ${err.message}`);
  process.exit(1);
});
