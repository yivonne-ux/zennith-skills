# Jade Oracle — Shopify Theme Merge Guide

> Best of both worlds: our design quality + the live site's conversion power.
> For Jenn/Tricia to implement in the existing "Jade Oracle CRO" Shopify theme.

---

## WHAT TO KEEP FROM THE LIVE SITE (conversion elements)
These are PROVEN — don't remove them:

1. **Strikethrough pricing** — $69→$29, $129→$49. Price anchoring works.
2. **Exit-intent popup** — "15% off + free mini birth chart." Keep Klaviyo integration.
3. **Live purchase toast** — "Sarah K. from London just purchased." Social proof.
4. **Countdown timer** — "Your Celestial Window." Creates urgency.
5. **Money-back guarantee** on every product card
6. **Sticky mobile CTA** — persistent bottom bar
7. **Announcement bar** — rotating offers
8. **GoAffPro** affiliate program
9. **97.3% satisfaction + 2,847+ readings** — specific numbers
10. **Sample reading preview** — shows actual QMDJ output language

## WHAT TO ADD FROM OUR DESIGN (quality elements)

### 1. Typography Upgrade
**Replace** Cormorant with **Instrument Serif** for display.
**Keep** Jost for body (or swap to DM Sans 300).
- Add to theme: `@import url('https://fonts.googleapis.com/css2?family=Instrument+Serif:ital@0;1')`
- More distinctive, less overused than Cormorant

### 2. Color Palette Upgrade
**Replace** pure black (#10101a) with **warm walnut (#2A2420)**
- Current: cold, void-like black
- New: warm dark wood — same depth, more warmth
- Background: `#2A2420` (primary), `#352F28` (cards), `#3A342C` (mid)
- Keep: Gold #c9a84c, Jade #1E6B4E, Cream #e8e0d4

### 3. Organic Motif PNGs (transparent backgrounds)
Upload these to Shopify Files → use as section backgrounds/dividers:
- `motif-fern.png` — fern + jade disc + crescent moon (between hero and about)
- `motif-lotus.png` — lotus flower + flowing water (before pricing)
- `motif-koi.png` — two koi fish + constellations (love/relationship theme)
- `badge-disc.png` — jade bi disc (brand mark)

**CSS for motifs:**
```css
.motif-section {
  position: relative;
  overflow: visible;
}
.motif-section img {
  position: absolute;
  width: 500px;
  opacity: 0.08;
  pointer-events: none;
  z-index: 0;
}
```

### 4. NANO Gold Coin Icons for Reading Types
Replace text/emoji icons with these gold medallion PNGs:
- `icon-question.png` — 问 (First Question $1)
- `icon-moment.png` — 时 (Quick Insight / Love Reading)
- `icon-destiny.png` — 命 (Full Destiny Reading)
- `icon-year.png` — 年 (Year Ahead — NEW tier at $497)

Display at **100-120px** in product cards. No circular crop. No borders.

### 5. Scroll Animations
Add this CSS for scroll-driven reveal (no JS needed):
```css
.reveal {
  opacity: 0;
  transform: translateY(40px);
  animation: revealUp linear both;
  animation-timeline: view();
  animation-range: entry 5% cover 28%;
}
@keyframes revealUp {
  to { opacity: 1; transform: translateY(0); }
}
```
Add class `reveal` to sections for scroll-triggered entrance.

### 6. Button Sweep Effect
Replace hover color-change with sweep-fill:
```css
.btn-primary {
  position: relative;
  overflow: hidden;
  z-index: 0;
}
.btn-primary::before {
  content: '';
  position: absolute;
  inset: 0;
  background: var(--color-jade-hover);
  transform: translateY(100%);
  transition: transform 0.45s cubic-bezier(0.65, 0, 0.35, 1);
  z-index: -1;
}
.btn-primary:hover::before {
  transform: translateY(0);
}
```

### 7. Gold Shimmer Text
For headings and Chinese characters:
```css
.gold-shimmer {
  background: linear-gradient(135deg, #DCCA7A 0%, #B8965A 35%, #8B6F3A 55%, #DCCA7A 75%, #B8965A 100%);
  background-size: 200% auto;
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  animation: goldShift 5s ease infinite;
}
@keyframes goldShift {
  0% { background-position: 0% center; }
  50% { background-position: 100% center; }
  100% { background-position: 0% center; }
}
```

### 8. Film Grain Overlay
```css
body::after {
  content: '';
  position: fixed;
  inset: 0;
  pointer-events: none;
  z-index: 9998;
  opacity: 0.02;
  background-image: url("data:image/svg+xml,..."); /* noise SVG */
}
```

### 9. Hero Upgrade — Split Layout
- **Left:** Text + CTA + trust line
- **Right:** Jade's face at 85% brightness with soft-edge blend
- NOT darkened face behind text overlay
- Jade should be WARM and VISIBLE

### 10. Jade's Real Photos
Replace "Luna Solaris" character images with face-locked Jade photos from:
`~/Downloads/jade-face-body-lock/_organized/04-ig-lifestyle-LOCKED/`

### 11. Trust Badge Upgrade
Replace text payment badges with `trust-pay.png` — unified gold-tone strip.
Replace unicode guarantee with `badge-guarantee.png` — gold shield.

### 12. Progress Bar
```css
.progress-bar {
  position: fixed;
  top: 0; left: 0;
  width: 100%; height: 2px;
  background: var(--color-jade);
  transform-origin: left;
  z-index: 101;
  animation: progressGrow linear;
  animation-timeline: scroll(root);
}
@keyframes progressGrow {
  from { transform: scaleX(0); }
  to { transform: scaleX(1); }
}
```

---

## PRICING STRUCTURE RECOMMENDATION

| Tier | Name | Price | Anchored From | Discount |
|------|------|-------|---------------|----------|
| Entry | First Question | $1 | — | "start here" tag |
| Core | Love & Relationship | $29 | ~~$69~~ | 58% off |
| Premium | Full Destiny Reading | $49 | ~~$129~~ | 62% off, "most chosen" |
| VIP | Year Ahead | $497 | — | NEW tier, "12 months" |

Keep the strikethrough pricing from the live site — it's proven conversion psychology.
Add the $497 Year Ahead as a new anchor tier.

---

## SECTION ORDER (ACCA optimized)

1. Announcement bar (rotating offers)
2. Hero (split layout: text left, Jade right)
3. Social proof bar (2,847+ readings, 97.3%, 24h, 4,000 years)
4. Marquee strip (love · career · timing · qi men dun jia · tarot)
5. Intro text (highlight-on-scroll)
6. Fern motif divider
7. About Jade (with floating fern bg accent)
8. Quote (jade green bg, gold corners)
9. Gallery (4 images, hover reveals)
10. Stats bar (gold shimmer numbers)
11. The System (QMDJ + tarot + astrology explanation)
12. Lotus motif divider
13. Typographic moment ("It has time.")
14. Video (Jade speaking)
15. Testimonials (4 cards, directly before pricing)
16. CTA → "see reading options"
17. How It Works (4 steps + reading PDF preview)
18. Koi motif divider
19. Packages (4 tiers with gold coin icons, strikethrough pricing)
20. Guarantee badge + scarcity + payment badges
21. Countdown timer ("Your Celestial Window")
22. Live purchase toast (persistent)
23. Quote (cream bg variant)
24. Reading preview ("What you receive")
25. FAQ (5-6 questions)
26. CTA → "start my first reading"
27. Oracle deck product
28. Parallax image break
29. Email capture (Klaviyo)
30. Telegram CTA
31. Jade disc badge
32. Connect + social links
33. Footer
34. Sticky mobile CTA
35. Exit-intent popup (15% off)

---

## FILES TO UPLOAD TO SHOPIFY

### Images (upload to Settings → Files)
- `motif-fern.png` (transparent)
- `motif-lotus.png` (transparent)
- `motif-koi.png` (transparent)
- `badge-disc.png` (transparent)
- `badge-guarantee.png` (transparent)
- `icon-question.png` (transparent)
- `icon-moment.png` (transparent)
- `icon-destiny.png` (transparent)
- `icon-year.png` (transparent)
- `trust-pay.png` (transparent)
- All Jade face-locked photos

### CSS (add to theme.css or assets/)
- Scroll animations
- Gold shimmer effect
- Button sweep effect
- Film grain overlay
- Progress bar
- Warm walnut color variables
- Instrument Serif import

### JS (add to theme.js or inline)
- Custom cursor (desktop only)
- Magnetic buttons
- Card tilt effect
- Scroll reveal fallback for older browsers

---

## WHAT NOT TO CHANGE ON LIVE SITE
- Shopify checkout flow — it works
- Klaviyo integration — it works
- GoAffPro — it works
- Live toast notifications — they work
- Exit-intent popup — it works
- Product URLs and SEO — they're indexed
- Money-back guarantee language — it converts

---

*This guide is the bridge between our design work and the live Shopify store.*
*Give this to Jenn + Tricia. They implement in the Shopify theme editor.*
