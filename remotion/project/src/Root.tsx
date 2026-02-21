import React from "react";
import { Composition, Folder } from "remotion";
import { PodcastClip } from "./compositions/PodcastClip";
import type { PodcastClipProps } from "./compositions/PodcastClip";
import { AnimatedCaptions } from "./compositions/AnimatedCaptions";
import type { AnimatedCaptionsProps } from "./compositions/AnimatedCaptions";
import { ProductShowcase } from "./compositions/ProductShowcase";
import type { ProductShowcaseProps } from "./compositions/ProductShowcase";
import { BrandIntro } from "./compositions/BrandIntro";
import type { BrandIntroProps } from "./compositions/BrandIntro";
import { DataChart } from "./compositions/DataChart";
import type { DataChartProps } from "./compositions/DataChart";
import { DEFAULT_BRAND_COLORS } from "./utils/types";

/**
 * GAIA MotionKit — Root composition registry.
 *
 * All compositions are parameterized with brand colors and accept
 * props via CLI --props JSON for scripted rendering.
 */
export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Folder name="Content">
        {/* PodcastClip: Square format for podcast audiograms */}
        <Composition<PodcastClipProps>
          id="PodcastClip"
          component={PodcastClip}
          width={1080}
          height={1080}
          fps={30}
          durationInFrames={30 * 30}
          defaultProps={{
            audioUrl: "",
            captions: [
              {
                text: " Hello",
                startMs: 0,
                endMs: 500,
                timestampMs: 0,
                confidence: 1,
              },
              {
                text: " world,",
                startMs: 500,
                endMs: 1000,
                timestampMs: 500,
                confidence: 1,
              },
              {
                text: " welcome",
                startMs: 1000,
                endMs: 1500,
                timestampMs: 1000,
                confidence: 1,
              },
              {
                text: " to",
                startMs: 1500,
                endMs: 1700,
                timestampMs: 1500,
                confidence: 1,
              },
              {
                text: " the",
                startMs: 1700,
                endMs: 1900,
                timestampMs: 1700,
                confidence: 1,
              },
              {
                text: " podcast.",
                startMs: 1900,
                endMs: 2500,
                timestampMs: 1900,
                confidence: 1,
              },
            ],
            speakerName: "Jenn",
            episodeTitle: "Plant-Powered Living",
            brandColors: DEFAULT_BRAND_COLORS,
          }}
        />

        {/* AnimatedCaptions: Vertical format for TikTok/Reels */}
        <Composition<AnimatedCaptionsProps>
          id="AnimatedCaptions"
          component={AnimatedCaptions}
          width={1080}
          height={1920}
          fps={30}
          durationInFrames={30 * 30}
          defaultProps={{
            videoUrl: "",
            captions: [
              {
                text: " Plant-based",
                startMs: 0,
                endMs: 800,
                timestampMs: 0,
                confidence: 1,
              },
              {
                text: " food",
                startMs: 800,
                endMs: 1200,
                timestampMs: 800,
                confidence: 1,
              },
              {
                text: " that",
                startMs: 1200,
                endMs: 1500,
                timestampMs: 1200,
                confidence: 1,
              },
              {
                text: " tastes",
                startMs: 1500,
                endMs: 2000,
                timestampMs: 1500,
                confidence: 1,
              },
              {
                text: " amazing.",
                startMs: 2000,
                endMs: 2800,
                timestampMs: 2000,
                confidence: 1,
              },
            ],
            style: "tiktok",
            fontSize: 72,
            position: "bottom",
            brandColors: DEFAULT_BRAND_COLORS,
          }}
        />
      </Folder>

      <Folder name="Marketing">
        {/* ProductShowcase: Vertical product spotlight */}
        <Composition<ProductShowcaseProps>
          id="ProductShowcase"
          component={ProductShowcase}
          width={1080}
          height={1920}
          fps={30}
          durationInFrames={15 * 30}
          defaultProps={{
            productImage: "",
            productName: "Rendang Paste",
            price: "RM15.90",
            features: [
              "100% Plant-Based",
              "Authentic Malaysian Recipe",
              "No Preservatives",
              "Ready in 30 Minutes",
            ],
            brandColors: DEFAULT_BRAND_COLORS,
            ctaText: "Shop Now",
          }}
        />

        {/* BrandIntro: Vertical brand animation */}
        <Composition<BrandIntroProps>
          id="BrandIntro"
          component={BrandIntro}
          width={1080}
          height={1920}
          fps={30}
          durationInFrames={5 * 30}
          defaultProps={{
            brandName: "GAIA Eats",
            tagline: "Plant-powered, Malaysian-hearted",
            brandColors: DEFAULT_BRAND_COLORS,
          }}
        />
      </Folder>

      <Folder name="Data">
        {/* DataChart: Landscape data visualization */}
        <Composition<DataChartProps>
          id="DataChart"
          component={DataChart}
          width={1920}
          height={1080}
          fps={30}
          durationInFrames={10 * 30}
          defaultProps={{
            data: [
              { label: "Jan", value: 120 },
              { label: "Feb", value: 180 },
              { label: "Mar", value: 250 },
              { label: "Apr", value: 310 },
              { label: "May", value: 420 },
              { label: "Jun", value: 380 },
            ],
            chartType: "bar",
            title: "Monthly Sales",
            subtitle: "Units sold per month",
            brandColors: DEFAULT_BRAND_COLORS,
            yAxisLabel: "Units",
          }}
        />
      </Folder>
    </>
  );
};
