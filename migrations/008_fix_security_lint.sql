-- =============================================================
-- 008: Fix Supabase security linter warnings
-- =============================================================
-- Fixes:
--   1. active_duties view — SECURITY DEFINER → SECURITY INVOKER
--   2. active_store_bundles view — SECURITY DEFINER → SECURITY INVOKER
--   3. active_forge_recipes view — SECURITY DEFINER → SECURITY INVOKER
--   4. content_version table — enable RLS + open SELECT policy
-- =============================================================


-- -----------------------------------------------------------
-- FIX 1-3: Set security_invoker on views
-- (Postgres 15+; Supabase supports this)
-- This ensures the views respect the *caller's* permissions
-- and RLS policies, not the view owner's.
-- -----------------------------------------------------------

ALTER VIEW public.active_duties SET (security_invoker = on);
ALTER VIEW public.active_store_bundles SET (security_invoker = on);
ALTER VIEW public.active_forge_recipes SET (security_invoker = on);


-- -----------------------------------------------------------
-- FIX 4: Enable RLS on content_version
-- This is a read-only content table (only service_role writes),
-- so we add a permissive SELECT policy for all authenticated
-- and anon users, matching the other content tables.
-- -----------------------------------------------------------

ALTER TABLE public.content_version ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Content version is publicly readable"
    ON public.content_version FOR SELECT
    USING (TRUE);


-- =============================================================
-- DONE
-- =============================================================
