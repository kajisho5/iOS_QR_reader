import { FONT } from "../timeline";

/** Headline (one or more lines) with an optional smaller sub line, centred on (x, y). */
export const Caption = ({
  x,
  y,
  lines,
  sub,
  size,
  subSize,
  opacity,
  shift,
}: {
  x: number;
  y: number;
  lines: string[];
  sub?: string;
  size: number;
  subSize: number;
  opacity: number;
  shift: number;
}) => (
  <div
    style={{
      position: "absolute",
      left: x,
      top: y,
      transform: `translate(-50%, -50%) translateY(${shift}px)`,
      opacity,
      textAlign: "center",
      color: "#fff",
      fontFamily: FONT,
      whiteSpace: "nowrap",
    }}
  >
    {lines.map((line) => (
      <div key={line} style={{ fontSize: size, fontWeight: 800, lineHeight: 1.22, letterSpacing: "0.02em", textShadow: "0 6px 30px rgba(0,40,30,0.25)" }}>
        {line}
      </div>
    ))}
    {sub ? <div style={{ marginTop: size * 0.38, fontSize: subSize, fontWeight: 500, opacity: 0.86, letterSpacing: "0.04em" }}>{sub}</div> : null}
  </div>
);
