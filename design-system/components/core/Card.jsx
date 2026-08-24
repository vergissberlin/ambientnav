import React from "react";

/**
 * AmbientNav Card — flat dark surface, hairline border, soft radius, ambient drop.
 * No grey inner shadow, no colored left-stripe — state/hue is signaled via
 * corner brackets (`frame` prop), not a side stripe. See the Cybernetic Frame
 * section in readme.md. Optional hue glow on hover.
 */
export function Card({
  children,
  glow = "none",
  frame = false,
  padding = 28,
  style = {},
  ...rest
}) {
  const [hover, setHover] = React.useState(false);
  const glowMap = {
    none: "none",
    cyan: "var(--amb-glow-cyan)",
    violet: "var(--amb-glow-violet)",
    magenta: "var(--amb-glow-magenta)",
  };
  const frameColorMap = {
    cyan: "var(--amb-frame-color)",
    violet: "var(--amb-frame-color-brand)",
    magenta: "var(--amb-frame-color-alert)",
  };
  const frameColor = frameColorMap[glow] ?? "var(--amb-frame-color)";
  const frameOpacity = hover
    ? "var(--amb-frame-opacity-active)"
    : "var(--amb-frame-opacity-rest)";
  // Corner-bracket overlay: four small L-shaped borders, one per corner.
  // Kept purely decorative (no pointer events) and additive to the card's
  // own hairline border + radius.
  const bracket = (corner) => ({
    position: "absolute",
    width: "var(--amb-frame-leg)",
    height: "var(--amb-frame-leg)",
    borderColor: frameColor,
    borderStyle: "solid",
    borderWidth: 0,
    opacity: frameOpacity,
    transition: "opacity var(--dur-base) var(--ease-glow)",
    ...corner,
  });

  return (
    <div
      onMouseEnter={() => setHover(true)}
      onMouseLeave={() => setHover(false)}
      style={{
        position: "relative",
        background: hover ? "var(--amb-surface-3)" : "var(--amb-surface-2)",
        border: "1px solid var(--amb-line)",
        borderRadius: "var(--radius-lg)",
        padding,
        boxShadow: hover && glow !== "none"
          ? glowMap[glow]
          : "var(--shadow-card)",
        transition: "background var(--dur-base) var(--ease-glow), box-shadow var(--dur-base) var(--ease-glow)",
        ...style,
      }}
      {...rest}
    >
      {frame && (
        <>
          <span
            style={{
              ...bracket({ top: -1, left: -1 }),
              borderTopWidth: "var(--amb-frame-thickness)",
              borderLeftWidth: "var(--amb-frame-thickness)",
              borderTopLeftRadius: "var(--radius-frame)",
            }}
          />
          <span
            style={{
              ...bracket({ top: -1, right: -1 }),
              borderTopWidth: "var(--amb-frame-thickness)",
              borderRightWidth: "var(--amb-frame-thickness)",
              borderTopRightRadius: "var(--radius-frame)",
            }}
          />
          <span
            style={{
              ...bracket({ bottom: -1, left: -1 }),
              borderBottomWidth: "var(--amb-frame-thickness)",
              borderLeftWidth: "var(--amb-frame-thickness)",
              borderBottomLeftRadius: "var(--radius-frame)",
            }}
          />
          <span
            style={{
              ...bracket({ bottom: -1, right: -1 }),
              borderBottomWidth: "var(--amb-frame-thickness)",
              borderRightWidth: "var(--amb-frame-thickness)",
              borderBottomRightRadius: "var(--radius-frame)",
            }}
          />
        </>
      )}
      {children}
    </div>
  );
}
