import React, { useMemo } from "react";
import {
  AbsoluteFill,
  Sequence,
  useCurrentFrame,
  useVideoConfig,
  spring,
  interpolate,
  Easing,
} from "remotion";
import { Video } from "@remotion/media";
import { createTikTokStyleCaptions } from "@remotion/captions";
import type { Caption } from "@remotion/captions";
import { FONT_HEADING } from "../utils/fonts";
import type { CaptionStyle, CaptionPosition, BrandColors } from "../utils/types";
import { DEFAULT_BRAND_COLORS } from "../utils/types";

export type AnimatedCaptionsProps = {
  videoUrl: string;
  captions: Caption[];
  style: CaptionStyle;
  fontFamily?: string;
  fontSize?: number;
  position: CaptionPosition;
  brandColors: BrandColors;
};

const SWITCH_CAPTIONS_EVERY_MS = 1200;

/**
 * AnimatedCaptions — Renders word-by-word animated captions over a background video.
 * Supports three styles: tiktok (yellow highlight), karaoke (color sweep), bounce (scale).
 * Format: 1080x1920 (9:16 vertical), 30fps.
 */
export const AnimatedCaptions: React.FC<AnimatedCaptionsProps> = ({
  videoUrl,
  captions,
  style = "tiktok",
  fontFamily,
  fontSize = 72,
  position = "bottom",
  brandColors = DEFAULT_BRAND_COLORS,
}) => {
  const resolvedFontFamily = fontFamily || FONT_HEADING;

  // Create caption pages
  const { pages } = useMemo(() => {
    return createTikTokStyleCaptions({
      captions,
      combineTokensWithinMilliseconds: SWITCH_CAPTIONS_EVERY_MS,
    });
  }, [captions]);

  const { fps } = useVideoConfig();

  const positionStyle = getPositionStyle(position);

  return (
    <AbsoluteFill>
      {/* Background video */}
      <Video
        src={videoUrl}
        style={{
          width: "100%",
          height: "100%",
          objectFit: "cover",
        }}
      />

      {/* Semi-transparent overlay for readability */}
      <AbsoluteFill
        style={{
          background:
            "linear-gradient(0deg, rgba(0,0,0,0.6) 0%, transparent 30%, transparent 70%, rgba(0,0,0,0.3) 100%)",
        }}
      />

      {/* Caption pages */}
      <AbsoluteFill>
        {pages.map((page, index) => {
          const nextPage = pages[index + 1] ?? null;
          const startFrame = Math.round((page.startMs / 1000) * fps);
          const endFrame = Math.min(
            nextPage ? Math.round((nextPage.startMs / 1000) * fps) : Infinity,
            startFrame + Math.round((SWITCH_CAPTIONS_EVERY_MS / 1000) * fps),
          );
          const durationInFrames = endFrame - startFrame;

          if (durationInFrames <= 0) return null;

          return (
            <Sequence
              key={index}
              from={startFrame}
              durationInFrames={durationInFrames}
            >
              <CaptionPageRenderer
                page={page}
                captionStyle={style}
                fontFamily={resolvedFontFamily}
                fontSize={fontSize}
                positionStyle={positionStyle}
                brandColors={brandColors}
              />
            </Sequence>
          );
        })}
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

function getPositionStyle(position: CaptionPosition): React.CSSProperties {
  switch (position) {
    case "top":
      return { top: 120, bottom: "auto" };
    case "center":
      return { top: "50%", transform: "translateY(-50%)" };
    case "bottom":
    default:
      return { bottom: 180, top: "auto" };
  }
}

/** Renders a single page of captions with the chosen animation style */
const CaptionPageRenderer: React.FC<{
  page: { startMs: number; tokens: Array<{ text: string; fromMs: number; toMs: number }> };
  captionStyle: CaptionStyle;
  fontFamily: string;
  fontSize: number;
  positionStyle: React.CSSProperties;
  brandColors: BrandColors;
}> = ({ page, captionStyle, fontFamily, fontSize, positionStyle, brandColors }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const currentTimeMs = (frame / fps) * 1000;
  const absoluteTimeMs = page.startMs + currentTimeMs;

  // Page entrance animation
  const pageEntrance = spring({
    frame,
    fps,
    config: { damping: 200 },
  });
  const pageOpacity = interpolate(pageEntrance, [0, 1], [0, 1]);

  return (
    <div
      style={{
        position: "absolute",
        left: 40,
        right: 40,
        ...positionStyle,
        textAlign: "center",
        opacity: pageOpacity,
      }}
    >
      <div
        style={{
          fontFamily,
          fontSize,
          fontWeight: 800,
          lineHeight: 1.3,
          whiteSpace: "pre-wrap",
          textShadow: "0 4px 12px rgba(0,0,0,0.9), 0 1px 3px rgba(0,0,0,0.8)",
        }}
      >
        {page.tokens.map((token, i) => {
          const isActive =
            token.fromMs <= absoluteTimeMs && token.toMs > absoluteTimeMs;
          const isPast = token.toMs <= absoluteTimeMs;

          const wordStyle = getWordStyle(
            captionStyle,
            isActive,
            isPast,
            frame,
            fps,
            token,
            absoluteTimeMs,
            brandColors,
          );

          return (
            <span
              key={`${token.fromMs}-${i}`}
              style={{
                display: "inline-block",
                ...wordStyle,
              }}
            >
              {token.text}
            </span>
          );
        })}
      </div>
    </div>
  );
};

function getWordStyle(
  style: CaptionStyle,
  isActive: boolean,
  isPast: boolean,
  frame: number,
  fps: number,
  token: { fromMs: number; toMs: number },
  absoluteTimeMs: number,
  brandColors: BrandColors,
): React.CSSProperties {
  switch (style) {
    case "tiktok": {
      // Yellow/gold highlight on active word, white otherwise
      if (isActive) {
        return {
          color: "#FFE135",
          backgroundColor: "rgba(0,0,0,0.5)",
          padding: "2px 6px",
          borderRadius: 4,
          transform: "scale(1.05)",
        };
      }
      return {
        color: isPast ? "rgba(255,255,255,0.7)" : "white",
      };
    }

    case "karaoke": {
      // Color sweeps from left to right as word progresses
      if (isActive) {
        const wordDuration = token.toMs - token.fromMs;
        const elapsed = absoluteTimeMs - token.fromMs;
        const progress = Math.min(1, Math.max(0, elapsed / wordDuration));
        const percentage = Math.round(progress * 100);
        return {
          backgroundImage: `linear-gradient(90deg, ${brandColors.secondary} ${percentage}%, white ${percentage}%)`,
          WebkitBackgroundClip: "text",
          WebkitTextFillColor: "transparent",
          backgroundClip: "text",
        };
      }
      if (isPast) {
        return { color: brandColors.secondary };
      }
      return { color: "white" };
    }

    case "bounce": {
      // Scale animation on active word
      if (isActive) {
        const wordDuration = token.toMs - token.fromMs;
        const elapsed = absoluteTimeMs - token.fromMs;
        const progress = Math.min(1, elapsed / wordDuration);
        // Quick bounce up then settle
        const bounceScale =
          progress < 0.3
            ? interpolate(progress, [0, 0.3], [1, 1.3])
            : interpolate(progress, [0.3, 1], [1.3, 1.1]);
        return {
          color: brandColors.secondary,
          transform: `scale(${bounceScale})`,
        };
      }
      return {
        color: isPast ? "rgba(255,255,255,0.6)" : "white",
        transform: "scale(1)",
      };
    }

    default:
      return { color: "white" };
  }
}
