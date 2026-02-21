import React from "react";
import { Img, useCurrentFrame, useVideoConfig, spring, interpolate } from "remotion";
import type { BrandColors } from "../utils/types";
import { FONT_HEADING } from "../utils/fonts";

type BrandLogoProps = {
  logoUrl?: string;
  brandName?: string;
  colors: BrandColors;
  size?: number;
  position?: "top-left" | "top-right" | "bottom-left" | "bottom-right" | "center";
  animated?: boolean;
};

/**
 * Brand logo/watermark component. Shows logo image if provided,
 * otherwise renders brand name as text.
 */
export const BrandLogo: React.FC<BrandLogoProps> = ({
  logoUrl,
  brandName = "GAIA",
  colors,
  size = 60,
  position = "bottom-right",
  animated = true,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const scale = animated
    ? spring({ frame, fps, config: { damping: 200 }, delay: 5 })
    : 1;
  const opacity = animated
    ? interpolate(frame, [5, 5 + fps * 0.5], [0, 1], {
        extrapolateLeft: "clamp",
        extrapolateRight: "clamp",
      })
    : 1;

  const positionStyles = getPositionStyles(position, size);

  return (
    <div
      style={{
        position: "absolute",
        ...positionStyles,
        transform: `scale(${scale})`,
        opacity,
        zIndex: 100,
      }}
    >
      {logoUrl ? (
        <Img
          src={logoUrl}
          style={{
            width: size,
            height: size,
            objectFit: "contain",
          }}
        />
      ) : (
        <div
          style={{
            fontFamily: FONT_HEADING,
            fontSize: size * 0.5,
            fontWeight: 800,
            color: colors.primary,
            backgroundColor: "rgba(0,0,0,0.3)",
            padding: `${size * 0.1}px ${size * 0.2}px`,
            borderRadius: size * 0.1,
            letterSpacing: 2,
          }}
        >
          {brandName}
        </div>
      )}
    </div>
  );
};

function getPositionStyles(
  position: string,
  size: number,
): React.CSSProperties {
  const margin = size * 0.4;
  switch (position) {
    case "top-left":
      return { top: margin, left: margin };
    case "top-right":
      return { top: margin, right: margin };
    case "bottom-left":
      return { bottom: margin, left: margin };
    case "bottom-right":
      return { bottom: margin, right: margin };
    case "center":
      return {
        top: "50%",
        left: "50%",
        transform: "translate(-50%, -50%)",
      };
    default:
      return { bottom: margin, right: margin };
  }
}
