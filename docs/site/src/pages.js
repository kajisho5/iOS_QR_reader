// Generates the site design SVGs: node docs/site/src/pages.js
// 01_mobile.svg (390pt wide: top, privacy, support, privacy in dark mode) and 02_desktop.svg (1280px: top, privacy).
const fs = require('fs');
const path = require('path');

const OUT = path.join(__dirname, '..');
// The 1024px App Store icon (square; rounded below with the iOS corner ratio).
const ICON = fs.readFileSync(path.join(__dirname, '../../../SeijitsuQR/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png')).toString('base64');
const FONT = "-apple-system, 'Hiragino Sans', 'Noto Sans JP', sans-serif";

const LIGHT = {
  bg: '#F7F8F7', surface: '#FFFFFF', text: '#1C1F1E', sub: '#5B6361', line: '#E3E7E5',
  brand: '#0F7F68', brandSoft: '#E5F3EF', heroFrom: '#0F7F68', heroTo: '#0A5F4E', footer: '#EEF1F0',
};
const DARK = {
  bg: '#0E1211', surface: '#151B19', text: '#ECEFEE', sub: '#A3ACAA', line: '#26302D',
  brand: '#3CC7A6', brandSoft: '#16302A', heroFrom: '#0F5A4B', heroTo: '#08372E', footer: '#121816',
};

const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
const t = (x, y, s, o = {}) =>
  `<text x="${x}" y="${y}" font-size="${o.size || 16}" font-weight="${o.weight || 400}" fill="${o.fill || '#000'}"` +
  `${o.anchor ? ` text-anchor="${o.anchor}"` : ''}${o.ls ? ` letter-spacing="${o.ls}"` : ''}>${esc(s)}</text>`;
const r = (x, y, w, h, o = {}) =>
  `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${o.rx || 0}" fill="${o.fill || 'none'}"` +
  `${o.stroke ? ` stroke="${o.stroke}" stroke-width="${o.sw || 1}"` : ''}/>`;
const icon = (x, y, s) => `<use href="#appicon" transform="translate(${x} ${y}) scale(${s / 512})"/>`;

// Rough Japanese wrapping: full-width glyphs count 1, ASCII 0.55.
function wrap(s, width, size) {
  const lines = [];
  let line = '', w = 0;
  for (const ch of s) {
    const cw = /[\x20-\x7e]/.test(ch) ? 0.55 : 1;
    if ((w + cw) * size > width && line) {
      // Keep closing punctuation on the line (kinsoku).
      if (/[、。）」』！？]/.test(ch)) { line += ch; lines.push(line); line = ''; w = 0; continue; }
      lines.push(line); line = ''; w = 0;
    }
    line += ch; w += cw;
  }
  if (line) lines.push(line);
  return lines;
}
function para(x, y, s, width, o = {}) {
  const size = o.size || 16, lh = o.lh || size * 1.85;
  const lines = wrap(s, width, size);
  return { svg: lines.map((l, i) => t(x, y + i * lh, l, { ...o, size })).join(''), height: lines.length * lh };
}

// ---- Content (mirrors docs/site/DESIGN.md §6) ----
const SITE = { app: '誠実QRリーダー', provider: 'seventhwell', email: 'support@（§9-2 で確定）', updated: '制定日 2026年11月1日 ・ 最終改定日 2026年11月1日' };
const PROMISES = [
  ['ad', '広告なし', '広告もアクセス解析も入っていません。'],
  ['sub', 'サブスクなし', 'Pro は ¥800 の買い切り。定期的な課金はありません。'],
  ['lock', '端末の中で完結', '読み取り・作成・履歴はすべて端末内。アプリは通信しません。'],
];
const FEATURES = ['QRコードとバーコードの読み取り', '写真から読み取り', '連続スキャン', '履歴の検索とお気に入り', 'QRコードの作成', 'Wi-Fi への接続・連絡先への追加'];
const PRIVACY_LEAD = '本アプリは利用者の情報を収集しません。開発者のサーバーへ情報を送る仕組みもありません。';
const PRIVACY_TOC = ['基本方針', '端末の中だけで扱う情報', 'アクセス権限', 'アクセス解析・広告・トラッキング', 'Apple が提供する機能', '外部のサイトやアプリ', '第三者への提供', 'お問い合わせで受け取る情報', '改定'];
const PRIVACY_SECTIONS = [
  ['1. 基本方針', [['p', '読み取り・作成・履歴の保存は、すべて端末の中だけで行います。アプリ自身はネットワーク通信を行いません。']]],
  ['2. 端末の中だけで扱う情報', [
    ['li', 'カメラの映像：コードを読み取るためだけに使い、保存も送信もしません。'],
    ['li', '写真から読み取るときに選んだ画像：端末内で解析するだけで、保存も送信もしません。'],
    ['li', '読み取り・作成の履歴と設定：端末内に保存します。アプリから削除でき、アプリを削除するとすべて消えます。'],
    ['note', '端末のバックアップ（iCloud バックアップなど）を有効にしている場合、OS の機能によって履歴がバックアップに含まれることがあります。'],
  ]],
  ['3. アクセス権限', [
    ['p', 'いずれも、その機能を使うときにだけ OS の確認画面が出ます。'],
    ['li', 'カメラ：コードの読み取り'],
    ['li', '写真ライブラリへの追加：作成した QR コードの保存'],
    ['li', '連絡先：読み取った連絡先を追加するとき'],
    ['li', 'Wi-Fi の設定：読み取った Wi-Fi に接続するとき'],
  ]],
];
const FAQ = [
  ['購入した Pro が反映されない', '設定画面の「購入を復元」を押してください。購入時と同じ Apple ID でサインインしている必要があります。'],
  ['返金したい', ''], ['カメラが真っ暗で使えない', ''], ['Wi-Fi に接続できない', ''], ['履歴が 30 件で消える', ''], ['対応している端末は？', ''],
];

// ---- Pictograms (24pt grid, stroke icons) ----
function pict(kind, x, y, color, s = 24) {
  const k = s / 24, g = (d) => `<g transform="translate(${x} ${y}) scale(${k})" fill="none" stroke="${color}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">${d}</g>`;
  switch (kind) {
    case 'ad': return g('<rect x="3" y="5" width="18" height="14" rx="3"/><path d="M4 20 20 4"/>');
    case 'sub': return g('<path d="M4 12a8 8 0 0 1 13.7-5.6M20 12a8 8 0 0 1-13.7 5.6"/><path d="M4 20 20 4"/>');
    case 'lock': return g('<rect x="5" y="10" width="14" height="10" rx="2.5"/><path d="M8 10V7.5a4 4 0 0 1 8 0V10"/>');
    case 'check': return g('<path d="m5 12.5 4.5 4.5L19 7.5"/>');
    case 'mail': return g('<rect x="3" y="5" width="18" height="14" rx="2.5"/><path d="m4 7 8 6 8-6"/>');
    case 'down': return g('<path d="m6 9 6 6 6-6"/>');
    case 'up': return g('<path d="m6 15 6-6 6 6"/>');
    case 'menu': return g('<path d="M4 7h16M4 12h16M4 17h16"/>');
  }
  return '';
}

// ---- Shared pieces ----
function mobileHeader(c, W, active) {
  return r(0, 0, W, 56, { fill: c.surface }) + `<line x1="0" y1="56" x2="${W}" y2="56" stroke="${c.line}"/>` +
    icon(16, 14, 28) + t(52, 34, SITE.app, { size: 16, weight: 700, fill: c.text }) +
    t(W - 16, 34, 'サポート', { size: 14, weight: active === 'support' ? 700 : 500, fill: c.brand, anchor: 'end' });
}
function mobileFooter(c, W, y) {
  const links = ['トップ', 'プライバシーポリシー', '利用規約', 'サポート'];
  let s = r(0, y, W, 176, { fill: c.footer });
  links.forEach((l, i) => { s += t(16, y + 40 + i * 28, l, { size: 14, fill: c.text }); });
  return s + t(16, y + 160, `© 2026 ${SITE.provider}`, { size: 12, fill: c.sub });
}
let frameCount = 0;
function frame(x, y, W, H, c, label, body) {
  const id = `frame${++frameCount}`;
  return `<g transform="translate(${x} ${y})">` +
    t(W / 2, -20, label, { size: 18, weight: 700, anchor: 'middle', fill: '#3A3A3C' }) +
    `<clipPath id="${id}"><rect width="${W}" height="${H}" rx="28"/></clipPath>` +
    `<rect x="-1" y="-1" width="${W + 2}" height="${H + 2}" rx="29" fill="#D1D5D4"/>` +
    `<g clip-path="url(#${id})">${r(0, 0, W, H, { fill: c.bg })}${body}</g></g>`;
}
const spec = (x, y, s) => t(x, y, s, { size: 13, fill: '#C2410C' });

// ---- Mobile pages (390 wide) ----
const MW = 390;
function mobileTop(c) {
  let s = mobileHeader(c, MW), y = 56;
  s += `<rect x="0" y="${y}" width="${MW}" height="388" fill="url(#hero)"/>`;
  s += icon(MW / 2 - 52, y + 40, 104);
  s += t(MW / 2, y + 196, SITE.app, { size: 28, weight: 800, fill: '#FFFFFF', anchor: 'middle' });
  s += t(MW / 2, y + 232, '広告なし。サブスクなし。', { size: 16, weight: 600, fill: '#FFFFFF', anchor: 'middle' });
  s += t(MW / 2, y + 260, '読み取った内容は端末の外に出ません。', { size: 16, weight: 600, fill: '#FFFFFF', anchor: 'middle' });
  s += r(MW / 2 - 104, y + 296, 208, 48, { rx: 12, fill: 'rgba(255,255,255,0.16)', stroke: 'rgba(255,255,255,0.5)' });
  s += t(MW / 2, y + 326, 'App Store で近日公開', { size: 15, weight: 700, fill: '#FFFFFF', anchor: 'middle' });
  y += 388 + 48;
  s += t(16, y, '3つの約束', { size: 22, weight: 800, fill: c.text }); y += 20;
  for (const [k, title, body] of PROMISES) {
    s += r(16, y, MW - 32, 104, { rx: 16, fill: c.surface, stroke: c.line });
    s += `<circle cx="48" cy="${y + 40}" r="20" fill="${c.brandSoft}"/>` + pict(k, 36, y + 28, c.brand);
    s += t(80, y + 46, title, { size: 17, weight: 700, fill: c.text });
    s += para(80, y + 74, body, MW - 32 - 80, { size: 14, fill: c.sub, lh: 22 }).svg;
    y += 116;
  }
  y += 40;
  s += t(16, y, 'できること', { size: 22, weight: 800, fill: c.text }); y += 28;
  for (const f of FEATURES) { s += pict('check', 16, y - 18, c.brand, 22) + t(48, y, f, { size: 16, fill: c.text }); y += 36; }
  y += 28;
  s += t(16, y, '価格', { size: 22, weight: 800, fill: c.text }); y += 20;
  s += r(16, y, MW - 32, 232, { rx: 16, fill: c.surface, stroke: c.line });
  s += t(36, y + 40, '無料', { size: 17, weight: 700, fill: c.text }) + t(MW - 36, y + 40, '¥0', { size: 17, weight: 700, fill: c.text, anchor: 'end' });
  s += t(36, y + 68, '読み取り・テキストと URL の作成・履歴 30 件', { size: 14, fill: c.sub });
  s += `<line x1="36" y1="${y + 96}" x2="${MW - 36}" y2="${y + 96}" stroke="${c.line}"/>`;
  s += t(36, y + 134, 'Pro（買い切り）', { size: 17, weight: 700, fill: c.brand }) + t(MW - 36, y + 134, '¥800', { size: 17, weight: 800, fill: c.brand, anchor: 'end' });
  s += t(36, y + 162, '履歴の無制限保存・すべての種類の作成', { size: 14, fill: c.sub });
  s += t(36, y + 186, '・CSV 書き出し', { size: 14, fill: c.sub });
  s += t(36, y + 212, '一度の購入で、同じ Apple ID の端末で使えます。', { size: 12, fill: c.sub });
  y += 232 + 48;
  s += mobileFooter(c, MW, y);
  return { svg: s, h: y + 176 };
}
function legalBody(c, x, y, width, sections) {
  let s = '';
  for (const [h, blocks] of sections) {
    s += t(x, y, h, { size: 20, weight: 700, fill: c.text }); y += 34;
    for (const [kind, text] of blocks) {
      if (kind === 'p') { const p = para(x, y, text, width, { fill: c.text }); s += p.svg; y += p.height + 8; }
      if (kind === 'li') {
        s += `<circle cx="${x + 6}" cy="${y - 5}" r="3" fill="${c.brand}"/>`;
        const p = para(x + 20, y, text, width - 20, { fill: c.text }); s += p.svg; y += p.height + 4;
      }
      if (kind === 'note') {
        const p = para(x + 16, y + 26, text, width - 32, { size: 14, fill: c.text, lh: 24 });
        s += r(x, y, width, p.height + 26, { rx: 12, fill: c.brandSoft }) + `<rect x="${x}" y="${y}" width="4" height="${p.height + 26}" rx="2" fill="${c.brand}"/>` + p.svg;
        y += p.height + 26 + 16;
      }
    }
    y += 32;
  }
  return { svg: s, y };
}
function mobilePrivacy(c) {
  let s = mobileHeader(c, MW), y = 56 + 44;
  s += t(16, y, 'プライバシーポリシー', { size: 26, weight: 800, fill: c.text }); y += 30;
  s += t(16, y, SITE.updated, { size: 13, fill: c.sub }); y += 24;
  const lead = para(36, y + 34, PRIVACY_LEAD, MW - 72, { size: 16, weight: 600, fill: c.text, lh: 28 });
  s += r(16, y, MW - 32, lead.height + 40, { rx: 16, fill: c.brandSoft }) + lead.svg; y += lead.height + 40 + 24;
  s += r(16, y, MW - 32, 44 + PRIVACY_TOC.length * 30 + 12, { rx: 16, fill: c.surface, stroke: c.line });
  s += t(36, y + 34, '目次', { size: 15, weight: 700, fill: c.sub });
  PRIVACY_TOC.forEach((l, i) => { s += t(36, y + 68 + i * 30, `${i + 1}. ${l}`, { size: 15, fill: c.brand }); });
  y += 44 + PRIVACY_TOC.length * 30 + 12 + 44;
  const body = legalBody(c, 16, y, MW - 32, PRIVACY_SECTIONS);
  s += body.svg; y = body.y;
  s += t(MW / 2, y, '（4〜9 も同じ組み方で続く）', { size: 13, fill: c.sub, anchor: 'middle' }); y += 40;
  s += mobileFooter(c, MW, y);
  return { svg: s, h: y + 176 };
}
function mobileSupport(c) {
  let s = mobileHeader(c, MW, 'support'), y = 56 + 44;
  s += t(16, y, 'サポート', { size: 26, weight: 800, fill: c.text }); y += 24;
  s += r(16, y, MW - 32, 132, { rx: 16, fill: c.surface, stroke: c.line });
  s += `<circle cx="48" cy="${y + 40}" r="20" fill="${c.brandSoft}"/>` + pict('mail', 36, y + 28, c.brand);
  s += t(80, y + 46, 'お問い合わせ', { size: 17, weight: 700, fill: c.text });
  s += t(36, y + 86, SITE.email, { size: 15, weight: 600, fill: c.brand });
  s += t(36, y + 112, '不具合のご報告・ご意見はメールでお送りください。', { size: 13, fill: c.sub });
  y += 132 + 44;
  s += t(16, y, 'よくある質問', { size: 22, weight: 800, fill: c.text }); y += 20;
  FAQ.forEach(([q, a], i) => {
    const open = i === 0;
    const ans = open ? para(36, y + 92, a, MW - 72, { size: 15, fill: c.sub, lh: 26 }) : { svg: '', height: 0 };
    const h = open ? 76 + ans.height + 16 : 60;
    s += r(16, y, MW - 32, h, { rx: 14, fill: c.surface, stroke: c.line });
    s += t(36, y + 37, q, { size: 16, weight: 600, fill: c.text }) + pict(open ? 'up' : 'down', MW - 56, y + 18, c.sub);
    if (open) s += `<line x1="36" y1="${y + 60}" x2="${MW - 36}" y2="${y + 60}" stroke="${c.line}"/>` + ans.svg;
    y += h + 10;
  });
  y += 38;
  s += mobileFooter(c, MW, y);
  return { svg: s, h: y + 176 };
}

// ---- Desktop pages (1280 wide) ----
const DW = 1280, CW = 1040, CX = (DW - CW) / 2;
function desktopHeader(c, active) {
  const nav = [['トップ', 'top'], ['プライバシーポリシー', 'privacy'], ['利用規約', 'terms'], ['サポート', 'support']];
  let s = r(0, 0, DW, 64, { fill: c.surface }) + `<line x1="0" y1="64" x2="${DW}" y2="64" stroke="${c.line}"/>`;
  s += icon(CX, 16, 32) + t(CX + 44, 39, SITE.app, { size: 18, weight: 700, fill: c.text });
  let x = CX + CW;
  for (const [l, k] of [...nav].reverse()) {
    s += t(x, 38, l, { size: 15, weight: k === active ? 700 : 500, fill: k === active ? c.brand : c.text, anchor: 'end' });
    if (k === active) s += r(x - l.length * 15, 62, l.length * 15, 2, { fill: c.brand });
    x -= l.length * 15 + 32;
  }
  return s;
}
function desktopFooter(c, y) {
  let s = r(0, y, DW, 120, { fill: c.footer });
  s += t(CX, y + 52, 'トップ　　プライバシーポリシー　　利用規約　　サポート', { size: 14, fill: c.text });
  s += t(CX, y + 84, `© 2026 ${SITE.provider}`, { size: 13, fill: c.sub });
  return s;
}
function desktopTop(c) {
  let s = desktopHeader(c, 'top'), y = 64;
  s += `<rect x="0" y="${y}" width="${DW}" height="440" fill="url(#hero)"/>`;
  s += t(CX, y + 150, SITE.app, { size: 48, weight: 800, fill: '#FFFFFF' });
  s += t(CX, y + 206, '広告なし。サブスクなし。', { size: 22, weight: 600, fill: '#FFFFFF' });
  s += t(CX, y + 242, '読み取った内容は端末の外に出ません。', { size: 22, weight: 600, fill: '#FFFFFF' });
  s += t(CX, y + 284, 'iPhone と iPad の QR コード・バーコードリーダー（iOS 17 以降）', { size: 16, fill: 'rgba(255,255,255,0.86)' });
  s += r(CX, y + 316, 220, 52, { rx: 12, fill: 'rgba(255,255,255,0.16)', stroke: 'rgba(255,255,255,0.5)' });
  s += t(CX + 110, y + 348, 'App Store で近日公開', { size: 16, weight: 700, fill: '#FFFFFF', anchor: 'middle' });
  s += icon(CX + CW - 260, y + 90, 260);
  y += 440 + 72;
  s += t(DW / 2, y, '3つの約束', { size: 30, weight: 800, fill: c.text, anchor: 'middle' }); y += 36;
  const cw = (CW - 48) / 3;
  PROMISES.forEach(([k, title, body], i) => {
    const x = CX + i * (cw + 24);
    s += r(x, y, cw, 200, { rx: 16, fill: c.surface, stroke: c.line });
    s += `<circle cx="${x + 52}" cy="${y + 56}" r="24" fill="${c.brandSoft}"/>` + pict(k, x + 38, y + 42, c.brand, 28);
    s += t(x + 28, y + 118, title, { size: 20, weight: 700, fill: c.text });
    s += para(x + 28, y + 150, body, cw - 56, { size: 15, fill: c.sub, lh: 26 }).svg;
  });
  y += 200 + 80;
  s += t(CX, y, 'できること', { size: 26, weight: 800, fill: c.text });
  FEATURES.forEach((f, i) => { const fx = CX + (i % 2) * 300, fy = y + 52 + Math.floor(i / 2) * 44; s += pict('check', fx, fy - 18, c.brand, 22) + t(fx + 32, fy, f, { size: 16, fill: c.text }); });
  const px = CX + 640, pw = CW - 640;
  s += t(px, y, '価格', { size: 26, weight: 800, fill: c.text });
  s += r(px, y + 24, pw, 200, { rx: 16, fill: c.surface, stroke: c.line });
  s += t(px + 28, y + 64, '無料', { size: 17, weight: 700, fill: c.text }) + t(px + pw - 28, y + 64, '¥0', { size: 17, weight: 700, fill: c.text, anchor: 'end' });
  s += t(px + 28, y + 92, '読み取り・テキストと URL の作成・履歴 30 件', { size: 14, fill: c.sub });
  s += `<line x1="${px + 28}" y1="${y + 116}" x2="${px + pw - 28}" y2="${y + 116}" stroke="${c.line}"/>`;
  s += t(px + 28, y + 152, 'Pro（買い切り）', { size: 17, weight: 700, fill: c.brand }) + t(px + pw - 28, y + 152, '¥800', { size: 17, weight: 800, fill: c.brand, anchor: 'end' });
  s += t(px + 28, y + 180, '履歴の無制限保存・全種類の作成・CSV 書き出し', { size: 14, fill: c.sub });
  s += t(px + 28, y + 204, '一度の購入で、同じ Apple ID の端末で使えます。', { size: 12, fill: c.sub });
  y += 224 + 80;
  s += desktopFooter(c, y);
  return { svg: s, h: y + 120 };
}
function desktopPrivacy(c) {
  let s = desktopHeader(c, 'privacy'), y = 64 + 64;
  const tocX = CX, tocW = 260, bodyX = CX + tocW + 60, bodyW = 680;
  // Sticky table of contents on the left.
  s += t(tocX, y + 8, '目次', { size: 14, weight: 700, fill: c.sub });
  PRIVACY_TOC.forEach((l, i) => {
    const ty = y + 44 + i * 34;
    if (i === 1) s += r(tocX - 12, ty - 22, tocW, 32, { rx: 8, fill: c.brandSoft });
    s += t(tocX, ty, `${i + 1}. ${l}`, { size: 14, weight: i === 1 ? 700 : 400, fill: i === 1 ? c.brand : c.text });
  });
  s += spec(tocX, y + 44 + PRIVACY_TOC.length * 34 + 16, '↑ スクロールしても上部に固定');
  s += t(bodyX, y + 16, 'プライバシーポリシー', { size: 34, weight: 800, fill: c.text });
  s += t(bodyX, y + 52, SITE.updated, { size: 14, fill: c.sub });
  let by = y + 80;
  const lead = para(bodyX + 28, by + 40, PRIVACY_LEAD, bodyW - 56, { size: 17, weight: 600, fill: c.text, lh: 30 });
  s += r(bodyX, by, bodyW, lead.height + 48, { rx: 16, fill: c.brandSoft }) + lead.svg; by += lead.height + 48 + 56;
  const body = legalBody(c, bodyX, by, bodyW, PRIVACY_SECTIONS);
  s += body.svg; by = body.y;
  s += t(bodyX + bodyW / 2, by, '（4〜9 も同じ組み方で続く）', { size: 13, fill: c.sub, anchor: 'middle' }); by += 56;
  s += desktopFooter(c, by);
  return { svg: s, h: by + 120 };
}

// ---- Assemble ----
function defs(c) {
  return `<defs><clipPath id="iconMask"><rect width="512" height="512" rx="114.5"/></clipPath>` +
    `<g id="appicon"><image width="512" height="512" clip-path="url(#iconMask)" href="data:image/png;base64,${ICON}"/></g>` +
    `<linearGradient id="hero" x1="0" y1="0" x2="0.4" y2="1"><stop offset="0" stop-color="${LIGHT.heroFrom}"/><stop offset="1" stop-color="${LIGHT.heroTo}"/></linearGradient>` +
    `<linearGradient id="heroDark" x1="0" y1="0" x2="0.4" y2="1"><stop offset="0" stop-color="${DARK.heroFrom}"/><stop offset="1" stop-color="${DARK.heroTo}"/></linearGradient></defs>`;
}
function doc(W, H, title, note, body) {
  W = Math.ceil(W); H = Math.ceil(H);
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}" font-family="${FONT}">` +
    defs() + r(0, 0, W, H, { fill: '#F2F2F4' }) +
    t(48, 64, title, { size: 30, weight: 800, fill: '#1C1C1E' }) + t(48, 98, note, { size: 16, fill: '#636366' }) + body + '</svg>';
}

// Mobile sheet
{
  const pages = [
    ['トップ（/）', mobileTop(LIGHT)],
    ['プライバシーポリシー（/privacy/）', mobilePrivacy(LIGHT)],
    ['サポート（/support/）', mobileSupport(LIGHT)],
    ['プライバシーポリシー・ダーク', mobilePrivacy(DARK)],
  ];
  const gap = 64, top = 180;
  const H = Math.max(...pages.map(([, p]) => p.h)) + top + 120;
  let body = '';
  pages.forEach(([label, p], i) => {
    const x = 48 + i * (MW + gap);
    body += frame(x, top, MW, p.h, i === 3 ? DARK : LIGHT, label, p.svg);
  });
  // Annotations
  const ax = 48 + 4 * (MW + gap) - 24;
  const notes = [
    'スマートフォン幅 390pt（最小 360pt で横スクロールなし）',
    '左右余白 16pt ／ セクション間 48pt',
    'ヘッダー 56pt：アイコン 28pt＋アプリ名、右にサポート',
    'ヒーロー：#0F7F68→#0A5F4E、白文字 4.93:1 以上',
    'カード：角丸 16、境界線 1px',
    '本文 16pt／行間 1.85、法務ページ見出し h1 26pt・h2 20pt',
    'よくある質問は <details>（JS なしで開閉）',
    'ダーク：背景 #0E1211、文字 #ECEFEE、主色 #3CC7A6',
    'App Store バッジは公開後に差し替え（今は「近日公開」）',
  ];
  notes.forEach((n, i) => { body += spec(ax, top + 20 + i * 26, '・' + n); });
  const W = ax + 460;
  fs.writeFileSync(path.join(OUT, '01_mobile.svg'), doc(W, H, '誠実QRリーダー 公開サイト — スマートフォン', '静的 HTML（Next.js static export）／ 広告・解析・Cookie・外部フォントなし', body));
}
// Desktop sheet
{
  const top = 180, gap = 80;
  const a = desktopTop(LIGHT), b = desktopPrivacy(LIGHT);
  let body = frame(48, top, DW, a.h, LIGHT, 'トップ（/）・1280px', a.svg);
  body += frame(48 + DW + gap, top, DW, b.h, LIGHT, 'プライバシーポリシー（/privacy/）・1280px', b.svg);
  const W = 48 + DW * 2 + gap + 48, H = Math.max(a.h, b.h) + top + 80;
  fs.writeFileSync(path.join(OUT, '02_desktop.svg'), doc(W, H, '誠実QRリーダー 公開サイト — デスクトップ', 'コンテンツ幅 1040px（中央寄せ）／ 法務ページは目次 260px＋本文 680px', body));
}
console.log('wrote 01_mobile.svg, 02_desktop.svg');
