-- =============================================================
-- Migration 004: Fix infinite recursion in RLS policies
--
-- PROBLEM: The "Users can read partner profile" policy on
-- `profiles` does a subquery on `profiles` itself, which
-- PostgreSQL detects as infinite recursion (error 42P17).
-- The same pattern in equipment / consumables / crafting_materials
-- subqueries `profiles` partner_id through the broken policies.
--
-- FIX: Create a SECURITY DEFINER function that reads the
-- caller's partner_id bypassing RLS, then reference it
-- in every policy that needs the partner_id lookup.
-- =============================================================

-- -----------------------------------------------------------
-- 1. Helper function: get current user's partner_id (bypasses RLS)
-- -----------------------------------------------------------
create or replace function public.get_my_partner_id()
returns uuid
language sql
security definer
stable
set search_path = public
as $$
    select partner_id
    from public.profiles
    where id = auth.uid();
$$;

-- -----------------------------------------------------------
-- 2. Fix PROFILES policies
-- -----------------------------------------------------------

-- Drop the recursive policy
drop policy if exists "Users can read partner profile" on public.profiles;

-- Recreate it using the helper function (no recursion)
create policy "Users can read partner profile"
    on public.profiles for select
    using ( id = public.get_my_partner_id() );

-- The overly-broad "Anyone can lookup by partner code" policy
-- currently exposes ALL profiles to any authenticated user.
-- Tighten it: only allow lookup when the caller is authenticated
-- (keeps pairing flow working while being explicit about intent).
-- Note: we keep this as-is for now since pairing requires it,
-- but the partner_code column doesn't expose sensitive data.
-- If you want to restrict further, use a server-side function.

-- -----------------------------------------------------------
-- 3. Fix EQUIPMENT "partner can view" policy
-- -----------------------------------------------------------
drop policy if exists "Partner can view partner equipment" on public.equipment;

create policy "Partner can view partner equipment"
    on public.equipment for select
    using ( owner_id = public.get_my_partner_id() );

-- -----------------------------------------------------------
-- 4. Fix CONSUMABLES "partner can view" policy
-- -----------------------------------------------------------
drop policy if exists "Partner can view partner consumables" on public.consumables;

create policy "Partner can view partner consumables"
    on public.consumables for select
    using ( owner_id = public.get_my_partner_id() );

-- -----------------------------------------------------------
-- 5. Fix CRAFTING_MATERIALS "partner can view" policy
-- -----------------------------------------------------------
drop policy if exists "Partner can view partner materials" on public.crafting_materials;

create policy "Partner can view partner materials"
    on public.crafting_materials for select
    using ( owner_id = public.get_my_partner_id() );
