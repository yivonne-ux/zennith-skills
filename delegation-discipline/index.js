// delegation-discipline - Agent routing and delegation guidance
// GAIA CORP-OS Skill for teaching when, how, and who to delegate

// Agent routing matrix
const AGENT_MATRIX = {
  myrmidons: {
    name: 'Myrmidons',
    role: 'Swarm Operations',
    focus: 'lookups, bulk processing, repetition, cross-channel, maintenance',
    keywordList: ['lookup', 'bulk', 'batch', 'process', 'organize', 'scan'],
  },
  taoz: {
    name: 'Taoz',
    role: 'Builder/Coder',
    focus: 'coding, building, debugging, system ops, deployment',
    keywordList: ['code', 'build', 'debug', 'fix', 'deploy', 'system'],
  },
  artemis: {
    name: 'Artemis',
    role: 'Scout/Researcher',
    focus: 'research, analysis, trends, external resources',
    keywordList: ['research', 'analyze', 'find', 'search', 'trend', 'market'],
  },
  dreami: {
    name: 'Dreami',
    role: 'Creative Director',
    focus: 'campaign strategy, creative briefs, cross-channel coherence',
    keywordList: ['campaign', 'creative', 'strategy', 'vision', 'coherence'],
  },
  artee: {
    name: 'Artee',
    role: 'Art Director',
    focus: 'visual design, brand consistency, image generation',
    keywordList: ['visual', 'design', 'brand', 'image', 'art', 'style'],
  },
  apollo: {
    name: 'Apollo',
    role: 'Copywriter',
    focus: 'copywriting, captions, ad copy, email, brand voice',
    keywordList: ['copy', 'caption', 'ad', 'email', 'brand voice', 'text'],
  },
  athena: {
    name: 'Athena',
    role: 'Strategist',
    focus: 'strategy, business model, growth, positioning',
    keywordList: ['strategy', 'business', 'growth', 'market', 'position'],
  },
  hermes: {
    name: 'Hermes',
    role: 'Merchant/Ads',
    focus: 'products, e-commerce, ads, pricing, sourcing',
    keywordList: ['product', 'shop', 'ads', 'pricing', 'commerce', 'source'],
  },
  iris: {
    name: 'Iris',
    role: 'Social & Visual',
    focus: 'social engagement, comments, visual content',
    keywordList: ['social', 'comment', 'engage', 'visual', 'user'],
  },
};

// Task type mapping
const TASK_MAP = {
  lookups: 'myrmidons',
  coding: 'taoz',
  research: 'artemis',
  creative: 'dreami',
  visual: 'artee',
  copy: 'apollo',
  strategy: 'athena',
  commerce: 'hermes',
  social: 'iris',
  ops: 'myrmidons',
};

// Token discipline rules
const TOKEN_DISCIPLINE = {
  maxLookupsBeforeDelegation: 3,
  maxItemsBeforeWriting: 5,
  shouldCompactAfter: 3,
};

/**
 * Determine which agent should handle a task
 * @param {string} taskDescription - Description of the task
 * @returns {string} Agent ID (myrmidons, taoz, artemis, etc.)
 */
function getTargetAgent(taskDescription) {
  const desc = taskDescription.toLowerCase();
  
  // Check each agent's keywords
  for (const [agentId, agent] of Object.entries(AGENT_MATRIX)) {
    for (const keyword of agent.keywordList) {
      if (desc.includes(keyword)) {
        return agentId;
      }
    }
  }
  
  // Default fallback
  return 'myrmidons';
}

/**
 * Check if task should be delegated based on complexity
 * @param {number} estimatedToolCalls - Estimated number of tool calls needed
 * @returns {boolean} True if should delegate
 */
function shouldDelegate(estimatedToolCalls) {
  return estimatedToolCalls > TOKEN_DISCIPLINE.maxLookupsBeforeDelegation;
}

/**
 * Generate delegation brief for agent
 * @param {Object} options
 * @param {string} options.task - Task description
 * @param {string} options.targetAgent - Target agent ID
 * @param {Object} options.params - Additional parameters
 * @returns {string} Brief for delegation
 */
function generateBrief(options) {
  const { task, targetAgent, params = {} } = options;
  const agent = AGENT_MATRIX[targetAgent];
  
  return `DELEGATE TO ${agent.name.toUpperCase()}:

Task: ${task}

Purpose: ${agent.focus}

Parameters: ${JSON.stringify(params)}

Begin work now. Return results in structured format.`;
}

/**
 * Check if task requires file writing instead of memory
 * @param {number} itemCount - Number of items to remember
 * @returns {boolean} True if should write to file
 */
function shouldWriteToFile(itemCount) {
  return itemCount > TOKEN_DISCIPLINE.maxItemsBeforeWriting;
}

/**
 * Get agent summary for quick reference
 * @param {string} agentId - Agent ID
 * @returns {Object} Agent summary
 */
function getAgentSummary(agentId) {
  return AGENT_MATRIX[agentId] || null;
}

/**
 * Get all agent IDs
 * @returns {Array} Array of agent IDs
 */
function getAllAgentIds() {
  return Object.keys(AGENT_MATRIX);
}

// Export functions
module.exports = {
  AGENT_MATRIX,
  TASK_MAP,
  TOKEN_DISCIPLINE,
  getTargetAgent,
  shouldDelegate,
  generateBrief,
  shouldWriteToFile,
  getAgentSummary,
  getAllAgentIds,
};
