import { Img, staticFile } from "remotion";

/** iPhone frame whose screen slides between screenshots like app navigation. */
export const Phone = ({
  height,
  screens,
  from,
  to,
  progress,
  direction,
}: {
  height: number;
  screens: string[];
  /** Index of the screen shown before the current transition. */
  from: number;
  /** Index of the screen shown after it. */
  to: number;
  /** 0…1 progress of the slide from `from` to `to`. */
  progress: number;
  /** 1 = new screen comes from the right (push), -1 = from the left (back). */
  direction: 1 | -1;
}) => {
  const width = height * 0.4795;
  const bezel = height * 0.018;
  const radius = height * 0.085;
  const screenW = width - bezel * 2;
  const shot = (index: number, x: number) => (
    <Img
      src={staticFile(screens[index])}
      style={{ position: "absolute", top: 0, left: 0, width: "100%", height: "100%", objectFit: "cover", transform: `translateX(${x}px)` }}
    />
  );
  return (
    <div
      style={{
        width,
        height,
        borderRadius: radius,
        background: "#111614",
        padding: bezel,
        boxSizing: "border-box",
        boxShadow: `0 ${height * 0.04}px ${height * 0.08}px rgba(0, 20, 15, 0.35), inset 0 0 0 ${height * 0.003}px rgba(255,255,255,0.12)`,
        position: "relative",
      }}
    >
      <div style={{ position: "relative", width: "100%", height: "100%", borderRadius: radius - bezel, overflow: "hidden", background: "#F2F2F7" }}>
        {from === to || progress <= 0 ? (
          shot(from, 0)
        ) : (
          <>
            {shot(from, -direction * screenW * 0.3 * progress)}
            <div style={{ position: "absolute", inset: 0, transform: `translateX(${direction * screenW * (1 - progress)}px)`, boxShadow: "-24px 0 48px rgba(0,0,0,0.12)" }}>
              {shot(to, 0)}
            </div>
          </>
        )}
      </div>
      <div
        style={{
          position: "absolute",
          top: bezel * 1.8,
          left: "50%",
          width: width * 0.32,
          height: height * 0.026,
          marginLeft: -width * 0.16,
          borderRadius: height * 0.013,
          background: "#000",
        }}
      />
    </div>
  );
};
