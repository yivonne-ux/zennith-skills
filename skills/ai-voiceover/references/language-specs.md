# Language Specs, Script Writing & SSML Reference

## Script Writing Golden Rules

1. **Sentence length**: 8-15 words per sentence for natural pacing. Shorter = punchier (ads). Longer = storytelling.
2. **Punctuation controls pacing**:
   - Comma `,` = short pause (~0.3s)
   - Period `.` = medium pause (~0.6s)
   - Ellipsis `...` = dramatic pause (~1.0s)
   - Em dash `—` = abrupt break
   - Exclamation `!` = energy boost
3. **CAPS for emphasis**: "This is NOT your average bento" — TTS engines stress capitalized words.
4. **Numbers**: Write out numbers under 10. Use digits for prices: "RM15.90" not "fifteen ringgit ninety sen."
5. **Pronunciation guides**: Add inline guides for names the engine might mispronounce.

## SSML Markup Reference

SSML (Speech Synthesis Markup Language) gives fine-grained control over TTS output. Supported by Google Cloud TTS and ElevenLabs.

```xml
<!-- Basic SSML wrapper -->
<speak>
  <!-- Pause: insert explicit break -->
  Welcome to Mirra. <break time="500ms"/> Your weight management meals, delivered fresh daily.

  <!-- Emphasis: stress a word -->
  This is <emphasis level="strong">not</emphasis> your average meal prep.

  <!-- Prosody: control rate, pitch, volume -->
  <prosody rate="slow" pitch="+2st">Take a moment. Breathe.</prosody>
  <prosody rate="fast" volume="loud">Order now and save 20%!</prosody>

  <!-- Say-as: control number/date reading -->
  Only <say-as interpret-as="currency" language="ms-MY">RM15.90</say-as> per bento.
  Available from <say-as interpret-as="date" format="dm">15 March</say-as>.

  <!-- Phoneme: force pronunciation -->
  <phoneme alphabet="ipa" ph="ˈmɪərɑː">Mirra</phoneme> weight management meals are here.

  <!-- Sub: substitution for abbreviations -->
  Order via <sub alias="WhatsApp">WA</sub> today.

  <!-- Audio: insert sound effect (Google Cloud TTS) -->
  <audio src="https://example.com/ding.mp3">notification sound</audio>
</speak>
```

## Pronunciation Guide for Common Brand Terms

| Term | Pronunciation | IPA | Engine Note |
|------|--------------|-----|-------------|
| Mirra | MEER-rah | ˈmɪərɑː | ElevenLabs handles well; add phoneme for Google |
| Pinxin | PIN-shin | ˈpɪnʃɪn | Must override — engines default to "pin-kshin" |
| Rasaya | rah-SAH-yah | rɑːˈsɑːjɑː | Stress on second syllable |
| Serein | seh-RAIN | sɛˈɹeɪn | French origin, engines often miss |
| Wholey Wonder | HOLE-ee WUN-der | ˈhoʊli ˈwʌndɚ | Natural, no override needed |
| Gaia | GUY-uh | ˈɡaɪ.ə | Engines handle correctly |
| Jade Oracle | JAYD OR-uh-kul | dʒeɪd ˈɒɹəkəl | Natural, no override needed |
| Dr. Stan | Doctor Stan | — | Use `<sub alias="Doctor Stan">Dr. Stan</sub>` |
| Bento | BEN-toh | ˈbɛntoʊ | Natural in most engines |
| Nasi lemak | NAH-see leh-MAHK | ˈnɑːsi ləˈmɑːk | Google BM handles natively; add phoneme for EN engines |
| Rendang | ren-DAHNG | ɹɛnˈdɑːŋ | Google BM handles natively |

## Ad Script Structure

```
┌────────────────────────────────┐
│ HOOK (0-3s)                    │  1-2 sentences. Grab attention.
│ "Tired of boring meal prep?"   │  Question, bold claim, or surprise.
├────────────────────────────────┤
│ PROBLEM (3-8s)                 │  2-3 sentences. Relatable pain point.
│ "You want healthy food, but    │
│  cooking takes forever..."     │
├────────────────────────────────┤
│ SOLUTION (8-13s)               │  2-3 sentences. Introduce the brand.
│ "Mirra delivers calorie-       │
│  controlled meals to your door.│
│  Balanced, delicious, READY."  │
├────────────────────────────────┤
│ CTA (13-16s)                   │  1-2 sentences. Clear action.
│ "Order now on WhatsApp.        │
│  First bento 20% off."         │
└────────────────────────────────┘
```
