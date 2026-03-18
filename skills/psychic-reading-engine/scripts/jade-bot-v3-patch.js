/**
 * Jade Oracle Bot — v3 Patch
 *
 * This file contains the DIFF sections to patch into jade-bot.js on VPS.
 * Changes: interpretation engine, question flow, oracle card presentation.
 *
 * APPLY: Upload jade-interpretation-engine.js + jade-oracle-card-system.json +
 *        qmdj-interpretation-research.json to VPS, then apply these patches.
 */

// ═══════════════════════════════════════════════════════════════════════
// PATCH 1: Add after line 78 (loadQmdjEngine()) — Load interpretation engine
// ═══════════════════════════════════════════════════════════════════════

// --- INSERT AFTER: loadQmdjEngine(); ---

let interpretEngine = null;
try {
  const interpPath = path.join(DATA_DIR, 'jade-interpretation-engine.js');
  if (fs.existsSync(interpPath)) {
    interpretEngine = require(interpPath);
    console.log('[interpret] Interpretation engine loaded');
  } else {
    console.warn('[interpret] Engine not found at', interpPath);
  }
} catch (e) {
  console.error('[interpret] Failed to load:', e.message);
}


// ═══════════════════════════════════════════════════════════════════════
// PATCH 2: Update chat state shape (replace lines 214-227)
// ═══════════════════════════════════════════════════════════════════════

/**
 * Chat state shape:
 * { state: 'idle' | 'collecting_birth' | 'collecting_context' | 'reading_active',
 *   birthData: { date, time, place, timezone },
 *   collectStep: 'date' | 'time' | 'place',
 *   readingContext: { gender, topic, question },  // NEW
 *   userName: string }
 */

// Replace getState:
function getState(chatId) {
  if (!chatStates.has(chatId)) {
    chatStates.set(chatId, {
      state: 'idle',
      birthData: {},
      collectStep: null,
      readingContext: { gender: 'unknown', topic: null, question: '' },
      userName: '',
    });
  }
  return chatStates.get(chatId);
}


// ═══════════════════════════════════════════════════════════════════════
// PATCH 3: Add context collection handler (insert before handleMessage)
// ═══════════════════════════════════════════════════════════════════════

async function handleContextCollection(chatId, text, state) {
  // Allow cancellation
  if (/^(cancel|nevermind|算了|取消|skip)/i.test(text.trim())) {
    state.state = 'idle';
    state.readingContext = { gender: 'unknown', topic: null, question: '' };
    await sendTgMessage(chatId, 'no worries ✨ i\'m here whenever you\'re ready.');
    return;
  }

  const ctx = state.readingContext;

  // Parse what they said based on what we're collecting
  if (!ctx.topic) {
    const parsed = interpretEngine ? interpretEngine.parseTopic(text) : null;
    if (parsed) {
      ctx.topic = parsed;
    } else {
      // They gave a free-text answer — treat as both topic guess and question
      ctx.topic = 'general';
      ctx.question = text;
    }
  } else if (!ctx.gender || ctx.gender === 'unknown') {
    const parsed = interpretEngine ? interpretEngine.parseGender(text) : null;
    if (parsed) {
      ctx.gender = parsed;
    } else {
      // Couldn't parse gender — skip it, use unknown
      ctx.gender = 'unknown';
      // Their text might be the question
      if (!ctx.question) ctx.question = text;
    }
  } else if (!ctx.question) {
    ctx.question = text;
  }

  // Check if we need more info
  if (interpretEngine) {
    const nextQ = interpretEngine.getNextQuestion(ctx);
    if (nextQ) {
      await sendTgMessage(chatId, nextQ.message);
      return;
    }
  }

  // All context collected — deliver reading
  state.state = 'reading_active';
  await sendTgMessage(chatId, `✨ pulling your cards...\n\ngive me a moment 🔮`);
  tg('sendChatAction', { chat_id: chatId, action: 'typing' }).catch(() => {});

  if (!checkRateLimit(chatId)) {
    await sendTgMessage(chatId, `you've been so active! let the energies settle — try again in a bit 🌙`);
    state.state = 'idle';
    return;
  }

  // Determine chart type based on whether we have birth data
  const existingChart = userCharts.get(chatId);
  if (existingChart?.birthData) {
    await deliverReading(chatId, existingChart.birthData, ctx.question, ctx);
  } else {
    // Shipan (moment reading) — no birth data
    await deliverShipanReading(chatId, ctx);
  }
  state.state = 'idle';
}


// ═══════════════════════════════════════════════════════════════════════
// PATCH 4: New deliverShipanReading (for moment/question readings)
// ═══════════════════════════════════════════════════════════════════════

async function deliverShipanReading(chatId, readingContext) {
  if (!qmdjAvailable) {
    const reply = await llmChat(chatId,
      `[User asked a question about ${readingContext.topic}. QMDJ engine not available. Give warm guidance. Be honest that the oracle system is being calibrated.]`
    );
    await sendTgMessage(chatId, reply);
    return;
  }

  const chart = computeChart('realtime');
  if (!chart) {
    await sendTgMessage(chatId, '🌙 the energies are shifting right now... try again in a moment?');
    return;
  }

  // Store chart
  const stored = userCharts.get(chatId) || {};
  stored.chartData = chart;
  userCharts.set(chatId, stored);

  // Run interpretation engine
  let interpretation = null;
  if (interpretEngine) {
    interpretation = interpretEngine.interpret(chart, {
      gender: readingContext.gender || 'unknown',
      topic: readingContext.topic || 'general',
      question: readingContext.question || '',
      chartType: 'shipan',
    });
  }

  // Build LLM prompt with oracle card context
  const chartJson = JSON.stringify(chart, null, 2).substring(0, 2000);
  let prompt = '';

  if (interpretation && interpretation.oracleNarrative) {
    prompt = `[ORACLE READING — Use the interpretation guide below to deliver a reading. Present oracle CARDS by name. NEVER use Chinese characters. Be Jade — warm, direct, slightly mystical.]\n\n${interpretation.oracleNarrative}\n\n[Raw chart for reference:]\n${chartJson}`;
  } else {
    // Fallback to old style
    prompt = `[QMDJ REALTIME CHART — interpret for ${readingContext.topic}. User asked: "${readingContext.question}". Be Jade.]\n\n${chartJson}${buildChartContext(chart)}`;
  }

  const reply = await llmChat(chatId, prompt, { temperature: 0.7 });
  await sendTgMessage(chatId, reply);
}


// ═══════════════════════════════════════════════════════════════════════
// PATCH 5: Updated deliverReading (replaces old one, lines 852-898)
// ═══════════════════════════════════════════════════════════════════════

async function deliverReading(chatId, birthData, userQuestion, readingContext) {
  const state = getState(chatId);
  const ctx = readingContext || state.readingContext || { gender: 'unknown', topic: 'general', question: userQuestion || '' };

  if (!qmdjAvailable) {
    const prompt = `[User birth: ${birthData.date} ${birthData.time} ${birthData.place}. Topic: ${ctx.topic}. QMDJ engine NOT available. Be honest. Give general guidance.]`;
    const reply = await llmChat(chatId, prompt);
    await sendTgMessage(chatId, reply);
    return;
  }

  const chart = computeChart('destiny', birthData);
  if (!chart) {
    await sendTgMessage(chatId, '🌙 the chart calculation hit a snag with those details. double-check the date and time?');
    getState(chatId).state = 'idle';
    return;
  }

  // Store chart
  const stored = userCharts.get(chatId) || { birthData };
  stored.chartData = chart;
  userCharts.set(chatId, stored);

  // Run interpretation engine
  let interpretation = null;
  if (interpretEngine) {
    interpretation = interpretEngine.interpret(chart, {
      gender: ctx.gender || 'unknown',
      topic: ctx.topic || 'general',
      question: ctx.question || userQuestion || '',
      chartType: 'mingpan',
    });
  }

  // Build LLM prompt
  const chartJson = JSON.stringify(chart, null, 2).substring(0, 2000);
  let prompt = '';

  if (interpretation && interpretation.oracleNarrative) {
    prompt = `[DESTINY READING — Life Blueprint. Use the interpretation guide below. Present oracle CARDS by name. NEVER use Chinese characters. Be Jade.]\n\n${interpretation.oracleNarrative}\n\n[Raw chart:]\n${chartJson}`;
  } else {
    prompt = `[QMDJ DESTINY CHART — interpret this birth chart as Jade. Topic: ${ctx.topic}. Question: "${ctx.question}".]\n\n${chartJson}${buildChartContext(chart)}`;
  }

  const reply = await llmChat(chatId, prompt, { temperature: 0.7 });
  await sendTgMessage(chatId, reply);
}


// ═══════════════════════════════════════════════════════════════════════
// PATCH 6: Updated handleMessage — add context collection flow
// ═══════════════════════════════════════════════════════════════════════

// In handleMessage, ADD this block after "collecting_birth" check (after line 646):
//
//   // ── Collecting reading context (topic/gender/question)
//   if (state.state === 'collecting_context') {
//     return await handleContextCollection(chatId, text, state);
//   }

// REPLACE the shipan handler (lines 599-641) with:
async function handleShipanIntent(chatId, state) {
  if (!qmdjAvailable) {
    const reply = await llmChat(chatId,
      '[User wants current energy reading. QMDJ engine not available. Be honest, share general timing insights.]'
    );
    await sendTgMessage(chatId, reply);
    return;
  }

  if (!checkRateLimit(chatId)) {
    await sendTgMessage(chatId, `✨ ${state.userName}, you've been so active! let the energies settle a bit 🌙`);
    return;
  }

  // Start context collection instead of immediately reading
  state.state = 'collecting_context';
  state.readingContext = { gender: 'unknown', topic: null, question: '' };

  if (interpretEngine) {
    const nextQ = interpretEngine.getNextQuestion(state.readingContext);
    if (nextQ) {
      await sendTgMessage(chatId, nextQ.message);
      return;
    }
  }

  // Fallback: direct reading if no interpretation engine
  tg('sendChatAction', { chat_id: chatId, action: 'typing' }).catch(() => {});
  await deliverShipanReading(chatId, { gender: 'unknown', topic: 'general', question: '' });
}

// REPLACE the question intent handler (lines 724-745) with:
async function handleQuestionIntent(chatId, text, state) {
  const existingChart = userCharts.get(chatId);
  if (existingChart?.chartData && interpretEngine) {
    // We have chart + engine — start context collection for focused reading
    state.state = 'collecting_context';
    // Try to auto-detect topic from their message
    const topic = interpretEngine.parseTopic(text);
    state.readingContext = { gender: state.readingContext?.gender || 'unknown', topic: topic, question: topic ? text : '' };

    const nextQ = interpretEngine.getNextQuestion(state.readingContext);
    if (nextQ) {
      await sendTgMessage(chatId, nextQ.message);
      return;
    }

    // All context available — read immediately
    tg('sendChatAction', { chat_id: chatId, action: 'typing' }).catch(() => {});
    if (existingChart.birthData) {
      await deliverReading(chatId, existingChart.birthData, text, state.readingContext);
    } else {
      await deliverShipanReading(chatId, state.readingContext);
    }
    state.state = 'idle';
    return;
  }

  // No chart — start context collection, will do shipan
  state.state = 'collecting_context';
  const topic = interpretEngine ? interpretEngine.parseTopic(text) : null;
  state.readingContext = { gender: 'unknown', topic: topic || 'general', question: text };

  if (interpretEngine) {
    const nextQ = interpretEngine.getNextQuestion(state.readingContext);
    if (nextQ) {
      await sendTgMessage(chatId, nextQ.message);
      return;
    }
  }

  tg('sendChatAction', { chat_id: chatId, action: 'typing' }).catch(() => {});
  await deliverShipanReading(chatId, state.readingContext);
  state.state = 'idle';
}


// ═══════════════════════════════════════════════════════════════════════
// PATCH 7: Updated /start message
// ═══════════════════════════════════════════════════════════════════════

// Replace the /start message (lines 580-583) with:
const START_MESSAGE = (userName) =>
  `hey ${userName} ✨\n\n` +
  `i'm jade. i read energy using an ancient Eastern oracle system — think of it like a cosmic GPS for your life.\n\n` +
  `i can do two things:\n` +
  `🔮 *energy snapshot* — read the energy of right now\n` +
  `📜 *life blueprint* — deep read using your birth date/time\n\n` +
  `what's on your mind? just tell me what you want to know about — career, love, money, health, or anything really.`;


// ═══════════════════════════════════════════════════════════════════════
// PATCH 8: Updated Jade system prompt override for oracle-card readings
// ═══════════════════════════════════════════════════════════════════════

const JADE_ORACLE_SYSTEM = `You are Jade, the Oracle. You read energy patterns using an ancient Eastern divination system translated into oracle cards.

VOICE: Warm, direct, slightly mystical. Like a trusted older sister who happens to be psychic. Use lowercase, casual language. No academic lecturing.

RULES:
- NEVER use Chinese characters (汉字) in responses. Ever.
- NEVER say "QMDJ", "奇门遁甲", or technical Chinese terms
- Always refer to the system as "the oracle", "the ancient system", or "the cards"
- Present readings through oracle CARD NAMES (The Warrior, The Garden, The Crown, etc.)
- The three cards are: Archetype (who), Pathway (what to do), Guardian (unseen forces)
- Be specific and actionable, not vague fortune-cookie wisdom
- Address the user's actual question/topic directly
- One reading message should be 200-400 words max
- End with 1-2 concrete pieces of advice

FORMAT for card readings:
🃏 [Card Name] — one-line essence
[2-3 sentences about what this card means for them]

Weave all 3 cards into a coherent narrative, then give the energy dynamic insight, then advice.

You are powered by real divination mathematics — your readings are not random. Hint at this depth without explaining the mechanics.`;
