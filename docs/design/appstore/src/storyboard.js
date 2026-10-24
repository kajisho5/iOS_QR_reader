// Storyboard for the App Store header / search-results video: node docs/design/appstore/src/storyboard.js
// Writes storyboard-header.svg (21:9, 3840x1646 per frame) and storyboard-search.svg (3:2, 3840x2560 per frame).
const fs = require('fs');
const path = require('path');

const OUT = path.join(__dirname, '..');
const PUB = path.join(__dirname, '../../../../appstore/video/public');
const img = (f) => 'data:image/' + (f.endsWith('.png') ? 'png' : 'jpeg') + ';base64,' + fs.readFileSync(path.join(PUB, f)).toString('base64');
const SHOTS = {
  url: img('shot-02-result-url.jpg'), history: img('shot-01-history.jpg'), create: img('shot-04-create.jpg'), icon: img('icon.png'),
};
const FONT = "'Noto Sans CJK JP', 'Hiragino Sans', sans-serif";
const esc = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;');
const text = (x, y, s, size, o = {}) =>
  `<text x="${x}" y="${y}" font-size="${size}" font-weight="${o.weight || 800}" fill="${o.fill || '#fff'}" text-anchor="${o.anchor || 'middle'}" opacity="${o.opacity ?? 1}"${o.ls ? ` letter-spacing="${o.ls}"` : ''}>${esc(s)}</text>`;

// Decorative QR glyph (not a real code).
function qr(cx, cy, size, opacity = 1) {
  const n = 21, c = size / n;
  const on = (r, k) => {
    const finder = (r0, c0) => r >= r0 && r < r0 + 7 && k >= c0 && k < c0 + 7 &&
      (r === r0 || r === r0 + 6 || k === c0 || k === c0 + 6 || (r >= r0 + 2 && r <= r0 + 4 && k >= c0 + 2 && k <= c0 + 4));
    if (finder(0, 0) || finder(0, 14) || finder(14, 0)) return true;
    if ((r < 8 && (k < 8 || k > 12)) || (r > 12 && k < 8)) return false;
    return ((r * 7 + k * 13 + r * k) % 5) < 2;
  };
  let s = `<g opacity="${opacity}"><rect x="${cx - size / 2 - c * 2}" y="${cy - size / 2 - c * 2}" width="${size + c * 4}" height="${size + c * 4}" rx="${c * 2}" fill="#fff"/>`;
  for (let r = 0; r < n; r++) for (let k = 0; k < n; k++) if (on(r, k)) s += `<rect x="${cx - size / 2 + k * c}" y="${cy - size / 2 + r * c}" width="${c}" height="${c}" fill="#0A3B31"/>`;
  return s + '</g>';
}
function reticle(cx, cy, size, color = '#fff', glow = false) {
  const h = size / 2, a = size * 0.22, w = size * 0.035;
  const corner = (sx, sy) => `<path d="M${cx + sx * h} ${cy + sy * (h - a)} V${cy + sy * h} H${cx + sx * (h - a)}" fill="none" stroke="${color}" stroke-width="${w}" stroke-linecap="round" stroke-linejoin="round"/>`;
  return (glow ? `<circle cx="${cx}" cy="${cy}" r="${size * 0.62}" fill="none" stroke="#7FF0D2" stroke-width="${w * 0.6}" opacity=".45"/><circle cx="${cx}" cy="${cy}" r="${size * 0.8}" fill="none" stroke="#7FF0D2" stroke-width="${w * 0.4}" opacity=".2"/>` : '') +
    corner(-1, -1) + corner(1, -1) + corner(-1, 1) + corner(1, 1);
}
function phone(cx, cy, h, shot, o = {}) {
  const w = h * 0.4795, r = h * 0.085, bez = h * 0.018;
  const id = 'p' + Math.round(cx) + Math.round(cy) + Math.round(h);
  return `<g opacity="${o.opacity ?? 1}" transform="rotate(${o.rotate || 0} ${cx} ${cy})">
    <rect x="${cx - w / 2 + h * 0.02}" y="${cy - h / 2 + h * 0.04}" width="${w}" height="${h}" rx="${r}" fill="#000" opacity=".25"/>
    <rect x="${cx - w / 2}" y="${cy - h / 2}" width="${w}" height="${h}" rx="${r}" fill="#111614"/>
    <clipPath id="${id}"><rect x="${cx - w / 2 + bez}" y="${cy - h / 2 + bez}" width="${w - bez * 2}" height="${h - bez * 2}" rx="${r - bez}"/></clipPath>
    <image href="${shot}" x="${cx - w / 2 + bez}" y="${cy - h / 2 + bez}" width="${w - bez * 2}" height="${h - bez * 2}" preserveAspectRatio="xMidYMid slice" clip-path="url(#${id})"/>
    <rect x="${cx - w * 0.16}" y="${cy - h / 2 + bez * 1.8}" width="${w * 0.32}" height="${h * 0.026}" rx="${h * 0.013}" fill="#000"/>
  </g>`;
}
function lock(cx, cy, s) {
  return `<g fill="none" stroke="#fff" stroke-width="${s * 0.09}" stroke-linecap="round"><rect x="${cx - s * 0.36}" y="${cy - s * 0.05}" width="${s * 0.72}" height="${s * 0.5}" rx="${s * 0.1}"/><path d="M${cx - s * 0.22} ${cy - s * 0.05} V${cy - s * 0.2} a${s * 0.22} ${s * 0.22} 0 0 1 ${s * 0.44} 0 V${cy - s * 0.05}"/></g>`;
}
const bg = (W, H) => `<rect width="${W}" height="${H}" fill="url(#bg)"/><circle cx="${W * 0.5}" cy="${H * 0.5}" r="${H * 0.75}" fill="url(#glow)"/>`;
const safeArea = (W, H) => `<rect x="${W * 0.2}" y="0" width="${W * 0.6}" height="${H}" fill="none" stroke="#FFD166" stroke-width="6" stroke-dasharray="30 24" opacity=".7"/>`;

// ---- Header (3840x1646) keyframes ----
const HW = 3840, HH = 1646;
const sub = (x, y, str, size) => text(x, y, str, size, { weight: 500, opacity: 0.85 });
const header = [
  ['① 0.0 秒 読み取り', () => qr(HW / 2, HH / 2, 520) + reticle(HW / 2, HH / 2, 900, '#fff')],
  ['② 1.5 秒 読み取れた', () => qr(HW / 2, HH / 2, 520) + reticle(HW / 2, HH / 2, 680, '#7FF0D2', true)],
  ['③ 3.0 秒 かざすだけ', () => qr(HW * 0.36, HH * 0.42, 300, 0.9) + reticle(HW * 0.36, HH * 0.42, 400, '#7FF0D2') +
    text(HW * 0.36, HH * 0.74, 'かざすだけ。', 150) + phone(HW * 0.64, HH * 0.56, 1500, SHOTS.url)],
  ['④ 6.0 秒 余計なものはない', () => text(HW * 0.4, HH * 0.52, '余計なものは、', 140) + text(HW * 0.4, HH * 0.63, '入れていない。', 140) +
    sub(HW * 0.4, HH * 0.75, '広告も、アクセス解析も。', 76) + phone(HW * 0.67, HH * 0.56, 1500, SHOTS.history)],
  ['⑤ 9.0 秒 買い切り', () => text(HW * 0.4, HH * 0.52, '毎月の支払いは、', 140) + text(HW * 0.4, HH * 0.63, 'いらない。', 140) +
    sub(HW * 0.4, HH * 0.75, '必要なら、一度買うだけ。', 76) + phone(HW * 0.67, HH * 0.56, 1500, SHOTS.create)],
  ['⑥ 12.0 秒 端末の中だけ', () => lock(HW * 0.4, HH * 0.3, 220) + text(HW * 0.4, HH * 0.54, '読んだ中身は、', 140) +
    text(HW * 0.4, HH * 0.65, 'どこにも送らない。', 140) + sub(HW * 0.4, HH * 0.77, 'ぜんぶ、この iPhone の中で。', 76) + phone(HW * 0.67, HH * 0.56, 1500, SHOTS.history)],
  ['⑦ 13.8 秒 締め（→ ① にループ）', () => `<image href="${SHOTS.icon}" x="${HW / 2 - 200}" y="${HH * 0.16}" width="400" height="400" clip-path="inset(0 round 90px)"/>` +
    text(HW / 2, HH * 0.66, '誠実QRリーダー', 170) + sub(HW / 2, HH * 0.78, 'ちゃんと、読むだけ。', 96)],
];
// ---- Search results (3840x2560) keyframes ----
const SW = 3840, SH = 2560;
const search = [
  ['① 0.0〜3.0 秒 かざすだけ', () => qr(SW * 0.3, SH * 0.5, 520) + reticle(SW * 0.3, SH * 0.5, 700, '#7FF0D2', true) +
    text(SW * 0.3, SH * 0.78, 'かざすだけ。', 170) + phone(SW * 0.64, SH * 0.58, 2100, SHOTS.url)],
  ['② 6.0 秒 余計なものはない', () => text(SW / 2, SH * 0.12, '余計なものは、入れていない。', 150) + sub(SW / 2, SH * 0.19, '広告も、アクセス解析も。', 84) +
    phone(SW / 2, SH * 0.64, 1800, SHOTS.history)],
  ['③ 12.0 秒 端末の中だけ', () => text(SW / 2, SH * 0.12, '読んだ中身は、どこにも送らない。', 150) + sub(SW / 2, SH * 0.19, 'ぜんぶ、この iPhone の中で。', 84) +
    phone(SW / 2, SH * 0.64, 1800, SHOTS.history)],
];

function sheet(file, title, W, H, frames, cols, scale) {
  const fw = W * scale, fh = H * scale, gap = 80, top = 200;
  const rows = Math.ceil(frames.length / cols);
  const SWd = cols * fw + (cols - 1) * gap + 160, SHd = top + rows * (fh + 120) + 60;
  let body = '';
  frames.forEach(([label, draw], i) => {
    const x = 80 + (i % cols) * (fw + gap), y = top + Math.floor(i / cols) * (fh + 120);
    body += `<text x="${x}" y="${y - 24}" font-size="34" font-weight="700" fill="#3A3A3C">${esc(label)}</text>` +
      `<svg x="${x}" y="${y}" width="${fw}" height="${fh}" viewBox="0 0 ${W} ${H}"><clipPath id="c${i}"><rect width="${W}" height="${H}" rx="40"/></clipPath><g clip-path="url(#c${i})">${bg(W, H)}${draw()}${safeArea(W, H)}</g></svg>`;
  });
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${SWd}" height="${SHd}" viewBox="0 0 ${SWd} ${SHd}" font-family="${FONT}">
  <defs><linearGradient id="bg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#0F7F68"/><stop offset="1" stop-color="#0A5F4E"/></linearGradient>
  <radialGradient id="glow"><stop offset="0" stop-color="#3CC7A6" stop-opacity=".35"/><stop offset="1" stop-color="#3CC7A6" stop-opacity="0"/></radialGradient></defs>
  <rect width="${SWd}" height="${SHd}" fill="#F2F2F4"/>
  <text x="80" y="90" font-size="56" font-weight="800" fill="#1C1C1E">${esc(title)}</text>
  <text x="80" y="140" font-size="30" fill="#636366">黄色の点線は文字と iPhone を収める中央 60% の範囲（動画には入らない）。15 秒でループ、音なし。</text>
  ${body}</svg>`;
  fs.writeFileSync(path.join(OUT, file), svg);
}
sheet('storyboard-header.svg', 'App Store ヘッダ動画（21:9・3840×1646）絵コンテ', HW, HH, header, 2, 0.25);
sheet('storyboard-search.svg', 'App Store 検索結果動画（3:2・3840×2560）絵コンテ', SW, SH, search, 3, 0.18);
console.log('wrote storyboard-header.svg, storyboard-search.svg');
