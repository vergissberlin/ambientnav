import * as React from "react";

export interface BadgeProps extends React.HTMLAttributes<HTMLSpanElement> {
  children: React.ReactNode;
  /** neutral = hairline · cyan/violet/magenta = signal tones */
  tone?: "neutral" | "cyan" | "violet" | "magenta";
  /** add a hue glow for live/active states */
  glow?: boolean;
  style?: React.CSSProperties;
}

/** Small uppercase mono label for status, modes and hardware tags. */
export function Badge(props: BadgeProps): JSX.Element;
