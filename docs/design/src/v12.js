// Mockups for the additions after 1.1 (docs/DESIGN_1.2.md): L, M, N, O, H, I, J, K.
// Writes docs/design/21_create_more_kinds.svg … 28_apple_watch.svg.
const fs = require('fs');
const path = require('path');
const L = require('./lib');
const S = require('./screens');
const { C, t, measure, iconLabel, rect, icon, tile, statusBar, tabBar, phone, doc, fakeQR, glass, glassCircle } = L;

const OUT = process.argv[2];
const W1 = 393, GAP = 90, PAD = 70, OY = 120;
const canvasW = n => PAD * 2 + n * W1 + (n - 1) * GAP;
const px = i => PAD + i * (W1 + GAP);
const CANVAS_H = 852 + 70 + 70 + 40 + 70;
const line = (x1, y1, x2, y2, c = C.separator) => `<line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="${c}"/>`;
Object.assign(C.kind, { email: '#DB2777', phone: '#16A34A', sms: '#0891B2', geo: '#EA580C' });

function header(title, sub, sub2) {
  return t(PAD - 13, 48, title, { size: 26, weight: 800, fill: C.label }) +
    (sub ? t(PAD - 13, 76, sub, { size: 15, fill: C.secondary }) : '') +
    (sub2 ? t(PAD - 13, 98, sub2, { size: 15, fill: C.secondary }) : '');
}
function write(name, title, sub, sub2, screens) {
  const w = canvasW(screens.length);
  // A screen marked bare (the Watch) is drawn without the iPhone frame.
  const body = header(title, sub, sub2) + screens.map(([inner, cap, bare], i) => bare
    ? `<g transform="translate(${px(i)} ${OY})">${inner}</g>` + t(px(i) + 196.5, OY + 900, cap, { size: 18, weight: 700, anchor: 'middle', fill: C.caption })
    : phone(px(i), OY, inner, cap)).join('\n');
  fs.writeFileSync(path.join(OUT, name), doc(w, CANVAS_H, body, title));
}

// Icons not in lib.js, on the same 24x24 grid.
const EXTRA = {
  clipboard: c => `<g fill="none" stroke="${c}" stroke-width="2" stroke-linejoin="round"><rect x="5" y="4" width="14" height="17" rx="2.5"/><rect x="9" y="2.5" width="6" height="4" rx="1.2" fill="${c}"/><path d="M8.5 11h7M8.5 15h5" stroke-linecap="round"/></g>`,
  printer: c => `<g fill="none" stroke="${c}" stroke-width="2" stroke-linejoin="round"><path d="M7 9V3.5h10V9"/><rect x="3" y="9" width="18" height="8" rx="2"/><rect x="7" y="14" width="10" height="7" fill="#fff"/></g><circle cx="17.5" cy="12" r="1" fill="${c}"/>`,
  palette: c => `<path d="M12 3a9 9 0 1 0 0 18c1.3 0 2-.8 2-1.8 0-1.2-1-1.6-1-2.6 0-1 .8-1.6 1.8-1.6H17a4 4 0 0 0 4-4C21 6.6 17 3 12 3z" fill="none" stroke="${c}" stroke-width="2" stroke-linejoin="round"/><g fill="${c}"><circle cx="7.5" cy="11" r="1.4"/><circle cx="10" cy="7" r="1.4"/><circle cx="14.5" cy="7" r="1.4"/></g>`,
  watch: c => `<g fill="none" stroke="${c}" stroke-width="2" stroke-linejoin="round"><rect x="6" y="6" width="12" height="12" rx="3.5"/><path d="M8.5 6l1-3.5h5l1 3.5M8.5 18l1 3.5h5l1-3.5"/></g>`,
  plus: c => `<path d="M12 5v14M5 12h14" stroke="${c}" stroke-width="2.4" stroke-linecap="round"/>`,
  minus: c => `<path d="M5 12h14" stroke="${c}" stroke-width="2.4" stroke-linecap="round"/>`,
  pencil: c => `<g fill="none" stroke="${c}" stroke-width="2" stroke-linejoin="round"><path d="M4 20l1-4.5L16 4.5l3.5 3.5L8.5 19z"/><path d="M14 7l3 3"/></g>`,
  location: c => `<path d="M20.5 3.5 3.5 10.6l7 2.4 2.4 7z" fill="none" stroke="${c}" stroke-width="2" stroke-linejoin="round"/>`,
  tally: c => `<g stroke="${c}" stroke-width="2.2" stroke-linecap="round"><path d="M5 5v14M9 5v14M13 5v14M17 5v14M3 15 19 9"/></g>`,
  shortcuts: c => `<g fill="none" stroke="${c}" stroke-width="2" stroke-linejoin="round"><path d="M8 3h8l5 5v8l-5 5H8l-5-5V8z"/></g>`,
};
Object.assign(L.ICON, EXTRA);  // so lib helpers (iconLabel, pillNote) can draw them too
function ic(name, x, y, size, color, extra) {
  if (!EXTRA[name]) return icon(name, x, y, size, color, extra);
  return `<g transform="translate(${x} ${y}) scale(${size / 24})">${EXTRA[name](color)}</g>`;
}
// iconLabel for the extra icons: icon + gap + label, centered on cx.
function icLabel(cx, baseline, name, isz, label, o = {}) {
  const gap = o.gap ?? 8, tw = measure(label, o), x0 = cx - (isz + gap + tw) / 2;
  return ic(name, x0, baseline - isz * 0.8, isz, o.iconColor || o.fill || C.label) + t(x0 + isz + gap, baseline, label, o);
}
function newBadge(x, y) {
  return rect(x, y, 40, 20, { rx: 10, fill: C.accentFill }) + t(x + 20, y + 14, 'NEW', { size: 11, weight: 800, fill: '#fff', anchor: 'middle' });
}
function proBadge(x, y) {
  return rect(x, y, 52, 22, { rx: 11, fill: C.accentSoft }) + iconLabel(x + 26, y + 16, 'lock', 12, 'Pro', { size: 12, weight: 800, fill: C.accent, gap: 3 });
}
function navBack(title, backLabel) {
  return rect(0, 0, 393, 852, { fill: C.bg }) + statusBar(false) +
    glassCircle(38, 82, 22, 'chevronLeft', false) + t(196.5, 88, title, { size: 17, weight: 700, anchor: 'middle' });
}
function field(y, label, value, o = {}) {
  const h = o.h || 48;
  return t(32, y - 8, label, { size: 13, weight: 600, fill: C.secondary }) +
    rect(16, y, 361, h, { rx: 12, fill: C.card }) +
    (Array.isArray(value) ? value.map((v, i) => t(32, y + 30 + i * 22, v, { size: 16, mono: o.mono, fill: o.placeholder ? C.placeholder : C.label })).join('')
      : t(32, y + 30, value, { size: 16, mono: o.mono, fill: o.placeholder ? C.placeholder : C.label })) +
    (o.right || '');
}
function primary(y, ic0, label, o = {}) {
  return rect(16, y, 361, 54, { rx: 14, fill: o.disabled ? C.fill : C.accentFill }) +
    iconLabel(196.5, y + 34, ic0, 22, label, { size: 17, weight: 700, fill: o.disabled ? C.tertiary : '#fff' });
}
function secondary(y, ic0, label) {
  return rect(16, y, 361, 54, { rx: 14, fill: C.card, stroke: C.separator }) + iconLabel(196.5, y + 34, ic0, 22, label, { size: 17, weight: 700, fill: C.accent });
}
function noteBox(y, lines, o = {}) {
  const h = 22 + lines.length * 20;
  return rect(16, y, 361, h, { rx: 12, fill: o.fill || C.neutralFill }) + icon(o.icon || 'info', 30, y + 12, 18, o.iconColor || C.secondary) +
    lines.map((s, i) => t(56, y + 26 + i * 20, s, { size: 13, fill: o.text || C.secondary })).join('');
}
function actionQuad(y, items) {
  const w = (361 - 24) / 4;
  return items.map(([ic0, label, col, isNew]) => [ic0, label, col, isNew]).map(([ic0, label, col, isNew], i) => {
    const x = 16 + i * (w + 8);
    return rect(x, y, w, 66, { rx: 14, fill: C.card, stroke: isNew ? C.accent : null, sw: 1.5 }) +
      ic(ic0, x + w / 2 - 12, y + 11, 24, col || C.accent, ic0 === 'star') +
      t(x + w / 2, y + 54, label, { size: S.fitSize(label, 12, w - 10, 600), weight: 600, fill: col ? C.label : C.accent, anchor: 'middle' });
  }).join('');
}
function pinnedQuad(ic0, label, tiles) {
  const Y = 676;
  return S.pinnedBar(Y, 852 - Y) + rect(16, Y + 12, 361, 54, { rx: 14, fill: C.accentFill }) +
    iconLabel(196.5, Y + 46, ic0, 22, label, { size: 17, weight: 700, fill: '#fff' }) + actionQuad(Y + 76, tiles);
}
function resultHead(y, kind, ic0, title, meta) {
  return tile(16, y, 48, C.kind[kind], ic0, 12) + t(76, y + 21, title, { size: 22, weight: 800 }) + t(76, y + 42, meta, { size: 13, fill: C.secondary });
}

// ---------- 21 L：作れる種類を増やす ----------
function kindCard(x, y, w, kind, ic0, title, sub, locked, isNew) {
  return `<g filter="url(#shadow)">${rect(x, y, w, 90, { rx: 16, fill: C.card })}</g>` +
    tile(x + 14, y + 14, 36, locked ? C.lockedTile : C.kind[kind], ic0, 9) +
    (locked ? proBadge(x + w - 64, y + 14) : rect(x + w - 58, y + 14, 46, 22, { rx: 11, fill: C.neutralFill }) + t(x + w - 35, y + 30, '無料', { size: 12, weight: 700, fill: C.secondary, anchor: 'middle' })) +
    (isNew ? newBadge(x + w - 64, y + 42) : '') +
    t(x + 14, y + 68, title, { size: 16, weight: 800, fill: locked ? C.secondary : C.label }) +
    t(x + 14, y + 84, sub, { size: 11, fill: C.secondary });
}
function l1() {
  const w = 172.5, xs = [16, 204.5];
  const items = [
    ['text', 'text', 'テキスト', '自由な文字列', false], ['url', 'link', 'URL', 'Webページへのリンク', false],
    ['wifi', 'wifi', 'Wi-Fi', 'SSID・パスワード', true], ['contact', 'person', '連絡先', '名前・電話・メール', true],
    ['event', 'calendar', 'イベント', '予定の日時・場所', true], ['email', 'envelope', 'メール', '宛先・件名・本文', true, true],
    ['phone', 'phone', '電話', '電話番号', true, true], ['sms', 'message', 'SMS', '番号・本文', true, true],
    ['geo', 'pin', '地図の位置', '緯度・経度', true, true],
  ];
  let s = S.navLarge('作成') + t(16, 158, '作成したQRコードは履歴にも保存されます', { size: 14, fill: C.secondary });
  items.forEach(([k, i0, ti, su, lo, nw], n) => { s += kindCard(xs[n % 2], 172 + Math.floor(n / 2) * 100, w, k, i0, ti, su, lo, nw); });
  s += rect(204.5, 572, 172.5, 90, { rx: 16, fill: C.accentSoft }) + icon('lockOpen', 218, 586, 22, C.accent) +
    t(218, 628, 'メール・電話・SMS・', { size: 12, weight: 700, fill: C.accentDark }) + t(218, 646, '位置も Pro で作れます', { size: 12, weight: 700, fill: C.accentDark });
  return s + tabBar(2, false);
}
function l2() {
  return navBack('メール') +
    field(136, '宛先（必須）', 'info@example.co.jp', { mono: true }) +
    field(216, '件名', '資料のご請求') +
    field(296, '本文', ['パンフレットを1部お送りください。', '住所：'], { h: 92 }) +
    `<g filter="url(#shadow)">${rect(16, 408, 361, 250, { rx: 18, fill: C.card })}</g>` +
    rect(106.5, 420, 180, 180, { rx: 10, fill: '#fff', stroke: C.separator }) + fakeQR(116.5, 430, 160, 29, '#000', 21) +
    t(196.5, 624, 'mailto:info@example.co.jp?subject=…', { size: 12, mono: true, fill: C.secondary, anchor: 'middle' }) +
    t(196.5, 644, '読み取ると、メールアプリに宛先と件名が入ります', { size: 12, fill: C.secondary, anchor: 'middle' }) +
    rect(16, 672, 176, 54, { rx: 14, fill: C.accentFill }) + iconLabel(104, 706, 'download', 20, '写真に保存', { size: 16, weight: 700, fill: '#fff' }) +
    rect(201, 672, 176, 54, { rx: 14, fill: C.card, stroke: C.separator }) + iconLabel(289, 706, 'share', 20, '共有', { size: 16, weight: 700, fill: C.accent }) +
    tabBar(2, false);
}
function l3() {
  return navBack('地図の位置') +
    field(136, '緯度（-90〜90）', '35.68124', { mono: true }) +
    field(216, '経度（-180〜180）', '139.76712', { mono: true }) +
    field(296, '名前（任意）', '誠実商事 本社') +
    rect(16, 360, 361, 48, { rx: 12, fill: C.card, stroke: C.separator }) +
    icLabel(196.5, 390, 'location', 20, '現在地を入れる', { size: 16, weight: 700, fill: C.accent }) +
    noteBox(422, ['地図は表示しません（地図の画像を取りに行く', '通信が要るため）。現在地は、ボタンを押した', 'ときだけ使い、どこにも送りません。'], { icon: 'shield', iconColor: C.accent, fill: C.accentSoft, text: C.accentDark }) +
    `<g filter="url(#shadow)">${rect(16, 520, 361, 214, { rx: 18, fill: C.card })}</g>` +
    rect(121.5, 532, 150, 150, { rx: 10, fill: '#fff', stroke: C.separator }) + fakeQR(129.5, 540, 134, 25, '#000', 33) +
    t(196.5, 704, 'geo:35.68124,139.76712', { size: 12, mono: true, fill: C.secondary, anchor: 'middle' }) +
    t(196.5, 722, '読み取ると、地図アプリでこの場所を開けます', { size: 12, fill: C.secondary, anchor: 'middle' }) +
    tabBar(2, false);
}

// ---------- 22 M：貼り付け ----------
function reticle(x, y, s, color = '#fff') {
  const L2 = 38, r = 24;
  return `<g fill="none" stroke="${color}" stroke-width="5" stroke-linecap="round">
    <path d="M${x} ${y + L2}V${y + r}a${r} ${r} 0 0 1 ${r}-${r}H${x + L2}"/><path d="M${x + s - L2} ${y}H${x + s - r}a${r} ${r} 0 0 1 ${r} ${r}V${y + L2}"/>
    <path d="M${x + s} ${y + s - L2}V${y + s - r}a${r} ${r} 0 0 1 -${r} ${r}H${x + s - L2}"/><path d="M${x + L2} ${y + s}H${x + r}a${r} ${r} 0 0 1 -${r}-${r}V${y + s - L2}"/></g>`;
}
function dimOutside(x, y, s) {
  return `<path fill="rgba(0,0,0,0.5)" fill-rule="evenodd" d="M0 0H393V852H0Z M${x + 24} ${y}H${x + s - 24}a24 24 0 0 1 24 24V${y + s - 24}a24 24 0 0 1-24 24H${x + 24}a24 24 0 0 1-24-24V${y + 24}a24 24 0 0 1 24-24Z"/>`;
}
const CY = 678;
function ctl(cx, name, label, on, isNew) {
  const r = 28;
  const circle = on ? `<circle cx="${cx}" cy="${CY}" r="${r}" fill="#fff" filter="url(#glass)"/>` : glass(cx - r, CY - r, r * 2, r * 2, true);
  return circle + ic(name, cx - 14, CY - 14, 28, on ? '#1C1C1E' : '#fff', name === 'star') +
    (isNew ? `<circle cx="${cx}" cy="${CY}" r="${r + 3}" fill="none" stroke="${C.accentOnDark}" stroke-width="2"/>` : '') +
    t(cx, CY + 50, label, { size: 12, weight: 600, fill: '#fff', anchor: 'middle' });
}
function scanBase(extra = '') {
  const X = 66.5, Y = 200, Sz = 260;
  return S.cameraFeed() + dimOutside(X, Y, Sz) + reticle(X, Y, Sz) + statusBar(true) + S.privacyPill() +
    t(196.5, 504, 'コードを枠内に合わせてください', { size: 17, weight: 700, fill: '#fff', anchor: 'middle' }) +
    t(196.5, 530, 'QRコード・バーコード 11種類に対応', { size: 13, fill: 'rgba(255,255,255,0.75)', anchor: 'middle' }) + extra;
}
function controls4(pasteNew, continuousOn, continuousLabel) {
  const xs = [78.6, 157.2, 235.8, 314.4];
  return ctl(xs[0], 'photo', '写真から') + ctl(xs[1], 'clipboard', '貼り付け', false, pasteNew) +
    ctl(xs[2], continuousLabel ? 'tally' : 'repeat', continuousLabel || (continuousOn ? '連続 ON' : '連続スキャン'), continuousOn) + ctl(xs[3], 'bolt', 'ライト');
}
function m1() {
  return scanBase() + controls4(true, false) +
    S.pillNote(604, 'clipboard', 'コピーした画像・文字を、押したときだけ読みます', { size: 12, weight: 600, fill: '#fff', iconColor: C.accentOnDark }, 'rgba(0,0,0,0.55)', 32) +
    tabBar(0, true);
}
function m2() {
  const Y = 236, H = Y + 46;
  return S.sheetBackdrop() + S.sheetTop(Y) + S.sheetClose(Y + 30) +
    resultHead(H + 10, 'url', 'link', 'URL', '貼り付け · 2026/11/12 10:20') +
    rect(16, H + 74, 361, 150, { rx: 14, fill: C.card }) +
    t(32, H + 100, 'リンク先（全文・省略なし）', { size: 13, weight: 600, fill: C.secondary }) +
    t(32, H + 128, [{ s: 'https://' }, { s: 'www.example.co.jp', weight: 800 }, { s: '/campaign' }], { size: 15, mono: true }) +
    line(32, H + 146, 361, H + 146) + t(32, H + 176, 'ドメイン', { size: 15, fill: C.secondary }) + t(361, H + 176, 'www.example.co.jp', { size: 15, weight: 700, anchor: 'end' }) +
    t(32, H + 208, '読み取り元', { size: 15, fill: C.secondary }) + icLabel(318, H + 208, 'clipboard', 16, '貼り付け', { size: 15, weight: 700, gap: 4 }) +
    noteBox(H + 238, ['コピーした画像から読み取りました。', 'URL の注意表示は、カメラで読んだときと同じです。']) +
    pinnedQuad('external', 'ブラウザで開く', [['qr', 'QRを表示'], ['copy', 'コピー'], ['share', '共有'], ['star', 'お気に入り', C.yellow]]) +
    L.homeIndicator(false);
}
function m3() {
  const paste = rect(287, 104, 90, 28, { rx: 14, fill: C.accentSoft }) + ic('clipboard', 297, 109, 18, C.accent) + t(320, 123, '貼り付け', { size: 13, weight: 700, fill: C.accent }) + newBadge(237, 108);
  return navBack('URL') + paste +
    field(146, 'URL', 'https://www.example.co.jp/campaign', { mono: true }) +
    noteBox(212, ['「貼り付け」は、押したときだけクリップボードを', '読みます（iOS の許可の確認は出ません）。']) +
    `<g filter="url(#shadow)">${rect(16, 288, 361, 300, { rx: 18, fill: C.card })}</g>` +
    rect(86.5, 302, 220, 220, { rx: 12, fill: '#fff', stroke: C.separator }) + fakeQR(98.5, 314, 196, 29, '#000', 3) +
    t(196.5, 546, 'https://www.example.co.jp/campaign', { size: 12, mono: true, fill: C.secondary, anchor: 'middle' }) +
    iconLabel(196.5, 572, 'checkCircle', 16, '履歴に保存しました', { size: 13, fill: C.secondary, iconColor: C.green, gap: 6 }) +
    rect(16, 604, 176, 54, { rx: 14, fill: C.accentFill }) + iconLabel(104, 638, 'download', 20, '写真に保存', { size: 16, weight: 700, fill: '#fff' }) +
    rect(201, 604, 176, 54, { rx: 14, fill: C.card, stroke: C.separator }) + iconLabel(289, 638, 'share', 20, '共有', { size: 16, weight: 700, fill: C.accent }) +
    tabBar(2, false);
}

// ---------- 23 N：ショートカット ----------
function scBlock(y, tint, ic0, label, param, o = {}) {
  const h = o.h || 64;
  return `<g filter="url(#shadow)">${rect(16, y, 361, h, { rx: 14, fill: C.card })}</g>` +
    tile(30, y + 14, 36, tint, ic0, 9) + t(78, y + 30, label, { size: 15, weight: 700 }) +
    (param ? rect(78, y + 38, measure(param, { size: 13, weight: 600 }) + 16, 20, { rx: 6, fill: C.accentSoft }) + t(86, y + 53, param, { size: 13, weight: 600, fill: C.accent }) : '') +
    (o.isNew ? newBadge(325, y + 10) : '');
}
function arrowDown(y) { return `<path d="M196.5 ${y}v18m-6-6 6 6 6-6" fill="none" stroke="${C.tertiary}" stroke-width="2" stroke-linecap="round"/>`; }
function n1() {
  let s = rect(0, 0, 393, 852, { fill: C.bg }) + statusBar(false) + t(196.5, 88, 'アクションを追加', { size: 17, weight: 700, anchor: 'middle' }) +
    rect(16, 110, 361, 38, { rx: 10, fill: C.fill }) + icon('search', 26, 119, 20, C.secondary) + t(52, 135, '誠実', { size: 16 }) +
    tile(16, 168, 44, C.accentFill, 'qr', 11) + t(70, 186, '誠実QRリーダー', { size: 17, weight: 800 }) + t(70, 206, 'アクション 3 件', { size: 13, fill: C.secondary });
  const rows = [['viewfinder', 'QRをスキャン', 'アプリを開いてスキャンを始める', false], ['qr', 'QRコードを作成', 'テキストから QR コードの画像を作る', true], ['photo', '画像のQRコードを読む', '画像に写ったコードの中身を取り出す', true]];
  s += rect(16, 228, 361, 3 * 72, { rx: 14, fill: C.card });
  rows.forEach(([i0, ti, su, nw], k) => {
    const y = 228 + k * 72;
    s += tile(30, y + 16, 40, C.accentFill, i0, 10) + t(82, y + 33, ti, { size: 16, weight: 700 }) + t(82, y + 54, su, { size: 12, fill: C.secondary }) +
      (nw ? newBadge(325, y + 14) : '') + (k < 2 ? line(82, y + 72, 377, y + 72) : '');
  });
  s += noteBox(462, ['ショートカットで作った・読んだものは、', '履歴に保存しません。アプリは通信しません。'], { icon: 'shield', iconColor: C.accent, fill: C.accentSoft, text: C.accentDark });
  return s + L.homeIndicator(false);
}
function n2() {
  return rect(0, 0, 393, 852, { fill: C.bg }) + statusBar(false) + t(196.5, 88, '店頭用 QR を作る', { size: 17, weight: 700, anchor: 'middle' }) +
    scBlock(124, '#8E8E93', 'text', 'テキスト', 'https://www.example.co.jp/menu') + arrowDown(194) +
    scBlock(218, C.accentFill, 'qr', 'QRコードを作成', '入力：テキスト', { isNew: true }) + arrowDown(288) +
    scBlock(312, '#F2A33A', 'photo', '写真アルバムに保存', '入力：QRコード（画像）') +
    `<g filter="url(#shadow)">${rect(96.5, 412, 200, 228, { rx: 16, fill: C.card })}</g>` +
    rect(116.5, 428, 160, 160, { rx: 8, fill: '#fff', stroke: C.separator }) + fakeQR(124.5, 436, 144, 29, '#000', 41) +
    t(196.5, 614, '出力：PNG 画像', { size: 13, weight: 600, fill: C.secondary, anchor: 'middle' }) +
    noteBox(664, ['作れるのはテキスト・URL の QR です。Wi-Fi など', 'の種類は、アプリの「作成」から作ります。']) +
    L.homeIndicator(false);
}
function n3() {
  return rect(0, 0, 393, 852, { fill: C.bg }) + statusBar(false) + t(196.5, 88, 'スクショの QR を読む', { size: 17, weight: 700, anchor: 'middle' }) +
    scBlock(124, '#F2A33A', 'photo', '写真を選択', '最新の写真 1 枚') + arrowDown(194) +
    scBlock(218, C.accentFill, 'photo', '画像のQRコードを読む', '入力：写真', { isNew: true }) + arrowDown(288) +
    scBlock(312, '#5B8DEF', 'docText', 'クイックルック', '入力：読み取った内容') +
    `<g filter="url(#shadow)">${rect(16, 412, 361, 150, { rx: 16, fill: C.card })}</g>` +
    t(32, 442, '出力：テキストの一覧（2 件）', { size: 13, weight: 600, fill: C.secondary }) +
    t(32, 474, 'https://www.example.co.jp/menu', { size: 15, mono: true }) + line(32, 490, 361, 490) +
    t(32, 522, '4901234567894', { size: 15, mono: true }) +
    t(32, 548, '画像に複数のコードがあれば、全部を返します', { size: 12, fill: C.secondary }) +
    L.homeIndicator(false);
}

// ---------- 24 O：QR の色 ----------
const FG = ['#000000', '#0A5F4E', '#1E3A8A', '#5B21B6', '#7C2D12', '#9D174D', '#374151', '#F59E0B'];
const BG = ['#FFFFFF', '#FFF8E7', '#EAF7F2', '#EEF2FF', '#FDF2F8', '#111827'];
function lum(hex) {
  const c = [1, 3, 5].map(i => parseInt(hex.slice(i, i + 2), 16) / 255).map(v => (v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4));
  return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2];
}
const usable = (fg, bg) => lum(fg) < lum(bg) && (lum(bg) + 0.05) / (lum(fg) + 0.05) >= 4.5;
function swatchRow(y, label, colors, sel, other, isFg) {
  let s = t(32, y, label, { size: 13, weight: 600, fill: C.secondary });
  colors.forEach((c, i) => {
    const cx = 54 + i * 40, cy = y + 30;
    const ok = isFg ? usable(c, other) : usable(other, c);
    s += `<circle cx="${cx}" cy="${cy}" r="15" fill="${c}" stroke="${C.separator}" opacity="${ok ? 1 : 0.28}"/>` +
      (i === sel ? `<circle cx="${cx}" cy="${cy}" r="19.5" fill="none" stroke="${C.accent}" stroke-width="2.5"/>` : '') +
      (!ok ? `<path d="M${cx - 9} ${cy + 9}L${cx + 9} ${cy - 9}" stroke="${C.secondary}" stroke-width="2"/>` : '');
  });
  return s;
}
function colorScreen(fgI, bgI, o = {}) {
  const fg = FG[fgI], bg = BG[bgI];
  let s = navBack('URL') + field(136, 'URL', 'https://www.example.co.jp', { mono: true }) +
    `<g filter="url(#shadow)">${rect(16, 200, 361, 252, { rx: 18, fill: C.card })}</g>` +
    rect(96.5, 212, 200, 200, { rx: 12, fill: bg, stroke: C.separator }) + fakeQR(108.5, 224, 176, 29, fg, 3) +
    t(196.5, 436, 'https://www.example.co.jp', { size: 12, mono: true, fill: C.secondary, anchor: 'middle' });
  if (o.locked) {
    s += rect(16, 466, 361, 128, { rx: 16, fill: C.card }) + ic('palette', 32, 482, 24, C.lockedTile) +
      t(66, 500, '色', { size: 16, weight: 800, fill: C.secondary }) + proBadge(309, 482) +
      t(32, 534, '模様と背景の色を変えられます（Pro）。', { size: 13, fill: C.secondary }) +
      t(32, 554, '読み取りにくい組み合わせは選べません。', { size: 13, fill: C.secondary }) +
      rect(32, 566, 120, 20, { rx: 0, fill: 'none' }) + t(32, 582, 'Pro を見る', { size: 14, weight: 700, fill: C.accent });
  } else {
    s += rect(16, 466, 361, 176, { rx: 16, fill: C.card }) + ic('palette', 32, 478, 22, C.accent) + t(62, 495, '色', { size: 16, weight: 800 }) + newBadge(90, 480) +
      t(361, 495, '白黒に戻す', { size: 13, weight: 600, fill: C.accent, anchor: 'end' }) +
      swatchRow(522, '模様', FG, fgI, bg, true) + swatchRow(584, '背景', BG, bgI, fg, false);
  }
  if (o.warn) {
    s += `<path d="M206 646l8-10 8 10z" fill="#1C1C1E"/>` + `<g filter="url(#shadowLg)">${rect(30, 646, 333, 62, { rx: 14, fill: '#1C1C1E' })}</g>` +
      icon('info', 44, 658, 18, '#FFD60A') + t(70, 670, 'この組み合わせは読み取りにくいため', { size: 13, weight: 600, fill: '#fff' }) +
      t(70, 690, '選べません（模様を背景より暗く、差を大きく）', { size: 12, fill: 'rgba(255,255,255,0.8)' });
  }
  const by = o.locked ? 610 : 656;
  const buttons = rect(16, by, 176, 54, { rx: 14, fill: C.accentFill }) + iconLabel(104, by + 34, 'download', 20, '写真に保存', { size: 16, weight: 700, fill: '#fff' }) +
    rect(201, by, 176, 54, { rx: 14, fill: C.card, stroke: C.separator }) + iconLabel(289, by + 34, 'share', 20, '共有', { size: 16, weight: 700, fill: C.accent });
  // The warning balloon sits over the buttons, as a transient message.
  return (o.warn ? s.replace(/(<path d="M206 646)/, buttons + '$1') : s + buttons) + tabBar(2, false);
}

// ---------- 25 H：履歴にメモ ----------
function h1() {
  let s = navBack('履歴') + glassCircle(355, 82, 22, 'star', false);
  s += resultHead(124, 'wifi', 'wifi', 'Wi-Fi', 'QRコード · 2026/11/12 08:05') +
    rect(16, 188, 361, 134, { rx: 14, fill: C.card }) +
    t(32, 220, 'ネットワーク名', { size: 15, fill: C.secondary }) + t(361, 220, 'Seijitsu-Guest', { size: 15, weight: 700, anchor: 'end' }) + line(32, 236, 377, 236) +
    t(32, 264, 'セキュリティ', { size: 15, fill: C.secondary }) + t(361, 264, 'WPA/WPA2/WPA3', { size: 15, weight: 700, anchor: 'end' }) + line(32, 280, 377, 280) +
    t(32, 308, 'パスワード', { size: 15, fill: C.secondary }) + t(327, 308, '••••••••••', { size: 15, weight: 700, anchor: 'end' }) + icon('eye', 339, 294, 22, C.accent) +
    t(32, 352, 'メモ', { size: 13, weight: 600, fill: C.secondary }) + newBadge(66, 338) +
    rect(16, 360, 361, 92, { rx: 14, fill: C.card, stroke: C.accent, sw: 1.5 }) +
    t(32, 390, '3階 大会議室の来客用。', { size: 16 }) + t(32, 414, '毎月1日にパスワードが変わる。', { size: 16 }) +
    t(361, 440, '26 / 200', { size: 12, fill: C.secondary, anchor: 'end' }) +
    t(32, 474, 'メモはこの iPhone の履歴にだけ保存されます。', { size: 12, fill: C.secondary });
  s += pinnedQuad('wifi', 'このWi-Fiに接続', [['qr', 'QRを表示'], ['copy', 'コピー'], ['share', '共有'], ['star', 'お気に入り', C.yellow]]);
  return s;
}
function noteRow(y, kind, ic0, title, memo, meta, last, hl) {
  return rect(16, y, 361, 82, { fill: C.card }) + tile(30, y + 16, 36, C.kind[kind], ic0, 9) +
    t(78, y + 27, title, { size: 16, weight: 600 }) +
    (memo ? t(78, y + 48, hl ? [{ s: 'メモ：' }, { s: hl, weight: 800, fill: C.accentDark }, { s: memo.slice(hl.length) }] : 'メモ：' + memo, { size: 13, fill: C.label }) : '') +
    t(78, y + (memo ? 68 : 50), meta, { size: 12, fill: C.secondary }) +
    (last ? '' : line(78, y + 82, 377, y + 82));
}
function historyHead(q) {
  const right = glass(377 - 96, 58, 96, 44, false) + icon('share', 377 - 84, 69, 22, C.label) + icon('selectCircle', 377 - 38, 69, 22, C.label);
  return S.navLarge('履歴', right) + rect(16, 148, 361, 38, { rx: 10, fill: C.fill }) + icon('search', 26, 157, 20, C.secondary) +
    (q ? t(52, 173, q, { size: 16 }) : t(52, 173, '日時・種類・内容・メモで検索', { size: 16, fill: C.placeholder }));
}
function h2() {
  return historyHead() + t(32, 218, '今日', { size: 13, weight: 600, fill: C.secondary }) +
    `<clipPath id="hn1"><rect x="16" y="226" width="361" height="246" rx="14"/></clipPath><g clip-path="url(#hn1)">` +
    noteRow(226, 'wifi', 'wifi', 'Seijitsu-Guest', '3階 大会議室の来客用。', 'Wi-Fi · QRコード · 08:05') +
    noteRow(308, 'url', 'link', 'https://www.example.co.jp/c…', '', 'URL · QRコード · 07:58') +
    noteRow(372, 'text', 'barcode', '4901234567894', '倉庫Bの棚3', 'テキスト · EAN-13 · 07:40', true) + '</g>' +
    t(32, 502, '昨日', { size: 13, weight: 600, fill: C.secondary }) +
    `<clipPath id="hn2"><rect x="16" y="510" width="361" height="82" rx="14"/></clipPath><g clip-path="url(#hn2)">` +
    noteRow(510, 'contact', 'person', '山田 太郎（誠実商事）', '展示会で名刺交換', '連絡先 · QRコード · 18:21', true) + '</g>' +
    tabBar(1, false);
}
function h3() {
  return historyHead('会議室') + t(32, 218, '検索結果 1 件', { size: 13, weight: 600, fill: C.secondary }) +
    `<clipPath id="hn3"><rect x="16" y="226" width="361" height="82" rx="14"/></clipPath><g clip-path="url(#hn3)">` +
    noteRow(226, 'wifi', 'wifi', 'Seijitsu-Guest', '3階 大会議室の来客用。', 'Wi-Fi · QRコード · 08:05', true, '3階 大会議室') + '</g>' +
    noteBox(330, ['メモも検索の対象です。', 'CSV の書き出しにも「メモ」の列が付きます。']) +
    tabBar(1, false);
}

// ---------- 26 I：数えながら読む ----------
function i1() {
  let s = scanBase() + controls4(false, false) + rect(0, 0, 393, 852, { fill: 'rgba(0,0,0,0.35)' });
  s += `<g filter="url(#shadowLg)">${rect(40, 430, 313, 180, { rx: 16, fill: 'rgba(242,242,247,0.97)' })}</g>` +
    ic('repeat', 58, 450, 22, C.accent) + t(90, 466, '続けて読む', { size: 16, weight: 700 }) +
    t(90, 486, '同じコードは 1 回だけ記録（今までどおり）', { size: 12, fill: C.secondary }) + line(40, 506, 353, 506) +
    ic('tally', 58, 524, 22, C.accent) + t(90, 540, '数えながら読む', { size: 16, weight: 700 }) + proBadge(222, 524) + newBadge(280, 525) +
    t(90, 560, '同じコードを読むたびに 1 つ数える（棚卸し）', { size: 12, fill: C.secondary }) +
    t(90, 578, '在庫や持ち物の数を確かめるときに', { size: 12, fill: C.secondary });
  return s + tabBar(0, true);
}
function countRow(y, code, kind, n, isLast) {
  return t(28, y + 18, code, { size: 15, weight: 700, mono: true, fill: '#fff' }) + t(28, y + 36, kind, { size: 12, fill: 'rgba(255,255,255,0.6)' }) +
    `<circle cx="262" cy="${y + 20}" r="15" fill="rgba(255,255,255,0.14)"/>` + ic('minus', 252, y + 10, 20, '#fff') +
    t(301, y + 27, String(n), { size: 20, weight: 800, fill: '#fff', anchor: 'middle' }) +
    `<circle cx="340" cy="${y + 20}" r="15" fill="rgba(255,255,255,0.14)"/>` + ic('plus', 330, y + 10, 20, '#fff') +
    (isLast ? '' : `<line x1="28" y1="${y + 46}" x2="365" y2="${y + 46}" stroke="rgba(255,255,255,0.12)"/>`);
}
function i2() {
  const X = 106.5, Y = 132, Sz = 180;
  let s = S.cameraFeed() + dimOutside(X, Y, Sz) + reticle(X, Y, Sz, C.accentOnDark) + statusBar(true) +
    S.pillNote(348, 'checkCircle', '＋1　4901234567894（3 個目）', { size: 13, weight: 700, fill: C.label, iconColor: C.accent }, 'rgba(255,255,255,0.95)', 40) +
    rect(12, 378, 369, 262, { rx: 22, fill: 'rgba(28,28,30,0.94)' }) +
    ic('tally', 28, 394, 20, C.accentOnDark) + t(56, 410, '数えた数', { size: 15, weight: 700, fill: '#fff' }) +
    t(56, 430, '3 種類・合計 7 個', { size: 12, fill: 'rgba(255,255,255,0.7)' }) +
    t(365, 410, '終了', { size: 15, weight: 700, fill: C.accentOnDark, anchor: 'end' }) +
    `<line x1="28" y1="444" x2="365" y2="444" stroke="rgba(255,255,255,0.12)"/>` +
    countRow(452, '4901234567894', 'EAN-13（JAN）', 3) + countRow(500, '4909876543210', 'EAN-13（JAN）', 2) + countRow(548, 'SHELF-B-03', 'QRコード', 2, true) +
    t(196.5, 620, 'かざしたままでは数えません。1 秒離すと次を数えます', { size: 11, fill: 'rgba(255,255,255,0.6)', anchor: 'middle' }) +
    controls4(false, true, '数える ON');
  return s + tabBar(0, true);
}
function i3() {
  const Y = 196, H = Y + 46;
  let s = S.sheetBackdrop() + S.sheetTop(Y) + S.sheetClose(Y + 30) +
    t(196.5, Y + 36, '数えた結果', { size: 17, weight: 700, anchor: 'middle' }) +
    t(16, H + 30, '3 種類・合計 7 個', { size: 22, weight: 800 }) + t(16, H + 52, '2026/11/12 10:02〜10:09', { size: 13, fill: C.secondary }) +
    rect(16, H + 70, 361, 150, { rx: 14, fill: C.card });
  [['4901234567894', 'EAN-13（JAN）', 3], ['4909876543210', 'EAN-13（JAN）', 2], ['SHELF-B-03', 'QRコード', 2]].forEach(([c, k, n], i) => {
    const y = H + 70 + i * 50;
    s += t(32, y + 22, c, { size: 15, weight: 700, mono: true }) + t(32, y + 40, k, { size: 12, fill: C.secondary }) +
      t(361, y + 31, `${n} 個`, { size: 17, weight: 800, anchor: 'end' }) + (i < 2 ? line(32, y + 50, 377, y + 50) : '');
  });
  s += rect(16, H + 240, 361, 54, { rx: 14, fill: C.accentFill }) + iconLabel(196.5, H + 274, 'docText', 22, 'CSV で書き出す', { size: 17, weight: 700, fill: '#fff' }) +
    t(196.5, H + 314, 'コード・種類・数・最後に読んだ時刻', { size: 12, fill: C.secondary, anchor: 'middle' }) +
    secondary(H + 330, 'clock', '履歴に保存して終える') +
    t(196.5, H + 412, '保存しないで終える', { size: 16, weight: 600, fill: C.red, anchor: 'middle' }) +
    t(196.5, H + 436, '数えた結果は、終えると消えます（履歴に保存した分は残ります）', { size: 11, fill: C.secondary, anchor: 'middle' });
  return s + L.homeIndicator(false);
}

// ---------- 27 J：印刷 ----------
function j1() {
  return rect(0, 0, 393, 852, { fill: '#FFFFFF' }) + statusBar(false) + glassCircle(38, 82, 20, 'xmark', false) +
    t(196.5, 88, 'Seijitsu-Guest', { size: 17, weight: 700, anchor: 'middle', fill: '#1C1C1E' }) + t(196.5, 108, 'Wi-Fi', { size: 13, anchor: 'middle', fill: '#6B6B70' }) +
    rect(56.5, 150, 280, 280, { rx: 16, fill: '#FFFFFF', stroke: '#E5E5EA' }) + fakeQR(72.5, 166, 248, 33, '#000', 5) +
    S.pillNote(470, 'bolt', '表示中は画面を最大の明るさにしています', { size: 12, weight: 600, fill: '#0A5F4E', iconColor: '#0E7C66' }, '#E3F2EE', 32) +
    rect(16, 610, 361, 54, { rx: 14, fill: '#0E7C66' }) + iconLabel(196.5, 644, 'download', 22, '写真に保存', { size: 17, weight: 700, fill: '#fff' }) +
    rect(16, 674, 176, 54, { rx: 14, fill: '#FFFFFF', stroke: '#E5E5EA' }) + iconLabel(104, 708, 'share', 20, '画像を共有', { size: 16, weight: 700, fill: '#0E7C66' }) +
    rect(201, 674, 176, 54, { rx: 14, fill: '#FFFFFF', stroke: '#0E7C66', sw: 1.5 }) + ic('printer', 238, 690, 22, '#0E7C66') + t(268, 708, '印刷', { size: 16, weight: 700, fill: '#0E7C66' }) + newBadge(320, 664) +
    rect(129.5, 838, 134, 5, { rx: 2.5, fill: '#000' });
}
function seg(y, items, sel) {
  const w = 361 / items.length;
  return rect(16, y, 361, 36, { rx: 9, fill: C.fill }) + rect(16 + sel * w + 2, y + 2, w - 4, 32, { rx: 7, fill: C.card, filter: 'url(#shadow)' }) +
    items.map((s, i) => t(16 + i * w + w / 2, y + 23, s, { size: 13, weight: 600, anchor: 'middle' })).join('');
}
function j2() {
  const Y = 120;
  let s = rect(0, 0, 393, 852, { fill: '#000' }) + `<path d="M0 ${Y + 12}a12 12 0 0 1 12-12H381a12 12 0 0 1 12 12V852H0Z" fill="${C.bg}"/>` + statusBar(true) +
    rect(178.5, Y + 6, 36, 5, { rx: 2.5, fill: C.grabber }) + glassCircle(38, Y + 38, 20, 'xmark', false) + t(196.5, Y + 44, '印刷', { size: 17, weight: 700, anchor: 'middle' }) +
    t(32, Y + 90, '並べ方', { size: 13, weight: 600, fill: C.secondary }) + seg(Y + 98, ['1 枚に大きく', 'ラベルのように並べる'], 1) +
    // preview of an A4 sheet with 3 x 6 labels
    `<g filter="url(#shadow)">${rect(111.5, Y + 154, 170, 240, { rx: 4, fill: '#fff' })}</g>`;
  for (let r = 0; r < 6; r++) for (let c = 0; c < 3; c++) {
    const x = 121.5 + c * 52, y = Y + 164 + r * 38;
    s += fakeQR(x + 12, y + 2, 26, 21, '#000', 5 + r + c) + t(x + 25, y + 36, 'Seijitsu-Guest', { size: 5, anchor: 'middle', fill: '#333' });
  }
  s += t(196.5, Y + 414, 'A4 に 3 列 × 6 段（18 枚）', { size: 12, fill: C.secondary, anchor: 'middle' }) +
    S.group(Y + 432, 102) + t(32, Y + 467, '1 枚の大きさ', { size: 16 }) + t(361, Y + 467, '4 cm', { size: 16, weight: 700, anchor: 'end' }) + S.sep(Y + 483) +
    t(32, Y + 518, '下にネットワーク名を入れる', { size: 16 }) + L.toggle(310, Y + 498, true) +
    t(32, Y + 556, 'パスワードは文字では印刷しません（QR の中には入っています）。', { size: 11, fill: C.secondary }) +
    rect(16, Y + 574, 361, 54, { rx: 14, fill: C.accentFill }) + icLabel(196.5, Y + 608, 'printer', 22, 'プリンタを選ぶ', { size: 17, weight: 700, fill: '#fff', iconColor: '#fff' });
  return s + L.homeIndicator(false);
}
function j3() {
  let s = rect(0, 0, 393, 852, { fill: C.bg }) + statusBar(false) +
    t(40, 88, 'キャンセル', { size: 17, fill: C.accent }) + t(196.5, 88, 'オプション', { size: 17, weight: 700, anchor: 'middle' }) + t(361, 88, 'プリント', { size: 17, weight: 700, fill: C.accent, anchor: 'end' }) +
    S.group(120, 154) + t(32, 155, 'プリンタ', { size: 16 }) + t(348, 155, 'Office-Printer', { size: 16, fill: C.secondary, anchor: 'end' }) + icon('chevron', 352, 141, 18, C.tertiary) + S.sep(171) +
    t(32, 206, '部数', { size: 16 }) + t(361, 206, '1', { size: 16, anchor: 'end' }) + S.sep(222) +
    t(32, 257, '用紙サイズ', { size: 16 }) + t(361, 257, 'A4', { size: 16, fill: C.secondary, anchor: 'end' }) +
    `<g filter="url(#shadow)">${rect(121.5, 310, 150, 212, { rx: 3, fill: '#fff' })}</g>`;
  for (let r = 0; r < 6; r++) for (let c = 0; c < 3; c++) s += fakeQR(131.5 + c * 46 + 10, 320 + r * 33 + 2, 22, 21, '#000', 5 + r + c);
  s += t(196.5, 548, '1 / 1 ページ', { size: 13, fill: C.secondary, anchor: 'middle' }) +
    noteBox(580, ['この画面は iOS の印刷画面です。プリンタとの', 'やり取りは iOS（AirPrint）が行います。']);
  return s + L.homeIndicator(false);
}

// ---------- 28 K：Apple Watch ----------
function k1() {
  let s = S.navLarge('設定') + S.secHead(164, 'Apple Watch') + S.group(172, 214) +
    ic('watch', 32, 188, 24, C.accent) + t(66, 207, 'Apple Watch に表示', { size: 16 }) + L.toggle(310, 187, true) + newBadge(226, 192) + S.sep(223, 66);
  [['wifi', 'wifi', 'Seijitsu-Guest', true], ['url', 'link', '会員証（example.co.jp）', true], ['text', 'barcode', '4901234567894', false]].forEach(([k, i0, ti, on], i) => {
    const y = 224 + i * 54;
    s += tile(32, y + 12, 30, C.kind[k], i0, 7) + t(74, y + 33, ti, { size: 15 }) +
      (on ? icon('checkCircle', 337, y + 15, 24, C.accent) : `<circle cx="349" cy="${y + 27}" r="11" fill="none" stroke="${C.tertiary}" stroke-width="1.5"/>`) + (i < 2 ? S.sep(y + 54, 74) : '');
  });
  s += t(32, 412, 'お気に入りから選んだ QR だけを、ペアリングした', { size: 12, fill: C.secondary }) +
    t(32, 430, 'Apple Watch に送ります（Pro）。インターネットの', { size: 12, fill: C.secondary }) +
    t(32, 448, 'サーバーには送りません。', { size: 12, fill: C.secondary });
  return s + tabBar(3, false);
}
// Watch screen 198x242 drawn inside the phone-sized slot (centered) on a dark backdrop.
function watchSlot(inner, caption) {
  const x = 97.5, y = 260;
  return `<g filter="url(#shadowLg)">${rect(x - 22, y - 30, 242, 302, { rx: 62, fill: '#1C1C1E' })}</g>` +
    rect(x - 34, y + 96, 14, 50, { rx: 6, fill: '#2C2C2E' }) + rect(x + 222, y + 70, 12, 40, { rx: 5, fill: '#3A3A3C' }) +
    `<clipPath id="wclip${caption}"><rect x="${x}" y="${y}" width="198" height="242" rx="44"/></clipPath>` +
    `<g clip-path="url(#wclip${caption})"><rect x="${x}" y="${y}" width="198" height="242" fill="#000"/><g transform="translate(${x} ${y})">${inner}</g></g>`;
}
function k2() {
  const rows = [['wifi', 'wifi', 'Seijitsu-Guest'], ['url', 'link', '会員証']];
  let s = t(20, 34, 'QR', { size: 15, weight: 700, fill: C.accentOnDark }) + t(178, 34, '10:09', { size: 15, weight: 600, fill: '#fff', anchor: 'end' });
  rows.forEach(([k, i0, ti], i) => {
    const y = 52 + i * 66;
    s += rect(8, y, 182, 58, { rx: 16, fill: '#222' }) + tile(18, y + 14, 30, C.kind[k], i0, 8) + t(58, y + 35, ti, { size: 14, weight: 700, fill: '#fff' });
  });
  s += t(99, 212, 'iPhone で選んだお気に入り', { size: 10, fill: 'rgba(255,255,255,0.55)', anchor: 'middle' });
  return watchSlot(s, 'k2');
}
function k3() {
  const s = rect(0, 0, 198, 242, { fill: '#fff' }) + fakeQR(31, 34, 136, 29, '#000', 5) +
    t(99, 196, 'Seijitsu-Guest', { size: 13, weight: 700, fill: '#1C1C1E', anchor: 'middle' }) +
    t(99, 214, '画面を明るくしています', { size: 10, fill: '#6B6B70', anchor: 'middle' });
  return watchSlot(s, 'k3');
}

write('21_create_more_kinds.svg', '21 作れる種類を増やす（案 L・Pro）', '作成に「メール」「電話」「SMS」「地図の位置」を追加。読み取りは対応済みなので、作る側だけを足す。',
  '地図は表示しない（地図の画像を取りに行く通信が要るため）。現在地は押したときだけ使い、送らない。',
  [[l1(), 'L1 作成：9 種類'], [l2(), 'L2 メール'], [l3(), 'L3 地図の位置']]);
write('22_paste.svg', '22 貼り付けて読む・作る（案 M・無料）', 'スキャン画面に「貼り付け」。コピーした画像は写真と同じく読み取り、文字はそのまま結果として表示（URL の注意も出る）。',
  'iOS の PasteButton を使うので、押したときだけ読み、許可の確認は出ない。アプリが勝手にクリップボードを読むことはない。',
  [[m1(), 'M1 スキャン画面'], [m2(), 'M2 貼り付けた結果'], [m3(), 'M3 作成の入力に貼り付け']]);
write('23_shortcuts.svg', '23 ショートカットのアクション（案 N・無料）', '「QRコードを作成」（テキスト→画像）と「画像のQRコードを読む」（画像→テキスト）を、ショートカットアプリに出す。',
  'ショートカットで作った・読んだものは履歴に保存しない。Wi-Fi などの種類はアプリの「作成」から作る。',
  [[n1(), 'N1 アクションの一覧'], [n2(), 'N2 例：テキストから QR'], [n3(), 'N3 例：スクショの QR を読む']]);
write('24_qr_color.svg', '24 QR の色を変える（案 O・Pro）', '作成の結果に「色」。模様 8 色・背景 6 色から選ぶ。模様が背景より暗く、コントラスト比 4.5:1 以上の組み合わせだけ選べる。',
  '色は保存・共有・印刷する画像だけに付き、履歴には中身だけを残す（再表示は白黒）。',
  [[colorScreen(1, 1), 'O1 色を選ぶ'], [colorScreen(1, 1, { warn: true }), 'O2 選べない組み合わせ'], [colorScreen(0, 0, { locked: true }), 'O3 無料のとき']]);
write('25_history_note.svg', '25 履歴にメモ（案 H・無料）', '履歴の詳細に「メモ」（200 文字まで）。一覧にはメモを 2 行目に出し、検索とCSV の書き出しにも入れる。',
  '履歴のスキーマを V2 にして、今の履歴を自動で移す（消さない）。メモはこの端末の履歴にだけ保存。',
  [[h1(), 'H1 詳細でメモを書く'], [h2(), 'H2 一覧にメモ'], [h3(), 'H3 メモで検索']]);
write('26_stocktake.svg', '26 数えながら読む・棚卸し（案 I・Pro）', '「連続スキャン」に「数えながら読む」を追加。同じコードを読むたびに 1 つ数え、−・＋で直せる。',
  'かざしたままでは数えない（1 秒以上見えなくなってから次を数える）。終了時に CSV・履歴への保存を選ぶ。',
  [[i1(), 'I1 読み方を選ぶ'], [i2(), 'I2 数えている画面'], [i3(), 'I3 数えた結果']]);
write('27_print.svg', '27 印刷（案 J・無料）', 'コードの全画面表示に「印刷」。「1 枚に大きく」か「ラベルのように並べる」（A4 に 3 列 × 6 段）を選び、大きさ（cm）を決める。',
  '下に入れる文字にパスワードは入れない。プリンタとのやり取りは iOS（AirPrint）が行い、アプリは通信しない。',
  [[j1(), 'J1 全画面表示に「印刷」'], [j2(), 'J2 並べ方と大きさ'], [j3(), 'J3 iOS の印刷画面']]);
write('28_apple_watch.svg', '28 Apple Watch に表示（案 K・Pro）', 'iPhone の設定で、お気に入りから Watch に出す QR を選ぶ。Watch では一覧から選んで、白地の全画面で表示。',
  'ペアリングした Watch へ Apple の WatchConnectivity で送る。Watch では読み取りはしない（カメラがない）。',
  [[k1(), 'K1 iPhone の設定'], [k2(), 'K2 Watch：一覧', true], [k3(), 'K3 Watch：QR を表示', true]]);
