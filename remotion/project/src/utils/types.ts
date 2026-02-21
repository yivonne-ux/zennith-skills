/**
 * Shared types for GAIA MotionKit compositions.
 */

/** Brand color palette — matches Brand DNA structure */
export type BrandColors = {
  primary: string;
  secondary: string;
  background: string;
  accent: string;
};

/** Default GAIA Eats brand colors (from DNA.json) */
export const DEFAULT_BRAND_COLORS: BrandColors = {
  primary: "#8FBC8F",
  secondary: "#DAA520",
  background: "#FFFDD0",
  accent: "#2E8B57",
};

/** Caption token for word-by-word highlighting */
export type CaptionToken = {
  text: string;
  fromMs: number;
  toMs: number;
};

/** Caption page — a group of tokens shown together */
export type CaptionPage = {
  startMs: number;
  tokens: CaptionToken[];
};

/** Caption style for AnimatedCaptions */
export type CaptionStyle = "tiktok" | "karaoke" | "bounce";

/** Caption position */
export type CaptionPosition = "top" | "center" | "bottom";

/** Chart data point */
export type DataPoint = {
  label: string;
  value: number;
  color?: string;
};

/** Chart type */
export type ChartType = "bar" | "line";

/** Product feature for showcase */
export type ProductFeature = {
  text: string;
  icon?: string;
};
