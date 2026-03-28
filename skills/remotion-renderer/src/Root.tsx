import React from "react";
import { Composition } from "remotion";
import { UGCComposition, ugcSchema } from "./UGCComposition";
import { HelloWorld } from "./HelloWorld";

export const RemotionRoot: React.FC = () => {
  return (
    <>
      {/* Main UGC Ad Composition — multi-block AIDA video ads */}
      <Composition
        id="UGCComposition"
        component={UGCComposition}
        durationInFrames={1350}
        fps={30}
        width={1080}
        height={1920}
        schema={ugcSchema}
        defaultProps={{
          variant_id: "variant_a",
          fps: 30,
          blocks: [],
          voiceover: null,
          voiceover_volume: 1.0,
          bgm: null,
          bgm_volume: 0.2,
          bgm_fade_out_s: 2.0,
          total_duration_s: 45,
          width: 1080,
          height: 1920,
          watermark: null,
          enable_transitions: true,
          voiceover_start_s: 0,
          text_style_preset: "jianying_outline" as const,
        }}
        calculateMetadata={({ props }) => ({
          fps: props.fps,
          durationInFrames: Math.max(1, Math.ceil(props.total_duration_s * props.fps)),
          width: props.width,
          height: props.height,
        })}
      />

      {/* Test/Preview Composition */}
      <Composition
        id="HelloWorld"
        component={HelloWorld}
        durationInFrames={150}
        fps={30}
        width={1080}
        height={1080}
      />
    </>
  );
};
