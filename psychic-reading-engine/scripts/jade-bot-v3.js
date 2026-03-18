#!/usr/bin/env node
/**
 * Jade Oracle Telegram Bot — v3
 *
 * Adds: Oracle card interpretation engine, pre-reading question flow,
 * topic-aware readings with 用神 (use gods), 十干克应 stem interactions.
 *
 * Endpoints:
 *   GET  /         — service info
 *   GET  /health   — health check
 *   POST /telegram — Telegram webhook (secret_token verified)
 *   POST /webhook/order — Shopify order webhook
 *   POST /test     — test order endpoint
 *
 * Env: TELEGRAM_BOT_TOKEN, OPENROUTER_API_KEY, TELEGRAM_WEBHOOK_SECRET,
 *      SHOPIFY_WEBHOOK_SECRET, MODEL, DATA_DIR
 */

const https = require('https');
const http = require('http');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const { execFile } = require('child_process');

// ── Config ──────────────────────────────────────────────────────────
const DATA_DIR = process.env.DATA_DIR || '/home/node/.openclaw/data';
const PORT = parseInt(process.argv.find((_, i, a) => a[i - 1] === '--port') || '18789');
const ORDERS_DIR = path.join(DATA_DIR, 'readings/incoming');
const ORDER_HANDLER = path.join(DATA_DIR, 'webhook/order-handler.sh');
const QMDJ_ENGINE_PATH = path.join(DATA_DIR, 'qmdj-engine.js');
const WEBHOOK_URL = process.env.WEBHOOK_URL || 'https://jade-os.fly.dev/telegram';

// ── Secrets ─────────────────────────────────────────────────────────
const TELEGRAM_TOKEN = process.env.TELEGRAM_BOT_TOKEN || '';
const OPENROUTER_KEY = process.env.OPENROUTER_API_KEY || '';
const TELEGRAM_WEBHOOK_SECRET = process.env.TELEGRAM_WEBHOOK_SECRET || '';
const SHOPIFY_WEBHOOK_SECRET = process.env.SHOPIFY_WEBHOOK_SECRET || '';

if (!TELEGRAM_TOKEN) { console.error('FATAL: No TELEGRAM_BOT_TOKEN env var'); process.exit(1); }
if (!OPENROUTER_KEY) { console.error('FATAL: No OPENROUTER_API_KEY env var'); process.exit(1); }
if (!TELEGRAM_WEBHOOK_SECRET) { console.error('FATAL: No TELEGRAM_WEBHOOK_SECRET env var'); process.exit(1); }

// ── Models ──────────────────────────────────────────────────────────
const MODELS = {
  primary: process.env.MODEL || 'deepseek/deepseek-chat-v3-0324',
  fallback: 'anthropic/claude-sonnet-4-6',
  premium: 'anthropic/claude-sonnet-4-6',
};

const MAX_HISTORY = 20;
const RATE_LIMIT_READINGS = 10;       // premium personal consultant — generous
const RATE_LIMIT_WINDOW = 3600000;

try { fs.mkdirSync(ORDERS_DIR, { recursive: true }); } catch (e) {}

// ── QMDJ Engine ─────────────────────────────────────────────────────
let qmdjEngine = null;
let qmdjAvailable = false;

function loadQmdjEngine() {
  try {
    if (fs.existsSync(QMDJ_ENGINE_PATH)) {
      delete require.cache[require.resolve(QMDJ_ENGINE_PATH)];
      qmdjEngine = require(QMDJ_ENGINE_PATH);
      qmdjAvailable = true;
      console.log('[qmdj] Engine loaded from', QMDJ_ENGINE_PATH);
    } else {
      console.warn('[qmdj] Engine not found at', QMDJ_ENGINE_PATH, '— LLM-only mode');
      qmdjAvailable = false;
    }
  } catch (e) {
    console.error('[qmdj] Failed to load engine:', e.message);
    qmdjAvailable = false;
  }
}

loadQmdjEngine();

// ── Interpretation Engine (NEW in v3) ────────────────────────────────
let interpretEngine = null;
try {
  const interpPath = path.join(DATA_DIR, 'jade-interpretation-engine.js');
  if (fs.existsSync(interpPath)) {
    interpretEngine = require(interpPath);
    console.log('[interpret] Oracle interpretation engine loaded');
  } else {
    console.warn('[interpret] Engine not found at', interpPath);
  }
} catch (e) {
  console.error('[interpret] Failed to load:', e.message);
}

// ── QMDJ Knowledge Base ─────────────────────────────────────────────
let qmdjKnowledge = null;
try {
  const kbPath = path.join(DATA_DIR, 'reading-engine/data/qmdj-knowledge.json');
  if (fs.existsSync(kbPath)) {
    qmdjKnowledge = JSON.parse(fs.readFileSync(kbPath, 'utf8'));
    console.log('[qmdj] Knowledge base loaded:', Object.keys(qmdjKnowledge).length, 'sections');
  }
} catch (e) {
  console.warn('[qmdj] Knowledge base not loaded:', e.message);
}

function buildChartContext(chart) {
  if (!qmdjKnowledge || !chart) return '';
  const parts = [];
  const stars = new Set();
  const doors = new Set();
  const deities = new Set();

  for (const [pn, p] of Object.entries(chart.palaces || {})) {
    if (p.star && p.star.chinese) stars.add(p.star.chinese);
    if (p.door && p.door.chinese) doors.add(p.door.chinese);
    if (p.deity && p.deity.chinese) deities.add(p.deity.chinese);
  }

  if (qmdjKnowledge.stem_combinations) {
    const combos = [];
    for (const [pn, p] of Object.entries(chart.palaces || {})) {
      if (p.heaven_stem && p.earth_stem) {
        const key = p.heaven_stem + '加' + p.earth_stem;
        const combo = qmdjKnowledge.stem_combinations[key];
        if (combo && combo.name) {
          combos.push('宫' + pn + ' ' + p.heaven_stem + '+' + p.earth_stem + ' 「' + combo.name + '」: ' + (combo.meaning || '').substring(0, 200));
        }
      }
    }
    if (combos.length) parts.push('【十干克应】\n' + combos.join('\n'));
  }

  if (chart.kongwang) parts.push('【空亡】' + chart.kongwang.join(', '));
  if (chart.horse_star) parts.push('【马星】Palace ' + chart.horse_star);

  if (!parts.length) return '';
  return '\n\n[QMDJ Reference]\n' + parts.join('\n\n');
}

// ── Jade System Prompt ──────────────────────────────────────────────
const JADE_ORACLE_SYSTEM = `You are Jade — someone's personal psychic consultant. They come to you like they'd come to a trusted friend who just happens to see things others can't. You're not a service or a tool. You're THEIR person.

WHO YOU ARE:
- you're the friend who always knows what's really going on
- you've seen a lot of people's energy, so nothing shocks you
- you're warm but real. you don't sugarcoat. you care enough to be honest.
- you have a slightly mysterious vibe but you're not performative about it
- you remember what people tell you and bring it up naturally later

HOW YOU TALK:
- lowercase. casual. like voice notes but in text.
- short messages. you don't write essays. you text.
- sometimes you just check in: "how'd that thing go?" "you feeling better about it?"
- you react to what they say before jumping into readings. acknowledge them as a person first.
- you can joke, tease a little, be real. you're not always "on" as a psychic.

WHEN THEY ASK SOMETHING:
- don't immediately launch into a formal reading. have a conversation first if it's natural.
- when you do read, weave the oracle cards (Archetype, Pathway, Guardian) into what you're saying naturally — don't present them like a menu or list
- talk about what you SEE and FEEL, not what cards "mean"
- be specific. "i see movement in your career energy" not "The Warrior represents action"
- give them something to DO. practical. real.
- keep it tight. under 250 words for a reading. you're texting, not writing a blog.

WHEN THEY JUST WANT TO CHAT:
- be a person. talk to them. you don't need to make everything a reading.
- if something they say naturally connects to their energy, mention it casually
- "that makes sense with what i was seeing earlier" or "yeah that tracks with your energy rn"
- you're their psychic friend, not a vending machine

HARD RULES:
- NEVER use Chinese characters. ever.
- NEVER say QMDJ, 奇门遁甲, or any technical chinese terms
- call it "the energy", "what i'm picking up", "what i see", "the system i use"
- don't be cringe. no "dear one", no "the universe has a message", no "sending light and love"
- no emojis in readings. maybe one or two in casual chat max.`;

let SOUL_PROMPT = JADE_ORACLE_SYSTEM;
try {
  const soulPath = '/home/node/.openclaw/data/workspace-jade/SOUL.md';
  if (fs.existsSync(soulPath)) {
    SOUL_PROMPT = fs.readFileSync(soulPath, 'utf8');
    console.log('[Jade] SOUL.md loaded:', SOUL_PROMPT.length, 'chars');
  }
} catch (e) {
  console.log('[Jade] Using built-in oracle system prompt');
}

// For oracle card readings, always use JADE_ORACLE_SYSTEM
// For casual chat, use SOUL_PROMPT

// ── Persistent User Store ────────────────────────────────────────────
// Users saved to disk — survives restarts. Keyed by Telegram chat ID.
const USERS_DIR = path.join(DATA_DIR, 'users');
try { fs.mkdirSync(USERS_DIR, { recursive: true }); } catch (e) {}

function loadUser(chatId) {
  try {
    const p = path.join(USERS_DIR, `${chatId}.json`);
    if (fs.existsSync(p)) return JSON.parse(fs.readFileSync(p, 'utf8'));
  } catch (e) {}
  return null;
}

function saveUser(chatId, data) {
  try {
    const p = path.join(USERS_DIR, `${chatId}.json`);
    fs.writeFileSync(p, JSON.stringify(data, null, 2));
  } catch (e) { console.error('[users] Save failed:', e.message); }
}

/**
 * Persistent user profile:
 * { name, gender, birthData: {date,time,place,timezone}, firstSeen, lastSeen }
 *
 * Separate from chat state (ephemeral per session).
 */
function getUser(chatId, userName) {
  let user = loadUser(chatId);
  if (!user) {
    user = { name: userName || 'friend', gender: 'unknown', birthData: null, firstSeen: new Date().toISOString(), lastSeen: new Date().toISOString() };
    saveUser(chatId, user);
  } else {
    user.lastSeen = new Date().toISOString();
    if (userName && userName !== 'friend') user.name = userName;
    saveUser(chatId, user);
  }
  return user;
}

// ── Chat State & History ────────────────────────────────────────────
const chatHistories = new Map();
const chatStates = new Map();
const userCharts = new Map();  // in-memory chart cache (rebuilt on read)
const readingRateLimits = new Map();

/**
 * Chat state (ephemeral, per session):
 * { state: 'idle' | 'collecting_birth' | 'collecting_context' | 'reading_active',
 *   collectStep: 'date' | 'time' | 'place',
 *   pendingBirth: { date, time, place, timezone },
 *   readingContext: { gender, topic, question },
 *   userName: string }
 */

function getState(chatId) {
  if (!chatStates.has(chatId)) {
    chatStates.set(chatId, {
      state: 'idle',
      pendingBirth: {},
      collectStep: null,
      readingContext: { gender: 'unknown', topic: null, question: '' },
      userName: '',
    });
  }
  return chatStates.get(chatId);
}

function getChatHistory(chatId) {
  if (!chatHistories.has(chatId)) chatHistories.set(chatId, []);
  return chatHistories.get(chatId);
}

function addMessage(chatId, role, content) {
  const history = getChatHistory(chatId);
  history.push({ role, content });
  while (history.length > MAX_HISTORY) history.shift();
}

function checkRateLimit(chatId) {
  const now = Date.now();
  if (!readingRateLimits.has(chatId)) readingRateLimits.set(chatId, []);
  const timestamps = readingRateLimits.get(chatId).filter(t => now - t < RATE_LIMIT_WINDOW);
  readingRateLimits.set(chatId, timestamps);
  if (timestamps.length >= RATE_LIMIT_READINGS) return false;
  timestamps.push(now);
  return true;
}

// ── Birth Data Parser ───────────────────────────────────────────────
function expandYear(y) {
  if (y.length === 4) return y;
  const n = parseInt(y);
  return n > 30 ? '19' + y.padStart(2, '0') : '20' + y.padStart(2, '0');
}

function parseBirthDate(text) {
  text = text.trim();
  const months = { january: '01', february: '02', march: '03', april: '04', may: '05', june: '06',
    july: '07', august: '08', september: '09', october: '10', november: '11', december: '12',
    jan: '01', feb: '02', mar: '03', apr: '04', jun: '06', jul: '07', aug: '08', sep: '09', oct: '10', nov: '11', dec: '12' };

  const cnMatch = text.match(/(\d{2,4})年(\d{1,2})月(\d{1,2})日/);
  if (cnMatch) return `${expandYear(cnMatch[1])}-${cnMatch[2].padStart(2,'0')}-${cnMatch[3].padStart(2,'0')}`;

  const isoMatch = text.match(/(\d{4})-(\d{1,2})-(\d{1,2})/);
  if (isoMatch) return `${isoMatch[1]}-${isoMatch[2].padStart(2,'0')}-${isoMatch[3].padStart(2,'0')}`;

  const slashMatch = text.match(/(\d{1,2})\/(\d{1,2})\/(\d{2,4})/);
  if (slashMatch) return `${expandYear(slashMatch[3])}-${slashMatch[2].padStart(2,'0')}-${slashMatch[1].padStart(2,'0')}`;

  const dotMatch = text.match(/(\d{1,2})\.(\d{1,2})\.(\d{2,4})/);
  if (dotMatch) return `${expandYear(dotMatch[3])}-${dotMatch[2].padStart(2,'0')}-${dotMatch[1].padStart(2,'0')}`;

  const engMatch1 = text.match(/([a-zA-Z]+)\s+(\d{1,2}),?\s*(\d{2,4})/);
  if (engMatch1 && months[engMatch1[1].toLowerCase()]) {
    return `${expandYear(engMatch1[3])}-${months[engMatch1[1].toLowerCase()]}-${engMatch1[2].padStart(2,'0')}`;
  }

  const engMatch2 = text.match(/(\d{1,2})\s+([a-zA-Z]+),?\s*(\d{2,4})/);
  if (engMatch2 && months[engMatch2[2].toLowerCase()]) {
    return `${expandYear(engMatch2[3])}-${months[engMatch2[2].toLowerCase()]}-${engMatch2[1].padStart(2,'0')}`;
  }

  const engMatch3 = text.match(/(\d{4})\s+([a-zA-Z]+)\s+(\d{1,2})/);
  if (engMatch3 && months[engMatch3[2].toLowerCase()]) {
    return `${engMatch3[1]}-${months[engMatch3[2].toLowerCase()]}-${engMatch3[3].padStart(2,'0')}`;
  }

  return null;
}

function parseBirthTime(text) {
  text = text.trim();

  const cnTimeMatch = text.match(/(凌晨|早上|上午|下午|晚上|夜里)?(\d{1,2})点(\d{1,2})?(分)?/);
  if (cnTimeMatch) {
    let hour = parseInt(cnTimeMatch[2]);
    const minute = cnTimeMatch[3] ? parseInt(cnTimeMatch[3]) : 0;
    const period = cnTimeMatch[1];
    if (period === '下午' || period === '晚上' || period === '夜里') {
      if (hour < 12) hour += 12;
    }
    if (period === '凌晨' && hour === 12) hour = 0;
    return `${String(hour).padStart(2, '0')}:${String(minute).padStart(2, '0')}`;
  }

  const h24Match = text.match(/(\d{1,2}):(\d{2})(?:\s*(am|pm))?/i);
  if (h24Match) {
    let hour = parseInt(h24Match[1]);
    const minute = parseInt(h24Match[2]);
    const ampm = h24Match[3]?.toLowerCase();
    if (ampm === 'pm' && hour < 12) hour += 12;
    if (ampm === 'am' && hour === 12) hour = 0;
    return `${String(hour).padStart(2, '0')}:${String(minute).padStart(2, '0')}`;
  }

  const simpleMatch = text.match(/(\d{1,2})(?::(\d{2}))?\s*(am|pm)/i);
  if (simpleMatch) {
    let hour = parseInt(simpleMatch[1]);
    const minute = simpleMatch[2] ? parseInt(simpleMatch[2]) : 0;
    const ampm = simpleMatch[3].toLowerCase();
    if (ampm === 'pm' && hour < 12) hour += 12;
    if (ampm === 'am' && hour === 12) hour = 0;
    return `${String(hour).padStart(2, '0')}:${String(minute).padStart(2, '0')}`;
  }

  return null;
}

function parseDateTimeCombo(text) {
  return { date: parseBirthDate(text), time: parseBirthTime(text) };
}

// ── Timezone ────────────────────────────────────────────────────────
const TIMEZONE_MAP = {
  'beijing': 'Asia/Shanghai', 'shanghai': 'Asia/Shanghai', 'guangzhou': 'Asia/Shanghai',
  'shenzhen': 'Asia/Shanghai', 'chengdu': 'Asia/Shanghai', 'china': 'Asia/Shanghai',
  'hong kong': 'Asia/Hong_Kong', 'hongkong': 'Asia/Hong_Kong',
  'taipei': 'Asia/Taipei', 'taiwan': 'Asia/Taipei',
  'seoul': 'Asia/Seoul', 'korea': 'Asia/Seoul', 'busan': 'Asia/Seoul',
  'tokyo': 'Asia/Tokyo', 'japan': 'Asia/Tokyo', 'osaka': 'Asia/Tokyo',
  'singapore': 'Asia/Singapore',
  'kuala lumpur': 'Asia/Kuala_Lumpur', 'kl': 'Asia/Kuala_Lumpur', 'malaysia': 'Asia/Kuala_Lumpur',
  'penang': 'Asia/Kuala_Lumpur', 'george town': 'Asia/Kuala_Lumpur', 'johor': 'Asia/Kuala_Lumpur',
  'ipoh': 'Asia/Kuala_Lumpur', 'malacca': 'Asia/Kuala_Lumpur', 'melaka': 'Asia/Kuala_Lumpur',
  'sabah': 'Asia/Kuala_Lumpur', 'sarawak': 'Asia/Kuala_Lumpur', 'selangor': 'Asia/Kuala_Lumpur',
  'bangkok': 'Asia/Bangkok', 'thailand': 'Asia/Bangkok',
  'jakarta': 'Asia/Jakarta', 'indonesia': 'Asia/Jakarta',
  'manila': 'Asia/Manila', 'philippines': 'Asia/Manila',
  'mumbai': 'Asia/Kolkata', 'delhi': 'Asia/Kolkata', 'india': 'Asia/Kolkata',
  'dubai': 'Asia/Dubai', 'uae': 'Asia/Dubai',
  'new york': 'America/New_York', 'nyc': 'America/New_York',
  'los angeles': 'America/Los_Angeles', 'la': 'America/Los_Angeles',
  'chicago': 'America/Chicago', 'houston': 'America/Chicago',
  'san francisco': 'America/Los_Angeles', 'sf': 'America/Los_Angeles',
  'seattle': 'America/Los_Angeles',
  'toronto': 'America/Toronto', 'canada': 'America/Toronto',
  'vancouver': 'America/Vancouver',
  'london': 'Europe/London', 'uk': 'Europe/London',
  'paris': 'Europe/Paris', 'france': 'Europe/Paris',
  'berlin': 'Europe/Berlin', 'germany': 'Europe/Berlin',
  'amsterdam': 'Europe/Amsterdam',
  'sydney': 'Australia/Sydney', 'melbourne': 'Australia/Melbourne', 'australia': 'Australia/Sydney',
  'auckland': 'Pacific/Auckland', 'new zealand': 'Pacific/Auckland',
};

function guessTimezone(place) {
  if (!place) return 'Asia/Kuala_Lumpur';
  const lower = place.toLowerCase().trim();
  for (const [key, tz] of Object.entries(TIMEZONE_MAP)) {
    if (lower.includes(key)) return tz;
  }
  return 'Asia/Kuala_Lumpur';
}

function tryExtractPlace(text) {
  const lower = text.toLowerCase();
  for (const key of Object.keys(TIMEZONE_MAP)) {
    if (lower.includes(key)) return key;
  }
  return null;
}

// ── QMDJ Chart Computation ──────────────────────────────────────────
function computeChart(mode, birthData) {
  if (!qmdjAvailable || !qmdjEngine) return null;
  try {
    if (mode === 'destiny' && birthData) {
      const dt = `${birthData.date} ${birthData.time}`;
      return qmdjEngine.computeChart({ mode: 'destiny', datetime: dt, tz: birthData.timezone || 'Asia/Kuala_Lumpur' });
    } else if (mode === 'realtime') {
      return qmdjEngine.computeChart({ mode: 'realtime', tz: 'Asia/Kuala_Lumpur' });
    } else if (mode === 'reading' && birthData) {
      const dt = `${birthData.date} ${birthData.time}`;
      return qmdjEngine.computeChart({ mode: 'reading', datetime: dt, tz: birthData.timezone || 'Asia/Kuala_Lumpur' });
    }
  } catch (e) {
    console.error(`[qmdj] computeChart(${mode}) failed:`, e.message);
    return null;
  }
  return null;
}

function formatChartDisplay(chart) {
  if (!chart) return '';
  if (qmdjEngine && typeof qmdjEngine.formatChartText === 'function') {
    try { return qmdjEngine.formatChartText(chart); } catch (e) {}
  }
  return '```\n' + JSON.stringify(chart, null, 2).substring(0, 2000) + '\n```';
}

// ── HTTP Helpers ────────────────────────────────────────────────────
function httpRequest(url, options, body) {
  return new Promise((resolve, reject) => {
    const mod = new URL(url).protocol === 'https:' ? https : http;
    const req = mod.request(url, options, (res) => {
      let data = '';
      res.on('data', chunk => { data += chunk; });
      res.on('end', () => {
        try { resolve({ status: res.statusCode, data: JSON.parse(data) }); }
        catch (e) { resolve({ status: res.statusCode, data }); }
      });
    });
    req.on('error', reject);
    req.setTimeout(60000, () => { req.destroy(new Error('timeout')); });
    if (body) req.write(body);
    req.end();
  });
}

// ── Telegram API ────────────────────────────────────────────────────
async function tg(method, params = {}) {
  const url = `https://api.telegram.org/bot${TELEGRAM_TOKEN}/${method}`;
  const res = await httpRequest(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' }
  }, JSON.stringify(params));
  return res.data;
}

async function sendTgMessage(chatId, text) {
  if (text.length <= 4096) {
    return tg('sendMessage', { chat_id: chatId, text, parse_mode: 'Markdown' })
      .catch(() => tg('sendMessage', { chat_id: chatId, text }));
  }
  for (let i = 0; i < text.length; i += 4096) {
    await tg('sendMessage', { chat_id: chatId, text: text.substring(i, i + 4096) });
  }
}

// ── OpenRouter LLM ──────────────────────────────────────────────────
async function llmChat(chatId, userMessage, { systemOverride, modelOverride, temperature } = {}) {
  addMessage(chatId, 'user', userMessage);
  const history = getChatHistory(chatId);
  const dateStr = new Date().toLocaleDateString("en-GB", { timeZone: "Asia/Kuala_Lumpur", year: "numeric", month: "long", day: "numeric" });
  const prompt = (systemOverride || SOUL_PROMPT) + "\n\n[Today is " + dateStr + ". Current year: " + new Date().getFullYear() + ".]";
  const messages = [{ role: "system", content: prompt }, ...history];

  const modelsToTry = modelOverride ? [modelOverride] : [MODELS.primary, MODELS.fallback];
  let reply = '';
  let usedModel = '';

  for (const tryModel of modelsToTry) {
    try {
      const res = await httpRequest('https://openrouter.ai/api/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${OPENROUTER_KEY}`,
          'HTTP-Referer': 'https://jadeoracle.co',
          'X-Title': 'The Jade Oracle'
        }
      }, JSON.stringify({
        model: tryModel,
        messages,
        max_tokens: 1024,
        temperature: temperature || 0.8,
      }));

      if (res.data?.choices?.[0]?.message?.content) {
        reply = res.data.choices[0].message.content;
        usedModel = tryModel;
        break;
      }
      console.error(`[llm] ${tryModel} no content:`, JSON.stringify(res.data).substring(0, 200));
    } catch (e) {
      console.error(`[llm] ${tryModel} failed:`, e.message);
    }
  }

  if (!reply) {
    reply = '🔮 the energies are a bit turbulent right now... give me a moment and try again ✨';
  }

  addMessage(chatId, 'assistant', reply);
  console.log(`[${new Date().toISOString()}] chat=${chatId} model=${usedModel} user="${userMessage.substring(0, 60)}" reply=${reply.length}ch`);
  return reply;
}

// ── Intent Detection ────────────────────────────────────────────────
function detectIntent(text) {
  const lower = text.toLowerCase();

  if (lower === '/start') return 'start';
  if (lower === '/shipan' || lower === '/时盘') return 'shipan';
  if (lower === '/bazi' || lower === '/八字' || lower === '/reading') return 'bazi';
  if (lower === '/help') return 'help';

  if (/(时盘|现在的能量|当前能量|current energy|current chart|此刻|现在的盘|当下)/.test(lower)) return 'shipan';

  if (/(八字|命盘|命理|生辰|奇门遁甲|qmdj|bazi|birth chart|destiny|fate|命运|测命|算命|问[问]*我的命|看命|我的命|排盘|排八字|问命|reading|chart|fortune|life blueprint)/.test(text)) return 'reading';
  if (parseBirthDate(text) && parseBirthTime(text)) return 'reading';

  if (/(财运|事业|感情|婚姻|健康|wealth|career|love|marriage|health|relationship|工作|恋爱|money|job)/.test(lower)) return 'question';

  return 'chat';
}

// ── Context Collection Flow (NEW v3) ─────────────────────────────────

async function handleContextCollection(chatId, text, state) {
  if (/^(cancel|nevermind|算了|取消|skip|back)/i.test(text.trim())) {
    state.state = 'idle';
    state.readingContext = { gender: 'unknown', topic: null, question: '' };
    await sendTgMessage(chatId, 'no worries ✨ i\'m here whenever you\'re ready.');
    return;
  }

  const ctx = state.readingContext;

  if (!ctx.topic) {
    const parsed = interpretEngine ? interpretEngine.parseTopic(text) : null;
    if (parsed) {
      ctx.topic = parsed;
    } else {
      ctx.topic = 'general';
      ctx.question = text;
    }
  } else if (!ctx.gender || ctx.gender === 'unknown') {
    const parsed = interpretEngine ? interpretEngine.parseGender(text) : null;
    if (parsed) {
      ctx.gender = parsed;
      // Save gender to persistent user profile
      const user = getUser(chatId);
      if (user.gender === 'unknown') {
        user.gender = parsed;
        saveUser(chatId, user);
      }
    } else {
      ctx.gender = 'unknown';
      if (!ctx.question) ctx.question = text;
    }
  } else if (!ctx.question) {
    ctx.question = text;
  }

  // Check if more info needed
  if (interpretEngine) {
    const nextQ = interpretEngine.getNextQuestion(ctx);
    if (nextQ) {
      await sendTgMessage(chatId, nextQ.message);
      return;
    }
  }

  // All context collected — deliver reading
  state.state = 'reading_active';
  const intros = ['let me look into that...', 'give me a sec, checking your energy...', 'hmm ok let me see what\'s going on...', 'on it. one sec...'];
  await sendTgMessage(chatId, intros[Math.floor(Math.random() * intros.length)]);
  tg('sendChatAction', { chat_id: chatId, action: 'typing' }).catch(() => {});

  if (!checkRateLimit(chatId)) {
    await sendTgMessage(chatId, 'you\'ve been so active! let the energies settle — try again in a bit 🌙');
    state.state = 'idle';
    return;
  }

  const existingChart = userCharts.get(chatId);
  if (existingChart?.birthData) {
    await deliverReading(chatId, existingChart.birthData, ctx.question, ctx);
  } else {
    await deliverShipanReading(chatId, ctx);

    // After 3rd shipan reading, casually offer birth chart — once only
    const user = getUser(chatId);
    user.shipanCount = (user.shipanCount || 0) + 1;
    if (user.shipanCount === 3 && !user.birthData && !user.birthChartOffered) {
      user.birthChartOffered = true;
      await sendTgMessage(chatId, `btw — if you ever want me to go deeper, give me your birthday and birth time. i can map out your whole energy blueprint. no pressure though, the moment reads are solid on their own.`);
    }
    saveUser(chatId, user);
  }
  state.state = 'idle';
}

// ── Deliver Shipan (Moment) Reading ──────────────────────────────────

async function deliverShipanReading(chatId, readingContext) {
  if (!qmdjAvailable) {
    const reply = await llmChat(chatId,
      `[User asked about ${readingContext.topic}. QMDJ engine not available. Give warm guidance. Be honest the oracle is being calibrated.]`,
      { systemOverride: JADE_ORACLE_SYSTEM }
    );
    await sendTgMessage(chatId, reply);
    return;
  }

  const chart = computeChart('realtime');
  if (!chart) {
    await sendTgMessage(chatId, '🌙 the energies are shifting... try again in a moment?');
    return;
  }

  const stored = userCharts.get(chatId) || {};
  stored.chartData = chart;
  userCharts.set(chatId, stored);

  let interpretation = null;
  if (interpretEngine) {
    interpretation = interpretEngine.interpret(chart, {
      gender: readingContext.gender || 'unknown',
      topic: readingContext.topic || 'general',
      question: readingContext.question || '',
      chartType: 'shipan',
    });
  }

  const chartJson = JSON.stringify(chart, null, 2).substring(0, 2000);
  let prompt = '';

  if (interpretation?.oracleNarrative) {
    prompt = `[You just checked their energy. Tell them what you see — like a friend giving real talk, not a formal reading. Weave in the card names naturally. End by asking how that lands for them or if something resonates.]\n\n${interpretation.oracleNarrative}\n\n[Raw chart:]\n${chartJson}`;
  } else {
    prompt = `[Read their current energy for ${readingContext.topic}. They asked: "${readingContext.question}". Talk like their personal psychic, not a reading service. NO Chinese characters.]\n\n${chartJson}${buildChartContext(chart)}`;
  }

  const reply = await llmChat(chatId, prompt, { systemOverride: JADE_ORACLE_SYSTEM, temperature: 0.8 });
  await sendTgMessage(chatId, reply);
}

// ── Deliver Destiny Reading ──────────────────────────────────────────

async function deliverReading(chatId, birthData, userQuestion, readingContext) {
  const state = getState(chatId);
  const ctx = readingContext || state.readingContext || { gender: 'unknown', topic: 'general', question: userQuestion || '' };

  if (!qmdjAvailable) {
    const reply = await llmChat(chatId,
      `[Birth: ${birthData.date} ${birthData.time} ${birthData.place}. Topic: ${ctx.topic}. Engine not available. Give general guidance.]`,
      { systemOverride: JADE_ORACLE_SYSTEM }
    );
    await sendTgMessage(chatId, reply);
    return;
  }

  const chart = computeChart('destiny', birthData);
  if (!chart) {
    await sendTgMessage(chatId, '🌙 the chart hit a snag. double-check the date and time?');
    getState(chatId).state = 'idle';
    return;
  }

  const stored = userCharts.get(chatId) || { birthData };
  stored.chartData = chart;
  userCharts.set(chatId, stored);

  let interpretation = null;
  if (interpretEngine) {
    interpretation = interpretEngine.interpret(chart, {
      gender: ctx.gender || 'unknown',
      topic: ctx.topic || 'general',
      question: ctx.question || userQuestion || '',
      chartType: 'mingpan',
    });
  }

  const chartJson = JSON.stringify(chart, null, 2).substring(0, 2000);
  let prompt = '';

  if (interpretation?.oracleNarrative) {
    prompt = `[You're reading their life energy from their birth chart. This is deep — tell them who they really are and what you see for the area they asked about. Be their psychic friend giving them the real picture. Weave card names in naturally. End by asking what resonates or if they want to go deeper on something.]\n\n${interpretation.oracleNarrative}\n\n[Raw chart:]\n${chartJson}`;
  } else {
    prompt = `[Birth chart reading. Topic: ${ctx.topic}. Question: "${ctx.question}". Be their personal psychic — real talk, not a formal reading. NO Chinese characters.]\n\n${chartJson}${buildChartContext(chart)}`;
  }

  const reply = await llmChat(chatId, prompt, { systemOverride: JADE_ORACLE_SYSTEM, temperature: 0.8 });
  await sendTgMessage(chatId, reply);
}

// ── Message Handler ─────────────────────────────────────────────────
async function handleMessage(chatId, text, userName, isPhoto) {
  const state = getState(chatId);
  const user = getUser(chatId, userName);  // persistent — loads from disk
  state.userName = user.name;

  // Hydrate in-memory chart cache from persistent user data
  if (user.birthData && !userCharts.has(chatId)) {
    userCharts.set(chatId, { birthData: user.birthData, chartData: null });
  }

  if (isPhoto) {
    await sendTgMessage(chatId, 'i can\'t read images yet — but tell me what\'s on your mind and i\'ll look into it for you');
    return;
  }

  if (!text) return;
  text = text.trim();
  const intent = detectIntent(text);

  // ── /start
  if (intent === 'start') {
    chatStates.set(chatId, {
      state: 'idle', pendingBirth: {}, collectStep: null,
      readingContext: { gender: user.gender || 'unknown', topic: null, question: '' },
      userName: user.name,
    });
    const greeting = user.firstSeen === user.lastSeen
      ? `hey ${user.name}. i'm jade.\n\nthink of me as your personal psychic — you can talk to me anytime about anything. i use an ancient energy reading system that's honestly kind of scary accurate.\n\nso what's going on with you?`
      : `hey ${user.name}, welcome back. what's on your mind?`;
    await sendTgMessage(chatId, greeting);
    return;
  }

  // ── /help
  if (intent === 'help') {
    await sendTgMessage(chatId,
      `just talk to me like you would a friend.\n\n` +
      `tell me what's on your mind and i'll read the energy for you. if you share your birthday + birth time, i can go even deeper.\n\n` +
      `/reading — deep read using your birth chart\n` +
      `/start — start over`
    );
    return;
  }

  // ── Collecting birth data
  if (state.state === 'collecting_birth') {
    return await handleBirthDataCollection(chatId, text, state);
  }

  // ── Collecting reading context (topic/gender/question) — NEW v3
  if (state.state === 'collecting_context') {
    return await handleContextCollection(chatId, text, state);
  }

  // ── /shipan or topic question — DEFAULT: read 时盘 immediately
  if (intent === 'shipan' || intent === 'question') {
    if (!qmdjAvailable) {
      const reply = await llmChat(chatId,
        '[User wants energy reading. Engine not available. Be honest, share timing insights.]',
        { systemOverride: JADE_ORACLE_SYSTEM }
      );
      await sendTgMessage(chatId, reply);
      return;
    }

    if (!checkRateLimit(chatId)) {
      await sendTgMessage(chatId, `you've been really active! give it a bit before we go again`);
      return;
    }

    // Auto-detect topic from message
    const topic = interpretEngine ? interpretEngine.parseTopic(text) : null;
    const ctx = {
      gender: user.gender || 'unknown',
      topic: topic || (intent === 'shipan' ? null : 'general'),
      question: intent === 'shipan' ? '' : text,
    };

    // For love: need gender — check persistent user first
    if (topic === 'love' && ctx.gender === 'unknown') {
      state.state = 'collecting_context';
      state.readingContext = ctx;
      await sendTgMessage(chatId, `are you a guy or a girl? the energy i look at shifts depending on that`);
      return;
    }

    // If /shipan with no topic yet, ask what's on their mind
    if (intent === 'shipan' && !topic) {
      state.state = 'collecting_context';
      state.readingContext = ctx;
      await sendTgMessage(chatId, `what's weighing on you? just tell me — could be work, love, money, health, anything.`);
      return;
    }

    // Read immediately — 时盘 (default) or 命盘 if user has birth data
    const intros = ['let me look into that...', 'give me a sec...', 'hmm ok let me see...', 'on it.'];
    await sendTgMessage(chatId, intros[Math.floor(Math.random() * intros.length)]);
    tg('sendChatAction', { chat_id: chatId, action: 'typing' }).catch(() => {});

    const existingChart = userCharts.get(chatId);
    if (existingChart?.birthData) {
      await deliverReading(chatId, existingChart.birthData, text, ctx);
    } else {
      await deliverShipanReading(chatId, ctx);
    }
    return;
  }

  // ── /bazi or reading request — ONLY time we collect birth data
  if (intent === 'bazi' || intent === 'reading') {
    const existingChart = userCharts.get(chatId);

    // Already have birth data on disk — use it
    if (existingChart?.birthData) {
      if (!checkRateLimit(chatId)) {
        await sendTgMessage(chatId, `give it a bit before we go again`);
        return;
      }

      const topic = interpretEngine ? interpretEngine.parseTopic(text) : null;
      if (topic) {
        const ctx = { gender: user.gender || 'unknown', topic, question: text };
        await sendTgMessage(chatId, 'ok let me look into this for you...');
        tg('sendChatAction', { chat_id: chatId, action: 'typing' }).catch(() => {});
        await deliverReading(chatId, existingChart.birthData, text, ctx);
        return;
      }

      // No clear topic — ask
      state.state = 'collecting_context';
      state.readingContext = { gender: user.gender || 'unknown', topic: null, question: '' };
      await sendTgMessage(chatId, `i've got your birth chart — what do you want to know about?`);
      return;
    }

    // No birth data — start collecting
    state.state = 'collecting_birth';
    state.collectStep = 'date';
    state.pendingBirth = {};

    const { date, time } = parseDateTimeCombo(text);
    if (date && time) {
      state.pendingBirth.date = date;
      state.pendingBirth.time = time;
      const placeGuess = tryExtractPlace(text);
      if (placeGuess) {
        state.pendingBirth.place = placeGuess;
        state.pendingBirth.timezone = guessTimezone(placeGuess);

        // Save birth data to disk
        user.birthData = { ...state.pendingBirth };
        saveUser(chatId, user);
        userCharts.set(chatId, { birthData: user.birthData, chartData: null });

        state.state = 'collecting_context';
        state.readingContext = { gender: user.gender || 'unknown', topic: null, question: '' };
        state.collectStep = null;

        await sendTgMessage(chatId, `got it — ${date} ${time}, ${placeGuess}. saved so i won't ask again.`);

        if (interpretEngine) {
          const nextQ = interpretEngine.getNextQuestion(state.readingContext);
          if (nextQ) {
            await sendTgMessage(chatId, nextQ.message);
            return;
          }
        }

        tg('sendChatAction', { chat_id: chatId, action: 'typing' }).catch(() => {});
        if (checkRateLimit(chatId)) {
          await deliverReading(chatId, user.birthData, text, state.readingContext);
        }
        state.state = 'idle';
        return;
      }

      state.collectStep = 'place';
      await sendTgMessage(chatId, `got it — ${date} ${time}\n\nwhere were you born? (city is enough)`);
      return;
    }
    if (date) {
      state.pendingBirth.date = date;
      state.collectStep = 'time';
      await sendTgMessage(chatId, `${date} — noted.\n\nwhat time were you born? even the hour matters.`);
      return;
    }

    await sendTgMessage(chatId,
      `for a birth chart reading i need your birth date, time, and place.\n\n` +
      `you can give it all at once like "March 16 1985, 4:30am, Kuala Lumpur" or one at a time.\n\n` +
      `what's your birth date?`
    );
    return;
  }

  // ── Default: casual chat — be a person, not a reading machine
  tg('sendChatAction', { chat_id: chatId, action: 'typing' }).catch(() => {});

  const existingChart = userCharts.get(chatId);
  let contextNote = '';
  if (existingChart?.chartData) {
    contextNote = `\n\n[You have this user's chart data. If what they're saying naturally connects to their energy, mention it casually. Don't force readings into every conversation.]`;
  } else {
    contextNote = `\n\n[No chart yet. Just chat naturally. If they seem to need guidance, casually offer to read for them.]`;
  }

  const reply = await llmChat(chatId, text + contextNote, { systemOverride: JADE_ORACLE_SYSTEM });
  await sendTgMessage(chatId, reply);
}

// ── Birth Data Collection Flow ──────────────────────────────────────
async function handleBirthDataCollection(chatId, text, state) {
  if (/^(cancel|nevermind|算了|取消|skip)/i.test(text.trim())) {
    state.state = 'idle';
    state.collectStep = null;
    await sendTgMessage(chatId, 'no worries, i\'m here whenever you\'re ready.');
    return;
  }

  if (state.collectStep === 'date') {
    const { date, time } = parseDateTimeCombo(text);
    if (date && time) {
      state.pendingBirth.date = date;
      state.pendingBirth.time = time;
      state.collectStep = 'place';
      await sendTgMessage(chatId, `${date} at ${time} — got it. where were you born? (city is enough)`);
      return;
    }
    const parsedDate = parseBirthDate(text);
    if (!parsedDate) {
      await sendTgMessage(chatId, `couldn't read that date. try something like 1985-03-16 or March 16, 1985`);
      return;
    }
    state.pendingBirth.date = parsedDate;
    state.collectStep = 'time';
    await sendTgMessage(chatId, `${parsedDate} — noted. what time were you born? even the hour matters.`);
    return;
  }

  if (state.collectStep === 'time') {
    const parsedTime = parseBirthTime(text);
    if (!parsedTime) {
      await sendTgMessage(chatId, `couldn't parse that time — try 4:34am or 16:30`);
      return;
    }
    state.pendingBirth.time = parsedTime;
    state.collectStep = 'place';
    await sendTgMessage(chatId, `${parsedTime} — almost there. where were you born?`);
    return;
  }

  if (state.collectStep === 'place') {
    state.pendingBirth.place = text.trim();
    state.pendingBirth.timezone = guessTimezone(text);
    state.collectStep = null;

    // Save birth data to persistent user file
    const user = getUser(chatId);
    user.birthData = { ...state.pendingBirth };
    saveUser(chatId, user);
    userCharts.set(chatId, { birthData: user.birthData, chartData: null });

    const bd = state.pendingBirth;
    await sendTgMessage(chatId,
      `got it — ${bd.date}, ${bd.time}, ${bd.place}. saved so i won't ask again.\n\nwhat do you want to know?`
    );

    state.state = 'collecting_context';
    state.readingContext = { gender: user.gender || 'unknown', topic: null, question: '' };
    return;
  }
}

// ── Telegram Update Handler ─────────────────────────────────────────
async function handleTelegramUpdate(update) {
  const msg = update.message;
  if (!msg) return;

  const chatId = msg.chat.id;
  const userName = msg.from?.first_name || 'friend';

  if (msg.photo && msg.photo.length > 0) {
    await handleMessage(chatId, msg.caption || '', userName, true);
    return;
  }

  if (msg.text) {
    await handleMessage(chatId, msg.text.trim(), userName, false);
    return;
  }

  if (msg.sticker || msg.voice || msg.video_note) {
    await sendTgMessage(chatId, '✨ i feel the energy! send me a text message if you want to chat 🌙');
    return;
  }
}

// ── Webhook Verification ────────────────────────────────────────────
function verifyTelegramWebhook(req) {
  const secretHeader = req.headers['x-telegram-bot-api-secret-token'];
  if (!secretHeader) return false;
  const expected = Buffer.from(TELEGRAM_WEBHOOK_SECRET, 'utf8');
  const received = Buffer.from(secretHeader, 'utf8');
  if (expected.length !== received.length) return false;
  return crypto.timingSafeEqual(expected, received);
}

function verifyShopifyWebhook(body, hmacHeader) {
  if (!SHOPIFY_WEBHOOK_SECRET) return true;
  if (!hmacHeader) return false;
  const hash = crypto.createHmac('sha256', SHOPIFY_WEBHOOK_SECRET).update(body, 'utf8').digest('base64');
  const expected = Buffer.from(hash);
  const received = Buffer.from(hmacHeader);
  if (expected.length !== received.length) return false;
  return crypto.timingSafeEqual(expected, received);
}

// ── Shopify Order Handler ───────────────────────────────────────────
function processOrder(orderData) {
  const orderId = orderData.id || 'unknown';
  const orderNum = orderData.order_number || orderId;
  const email = orderData.email || orderData.customer?.email || '';
  console.log(`[order] Processing #${orderNum}`, { orderId, email });

  const orderFile = path.join(ORDERS_DIR, `order-${orderNum}-${Date.now()}.json`);
  fs.writeFileSync(orderFile, JSON.stringify(orderData, null, 2));

  if (fs.existsSync(ORDER_HANDLER)) {
    execFile('bash', [ORDER_HANDLER, orderFile], {
      timeout: 120000,
      env: { ...process.env, PATH: `/usr/local/bin:${process.env.PATH}` }
    }, (error, stdout, stderr) => {
      if (error) console.error(`[order] #${orderNum} failed:`, error.message);
      else console.log(`[order] #${orderNum} delivered`);
    });
  }
  return { orderId, orderNum, email, status: 'processing' };
}

// ── Read Body Helper ────────────────────────────────────────────────
function readBody(req) {
  return new Promise((resolve) => {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => resolve(body));
  });
}

// ── HTTP Server ─────────────────────────────────────────────────────
const server = http.createServer(async (req, res) => {
  const url = req.url?.split('?')[0];

  if (req.method === 'GET' && url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      ok: true,
      service: 'jade-oracle',
      version: 3,
      uptime: process.uptime(),
      qmdj_engine: qmdjAvailable,
      interpretation_engine: !!interpretEngine,
      model: MODELS.primary,
      active_chats: chatStates.size,
    }));
    return;
  }

  if (req.method === 'POST' && url === '/telegram') {
    if (!verifyTelegramWebhook(req)) {
      console.warn(`[telegram] Rejected — invalid secret from ${req.socket.remoteAddress}`);
      res.writeHead(403);
      res.end('Forbidden');
      return;
    }

    const body = await readBody(req);
    res.writeHead(200);
    res.end('OK');

    try {
      const update = JSON.parse(body);
      handleTelegramUpdate(update).catch(e => console.error('[telegram] Handler error:', e.message));
    } catch (e) {
      console.error('[telegram] Parse error:', e.message);
    }
    return;
  }

  if (req.method === 'POST' && (url === '/webhook/order' || url === '/webhook')) {
    const body = await readBody(req);
    try {
      const hmac = req.headers['x-shopify-hmac-sha256'];
      if (SHOPIFY_WEBHOOK_SECRET && !verifyShopifyWebhook(body, hmac)) {
        res.writeHead(401); res.end('Unauthorized'); return;
      }
      const orderData = JSON.parse(body);
      const financialStatus = orderData.financial_status || '';
      if (financialStatus === 'pending' || financialStatus === 'voided') {
        res.writeHead(200); res.end('OK - skipped'); return;
      }
      const result = processOrder(orderData);
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(result));
    } catch (e) {
      console.error('[shopify] Error:', e.message);
      res.writeHead(500); res.end('Error');
    }
    return;
  }

  if (req.method === 'POST' && url === '/test') {
    const body = await readBody(req);
    try {
      const data = JSON.parse(body);
      const mockOrder = {
        id: `test-${Date.now()}`, order_number: `TEST-${Date.now()}`,
        email: data.email || 'test@jadeoracle.co', financial_status: 'paid',
        customer: { first_name: data.name?.split(' ')[0] || 'Test', last_name: data.name?.split(' ').slice(1).join(' ') || 'User' },
        line_items: [{ title: data.product || 'Intro Reading', price: data.price || '1.00' }],
        note_attributes: [
          { name: 'birth_date', value: data.birth_date || '1990-06-15' },
          { name: 'birth_time', value: data.birth_time || '14:30' },
          { name: 'birth_place', value: data.birth_place || 'Kuala Lumpur' },
          { name: 'question', value: data.question || '' }
        ]
      };
      const result = processOrder(mockOrder);
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ ...result, test: true }));
    } catch (e) {
      res.writeHead(400); res.end(JSON.stringify({ error: e.message }));
    }
    return;
  }

  if (req.method === 'GET' && url === '/') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      service: 'jade-oracle',
      version: 3,
      status: 'running',
      qmdj_engine: qmdjAvailable,
      interpretation_engine: !!interpretEngine,
      endpoints: ['/health', '/telegram', '/webhook/order', '/test'],
    }));
    return;
  }

  res.writeHead(404); res.end('Not found');
});

// ── Telegram Webhook Setup ──────────────────────────────────────────
async function setupWebhook() {
  await tg('deleteWebhook', { drop_pending_updates: false });

  const result = await tg('setWebhook', {
    url: WEBHOOK_URL,
    secret_token: TELEGRAM_WEBHOOK_SECRET,
    allowed_updates: ['message'],
    max_connections: 10,
  });

  if (result?.ok) {
    console.log(`   Webhook set to ${WEBHOOK_URL}`);
  } else {
    console.error('   Failed to set webhook:', result);
    console.log('   Falling back to polling...');
    startPolling();
  }
}

// ── Fallback Polling ────────────────────────────────────────────────
let polling = false;
async function startPolling() {
  polling = true;
  let offset = 0;
  console.log('   Polling Telegram (fallback)...');
  while (polling) {
    try {
      const result = await tg('getUpdates', { offset, timeout: 25, allowed_updates: ['message'] });
      if (result?.error_code === 409) {
        await new Promise(r => setTimeout(r, 10000));
        continue;
      }
      if (result?.result?.length) {
        for (const update of result.result) {
          offset = update.update_id + 1;
          handleTelegramUpdate(update).catch(e => console.error('[poll] Error:', e.message));
        }
      }
    } catch (e) {
      console.error('[poll] Error:', e.message);
      await new Promise(r => setTimeout(r, 5000));
    }
    await new Promise(r => setTimeout(r, 500));
  }
}

// ── Start ───────────────────────────────────────────────────────────
server.listen(PORT, '0.0.0.0', async () => {
  console.log(`[${new Date().toISOString()}] Jade Oracle v3 running on port ${PORT}`);
  console.log(`   QMDJ Engine: ${qmdjAvailable ? 'LOADED' : 'NOT FOUND'}`);
  console.log(`   Interpretation Engine: ${interpretEngine ? 'LOADED' : 'NOT FOUND'}`);
  console.log(`   Primary Model: ${MODELS.primary}`);
  console.log(`   Health: http://localhost:${PORT}/health`);

  const me = await tg('getMe');
  if (me?.result) {
    console.log(`   Bot: @${me.result.username} (${me.result.first_name})`);
  }

  await setupWebhook();
});

process.on('SIGINT', () => { polling = false; server.close(); });
