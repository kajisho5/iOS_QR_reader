// App Store screenshots with headlines (docs/design/appstore/SCREENSHOTS.md):
//   node docs/design/appstore/src/screenshots.js
// Writes screenshots-iphone.svg (6 frames, 1320x2868 each = 440x956 pt) and screenshots-ipad.svg
// (3 frames, 2064x2752 each = 1032x1376 pt). The screens are the 1.1.0 App Store captures in ../shots
// (downscaled); the product-code screen is not captured yet, so it is drawn from the 1.1 mockup (19_product_search).
// Text is converted to outlines with the shared helpers in docs/design/src/lib.js.
const fs = require('fs');
const path = require('path');
const L = require('../../src/lib');
const S = require('../../src/screens');
const { C, t, rect, icon, tile, iconLabel } = L;

const OUT = path.join(__dirname, '..');
const SHOTS = path.join(__dirname, '../shots');
const jpg = (f) => 'data:image/jpeg;base64,' + fs.readFileSync(path.join(SHOTS, f)).toString('base64');

// Same gradient as the app icon and the App Store video (VIDEO.md), so the preview and the screenshots read as one set.
const BG_TOP = '#16A386', BG_BOTTOM = '#0A5F4E', MINT = '#7FF0D2';
let uid = 0;
const id = (p) => `${p}${++uid}`;

// ---------- Product-code result (1.1), drawn on the 393x852 mockup grid ----------
const line = (x1, y1, x2, y2) => `<line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="${C.separator}"/>`;
function actionQuad(y, items) {
  const w = (361 - 24) / 4;
  return items.map(([ic, label, col], i) => {
    const x = 16 + i * (w + 8);
    return rect(x, y, w, 66, { rx: 14, fill: C.card }) + icon(ic, x + w / 2 - 12, y + 11, 24, col || C.accent, ic === 'star') +
      t(x + w / 2, y + 54, label, { size: S.fitSize(label, 12, w - 10, 600), weight: 600, fill: col ? C.label : C.accent, anchor: 'middle' });
  }).join('');
}
function productScreen() {
  const H = 96;
  return rect(0, 0, 393, 852, { fill: C.bg }) +
    t(196.5, 78, '商品コード', { size: 17, weight: 600, anchor: 'middle' }) +
    tile(16, H + 10, 48, C.kind.text, 'barcode', 12) + t(76, H + 31, '商品コード', { size: 22, weight: 800 }) +
    t(76, H + 52, 'EAN-13 ・ 2026/11/11 23:46', { size: 13, fill: C.secondary }) +
    rect(16, H + 74, 361, 112, { rx: 14, fill: C.card }) +
    t(32, H + 100, '商品コード（JAN）', { size: 13, weight: 600, fill: C.secondary }) +
    t(32, H + 132, '4901234567894', { size: 22, weight: 700, mono: true }) +
    line(32, H + 150, 361, H + 150) +
    t(32, H + 174, '種類', { size: 15, fill: C.secondary }) + t(361, H + 174, 'JAN（EAN-13）', { size: 15, weight: 600, anchor: 'end' }) +
    icon('info', 18, H + 206, 16, C.secondary) +
    t(40, H + 219, '「ウェブで検索」を押すと、この番号が検索サイト', { size: 13, fill: C.secondary }) +
    t(40, H + 239, '（Google）に送られ、Safari で結果を開きます。', { size: 13, fill: C.secondary }) +
    t(40, H + 259, '押すまで、どこにも送りません。', { size: 13, fill: C.secondary }) +
    S.pinnedBar(676, 176) +
    rect(16, 688, 361, 54, { rx: 14, fill: C.accentFill }) + iconLabel(196.5, 722, 'search', 22, 'ウェブで検索', { size: 17, weight: 700, fill: '#fff' }) +
    actionQuad(752, [['qr', 'コードを表示'], ['copy', 'コピー'], ['share', '共有'], ['star', 'お気に入り', C.yellow]]);
}

// ---------- One store frame ----------
// d: device geometry in frame points. screen: { jpg } or { svg } (393x852 grid).
function frame(ox, oy, f, d) {
  const sx = (d.W - d.w) / 2, sy = d.top, sh = d.w * d.ratio;
  const clip = id('clip'), grad = id('bg'), shadow = id('sh');
  const screen = f.jpg
    ? `<image href="${jpg(f.jpg)}" x="${sx}" y="${sy}" width="${d.w}" height="${sh}" preserveAspectRatio="none"/>`
    : `<g transform="translate(${sx} ${sy}) scale(${d.w / 393} ${sh / 852})">${f.svg}</g>`;
  const lines = f.head.split('\n');
  const heads = lines.map((s, i) => t(d.W / 2, d.headY + i * d.headLead, s, { size: d.headSize, weight: 800, fill: '#fff', anchor: 'middle' })).join('');
  const subY = d.headY + (lines.length - 1) * d.headLead + d.subGap;
  const subs = f.sub.split('\n').map((s, i) => t(d.W / 2, subY + i * d.subLead, s, { size: d.subSize, weight: 500, fill: '#fff', anchor: 'middle', opacity: 0.88 })).join('');
  const b = d.bezel;
  return `<g transform="translate(${ox} ${oy})">
  <defs>
    <linearGradient id="${grad}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${BG_TOP}"/><stop offset="1" stop-color="${BG_BOTTOM}"/></linearGradient>
    <clipPath id="${clip}"><rect x="${sx}" y="${sy}" width="${d.w}" height="${sh}" rx="${d.r}"/></clipPath>
    <filter id="${shadow}" x="-20%" y="-10%" width="140%" height="130%"><feDropShadow dx="0" dy="${d.W * 0.02}" stdDeviation="${d.W * 0.03}" flood-color="#002A20" flood-opacity=".45"/></filter>
  </defs>
  <rect width="${d.W}" height="${d.H}" fill="url(#${grad})"/>
  ${heads}${subs}
  <rect x="${sx - b}" y="${sy - b}" width="${d.w + 2 * b}" height="${sh + 2 * b}" rx="${d.r + b}" fill="#101312" filter="url(#${shadow})"/>
  <rect x="${sx - b + 1.5}" y="${sy - b + 1.5}" width="${d.w + 2 * b - 3}" height="${sh + 2 * b - 3}" rx="${d.r + b - 1.5}" fill="none" stroke="#3A3F3D" stroke-width="1.5"/>
  <g clip-path="url(#${clip})">${screen}</g>
  ${d.island ? `<rect x="${d.W / 2 - d.island[0] / 2}" y="${sy + d.island[2]}" width="${d.island[0]}" height="${d.island[1]}" rx="${d.island[1] / 2}" fill="#000"/>` : ''}
  </g>`;
}

// iPhone 6.9" (1320x2868 px at 3x). The whole screen stays visible: the result screens' buttons are at the bottom.
const IPHONE = { W: 440, H: 956, w: 318, ratio: 2868 / 1320, top: 240, r: 45, bezel: 8, island: [91, 27, 8],
  headY: 92, headLead: 44, headSize: 34, subGap: 44, subSize: 15.5, subLead: 22 };
// iPad 13" (2064x2752 px at 2x).
const IPAD = { W: 1032, H: 1376, w: 836, ratio: 2752 / 2064, top: 214, r: 15, bezel: 14, island: null,
  headY: 112, headLead: 64, headSize: 52, subGap: 56, subSize: 24, subLead: 32 };

const IPHONE_FRAMES = [
  { jpg: 'iphone-02-result-url.jpg', head: '開く前に、\nURL を全部見せる', sub: '省略せずに全文を表示。まぎらわしい URL には\n開く前に注意を出します' },
  { jpg: 'iphone-01-history.jpg', head: '読んだ中身を、\nどこにも送らない', sub: 'アプリは通信しません。登録も不要。\n履歴は Face ID などでロックできます' },
  { jpg: 'iphone-05-purchase.jpg', head: '広告なし。\n買い切りで、ずっと使える', sub: '毎月の支払いはありません。\n読み取りは無料で、回数も無制限' },
  { svg: productScreen(), head: 'バーコードの商品を、\nそのまま検索', sub: 'JAN・ISBN は、ボタンひとつで Web 検索。\n押すまで、どこにも送りません' },
  { jpg: 'iphone-03-result-wifi.jpg', head: 'Wi-Fi の QR から、\nそのまま接続', sub: 'パスワードは伏せたまま確認できます' },
  { jpg: 'iphone-04-create.jpg', head: 'QR コードも、\n自分で作れる', sub: 'テキストと URL は無料。\nWi-Fi・連絡先・イベントは Pro' },
];
const IPAD_FRAMES = [
  { jpg: 'ipad-01-history.jpg', head: '開く前に、URL を全部見せる', sub: '省略せずに全文を表示。まぎらわしい URL には開く前に注意を出します' },
  { jpg: 'ipad-03-purchase.jpg', head: '広告なし。買い切りで、ずっと使える', sub: '毎月の支払いはありません。読み取りは無料で、回数も無制限' },
  { jpg: 'ipad-02-create.jpg', head: 'QR コードも、自分で作れる', sub: 'テキストと URL は無料。Wi-Fi・連絡先・イベントは Pro' },
];

// Sheet: frames side by side at `scale`, with the order number and the file name under each.
function sheet(name, title, notes, frames, d, scale, gap) {
  const PAD = 60, TOP = 150, fw = d.W * scale, fh = d.H * scale;
  const W = PAD * 2 + frames.length * fw + (frames.length - 1) * gap, H = TOP + fh + 90;
  const body = frames.map((f, i) => {
    const x = PAD + i * (fw + gap);
    return `<g transform="translate(${x} ${TOP}) scale(${scale})">${frame(0, 0, f, d)}</g>` +
      t(x + fw / 2, TOP + fh + 44, `${i + 1}`, { size: 22, weight: 800, anchor: 'middle', fill: C.caption });
  }).join('\n');
  const head = t(PAD, 56, title, { size: 28, weight: 800 }) + notes.map((s, i) => t(PAD, 90 + i * 24, s, { size: 15, fill: C.secondary })).join('');
  fs.writeFileSync(path.join(OUT, name), `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">
<title>${L.esc(title)}</title>
<rect width="${W}" height="${H}" fill="${C.canvas}"/>
${head}
${body}
</svg>
`);
}

sheet('screenshots-iphone.svg', 'App Store スクリーンショット（iPhone 6.9 インチ・1320×2868）',
  ['見出し＋実際の画面。背景はアイコン・動画と同じ緑のグラデーション。並びは伝えたい順（1 枚目が最重要）。',
    '4 枚目（商品コード）は未撮影のため 1.1 のモックアップで描画。実装時は他と同じく実機の画面を撮る。'],
  IPHONE_FRAMES, IPHONE, 0.75, 40);
sheet('screenshots-ipad.svg', 'App Store スクリーンショット（iPad 13 インチ・2064×2752）',
  ['iPhone と同じ見出し・同じ並び（iPad は 3 枚）。見出しは 1 行。'],
  IPAD_FRAMES, IPAD, 0.5, 40);
