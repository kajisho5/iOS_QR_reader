import { CameraMotionBlur } from "@remotion/motion-blur";
import { AbsoluteFill, Composition } from "remotion";
import { Promo } from "./Promo";
import { BRAND, DURATION, FPS } from "./timeline";

type Layout = "header" | "search";

/**
 * The promo with motion blur on everything that moves: each frame averages 10 samples over half a frame (180°).
 * CameraMotionBlur, because HtmlInCanvasMotionBlur fails in the headless renderer here ("No cached paint record").
 */
const BlurredPromo = ({ layout }: { layout: Layout }) => (
  // The still background stays outside the blur: averaging it 10 times would band the gradient.
  <AbsoluteFill style={{ background: `linear-gradient(${BRAND.top}, ${BRAND.bottom})` }}>
    <CameraMotionBlur samples={10} shutterAngle={180}>
      <Promo layout={layout} />
    </CameraMotionBlur>
  </AbsoluteFill>
);

// App Store creative assets: product page header (21:9) and search results (3:2). 15-second loops, no audio.
export const RemotionRoot = () => (
  <>
    <Composition id="Header" component={BlurredPromo} durationInFrames={DURATION} fps={FPS} width={3840} height={1646} defaultProps={{ layout: "header" as const }} />
    <Composition id="Search" component={BlurredPromo} durationInFrames={DURATION} fps={FPS} width={3840} height={2560} defaultProps={{ layout: "search" as const }} />
  </>
);
