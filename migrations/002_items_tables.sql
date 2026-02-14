-- =============================================================
-- DuoCraft Migration 002 — Items Tables
-- Run this in the Supabase SQL Editor.
-- Safe to run on a database that already has the base schema
-- (profiles, partner_requests, partner_interactions).
-- =============================================================

-- -----------------------------------------------------------
-- EQUIPMENT (player-owned gear)
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

create index if not exists idx_equipment_owner on public.equipment(owner_id);

alter table public.equipment enable row level security;

create policy "Owner can read own equipment"
    on public.equipment for select
    using (auth.uid() = owner_id);

create policy "Partner can view partner equipment"
    on public.equipment for select
    using (
        owner_id = (select partner_id from public.profiles where id = auth.uid())
    );

create policy "Owner can insert own equipment"
    on public.equipment for insert
    with check (auth.uid() = owner_id);

create policy "Owner can update own equipment"
    on public.equipment for update
    using (auth.uid() = owner_id);

create policy "Owner can delete own equipment"
    on public.equipment for delete
    using (auth.uid() = owner_id);

-- Reuse the handle_updated_at() function from the base schema
create trigger on_equipment_updated
    before update on public.equipment
    for each row execute function public.handle_updated_at();

-- -----------------------------------------------------------
-- CONSUMABLES (potions, boosts, food, scrolls)
-- -----------------------------------------------------------
create table if not exists public.consumables (
    id                  uuid primary key default gen_random_uuid(),
    owner_id            uuid not null references public.profiles(id) on delete cascade,

    name                text not null,
    description         text not null default '',
    consumable_type     text not null check (consumable_type in (
        'HP Potion', 'EXP Boost', 'Gold Boost', 'Mission Speed-Up',
        'Streak Shield', 'Stat Food', 'Dungeon Revive', 'Loot Reroll'
    )),
    icon                text not null default 'cross.vial.fill',

    effect_value        int not null default 0,
    effect_stat         text check (effect_stat in ('strength', 'wisdom', 'charisma', 'dexterity', 'luck', 'defense')),
    remaining_uses      int not null default 1,

    acquired_at         timestamptz default now()
);

create index if not exists idx_consumables_owner on public.consumables(owner_id);

alter table public.consumables enable row level security;

create policy "Owner can read own consumables"
    on public.consumables for select
    using (auth.uid() = owner_id);

create policy "Partner can view partner consumables"
    on public.consumables for select
    using (
        owner_id = (select partner_id from public.profiles where id = auth.uid())
    );

create policy "Owner can insert own consumables"
    on public.consumables for insert
    with check (auth.uid() = owner_id);

create policy "Owner can update own consumables"
    on public.consumables for update
    using (auth.uid() = owner_id);

create policy "Owner can delete own consumables"
    on public.consumables for delete
    using (auth.uid() = owner_id);

-- -----------------------------------------------------------
-- CRAFTING MATERIALS (stacked by type + rarity)
-- -----------------------------------------------------------
create table if not exists public.crafting_materials (
    id                  uuid primary key default gen_random_uuid(),
    owner_id            uuid not null references public.profiles(id) on delete cascade,

    material_type       text not null check (material_type in (
        'Essence', 'Ore', 'Crystal', 'Hide', 'Herb', 'Fragment'
    )),
    rarity              text not null check (rarity in ('Common', 'Uncommon', 'Rare', 'Epic', 'Legendary')),
    quantity            int not null default 0 check (quantity >= 0),

    -- One stack per (owner, type, rarity)
    unique (owner_id, material_type, rarity)
);

create index if not exists idx_crafting_materials_owner on public.crafting_materials(owner_id);

alter table public.crafting_materials enable row level security;

create policy "Owner can read own materials"
    on public.crafting_materials for select
    using (auth.uid() = owner_id);

create policy "Partner can view partner materials"
    on public.crafting_materials for select
    using (
        owner_id = (select partner_id from public.profiles where id = auth.uid())
    );

create policy "Owner can insert own materials"
    on public.crafting_materials for insert
    with check (auth.uid() = owner_id);

create policy "Owner can update own materials"
    on public.crafting_materials for update
    using (auth.uid() = owner_id);

create policy "Owner can delete own materials"
    on public.crafting_materials for delete
    using (auth.uid() = owner_id);

-- -----------------------------------------------------------
-- REALTIME — add equipment for live partner gear updates
-- (partner_interactions and partner_requests were already added
--  in the base schema, so we only add equipment here)
-- -----------------------------------------------------------
alter publication supabase_realtime add table public.equipment;
