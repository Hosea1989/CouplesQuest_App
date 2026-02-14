-- =============================================================
-- QuestBond Migration 005 — Server-Driven Content Tables
-- Run this in the Supabase SQL Editor.
--
-- These tables hold GAME CONTENT definitions (equipment catalog,
-- dungeon templates, cards, missions, affixes, forge recipes,
-- drop rates, expeditions, consumable definitions, gear sets,
-- duty board templates, and narrative text).
--
-- Content tables are PUBLIC READ (no RLS) because they define
-- the game world, not user data. Only service_role can write.
--
-- A content_version row lets the app check for updates with
-- a single lightweight query instead of re-fetching everything.
-- =============================================================


-- -----------------------------------------------------------
-- CONTENT VERSION — single-row table for cache invalidation
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.content_version (
    id          TEXT PRIMARY KEY DEFAULT 'current',
    version     INT NOT NULL DEFAULT 1,
    notes       TEXT,                           -- e.g. "Added 5 new dungeon cards"
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Seed the initial version row
INSERT INTO public.content_version (id, version, notes)
VALUES ('current', 1, 'Initial content load')
ON CONFLICT (id) DO NOTHING;

-- Helper: bump version automatically when any content table changes
CREATE OR REPLACE FUNCTION public.bump_content_version()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.content_version
    SET version = version + 1, updated_at = NOW()
    WHERE id = 'current';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- -----------------------------------------------------------
-- EQUIPMENT CATALOG (replaces EquipmentCatalog.swift)
-- 110+ curated equipment templates
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.content_equipment (
    id                      TEXT PRIMARY KEY,       -- e.g. "sword_common_01"
    name                    TEXT NOT NULL,
    description             TEXT NOT NULL DEFAULT '',
    slot                    TEXT NOT NULL CHECK (slot IN ('weapon', 'armor', 'accessory', 'trinket')),
    base_type               TEXT NOT NULL,           -- e.g. "sword", "axe", "plate", "ring", "cloak"
    rarity                  TEXT NOT NULL CHECK (rarity IN ('common', 'uncommon', 'rare', 'epic', 'legendary')),
    primary_stat            TEXT NOT NULL CHECK (primary_stat IN ('strength', 'wisdom', 'charisma', 'dexterity', 'luck', 'defense')),
    stat_bonus              INT NOT NULL DEFAULT 0,
    secondary_stat          TEXT CHECK (secondary_stat IN ('strength', 'wisdom', 'charisma', 'dexterity', 'luck', 'defense')),
    secondary_stat_bonus    INT NOT NULL DEFAULT 0,
    level_requirement       INT NOT NULL DEFAULT 1,
    image_name              TEXT,                    -- asset catalog reference
    is_set_piece            BOOLEAN NOT NULL DEFAULT FALSE,
    set_id                  TEXT,                    -- FK to content_gear_sets.id
    active                  BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order              INT NOT NULL DEFAULT 0,
    created_at              TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_content_equipment_slot ON public.content_equipment(slot);
CREATE INDEX IF NOT EXISTS idx_content_equipment_rarity ON public.content_equipment(rarity);
CREATE INDEX IF NOT EXISTS idx_content_equipment_active ON public.content_equipment(active) WHERE active = TRUE;

-- Public read, service_role write
ALTER TABLE public.content_equipment ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read content equipment"
    ON public.content_equipment FOR SELECT
    USING (TRUE);

-- Auto-bump version on changes
CREATE TRIGGER bump_version_on_equipment
    AFTER INSERT OR UPDATE OR DELETE ON public.content_equipment
    FOR EACH STATEMENT EXECUTE FUNCTION public.bump_content_version();


-- -----------------------------------------------------------
-- MILESTONE GEAR (replaces MilestoneGearCatalog.swift)
-- Class-specific equipment unlocked at level milestones
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.content_milestone_gear (
    id                      TEXT PRIMARY KEY,       -- e.g. "warrior_lv5_sword"
    name                    TEXT NOT NULL,
    description             TEXT NOT NULL DEFAULT '',
    slot                    TEXT NOT NULL CHECK (slot IN ('weapon', 'armor', 'accessory', 'trinket')),
    base_type               TEXT NOT NULL,
    rarity                  TEXT NOT NULL CHECK (rarity IN ('common', 'uncommon', 'rare', 'epic', 'legendary')),
    primary_stat            TEXT NOT NULL CHECK (primary_stat IN ('strength', 'wisdom', 'charisma', 'dexterity', 'luck', 'defense')),
    stat_bonus              INT NOT NULL DEFAULT 0,
    secondary_stat          TEXT CHECK (secondary_stat IN ('strength', 'wisdom', 'charisma', 'dexterity', 'luck', 'defense')),
    secondary_stat_bonus    INT NOT NULL DEFAULT 0,
    level_requirement       INT NOT NULL,
    character_class         TEXT NOT NULL,           -- e.g. "warrior", "mage", "berserker"
    gold_cost               INT NOT NULL DEFAULT 0,
    image_name              TEXT,
    active                  BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order              INT NOT NULL DEFAULT 0,
    created_at              TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_content_milestone_class ON public.content_milestone_gear(character_class);

ALTER TABLE public.content_milestone_gear ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read milestone gear"
    ON public.content_milestone_gear FOR SELECT
    USING (TRUE);

CREATE TRIGGER bump_version_on_milestone_gear
    AFTER INSERT OR UPDATE OR DELETE ON public.content_milestone_gear
    FOR EACH STATEMENT EXECUTE FUNCTION public.bump_content_version();


-- -----------------------------------------------------------
-- GEAR SETS (replaces GearSetCatalog.swift)
-- Set definitions with 2-piece activation bonuses
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.content_gear_sets (
    id                      TEXT PRIMARY KEY,       -- e.g. "vanguards_resolve"
    name                    TEXT NOT NULL,
    description             TEXT NOT NULL DEFAULT '',
    character_class_line    TEXT NOT NULL,           -- e.g. "warrior" (covers warrior/berserker/paladin)
    pieces_required         INT NOT NULL DEFAULT 2,
    bonus_stat              TEXT NOT NULL CHECK (bonus_stat IN ('strength', 'wisdom', 'charisma', 'dexterity', 'luck', 'defense')),
    bonus_amount            INT NOT NULL DEFAULT 0,
    bonus_description       TEXT NOT NULL DEFAULT '',  -- e.g. "+10% Defense in dungeons"
    bonus_type              TEXT NOT NULL DEFAULT 'flat', -- 'flat', 'percent', 'dungeon_only', 'mission_only', 'loot_chance'
    bonus_value             DOUBLE PRECISION NOT NULL DEFAULT 0.0, -- for percentage-based bonuses
    level_requirement       INT NOT NULL DEFAULT 1,
    active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at              TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.content_gear_sets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read gear sets"
    ON public.content_gear_sets FOR SELECT
    USING (TRUE);

CREATE TRIGGER bump_version_on_gear_sets
    AFTER INSERT OR UPDATE OR DELETE ON public.content_gear_sets
    FOR EACH STATEMENT EXECUTE FUNCTION public.bump_content_version();


-- -----------------------------------------------------------
-- MONSTER CARDS (new — card collection definitions)
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.content_cards (
    id                      TEXT PRIMARY KEY,       -- e.g. "card_shadow_lurker"
    name                    TEXT NOT NULL,
    description             TEXT NOT NULL DEFAULT '',
    theme                   TEXT NOT NULL,           -- dungeon theme: "shadow", "crystal", "forest", etc.
    rarity                  TEXT NOT NULL CHECK (rarity IN ('common', 'uncommon', 'rare', 'epic', 'legendary')),
    bonus_type              TEXT NOT NULL CHECK (bonus_type IN (
        'exp_percent', 'gold_percent', 'dungeon_success',
        'loot_chance', 'mission_speed', 'flat_defense'
    )),
    bonus_value             DOUBLE PRECISION NOT NULL,  -- e.g. 0.005 for +0.5%
    source_type             TEXT NOT NULL CHECK (source_type IN ('dungeon', 'arena', 'expedition', 'raid')),
    source_name             TEXT NOT NULL DEFAULT '',    -- e.g. "Goblin Caves", "Arena Wave 15"
    drop_chance             DOUBLE PRECISION NOT NULL DEFAULT 0.10, -- base drop chance
    image_name              TEXT,
    active                  BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order              INT NOT NULL DEFAULT 0,
    created_at              TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_content_cards_theme ON public.content_cards(theme);
CREATE INDEX IF NOT EXISTS idx_content_cards_source ON public.content_cards(source_type);
CREATE INDEX IF NOT EXISTS idx_content_cards_active ON public.content_cards(active) WHERE active = TRUE;

ALTER TABLE public.content_cards ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read content cards"
    ON public.content_cards FOR SELECT
    USING (TRUE);

CREATE TRIGGER bump_version_on_cards
    AFTER INSERT OR UPDATE OR DELETE ON public.content_cards
    FOR EACH STATEMENT EXECUTE FUNCTION public.bump_content_version();


-- -----------------------------------------------------------
-- DUNGEON TEMPLATES (replaces static dungeons in Dungeon.swift)
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.content_dungeons (
    id                      TEXT PRIMARY KEY,       -- e.g. "goblin_caves"
    name                    TEXT NOT NULL,
    description             TEXT NOT NULL DEFAULT '',
    theme                   TEXT NOT NULL,           -- "goblin", "shadow", "crystal", "iron", "dragon", "abyss"
    difficulty              TEXT NOT NULL CHECK (difficulty IN ('normal', 'hard', 'heroic', 'mythic')),
    level_requirement       INT NOT NULL DEFAULT 1,
    recommended_stat_total  INT NOT NULL DEFAULT 0,
    max_party_size          INT NOT NULL DEFAULT 4,
    base_exp_reward         INT NOT NULL DEFAULT 0,
    base_gold_reward        INT NOT NULL DEFAULT 0,
    loot_tier               INT NOT NULL DEFAULT 1,
    rooms                   JSONB NOT NULL DEFAULT '[]',
    -- rooms is an array of objects:
    -- [
    --   {
    --     "name": "Entrance Hall",
    --     "description": "A dimly lit corridor...",
    --     "encounter_type": "combat",       -- combat, puzzle, trap, treasure, boss
    --     "primary_stat": "strength",
    --     "difficulty_rating": 3,
    --     "is_boss_room": false,
    --     "bonus_loot_chance": 0.0
    --   }
    -- ]
    is_party_only           BOOLEAN NOT NULL DEFAULT FALSE,
    party_bond_level_req    INT NOT NULL DEFAULT 0,    -- min bond level for party dungeons
    active                  BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order              INT NOT NULL DEFAULT 0,
    created_at              TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_content_dungeons_difficulty ON public.content_dungeons(difficulty);
CREATE INDEX IF NOT EXISTS idx_content_dungeons_active ON public.content_dungeons(active) WHERE active = TRUE;

ALTER TABLE public.content_dungeons ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read content dungeons"
    ON public.content_dungeons FOR SELECT
    USING (TRUE);

CREATE TRIGGER bump_version_on_dungeons
    AFTER INSERT OR UPDATE OR DELETE ON public.content_dungeons
    FOR EACH STATEMENT EXECUTE FUNCTION public.bump_content_version();


-- -----------------------------------------------------------
-- AFK MISSION TEMPLATES (replaces static missions)
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.content_missions (
    id                      TEXT PRIMARY KEY,       -- e.g. "forest_patrol"
    name                    TEXT NOT NULL,
    description             TEXT NOT NULL DEFAULT '',
    mission_type            TEXT NOT NULL CHECK (mission_type IN (
        'combat', 'exploration', 'research', 'negotiation', 'stealth', 'gathering'
    )),
    rarity                  TEXT NOT NULL CHECK (rarity IN ('common', 'uncommon', 'rare', 'epic', 'legendary')),
    duration_seconds        INT NOT NULL,
    stat_requirements       JSONB NOT NULL DEFAULT '[]',
    -- [{"stat": "strength", "value": 10}, {"stat": "dexterity", "value": 5}]
    level_requirement       INT NOT NULL DEFAULT 1,
    base_success_rate       DOUBLE PRECISION NOT NULL DEFAULT 0.5,
    exp_reward              INT NOT NULL DEFAULT 0,
    gold_reward             INT NOT NULL DEFAULT 0,
    can_drop_equipment      BOOLEAN NOT NULL DEFAULT FALSE,
    possible_drops          JSONB NOT NULL DEFAULT '[]',
    -- [{"type": "material", "material_type": "Herb", "rarity": "Common", "quantity_min": 1, "quantity_max": 3}]
    active                  BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order              INT NOT NULL DEFAULT 0,
    created_at              TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.content_missions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read content missions"
    ON public.content_missions FOR SELECT
    USING (TRUE);

CREATE TRIGGER bump_version_on_missions
    AFTER INSERT OR UPDATE OR DELETE ON public.content_missions
    FOR EACH STATEMENT EXECUTE FUNCTION public.bump_content_version();


-- -----------------------------------------------------------
-- EXPEDITION TEMPLATES (new content type)
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.content_expeditions (
    id                      TEXT PRIMARY KEY,       -- e.g. "ancient_ruins_exp"
    name                    TEXT NOT NULL,
    description             TEXT NOT NULL DEFAULT '',
    theme                   TEXT NOT NULL,           -- "ruins", "wilderness", "ocean", "mountains", "underworld"
    total_duration_seconds  INT NOT NULL,
    level_requirement       INT NOT NULL DEFAULT 1,
    stat_requirements       JSONB NOT NULL DEFAULT '[]',
    is_party_expedition     BOOLEAN NOT NULL DEFAULT FALSE,
    stages                  JSONB NOT NULL DEFAULT '[]',
    -- [
    --   {
    --     "name": "Entrance",
    --     "narrative_text": "Your party enters the ancient ruins...",
    --     "duration_seconds": 3600,
    --     "primary_stat": "wisdom",
    --     "difficulty_rating": 3,
    --     "possible_rewards": {
    --       "exp": 50,
    --       "gold": 30,
    --       "equipment_chance": 0.20,
    --       "material_chance": 0.50,
    --       "card_chance": 0.15
    --     }
    --   }
    -- ]
    exclusive_loot_ids      JSONB NOT NULL DEFAULT '[]',  -- content_equipment IDs only from this expedition
    active                  BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order              INT NOT NULL DEFAULT 0,
    created_at              TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.content_expeditions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read content expeditions"
    ON public.content_expeditions FOR SELECT
    USING (TRUE);

CREATE TRIGGER bump_version_on_expeditions
    AFTER INSERT OR UPDATE OR DELETE ON public.content_expeditions
    FOR EACH STATEMENT EXECUTE FUNCTION public.bump_content_version();


-- -----------------------------------------------------------
-- AFFIX POOL (new — prefix/suffix definitions for equipment)
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.content_affixes (
    id                      TEXT PRIMARY KEY,       -- e.g. "prefix_blazing"
    name                    TEXT NOT NULL,           -- "Blazing"
    affix_type              TEXT NOT NULL CHECK (affix_type IN ('prefix', 'suffix')),
    effect_description      TEXT NOT NULL DEFAULT '',  -- "+X% EXP from physical tasks"
    bonus_type              TEXT NOT NULL,           -- what game stat/mechanic it modifies
    min_value               DOUBLE PRECISION NOT NULL DEFAULT 0.0,  -- value at lowest roll
    max_value               DOUBLE PRECISION NOT NULL DEFAULT 0.0,  -- value at highest roll
    -- Value scales with item rarity and level_requirement
    min_item_rarity         TEXT NOT NULL DEFAULT 'uncommon' CHECK (min_item_rarity IN ('common', 'uncommon', 'rare', 'epic', 'legendary')),
    category                TEXT NOT NULL DEFAULT 'general', -- "task_specific", "idle_bonus", "economy", "combat", "meta_loot", "social", "protection"
    active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at              TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.content_affixes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read content affixes"
    ON public.content_affixes FOR SELECT
    USING (TRUE);

CREATE TRIGGER bump_version_on_affixes
    AFTER INSERT OR UPDATE OR DELETE ON public.content_affixes
    FOR EACH STATEMENT EXECUTE FUNCTION public.bump_content_version();


-- -----------------------------------------------------------
-- CONSUMABLE DEFINITIONS (replaces ConsumableCatalog)
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.content_consumables (
    id                      TEXT PRIMARY KEY,       -- e.g. "minor_hp_potion"
    name                    TEXT NOT NULL,
    description             TEXT NOT NULL DEFAULT '',
    consumable_type         TEXT NOT NULL,           -- "hp_potion", "exp_boost", "gold_boost", etc.
    icon                    TEXT NOT NULL DEFAULT 'cross.vial.fill',
    effect_value            INT NOT NULL DEFAULT 0,
    effect_stat             TEXT CHECK (effect_stat IN ('strength', 'wisdom', 'charisma', 'dexterity', 'luck', 'defense')),
    duration_seconds        INT,                     -- null = instant, otherwise buff duration
    gold_cost               INT NOT NULL DEFAULT 0,
    gem_cost                INT NOT NULL DEFAULT 0,
    level_requirement       INT NOT NULL DEFAULT 1,
    tier                    TEXT NOT NULL DEFAULT 'common' CHECK (tier IN ('common', 'uncommon', 'rare', 'expedition')),
    is_premium              BOOLEAN NOT NULL DEFAULT FALSE,
    max_stack               INT NOT NULL DEFAULT 99,
    active                  BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order              INT NOT NULL DEFAULT 0,
    created_at              TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.content_consumables ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read content consumables"
    ON public.content_consumables FOR SELECT
    USING (TRUE);

CREATE TRIGGER bump_version_on_consumables
    AFTER INSERT OR UPDATE OR DELETE ON public.content_consumables
    FOR EACH STATEMENT EXECUTE FUNCTION public.bump_content_version();


-- -----------------------------------------------------------
-- FORGE RECIPES (replaces ForgeRecipe struct)
-- 4 stations: craft, enhance rules, salvage rules, affix ops
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.content_forge_recipes (
    id                      TEXT PRIMARY KEY,       -- e.g. "craft_tier1_weapon"
    name                    TEXT NOT NULL,
    recipe_type             TEXT NOT NULL CHECK (recipe_type IN ('craft', 'consumable_craft')),
    tier                    INT NOT NULL CHECK (tier BETWEEN 1 AND 5),
    target_slot             TEXT,                    -- null = any slot; "weapon", "armor", etc.
    -- Material costs
    essence_cost            INT NOT NULL DEFAULT 0,
    material_cost           INT NOT NULL DEFAULT 0,  -- general materials (ore/crystal/hide)
    material_min_rarity     TEXT NOT NULL DEFAULT 'common' CHECK (material_min_rarity IN ('common', 'uncommon', 'rare', 'epic', 'legendary')),
    fragment_cost           INT NOT NULL DEFAULT 0,
    herb_cost               INT NOT NULL DEFAULT 0,  -- for consumable crafting
    gold_cost               INT NOT NULL DEFAULT 0,
    gem_cost                INT NOT NULL DEFAULT 0,  -- premium alternative
    -- Output
    output_rarity_min       TEXT NOT NULL DEFAULT 'common' CHECK (output_rarity_min IN ('common', 'uncommon', 'rare', 'epic', 'legendary')),
    output_rarity_max       TEXT NOT NULL DEFAULT 'uncommon' CHECK (output_rarity_max IN ('common', 'uncommon', 'rare', 'epic', 'legendary')),
    output_consumable_id    TEXT,                    -- for consumable_craft recipes, FK to content_consumables.id
    guaranteed_affix_count  INT NOT NULL DEFAULT 0,  -- 0 = no guarantee, 1+ = guaranteed affixes
    description             TEXT NOT NULL DEFAULT '',
    -- Seasonal / event gating
    is_seasonal             BOOLEAN NOT NULL DEFAULT FALSE,
    available_from          TIMESTAMPTZ,             -- null = always available
    available_until         TIMESTAMPTZ,             -- null = never expires
    active                  BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order              INT NOT NULL DEFAULT 0,
    created_at              TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.content_forge_recipes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read forge recipes"
    ON public.content_forge_recipes FOR SELECT
    USING (TRUE);

CREATE TRIGGER bump_version_on_forge_recipes
    AFTER INSERT OR UPDATE OR DELETE ON public.content_forge_recipes
    FOR EACH STATEMENT EXECUTE FUNCTION public.bump_content_version();


-- -----------------------------------------------------------
-- ENHANCEMENT RULES (server-tunable enhancement tiers)
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.content_enhancement_rules (
    id                      TEXT PRIMARY KEY,       -- e.g. "enhance_1", "enhance_10"
    enhancement_level       INT NOT NULL UNIQUE,     -- +1 through +10
    success_rate            DOUBLE PRECISION NOT NULL, -- 1.0 = 100%, 0.25 = 25%
    cost_multiplier         DOUBLE PRECISION NOT NULL, -- multiplied by base rarity cost
    stat_gain               INT NOT NULL DEFAULT 1,    -- primary stat gained on success
    critical_chance         DOUBLE PRECISION NOT NULL DEFAULT 0.10, -- chance for double stat gain
    active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at              TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.content_enhancement_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read enhancement rules"
    ON public.content_enhancement_rules FOR SELECT
    USING (TRUE);

CREATE TRIGGER bump_version_on_enhancement_rules
    AFTER INSERT OR UPDATE OR DELETE ON public.content_enhancement_rules
    FOR EACH STATEMENT EXECUTE FUNCTION public.bump_content_version();

-- Seed default enhancement rules
INSERT INTO public.content_enhancement_rules (id, enhancement_level, success_rate, cost_multiplier, stat_gain, critical_chance) VALUES
    ('enhance_1',   1,  1.00,  1.0,  1, 0.10),
    ('enhance_2',   2,  1.00,  1.5,  1, 0.10),
    ('enhance_3',   3,  1.00,  2.0,  1, 0.10),
    ('enhance_4',   4,  0.80,  3.0,  1, 0.10),
    ('enhance_5',   5,  0.80,  4.0,  1, 0.10),
    ('enhance_6',   6,  0.80,  5.0,  1, 0.10),
    ('enhance_7',   7,  0.60,  8.0,  2, 0.10),
    ('enhance_8',   8,  0.60, 12.0,  2, 0.10),
    ('enhance_9',   9,  0.40, 20.0,  2, 0.10),
    ('enhance_10', 10,  0.25, 40.0,  3, 0.10)
ON CONFLICT (id) DO NOTHING;


-- -----------------------------------------------------------
-- SALVAGE RULES (what you get back per rarity)
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.content_salvage_rules (
    id                      TEXT PRIMARY KEY,       -- e.g. "salvage_common"
    item_rarity             TEXT NOT NULL UNIQUE CHECK (item_rarity IN ('common', 'uncommon', 'rare', 'epic', 'legendary')),
    materials_returned      INT NOT NULL DEFAULT 1,
    fragments_returned      INT NOT NULL DEFAULT 0,
    gold_returned           INT NOT NULL DEFAULT 0,
    affix_recovery_chance   DOUBLE PRECISION NOT NULL DEFAULT 0.0,  -- chance to get Affix Scroll
    active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at              TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.content_salvage_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read salvage rules"
    ON public.content_salvage_rules FOR SELECT
    USING (TRUE);

CREATE TRIGGER bump_version_on_salvage_rules
    AFTER INSERT OR UPDATE OR DELETE ON public.content_salvage_rules
    FOR EACH STATEMENT EXECUTE FUNCTION public.bump_content_version();

-- Seed default salvage rules
INSERT INTO public.content_salvage_rules (id, item_rarity, materials_returned, fragments_returned, gold_returned, affix_recovery_chance) VALUES
    ('salvage_common',    'common',    0, 1,   5,  0.00),
    ('salvage_uncommon',  'uncommon',  2, 0,  15,  0.10),
    ('salvage_rare',      'rare',      3, 1,  40,  0.20),
    ('salvage_epic',      'epic',      5, 2, 100,  0.30),
    ('salvage_legendary', 'legendary', 8, 4, 250,  0.50)
ON CONFLICT (id) DO NOTHING;


-- -----------------------------------------------------------
-- DROP RATE CONFIGURATION (live-tunable)
-- The single most important table for balance tuning.
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.content_drop_rates (
    id                      TEXT PRIMARY KEY,       -- e.g. "task_equipment"
    content_source          TEXT NOT NULL,           -- "task", "dungeon", "mission", "expedition", "raid", "arena", "level_up"
    drop_type               TEXT NOT NULL,           -- "equipment", "material", "consumable", "card", "key"
    base_chance             DOUBLE PRECISION NOT NULL, -- 0.08 = 8%
    rarity_weights          JSONB NOT NULL DEFAULT '{}',
    -- {"common": 0.50, "uncommon": 0.30, "rare": 0.15, "epic": 0.04, "legendary": 0.01}
    luck_scaling            DOUBLE PRECISION NOT NULL DEFAULT 0.002, -- per luck point bonus
    pity_threshold          INT,                     -- guaranteed drop after N dry runs (null = no pity)
    pity_min_rarity         TEXT,                    -- min rarity of pity drop
    notes                   TEXT,
    active                  BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at              TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.content_drop_rates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read drop rates"
    ON public.content_drop_rates FOR SELECT
    USING (TRUE);

CREATE TRIGGER bump_version_on_drop_rates
    AFTER INSERT OR UPDATE OR DELETE ON public.content_drop_rates
    FOR EACH STATEMENT EXECUTE FUNCTION public.bump_content_version();

-- Seed default drop rates (from GAME_DESIGN.md)
INSERT INTO public.content_drop_rates (id, content_source, drop_type, base_chance, rarity_weights, pity_threshold, pity_min_rarity, notes) VALUES
    ('task_equipment',     'task',       'equipment',  0.07,  '{"common":0.55,"uncommon":0.30,"rare":0.12,"epic":0.03,"legendary":0.00}', 20, 'uncommon', 'Low chance but frequent source'),
    ('task_material',      'task',       'material',   0.35,  '{"common":0.60,"uncommon":0.30,"rare":0.10}', NULL, NULL, 'Primary material source'),
    ('task_consumable',    'task',       'consumable',  0.18,  '{}', NULL, NULL, 'Common consumables only'),
    ('dungeon_equipment',  'dungeon',    'equipment',  0.30,  '{"common":0.35,"uncommon":0.30,"rare":0.20,"epic":0.12,"legendary":0.03}', 12, 'rare', 'Scales with dungeon tier'),
    ('dungeon_material',   'dungeon',    'material',   0.60,  '{"common":0.30,"uncommon":0.35,"rare":0.25,"epic":0.10}', NULL, NULL, NULL),
    ('dungeon_card',       'dungeon',    'card',       0.12,  '{"common":0.50,"uncommon":0.30,"rare":0.15,"epic":0.05}', NULL, NULL, '10-15% per room'),
    ('mission_equipment',  'mission',    'equipment',  0.15,  '{"rare":0.60,"epic":0.30,"legendary":0.10}', 5, 'rare', 'AFK-only rare pool'),
    ('mission_material',   'mission',    'material',   0.40,  '{"common":0.40,"uncommon":0.40,"rare":0.20}', NULL, NULL, NULL),
    ('expedition_equip',   'expedition', 'equipment',  0.25,  '{"rare":0.40,"epic":0.40,"legendary":0.20}', 3, 'epic', 'Expedition-exclusive table'),
    ('expedition_material','expedition', 'material',   0.50,  '{"uncommon":0.30,"rare":0.40,"epic":0.30}', NULL, NULL, 'Higher tier materials'),
    ('expedition_card',    'expedition', 'card',       0.18,  '{"rare":0.50,"epic":0.35,"legendary":0.15}', NULL, NULL, '15-20% per stage'),
    ('raid_equipment',     'raid',       'equipment',  1.00,  '{"epic":0.60,"legendary":0.40}', NULL, NULL, 'Guaranteed drop'),
    ('raid_card',          'raid',       'card',       1.00,  '{"epic":0.60,"legendary":0.40}', NULL, NULL, 'Guaranteed card'),
    ('raid_material',      'raid',       'material',   0.80,  '{"rare":0.40,"epic":0.40,"legendary":0.20}', NULL, NULL, NULL),
    ('arena_card',         'arena',      'card',       0.20,  '{"uncommon":0.40,"rare":0.35,"epic":0.25}', NULL, NULL, '20% at wave milestones')
ON CONFLICT (id) DO NOTHING;


-- -----------------------------------------------------------
-- DUTY BOARD TEMPLATES (replaces DutyBoardGenerator taskPool)
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.content_duties (
    id                      TEXT PRIMARY KEY,       -- e.g. "duty_morning_run"
    title                   TEXT NOT NULL,
    description             TEXT NOT NULL DEFAULT '',
    category                TEXT NOT NULL CHECK (category IN ('physical', 'mental', 'social', 'household', 'wellness', 'creative')),
    icon                    TEXT,                    -- SF Symbol name
    exp_multiplier          DOUBLE PRECISION NOT NULL DEFAULT 1.0,  -- relative to base duty EXP
    is_seasonal             BOOLEAN NOT NULL DEFAULT FALSE,
    available_from          TIMESTAMPTZ,
    available_until         TIMESTAMPTZ,
    active                  BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order              INT NOT NULL DEFAULT 0,
    created_at              TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.content_duties ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read content duties"
    ON public.content_duties FOR SELECT
    USING (TRUE);

CREATE TRIGGER bump_version_on_duties
    AFTER INSERT OR UPDATE OR DELETE ON public.content_duties
    FOR EACH STATEMENT EXECUTE FUNCTION public.bump_content_version();


-- -----------------------------------------------------------
-- NARRATIVE TEXT (dungeon narratives, expedition stories,
-- shopkeeper/forgekeeper dialogue)
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.content_narratives (
    id                      TEXT PRIMARY KEY,       -- e.g. "dungeon_combat_success_01"
    context                 TEXT NOT NULL,           -- "dungeon_combat_success", "dungeon_puzzle_fail", "expedition_stage", "shopkeeper_greeting", "forgekeeper_welcome"
    text                    TEXT NOT NULL,
    theme                   TEXT,                    -- null = universal, or specific theme
    sort_order              INT NOT NULL DEFAULT 0,
    active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at              TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_content_narratives_context ON public.content_narratives(context);

ALTER TABLE public.content_narratives ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read narratives"
    ON public.content_narratives FOR SELECT
    USING (TRUE);

CREATE TRIGGER bump_version_on_narratives
    AFTER INSERT OR UPDATE OR DELETE ON public.content_narratives
    FOR EACH STATEMENT EXECUTE FUNCTION public.bump_content_version();


-- -----------------------------------------------------------
-- AFFIX RE-ROLL COSTS (escalating cost curve)
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.content_affix_reroll_costs (
    id                      TEXT PRIMARY KEY,       -- e.g. "reroll_1"
    reroll_number           INT NOT NULL UNIQUE,     -- 1st, 2nd, 3rd... on same item
    gold_cost               INT NOT NULL,
    active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at              TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.content_affix_reroll_costs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read reroll costs"
    ON public.content_affix_reroll_costs FOR SELECT
    USING (TRUE);

-- Seed escalating re-roll costs
INSERT INTO public.content_affix_reroll_costs (id, reroll_number, gold_cost) VALUES
    ('reroll_1',  1,   300),
    ('reroll_2',  2,   500),
    ('reroll_3',  3,   800),
    ('reroll_4',  4,  1200),
    ('reroll_5',  5,  1800),
    ('reroll_6',  6,  2500),
    ('reroll_7',  7,  3500),
    ('reroll_8',  8,  5000),
    ('reroll_9',  9,  7000),
    ('reroll_10', 10, 10000)
ON CONFLICT (id) DO NOTHING;


-- -----------------------------------------------------------
-- COLLECTION MILESTONES (card collection rewards)
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.content_collection_milestones (
    id                      TEXT PRIMARY KEY,       -- e.g. "cards_10"
    collection_type         TEXT NOT NULL DEFAULT 'cards',
    threshold               INT NOT NULL,            -- how many collected
    reward_type             TEXT NOT NULL,            -- "permanent_bonus", "equipment", "title"
    reward_bonus_type       TEXT,                     -- "exp_percent", "gold_percent", etc.
    reward_bonus_value      DOUBLE PRECISION,         -- 0.02 for +2%
    reward_title            TEXT,                     -- e.g. "Monster Scholar"
    reward_equipment_id     TEXT,                     -- FK to content_equipment
    description             TEXT NOT NULL DEFAULT '',
    active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at              TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.content_collection_milestones ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read collection milestones"
    ON public.content_collection_milestones FOR SELECT
    USING (TRUE);

-- Seed card milestones
INSERT INTO public.content_collection_milestones (id, collection_type, threshold, reward_type, reward_bonus_type, reward_bonus_value, description) VALUES
    ('cards_10',  'cards', 10,  'permanent_bonus', 'exp_percent',      0.02, '+2% EXP from all sources'),
    ('cards_25',  'cards', 25,  'permanent_bonus', 'gold_percent',     0.02, '+2% Gold from all sources'),
    ('cards_50',  'cards', 50,  'permanent_bonus', 'loot_chance',      0.03, '+3% loot drop chance'),
    ('cards_75',  'cards', 75,  'permanent_bonus', 'dungeon_success',  0.03, '+3% dungeon success'),
    ('cards_100', 'cards', 100, 'title',           NULL,               NULL, 'Title: Monster Scholar + unique equipment')
ON CONFLICT (id) DO NOTHING;


-- -----------------------------------------------------------
-- STORE BUNDLES (replaces GearSetCatalog bundle deals)
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.content_store_bundles (
    id                      TEXT PRIMARY KEY,       -- e.g. "starter_pack"
    name                    TEXT NOT NULL,
    description             TEXT NOT NULL DEFAULT '',
    icon                    TEXT,
    contents                JSONB NOT NULL DEFAULT '[]',
    -- [{"type": "equipment", "id": "sword_common_01"}, {"type": "consumable", "id": "minor_hp_potion", "quantity": 3}]
    gold_cost               INT NOT NULL DEFAULT 0,
    gem_cost                INT NOT NULL DEFAULT 0,
    discount_percent        INT NOT NULL DEFAULT 0,
    level_requirement       INT NOT NULL DEFAULT 1,
    is_one_time_purchase    BOOLEAN NOT NULL DEFAULT FALSE,
    is_seasonal             BOOLEAN NOT NULL DEFAULT FALSE,
    available_from          TIMESTAMPTZ,
    available_until         TIMESTAMPTZ,
    active                  BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order              INT NOT NULL DEFAULT 0,
    created_at              TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.content_store_bundles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read store bundles"
    ON public.content_store_bundles FOR SELECT
    USING (TRUE);

CREATE TRIGGER bump_version_on_store_bundles
    AFTER INSERT OR UPDATE OR DELETE ON public.content_store_bundles
    FOR EACH STATEMENT EXECUTE FUNCTION public.bump_content_version();


-- =============================================================
-- PLAYER DATA TABLES (user-owned, RLS-protected)
-- These are NOT content — they track player progress.
-- NOTE: parties must be created before player_cards because
--       player_cards RLS references the parties table.
-- =============================================================


-- -----------------------------------------------------------
-- PARTIES (replaces partner_id on profiles for 1-4 members)
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.parties (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name                    TEXT,                    -- optional party name
    member_ids              UUID[] NOT NULL DEFAULT '{}',  -- array of 1-4 profile IDs
    bond_level              INT NOT NULL DEFAULT 1,
    bond_exp                INT NOT NULL DEFAULT 0,
    party_streak_days       INT NOT NULL DEFAULT 0,
    party_streak_last_date  DATE,                    -- last date all members completed a task
    created_by              UUID NOT NULL REFERENCES public.profiles(id),
    created_at              TIMESTAMPTZ DEFAULT NOW(),
    updated_at              TIMESTAMPTZ DEFAULT NOW(),
    -- Enforce max 4 members
    CONSTRAINT max_party_size CHECK (array_length(member_ids, 1) <= 4)
);

CREATE INDEX IF NOT EXISTS idx_parties_members ON public.parties USING GIN (member_ids);

ALTER TABLE public.parties ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Party members can read their party"
    ON public.parties FOR SELECT
    USING (auth.uid() = ANY(member_ids));

CREATE POLICY "Party members can update their party"
    ON public.parties FOR UPDATE
    USING (auth.uid() = ANY(member_ids));

CREATE POLICY "Any authenticated user can create a party"
    ON public.parties FOR INSERT
    WITH CHECK (auth.uid() = created_by);

ALTER PUBLICATION supabase_realtime ADD TABLE public.parties;


-- -----------------------------------------------------------
-- PLAYER CARD COLLECTION (tracks which cards a player owns)
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.player_cards (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id                UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    card_id                 TEXT NOT NULL REFERENCES public.content_cards(id),
    collected_at            TIMESTAMPTZ DEFAULT NOW(),
    -- One card per player (no duplicates in collection)
    UNIQUE (owner_id, card_id)
);

CREATE INDEX IF NOT EXISTS idx_player_cards_owner ON public.player_cards(owner_id);

ALTER TABLE public.player_cards ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Owner can read own cards"
    ON public.player_cards FOR SELECT
    USING (auth.uid() = owner_id);

CREATE POLICY "Party members can view cards"
    ON public.player_cards FOR SELECT
    USING (
        owner_id IN (
            SELECT unnest(member_ids) FROM public.parties
            WHERE auth.uid() = ANY(member_ids)
        )
    );

CREATE POLICY "Owner can insert own cards"
    ON public.player_cards FOR INSERT
    WITH CHECK (auth.uid() = owner_id);

-- Cards cannot be deleted or updated once collected


-- -----------------------------------------------------------
-- PARTY FEED (activity log visible to party members)
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.party_feed (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    party_id                UUID NOT NULL REFERENCES public.parties(id) ON DELETE CASCADE,
    actor_id                UUID NOT NULL REFERENCES public.profiles(id),
    event_type              TEXT NOT NULL CHECK (event_type IN (
        'task_completed', 'dungeon_loot', 'card_discovered',
        'level_up', 'achievement', 'expedition_stage',
        'enhancement_success', 'streak_milestone',
        'nudge', 'kudos'
    )),
    message                 TEXT NOT NULL,
    metadata                JSONB NOT NULL DEFAULT '{}',
    -- e.g. {"task_title": "Gym Session", "exp_earned": 35}
    -- or {"card_name": "Shadow Lurker", "cards_collected": 23, "cards_total": 50}
    created_at              TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_party_feed_party ON public.party_feed(party_id);
CREATE INDEX IF NOT EXISTS idx_party_feed_created ON public.party_feed(created_at DESC);

ALTER TABLE public.party_feed ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Party members can read their feed"
    ON public.party_feed FOR SELECT
    USING (
        party_id IN (
            SELECT id FROM public.parties WHERE auth.uid() = ANY(member_ids)
        )
    );

CREATE POLICY "Party members can insert to their feed"
    ON public.party_feed FOR INSERT
    WITH CHECK (
        party_id IN (
            SELECT id FROM public.parties WHERE auth.uid() = ANY(member_ids)
        )
    );

ALTER PUBLICATION supabase_realtime ADD TABLE public.party_feed;


-- -----------------------------------------------------------
-- ACTIVE EXPEDITIONS (player state for in-progress expeditions)
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.active_expeditions (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    expedition_id           TEXT NOT NULL REFERENCES public.content_expeditions(id),
    character_id            UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    party_member_ids        UUID[] NOT NULL DEFAULT '{}',
    current_stage_index     INT NOT NULL DEFAULT 0,
    stage_results           JSONB NOT NULL DEFAULT '[]',
    -- [{"stage_index": 0, "success": true, "narrative": "...", "exp": 50, "gold": 30, "loot": null}]
    started_at              TIMESTAMPTZ DEFAULT NOW(),
    next_stage_completes_at TIMESTAMPTZ,
    status                  TEXT NOT NULL DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed', 'failed')),
    created_at              TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_active_expeditions_character ON public.active_expeditions(character_id);

ALTER TABLE public.active_expeditions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Owner can read own expeditions"
    ON public.active_expeditions FOR SELECT
    USING (auth.uid() = character_id);

CREATE POLICY "Party members can read shared expeditions"
    ON public.active_expeditions FOR SELECT
    USING (auth.uid() = ANY(party_member_ids));

CREATE POLICY "Owner can insert own expeditions"
    ON public.active_expeditions FOR INSERT
    WITH CHECK (auth.uid() = character_id);

CREATE POLICY "Owner can update own expeditions"
    ON public.active_expeditions FOR UPDATE
    USING (auth.uid() = character_id);


-- =============================================================
-- HELPER VIEWS — convenience for the app
-- =============================================================

-- View: active content only (filters out inactive/expired)
CREATE OR REPLACE VIEW public.active_forge_recipes AS
SELECT * FROM public.content_forge_recipes
WHERE active = TRUE
  AND (available_from IS NULL OR available_from <= NOW())
  AND (available_until IS NULL OR available_until > NOW());

CREATE OR REPLACE VIEW public.active_store_bundles AS
SELECT * FROM public.content_store_bundles
WHERE active = TRUE
  AND (available_from IS NULL OR available_from <= NOW())
  AND (available_until IS NULL OR available_until > NOW());

CREATE OR REPLACE VIEW public.active_duties AS
SELECT * FROM public.content_duties
WHERE active = TRUE
  AND (available_from IS NULL OR available_from <= NOW())
  AND (available_until IS NULL OR available_until > NOW());


-- =============================================================
-- DONE — Run content_version check:
-- SELECT version, updated_at FROM content_version WHERE id = 'current';
-- =============================================================
