/**
 * The app icon's mark (docs/design/icon/src/viewfinder.svg + qr.svg), drawn large on the background so the
 * opening matches the icon. The corners scale around the centre to "close in" on the code.
 */
export const IconMark = ({
  size,
  bracketScale,
  bracketColor,
}: {
  size: number;
  bracketScale: number;
  bracketColor: string;
}) => (
  <svg width={size} height={size} viewBox="0 0 1024 1024" style={{ display: "block", overflow: "visible" }}>
    <defs>
      <filter id="markShadow" x="-20%" y="-20%" width="140%" height="140%">
        <feDropShadow dx="0" dy="14" stdDeviation="18" floodColor="#00261C" floodOpacity="0.35" />
      </filter>
    </defs>
    <g fill="#FFFFFF" opacity={0.96} filter="url(#markShadow)">
      <path fillRule="evenodd" d="M342 342h150v150H342zM384 384v66h66v-66zM532 342h150v150H532zM574 384v66h66v-66zM342 532h150v150H342zM384 574v66h66v-66z" />
      <rect x="532" y="532" width="62" height="62" rx="10" />
      <rect x="620" y="620" width="62" height="62" rx="10" />
      <rect x="620" y="532" width="62" height="42" rx="10" />
      <rect x="532" y="640" width="42" height="42" rx="10" />
    </g>
    <g transform={`translate(512 512) scale(${bracketScale}) translate(-512 -512)`} filter="url(#markShadow)">
      <path
        d="M212 352V282a70 70 0 0 1 70-70h70M672 212h70a70 70 0 0 1 70 70v70M812 672v70a70 70 0 0 1-70 70h-70M352 812h-70a70 70 0 0 1-70-70v-70"
        fill="none"
        stroke={bracketColor}
        strokeWidth={56 / bracketScale}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </g>
  </svg>
);
