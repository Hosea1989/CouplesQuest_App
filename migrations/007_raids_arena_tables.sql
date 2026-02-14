-- =============================================================
-- QuestBond Migration 007 — Raid Boss Templates & Arena Modifiers
-- Run this in the Supabase SQL Editor.
--
-- Agent 7: Adds content tables for server-driven raid boss
-- templates and weekly arena modifier rotation.
-- =============================================================


-- -----------------------------------------------------------
-- RAID BOSS TEMPLATES (server-driven weekly rotation)
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.content_raids (
    id                      TEXT PRIMARY KEY,       -- e.g. "boss_gorrath"
    name                    TEXT NOT NULL,
    description             TEXT NOT NULL DEFAULT '',
    icon                    TEXT NOT NULL DEFAULT 'flame.circle.fill',
    theme                   TEXT NOT NULL DEFAULT 'general', -- "fire", "ice", "shadow", "nature", "arcane", "iron", "void", "general"
    modifier_name           TEXT NOT NULL DEFAULT '',        -- e.g. "Fire Aura"
    modifier_description    TEXT NOT NULL DEFAULT '',        -- e.g. "-30% STR damage, +50% WIS damage"
    modifier_stat_penalty   TEXT,                            -- stat that deals less damage (e.g. "strength")
    modifier_penalty_value  DOUBLE PRECISION NOT NULL DEFAULT 0.0, -- e.g. 0.30 for -30%
    modifier_stat_bonus     TEXT,                            -- stat that deals more damage (e.g. "wisdom")
    modifier_bonus_value    DOUBLE PRECISION NOT NULL DEFAULT 0.0, -- e.g. 0.50 for +50%
    base_hp_per_tier        INT NOT NULL DEFAULT 3000,       -- HP = base_hp_per_tier × tier × party_factor
    gold_reward_per_tier    INT NOT NULL DEFAULT 150,        -- gold = gold_reward_per_tier × tier
    exp_reward_per_tier     INT NOT NULL DEFAULT 200,        -- EXP = exp_reward_per_tier × tier
    guaranteed_consumable   TEXT,                            -- consumable type guaranteed on defeat
    equip_drop_chance       DOUBLE PRECISION NOT NULL DEFAULT 0.20, -- 15-25% rare+ equipment
    unique_card_id          TEXT,                            -- FK to content_cards — boss-exclusive card
    active                  BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order              INT NOT NULL DEFAULT 0,
    created_at              TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_content_raids_active ON public.content_raids(active) WHERE active = TRUE;

ALTER TABLE public.content_raids ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read raid templates"
    ON public.content_raids FOR SELECT
    USING (TRUE);

-- Auto-bump content version on changes
CREATE TRIGGER bump_version_on_raids
    AFTER INSERT OR UPDATE OR DELETE ON public.content_raids
    FOR EACH STATEMENT EXECUTE FUNCTION public.bump_content_version();


-- -----------------------------------------------------------
-- ARENA MODIFIERS (weekly rotation pool)
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.content_arena_modifiers (
    id                      TEXT PRIMARY KEY,       -- e.g. "mod_berserker"
    name                    TEXT NOT NULL,
    description             TEXT NOT NULL DEFAULT '',
    icon                    TEXT NOT NULL DEFAULT 'bolt.fill',
    -- Mechanical effects (all optional, engine applies what's set)
    damage_dealt_multiplier DOUBLE PRECISION NOT NULL DEFAULT 1.0,  -- 2.0 = double damage dealt
    damage_taken_multiplier DOUBLE PRECISION NOT NULL DEFAULT 1.0,  -- 2.0 = double damage taken
    starting_hp_override    INT,                     -- null = default 100, e.g. 50 for Glass Cannon
    hp_regen_per_wave       INT NOT NULL DEFAULT 0,  -- heal X HP between waves
    gold_multiplier         DOUBLE PRECISION NOT NULL DEFAULT 1.0,  -- bonus gold
    exp_multiplier          DOUBLE PRECISION NOT NULL DEFAULT 1.0,  -- bonus EXP
    all_boss_waves          BOOLEAN NOT NULL DEFAULT FALSE, -- every wave is a boss wave
    stat_focus              TEXT,                     -- null = no focus, e.g. "strength" for Elemental Fury
    stat_focus_multiplier   DOUBLE PRECISION NOT NULL DEFAULT 1.0, -- how much focused stat is boosted
    active                  BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order              INT NOT NULL DEFAULT 0,
    created_at              TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.content_arena_modifiers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read arena modifiers"
    ON public.content_arena_modifiers FOR SELECT
    USING (TRUE);

CREATE TRIGGER bump_version_on_arena_modifiers
    AFTER INSERT OR UPDATE OR DELETE ON public.content_arena_modifiers
    FOR EACH STATEMENT EXECUTE FUNCTION public.bump_content_version();


-- =============================================================
-- DONE
-- =============================================================
