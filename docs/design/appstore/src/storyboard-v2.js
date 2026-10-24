// Storyboard for v2 (one continuous take) of the App Store header / search-results video:
//   node docs/design/appstore/src/storyboard-v2.js
// Writes storyboard-v2-header.svg (21:9, 3840x1646 per frame) and storyboard-v2-search.svg (3:2, 3840x2560 per frame).
// The glass parts (mark-corner-*.png, mark-qr.png) are rendered with fresnel from docs/design/icon (see VIDEO.md §5).
const fs = require('fs');
const path = require('path');

const OUT = path.join(__dirname, '..');
const PUB = path.join(__dirname, '../../../../appstore/video/public');
const img = (f) => 'data:image/' + (f.endsWith('.png') ? 'png' : 'jpeg') + ';base64,' + fs.readFileSync(path.join(PUB, f)).toString('base64');
// Each picture is embedded once as a <symbol> and placed with <use>.
const SOURCES = {
  url: ['shot-02-result-url.jpg', 1320, 2868], history: ['shot-01-history.jpg', 1320, 2868], create: ['shot-04-create.jpg', 1320, 2868],
  qr: ['mark-qr.png', 1, 1], tl: ['mark-corner-tl.png', 1, 1], tr: ['mark-corner-tr.png', 1, 1],
  bl: ['mark-corner-bl.png', 1, 1], br: ['mark-corner-br.png', 1, 1],
};
const SYMBOLS = Object.entries(SOURCES).map(([k, [f, w, h]]) =>
  `<symbol id="img-${k}" viewBox="0 0 ${w} ${h}" preserveAspectRatio="xMidYMid slice"><image href="${img(f)}" width="${w}" height="${h}" preserveAspectRatio="none"/></symbol>`).join('');
const IMG = Object.fromEntries(Object.keys(SOURCES).map((k) => [k, k]));
const pic = (k, x, y, w, h, extra = '') => `<use href="#img-${k}" x="${x}" y="${y}" width="${w}" height="${h}"${extra}/>`;
const FONT = "'Noto Sans CJK JP', 'Hiragino Sans', sans-serif";
const MINT = '#7FF0D2';
const esc = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;');
const text = (x, y, s, size, o = {}) =>
  `<text x="${x}" y="${y}" font-size="${size}" font-weight="${o.weight || 800}" fill="${o.fill || '#fff'}" text-anchor="${o.anchor || 'middle'}" opacity="${o.opacity ?? 1}">${esc(s)}</text>`;
let uid = 0;
const id = (p) => `${p}${++uid}`;

// ---- The one shape: the icon's four glass viewfinder corners, plus the glass QR ----
// Mark space is the icon's 1024 grid; `px` is how wide that grid is drawn. `gap` pushes each corner outward
// (positive: wider than in the icon, negative: squeezed). `box` frames a rectangle instead (corner tips on its corners).
function corners(cx, cy, px, gap = 0, o = {}) {
  const half = px / 2;
  const at = o.box
    ? { tl: [o.box.x - 0.18 * px, o.box.y - 0.18 * px], tr: [o.box.x + o.box.w - 0.32 * px, o.box.y - 0.18 * px],
        bl: [o.box.x - 0.18 * px, o.box.y + o.box.h - 0.32 * px], br: [o.box.x + o.box.w - 0.32 * px, o.box.y + o.box.h - 0.32 * px] }
    : { tl: [cx - half - gap, cy - half - gap], tr: [cx - gap * -1, cy - half - gap], bl: [cx - half - gap, cy + gap], br: [cx + gap, cy + gap] };
  let s = '';
  for (const k of ['tl', 'tr', 'bl', 'br']) {
    s += pic(k, at[k][0], at[k][1], half, half);
  }
  if (o.mint) {
    // Locked: the corners take on the mint tint (drawn as a mint overlay in the storyboard).
    s = `<g filter="url(#mint)">${s}</g>`;
  }
  return s;
}
const qr = (cx, cy, px, opacity = 1) => pic('qr', cx - px / 2, cy - px / 2, px, px, ` opacity="${opacity}"`);
const ripple = (cx, cy, r, w, opacity) => `<circle cx="${cx}" cy="${cy}" r="${r}" fill="none" stroke="${MINT}" stroke-width="${w}" opacity="${opacity}"/>`;

// ---- iPhone (thin bezel), with optional sliding screens and an expanded Dynamic Island ----
function phone(cx, cy, h, screens, o = {}) {
  const w = h * 0.4795, r = h * 0.085, bez = h * 0.016;
  const sx = cx - w / 2 + bez, sy = cy - h / 2 + bez, sw = w - bez * 2, sh = h - bez * 2;
  const clip = id('scr');
  let shots = '';
  screens.forEach(([shot, offset]) => {
    shots += pic(shot, sx + offset * sw, sy, sw, sh);
  });
  const island = o.lock
    ? `<rect x="${cx - w * 0.3}" y="${sy + h * 0.012}" width="${w * 0.6}" height="${h * 0.05}" rx="${h * 0.025}" fill="#000"/>` + lock(cx, sy + h * 0.037, h * 0.032, MINT)
    : `<rect x="${cx - w * 0.16}" y="${sy + h * 0.012}" width="${w * 0.32}" height="${h * 0.026}" rx="${h * 0.013}" fill="#000"/>`;
  return `<g>
    <rect x="${cx - w / 2}" y="${cy - h / 2 + h * 0.03}" width="${w}" height="${h}" rx="${r}" fill="#00271F" opacity=".28"/>
    <rect x="${cx - w / 2}" y="${cy - h / 2}" width="${w}" height="${h}" rx="${r}" fill="#101513"/>
    <clipPath id="${clip}"><rect x="${sx}" y="${sy}" width="${sw}" height="${sh}" rx="${r - bez}"/></clipPath>
    <g clip-path="url(#${clip})"><rect x="${sx}" y="${sy}" width="${sw}" height="${sh}" fill="#F2F2F7"/>${shots}</g>${island}</g>`;
}
const phoneBox = (cx, cy, h) => ({ x: cx - (h * 0.4795) / 2, y: cy - h / 2, w: h * 0.4795, h });
function lock(cx, cy, s, color = '#fff') {
  return `<g fill="none" stroke="${color}" stroke-width="${s * 0.11}" stroke-linecap="round"><rect x="${cx - s * 0.36}" y="${cy - s * 0.05}" width="${s * 0.72}" height="${s * 0.5}" rx="${s * 0.1}"/><path d="M${cx - s * 0.22} ${cy - s * 0.05} V${cy - s * 0.2} a${s * 0.22} ${s * 0.22} 0 0 1 ${s * 0.44} 0 V${cy - s * 0.05}"/></g>`;
}

// ---- Headline that rises from (and rolls back into) a mask line ----
// `t`: 0 = resting, -1..0 = rolling up out, 0..1 = rising in (1 = still below the line).
function headline(x, top, lines, size, sub, subSize, t = 0, o = {}) {
  const lineH = size * 1.22;
  const height = lines.length * lineH + (sub ? subSize * 1.7 : 0);
  const clip = id('mask');
  const dy = t * height;
  let s = `<clipPath id="${clip}"><rect x="${x - 2000}" y="${top - size * 0.1}" width="4000" height="${height + size * 0.2}"/></clipPath><g clip-path="url(#${clip})"><g transform="translate(0 ${dy})">`;
  lines.forEach((l, i) => { s += text(x, top + size + i * lineH, l, size, { anchor: o.anchor }); });
  if (sub) s += text(x, top + lines.length * lineH + subSize * 1.35, sub, subSize, { weight: 500, opacity: 0.88, anchor: o.anchor });
  s += '</g></g>';
  if (o.showMask) {
    s += `<line x1="${x - 760}" x2="${x + 760}" y1="${top + height + size * 0.1}" y2="${top + height + size * 0.1}" stroke="#FFD166" stroke-width="8" stroke-dasharray="26 18"/>`;
  }
  return s;
}

// ---- App icon tile: the icon's own gradient in a squircle ----
function iconTile(cx, cy, size) {
  const r = size * 0.2237;
  return `<rect x="${cx - size / 2}" y="${cy - size / 2 + size * 0.04}" width="${size}" height="${size}" rx="${r}" fill="#00271F" opacity=".3"/>
    <rect x="${cx - size / 2}" y="${cy - size / 2}" width="${size}" height="${size}" rx="${r}" fill="url(#iconFill)"/>
    <rect x="${cx - size / 2 + 3}" y="${cy - size / 2 + 3}" width="${size - 6}" height="${size - 6}" rx="${r - 3}" fill="none" stroke="#fff" stroke-opacity=".28" stroke-width="6"/>`;
}

const note = (x, y, s, size = 64) => `<g><rect x="${x - 24}" y="${y - size * 1.05}" width="${s.length * size * 0.98 + 48}" height="${size * 1.45}" rx="${size * 0.35}" fill="#FFD166"/>${text(x, y, s, size, { fill: '#3D2E00', anchor: 'start', weight: 700 })}</g>`;
const arrow = (x1, y1, x2, y2) => `<line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="#FFD166" stroke-width="12" stroke-linecap="round" marker-end="url(#arrow)"/>`;
const safeArea = (W, H) => `<rect x="${W * 0.2}" y="0" width="${W * 0.6}" height="${H}" fill="none" stroke="#FFD166" stroke-width="6" stroke-dasharray="30 24" opacity=".7"/>`;

// ---- Header (3840x1646) keyframes ----
function headerFrames() {
  const W = 3840, H = 1646;
  const M = { x: W / 2, y: H / 2, px: 1204 }; // scene ① mark (the code is 400px wide, as in v1)
  const P = { x: 2560, y: 850, h: 1400 }; // phone
  const box = phoneBox(P.x, P.y, P.h);
  const frame = { ...box, x: box.x - 70, y: box.y - 60, w: box.w + 140, h: box.h + 120 };
  const T = { x: 1440, top: 560, size: 150, sub: 80 };
  const I = { x: W / 2, y: 610, size: 440 };
  const copy = {
    scan: [['かざすだけ。'], ''],
    extras: [['余計なものは、', '入れていない。'], '広告も、アクセス解析も。'],
    once: [['毎月の支払いは、', 'いらない。'], '必要なら、一度買うだけ。'],
    local: [['読んだ中身は、', 'どこにも送らない。'], 'ぜんぶ、この iPhone の中で。'],
  };
  const hl = (c, t = 0, o) => headline(T.x, T.top, copy[c][0], T.size, copy[c][1], T.sub, t, o);
  return [
    ['① 0.0 秒 枠が寄ってくる（アイコンの中から始まる）', () => corners(M.x, M.y, M.px, 150) + qr(M.x, M.y, M.px) + note(120, 160, '背景＝アイコンの地のグラデーション。ガラスの角と QR はアイコンそのもの')],
    ['② 1.5 秒 読み取れた（ミントに光り、中心から波紋）', () => corners(M.x, M.y, M.px, -18, { mint: true }) + qr(M.x, M.y, M.px) +
      ripple(M.x, M.y, 560, 14, 0.5) + ripple(M.x, M.y, 760, 9, 0.25)],
    ['②→③ 2.2 秒 QR から画面が広がり、角が iPhone を囲む位置へ', () => {
      const h = 980, b = phoneBox(2380, 840, h);
      return corners(0, 0, 900, 0, { box: { ...b, x: b.x - 60, y: b.y - 50, w: b.w + 120, h: b.h + 100 } }) +
        `<rect x="${2380 - 300}" y="${840 - 420}" width="600" height="840" rx="70" fill="#F2F2F7"/>` +
        pic('url', 2380 - 300, 840 - 420, 600, 840, ' opacity=".9"') +
        qr(2380, 840, 380, 0.5) + arrow(1960, 830, 2160, 830) + note(120, 160, '画面は QR の位置から角丸の四角として伸びる（置き換えずに変形）。カメラは一度だけ引く');
    }],
    ['③ 3.0 秒 かざすだけ。（線の下からせり上がる）', () => corners(0, 0, 840, 0, { box: frame }) + phone(P.x, P.y, P.h, [[IMG.url, 0]]) + hl('scan', 0, { showMask: true })],
    ['④ 6.0 秒 文字は縦に入れ替わり、画面は横に送られる', () => corners(0, 0, 840, 0, { box: frame }) +
      phone(P.x, P.y, P.h, [[IMG.url, -0.45], [IMG.history, 0.55]]) + hl('scan', -0.55) + hl('extras', 0.45, { showMask: true }) +
      note(120, 160, '文字の入れ替え＝縦ロール 0.35 秒。画面の切り替え＝横送り 0.45 秒。フェードは使わない')],
    ['④ 6.5 秒 余計なものは、入れていない。', () => corners(0, 0, 840, 0, { box: frame }) + phone(P.x, P.y, P.h, [[IMG.history, 0]]) + hl('extras')],
    ['⑤ 9.0 秒 毎月の支払いは、いらない。（作成画面）', () => corners(0, 0, 840, 0, { box: frame }) + phone(P.x, P.y, P.h, [[IMG.create, 0]]) + hl('once')],
    ['⑥ 12.0 秒 ダイナミックアイランドが伸びて鍵に', () => corners(0, 0, 840, 0, { box: frame }) + phone(P.x, P.y, P.h, [[IMG.history, 0]], { lock: true }) + hl('local') +
      note(120, 160, '鍵は別の絵を重ねず、アイランドが横に伸びて中に鍵が現れる')],
    ['⑦ 13.8 秒 iPhone が縮みながらアイコンの形へ。角は内側へ戻る', () => {
      const s = 760, cx = 2300, cy = 760;
      return `<rect x="${cx - s * 0.36}" y="${cy - s * 0.6}" width="${s * 0.72}" height="${s * 1.2}" rx="${s * 0.17}" fill="url(#iconFill)"/>` +
        corners(cx, cy, s * 0.9, 40) + qr(cx, cy, s * 0.9, 0.7) + arrow(2900, 760, 2700, 760) + hl('local', -0.6) +
        note(120, 160, '画面は緑で満たされ、縦長の角丸がアイコンの角丸四角へ。角と QR がアイコンの配置に収まる');
    }],
    ['⑦ 14.2 秒 誠実QRリーダー（ちゃんと、読むだけ。）', () => iconTile(I.x, I.y, I.size) + corners(I.x, I.y, I.size) + qr(I.x, I.y, I.size) +
      headline(W / 2, 960, ['誠実QRリーダー'], 170, 'ちゃんと、読むだけ。', 90)],
    ['→ 14.7 秒 アイコンが画面いっぱいに広がり ① の 1 コマ目へ（継ぎ目なし）', () => iconTile(W / 2, H / 2, 3000) + corners(M.x, M.y, M.px * 0.82, 90) + qr(M.x, M.y, M.px * 0.82) +
      arrow(3500, 300, 3720, 140) + arrow(340, 1350, 120, 1520) +
      note(120, 160, 'アイコンの角丸四角が画面の外まで広がる＝アイコンの中へ入る。最終コマ＝最初のコマ')],
  ];
}

// ---- Search results (3840x2560) keyframes ----
function searchFrames() {
  const W = 3840, H = 2560;
  const M = { x: W / 2, y: H * 0.47, px: 1566 };
  const P = { x: W / 2, y: 1920, h: 2000 }; // the bottom of the phone runs off the frame
  const box = phoneBox(P.x, P.y, P.h);
  const frame = { ...box, x: box.x - 80, y: box.y - 70, w: box.w + 160, h: box.h + 140 };
  const T = { x: W / 2, top: 100, size: 180, sub: 92 };
  const I = { x: W / 2, y: 1000, size: 600 };
  const hl = (lines, sub, t = 0, o) => headline(T.x, T.top, lines, T.size, sub, T.sub, t, o);
  return [
    ['① 0.0 秒 枠が寄ってくる', () => corners(M.x, M.y, M.px, 190) + qr(M.x, M.y, M.px)],
    ['② 1.5 秒 読み取れた', () => corners(M.x, M.y, M.px, -22, { mint: true }) + qr(M.x, M.y, M.px) + ripple(M.x, M.y, 720, 18, 0.5) + ripple(M.x, M.y, 980, 12, 0.25)],
    ['③ 3.0 秒 かざすだけ。', () => corners(0, 0, 1100, 0, { box: frame }) + phone(P.x, P.y, P.h, [[IMG.url, 0]]) + hl(['かざすだけ。'], '', 0, { showMask: true })],
    ['④ 6.0 秒 余計なものは…', () => corners(0, 0, 1100, 0, { box: frame }) + phone(P.x, P.y, P.h, [[IMG.history, 0]]) + hl(['余計なものは、', '入れていない。'], '広告も、アクセス解析も。')],
    ['⑤ 9.0 秒 毎月の支払いは…', () => corners(0, 0, 1100, 0, { box: frame }) + phone(P.x, P.y, P.h, [[IMG.create, 0]]) + hl(['毎月の支払いは、', 'いらない。'], '必要なら、一度買うだけ。')],
    ['⑥ 12.0 秒 どこにも送らない（鍵）', () => corners(0, 0, 1100, 0, { box: frame }) + phone(P.x, P.y, P.h, [[IMG.history, 0]], { lock: true }) + hl(['読んだ中身は、', 'どこにも送らない。'], 'ぜんぶ、この iPhone の中で。')],
    ['⑦ 14.2 秒 誠実QRリーダー', () => iconTile(I.x, I.y, I.size) + corners(I.x, I.y, I.size) + qr(I.x, I.y, I.size) + headline(W / 2, 1460, ['誠実QRリーダー'], 220, 'ちゃんと、読むだけ。', 110)],
    ['→ 14.7 秒 アイコンが広がり ① へ', () => iconTile(W / 2, H / 2, 4200) + corners(M.x, M.y, M.px * 0.82, 110) + qr(M.x, M.y, M.px * 0.82)],
  ];
}

function sheet(file, title, W, H, frames, cols, scale) {
  const fw = W * scale, fh = H * scale, gap = 80, top = 330;
  const rows = Math.ceil(frames.length / cols);
  const SWd = cols * fw + (cols - 1) * gap + 160, SHd = top + rows * (fh + 120) + 60;
  let body = '';
  frames.forEach(([label, draw], i) => {
    const x = 80 + (i % cols) * (fw + gap), y = top + Math.floor(i / cols) * (fh + 120);
    body += `<text x="${x}" y="${y - 24}" font-size="34" font-weight="700" fill="#3A3A3C">${esc(label)}</text>` +
      `<svg x="${x}" y="${y}" width="${fw}" height="${fh}" viewBox="0 0 ${W} ${H}"><clipPath id="c${i}"><rect width="${W}" height="${H}" rx="40"/></clipPath><g clip-path="url(#c${i})"><rect width="${W}" height="${H}" fill="url(#bg)"/>${draw()}${safeArea(W, H)}</g></svg>`;
  });
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${SWd}" height="${SHd}" viewBox="0 0 ${SWd} ${SHd}" font-family="${FONT}">
  <defs>${SYMBOLS}<linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#16A386"/><stop offset="1" stop-color="#0A5F4E"/></linearGradient>
  <linearGradient id="iconFill" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#16A386"/><stop offset="1" stop-color="#0A5F4E"/></linearGradient>
  <filter id="mint"><feColorMatrix type="matrix" values="0.5 0 0 0 0.25  0 0.94 0 0 0.03  0 0 0.82 0 0.01  0 0 0 1 0"/></filter>
  <marker id="arrow" viewBox="0 0 10 10" refX="6" refY="5" markerWidth="4" markerHeight="4" orient="auto"><path d="M0 0L10 5L0 10z" fill="#FFD166"/></marker></defs>
  <rect width="${SWd}" height="${SHd}" fill="#F2F2F4"/>
  <text x="80" y="90" font-size="56" font-weight="800" fill="#1C1C1E">${esc(title)}</text>
  <text x="80" y="145" font-size="30" fill="#636366">v2：ワンカット（切り替えなし）。アイコンのガラスの角が最初から最後まで一つの形として残り、QR → iPhone → アイコンを順に囲む。</text>
  <text x="80" y="190" font-size="30" fill="#636366">フェード・クロスフェードは使わない。文字は線の下からせり上がり、画面は横に送られ、形は変形でつながる。最後のコマ＝最初のコマ。</text>
  <text x="80" y="235" font-size="30" fill="#636366">黄色の点線の枠は文字と iPhone を収める中央 60% の範囲、黄色の注記と矢印は説明用（動画には入らない）。15 秒でループ、音なし。</text>
  ${body}</svg>`;
  fs.writeFileSync(path.join(OUT, file), svg);
}
sheet('storyboard-v2-header.svg', 'App Store ヘッダ動画 v2（21:9・3840×1646）絵コンテ', 3840, 1646, headerFrames(), 2, 0.25);
sheet('storyboard-v2-search.svg', 'App Store 検索結果動画 v2（3:2・3840×2560）絵コンテ', 3840, 2560, searchFrames(), 4, 0.16);
console.log('wrote storyboard-v2-header.svg, storyboard-v2-search.svg');
