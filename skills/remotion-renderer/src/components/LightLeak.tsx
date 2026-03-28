import React from "react";
import {
  AbsoluteFill,
  interpolate,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";

interface LightLeakProps {
  color?: string; // default: warm salmon glow
  position?: "top-left" | "top-right" | "bottom-left" | "bottom-right" | "center";
  durationInFrames: number;
  peakOpacity?: number; // default 0.15 (subtle)
}

/**
 * Light leak overlay — warm glow that fades in and out.
 * Used at AIDA phase transitions to add warmth and visual punctuation.
 * CSS gradient with screen blend mode — no extra packages needed.
 */
export const LightLeak: React.FC<LightLeakProps> = ({
  color = "rgba(246, 171, 159, 0.8)", // Mirra salmon
  position = "top-right",
  durationInFrames,
  peakOpacity = 0.15,
}) => {
  const frame = useCurrentFrame();

  // Fade in first 40%, hold 20%, fade out last 40%
  const opacity = interpolate(
    frame,
    [0, durationInFrames * 0.4, durationInFrames * 0.6, durationInFrames],
    [0, peakOpacity, peakOpacity, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
  );

  // Slight drift animation
  const drift = interpolate(
    frame,
    [0, durationInFrames],
    [0, 30],
    { extrapolateRight: "clamp" },
  );

  const positionMap: Record<string, string> = {
    "top-left": `radial-gradient(ellipse at ${15 + drift * 0.3}% ${20 + drift * 0.2}%, ${color}, transparent 70%)`,
    "top-right": `radial-gradient(ellipse at ${85 - drift * 0.3}% ${20 + drift * 0.2}%, ${color}, transparent 70%)`,
    "bottom-left": `radial-gradient(ellipse at ${15 + drift * 0.3}% ${80 - drift * 0.2}%, ${color}, transparent 70%)`,
    "bottom-right": `radial-gradient(ellipse at ${85 - drift * 0.3}% ${80 - drift * 0.2}%, ${color}, transparent 70%)`,
    "center": `radial-gradient(ellipse at ${50 + drift * 0.1}% ${50 + drift * 0.1}%, ${color}, transparent 60%)`,
  };

  return (
    <AbsoluteFill
      style={{
        background: positionMap[position] || positionMap["top-right"],
        mixBlendMode: "screen",
        opacity,
        pointerEvents: "none",
      }}
    />
  );
};
