# QuestBond — Agent Work Assignments

> **How to use this document**: Tell the agent "You are Agent [NUMBER]. Read `GAME_DESIGN.md` first, then read `AGENT_ASSIGNMENTS.md` and find your assignment. Do your work."
>
> **Rule**: Every agent MUST read `GAME_DESIGN.md` before starting any work. It is the single source of truth for all design decisions. Pay special attention to §3 (App Navigation Map) and §4 (Visual & Implementation Rules).

---

## Execution Order

```
Step 1:  Agent 0  (alone)           → Phase -1: Data Architecture
Step 2:  Agent 1 + Agent 2          → Phase 0: Core Loop + Onboarding (parallel)
Step 3:  Agent 5  (alone)           → Phase 1a: Content Pipeline (builds ContentManager)
Step 4:  Agent 3 + Agent 4 + Agent 6 + Agent 7 (parallel) → Phase 1b: Loot + Forge + Cards + Content
Step 5:  Agent 8  (alone)           → Phase 2: Party System
Step 6:  Agent 9  (alone)           → Phase 3: Expeditions
Step 7:  Agent 10 (alone)           → Phase 4: Research Tree
Step 8:  Agent 11 (alone)           → Phase 5: Prestige System
```

**Total: 11 agents, 8 steps. Steps 2 and 4 run agents in parallel.**

---

## Phase -1: Data Architecture

### Agent 0 — Data Sync & Settings
**Runs**: Alone. Must complete before anything else starts.

**Why first**: Creates SyncManager that ALL subsequent agents use for data writes. Without this, every agent would write to local-only SwiftData and we'd have to retrofit later.

**Scope**: Cloud sync infrastructure + Settings screen (App Store requirement).

**Files to modify:**
- `SupabaseService.swift` — expand `syncCharacterData()` to push comprehensive JSONB snapshot (all fields, daily counters, dates, trackers). Add sync methods for achievements, tasks, goals, mood entries.
- `PlayerCharacter.swift` — ensure all fields serialize for cloud snapshot. Add `lastSyncTimestamp` for conflict resolution.
- `GameEngine.swift` — every write path calls `SyncManager.queue()` after local SwiftData write
- `AchievementTracker.swift` — on unlock → write to `player_achievements` via SyncManager
- `CouplesQuestApp.swift` — on launch → trigger cloud pull + merge before UI loads. Add one-time "Backing up your progress..." screen for existing users.

**New files to create:**
- `SyncManager.swift` — queue local writes for async cloud push, flush every 30s + on app background, retry with exponential backoff, timestamp-based last-write-wins conflict resolution, subtle "sync pending" icon after 3 consecutive failures
- `SettingsView.swift` — gear icon in Character tab (top-right). Sections: Account (email, sign-out, delete account, data export), Audio (mute, volume, SFX on/off), Notifications (push preferences, quiet hours), Meditation (default duration, bell, ambient), Gameplay (auto-salvage, confirmation toggles, analytics opt-in), Privacy (location, HealthKit, mood sharing toggle), About (version, credits, feedback link)

**New migration:**
- `006_player_sync_tables.sql` — tables: `player_achievements`, `player_tasks`, `player_goals`, `player_daily_state`, `player_mood_entries`, `player_arena_runs`, `player_dungeon_runs`, `player_mission_history`

**Design doc sections**: §25 (Data Architecture & Sync Strategy), §41 (Settings Screen)

**Deliverables:**
- [ ] Write and run migration `006_player_sync_tables.sql` on Supabase
- [ ] Expand `profiles.character_data` JSONB to include ALL fields
- [ ] SyncManager service (queue → batch 30s → flush on background → retry → conflict resolution)
- [ ] App-launch sync: pull from Supabase, merge with local SwiftData
- [ ] One-time bulk upload screen for existing users ("Backing up your progress...")
- [ ] Achievement sync on unlock
- [ ] Task sync (all tasks — self + partner) to `player_tasks`
- [ ] Goal sync to `player_goals`
- [ ] Mood sync to `player_mood_entries`
- [ ] Bond data migration to Supabase `parties` table
- [ ] SettingsView with all sections
- [ ] Account deletion flow (immediate, type DELETE to confirm, wipes Supabase + local SwiftData)
- [ ] Data export (JSON dump of tasks, achievements, goals, mood entries, analytics)
- [ ] Test: reinstall app → verify all data recovers from cloud

---

## Phase 0: Foundation & Polish

### Agent 1 — Core Loop & Existing Systems
**Runs**: Parallel with Agent 2. Start at the same time. Agent 1 is the more important of the two.

**Scope**: Make task completion feel amazing AND update existing systems that don't depend on Phase 1 (ContentManager). This is the biggest agent — the core loop must feel good or nothing else matters.

**Files to modify:**
- `GameEngine.swift` — add loot rolls to task completion, class task affinity bonus (+15% EXP for matching category), opportunity cost messaging (replace penalties), verification tier reward multipliers, meditation Wisdom buff
- `GameTask.swift` — add routine bundle support, streak freeze integration
- `TaskDetailView.swift` — enhance completion moment (haptic + sound + card animation + loot roll)
- `TasksView.swift` — add swipe-to-complete on habit cards, add mini-game free play access
- `HomeView.swift` — add weekly progress summary card, goal progress widget, leaderboard summary card ("This Week's Leader: Alex — 42 tasks"), weather task suggestion line
- `PlayerCharacter.swift` — add category mastery tracking, personal records, login streak fields
- `DutyBoardGenerator.swift` — add 5th bonus duty (unlocks after completing 4), add 50g paid refresh, add loot drops to duty completion (same rates as tasks)
- `VerificationEngine.swift` — add verification tier system (Quick 1.0x → Standard 1.15x → Verified 1.3x → Party-verified 1.5x EXP multiplier + loot chance bonus)
- `WellnessTabContent.swift` — add wellness achievements display
- `MeditationView.swift` — on completion, grant +5% Wisdom buff for 24hr
- `CouplesLeaderboardView.swift` → rename to `PartyLeaderboardView.swift`, support 1-4 members, add fun titles per member, add solo personal records fallback
- `SudokuGameView.swift` — keep Wisdom stat bonus
- `MemoryMatchGameView.swift` — change stat bonus from Wisdom → Luck
- `MathBlitzGameView.swift` — keep Wisdom stat bonus
- `WordSearchGameView.swift` — change stat bonus from Wisdom → Charisma
- `Game2048View.swift` — change stat bonus from Wisdom → Dexterity

**New files to create:**
- `RoutineBundle.swift` — model for grouping 3-6 habits into a named routine

**Design doc sections**: §7 (IRL Task Experience), §19 (Class System — Task Affinity), §28 (Duty Board & Mini-Games), §30 (Goals — HomeView widget), §31 (Wellness — Wisdom buff + achievements), §33 (Arena — leaderboard), §35 (Verification — reward tiers), §39 (Leaderboard — rename + placement)

**Deliverables:**
- [ ] Haptic + sound + card animation on every task completion
- [ ] Loot roll chance on task completion (5-8% equip, 30-40% materials, 15-20% consumables)
- [ ] Swipe-to-complete on habit cards
- [ ] Routine Bundle model + completion bonus (+50% EXP)
- [ ] Remove penalties for missed habits → opportunity cost messaging
- [ ] Streak freeze consumable integration
- [ ] Category mastery tracking (count + level per category)
- [ ] Personal records (most tasks/day, longest streak per category)
- [ ] Weekly progress summary card on HomeView
- [ ] Class task affinity bonus (+15% EXP for matching category)
- [ ] Class-flavored completion messages
- [ ] Verification tier reward multipliers (1.0x/1.15x/1.3x/1.5x)
- [ ] Duty board: 5th bonus duty + 50g paid refresh + loot drops
- [ ] Mini-game stat diversification (Memory→Luck, Word Search→Charisma, 2048→Dexterity)
- [ ] Mini-game free play access (button in Tasks tab, no stat bonus outside duty)
- [ ] Meditation Wisdom buff (+5% for 24hr on completion)
- [ ] Wellness achievements: "Inner Peace" (7d meditation), "Self-Aware" (30d mood), "Zen Master" (30d meditation)
- [ ] Leaderboard: rename to Party, support 1-4 members, fun titles, solo fallback
- [ ] Leaderboard summary card on HomeView
- [ ] Goal progress widget on HomeView (top active goal progress bar)
- [ ] Weather task suggestion on HomeView ("Rainy day — great for indoor tasks")

---

### Agent 2 — Onboarding & Retention
**Runs**: Parallel with Agent 1. Can build most things independently. Needs Agent 1's task completion animation done before wiring up the onboarding reward demo.

**Scope**: First-time user experience and keeping users coming back.

**Files to modify:**
- `ContentView.swift` — integrate onboarding flow check and welcome-back detection
- `CouplesQuestApp.swift` — add absence detection on launch, re-engagement notification scheduling on app background
- `PushNotificationService.swift` — add re-engagement notifications (2d/5d/14d after last open), frequency cap (max 2/day), evening batch summary, remove daily reset notification
- `PlayerCharacter.swift` — add `hasCompletedOnboarding`, `loginStreakDay`, `lastLoginRewardDate`, `comebackGiftClaimed`

**New files to create:**
- `OnboardingView.swift` — post-character-creation guided flow: first task creation → reward demo (uses Agent 1's completion animation) → quick tour tooltips (Character, Adventures, Party tabs) → starter equipment gift → optional habit setup with category suggestions
- `WelcomeBackView.swift` — overlay on return after 3+ day absence. Scale gifts by absence: 3d (small gold), 7d (gold + consumable), 14d (gold + consumable + streak armor), 30d (gold + rare consumable + equipment)
- `DailyLoginRewardView.swift` — 7-day cycle reward calendar. Claim on first open each day. Day 7 = best reward. Cycle resets.

**Design doc sections**: §20 (Onboarding / First 5 Minutes), §21 (Retention & Re-engagement)

**Deliverables:**
- [ ] Post-creation onboarding flow (first task → reward demo → quick tour → starter gift → habit setup)
- [ ] `hasCompletedOnboarding` flag — skip onboarding for existing users
- [ ] Breadcrumb quest log on HomeView (first 7 days only, guided "next step" card, disappears after)
- [ ] Daily login reward (7-day cycle, escalating rewards, claim on open)
- [ ] Welcome back screen with scaled comeback gifts (3d/7d/14d/30d tiers)
- [ ] Streak recovery offer on return (free Streak Armor)
- [ ] Re-engagement push notifications (2d/5d/14d after last open, max 3 per lapse period)
- [ ] Push notification frequency cap (max 2 per day across all notification types)
- [ ] Remove daily reset notification (noise)
- [ ] Evening batch summary notification for party activity

---

## Phase 1a: Content Pipeline

### Agent 5 — Content Pipeline & Server Migration
**Runs**: Alone. Must complete ContentManager before Agents 3, 4, 6, 7 start.

**Scope**: Move all hard-coded content to Supabase. Build ContentManager. Seed data. Also handle the existing-system updates that depend on ContentManager.

**Files to modify:**
- `SupabaseService.swift` — add content fetching methods
- `GameEngine.swift` — read drop rates from ContentManager
- `DungeonEngine.swift` — load dungeons from ContentManager
- `DutyBoardGenerator.swift` — load duties from ContentManager
- `StoreView.swift` / `StorefrontSection.swift` / `ShopGenerator` — load from ContentManager
- `DailyQuest.swift` — expand quest pool with new types (forgeItem, useConsumable, completeArenaWave, checkMood, completeDuty, partyTaskSync, attemptCardContent). Move definitions to server-driven `content_quests` table.
- `ShopkeeperDialogue.swift` / `ForgekeeperDialogue.swift` — load dialogue from `content_narratives` table

**New files to create:**
- `ContentManager.swift` — central content cache: version check against `content_version` table → fetch all content tables if version bumped → store locally (SwiftData or JSON cache) → provide typed access. Bundle fallback JSON snapshot in app binary for first-run-offline.

**Files to eventually remove** (after ContentManager verified stable):
- `EquipmentCatalog.swift` (1,198 lines)
- `MilestoneGearCatalog.swift` (392 lines)
- `GearSetCatalog.swift` (327 lines)

**Design doc sections**: §24 (Content Pipeline), §27 (Daily Quest — server-driven), §37 (NPC — server dialogue)

**Deliverables:**
- [ ] Run migration `005_content_tables.sql` on Supabase (if not already done)
- [ ] Write seed script (copy existing Swift catalog data → Supabase content tables)
- [ ] ContentManager service (version check → fetch → cache → typed access)
- [ ] Update LootGenerator to read from ContentManager
- [ ] Update DungeonEngine to load dungeons from ContentManager
- [ ] Update GameEngine for missions and drop rates from ContentManager
- [ ] Update ForgeView for server-driven recipes from ContentManager
- [ ] Update StoreView/ShopGenerator to load from ContentManager
- [ ] Update DutyBoardGenerator to load duties from ContentManager
- [ ] Bundle fallback JSON snapshot for offline first-run
- [ ] Add `content_achievements` table for expanded achievement definitions
- [ ] Add `content_quests` table for daily quest definitions (7 new quest types)
- [ ] Add weekly bonus quest logic (5/7 daily quest days → weekly reward chest)
- [ ] NPC dialogue loads from `content_narratives` table (Shopkeeper + Forgekeeper)

---

## Phase 1b: Loot, Forge, Cards, Content

### Agent 3 — Loot System & Equipment
**Runs**: Parallel with Agents 4, 6, 7. Starts after Agent 5 completes ContentManager.

**Scope**: Make every drop interesting. Affixes, pity system, equipment expansion, gear sets.

**Files to modify:**
- `Equipment.swift` — add `prefix: EquipmentAffix?`, `suffix: EquipmentAffix?` properties, add Trinket slot
- `LootTable.swift` / `LootGenerator` — pity system, affix rolling, content-specific drop tables, class affix preference (+10% weight for matching stat)
- `PlayerCharacter.swift` — add `pityCounters: [String: Int]`
- `InventoryView.swift` — show affixes on equipment cards, 4-slot display
- `CharacterView.swift` — 4-slot equipment display (add Trinket)

**New files to create:**
- `EquipmentAffix.swift` — affix model, affix pool (reads from ContentManager `content_affixes`), rolling logic

**Design doc sections**: §8 (Loot System Redesign), §9 (Equipment Slots), §10 (Gear Sets), §19 (Class — AFK Combat Model)

**Deliverables:**
- [ ] Pity counters per content type (tasks/dungeons/missions)
- [ ] Bad luck protection in LootGenerator (hard guarantee at thresholds)
- [ ] EquipmentAffix model with prefix/suffix pool
- [ ] Affix rolling based on rarity (0% Common → 100%/80% Legendary)
- [ ] Equipment slot expansion (3 → 4, add Trinket)
- [ ] Update catalog mapping (cloaks/belts/charms/bracelets → Trinket slot)
- [ ] Gear sets: 2-piece activation (any 2 of 3), upgrade to Epic rarity
- [ ] Class affix preference (+10% weight for matching stat)
- [ ] Equipment detail UI showing affixes
- [ ] Class-specific affixes ("Berserker's Fury: +3 STR" — class-only equip)

---

### Agent 4 — Forge & Economy
**Runs**: Parallel with Agents 3, 6, 7. Starts after Agent 5 completes ContentManager.

**Scope**: Unify the forge, implement enhancement overhaul, balance the economy.

**Files to modify:**
- `Views/Forge/ForgeView.swift` — complete rewrite as unified 4-station forge (Craft, Enhance, Salvage, Affix tabs)
- `Views/Inventory/ForgeView.swift` — **delete** (merged into main ForgeView)
- `GameEngine.swift` — enhancement logic (server-driven rules from `content_enhancement_rules`), salvage logic, consumable crafting
- `Consumable.swift` — add new types (Material Magnet, Luck Elixir, Party Beacon, Affix Scroll, Forge Catalyst), add Common tier consumables, herb crafting recipes

**Design doc sections**: §12 (Consumables Overhaul), §13 (Forge Redesign), §14 (Economy Balance)

**Deliverables:**
- [ ] Unified ForgeView with 4 station tabs: Craft, Enhance, Salvage, Affix
- [ ] Remove Forge Shards currency (salvage returns materials directly)
- [ ] Shard → Gold conversion for existing players (1 shard = 10 gold)
- [ ] Enhancement overhaul: failure chance at +4, critical enhancement, server-driven rules
- [ ] Affix Station: apply Affix Scrolls, re-roll affixes with escalating gold cost
- [ ] Consumable crafting from Herbs (5-8 recipes at launch)
- [ ] Auto-salvage toggle setting
- [ ] New consumable types
- [ ] Affix Scrolls available in Store at 800 gold
- [ ] Forge sound effects (hammer, anvil ring, shatter, crumble, magic swirl) + haptics

---

### Agent 6 — Monster Cards & Bestiary
**Runs**: Parallel with Agents 3, 4, 7. Starts after Agent 5 completes ContentManager.

**Scope**: Card collection system, bestiary view, integration with dungeon/arena/raid.

**Files to modify:**
- `DungeonEngine.swift` — add card drop rolls after successful rooms (10-15% per room)
- `GameEngine.swift` — add card drops to arena milestones (20%), guaranteed card from raid boss
- `CharacterView.swift` — add Bestiary as 5th pill tab

**New files to create:**
- `MonsterCard.swift` — card model, card catalog (reads from `content_cards` via ContentManager), drop logic
- `BestiaryView.swift` — card grid (collected vs undiscovered), total bonus summary, milestones, Card Collector NPC at top

**Design doc sections**: §11 (Monster Card Collection)

**Deliverables:**
- [ ] MonsterCard model (syncs with `player_cards` Supabase table)
- [ ] Define ~50 cards across dungeon themes, arena, raid boss (seed into `content_cards`)
- [ ] Card drop logic in DungeonEngine (10-15% per room)
- [ ] Card drops at arena milestones (20% at waves 15, 25, etc.)
- [ ] Guaranteed card from raid boss (boss-exclusive card per template)
- [ ] BestiaryView as 5th tab in CharacterView (grid, progress, total bonus)
- [ ] Card Collector NPC at top of Bestiary ("Only 3 more Forest cards to go!")
- [ ] Collection milestone rewards (10/25/50/75/100 cards)
- [ ] Card discoveries in party feed
- [ ] Card passive bonuses applied to Power Score calculation
- [ ] Card sounds (reveal, collection chime, page turn) + haptics

---

### Agent 7 — Dungeon / Arena / Training Content & Combat Expansion
**Runs**: Parallel with Agents 3, 4, 6. Starts after Agent 5 completes ContentManager.

**Scope**: Author new content to fill level gaps and rarity tiers. Update arena, raid boss, and dungeon engines with decided features.

**Content to author (seed into Supabase `content_*` tables via seed scripts):**
- 8+ new dungeon templates covering Lv15–100 gaps
- 10+ new AFK mission templates filling Rare + Legendary tiers
- Room pool expansion: 8–10 rooms per dungeon (pool, not fixed list)
- 6-8 raid boss templates for weekly rotation
- 6 arena modifier definitions for weekly rotation
- 3-5 arena-exclusive monster cards
- Monster cards for each new dungeon theme (3–5 per theme)

**Files to modify:**
- `DungeonEngine.swift` — add room pool shuffle system (select N from pool per run), add class-gated bonus rooms
- `GameEngine.swift` — arena infinite scaling (remove 10-wave cap), arena milestone rewards, raid boss party scaling (sublinear: 1x/1.8x/2.4x/3.0x), raid boss loot table
- `ArenaView.swift` — update for infinite waves, display weekly modifier badge, show milestone reward preview
- `RaidBossView.swift` — update for party scaling (1-4 members), add boss loot display, add party member damage bars
- `RaidBoss.swift` — add loot table (gold + rare equip chance + guaranteed boss card), boss template rotation, infinite tier scaling (tier = ceil(avg level / 10))
- `Arena.swift` — remove 10-wave cap, add modifier system

**Design doc sections**: §26 (Dungeon/Arena/Training Content Expansion), §32 (Raid Boss), §33 (Arena), §34 (Class Evolution — class-gated rooms, class-specific approaches)

**Deliverables:**
- [ ] 8+ new dungeon templates (Lv15–100) seeded into `content_dungeons`
- [ ] Room pool system: 8–10 rooms defined, 5–7 selected per run (shuffle on re-run)
- [ ] Bonus rooms (rare spawn, better loot) in dungeon room pools
- [ ] Class-gated bonus rooms ("Mage Door" only Mages enter)
- [ ] 10+ new AFK mission templates across all 5 rarity tiers seeded into `content_missions`
- [ ] Arena extended beyond 10 waves (infinite, ~8-10% difficulty scaling per wave)
- [ ] Arena milestone rewards at waves 5/10/15/20/25+ (see §33 for reward table)
- [ ] 6 weekly arena modifiers (Berserker, Endurance, Glass Cannon, Boss Rush, Time Trial, Elemental Fury)
- [ ] 3-5 arena-exclusive monster cards at milestone waves
- [ ] Class-specific arena approaches (Berserker "Rampage", Guardian "Shield Wall", etc.)
- [ ] Raid boss party scaling (sublinear: solo=1x HP, 2=1.8x, 3=2.4x, 4=3.0x)
- [ ] Raid boss infinite tier scaling (tier = ceil(avg party level / 10), HP = 3000 × tier × party factor)
- [ ] Raid boss loot table (gold + consumable + 15-25% rare+ equip + guaranteed boss card)
- [ ] 6-8 raid boss templates with modifiers in `content_raids`
- [ ] Raid boss weekly rotation from template pool
- [ ] Quest Giver NPC at top of Adventures Hub (contextual dialogue)
- [ ] Arena sounds (wave horn, clear sting, milestone fanfare) + haptics
- [ ] Raid boss sounds (heavy impact, roar, victory) + haptics

---

## Phase 2: Party System

### Agent 8 — Party Model & Social
**Runs**: Alone. Starts after Phase 1 completes.

**Scope**: Expand from couples to 1-4 member parties. Model changes, UI renaming, party features, shared goals.

**Files to modify:**
- `Bond.swift` — refactor to PartyBond (or new file). `partnerID: UUID` → `memberIDs: [UUID]` (max 4)
- `PartnerView.swift` → rename to `PartyView.swift` — complete expansion
- `QRPairingView.swift` — support inviting multiple members (up to 3 allies)
- `AssignTaskView.swift` — assign to any party member
- `PendingConfirmationsView.swift` — any member can confirm
- `DungeonEngine.swift` — 2-4 player co-op with party power scaling (diminishing returns)
- `GameEngine.swift` — party streak (all members 1+ task/day), party streak bonus tiers (3/7/14/30 day)
- `GoalsView.swift` / `GoalDetailView.swift` — add shared party goal creation + tracking

**New files to create:**
- `PartyBond.swift` — extended bond model for 1-4 members (or refactor Bond.swift)
- `PartyFeedView.swift` — activity feed with Realtime subscription (task completions, drops, cards, levels, achievements)

**Design doc sections**: §5 (Pivot), §6 (Party System), §30 (Goals — shared party goals)

**Deliverables:**
- [ ] All "Partner"/"Couples" renaming in UI and code
- [ ] Bond → PartyBond model (memberIDs array, max 4)
- [ ] Supabase `parties` + `party_feed` integration
- [ ] Party power scaling with diminishing returns (1.0x/1.5x/1.85x/2.1x)
- [ ] Party streak (all members must complete 1+ task/day)
- [ ] Party streak bonus tiers (3-day +10% EXP, 7-day +15% EXP +10% Gold, 14-day, 30-day)
- [ ] Party feed with Realtime subscription
- [ ] Invite flow (QR or link, up to 3 allies)
- [ ] Party member list view (avatars, levels, stats, activity)
- [ ] Co-op dungeon for 2-4 players
- [ ] Shared Bestiary view (see which cards any member found)
- [ ] Shared party goals (create together, track individually, party reward on completion)
- [ ] Party-verified task verification (any member can confirm)
- [ ] Party mood sharing (triple opt-in: Settings toggle + per-mood confirm + subtle avatar icon only)

---

## Phase 3: Expeditions

### Agent 9 — Expedition System
**Runs**: Alone. Can start after Phase 1 completes (parallel with or after Phase 2).

**Scope**: Long-duration AFK content with stages, narrative, and exclusive loot.

**Files to modify:**
- `AdventuresHubView.swift` — add Expeditions as 5th category in horizontal picker
- `GameEngine.swift` — stage completion and reward resolution
- `PushNotificationService.swift` — stage completion push notifications

**New files to create:**
- `Expedition.swift` — Expedition + ExpeditionStage + ActiveExpedition models
- `ExpeditionView.swift` — launch, progress, stage results, claim rewards

**Design doc sections**: §16 (Expedition System)

**Deliverables:**
- [ ] Expedition model with multi-stage JSONB structure
- [ ] ActiveExpedition model (syncs with Supabase `active_expeditions`)
- [ ] Expedition template pool (rotating, reads from ContentManager `content_expeditions`)
- [ ] Expedition Key item (drops from Hard+ dungeons)
- [ ] ExpeditionView (launch → progress → results → claim)
- [ ] Stage completion with push notifications
- [ ] Expedition-exclusive loot table
- [ ] Party expedition support (combined stats)
- [ ] Narrative log per stage
- [ ] Expedition sounds (departure horn, stage complete, treasure chest) + haptics

---

## Phase 4: Passive Progression

### Agent 10 — Research Tree
**Runs**: Alone. Starts after Phase 1 completes.

**Scope**: Permanent upgrade system with 3 branches.

**New files to create:**
- `ResearchTree.swift` — research node model, tree structure, 3 branches (Combat, Efficiency, Fortune)
- `ResearchView.swift` — tree visualization, node detail, progress tracking

**Design doc sections**: §18 (Passive Progression Layer)

**Deliverables:**
- [ ] Research tree with 3 branches (Combat, Efficiency, Fortune)
- [ ] Node costs (materials + Research Tokens + gold + time)
- [ ] Research timer (like mission timer)
- [ ] Apply research bonuses to GameEngine calculations (Power Score, EXP, drops)
- [ ] Research Token as mission-exclusive drop

---

## Phase 5: End-Game

### Agent 11 — Prestige System
**Runs**: Alone. Starts after Phase 0 completes (low dependency).

**Scope**: Level 100+ content. Paragon levels and eventually Rebirth.

**Files to modify:**
- `PlayerCharacter.swift` — add paragon level, rebirth count, permanent bonuses
- `GameEngine.swift` — handle leveling beyond 100 (Paragon levels: +1 random stat + gold each)
- `CharacterView.swift` — display paragon level, rebirth star on avatar frame

**New files to create:**
- `RebirthView.swift` — prestige confirmation screen (shows what you keep/lose/gain)

**Design doc sections**: §22 (End-Game / Prestige System)

**Deliverables:**
- [ ] Paragon levels beyond 100 (infinite, +1 random stat + small gold each)
- [ ] Rebirth system (reset level/class, keep gear/cards/achievements, gain permanent stacking bonus)
- [ ] Rebirth star visual marker on avatar frame
- [ ] Rebirth count visible in party profile
- [ ] Rebirth achievements (2)
- [ ] Class resets on rebirth → player picks new starter class → new evolution path

---

## Cross-Cutting Concerns

### All Agents — Shared Rules

1. **Read `GAME_DESIGN.md` first.** Every decision is documented there. Pay special attention to §3 (App Navigation Map) for where your features live and §4 (Visual & Implementation Rules) for how to build them.
2. **Build-verify after every change.** Run `xcodebuild` and fix errors before declaring done.
3. **Register new files** in `project.pbxproj`.
4. **Use named colors** from `Colors.xcassets` (AccentGold, CardBackground, BackgroundTop, BackgroundBottom, etc.). Never use hardcoded colors.
5. **Don't change visual design.** Use the existing card pattern, font (Avenir), spacing, corner radii, shadows, and gradients. See §4 in GAME_DESIGN.md.
6. **Use out-of-the-box SwiftUI.** No third-party UI libraries. No UIKit bridges unless absolutely necessary. SF Symbols for icons. Swift Charts for graphs.
7. **SwiftData predicates**: Don't use bare enum access inside `#Predicate`. Use computed property filters.
8. **SyncManager**: Every write to SwiftData must also call `SyncManager.queue()` to sync to cloud.
9. **Content from server**: If your feature reads game content (equipment, dungeons, cards, etc.), read from `ContentManager` — not static Swift arrays.
10. **Power Score**: If your feature affects AFK combat outcomes, integrate with the unified Power Score formula (§19 in GAME_DESIGN.md).
11. **Party feed**: If your feature creates a noteworthy event (loot drop, card discovery, level up, achievement), add a party feed entry.
12. **Achievements**: If your feature creates a trackable milestone, add an achievement definition.
13. **Audio + Haptics**: Every key action needs a sound effect (via AudioManager) paired with a matching haptic.

---

*This document should be updated as agents complete their work. Coordinate through `GAME_DESIGN.md` for design decisions.*
