-- Migration 015: Shared weekly raid boss for parties
-- Partners share the same raid boss instead of each having their own.

CREATE TABLE IF NOT EXISTS party_raid_bosses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    party_id UUID REFERENCES parties(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    icon TEXT DEFAULT 'flame.circle.fill',
    tier INT DEFAULT 1,
    max_hp INT NOT NULL,
    current_hp INT NOT NULL,
    week_start_date TIMESTAMPTZ NOT NULL,
    week_end_date TIMESTAMPTZ NOT NULL,
    is_defeated BOOLEAN DEFAULT false,
    rewards_claimed_by UUID[] DEFAULT '{}',
    template_id TEXT,
    modifier_name TEXT,
    modifier_description TEXT,
    party_scale_factor DOUBLE PRECISION DEFAULT 1.0,
    attack_log JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS: party members can read/write their party's raid boss
ALTER TABLE party_raid_bosses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Party members can view their raid boss"
    ON party_raid_bosses FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM parties
            WHERE parties.id = party_raid_bosses.party_id
            AND auth.uid() = ANY(parties.member_ids)
        )
    );

CREATE POLICY "Party members can insert raid boss"
    ON party_raid_bosses FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM parties
            WHERE parties.id = party_raid_bosses.party_id
            AND auth.uid() = ANY(parties.member_ids)
        )
    );

CREATE POLICY "Party members can update their raid boss"
    ON party_raid_bosses FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM parties
            WHERE parties.id = party_raid_bosses.party_id
            AND auth.uid() = ANY(parties.member_ids)
        )
    );

-- Index for quick lookups
CREATE INDEX IF NOT EXISTS idx_party_raid_bosses_party_id ON party_raid_bosses(party_id);
CREATE INDEX IF NOT EXISTS idx_party_raid_bosses_week ON party_raid_bosses(week_start_date);
