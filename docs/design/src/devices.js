// iPad and iPhone Duo mockups, following HIG "Designing for iPhone Duo" (2026-09-09):
// vertical bars on the trailing edge (outer display / inner landscape), split views on
// the inner display, fold-aware layout when partially folded, Liquid Glass controls.
const fs = require('fs');
const path = require('path');
const L = require('./lib');
const { C, t, measure, iconLabel, rect, icon, tile, fakeQR, toggle, doc, esc, glass, glassCircle } = L;

const OUT = process.argv[2];
let seq = 0;
const uid = p => `${p}${seq++}`;

// ---------- shared primitives ----------
function camFeed(w, h, qx, qy, qs = 150) {
  const id = uid('cam');
  return `<defs><linearGradient id="${id}" x1="0" y1="0" x2="0.3" y2="1"><stop offset="0" stop-color="#3B4240"/><stop offset=".55" stop-color="#262B2A"/><stop offset="1" stop-color="#121514"/></linearGradient></defs>` +
    rect(0, 0, w, h, { fill: `url(#${id})` }) +
    `<g filter="url(#blur6)" opacity=".9"><rect x="${-40}" y="${h * 0.72}" width="${w + 80}" height="${h * 0.4}" fill="#4A4038"/>
     <rect x="${w * 0.66}" y="${h * 0.12}" width="${w * 0.4}" height="${h * 0.32}" rx="6" fill="#56605D"/>
     <circle cx="${w * 0.12}" cy="${h * 0.2}" r="${Math.min(w, h) * 0.16}" fill="#5B6563" opacity=".6"/></g>
    <g transform="rotate(-4 ${qx} ${qy})">
      <rect x="${qx - qs * 0.74}" y="${qy - qs * 0.79}" width="${qs * 1.48}" height="${qs * 1.6}" rx="8" fill="#E9E6DD"/>
      <rect x="${qx - qs * 0.63}" y="${qy - qs * 0.68}" width="${qs * 1.26}" height="${qs * 0.066}" rx="3" fill="#B8B2A4"/>
      ${fakeQR(qx - qs / 2, qy - qs * 0.53, qs, 29, '#1A1A1A', 11)}
      <rect x="${qx - qs * 0.56}" y="${qy + qs * 0.58}" width="${qs * 1.12}" height="${qs * 0.05}" rx="3" fill="#C9C3B5"/>
    </g>`;
}
function reticle(cx, cy, s, color = '#fff', dim = true, w = 2000, h = 2000) {
  const x = cx - s / 2, y = cy - s / 2, l = Math.min(38, s * 0.16), r = Math.min(24, s * 0.1);
  return (dim ? `<path fill="rgba(0,0,0,0.45)" fill-rule="evenodd" d="M0 0H${w}V${h}H0Z M${x + r} ${y}H${x + s - r}a${r} ${r} 0 0 1 ${r} ${r}V${y + s - r}a${r} ${r} 0 0 1-${r} ${r}H${x + r}a${r} ${r} 0 0 1-${r}-${r}V${y + r}a${r} ${r} 0 0 1 ${r}-${r}Z"/>` : '') +
    `<g fill="none" stroke="${color}" stroke-width="5" stroke-linecap="round">
    <path d="M${x} ${y + l}V${y + r}a${r} ${r} 0 0 1 ${r}-${r}H${x + l}"/><path d="M${x + s - l} ${y}H${x + s - r}a${r} ${r} 0 0 1 ${r} ${r}V${y + l}"/>
    <path d="M${x + s} ${y + s - l}V${y + s - r}a${r} ${r} 0 0 1 -${r} ${r}H${x + s - l}"/><path d="M${x + l} ${y + s}H${x + r}a${r} ${r} 0 0 1 -${r}-${r}V${y + s - l}"/></g>`;
}
function pill(cx, baseline, ic, label, o, bg, h) {
  const w = 18 + measure(label, o) + 6 + o.size + 6 + 18;
  const top = baseline - o.size * 0.36 - h / 2;
  return rect(cx - w / 2, top, w, h, { rx: h / 2, fill: bg }) + iconLabel(cx, baseline, ic, o.size + 6, label, { ...o, gap: 6 });
}
const sep = (x1, x2, y) => `<line x1="${x1}" y1="${y}" x2="${x2}" y2="${y}" stroke="${C.separator}"/>`;

// URL wrapped to the card width by measured monospace advance (no truncation: HIG + product rule).
const URL_TEXT = 'https://www.example.co.jp/campaign/2026/autumn?utm_source=qr&ref=store-1234&lang=ja';
function wrapMono(s, width, size) {
  const per = Math.max(8, Math.floor(width / measure('a', { size, mono: true })));
  const out = [];
  for (let i = 0; i < s.length; i += per) out.push(s.slice(i, i + per));
  return out;
}
// Result detail for a URL; returns svg. Width-adaptive, used by every pane size.
function urlDetail(x, y, w, o = {}) {
  let s = tile(x, y, 48, C.kind.url, 'link', 12) +
    t(x + 60, y + 21, 'URL', { size: 22, weight: 800 }) +
    t(x + 60, y + 42, 'QRコード ・ 2026/10/24 08:12', { size: 13, fill: C.secondary });
  const lines = wrapMono(URL_TEXT, w - 32, 15);
  const cardH = 44 + lines.length * 22 + 102;
  let cy = y + 66;
  s += rect(x, cy, w, cardH, { rx: 14, fill: C.card });
  s += t(x + 16, cy + 26, 'リンク先（全文・省略なし）', { size: 13, weight: 600, fill: C.secondary });
  const host = 'www.example.co.jp';
  lines.forEach((ln, i) => {
    const by = cy + 54 + i * 22;
    const hi = ln.indexOf(host);
    if (i === 0 && hi >= 0) s += t(x + 16, by, [{ s: ln.slice(0, hi) }, { s: host, weight: 800 }, { s: ln.slice(hi + host.length) }], { size: 15, mono: true });
    else s += t(x + 16, by, ln, { size: 15, mono: true });
  });
  let ry = cy + 54 + (lines.length - 1) * 22 + 22;
  s += sep(x + 16, x + w - 16, ry);
  s += t(x + 16, ry + 26, 'ドメイン', { size: 15, fill: C.secondary }) + t(x + w - 16, ry + 26, host, { size: 15, weight: 700, anchor: 'end' });
  s += sep(x + 16, x + w - 16, ry + 42);
  const hw = measure('https（暗号化）', { size: 15, weight: 600 });
  s += t(x + 16, ry + 68, '方式', { size: 15, fill: C.secondary }) + icon('lock', x + w - 16 - hw - 20, ry + 55, 16, C.accent) + t(x + w - 16, ry + 68, 'https（暗号化）', { size: 15, weight: 600, anchor: 'end' });
  cy += cardH + 14;
  s += icon('info', x + 2, cy, 16, C.secondary) + t(x + 24, cy + 13, '「ブラウザで開く」を押すまで通信は発生しません。', { size: 13, fill: C.secondary });
  cy += 30;
  s += rect(x, cy, w, 52, { rx: 14, fill: C.accentFill }) + iconLabel(x + w / 2, cy + 33, 'external', 22, 'ブラウザで開く', { size: 17, weight: 700, fill: '#fff' });
  if (o.actions) {
    cy += 64;
    const bw = (w - 16) / 3;
    [['copy', 'コピー'], ['share', '共有'], ['star', 'お気に入り', C.yellow]].forEach(([ic, lb, col], i) => {
      const bx = x + i * (bw + 8);
      s += rect(bx, cy, bw, 62, { rx: 14, fill: C.card }) + icon(ic, bx + bw / 2 - 12, cy + 10, 24, col || C.accent, ic === 'star') +
        t(bx + bw / 2, cy + 50, lb, { size: 13, weight: 600, fill: col || C.accent, anchor: 'middle' });
    });
    cy += 62;
  }
  return s;
}
// History list rows (inset grouped). sel = persistent selection highlight for split views (HIG Split views).
const ROWS_TODAY = [
  ['url', 'link', 'https://www.example.co.jp/campaign/2026/autumn?utm…', 'URL ・ QRコード ・ 08:12', true],
  ['wifi', 'wifi', 'Seijitsu-Cafe_5G', 'Wi-Fi ・ QRコード ・ 08:05', false],
  ['text', 'barcode', '4901234567894', 'テキスト ・ EAN-13 ・ 07:58', false],
];
const ROWS_YDAY = [
  ['contact', 'person', '山田 太郎（誠実商事）', '連絡先 ・ 作成 ・ 18:21', true],
  ['phone', 'phone', '03-1234-5678', '電話 ・ QRコード ・ 12:40', false],
  ['geo', 'pin', '35.68124, 139.76712', '地図座標 ・ QRコード ・ 09:03', false],
];
function truncate(s, width, o) {
  if (measure(s, o) <= width) return s;
  while (s.length > 1 && measure(s + '…', o) > width) s = s.slice(0, -1);
  return s + '…';
}
function rowsGroup(x, y, w, rows, sel = -1, head) {
  const id = uid('rc');
  let s = head ? t(x + 16, y - 8, head, { size: 13, weight: 600, fill: C.secondary }) : '';
  s += `<g filter="url(#shadow)">${rect(x, y, w, rows.length * 64, { rx: 14, fill: C.card })}</g><clipPath id="${id}"><rect x="${x}" y="${y}" width="${w}" height="${rows.length * 64}" rx="14"/></clipPath><g clip-path="url(#${id})">`;
  rows.forEach(([kind, ic, title, meta, fav], i) => {
    const ry = y + i * 64, on = i === sel;
    if (on) s += rect(x, ry, w, 64, { fill: C.accent });
    s += tile(x + 14, ry + 14, 36, on ? 'rgba(255,255,255,0.22)' : C.kind[kind], ic, 9);
    const tw = w - 62 - (fav ? 40 : 16);
    s += t(x + 62, ry + 29, truncate(title, tw, { size: 16, weight: 600 }), { size: 16, weight: 600, fill: on ? '#fff' : C.label });
    s += t(x + 62, ry + 49, meta, { size: 13, fill: on ? 'rgba(255,255,255,0.85)' : C.secondary });
    if (fav) s += icon('star', x + w - 34, ry + 21, 20, on ? '#fff' : C.yellow, true);
    if (i < rows.length - 1 && !on && i + 1 !== sel) s += sep(x + 62, x + w, ry + 64);
  });
  return s + '</g>';
}
function chips(x, y, items, maxX) {
  const id = uid('ch');
  let s = `<clipPath id="${id}"><rect x="${x - 2}" y="${y - 2}" width="${maxX - x + 2}" height="40"/></clipPath><g clip-path="url(#${id})">`;
  for (const [label, on, ic] of items) {
    const o = { size: 14, weight: 600, fill: on ? '#fff' : C.label };
    const w = measure(label, o) + 28 + (ic ? 22 : 0);
    s += rect(x, y, w, 32, { rx: 16, fill: on ? C.accent : C.card, stroke: on ? null : C.separator });
    s += ic ? iconLabel(x + w / 2, y + 21, ic, 16, label, { ...o, iconColor: on ? '#fff' : C.yellow, iconExtra: true, gap: 6 }) : t(x + w / 2, y + 21, label, { ...o, anchor: 'middle' });
    x += w + 8;
  }
  return s + '</g>';
}
const CHIP_ITEMS = [['すべて', true], ['お気に入り', false, 'star'], ['URL', false], ['Wi-Fi', false], ['連絡先', false], ['テキスト', false], ['電話', false]];
function searchField(x, y, w) {
  return rect(x, y, w, 38, { rx: 19, fill: C.fill }) + icon('search', x + 12, y + 9, 20, C.secondary) +
    t(x + 40, y + 25, '日時・種類・内容で検索', { size: 16, fill: '#8E8E93' });
}
function freeBanner(x, y, w) {
  return rect(x, y, w, 58, { rx: 14, fill: C.accentSoft }) + icon('infinity', x + 14, y + 17, 24, C.accent) +
    t(x + 50, y + 25, '無料版は直近30件まで保存します', { size: 14, weight: 700, fill: C.accentDark }) +
    t(x + 50, y + 45, truncate('現在 28 / 30件 ・ Pro（買い切り）で無制限に', w - 80, { size: 12 }), { size: 12, fill: C.accentDark }) +
    icon('chevron', x + w - 30, y + 20, 18, C.accent);
}
function sessionList(x, y, w) {
  const rows = [['text', 'barcode', '4901234567894', 'テキスト ・ EAN-13 ・ たった今'], ['url', 'link', 'https://www.example.co.jp/item/…', 'URL ・ QRコード ・ 12秒前'], ['text', 'barcode', '4909876543210', 'テキスト ・ EAN-13 ・ 25秒前']];
  let s = t(x + 4, y, '今回の読み取り', { size: 15, weight: 700 }) +
    rect(x + 4 + measure('今回の読み取り', { size: 15, weight: 700 }) + 8, y - 15, 28, 20, { rx: 10, fill: C.fill }) +
    t(x + 4 + measure('今回の読み取り', { size: 15, weight: 700 }) + 22, y, '3', { size: 13, weight: 700, anchor: 'middle' });
  s += rowsGroup(x, y + 14, w, rows.map(r => [...r, false]));
  return s;
}

// ---------- iPhone Duo ----------
// Point sizes are estimated from Apple's published pixels at @3x (Apple does not publish pt sizes):
// outer 1398x2034px -> 466x678pt (portrait), inner 2670x1878px -> 890x626pt (landscape).
const OUT_W = 466, OUT_H = 678, IN_W = 890, IN_H = 626;
const COL = 64;          // trailing column reserved for vertical bars (outer)
const COL_IN = 72;       // trailing column on inner display

// Trailing vertical stack: Dynamic Island, status bar, toolbar groups, tab bar (top -> bottom).
function verticalBars(W, H, colW, o) {
  const cx = W - colW / 2, dark = !!o.dark, fg = dark ? '#fff' : C.label;
  let s = '';
  let y = 22;
  if (o.island) { s += `<circle cx="${cx}" cy="${y + 14}" r="15" fill="#000"/>`; y += 44; } else y += 10;
  s += t(cx, y + 14, '9:41', { size: 15, weight: 700, fill: fg, anchor: 'middle' });
  s += `<circle cx="${cx}" cy="${y + 38}" r="15" fill="none" stroke="${fg}" stroke-width="1.6" stroke-dasharray="2 3.2"/>` + icon('wifi', cx - 9, y + 29, 18, fg);
  y += 70;
  for (const group of (o.toolbar || [])) {
    const h = group.length * 46 + 4;
    s += glass(cx - 24, y, 48, h, dark);
    group.forEach((g, i) => {
      const [name, on] = Array.isArray(g) ? g : [g, false];
      const iy = y + 2 + i * 46;
      if (on) s += `<circle cx="${cx}" cy="${iy + 23}" r="19" fill="${dark ? '#fff' : C.accent}"/>`;
      s += icon(name, cx - 11, iy + 12, 22, on ? (dark ? C.label : '#fff') : fg, name === 'star' && on);
    });
    y += h + 10;
  }
  if (o.tab != null) {
    const tabs = ['viewfinder', 'clock', 'plusSquare', 'gear'];
    const h = tabs.length * 52 + 8;
    const ty = H - 18 - h;
    s += glass(cx - 26, ty, 52, h, dark);
    tabs.forEach((name, i) => {
      const iy = ty + 4 + i * 52;
      if (i === o.tab) s += rect(cx - 22, iy, 44, 52, { rx: 22, fill: dark ? 'rgba(255,255,255,0.22)' : 'rgba(14,124,102,0.12)' });
      s += icon(name, cx - 12, iy + 14, 24, i === o.tab ? (dark ? C.accentOnDark : C.accent) : fg);
    });
  }
  return s;
}
function outerFrame(ox, oy, inner, caption, sub) {
  const id = uid('od');
  const shape = `M18 0H${OUT_W - 48}A48 48 0 0 1 ${OUT_W} 48V${OUT_H - 48}A48 48 0 0 1 ${OUT_W - 48} ${OUT_H}H18A18 18 0 0 1 0 ${OUT_H - 18}V18A18 18 0 0 1 18 0Z`;
  return `<g transform="translate(${ox} ${oy})">
    <rect x="-22" y="-10" width="16" height="${OUT_H + 20}" rx="7" fill="#B9BBC0"/>
    <path transform="translate(-10 -10) scale(${(OUT_W + 20) / OUT_W} ${(OUT_H + 20) / OUT_H})" d="${shape}" fill="#1C1C1E"/>
    <clipPath id="${id}"><path d="${shape}"/></clipPath><g clip-path="url(#${id})">${inner}</g>
  </g>` + caps(ox + OUT_W / 2, oy + OUT_H + 44, caption, sub);
}
function innerFrame(ox, oy, inner, caption, sub) {
  const id = uid('id');
  return `<g transform="translate(${ox} ${oy})">
    <rect x="-11" y="-11" width="${IN_W + 22}" height="${IN_H + 22}" rx="50" fill="#1C1C1E"/>
    <clipPath id="${id}"><rect x="0" y="0" width="${IN_W}" height="${IN_H}" rx="40"/></clipPath><g clip-path="url(#${id})">${inner}</g>
  </g>` + caps(ox + IN_W / 2, oy + IN_H + 44, caption, sub);
}
function caps(cx, y, caption, sub) {
  return t(cx, y, caption, { size: 18, weight: 700, anchor: 'middle', fill: '#3A3A3C' }) +
    (sub ? t(cx, y + 24, sub, { size: 13, anchor: 'middle', fill: C.secondary }) : '');
}
function foldGuide(active) {
  const x = IN_W / 2;
  return active
    ? rect(x - 14, 0, 28, IN_H, { fill: 'rgba(56,150,230,0.22)' }) + `<line x1="${x}" y1="0" x2="${x}" y2="${IN_H}" stroke="rgba(56,150,230,0.7)" stroke-dasharray="6 6"/>`
    : '';
}

// A. Closed: scan. Camera spans the full width under the vertical bars (HIG: immersive, non-scrolling).
function duoScanClosed() {
  const cw = OUT_W - COL;
  return camFeed(OUT_W, OUT_H, cw / 2, 300, 130) + reticle(cw / 2, 300, 236, '#fff', true, OUT_W, OUT_H) +
    t(cw / 2, 458, 'コードを枠内に合わせてください', { size: 17, weight: 700, fill: '#fff', anchor: 'middle' }) +
    t(cw / 2, 482, 'QRコード・バーコード 11種類に対応', { size: 13, fill: 'rgba(255,255,255,0.75)', anchor: 'middle' }) +
    pill(cw / 2, 640, 'shield', '読み取り内容は端末内だけで処理します', { size: 12, weight: 500, fill: '#fff', iconColor: C.accentOnDark }, 'rgba(0,0,0,0.45)', 32) +
    verticalBars(OUT_W, OUT_H, COL, { dark: true, island: true, toolbar: [['repeat', 'photo', 'bolt']], tab: 0 });
}
// B. Closed: result sheet. Sheets on the outer display present bars vertically; Close on top of the axis.
function duoResultClosed() {
  const cw = OUT_W - COL;
  return camFeed(OUT_W, OUT_H, cw / 2, 300, 130) + rect(0, 0, OUT_W, OUT_H, { fill: 'rgba(0,0,0,0.5)' }) +
    `<path d="M0 72a16 16 0 0 1 16-16H${OUT_W}V${OUT_H}H0Z" fill="${C.bg}"/>` +
    rect(cw / 2 - 18, 62, 36, 5, { rx: 2.5, fill: '#C7C7CC' }) +
    `<g transform="translate(0 -10)">${urlDetail(16, 92, cw - 24)}</g>` +
    iconLabel(cw / 2, OUT_H - 20, 'checkCircle', 16, '履歴に保存しました', { size: 13, fill: C.secondary, iconColor: C.green, gap: 6 }) +
    verticalBars(OUT_W, OUT_H, COL, { island: true, toolbar: [['xmark'], ['copy', 'share', 'star']] });
}
// C. Closed: history (compact width = single column, same as iPhone).
function duoHistoryClosed() {
  const cw = OUT_W - COL, x = 16, w = cw - 24;
  return rect(0, 0, OUT_W, OUT_H, { fill: C.bg }) +
    t(x, 62, '履歴', { size: 34, weight: 800 }) +
    searchField(x, 80, w) + chips(x, 130, CHIP_ITEMS, cw - 4) + freeBanner(x, 176, w) +
    rowsGroup(x, 268, w, ROWS_TODAY, -1, '今日') + rowsGroup(x, 488, w, ROWS_YDAY.slice(0, 3), -1, '昨日') +
    verticalBars(OUT_W, OUT_H, COL, { island: true, toolbar: [['share', 'selectCircle']], tab: 1 });
}
// D. Open: scan with an arrangement view (split): camera | result. Bars stay on the side in landscape.
function duoScanOpen(folded) {
  const half = IN_W / 2, gap = folded ? 14 : 0;
  const camW = half - gap;
  const id = uid('cp');
  let s = rect(0, 0, IN_W, IN_H, { fill: C.bg }) +
    `<clipPath id="${id}"><rect x="0" y="0" width="${camW}" height="${IN_H}"/></clipPath><g clip-path="url(#${id})">` +
    camFeed(camW, IN_H, camW / 2, 290, 130) + reticle(camW / 2, 290, 236, C.accentOnDark, true, camW, IN_H) +
    pill(camW / 2, 470, 'checkCircle', '読み取りました（重複は記録しません）', { size: 13, weight: 600, fill: C.label, iconColor: C.accent }, 'rgba(255,255,255,0.95)', 38) +
    pill(camW / 2, 590, 'shield', '読み取り内容は端末内だけで処理します', { size: 12, weight: 500, fill: '#fff', iconColor: C.accentOnDark }, 'rgba(0,0,0,0.45)', 32) +
    '</g>';
  const px = half + gap + 20, pw = IN_W - COL_IN - px - 8;
  s += t(px, 52, '読み取り結果', { size: 13, weight: 700, fill: C.secondary });
  s += `<g transform="translate(0 0)">${urlDetail(px, 66, pw)}</g>`;
  s += foldGuide(folded);
  s += verticalBars(IN_W, IN_H, COL_IN, { toolbar: [[['repeat', true], 'photo', 'bolt'], ['copy', 'share', 'star']], tab: 0 });
  return s;
}
// E/F. Open: history split view (list | detail). Folded: columns become symmetric around the fold.
function duoHistoryOpen(folded) {
  const half = IN_W / 2;
  const listW = folded ? half - 14 : 372;
  const detailX = folded ? half + 14 : listW;
  let s = rect(0, 0, IN_W, IN_H, { fill: C.bg }) + rect(0, 0, listW, IN_H, { fill: C.listColumn }) +
    `<line x1="${listW}" y1="0" x2="${listW}" y2="${IN_H}" stroke="${C.separator}"/>`;
  // Controls for the list stay above the list pane (HIG: locate controls near the content they affect).
  const lx = 20, lw = listW - 40;
  s += glass(lx, 22, 44, 44, false) + icon('sidebar', lx + 11, 33, 22, C.label);
  s += glass(lx + lw - 96, 22, 96, 44, false) + icon('share', lx + lw - 84, 33, 22, C.label) + icon('selectCircle', lx + lw - 38, 33, 22, C.label);
  s += t(lx, 104, '履歴', { size: 34, weight: 800 });
  s += searchField(lx, 120, lw) + chips(lx, 170, CHIP_ITEMS, listW - 6) + freeBanner(lx, 214, lw);
  s += rowsGroup(lx, 304, lw, ROWS_TODAY, 0, '今日');
  s += rowsGroup(lx, 524, lw, ROWS_YDAY.slice(0, 2), -1, '昨日');
  const dx = detailX + 24, dw = IN_W - COL_IN - dx - 8;
  s += urlDetail(dx, 40, dw);
  s += foldGuide(folded);
  s += verticalBars(IN_W, IN_H, COL_IN, { toolbar: [['copy', 'share', 'star', 'trash']], tab: 1 });
  return s;
}

// ---------- iPad (11-inch, landscape 1180x820pt = 2360x1640px @2x) ----------
const PW = 1180, PH = 820;
function ipadFrame(ox, oy, inner, caption, sub) {
  const id = uid('ip');
  return `<g transform="translate(${ox} ${oy})">
    <rect x="-22" y="-22" width="${PW + 44}" height="${PH + 44}" rx="40" fill="#1C1C1E"/>
    <circle cx="${PW / 2}" cy="-11" r="3" fill="#3A3A3C"/>
    <clipPath id="${id}"><rect x="0" y="0" width="${PW}" height="${PH}" rx="20"/></clipPath><g clip-path="url(#${id})">${inner}</g>
  </g>` + caps(ox + PW / 2, oy + PH + 52, caption, sub);
}
function ipadStatus(dark, rightDark = dark) {
  const c = rightDark ? '#fff' : C.label;
  return t(24, 22, '9:41  10月24日(土)', { size: 13, weight: 600, fill: dark ? '#fff' : C.label }) +
    icon('wifi', PW - 76, 9, 17, c) + rect(PW - 52, 10, 25, 12, { rx: 3.5, stroke: c, sw: 1 }) + rect(PW - 50, 12, 19, 8, { rx: 2, fill: c });
}
// iPadOS: tab bar floats at the top (Liquid Glass); labels as text.
function ipadTabs(active, dark) {
  const labels = ['スキャン', '履歴', '作成', '設定'];
  const o = { size: 15, weight: 600 };
  const ws = labels.map(l => measure(l, o) + 36);
  const total = ws.reduce((a, b) => a + b, 0) + 8;
  let x = PW / 2 - total / 2;
  let s = glass(x, 34, total, 44, dark);
  x += 4;
  labels.forEach((l, i) => {
    if (i === active) s += rect(x, 38, ws[i], 36, { rx: 18, fill: dark ? 'rgba(255,255,255,0.9)' : 'rgba(14,124,102,0.12)' });
    s += t(x + ws[i] / 2, 61, l, { ...o, anchor: 'middle', fill: i === active ? C.accent : (dark ? '#fff' : C.label) });
    x += ws[i];
  });
  return s;
}
function ipadScan() {
  const camW = 780;
  const id = uid('ic');
  let s = rect(0, 0, PW, PH, { fill: C.bg }) +
    `<clipPath id="${id}"><rect x="0" y="0" width="${camW}" height="${PH}"/></clipPath><g clip-path="url(#${id})">` +
    camFeed(camW, PH, camW / 2, 400, 170) + reticle(camW / 2, 400, 300, '#fff', true, camW, PH) +
    t(camW / 2, 600, 'コードを枠内に合わせてください', { size: 20, weight: 700, fill: '#fff', anchor: 'middle' }) +
    t(camW / 2, 628, 'QRコード・バーコード 11種類に対応', { size: 15, fill: 'rgba(255,255,255,0.75)', anchor: 'middle' }) +
    pill(camW / 2, 770, 'shield', '読み取り内容は端末内だけで処理します', { size: 13, weight: 500, fill: '#fff', iconColor: C.accentOnDark }, 'rgba(0,0,0,0.45)', 36) +
    glassCircle(36 + 22, 124, 22, 'repeat', true) + '</g>';
  s += glass(camW - 120, 102, 100, 44, true) + icon('photo', camW - 105, 113, 22, '#fff') + icon('bolt', camW - 57, 113, 22, '#fff');
  const px = camW + 24, pw = PW - px - 24;
  s += t(px, 120, '読み取り結果', { size: 28, weight: 800 });
  s += urlDetail(px, 140, pw, { actions: true });
  s += ipadStatus(true, false) + ipadTabs(0, false);
  return s;
}
function ipadHistory() {
  const listW = 380;
  let s = rect(0, 0, PW, PH, { fill: C.bg }) + rect(0, 0, listW, PH, { fill: C.listColumn }) +
    `<line x1="${listW}" y1="0" x2="${listW}" y2="${PH}" stroke="${C.separator}"/>`;
  const lx = 20, lw = listW - 40;
  s += glass(lx, 96, 44, 44, false) + icon('sidebar', lx + 11, 107, 22, C.label);
  s += glass(lx + lw - 96, 96, 96, 44, false) + icon('share', lx + lw - 84, 107, 22, C.label) + icon('selectCircle', lx + lw - 38, 107, 22, C.label);
  s += t(lx, 178, '履歴', { size: 34, weight: 800 }) + searchField(lx, 194, lw) + chips(lx, 244, CHIP_ITEMS, listW - 6) + freeBanner(lx, 288, lw);
  s += rowsGroup(lx, 378, lw, ROWS_TODAY, 0, '今日') + rowsGroup(lx, 598, lw, ROWS_YDAY.slice(0, 3), -1, '昨日');
  const dx = listW + 48, dw = PW - dx - 48;
  s += glass(PW - 24 - 196, 96, 196, 44, false);
  ['copy', 'share', 'star', 'trash'].forEach((n, i) => { s += icon(n, PW - 24 - 196 + 15 + i * 46, 107, 22, n === 'trash' ? C.red : C.label, false); });
  s += urlDetail(dx, 170, Math.min(dw, 640));
  s += ipadStatus(false) + ipadTabs(1, false);
  return s;
}
function ipadCreate() {
  const listW = 380;
  let s = rect(0, 0, PW, PH, { fill: C.bg }) + rect(0, 0, listW, PH, { fill: C.listColumn }) +
    `<line x1="${listW}" y1="0" x2="${listW}" y2="${PH}" stroke="${C.separator}"/>`;
  const lx = 20, lw = listW - 40;
  s += t(lx, 178, '作成', { size: 34, weight: 800 }) + t(lx, 204, '作成したQRコードは履歴にも保存されます', { size: 14, fill: C.secondary });
  const items = [['text', 'text', 'テキスト', '無料'], ['url', 'link', 'URL', '無料'], ['wifi', 'wifi', 'Wi-Fi', 'Pro'], ['contact', 'person', '連絡先', 'Pro'], ['event', 'calendar', 'イベント', 'Pro']];
  const gy = 228;
  s += `<g filter="url(#shadow)">${rect(lx, gy, lw, items.length * 56, { rx: 14, fill: C.card })}</g>`;
  items.forEach(([k, ic, name, badge], i) => {
    const y = gy + i * 56, on = i === 1, locked = badge === 'Pro';
    if (on) s += rect(lx, y, lw, 56, { rx: i === 0 ? 14 : 0, fill: C.accentFill });
    s += tile(lx + 14, y + 12, 32, on ? 'rgba(255,255,255,0.22)' : (locked ? '#B9BEC4' : C.kind[k]), ic, 8);
    s += t(lx + 58, y + 34, name, { size: 16, weight: 600, fill: on ? '#fff' : (locked ? C.secondary : C.label) });
    s += locked ? rect(lx + lw - 70, y + 16, 56, 24, { rx: 12, fill: C.accentSoft }) + iconLabel(lx + lw - 42, y + 33, 'lock', 13, 'Pro', { size: 13, weight: 800, fill: C.accent, gap: 3 })
      : t(lx + lw - 16, y + 34, badge, { size: 13, weight: 600, fill: on ? 'rgba(255,255,255,0.85)' : C.secondary, anchor: 'end' });
    if (i < items.length - 1 && !on && i + 1 !== 1) s += sep(lx + 58, lx + lw, y + 56);
  });
  s += rect(lx, gy + items.length * 56 + 20, lw, 72, { rx: 14, fill: C.accentSoft }) +
    icon('lockOpen', lx + 14, gy + items.length * 56 + 44, 24, C.accent) +
    t(lx + 50, gy + items.length * 56 + 48, 'Wi-Fi・連絡先・イベントは Pro で作成', { size: 13, weight: 700, fill: C.accentDark }) +
    t(lx + 50, gy + items.length * 56 + 70, '買い切り ¥800 ・ 毎月/毎週の支払いなし', { size: 12, fill: C.accentDark });
  // Detail: form (leading) + preview (trailing) in one view.
  const dx = listW + 40;
  s += t(dx, 178, 'URL', { size: 28, weight: 800 });
  s += t(dx + 16, 222, 'URL', { size: 13, weight: 600, fill: C.secondary }) + rect(dx, 230, 340, 48, { rx: 12, fill: C.card }) + t(dx + 16, 260, 'https://www.example.co.jp', { size: 16, mono: true });
  s += rect(dx, 296, 340, 52, { rx: 14, fill: C.accentFill }) + t(dx + 170, 328, 'QRコードを作成', { size: 17, weight: 700, fill: '#fff', anchor: 'middle' });
  const qx = dx + 380, qw = PW - qx - 40;
  s += `<g filter="url(#shadow)">${rect(qx, 200, qw, 420, { rx: 18, fill: C.card })}</g>` + fakeQR(qx + qw / 2 - 140, 230, 280, 29, '#000', 3) +
    t(qx + qw / 2, 548, 'https://www.example.co.jp', { size: 13, mono: true, fill: C.secondary, anchor: 'middle' }) +
    iconLabel(qx + qw / 2, 580, 'checkCircle', 16, '履歴に保存しました', { size: 13, fill: C.secondary, iconColor: C.green, gap: 6 });
  const bw = (qw - 12) / 2;
  s += rect(qx, 640, bw, 52, { rx: 14, fill: C.accentFill }) + iconLabel(qx + bw / 2, 672, 'download', 22, '写真に保存', { size: 17, weight: 700, fill: '#fff' });
  s += rect(qx + bw + 12, 640, bw, 52, { rx: 14, fill: C.card, stroke: C.separator }) + iconLabel(qx + bw + 12 + bw / 2, 672, 'share', 22, '共有', { size: 17, weight: 700, fill: C.accent });
  s += ipadStatus(false) + ipadTabs(2, false);
  return s;
}
function ipadPaywall() {
  let s = ipadHistory() + rect(0, 0, PW, PH, { fill: 'rgba(0,0,0,0.35)' });
  const w = 560, h = 700, x = PW / 2 - w / 2, y = 60;
  s += `<g filter="url(#shadowLg)">${rect(x, y, w, h, { rx: 28, fill: '#fff' })}</g>`;
  s += glassCircle(x + 38, y + 38, 20, 'xmark', false);
  const cx = x + w / 2;
  s += tile(cx - 34, y + 40, 68, C.accentFill, 'qr', 16) +
    t(cx, y + 144, '誠実QRリーダー Pro', { size: 26, weight: 800, anchor: 'middle' }) +
    t(cx, y + 170, '一回払いで、ずっと使えます', { size: 15, fill: C.secondary, anchor: 'middle' });
  const bx = x + 40, bw = w - 80;
  s += rect(bx, y + 192, bw, 112, { rx: 16, fill: C.accentSoft, stroke: C.accent, sw: 1.5 }) +
    icon('checkCircle', bx + 16, y + 210, 24, C.accent) + t(bx + 50, y + 222, 'これは買い切りです。', { size: 16, weight: 800, fill: C.accentDark }) +
    t(bx + 50, y + 244, '毎月・毎週の支払いは発生しません', { size: 16, weight: 800, fill: C.accentDark }) +
    icon('checkCircle', bx + 16, y + 264, 24, C.accent) + t(bx + 50, y + 282, '広告は今後も入れません', { size: 16, weight: 800, fill: C.accentDark });
  const feats = [['infinity', '履歴を無制限に保存', '無料版は直近30件まで'], ['qr', 'すべての種類のQRコードを作成', 'Wi-Fi・連絡先・イベントにも対応'], ['docText', '履歴のCSVエクスポート', '表計算アプリで開ける形式で書き出し']];
  s += t(bx, y + 336, 'Proで使えるようになる機能', { size: 13, weight: 700, fill: C.secondary });
  feats.forEach(([ic, a, b], i) => {
    const fy = y + 350 + i * 52;
    s += `<circle cx="${bx + 20}" cy="${fy + 20}" r="20" fill="${C.accentSoft}"/>` + icon(ic, bx + 8, fy + 8, 24, C.accent) +
      t(bx + 52, fy + 15, a, { size: 16, weight: 700 }) + t(bx + 52, fy + 36, b, { size: 13, fill: C.secondary });
  });
  s += t(cx, y + 528, 'スキャンは無料版でも回数無制限です。', { size: 13, fill: C.secondary, anchor: 'middle' }) +
    rect(bx, y + 546, bw, 56, { rx: 14, fill: C.accentFill }) + t(cx, y + 581, '¥800 で購入（買い切り）', { size: 18, weight: 800, fill: '#fff', anchor: 'middle' }) +
    t(cx, y + 636, '購入を復元', { size: 16, weight: 600, fill: C.accent, anchor: 'middle' }) +
    t(cx, y + 664, 'お支払いはAppleアカウントに1回だけ請求されます。', { size: 12, fill: C.secondary, anchor: 'middle' }) +
    t(cx, y + 682, '同じAppleアカウントのiPhone・iPadで復元できます。', { size: 12, fill: C.secondary, anchor: 'middle' });
  return s;
}

// ---------- compose ----------
function header(title, lines) {
  return t(70, 56, title, { size: 30, weight: 800 }) + lines.map((l, i) => t(70, 88 + i * 22, l, { size: 15, fill: C.secondary })).join('');
}
function writeDuo() {
  const W = 70 * 2 + IN_W * 2 + 120;
  let body = header('08 iPhone Duo', [
    '閉じた時＝外側ディスプレイ（compact幅・縦長）、開いた時＝内側ディスプレイ（regular幅・横長）。HIG「Designing for iPhone Duo」に準拠。',
    'ツールバー／タブバー／ステータスバー／Dynamic Island は後縁（右端）に縦配置（システム標準）。内側では一段深い階層（一覧＋詳細）を並べる。',
    '寸法はAppleの公開ピクセル値を@3xで換算した推定値（外側 466×678pt、内側 890×626pt）。Appleはpt値を公開していない。',
  ]);
  const y1 = 190;
  body += t(70, y1 - 22, '閉じた時（外側ディスプレイ）', { size: 20, weight: 800, fill: C.accentDark });
  const cx0 = 70 + 22;
  [duoScanClosed(), duoResultClosed(), duoHistoryClosed()].forEach((inner, i) => {
    const caps2 = [['A. スキャン', '全面カメラ＋縦配置のツールバー/タブバー'], ['B. 結果（シート）', 'シートでも縦バー。閉じるは軸の最上部'], ['C. 履歴', 'compact幅＝1カラム（iPhoneと同じ構成）']][i];
    body += outerFrame(cx0 + i * (OUT_W + 110), y1, inner, caps2[0], caps2[1]);
  });
  const y2 = y1 + OUT_H + 150;
  body += t(70, y2 - 22, '開いた時（内側ディスプレイ・横向き）', { size: 20, weight: 800, fill: C.accentDark });
  body += innerFrame(70 + 11, y2, duoScanOpen(false), 'D. スキャン（全開）', 'ArrangementView（split）：カメラ｜読み取り結果。結果はシートでなく右ペインに表示');
  body += innerFrame(70 + 11 + IN_W + 120, y2, duoHistoryOpen(false), 'E. 履歴（全開）', 'NavigationSplitView：一覧（操作は一覧の上）｜詳細（操作は右端の縦バー）');
  const y3 = y2 + IN_H + 150;
  body += t(70, y3 - 22, '開いた時（部分的に折りたたみ＝本のように持った状態）', { size: 20, weight: 800, fill: C.accentDark });
  body += innerFrame(70 + 11, y3, duoScanOpen(true), 'F. スキャン（部分折りたたみ）', '折り目（青）を避けて左右に配置。カメラと結果が折り目で分かれる');
  body += innerFrame(70 + 11 + IN_W + 120, y3, duoHistoryOpen(true), 'G. 履歴（部分折りたたみ）', 'スプリットビューの列幅が折り目を軸に左右対称へ（システムが自動調整）');
  const H = y3 + IN_H + 110;
  fs.writeFileSync(path.join(OUT, '08_iphone_duo.svg'), doc(W, H, body, '08 iPhone Duo'));
}
function writeIpad() {
  const W = 70 * 2 + PW * 2 + 120;
  let body = header('07 iPad', [
    'iPad 11インチ横向き（1180×820pt。Apple公開の2360×1640px を@2xで換算）。regular幅＝NavigationSplitView／分割レイアウトで一段深い階層を表示。',
    'タブバーは上部中央に浮かぶ Liquid Glass（iPadOS 標準）。課金画面は中央のフォームシート、閉じるはシステム標準の×ボタン。',
  ]);
  const y1 = 170, gx = 70 + 22;
  body += ipadFrame(gx, y1, ipadScan(), 'A. スキャン', 'カメラ｜読み取り結果（シートではなく右ペインに常時表示）');
  body += ipadFrame(gx + PW + 120 - 44, y1, ipadHistory(), 'B. 履歴', '一覧（選択を持続ハイライト）｜詳細。操作は詳細ペインのツールバーへ');
  const y2 = y1 + PH + 150;
  body += ipadFrame(gx, y2, ipadCreate(), 'C. QR作成', '種類一覧｜入力フォーム＋プレビュー（無料版は Wi-Fi/連絡先/イベントにロック表示）');
  body += ipadFrame(gx + PW + 120 - 44, y2, ipadPaywall(), 'D. 課金（フォームシート）', 'ユーザー操作時のみ表示。文言・価格表示は iPhone 版と同一');
  const H = y2 + PH + 120;
  fs.writeFileSync(path.join(OUT, '07_ipad.svg'), doc(W, H, body, '07 iPad'));
}
module.exports = { glass, glassCircle, camFeed, reticle, pill, sep, urlDetail, rowsGroup, chips, CHIP_ITEMS, searchField, freeBanner, ROWS_TODAY, ROWS_YDAY, caps, truncate, uid };

if (require.main === module) {
  writeIpad();
  writeDuo();
  console.log('ok');
}
