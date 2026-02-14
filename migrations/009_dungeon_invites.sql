-- Migration 009: Dungeon invite / lobby tables
-- Tracks co-op dungeon invitations so party members can accept/decline.

-- Parent table: one row per dungeon invite session
CREATE TABLE IF NOT EXISTS dungeon_invites (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    party_id    UUID REFERENCES parties(id) ON DELETE CASCADE,
    host_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    dungeon_id  UUID NOT NULL,
    dungeon_name TEXT NOT NULL,
    status      TEXT NOT NULL DEFAULT 'waiting'
                CHECK (status IN ('waiting', 'started', 'cancelled', 'expired')),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at  TIMESTAMPTZ NOT NULL DEFAULT (now() + INTERVAL '2 minutes')
);

-- Child table: one row per invited member
CREATE TABLE IF NOT EXISTS dungeon_invite_responses (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invite_id   UUID NOT NULL REFERENCES dungeon_invites(id) ON DELETE CASCADE,
    user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    response    TEXT NOT NULL DEFAULT 'pending'
                CHECK (response IN ('pending', 'accepted', 'declined')),
    responded_at TIMESTAMPTZ,
    UNIQUE (invite_id, user_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_dungeon_invites_host ON dungeon_invites(host_user_id);
CREATE INDEX IF NOT EXISTS idx_dungeon_invites_status ON dungeon_invites(status) WHERE status = 'waiting';
CREATE INDEX IF NOT EXISTS idx_invite_responses_invite ON dungeon_invite_responses(invite_id);
CREATE INDEX IF NOT EXISTS idx_invite_responses_user ON dungeon_invite_responses(user_id);

-- RLS
ALTER TABLE dungeon_invites ENABLE ROW LEVEL SECURITY;
ALTER TABLE dungeon_invite_responses ENABLE ROW LEVEL SECURITY;

-- Anyone in the party can read the invite
CREATE POLICY "Party members can read invites" ON dungeon_invites
    FOR SELECT USING (TRUE);

-- Only the host can insert
CREATE POLICY "Host can create invites" ON dungeon_invites
    FOR INSERT WITH CHECK (auth.uid() = host_user_id);

-- Host can update status (start / cancel)
CREATE POLICY "Host can update invite status" ON dungeon_invites
    FOR UPDATE USING (auth.uid() = host_user_id);

-- Responses: readable by anyone (lobby needs to see all responses)
CREATE POLICY "Anyone can read responses" ON dungeon_invite_responses
    FOR SELECT USING (TRUE);

-- Host can insert response rows for all members
CREATE POLICY "Host can insert responses" ON dungeon_invite_responses
    FOR INSERT WITH CHECK (TRUE);

-- Each user can update their own response
CREATE POLICY "User can update own response" ON dungeon_invite_responses
    FOR UPDATE USING (auth.uid() = user_id);

-- Enable realtime for the responses table (lobby listens for changes)
ALTER PUBLICATION supabase_realtime ADD TABLE dungeon_invite_responses;
