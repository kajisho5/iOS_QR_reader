const fs = require('fs');
const path = require('path');
const { C, t, rect, icon, esc } = require('./lib');

const W = 1640, H = 1080;
let s = '';
const box = (x, y, w, h, title, lines = [], o = {}) => {
  s += `<g filter="url(#sh)">${rect(x, y, w, h, { rx: 14, fill: o.fill || '#fff', stroke: o.stroke || '#D9DCE1', sw: o.sw || 1.2, dash: o.dash })}</g>`;
  if (o.ic) s += icon(o.ic, x + 16, y + 15, 22, o.icColor || C.accent);
  s += t(x + (o.ic ? 46 : 18), y + 32, title, { size: 16, weight: 800, fill: o.titleFill || C.label });
  lines.forEach((l, i) => { s += t(x + 18, y + 58 + i * 21, l, { size: 13, fill: C.secondary }); });
};
const arrow = (d, o = {}) => {
  s += `<path d="${d}" fill="none" stroke="${o.color || (o.dash ? C.accent : '#8A9099')}" stroke-width="${o.w || 2}"${o.dash ? ' stroke-dasharray="7 6"' : ''} marker-end="url(#${o.dash ? 'ahA' : 'ah'})"/>`;
  if (o.label) s += t(o.lx, o.ly, o.label, { size: 12, weight: 600, fill: o.dash ? C.accent : C.secondary, anchor: o.anchor || 'start' });
};

s += t(60, 56, '00 画面遷移', { size: 28, weight: 800 });
s += t(60, 86, '実線＝通常の遷移（sheet / push / 外部アプリ）　破線＝Proゲート（ユーザーがロック機能を押した時だけ課金画面を表示）', { size: 15, fill: C.secondary });

// launch
box(60, 120, 180, 64, 'App起動', [], { ic: 'qr' });
arrow('M240 152H318');
box(320, 120, 1260, 64, 'RootView（TabView）— 初期タブ＝スキャン。スプラッシュ／チュートリアル／起動時課金画面なし', [], { ic: 'viewfinder', fill: C.accentSoft, stroke: C.accent });

const cols = [60, 450, 840, 1230], CW = 350;
const tabs = [['スキャン', 'viewfinder'], ['履歴', 'clock'], ['作成', 'plusSquare'], ['設定', 'gear']];
tabs.forEach(([n, ic], i) => {
  const cx = cols[i] + CW / 2;
  arrow(`M${cx} 184V222`);
  s += rect(cols[i], 196 + 30, CW, 0, {});
});

// Scan column
let x = cols[0];
box(x, 226, CW, 132, 'ScannerView', ['カメラ即起動（AVCaptureSession）', 'トーチ ON/OFF ・ 連続スキャン切替', '触覚／音（設定値に従う）'], { ic: 'viewfinder' });
box(x, 398, 165, 92, 'PhotosPicker', ['写真1枚を選択', '→ Visionで検出'], { ic: 'photo' });
box(x + 185, 398, 165, 92, '連続トレイ', ['今回の読取一覧', '重複は記録しない'], { ic: 'repeat' });
arrow(`M${x + 82} 358V396`); arrow(`M${x + 268} 358V396`);
box(x, 530, CW, 156, 'ResultSheet（.sheet）', ['種類判定: URL/Wi-Fi/連絡先/メール/電話/', 'SMS/地図座標/テキスト', 'URLは全文表示 → 押した時だけ開く', 'コピー・共有・お気に入り ／ 自動保存'], { ic: 'docText', stroke: C.accent, sw: 2 });
arrow(`M${x + 82} 490V528`); arrow(`M${x + 268} 490V528`, { label: 'タップ', lx: x + 276, ly: 514 });
box(x, 726, CW, 116, '外部（ユーザー操作時のみ）', ['ブラウザ（openURL）・iOS Wi-Fi確認', 'CNContactViewController（連絡先追加）', 'メール／電話／SMS／マップ（要確認Q4）'], { ic: 'external', fill: '#F7F8FA', dash: '6 5' });
arrow(`M${x + 175} 686V724`);
box(x, 882, CW, 76, 'CameraPermissionView', ['未許可時: 設定を開く ／ 写真から読み取る'], { ic: 'cameraSlash' });
s += `<path d="M${x + 350} 300 H${x + 372} V920 H${x + 352}" fill="none" stroke="#8A9099" stroke-width="2" marker-end="url(#ah)"/>`;
s += t(x + 368, 908, '権限拒否', { size: 12, weight: 600, fill: C.secondary, anchor: 'end' });

// History column
x = cols[1];
box(x, 226, CW, 154, 'HistoryListView', ['検索（日時・種類・内容）', '種類フィルタ ・ お気に入りのみ', 'スワイプ削除／お気に入り', '無料版: 30件バナー'], { ic: 'clock' });
box(x, 420, CW, 92, 'HistoryDetail（push）', ['ResultView を再利用', '削除・お気に入り切替'], { ic: 'docText' });
arrow(`M${x + 175} 380V418`, { label: '行タップ', lx: x + 185, ly: 404 });
box(x, 552, 165, 92, 'CSV共有', ['UTF-8 CSV', '→ ShareSheet'], { ic: 'share' });
box(x + 185, 552, 165, 92, '全件削除', ['確認ダイアログ', '（取り消し不可）'], { ic: 'trash', icColor: C.red });
arrow(`M${x + 82} 512V550`, { label: 'Pro', lx: x + 90, ly: 538 });
arrow(`M${x + 268} 512V550`, { label: '編集', lx: x + 276, ly: 538 });

// Create column
x = cols[2];
box(x, 226, CW, 132, 'CreateMenuView', ['無料: テキスト・URL', 'Pro: Wi-Fi・連絡先・イベント（ロック表示）'], { ic: 'plusSquare' });
box(x, 398, CW, 112, '入力フォーム（種類別）', ['「QRコードを作成」で生成', '（CoreImage）→ この時点で履歴保存'], { ic: 'text' });
arrow(`M${x + 175} 358V396`);
box(x, 550, CW, 92, 'GeneratedQRView', ['写真に保存（追加のみ権限）', '共有（ShareLink）'], { ic: 'download' });
arrow(`M${x + 175} 510V548`);

// Settings column
x = cols[3];
box(x, 226, CW, 154, 'SettingsView', ['Pro: 購入 ／ 購入を復元', '読み取り時の音・振動', '履歴の自動保存', 'プライバシーポリシー・利用規約'], { ic: 'gear' });
box(x, 420, 165, 92, '購入を復元', ['AppStore.sync()', ''], { ic: 'repeat' });
box(x + 185, 420, 165, 92, '規約ページ', ['ブラウザで開く', '（定数URL）'], { ic: 'external' });
arrow(`M${x + 82} 380V418`); arrow(`M${x + 268} 380V418`);

// Paywall
const PY = 960;
box(450, PY, 1130, 92, 'PaywallSheet（.sheet）— 非消耗型「Pro（買い切り）」1点', ['「これは買い切りです。毎月・毎週の支払いは発生しません」「広告は今後も入れません」 ／ 価格は displayPrice をそのまま表示 ／ 購入を復元'], { ic: 'lockOpen', fill: '#FFFDF5', stroke: '#E7C66A', sw: 2 });
arrow(`M${cols[1] + 82} 644V958`, { dash: true, label: 'CSV（無料版）', lx: cols[1] + 92, ly: 760 });
arrow(`M${cols[1] + 340} 330 H${cols[1] + 362} V900 H${cols[1] + 200} V958`, { dash: true, label: '30件バナー', lx: cols[1] + 352, ly: 860, anchor: 'end' });
arrow(`M${cols[2] + 340} 300 H${cols[2] + 362} V958`, { dash: true, label: 'ロックをタップ', lx: cols[2] + 354, ly: 860, anchor: 'end' });
arrow(`M${cols[3] + 175} 512V958`, { dash: true, label: '購入', lx: cols[3] + 185, ly: 760 });

s += rect(840, 690, 330, 70, { rx: 12, fill: '#FFF6F5', stroke: '#F3B7B0' });
s += t(858, 718, '課金画面を自動では出さない', { size: 14, weight: 800, fill: C.red });
s += t(858, 742, '起動時・スキャン直後・N回目などのトリガーなし', { size: 12, fill: C.secondary });

const out = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">
<title>${esc('00 画面遷移')}</title>
<defs>
  <filter id="sh" x="-10%" y="-10%" width="120%" height="130%"><feDropShadow dx="0" dy="2" stdDeviation="4" flood-color="#000" flood-opacity=".06"/></filter>
  <marker id="ah" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0 0L10 5L0 10z" fill="#8A9099"/></marker>
  <marker id="ahA" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0 0L10 5L0 10z" fill="${C.accent}"/></marker>
</defs>
${rect(0, 0, W, H, { fill: '#F4F5F7' })}
${s}
</svg>
`;
fs.writeFileSync(path.join(process.argv[2], '00_flow.svg'), out);
console.log('ok');
