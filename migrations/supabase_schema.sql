-- =============================================================
-- DuoCraft Supabase Schema
-- Run this in the Supabase SQL Editor to create all tables.
-- =============================================================

-- -----------------------------------------------------------
-- 1. PROFILES
-- Linked to Supabase Auth — one row per user.
-- -----------------------------------------------------------
create table if not exists public.profiles (
    id          uuid primary key references auth.users(id) on delete cascade,
    email       text,
    character_name text,
    character_class text,
    level       int default 1,
    avatar_name text,
    character_data jsonb,
    partner_id  uuid references public.profiles(id) on delete set null,
    partner_code text unique,
    created_at  timestamptz default now(),
    updated_at  timestamptz default now()
);

-- Enable RLS
alter table public.profiles enable row level security;

-- Helper function: get current user's partner_id (SECURITY DEFINER
-- bypasses RLS so policies can look up partner_id without recursion)
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

-- Users can read their own profile
create policy "Users can read own profile"
    on public.profiles for select
    using (auth.uid() = id);

-- Users can read their partner's profile (uses helper to avoid recursion)
create policy "Users can read partner profile"
    on public.profiles for select
    using ( id = public.get_my_partner_id() );

-- Anyone can look up a profile by partner_code (for pairing)
create policy "Anyone can lookup by partner code"
    on public.profiles for select
    using (partner_code is not null);

-- Users can update their own profile
create policy "Users can update own profile"
    on public.profiles for update
    using (auth.uid() = id);

-- Users can insert their own profile (on sign-up)
create policy "Users can insert own profile"
    on public.profiles for insert
    with check (auth.uid() = id);

-- Auto-update updated_at timestamp
create or replace function public.handle_updated_at()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

create trigger on_profiles_updated
    before update on public.profiles
    for each row execute function public.handle_updated_at();

-- -----------------------------------------------------------
-- 2. Auto-create profile on sign-up (trigger)
-- -----------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger as $$
declare
    new_code text;
begin
    -- Generate a unique 6-character partner code
    loop
        new_code := upper(substr(md5(random()::text), 1, 6));
        exit when not exists (select 1 from public.profiles where partner_code = new_code);
    end loop;

    insert into public.profiles (id, email, partner_code)
    values (new.id, new.email, new_code);
    return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function public.handle_new_user();

-- -----------------------------------------------------------
-- 3. PARTNER REQUESTS
-- -----------------------------------------------------------
create table if not exists public.partner_requests (
    id            uuid primary key default gen_random_uuid(),
    from_user_id  uuid not null references public.profiles(id) on delete cascade,
    to_user_id    uuid not null references public.profiles(id) on delete cascade,
    status        text not null default 'pending' check (status in ('pending', 'accepted', 'rejected')),
    created_at    timestamptz default now()
);

alter table public.partner_requests enable row level security;

-- Sender can read their own requests
create policy "Sender can read own requests"
    on public.partner_requests for select
    using (auth.uid() = from_user_id);

-- Receiver can read requests sent to them
create policy "Receiver can read incoming requests"
    on public.partner_requests for select
    using (auth.uid() = to_user_id);

-- Authenticated users can send requests
create policy "Users can send partner requests"
    on public.partner_requests for insert
    with check (auth.uid() = from_user_id);

-- Receiver can update (accept/reject) requests sent to them
create policy "Receiver can update request status"
    on public.partner_requests for update
    using (auth.uid() = to_user_id);

-- -----------------------------------------------------------
-- 4. PARTNER INTERACTIONS (nudges, kudos, challenges)
-- -----------------------------------------------------------
create table if not exists public.partner_interactions (
    id            uuid primary key default gen_random_uuid(),
    from_user_id  uuid not null references public.profiles(id) on delete cascade,
    to_user_id    uuid not null references public.profiles(id) on delete cascade,
    type          text not null check (type in ('nudge', 'kudos', 'challenge', 'task_assigned', 'task_completed', 'task_invited')),
    message       text,
    is_read       boolean default false,
    created_at    timestamptz default now()
);

alter table public.partner_interactions enable row level security;

-- Sender can read interactions they sent
create policy "Sender can read own interactions"
    on public.partner_interactions for select
    using (auth.uid() = from_user_id);

-- Receiver can read interactions sent to them
create policy "Receiver can read incoming interactions"
    on public.partner_interactions for select
    using (auth.uid() = to_user_id);

-- Users can send interactions
create policy "Users can send interactions"
    on public.partner_interactions for insert
    with check (auth.uid() = from_user_id);

-- Receiver can mark interactions as read
create policy "Receiver can update interactions"
    on public.partner_interactions for update
    using (auth.uid() = to_user_id);

-- -----------------------------------------------------------
-- 5. EQUIPMENT (player-owned gear)
-- Stores every piece of equipment a player owns, including
-- stats, enhancement level, equipped status, and an optional
-- catalog_id linking back to the curated EquipmentCatalog.
-- -----------------------------------------------------------
create table if not exists public.equipment (
    id                  uuid primary key default gen_random_uuid(),
    owner_id            uuid not null references public.profiles(id) on delete cascade,

    -- Catalog link (null for procedurally generated items)
    catalog_id          text,

    -- Core identity
    name                text not null,
    description         text not null default '',
    slot                text not null check (slot in ('Weapon', 'Armor', 'Accessory')),
    rarity              text not null check (rarity in ('Common', 'Uncommon', 'Rare', 'Epic', 'Legendary')),

    -- Stats
    primary_stat        text not null check (primary_stat in ('strength', 'wisdom', 'charisma', 'dexterity', 'luck', 'defense')),
    stat_bonus          int not null default 0,
    secondary_stat      text check (secondary_stat in ('strength', 'wisdom', 'charisma', 'dexterity', 'luck', 'defense')),
    secondary_stat_bonus int not null default 0,

    -- Progression
    level_requirement   int not null default 1,
    enhancement_level   int not null default 0 check (enhancement_level between 0 and 10),
    is_equipped         boolean not null default false,

    -- Timestamps
    acquired_at         timestamptz default now(),
    updated_at          timestamptz default now()
);

-- Index for fast lookups by owner
create index if not exists idx_equipment_owner on public.equipment(owner_id);

alter table public.equipment enable row level security;

-- Owner can read their own equipment
create policy "Owner can read own equipment"
    on public.equipment for select
    using (auth.uid() = owner_id);

-- Partner can view their partner's equipment (read-only, uses helper)
create policy "Partner can view partner equipment"
    on public.equipment for select
    using ( owner_id = public.get_my_partner_id() );

-- Owner can insert their own equipment
create policy "Owner can insert own equipment"
    on public.equipment for insert
    with check (auth.uid() = owner_id);

-- Owner can update their own equipment (equip/unequip, enhance, etc.)
create policy "Owner can update own equipment"
    on public.equipment for update
    using (auth.uid() = owner_id);

-- Owner can delete their own equipment (discard, dismantle)
create policy "Owner can delete own equipment"
    on public.equipment for delete
    using (auth.uid() = owner_id);

-- Auto-update updated_at
create trigger on_equipment_updated
    before update on public.equipment
    for each row execute function public.handle_updated_at();

-- -----------------------------------------------------------
-- 6. CONSUMABLES (potions, boosts, food, scrolls)
-- -----------------------------------------------------------
create table if not exists public.consumables (
    id                  uuid primary key default gen_random_uuid(),
    owner_id            uuid not null references public.profiles(id) on delete cascade,

    -- Identity
    name                text not null,
    description         text not null default '',
    consumable_type     text not null check (consumable_type in (
        'HP Potion', 'EXP Boost', 'Gold Boost', 'Mission Speed-Up',
        'Streak Shield', 'Stat Food', 'Dungeon Revive', 'Loot Reroll'
    )),
    icon                text not null default 'cross.vial.fill',

    -- Effect
    effect_value        int not null default 0,
    effect_stat         text check (effect_stat in ('strength', 'wisdom', 'charisma', 'dexterity', 'luck', 'defense')),
    remaining_uses      int not null default 1,

    -- Timestamps
    acquired_at         timestamptz default now()
);

create index if not exists idx_consumables_owner on public.consumables(owner_id);

alter table public.consumables enable row level security;

-- Owner can read their own consumables
create policy "Owner can read own consumables"
    on public.consumables for select
    using (auth.uid() = owner_id);

-- Partner can view partner's consumables (uses helper)
create policy "Partner can view partner consumables"
    on public.consumables for select
    using ( owner_id = public.get_my_partner_id() );

-- Owner can insert consumables
create policy "Owner can insert own consumables"
    on public.consumables for insert
    with check (auth.uid() = owner_id);

-- Owner can update consumables (use / decrement remaining_uses)
create policy "Owner can update own consumables"
    on public.consumables for update
    using (auth.uid() = owner_id);

-- Owner can delete consumed items
create policy "Owner can delete own consumables"
    on public.consumables for delete
    using (auth.uid() = owner_id);

-- -----------------------------------------------------------
-- 7. CRAFTING MATERIALS (stacked by type + rarity)
-- -----------------------------------------------------------
create table if not exists public.crafting_materials (
    id                  uuid primary key default gen_random_uuid(),
    owner_id            uuid not null references public.profiles(id) on delete cascade,

    -- Material identity
    material_type       text not null check (material_type in (
        'Essence', 'Ore', 'Crystal', 'Hide', 'Herb', 'Fragment'
    )),
    rarity              text not null check (rarity in ('Common', 'Uncommon', 'Rare', 'Epic', 'Legendary')),
    quantity            int not null default 0 check (quantity >= 0),

    -- Prevent duplicate stacks: one row per (owner, type, rarity)
    unique (owner_id, material_type, rarity)
);

create index if not exists idx_crafting_materials_owner on public.crafting_materials(owner_id);

alter table public.crafting_materials enable row level security;

-- Owner can read their own materials
create policy "Owner can read own materials"
    on public.crafting_materials for select
    using (auth.uid() = owner_id);

-- Partner can view partner's materials (uses helper)
create policy "Partner can view partner materials"
    on public.crafting_materials for select
    using ( owner_id = public.get_my_partner_id() );

-- Owner can insert materials
create policy "Owner can insert own materials"
    on public.crafting_materials for insert
    with check (auth.uid() = owner_id);

-- Owner can update materials (add/spend quantity)
create policy "Owner can update own materials"
    on public.crafting_materials for update
    using (auth.uid() = owner_id);

-- Owner can delete empty stacks
create policy "Owner can delete own materials"
    on public.crafting_materials for delete
    using (auth.uid() = owner_id);

-- -----------------------------------------------------------
-- 8. Realtime — enable for live updates
-- -----------------------------------------------------------
alter publication supabase_realtime add table public.partner_interactions;
alter publication supabase_realtime add table public.partner_requests;
alter publication supabase_realtime add table public.equipment;

-- -----------------------------------------------------------
-- 9. MIGRATION: Add character_data JSONB column
-- Run this on existing databases that already have the profiles table.
-- -----------------------------------------------------------
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS character_data jsonb;
