import React from "react";

/**
 * LightStrip — the signature AmbientNav element. A horizontal addressable-LED
 * strip that renders the brand's light language:
 *   mode="ambient" → calm idle gradient
 *   mode="guide"   → cyan flow toward `direction` ("left" | "right")
 *   mode="alert"   → magenta fills inward by `intensity` (0..1)
 */
export function LightStrip({
  mode = "ambient",
  direction = "right",
  intensity = 0.6,
  leds = 28,
  height = 16,
  style = {},
  ...rest
}) {
  const colorFor = (i) => {
    const t = i / (leds - 1);
    if (mode === "guide") {
      // brighten toward the travel direction
      const pos = direction === "right" ? t : 1 - t;
      const a = 0.12 + pos * 0.88;
      return `rgba(25,227,255,${a.toFixed(2)})`;
    }
    if (mode === "alert") {
      // fill inward from both ends as intensity rises
      const edge = Math.min(t, 1 - t) * 2; // 0 center .. 1 edges
      const on = edge >= 1 - intensity;
      return on ? `rgba(255,45,156,${(0.5 + intensity * 0.5).toFixed(2)})` : "rgba(255,45,156,0.08)";
    }
    // ambient: full gradient, dim
    const stops = ["25,227,255", "124,92,255", "255,45,156"];
    const seg = t * 2;
    const idx = Math.min(1, Math.floor(seg));
    const f = seg - idx;
    const mix = (a, b) => Math.round(a + (b - a) * f);
    const [r1, g1, b1] = stops[idx].split(",").map(Number);
    const [r2, g2, b2] = stops[idx + 1].split(",").map(Number);
    return `rgba(${mix(r1, r2)},${mix(g1, g2)},${mix(b1, b2)},0.55)`;
  };

  const glow = mode === "alert"
    ? "0 0 22px rgba(255,45,156,.55)"
    : mode === "guide"
    ? "0 0 22px rgba(25,227,255,.5)"
    : "0 0 18px rgba(124,92,255,.3)";

  return (
    <div
      style={{
        display: "flex",
        gap: 2,
        padding: 4,
        borderRadius: "var(--radius-strip)",
        background: "rgba(255,255,255,.03)",
        border: "1px solid var(--amb-line)",
        boxShadow: glow,
        ...style,
      }}
      {...rest}
    >
      {Array.from({ length: leds }).map((_, i) => (
        <div
          key={i}
          style={{
            flex: 1,
            height,
            borderRadius: 999,
            background: colorFor(i),
            transition: "background var(--dur-base) var(--ease-glow)",
          }}
        />
      ))}
    </div>
  );
}
