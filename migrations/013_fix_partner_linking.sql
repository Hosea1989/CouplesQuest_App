-- =============================================================
-- 013: Fix Partner Linking (QR instant link)
--
-- Two issues:
-- 1. RLS on profiles only allows auth.uid() = id for UPDATE,
--    so Phone B cannot set partner_id on Phone A's profile.
--    Fix: SECURITY DEFINER function that sets partner_id on
--    both profiles in a single trusted call.
--
-- 2. Realtime is not enabled for profiles, so the QR displayer's
--    subscription never fires when partner_id is set.
--    Fix: Add profiles to supabase_realtime publication.
-- =============================================================

-- -----------------------------------------------------------
-- 1. SECURITY DEFINER function to link two users as partners
--    Callable by any authenticated user; sets partner_id on
--    both the caller's and the target's profile rows.
-- -----------------------------------------------------------
create or replace function public.link_partners(target_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    caller_id uuid := auth.uid();
begin
    -- Validate caller is authenticated
    if caller_id is null then
        raise exception 'Not authenticated';
    end if;

    -- Cannot pair with yourself
    if caller_id = target_user_id then
        raise exception 'Cannot pair with yourself';
    end if;

    -- Verify target user exists
    if not exists (select 1 from public.profiles where id = target_user_id) then
        raise exception 'Target user not found';
    end if;

    -- Set partner_id on both profiles
    update public.profiles
    set partner_id = target_user_id
    where id = caller_id;

    update public.profiles
    set partner_id = caller_id
    where id = target_user_id;
end;
$$;

-- Grant execute to authenticated users
grant execute on function public.link_partners(uuid) to authenticated;

-- -----------------------------------------------------------
-- 1b. SECURITY DEFINER function to UNLINK partners
--     Clears partner_id on both the caller's and their
--     partner's profile rows.
-- -----------------------------------------------------------
create or replace function public.unlink_partners()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    caller_id uuid := auth.uid();
    partner uuid;
begin
    if caller_id is null then
        raise exception 'Not authenticated';
    end if;

    -- Get current partner
    select partner_id into partner
    from public.profiles
    where id = caller_id;

    if partner is null then
        return; -- already unlinked
    end if;

    -- Clear partner_id on both profiles
    update public.profiles
    set partner_id = null
    where id = caller_id;

    update public.profiles
    set partner_id = null
    where id = partner;
end;
$$;

grant execute on function public.unlink_partners() to authenticated;

-- -----------------------------------------------------------
-- 2. Enable Realtime on the profiles table so that the QR
--    displayer's subscription can detect partner_id changes.
-- -----------------------------------------------------------
-- Note: This is idempotent — if profiles is already in the
-- publication, Postgres will raise a notice but not fail.
-- We use DO block to handle the case gracefully.
do $$
begin
    alter publication supabase_realtime add table public.profiles;
exception
    when duplicate_object then
        raise notice 'profiles already in supabase_realtime publication';
end;
$$;
