import React, { useMemo } from "react";
import {
  AbsoluteFill,
  Audio,
  Sequence,
  useCurrentFrame,
  useVideoConfig,
  spring,
  interpolate,
  Easing,
} from "remotion";
import {
  useWindowedAudioData,
  visualizeAudio,
} from "@remotion/media-utils";
import { createTikTokStyleCaptions } from "@remotion/captions";
import type { Caption } from "@remotion/captions";
import { GradientBackground } from "../components/GradientBackground";
import { BrandLogo } from "../components/BrandLogo";
import { FONT_HEADING, FONT_BODY } from "../utils/fonts";
import type { BrandColors } from "../utils/types";
import { DEFAULT_BRAND_COLORS } from "../utils/types";
import { fadeIn } from "../utils/animations";

export type PodcastClipProps = {
  audioUrl: string;
  captions: Caption[];
  speakerName: string;
  episodeTitle: string;
  brandColors: BrandColors;
  logoUrl?: string;
};

const SWITCH_CAPTIONS_EVERY_MS = 1500;
const NUM_BARS = 48;

/**
 * PodcastClip — Dark gradient background with audio waveform bars,
 * word-by-word highlighted captions, speaker name, and episode title.
 * Format: 1080x1080, 30fps.
 */
export const PodcastClip: React.FC<PodcastClipProps> = ({
  audioUrl,
  captions,
  speakerName,
  episodeTitle,
  brandColors = DEFAULT_BRAND_COLORS,
  logoUrl,
}) => {
  const frame = useCurrentFrame();
  const { fps, width, height } = useVideoConfig();

  // Audio data for waveform visualization
  const { audioData, dataOffsetInSeconds } = useWindowedAudioData({
    src: audioUrl,
    frame,
    fps,
    windowInSeconds: 30,
  });

  // Frequency data for bars
  const frequencies = useMemo(() => {
    if (!audioData) return new Array(NUM_BARS).fill(0);
    return visualizeAudio({
      fps,
      frame,
      audioData,
      numberOfSamples: 256,
      optimizeFor: "speed",
      dataOffsetInSeconds,
    }).slice(0, NUM_BARS);
  }, [audioData, fps, frame, dataOffsetInSeconds]);

  // Create caption pages
  const { pages } = useMemo(() => {
    return createTikTokStyleCaptions({
      captions,
      combineTokensWithinMilliseconds: SWITCH_CAPTIONS_EVERY_MS,
    });
  }, [captions]);

  // Header fade in
  const headerOpacity = fadeIn(frame, 0, fps);

  return (
    <AbsoluteFill>
      {/* Dark gradient background */}
      <GradientBackground colors={brandColors} direction="radial" dark />

      {/* Audio playback */}
      <Audio src={audioUrl} />

      {/* Episode title — top area */}
      <div
        style={{
          position: "absolute",
          top: 60,
          left: 60,
          right: 60,
          opacity: headerOpacity,
          textAlign: "center",
        }}
      >
        <div
          style={{
            fontFamily: FONT_BODY,
            fontSize: 28,
            color: brandColors.secondary,
            letterSpacing: 3,
            textTransform: "uppercase",
            marginBottom: 12,
          }}
        >
          PODCAST
        </div>
        <div
          style={{
            fontFamily: FONT_HEADING,
            fontSize: 42,
            fontWeight: 700,
            color: "white",
            lineHeight: 1.3,
          }}
        >
          {episodeTitle}
        </div>
      </div>

      {/* Audio waveform bars — center */}
      <div
        style={{
          position: "absolute",
          top: height * 0.3,
          left: 60,
          right: 60,
          height: height * 0.25,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          gap: 4,
        }}
      >
        {frequencies.map((value, i) => {
          const barHeight = Math.max(4, value * height * 0.22);
          const hue = interpolate(i, [0, NUM_BARS], [120, 45]);
          const barColor = `hsl(${hue}, 60%, 55%)`;
          return (
            <div
              key={i}
              style={{
                width: Math.floor((width - 120 - (NUM_BARS - 1) * 4) / NUM_BARS),
                height: barHeight,
                backgroundColor: barColor,
                borderRadius: 3,
                transition: "none",
              }}
            />
          );
        })}
      </div>

      {/* Speaker name — below waveform */}
      <div
        style={{
          position: "absolute",
          top: height * 0.58,
          left: 0,
          right: 0,
          textAlign: "center",
          opacity: headerOpacity,
        }}
      >
        <div
          style={{
            display: "inline-block",
            fontFamily: FONT_HEADING,
            fontSize: 32,
            fontWeight: 700,
            color: brandColors.primary,
            backgroundColor: "rgba(0,0,0,0.4)",
            padding: "8px 24px",
            borderRadius: 8,
          }}
        >
          {speakerName}
        </div>
      </div>

      {/* Caption pages — lower area */}
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
              <CaptionPageDisplay
                page={page}
                brandColors={brandColors}
                containerHeight={height}
              />
            </Sequence>
          );
        })}
      </AbsoluteFill>

      {/* Brand logo */}
      <BrandLogo
        logoUrl={logoUrl}
        colors={brandColors}
        size={50}
        position="bottom-right"
      />
    </AbsoluteFill>
  );
};

/** Internal caption page display with word highlighting */
const CaptionPageDisplay: React.FC<{
  page: { startMs: number; tokens: Array<{ text: string; fromMs: number; toMs: number }> };
  brandColors: BrandColors;
  containerHeight: number;
}> = ({ page, brandColors, containerHeight }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const currentTimeMs = (frame / fps) * 1000;
  const absoluteTimeMs = page.startMs + currentTimeMs;

  return (
    <div
      style={{
        position: "absolute",
        bottom: containerHeight * 0.12,
        left: 60,
        right: 60,
        textAlign: "center",
      }}
    >
      <div
        style={{
          fontFamily: FONT_HEADING,
          fontSize: 52,
          fontWeight: 700,
          lineHeight: 1.4,
          whiteSpace: "pre-wrap",
          textShadow: "0 2px 8px rgba(0,0,0,0.8)",
        }}
      >
        {page.tokens.map((token, i) => {
          const isActive =
            token.fromMs <= absoluteTimeMs && token.toMs > absoluteTimeMs;
          return (
            <span
              key={`${token.fromMs}-${i}`}
              style={{
                color: isActive ? brandColors.secondary : "white",
                textShadow: isActive
                  ? `0 0 20px ${brandColors.secondary}`
                  : "0 2px 8px rgba(0,0,0,0.8)",
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
