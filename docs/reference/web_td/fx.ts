// Particle system + cached glow sprites. Everything is pooled to avoid GC hiccups.

export type PKind = "spark" | "dot" | "ring" | "text" | "coin" | "shard" | "smoke" | "bolt";

export interface P {
  kind: PKind;
  x: number;
  y: number;
  vx: number;
  vy: number;
  life: number;
  max: number;
  size: number;
  size2: number;
  color: string;
  rot: number;
  vr: number;
  drag: number;
  grav: number;
  text: string;
  alpha: number;
  add: boolean;
  lw: number;
  pts: number[] | null;
  tx: number;
  ty: number;
  hold: number;
  sx: number;
  sy: number;
  flag: boolean;
}

const glowCache = new Map<string, HTMLCanvasElement>();

export function glowSprite(color: string): HTMLCanvasElement {
  let c = glowCache.get(color);
  if (c) return c;
  c = document.createElement("canvas");
  c.width = c.height = 64;
  const g = c.getContext("2d")!;
  const grd = g.createRadialGradient(32, 32, 0, 32, 32, 32);
  grd.addColorStop(0, "#ffffff");
  grd.addColorStop(0.14, color);
  grd.addColorStop(0.45, color + "66");
  grd.addColorStop(1, color + "00");
  g.fillStyle = grd;
  g.fillRect(0, 0, 64, 64);
  glowCache.set(color, c);
  return c;
}

export function drawGlow(ctx: CanvasRenderingContext2D, color: string, x: number, y: number, r: number, alpha = 1) {
  ctx.globalAlpha = alpha;
  ctx.drawImage(glowSprite(color), x - r, y - r, r * 2, r * 2);
}

const blank = (): P => ({
  kind: "dot",
  x: 0,
  y: 0,
  vx: 0,
  vy: 0,
  life: 0,
  max: 1,
  size: 3,
  size2: 0,
  color: "#fff",
  rot: 0,
  vr: 0,
  drag: 0,
  grav: 0,
  text: "",
  alpha: 1,
  add: false,
  lw: 2,
  pts: null,
  tx: 0,
  ty: 0,
  hold: 0,
  sx: 0,
  sy: 0,
  flag: false,
});

const FONT = "Rajdhani, 'Segoe UI', system-ui, sans-serif";

export class Particles {
  list: P[] = [];
  private pool: P[] = [];
  readonly cap = 1000;
  texts = 0;
  constructor(private onCoin: () => void) {}

  clear() {
    for (const p of this.list) this.pool.push(p);
    this.list.length = 0;
    this.texts = 0;
  }

  emit(kind: PKind, x: number, y: number, o: Partial<P> = {}): P | null {
    if (this.list.length >= this.cap && kind !== "text" && kind !== "coin") return null;
    if (kind === "text" && this.texts > 36) return null;
    const p = this.pool.pop() ?? blank();
    Object.assign(p, blank(), o);
    p.kind = kind;
    p.x = x;
    p.y = y;
    if (kind === "text") this.texts++;
    this.list.push(p);
    return p;
  }

  update(dt: number) {
    const L = this.list;
    for (let i = L.length - 1; i >= 0; i--) {
      const p = L[i];
      p.life += dt;
      if (p.life >= p.max) {
        if (p.kind === "coin") this.onCoin();
        if (p.kind === "text") this.texts--;
        L[i] = L[L.length - 1];
        L.pop();
        this.pool.push(p);
        continue;
      }
      if (p.kind === "coin") {
        if (p.life < p.hold) {
          p.vy += 700 * dt;
          p.x += p.vx * dt;
          p.y += p.vy * dt;
          p.vx *= 0.96;
        } else {
          if (!p.flag) {
            p.flag = true;
            p.sx = p.x;
            p.sy = p.y;
          }
          const k = (p.life - p.hold) / (p.max - p.hold);
          const e = k * k * (3 - 2 * k) * 0.35 + k * k * k * 0.65;
          p.x = p.sx + (p.tx - p.sx) * e;
          p.y = p.sy + (p.ty - p.sy) * e - Math.sin(k * Math.PI) * 30;
        }
        p.rot += p.vr * dt;
        continue;
      }
      if (p.drag) {
        const f = Math.exp(-p.drag * dt);
        p.vx *= f;
        p.vy *= f;
      }
      p.vy += p.grav * dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.rot += p.vr * dt;
    }
  }

  draw(ctx: CanvasRenderingContext2D, additive: boolean) {
    const L = this.list;
    for (let i = 0; i < L.length; i++) {
      const p = L[i];
      if (p.add !== additive) continue;
      const k = p.life / p.max;
      switch (p.kind) {
        case "spark": {
          const s = p.size + (p.size2 - p.size) * k;
          drawGlow(ctx, p.color, p.x, p.y, s * 2.2, (1 - k) * p.alpha);
          break;
        }
        case "dot": {
          const s = p.size + (p.size2 - p.size) * k;
          ctx.globalAlpha = (1 - k * k) * p.alpha;
          ctx.fillStyle = p.color;
          ctx.beginPath();
          ctx.arc(p.x, p.y, Math.max(0.1, s), 0, 6.2832);
          ctx.fill();
          break;
        }
        case "smoke": {
          const s = p.size + (p.size2 - p.size) * k;
          ctx.globalAlpha = (1 - k) * p.alpha * 0.4;
          ctx.fillStyle = p.color;
          ctx.beginPath();
          ctx.arc(p.x, p.y, Math.max(0.1, s), 0, 6.2832);
          ctx.fill();
          break;
        }
        case "ring": {
          const e = 1 - (1 - k) * (1 - k) * (1 - k);
          const r = p.size + (p.size2 - p.size) * e;
          ctx.globalAlpha = (1 - k) * p.alpha;
          ctx.strokeStyle = p.color;
          ctx.lineWidth = Math.max(0.5, p.lw * (1 - k * 0.7));
          ctx.beginPath();
          ctx.arc(p.x, p.y, Math.max(0.5, r), 0, 6.2832);
          ctx.stroke();
          break;
        }
        case "shard": {
          const s = p.size * (1 - k * 0.6);
          ctx.globalAlpha = (1 - k * k) * p.alpha;
          ctx.fillStyle = p.color;
          ctx.save();
          ctx.translate(p.x, p.y);
          ctx.rotate(p.rot);
          ctx.beginPath();
          ctx.moveTo(s, 0);
          ctx.lineTo(-s * 0.6, s * 0.55);
          ctx.lineTo(-s * 0.6, -s * 0.55);
          ctx.closePath();
          ctx.fill();
          ctx.restore();
          break;
        }
        case "coin": {
          const s = 6 + (k > 0.5 ? 0 : 0);
          const squash = Math.abs(Math.cos(p.rot));
          ctx.globalAlpha = 1;
          ctx.fillStyle = "#fbbf24";
          ctx.strokeStyle = "#92400e";
          ctx.lineWidth = 1.5;
          ctx.beginPath();
          ctx.ellipse(p.x, p.y, s * (0.35 + squash * 0.65), s, 0, 0, 6.2832);
          ctx.fill();
          ctx.stroke();
          break;
        }
        case "text": {
          const pop = k < 0.15 ? 0.6 + (k / 0.15) * 0.6 : 1.2 - Math.min(0.2, (k - 0.15) * 0.4);
          ctx.globalAlpha = k > 0.6 ? 1 - (k - 0.6) / 0.4 : 1;
          ctx.font = `800 ${Math.round(p.size * pop)}px ${FONT}`;
          ctx.textAlign = "center";
          ctx.textBaseline = "middle";
          ctx.lineWidth = 3;
          ctx.strokeStyle = "rgba(8,10,20,0.85)";
          ctx.lineJoin = "round";
          ctx.strokeText(p.text, p.x, p.y);
          ctx.fillStyle = p.color;
          ctx.fillText(p.text, p.x, p.y);
          break;
        }
        case "bolt": {
          const pts = p.pts;
          if (!pts) break;
          const a = 1 - k;
          ctx.lineJoin = "round";
          ctx.lineCap = "round";
          ctx.globalAlpha = a * 0.55;
          ctx.strokeStyle = p.color;
          ctx.lineWidth = p.lw * 3.2;
          ctx.beginPath();
          ctx.moveTo(pts[0], pts[1]);
          for (let j = 2; j < pts.length; j += 2) ctx.lineTo(pts[j], pts[j + 1]);
          ctx.stroke();
          ctx.globalAlpha = a;
          ctx.strokeStyle = "#ffffff";
          ctx.lineWidth = p.lw;
          ctx.beginPath();
          ctx.moveTo(pts[0], pts[1]);
          for (let j = 2; j < pts.length; j += 2) ctx.lineTo(pts[j], pts[j + 1]);
          ctx.stroke();
          break;
        }
      }
    }
    ctx.globalAlpha = 1;
  }
}
