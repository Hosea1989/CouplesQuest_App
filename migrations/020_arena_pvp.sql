-- Migration 020: Arena PVP System
-- Adds tables and RPCs for async PVP arena with ranked ladder

-- ============================================================
-- arena_fighters: Snapshot of each player's PVP profile
-- Updated on character changes (task completion, equip, level up)
-- ============================================================
CREATE TABLE IF NOT EXISTS arena_fighters (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL DEFAULT '',
    level INT NOT NULL DEFAULT 1,
    class TEXT,
    stats_json JSONB NOT NULL DEFAULT '{}',
    equipment_summary_json JSONB NOT NULL DEFAULT '{}',
    weapon_primary_bonus INT NOT NULL DEFAULT 0,
    armor_primary_bonus INT NOT NULL DEFAULT 0,
    hero_power INT NOT NULL DEFAULT 0,
    rating INT NOT NULL DEFAULT 1000,
    tier TEXT NOT NULL DEFAULT 'Bronze',
    defense_stance TEXT NOT NULL DEFAULT 'Fortress',
    wins INT NOT NULL DEFAULT 0,
    losses INT NOT NULL DEFAULT 0,
    streak INT NOT NULL DEFAULT 0,
    peak_rating INT NOT NULL DEFAULT 1000,
    recent_trend TEXT NOT NULL DEFAULT 'neutral',
    pending_revenge_ids JSONB NOT NULL DEFAULT '[]',
    arena_points INT NOT NULL DEFAULT 0,
    has_bond BOOLEAN NOT NULL DEFAULT false,
    season_number INT NOT NULL DEFAULT 1,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_arena_fighters_tier_rating ON arena_fighters(tier, rating DESC);
CREATE INDEX idx_arena_fighters_rating ON arena_fighters(rating);

ALTER TABLE arena_fighters ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read arena fighters"
    ON arena_fighters FOR SELECT
    USING (true);

CREATE POLICY "Users can update own fighter"
    ON arena_fighters FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own fighter"
    ON arena_fighters FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- ============================================================
-- arena_matches: Record of each PVP bout
-- ============================================================
CREATE TABLE IF NOT EXISTS arena_matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    attacker_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    defender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    attacker_stance TEXT NOT NULL,
    defender_stance TEXT NOT NULL,
    rounds_json JSONB NOT NULL DEFAULT '[]',
    winner_id UUID NOT NULL,
    attacker_rating_change INT NOT NULL DEFAULT 0,
    defender_rating_change INT NOT NULL DEFAULT 0,
    attacker_rating_after INT NOT NULL DEFAULT 1000,
    defender_rating_after INT NOT NULL DEFAULT 1000,
    is_revenge BOOLEAN NOT NULL DEFAULT false,
    arena_points_earned INT NOT NULL DEFAULT 0,
    gold_earned INT NOT NULL DEFAULT 0,
    exp_earned INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_arena_matches_attacker ON arena_matches(attacker_id, created_at DESC);
CREATE INDEX idx_arena_matches_defender ON arena_matches(defender_id, created_at DESC);
CREATE INDEX idx_arena_matches_created ON arena_matches(created_at DESC);

ALTER TABLE arena_matches ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own matches"
    ON arena_matches FOR SELECT
    USING (auth.uid() = attacker_id OR auth.uid() = defender_id);

CREATE POLICY "Users can insert matches as attacker"
    ON arena_matches FOR INSERT
    WITH CHECK (auth.uid() = attacker_id);

-- ============================================================
-- arena_seasons_history: Snapshot of each player's season results
-- ============================================================
CREATE TABLE IF NOT EXISTS arena_seasons_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    season_number INT NOT NULL,
    peak_rating INT NOT NULL DEFAULT 1000,
    peak_tier TEXT NOT NULL DEFAULT 'Bronze',
    final_rating INT NOT NULL DEFAULT 1000,
    final_tier TEXT NOT NULL DEFAULT 'Bronze',
    total_wins INT NOT NULL DEFAULT 0,
    total_losses INT NOT NULL DEFAULT 0,
    rewards_claimed BOOLEAN NOT NULL DEFAULT false,
    season_start TIMESTAMPTZ NOT NULL,
    season_end TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(user_id, season_number)
);

ALTER TABLE arena_seasons_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own season history"
    ON arena_seasons_history FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "System can insert season history"
    ON arena_seasons_history FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- ============================================================
-- fn_arena_find_opponents: Find 3 matched opponents
-- Returns 1 slightly higher, 1 similar, 1 slightly lower
-- ============================================================
CREATE OR REPLACE FUNCTION fn_arena_find_opponents(
    p_user_id UUID,
    p_rating INT
)
RETURNS SETOF arena_fighters
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_higher arena_fighters;
    v_similar arena_fighters;
    v_lower arena_fighters;
BEGIN
    -- Find one fighter rated slightly higher (up to +200)
    SELECT * INTO v_higher
    FROM arena_fighters
    WHERE user_id != p_user_id
      AND rating BETWEEN p_rating AND p_rating + 200
    ORDER BY random()
    LIMIT 1;

    -- Find one fighter rated similarly (within +/- 100)
    SELECT * INTO v_similar
    FROM arena_fighters
    WHERE user_id != p_user_id
      AND user_id != COALESCE(v_higher.user_id, '00000000-0000-0000-0000-000000000000')
      AND rating BETWEEN p_rating - 100 AND p_rating + 100
    ORDER BY random()
    LIMIT 1;

    -- Find one fighter rated slightly lower (down to -200)
    SELECT * INTO v_lower
    FROM arena_fighters
    WHERE user_id != p_user_id
      AND user_id != COALESCE(v_higher.user_id, '00000000-0000-0000-0000-000000000000')
      AND user_id != COALESCE(v_similar.user_id, '00000000-0000-0000-0000-000000000000')
      AND rating BETWEEN p_rating - 200 AND p_rating
    ORDER BY random()
    LIMIT 1;

    -- Return all found opponents (may be less than 3 if not enough players)
    IF v_higher IS NOT NULL THEN RETURN NEXT v_higher; END IF;
    IF v_similar IS NOT NULL THEN RETURN NEXT v_similar; END IF;
    IF v_lower IS NOT NULL THEN RETURN NEXT v_lower; END IF;

    -- Fallback: if we got fewer than 3, fill with any random fighters
    IF v_higher IS NULL OR v_similar IS NULL OR v_lower IS NULL THEN
        RETURN QUERY
        SELECT *
        FROM arena_fighters
        WHERE user_id != p_user_id
          AND user_id != COALESCE(v_higher.user_id, '00000000-0000-0000-0000-000000000000')
          AND user_id != COALESCE(v_similar.user_id, '00000000-0000-0000-0000-000000000000')
          AND user_id != COALESCE(v_lower.user_id, '00000000-0000-0000-0000-000000000000')
        ORDER BY random()
        LIMIT 3 - (CASE WHEN v_higher IS NOT NULL THEN 1 ELSE 0 END)
                 - (CASE WHEN v_similar IS NOT NULL THEN 1 ELSE 0 END)
                 - (CASE WHEN v_lower IS NOT NULL THEN 1 ELSE 0 END);
    END IF;
END;
$$;

-- ============================================================
-- fn_arena_submit_match: Atomically record match and update ratings
-- ============================================================
CREATE OR REPLACE FUNCTION fn_arena_submit_match(
    p_attacker_id UUID,
    p_defender_id UUID,
    p_attacker_stance TEXT,
    p_defender_stance TEXT,
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

    -- Insert match record
    INSERT INTO arena_matches (
        attacker_id, defender_id, attacker_stance, defender_stance,
        rounds_json, winner_id, attacker_rating_change, defender_rating_change,
        attacker_rating_after, defender_rating_after,
        is_revenge, arena_points_earned, gold_earned, exp_earned
    ) VALUES (
        p_attacker_id, p_defender_id, p_attacker_stance, p_defender_stance,
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

    -- Add revenge opportunity for defender (if attacker won and not already a revenge match)
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

    -- Compute recent trend for attacker based on last 5 matches
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

-- ============================================================
-- fn_arena_leaderboard: Fetch tier-scoped leaderboard
-- ============================================================
CREATE OR REPLACE FUNCTION fn_arena_leaderboard(
    p_tier TEXT,
    p_limit INT DEFAULT 50,
    p_offset INT DEFAULT 0
)
RETURNS SETOF arena_fighters
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT *
    FROM arena_fighters
    WHERE tier = p_tier
    ORDER BY rating DESC
    LIMIT p_limit
    OFFSET p_offset;
$$;

-- ============================================================
-- fn_arena_end_season: Reset all ratings for new season
-- Called by a scheduled cron job on the 1st of each month
-- ============================================================
CREATE OR REPLACE FUNCTION fn_arena_end_season()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_current_season INT;
    v_season_start TIMESTAMPTZ;
    v_season_end TIMESTAMPTZ;
BEGIN
    -- Determine current season from max in history + 1
    SELECT COALESCE(MAX(season_number), 0) + 1 INTO v_current_season FROM arena_seasons_history;
    v_season_end := date_trunc('month', now());
    v_season_start := v_season_end - interval '1 month';

    -- Snapshot all fighters into history
    INSERT INTO arena_seasons_history (user_id, season_number, peak_rating, peak_tier, final_rating, final_tier, total_wins, total_losses, season_start, season_end)
    SELECT
        user_id,
        v_current_season,
        peak_rating,
        CASE
            WHEN peak_rating >= 2400 THEN 'Champion'
            WHEN peak_rating >= 2100 THEN 'Diamond'
            WHEN peak_rating >= 1800 THEN 'Platinum'
            WHEN peak_rating >= 1500 THEN 'Gold'
            WHEN peak_rating >= 1200 THEN 'Silver'
            ELSE 'Bronze'
        END,
        rating,
        tier,
        wins,
        losses,
        v_season_start,
        v_season_end
    FROM arena_fighters
    ON CONFLICT (user_id, season_number) DO NOTHING;

    -- Hard reset all fighters
    UPDATE arena_fighters SET
        rating = 1000,
        tier = 'Bronze',
        wins = 0,
        losses = 0,
        streak = 0,
        peak_rating = 1000,
        recent_trend = 'neutral',
        season_number = v_current_season + 1,
        updated_at = now();
END;
$$;
