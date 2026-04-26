// Ngũ Hành Sơn — Đà Nẵng
// Cảnh đường phố với núi đá vôi, biển Đông, xe cộ, cây xanh,
// đèn giao thông và người đi bộ. Vẽ bằng p5.js.

const W = 1280;
const H = 720;

// Mặt đường (tính từ đỉnh canvas)
const ROAD_TOP = 470;
const ROAD_BOTTOM = 640;
const SIDEWALK_BOTTOM = H;

let cars = [];
let pedestrians = [];
let trees = [];
let buildings = [];
let mountains = [];
let waves = [];
let clouds = [];

let trafficLight = {
  state: "green", // "green" | "yellow" | "red"
  timer: 0,
  durations: { green: 360, yellow: 80, red: 320 },
};

function setup() {
  const c = createCanvas(W, H);
  c.parent(document.body);
  noStroke();

  // Núi Ngũ Hành Sơn — 5 ngọn (Kim, Mộc, Thuỷ, Hoả, Thổ)
  mountains = [
    { x: 120, base: 470, w: 220, h: 180, tone: 196 }, // Thuỷ Sơn (lớn nhất)
    { x: 320, base: 470, w: 150, h: 120, tone: 188 }, // Mộc Sơn
    { x: 470, base: 470, w: 130, h: 95,  tone: 182 }, // Hoả Sơn
    { x: 600, base: 470, w: 160, h: 130, tone: 192 }, // Kim Sơn
    { x: 770, base: 470, w: 140, h: 105, tone: 185 }, // Thổ Sơn
  ];

  // Toà nhà phía sau (phố phường)
  for (let i = 0; i < 14; i++) {
    buildings.push({
      x: 880 + i * 32 + random(-6, 6),
      w: random(28, 44),
      h: random(80, 170),
      hue: random(35, 55),
      windows: floor(random(2, 5)),
    });
  }

  // Cây xanh hai bên đường
  for (let i = 0; i < 18; i++) {
    trees.push({
      x: random(20, W - 20),
      y: random(ROAD_BOTTOM + 18, H - 10),
      size: random(48, 78),
      sway: random(1000),
    });
  }
  // Cây phía xa, sau toà nhà
  for (let i = 0; i < 10; i++) {
    trees.push({
      x: random(900, W - 10),
      y: random(440, 470),
      size: random(28, 42),
      sway: random(1000),
      far: true,
    });
  }

  // Xe ban đầu — 2 làn, đi ngược chiều nhau
  for (let i = 0; i < 4; i++) spawnCar(random(0, W));

  // Người đi bộ trên vỉa hè
  for (let i = 0; i < 6; i++) spawnPedestrian(random(0, W));

  // Sóng biển (đường ngang)
  for (let i = 0; i < 8; i++) {
    waves.push({ y: 380 + i * 8, offset: random(1000), speed: random(0.005, 0.015) });
  }

  // Mây
  for (let i = 0; i < 5; i++) {
    clouds.push({ x: random(0, W), y: random(40, 160), w: random(80, 160), speed: random(0.15, 0.4) });
  }
}

function draw() {
  drawSky();
  drawSun();
  drawClouds();
  drawSea();
  drawMountains();
  drawBuildings();
  drawFarTrees();
  drawRoad();
  drawTrafficLight(1100, ROAD_TOP - 10);
  drawCrosswalk(640);
  updateAndDrawCars();
  updateTrafficLight();
  drawSidewalk();
  drawNearTrees();
  drawStreetLamps();
  updateAndDrawPedestrians();
  drawForegroundOverlay();
}

// ---------- BẦU TRỜI / MẶT TRỜI / MÂY ----------
function drawSky() {
  for (let y = 0; y < 380; y++) {
    const t = y / 380;
    const c = lerpColor(color(255, 196, 140), color(120, 180, 220), t);
    stroke(c);
    line(0, y, W, y);
  }
  noStroke();
}

function drawSun() {
  push();
  const cx = 980, cy = 150;
  for (let r = 90; r > 30; r -= 6) {
    fill(255, 220, 150, map(r, 90, 30, 8, 30));
    ellipse(cx, cy, r * 2, r * 2);
  }
  fill(255, 230, 170);
  ellipse(cx, cy, 70, 70);
  pop();
}

function drawClouds() {
  noStroke();
  for (const cl of clouds) {
    cl.x += cl.speed;
    if (cl.x - cl.w > W) cl.x = -cl.w;
    drawCloud(cl.x, cl.y, cl.w);
  }
}

function drawCloud(x, y, w) {
  fill(255, 255, 255, 220);
  ellipse(x, y, w, w * 0.55);
  ellipse(x + w * 0.3, y - w * 0.1, w * 0.7, w * 0.5);
  ellipse(x - w * 0.3, y + w * 0.05, w * 0.6, w * 0.4);
}

// ---------- BIỂN ----------
function drawSea() {
  // Vùng biển nằm sau núi, tạo cảm giác bờ biển Đà Nẵng
  fill(46, 128, 168);
  rect(0, 360, W, 110);
  // Sóng
  noFill();
  for (const w of waves) {
    stroke(255, 255, 255, 90);
    strokeWeight(1.2);
    beginShape();
    for (let x = 0; x <= W; x += 12) {
      const yy = w.y + sin((x + frameCount * w.speed * 200) * 0.02 + w.offset) * 2.5;
      vertex(x, yy);
    }
    endShape();
  }
  noStroke();
  // Đường chân trời mờ
  fill(255, 255, 255, 30);
  rect(0, 360, W, 4);
}

// ---------- NÚI NGŨ HÀNH SƠN ----------
function drawMountains() {
  for (const m of mountains) drawMarbleMountain(m);
}

function drawMarbleMountain(m) {
  // Bóng đá vôi gradient
  const peakX = m.x + m.w / 2;
  const peakY = m.base - m.h;

  // Thân núi
  fill(m.tone, m.tone + 6, m.tone + 12);
  beginShape();
  vertex(m.x, m.base);
  vertex(m.x + m.w * 0.18, m.base - m.h * 0.55);
  vertex(m.x + m.w * 0.32, m.base - m.h * 0.78);
  vertex(peakX - 6, peakY + 6);
  vertex(peakX + 8, peakY);
  vertex(m.x + m.w * 0.7, m.base - m.h * 0.7);
  vertex(m.x + m.w * 0.86, m.base - m.h * 0.4);
  vertex(m.x + m.w, m.base);
  endShape(CLOSE);

  // Mặt sáng
  fill(m.tone + 24, m.tone + 28, m.tone + 32);
  beginShape();
  vertex(peakX + 8, peakY);
  vertex(m.x + m.w * 0.7, m.base - m.h * 0.7);
  vertex(m.x + m.w * 0.86, m.base - m.h * 0.4);
  vertex(m.x + m.w, m.base);
  vertex(m.x + m.w * 0.55, m.base);
  endShape(CLOSE);

  // Cây trên núi (chấm xanh)
  fill(60, 110, 70);
  for (let i = 0; i < 14; i++) {
    const px = m.x + 10 + (i * (m.w - 20)) / 14 + sin(i) * 4;
    const py = m.base - 6 - noise(i * 0.5, m.x * 0.01) * m.h * 0.4;
    ellipse(px, py, 8, 7);
  }

  // Chùa nhỏ trên đỉnh núi lớn nhất
  if (m.w > 200) {
    const tx = peakX, ty = peakY + 10;
    fill(180, 60, 50);
    triangle(tx - 14, ty, tx + 14, ty, tx, ty - 14);
    fill(220, 200, 170);
    rect(tx - 9, ty, 18, 12);
    fill(120, 70, 40);
    rect(tx - 2, ty + 4, 4, 8);
  }
}

// ---------- TOÀ NHÀ ----------
function drawBuildings() {
  for (const b of buildings) {
    fill(b.hue + 180, b.hue + 160, b.hue + 140);
    rect(b.x, ROAD_TOP - b.h, b.w, b.h);
    // cửa sổ
    fill(255, 230, 150, 200);
    for (let r = 0; r < floor(b.h / 22); r++) {
      for (let cIdx = 0; cIdx < b.windows; cIdx++) {
        const wx = b.x + 4 + cIdx * ((b.w - 8) / b.windows);
        const wy = ROAD_TOP - b.h + 8 + r * 22;
        rect(wx, wy, (b.w - 8) / b.windows - 3, 12);
      }
    }
    // mái
    fill(120, 80, 70);
    rect(b.x - 2, ROAD_TOP - b.h - 4, b.w + 4, 5);
  }
}

// ---------- CÂY ----------
function drawFarTrees() {
  for (const t of trees) {
    if (!t.far) continue;
    drawTree(t);
  }
}

function drawNearTrees() {
  for (const t of trees) {
    if (t.far) continue;
    drawTree(t);
  }
}

function drawTree(t) {
  const sway = sin(frameCount * 0.02 + t.sway) * 1.2;
  // thân
  fill(86, 56, 36);
  rect(t.x - t.size * 0.06, t.y - t.size * 0.5, t.size * 0.12, t.size * 0.5);
  // tán lá nhiều lớp xanh
  fill(34, 100, 52);
  ellipse(t.x + sway, t.y - t.size * 0.6, t.size, t.size * 0.95);
  fill(52, 130, 70);
  ellipse(t.x - t.size * 0.2 + sway, t.y - t.size * 0.7, t.size * 0.7, t.size * 0.7);
  fill(72, 156, 86);
  ellipse(t.x + t.size * 0.22 + sway, t.y - t.size * 0.55, t.size * 0.6, t.size * 0.55);
}

// ---------- ĐƯỜNG ----------
function drawRoad() {
  // mặt đường
  fill(52, 52, 56);
  rect(0, ROAD_TOP, W, ROAD_BOTTOM - ROAD_TOP);

  // vạch lề trắng
  fill(240);
  rect(0, ROAD_TOP, W, 3);
  rect(0, ROAD_BOTTOM - 3, W, 3);

  // vạch chia làn (đứt)
  fill(245, 220, 80);
  const midY = (ROAD_TOP + ROAD_BOTTOM) / 2 - 2;
  for (let x = 0; x < W; x += 40) {
    rect(x, midY, 22, 4);
  }
}

function drawCrosswalk(centerX) {
  fill(245);
  for (let i = 0; i < 7; i++) {
    rect(centerX - 60 + i * 18, ROAD_TOP + 6, 12, ROAD_BOTTOM - ROAD_TOP - 12);
  }
}

function drawSidewalk() {
  // vỉa hè
  fill(190, 188, 180);
  rect(0, ROAD_BOTTOM, W, SIDEWALK_BOTTOM - ROAD_BOTTOM);
  // gạch
  stroke(160, 158, 150);
  strokeWeight(1);
  for (let x = 0; x < W; x += 36) line(x, ROAD_BOTTOM, x, H);
  for (let y = ROAD_BOTTOM + 18; y < H; y += 18) line(0, y, W, y);
  noStroke();
}

// ---------- ĐÈN ĐƯỜNG ----------
function drawStreetLamps() {
  const positions = [80, 360, 640, 920, 1200];
  for (const x of positions) drawStreetLamp(x, ROAD_BOTTOM + 4);
}

function drawStreetLamp(x, baseY) {
  fill(60);
  rect(x - 2, baseY - 110, 4, 110);
  rect(x - 22, baseY - 110, 44, 4);
  fill(255, 220, 130);
  ellipse(x - 18, baseY - 100, 10, 10);
  ellipse(x + 18, baseY - 100, 10, 10);
}

// ---------- ĐÈN GIAO THÔNG ----------
function updateTrafficLight() {
  trafficLight.timer++;
  const d = trafficLight.durations[trafficLight.state];
  if (trafficLight.timer >= d) {
    trafficLight.timer = 0;
    if (trafficLight.state === "green") trafficLight.state = "yellow";
    else if (trafficLight.state === "yellow") trafficLight.state = "red";
    else trafficLight.state = "green";
  }
}

function drawTrafficLight(x, y) {
  // cột
  fill(50);
  rect(x - 3, y, 6, 130);
  rect(x - 3, y, 60, 6);
  // hộp đèn
  fill(30);
  rect(x + 40, y - 60, 30, 80, 4);
  // bóng đèn
  const on = trafficLight.state;
  fill(on === "red" ? color(230, 60, 60) : color(70, 25, 25));
  ellipse(x + 55, y - 45, 18, 18);
  fill(on === "yellow" ? color(245, 210, 70) : color(80, 70, 25));
  ellipse(x + 55, y - 23, 18, 18);
  fill(on === "green" ? color(70, 220, 110) : color(25, 70, 35));
  ellipse(x + 55, y - 1, 18, 18);
}

// ---------- XE Ô TÔ ----------
function spawnCar(x = -120) {
  const goingRight = random() < 0.5;
  const lane = goingRight
    ? (ROAD_TOP + ROAD_BOTTOM) / 2 + 22
    : (ROAD_TOP + ROAD_BOTTOM) / 2 - 42;
  const palette = [
    [220, 70, 70], [240, 180, 60], [80, 140, 220],
    [60, 170, 110], [240, 240, 240], [40, 40, 50],
  ];
  const col = palette[floor(random(palette.length))];
  cars.push({
    x: goingRight ? -120 : W + 120,
    y: lane,
    w: random(70, 96),
    h: 28,
    color: col,
    speed: random(1.6, 2.8) * (goingRight ? 1 : -1),
    type: random() < 0.25 ? "suv" : "sedan",
  });
}

function updateAndDrawCars() {
  // Đèn đỏ -> xe dừng trước vạch
  const stopLineX = 600;
  for (const c of cars) {
    const goingRight = c.speed > 0;
    let canMove = true;
    if (trafficLight.state === "red" || trafficLight.state === "yellow") {
      if (goingRight && c.x + c.w / 2 > stopLineX - 80 && c.x + c.w / 2 < stopLineX - 6) {
        canMove = false;
      }
    }
    // tránh đâm đuôi xe trước
    for (const o of cars) {
      if (o === c) continue;
      if (sign(o.speed) !== sign(c.speed)) continue;
      const ahead = goingRight ? o.x > c.x : o.x < c.x;
      if (ahead && abs(o.x - c.x) < c.w + 12 && abs(o.y - c.y) < 6) {
        canMove = false;
      }
    }
    if (canMove) c.x += c.speed;
  }
  // dọn xe ra khỏi màn hình + spawn
  cars = cars.filter(c => c.x > -200 && c.x < W + 200);
  if (frameCount % 90 === 0 && cars.length < 7) spawnCar();

  // vẽ
  for (const c of cars) drawCar(c);
}

function drawCar(c) {
  push();
  translate(c.x, c.y);
  const dir = c.speed >= 0 ? 1 : -1;
  scale(dir, 1);

  // bóng đổ
  fill(0, 0, 0, 60);
  ellipse(0, 18, c.w * 1.05, 8);

  // thân dưới
  fill(c.color[0], c.color[1], c.color[2]);
  rect(-c.w / 2, -c.h / 2, c.w, c.h, 4);
  // cabin
  if (c.type === "suv") {
    rect(-c.w / 2 + 10, -c.h / 2 - 18, c.w - 20, 20, 4);
  } else {
    beginShape();
    vertex(-c.w / 2 + 14, -c.h / 2);
    vertex(-c.w / 2 + 22, -c.h / 2 - 16);
    vertex( c.w / 2 - 16, -c.h / 2 - 16);
    vertex( c.w / 2 - 8,  -c.h / 2);
    endShape(CLOSE);
  }
  // kính
  fill(140, 200, 230, 220);
  rect(-c.w / 2 + 16, -c.h / 2 - 14, c.w - 30, 12, 2);
  // đèn pha (phía trước, theo chiều di chuyển)
  fill(255, 240, 180);
  rect(c.w / 2 - 5, -2, 4, 6, 1);
  // đèn hậu
  fill(220, 70, 70);
  rect(-c.w / 2 + 1, -2, 4, 6, 1);
  // bánh xe
  fill(20);
  ellipse(-c.w / 2 + 16, c.h / 2, 14, 14);
  ellipse( c.w / 2 - 16, c.h / 2, 14, 14);
  fill(120);
  ellipse(-c.w / 2 + 16, c.h / 2, 6, 6);
  ellipse( c.w / 2 - 16, c.h / 2, 6, 6);
  pop();
}

// ---------- NGƯỜI ĐI BỘ ----------
function spawnPedestrian(x) {
  pedestrians.push({
    x: x ?? (random() < 0.5 ? -10 : W + 10),
    y: random(ROAD_BOTTOM + 30, H - 20),
    speed: random(0.5, 1.2) * (random() < 0.5 ? 1 : -1),
    shirt: color(random(60, 240), random(60, 240), random(60, 240)),
    pant:  color(random(20, 100), random(20, 100), random(20, 120)),
    skin:  color(245, 210, 175),
    phase: random(1000),
    crossing: false,
  });
}

function updateAndDrawPedestrians() {
  for (const p of pedestrians) {
    p.x += p.speed;
    if (p.x < -20) p.x = W + 20;
    if (p.x > W + 20) p.x = -20;
    drawPedestrian(p);
  }
  // người sang đường khi đèn đỏ cho xe
  if (trafficLight.state === "red" && frameCount % 4 === 0 && pedestrians.length < 12) {
    if (random() < 0.04) {
      pedestrians.push({
        x: 640 + random(-30, 30),
        y: H - 10,
        speed: 0,
        shirt: color(random(60, 240), random(60, 240), random(60, 240)),
        pant:  color(40, 40, 80),
        skin:  color(245, 210, 175),
        phase: random(1000),
        crossing: true,
        crossY: H - 10,
        crossDir: -1,
      });
    }
  }
  for (const p of pedestrians) {
    if (p.crossing) {
      p.crossY += p.crossDir * 0.6;
      p.y = p.crossY;
      if (p.crossY < ROAD_TOP - 6) {
        p.crossing = false;
        p.y = random(ROAD_BOTTOM + 30, H - 20);
        p.speed = random(0.5, 1.2) * (random() < 0.5 ? 1 : -1);
      }
    }
  }
}

function drawPedestrian(p) {
  const swing = sin(frameCount * 0.2 + p.phase) * 3;
  push();
  translate(p.x, p.y);
  // bóng
  fill(0, 0, 0, 60);
  ellipse(0, 2, 14, 4);
  // chân
  stroke(red(p.pant), green(p.pant), blue(p.pant));
  strokeWeight(3);
  line(-2,  -4, -2 + swing * 0.4,  6);
  line( 2,  -4,  2 - swing * 0.4,  6);
  // thân
  noStroke();
  fill(p.shirt);
  rect(-5, -16, 10, 14, 2);
  // tay
  stroke(red(p.shirt), green(p.shirt), blue(p.shirt));
  strokeWeight(3);
  line(-5, -14, -7 - swing * 0.3, -4);
  line( 5, -14,  7 + swing * 0.3, -4);
  noStroke();
  // đầu
  fill(p.skin);
  ellipse(0, -22, 9, 9);
  // tóc
  fill(35, 25, 20);
  arc(0, -23, 10, 10, PI, TWO_PI);
  pop();
}

// ---------- LỚP MỜ TIỀN CẢNH ----------
function drawForegroundOverlay() {
  // viền chân trang nhẹ
  noFill();
  stroke(0, 0, 0, 30);
  strokeWeight(2);
  rect(1, 1, W - 2, H - 2);
  noStroke();
}

// ---------- HELPERS ----------
function sign(v) { return v > 0 ? 1 : v < 0 ? -1 : 0; }

function windowResized() {
  // giữ kích thước cố định để bố cục không bị méo
}
