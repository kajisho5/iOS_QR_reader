import { Easing, interpolate, spring } from "remotion";

export const FPS = 30;
export const DURATION = 15 * FPS;

/** Beats in frames (docs/design/appstore/VIDEO.md §5.3). One continuous take; the last frame leads into the first. */
export const T = {
  close: 6, // ① the corners close in on the code
  lock: 45, // ② locked: mint, ripples
  grow: 50, // the screen grows out of the code, the corners move out to frame the phone
  result: 90, // ③ かざすだけ
  noExtras: 165, // ④ 余計なものは、入れていない
  oneTime: 240, // ⑤ 毎月の支払いは、いらない
  onDevice: 315, // ⑥ 読んだ中身は、どこにも送らない
  flood: 372, // ⑦ the screen fills with the icon's green
  toIcon: 380, // the phone becomes the app icon
  name: 394, // 誠実QRリーダー
  dive: 436, // the icon grows past the frame edges and becomes scene ①
};

/** The icon's own fill (docs/design/icon/icon.spec.json), also the video's background. */
export const BRAND = {
  top: "#16A386",
  bottom: "#0A5F4E",
  mint: "#7FF0D2",
};

export const FONT = "'Noto Sans CJK JP', 'Hiragino Sans', sans-serif";

/** Springs from the reference: the shape settles fast with a little bounce (damping ratio 0.72), the camera slower and without (1.0). */
export const shape = (frame: number, start: number, frames = 14) =>
  spring({ frame: frame - start, fps: FPS, durationInFrames: frames, config: { mass: 1, stiffness: 252, damping: 22.9 } });

export const camera = (frame: number, start: number, frames = 30) =>
  spring({ frame: frame - start, fps: FPS, durationInFrames: frames, config: { mass: 1, stiffness: 44, damping: 13.3 } });

const clamp = { extrapolateLeft: "clamp", extrapolateRight: "clamp" } as const;

/** Eased 0→1 between two frames. `out` for things that arrive, `inOut` for things that travel and stop. */
export const ease = (frame: number, from: number, to: number, curve: "out" | "inOut" = "out") =>
  interpolate(frame, [from, to], [0, 1], { ...clamp, easing: curve === "out" ? Easing.bezier(0.16, 1, 0.3, 1) : Easing.bezier(0.65, 0, 0.35, 1) });

export const linear = (frame: number, from: number, to: number) => interpolate(frame, [from, to], [0, 1], clamp);

export const mix = (a: number, b: number, t: number) => a + (b - a) * t;

export type Box = { x: number; y: number; w: number; h: number };

export const mixBox = (a: Box, b: Box, t: number): Box => ({ x: mix(a.x, b.x, t), y: mix(a.y, b.y, t), w: mix(a.w, b.w, t), h: mix(a.h, b.h, t) });
