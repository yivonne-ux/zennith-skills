/**
 * Font loading for GAIA MotionKit.
 * Uses Nunito (heading) and Open Sans (body) matching GAIA brand DNA typography.
 */
import { loadFont as loadNunito } from "@remotion/google-fonts/Nunito";
import { loadFont as loadOpenSans } from "@remotion/google-fonts/OpenSans";

const nunito = loadNunito("normal", {
  weights: ["400", "600", "700", "800"],
  subsets: ["latin"],
});

const openSans = loadOpenSans("normal", {
  weights: ["400", "600", "700"],
  subsets: ["latin"],
});

export const FONT_HEADING = nunito.fontFamily;
export const FONT_BODY = openSans.fontFamily;
