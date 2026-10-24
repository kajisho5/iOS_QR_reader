// Dark mode, empty / permission states, and the largest Dynamic Type size (AX5).
const fs = require('fs');
const path = require('path');
const L = require('./lib');
const S = require('./screens');
const { C, setTheme, t, measure, iconLabel, rect, icon, tile, statusBar, tabBar, phone, doc, glass, glassCircle, toggle } = L;

const OUT = process.argv[2];
const W1 = 393, GAP = 90, PAD = 70, OY = 140;
const px = i => PAD + i * (W1 + GAP);

function write(name, title, subs, screens) {
  const w = PAD * 2 + screens.length * W1 + (screens.length - 1) * GAP;
  const h = OY + 852 + 110;
  const head = t(PAD - 13, 48, title, { size: 26, weight: 800, fill: C.label }) +
    subs.map((s, i) => t(PAD - 13, 78 + i * 22, s, { size: 15, fill: C.secondary })).join('');
  const body = head + screens.map(([inner, cap], i) => phone(px(i), OY, inner, cap)).join('\n');
  fs.writeFileSync(path.join(OUT, name), doc(w, h, body, title));
}

// Wrap text to a width by measured advance, like the system line breaker:
// Latin/number runs stay whole when they fit, Japanese breaks between characters with
// basic kinsoku (no closing punctuation at line start, no opening bracket at line end).
// The URL (o.mono) may break anywhere: it is shown in full, never truncated.
const NO_START = '）)」』】、。，．・ーぁぃぅぇぉっゃゅょァィゥェォッャュョ!?！？:：;；';
const NO_END = '（(「『【';
function tokens(str, o) {
  if (o.mono) return [...str];
  return str.match(/[A-Za-z0-9\-_:./@#&?=%+]+|./gsu) || [];
}
function wrap(str, width, o) {
  const lines = [];
  let cur = '';
  const push = () => { if (cur) lines.push(cur); cur = ''; };
  for (const tok of tokens(str, o)) {
    if (measure(cur + tok, o) <= width) { cur += tok; continue; }
    if (tok.length > 1 && measure(tok, o) > width) {
      for (const ch of tok) { if (measure(cur + ch, o) > width && cur) push(); cur += ch; }
      continue;
    }
    if (NO_START.includes(tok) && cur) {
      const last = [...cur].pop();
      cur = cur.slice(0, -last.length); push(); cur = last + tok; continue;
    }
    const last = [...cur].pop();
    if (last && NO_END.includes(last)) { cur = cur.slice(0, -last.length); push(); cur = last + tok; continue; }
    push(); cur = tok;
  }
  push();
  return lines;
}
function para(x, y, str, width, o, lead) {
  return wrap(str, width, o).map((ln, i) => t(x, y + i * lead, ln, o)).join('');
}
function paraLines(str, width, o) { return wrap(str, width, o).length; }

// ---------- empty & permission states (light) ----------
function emptyBlock(cy, ic, title, body, button, o = {}) {
  let s = `<circle cx="196.5" cy="${cy}" r="48" fill="${C.accentSoft}"/>` + icon(ic, 196.5 - 26, cy - 26, 52, C.accent);
  let y = cy + 92;
  wrap(title, 320, { size: 22, weight: 800 }).forEach((ln, i) => { s += t(196.5, y + i * 30, ln, { size: 22, weight: 800, anchor: 'middle' }); y += 0; });
  y += paraLines(title, 320, { size: 22, weight: 800 }) * 30 + 6;
  wrap(body, 300, { size: 15 }).forEach((ln, i) => { s += t(196.5, y + i * 22, ln, { size: 15, fill: C.secondary, anchor: 'middle' }); });
  y += paraLines(body, 300, { size: 15 }) * 22 + 20;
  if (button) {
    const bw = Math.max(200, measure(button, { size: 17, weight: 700 }) + 64);
    s += o.secondary
      ? rect(196.5 - bw / 2, y, bw, 50, { rx: 25, fill: C.card, stroke: C.separator }) + t(196.5, y + 31, button, { size: 17, weight: 700, fill: C.accent, anchor: 'middle' })
      : rect(196.5 - bw / 2, y, bw, 50, { rx: 25, fill: C.accentFill }) + t(196.5, y + 31, button, { size: 17, weight: 700, fill: '#fff', anchor: 'middle' });
  }
  return s;
}
// History with zero records: no search / CSV / select (HIG: don't show controls that can't act).
function historyEmpty() {
  return S.navLarge('履歴') +
    emptyBlock(330, 'clock', '履歴はまだありません', 'QRコードやバーコードを読み取ると、ここに自動で保存されます。保存先はこの端末の中だけです。', 'スキャンを始める') +
    tabBar(1, false);
}
function historyNoResults() {
  return S.navLarge('履歴', glass(377 - 96, 58, 96, 44, false) + icon('share', 377 - 84, 69, 22, C.label) + icon('selectCircle', 377 - 38, 69, 22, C.label)) +
    rect(16, 148, 361, 38, { rx: 10, fill: C.fill }) + icon('search', 26, 157, 20, C.secondary) + t(52, 173, 'クーポン', { size: 16 }) +
    `<circle cx="358" cy="167" r="9" fill="${C.tertiary}"/>` + icon('xmark', 352, 161, 12, C.card) +
    S.chips(16, 198, [['すべて', false], ['お気に入り', true, 'star'], ['URL', false], ['Wi-Fi', false]]) +
    emptyBlock(360, 'search', '「クーポン」に一致する履歴はありません', '検索語や絞り込み（お気に入り）を変えてお試しください。', '絞り込みを解除', { secondary: true }) +
    tabBar(1, false);
}
function historyAutosaveOff() {
  return S.navLarge('履歴') +
    emptyBlock(330, 'clock', '履歴の自動保存がオフです', 'オンにすると、読み取り・作成した内容がこの端末に保存されます。', '設定を開く') +
    tabBar(1, false);
}
// Alert over the screen that triggered it. Cancel leading, default action trailing (HIG Alerts).
function alertOver(base, title, msg, cancel, action) {
  const w = 320, x = 196.5 - w / 2;
  const tl = wrap(title, w - 40, { size: 17, weight: 700 }), ml = wrap(msg, w - 40, { size: 13 });
  const h = 36 + tl.length * 22 + 8 + ml.length * 18 + 22 + 50;
  const y = 426 - h / 2;
  let s = base + rect(0, 0, 393, 852, { fill: 'rgba(0,0,0,0.3)' }) +
    `<g filter="url(#shadowLg)">${rect(x, y, w, h, { rx: 26, fill: C.sheet })}</g>`;
  tl.forEach((l, i) => { s += t(196.5, y + 36 + i * 22, l, { size: 17, weight: 700, anchor: 'middle' }); });
  const my = y + 36 + tl.length * 22 + 6;
  ml.forEach((l, i) => { s += t(196.5, my + i * 18, l, { size: 13, anchor: 'middle' }); });
  const by = y + h - 62, bw = (w - 44) / 2;
  s += rect(x + 16, by, bw, 46, { rx: 23, fill: C.fill }) + t(x + 16 + bw / 2, by + 29, cancel, { size: 17, weight: 600, anchor: 'middle' });
  s += rect(x + 28 + bw, by, bw, 46, { rx: 23, fill: C.accentFill }) + t(x + 28 + bw + bw / 2, by + 29, action, { size: 17, weight: 700, fill: '#fff', anchor: 'middle' });
  return s;
}
function photoDenied() {
  return alertOver(S.createB(), '写真への保存が許可されていません', '作成したQRコードを保存するには、設定アプリでこのアプリに写真の追加を許可してください。', 'キャンセル', '設定を開く');
}
function noCodeInImage() {
  return alertOver(S.scanA(), 'コードが見つかりませんでした', '別の画像を選ぶか、コードが大きくはっきり写った画像でお試しください。', 'キャンセル', '別の画像を選ぶ');
}

// ---------- Dynamic Type AX5 (largest) ----------
// HIG AX5: Large Title 60, Title 2 56, Headline/Body 53, Subhead 49, Footnote 44, Caption 1 43.
const AX = { large: 60, title2: 56, body: 53, subhead: 49, footnote: 44 };
function axResult() {
  let s = S.sheetBackdrop() + `<path d="M0 72a14 14 0 0 1 14-14H379a14 14 0 0 1 14 14V852H0Z" fill="${C.bg}"/>` + rect(178.5, 64, 36, 5, { rx: 2.5, fill: C.grabber }) +
    glassCircle(38, 104, 22, 'xmark', false);
  // Header stacks vertically: icon above the title (inline -> stacked at accessibility sizes).
  s += tile(16, 90, 64, C.kind.url, 'link', 16);
  s += t(16, 210, 'URL', { size: AX.title2, weight: 800 });
  s += para(16, 262, 'QRコード・2026/10/24 08:12', 361, { size: AX.footnote, fill: C.secondary }, 52);
  const card = 380;
  s += rect(16, card, 361, 520, { rx: 14, fill: C.card });
  s += para(32, card + 52, 'リンク先（全文）', 329, { size: AX.footnote, weight: 600, fill: C.secondary }, 52);
  wrap('https://www.example.co.jp/campaign/2026/autumn?utm_source=qr&ref=store-1234&lang=ja', 329, { size: AX.body, mono: true })
    .forEach((ln, i) => { const by = card + 168 + i * 62; if (by < 812) s += t(32, by, ln, { size: AX.body, mono: true }); });
  // scroll indicator: content continues; at accessibility sizes the actions are not pinned
  // (a pinned bar would cover too much of the screen) and follow below the full URL
  s += rect(386, 300, 4, 140, { rx: 2, fill: 'rgba(0,0,0,0.35)' });
  return s + L.homeIndicator(false);
}
function axHistory() {
  let s = rect(0, 0, 393, 852, { fill: C.bg }) + statusBar(false) +
    glass(377 - 96, 58, 96, 44, false) + icon('share', 377 - 84, 69, 22, C.label) + icon('selectCircle', 377 - 38, 69, 22, C.label);
  s += t(16, 176, '履歴', { size: AX.large, weight: 800 });
  // Each row: icon on its own line, title wraps, metadata wraps. No truncation of the title.
  let y = 210;
  const rows = [['url', 'link', 'Seijitsu-Cafe_5G の案内', 'Wi-Fi・08:05'], ['text', 'barcode', '4901234567894', 'EAN-13・07:58']];
  rows.forEach(([k, ic, title, meta]) => {
    const tl = wrap(title, 329, { size: AX.body, weight: 600 }), ml = wrap(meta, 329, { size: AX.subhead });
    const h = 24 + 56 + 12 + tl.length * 62 + ml.length * 58 + 12;
    s += rect(16, y, 361, h, { rx: 14, fill: C.card });
    s += tile(32, y + 20, 56, C.kind[k], ic, 14);
    tl.forEach((l, i) => { s += t(32, y + 92 + 50 + i * 62, l, { size: AX.body, weight: 600 }); });
    ml.forEach((l, i) => { s += t(32, y + 92 + tl.length * 62 + 42 + i * 58, l, { size: AX.subhead, fill: C.secondary }); });
    y += h + 16;
  });
  return s + tabBar(1, false);
}
function axSettings() {
  let s = rect(0, 0, 393, 852, { fill: C.bg }) + statusBar(false) + t(16, 130, '設定', { size: AX.large, weight: 800 });
  s += para(32, 196, 'スキャン', 329, { size: AX.footnote, fill: C.secondary }, 52);
  // Label wraps on its own lines; the switch keeps its size and moves below the label.
  const rowsY = 220;
  s += rect(16, rowsY, 361, 520, { rx: 14, fill: C.card });
  const lab1 = wrap('読み取り時の音', 329, { size: AX.body });
  lab1.forEach((l, i) => { s += t(32, rowsY + 62 + i * 62, l, { size: AX.body }); });
  let ty = rowsY + 62 + lab1.length * 62 - 30;
  s += toggle(32, ty, true);
  s += `<line x1="32" y1="${ty + 52}" x2="377" y2="${ty + 52}" stroke="${C.separator}"/>`;
  const lab2 = wrap('読み取り時の振動', 329, { size: AX.body });
  lab2.forEach((l, i) => { s += t(32, ty + 52 + 70 + i * 62, l, { size: AX.body }); });
  ty = ty + 52 + 70 + lab2.length * 62 - 30;
  s += toggle(32, ty, true);
  return s + tabBar(3, false);
}

// ---------- write ----------
write('11_empty_and_permission.svg', '11 空状態・権限拒否', [
  '空の画面には次の行動を示す（HIG Writing）。使えない操作（CSV・選択）は空のときは表示しない。',
  '権限が拒否されたら設定アプリへの導線を出す。アラートはキャンセルを左、実行ボタンを右（HIG Alerts）。カメラ拒否は 01-C。',
], [
  [historyEmpty(), 'A. 履歴 0 件'], [historyNoResults(), 'B. 検索・絞り込みで 0 件'], [historyAutosaveOff(), 'C. 自動保存オフで 0 件'],
  [photoDenied(), 'D. 写真への保存が拒否済み'], [noCodeInImage(), 'E. 画像にコードがない'],
]);
write('12_dynamic_type.svg', '12 最大文字サイズ（Dynamic Type AX5）', [
  '本文 53pt・大見出し 60pt（HIG Typography AX5）。横並びは縦積みに、タイトル・URLは切り詰めず折り返し、画面はスクロールで全文表示。',
  'タブバーのラベルは拡大しない（システム挙動。長押しで拡大表示）。スイッチは大きさを変えずラベルの下へ。',
], [[axResult(), 'A. 結果（URL全文を折り返し）'], [axHistory(), 'B. 履歴（行内を縦積み）'], [axSettings(), 'C. 設定（ラベル折り返し）']]);

setTheme('dark');
write('10_dark_mode.svg', '10 ダークモード', [
  '色はアセットカタログの Color Set（Any / Dark / 高コントラスト）で定義し、背景・文字はシステムのセマンティックカラーを使う。',
  'ダークではアクセント文字 #2BA083（背景比 5.2:1 以上）、塗りボタン #1C8269（白文字 4.7:1）。QRコード画像は両モードとも白地に黒で表示。',
], [[S.resultURL(), 'A. 結果'], [S.historyA(), 'B. 履歴'], [S.createB(), 'C. QR作成'], [S.paywall(false), 'D. 課金'], [S.settings(false), 'E. 設定']]);
setTheme('light');
console.log('ok');
