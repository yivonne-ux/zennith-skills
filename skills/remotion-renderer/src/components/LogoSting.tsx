import React from "react";
import { AbsoluteFill, OffthreadVideo, staticFile } from "remotion";

interface LogoStingProps {
  /** Video file for the logo sting — defaults to Mirra-Logo Ending.mp4 */
  video?: string;
  durationInFrames: number;
}

/**
 * Logo sting closer — plays the actual brand ending video.
 * For Mirra: uses Mirra-Logo Ending.mp4 (pre-made animated logo).
 */
export const LogoSting: React.FC<LogoStingProps> = ({
  video = "mirra-logo-ending.mp4",
  durationInFrames,
}) => {
  const videoSrc = video.startsWith("http") ? video : staticFile(video);

  return (
    <AbsoluteFill style={{ backgroundColor: "#ffffff" }}>
      <OffthreadVideo
        src={videoSrc}
        style={{
          width: "100%",
          height: "100%",
          objectFit: "cover",
        }}
      />
    </AbsoluteFill>
  );
};
