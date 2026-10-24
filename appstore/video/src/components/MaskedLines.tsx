import { useCurrentFrame } from "remotion";
import { FONT, ease } from "../timeline";

/**
 * Headline lines (and an optional sub line) that rise from a mask line at `inAt` and roll up out of it at `outAt`.
 * Nothing fades: each row slides inside a clipped box, one after the other.
 */
export const MaskedLines = ({
  x,
  top,
  lines,
  sub,
  size,
  subSize,
  inAt,
  outAt,
  sink = false,
}: {
  x: number;
  top: number;
  lines: string[];
  sub?: string;
  size: number;
  subSize: number;
  inAt: number;
  outAt?: number;
  /** Leave downwards (back into the line) instead of upwards. */
  sink?: boolean;
}) => {
  const frame = useCurrentFrame();
  const rows = [...lines.map((text) => ({ text, sub: false })), ...(sub ? [{ text: sub, sub: true }] : [])];
  const lineH = size * 1.22;
  const height = lines.length * lineH + (sub ? size * 0.3 + subSize * 1.4 : 0) + size * 0.2;
  if (frame < inAt || (outAt !== undefined && frame > outAt + 16)) return null;
  return (
    <div style={{ position: "absolute", left: x - 1900, width: 3800, top, height, overflow: "hidden", fontFamily: FONT, color: "#fff", textAlign: "center" }}>
      <div style={{ position: "absolute", left: 0, right: 0, top: size * 0.1 }}>
        {rows.map((row, i) => {
          const rise = 1 - ease(frame, inAt + i * 2, inAt + i * 2 + 13);
          const leave = outAt === undefined ? 0 : ease(frame, outAt + i * 1.5, outAt + i * 1.5 + 10, "inOut");
          return (
            <div
              key={i}
              style={{
                translate: `0 ${(rise - leave * (sink ? -1 : 1)) * height}px`,
                fontSize: row.sub ? subSize : size,
                fontWeight: row.sub ? 500 : 800,
                lineHeight: row.sub ? 1.4 : 1.22,
                marginTop: row.sub ? size * 0.3 : 0,
                letterSpacing: row.sub ? "0.04em" : "0.02em",
                opacity: row.sub ? 0.88 : 1,
                whiteSpace: "nowrap",
                textShadow: "0 6px 30px rgba(0,40,30,0.25)",
              }}
            >
              {row.text}
            </div>
          );
        })}
      </div>
    </div>
  );
};
