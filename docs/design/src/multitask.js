// iPad orientation and multitasking mockups: portrait full screen, iPadOS 26+ windowed apps,
// and iPadOS 17-18 Split View. Layout follows size classes only (HIG Layout / Multitasking).
const fs = require('fs');
const path = require('path');
const L = require('./lib');
const D = require('./devices');
const { C, t, measure, iconLabel, rect, icon, tile, doc, glass, glassCircle } = L;
const { camFeed, reticle, pill, urlDetail, rowsGroup, chips, CHIP_ITEMS, searchField, freeBanner, ROWS_TODAY, ROWS_YDAY, caps, uid } = D;

const OUT = process.argv[2];
const LW = 1180, LH = 820;   // landscape
const PW = 820, PH = 1180;   // portrait

function status(W, darkLeft, darkRight = darkLeft) {
  const cr = darkRight ? '#fff' : C.label;
  return t(24, 22, '9:41  10月24日(土)', { size: 13, weight: 600, fill: darkLeft ? '#fff' : C.label }) +
    icon('wifi', W - 76, 9, 17, cr) + rect(W - 52, 10, 25, 12, { rx: 3.5, stroke: cr, sw: 1 }) + rect(W - 50, 12, 19, 8, { rx: 2, fill: cr });
}
// Regular width: tab bar floats at the top centre.
function topTabs(cx, active) {
  const labels = ['スキャン', '履歴', '作成', '設定'];
  const o = { size: 15, weight: 600 };
  const ws = labels.map(l => measure(l, o) + 36);
  const total = ws.reduce((a, b) => a + b, 0) + 8;
  let x = cx - total / 2;
  let s = glass(x, 34, total, 44, false);
  x += 4;
  labels.forEach((l, i) => {
    if (i === active) s += rect(x, 38, ws[i], 36, { rx: 18, fill: C.tabSel });
    s += t(x + ws[i] / 2, 61, l, { ...o, anchor: 'middle', fill: i === active ? C.accent : C.label });
    x += ws[i];
  });
  return s;
}
// Compact width (iPadOS 26+ / iOS 26+): floating Liquid Glass tab bar at the bottom.
function bottomTabs(x, y, w, active) {
  const items = [['スキャン', 'viewfinder'], ['履歴', 'clock'], ['作成', 'plusSquare'], ['設定', 'gear']];
  let s = glass(x, y, w, 62, false);
  const iw = (w - 8) / items.length;
  items.forEach(([l, ic], i) => {
    const ix = x + 4 + i * iw;
    if (i === active) s += rect(ix, y + 4, iw, 54, { rx: 27, fill: C.tabSel });
    const col = i === active ? C.accent : C.label;
    s += icon(ic, ix + iw / 2 - 12, y + 10, 24, col) + t(ix + iw / 2, y + 50, l, { size: 10, weight: 600, fill: col, anchor: 'middle' });
  });
  return s;
}
// Compact width on iPadOS 17-18: classic opaque tab bar.
function classicTabs(x, y, w, active) {
  const items = [['スキャン', 'viewfinder'], ['履歴', 'clock'], ['作成', 'plusSquare'], ['設定', 'gear']];
  let s = rect(x, y, w, 56, { fill: 'rgba(249,249,249,0.97)' }) + `<line x1="${x}" y1="${y}" x2="${x + w}" y2="${y}" stroke="#C6C6C8" stroke-width=".5"/>`;
  const iw = w / items.length;
  items.forEach(([l, ic], i) => {
    const col = i === active ? C.accent : '#8E8E93';
    s += icon(ic, x + i * iw + iw / 2 - 12, y + 7, 24, col) + t(x + i * iw + iw / 2, y + 46, l, { size: 10, weight: 500, fill: col, anchor: 'middle' });
  });
  return s;
}
function screenFrame(ox, oy, W, H, inner, caption, sub) {
  const id = uid('mf');
  return `<g transform="translate(${ox} ${oy})">
    <rect x="-22" y="-22" width="${W + 44}" height="${H + 44}" rx="40" fill="#1C1C1E"/>
    <clipPath id="${id}"><rect x="0" y="0" width="${W}" height="${H}" rx="20"/></clipPath><g clip-path="url(#${id})">${inner}</g>
  </g>` + caps(ox + W / 2, oy + H + 52, caption, sub);
}
function wallpaper(W, H) {
  const id = uid('wp');
  return `<defs><linearGradient id="${id}" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#3D6FB6"/><stop offset=".55" stop-color="#7FB4D9"/><stop offset="1" stop-color="#8FD3C7"/></linearGradient></defs>` + rect(0, 0, W, H, { fill: `url(#${id})` });
}
function dock(W, H) {
  const n = 7, s = 56, g = 18, w = n * s + (n - 1) * g + 36;
  let out = glass(W / 2 - w / 2, H - 92, w, 80, false, 28);
  const cols = ['#34C759', '#0A84FF', '#FF9500', '#FF2D55', '#5856D6', '#8E8E93', C.accent];
  cols.forEach((c, i) => { out += rect(W / 2 - w / 2 + 18 + i * (s + g), H - 80, s, s, { rx: 14, fill: c }); });
  return out;
}
// iPadOS 26+ window: rounded frame with window controls at the leading edge of the toolbar.
function appWindow(x, y, w, h, inner, active) {
  const id = uid('aw');
  const ctl = (active ? ['#FF5F57', '#FEBC2E', '#28C840'] : ['#C7C7CC', '#C7C7CC', '#C7C7CC'])
    .map((c, i) => `<circle cx="${x + 24 + i * 18}" cy="${y + 24}" r="6" fill="${c}"/>`).join('');
  return `<g filter="url(#${active ? 'shadowLg' : 'shadow'})">${rect(x, y, w, h, { rx: 26, fill: C.bg })}</g>` +
    `<clipPath id="${id}"><rect x="${x}" y="${y}" width="${w}" height="${h}" rx="26"/></clipPath><g clip-path="url(#${id})"><g transform="translate(${x} ${y})">${inner}</g></g>` + ctl;
}
function otherApp(w, h, label) {
  let s = rect(0, 0, w, h, { fill: '#FFFFFF' }) + rect(0, 0, w, 64, { fill: '#F2F2F7' });
  s += t(w / 2, h / 2 - 8, label, { size: 17, weight: 700, fill: C.tertiary, anchor: 'middle' });
  s += t(w / 2, h / 2 + 16, '（他のアプリ）', { size: 13, fill: C.tertiary, anchor: 'middle' });
  for (let i = 0; i < 4; i++) s += rect(24, 96 + i * 56, w - 48, 40, { rx: 10, fill: '#F2F2F7' });
  return s;
}
// Compact scan state when the camera is interrupted by multitasking (no camera access with other foreground apps).
function cameraUnavailable(w, h, tabs) {
  const cx = w / 2;
  let s = rect(0, 0, w, h, { fill: C.bg });
  s += `<circle cx="${cx}" cy="${h * 0.3}" r="52" fill="${C.accentSoft}"/>` + icon('cameraSlash', cx - 28, h * 0.3 - 28, 56, C.accent);
  const ty = h * 0.3 + 96;
  s += t(cx, ty, '他のアプリと同時に表示中は', { size: 20, weight: 800, anchor: 'middle' }) +
    t(cx, ty + 28, 'カメラを使えません', { size: 20, weight: 800, anchor: 'middle' });
  const lines = ['全画面表示に戻すと、スキャンを再開します。', '画像からの読み取りはこのまま使えます。'];
  lines.forEach((l, i) => { s += t(cx, ty + 64 + i * 22, l, { size: 15, fill: C.secondary, anchor: 'middle' }); });
  const bw = Math.min(w - 64, 320);
  s += rect(cx - bw / 2, ty + 112, bw, 52, { rx: 14, fill: C.accentFill }) + iconLabel(cx, ty + 144, 'photo', 22, '写真から読み取る', { size: 17, weight: 700, fill: '#fff' });
  return s + tabs;
}
// Compact history (same layout as iPhone).
function compactHistory(w, h, topPad, tabs, opts = {}) {
  const x = 16, cw = w - 32;
  let s = rect(0, 0, w, h, { fill: C.bg });
  const ty = topPad;
  if (!opts.classic) s += glass(w - 16 - 96, ty, 96, 44, false);
  s += icon('share', w - 16 - 84, ty + 11, 22, opts.classic ? C.accent : C.label) + icon('selectCircle', w - 16 - 38, ty + 11, 22, opts.classic ? C.accent : C.label);
  s += t(x, ty + 92, '履歴', { size: 34, weight: 800 });
  s += searchField(x, ty + 108, cw) + chips(x, ty + 158, CHIP_ITEMS, w - 4) + freeBanner(x, ty + 202, cw);
  s += rowsGroup(x, ty + 292, cw, ROWS_TODAY, -1, '今日');
  if (!opts.short) s += rowsGroup(x, ty + 512, cw, ROWS_YDAY, -1, '昨日');
  return s + tabs;
}

// A. Portrait, full screen, scan: taller than wide -> camera above, result below.
function portraitScan() {
  const camH = 560;
  const id = uid('pc');
  let s = rect(0, 0, PW, PH, { fill: C.bg }) +
    `<clipPath id="${id}"><rect x="0" y="0" width="${PW}" height="${camH}"/></clipPath><g clip-path="url(#${id})">` +
    camFeed(PW, camH, PW / 2, 300, 150) + reticle(PW / 2, 300, 260, '#fff', true, PW, camH) +
    pill(PW / 2, 520, 'shield', '読み取り内容は端末内だけで処理します', { size: 13, weight: 500, fill: '#fff', iconColor: C.accentOnDark }, 'rgba(0,0,0,0.45)', 34) + '</g>';
  s += glassCircle(46, 124, 22, 'repeat', true) + glass(PW - 124, 102, 100, 44, true) + icon('photo', PW - 109, 113, 22, '#fff') + icon('bolt', PW - 61, 113, 22, '#fff');
  s += t(24, 612, '読み取り結果', { size: 28, weight: 800 });
  s += urlDetail(24, 632, PW - 48, { actions: true });
  return s + status(PW, true) + topTabs(PW / 2, 0);
}
// B. Portrait, full screen, history: split view keeps both columns (balanced).
function portraitHistory() {
  const listW = 330;
  let s = rect(0, 0, PW, PH, { fill: C.bg }) + rect(0, 0, listW, PH, { fill: C.listColumn }) + `<line x1="${listW}" y1="0" x2="${listW}" y2="${PH}" stroke="${C.separator}"/>`;
  const lx = 16, lw = listW - 32;
  s += glass(lx, 96, 44, 44, false) + icon('sidebar', lx + 11, 107, 22, C.label);
  s += glass(lx + lw - 96, 96, 96, 44, false) + icon('share', lx + lw - 84, 107, 22, C.label) + icon('selectCircle', lx + lw - 38, 107, 22, C.label);
  s += t(lx, 178, '履歴', { size: 34, weight: 800 }) + searchField(lx, 194, lw) + chips(lx, 244, CHIP_ITEMS, listW - 4) + freeBanner(lx, 288, lw);
  s += rowsGroup(lx, 378, lw, ROWS_TODAY, 0, '今日') + rowsGroup(lx, 598, lw, ROWS_YDAY, -1, '昨日');
  s += glass(PW - 24 - 196, 96, 196, 44, false);
  ['copy', 'share', 'star', 'trash'].forEach((n, i) => { s += icon(n, PW - 24 - 196 + 15 + i * 46, 107, 22, n === 'trash' ? C.red : C.label); });
  s += urlDetail(listW + 28, 170, PW - listW - 56);
  return s + status(PW, false) + topTabs(listW + (PW - listW) / 2, 1);
}
// C. iPadOS 26+ windowed apps, tiled side by side: our window is compact width.
function tiledWindows() {
  const gap = 10, wy = 36, wh = LH - wy - 10, ww = (LW - gap * 3) / 2;
  let s = wallpaper(LW, LH) + status(LW, true);
  const inner = cameraUnavailable(ww, wh, bottomTabs(24, wh - 62 - 18, ww - 48, 0));
  s += appWindow(gap, wy, ww, wh, inner, true);
  s += appWindow(gap * 2 + ww, wy, ww, wh, otherApp(ww, wh, '別のアプリ'), false);
  return s;
}
// D. iPadOS 26+ windowed apps, freely resized small window in front.
function smallWindow() {
  let s = wallpaper(LW, LH) + status(LW, true);
  s += appWindow(60, 60, 640, 560, otherApp(640, 560, '別のアプリ'), false);
  const ww = 440, wh = 650, wx = 620, wy = 70;
  const inner = compactHistory(ww, wh, 12, bottomTabs(20, wh - 62 - 16, ww - 40, 1), { short: true });
  s += appWindow(wx, wy, ww, wh, inner, true);
  return s + dock(LW, LH);
}
// E. iPadOS 17-18 Split View (our app at 1/3 = compact). Classic bars on these OS versions.
function legacySplit() {
  const rightW = 375, div = 10, leftW = LW - rightW - div;
  let s = rect(0, 0, LW, LH, { fill: '#000' });
  s += `<g>${otherApp(leftW, LH, '別のアプリ（2/3）')}</g>`;
  s += rect(leftW, 0, div, LH, { fill: '#000' }) + rect(leftW + 3, LH / 2 - 20, 4, 40, { rx: 2, fill: '#8E8E93' });
  const inner = compactHistory(rightW, LH, 30, classicTabs(0, LH - 56, rightW, 1), { classic: true });
  s += `<g transform="translate(${leftW + div} 0)">${inner}${t(rightW / 2, 14, '•••', { size: 12, weight: 800, fill: '#8E8E93', anchor: 'middle' })}</g>`;
  s += t(leftW / 2, 14, '•••', { size: 12, weight: 800, fill: '#8E8E93', anchor: 'middle' });
  return s + status(LW, false);
}

function header(title, lines) {
  return t(70, 56, title, { size: 30, weight: 800 }) + lines.map((l, i) => t(70, 88 + i * 22, l, { size: 15, fill: C.secondary })).join('');
}
const W = 70 * 2 + LW * 2 + 120;
let body = header('09 iPad：回転・マルチタスク', [
  'iPad は全方向の回転と、マルチタスク（iPadOS 26 以降：ウィンドウ表示／iPadOS 17〜18：Split View・Slide Over・ステージマネージャ）に対応。iPhone は縦向き固定。',
  'レイアウトはサイズクラスだけで切り替える：regular 幅＝2カラム、compact 幅（狭いウィンドウ・1/3 分割など）＝ iPhone と同じ 1 カラム＋下部タブバー。',
  '他のアプリと同時表示中は iPadOS がカメラを停止する（Apple 公式ドキュメント）。その間は「写真から読み取る」を案内し、全画面に戻ると自動で再開。',
]);
const gx = 70 + 22;
let y = 214;
body += t(70, y - 40, '縦向き・全画面（820×1180pt）', { size: 20, weight: 800, fill: C.accentDark });
body += screenFrame(gx, y, PW, PH, portraitScan(), 'A. スキャン（縦）', '縦長なのでカメラを上、結果を下に配置（横向きでは左右）');
body += screenFrame(gx + PW + 120, y, PW, PH, portraitHistory(), 'B. 履歴（縦）', '縦でも regular 幅のため一覧｜詳細の 2 カラムを維持');
const rx = gx + 2 * (PW + 120);
body += `<g>${rect(rx, y, LW * 2 + 120 + 44 - 2 * (PW + 120) - 44, 300, { rx: 18, fill: '#FFFFFF', stroke: C.separator })}` +
  t(rx + 24, y + 40, 'レイアウト切替の基準', { size: 18, weight: 800 }) +
  ['横幅 regular → 2 カラム（一覧｜詳細、カメラ｜結果）', '横幅 compact → 1 カラム＋下部タブバー', '縦長（高さ＞幅）→ カメラ｜結果を上下に', '端末の種類・向きでは分岐しない', '最小幅 320pt まで崩れないこと'].map((l, i) =>
    icon('check', rx + 24, y + 66 + i * 40, 20, C.accent) + t(rx + 54, y + 82 + i * 40, l, { size: 15 })).join('') + '</g>';
y += PH + 150;
body += t(70, y - 40, 'iPadOS 26 以降：ウィンドウ表示', { size: 20, weight: 800, fill: C.accentDark });
body += screenFrame(gx, y, LW, LH, tiledWindows(), 'C. 左右に並べたウィンドウ（スキャン）', 'compact 幅＝1 カラム。カメラ停止中の案内と「写真から読み取る」');
body += screenFrame(gx + LW + 120 - 44, y, LW, LH, smallWindow(), 'D. 小さいウィンドウ（履歴）', 'ウィンドウコントロール（左上）と重ならないよう操作は右上に配置');
y += LH + 150;
body += t(70, y - 40, 'iPadOS 17〜18：Split View（最低対応 OS が iOS 17 のため）', { size: 20, weight: 800, fill: C.accentDark });
body += screenFrame(gx, y, LW, LH, legacySplit(), 'E. Split View 1/3（履歴）', '幅 375pt 程度の compact 幅。従来型の下部タブバー');
const H = y + LH + 120;
fs.writeFileSync(path.join(OUT, '09_ipad_multitasking.svg'), doc(W, H, body, '09 iPad：回転・マルチタスク'));
console.log('ok');
