import { Img, staticFile } from "remotion";
import type { Box } from "../timeline";

const CORNERS = ["tl", "tr", "bl", "br"] as const;

/**
 * The app icon's four glass viewfinder corners (rendered with fresnel from docs/design/icon), framing `box`:
 * the outer tip of each corner sits on the matching corner of the box. `px` is the width of the icon's 1024 grid
 * the corners are drawn at; `mint` (0…1) blends in the mint version.
 */
export const GlassCorners = ({ box, px, mint }: { box: Box; px: number; mint: number }) => {
  const half = px / 2;
  // In the icon the corner tips are 184/1024 in from the edge; each image is one quadrant of the icon.
  const near = 0.18 * px;
  const far = 0.32 * px;
  const at = {
    tl: [box.x - near, box.y - near],
    tr: [box.x + box.w - far, box.y - near],
    bl: [box.x - near, box.y + box.h - far],
    br: [box.x + box.w - far, box.y + box.h - far],
  };
  return (
    <>
      {CORNERS.map((c) => (
        <div key={c} style={{ position: "absolute", left: at[c][0], top: at[c][1], width: half, height: half }}>
          <Img src={staticFile(`mark-corner-${c}.png`)} style={{ position: "absolute", width: "100%", height: "100%" }} />
          {mint > 0 ? (
            <Img src={staticFile(`mark-corner-${c}-mint.png`)} style={{ position: "absolute", width: "100%", height: "100%", opacity: mint }} />
          ) : null}
        </div>
      ))}
    </>
  );
};

/** Where the corners sit in the icon itself, for an icon grid `px` wide centred on (cx, cy), pushed out by `gap`. */
export const iconBox = (cx: number, cy: number, px: number, gap = 0): Box => ({
  x: cx - 0.32 * px - gap,
  y: cy - 0.32 * px - gap,
  w: 0.64 * px + gap * 2,
  h: 0.64 * px + gap * 2,
});
