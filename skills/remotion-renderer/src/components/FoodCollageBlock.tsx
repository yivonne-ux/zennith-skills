import React from "react";
import {
  AbsoluteFill,
  Img,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { ensureBrandFonts } from "../fonts";

ensureBrandFonts();

const MIRRA_SALMON = "#F7AB9F";

type CollageLayout = "grid_2x2" | "grid_3x2" | "masonry" | "diagonal";
type AnimationStyle = "stagger_pop" | "slide_in" | "scale_reveal";

interface FoodCollageBlockProps {
  images: string[];
  layout?: CollageLayout;
  durationInFrames: number;
  brandColor?: string;
  animationStyle?: AnimationStyle;
}

interface CellPosition {
  top: number;
  left: number;
  width: number;
  height: number;
}

function getGridPositions(layout: CollageLayout, count: number): CellPosition[] {
  const gap = 12;
  const pad = 24;
  const canvasW = 1080 - pad * 2;
  const canvasH = 1920 - pad * 2;

  switch (layout) {
    case "grid_2x2": {
      const cols = 2;
      const rows = Math.ceil(Math.min(count, 4) / cols);
      const cellW = (canvasW - gap * (cols - 1)) / cols;
      const cellH = (canvasH - gap * (rows - 1)) / rows;
      const offsetY = (canvasH - (cellH * rows + gap * (rows - 1))) / 2;
      return Array.from({ length: Math.min(count, 4) }, (_, i) => ({
        left: pad + (i % cols) * (cellW + gap),
        top: pad + offsetY + Math.floor(i / cols) * (cellH + gap),
        width: cellW,
        height: cellH,
      }));
    }
    case "grid_3x2": {
      const cols = 3;
      const rows = Math.ceil(Math.min(count, 6) / cols);
      const cellW = (canvasW - gap * (cols - 1)) / cols;
      const cellH = (canvasH - gap * (rows - 1)) / rows;
      const offsetY = (canvasH - (cellH * rows + gap * (rows - 1))) / 2;
      return Array.from({ length: Math.min(count, 6) }, (_, i) => ({
        left: pad + (i % cols) * (cellW + gap),
        top: pad + offsetY + Math.floor(i / cols) * (cellH + gap),
        width: cellW,
        height: cellH,
      }));
    }
    case "masonry": {
      // 2-column masonry with alternating tall/short cells
      const colW = (canvasW - gap) / 2;
      const positions: CellPosition[] = [];
      const colCursors = [pad, pad]; // track Y position per column
      const safeCount = Math.min(count, 6);
      for (let i = 0; i < safeCount; i++) {
        const col = i % 2;
        const isTall = i % 3 === 0;
        const cellH = isTall ? canvasH * 0.38 : canvasH * 0.28;
        positions.push({
          left: pad + col * (colW + gap),
          top: colCursors[col],
          width: colW,
          height: cellH,
        });
        colCursors[col] += cellH + gap;
      }
      return positions;
    }
    case "diagonal": {
      // Diagonal cascade from top-left to bottom-right
      const safeCount = Math.min(count, 6);
      const cellW = canvasW * 0.55;
      const cellH = canvasH * 0.28;
      const stepX = (canvasW - cellW) / Math.max(safeCount - 1, 1);
      const stepY = (canvasH - cellH) / Math.max(safeCount - 1, 1);
      return Array.from({ length: safeCount }, (_, i) => ({
        left: pad + stepX * i,
        top: pad + stepY * i,
        width: cellW,
        height: cellH,
      }));
    }
    default:
      return [];
  }
}

function getEntranceTransform(
  style: AnimationStyle,
  progress: number,
  index: number
): { opacity: number; transform: string } {
  switch (style) {
    case "stagger_pop":
      return {
        opacity: progress,
        transform: `scale(${interpolate(progress, [0, 1], [0.3, 1], { extrapolateRight: "clamp" })})`,
      };
    case "slide_in": {
      const direction = index % 2 === 0 ? -1 : 1;
      const tx = interpolate(progress, [0, 1], [200 * direction, 0], { extrapolateRight: "clamp" });
      return {
        opacity: progress,
        transform: `translateX(${tx}px)`,
      };
    }
    case "scale_reveal": {
      const s = interpolate(progress, [0, 1], [1.6, 1], { extrapolateRight: "clamp" });
      return {
        opacity: progress,
        transform: `scale(${s})`,
      };
    }
    default:
      return { opacity: 1, transform: "none" };
  }
}

export const FoodCollageBlock: React.FC<FoodCollageBlockProps> = ({
  images,
  layout = "grid_2x2",
  durationInFrames,
  brandColor = MIRRA_SALMON,
  animationStyle = "stagger_pop",
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Edge case: no images
  if (!images || images.length === 0) {
    return <AbsoluteFill style={{ backgroundColor: "#000" }} />;
  }

  const safeImages = images.slice(0, layout === "grid_3x2" ? 6 : layout === "grid_2x2" ? 4 : 6);
  const positions = getGridPositions(layout, safeImages.length);

  return (
    <AbsoluteFill style={{ backgroundColor: "#000", overflow: "hidden" }}>
      {safeImages.map((src, i) => {
        const pos = positions[i];
        if (!pos) return null;

        const staggerDelay = i * 5;
        const entranceProgress = spring({
          frame,
          fps,
          config: { damping: 14, stiffness: 100, mass: 0.8 },
          delay: staggerDelay,
        });

        const { opacity, transform: entranceTransform } = getEntranceTransform(
          animationStyle,
          entranceProgress,
          i
        );

        // Continuous float after entrance (subtle sine wave)
        const floatY = Math.sin((frame - staggerDelay) * 0.04 + i * 1.2) * 4;
        const floatX = Math.cos((frame - staggerDelay) * 0.03 + i * 0.8) * 2;

        // Ken Burns per cell: subtle zoom 1.0 → 1.06
        const kenBurns = interpolate(frame, [0, durationInFrames], [1.0, 1.06], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
        });

        // Glow pulse on brand color border
        const glowIntensity = interpolate(
          Math.sin(frame * 0.06 + i * 0.9),
          [-1, 1],
          [4, 10],
          { extrapolateRight: "clamp" }
        );

        return (
          <div
            key={i}
            style={{
              position: "absolute",
              top: pos.top,
              left: pos.left,
              width: pos.width,
              height: pos.height,
              borderRadius: 16,
              overflow: "hidden",
              opacity,
              transform: `${entranceTransform} translate(${floatX}px, ${floatY}px)`,
              boxShadow: `0 0 ${glowIntensity}px ${brandColor}`,
              border: `2px solid ${brandColor}40`,
            }}
          >
            <Img
              src={src}
              style={{
                width: "100%",
                height: "100%",
                objectFit: "cover",
                transform: `scale(${kenBurns})`,
                transformOrigin: "center center",
              }}
            />
          </div>
        );
      })}
    </AbsoluteFill>
  );
};
