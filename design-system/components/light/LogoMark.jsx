import React from "react";

/**
 * LogoMark — animated version of the AmbientNav symbol.
 * Each dot can light up sequentially, like a navigation turn indicator.
 *
 *   mode="ambient"     → all dots breathe slowly with gradient colours
 *   mode="guide"       → dots sequence from apex outward in `direction`
 *   mode="alert"       → all dots pulse magenta simultaneously
 *
 * API mirrors LightStrip for consistency.
 */

// Dot positions calculated from SVG paths with stroke-dasharray="0.1 11.5"
// Period = 11.6, dot centers at arc lengths: 0.05, 11.65, 23.25, 34.85, ...
//
// Left leg  (23,83)→(50,17): unit vector (0.3787, -0.9255), length 71.31
// Right leg (50,17)→(77,83): unit vector (0.3787, +0.9255), length 71.31
// Crossbar  (35,59)→(65,59): unit vector (1, 0),            length 30
const DOTS = [
  // Left leg — bottom to apex (index 0–5), then apex (index 6)
  { x: 23.0, y: 83.0, group: "left",  gradT: 0.00 },
  { x: 27.4, y: 72.2, group: "left",  gradT: 0.08 },
  { x: 31.8, y: 61.5, group: "left",  gradT: 0.17 },
  { x: 36.2, y: 50.8, group: "left",  gradT: 0.25 },
  { x: 40.6, y: 40.0, group: "left",  gradT: 0.33 },
  { x: 45.0, y: 29.3, group: "left",  gradT: 0.42 },
  { x: 49.4, y: 18.5, group: "apex",  gradT: 0.50 },
  // Right leg — apex to bottom (index 7–12)
  { x: 53.8, y: 26.2, group: "right", gradT: 0.58 },
  { x: 58.2, y: 36.9, group: "right", gradT: 0.67 },
  { x: 62.6, y: 47.7, group: "right", gradT: 0.75 },
  { x: 66.9, y: 58.4, group: "right", gradT: 0.83 },
  { x: 71.3, y: 69.2, group: "right", gradT: 0.92 },
  { x: 75.7, y: 79.9, group: "right", gradT: 1.00 },
  // Crossbar — left to right (index 13–15)
  { x: 35.1, y: 59.0, group: "bar",   gradT: 0.28 },
  { x: 46.7, y: 59.0, group: "bar",   gradT: 0.44 },
  { x: 58.3, y: 59.0, group: "bar",   gradT: 0.60 },
];

// Gradient stops: cyan(0) → violet(0.5) → magenta(1)
const STOPS = [
  [25, 227, 255],
  [124, 92, 255],
  [255, 45, 156],
];

function gradientColor(t, alpha = 1) {
  const seg = t * 2;
  const idx = Math.min(1, Math.floor(seg));
  const f = seg - idx;
  const mix = (a, b) => Math.round(a + (b - a) * f);
  const [r1, g1, b1] = STOPS[idx];
  const [r2, g2, b2] = STOPS[idx + 1];
  return `rgba(${mix(r1, r2)},${mix(g1, g2)},${mix(b1, b2)},${alpha.toFixed(2)})`;
}

// guide sequence: apex (idx 6) outward in given direction
const GUIDE_SEQ_RIGHT = [6, 7, 8, 9, 10, 11, 12]; // apex → right bottom
const GUIDE_SEQ_LEFT  = [6, 5, 4, 3, 2, 1, 0];    // apex → left bottom

const STEP_MS = 150;  // ms between each dot in guide mode
const CYCLE_MS = 1400; // total cycle duration

export function LogoMark({
  mode = "ambient",
  direction = "right",
  size = 100,
  style = {},
  ...rest
}) {
  const id = React.useId ? React.useId() : "lm";
  const keyframeId = `lm-${id}`.replace(/:/g, "");

  const guideSeq = direction === "right" ? GUIDE_SEQ_RIGHT : GUIDE_SEQ_LEFT;

  // Per-dot animation params
  const dotParams = DOTS.map((dot, i) => {
    if (mode === "guide") {
      const seqIdx = guideSeq.indexOf(i);
      const active = seqIdx !== -1;
      return {
        fill: active ? "rgba(25,227,255,0.18)" : "rgba(124,92,255,0.18)",
        animation: active
          ? `${keyframeId}-guide ${CYCLE_MS}ms ${STEP_MS * seqIdx}ms ease-in-out infinite`
          : "none",
        filter: "none",
      };
    }

    if (mode === "alert") {
      return {
        fill: "rgba(255,45,156,0.2)",
        animation: `${keyframeId}-alert 900ms ${i * 30}ms ease-in-out infinite`,
        filter: "none",
      };
    }

    // ambient: staggered breathe across full set
    const delay = (i / DOTS.length) * 3000;
    return {
      fill: gradientColor(dot.gradT, 0.35),
      animation: `${keyframeId}-amb 3000ms ${delay.toFixed(0)}ms ease-in-out infinite`,
      filter: "none",
    };
  });

  const glowColor =
    mode === "alert"
      ? "rgba(255,45,156,.6)"
      : mode === "guide"
      ? "rgba(25,227,255,.5)"
      : "rgba(124,92,255,.35)";

  return (
    <svg
      viewBox="0 0 100 100"
      width={size}
      height={size}
      style={{ overflow: "visible", ...style }}
      aria-hidden="true"
      {...rest}
    >
      <defs>
        <filter id={`${keyframeId}-glow`} x="-50%" y="-50%" width="200%" height="200%">
          <feGaussianBlur stdDeviation="3" result="blur" />
          <feComposite in="SourceGraphic" in2="blur" operator="over" />
        </filter>
      </defs>

      <style>{`
        @keyframes ${keyframeId}-amb {
          0%, 100% { opacity: 0.35; }
          50%       { opacity: 0.85; }
        }
        @keyframes ${keyframeId}-guide {
          0%   { opacity: 0.18; filter: none; }
          15%  { opacity: 1;    filter: drop-shadow(0 0 5px rgba(25,227,255,.9)); }
          45%  { opacity: 0.5;  filter: drop-shadow(0 0 3px rgba(25,227,255,.4)); }
          100% { opacity: 0.18; filter: none; }
        }
        @keyframes ${keyframeId}-alert {
          0%, 100% { opacity: 0.2; }
          50%       { opacity: 1;   filter: drop-shadow(0 0 6px rgba(255,45,156,.9)); }
        }
      `}</style>

      {/* Dim background paths to preserve logo silhouette */}
      <g
        fill="none"
        stroke={`rgba(255,255,255,0.06)`}
        strokeWidth="8.5"
        strokeLinecap="round"
        strokeDasharray="0.1 11.5"
      >
        <path d="M23 83 L50 17 L77 83" />
        <path d="M35 59 L65 59" />
      </g>

      {/* Animated dot layer */}
      <g style={{ filter: `drop-shadow(0 0 8px ${glowColor})` }}>
        {DOTS.map((dot, i) => (
          <circle
            key={i}
            cx={dot.x}
            cy={dot.y}
            r="4.25"
            fill={dotParams[i].fill}
            style={{
              animation: dotParams[i].animation,
              willChange: "opacity, filter",
            }}
          />
        ))}
      </g>
    </svg>
  );
}
