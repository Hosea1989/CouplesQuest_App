-- =============================================================
-- Fix Dungeon Reward Progression
--
-- Problem: Original 6 dungeons had inflated rewards (The Abyss
-- at Lv40 gave 5000 EXP / 3000 Gold) while the 8 newer dungeons
-- had deflated rewards (Venomspire Jungle at Lv45 gave only
-- 600 EXP / 400 Gold). Rewards now scale smoothly from Lv1→Lv90.
-- =============================================================

-- Original 6 dungeons (from seed_content_data.sql)
-- Goblin Caves (Lv1) stays the same: 150 / 80

UPDATE public.content_dungeons
SET base_exp_reward = 300, base_gold_reward = 175
WHERE id = 'dungeon_ancient_ruins';

UPDATE public.content_dungeons
SET base_exp_reward = 500, base_gold_reward = 300
WHERE id = 'dungeon_shadow_forest';

UPDATE public.content_dungeons
SET base_exp_reward = 700, base_gold_reward = 425
WHERE id = 'dungeon_iron_fortress';

UPDATE public.content_dungeons
SET base_exp_reward = 1400, base_gold_reward = 850
WHERE id = 'dungeon_dragons_peak';

UPDATE public.content_dungeons
SET base_exp_reward = 2800, base_gold_reward = 1700
WHERE id = 'dungeon_the_abyss';

-- Agent 7 dungeons (from seed_agent7_content.sql)
UPDATE public.content_dungeons
SET base_exp_reward = 650, base_gold_reward = 375
WHERE id = 'sunken_temple';

UPDATE public.content_dungeons
SET base_exp_reward = 1000, base_gold_reward = 600
WHERE id = 'crimson_mines';

UPDATE public.content_dungeons
SET base_exp_reward = 1800, base_gold_reward = 1100
WHERE id = 'phantom_citadel';

UPDATE public.content_dungeons
SET base_exp_reward = 3400, base_gold_reward = 2000
WHERE id = 'venomspire_jungle';

UPDATE public.content_dungeons
SET base_exp_reward = 5000, base_gold_reward = 3000
WHERE id = 'crystal_caverns';

UPDATE public.content_dungeons
SET base_exp_reward = 6500, base_gold_reward = 4000
WHERE id = 'stormspire_pinnacle';

UPDATE public.content_dungeons
SET base_exp_reward = 8500, base_gold_reward = 5200
WHERE id = 'necropolis_shadows';

UPDATE public.content_dungeons
SET base_exp_reward = 10000, base_gold_reward = 6500
WHERE id = 'celestial_sanctum';
