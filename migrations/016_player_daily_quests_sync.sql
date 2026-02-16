-- Migration 016: Player daily quest state sync
-- Ensures the same daily quests and progress across devices for the same day.

CREATE TABLE IF NOT EXISTS player_daily_quests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    local_id UUID NOT NULL,
    title TEXT NOT NULL,
    quest_description TEXT,
    icon TEXT DEFAULT 'star.fill',
    quest_type TEXT NOT NULL,
    quest_param TEXT,
    target_value INT NOT NULL DEFAULT 1,
    current_value INT NOT NULL DEFAULT 0,
    exp_reward INT DEFAULT 0,
    gold_reward INT DEFAULT 0,
    is_completed BOOLEAN DEFAULT false,
    is_claimed BOOLEAN DEFAULT false,
    is_bonus_quest BOOLEAN DEFAULT false,
    generated_date DATE NOT NULL,
    UNIQUE(player_id, local_id)
);

-- RLS: users can only access their own daily quests
ALTER TABLE player_daily_quests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own daily quests"
    ON player_daily_quests FOR SELECT
    USING (auth.uid() = player_id);

CREATE POLICY "Users can insert own daily quests"
    ON player_daily_quests FOR INSERT
    WITH CHECK (auth.uid() = player_id);

CREATE POLICY "Users can update own daily quests"
    ON player_daily_quests FOR UPDATE
    USING (auth.uid() = player_id);

CREATE POLICY "Users can delete own daily quests"
    ON player_daily_quests FOR DELETE
    USING (auth.uid() = player_id);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_player_daily_quests_player ON player_daily_quests(player_id);
CREATE INDEX IF NOT EXISTS idx_player_daily_quests_date ON player_daily_quests(player_id, generated_date);
