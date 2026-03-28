/**
 * Brand Configuration for Zennith OS Remotion Renderer
 * Maps Zennith OS brands to visual presets (colors, fonts, assets).
 * Tricia's system was Mirra-only; this extends to all 14 brands.
 */

export interface BrandColors {
  primary: string;
  secondary: string;
  accent: string;
  background: string;
  text: string;
  textLight: string;
  salmon: string; // emphasis/highlight color
}

export interface BrandConfig {
  name: string;
  displayName: string;
  colors: BrandColors;
  watermarkImage?: string; // path in public/
  logoImage?: string;
  logoEndingVideo?: string;
  fontHeading: string;
  fontBody: string;
}

/** Default brand presets — extend as new brands onboard */
export const BRAND_PRESETS: Record<string, BrandConfig> = {
  mirra: {
    name: "mirra",
    displayName: "MIRRA",
    colors: {
      primary: "#E8788A",
      secondary: "#F7AB9F",
      accent: "#F7AB9F",
      background: "#FFF9EB",
      text: "#252525",
      textLight: "#FFFFFF",
      salmon: "#F7AB9F",
    },
    watermarkImage: "mirra-watermark.png",
    logoImage: "mirra-logo-black.png",
    logoEndingVideo: "mirra-logo-ending.mp4",
    fontHeading: "'Awesome Serif', 'Source Han Serif CN', serif",
    fontBody: "'Mabry Pro', 'FZZHXL', sans-serif",
  },
  "jade-oracle": {
    name: "jade-oracle",
    displayName: "JADE ORACLE",
    colors: {
      primary: "#00A86B",
      secondary: "#C9B037",
      accent: "#C9B037",
      background: "#1A1A1A",
      text: "#FFFFFF",
      textLight: "#E8E0D0",
      salmon: "#C9B037", // gold for Jade
    },
    fontHeading: "'Source Han Serif CN', serif",
    fontBody: "'Mabry Pro', sans-serif",
  },
  luna: {
    name: "luna",
    displayName: "LUNA SOLARIS",
    colors: {
      primary: "#D4A5A5",
      secondary: "#FAF8F5",
      accent: "#D4A5A5",
      background: "#FAF8F5",
      text: "#3A3A3A",
      textLight: "#FFFFFF",
      salmon: "#D4A5A5",
    },
    fontHeading: "'Awesome Serif', serif",
    fontBody: "'Mabry Pro', sans-serif",
  },
  "pinxin-vegan": {
    name: "pinxin-vegan",
    displayName: "PINXIN VEGAN",
    colors: {
      primary: "#4CAF50",
      secondary: "#F5F0E8",
      accent: "#4CAF50",
      background: "#F5F0E8",
      text: "#333333",
      textLight: "#FFFFFF",
      salmon: "#4CAF50",
    },
    fontHeading: "'Source Han Serif CN', serif",
    fontBody: "'Mabry Pro', sans-serif",
  },
  rasaya: {
    name: "rasaya",
    displayName: "RASAYA",
    colors: {
      primary: "#8B4513",
      secondary: "#DEB887",
      accent: "#DEB887",
      background: "#FFF8F0",
      text: "#3A2A1A",
      textLight: "#FFFFFF",
      salmon: "#DEB887",
    },
    fontHeading: "'Awesome Serif', serif",
    fontBody: "'Mabry Pro', sans-serif",
  },
};

/** Get brand config — falls back to Mirra defaults if brand not found */
export function getBrandConfig(brandName: string): BrandConfig {
  return BRAND_PRESETS[brandName] || BRAND_PRESETS["mirra"];
}
