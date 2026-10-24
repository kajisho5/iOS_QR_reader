import { Easing, interpolate, spring } from "remotion";

export const FPS = 30;
export const DURATION = 15 * FPS;

/** Scene boundaries in frames (docs/design/appstore/VIDEO.md §2). */
export const T = {
  lock: 45, // ② the reticle locks onto the code
  result: 90, // ③ かざすだけ
  noExtras: 180, // ④ 余計なものは、入れていない
  oneTime: 270, // ⑤ 毎月の支払いは、いらない
  onDevice: 360, // ⑥ 読んだ中身は、どこにも送らない
  endCard: 414, // ⑦ 誠実QRリーダー
  loop: 438, // fade back to scene ① so the loop has no visible seam
};

export const BRAND = {
  from: "#0F7F68",
  to: "#0A5F4E",
  mint: "#7FF0D2",
  glow: "#3CC7A6",
  ink: "#0A3B31",
};

export const FONT = "'Noto Sans CJK JP', 'Hiragino Sans', sans-serif";

/** Spring from 0 to 1 starting at `start` (no overshoot). */
export const rise = (frame: number, start: number, frames = 20) =>
  spring({ frame: frame - start, fps: FPS, durationInFrames: frames, config: { damping: 200 } });

/** Spring with a little overshoot, for objects that land. */
export const pop = (frame: number, start: number, frames = 24) =>
  spring({ frame: frame - start, fps: FPS, durationInFrames: frames, config: { damping: 14, stiffness: 120, mass: 0.8 } });

export const ramp = (frame: number, from: number, to: number) =>
  interpolate(frame, [from, to], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: Easing.bezier(0.33, 0, 0.2, 1) });

export const mix = (a: number, b: number, t: number) => a + (b - a) * t;
