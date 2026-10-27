// Procedural vector art for the world: background, towers, enemies, hero, heart, projectiles.
import { ENEMIES, TOWERS, type GameMap, type HeroDef, type TowerId, type Vec } from "./config";
import { drawGlow, glowSprite } from "./fx";
import type { Enemy, Hero, Proj, Tower } from "./types";

const TAU = Math.PI * 2;

export const easeOutBack = (t: number) => {
  const c1 = 1.70158;
  const c3 = c1 + 1;
  return 1 + c3 * Math.pow(t - 1, 3) + c1 * Math.pow(t - 1, 2);
};

function mulberry32(a: number) {
  return () => {
    a |= 0;
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function poly(ctx: CanvasRenderingContext2D, sides: number, r: number, rot = 0) {
  ctx.beginPath();
  for (let i = 0; i < sides; i++) {
    const a = rot + (i / sides) * TAU;
    const x = Math.cos(a) * r;
    const y = Math.sin(a) * r;
    if (i === 0) ctx.moveTo(x, y);
    else ctx.lineTo(x, y);
  }
  ctx.closePath();
}

export function roundRect(ctx: CanvasRenderingContext2D, x: number, y: number, w: number, h: number, r: number) {
  const rr = Math.min(r, w / 2, h / 2);
  ctx.beginPath();
  ctx.moveTo(x + rr, y);
  ctx.arcTo(x + w, y, x + w, y + h, rr);
  ctx.arcTo(x + w, y + h, x, y + h, rr);
  ctx.arcTo(x, y + h, x, y, rr);
  ctx.arcTo(x, y, x + w, y, rr);
  ctx.closePath();
}

// ------------------------------------------------------------------ background
export function buildBackground(map: GameMap, scale: number): HTMLCanvasElement {
  const { w, h } = map;
  const c = document.createElement("canvas");
  c.width = Math.ceil(w * scale);
  c.height = Math.ceil(h * scale);
  const g = c.getContext("2d")!;
  g.scale(c.width / w, c.height / h);
  const rnd = mulberry32(map.portrait ? 77 : 1337);

  const base = g.createRadialGradient(w / 2, h / 2, 40, w / 2, h / 2, Math.max(w, h) * 0.78);
  base.addColorStop(0, "#1d3445");
  base.addColorStop(1, "#091120");
  g.fillStyle = base;
  g.fillRect(0, 0, w, h);

  const distPath = (x: number, y: number) => {
    let best = 1e9;
    for (let i = 0; i < map.n; i += 5) {
      const dx = map.px[i] - x;
      const dy = map.py[i] - y;
      const d = dx * dx + dy * dy;
      if (d < best) best = d;
    }
    return Math.sqrt(best);
  };
  const nearPad = (x: number, y: number, r: number) => map.pads.some((p) => Math.hypot(p.x - x, p.y - y) < r);

  // soft color patches
  const patch = ["#2a6a5a", "#1e3f6a", "#4a3a7a", "#22554a"];
  for (let i = 0; i < 46; i++) {
    g.globalAlpha = 0.1 + rnd() * 0.12;
    const r = 50 + rnd() * 110;
    g.drawImage(glowSprite(patch[i % patch.length]), rnd() * w - r, rnd() * h - r, r * 2, r * 2);
  }
  g.globalAlpha = 1;

  // grass tufts
  for (let i = 0; i < 520; i++) {
    const x = rnd() * w;
    const y = rnd() * h;
    if (distPath(x, y) < 36 || nearPad(x, y, 30)) continue;
    g.strokeStyle = rnd() > 0.5 ? "#2f6b55" : "#3a8061";
    g.globalAlpha = 0.25 + rnd() * 0.35;
    g.lineWidth = 1.4;
    g.beginPath();
    for (let k = -1; k <= 1; k++) {
      g.moveTo(x + k * 2.5, y);
      g.lineTo(x + k * 4.5, y - 4 - rnd() * 4);
    }
    g.stroke();
  }
  g.globalAlpha = 1;

  // stones
  for (let i = 0; i < 46; i++) {
    const x = rnd() * w;
    const y = rnd() * h;
    if (distPath(x, y) < 40 || nearPad(x, y, 34)) continue;
    const r = 3 + rnd() * 6;
    g.fillStyle = "rgba(0,0,0,0.3)";
    g.beginPath();
    g.ellipse(x + 1, y + r * 0.5, r * 1.1, r * 0.5, 0, 0, TAU);
    g.fill();
    g.fillStyle = "#2c3a4f";
    g.beginPath();
    g.ellipse(x, y, r, r * 0.75, 0, 0, TAU);
    g.fill();
    g.fillStyle = "rgba(255,255,255,0.1)";
    g.beginPath();
    g.ellipse(x - r * 0.25, y - r * 0.25, r * 0.5, r * 0.3, 0, 0, TAU);
    g.fill();
  }

  // path
  const strokePath = (width: number, color: string, dash: number[] = [], offset = 0, cap: CanvasLineCap = "round", dy = 0) => {
    g.save();
    g.translate(0, dy);
    g.lineJoin = "round";
    g.lineCap = cap;
    g.lineWidth = width;
    g.strokeStyle = color;
    g.setLineDash(dash);
    g.lineDashOffset = offset;
    g.beginPath();
    for (let i = 0; i < map.n; i += 2) {
      if (i === 0) g.moveTo(map.px[i], map.py[i]);
      else g.lineTo(map.px[i], map.py[i]);
    }
    g.stroke();
    g.restore();
  };
  strokePath(64, "rgba(0,0,0,0.35)", [], 0, "round", 4);
  strokePath(58, "#241b33");
  strokePath(50, "#4a3d5e");
  strokePath(42, "#55476b");
  strokePath(30, "rgba(255,255,255,0.06)", [1, 11]);
  strokePath(18, "rgba(0,0,0,0.12)", [1, 15], 6);
  strokePath(2, "rgba(167,139,250,0.35)", [5, 19]);

  // glowing crystals / mushrooms
  g.globalCompositeOperation = "lighter";
  for (let i = 0; i < 30; i++) {
    const x = rnd() * w;
    const y = rnd() * h;
    if (distPath(x, y) < 44 || nearPad(x, y, 36)) continue;
    const col = rnd() > 0.5 ? "#5eead4" : "#f472b6";
    g.globalAlpha = 0.5;
    g.drawImage(glowSprite(col), x - 12, y - 12, 24, 24);
  }
  g.globalAlpha = 1;
  g.globalCompositeOperation = "source-over";

  // pine trees
  const trees: Vec[] = [];
  for (let i = 0; i < 260 && trees.length < 40; i++) {
    const x = rnd() * w;
    const y = rnd() * h;
    if (distPath(x, y) < 66 || nearPad(x, y, 48) || Math.hypot(x - map.heart.x, y - map.heart.y) < 70) continue;
    if (trees.some((t) => Math.hypot(t.x - x, t.y - y) < 34)) continue;
    trees.push({ x, y });
  }
  trees.sort((a, b) => a.y - b.y);
  for (const t of trees) {
    const s = 0.85 + rnd() * 0.5;
    g.fillStyle = "rgba(0,0,0,0.3)";
    g.beginPath();
    g.ellipse(t.x + 3, t.y + 3, 13 * s, 5 * s, 0, 0, TAU);
    g.fill();
    g.fillStyle = "#3b2a2a";
    g.fillRect(t.x - 2 * s, t.y - 4 * s, 4 * s, 8 * s);
    const shades = ["#14403a", "#1a5245", "#216355"];
    for (let k = 0; k < 3; k++) {
      g.fillStyle = shades[k];
      g.beginPath();
      const ty = t.y - 6 * s - k * 9 * s;
      const half = (15 - k * 3) * s;
      g.moveTo(t.x, ty - 14 * s);
      g.lineTo(t.x + half, ty + 3 * s);
      g.lineTo(t.x - half, ty + 3 * s);
      g.closePath();
      g.fill();
    }
    g.fillStyle = "rgba(255,255,255,0.08)";
    g.beginPath();
    g.moveTo(t.x, t.y - 42 * s);
    g.lineTo(t.x + 4 * s, t.y - 28 * s);
    g.lineTo(t.x - 3 * s, t.y - 28 * s);
    g.fill();
  }

  // pad bases
  for (const p of map.pads) {
    g.save();
    g.translate(p.x, p.y);
    g.fillStyle = "rgba(0,0,0,0.35)";
    g.beginPath();
    g.ellipse(0, 4, 26, 12, 0, 0, TAU);
    g.fill();
    poly(g, 8, 24, Math.PI / 8);
    g.fillStyle = "#2b3347";
    g.fill();
    g.strokeStyle = "#171c2b";
    g.lineWidth = 3;
    g.stroke();
    poly(g, 8, 18, Math.PI / 8);
    g.fillStyle = "#1f2638";
    g.fill();
    g.strokeStyle = "rgba(148,163,184,0.25)";
    g.lineWidth = 1.5;
    g.stroke();
    g.restore();
  }

  // heart base
  g.save();
  g.translate(map.heart.x, map.heart.y);
  g.globalAlpha = 0.5;
  g.drawImage(glowSprite("#ff4d8d"), -90, -90, 180, 180);
  g.globalAlpha = 1;
  poly(g, 10, 36, 0);
  g.fillStyle = "#2a2036";
  g.fill();
  g.strokeStyle = "#ff6fa6";
  g.globalAlpha = 0.5;
  g.lineWidth = 2;
  g.stroke();
  g.restore();

  return c;
}

// ------------------------------------------------------------------ pads (dynamic overlay)
export function drawPadOverlay(
  ctx: CanvasRenderingContext2D,
  p: Vec,
  time: number,
  affordable: boolean,
  focused: boolean,
  occupied: boolean,
) {
  if (occupied && !focused) return;
  ctx.save();
  ctx.translate(p.x, p.y);
  if (focused) {
    ctx.strokeStyle = "#fde68a";
    ctx.globalAlpha = 0.9;
    ctx.lineWidth = 3;
    poly(ctx, 8, 26 + Math.sin(time * 8) * 1.2, Math.PI / 8);
    ctx.stroke();
  } else if (affordable) {
    const k = 0.5 + 0.5 * Math.sin(time * 3 + p.x * 0.05);
    ctx.globalAlpha = 0.35 + k * 0.5;
    ctx.strokeStyle = "#5eead4";
    ctx.lineWidth = 2;
    poly(ctx, 8, 22 + k * 2, Math.PI / 8);
    ctx.stroke();
    ctx.globalAlpha = 0.5 + k * 0.4;
    ctx.fillStyle = "#99f6e4";
    ctx.fillRect(-1.5, -7, 3, 14);
    ctx.fillRect(-7, -1.5, 14, 3);
  } else {
    ctx.globalAlpha = 0.25;
    ctx.fillStyle = "#94a3b8";
    ctx.fillRect(-1.5, -6, 3, 12);
    ctx.fillRect(-6, -1.5, 12, 3);
  }
  ctx.restore();
}

// ------------------------------------------------------------------ towers
export function drawTower(ctx: CanvasRenderingContext2D, t: Tower, time: number) {
  const def = TOWERS[t.type];
  const s = t.spawnT >= 1 ? 1 : Math.max(0, easeOutBack(t.spawnT));
  const col = def.color;
  const lvl = t.lvl;
  ctx.save();
  ctx.translate(t.x, t.y);
  ctx.scale(s * (1 + t.flash * 0.1), s * (1 + t.flash * 0.1));
  // base
  poly(ctx, 8, 21 + lvl * 1.2, Math.PI / 8);
  ctx.fillStyle = "#3d445f";
  ctx.fill();
  ctx.strokeStyle = "#151a2a";
  ctx.lineWidth = 2.5;
  ctx.stroke();
  poly(ctx, 8, 16, Math.PI / 8);
  ctx.strokeStyle = col;
  ctx.globalAlpha = 0.55 + lvl * 0.15;
  ctx.lineWidth = 2;
  ctx.stroke();
  ctx.globalAlpha = 1;

  if (t.buffed) {
    ctx.globalAlpha = 0.55 + 0.3 * Math.sin(time * 6);
    ctx.strokeStyle = "#fde68a";
    ctx.lineWidth = 1.5;
    ctx.setLineDash([3, 5]);
    ctx.lineDashOffset = -time * 14;
    ctx.beginPath();
    ctx.arc(0, 0, 27, 0, TAU);
    ctx.stroke();
    ctx.setLineDash([]);
    ctx.globalAlpha = 1;
  }

  const rc = t.recoil * 5;
  switch (t.type) {
    case "arrow": {
      ctx.save();
      ctx.rotate(t.angle);
      ctx.fillStyle = "#6b4f35";
      ctx.beginPath();
      ctx.arc(0, 0, 10, 0, TAU);
      ctx.fill();
      ctx.fillStyle = "#8b6a47";
      ctx.beginPath();
      ctx.arc(0, 0, 6.5, 0, TAU);
      ctx.fill();
      ctx.strokeStyle = col;
      ctx.lineWidth = 3;
      ctx.lineCap = "round";
      ctx.beginPath();
      ctx.arc(5 - rc * 0.3, 0, 12, -1.15, 1.15);
      ctx.stroke();
      const bx = 5 - rc * 0.3 + Math.cos(1.15) * 12;
      const by = Math.sin(1.15) * 12;
      ctx.strokeStyle = "rgba(255,255,255,0.7)";
      ctx.lineWidth = 1;
      ctx.beginPath();
      ctx.moveTo(bx, -by);
      ctx.lineTo(2 - rc, 0);
      ctx.lineTo(bx, by);
      ctx.stroke();
      ctx.strokeStyle = "#e5e7eb";
      ctx.lineWidth = 2;
      const shafts = lvl >= 2 ? [-3, 0, 3] : lvl >= 1 ? [-2, 2] : [0];
      for (const sy of shafts) {
        ctx.beginPath();
        ctx.moveTo(2 - rc, sy);
        ctx.lineTo(19 - rc, sy);
        ctx.stroke();
        ctx.fillStyle = col;
        ctx.beginPath();
        ctx.moveTo(23 - rc, sy);
        ctx.lineTo(18 - rc, sy - 2.5);
        ctx.lineTo(18 - rc, sy + 2.5);
        ctx.fill();
      }
      ctx.restore();
      break;
    }
    case "cannon": {
      ctx.save();
      ctx.rotate(t.angle);
      ctx.fillStyle = "#4a4f66";
      ctx.beginPath();
      ctx.arc(0, 0, 13, 0, TAU);
      ctx.fill();
      const bw = 9 + lvl * 2;
      ctx.fillStyle = "#5f4a3b";
      roundRect(ctx, 0 - rc, -bw / 2, 22, bw, 3);
      ctx.fill();
      ctx.fillStyle = col;
      roundRect(ctx, 18 - rc, -bw / 2 - 1.5, 5, bw + 3, 2);
      ctx.fill();
      ctx.fillRect(7 - rc, -bw / 2, 2.5, bw);
      ctx.restore();
      ctx.fillStyle = col;
      ctx.beginPath();
      ctx.arc(0, 0, 5, 0, TAU);
      ctx.fill();
      ctx.fillStyle = "rgba(255,255,255,0.35)";
      ctx.beginPath();
      ctx.arc(-1.5, -1.5, 2, 0, TAU);
      ctx.fill();
      break;
    }
    case "frost": {
      const bob = Math.sin(time * 2 + t.x) * 1.5;
      ctx.save();
      ctx.translate(0, -3 + bob);
      const hgt = 22 + lvl * 3;
      ctx.fillStyle = "#67e8f9";
      ctx.beginPath();
      ctx.moveTo(0, -hgt);
      ctx.lineTo(-9, -3);
      ctx.lineTo(0, 10);
      ctx.closePath();
      ctx.fill();
      ctx.fillStyle = "#cffafe";
      ctx.beginPath();
      ctx.moveTo(0, -hgt);
      ctx.lineTo(9, -3);
      ctx.lineTo(0, 10);
      ctx.closePath();
      ctx.fill();
      ctx.strokeStyle = "rgba(255,255,255,0.8)";
      ctx.lineWidth = 1;
      ctx.beginPath();
      ctx.moveTo(0, -hgt + 3);
      ctx.lineTo(0, 7);
      ctx.stroke();
      const n = 2 + lvl;
      for (let i = 0; i < n; i++) {
        const a = time * 1.6 + (i / n) * TAU;
        const px = Math.cos(a) * 16;
        const py = Math.sin(a) * 6 + 2;
        ctx.fillStyle = "#a5f3fc";
        ctx.beginPath();
        ctx.moveTo(px, py - 3.5);
        ctx.lineTo(px + 2.5, py);
        ctx.lineTo(px, py + 3.5);
        ctx.lineTo(px - 2.5, py);
        ctx.fill();
      }
      ctx.restore();
      break;
    }
    case "storm": {
      ctx.fillStyle = "#4a4468";
      roundRect(ctx, -4.5, -8, 9, 17, 3);
      ctx.fill();
      for (let i = 0; i < 2 + lvl; i++) {
        ctx.strokeStyle = i % 2 ? "#a78bfa" : "#ddd6fe";
        ctx.lineWidth = 2.2;
        ctx.beginPath();
        ctx.ellipse(0, 6 - i * 4.6, 9 - i * 0.8, 3, 0, 0, TAU);
        ctx.stroke();
      }
      const oy = -10 - lvl * 3;
      ctx.fillStyle = "#ede9fe";
      ctx.beginPath();
      ctx.arc(0, oy, 5.5 + t.flash * 2, 0, TAU);
      ctx.fill();
      ctx.globalCompositeOperation = "lighter";
      drawGlow(ctx, "#a78bfa", 0, oy, 16 + t.flash * 10, 0.7);
      ctx.strokeStyle = "#e0e7ff";
      ctx.lineWidth = 1.2;
      for (let i = 0; i < 3; i++) {
        if (Math.sin(time * 31 + i * 2.1 + t.x) > 0.35) {
          const a = time * 4 + i * 2.1;
          ctx.globalAlpha = 0.9;
          ctx.beginPath();
          ctx.moveTo(Math.cos(a) * 5, oy + Math.sin(a) * 5);
          ctx.lineTo(Math.cos(a + 0.3) * 11, oy + Math.sin(a + 0.4) * 11);
          ctx.lineTo(Math.cos(a - 0.1) * 14, oy + Math.sin(a - 0.1) * 14);
          ctx.stroke();
        }
      }
      ctx.globalCompositeOperation = "source-over";
      ctx.globalAlpha = 1;
      break;
    }
  }

  // level pips
  for (let i = 0; i <= lvl; i++) {
    const px = (i - lvl / 2) * 7;
    ctx.fillStyle = "#fbbf24";
    ctx.strokeStyle = "#78350f";
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.arc(px, 24, 2.6, 0, TAU);
    ctx.fill();
    ctx.stroke();
  }
  if (t.flash > 0) {
    ctx.globalAlpha = t.flash * 0.4;
    ctx.fillStyle = "#fff";
    poly(ctx, 8, 20, Math.PI / 8);
    ctx.fill();
  }
  ctx.restore();
}

export function drawTowerIcon(ctx: CanvasRenderingContext2D, id: TowerId, x: number, y: number, s: number, dim = false) {
  const col = TOWERS[id].color;
  ctx.save();
  ctx.translate(x, y);
  ctx.scale(s / 20, s / 20);
  ctx.globalAlpha = dim ? 0.45 : 1;
  ctx.lineCap = "round";
  switch (id) {
    case "arrow":
      ctx.strokeStyle = col;
      ctx.lineWidth = 3.5;
      ctx.beginPath();
      ctx.arc(2, 0, 13, -1.15, 1.15);
      ctx.stroke();
      ctx.strokeStyle = "#f1f5f9";
      ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.moveTo(-9, 0);
      ctx.lineTo(13, 0);
      ctx.stroke();
      ctx.fillStyle = col;
      ctx.beginPath();
      ctx.moveTo(17, 0);
      ctx.lineTo(11, -4);
      ctx.lineTo(11, 4);
      ctx.fill();
      break;
    case "cannon":
      ctx.fillStyle = "#5f4a3b";
      roundRect(ctx, -4, -6, 22, 12, 3);
      ctx.fill();
      ctx.fillStyle = col;
      roundRect(ctx, 13, -8, 5, 16, 2);
      ctx.fill();
      ctx.fillStyle = "#4a4f66";
      ctx.beginPath();
      ctx.arc(-4, 0, 9, 0, TAU);
      ctx.fill();
      ctx.fillStyle = col;
      ctx.beginPath();
      ctx.arc(-4, 0, 4, 0, TAU);
      ctx.fill();
      break;
    case "frost":
      ctx.fillStyle = "#67e8f9";
      ctx.beginPath();
      ctx.moveTo(0, -17);
      ctx.lineTo(-9, -1);
      ctx.lineTo(0, 13);
      ctx.fill();
      ctx.fillStyle = "#cffafe";
      ctx.beginPath();
      ctx.moveTo(0, -17);
      ctx.lineTo(9, -1);
      ctx.lineTo(0, 13);
      ctx.fill();
      break;
    case "storm":
      ctx.strokeStyle = "#a78bfa";
      ctx.lineWidth = 2.6;
      for (let i = 0; i < 3; i++) {
        ctx.beginPath();
        ctx.ellipse(0, 10 - i * 6, 10 - i, 3.2, 0, 0, TAU);
        ctx.stroke();
      }
      ctx.fillStyle = "#ede9fe";
      ctx.beginPath();
      ctx.arc(0, -10, 6, 0, TAU);
      ctx.fill();
      break;
  }
  ctx.restore();
}

// ------------------------------------------------------------------ enemies
export function drawEnemy(ctx: CanvasRenderingContext2D, e: Enemy, time: number) {
  const def = ENEMIES[e.type];
  const r = e.r;
  const sc = (e.spawnT < 1 ? Math.max(0, easeOutBack(e.spawnT)) : 1) * (1 + e.hitScale * 0.16);
  ctx.save();
  ctx.translate(e.x, e.y);
  ctx.fillStyle = "rgba(0,0,0,0.3)";
  ctx.beginPath();
  ctx.ellipse(0, r * 0.75, r * 0.95, r * 0.4, 0, 0, TAU);
  ctx.fill();
  ctx.scale(sc, sc);
  const bob = Math.sin(time * (e.type === "runner" ? 20 : 7) + e.wob);
  const dx = Math.cos(e.ang);
  const dy = Math.sin(e.ang);

  switch (e.type) {
    case "wisp":
    case "spawnling": {
      for (let i = 3; i >= 1; i--) {
        ctx.globalAlpha = 0.16 * (4 - i);
        ctx.fillStyle = def.color;
        ctx.beginPath();
        ctx.arc(-dx * i * r * 0.55, -dy * i * r * 0.55, r * (0.9 - i * 0.18), 0, TAU);
        ctx.fill();
      }
      ctx.globalAlpha = 1;
      ctx.save();
      ctx.scale(1 + bob * 0.07, 1 - bob * 0.07);
      ctx.fillStyle = def.color;
      ctx.beginPath();
      ctx.arc(0, 0, r, 0, TAU);
      ctx.fill();
      ctx.fillStyle = "rgba(255,255,255,0.55)";
      ctx.beginPath();
      ctx.ellipse(-r * 0.25, -r * 0.35, r * 0.45, r * 0.28, -0.5, 0, TAU);
      ctx.fill();
      ctx.restore();
      ctx.fillStyle = def.dark;
      ctx.beginPath();
      ctx.ellipse(-r * 0.36, 0, r * 0.17, r * 0.27, 0, 0, TAU);
      ctx.ellipse(r * 0.36, 0, r * 0.17, r * 0.27, 0, 0, TAU);
      ctx.fill();
      ctx.fillStyle = "#fff";
      ctx.beginPath();
      ctx.arc(-r * 0.32, -r * 0.08, r * 0.06, 0, TAU);
      ctx.arc(r * 0.4, -r * 0.08, r * 0.06, 0, TAU);
      ctx.fill();
      break;
    }
    case "runner": {
      ctx.rotate(e.ang);
      ctx.strokeStyle = "rgba(255,138,91,0.4)";
      ctx.lineWidth = 2;
      for (let i = -1; i <= 1; i++) {
        ctx.beginPath();
        ctx.moveTo(-r * 1.1, i * r * 0.45);
        ctx.lineTo(-r * (2 + Math.abs(bob) * 0.6), i * r * 0.45);
        ctx.stroke();
      }
      ctx.fillStyle = def.color;
      ctx.beginPath();
      ctx.moveTo(r * 1.25, 0);
      ctx.lineTo(-r * 0.7, r * 0.95);
      ctx.lineTo(-r * 0.25, 0);
      ctx.lineTo(-r * 0.7, -r * 0.95);
      ctx.closePath();
      ctx.fill();
      ctx.fillStyle = def.dark;
      ctx.beginPath();
      ctx.moveTo(r * 0.2, -r * 0.55);
      ctx.lineTo(r * 0.5, -r * 1.15);
      ctx.lineTo(r * 0.65, -r * 0.45);
      ctx.moveTo(r * 0.2, r * 0.55);
      ctx.lineTo(r * 0.5, r * 1.15);
      ctx.lineTo(r * 0.65, r * 0.45);
      ctx.fill();
      ctx.fillStyle = "#fff";
      ctx.beginPath();
      ctx.arc(r * 0.45, 0, r * 0.22, 0, TAU);
      ctx.fill();
      ctx.fillStyle = "#7f1d1d";
      ctx.beginPath();
      ctx.arc(r * 0.52, 0, r * 0.11, 0, TAU);
      ctx.fill();
      break;
    }
    case "brute": {
      ctx.translate(0, bob * 1.2);
      ctx.rotate(Math.sin(time * 3.5 + e.wob) * 0.05);
      ctx.fillStyle = def.dark;
      roundRect(ctx, -r * 0.85, -r * 0.8, r * 1.7, r * 1.7, r * 0.3);
      ctx.fill();
      ctx.fillStyle = def.color;
      roundRect(ctx, -r * 0.55, -r * 1.15, r * 1.1, r * 0.8, r * 0.25);
      ctx.fill();
      ctx.beginPath();
      ctx.arc(-r * 0.95, -r * 0.25, r * 0.48, 0, TAU);
      ctx.arc(r * 0.95, -r * 0.25, r * 0.48, 0, TAU);
      ctx.fill();
      ctx.fillStyle = "#fdba74";
      ctx.fillRect(-r * 0.38, -r * 0.88, r * 0.24, r * 0.2);
      ctx.fillRect(r * 0.14, -r * 0.88, r * 0.24, r * 0.2);
      ctx.strokeStyle = "rgba(251,146,60,0.8)";
      ctx.lineWidth = 1.5;
      ctx.beginPath();
      ctx.moveTo(-r * 0.4, 0);
      ctx.lineTo(-r * 0.1, r * 0.25);
      ctx.lineTo(-r * 0.3, r * 0.6);
      ctx.moveTo(r * 0.3, -r * 0.1);
      ctx.lineTo(r * 0.5, r * 0.3);
      ctx.stroke();
      break;
    }
    case "shaman": {
      ctx.translate(0, bob * 1.4);
      ctx.fillStyle = def.dark;
      ctx.beginPath();
      ctx.moveTo(0, -r * 1.45);
      ctx.quadraticCurveTo(r * 1.1, -r * 0.2, r * 1.0, r * 0.95);
      ctx.lineTo(-r * 1.0, r * 0.95);
      ctx.quadraticCurveTo(-r * 1.1, -r * 0.2, 0, -r * 1.45);
      ctx.fill();
      ctx.fillStyle = "#1e1033";
      ctx.beginPath();
      ctx.ellipse(0, -r * 0.2, r * 0.55, r * 0.5, 0, 0, TAU);
      ctx.fill();
      ctx.fillStyle = "#fde047";
      ctx.beginPath();
      ctx.arc(-r * 0.22, -r * 0.2, r * 0.1, 0, TAU);
      ctx.arc(r * 0.22, -r * 0.2, r * 0.1, 0, TAU);
      ctx.fill();
      const oy = -r * 0.8 + Math.sin(time * 4 + e.wob) * 2.5;
      ctx.fillStyle = def.color;
      ctx.beginPath();
      ctx.arc(r * 1.25, oy, r * 0.32, 0, TAU);
      ctx.fill();
      ctx.globalCompositeOperation = "lighter";
      drawGlow(ctx, "#a855f7", r * 1.25, oy, r * 1.1, 0.8);
      ctx.globalCompositeOperation = "source-over";
      ctx.globalAlpha = 1;
      break;
    }
    case "brood": {
      ctx.rotate(Math.sin(time * 5 + e.wob) * 0.1);
      ctx.fillStyle = def.dark;
      ctx.beginPath();
      ctx.ellipse(0, r * 0.1, r * 0.98, r * 1.1, 0, 0, TAU);
      ctx.fill();
      ctx.fillStyle = def.color;
      ctx.beginPath();
      ctx.ellipse(0, 0, r * 0.9, r * 1.02, 0, 0, TAU);
      ctx.fill();
      ctx.fillStyle = "rgba(77,124,15,0.5)";
      ctx.beginPath();
      ctx.arc(-r * 0.4, r * 0.35, r * 0.2, 0, TAU);
      ctx.arc(r * 0.45, r * 0.2, r * 0.15, 0, TAU);
      ctx.arc(r * 0.1, r * 0.65, r * 0.12, 0, TAU);
      ctx.fill();
      ctx.strokeStyle = "#fef08a";
      ctx.lineWidth = 1.8;
      ctx.beginPath();
      ctx.moveTo(-r * 0.2, -r * 0.9);
      ctx.lineTo(0, -r * 0.5);
      ctx.lineTo(-r * 0.15, -r * 0.2);
      ctx.lineTo(r * 0.15, 0);
      ctx.stroke();
      ctx.fillStyle = "#1a2e05";
      ctx.beginPath();
      ctx.arc(-r * 0.3, -r * 0.05, r * 0.14, 0, TAU);
      ctx.arc(r * 0.35, -r * 0.05, r * 0.14, 0, TAU);
      ctx.fill();
      break;
    }
    case "boss": {
      ctx.translate(0, bob * 1.5);
      const tele = e.timer > 2.9 ? (e.timer - 2.9) / 0.7 : 0;
      ctx.globalCompositeOperation = "lighter";
      drawGlow(ctx, "#fb7185", 0, 0, r * (2.6 + tele), 0.45 + tele * 0.4);
      ctx.globalCompositeOperation = "source-over";
      ctx.globalAlpha = 1;
      ctx.fillStyle = def.dark;
      ctx.beginPath();
      ctx.ellipse(0, r * 0.15, r * 1.05, r * 1.1, 0, 0, TAU);
      ctx.fill();
      ctx.fillStyle = "#3b0d1e";
      ctx.beginPath();
      ctx.ellipse(0, 0, r * 0.95, r, 0, 0, TAU);
      ctx.fill();
      ctx.fillStyle = "#5b1330";
      ctx.beginPath();
      ctx.arc(-r * 1.05, r * 0.1, r * 0.38, 0, TAU);
      ctx.arc(r * 1.05, r * 0.1, r * 0.38, 0, TAU);
      ctx.fill();
      // crown
      ctx.fillStyle = "#fbbf24";
      ctx.beginPath();
      ctx.moveTo(-r * 0.7, -r * 0.7);
      for (let i = 0; i < 5; i++) {
        const cx = -r * 0.7 + (i / 4) * r * 1.4;
        ctx.lineTo(cx, -r * 1.35);
        ctx.lineTo(cx + r * 0.17, -r * 0.8);
      }
      ctx.lineTo(r * 0.7, -r * 0.6);
      ctx.lineTo(-r * 0.7, -r * 0.6);
      ctx.fill();
      ctx.fillStyle = "#fb7185";
      ctx.beginPath();
      ctx.arc(0, -r * 0.82, r * 0.12, 0, TAU);
      ctx.fill();
      // eyes + jaw
      ctx.fillStyle = tele > 0 ? "#ffffff" : "#fda4af";
      ctx.beginPath();
      ctx.ellipse(-r * 0.36, -r * 0.2, r * 0.2, r * 0.26, 0.3, 0, TAU);
      ctx.ellipse(r * 0.36, -r * 0.2, r * 0.2, r * 0.26, -0.3, 0, TAU);
      ctx.fill();
      ctx.fillStyle = "#1c0710";
      ctx.fillRect(-r * 0.5, r * 0.3, r, r * 0.3);
      ctx.fillStyle = "#e5e7eb";
      for (let i = 0; i < 5; i++) ctx.fillRect(-r * 0.46 + i * r * 0.2, r * 0.3, r * 0.1, r * 0.14);
      break;
    }
  }

  if (e.slowT > 0) {
    ctx.globalAlpha = 0.38;
    ctx.fillStyle = "#7dd3fc";
    ctx.beginPath();
    ctx.arc(0, 0, r * 1.05, 0, TAU);
    ctx.fill();
    ctx.globalAlpha = 1;
  }
  if (e.flash > 0) {
    ctx.globalAlpha = Math.min(1, e.flash) * 0.85;
    ctx.fillStyle = "#fff";
    ctx.beginPath();
    ctx.arc(0, 0, r * 1.05, 0, TAU);
    ctx.fill();
    ctx.globalAlpha = 1;
  }
  if (e.stun > 0) {
    ctx.fillStyle = "#fde047";
    for (let i = 0; i < 3; i++) {
      const a = time * 6 + (i / 3) * TAU;
      ctx.beginPath();
      ctx.arc(Math.cos(a) * r * 0.8, -r * 1.3 + Math.sin(a) * 3, 2.2, 0, TAU);
      ctx.fill();
    }
  }
  ctx.restore();

  // health bar
  if (e.hp < e.maxHp - 0.5 && e.type !== "boss") {
    const bw = Math.max(18, r * 2.2);
    const bx = e.x - bw / 2;
    const by = e.y - r - 11;
    ctx.fillStyle = "rgba(8,10,20,0.8)";
    ctx.fillRect(bx - 1, by - 1, bw + 2, 5);
    ctx.fillStyle = "#f8fafc";
    ctx.fillRect(bx, by, bw * Math.max(0, e.shownHp / e.maxHp), 3);
    const f = Math.max(0, e.hp / e.maxHp);
    ctx.fillStyle = f > 0.55 ? "#4ade80" : f > 0.25 ? "#facc15" : "#f87171";
    ctx.fillRect(bx, by, bw * f, 3);
  }
}

// ------------------------------------------------------------------ hero
export function drawHero(ctx: CanvasRenderingContext2D, h: Hero, def: HeroDef, time: number, auraR: number, id: string) {
  ctx.save();
  ctx.translate(h.x, h.y);
  // rally aura
  ctx.globalAlpha = 0.14 + 0.05 * Math.sin(time * 3);
  ctx.fillStyle = def.color;
  ctx.beginPath();
  ctx.arc(0, 0, auraR, 0, TAU);
  ctx.fill();
  ctx.globalAlpha = 0.4;
  ctx.strokeStyle = def.accent;
  ctx.lineWidth = 1.5;
  ctx.setLineDash([7, 9]);
  ctx.lineDashOffset = -time * 24;
  ctx.beginPath();
  ctx.arc(0, 0, auraR, 0, TAU);
  ctx.stroke();
  ctx.setLineDash([]);
  ctx.globalAlpha = 1;

  ctx.fillStyle = "rgba(0,0,0,0.35)";
  ctx.beginPath();
  ctx.ellipse(0, 13, 12, 5, 0, 0, TAU);
  ctx.fill();
  ctx.strokeStyle = def.color;
  ctx.globalAlpha = 0.7;
  ctx.lineWidth = 2;
  ctx.beginPath();
  ctx.ellipse(0, 12, 14 + h.recoil * 3, 6 + h.recoil, 0, 0, TAU);
  ctx.stroke();
  ctx.globalAlpha = 1;

  const bob = h.moving ? Math.sin(time * 18) * 1.8 : Math.sin(time * 3) * 0.8;
  ctx.translate(0, bob);
  const sc = 1 + h.recoil * 0.12;
  ctx.scale(sc, sc);

  // weapon (behind body for pointing away)
  const drawWeapon = () => {
    ctx.save();
    ctx.rotate(h.aim);
    const kick = h.recoil * 3;
    if (id === "kael") {
      ctx.strokeStyle = "#fde68a";
      ctx.lineWidth = 3;
      ctx.lineCap = "round";
      ctx.beginPath();
      ctx.arc(10 - kick, 0, 11, -1.2, 1.2);
      ctx.stroke();
      ctx.strokeStyle = "rgba(255,255,255,0.8)";
      ctx.lineWidth = 1;
      ctx.beginPath();
      ctx.moveTo(10 - kick + Math.cos(1.2) * 11, -Math.sin(1.2) * 11);
      ctx.lineTo(8 - kick - h.recoil * 3, 0);
      ctx.lineTo(10 - kick + Math.cos(1.2) * 11, Math.sin(1.2) * 11);
      ctx.stroke();
    } else {
      ctx.strokeStyle = id === "mira" ? "#7c2d12" : "#4c1d95";
      ctx.lineWidth = 3;
      ctx.lineCap = "round";
      ctx.beginPath();
      ctx.moveTo(-2 - kick, 0);
      ctx.lineTo(16 - kick, 0);
      ctx.stroke();
      ctx.fillStyle = id === "mira" ? "#fb923c" : "#c4b5fd";
      ctx.beginPath();
      ctx.arc(18 - kick, 0, 4.5 + h.recoil * 2, 0, TAU);
      ctx.fill();
    }
    ctx.restore();
  };

  // body / cloak
  ctx.fillStyle = def.color;
  ctx.beginPath();
  ctx.moveTo(-10, 12);
  ctx.quadraticCurveTo(-11, -4, 0, -6);
  ctx.quadraticCurveTo(11, -4, 10, 12);
  ctx.closePath();
  ctx.fill();
  ctx.fillStyle = "rgba(0,0,0,0.22)";
  ctx.beginPath();
  ctx.moveTo(-10, 12);
  ctx.quadraticCurveTo(-10, 5, 0, 5);
  ctx.quadraticCurveTo(10, 5, 10, 12);
  ctx.closePath();
  ctx.fill();
  ctx.fillStyle = def.accent;
  ctx.beginPath();
  ctx.arc(0, 1, 2.6, 0, TAU);
  ctx.fill();

  // head
  ctx.fillStyle = "#ffe2c2";
  ctx.beginPath();
  ctx.arc(0, -10, 7, 0, TAU);
  ctx.fill();
  // headgear
  ctx.fillStyle = id === "kael" ? "#166534" : id === "mira" ? "#9f1239" : "#5b21b6";
  ctx.beginPath();
  if (id === "mira") {
    ctx.moveTo(-10, -11);
    ctx.lineTo(10, -11);
    ctx.lineTo(1, -27);
    ctx.closePath();
    ctx.fill();
    ctx.fillRect(-10, -12, 20, 3);
  } else if (id === "kael") {
    ctx.arc(0, -11, 8, Math.PI, TAU);
    ctx.lineTo(8, -8);
    ctx.lineTo(-8, -8);
    ctx.fill();
  } else {
    ctx.moveTo(-8, -12);
    ctx.lineTo(-6, -20);
    ctx.lineTo(-2, -14);
    ctx.lineTo(1, -22);
    ctx.lineTo(4, -14);
    ctx.lineTo(8, -19);
    ctx.lineTo(8, -12);
    ctx.closePath();
    ctx.fill();
  }
  // eyes look toward aim
  const ex = Math.cos(h.aim) * 2;
  const ey = Math.sin(h.aim) * 1.2;
  ctx.fillStyle = "#1e293b";
  ctx.beginPath();
  ctx.arc(-2.6 + ex, -9 + ey, 1.2, 0, TAU);
  ctx.arc(2.6 + ex, -9 + ey, 1.2, 0, TAU);
  ctx.fill();
  drawWeapon();
  ctx.restore();
}

// ------------------------------------------------------------------ heart
export function drawHeart(ctx: CanvasRenderingContext2D, x: number, y: number, time: number, frac: number, flash: number) {
  const rate = 2 + (1 - frac) * 6;
  const pulse = 1 + Math.sin(time * rate) * 0.05 + flash * 0.18;
  ctx.save();
  ctx.translate(x, y);
  ctx.globalCompositeOperation = "lighter";
  drawGlow(ctx, frac > 0.3 ? "#ff4d8d" : "#ff2a4d", 0, -4, 70 * pulse, 0.45 + flash * 0.4);
  ctx.globalCompositeOperation = "source-over";
  ctx.globalAlpha = 0.55;
  ctx.strokeStyle = "#fb7185";
  ctx.lineWidth = 2;
  ctx.setLineDash([5, 9]);
  ctx.lineDashOffset = time * 14;
  ctx.beginPath();
  ctx.arc(0, 0, 30, 0, TAU);
  ctx.stroke();
  ctx.setLineDash([]);
  ctx.globalAlpha = 1;
  ctx.translate(0, -8 + Math.sin(time * 2) * 3);
  ctx.scale(pulse, pulse);
  const c1 = frac > 0.3 ? "#ff5c93" : "#e11d48";
  const c2 = frac > 0.3 ? "#ff9fc0" : "#fb7185";
  const c3 = frac > 0.3 ? "#c2255c" : "#9f1239";
  ctx.fillStyle = c1;
  ctx.beginPath();
  ctx.moveTo(0, -26);
  ctx.lineTo(17, -8);
  ctx.lineTo(10, 18);
  ctx.lineTo(-10, 18);
  ctx.lineTo(-17, -8);
  ctx.closePath();
  ctx.fill();
  ctx.fillStyle = c2;
  ctx.beginPath();
  ctx.moveTo(0, -26);
  ctx.lineTo(-17, -8);
  ctx.lineTo(-10, 18);
  ctx.lineTo(0, 4);
  ctx.closePath();
  ctx.fill();
  ctx.fillStyle = c3;
  ctx.beginPath();
  ctx.moveTo(0, 4);
  ctx.lineTo(17, -8);
  ctx.lineTo(10, 18);
  ctx.closePath();
  ctx.fill();
  ctx.strokeStyle = "rgba(255,255,255,0.7)";
  ctx.lineWidth = 1.5;
  ctx.beginPath();
  ctx.moveTo(-10, -9);
  ctx.lineTo(-4, -18);
  ctx.stroke();
  if (flash > 0) {
    ctx.globalAlpha = Math.min(1, flash);
    ctx.fillStyle = "#fff";
    ctx.beginPath();
    ctx.moveTo(0, -26);
    ctx.lineTo(17, -8);
    ctx.lineTo(10, 18);
    ctx.lineTo(-10, 18);
    ctx.lineTo(-17, -8);
    ctx.closePath();
    ctx.fill();
  }
  ctx.restore();
}

export function drawPortal(ctx: CanvasRenderingContext2D, x: number, y: number, ang: number, time: number) {
  ctx.save();
  ctx.translate(x, y);
  ctx.rotate(ang);
  ctx.globalCompositeOperation = "lighter";
  drawGlow(ctx, "#a78bfa", 0, 0, 60, 0.6 + Math.sin(time * 3) * 0.1);
  ctx.globalAlpha = 0.85;
  ctx.strokeStyle = "#ddd6fe";
  ctx.lineWidth = 2.5;
  for (let i = 0; i < 3; i++) {
    ctx.beginPath();
    ctx.ellipse(0, 0, 10 + i * 4, 30 - i * 4, 0, time * (2 + i) + i, time * (2 + i) + i + 3.2);
    ctx.stroke();
  }
  ctx.restore();
  ctx.globalAlpha = 1;
}

// ------------------------------------------------------------------ projectiles
export function drawProj(ctx: CanvasRenderingContext2D, p: Proj, time: number, additive: boolean) {
  const ang = Math.atan2(p.vy, p.vx);
  const lift = p.arc > 0 ? Math.sin(Math.PI * Math.min(1, p.prog)) * p.arc : 0;
  if (additive) {
    switch (p.kind) {
      case "harrow":
        drawGlow(ctx, "#86efac", p.x, p.y, 14, 0.7);
        break;
      case "sarrow":
        drawGlow(ctx, "#bbf7d0", p.x, p.y, 17, 0.85);
        break;
      case "arrow":
        drawGlow(ctx, "#fbbf24", p.x, p.y, 9, 0.5);
        break;
      case "fire":
        drawGlow(ctx, "#fb923c", p.x, p.y - lift, 26 + Math.sin(time * 40) * 3, 0.9);
        break;
      case "cannon":
        drawGlow(ctx, "#f97316", p.x, p.y - lift, 14, 0.5);
        break;
      case "frost":
        drawGlow(ctx, "#67e8f9", p.x, p.y, 15, 0.8);
        break;
    }
    return;
  }
  ctx.save();
  switch (p.kind) {
    case "arrow":
    case "harrow":
    case "sarrow": {
      ctx.translate(p.x, p.y);
      ctx.rotate(ang);
      const len = p.kind === "arrow" ? 11 : p.kind === "harrow" ? 14 : 16;
      ctx.strokeStyle = p.kind === "arrow" ? "#fde68a" : "#dcfce7";
      ctx.lineWidth = p.kind === "sarrow" ? 3 : 2.2;
      ctx.lineCap = "round";
      ctx.beginPath();
      ctx.moveTo(-len, 0);
      ctx.lineTo(len * 0.4, 0);
      ctx.stroke();
      ctx.fillStyle = p.kind === "arrow" ? "#fbbf24" : "#4ade80";
      ctx.beginPath();
      ctx.moveTo(len * 0.9, 0);
      ctx.lineTo(len * 0.3, -3.2);
      ctx.lineTo(len * 0.3, 3.2);
      ctx.fill();
      break;
    }
    case "cannon": {
      ctx.fillStyle = "rgba(0,0,0,0.3)";
      ctx.beginPath();
      ctx.ellipse(p.x, p.y + 4, 6, 3, 0, 0, TAU);
      ctx.fill();
      ctx.fillStyle = "#2b2f40";
      ctx.strokeStyle = "#fb923c";
      ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.arc(p.x, p.y - lift, 6.5, 0, TAU);
      ctx.fill();
      ctx.stroke();
      break;
    }
    case "fire": {
      ctx.fillStyle = "rgba(0,0,0,0.25)";
      ctx.beginPath();
      ctx.ellipse(p.x, p.y + 4, 6, 3, 0, 0, TAU);
      ctx.fill();
      ctx.fillStyle = "#f97316";
      ctx.beginPath();
      ctx.arc(p.x, p.y - lift, 8, 0, TAU);
      ctx.fill();
      ctx.fillStyle = "#fde047";
      ctx.beginPath();
      ctx.arc(p.x, p.y - lift, 4.5, 0, TAU);
      ctx.fill();
      break;
    }
    case "frost": {
      ctx.translate(p.x, p.y);
      ctx.rotate(time * 8);
      ctx.fillStyle = "#e0f7ff";
      ctx.beginPath();
      ctx.moveTo(0, -7);
      ctx.lineTo(4, 0);
      ctx.lineTo(0, 7);
      ctx.lineTo(-4, 0);
      ctx.fill();
      break;
    }
  }
  ctx.restore();
}
