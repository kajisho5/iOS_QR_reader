/** Four viewfinder corners, like the app's scan screen. */
export const Reticle = ({ size, color }: { size: number; color: string }) => {
  const s = 100, a = 22, w = 3.6;
  const corners = [
    `M0 ${a} V0 H${a}`,
    `M${s - a} 0 H${s} V${a}`,
    `M0 ${s - a} V${s} H${a}`,
    `M${s - a} ${s} H${s} V${s - a}`,
  ];
  return (
    <svg width={size} height={size} viewBox={`${-w} ${-w} ${s + w * 2} ${s + w * 2}`} style={{ display: "block", overflow: "visible" }}>
      {corners.map((d) => (
        <path key={d} d={d} fill="none" stroke={color} strokeWidth={w} strokeLinecap="round" strokeLinejoin="round" />
      ))}
    </svg>
  );
};
