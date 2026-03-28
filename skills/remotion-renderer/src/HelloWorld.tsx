import React from "react";
import {
  AbsoluteFill,
  interpolate,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";

export const HelloWorld: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Fade in over 2 seconds
  const opacity = interpolate(frame, [0, 2 * fps], [0, 1], {
    extrapolateRight: "clamp",
  });

  // Subtle scale: 0.92 → 1.0 over first 1.5s
  const scale = interpolate(frame, [0, 1.5 * fps], [0.92, 1], {
    extrapolateRight: "clamp",
  });

  return (
    <AbsoluteFill
      style={{
        backgroundColor: "#0f0f0f",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
      }}
    >
      <div
        style={{
          opacity,
          transform: `scale(${scale})`,
          fontFamily: "'Montserrat', 'Arial Black', sans-serif",
          fontWeight: 800,
          fontSize: 120,
          color: "#ffffff",
          letterSpacing: "-2px",
          textAlign: "center",
        }}
      >
        Hello World
      </div>
    </AbsoluteFill>
  );
};
