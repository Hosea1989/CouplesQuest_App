-- Migration 018: Global community raid boss
-- All authenticated users attack the same weekly boss with a shared HP pool.

-- The single active boss each week
CREATE TABLE IF NOT EXISTS community_raid_boss (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    sprite_image TEXT NOT NULL DEFAULT 'raidboss-beast',
    background_image TEXT NOT NULL DEFAULT 'raidboss-bg-volcano',
    tier INT NOT NULL DEFAULT 1,
    max_hp BIGINT NOT NULL,
    current_hp BIGINT NOT NULL,
    week_start TIMESTAMPTZ NOT NULL,
    week_end TIMESTAMPTZ NOT NULL,
    is_defeated BOOLEAN NOT NULL DEFAULT false,
    total_participants INT NOT NULL DEFAULT 0,
    modifier_name TEXT,
    modifier_description TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Individual attacks from every player
CREATE TABLE IF NOT EXISTS community_raid_attacks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    boss_id UUID NOT NULL REFERENCES community_raid_boss(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    player_name TEXT NOT NULL,
    damage INT NOT NULL,
    source_description TEXT DEFAULT 'Manual raid attack',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Track which users have claimed rewards for a defeated boss
CREATE TABLE IF NOT EXISTS community_raid_rewards_claimed (
    boss_id UUID NOT NULL REFERENCES community_raid_boss(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    claimed_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (boss_id, user_id)
);

-- RLS
ALTER TABLE community_raid_boss ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_raid_attacks ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_raid_rewards_claimed ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view the community boss"
    ON community_raid_boss FOR SELECT
    USING (true);

CREATE POLICY "Anyone can view community attacks"
    ON community_raid_attacks FOR SELECT
    USING (true);

CREATE POLICY "Users can view their own reward claims"
    ON community_raid_rewards_claimed FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can claim their own rewards"
    ON community_raid_rewards_claimed FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_community_raid_boss_week ON community_raid_boss(week_start);
CREATE INDEX IF NOT EXISTS idx_community_raid_attacks_boss ON community_raid_attacks(boss_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_community_raid_attacks_user_day ON community_raid_attacks(boss_id, user_id, created_at);

-- Atomic attack RPC: decrements HP, records the attack, enforces daily cap, returns result
CREATE OR REPLACE FUNCTION fn_community_raid_attack(
    p_boss_id UUID,
    p_user_id UUID,
    p_player_name TEXT,
    p_damage INT,
    p_source TEXT DEFAULT 'Manual raid attack'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_boss RECORD;
    v_attacks_today INT;
    v_new_hp BIGINT;
    v_defeated BOOLEAN;
    v_is_new_participant BOOLEAN;
BEGIN
    SELECT * INTO v_boss FROM community_raid_boss WHERE id = p_boss_id FOR UPDATE;

    IF v_boss IS NULL THEN
        RETURN jsonb_build_object('error', 'Boss not found');
    END IF;

    IF v_boss.is_defeated THEN
        RETURN jsonb_build_object('error', 'Boss already defeated');
    END IF;

    IF now() > v_boss.week_end THEN
        RETURN jsonb_build_object('error', 'Boss expired');
    END IF;

    SELECT COUNT(*) INTO v_attacks_today
    FROM community_raid_attacks
    WHERE boss_id = p_boss_id
      AND user_id = p_user_id
      AND created_at >= date_trunc('day', now());

    IF v_attacks_today >= 5 THEN
        RETURN jsonb_build_object('error', 'Daily attack limit reached', 'daily_attacks_used', v_attacks_today);
    END IF;

    SELECT NOT EXISTS (
        SELECT 1 FROM community_raid_attacks
        WHERE boss_id = p_boss_id AND user_id = p_user_id
    ) INTO v_is_new_participant;

    INSERT INTO community_raid_attacks (boss_id, user_id, player_name, damage, source_description)
    VALUES (p_boss_id, p_user_id, p_player_name, p_damage, p_source);

    v_new_hp := GREATEST(0, v_boss.current_hp - p_damage);
    v_defeated := v_new_hp <= 0;

    UPDATE community_raid_boss
    SET current_hp = v_new_hp,
        is_defeated = v_defeated,
        total_participants = CASE WHEN v_is_new_participant THEN total_participants + 1 ELSE total_participants END
    WHERE id = p_boss_id;

    RETURN jsonb_build_object(
        'new_hp', v_new_hp,
        'boss_defeated', v_defeated,
        'daily_attacks_used', v_attacks_today + 1
    );
END;
$$;
