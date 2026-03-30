# Reference-Based Design Adaptation Pipelines
## Comprehensive Research Report — March 2026

Research compiled for Bloom & Bare production pipeline development.

---

## Table of Contents
1. [Vision AI for Design Analysis](#1-vision-ai-for-design-analysis)
2. [Design Decomposition Techniques](#2-design-decomposition-techniques)
3. [Style Transfer for Graphic Design](#3-style-transfer-for-graphic-design)
4. [Current Tools and APIs](#4-current-tools-and-apis)
5. [Production Workflows Used by Agencies](#5-production-workflows-used-by-agencies)
6. [Existing Open-Source Projects](#6-existing-open-source-projects)
7. [Practical Implementation Architecture](#7-practical-implementation-architecture)
8. [Sources](#8-sources)

---

## 1. Vision AI for Design Analysis

### 1.1 Multimodal Models for Layout Extraction

Three tiers of vision models are available today for analyzing reference designs:

**Tier 1: Commercial API Models (Best accuracy, highest cost)**

- **GPT-4o / GPT-5.3** — Can analyze uploaded design images and return structured JSON describing layout zones, text hierarchy, and color relationships. Supports structured output mode to force consistent JSON schemas. Key limitation: bounding box coordinates are often inaccurate for precise pixel-level localization. Best used for semantic understanding ("this is a headline at the top, with a mascot in the lower-right") rather than exact pixel coordinates.

- **Claude Opus 4.5 / 4.6** — Excels at reasoning-based interpretation of design intent. Can handle 200,000-token contexts while preserving spatial relationships. Strong at extracting design "intent" and hierarchy rather than raw coordinates. Best prompt approach: request interpretation rather than description (e.g., "explain the visual hierarchy" not "list the elements").

- **Gemini 2.0 / 2.5** — The standout for spatial understanding and bounding box detection. Unlike GPT-4o and Claude which bolt vision encoders onto language models, Gemini learned vision and language simultaneously. Returns bounding box coordinates normalized to 0-1000 scale in [y_min, x_min, y_max, x_max] format. Open vocabulary detection — not restricted to fixed categories. Can detect up to 25 objects per image. Supports zero-shot object detection AND segmentation.

**Tier 2: Open-Source VLMs (Good accuracy, self-hostable)**

- **Qwen2.5-VL (7B/72B)** — Open-source model from Alibaba. Outperforms GPT-4o and Claude 3.5 Sonnet on benchmarks like MMMU (70.2), DocVQA (96.4). Uses absolute coordinate space for bounding boxes. Outputs stable JSON for coordinates and attributes. Uses unified HTML-based representation encoding both text and spatial layout. The 7B variant is runnable on consumer hardware.

- **Florence-2 (0.2B/0.7B)** — Microsoft's lightweight foundation VLM, MIT licensed. Handles captioning, object detection, segmentation, OCR, and visual grounding through a single prompt-based interface. Trained on FLD-5B dataset (5.4B annotations across 126M images). Extremely small and fast — suitable for batch processing.

- **Molmo / LLaMA 3.2 Vision** — Viable alternatives but Qwen2.5-VL generally outperforms on design-specific tasks.

**Tier 3: Specialized Detection Models (Best for specific subtasks)**

- **Grounding DINO** — Open-set object detector. Accepts text prompts like "headline text, decorative shape, mascot, logo" and returns bounding boxes. 52.5 AP on zero-shot COCO. Dual-encoder architecture (Swin Transformer + BERT). Can detect arbitrary objects described in natural language.

- **SAM 3 / SAM 2** — Meta's Segment Anything Model. SAM 3 (released Nov 2025) introduces Prompt Concept Segmentation — segments all instances of a visual concept. 6x faster than original SAM. Accepts points, boxes, or text prompts. Outputs individual masks per element. Ideal for isolating design elements from flat images.

### 1.2 What Each Model Can Extract

| Extraction Task | Best Model | Accuracy Level |
|---|---|---|
| Layout grid / zone detection | Gemini 2.5 | High (normalized coords) |
| Typography hierarchy (relative) | Claude / GPT-4o | High (semantic) |
| Typography hierarchy (exact px) | PaddleOCR + heuristics | Medium |
| Color palette extraction | ColorThief (Python) | Exact |
| Element identification (semantic) | Qwen2.5-VL / GPT-4o | High |
| Element segmentation (masks) | SAM 3 + Grounding DINO | High |
| Compositional structure | Claude / GPT-4o | High (semantic) |
| White space mapping | OpenCV contours + VLM | Medium |
| Visual weight distribution | VLM semantic analysis | Medium |

### 1.3 Recommended Prompt Strategy for Design Analysis

For extracting design specifications via VLM, use structured prompts requesting JSON:

```
Analyze this graphic design image. Return a JSON object with:
{
  "canvas": {"width_px": int, "height_px": int, "background_color": "#hex"},
  "zones": [
    {
      "id": "zone_1",
      "type": "headline|body_text|image|decorative|mascot|logo|badge",
      "bbox_normalized": [y_min, x_min, y_max, x_max],  // 0-1000 scale
      "content_description": "string",
      "estimated_font_size_relative": "large|medium|small",
      "estimated_font_weight": "bold|medium|regular",
      "dominant_color": "#hex",
      "visual_weight": "high|medium|low"
    }
  ],
  "typography_hierarchy": {
    "levels": int,
    "headline_style": "string description",
    "body_style": "string description"
  },
  "color_palette": ["#hex1", "#hex2", ...],
  "composition": {
    "structure": "centered|asymmetric|grid|diagonal",
    "rule_of_thirds": bool,
    "symmetry_axis": "vertical|horizontal|none"
  },
  "white_space_ratio": float  // 0.0-1.0
}
```

Key insight from research: GPT-4V/4o hallucinates bounding box coordinates for complex scenes. A hybrid workflow (VLM pre-labeling + programmatic verification) is recommended.

---

## 2. Design Decomposition Techniques

### 2.1 Layer Extraction from Flat Images

The core challenge: a reference image is a flat raster — no layers, no objects, just pixels. Decomposing it requires multiple techniques in concert.

**Pipeline approach (recommended):**

1. **SAM 3 + Grounding DINO** — Use Grounding DINO to identify element bounding boxes by text prompt ("headline, subheading, mascot, logo, decorative blob, photo, badge pill"). Then pass each box to SAM 3 for precise mask segmentation. This gives you isolated elements with alpha masks.

2. **PaddleOCR Layout Detection** — PaddleOCR's layout detection module (PP-PicoDet based) can identify: text, title, table, figure, list regions. Available models: English layout, Chinese layout, table layout. Python: `from paddleocr import LayoutDetection`. Outputs bounding boxes with region type labels.

3. **PaddleOCR Text Detection + Recognition** — After layout detection, run OCR on text regions to extract: text content, text bounding boxes (word-level and line-level), reading order.

4. **OpenCV Contour Detection** — For decorative elements (blobs, shapes, swooshes): convert to binary, `cv.findContours()`, filter by area/shape. Extracts shape boundaries, centroids, and areas. Useful for white space analysis (invert → measure empty regions).

### 2.2 Academic Models for Design Layout

**LayoutLMv3** (Microsoft, Hugging Face)
- Pre-trained multimodal Transformer for document layout analysis
- Model IDs: `microsoft/layoutlmv3-base`, `microsoft/layoutlmv3-large`
- Uses patch embeddings (ViT-style), trained on MLM + MIM + word-patch alignment
- State-of-the-art on form understanding, receipt understanding, document VQA, and document image classification
- 95% accuracy on RVL-CDIP

**DiT — Document Image Transformer** (Microsoft)
- Pure vision model (no text input needed)
- Pre-trained on large-scale unlabeled document images
- 92% accuracy on RVL-CDIP
- Model doc: `huggingface.co/docs/transformers/model_doc/dit`

**DesignProbe Benchmark** (arXiv: 2404.14801)
- Benchmark for evaluating MLLMs on graphic design understanding
- 8 tasks across element-level and overall-design-level
- Element-level: color attribute recognition, font attribute recognition, layout attribute recognition
- Semantic-level: color understanding, font understanding, layout understanding
- Finding: adding image examples to prompts boosts performance more than text descriptions
- Tested 9 MLLMs including GPT-4V and Gemini Pro Vision

**PosterLLaVA** (arXiv: 2406.02884)
- Unified multi-modal layout generator using LLM
- Generates poster layouts in JSON format from visual and textual constraints
- Trained on 84,200 constrained layout generation samples
- Includes QB-Poster dataset: 5,188 samples from Chinese social media
- Can generate editable SVG posters from text descriptions
- GitHub: `github.com/posterllava/PosterLLaVA`

**PosterLayout** (CVPR 2023)
- Dataset: 9,974 poster-layout pairs + 905 images
- Content-aware visual-textual presentation layout benchmark

**Layout Parser** (open-source toolkit)
- GitHub: `github.com/Layout-Parser/layout-parser`
- Deep learning based document image analysis
- Extracts complicated document structures with minimal code
- No sophisticated rules needed — model-driven

### 2.3 Design Token Extraction

**From Images (automated):**
- Color palette: `colorthief` Python library → `get_palette(color_count=6)` returns dominant colors
- Typography: VLM semantic analysis (relative sizing) + PaddleOCR (bounding box heights as proxy for font size)
- Spacing: compute distances between detected element bounding boxes
- Grid: cluster element x/y coordinates to find alignment guides

**From Websites (brand extraction):**
- Brandfetch (`brandfetch.dev`) — instantly extracts colors, typography, spacing, component styles from any URL. Exports as JSON or Markdown.
- Tokens Studio — Figma plugin for managing design tokens as a single source of truth

**Design Token Standard:**
- DTCG 2025.10 standard covers token format, color spaces, composite types, and resolver system
- Tokens capture: colors, spacing, typography, shadows, borders, durations, animation timing

---

## 3. Style Transfer for Graphic Design

### 3.1 The Core Problem

"Make it look like this but in our brand" is the most common design agency request. This is NOT neural style transfer (which transfers painterly textures). This is structural design adaptation — preserving layout, hierarchy, and composition while swapping brand elements.

### 3.2 Wireframe Extraction → Brand Application

The most practical workflow today:

1. **Extract wireframe from reference** — Use VLM to analyze reference and output a structural description (zone positions, hierarchy, proportions)
2. **Map to design tokens** — Convert structural description to brand-agnostic layout specification
3. **Apply brand DNA** — Swap in target brand colors, fonts, logos, mascots, tone
4. **Render programmatically** — Use Python (Pillow/DrawBot) to render the adapted design

This is essentially what Bloom & Bare's production pipeline already does — the research confirms this is the industry-leading approach.

### 3.3 How Agencies Handle It

**Pentagram's approach:** Map out where consistency creates the most impact. Build systems so consistency is embedded and easy for clients to maintain. The system IS the design — not individual executions.

**Collins' approach:** Strip everything back to essence. Sophistication from restraint, not decoration. Design systems over one-off executions.

**Industry-standard workflow:**
1. Receive reference deck / mood board from client
2. Extract "design DNA" — the structural and tonal qualities that make it work
3. Translate DNA into design tokens (spacing scale, type scale, color relationships)
4. Build template system using those tokens + client's brand assets
5. Generate variants programmatically or through design system

**Key insight:** No major agency is using AI to directly "style transfer" one design into another brand. They ALL decompose first, extract structure, then rebuild. The decomposition step is where AI is now accelerating the workflow.

### 3.4 Brand Guidelines as API

Frontify and others are pushing "brand guidelines as an API" — a structured data layer that tools can query programmatically. This means a design pipeline could:
- Pull brand color tokens from guidelines API
- Check campaign assets for compliance automatically
- Validate that generated designs match brand specifications

---

## 4. Current Tools and APIs

### 4.1 Segmentation & Element Isolation

| Tool | What It Does | Access |
|---|---|---|
| **SAM 3** | Segment any object from image with point/box/text prompt | `github.com/facebookresearch/sam3`, integrated in Ultralytics 8.3.237+ |
| **SAM 2** | Image + video segmentation, 6x faster than SAM 1 | `github.com/facebookresearch/sam2` |
| **Grounding DINO** | Open-vocabulary object detection with text prompts | `github.com/IDEA-Research/GroundingDINO` |
| **Grounded SAM** | Grounding DINO + SAM combined pipeline | Various GitHub repos |

### 4.2 OCR & Text Detection

| Tool | Strengths | Python Install |
|---|---|---|
| **PaddleOCR** | Best overall: layout detection + text detection + recognition. 100+ languages. | `pip install paddleocr` |
| **EasyOCR** | Simple API, 80+ languages, no training needed | `pip install easyocr` |
| **Tesseract/Pytesseract** | Classic OCR, good for clean text | `pip install pytesseract` |
| **Keras-OCR** | Pre-trained models via Keras/TensorFlow | `pip install keras-ocr` |

**PaddleOCR specific modules:**
- `LayoutDetection` — detect text/title/table/figure/list regions
- `PPStructure` — end-to-end document structure analysis
- Layout models: English, Chinese, Table variants

### 4.3 Color Extraction

| Tool | What It Does | Install |
|---|---|---|
| **ColorThief** | Dominant color + palette from image (Median Cut Quantization) | `pip install colorthief` |
| **fast-colorthief** | Faster C++ backend version | `pip install fast-colorthief` |
| **OpenCV k-means** | Manual k-means clustering on pixel colors | `pip install opencv-python` |
| **scikit-learn KMeans** | More control over clustering params | `pip install scikit-learn` |

### 4.4 Layout Analysis Models (Hugging Face)

| Model | ID | Size | Task |
|---|---|---|---|
| **LayoutLMv3-base** | `microsoft/layoutlmv3-base` | 133M | Document layout + text understanding |
| **LayoutLMv3-large** | `microsoft/layoutlmv3-large` | 368M | Same, higher accuracy |
| **DiT** | `microsoft/dit-base` | — | Document image classification |
| **Florence-2-base** | `microsoft/Florence-2-base` | 0.2B | Multi-task vision (detection, segmentation, OCR, captioning) |
| **Florence-2-large** | `microsoft/Florence-2-large` | 0.7B | Same, higher accuracy |
| **DETR Layout** | `cmarkea/detr-layout-detection` | — | Layout element detection |
| **Qwen2.5-VL-7B** | `Qwen/Qwen2.5-VL-7B-Instruct` | 7B | Full VLM with spatial understanding |

### 4.5 Design Analysis Python Libraries

| Library | Purpose |
|---|---|
| **Pillow (PIL)** | Image manipulation, crop zones, draw bounding boxes, composite layers |
| **OpenCV** | Contour detection, edge detection, morphological operations, color space conversion |
| **scikit-image** | Image processing, segmentation, feature detection |
| **layoutparser** | Deep learning document layout analysis (`pip install layoutparser`) |
| **colorthief** | Color palette extraction |
| **paddleocr** | OCR + layout detection |
| **ultralytics** | YOLO + SAM 3 integration |
| **transformers** | Hugging Face models (LayoutLMv3, Florence-2, etc.) |

### 4.6 Font Recognition

| Tool | Approach |
|---|---|
| **DeepFont** (Adobe) | Deep learning font recognition from images. GitHub implementations exist (`github.com/robinreni96/Font_Recognition-DeepFont`) |
| **Font-Finder** | OCR-based font recognition (`github.com/ChrisBarsolai/Font-Finder`) |
| **VLM analysis** | Prompt GPT-4o/Claude with "identify the font family, weight, and approximate size" — gives semantic results, not exact |

Note: Exact font size detection from images remains a gap. Best approach is PaddleOCR bounding box heights as a proxy, combined with VLM semantic analysis.

### 4.7 Vision Model APIs

| Provider | Model | Bounding Box Support | Cost |
|---|---|---|---|
| **Google** | Gemini 2.5 | Yes (0-1000 normalized) | API pricing |
| **OpenAI** | GPT-4o / o3 | Limited accuracy | API pricing |
| **Anthropic** | Claude Opus 4.6 | Semantic only | API pricing |
| **Alibaba** | Qwen2.5-VL | Yes (absolute coords) | Free (open-source) |
| **Microsoft** | Florence-2 | Yes | Free (MIT license) |
| **Roboflow** | Various | Yes | Free tier + paid |

---

## 5. Production Workflows Used by Agencies

### 5.1 The Reference Adaptation Workflow

**Standard agency process:**

```
Reference Deck (3-10 inspiration images)
    ↓
Design Director extracts "what works" (structure, energy, hierarchy)
    ↓
Translates to design tokens + layout principles
    ↓
Junior designers build templates using brand assets + extracted structure
    ↓
Review cycle (does it capture the reference's energy with our brand?)
    ↓
Production pipeline generates variants
```

### 5.2 AI-Augmented Version (What's Possible Today)

```
Reference Image
    ↓
[Vision AI Analysis] — Gemini 2.5 or Qwen2.5-VL
    Extract: layout zones, hierarchy, color relationships, composition
    Output: structured JSON specification
    ↓
[Element Segmentation] — Grounding DINO + SAM 3
    Isolate: each design element as masked layer
    Output: individual PNGs with alpha
    ↓
[Text Extraction] — PaddleOCR
    Extract: all text content, positions, relative sizes
    Output: text map with bounding boxes
    ↓
[Color Analysis] — ColorThief + OpenCV
    Extract: palette, color distribution, gradients
    Output: hex values + usage percentages
    ↓
[Template Specification] — LLM synthesis
    Combine all extracted data into template spec
    Map reference zones to brand asset slots
    Output: JSON template definition
    ↓
[Brand Asset Substitution]
    Swap: reference colors → brand palette
    Swap: reference fonts → brand fonts
    Swap: reference images → brand assets (mascots, logos, photos)
    Keep: layout proportions, hierarchy, spacing ratios
    ↓
[Programmatic Rendering] — Python (Pillow/DrawBot)
    Render final design from template spec + brand assets
    ↓
[Quality Audit] — VLM comparison
    Compare output against reference for structural fidelity
    Compare against brand guidelines for brand compliance
```

### 5.3 Design System Tokenization

Modern agencies build design systems with these token categories:
- **Color tokens**: primary, secondary, accent, background, text colors
- **Typography tokens**: font family, size scale (8 steps), weight scale, line height, letter spacing
- **Spacing tokens**: base unit + multipliers (4px base × 1/2/3/4/6/8/12/16)
- **Layout tokens**: column count, gutter width, margin, max-width
- **Component tokens**: border-radius, shadow levels, animation timing

These tokens bridge the gap between reference analysis and brand application.

---

## 6. Existing Open-Source Projects

### 6.1 Screenshot-to-Code

**Repository:** `github.com/abi/screenshot-to-code` (53,000+ GitHub stars)
- Drop in a screenshot, get clean HTML/Tailwind/React/Vue code
- Uses GPT-4 Vision + DALL-E 3
- Supports React, Vue, Angular, and more
- Iteratively refines generated code for high fidelity
- **Relevance to design adaptation:** Demonstrates that VLMs can extract enough structural information from a flat image to recreate it programmatically. The same principle applies to design adaptation — extract structure, rebuild with different assets.

### 6.2 OpenPencil

**Repository:** `github.com/open-pencil/open-pencil`
- Open-source, AI-native design editor (Figma alternative)
- Reads and writes native Figma .fig files
- 87 AI tools: create shapes, set fills/strokes, manage auto-layout, work with components/variables, boolean operations, analyze design tokens, export assets
- Headless CLI for inspection, export, and analysis
- MCP-compatible — connects to Claude Code, Cursor, etc.
- ~7 MB desktop app (macOS, Windows, Linux) or browser
- **Relevance to design adaptation:** Could serve as the "design engine" in an automated pipeline — import reference .fig, extract tokens programmatically, apply new brand, export.

### 6.3 Lovart AI

**Website:** `lovart.ai`
- "Edit Elements" feature (launched Nov 2025): deconstructs any finished poster into independently editable text, subject, and background layers with a single click
- Text extracted as editable layer (modify content, font, color, layout)
- Automatic task decomposition from natural language
- **Relevance:** Demonstrates that AI-powered layer decomposition from flat designs is production-ready. However, it's a commercial tool, not open-source.

### 6.4 PosterLLaVA

**Repository:** `github.com/posterllava/PosterLLaVA`
- Academic project: unified multi-modal layout generator
- Generates poster layouts in structured JSON from visual + textual constraints
- 84,200 training samples for constrained layout generation
- Can output editable SVG posters
- **Relevance:** Could be used to generate layout specifications that match a reference's structure.

### 6.5 Layout Parser

**Repository:** `github.com/Layout-Parser/layout-parser`
- Deep learning toolkit for document image analysis
- Pre-trained models for layout detection
- Minimal code required
- **Relevance:** Quick layout zone detection as first step in decomposition.

### 6.6 Other Notable Projects

- **Flame** — Open-source multimodal AI for translating UI mockups into React code
- **Builder.io Visual Copilot** — Figma to code with AI + Mitosis compiler
- **Codia AI** — Screenshots/PDFs/webpages to Figma designs and code
- **Anima** — Figma design to functional application

---

## 7. Practical Implementation Architecture

### 7.1 Recommended Pipeline for Bloom & Bare

Based on all research findings, here is the optimal reference-based design adaptation pipeline:

```
PHASE 1: ANALYSIS (one-time per reference)
├── Input: reference_image.png
├── Step 1: VLM Analysis (Gemini 2.5 or Qwen2.5-VL)
│   └── Output: layout_spec.json (zones, hierarchy, composition)
├── Step 2: Element Segmentation (Grounding DINO + SAM 3)
│   └── Output: element_masks/ (individual PNGs)
├── Step 3: Text Extraction (PaddleOCR)
│   └── Output: text_map.json (content, positions, sizes)
├── Step 4: Color Analysis (ColorThief + OpenCV)
│   └── Output: palette.json (colors, distribution)
└── Step 5: Template Synthesis (Claude/GPT-4o)
    └── Output: template_definition.json

PHASE 2: ADAPTATION (per brand application)
├── Input: template_definition.json + brand_DNA.md
├── Step 1: Token Mapping
│   └── Map reference tokens → brand tokens
├── Step 2: Asset Substitution
│   └── Swap placeholders → brand mascots, logos, photos
├── Step 3: Text Adaptation
│   └── Apply brand copy, bilingual content, brand voice
└── Step 4: Render (Python/Pillow)
    └── Output: branded_design.png

PHASE 3: QUALITY (automated)
├── Step 1: Structure Fidelity Check (VLM comparison)
├── Step 2: Brand Compliance Check (against brand DNA)
├── Step 3: Text Legibility Check (OCR validation)
└── Step 4: Color Accuracy Check (palette verification)
```

### 7.2 Key Technical Decisions

1. **Use Gemini 2.5 for bounding boxes** — best spatial accuracy among commercial APIs
2. **Use Qwen2.5-VL-7B as fallback** — free, self-hostable, strong spatial understanding
3. **Use SAM 3 (not SAM 2)** for element segmentation — Prompt Concept Segmentation is a game-changer
4. **Use PaddleOCR over Tesseract** — layout detection module + better multilingual support (critical for EN/CN bilingual content)
5. **Use ColorThief for palette** — lightweight, accurate, no ML overhead
6. **Keep Python/Pillow as renderer** — consistent with existing Bloom & Bare pipeline, full control over output
7. **VLM for semantic analysis, specialized tools for precise extraction** — hybrid approach compensates for VLM coordinate inaccuracy

### 7.3 What's NOT Ready Yet (Gaps)

1. **Exact font recognition from images** — DeepFont exists but limited font coverage. VLMs give semantic descriptions ("bold sans-serif") not exact font names. For brand work, you already know your fonts — this gap doesn't matter.
2. **Automatic spacing scale extraction** — Must be inferred from bounding box distances. No dedicated tool exists.
3. **Visual weight distribution** — No quantitative tool. VLMs provide qualitative analysis only.
4. **One-click reference → brand-adapted output** — No single tool does this end-to-end. The pipeline approach (analysis → adaptation → render) is required.
5. **Decorative element recreation** — AI can identify decorative shapes but can't reliably recreate them in brand style. Pre-generated SVG libraries or Python-drawn shapes remain the best approach (consistent with Bloom & Bare's existing v2 architecture).

### 7.4 Cost Estimates

| Component | Cost per Reference Analysis |
|---|---|
| Gemini 2.5 API (analysis) | ~$0.01-0.05 per image |
| SAM 3 (local, Ultralytics) | Free (compute only) |
| PaddleOCR (local) | Free (compute only) |
| ColorThief (local) | Free |
| Claude/GPT-4o (synthesis) | ~$0.02-0.10 per call |
| **Total per reference** | **~$0.03-0.15** |

---

## 8. Sources

### Vision AI & Design Analysis
- [GPT-4o Vision Guide](https://getstream.io/blog/gpt-4o-vision-guide/)
- [OpenAI Vision API Guide](https://platform.openai.com/docs/guides/vision)
- [Claude Vision for Document Analysis](https://getstream.io/blog/anthropic-claude-visual-reasoning/)
- [Gemini 2.0 Bounding Box Detection](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/bounding-box-detection)
- [Gemini 2.0 Spatial Understanding](https://github.com/GoogleCloudPlatform/generative-ai/blob/main/gemini/use-cases/spatial-understanding/spatial_understanding.ipynb)
- [Gemini 2.5 Zero-Shot Object Detection](https://blog.roboflow.com/gemini-2-5-object-detection-segmentation/)
- [NVIDIA VLM Prompt Engineering Guide](https://developer.nvidia.com/blog/vision-language-model-prompt-engineering-guide-for-image-and-video-understanding/)
- [VLM: How Vision-Language Models Work (2026)](https://labelyourdata.com/articles/machine-learning/vision-language-models)

### Open-Source Vision Models
- [Qwen2.5-VL on Hugging Face](https://huggingface.co/Qwen/Qwen2.5-VL-7B-Instruct)
- [Qwen2.5-VL Object Detection](https://learnopencv.com/object-detection-with-vlms-ft-qwen2-5-vl/)
- [Florence-2-large on Hugging Face](https://huggingface.co/microsoft/Florence-2-large)
- [Florence-2 Explained](https://encord.com/blog/florence-2-explained/)
- [LayoutLMv3 on Hugging Face](https://huggingface.co/microsoft/layoutlmv3-base)
- [DiT on Hugging Face](https://huggingface.co/docs/transformers/model_doc/dit)
- [SmolVLM2 by Hugging Face](https://blog.roboflow.com/smolvlm2/)

### Segmentation & Detection
- [SAM 3 — Segment Anything with Concepts](https://docs.ultralytics.com/models/sam-3/)
- [SAM 3 on GitHub](https://github.com/facebookresearch/sam3)
- [SAM 2 by Meta AI](https://ai.meta.com/sam2/)
- [Grounding DINO on GitHub](https://github.com/IDEA-Research/GroundingDINO)
- [Grounding DINO Paper](https://arxiv.org/abs/2303.05499)
- [How to Use SAM](https://blog.roboflow.com/how-to-use-segment-anything-model-sam/)

### OCR & Layout Detection
- [PaddleOCR Layout Detection Docs](https://paddlepaddle.github.io/PaddleOCR/main/en/version3.x/module_usage/layout_detection.html)
- [PaddleOCR Layout Analysis](https://paddlepaddle.github.io/PaddleOCR/main/en/version3.x/module_usage/layout_analysis.html)
- [PaddleOCR on GitHub](https://github.com/PaddlePaddle/PaddleOCR)
- [Mastering PaddleOCR for Layout Detection](https://pvsravanth.medium.com/mastering-paddleocr-for-layout-detection-d4edb26723d0)
- [Layout Parser on GitHub](https://github.com/Layout-Parser/layout-parser)

### Color Extraction
- [ColorThief Python](https://github.com/fengsp/color-thief-py)
- [fast-colorthief](https://github.com/bedapisl/fast-colorthief)

### Font Recognition
- [DeepFont Implementation](https://github.com/robinreni96/Font_Recognition-DeepFont)
- [Font-Finder](https://github.com/ChrisBarsolai/Font-Finder)

### Academic Papers & Benchmarks
- [DesignProbe Benchmark (arXiv 2404.14801)](https://arxiv.org/abs/2404.14801)
- [PosterLLaVA (arXiv 2406.02884)](https://arxiv.org/abs/2406.02884)
- [PosterLayout (CVPR 2023)](https://arxiv.org/abs/2303.15937)
- [SciPostLayout (BMVC 2024)](https://arxiv.org/abs/2407.19787)
- [Deep Learning-Based Layout Analysis (MDPI 2025)](https://www.mdpi.com/2076-3417/15/14/7797)
- [Document Layout Analysis Survey](https://www.rohan-paul.com/p/state-of-the-art-model-architectures)

### Design Tools & Platforms
- [OpenPencil on GitHub](https://github.com/open-pencil/open-pencil)
- [Screenshot-to-Code on GitHub](https://github.com/abi/screenshot-to-code)
- [PosterLLaVA on GitHub](https://github.com/posterllava/PosterLLaVA)
- [Lovart AI](https://www.lovart.ai/)
- [Lovart Edit Elements](https://www.agiyes.com/ainews/lovart-edit-elements/)
- [Brandfetch](https://brandfetch.dev/)
- [Tokens Studio](https://tokens.studio/plugin-tools)

### Agency Workflows & Design Systems
- [Pentagram — Systemising a Brand](https://the-brandidentity.com/interview/presented-by-brandpad-how-to-systemise-a-brand-featuring-pentagram-how-how-and-studio-blackburn)
- [Brand Guidelines as API (Frontify)](https://www.frontify.com/en/guide/brand-guidelines)
- [Design Tokens and AI](https://medium.com/@marketingtd64/design-tokens-and-ai-scaling-ux-with-dynamic-systems-316afa240f6f)
- [Design Token Management Tools 2025](https://cssauthor.com/design-token-management-tools/)
- [Design System Agencies 2026](https://www.superside.com/blog/design-system-agencies)

### Design-to-Code & AI Design Tools
- [Figma AI Tools](https://www.figma.com/resource-library/ai-design-tools/)
- [Builder.io Figma to Code](https://www.builder.io/blog/figma-to-code-ai)
- [Codia AI](https://codia.ai/)
- [Anima](https://www.animaapp.com)
- [Tailwind CSS from Screenshot](https://www.aiui.me/blog/tailwind-css-classes-from-screenshot)
