import React from "react";
import {
  AbsoluteFill,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { ensureBrandFonts, FONT_BODY } from "../fonts";

ensureBrandFonts();

/* ═══════════════════════════════════════════════════════════════════════
 * KineticOverlay v3 — World-class kinetic typography for brand montage ads
 *
 * MASTERY PRINCIPLES (from Grubhub/DoorDash/Apple/Nike analysis):
 *
 * 1. EVERY WORD IS A DESIGN OBJECT — independent size, weight, color,
 *    position, animation style, and timing. Not a text block — a composition.
 *
 * 2. ANIMATION VARIETY — different entrance styles per phrase prevents
 *    visual fatigue. Slam for hooks, blur reveal for transitions,
 *    slide for supporting text. Monotony = amateur.
 *
 * 3. INDEPENDENT Y POSITIONING — each word occupies its own vertical
 *    space. Creates cascading columns, diagonal tension, visual hierarchy.
 *    Not 3 fixed slots — continuous Y control.
 *
 * 4. EXIT MATTERS — hard cut, slide-out, scale-down, blur-out.
 *    The exit animation is as important as the entrance.
 *
 * 5. BEAT SYNC — text lands ON the musical beat. Pre-roll the animation
 *    2-3 frames so the IMPACT frame (scale=1.0) hits the beat, not the
 *    start of the animation.
 *
 * 6. CLARITY > COMPLEXITY — research shows simple bold text with 20%
 *    longer dwell outperforms fancy animations by 60% on share rate.
 *    Motion should REDUCE cognitive load, not add to it.
 *
 * 7. COMPOSITIONAL TENSION — text on one side, visual subject on the
 *    other. Gradient dim only on the text side. Creates depth and focus.
 * ═══════════════════════════════════════════════════════════════════════ */

// ─── Animation mode types ────────────────────────────────────────────
export type AnimationMode =
  | "slam"           // Scale overshoot + slight slide (default, Grubhub style)
  | "blur_reveal"    // Blur-to-sharp with scale
  | "slide_up"       // Smooth slide from below with fade
  | "slide_down"     // Smooth slide from above
  | "elastic"        // Rubber-band bounce (playful/fun)
  | "typewriter"     // Character-by-character reveal
  | "fade_scale"     // Subtle fade + gentle scale (elegant)
  | "drop"           // Drop from above with gravity bounce
  ;

export type ExitMode =
  | "fade"           // Simple opacity fade (default)
  | "slide_out"      // Slide away in alignment direction
  | "scale_down"     // Shrink to nothing
  | "blur_out"       // Sharp-to-blur exit
  | "cut"            // Instant disappear (hard cut)
  ;

/**
 * A single phrase in the kinetic overlay timeline.
 * Each phrase is a complete visual composition — words animate in
 * as independent design objects, hold, then exit together.
 */
export interface KineticPhrase {
  words: string[];
  start_s: number;
  end_s: number;

  // Per-word visual overrides (arrays must match words.length)
  colors?: string[];
  fontSizes?: number[];
  fontWeights?: number[];

  // Per-word Y offset in pixels (independent vertical positioning)
  // Positive = down from phrase anchor, negative = up
  yOffsets?: number[];

  // Per-word rotation on entry (degrees, resolves to 0)
  rotations?: number[];

  // Phrase-level layout
  align?: "right" | "left" | "center";
  vPosition?: "upper_third" | "center" | "lower_third";

  // Animation controls
  animationMode?: AnimationMode;
  exitMode?: ExitMode;
  staggerFrames?: number;    // Frames between each word (default: 3)
  holdBeforeExit?: number;   // Extra hold frames before exit starts

  // Per-word letter spacing overrides
  letterSpacings?: number[];
}

interface KineticOverlayProps {
  phrases: KineticPhrase[];
  color?: string;
  fontSize?: number;
  dimVideo?: boolean;
  dimOpacity?: number;
}

// ─── Spring configs per animation mode ───────────────────────────────
const SPRING_CONFIGS: Record<AnimationMode, { damping: number; stiffness: number; mass: number }> = {
  slam:         { damping: 14, stiffness: 220, mass: 0.8 },
  blur_reveal:  { damping: 22, stiffness: 120, mass: 1.0 },
  slide_up:     { damping: 20, stiffness: 140, mass: 0.8 },
  slide_down:   { damping: 20, stiffness: 140, mass: 0.8 },
  elastic:      { damping: 8,  stiffness: 260, mass: 0.6 },
  typewriter:   { damping: 30, stiffness: 300, mass: 0.3 },
  fade_scale:   { damping: 26, stiffness: 90,  mass: 1.0 },
  drop:         { damping: 12, stiffness: 180, mass: 1.2 },
};

// ─── Per-mode animation values ───────────────────────────────────────
// CRITICAL: Use extrapolateRight: "extend" on scale/rotation/position
// to PRESERVE spring overshoot. The spring naturally goes past 1.0 —
// that overshoot IS the physical slam feel. Clamping it = killing physics.
// Only clamp opacity and blur (those should never exceed their targets).
function getWordTransform(
  mode: AnimationMode,
  progress: number,   // 0→1+ spring value (overshoots past 1.0!)
  align: "right" | "left" | "center",
  wordRotation: number,
): { scale: number; translateX: number; translateY: number; rotate: number; blur: number; opacity: number } {
  const slideDir = align === "right" ? 1 : align === "left" ? -1 : 0;

  switch (mode) {
    case "slam":
      // Scale 0.6→1.0 with overshoot to ~1.08, rotation resolves with same spring
      return {
        scale: interpolate(progress, [0, 1], [0.6, 1], { extrapolateRight: "extend" }),
        translateX: interpolate(progress, [0, 1], [40 * slideDir, 0], { extrapolateRight: "extend" }),
        translateY: 0,
        rotate: interpolate(progress, [0, 1], [wordRotation, 0], { extrapolateRight: "extend" }),
        blur: 0,
        opacity: interpolate(progress, [0, 0.15], [0, 1], { extrapolateRight: "clamp" }),
      };

    case "blur_reveal":
      // Blur resolves FASTER than scale (first 60% of spring) — text materializes
      return {
        scale: interpolate(progress, [0, 1], [0.92, 1], { extrapolateRight: "extend" }),
        translateX: 0,
        translateY: interpolate(progress, [0, 1], [8, 0], { extrapolateRight: "extend" }),
        rotate: 0,
        blur: interpolate(progress, [0, 0.6], [16, 0], { extrapolateRight: "clamp" }),
        opacity: interpolate(progress, [0, 0.2], [0, 1], { extrapolateRight: "clamp" }),
      };

    case "slide_up":
      return {
        scale: 1,
        translateX: 0,
        translateY: interpolate(progress, [0, 1], [60, 0], { extrapolateRight: "extend" }),
        rotate: 0,
        blur: 0,
        opacity: interpolate(progress, [0, 0.25], [0, 1], { extrapolateRight: "clamp" }),
      };

    case "slide_down":
      return {
        scale: 1,
        translateX: 0,
        translateY: interpolate(progress, [0, 1], [-60, 0], { extrapolateRight: "extend" }),
        rotate: 0,
        blur: 0,
        opacity: interpolate(progress, [0, 0.25], [0, 1], { extrapolateRight: "clamp" }),
      };

    case "elastic":
      // Pronounced overshoot with visible bounce — playful brands
      return {
        scale: interpolate(progress, [0, 1], [0.3, 1], { extrapolateRight: "extend" }),
        translateX: interpolate(progress, [0, 1], [20 * slideDir, 0], { extrapolateRight: "extend" }),
        translateY: 0,
        rotate: interpolate(progress, [0, 1], [wordRotation * 1.5, 0], { extrapolateRight: "extend" }),
        blur: 0,
        opacity: interpolate(progress, [0, 0.1], [0, 1], { extrapolateRight: "clamp" }),
      };

    case "typewriter":
      return {
        scale: 1,
        translateX: 0,
        translateY: 0,
        rotate: 0,
        blur: 0,
        opacity: interpolate(progress, [0, 0.01], [0, 1], { extrapolateRight: "clamp" }),
      };

    case "fade_scale":
      // Gentle, elegant — slight overshoot on scale, blur resolves fast
      return {
        scale: interpolate(progress, [0, 1], [0.85, 1], { extrapolateRight: "extend" }),
        translateX: 0,
        translateY: interpolate(progress, [0, 1], [15, 0], { extrapolateRight: "extend" }),
        rotate: 0,
        blur: interpolate(progress, [0, 0.7], [4, 0], { extrapolateRight: "clamp" }),
        opacity: interpolate(progress, [0, 0.4], [0, 1], { extrapolateRight: "clamp" }),
      };

    case "drop":
      // Gravity drop from above — scale starts LARGER (1.15), settles to 1.0
      // with overshoot below 1.0 (squash on landing)
      return {
        scale: interpolate(progress, [0, 1], [1.15, 1], { extrapolateRight: "extend" }),
        translateX: 0,
        translateY: interpolate(progress, [0, 1], [-80, 0], { extrapolateRight: "extend" }),
        rotate: interpolate(progress, [0, 1], [wordRotation * 0.5, 0], { extrapolateRight: "extend" }),
        blur: 0,
        opacity: interpolate(progress, [0, 0.1], [0, 1], { extrapolateRight: "clamp" }),
      };

    default:
      return { scale: 1, translateX: 0, translateY: 0, rotate: 0, blur: 0, opacity: 1 };
  }
}

// ─── Exit animation ──────────────────────────────────────────────────
function getExitValues(
  exitMode: ExitMode,
  exitProgress: number,  // 0→1
  align: "right" | "left" | "center",
): { opacity: number; scale: number; translateX: number; blur: number } {
  const slideDir = align === "right" ? 1 : align === "left" ? -1 : 0;

  switch (exitMode) {
    case "fade":
      return {
        opacity: interpolate(exitProgress, [0, 1], [1, 0], { extrapolateRight: "clamp" }),
        scale: 1,
        translateX: 0,
        blur: 0,
      };
    case "slide_out":
      return {
        opacity: interpolate(exitProgress, [0, 1], [1, 0], { extrapolateRight: "clamp" }),
        scale: 1,
        translateX: interpolate(exitProgress, [0, 1], [0, 80 * slideDir], { extrapolateRight: "clamp" }),
        blur: 0,
      };
    case "scale_down":
      return {
        opacity: interpolate(exitProgress, [0, 1], [1, 0], { extrapolateRight: "clamp" }),
        scale: interpolate(exitProgress, [0, 1], [1, 0.5], { extrapolateRight: "clamp" }),
        translateX: 0,
        blur: 0,
      };
    case "blur_out":
      return {
        opacity: interpolate(exitProgress, [0, 1], [1, 0], { extrapolateRight: "clamp" }),
        scale: 1,
        translateX: 0,
        blur: interpolate(exitProgress, [0, 1], [0, 20], { extrapolateRight: "clamp" }),
      };
    case "cut":
      return {
        opacity: exitProgress >= 0.99 ? 0 : 1,
        scale: 1,
        translateX: 0,
        blur: 0,
      };
    default:
      return { opacity: interpolate(exitProgress, [0, 1], [1, 0], { extrapolateRight: "clamp" }), scale: 1, translateX: 0, blur: 0 };
  }
}

// ─── Main component ──────────────────────────────────────────────────
export const KineticOverlay: React.FC<KineticOverlayProps> = ({
  phrases,
  color = "#FFFFFF",
  fontSize = 120,
  dimVideo = true,
  dimOpacity = 0.18,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  if (!phrases || phrases.length === 0) return null;

  const currentS = frame / fps;
  const activePhrase = phrases.find(
    (p) => currentS >= p.start_s && currentS < p.end_s
  );

  if (!activePhrase) return null;

  const phraseStartFrame = Math.round(activePhrase.start_s * fps);
  const phraseFrame = frame - phraseStartFrame;
  const phraseDurationFrames = Math.round(
    (activePhrase.end_s - activePhrase.start_s) * fps
  );

  // Animation mode & exit mode
  const animMode = activePhrase.animationMode || "slam";
  const exitMode = activePhrase.exitMode || "fade";
  const staggerFrames = activePhrase.staggerFrames ?? 3;

  // Exit: last 6 frames by default (200ms at 30fps)
  const exitDurationFrames = exitMode === "cut" ? 1 : 6;
  const holdExtra = activePhrase.holdBeforeExit ?? 0;
  const exitStartFrame = phraseDurationFrames - exitDurationFrames - holdExtra;

  const exitProgress = phraseFrame >= exitStartFrame
    ? interpolate(
        phraseFrame,
        [exitStartFrame, exitStartFrame + exitDurationFrames],
        [0, 1],
        { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
      )
    : 0;

  const exitVals = getExitValues(exitMode, exitProgress, activePhrase.align || "right");

  // Layout
  const align = activePhrase.align || "right";
  const vPos = activePhrase.vPosition || "upper_third";

  const paddingTop = vPos === "upper_third" ? 300
    : vPos === "center" ? 0
    : 0;

  const justifyContent = vPos === "lower_third" ? "flex-end"
    : vPos === "center" ? "center"
    : "flex-start";

  const alignItems = align === "right" ? "flex-end"
    : align === "left" ? "flex-start"
    : "center";

  const textAlign = align as "right" | "left" | "center";

  const transformOrigin = align === "right" ? "right center"
    : align === "left" ? "left center"
    : "center center";

  // Text shadow — subtle, layered for depth
  const textShadow = [
    "0 2px 8px rgba(0,0,0,0.4)",
    "0 0 30px rgba(0,0,0,0.15)",
    "0 4px 20px rgba(0,0,0,0.1)",
  ].join(", ");

  return (
    <>
      {/* Video dim layer — gradient darkening behind text area */}
      {dimVideo && (
        <AbsoluteFill
          style={{
            pointerEvents: "none",
            background: `linear-gradient(${
              align === "right"
                ? "to right, transparent 15%, rgba(0,0,0," + dimOpacity * 0.3 + ") 40%, rgba(0,0,0," + dimOpacity + ") 65%"
                : align === "left"
                ? "to left, transparent 15%, rgba(0,0,0," + dimOpacity * 0.3 + ") 40%, rgba(0,0,0," + dimOpacity + ") 65%"
                : "rgba(0,0,0," + dimOpacity + ")"
            })`,
            opacity: exitVals.opacity,
          }}
        />
      )}

      {/* Text composition layer */}
      <AbsoluteFill
        style={{
          pointerEvents: "none",
          display: "flex",
          flexDirection: "column",
          alignItems,
          justifyContent,
          paddingTop: vPos === "upper_third" ? paddingTop : 0,
          paddingBottom: vPos === "lower_third" ? 380 : 0,
          paddingLeft: 50,
          paddingRight: 50,
          // Exit transform applied to entire phrase
          opacity: exitVals.opacity,
          transform: `scale(${exitVals.scale}) translateX(${exitVals.translateX}px)`,
          filter: exitVals.blur > 0 ? `blur(${exitVals.blur}px)` : undefined,
        }}
      >
        {activePhrase.words.map((word, wIdx) => {
          const wordDelay = wIdx * staggerFrames;
          const springConfig = SPRING_CONFIGS[animMode];

          const wordSpring = spring({
            frame: phraseFrame,
            fps,
            config: springConfig,
            delay: wordDelay,
          });

          // Per-word overrides
          const wordColor = activePhrase.colors?.[wIdx] || color;
          const wordSize = activePhrase.fontSizes?.[wIdx] || fontSize;
          const wordWeight = activePhrase.fontWeights?.[wIdx] || 700;
          const wordYOffset = activePhrase.yOffsets?.[wIdx] || 0;
          const wordRotation = activePhrase.rotations?.[wIdx] || 0;
          const wordLetterSpacing = activePhrase.letterSpacings?.[wIdx] ?? -1;

          // Get animation values for this mode
          const anim = getWordTransform(animMode, wordSpring, align, wordRotation);

          // Typewriter mode: character-by-character reveal
          if (animMode === "typewriter") {
            const chars = word.split("");
            const totalChars = chars.length;
            const charsPerFrame = totalChars / Math.max(staggerFrames * 2, 6);
            const localFrame = phraseFrame - wordDelay;
            const visibleChars = Math.min(
              totalChars,
              Math.floor(Math.max(0, localFrame) * charsPerFrame)
            );

            return (
              <div
                key={wIdx}
                style={{
                  lineHeight: 0.88,
                  textAlign,
                  marginTop: wordYOffset,
                  opacity: anim.opacity * exitVals.opacity,
                }}
              >
                <span
                  style={{
                    fontFamily: FONT_BODY,
                    fontWeight: wordWeight,
                    fontSize: wordSize,
                    color: wordColor,
                    textShadow,
                    letterSpacing: wordLetterSpacing,
                    display: "block",
                    textTransform: "uppercase" as const,
                  }}
                >
                  <span>{word.slice(0, visibleChars)}</span>
                  <span style={{ opacity: 0 }}>{word.slice(visibleChars)}</span>
                </span>
              </div>
            );
          }

          // All other modes: spring-based word animation
          return (
            <div
              key={wIdx}
              style={{
                transform: [
                  `scale(${anim.scale})`,
                  `translateX(${anim.translateX}px)`,
                  `translateY(${anim.translateY}px)`,
                  `rotate(${anim.rotate}deg)`,
                ].join(" "),
                opacity: anim.opacity,
                filter: anim.blur > 0 ? `blur(${anim.blur}px)` : undefined,
                transformOrigin,
                lineHeight: 0.88,
                textAlign,
                marginTop: wordYOffset,
              }}
            >
              <span
                style={{
                  fontFamily: FONT_BODY,
                  fontWeight: wordWeight,
                  fontSize: wordSize,
                  color: wordColor,
                  textShadow,
                  letterSpacing: wordLetterSpacing,
                  display: "block",
                  textTransform: "uppercase" as const,
                }}
              >
                {word}
              </span>
            </div>
          );
        })}
      </AbsoluteFill>
    </>
  );
};
