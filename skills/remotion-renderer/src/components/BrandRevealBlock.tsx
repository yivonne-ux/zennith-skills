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
  FONT_BODY,
} from "../fonts";

ensureBrandFonts();

const MIRRA_SALMON = "#F7AB9F";
const NEAR_BLACK = "#252525";
const WARM_CREAM = "#FFF9EB";

type RevealStyle = "zoom_burst" | "cascade_in" | "orbit";

interface BrandRevealBlockProps {
  logo: string;
  productImages?: string[];
  tagline?: string;
  bgColor?: string;
  durationInFrames: number;
  revealStyle?: RevealStyle;
}

const CANVAS_W = 1080;
const CANVAS_H = 1920;
const CENTER_X = CANVAS_W / 2;
const CENTER_Y = CANVAS_H / 2;

/**
 * zoom_burst: logo scales up with spring overshoot, products burst outward.
 */
const ZoomBurstLayout: React.FC<{
  logo: string;
  products: string[];
  frame: number;
  fps: number;
  durationInFrames: number;
  tagline?: string;
}> = ({ logo, products, frame, fps, durationInFrames, tagline }) => {
  // Logo entrance: big spring overshoot
  const logoSpring = spring({
    frame,
    fps,
    config: { damping: 10, stiffness: 100, mass: 0.8 },
    delay: 0,
  });

  const logoScale = interpolate(logoSpring, [0, 1], [0, 1], { extrapolateRight: "clamp" });
  const logoOpacity = Math.min(logoSpring * 3, 1);

  // Product burst: starts after logo settles (~frame 15)
  const burstDelay = 15;
  const burstRadius = 380;

  return (
    <>
      {/* Product images burst outward */}
      {products.map((src, i) => {
        const angle = (i / Math.max(products.length, 1)) * Math.PI * 2 - Math.PI / 2;
        const targetX = CENTER_X + Math.cos(angle) * burstRadius - 80;
        const targetY = CENTER_Y + Math.sin(angle) * burstRadius - 80;

        const productSpring = spring({
          frame,
          fps,
          config: { damping: 12, stiffness: 80, mass: 0.6 },
          delay: burstDelay + i * 4,
        });

        const x = interpolate(productSpring, [0, 1], [CENTER_X - 80, targetX], {
          extrapolateRight: "clamp",
        });
        const y = interpolate(productSpring, [0, 1], [CENTER_Y - 80, targetY], {
          extrapolateRight: "clamp",
        });
        const scale = interpolate(productSpring, [0, 1], [0.2, 1], {
          extrapolateRight: "clamp",
        });
        const rotation = interpolate(productSpring, [0, 1], [180, 0], {
          extrapolateRight: "clamp",
        });

        // Subtle float after settling
        const floatY = Math.sin(frame * 0.04 + i * 1.5) * 6;

        return (
          <div
            key={i}
            style={{
              position: "absolute",
              left: x,
              top: y + floatY,
              width: 160,
              height: 160,
              borderRadius: 20,
              overflow: "hidden",
              transform: `scale(${scale}) rotate(${rotation}deg)`,
              opacity: productSpring,
              boxShadow: "0 8px 32px rgba(0,0,0,0.3)",
            }}
          >
            <Img
              src={src}
              style={{
                width: "100%",
                height: "100%",
                objectFit: "cover",
              }}
            />
          </div>
        );
      })}

      {/* Logo center */}
      <div
        style={{
          position: "absolute",
          left: CENTER_X - 120,
          top: CENTER_Y - 120,
          width: 240,
          height: 240,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          transform: `scale(${logoScale})`,
          opacity: logoOpacity,
        }}
      >
        <Img
          src={logo}
          style={{
            maxWidth: "100%",
            maxHeight: "100%",
            objectFit: "contain",
          }}
        />
      </div>

      {/* Tagline */}
      {tagline && (
        <TaglineText
          text={tagline}
          frame={frame}
          fps={fps}
          durationInFrames={durationInFrames}
          delay={burstDelay + products.length * 4 + 8}
        />
      )}
    </>
  );
};

/**
 * cascade_in: products waterfall from top, then logo fades in center.
 */
const CascadeLayout: React.FC<{
  logo: string;
  products: string[];
  frame: number;
  fps: number;
  durationInFrames: number;
  tagline?: string;
}> = ({ logo, products, frame, fps, durationInFrames, tagline }) => {
  // Products cascade in from top
  const columns = Math.min(products.length, 3);
  const cellSize = 200;
  const gap = 20;
  const totalW = columns * cellSize + (columns - 1) * gap;
  const startX = (CANVAS_W - totalW) / 2;

  const logoDelay = products.length * 6 + 10;

  // Logo fade in after products settle
  const logoFade = spring({
    frame,
    fps,
    config: { damping: 20, stiffness: 60 },
    delay: logoDelay,
  });

  return (
    <>
      {/* Cascading products */}
      {products.map((src, i) => {
        const col = i % columns;
        const row = Math.floor(i / columns);
        const targetX = startX + col * (cellSize + gap);
        const targetY = 300 + row * (cellSize + gap);

        const cascadeSpring = spring({
          frame,
          fps,
          config: { damping: 15, stiffness: 70 },
          delay: i * 6,
        });

        const y = interpolate(cascadeSpring, [0, 1], [-300, targetY], {
          extrapolateRight: "clamp",
        });
        const opacity = cascadeSpring;
        const rotation = interpolate(cascadeSpring, [0, 1], [-15 + i * 5, 0], {
          extrapolateRight: "clamp",
        });

        return (
          <div
            key={i}
            style={{
              position: "absolute",
              left: targetX,
              top: y,
              width: cellSize,
              height: cellSize,
              borderRadius: 16,
              overflow: "hidden",
              opacity,
              transform: `rotate(${rotation}deg)`,
              boxShadow: "0 6px 24px rgba(0,0,0,0.25)",
            }}
          >
            <Img
              src={src}
              style={{
                width: "100%",
                height: "100%",
                objectFit: "cover",
              }}
            />
          </div>
        );
      })}

      {/* Logo fades in center */}
      <div
        style={{
          position: "absolute",
          left: CENTER_X - 130,
          top: CENTER_Y + 100,
          width: 260,
          height: 260,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          opacity: logoFade,
          transform: `scale(${interpolate(logoFade, [0, 1], [0.8, 1], { extrapolateRight: "clamp" })})`,
        }}
      >
        <Img
          src={logo}
          style={{
            maxWidth: "100%",
            maxHeight: "100%",
            objectFit: "contain",
          }}
        />
      </div>

      {/* Tagline */}
      {tagline && (
        <TaglineText
          text={tagline}
          frame={frame}
          fps={fps}
          durationInFrames={durationInFrames}
          delay={logoDelay + 8}
        />
      )}
    </>
  );
};

/**
 * orbit: products orbit around centered logo.
 */
const OrbitLayout: React.FC<{
  logo: string;
  products: string[];
  frame: number;
  fps: number;
  durationInFrames: number;
  tagline?: string;
}> = ({ logo, products, frame, fps, durationInFrames, tagline }) => {
  // Logo entrance
  const logoSpring = spring({
    frame,
    fps,
    config: { damping: 16, stiffness: 80 },
    delay: 0,
  });

  const orbitRadius = 320;
  const orbitSpeed = 0.015; // radians per frame

  return (
    <>
      {/* Orbiting products */}
      {products.map((src, i) => {
        const baseAngle = (i / Math.max(products.length, 1)) * Math.PI * 2;
        const currentAngle = baseAngle + frame * orbitSpeed;

        // Entrance: products appear one by one
        const entranceSpring = spring({
          frame,
          fps,
          config: { damping: 14, stiffness: 100 },
          delay: 5 + i * 5,
        });

        const x = CENTER_X + Math.cos(currentAngle) * orbitRadius - 70;
        const y = CENTER_Y + Math.sin(currentAngle) * orbitRadius * 0.6 - 70; // elliptical orbit
        const scale = interpolate(
          Math.sin(currentAngle),
          [-1, 1],
          [0.7, 1.0]
        );
        const zIndex = Math.sin(currentAngle) > 0 ? 3 : 1;

        return (
          <div
            key={i}
            style={{
              position: "absolute",
              left: x,
              top: y,
              width: 140,
              height: 140,
              borderRadius: 70,
              overflow: "hidden",
              transform: `scale(${scale * entranceSpring})`,
              opacity: entranceSpring,
              zIndex,
              boxShadow: "0 4px 20px rgba(0,0,0,0.3)",
              border: `3px solid ${WARM_CREAM}40`,
            }}
          >
            <Img
              src={src}
              style={{
                width: "100%",
                height: "100%",
                objectFit: "cover",
              }}
            />
          </div>
        );
      })}

      {/* Center logo */}
      <div
        style={{
          position: "absolute",
          left: CENTER_X - 100,
          top: CENTER_Y - 100,
          width: 200,
          height: 200,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          opacity: logoSpring,
          transform: `scale(${interpolate(logoSpring, [0, 1], [0.3, 1], { extrapolateRight: "clamp" })})`,
          zIndex: 2,
        }}
      >
        <Img
          src={logo}
          style={{
            maxWidth: "100%",
            maxHeight: "100%",
            objectFit: "contain",
          }}
        />
      </div>

      {/* Tagline */}
      {tagline && (
        <TaglineText
          text={tagline}
          frame={frame}
          fps={fps}
          durationInFrames={durationInFrames}
          delay={5 + products.length * 5 + 10}
        />
      )}
    </>
  );
};

/**
 * Shared tagline text with typewriter/fade entrance.
 */
const TaglineText: React.FC<{
  text: string;
  frame: number;
  fps: number;
  durationInFrames: number;
  delay: number;
}> = ({ text, frame, fps, delay }) => {
  const taglineSpring = spring({
    frame,
    fps,
    config: { damping: 20, stiffness: 60 },
    delay,
  });

  const ty = interpolate(taglineSpring, [0, 1], [30, 0], { extrapolateRight: "clamp" });

  return (
    <div
      style={{
        position: "absolute",
        bottom: 280,
        left: 60,
        right: 60,
        textAlign: "center",
        opacity: taglineSpring,
        transform: `translateY(${ty}px)`,
        zIndex: 10,
      }}
    >
      <span
        style={{
          fontFamily: FONT_BODY,
          fontWeight: 500,
          fontSize: 40,
          color: NEAR_BLACK,
          lineHeight: 1.4,
          letterSpacing: 1,
        }}
      >
        {text}
      </span>
    </div>
  );
};

export const BrandRevealBlock: React.FC<BrandRevealBlockProps> = ({
  logo,
  productImages,
  tagline,
  bgColor = MIRRA_SALMON,
  durationInFrames,
  revealStyle = "zoom_burst",
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const products = productImages || [];

  // Background gradient: bgColor to slightly darker version
  const bgGradient = `radial-gradient(ellipse at center, ${bgColor}, ${bgColor}DD)`;

  const sharedProps = {
    logo,
    products,
    frame,
    fps,
    durationInFrames,
    tagline,
  };

  return (
    <AbsoluteFill
      style={{
        background: bgGradient,
        overflow: "hidden",
      }}
    >
      {/* Subtle animated background circles */}
      {[0, 1, 2].map((i) => {
        const circleScale = interpolate(
          Math.sin(frame * 0.02 + i * 2),
          [-1, 1],
          [0.8, 1.2]
        );
        const circleOpacity = 0.06;
        return (
          <div
            key={`bg-circle-${i}`}
            style={{
              position: "absolute",
              left: CENTER_X - 300 + i * 150,
              top: CENTER_Y - 300 + i * 100,
              width: 600,
              height: 600,
              borderRadius: "50%",
              backgroundColor: WARM_CREAM,
              opacity: circleOpacity,
              transform: `scale(${circleScale})`,
            }}
          />
        );
      })}

      {revealStyle === "zoom_burst" && <ZoomBurstLayout {...sharedProps} />}
      {revealStyle === "cascade_in" && <CascadeLayout {...sharedProps} />}
      {revealStyle === "orbit" && <OrbitLayout {...sharedProps} />}
    </AbsoluteFill>
  );
};
