// Keyboard avoidance, thumb reach and sheet rules (iPhone), and pointer / hardware keyboard (iPad).
const fs = require('fs');
const path = require('path');
const L = require('./lib');
const S = require('./screens');
const D = require('./devices');
const { C, t, measure, iconLabel, rect, icon, statusBar, phone, doc, glassCircle } = L;

const OUT = process.argv[2];
const W1 = 393, GAP = 90, PAD = 70;

function header(title, lines) {
  return t(PAD - 13, 48, title, { size: 26, weight: 800, fill: C.label }) +
    lines.map((l, i) => t(PAD - 13, 78 + i * 22, l, { size: 15, fill: C.secondary })).join('');
}

// ---------- software keyboard ----------
// Japanese romaji keyboard with the predictive bar. Height ~332pt on a 6.3-inch iPhone (approximate).
const KB_Y = 520;
const KB_BG = '#D2D5DB';
function key(x, y, w, label, o = {}) {
  return rect(x, y, w, 42, { rx: 8, fill: o.fill || '#FFFFFF' }) +
    (label ? t(x + w / 2, y + 28, label, { size: o.size || 20, weight: o.weight || 400, fill: o.color || C.label, anchor: 'middle' }) : '');
}
function keyboard(returnLabel, returnProminent, bottomKeys) {
  let s = rect(0, KB_Y, 393, 852 - KB_Y, { fill: KB_BG });
  // predictive candidates
  ['候補', '変換', '予測'].forEach((w, i) => {
    s += t(65 + i * 131, KB_Y + 28, w, { size: 16, fill: '#3A3A3C', anchor: 'middle' });
    if (i < 2) s += `<line x1="${131 + i * 131}" y1="${KB_Y + 12}" x2="${131 + i * 131}" y2="${KB_Y + 34}" stroke="#AEB1B7"/>`;
  });
  const rows = ['qwertyuiop', 'asdfghjkl', 'zxcvbnm'];
  const kw = (393 - 6 - 9 * 6) / 10;
  let y = KB_Y + 52;
  s += [...rows[0]].map((c, i) => key(3 + i * (kw + 6), y, kw, c)).join('');
  y += 54;
  s += [...rows[1]].map((c, i) => key(3 + kw / 2 + 3 + i * (kw + 6), y, kw, c)).join('');
  y += 54;
  s += key(3, y, kw * 1.3, '', { fill: '#ABB0BA' }) + icon('chevronUp', 3 + kw * 0.65 - 11, y + 10, 22, C.label);
  s += [...rows[2]].map((c, i) => key(3 + kw * 1.3 + 13 + i * (kw + 6), y, kw, c)).join('');
  s += key(393 - 3 - kw * 1.3, y, kw * 1.3, '', { fill: '#ABB0BA' }) + icon('deleteKey', 393 - 3 - kw * 0.65 - 11, y + 10, 22, C.label);
  y += 54;
  const retW = 96;
  s += key(3, y, 46, '123', { fill: '#ABB0BA', size: 15 });
  let x = 55;
  for (const [label, w] of bottomKeys) { s += key(x, y, w, label, { size: label === '空白' ? 15 : 18 }); x += w + 6; }
  s += key(393 - 3 - retW, y, retW, returnLabel, returnProminent
    ? { fill: C.accentFill, color: '#fff', size: 16, weight: 700 }
    : { fill: '#ABB0BA', size: 16, weight: 600 });
  return s + rect(129.5, 838, 134, 5, { rx: 2.5, fill: '#000' });
}

// "QRコードを作成" stays directly above the keyboard (safeAreaInset), so the keyboard never hides it.
const BAR_Y = KB_Y - 76;
function pinnedCreate() {
  return rect(0, BAR_Y, 393, 76, { fill: C.bg }) + `<line x1="0" y1="${BAR_Y}" x2="393" y2="${BAR_Y}" stroke="${C.separator}"/>` +
    rect(16, BAR_Y + 12, 361, 52, { rx: 14, fill: C.accentFill }) +
    iconLabel(196.5, BAR_Y + 44, 'qr', 22, 'QRコードを作成', { size: 17, weight: 700, fill: '#fff' });
}
function formNav(title) {
  return rect(0, 0, 393, 852, { fill: C.bg }) + statusBar(false) +
    glassCircle(38, 82, 22, 'chevronLeft', false) + t(196.5, 88, title, { size: 17, weight: 700, anchor: 'middle' });
}
function field(y, label, value, o = {}) {
  let s = t(32, y + 24, label, { size: 13, weight: 600, fill: C.secondary });
  const vo = { size: 17, mono: !!o.mono, fill: value ? C.label : C.placeholder };
  s += t(32, y + 50, value || o.placeholder || '', vo);
  if (o.focused) s += rect(32 + measure(value, vo) + 1, y + 34, 2, 21, { fill: C.accent });
  if (!o.last) s += `<line x1="32" y1="${y + 66}" x2="377" y2="${y + 66}" stroke="${C.separator}"/>`;
  return s;
}
function createContactKeyboard() {
  let s = formNav('連絡先');
  // The form has scrolled so the focused field sits above the pinned button.
  const gy = 112;
  s += `<clipPath id="kbc"><rect x="0" y="108" width="393" height="${BAR_Y - 108}"/></clipPath><g clip-path="url(#kbc)">` +
    rect(16, gy, 361, 66 * 5, { rx: 12, fill: C.card }) +
    field(gy, '名', '太郎') + field(gy + 66, '会社', '誠実商事') + field(gy + 132, '役職', '営業部長', { focused: true }) +
    field(gy + 198, '電話番号', '', { placeholder: '例：03-1234-5678' }) + field(gy + 264, 'メールアドレス', '') + '</g>';
  s += rect(386, 150, 3.5, 120, { rx: 1.75, fill: 'rgba(0,0,0,0.3)' });
  return s + pinnedCreate() + keyboard('次へ', false, [['、', 40], ['空白', 120], ['。', 40]]);
}
function createURLKeyboard() {
  let s = formNav('URL');
  s += t(32, 128, '入力内容', { size: 13, fill: C.secondary }) +
    rect(16, 136, 361, 70, { rx: 12, fill: C.card }) + field(136, 'URL', 'https://www.exa', { focused: true, mono: true, last: true });
  return s + pinnedCreate() + keyboard('完了', true, [['.', 40], ['/', 40], ['.com', 120]]);
}

// ---------- thumb reach ----------
function callout(x, y, w, lines, anchorX, anchorY) {
  const h = 16 + lines.length * 20;
  return `<line x1="${anchorX}" y1="${anchorY}" x2="${Math.min(Math.max(anchorX, x + 12), x + w - 12)}" y2="${anchorY < y ? y : y + h}" stroke="#fff" stroke-width="1.5"/>` +
    rect(x, y, w, h, { rx: 10, fill: 'rgba(0,0,0,0.72)', stroke: 'rgba(255,255,255,0.5)' }) +
    lines.map((l, i) => t(x + 12, y + 26 + i * 20, l, { size: 13, weight: i === 0 ? 700 : 400, fill: '#fff' })).join('');
}
function scanReach() {
  return S.scanA() +
    `<defs><radialGradient id="thumb" cx="0.5" cy="1" r="0.75"><stop offset="0" stop-color="${C.accentOnDark}" stop-opacity=".42"/><stop offset=".7" stop-color="${C.accentOnDark}" stop-opacity=".16"/><stop offset="1" stop-color="${C.accentOnDark}" stop-opacity="0"/></radialGradient></defs>` +
    rect(0, 520, 393, 332, { fill: 'url(#thumb)' }) +
    `<line x1="16" y1="566" x2="377" y2="566" stroke="#fff" stroke-opacity=".7" stroke-dasharray="6 6"/>` +
    t(377, 558, '親指が届きやすい範囲', { size: 12, weight: 700, fill: '#fff', anchor: 'end' }) +
    callout(150, 118, 226, ['上部：情報表示のみ', '操作ボタンは置かない'], 300, 102) +
    callout(16, 578, 250, ['主な操作は下部（タブバーの上）', '写真から・連続スキャン・ライト'], 92, 650);
}

// ---------- sheet rules ----------
function badge(cx, cy, n) {
  return `<circle cx="${cx}" cy="${cy}" r="13" fill="${C.red}" stroke="#fff" stroke-width="2"/>` +
    t(cx, cy + 5, String(n), { size: 14, weight: 800, fill: '#fff', anchor: 'middle' });
}
function sheetRules() {
  return S.resultURL() +
    badge(70, 248, 1) + badge(232, 236, 2) + badge(30, 664, 3) + badge(360, 214, 4);
}

// ---------- iPad: pointer ----------
function contextMenu(x, y, items) {
  const w = 270, ih = 44;
  const seps = items.filter(i => i === '-').length;
  const h = (items.length - seps) * ih + seps * 9 + 12;
  let s = `<g filter="url(#shadowLg)">${rect(x, y, w, h, { rx: 16, fill: 'rgba(248,248,250,0.97)' })}</g>`;
  let cy = y + 6;
  for (const it of items) {
    if (it === '-') { s += rect(x, cy + 2, w, 5, { fill: 'rgba(0,0,0,0.06)' }); cy += 9; continue; }
    const [label, ic, red, hover] = it;
    if (hover) s += rect(x + 6, cy, w - 12, ih, { rx: 10, fill: 'rgba(0,0,0,0.08)' });
    s += t(x + 18, cy + 28, label, { size: 16, fill: red ? C.red : C.label });
    s += icon(ic, x + w - 40, cy + 11, 22, red ? C.red : C.label, false);
    cy += ih;
  }
  return s;
}
function pointerAt(x, y) {
  return `<circle cx="${x}" cy="${y}" r="10" fill="rgba(60,60,67,0.45)" stroke="#fff" stroke-width="1.5"/>`;
}
function ipadHistoryPointer() {
  let s = D.ipadHistory();
  // Hover: system highlight on the list row under the pointer.
  s += rect(20, 506, 340, 64, { fill: 'rgba(0,0,0,0.05)' });
  // Secondary click (two-finger tap / right click) opens the context menu.
  s += contextMenu(250, 540, [['お気に入りに追加', 'star'], ['内容をコピー', 'copy', false, true], ['共有', 'share'], '-', ['削除', 'trash', true]]);
  s += pointerAt(404, 616);
  // Pointer highlight on a toolbar button (system highlight effect).
  s += rect(1180 - 24 - 196 + 8 + 46, 100, 40, 36, { rx: 12, fill: 'rgba(0,0,0,0.08)' });
  return s;
}

// ---------- iPad: keyboard shortcuts ----------
// Key combination drawn right-aligned at xr; 'return' / 'delete' are drawn as key symbols.
function combo(xr, baseline, keys) {
  let x = xr, s = '';
  const o = { size: 15, weight: 600, fill: C.secondary };
  for (const k of [...keys].reverse()) {
    if (k === 'return' || k === 'delete') {
      x -= 20;
      s += icon(k === 'return' ? 'returnKey' : 'deleteKey', x, baseline - 15, 20, C.secondary);
    } else {
      x -= measure(k, o);
      s += t(x, baseline, k, o);
    }
    x -= 3;
  }
  return s;
}
function shortcutPanel(x, y) {
  const w = 760, colW = (w - 28 * 2 - 40) / 2;
  const groups = [
    ['タブ', [['スキャン', ['⌘', '1']], ['履歴', ['⌘', '2']], ['作成', ['⌘', '3']], ['設定', ['⌘', '4']]]],
    ['スキャン', [['写真から読み取る', ['⌘', 'O']]]],
    ['読み取り結果', [['主な操作（開く・接続・追加）', ['⌘', 'return']], ['内容をコピー', ['⇧', '⌘', 'C']], ['お気に入りの切り替え', ['⌘', 'D']]]],
    ['履歴', [['検索', ['⌘', 'F']], ['選択した履歴を削除', ['⌘', 'delete']]]],
    ['作成', [['QRコードを作成', ['⌘', 'return']]]],
    ['シート', [['閉じる', ['esc']]]],
  ];
  const cols = [[groups[0], groups[1], groups[5]], [groups[2], groups[3], groups[4]]];
  const h = 430;
  let s = `<g filter="url(#shadowLg)">${rect(x, y, w, h, { rx: 24, fill: 'rgba(250,250,252,0.97)' })}</g>` +
    t(x + 28, y + 42, '誠実QRリーダー', { size: 20, weight: 800 });
  cols.forEach((col, ci) => {
    const cx = x + 28 + ci * (colW + 40);
    let cy = y + 82;
    for (const [title, items] of col) {
      s += t(cx, cy, title, { size: 13, weight: 700, fill: C.secondary });
      cy += 10;
      for (const [label, keys] of items) {
        cy += 30;
        s += t(cx, cy, label, { size: 16 });
        s += combo(cx + colW, cy, keys);
      }
      cy += 44;
    }
  });
  return s;
}
function ipadShortcuts() {
  let s = D.ipadHistory() + rect(0, 0, 1180, 820, { fill: 'rgba(0,0,0,0.25)' });
  return s + shortcutPanel(210, 200);
}

// ---------- write ----------
function writePhones(name, title, lines, screens) {
  const w = PAD * 2 + screens.length * W1 + (screens.length - 1) * GAP;
  const oy = 120 + lines.length * 22;
  const body = header(title, lines) + screens.map(([inner, cap], i) => phone(PAD + i * (W1 + GAP), oy, inner, cap)).join('\n');
  fs.writeFileSync(path.join(OUT, name), doc(w, oy + 852 + 110, body, title));
}
writePhones('13_keyboard_reach_sheets.svg', '13 キーボード・操作位置・シート（iPhone）', [
  'キーボード表示中も「QRコードを作成」はキーボードの直上に固定（キーボードに隠れない）。入力中の項目はフォームが自動でスクロールして表示し、改行キーで次の項目へ。',
  '主な操作は画面の下部〜中部（親指の届く範囲）に置く。画面上部は情報表示だけにする。',
  'シートはすべて同じ開閉ルール：①閉じる×は左上（外付けキーボードの esc でも閉じる） ②グラバーと下スワイプ ③主な操作は下部に固定 ④シートの上にシートを重ねない。',
], [
  [createContactKeyboard(), 'A. 連絡先の作成（キーボード表示中）'],
  [createURLKeyboard(), 'B. URLの作成（キーボード表示中）'],
  [scanReach(), 'C. スキャン：親指の届く範囲'],
  [sheetRules(), 'D. 結果シート：開閉ルール①〜④'],
]);

const PW = 1180, PH = 820;
function writeIpad() {
  const W = 70 * 2 + PW * 2 + 120;
  let body = t(70, 56, '14 iPad：ポインタとハードウェアキーボード', { size: 30, weight: 800 }) + [
    'ポインタ：ボタンとリストはシステム標準のハイライト。自作のボタン・カードにも同じ効果を付ける。副ボタンのクリック（右クリック・2本指タップ）で履歴の操作メニューを開く。',
    'キーボード：よく使う操作だけにショートカットを付ける（HIG Keyboards）。標準の意味（⌘F＝検索、⌘O＝開く、esc＝キャンセル）は変えない。',
    '一覧の表示方法は iPadOS のバージョンで異なる（⌘ 長押しの一覧／メニューバー）。右の図は内容を示す概念図。',
  ].map((l, i) => t(70, 88 + i * 22, l, { size: 15, fill: C.secondary })).join('');
  const y = 200, gx = 92;
  body += ipadFrameLocal(gx, y, ipadHistoryPointer(), 'A. 履歴：ポインタのハイライトと右クリックメニュー', 'サイドバー（一覧）＋詳細。選択中の行は持続ハイライト、ポインタ下の行は薄いハイライト');
  body += ipadFrameLocal(gx + PW + 76, y, ipadShortcuts(), 'B. キーボードショートカット', 'ショートカットはメニュー項目として登録し、OS の一覧に表示される');
  fs.writeFileSync(path.join(OUT, '14_ipad_pointer_keyboard.svg'), doc(W, y + PH + 130, body, '14 iPad ポインタとキーボード'));
}
function ipadFrameLocal(ox, oy, inner, caption, sub) {
  const id = D.uid('ipf');
  return `<g transform="translate(${ox} ${oy})">
    <rect x="-22" y="-22" width="${PW + 44}" height="${PH + 44}" rx="40" fill="#1C1C1E"/>
    <clipPath id="${id}"><rect x="0" y="0" width="${PW}" height="${PH}" rx="20"/></clipPath><g clip-path="url(#${id})">${inner}</g>
  </g>` + D.caps(ox + PW / 2, oy + PH + 52, caption, sub);
}
writeIpad();
console.log('ok');
