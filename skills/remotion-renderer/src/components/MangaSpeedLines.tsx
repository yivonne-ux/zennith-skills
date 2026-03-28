import React, { useMemo } from "react";
import { useCurrentFrame, interpolate, Easing } from "remotion";

interface MangaSpeedLinesProps {
  startFrame: number;
  durationFrames: number;
  intensity?: number;
  color?: string;
  opacity?: number;
  centerX?: number;
  centerY?: number;
  motionBlur?: boolean;
}

interface SpeedLine {
  angle: number;
  length: number;
  widthStart: number;
  widthEnd: number;
  offset: number;
  shimmerPhase: number;
  gapStart: number;
}

/**
 * MangaSpeedLines — Radial concentration/impact lines inspired by manga panels.
 *
 * Renders animated black streaks emanating from a central vanishing point outward
 * to the edges of the frame, matching the "concentration lines" seen in Dragon Ball
 * or One Piece impact panels. Used as a dramatic impact/transition overlay.
 *
 * Composites via multiply blend mode so it darkens bright backgrounds naturally
 * while remaining invisible on black regions.
 */
export const MangaSpeedLines: React.FC<MangaSpeedLinesProps> = ({
  startFrame,
  durationFrames,
  intensity = 0.7,
  color = "#000000",
  opacity: maxOpacity = 0.85,
  centerX = 0.5,
  centerY = 0.5,
  motionBlur = true,
}) => {
  const frame = useCurrentFrame();
  const localFrame = frame - startFrame;

  // Number of lines scales with intensity: 30 at 0 to 60 at 1
  const lineCount = Math.round(30 + 30 * intensity);

  // Generate stable random lines using a seeded approach (MUST be before early return — hooks rule)
  const lines = useMemo<SpeedLine[]>(() => {
    const result: SpeedLine[] = [];
    // Simple seeded PRNG for deterministic output across frames
    const seed = (i: number) => {
      let x = Math.sin(i * 127.1 + 311.7) * 43758.5453;
      return x - Math.floor(x);
    };

    for (let i = 0; i < lineCount; i++) {
      const angle = (i / lineCount) * Math.PI * 2 + seed(i) * 0.15;
      const r1 = seed(i + 100);
      const r2 = seed(i + 200);
      const r3 = seed(i + 300);
      const r4 = seed(i + 400);

      // Width at the thin end (near center): 1-2px
      const widthStart = 1 + r1 * 1;
      // Width at the thick end (edges): scales with intensity 8-20px
      const widthEnd = 8 + r2 * 12 * intensity;
      // How far from center the line starts (small gap so center isn't solid)
      const gapStart = 0.03 + r3 * 0.07;
      // Line length variation (0.7 to 1.0 of max radius)
      const length = 0.7 + r4 * 0.3;

      result.push({
        angle,
        length,
        widthStart,
        widthEnd,
        offset: seed(i + 500) * 0.3, // slight radial offset for organic feel
        shimmerPhase: seed(i + 600) * Math.PI * 2,
        gapStart,
      });
    }
    return result;
  }, [lineCount, intensity]);

  // Not visible outside the active range (after hooks)
  if (localFrame < 0 || localFrame >= durationFrames) {
    return null;
  }

  // --- Animations ---

  // Scale-up: 0 to full over first 5 frames
  const scaleProgress = interpolate(localFrame, [0, 5], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.out(Easing.cubic),
  });

  // Fade envelope: fade in 3 frames, hold, fade out last 5 frames
  const fadeIn = interpolate(localFrame, [0, 3], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const fadeOut = interpolate(
    localFrame,
    [durationFrames - 5, durationFrames],
    [1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );
  const envelope = Math.min(fadeIn, fadeOut) * maxOpacity;

  // Shimmer: subtle per-frame opacity variation
  const shimmerTime = localFrame * 0.8;

  // Viewport diagonal for line length calculation (1080x1920)
  const W = 1080;
  const H = 1920;
  const maxRadius = Math.sqrt(W * W + H * H) * 0.6;
  const cx = centerX * W;
  const cy = centerY * H;

  return (
    <div
      style={{
        position: "absolute",
        top: 0,
        left: 0,
        width: W,
        height: H,
        zIndex: 5,
        pointerEvents: "none",
        mixBlendMode: "multiply",
        opacity: envelope,
        ...(motionBlur
          ? { filter: `blur(${interpolate(scaleProgress, [0, 1], [2, 0.5])}px)` }
          : {}),
      }}
    >
      <svg
        width={W}
        height={H}
        viewBox={`0 0 ${W} ${H}`}
        xmlns="http://www.w3.org/2000/svg"
      >
        {lines.map((line, i) => {
          // Per-line shimmer: subtle opacity oscillation
          const shimmer =
            0.85 +
            0.15 *
              Math.sin(shimmerTime + line.shimmerPhase);

          // Scale animation affects line extension from center
          const effectiveScale = scaleProgress;

          // Start and end points
          const startR = line.gapStart * maxRadius;
          const endR = startR + (maxRadius * line.length - startR) * effectiveScale;

          const cosA = Math.cos(line.angle);
          const sinA = Math.sin(line.angle);

          const x1 = cx + cosA * startR;
          const y1 = cy + sinA * startR;
          const x2 = cx + cosA * endR;
          const y2 = cy + sinA * endR;

          // Taper: line gets wider toward the edge
          // We draw it as a polygon (quad) for the taper effect
          const perpX = -sinA;
          const perpY = cosA;

          const halfStart = line.widthStart * 0.5;
          const halfEnd = (line.widthEnd * 0.5) * effectiveScale;

          const p1x = x1 + perpX * halfStart;
          const p1y = y1 + perpY * halfStart;
          const p2x = x1 - perpX * halfStart;
          const p2y = y1 - perpY * halfStart;
          const p3x = x2 - perpX * halfEnd;
          const p3y = y2 - perpY * halfEnd;
          const p4x = x2 + perpX * halfEnd;
          const p4y = y2 + perpY * halfEnd;

          return (
            <polygon
              key={i}
              points={`${p1x},${p1y} ${p4x},${p4y} ${p3x},${p3y} ${p2x},${p2y}`}
              fill={color}
              opacity={shimmer * intensity}
            />
          );
        })}
      </svg>
    </div>
  );
};
