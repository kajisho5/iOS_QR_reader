// 1.1 design proposal mockups: node v11.js ..
// 15 QR を再表示 / 16 URL の注意表示 / 17 ウィジェット / 18 すぐ読める入口・共有シートから読む
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

function header(title, sub, sub2) {
  return t(PAD - 13, 48, title, { size: 26, weight: 800, fill: C.label }) +
    (sub ? t(PAD - 13, 76, sub, { size: 15, fill: C.secondary }) : '') +
    (sub2 ? t(PAD - 13, 98, sub2, { size: 15, fill: C.secondary }) : '');
}
function write(name, title, sub, sub2, screens) {
  const w = canvasW(screens.length);
  const body = header(title, sub, sub2) + screens.map(([inner, cap], i) => phone(px(i), OY, inner, cap)).join('\n');
  fs.writeFileSync(path.join(OUT, name), doc(w, CANVAS_H, body, title));
}

// Four equal tiles in the pinned area of a result sheet (1.0 has three).
function actionQuad(y, items) {
  const w = (361 - 24) / 4;
  return items.map(([ic, label, col, isNew], i) => {
    const x = 16 + i * (w + 8);
    return rect(x, y, w, 66, { rx: 14, fill: C.card, stroke: isNew ? C.accent : null, sw: 1.5 }) +
      icon(ic, x + w / 2 - 12, y + 11, 24, col || C.accent, ic === 'star') +
      t(x + w / 2, y + 54, label, { size: S.fitSize(label, 12, w - 10, 600), weight: 600, fill: col ? C.label : C.accent, anchor: 'middle' });
  }).join('');
}
function resultPinnedQuad(ic, label, tiles) {
  const Y = 676;
  return S.pinnedBar(Y, 852 - Y) +
    rect(16, Y + 12, 361, 54, { rx: 14, fill: C.accentFill }) + iconLabel(196.5, Y + 46, ic, 22, label, { size: 17, weight: 700, fill: '#fff' }) +
    actionQuad(Y + 76, tiles);
}
function resultHead(y, kind, ic, title, meta) {
  return tile(16, y, 48, C.kind[kind], ic, 12) + t(76, y + 21, title, { size: 22, weight: 800 }) + t(76, y + 42, meta, { size: 13, fill: C.secondary });
}
function newBadge(x, y) {
  return rect(x, y, 40, 20, { rx: 10, fill: C.accentFill }) + t(x + 20, y + 14, 'NEW', { size: 11, weight: 800, fill: '#fff', anchor: 'middle' });
}

// ---------- 15 QR を再表示 ----------
function a1() {
  const Y = 236, H = Y + 46;
  return S.sheetBackdrop() + S.sheetTop(Y) + S.sheetClose(Y + 30) +
    resultHead(H + 10, 'wifi', 'wifi', 'Wi-Fi', 'QRコード · 2026/11/06 08:05') +
    rect(16, H + 74, 361, 134, { rx: 14, fill: C.card }) +
    t(32, H + 106, 'ネットワーク名', { size: 15, fill: C.secondary }) + t(361, H + 106, 'Seijitsu-Cafe_5G', { size: 15, weight: 700, anchor: 'end' }) + line(32, H + 122, 377, H + 122) +
    t(32, H + 150, 'セキュリティ', { size: 15, fill: C.secondary }) + t(361, H + 150, 'WPA/WPA2/WPA3', { size: 15, weight: 700, anchor: 'end' }) + line(32, H + 166, 377, H + 166) +
    t(32, H + 194, 'パスワード', { size: 15, fill: C.secondary }) + t(327, H + 194, '••••••••••', { size: 15, weight: 700, anchor: 'end' }) + icon('eye', 339, H + 180, 22, C.accent) +
    iconLabel(196.5, H + 246, 'checkCircle', 16, '履歴に保存しました', { size: 13, fill: C.secondary, iconColor: C.green, gap: 6 }) +
    resultPinnedQuad('wifi', 'このWi-Fiに接続', [['qr', 'QRを表示', null, true], ['copy', 'コピー'], ['share', '共有'], ['star', 'お気に入り', C.yellow]]) +
    newBadge(16 + 84.25 / 2 - 20, 676 + 64) +
    L.homeIndicator(false);
}
function a2() {
  // Full screen, white in both appearances so any scanner can read it; brightness raised while shown.
  return rect(0, 0, 393, 852, { fill: '#FFFFFF' }) + statusBar(false) +
    glassCircle(38, 82, 20, 'xmark', false) +
    t(196.5, 88, 'Seijitsu-Cafe_5G', { size: 17, weight: 700, anchor: 'middle', fill: '#1C1C1E' }) +
    t(196.5, 108, 'Wi-Fi', { size: 13, anchor: 'middle', fill: '#6B6B70' }) +
    rect(36.5, 168, 320, 320, { rx: 16, fill: '#FFFFFF', stroke: '#E5E5EA' }) + fakeQR(56.5, 188, 280, 33, '#000', 5) +
    S.pillNote(530, 'bolt', '表示中は画面を最大の明るさにしています', { size: 12, weight: 600, fill: '#0A5F4E', iconColor: '#0E7C66' }, '#E3F2EE', 32) +
    t(196.5, 578, '読み取った内容から作り直したQRコードです。', { size: 13, fill: '#6B6B70', anchor: 'middle' }) +
    t(196.5, 598, '模様が元と違うことがありますが、読み取ると同じ内容です。', { size: 13, fill: '#6B6B70', anchor: 'middle' }) +
    rect(16, 676, 361, 54, { rx: 14, fill: '#0E7C66' }) + iconLabel(196.5, 710, 'download', 22, '写真に保存', { size: 17, weight: 700, fill: '#fff' }) +
    rect(16, 742, 361, 54, { rx: 14, fill: '#FFFFFF', stroke: '#E5E5EA' }) + iconLabel(196.5, 776, 'share', 22, '画像を共有', { size: 17, weight: 700, fill: '#0E7C66' }) +
    rect(129.5, 838, 134, 5, { rx: 2.5, fill: '#000' });
}
function a3() {
  // History detail: the code itself is shown at the top; tap to enlarge (= a2).
  let s = rect(0, 0, 393, 852, { fill: C.bg }) + statusBar(false) +
    glassCircle(38, 82, 22, 'chevronLeft', false) + t(196.5, 88, '履歴', { size: 17, weight: 700, anchor: 'middle' }) +
    glassCircle(355, 82, 22, 'star', false);
  s += `<g filter="url(#shadow)">${rect(16, 124, 361, 268, { rx: 18, fill: C.card })}</g>` +
    rect(96.5, 140, 200, 200, { rx: 10, fill: '#FFFFFF', stroke: C.separator }) + fakeQR(108.5, 152, 176, 29, '#000', 9) +
    iconLabel(196.5, 372, 'search', 16, 'タップで大きく表示', { size: 13, weight: 600, fill: C.accent, gap: 6 });
  s += resultHead(412, 'url', 'link', 'URL', 'QRコード · 2026/11/06 08:12') +
    rect(16, 476, 361, 128, { rx: 14, fill: C.card }) +
    t(32, 502, 'リンク先（全文・省略なし）', { size: 13, weight: 600, fill: C.secondary }) +
    t(32, 530, [{ s: 'https://' }, { s: 'www.example.co.jp', weight: 800 }, { s: '/menu' }], { size: 15, mono: true }) +
    line(32, 550, 361, 550) + t(32, 580, 'ドメイン', { size: 15, fill: C.secondary }) + t(361, 580, 'www.example.co.jp', { size: 15, weight: 700, anchor: 'end' }) +
    rect(16, 620, 361, 54, { rx: 14, fill: C.accentFill }) + iconLabel(196.5, 654, 'external', 22, 'ブラウザで開く', { size: 17, weight: 700, fill: '#fff' });
  return s + tabBar(1, false);
}
function a4() {
  // A symbology iOS cannot draw (JAN/EAN): say so instead of showing a wrong image.
  const Y = 236, H = Y + 46;
  return S.sheetBackdrop() + S.sheetTop(Y) + S.sheetClose(Y + 30) +
    resultHead(H + 10, 'text', 'qr', 'テキスト', 'Data Matrix · 2026/11/06 07:58') +
    rect(16, H + 74, 361, 70, { rx: 14, fill: C.card }) + t(32, H + 116, 'LOT-20261106-0042', { size: 20, weight: 700, mono: true }) +
    rect(16, H + 158, 361, 70, { rx: 14, fill: C.neutralFill }) + icon('info', 30, H + 172, 20, C.secondary) +
    t(60, H + 186, 'この種類のコード（Data Matrix）は、', { size: 13, fill: C.secondary }) +
    t(60, H + 206, '画像として表示できません。', { size: 13, fill: C.secondary }) +
    S.resultPinned('copy', 'コピー', [['qr', '表示できません', C.tertiary], ['share', '共有'], ['star', 'お気に入り', C.yellow]]) +
    L.homeIndicator(false);
}

// ---------- 16 URL の注意表示 ----------
function warnCard(y, level, title, lines) {
  const bg = level === 'high' ? '#FDECEA' : '#FFF4D6', fg = level === 'high' ? C.red : '#8A5A00';
  const h = 50 + lines.length * 20;
  return rect(16, y, 361, h, { rx: 14, fill: bg }) + icon('info', 30, y + 14, 22, fg) +
    t(62, y + 31, title, { size: 15, weight: 800, fill: fg }) +
    lines.map((l, i) => t(62, y + 54 + i * 20, l, { size: 13, fill: '#3A3A3C' })).join('');
}
function urlSheet(meta, warn, urlParts, domain, scheme) {
  const Y = 196, H = Y + 46;
  return S.sheetBackdrop() + S.sheetTop(Y) + S.sheetClose(Y + 30) +
    resultHead(H + 10, 'url', 'link', 'URL', meta) + warn(H + 74) +
    rect(16, H + 210, 361, 158, { rx: 14, fill: C.card }) +
    t(32, H + 236, 'リンク先（全文・省略なし）', { size: 13, weight: 600, fill: C.secondary }) +
    t(32, H + 264, urlParts, { size: 15, mono: true }) + line(32, H + 284, 361, H + 284) +
    t(32, H + 310, 'ドメイン', { size: 15, fill: C.secondary }) + t(361, H + 310, domain, { size: 15, weight: 700, anchor: 'end', mono: true }) + line(32, H + 326, 361, H + 326) +
    t(32, H + 352, '方式', { size: 15, fill: C.secondary }) + t(361, H + 352, scheme, { size: 15, weight: 600, anchor: 'end' }) +
    S.resultPinned('external', 'ブラウザで開く', [['copy', 'コピー'], ['share', '共有'], ['star', 'お気に入り', C.yellow]]) +
    L.homeIndicator(false);
}
function c1() {
  return urlSheet('QRコード · 2026/11/06 08:12',
    y => warnCard(y, 'mid', '短縮URLです', ['本当の行き先は、開くまで分かりません。', 'このアプリは通信しないため、確認もしません。', '心当たりがなければ開かないでください。']),
    [{ s: 'https://' }, { s: 'bit.ly', weight: 800 }, { s: '/3xAbCdE' }], 'bit.ly', 'https（暗号化）');
}
function c2() {
  return urlSheet('QRコード · 2026/11/06 08:20',
    y => warnCard(y, 'high', '見た目の似た別の文字が入っています', ['「аpple.com」の「а」はラテン文字ではなく', 'キリル文字です。本物とは別のサイトです。', '実際のドメイン：xn--pple-43d.com']),
    [{ s: 'https://' }, { s: 'аpple.com', weight: 800 }, { s: '/login' }], 'xn--pple-43d.com', 'https（暗号化）');
}
function c3() {
  const base = urlSheet('QRコード · 2026/11/06 08:31',
    y => warnCard(y, 'mid', '暗号化されていない接続（http）です', ['入力した内容が途中で見られる可能性が', 'あります。パスワードなどは入れないでください。']),
    [{ s: 'http://' }, { s: '192.168.0.10', weight: 800 }, { s: ':8080/admin' }], '192.168.0.10', 'http（暗号化なし）');
  return base + rect(0, 0, 393, 852, { fill: 'rgba(0,0,0,0.35)' }) +
    `<g filter="url(#shadowLg)">${rect(8, 560, 377, 152, { rx: 14, fill: C.sheetGroup })}</g>` +
    t(196.5, 590, '注意があるURLです', { size: 14, weight: 700, fill: C.secondary, anchor: 'middle' }) +
    t(196.5, 612, '暗号化なし ・ IPアドレスを直接指定', { size: 13, fill: C.secondary, anchor: 'middle' }) +
    line(8, 630, 385, 630) + t(196.5, 676, 'このまま開く', { size: 20, weight: 600, fill: C.red, anchor: 'middle' }) +
    `<g filter="url(#shadowLg)">${rect(8, 722, 377, 58, { rx: 14, fill: C.sheet })}</g>` +
    t(196.5, 758, '開かない', { size: 20, weight: 700, fill: C.accent, anchor: 'middle' }) + L.homeIndicator(false);
}

// ---------- 17 ウィジェット ----------
function homeBg() {
  let s = `<defs><linearGradient id="wall" x1="0" y1="0" x2="0.4" y2="1"><stop offset="0" stop-color="#2F6F63"/><stop offset="1" stop-color="#16302B"/></linearGradient></defs>` +
    rect(0, 0, 393, 852, { fill: 'url(#wall)' }) + statusBar(true);
  return s;
}
function appIcons(y, n, palette) {
  let s = '';
  for (let i = 0; i < n; i++) {
    const x = 27 + (i % 4) * 92, yy = y + Math.floor(i / 4) * 102;
    s += rect(x, yy, 64, 64, { rx: 15, fill: palette[i % palette.length], opacity: '0.85' }) + rect(x + 8, yy + 74, 48, 8, { rx: 4, fill: 'rgba(255,255,255,0.55)' });
  }
  return s;
}
function widgetSmall(x, y, title, locked) {
  let s = `<g filter="url(#shadowLg)">${rect(x, y, 158, 158, { rx: 24, fill: '#FFFFFF' })}</g>`;
  if (locked) {
    s += tile(x + 55, y + 30, 48, C.accentFill, 'qr', 12) + t(x + 79, y + 108, 'Pro で使えます', { size: 13, weight: 700, fill: '#0A5F4E', anchor: 'middle' }) +
      t(x + 79, y + 128, 'タップして詳細', { size: 11, fill: '#6B6B70', anchor: 'middle' });
  } else {
    s += fakeQR(x + 24, y + 14, 110, 29, '#000', 21) + t(x + 79, y + 144, title, { size: 12, weight: 700, fill: '#1C1C1E', anchor: 'middle' });
  }
  return s;
}
function widgetMedium(x, y) {
  return `<g filter="url(#shadowLg)">${rect(x, y, 338, 158, { rx: 24, fill: '#FFFFFF' })}</g>` +
    fakeQR(x + 16, y + 16, 126, 29, '#000', 13) +
    tile(x + 160, y + 20, 32, C.kind.contact, 'person', 8) +
    t(x + 160, y + 80, '会員証（誠実書店）', { size: 15, weight: 800, fill: '#1C1C1E' }) +
    t(x + 160, y + 100, 'No. 0012-3456-7890', { size: 12, fill: '#6B6B70', mono: true }) +
    t(x + 160, y + 136, '誠実QRリーダー', { size: 11, weight: 600, fill: '#0E7C66' });
}
function b1() {
  return homeBg() + widgetSmall(27, 72, 'お店のWi-Fi') + widgetSmall(208, 72, '会員証（誠実書店）') +
    widgetMedium(27, 252) + appIcons(440, 12, ['#5B8DEF', '#F2A33A', '#E35D6A', '#7C6CE0', '#3BB273', '#8E959E']) +
    rect(16, 760, 361, 74, { rx: 30, fill: 'rgba(255,255,255,0.25)' }) +
    [0, 1, 2, 3].map(i => rect(37 + i * 88, 769, 56, 56, { rx: 14, fill: ['#3BB273', '#5B8DEF', '#0E7C66', '#F2A33A'][i] })).join('') +
    L.homeIndicator(true);
}
function b2() {
  // Choosing what the widget shows (App Intent configuration): favorites only.
  let s = homeBg() + rect(0, 0, 393, 852, { fill: 'rgba(0,0,0,0.45)' }) + widgetSmall(117.5, 96, 'お店のWi-Fi');
  s += `<g filter="url(#shadowLg)">${rect(16, 300, 361, 420, { rx: 28, fill: C.sheet })}</g>` +
    t(196.5, 342, 'ウィジェットに表示するQR', { size: 17, weight: 800, anchor: 'middle' }) +
    t(196.5, 364, 'お気に入りから選びます', { size: 13, fill: C.secondary, anchor: 'middle' });
  const rows = [['wifi', 'wifi', 'お店のWi-Fi', 'Wi-Fi · お気に入り', true], ['contact', 'person', '会員証（誠実書店）', 'テキスト · お気に入り'], ['url', 'link', 'https://www.example.co.jp/…', 'URL · お気に入り'], ['event', 'calendar', '町内会の集まり', 'イベント · お気に入り']];
  rows.forEach(([k, ic, ti, me, on], i) => {
    const y = 384 + i * 70;
    s += tile(36, y + 12, 36, C.kind[k], ic, 9) + t(84, y + 28, ti, { size: 15, weight: 600 }) + t(84, y + 47, me, { size: 12, fill: C.secondary }) +
      (on ? icon('check', 337, y + 18, 22, C.accent) : '') + (i < 3 ? line(84, y + 66, 357, y + 66) : '');
  });
  return s + L.homeIndicator(true);
}
function b3() {
  // Without Pro the widget can still be placed; it explains itself and opens the purchase screen.
  return homeBg() + widgetSmall(27, 72, '', true) +
    S.pillNote(300, 'info', 'タップで購入画面（買い切り ¥800）を開きます', { size: 12, weight: 600, fill: '#fff', iconColor: C.accentOnDark }, 'rgba(0,0,0,0.45)', 32) +
    appIcons(360, 12, ['#5B8DEF', '#F2A33A', '#E35D6A', '#7C6CE0', '#3BB273', '#8E959E']) +
    rect(16, 760, 361, 74, { rx: 30, fill: 'rgba(255,255,255,0.25)' }) + L.homeIndicator(true);
}

// ---------- 18 すぐ読める入口・共有シートから読む ----------
function ccButton(x, y, w, h, ic, label, on, isNew) {
  return rect(x, y, w, h, { rx: Math.min(w, h) / 2 > 30 ? 30 : Math.min(w, h) / 2, fill: on ? '#FFFFFF' : 'rgba(255,255,255,0.18)', stroke: isNew ? C.accentOnDark : null, sw: 2 }) +
    icon(ic, x + w / 2 - 14, y + h / 2 - (label ? 22 : 14), 28, on ? '#1C1C1E' : '#fff') +
    (label ? t(x + w / 2, y + h / 2 + 26, label, { size: 11, weight: 600, fill: on ? '#1C1C1E' : '#fff', anchor: 'middle' }) : '');
}
function d1() {
  let s = homeBg() + rect(0, 0, 393, 852, { fill: 'rgba(10,20,18,0.72)' }) + `<g filter="url(#blur6)" opacity=".3">${appIcons(120, 16, ['#5B8DEF', '#F2A33A'])}</g>`;
  s += rect(24, 120, 166, 166, { rx: 34, fill: 'rgba(255,255,255,0.18)' }) +
    [0, 1, 2, 3].map(i => `<circle cx="${68 + (i % 2) * 78}" cy="${164 + Math.floor(i / 2) * 78}" r="26" fill="${i === 0 ? '#F2A33A' : i === 1 ? '#5B8DEF' : 'rgba(255,255,255,0.25)'}"/>`).join('') +
    rect(203, 120, 166, 166, { rx: 34, fill: 'rgba(255,255,255,0.18)' }) + t(286, 210, '再生していません', { size: 13, fill: 'rgba(255,255,255,0.7)', anchor: 'middle' }) +
    ccButton(24, 300, 77, 77, 'bolt', '', false) + ccButton(113, 300, 77, 77, 'clock', '', false) +
    ccButton(203, 300, 166, 77, 'viewfinder', 'QRスキャン', true, true) +
    t(286, 400, '誠実QRリーダー', { size: 11, weight: 600, fill: C.accentOnDark, anchor: 'middle' }) +
    rect(24, 420, 77, 166, { rx: 30, fill: 'rgba(255,255,255,0.18)' }) + rect(113, 420, 77, 166, { rx: 30, fill: 'rgba(255,255,255,0.18)' }) +
    S.pillNote(640, 'info', 'タップでアプリが開き、すぐにスキャンが始まります', { size: 12, weight: 600, fill: '#fff', iconColor: C.accentOnDark }, 'rgba(0,0,0,0.45)', 32);
  return s + L.homeIndicator(true);
}
function d2() {
  // Lock screen: the bottom-left control replaced by "QRスキャン"; also usable from the Action button.
  let s = homeBg() +
    t(196.5, 150, '11月6日 木曜日', { size: 18, weight: 600, fill: 'rgba(255,255,255,0.85)', anchor: 'middle' }) +
    t(196.5, 250, '9:41', { size: 96, weight: 700, fill: '#fff', anchor: 'middle' }) +
    `<circle cx="72" cy="760" r="26" fill="rgba(0,0,0,0.35)" stroke="${C.accentOnDark}" stroke-width="2"/>` + icon('viewfinder', 58, 746, 28, '#fff') +
    `<circle cx="321" cy="760" r="26" fill="rgba(0,0,0,0.35)"/>` + icon('photo', 307, 746, 28, '#fff') +
    t(72, 806, 'QRスキャン', { size: 11, weight: 700, fill: '#fff', anchor: 'middle' }) +
    S.pillNote(560, 'info', 'ロック画面・アクションボタンにも置けます（iOS 18 以降）', { size: 12, weight: 600, fill: '#fff', iconColor: C.accentOnDark }, 'rgba(0,0,0,0.45)', 32);
  return s + L.homeIndicator(true);
}
function e1() {
  // Photos share sheet: the app's Share Extension reads codes in the image without leaving Photos.
  let s = rect(0, 0, 393, 852, { fill: '#000' }) + statusBar(true) +
    rect(0, 100, 393, 420, { fill: '#2A2F2D' }) + `<g transform="translate(96 160)">${rect(0, 0, 200, 240, { rx: 6, fill: '#E9E6DD' })}${fakeQR(25, 30, 150, 29, '#1A1A1A', 17)}</g>`;
  s += `<path d="M0 470a14 14 0 0 1 14-14H379a14 14 0 0 1 14 14V852H0Z" fill="${C.sheet}"/>` + rect(178.5, 462, 36, 5, { rx: 2.5, fill: C.grabber }) +
    rect(24, 486, 40, 40, { rx: 8, fill: '#2A2F2D' }) + t(76, 503, '写真 1枚', { size: 15, weight: 700 }) + t(76, 521, 'IMG_0412.HEIC', { size: 12, fill: C.secondary });
  const apps = [['#3BB273', 'メッセージ'], ['#5B8DEF', 'メール'], [C.accentFill, '誠実QRで読む', true], ['#F2A33A', 'メモ']];
  apps.forEach(([c, l, me], i) => {
    const x = 28 + i * 88;
    s += (me ? tile(x, 548, 64, c, 'qr', 15) + rect(x - 3, 545, 70, 70, { rx: 17, stroke: C.accent, sw: 2 }) : rect(x, 548, 64, 64, { rx: 15, fill: c })) +
      t(x + 32, 634, l, { size: S.fitSize(l, 11, 84, 600), weight: me ? 700 : 500, anchor: 'middle', fill: me ? C.accent : C.label });
  });
  s += rect(16, 660, 361, 52, { rx: 12, fill: C.card }) + t(32, 692, 'コピー', { size: 16 }) + icon('copy', 341, 674, 22, C.label) +
    rect(16, 720, 361, 52, { rx: 12, fill: C.card }) + t(32, 752, '画像を保存', { size: 16 }) + icon('download', 341, 734, 22, C.label);
  return s + L.homeIndicator(false);
}
function e2() {
  // The extension's own sheet: result + actions. Saved to history when the app next opens.
  const Y = 160, H = Y + 46;
  let s = rect(0, 0, 393, 852, { fill: '#000' }) + statusBar(true) + rect(0, 100, 393, 300, { fill: '#2A2F2D', opacity: '0.6' }) +
    S.sheetTop(Y) + S.sheetClose(Y + 30) + t(196.5, Y + 36, '誠実QRリーダー', { size: 15, weight: 700, anchor: 'middle' }) +
    resultHead(H + 10, 'url', 'link', 'URL', 'QRコード · 写真から') +
    rect(16, H + 74, 361, 120, { rx: 14, fill: C.card }) +
    t(32, H + 100, 'リンク先（全文・省略なし）', { size: 13, weight: 600, fill: C.secondary }) +
    t(32, H + 128, [{ s: 'https://' }, { s: 'www.example.co.jp', weight: 800 }, { s: '/event' }], { size: 15, mono: true }) +
    line(32, H + 148, 361, H + 148) + t(32, H + 176, 'ドメイン', { size: 15, fill: C.secondary }) + t(361, H + 176, 'www.example.co.jp', { size: 15, weight: 700, anchor: 'end' }) +
    icon('info', 18, H + 212, 16, C.secondary) + t(40, H + 225, '履歴には、次にアプリを開いたときに保存します。', { size: 13, fill: C.secondary }) +
    S.resultPinned('external', 'ブラウザで開く', [['copy', 'コピー'], ['share', '共有'], ['qr', 'アプリで開く']]) +
    L.homeIndicator(false);
  return s;
}

write('15_show_code.svg', '15 読み取ったQRを再表示（1.1 案 A）', '結果シートと履歴の詳細に「QRを表示」。読み取った内容から作り直したQRを、白地・最大の明るさで全画面表示。保存・共有も。',
  'QR・Code128・PDF417・Aztec は iOS の機能で、JAN/EAN・UPC-E・Code39/93・ITF-14 は自前で描いて表示。Data Matrix など描けない種類は「表示できません」と正直に出す。', [
    [a1(), 'A1. 結果シート（「QRを表示」を追加）'], [a2(), 'A2. 全画面表示（白地・明るさ最大）'], [a3(), 'A3. 履歴の詳細（上にQR）'], [a4(), 'A4. 表示できない種類']]);
write('16_url_check.svg', '16 URLの注意表示（1.1 案 C）', 'URLを開く前に、端末内だけで確認して注意を出す（通信して行き先を調べることはしない）。注意があるURLは「ブラウザで開く」で確認を挟む。',
  '対象：短縮URL・見た目の似た文字（IDN／punycode）・http・IPアドレス直接・「@」でドメインを偽装したURL・標準でないポート。', [
    [c1(), 'C1. 短縮URL（注意）'], [c2(), 'C2. 似た文字のドメイン（警告）'], [c3(), 'C3. 注意があるURLを開くとき']]);
write('17_widget.svg', '17 ウィジェット（1.2 案 B・Pro）', 'お気に入りのQR（店のWi-Fi・会員証など）をホーム画面に表示。小・中サイズ。表示するQRはお気に入りから選ぶ。',
  'Pro の機能として提案。未購入でも置けるが、QRの代わりに「Pro で使えます」を表示し、タップで購入画面へ。', [
    [b1(), 'B1. ホーム画面（小・中）'], [b2(), 'B2. 表示するQRを選ぶ'], [b3(), 'B3. Pro 未購入のとき']]);
write('18_entry_points.svg', '18 すぐ読める入口・共有シートから読む（案 D・E）', 'D：コントロールセンター・ロック画面・アクションボタンに「QRスキャン」（iOS 18 以降。iOS 17 はショートカットアプリから）。',
  'E：写真・Safari などの共有シートから画像のQRを読む。アプリを開かずに結果を表示し、履歴には次にアプリを開いたとき保存。', [
    [d1(), 'D1. コントロールセンター'], [d2(), 'D2. ロック画面'], [e1(), 'E1. 写真の共有シート'], [e2(), 'E2. 共有シート内の結果']]);
console.log('ok');
