import React from "react";
import {
  AbsoluteFill,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { ensureBrandFonts, FONT_BODY } from "../fonts";

ensureBrandFonts();

interface PersistentBadgeProps {
  /** Brand name text (e.g. "MIRRA") */
  brandName?: string;
  /** CTA text below brand (e.g. "ORDER NOW") */
  ctaText?: string;
  /** Text color */
  color?: string;
  /** Overall opacity */
  opacity?: number;
  /** Hide during specific time ranges (e.g. end card) */
  hideAfterS?: number;
}

/**
 * PersistentBadge — Text-only brand + CTA in bottom-right corner.
 *
 * Matches Grubhub style: just the brand name + CTA as plain text,
 * no background box, no logo image. Subtle shadow for readability.
 *
 * This is NOT a floating card. It's organic text on the video.
 */
export const PersistentBadge: React.FC<PersistentBadgeProps> = ({
  brandName = "MIRRA",
  ctaText = "ORDER NOW",
  color = "#FFFFFF",
  opacity = 0.95,
  hideAfterS,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Hide after a certain time (e.g. when end card starts)
  if (hideAfterS && frame / fps >= hideAfterS) return null;

  // Subtle entrance
  const entrance = spring({
    frame,
    fps,
    config: { damping: 20, stiffness: 100 },
    delay: 10,
  });

  const fadeIn = interpolate(entrance, [0, 1], [0, opacity], {
    extrapolateRight: "clamp",
  });

  const textShadow = "0 1px 6px rgba(0,0,0,0.5), 0 0 20px rgba(0,0,0,0.2)";

  return (
    <AbsoluteFill style={{ pointerEvents: "none" }}>
      <div
        style={{
          position: "absolute",
          bottom: 90,
          right: 40,
          display: "flex",
          flexDirection: "column",
          alignItems: "flex-end",
          gap: 2,
          opacity: fadeIn,
        }}
      >
        <span
          style={{
            fontFamily: FONT_BODY,
            fontWeight: 700,
            fontSize: 26,
            color,
            textShadow,
            letterSpacing: 3,
            textTransform: "uppercase" as const,
          }}
        >
          {brandName}
        </span>
        {ctaText && (
          <span
            style={{
              fontFamily: FONT_BODY,
              fontWeight: 500,
              fontSize: 16,
              color,
              textShadow,
              letterSpacing: 1.5,
              textTransform: "uppercase" as const,
              opacity: 0.85,
            }}
          >
            {ctaText}
          </span>
        )}
      </div>
    </AbsoluteFill>
  );
};
