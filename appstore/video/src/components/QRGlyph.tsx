import { BRAND } from "../timeline";

const N = 21;

// Decorative QR-like pattern (three finder squares and a fixed scatter). Scanning it does nothing.
const cells: [number, number][] = (() => {
  const finder = (r: number, c: number, r0: number, c0: number) =>
    r >= r0 && r < r0 + 7 && c >= c0 && c < c0 + 7 &&
    (r === r0 || r === r0 + 6 || c === c0 || c === c0 + 6 || (r >= r0 + 2 && r <= r0 + 4 && c >= c0 + 2 && c <= c0 + 4));
  const out: [number, number][] = [];
  for (let r = 0; r < N; r++) {
    for (let c = 0; c < N; c++) {
      const inFinderZone = (r < 8 && (c < 8 || c > 12)) || (r > 12 && c < 8);
      const on = finder(r, c, 0, 0) || finder(r, c, 0, 14) || finder(r, c, 14, 0) || (!inFinderZone && (r * 7 + c * 13 + r * c) % 5 < 2);
      if (on) out.push([r, c]);
    }
  }
  return out;
})();

export const QRGlyph = ({ size }: { size: number }) => {
  const pad = 2;
  return (
    <svg width={size} height={size} viewBox={`${-pad} ${-pad} ${N + pad * 2} ${N + pad * 2}`} style={{ display: "block" }}>
      <rect x={-pad} y={-pad} width={N + pad * 2} height={N + pad * 2} rx={2} fill="#fff" />
      {cells.map(([r, c]) => (
        <rect key={`${r}-${c}`} x={c} y={r} width={1.02} height={1.02} fill={BRAND.ink} />
      ))}
    </svg>
  );
};
