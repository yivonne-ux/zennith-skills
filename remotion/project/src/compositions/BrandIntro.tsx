import React from "react";
import {
  AbsoluteFill,
  Img,
  useCurrentFrame,
  useVideoConfig,
  spring,
  interpolate,
  Easing,
} from "remotion";
import { FONT_HEADING, FONT_BODY } from "../utils/fonts";
import type { BrandColors } from "../utils/types";
import { DEFAULT_BRAND_COLORS } from "../utils/types";

export type BrandIntroProps = {
  logoUrl?: string;
  brandName?: string;
  tagline: string;
  brandColors: BrandColors;
};

/**
 * BrandIntro — Logo animation (scale up + fade in), tagline text animation,
 * brand colors background with animated particles.
 * Format: 1080x1920 (9:16 vertical), 30fps, 5s default.
 */
export const BrandIntro: React.FC<BrandIntroProps> = ({
  logoUrl,
  brandName = "GAIA Eats",
  tagline,
  brandColors = DEFAULT_BRAND_COLORS,
}) => {
  const frame = useCurrentFrame();
  const { fps, width, height, durationInFrames } = useVideoConfig();

  // === Logo animation: scale from 0 to 1 with bounce ===
  const logoSpring = spring({
    frame,
    fps,
    delay: Math.round(fps * 0.3),
    config: { damping: 12, stiffness: 120 },
  });

  const logoScale = interpolate(logoSpring, [0, 1], [0.3, 1]);
  const logoOpacity = interpolate(logoSpring, [0, 0.3], [0, 1], {
    extrapolateRight: "clamp",
  });

  // === Logo glow pulse ===
  const glowProgress = interpolate(
    frame,
    [fps * 1, fps * 2.5],
    [0, Math.PI * 2],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
  );
  const glowIntensity = 0.3 + 0.2 * Math.sin(glowProgress);

  // === Tagline animation: words appear one by one ===
  const taglineWords = tagline.split(" ");
  const taglineStartFrame = Math.round(fps * 1.5);
  const wordDuration = Math.round(fps * 0.2);

  // === Decorative ring animation ===
  const ringSpring = spring({
    frame,
    fps,
    delay: Math.round(fps * 0.5),
    config: { damping: 200 },
  });
  const ringScale = interpolate(ringSpring, [0, 1], [0, 1]);
  const ringOpacity = interpolate(ringSpring, [0, 0.5, 1], [0, 0.6, 0.3]);

  // === Outro fade ===
  const outroStart = durationInFrames - Math.round(fps * 0.8);
  const outroOpacity = interpolate(
    frame,
    [outroStart, durationInFrames],
    [1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
  );

  return (
    <AbsoluteFill
      style={{
        backgroundColor: brandColors.background,
        opacity: outroOpacity,
      }}
    >
      {/* Animated gradient background */}
      <AbsoluteFill
        style={{
          background: `radial-gradient(ellipse at 50% 40%, ${brandColors.primary}33 0%, ${brandColors.background} 60%)`,
        }}
      />

      {/* Decorative rings */}
      <div
        style={{
          position: "absolute",
          top: height * 0.35,
          left: "50%",
          transform: `translate(-50%, -50%) scale(${ringScale})`,
          opacity: ringOpacity,
          width: 400,
          height: 400,
          borderRadius: "50%",
          border: `3px solid ${brandColors.primary}`,
        }}
      />
      <div
        style={{
          position: "absolute",
          top: height * 0.35,
          left: "50%",
          transform: `translate(-50%, -50%) scale(${ringScale * 0.85})`,
          opacity: ringOpacity * 0.7,
          width: 400,
          height: 400,
          borderRadius: "50%",
          border: `2px solid ${brandColors.secondary}`,
        }}
      />

      {/* Logo */}
      <div
        style={{
          position: "absolute",
          top: height * 0.25,
          left: 0,
          right: 0,
          display: "flex",
          justifyContent: "center",
          alignItems: "center",
          flexDirection: "column",
          transform: `scale(${logoScale})`,
          opacity: logoOpacity,
        }}
      >
        {logoUrl ? (
          <Img
            src={logoUrl}
            style={{
              width: 220,
              height: 220,
              objectFit: "contain",
              filter: `drop-shadow(0 0 ${40 * glowIntensity}px ${brandColors.primary})`,
            }}
          />
        ) : (
          <div
            style={{
              fontFamily: FONT_HEADING,
              fontSize: 120,
              fontWeight: 800,
              color: brandColors.accent,
              textShadow: `0 0 ${60 * glowIntensity}px ${brandColors.primary}`,
              letterSpacing: 6,
            }}
          >
            {brandName}
          </div>
        )}
      </div>

      {/* Tagline — word by word entrance */}
      <div
        style={{
          position: "absolute",
          top: height * 0.52,
          left: 60,
          right: 60,
          textAlign: "center",
        }}
      >
        <div
          style={{
            fontFamily: FONT_BODY,
            fontSize: 44,
            fontWeight: 600,
            lineHeight: 1.5,
            color: brandColors.accent,
          }}
        >
          {taglineWords.map((word, i) => {
            const wordStart = taglineStartFrame + i * wordDuration;
            const wordSpring = spring({
              frame,
              fps,
              delay: wordStart,
              config: { damping: 200 },
            });
            const wordY = interpolate(wordSpring, [0, 1], [20, 0]);

            return (
              <span
                key={i}
                style={{
                  display: "inline-block",
                  opacity: wordSpring,
                  transform: `translateY(${wordY}px)`,
                  marginRight: 10,
                }}
              >
                {word}
              </span>
            );
          })}
        </div>
      </div>

      {/* Decorative accent line */}
      <div
        style={{
          position: "absolute",
          top: height * 0.62,
          left: "50%",
          transform: "translateX(-50%)",
        }}
      >
        {(() => {
          const lineSpring = spring({
            frame,
            fps,
            delay: Math.round(fps * 2.2),
            config: { damping: 200 },
          });
          const lineWidth = interpolate(lineSpring, [0, 1], [0, 200]);
          return (
            <div
              style={{
                width: lineWidth,
                height: 4,
                backgroundColor: brandColors.secondary,
                borderRadius: 2,
              }}
            />
          );
        })()}
      </div>
    </AbsoluteFill>
  );
};
