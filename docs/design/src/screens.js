const fs = require('fs');
const path = require('path');
const L = require('./lib');
const { C, t, measure, iconLabel, rect, icon, tile, statusBar, tabBar, phone, doc, fakeQR, toggle, glass, glassCircle } = L;

const OUT = process.argv[2];
const W1 = 393, GAP = 90, PAD = 70;
const canvasW = n => PAD * 2 + n * W1 + (n - 1) * GAP;
const px = i => PAD + i * (W1 + GAP);
const CANVAS_H = 852 + 70 + 70 + 40 + 70;

function header(title, sub) {
  return t(PAD - 13, 48, title, { size: 26, weight: 800, fill: C.label }) +
    (sub ? t(PAD - 13, 76, sub, { size: 15, fill: C.secondary }) : '');
}
const OY = 120;

// Pill sized to its measured content, centered horizontally on the screen.
function pillNote(baseline, ic, label, o, bg, h) {
  const w = 18 + measure(label, o) + 6 + 20 + 18;
  const top = baseline - (o.size * 0.36) - h / 2;
  return rect(196.5 - w / 2, top, w, h, { rx: h / 2, fill: bg }) + iconLabel(196.5, baseline, ic, o.size + 6, label, { ...o, gap: 6 });
}

// Largest size <= max (0.5pt steps) at which the label fits in width (mirrors SwiftUI minimumScaleFactor).
function fitSize(label, max, width, weight) {
  let size = max;
  while (size > 9 && measure(label, { size, weight }) > width) size -= 0.5;
  return size;
}

// ---------- 01 Scan ----------
function cameraFeed() {
  return rect(0, 0, 393, 852, { fill: 'url(#camBg)' }) +
    `<g filter="url(#blur6)" opacity=".9">
      <rect x="-40" y="600" width="480" height="300" fill="#4A4038"/>
      <rect x="250" y="120" width="190" height="260" rx="6" fill="#56605D"/>
      <circle cx="60" cy="170" r="70" fill="#5B6563" opacity=".6"/>
    </g>
    <g transform="rotate(-4 196 380)">
      <rect x="86" y="262" width="222" height="240" rx="8" fill="#E9E6DD"/>
      <rect x="102" y="278" width="190" height="10" rx="3" fill="#B8B2A4"/>
      ${fakeQR(122, 300, 150, 29, '#1A1A1A', 11)}
      <rect x="112" y="466" width="170" height="8" rx="3" fill="#C9C3B5"/>
      <rect x="132" y="480" width="130" height="8" rx="3" fill="#C9C3B5"/>
    </g>`;
}
function reticle(x, y, s, color = '#fff') {
  const L2 = 38, r = 24;
  return `<g fill="none" stroke="${color}" stroke-width="5" stroke-linecap="round">
    <path d="M${x} ${y + L2}V${y + r}a${r} ${r} 0 0 1 ${r}-${r}H${x + L2}"/>
    <path d="M${x + s - L2} ${y}H${x + s - r}a${r} ${r} 0 0 1 ${r} ${r}V${y + L2}"/>
    <path d="M${x + s} ${y + s - L2}V${y + s - r}a${r} ${r} 0 0 1 -${r} ${r}H${x + s - L2}"/>
    <path d="M${x + L2} ${y + s}H${x + r}a${r} ${r} 0 0 1 -${r}-${r}V${y + s - L2}"/></g>`;
}
function dimOutside(x, y, s) {
  return `<path fill="rgba(0,0,0,0.5)" fill-rule="evenodd" d="M0 0H393V852H0Z M${x + 24} ${y}H${x + s - 24}a24 24 0 0 1 24 24V${y + s - 24}a24 24 0 0 1-24 24H${x + 24}a24 24 0 0 1-24-24V${y + 24}a24 24 0 0 1 24-24Z"/>`;
}
// Scan controls sit in the lower part of the screen, within thumb reach (above the tab bar).
const CONTROL_Y = 678;
function controlButton(cx, name, label, on) {
  return glassCircle(cx, CONTROL_Y, 28, name, true, on) +
    t(cx, CONTROL_Y + 50, label, { size: 12, weight: 600, fill: '#fff', anchor: 'middle' });
}
function scanControls(continuous, torch) {
  return controlButton(92, 'photo', '写真から') +
    controlButton(196.5, 'repeat', continuous ? '連続 ON' : '連続スキャン', continuous) +
    controlButton(301, 'bolt', 'ライト', torch);
}
function privacyPill() {
  return pillNote(86, 'shield', '読み取り内容は端末内だけで処理します', { size: 12, weight: 500, fill: '#fff', iconColor: C.accentOnDark }, 'rgba(0,0,0,0.45)', 32);
}
function scanA() {
  const X = 66.5, Y = 200, S = 260;
  return cameraFeed() + dimOutside(X, Y, S) + reticle(X, Y, S) +
    rect(X + 20, Y + 148, S - 40, 2.5, { rx: 1.25, fill: 'url(#scanLine)' }) +
    statusBar(true) + privacyPill() +
    t(196.5, 504, 'コードを枠内に合わせてください', { size: 17, weight: 700, fill: '#fff', anchor: 'middle' }) +
    t(196.5, 530, 'QRコード・バーコード 11種類に対応', { size: 13, fill: 'rgba(255,255,255,0.75)', anchor: 'middle' }) +
    scanControls(false, false) +
    tabBar(0, true);
}
function trayRow(y, kind, ic, title, meta, isNew) {
  return tile(28, y, 32, C.kind[kind], ic, 8) +
    t(72, y + 14, title, { size: 15, weight: 600, fill: '#fff' }) +
    t(72, y + 30, meta, { size: 12, fill: 'rgba(255,255,255,0.6)' }) +
    (isNew ? rect(318, y + 6, 44, 20, { rx: 10, fill: C.accentOnDark }) + t(340, y + 20, '新規', { size: 11, weight: 700, fill: '#06281F', anchor: 'middle' }) : icon('chevron', 336, y + 7, 18, 'rgba(255,255,255,0.5)'));
}
function scanB() {
  const X = 86.5, Y = 132, S = 220;
  return cameraFeed() + dimOutside(X, Y, S) + reticle(X, Y, S, C.accentOnDark) +
    statusBar(true) + privacyPill() +
    // toast
    pillNote(398, 'checkCircle', '読み取りました（重複は記録しません）', { size: 13, weight: 600, fill: C.label, iconColor: C.accent }, 'rgba(255,255,255,0.95)', 40) +
    // tray
    rect(12, 424, 369, 200, { rx: 22, fill: 'rgba(28,28,30,0.94)' }) +
    t(28, 454, '今回の読み取り', { size: 15, weight: 700, fill: '#fff' }) +
    rect(134, 439, 28, 20, { rx: 10, fill: 'rgba(255,255,255,0.18)' }) + t(148, 454, '3', { size: 13, weight: 700, fill: '#fff', anchor: 'middle' }) +
    t(365, 454, '終了', { size: 15, weight: 600, fill: C.accentOnDark, anchor: 'end' }) +
    `<line x1="28" y1="468" x2="365" y2="468" stroke="rgba(255,255,255,0.12)"/>` +
    trayRow(478, 'text', 'barcode', '4901234567894', 'テキスト · EAN-13 · たった今', true) +
    trayRow(526, 'url', 'link', 'https://www.example.co.jp/item/…', 'URL · QRコード · 12秒前') +
    trayRow(574, 'text', 'barcode', '4909876543210', 'テキスト · EAN-13 · 25秒前') +
    scanControls(true, true) +
    tabBar(0, true);
}
function scanC() {
  return rect(0, 0, 393, 852, { fill: C.bg }) + statusBar(false) +
    `<circle cx="196.5" cy="270" r="56" fill="${C.accentSoft}"/>` + icon('cameraSlash', 166.5, 240, 60, C.accent) +
    t(196.5, 372, 'カメラへのアクセスが', { size: 22, weight: 800, anchor: 'middle' }) +
    t(196.5, 402, '許可されていません', { size: 22, weight: 800, anchor: 'middle' }) +
    t(196.5, 442, 'QRコードとバーコードを読み取るには、', { size: 15, fill: C.secondary, anchor: 'middle' }) +
    t(196.5, 464, '設定でカメラの使用を許可してください。', { size: 15, fill: C.secondary, anchor: 'middle' }) +
    t(196.5, 486, '読み取った内容が外部に送信されることはありません。', { size: 13, fill: C.secondary, anchor: 'middle' }) +
    rect(36, 528, 321, 52, { rx: 14, fill: C.accentFill }) + t(196.5, 560, '設定を開く', { size: 17, weight: 700, fill: '#fff', anchor: 'middle' }) +
    rect(36, 592, 321, 52, { rx: 14, fill: C.card, stroke: C.separator }) +
    iconLabel(196.5, 624, 'photo', 22, '写真から読み取る', { size: 17, weight: 600, fill: C.accent }) +
    tabBar(0, false);
}

// ---------- 02 Result ----------
function sheetBackdrop() {
  return cameraFeed() + rect(0, 0, 393, 852, { fill: 'rgba(0,0,0,0.55)' }) + statusBar(true);
}
function sheetTop(y) {
  return `<path d="M0 ${y + 14}a14 14 0 0 1 14-14H379a14 14 0 0 1 14 14V852H0Z" fill="${C.bg}"/>` + rect(178.5, y + 6, 36, 5, { rx: 2.5, fill: C.grabber });
}
// Sheet toolbar: Close (xmark) on the leading edge (HIG Sheets, iOS: Cancel/Close belongs on the leading edge).
function sheetClose(y) {
  return glassCircle(38, y, 20, 'xmark', false);
}
function resultHeader(y, kind, ic, title, meta) {
  return tile(16, y, 48, C.kind[kind], ic, 12) +
    t(76, y + 21, title, { size: 22, weight: 800 }) +
    t(76, y + 42, meta, { size: 13, fill: C.secondary });
}
// Primary action and secondary tiles pinned to the bottom of the sheet (thumb reach at any detent).
const PIN_Y = 676;
function pinnedBar(y, h) {
  return rect(0, y, 393, h, { fill: C.bg }) + `<line x1="0" y1="${y}" x2="393" y2="${y}" stroke="${C.separator}"/>`;
}
function resultPinned(ic, label, tiles) {
  return pinnedBar(PIN_Y, 852 - PIN_Y) +
    rect(16, PIN_Y + 12, 361, 54, { rx: 14, fill: C.accentFill }) + iconLabel(196.5, PIN_Y + 46, ic, 22, label, { size: 17, weight: 700, fill: '#fff' }) +
    actionTriple(PIN_Y + 76, tiles);
}
function actionTriple(y, items) {
  const w = (361 - 16) / 3;
  return items.map(([ic, label, col], i) => {
    const x = 16 + i * (w + 8);
    return rect(x, y, w, 66, { rx: 14, fill: C.card }) + icon(ic, x + w / 2 - 12, y + 11, 24, col || C.accent, ic === 'star') +
      t(x + w / 2, y + 54, label, { size: fitSize(label, 13, w - 16, 600), weight: 600, fill: col ? C.label : C.accent, anchor: 'middle' });
  }).join('');
}
function resultURL() {
  const Y = 236, H = Y + 46;
  return sheetBackdrop() + sheetTop(Y) + sheetClose(Y + 30) +
    resultHeader(H + 10, 'url', 'link', 'URL', 'QRコード · 2026/10/24 08:12') +
    rect(16, H + 74, 361, 214, { rx: 14, fill: C.card }) +
    t(32, H + 100, 'リンク先（全文・省略なし）', { size: 13, weight: 600, fill: C.secondary }) +
    t(32, H + 128, [{ s: 'https://' }, { s: 'www.example.co.jp', weight: 800 }, { s: '/campa' }], { size: 15, mono: true }) +
    t(32, H + 150, 'ign/2026/autumn?utm_source=qr&r', { size: 15, mono: true }) +
    t(32, H + 172, 'ef=store-1234&lang=ja', { size: 15, mono: true }) +
    `<line x1="32" y1="${H + 192}" x2="361" y2="${H + 192}" stroke="${C.separator}"/>` +
    t(32, H + 218, 'ドメイン', { size: 15, fill: C.secondary }) + t(361, H + 218, 'www.example.co.jp', { size: 15, weight: 700, anchor: 'end' }) +
    `<line x1="32" y1="${H + 234}" x2="361" y2="${H + 234}" stroke="${C.separator}"/>` +
    t(32, H + 260, '方式', { size: 15, fill: C.secondary }) + icon('lock', 361 - measure('https（暗号化）', { size: 15, weight: 600 }) - 20, H + 247, 16, C.accent) + t(361, H + 260, 'https（暗号化）', { size: 15, weight: 600, anchor: 'end' }) +
    icon('info', 18, H + 300, 16, C.secondary) +
    t(40, H + 313, '「ブラウザで開く」を押すまで通信は発生しません。', { size: 13, fill: C.secondary }) +
    iconLabel(196.5, H + 350, 'checkCircle', 16, '履歴に保存しました', { size: 13, fill: C.secondary, iconColor: C.green, gap: 6 }) +
    resultPinned('external', 'ブラウザで開く', [['copy', 'コピー'], ['share', '共有'], ['star', 'お気に入り', C.yellow]]) +
    L.homeIndicator(false);
}
function resultWiFi() {
  const Y = 236, H = Y + 46;
  const row = (y, k, v, extra = '') => t(32, y, k, { size: 15, fill: C.secondary }) + t(extra ? 327 : 361, y, v, { size: 15, weight: 700, anchor: 'end' }) + extra;
  return sheetBackdrop() + sheetTop(Y) + sheetClose(Y + 30) +
    resultHeader(H + 10, 'wifi', 'wifi', 'Wi-Fi', 'QRコード · 2026/10/24 08:05') +
    rect(16, H + 74, 361, 178, { rx: 14, fill: C.card }) +
    row(H + 106, 'ネットワーク名', 'Seijitsu-Cafe_5G') +
    `<line x1="32" y1="${H + 122}" x2="377" y2="${H + 122}" stroke="${C.separator}"/>` +
    row(H + 150, 'セキュリティ', 'WPA/WPA2/WPA3') +
    `<line x1="32" y1="${H + 166}" x2="377" y2="${H + 166}" stroke="${C.separator}"/>` +
    row(H + 194, 'パスワード', '••••••••••', icon('eye', 339, H + 180, 22, C.accent)) +
    `<line x1="32" y1="${H + 210}" x2="377" y2="${H + 210}" stroke="${C.separator}"/>` +
    row(H + 236, 'ステルス（非公開）', 'いいえ') +
    icon('info', 18, H + 266, 16, C.secondary) +
    t(40, H + 279, '接続時にiOSの確認ダイアログが表示されます。', { size: 13, fill: C.secondary }) +
    iconLabel(196.5, H + 316, 'checkCircle', 16, '履歴に保存しました', { size: 13, fill: C.secondary, iconColor: C.green, gap: 6 }) +
    resultPinned('wifi', 'このWi-Fiに接続', [['copy', 'パスワードをコピー'], ['share', '共有'], ['star', 'お気に入り', C.yellow]]) +
    L.homeIndicator(false);
}

// ---------- 03 History ----------
function navLarge(title, right) {
  return rect(0, 0, 393, 852, { fill: C.bg }) + statusBar(false) + (right || '') +
    t(16, 128, title, { size: 34, weight: 800 });
}
function histRow(y, kind, ic, title, meta, fav, last, offset = 0) {
  let s = '';
  if (offset) {
    s += rect(377 - 148, y, 74, 64, { fill: C.favFill }) + icon('star', 377 - 148 + 25, y + 12, 24, '#fff', true) + t(377 - 111, y + 54, 'お気に入り', { size: 10, weight: 700, fill: '#fff', anchor: 'middle' });
    s += rect(377 - 74, y, 74, 64, { fill: C.red }) + icon('trash', 377 - 74 + 25, y + 12, 24, '#fff') + t(377 - 37, y + 54, '削除', { size: 12, weight: 700, fill: '#fff', anchor: 'middle' });
  }
  s += `<g transform="translate(${-offset} 0)">` + rect(16, y, 361, 64, { fill: C.card }) +
    tile(30, y + 14, 36, C.kind[kind], ic, 9) +
    t(78, y + 29, title, { size: 16, weight: 600 }) +
    t(78, y + 49, meta, { size: 13, fill: C.secondary }) +
    (fav ? icon('star', 343, y + 21, 20, C.yellow, true) : '') +
    (last ? '' : `<line x1="78" y1="${y + 64}" x2="377" y2="${y + 64}" stroke="${C.separator}"/>`) + '</g>';
  return s;
}
function chips(x, y, items) {
  let s = '';
  for (const [label, on, ic] of items) {
    const o = { size: 14, weight: 600, fill: on ? '#fff' : C.label };
    const w = measure(label, o) + 28 + (ic ? 22 : 0);
    s += rect(x, y, w, 32, { rx: 16, fill: on ? C.accentFill : C.card, stroke: on ? null : C.separator });
    s += ic ? iconLabel(x + w / 2, y + 21, ic, 16, label, { ...o, iconColor: on ? '#fff' : C.yellow, iconExtra: true, gap: 6 }) : t(x + w / 2, y + 21, label, { ...o, anchor: 'middle' });
    x += w + 8;
  }
  return s;
}
function historyTop() {
  const right = glass(377 - 96, 58, 96, 44, false) + icon('share', 377 - 84, 69, 22, C.label) + icon('selectCircle', 377 - 38, 69, 22, C.label);
  return navLarge('履歴', right) +
    rect(16, 148, 361, 38, { rx: 10, fill: C.fill }) + icon('search', 26, 157, 20, C.secondary) +
    t(52, 173, '日時・種類・内容で検索', { size: 16, fill: C.placeholder }) +
    chips(16, 198, [['すべて', true], ['お気に入り', false, 'star'], ['URL', false], ['Wi-Fi', false], ['連絡先', false], ['テキスト', false]]);
}
function historyBanner(y) {
  return rect(16, y, 361, 58, { rx: 14, fill: C.accentSoft }) +
    icon('infinity', 30, y + 17, 24, C.accent) +
    t(66, y + 25, '無料版は直近30件まで保存します', { size: 14, weight: 700, fill: C.accentDark }) +
    t(66, y + 45, '現在 28 / 30件 ・ Pro（買い切り）で無制限に', { size: 12, fill: C.accentDark }) +
    icon('chevron', 349, y + 20, 18, C.accent);
}
function historyA() {
  let y = 334;
  return historyTop() + historyBanner(242) +
    t(32, y - 8, '今日', { size: 13, weight: 600, fill: C.secondary }) +
    `<g filter="url(#shadow)">${rect(16, y, 361, 192, { rx: 14, fill: C.card })}</g>` +
    `<clipPath id="hc1"><rect x="16" y="${y}" width="361" height="192" rx="14"/></clipPath><g clip-path="url(#hc1)">` +
    histRow(y, 'url', 'link', 'https://www.example.co.jp/c…', 'URL · QRコード · 08:12', true) +
    histRow(y + 64, 'wifi', 'wifi', 'Seijitsu-Cafe_5G', 'Wi-Fi · QRコード · 08:05', false) +
    histRow(y + 128, 'text', 'barcode', '4901234567894', 'テキスト · EAN-13 · 07:58', false, true) + '</g>' +
    t(32, y + 222, '昨日', { size: 13, weight: 600, fill: C.secondary }) +
    `<g filter="url(#shadow)">${rect(16, y + 230, 361, 192, { rx: 14, fill: C.card })}</g>` +
    `<clipPath id="hc2"><rect x="16" y="${y + 230}" width="361" height="192" rx="14"/></clipPath><g clip-path="url(#hc2)">` +
    histRow(y + 230, 'contact', 'person', '山田 太郎（誠実商事）', '連絡先 · 作成 · 18:21', true) +
    histRow(y + 294, 'phone', 'phone', '03-1234-5678', '電話 · QRコード · 12:40', false, false, 148) +
    histRow(y + 358, 'geo', 'pin', '35.68124, 139.76712', '地図座標 · QRコード · 09:03', false, true) + '</g>' +
    tabBar(1, false);
}
function historyB() {
  let y = 334;
  const list = historyTop() + historyBanner(242) +
    t(32, y - 8, '今日', { size: 13, weight: 600, fill: C.secondary }) +
    rect(16, y, 361, 192, { rx: 14, fill: C.card }) +
    histRow(y, 'url', 'link', 'https://www.example.co.jp/c…', 'URL · QRコード · 08:12', true) +
    histRow(y + 64, 'wifi', 'wifi', 'Seijitsu-Cafe_5G', 'Wi-Fi · QRコード · 08:05', false) +
    histRow(y + 128, 'text', 'barcode', '4901234567894', 'テキスト · EAN-13 · 07:58', false, true) +
    tabBar(1, false);
  return list + rect(0, 0, 393, 852, { fill: 'rgba(0,0,0,0.35)' }) +
    `<g filter="url(#shadowLg)">${rect(8, 552, 377, 156, { rx: 14, fill: C.sheetGroup })}</g>` +
    t(196.5, 584, '履歴をすべて削除しますか？', { size: 14, weight: 700, fill: C.secondary, anchor: 'middle' }) +
    t(196.5, 606, 'お気に入りを含む28件が削除されます。取り消せません。', { size: 13, fill: C.secondary, anchor: 'middle' }) +
    `<line x1="8" y1="626" x2="385" y2="626" stroke="${C.separator}"/>` +
    t(196.5, 674, 'すべて削除', { size: 20, weight: 600, fill: C.red, anchor: 'middle' }) +
    `<g filter="url(#shadowLg)">${rect(8, 718, 377, 58, { rx: 14, fill: C.sheet })}</g>` +
    t(196.5, 754, 'キャンセル', { size: 20, weight: 700, fill: C.accent, anchor: 'middle' }) +
    L.homeIndicator(false);
}

// ---------- 04 Create ----------
function createCard(x, y, w, kind, ic, title, sub, locked) {
  return `<g filter="url(#shadow)">${rect(x, y, w, 128, { rx: 18, fill: C.card })}</g>` +
    tile(x + 16, y + 16, 44, locked ? C.lockedTile : C.kind[kind], ic, 11) +
    (locked ? rect(x + w - 66, y + 16, 52, 24, { rx: 12, fill: C.accentSoft }) + iconLabel(x + w - 40, y + 33, 'lock', 13, 'Pro', { size: 13, weight: 800, fill: C.accent, gap: 3 }) :
      rect(x + w - 62, y + 16, 48, 24, { rx: 12, fill: C.neutralFill }) + t(x + w - 38, y + 33, '無料', { size: 12, weight: 700, fill: C.secondary, anchor: 'middle' })) +
    t(x + 16, y + 92, title, { size: 18, weight: 800, fill: locked ? C.secondary : C.label }) +
    t(x + 16, y + 113, sub, { size: 12, fill: C.secondary });
}
function createA() {
  const w = 172.5;
  return navLarge('作成') +
    t(16, 158, '作成したQRコードは履歴にも保存されます', { size: 14, fill: C.secondary }) +
    createCard(16, 180, w, 'text', 'text', 'テキスト', '自由な文字列', false) +
    createCard(204.5, 180, w, 'url', 'link', 'URL', 'Webページへのリンク', false) +
    createCard(16, 324, w, 'wifi', 'wifi', 'Wi-Fi', 'SSID・パスワード', true) +
    createCard(204.5, 324, w, 'contact', 'person', '連絡先', '名前・電話・メール', true) +
    createCard(16, 468, w, 'event', 'calendar', 'イベント', '予定の日時・場所', true) +
    rect(16, 620, 361, 72, { rx: 14, fill: C.accentSoft }) +
    icon('lockOpen', 30, 644, 24, C.accent) +
    t(66, 648, 'Wi-Fi・連絡先・イベントは Pro で作成できます', { size: 13, weight: 700, fill: C.accentDark }) +
    t(66, 670, '買い切り ¥800 ・ 毎月/毎週の支払いはありません', { size: 12, fill: C.accentDark }) +
    tabBar(2, false);
}
function createB() {
  return rect(0, 0, 393, 852, { fill: C.bg }) + statusBar(false) +
    glassCircle(38, 82, 22, 'chevronLeft', false) +
    t(196.5, 88, 'URL', { size: 17, weight: 700, anchor: 'middle' }) +
    t(32, 128, 'URL', { size: 13, weight: 600, fill: C.secondary }) +
    rect(16, 136, 361, 48, { rx: 12, fill: C.card }) + t(32, 166, 'https://www.example.co.jp', { size: 16, mono: true }) +
    `<g filter="url(#shadow)">${rect(16, 200, 361, 352, { rx: 18, fill: C.card })}</g>` +
    rect(64.5, 214, 264, 264, { rx: 12, fill: '#FFFFFF' }) + fakeQR(76.5, 226, 240, 29, '#000', 3) +
    t(196.5, 498, 'https://www.example.co.jp', { size: 13, mono: true, fill: C.secondary, anchor: 'middle' }) +
    iconLabel(196.5, 528, 'checkCircle', 16, '履歴に保存しました', { size: 13, fill: C.secondary, iconColor: C.green, gap: 6 }) +
    rect(16, 568, 361, 54, { rx: 14, fill: C.accentFill }) + iconLabel(196.5, 602, 'download', 22, '写真に保存', { size: 17, weight: 700, fill: '#fff' }) +
    rect(16, 634, 361, 54, { rx: 14, fill: C.card, stroke: C.separator }) + iconLabel(196.5, 668, 'share', 22, '共有', { size: 17, weight: 700, fill: C.accent }) +
    tabBar(2, false);
}

// ---------- 05 Paywall ----------
function feature(y, ic, title, sub) {
  return `<circle cx="44" cy="${y + 20}" r="20" fill="${C.accentSoft}"/>` + icon(ic, 32, y + 8, 24, C.accent) +
    t(76, y + 15, title, { size: 16, weight: 700 }) + t(76, y + 36, sub, { size: 13, fill: C.secondary });
}
function paywall(purchased) {
  const Y = 58;
  let s = rect(0, 0, 393, 852, { fill: '#000' }) + `<path d="M0 ${Y + 12}a12 12 0 0 1 12-12H381a12 12 0 0 1 12 12V852H0Z" fill="${C.sheet}"/>` +
    statusBar(true) + rect(178.5, Y + 6, 36, 5, { rx: 2.5, fill: C.grabber }) +
    glassCircle(38, Y + 38, 20, 'xmark', false) +
    tile(160.5, Y + 52, 72, C.accentFill, 'qr', 17) +
    t(196.5, Y + 160, '誠実QRリーダー Pro', { size: 26, weight: 800, anchor: 'middle' }) +
    t(196.5, Y + 186, '一回払いで、ずっと使えます', { size: 15, fill: C.secondary, anchor: 'middle' }) +
    rect(16, Y + 206, 361, 112, { rx: 16, fill: C.accentSoft, stroke: C.accent, sw: 1.5 }) +
    icon('checkCircle', 32, Y + 224, 24, C.accent) +
    t(66, Y + 236, 'これは買い切りです。', { size: 16, weight: 800, fill: C.accentDark }) +
    t(66, Y + 258, '毎月・毎週の支払いは発生しません', { size: 16, weight: 800, fill: C.accentDark }) +
    icon('checkCircle', 32, Y + 278, 24, C.accent) +
    t(66, Y + 296, '広告は今後も入れません', { size: 16, weight: 800, fill: C.accentDark }) +
    t(16, Y + 350, 'Proで使えるようになる機能', { size: 13, weight: 700, fill: C.secondary }) +
    feature(Y + 362, 'infinity', '履歴を無制限に保存', '無料版は直近30件まで') +
    feature(Y + 414, 'qr', 'すべての種類のQRコードを作成', 'Wi-Fi・連絡先・イベントにも対応') +
    feature(Y + 466, 'docText', '履歴のCSVエクスポート', '表計算アプリで開ける形式で書き出し') +
    t(196.5, Y + 540, 'スキャンは無料版でも回数無制限です。', { size: 13, fill: C.secondary, anchor: 'middle' }) +
    t(196.5, Y + 568, 'お支払いはAppleアカウントに1回だけ請求されます。', { size: 12, fill: C.secondary, anchor: 'middle' }) +
    t(196.5, Y + 586, '同じAppleアカウントのiPhone・iPadで復元できます。', { size: 12, fill: C.secondary, anchor: 'middle' }) +
    t(196.5, Y + 614, '利用規約 ・ プライバシーポリシー', { size: 12, weight: 600, fill: C.accent, anchor: 'middle' });
  // Pinned purchase area (stays at the bottom while the content scrolls).
  const B = 690;
  s += rect(0, B, 393, 852 - B, { fill: C.sheet }) + `<line x1="0" y1="${B}" x2="393" y2="${B}" stroke="${C.separator}"/>`;
  if (purchased) {
    s += rect(16, B + 12, 361, 56, { rx: 14, fill: C.neutralFill }) + iconLabel(196.5, B + 47, 'checkCircle', 24, '購入済みです', { size: 17, weight: 700, fill: C.accentDark, iconColor: C.accent });
  } else {
    s += rect(16, B + 12, 361, 56, { rx: 14, fill: C.accentFill }) +
      t(196.5, B + 47, '¥800 で購入（買い切り）', { size: 18, weight: 800, fill: '#fff', anchor: 'middle' });
  }
  s += t(196.5, B + 104, '購入を復元', { size: 16, weight: 600, fill: C.accent, anchor: 'middle' }) +
    L.homeIndicator(false);
  return s;
}

// ---------- 06 Settings ----------
function group(y, h) { return rect(16, y, 361, h, { rx: 12, fill: C.card }); }
function sep(y, x = 32) { return `<line x1="${x}" y1="${y}" x2="377" y2="${y}" stroke="${C.separator}"/>`; }
function secHead(y, s) { return t(32, y, s, { size: 13, fill: C.secondary }); }
function settings(purchased) {
  let s = navLarge('設定');
  s += secHead(164, 'PRO（買い切り）') + group(172, 116) +
    tile(32, 184, 40, C.accentFill, 'qr', 10) +
    t(84, 201, '誠実QRリーダー Pro', { size: 16, weight: 700 }) +
    t(84, 221, purchased ? '購入済み ・ ありがとうございます' : '未購入 ・ 買い切り ¥800', { size: 13, fill: C.secondary }) +
    (purchased ? icon('checkCircle', 341, 192, 24, C.accent) : rect(301, 191, 62, 30, { rx: 15, fill: C.accentFill }) + t(332, 211, '購入', { size: 14, weight: 700, fill: '#fff', anchor: 'middle' })) +
    sep(236) + t(32, 268, '購入を復元', { size: 16, fill: C.accent }) +
    t(32, 308, 'サブスクリプションではありません。毎月・毎週の支払いは', { size: 12, fill: C.secondary }) +
    t(32, 324, '発生しません。広告も表示しません。', { size: 12, fill: C.secondary });
  s += secHead(362, 'スキャン') + group(370, 102) +
    t(32, 405, '読み取り時の音', { size: 16 }) + toggle(310, 385, true) + sep(421) +
    t(32, 456, '読み取り時の振動', { size: 16 }) + toggle(310, 436, true);
  s += secHead(508, '履歴') + group(516, 51) +
    t(32, 548, '履歴を自動保存', { size: 16 }) + toggle(310, 526, true) +
    t(32, 588, 'オフにすると、スキャン・作成した内容を保存しません。', { size: 12, fill: C.secondary });
  s += secHead(624, 'このアプリについて') + group(632, 132) +
    t(32, 664, 'プライバシーポリシー', { size: 16 }) + icon('external', 349, 650, 18, C.tertiary) + sep(676) +
    t(32, 708, '利用規約', { size: 16 }) + icon('external', 349, 694, 18, C.tertiary) + sep(720) +
    t(32, 752, 'バージョン', { size: 16 }) + t(361, 752, '1.0.0', { size: 16, fill: C.secondary, anchor: 'end' });
  return s + tabBar(3, false);
}

// ---------- Write ----------
module.exports = { scanControls, privacyPill, sheetClose, resultPinned, pinnedBar, scanA, scanB, scanC, resultURL, resultWiFi, historyA, historyB, createA, createB, paywall, settings, navLarge, histRow, chips, sheetBackdrop, sheetTop, actionTriple, fitSize, pillNote, group, sep, secHead, feature, cameraFeed };
if (require.main !== module) return;
function write(name, title, sub, screens) {
  const w = canvasW(screens.length);
  const body = header(title, sub) + screens.map(([inner, cap], i) => phone(px(i), OY, inner, cap)).join('\n');
  fs.writeFileSync(path.join(OUT, name), doc(w, CANVAS_H, body, title));
}

write('01_scan.svg', '01 スキャン', '起動直後に表示（オンボーディング・演出なし）。写真・連続スキャン・ライトは親指の届く画面下部に配置。', [
  [scanA(), 'A. 通常スキャン'], [scanB(), 'B. 連続スキャン ON（トーチ点灯中）'], [scanC(), 'C. カメラ未許可']]);
write('02_result.svg', '02 結果表示（シート）', 'URLは全文を省略せず表示。閉じる×は左上、主な操作は下部に固定。シート表示中もカメラは動かしたまま、読み取りだけ止める（閉じてすぐ読める）。', [
  [resultURL(), 'A. URL'], [resultWiFi(), 'B. Wi-Fi']]);
write('03_history.svg', '03 履歴', '検索（日時・種類・内容）、種類フィルタ、お気に入り、スワイプ削除、全件削除、CSV。', [
  [historyA(), 'A. 一覧（無料版バナー・スワイプ操作）'], [historyB(), 'B. 全件削除の確認']]);
write('04_create.svg', '04 QR作成', '無料: テキスト・URL ／ Pro: Wi-Fi・連絡先・イベント。「作成」実行時に履歴へ保存。', [
  [createA(), 'A. 作成メニュー（無料版）'], [createB(), 'B. 生成結果']]);
write('05_paywall.svg', '05 課金（Pro 買い切り）', 'ユーザー操作でのみ表示。価格はdisplayPriceをそのまま表示。購入・復元は下部に固定。', [
  [paywall(false), 'A. 未購入'], [paywall(true), 'B. 購入済み']]);
write('06_settings.svg', '06 設定', '購入／復元、音・振動、履歴の自動保存、規約リンク（URLは定数ファイル）。', [
  [settings(false), 'A. 未購入'], [settings(true), 'B. 購入済み']]);
console.log('ok');
