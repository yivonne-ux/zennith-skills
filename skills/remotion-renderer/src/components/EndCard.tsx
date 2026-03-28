import React from "react";
import {
  AbsoluteFill,
  Img,
  interpolate,
  spring,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import {
  ensureBrandFonts,
  FONT_HEADING,
  FONT_BODY,
} from "../fonts";

ensureBrandFonts();

// Brand guide colors
const MIRRA_SALMON = "#F7AB9F";
const NEAR_BLACK = "#252525";
const WARM_CREAM = "#FFF9EB";

interface EndCardProps {
  headline: string;
  subHeadline?: string;
  ctaText: string;
  bgColor?: string;
  logo?: string;
  productImages?: string[];
  durationInFrames: number;
}

/**
 * Branded CTA end card — uses brand guide colors + actual brand fonts.
 *
 * NOTE: For Mirra, prefer using the actual Mirra-Logo Ending.mp4 video block.
 * This component is a fallback for programmatic end cards.
 */
export const EndCard: React.FC<EndCardProps> = ({
  headline,
  subHeadline,
  ctaText,
  bgColor = MIRRA_SALMON,
  logo = "mirra-logo-black.png",
  productImages,
  durationInFrames,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const fadeIn = interpolate(frame, [0, 12], [0, 1], {
    extrapolateRight: "clamp",
  });

  const headlineSpring = spring({
    frame,
    fps,
    config: { damping: 200 },
    delay: 4,
  });
  const subSpring = spring({
    frame,
    fps,
    config: { damping: 200 },
    delay: 8,
  });
  const ctaSpring = spring({
    frame,
    fps,
    config: { damping: 15, stiffness: 120 },
    delay: 12,
  });

  const logoSrc = logo.startsWith("http") ? logo : staticFile(logo);

  return (
    <AbsoluteFill
      style={{
        backgroundColor: bgColor,
        opacity: fadeIn,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        padding: "60px 48px",
      }}
    >
      {/* Brand logo top — actual PNG */}
      <Img
        src={logoSrc}
        style={{
          width: 180,
          height: "auto",
          position: "absolute",
          top: 120,
          opacity: headlineSpring,
        }}
      />

      {/* Headline — Awesome Serif Bold */}
      <div
        style={{
          opacity: headlineSpring,
          transform: `translateY(${interpolate(headlineSpring, [0, 1], [30, 0])}px)`,
        }}
      >
        <h1
          style={{
            fontFamily: FONT_HEADING,
            fontWeight: 700,
            fontSize: 64,
            color: NEAR_BLACK,
            textAlign: "center",
            margin: 0,
            lineHeight: 1.2,
          }}
        >
          {headline}
        </h1>
      </div>

      {/* Sub-headline — Mabry Pro Medium */}
      {subHeadline && (
        <div
          style={{
            opacity: subSpring,
            transform: `translateY(${interpolate(subSpring, [0, 1], [20, 0])}px)`,
            marginTop: 20,
          }}
        >
          <p
            style={{
              fontFamily: FONT_BODY,
              fontWeight: 500,
              fontSize: 28,
              color: NEAR_BLACK,
              textAlign: "center",
              margin: 0,
              opacity: 0.7,
            }}
          >
            {subHeadline}
          </p>
        </div>
      )}

      {/* CTA Button */}
      <div
        style={{
          opacity: ctaSpring,
          transform: `scale(${interpolate(ctaSpring, [0, 1], [0.8, 1])})`,
          marginTop: 40,
        }}
      >
        <div
          style={{
            backgroundColor: NEAR_BLACK,
            borderRadius: 50,
            padding: "18px 60px",
            display: "inline-flex",
            alignItems: "center",
            justifyContent: "center",
          }}
        >
          <span
            style={{
              fontFamily: FONT_BODY,
              fontWeight: 700,
              fontSize: 32,
              color: WARM_CREAM,
              letterSpacing: 2,
            }}
          >
            {ctaText}
          </span>
        </div>
      </div>

      {/* Product images in corners (optional) */}
      {productImages && productImages.length > 0 && (
        <>
          {productImages[0] && (
            <Img
              src={productImages[0]}
              style={{
                position: "absolute",
                bottom: 80,
                left: 40,
                width: 200,
                height: 200,
                objectFit: "cover",
                borderRadius: 16,
                opacity: headlineSpring,
              }}
            />
          )}
          {productImages[1] && (
            <Img
              src={productImages[1]}
              style={{
                position: "absolute",
                bottom: 80,
                right: 40,
                width: 200,
                height: 200,
                objectFit: "cover",
                borderRadius: 16,
                opacity: headlineSpring,
              }}
            />
          )}
        </>
      )}
    </AbsoluteFill>
  );
};
