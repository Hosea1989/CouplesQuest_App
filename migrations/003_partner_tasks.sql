-- =============================================================
-- DuoCraft Migration 003 — Partner Tasks Table
-- Run this in the Supabase SQL Editor.
-- Enables syncing partner-assigned tasks between devices.
-- =============================================================

-- -----------------------------------------------------------
-- PARTNER TASKS (tasks assigned between partners)
-- -----------------------------------------------------------
create table if not exists public.partner_tasks (
    id                      uuid primary key default gen_random_uuid(),
    created_by              uuid not null references public.profiles(id) on delete cascade,
    assigned_to             uuid not null references public.profiles(id) on delete cascade,

    -- Task details
    title                   text not null,
    description             text,
    category                text not null,
    partner_message         text,
    verification_type       text not null default 'none',
    is_on_duty_board        boolean not null default false,
    due_date                timestamptz,

    -- Status tracking
    status                  text not null default 'pending'
                            check (status in ('pending', 'in_progress', 'completed', 'failed', 'expired')),
    completed_at            timestamptz,

    -- Partner confirmation
    partner_confirmed       boolean not null default false,
    partner_dispute_reason  text,

    -- Timestamps
    created_at              timestamptz default now(),
    updated_at              timestamptz default now()
);

-- Indexes for fast lookups
create index if not exists idx_partner_tasks_created_by on public.partner_tasks(created_by);
create index if not exists idx_partner_tasks_assigned_to on public.partner_tasks(assigned_to);

alter table public.partner_tasks enable row level security;

-- Creator can read tasks they created
create policy "Creator can read own tasks"
    on public.partner_tasks for select
    using (auth.uid() = created_by);

-- Assignee can read tasks assigned to them
create policy "Assignee can read assigned tasks"
    on public.partner_tasks for select
    using (auth.uid() = assigned_to);

-- Creator can insert tasks (assign to partner)
create policy "Creator can insert tasks"
    on public.partner_tasks for insert
    with check (auth.uid() = created_by);

-- Creator can update their own tasks (confirm/dispute)
create policy "Creator can update own tasks"
    on public.partner_tasks for update
    using (auth.uid() = created_by);

-- Assignee can update assigned tasks (complete/start)
create policy "Assignee can update assigned tasks"
    on public.partner_tasks for update
    using (auth.uid() = assigned_to);

-- Creator can delete tasks they created
create policy "Creator can delete own tasks"
    on public.partner_tasks for delete
    using (auth.uid() = created_by);

-- Auto-update updated_at (reuses the function from base schema)
create trigger on_partner_tasks_updated
    before update on public.partner_tasks
    for each row execute function public.handle_updated_at();

-- -----------------------------------------------------------
-- REALTIME — enable for instant partner task delivery
-- -----------------------------------------------------------
alter publication supabase_realtime add table public.partner_tasks;
