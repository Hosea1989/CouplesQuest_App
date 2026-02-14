-- =============================================================
-- QuestBond Seed — Agent 7 Content Expansion
-- Dungeons, AFK Missions, Raid Bosses, Arena Modifiers, Cards
--
-- Run AFTER 005_content_tables.sql and 007_raids_arena_tables.sql
-- =============================================================


-- -----------------------------------------------------------
-- 1. NEW DUNGEON TEMPLATES (8 new dungeons covering Lv15–100)
--    Existing 6 dungeons should already be seeded by Agent 5.
--    Each dungeon has 8–10 rooms defined; engine picks 5–7 per run.
-- -----------------------------------------------------------

-- Dungeon 7: Sunken Temple (Hard, Lv15) — Water/Ruin theme
INSERT INTO public.content_dungeons (id, name, description, theme, difficulty, level_requirement, recommended_stat_total, max_party_size, base_exp_reward, base_gold_reward, loot_tier, rooms, active, sort_order)
VALUES (
    'sunken_temple',
    'Sunken Temple',
    'An ancient temple half-submerged beneath murky waters. Strange lights flicker in the depths.',
    'aquatic',
    'hard',
    15,
    60,
    4,
    650,
    375,
    2,
    '[
        {"name":"Flooded Entrance","description":"Waist-deep water slows your advance. Something moves beneath the surface.","encounter_type":"trap","primary_stat":"dexterity","difficulty_rating":18,"is_boss_room":false,"bonus_loot_chance":0.05},
        {"name":"Coral Corridor","description":"Bioluminescent coral lights a narrow passage. The walls seem to breathe.","encounter_type":"puzzle","primary_stat":"wisdom","difficulty_rating":20,"is_boss_room":false,"bonus_loot_chance":0.05},
        {"name":"Tide Pool Chamber","description":"A massive tide pool harbors aggressive sea creatures.","encounter_type":"combat","primary_stat":"strength","difficulty_rating":22,"is_boss_room":false,"bonus_loot_chance":0.08},
        {"name":"Sunken Library","description":"Waterlogged tomes line the shelves. Some still hold readable secrets.","encounter_type":"puzzle","primary_stat":"wisdom","difficulty_rating":19,"is_boss_room":false,"bonus_loot_chance":0.10},
        {"name":"Pressure Lock","description":"A mechanical lock system threatens to flood the chamber entirely.","encounter_type":"trap","primary_stat":"dexterity","difficulty_rating":24,"is_boss_room":false,"bonus_loot_chance":0.05},
        {"name":"Kelp Garden","description":"Thick kelp forests hide darting shadows and buried treasure.","encounter_type":"treasure","primary_stat":"luck","difficulty_rating":16,"is_boss_room":false,"bonus_loot_chance":0.20},
        {"name":"Merfolk Guard Post","description":"Ancient merfolk guardians still patrol these halls in undeath.","encounter_type":"combat","primary_stat":"strength","difficulty_rating":25,"is_boss_room":false,"bonus_loot_chance":0.08},
        {"name":"Whirlpool Staircase","description":"A spiraling staircase descends around a swirling vortex.","encounter_type":"trap","primary_stat":"dexterity","difficulty_rating":26,"is_boss_room":false,"bonus_loot_chance":0.05},
        {"name":"The Leviathan''s Rest","description":"The temple''s deepest chamber. Something ancient sleeps here.","encounter_type":"boss","primary_stat":"strength","difficulty_rating":30,"is_boss_room":true,"bonus_loot_chance":0.30},
        {"name":"Treasure Vault (Bonus)","description":"A hidden vault behind a crumbling wall. Riches untouched for centuries.","encounter_type":"treasure","primary_stat":"luck","difficulty_rating":15,"is_boss_room":false,"bonus_loot_chance":0.40,"is_bonus_room":true}
    ]'::jsonb,
    TRUE,
    7
) ON CONFLICT (id) DO NOTHING;

-- Dungeon 8: Crimson Mines (Heroic, Lv20) — Fire/Mining theme
INSERT INTO public.content_dungeons (id, name, description, theme, difficulty, level_requirement, recommended_stat_total, max_party_size, base_exp_reward, base_gold_reward, loot_tier, rooms, active, sort_order)
VALUES (
    'crimson_mines',
    'Crimson Mines',
    'Deep mining tunnels glow red with volcanic heat. The dwarves who dug here vanished overnight.',
    'volcanic',
    'heroic',
    20,
    80,
    4,
    1000,
    600,
    3,
    '[
        {"name":"Mine Entrance","description":"Abandoned carts and broken picks litter the entrance. The air is thick with sulfur.","encounter_type":"trap","primary_stat":"dexterity","difficulty_rating":24,"is_boss_room":false,"bonus_loot_chance":0.05},
        {"name":"Collapsed Shaft","description":"The ceiling groans overhead. One wrong step could bring it all down.","encounter_type":"trap","primary_stat":"dexterity","difficulty_rating":28,"is_boss_room":false,"bonus_loot_chance":0.05},
        {"name":"Lava Flow Crossing","description":"Molten rock cuts across the path. Find a way through or turn back.","encounter_type":"puzzle","primary_stat":"wisdom","difficulty_rating":30,"is_boss_room":false,"bonus_loot_chance":0.08},
        {"name":"Ember Beetle Nest","description":"Fire-breathing beetles swarm from cracks in the stone.","encounter_type":"combat","primary_stat":"strength","difficulty_rating":32,"is_boss_room":false,"bonus_loot_chance":0.08},
        {"name":"Ore Vein Chamber","description":"Raw gemstones glitter in the walls. Guarded by something territorial.","encounter_type":"combat","primary_stat":"strength","difficulty_rating":30,"is_boss_room":false,"bonus_loot_chance":0.15},
        {"name":"Dwarven Forge Hall","description":"A magnificent forge still burns. Ancient runes protect its secrets.","encounter_type":"puzzle","primary_stat":"wisdom","difficulty_rating":26,"is_boss_room":false,"bonus_loot_chance":0.10},
        {"name":"Steam Vent Maze","description":"Superheated steam erupts unpredictably from grates in the floor.","encounter_type":"trap","primary_stat":"dexterity","difficulty_rating":34,"is_boss_room":false,"bonus_loot_chance":0.05},
        {"name":"Magma Guardian","description":"A construct of living magma blocks the deepest passage.","encounter_type":"combat","primary_stat":"defense","difficulty_rating":36,"is_boss_room":false,"bonus_loot_chance":0.10},
        {"name":"Heart of the Mountain","description":"The mine''s core — a chamber of pure volcanic fury and ancient dwarven gold.","encounter_type":"boss","primary_stat":"strength","difficulty_rating":40,"is_boss_room":true,"bonus_loot_chance":0.30},
        {"name":"Hidden Gem Cache (Bonus)","description":"A secret room behind a false wall. Gems as big as your fist.","encounter_type":"treasure","primary_stat":"luck","difficulty_rating":20,"is_boss_room":false,"bonus_loot_chance":0.45,"is_bonus_room":true}
    ]'::jsonb,
    TRUE,
    8
) ON CONFLICT (id) DO NOTHING;

-- Dungeon 9: Phantom Citadel (Heroic, Lv30) — Ghost/Undead theme
INSERT INTO public.content_dungeons (id, name, description, theme, difficulty, level_requirement, recommended_stat_total, max_party_size, base_exp_reward, base_gold_reward, loot_tier, rooms, active, sort_order)
VALUES (
    'phantom_citadel',
    'Phantom Citadel',
    'A fortress frozen in time. The spirits of its fallen garrison still march its halls.',
    'phantom',
    'heroic',
    30,
    110,
    4,
    1800,
    1100,
    3,
    '[
        {"name":"Ghostly Gatehouse","description":"Spectral guards challenge all who approach. Only the brave may pass.","encounter_type":"combat","primary_stat":"charisma","difficulty_rating":35,"is_boss_room":false,"bonus_loot_chance":0.05},
        {"name":"Hall of Echoes","description":"Every sound repeats endlessly. The whispers reveal clues — or madness.","encounter_type":"puzzle","primary_stat":"wisdom","difficulty_rating":38,"is_boss_room":false,"bonus_loot_chance":0.08},
        {"name":"Phantom Armory","description":"Weapons float in mid-air, wielded by invisible hands.","encounter_type":"combat","primary_stat":"strength","difficulty_rating":40,"is_boss_room":false,"bonus_loot_chance":0.10},
        {"name":"Cursed Banquet Hall","description":"A feast that never ends. Eat and be trapped. Resist and find the key.","encounter_type":"trap","primary_stat":"wisdom","difficulty_rating":36,"is_boss_room":false,"bonus_loot_chance":0.05},
        {"name":"Haunted Barracks","description":"Rows of ghostly soldiers snap to attention as you enter.","encounter_type":"combat","primary_stat":"defense","difficulty_rating":42,"is_boss_room":false,"bonus_loot_chance":0.08},
        {"name":"Spirit Library","description":"Phantom scholars endlessly rewrite the same tome. The answer lies within.","encounter_type":"puzzle","primary_stat":"wisdom","difficulty_rating":38,"is_boss_room":false,"bonus_loot_chance":0.12},
        {"name":"Wailing Tower","description":"The screams intensify as you climb. Each floor tests your resolve.","encounter_type":"trap","primary_stat":"charisma","difficulty_rating":44,"is_boss_room":false,"bonus_loot_chance":0.05},
        {"name":"Throne of Sorrow","description":"The spectral king sits upon his throne. He will not yield it easily.","encounter_type":"boss","primary_stat":"charisma","difficulty_rating":50,"is_boss_room":true,"bonus_loot_chance":0.30},
        {"name":"Royal Vault (Bonus)","description":"Behind the throne — treasures buried with the king himself.","encounter_type":"treasure","primary_stat":"luck","difficulty_rating":25,"is_boss_room":false,"bonus_loot_chance":0.45,"is_bonus_room":true}
    ]'::jsonb,
    TRUE,
    9
) ON CONFLICT (id) DO NOTHING;

-- Dungeon 10: Venomspire Jungle (Mythic, Lv45) — Jungle/Poison theme
INSERT INTO public.content_dungeons (id, name, description, theme, difficulty, level_requirement, recommended_stat_total, max_party_size, base_exp_reward, base_gold_reward, loot_tier, rooms, active, sort_order)
VALUES (
    'venomspire_jungle',
    'Venomspire Jungle',
    'A jungle where everything wants to kill you. The trees themselves drip with venom.',
    'jungle',
    'mythic',
    45,
    160,
    4,
    3400,
    2000,
    4,
    '[
        {"name":"Toxic Canopy","description":"Poisonous spores drift from the treetops. Every breath is a gamble.","encounter_type":"trap","primary_stat":"defense","difficulty_rating":50,"is_boss_room":false,"bonus_loot_chance":0.05},
        {"name":"Vine Trap Thicket","description":"Living vines lash out at anything that moves.","encounter_type":"trap","primary_stat":"dexterity","difficulty_rating":54,"is_boss_room":false,"bonus_loot_chance":0.05},
        {"name":"Serpent Nest","description":"Giant venomous serpents guard their brood with ferocity.","encounter_type":"combat","primary_stat":"strength","difficulty_rating":56,"is_boss_room":false,"bonus_loot_chance":0.10},
        {"name":"Ancient Altar","description":"A blood-stained altar holds an inscription in a forgotten tongue.","encounter_type":"puzzle","primary_stat":"wisdom","difficulty_rating":52,"is_boss_room":false,"bonus_loot_chance":0.12},
        {"name":"Quicksand Crossing","description":"The path disappears into treacherous quicksand. Choose wisely.","encounter_type":"trap","primary_stat":"dexterity","difficulty_rating":58,"is_boss_room":false,"bonus_loot_chance":0.05},
        {"name":"Predator''s Arena","description":"You''ve stumbled into a natural arena. Apex predators circle.","encounter_type":"combat","primary_stat":"strength","difficulty_rating":60,"is_boss_room":false,"bonus_loot_chance":0.10},
        {"name":"Mushroom Cavern","description":"Bioluminescent fungi illuminate a hidden cave. The spores whisper secrets.","encounter_type":"puzzle","primary_stat":"wisdom","difficulty_rating":50,"is_boss_room":false,"bonus_loot_chance":0.15},
        {"name":"River of Venom","description":"A river of pure venom blocks the path. One slip means death.","encounter_type":"trap","primary_stat":"dexterity","difficulty_rating":62,"is_boss_room":false,"bonus_loot_chance":0.05},
        {"name":"The Venomspire Queen","description":"The source of the jungle''s corruption — a colossal spider queen.","encounter_type":"boss","primary_stat":"strength","difficulty_rating":70,"is_boss_room":true,"bonus_loot_chance":0.35},
        {"name":"Hidden Hollow (Bonus)","description":"A pristine clearing untouched by corruption. Rare herbs grow here.","encounter_type":"treasure","primary_stat":"luck","difficulty_rating":30,"is_boss_room":false,"bonus_loot_chance":0.50,"is_bonus_room":true}
    ]'::jsonb,
    TRUE,
    10
) ON CONFLICT (id) DO NOTHING;

-- Dungeon 11: Crystal Caverns (Mythic, Lv60) — Crystal/Arcane theme
INSERT INTO public.content_dungeons (id, name, description, theme, difficulty, level_requirement, recommended_stat_total, max_party_size, base_exp_reward, base_gold_reward, loot_tier, rooms, active, sort_order)
VALUES (
    'crystal_caverns',
    'Crystal Caverns',
    'Massive crystals hum with raw magical energy. Reality bends at the deeper levels.',
    'crystal',
    'mythic',
    60,
    220,
    4,
    5000,
    3000,
    4,
    '[
        {"name":"Prism Entry","description":"Light refracts through crystalline walls, creating disorienting rainbows.","encounter_type":"puzzle","primary_stat":"wisdom","difficulty_rating":65,"is_boss_room":false,"bonus_loot_chance":0.05},
        {"name":"Resonance Chamber","description":"The crystals vibrate at a frequency that rattles your bones.","encounter_type":"trap","primary_stat":"defense","difficulty_rating":70,"is_boss_room":false,"bonus_loot_chance":0.05},
        {"name":"Crystal Golem Patrol","description":"Massive golems of living crystal patrol the tunnels.","encounter_type":"combat","primary_stat":"strength","difficulty_rating":72,"is_boss_room":false,"bonus_loot_chance":0.10},
        {"name":"Mirror Maze","description":"Every surface reflects your image. Which path is real?","encounter_type":"puzzle","primary_stat":"wisdom","difficulty_rating":68,"is_boss_room":false,"bonus_loot_chance":0.08},
        {"name":"Arcane Minefield","description":"Unstable mana crystals litter the floor. Step carefully.","encounter_type":"trap","primary_stat":"dexterity","difficulty_rating":75,"is_boss_room":false,"bonus_loot_chance":0.05},
        {"name":"Geode Grotto","description":"A hollow geode the size of a cathedral. Its guardians are ancient.","encounter_type":"combat","primary_stat":"strength","difficulty_rating":74,"is_boss_room":false,"bonus_loot_chance":0.12},
        {"name":"Mana Wellspring","description":"Pure magical energy erupts from the ground. Harness it or be consumed.","encounter_type":"puzzle","primary_stat":"wisdom","difficulty_rating":78,"is_boss_room":false,"bonus_loot_chance":0.10},
        {"name":"Crystallized Dragon","description":"A dragon frozen mid-flight in crystal. Its magic still lives.","encounter_type":"combat","primary_stat":"wisdom","difficulty_rating":80,"is_boss_room":false,"bonus_loot_chance":0.10},
        {"name":"The Heart Crystal","description":"A crystal of immense power pulsates at the cavern''s core.","encounter_type":"boss","primary_stat":"wisdom","difficulty_rating":90,"is_boss_room":true,"bonus_loot_chance":0.35},
        {"name":"Sealed Vein (Bonus)","description":"A sealed vein of pure mana crystal. Priceless to those who can harvest it.","encounter_type":"treasure","primary_stat":"luck","difficulty_rating":40,"is_boss_room":false,"bonus_loot_chance":0.50,"is_bonus_room":true}
    ]'::jsonb,
    TRUE,
    11
) ON CONFLICT (id) DO NOTHING;

-- Dungeon 12: Stormspire Pinnacle (Mythic, Lv70) — Storm/Sky theme
INSERT INTO public.content_dungeons (id, name, description, theme, difficulty, level_requirement, recommended_stat_total, max_party_size, base_exp_reward, base_gold_reward, loot_tier, rooms, active, sort_order)
VALUES (
    'stormspire_pinnacle',
    'Stormspire Pinnacle',
    'A tower that pierces the storm clouds. Lightning strikes every few seconds.',
    'storm',
    'mythic',
    70,
    270,
    4,
    6500,
    4000,
    4,
    '[
        {"name":"Wind-Battered Base","description":"Gale-force winds threaten to throw you from the tower before you even begin.","encounter_type":"trap","primary_stat":"defense","difficulty_rating":78,"is_boss_room":false,"bonus_loot_chance":0.05},
        {"name":"Lightning Rod Gallery","description":"Metal rods channel lightning in unpredictable patterns.","encounter_type":"trap","primary_stat":"dexterity","difficulty_rating":82,"is_boss_room":false,"bonus_loot_chance":0.05},
        {"name":"Thunderbird Roost","description":"Massive electric birds nest here. They do not welcome visitors.","encounter_type":"combat","primary_stat":"strength","difficulty_rating":85,"is_boss_room":false,"bonus_loot_chance":0.10},
        {"name":"Storm Cipher","description":"Ancient runes flash with lightning. Decode them to proceed.","encounter_type":"puzzle","primary_stat":"wisdom","difficulty_rating":80,"is_boss_room":false,"bonus_loot_chance":0.08},
        {"name":"Cloud Bridge","description":"A bridge of solidified cloud stretches over a mile-high drop.","encounter_type":"trap","primary_stat":"dexterity","difficulty_rating":88,"is_boss_room":false,"bonus_loot_chance":0.05},
        {"name":"Tempest Warriors","description":"Storm elementals in humanoid form guard the upper floors.","encounter_type":"combat","primary_stat":"strength","difficulty_rating":90,"is_boss_room":false,"bonus_loot_chance":0.10},
        {"name":"Eye of the Storm","description":"A pocket of calm amid the chaos. But it won''t last.","encounter_type":"puzzle","primary_stat":"wisdom","difficulty_rating":84,"is_boss_room":false,"bonus_loot_chance":0.12},
        {"name":"Conduit Chamber","description":"Pure electrical energy arcs between massive coils.","encounter_type":"trap","primary_stat":"defense","difficulty_rating":92,"is_boss_room":false,"bonus_loot_chance":0.05},
        {"name":"The Stormfather","description":"An ancient being of living lightning. The source of eternal storms.","encounter_type":"boss","primary_stat":"wisdom","difficulty_rating":100,"is_boss_room":true,"bonus_loot_chance":0.40},
        {"name":"Sky Cache (Bonus)","description":"A treasure room floating in clouds. The winds have gathered riches from across the land.","encounter_type":"treasure","primary_stat":"luck","difficulty_rating":50,"is_boss_room":false,"bonus_loot_chance":0.50,"is_bonus_room":true}
    ]'::jsonb,
    TRUE,
    12
) ON CONFLICT (id) DO NOTHING;

-- Dungeon 13: Necropolis of Shadows (Mythic, Lv80) — Shadow/Death theme
INSERT INTO public.content_dungeons (id, name, description, theme, difficulty, level_requirement, recommended_stat_total, max_party_size, base_exp_reward, base_gold_reward, loot_tier, rooms, active, sort_order)
VALUES (
    'necropolis_shadows',
    'Necropolis of Shadows',
    'An underground city of the dead. Shadows here have teeth.',
    'shadow',
    'mythic',
    80,
    320,
    4,
    8500,
    5200,
    4,
    '[
        {"name":"Tomb Gate","description":"A gate of black iron inscribed with warnings in a dead language.","encounter_type":"puzzle","primary_stat":"wisdom","difficulty_rating":90,"is_boss_room":false,"bonus_loot_chance":0.05},
        {"name":"Crypt Passage","description":"Coffins line the walls. Some are open. Some are moving.","encounter_type":"combat","primary_stat":"strength","difficulty_rating":95,"is_boss_room":false,"bonus_loot_chance":0.08},
        {"name":"Shadow Maze","description":"Darkness so thick it has weight. Your torch reveals nothing.","encounter_type":"trap","primary_stat":"dexterity","difficulty_rating":98,"is_boss_room":false,"bonus_loot_chance":0.05},
        {"name":"Bone Cathedral","description":"A cathedral built entirely of bones. The architecture is disturbingly beautiful.","encounter_type":"puzzle","primary_stat":"charisma","difficulty_rating":92,"is_boss_room":false,"bonus_loot_chance":0.10},
        {"name":"Wraith Corridor","description":"Wraiths phase through walls, striking from impossible angles.","encounter_type":"combat","primary_stat":"defense","difficulty_rating":100,"is_boss_room":false,"bonus_loot_chance":0.10},
        {"name":"Soul Well","description":"A well of captured souls. Free them for a reward — or a curse.","encounter_type":"trap","primary_stat":"wisdom","difficulty_rating":96,"is_boss_room":false,"bonus_loot_chance":0.15},
        {"name":"Death Knight Garrison","description":"Elite undead warriors in full plate. They fight with terrible skill.","encounter_type":"combat","primary_stat":"strength","difficulty_rating":105,"is_boss_room":false,"bonus_loot_chance":0.10},
        {"name":"Phylactery Vault","description":"Powerful magical containers holding fragments of dark power.","encounter_type":"puzzle","primary_stat":"wisdom","difficulty_rating":100,"is_boss_room":false,"bonus_loot_chance":0.12},
        {"name":"The Shadow Lord","description":"Master of the Necropolis. Darkness incarnate. The final test.","encounter_type":"boss","primary_stat":"strength","difficulty_rating":120,"is_boss_room":true,"bonus_loot_chance":0.40},
        {"name":"Lich''s Private Hoard (Bonus)","description":"Millennia of plunder. The lich won''t miss a few pieces.","encounter_type":"treasure","primary_stat":"luck","difficulty_rating":60,"is_boss_room":false,"bonus_loot_chance":0.55,"is_bonus_room":true}
    ]'::jsonb,
    TRUE,
    13
) ON CONFLICT (id) DO NOTHING;

-- Dungeon 14: Celestial Sanctum (Mythic+, Lv90) — Holy/Celestial theme
INSERT INTO public.content_dungeons (id, name, description, theme, difficulty, level_requirement, recommended_stat_total, max_party_size, base_exp_reward, base_gold_reward, loot_tier, rooms, active, sort_order)
VALUES (
    'celestial_sanctum',
    'Celestial Sanctum',
    'A sanctum among the stars. The trials here judge your very soul.',
    'celestial',
    'mythic',
    90,
    380,
    4,
    10000,
    6500,
    4,
    '[
        {"name":"Starfall Bridge","description":"A bridge of light stretches across the void between stars.","encounter_type":"trap","primary_stat":"dexterity","difficulty_rating":100,"is_boss_room":false,"bonus_loot_chance":0.05},
        {"name":"Trial of Valor","description":"Celestial judges weigh your courage against your fears.","encounter_type":"combat","primary_stat":"strength","difficulty_rating":110,"is_boss_room":false,"bonus_loot_chance":0.10},
        {"name":"Constellation Puzzle","description":"The stars themselves rearrange into a lock. Find the right pattern.","encounter_type":"puzzle","primary_stat":"wisdom","difficulty_rating":105,"is_boss_room":false,"bonus_loot_chance":0.08},
        {"name":"Solar Furnace","description":"The heat of a miniature sun fills this chamber. Move fast.","encounter_type":"trap","primary_stat":"defense","difficulty_rating":115,"is_boss_room":false,"bonus_loot_chance":0.05},
        {"name":"Angel Vanguard","description":"Celestial warriors test all who seek the inner sanctum.","encounter_type":"combat","primary_stat":"charisma","difficulty_rating":112,"is_boss_room":false,"bonus_loot_chance":0.10},
        {"name":"Moonlight Archives","description":"Knowledge of the cosmos awaits those who can read the light.","encounter_type":"puzzle","primary_stat":"wisdom","difficulty_rating":108,"is_boss_room":false,"bonus_loot_chance":0.12},
        {"name":"Void Gauntlet","description":"Pockets of nothing tear at your existence.","encounter_type":"trap","primary_stat":"defense","difficulty_rating":118,"is_boss_room":false,"bonus_loot_chance":0.05},
        {"name":"Seraphim Arena","description":"The highest order of celestials engage you in ritual combat.","encounter_type":"combat","primary_stat":"strength","difficulty_rating":120,"is_boss_room":false,"bonus_loot_chance":0.12},
        {"name":"The Celestial Arbiter","description":"The final judge. Prove your worth or be cast into the void.","encounter_type":"boss","primary_stat":"charisma","difficulty_rating":135,"is_boss_room":true,"bonus_loot_chance":0.45},
        {"name":"Astral Treasury (Bonus)","description":"Treasures from beyond mortal comprehension. Take what you can carry.","encounter_type":"treasure","primary_stat":"luck","difficulty_rating":70,"is_boss_room":false,"bonus_loot_chance":0.60,"is_bonus_room":true}
    ]'::jsonb,
    TRUE,
    14
) ON CONFLICT (id) DO NOTHING;


-- -----------------------------------------------------------
-- 2. NEW AFK MISSION TEMPLATES (12 new, filling all 5 rarities)
-- -----------------------------------------------------------

-- Common tier (30min-2hr)
INSERT INTO public.content_missions (id, name, description, mission_type, rarity, duration_seconds, stat_requirements, level_requirement, base_success_rate, exp_reward, gold_reward, can_drop_equipment, possible_drops, active, sort_order) VALUES
('herb_gathering',     'Herb Gathering',       'Forage for medicinal herbs in the nearby meadows.',           'gathering',    'common',   1800,  '[]', 1, 0.85, 15, 10, FALSE, '[{"type":"material","material_type":"Herb","rarity":"Common","quantity_min":1,"quantity_max":3}]', TRUE, 10),
('village_patrol',     'Village Patrol',        'Walk the perimeter and keep watch for trouble.',              'combat',       'common',   3600,  '[{"stat":"strength","value":5}]', 1, 0.80, 25, 18, FALSE, '[{"type":"material","material_type":"Ore","rarity":"Common","quantity_min":1,"quantity_max":2}]', TRUE, 11),

-- Uncommon tier (2-4hr)
('canyon_survey',      'Canyon Survey',         'Map uncharted canyons and document wildlife.',                'exploration',  'uncommon', 10800, '[{"stat":"dexterity","value":10}]', 5, 0.70, 55, 40, FALSE, '[{"type":"material","material_type":"Crystal","rarity":"Uncommon","quantity_min":1,"quantity_max":2}]', TRUE, 20),
('ancient_translation','Ancient Translation',   'Decipher an old manuscript found in the ruins.',              'research',     'uncommon', 7200,  '[{"stat":"wisdom","value":10}]', 5, 0.75, 45, 30, FALSE, '[{"type":"material","material_type":"Fragment","rarity":"Uncommon","quantity_min":1,"quantity_max":2}]', TRUE, 21),

-- Rare tier (4-8hr) — NEW TIER
('deep_cave_expedition','Deep Cave Expedition', 'Explore the treacherous caves beneath the mountains for rare minerals.', 'exploration', 'rare', 18000, '[{"stat":"strength","value":18},{"stat":"dexterity","value":12}]', 15, 0.60, 120, 85, TRUE, '[{"type":"material","material_type":"Ore","rarity":"Rare","quantity_min":2,"quantity_max":4},{"type":"material","material_type":"Crystal","rarity":"Uncommon","quantity_min":1,"quantity_max":3}]', TRUE, 30),
('bandit_infiltration', 'Bandit Infiltration',  'Infiltrate a bandit camp and recover stolen goods.',          'stealth',      'rare',     21600, '[{"stat":"dexterity","value":20},{"stat":"charisma","value":10}]', 20, 0.55, 140, 100, TRUE, '[{"type":"material","material_type":"Hide","rarity":"Rare","quantity_min":1,"quantity_max":3}]', TRUE, 31),
('arcane_ritual',      'Arcane Ritual',         'Perform a complex magical ritual to harness ley line energy.', 'research',     'rare',     14400, '[{"stat":"wisdom","value":22}]', 20, 0.60, 110, 75, TRUE, '[{"type":"material","material_type":"Essence","rarity":"Rare","quantity_min":2,"quantity_max":4}]', TRUE, 32),
('diplomatic_mission', 'Diplomatic Mission',    'Negotiate a trade agreement with a distant settlement.',      'negotiation',  'rare',     25200, '[{"stat":"charisma","value":20},{"stat":"wisdom","value":12}]', 18, 0.55, 130, 120, TRUE, '[{"type":"material","material_type":"Fragment","rarity":"Rare","quantity_min":1,"quantity_max":2}]', TRUE, 33),

-- Epic tier (8-12hr)
('volcanic_expedition','Volcanic Expedition',   'Brave the volcanic peaks to harvest obsidian and fire opals.', 'exploration',  'epic',     36000, '[{"stat":"strength","value":30},{"stat":"defense","value":20}]', 35, 0.45, 280, 200, TRUE, '[{"type":"material","material_type":"Ore","rarity":"Epic","quantity_min":2,"quantity_max":4},{"type":"material","material_type":"Crystal","rarity":"Rare","quantity_min":1,"quantity_max":3}]', TRUE, 40),
('shadow_realm_recon', 'Shadow Realm Recon',    'Scout the borders of the Shadow Realm and report your findings.', 'stealth',   'epic',     43200, '[{"stat":"dexterity","value":28},{"stat":"wisdom","value":22}]', 40, 0.40, 320, 230, TRUE, '[{"type":"material","material_type":"Essence","rarity":"Epic","quantity_min":2,"quantity_max":3}]', TRUE, 41),

-- Legendary tier (12-24hr) — NEW TIER
('celestial_pilgrimage','Celestial Pilgrimage', 'Embark on a spiritual journey to the Celestial Sanctum itself.', 'exploration', 'legendary', 57600, '[{"stat":"wisdom","value":35},{"stat":"charisma","value":25}]', 60, 0.35, 550, 400, TRUE, '[{"type":"material","material_type":"Essence","rarity":"Epic","quantity_min":3,"quantity_max":5},{"type":"material","material_type":"Crystal","rarity":"Epic","quantity_min":2,"quantity_max":4}]', TRUE, 50),
('abyssal_hunt',       'Abyssal Hunt',          'Track and confront a lesser abyssal entity in its own domain.', 'combat',     'legendary', 86400, '[{"stat":"strength","value":40},{"stat":"defense","value":30},{"stat":"luck","value":15}]', 70, 0.30, 750, 550, TRUE, '[{"type":"material","material_type":"Ore","rarity":"Epic","quantity_min":2,"quantity_max":4},{"type":"material","material_type":"Fragment","rarity":"Epic","quantity_min":2,"quantity_max":3}]', TRUE, 51)
ON CONFLICT (id) DO NOTHING;


-- -----------------------------------------------------------
-- 3. RAID BOSS TEMPLATES (8 bosses for weekly rotation)
-- -----------------------------------------------------------

INSERT INTO public.content_raids (id, name, description, icon, theme, modifier_name, modifier_description, modifier_stat_penalty, modifier_penalty_value, modifier_stat_bonus, modifier_bonus_value, base_hp_per_tier, gold_reward_per_tier, exp_reward_per_tier, guaranteed_consumable, equip_drop_chance, unique_card_id, active, sort_order) VALUES
('boss_gorrath',    'Gorrath the Undying',       'An ancient lich whose dark magic drains the life from all who oppose him.', 'flame.circle.fill',    'shadow',  'Necrotic Aura',   '-30% STR damage, +50% WIS damage',     'strength', 0.30, 'wisdom',    0.50, 3000, 150, 200, 'exp_boost',   0.20, 'card_boss_gorrath',    TRUE, 1),
('boss_vexara',     'Vexara, Queen of Thorns',   'A corrupted nature spirit whose venomous thorns spread across the land.',  'leaf.circle.fill',     'nature',  'Thorn Shield',    '-30% DEX damage, +50% STR damage',     'dexterity',0.30, 'strength',  0.50, 3000, 150, 200, 'hp_restore',  0.20, 'card_boss_vexara',     TRUE, 2),
('boss_ironclad',   'Ironclad Behemoth',         'A massive construct of steel and fury, awakened from a forgotten war.',    'gearshape.circle.fill','iron',    'Iron Fortress',   '-30% WIS damage, +50% DEF damage',     'wisdom',   0.30, 'defense',   0.50, 3500, 175, 220, 'stat_potion', 0.22, 'card_boss_ironclad',   TRUE, 3),
('boss_shadowmaw',  'Shadowmaw',                 'A draconic beast born from pure darkness, consuming light itself.',       'moon.circle.fill',     'shadow',  'Consuming Dark',  '-30% CHA damage, +50% DEX damage',     'charisma', 0.30, 'dexterity', 0.50, 3000, 150, 200, 'luck_elixir', 0.20, 'card_boss_shadowmaw',  TRUE, 4),
('boss_herald',     'The Crimson Herald',        'A demonic commander who heralds the end of an age.',                      'bolt.circle.fill',     'fire',    'Crimson Flames',  '-30% DEF damage, +50% CHA damage',     'defense',  0.30, 'charisma',  0.50, 3200, 160, 210, 'exp_boost',   0.22, 'card_boss_herald',     TRUE, 5),
('boss_frostweaver','Frostweaver Empress',       'An ice sorceress whose blizzards can freeze time itself.',                'snowflake.circle',     'ice',     'Absolute Zero',   '-30% STR damage, +50% WIS damage',     'strength', 0.30, 'wisdom',    0.50, 3000, 150, 200, 'stat_potion', 0.20, 'card_boss_frostweaver',TRUE, 6),
('boss_titan',      'Abyssal Titan',             'A colossal entity from the deep, whose mere presence warps reality.',     'tornado.circle.fill',  'void',    'Reality Warp',    'All stats reduced -15%, LCK +80%',     NULL,       0.15, 'luck',      0.80, 3800, 190, 240, 'luck_elixir', 0.25, 'card_boss_titan',      TRUE, 7),
('boss_pyrax',      'Pyrax the World Burner',    'A primordial dragon of flame, scorching all in its path.',                'flame.fill',           'fire',    'World Fire',      '-40% DEF damage, +60% STR damage',     'defense',  0.40, 'strength',  0.60, 4000, 200, 250, 'hp_restore',  0.25, 'card_boss_pyrax',      TRUE, 8)
ON CONFLICT (id) DO NOTHING;


-- -----------------------------------------------------------
-- 4. ARENA MODIFIERS (6 weekly rotation modifiers)
-- -----------------------------------------------------------

INSERT INTO public.content_arena_modifiers (id, name, description, icon, damage_dealt_multiplier, damage_taken_multiplier, starting_hp_override, hp_regen_per_wave, gold_multiplier, exp_multiplier, all_boss_waves, stat_focus, stat_focus_multiplier, active, sort_order) VALUES
('mod_berserker',      'Berserker',        'Double damage dealt and taken. High risk, high reward.',      'flame.fill',            2.0, 2.0, NULL, 0,  1.0, 1.0,  FALSE, NULL,        1.0, TRUE, 1),
('mod_endurance',      'Endurance',        'Heal 10 HP between waves. Test your stamina.',                'heart.circle.fill',     1.0, 1.0, NULL, 10, 1.0, 1.0,  FALSE, NULL,        1.0, TRUE, 2),
('mod_glass_cannon',   'Glass Cannon',     'Start with 50 HP but deal double damage.',                   'bolt.trianglebadge.exclamationmark.fill', 2.0, 1.0, 50, 0, 1.0, 1.0, FALSE, NULL, 1.0, TRUE, 3),
('mod_boss_rush',      'Boss Rush',        'Every wave is a boss wave. Only the strongest survive.',      'crown.fill',            1.0, 1.0, NULL, 0,  1.5, 1.5,  TRUE,  NULL,        1.0, TRUE, 4),
('mod_time_trial',     'Time Trial',       'Faster timer, but +50% gold rewards.',                        'clock.badge.checkmark.fill', 1.0, 1.0, NULL, 0, 1.5, 1.0, FALSE, NULL,    1.0, TRUE, 5),
('mod_elemental_fury', 'Elemental Fury',   'One stat deals double damage this week. Class composition matters.', 'sparkles',      1.0, 1.0, NULL, 0,  1.0, 1.0,  FALSE, 'strength',  2.0, TRUE, 6)
ON CONFLICT (id) DO NOTHING;


-- -----------------------------------------------------------
-- 5. MONSTER CARDS — New dungeon themes + Arena-exclusive
-- -----------------------------------------------------------

-- Aquatic theme (Sunken Temple) — 4 cards
INSERT INTO public.content_cards (id, name, description, theme, rarity, bonus_type, bonus_value, source_type, source_name, drop_chance, active, sort_order) VALUES
('card_tide_lurker',     'Tide Lurker',        'A creature that hunts in the shallows.',                  'aquatic',  'common',    'dungeon_success', 0.003, 'dungeon', 'Sunken Temple', 0.12, TRUE, 100),
('card_coral_sentinel',  'Coral Sentinel',     'An ancient guardian made of living coral.',                'aquatic',  'uncommon',  'flat_defense',    1.0,   'dungeon', 'Sunken Temple', 0.10, TRUE, 101),
('card_deep_siren',      'Deep Siren',         'Its song lures the unwary into the depths.',              'aquatic',  'rare',      'loot_chance',     0.004, 'dungeon', 'Sunken Temple', 0.08, TRUE, 102),
('card_leviathan_spawn', 'Leviathan Spawn',    'A lesser offspring of the temple''s ancient guardian.',    'aquatic',  'epic',      'dungeon_success', 0.005, 'dungeon', 'Sunken Temple', 0.05, TRUE, 103),

-- Volcanic theme (Crimson Mines) — 4 cards
('card_ember_beetle',    'Ember Beetle',       'Its carapace burns with inner fire.',                      'volcanic', 'common',    'gold_percent',    0.003, 'dungeon', 'Crimson Mines', 0.12, TRUE, 110),
('card_magma_guardian',  'Magma Guardian',      'A living construct of molten stone.',                     'volcanic', 'uncommon',  'flat_defense',    1.0,   'dungeon', 'Crimson Mines', 0.10, TRUE, 111),
('card_flame_wyrm',      'Flame Wyrm',         'A serpentine beast that swims through lava.',              'volcanic', 'rare',      'exp_percent',     0.004, 'dungeon', 'Crimson Mines', 0.08, TRUE, 112),
('card_forge_elemental', 'Forge Elemental',    'Born from the abandoned dwarven forges.',                  'volcanic', 'epic',      'dungeon_success', 0.005, 'dungeon', 'Crimson Mines', 0.05, TRUE, 113),

-- Phantom theme (Phantom Citadel) — 4 cards
('card_phantom_soldier', 'Phantom Soldier',    'A ghostly warrior still following orders.',                'phantom',  'common',    'exp_percent',     0.003, 'dungeon', 'Phantom Citadel', 0.12, TRUE, 120),
('card_wailing_wraith',  'Wailing Wraith',     'Its cry freezes the blood of the living.',                 'phantom',  'uncommon',  'gold_percent',    0.003, 'dungeon', 'Phantom Citadel', 0.10, TRUE, 121),
('card_death_knight',    'Death Knight',        'An elite undead warrior bound by dark oaths.',            'phantom',  'rare',      'flat_defense',    2.0,   'dungeon', 'Phantom Citadel', 0.08, TRUE, 122),
('card_spectral_king',   'Spectral King',      'The once-great ruler, now a shadow of former glory.',      'phantom',  'epic',      'dungeon_success', 0.005, 'dungeon', 'Phantom Citadel', 0.05, TRUE, 123),

-- Jungle theme (Venomspire Jungle) — 4 cards
('card_toxic_crawler',   'Toxic Crawler',      'A many-legged creature dripping with venom.',              'jungle',   'common',    'mission_speed',   0.003, 'dungeon', 'Venomspire Jungle', 0.12, TRUE, 130),
('card_vine_strangler',  'Vine Strangler',     'Animate vines that constrict prey with crushing force.',   'jungle',   'uncommon',  'flat_defense',    1.0,   'dungeon', 'Venomspire Jungle', 0.10, TRUE, 131),
('card_venomspire_drake','Venomspire Drake',   'A flying serpent that spits corrosive venom.',             'jungle',   'rare',      'loot_chance',     0.004, 'dungeon', 'Venomspire Jungle', 0.08, TRUE, 132),
('card_queen_arachne',   'Queen Arachne',      'The jungle''s apex predator. Absolutely massive.',         'jungle',   'epic',      'dungeon_success', 0.005, 'dungeon', 'Venomspire Jungle', 0.05, TRUE, 133),

-- Crystal theme (Crystal Caverns) — 4 cards
('card_prism_spider',    'Prism Spider',       'Its web refracts light into dazzling traps.',              'crystal',  'common',    'gold_percent',    0.003, 'dungeon', 'Crystal Caverns', 0.12, TRUE, 140),
('card_crystal_golem',   'Crystal Golem',      'A massive construct of living crystal.',                   'crystal',  'uncommon',  'flat_defense',    1.0,   'dungeon', 'Crystal Caverns', 0.10, TRUE, 141),
('card_mana_serpent',    'Mana Serpent',        'A serpent made of pure crystallized magic.',               'crystal',  'rare',      'exp_percent',     0.004, 'dungeon', 'Crystal Caverns', 0.08, TRUE, 142),
('card_heart_crystal',   'Heart Crystal Entity','The living embodiment of the cavern''s magical core.',    'crystal',  'legendary', 'dungeon_success', 0.008, 'dungeon', 'Crystal Caverns', 0.03, TRUE, 143),

-- Storm theme (Stormspire Pinnacle) — 4 cards
('card_storm_hawk',      'Storm Hawk',         'A raptor that rides the lightning.',                        'storm',    'common',    'mission_speed',   0.003, 'dungeon', 'Stormspire Pinnacle', 0.12, TRUE, 150),
('card_thunderbird',     'Thunderbird',        'Its wings crack with static electricity.',                  'storm',    'uncommon',  'exp_percent',     0.003, 'dungeon', 'Stormspire Pinnacle', 0.10, TRUE, 151),
('card_tempest_elemental','Tempest Elemental', 'A being of pure wind and lightning.',                       'storm',    'rare',      'loot_chance',     0.004, 'dungeon', 'Stormspire Pinnacle', 0.08, TRUE, 152),
('card_stormfather',     'The Stormfather',    'Ancient lord of all storms. Few have seen it and lived.',   'storm',    'legendary', 'dungeon_success', 0.008, 'dungeon', 'Stormspire Pinnacle', 0.03, TRUE, 153),

-- Shadow theme (Necropolis) — 4 cards
('card_shadow_rat',      'Shadow Rat',         'A scurrying darkness that steals trinkets.',                'shadow',   'common',    'gold_percent',    0.003, 'dungeon', 'Necropolis of Shadows', 0.12, TRUE, 160),
('card_bone_colossus',   'Bone Colossus',      'Assembled from a thousand skeletal remains.',               'shadow',   'uncommon',  'flat_defense',    2.0,   'dungeon', 'Necropolis of Shadows', 0.10, TRUE, 161),
('card_soul_harvester',  'Soul Harvester',     'It feeds on the essence of the fallen.',                    'shadow',   'rare',      'exp_percent',     0.005, 'dungeon', 'Necropolis of Shadows', 0.08, TRUE, 162),
('card_shadow_lord',     'The Shadow Lord',    'Master of the Necropolis. Darkness incarnate.',              'shadow',   'legendary', 'dungeon_success', 0.008, 'dungeon', 'Necropolis of Shadows', 0.03, TRUE, 163),

-- Celestial theme (Celestial Sanctum) — 4 cards
('card_starling',        'Starling',           'A tiny creature of pure light. Harmless but mesmerizing.',  'celestial','common',    'exp_percent',     0.003, 'dungeon', 'Celestial Sanctum', 0.12, TRUE, 170),
('card_angel_sentinel',  'Angel Sentinel',     'A celestial guardian of unwavering duty.',                  'celestial','uncommon',  'flat_defense',    2.0,   'dungeon', 'Celestial Sanctum', 0.10, TRUE, 171),
('card_seraphim',        'Seraphim',           'A being of pure divine energy and righteous fury.',         'celestial','rare',      'loot_chance',     0.005, 'dungeon', 'Celestial Sanctum', 0.08, TRUE, 172),
('card_celestial_arbiter','The Celestial Arbiter','Judge of all who seek the sanctum. Incorruptible.',      'celestial','legendary', 'dungeon_success', 0.010, 'dungeon', 'Celestial Sanctum', 0.03, TRUE, 173),

-- Arena-exclusive cards (5 cards)
('card_arena_gladiator', 'Arena Gladiator',    'A spectral champion who once ruled the arena.',             'arena',    'uncommon',  'exp_percent',     0.004, 'arena', 'Arena Wave 15', 0.10, TRUE, 200),
('card_pit_champion',    'Pit Champion',       'The undefeated champion of a thousand bouts.',              'arena',    'rare',      'gold_percent',    0.005, 'arena', 'Arena Wave 20', 0.10, TRUE, 201),
('card_war_colossus',    'War Colossus',       'A towering golem built for arena entertainment.',           'arena',    'rare',      'flat_defense',    3.0,   'arena', 'Arena Wave 25', 0.10, TRUE, 202),
('card_eternal_duelist', 'Eternal Duelist',    'An immortal warrior who lives only to fight.',              'arena',    'epic',      'dungeon_success', 0.006, 'arena', 'Arena Wave 30', 0.10, TRUE, 203),
('card_arena_overlord',  'Arena Overlord',     'Master of all arena challenges. Unmatched in combat.',      'arena',    'legendary', 'loot_chance',     0.008, 'arena', 'Arena Wave 50', 0.05, TRUE, 204),

-- Raid boss exclusive cards (8 cards, 1 per boss)
('card_boss_gorrath',    'Gorrath''s Phylactery',   'A fragment of the lich''s soul vessel.',              'shadow',   'epic',      'exp_percent',     0.006, 'raid', 'Gorrath the Undying',     1.00, TRUE, 300),
('card_boss_vexara',     'Vexara''s Crown',         'A crown woven from living thorns.',                   'nature',   'epic',      'mission_speed',   0.006, 'raid', 'Vexara, Queen of Thorns', 1.00, TRUE, 301),
('card_boss_ironclad',   'Ironclad Core',           'The power core of the unstoppable behemoth.',         'iron',     'epic',      'flat_defense',    3.0,   'raid', 'Ironclad Behemoth',       1.00, TRUE, 302),
('card_boss_shadowmaw',  'Shadowmaw''s Fang',       'A tooth that absorbs all light around it.',           'shadow',   'epic',      'loot_chance',     0.006, 'raid', 'Shadowmaw',               1.00, TRUE, 303),
('card_boss_herald',     'Herald''s Banner',         'The crimson banner that rallies demonic armies.',     'fire',     'epic',      'gold_percent',    0.006, 'raid', 'The Crimson Herald',      1.00, TRUE, 304),
('card_boss_frostweaver','Frostweaver''s Scepter',  'A scepter of eternal ice.',                           'ice',      'epic',      'dungeon_success', 0.006, 'raid', 'Frostweaver Empress',     1.00, TRUE, 305),
('card_boss_titan',      'Abyssal Eye',             'A fragment of the titan''s all-seeing gaze.',         'void',     'legendary', 'loot_chance',     0.010, 'raid', 'Abyssal Titan',           1.00, TRUE, 306),
('card_boss_pyrax',      'Pyrax''s Scale',           'A scale that radiates unbearable heat.',             'fire',     'legendary', 'exp_percent',     0.010, 'raid', 'Pyrax the World Burner',  1.00, TRUE, 307)
ON CONFLICT (id) DO NOTHING;


-- =============================================================
-- DONE — Agent 7 content seeded.
-- Verify: SELECT COUNT(*) FROM content_dungeons;  (should be 14 total)
--         SELECT COUNT(*) FROM content_missions;   (should be 17+ total)
--         SELECT COUNT(*) FROM content_raids;      (should be 8)
--         SELECT COUNT(*) FROM content_arena_modifiers; (should be 6)
--         SELECT COUNT(*) FROM content_cards WHERE source_type IN ('dungeon','arena','raid');
-- =============================================================
