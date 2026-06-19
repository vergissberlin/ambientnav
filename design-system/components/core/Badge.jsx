import React from "react";

/**
 * AmbientNav Badge — a small mono label. Use for status, modes, hardware tags.
 * tone maps to the signal palette; `glow` adds a hue bloom for live states.
 */
export function Badge({ children, tone = "neutral", glow = false, style = {}, ...rest }) {
  const tones = {
    neutral: { color: "var(--amb-text-3)", border: "1px solid var(--amb-line-strong)", bg: "transparent" },
    cyan: { color: "var(--amb-cyan)", border: "1px solid rgba(25,227,255,.4)", bg: "rgba(25,227,255,.08)" },
    violet: { color: "var(--amb-violet-soft)", border: "1px solid rgba(124,92,255,.4)", bg: "rgba(124,92,255,.08)" },
    magenta: { color: "var(--amb-magenta-soft)", border: "1px solid rgba(255,45,156,.4)", bg: "rgba(255,45,156,.08)" },
  };
  const t = tones[tone];
  const glowMap = {
    cyan: "var(--amb-glow-cyan)",
    violet: "var(--amb-glow-violet)",
    magenta: "var(--amb-glow-magenta)",
    neutral: "none",
  };
  return (
    <span
      style={{
        display: "inline-flex",
        alignItems: "center",
        gap: 6,
        fontFamily: "var(--font-mono)",
        fontSize: 11.5,
        letterSpacing: "0.1em",
        textTransform: "uppercase",
        whiteSpace: "nowrap",
        padding: "6px 11px",
        borderRadius: "var(--radius-xs)",
        color: t.color,
        border: t.border,
        background: t.bg,
        boxShadow: glow ? glowMap[tone] : "none",
        ...style,
      }}
      {...rest}
    >
      {children}
    </span>
  );
}
