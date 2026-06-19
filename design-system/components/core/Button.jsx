import React from "react";

/**
 * AmbientNav Button — geometric, calm, signal-aware.
 * Variants map to the light language: primary (cyan guide), alert (magenta),
 * ghost (quiet), gradient (brand hero CTA).
 */
export function Button({
  children,
  variant = "primary",
  size = "md",
  disabled = false,
  iconLeft = null,
  iconRight = null,
  onClick,
  style = {},
  ...rest
}) {
  const sizes = {
    sm: { padding: "8px 14px", fontSize: 13 },
    md: { padding: "12px 20px", fontSize: 15 },
    lg: { padding: "15px 28px", fontSize: 16 },
  };

  const base = {
    display: "inline-flex",
    alignItems: "center",
    justifyContent: "center",
    gap: 9,
    fontFamily: "var(--font-display)",
    fontWeight: 600,
    letterSpacing: "-0.01em",
    border: "1px solid transparent",
    borderRadius: "var(--radius-sm)",
    cursor: disabled ? "not-allowed" : "pointer",
    opacity: disabled ? 0.4 : 1,
    transition: "transform var(--dur-fast) var(--ease-glow), background var(--dur-base) var(--ease-glow), box-shadow var(--dur-base) var(--ease-glow)",
    whiteSpace: "nowrap",
    ...sizes[size],
  };

  const variants = {
    primary: {
      background: "var(--amb-cyan)",
      color: "#05323A",
      boxShadow: "var(--amb-glow-cyan)",
    },
    alert: {
      background: "var(--amb-magenta)",
      color: "#2A0719",
      boxShadow: "var(--amb-glow-magenta)",
    },
    gradient: {
      background: "var(--amb-gradient-h)",
      color: "#06080E",
      boxShadow: "0 0 26px rgba(124,92,255,.5)",
    },
    secondary: {
      background: "var(--amb-surface-3)",
      color: "var(--amb-text)",
      border: "1px solid var(--amb-line-strong)",
    },
    ghost: {
      background: "transparent",
      color: "var(--amb-text-2)",
      border: "1px solid var(--amb-line)",
    },
  };

  return (
    <button
      type="button"
      disabled={disabled}
      onClick={onClick}
      style={{ ...base, ...variants[variant], ...style }}
      onMouseDown={(e) => { if (!disabled) e.currentTarget.style.transform = "scale(0.97)"; }}
      onMouseUp={(e) => { e.currentTarget.style.transform = "scale(1)"; }}
      onMouseLeave={(e) => { e.currentTarget.style.transform = "scale(1)"; }}
      {...rest}
    >
      {iconLeft}
      {children}
      {iconRight}
    </button>
  );
}
