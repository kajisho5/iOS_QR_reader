import { AbsoluteFill, Img, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { Caption } from "./components/Caption";
import { LockIcon } from "./components/LockIcon";
import { Phone } from "./components/Phone";
import { IconMark } from "./components/IconMark";
import { BRAND, FONT, T, mix, pop, ramp, rise } from "./timeline";

type Layout = "header" | "search";

const SCREENS = ["shot-02-result-url.jpg", "shot-01-history.jpg", "shot-04-create.jpg"];

/** Positions as fractions of the frame; sizes in px (both compositions are 3840 wide). */
const LAYOUTS = {
  header: {
    qrCenter: { x: 0.5, y: 0.5, size: 400 },
    qrSide: { x: 0.36, y: 0.42, size: 230 },
    scanCaption: { x: 0.36, y: 0.75, size: 150 },
    phoneIn: { x: 0.64, y: 0.56, h: 1500 },
    phoneMain: { x: 0.67, y: 0.56, h: 1500 },
    text: { x: 0.4, y: 0.6, size: 140, sub: 76, oneLine: false },
    lock: { x: 0.4, y: 0.27, size: 230 },
    end: { iconY: 0.3, icon: 400, nameY: 0.66, name: 170, subY: 0.79, sub: 96 },
  },
  search: {
    qrCenter: { x: 0.5, y: 0.45, size: 520 },
    qrSide: { x: 0.3, y: 0.5, size: 400 },
    scanCaption: { x: 0.3, y: 0.79, size: 170 },
    phoneIn: { x: 0.64, y: 0.58, h: 2100 },
    phoneMain: { x: 0.5, y: 0.64, h: 1800 },
    text: { x: 0.5, y: 0.155, size: 150, sub: 84, oneLine: true },
    lock: null,
    end: { iconY: 0.32, icon: 520, nameY: 0.62, name: 210, subY: 0.72, sub: 110 },
  },
} as const;

const MESSAGES = [
  { start: T.noExtras, end: T.oneTime, lines: ["余計なものは、", "入れていない。"], sub: "広告も、アクセス解析も。" },
  { start: T.oneTime, end: T.onDevice, lines: ["毎月の支払いは、", "いらない。"], sub: "必要なら、一度買うだけ。" },
  { start: T.onDevice, end: T.endCard, lines: ["読んだ中身は、", "どこにも送らない。"], sub: "ぜんぶ、この iPhone の中で。" },
];

export const Promo = ({ layout }: { layout: Layout }) => {
  const f = useCurrentFrame();
  const { width: W, height: H, durationInFrames } = useVideoConfig();
  const L = LAYOUTS[layout];
  const looping = f >= T.loop;

  // Background: brand gradient with a slow glow that returns to its start every loop.
  const angle = (f / durationInFrames) * Math.PI * 2;
  const glowX = 50 + Math.sin(angle) * 8;
  const glowY = 50 + Math.cos(angle) * 6;

  // ①② The reticle closes in on the code, locks (turns mint, ripples), then the code moves aside (③).
  const toSide = looping ? 0 : rise(f, T.result + 4, 26);
  const qrX = mix(L.qrCenter.x, L.qrSide.x, toSide) * W;
  const qrY = mix(L.qrCenter.y, L.qrSide.y, toSide) * H;
  const qrSize = mix(L.qrCenter.size, L.qrSide.size, toSide);
  const approach = looping ? 0 : rise(f, 4, 36);
  const locked = looping ? 0 : pop(f, T.lock, 18);
  const markSize = qrSize * (1024 / 340);
  const bracketScale = mix(1.45, 1.04, approach) * mix(1, 0.94, locked);
  const reticleSize = markSize * (600 / 1024) * bracketScale; // span of the corners, for the ripples
  const mintness = looping ? 0 : ramp(f, T.lock, T.lock + 6);
  const reticleColor = mintness > 0.5 ? BRAND.mint : "#fff";
  const qrOpacity = looping ? ramp(f, T.loop, durationInFrames) : 1 - ramp(f, T.noExtras - 10, T.noExtras);
  const ripples = [T.lock + 2, T.lock + 10].map((start) => {
    const p = ramp(f, start, start + 26);
    return { scale: mix(0.9, 2.1, p), opacity: p > 0 && p < 1 ? (1 - p) * 0.55 : 0 };
  });

  // ③ Caption under the code.
  const scanCaptionIn = rise(f, T.result + 16, 22);
  const scanCaptionOut = ramp(f, T.noExtras - 8, T.noExtras);

  // Phone: rises at ③, moves to its main spot at ④, screens slide between scenes, leaves at ⑦.
  const enter = pop(f, T.result, 30);
  const settle = rise(f, T.noExtras, 24);
  const leave = ramp(f, T.endCard, T.endCard + 12);
  const phoneH = mix(L.phoneIn.h, L.phoneMain.h, settle);
  const phoneX = mix(L.phoneIn.x, L.phoneMain.x, settle) * W;
  const phoneY = mix(L.phoneIn.y, L.phoneMain.y, settle) * H + (1 - enter) * H * 0.95 + Math.sin((f / 120) * Math.PI * 2) * 8 + leave * 60;
  const phoneOpacity = f < T.result ? 0 : ramp(f, T.result, T.result + 6) * (1 - leave);
  const slide = (start: number) => rise(f, start + 2, 18);
  const nav =
    f < T.noExtras ? { from: 0, to: 0, progress: 0, direction: 1 as const }
    : f < T.oneTime ? { from: 0, to: 1, progress: slide(T.noExtras), direction: 1 as const }
    : f < T.onDevice ? { from: 1, to: 2, progress: slide(T.oneTime), direction: 1 as const }
    : { from: 2, to: 1, progress: slide(T.onDevice), direction: -1 as const };

  // ④⑤⑥ Messages fade up in, and drift up as they leave.
  const message = (start: number, end: number) => ({
    opacity: ramp(f, start + 6, start + 18) * (1 - ramp(f, end - 8, end)),
    shift: (1 - rise(f, start + 6, 22)) * 40 - ramp(f, end - 8, end) * 24,
  });

  // ⑦ End card.
  const endIn = rise(f, T.endCard + 6, 22);
  const endOut = ramp(f, T.loop, T.loop + 10);
  const iconPop = pop(f, T.endCard + 4, 26);

  return (
    <AbsoluteFill
      style={{
        background: `radial-gradient(circle at ${glowX}% ${glowY}%, rgba(60,199,166,0.38) 0%, rgba(60,199,166,0) 55%), linear-gradient(135deg, ${BRAND.from}, ${BRAND.to})`,
        fontFamily: FONT,
        overflow: "hidden",
      }}
    >
      {/* Code and viewfinder */}
      <div style={{ position: "absolute", left: qrX, top: qrY, opacity: qrOpacity }}>
        {ripples.map((r, i) => (
          <div
            key={i}
            style={{
              position: "absolute",
              width: reticleSize,
              height: reticleSize,
              left: -reticleSize / 2,
              top: -reticleSize / 2,
              borderRadius: "50%",
              border: `${reticleSize * 0.012}px solid ${BRAND.mint}`,
              transform: `scale(${r.scale})`,
              opacity: r.opacity,
            }}
          />
        ))}
        <div style={{ position: "absolute", left: -markSize / 2, top: -markSize / 2 }}>
          <IconMark size={markSize} bracketScale={bracketScale} bracketColor={reticleColor} />
        </div>
      </div>

      <Caption
        x={L.scanCaption.x * W}
        y={L.scanCaption.y * H}
        lines={["かざすだけ。"]}
        size={L.scanCaption.size}
        subSize={0}
        opacity={scanCaptionIn * (1 - scanCaptionOut)}
        shift={(1 - scanCaptionIn) * 40 - scanCaptionOut * 24}
      />

      {MESSAGES.map((m) => {
        const { opacity, shift } = message(m.start, m.end);
        if (opacity <= 0) return null;
        return (
          <Caption
            key={m.start}
            x={L.text.x * W}
            y={L.text.y * H}
            lines={L.text.oneLine ? [m.lines.join("")] : [...m.lines]}
            sub={m.sub}
            size={L.text.size}
            subSize={L.text.sub}
            opacity={opacity}
            shift={shift}
          />
        );
      })}

      {L.lock ? (() => {
        const { opacity } = message(T.onDevice, T.endCard);
        const s = L.lock.size * mix(0.6, 1, pop(f, T.onDevice + 4, 24));
        return opacity > 0 ? (
          <div style={{ position: "absolute", left: L.lock.x * W - s / 2, top: L.lock.y * H - s / 2, opacity }}>
            <LockIcon size={s} />
          </div>
        ) : null;
      })() : null}

      {phoneOpacity > 0 ? (
        <div
          style={{
            position: "absolute",
            left: phoneX,
            top: phoneY,
            transform: `translate(-50%, -50%) scale(${1 - leave * 0.06})`,
            opacity: phoneOpacity,
          }}
        >
          <Phone height={phoneH} screens={SCREENS} {...nav} />
        </div>
      ) : null}

      {endIn > 0 && endOut < 1 ? (
        <div style={{ position: "absolute", inset: 0, opacity: endIn * (1 - endOut) }}>
          <div
            style={{
              position: "absolute",
              width: L.end.icon * 2.2,
              height: L.end.icon * 2.2,
              left: W / 2 - L.end.icon * 1.1,
              top: L.end.iconY * H - L.end.icon * 1.1,
              borderRadius: "50%",
              background: "radial-gradient(circle, rgba(255,255,255,0.22) 0%, rgba(255,255,255,0) 62%)",
              opacity: iconPop,
            }}
          />
          <Img
            src={staticFile("icon-glass.png")}
            style={{
              position: "absolute",
              width: L.end.icon,
              height: L.end.icon,
              left: W / 2 - L.end.icon / 2,
              top: L.end.iconY * H - L.end.icon / 2,
              transform: `scale(${mix(0.7, 1, iconPop)})`,
              filter: "drop-shadow(0 30px 60px rgba(0,30,20,0.4))",
            }}
          />
          <Caption
            x={W / 2}
            y={mix(L.end.nameY, L.end.subY, 0.5) * H}
            lines={["誠実QRリーダー"]}
            sub="ちゃんと、読むだけ。"
            size={L.end.name}
            subSize={L.end.sub}
            opacity={1}
            shift={(1 - endIn) * 40}
          />
        </div>
      ) : null}
    </AbsoluteFill>
  );
};
