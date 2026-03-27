## 8. Quality Gates

Every translated campaign asset must pass these gates before publishing.

### Gate 1: Back-Translation Check
- Translate output BACK to source language
- Compare meaning (not words) with original
- **Pass:** Core meaning and emotional intent preserved
- **Fail:** Meaning drift, lost nuance, or wrong emotional tone
- **Action on fail:** Re-transcreate the drifted sections

### Gate 2: Brand Voice Check
```bash
bash ~/.openclaw/skills/brand-voice-check/scripts/brand-voice-check.sh \
  --brand {brand} \
  --input {translated_file} \
  --language {target_lang}
```
- **Pass:** Voice score >= 80%
- **Fail:** Voice attributes misaligned
- **Action on fail:** Identify which attributes drifted, adjust register/tone

### Gate 3: Cultural Sensitivity Review
Checklist:
- [ ] No accidental halal/haram implications
- [ ] No culturally inappropriate imagery references in text
- [ ] Holiday/festival references appropriate for target language audience
- [ ] No political sensitivity (Malaysian context)
- [ ] Honorifics and address forms correct (BM: anda/kamu/awak register)
- [ ] No direct translation of idioms that change meaning cross-culturally
- [ ] Food terminology checked (some dishes have different names in different languages)

### Gate 4: Character Count Verification
```
For each output:
  - Count characters
  - Compare against platform limit for content type
  - Flag any overflow (>95% of limit = warning, >100% = fail)
  - BM outputs: verify expansion within expected 1.1-1.3x range
  - ZH outputs: verify contraction within expected 0.5-0.7x range
```

### Gate 5: Platform Compatibility
- [ ] Hashtags are language-appropriate and trending (not direct-translated)
- [ ] Emoji render correctly across platforms
- [ ] CJK text doesn't break layout in design files
- [ ] SRT/ASS timing verified for subtitle files
- [ ] WhatsApp button text within character limits (20 chars max)
- [ ] Email subject line under 50 chars per language
- [ ] Shopee title under 120 chars per language

### Gate Summary Matrix

| Gate | Automated? | Blocking? | Tool |
|------|-----------|-----------|------|
| Back-Translation | Semi (LLM-assisted) | Yes for ads, No for social | campaign-translate.sh validate |
| Brand Voice | Yes | Yes | brand-voice-check.sh |
| Cultural Sensitivity | Manual | Yes for all | Checklist review |
| Character Count | Yes | Yes | campaign-translate.sh validate |
| Platform Compatibility | Semi | Yes for paid, No for organic | campaign-translate.sh validate |

