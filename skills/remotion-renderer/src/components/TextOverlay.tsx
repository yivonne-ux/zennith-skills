import React from "react";
import {
  AbsoluteFill,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import {
  ensureBrandFonts,
  FONT_HEADING_CN,
  FONT_HEADING_EN,
  FONT_BODY_EN,
  FONT_SUBTITLE_CN,
} from "../fonts";

ensureBrandFonts();

const SALMON_DEEP = "#E68A7E";
const SALMON_GLOW = "rgba(230, 138, 126, 0.4)";

type TextStyle = "bold" | "normal" | "stat_card" | "full_emphasis";
type TextPosition = "lower_third" | "center" | "top";

export type TextStylePreset =
  | "cn_black_outline"
  | "cn_polished"
  | "en_black_outline"
  | "en_polished"
  // Legacy aliases (map to new presets)
  | "jianying_outline"
  | "jianying_polished"
  | "jianying_english"
  | "outline_soft"
  | "serif_premium"
  | "bold_hook"
  | "banner_safe"
  | "minimal_clean";

interface EmphasisSegment {
  text: string;
  color?: string;
  scale?: number;
  kinetic?: string;
}

interface CaptionSegment {
  text: string;
  start_s: number;
  end_s: number;
  emphasis?: (EmphasisSegment | string)[] | null;
}

interface TextOverlayProps {
  text: string;
  headline?: string;
  style: TextStyle;
  position: TextPosition;
  durationInFrames: number;
  emphasis?: (EmphasisSegment | string)[];
  color?: string;
  outline?: boolean;
  charTimestamps?: number[];
  blockStartS?: number;
  emoji?: string[];
  preset?: TextStylePreset;
  instantReveal?: boolean;
  textDelayFrames?: number;
  segments?: CaptionSegment[];
}

/**
 * Preset configuration — controls fonts, colors, sizes, shadows, backgrounds.
 * Each preset produces a visually distinct look for batch creative diversity.
 */
interface PresetConfig {
  headlineFont: string;
  headlineSize: number;
  headlineColor: string;
  headlineGlow: string;
  bodyFont: string;
  bodySize: number;
  bodyBoldSize: number;
  bodyColor: string;
  bodyWeight: number;
  bodyBoldWeight: number;
  emphasisColor: string;
  emphasisGlow: string;
  emphasisScale: number;
  /** Directional shadow on emphasis text (e.g. dark red offset shadow from Jianying) */
  emphasisShadow: string | null;
  textShadow: string;
  lineHeight: number;
  letterSpacing: string;
  /** Semi-transparent background strip behind text */
  bgStrip: string | null;
  bgStripPadding: string;
  bgStripRadius: number;
  /** Full emphasis (textStyle="full_emphasis") — preset-aware overrides */
  fullEmphasisColor: string;
  fullEmphasisBg: string | null;
  fullEmphasisStroke: string;
}

const TEXT_SHADOW_HEAVY = [
  "0 2px 4px rgba(0,0,0,0.9)",
  "0 0 8px rgba(0,0,0,0.7)",
  "-1px -1px 0 rgba(0,0,0,0.8)",
  "1px -1px 0 rgba(0,0,0,0.8)",
  "-1px 1px 0 rgba(0,0,0,0.8)",
  "1px 1px 0 rgba(0,0,0,0.8)",
].join(", ");

const TEXT_SHADOW_LIGHT = [
  "0 2px 6px rgba(0,0,0,0.6)",
  "0 0 4px rgba(0,0,0,0.4)",
].join(", ");

const TEXT_SHADOW_OUTLINE = [
  "-3px -3px 0 rgba(0,0,0,0.95)",
  "3px -3px 0 rgba(0,0,0,0.95)",
  "-3px 3px 0 rgba(0,0,0,0.95)",
  "3px 3px 0 rgba(0,0,0,0.95)",
  "0 -3px 0 rgba(0,0,0,0.95)",
  "0 3px 0 rgba(0,0,0,0.95)",
  "-3px 0 0 rgba(0,0,0,0.95)",
  "3px 0 0 rgba(0,0,0,0.95)",
  "0 0 6px rgba(0,0,0,0.5)",
].join(", ");

/**
 * Mirra text style presets — extracted from Jianying "Mirra text style" project.
 * 4 presets: 2 Chinese (cn_black_outline, cn_polished) + 2 English (en_black_outline, en_polished).
 * Config source: config/text_style_presets.json
 */
const MIRRA_PRESETS: Record<string, PresetConfig> = {
  /**
   * cn_black_outline — Chinese primary style.
   * FZZCHJW body, Source Han Serif CN headline. Black outline stroke.
   * Emphasis: salmon #f7ab9f at 1.27x. Full emphasis: salmon stroke + brown shadow.
   */
  cn_black_outline: {
    headlineFont: FONT_HEADING_CN,  // SourceHanSerifCN-Bold
    headlineSize: 92,     // Bigger hook headline — punchy impact
    headlineColor: "#ffffff",
    headlineGlow: "",
    bodyFont: FONT_SUBTITLE_CN,  // FZZCHJW
    bodySize: 56,         // Reference standard: 56px (Jianying 13pt at 1080p)
    bodyBoldSize: 70,     // 1.25x body = 70px
    bodyColor: "#ffffff",
    bodyWeight: 700,
    bodyBoldWeight: 900,
    emphasisColor: "#f7ab9f",   // Salmon — from Jianying letter_color
    emphasisGlow: "",
    emphasisScale: 1.25,        // 70/56 = 1.25x
    emphasisShadow: "0 6px 0 rgba(0,0,0,0.53)",  // Jianying shadow: distance 6.12, angle -90.8°
    textShadow: TEXT_SHADOW_OUTLINE,
    lineHeight: 1.3,
    letterSpacing: "0.05em",
    bgStrip: null,
    bgStripPadding: "0",
    bgStripRadius: 0,
    fullEmphasisColor: "#ffffff",
    fullEmphasisBg: null,
    fullEmphasisStroke: [
      "-3px -3px 0 rgba(232,138,126,0.95)", "3px -3px 0 rgba(232,138,126,0.95)",
      "-3px 3px 0 rgba(232,138,126,0.95)", "3px 3px 0 rgba(232,138,126,0.95)",
      "0 -3px 0 rgba(232,138,126,0.95)", "0 3px 0 rgba(232,138,126,0.95)",
      "-3px 0 0 rgba(232,138,126,0.95)", "3px 0 0 rgba(232,138,126,0.95)",
      "5.7px 5.7px 0 rgba(188,98,54,1.0)",
    ].join(", "),
  },

  /**
   * cn_polished — Chinese soft embossed style.
   * Warm peach body (#ffd9c6), soft brown stroke (#584c4c).
   * Emphasis: inverted (white keywords on peach body). Full emphasis: salmon pill background.
   */
  cn_polished: {
    headlineFont: FONT_HEADING_CN,
    headlineSize: 92,
    headlineColor: "#ffffff",
    headlineGlow: "",
    bodyFont: FONT_SUBTITLE_CN,
    bodySize: 56,               // Reference standard: 56px
    bodyBoldSize: 70,           // 1.25x body = 70px
    bodyColor: "#ffd9c6",       // Warm peach body text
    bodyWeight: 700,
    bodyBoldWeight: 900,
    emphasisColor: "#ffffff",   // White fill — visible against peach body with brown stroke
    emphasisGlow: "",
    emphasisScale: 1.25,
    emphasisShadow: "0 6px 0 rgba(0,0,0,0.53)",
    textShadow: [
      "-3px -3px 0 rgba(88,76,76,0.95)",  // Soft brown stroke (#584c4c)
      "3px -3px 0 rgba(88,76,76,0.95)",
      "-3px 3px 0 rgba(88,76,76,0.95)",
      "3px 3px 0 rgba(88,76,76,0.95)",
      "0 -3px 0 rgba(88,76,76,0.95)",
      "0 3px 0 rgba(88,76,76,0.95)",
      "-3px 0 0 rgba(88,76,76,0.95)",
      "3px 0 0 rgba(88,76,76,0.95)",
      "0 6px 4px rgba(0,0,0,0.53)",  // Soft shadow with smoothing
    ].join(", "),
    lineHeight: 1.3,
    letterSpacing: "0.05em",
    bgStrip: null,
    bgStripPadding: "0",
    bgStripRadius: 0,
    fullEmphasisColor: "#ffcdd2",
    fullEmphasisBg: "#584c4c",
    fullEmphasisStroke: "",
  },

  /**
   * en_black_outline — English primary style.
   * MabryPro-Bold body, AwesomeSerif headline (→ Georgia fallback).
   * Headline: salmon stroke (#fe8a80) + deeper salmon shadow.
   * Emphasis: salmon color, no scale jump. Full emphasis: salmon stroke + brown shadow.
   */
  en_black_outline: {
    headlineFont: FONT_HEADING_EN,  // Awesome Serif Bold (was Georgia fallback)
    headlineSize: 82,
    headlineColor: "#ffffff",
    headlineGlow: "",
    bodyFont: FONT_BODY_EN,    // MabryPro-Bold
    bodySize: 48,              // Increased from 40px — user feedback: too small at 40px
    bodyBoldSize: 48,          // Match body (EN uses color-only emphasis, no scale jump)
    bodyColor: "#ffffff",
    bodyWeight: 700,
    bodyBoldWeight: 700,
    emphasisColor: "#f7ab9f",  // Salmon — color change only
    emphasisGlow: "",
    emphasisScale: 1.0,        // No scale jump in EN (same size, color change only)
    emphasisShadow: null,
    textShadow: TEXT_SHADOW_OUTLINE,
    lineHeight: 1.4,           // Wide line-spacing (0.22) for EN readability
    letterSpacing: "0",
    bgStrip: null,
    bgStripPadding: "0",
    bgStripRadius: 0,
    fullEmphasisColor: "#ffffff",
    fullEmphasisBg: null,
    fullEmphasisStroke: [
      "-3px -3px 0 rgba(232,138,126,0.95)", "3px -3px 0 rgba(232,138,126,0.95)",
      "-3px 3px 0 rgba(232,138,126,0.95)", "3px 3px 0 rgba(232,138,126,0.95)",
      "0 -3px 0 rgba(232,138,126,0.95)", "0 3px 0 rgba(232,138,126,0.95)",
      "-3px 0 0 rgba(232,138,126,0.95)", "3px 0 0 rgba(232,138,126,0.95)",
      "5.7px 5.7px 0 rgba(188,98,54,1.0)",
    ].join(", "),
  },

  /**
   * en_polished — English soft embossed style.
   * White body, NO stroke, high shadow smoothing (soft glow/float).
   * Emphasis: inverted — dark brown fill (#584c4c) with WHITE stroke.
   */
  en_polished: {
    headlineFont: FONT_HEADING_EN,  // Awesome Serif Bold (was Georgia fallback)
    headlineSize: 82,
    headlineColor: "#ffffff",
    headlineGlow: "",
    bodyFont: FONT_BODY_EN,
    bodySize: 48,
    bodyBoldSize: 48,
    bodyColor: "#ffffff",
    bodyWeight: 700,
    bodyBoldWeight: 700,
    emphasisColor: "#584c4c",  // Dark brown — inverted emphasis
    emphasisGlow: "",
    emphasisScale: 1.0,
    emphasisShadow: [
      "-2px -2px 0 rgba(255,255,255,0.9)",  // White stroke around emphasis
      "2px -2px 0 rgba(255,255,255,0.9)",
      "-2px 2px 0 rgba(255,255,255,0.9)",
      "2px 2px 0 rgba(255,255,255,0.9)",
    ].join(", "),
    textShadow: [
      "0 7px 8px rgba(0,0,0,0.8)",  // High smoothing soft shadow (no stroke)
      "0 0 12px rgba(0,0,0,0.4)",
    ].join(", "),
    lineHeight: 1.4,
    letterSpacing: "0",
    bgStrip: null,
    bgStripPadding: "0",
    bgStripRadius: 0,
    // Full emphasis: pink text on dark brown background bar (Jianying reference)
    fullEmphasisColor: "#ffcdd2",
    fullEmphasisBg: "#584c4c",
    fullEmphasisStroke: "",
  },
};

// Legacy alias mapping — old jianying presets → new Mirra presets
const LEGACY_ALIAS: Record<string, string> = {
  jianying_outline: "cn_black_outline",
  jianying_polished: "cn_polished",
  jianying_english: "en_black_outline",
  outline_soft: "cn_black_outline",
  serif_premium: "cn_polished",
  bold_hook: "cn_black_outline",
  banner_safe: "cn_polished",
  minimal_clean: "en_polished",
};

function getPreset(preset?: TextStylePreset): PresetConfig {
  const key = preset || "cn_black_outline";
  return MIRRA_PRESETS[key] || MIRRA_PRESETS[LEGACY_ALIAS[key]] || MIRRA_PRESETS["cn_black_outline"];
}

/**
 * Caption position — ALL positions forced to lower_third (Jianying standard).
 * Jianying Y ≈ -0.29 to -0.33 = ~65-70% from top = paddingBottom 540-576px at 1920h.
 * CRITICAL: Captions must stay FIXED per video — no jumping between positions.
 */
const POSITION_OUTER: Record<TextPosition, React.CSSProperties> = {
  lower_third: {
    justifyContent: "flex-end",
    paddingBottom: 540,
  },
  // Force center and top to same position as lower_third — prevents caption jumping
  center: {
    justifyContent: "flex-end",
    paddingBottom: 540,
  },
  top: {
    justifyContent: "flex-end",
    paddingBottom: 540,
  },
};

/**
 * Headline text — spring pop entrance.
 */
const HeadlineText: React.FC<{
  text: string;
  durationInFrames: number;
  preset: PresetConfig;
}> = ({ text, durationInFrames, preset }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Headline shows for ~4s then fades out — enough time to read and absorb
  // the hook before first dialogue line takes over.
  const headlineHoldFrames = Math.round(4.0 * fps);
  const headlineEndFrame = Math.min(headlineHoldFrames, durationInFrames);

  const entrance = spring({
    frame,
    fps,
    config: { damping: 18, stiffness: 180, mass: 0.7 },
  });

  const scale = interpolate(entrance, [0, 1], [0.4, 1.0]);
  const opacity = interpolate(entrance, [0, 1], [0, 1]);

  const fadeOut = interpolate(
    frame,
    [headlineEndFrame - 8, headlineEndFrame],
    [1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
  );

  return (
    <div
      style={{
        fontFamily: preset.headlineFont,
        fontWeight: 700,
        fontSize: preset.headlineSize,
        color: preset.headlineColor,
        textAlign: "center",
        textShadow: preset.textShadow + preset.headlineGlow,
        transform: `scale(${scale})`,
        opacity: opacity * fadeOut,
        marginBottom: 12,
        letterSpacing: "0.06em",
        lineHeight: 1.2,
        maxWidth: "85%",
        padding: "0 40px",
        boxSizing: "border-box" as const,
      }}
    >
      {text}
    </div>
  );
};

/**
 * Emoji decoration — single emoji centered above text.
 */
const EmojiDeco: React.FC<{
  emojis: string[];
  durationInFrames: number;
}> = ({ emojis, durationInFrames }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  if (!emojis || emojis.length === 0) return null;

  // Render up to 2 emoji with staggered entrance
  const visibleEmojis = emojis.slice(0, 2);

  const fadeOut = interpolate(
    frame,
    [durationInFrames - 10, durationInFrames],
    [1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
  );

  // Single emoji: centered above text. Two emoji: flanking left/right.
  const positions: React.CSSProperties[] =
    visibleEmojis.length === 1
      ? [{ textAlign: "center" as const }]
      : [
          { position: "absolute" as const, left: "10%", top: 0 },
          { position: "absolute" as const, right: "10%", top: 0 },
        ];

  return (
    <div
      style={{
        position: "relative",
        width: "100%",
        pointerEvents: "none",
      }}
    >
      {visibleEmojis.map((emoji, idx) => {
        const staggerDelay = idx * 4; // 4 frames stagger
        const entrance = spring({
          frame: Math.max(0, frame - staggerDelay),
          fps,
          config: { damping: 14, stiffness: 160, mass: 0.6 },
        });
        const scale = interpolate(entrance, [0, 1], [0, 1.0]);
        const opacity = interpolate(entrance, [0, 1], [0, 1]);
        const floatY = Math.sin((frame + idx * 10) / 18) * 4;

        return (
          <div
            key={idx}
            style={{
              fontSize: 65,
              transform: `scale(${scale}) translateY(${floatY}px)`,
              opacity: opacity * fadeOut,
              filter: "drop-shadow(0 2px 6px rgba(0,0,0,0.5))",
              ...positions[idx],
            }}
          >
            {emoji}
          </div>
        );
      })}
    </div>
  );
};

/**
 * Detect if text is primarily Chinese (CJK characters).
 */
function isChinese(text: string): boolean {
  const cjk = text.replace(/[^\u4e00-\u9fff]/g, "").length;
  const ascii = text.replace(/[^a-zA-Z]/g, "").length;
  return cjk >= ascii;
}

/**
 * Split text into lines for display.
 * Chinese: max 12 chars per line, break on punctuation.
 * English: max 25 chars per line, break on word boundaries.
 * Max 2 lines per caption (Jianying standard).
 */
function splitIntoLines(text: string): string[] {
  const chinese = isChinese(text);
  const MAX_LINE = chinese ? 12 : 25;

  // Strip trailing Chinese comma/period from display (keep ！？ for emphasis)
  let cleaned = chinese ? text.replace(/[，。、；：]+$/g, "") : text;
  if (cleaned.length === 0) cleaned = text; // safety: don't produce empty

  // Short text — single line
  if (cleaned.length <= MAX_LINE) return [cleaned];

  // Helper: strip trailing CN punctuation from each line
  const stripTrailing = (s: string) => chinese ? s.replace(/[，。、；：]+$/g, "") : s;

  if (chinese) {
    // Chinese: use punctuation as split points, then strip from display
    const parts = cleaned.split(/(?<=[，。！？、；：])/);
    if (parts.length <= 1) {
      // No punctuation — balanced split to prevent orphans
      if (cleaned.length <= MAX_LINE * 2) {
        const mid = Math.ceil(cleaned.length / 2);
        return [stripTrailing(cleaned.slice(0, mid)), stripTrailing(cleaned.slice(mid))];
      }
      const lines: string[] = [];
      for (let i = 0; i < cleaned.length; i += MAX_LINE) {
        lines.push(stripTrailing(cleaned.slice(i, i + MAX_LINE)));
      }
      return lines.slice(0, 2);
    }

    const lines: string[] = [];
    let current = "";

    for (const part of parts) {
      if (current.length === 0) {
        current = part;
      } else if (current.length + part.length <= MAX_LINE) {
        current += part;
      } else {
        lines.push(stripTrailing(current));
        current = part;
      }
    }

    if (current.length > 0) {
      const stripped = current.replace(/[，。！？、；：。？！]/g, "");
      if (stripped.length < 5 && lines.length > 0) {
        lines[lines.length - 1] += stripTrailing(current);
      } else {
        lines.push(stripTrailing(current));
      }
    }

    return (lines.length > 0 ? lines : [cleaned]).slice(0, 2);
  } else {
    // English: break on word boundaries
    const words = cleaned.split(/\s+/);
    const lines: string[] = [];
    let current = "";

    for (const word of words) {
      if (current.length === 0) {
        current = word;
      } else if (current.length + 1 + word.length <= MAX_LINE) {
        current += " " + word;
      } else {
        lines.push(current);
        current = word;
      }
    }
    if (current.length > 0) {
      lines.push(current);
    }

    return (lines.length > 0 ? lines : [cleaned]).slice(0, 2);
  }
}

interface EmphasisRange {
  start: number;
  end: number;
  color: string;
  scale: number;
  kinetic?: string;
}

function findEmphasisRanges(
  text: string,
  emphasis?: (EmphasisSegment | string)[],
  defaultScale?: number,
  defaultColor?: string,
): EmphasisRange[] {
  if (!emphasis || emphasis.length === 0) return [];

  const ranges: EmphasisRange[] = [];
  const clean = text.replace(/\*\*/g, "");

  for (const em of emphasis) {
    // Support both string and object emphasis formats
    const emText = typeof em === "string" ? em : em.text;
    const emColor = typeof em === "string" ? undefined : em.color;
    const emScale = typeof em === "string" ? undefined : em.scale;
    const emKinetic = typeof em === "string" ? undefined : em.kinetic;
    if (!emText) continue;
    const needle = emText.replace(/\*\*/g, "");
    const idx = clean.indexOf(needle);
    if (idx !== -1) {
      ranges.push({
        start: idx,
        end: idx + needle.length,
        color: emColor || defaultColor || SALMON_DEEP,
        scale: emScale || defaultScale || 1.15,
        kinetic: emKinetic,
      });
    }
  }

  return ranges.sort((a, b) => a.start - b.start);
}

/**
 * Word-by-word dialogue text with emphasis + preset styling.
 */
const DialogueText: React.FC<{
  text: string;
  durationInFrames: number;
  emphasis?: (EmphasisSegment | string)[];
  textStyle: TextStyle;
  preset: PresetConfig;
  instantReveal?: boolean;
  charTimestamps?: number[];
  blockStartS?: number;
  fps?: number;
  textDelayFrames?: number;
}> = ({ text, durationInFrames, emphasis, textStyle, preset, instantReveal, charTimestamps, blockStartS, fps: fpsProp, textDelayFrames = 0 }) => {
  const rawFrame = useCurrentFrame();
  const frame = Math.max(0, rawFrame - textDelayFrames);

  const { fps: configFps } = useVideoConfig();
  const fps = fpsProp || configFps;

  const clean = text.replace(/\*\*/g, "");
  const lines = splitIntoLines(clean);
  const ranges = findEmphasisRanges(text, emphasis, preset.emphasisScale, preset.emphasisColor);

  const totalChars = clean.length;

  // Audio-synced reveal: if char_timestamps are available, use them for
  // frame-precise text-voice sync. Otherwise fall back to uniform distribution.
  const hasTimestamps = charTimestamps && charTimestamps.length >= totalChars;
  const blockOffset = blockStartS || 0;

  const revealFrames = Math.max(12, Math.floor(durationInFrames * 0.55));
  const framesPerChar = revealFrames / Math.max(totalChars, 1);

  const fadeOutFrames = Math.min(6, Math.floor(durationInFrames / 5));
  const fadeOut = interpolate(
    frame,
    [durationInFrames - fadeOutFrames, durationInFrames],
    [1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
  );

  // full_emphasis: entire phrase highlighted — salmon stroke + brown directional shadow
  // Matches text_style_presets.json full_emphasis config.
  const isFullEmphasis = textStyle === "full_emphasis";
  const baseFontSize = (textStyle === "bold" || isFullEmphasis) ? preset.bodyBoldSize : preset.bodySize;
  const baseWeight = (textStyle === "bold" || isFullEmphasis) ? preset.bodyBoldWeight : preset.bodyWeight;

  let globalIdx = 0;

  const lineNodes = lines.map((line, lineIdx) => {
    const lineStart = globalIdx;
    const charNodes: React.ReactNode[] = [];

    for (let i = 0; i < line.length; i++) {
      const charIdx = lineStart + i;
      // Frame when this character should appear:
      // - With timestamps: convert absolute timestamp (seconds) to frame relative to block start
      // - Without timestamps: uniform distribution across 55% of block duration
      const charAppearFrame = hasTimestamps
        ? Math.round((charTimestamps![charIdx] - blockOffset) * fps)
        : charIdx * framesPerChar;
      // Instant reveal — no per-char fade so text keeps up with VO
      const charOpacity = instantReveal
        ? 1
        : interpolate(
            frame,
            [charAppearFrame, charAppearFrame + 1],
            [0, 1],
            { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
          );

      const emRange = ranges.find(r => charIdx >= r.start && charIdx < r.end);

      const style: React.CSSProperties = {
        opacity: charOpacity * fadeOut,
        display: "inline",
      };

      if (isFullEmphasis) {
        // Full phrase emphasis — preset-aware rendering.
        // en_polished/cn_polished: pink text on dark brown background bar
        // en_black_outline/cn_black_outline: white text with salmon stroke + brown shadow
        style.color = preset.fullEmphasisColor;
        style.fontWeight = 900;
        style.letterSpacing = "0.10em";
        if (preset.fullEmphasisStroke) {
          style.textShadow = preset.fullEmphasisStroke;
        }
        // Background bar handled at container level (bgStrip uses fullEmphasisBg)
      } else if (emRange) {
        style.color = emRange.color;
        style.fontWeight = 700;
        style.fontSize = Math.round(baseFontSize * emRange.scale);
        // Emphasis stroke MUST render on top of base shadow.
        // CSS textShadow: first listed = rendered on top.
        const baseShadow = preset.textShadow || "";
        const extraShadow = preset.emphasisShadow || "";
        const extraGlow = preset.emphasisGlow || "";
        const layers = [extraShadow, extraGlow, baseShadow].filter(Boolean);
        style.textShadow = layers.join(", ");

        // Kinetic animation: spring-based transform on emphasis words.
        // CRITICAL: Use the FIRST character's appear frame for the entire word,
        // so the whole emphasis phrase animates as ONE unit — not per-character
        // (which looks "stuck" as letters trickle in with individual springs).
        if (emRange.kinetic && charOpacity > 0.1) {
          // Word-level trigger: when instantReveal, fire kinetic at frame 3
          // (tiny delay for visual pop). Otherwise use timestamp-based timing.
          const wordStartFrame = instantReveal
            ? 3
            : hasTimestamps
              ? Math.round((charTimestamps![emRange.start] - blockOffset) * fps)
              : emRange.start * framesPerChar;
          const kineticProgress = spring({
            frame: Math.max(0, frame - Math.round(wordStartFrame)),
            fps,
            // Snappy spring: low mass = fast, higher stiffness = punchy,
            // moderate damping = settles quickly without oscillating
            config: { damping: 18, stiffness: 280, mass: 0.4 },
          });
          const mode = emRange.kinetic;
          if (mode === "scale_pop") {
            const s = interpolate(kineticProgress, [0, 1], [1.5, 1]);
            style.transform = `scale(${s})`;
            style.display = "inline-block";
          } else if (mode === "bounce") {
            const s = interpolate(kineticProgress, [0, 1], [1.3, 1]);
            const y = interpolate(kineticProgress, [0, 0.5, 1], [-8, 3, 0]);
            style.transform = `scale(${s}) translateY(${y}px)`;
            style.display = "inline-block";
          } else if (mode === "blur_reveal") {
            const blur = interpolate(kineticProgress, [0, 1], [6, 0]);
            style.filter = `blur(${blur}px)`;
          } else if (mode === "slide_up") {
            const y = interpolate(kineticProgress, [0, 1], [15, 0]);
            style.transform = `translateY(${y}px)`;
            style.display = "inline-block";
          } else if (mode === "drop") {
            const y = interpolate(kineticProgress, [0, 1], [-20, 0]);
            const s = interpolate(kineticProgress, [0, 0.7, 1], [1.2, 0.97, 1]);
            style.transform = `translateY(${y}px) scale(${s})`;
            style.display = "inline-block";
          } else if (mode === "glow_pulse") {
            const glowIntensity = interpolate(kineticProgress, [0, 0.5, 1], [0, 15, 5]);
            style.textShadow = (style.textShadow || "") + `, 0 0 ${glowIntensity}px ${emRange.color}`;
          }
        }
      } else {
        style.color = preset.bodyColor;
      }

      // Preserve spaces inside emphasis groups — inline-block collapses whitespace
      const ch = line[i] === " " && emRange ? "\u00A0" : line[i];
      charNodes.push(
        <span key={`c-${charIdx}`} style={style}>{ch}</span>,
      );
    }

    globalIdx += line.length;
    // Account for the space/newline between lines that splitIntoLines consumed.
    // Without this, emphasis ranges (computed on full text) drift by 1 char per line break.
    if (lineIdx < lines.length - 1) {
      globalIdx += 1; // the eaten space between lines
    }

    // Group consecutive emphasis chars into nowrap wrapper spans so
    // emphasis phrases never split across line breaks.
    const groupedNodes: React.ReactNode[] = [];
    let groupBuf: React.ReactNode[] = [];
    let groupRangeStart: number | null = null;

    for (let ci = 0; ci < charNodes.length; ci++) {
      const absIdx = lineStart + ci;
      const em = ranges.find(r => absIdx >= r.start && absIdx < r.end);
      const curStart = em ? em.start : null;

      if (curStart !== null && curStart === groupRangeStart) {
        // Continue same emphasis group
        groupBuf.push(charNodes[ci]);
      } else {
        // Flush previous group
        if (groupBuf.length > 0 && groupRangeStart !== null) {
          groupedNodes.push(
            <span key={`emg-${lineIdx}-${groupRangeStart}`} style={{ display: "inline-block", whiteSpace: "nowrap" }}>
              {groupBuf}
            </span>,
          );
        } else {
          groupedNodes.push(...groupBuf);
        }
        groupBuf = [charNodes[ci]];
        groupRangeStart = curStart;
      }
    }
    // Flush final group
    if (groupBuf.length > 0 && groupRangeStart !== null) {
      groupedNodes.push(
        <span key={`emg-${lineIdx}-${groupRangeStart}-f`} style={{ display: "inline-block", whiteSpace: "nowrap" }}>
          {groupBuf}
        </span>,
      );
    } else {
      groupedNodes.push(...groupBuf);
    }

    return (
      <div key={`line-${lineIdx}`} style={{ whiteSpace: "pre-wrap", wordBreak: "keep-all", textWrap: "balance" as any }}>
        {groupedNodes}
      </div>
    );
  });

  // Background: preset bgStrip for normal text, fullEmphasisBg for full_emphasis blocks
  const activeBg = isFullEmphasis && preset.fullEmphasisBg
    ? preset.fullEmphasisBg
    : preset.bgStrip;
  const hasBg = !!activeBg;

  const innerContent = (
    <div
      style={{
        fontFamily: preset.bodyFont,
        fontWeight: baseWeight,
        fontSize: baseFontSize,
        color: preset.bodyColor,
        textAlign: "center",
        padding: hasBg ? (preset.bgStripPadding || "12px 24px") : "0 40px",
        lineHeight: preset.lineHeight,
        letterSpacing: preset.letterSpacing,
        textShadow: preset.textShadow,
        ...(hasBg
          ? {
              background: activeBg,
              borderRadius: preset.bgStripRadius,
              display: "inline-block",
            }
          : {}),
      }}
    >
      {lineNodes}
    </div>
  );

  return innerContent;
};

/**
 * SegmentedDialogue — renders subtitle-style captions.
 * Shows one segment at a time, each appearing/disappearing in sync with VO.
 * Like real subtitles: short phrases that follow the speaking rhythm.
 */
const SegmentedDialogue: React.FC<{
  segments: CaptionSegment[];
  durationInFrames: number;
  textStyle: TextStyle;
  preset: PresetConfig;
  fps: number;
}> = ({ segments, durationInFrames, textStyle, preset, fps }) => {
  const frame = useCurrentFrame();
  const currentTimeS = frame / fps;

  // Find the active segment based on current time
  const activeSegment = segments.find(
    (seg) => currentTimeS >= seg.start_s && currentTimeS < seg.end_s,
  );

  if (!activeSegment) return null;

  // Calculate segment-local progress for fade-in
  const segStartFrame = Math.round(activeSegment.start_s * fps);
  const segFrame = frame - segStartFrame;

  // Instant appear — no fade delay so text keeps up with VO
  const fadeIn = 1;

  // Quick 3-frame fade-out before segment ends
  const segEndFrame = Math.round(activeSegment.end_s * fps);
  const fadeOut = interpolate(frame, [segEndFrame - 3, segEndFrame], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  const opacity = fadeIn * fadeOut;

  // Render this segment's text using DialogueText (reuses emphasis/styling)
  const segDurationFrames = Math.round((activeSegment.end_s - activeSegment.start_s) * fps);

  return (
    <div style={{ opacity }}>
      <DialogueText
        text={activeSegment.text}
        durationInFrames={durationInFrames}
        emphasis={activeSegment.emphasis ?? undefined}
        textStyle={textStyle}
        preset={preset}
        instantReveal={true}
        fps={fps}
      />
    </div>
  );
};

export const TextOverlayLayer: React.FC<TextOverlayProps> = ({
  text,
  headline,
  style,
  position,
  durationInFrames,
  emphasis,
  color,
  outline = true,
  charTimestamps,
  blockStartS,
  emoji,
  preset: presetName,
  instantReveal,
  textDelayFrames,
  segments,
}) => {
  const rawFrame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const preset = getPreset(presetName);
  const delay = textDelayFrames || 0;

  // During delay period, entire text overlay is hidden (visual-first hook)
  if (rawFrame < delay) {
    return null;
  }

  const frame = rawFrame - delay;

  // Use subtitle-style segmented captions when segments are available.
  // Shows one short phrase at a time in sync with VO — like real subtitles.
  const useSegments = segments && segments.length > 1;

  return (
    <AbsoluteFill
      style={{
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        pointerEvents: "none",
        ...POSITION_OUTER[position],
      }}
    >
      {/* Headline — own absolute layer, NOT affected by body text height */}
      {headline && (
        <div
          style={{
            position: "absolute",
            top: "50%",
            left: 0,
            right: 0,
            display: "flex",
            justifyContent: "center",
            pointerEvents: "none",
            zIndex: 10,
          }}
        >
          <HeadlineText text={headline} durationInFrames={durationInFrames} preset={preset} />
        </div>
      )}

      {/* Emoji — dynamic position: sits above body text, below headline.
          Body text bottom edge = 540px from bottom. Each text line ~70px (CN 56px + line gap).
          Uses splitIntoLines() for accurate line count instead of character estimation. */}
      {emoji && emoji.length > 0 && (() => {
        // Use splitIntoLines() for accurate line count (matches actual rendering)
        const bodyText = segments && segments.length > 0
          ? segments.map((s: {text?: string}) => s.text || "").join("")
          : (text || "");
        const isCN = /[\u4e00-\u9fff]/.test(bodyText);
        const actualLines = bodyText.length > 0 ? splitIntoLines(bodyText) : [""];
        const lineCount = Math.max(1, actualLines.length);
        const lineHeight = isCN ? 75 : 60; // px per line
        const textAreaHeight = lineCount * lineHeight;
        // Body text bottom = 540px from bottom, extends upward by textAreaHeight
        // Emoji sits 60px above the top of text area (increased from 40px for extra clearance)
        const emojiBottom = 540 + textAreaHeight + 60;
        // If headline exists (at ~50% = 960px from top = 960px from bottom),
        // clamp emoji so it doesn't overlap headline (keep below 960-80=880 from bottom)
        const maxBottom = headline ? 880 : 1100;
        const finalBottom = Math.min(emojiBottom, maxBottom);

        return (
          <div
            style={{
              position: "absolute",
              bottom: finalBottom,
              left: 0,
              right: 0,
              display: "flex",
              justifyContent: "center",
              pointerEvents: "none",
              zIndex: 9,
            }}
          >
            <EmojiDeco emojis={emoji} durationInFrames={durationInFrames} />
          </div>
        );
      })()}

      <div style={{ maxWidth: "82%", position: "relative", overflow: "hidden", padding: "0 8px" }}>
        {/* Caption text — two modes:
            1. Segmented: short phrases appear/disappear with VO (subtitle-style)
            2. Full: entire text shown at once (for short text or no segments) */}
        {useSegments ? (
          <SegmentedDialogue
            segments={segments!}
            durationInFrames={durationInFrames}
            textStyle={style}
            preset={preset}
            fps={fps}
          />
        ) : (
          <DialogueText
            text={text}
            durationInFrames={durationInFrames}
            emphasis={emphasis}
            textStyle={style}
            preset={preset}
            instantReveal={true}
            charTimestamps={charTimestamps}
            blockStartS={blockStartS}
            fps={fps}
          />
        )}
      </div>
    </AbsoluteFill>
  );
};
