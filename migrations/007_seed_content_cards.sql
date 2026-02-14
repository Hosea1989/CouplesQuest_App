-- =============================================================
-- QuestBond Migration 007 — Seed Monster Card Definitions
-- Run this in the Supabase SQL Editor AFTER 005_content_tables.sql
--
-- Seeds ~50 monster cards across dungeon themes, arena, and raid boss.
-- Each card grants a small permanent passive bonus when collected.
-- =============================================================

-- Cave Theme (5 cards)
INSERT INTO public.content_cards (id, name, description, theme, rarity, bonus_type, bonus_value, source_type, source_name, drop_chance, sort_order)
VALUES
  ('card_cave_bat', 'Cave Bat', 'A screeching bat that haunts dark caverns.', 'cave', 'common', 'exp_percent', 0.003, 'dungeon', 'Goblin Caves', 0.12, 1),
  ('card_cave_spider', 'Cave Spider', 'Eight-legged terror lurking in the shadows.', 'cave', 'common', 'gold_percent', 0.003, 'dungeon', 'Goblin Caves', 0.12, 2),
  ('card_cave_goblin', 'Goblin Scout', 'A sneaky goblin always looking for trouble.', 'cave', 'uncommon', 'loot_chance', 0.003, 'dungeon', 'Goblin Caves', 0.10, 3),
  ('card_cave_troll', 'Stone Troll', 'A massive troll that blends with the cavern walls.', 'cave', 'rare', 'dungeon_success', 0.004, 'dungeon', 'Goblin Caves', 0.08, 4),
  ('card_cave_worm', 'Tunnel Worm', 'A burrowing creature that shakes the earth.', 'cave', 'epic', 'flat_defense', 0.8, 'dungeon', 'Goblin Caves', 0.05, 5),

-- Ruins Theme (5 cards)
  ('card_ruins_skeleton', 'Restless Skeleton', 'Bones that refuse to stay buried.', 'ruins', 'common', 'exp_percent', 0.003, 'dungeon', 'Ancient Ruins', 0.12, 10),
  ('card_ruins_specter', 'Fading Specter', 'A ghostly figure drifting through crumbling halls.', 'ruins', 'common', 'gold_percent', 0.003, 'dungeon', 'Ancient Ruins', 0.12, 11),
  ('card_ruins_golem', 'Stone Golem', 'An ancient guardian animated by forgotten magic.', 'ruins', 'uncommon', 'flat_defense', 0.5, 'dungeon', 'Ancient Ruins', 0.10, 12),
  ('card_ruins_wraith', 'Tomb Wraith', 'A vengeful spirit guarding ancient treasure.', 'ruins', 'rare', 'loot_chance', 0.004, 'dungeon', 'Ancient Ruins', 0.08, 13),
  ('card_ruins_lich', 'Ancient Lich', 'A long-dead sorcerer clinging to undeath.', 'ruins', 'epic', 'exp_percent', 0.008, 'dungeon', 'Ancient Ruins', 0.05, 14),

-- Forest Theme (5 cards)
  ('card_forest_wolf', 'Timber Wolf', 'A fierce wolf that hunts in packs.', 'forest', 'common', 'mission_speed', 0.003, 'dungeon', 'Enchanted Forest', 0.12, 20),
  ('card_forest_sprite', 'Forest Sprite', 'A mischievous fairy with a glowing aura.', 'forest', 'common', 'exp_percent', 0.003, 'dungeon', 'Enchanted Forest', 0.12, 21),
  ('card_forest_bear', 'Dire Bear', 'A towering beast defending its territory.', 'forest', 'uncommon', 'flat_defense', 0.5, 'dungeon', 'Enchanted Forest', 0.10, 22),
  ('card_forest_treant', 'Elder Treant', 'An ancient tree awakened to guard the forest.', 'forest', 'rare', 'dungeon_success', 0.004, 'dungeon', 'Enchanted Forest', 0.08, 23),
  ('card_forest_dragon', 'Emerald Wyrmling', 'A young dragon with shimmering green scales.', 'forest', 'epic', 'loot_chance', 0.006, 'dungeon', 'Enchanted Forest', 0.05, 24),

-- Fortress Theme (5 cards)
  ('card_fortress_guard', 'Iron Guard', 'A vigilant sentinel in heavy plate armor.', 'fortress', 'common', 'flat_defense', 0.3, 'dungeon', 'Dark Fortress', 0.12, 30),
  ('card_fortress_archer', 'Tower Archer', 'A sharpshooter posted on the battlements.', 'fortress', 'common', 'gold_percent', 0.003, 'dungeon', 'Dark Fortress', 0.12, 31),
  ('card_fortress_knight', 'Fallen Knight', 'A cursed warrior bound to serve eternally.', 'fortress', 'uncommon', 'exp_percent', 0.005, 'dungeon', 'Dark Fortress', 0.10, 32),
  ('card_fortress_warden', 'Dungeon Warden', 'A cruel jailer with keys to every cell.', 'fortress', 'rare', 'gold_percent', 0.005, 'dungeon', 'Dark Fortress', 0.08, 33),
  ('card_fortress_general', 'Dark General', 'The ruthless commander of the fortress army.', 'fortress', 'epic', 'dungeon_success', 0.005, 'dungeon', 'Dark Fortress', 0.05, 34),

-- Volcano Theme (5 cards)
  ('card_volcano_imp', 'Magma Imp', 'A small fiend born from molten rock.', 'volcano', 'common', 'exp_percent', 0.003, 'dungeon', 'Molten Core', 0.12, 40),
  ('card_volcano_salamander', 'Fire Salamander', 'A lizard that bathes in lava.', 'volcano', 'common', 'mission_speed', 0.003, 'dungeon', 'Molten Core', 0.12, 41),
  ('card_volcano_elemental', 'Lava Elemental', 'A living mass of molten stone.', 'volcano', 'uncommon', 'flat_defense', 0.6, 'dungeon', 'Molten Core', 0.10, 42),
  ('card_volcano_phoenix', 'Ember Phoenix', 'A bird of fire that rises from its ashes.', 'volcano', 'rare', 'exp_percent', 0.006, 'dungeon', 'Molten Core', 0.08, 43),
  ('card_volcano_titan', 'Volcanic Titan', 'An ancient giant wreathed in flame.', 'volcano', 'epic', 'loot_chance', 0.006, 'dungeon', 'Molten Core', 0.05, 44),

-- Abyss Theme (5 cards)
  ('card_abyss_shadow', 'Shadow Lurker', 'A creature that thrives in absolute darkness.', 'abyss', 'common', 'gold_percent', 0.003, 'dungeon', 'The Abyss', 0.12, 50),
  ('card_abyss_horror', 'Void Horror', 'A writhing mass of tentacles and eyes.', 'abyss', 'uncommon', 'exp_percent', 0.005, 'dungeon', 'The Abyss', 0.10, 51),
  ('card_abyss_demon', 'Abyssal Demon', 'A fiend summoned from the deepest darkness.', 'abyss', 'rare', 'dungeon_success', 0.005, 'dungeon', 'The Abyss', 0.08, 52),
  ('card_abyss_overlord', 'Void Overlord', 'The terrifying ruler of the abyss.', 'abyss', 'epic', 'flat_defense', 1.0, 'dungeon', 'The Abyss', 0.05, 53),
  ('card_abyss_devourer', 'Soul Devourer', 'It feeds on the essence of fallen heroes.', 'abyss', 'legendary', 'exp_percent', 0.010, 'dungeon', 'The Abyss', 0.02, 54),

-- Arena Cards (8 cards — drop at milestone waves)
  ('card_arena_gladiator', 'Arena Gladiator', 'A champion of the colosseum who never yields.', 'arena', 'uncommon', 'exp_percent', 0.004, 'arena', 'Arena Wave 15', 0.20, 60),
  ('card_arena_berserker', 'Frenzied Berserker', 'Fury made flesh, unstoppable in combat.', 'arena', 'uncommon', 'gold_percent', 0.004, 'arena', 'Arena Wave 15', 0.20, 61),
  ('card_arena_duelist', 'Master Duelist', 'Every strike is precise and deadly.', 'arena', 'rare', 'loot_chance', 0.004, 'arena', 'Arena Wave 25', 0.20, 62),
  ('card_arena_champion', 'Arena Champion', 'The undisputed king of the arena.', 'arena', 'rare', 'dungeon_success', 0.004, 'arena', 'Arena Wave 25', 0.20, 63),
  ('card_arena_warlord', 'Warlord', 'A battle-hardened leader who inspires allies.', 'arena', 'epic', 'exp_percent', 0.007, 'arena', 'Arena Wave 35', 0.20, 64),
  ('card_arena_colossus', 'Iron Colossus', 'A towering construct of enchanted metal.', 'arena', 'epic', 'flat_defense', 0.8, 'arena', 'Arena Wave 35', 0.20, 65),
  ('card_arena_reaper', 'Silent Reaper', 'Death walks the arena floor.', 'arena', 'epic', 'gold_percent', 0.007, 'arena', 'Arena Wave 45', 0.20, 66),
  ('card_arena_titan', 'Arena Titan', 'The ultimate warrior — none can stand against it.', 'arena', 'legendary', 'loot_chance', 0.005, 'arena', 'Arena Wave 50', 0.20, 67),

-- Raid Boss Cards (7 cards — guaranteed on boss defeat)
  ('card_raid_dragon_king', 'Dragon King', 'The mightiest dragon of the realm.', 'raid', 'epic', 'exp_percent', 0.008, 'raid', 'Raid Boss: Dragon King', 1.00, 70),
  ('card_raid_kraken', 'Abyssal Kraken', 'A sea monster of legendary proportions.', 'raid', 'epic', 'gold_percent', 0.008, 'raid', 'Raid Boss: Abyssal Kraken', 1.00, 71),
  ('card_raid_lich_lord', 'Lich Lord Malachar', 'The undying sorcerer who commands the dead.', 'raid', 'epic', 'dungeon_success', 0.005, 'raid', 'Raid Boss: Lich Lord', 1.00, 72),
  ('card_raid_behemoth', 'World Behemoth', 'A creature so large it shapes the landscape.', 'raid', 'legendary', 'flat_defense', 1.0, 'raid', 'Raid Boss: World Behemoth', 1.00, 73),
  ('card_raid_phoenix_lord', 'Phoenix Lord', 'An immortal bird of cosmic fire.', 'raid', 'legendary', 'exp_percent', 0.010, 'raid', 'Raid Boss: Phoenix Lord', 1.00, 74),
  ('card_raid_shadow_king', 'Shadow King', 'The dark sovereign who rules from the void.', 'raid', 'legendary', 'loot_chance', 0.005, 'raid', 'Raid Boss: Shadow King', 1.00, 75),
  ('card_raid_titan_forge', 'Titan of the Forge', 'An ancient being that forged the first weapons.', 'raid', 'legendary', 'mission_speed', 0.005, 'raid', 'Raid Boss: Titan of the Forge', 1.00, 76)

ON CONFLICT (id) DO NOTHING;

-- Also seed collection milestones if not already present
INSERT INTO public.content_collection_milestones (id, collection_type, threshold, reward_type, reward_bonus_type, reward_bonus_value, reward_title, reward_equipment_id, description, active)
VALUES
  ('milestone_cards_10', 'cards', 10, 'bonus', 'exp_percent', 0.02, NULL, NULL, '+2% EXP from all sources (permanent)', TRUE),
  ('milestone_cards_25', 'cards', 25, 'bonus', 'gold_percent', 0.02, NULL, NULL, '+2% Gold from all sources (permanent)', TRUE),
  ('milestone_cards_50', 'cards', 50, 'bonus', 'loot_chance', 0.03, NULL, NULL, '+3% loot drop chance (permanent)', TRUE),
  ('milestone_cards_75', 'cards', 75, 'bonus', 'dungeon_success', 0.03, NULL, NULL, '+3% dungeon success (permanent)', TRUE),
  ('milestone_cards_100', 'cards', 100, 'title', NULL, NULL, 'Monster Scholar', NULL, 'Title: "Monster Scholar" + unique equipment piece', TRUE)
ON CONFLICT (id) DO NOTHING;

-- Bump content version so apps re-fetch
UPDATE public.content_version
SET version = version + 1, notes = 'Added ~50 monster cards + collection milestones', updated_at = NOW()
WHERE id = 'current';
