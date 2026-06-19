import * as React from "react";

export interface LightStripProps extends React.HTMLAttributes<HTMLDivElement> {
  /** ambient = idle gradient · guide = cyan directional flow · alert = magenta proximity fill */
  mode?: "ambient" | "guide" | "alert";
  /** travel direction for guide mode */
  direction?: "left" | "right";
  /** 0..1 proximity fill amount for alert mode */
  intensity?: number;
  /** number of LEDs to render */
  leds?: number;
  height?: number;
  style?: React.CSSProperties;
}

/**
 * The signature AmbientNav LED strip — renders the brand light language.
 * @startingPoint section="Light" subtitle="Addressable LED strip graphic" viewport="700x120"
 */
export function LightStrip(props: LightStripProps): JSX.Element;
