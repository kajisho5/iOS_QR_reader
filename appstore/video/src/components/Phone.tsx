import { Img, staticFile } from "remotion";
import { BRAND, mix } from "../timeline";

export type Slide = { from: string; to: string; progress: number; direction: 1 | -1 };

/**
 * One device shape that grows out of the code, behaves as an iPhone, and turns into the app icon tile:
 * body (cx, cy, w, h, radius) with a black bezel of `bezel` px around the screen.
 * `island` (0…1) widens the Dynamic Island into a pill with a lock. `flood` (0…1) fills the screen with the icon's green
 * from the island outwards; `globalFill` (0…1) moves that gradient from the tile's own height to the whole frame's, so the
 * tile matches the background once it covers the frame.
 */
export const Phone = ({
  cx,
  cy,
  w,
  h,
  radius,
  bezel,
  slide,
  island,
  flood,
  globalFill,
  frameH,
  shadow,
}: {
  cx: number;
  cy: number;
  w: number;
  h: number;
  radius: number;
  bezel: number;
  slide: Slide;
  island: number;
  flood: number;
  globalFill: number;
  frameH: number;
  shadow: number;
}) => {
  const innerW = w - bezel * 2;
  const innerH = h - bezel * 2;
  const innerTop = cy - h / 2 + bezel;
  const innerR = Math.max(0, radius - bezel);
  const shot = (src: string, x: number) => (
    <Img src={staticFile(src)} style={{ position: "absolute", left: 0, top: 0, width: "100%", height: "100%", objectFit: "cover", translate: `${x}px 0` }} />
  );
  const p = slide.progress;
  // The island in a real iPhone screen: 11 pt below the top, 126 x 37 pt of a 402 x 874 pt screen.
  const deviceH = Math.max(h, 1);
  const islandW = mix(0.31, 0.6, island) * w;
  const islandH = mix(0.042, 0.06, island) * deviceH;
  const islandTop = 0.014 * deviceH;
  const floodR = flood * Math.hypot(innerW, innerH) * 1.05;
  const gradientH = mix(innerH, frameH, globalFill);
  const gradientY = mix(0, -innerTop, globalFill);
  return (
    <div
      style={{
        position: "absolute",
        left: cx - w / 2,
        top: cy - h / 2,
        width: w,
        height: h,
        borderRadius: radius,
        background: "#101513",
        boxShadow: shadow > 0 ? `0 ${h * 0.03}px ${h * 0.07}px rgba(0, 30, 22, ${0.35 * shadow})` : "none",
      }}
    >
      <div style={{ position: "absolute", left: bezel, top: bezel, width: innerW, height: innerH, borderRadius: innerR, overflow: "hidden", background: "#F2F2F7" }}>
        {p <= 0 ? (
          shot(slide.from, 0)
        ) : p >= 1 ? (
          shot(slide.to, 0)
        ) : (
          <>
            {shot(slide.from, -slide.direction * innerW * 0.3 * p)}
            <div style={{ position: "absolute", inset: 0, translate: `${slide.direction * innerW * (1 - p)}px 0`, boxShadow: "-24px 0 48px rgba(0,0,0,0.14)" }}>
              {shot(slide.to, 0)}
            </div>
          </>
        )}
        {island >= 0 && h > 0 && bezel > 0.5 ? (
          <div
            style={{
              position: "absolute",
              left: innerW / 2 - islandW / 2,
              top: islandTop,
              width: islandW,
              height: islandH,
              borderRadius: islandH / 2,
              background: "#000",
              opacity: Math.min(1, bezel / 6),
            }}
          >
            {island > 0.05 ? <Lock size={islandH * 0.62} x={islandW / 2} y={islandH / 2} scale={island} /> : null}
          </div>
        ) : null}
        {flood > 0 ? (
          <div
            style={{
              position: "absolute",
              inset: 0,
              backgroundImage: `linear-gradient(${BRAND.top}, ${BRAND.bottom})`,
              backgroundSize: `100% ${gradientH}px`,
              backgroundPosition: `0 ${gradientY}px`,
              backgroundRepeat: "no-repeat",
              backgroundColor: BRAND.bottom,
              clipPath: `circle(${floodR}px at 50% ${islandTop + islandH / 2}px)`,
            }}
          />
        ) : null}
      </div>
    </div>
  );
};

const Lock = ({ size, x, y, scale }: { size: number; x: number; y: number; scale: number }) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="none"
    stroke={BRAND.mint}
    strokeWidth={2.4}
    strokeLinecap="round"
    strokeLinejoin="round"
    style={{ position: "absolute", left: x - size / 2, top: y - size / 2, scale: String(scale) }}
  >
    <rect x="5" y="10.5" width="14" height="10" rx="2.5" />
    <path d="M8 10.5V7.5a4 4 0 0 1 8 0v3" />
  </svg>
);
