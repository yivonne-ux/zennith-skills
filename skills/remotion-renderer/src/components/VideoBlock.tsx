import React from "react";
import {
  AbsoluteFill,
  OffthreadVideo,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { noise2D } from "@remotion/noise";

type KenBurnsPreset = "none" | "slow_zoom_in" | "slow_zoom_out" | "drift_right" | "drift_left";
interface VideoBlockProps {
  src: string;
  kenBurns?: KenBurnsPreset;
  colorGrade?: string; // Ignored — grading via FFmpeg pre-assembly (config/color_grades.json)
  muted?: boolean; // default: true — mute source audio (we use separate VO track)
  playbackRate?: number; // 0.3-2.0, default 1.0
  zoomPunch?: boolean; // Scale overshoot on block entry (1.12→1.0 spring)
  cameraShake?: boolean; // Organic shake on emphasis/impact moments
  cameraShakeIntensity?: number; // 1-5px displacement, default 2
  clipDurationFrames?: number; // Source clip duration in frames (for looping short clips)
}

function getKenBurnsTransform(preset: KenBurnsPreset, progress: number): string {
  switch (preset) {
    case "slow_zoom_in": {
      const scale = interpolate(progress, [0, 1], [1.0, 1.08], { extrapolateRight: "clamp" });
      return `scale(${scale})`;
    }
    case "slow_zoom_out": {
      const scale = interpolate(progress, [0, 1], [1.08, 1.0], { extrapolateRight: "clamp" });
      return `scale(${scale})`;
    }
    case "drift_right": {
      const scale = interpolate(progress, [0, 1], [1.04, 1.08], { extrapolateRight: "clamp" });
      const tx = interpolate(progress, [0, 1], [0, -20], { extrapolateRight: "clamp" });
      return `scale(${scale}) translateX(${tx}px)`;
    }
    case "drift_left": {
      const scale = interpolate(progress, [0, 1], [1.04, 1.08], { extrapolateRight: "clamp" });
      const tx = interpolate(progress, [0, 1], [0, 20], { extrapolateRight: "clamp" });
      return `scale(${scale}) translateX(${tx}px)`;
    }
    default:
      return "none";
  }
}

export const VideoBlock: React.FC<VideoBlockProps> = ({
  src,
  kenBurns = "none",
  muted = true,
  playbackRate = 1.0,
  zoomPunch = false,
  cameraShake = false,
  cameraShakeIntensity = 2,
  clipDurationFrames,
}) => {
  const frame = useCurrentFrame();
  const { durationInFrames, fps } = useVideoConfig();

  const progress = durationInFrames > 1
    ? interpolate(frame, [0, durationInFrames - 1], [0, 1], { extrapolateRight: "clamp" })
    : 0;

  // Ken Burns (continuous motion)
  const kenBurnsTransform = getKenBurnsTransform(kenBurns, progress);

  // Zoom punch: 12% scale overshoot on entry, spring back to 1.0 in ~8 frames.
  // Creates physical "weight" to scene transitions — top editors use this on every cut.
  let zoomPunchScale = 1.0;
  if (zoomPunch) {
    zoomPunchScale = spring({
      frame,
      fps,
      from: 1.12,
      to: 1.0,
      config: { damping: 8, stiffness: 200, mass: 0.6 },
    });
  }

  // Camera shake: organic noise-based displacement for impact moments.
  // Subtle (1-3px) — if the viewer consciously notices it, it's too much.
  // Decays over the block duration so it's strongest at entry.
  let shakeX = 0, shakeY = 0, shakeRot = 0;
  if (cameraShake) {
    const intensity = cameraShakeIntensity;
    // Decay shake over first 40% of block, then settle
    const decay = interpolate(frame, [0, durationInFrames * 0.4], [1, 0], {
      extrapolateLeft: "clamp", extrapolateRight: "clamp",
    });
    shakeX = noise2D("shakeX", frame * 0.15, 0) * intensity * decay;
    shakeY = noise2D("shakeY", 0, frame * 0.15) * intensity * decay;
    shakeRot = noise2D("shakeR", frame * 0.12, frame * 0.12) * (intensity * 0.3) * decay;
  }

  // Compose transforms: zoom punch (outer) → Ken Burns (continuous) → shake (micro)
  const transforms: string[] = [];
  if (zoomPunch && zoomPunchScale !== 1.0) {
    transforms.push(`scale(${zoomPunchScale})`);
  }
  if (kenBurnsTransform !== "none") {
    transforms.push(kenBurnsTransform);
  }
  if (cameraShake && (shakeX !== 0 || shakeY !== 0 || shakeRot !== 0)) {
    transforms.push(`translate(${shakeX.toFixed(1)}px, ${shakeY.toFixed(1)}px) rotate(${shakeRot.toFixed(2)}deg)`);
  }
  const combinedTransform = transforms.length > 0 ? transforms.join(" ") : undefined;

  // ARCH-4: Visual fill handles short clips upstream — no looping or freezing.
  // If a clip is shorter than the block, _visual_fill_blocks() in run_brief.py
  // splits the block into sub-blocks with additional library clips.
  // Remotion just plays each clip naturally within its Sequence duration.

  const videoEl = (
    <OffthreadVideo
      src={src}
      volume={muted ? 0 : 1}
      playbackRate={playbackRate}
      style={{
        width: "100%",
        height: "100%",
        objectFit: "cover",
        transform: combinedTransform,
      }}
    />
  );

  return (
    <AbsoluteFill>
      {videoEl}
    </AbsoluteFill>
  );
};
