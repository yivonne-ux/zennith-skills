/**
 * Jade Oracle — Interpretation Engine
 *
 * Converts raw QMDJ chart data + user context into structured oracle card readings.
 * Wires: 十干克应 (81 stem combos) + Oracle Cards (25 cards) + 用神 (use gods by topic)
 *
 * Input:  { chart, userContext: { gender, topic, question, chartType } }
 * Output: { cards, focusPalace, stemReading, narrative, systemPromptOverride }
 */

const fs = require('fs');
const path = require('path');

// ── Load Data ────────────────────────────────────────────────────────
const DATA_DIR = process.env.DATA_DIR || path.join(__dirname, '..', 'data');

let cardSystem = null;
let interpretationData = null;

function findDataFile(filename) {
  // Try multiple locations: DATA_DIR directly, reading-engine/data subdir, __dirname/../data
  const candidates = [
    path.join(DATA_DIR, filename),
    path.join(DATA_DIR, 'reading-engine', 'data', filename),
    path.join(__dirname, '..', 'data', filename),
  ];
  for (const p of candidates) {
    if (fs.existsSync(p)) return p;
  }
  return null;
}

function loadData() {
  try {
    const cardPath = findDataFile('jade-oracle-card-system.json');
    if (cardPath) {
      cardSystem = JSON.parse(fs.readFileSync(cardPath, 'utf8'));
      console.log('[interpret] Card system loaded from', cardPath);
    }
  } catch (e) { console.error('[interpret] Card system load failed:', e.message); }

  try {
    const interpPath = findDataFile('qmdj-interpretation-research.json');
    if (interpPath) {
      interpretationData = JSON.parse(fs.readFileSync(interpPath, 'utf8'));
      console.log('[interpret] Research data loaded from', interpPath);
    }
  } catch (e) { console.error('[interpret] Interpretation data load failed:', e.message); }
}

loadData();

// ── QMDJ → Oracle Card Mapping ──────────────────────────────────────

const STAR_TO_CARD = {
  '天蓬': 'The Drifter',
  '天芮': 'The Healer',
  '天冲': 'The Warrior',
  '天辅': 'The Sage',
  '天禽': 'The Emperor',
  '天心': 'The Architect',
  '天柱': 'The Blade',
  '天任': 'The Mountain',
  '天英': 'The Phoenix',
};

const DOOR_TO_CARD = {
  '休门': 'The Rest',
  '死门': 'The Tomb',
  '伤门': 'The Strike',
  '杜门': 'The Veil',
  '景门': 'The Stage',
  '开门': 'The Open Road',
  '惊门': 'The Alarm',
  '生门': 'The Garden',
};

const DEITY_TO_CARD = {
  '值符': 'The Crown',
  '腾蛇': 'The Serpent',
  '太阴': 'The Moon Mother',
  '六合': 'The Union',
  '白虎': 'The White Tiger',
  '玄武': 'The Dark Warrior',
  '九地': 'The Earth Mother',
  '九天': 'The Sky Father',
};

// ── Use Gods by Topic ────────────────────────────────────────────────
// Returns which palaces/symbols to focus on for each reading topic

const USE_GODS = {
  career: {
    primary: ['开门', '值符'],        // workplace + top boss
    secondary: ['戊', '生门'],         // capital + income
    focus: 'Look at 开门 palace for career energy, 值符 for authority/boss dynamics, 生门 for income potential.',
  },
  wealth: {
    primary: ['戊', '生门'],           // capital + profit
    secondary: ['开门', '天蓬'],       // business + financial star
    focus: 'Look at 戊 palace for investment energy, 生门 for profit flow, compare both to 日干 palace.',
  },
  love: {
    primary_male: ['乙'],              // wife/gf for male querent
    primary_female: ['庚'],            // husband/bf for female querent
    secondary: ['六合', '丁'],         // harmony + romance
    focus_male: 'Look at 乙 palace for partner energy. 六合 deity for harmony. Compare 日干 vs 乙 palaces.',
    focus_female: 'Look at 庚 palace for partner energy. 六合 deity for harmony. Compare 日干 vs 庚 palaces.',
  },
  health: {
    primary: ['天芮'],                 // disease star
    secondary: ['天心', '开门'],       // healing star + hospital
    focus: 'Look at 天芮 palace for disease location/nature. 天心 for treatment quality. Body mapping from 九宫.',
  },
  general: {
    primary: ['日干'],
    secondary: ['时干', '值符'],
    focus: 'Read 日干 palace as querent. 时干 as the matter/other party. Layer: stems → door → star → deity.',
  },
  travel: {
    primary: ['日干', '时干'],
    secondary: ['开门', '九天'],
    focus: '日干 = traveler, 时干 = destination. 开门 for favorable start, 九天 for expansion.',
  },
};

// ── Stem Interaction Lookup ──────────────────────────────────────────
// Build a fast lookup from the 81-combo research data

let stemLookup = {};

function buildStemLookup() {
  if (!interpretationData?.section_1_ten_stems_interactions?.formations_81) return;
  const formations = interpretationData.section_1_ten_stems_interactions.formations_81;
  for (const [groupKey, group] of Object.entries(formations)) {
    if (groupKey === 'note') continue;
    for (const [comboKey, data] of Object.entries(group)) {
      if (comboKey === 'note') continue;
      // Parse keys like "甲加甲_戊加戊", "乙加丙", etc.
      const parts = comboKey.split('_');
      for (const part of parts) {
        const match = part.match(/^([\u4e00-\u9fff])加([\u4e00-\u9fff])$/);
        if (match) {
          const key = match[1] + '加' + match[2];
          stemLookup[key] = data;
        }
      }
    }
  }
}

buildStemLookup();

function getStemInteraction(heavenStem, earthStem) {
  const key = heavenStem + '加' + earthStem;
  return stemLookup[key] || null;
}

// ── Palace Element Info ──────────────────────────────────────────────

const PALACE_ELEMENTS = {
  1: { name: '坎', element: '水', direction: 'North' },
  2: { name: '坤', element: '土', direction: 'Southwest' },
  3: { name: '震', element: '木', direction: 'East' },
  4: { name: '巽', element: '木', direction: 'Southeast' },
  5: { name: '中', element: '土', direction: 'Center' },
  6: { name: '乾', element: '金', direction: 'Northwest' },
  7: { name: '兑', element: '金', direction: 'West' },
  8: { name: '艮', element: '土', direction: 'Northeast' },
  9: { name: '离', element: '火', direction: 'South' },
};

const BODY_MAP = {
  1: 'kidneys, ears, reproductive system, blood',
  2: 'abdomen, stomach, spleen, digestive system',
  3: 'liver, gallbladder, limbs, tendons',
  4: 'bile ducts, intestines, thighs, nerves',
  5: 'spleen, central organs',
  6: 'head, lungs, large intestine, bones',
  7: 'mouth, throat, teeth, respiratory',
  8: 'hands, back, nose, stomach',
  9: 'eyes, heart, blood circulation, complexion',
};

// ── Card Data Lookup ─────────────────────────────────────────────────

function getCardData(cardName, category) {
  if (!cardSystem) return null;
  const section = cardSystem[category + '_cards'];
  if (!section?.cards) return null;
  return section.cards.find(c => c.card_name === cardName) || null;
}

// ── Find Symbol in Chart ─────────────────────────────────────────────

function findSymbolPalace(chart, symbolName) {
  if (!chart?.palaces) return null;
  for (const [palaceNum, palace] of Object.entries(chart.palaces)) {
    if (palace.star?.chinese === symbolName) return { palace: parseInt(palaceNum), type: 'star', data: palace };
    if (palace.door?.chinese === symbolName) return { palace: parseInt(palaceNum), type: 'door', data: palace };
    if (palace.deity?.chinese === symbolName) return { palace: parseInt(palaceNum), type: 'deity', data: palace };
    if (palace.heaven_stem === symbolName) return { palace: parseInt(palaceNum), type: 'heaven_stem', data: palace };
    if (palace.earth_stem === symbolName) return { palace: parseInt(palaceNum), type: 'earth_stem', data: palace };
  }
  return null;
}

function findDayStemPalace(chart) {
  if (chart?.day_stem_palace) return chart.day_stem_palace;
  // Fallback: search for 日干 in palaces
  if (!chart?.pillars?.day?.stem || !chart?.palaces) return null;
  const dayStem = chart.pillars.day.stem;
  for (const [pn, p] of Object.entries(chart.palaces)) {
    if (p.heaven_stem === dayStem || p.earth_stem === dayStem) return parseInt(pn);
  }
  return null;
}

// ── Main Interpretation Function ─────────────────────────────────────

/**
 * Generate a structured interpretation from a QMDJ chart + user context.
 *
 * @param {Object} chart - Raw QMDJ chart from engine
 * @param {Object} context - { gender: 'male'|'female', topic: string, question: string, chartType: 'shipan'|'mingpan' }
 * @returns {Object} Structured interpretation for LLM to narrate
 */
function interpret(chart, context = {}) {
  if (!chart?.palaces) return { error: 'No chart data' };

  const { gender = 'unknown', topic = 'general', question = '', chartType = 'shipan' } = context;
  const result = {
    cards: { archetype: null, pathway: null, guardian: null },
    focusPalace: null,
    focusExplanation: '',
    stemReading: null,
    dayPalaceReading: null,
    topicInsights: [],
    formations: [],
    warnings: [],
    oracleNarrative: '',
  };

  // 1. Determine focus palace based on topic + use gods
  const useGod = USE_GODS[topic] || USE_GODS.general;
  let focusSymbols = useGod.primary || [];

  // For love, pick gendered symbols
  if (topic === 'love') {
    if (gender === 'female') {
      focusSymbols = useGod.primary_female || ['庚'];
      result.focusExplanation = useGod.focus_female;
    } else {
      focusSymbols = useGod.primary_male || ['乙'];
      result.focusExplanation = useGod.focus_male;
    }
  } else {
    result.focusExplanation = useGod.focus;
  }

  // Find the primary focus palace
  let focusPalaceNum = null;
  let focusSource = '';
  for (const sym of focusSymbols) {
    if (sym === '日干') {
      focusPalaceNum = findDayStemPalace(chart);
      focusSource = 'Day Stem (You)';
    } else {
      const found = findSymbolPalace(chart, sym);
      if (found) {
        focusPalaceNum = found.palace;
        focusSource = sym;
      }
    }
    if (focusPalaceNum) break;
  }

  // Fallback to day stem palace
  if (!focusPalaceNum) {
    focusPalaceNum = findDayStemPalace(chart);
    focusSource = 'Day Stem (fallback)';
  }

  result.focusPalace = {
    number: focusPalaceNum,
    source: focusSource,
    info: PALACE_ELEMENTS[focusPalaceNum] || null,
    bodyPart: BODY_MAP[focusPalaceNum] || null,
  };

  // 2. Extract the 3 oracle cards from the focus palace
  const focusPalaceData = chart.palaces?.[focusPalaceNum] || chart.palaces?.[String(focusPalaceNum)];
  if (focusPalaceData) {
    // Archetype card (from star)
    const starCn = focusPalaceData.star?.chinese;
    if (starCn && STAR_TO_CARD[starCn]) {
      const cardName = STAR_TO_CARD[starCn];
      result.cards.archetype = {
        name: cardName,
        qmdj: starCn,
        data: getCardData(cardName, 'archetype'),
      };
    }

    // Pathway card (from door)
    const doorCn = focusPalaceData.door?.chinese;
    if (doorCn && DOOR_TO_CARD[doorCn]) {
      const cardName = DOOR_TO_CARD[doorCn];
      result.cards.pathway = {
        name: cardName,
        qmdj: doorCn,
        data: getCardData(cardName, 'pathway'),
      };
    }

    // Guardian card (from deity)
    const deityCn = focusPalaceData.deity?.chinese;
    if (deityCn && DEITY_TO_CARD[deityCn]) {
      const cardName = DEITY_TO_CARD[deityCn];
      result.cards.guardian = {
        name: cardName,
        qmdj: deityCn,
        data: getCardData(cardName, 'guardian'),
      };
    }

    // 3. Stem interaction reading (十干克应)
    if (focusPalaceData.heaven_stem && focusPalaceData.earth_stem) {
      const interaction = getStemInteraction(focusPalaceData.heaven_stem, focusPalaceData.earth_stem);
      if (interaction) {
        result.stemReading = {
          heavenStem: focusPalaceData.heaven_stem,
          earthStem: focusPalaceData.earth_stem,
          formation: interaction.name,
          nature: interaction.nature,
          meaning: interaction.meaning,
        };
      }
    }
  }

  // 4. Day stem palace reading (querent's state)
  const dayStemPalace = findDayStemPalace(chart);
  if (dayStemPalace) {
    const dsp = chart.palaces?.[dayStemPalace] || chart.palaces?.[String(dayStemPalace)];
    if (dsp) {
      result.dayPalaceReading = {
        palace: dayStemPalace,
        info: PALACE_ELEMENTS[dayStemPalace],
        star: dsp.star?.chinese ? STAR_TO_CARD[dsp.star.chinese] || dsp.star.chinese : null,
        door: dsp.door?.chinese ? DOOR_TO_CARD[dsp.door.chinese] || dsp.door.chinese : null,
        deity: dsp.deity?.chinese ? DEITY_TO_CARD[dsp.deity.chinese] || dsp.deity.chinese : null,
        stemInteraction: dsp.heaven_stem && dsp.earth_stem ? getStemInteraction(dsp.heaven_stem, dsp.earth_stem) : null,
      };
    }
  }

  // 5. Topic-specific insights
  const secondarySymbols = topic === 'love'
    ? (useGod.secondary || [])
    : (useGod.secondary || []);

  for (const sym of secondarySymbols) {
    const found = findSymbolPalace(chart, sym);
    if (found) {
      const interaction = found.data.heaven_stem && found.data.earth_stem
        ? getStemInteraction(found.data.heaven_stem, found.data.earth_stem)
        : null;
      result.topicInsights.push({
        symbol: sym,
        palace: found.palace,
        palaceInfo: PALACE_ELEMENTS[found.palace],
        star: found.data.star?.chinese ? STAR_TO_CARD[found.data.star.chinese] || found.data.star.chinese : null,
        door: found.data.door?.chinese ? DOOR_TO_CARD[found.data.door.chinese] || found.data.door.chinese : null,
        stemInteraction: interaction,
      });
    }
  }

  // 6. Check for special formations
  if (chart.palaces) {
    for (const [pn, p] of Object.entries(chart.palaces)) {
      if (!p.heaven_stem || !p.earth_stem) continue;
      const inter = getStemInteraction(p.heaven_stem, p.earth_stem);
      if (!inter) continue;

      // Flag notable formations
      if (inter.nature === '吉' && ['青龙返首', '飞鸟跌穴', '小蛇化龙', '青龙耀明'].includes(inter.name)) {
        result.formations.push({ palace: parseInt(pn), formation: inter.name, nature: 'auspicious', meaning: inter.meaning });
      }
      if (inter.name === '伏吟') {
        result.formations.push({ palace: parseInt(pn), formation: '伏吟', nature: 'stagnation', meaning: inter.meaning });
      }
      if (['荧入太白', '白虎猖狂', '青龙逃走', '天网四张'].includes(inter.name)) {
        result.warnings.push({ palace: parseInt(pn), formation: inter.name, meaning: inter.meaning });
      }
    }
  }

  // 7. Check 空亡 (void) — palaces with void branches have diminished energy
  if (chart.kongwang && focusPalaceData) {
    // Check if focus palace's branch is in kongwang
    const kongBranches = chart.kongwang || [];
    if (kongBranches.length > 0) {
      result.voidWarning = `Void branches: ${kongBranches.join(', ')} — energy in those directions is weakened or won't manifest.`;
    }
  }

  // 8. Build the oracle narrative prompt for LLM
  result.oracleNarrative = buildNarrativePrompt(result, context, chartType);

  return result;
}

// ── Build Narrative Prompt for LLM ───────────────────────────────────

function buildNarrativePrompt(interpretation, context, chartType) {
  const { cards, focusPalace, stemReading, dayPalaceReading, topicInsights, formations, warnings } = interpretation;
  const parts = [];

  parts.push('=== JADE ORACLE INTERPRETATION GUIDE ===');
  parts.push(`Reading type: ${chartType === 'mingpan' ? 'Life Blueprint (Destiny Chart)' : 'Energy Snapshot (Moment Chart)'}`);
  parts.push(`Topic: ${context.topic || 'general'}`);
  if (context.gender !== 'unknown') parts.push(`Querent gender: ${context.gender}`);
  if (context.question) parts.push(`Their question: "${context.question}"`);
  parts.push('');

  // Cards drawn
  parts.push('=== THREE ORACLE CARDS DRAWN ===');
  if (cards.archetype) {
    const c = cards.archetype;
    const d = c.data;
    parts.push(`ARCHETYPE: ${c.name} (energy pattern: ${d?.element || ''})`);
    parts.push(`  Keywords: ${d?.keywords?.join(', ') || ''}`);
    if (context.topic === 'career' && d?.career) parts.push(`  Career energy: ${d.career}`);
    if (context.topic === 'wealth' && d?.wealth) parts.push(`  Wealth energy: ${d.wealth}`);
    if (context.topic === 'love' && d?.relationships) parts.push(`  Relationship energy: ${d.relationships}`);
    if (context.topic === 'health') parts.push(`  Light: ${d?.light || ''}`);
    if (context.topic === 'general') {
      parts.push(`  Light: ${d?.light || ''}`);
      parts.push(`  Shadow: ${d?.shadow || ''}`);
    }
  }

  if (cards.pathway) {
    const c = cards.pathway;
    const d = c.data;
    parts.push(`PATHWAY: ${c.name}`);
    parts.push(`  Keywords: ${d?.keywords?.join(', ') || ''}`);
    parts.push(`  Meaning: ${d?.meaning || ''}`);
    parts.push(`  Advice: ${d?.advice || ''}`);
  }

  if (cards.guardian) {
    const c = cards.guardian;
    const d = c.data;
    parts.push(`GUARDIAN: ${c.name}`);
    parts.push(`  Keywords: ${d?.keywords?.join(', ') || ''}`);
    parts.push(`  Meaning: ${d?.meaning || ''}`);
  }

  // Energy dynamics (十干克应)
  if (stemReading) {
    parts.push('');
    parts.push('=== ENERGY DYNAMIC (core reading) ===');
    parts.push(`Formation: "${stemReading.formation}" (${stemReading.nature === '吉' ? 'Auspicious' : stemReading.nature === '凶' ? 'Challenging' : 'Mixed'})`);
    parts.push(`Meaning: ${stemReading.meaning}`);
  }

  // Your current state (day stem)
  if (dayPalaceReading && dayPalaceReading.palace !== focusPalace?.number) {
    parts.push('');
    parts.push('=== YOUR CURRENT STATE ===');
    parts.push(`Your energy sits in Palace ${dayPalaceReading.palace} (${dayPalaceReading.info?.name || ''}, ${dayPalaceReading.info?.element || ''}, ${dayPalaceReading.info?.direction || ''})`);
    if (dayPalaceReading.star) parts.push(`  Archetype: ${dayPalaceReading.star}`);
    if (dayPalaceReading.door) parts.push(`  Pathway: ${dayPalaceReading.door}`);
    if (dayPalaceReading.deity) parts.push(`  Guardian: ${dayPalaceReading.deity}`);
    if (dayPalaceReading.stemInteraction) {
      parts.push(`  Energy: "${dayPalaceReading.stemInteraction.name}" — ${dayPalaceReading.stemInteraction.meaning}`);
    }
  }

  // Topic-specific insights
  if (topicInsights.length > 0) {
    parts.push('');
    parts.push('=== SUPPORTING INSIGHTS ===');
    for (const insight of topicInsights) {
      let line = `${insight.symbol} energy in Palace ${insight.palace} (${insight.palaceInfo?.direction || ''})`;
      if (insight.door) line += ` — Pathway: ${insight.door}`;
      if (insight.stemInteraction) line += ` — "${insight.stemInteraction.name}": ${insight.stemInteraction.meaning}`;
      parts.push(line);
    }
  }

  // Special formations
  if (formations.length > 0) {
    parts.push('');
    parts.push('=== SPECIAL PATTERNS ===');
    for (const f of formations) {
      parts.push(`Palace ${f.palace}: "${f.formation}" (${f.nature}) — ${f.meaning}`);
    }
  }

  // Warnings
  if (warnings.length > 0) {
    parts.push('');
    parts.push('=== WATCH OUT ===');
    for (const w of warnings) {
      parts.push(`Palace ${w.palace}: "${w.formation}" — ${w.meaning}`);
    }
  }

  if (interpretation.voidWarning) {
    parts.push('');
    parts.push(`VOID: ${interpretation.voidWarning}`);
  }

  // How to deliver
  parts.push('');
  parts.push('=== DELIVERY NOTES ===');
  parts.push('Tell a story using the 3 cards. Don\'t list them one by one like a menu.');
  parts.push('The Energy Dynamic is the deepest insight — weave it in naturally.');
  parts.push('Talk about what you SEE, not what cards "mean". Be specific to their situation.');
  parts.push('NEVER use Chinese characters. Call it "the energy", "what i\'m seeing", "the system".');
  parts.push('End with 1-2 things they can actually do. Keep it under 300 words total.');

  return parts.join('\n');
}

// ── Conversation Flow: Pre-Reading Questions ─────────────────────────

/**
 * Generate Jade's question flow before a reading.
 * Returns the next question to ask, or null if ready to read.
 *
 * Design: MAX 1 question before reading. Don't interrogate.
 * - If no topic: ask what's on their mind (open-ended, NOT a menu)
 * - Gender: only ask for love readings. Skip otherwise.
 * - Specific question: skip — the topic IS the question. If they want to elaborate, they will.
 */
function getNextQuestion(collectedContext) {
  const { gender, topic, question } = collectedContext;

  // No topic yet — ask naturally, ONE open question
  if (!topic) {
    return {
      field: 'topic',
      message: `what's weighing on you? just tell me — could be work, love, money, health, anything. i'll read from there.`,
    };
  }

  // Only ask gender for love/relationship readings — it actually matters there
  if (topic === 'love' && (!gender || gender === 'unknown')) {
    return {
      field: 'gender',
      message: `and are you a guy or a girl? the energy i look at shifts depending on that`,
    };
  }

  // Ready to read — don't ask more questions
  return null;
}

/**
 * Parse user's topic selection from free text.
 */
function parseTopic(text) {
  const lower = text.toLowerCase();
  if (/career|job|work|business|purpose|promotion|boss|company|startup|职业|事业|工作/.test(lower)) return 'career';
  if (/money|wealth|financ|invest|income|abundance|rich|salary|财|钱|投资/.test(lower)) return 'wealth';
  if (/love|relationship|partner|marriage|dating|boyfriend|girlfriend|crush|husband|wife|ex|感情|恋爱|婚姻/.test(lower)) return 'love';
  if (/health|sick|illness|body|medical|wellbeing|mental|anxiety|depression|stress|健康|身体/.test(lower)) return 'health';
  if (/general|life|direction|everything|overall|all|通用|综合/.test(lower)) return 'general';

  // Check for topic emoji shortcuts
  if (/💫/.test(text)) return 'career';
  if (/💰/.test(text)) return 'wealth';
  if (/❤/.test(text)) return 'love';
  if (/🌿/.test(text)) return 'health';
  if (/✨/.test(text)) return 'general';

  // Number shortcuts
  if (/^[1１]$/.test(text.trim())) return 'career';
  if (/^[2２]$/.test(text.trim())) return 'wealth';
  if (/^[3３]$/.test(text.trim())) return 'love';
  if (/^[4４]$/.test(text.trim())) return 'health';
  if (/^[5５]$/.test(text.trim())) return 'general';

  return null; // Could not determine — treat as the question itself
}

/**
 * Parse gender from text.
 */
function parseGender(text) {
  const lower = text.toLowerCase();
  if (/\b(male|man|guy|boy|m|他|男)\b/.test(lower)) return 'male';
  if (/\b(female|woman|girl|lady|f|她|女)\b/.test(lower)) return 'female';
  return null;
}

// ── Export ────────────────────────────────────────────────────────────

module.exports = {
  interpret,
  getNextQuestion,
  parseTopic,
  parseGender,
  getStemInteraction,
  findSymbolPalace,
  findDayStemPalace,
  STAR_TO_CARD,
  DOOR_TO_CARD,
  DEITY_TO_CARD,
  USE_GODS,
  loadData,
};
