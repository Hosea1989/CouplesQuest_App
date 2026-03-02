-- Migration 017: Fix player_mood_entries RLS for upsert
-- The syncMoodEntry method uses upsert (INSERT ON CONFLICT UPDATE),
-- which requires an UPDATE policy. The original migration only created
-- INSERT and SELECT policies, causing:
--   "new row violates row-level security policy (USING expression)"

CREATE POLICY "Users can update own mood entries"
    ON player_mood_entries FOR UPDATE
    USING (auth.uid() = player_id);
