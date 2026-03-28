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
  FONT_HEADING,
  FONT_BODY,
} from "../fonts";

ensureBrandFonts();

const NEAR_BLACK = "#252525";
const MIRRA_SALMON = "#F7AB9F";
const WARM_CREAM = "#FFF9EB";

type KineticAnimationStyle = "word_pop" | "line_slide" | "typewriter" | "scale_bounce";

interface KineticLine {
  text: string;
  color?: string;
  fontSize?: number;
  bold?: boolean;
}

interface KineticTextBlockProps {
  lines: KineticLine[];
  bgColor?: string;
  animationStyle?: KineticAnimationStyle;
  durationInFrames: number;
  textAlign?: "center" | "left";
  accentColor?: string;
}

/**
 * Parse text for *asterisk* accent markers.
 * Returns array of segments: { text, isAccent }.
 */
function parseAccents(text: string): Array<{ text: string; isAccent: boolean }> {
  const segments: Array<{ text: string; isAccent: boolean }> = [];
  const regex = /\*([^*]+)\*/g;
  let lastIndex = 0;
  let match: RegExpExecArray | null;

  while ((match = regex.exec(text)) !== null) {
    if (match.index > lastIndex) {
      segments.push({ text: text.slice(lastIndex, match.index), isAccent: false });
    }
    segments.push({ text: match[1], isAccent: true });
    lastIndex = regex.lastIndex;
  }
  if (lastIndex < text.length) {
    segments.push({ text: text.slice(lastIndex), isAccent: false });
  }
  if (segments.length === 0) {
    segments.push({ text, isAccent: false });
  }
  return segments;
}

/**
 * Render a single line with accent highlighting.
 */
const AccentedText: React.FC<{
  text: string;
  accentColor: string;
  baseColor: string;
  fontSize: number;
  bold: boolean;
  fontFamily: string;
}> = ({ text, accentColor, baseColor, fontSize, bold, fontFamily }) => {
  const segments = parseAccents(text);
  return (
    <span>
      {segments.map((seg, i) => (
        <span
          key={i}
          style={{
            color: seg.isAccent ? accentColor : baseColor,
            fontWeight: seg.isAccent ? 800 : bold ? 700 : 500,
            fontSize: seg.isAccent ? fontSize * 1.15 : fontSize,
            fontFamily,
          }}
        >
          {seg.text}
        </span>
      ))}
    </span>
  );
};

/**
 * word_pop: each word appears with spring scale, staggered across all lines.
 */
const WordPopLayout: React.FC<{
  lines: KineticLine[];
  frame: number;
  fps: number;
  textAlign: "center" | "left";
  accentColor: string;
}> = ({ lines, frame, fps, textAlign, accentColor }) => {
  let wordIndex = 0;

  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        alignItems: textAlign === "center" ? "center" : "flex-start",
        gap: 24,
        padding: "0 60px",
        width: "100%",
      }}
    >
      {lines.map((line, lineIdx) => {
        const words = line.text.split(/\s+/);
        const fontSize = line.fontSize || 72;
        const color = line.color || WARM_CREAM;
        const fontFamily = line.bold !== false ? FONT_HEADING : FONT_BODY;

        return (
          <div
            key={lineIdx}
            style={{
              display: "flex",
              flexWrap: "wrap",
              justifyContent: textAlign === "center" ? "center" : "flex-start",
              gap: "0 16px",
            }}
          >
            {words.map((word, wIdx) => {
              const delay = wordIndex * 3;
              wordIndex++;

              const pop = spring({
                frame,
                fps,
                config: { damping: 12, stiffness: 150, mass: 0.6 },
                delay,
              });

              const scale = interpolate(pop, [0, 1], [0, 1], { extrapolateRight: "clamp" });
              const opacity = pop;

              return (
                <span
                  key={wIdx}
                  style={{
                    display: "inline-block",
                    transform: `scale(${scale})`,
                    opacity,
                    transformOrigin: "center bottom",
                  }}
                >
                  <AccentedText
                    text={word}
                    accentColor={accentColor}
                    baseColor={color}
                    fontSize={fontSize}
                    bold={line.bold !== false}
                    fontFamily={fontFamily}
                  />
                </span>
              );
            })}
          </div>
        );
      })}
    </div>
  );
};

/**
 * line_slide: each line slides in from alternating left/right.
 */
const LineSlideLayout: React.FC<{
  lines: KineticLine[];
  frame: number;
  fps: number;
  textAlign: "center" | "left";
  accentColor: string;
}> = ({ lines, frame, fps, textAlign, accentColor }) => {
  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        alignItems: textAlign === "center" ? "center" : "flex-start",
        gap: 32,
        padding: "0 60px",
        width: "100%",
      }}
    >
      {lines.map((line, i) => {
        const delay = i * 8;
        const slideProgress = spring({
          frame,
          fps,
          config: { damping: 18, stiffness: 80 },
          delay,
        });

        const direction = i % 2 === 0 ? -1 : 1;
        const tx = interpolate(slideProgress, [0, 1], [400 * direction, 0], {
          extrapolateRight: "clamp",
        });
        const opacity = slideProgress;
        const fontSize = line.fontSize || 72;
        const color = line.color || WARM_CREAM;
        const fontFamily = line.bold !== false ? FONT_HEADING : FONT_BODY;

        return (
          <div
            key={i}
            style={{
              transform: `translateX(${tx}px)`,
              opacity,
              textAlign,
            }}
          >
            <AccentedText
              text={line.text}
              accentColor={accentColor}
              baseColor={color}
              fontSize={fontSize}
              bold={line.bold !== false}
              fontFamily={fontFamily}
            />
          </div>
        );
      })}
    </div>
  );
};

/**
 * typewriter: characters appear one at a time across all lines.
 */
const TypewriterLayout: React.FC<{
  lines: KineticLine[];
  frame: number;
  durationInFrames: number;
  textAlign: "center" | "left";
  accentColor: string;
}> = ({ lines, frame, durationInFrames, textAlign, accentColor }) => {
  // Total chars across all lines
  const totalChars = lines.reduce((sum, l) => sum + l.text.replace(/\*/g, "").length, 0);
  // Use 70% of duration for typing, 30% for hold
  const typingFrames = Math.floor(durationInFrames * 0.7);
  const charsRevealed = Math.floor(
    interpolate(frame, [0, typingFrames], [0, totalChars], {
      extrapolateLeft: "clamp",
      extrapolateRight: "clamp",
    })
  );

  let charsSoFar = 0;

  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        alignItems: textAlign === "center" ? "center" : "flex-start",
        gap: 24,
        padding: "0 60px",
        width: "100%",
      }}
    >
      {lines.map((line, i) => {
        const plainText = line.text.replace(/\*/g, "");
        const lineStart = charsSoFar;
        charsSoFar += plainText.length;
        const lineCharsRevealed = Math.max(0, Math.min(plainText.length, charsRevealed - lineStart));
        const fontSize = line.fontSize || 72;
        const color = line.color || WARM_CREAM;
        const fontFamily = line.bold !== false ? FONT_HEADING : FONT_BODY;

        if (lineCharsRevealed <= 0) return null;

        // Build revealed text preserving accent markers
        const segments = parseAccents(line.text);
        let revealed = 0;

        return (
          <div key={i} style={{ textAlign }}>
            {segments.map((seg, j) => {
              const segLen = seg.text.length;
              const segStart = revealed;
              revealed += segLen;
              const visibleCount = Math.max(0, Math.min(segLen, lineCharsRevealed - segStart));
              if (visibleCount <= 0) return null;

              return (
                <span
                  key={j}
                  style={{
                    color: seg.isAccent ? accentColor : color,
                    fontWeight: seg.isAccent ? 800 : line.bold !== false ? 700 : 500,
                    fontSize: seg.isAccent ? fontSize * 1.15 : fontSize,
                    fontFamily,
                  }}
                >
                  {seg.text.slice(0, visibleCount)}
                </span>
              );
            })}
            {/* Blinking cursor at end of current typing line */}
            {charsRevealed < totalChars && charsRevealed >= lineStart && charsRevealed <= lineStart + plainText.length && (
              <span
                style={{
                  opacity: Math.sin(frame * 0.3) > 0 ? 1 : 0,
                  color: accentColor,
                  fontSize,
                  fontFamily,
                  fontWeight: 300,
                }}
              >
                |
              </span>
            )}
          </div>
        );
      })}
    </div>
  );
};

/**
 * scale_bounce: each line scales up with overshoot spring.
 */
const ScaleBounceLayout: React.FC<{
  lines: KineticLine[];
  frame: number;
  fps: number;
  textAlign: "center" | "left";
  accentColor: string;
}> = ({ lines, frame, fps, textAlign, accentColor }) => {
  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        alignItems: textAlign === "center" ? "center" : "flex-start",
        gap: 32,
        padding: "0 60px",
        width: "100%",
      }}
    >
      {lines.map((line, i) => {
        const delay = i * 10;
        const bounceProgress = spring({
          frame,
          fps,
          config: { damping: 8, stiffness: 120, mass: 0.7 },
          delay,
        });

        const scale = interpolate(bounceProgress, [0, 1], [0, 1], {
          extrapolateRight: "clamp",
        });
        const opacity = Math.min(bounceProgress * 2, 1);
        const fontSize = line.fontSize || 72;
        const color = line.color || WARM_CREAM;
        const fontFamily = line.bold !== false ? FONT_HEADING : FONT_BODY;

        return (
          <div
            key={i}
            style={{
              transform: `scale(${scale})`,
              opacity,
              transformOrigin: "center center",
              textAlign,
            }}
          >
            <AccentedText
              text={line.text}
              accentColor={accentColor}
              baseColor={color}
              fontSize={fontSize}
              bold={line.bold !== false}
              fontFamily={fontFamily}
            />
          </div>
        );
      })}
    </div>
  );
};

export const KineticTextBlock: React.FC<KineticTextBlockProps> = ({
  lines,
  bgColor = NEAR_BLACK,
  animationStyle = "word_pop",
  durationInFrames,
  textAlign = "center",
  accentColor = MIRRA_SALMON,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Edge case: no lines
  if (!lines || lines.length === 0) {
    return <AbsoluteFill style={{ backgroundColor: bgColor }} />;
  }

  const sharedProps = { lines, frame, fps, textAlign, accentColor };

  return (
    <AbsoluteFill
      style={{
        backgroundColor: bgColor,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
      }}
    >
      {animationStyle === "word_pop" && <WordPopLayout {...sharedProps} />}
      {animationStyle === "line_slide" && <LineSlideLayout {...sharedProps} />}
      {animationStyle === "typewriter" && (
        <TypewriterLayout
          lines={lines}
          frame={frame}
          durationInFrames={durationInFrames}
          textAlign={textAlign}
          accentColor={accentColor}
        />
      )}
      {animationStyle === "scale_bounce" && <ScaleBounceLayout {...sharedProps} />}
    </AbsoluteFill>
  );
};
