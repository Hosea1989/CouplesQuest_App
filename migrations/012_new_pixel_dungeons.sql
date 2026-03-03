-- =============================================================
-- 012 — New Pixel-Art Dungeons
-- Adds 4 new dungeons that use the pixel background assets.
-- Fills level gaps in the progression: Lv3, Lv12, Lv20, Lv35.
--
-- Run AFTER seed_agent7_content.sql
-- =============================================================

-- Dungeon 15: Emerald Canopy (Normal, Lv3) — Grove/Forest theme
INSERT INTO public.content_dungeons (id, name, description, theme, difficulty, level_requirement, recommended_stat_total, max_party_size, base_exp_reward, base_gold_reward, loot_tier, rooms, active, sort_order)
VALUES (
    'emerald_canopy',
    'Emerald Canopy',
    'A sunlit grove where mischievous sprites guard nature''s treasures. A gentle test for new adventurers.',
    'grove',
    'normal',
    3,
    25,
    2,
    100,
    55,
    1,
    '[
        {"name":"Mossy Trail","description":"Vines tug at your ankles. The forest is sizing you up.","encounter_type":"trap","primary_stat":"dexterity","difficulty_rating":8,"is_boss_room":false,"bonus_loot_chance":0.05},
        {"name":"Sprite Hollow","description":"Giggling sprites pelt you with acorns and riddles.","encounter_type":"puzzle","primary_stat":"wisdom","difficulty_rating":10,"is_boss_room":false,"bonus_loot_chance":0.08},
        {"name":"The Great Oak","description":"An ancient treant awakens to test your worth.","encounter_type":"boss","primary_stat":"charisma","difficulty_rating":14,"is_boss_room":true,"bonus_loot_chance":0.25}
    ]'::jsonb,
    TRUE,
    15
) ON CONFLICT (id) DO NOTHING;

-- Dungeon 16: Mycelium Depths (Hard, Lv12) — Mushroom/Fungal theme
INSERT INTO public.content_dungeons (id, name, description, theme, difficulty, level_requirement, recommended_stat_total, max_party_size, base_exp_reward, base_gold_reward, loot_tier, rooms, active, sort_order)
VALUES (
    'mycelium_depths',
    'Mycelium Depths',
    'Bioluminescent fungi light a sprawling underground network. The spores whisper secrets to those who listen.',
    'mushroom',
    'hard',
    12,
    55,
    4,
    450,
    250,
    2,
    '[
        {"name":"Spore Tunnel","description":"Clouds of glowing spores obscure the path. Breathe carefully.","encounter_type":"trap","primary_stat":"dexterity","difficulty_rating":18,"is_boss_room":false,"bonus_loot_chance":0.05},
        {"name":"Fungal Garden","description":"Towering mushrooms hum with strange energy. Rare ingredients grow here.","encounter_type":"treasure","primary_stat":"luck","difficulty_rating":14,"is_boss_room":false,"bonus_loot_chance":0.30},
        {"name":"Myconid Colony","description":"Sentient mushroom-folk block the way. They can be reasoned with... maybe.","encounter_type":"puzzle","primary_stat":"charisma","difficulty_rating":20,"is_boss_room":false,"bonus_loot_chance":0.08},
        {"name":"Rot Beetle Nest","description":"Armoured beetles swarm from the decaying walls!","encounter_type":"combat","primary_stat":"strength","difficulty_rating":22,"is_boss_room":false,"bonus_loot_chance":0.08},
        {"name":"The Spormother","description":"A massive fungal entity pulses at the heart of the depths.","encounter_type":"boss","primary_stat":"wisdom","difficulty_rating":26,"is_boss_room":true,"bonus_loot_chance":0.35}
    ]'::jsonb,
    TRUE,
    16
) ON CONFLICT (id) DO NOTHING;

-- Dungeon 17: Frostpeak Summit (Heroic, Lv20) — Mountain/Frost theme
INSERT INTO public.content_dungeons (id, name, description, theme, difficulty, level_requirement, recommended_stat_total, max_party_size, base_exp_reward, base_gold_reward, loot_tier, rooms, active, sort_order)
VALUES (
    'frostpeak_summit',
    'Frostpeak Summit',
    'A treacherous ascent through blinding snowstorms and ancient ice caverns. Only the resilient reach the top.',
    'mountain',
    'heroic',
    20,
    85,
    4,
    1100,
    650,
    3,
    '[
        {"name":"Avalanche Pass","description":"The mountain rumbles. Time your crossing or be buried.","encounter_type":"trap","primary_stat":"dexterity","difficulty_rating":28,"is_boss_room":false,"bonus_loot_chance":0.05},
        {"name":"Ice Bridge","description":"A shimmering bridge of solid ice spans a bottomless crevasse.","encounter_type":"puzzle","primary_stat":"wisdom","difficulty_rating":30,"is_boss_room":false,"bonus_loot_chance":0.08},
        {"name":"Frost Wolf Den","description":"A pack of dire wolves guards their territory with fang and fury.","encounter_type":"combat","primary_stat":"strength","difficulty_rating":32,"is_boss_room":false,"bonus_loot_chance":0.08},
        {"name":"Frozen Shrine","description":"An ancient shrine encased in ice. Offerings still glitter within.","encounter_type":"treasure","primary_stat":"luck","difficulty_rating":22,"is_boss_room":false,"bonus_loot_chance":0.40},
        {"name":"Storm Plateau","description":"Winds howl at speeds that could tear flesh from bone.","encounter_type":"trap","primary_stat":"defense","difficulty_rating":34,"is_boss_room":false,"bonus_loot_chance":0.05},
        {"name":"The Frost Wyrm","description":"Atop the summit, a dragon of living ice spreads its crystalline wings.","encounter_type":"boss","primary_stat":"strength","difficulty_rating":40,"is_boss_room":true,"bonus_loot_chance":0.50}
    ]'::jsonb,
    TRUE,
    17
) ON CONFLICT (id) DO NOTHING;

-- Dungeon 18: Scorched Wastes (Heroic, Lv35) — Desert theme
INSERT INTO public.content_dungeons (id, name, description, theme, difficulty, level_requirement, recommended_stat_total, max_party_size, base_exp_reward, base_gold_reward, loot_tier, rooms, active, sort_order)
VALUES (
    'scorched_wastes',
    'Scorched Wastes',
    'An endless expanse of burning sands where a buried civilization hides terrible power. The heat alone can kill.',
    'desert',
    'heroic',
    35,
    120,
    4,
    2000,
    1200,
    4,
    '[
        {"name":"Sandstorm Gauntlet","description":"Walls of sand roar across the dunes. Visibility is zero.","encounter_type":"trap","primary_stat":"dexterity","difficulty_rating":34,"is_boss_room":false,"bonus_loot_chance":0.05},
        {"name":"Mirage Oasis","description":"Is it real? The shimmering pool could be salvation or a trap.","encounter_type":"puzzle","primary_stat":"wisdom","difficulty_rating":32,"is_boss_room":false,"bonus_loot_chance":0.08},
        {"name":"Scorpion Pit","description":"Giant scorpions erupt from the sand, stingers poised to strike.","encounter_type":"combat","primary_stat":"strength","difficulty_rating":36,"is_boss_room":false,"bonus_loot_chance":0.08},
        {"name":"Buried Temple","description":"Half-swallowed by sand, ancient treasures peek through the dunes.","encounter_type":"treasure","primary_stat":"luck","difficulty_rating":26,"is_boss_room":false,"bonus_loot_chance":0.45},
        {"name":"Sun Altar","description":"Blinding light pours from a stone altar. A puzzle of reflections.","encounter_type":"puzzle","primary_stat":"wisdom","difficulty_rating":38,"is_boss_room":false,"bonus_loot_chance":0.08},
        {"name":"The Sand Pharaoh","description":"An undead king rises from his sarcophagus, wreathed in golden flame.","encounter_type":"boss","primary_stat":"charisma","difficulty_rating":44,"is_boss_room":true,"bonus_loot_chance":0.55}
    ]'::jsonb,
    TRUE,
    18
) ON CONFLICT (id) DO NOTHING;
