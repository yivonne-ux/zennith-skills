export type BlockType =
  | "kol_video" | "broll_video" | "product_image" | "text_card"  // legacy
  | "usage_scene" | "pain_scenario" | "positive_reactions"
  | "social_proof_grid" | "product_showcase" | "product_collage"
  | "results_transform" | "behind_the_scenes" | "process_method"
  | "premium_materials" | "production_line" | "raw_reviews"
  | "receive_scene" | "unbox_reveal" | "before_after"
  | "lifestyle_shot" | "comparison_demo"
  | "packaging_shot" | "bundle_group" | "promo_visual" | "end_card"
  | "logo_sting" | "customer_screenshot" | "menu_card"
  | "food_collage" | "kinetic_text" | "split_screen" | "brand_reveal";

export type AidaPhase = "attention" | "interest" | "desire" | "action";
export type TextPosition = "lower_third" | "center" | "top";
export type TextStyle = "bold" | "normal" | "stat_card";

/** Kinetic animation mode for emphasis words */
export type KineticMode = "scale_pop" | "bounce" | "blur_reveal" | "slide_up" | "drop" | "glow_pulse";

/** Emphasis segment within text — rendered larger and in brand color */
export interface EmphasisSegment {
  text: string;
  color?: string;        // default: Mirra pink #E8788A
  scale?: number;        // default: 2.0 (2x the base font size)
  kinetic?: KineticMode; // optional spring-based animation on reveal
}

export interface TextOverlayConfig {
  text: string;
  style: TextStyle;
  position: TextPosition;
  /** Words to emphasize — rendered in brand color at larger size */
  emphasis?: EmphasisSegment[];
  /** Override text color */
  color?: string;
  /** Show text with outline for readability on busy backgrounds */
  outline?: boolean;
}

export interface BlockConfig {
  id: string;
  type: BlockType;
  aida_phase?: AidaPhase;
  block_code?: string;
  file: string;         // file:// URL or HTTPS URL
  duration_s: number;
  start_s: number;
  text_overlay: TextOverlayConfig | null;
}

export interface BrandWatermarkConfig {
  text: string;          // e.g. "MIRRA"
  fontFamily?: string;   // default: serif
  color?: string;        // default: white
  opacity?: number;      // default: 0.85
}

export interface EndCardConfig {
  headline: string;           // e.g. "Take the First Step"
  subHeadline?: string;       // e.g. "Start your success story now"
  ctaText: string;            // e.g. "PM US NOW"
  bgColor?: string;           // default: #E8788A (Mirra pink)
  productImages?: string[];   // URLs for corner product photos
}

export interface UGCProps {
  variant_id: string;
  fps: number;
  blocks: BlockConfig[];
  voiceover: string | null;
  voiceover_volume: number;
  bgm: string | null;
  bgm_volume: number;
  total_duration_s: number;
  width: number;
  height: number;
  /** Brand watermark shown on every frame */
  watermark?: BrandWatermarkConfig | null;
}
