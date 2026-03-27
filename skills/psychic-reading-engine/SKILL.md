---
name: psychic-reading-engine
agents:
  - taoz
---

# Psychic Reading Engine

## Overview
Deep computational psychic reading system combining Western astrology (PyEphem), Chinese metaphysics (Qi Men Dun Jia), Tarot (Rider-Waite), and Jungian/Forer psychology synthesis. All astronomical computations are real — no approximations or fake data.

## Trigger Conditions
- User asks for a reading, horoscope, birth chart, astrology, tarot, qi men dun jia, QMDJ, or psychic reading
- User provides birth date/time/location
- Agent receives a "reading request" dispatch

## Agent Ownership
- **Zenni (main)**: Computation layer — runs birth-chart.py, qmdj-calc.py, tarot-engine.py
- **Dreami**: Interpretation layer — runs reading-synthesizer.py, crafts narrative output
- **Zenni**: Routing — detects reading requests, runs computation first, then dispatches to Dreami

## Usage

### Full Reading (CLI)
```bash
psychic-reading.sh \
  --name "Name" \
  --date "1990-05-15" \
  --time "14:30" \
  --lat 3.1390 --lon 101.6869 \
  --tz "Asia/Kuala_Lumpur" \
  --spread celtic-cross \
  --question "career" \
  --output markdown
```

### Individual Engines
```bash
# Western birth chart only
python3 scripts/birth-chart.py --name "Name" --date "1990-05-15" --time "14:30" --lat 3.1390 --lon 101.6869 --tz "Asia/Kuala_Lumpur"

# Qi Men Dun Jia only
python3 scripts/qmdj-calc.py --datetime "1990-05-15 14:30" --tz "Asia/Kuala_Lumpur" --question career

# Tarot only
python3 scripts/tarot-engine.py --spread celtic-cross --question "career" --seed 12345
```

### Batch Mode
```bash
psychic-reading.sh --batch readings.csv --output json
# CSV columns: name,date,time,lat,lon,tz,spread,question
```

## Dependencies
- Python 3 with `ephem`, `pytz` (both pre-installed)
- Standard library: `json`, `math`, `datetime`, `random`, `sys`, `argparse`
- No additional pip installs required

## Output Sections
Each full reading produces structured JSON/markdown with:
- **Overview**: Core personality + current energetic snapshot
- **Love**: Relationship patterns, Venus/Moon analysis, 8 Doors love palace
- **Career**: Vocational indicators, Mars/Saturn/10th house, QMDJ career palace
- **Health**: Physical constitution, vulnerable areas, timing
- **Spiritual**: Soul purpose, North Node, Jungian individuation stage
- **Timing**: Key windows from planetary transits + QMDJ temporal gates
- **Advice**: Synthesized actionable guidance with confidence levels

## Computation Stack
1. **Birth Chart** (birth-chart.py): PyEphem real ephemeris, Placidus houses, 10 planets, aspects with orbs, dignities, element/modality balance
2. **QMDJ** (qmdj-calc.py): Real solar terms from astronomical computation, sexagenary cycles, 9 palaces, 8 doors, 9 stars, 8 deities, heaven/earth/human plates
3. **Tarot** (tarot-engine.py): Full 78-card Rider-Waite deck, multiple spread types, reversals, card interactions, Jungian archetypes
4. **Synthesizer** (reading-synthesizer.py): Cross-system pattern matching, Barnum/Forer psychology, cold reading techniques, confidence scoring
