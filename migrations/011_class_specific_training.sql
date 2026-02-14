-- =============================================================
-- Class-Specific Training Overhaul
--
-- Training is now class-specific stat exercises instead of
-- generic adventure missions. Each class line has dedicated
-- training that boosts their relevant stats.
-- =============================================================

-- Add new columns to content_missions
ALTER TABLE public.content_missions ADD COLUMN IF NOT EXISTS class_requirement TEXT;
ALTER TABLE public.content_missions ADD COLUMN IF NOT EXISTS training_stat TEXT;

-- Remove ALL old generic missions (both original and agent7 adventure-style)
-- New class-specific training rows use 'train_' prefix
DELETE FROM public.content_missions WHERE id NOT LIKE 'train_%';

-- ===========================
-- WARRIOR LINE TRAINING
-- (Warrior / Berserker / Paladin)
-- ===========================
INSERT INTO public.content_missions (id, name, description, mission_type, rarity, duration_seconds, stat_requirements, level_requirement, base_success_rate, exp_reward, gold_reward, can_drop_equipment, possible_drops, active, sort_order, class_requirement, training_stat) VALUES
('train_warrior_strength',     'Strength Training',    'Lift heavy stones and swing weighted weapons to build raw power.',                        'combat', 'common',   1800,  '[]'::jsonb,                                              1,  0.95, 20,  5,  false, '[]'::jsonb, true, 1,  'warrior', 'Strength'),
('train_warrior_sparring',     'Sparring Practice',    'Trade blows with a training dummy to sharpen your combat instincts.',                    'combat', 'common',   3600,  '[{"stat":"strength","value":6}]'::jsonb,                 3,  0.90, 40,  10, false, '[]'::jsonb, true, 2,  'warrior', 'Strength'),
('train_warrior_shield',       'Shield Wall Drills',   'Practice holding the line against repeated impacts. Your defense will grow.',             'combat', 'uncommon', 7200,  '[{"stat":"defense","value":8}]'::jsonb,                  8,  0.85, 80,  20, false, '[]'::jsonb, true, 3,  'warrior', 'Defense'),
('train_warrior_endurance',    'Endurance March',      'A grueling long-distance march in full armor. Builds both strength and willpower.',       'combat', 'uncommon', 14400, '[{"stat":"strength","value":12}]'::jsonb,                15, 0.80, 150, 40, false, '[]'::jsonb, true, 4,  'warrior', 'Strength'),
('train_warrior_conditioning', 'Battle Conditioning',  'An intense combat regimen that pushes your body to its absolute limit.',                  'combat', 'rare',     28800, '[{"stat":"strength","value":18},{"stat":"defense","value":14}]'::jsonb, 25, 0.70, 300, 80, false, '[]'::jsonb, true, 5, 'warrior', 'Strength')
ON CONFLICT (id) DO NOTHING;

-- ===========================
-- MAGE LINE TRAINING
-- (Mage / Sorcerer / Enchanter)
-- ===========================
INSERT INTO public.content_missions (id, name, description, mission_type, rarity, duration_seconds, stat_requirements, level_requirement, base_success_rate, exp_reward, gold_reward, can_drop_equipment, possible_drops, active, sort_order, class_requirement, training_stat) VALUES
('train_mage_study',        'Study Magic',           'Pore over basic spell tomes to deepen your arcane understanding.',                         'research', 'common',   1800,  '[]'::jsonb,                                                1,  0.95, 20,  5,  false, '[]'::jsonb, true, 10, 'mage', 'Wisdom'),
('train_mage_arcane',       'Arcane Research',       'Study ancient scrolls and practice rune-drawing to refine your magical knowledge.',        'research', 'common',   3600,  '[{"stat":"wisdom","value":6}]'::jsonb,                     3,  0.90, 40,  10, false, '[]'::jsonb, true, 11, 'mage', 'Wisdom'),
('train_mage_enchantment',  'Enchantment Practice',  'Practice weaving enchantments into objects. Strengthens your force of personality.',       'research', 'uncommon', 7200,  '[{"stat":"charisma","value":8}]'::jsonb,                   8,  0.85, 80,  20, false, '[]'::jsonb, true, 12, 'mage', 'Charisma'),
('train_mage_elemental',    'Elemental Attunement',  'Meditate on the primal forces of nature to attune your mind to deeper magic.',             'research', 'uncommon', 14400, '[{"stat":"wisdom","value":12}]'::jsonb,                    15, 0.80, 150, 40, false, '[]'::jsonb, true, 13, 'mage', 'Wisdom'),
('train_mage_deep',         'Deep Meditation',       'Enter a trance-like state of intense focus, pushing the boundaries of your intellect.',    'research', 'rare',     28800, '[{"stat":"wisdom","value":18},{"stat":"charisma","value":14}]'::jsonb, 25, 0.70, 300, 80, false, '[]'::jsonb, true, 14, 'mage', 'Wisdom')
ON CONFLICT (id) DO NOTHING;

-- ===========================
-- ARCHER LINE TRAINING
-- (Archer / Ranger / Trickster)
-- ===========================
INSERT INTO public.content_missions (id, name, description, mission_type, rarity, duration_seconds, stat_requirements, level_requirement, base_success_rate, exp_reward, gold_reward, can_drop_equipment, possible_drops, active, sort_order, class_requirement, training_stat) VALUES
('train_archer_target',     'Target Practice',       'Fire arrows at targets from increasing distances to sharpen your aim.',                    'stealth', 'common',   1800,  '[]'::jsonb,                                                  1,  0.95, 20,  5,  false, '[]'::jsonb, true, 20, 'archer', 'Dexterity'),
('train_archer_agility',    'Agility Drills',        'Sprint, dodge, and roll through an obstacle course to build speed and reflexes.',          'stealth', 'common',   3600,  '[{"stat":"dexterity","value":6}]'::jsonb,                    3,  0.90, 40,  10, false, '[]'::jsonb, true, 21, 'archer', 'Dexterity'),
('train_archer_stealth',    'Stealth Training',      'Move unseen through dense terrain. Sharpens both agility and awareness.',                  'stealth', 'uncommon', 7200,  '[{"stat":"dexterity","value":8}]'::jsonb,                    8,  0.85, 80,  20, false, '[]'::jsonb, true, 22, 'archer', 'Dexterity'),
('train_archer_wilderness', 'Wilderness Survival',   'Spend time in the wild relying on instinct and resourcefulness.',                          'exploration', 'uncommon', 14400, '[{"stat":"luck","value":10}]'::jsonb,                     15, 0.80, 150, 40, false, '[]'::jsonb, true, 23, 'archer', 'Luck'),
('train_archer_precision',  'Precision Focus',       'An exhaustive regimen of trick shots and reaction drills. Only the sharpest survive.',     'stealth', 'rare',     28800, '[{"stat":"dexterity","value":18},{"stat":"luck","value":14}]'::jsonb, 25, 0.70, 300, 80, false, '[]'::jsonb, true, 24, 'archer', 'Dexterity')
ON CONFLICT (id) DO NOTHING;

-- ===========================
-- UNIVERSAL TRAINING (any class)
-- ===========================
INSERT INTO public.content_missions (id, name, description, mission_type, rarity, duration_seconds, stat_requirements, level_requirement, base_success_rate, exp_reward, gold_reward, can_drop_equipment, possible_drops, active, sort_order, class_requirement, training_stat) VALUES
('train_universal_conditioning', 'Basic Conditioning', 'A general fitness routine. Good for any aspiring adventurer.',                           'exploration', 'common',   1800,  '[]'::jsonb, 1, 0.95, 15, 5, false, '[]'::jsonb, true, 50, NULL, 'Dexterity'),
('train_universal_luck',         'Luck Meditation',    'Clear your mind and open yourself to fortune''s favor.',                                 'gathering',   'uncommon', 3600,  '[]'::jsonb, 5, 0.85, 30, 10, false, '[]'::jsonb, true, 51, NULL, 'Luck')
ON CONFLICT (id) DO NOTHING;

-- ===========================
-- RANK-UP TRAINING COURSES
-- (Class evolution trials — level 20+)
-- ===========================
ALTER TABLE public.content_missions ADD COLUMN IF NOT EXISTS is_rank_up_training BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE public.content_missions ADD COLUMN IF NOT EXISTS rank_up_target_class TEXT;

INSERT INTO public.content_missions (id, name, description, mission_type, rarity, duration_seconds, stat_requirements, level_requirement, base_success_rate, exp_reward, gold_reward, can_drop_equipment, possible_drops, active, sort_order, class_requirement, training_stat, is_rank_up_training, rank_up_target_class) VALUES
-- Warrior rank-ups (2 stat checks each)
('rankup_berserker',  'Trial of Fury',         'Channel your rage through a brutal gauntlet. Only those with overwhelming strength and speed may walk the path of the Berserker.',  'combat',   'epic', 14400, '[{"stat":"strength","value":15},{"stat":"dexterity","value":12}]'::jsonb, 20, 0.65, 500, 100, false, '[]'::jsonb, true, 100, 'warrior', 'Strength',  true, 'Berserker'),
('rankup_paladin',    'Trial of the Shield',   'Endure an endless onslaught without breaking. Only those with iron defense and raw power earn the title of Paladin.',                'combat',   'epic', 14400, '[{"stat":"defense","value":15},{"stat":"strength","value":12}]'::jsonb,  20, 0.65, 500, 100, false, '[]'::jsonb, true, 101, 'warrior', 'Defense',   true, 'Paladin'),
-- Mage rank-ups (2 stat checks each)
('rankup_sorcerer',   'Arcane Ascension Trial', 'Unravel the deepest mysteries of arcane power. Only a mind of extraordinary wisdom and fortune''s favor may ascend to Sorcerer.',   'research', 'epic', 14400, '[{"stat":"wisdom","value":15},{"stat":"luck","value":12}]'::jsonb,       20, 0.65, 500, 100, false, '[]'::jsonb, true, 102, 'mage',    'Wisdom',    true, 'Sorcerer'),
('rankup_enchanter',  'Enchanter''s Exam',      'Weave intricate enchantments under immense pressure. Only those with magnetic charisma and deep knowledge become Enchanters.',      'research', 'epic', 14400, '[{"stat":"charisma","value":15},{"stat":"wisdom","value":12}]'::jsonb,   20, 0.65, 500, 100, false, '[]'::jsonb, true, 103, 'mage',    'Charisma',  true, 'Enchanter'),
-- Archer rank-ups (2 stat checks each)
('rankup_ranger',     'Ranger''s Rite',         'Survive alone in the deepest wilderness using only your reflexes and instinct. The ultimate test for a Ranger.',                    'stealth',  'epic', 14400, '[{"stat":"dexterity","value":15},{"stat":"luck","value":12}]'::jsonb,    20, 0.65, 500, 100, false, '[]'::jsonb, true, 104, 'archer',  'Dexterity', true, 'Ranger'),
('rankup_trickster',  'Trickster''s Trial',     'Outsmart a gauntlet of traps and riddles. Only the luckiest and most nimble earn the title of Trickster.',                          'stealth',  'epic', 14400, '[{"stat":"luck","value":15},{"stat":"dexterity","value":12}]'::jsonb,    20, 0.65, 500, 100, false, '[]'::jsonb, true, 105, 'archer',  'Luck',      true, 'Trickster')
ON CONFLICT (id) DO NOTHING;
