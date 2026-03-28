import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";

interface FilmGrainProps {
  intensity?: number; // 0-1, default 0.04 (very subtle)
  speed?: number; // how fast grain changes, default 1
}

/**
 * Film grain overlay using SVG feTurbulence.
 * Renders a per-frame noise pattern that gives video a tactile, authentic feel.
 * At 0.04 intensity, it's barely visible but adds organic texture.
 */
export const FilmGrain: React.FC<FilmGrainProps> = ({
  intensity = 0.04,
  speed = 1,
}) => {
  const frame = useCurrentFrame();

  // Change seed every frame for animated grain
  const seed = Math.floor(frame * speed) % 1000;

  return (
    <AbsoluteFill
      style={{
        pointerEvents: "none",
        mixBlendMode: "overlay",
        opacity: intensity,
      }}
    >
      <svg width="100%" height="100%" style={{ position: "absolute" }}>
        <filter id={`grain-${seed}`}>
          <feTurbulence
            type="fractalNoise"
            baseFrequency="0.85"
            numOctaves={4}
            seed={seed}
            stitchTiles="stitch"
          />
          <feColorMatrix type="saturate" values="0" />
        </filter>
        <rect
          width="100%"
          height="100%"
          filter={`url(#grain-${seed})`}
          opacity={1}
        />
      </svg>
    </AbsoluteFill>
  );
};
