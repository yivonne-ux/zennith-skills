import React from "react";
import {
  AbsoluteFill,
  Img,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import {
  ensureBrandFonts,
  FONT_HEADING,
} from "../fonts";

ensureBrandFonts();

const MIRRA_SALMON = "#F7AB9F";
const WARM_CREAM = "#FFF9EB";

type SplitDirection = "horizontal" | "vertical";

interface SplitScreenBlockProps {
  topMedia: string;
  bottomMedia: string;
  topLabel?: string;
  bottomLabel?: string;
  splitDirection?: SplitDirection;
  durationInFrames: number;
  animateReveal?: boolean;
  labelColor?: string;
}

/**
 * Animated label badge with spring entrance.
 */
const SplitLabel: React.FC<{
  text: string;
  color: string;
  frame: number;
  fps: number;
  delay: number;
  position: "top" | "bottom" | "left" | "right";
}> = ({ text, color, frame, fps, delay, position }) => {
  const labelSpring = spring({
    frame,
    fps,
    config: { damping: 14, stiffness: 120 },
    delay,
  });

  const scale = interpolate(labelSpring, [0, 1], [0.5, 1], { extrapolateRight: "clamp" });
  const opacity = labelSpring;

  // Position the label within its half
  const positionStyles: React.CSSProperties = {
    position: "absolute",
    zIndex: 10,
  };

  switch (position) {
    case "top":
      positionStyles.top = 40;
      positionStyles.left = "50%";
      positionStyles.transform = `translateX(-50%) scale(${scale})`;
      break;
    case "bottom":
      positionStyles.bottom = 40;
      positionStyles.left = "50%";
      positionStyles.transform = `translateX(-50%) scale(${scale})`;
      break;
    case "left":
      positionStyles.top = "50%";
      positionStyles.left = 30;
      positionStyles.transform = `translateY(-50%) scale(${scale})`;
      break;
    case "right":
      positionStyles.top = "50%";
      positionStyles.right = 30;
      positionStyles.transform = `translateY(-50%) scale(${scale})`;
      break;
  }

  return (
    <div
      style={{
        ...positionStyles,
        opacity,
        backgroundColor: `${color}CC`,
        borderRadius: 12,
        padding: "12px 32px",
        backdropFilter: "blur(8px)",
      }}
    >
      <span
        style={{
          fontFamily: FONT_HEADING,
          fontWeight: 700,
          fontSize: 36,
          color: WARM_CREAM,
          letterSpacing: 3,
          textTransform: "uppercase",
        }}
      >
        {text}
      </span>
    </div>
  );
};

export const SplitScreenBlock: React.FC<SplitScreenBlockProps> = ({
  topMedia,
  bottomMedia,
  topLabel,
  bottomLabel,
  splitDirection = "horizontal",
  durationInFrames,
  animateReveal = true,
  labelColor = MIRRA_SALMON,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const isHorizontal = splitDirection === "horizontal";

  // Ken Burns: subtle zoom on both halves
  const kenBurnsTop = interpolate(frame, [0, durationInFrames], [1.0, 1.06], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const kenBurnsBottom = interpolate(frame, [0, durationInFrames], [1.04, 1.0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  // Wipe-reveal animation for the "after" half
  // The divider starts covering the "after" side, then reveals it
  const revealProgress = animateReveal
    ? spring({
        frame,
        fps,
        config: { damping: 20, stiffness: 60 },
        delay: 8,
      })
    : 1;

  // Divider position: 0% = fully covering "after", 100% = at split line
  const dividerLineWidth = 4;

  // "Before" half clip region (always fully visible)
  const beforeClip = isHorizontal
    ? "polygon(0% 0%, 100% 0%, 100% 50%, 0% 50%)"
    : "polygon(0% 0%, 50% 0%, 50% 100%, 0% 100%)";

  // "After" half reveal: clip expands from split line outward
  const afterRevealPercent = interpolate(revealProgress, [0, 1], [0, 100], {
    extrapolateRight: "clamp",
  });

  const afterClip = isHorizontal
    ? `polygon(0% ${100 - afterRevealPercent / 2}%, 100% ${100 - afterRevealPercent / 2}%, 100% 100%, 0% 100%)`
    : `polygon(${100 - afterRevealPercent / 2}% 0%, 100% 0%, 100% 100%, ${100 - afterRevealPercent / 2}% 100%)`;

  // Divider line position
  const dividerStyle: React.CSSProperties = isHorizontal
    ? {
        position: "absolute",
        left: 0,
        right: 0,
        top: "50%",
        height: dividerLineWidth,
        backgroundColor: labelColor,
        transform: "translateY(-50%)",
        zIndex: 5,
        boxShadow: `0 0 12px ${labelColor}`,
      }
    : {
        position: "absolute",
        top: 0,
        bottom: 0,
        left: "50%",
        width: dividerLineWidth,
        backgroundColor: labelColor,
        transform: "translateX(-50%)",
        zIndex: 5,
        boxShadow: `0 0 12px ${labelColor}`,
      };

  // Divider opacity matches reveal
  const dividerOpacity = interpolate(revealProgress, [0, 0.3, 1], [0, 1, 1], {
    extrapolateRight: "clamp",
  });

  return (
    <AbsoluteFill style={{ backgroundColor: "#000", overflow: "hidden" }}>
      {/* "Before" / top / left half */}
      <div
        style={{
          position: "absolute",
          top: 0,
          left: 0,
          width: "100%",
          height: "100%",
          clipPath: beforeClip,
          overflow: "hidden",
        }}
      >
        <Img
          src={topMedia}
          style={{
            width: "100%",
            height: "100%",
            objectFit: "cover",
            transform: `scale(${kenBurnsTop})`,
            transformOrigin: "center center",
          }}
        />
        {topLabel && (
          <SplitLabel
            text={topLabel}
            color={labelColor}
            frame={frame}
            fps={fps}
            delay={15}
            position={isHorizontal ? "top" : "left"}
          />
        )}
      </div>

      {/* "After" / bottom / right half */}
      <div
        style={{
          position: "absolute",
          top: 0,
          left: 0,
          width: "100%",
          height: "100%",
          clipPath: afterClip,
          overflow: "hidden",
        }}
      >
        <Img
          src={bottomMedia}
          style={{
            width: "100%",
            height: "100%",
            objectFit: "cover",
            transform: `scale(${kenBurnsBottom})`,
            transformOrigin: "center center",
          }}
        />
        {bottomLabel && (
          <SplitLabel
            text={bottomLabel}
            color={labelColor}
            frame={frame}
            fps={fps}
            delay={25}
            position={isHorizontal ? "bottom" : "right"}
          />
        )}
      </div>

      {/* Divider line */}
      <div style={{ ...dividerStyle, opacity: dividerOpacity }} />
    </AbsoluteFill>
  );
};
