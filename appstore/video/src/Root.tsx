import { Composition } from "remotion";
import { Promo } from "./Promo";
import { DURATION, FPS } from "./timeline";

// App Store creative assets: product page header (21:9) and search results (3:2). 15-second loops, no audio.
export const RemotionRoot = () => (
  <>
    <Composition id="Header" component={Promo} durationInFrames={DURATION} fps={FPS} width={3840} height={1646} defaultProps={{ layout: "header" as const }} />
    <Composition id="Search" component={Promo} durationInFrames={DURATION} fps={FPS} width={3840} height={2560} defaultProps={{ layout: "search" as const }} />
  </>
);
