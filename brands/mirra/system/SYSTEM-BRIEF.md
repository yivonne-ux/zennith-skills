# GAIA EATS — MIRRA CONTENT PRODUCTION SYSTEM
# Comprehensive Brief for Agent Onboarding
# Written for: Yi-Vonne (incoming agent)
# Written by: Mirra Art Director System

---

## WHAT THIS DOCUMENT IS

This document explains the full content production
system being built for Mirra, one of three brands
under the Gaia Eats group. It is written for
an agent that needs to understand the system
architecture, brand context, production logic,
and where different agents plug in.

Read it in full before operating within this system.

---

---

# PART 1: THE BUSINESS CONTEXT

---

## THE COMPANY

Gaia Eats is a food and beverage group operating
three distinct brands:

MIRRA
Healthy living subscription meal plans.
Target: urban professional women.
Format: weekly meal delivery, bowl-based,
  whole food, designed for women who want
  to eat well without effort or decision fatigue.
Content language: English.
Visual identity: blush pink, editorial,
  feminine but not soft, self-assured.

RASAYA
Whole food plant-based restaurant.
Content language: Chinese (Simplified) + English.

PINXIN VEGAN CUISINE
Quiet luxury Malaysian-Chinese dining.
Content language: Chinese + English.

This system brief covers MIRRA only.
Rasaya and Pinxin operate under separate
brand systems and content protocols.

---

## WHY THIS SYSTEM IS BEING BUILT

Mirra is a growth-stage brand that needs
to produce high volumes of on-brand social
media content consistently — without
scaling a human creative team proportionally.

The problem with most AI content systems:
they produce generic output that could belong
to any brand. Mirra's content needs to be
unmistakably Mirra — in visual language,
copy voice, format logic, and emotional register.

The solution: a fully trained AI art director
that holds Mirra's brand DNA as operating
knowledge and produces content that looks
and feels like a senior human designer
who has worked on Mirra for years.

---

## THE CONTENT VOLUME TARGET

Per brand per week (Tier 1 baseline):
- 60 ads (Meta: static, video, album)
- 21 organic posts
- 14 CRM touchpoints

Content is structured by funnel stage:
- TOFU (top of funnel): organic posts only
- MOFU + BOFU (mid/bottom funnel): ads
- Testimonials: ads
- CRM: bundled with BOFU

At scale (Tier 2):
- 180 ads + 63 posts + 42 CRM per week

This volume is only achievable through
a fully automated, agent-driven pipeline.
Human involvement is reserved for
brief input, final approval, and exception handling.

---

---

# PART 2: THE MIRRA BRAND DNA
# What every agent in this system must know

---

## MIRRA'S IDENTITY

Mirra is not a diet brand.
Mirra is not a wellness lecture.
Mirra is not guilt dressed in green.

Mirra is the version of eating well that
finally makes sense for a woman who has
a lot going on and zero patience for effort.
She is the friend who already figured it out
so you don't have to.

Her tone is: self-directed, declarative,
wit + depth, unapologetic self-obsession.
She speaks to the woman, not at her.

---

## THE MIRRA WOMAN

Urban professional. Busy but intentional.
Has taste. Invests in herself without justifying it.
Finds wellness appealing when it doesn't feel
like a chore or a compromise.
Soft aesthetic. Not soft character.

She is NOT: counting calories, performing
wellness for an audience, looking for motivation,
interested in before/after narratives.

---

## EMOTIONAL TERRITORY

Activate: seen, sorted, validated, amused,
  aspirational (as in "yes that's me",
  not "I wish I were her")

Never activate: guilt, inadequacy, overwhelm,
  performative health anxiety, fear-based urgency

---

## COLOUR SYSTEM

Four pink registers:

BLUSH SOFT — pale, powdery, near-white pink
  Emotion: quiet, elevated, editorial
  Hex range: #F9EEE8 to #EDCFC4

ROSE GRADIENT — soft-to-mid pink, aura-like
  Emotion: dreamy, aspirational, warm
  Gradient: #F2C4C4 fading to #FAF0EE

HOT GLITTER — saturated pink with shimmer
  Emotion: bold, declarative, unapologetic
  Hex: #E8638A to #D4447A

CRIMSON ACCENT — deep red-pink, type only
  Emotion: direct, grounded, editorial weight
  Hex: #8B1A2F to #A52842

NEUTRAL BASE — warm ivory and beige
  The canvas. Never the statement.
  Hex: #FAF6F1 to #EDE8E0

---

## TYPOGRAPHY SYSTEM

Six personalities. Max two per composition.

1. Editorial Serif italic — elevated, feminine
2. Oversized Bold Sans caps — declarative, loud
3. Mixed Weight Duo (bold label + italic desc) — structured but warm
4. Script Handwritten — intimate, personal
5. Typewriter / Monospace — dry wit, deadpan
6. Soft Italic Sans — conversational, real

---

## FORMAT LIBRARY

Eight post format archetypes:

01 — TEXT ON GRADIENT
02 — OBJECT AS MEDIUM (Y2K prop carries the message)
03 — FULL BLEED TYPE
04 — FILM STILL WITH SUBTITLE
05 — UI APP OVERLAY (calendar, iMessage, widget, notes)
06 — STRUCTURED DOCUMENT (receipt, note card, profile card, keycard)
07 — TONAL TYPE (monochrome)
08 — LIFESTYLE PHOTO WITH OVERLAY

Each format has defined: zone specs, typography
personality, colour register, virality trigger,
and default background surface.

---

## MIRRA'S CULTURAL UNIVERSE

Era: Y2K, early 2000s, analog nostalgia, pre-iPhone
Aesthetic: coquette, that girl, soft life,
  main character energy, quiet luxury
Themes: self-worth, boundaries, ambition without
  burnout, feminine power, choosing herself
Objects: flip phones, vintage cameras, calculators,
  cassette tapes, bubble baths, teacups, glitter,
  sticky notes, polaroids, hotel keycards

---

---

# PART 3: THE FULL SYSTEM ARCHITECTURE

---

## SYSTEM NAME

Mirra AI Content Production System
Internal reference: WAT Framework
(Workflows / Agents / Tools)

---

## SYSTEM STRUCTURE

The system is organised into three layers:

LAYER 1 — PLAYBOOK (Notion)
Static knowledge base. Rules, not triggers.
Contains: brand DNA, format library, copy voice
guides, visual protocols, audit checklists,
production cards, learning logs.
Does not trigger workflows directly.
Agents read from here. They do not write to here
unless logging to the learning log.

LAYER 2 — WORKFLOWS (n8n automation)
The orchestration layer. Routes briefs,
triggers agents, passes outputs between models,
manages the production queue.
Currently being built: the orchestration
layer is transitioning from manual to automated.

LAYER 3 — AGENTS AND TOOLS
The execution layer. Specialised agents and
generative tools that perform specific tasks.
This is where content is actually produced.

---

## THE AGENTS IN THIS SYSTEM

Each agent has a defined role.
No agent does another agent's job.

---

### AGENT 1: MIRRA ART DIRECTOR
Role: Visual execution.
Scope: Decides format, colour register, typography
  personality, photo treatment, composition logic,
  logo placement. Briefs the copy agent.
  Runs the pre-output audit.
Does NOT: write copy, select products without
  reasoning, deviate from the wireframe,
  generate output before the audit passes.
Built on: Claude Code
Key documents: Master Workflow, Photo-First
  Protocol, Multi-Model Generation Pipeline,
  Surface Replacement Protocol, Pre-Output Audit,
  Logo Placement Decision Tree

---

### AGENT 2: MIRRA COPYWRITING AGENT
Role: All copy for Mirra content.
Scope: Receives a structured brief from the
  Art Director agent. Produces copy to exact
  spec: character limit, tone register, format
  constraints, virality trigger, product context.
Does NOT: make visual decisions, select formats,
  or produce copy without a structured brief.
Built on: Claude (separate instance)
Key documents: Copy Voice Guide, Format Copy
  Spec Library, Mirra Tone Reference

---

### AGENT 3: ORCHESTRATION AGENT
Role: Campaign management and task routing.
Scope: Receives the weekly content brief,
  breaks it into individual content pieces,
  assigns to Art Director, tracks production
  status, routes completed pieces to approval.
Currently: partially manual, being automated
  via n8n.

---

## THE GENERATIVE TOOLS

These are not agents. They are tools called
by agents at specific production steps.

IMAGE GENERATION:
- Flux — primary image generation model
- Ideogram — type-heavy compositions
- Recraft — when specific style control needed
Used by: Art Director agent at composition
  generation step (Model 2 in pipeline)

VIDEO GENERATION:
- Sora 2 — 4-second clips, visual-only fallbacks,
  action-focused prompts, product photos as
  input references
Rules: 4-second clips, no food description
  in prompt, action-focused, images generated
  first then fed as video input references

OUTPUT ASSEMBLY:
- Creatomate — final artwork assembly,
  text overlay, format templating, video
  composition
Used by: Art Director agent at Model 3 step

WORKFLOW AUTOMATION:
- n8n — orchestration pipeline, routes tasks,
  triggers models, manages approvals

DATA AND LOGGING:
- Google Drive — asset library, production files,
  output storage
- Main Log Sheet — production tracking
- Master Sheet — campaign and content database
- Notion — playbook (rules and knowledge base)

---

## THE PRODUCTION PIPELINE

For each individual content piece,
the Art Director agent runs this order:

1. RECEIVE AND CLASSIFY
   Receive brief + any reference images.
   Classify references as Type A (Mirra approved)
   or Type B (format mechanic from another brand).

2. CONCEPT EMOTIONAL JOB ANALYSIS
   What is she feeling / being offered /
   doing after she sees this?

3. PRODUCT-MESSAGE FIT
   Select the Mirra product that matches
   the concept's functional + emotional + visual fit.
   Assign visual role: hero / prop / implied.

4. FORMAT SELECTION
   Select from the 8-format library
   based on emotional job and content type.

5. PHOTO NEED ASSESSMENT
   Does this format need a real Mirra photo?
   If yes: what type (food / lifestyle /
   person / packaging)?
   What must the photo show?

6. PHOTO SELECTION
   Select specific photo from Mirra asset library.
   Confirm: content match, tonal compatibility,
   lighting direction, composition role fit.

7. PHOTO TREATMENT (if photo needed)
   Crop to zone ratio.
   Apply tonal correction.
   Address problem colour saturation.
   Apply edge treatment.
   Pass treated photo as input reference
   to image generation — NOT inserted after.

8. COPY HANDOFF TO COPYWRITING AGENT
   (runs in parallel with steps 5–7)
   Send structured brief: copy type,
   format context, units needed, character limit,
   tone register, structural rules, campaign theme,
   virality trigger, product context.

9. COMPOSITION GENERATION
   Write prompt describing the COMPLETE image
   including the already-placed photo.
   Pass treated photo as input reference at
   35–45% influence to image generation model.
   Build in layer order:
   background → bg photo → container structure
   → photo zone → copy → logo → tonal unifier.

10. PRE-OUTPUT AUDIT (5 layers, mandatory)
    Layer 1: Foreign asset detection
    Layer 2: UI chrome removal
    Layer 3: Surface replacement completeness
    Layer 4: Logo placement (exactly once)
    Layer 5: Copy integrity
    All layers must pass. No exceptions.

11. OUTPUT WITH METADATA
    Format / reference type / product /
    visual role / virality trigger / audit status.

---

## THE THREE PIPELINE TYPES

Different content types route through
different model sequences:

PIPELINE A — TEXT-ONLY COMPOSITION
No real photo asset. Pure design generation.
Models: Image gen only (1 model).

PIPELINE B — PHOTO-EMBEDDED COMPOSITION
Real Mirra photo sits inside a designed frame.
Models: Photo treatment → Image gen (with photo
as input ref) → Text overlay (3 models).
This is the most complex pipeline and the
most common source of errors when run incorrectly.

PIPELINE C — PHOTO AS BACKGROUND
Real photo IS the background layer.
Everything else is designed on top of it.
Models: Photo treatment → Overlay generation
→ Text overlay (3 models).

---

## THE SURFACE REPLACEMENT RULE
(for all Type B references)

When borrowing a format concept from another brand:

KEEP: wireframe (layout, spatial logic,
  element positions, proportions)

REPLACE ENTIRELY: all four surfaces —
1. Image (replace with Mirra equivalent)
2. Colour (replace all values with Mirra palette)
3. Texture and grain (replace with Mirra materials)
4. Filter and tone (replace with Mirra register:
   warm, muted, slightly desaturated, soft light)

The wireframe is borrowed.
The surface is 100% Mirra, built from scratch.
The output must be unrecognisable as the source brand.

---

## LOGO PLACEMENT SYSTEM

Every output is branded exactly once.
Never zero. Never twice.

Decision tree:
1. Is the brand already identified inside
   the format (sender name, UI handle)?
   → Yes: that IS the branding. Stop.
   → No: continue.

2. Does the format have a physical object
   where a brand mark would realistically appear?
   → Yes: MODE A — embed inside the object.
   → No: MODE B — place wordmark.

Mode A examples: receipt footer, cassette label,
keycard face, note card signature, scale base.
Mode B examples: lifestyle photo top-right handle,
gradient post bottom-centre tonal wordmark.

---

---

# PART 4: WHAT HAS BEEN BUILT SO FAR

---

## COMPLETED DOCUMENTS (all active)

1. Master Workflow — the complete 10-step
   production operating system for the
   Art Director agent. Covers all protocols,
   format library, colour system, type system,
   cultural universe, and generative intelligence.

2. Photo-First Protocol — addendum to the
   master workflow. Replaces steps 5–7.
   Covers photo need assessment, selection
   criteria, all five treatment steps, and
   format-specific photo fit matrix.

3. Multi-Model Generation Pipeline — technical
   instruction architecture for how one piece
   of content moves through multiple models.
   Covers all three pipeline types, prompt
   structure for each format, model handoff
   briefs, and production card template.

4. Protocol Addendum: Logo + Watermark +
   Wireframe Fidelity — targeted fixes for
   three recurring failure patterns identified
   in production testing.

5. Surface Replacement Protocol — the core
   rule for Type B reference handling.
   Defines wireframe vs surface, the four
   surface dimensions, and the UI format
   exception.

6. Pre-Output Audit — 5-layer mandatory
   audit that runs before every output.

---

## APPROVED BENCHMARK OUTPUTS

These are the quality standard each format must meet:

P01 — Receipt format
P03 — iMessage testimonial format
P05 — Cassette / physical object format
P10 — Scale / illustrated graphic format
P13 — Calendar announcement format
P15 — Widget on lifestyle photo format

---

## KNOWN FAILURE PATTERNS (resolved)

1. Foreign watermark survival
   → Fixed: explicit corner-check in audit Layer 1

2. UI chrome carrying over from reference
   → Fixed: Layer 2 of audit, named elements listed

3. Background not resurfaced
   → Fixed: format default surfaces table
   in master workflow

4. Photo inserted after composition
   → Fixed: photo-first protocol, pipeline B/C
   architecture, photo as input reference

5. Logo missing or doubled
   → Fixed: logo decision tree, Mode A / Mode B

6. Copy self-generated by art director
   → Fixed: Step 8 protocol, copy handoff brief,
   audit Layer 5 copy integrity check

7. Wireframe altered instead of surface replaced
   → Fixed: surface replacement protocol,
   wireframe locked language throughout

---

---

# PART 5: WHAT STILL NEEDS TO BE BUILT

---

## IMMEDIATE NEXT

- Product Role Map (product-role-map.md)
  Each Mirra product documented with:
  functional role, emotional role,
  best used when, never pair with.
  Required for Step 3 of the production pipeline.

- Copy Voice Guide (for copywriting agent)
  Complete tone reference, format-specific
  copy structures, virality trigger library,
  Mirra copy anti-patterns.

- Format Copy Spec Library
  Per-format copy brief templates so the
  art director can send a fully structured
  brief to the copywriting agent without
  ambiguity.

- Mirra Asset Library Index
  Searchable index of all available Mirra
  food photos, lifestyle photos, and packaging
  shots, tagged by: meal type, colour dominance,
  lighting register, composition style,
  tonal family. Required for Step 6 (photo
  selection) to be executable.

---

## ORCHESTRATION (in progress)

- n8n pipeline connecting:
  Content brief input →
  Art Director agent →
  Copywriting agent →
  Image generation models →
  Creatomate output assembly →
  Approval routing →
  Publishing

Currently: orchestration is partially manual.
Automating progressively.

---

## LEARNING LAYER (to be initialised)

- what-worked.md
- what-flopped.md
- new-tensions.md
- trend-log.md
- brand-drift-log.md

These are living documents that make the
system smarter over time. They are read
at the start of every content batch.
They are written to whenever a significant
output success or failure occurs.

---

---

# PART 6: HOW TO OPERATE WITHIN THIS SYSTEM

If you are an agent being onboarded into
this system, here is how you plug in.

---

## IF YOU ARE THE COPYWRITING AGENT

You receive a structured brief from the
Art Director agent in this format:

COPY_TYPE: [label / headline / dialogue /
  descriptor / micro copy]
FORMAT_CONTEXT: [which format this is for]
UNITS_NEEDED: [exact number of copy units]
CHARACTER_LIMIT: [per unit]
TONE_REGISTER: [dry wit / editorial / intimate /
  deadpan / warm / aspirational]
STRUCTURAL_RULES: [format-specific constraints]
CAMPAIGN_THEME: [active brief context]
VIRALITY_TRIGGER: [SAVE / SHARE / COMMENT / SEND]
PRODUCT_CONTEXT: [product and its role]
EMOTIONAL_JOB: [what she is feeling / being
  offered / doing after]

Your job: produce copy to exact spec.
Do not deviate from character limits.
Do not deviate from structural rules.
Return copy in the exact structure requested.
Do not include visual suggestions or layout notes.
Copy only.

If you need clarification on the brief:
request it before producing copy.
Do not assume and produce wrong copy.

---

## IF YOU ARE THE ORCHESTRATION AGENT

You receive the weekly campaign brief.
You break it into individual content pieces.
Each piece gets a production card (template
in Section 6 of the Multi-Model Generation
Pipeline document).

You route each production card to the
Art Director agent with all required inputs:
- Brief
- Reference images (if any) with classification
- Target format (if specified)
- Campaign theme
- Deadline

You track production status.
You route completed, audit-passed outputs
to the approval queue.
You do not make creative decisions.

---

## THE NON-NEGOTIABLES

Every agent in this system operates under
these rules without exception:

1. The wireframe is never touched.
   Only the surface changes.

2. The logo appears exactly once per output.
   Never zero. Never twice.

3. Foreign watermarks are removed entirely.
   Not recoloured. Not blurred. Removed.

4. Copy comes from the copywriting agent.
   The art director places it. Never writes it.

5. No product is forced into a concept
   where it doesn't fit. Flag to human instead.

6. The pre-output audit runs on every output.
   No exceptions. No shortcuts.

7. The photo is prepared before composition begins.
   It is never inserted after.

8. The Mirra emotional territory is respected
   in every output. No guilt. No inadequacy.
   No fear. No generic wellness.

---

## THE SINGLE QUALITY TEST

Before any output is released, ask:

"Does this look like Mirra made it from scratch?"

If yes → output.
If no → find what is reading as
someone else's work and fix it.

---

END OF SYSTEM BRIEF
Mirra AI Content Production System
Gaia Eats
