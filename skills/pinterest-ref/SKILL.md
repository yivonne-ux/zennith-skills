# Pinterest Visual Reference Extraction

## Purpose

Extract visual references from Pinterest pins and boards, then generate structured visual DNA analysis documents for character design and brand identity work.

## The Yvonne Method (7-Phase Brand Visual DNA Extraction)

A systematic process for extracting actionable visual identity from reference imagery:

1. **Harvest** — `pinterest-extract.sh` downloads high-resolution reference images from Pinterest pins or boards
2. **View** — Agent views downloaded images using its image/vision tool
3. **Template** — `visual-dna-extract.sh` generates a structured analysis template
4. **Analyze** — Agent fills in the visual DNA template after viewing all images
5. **Synthesize** — Agent distills analysis into a character spec or brand DNA document
6. **Generate** — Character spec feeds into NanoBanana image generation prompts
7. **Iterate** — Compare generated output to references, refine prompts

## Scripts

### pinterest-extract.sh

Downloads images from a Pinterest pin or board URL.

```
pinterest-extract.sh <pinterest-url> <output-dir>
```

- Fetches page HTML with Chrome user agent
- Extracts all `i.pinimg.com` image URLs (jpg and png)
- Deduplicates by image hash
- Prefers highest resolution (originals > 1200x > 736x > smaller)
- Downloads to specified output directory
- Prints summary of downloaded files

**Examples:**

```bash
# Single pin
pinterest-extract.sh "https://www.pinterest.com/pin/123456789/" /tmp/refs/pin1

# Board
pinterest-extract.sh "https://www.pinterest.com/user/board-name/" /tmp/refs/board1
```

### visual-dna-extract.sh

Creates a visual DNA analysis template for a directory of reference images.

```
visual-dna-extract.sh <image-dir> <output-file>
```

- Scans the image directory for downloaded references
- Generates a markdown template with sections for: color palette, mood, lighting, fashion, composition, cultural elements, typography, texture
- Lists all image filenames for reference during analysis
- The template is a checklist — an agent with vision capability must fill it in after viewing the images

**Example:**

```bash
visual-dna-extract.sh /tmp/refs/board1 /tmp/refs/board1/visual-dna.md
```

## Workflow Integration

Typical agent workflow:

```
1. Receive Pinterest URL(s) from user or brand brief
2. Run: pinterest-extract.sh <url> <output-dir>
3. View each downloaded image with vision tool
4. Run: visual-dna-extract.sh <output-dir> <output-dir>/visual-dna.md
5. Fill in the visual-dna.md template based on what was observed
6. Use completed visual DNA to write character specs or NanoBanana prompts
```

## Dependencies

- `curl` (macOS built-in)
- `grep`, `sed`, `sort`, `awk` (macOS built-in, no GNU extensions required)
- No bash 4+ features required (runs on macOS default bash 3.2)

## Limitations

- Pinterest may block aggressive scraping; the script uses a single curl request per URL
- Board pages may not return all pins in the initial HTML (Pinterest lazy-loads)
- For boards with many pins, only the initially-rendered pins are captured
- Actual visual analysis requires an agent with image/vision capability (Iris, Dreami)
