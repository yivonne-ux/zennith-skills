import React from "react";
import {
  AbsoluteFill,
  Img,
  Sequence,
  useCurrentFrame,
  useVideoConfig,
  spring,
  interpolate,
  Easing,
} from "remotion";
import { GradientBackground } from "../components/GradientBackground";
import { FONT_HEADING, FONT_BODY } from "../utils/fonts";
import type { BrandColors, ProductFeature } from "../utils/types";
import { DEFAULT_BRAND_COLORS } from "../utils/types";
import { kenBurnsZoom, fadeIn, slideIn, staggerDelay } from "../utils/animations";

export type ProductShowcaseProps = {
  productImage: string;
  productName: string;
  price: string;
  features: string[];
  brandColors: BrandColors;
  ctaText: string;
  logoUrl?: string;
};

/**
 * ProductShowcase — Product image with Ken Burns zoom, sliding text overlays,
 * feature callouts, and a CTA at the end.
 * Format: 1080x1920 (9:16 vertical), 30fps, 15s default.
 */
export const ProductShowcase: React.FC<ProductShowcaseProps> = ({
  productImage,
  productName,
  price,
  features,
  brandColors = DEFAULT_BRAND_COLORS,
  ctaText = "Shop Now",
  logoUrl,
}) => {
  const frame = useCurrentFrame();
  const { fps, width, height, durationInFrames } = useVideoConfig();

  // Ken Burns zoom on product image
  const imageScale = kenBurnsZoom(frame, durationInFrames, 1.0, 1.2);

  // Product name slides in from left at 0.5s
  const nameDelay = Math.round(fps * 0.5);
  const nameSpring = spring({
    frame,
    fps,
    delay: nameDelay,
    config: { damping: 200 },
  });
  const nameX = interpolate(nameSpring, [0, 1], [-width, 0]);
  const nameOpacity = nameSpring;

  // Price tag pops in at 1.5s
  const priceDelay = Math.round(fps * 1.5);
  const priceSpring = spring({
    frame,
    fps,
    delay: priceDelay,
    config: { damping: 15, stiffness: 200 },
  });

  // Features stagger in starting at 3s
  const featuresStartDelay = Math.round(fps * 3);
  const featureStagger = Math.round(fps * 0.5);

  // CTA appears at last 3 seconds
  const ctaStartFrame = durationInFrames - Math.round(fps * 3);
  const ctaSpring = spring({
    frame,
    fps,
    delay: ctaStartFrame,
    config: { damping: 12 },
  });

  return (
    <AbsoluteFill>
      {/* Brand color gradient background */}
      <GradientBackground colors={brandColors} direction="vertical" />

      {/* Product image with Ken Burns zoom */}
      <div
        style={{
          position: "absolute",
          top: 0,
          left: 0,
          right: 0,
          height: height * 0.55,
          overflow: "hidden",
        }}
      >
        <Img
          src={productImage}
          style={{
            width: "100%",
            height: "100%",
            objectFit: "cover",
            transform: `scale(${imageScale})`,
          }}
        />
        {/* Gradient overlay at bottom of image */}
        <div
          style={{
            position: "absolute",
            bottom: 0,
            left: 0,
            right: 0,
            height: 200,
            background: `linear-gradient(transparent, ${brandColors.background})`,
          }}
        />
      </div>

      {/* Product name */}
      <div
        style={{
          position: "absolute",
          top: height * 0.52,
          left: 0,
          right: 0,
          padding: "0 50px",
          transform: `translateX(${nameX}px)`,
          opacity: nameOpacity,
        }}
      >
        <h1
          style={{
            fontFamily: FONT_HEADING,
            fontSize: 64,
            fontWeight: 800,
            color: brandColors.accent,
            margin: 0,
            lineHeight: 1.2,
          }}
        >
          {productName}
        </h1>
      </div>

      {/* Price tag */}
      <div
        style={{
          position: "absolute",
          top: height * 0.62,
          left: 50,
          transform: `scale(${priceSpring})`,
          transformOrigin: "left center",
        }}
      >
        <div
          style={{
            display: "inline-block",
            fontFamily: FONT_HEADING,
            fontSize: 48,
            fontWeight: 700,
            color: "white",
            backgroundColor: brandColors.secondary,
            padding: "10px 30px",
            borderRadius: 12,
            boxShadow: "0 4px 20px rgba(0,0,0,0.15)",
          }}
        >
          {price}
        </div>
      </div>

      {/* Features list */}
      <div
        style={{
          position: "absolute",
          top: height * 0.72,
          left: 50,
          right: 50,
        }}
      >
        {features.map((feature, i) => {
          const delay = featuresStartDelay + staggerDelay(i, featureStagger);
          const featureSpring = spring({
            frame,
            fps,
            delay,
            config: { damping: 200 },
          });
          const featureX = interpolate(featureSpring, [0, 1], [400, 0]);

          return (
            <div
              key={i}
              style={{
                display: "flex",
                alignItems: "center",
                marginBottom: 20,
                transform: `translateX(${featureX}px)`,
                opacity: featureSpring,
              }}
            >
              <div
                style={{
                  width: 12,
                  height: 12,
                  borderRadius: 6,
                  backgroundColor: brandColors.primary,
                  marginRight: 16,
                  flexShrink: 0,
                }}
              />
              <span
                style={{
                  fontFamily: FONT_BODY,
                  fontSize: 34,
                  color: brandColors.accent,
                  fontWeight: 600,
                }}
              >
                {feature}
              </span>
            </div>
          );
        })}
      </div>

      {/* CTA button */}
      <div
        style={{
          position: "absolute",
          bottom: 100,
          left: 0,
          right: 0,
          display: "flex",
          justifyContent: "center",
          transform: `scale(${ctaSpring})`,
        }}
      >
        <div
          style={{
            fontFamily: FONT_HEADING,
            fontSize: 42,
            fontWeight: 800,
            color: "white",
            backgroundColor: brandColors.accent,
            padding: "20px 60px",
            borderRadius: 60,
            boxShadow: `0 8px 30px ${brandColors.accent}66`,
            letterSpacing: 2,
            textTransform: "uppercase",
          }}
        >
          {ctaText}
        </div>
      </div>
    </AbsoluteFill>
  );
};
