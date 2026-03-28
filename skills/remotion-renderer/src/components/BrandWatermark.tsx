import React from "react";
import { AbsoluteFill, Img, staticFile } from "remotion";

interface BrandWatermarkProps {
  logo?: string;
  text?: string;
  color?: string;
  opacity?: number;
}

/**
 * Persistent brand watermark — full-frame logo overlay on every frame.
 * Uses the Mirra Reels logo placement PNG (1080x1920, pre-positioned).
 * The PNG already has correct positioning — just render it full-frame.
 */
export const BrandWatermark: React.FC<BrandWatermarkProps> = ({
  logo = "mirra-watermark.png",
  text,
  color = "#ffffff",
  opacity = 0.85,
}) => {
  const logoSrc = logo.startsWith("http") ? logo : staticFile(logo);

  return (
    <AbsoluteFill
      style={{
        pointerEvents: "none",
      }}
    >
      {logo ? (
        <Img
          src={logoSrc}
          style={{
            width: "100%",
            height: "100%",
            objectFit: "contain",
            opacity,
          }}
        />
      ) : text ? (
        <AbsoluteFill
          style={{
            display: "flex",
            justifyContent: "flex-start",
            alignItems: "center",
            paddingTop: 60,
          }}
        >
          <span
            style={{
              fontWeight: 700,
              fontSize: 28,
              color,
              opacity,
              letterSpacing: 4,
              textTransform: "uppercase" as const,
              textShadow: "0 1px 4px rgba(0,0,0,0.5)",
            }}
          >
            {text}
          </span>
        </AbsoluteFill>
      ) : null}
    </AbsoluteFill>
  );
};
