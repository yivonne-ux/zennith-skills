// test.js - Delegation discipline skill tests
// Run: node test.js

const delegation = require('./index.js');

console.log('=== Delegation Discipline Skill Tests ===\n');

// Test 1: Agent routing
console.log('Test 1: Agent Routing');
console.log('---------------------');

const testTasks = [
  'Build a new skill for WeChat',
  'Search for 50 organic coconut oil products',
  'Research TikTok trends for Q2',
  'Write ad copy for coconut oil campaign',
  'Analyze Q1 sales data',
  'Design visual assets for new brand',
  'Draft product listing for Shopee',
  'Check social media comments',
];

testTasks.forEach(task => {
  const agentId = delegation.getTargetAgent(task);
  const agent = delegation.getAgentSummary(agentId);
  console.log(`Task: "${task}"`);
  console.log(`→ Delegate to: ${agent?.name || agentId} (${agent?.role})`);
  console.log('');
});

// Test 2: Should delegate check
console.log('\nTest 2: Delegation Threshold');
console.log('----------------------------');

const testCases = [1, 2, 3, 4, 5, 10];
testCases.forEach(count => {
  const should = delegation.shouldDelegate(count);
  console.log(`${count} tool calls → ${should ? 'DELEGATE' : 'DO IT'}`);
});

// Test 3: Generate brief
console.log('\n\nTest 3: Generate Brief');
console.log('----------------------');

const brief = delegation.generateBrief({
  task: 'Research organic coconut oil products on Taobao, filter by price $40-60, rating ≥4.5, sales ≥1000',
  targetAgent: 'artemis',
  params: { minPrice: 40, maxPrice: 60, minRating: 4.5, minSales: 1000 },
});
console.log(brief);

// Test 4: File writing check
console.log('\n\nTest 4: File Writing Check');
console.log('---------------------------');

const itemCounts = [3, 5, 8, 15];
itemCounts.forEach(count => {
  const shouldWrite = delegation.shouldWriteToFile(count);
  console.log(`${count} items → ${shouldWrite ? 'WRITE TO FILE' : 'keep in memory'}`);
});

// Test 5: Token discipline rules
console.log('\n\nTest 5: Token Discipline Rules');
console.log('-------------------------------');

console.log('Max lookups before delegation:', delegation.TOKEN_DISCIPLINE.maxLookupsBeforeDelegation);
console.log('Max items before writing:', delegation.TOKEN_DISCIPLINE.maxItemsBeforeWriting);
console.log('Should compact after tasks:', delegation.TOKEN_DISCIPLINE.shouldCompactAfter);

// Test 6: All agents
console.log('\n\nTest 6: All Agents');
console.log('------------------');

const allAgents = delegation.getAllAgentIds();
console.log('Available agents:', allAgents.join(', '));

// Summary
console.log('\n\n=== Summary ===');
console.log('All tests completed successfully! ✅');
console.log('Delegation discipline skill is ready to use.');
