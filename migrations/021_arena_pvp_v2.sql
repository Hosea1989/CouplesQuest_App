-- Migration 021: Arena PVP v2 - Remove Stances, Stats-Driven Combat
-- Removes stance requirement from arena matches and fighters.
-- Combat is now purely determined by character stats, gear, quirks, and class passives.

-- ============================================================
-- Drop defense_stance default requirement (keep column for backward compat)
-- ============================================================
ALTER TABLE arena_fighters
    ALTER COLUMN defense_stance SET DEFAULT 'none';

-- ============================================================
-- Add PVP-specific fields derived from gear quirks
-- ============================================================
ALTER TABLE arena_fighters
    ADD COLUMN IF NOT EXISTS pvp_damage_bonus DOUBLE PRECISION NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS pvp_hp_regen_percent DOUBLE PRECISION NOT NULL DEFAULT 0;

-- ============================================================
-- fn_arena_submit_match: Updated to remove stance parameters
-- ============================================================
CREATE OR REPLACE FUNCTION fn_arena_submit_match(
    p_attacker_id UUID,
    p_defender_id UUID,
    p_rounds_json JSONB,
    p_winner_id UUID,
    p_attacker_rating_change INT,
    p_defender_rating_change INT,
    p_is_revenge BOOLEAN,
    p_arena_points_earned INT,
    p_gold_earned INT,
    p_exp_earned INT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_attacker_new_rating INT;
    v_defender_new_rating INT;
    v_attacker_new_tier TEXT;
    v_defender_new_tier TEXT;
    v_attacker_streak INT;
BEGIN
    -- Calculate new ratings
    IF p_winner_id = p_attacker_id THEN
        SELECT GREATEST(0, rating + p_attacker_rating_change), streak + 1
        INTO v_attacker_new_rating, v_attacker_streak
        FROM arena_fighters WHERE user_id = p_attacker_id;

        v_defender_new_rating := GREATEST(0, (SELECT rating FROM arena_fighters WHERE user_id = p_defender_id) - p_defender_rating_change);
    ELSE
        v_attacker_new_rating := GREATEST(0, (SELECT rating FROM arena_fighters WHERE user_id = p_attacker_id) - p_attacker_rating_change);
        v_attacker_streak := 0;

        SELECT GREATEST(0, rating + p_defender_rating_change)
        INTO v_defender_new_rating
        FROM arena_fighters WHERE user_id = p_defender_id;
    END IF;

    -- Derive tiers
    v_attacker_new_tier := CASE
        WHEN v_attacker_new_rating >= 2400 THEN 'Champion'
        WHEN v_attacker_new_rating >= 2100 THEN 'Diamond'
        WHEN v_attacker_new_rating >= 1800 THEN 'Platinum'
        WHEN v_attacker_new_rating >= 1500 THEN 'Gold'
        WHEN v_attacker_new_rating >= 1200 THEN 'Silver'
        ELSE 'Bronze'
    END;

    v_defender_new_tier := CASE
        WHEN v_defender_new_rating >= 2400 THEN 'Champion'
        WHEN v_defender_new_rating >= 2100 THEN 'Diamond'
        WHEN v_defender_new_rating >= 1800 THEN 'Platinum'
        WHEN v_defender_new_rating >= 1500 THEN 'Gold'
        WHEN v_defender_new_rating >= 1200 THEN 'Silver'
        ELSE 'Bronze'
    END;

    -- Insert match record (stances default to 'none' for v2)
    INSERT INTO arena_matches (
        attacker_id, defender_id, attacker_stance, defender_stance,
        rounds_json, winner_id, attacker_rating_change, defender_rating_change,
        attacker_rating_after, defender_rating_after,
        is_revenge, arena_points_earned, gold_earned, exp_earned
    ) VALUES (
        p_attacker_id, p_defender_id, 'none', 'none',
        p_rounds_json, p_winner_id, p_attacker_rating_change, p_defender_rating_change,
        v_attacker_new_rating, v_defender_new_rating,
        p_is_revenge, p_arena_points_earned, p_gold_earned, p_exp_earned
    );

    -- Update attacker
    UPDATE arena_fighters SET
        rating = v_attacker_new_rating,
        tier = v_attacker_new_tier,
        wins = CASE WHEN p_winner_id = p_attacker_id THEN wins + 1 ELSE wins END,
        losses = CASE WHEN p_winner_id != p_attacker_id THEN losses + 1 ELSE losses END,
        streak = v_attacker_streak,
        peak_rating = GREATEST(peak_rating, v_attacker_new_rating),
        arena_points = arena_points + p_arena_points_earned,
        updated_at = now()
    WHERE user_id = p_attacker_id;

    -- Update defender
    UPDATE arena_fighters SET
        rating = v_defender_new_rating,
        tier = v_defender_new_tier,
        wins = CASE WHEN p_winner_id = p_defender_id THEN wins + 1 ELSE wins END,
        losses = CASE WHEN p_winner_id != p_defender_id THEN losses + 1 ELSE losses END,
        streak = CASE WHEN p_winner_id = p_defender_id THEN streak + 1 ELSE 0 END,
        peak_rating = GREATEST(peak_rating, v_defender_new_rating),
        updated_at = now()
    WHERE user_id = p_defender_id;

    -- Add revenge opportunity for defender
    IF p_winner_id = p_attacker_id AND NOT p_is_revenge THEN
        UPDATE arena_fighters SET
            pending_revenge_ids = (
                SELECT jsonb_agg(val)
                FROM (
                    SELECT val FROM jsonb_array_elements(pending_revenge_ids) AS val
                    UNION ALL
                    SELECT to_jsonb(p_attacker_id::TEXT)
                ) sub
                LIMIT 3
            )
        WHERE user_id = p_defender_id;
    END IF;

    -- Compute recent trend for attacker
    UPDATE arena_fighters SET
        recent_trend = (
            SELECT CASE
                WHEN wins_count > losses_count THEN 'up'
                WHEN losses_count > wins_count THEN 'down'
                ELSE 'neutral'
            END
            FROM (
                SELECT
                    COUNT(*) FILTER (WHERE winner_id = p_attacker_id) AS wins_count,
                    COUNT(*) FILTER (WHERE winner_id != p_attacker_id) AS losses_count
                FROM (
                    SELECT winner_id FROM arena_matches
                    WHERE attacker_id = p_attacker_id OR defender_id = p_attacker_id
                    ORDER BY created_at DESC LIMIT 5
                ) recent
            ) agg
        )
    WHERE user_id = p_attacker_id;

    RETURN jsonb_build_object(
        'attacker_new_rating', v_attacker_new_rating,
        'attacker_new_tier', v_attacker_new_tier,
        'attacker_streak', v_attacker_streak,
        'defender_new_rating', v_defender_new_rating
    );
END;
$$;
