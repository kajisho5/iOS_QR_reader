import { CameraMotionBlur } from "@remotion/motion-blur";
import { AbsoluteFill, Composition, useCurrentFrame } from "remotion";
import { Promo } from "./Promo";
import { BRAND, DURATION, FPS, T } from "./timeline";

type Layout = "header" | "search";

/**
 * Frames where something moves fast enough to need motion blur. Elsewhere (holds, the slow drift) the frame is drawn
 * sharp: averaging identical samples would only add banding to the gradients (the icon tile, the green screen).
 */
const MOVING: [number, number][] = [
  [0, T.result + 10], // corners close, lock, the screen grows into the phone
  [T.noExtras - 2, T.noExtras + 18],
  [T.oneTime - 2, T.oneTime + 18],
  [T.onDevice - 2, T.onDevice + 18],
  [T.flood - 2, T.toIcon + 24], // the phone becomes the icon
  [T.dive - 4, DURATION],
];

/**
 * The promo with motion blur on everything that moves: 10 samples over half a frame (180°).
 * CameraMotionBlur, because HtmlInCanvasMotionBlur fails in the headless renderer here ("No cached paint record").
 */
const BlurredPromo = ({ layout }: { layout: Layout }) => {
  const frame = useCurrentFrame();
  const moving = MOVING.some(([from, to]) => frame >= from && frame < to);
  return (
    // The still background stays outside the blur: averaging it 10 times would band the gradient.
    <AbsoluteFill style={{ background: `linear-gradient(${BRAND.top}, ${BRAND.bottom})` }}>
      {moving ? (
        <CameraMotionBlur samples={10} shutterAngle={180}>
          <Promo layout={layout} />
        </CameraMotionBlur>
      ) : (
        <Promo layout={layout} />
      )}
    </AbsoluteFill>
  );
};

// App Store creative assets: product page header (21:9) and search results (3:2). 15-second loops, no audio.
export const RemotionRoot = () => (
  <>
    <Composition id="Header" component={BlurredPromo} durationInFrames={DURATION} fps={FPS} width={3840} height={1646} defaultProps={{ layout: "header" as const }} />
    <Composition id="Search" component={BlurredPromo} durationInFrames={DURATION} fps={FPS} width={3840} height={2560} defaultProps={{ layout: "search" as const }} />
  </>
);
