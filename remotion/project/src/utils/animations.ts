/**
 * Shared animation helpers for GAIA MotionKit.
 * All animations are driven by frame — no CSS transitions or keyframes.
 */
import { interpolate, Easing } from "remotion";

/** Fade in over a given number of frames, starting at startFrame */
export function fadeIn(
  frame: number,
  startFrame: number,
  durationFrames: number,
): number {
  return interpolate(frame, [startFrame, startFrame + durationFrames], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.out(Easing.quad),
  });
}

/** Fade out over a given number of frames, starting at startFrame */
export function fadeOut(
  frame: number,
  startFrame: number,
  durationFrames: number,
): number {
  return interpolate(frame, [startFrame, startFrame + durationFrames], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.in(Easing.quad),
  });
}

/** Slide in from a direction over a given number of frames */
export function slideIn(
  frame: number,
  startFrame: number,
  durationFrames: number,
  distance: number,
  direction: "left" | "right" | "up" | "down" = "left",
): { x: number; y: number } {
  const progress = interpolate(
    frame,
    [startFrame, startFrame + durationFrames],
    [0, 1],
    {
      extrapolateLeft: "clamp",
      extrapolateRight: "clamp",
      easing: Easing.out(Easing.quad),
    },
  );

  switch (direction) {
    case "left":
      return { x: interpolate(progress, [0, 1], [-distance, 0]), y: 0 };
    case "right":
      return { x: interpolate(progress, [0, 1], [distance, 0]), y: 0 };
    case "up":
      return { x: 0, y: interpolate(progress, [0, 1], [-distance, 0]) };
    case "down":
      return { x: 0, y: interpolate(progress, [0, 1], [distance, 0]) };
  }
}

/** Ken Burns zoom — smooth scale from startScale to endScale */
export function kenBurnsZoom(
  frame: number,
  totalFrames: number,
  startScale: number = 1.0,
  endScale: number = 1.15,
): number {
  return interpolate(frame, [0, totalFrames], [startScale, endScale], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.inOut(Easing.sin),
  });
}

/** Stagger delay for items in a list */
export function staggerDelay(index: number, delayPerItem: number): number {
  return index * delayPerItem;
}
