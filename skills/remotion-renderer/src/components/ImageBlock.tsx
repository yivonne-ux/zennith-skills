import React from "react";
import { AbsoluteFill, Img, interpolate, useCurrentFrame } from "remotion";

interface ImageBlockProps {
  src: string;
  durationInFrames: number;
}

export const ImageBlock: React.FC<ImageBlockProps> = ({ src, durationInFrames }) => {
  const frame = useCurrentFrame();

  // Subtle Ken Burns zoom: 1.0 → 1.05 over the block duration
  const scale = interpolate(frame, [0, durationInFrames], [1.0, 1.05], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  return (
    <AbsoluteFill style={{ overflow: "hidden", backgroundColor: "#000" }}>
      <Img
        src={src}
        style={{
          width: "100%",
          height: "100%",
          objectFit: "cover",
          transform: `scale(${scale})`,
          transformOrigin: "center center",
        }}
      />
    </AbsoluteFill>
  );
};
