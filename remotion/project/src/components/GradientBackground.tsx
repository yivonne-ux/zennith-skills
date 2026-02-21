import React from "react";
import { AbsoluteFill } from "remotion";
import type { BrandColors } from "../utils/types";

type GradientBackgroundProps = {
  colors: BrandColors;
  direction?: "diagonal" | "vertical" | "radial";
  dark?: boolean;
};

/**
 * Reusable gradient background component.
 * When dark=true, uses darkened versions of brand colors (good for podcast clips).
 */
export const GradientBackground: React.FC<GradientBackgroundProps> = ({
  colors,
  direction = "diagonal",
  dark = false,
}) => {
  const c1 = dark ? darken(colors.accent, 0.7) : colors.primary;
  const c2 = dark ? darken(colors.primary, 0.8) : colors.secondary;
  const c3 = dark ? "#0a0a0a" : colors.background;

  let background: string;
  switch (direction) {
    case "vertical":
      background = `linear-gradient(180deg, ${c1} 0%, ${c2} 50%, ${c3} 100%)`;
      break;
    case "radial":
      background = `radial-gradient(ellipse at center, ${c1} 0%, ${c2} 50%, ${c3} 100%)`;
      break;
    case "diagonal":
    default:
      background = `linear-gradient(135deg, ${c1} 0%, ${c2} 50%, ${c3} 100%)`;
      break;
  }

  return <AbsoluteFill style={{ background }} />;
};

/** Darken a hex color by a factor (0 = black, 1 = original) */
function darken(hex: string, factor: number): string {
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  const dr = Math.round(r * factor);
  const dg = Math.round(g * factor);
  const db = Math.round(b * factor);
  return `#${dr.toString(16).padStart(2, "0")}${dg.toString(16).padStart(2, "0")}${db.toString(16).padStart(2, "0")}`;
}
