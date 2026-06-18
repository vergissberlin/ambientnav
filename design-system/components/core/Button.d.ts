import * as React from "react";

export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  children: React.ReactNode;
  /** primary = cyan guide · alert = magenta warning · gradient = hero CTA · secondary/ghost = quiet */
  variant?: "primary" | "alert" | "gradient" | "secondary" | "ghost";
  size?: "sm" | "md" | "lg";
  disabled?: boolean;
  iconLeft?: React.ReactNode;
  iconRight?: React.ReactNode;
  style?: React.CSSProperties;
}

/**
 * Primary action control for AmbientNav.
 * @startingPoint section="Core" subtitle="Signal-aware button set" viewport="700x150"
 */
export function Button(props: ButtonProps): JSX.Element;
