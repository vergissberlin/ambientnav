import * as React from "react";

export interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  children: React.ReactNode;
  /** hue glow shown on hover */
  glow?: "none" | "cyan" | "violet" | "magenta";
  padding?: number;
  style?: React.CSSProperties;
}

/** Flat dark surface container with hairline border and ambient elevation. */
export function Card(props: CardProps): JSX.Element;
