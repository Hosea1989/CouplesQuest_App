# QuestBond — Game Design & Roadmap

> **Working title**: QuestBond (formerly CouplesQuest)
> **Last updated**: 2025-02-11 (All 16 undiscussed features reviewed and decided — Settings, Daily Quests, Duty Board, Store, Goals, Wellness, Raid Boss, Arena, Verification, Class Evolution, Analytics, NPCs, Audio, Leaderboard, Weather, Data Architecture)
> **Status**: Pre-overhaul planning. No code changes yet. This document is the source of truth for all design decisions moving forward.

---

## Table of Contents

**Core Design**
1. [Vision & Identity](#vision--identity)
2. [Current State of the App](#current-state-of-the-app)
3. [App Navigation Map](#app-navigation-map)
4. [Visual & Implementation Rules](#visual--implementation-rules)
5. [The Pivot: From Couples to Parties](#the-pivot-from-couples-to-parties)

**New Systems (Designed)**
6. [Party System (1–4 Members)](#party-system-14-members)
7. [IRL Task Experience Design](#irl-task-experience-design)
8. [Loot System Redesign](#loot-system-redesign)
9. [Equipment Slot Expansion](#equipment-slot-expansion)
10. [Gear Sets Redesign (Simplified)](#gear-sets-redesign-simplified)
11. [Monster Card Collection](#monster-card-collection)
12. [Consumables Overhaul](#consumables-overhaul)
13. [Forge Redesign](#forge-redesign)
14. [Economy Balance (Faucets & Sinks)](#economy-balance-faucets--sinks)
15. [Complete Loot Acquisition Map](#complete-loot-acquisition-map)
16. [Expedition System (New)](#expedition-system-new)
17. [System Interconnection Map](#system-interconnection-map)
18. [Passive Progression Layer](#passive-progression-layer)
19. [Class System Depth & AFK Combat Model](#class-system-depth--afk-combat-model)
20. [Onboarding / First 5 Minutes](#onboarding--first-5-minutes)
21. [Retention & Re-engagement](#retention--re-engagement)
22. [End-Game / Prestige System](#end-game--prestige-system)
23. [Achievements System (Expanded)](#achievements-system-expanded)
24. [Content Pipeline (Server-Driven)](#content-pipeline-server-driven)

**Infrastructure**
25. [Data Architecture & Sync Strategy](#data-architecture--sync-strategy)

**Existing Systems — Content & Expansion (All Decisions Made)**
26. [Dungeon / Arena / Training Content Expansion](#dungeon--arena--training-content-expansion)
27. [Daily Quest System](#daily-quest-system)
28. [Duty Board & Mini-Games](#duty-board--mini-games)
29. [Store & Shop Experience](#store--shop-experience)
30. [Goals System](#goals-system)

**Existing Systems — Features & Polish (All Decisions Made)**
31. [Wellness & Meditation System](#wellness--meditation-system)
32. [Raid Boss System](#raid-boss-system)
33. [Arena System](#arena-system)
34. [Class Evolution System](#class-evolution-system)
35. [Verification & Anti-Cheat](#verification--anti-cheat)
36. [Task Analytics Dashboard](#task-analytics-dashboard)
37. [NPC & Dialogue System](#npc--dialogue-system)
38. [Audio & Sound Design](#audio--sound-design)
39. [Leaderboard (Party Update)](#leaderboard-party-update)
40. [Weather Integration](#weather-integration)
41. [Settings Screen](#settings-screen)

**Planning & Reference**
42. [Launch Scope vs Future Expansion](#launch-scope-vs-future-expansion)
43. [Phased Roadmap](#phased-roadmap)
44. [Competitor & Research Notes](#competitor--research-notes)
45. [Technical Architecture Notes](#technical-architecture-notes)
46. [Open Questions](#open-questions)

---

## Vision & Identity

### What This App Is

A **party-based accountability RPG** where 1–4 friends level up together by completing real-world tasks. Complete tasks, run dungeons, go on expeditions, forge gear, and grow your character — solo or with your party.

### What This App Is NOT

- Not a dating/couples-only app (anyone with a friend can play)
- Not a pure idle clicker (real-world tasks are the core loop)
- Not Habitica (deeper RPG systems, visual character progression, idle content)
- Not a social media app (small parties of 1–4, not communities)

### Core Identity (Never Change These)

1. **Real-world tasks drive all progression.** You cannot level up, get loot, or progress without completing real things.
2. **RPG systems make productivity fun.** Classes, equipment, dungeons, stats — this is a real game, not a to-do list with badges.
3. **Accountability through party bonds.** Friends/partners keep each other honest. The social layer is the retention layer.
4. **AFK/idle content respects your time.** The app works for you when you're away. Come back to rewards, not obligations.

### Target Player

Working adults (20–35) who:
- Want to build better habits but find pure habit trackers boring
- Enjoy RPG/idle game mechanics (grew up on games, still like progression systems)
- Have 1–3 friends or a partner they'd do an accountability challenge with
- Open the app 3–6 times a day for 1–3 minutes each time

---

## Current State of the App

### Tech Stack
- **Language**: Swift 5.9 / SwiftUI
- **Data**: SwiftData (local) + Supabase (cloud sync, auth, realtime)
- **Push**: OneSignal via Supabase Edge Functions
- **Target**: iOS 17.0+

### What's Built (as of Feb 2025)

#### Character System
- Character creation with name, class, zodiac sign, avatar
- 3 starter classes (Warrior, Mage, Archer) with 6 advanced evolutions
- 7 stats: Strength, Wisdom, Charisma, Dexterity, Luck, Defense, Endurance (legacy)
- Level 1–100 with exponential EXP curve (`100 × (level-1)^1.5`)
- Stat point allocation on level-up
- Equipment loadout: 3 slots (Weapon, Armor, Accessory)
- Gear sets (3-piece bonuses) and milestone gear (class-specific unlocks)

#### Task System
- Task creation with categories (Physical, Mental, Social, Household, Wellness, Creative)
- Recurring tasks and habit tracking with streaks
- Verification system: photo, location, HealthKit cross-reference
- Anti-cheat engine (minimum durations, anomaly detection, rapid-completion checks)
- Duty board: daily rotating curated tasks with mini-games (Sudoku, Memory Match, Math Blitz, Word Search, 2048)
- Daily quests: generated objectives scaled to character level
- Goals system with milestone rewards at 25/50/75/100%

#### Partner/Bond System (Current — Couples-Only)
- QR code pairing + manual code entry
- Bond model: level 1–50, bond EXP, bond perks tree (11 perks)
- Partner interactions: nudge, kudos, challenge
- Task assignment between partners
- Task confirmation/dispute system
- Co-op dungeon runs (partner proxy calculation)
- Dual streak bonus
- Weekly raid boss (shared damage)
- Couples leaderboard
- Supabase Realtime subscriptions for live partner data

#### Dungeon System
- Dungeon templates with themed rooms (combat, puzzle, trap, treasure, boss)
- 4 difficulty tiers: Normal, Hard, Heroic, Mythic
- Room approach choices (Aggressive, Analyze, Stealth, etc.)
- Auto-run system with narrative feed
- Arena: escalating waves with daily attempt limits
- Weekly raid boss: timed HP pool, damage from task completion

#### AFK Mission System
- 6 mission types: Combat, Exploration, Research, Negotiation, Stealth, Gathering
- 5 rarity tiers with reward multipliers
- Duration-based with stat requirements
- Success rate calculation from character stats
- Persisted via UserDefaults (survives app restart)
- Single active mission at a time

#### Loot / Economy
- Equipment: 3 slots × 5 rarities, primary + optional secondary stat
- 110 curated catalog items (40 weapons, 35 armor, 35 accessories)
- Procedural generation fallback (20% of drops)
- LootGenerator: rarity rolling, stat rolling, name generation (prefix + base + suffix)
- Forge: craft equipment from 6 material types × 5 rarities, enhance (max +10), salvage
- Store: daily rotating stock, daily deal, consumables, bundles, milestone gear
- Consumables: 8 types (HP potion, EXP boost, gold boost, mission speed-up, streak shield, stat food, dungeon revive, loot reroll)
- Currencies: Gold (primary), Gems (premium), Forge Shards (salvage)

#### Audio & Polish
- AudioManager with sound effects for UI, game events, rewards
- Meditation system with ambient sounds, interval bells
- Level-up celebration overlay
- Achievement celebration overlay
- Toast notification system

#### Backend (Supabase)
- Auth: email/password, Apple Sign-In
- Tables: profiles, partner_requests, partner_interactions, partner_tasks, equipment, consumables, crafting_materials
- RLS policies on all tables
- Realtime subscriptions for partner data
- Edge function: send-push (OneSignal integration)

### What's NOT Built Yet
- Expedition system
- Affix system on equipment
- Pity/bad luck protection on loot
- Party system (1-4 members, currently couples only)
- Passive progression layer (stamps/research tree)
- Collection log
- Auto-salvage rules
- Season/battle pass
- Expanded equipment slots (currently 3)

---

## App Navigation Map

> **Rule: Do NOT add new tabs.** The app has 5 tabs. Every feature lives inside one of them. No exceptions.

### Tab Structure (5 Tabs — Unchanged)

```
┌─────────────────────────────────────────────────────┐
│  Home       Tasks       Adventures    Party    Char  │
│  house.fill checklist   map.fill    heart.fill person│
└─────────────────────────────────────────────────────┘
```

### Tab 1: Home (house.fill) — Dashboard

The Home tab is the "what happened / what should I do" screen. Cards, not actions.

| Card / Section | Status | Notes |
|---|---|---|
| Character Summary (avatar, level, EXP, weather) | ✅ Exists | Add weather icon + temp in header |
| Mood Check-In | ✅ Exists | No change |
| Daily Quests (3+1 + claim) | ✅ Exists | Add weekly bonus progress bar |
| Active Duties (currently active tasks) | ✅ Exists | No change |
| Goals Summary (active goals progress) | ✅ Exists | Ensure top goal shows compact progress bar |
| Active Training (AFK mission status) | ✅ Exists | No change |
| Quick Stats Grid | ✅ Exists | No change |
| Productivity Overview | ✅ Exists | No change |
| Daily Tip | ✅ Exists | No change |
| **Leaderboard Summary Card** | 🆕 New | "This Week's Leader: Alex — 42 tasks" (tap → Party tab). Solo: personal best. |
| **Breadcrumb Quest Log** | 🆕 New | First 7 days only. Guided "next step" card. Disappears after onboarding. |
| **Daily Login Reward** | 🆕 New | Overlay/modal on first open each day. 7-day cycle calendar. Claim → dismiss. |
| **Welcome Back Screen** | 🆕 New | Overlay on return after 3+ day absence. Shows gifts. One-time per return. |
| **Weather Task Suggestion** | 🆕 New | One line below weather display: "Rainy day — great for indoor tasks" |

**Ordering rule:** Actionable cards (login reward, mood check-in, daily quests, active duties) float to top. Informational cards (stats, tip, leaderboard) sit lower.

### Tab 2: Tasks (checklist) — Task Management

The Tasks tab is where work happens. Create, complete, track.

| Section | Status | Notes |
|---|---|---|
| Daily Habits (recurring, streaks) | ✅ Exists | Add swipe-to-complete |
| Duty Board (4 slots, 2-col grid) | ✅ Exists | Add 5th bonus duty after completing 4. Add loot drops. 50g refresh. |
| Partner Quests (assigned by ally) | ✅ Exists | Rename to "Party Quests" |
| Active Tasks (user's tasks) | ✅ Exists | No change |
| Create Task (sheet) | ✅ Exists | No change |
| Task Detail (verification, timer) | ✅ Exists | Add loot roll animation on completion |
| Mini-Games (Sudoku, etc.) | ✅ Exists | Add "Free Play" access outside duty board (no stat bonus) |
| Task Analytics (NavigationLink) | ✅ Exists | Add insights text at top. Low priority. |
| **Routine Bundles** | 🆕 New | Group habits into named routines. Card above individual habits. |

**Mini-game free play placement:** Add a "Mini-Games" button in the Tasks tab header or as a NavigationLink. Opens list of all 5 games. Free play = no stat reward, just fun.

### Tab 3: Adventures (map.fill) — AFK & Combat Content

The Adventures tab is where RPG content lives. All AFK/idle/combat content.

| Category (Horizontal Picker) | Status | Notes |
|---|---|---|
| Training (AFK Missions) | ✅ Exists | No structural change. More templates from server. |
| Dungeons | ✅ Exists | No structural change. More dungeons from server. Room shuffle is engine-level. |
| Arena | ✅ Exists | Add infinite waves. Add weekly modifier badge. Add milestone reward preview. Add party leaderboard. |
| Raid Boss | ✅ Exists | Add boss loot preview. Add party member damage bars. |
| **Expeditions** | 🆕 New | 5th category in horizontal picker. Locked until appropriate level. Launch → progress → results. |

**NPC placement:**
- **Quest Giver** — Top of Adventures Hub, above category picker. Small character + dialogue line. "I've heard rumors of a new dungeon..." Contextual based on what's available. Tap to dismiss.

### Tab 4: Party (heart.fill) — Social & Accountability

Currently "Partner" — will become "Party." Icon stays `heart.fill` (accountability = caring).

| Section | Status | Notes |
|---|---|---|
| My Party Code (copy button) | ✅ Exists (as "Partner Code") | Rename |
| Party Dashboard (bond level, members) | ✅ Exists (as "Partner Dashboard") | Expand to show 1-4 members |
| Pending Confirmations | ✅ Exists | Any member can verify now |
| Recent Activity | ✅ Exists | Becomes party feed (Realtime) |
| Duty Board Preview | ✅ Exists | No change |
| Not Connected View (pairing) | ✅ Exists | Update for multi-member invite |
| **Party Leaderboard (full)** | 🆕 New | NavigationLink from dashboard. Ranked list, fun titles, period filters. |
| **Shared Goals** | 🆕 New | NavigationLink. Create/view party goals. Each member's progress tracked. |
| **Party Feed (enhanced)** | 🆕 Upgrade | Realtime subscription. Task completions, drops, cards, levels, achievements. |

### Tab 5: Character (person.fill) — Character Sheet & Personal

The Character tab is "me" — stats, gear, achievements, wellness, settings.

| Tab (Horizontal Pills) | Status | Notes |
|---|---|---|
| Stats (raw numbers, allocation) | ✅ Exists | Removed progress bars (they implied a stat cap). Show raw numeric values. Tap any stat row to expand a source breakdown (base + equipment + class + zodiac). Chevron hint for tappability. Stats are uncapped for long-term growth. |
| Equipment (slots, inventory link) | ✅ Exists | Expand to 4 slots (add Trinket). Show affixes on items. |
| Achievements | ✅ Exists | Expand to 40 achievements |
| Wellness (mood chart, meditation) | ✅ Exists | Add Wisdom buff indicator. Add mood sharing toggle in meditation prefs. |
| **Bestiary** | 🆕 New | 5th pill tab. Card collection grid, milestones, total bonus summary. |

**Settings:** Gear icon already exists in navigation bar (top-right). Opens `SettingsView`.

**Card Collector NPC:** Top of Bestiary tab. Small character + dialogue. "Only 3 more Forest cards to go!"

### Store (Accessed from Character → Equipment → Store link, or direct)

| Section | Status | Notes |
|---|---|---|
| Storefront (daily deal, stock, bundles) | ✅ Exists | Content pipeline migration |
| Equipment tab | ✅ Exists | No change |
| Consumables tab | ✅ Exists | Add Affix Scrolls (800g) |
| Premium tab | ✅ Exists | Gems earn-only |
| Shopkeeper NPC | ✅ Exists | Server-driven dialogue |
| **Wandering Merchant** | 🆕 New | Conditional — 10% daily chance. Different NPC portrait. Replaces/sits alongside shopkeeper for the day. |

### Forge (Accessed from Character → Equipment → Forge link, or Adventures?)

| Section | Status | Notes |
|---|---|---|
| Forge (currently 2 views) | ✅ Exists | **Merge into 1 unified ForgeView with 4 station tabs:** Craft, Enhance, Salvage, Affix |
| Forgekeeper NPC | ✅ Exists | Server-driven dialogue |

### Pre-Tab Flows (Before Main App)

| Flow | When | Notes |
|---|---|---|
| Auth Gate (login/signup) | No account | ✅ Exists |
| Character Creation | No character | ✅ Exists |
| **Onboarding** | First time post-creation | 🆕 New. Guided first task → reward demo → quick tour → starter gift → habit setup. Then drops into Home tab. |
| **Backing Up Progress** | First launch after sync update | 🆕 New. One-time loading screen. Bulk uploads local data to cloud. |

### Goals (Accessed from Home → Goals card, or separate?)

Goals currently live as a separate view accessed from HomeView. With the addition of shared party goals, they need to be reachable from both Home and Party tabs:
- **Home → Goals card → GoalsView** (personal goals)
- **Party → Shared Goals → GoalsView** (filtered to party goals)
- Same view, different filter. Not a new screen.

---

## Visual & Implementation Rules

> **These rules are non-negotiable. Every agent must follow them. The app has an established look — do not change it.**

### Visual Theme — Do Not Change

| Element | Current Style | Rule |
|---|---|---|
| **Background** | `LinearGradient(colors: [Color("BackgroundTop"), Color("BackgroundBottom")])` | Use this gradient on every full-screen view. Never use plain white/black backgrounds. |
| **Cards** | `RoundedRectangle(cornerRadius: 16)` + `Color("CardBackground")` + shadow | Every content block is a card. Never use bare text on the background. |
| **Shadows** | `.shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)` | Consistent shadow on all cards. |
| **Accent color** | `Color("AccentGold")` | Primary accent. Tab tint, buttons, highlights. |
| **Secondary accents** | `AccentOrange`, `AccentGreen`, `AccentPink`, `AccentPurple` | Use contextually. Orange for warnings/duties, Green for success, Pink for party, Purple for class. |
| **Typography** | Avenir font family (`Avenir-Heavy`, `Avenir-Medium`) | Use these fonts. Do not use system fonts or other font families. |
| **Font sizes** | 11-13 (small/caption), 14-16 (body), 18-20 (heading), 24-28 (title) | Stay in these ranges. |
| **Corner radius** | 12-16 (cards), 8-10 (buttons/badges) | Consistent across all new UI. |
| **Spacing** | 4-6 (tight), 12-16 (normal), 24 (between sections) | Match existing spacing. `VStack(spacing: 24)` for section-level. |
| **Category colors** | `CategoryPhysical`, `CategoryMental`, `CategoryCreative`, `CategorySocial`, `CategoryHousehold`, `CategoryWellness` | Use these for any category-related UI. |
| **Rarity colors** | `RarityCommon`, `RarityUncommon`, `RarityRare`, `RarityEpic`, `RarityLegendary` | Use these for any rarity-related UI. |
| **Gold gradients** | `LinearGradient(colors: [Color("AccentGold"), Color("AccentOrange")])` | Use for gold/premium UI elements. |
| **Dark mode** | Supported via semantic named colors | All named colors are dark-mode aware. Never use hardcoded color values. |

### Implementation Rules — Out of the Box Only

| Pattern | Use | Do NOT Use |
|---|---|---|
| **Navigation** | `NavigationStack` + `NavigationLink` | UIKit navigation, custom navigation stacks |
| **Tabs** | `TabView` (existing, don't modify) | Custom tab bars, third-party tab libraries |
| **Scrolling** | `ScrollView` + `VStack` | `List` (unless filtering/searching), `UIScrollView` |
| **Grids** | `LazyVGrid` / `LazyHGrid` | `UICollectionView`, third-party grid libraries |
| **Modals** | `.sheet()` for forms/creation, `.fullScreenCover()` for immersive (games, meditation) | Custom modal presentations, `UIViewController` |
| **Alerts** | `.alert()` and `.confirmationDialog()` | Custom alert views (unless matching existing toast system) |
| **Toasts** | Existing `ToastOverlayView` | Third-party toast libraries |
| **Animations** | SwiftUI `.animation()`, `.transition()`, `.matchedGeometryEffect()` | UIKit animations, Lottie, third-party animation libraries |
| **Haptics** | `UIImpactFeedbackGenerator`, `UINotificationFeedbackGenerator` | Third-party haptic libraries |
| **Audio** | Existing `AudioManager` (system sounds) | AVPlayer for SFX, third-party audio |
| **Data** | `@Query` (SwiftData), `@EnvironmentObject` (GameEngine), `@State` / `@Binding` | Combine publishers for UI state, third-party state management |
| **Images** | SF Symbols + asset catalog images | Third-party icon libraries |
| **Charts** | Swift Charts framework (iOS 17+) | Third-party charting libraries |
| **Networking** | Supabase Swift client | URLSession directly (unless Supabase doesn't cover the case) |
| **Push** | OneSignal (existing) | Firebase, custom push |
| **Local storage** | SwiftData (models), UserDefaults (preferences) | Core Data, Realm, third-party storage |

### Card Pattern — Reference Implementation

Every new section/feature should follow this card pattern:

```swift
// Standard card
VStack(alignment: .leading, spacing: 12) {
    // Card header
    HStack {
        Image(systemName: "icon.name")
            .foregroundColor(Color("AccentGold"))
        Text("Card Title")
            .font(.custom("Avenir-Heavy", size: 16))
        Spacer()
    }
    
    // Card content
    // ... your content here ...
}
.padding(16)
.background(Color("CardBackground"))
.cornerRadius(16)
.shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
```

### Entrance Animation Pattern

New cards should use the existing `.cardEntrance()` modifier with staggered delays:

```swift
.cardEntrance(delay: 0.1) // increment by 0.05-0.1 per card
```

### What "Out of the Box" Means

1. **Use SwiftUI native components.** If SwiftUI has a built-in way to do it, use that.
2. **No third-party UI dependencies.** The app has zero UI library dependencies. Keep it that way.
3. **The only external services are Supabase and OneSignal.** Both are already integrated. Don't add new services.
4. **SF Symbols for all icons.** The app uses SF Symbols everywhere. New features should too. Custom art (avatars, equipment, NPCs) goes in asset catalogs.
5. **Swift Charts for any new charts/graphs.** Already available on iOS 17+.
6. **No UIKit bridges unless absolutely necessary.** The app is pure SwiftUI. Keep it that way.

---

## The Pivot: From Couples to Parties

### Why

- Couples-only cuts out ~50% of potential users (single people)
- The mechanics already work for any pair of people — friends, roommates, gym buddies
- Habitica removed guilds in 2023, leaving a gap for group accountability + RPG
- Research: small groups (5–15) show 73% higher completion rates vs. solo (Cohorty data)
- Research: accountability partners increase success rates by 65%

### What Changes

| Current (Couples) | New (Party) |
|---|---|
| Bond (1 partner) | Party Bond (1–4 members) |
| "Partner" language everywhere | "Ally" / "Party Member" |
| Couples Leaderboard | Party Leaderboard |
| Romantic item names ("Soulmate's Bangle", "The Eternal Vow") | Adventure-themed ("Oathbound Bangle", "The Eternal Pact") |
| Bond titles: "Power Couple", "Soulbound" | "Battle Forged", "Ironbound", "Oathsworn" |
| 2-person co-op only | 1–4 person co-op |

### What Stays the Same

- QR pairing system (works identically for friends)
- Bond level / EXP / perk system (just generalized)
- Nudge / Kudos / Challenge interactions
- Task assignment between members
- Task confirmation / dispute system
- Co-op dungeon runs
- Shared streak mechanic
- Weekly raid boss

### New Group Mechanics (Party of 3–4)

- **Party roles**: Natural mapping to RPG classes — the Warrior does the hardest tasks, the Mage handles mental tasks, etc.
- **Group challenges**: "Everyone completes 5 tasks this week or nobody gets the bonus chest"
- **Party expeditions**: Combine stats from all members for expedition success
- **Contribution tracking**: See who's pulling their weight (accountability)

### Naming / Branding

- App name: **QuestBond** (working title — captures both the quest/RPG identity and the social bond)
- Alternative candidates: PartyQuest, BondForge, QuestPact
- Decision: TBD (need to check App Store availability)

### Bond Title Renames

| Level | Current | New |
|---|---|---|
| 1–4 | Acquaintances | Acquaintances |
| 5–9 | Companions | Companions |
| 10–14 | Trusted Allies | Trusted Allies |
| 15–19 | Battle Partners | Battle Forged |
| 20–29 | Soulbound | Ironbound |
| 30–39 | Dynamic Duo | Oathsworn |
| 40–49 | Power Couple | Legends |
| 50 | Legendary Bond | Legendary Bond |

### Perk Renames

| Current | New |
|---|---|
| Couples Achievements | Party Achievements |
| Shared Duty Board | Shared Duty Board (no change) |
| Task Assignment | Task Assignment (no change) |

---

## Party System (1–4 Members)

### Core Concept

The party is **async co-op**. Members aren't playing together in real-time. Each person lives their own day, completes their own tasks, runs their own dungeons — but their actions affect the group. Think guild in an idle MMO, not a raid party in WoW.

### What Each Member Sees

When you open the app, your Home screen shows:
1. Your own tasks, streaks, and character (unchanged)
2. A **Party Bar** showing your 1–3 allies: avatar, level, quick status (online / completed X tasks today / on a mission)
3. A **Party Feed**: "Maya completed 'Gym Session' (+35 EXP)" / "Jordan's dungeon run dropped a Rare Axe" / "Alex collected the Shadow Lurker card"

That ambient awareness IS the social loop. No coordination needed. You just see your friends being productive, and that's enough to keep up.

### Feature Mapping (Current → Party)

| Feature | Currently (2 people) | With Party (1–4 people) |
|---|---|---|
| Bond | 1 partner → 1 Bond object | 1 party → 1 PartyBond shared by all members |
| Pairing | QR code, 1 partner | QR code or invite link, up to 3 allies |
| Nudge/Kudos | Send to partner | Send to any party member |
| Task assignment | Assign to partner | Assign to any party member |
| Task confirmation | Partner confirms | Assigner confirms (whoever assigned it) |
| Co-op dungeons | Partner proxy stats | Party proxy: combined stats of all members |
| Raid Boss | 2-person shared damage | 4-person shared damage (scales thresholds) |
| Streak bonus | Dual streak (both partners) | Party streak: bonus when ALL members maintain streaks |
| Expeditions | Solo or 2-person | Solo or up to 4 members (combined stats) |
| Bond EXP | Shared between pair | Shared across party (everyone contributes, everyone benefits) |

### Party Power Scaling (Diminishing Returns)

A party of 4 can't be 4x more powerful than solo — that breaks balance. Use diminishing returns:

| Party Size | Power Multiplier | How It Works |
|---|---|---|
| 1 (solo) | 1.0x | Base power |
| 2 | 1.5x | 75% of second member's stats added |
| 3 | 1.85x | 70% of third member's stats added |
| 4 | 2.1x | 65% of fourth member's stats added |

Parties are always stronger than solo (incentive to recruit), but not so strong that solo players feel punished.

### Party Streak

The single biggest retention lever. When ALL party members complete at least 1 task in a day, the party streak ticks up.

| Party Streak Days | Bonus |
|---|---|
| 3 days | +10% EXP for all members |
| 7 days | +15% EXP, +10% Gold |
| 14 days | +20% EXP, +15% Gold, +5% loot chance |
| 30 days | +25% EXP, +20% Gold, +10% loot chance |

**If one person breaks it, everyone loses it.** Social pressure from people you actually know is stronger than any algorithm. Combined with **Streak Armor** (consumable) — any member can cover for a bad day. The party can collectively maintain 1–2 freezes.

### Party Loot Rules

Each player gets **their own individual loot rolls**. Being in a party doesn't multiply loot — it gives access to party-only content and the party streak bonuses.

### Party-Exclusive Content

| Content | Requirement | Reward |
|---|---|---|
| Party Dungeons | 2+ members, bond level 5+ | Higher tier loot, set piece drops |
| Party Expeditions | 2+ members, combined stats | Better success rates, more stage loot |
| Weekly Raid Boss | Scales with party size | Faster kill, better rewards at higher tiers |
| Party Challenges | All members participate | Bonus chest if everyone completes weekly target |

### Party Challenges (Weekly)

Once per week, the party gets a shared objective: "Everyone complete 15 tasks this week." If ALL members hit the target, everyone gets a bonus chest with guaranteed Rare+ equipment. If anyone misses, nobody gets it. Pure group accountability.

### Implementation Notes

- `Bond` model becomes `PartyBond` — `partnerID: UUID` becomes `memberIDs: [UUID]` (max 4)
- Supabase: new `parties` table or extend `profiles` with party membership
- Party Feed: new Realtime subscription channel per party
- Party Challenges: weekly generated objective, tracked per member, resolved at week end

---

## IRL Task Experience Design

> The RPG layer is decoration. The IRL task loop is the product. If completing real-world tasks doesn't feel good, nothing else matters.

### Design Principles (From Research)

**Self-Determination Theory (SDT)** — the gold standard for sustainable motivation — identifies three needs:

1. **Autonomy** ("I chose this"): Players must feel ownership over their tasks, not obligation. Let them define categories, set custom EXP values, choose verification level.
2. **Competence** ("I'm getting better"): Players must see real-life improvement, not just numbers. Track personal records, category mastery, weekly progress vs. prior weeks.
3. **Relatedness** ("I'm doing this with people who care"): Social accountability is 2–3x more effective than solo tracking. The party feed, kudos, and shared routines are the retention layer.

**What research says NOT to do:**
- Habitica's HP-loss-for-missed-tasks system is **scientifically counterproductive**. A peer-reviewed study found 7 distinct ways it produces the opposite of its intended effect (avoidance, anxiety, gaming the system, disengagement).
- Punishment ≠ motivation. Use **opportunity cost** instead: "You could have earned 45 EXP and maintained your 12-day streak" is better than "You lost 10 HP."

**What research says TO do:**
- Variable reward schedules on task completion (occasional loot rolls create curiosity)
- Multisensory completion feedback (animation + haptic + sound in < 0.5 seconds)
- Friction under 3.5 seconds for standard task logging (above this, attention residue lasts 22+ minutes)
- Streak mechanics leverage loss aversion naturally without punishing

### The Completion Moment

The single most important UX moment in the entire app. Happens 5–10 times per day. Currently undersold.

**Current flow:**
1. Tap "Complete" (or verify with photo/location)
2. `GameEngine.completeTask()` calculates rewards
3. Show `TaskCompletionResult` with numbers
4. Level-up overlay if applicable

**Target flow:**
1. Tap "Complete" → immediate haptic pulse + sound effect + visual state change (task card animates to "done")
2. Brief reward reveal (0.5–1 sec): EXP + Gold fly to their respective counters
3. **Bonus roll** (when applicable): A small chest/card flip animation with a ~8% chance of equipment or ~35% chance of crafting materials. The possibility is the excitement — even getting nothing is fine because next time they might get something.
4. Streak counter visibly ticks up (if habit)
5. Party feed notification fires ("Alex completed 'Gym Session'")

**Key insight from research:** Curiosity ("what could I get?") is the #1 driver of both enjoyment and continued play — stronger than the actual reward value. The loot roll on task completion creates this.

### Verification Tiers (Not One-Size-Fits-All)

Tasks need different friction levels based on their nature. Don't make someone take a photo to prove they drank water.

| Tier | Verification | Time to Log | When to Use |
|---|---|---|---|
| **Quick** | One-tap toggle | < 1 second | Simple habits: water, vitamins, make bed, journal |
| **Standard** | Tap complete + optional note | 2–3 seconds | Standard tasks: read 30 min, clean kitchen, walk dog |
| **Verified** | Photo and/or location + optional HealthKit | 15–30 seconds | High-value tasks: gym session, project milestone, meal prep |
| **Party-verified** | Photo + ally confirmation | 30–60 seconds | Party-assigned challenges, accountability tasks |

Infrastructure for all four tiers already exists (`VerificationType` enum). The work is making Quick tier the default and making it genuinely 1-tap.

**Quick-complete surfaces:**
- Swipe-to-complete on habit cards in task list (no navigation to detail view)
- iOS Widget: check off habits from home screen without opening app
- Apple Watch: tap to complete on wrist (future phase)
- Batch completion for routine bundles (see below)

### Routine Bundles (Morning/Evening Quests)

People think in routines, not individual tasks. "My morning routine" is a single mental unit, not 5 separate habits.

**Concept: Routine Quests**

A Routine is a player-defined bundle of 3–6 habits tied to a time of day. Completing all habits in the routine triggers a **routine completion bonus**.

| Routine | Example Habits | Completion Bonus |
|---|---|---|
| Morning Quest | Make bed, drink water, stretch, journal, plan day | +50% EXP for all habits in bundle + bonus loot roll |
| Workout Quest | Warm up, main workout, cool down, log stats | +50% EXP + guaranteed crafting material |
| Evening Quest | Clean kitchen, read 20 min, prep tomorrow, wind-down | +50% EXP + streak protection for the bundle |

**UX:** The routine appears as a single expandable card. Tap to expand, rapid-fire check off each sub-task, see the bonus trigger when all are done. Total time: ~5 seconds for a 5-habit routine.

**Why this matters:** It solves friction (batch completion), creates a compounding reward (routine bonus > sum of individual bonuses), and mirrors real behavior patterns.

### No Punishment — Opportunity Cost Instead

**Remove from the game:**
- Gold/EXP penalties for missed habits
- Any mechanic that damages the character for not doing a real-world task
- Any "you failed" language in the UI

**Replace with:**
- "Missed opportunity" messaging: "Your streak was at 12 days. Complete today's tasks to get it back!"
- Streak freeze item (consumable): protects one missed day per week without breaking the streak. Available from store or as party perk. This is the safety valve that prevents the anxiety spiral.
- Gentle nudge from party members (human accountability > algorithmic punishment)
- Faded/dimmed display of what they *would have earned*, not what they *lost*

### Category-Specific Mechanics

Each task category should feel distinct to complete, not just boost a different stat.

| Category | Unique Mechanic | Why |
|---|---|---|
| **Physical** | HealthKit auto-verify. Set "Run 30 min" → if Apple Health shows 30+ min running activity, auto-complete with bonus EXP. No manual logging. | Removes friction for the most verifiable task type |
| **Mental** | Optional focus timer integration. Start a Pomodoro-style timer, get bonus EXP for sustained focus blocks. | Matches how mental work happens — deep focus, not multitasking |
| **Social** | Party-visible by default. Social tasks always appear in party feed. Bonus EXP if an ally also completes a social task the same day. | Reinforces the social nature of the category |
| **Household** | Optional before/after photo. Snap the mess → snap the clean. Creates a transformation record + verification. | The visual transformation is inherently satisfying for chores |
| **Wellness** | Integrates with existing meditation system. Wellness tasks can trigger meditation timer, mood check-in, or journal entry as completion step. | Deepens the wellness feature already built |
| **Creative** | Photo gallery of creative output. Over time builds a portfolio of things created. | Creative people want to see their body of work grow |

### Making Real Life Feel Like Leveling Up

The RPG layer can't make doing dishes fun. But it can make you **want to do the dishes** because:
- You're on a 15-day streak and your party is counting on you
- You're 200 EXP from your next level
- You might get a rare material drop
- Your Morning Quest routine bonus is waiting
- Your ally just completed their household task and you don't want to fall behind

**Additional "IRL leveling" features:**

| Feature | Description | Implementation |
|---|---|---|
| **Category Mastery** | "You've completed 150 physical tasks. Physical Mastery: Level 8." Visible progression per life area. | New computed property on PlayerCharacter per category |
| **Personal Records** | "Most tasks in one day: 12. Longest gym streak: 23 days." Track and celebrate real-life bests. | New tracking fields, displayed in character view |
| **Weekly Progress Summary** | Push notification + in-app card: tasks this week vs. last week, streaks maintained, stats grown. The "IRL level-up" moment. | Scheduled local notification + HomeView card |
| **Difficulty Progression** | "You've done 20-min workouts for 3 weeks. Ready for 30?" Gentle growth suggestions. | Heuristic based on habit history |
| **Photo Journal** | Verified task photos accumulate into a private timeline. Over months, you can scroll back and see your progress visually. | Surface existing `verificationPhotoData` in a timeline view |
| **Identity Reinforcement** | The character IS the player. "Level 23 Warrior who never misses leg day." The RPG persona becomes a positive self-image over time. | Already happening naturally through class + stat system |

### The Real-World → Game-World Bridge (Summary)

```
Real action (do the dishes)
  → Quick-tap completion (< 1 sec for habits)
  → Immediate feedback (haptic + sound + animation)
  → Reward reveal (EXP + Gold + possible loot roll)
  → Streak tick (visible counter)
  → Routine bonus (if part of a bundle)
  → Party feed ("Alex completed Household task")
  → Stat growth (Dexterity +0.1)
  → Category mastery progress
  → Pity counter progress (closer to guaranteed drop)
  → Goal milestone progress (if linked to a Goal)
  → Bond EXP (if party-related)
```

One real-world action triggers 10+ game responses. That density of feedback is what makes the bridge work.

---

## Loot System Redesign

### Problems with Current System

1. **No loot from tasks.** The most frequent activity (real-world tasks) gives only flat EXP + Gold. No "what did I get?" moment.
2. **No bad luck protection.** A player can run 20 dungeons and get nothing but common gear. No pity system.
3. **No chase items.** Two legendary swords are basically identical. Nothing to specifically hunt for.
4. **Flat probability.** `rollRarity` uses a linear scale with no dynamic adjustment.
5. **No system interconnection.** Tasks, dungeons, missions, and forge are parallel pipes — they don't feed each other.
6. **Enhancement is linear and predictable.** +1 per level, guaranteed. No risk, no excitement.

### Redesign: 5-Layer Loot Model

#### Layer 1: Guaranteed Baseline
Every completed activity always gives EXP + Gold + progress toward a **pity counter**. The player never walks away empty-handed.

#### Layer 2: Variable Reward Roll
On top of baseline, roll for bonus loot. This roll should happen **visually** — a chest opening, card flip, or shimmer effect. The anticipation is the reward.

**Drop chances by content type:**

| Content | Equipment Drop Chance | Material Drop Chance | Notes |
|---|---|---|---|
| Task completion | 5–8% | 30–40% | Tasks are frequent — small but consistent rewards |
| Dungeon room (success) | 15–50% (scales with tier) | 60% | The "big loot moment" |
| AFK Mission | 10–50% (scales with luck) | 40% | Rewards patience — access to Rare-only table |
| Expedition stage | 20–30% per stage | 50% | Expedition-exclusive loot table |
| Weekly Raid Boss | 100% (guaranteed) | 80% | The weekly event — always feels good |
| Level-up chest | Current system (milestone-based) | Current system | Already works well |

#### Layer 3: Bad Luck Protection (Pity System)

Track consecutive "dry runs" (no equipment drops) per content type.

| Content | Pity Threshold | Guaranteed Quality |
|---|---|---|
| Tasks | 20 completions | Uncommon+ equipment |
| Dungeon rooms | 12 rooms | Rare+ equipment |
| AFK Missions | 5 missions | Rare+ equipment |
| Expeditions | 3 expeditions | Epic+ equipment |

**Implementation**: Add `pityCounter: [String: Int]` to `PlayerCharacter`. Increment on dry runs, reset to 0 on any equipment drop. When counter >= threshold, force a drop and reset.

#### Layer 4: Exclusive Drop Tables (Content-Specific Loot)

| Content Type | Exclusive Drops | Why |
|---|---|---|
| Tasks | Crafting materials, consumables, small gold bonuses | Frequent + quick = small consistent rewards |
| AFK Missions | Rare-only equipment pool, passive bonus tokens | Reward patience (IdleON's AFK-only rares concept) |
| Dungeons | Full equipment table, affix gear, set pieces | The big loot chase |
| Expeditions | Expedition-exclusive equipment, lore items, unique affixes | Ultra-long-term chase |
| Weekly Raid Boss | Boss-exclusive equipment, unique cosmetics | Weekly event feeling |

#### Layer 5: Affix System (Making Each Drop Unique)

Add prefix and suffix affixes to equipment. Inspired by Diablo 4's Loot 2.0: fewer but more meaningful affixes.

**New Equipment properties:**

```swift
var prefix: EquipmentAffix?    // e.g., "Blazing" (+10% EXP from physical tasks)
var suffix: EquipmentAffix?    // e.g., "of the Scholar" (+5% mission speed)
```

**Affix chances by rarity:**

| Rarity | Prefix Chance | Suffix Chance | Total Possible Affixes |
|---|---|---|---|
| Common | 0% | 0% | 0 |
| Uncommon | 20% | 0% | 0–1 |
| Rare | 50% | 30% | 0–2 |
| Epic | 80% | 60% | 1–2 |
| Legendary | 100% | 80% | 1–2, with chance for "Greater Affix" (1.5x power) |

**Affix Pool:**

| Affix Name | Type | Effect | Category |
|---|---|---|---|
| Blazing | Prefix | +X% EXP from physical tasks | Task-specific |
| Scholarly | Prefix | +X% EXP from mental tasks | Task-specific |
| Social | Prefix | +X% EXP from social tasks | Task-specific |
| Industrious | Prefix | +X% EXP from household tasks | Task-specific |
| Mindful | Prefix | +X% EXP from wellness tasks | Task-specific |
| Inspired | Prefix | +X% EXP from creative tasks | Task-specific |
| Swift | Prefix | -X% AFK mission duration | Idle bonus |
| Prosperous | Prefix | +X% Gold from all sources | Economy |
| Lucky | Prefix | +X% rare drop chance | Meta loot |
| Resilient | Prefix | +X% streak shield chance | Protection |
| Vigilant | Suffix | +X% dungeon success chance | Combat |
| of Fortune | Suffix | +X% loot drop chance | Meta loot |
| of the Scholar | Suffix | +X% mission speed | Idle bonus |
| of Devotion | Suffix | +X% party bond EXP | Social |
| of Persistence | Suffix | +X% habit streak bonus | Habit |
| of the Pathfinder | Suffix | +X% expedition rewards | Expedition |
| of Warding | Suffix | +X defense in dungeons | Combat |
| of Haste | Suffix | -X% dungeon room time | Combat |

**Affix value ranges scale with item rarity and level requirement.**

### Enhancement Overhaul

| Level | Success Rate | Materials | Effect |
|---|---|---|---|
| +1 to +3 | 100% | Low cost | +1 primary stat per level |
| +4 to +6 | 80% | Medium cost | +1 primary stat per level |
| +7 to +8 | 60% | High cost | +2 primary stat per level |
| +9 | 40% | Very high cost | +2 primary stat |
| +10 | 25% | Extreme cost | +3 primary stat + "Perfected" title |

**On failure**: Materials are consumed but enhancement level does not decrease. No punishment — just lost investment.

**Critical enhancement**: 10% chance on any success to get double the stat bonus for that level.

### Auto-Salvage System

Player sets rules:
- "Auto-salvage all Common equipment" (toggle)
- "Auto-salvage all equipment below Rare" (toggle)
- "Never auto-salvage items with affixes" (safety toggle)

Salvaged equipment yields crafting materials + forge shards scaled to rarity. This feeds the forge loop.

---

## Equipment Slot Expansion

### Current: 3 Slots (Weapon, Armor, Accessory)

3 slots means a player needs 3 items to be "fully geared." Once they have a Legendary in each slot, the gear chase is over. The catalog already has cloaks, belts, charms, bracelets crammed into the generic Accessory slot.

### Launch: 4 Slots (Add Trinket)

| Slot | What Goes Here | Primary Stats | Catalog Items |
|---|---|---|---|
| **Weapon** | Swords, Axes, Staves, Daggers, Bows, Wands, Maces, Spears | Str, Wis, Dex | All current weapons (unchanged) |
| **Armor** | Plate, Chainmail, Robes, Leather, Breastplate, Helms, Gauntlets | Def, Dex, Str | All current armor (unchanged) |
| **Accessory** | Rings, Amulets, Pendants | Any | Rings, Amulets, Pendants |
| **Trinket** (new) | Cloaks, Belts, Charms, Bracelets | Any | Cloaks, Belts, Charms, Bracelets (moved from Accessory) |

**Why 4 not 6:** One new slot is manageable on a phone screen. Still increases the gear chase by 33%. Cloaks/belts/charms already exist in the catalog — they just need their own slot.

**Backward compatible:** Existing equipped accessories that are cloaks/belts/charms/bracelets unequip and move to Trinket slot availability. New `EquipmentSlot.trinket` case added to enum.

### Future Expansion: 6 Slots

Split Armor into Head + Chest + Hands if players want more depth. The catalog already has Helms and Gauntlets that could break out.

### Gem Sockets (Future — Not at Launch)

Gem sockets add a second customization layer on top of affixes. Only implement if affixes alone aren't creating enough gear depth. Design spec preserved here for future reference:

- Equipment drops with 0–2 socket slots (scales with rarity)
- 6 gem types crafted from Crystal materials (Ruby +Str, Sapphire +Wis, Emerald +Dex, Diamond +Def, Topaz +Luck, Amethyst +Cha)
- Gems removable and reusable (gold cost sink)
- Gives Crystal materials a unique purpose

---

## Gear Sets Redesign (Simplified)

### Current: 3 Sets, All-Or-Nothing Bonus

3 class sets (Warrior, Mage, Archer), each 3 pieces, single bonus (+5 to a stat). All 3 pieces required for any benefit.

### Simplified Redesign: 3 Sets, 2-Piece Activation

Keep the 3 starter class sets already built. Change to **2-piece bonus activation** — wear any 2 of the set's pieces, get the bonus. Other slots stay free for affix gear.

| Set | Class Line | 2pc Bonus | Pieces |
|---|---|---|---|
| Vanguard's Resolve | Warrior / Berserker / Paladin | +10% Defense in dungeons | Weapon + Armor + Accessory (any 2) |
| Arcanum's Embrace | Mage / Sorcerer / Enchanter | -10% AFK mission time | Weapon + Armor + Accessory (any 2) |
| Windstrider's Mark | Archer / Ranger / Trickster | +10% loot drop chance | Weapon + Armor + Accessory (any 2) |

**Why this is enough for launch:**
- Creates a real decision: "Do I wear 2 set pieces for the bonus, or swap in this Legendary with a great affix?"
- Only 3 sets to maintain (not 9)
- Set pieces already exist in `GearSetCatalog` — minimal code change
- Advanced class sets (Berserker, Enchanter, Trickster, etc.) can be added later as content updates if players want more depth

**Set pieces are upgraded to Epic rarity** (from current Rare) so they stay relevant longer.

**Set piece sources:**
- Party dungeons (targeted farming)
- Expedition loot tables
- Forge (high-cost recipe)

### Future Expansion
- Add 6 advanced class sets with unique 2pc bonuses
- Consider 4pc bonus tier if players want deeper build customization
- Cross-class "universal" sets (e.g., a Fortune set for any class that boosts loot)

**Build examples:**
- Trickster wearing Shadow Gambit 4pc (+25% affix chance) is a "loot hunter" build — fundamentally changes how they approach drops
- Enchanter wearing Resonance Threads 4pc (+20% party bond EXP) is a "support" build — they make the whole party level faster
- A Paladin could wear 2pc Oathkeeper + 2pc Vanguard for a tank/support hybrid

---

## Monster Card Collection

### Core Concept

Every time your character defeats an encounter (dungeon room, arena wave, expedition stage, raid boss), there's a chance a **Monster Card** drops. Cards go into a Bestiary/Codex collection. Each card gives a small permanent passive bonus. No deck building, no card battles, no card leveling — just collect and get stronger.

### Why This Works

- **Zero new gameplay** — it's a passive reward layer on top of content that already exists
- **Replay incentive** — gives a reason to re-run dungeons you've already cleared
- **Completionism** — "gotta catch 'em all" is one of the strongest long-term engagement drivers in idle games
- **Small implementation** — 1 new model, 1 new view, drop logic added to existing dungeon/arena/expedition handlers

### Card Structure

Each card has:
- **Name** (from the dungeon/encounter it drops in, e.g., "Shadow Lurker", "Crystal Golem", "Flame Wraith")
- **Theme** (inherited from `DungeonTheme`)
- **Rarity** (Common through Legendary, using existing `ItemRarity`)
- **Passive bonus** (permanent, always active once collected)
- **Source** (which content it drops from)

### Card Bonuses

Individually tiny. Collectively meaningful. 20–30 cards = +10–15% across various stats.

| Bonus Type | Example Values | How Many Cards |
|---|---|---|
| +EXP% | +0.3% to +1.0% | ~15 cards with this bonus |
| +Gold% | +0.3% to +1.0% | ~10 cards |
| +Dungeon success% | +0.3% to +0.5% | ~8 cards |
| +Loot drop chance% | +0.2% to +0.5% | ~7 cards |
| +Mission speed% | +0.3% to +0.5% | ~5 cards |
| +Defense | +0.5 to +1.0 flat | ~5 cards |

### Drop Sources and Rates

| Source | Cards Available | Drop Chance | Card Rarity Range |
|---|---|---|---|
| Dungeon rooms (combat/boss) | 3–5 per dungeon theme | 10–15% per room | Common – Epic |
| Arena waves | 1 per 5-wave milestone | 20% at milestone | Uncommon – Epic |
| Expedition stages | 1–2 per expedition | 15–20% per stage | Rare – Legendary |
| Weekly Raid Boss | 1 per boss (unique weekly) | 100% on defeat (guaranteed) | Epic – Legendary |

### Collection Milestones

| Cards Collected | Reward |
|---|---|
| 10 | +2% EXP from all sources (permanent) |
| 25 | +2% Gold from all sources (permanent) |
| 50 | +3% loot drop chance (permanent) |
| 75 | +3% dungeon success (permanent) |
| 100 (full collection) | Title: "Monster Scholar" + unique equipment piece |

### Launch Scope

~50 cards at launch across existing dungeon themes, arena, and raid boss. Expand to 100+ as new dungeons and expeditions ship.

### Cards + Party Integration

- **Party Feed** shows when someone finds a new card: "Maya discovered Crystal Golem! (23/50 collected)"
- **Shared Bestiary**: The party can see which cards any member has found. But bonuses are individual — you only get the passive bonus from cards YOU'VE collected. Seeing a party member's card tells you "this exists, I should farm that dungeon."
- **Rare card discoveries** trigger a party notification — bragging rights and organic conversation
- **Party collection milestones** (future): bonus when the party collectively reaches thresholds

### Implementation

**New model:**
```swift
// MonsterCard
- id: UUID
- cardID: String           // unique key, e.g. "card_shadow_lurker"
- name: String
- cardDescription: String
- theme: DungeonTheme
- rarity: ItemRarity
- bonusType: CardBonusType // .expPercent, .goldPercent, .dungeonSuccess, .lootChance, .missionSpeed, .flatDefense
- bonusValue: Double       // e.g. 0.005 for +0.5%
- source: String           // "Dungeon: Shadow Crypt", "Arena Wave 15", etc.
- isCollected: Bool
- collectedAt: Date?
- ownerID: UUID
```

**New view:** `BestiaryView` — grid/list of all cards, collected vs undiscovered, total bonuses summary, collection milestones progress. Accessible from Character tab.

**Integration points:**
- `DungeonEngine.resolveRoom()` — roll for card drop after successful room
- Arena wave completion handler — roll for card at milestones
- Expedition stage handler — roll for card per stage
- Raid boss completion — guaranteed card drop

---

## Consumables Overhaul

### The Hoarding Problem

Research: "too good to use" syndrome. Players stockpile consumables for a "better moment" that never comes. Critical items that appear rarely reinforce hoarding and limit player decision-making.

### Solution: Tiered Abundance

| Tier | Accessibility | Power | Philosophy |
|---|---|---|---|
| **Common** | Rain from tasks (15-20%), cheap in store | Small effects, short duration | Use freely, multiple per day |
| **Uncommon** | Drop from dungeons, medium store price | Medium effects | Use before big activities |
| **Rare** | Expeditions, forge crafting, premium store | Strong effects | Save for important moments |
| **Expedition-only** | Expedition exclusive | Unique effects | Rare and special |

### Updated Consumable Types

**Existing (keep but rebalance):**

| Type | Change |
|---|---|
| HP Potion | Add Common tier (heal 10 HP, drops from tasks) |
| EXP Boost | Add Common tier (+25% for 1 task, drops from tasks) |
| Gold Boost | Add Common tier (+25% for 1 task, drops from tasks) |
| Mission Speed-Up | Keep as-is |
| Streak Shield | Rename to "Streak Armor," extend to 3 days as standard |
| Stat Food | Keep tiers, add to task drop table |
| Dungeon Revive | Keep as premium |
| Loot Reroll | Keep as premium |

**New consumable types:**

| Type | Effect | Source | Tier |
|---|---|---|---|
| Material Magnet | Double crafting material drops for 5 tasks | Task drops, store | Common |
| Luck Elixir | +20% rare drop chance for next dungeon run | Dungeon boss rooms | Uncommon |
| Party Beacon | +25% party bond EXP for 1 hour | Expeditions, store | Uncommon |
| Affix Scroll | Guarantees at least 1 affix on next equipment drop | Expeditions only | Rare |
| Expedition Compass | Reveals next expedition stage rewards before completion | Expeditions only | Rare |
| Forge Catalyst | Doubles enhancement success chance for 1 attempt | Forge crafting | Uncommon |

### Task Completion Consumable Drops

Common consumables should flow from task completion like water:

```
Task completed → 15-20% chance of consumable drop
  ├── 40% chance: Minor EXP Boost (+25% for 1 task)
  ├── 25% chance: Minor Gold Boost (+25% for 1 task)
  ├── 15% chance: Material Magnet (double materials for 5 tasks)
  ├── 10% chance: Small Stat Snack (+1 to random stat, temporary)
  └── 10% chance: Small HP Potion (heal 10 HP in next dungeon)
```

Players use these casually. No hoarding because they're always getting more. This normalizes consumable usage and makes each task completion more interesting.

---

## Forge Redesign

### Current State: Two Confusing Systems

The app currently has **two separate forge systems**:

1. **Main Forge** (`Views/Forge/ForgeView.swift`) — material-based crafting, 4 tiers, 3-step flow (Slot → Tier → Forge)
2. **Legacy Forge** (`Views/Inventory/ForgeView.swift`) — shard-based salvage/craft/enhance, unlocks at level 10

Problems:
- Two currencies for the same purpose (Forge Shards + Crafting Materials)
- Enhancement is 100% success with no risk — no excitement, no material sink
- Herbs drop from missions but are unused ("Used in future recipes")
- No connection to the affix system
- No way to craft consumables
- Crafting output is fully random — no player agency

### Redesign: One Unified Forge, Four Stations

Merge everything into a single forge with 4 tabs/stations. Kill the Forge Shards currency entirely — salvage returns materials directly.

#### Station 1: Craft

The existing material-based crafting, improved.

| Tier | Output Rarity | Affix Guarantee | Cost (Essence / Materials / Fragments / Gold) |
|---|---|---|---|
| 1 (Apprentice) | Common – Uncommon | None | 3 / 2 / 0 / 0 |
| 2 (Journeyman) | Uncommon – Rare | None | 8 / 5 / 2 / 50 |
| 3 (Artisan) | Rare – Epic | 1 affix guaranteed | 15 / 8 / 5 / 200 |
| 4 (Master) | Epic – Legendary | 1-2 affixes guaranteed | 30 / 15 / 10 / 500 |

**What's new:**
- **Tier 3+ guarantees affixes** — the forge's competitive advantage over random drops. This is why players craft instead of just farming dungeons.
- **Targeted Crafting**: Spend 2x materials to lock the primary stat (e.g., "I want a Strength weapon"). Reduces randomness, increases material sink.
- **Recipes are server-driven** (from `content_forge_recipes` table) — you can add seasonal recipes, event recipes, and new tiers without app updates.

**Consumable Crafting** (new recipe type):
- Herbs (from AFK missions) + Gold → consumables
- Common Herbs → Minor consumables (HP pots, minor boosts)
- Uncommon Herbs → Standard consumables (Luck Elixir, Stat Food)
- Rare Herbs → Strong consumables (Forge Catalyst, Party Beacon)
- This gives Herbs a purpose and gives missions a unique output that feeds back into the forge.

#### Station 2: Enhance

Overhaul from the current 100% success / +1 per level system.

| Level | Success Rate | Cost Multiplier | Stat Gain | On Failure |
|---|---|---|---|---|
| +1 to +3 | 100% | 1x – 2x base | +1 primary | N/A (guaranteed) |
| +4 to +6 | 80% | 3x – 5x base | +1 primary | Materials consumed, level stays |
| +7 to +8 | 60% | 8x – 12x base | +2 primary | Materials consumed, level stays |
| +9 | 40% | 20x base | +2 primary | Materials consumed, level stays |
| +10 | 25% | 40x base | +3 primary + "Perfected" title | Materials consumed, level stays |

**Key design rules:**
- **No downgrade on failure** — materials are consumed but enhancement level never decreases. This is a gold/material sink, not a punishment mechanic.
- **10% Critical Enhancement chance** on any success — double stat bonus for that level. Creates "holy crap" moments.
- **Forge Catalyst** consumable (from expeditions) doubles success rate for 1 attempt. So +10 goes from 25% → 50%.
- Enhancement rules come from `content_enhancement_rules` table — balance-tunable without app updates.

**Base gold costs per rarity:**
- Common: 50g, Uncommon: 100g, Rare: 200g, Epic: 500g, Legendary: 1000g
- Multiply by cost_multiplier per level (e.g., Legendary +10 = 1000 × 40 = 40,000g)

#### Station 3: Salvage

Merge both salvage systems. Kill Forge Shards.

| Rarity | Materials Back | Fragments Back | Gold Back | Affix Recovery Chance |
|---|---|---|---|---|
| Common | 0 | 1 Fragment | 5g | N/A |
| Uncommon | 2 random materials | 0 | 15g | 10% if has affix |
| Rare | 3 random materials | 1 Fragment | 40g | 20% if has affix |
| Epic | 5 random materials | 2 Fragments | 100g | 30% if has affix |
| Legendary | 8 random materials | 4 Fragments | 250g | 50% if has affix |

**Affix Recovery**: When salvaging an item with affixes, there's a chance to recover an **Affix Scroll** containing that affix. This feeds the Affix Station.

**Auto-Salvage** (player-configured rules):
- "Auto-salvage all Common equipment" (toggle)
- "Auto-salvage all equipment below Rare" (toggle)
- "Never auto-salvage items with affixes" (safety toggle, default on)

Salvage rules come from `content_salvage_rules` table.

#### Station 4: Affix Station (New)

The endgame gold sink. Two operations:

**Apply Affix Scroll**: Take a recovered Affix Scroll (from salvage or expedition drop) and apply it to an item with an empty prefix or suffix slot.
- Cost: Gold based on item rarity (100g–500g)
- The affix is guaranteed — no RNG, you pick which scroll to use

**Re-roll Affix**: Spend gold to re-roll an existing prefix OR suffix on an item. Randomizes from the affix pool.
- Cost: **Escalating** — 300g first re-roll, 500g second, 800g third, etc. on the same item
- Resets if you change the other affix slot
- This is where endgame players spend their gold chasing "the perfect piece"
- Re-roll costs come from `content_affix_reroll_costs` table

### Why the Forge Matters

The forge is the **player agency layer** in a loot system that's otherwise RNG-driven:
- Can't get the right drop? **Craft it** (Tier 3+ with guaranteed affixes).
- Got a great base item with bad affixes? **Re-roll** them.
- Got a great affix on trash gear? **Salvage** it, recover the scroll, apply it to better gear.
- Want to push your best item further? **Enhance** it (with risk/reward at higher levels).

Without the forge, players are at the mercy of RNG. With it, they always have a path forward.

### Implementation Notes

- Merge `Views/Forge/ForgeView.swift` and `Views/Inventory/ForgeView.swift` into single unified ForgeView
- Remove `ForgeShards` currency from models and Supabase
- Add `content_forge_recipes`, `content_enhancement_rules`, `content_salvage_rules`, `content_affix_reroll_costs` tables
- Enhancement logic moves from flat +1 to server-driven rules
- Forge recipes support `is_seasonal`, `available_from`, `available_until` for event content

---

## Economy Balance (Faucets & Sinks)

### The Fundamental Rule

**Stuff in ≈ Stuff out.** Without balance: inflation → rewards lose meaning → players disengage.

### Current Faucets (Gold In)

| Source | Gold Per Activity | Frequency | Daily Estimate |
|---|---|---|---|
| Task completion | 10-60 (scaled by level) | 5-10/day | ~200-400 |
| Dungeon completion | 50-200 | 1-2/day | ~150-300 |
| AFK Mission | 20-100 | 1-3/day | ~60-200 |
| Daily quests | 30-100 | 3-5/day | ~100-300 |
| Level-up | 50-500 (scaled) | ~1/2 days | ~100 |
| **Daily Total** | | | **~600-1300 Gold** |

### Current Sinks (Gold Out)

| Sink | Gold Per Use | Frequency | Daily Estimate |
|---|---|---|---|
| Store purchases | 25-1000 | 0-2/day | ~100-200 |
| Forge crafting | 50-300 | 0-1/day | ~50-100 |
| Enhancement | ~10-50 per level | 0-2/day | ~30-60 |
| Consumable purchases | 30-500 | 0-1/day | ~50-100 |
| **Daily Total** | | | **~230-460 Gold** |

**Gap: ~400-850 Gold accumulated daily** with no place to go. By level 30, players are sitting on 10,000+ gold.

### Proposed New Sinks

| Sink | Gold Per Use | Expected Frequency | Purpose |
|---|---|---|---|
| Enhancement (scaled) | 100-40,000 (exponential by rarity × level) | 1-2/week | Major gold sink at high enhancement levels |
| Affix re-roll | 300-10,000 (escalating per re-roll on same item) | 1-3/week | Endgame gold sink, loot customization |
| Affix Scroll application | 100-500 (by item rarity) | 1/week | Controlled affix placement |
| Targeted crafting (2x materials) | 2x recipe gold cost | 1-2/week | Stat-locked crafting |
| Consumable crafting (Herbs) | 50-300 per recipe | 2-3/week | Convert mission herbs to consumables |
| Research tree nodes | 200-1000 per node | 1-2/week | Permanent progression investment |
| Expedition Key purchase | 500-1000 | 1/week | Premium access to expeditions |
| Gear gifting transfer fee | 10% of item value | Occasional | Party feature tax |
| **Estimated Daily Sink** | | | **~500-1200 Gold** |

This brings faucets and sinks into approximate balance. Gold stays meaningful at all levels.

---

## Complete Loot Acquisition Map

> No single source gives everything. Players must engage with multiple systems.

| Loot Type | Tasks | Dungeons | AFK Missions | Expeditions | Forge | Store | Raid Boss | Level-Up |
|---|---|---|---|---|---|---|---|---|
| Common equipment | 5-8% | Per room | 10% | Per stage | Craft (T1-T2) | Buy | - | Every 5 lvl |
| Rare+ equipment | Pity only | Hard+ guaranteed | AFK-only rare table | Exclusive table | Craft (T3-T4, affix guaranteed) | Daily deal | Guaranteed | Milestone |
| Set pieces | - | Party dungeons | - | Expedition loot | High-cost recipe | Rotation | - | - |
| Monster cards | - | 10-15% per room | - | 15-20% per stage | - | - | 100% guaranteed | - |
| Common consumables | 15-20% | Room loot | - | Stage loot | Herb crafting | Buy | - | Random pick |
| Rare consumables | - | Boss rooms | Mission reward | Exclusive | Rare herb crafting | Premium | Completion | Milestone |
| Crafting materials | 30-40% | 60% | 40% (+ Herbs) | 50% | Salvage returns | - | 80% | Random pick |
| Affix Scrolls | - | - | - | Exclusive | Salvage recovery (10-50%) | - | - | - |
| Expedition Keys | - | Hard+ completion | - | - | - | Gold (premium price) | - | - |
| Research Tokens | - | - | Exclusive | - | - | - | - | - |

---

## Expedition System (New)

### What Is It

Expeditions are **long-duration AFK content** (4–24 hours) with multiple stages, narrative logs, and exclusive loot. They live alongside AFK Missions in the Adventures Hub as a separate content tier.

### How It Differs from Missions

| AFK Missions (current) | Expeditions (new) |
|---|---|
| 5–60 minutes | 4–24 hours |
| Single outcome: success/fail | Multi-stage: 3–6 checkpoints |
| Generic rewards | Expedition-exclusive loot table |
| No narrative | Story unfolds stage by stage |
| Solo only | Party expeditions (combine stats) |
| No mid-run engagement | Push notification at each stage |
| Always available | Requires Expedition Keys (from dungeons) |

### Architecture

Expeditions build on top of existing `AFKMission` infrastructure. They don't replace missions — they're a higher tier.

**Models needed:**

```
Expedition
  - id: UUID
  - name: String
  - description: String
  - theme: ExpeditionTheme (ruins, wilderness, ocean, mountains, underworld)
  - stages: [ExpeditionStage]
  - totalDurationSeconds: Int
  - levelRequirement: Int
  - statRequirements: [StatRequirement]
  - isPartyExpedition: Bool
  - exclusiveLootTable: [String]  // catalog IDs only from expeditions

ExpeditionStage
  - name: String
  - narrativeText: String
  - durationSeconds: Int
  - primaryStat: StatType
  - difficultyRating: Int
  - possibleRewards: StageRewards

ActiveExpedition (persisted, like ActiveMission)
  - expeditionID: UUID
  - characterID: UUID
  - partyMemberIDs: [UUID]
  - currentStageIndex: Int
  - stageResults: [StageResult]
  - startedAt: Date
  - nextStageCompletesAt: Date
  - status: ExpeditionStatus (.inProgress, .completed, .failed)

StageResult
  - stageIndex: Int
  - success: Bool
  - narrativeLog: String
  - earnedEXP: Int
  - earnedGold: Int
  - lootDropped: Equipment?
  - materialsDropped: [(MaterialType, ItemRarity, Int)]
```

### Expedition Flow

1. Player unlocks expedition slot (level requirement + Expedition Key item)
2. Chooses an expedition from rotating pool (2–3 available at a time)
3. Optionally invites party members (their stats combine for success calc)
4. Expedition launches — first stage timer starts
5. At each stage completion:
   - Push notification: "Your party reached [Stage Name]. [Narrative]. Loot: [Items]"
   - Results are persisted locally
   - Next stage timer begins automatically
6. After final stage, expedition completes
7. Player opens app to claim all rewards + read full narrative log

### Expedition Keys

- Drop from dungeon completion (1 key per completed dungeon on Hard+ difficulty)
- Can be purchased from store (premium currency)
- Limits expedition runs to ~3–5 per week for engaged players
- Prevents expeditions from replacing dungeons as the main loot source

### Party Expeditions

- All party members contribute stats to success calculation
- Each member gets individual loot rolls (not shared — everyone benefits)
- Bond/Party EXP awarded on completion
- Narrative log references all party members by name

### Why Expeditions Don't Overhaul the Game

- Architecturally: extends `AFKMission` pattern — same persistence, same timer model
- Gameplay: sits alongside missions as a longer-duration option in Adventures Hub
- Economy: expedition-exclusive loot creates a new reason to engage without replacing existing rewards
- Effort: ~1 new model file, ~1 new view, extensions to GameEngine + AdventuresHubView
- Push notifications: already have OneSignal infrastructure

---

## System Interconnection Map

### Current Problem

All systems dump into the same two currencies (EXP and Gold). No system uniquely feeds another.

### Target State

```
Tasks (real-world)
  → EXP + Gold
  → Crafting Materials (feed → Forge)
  → Pity Counter progress (feed → Guaranteed loot drops)
  → Small chance: equipment drop (with affixes)

Dungeons
  → EXP + Gold
  → Equipment drops (with affixes, set pieces)
  → Expedition Keys (feed → Expeditions)
  → Salvageable drops (feed → Forge Shards)

AFK Missions
  → EXP + Gold
  → Mission-exclusive equipment (Rare+)
  → Research Tokens (feed → Passive Progression layer)

Expeditions
  → Expedition-exclusive equipment
  → Rare crafting materials (feed → High-tier Forge recipes)
  → Lore items / collection log entries
  → Party Bond EXP

Forge
  ← Materials from Tasks
  ← Forge Shards from Salvage
  ← Rare Materials from Expeditions
  → Crafted equipment (targeted slot + rarity)
  → Enhanced equipment

Store
  → Equipment (daily rotation)
  → Consumables
  → Expedition Keys (premium)
  → Bundles

Weekly Raid Boss
  → Boss-exclusive equipment
  → Party Bond EXP
  ← Damage from task completion (social incentive)

Party Bond
  → Perks that multiply ALL of the above
  ← EXP from co-op activities, nudges, kudos, shared tasks
```

**Key principle: no single content type gives you everything.** Players must engage with multiple systems to optimize progression.

---

## Passive Progression Layer

### Concept (IdleON-Inspired)

A permanent upgrade system where players invest materials and time for small, stacking bonuses that never reset. This is the "always something cooking" system — even when you've done your daily tasks, something is progressing.

### Research Tree (Working Name: "Study")

**3 branches:**

| Branch | Focus | Example Nodes |
|---|---|---|
| **Combat** | Dungeon & expedition bonuses | +2% dungeon success, +5% boss damage, +1% crit chance |
| **Efficiency** | Mission & task bonuses | -5% mission duration, +3% task EXP, +2% material drop rate |
| **Fortune** | Loot & economy bonuses | +2% rare drop chance, +5% gold, +1% affix chance |

**Mechanics:**
- Each node costs materials + gold + time (1–8 hours to "research")
- Only one node researches at a time (like a single build queue)
- Nodes unlock in order within each branch
- Bonuses are permanent and never reset
- Higher-tier nodes require completion of lower nodes

**Funded by:**
- Crafting materials (from tasks)
- Research Tokens (from AFK missions — exclusive to this system)
- Gold

### Why This Matters

Without a passive progression system, players hit a ceiling where they've done their tasks, their mission is running, and there's nothing else to do. The research tree gives them something to invest in and come back to check on. It's the IdleON philosophy: **your account is always getting stronger, even when you're not actively playing.**

---

## Class System Depth & AFK Combat Model

### What Classes Already Do

Classes are more than stat distributions — they already affect gameplay:

| Feature | How Class Matters |
|---|---|
| Dungeon combat | Warrior +25% on Combat rooms, Mage +25% on Puzzle, Archer +20% on Traps |
| Advanced abilities | Paladin: -50% party damage. Enchanter: +20% party power. Trickster: +25% loot. Ranger: -15% mission time. |
| Gear sets | Class-locked (Warrior/Mage/Archer lines) |
| Milestone gear | Class-specific equipment at level milestones |
| Avatar icons | Class affinity filtering |
| Class evolution | Level 20 branching (Warrior → Berserker/Paladin, etc.) |

### What's Missing: Class → Task Connection

Classes affect dungeons and missions, but NOT tasks — the thing players do 5-10x per day. A Warrior and a Mage who both complete "Go to the gym" get identical rewards. This breaks the class identity in the core loop.

**Class Task Affinity (New):**

| Class Line | Primary Category | Bonus |
|---|---|---|
| Warrior / Berserker / Paladin | Physical | +15% EXP from Physical tasks |
| Mage / Sorcerer / Enchanter | Mental | +15% EXP from Mental tasks |
| Archer / Ranger / Trickster | Creative + Social | +10% EXP from Creative and Social tasks |

- Doesn't punish other categories — just gives a small bonus to the affinity
- Reinforces class identity in the core loop
- Creates organic fit between player personality and class choice ("I chose Mage because I'm a student")
- Implementation: one multiplier check in `GameEngine.completeTask()`

**Class-flavored completion messages:**
- Warrior: "The Warrior's discipline pays off."
- Mage: "The Mage's focus sharpens."
- Archer: "The Archer's keen eye strikes true."

**Class affix preference:** When rolling affixes, each class line has a slightly higher chance (+10%) of rolling affixes that match their primary stat. Warriors see more Strength affixes, Mages more Wisdom. Subtle but reinforces identity.

### How Classes Affect ALL AFK Content

Every piece of AFK content should consider your class, stats, equipment, affixes, gear set bonus, and card bonuses. Here's the unified model:

#### Power Score Calculation

Every AFK activity (dungeon room, arena wave, mission, expedition stage, raid boss tick) uses the same **Power Score** formula:

```
Power Score = Base Stat Power
            + Equipment Bonus
            + Affix Effects
            + Gear Set Bonus
            + Card Collection Bonuses
            + Research Tree Bonuses
            + Party Power (if applicable)
            + Consumable Buffs (if active)
```

**Base Stat Power** (what the room/stage cares about):
- Each room/stage has a `primary_stat` (e.g., Strength for combat rooms)
- Power = `effectiveStat[primary_stat]` (base + allocated + equipment + class passive)

**Class Encounter Bonus** (existing, keep):

| Class | Encounter Type | Bonus |
|---|---|---|
| Warrior | Combat | +25% |
| Berserker | Combat | +40% |
| Mage | Puzzle | +25% |
| Sorcerer | Puzzle | +40% |
| Archer | Trap | +20% |
| Ranger | Trap | +30% |
| Paladin | Boss | +20% (party takes -50% damage) |
| Enchanter | Any (party) | +20% to all party members' power |
| Trickster | Any | +25% loot drop chance on success |

**Equipment Contribution:**
- Primary stat from each equipped item adds to Base Stat Power
- Secondary stats add at 50% rate
- Enhancement levels add their bonus to primary stat

**Affix Effects (new — affixes that matter in AFK):**

| Affix | Effect in AFK Content |
|---|---|
| Vigilant | +X% dungeon success chance (direct power boost) |
| of Warding | +X flat defense (reduces damage from failed rooms) |
| of Haste | -X% dungeon room time (faster completion) |
| Swift | -X% mission duration |
| of the Pathfinder | +X% expedition stage success |
| Lucky / of Fortune | +X% loot drop chance on success |

Affixes that are task-specific (Blazing, Scholarly, etc.) do NOT affect AFK content — they're IRL bonuses only. This keeps the two systems distinct.

**Gear Set Bonus:**

| Set | Effect in AFK |
|---|---|
| Vanguard's Resolve | +10% Defense in dungeons → reduces damage from failed rooms |
| Arcanum's Embrace | -10% AFK mission time → missions complete faster |
| Windstrider's Mark | +10% loot drop chance → better loot from all AFK content |

**Card Collection Bonuses** (passive, always active):
- +Dungeon success% cards directly boost room success chance
- +Mission speed% cards reduce mission timer
- +Loot drop chance% cards improve drop rates everywhere
- These are individually tiny (+0.3–0.5% each) but stack across 20-30 collected cards

**Consumable Buffs** (temporary, player-activated):
- EXP Boost: +X% EXP from next dungeon/mission
- Luck Elixir: +20% rare drop chance for next dungeon run
- Forge Catalyst: +X% enhancement success (forge only, not AFK combat)
- Stat Food: +X to a stat for Y minutes (affects Power Score calculation)

#### How Each AFK Content Type Uses Power Score

**Dungeons (per room):**
```
Room Power Needed = room.difficulty_rating × dungeon_difficulty_multiplier
Your Power = Power Score for room.primary_stat
Success Chance = (Your Power / Room Power Needed) × 100, capped at 95%
Class bonus applied if encounter_type matches
On Success: EXP + Gold + loot roll + card roll
On Failure: Reduced EXP, no loot, HP damage (Paladin reduces for party)
```

**Arena (per wave):**
```
Wave Difficulty = base × (1 + 0.15 × wave_number)
Your Power = average of top 3 stats (encourages balanced builds)
Success: next wave. Failure: arena ends.
Rewards at wave milestones (5, 10, 15, 20, 25)
Card drop chance at milestone waves (20%)
```

**AFK Missions:**
```
Success Rate = base_success_rate × (relevant_stat / stat_requirement)
Duration = base_duration × (1 - Ranger bonus - Arcanum set - mission_speed_cards - Swift affix)
Loot Quality = mission.rarity tier, modified by Luck stat + Trickster bonus + Fortune affix
```

**Expeditions (per stage):**
```
Stage Power = stage.difficulty_rating
Your Power = Power Score for stage.primary_stat
  + Party member contributions (with diminishing returns)
Success Chance = (Combined Power / Stage Power) × 100, capped at 90%
Each stage: independent roll. Can succeed some, fail others.
Failed stages: reduced rewards but expedition continues.
Narrative log describes outcomes based on class + success/failure.
```

**Weekly Raid Boss:**
```
Damage Per Tick = Sum of all party members' task completions × damage_multiplier
damage_multiplier = base × (1 + class_bonuses + equipment_bonuses + card_bonuses)
Boss HP scales with party size (so bigger parties don't trivially one-shot)
Rewards: guaranteed equipment + card on kill
```

### Why This Matters

When everything feeds into Power Score, the player sees a clear connection:
- "I completed Physical tasks → my Strength went up → my dungeon success rate improved → I got better loot → I enhanced my weapon → my Power Score went up more"
- "I collected 10 cards → my passive dungeon success bonus went up 2% → I can tackle harder dungeons"
- "I crafted gear with the Vigilant affix → my dungeon success jumped 5%"

Every system reinforces every other system. Nothing exists in isolation.

---

## Onboarding / First 5 Minutes

### Current State

Auth → Character Creation (5-step wizard: Class → Zodiac → Stats → Name/Avatar → Review). After creation, user lands on the main TabView with no guidance. No tutorial, no first task, no "aha moment."

### The Problem

A new user creates a character and sees: empty task list, empty inventory, unfamiliar tabs. They have no context for what anything means, no reason to come back, and no demonstration of the core value proposition ("real tasks → RPG rewards").

### Proposed Onboarding Flow

**Step 1: First Task (forced, ~30 seconds)**

Immediately after character creation, before showing the main app:

"Every hero starts somewhere. What's one thing you want to do today?"

- 6 pre-filled suggestions, one per category:
  - "Go for a walk" (Physical)
  - "Read for 15 minutes" (Mental)
  - "Text a friend" (Social)
  - "Clean your desk" (Household)
  - "Take 5 deep breaths" (Wellness)
  - "Draw or write something" (Creative)
- Player picks one OR types custom
- Quick-verify auto-set (one-tap completion)

**Step 2: Complete It (~10 seconds)**

"Complete this task to earn your first rewards."

- Player taps the complete button
- Full reward animation plays: haptic pulse + sound + EXP/Gold fly to counters + potential loot roll
- "You earned 25 EXP and 10 Gold! Every task you complete makes your character stronger."

This IS the aha moment. They see the game respond to a real-world action.

**Step 3: Quick Tour (contextual tooltips, ~15 seconds)**

Highlight 3 key tabs with dismissible tooltips:
1. Character tab: "This is your hero. Complete tasks to level up."
2. Adventures tab: "Run dungeons and AFK missions to earn loot."
3. Party tab: "Invite up to 3 friends to keep each other accountable."

**Step 4: Starter Gift**

- Grant starter equipment set (Common weapon + armor for their class)
- Show equipping flow: "Equip your gear to boost your stats."
- Teaches inventory/equipment in context

**Step 5: Set Habits (optional, skippable)**

"Want to set up a daily routine? Pick habits you want to build."

- Category-grouped suggestions (Morning routine, Exercise, Reading, etc.)
- Skip button prominently available
- If they set habits, task list is immediately populated

**Post-Onboarding Breadcrumbs (first week):**

A subtle "Quest Log" banner on the Home screen that guides without being intrusive:
- Day 1: "Try your first dungeon" (link to Adventures)
- Day 2: "Send your character on a mission" (link to AFK Missions)
- Day 3: "Invite a friend to your party" (link to Party tab)
- Day 4: "Visit the Forge" (link to Forge)
- Day 5: "Check the Store for daily deals" (link to Store)

Each breadcrumb disappears after the action is taken. All gone after 7 days regardless.

### Implementation Notes

- New `OnboardingView.swift` — post-creation guided flow
- `PlayerCharacter.hasCompletedOnboarding: Bool` flag
- `PlayerCharacter.onboardingBreadcrumbs: [String: Bool]` for tracking breadcrumb completion
- Onboarding task is a real `GameTask` — completion actually gives EXP/Gold
- Total onboarding time: **under 2 minutes** after character creation

---

## Retention & Re-engagement

### What Exists

- **Streaks:** Main streak + per-habit + mood + meditation (up to +50% EXP/Gold)
- **Notifications:** 7 local types + 9 partner types. Streak-at-risk at 8 PM.
- **Daily content:** Quests, shop, arena refresh daily

### What's Missing

#### Daily Login Reward

The simplest retention mechanic in mobile gaming. 7-day cycle:

| Day | Reward |
|---|---|
| 1 | 50 Gold |
| 2 | 1 Common Consumable |
| 3 | 100 Gold |
| 4 | 1 Crafting Material |
| 5 | 150 Gold + 1 Uncommon Consumable |
| 6 | 2 Crafting Materials |
| 7 | 250 Gold + Bonus Loot Roll (Rare+ chance) |

Resets after Day 7, cycles again. Displayed as a calendar card on Home screen. Claim on first app open of the day.

#### Comeback Mechanic (Lapsed Users)

`lastActiveAt` is tracked but unused. When someone returns after 3+ days:

**"Welcome Back" screen:**
- "You were gone for X days. Your character rested and recovered."
- Show: party member activity, accumulated AFK rewards, new content added

**Comeback gift (scales with absence):**

| Absence | Gift |
|---|---|
| 3-7 days | 200 Gold + 1 random consumable |
| 7-14 days | 500 Gold + 1 Uncommon+ equipment |
| 14-30 days | 1000 Gold + 1 Rare+ equipment + "Welcome Back" title |
| 30+ days | All above + 24-hour EXP boost |

**Streak recovery offer:**
"Your 15-day streak was broken. Complete 3 tasks today to start a new one. Here's a free Streak Armor."

**Tone: never guilt. Never say "you lost X."** Say "here's what's waiting for you."

#### Re-engagement Push Notifications

| Absence | Push Copy |
|---|---|
| 2 days | "Your party misses you. [Name] completed 3 tasks yesterday." |
| 5 days | "Your character is resting at camp. Come back to claim [X] Gold." |
| 14 days | "New dungeons added since you left. Your adventurer awaits." |
| 30+ days | Silence. Don't annoy people who've moved on. |

Cap: 3 re-engagement notifications total per lapse. Respect the user.

#### Notification Frequency Framework

| Type | Frequency | Priority |
|---|---|---|
| Streak at risk | 1x/day at 8 PM | High |
| Mission/dungeon complete | Immediate | Medium |
| Party member activity | Batch 1x/day evening summary | Medium |
| Daily login reward | 1x/day morning if not opened | Low |
| Comeback | Max 3 total per lapse, spaced 2+ days | Low |
| Daily reset | **Remove** — it's noise, not useful | — |

**Rule: never more than 2 push notifications per day.** Streak-at-risk + mission-complete = cap. Everything else batches into evening summary.

#### Implementation Notes

- `PlayerCharacter.lastActiveAt: Date` — already exists, use for absence detection
- `PlayerCharacter.loginStreakDay: Int` (1-7) — new field for daily login cycle
- `PlayerCharacter.lastLoginRewardDate: Date` — prevent double-claiming
- `PlayerCharacter.comebackGiftClaimed: Bool` — one-time per lapse
- `WelcomeBackView.swift` — new view shown when `daysSinceLastActive > 3`
- Re-engagement notifications: schedule on app backgrounding, cancel on foreground

---

## End-Game / Prestige System

### Current State

Level cap: 100. Title: "Transcendent." Achievement: 50 Gems. After that — nothing. EXP accumulates but does nothing. The most engaged players hit a wall.

### Prestige System: "Rebirth"

At level 100, the player can choose to **Rebirth**:

**What you keep:**
- All equipment, cards, achievements, party, bond progress, research tree
- Your accumulated wealth (gold, gems, materials)

**What resets:**
- Level → 1
- Stat points → re-allocated on level-up (chance to try a different build)
- Class → resets to starter (can re-evolve at 20 — try the other path)

**What you gain:**

| Rebirth # | Permanent Bonus | Title |
|---|---|---|
| 1st | +5% EXP from all sources forever | "Reborn" |
| 2nd | +5% Gold from all sources forever | "Twice-Forged" |
| 3rd | +5% Loot drop chance forever | "Thrice-Blessed" |
| 4th | +3% all stats forever | "Ascendant" |
| 5th+ | +1% all stats per rebirth (stacking) | "Eternal [Class]" |

**Visual marker:** Rebirth Star displayed on avatar frame. Party members and leaderboard see your rebirth count. It's social currency.

**Why this works:**
- Re-leveling is faster with rebirth bonuses + kept equipment
- Trying the other evolution path adds variety (Warrior who was Berserker can now try Paladin)
- Permanent stacking bonuses mean your 3rd playthrough is meaningfully stronger
- All existing content stays relevant — you re-run dungeons with better gear
- Proven pattern from idle games (IdleON, Realm Grinder, Clicker Heroes)

**Alternative for launch (simpler):** If rebirth is too complex for v1, implement **Paragon Levels** — every "level" after 100 gives +1 to a random stat + small gold reward. No reset, just infinite slow progression. Less exciting but zero-effort implementation.

### Implementation Notes

- `PlayerCharacter.rebirthCount: Int` — default 0
- `PlayerCharacter.permanentBonuses: [String: Double]` — accumulated rebirth bonuses
- `RebirthView.swift` — confirmation screen showing what you keep/lose/gain
- Rebirth triggers: re-run character creation for stat allocation only (skip name/avatar/class)
- Rebirth star: new avatar frame tier above Gold

---

## Achievements System (Expanded)

### Current: 16 Achievements

7 categories: Tasks (4), Streaks (3), Levels (4), Dungeons (2), Couples (2), Collector (2), Class (2).

### Expanded: 40 Achievements

Add 24 new achievements for all new systems. Achievement definitions should move to `content_achievements` Supabase table (part of content pipeline).

**Monster Cards (4):**

| Achievement | Condition | Reward |
|---|---|---|
| Card Collector | Collect 10 cards | 200 Gold |
| Bestiary Scholar | Collect 25 cards | 3 Gems |
| Monster Expert | Collect 50 cards | 10 Gems |
| Monster Scholar | Collect all cards | Title + unique equipment |

**Forge (4):**

| Achievement | Condition | Reward |
|---|---|---|
| Apprentice Smith | Craft 1 item | 100 EXP |
| Master Craftsman | Craft 25 items | 500 Gold |
| Perfection | Enhance an item to +10 | 10 Gems |
| Affix Hunter | Own item with both prefix and suffix | 3 Gems |

**Party (4):**

| Achievement | Condition | Reward |
|---|---|---|
| Stronger Together | Join or create a party | 100 EXP |
| Full Party | Have a 4-person party | 200 Gold |
| Iron Chain | Party streak of 7 days | 5 Gems |
| Unbreakable Bond | Party streak of 30 days | 15 Gems |

**Expeditions (3):**

| Achievement | Condition | Reward |
|---|---|---|
| Explorer | Complete 1 expedition | 200 EXP |
| Veteran Explorer | Complete 10 expeditions | 5 Gems |
| Into the Unknown | Complete a 24-hour expedition | 10 Gems |

**Loot (3):**

| Achievement | Condition | Reward |
|---|---|---|
| Lucky Find | Get equipment drop from a task | 100 Gold |
| Affixed | Get item with a Greater Affix | 5 Gems |
| Suited Up | Activate a gear set bonus (2pc equipped) | 500 Gold |

**IRL Milestones (4):**

| Achievement | Condition | Reward |
|---|---|---|
| Morning Person | Complete a routine bundle 7 days in a row | 200 Gold |
| Category Master | Reach mastery level 10 in any category | 5 Gems |
| Personal Best | Set a new personal record (most tasks/day) | 200 EXP |
| Habit Machine | Maintain 5 simultaneous habit streaks of 7+ days | 10 Gems |

**Rebirth (2):**

| Achievement | Condition | Reward |
|---|---|---|
| Reborn | Complete first rebirth | 500 Gold + Title |
| Eternal | Complete 5 rebirths | 50 Gems + Title |

### Implementation Notes

- Add `content_achievements` table to Supabase (content pipeline)
- Each achievement: `id`, `name`, `description`, `icon`, `category`, `tracking_key`, `target_value`, `reward_type`, `reward_amount`, `active`
- Existing 16 achievements migrate to the table
- `AchievementTracker.checkAll()` already runs after task/dungeon/mission completion — extend to check new categories
- New tracking keys: `cardsCollected`, `itemsCrafted`, `maxEnhancementLevel`, `partyStreakDays`, `expeditionsCompleted`, `rebirthCount`, `routineStreakDays`, `categoryMasteryMax`, `simultaneousStreaks`

---

## Content Pipeline (Server-Driven)

### The Problem: Everything Is Hard-Coded

The app currently has **~400+ content items** defined as static Swift arrays across 8+ files:

| Content | Count | File | Lines |
|---|---|---|---|
| Equipment templates | 110 | `EquipmentCatalog.swift` | 1,198 |
| Milestone gear | 40 | `MilestoneGearCatalog.swift` | 392 |
| Consumable templates | 23 | `Consumable.swift` | 580 |
| Dungeon templates | 6 (31 rooms) | `Dungeon.swift` | 965 |
| AFK Missions | 5 | `AFKMission.swift` | 388 |
| Duty board tasks | 35 | `DutyBoardGenerator.swift` | 276 |
| Gear sets | 3 | `GearSetCatalog.swift` | 327 |
| Dialogue/narrative | ~160 lines | Shopkeeper/Forgekeeper + dungeon | ~200 |

Every new dungeon, equipment piece, card, or balance tweak requires editing Swift, building, App Store review (1-3 days), and user updates.

### The Solution: Supabase Content Tables

Move all game content definitions to `content_*` tables in Supabase. The app caches content locally and syncs when the server version changes.

**What moves to Supabase (updated frequently):**

| Content | Supabase Table | Update Frequency |
|---|---|---|
| Equipment catalog | `content_equipment` | Weekly-monthly |
| Milestone gear | `content_milestone_gear` | Quarterly |
| Monster cards | `content_cards` | Monthly (with new dungeons) |
| Dungeon templates | `content_dungeons` | Bi-weekly |
| AFK Mission templates | `content_missions` | Monthly |
| Expedition templates | `content_expeditions` | Monthly |
| Consumable definitions | `content_consumables` | Occasional |
| Gear set definitions | `content_gear_sets` | Quarterly |
| Affix pool | `content_affixes` | Monthly |
| Forge recipes | `content_forge_recipes` | Monthly (seasonal events) |
| Enhancement rules | `content_enhancement_rules` | Rare (balance only) |
| Salvage rules | `content_salvage_rules` | Rare (balance only) |
| Drop rate tables | `content_drop_rates` | Weekly (balance tuning) |
| Duty board tasks | `content_duties` | Monthly (seasonal pools) |
| Narrative text | `content_narratives` | Ongoing |
| Affix re-roll costs | `content_affix_reroll_costs` | Rare (balance only) |
| Collection milestones | `content_collection_milestones` | Rare |
| Store bundles | `content_store_bundles` | Monthly (seasonal deals) |

**What stays in Swift (rarely changes, core logic):**

| Content | Why |
|---|---|
| Enum definitions (EquipmentSlot, ItemRarity, StatType, etc.) | Type-safe code, not data |
| Stat formulas (EXP curve, damage calc, success rate) | Logic, not data |
| UI layout and views | Obviously |
| LootGenerator structure | The rolling/generation logic stays; the data it reads comes from server |

### Content Versioning

A single `content_version` table with one row tracks the current version number. Every time any content table changes, a trigger auto-increments the version.

```
App launch
  → Fetch content_version.version (1 lightweight query)
  → If server version > local cached version:
      → Re-fetch all content tables
      → Store in local cache (SwiftData or JSON in UserDefaults)
      → Update local version number
  → If equal: use local cache (instant, works offline)
  → If offline: use local cache (always works)
```

**Benefits:**
- Content updates ship instantly — no App Store review
- One query to check, not N queries per table
- App always works offline from cache
- First launch pulls everything, subsequent launches only re-fetch on changes

### Content Tables Are Public Read

Content tables define the game world, not user data. They use `USING (TRUE)` RLS policies — anyone can read. Only `service_role` (admin) can write. This makes queries simple, fast, and cacheable.

### What This Enables

| Capability | Before (Hard-Coded) | After (Server-Driven) |
|---|---|---|
| Add a new dungeon | Edit Swift → Build → App Store review → User update | Insert row in Supabase → Users see it on next refresh |
| Tweak drop rates | Same as above | Update `content_drop_rates` row → Live in seconds |
| Seasonal event | Impossible without app update | Set `is_seasonal`, `available_from`, `available_until` on recipes/bundles/duties |
| A/B test loot balance | Impossible | Adjust `content_drop_rates` for a subset, measure engagement |
| Add 50 monster cards | Edit catalog file, add 50 structs | Batch insert into `content_cards` |
| Holiday forge recipe | Impossible | Insert recipe with date range, it auto-appears and auto-expires |

### Migration Plan

The migration from hard-coded to server-driven is **backward-compatible**:

1. Create all `content_*` tables (migration `005_content_tables.sql`)
2. Write a seed script that copies existing catalog data into the tables
3. Add `ContentManager` service in Swift that:
   - Checks `content_version` on app launch
   - Fetches and caches content tables locally
   - Provides typed access (`ContentManager.shared.equipment`, `.cards`, `.dungeons`, etc.)
4. Update `LootGenerator`, `DungeonEngine`, `GameEngine`, etc. to read from `ContentManager` instead of static arrays
5. Keep static arrays as **fallback** for first-run-offline scenarios (ship a bundled JSON snapshot)
6. Once verified, remove the static Swift catalogs

### Supabase Migration File

Full schema: `migrations/005_content_tables.sql`

Tables created:
- `content_version` — cache invalidation (auto-bumps on any content change)
- `content_equipment` — 110+ equipment templates (replaces `EquipmentCatalog.swift`)
- `content_milestone_gear` — 40 class milestone items (replaces `MilestoneGearCatalog.swift`)
- `content_gear_sets` — gear set definitions with 2pc bonuses
- `content_cards` — 50+ monster card definitions
- `content_dungeons` — dungeon templates with JSONB rooms
- `content_missions` — AFK mission templates
- `content_expeditions` — expedition templates with JSONB stages
- `content_affixes` — prefix/suffix affix pool
- `content_consumables` — consumable definitions
- `content_forge_recipes` — crafting recipes (supports seasonal gating)
- `content_enhancement_rules` — enhancement tiers (seeded with default values)
- `content_salvage_rules` — salvage return rates (seeded with default values)
- `content_drop_rates` — drop chances and rarity weights per content source (seeded with all defaults from this doc)
- `content_duties` — duty board task templates
- `content_narratives` — all dialogue and narrative text
- `content_affix_reroll_costs` — escalating re-roll gold costs (seeded 300 → 10,000)
- `content_collection_milestones` — card collection rewards (seeded 10/25/50/75/100)
- `content_store_bundles` — store bundle deals with seasonal support

Player data tables also created:
- `player_cards` — tracks which cards each player has collected
- `parties` — 1-4 member party with bond tracking and streak
- `party_feed` — activity log with realtime subscription
- `active_expeditions` — in-progress expedition state

Helper views: `active_forge_recipes`, `active_store_bundles`, `active_duties` (auto-filter expired seasonal content)

---

## Data Architecture & Sync Strategy

### The Problem

Most player game state lives in **local SwiftData only**. Supabase stores a partial character snapshot (JSONB blob) and partner-related data, but the majority of a player's progress has **no cloud backup**.

**What syncs to Supabase today (safe):**
- Character snapshot (level, stats, gold, gems, streaks, class — partial JSONB blob)
- Equipment (individual items in `equipment` table)
- Consumables (individual items)
- Crafting materials (quantity stacks)
- Partner-assigned tasks

**What is LOCAL-ONLY (at risk of permanent loss):**

| Data | Risk |
|---|---|
| **Achievements** | All 16 (soon 40) achievements — gone on reinstall |
| **Self-assigned tasks** | Every task the player created — gone |
| **Goals** | All goal progress and milestones — gone |
| **Dungeon run history** | All runs — gone |
| **Arena records** | Best wave, run history — gone |
| **AFK mission history** | All completed missions — gone |
| **Bond / party data** | Bond level, bond EXP, perk unlocks — gone |
| **Mood entries** | Wellness tracking history — gone |
| **Daily quest progress** | Current quests — gone |
| **Raid boss state** | Weekly boss progress — gone |
| **Daily counters** | Tasks today, duties today — not even in the snapshot |
| **Custom avatar photo** | Photo data — gone |
| **Equipment loadout** | Saved loadout — gone |

**When data loss happens:**
- New phone
- App reinstall
- iOS storage pressure cleanup
- SwiftData migration failure (current code deletes the store on failure)

**Other problems:**
- **No conflict resolution** — two devices with same account: last write wins, no merge
- **Multi-device doesn't work** — play on iPhone, switch to iPad, half your data is missing
- **Partial snapshot** — character JSONB blob doesn't include daily counters, dates, or attempt trackers
- **Achievements can't be recovered** — local SwiftData with no cloud copy
- **Bond is local-only** — the core social feature has no server-side truth

### The Decision: Hybrid Sync (Option A for progression, Option B for ephemeral)

**Must sync (affects progression):**

| New Supabase Table | Purpose |
|---|---|
| `player_achievements` | Achievement progress + unlock timestamps |
| `player_tasks` | ALL tasks (self-created + partner-assigned, unified) |
| `player_goals` | Goal progress, milestone completions |
| `player_daily_state` | Daily counters, streak dates, last reset timestamp |
| `player_mood_entries` | Wellness tracking (mood + journal) |
| `player_arena_runs` | Arena personal bests + history |
| `player_dungeon_runs` | Run history (for stats display, not replay) |
| `player_mission_history` | Completed AFK mission log |

**The `profiles.character_data` JSONB snapshot becomes comprehensive** — every field, every counter, every date. Not a subset.

**Sync pattern:**
```
User action (complete task, level up, etc.)
  → Write to local SwiftData (immediate, offline-safe)
  → Queue sync to Supabase (async, retry on failure)
  → On conflict: timestamp comparison, most recent wins
  → On app launch: pull from Supabase, merge with local
```

**Don't need to sync (regenerated on launch):**
- Daily quests (generated daily from content tables)
- Active mission timer (already persisted via UserDefaults)

### Sync Implementation Decisions

- **Sync frequency:** Queue on every write, flush the queue every 30 seconds + on app background. Writes captured immediately, network traffic batched.
- **Conflict resolution:** Timestamp-based last-write-wins. Two devices simultaneously is an edge case. Full field-level merging is overkill.
- **Failure handling:** Silent retry with exponential backoff. Subtle "sync pending" icon appears only after 3 consecutive failures. Never block gameplay for sync.
- **Initial migration:** On first launch after update, bulk upload all local data to Supabase. One-time "Backing up your progress..." loading screen. After that, normal sync resumes.

### Why This Must Happen Before Phase 0

Every agent that writes data (task completion, dungeon runs, achievements, etc.) needs to know whether they write to local-only SwiftData or to local + queue-to-cloud. This is a foundational decision that affects every feature. If we build Phase 0–5 on local-only SwiftData and then try to add sync later, we'd need to retrofit every write path in the app.

**Phase -1: Data Architecture** happens first. It creates the sync infrastructure so every subsequent phase writes to both local and cloud from day one.

---

## Dungeon / Arena / Training Content Expansion

### Current Content — The Problem Is Volume, Not Mechanics

The dungeon engine, arena system, and AFK mission timer all work well mechanically. The issue is **thin content**:

**Dungeons: 6 total, with large gaps**

| Dungeon | Difficulty | Level Req | Rooms | Theme |
|---|---|---|---|---|
| Goblin Caves | Normal | 1 | 3 | Goblin |
| Ancient Ruins | Normal | 5 | 4 | Undead/Ruins |
| Shadow Forest | Hard | 10 | 5 | Forest/Nature |
| Iron Fortress | Hard | 15 | 6 | Fortress/Metal |
| Dragon's Peak | Heroic | 25 | 6 | Mountain/Dragon |
| The Abyss | Mythic | 40 | 7 | Abyss/Void |

**Problems:**
- Lv15 → Lv25 is a 10-level gap with no new dungeon
- Lv25 → Lv40 is a 15-level gap
- Nothing above Lv40 (players can reach 100)
- Only 1 Mythic dungeon — endgame has 1 option
- Rooms are static — same rooms every re-run, no variety
- Only 6 themes for monster cards (limits card variety)

**Training (AFK Missions): Only 5 templates**

| Mission | Rarity | Duration |
|---|---|---|
| Forest Patrol | Common | 1hr |
| Goblin Skirmish | Common | 2hr |
| Library Research | Uncommon | 4hr |
| Merchant Negotiations | Uncommon | 3hr |
| Dragon's Lair | Epic | 8hr |

- No Rare or Legendary missions exist
- Players will see the same 5 missions over and over
- All 5 are hard-coded in `AFKMission.swift` (moving to `content_missions` table)

**Arena: Basic but functional**
- Fixed 10 waves, same pattern every run
- 1 free daily entry, 50g additional entries
- Linear reward scaling (no exciting breakpoints)
- No weekly variation, no modifiers, no leaderboard

### Proposed Content Expansion

**Dungeons: Target 15-20 at launch**

Fill every level bracket with at least 1 dungeon, and give endgame players 3–4 options:

| Level Range | Difficulty | # Needed | Notes |
|---|---|---|---|
| 1–5 | Normal | 2 | (have 2) Tutorial-friendly |
| 6–14 | Hard | 2 | (have 2) Introduce harder mechanics |
| 15–24 | Hard/Heroic | 2 | **GAP — need 2 new** |
| 25–39 | Heroic | 2 | (have 1 — need 1 more) |
| 40–59 | Mythic | 2 | (have 1 — need 1 more) |
| 60–79 | Mythic | 2 | **GAP — need 2 new** |
| 80–100 | Mythic+ | 3 | **GAP — need 3 new** |

That's ~8 new dungeons minimum. Each new dungeon = a new theme = 3–5 new monster cards.

**Room variety:** Add room modifier system — same dungeon can have shuffled rooms on re-run:
- Room pool per dungeon (8–10 rooms defined, 5–7 selected per run)
- Bonus rooms (rare spawn, better loot)
- Room modifiers from server (`content_dungeons.rooms` JSONB can hold a pool, not just a fixed list)

**AFK Missions: Target 15-20 templates**

Fill every rarity tier and mission type:

| Rarity | # Needed | Duration Range | Notes |
|---|---|---|---|
| Common | 4 | 30min–2hr | Quick missions, low reward |
| Uncommon | 4 | 2–4hr | Medium missions |
| Rare | 4 | 4–8hr | **NEW TIER** — good rewards |
| Epic | 3 | 8–12hr | Overnight missions |
| Legendary | 2 | 12–24hr | **NEW TIER** — best AFK rewards |

All loaded from `content_missions` table — can add more via Supabase without app update.

**Arena improvements:**
- Wave modifiers (weekly rotation): "Armored Foes" (+defense), "Glass Cannon" (+damage, -HP), "Time Trial" (faster timer), "Boss Rush" (all bosses)
- Milestone wave rewards at 5/10/15/20 waves
- Extend beyond 10 waves for high-level players (scale infinitely, leaderboard tracks best wave)
- Weekly arena leaderboard (party-wide or global)
- Arena-exclusive card drops at milestone waves

### Content Pipeline Integration

All dungeon/mission/arena content is defined in Supabase `content_*` tables. This means:
- New dungeons can be added as server-side "content drops" — no app update needed
- Seasonal/event dungeons can have start/end dates
- Arena modifiers can rotate weekly via server schedule
- Mission templates can expand without code changes

This is a **content authoring task**, not a systems task. The engine works — it just needs more fuel.

---

## Daily Quest System

### What's Built

3 daily quests + 1 bonus quest, regenerated each day. Quest types:

| Quest Type | Example | Tracking |
|---|---|---|
| `completeTasks` | "Complete 3 tasks" | Count tasks completed today |
| `completeCategory` | "Complete 2 Physical tasks" | Count by category |
| `startTraining` | "Start a training mission" | Boolean — any mission started |
| `clearDungeonRooms` | "Clear 5 dungeon rooms" | Count rooms cleared today |
| `earnExp` | "Earn 500 EXP" | Sum EXP earned today |
| `earnGold` | "Earn 200 Gold" | Sum Gold earned today |
| `maintainStreak` | "Maintain your daily streak" | Streak ≥ 1 |

Rewards are level-scaled (higher level → more gold/EXP). The bonus quest requires all 3 daily quests to be completed first.

### What Needs Discussion

**Current issues:**
- Quest pool is small — players see the same quest types repeatedly
- No party-focused quests ("Ally completes a task while you're online")
- No adventure-focused quests beyond "clear rooms" / "start training"
- Bonus quest is always just "complete all 3" — could be more interesting

**Proposed improvements:**
- **Expand quest pool** with new types:
  - `forgeItem` — "Forge or enhance 1 item"
  - `useConsumable` — "Use a consumable"
  - `completeArenaWave` — "Reach wave 5 in Arena"
  - `checkMood` — "Log your mood today"
  - `completeDuty` — "Complete a duty board task"
  - `partyTaskSync` — "Complete a task within 1 hour of a party member"
  - `attemptCardContent` — "Attempt content that can drop a card" (replaces `collectCard` — avoids RNG frustration)
- **Quest difficulty tiers** that scale with level (not just reward amounts — harder objectives)
- **Weekly bonus quest** (complete all daily quests 5/7 days → weekly reward chest)
- **Move quest definitions to `content_quests` table** — server-driven so new types, seasonal quests, and weight adjustments don't need app updates

### Decisions Made

- **Quest count:** Keep 3+1 bonus. Variety comes from expanded pool, not more quests.
- **New quest types:** All 7 new types confirmed (forgeItem, useConsumable, completeArenaWave, checkMood, completeDuty, partyTaskSync, attemptCardContent). `collectCard` replaced with `attemptCardContent` to avoid RNG frustration.
- **Weekly bonus:** Yes — complete all daily quests 5/7 days → weekly reward chest (gold + consumable + chance at rare equipment). Strong weekly retention loop.
- **Server-driven:** Yes — quest definitions in `content_quests` table. Aligns with content pipeline philosophy.

### Status: ✅ Built, decisions made. Needs expansion for new systems.

---

## Duty Board & Mini-Games

### Duty Board — What's Built

Daily rotating board of 4 curated tasks. Seeded RNG based on date + player ID, so each player sees a unique board. 1 free daily refresh. Tasks are drawn from a pool of ~35 templates in `DutyBoardGenerator.swift`.

Duty types:
- Standard tasks (same as player tasks — Physical, Mental, Social, etc.)
- Mini-game duties (complete a Sudoku, Memory Match, etc.)
- Category-specific duties ("Meditate for 5 minutes", "Read for 15 minutes")

Completing a duty awards gold + EXP (comparable to a regular task). The duty board is a way to suggest tasks the player might not have thought of — it's discovery-driven.

### Mini-Games — What's Built

5 fully implemented games, each with time-based reward tiers:

| Game | Type | Reward Scaling | Awards |
|---|---|---|---|
| **Sudoku** | Logic puzzle | 3 tiers by completion time | Gold + Wisdom bonus |
| **Memory Match** | Card matching | 3 tiers by completion time | Gold + Wisdom bonus |
| **Math Blitz** | Mental math | 3 tiers by problems solved | Gold + Wisdom bonus |
| **Word Search** | Word puzzle | 3 tiers by completion time | Gold + Wisdom bonus |
| **2048** | Tile merge | Score-based tiers | Gold + Wisdom bonus |

All games award Wisdom stat bonus (mental tasks). They're accessed through the duty board.

### What Needs Discussion

**Duty Board:**
- Pool of 35 templates is fine for now but will get stale. Moving to `content_duties` table (already planned) solves this.
- Should duties award loot drops like regular tasks? (Currently: gold + EXP only)
- Should the board have more than 4 slots? Or vary by level?
- Paid refresh cost (currently not implemented — just 1 free refresh) — should additional refreshes cost gold?

**Mini-Games:**
- All 5 games only give Wisdom bonus — should different games give different stat bonuses?
  - Sudoku → Wisdom, Memory Match → Wisdom, Math Blitz → Wisdom, Word Search → Wisdom, 2048 → Wisdom
  - Proposal: Diversify. Memory Match → Luck (memory = pattern recognition), 2048 → Dexterity (spatial reasoning), Math Blitz → keep Wisdom
- Should mini-games have difficulty levels that unlock with player level?
- Should mini-games be playable outside the duty board? (Currently: duty-board-only)
- Should mini-games have leaderboards (personal best times)?
- Could mini-games be party challenges? ("Beat your ally's Sudoku time")

### Decisions Made

**Duty Board:**
- **Loot drops:** Yes — duties drop loot at same rates as regular tasks (5-8% equipment, 30-40% materials, 15-20% consumables)
- **Slot count:** Keep 4 + add a bonus duty that unlocks after completing all 4 (mirrors daily quest 3+1 structure)
- **Paid refresh:** Yes — 50 gold per additional refresh after 1 free daily. Small gold sink, optional.

**Mini-Games:**
- **Stat diversification confirmed:**

| Game | Old Stat | New Stat | Reasoning |
|---|---|---|---|
| Sudoku | Wisdom | **Wisdom** | Logic = Wisdom. Keep. |
| Math Blitz | Wisdom | **Wisdom** | Math = mental. Keep. |
| Memory Match | Wisdom | **Luck** | Pattern recognition, "finding" matches |
| Word Search | Wisdom | **Charisma** | Language/words = communication |
| 2048 | Wisdom | **Dexterity** | Spatial reasoning, quick decisions |

- **Free play:** Yes — mini-games playable anytime, but only duty board appearances give the stat bonus. Prevents stat farming while letting people play for fun.

### Status: ✅ Built, decisions made. Needs loot integration + stat diversification.

---

## Store & Shop Experience

### What's Built

The store has 4 tabs with a shopkeeper NPC:

**Storefront:**
- Daily deal (1 item, 25–40% discount, rotates daily)
- Daily equipment stock (4 items, seeded RNG rotation)
- Milestone gear (class-specific items unlocking at level milestones: Lv5, 10, 15, 20, 25, 30, 40, 50)
- Gear sets (3-piece sets with set bonuses)
- Bundles (equipment + consumable packages)

**Equipment tab:** Browse full equipment catalog by slot + rarity filter

**Consumables tab:** HP potions, EXP boosts, gold boosts, streak shields, stat foods, mission speed-ups

**Premium tab:** Gem-purchased items (revive tokens, loot rerolls)

**Shopkeeper NPC:** Dialogue system with contextual lines. Visual character with shop personality.

### What Needs Discussion

**Store evolution with new systems:**
- How does the store change when catalogs move to `content_*` tables? (Answer: `ShopGenerator` reads from `ContentManager` instead of static arrays. Daily rotation logic stays the same, just the item pool is server-driven.)
- Should the store sell monster cards? Or are they drop-only?
- Should the store sell Affix Scrolls? (Proposed: yes, expensive — gold sink)
- Should daily deal discount be a percentage or a flat gold reduction?
- Should the store have a "black market" that appears rarely with premium items?
- Premium tab: what exactly is purchasable with Gems? (Gems are currently earn-only from daily quests and achievements — no IAP yet)

**Shopkeeper NPC:**
- Does the shopkeeper's dialogue change based on what you buy? Player level? Party status?
- Should there be seasonal/event shopkeeper dialogue?
- How does the shopkeeper interact with the Forgekeeper? Are they in the same "town" concept?

**Store bundles:**
- Bundles move to `content_store_bundles` table with `active_from`/`active_until` dates
- Can be used for seasonal sales, event bundles, comeback deals

### Decisions Made

- **Affix Scrolls in store:** Yes — 800 gold. Endgame gold sink. Finding one as a drop saves you 800g — still exciting.
- **Monster cards:** Drop-only. Not purchasable. Buying cards kills the collection hunt.
- **Wandering Merchant:** Yes — rare event NPC (10% chance on daily reset). Different NPC from shopkeeper. 1-3 premium items, better deals, disappears next day. Server-driven via content pipeline.
- **Premium / IAP:** Gems stay earn-only at launch. Premium tab sells gem items. Revisit IAP post-launch based on engagement data.
- **Content pipeline:** Direct migration. Daily stock rotation logic stays client-side, item pool + pricing from `content_equipment`, `content_consumables`, `content_store_bundles`. Bundles get `active_from`/`active_until` for seasonal sales.

### Status: ✅ Built and functional, decisions made. Needs content pipeline migration + Wandering Merchant.

---

## Goals System

### What's Built

Long-term goals with milestone rewards:

- Player creates a goal (name, description, target count, category)
- Milestones at 25%, 50%, 75%, 100% completion
- Each milestone awards gold + EXP
- Tasks can be linked to a goal (completing linked tasks advances goal progress)
- Goals can be filtered by status: Active / Completed / Abandoned
- Goal data is **local-only** (SwiftData) — at risk of loss

### What Needs Discussion

**Current limitations:**
- Goals have no party visibility — allies can't see each other's goals or cheer progress
- No goal suggestions or templates (player must create from scratch)
- No recurring goals ("Exercise 20 times this month, every month")
- No visual progress display on home screen
- Goal milestones give flat rewards — no scaling by difficulty

**Proposed improvements:**
- **Shared goals**: Party can create a shared goal ("We all meditate 30 times this month"). Tracks each member's contribution. Party reward on completion.
- **Goal templates**: Server-driven suggestions via `content_goals` table (e.g., "30-Day Fitness Challenge", "Read 12 Books This Year"). Reduces friction of creating goals.
- **Goal streaks**: Consecutive months completing a recurring goal → escalating rewards
- **Home widget**: Show top active goal progress on HomeView dashboard
- **Goal → Achievement integration**: Completing certain goals should trigger achievements

**Data concern:** Goals MUST sync to Supabase (see Data Architecture section). A player losing their 6-month goal progress is devastating.

### Decisions Made

- **Shared party goals:** Yes — launch feature. Party creates a goal together, each member tracked individually, party reward when all members hit target (bonus gold + rare consumable). Strong accountability feature.
- **Goal templates:** Yes — server-driven via `content_goals` table. Reduces "blank page" friction. Players can use as-is or customize.
- **Recurring goals:** Future Expansion. Regular goals + templates are enough for launch. Recurring adds state machine complexity.
- **HomeView widget:** Yes — compact progress bar for top active goal on Home dashboard. "30-Day Fitness — 18/30 (60%)"
- **Goal achievements:** Yes — 3 achievements: "Goal Setter" (create first goal), "Goal Crusher" (complete 5 goals), "Party Goal" (complete a shared party goal)
- **Cloud sync:** Mandatory. Part of Phase -1. Goals are long-term — losing 6-month progress is devastating.

### Status: ✅ Built, decisions made. Needs party integration + cloud sync + templates.

---

## Wellness & Meditation System

### What's Built

**Mood Check-ins:**
- Daily mood entry (1–5 scale: Terrible → Great)
- Optional journal text entry with each mood
- 7-day mood history chart in `WellnessTabContent` (Character view tab)
- Mood streak tracking

**Meditation:**
- Full meditation timer with customizable duration
- Warm-up phase before timer starts
- Pause/resume support
- 8 bell options (none, vibrate, chime, glass, bloom, calypso, bell tower, zen)
- 5 ambient sound options (ocean waves, rain, forest, fire crackling, night sounds)
- Interval bells (configurable frequency)
- Meditation streak tracking with bonus EXP for streaks
- Meditation preferences stored in UserDefaults

**Integration:**
- Meditation completion awards EXP (scales with duration + level)
- Mood entries tracked in `MoodEntry` model (SwiftData)
- Wellness tab visible on Character view
- Meditation accessible from Adventures Hub

### What Needs Discussion

**Current limitations:**
- Mood entries are **local-only** — no cloud sync. Wellness history lost on reinstall.
- No party mood sharing — allies can't see if someone is having a rough day
- No mood trends analysis beyond 7-day chart (monthly trends? correlations with task completion?)
- Meditation is isolated — doesn't connect to any other game system beyond EXP
- No guided meditation content (just a timer)

**Proposed improvements:**
- **Sync mood entries to Supabase** (`player_mood_entries` table — see Data Architecture)
- **Party mood sharing (opt-in)**: If a member logs a 1–2 mood, party gets a gentle nudge ("Your ally might need encouragement"). Privacy-first — must be opt-in.
- **Mood → Task recommendations**: "You logged low energy today. Here are some light tasks." (Only if this doesn't feel patronizing.)
- **Meditation → Stat bonus**: Meditation could give a temporary Wisdom buff (+5% for 24hr) instead of or in addition to flat EXP. Ties it into the RPG layer.
- **Monthly mood report**: Show trends, correlations with task categories, streaks, and party activity
- **Wellness achievements**: "Meditate 7 days in a row", "Log mood for 30 consecutive days"

### Decisions Made

- **Prominence:** Core feature. Wellness IS a real-world task. Meditation and mood tracking are legitimate self-improvement habits. Making them first-class differentiates from pure habit trackers.
- **Meditation Wisdom buff:** Yes — meditation completion gives +5% Wisdom buff for 24 hours. Ties into RPG layer ("I meditated so my character is smarter"). Affects AFK outcomes via Power Score.
- **Party mood sharing:** Yes — **triple opt-in**: (1) enable in Settings, (2) confirm each time on low mood ("Share with party?"), (3) party sees a subtle icon on avatar, NOT a push notification and NOT the actual number. Privacy-first.
- **Monthly mood report:** Future Expansion. 7-day chart works for now. Monthly needs enough data history to be meaningful.
- **Cloud sync:** Mandatory. Part of Phase -1. Mood history is personal and valuable.
- **Wellness achievements:** Yes — 3 achievements: "Inner Peace" (meditate 7 days in a row), "Self-Aware" (log mood 30 consecutive days), "Zen Master" (meditate 30 days in a row)

### Status: ✅ Built and polished, decisions made. Needs cloud sync + Wisdom buff + party mood sharing.

---

## Raid Boss System

### What's Built

Weekly raid bosses appearing Monday–Sunday:

- **Tier system (1–5):** Tier scales based on average partner level
  - Tier 1: Level 1–10, HP 3,000
  - Tier 2: Level 11–20, HP 6,000
  - Tier 3: Level 21–35, HP 9,000
  - Tier 4: Level 36–50, HP 12,000
  - Tier 5: Level 51+, HP 15,000
- **Daily attack cap:** 5 attacks per day per player
- **Damage calculation:** Based on character stats (Power Score formula)
- **Attack log:** Visible history of all attacks this week
- **Defeat rewards:** Bond EXP (ties into partner system)
- **Auto-generation:** New boss spawns every Monday
- **Boss names:** Themed names generated per tier

### What Needs Discussion

**Current limitations:**
- Only works with partner (needs party update for 1–4 members)
- Damage is stat-based but doesn't factor equipment quality or class bonuses
- Only 1 boss per week with fixed HP — no variety
- Rewards are Bond EXP only — no loot, gold, or cards
- No visual boss representation (just text + HP bar)
- Boss tier caps at Tier 5 (Level 51+) — no scaling for endgame players

**Proposed improvements:**
- **Party update:** Scale for 1–4 members. HP = base × member count scaling (not linear — 2 players don't get 2x HP)
- **Equipment and class factor into damage:** Power Score formula already exists — use full calculation including gear, affixes, cards
- **Boss loot table:** Defeating the boss awards loot chest to all participants (gold + chance at rare equipment + chance at boss-exclusive monster card)
- **Boss variety:** Multiple boss templates per tier in `content_raids` table. Weekly rotation picks from pool.
- **Boss modifiers:** Weekly modifiers ("Fire Aura: -50% strength damage", "Arcane Shield: bonus wisdom damage") that make class composition matter
- **Extend tiers:** Add Tier 6–10 for endgame (or infinite scaling like arena)
- **Boss-exclusive monster cards:** Each boss drops a unique card (collection incentive)
- **Visual boss art:** Use dungeon theme art as placeholder; eventually unique boss art

### Decisions Made

- **Party scaling:** Sublinear. Solo = 1x HP, 2 members = 1.8x, 3 = 2.4x, 4 = 3.0x. Parties feel powerful together.
- **Boss loot:** Yes — all participants receive: Gold (200-500 by tier) + guaranteed consumable + 15-25% chance at rare+ equipment + **guaranteed boss-exclusive monster card** (1 unique card per boss template). No loot splitting.
- **Boss variety:** Yes — 6-8 boss templates in `content_raids` table. Weekly rotation from pool. Each boss has a name, theme, modifier (e.g., "Fire Aura: -30% STR damage", "Arcane Shield: +50% WIS damage"), and unique card. Modifiers make class composition matter.
- **Tier scaling:** Infinite. Tier = ceil(average party level / 10). HP = 3,000 × tier × party size factor. No cap. Endgame players face proportional challenge.
- **Power Score for damage:** Yes. Full Power Score formula (stats + equipment + affixes + card bonuses) used for boss damage calculation.

### Status: ✅ Built, decisions made. Needs party scaling + loot + boss templates + infinite tiers.

---

## Arena System

### What's Built

10-wave escalating combat accessible from Adventures Hub:

- **Wave structure:** Waves 1–10 with escalating difficulty. Boss waves at 5 and 10.
- **HP system:** Start at 100 HP, carries between waves
- **Approach selection:** Choose combat approach per wave (Aggressive, Defensive, Tactical, etc.)
- **Daily entry:** 1 free attempt per day, additional attempts cost 50 gold
- **Personal best tracking:** Records best wave reached + date
- **Wave results:** Each wave produces a result (damage dealt, damage taken, approach effectiveness)

### What Needs Discussion

**Current limitations:**
- Fixed at 10 waves — endgame players clear it trivially
- Same difficulty curve every run — no variety
- Rewards scale linearly (no exciting breakpoints)
- No leaderboard (personal best only, no party/global)
- No arena-exclusive drops
- Only 1 arena mode (standard combat waves)

**Proposed improvements:**
- **Extend to infinite waves:** Remove the 10-wave cap. Scale infinitely. Leaderboard tracks highest wave.
- **Milestone wave rewards:** Bonus loot at waves 5, 10, 15, 20, 25 (gold + consumables + chance at gear)
- **Arena-exclusive monster cards:** Rare card drops at milestone waves
- **Weekly modifiers:** Rotate modifiers that change the meta:
  - "Berserker" — double damage dealt and taken
  - "Endurance" — HP regen between waves
  - "Glass Cannon" — 50 starting HP, 2x damage
  - "Boss Rush" — every wave is a boss wave
  - "Time Trial" — faster timer, bonus rewards
- **Arena leaderboard:** Party leaderboard (competitive) and global leaderboard (aspirational)
- **Arena modes (future):**
  - Standard (current)
  - Survival (infinite waves, no healing)
  - Class Challenge (only class-appropriate approaches work)

### Decisions Made

- **Infinite waves:** Yes. Remove 10-wave cap. Difficulty scales ~8-10% per wave above 10. Everyone hits a wall based on Power Score.
- **Milestone rewards:** Yes — breakpoints at waves 5/10/15/20/25, then every 10:

| Wave | Reward |
|---|---|
| 5 | Gold + common consumable |
| 10 | Gold + uncommon consumable |
| 15 | Gold + rare consumable + arena card chance (10%) |
| 20 | Gold + guaranteed rare+ equipment |
| 25 | Gold + epic consumable + arena card chance (25%) |
| Every 10 after | Escalating gold + increasing card/gear chance |

- **Weekly modifiers:** Yes — 6 modifiers at launch, weekly server-driven rotation:
  - Berserker (2x damage dealt/taken), Endurance (heal 10 HP between waves), Glass Cannon (50 HP start, 2x damage), Boss Rush (every wave is boss), Time Trial (faster timer, +50% gold), Elemental Fury (one stat deals 2x — rotates STR/WIS/DEX, makes class matter)
- **Leaderboard:** Party leaderboard at launch (best wave this week). Global leaderboard deferred (needs anti-cheat).
- **Arena-exclusive cards:** Yes — 3-5 exclusive cards that only drop at milestone waves (15, 25, etc.). Among the cooler-looking cards.

### Status: ✅ Built, decisions made. Needs infinite scaling + milestones + modifiers + party leaderboard + cards.

---

## Class Evolution System

### What's Built

At level 20, players evolve their starter class into an advanced class:

| Starter | Evolution A | Evolution B |
|---|---|---|
| **Warrior** | Berserker (Strength focus) | Guardian (Defense focus) |
| **Mage** | Elementalist (Wisdom focus) | Enchanter (Charisma focus) |
| **Archer** | Sharpshooter (Dexterity focus) | Ranger (Luck focus) |

**Requirements:**
- Level 20
- Primary stat ≥ 15 (stat for chosen evolution)

**Visual:** `ClassEvolutionView` shows the two paths with stat requirements, evolution happens with a celebration.

### What Needs Discussion

**Current issues:**
- Evolution is a one-time event that feels big but has limited ongoing impact
- After evolution, class identity fades — it mainly affects AFK combat power scores and a few UI labels
- No "class fantasy" moments in gameplay (a Berserker should feel different from a Guardian)
- What happens with Rebirth? (Already decided: class resets, player can pick a new starter → new evolution)

**How evolution ties into new systems:**
- **Task Affinity:** Already designed — evolved classes inherit starter class affinity + stronger bonus (+20% vs +15%?)
- **Class-specific dungeon content:** Some dungeons could have class-gated bonus rooms ("Mage door" only Elementalist/Enchanter can enter)
- **Class-specific affixes:** Affixes with class requirements (e.g., "Berserker's Fury: +3 STR, Berserker-only")
- **Class fantasy in arena:** Different approaches available to different classes (Berserker gets "Rampage" approach, Guardian gets "Shield Wall")
- **Evolved class gear sets:** The 3 existing gear sets are per-starter-class. Could add evolved-class sets as endgame.

### Decisions Made

- **Class fantasy mechanics:** All four confirmed:
  1. **Class-specific arena approaches** — Berserker gets "Rampage", Guardian gets "Shield Wall", etc. Exclusive to that class.
  2. **Class-gated dungeon bonus rooms** — "Mage Door", "Warrior Gate" in some dungeons. Only that class can enter for bonus loot. Creates Rebirth replay incentive.
  3. **Evolved class task affinity** — Evolved classes get +20% EXP for affinity category (up from +15% for starter classes). Small bump rewarding evolution.
  4. **Class-specific affixes** — "Berserker's Fury: +3 STR" — only equippable by Berserkers. Rare drops that feel special.
- **Second evolution tier:** No, not at launch. Rebirth provides class variety (reset + new class + new evolution). Second tier is Future Expansion if players want more class depth.
- **Party composition bonus:** No hard bonus for balanced parties. Raid boss modifiers and class-gated rooms create soft incentives. Hard bonus punishes same-class parties.

### Status: ✅ Built, decisions made. Needs class fantasy integration with new systems.

---

## Verification & Anti-Cheat

### What's Built

Multi-layer verification system in `VerificationEngine.swift`:

**Verification methods:**
- **Minimum duration:** Each task type has a minimum time requirement before completion is allowed
- **Photo proof:** Take a photo to verify task completion. Timestamp validation ensures photo was taken during task.
- **Location check-in:** Geofence verification — player must be at specified location (gym, office, etc.)
- **HealthKit cross-reference:** For physical tasks, checks if a workout/step activity was recorded in the verification window (2-hour lookback)
- **Partner confirmation:** Partner can confirm/dispute task completion

**Anti-cheat detection:**
- **Rapid completion:** Flags tasks completed suspiciously fast
- **Late-night anomaly:** Flags completion between 2am–5am (configurable)
- **Excessive daily count:** Flags if player completes more than X tasks in a day
- **Combined verification multiplier:** Higher verification = higher EXP multiplier. More proof methods used = more reward.

### What Needs Discussion

**Current limitations:**
- Verification is per-task, opt-in at creation — many tasks have no verification
- No ongoing monitoring (verification happens once at completion)
- Photo storage is local — no cloud backup of proof photos
- Geofence requires location permissions (friction)
- No verification for AFK game content (dungeons, missions, arena are just timer-based)

**Proposed improvements:**
- **Verification tiers (already designed in IRL Task Experience section):**
  - Quick (tap complete)
  - Standard (minimum duration enforced)
  - Verified (photo or location)
  - Party-verified (ally confirms)
- **Tier → Reward multiplier:** Higher verification tier = more EXP, gold, and loot chance. This incentivizes proof without requiring it.
- **Party-verified as an option:** Any party member can confirm a task, not just your "partner"
- **Photo sync to Supabase Storage:** Enables party members to see proof + enables photo timeline feature
- **Anomaly → warning, not punishment:** Flag anomalies in player data but don't auto-penalize. Let the system learn patterns first.
- **Motion detection for physical tasks:** Already exists conceptually via HealthKit. Could expand to CoreMotion for walking/running detection.

### Decisions Made

- **Verification reward tiers:** Yes — incentivize proof through rewards, not punishment:

| Tier | What It Means | EXP Multiplier | Loot Chance Bonus |
|---|---|---|---|
| Quick | Tap complete, no proof | 1.0x (base) | 0% |
| Standard | Minimum duration met | 1.15x | +2% |
| Verified | Photo OR location proof | 1.3x | +5% |
| Party-verified | Ally confirms completion | 1.5x | +8% |

  Tiers stack: duration + photo + party confirmation = 1.5x EXP and +8% loot chance.

- **Party-verified:** Any party member can confirm (not just partner). Simple expansion.
- **Photo sync:** Future Expansion. Storage costs add up. Feature works fine without cloud photos. Revisit when revenue covers storage.
- **Anomaly handling:** Warning label approach. Subtle "unverified" tag on flagged completions. No EXP reduction — the verification tier reward gap IS the incentive. No punishment needed.
- **Philosophy:** Verification is *rewarding*, not *punishing*. Quick-complete always works. More proof = more rewards.

### Status: ✅ Built and comprehensive, decisions made. Needs reward tier system + party-verified expansion.

---

## Task Analytics Dashboard

### What's Built

Full analytics dashboard in `TaskAnalyticsView.swift`:

- **All-time completion rate:** Tasks completed / tasks created (percentage)
- **Weekly completion rate:** Same but filtered to current week
- **Category breakdown:** Pie/bar chart showing task distribution by category (Physical, Mental, Social, etc.)
- **Weekly trend:** Bar chart showing last 4 weeks of task completions (trend up/down)
- **Streak calendar:** 28-day visualization of daily completion status
- **Stat gains tracking:** Total stat points gained from task completion
- **Time-of-day analysis:** When the player is most productive (morning/afternoon/evening/night)

### What Needs Discussion

**Current limitations:**
- Analytics is a passive view — no actionable insights
- No comparisons (to self over time, to party members, to averages)
- No export functionality
- Local-only data means analytics can only show what's in SwiftData
- No goal integration (how do tasks relate to goal progress?)

**Proposed improvements:**
- **Insights engine:** Generate weekly insights: "You complete 40% more tasks on Tuesday than Friday", "Your Physical tasks have a 92% completion rate — your highest category"
- **Party comparison (opt-in):** Side-by-side stats with party members (completion rate, category strengths). Competitive but friendly.
- **Goal correlation:** Show which tasks contributed to which goals
- **Personal records display:** Most tasks in a day, longest streak, most consistent category
- **Weekly summary notification:** Push notification with a weekly recap and stat highlight

### Decisions Made

- **Insights engine:** Yes — generate actionable text insights at top of analytics view: "You complete 40% more tasks on Tuesdays", "Physical is your strongest category at 92%", "Most productive between 7-9am". Simple string templates.
- **Party comparison:** Yes, opt-in. Strengths-focused framing: "Alex leads in Physical. You lead in Mental." Not shaming.
- **Weekly summary push:** Yes — one Sunday evening notification: "This week: 18 tasks, 3-day streak, +12 Wisdom. Best category: Mental (95%)." Pat on the back, not a nag.
- **Priority:** Low. Existing dashboard is already good. Insights + comparison go in Phase 0 Agent 2.5 but are last items.

### Status: ✅ Built, decisions made. Low priority enhancement.

---

## NPC & Dialogue System

### What's Built

Two NPC characters with dialogue systems:

**Shopkeeper:**
- `ShopkeeperView.swift` + `ShopkeeperDialogue.swift`
- Visual character display with dialogue bubble
- Contextual lines based on store state (new items, deals, etc.)
- Part of the Store experience

**Forgekeeper:**
- `ForgekeeperView.swift` + `ForgekeeperDialogue.swift`
- Visual character display with dialogue bubble
- Contextual lines based on forge state
- Part of the Forge experience

Both use custom image assets (`shopkeeper`, `forgekeeper` in `Avatars.xcassets`).

### What Needs Discussion

**Current questions:**
- Should NPCs exist in a shared "town" concept, or remain isolated per feature?
- Should there be more NPCs? Candidates:
  - Quest Giver (Adventures Hub — introduces dungeons, expeditions)
  - Card Collector (Bestiary — shows card progress, hints at rare cards)
  - Class Trainer (Class Evolution — guides evolution choice)
- Should NPC dialogue be server-driven? (Enables seasonal dialogue, event NPCs)
- Should NPCs offer daily tips or subtle tutorials? ("I heard the forge can add special properties to your gear now…")
- Should NPCs have a relationship/reputation system? (Buy enough from shopkeeper → unlocks special deals)

**Integration with content pipeline:**
- Dialogue lines could live in `content_narratives` table (already exists in migration 005)
- Seasonal/event dialogue can be toggled via server
- New NPCs can be added without app update if dialogue is server-driven

### Decisions Made

- **New NPCs:** Yes — 2 new NPCs confirmed:
  - **Quest Giver** — Adventures Hub. Introduces dungeons, expeditions. Flavor dialogue.
  - **Card Collector** — Bestiary. Comments on card progress, hints at rare cards.
- **Server-driven dialogue:** Yes — all NPC dialogue lines move to `content_narratives` table. Enables seasonal dialogue, event dialogue, new lines without app update.
- **NPC reputation:** Future Expansion. Cool but adds per-NPC state tracking + cloud sync. Not worth launch complexity.

### Status: ✅ Built (2 NPCs), decisions made. Add 2 new NPCs + server-driven dialogue.

---

## Audio & Sound Design

### What's Built

Full audio system in `AudioManager.swift`:

**Sound effects:**
- Button taps and tab switches
- Dungeon/training/arena sounds
- Reward sounds (gold, loot, level-up)
- Achievement unlock sound
- Task completion sound

**Meditation audio:**
- 8 bell options (none, vibrate, chime, glass, bloom, calypso, bell tower, zen)
- 5 ambient sounds (ocean waves, rain, forest, fire crackling, night sounds)
- Interval bells at configurable frequency
- Fade in/out transitions

**Controls:**
- Global mute toggle
- Volume control
- Respects iOS silent switch
- Fallback to system sounds if custom files are missing

### What Needs Discussion

**Current state:** Audio is solid for MVP. Most sounds use system audio (AudioServicesPlaySystemSound) with named sound IDs.

**Potential improvements:**
- **Music:** No background music exists. Should there be ambient background music? (Risky — most people listen to their own music/podcasts while doing tasks)
- **Sound packs:** Different audio themes purchasable with gems? (Fantasy pack, sci-fi pack, lo-fi pack)
- **Haptics integration:** Currently separate from audio. Should be unified — every sound effect paired with appropriate haptic.
- **Dungeon ambient audio:** Different ambient sounds per dungeon theme (cave echoes, forest sounds, etc.)
- **Audio for new systems:** Forge sounds (hammer, fire), expedition sounds (travel, discovery), card collection sound

### Decisions Made

- **New system sounds:** Yes — every major action gets audio feedback:
  - Forge: hammer strike, anvil ring (success), shatter (fail), material crumble (salvage), magic swirl (affix)
  - Cards: card reveal, collection chime (milestone), page turn (bestiary)
  - Expeditions: departure horn, stage complete, treasure chest
  - Arena: wave start horn, wave clear, milestone fanfare, defeat tone
  - Raid boss: heavy impact (attack), roar (phase change), victory (defeat)
- **Background music:** No at launch. App used in short 1-3 min sessions — music would be muted 90% of the time. Sound effects are more impactful. Revisit post-launch if requested.
- **Haptics pairing:** Yes — every sound effect paired with matching haptic (light tap for UI, medium impact for rewards, heavy for level-ups, success/error for forge). Part of Agent 1's work, extended to all systems.
- **SFX manifest:** Will be compiled after all systems are finalized to get a complete list of what's needed.

### Status: ✅ Built, decisions made. New system sounds + haptics needed.

---

## Leaderboard (Party Update)

### What's Built

`CouplesLeaderboardView.swift` — friendly competition between two partners:

- Period filters: Today / This Week / All Time
- Score comparison: tasks completed, total EXP earned
- Category breakdown comparison
- Fun titles based on relative performance ("Task Machine", "EXP Hunter", etc.)
- Visual bars showing relative progress

### What Needs Discussion

**Required changes for party update:**
- Rename from "Couples Leaderboard" to "Party Leaderboard"
- Support 1–4 members (currently hardcoded for 2)
- Ranking: show all members ranked by score (not just a comparison bar)
- Should there be a global leaderboard? (Privacy considerations)

**Expansion ideas:**
- **Weekly competitions:** Themed weekly challenges ("Most Physical tasks this week", "Highest arena wave")
- **Party vs Party:** Anonymous matchmaking against another party of similar size/level (future)
- **Category champions:** Crown the party member who's best at each category
- **All-time records:** Party records (most tasks in a day as a group, longest party streak, fastest raid boss clear)

### Decisions Made

- **Rename + scale:** Yes — "Couples Leaderboard" → "Party Leaderboard". Ranked list of 1-4 members.
- **Fun titles:** Yes, expanded. Each member gets a title based on their strongest area: "Task Machine" (highest count), "EXP Hunter" (highest EXP), "Streak Lord" (best streak), "Gym Warrior" (most Physical), "Scholar" (most Mental), "Jack of All Trades" (most categories).
- **Weekly competitions:** Future Expansion. Base leaderboard with fun titles and period filters is enough for launch.
- **Solo fallback:** Yes — if party size = 1, show personal records board (best week, best day, longest streak, best arena wave) instead of empty leaderboard.
- **Placement:** Option C — compact summary card on HomeView ("This Week's Leader: Alex — 42 tasks") + full leaderboard in Party tab. Solo players see personal best on Home card instead.

### Status: ✅ Built, decisions made. Needs rename + party scaling + Home card + solo fallback.

---

## Weather Integration

### What's Built

`WeatherService.swift`:
- WeatherKit integration for current weather
- Returns temperature + condition (sunny, cloudy, rain, etc.)
- 30-minute cache TTL
- Location-based (requires location permission)

Currently used minimally — weather data is available but not prominently displayed.

### What Needs Discussion

**Current usage:** Unclear where weather is displayed in the UI. May be part of HomeView or a minor detail.

**Potential uses:**
- **Weather-based task suggestions:** "It's sunny — great day for an outdoor task!" or "Rainy day — perfect for indoor tasks"
- **Weather bonus:** Completing an outdoor task in bad weather → bonus EXP ("Dedication Bonus")
- **Visual theming:** Home screen changes ambient visuals based on weather (subtle, decorative)
- **AFK mission flavor:** Mission narratives reference actual weather ("You set out in the rain…")

### Decisions Made

- **Keep it:** Yes — location permission already needed for geofence, so no added friction.
- **Launch scope — minimal:**
  1. **Weather display on HomeView** — small icon + temp in header. Decorative. Makes app feel alive.
  2. **Weather-based task suggestions** — one line: "Perfect day for an outdoor workout" or "Rainy day — great for indoor tasks." Helps players decide what to tackle. Just flavor.
- **Dedication Bonus (bad weather EXP):** Future Expansion. Needs weather-to-task-type matching logic.
- **Permission denied:** Gracefully hide. No weather card, no suggestions. App works perfectly without it. Purely additive.

### Status: ✅ Built, decisions made. Low priority polish — weather display + task suggestions.

---

## Settings Screen

### What Doesn't Exist

There is **no centralized Settings screen**. Preferences are scattered:

| Setting | Where It Lives | How It's Changed |
|---|---|---|
| Audio mute/volume | `AudioManager` | Meditation settings only |
| Meditation bells | UserDefaults | Meditation view picker |
| Meditation ambient sound | UserDefaults | Meditation view picker |
| Meditation duration | UserDefaults | Meditation view picker |
| Duty board refresh tracking | UserDefaults | Automatic |
| Notification preferences | System Settings | Not in-app |

### What Needs to Be Built

A centralized `SettingsView` accessible from Character tab (gear icon):

**Sections:**
- **Account:** Email, sign-out, delete account, data export
- **Audio:** Mute toggle, volume slider, sound effects on/off
- **Notifications:** Push notification preferences, quiet hours
- **Meditation:** Default duration, bell choice, ambient sound
- **Gameplay:** Auto-salvage rules, task completion confirmation toggle, analytics opt-in
- **Privacy:** Location services, HealthKit access, mood sharing toggle (for party)
- **About:** Version, credits, feedback link, support

**Data export:** Critical for GDPR/privacy. Player should be able to export all their data (tasks, achievements, goals, mood entries, analytics).

**Account deletion:** Required by App Store. Must delete Supabase data + clear local SwiftData.

### Decisions Made

- **Placement:** Gear icon in Character tab (top-right corner)
- **Account deletion:** Immediate deletion with "type DELETE to confirm" safeguard. No grace period.
- **Data export:** JSON dump of all player data (tasks, achievements, goals, mood entries, analytics)
- **All sections confirmed:** Account, Audio, Notifications, Meditation, Gameplay, Privacy, About

### Status: ❌ Not built. Required before launch (App Store requires account deletion). Assigned to Agent 0 (Phase -1).

---

## Launch Scope vs Future Expansion

> This is a productivity app with RPG flavor, not a full RPG. Launch with the minimum that creates the "what did I get?" feeling. Deepen in updates based on what players engage with.

| System | Launch Scope | Future Expansion |
|---|---|---|
| **Equipment slots** | 4 (Weapon, Armor, Accessory, Trinket) | Expand to 6 (Head, Hands) |
| **Affixes** | Prefix + Suffix on Uncommon+ gear | Greater Affixes on Legendary (1.5x power) |
| **Gem sockets** | Not at launch | Add if affixes alone aren't enough depth |
| **Gear sets** | 3 sets, 2-piece bonus | Add advanced class sets, 4pc bonus tier |
| **Consumables** | 10 types (8 existing + Material Magnet + Affix Scroll) | Expedition-specific consumables |
| **Monster cards** | ~50 cards across existing content | Expand to 100+ with new dungeons/expeditions |
| **Party system** | 1–4 members, shared bond, party streak, co-op content | Group challenges, party base building |
| **Expeditions** | 3–6 stage long AFK runs with narrative | Expand expedition pool, party expeditions |
| **Enhancement** | Scaling cost + failure chance at +4 and above | Gem sockets, transmog/cosmetic |
| **Pity system** | Per-content-type counters with hard guarantee | Soft pity (increasing chance before hard cap) |
| **Passive progression** | Not at launch (Phase 4) | Research tree with 3 branches |
| **Task loot** | Material drops (30–40%), consumable drops (15–20%), equipment (5–8%) | Category-specific loot tables |
| **Party challenges** | Not at launch | Weekly shared objectives |
| **Forge** | 4 stations (Craft, Enhance, Salvage, Affix). Kill Forge Shards. | Consumable crafting from Herbs, seasonal recipes |
| **Content pipeline** | All content in Supabase `content_*` tables with local caching | A/B testing, admin dashboard for content creation |
| **Class depth** | Task affinity (+15% EXP), class flavored messages, affix preference | Category-specific class abilities |
| **Onboarding** | Guided first task + quick tour + starter gift + breadcrumbs | Apple Watch onboarding, advanced tutorial |
| **Retention** | Daily login reward (7-day cycle), comeback gift, re-engagement push | Seasonal events, battle pass |
| **End-game** | Paragon levels beyond 100 (simple) | Full Rebirth/prestige system |
| **Achievements** | 40 achievements (16 existing + 24 new for all systems) | Server-driven achievements via content pipeline |
| **Data architecture** | Hybrid sync — progression data to Supabase, SwiftData as cache | Full cloud-first with real-time sync |
| **Dungeons** | 15–20 dungeons covering Lv1–100 (fill all gaps) | Room shuffle system, seasonal dungeons |
| **AFK missions** | 15–20 templates across all 5 rarities | Legendary 24hr missions, party missions |
| **Arena** | Infinite waves, milestone rewards, weekly modifiers | Arena modes (Survival, Class Challenge), global leaderboard |
| **Raid boss** | Party scaling (1–4), boss loot table, boss cards | Boss modifiers, visual boss art, Tier 6–10 |
| **Daily quests** | Expand quest pool with forge/arena/mood/party types | Weekly bonus quest chain |
| **Duty board** | Move to content pipeline, add loot drops to duties | Difficulty scaling, more mini-game variety |
| **Goals** | Cloud sync, shared party goals, goal templates | Recurring goals, home widget |
| **Store** | Content pipeline migration, affix scroll sales | Black market, seasonal events, premium IAP |
| **Wellness** | Cloud sync mood entries, meditation stat buff | Party mood sharing, monthly report, guided content |
| **Settings** | Full settings screen (account, audio, privacy, gameplay) | Data export, advanced preferences |
| **Leaderboard** | Party update (2 → 4 members), rename | Weekly competitions, party vs party |
| **Class evolution** | Deeper integration with task affinity + affixes | Second evolution tier, class-gated content |
| **Verification** | Verification reward tiers, party-verified option | Photo sync to Supabase Storage |
| **Analytics** | Insights engine, party comparison | Weekly summary push, goal correlation |
| **NPCs** | Server-driven dialogue via content pipeline | More NPCs (quest giver, card collector), reputation |
| **Audio** | Sound effects for all new systems | Background music, sound packs, dungeon ambient |
| **Weather** | Weather-based task suggestions | Weather bonus EXP, visual theming |

### The Decision Filter

Before adding anything, ask: **"Does this make the player want to complete one more real-world task today?"** If yes, build it. If it's just RPG depth for its own sake, it goes in Future Expansion.

---

## Phased Roadmap

### Phase -1: Data Architecture (MUST DO FIRST)
> **Goal**: Establish cloud sync infrastructure so every subsequent phase writes to both local and cloud from day one.
> **Scope**: Medium. Touches SupabaseService, PlayerCharacter, GameEngine, and every service that writes data.

- [ ] Run migration `006_player_sync_tables.sql` — create `player_achievements`, `player_tasks`, `player_goals`, `player_daily_state`, `player_mood_entries`, `player_arena_runs`, `player_dungeon_runs`, `player_mission_history` tables
- [ ] Expand `profiles.character_data` JSONB to include ALL fields (daily counters, dates, attempt trackers)
- [ ] Create `SyncManager` service — queue local writes for async cloud push, retry on failure
- [ ] Add conflict resolution: timestamp comparison on sync, most recent wins
- [ ] Update `SupabaseService.syncCharacterData()` to push comprehensive snapshot
- [ ] Add app-launch sync: pull from Supabase, merge with local SwiftData
- [ ] Migrate Bond data to Supabase `parties` table (already created in 005)
- [ ] Add achievement sync: write to `player_achievements` on unlock
- [ ] Add task sync: write all tasks (self + partner) to `player_tasks`
- [ ] Add goal sync: write to `player_goals` on create/update/milestone
- [ ] Add mood sync: write to `player_mood_entries` on mood check-in
- [ ] Build `SettingsView.swift` — account, audio, privacy, gameplay, about sections
- [ ] Add account deletion flow (required by App Store)
- [ ] Add data export functionality (required for GDPR-readiness)
- [ ] Test: reinstall app, verify all data recovers from cloud

### Phase 0: IRL Task Experience Polish
> **Goal**: Make the core loop (completing real tasks) feel amazing. This is foundational — everything else is built on top of this feeling good.
> **Scope**: Medium. Touches GameTask, GameEngine, TaskDetailView, TasksView, HomeView.

- [ ] Improve task completion moment: haptic feedback + sound effect + card animation on every completion
- [ ] Add loot roll chance to task completion (5–8% equipment, 30–40% materials)
- [ ] Implement swipe-to-complete on habit cards (no navigation required)
- [ ] Add Routine Bundle model (group 3–6 habits into a named routine)
- [ ] Build routine completion bonus system (+50% EXP when all habits in routine are done)
- [ ] Remove gold/EXP penalties for missed habits — replace with opportunity cost messaging
- [ ] Add streak freeze consumable item
- [ ] Add category mastery tracking (completion count + mastery level per category)
- [ ] Add personal records tracking (most tasks/day, longest streak per category)
- [ ] Add weekly progress summary card on HomeView
- [ ] Add party activity feed entries for task completions
- [ ] HealthKit auto-verify for physical tasks (passive step/workout detection)

**Onboarding:**
- [ ] Create `OnboardingView.swift` — guided first task flow (post-character creation)
- [ ] Add `hasCompletedOnboarding` flag to `PlayerCharacter`
- [ ] Implement first task creation with category suggestions
- [ ] Build reward animation demo on first task completion
- [ ] Add quick tour tooltips (Character, Adventures, Party tabs)
- [ ] Grant starter equipment set on completion
- [ ] Add optional habit setup step with category suggestions
- [ ] Implement breadcrumb quest log on HomeView (first 7 days)

**Retention:**
- [ ] Add daily login reward system (7-day cycle, claim on first open)
- [ ] Add `WelcomeBackView.swift` — comeback gift for 3+ day absence
- [ ] Scale comeback gifts by absence duration (3d/7d/14d/30d tiers)
- [ ] Add streak recovery offer (free Streak Armor on comeback)
- [ ] Schedule re-engagement push notifications on app background (2d/5d/14d)
- [ ] Cap push notifications at 2 per day
- [ ] Remove daily reset notification (noise)
- [ ] Add evening batch summary notification for party activity

**Class Task Affinity:**
- [ ] Add class task category bonus (+15% EXP for affinity category) to `GameEngine.completeTask()`
- [ ] Add class-flavored completion messages
- [ ] Add class affix preference (+10% weight for class-matching affixes) to `LootGenerator`

**Achievements (expand to 40):**
- [ ] Add 24 new achievement definitions (cards, forge, party, expeditions, loot, IRL, rebirth)
- [ ] Add new tracking keys to `AchievementTracker`
- [ ] Migrate achievement definitions to `content_achievements` Supabase table

**Existing Systems Polish (Phase 0):**
- [ ] Daily quests: expand quest pool with forge/arena/mood/party/duty quest types
- [ ] Duty board: add loot drops to duty completion (same rates as tasks)
- [ ] Goals: add goal progress widget to HomeView dashboard
- [ ] Goals: add shared party goal creation
- [ ] Store: update to read from ContentManager
- [ ] Wellness: meditation gives temporary Wisdom buff (+5% for 24hr)
- [ ] Wellness: add wellness achievements (meditation streak, mood streak)
- [ ] Leaderboard: rename "Couples" → "Party", support 1–4 members
- [ ] Verification: add verification tier → reward multiplier system
- [ ] Audio: ensure sound effects exist for all key actions in new systems
- [ ] NPC dialogue: move to `content_narratives` table (server-driven)
- [ ] Mini-games: diversify stat bonuses (Memory → Luck, 2048 → Dexterity)

### Phase 1: Fix the Loot Foundation
> **Goal**: Make every drop interesting, every source distinct, every piece of gear worth evaluating.
> **Scope**: Large. Touches Equipment model, LootGenerator, GameEngine, InventoryView, Consumable, ForgeView, StoreView.

**Loot Core:**
- [ ] Add pity counters to `PlayerCharacter` (per content type: tasks, dungeons, missions)
- [ ] Implement bad luck protection in `LootGenerator`
- [ ] Add `EquipmentAffix` model and affix pool (prefixes + suffixes)
- [ ] Update `Equipment` with optional prefix/suffix affixes + socket slots
- [ ] Update `LootGenerator` to roll affixes and sockets based on rarity
- [ ] Update equipment detail UI to show affixes and sockets

**Task Loot Integration:**
- [ ] Add equipment drop chance (5-8%) to task completion in `GameEngine`
- [ ] Add crafting material drops (30-40%) to task completion
- [ ] Add common consumable drops (15-20%) to task completion
- [ ] Create task-specific loot roll animation/feedback

**Equipment Expansion:**
- [ ] Expand `EquipmentSlot` from 3 → 4 (Weapon, Armor, Accessory, Trinket)
- [ ] Update `EquipmentCatalog` — cloaks, belts, charms, bracelets map to Trinket slot
- [ ] Update `PlayerCharacter` equipment loadout for 4 slots
- [ ] Update InventoryView and CharacterView for 4-slot display

**Consumables:**
- [ ] Add Common-tier consumables (Minor EXP Boost, Minor Gold Boost, Material Magnet, etc.)
- [ ] Add new consumable types (Material Magnet, Luck Elixir, Party Beacon, Affix Scroll, Forge Catalyst)
- [ ] Add consumable drops to task completion loot table
- [ ] Rebalance consumable store prices

**Forge Unification:**
- [ ] Merge two ForgeViews into single unified Forge with 4 stations (Craft, Enhance, Salvage, Affix)
- [ ] Remove Forge Shards currency — salvage returns materials directly
- [ ] Revise enhancement system: server-driven rules from `content_enhancement_rules` (failure chance at +4, critical enhancement)
- [ ] Add Affix Station: apply Affix Scrolls, re-roll affixes with escalating gold cost
- [ ] Add auto-salvage toggle setting (with "never auto-salvage affixed items" safety)
- [ ] Add consumable crafting from Herbs (AFK mission drops → forge consumables)
- [ ] Balance gold faucets vs. new sinks

**Content Pipeline:**
- [ ] Run migration `005_content_tables.sql` on Supabase
- [ ] Write seed script to copy existing catalog data into `content_*` tables
- [ ] Create `ContentManager` service (version check, fetch, local cache, typed access)
- [ ] Update `LootGenerator` to read from `ContentManager` instead of static arrays
- [ ] Update `DungeonEngine` to load dungeons from `ContentManager`
- [ ] Update `GameEngine` to load missions, drop rates from `ContentManager`
- [ ] Update `ForgeView` to load recipes from `ContentManager`
- [ ] Update `StoreView` / `ShopGenerator` to load from `ContentManager`
- [ ] Update `DutyBoardGenerator` to load duties from `ContentManager`
- [ ] Bundle fallback JSON snapshot for first-run-offline
- [ ] Remove static Swift catalog files once server-driven content is verified

**Gear Sets:**
- [ ] Update 3 existing gear sets to 2-piece activation (any 2 of 3 pieces)
- [ ] Upgrade set pieces from Rare → Epic rarity
- [ ] Add set piece drops to party dungeon and expedition loot tables

**Monster Cards:**
- [ ] Create `MonsterCard` model (cardID, name, theme, rarity, bonusType, bonusValue, source)
- [ ] Create `BestiaryView` (card grid, collected vs undiscovered, total bonuses, milestones)
- [ ] Define ~50 cards across existing dungeon themes, arena, and raid boss
- [ ] Add card drop rolls to `DungeonEngine.resolveRoom()`, arena handler, raid boss completion
- [ ] Implement collection milestone rewards (10/25/50 cards)
- [ ] Add card discoveries to party feed

**Dungeon / Arena / Training Content Expansion (Phase 1):**
- [ ] Author 8+ new dungeon templates to fill Lv15–100 gaps (seed into `content_dungeons` table)
- [ ] Add room pool system: 8–10 rooms per dungeon, 5–7 selected per run (shuffle on re-run)
- [ ] Add bonus rooms (rare spawn, better loot) to dungeon room pools
- [ ] Author 10+ new AFK mission templates: fill Rare + Legendary tiers (seed into `content_missions`)
- [ ] Extend arena beyond 10 waves (infinite scaling)
- [ ] Add arena milestone wave rewards at waves 5/10/15/20/25
- [ ] Add weekly arena modifier system (server-driven rotation via `content_arena_modifiers` or similar)
- [ ] Add arena-exclusive monster card drops at milestone waves
- [ ] Update raid boss to support party scaling (1–4 members)
- [ ] Add raid boss loot table (gold + rare equipment + boss-exclusive card)
- [ ] Add raid boss templates to `content_raids` table (weekly rotation from pool)

### Phase 2: Party System (Couples → 1–4 Members)
> **Goal**: Expand from couples-only to 1–4 person parties. Doubles addressable market.
> **Scope**: Medium-Large. Model changes, UI renaming, new party features.

**Renaming (low effort, high impact):**
- [ ] Rename Bond → PartyBond (model + all references)
- [ ] Rename "Partner" → "Ally" / "Party Member" in all UI text
- [ ] Update Bond titles (remove romantic language — see rename table in §3)
- [ ] Update item names/descriptions (remove romantic references)
- [ ] Rename "Couples Leaderboard" → "Party Leaderboard"
- [ ] Rename `BondPerk.couplesAchievements` → `.partyAchievements`

**Party model (core):**
- [ ] Extend Bond model: `partnerID: UUID` → `memberIDs: [UUID]` (max 4)
- [ ] Update Supabase schema: `parties` table + `party_members` junction table
- [ ] Update pairing flow to support inviting multiple members via QR or invite link
- [ ] Add party member list view (avatars, levels, stats, activity status)
- [ ] Implement party power scaling with diminishing returns (1.0x → 1.5x → 1.85x → 2.1x)

**Party streak:**
- [ ] Implement party streak counter (all members must complete 1+ task per day)
- [ ] Party streak bonus tiers: 3-day (+10% EXP), 7-day (+15% EXP, +10% Gold), 14-day, 30-day
- [ ] Party streak break: resets for all members if anyone misses
- [ ] Streak Armor consumable covers party streak for 1 day

**Party feed:**
- [ ] New Realtime subscription channel per party
- [ ] Feed entries: task completions, dungeon drops, card discoveries, level-ups, achievements
- [ ] Display in Party tab and as ambient bar on Home screen

**Party content:**
- [ ] Update co-op dungeon to support 2–4 players with party power scaling
- [ ] Update raid boss damage for party size scaling
- [ ] Add party-only dungeon tier (requires 2+ members, bond level 5+)
- [ ] Shared Bestiary view (see which cards any member has found)

### Phase 3: Expeditions
> **Goal**: Add long-duration AFK content with narrative and exclusive loot.
> **Scope**: Medium. New models, new view, extensions to existing systems.

- [ ] Create `Expedition` model and `ExpeditionStage` model
- [ ] Create `ActiveExpedition` model with persistence
- [ ] Create expedition template pool (rotating selection)
- [ ] Create expedition-exclusive loot table
- [ ] Add Expedition Key item (drops from Hard+ dungeons)
- [ ] Build `ExpeditionView` (launch, progress, stage results, claim rewards)
- [ ] Add expedition section to `AdventuresHubView`
- [ ] Implement stage completion + reward resolution in `GameEngine`
- [ ] Add push notifications at each stage completion
- [ ] Add party expedition support (combined stats, shared narrative)
- [ ] Add expedition entries to collection log

### Phase 4: Passive Progression
> **Goal**: Give players permanent upgrades to work toward. "Always something cooking."
> **Scope**: Medium. New model, new view, integration with existing economy.

- [ ] Design research tree nodes (Combat, Efficiency, Fortune branches)
- [ ] Create `ResearchNode` model
- [ ] Create Research Token item (mission-exclusive drop)
- [ ] Build `ResearchView` (tree visualization, node detail, progress)
- [ ] Add research timer system (like mission timer)
- [ ] Apply research bonuses to GameEngine calculations
- [ ] Add research section to character view or adventures hub

### Phase 5: End-Game & Prestige
> **Goal**: Give max-level players a reason to keep playing.
> **Scope**: Small-Medium. New model, new view, integration with leveling system.

- [ ] Implement Paragon Levels beyond 100 (+1 random stat + small reward per level)
- [ ] Design Rebirth system (reset level, keep gear/cards/achievements, gain permanent bonus)
- [ ] Create `RebirthView.swift` — confirmation showing keep/lose/gain
- [ ] Add rebirth star visual marker on avatar frame
- [ ] Add rebirth count to party profile visibility
- [ ] Add Rebirth achievements (2)

### Future Phases (Not Yet Planned in Detail)

- **iOS Widget**: Quick-complete habits from home screen (ties to Phase 0 friction reduction)
- **Apple Watch**: Tap to complete habits on wrist + HealthKit integration
- **Expanded equipment slots** (3 → 6): Helm, Boots, Cape as separate slots
- **Season / Battle Pass**: Monthly reward tracks tied to task completion
- **Collection Log**: Track every item, monster, achievement discovered
- **Base Building**: Shared party home with visual upgrades and passive bonuses
- **Group Challenges**: "Everyone does X by Friday or nobody gets the reward"
- **Photo Journal / Timeline**: Surface verified task photos as a scrollable life progress timeline
- **Focus Timer**: Pomodoro-style integration for Mental tasks with bonus EXP for deep focus
- **Category-specific completion mechanics**: Before/after photos for Household, gallery for Creative, etc.
- **Weekly Party Check-in**: Structured recap where each member shares highlight + struggle, earns bond EXP
- **Difficulty Progression Suggestions**: "You've done 20-min workouts for 3 weeks. Ready for 30?"

---

## Competitor & Research Notes

### Direct Competitors

| App | What They Do | What We Do Better | What They Do Better |
|---|---|---|---|
| **Habitica** | Gamified to-do list, pixel avatar, party quests | Deeper RPG (classes, gear, dungeons, idle content), real verification | Larger user base, guild system (removed 2023), web + mobile |
| **TaskHero** | MMORPG + habit tracking, guild system | Deeper loot/forge system, partner-specific features | More social (guilds, not just pairs) |
| **Couple Quest** (couplequest.me) | Relationship gamification, emotional check-ins, virtual pet | Task verification (photo/location), RPG depth | Emotional/relationship focus, virtual pet |
| **BestPrize** | Chores → XP, unlock gesture rewards | RPG depth, class system, dungeons | Real-world reward marketplace |
| **CoupleFit** | Fitness + couples streaks | Broader task categories (not just fitness), RPG systems | Fitness-specific features |
| **Amicado** | Friend challenges, AI matching | RPG progression, idle content, deeper systems | AI matching, group challenges |
| **The ShowUp App** | Accountability with monetary stakes | No real money risk, RPG motivation instead | Financial accountability, coaching |

### Key Research Findings

**Loot Psychology:**
- Variable ratio reinforcement creates stronger engagement than fixed rewards (behavioral research)
- **Curiosity** ("what could drop?") is the strongest driver of both enjoyment and continued play — stronger than raw reward value (GDC research)
- **Competence** (feeling effective) mediates motivation — players must feel they earned rewards
- Diablo 4 Loot 2.0: fewer but more meaningful affixes. Quality over quantity.

**Bad Luck Protection:**
- Pity systems prevent frustration cliffs that cause player churn
- Dynamic probability adjustment is better than hard cutoffs (soft pity > hard pity)
- Sweet spot: guarantee meaningful drop every 8–12 attempts for main loop

**IdleON Design Lessons:**
- Multi-character simultaneous progression = engagement multiplier
- Nested drop tables: Normal → Rare Table → Mega-Rare Table (layered rolls)
- AFK-exclusive rare drops reward patience over grinding
- Systems must interconnect: Alchemy → Cards → Stamps → Obols. Everything feeds everything.
- 983+ drop tables across 6 worlds — depth is the product

**AFK Journey Design Lessons:**
- $128M in 7 months — the genre works commercially
- "Low entry threshold, high depth development" — easy to start, years to master
- Idle resources as the fuel, not the car — spending money can't skip the idle timer
- Shared leveling across characters reduces friction
- Seasonal systems manage power creep

**Accountability Research:**
- Accountability partners increase success rates by 65%
- Small groups (5–15) show 73% higher completion rates vs. solo
- Social accountability works through: commitment consistency, identity reinforcement, reciprocal obligation
- Science-backed: novel shared activities significantly strengthen relationships (Berkeley research)
- Weekly structured check-ins improve relationship satisfaction (JMIR study, Paired app)

**Feature Scope Management:**
- Feature creep is the #1 killer of indie games
- Idle games need 18+ month strategic plans — every timer and multiplier shapes long-term retention
- Deepen existing systems before adding new ones
- Prioritize by impact-to-effort ratio: high-impact, low-effort first

**Loot & Economy Design Research:**
- Faucets must equal sinks — without balance, inflation makes rewards meaningless (GDC talk, Medium deep dives)
- 6 currency sinks and 11 item sinks identified in research, each with different behavioral economics implications (GDC 2014)
- Critical consumables should be easy to replenish — scarcity reinforces hoarding, not usage (Game Wisdom)
- Value chains: items gain meaning through utility in reaching future goals, not just core mechanics (Lost Garden)
- Diablo 4 Loot 2.0: fewer but more powerful affixes per item. Quality > quantity. Rare items get 2 affixes, Legendary get 3.
- Greater Affixes (1.5x power) on endgame gear create the ultra-rare chase
- Set bonuses: 2pc/4pc tier system is industry standard (Blizzard, WoW, Destiny 2). Allows partial commitment + hybrid builds.
- Multiple acquisition paths matter: drops, crafting, quest rewards, vendors each serve different player motivations (Gamasutra)
- Set loot (handcrafted) vs. randomized loot (procedural) both have value — set loot for narrative/milestone, random for replayability
- Expandable equipment slot systems (NGU Idle: 7 base + 14 unlockable) extend the gear chase across entire game lifetime
- "Too good to use" syndrome: rare consumables get hoarded forever. Fix by making common consumables abundant and low-stakes.

**IRL Task Design Research:**
- Self-Determination Theory (SDT): autonomy, competence, relatedness are the 3 pillars of sustainable motivation (Ryan & Deci, 2000 — 50,000+ citations)
- Habitica's HP-loss punishment system is counterproductive — peer-reviewed study found 7 ways it backfires (avoidance, anxiety, gaming the system)
- Task logging over 3.5 seconds causes attention residue lasting 22+ minutes (2023 study of 1,247 engineers)
- Gamified fitness interventions increase step counts but don't increase intrinsic motivation — behavior change occurs through reward-driven mechanisms independent of motivation shifts (JMIR 2024, n=4,800)
- Streak psychology works via loss aversion — but only when validation is local/zero-latency, not cloud-dependent (300-1200ms delays disrupt flow)
- Hybrid gamification (competitive + cooperative) outperforms purely competitive or purely cooperative designs
- RECIPE framework for meaningful gamification: Reflection, Exposition, Choice, Information, Play, Engagement — goes beyond points/badges
- Multisensory completion feedback (visual + haptic + sound) strengthens motivation through curiosity and competence, not raw dopamine (GDC research)
- Weekly habit streaks with micro-streaks increased consistency by 3.1x over 90 days when friction was minimized
- Pokemon Go / Sweatcoin: passive verification (HealthKit, GPS, accelerometer) removes friction — Sweatcoin converts ~65% of total steps to verified steps

---

## Technical Architecture Notes

### Files That Will Change (Phase 1: Loot + Content Pipeline)

| File | Changes |
|---|---|
| `Equipment.swift` | Add `prefix: EquipmentAffix?`, `suffix: EquipmentAffix?` properties |
| `LootTable.swift` / `LootGenerator` | Read from `ContentManager`, add pity system, affix rolling |
| `PlayerCharacter.swift` | Add `pityCounters: [String: Int]` |
| `GameEngine.swift` | Add loot rolls to task completion, read drop rates from server |
| `EquipmentCatalog.swift` | **Remove** — replaced by `content_equipment` table via `ContentManager` |
| `MilestoneGearCatalog.swift` | **Remove** — replaced by `content_milestone_gear` table |
| `GearSetCatalog.swift` | **Remove** — replaced by `content_gear_sets` table |
| `Consumable.swift` | Remove `ConsumableCatalog` — replaced by `content_consumables` table |
| `Dungeon.swift` | Remove static dungeons — replaced by `content_dungeons` table |
| `AFKMission.swift` | Remove static missions — replaced by `content_missions` table |
| `DutyBoardGenerator.swift` | Remove `taskPool` — replaced by `content_duties` table |
| `InventoryView.swift` | Show affixes on equipment cards |
| `ForgeView.swift` (both) | **Merge** into single unified ForgeView with 4 stations |

### New Files Needed (All Phases)

| Phase | File | Purpose |
|---|---|---|
| -1 | `SyncManager.swift` | Queue local writes for async cloud push, retry, conflict resolution |
| -1 | `SettingsView.swift` | Centralized settings (account, audio, privacy, gameplay, about) |
| 0 | `OnboardingView.swift` | Guided first-task flow post-character creation |
| 0 | `WelcomeBackView.swift` | Comeback gift screen for lapsed users |
| 0 | `DailyLoginRewardView.swift` | Daily login reward claim screen |
| 1 | `ContentManager.swift` | Central content cache: fetch, store, version check, typed access |
| 1 | `EquipmentAffix.swift` | Affix model, affix rolling logic (reads pool from ContentManager) |
| 1 | `MonsterCard.swift` | Card model, collection tracking, drop logic |
| 1 | `BestiaryView.swift` | Card collection grid, milestones, total bonuses |
| 2 | `PartyBond.swift` | Extended bond model for 1–4 members (or refactor Bond.swift) |
| 2 | `PartyFeedView.swift` | Party activity feed UI |
| 3 | `Expedition.swift` | Expedition + ExpeditionStage + ActiveExpedition models |
| 3 | `ExpeditionView.swift` | Expedition UI (launch, progress, results) |
| 4 | `ResearchTree.swift` | Research node model, tree structure |
| 4 | `ResearchView.swift` | Research tree UI |
| 5 | `RebirthView.swift` | Prestige confirmation screen (keep/lose/gain) |

### Files to Remove (After Content Pipeline Verified)

| File | Replaced By |
|---|---|
| `EquipmentCatalog.swift` (1,198 lines) | `content_equipment` table |
| `MilestoneGearCatalog.swift` (392 lines) | `content_milestone_gear` table |
| `GearSetCatalog.swift` (327 lines) | `content_gear_sets` table |
| `Views/Inventory/ForgeView.swift` | Merged into `Views/Forge/ForgeView.swift` |

### Files That Will Change (Phase -1: Data Architecture)

| File | Changes |
|---|---|
| `SupabaseService.swift` | Expand `syncCharacterData()` to push comprehensive JSONB snapshot (all fields). Add sync methods for achievements, tasks, goals, mood entries. |
| `PlayerCharacter.swift` | Ensure all fields serialize for cloud snapshot. Add `lastSyncTimestamp` for conflict resolution. |
| `GameEngine.swift` | Every write path calls `SyncManager.queue()` after local SwiftData write |
| `AchievementTracker.swift` | On unlock → write to `player_achievements` via SyncManager |
| `CouplesQuestApp.swift` | On launch → trigger cloud pull + merge before UI loads |

### Supabase Schema Changes

| Phase | Migration | Tables | Purpose |
|---|---|---|---|
| -1 | `006_player_sync_tables.sql` | `player_achievements`, `player_tasks`, `player_goals`, `player_daily_state`, `player_mood_entries`, `player_arena_runs`, `player_dungeon_runs`, `player_mission_history` | Cloud sync for all player progression data |
| 1 | `005_content_tables.sql` | 18 `content_*` tables + `player_cards` + `parties` + `party_feed` + `active_expeditions` | Server-driven content + party + card collection |
| 1 | Seed script | Populates `content_*` tables from existing Swift catalogs | Initial data load |
| 2 | (no new migration) | Uses `parties` + `party_feed` from 005 | Party system uses tables already created |
| 3 | (no new migration) | Uses `content_expeditions` + `active_expeditions` from 005 | Expeditions use tables already created |

### Data Migration Considerations

- **Phase -1 (Data Architecture):** All existing local-only data needs a one-time migration to cloud on first launch after update. SyncManager handles initial bulk upload.
- Equipment affix fields are optional (`prefix: EquipmentAffix?`) — existing equipment works without affixes (backward compatible)
- Pity counters are new fields on PlayerCharacter — default to 0 (backward compatible)
- Bond → PartyBond rename: Supabase table rename or new table with migration
- Party member array: Bond currently stores single `partnerID: UUID` — needs to become `memberIDs: [UUID]`
- Content pipeline: keep static Swift arrays as fallback for v1 (first-run offline). Remove after ContentManager is verified stable.
- Forge Shards: remove currency, convert any existing player shards to gold at fixed rate (1 shard = 10 gold)
- Existing player equipment in `equipment` table needs `slot` check updated to include 'Trinket'

---

## Open Questions

> These need answers before committing to code changes.

### Naming
- [ ] Final app name? QuestBond? PartyQuest? Something else?
- [ ] Check App Store availability for chosen name

### Party System
- [ ] Max party size: **4 (decided)**
- [ ] Can a user be in multiple parties? Or one party at a time? (Recommend: one at a time for simplicity)
- [ ] Party leader role? Or all members equal? (Recommend: all equal, any member can invite/remove)
- [ ] How does party dissolution work? What happens to bond progress? (Bond EXP resets? Or preserved per-pair?)
- [ ] Party streak: is "1 task per day" the right threshold? Or should it be "complete all daily habits"?
- [ ] Should party members be able to see each other's task lists or just completions?

### Monster Cards
- [ ] How many cards per dungeon theme at launch? (Proposed: 3–5)
- [ ] Should duplicate card drops give anything? (e.g., +0.1% to existing card's bonus, or convert to materials)
- [ ] Card rarity distribution: what % Common vs Uncommon vs Rare vs Epic vs Legendary?
- [ ] Should the Bestiary be a tab in Character view or its own tab in the main TabView?
- [ ] Card art: generate placeholder icons per theme, or use SF Symbols initially?

### Loot Balance
- [ ] Exact affix value ranges per rarity tier (need playtesting)
- [ ] Pity counter thresholds (proposed 20/12/5/3 — need validation)
- [ ] Task loot drop rate (5–8% proposed — too generous? Too stingy?)
- [ ] Should affixes be re-rollable? (Gold/gem cost to re-roll one affix) — currently proposed yes, gold sink
- [ ] Gem socket bonus values per gem type (need to feel meaningful without breaking balance)
- [ ] Should gems have quality tiers (Chipped → Flawed → Normal → Perfect)?
- [ ] How many Common consumables per day should feel right? (Currently proposed 1-2)
- [ ] Gear set piece drop rate in class dungeons? (needs to feel earnable but not trivial)
- [ ] 6 equipment slots: implement all at once in Phase 1 or start with 4 and add 2 later?
- [ ] Enhancement failure: should failed attempts give partial progress (e.g. +0.5 "pity" toward next guaranteed success)?
- [ ] Affix re-roll cost curve: flat gold cost or increasing cost per re-roll on same item?
- [ ] Should consumable effects stack? (e.g., EXP boost + Material Magnet active simultaneously)

### Expeditions
- [ ] How many expedition templates at launch? (Propose 8–12)
- [ ] Expedition key drop rate from dungeons?
- [ ] Can you cancel an expedition mid-run? Penalty?
- [ ] Maximum simultaneous expeditions? (Propose 1, upgradeable to 2 via research tree)

### Economy
- [ ] Do Research Tokens need to be a separate currency or can they be a craftable material?
- [ ] Gold sink balance — is the current economy too generous or too tight?
- [ ] Should expedition-exclusive gear be tradeable between party members?

### IRL Task Experience
- [ ] Should routine bundles be a launch feature or post-launch? (High impact but medium effort)
- [ ] Category-specific mechanics: implement all 6 at once or roll out 1–2 at a time?
- [ ] HealthKit auto-verify for physical tasks: scope and permissions model?
- [ ] Photo journal / timeline view: store photos locally or sync to Supabase? (Storage cost implications)
- [ ] Focus timer for mental tasks: build custom or integrate with existing iOS Focus modes?
- [ ] Widget support for quick-complete: which habits appear in widget? User-configurable?
- [ ] Streak freeze: how many per week? Purchasable with gold, gems, or earned via party bond?
- [ ] Should "missed opportunity" messaging show exact numbers or vague ("you missed out on rewards")?
- [ ] Category mastery: separate leveling system per category, or just a counter + milestones?

### Content Pipeline
- [ ] How to handle first-run offline? (Proposed: bundle a JSON snapshot of all content tables in the app binary as fallback)
- [ ] Content cache storage: SwiftData tables mirroring Supabase, or raw JSON in UserDefaults/FileManager?
- [ ] Should ContentManager fetch all tables on version bump, or only changed tables? (Simpler: all. Smarter: per-table versioning)
- [ ] Content admin: use Supabase dashboard directly, or build a simple web admin panel?
- [ ] Seed script format: SQL INSERT statements, or a Swift script that reads existing catalogs and calls Supabase API?
- [ ] How to handle content table schema changes post-launch? (Supabase migrations + app-side model versioning)

### Forge
- [ ] **Decided**: Kill Forge Shards, merge two forge systems into one with 4 stations
- [ ] Shard → Gold conversion rate for existing players? (Proposed: 1 shard = 10 gold)
- [ ] Should targeted crafting (lock primary stat) be available at all tiers or only Tier 2+?
- [ ] Consumable crafting: how many Herb recipes at launch? (Proposed: 5-8 covering common consumables)
- [ ] Affix re-roll: should re-roll count reset when you change the OTHER affix slot? (Proposed: yes, prevents infinite escalation)
- [ ] Should the Forge Catalyst consumable be expedition-only or also craftable from rare herbs?

### Onboarding
- [ ] Should onboarding first task be a real GameTask or a simulated demo? (Proposed: real task — player sees actual rewards)
- [ ] How many breadcrumb quests in first week? (Proposed: 5, one per day)
- [ ] Should breadcrumbs give bonus rewards or just guide? (Proposed: small gold bonus for completing each)

### Retention
- [ ] Daily login reward: should it require opening the app or just being "active"? (Proposed: opening = claim)
- [ ] Comeback gift: should party members be notified when someone returns? (Proposed: yes, party feed entry)
- [ ] Re-engagement notifications: use local scheduling or server-side via OneSignal? (Server-side is more reliable)

### End-Game
- [ ] Launch with Paragon Levels only, or build full Rebirth? (Proposed: Paragon for launch, Rebirth in Phase 5)
- [ ] Rebirth: should class reset be mandatory or optional? (Proposed: mandatory — adds replay variety)
- [ ] Paragon level stat assignment: random or player choice? (Proposed: random, with re-roll option for gold)

### Technical
- [ ] Party system: uses `parties` table from migration 005 (decided — not extending profiles)
- [ ] Expedition persistence: Supabase `active_expeditions` table (decided — needed for party expedition visibility)
- [ ] How much narrative content is needed for expeditions at launch?
- [ ] Task completion loot roll: animate in TaskDetailView or a global overlay?
- [ ] Routine bundles: new model or a property on GameTask grouping habits?
- [ ] ContentManager architecture: singleton service, or injected via SwiftUI environment?
- [ ] Content fetch: use Supabase Swift client `.from("content_equipment").select()` or a single RPC that returns all tables?

### Data Architecture
- [x] **Decided**: SyncManager is a singleton, called from services
- [x] **Decided**: Timestamp-based last-write-wins for conflict resolution
- [x] **Decided**: Queue on every write, flush every 30s + on app background
- [x] **Decided**: Silent retry with exponential backoff, subtle "sync pending" icon after 3 failures
- [x] **Decided**: Full JSONB snapshot on every sync (character data isn't large)
- [x] **Decided**: One-time bulk upload on first launch after update ("Backing up your progress..." screen)
- [x] **Decided**: Photo storage deferred — photos stay local. Revisit when revenue covers storage costs.

### Dungeon / Arena / Training Content
- [ ] How many dungeon themes total at launch? (Proposed: 12–15 unique themes for card variety)
- [ ] Room shuffle: fully random from pool, or weighted by dungeon difficulty?
- [ ] Should bonus rooms have their own loot table (higher rarity chance)?
- [x] **Decided**: Arena scales ~8-10% difficulty per wave above 10
- [x] **Decided**: 6 arena modifiers at launch, weekly rotation
- [x] **Decided**: Raid boss infinite tier scaling: tier = ceil(avg party level / 10), HP = 3000 × tier × party factor
- [ ] Should there be "event" dungeons with time-limited availability?

### Existing Systems
- [x] **Decided**: Wellness is a core feature — cloud sync, party integration, Wisdom buff
- [x] **Decided**: Mood sharing is triple opt-in (Settings toggle + per-mood confirm + subtle icon only)
- [x] **Decided**: Goal templates are server-driven via `content_goals` table
- [x] **Decided**: Mini-games playable anytime, but only duty board gives stat bonus
- [ ] Mini-games: should they have personal best leaderboards?
- [x] **Decided**: Wandering Merchant event (10% daily chance, 1-3 items, server-driven)
- [x] **Decided**: 4 NPCs at launch (Shopkeeper, Forgekeeper, Quest Giver, Card Collector)
- [x] **Decided**: Weather kept — display on Home + task suggestions. Graceful hide if permission denied.
- [x] **Decided**: Data export is JSON — tasks, achievements, goals, mood entries, analytics
- [x] **Decided**: Party leaderboard at launch. Global deferred (needs anti-cheat).
- [x] **Decided**: No second evolution tier at launch. Rebirth provides class variety.
- [x] **Decided**: Analytics insights engine yes, low priority (Phase 0 Agent 2.5, last items)
- [x] **Decided**: Settings gear icon in Character tab. Immediate deletion with type-to-confirm.
- [x] **Decided**: Daily quests keep 3+1, add 7 new types, add weekly bonus quest, server-driven
- [x] **Decided**: Duties drop loot at same rates as tasks. 4+1 bonus duty. 50g paid refresh.
- [x] **Decided**: Affix Scrolls sold in store at 800g. Cards are drop-only.
- [x] **Decided**: Verification reward tiers (1.0x-1.5x EXP). Any party member can verify.
- [x] **Decided**: Class fantasy: exclusive approaches, gated rooms, +20% affinity, class-specific affixes
- [x] **Decided**: Audio: sounds for all new systems, haptics paired, no background music, SFX manifest later
- [x] **Decided**: Leaderboard: Option C (Home card + Party tab), solo personal records fallback

---

*This document is the single source of truth for design decisions. Update it before starting any implementation work. Other agents should read this document first to understand the full context.*
