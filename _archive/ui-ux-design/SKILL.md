---
name: ui-ux-design
description: UI/UX design capabilities — landing pages, product page layouts, wireframes, user flow optimization
version: 1.0.0
agent: daedalus
---

# UI/UX Design Skill

Enables Daedalus (Art Director) to create UI/UX design specs and visual concepts for web and mobile.

## Capabilities

### 1. Landing Page Design
Create high-converting landing page layouts:

**Above the fold (hero section):**
- Hero image/video (full width or split layout)
- Headline (max 10 words, benefit-driven)
- Sub-headline (max 20 words, clarifying)
- Primary CTA button (brand accent color, high contrast)
- Social proof element (reviews, badges, numbers)

**Below the fold sections:**
- Problem/Solution (PAS framework)
- Product showcase (features + benefits)
- Social proof (testimonials, reviews, UGC)
- FAQ accordion
- Final CTA block
- Footer with trust signals

### 2. Product Page Layout
Optimized e-commerce product page structure:
- Product image gallery (main + 4-6 thumbnails)
- Product title + price (above fold)
- Add to cart (sticky on mobile)
- Key benefits (3-5 icon + text blocks)
- Description tabs (details, ingredients, reviews)
- Related products carousel
- Mobile-first responsive considerations

### 3. Wireframe Spec Format
When producing wireframes, output as structured spec:

```json
{
  "page": "landing-page",
  "brand": "{brand}",
  "sections": [
    {
      "name": "hero",
      "layout": "split-left-text-right-image",
      "elements": [
        {"type": "headline", "content": "...", "font": "DNA.typography.heading", "size": "48px"},
        {"type": "subheadline", "content": "...", "font": "DNA.typography.body", "size": "18px"},
        {"type": "cta", "content": "Shop Now", "color": "DNA.colors.accent", "style": "rounded-pill"},
        {"type": "image", "source": "hero-product-shot", "position": "right-50%"}
      ]
    }
  ]
}
```

### 4. Mobile-First Principles
- Touch targets: minimum 44x44px
- Text: minimum 16px body, 24px headings
- CTA buttons: full width on mobile, min height 48px
- Spacing: 16px minimum between elements
- Loading: lazy load images below fold
- Navigation: hamburger menu with brand icon

### 5. Shopee/Lazada Store Design
Platform-specific store page optimization:
- Store banner: 1200x400 (Lazada) / 1200x300 (Shopee)
- Category banners: 600x200
- Product thumbnail: 800x800 (square, white background, product centered)
- Store decoration: themed for campaigns, seasonal updates

## Visual Mockup Generation
Use NanoBanana to generate visual mockups:

```
Modern e-commerce landing page design for {brand},
{DNA.visual.style} aesthetic, {DNA.visual.colors.background} background,
hero section with product photography and bold headline,
clean minimal layout, {DNA.visual.typography.body} font,
mobile responsive preview, UI/UX design mockup,
professional web design presentation
```

## Integration
- Read Brand DNA for all visual decisions
- Coordinate with Apollo for copy elements in layouts
- Store approved layouts in seed bank
- Tag with `ui-ux,{page-type},{brand}`
