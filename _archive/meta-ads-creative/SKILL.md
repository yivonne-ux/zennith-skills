# Meta Ads Creative Workflow — GAIA Brand
## Skill: meta-ads-creative-v1

---

## INPUT REQUIREMENTS

### Required Assets
| Asset | Format | Purpose |
|-------|--------|---------|
| **Product Hero** | PNG with transparency | Main product shot (Poon Choi pot) |
| **Logo** | PNG/SVG | Brand mark placement |
| **Safe Zone Guide** | PNG/JPG | Text placement reference |
| **Font Reference** | JPG/PNG | Typography style guide |
| **Background/Context** | Optional JPG | Scene setting |

### Required Copy (Per Ad)
- **Headline** (primary hook, 40 chars)
- **Body** (supporting text, 125 chars)
- **CTA** (call-to-action, 20 chars)
- **Offer mechanics** (RM values, conditions)

---

## STEP-BY-STEP PROCESS

### Step 1: Asset Preparation
```bash
# Download all assets to workspace
mkdir -p ~/.openclaw/workspace-artemis/ad-assets/

# Assets to fetch:
# 1. Poon Choi transparent: 2026%20poon%20choi%20edit-gravy3.png
# 2. Safe zone guide: 9-16%20ads%20safe%20zone.png
# 3. Font reference: font%20english.jpeg
# 4. Logo/masthead: 2026%20cny%20horse%20masthead.png
```

### Step 2: Safe Zone Analysis
- Load safe zone template (9:16)
- Identify: **Top safe zone** (headline), **Middle** (product), **Bottom** (CTA)
- Mark text exclusion zones (keep clear for Meta UI)

### Step 3: Design Composition (Tool: Canva/Figma/Photoshop)

**Canvas Setup:**
- Size: 1080 × 1920px (9:16)
- Color profile: sRGB
- DPI: 72 (web)

**Layer Stack (bottom to top):**
1. Background image/color gradient
2. Decorative elements (coins, lanterns, CNY motifs)
3. **Product layer** (Poon Choi pot) — center frame
4. Shadow/contact shadow for grounding
5. Glow/effects layer
6. **Text overlay group** (with safe zone compliance)
7. Logo placement
8. CTA button area

### Step 4: Typography Rules
- **Headline**: Bold, 60-80pt, all caps or title case
- **Body**: 40-50pt, readable weight
- **CTA**: Bold, 50-60pt, contrasting color
- **Font family**: Per brand guide (English reference provided)
- **Chinese**: Noto Sans SC or brand-specified

### Step 5: Export & QA
- Export PNG: 1080×1920, <30MB
- Verify text < 20% of image area (Meta rule)
- Check safe zone compliance
- Confirm all 6 ad variations

---

## CHAP GOH MEH 2026 — AD SPECIFICATIONS

### Ad 1: Phone Numbers (1/6/8)
| Element | Specification |
|---------|---------------|
| **Visual** | Poon Choi pot center, exploding "1 6 8" gold digits above |
| **Headline** | "LUCKY YOU! PHONE ENDS IN 1, 6, OR 8?" |
| **Body** | "Extra RM20 off instantly. This is your sign." |
| **CTA** | "CLAIM YOUR RM20 →" |
| **Color** | Deep crimson #8B0000, gold #FFD700 |

### Ad 2: Surnames
| Element | Specification |
|---------|---------------|
| **Visual** | Poon Choi pot, surnames 马/黄/王/翁 on ribbons |
| **Headline** | "SURNAMES MA, BEH, WONG, ONG — THIS IS FOR YOU" |
| **Body** | "Comment 'I want good luck' for RM20 bonus. First 100 only." |
| **CTA** | "COMMENT NOW →" |
| **Badge** | "FIRST 100" upper-left |

### Ad 3: Year of Horse
| Element | Specification |
|---------|---------------|
| **Visual** | Poon Choi pot, horse silhouette formed from golden particles |
| **Headline** | "BORN IN THE YEAR OF THE HORSE?" |
| **Body** | "This is YOUR year. RM20 fortune bonus waiting." |
| **CTA** | "DM YOUR BIRTH YEAR →" |
| **Color** | Sunset orange to purple gradient |

### Ad 4: iPhone + Prize
| Element | Specification |
|---------|---------------|
| **Visual** | Poon Choi pot, iPhone 17 Pro + cash stacks bursting |
| **Headline** | "THIS MEAL COULD PAY FOR ITSELF" |
| **Body** | "Win iPhone 17 Pro + RM38,888 cash. Every order enters." |
| **CTA** | "ORDER NOW TO WIN →" |
| **Color** | Glossy black #0A0A0A, gold accents |

### Ad 5: Unclaimed Prize
| Element | Specification |
|---------|---------------|
| **Visual** | Poon Choi pot, "RM38,888" slot machine style |
| **Headline** | "RM38,888 STILL UNCLAIMED" |
| **Body** | "Last chance this Chap Goh Meh. Someone's winning. Why not you?" |
| **CTA** | "ENTER BEFORE IT CLOSES →" |
| **Urgency** | "UNCLAIMED" badge with pulse effect |

### Ad 6: Final Chance
| Element | Specification |
|---------|---------------|
| **Visual** | Poon Choi pot, ripping calendar, red curtains closing |
| **Headline** | "FINAL CHANCE. NO EXTENSION." |
| **Body** | "Last batch of Chap Goh Meh pots. Order now or wait until next year." |
| **CTA** | "LOCK IN NOW →" |
| **Banner** | "FINAL CHANCE" top banner |

---

## DELIVERABLES CHECKLIST

- [ ] 6 final ad images (1080×1920 PNG)
- [ ] All use Poon Choi product photo
- [ ] All follow safe zone guide
- [ ] All include proper copy overlays
- [ ] Brand logo present on all
- [ ] Meta-compliant (<20% text area)
- [ ] CTA buttons visible and clear

---

## TOOLS RECOMMENDED

| Task | Tool | Why |
|------|------|-----|
| Design composition | Canva Pro / Figma / Photoshop | Layer control, text tools |
| Background generation | Midjourney / DALL-E / Gemini | CNY festive scenes |
| Product cutout | Remove.bg / Photoshop | Clean transparency |
| Text compliance | Meta Text Overlay Tool | Verify <20% rule |
| Final export | Photoshop / Canva | 1080×1920 PNG output |

---

## NEXT ACTIONS

1. **Download assets** from provided URLs
2. **Open Canva/Figma** with 9:16 template
3. **Import Poon Choi** as main product layer
4. **Add copywriting** per specs above
5. **Export all 6 variants**
6. **Upload to Meta Ads Manager**

---

*Workflow v1.0 — Chap Goh Meh 2026 Campaign*