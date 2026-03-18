# MIRRA — Reference Scraping Tasks
> Generated: 2026-03-08T22:45:41
> Agent: Artemis (Scout/Researcher)
> Target: 40-60 references across sources

---

## Brand Context
- **Brand**: MIRRA
- **Tagline**: Same delicious local flavours, no compromises
- **Existing refs**: 31 images

## Reference Categories

- 1-recipe-rebels (from pillar: RECIPE_REBELS)
- 2-beyond-the-food (from pillar: BEYOND_THE_FOOD)
- 3-women-who-get-it (from pillar: WOMEN_WHO_GET_IT)
- 4-mirra-magic (from pillar: MIRRA_MAGIC)
- logo (standard)
- typography (standard)
- competitor-refs (standard)
- aesthetic-board (standard)

## Scraping Sources

### Pinterest (target: 20-30 pins)
Search terms to try:
- "MIRRA aesthetic"
- "MIRRA brand"
- Keywords from content pillars (see DNA.json)
- Competitor aesthetic boards

### Instagram (target: 10-15 posts)
- Brand's own IG feed (top performing posts)
- Competitor IG accounts (see DNA.json competitor_intel)
- Aesthetic hashtags relevant to brand

### Competitor (target: 10-15 references)
- Direct competitor content for format inspiration
- Type B references (wireframe only — surface will be replaced)

## Auto-categorization Rules
After scraping, categorize each image:
1. Match to content pillar category if content aligns
2. If typography-focused: `typography/`
3. If competitor format reference: `competitor-refs/`
4. If general aesthetic/mood: `aesthetic-board/`
5. Place brand logos in `logo/`

## Output
Save images to: `brands/mirra/references/{category}/`
When complete, run: `brand-system-architect.sh analyze --brand mirra`
