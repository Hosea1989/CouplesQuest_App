-- Migration 014: Party Challenges cloud sync
-- Allows party members to see and participate in challenges created by others.

CREATE TABLE IF NOT EXISTS party_challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    party_id UUID REFERENCES parties(id) ON DELETE CASCADE,
    challenge_type TEXT NOT NULL,
    target_count INT NOT NULL,
    title TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    deadline TIMESTAMPTZ NOT NULL,
    created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    is_active BOOLEAN DEFAULT true,
    member_progress JSONB DEFAULT '[]'::jsonb,
    reward_bond_exp INT DEFAULT 0,
    reward_gold INT DEFAULT 0,
    party_bonus_bond_exp INT DEFAULT 0,
    party_bonus_awarded BOOLEAN DEFAULT false
);

-- RLS: party members can read/write challenges for their party
ALTER TABLE party_challenges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Party members can view their challenges"
    ON party_challenges FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM parties
            WHERE parties.id = party_challenges.party_id
            AND auth.uid() = ANY(parties.member_ids)
        )
    );

CREATE POLICY "Party members can insert challenges"
    ON party_challenges FOR INSERT
    WITH CHECK (
        auth.uid() = created_by
        AND EXISTS (
            SELECT 1 FROM parties
            WHERE parties.id = party_challenges.party_id
            AND auth.uid() = ANY(parties.member_ids)
        )
    );

CREATE POLICY "Party members can update their challenges"
    ON party_challenges FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM parties
            WHERE parties.id = party_challenges.party_id
            AND auth.uid() = ANY(parties.member_ids)
        )
    );

-- Index for quick lookups
CREATE INDEX IF NOT EXISTS idx_party_challenges_party_id ON party_challenges(party_id);
CREATE INDEX IF NOT EXISTS idx_party_challenges_active ON party_challenges(is_active) WHERE is_active = true;
