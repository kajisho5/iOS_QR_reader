// Shared drawing helpers for the SVG mockups (iPhone 393x852pt canvas).
const FONT = "-apple-system, 'SF Pro Text', 'Hiragino Sans', 'IPAPGothic', sans-serif";
const MONO = "'SF Mono', Menlo, 'IPAGothic', monospace";

const C = {
  accent: '#0E7C66', accentDark: '#0A5F4E', accentSoft: '#E3F2EE', accentOnDark: '#3CC9A6',
  label: '#1C1C1E', secondary: '#6B6B70', tertiary: '#AEAEB2', separator: '#E5E5EA',
  bg: '#F2F2F7', card: '#FFFFFF', fill: '#E3E3E8', red: '#D92D20', yellow: '#F5B400',
  kind: { url: '#2563EB', wifi: '#0E7C66', contact: '#7C3AED', email: '#DB2777', phone: '#16A34A', sms: '#0891B2', geo: '#EA580C', text: '#6B7280', event: '#C2410C' },
};

const esc = s => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

function t(x, y, str, o = {}) {
  const a = [`x="${x}"`, `y="${y}"`, `font-family="${o.mono ? MONO : FONT}"`, `font-size="${o.size || 15}"`, `fill="${o.fill || C.label}"`];
  if (o.weight) a.push(`font-weight="${o.weight}"`);
  if (o.anchor) a.push(`text-anchor="${o.anchor}"`);
  if (o.ls) a.push(`letter-spacing="${o.ls}"`);
  if (o.opacity) a.push(`opacity="${o.opacity}"`);
  const body = Array.isArray(str)
    ? str.map(p => `<tspan${p.fill ? ` fill="${p.fill}"` : ''}${p.weight ? ` font-weight="${p.weight}"` : ''}>${esc(p.s)}</tspan>`).join('')
    : esc(str);
  return `<text ${a.join(' ')}>${body}</text>`;
}

const rect = (x, y, w, h, o = {}) =>
  `<rect x="${x}" y="${y}" width="${w}" height="${h}"${o.rx != null ? ` rx="${o.rx}"` : ''} fill="${o.fill || 'none'}"${o.stroke ? ` stroke="${o.stroke}" stroke-width="${o.sw || 1}"` : ''}${o.opacity ? ` opacity="${o.opacity}"` : ''}${o.dash ? ` stroke-dasharray="${o.dash}"` : ''}${o.filter ? ` filter="${o.filter}"` : ''}/>`;

// Icons drawn on a 24x24 grid, stroke based unless noted.
const ICON = {
  qr: c => `<g fill="${c}"><path d="M3 3h7v7H3zM5 5v3h3V5zM14 3h7v7h-7zM16 5v3h3V5zM3 14h7v7H3zM5 16v3h3v-3z" fill-rule="evenodd"/><rect x="14" y="14" width="3" height="3"/><rect x="18" y="18" width="3" height="3"/><rect x="18" y="14" width="3" height="2"/><rect x="14" y="18" width="2" height="3"/></g>`,
  viewfinder: c => `<g fill="none" stroke="${c}" stroke-width="2" stroke-linecap="round"><path d="M3 8V5a2 2 0 0 1 2-2h3M16 3h3a2 2 0 0 1 2 2v3M21 16v3a2 2 0 0 1-2 2h-3M8 21H5a2 2 0 0 1-2-2v-3"/></g><g fill="${c}"><rect x="7" y="7" width="4" height="4" rx=".6"/><rect x="13" y="7" width="4" height="4" rx=".6"/><rect x="7" y="13" width="4" height="4" rx=".6"/><rect x="13.5" y="13.5" width="3" height="3"/></g>`,
  clock: c => `<g fill="none" stroke="${c}" stroke-width="2" stroke-linecap="round"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3.5 2"/></g>`,
  plusSquare: c => `<g fill="none" stroke="${c}" stroke-width="2" stroke-linecap="round"><rect x="3" y="3" width="18" height="18" rx="5"/><path d="M12 8v8M8 12h8"/></g>`,
  gear: c => {
    const pts = [];
    for (let k = 0; k < 8; k++) {
      const a = k * 45;
      for (const [r, d] of [[7.4, -17], [10, -9], [10, 9], [7.4, 17]]) {
        const rad = (a + d) * Math.PI / 180;
        pts.push(`${(12 + r * Math.cos(rad)).toFixed(2)} ${(12 + r * Math.sin(rad)).toFixed(2)}`);
      }
    }
    return `<g fill="none" stroke="${c}" stroke-width="1.9" stroke-linejoin="round"><path d="M${pts.join('L')}Z"/><circle cx="12" cy="12" r="3.2"/></g>`;
  },
  bolt: c => `<path d="M13.5 2 4.5 13.5h6.5l-1 8.5 9-11.5h-6.5z" fill="${c}"/>`,
  boltSlash: c => `<path d="M13.5 2 4.5 13.5h6.5l-1 8.5 9-11.5h-6.5z" fill="none" stroke="${c}" stroke-width="1.8" stroke-linejoin="round"/>`,
  photo: c => `<g fill="none" stroke="${c}" stroke-width="2" stroke-linejoin="round"><rect x="3" y="5" width="18" height="14" rx="2.5"/><circle cx="8.5" cy="10" r="1.6" fill="${c}" stroke="none"/><path d="m3.5 17 5-5 4 4 2.5-2.5L20.5 18"/></g>`,
  link: c => `<g fill="none" stroke="${c}" stroke-width="2.2" stroke-linecap="round"><path d="M10 14a4 4 0 0 0 5.66 0l3-3a4 4 0 0 0-5.66-5.66l-1.2 1.2"/><path d="M14 10a4 4 0 0 0-5.66 0l-3 3a4 4 0 0 0 5.66 5.66l1.2-1.2"/></g>`,
  wifi: c => `<g fill="none" stroke="${c}" stroke-width="2.2" stroke-linecap="round"><path d="M2.5 9a14 14 0 0 1 19 0M5.5 12.6a9.5 9.5 0 0 1 13 0M8.7 16.1a4.8 4.8 0 0 1 6.6 0"/></g><circle cx="12" cy="19.5" r="1.5" fill="${c}"/>`,
  person: c => `<g fill="none" stroke="${c}" stroke-width="2.2" stroke-linecap="round"><circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/></g>`,
  envelope: c => `<g fill="none" stroke="${c}" stroke-width="2" stroke-linejoin="round"><rect x="3" y="5" width="18" height="14" rx="2"/><path d="m3.5 6.5 8.5 6.5 8.5-6.5"/></g>`,
  phone: c => `<path d="M5 3.5h3.6l1.9 4.8-2.4 1.6a11.5 11.5 0 0 0 6 6l1.6-2.4 4.8 1.9v3.6a2 2 0 0 1-2.1 2A16.5 16.5 0 0 1 3 5.6a2 2 0 0 1 2-2.1z" fill="none" stroke="${c}" stroke-width="2" stroke-linejoin="round"/>`,
  message: c => `<path d="M20.5 15a2 2 0 0 1-2 2H8l-4.5 4V5a2 2 0 0 1 2-2h13a2 2 0 0 1 2 2z" fill="none" stroke="${c}" stroke-width="2" stroke-linejoin="round"/>`,
  pin: c => `<g fill="none" stroke="${c}" stroke-width="2"><path d="M12 21.5s-7-6.3-7-12a7 7 0 0 1 14 0c0 5.7-7 12-7 12z"/><circle cx="12" cy="9.5" r="2.5"/></g>`,
  text: c => `<g fill="none" stroke="${c}" stroke-width="2" stroke-linecap="round"><rect x="4.5" y="3" width="15" height="18" rx="2.5"/><path d="M8 8h8M8 12h8M8 16h5"/></g>`,
  barcode: c => `<g fill="${c}"><rect x="3" y="5" width="2" height="14"/><rect x="6.5" y="5" width="1" height="14"/><rect x="9" y="5" width="2.5" height="14"/><rect x="13" y="5" width="1" height="14"/><rect x="15.5" y="5" width="2" height="14"/><rect x="19" y="5" width="2" height="14"/></g>`,
  star: (c, fill) => `<path d="M12 2.8 14.8 8.6 21.2 9.4 16.5 13.8 17.7 20.2 12 17.1 6.3 20.2 7.5 13.8 2.8 9.4 9.2 8.6z" fill="${fill ? c : 'none'}" stroke="${c}" stroke-width="1.8" stroke-linejoin="round"/>`,
  share: c => `<g fill="none" stroke="${c}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3v12M7.5 7.5 12 3l4.5 4.5M5.5 11.5V19a2 2 0 0 0 2 2h9a2 2 0 0 0 2-2v-7.5"/></g>`,
  copy: c => `<g fill="none" stroke="${c}" stroke-width="2" stroke-linejoin="round"><rect x="8.5" y="8.5" width="12" height="12" rx="2.5"/><path d="M15.5 8.5V6a2.5 2.5 0 0 0-2.5-2.5H6A2.5 2.5 0 0 0 3.5 6v7A2.5 2.5 0 0 0 6 15.5h2.5"/></g>`,
  lock: c => `<g fill="none" stroke="${c}" stroke-width="2.2"><rect x="5" y="11" width="14" height="10" rx="2.5" fill="${c}"/><path d="M8 11V7.5a4 4 0 0 1 8 0V11"/></g>`,
  lockOpen: c => `<g fill="none" stroke="${c}" stroke-width="2"><rect x="5" y="11" width="14" height="10" rx="2.5"/><path d="M8 11V7.5a4 4 0 0 1 7.6-1.7"/></g>`,
  check: c => `<path d="m5 12.5 4.5 4.5L19 7" fill="none" stroke="${c}" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/>`,
  checkCircle: c => `<circle cx="12" cy="12" r="10" fill="${c}"/><path d="m7.5 12.3 3 3 6-6.3" fill="none" stroke="#fff" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>`,
  calendar: c => `<g fill="none" stroke="${c}" stroke-width="2" stroke-linecap="round"><rect x="3.5" y="5" width="17" height="15.5" rx="2.5"/><path d="M3.5 10h17M8 3v4M16 3v4"/></g>`,
  download: c => `<g fill="none" stroke="${c}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3.5v11M7.5 10l4.5 4.5 4.5-4.5M5 20.5h14"/></g>`,
  search: c => `<g fill="none" stroke="${c}" stroke-width="2.2" stroke-linecap="round"><circle cx="10.5" cy="10.5" r="6.5"/><path d="m20 20-4.8-4.8"/></g>`,
  chevron: c => `<path d="m9 5.5 6.5 6.5L9 18.5" fill="none" stroke="${c}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>`,
  chevronLeft: c => `<path d="M15 4.5 7.5 12l7.5 7.5" fill="none" stroke="${c}" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/>`,
  xmark: c => `<path d="M7 7l10 10M17 7 7 17" fill="none" stroke="${c}" stroke-width="2.4" stroke-linecap="round"/>`,
  eye: c => `<g fill="none" stroke="${c}" stroke-width="2"><path d="M2 12s3.8-7 10-7 10 7 10 7-3.8 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/></g>`,
  repeat: c => `<g fill="none" stroke="${c}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m17 2.5 3.5 3.5-3.5 3.5M3.5 11V9.5a3.5 3.5 0 0 1 3.5-3.5h13.5M7 21.5 3.5 18 7 14.5M20.5 13v1.5a3.5 3.5 0 0 1-3.5 3.5H3.5"/></g>`,
  cameraSlash: c => `<g fill="none" stroke="${c}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 5h6l1.5 2H19a2 2 0 0 1 2 2v8.5M17.5 19.5H5a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2h1.5"/><circle cx="12" cy="13" r="3.5"/><path d="M3 3l18 18"/></g>`,
  shield: c => `<g fill="none" stroke="${c}" stroke-width="2" stroke-linejoin="round"><path d="M12 2.8 19.5 5.6v6c0 4.9-3.2 8.2-7.5 9.6-4.3-1.4-7.5-4.7-7.5-9.6v-6z"/><path d="m8.7 12 2.4 2.4 4.3-4.6" stroke-linecap="round"/></g>`,
  trash: c => `<g fill="none" stroke="${c}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 6.5h16M9.5 6.5V4h5v2.5M6 6.5l1 14h10l1-14M10 10.5v6M14 10.5v6"/></g>`,
  info: c => `<g fill="none" stroke="${c}" stroke-width="2" stroke-linecap="round"><circle cx="12" cy="12" r="9"/><path d="M12 11v5.5"/></g><circle cx="12" cy="7.6" r="1.3" fill="${c}"/>`,
  external: c => `<g fill="none" stroke="${c}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 4h6v6M20 4l-9 9M18 14v4.5a1.5 1.5 0 0 1-1.5 1.5h-11A1.5 1.5 0 0 1 4 18.5v-11A1.5 1.5 0 0 1 5.5 6H10"/></g>`,
  docText: c => `<g fill="none" stroke="${c}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z"/><path d="M14 3v5h5M9 13h6M9 17h6"/></g>`,
  infinity: c => `<path d="M7 8.5c-2 0-3.5 1.6-3.5 3.5S5 15.5 7 15.5c3.5 0 6.5-7 10-7 2 0 3.5 1.6 3.5 3.5S19 15.5 17 15.5c-3.5 0-6.5-7-10-7z" fill="none" stroke="${c}" stroke-width="2.2" stroke-linecap="round"/>`,
};

function icon(name, x, y, size, color, extra) {
  const s = size / 24;
  return `<g transform="translate(${x} ${y}) scale(${s})">${ICON[name](color, extra)}</g>`;
}

function tile(x, y, size, color, name, rx) {
  return rect(x, y, size, size, { rx: rx ?? size * 0.24, fill: color }) + icon(name, x + size * 0.2, y + size * 0.2, size * 0.6, '#fff');
}

function statusBar(dark) {
  const c = dark ? '#fff' : C.label;
  return `<g>${t(54, 33, '9:41', { size: 17, weight: 600, fill: c, anchor: 'middle' })}
  <g fill="${c}"><rect x="292" y="25" width="3" height="5" rx="1"/><rect x="297" y="23" width="3" height="7" rx="1"/><rect x="302" y="20.5" width="3" height="9.5" rx="1"/><rect x="307" y="18" width="3" height="12" rx="1"/></g>
  <g transform="translate(316 17) scale(0.62)">${ICON.wifi(c)}</g>
  <rect x="337" y="18.5" width="25" height="12" rx="3.5" fill="none" stroke="${c}" stroke-opacity=".4" stroke-width="1"/><rect x="339" y="20.5" width="19" height="8" rx="2" fill="${c}"/><rect x="363.5" y="22.5" width="1.6" height="4" rx=".8" fill="${c}" opacity=".45"/></g>`;
}

function homeIndicator(dark) {
  return rect(129.5, 838, 134, 5, { rx: 2.5, fill: dark ? '#fff' : '#000' });
}

const TABS = [['スキャン', 'viewfinder'], ['履歴', 'clock'], ['作成', 'plusSquare'], ['設定', 'gear']];
function tabBar(active, dark) {
  const bg = dark ? 'rgba(22,22,24,0.94)' : 'rgba(249,249,249,0.96)';
  const inactive = dark ? '#8E8E93' : '#8E8E93';
  const act = dark ? C.accentOnDark : C.accent;
  let s = rect(0, 769, 393, 83, { fill: bg }) + `<line x1="0" y1="769.25" x2="393" y2="769.25" stroke="${dark ? '#38383A' : '#C6C6C8'}" stroke-width=".5"/>`;
  TABS.forEach(([label, ic], i) => {
    const cx = 393 / 8 * (2 * i + 1);
    const col = i === active ? act : inactive;
    s += icon(ic, cx - 13, 777, 26, col);
    s += t(cx, 817, label, { size: 10, weight: 500, fill: col, anchor: 'middle' });
  });
  return s + homeIndicator(dark);
}

let phoneSeq = 0;
// Device frame with clipped 393x852 screen. ox/oy = screen origin on the canvas.
function phone(ox, oy, inner, caption) {
  const id = `scr${phoneSeq++}`;
  return `<g transform="translate(${ox} ${oy})">
  <rect x="-13" y="-13" width="419" height="878" rx="66" fill="#1C1C1E"/>
  <rect x="-10" y="-10" width="413" height="872" rx="63" fill="none" stroke="#3A3A3C" stroke-width="1.5"/>
  <clipPath id="${id}"><rect x="0" y="0" width="393" height="852" rx="54"/></clipPath>
  <g clip-path="url(#${id})">${inner}</g>
  <rect x="136" y="11" width="121" height="35.5" rx="17.75" fill="#000"/>
  </g>${caption ? t(ox + 196.5, oy + 900, caption, { size: 18, weight: 700, anchor: 'middle', fill: '#3A3A3C' }) : ''}`;
}

function doc(w, h, body, title) {
  return `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">
<title>${esc(title)}</title>
<defs>
  <filter id="shadow" x="-20%" y="-20%" width="140%" height="140%"><feDropShadow dx="0" dy="2" stdDeviation="6" flood-color="#000" flood-opacity=".08"/></filter>
  <filter id="shadowLg" x="-20%" y="-20%" width="140%" height="140%"><feDropShadow dx="0" dy="8" stdDeviation="16" flood-color="#000" flood-opacity=".18"/></filter>
  <filter id="blur6"><feGaussianBlur stdDeviation="6"/></filter>
  <linearGradient id="camBg" x1="0" y1="0" x2="0.3" y2="1"><stop offset="0" stop-color="#3B4240"/><stop offset=".55" stop-color="#262B2A"/><stop offset="1" stop-color="#121514"/></linearGradient>
  <linearGradient id="scanLine" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="${C.accentOnDark}" stop-opacity="0"/><stop offset=".5" stop-color="${C.accentOnDark}"/><stop offset="1" stop-color="${C.accentOnDark}" stop-opacity="0"/></linearGradient>
</defs>
${rect(0, 0, w, h, { fill: '#ECECEF' })}
${body}
</svg>
`;
}

// Deterministic pseudo QR pattern (visual only, not a decodable code).
function fakeQR(x, y, size, n = 29, color = '#000', seed = 7) {
  const m = size / n;
  let r = seed;
  const rnd = () => ((r = (r * 1103515245 + 12345) & 0x7fffffff) / 0x7fffffff);
  const inFinder = (i, j) => (i < 8 && j < 8) || (i >= n - 8 && j < 8) || (i < 8 && j >= n - 8);
  let s = `<g fill="${color}">`;
  for (let i = 0; i < n; i++) for (let j = 0; j < n; j++) {
    if (inFinder(i, j)) continue;
    if ((i === 6 || j === 6) ? (i + j) % 2 === 0 : rnd() > 0.52) s += `<rect x="${(x + j * m).toFixed(2)}" y="${(y + i * m).toFixed(2)}" width="${m.toFixed(2)}" height="${m.toFixed(2)}"/>`;
  }
  const finder = (fi, fj) => {
    const fx = x + fj * m, fy = y + fi * m;
    return `<path fill-rule="evenodd" d="M${fx} ${fy}h${7 * m}v${7 * m}h${-7 * m}z M${fx + m} ${fy + m}v${5 * m}h${5 * m}v${-5 * m}z"/><rect x="${fx + 2 * m}" y="${fy + 2 * m}" width="${3 * m}" height="${3 * m}"/>`;
  };
  s += finder(0, 0) + finder(n - 7, 0) + finder(0, n - 7);
  return s + '</g>';
}

function toggle(x, y, on) {
  return rect(x, y, 51, 31, { rx: 15.5, fill: on ? C.accent : '#E9E9EA' }) +
    `<circle cx="${on ? x + 35.5 : x + 15.5}" cy="${y + 15.5}" r="13.5" fill="#fff" filter="url(#shadow)"/>`;
}

module.exports = { C, FONT, MONO, esc, t, rect, icon, tile, statusBar, homeIndicator, tabBar, phone, doc, fakeQR, toggle, ICON };
