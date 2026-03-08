#!/usr/bin/env bash
# classify.sh — Quick task classifier + auto-dispatcher for Zenni
# Wraps route-task.py with SOUL.md hardcoded override rules
# v2: --auto-dispatch flag executes dispatch directly (no LLM needed)
#
# Usage:
#   bash classify.sh "your task description" [--sender "+60126169979"] [--auto-dispatch] [--session-key "key"]
#
# Without --auto-dispatch (backward compat):
#   Outputs classification info for Zenni to read and act on
#
# With --auto-dispatch:
#   Classifies AND dispatches in one shot. Returns:
#     DISPATCHED:<agent>   — background dispatch started via openclaw agent
#     SCRIPT:<label>       — direct CLI execution (no LLM subagent needed). CMD: line has the command.
#     LOOKUP:<agent>       — lookup executed inline, result follows
#     RELAY:<agent>        — Zenni handles this herself (greetings, simple replies)
#     DENIED:<agent>       — sender not permitted for this agent

set -euo pipefail

TASK="${1:-}"
SENDER=""
AUTO_DISPATCH=false
SESSION_KEY=""

# Parse args
shift 2>/dev/null || true
while [ $# -gt 0 ]; do
  case "$1" in
    --sender) shift; SENDER="${1:-}" ;;
    --auto-dispatch) AUTO_DISPATCH=true ;;
    --session-key) shift; SESSION_KEY="${1:-}" ;;
  esac
  shift 2>/dev/null || true
done

if [[ -z "$TASK" ]]; then
  echo "Usage: classify.sh \"task description\" [--sender \"+60...\"] [--auto-dispatch]"
  exit 1
fi

TASK_LOWER=$(echo "$TASK" | tr '[:upper:]' '[:lower:]')
ROUTER="$HOME/.openclaw/workspace/scripts/routing/route-task.py"
OPENCLAW_CLI="$HOME/local/bin/openclaw"
LOG_DIR="$HOME/.openclaw/logs"
DISPATCH_LOG="$LOG_DIR/dispatch-log.jsonl"
mkdir -p "$LOG_DIR"

# ── HARDCODED OVERRIDES (from SOUL.md — these trump the router) ───────────────
# These patterns are so clear that we skip the router entirely.
# Ordered: most specific first.

classify_override() {
  local task="$1"

  # DIRECT AGENT MENTION: @taoz, /taoz, @dreami etc. → route directly (user override)
  if echo "$task" | grep -qiE '^(@|/)(taoz|dreami|artemis|athena|hermes|iris|argus|myrmidons)'; then
    local direct_agent
    direct_agent=$(echo "$task" | grep -oiE '(taoz|dreami|artemis|athena|hermes|iris|argus|myrmidons)' | head -1 | tr '[:upper:]' '[:lower:]')
    echo "$direct_agent"
    return 0
  fi

  # EXPLICIT CLAUDE CODE / TAOZ REQUEST: "use claude code", "ask taoz to", "tell taoz to" → taoz (auto-upgrades to CODE tier)
  # Catches user explicitly requesting Taoz or Claude Code CLI — MUST be before any other pattern
  if echo "$task" | grep -qiE '(use claude.?code|ask taoz|tell taoz|get taoz|have taoz|let taoz|make taoz|taoz (should|can|will|needs? to)|via claude.?code|through claude.?code|with claude.?code)'; then
    echo "taoz"
    return 0
  fi

  # ARGUS: testing, QA, regression — MUST check BEFORE brand-studio
  if echo "$task" | grep -qiE '(^run .*(test|regression|qa|e2e|nightly|review)|regression.?test|smoke.?test|sanity.?check|^test |qa .*(check|audit|run)|end.?to.?end.?test|check.?if.?(it |this )?work|^e2e |run.*regression|nightly.?review|run.*(nightly|review|audit))' && ! echo "$task" | grep -qiE '(contest|social media|latest|protest|fastest)'; then
    echo "argus"
    return 0
  fi

  # MULTI-STEP: "X then Y" patterns — route to the FIRST action's agent
  # Use "then" / "and then" only (NOT comma — commas cause false positives in long messages)
  if echo "$task" | grep -qiE '(research|find|scrape).*(then|and then).*(create|generate|make)'; then
    echo "artemis"
    return 0
  fi
  if echo "$task" | grep -qiE '(write|draft).*(copy|caption|script).*(then|and then).*(generate|create|make).*(visual|image|ad)'; then
    echo "dreami"
    return 0
  fi

  # SHARING / NOTION / SEND: share images/videos to Notion/WhatsApp/team → HERMES
  if echo "$task" | grep -qiE '(share|send|upload|push|post).*(to |into )?(notion|branding|team|group|whatsapp|gdrive|google drive)|(notion|gdrive).*(sync|upload|push|share|send)'; then
    echo "hermes"
    return 0
  fi

  # SELF-REFERENTIAL / META QUESTIONS → RELAY (Zenni answers about herself)
  # "what's your model", "how do you route", "what are you", "who are you"
  if echo "$task" | grep -qiE '(what.*(your|ur) (model|route|routing|name|version|config|system|role|agent)|how (do |did )?(you|u) (route|use|dispatch|classify|work|handle|process)|who are (you|u)|are (you|u) (on |using |running )|what model|which model|your (model|route|dispatch|config))'; then
    echo "main"
    return 0
  fi

  # INFO / HOW-TO QUESTIONS about workflows → RELAY (Zenni answers directly)
  # NOTE: "work" removed from pattern — was matching "working" in "is this URL working" (false positive)
  # "workflow" already catches workflow questions. Negative lookahead (?!...) removed — not supported by BSD grep.
  if echo "$task" | grep -qiE '^(what|which|how|where|when|why|can|does|do|is|are) .*(workflow|pipeline|tool|skill|process|step|use)' && ! echo "$task" | grep -qiE '(create|generate|make|build|run|launch|do|start|set up)'; then
    echo "main"
    return 0
  fi

  # SYSTEM CONFIG / BUILD / FIX WORKFLOW → TAOZ (builder owns all system changes)
  # configure, tune, build, fix, change, optimize any workflow/pipeline/routing/system
  if echo "$task" | grep -qiE '(configure|tune|adjust|modify|change|update|optimize|improve|speed up|fix|repair|debug).*(workflow|pipeline|routing|system|cron|automation|dispatch|classify|gateway|skill|infrastructure|config|generation|nanobanana|video.?gen|render)|(build|create|set up|add).*(new )?(workflow|pipeline|step|automation|cron|routing rule|skill)|(workflow|pipeline|routing|system|gateway|cron|automation|generation).*(broken|not working|failing|down|error|wrong|stuck|slow|issue|problem|bug)'; then
    echo "taoz"
    return 0
  fi

  # FAILURE ANALYSIS / WHY DID X FAIL → ATHENA (analyst investigates root cause)
  if echo "$task" | grep -qiE '(why did|why is|why are|what went wrong|what happened|root cause|diagnose|investigate).*(fail|crash|error|break|not work|stop|wrong|miss|lost|drop|decline|batch|campaign|ads?)|^why .*(fail|crash|not work|broken|error|miss)|what went wrong'; then
    echo "athena"
    return 0
  fi

  # RETRY / REDO / RERUN failed task → same agent that handles the task type
  if echo "$task" | grep -qiE '(retry|redo|rerun|re-run|try again|run again).*(campaign|ads?|generation|pipeline|batch)'; then
    echo "hermes"
    return 0
  fi

  # CAMPAIGN ORCHESTRATION: full campaign / batch campaign / 30+ ads → HERMES (not individual ad gen)
  # Hermes plans the campaign, then spawns Iris + Dreami in parallel
  if echo "$task" | grep -qiE '(full.?campaign|campaign.*(plan|brief|all|full|batch|launch|start|run)|launch.*(campaign|all.*(ad|type))|run.*(campaign|all)|[0-9][0-9]+.*(ads?|images?|visuals?).*(campaign|all|full|type|mix|includ|with)|campaign.*[0-9][0-9]+|all.*(ad|ads).*(type|format|kind)|campaign.*(with|includ).*(video|sora|kling))'; then
    echo "hermes"
    return 0
  fi

  # BRAND STUDIO: ad/image generation with brand awareness → iris
  # Handles single ad or small batch: "generate mirra ad", "generate 5 mirra ads"
  # For large campaigns (30+ ads, full campaign), routed to Hermes above
  if echo "$task" | grep -qiE '(create|generate|make).*(mirra|pinxin|wholey|serein|rasaya|gaia).*(ad|ads|image|visual|poster|banner|post|catalog|carousel|grid|comparison|hero|lifestyle|testimonial|persona|sales|promo|deal|urgency|price|raw|meme|product)|(create|generate|make).*[0-9]*.*(ad|ads|image|visual|poster|banner).*(mirra|pinxin|wholey|serein|rasaya|gaia)|brand.?studio|comparison.?ad|hero.?ad|grid.?ad|lifestyle.?ad'; then
    echo "iris"
    return 0
  fi

  # NEW TOOL / TUTORIAL / LEARNING / ANALYSIS → TAOZ (CODE tier)
  # When user sends links to new tools, tutorials, editors, or asks to "understand/analyze/check"
  # a new workflow/tool — this needs Claude Code (Opus) to deeply understand, NOT Dreami
  # Must be BEFORE creative pipeline rule to prevent "video workflow" matching dreami
  if echo "$task" | grep -qiE '(check.*(this|the) (editor|tool|app|platform|service|workflow|approach)|analy[sz]e.*(and |then )?(understand|discuss|report|learn|summarize)|understand.*(tool|editor|workflow|approach|method|technique|concept|video|pipeline|system)|what.*(we |are we |we.re )miss|tutorial|vpick|learn.*(how|about|from|this)|new.*(tool|editor|workflow|approach|method)|working on.*(this|a ).*(workflow|pipeline|approach)|please.*(analy[sz]e|understand|check).*(this|the|fully)|deep.?(research|dive|analy)|brainstorm.*(video|workflow|pipeline|tool|approach|method).*(option|idea|way|approach)|how.*(can|do|should).*(we|i).*(use|integrate|adopt|implement).*(this|the|it)|evaluate.*(tool|editor|platform|service|approach))' && ! echo "$task" | grep -qiE '(generate|create|make) (a |the )?(video|clip|reel|image|ad|poster)'; then
    echo "taoz"
    return 0
  fi

  # CHARACTER MODIFICATION: change hair, remove headgear, change outfit, redesign look → IRIS
  # These are visual edits to locked character images, need Art Director (Iris)
  if echo "$task" | grep -qiE '(change.*(hair|outfit|suit|look|style|cloth|headgear|helmet|armor|armour|dress|attire|accessori)|remove.*(headgear|helmet|armor|armour|hat|crown|mask|visor|accessori)|make.*(suit|outfit|look|cloth|dress|attire).*(sexi|cool|sleek|modern|casual|formal|dark|bright|different)|redesign.*(look|character|avatar|outfit)|update.*(look|character|avatar|outfit|hair|style)|modify.*(character|avatar|look|outfit|hair)|edit.*(character|avatar|look|outfit)|iris.*(hair|look|outfit|character|update|change|modify|edit|redesign)|character.*(change|modif|redesign|update|edit|rework).*(hair|look|outfit|style))'; then
    echo "iris"
    return 0
  fi

  # EVOMAP: evolution network commands → TAOZ (SCRIPT tier)
  # Catches: "evomap status", "publish to evomap", "run evolution cycle", "evomap heartbeat", "fetch capsules"
  if echo "$task" | grep -qiE '(evomap|evolve.?cycle|evolution.?(cycle|network)|gene.?capsule|publish.*(gene|capsule|learning).*evomap|fetch.*(capsule|gene).*evomap|evomap.*(status|heartbeat|publish|fetch|tasks|evolve))'; then
    echo "taoz"
    return 0
  fi

  # CLIP FACTORY: split/cut/clip/find/compose clips → IRIS (SCRIPT tier)
  # Catches: "split this video into clips", "extract highlights from podcast", "find inspiring clips", "compose highlight reel"
  # Route to iris (visual pipeline lead). Excluded: "fix clip factory" (goes to taoz via build rule above)
  if echo "$task" | grep -qiE '(clip|split|cut|chop|segment|highlight).*(video|long|podcast|vlog|interview)|fomofly|viral.?clip|short.?clip|clip.?factory.*(run|extract|analyze|produce|preview|find|compose)|extract.*(highlight|clip|best.?part|moment).*from|find.*(clip|hook|intro|highlight|broll)|compose.*(clip|video|reel|highlight|compilation)|assemble.*(clip|highlight|reel)|highlight.?reel|clip.?library|search.*clip|(split|cut|chop).*\.(mp4|mov|mkv|avi|webm)|(split|cut|chop).*into.*(clip|segment|short)' && ! echo "$task" | grep -qiE '(fix|debug|build|repair|broken|bug).*(clip.?factory|pipeline)'; then
    echo "iris"
    return 0
  fi

  # VIDEO COMPILER: create UGC video ads from briefs → IRIS (SCRIPT tier)
  # Catches: "compile video ad for mirra", "create ugc ads for bento", "make 3 video ad variants"
  # Distinguished from clip-factory (splits existing video) — video-compiler creates NEW ads from briefs
  if echo "$task" | grep -qiE '(video.?compiler|compile.*(video|ad)|video.?ad.*(creat|generat|make|build|produc)|ugc.?ad.*(creat|generat|make|build|produc)|(make|create|generate|produce|build).*(video|ugc).*(ad|variant|campaign).*for|batch.*(video|ugc).*(ad|variant|campaign)|(pas|slap|emotional|testimonial).*(framework|ad|video)|(3|5|10|multiple|batch).*(video|ugc|ad).*(variant|version)|video.?brief.*(run|execut|produc))' && ! echo "$task" | grep -qiE '(fix|debug|build|repair|broken|bug).*(video.?compiler|pipeline)'; then
    echo "iris"
    return 0
  fi

  # CREATIVE PIPELINE: video production + character creation → DREAMI
  if echo "$task" | grep -qiE '(intro.?video|self.?intro.?video|character.?intro|ugc.?video|product.?ugc|character.?lock|video.?pipeline|creative.?pipeline|video.?remake|remake.*(video|intro|clip)|make.*(intro|ugc).*(video|clip|reel)|make.*(a |the )?(video|clip|reel)|do .*(ugc|intro|product)|do .*bento.*ugc| ugc |^ugc |lock.*(character|face|avatar)|6.?sec.*(intro|video)|agent.*(intro|video)|brand.*(intro|ugc|video)|(zenni|artemis|athena|iris|dreami|hermes|taoz|argus).*(video|intro)|create.*(persona|avatar)|generate.*(character|persona)|character.*(lock|produc|pipeline)|make.*(character|persona)|sora.*(video|gen|prompt|ugc|content)|kling.*(video|gen)|wan.*(video|gen)|12.?angle|angle.?sheet|storyboard.*(gen|creat)|turn.*(into|to) .*(video|clip|reel|animation)|generate .*(a )?(clip|reel)|cr?ete.*(video|clip|reel)| video$|youtube.?shorts?|animat.*(logo|brand|intro|reveal)|logo.?reveal|recipe.?video|demo.?video|testimonial.?video|unboxing|before.?and.?after.*(video|clip)|how.?to.?video|comparison.?video|edit.*(video|clip).*(short|trim|cut)|a.?roll|b.?roll|aroll|broll|remotion|lottie)' && ! echo "$task" | grep -qiE '(how many video|video.*(performance|analytics|stats|result)|design.*(thumbnail|poster|banner|flyer).*(video|clip)|video thumbnail)'; then
    echo "dreami"
    return 0
  fi

  # MYRMIDONS: simple operations (check, list, git, file ops, format, ping, send, fetch files)
  if echo "$task" | grep -qiE '(check (if|on )|is (up|down|live|running)|is .*(url|link|site|page|domain|endpoint).*(working|up|down|live|broken)|(url|link|site|website|domain|endpoint).*(work|up|down|check|live|broken)|is this .*(working|up|down|live|broken)|git (status|log|push|pull|psh|commit|add)|^ping |health.?check|list files|move file|rename file|copy file|create dir|mkdir|reformat|convert (csv|json)|post (this|result|summary) to (room|exec|build|creative)|fetch (url|file)|read .*(file|md|json|dna) and|what.?s in |summarize this|who handles|where.*(save|store|put)|move .*(to|into) .*(folder|dir)|copy .*(to|into) .*(folder|dir)|organize .*(asset|file|folder)|create folder|read.*(brand )?(dna|DNA)|list.*(file|folder|asset)|what (file|folder)|check.*(room|gateway|system)|send (this |it )to |^hi$|^thanks|^ok |^yes$|^help$|^stop|^undo|what can you|(send|show|get|find|fetch|give|pull up|grab) (me |us )?(the |a |an )?(latest |recent |last |current )?(image|photo|picture|file|doc|pdf|video|logo|asset|character|avatar|poster|banner|screenshot|result|output).*(of |for |from )?(zenni|taoz|dreami|iris|hermes|athena|artemis|argus|mirra|pinxin|wholey|serein|rasaya|gaia)|(send|show|get|find|fetch|give) (me )?(zenni|taoz|dreami|iris|hermes|athena|artemis|argus|mirra|pinxin|wholey|serein|rasaya|gaia).*(image|photo|picture|file|logo|asset|character|avatar|poster)|(send|show|get|find|fetch|give) (me )?(the |a |an )?(zenni|taoz|dreami|iris|hermes|athena|artemis|argus|mirra|pinxin|wholey|serein|rasaya|gaia) ?(image|photo|picture|file|logo|asset|character|avatar|poster|banner|result|output))'; then
    echo "myrmidons"
    return 0
  fi

  # TAOZ: code and builds → route directly to Taoz
  if echo "$task" | grep -qiE '(write|build|biuld|create|fix|debug|deploy|deploye|refactor|install|set up|setup|script|api integration|landing page|database schema|migration|skill|infrastructure|cloudflare|wrangler).*?(code|page|skill|script|bug|error|app|function|component|integration|webhook|shopify|stripe|worker|api|fail|broken|crash|workflow|pipeline|cron|automation)|(build|biuld|create|write|fix|set up|setup) (a |the |this |new )?(react|python|typescript|bash|js|html|css|sql|skill|script|app|tool|function|integration|api|shopify|stripe|webhook|cloudflare|worker|workflow|pipeline|cron|automation)|deploy.*(build|production|live|staging|server|site|app)|website.*(speed|slow|broken|down|crash|fix)|cloudflare worker|(debug|fix) .*(why|nanobanana|audit|compose|loop|curator|script|pipeline)' && ! echo "$task" | grep -qiE '(tiktok|instagram|youtube|reels|ugc|video|ad|brand|product) script'; then
    echo "taoz"
    return 0
  fi

  # TAOZ: thinking, architecture, code review, technical planning → Taoz (needs Opus-level intelligence)
  # Guard: exclude creative brainstorm (dreami), campaign planning (hermes), competitor/strategy analysis (athena),
  #         visual redesign (iris), ad/budget optimization (hermes)
  if echo "$task" | grep -qiE '(^think |^thinking |deep.?think|^brainstorm.*(system|tech|code|arch|pipeline|infra|gateway|routing|dispatch|skill|backend|api|migration|refactor|database|cron)|^architect|architecture.*(review|plan|redesign|rethink|overhaul|improve|change|refactor)|system.?design|design.*(system|architecture|schema|pipeline|infra)|^plan.*(migrat|refactor|rebuild|restructur|backend|api|database|schema|pipeline|infra|gateway|cron|deploy|code|technical)|review.*(code|classify|script|pipeline|cron|dispatch|gateway|routing|skill|infra)|code.?review|audit.*(code|script|classify|pipeline|cron|dispatch|gateway|routing|skill|infra)|^optimiz.*(system|code|pipeline|infra|gateway|routing|dispatch|classify|cron|script|backend|api|database|query|latency|speed|perf)|^redesign.*(system|arch|pipeline|infra|gateway|routing|dispatch|classify|cron|backend|api|database))' && ! echo "$task" | grep -qiE '(brainstorm.*(ad|creative|content|copy|campaign|brand|marketing|social|video|visual|caption|tagline|post|idea)|plan.*(campaign|content|post|social|marketing|ad|promotion|launch|sale)|optimiz.*(meta|facebook|google|tiktok|ad|budget|roas|spend|listing|shopee|lazada)|redesign.*(logo|brand|visual|ui|poster|banner|thumbnail|look|character|avatar|outfit)|think.*(competitor|market|pricing|strateg|revenue|sales|brand|campaign|customer)|analyz.*(competitor|market|pricing|sales|revenue|q[1-4]|brand|campaign|customer|performance))'; then
    echo "taoz"
    return 0
  fi

  # ARTEMIS: research — pure intel gathering, NOT analysis
  if echo "$task" | grep -qiE '(research|scrape|scrap|competitor|market (data|analysis|research)|find (info|data|details) (about|on)|find.*(trending|viral|popular|top).*(content|video|post|format|bento|food|recipe)|trend analysis|news monitoring|monitor|competitive intel|best.?sell|top.?sell|popular (product|item|menu)|top (product|item|menu)|what.*(sell|product|item).*(best|most|top)|what (are|is) .*(top|best|trending|popular)|what .*(content|type|format) works|vs .*(competitor|laneige|skii|innisfree|competitor)|top .*(brand|supplement|product).* in |biz.?scout|discover.*(business|opportunity|product)|scan.*(product|market|trend|opportunity)|spy.*(product|store|ad))' && ! echo "$task" | grep -qiE '(analyz|compar).*(competitor|vs |pricing)'; then
    echo "artemis"
    return 0
  fi

  # AD PERFORMANCE INQUIRY → Athena (analysis)
  if echo "$task" | grep -qiE '(how (are|is) .*(ads?|campaign).*(perform|doing|going)|how .*(ads?|campaign) (perform|doing|going)|are .*(ads?|campaign).*(working|perform|doing)|check.*(ad|ads|campaign).*(perform|result|stat|data)|ad.?performance.*(check|report|this|last)|pull.*(ad|ads|campaign).*(number|stat|data)|show.*(ad|ads|campaign).*(number|stat|data))' && ! echo "$task" | grep -qiE '(review|audit|optimize|improve|fix|pause|scale)'; then
    echo "athena"
    return 0
  fi

  # HERMES: campaign planning, ads and pricing
  if echo "$task" | grep -qiE '(campaign.?plan|create.*campaign|campaign.?brief|ad.?set.?for|campaign.?status|check.?notion|notion.?status|kanban|meta ads|facebook ads|google ads|tiktok ads|ad (optimization|spend|budget|link|creative)|ads (budget|review|audit|performance|spend)|pricing (strategy|model|plan)|roas|shopee|lazada|revenue (campaign|optimization)|promotion mechanics|ad campaign|audit.*(ads|ad )|our ads|all.*(ads|ad campaign)|pricing.*(for|of) |^pricing | pricing$|price.*(point|range|tier)|margin.*(analys|optim)|how much.*(cost|price|charge)|fix.*(ad|ads)|^.{0,20} ads$| ads |cost.*(cream|product|serum|item)|(facebook|google|tiktok|meta|instagram) campaign| need pricing|ad spend.*(too|high|low)|optimize.*(listing|shopee)|shopee listing|set up.*(google|meta|facebook|tiktok) ads|ad.*(creativ|performanc)|onboard.*(brand|new)|register.*(brand|new)|brand.?onboard|new brand.*(setup|register|create)|brand.?readiness|go.?live.*(brand)|what campaign|show.*(campaign|direction|template)|campaign.*(direction|option|menu|list)|which (direction|template|campaign)|available.*(direction|template|campaign)|what.*(template|direction|campaign).*(option|available|have|can|do)|what.*ads.*direction|ads.*direction|mirra.*ads.*direction|ads.*(strategy|plan|approach)|ad direction)' && ! echo "$task" | grep -qiE '(analyz|compar).*(pric|cost|margin|competitor)|(photo|image|visual|poster|banner|design).*(shopee|lazada)|needs?.*(photo|image|visual).*(shopee|lazada)'; then
    echo "hermes"
    return 0
  fi

  # SOCIAL PUBLISHING / SCHEDULING → Hermes (decides when/where to post, manages calendar)
  if echo "$task" | grep -qiE '(post.*(to|on) (ig|instagram|fb|facebook|tiktok)|publish.*(to|on) (ig|instagram|fb|facebook)|schedule.*(post|publish|content)|social.?publish|content.?calendar|posting.?schedule|when.*(post|publish)|plan.*(post|content).*(week|month|calendar)|schedule.*(content|post).*(next|this|for))'; then
    echo "hermes"
    return 0
  fi

  # DREAMI: creative copy
  if echo "$task" | grep -qiE '(write .*(copy|caption|edm|email|tagline|headline|brief|post|bio)|copywriting|campaign (concept|brief|strategy)|brand voice|creative direction|bilingual|chinese (copy|content)|content strategy|^caption |caption for| caption$|(caption|copy|tagline|headline) for .*(instagram|tiktok|facebook|reels|story)|(tiktok|instagram|youtube|reels|social|ugc|brand|product|ad|video) script|write .*(tiktok|instagram|youtube|reels|ugc|ad|video) |content for (instagram|tiktok|facebook|social|reels)|update.*(copy|caption|content)|wrte .*(caption|copy)| copy$| copy |^copy |what to (post|write|create)|idea.*(post|content|caption)|social media (contest|campaign|challenge)|capitaliz|going viral|brand.?guideline|tiktok content|instagram (bio|content)|more content|needs? (more )?content)'; then
    echo "dreami"
    return 0
  fi

  # ATHENA: strategy and analysis
  if echo "$task" | grep -qiE '(strateg(y|ic)|analyz(e|is)|analysis|forecast|report(ing)?|dashboard|okr|kpi|business (plan|case)|feasibility|performance (review|this month|last|data|stats)|multi.?variable|(tiktok|instagram|facebook|youtube|social).*(performance|analytics|stats|data|numbers|results)|how (is|are) .*(performing|doing)|how many .*(video|content|post|order|sale)|what should we (do|focus|prioritize)| numbers$| report$| forecast$|check.*(numbers|stats|data|performance)|launch plan|doing (ok|well|good|bad)|^is .*(doing|performing|ok|good)| is .*(doing|performing|ok|good)|not (selling|getting|performing|converting|growing)|which brand.*(best|worst|top)|across all brands|all brands.*(performance|stats|number)|what did we learn|page.*(insight|analytics|stats)|compare.*(brand|sales|perform)|complain.*(about|speed|slow))' && ! echo "$task" | grep -qiE '(analyz|review|check).*(poster|banner|design|visual|image|logo|photo)'; then
    echo "athena"
    return 0
  fi

  # IRIS: visual, image gen, design, avatar, style references (NOT publishing/scheduling — that's Hermes)
  if echo "$task" | grep -qiE '(generate .*(image|photo|visual|poster|banner|thumbnail)|image generation|nanobanana|visual direction|mood.?board|community engagement|character (design|sheet|concept)|create.*(character|avatar) (of|for)|avatar|art style|editorial style|style of|selfie|storyboard|reverse.?prompt|visual.?qa|brand.?visual|heyshiro|heysirio|ohneis|persona.?gen|product (image|photo|shot)|create .*(image|visual|graphic)|make .*(poster|banner|thumbnail|flyer|graphic)|style.?seed|design.?sheet| poster$| poster | banner$| banner |genrate .*(image|visual)|design .*(thumbnail|poster|banner|flyer|graphic)|style.?refer|pinterest.*(style|board|refer)|extract style|what style|color.?palette|similar style|visual.?element|describe.*(visual|image|design)|visual.?identity|brand.?visual|brand.?identity|design.?brief|set of .*(image|poster|banner|visual|graphic)|batch.*(image|visual|poster|banner)|[0-9]+ .*(image|poster|banner|thumbnail|version|variation)|variations? (of|for)|versions? (of|for)|product photo|better.*(photo|image|visual)|needs?.*(photo|image|visual|refresh)|(analyz|review|check).*(poster|banner|design|visual|image|logo)|as reference| as ref |campaign look|this image|better.*(product )?(photo|image|visual)|add.*(reference|inspiration|ref)|pin.*(this|image|photo|url)|ref.?library|reference.*(library|image|board)|inspiration.?board)' && ! echo "$task" | grep -qiE '(where.*(save|store|put)|move .*(to|into)|copy .*(to|into)|list (all )?file)'; then
    echo "iris"
    return 0
  fi

  # HERMES (revenue): revenue, products, gumroad, info products, monetization
  if echo "$task" | grep -qiE '(gumroad|info.?product|digital.?product|revenue.?stream|monetiz|tiktok.?shop|product.?launch|sales.?funnel|lead.?magnet| ebook|^ebook|course launch|template.?pack)'; then
    echo "hermes"
    return 0
  fi

  # ARGUS (fallback): testing, QA, regression, verification
  if echo "$task" | grep -qiE '(^test | test |test$|^qa | qa |qa$|quality.?assur|regression|^verify |validate |check.?if.?work|^e2e | e2e|smoke.?test|sanity.?check|run.*(test|check))'; then
    echo "argus"
    return 0
  fi

  # MIRRA CONTENT PIPELINE
  if echo "$task" | grep -qiE '(mirra.*(post|content|instagram|bento|recipe|caption|pillar|magic)|create.*mirra.*(post|content)|mirra.*(beyond|rebels?|women|magic))'; then
    echo "dreami"
    return 0
  fi

  # COMPARISON ADS: routed via brand-studio (line 122) → iris → SCRIPT tier
  # Do NOT override to dreami — comparison ads are image generation, handled by NanoBanana CLI

  # BRAND-NOUN SHORTHAND FALLBACK
  local brands='(pinxin|mirra|wholey|dr.?stan|serein|rasaya|gaia)'
  if echo "$task" | grep -qiE "$brands"; then
    if echo "$task" | grep -qiE '(video|clip|reel|animation)'; then
      echo "dreami"; return 0
    fi
    if echo "$task" | grep -qiE '(poster|banner|thumbnail|image|photo|visual|design|graphic|flyer)'; then
      echo "iris"; return 0
    fi
    if echo "$task" | grep -qiE '(copy|caption|content|ideas|creative|script|edm|email|tagline|headline|brief|stuff)'; then
      echo "dreami"; return 0
    fi
    if echo "$task" | grep -qiE '(ads|ad|pricing|price|budget|roas|margin|promo)'; then
      echo "hermes"; return 0
    fi
    if echo "$task" | grep -qiE '(research|competitor|trend|intel|scrape)'; then
      echo "artemis"; return 0
    fi
    if echo "$task" | grep -qiE '(report|forecast|numbers|analytics|stats|performance|plan|strategy|update|work|help|steps|focus|next|^what about |^how about |needs work)'; then
      echo "athena"; return 0
    fi
    local wc_brand
    wc_brand=$(echo "$task" | wc -w | tr -d ' ')
    if [ "$wc_brand" -le 3 ]; then
      echo "athena"; return 0
    fi
  fi

  # COMPARISON ADS: routed via brand-studio (line 122) → iris → SCRIPT tier
  # Do NOT override to dreami — comparison ads are image generation, handled by NanoBanana CLI

  # No override matched
  echo "auto"
  return 0
}

OVERRIDE=$(classify_override "$TASK_LOWER")

# ── MODEL MAP (reads from openclaw.json — source of truth) ────────────────────
agent_to_model() {
  local agent="$1"
  local config="$HOME/.openclaw/openclaw.json"
  local model
  model=$(python3 -c "
import json, os
with open(os.path.expanduser('$config')) as f:
    data = json.load(f)
for a in data['agents']['list']:
    if a['id'] == '$agent':
        print(a.get('model',{}).get('primary',''))
        break
" 2>/dev/null)
  if [[ -n "$model" ]]; then
    echo "$model"
  else
    echo "openrouter/z-ai/glm-4.7-flash"
  fi
}

agent_to_cost() {
  case "$1" in
    myrmidons) echo "cheapest (minimax-m2.5)" ;;
    taoz)      echo "cheapest (glm-4.7-flash)" ;;
    artemis)   echo "free (kimi-k2.5)" ;;
    dreami)    echo "free (kimi-k2.5)" ;;
    iris)      echo "medium (qwen3-vl)" ;;
    athena)    echo "medium (glm-5)" ;;
    hermes)    echo "medium (glm-5)" ;;
    argus)     echo "medium (glm-5)" ;;
    *)         echo "unknown" ;;
  esac
}

estimate_complexity() {
  local task="$1"
  if echo "$task" | grep -qiE '(build|create|research|analyze|strategy|campaign|full|complete|end.?to.?end|multi.?step|integration)'; then
    echo "complex"
  elif echo "$task" | grep -qiE '(check|list|git|ping|read|fetch|post|send|move|rename|commit)'; then
    echo "simple"
  else
    echo "medium"
  fi
}

COMPLEXITY=$(estimate_complexity "$TASK_LOWER")

# ── Resolve agent from override or router fallback ──────────────────────────
if [[ "$OVERRIDE" != "auto" ]]; then
  AGENT="$OVERRIDE"
  SOURCE="override"
else
  # Fall back to route-task.py (capability matching)
  if [[ -f "$ROUTER" ]] && source ~/.openclaw/.env 2>/dev/null; then
    AGENT=$(python3 "$ROUTER" "$TASK" --json 2>/dev/null | python3 -c "
import sys, json
results = json.loads(sys.stdin.read())
if results:
    print(results[0]['agent'])
else:
    print('myrmidons')
" 2>/dev/null || echo "myrmidons")
    SOURCE="router"
  else
    AGENT="myrmidons"
    SOURCE="fallback"
  fi
fi

# ── TRIAGE FALLBACK (Haiku via CLI, $0) ──────────────────────────────────────
# If both override AND router returned catch-all (myrmidons), try Haiku triage
# This catches ambiguous tasks that keyword matching missed
TRIAGE_SCRIPT="$HOME/.openclaw/skills/orchestrate-v2/scripts/triage.sh"
CODE_TIER=""  # Will be set if triage returns CODE_* category

if [[ "$SOURCE" = "fallback" || ("$AGENT" = "myrmidons" && "$SOURCE" = "router") || ("$AGENT" = "main" && "$SOURCE" = "router") ]]; then
  # Pre-check: greetings should NEVER hit triage (Haiku inconsistently returns CODE_SIMPLE for greetings)
  if echo "$TASK" | grep -qiE '^(hi|hello|hey|thanks|thank you|ok|yes|no|help|stop|undo|what can you)( +(zenni|taoz|dreami|iris|hermes|athena|artemis|argus|myrmidons|there|everyone|team|guys|all))?[!?.]*$'; then
    AGENT="main"
    SOURCE="greeting"
  elif [[ -f "$TRIAGE_SCRIPT" ]]; then
    TRIAGE_RESULT=$(bash "$TRIAGE_SCRIPT" "$TASK" 2>/dev/null || echo "CODE_SIMPLE")
    case "$TRIAGE_RESULT" in
      CODE_SIMPLE)
        AGENT="taoz"
        CODE_TIER="code_simple"
        SOURCE="triage"
        ;;
      CODE_COMPLEX)
        AGENT="taoz"
        CODE_TIER="code_complex"
        SOURCE="triage"
        ;;
      CODE_MULTI)
        AGENT="taoz"
        CODE_TIER="code_multi"
        SOURCE="triage"
        ;;
      CHAT)
        AGENT="main"
        SOURCE="triage"
        ;;
      DOMAIN:*)
        AGENT="${TRIAGE_RESULT#DOMAIN:}"
        SOURCE="triage"
        ;;
    esac
  fi
fi

# ── AGENT VALIDATION (reject ghost/stale agent names) ──────────
# Only allow agents that actually exist in openclaw.json
VALID_AGENTS="main taoz myrmidons artemis dreami hermes athena iris argus"
if ! echo " $VALID_AGENTS " | grep -q " $AGENT "; then
  # Map known ghost agents to their real replacements
  case "$AGENT" in
    visualos)   AGENT="iris" ;;
    creativeos) AGENT="dreami" ;;
    zenni)      AGENT="main" ;;
    thinker)    AGENT="taoz" ;;
    *)          AGENT="myrmidons" ;;
  esac
  SOURCE="validated"
fi

# ── TIER DETECTION ────────────────────────────────────────────────────────────
# Tier 1 (LOOKUP): Read-only queries that can be answered by running a command
# Tier 2 (DISPATCH): Agent work — spawn agent in background
# Tier 3 (RELAY): Zenni handles herself (greetings, simple acks)
detect_tier() {
  local task="$1"
  local agent="$2"

  # RELAY: greetings, acks, help — Zenni handles directly
  # Match exact greetings OR greeting + agent name (e.g. "hi zenni", "hello taoz")
  if echo "$task" | grep -qiE '^(hi|hello|hey|thanks|thank you|ok|yes|no|help|stop|undo|what can you)( +(zenni|taoz|dreami|iris|hermes|athena|artemis|argus|myrmidons|there|everyone|team|guys|all))?[!?.]*$'; then
    echo "relay"
    return 0
  fi

  # LOOKUP: read-only queries that a script can answer directly
  # Campaign directions listing — but NOT "create campaign" (that's dispatch)
  if echo "$task" | grep -qiE '(show.*(campaign|direction|template)|what.*(campaign|direction|template)|which.*(direction|template|campaign)|available.*(direction|template|campaign)|list.*(campaign|direction|template)|campaign.*(direction|option|menu|list))' && ! echo "$task" | grep -qiE '(create|generate|make|build|run|launch|start|set up)'; then
    echo "lookup"
    return 0
  fi

  # SCRIPT: tasks that can be handled by running a CLI tool directly (no LLM needed)
  # Image generation, bulk generation, status checks — all have deterministic CLI commands
  if [[ "$agent" = "iris" ]] || [[ "$agent" = "dreami" ]]; then
    # Single image generation — NanoBanana CLI can handle directly
    # Covers all 11 ad types: M1-M5 (comparison,hero,grid,lifestyle,testimonial,persona) + B1-B4 (sales-boom,urgency,raw,price) + product
    if echo "$task" | grep -qiE '(generate|create|make|compose).*(ad|ads|image|visual|poster|banner|comparison|hero|grid|lifestyle|testimonial|persona|kol|ugc|flash.?sale|boom|promo|deal|discount|urgency|countdown|last.?call|raw|authentic|lo.?fi|meme|price|cod|delivery|product)' && ! echo "$task" | grep -qiE '(batch|bulk|multiple|mass|[0-9][0-9]+ *(ads?|images?|visuals?|posters?|banners?))' && ! echo "$task" | grep -qiE '(video|clip|reel|animation|animate|storyboard|sora|kling|wan|remotion)'; then
      echo "script"
      return 0
    fi
    # Bulk generation — ad-bulk-gen.sh handles directly
    if echo "$task" | grep -qiE '(batch|bulk|multiple|mass).*(generat|create|make|image|ad|visual)|([0-9]+)\s*(ads?|images?|visuals?|posters?|banners?)'; then
      echo "script"
      return 0
    fi
  fi
  # VIDEO SCRIPT: single video generation with brand — video-gen.sh handles directly
  # Catches: "generate mirra video", "make mirra bento video", "sora video for mirra"
  # Must have a brand name + video intent. Complex/creative video → DISPATCH to dreami
  # EXCLUDES: ugc, intro, character, creative, script-writing tasks (need Dreami direction)
  if [[ "$agent" = "dreami" ]] || [[ "$agent" = "iris" ]]; then
    if echo "$task" | grep -qiE '(generate|create|make).*(video|clip|reel)|(video|clip|reel).*(generate|create|make)|sora.*(generate|video)|kling.*(generate|video)' && echo "$task" | grep -qiE '(mirra|pinxin|wholey|serein|rasaya|gaia)' && ! echo "$task" | grep -qiE '(batch|bulk|multiple|[0-9][0-9]+|script|concept|brief|storyboard|plan|strategy|ugc|intro|character|creative|persona|testimonial|behind|bts)'; then
      echo "script"
      return 0
    fi
  fi

  # VIDEO COMPILER: create video ads from briefs → SCRIPT tier (video-compiler.sh handles directly)
  if [[ "$agent" = "iris" ]]; then
    if echo "$task" | grep -qiE '(video.?compiler|compile.*(video|ad)|video.?ad.*(creat|generat|make|build|produc)|ugc.?ad.*(creat|generat|make|build|produc)|(make|create|generate|produce|build).*(video|ugc).*(ad|variant|campaign).*for|batch.*(video|ugc).*(ad|variant|campaign)|(pas|slap|emotional|testimonial).*(framework|ad|video)|(3|5|10|multiple|batch).*(video|ugc|ad).*(variant|version)|video.?brief.*(run|execut|produc))'; then
      echo "script"
      return 0
    fi
  fi

  # EVOMAP: evomap commands → SCRIPT tier (evomap-gaia.sh handles directly)
  if [[ "$agent" = "taoz" ]]; then
    if echo "$task" | grep -qiE '(evomap|evolve.?cycle|evolution.?(cycle|network)|gene.?capsule|publish.*(gene|capsule|learning).*evomap|fetch.*(capsule|gene).*evomap|evomap.*(status|heartbeat|publish|fetch|tasks|evolve))'; then
      echo "script"
      return 0
    fi
  fi

  # CLIP FACTORY: split/clip/find/compose → SCRIPT tier (clip-factory.sh handles directly)
  if [[ "$agent" = "iris" ]]; then
    if echo "$task" | grep -qiE '(clip|split|cut|chop|segment|highlight).*(video|long|podcast|vlog|interview)|fomofly|viral.?clip|short.?clip|clip.?factory.*(run|extract|analyze|produce|find|compose)|extract.*(highlight|clip|best.?part|moment).*from|find.*(clip|hook|intro|highlight|broll)|compose.*(clip|video|reel|highlight|compilation)|assemble.*(clip|highlight|reel)|highlight.?reel|clip.?library|search.*clip|(split|cut|chop).*\.(mp4|mov|mkv|avi|webm)|(split|cut|chop).*into.*(clip|segment|short)'; then
      echo "script"
      return 0
    fi
  fi

  # Status/audit checks — script can handle
  if echo "$task" | grep -qiE '(batch|bulk).*(status|check|audit|retry)'; then
    echo "script"
    return 0
  fi

  # Everything else → DISPATCH to the classified agent
  echo "dispatch"
  return 0
}

TIER=$(detect_tier "$TASK_LOWER" "$AGENT")

# ── PERMISSION CHECK ──────────────────────────────────────────────────────────
check_permission() {
  local sender="$1"
  local agent="$2"

  if [[ -z "$sender" ]]; then
    echo "allowed"
    return 0
  fi

  local ADMIN_NUMBERS="+60126169979 +60176847832"
  local TEAM_CREATIVE="+60164638223"
  local sender_clean
  sender_clean=$(echo "$sender" | tr -d ' -')

  case " $ADMIN_NUMBERS " in
    *" $sender_clean "*) echo "allowed"; return 0 ;;
  esac

  case " $TEAM_CREATIVE " in
    *" $sender_clean "*)
      case "$agent" in
        taoz|argus) echo "denied_system" ;;
        *) echo "allowed" ;;
      esac
      return 0
      ;;
  esac

  case "$agent" in
    athena|artemis|dreami) echo "allowed" ;;
    *) echo "denied_restricted" ;;
  esac
}

PERMISSION=$(check_permission "$SENDER" "$AGENT")

# ── AUTO-DISPATCH MODE ────────────────────────────────────────────────────────
if [[ "$AUTO_DISPATCH" = true ]]; then

  # Permission denied → early exit
  if [[ "$PERMISSION" != "allowed" ]]; then
    echo "DENIED:${AGENT}:${PERMISSION}"
    exit 0
  fi

  # --- TIER: RELAY ---
  if [[ "$TIER" = "relay" ]]; then
    echo "RELAY:${AGENT}"
    exit 0
  fi

  # --- TIER: LOOKUP ---
  if [[ "$TIER" = "lookup" ]]; then
    # Detect brand from task
    BRAND=""
    if echo "$TASK_LOWER" | grep -qiE 'mirra'; then BRAND="mirra"
    elif echo "$TASK_LOWER" | grep -qiE 'pinxin'; then BRAND="pinxin-vegan"
    elif echo "$TASK_LOWER" | grep -qiE 'wholey'; then BRAND="wholey-wonder"
    elif echo "$TASK_LOWER" | grep -qiE 'serein'; then BRAND="serein"
    elif echo "$TASK_LOWER" | grep -qiE 'rasaya'; then BRAND="rasaya"
    elif echo "$TASK_LOWER" | grep -qiE 'dr.?stan'; then BRAND="dr-stan"
    elif echo "$TASK_LOWER" | grep -qiE 'gaia.?eats'; then BRAND="gaia-eats"
    fi

    CAMPAIGN_PLANNER="$HOME/.openclaw/skills/campaign-planner/scripts/campaign-planner.sh"

    # Campaign directions lookup
    if echo "$TASK_LOWER" | grep -qiE '(direction|campaign.*(list|option|menu|available))'; then
      if [[ -n "$BRAND" ]] && [[ -f "$CAMPAIGN_PLANNER" ]]; then
        RESULT=$(bash "$CAMPAIGN_PLANNER" directions --brand "$BRAND" 2>/dev/null || echo "Campaign planner not available for $BRAND")
        echo "LOOKUP:${AGENT}"
        echo "---"
        echo "$RESULT"
        exit 0
      fi
    fi

    # Template listing lookup
    if echo "$TASK_LOWER" | grep -qiE '(template.*(list|option|available|what)|what.*template)'; then
      if [[ -n "$BRAND" ]] && [[ -f "$CAMPAIGN_PLANNER" ]]; then
        RESULT=$(bash "$CAMPAIGN_PLANNER" list --brand "$BRAND" 2>/dev/null || echo "Template listing not available for $BRAND")
        echo "LOOKUP:${AGENT}"
        echo "---"
        echo "$RESULT"
        exit 0
      fi
    fi

    # Fallback: couldn't execute lookup, dispatch instead
    TIER="dispatch"
  fi

  # COMPARISON ADS: handled by iris → SCRIPT tier (NanoBanana CLI)
  # Do NOT override to dreami — comparison ads are image generation

  # --- TIER: SCRIPT ---
  # Direct script execution — Zenni runs CLI tools via exec, NO LLM subagent needed
  # This is the key bridge: scripts built in Claude Code get used by Zenni directly
  if [[ "$TIER" = "script" ]]; then
    TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    LABEL="script-$(date +%H%M%S)"

    # --- EVOMAP: Direct evomap-gaia.sh execution ---
    if echo "$TASK_LOWER" | grep -qiE '(evomap|evolve.?cycle|evolution.?(cycle|network)|gene.?capsule|publish.*(gene|capsule|learning).*evomap|fetch.*(capsule|gene)|evomap.*(status|heartbeat|publish|fetch|tasks|evolve))'; then
      EVOMAP_SCRIPT="/Users/jennwoeiloh/.openclaw/skills/evomap/scripts/evomap-gaia.sh"
      # Detect subcommand
      EVOMAP_CMD="status"
      if echo "$TASK_LOWER" | grep -qiE 'heartbeat'; then EVOMAP_CMD="heartbeat"
      elif echo "$TASK_LOWER" | grep -qiE 'publish|gene|capsule'; then EVOMAP_CMD="publish"
      elif echo "$TASK_LOWER" | grep -qiE 'fetch'; then EVOMAP_CMD="fetch"
      elif echo "$TASK_LOWER" | grep -qiE 'task|bounty'; then EVOMAP_CMD="tasks"
      elif echo "$TASK_LOWER" | grep -qiE 'evolve|evolution|cycle'; then EVOMAP_CMD="evolve"
      elif echo "$TASK_LOWER" | grep -qiE 'hello|register'; then EVOMAP_CMD="hello"
      fi
      CMD="bash ${EVOMAP_SCRIPT} ${EVOMAP_CMD}"
      echo "SCRIPT:${LABEL}"; echo "TYPE:evomap"; echo "CMD:${CMD}"
      echo "{\"ts\":\"$TS\",\"label\":\"$LABEL\",\"tier\":\"script\",\"type\":\"evomap\",\"cmd\":\"$EVOMAP_CMD\"}" >> "$DISPATCH_LOG"
      exit 0
    fi

    # Detect brand
    SCRIPT_BRAND=""
    if echo "$TASK_LOWER" | grep -qiE 'mirra'; then SCRIPT_BRAND="mirra"
    elif echo "$TASK_LOWER" | grep -qiE 'pinxin'; then SCRIPT_BRAND="pinxin-vegan"
    elif echo "$TASK_LOWER" | grep -qiE 'wholey'; then SCRIPT_BRAND="wholey-wonder"
    elif echo "$TASK_LOWER" | grep -qiE 'serein'; then SCRIPT_BRAND="serein"
    elif echo "$TASK_LOWER" | grep -qiE 'rasaya'; then SCRIPT_BRAND="rasaya"
    elif echo "$TASK_LOWER" | grep -qiE 'dr.?stan'; then SCRIPT_BRAND="dr-stan"
    elif echo "$TASK_LOWER" | grep -qiE 'gaia.?eats'; then SCRIPT_BRAND="gaia-eats"
    else SCRIPT_BRAND="mirra"  # default
    fi

    # Detect ad type from keywords (9 Tricia template types: M1-M5 MOFU + B1-B4 BOFU)
    ad_type="product"
    if echo "$TASK_LOWER" | grep -qiE 'comparison|vs |before.?after|versus|split'; then ad_type="comparison"        # M4
    elif echo "$TASK_LOWER" | grep -qiE 'hero|feature|spotlight'; then ad_type="hero"                                # M2
    elif echo "$TASK_LOWER" | grep -qiE 'grid|menu|catalog|carousel|album'; then ad_type="grid"                      # M3
    elif echo "$TASK_LOWER" | grep -qiE 'lifestyle|office|lunch|daily|scene'; then ad_type="lifestyle"               # M2 variant
    elif echo "$TASK_LOWER" | grep -qiE 'testimonial|review|quote|egc|customer.?story'; then ad_type="testimonial"   # M5
    elif echo "$TASK_LOWER" | grep -qiE 'persona|kol|influencer|ugc|talking.?head|face.?ad'; then ad_type="persona"  # M1
    elif echo "$TASK_LOWER" | grep -qiE 'flash.?sale|boom|promo|offer|deal|discount|limited.?offer'; then ad_type="sales-boom"  # B1
    elif echo "$TASK_LOWER" | grep -qiE 'last.?call|urgency|countdown|expir|scarci|slots|hurry|ending'; then ad_type="urgency"  # B2
    elif echo "$TASK_LOWER" | grep -qiE 'raw|authentic|lo.?fi|meme|sticker|whatsapp.?style|unpolish'; then ad_type="raw"        # B3
    elif echo "$TASK_LOWER" | grep -qiE 'price|cod|cash.?on|delivery|value.?stack|package.?deal|rm[0-9]'; then ad_type="price"  # B4
    fi

    # Detect ratio
    ratio="1:1"
    if echo "$TASK_LOWER" | grep -qiE '4:5|portrait|story|stories'; then ratio="4:5"
    elif echo "$TASK_LOWER" | grep -qiE '9:16|vertical|reel'; then ratio="9:16"
    elif echo "$TASK_LOWER" | grep -qiE '16:9|landscape|youtube|banner'; then ratio="16:9"
    fi

    # Detect funnel stage (B-type ads are always BOFU)
    funnel="MOFU"
    if echo "$TASK_LOWER" | grep -qiE 'bofu|bottom|retarget'; then funnel="BOFU"
    elif echo "$TASK_LOWER" | grep -qiE 'tofu|top|awareness'; then funnel="TOFU"
    fi
    # Auto-set BOFU for B-type ad types
    case "$ad_type" in
      sales-boom|urgency|raw|price) funnel="BOFU" ;;
    esac

    # Detect bento/dish name for MIRRA
    bento=""
    if echo "$TASK_LOWER" | grep -qiE 'fusilli|bolognese'; then bento="Fusilli Bolognese"
    elif echo "$TASK_LOWER" | grep -qiE 'pad thai|padthai'; then bento="Konjac Pad Thai"
    elif echo "$TASK_LOWER" | grep -qiE 'curry katsu|katsu'; then bento="Japanese Curry Katsu"
    elif echo "$TASK_LOWER" | grep -qiE 'burrito|buritto'; then bento="Fiery Burrito Bowl"
    elif echo "$TASK_LOWER" | grep -qiE 'bbq|pita|mushroom'; then bento="BBQ Pita Mushroom Wrap"
    elif echo "$TASK_LOWER" | grep -qiE 'golden|eryngii|fragrant'; then bento="Golden Eryngii Fragrant Rice"
    elif echo "$TASK_LOWER" | grep -qiE 'curry noodle|konjac noodle'; then bento="Dry Classic Curry Konjac Noodle"
    fi

    # --- VIDEO COMPILER early check: create NEW video ads from briefs ---
    if echo "$TASK_LOWER" | grep -qiE '(video.?compiler|compile.*(video|ad)|video.?ad.*(creat|generat|make|build|produc)|ugc.?ad.*(creat|generat|make|build|produc)|(make|create|generate|produce|build).*(video|ugc).*(ad|variant|campaign).*for|batch.*(video|ugc).*(ad|variant|campaign)|(pas|slap|emotional|testimonial).*(framework|ad|video)|(3|5|10|multiple|batch).*(video|ugc|ad).*(variant|version)|video.?brief.*(run|execut|produc))'; then
      VIDEO_COMPILER="/Users/jennwoeiloh/.openclaw/skills/video-compiler/scripts/video-compiler.sh"

      # Detect mode
      VC_MODE="assembled"
      if echo "$TASK_LOWER" | grep -qiE 'single.?shot|12.?s|quick'; then VC_MODE="single-shot"
      elif echo "$TASK_LOWER" | grep -qiE 'combinat|hook.*bod|a.?b.*test|batch.*variant'; then VC_MODE="combinatorial"
      fi

      # Detect goal
      VC_GOAL="conversion"
      if echo "$TASK_LOWER" | grep -qiE 'awareness|brand.?aware|top.?funnel'; then VC_GOAL="awareness"
      elif echo "$TASK_LOWER" | grep -qiE 'retarget|remarket|warm.?audience'; then VC_GOAL="retargeting"
      fi

      # Detect variant count
      VC_VARIANTS=$(echo "$TASK_LOWER" | grep -oE '[0-9]+' | head -1 || true)
      VC_VARIANTS="${VC_VARIANTS:-3}"

      # Detect framework
      VC_FRAMEWORK=""
      if echo "$TASK_LOWER" | grep -qiE '\bpas\b|problem.*agitate'; then VC_FRAMEWORK="pas"
      elif echo "$TASK_LOWER" | grep -qiE '\bslap\b|stop.*look.*act'; then VC_FRAMEWORK="slap"
      elif echo "$TASK_LOWER" | grep -qiE 'emotional|story'; then VC_FRAMEWORK="emotional_storytelling"
      elif echo "$TASK_LOWER" | grep -qiE 'testimonial|ugc'; then VC_FRAMEWORK="ugc_testimonial"
      fi

      # Detect product from bento variable or task
      VC_PRODUCT="${bento:-}"
      if [ -z "$VC_PRODUCT" ]; then
        VC_PRODUCT=$(echo "$TASK_LOWER" | grep -oE '(bento|meal|bowl|noodle|rice|wrap|snack|supplement|serum|cream|oil)' | head -1 || true)
        VC_PRODUCT="${VC_PRODUCT:-product}"
      fi

      CMD="bash ${VIDEO_COMPILER} run --brand ${SCRIPT_BRAND} --product \"${VC_PRODUCT}\" --mode ${VC_MODE} --goal ${VC_GOAL} --variants ${VC_VARIANTS}"
      if [ -n "$VC_FRAMEWORK" ]; then CMD="${CMD} --framework ${VC_FRAMEWORK}"; fi

      echo "SCRIPT:${LABEL}"; echo "TYPE:video-compiler"; echo "BRAND:${SCRIPT_BRAND}"
      echo "MODE:${VC_MODE}"; echo "GOAL:${VC_GOAL}"; echo "VARIANTS:${VC_VARIANTS}"
      echo "CMD:${CMD}"
      echo "{\"ts\":\"$TS\",\"label\":\"$LABEL\",\"tier\":\"script\",\"type\":\"video-compiler\",\"brand\":\"$SCRIPT_BRAND\",\"mode\":\"$VC_MODE\"}" >> "$DISPATCH_LOG"
      exit 0
    fi

    # --- CLIP FACTORY early check: exit before image gen if this is a clip task ---
    if echo "$TASK_LOWER" | grep -qiE '(clip|split|cut|chop|segment|highlight).*(video|long|podcast|vlog|interview)|fomofly|viral.?clip|short.?clip|clip.?factory|extract.*(highlight|clip|best.?part|moment).*from|find.*(clip|hook|intro|highlight|broll)|compose.*(clip|video|reel|highlight|compilation)|assemble.*(clip|highlight|reel)|highlight.?reel|clip.?library|search.*clip|(split|cut|chop).*\.(mp4|mov|mkv|avi|webm)|(split|cut|chop).*into.*(clip|segment|short)'; then
      CLIP_FACTORY="/Users/jennwoeiloh/.openclaw/skills/clip-factory/scripts/clip-factory.sh"
      CF_SUBCMD="run"
      if echo "$TASK_LOWER" | grep -qiE 'find.*(clip|hook|intro|highlight|broll)|search.*clip|clip.?library.*search|browse.*clip'; then
        CF_SUBCMD="find"
      elif echo "$TASK_LOWER" | grep -qiE 'compose.*(clip|video|reel|highlight|compilation)|assemble.*(clip|highlight|reel)|highlight.?reel|build.*(reel|compilation).*from.*clip'; then
        CF_SUBCMD="compose"
      fi
      CF_MOOD=""
      if echo "$TASK_LOWER" | grep -qoiE '(inspiring|funny|educational|emotional|dramatic|calm|urgent|casual)'; then
        CF_MOOD=$(echo "$TASK_LOWER" | grep -oiE '(inspiring|funny|educational|emotional|dramatic|calm|urgent|casual)' | head -1)
      fi
      CF_ENERGY=""
      if echo "$TASK_LOWER" | grep -qoiE '(high.?energy|low.?energy|medium.?energy)'; then
        CF_ENERGY=$(echo "$TASK_LOWER" | grep -oiE '(high|low|medium)' | head -1)
      fi

      if [[ "$CF_SUBCMD" = "find" ]]; then
        CMD="bash ${CLIP_FACTORY} find --brand ${SCRIPT_BRAND}"
        if [[ -n "$CF_MOOD" ]]; then CMD="${CMD} --mood ${CF_MOOD}"; fi
        if [[ -n "$CF_ENERGY" ]]; then CMD="${CMD} --energy ${CF_ENERGY}"; fi
        echo "SCRIPT:${LABEL}"; echo "TYPE:clip-factory-find"; echo "BRAND:${SCRIPT_BRAND}"; echo "CMD:${CMD}"
      elif [[ "$CF_SUBCMD" = "compose" ]]; then
        CMD="bash ${CLIP_FACTORY} compose --brand ${SCRIPT_BRAND}"
        if [[ -n "$CF_MOOD" ]]; then CMD="${CMD} --mood ${CF_MOOD}"; fi
        if [[ -n "$CF_ENERGY" ]]; then CMD="${CMD} --energy ${CF_ENERGY}"; fi
        echo "SCRIPT:${LABEL}"; echo "TYPE:clip-factory-compose"; echo "BRAND:${SCRIPT_BRAND}"; echo "CMD:${CMD}"
      else
        INPUT_PATH=""
        if echo "$TASK" | grep -qoE '(/[^ ]+\.(mp4|mov|mkv|avi|webm))'; then
          INPUT_PATH=$(echo "$TASK" | grep -oE '(/[^ ]+\.(mp4|mov|mkv|avi|webm))' | head -1)
        fi
        CMD="bash ${CLIP_FACTORY} run --brand ${SCRIPT_BRAND}"
        if [[ -n "$INPUT_PATH" ]]; then
          CMD="${CMD} --input \"${INPUT_PATH}\""
          echo "SCRIPT:${LABEL}"; echo "TYPE:clip-factory"; echo "BRAND:${SCRIPT_BRAND}"; echo "CMD:${CMD}"
        else
          echo "SCRIPT:${LABEL}"; echo "TYPE:clip-factory"; echo "BRAND:${SCRIPT_BRAND}"
          echo "DESCRIPTION:Split video into viral clips for ${SCRIPT_BRAND}"
          echo "NOTE:Video path needed. Ask user for the video file path."
          echo "CMD_TEMPLATE:${CMD} --input /path/to/video.mp4"
        fi
      fi
      echo "{\"ts\":\"$TS\",\"label\":\"$LABEL\",\"tier\":\"script\",\"type\":\"clip-factory-${CF_SUBCMD}\",\"brand\":\"$SCRIPT_BRAND\"}" >> "$DISPATCH_LOG"
      exit 0
    fi

    NANOBANANA="/Users/jennwoeiloh/.openclaw/skills/nanobanana/scripts/nanobanana-gen.sh"
    GENERATE_AUDIT="/Users/jennwoeiloh/.openclaw/skills/nanobanana/scripts/generate-and-audit.sh"
    BULK_GEN="/Users/jennwoeiloh/.openclaw/skills/ad-composer/scripts/ad-bulk-gen.sh"
    SKU_DIR="/Users/jennwoeiloh/.openclaw/workspace/brands/${SCRIPT_BRAND}/march-campaign/drive-assets/My product bento"
    BRAND_ASSETS="/Users/jennwoeiloh/.openclaw/brands/${SCRIPT_BRAND}/assets"

    # --- BULK GENERATION ---
    if echo "$TASK_LOWER" | grep -qiE '(batch|bulk|multiple|mass).*(generat|create|make|image|ad|visual)|([0-9]+)\s*(ads?|images?)'; then
      # Extract count if mentioned
      count=$(echo "$TASK_LOWER" | grep -oE '[0-9]+' | head -1)
      count="${count:-5}"

      echo "SCRIPT:${LABEL}"
      echo "TYPE:bulk-gen"
      echo "BRAND:${SCRIPT_BRAND}"
      echo "COUNT:${count}"
      echo "DESCRIPTION:Generate ${count} ${ad_type} ads for ${SCRIPT_BRAND} (${ratio}, ${funnel})"
      echo "NOTE:Bulk generation requires a prompts file. Zenni should ask user for prompts file path, or generate prompts first."
      echo "CMD_TEMPLATE:bash ${BULK_GEN} from-file --brand ${SCRIPT_BRAND} --file /path/to/prompts.json --model flash --size 2K"
      echo "CMD_STATUS:bash ${BULK_GEN} status --latest --brand ${SCRIPT_BRAND}"

      echo "{\"ts\":\"$TS\",\"label\":\"$LABEL\",\"tier\":\"script\",\"type\":\"bulk-gen\",\"brand\":\"$SCRIPT_BRAND\",\"count\":\"$count\"}" >> "$DISPATCH_LOG"
      exit 0
    fi

    # --- BATCH STATUS/AUDIT ---
    if echo "$TASK_LOWER" | grep -qiE '(batch|bulk).*(status|check|audit|retry)'; then
      if echo "$TASK_LOWER" | grep -qiE 'retry'; then
        echo "SCRIPT:${LABEL}"
        echo "TYPE:batch-retry"
        echo "CMD:bash ${BULK_GEN} retry --latest --brand ${SCRIPT_BRAND}"
      elif echo "$TASK_LOWER" | grep -qiE 'audit'; then
        echo "SCRIPT:${LABEL}"
        echo "TYPE:batch-audit"
        echo "CMD:bash ${BULK_GEN} audit --latest --brand ${SCRIPT_BRAND}"
      else
        echo "SCRIPT:${LABEL}"
        echo "TYPE:batch-status"
        echo "CMD:bash ${BULK_GEN} status --latest --brand ${SCRIPT_BRAND}"
      fi

      echo "{\"ts\":\"$TS\",\"label\":\"$LABEL\",\"tier\":\"script\",\"type\":\"batch-op\",\"brand\":\"$SCRIPT_BRAND\"}" >> "$DISPATCH_LOG"
      exit 0
    fi

    # --- SINGLE IMAGE GENERATION ---
    # Skip if task is video generation (handled by VIDEO SCRIPT section below)
    if echo "$TASK_LOWER" | grep -qiE '(video|clip|reel|sora|kling|wan).*(generate|create|make)|(generate|create|make).*(video|clip|reel)'; then
      # Fall through to VIDEO SCRIPT section below
      :
    else
    # Build a smart prompt from keywords
    PROMPT=""
    case "$ad_type" in
      comparison)
        bento_name="${bento:-Fusilli Bolognese}"
        PROMPT="Split comparison layout. LEFT side: generic unhealthy fast food takeout in plastic container, greasy and unappealing. RIGHT side: EXACT ${bento_name} bento from MIRRA — fresh, colorful, healthy meal in eco-friendly packaging, keep food identical to reference. MIRRA logo top-right corner. Calorie count badges: LEFT 800cal vs RIGHT 450cal. Brand colors salmon pink #F7AB9F background with cream #FFF9EB accents. Clean modern design with organic blob shapes. Serif headline font."
        ;;
      hero)
        bento_name="${bento:-Fusilli Bolognese}"
        PROMPT="Hero product shot: EXACT ${bento_name} bento from MIRRA centered on clean background. MIRRA logo top-right. Large serif headline text area at bottom. Gradient background using brand colors salmon pink #F7AB9F to cream #FFF9EB. Organic blob shapes as decorative elements. Steam rising from food. Professional food photography style, overhead angle."
        ;;
      lifestyle)
        PROMPT="Lifestyle scene: young Malaysian professional woman (25-35) enjoying MIRRA bento meal at modern office desk during lunch. Natural window lighting. MIRRA branded packaging visible. Clean minimal aesthetic. Brand colors salmon pink #F7AB9F and cream #FFF9EB in environment details. Authentic, aspirational, not posed. Shot on 35mm lens."
        ;;
      grid)
        PROMPT="Menu grid layout showing 4 MIRRA bento varieties in 2x2 grid: each bento in branded packaging, overhead shot. MIRRA logo centered. Brand colors salmon pink #F7AB9F background, cream #FFF9EB card backgrounds. Price badges on each item. Clean minimal typography. Professional food photography."
        ;;
      testimonial)
        PROMPT="Testimonial ad layout: Large quote text area with customer review. Small circular portrait photo placeholder. MIRRA bento product image bottom-right. Star rating 5/5. Brand colors salmon pink #F7AB9F and cream #FFF9EB. Serif font for quote, sans-serif for attribution. MIRRA logo top-right."
        ;;
      persona)
        # M1: Faces/KOL/Persona — person-led storytelling
        PROMPT="Person-led ad: Young Malaysian woman (25-35) holding or presenting MIRRA bento meal, direct eye contact with camera, genuine smile. UGC talking-head style, natural lighting. Text overlay area for quote/caption. MIRRA logo small top-right. Brand colors salmon pink #F7AB9F background tones. Authentic, not overly styled. Warm feminine energy."
        ;;
      sales-boom)
        # B1: Sales Boom/Flash Sale — high-energy promo
        bento_name="${bento:-Fusilli Bolognese}"
        PROMPT="Flash sale BOFU ad: Bold eye-catching design. EXACT ${bento_name} bento from MIRRA center. Large bold price tag or discount badge (e.g. 20% OFF). Countdown timer graphic element. Bright salmon pink #F7AB9F background with energetic design. FOMO urgency text area. MIRRA logo. Bold sans-serif headlines. Dynamic starburst or sale badge shapes. High contrast, attention-grabbing."
        ;;
      urgency)
        # B2: Last Call/Scarcity — countdown, limited slots
        bento_name="${bento:-Fusilli Bolognese}"
        PROMPT="Urgency/scarcity BOFU ad: EXACT ${bento_name} bento from MIRRA. Countdown clock or timer graphic. 'LAST FEW SLOTS' or 'ENDING SOON' text area. Dark salmon pink to cream gradient background. MIRRA logo. Bold typography. Red accent badges for urgency. Stock quantity indicator showing low numbers. Clean but urgent design."
        ;;
      raw)
        # B3: Raw/Authentic — lo-fi, WhatsApp chat aesthetic
        bento_name="${bento:-Fusilli Bolognese}"
        PROMPT="Lo-fi authentic raw ad: ${bento_name} bento from MIRRA shot casually on phone camera style. Slightly imperfect framing, like a real WhatsApp photo. Handwritten-style text overlay. Sticker-like emoji elements. No polished layout — intentionally unpolished, real, relatable. MIRRA branding subtle. Raw food photography, natural messy background like real kitchen/desk. Meme-inspired format."
        ;;
      price)
        # B4: Price/COD/Value Stack — clear pricing, delivery info
        bento_name="${bento:-Fusilli Bolognese}"
        PROMPT="Price-focused BOFU ad: EXACT ${bento_name} bento from MIRRA with clear price breakdown. Large price tag (RM XX.XX). Value stack showing what's included: bento + delivery + eco-packaging. COD/free delivery badge if applicable. MIRRA logo top-right. Clean cream #FFF9EB background with salmon pink #F7AB9F price badges. Sans-serif price typography. Trust badges: halal, nutritionist-approved."
        ;;
      *)
        bento_name="${bento:-Fusilli Bolognese}"
        PROMPT="Product advertisement: EXACT ${bento_name} bento from MIRRA in branded eco-friendly packaging. Overhead angle, professional food photography. MIRRA logo top-right. Headline text area. Brand colors salmon pink #F7AB9F background with cream #FFF9EB accents. Organic blob shapes. Fresh ingredients scattered around. Clean modern design."
        ;;
    esac

    # If user provided a specific prompt in quotes, use that instead
    user_prompt=$(echo "$TASK" | sed -n 's/.*"\([^"]*\)".*/\1/p' | head -1)
    if [[ -n "$user_prompt" ]]; then
      PROMPT="$user_prompt"
    fi

    # Build the CLI command — find matching SKU photo for ref-image
    SKU_FILE=""
    if [[ "$SCRIPT_BRAND" = "mirra" ]] && [[ -d "$SKU_DIR" ]]; then
      case "$bento" in
        *Fusilli*) SKU_FILE="${SKU_DIR}/Fusilli-Bolognese-Bento-Box-Top-View.png" ;;
        *Pad*Thai*) SKU_FILE="${SKU_DIR}/Konjac-Pad-Thai-Bento-Box-Top-View.png" ;;
        *Katsu*) SKU_FILE="${SKU_DIR}/Japanese Curry Katsu Bento Box-Top View.png" ;;
        *Burrito*|*Buritto*) SKU_FILE="${SKU_DIR}/Fierry-Buritto-Bowl-Top-View.png" ;;
        *BBQ*|*Pita*) SKU_FILE="${SKU_DIR}/BBQ-Pita-Mushroom-Wrap-Bento-Box-Top-View.png" ;;
        *Eryngii*|*Golden*) SKU_FILE="${SKU_DIR}/Golden-Eryngii-Fragrant-Rice-Bento-Box-Top-View.png" ;;
        *Curry*Noodle*|*Konjac*Noodle*) SKU_FILE="${SKU_DIR}/Dry-Classic-Curry-Konjac-Noodle-Top-View.png" ;;
      esac
    fi

    # Build reference image args
    REF_ARGS=""
    if [[ -n "$SKU_FILE" ]] && [[ -f "$SKU_FILE" ]]; then
      LOGO="${BRAND_ASSETS}/logo-black.png"
      if [[ -f "$LOGO" ]]; then
        REF_ARGS="--ref-image \"${SKU_FILE},${LOGO}\""
      else
        REF_ARGS="--ref-image \"${SKU_FILE}\""
      fi
    fi

    # Use generate-and-audit.sh wrapper: Generate → Audit → Notion → Room post
    # The wrapper prepends 'generate' and passes all args to nanobanana-gen.sh
    CMD="bash ${GENERATE_AUDIT} --brand ${SCRIPT_BRAND} --prompt \"${PROMPT}\" --size 2K --ratio ${ratio} --model flash --use-case ${ad_type} --funnel-stage ${funnel}"
    if [[ -n "$REF_ARGS" ]]; then
      CMD="${CMD} ${REF_ARGS}"
    else
      # No manual SKU found — enable auto-ref to pick from catalog
      CMD="${CMD} --auto-ref"
    fi

    echo "SCRIPT:${LABEL}"
    echo "TYPE:single-gen"
    echo "BRAND:${SCRIPT_BRAND}"
    echo "AD_TYPE:${ad_type}"
    echo "RATIO:${ratio}"
    echo "FUNNEL:${funnel}"
    if [[ -n "$bento" ]]; then
      echo "BENTO:${bento}"
    fi
    echo "CMD:${CMD}"

    echo "{\"ts\":\"$TS\",\"label\":\"$LABEL\",\"tier\":\"script\",\"type\":\"single-gen\",\"brand\":\"$SCRIPT_BRAND\",\"ad_type\":\"$ad_type\",\"ratio\":\"$ratio\"}" >> "$DISPATCH_LOG"
    exit 0
    fi  # end of "not a video task" guard

  fi  # end of TIER=script image block

  # --- VIDEO SCRIPT: Direct video generation via video-gen.sh ---
  # When task is "generate mirra video" with clear brand context, run video-gen.sh directly
  # Auto-ref will find product photos, auto-forge will add branding
  # ONLY runs when detect_tier returned "script" for a video task (excludes ugc/intro/creative)
  if [[ "$TIER" = "script" ]] && echo "$TASK_LOWER" | grep -qiE '(generate|create|make).*(video|clip|reel)|(video|clip|reel).*(generate|create|make)|sora.*(generate|video)|kling.*(generate|video)'; then
    VIDEO_GEN="/Users/jennwoeiloh/.openclaw/skills/video-gen/scripts/video-gen.sh"

    # Detect video provider
    video_provider="sora"
    if echo "$TASK_LOWER" | grep -qiE 'kling'; then video_provider="kling"
    elif echo "$TASK_LOWER" | grep -qiE 'wan'; then video_provider="wan"
    fi

    # Detect duration
    video_duration="8"
    if echo "$TASK_LOWER" | grep -qiE '4.?s|4 sec|short'; then video_duration="4"
    elif echo "$TASK_LOWER" | grep -qiE '12.?s|12 sec|long'; then video_duration="12"
    fi

    # Detect aspect ratio
    video_ratio="9:16"
    if echo "$TASK_LOWER" | grep -qiE '16:9|landscape|youtube'; then video_ratio="16:9"
    elif echo "$TASK_LOWER" | grep -qiE '1:1|square|feed'; then video_ratio="1:1"
    fi

    # Extract prompt (strip the "generate mirra video" part, keep the description)
    video_prompt=$(echo "$TASK" | sed 's/[Gg]enerate\|[Cc]reate\|[Mm]ake//g' | sed 's/mirra\|pinxin\|wholey\|serein\|rasaya//gi' | sed 's/video\|clip\|reel\|sora\|kling\|wan//gi' | sed 's/^ *//;s/ *$//' | sed 's/  */ /g')
    if [ -z "$video_prompt" ] || [ ${#video_prompt} -lt 5 ]; then
      video_prompt="Top-down cinematic reveal of bento box with fresh vibrant ingredients, steam rising gently"
    fi

    # Build command — auto-ref is automatic when --brand is set
    if [ "$video_provider" = "sora" ]; then
      CMD="bash ${VIDEO_GEN} sora generate --prompt \"${video_prompt}\" --brand ${SCRIPT_BRAND} --duration ${video_duration} --aspect-ratio ${video_ratio}"
    elif [ "$video_provider" = "kling" ]; then
      CMD="bash ${VIDEO_GEN} kling text2video --prompt \"${video_prompt}\" --brand ${SCRIPT_BRAND} --duration ${video_duration}"
    else
      CMD="bash ${VIDEO_GEN} wan text2video --prompt \"${video_prompt}\" --brand ${SCRIPT_BRAND} --duration ${video_duration} --aspect-ratio ${video_ratio}"
    fi

    echo "SCRIPT:${LABEL}"
    echo "TYPE:video-gen"
    echo "BRAND:${SCRIPT_BRAND}"
    echo "PROVIDER:${video_provider}"
    echo "DURATION:${video_duration}s"
    echo "RATIO:${video_ratio}"
    echo "CMD:${CMD}"

    echo "{\"ts\":\"$TS\",\"label\":\"$LABEL\",\"tier\":\"script\",\"type\":\"video-gen\",\"brand\":\"$SCRIPT_BRAND\",\"provider\":\"$video_provider\"}" >> "$DISPATCH_LOG"
    exit 0
  fi

  # (clip-factory SCRIPT block moved earlier — before image gen section)

  # --- TAOZ AUTO-UPGRADE: All Taoz tasks → Claude Code CLI ---
  # Taoz runs on glm-4.7-flash (too weak for code/thinking). ALWAYS fire Claude Code CLI.
  # Catches taoz tasks from keyword routing that bypassed triage CODE_TIER detection.
  if [[ "$TIER" = "dispatch" && "$AGENT" = "taoz" && -z "$CODE_TIER" ]]; then
    # KEYWORD-LEVEL MODEL HINTS: Skip Haiku triage if keywords clearly indicate complexity
    # These patterns FORCE Opus — no need to ask Haiku
    if echo "$TASK_LOWER" | grep -qiE '(deep.?think|restyle.*(entire|full|whole|all)|refactor.*(entire|full|whole|all|system)|redesign.*(system|architecture|infra)|rebuild.*(system|entire|full)|think.*(about|through|deeply|hard)|architect|architecture|plan.*(migration|refactor|rebuild|restructure)|review.*(codebase|system|entire)|full.*(audit|review|rewrite)|overhaul)'; then
      CODE_TIER="code_complex"
    # Multi-task detection — "X and Y and Z"
    elif echo "$TASK_LOWER" | grep -qiE '(fix|build|create|update|add|refactor).*(and|then).*(fix|build|create|update|add|refactor).*(and|then)'; then
      CODE_TIER="code_multi"
    else
      # Default: ask Haiku or fall back to sonnet
      CODE_TIER="code_simple"
      if [[ -f "$TRIAGE_SCRIPT" ]]; then
        _QUICK_TRIAGE=$(bash "$TRIAGE_SCRIPT" "$TASK" 2>/dev/null || echo "CODE_SIMPLE")
        case "$_QUICK_TRIAGE" in
          CODE_COMPLEX) CODE_TIER="code_complex" ;;
          CODE_MULTI) CODE_TIER="code_multi" ;;
          *) CODE_TIER="code_simple" ;;
        esac
      fi
    fi
  fi

  # --- TIER: CODE (Claude Code CLI, $0 subscription) ---
  # Fires claude-code-runner.sh directly — no glm-4.7-flash subagent needed
  if [[ -n "$CODE_TIER" ]]; then
    TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    LABEL="code-$(date +%H%M%S)"
    CLAUDE_RUNNER="$HOME/.openclaw/skills/claude-code/scripts/claude-code-runner.sh"

    # KEYWORD OPUS OVERRIDE — catches ALL code tasks regardless of how they got here
    # If task clearly needs deep reasoning, force Opus even if triage said code_simple
    if [[ "$CODE_TIER" = "code_simple" ]] && echo "$TASK_LOWER" | grep -qiE '(deep.?think|restyle.*(entire|full|whole|all)|refactor.*(entire|full|whole|all|system)|redesign.*(system|arch|pipeline|infra)|rebuild.*(entire|full|whole|system)|think.*(about|through|deeply|hard).*(system|arch|gateway|dispatch|pipeline|infra|code|routing)|architect|full.*(audit|review|rewrite|overhaul)|plan.*(migrat|refactor|rebuild|restructur)|review.*(entire|full|whole|codebase|system))'; then
      CODE_TIER="code_complex"
    fi

    # Map triage category → CLI model
    case "$CODE_TIER" in
      code_simple) CLI_MODEL="sonnet" ;;
      code_complex) CLI_MODEL="opus" ;;
      code_multi) CLI_MODEL="sonnet" ;;  # Sonnet orchestrates multi-task via Agent Teams
      *) CLI_MODEL="sonnet" ;;
    esac

    echo "CODE:${CODE_TIER}:${LABEL}"
    echo "MODEL:${CLI_MODEL}"
    echo "AGENT:taoz"
    echo "TASK:${TASK}"
    echo "CMD:bash ${CLAUDE_RUNNER} dispatch \"$(echo "$TASK" | sed 's/"/\\"/g')\" zenni build --model ${CLI_MODEL}"
    echo "SOURCE:${SOURCE}"

    echo "{\"ts\":\"$TS\",\"label\":\"$LABEL\",\"tier\":\"code\",\"code_tier\":\"$CODE_TIER\",\"model\":\"$CLI_MODEL\",\"source\":\"${SOURCE}\",\"status\":\"classified\"}" >> "$DISPATCH_LOG"
    exit 0
  fi

  # --- TIER: DISPATCH ---
  if [[ "$TIER" = "dispatch" ]]; then
    # Log the dispatch
    TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    LABEL="${AGENT}-$(date +%H%M%S)"
    TASK_PREVIEW=$(echo "$TASK" | head -c 200 | tr '\n' ' ')
    echo "{\"ts\":\"$TS\",\"agent\":\"$AGENT\",\"label\":\"$LABEL\",\"task\":\"$(echo "$TASK_PREVIEW" | sed 's/"/\\"/g')\",\"tier\":\"dispatch\",\"status\":\"dispatching\"}" >> "$DISPATCH_LOG"

    # Build context-enriched task for the agent
    BRAND_CONTEXT=""
    if echo "$TASK_LOWER" | grep -qiE 'mirra'; then
      BRAND_CONTEXT="Brand: MIRRA (bento health food, NOT skincare). Read /Users/jennwoeiloh/.openclaw/brands/mirra/DNA.json for brand voice, colors, and guidelines. Directions: /Users/jennwoeiloh/.openclaw/brands/mirra/campaigns/directions.json. Templates: /Users/jennwoeiloh/.openclaw/brands/mirra/templates/templates.json."
    elif echo "$TASK_LOWER" | grep -qiE 'pinxin'; then
      BRAND_CONTEXT="Brand: Pinxin Vegan. Read /Users/jennwoeiloh/.openclaw/brands/pinxin-vegan/DNA.json for brand voice, colors, and guidelines."
    elif echo "$TASK_LOWER" | grep -qiE 'wholey'; then
      BRAND_CONTEXT="Brand: Wholey Wonder. Read /Users/jennwoeiloh/.openclaw/brands/wholey-wonder/DNA.json for brand voice, colors, and guidelines."
    elif echo "$TASK_LOWER" | grep -qiE 'serein'; then
      BRAND_CONTEXT="Brand: Serein. Read /Users/jennwoeiloh/.openclaw/brands/serein/DNA.json for brand voice, colors, and guidelines."
    elif echo "$TASK_LOWER" | grep -qiE 'rasaya'; then
      BRAND_CONTEXT="Brand: Rasaya. Read /Users/jennwoeiloh/.openclaw/brands/rasaya/DNA.json for brand voice, colors, and guidelines."
    elif echo "$TASK_LOWER" | grep -qiE 'dr.?stan'; then
      BRAND_CONTEXT="Brand: Dr Stan. Read /Users/jennwoeiloh/.openclaw/brands/dr-stan/DNA.json for brand voice, colors, and guidelines."
    elif echo "$TASK_LOWER" | grep -qiE 'gaia.?eats'; then
      BRAND_CONTEXT="Brand: Gaia Eats. Read /Users/jennwoeiloh/.openclaw/brands/gaia-eats/DNA.json for brand voice, colors, and guidelines."
    elif echo "$TASK_LOWER" | grep -qiE 'gaia.?os'; then
      BRAND_CONTEXT="Brand: GAIA OS. Read /Users/jennwoeiloh/.openclaw/brands/gaia-os/DNA.json for character design, agent visual identity. NOT a food brand — this is the AI agent visual identity system."
    fi

    # CHARACTER tasks (hair, outfit, avatar, etc.) always use gaia-os brand
    if echo "$TASK_LOWER" | grep -qiE '(change|modify|update|remove|redesign|edit|rework).*(hair|outfit|suit|look|headgear|helmet|character|avatar|attire|cloth|dress|armor|armour)|(hair|outfit|suit|look|headgear|helmet|character|avatar).*(change|modif|redesign|update|edit|rework)|lock.*(character|face|avatar)|character.*(lock|creation|design)'; then
      BRAND_CONTEXT="Brand: GAIA OS. Read /Users/jennwoeiloh/.openclaw/brands/gaia-os/DNA.json for character design, agent visual identity. NOT a food brand — this is the AI agent visual identity system. Characters: /Users/jennwoeiloh/.openclaw/workspace/data/characters/"
    fi

    # Build tool instructions for subagent (subagents get minimal prompt — need explicit commands)
    TOOL_INSTRUCTIONS=""
    DETECTED_BRAND=""
    if echo "$TASK_LOWER" | grep -qiE 'mirra'; then DETECTED_BRAND="mirra"
    elif echo "$TASK_LOWER" | grep -qiE 'pinxin'; then DETECTED_BRAND="pinxin-vegan"
    elif echo "$TASK_LOWER" | grep -qiE 'wholey'; then DETECTED_BRAND="wholey-wonder"
    elif echo "$TASK_LOWER" | grep -qiE 'serein'; then DETECTED_BRAND="serein"
    elif echo "$TASK_LOWER" | grep -qiE 'rasaya'; then DETECTED_BRAND="rasaya"
    elif echo "$TASK_LOWER" | grep -qiE 'dr.?stan'; then DETECTED_BRAND="dr-stan"
    elif echo "$TASK_LOWER" | grep -qiE 'gaia.?eats'; then DETECTED_BRAND="gaia-eats"
    elif echo "$TASK_LOWER" | grep -qiE 'gaia.?os|gaia'; then DETECTED_BRAND="gaia-os"
    fi

    # CHARACTER tasks (hair, outfit, avatar, etc.) always use gaia-os brand — NOT mirra
    if echo "$TASK_LOWER" | grep -qiE '(change|modify|update|remove|redesign|edit|rework).*(hair|outfit|suit|look|headgear|helmet|character|avatar|attire|cloth|dress|armor|armour)|(hair|outfit|suit|look|headgear|helmet|character|avatar).*(change|modif|redesign|update|edit|rework)|lock.*(character|face|avatar)|character.*(lock|creation|design)'; then
      DETECTED_BRAND="gaia-os"
    fi

    if [[ "$AGENT" = "iris" ]]; then
      # BULK image generation — detect batch/bulk requests
      if echo "$TASK_LOWER" | grep -qiE '(batch|bulk|multiple|mass).*(generat|create|make|image|ad|visual)|(\d+)\s*(ads?|images?)'; then
        TOOL_INSTRUCTIONS="

=== MANDATORY TOOL INSTRUCTIONS — BULK GENERATION ===

RULE 1: NEVER write your own Python/curl to call Gemini API. Use the CLI tools only.
RULE 2: Use ONLY absolute paths. NEVER use ~ or relative paths.

For BULK generation, use the ad-bulk-gen.sh pipeline:

STEP 1: If you have a markdown prompts file, convert it to JSON:
  bash /Users/jennwoeiloh/.openclaw/skills/ad-composer/scripts/ad-bulk-gen.sh convert-md \\
    --file /path/to/prompts.md --output /tmp/prompts.json

STEP 2: Run bulk generation:
  bash /Users/jennwoeiloh/.openclaw/skills/ad-composer/scripts/ad-bulk-gen.sh from-file \\
    --brand ${DETECTED_BRAND:-gaia-os} --file /tmp/prompts.json --model flash --size 2K

STEP 3: Check status:
  bash /Users/jennwoeiloh/.openclaw/skills/ad-composer/scripts/ad-bulk-gen.sh status --batch <batch-id>

STEP 4: Audit all results:
  bash /Users/jennwoeiloh/.openclaw/skills/ad-composer/scripts/ad-bulk-gen.sh audit --batch <batch-id>

STEP 5: Retry failures:
  bash /Users/jennwoeiloh/.openclaw/skills/ad-composer/scripts/ad-bulk-gen.sh retry --batch <batch-id>

The pipeline auto-registers all generated images to the seed bank with proper tags.
Report back with the batch ID and success/failure counts.

=== END MANDATORY INSTRUCTIONS ==="
      # Single image/ad generation — choose between COMPOSITOR (real assets) and AI GENERATOR
      elif echo "$TASK_LOWER" | grep -qiE '(generate|create|make|compose).*(ad|image|visual|poster|banner|comparison|hero|grid|lifestyle)'; then
        ad_type="product"
        funnel="MOFU"
        if echo "$TASK_LOWER" | grep -qiE 'comparison'; then ad_type="comparison"; fi
        if echo "$TASK_LOWER" | grep -qiE 'hero'; then ad_type="hero"; fi
        if echo "$TASK_LOWER" | grep -qiE 'grid|menu|catalog'; then ad_type="grid"; fi
        if echo "$TASK_LOWER" | grep -qiE 'lifestyle'; then ad_type="lifestyle"; fi
        if echo "$TASK_LOWER" | grep -qiE 'bofu'; then funnel="BOFU"; fi
        if echo "$TASK_LOWER" | grep -qiE 'tofu'; then funnel="TOFU"; fi

        # HYBRID APPROACH: NanoBanana generates with brand vibes, BUT uses real product photos + logo + style refs
        # This gives AI art direction + real brand assets (not hallucinated)

        # Build reference images list based on brand
        BRAND_ASSETS_DIR="/Users/jennwoeiloh/.openclaw/brands/${DETECTED_BRAND:-gaia-os}/assets"
        SKU_DIR="/Users/jennwoeiloh/.openclaw/workspace/brands/${DETECTED_BRAND:-gaia-os}/march-campaign/drive-assets/My product bento"
        LOGO_PATH="${BRAND_ASSETS_DIR}/logo-black.png"
        STYLE_REF="${BRAND_ASSETS_DIR}/ref-comparison-v1.jpg"

        TOOL_INSTRUCTIONS="

=== MANDATORY TOOL INSTRUCTIONS — DO NOT DEVIATE ===

RULE 1: NEVER write your own Python, curl, or any code to call the Gemini/Google API directly. It WILL fail.
RULE 2: Use the FULL PIPELINE wrapper (generates + audits + registers in Notion + posts to room):
  bash /Users/jennwoeiloh/.openclaw/skills/nanobanana/scripts/generate-and-audit.sh
RULE 3: Use ONLY absolute paths. NEVER use ~ or relative paths.
RULE 4: Run the CLI via exec (shell command). Do NOT import google.generativeai or use any Python SDK.
RULE 5: Use --auto-ref to auto-pick reference images from catalog. No manual searching needed.

HOW TO GENERATE AN IMAGE — Full pipeline (generate + audit + Notion + room):

bash /Users/jennwoeiloh/.openclaw/skills/nanobanana/scripts/generate-and-audit.sh \\
  --brand ${DETECTED_BRAND:-gaia-os} \\
  --prompt \"YOUR PROMPT HERE\" \\
  --size 2K \\
  --ratio 1:1 \\
  --model flash \\
  --use-case product \\
  --auto-ref

For HYBRID ads with specific SKU ref (overrides auto-ref):

bash /Users/jennwoeiloh/.openclaw/skills/nanobanana/scripts/generate-and-audit.sh \\
  --brand ${DETECTED_BRAND:-gaia-os} \\
  --ref-image \"SKU_PHOTO_PATH,${STYLE_REF},${LOGO_PATH}\" \\
  --prompt \"YOUR PROMPT HERE\" \\
  --size 2K \\
  --ratio 1:1 \\
  --model flash \\
  --funnel-stage ${funnel} \\
  --use-case product

REFERENCE TOOLS (auto-ref handles this, but for manual control):
  Browse refs: bash /Users/jennwoeiloh/.openclaw/skills/ref-picker/scripts/ref-picker.sh browse --brand ${DETECTED_BRAND:-gaia-os}
  Pick best refs: bash /Users/jennwoeiloh/.openclaw/skills/ref-picker/scripts/ref-picker.sh pick --brand ${DETECTED_BRAND:-gaia-os} --use-case product
  Assemble SKU+Model+Scene: bash /Users/jennwoeiloh/.openclaw/skills/visual-registry/scripts/visual-registry.sh assemble --sku va-X --model va-Y --scene va-Z --command

Available SKU photos in: ${SKU_DIR}/
  BBQ-Pita-Mushroom-Wrap-Bento-Box-Top-View.png, Dry-Classic-Curry-Konjac-Noodle-Top-View.png, Fierry-Buritto-Bowl-Top-View.png, Fusilli-Bolognese-Bento-Box-Top-View.png, Golden-Eryngii-Fragrant-Rice-Bento-Box-Top-View.png, Japanese Curry Katsu Bento Box-Top View.png, Konjac-Pad-Thai-Bento-Box-Top-View.png

SUPPORTED FLAGS: --brand (required), --prompt (required), --size (1K/2K/4K), --ratio (1:1/4:5/9:16/16:9), --model (flash/pro), --ref-image (comma-separated paths), --use-case (product/food/lifestyle/social), --funnel-stage (TOFU/MOFU/BOFU), --campaign, --style-seed, --raw, --dry-run, --auto-ref (auto-picks refs from catalog)

PROMPT TIPS:
- COMPARISON ads: 'Split comparison layout. LEFT: generic fast food. RIGHT: EXACT [bento] from reference — keep food identical. MIRRA logo top-right. Calorie badges. Brand colors salmon pink #F7AB9F and cream #FFF9EB.'
- HERO ads: 'Center EXACT [bento] from reference. MIRRA logo top-right. Headline in serif. Gradient background.'
- Always say 'EXACT' and 'from reference' to anchor real product photos
- Always mention brand colors, organic blob shapes, serif headline font

The pipeline handles: API auth, rate limiting, brand DNA enrichment, seed bank registration, image extraction, visual audit, Notion registration, creative room posting.
After running, report the output image path printed by the CLI.

=== END MANDATORY INSTRUCTIONS ==="
      fi

      # Video generation
      if echo "$TASK_LOWER" | grep -qiE '(video|ugc|reel|clip|animate)'; then
        TOOL_INSTRUCTIONS="

IMPORTANT: You are a subagent. Use ONLY absolute paths. NEVER use ~ in paths.

For video generation, run:
bash /Users/jennwoeiloh/.openclaw/skills/video-gen/scripts/video-gen.sh sora image2video --image <image_path> --prompt \"<motion description>\" --duration 8 --aspect-ratio 9:16

For text-to-video:
bash /Users/jennwoeiloh/.openclaw/skills/video-gen/scripts/video-gen.sh sora generate --prompt \"<scene description>\" --duration 8 --aspect-ratio 9:16

Report back with the output video path."
      fi

      # Social publishing
      if echo "$TASK_LOWER" | grep -qiE '(post.*(ig|instagram|fb|facebook)|publish|schedule.?post)'; then
        TOOL_INSTRUCTIONS="

IMPORTANT: You are a subagent. Use ONLY absolute paths. NEVER use ~ in paths.

For social publishing, use the ad-image-gen.sh or report the image path for manual posting.
List recent images: ls -lt /Users/jennwoeiloh/.openclaw/workspace/data/images/${DETECTED_BRAND:-gaia-os}/ | head -5"
      fi
    fi

    if [[ "$AGENT" = "dreami" ]]; then
      if echo "$TASK_LOWER" | grep -qiE '(video|ugc|reel|clip|animate)'; then
        TOOL_INSTRUCTIONS="

IMPORTANT: You are a subagent. Use ONLY absolute paths. NEVER use ~ in paths.
Brand DNA: cat /Users/jennwoeiloh/.openclaw/brands/${DETECTED_BRAND:-gaia-os}/DNA.json

For video generation:
1. First write a script/brief for the video
2. Generate source image (full pipeline with audit + Notion):
   bash /Users/jennwoeiloh/.openclaw/skills/nanobanana/scripts/generate-and-audit.sh --brand -e --prompt \"<scene description>\" --use-case lifestyle --ratio 9:16 --auto-ref
3. Then animate: bash /Users/jennwoeiloh/.openclaw/skills/video-gen/scripts/video-gen.sh sora image2video --image <image_path> --prompt \"<motion description>\" --duration 8 --aspect-ratio 9:16
Report back with the output video path."
      else
        # Inject latest performance insights if available
        PERF_INSIGHTS=""
        PERF_FILE="/Users/jennwoeiloh/.openclaw/workspace/data/performance-insights.txt"
        if [ -f "$PERF_FILE" ]; then
          PERF_INSIGHTS="

PERFORMANCE DATA (use this to guide your creative decisions):
$(tail -5 "$PERF_FILE")
"
        fi
        TOOL_INSTRUCTIONS="

IMPORTANT: You are a subagent. Use ONLY absolute paths. NEVER use ~ in paths.
Brand DNA: cat /Users/jennwoeiloh/.openclaw/brands/${DETECTED_BRAND:-gaia-os}/DNA.json
Campaign directions: cat /Users/jennwoeiloh/.openclaw/brands/${DETECTED_BRAND:-gaia-os}/campaigns/directions.json
${PERF_INSIGHTS}
Post output to creative room: printf '{\"ts\":%s000,\"agent\":\"dreami\",\"room\":\"creative\",\"msg\":\"YOUR_OUTPUT\"}\n' \"\$(date +%s)\" >> /Users/jennwoeiloh/.openclaw/workspace/rooms/creative.jsonl"
      fi
    fi

    if [[ "$AGENT" = "hermes" ]]; then
      if echo "$TASK_LOWER" | grep -qiE '(create|plan).*(campaign)'; then
        TOOL_INSTRUCTIONS="

IMPORTANT: You are a subagent. Use ONLY absolute paths. NEVER use ~ in paths.

To create a campaign, run:
bash /Users/jennwoeiloh/.openclaw/skills/campaign-planner/scripts/campaign-planner.sh create --brand -e --direction <pick from directions.json> --template-type M2 --variants 5

To list directions: bash /Users/jennwoeiloh/.openclaw/skills/campaign-planner/scripts/campaign-planner.sh directions --brand -e
Brand DNA: cat /Users/jennwoeiloh/.openclaw/brands/${DETECTED_BRAND:-gaia-os}/DNA.json"
      fi
    fi

    FULL_TASK="${TASK}"
    if [ -n "$BRAND_CONTEXT" ]; then
      FULL_TASK="${TASK}. ${BRAND_CONTEXT}"
    fi
    if [ -n "$TOOL_INSTRUCTIONS" ]; then
      FULL_TASK="${FULL_TASK}${TOOL_INSTRUCTIONS}"
    fi

    # Return dispatch info for Zenni to use sessions_spawn natively
    # Format: DISPATCH:<agent>:<label>:<enriched_task>
    echo "DISPATCH:${AGENT}:${LABEL}"
    echo "AGENT:${AGENT}"
    echo "TASK:${FULL_TASK}"
    echo "LABEL:${LABEL}"
    echo "SOURCE:${SOURCE}"

    # Log dispatch instruction with routing path
    echo "{\"ts\":\"$TS\",\"agent\":\"$AGENT\",\"label\":\"$LABEL\",\"status\":\"classified\",\"method\":\"sessions_spawn\",\"source\":\"${SOURCE}\"}" >> "$DISPATCH_LOG"

    exit 0
  fi

  # Should not reach here
  echo "ERROR:unknown_tier:${TIER}"
  exit 1
fi

# ── VERBOSE OUTPUT (backward compat — no --auto-dispatch) ─────────────────────
MODEL=$(agent_to_model "$AGENT")
COST=$(agent_to_cost "$AGENT")

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎯 TASK CLASSIFICATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Task: $TASK"
echo ""

echo "✅ AGENT:      $(echo "$AGENT" | tr '[:lower:]' '[:upper:]')"
echo "   Source:     $SOURCE"
echo "   Model:      $MODEL"
echo "   Cost tier:  $COST"
echo "   Complexity: $COMPLEXITY"
echo "   Tier:       $TIER"
echo ""
echo "📋 Dispatch command:"
echo "   bash /Users/jennwoeiloh/.openclaw/skills/orchestrate-v2/scripts/dispatch.sh \\"
echo "     \"$AGENT\" \\"
echo "     \"$TASK\" \\"
echo "     \"${AGENT}-$(date +%H%M)\""

# ── WORKFLOW LOOKUP ───────────────────────────────────────────────────────────
WORKFLOW_LOOKUP="$HOME/.openclaw/workspace/scripts/workflow-lookup.sh"
if [ -f "$WORKFLOW_LOOKUP" ]; then
  WORKFLOW_RESULT=$(bash "$WORKFLOW_LOOKUP" "$TASK" 2>/dev/null || true)
  if [ -n "$WORKFLOW_RESULT" ] && ! echo "$WORKFLOW_RESULT" | grep -q '"error"'; then
    WF_ID=$(echo "$WORKFLOW_RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('id',''))" 2>/dev/null || true)
    WF_NAME=$(echo "$WORKFLOW_RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('name',''))" 2>/dev/null || true)
    WF_DOC=$(echo "$WORKFLOW_RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('doc_path',''))" 2>/dev/null || true)
    WF_CMD=$(echo "$WORKFLOW_RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('entry_command',''))" 2>/dev/null || true)
    if [ -n "$WF_ID" ]; then
      echo ""
      echo "📖 WORKFLOW:   $WF_ID ($WF_NAME)"
      echo "   Doc:        $WF_DOC"
      echo "   Command:    $WF_CMD"
      echo "   Lookup:     bash workflow-lookup.sh --id $WF_ID"
    fi
  fi
fi

# ── PERMISSION ────────────────────────────────────────────────────────────────
if [[ -n "$SENDER" ]]; then
  echo ""
  if [[ "$PERMISSION" = "allowed" ]]; then
    echo "🔑 PERMISSION: ✅ $PERMISSION (sender: $(echo "$SENDER" | tr -d ' -'))"
  else
    echo "🔑 PERMISSION: ❌ $PERMISSION (sender: $(echo "$SENDER" | tr -d ' -') → $AGENT blocked)"
    echo "   Redirect:   Flag for Jenn or suggest alternative agent"
  fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
