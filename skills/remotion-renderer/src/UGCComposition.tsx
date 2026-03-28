import React from "react";
import {
  AbsoluteFill,
  Audio,
  Sequence,
  interpolate,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { z } from "zod";
import { VideoBlock } from "./components/VideoBlock";
import { ImageBlock } from "./components/ImageBlock";
import { TextOverlayLayer } from "./components/TextOverlay";
import { BrandWatermark } from "./components/BrandWatermark";
import { EndCard } from "./components/EndCard";
import { LogoSting } from "./components/LogoSting";
import { FoodCollageBlock } from "./components/FoodCollageBlock";
import { KineticTextBlock } from "./components/KineticTextBlock";
import { KineticOverlay } from "./components/KineticOverlay";
import type { KineticPhrase } from "./components/KineticOverlay";
import { PersistentBadge } from "./components/PersistentBadge";
import { SplitScreenBlock } from "./components/SplitScreenBlock";
import { BrandRevealBlock } from "./components/BrandRevealBlock";
import { FilmGrain } from "./components/FilmGrain";
import { MangaSpeedLines } from "./components/MangaSpeedLines";
import { LightLeak } from "./components/LightLeak";
import {
  TransitionSeries,
  linearTiming,
  springTiming,
} from "@remotion/transitions";
import { fade } from "@remotion/transitions/fade";
import { slide } from "@remotion/transitions/slide";
import { wipe } from "@remotion/transitions/wipe";
import { flip } from "@remotion/transitions/flip";

// Emphasis segment for text overlays
const emphasisSchema = z.object({
  text: z.string(),
  color: z.string().optional(),
  scale: z.number().optional(),
  kinetic: z.string().optional(),
});

// End card config for branded CTA
const endCardSchema = z.object({
  headline: z.string(),
  subHeadline: z.string().optional(),
  ctaText: z.string(),
  bgColor: z.string().optional(),
  productImages: z.array(z.string()).optional(),
});

// Light leak config
const lightLeakSchema = z.object({
  position: z.enum(["top-left", "top-right", "bottom-left", "bottom-right", "center"]).optional(),
  color: z.string().optional(),
  peakOpacity: z.number().optional(),
});

// SFX item — multiple SFX can be placed per block
const sfxItemSchema = z.object({
  file: z.string(),
  volume: z.number().optional(),
  delay_s: z.number().optional(),
  category: z.string().optional(), // whoosh, pop_ding, chime, page_flip, variety
});

// Zod schema for type-safe props (used by Remotion's GUI + CLI)
export const ugcSchema = z.object({
  variant_id: z.string().default("variant_a"),
  fps: z.number().default(30),
  blocks: z.array(
    z.object({
      id: z.string(),
      type: z.string(),
      file: z.string(),
      duration_s: z.number(),
      start_s: z.number(),
      text_overlay: z
        .object({
          text: z.string(),
          headline: z.string().nullable().optional(),
          style: z.enum(["bold", "normal", "stat_card", "full_emphasis"]),
          position: z.enum(["lower_third", "center", "top"]),
          emphasis: z.array(emphasisSchema).optional(),
          color: z.string().optional(),
          outline: z.boolean().optional(),
          char_timestamps: z.array(z.number()).optional(),
          emoji: z.array(z.string()).nullable().optional(),
          instant_reveal: z.boolean().optional(),
          text_delay_frames: z.number().optional(),
          segments: z
            .array(
              z.object({
                text: z.string(),
                start_s: z.number(),
                end_s: z.number(),
                emphasis: z.array(emphasisSchema).nullable().optional(),
              }),
            )
            .optional(),
        })
        .nullable(),
      end_card: endCardSchema.nullable().optional(),
      ken_burns: z.enum(["none", "slow_zoom_in", "slow_zoom_out", "drift_right", "drift_left"]).optional(),
      transition: z.enum([
        "none", "fade", "slide_up", "slide_left",
        "push_close", "zoom_out", "page_flip", "blur_zoom", "cross_dissolve", "wipe",
      ]).optional(),
      color_grade: z.string().optional(), // Ignored by Remotion — grading via FFmpeg pre-assembly
      light_leak: lightLeakSchema.nullable().optional(),
      playback_rate: z.number().optional(),
      // Energy level for dopamine curve pacing (drives visual intensity decisions)
      energy_level: z.enum(["high", "medium", "low", "peak"]).optional(),
      // Zoom punch on block entry (spring overshoot on first frames)
      zoom_punch: z.boolean().optional(),
      // Camera shake on emphasis/impact moments
      camera_shake: z.boolean().optional(),
      camera_shake_intensity: z.number().optional(), // 1-5px, default 2
      clip_duration_frames: z.number().optional(), // Source clip duration for looping short clips
      // Multi-SFX: array of sound effects per block (whoosh, accent, etc.)
      sfx: z.array(sfxItemSchema).optional(),
      // Legacy single SFX (backwards compat) — prefer sfx array
      no_watermark: z.boolean().optional(),
      muted: z.boolean().optional(),
      sfx_single: z.object({
        file: z.string(),
        volume: z.number().optional(),
        delay_s: z.number().optional(),
      }).nullable().optional(),
      // Animation block fields
      collage_images: z.array(z.string()).optional(),
      collage_layout: z.enum(["grid_2x2", "grid_3x2", "masonry", "diagonal"]).optional(),
      collage_animation: z.enum(["stagger_pop", "slide_in", "scale_reveal"]).optional(),
      kinetic_lines: z.array(z.object({
        text: z.string(),
        color: z.string().optional(),
        fontSize: z.number().optional(),
        bold: z.boolean().optional(),
      })).optional(),
      kinetic_animation: z.enum(["word_pop", "line_slide", "typewriter", "scale_bounce"]).optional(),
      kinetic_bg_color: z.string().optional(),
      kinetic_text_align: z.enum(["center", "left"]).optional(),
      kinetic_accent_color: z.string().optional(),
      split_top_media: z.string().optional(),
      split_bottom_media: z.string().optional(),
      split_top_label: z.string().optional(),
      split_bottom_label: z.string().optional(),
      split_direction: z.enum(["horizontal", "vertical"]).optional(),
      split_animate_reveal: z.boolean().optional(),
      split_label_color: z.string().optional(),
      brand_logo: z.string().optional(),
      brand_product_images: z.array(z.string()).optional(),
      brand_tagline: z.string().optional(),
      brand_bg_color: z.string().optional(),
      brand_reveal_style: z.enum(["zoom_burst", "cascade_in", "orbit"]).optional(),
    })
  ).default([]),
  voiceover: z.string().nullable().default(null),
  voiceover_volume: z.number().default(1.0),
  voiceover_start_s: z.number().default(0), // Delay voiceover start (e.g. compiled_montage D+Act)
  bgm: z.string().nullable().default(null),
  bgm_volume: z.number().default(0.2),
  bgm_fade_out_s: z.number().default(2.0), // Fade-out duration at end
  total_duration_s: z.number().default(45),
  width: z.number().default(1080),
  height: z.number().default(1920),
  watermark: z.object({
    logo: z.string().optional(),
    text: z.string().optional(),
    color: z.string().optional(),
    opacity: z.number().optional(),
  }).nullable().default(null),
  enable_transitions: z.boolean().default(true), // Default ON now
  film_grain: z.object({
    enabled: z.boolean().default(false),
    intensity: z.number().default(0.04),
  }).optional(),
  // BGM ducking: auto-lower BGM when voiceover is active
  bgm_ducking: z.object({
    enabled: z.boolean().default(true),
    ducked_volume: z.number().default(0.14),   // Volume under VO (default 14%)
    full_volume: z.number().default(0.32),     // Volume during breathers/no-VO (default 32%)
    // Per-block VO presence map: [{start_s, end_s, has_vo}]
    vo_regions: z.array(z.object({
      start_s: z.number(),
      end_s: z.number(),
      has_vo: z.boolean(),
    })).optional(),
  }).optional(),
  // Progress bar: thin gradient line showing video progress (retention hook)
  progress_bar: z.object({
    enabled: z.boolean().default(false),
    color: z.string().default("#F7AB9F"),     // Brand color
    height: z.number().default(3),            // Pixels
    position: z.enum(["top", "bottom"]).default("top"),
    opacity: z.number().default(0.6),
  }).optional(),
  // Legacy global transition SFX (kept for backwards compat)
  sfx_transition: z.string().nullable().optional(),
  sfx_volume: z.number().optional(),
  bgm_end_s: z.number().optional(),
  // Kinetic overlay v3: phrase-by-phrase kinetic typography (brand montage style)
  kinetic_overlay: z.object({
    phrases: z.array(z.object({
      words: z.array(z.string()),
      start_s: z.number(),
      end_s: z.number(),
      colors: z.array(z.string()).optional(),
      fontSizes: z.array(z.number()).optional(),
      fontWeights: z.array(z.number()).optional(),
      yOffsets: z.array(z.number()).optional(),
      rotations: z.array(z.number()).optional(),
      letterSpacings: z.array(z.number()).optional(),
      align: z.enum(["right", "left", "center"]).optional(),
      vPosition: z.enum(["upper_third", "center", "lower_third"]).optional(),
      animationMode: z.enum(["slam", "blur_reveal", "slide_up", "slide_down", "elastic", "typewriter", "fade_scale", "drop"]).optional(),
      exitMode: z.enum(["fade", "slide_out", "scale_down", "blur_out", "cut"]).optional(),
      staggerFrames: z.number().optional(),
      holdBeforeExit: z.number().optional(),
    })),
    color: z.string().optional(),
    fontSize: z.number().optional(),
    dimVideo: z.boolean().optional(),
    dimOpacity: z.number().optional(),
  }).nullable().optional(),
  // Persistent badge: text-only brand + CTA in bottom-right corner
  persistent_badge: z.object({
    brandName: z.string().optional(),
    ctaText: z.string().optional(),
    color: z.string().optional(),
    opacity: z.number().optional(),
    hideAfterS: z.number().optional(),
  }).nullable().optional(),
  // Manga speed lines: radial impact/concentration lines overlay (anime-style)
  manga_speed_lines: z.array(z.object({
    start_s: z.number(),
    duration_s: z.number(),
    intensity: z.number().optional(),
    color: z.string().optional(),
    opacity: z.number().optional(),
    centerX: z.number().optional(),
    centerY: z.number().optional(),
    motionBlur: z.boolean().optional(),
  })).nullable().optional(),
  // Global text track: VO-synced text segments independent of block boundaries
  global_text_track: z.object({
    segments: z.array(z.object({
      text: z.string(),
      start_s: z.number(),
      end_s: z.number(),
      emphasis: z.array(emphasisSchema).nullable().optional(),
      headline: z.string().nullable().optional(),
      emoji: z.array(z.string()).nullable().optional(),
      style: z.enum(["bold", "normal", "stat_card", "full_emphasis"]).default("bold"),
      instant_reveal: z.boolean().optional(),
      block_index: z.number().optional(),
    })),
    preset: z.string().optional(),
  }).nullable().optional(),
  text_style_preset: z.enum([
    // Mirra presets (primary — used by pipeline)
    "cn_black_outline",
    "cn_polished",
    "en_black_outline",
    "en_polished",
    // Legacy aliases (still accepted for backwards compat)
    "jianying_outline",
    "jianying_polished",
    "jianying_english",
    "outline_soft",
    "serif_premium",
    "bold_hook",
    "banner_safe",
    "minimal_clean",
  ]).default("cn_black_outline"),
});

export type UGCCompositionProps = z.infer<typeof ugcSchema>;

const IMAGE_TYPES = ["product_image", "text_card", "promo_visual", "customer_screenshot", "menu_card"];
const NO_WATERMARK_TYPES = ["end_card", "logo_sting"];

// Transition duration in frames: 0.47s standard (14 frames at 30fps)
const TRANSITION_FRAMES_STANDARD = 14;
const TRANSITION_FRAMES_FAST = 2; // cross_dissolve: 0.07s jump-cut feel

/**
 * Render a single block's content (video/image + text overlay + light leak).
 */
const BlockContent: React.FC<{
  block: UGCCompositionProps["blocks"][0];
  durationFrames: number;
  fps: number;
  textStylePreset?: UGCCompositionProps["text_style_preset"];
  nextTransitionFrames?: number;
}> = ({ block, durationFrames, fps, textStylePreset, nextTransitionFrames = 0 }) => {
  const frame = useCurrentFrame();
  const isImage = IMAGE_TYPES.includes(block.type);

  if (block.type === "end_card" && block.end_card) {
    return (
      <EndCard
        headline={block.end_card.headline}
        subHeadline={block.end_card.subHeadline}
        ctaText={block.end_card.ctaText}
        bgColor={block.end_card.bgColor}
        productImages={block.end_card.productImages}
        durationInFrames={durationFrames}
      />
    );
  }

  if (block.type === "logo_sting") {
    return <LogoSting durationInFrames={durationFrames} />;
  }

  if (block.type === "food_collage" && block.collage_images) {
    return (
      <FoodCollageBlock
        images={block.collage_images}
        layout={block.collage_layout as any}
        durationInFrames={durationFrames}
        brandColor={block.kinetic_accent_color}
        animationStyle={block.collage_animation as any}
      />
    );
  }

  if (block.type === "kinetic_text" && block.kinetic_lines) {
    return (
      <KineticTextBlock
        lines={block.kinetic_lines}
        bgColor={block.kinetic_bg_color}
        animationStyle={block.kinetic_animation as any}
        durationInFrames={durationFrames}
        textAlign={block.kinetic_text_align as any}
        accentColor={block.kinetic_accent_color}
      />
    );
  }

  if (block.type === "split_screen" && block.split_top_media && block.split_bottom_media) {
    return (
      <SplitScreenBlock
        topMedia={block.split_top_media}
        bottomMedia={block.split_bottom_media}
        topLabel={block.split_top_label}
        bottomLabel={block.split_bottom_label}
        splitDirection={block.split_direction as any}
        durationInFrames={durationFrames}
        animateReveal={block.split_animate_reveal}
        labelColor={block.split_label_color}
      />
    );
  }

  if (block.type === "brand_reveal" && block.brand_logo) {
    return (
      <BrandRevealBlock
        logo={block.brand_logo}
        productImages={block.brand_product_images}
        tagline={block.brand_tagline}
        bgColor={block.brand_bg_color}
        durationInFrames={durationFrames}
        revealStyle={block.brand_reveal_style as any}
      />
    );
  }

  return (
    <AbsoluteFill>
      {isImage ? (
        <ImageBlock src={block.file} durationInFrames={durationFrames} />
      ) : (
        <VideoBlock
          src={block.file}
          kenBurns={(block.ken_burns as any) || "none"}
          colorGrade={(block.color_grade as any) || "none"}
          muted={block.muted !== false}
          playbackRate={block.playback_rate || 1.0}
          zoomPunch={block.zoom_punch}
          cameraShake={block.camera_shake}
          cameraShakeIntensity={block.camera_shake_intensity}
          clipDurationFrames={block.clip_duration_frames}
        />
      )}

      {block.light_leak && (
        <LightLeak
          position={block.light_leak.position as any}
          color={block.light_leak.color}
          peakOpacity={block.light_leak.peakOpacity}
          durationInFrames={durationFrames}
        />
      )}

      {block.text_overlay && (() => {
        // Fade out text during transition overlap to prevent double-caption artifact.
        // During TransitionSeries transitions, both blocks render simultaneously.
        // Without this, viewers see two sets of captions stacked during the overlap.
        const textOpacity = nextTransitionFrames > 0
          ? interpolate(
              frame,
              [durationFrames - nextTransitionFrames, durationFrames],
              [1, 0],
              { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
            )
          : 1;
        return (
          <div style={{ opacity: textOpacity }}>
            <TextOverlayLayer
              text={block.text_overlay.text}
              headline={block.text_overlay.headline ?? undefined}
              style={block.text_overlay.style}
              position={block.text_overlay.position}
              durationInFrames={durationFrames}
              emphasis={block.text_overlay.emphasis}
              color={block.text_overlay.color}
              outline={block.text_overlay.outline}
              charTimestamps={block.text_overlay.char_timestamps}
              blockStartS={0}  /* char_timestamps are already block-relative (base subtracted in run_brief.py) */
              emoji={block.text_overlay.emoji ?? undefined}
              preset={textStylePreset}
              instantReveal={block.text_overlay.instant_reveal}
              textDelayFrames={block.text_overlay.text_delay_frames}
              segments={block.text_overlay.segments}
            />
          </div>
        );
      })()}
    </AbsoluteFill>
  );
};

const StandardLayout: React.FC<{
  blocks: UGCCompositionProps["blocks"];
  fps: number;
  textStylePreset?: UGCCompositionProps["text_style_preset"];
}> = ({ blocks, fps, textStylePreset }) => {
  return (
    <>
      {blocks.map((block) => {
        const startFrame = Math.round(block.start_s * fps);
        const durationFrames = Math.max(1, Math.round(block.duration_s * fps));
        return (
          <Sequence key={block.id} from={startFrame} durationInFrames={durationFrames}>
            <BlockContent block={block} durationFrames={durationFrames} fps={fps} textStylePreset={textStylePreset} />
          </Sequence>
        );
      })}
    </>
  );
};

/**
 * Get transition frames for a given type.
 */
function getTransitionFrames(type: string): number {
  return type === "cross_dissolve" ? TRANSITION_FRAMES_FAST : TRANSITION_FRAMES_STANDARD;
}

const TransitionLayout: React.FC<{
  blocks: UGCCompositionProps["blocks"];
  fps: number;
  textStylePreset?: UGCCompositionProps["text_style_preset"];
}> = ({ blocks, fps, textStylePreset }) => {
  return (
    <TransitionSeries>
      {blocks.map((block, index) => {
        const durationFrames = Math.max(1, Math.round(block.duration_s * fps));
        const transitionType = block.transition || "none";
        const tFrames = getTransitionFrames(transitionType);

        const getTransition = (): { presentation: any; timing: any } | null => {
          if (index === 0 || transitionType === "none") return null;
          switch (transitionType) {
            case "fade":
              return {
                presentation: fade(),
                timing: linearTiming({ durationInFrames: tFrames }),
              };
            case "slide_up":
              return {
                presentation: slide({ direction: "from-bottom" }),
                timing: springTiming({
                  config: { damping: 200 },
                  durationInFrames: tFrames,
                }),
              };
            case "slide_left":
              return {
                presentation: slide({ direction: "from-right" }),
                timing: linearTiming({ durationInFrames: tFrames }),
              };
            case "push_close":
              // 推近: slide from bottom with spring (simulates zoom push)
              return {
                presentation: slide({ direction: "from-bottom" }),
                timing: springTiming({
                  config: { damping: 15, stiffness: 120, mass: 0.8 },
                  durationInFrames: tFrames,
                }),
              };
            case "zoom_out":
              // 拉远: fade with longer duration for pull-back feel
              return {
                presentation: fade(),
                timing: linearTiming({ durationInFrames: tFrames }),
              };
            case "page_flip":
              // 翻页: flip presentation
              return {
                presentation: flip(),
                timing: springTiming({
                  config: { damping: 200 },
                  durationInFrames: tFrames,
                }),
              };
            case "blur_zoom":
              // 模糊放大: fade (CSS blur handled by VideoBlock if needed)
              return {
                presentation: fade(),
                timing: linearTiming({ durationInFrames: tFrames }),
              };
            case "cross_dissolve":
              // 叠化: very fast fade for jump-cut feel (0.07s)
              return {
                presentation: fade(),
                timing: linearTiming({ durationInFrames: TRANSITION_FRAMES_FAST }),
              };
            case "wipe":
              return {
                presentation: wipe(),
                timing: linearTiming({ durationInFrames: tFrames }),
              };
            default:
              return null;
          }
        };

        const transition = getTransition();

        // Look ahead: if the NEXT block has a transition, this block's text
        // must fade out during the overlap to prevent double captions.
        const nextBlock = index < blocks.length - 1 ? blocks[index + 1] : null;
        const nextTransType = nextBlock?.transition || "none";
        const nextTFrames = nextTransType !== "none" ? getTransitionFrames(nextTransType) : 0;

        return (
          <React.Fragment key={block.id}>
            {transition && (
              <TransitionSeries.Transition
                presentation={transition.presentation}
                timing={transition.timing}
              />
            )}
            <TransitionSeries.Sequence durationInFrames={durationFrames}>
              <BlockContent block={block} durationFrames={durationFrames} fps={fps} textStylePreset={textStylePreset} nextTransitionFrames={nextTFrames} />
            </TransitionSeries.Sequence>
          </React.Fragment>
        );
      })}
    </TransitionSeries>
  );
};

/**
 * BGM with ducking + fade-out.
 * Ducking: BGM dips to 12% under voiceover, rises to 45% during breathers.
 * Smooth 6-frame (0.2s) ramp between ducked/full volume.
 * Fade-out: gradual volume drop in final N seconds.
 */
const BgmTrack: React.FC<{
  src: string;
  volume: number;
  fadeOutS: number;
  endS?: number;
  fps: number;
  totalFrames: number;
  ducking?: UGCCompositionProps["bgm_ducking"];
}> = ({ src, volume, fadeOutS, endS, fps, totalFrames, ducking }) => {
  const bgmEndFrame = endS ? Math.round(endS * fps) : totalFrames;
  const fadeOutFrames = Math.round(fadeOutS * fps);
  const fadeStart = bgmEndFrame - fadeOutFrames;

  // Pre-compute VO region frames for ducking
  const voRegionFrames = ducking?.vo_regions?.map(r => ({
    start: Math.round(r.start_s * fps),
    end: Math.round(r.end_s * fps),
    has_vo: r.has_vo,
  })) || [];

  const rampFrames = 15; // 0.5s smooth transition between ducked/full (AUD-4)

  const volumeCallback = (f: number) => {
    // Fade-out at end
    if (f >= bgmEndFrame) return 0;
    let baseVolume = volume;

    if (f >= fadeStart) {
      baseVolume = volume * interpolate(f, [fadeStart, bgmEndFrame], [1, 0], {
        extrapolateRight: "clamp",
        extrapolateLeft: "clamp",
      });
    }

    // Apply ducking if enabled
    if (ducking?.enabled && voRegionFrames.length > 0) {
      const duckedVol = ducking.ducked_volume ?? 0.14;
      const fullVol = ducking.full_volume ?? 0.32;

      // Find which region this frame is in
      let targetVol = fullVol; // Default: no VO = full volume
      for (const region of voRegionFrames) {
        if (f >= region.start && f < region.end) {
          targetVol = region.has_vo ? duckedVol : fullVol;
          // Smooth ramp at region boundaries
          if (f < region.start + rampFrames) {
            const prevVol = region.has_vo ? fullVol : duckedVol;
            targetVol = interpolate(f, [region.start, region.start + rampFrames], [prevVol, targetVol], {
              extrapolateLeft: "clamp", extrapolateRight: "clamp",
            });
          }
          if (f > region.end - rampFrames) {
            const nextVol = region.has_vo ? fullVol : duckedVol;
            targetVol = interpolate(f, [region.end - rampFrames, region.end], [targetVol, nextVol], {
              extrapolateLeft: "clamp", extrapolateRight: "clamp",
            });
          }
          break;
        }
      }
      return baseVolume * (targetVol / volume); // Scale relative to base
    }

    return baseVolume;
  };

  if (endS) {
    return (
      <Sequence from={0} durationInFrames={bgmEndFrame}>
        <Audio src={src} volume={volumeCallback} loop />
      </Sequence>
    );
  }
  return <Audio src={src} volume={volumeCallback} loop />;
};

/**
 * ProgressBar — thin gradient line showing video progress.
 * Creates subconscious commitment: viewers who see progress are more likely to finish.
 */
// ── Global Text Track: VO-synced text independent of block boundaries ──────
// Text segments use absolute timestamps from the VO timeline.
// Renders as a single layer spanning the entire composition.
interface GlobalTextSegment {
  text: string;
  start_s: number;
  end_s: number;
  emphasis?: Array<{ text: string; color?: string; scale?: number; kinetic?: string }> | null;
  headline?: string | null;
  emoji?: string[] | null;
  style: "bold" | "normal" | "stat_card" | "full_emphasis";
  instant_reveal?: boolean;
  block_index?: number;
}

const GlobalTextTrack: React.FC<{
  segments: GlobalTextSegment[];
  preset?: string;
  fps: number;
  textDelayFrames?: number;
}> = ({ segments, preset, fps, textDelayFrames = 0 }) => {
  // Find headline from segments (set on first block's segments only).
  // Render it as its OWN 4s Sequence so it's not clamped to a caption
  // segment's short duration (1-2s). Caption segments render without headline.
  const headlineSeg = segments.find((s) => s.headline);
  const headlineText = headlineSeg?.headline ?? undefined;
  const headlineStartFrame = headlineSeg
    ? Math.round(headlineSeg.start_s * fps)
    : 0;
  const headlineDurFrames = Math.round(4.0 * fps); // always 4s

  return (
    <AbsoluteFill>
      {/* Headline layer — independent 4s Sequence, not bound to caption segment */}
      {headlineText && (
        <Sequence
          key="gtt-headline"
          from={headlineStartFrame}
          durationInFrames={headlineDurFrames}
        >
          <TextOverlayLayer
            text=""
            headline={headlineText}
            style="bold"
            position="lower_third"
            durationInFrames={headlineDurFrames}
            preset={preset as any}
            instantReveal={true}
          />
        </Sequence>
      )}

      {/* Caption segments — each gets its own Sequence for correct fade timing */}
      {segments.map((seg, i) => {
        const startFrame = Math.round(seg.start_s * fps);
        const durFrames = Math.max(1, Math.round((seg.end_s - seg.start_s) * fps));

        return (
          <Sequence key={`gtt-${i}`} from={startFrame} durationInFrames={durFrames}>
            <TextOverlayLayer
              text={seg.text}
              headline={undefined}
              style={seg.style}
              position="lower_third"
              durationInFrames={durFrames}
              emphasis={seg.emphasis ?? undefined}
              emoji={seg.emoji ?? undefined}
              preset={preset as any}
              instantReveal={seg.instant_reveal ?? true}
            />
          </Sequence>
        );
      })}
    </AbsoluteFill>
  );
};

const ProgressBar: React.FC<{
  color: string;
  height: number;
  position: "top" | "bottom";
  opacity: number;
  totalFrames: number;
}> = ({ color, height, position, opacity, totalFrames }) => {
  const frame = useCurrentFrame();
  const progress = interpolate(frame, [0, totalFrames], [0, 100], { extrapolateRight: "clamp" });

  return (
    <div
      style={{
        position: "absolute",
        [position]: 0,
        left: 0,
        width: `${progress}%`,
        height,
        background: `linear-gradient(90deg, ${color}00, ${color})`,
        opacity,
        zIndex: 100,
      }}
    />
  );
};

export const UGCComposition: React.FC<UGCCompositionProps> = ({
  blocks,
  voiceover,
  voiceover_volume,
  voiceover_start_s = 0,
  bgm,
  bgm_volume,
  bgm_fade_out_s = 2.0,
  fps,
  watermark,
  enable_transitions = true,
  film_grain,
  sfx_transition,
  sfx_volume = 0.3,
  bgm_end_s,
  text_style_preset,
  bgm_ducking,
  progress_bar,
  kinetic_overlay,
  persistent_badge,
  manga_speed_lines,
  global_text_track,
}) => {
  // Calculate transition points for legacy SFX playback
  const transitionPointFrames: number[] = [];
  if (sfx_transition) {
    for (const block of blocks) {
      if (block.transition && block.transition !== "none") {
        transitionPointFrames.push(Math.round(block.start_s * fps));
      }
    }
  }

  // Calculate actual block positions accounting for TransitionSeries overlap.
  // Each transition compresses the timeline by its overlap duration.
  const adjustedPositions: Array<{ from: number; to: number }> = [];
  {
    let cursor = 0;
    for (let i = 0; i < blocks.length; i++) {
      const block = blocks[i];
      const durationFrames = Math.max(1, Math.round(block.duration_s * fps));
      if (enable_transitions && i > 0) {
        const tType = block.transition || "none";
        if (tType !== "none") {
          const tFrames = getTransitionFrames(tType);
          cursor -= tFrames; // transition overlap shifts block earlier
        }
      }
      adjustedPositions.push({ from: cursor, to: cursor + durationFrames });
      cursor += durationFrames;
    }
  }

  const noWatermarkRanges = blocks
    .map((b, i) => ({ block: b, pos: adjustedPositions[i] }))
    .filter(({ block: b }) => NO_WATERMARK_TYPES.includes(b.type) || b.no_watermark)
    .map(({ pos }) => ({
      from: Math.max(0, pos.from),
      to: pos.to,
    }));

  const totalFrames = adjustedPositions.length > 0
    ? adjustedPositions[adjustedPositions.length - 1].to
    : Math.max(1, ...blocks.map((b) => Math.round((b.start_s + b.duration_s) * fps)));

  const watermarkSegments: Array<{ from: number; duration: number }> = [];
  if (watermark && blocks.length > 0) {
    let cursor = 0;
    for (const range of noWatermarkRanges) {
      if (range.from > cursor) {
        watermarkSegments.push({ from: cursor, duration: range.from - cursor });
      }
      cursor = range.to;
    }
    if (cursor < totalFrames) {
      watermarkSegments.push({ from: cursor, duration: totalFrames - cursor });
    }
  }

  // Collect all SFX from blocks (new multi-SFX system)
  const allBlockSfx: Array<{ startFrame: number; file: string; volume: number; key: string }> = [];
  blocks.forEach((block, i) => {
    // New multi-SFX array
    if (block.sfx && Array.isArray(block.sfx)) {
      block.sfx.forEach((sfxItem, j) => {
        const delayFrames = Math.round((sfxItem.delay_s || 0) * fps);
        const startFrame = Math.round(block.start_s * fps) + delayFrames;
        allBlockSfx.push({
          startFrame,
          file: sfxItem.file,
          volume: sfxItem.volume || 0.4,
          key: `sfx-${i}-${j}`,
        });
      });
    }
    // Legacy single SFX
    if (block.sfx_single) {
      const delayFrames = Math.round((block.sfx_single.delay_s || 0) * fps);
      const startFrame = Math.round(block.start_s * fps) + delayFrames;
      allBlockSfx.push({
        startFrame,
        file: block.sfx_single.file,
        volume: block.sfx_single.volume || 0.4,
        key: `sfx-legacy-${i}`,
      });
    }
  });

  return (
    <AbsoluteFill style={{ backgroundColor: "#000000" }}>
      {/* Track 1: Video/Image blocks with transitions */}
      {enable_transitions ? (
        <TransitionLayout blocks={blocks} fps={fps} textStylePreset={text_style_preset} />
      ) : (
        <StandardLayout blocks={blocks} fps={fps} textStylePreset={text_style_preset} />
      )}

      {/* Track 2: Film grain overlay */}
      {film_grain?.enabled && (
        <FilmGrain intensity={film_grain.intensity} />
      )}

      {/* Track 2.3: Manga speed lines overlay (impact/transition effect) */}
      {manga_speed_lines && manga_speed_lines.map((msl, i) => (
        <MangaSpeedLines
          key={`msl-${i}`}
          startFrame={Math.round(msl.start_s * fps)}
          durationFrames={Math.round(msl.duration_s * fps)}
          intensity={msl.intensity}
          color={msl.color}
          opacity={msl.opacity}
          centerX={msl.centerX}
          centerY={msl.centerY}
          motionBlur={msl.motionBlur}
        />
      ))}

      {/* Track 2.5: Progress bar (retention hook) */}
      {progress_bar?.enabled && (
        <ProgressBar
          color={progress_bar.color || "#F7AB9F"}
          height={progress_bar.height || 3}
          position={progress_bar.position || "top"}
          opacity={progress_bar.opacity || 0.6}
          totalFrames={totalFrames}
        />
      )}

      {/* Track 2.7: Kinetic overlay (phrase-by-phrase text over video) */}
      {kinetic_overlay && kinetic_overlay.phrases.length > 0 && (
        <KineticOverlay
          phrases={kinetic_overlay.phrases as KineticPhrase[]}
          color={kinetic_overlay.color}
          fontSize={kinetic_overlay.fontSize}
          dimVideo={kinetic_overlay.dimVideo}
          dimOpacity={kinetic_overlay.dimOpacity}
        />
      )}

      {/* Track 2.8: Persistent badge (text-only brand + CTA) */}
      {persistent_badge && (
        <PersistentBadge
          brandName={persistent_badge.brandName}
          ctaText={persistent_badge.ctaText}
          color={persistent_badge.color}
          opacity={persistent_badge.opacity}
          hideAfterS={persistent_badge.hideAfterS}
        />
      )}

      {/* Track 3: Brand watermark */}
      {watermark && watermarkSegments.map((seg, i) => (
        <Sequence key={`wm-${i}`} from={seg.from} durationInFrames={seg.duration}>
          <BrandWatermark
            logo={watermark.logo}
            text={watermark.text}
            color={watermark.color}
            opacity={watermark.opacity}
          />
        </Sequence>
      ))}

      {/* Track 8: Global text track (VO-synced, independent of block boundaries) */}
      {/* Each segment renders as its own <Sequence> inside GlobalTextTrack */}
      {global_text_track && global_text_track.segments && global_text_track.segments.length > 0 && (
        <GlobalTextTrack
          segments={global_text_track.segments}
          preset={global_text_track.preset || text_style_preset}
          fps={fps}
        />
      )}

      {/* Track 4: Voiceover (with optional delayed start for compiled_montage) */}
      {voiceover && voiceover_start_s > 0 ? (
        <Sequence from={Math.round(voiceover_start_s * fps)}>
          <Audio src={voiceover} volume={voiceover_volume} />
        </Sequence>
      ) : voiceover ? (
        <Audio src={voiceover} volume={voiceover_volume} startFrom={0} />
      ) : null}

      {/* Track 5: BGM with ducking + fade-out */}
      {bgm && (
        <BgmTrack
          src={bgm}
          volume={bgm_volume}
          fadeOutS={bgm_fade_out_s}
          endS={bgm_end_s}
          fps={fps}
          totalFrames={totalFrames}
          ducking={bgm_ducking}
        />
      )}

      {/* Track 6: Legacy global transition SFX (backwards compat) */}
      {sfx_transition && transitionPointFrames.map((frame, i) => (
        <Sequence key={`sfx-tr-${i}`} from={Math.max(0, frame - 3)} durationInFrames={30}>
          <Audio src={sfx_transition} volume={sfx_volume} />
        </Sequence>
      ))}

      {/* Track 7: All block SFX (multi-SFX system) */}
      {allBlockSfx.map((sfx) => (
        <Sequence key={sfx.key} from={Math.max(0, sfx.startFrame)} durationInFrames={90}>
          <Audio src={sfx.file} volume={sfx.volume} />
        </Sequence>
      ))}
    </AbsoluteFill>
  );
};
