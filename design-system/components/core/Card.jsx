import React from "react";

/**
 * AmbientNav Card — flat dark surface, hairline border, soft radius, ambient drop.
 * No grey inner shadow, no colored left-stripe. Optional hue glow on hover.
 */
export function Card({ children, glow = "none", padding = 28, style = {}, ...rest }) {
  const [hover, setHover] = React.useState(false);
  const glowMap = {
    none: "none",
    cyan: "var(--amb-glow-cyan)",
    violet: "var(--amb-glow-violet)",
    magenta: "var(--amb-glow-magenta)",
  };
  return (
    <div
      onMouseEnter={() => setHover(true)}
      onMouseLeave={() => setHover(false)}
      style={{
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
      {children}
    </div>
  );
}
