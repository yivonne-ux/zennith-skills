import { staticFile } from "remotion";

/**
 * Brand font loader — registers @font-face for Mirra brand fonts.
 * Call once at module level in components that need brand typography.
 *
 * EN Headings: Awesome Serif Bold
 * EN Body: Mabry Pro Medium (semibold equivalent)
 * CN Headings: Source Han Serif CN Bold
 * CN Body: FZZHXL (方正正中黑简体)
 */

let fontsLoaded = false;

export function ensureBrandFonts(): void {
  if (fontsLoaded || typeof document === "undefined") return;
  fontsLoaded = true;

  const fonts: Array<{ family: string; src: string; weight?: string }> = [
    {
      family: "Awesome Serif",
      src: staticFile("fonts/AwesomeSerif-Bold.otf"),
      weight: "700",
    },
    {
      family: "Mabry Pro",
      src: staticFile("fonts/MabryPro-Medium.ttf"),
      weight: "500",
    },
    {
      family: "Mabry Pro",
      src: staticFile("fonts/MabryPro-Bold.ttf"),
      weight: "700",
    },
    {
      family: "Source Han Serif CN",
      src: staticFile("fonts/SourceHanSerifCN-Bold.otf"),
      weight: "700",
    },
    {
      family: "FZZHXL",
      src: staticFile("fonts/FZZHXL.ttf"),
      weight: "400",
    },
    {
      family: "FZZCHJW",
      src: staticFile("fonts/FZZCHJW.TTF"),
      weight: "400",
    },
  ];

  for (const f of fonts) {
    const face = new FontFace(f.family, `url("${f.src}")`, {
      weight: f.weight || "400",
      style: "normal",
    });
    face.load().then((loaded) => {
      (document.fonts as any).add(loaded);
    });
  }
}

// Font family stacks
// EN: Awesome Serif for headings, Mabry Pro for body
// CN: Source Han Serif CN for headings, FZZHXL for body
export const FONT_HEADING_EN = "'Awesome Serif', serif";
export const FONT_BODY_EN = "'Mabry Pro', sans-serif";
export const FONT_HEADING_CN = "'Source Han Serif CN', serif";
export const FONT_BODY_CN = "'FZZHXL', sans-serif";

// Combined stacks (tries EN first, falls back to CN for Chinese chars)
export const FONT_HEADING = `'Awesome Serif', 'Source Han Serif CN', serif`;
export const FONT_BODY = `'Mabry Pro', 'FZZHXL', sans-serif`;
// Jianying subtitle font — matches real Jianying project captions
export const FONT_SUBTITLE_CN = `'FZZCHJW', 'FZZHXL', sans-serif`;
