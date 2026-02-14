-- Migration 006: Player Sync Tables
-- Phase -1: Data Architecture — Cloud sync for all player progression data
-- These tables ensure that achievements, tasks, goals, mood entries,
-- arena/dungeon/mission history, and daily state survive app reinstalls.

-- ============================================================
-- 1. player_achievements — Achievement progress + unlock timestamps
-- ============================================================
CREATE TABLE IF NOT EXISTS player_achievements (
    id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    player_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    tracking_key TEXT NOT NULL,
    name        TEXT NOT NULL,
    description TEXT NOT NULL,
    icon        TEXT NOT NULL DEFAULT 'trophy.fill',
    target_value INT NOT NULL DEFAULT 1,
    current_value INT NOT NULL DEFAULT 0,
    is_unlocked BOOLEAN NOT NULL DEFAULT FALSE,
    unlocked_at TIMESTAMPTZ,
    reward_type TEXT NOT NULL DEFAULT 'EXP',
    reward_amount INT NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ DEFAULT now(),
    updated_at  TIMESTAMPTZ DEFAULT now(),
    UNIQUE(player_id, tracking_key)
);

ALTER TABLE player_achievements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own achievements"
    ON player_achievements FOR SELECT
    USING (auth.uid() = player_id);

CREATE POLICY "Users can insert own achievements"
    ON player_achievements FOR INSERT
    WITH CHECK (auth.uid() = player_id);

CREATE POLICY "Users can update own achievements"
    ON player_achievements FOR UPDATE
    USING (auth.uid() = player_id);

CREATE INDEX idx_player_achievements_player ON player_achievements(player_id);

-- ============================================================
-- 2. player_tasks — ALL tasks (self-created + partner-assigned, unified)
-- ============================================================
CREATE TABLE IF NOT EXISTS player_tasks (
    id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    player_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    local_id        UUID NOT NULL,
    title           TEXT NOT NULL,
    description     TEXT,
    category        TEXT NOT NULL DEFAULT 'Mental',
    status          TEXT NOT NULL DEFAULT 'pending',
    is_habit        BOOLEAN NOT NULL DEFAULT FALSE,
    is_recurring    BOOLEAN NOT NULL DEFAULT FALSE,
    recurrence_pattern TEXT,
    habit_streak    INT NOT NULL DEFAULT 0,
    habit_longest_streak INT NOT NULL DEFAULT 0,
    is_from_partner BOOLEAN NOT NULL DEFAULT FALSE,
    assigned_to     UUID,
    created_by      UUID,
    verification_type TEXT NOT NULL DEFAULT 'none',
    is_verified     BOOLEAN NOT NULL DEFAULT FALSE,
    due_date        TIMESTAMPTZ,
    completed_at    TIMESTAMPTZ,
    goal_id         UUID,
    custom_exp      INT,
    created_at      TIMESTAMPTZ DEFAULT now(),
    updated_at      TIMESTAMPTZ DEFAULT now(),
    UNIQUE(player_id, local_id)
);

ALTER TABLE player_tasks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own tasks"
    ON player_tasks FOR SELECT
    USING (auth.uid() = player_id);

CREATE POLICY "Users can insert own tasks"
    ON player_tasks FOR INSERT
    WITH CHECK (auth.uid() = player_id);

CREATE POLICY "Users can update own tasks"
    ON player_tasks FOR UPDATE
    USING (auth.uid() = player_id);

CREATE POLICY "Users can delete own tasks"
    ON player_tasks FOR DELETE
    USING (auth.uid() = player_id);

CREATE INDEX idx_player_tasks_player ON player_tasks(player_id);
CREATE INDEX idx_player_tasks_status ON player_tasks(player_id, status);

-- ============================================================
-- 3. player_goals — Goal progress, milestone completions
-- ============================================================
CREATE TABLE IF NOT EXISTS player_goals (
    id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    player_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    local_id        UUID NOT NULL,
    title           TEXT NOT NULL,
    description     TEXT,
    category        TEXT NOT NULL DEFAULT 'Mental',
    status          TEXT NOT NULL DEFAULT 'active',
    target_date     TIMESTAMPTZ,
    milestone_25_claimed BOOLEAN NOT NULL DEFAULT FALSE,
    milestone_50_claimed BOOLEAN NOT NULL DEFAULT FALSE,
    milestone_75_claimed BOOLEAN NOT NULL DEFAULT FALSE,
    milestone_100_claimed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ DEFAULT now(),
    completed_at    TIMESTAMPTZ,
    updated_at      TIMESTAMPTZ DEFAULT now(),
    UNIQUE(player_id, local_id)
);

ALTER TABLE player_goals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own goals"
    ON player_goals FOR SELECT
    USING (auth.uid() = player_id);

CREATE POLICY "Users can insert own goals"
    ON player_goals FOR INSERT
    WITH CHECK (auth.uid() = player_id);

CREATE POLICY "Users can update own goals"
    ON player_goals FOR UPDATE
    USING (auth.uid() = player_id);

CREATE POLICY "Users can delete own goals"
    ON player_goals FOR DELETE
    USING (auth.uid() = player_id);

CREATE INDEX idx_player_goals_player ON player_goals(player_id);

-- ============================================================
-- 4. player_daily_state — Daily counters, streak dates, last reset
-- ============================================================
CREATE TABLE IF NOT EXISTS player_daily_state (
    id                  UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    player_id           UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE UNIQUE,
    tasks_completed_today INT NOT NULL DEFAULT 0,
    duties_completed_today INT NOT NULL DEFAULT 0,
    arena_attempts_today INT NOT NULL DEFAULT 0,
    last_daily_reset    TIMESTAMPTZ DEFAULT now(),
    last_active_at      TIMESTAMPTZ DEFAULT now(),
    last_meditation_date TIMESTAMPTZ,
    last_mood_date      TIMESTAMPTZ,
    last_arena_date     TIMESTAMPTZ,
    current_streak      INT NOT NULL DEFAULT 0,
    longest_streak      INT NOT NULL DEFAULT 0,
    mood_streak         INT NOT NULL DEFAULT 0,
    meditation_streak   INT NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE player_daily_state ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own daily state"
    ON player_daily_state FOR SELECT
    USING (auth.uid() = player_id);

CREATE POLICY "Users can insert own daily state"
    ON player_daily_state FOR INSERT
    WITH CHECK (auth.uid() = player_id);

CREATE POLICY "Users can update own daily state"
    ON player_daily_state FOR UPDATE
    USING (auth.uid() = player_id);

CREATE INDEX idx_player_daily_state_player ON player_daily_state(player_id);

-- ============================================================
-- 5. player_mood_entries — Wellness tracking (mood + journal)
-- ============================================================
CREATE TABLE IF NOT EXISTS player_mood_entries (
    id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    player_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    local_id    UUID NOT NULL,
    mood_level  INT NOT NULL CHECK (mood_level BETWEEN 1 AND 5),
    journal_text TEXT,
    date        TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at  TIMESTAMPTZ DEFAULT now(),
    UNIQUE(player_id, local_id)
);

ALTER TABLE player_mood_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own mood entries"
    ON player_mood_entries FOR SELECT
    USING (auth.uid() = player_id);

CREATE POLICY "Users can insert own mood entries"
    ON player_mood_entries FOR INSERT
    WITH CHECK (auth.uid() = player_id);

CREATE INDEX idx_player_mood_player ON player_mood_entries(player_id);
CREATE INDEX idx_player_mood_date ON player_mood_entries(player_id, date DESC);

-- ============================================================
-- 6. player_arena_runs — Arena personal bests + history
-- ============================================================
CREATE TABLE IF NOT EXISTS player_arena_runs (
    id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    player_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    best_wave       INT NOT NULL DEFAULT 0,
    waves_cleared   INT NOT NULL DEFAULT 0,
    score           INT NOT NULL DEFAULT 0,
    character_level INT NOT NULL DEFAULT 1,
    character_class TEXT,
    completed_at    TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE player_arena_runs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own arena runs"
    ON player_arena_runs FOR SELECT
    USING (auth.uid() = player_id);

CREATE POLICY "Users can insert own arena runs"
    ON player_arena_runs FOR INSERT
    WITH CHECK (auth.uid() = player_id);

CREATE INDEX idx_player_arena_player ON player_arena_runs(player_id);

-- ============================================================
-- 7. player_dungeon_runs — Run history (for stats display)
-- ============================================================
CREATE TABLE IF NOT EXISTS player_dungeon_runs (
    id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    player_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    dungeon_name    TEXT NOT NULL,
    difficulty      TEXT NOT NULL DEFAULT 'Normal',
    rooms_cleared   INT NOT NULL DEFAULT 0,
    total_rooms     INT NOT NULL DEFAULT 0,
    was_successful  BOOLEAN NOT NULL DEFAULT FALSE,
    loot_earned     JSONB DEFAULT '[]'::jsonb,
    exp_earned      INT NOT NULL DEFAULT 0,
    gold_earned     INT NOT NULL DEFAULT 0,
    character_level INT NOT NULL DEFAULT 1,
    character_class TEXT,
    completed_at    TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE player_dungeon_runs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own dungeon runs"
    ON player_dungeon_runs FOR SELECT
    USING (auth.uid() = player_id);

CREATE POLICY "Users can insert own dungeon runs"
    ON player_dungeon_runs FOR INSERT
    WITH CHECK (auth.uid() = player_id);

CREATE INDEX idx_player_dungeon_player ON player_dungeon_runs(player_id);

-- ============================================================
-- 8. player_mission_history — Completed AFK mission log
-- ============================================================
CREATE TABLE IF NOT EXISTS player_mission_history (
    id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    player_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    mission_name    TEXT NOT NULL,
    mission_type    TEXT NOT NULL,
    rarity          TEXT NOT NULL DEFAULT 'Common',
    was_successful  BOOLEAN NOT NULL DEFAULT FALSE,
    duration_seconds INT NOT NULL DEFAULT 0,
    exp_earned      INT NOT NULL DEFAULT 0,
    gold_earned     INT NOT NULL DEFAULT 0,
    loot_earned     JSONB DEFAULT '[]'::jsonb,
    character_level INT NOT NULL DEFAULT 1,
    completed_at    TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE player_mission_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own mission history"
    ON player_mission_history FOR SELECT
    USING (auth.uid() = player_id);

CREATE POLICY "Users can insert own mission history"
    ON player_mission_history FOR INSERT
    WITH CHECK (auth.uid() = player_id);

CREATE INDEX idx_player_mission_player ON player_mission_history(player_id);

-- ============================================================
-- Enable Realtime on tables that benefit from live updates
-- ============================================================
ALTER PUBLICATION supabase_realtime ADD TABLE player_achievements;
ALTER PUBLICATION supabase_realtime ADD TABLE player_daily_state;

-- ============================================================
-- Auto-update updated_at timestamps
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_player_achievements_updated_at
    BEFORE UPDATE ON player_achievements
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_player_tasks_updated_at
    BEFORE UPDATE ON player_tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_player_goals_updated_at
    BEFORE UPDATE ON player_goals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_player_daily_state_updated_at
    BEFORE UPDATE ON player_daily_state
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
