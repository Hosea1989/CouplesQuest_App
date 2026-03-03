-- Migration 019: Raid Boss V2 — 3-phase system, 2-week window, party tracking, no daily cap
-- Adds phase progression, contribution tracking, party counting, and next-boss scheduling.

-- New columns on community_raid_boss
ALTER TABLE community_raid_boss
    ADD COLUMN IF NOT EXISTS current_phase INT NOT NULL DEFAULT 1,
    ADD COLUMN IF NOT EXISTS phase_max_hp BIGINT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS total_damage_dealt BIGINT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS total_parties INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS next_boss_date TIMESTAMPTZ;

-- Party tracking on attacks
ALTER TABLE community_raid_attacks
    ADD COLUMN IF NOT EXISTS party_id TEXT;

CREATE INDEX IF NOT EXISTS idx_community_raid_attacks_party
    ON community_raid_attacks(boss_id, party_id);

-- Replace the attack RPC with phase-aware logic (no daily cap)
CREATE OR REPLACE FUNCTION fn_community_raid_attack(
    p_boss_id UUID,
    p_user_id UUID,
    p_player_name TEXT,
    p_damage INT,
    p_source TEXT DEFAULT 'Activity damage',
    p_party_id TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_boss RECORD;
    v_new_hp BIGINT;
    v_defeated BOOLEAN;
    v_is_new_participant BOOLEAN;
    v_is_new_party BOOLEAN;
    v_new_phase INT;
    v_new_phase_max_hp BIGINT;
    v_base_hp BIGINT;
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

    -- Check new participant
    SELECT NOT EXISTS (
        SELECT 1 FROM community_raid_attacks
        WHERE boss_id = p_boss_id AND user_id = p_user_id
    ) INTO v_is_new_participant;

    -- Check new party
    v_is_new_party := false;
    IF p_party_id IS NOT NULL THEN
        SELECT NOT EXISTS (
            SELECT 1 FROM community_raid_attacks
            WHERE boss_id = p_boss_id AND party_id = p_party_id
        ) INTO v_is_new_party;
    END IF;

    -- Record the attack
    INSERT INTO community_raid_attacks (boss_id, user_id, player_name, damage, source_description, party_id)
    VALUES (p_boss_id, p_user_id, p_player_name, p_damage, p_source, p_party_id);

    -- Apply damage
    v_new_hp := GREATEST(0, v_boss.current_hp - p_damage);
    v_defeated := false;
    v_new_phase := v_boss.current_phase;
    v_new_phase_max_hp := v_boss.phase_max_hp;

    -- Phase transition: if HP reaches 0 and not on phase 3, advance
    IF v_new_hp <= 0 AND v_boss.current_phase < 3 THEN
        v_new_phase := v_boss.current_phase + 1;
        -- Phase HP formula: base * multiplier (1.0 / 1.5 / 2.5)
        v_base_hp := 30000 * v_boss.tier;
        CASE v_new_phase
            WHEN 2 THEN v_new_phase_max_hp := (v_base_hp * 1.5)::BIGINT;
            WHEN 3 THEN v_new_phase_max_hp := (v_base_hp * 2.5)::BIGINT;
            ELSE v_new_phase_max_hp := v_base_hp;
        END CASE;
        v_new_hp := v_new_phase_max_hp;
    ELSIF v_new_hp <= 0 AND v_boss.current_phase = 3 THEN
        v_defeated := true;
    END IF;

    UPDATE community_raid_boss
    SET current_hp = v_new_hp,
        is_defeated = v_defeated,
        current_phase = v_new_phase,
        phase_max_hp = v_new_phase_max_hp,
        total_damage_dealt = total_damage_dealt + p_damage,
        total_participants = CASE WHEN v_is_new_participant THEN total_participants + 1 ELSE total_participants END,
        total_parties = CASE WHEN v_is_new_party THEN total_parties + 1 ELSE total_parties END,
        next_boss_date = CASE WHEN v_defeated THEN now() + (floor(random() * 3) + 1) * INTERVAL '1 day' ELSE next_boss_date END
    WHERE id = p_boss_id;

    RETURN jsonb_build_object(
        'new_hp', v_new_hp,
        'boss_defeated', v_defeated,
        'current_phase', v_new_phase,
        'phase_max_hp', v_new_phase_max_hp,
        'total_damage_dealt', v_boss.total_damage_dealt + p_damage
    );
END;
$$;
