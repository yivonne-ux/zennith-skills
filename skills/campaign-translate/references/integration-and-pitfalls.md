## 9. Integration

### Upstream (Feeds FROM)

| Skill | What It Provides | How |
|-------|-----------------|-----|
| `content-supply-chain` | Campaign briefs, content calendar | Translated at CREATE stage |
| `campaign-planner` | Campaign strategy with target languages | Specifies which languages per campaign |
| `meta-ads-creative` | Ad copy in source language | Triggers translation for ad variants |
| `ad-composer` | Image assets with text overlays | Text layers need per-language variants |
| `video-gen` / `video-forge` | Video with subtitles | SRT/ASS files for translation |
| `content-ideation-workflow` | Content ideas in source language | Ideas adapted per language |

### Downstream (Feeds INTO)

| Skill | What It Receives | How |
|-------|-----------------|-----|
| `content-repurpose` | Translated content for platform variants | Each language version gets platform-adapted |
| `social-publish` | Platform-ready multilingual posts | Published with correct language targeting |
| `meta-ads-manager` | Translated ad variants for A/B testing | Language-targeted ad sets |
| `acca-engine` | Translated WhatsApp flows | ACCA messages in user's preferred language |
| `video-forge` | Translated SRT files | Burned into video as subtitles |
| `shopify-cdp` | Translated product descriptions | Synced to multilingual Shopify store |

### Tools Used

| Tool | Purpose |
|------|---------|
| `brand-voice-check.sh` | Validates brand voice compliance post-translation |
| Brand `DNA.json` | Source of truth for voice, tone, personality per brand |
| `nanobanana-gen.sh` | Regenerate image assets with translated text overlays |
| `video-forge.sh` | Burn translated subtitles into video |
| `seed-store.sh` | Store successful translations as seed content |

### Data Flow Diagram

```
campaign-planner ──→ campaign brief (EN) ──→ campaign-translate ──→ brief_bm.md + brief_zh.md
                                                    |
meta-ads-creative ──→ ad copy (EN) ────────→ campaign-translate ──→ ad_bm.txt + ad_zh.txt
                                                    |
video-forge ──────→ video.srt (EN) ────────→ campaign-translate ──→ video_bm.srt + video_zh.srt
                                                    |
                                                    v
                                          brand-voice-check.sh
                                                    |
                                                    v
                                    ┌───────────────┼───────────────┐
                                    v               v               v
                              social-publish   meta-ads-manager   acca-engine
                              (multilingual)   (language A/B)     (user lang pref)
```

---

## 10. Appendix: Common Pitfalls

### Translation Anti-Patterns

| Anti-Pattern | Why It Fails | Do This Instead |
|-------------|-------------|-----------------|
| Direct-translate headlines | Wordplay/puns don't survive | Transcreate: new pun in target language |
| Google Translate for CTAs | Generic, no brand voice | Use CTA Dictionary (Section 7) |
| Same hashtags across languages | Zero discoverability | Research per-language trending tags |
| Translate "free delivery" literally to ZH | Nobody searches that way | Use "免运费" or "包邮" (platform-dependent) |
| Formal BM for casual brand | Sounds like a government notice | Match brand register — use Manglish if DNA says casual |
| Ignore char expansion for BM | Text overflows design | Budget 1.3x space for BM text boxes |
| Copy EN email subject to BM | Open rates tank | Transcreate subject lines independently |
| Translate food names | "Nasi lemak" is "nasi lemak" everywhere | Keep iconic Malaysian food names untranslated |
| Same urgency tactics across languages | Cultural response differs | BM: community ("jom sama-sama"), ZH: scarcity ("限量"), EN: FOMO |

### Untranslatable Terms (Keep As-Is)

These Malaysian terms should NEVER be translated regardless of target language:

| Term | Why |
|------|-----|
| Nasi lemak | Iconic — universally recognized |
| Rendang | Cultural dish name |
| Satay | Universal food term |
| Roti canai | No equivalent |
| Teh tarik | Cultural drink name |
| Kopitiam | Cultural institution |
| Pasar malam | Night market — keep in BM even in ZH/EN |
| Mamak | Restaurant type — culturally specific |
| Kuih | Traditional snack category |
| Jamu | Traditional remedy — keep for Rasaya |
| Bento | Already borrowed into all 3 languages (from Japanese) |
| Halal | Religious certification — universal |
| Hari Raya | Festival name — keep as-is |
| Ang pow / Ang pao | Red packet — keep local term |

