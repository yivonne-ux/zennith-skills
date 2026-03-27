# AI SEO Vertical Playbooks

## Spiritual / Oracle (Jade Oracle)

- Cite psychological frameworks (Jung's archetypes, positive psychology, narrative therapy) -- not just metaphysics
- Handle YMYL/E-E-A-T by positioning the reading methodology as the authority signal, not supernatural claims
- Schema: `Service` for readings, `FAQPage` for "what is oracle reading" queries
- Target queries: "online psychic reading," "oracle card reading," "spiritual guidance online," "tarot vs oracle cards"
- Create content that frames oracle readings through the lens of self-reflection and personal growth
- Include practitioner credentials, years of experience, and number of readings delivered as trust signals
- Avoid "prediction" language -- use "insight," "reflection," "guidance" for E-E-A-T compliance

## Wellness / Supplements (Dr Stan, Serein, Gaia Supplements)

- Cite clinical studies with DOI links or PubMed references for every health claim
- Use `NutritionInformation` schema on all product pages, `Product` with `offers` for e-commerce
- Comply with Malaysian health claim regulations (KKM/MOH) -- never claim "cures" or "treats," use "supports" or "promotes"
- Target queries: "best probiotics Malaysia," "gut health supplements," "immunity boosters," "natural wellness Malaysia"
- Include ingredient sourcing transparency (origin, certifications, third-party testing)
- Add "Reviewed by [qualified nutritionist/pharmacist]" attribution to health content
- Structure comparison pages: "[Brand] vs [competitor]" with objective criteria tables

## F&B / Vegan (Pinxin Vegan, Mirra, Wholey Wonder, Rasaya, Gaia Eats)

- Use `Recipe` schema with full nutrition data, `Product` schema with pricing, `LocalBusiness` for physical locations
- Target queries: "vegan food delivery [city]," "healthy meal plans Malaysia," "[product] recipe," "best vegan restaurant KL"
- Include transparent nutrition info (calories, macros, allergens) -- AI heavily cites pages with structured nutrition data
- Add `Menu` schema for F&B businesses with pricing and dietary labels (vegan, gluten-free, halal)
- Optimise Google Business Profile with menu links, photos, and regular post updates
- Create "vs" content: "meal prep vs MIRRA subscription," "vegan vs plant-based"
- For MIRRA specifically: target "weight management meal plan" and "healthy bento subscription" queries

## E-commerce / D2C (Aerthera, Iris)

- Use `Product` schema with `offers`, `AggregateRating`, `brand` entity, and `Review` markup
- Target queries: "[brand] review," "best [category] Malaysia," "[product] vs [competitor]"
- Build rich product pages with specs, ingredient lists, usage instructions, and customer testimonials
- Create comparison content: "[product] vs [competitor product]" with objective feature tables
- Maintain active presence on Shopee/Lazada with rich descriptions that mirror site content
- Use `Organization` schema to build brand entity recognition across platforms
- Encourage and mark up verified customer reviews -- AI engines heavily weight aggregate ratings

## Handling AI Hallucinations About Your Brand

If AI engines return incorrect information about your brand (wrong products, outdated pricing, competitor confusion):

1. **Create a definitive "About [Brand]" page** with correct facts -- founding date, product range, pricing, locations, key differentiators
2. **Cite it across third-party platforms** -- Google Business Profile, LinkedIn, social bios, directory listings should all match
3. **Add `Organization` schema** with `sameAs` links to all official profiles
4. **Re-test monthly** -- query ChatGPT, Perplexity, and Google AI Overviews until the correct information surfaces
5. **If persistent:** publish a structured FAQ ("Is [Brand] a skincare company? No, [Brand] is...") directly addressing the misinformation
