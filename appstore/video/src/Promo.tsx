import { AbsoluteFill, Img, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { GlassCorners, iconBox } from "./components/GlassCorners";
import { MaskedLines } from "./components/MaskedLines";
import { Phone, type Slide } from "./components/Phone";
import { BRAND, T, camera, ease, linear, mix, mixBox, shape, type Box } from "./timeline";

type Layout = "header" | "search";

/** Sizes in px (both compositions are 3840 wide). docs/design/appstore/VIDEO.md §5, storyboard-v2-*.svg. */
const LAYOUTS = {
  header: {
    mark: { x: 1920, y: 823, px: 1204, gap: 150 }, // scene ①: the icon's mark, the code 400px wide
    phone: { x0: 2590, x1: 2500, y0: 850, y1: 850, h: 1400 }, // drifts from (x0, y0) to (x1, y1) during ③–⑥
    frame: { mx: 70, my: 60, px: 840 }, // the corners around the phone
    text: { x: 1440, top: 560, size: 150, sub: 80 },
    icon: { x: 1920, y: 610, size: 440 },
    name: { top: 940, size: 170, sub: 90 },
  },
  search: {
    mark: { x: 1920, y: 1203, px: 1566, gap: 190 },
    phone: { x0: 1920, x1: 1920, y0: 1950, y1: 1900, h: 2000 }, // the bottom runs off the frame
    frame: { mx: 80, my: 70, px: 1100 },
    text: { x: 1920, top: 100, size: 180, sub: 92 },
    icon: { x: 1920, y: 1000, size: 600 },
    name: { top: 1440, size: 220, sub: 110 },
  },
} as const;

const COPY = [
  { at: T.result, out: T.noExtras, lines: ["かざすだけ。"] },
  { at: T.noExtras, out: T.oneTime, lines: ["余計なものは、", "入れていない。"], sub: "広告も、アクセス解析も。" },
  { at: T.oneTime, out: T.onDevice, lines: ["毎月の支払いは、", "いらない。"], sub: "必要なら、一度買うだけ。" },
  { at: T.onDevice, out: T.flood + 2, lines: ["読んだ中身は、", "どこにも送らない。"], sub: "ぜんぶ、この iPhone の中で。" },
];

const SCREENS = { url: "shot-02-result-url.jpg", history: "shot-01-history.jpg", create: "shot-04-create.jpg" };
const PHONE_RATIO = 0.4795; // body width / height
const ICON_RADIUS = 0.2237; // squircle corner radius / size

/** Everything that moves, on a transparent background (the background is drawn outside the motion blur; see Root). */
export const Promo = ({ layout }: { layout: Layout }) => {
  const f = useCurrentFrame();
  const { width: W, height: H } = useVideoConfig();
  const L = LAYOUTS[layout];
  const M = L.mark;

  // ---- Where each stage puts the shape ----
  const drift = linear(f, T.result - 6, T.flood);
  const phoneX = mix(L.phone.x0, L.phone.x1, drift);
  const phoneY = mix(L.phone.y0, L.phone.y1, drift);
  const phoneH = L.phone.h;
  const phoneW = phoneH * PHONE_RATIO;
  const phoneBox: Box = { x: phoneX - phoneW / 2, y: phoneY - phoneH / 2, w: phoneW, h: phoneH };
  const frameBox: Box = { x: phoneBox.x - L.frame.mx, y: phoneBox.y - L.frame.my, w: phoneBox.w + L.frame.mx * 2, h: phoneBox.h + L.frame.my * 2 };

  // ① close in, ② lock (squeeze), then grow into the phone, ⑦ shrink into the icon, then dive into scene ①.
  const close = shape(f, T.close, 26);
  const squeeze = shape(f, T.lock, 8) - shape(f, T.lock + 6, 12);
  const grow = camera(f, T.grow, 34);
  const toIcon = shape(f, T.toIcon, 18);
  const dive = ease(f, T.dive, 450, "inOut");

  let corners: { box: Box; px: number };
  const markBox = iconBox(M.x, M.y, M.px, mix(M.gap, 0, close) - squeeze * 20);
  const iconAt = iconBox(L.icon.x, L.icon.y, L.icon.size);
  if (f < T.toIcon) {
    corners = { box: mixBox(markBox, frameBox, grow), px: mix(M.px, L.frame.px, grow) };
  } else if (f < T.dive) {
    corners = { box: mixBox(frameBox, iconAt, toIcon), px: mix(L.frame.px, L.icon.size, toIcon) };
  } else {
    corners = { box: mixBox(iconAt, iconBox(M.x, M.y, M.px, M.gap), dive), px: mix(L.icon.size, M.px, dive) };
  }
  const mint = ease(f, T.lock, T.lock + 4) * (1 - ease(f, T.lock + 22, T.lock + 40));

  // The code: shown in ①②, covered by the growing screen, back inside the icon at ⑦ and growing with the dive.
  const qrPop = shape(f, T.toIcon + 8, 16);
  const qr =
    f < T.grow + 12 ? { x: M.x, y: M.y, px: M.px, scale: 1 }
    : f >= T.toIcon + 8 ? { x: mix(L.icon.x, M.x, dive), y: mix(L.icon.y, M.y, dive), px: mix(L.icon.size, M.px, dive), scale: qrPop }
    : null;

  // The device: grows out of the code (②→③), is the iPhone (③–⑥), becomes the icon tile (⑦), covers the frame (dive).
  type Shape = { x: number; y: number; w: number; h: number; r: number };
  const seed: Shape = { x: M.x, y: M.y, w: M.px * 0.3, h: M.px * 0.3, r: M.px * 0.03 };
  const phone = { x: phoneX, y: phoneY, w: phoneW, h: phoneH, r: phoneH * 0.085 };
  const tile = { x: L.icon.x, y: L.icon.y, w: L.icon.size, h: L.icon.size, r: L.icon.size * ICON_RADIUS };
  const cover = Math.max(W, H) * 1.9;
  const full = { x: M.x, y: M.y, w: cover, h: cover, r: cover * ICON_RADIUS };
  const lerp = (a: Shape, b: Shape, t: number): Shape => ({ x: mix(a.x, b.x, t), y: mix(a.y, b.y, t), w: mix(a.w, b.w, t), h: mix(a.h, b.h, t), r: mix(a.r, b.r, t) });
  const body = f < T.toIcon ? lerp(seed, phone, grow) : f < T.dive ? lerp(phone, tile, toIcon) : lerp(tile, full, dive);
  const bezelFull = phoneH * 0.016;
  const bezel = f < T.toIcon ? bezelFull * grow : bezelFull * (1 - toIcon);
  const showDevice = f >= T.grow;

  // Screens: the URL result, then push to history (④), create (⑤), back to history (⑥).
  const push = (at: number) => ease(f, at + 1, at + 15, "inOut");
  const slide: Slide =
    f < T.noExtras ? { from: SCREENS.url, to: SCREENS.url, progress: 0, direction: 1 }
    : f < T.oneTime ? { from: SCREENS.url, to: SCREENS.history, progress: push(T.noExtras), direction: 1 }
    : f < T.onDevice ? { from: SCREENS.history, to: SCREENS.create, progress: push(T.oneTime), direction: 1 }
    : { from: SCREENS.create, to: SCREENS.history, progress: push(T.onDevice), direction: -1 };
  const island = shape(f, T.onDevice + 8, 16);
  const flood = ease(f, T.flood, T.toIcon + 6);

  // ② ripples from the centre.
  const ripples = [T.lock + 1, T.lock + 8].map((start) => {
    const p = linear(f, start, start + 28);
    return { r: mix(0.36, 0.95, ease(f, start, start + 28)) * M.px, opacity: p > 0 && p < 1 ? (1 - p) * 0.55 : 0 };
  });

  return (
    <AbsoluteFill style={{ overflow: "hidden" }}>
      {ripples.map((r, i) =>
        r.opacity > 0 ? (
          <div
            key={i}
            style={{
              position: "absolute",
              left: M.x - r.r,
              top: M.y - r.r,
              width: r.r * 2,
              height: r.r * 2,
              borderRadius: "50%",
              border: `${M.px * 0.012}px solid ${BRAND.mint}`,
              opacity: r.opacity,
            }}
          />
        ) : null,
      )}

      {qr && f < T.grow + 12 ? <Qr {...qr} /> : null}

      {showDevice ? (
        <Phone
          cx={body.x}
          cy={body.y}
          w={body.w}
          h={body.h}
          radius={body.r}
          bezel={bezel}
          slide={slide}
          island={f >= T.onDevice ? island : 0}
          flood={flood}
          globalFill={dive}
          frameH={H}
          shadow={1 - dive}
          // By the end of the dive the tile's gradient is the background's, so it can vanish without a visible change
          // (and the last frame has no motion-blur banding, matching the first).
          opacity={1 - dive}
        />
      ) : null}

      {qr && f >= T.toIcon + 8 ? <Qr {...qr} /> : null}

      <GlassCorners box={corners.box} px={corners.px} mint={mint} />

      {COPY.map((c) => (
        <MaskedLines
          key={c.at}
          x={L.text.x}
          top={L.text.top + (c.lines.length === 1 ? L.text.size * 0.6 : 0)}
          lines={c.lines}
          sub={c.sub}
          size={L.text.size}
          subSize={L.text.sub}
          inAt={c.at + 2}
          outAt={c.out}
        />
      ))}
      <MaskedLines x={W / 2} top={L.name.top} lines={["誠実QRリーダー"]} sub="ちゃんと、読むだけ。" size={L.name.size} subSize={L.name.sub} inAt={T.name} outAt={T.dive - 2} sink />
    </AbsoluteFill>
  );
};

/** The icon's glass QR (a full 1024 icon grid image, `px` wide, centred). */
const Qr = ({ x, y, px, scale }: { x: number; y: number; px: number; scale: number }) => (
  <Img src={staticFile("mark-qr.png")} style={{ position: "absolute", left: x - px / 2, top: y - px / 2, width: px, height: px, scale: String(scale) }} />
);
