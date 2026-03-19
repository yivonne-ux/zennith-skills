/* WARNING: Script requires that SQLITE_DBCONFIG_DEFENSIVE be disabled */
PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
CREATE TABLE strategies (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    brand TEXT NOT NULL,
    title TEXT NOT NULL,
    brief TEXT,
    status TEXT DEFAULT 'draft',
    funnel_stage TEXT,
    formula_used TEXT,
    seasonal_context TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO strategies VALUES(1,'pinxin','Poon Choi Campaign','BOFU conversion ad for Yuanxiao Festival','draft','BOFU',NULL,NULL,'2026-02-20 15:27:55','2026-02-20 15:27:55');
CREATE TABLE creatives (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    strategy_id INTEGER REFERENCES strategies(id),
    type TEXT NOT NULL,
    ads_type TEXT,
    hook TEXT,
    content TEXT,
    cta TEXT,
    format TEXT,
    platform TEXT,
    file_path TEXT,
    meta_ad_id TEXT,
    status TEXT DEFAULT 'draft',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO creatives VALUES(1,NULL,'social_post','RECIPE_REBELS','Katsu that hits different. Zero guilt.',unistr('@mirramalaysia\u000a\u000aKatsu that hits different. Zero guilt. 💫\u000a\u000aOur Japanese Curry Katsu Bento is giving main character energy — crispy plant-based katsu, house-made golden curry, fluffy rice, and pickled sides that slap.\u000a\u000a430 cal | 22g protein | All the flavour\u000a\u000aSiapa kata healthy food boring? 🙄\u000a\u000aOrder now — your taste buds (and your waistline) will thank you.'),'Link in bio to order 🛒','1080x1350','instagram_feed','/Users/jennwoeiloh/.openclaw/workspace/data/output/mirra/2026-03-01/mirra-RECIPE_REBELS-1772373900.png',NULL,'pending_review','2026-03-01 14:05:01');
INSERT INTO creatives VALUES(2,NULL,'social_post','RECIPE_REBELS','430 calories. Zero regrets. Full send. 🍛',unistr('Crispy plant-based katsu that shatters like your ex''s excuses. 💅\u000a\u000aGolden Japanese curry, slow-simmered with intention. Panko-crusted katsu that''s all crunch, no compromise. Sedap gila, but make it wellness.\u000a\u000aThis isn''t ''diet food.'' This is MIRRA.\u000a\u000a🔥 430 cal | 28g protein | 8g fiber\u000a\u000aNo gluten. No guilt. All flavour.\u000a\u000a@mirramalaysia'),'Order now — your bento is waiting. Link in bio.','1080x1350','instagram_feed','',NULL,'pending_review','2026-03-01 14:13:49');
INSERT INTO creatives VALUES(3,NULL,'social_post','BEYOND_THE_FOOD','Treating yourself is not selfish. It''s survival. 🌸',unistr('You are not a machine. You are allowed to pause. 🕊️\u000a\u000aThat extra hour of sleep. The meal you didn''t have to cook. Saying ''no'' without apologising.\u000a\u000aSelf-care bukan selfish — it''s self-preservation. You cannot pour from an empty cup. You cannot glow when you''re running on fumes.\u000a\u000aMIRRA isn''t just what''s on your plate. It''s the permission to put yourself first.\u000a\u000aYour Sunday ritual starts here.\u000a\u000a@mirramalaysia'),'What''s your non-negotiable self-care? Tell us below.','1080x1350','instagram_feed','',NULL,'pending_review','2026-03-01 14:14:21');
INSERT INTO creatives VALUES(4,NULL,'social_post','WOMEN_WHO_GET_IT','','','','1080x1350','instagram_feed','/Users/jennwoeiloh/.openclaw/workspace/data/output/mirra/2026-03-06/mirra-WOMEN_WHO_GET_IT-1772777065.png',NULL,'pending_review','2026-03-06 06:05:41');
INSERT INTO creatives VALUES(5,NULL,'social_post','WOMEN_WHO_GET_IT','','','','1080x1350','instagram_feed','/Users/jennwoeiloh/.openclaw/workspace/data/output/mirra/2026-03-06/mirra-WOMEN_WHO_GET_IT-1772806004.png',NULL,'pending_review','2026-03-06 14:10:46');
INSERT INTO creatives VALUES(6,NULL,'social_post','WOMEN_WHO_GET_IT','','','','1080x1350','instagram_feed','/Users/jennwoeiloh/.openclaw/workspace/data/output/mirra/2026-03-07/mirra-WOMEN_WHO_GET_IT-1772813204.png',NULL,'pending_review','2026-03-06 16:11:01');
INSERT INTO creatives VALUES(7,NULL,'social_post','WOMEN_WHO_GET_IT','','','','1080x1350','instagram_feed','/Users/jennwoeiloh/.openclaw/workspace/data/output/mirra/2026-03-07/mirra-WOMEN_WHO_GET_IT-1772813541.png',NULL,'pending_review','2026-03-06 16:14:31');
INSERT INTO creatives VALUES(8,NULL,'social_post','RECIPE_REBELS','','','','1080x1350','instagram_feed','/Users/jennwoeiloh/.openclaw/workspace/data/output/mirra/2026-03-11/mirra-RECIPE_REBELS-1773210426.png',NULL,'pending_review','2026-03-11 06:28:45');
INSERT INTO creatives VALUES(9,NULL,'social_post','RECIPE_REBELS','',unistr('@mirramalaysia\u000a\u000aKatsu that won''t make you sleepy by 3pm 💤\u000a\u000aTired of that 3pm crash after your office lunch? We feel you, girl. That''s why our Japanese Curry Katsu Bento is here to save your workday!\u000a\u000a🍱 430 calories | 22g protein | Real ingredients\u000a✨ No MSG, no guilt, all the flavour\u000a\u000aCrispy plant-based katsu with our signature curry that''s been slow-cooked to perfection. Served with perfectly seasoned rice and fresh pickled sides.\u000a\u000aKena lagi dengan your 2pm meeting when you''re fueled with this? We don''t think so 😉\u000a\u000aPre-order now for delivery to your office! No more last-minute decisions.\u000a\u000a#MIRRA #OfficeLunch #HealthyBento #JapaneseCurry #PlantBased #KualaLumpur #WorkingGirlEats #MealDelivery #NoMoreCrash #LunchSolution'),'Pre-order now for delivery to your office! Link in bio 📦','1080x1350','instagram_feed','/Users/jennwoeiloh/.openclaw/workspace/data/output/mirra/2026-03-17/mirra-RECIPE_REBELS-1773728364.png',NULL,'pending_review','2026-03-17 06:21:10');
INSERT INTO creatives VALUES(10,NULL,'social_post','RECIPE_REBELS','','','','1080x1350','instagram_feed','/Users/jennwoeiloh/.openclaw/workspace/data/output/mirra/2026-03-17/mirra-RECIPE_REBELS-1773728151.png',NULL,'pending_review','2026-03-17 06:22:38');
INSERT INTO creatives VALUES(11,NULL,'social_post','RECIPE_REBELS','Katsu that won''t make you sleepy by 3pm 💤',unistr('@mirramalaysia\u000a\u000aKatsu that won''t make you sleepy by 3pm 💤\u000a\u000aTired of that 3pm crash after your office lunch? We feel you, girl. That''s why our Japanese Curry Katsu Bento is here to save your workday!\u000a\u000a🍱 430 calories | 22g protein | Real ingredients\u000a✨ No MSG, no guilt, all the flavour\u000a\u000aCrispy plant-based katsu with our signature curry that''s been slow-cooked to perfection. Served with perfectly seasoned rice and fresh pickled sides.\u000a\u000aKena lagi dengan your 2pm meeting when you''re fueled with this? We don''t think so 😉\u000a\u000aPre-order now for delivery to your office! No more last-minute decisions.\u000a\u000a#MIRRA #OfficeLunch #HealthyBento #JapaneseCurry #PlantBased #KualaLumpur #WorkingGirlEats #MealDelivery #NoMoreCrash #LunchSolution'),'Pre-order now for delivery to your office! Link in bio 📦','1080x1350','instagram_feed','/Users/jennwoeiloh/.openclaw/workspace/data/output/mirra/2026-03-17/mirra-RECIPE_REBELS-1773728364.png',NULL,'pending_review','2026-03-17 06:22:46');
CREATE TABLE seeds (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT NOT NULL,
    content TEXT NOT NULL,
    brand TEXT,
    platform TEXT,
    funnel_stage TEXT,
    formula_used TEXT,
    tags TEXT,
    parent_seed_id INTEGER REFERENCES seeds(id),
    impressions INTEGER DEFAULT 0,
    clicks INTEGER DEFAULT 0,
    ctr REAL DEFAULT 0,
    cpa REAL DEFAULT 0,
    roas REAL DEFAULT 0,
    is_winner BOOLEAN DEFAULT 0,
    confidence REAL DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO seeds VALUES(1,'hook','POV: You just discovered vegan Poon Choi can taste THIS good','pinxin','instagram_reels','TOFU','POV_hook',NULL,NULL,0,0,0.0,0.0,0.0,0,0.0,'2026-02-20 15:27:55');
CREATE TABLE campaigns (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    strategy_id INTEGER REFERENCES strategies(id),
    brand TEXT NOT NULL,
    name TEXT NOT NULL,
    meta_campaign_id TEXT,
    meta_account_id TEXT,
    status TEXT DEFAULT 'draft',
    budget_daily REAL,
    budget_total REAL,
    start_date DATE,
    end_date DATE,
    performance_json TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE ads_types (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    mode TEXT NOT NULL,
    description TEXT,
    specs TEXT
);
INSERT INTO ads_types VALUES(1,'product-hero','IMAGE','Single product beauty shot',NULL);
INSERT INTO ads_types VALUES(2,'before-after','IMAGE','Before/after transformation',NULL);
INSERT INTO ads_types VALUES(3,'testimonial','IMAGE','Customer testimonial card',NULL);
INSERT INTO ads_types VALUES(4,'ugc-style','IMAGE','User-generated content look',NULL);
INSERT INTO ads_types VALUES(5,'infographic','IMAGE','Data/stats visualization',NULL);
INSERT INTO ads_types VALUES(6,'lifestyle','IMAGE','Product in lifestyle context',NULL);
INSERT INTO ads_types VALUES(7,'carousel-product','IMAGE','Multi-image product carousel',NULL);
INSERT INTO ads_types VALUES(8,'flash-sale','IMAGE','Limited time offer graphic',NULL);
INSERT INTO ads_types VALUES(9,'bundle-deal','IMAGE','Multi-product bundle offer',NULL);
INSERT INTO ads_types VALUES(10,'ingredient-spotlight','IMAGE','Key ingredient highlight',NULL);
INSERT INTO ads_types VALUES(11,'comparison','IMAGE','Side-by-side comparison',NULL);
INSERT INTO ads_types VALUES(12,'recipe-card','IMAGE','Recipe/how-to card',NULL);
INSERT INTO ads_types VALUES(13,'social-proof','IMAGE','Reviews/ratings showcase',NULL);
INSERT INTO ads_types VALUES(14,'seasonal','IMAGE','Holiday/seasonal themed',NULL);
INSERT INTO ads_types VALUES(15,'talking-head','VIDEO','A-roll founder/expert speaking',NULL);
INSERT INTO ads_types VALUES(16,'product-demo','VIDEO','Product demonstration',NULL);
INSERT INTO ads_types VALUES(17,'unboxing','VIDEO','Package opening experience',NULL);
INSERT INTO ads_types VALUES(18,'behind-scenes','VIDEO','Making/production process',NULL);
INSERT INTO ads_types VALUES(19,'tutorial','VIDEO','How-to/educational',NULL);
INSERT INTO ads_types VALUES(20,'transformation','VIDEO','Before/after video',NULL);
INSERT INTO ads_types VALUES(21,'asmr-food','VIDEO','ASMR cooking/eating',NULL);
INSERT INTO ads_types VALUES(22,'street-food-hack','VIDEO','Heritage food twist',NULL);
INSERT INTO ads_types VALUES(23,'pov-eating','VIDEO','POV food experience',NULL);
INSERT INTO ads_types VALUES(24,'vlog-style','VIDEO','Day-in-the-life format',NULL);
INSERT INTO ads_types VALUES(25,'interview','VIDEO','Q&A format',NULL);
INSERT INTO ads_types VALUES(26,'reels-trend','CLIP','Trending audio/format',NULL);
INSERT INTO ads_types VALUES(27,'quick-tip','CLIP','15s quick tip',NULL);
INSERT INTO ads_types VALUES(28,'reaction','CLIP','Reaction to product/food',NULL);
INSERT INTO ads_types VALUES(29,'duet-stitch','CLIP','Duet/stitch format',NULL);
INSERT INTO ads_types VALUES(30,'challenge','CLIP','Challenge participation',NULL);
INSERT INTO ads_types VALUES(31,'countdown','CLIP','Countdown reveal',NULL);
INSERT INTO ads_types VALUES(32,'pack-order','CLIP','Packing/shipping ASMR',NULL);
INSERT INTO ads_types VALUES(33,'taste-test','CLIP','Blind taste test',NULL);
INSERT INTO ads_types VALUES(34,'day-in-life','CLIP','Day-in-the-life snippet',NULL);
INSERT INTO ads_types VALUES(35,'text-overlay-hook','CLIP','Bold text + visual hook',NULL);
INSERT INTO ads_types VALUES(36,'meme-format','CLIP','Meme-style content',NULL);
INSERT INTO ads_types VALUES(37,'sound-trending','CLIP','Trending sound + visual',NULL);
CREATE TABLE brands (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    slug TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    meta_ad_account_id TEXT,
    meta_page_id TEXT,
    description TEXT,
    brand_dna TEXT
);
INSERT INTO brands VALUES(1,'pinxin-vegan-my','Pinxin Vegan MY','act_3455146008076191',NULL,NULL,NULL);
INSERT INTO brands VALUES(2,'pinxin-vegan-malaysia','Pinxin Vegan Malaysia','act_138893238421035',NULL,NULL,NULL);
INSERT INTO brands VALUES(3,'pinxin-vegan-cooking','Pinxin Vegan Cooking','act_2034433410051017',NULL,NULL,NULL);
INSERT INTO brands VALUES(4,'wholey-wonder','Wholey Wonder','act_1399449027116965',NULL,NULL,NULL);
INSERT INTO brands VALUES(5,'wholey-wonder-damai','Wholey Wonder Damai',NULL,NULL,NULL,NULL);
INSERT INTO brands VALUES(6,'rasaya-wellness','Rasaya Wellness',NULL,NULL,NULL,NULL);
INSERT INTO brands VALUES(7,'mirra-eats','Mirra Eats',NULL,NULL,NULL,NULL);
INSERT INTO brands VALUES(8,'mirra-meals','Mirra Meals',NULL,NULL,NULL,NULL);
INSERT INTO brands VALUES(9,'gaia-eats','Gaia Eats',NULL,NULL,NULL,NULL);
INSERT INTO brands VALUES(10,'gaiamarkets','Gaiamarkets.com','act_114306219075053',NULL,NULL,NULL);
CREATE TABLE reference_library (id INTEGER PRIMARY KEY AUTOINCREMENT, source TEXT NOT NULL, brand_id INTEGER REFERENCES brands(id), content_type TEXT, url TEXT, title TEXT, description TEXT, metrics TEXT, tags TEXT, scraped_at TEXT DEFAULT (datetime('now')), expires_at TEXT);
INSERT INTO reference_library VALUES(1,'designs-folder',7,'comparison','/Users/jennwoeiloh/Desktop/DESIGNS/M4A-MOFU-en-Calorie Conscious Cheat day-Comparison-Img-a541454f/v1.jpg','v1.jpg','M4A This or That comparison - fried rice vs MIRRA bento, split pink/cream layout',NULL,'comparison,this-or-that,calorie,split-layout','2026-03-01 19:28:39',NULL);
INSERT INTO reference_library VALUES(2,'designs-folder',7,'comparison','/Users/jennwoeiloh/Desktop/DESIGNS/M4A-MOFU-en-Calorie Conscious Cheat day-Comparison-Img-a541454f/v2.jpg','v2.jpg','M4A This or That v2 - alternative layout with different food',NULL,'comparison,this-or-that,calorie','2026-03-01 19:28:39',NULL);
INSERT INTO reference_library VALUES(3,'designs-folder',7,'comparison','/Users/jennwoeiloh/Desktop/DESIGNS/M4B-MOFU-en-Calorie Conscious Cheat day Comparison-Img-8b6f871f/v1.jpg','v1.jpg','M4B Swap This For This - 1 meal vs 2 MIRRA meals, calorie swap',NULL,'comparison,swap,calorie,value','2026-03-01 19:28:39',NULL);
INSERT INTO reference_library VALUES(4,'designs-folder',7,'comparison','/Users/jennwoeiloh/Desktop/DESIGNS/M4B-MOFU-en-Calorie Conscious Cheat day Comparison-Img-8b6f871f/v2.jpg','v2.jpg','M4B Swap v2 - brush stroke CTA bar, circular calorie badges',NULL,'comparison,swap,cta-bar','2026-03-01 19:28:39',NULL);
INSERT INTO reference_library VALUES(5,'designs-folder',7,'grid','/Users/jennwoeiloh/Desktop/DESIGNS/M3A-MOFU-en-Calorie Conscious-T062-Img-hpjri87878/v1.jpg','v1.jpg','M3A Counting Calories at Work 3x3 grid - 9 bentos with names and calories',NULL,'grid,3x3,calorie,office','2026-03-01 19:28:39',NULL);
INSERT INTO reference_library VALUES(6,'designs-folder',7,'grid','/Users/jennwoeiloh/Desktop/DESIGNS/M3A-MOFU-en-Calorie Conscious-T062-Img-hpjri87878/v2.jpg','v2.jpg','M3A Counting Calories v2 - cleaner layout, under 500 kcal',NULL,'grid,3x3,calorie','2026-03-01 19:28:39',NULL);
INSERT INTO reference_library VALUES(7,'designs-folder',7,'collage','/Users/jennwoeiloh/Desktop/DESIGNS/M3B-MOFU-en-Calorie Conscious-T105-Img-ndxwq53641/v1.jpg','v1.jpg','M3B 50+ International Bento collage - scattered bento photos with checkmark badges',NULL,'collage,variety,50+,badges','2026-03-01 19:28:39',NULL);
INSERT INTO reference_library VALUES(8,'designs-folder',7,'template','/Users/jennwoeiloh/Desktop/DESIGNS/M4C-MOFU-en-Calorie Conscious Cheat day Comparison-Img-5fcdc505/T128__2025-07-28+17_23_59.jpg','T128__2025-07-28+17_23_59.jpg','M4C template - pink/cream split with headline placeholders and badges',NULL,'template,split,badges','2026-03-01 19:28:39',NULL);
INSERT INTO reference_library VALUES(9,'designs-folder',7,'product','/Users/jennwoeiloh/Desktop/DESIGNS/M4C-MOFU-en-Calorie Conscious Cheat day Comparison-Img-5fcdc505/NasiLemakClassicCurry-Apr-TopView.png','NasiLemakClassicCurry-Apr-TopView.png','Nasi Lemak Classic Curry - top view bento, pink rice, samosa, curry',NULL,'product,topview,nasi-lemak','2026-03-01 19:28:39',NULL);
INSERT INTO reference_library VALUES(10,'designs-folder',7,'product','/Users/jennwoeiloh/Desktop/DESIGNS/M4C-MOFU-en-Calorie Conscious Cheat day Comparison-Img-5fcdc505/Carbonara fusilli.png','Carbonara fusilli.png','Carbonara Fusilli - top view bento, pasta, tomatoes, greens, fruit',NULL,'product,topview,carbonara','2026-03-01 19:28:39',NULL);
INSERT INTO reference_library VALUES(11,'designs-folder',7,'product','/Users/jennwoeiloh/Desktop/DESIGNS/M4C-MOFU-en-Calorie Conscious Cheat day Comparison-Img-5fcdc505/Tortilla-TopView.png','Tortilla-TopView.png','Tortilla Wrap - top view bento, wrap, curry, roasted veggies',NULL,'product,topview,tortilla','2026-03-01 19:28:39',NULL);
INSERT INTO reference_library VALUES(12,'designs-folder',7,'product','/Users/jennwoeiloh/Desktop/DESIGNS/M3A-MOFU-en-Calorie Conscious-T062-Img-hpjri87878/LemonMushroom-Apr-Top.png','LemonMushroom-Apr-Top.png','Lemon Mushroom - top view bento, chicken, broccoli, pink rice, eggplant',NULL,'product,topview,lemon-mushroom','2026-03-01 19:28:39',NULL);
INSERT INTO reference_library VALUES(13,'designs-folder',7,'product','/Users/jennwoeiloh/Desktop/DESIGNS/M4B-MOFU-en-Calorie Conscious Cheat day Comparison-Img-8b6f871f/Nasi Lemak Classic Bento Box-Top View.png','Nasi Lemak Classic Bento Box-Top View.png','Nasi Lemak Classic - overhead bento, pink rice, chickpeas, samosa',NULL,'product,topview,nasi-lemak','2026-03-01 19:28:39',NULL);
INSERT INTO reference_library VALUES(14,'designs-folder',7,'brand-guide','/Users/jennwoeiloh/Desktop/DESIGNS/Mirra Brand Guide image.jpg','Mirra Brand Guide image.jpg','MIRRA brand guide - colors, fonts, icons, illustration style',NULL,'brand-guide,style,colors,typography','2026-03-01 19:28:39',NULL);
INSERT INTO reference_library VALUES(15,'designs-folder',7,'brand-guide','/Users/jennwoeiloh/.openclaw/brands/mirra/assets/brand-guide.jpg','brand-guide.jpg','MIRRA brand guide (assets copy)',NULL,'brand-guide','2026-03-01 19:28:39',NULL);
INSERT INTO reference_library VALUES(16,'designs-folder',7,'comparison','/Users/jennwoeiloh/.openclaw/brands/mirra/assets/ref-comparison-template.jpg','ref-comparison-template.jpg','Comparison template reference',NULL,'comparison,template','2026-03-01 19:28:39',NULL);
INSERT INTO reference_library VALUES(17,'designs-folder',7,'comparison','/Users/jennwoeiloh/.openclaw/brands/mirra/assets/ref-comparison-v1.jpg','ref-comparison-v1.jpg','Comparison v1 reference',NULL,'comparison','2026-03-01 19:28:39',NULL);
INSERT INTO reference_library VALUES(18,'designs-folder',7,'product','/Users/jennwoeiloh/.openclaw/brands/mirra/assets/ref-bento-topview.png','ref-bento-topview.png','Bento top view reference',NULL,'product,topview','2026-03-01 19:28:39',NULL);
INSERT INTO reference_library VALUES(19,'designs-folder',7,'product','/Users/jennwoeiloh/.openclaw/brands/mirra/assets/ref-carbonara-fusilli.png','ref-carbonara-fusilli.png','Carbonara fusilli reference',NULL,'product,carbonara','2026-03-01 19:28:39',NULL);
INSERT INTO reference_library VALUES(20,'designs-folder',7,'product','/Users/jennwoeiloh/.openclaw/brands/mirra/assets/ref-tortilla-topview.png','ref-tortilla-topview.png','Tortilla top view reference',NULL,'product,tortilla','2026-03-01 19:28:39',NULL);
INSERT INTO reference_library VALUES(21,'designs-folder',7,'logo','/Users/jennwoeiloh/.openclaw/brands/mirra/assets/logo-black.png','logo-black.png','MIRRA logo black',NULL,'logo,black','2026-03-01 19:28:39',NULL);
CREATE TABLE knowledge (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    source TEXT NOT NULL,
    type TEXT NOT NULL,
    fact TEXT NOT NULL,
    tags TEXT DEFAULT '',
    agent TEXT DEFAULT '',
    status TEXT DEFAULT 'active',
    confidence REAL DEFAULT 1.0,
    source_file TEXT DEFAULT '',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO knowledge VALUES(1,'robonuggets/R32,R34,R38','workflow','Use SQLite/Sheets with status column as production queue: queued to processing to for_review to published to done. Scheduler polls, picks first match, processes, updates status.','factory,queue,state-machine','myrmidons,athena','active',1.0,'','2026-03-01 16:42:26','2026-03-01 16:42:26');
INSERT INTO knowledge VALUES(2,'robonuggets/R48,R40','workflow','Pass callBackUrl to slow APIs instead of polling. API calls back when done.','async,performance','taoz,myrmidons','active',1.0,'','2026-03-01 16:43:10','2026-03-01 16:43:10');
INSERT INTO knowledge VALUES(3,'robonuggets/R31,R34,R36,R38,R44','workflow','Every LLM agent uses Think tool + structured output parser. Reduces format errors.','llm,quality','dreami,athena,iris','active',1.0,'','2026-03-01 16:43:28','2026-03-01 16:43:28');
INSERT INTO knowledge VALUES(4,'robonuggets/R34,R31','workflow','Define element pools. LLM picks from pools fills template. Controlled creativity.','creative,templates','dreami','active',1.0,'','2026-03-01 16:43:28','2026-03-01 16:43:28');
INSERT INTO knowledge VALUES(5,'robonuggets/R36,R38,R48','workflow','Generate stable image first, then animate to video. Anchors visual, reduces hallucination.','video,pipeline','iris,dreami','active',1.0,'','2026-03-01 16:43:28','2026-03-01 16:43:28');
INSERT INTO knowledge VALUES(6,'robonuggets/R36,R39','workflow','WhatsApp/Telegram as creative interface. sendAndWait for approval gates.','ux,whatsapp','zenni','active',1.0,'','2026-03-01 16:43:28','2026-03-01 16:43:28');
INSERT INTO knowledge VALUES(7,'robonuggets/R40','workflow','Voice, Image, Video as separate callable sub-workflows. Reusable across pipelines.','architecture','taoz','active',1.0,'','2026-03-01 16:43:28','2026-03-01 16:43:28');
INSERT INTO knowledge VALUES(8,'robonuggets/R34,R32','workflow','Single media load then parallel publish: TikTok + Instagram + YouTube.','publishing,social','myrmidons,hermes','active',1.0,'','2026-03-01 16:43:28','2026-03-01 16:43:28');
INSERT INTO knowledge VALUES(9,'robonuggets/R38','workflow','Feed reference image to vision model. Returns brand colors, fonts, style. Anchors all downstream creative.','brand,vision','iris','active',1.0,'','2026-03-01 16:43:28','2026-03-01 16:43:28');
INSERT INTO knowledge VALUES(10,'robonuggets/R31,R34,R38','workflow','Generate N scenes in one LLM call. Split out. Process in parallel. Aggregate.','parallel,batch','dreami,iris','active',1.0,'','2026-03-01 16:43:28','2026-03-01 16:43:28');
INSERT INTO knowledge VALUES(11,'cso/maincore','workflow','Explicit stage progression: DRAFT to ANALYSIS to ADAPTATION to PUBLISHING to COMPLETED. API-persisted. Enables audit trail and retry.','orchestration,cso','athena,zenni','active',1.0,'','2026-03-01 16:43:29','2026-03-01 16:43:29');
INSERT INTO knowledge VALUES(12,'cso/analysis','workflow','Detect language from hook. Force entire output to match. No bilingual mixing.','voice,language','dreami,athena','active',1.0,'','2026-03-01 16:43:29','2026-03-01 16:43:29');
INSERT INTO knowledge VALUES(13,'cso/adaptation','workflow','Branch by mode: IMAGE vs VIDEO vs CLIP. Each mode uses different agent, prompt, tools, timeout.','routing,creative','dreami,iris','active',1.0,'','2026-03-01 16:43:29','2026-03-01 16:43:29');
INSERT INTO knowledge VALUES(14,'cso/publishing','workflow','Art Director outputs structured layout JSON: shot, visual_hook, subject, layout_mechanics, lighting, color_strategy.','art-direction,layout','iris','active',1.0,'','2026-03-01 16:43:29','2026-03-01 16:43:29');
INSERT INTO knowledge VALUES(15,'user/jenn/2026-03-01','user-correction','MIRRA is bento meal delivery NOT skincare. Colors: salmon pink F7AB9F, black 252525, cream FFF9EB.','mirra,brand,critical','dreami,iris','active',1.0,'','2026-03-01 16:43:29','2026-03-01 16:43:29');
INSERT INTO knowledge VALUES(16,'user/jenn/2026-03-01','user-correction','Seedance 2.0 NOT on fal.ai yet. User wants 2.0 only. Monitor for release.','seedance,video','iris,artemis','active',1.0,'','2026-03-01 16:43:29','2026-03-01 16:43:29');
INSERT INTO knowledge VALUES(17,'session/2026-03-01','tool-discovery','openclaw message send bypasses Zenni LLM. Direct WhatsApp delivery for sending outputs.','whatsapp,direct-send','zenni,myrmidons','active',1.0,'','2026-03-01 16:43:29','2026-03-01 16:43:29');
INSERT INTO knowledge VALUES(18,'session/2026-03-01','session-learning','NanoBanana needs --ref-image for brand consistency. Always pass brand reference.','nanobanana,brand','dreami,iris','active',1.0,'','2026-03-01 16:43:29','2026-03-01 16:43:29');
INSERT INTO knowledge VALUES(19,'session/dreami/2026-03-02','session-learning','Generated katsu bento image first via NanoBanana, then would animate with Kling. Image quality was right, video would have been anchored.','','dreami','active',1.0,'','2026-03-01 16:43:50','2026-03-01 16:43:50');
INSERT INTO knowledge VALUES(20,'competitor/grabfood-ads','competitor-intel','GrabFood competitor uses static hero image → animate for Reels. Same pattern as RoboNuggets R36.','','artemis','active',1.0,'','2026-03-01 16:43:50','2026-03-01 16:43:50');
INSERT INTO knowledge VALUES(26,'evolution-trial/trial-1772387740','session-learning','Pre-task knowledge review via dispatch.sh reduces duplicate work by letting agents see what the system already knows before starting.','','athena','active',1.0,'','2026-03-01 17:55:52','2026-03-01 17:55:52');
INSERT INTO knowledge VALUES(27,'video-eye/ve-20260302-020408-2a47','workflow','Analyzed local video: hook=unknown, structure=unknown, virality=?/10. URL: /Users/jennwoeiloh/Downloads/Mirra-KOL-Lecey-02-Good.mp4','video-eye,local,unknown','iris,dreami','active',1.0,'','2026-03-01 18:04:57','2026-03-01 18:04:57');
INSERT INTO knowledge VALUES(28,'video-eye/ve-20260302-020408-2a47','pattern','Hook type: unknown on local','','iris,dreami','active',1.0,'','2026-03-01 18:04:57','2026-03-01 18:04:57');
INSERT INTO knowledge VALUES(29,'video-eye/ve-20260302-020634-25ae','workflow','Analyzed local video: hook=POV, structure=hook > context > process > reaction > CTA, virality=8/10. URL: /Users/jennwoeiloh/Downloads/Mirra-KOL-Lecey-02-Good.mp4','video-eye,local,POV','iris,dreami','active',1.0,'','2026-03-01 18:07:31','2026-03-01 18:07:31');
INSERT INTO knowledge VALUES(30,'video-eye/ve-20260302-020634-25ae','pattern','Hook type: POV on local','','iris,dreami','active',1.0,'','2026-03-01 18:07:31','2026-03-01 18:07:31');
INSERT INTO knowledge VALUES(31,'session/taoz/2026-03-02','workflow-learning','MIRRA NanoBanana ads work best when: (1) prompt describes LAYOUT TYPE not just food (comparison/grid/lifestyle), (2) ref-image from real Trica designs guides style, (3) DNA.json provides colors/badges/typography, (4) ref images must be under 1MB or auto-resize kicks in. Three proven templates: This-or-That comparison (M4A), 9-grid bento showcase (M3A), lifestyle desk scene (M2A). All use REAL food photography composited into designed backgrounds.','','taoz','active',1.0,'','2026-03-01 18:54:54','2026-03-01 18:54:54');
INSERT INTO knowledge VALUES(32,'brand-studio/mirra/2026-03-02','workflow-metric','brand-studio loop: brand=mirra template=comparison attempts=1 best_score=10 passed=true','','iris','active',1.0,'','2026-03-01 19:19:24','2026-03-02 10:14:13');
INSERT INTO knowledge VALUES(33,'brand-studio/mirra/2026-03-02','workflow-metric','brand-studio loop: brand=mirra template=hero attempts=1 best_score=10 passed=true','','iris','active',1.0,'','2026-03-01 19:22:49','2026-03-02 06:51:33');
INSERT INTO knowledge VALUES(34,'brand-studio/mirra/2026-03-02','workflow-metric','brand-studio loop: brand=mirra template=grid attempts=1 best_score=9.7 passed=true','','iris','active',1.0,'','2026-03-01 19:32:10','2026-03-01 19:32:10');
INSERT INTO knowledge VALUES(35,'curator/mirra/curator-20260302-034150','creative-learning','WINNING: brand=mirra template=comparison headline="Swap This For This" score=10.0','','iris','active',1.0,'','2026-03-01 19:50:29','2026-03-01 19:50:29');
INSERT INTO knowledge VALUES(36,'brand-studio/mirra/2026-03-02','workflow-metric','brand-studio loop: brand=mirra template=grid attempts=1 best_score=10 passed=true','','iris','active',1.0,'','2026-03-01 19:53:29','2026-03-01 19:53:29');
INSERT INTO knowledge VALUES(37,'curator/mirra/curator-20260302-035024','creative-learning','WINNING: brand=mirra template=comparison headline="This or That" score=10.0','','iris','active',1.0,'','2026-03-01 19:53:29','2026-03-01 19:53:29');
INSERT INTO knowledge VALUES(38,'curator/mirra/curator-20260302-035024','creative-learning','WINNING: brand=mirra template=grid headline="Counting Calories at Work?" score=10.0','','iris','active',1.0,'','2026-03-01 19:53:29','2026-03-01 19:53:29');
INSERT INTO knowledge VALUES(39,'curator/mirra/curator-20260302-035024','creative-learning','WINNING: brand=mirra template=hero headline="Finally, Healthy That Tastes Good" score=10.0','','iris','active',1.0,'','2026-03-01 19:53:29','2026-03-01 19:53:29');
INSERT INTO knowledge VALUES(40,'curator/mirra/curator-20260302-035024','workflow-metric','CURATOR: brand=mirra total=3 passed=3 failed=0 avg=10.0 pass_rate=100%','','iris','active',1.0,'','2026-03-01 19:53:29','2026-03-01 19:53:29');
INSERT INTO knowledge VALUES(41,'brand-studio/mirra/2026-03-02','workflow-metric','brand-studio loop: brand=mirra template=comparison attempts=1 best_score=9 passed=true','','iris','active',1.0,'','2026-03-02 01:38:44','2026-03-02 01:38:44');
INSERT INTO knowledge VALUES(42,'brand-studio/mirra/2026-03-02','workflow-metric','brand-studio loop: brand=mirra template=lifestyle attempts=1 best_score=8 passed=true','','iris','active',1.0,'','2026-03-02 03:15:52','2026-03-02 03:15:52');
INSERT INTO knowledge VALUES(43,'brand-studio/mirra/2026-03-02','workflow-metric','brand-studio loop: brand=mirra template=comparison attempts=1 best_score=9.7 passed=true','','iris','active',1.0,'','2026-03-02 04:09:28','2026-03-02 04:09:28');
INSERT INTO knowledge VALUES(44,'brand-studio/mirra/2026-03-02','workflow-metric','brand-studio loop: brand=mirra template=comparison attempts=1 best_score=9.3 passed=true','','iris','active',1.0,'','2026-03-02 06:48:26','2026-03-02 06:48:26');
INSERT INTO knowledge VALUES(45,'brand-studio/mirra/2026-03-02','workflow-metric','brand-studio loop: brand=mirra template=comparison attempts=1 best_score=9.6 passed=true','','iris','active',1.0,'','2026-03-02 10:04:25','2026-03-02 10:04:25');
INSERT INTO knowledge VALUES(46,'brand-studio/mirra/2026-03-02','workflow-metric','brand-studio loop: brand=mirra template=comparison attempts=1 best_score=9.85 passed=true','','iris','active',1.0,'','2026-03-02 10:11:01','2026-03-02 10:11:01');
INSERT INTO knowledge VALUES(47,'brand-studio/mirra/2026-03-03','workflow-metric','brand-studio loop: brand=mirra template=comparison attempts=1 best_score=10 passed=true','','iris','active',1.0,'','2026-03-03 12:11:53','2026-03-03 12:16:16');
INSERT INTO knowledge VALUES(48,'brand-studio/mirra/2026-03-03','workflow-metric','brand-studio loop: brand=mirra template=lifestyle attempts=2 best_score=7.4 passed=true','','iris','active',1.0,'','2026-03-03 12:15:00','2026-03-03 12:15:00');
INSERT INTO knowledge VALUES(49,'video-eye/ve-20260304-171155-6aec','workflow','Analyzed local video: hook=question, structure=hook > problem > solution > CTA, virality=7/10. URL: /Users/jennwoeiloh/.openclaw/media/inbound/f5ae6b29-00f9-46c4-88d7-47338fc67a58.mp4','video-eye,local,question','iris,dreami','active',1.0,'','2026-03-04 09:13:09','2026-03-04 09:13:09');
INSERT INTO knowledge VALUES(50,'video-eye/ve-20260304-171155-6aec','pattern','Hook type: question on local','','iris,dreami','active',1.0,'','2026-03-04 09:13:09','2026-03-04 09:13:09');
INSERT INTO knowledge VALUES(51,'session/argus/2026-03-05','session-learning','Taoz tasks can timeout (600s limit) with no output when Google Drive access or complex script analysis is required. Breaking tasks into smaller chunks or pre-downloading resources improves success rate.','','argus','active',1.0,'','2026-03-05 05:40:33','2026-03-05 05:40:33');
INSERT INTO knowledge VALUES(52,'session/argus/2026-03-05','session-learning','Google Drive files require ''Anyone with link can view'' permission for Taoz to access via WebFetch. Private/shared files need to be pasted directly or saved locally to ~/.openclaw/workspace/data/ before build tasks can proceed.','','argus','active',1.0,'','2026-03-05 05:43:14','2026-03-05 05:43:14');
INSERT INTO knowledge VALUES(53,'session/argus/2026-03-05','session-learning','Kitchen app (kitchen.gaiaos.ai) unit dropdown only has ''g'' and ''pcs'' options - missing ''kg''. Taoz needs to add <option value="kg">kg — kilograms</option> to the dropdown.','','argus','active',1.0,'','2026-03-05 06:40:08','2026-03-05 06:40:08');
INSERT INTO knowledge VALUES(54,'session/argus/2026-03-05','session-learning','Kitchen app kg unit fix completed by Taoz (task taoz-1772692927-1904). Code changes verified in local file and deploy folder. Deployment to kitchen.gaiaos.ai pending - GitHub remote was unreachable, needs manual push.','','argus','active',1.0,'','2026-03-05 06:48:07','2026-03-05 06:48:07');
INSERT INTO knowledge VALUES(55,'session/argus/2026-03-05','session-learning','Kitchen app kg fix: Code verified locally but NOT deployed to kitchen.gaiaos.ai. GitHub remote was unreachable from Taoz session. Manual deployment required: upload deploy/index.html to production.','','argus','active',1.0,'','2026-03-05 06:51:53','2026-03-05 06:51:53');
INSERT INTO knowledge VALUES(56,'session/argus/2026-03-05','session-learning','Kitchen app (kitchen.gaiaos.ai) deployment method: Cloudflare Tunnel routes to local server.js (port 8899). The deploy/index.html file is served directly - no git push required. Changes to deploy/index.html go live immediately if server is running.','','argus','active',1.0,'','2026-03-05 07:09:16','2026-03-05 07:09:16');
INSERT INTO knowledge VALUES(57,'brand-studio/mirra/2026-03-06','workflow-metric','brand-studio loop: brand=mirra template=comparison attempts=1 best_score=9 passed=true','','iris','active',1.0,'','2026-03-06 06:02:48','2026-03-06 06:02:48');
INSERT INTO knowledge VALUES(58,'brand-studio/mirra/2026-03-06','workflow-metric','brand-studio loop: brand=mirra template=comparison attempts=1 best_score=10 passed=true','','iris','active',1.0,'','2026-03-06 06:03:26','2026-03-06 06:03:26');
INSERT INTO knowledge VALUES(59,'session/argus/2026-03-07','session-learning','Gateway connectivity (device signature + timeout) caused 2 cron failures overnight - gateway-auto-recovery skill is the solution, not a regression','','argus','active',1.0,'','2026-03-07 00:31:39','2026-03-07 00:31:39');
INSERT INTO knowledge VALUES(60,'session/argus/2026-03-07','session-learning','Done-gate stuck in dispatch loop — same task sent 3x in 3 minutes. Flagged to exec room for Taoz investigation.','','argus','active',1.0,'','2026-03-07 00:32:16','2026-03-07 00:32:16');
INSERT INTO knowledge VALUES(61,'session/argus/2026-03-07','session-learning','Done-gate infinite loop bug: task-complete.sh calls dispatch.sh done-gate which calls done-gate.sh which calls task-complete.sh again. Fixed by killing processes with pkill -f done-gate.sh and pkill -f dispatch.sh done-gate','','argus','active',1.0,'','2026-03-07 00:33:05','2026-03-07 00:33:05');
CREATE TABLE patterns (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    description TEXT DEFAULT '',
    occurrences INTEGER DEFAULT 1,
    sources TEXT DEFAULT '',
    agents TEXT DEFAULT '',
    status TEXT DEFAULT 'observed',
    skill_proposed TEXT DEFAULT '',
    promoted_to TEXT DEFAULT '',
    first_seen DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_seen DATETIME DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO patterns VALUES(1,'production-queue-state-machine','Use SQLite/Sheets with status column as production queue: queued to processing to for_review to published to done. Scheduler polls, picks first match, processes, updates status.',1,'robonuggets/R32,R34,R38','myrmidons,athena','observed','','','2026-03-01 16:42:26','2026-03-01 16:42:26');
INSERT INTO patterns VALUES(2,'callback-async-no-polling','Pass callBackUrl to slow APIs instead of polling. API calls back when done.',1,'robonuggets/R48,R40','taoz,myrmidons','observed','','','2026-03-01 16:43:10','2026-03-01 16:43:10');
INSERT INTO patterns VALUES(3,'think-then-structured-output','Every LLM agent uses Think tool + structured output parser. Reduces format errors.',1,'robonuggets/R31,R34,R36,R38,R44','dreami,athena,iris','observed','','','2026-03-01 16:43:28','2026-03-01 16:43:28');
INSERT INTO patterns VALUES(4,'element-pools-template-fill','Define element pools. LLM picks from pools fills template. Controlled creativity.',1,'robonuggets/R34,R31','dreami','observed','','','2026-03-01 16:43:28','2026-03-01 16:43:28');
INSERT INTO patterns VALUES(5,'image-first-then-animate','Generate stable image first, then animate to video. Anchors visual, reduces hallucination.',3,'robonuggets/R36,R38,R48,session/dreami/2026-03-02,competitor/grabfood-ads','iris,dreami','validated','','','2026-03-01 16:43:28','2026-03-01 16:43:50');
INSERT INTO patterns VALUES(6,'chat-app-as-creative-ui','WhatsApp/Telegram as creative interface. sendAndWait for approval gates.',1,'robonuggets/R36,R39','zenni','observed','','','2026-03-01 16:43:28','2026-03-01 16:43:28');
INSERT INTO patterns VALUES(7,'sub-workflow-modularization','Voice, Image, Video as separate callable sub-workflows. Reusable across pipelines.',1,'robonuggets/R40','taoz','observed','','','2026-03-01 16:43:28','2026-03-01 16:43:28');
INSERT INTO patterns VALUES(8,'multi-platform-publish','Single media load then parallel publish: TikTok + Instagram + YouTube.',1,'robonuggets/R34,R32','myrmidons,hermes','observed','','','2026-03-01 16:43:28','2026-03-01 16:43:28');
INSERT INTO patterns VALUES(9,'brand-dna-from-image','Feed reference image to vision model. Returns brand colors, fonts, style. Anchors all downstream creative.',1,'robonuggets/R38','iris','observed','','','2026-03-01 16:43:28','2026-03-01 16:43:28');
INSERT INTO patterns VALUES(10,'parallel-scene-fanout','Generate N scenes in one LLM call. Split out. Process in parallel. Aggregate.',1,'robonuggets/R31,R34,R38','dreami,iris','observed','','','2026-03-01 16:43:29','2026-03-01 16:43:29');
INSERT INTO patterns VALUES(11,'stage-state-machine','Explicit stage progression: DRAFT to ANALYSIS to ADAPTATION to PUBLISHING to COMPLETED. API-persisted. Enables audit trail and retry.',1,'cso/maincore','athena,zenni','observed','','','2026-03-01 16:43:29','2026-03-01 16:43:29');
INSERT INTO patterns VALUES(12,'language-lock-enforcement','Detect language from hook. Force entire output to match. No bilingual mixing.',1,'cso/analysis','dreami,athena','observed','','','2026-03-01 16:43:29','2026-03-01 16:43:29');
INSERT INTO patterns VALUES(13,'mode-branch-routing','Branch by mode: IMAGE vs VIDEO vs CLIP. Each mode uses different agent, prompt, tools, timeout.',1,'cso/adaptation','dreami,iris','observed','','','2026-03-01 16:43:29','2026-03-01 16:43:29');
INSERT INTO patterns VALUES(14,'art-director-layout-json','Art Director outputs structured layout JSON: shot, visual_hook, subject, layout_mechanics, lighting, color_strategy.',1,'cso/publishing','iris','observed','','','2026-03-01 16:43:29','2026-03-01 16:43:29');
INSERT INTO patterns VALUES(16,'hook-unknown','Hook type: unknown on local',1,'video-eye/ve-20260302-020408-2a47','iris,dreami','observed','','','2026-03-01 18:04:57','2026-03-01 18:04:57');
INSERT INTO patterns VALUES(17,'hook-POV','Hook type: POV on local',1,'video-eye/ve-20260302-020634-25ae','iris,dreami','observed','','','2026-03-01 18:07:31','2026-03-01 18:07:31');
INSERT INTO patterns VALUES(18,'hook-question','Hook type: question on local',1,'video-eye/ve-20260304-171155-6aec','iris,dreami','observed','','','2026-03-04 09:13:09','2026-03-04 09:13:09');
PRAGMA writable_schema=ON;
INSERT INTO sqlite_schema(type,name,tbl_name,rootpage,sql)VALUES('table','knowledge_fts','knowledge_fts',0,'CREATE VIRTUAL TABLE knowledge_fts USING fts5(
    fact, tags, source, type, agent, content=knowledge, content_rowid=id
)');
CREATE TABLE IF NOT EXISTS 'knowledge_fts_data'(id INTEGER PRIMARY KEY, block BLOB);
INSERT INTO knowledge_fts_data VALUES(1,X'38876f34820b5c4c');
INSERT INTO knowledge_fts_data VALUES(10,X'0000000002033f00021201010101010001110102');
INSERT INTO knowledge_fts_data VALUES(137438953473,X'0000011e033030333d060102050201373d060102060104323032363d060102040105616761696e3d021902026e643d02240204726775733d0c01020301040201036275673d02060201793d021b010563616c6c733d060a080702076f6d706c6574653d040811010864697370617463683d040b1e02036f6e653d0a020d06120a0101663d0420080204697865643d021a0104676174653d0a030d06120a0108696e66696e6974653d020401076b696c6c696e673d021c01086c6561726e696e673d0601030302036f6f703d02050105706b696c6c3d041f080208726f6365737365733d021d010773657373696f6e3d0c0102020103020201683d0c090509070d0701047461736b3d040711010577686963683d040f0702036974683d021e0409080b0a070e08060c0d0e0c07090d0d0c0f080b0d110b0a0b');
INSERT INTO knowledge_fts_data VALUES(2336462209025,X'00000ed40230301004040b13020e02020d01020e01020f01040a050201310f0601020601060102060106010205010601020502013213060102060802120202170206010206010601020701060102070106010207020601020705060102070106010207010601020701060102070304303430381b06010206010601020604033633341d0601020601060102060201330f0601020501060102050106010204010601020401060102050c0601020501060102060106010206010601020602060102060506010206010601020601060102060106010206030434313530230601020603043530323425060102060106010206010601020601060102060101311f020801020a01020a01020a02020a05020a01020a01020a01020a0201301b020a02020f03020d01020d02020d01020d01020c01020d01020e01020c03013028021002093737323338373734301a0601020502026d621f02290101321004030b0f021302033032360f0601020401060102040106010203010601020301060102040c06010204010601020501060102050106010205020601020505060102050106010205010601020501060102050504303330321b0601020501060102050106010205010601020505060102050206010205010601020501060102050106010205020535323532350f020e030261651d06010207010601020702036134371b0601020701060102070101331f021c0904060404020e0101341f022301013722020e09020e0101381d020e0d020d0101391f023703020d07020d02020d01020d01066163726f737307020b0209646170746174696f6e0b0209020601020303017314060102040b0204020467656e740302040a020e0601731a020e0307677265676174650a020e02016910020802026c6c09020e160240030572656164791a021303047761797312020902076e616c797369730b0207010601020306037a65641b0202020202030663686f72656413021607017305020a04020d0301640b02130305696d6174650502070e020b0102080202706902020a09020e040173020206030670726f76616c060209020b726368697465637475726507060101020301740e08020101020404656d6973100601040304060104020201730102080502040102050d020d0303796e63020601010202017426020a030468656e6101060104030206010403080601040201060104030e06010402030674656d7074732002090102090102090202090502090102090102090102090204756469740b02110302746f1f022b0202766728020b01046261636b02020c050767726f756e64731f02480304646765731f022103037463680a060101030201651f02270302656e1302150304666f72651a021503036e746f0f02040402040c0239030273741f020601020b01020b01020b02020b05020b01020b01020b01020b0208696c696e6775616c0c020c02046c61636b0f020d020572616e63680d02020501640908090101020606010103030a07060101030e0a0205010202010a0205010202010a0205010202010203010a0205010202010203010203010203010203010a0205010202010a0205010202010a0205010202010a02050102020201790d02030d020c0306706173736573110205010463616c6c0a0208050461626c6507020705076261636b75726c02020305017302020b04056f7269657326020902036c69700d020902046f6c6f720e020f06017309020a0602091002200403756d6e01020703086d70617269736f6e1f0410270102080302060202060402080202080102080506657469746f72140e0301020201030205056c657465640b020d05066f73697465641f024503096e73697374656e63791202080404746578741d02090506726f6c6c656404020b03087272656374696f6e0f0601030301060103030306756e74696e6726020802047265616d0f020f050474697665040601010202020503021004060101031606010302020601030201060103020106010302080369747904020c030669746963616c0f060101040202736f0b0c010103010202010601020201060102020106010202020274611d020c0206757261746f72230801020204020801020204010801020204010801020204010a02010202040106646566696e6504020203066c69766572790f020602020a0307736372696265731f020a040569676e65641f02470701731f021904016b1f023d0304746563740c020202086966666572656e740d020d0304726563741108080101030703696f6e0e0601010307026f720e0203030773636f766572791106010303040570617463681a020702026e611f021d02036f6e6501021401020e0307776e6c6f6164731b020e020213050673747265616d09020f0204726166740b0205030465616d6903060104020106010402010601040305060104020206010402010601040202060104020306010402010c0102030104020806010403010601040301060104030106010403020875706c69636174651a020a0104656163680d020a02066c656d656e7404020302066e61626c65730b02100304746972650c0207020572726f727303020d02047665727903020203076f6c7574696f6e1a06010202020778706c696369740b0202020279651b0c0101030102030106010203010c010103010203010601020301066637616239660f020c02066163746f727901060101020304696c656428020903016c1002070203656564090202020566663965620f02100204696c6c7304020903056e616c6c7927020803037273740102180402050e020602046f6e747309020b03026f641f040f3603017201020f0502080a021001020b0102060202090f020a040263650c020604036d617403020c0203726f6d0402070802041302160105676174657306020a0207656e657261746505020205020209016413020202036f6f641b02130202180a020c0207726162666f6f64140802010203030269641f041129030208020208020206020575696465731f021a010d68616c6c7563696e6174696f6e05020d0302766513021402076561646c696e6523020702020701020701020704046c7468792702090304726d6573080601040304016f1402060d020806020602036f6f6b0c020502020a0d0205010202010405050102020105696d6167650502040202030202040402050502050104050b0102070b02150601731f022502016e0a04050915022e03077374616772616d0802090503656164020207030374656c14060103030505726661636506020604016f1f02460203726973030601040402060104020406010402010601040303060104030106010402010601040301060104020206010403090601040201060104020106010402010601040202060104020106010402010601040201060104020106010402010601040201060104020106010402010601040201060104020106010402010601040201060104020201730f020301046a656e6e0f0601020301060102030507776f65696c6f681b020d0202120203736f6e0e020711021e02037573741f020e01056b61747375130203020469636b731f022d02046c696e6713020d02086e6f776c656467651a02040501731a021402026f6c1b021002021501086c616e67756167650c08030101030304796f75740e0a060801010411020b02076561726e696e671206010303010601030307060103030506010303040601030302060103030106010303010601030303036365791b021102021603057474696e671a020d02086966657374796c651f04122c0b02080306676874696e670e020e02026c6d03080301010201020506020707020702036f6164080204030363616c1b080301010401020601080301010401020603026f7020020401020401020402020405020401020401020401020401036d32611f023f020233611f023b020234611f02360206616368696e6501060101050306696e636f72650b0601020303037463680102190b020a020365616c0f020503076368616e6963730e020d0303646961080203030573736167651102030304747269632006010303010601030301060103030206010303040601030301060103030106010303010601030301060103030204697272610f08020101020c020f020214020202010806010204010806010204010806010204010804010203010806010204010804010203010804010203010804010203010804010203010806010204010806010204010806010204010806010204030478696e670c020d02036f64650d04040905016c09020703056e69746f7210020f020270341b021402021902037573741f0226020879726d69646f6e73010601040201060104030606010402090601040301016e0a02030209616e6f62616e616e611208020101020102080c020302046565647312020302016f0c020b0301740f02070102050f020d01026f6602020802016e1002060c02050202050301650a020603026c7910020e020770656e636c61771102020201721f042a0b060209030b6368657374726174696f6e0b06010102020275740a020a04037075740302090902080701730e020403020d0108706172616c6c656c08020602080d010102040373657203020a0302737302020210020a16020e0502656420020e01020e01020f02020e04020701020e01020e01020f01020f0305747465726e14020c08060103020206010302020a6572666f726d616e6365020601010304067369737465640b020f020a686f746f6772617068791f0244020469636b7301021703020603026e6b0f020b030670656c696e65050601010309017307020c02066f6c6c696e6702020905017301021603036f6c73040404060301761d0806010105010204020272651a020203056f636573730a020b13020a0802657301021a0803696e6701020d040764756374696f6e01020904086772657373696f6e0b020404036d70740d020f120209040376656e1f02300504696465731f021f020675626c697368080207080265640102120803696e67080601010203020b030601020301077175616c697479030601010310020f030365756501080a01010306016401020b010372333103060102030106010204060601020303013201060102030706010204030134010601020402060102040106010203040601020302060102040301360306010205020601020301060102030e020f030138010601020502060102060206010204040601020301060417173b100f490b1a1e210610070a4b330a0e0f0d060909120b130b0c060c060a0a09110b0b0906100a060b1209100f0a061f20090707090c090a0607090e1f0d090a5c090b09090c060a08090c0820110a0b0e090b140b092a080d1b07270b0e0c0a0606090d0c0a070e0a070b0f0b094a0d090b0b090a090e0c1e0b0d0906080a090a0e09081807080e0a0f060e0f110a120715090b0c1820060a0c080a0a06810706100f0b080a09090d060a1010310b0a110b1308171c0807070d0d0b080c080a33630909060a0a081e061709060c070c06070c0a12070b0913080d1f14110b0f0c070d060b06090c070d07080c0d0b08090b0712110b06140d1c15');
INSERT INTO knowledge_fts_data VALUES(2336462209026,X'0000063f010205043072333906060102040202343002060102040506010203030134030601020703013802060102030306010205020361746528020f020765616374696f6e1d020b04016c1f04172d0305647563657303020b02020c1502090303656c7314020a0301661202040d04141204066572656e636509020309020c03056c65617365100211030473697a651f022c03037472790b0214040475726e730902080306757361626c6507020a030476696577010210190205020469676874130211020a6f626f6e75676765747301060102020106010202010601020201060102020106010202010601020201060102020106010202010601020201060102020a020e03057574696e670d06010102010673616c6d6f6e0f020a03026d6514020b020463656e651f023e0601730a02040307686564756c657201021503036f726520020c01020c01020c01020c01020c01020b01020c01020d02020c01020c01020c01020c020265651a020f040564616e636510080201010203026e641108040101040507616e64776169740602070503696e6711020c030670617261746507020603057373696f6e1106010202010c010202010302010c010202010302070601030205060102020201681a020803046565747301020403026f740e0208040577636173651f023a0205696e676c6508020202076b696e636172650f020802036c6f7702020502056f6369616c08060101030204706c69740a02090205716c69746501020302057461626c65050203040267650b020304057274696e671a021604027465010601010405026963140205050275730104061803067261746567790e021004067563747572651b02070202070a01640302080b020503047564696f2008030102030108030102030108030102030208030102030508030102030108030102030108030102030108030102030303796c6509020c16021b0202756207020804046a6563740e020b02037761702302080205797374656d1a0212010474616f7a02060104020506010402180c0102030104020302736b1a0203040374657327020b0207656c656772616d06020303066d706c61746504020a1c020701020701020701020501020701020501020501020502020701020701020701020709017304060101031b023102036861741f023406020a02020a0301651a021104016e0502060302050b02090303696e6b0302060401731f02320404090402020803037265651f022f0205696b746f6b08020803056d656f75740d021102016f01080c04050401020403020804020502080604040401020903026f6c0302070e060103020501730d0210030374616c28020502047261696c0b0212030369616c1a0801020303040263611f02180302756520020f01020f01021002020f05020f01020f01021001021002037970651c020302020301020c04076f6772617068791f02220105756e6465721f022803056b6e6f776e1b0a0604010105010204020670646174657301021b0202726c1b020b020210020273650102021e02410401720f0c010202010302010e0a0102020103020501731b020c0202110401730302050a020c0702040201780606010102010276651b0601020401060102040106010204010601020402026961130207070206030364656f0508090101020202040602070306010103030212080e040101020102020106010202010e040101020102020106010202030672616c6974791b020902020d030473696f6e090806010103040375616c05020b09020902046f69636507020205060101020201730d040604010577616e747310020b03017313021002036861741a02100504736170700608020101030b08090101020302656e02020d1d02070206696e6e696e672302020202020102020102020302746801020512020c02036f726b1a020b05020507020b0504666c6f77010601030201060103020106010302010601030201060103020106010302010601030201060103020106010302010601030201060103020106010302010601030201060103020d06010302020601030202060103020106010302010601030201060103020206010302040601030201060103020106010302010601030201060103020901730702090303756c6413040a0b010379657410020902066f757475626508020a01057a656e6e6906060104020506010403060806010402070a0e080d080c0710080a0e0a0908090b0c09410c0b0709060c29070d0a0c080b260609070a0a0c080c090a0a070a0907080b0e09360b0709080a1807080c2f0b0e060c080d080a0a1b0c0608090b071c0e0c0a110b0a0a14090c08180a350e0c0b0e070a0608120a140a0e81080609080b');
INSERT INTO knowledge_fts_data VALUES(2473901162497,X'00000b0a0530303066393102160201322d0601020701060102070201332d0601020601060102060108010206030108010206030306010205010601020501060102050106010205010601020501060102050106010206010601020601060102050106010205020135330601020601060102060106010206010601020601060102060106010206020136390601020701060102070201373b0601020601060102060101312d020a01020a01020a0a020a01020a0201302f020d02020e09020d02053731313535310601020601060102060308373236393239323736020c020339303436020d01013230020a0b020802033032362d060102050106010205010601020501060102050306010204010601020401060102040106010204010601020401060102040106010205010601020501060102040106010204050430333034310601020501060102050101333c020d0201783c020b01013430020e0203366334310217020b37333338666336376135383102190101362d020e020330307333020602036165633106010207010601020701013730020d01020d010238352e020e0203383939380211030264373102180101392d020d01020d0b020d0101613b02140205636365737333020e01020f0202646435021402016935020601021b01020f01020602076e616c7973697333021206037a656431020203016435020c0102140304796f6e6534020602027070350203010203010203010203020472677573330c010203010402010c010203010402010c010203010402010c010203010402010c010203010402010c010203010402030c010203010402010c01020301040202077474656d7074732d0209010209010209010209090209010209020375746f3b020d010262653402170304666f7265340221030273742d020b01020b01020b01020b09020b01020b020472616e642d0a0205010202010a0205010202010a0205010202010a0205010202090a0205010202010a0205010202030665616b696e67330215020475696c64340222030174370209020179360208010363616e3302040104091d0304757365643b0207020668616e67657336020f02021e0304756e6b7333021902096c6f7564666c61726538020902036f646536020e01020603086d70617269736f6e2d02080102080102080a020801020805056c65746564360207070178330210030a6e6e65637469766974793b02030203726f6e3b02090202746131020b010464617461340220020565706c6f7936021501021b0104130f0702656437020b07046d656e743602170102180102070304766963653b0204020769726563746c7934021904021903067370617463683c020602036f6e653c02020309776e6c6f6164696e6733021c02057265616d6931060104030106010403030369766533020d01020303066f70646f776e350408170104657865633c021102027965310c010103010203010601020301086635616536623239310215020761696c757265733b020a0203696c653602130202160501733404041203017836020601020502066c61676765643c020f02056f6c64657236021603017234020c0802130203726f6d37021401016735020b02056169616f7335020501021a01020e010205030274653c020305037761793b04020c0202697438021b040368756236021d01021002016f38022303046f676c6533020c010202010368617335020a02036f6f6b310405050102020203746d6c37021d0104150f01026966380226020a6d6d6564696174656c79380225030670726f76657333021e02016e360211060405090305626f756e64310214030364657837021c0104140f0302746f330217030b7665737469676174696f6e3c021502037269732d06010402010601040201060104020106010402010601040201060104020706010402010601040202017333021305041713030210010b6a656e6e776f65696c6f6831021102017338020f01026b6735061009030102040102040208696c6f6772616d733502190305746368656e35040204010402190104020d0104020401086c6561726e696e673306010303010601030301060103030106010303010601030301060103030306010303010601030302086966657374796c6530020803036d697433020703026e6b3402080302766538022402046f63616c31080301010401020604021202020d06026c7934021c03020803026f702d020401020401020401020409020401020402020701066d616e75616c360222010217020465646961310213030474686f6438020804037269632d06010303010601030301060103030106010303090601030301060103030206696e757465733c020e03037272612d080601020401080601020401080601020401080601020409080601020401080601020403057373696e6735020f0202703431021a01046e65656434021505017335021201022102016f33020905021a03017437020a04021301026f6e32020503026c79350209020770656e636c617731021203021e030474696f6e3504150707017335020e02017233040f0d01021a0205757470757433020a02087665726e696768743b020b01067061737365642d020f01020f01020e01020f09020e01020e04037465643402180305747465726e32060103020202637335020d0206656e64696e6736021c0308726d697373696f6e34020b02036f72743802100202726533021b0305697661746534021203056f626c656d310209040463656564340225040764756374696f6e37021f020375736836022302021c01087175657374696f6e310806010105010204010472617465330220020765636f766572793b020e03086772657373696f6e3b021503046d6f746536021e0102110305717569726534020508016433021404021901021d0307736f757263657333021d02036f6f6d3c021203047574657338020b0206756e6e696e67380229010473616d653c0208030376656434021b0204636f72652d020c01020c01020c01020c09020c01020c0304726970743302110203656e743c020a03047276656438021806017238040e1b03057373696f6e330c010202010302010c010202010302010c010202010302010c010202010302010e16010202010302010c010202010302030c010202010302010c01020201030202056861726564340213020869676e61747572653b020502046b696c6c3b020f02066d616c6c657233021802076f6c7574696f6e31020a0a021202087472756374757265310207030375636b3c0204040364696f2d0803010203010803010203010803010203010803010203090803010203010803010203020675636365737333021f010474616f7a33020201020d010211010409040102150502140302736b36020a060209050173330403150102230207656d706c6174652d02070102070102070102070902070102070202686535021c0302120302110206696d656f757433020508020602016f34060e0a090104130a01021801040c1401040c1504021002037275652d021001021001020f01021009020f01020f0205756e6e656c38020a02037970653202030104756e69743502070102050309726561636861626c653602200102130205706c6f616437021a0202726c31020f020473657273310210010576616c756535021602016531060102040106010204030672696669656436021001020702026961340210030364656f310e0401010201020201060102020302657734020a030672616c69747931020c010377617336021f010212020765626665746368340211020368656e33020b020369746833020801020702076f726b666c6f772d060103020106010302010601030201060103020106010302080601030201060103020505737061636534021f04090d4b210d0d120c110d08094b10060606081006080f090708070c060d070f0c08090910461b08070916300b0906060c090e090e0b190a060f08070911070f090f0b080e110b0c09110d0c0b07090b0a090806130709070b060c080c0c070f0b0a0a0c07102d0d10060f0d17320d080707150a190e0909230b290a070909090907070f0a060a0a0d1a080c070b0d08070a0a090c0b13090c0d0c0a0c0c08090b09081809080907480a0d090b0f0d08290b190a0a1b0d0e1a170a080c110a07090a0d0e0713070b0b0c080b2c');
CREATE TABLE IF NOT EXISTS 'knowledge_fts_idx'(segid, term, pgno, PRIMARY KEY(segid, term)) WITHOUT ROWID;
INSERT INTO knowledge_fts_idx VALUES(1,X'',2);
INSERT INTO knowledge_fts_idx VALUES(17,X'',2);
INSERT INTO knowledge_fts_idx VALUES(17,X'30723339',4);
INSERT INTO knowledge_fts_idx VALUES(18,X'',2);
CREATE TABLE IF NOT EXISTS 'knowledge_fts_docsize'(id INTEGER PRIMARY KEY, sz BLOB);
INSERT INTO knowledge_fts_docsize VALUES(1,X'1b04040102');
INSERT INTO knowledge_fts_docsize VALUES(2,X'0d02030102');
INSERT INTO knowledge_fts_docsize VALUES(3,X'0c02060103');
INSERT INTO knowledge_fts_docsize VALUES(4,X'0b02030101');
INSERT INTO knowledge_fts_docsize VALUES(5,X'0c02040102');
INSERT INTO knowledge_fts_docsize VALUES(6,X'0902030101');
INSERT INTO knowledge_fts_docsize VALUES(7,X'0b01020101');
INSERT INTO knowledge_fts_docsize VALUES(8,X'0902030102');
INSERT INTO knowledge_fts_docsize VALUES(9,X'0f02020101');
INSERT INTO knowledge_fts_docsize VALUES(10,X'0d02040102');
INSERT INTO knowledge_fts_docsize VALUES(11,X'1302020102');
INSERT INTO knowledge_fts_docsize VALUES(12,X'0c02020102');
INSERT INTO knowledge_fts_docsize VALUES(13,X'1002020102');
INSERT INTO knowledge_fts_docsize VALUES(14,X'0f03020101');
INSERT INTO knowledge_fts_docsize VALUES(15,X'0f03050202');
INSERT INTO knowledge_fts_docsize VALUES(16,X'1002050202');
INSERT INTO knowledge_fts_docsize VALUES(17,X'0c03040202');
INSERT INTO knowledge_fts_docsize VALUES(18,X'0b02040202');
INSERT INTO knowledge_fts_docsize VALUES(19,X'1500050201');
INSERT INTO knowledge_fts_docsize VALUES(20,X'0e00030201');
INSERT INTO knowledge_fts_docsize VALUES(26,X'1500040201');
INSERT INTO knowledge_fts_docsize VALUES(27,X'1304060102');
INSERT INTO knowledge_fts_docsize VALUES(28,X'0500060102');
INSERT INTO knowledge_fts_docsize VALUES(29,X'1804060102');
INSERT INTO knowledge_fts_docsize VALUES(30,X'0500060102');
INSERT INTO knowledge_fts_docsize VALUES(31,X'4700050201');
INSERT INTO knowledge_fts_docsize VALUES(32,X'0e00060201');
INSERT INTO knowledge_fts_docsize VALUES(33,X'0e00060201');
INSERT INTO knowledge_fts_docsize VALUES(34,X'0f00060201');
INSERT INTO knowledge_fts_docsize VALUES(35,X'0d00050201');
INSERT INTO knowledge_fts_docsize VALUES(36,X'0e00060201');
INSERT INTO knowledge_fts_docsize VALUES(37,X'0c00050201');
INSERT INTO knowledge_fts_docsize VALUES(38,X'0d00050201');
INSERT INTO knowledge_fts_docsize VALUES(39,X'0e00050201');
INSERT INTO knowledge_fts_docsize VALUES(40,X'0f00050201');
INSERT INTO knowledge_fts_docsize VALUES(41,X'0e00060201');
INSERT INTO knowledge_fts_docsize VALUES(42,X'0e00060201');
INSERT INTO knowledge_fts_docsize VALUES(43,X'0f00060201');
INSERT INTO knowledge_fts_docsize VALUES(44,X'0f00060201');
INSERT INTO knowledge_fts_docsize VALUES(45,X'0f00060201');
INSERT INTO knowledge_fts_docsize VALUES(46,X'0f00060201');
INSERT INTO knowledge_fts_docsize VALUES(47,X'0e00060201');
INSERT INTO knowledge_fts_docsize VALUES(48,X'0f00060201');
INSERT INTO knowledge_fts_docsize VALUES(49,X'1904060102');
INSERT INTO knowledge_fts_docsize VALUES(50,X'0500060102');
INSERT INTO knowledge_fts_docsize VALUES(51,X'1f00050201');
INSERT INTO knowledge_fts_docsize VALUES(52,X'2400050201');
INSERT INTO knowledge_fts_docsize VALUES(53,X'1c00050201');
INSERT INTO knowledge_fts_docsize VALUES(54,X'2200050201');
INSERT INTO knowledge_fts_docsize VALUES(55,X'1e00050201');
INSERT INTO knowledge_fts_docsize VALUES(56,X'2800050201');
INSERT INTO knowledge_fts_docsize VALUES(57,X'0e00060201');
INSERT INTO knowledge_fts_docsize VALUES(58,X'0e00060201');
INSERT INTO knowledge_fts_docsize VALUES(59,X'1400050201');
INSERT INTO knowledge_fts_docsize VALUES(60,X'1400050201');
INSERT INTO knowledge_fts_docsize VALUES(61,X'2900050201');
CREATE TABLE IF NOT EXISTS 'knowledge_fts_config'(k PRIMARY KEY, v) WITHOUT ROWID;
INSERT INTO knowledge_fts_config VALUES('version',4);
INSERT INTO sqlite_sequence VALUES('ads_types',37);
INSERT INTO sqlite_sequence VALUES('brands',10);
INSERT INTO sqlite_sequence VALUES('strategies',1);
INSERT INTO sqlite_sequence VALUES('seeds',1);
INSERT INTO sqlite_sequence VALUES('creatives',11);
INSERT INTO sqlite_sequence VALUES('knowledge',61);
INSERT INTO sqlite_sequence VALUES('patterns',18);
INSERT INTO sqlite_sequence VALUES('reference_library',21);
CREATE TRIGGER knowledge_ai AFTER INSERT ON knowledge BEGIN
    INSERT INTO knowledge_fts(rowid, fact, tags, source, type, agent)
    VALUES (new.id, new.fact, new.tags, new.source, new.type, new.agent);
END;
CREATE TRIGGER knowledge_ad AFTER DELETE ON knowledge BEGIN
    INSERT INTO knowledge_fts(knowledge_fts, rowid, fact, tags, source, type, agent)
    VALUES ('delete', old.id, old.fact, old.tags, old.source, old.type, old.agent);
END;
CREATE INDEX idx_ref_source ON reference_library(source);
CREATE INDEX idx_ref_brand ON reference_library(brand_id);
PRAGMA writable_schema=OFF;
COMMIT;
