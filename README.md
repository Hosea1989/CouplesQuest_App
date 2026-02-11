# DuoCraft

A gamified task management iOS app for couples. Complete real-life tasks to earn EXP, level up your character, and send them on AFK missions while you're away.

## Features

- **Task System**: Create tasks, assign to partner, or add to shared duty board
- **Deep RPG Progression**: Stats, classes, skills, equipment, and achievements
- **AFK Missions**: Your character goes on automated missions based on their stats
- **Partner Sync**: Connect with your partner via CloudKit for real-time updates
- **Apple Watch Integration**: (Coming in Phase 4) Track physical tasks with HealthKit

## Tech Stack

- **SwiftUI** - Modern declarative UI
- **SwiftData** - Persistence (Core Data successor)
- **CloudKit** - Free sync between partners (included with Apple Developer account)
- **HealthKit** - Activity tracking (Phase 4)
- **WatchKit** - Apple Watch companion (Phase 4)

## Requirements

- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+
- Apple Developer Account (for CloudKit)

## Setup Instructions

### 1. Create Xcode Project

1. Open Xcode
2. File → New → Project
3. Select **iOS → App**
4. Configure:
   - Product Name: `CouplesQuest`
   - Team: Your Apple Developer Team
   - Organization Identifier: `com.yourname` (or your bundle ID prefix)
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **SwiftData**
   - ✅ Include Tests (optional)

### 2. Add Source Files

1. In Xcode, delete the auto-generated `ContentView.swift` and `CouplesQuestApp.swift`
2. Right-click on the `CouplesQuest` folder in the Project Navigator
3. Select **Add Files to "CouplesQuest"...**
4. Navigate to this folder's `CouplesQuest/CouplesQuest/` directory
5. Select all folders (`App`, `Models`, `Views`, `Services`, `Resources`)
6. Make sure **"Copy items if needed"** is checked
7. Click **Add**

### 3. Configure Color Assets

1. In Xcode's Project Navigator, locate the `Assets.xcassets` file
2. Right-click → **Show in Finder**
3. Copy all `.colorset` folders from `Resources/Colors.xcassets/` into your `Assets.xcassets`
4. Alternatively, drag the entire `Colors.xcassets` folder into your project

### 4. Enable CloudKit (for Partner Sync)

1. Select your project in the Navigator
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **iCloud**
5. Check **CloudKit**
6. Add a container: `iCloud.com.yourname.CouplesQuest`

### 5. Build and Run

1. Select a simulator or your iPhone
2. Press **Cmd + R** to build and run
3. The app should launch with the character creation screen

## Project Structure

```
CouplesQuest/
├── App/
│   ├── CouplesQuestApp.swift    # App entry point
│   └── ContentView.swift         # Main tab view
├── Models/
│   ├── PlayerCharacter.swift    # Character model
│   ├── Stats.swift              # Stat system
│   ├── GameTask.swift           # Task model
│   ├── AFKMission.swift         # Mission system
│   └── Equipment.swift          # Items & skills
├── Views/
│   ├── Home/
│   │   └── HomeView.swift       # Dashboard
│   ├── Tasks/
│   │   ├── TasksView.swift      # Task list
│   │   └── CreateTaskView.swift # Task creation
│   ├── Character/
│   │   ├── CharacterView.swift  # Character sheet
│   │   └── CharacterCreationView.swift
│   ├── Missions/
│   │   └── MissionsView.swift   # AFK missions
│   └── Partner/
│       └── PartnerView.swift    # Partner connection
├── Services/
│   └── GameEngine.swift         # Core game logic
└── Resources/
    └── Colors.xcassets/         # Color definitions
```

## Development Phases

### Phase 1: Foundation (Current)
- ✅ Project structure
- ✅ Data models
- ✅ Basic views
- ✅ EXP/leveling system
- ✅ Task CRUD

### Phase 2: Partner Features
- [ ] CloudKit integration
- [ ] Partner pairing
- [ ] Real-time sync
- [ ] Shared duty board

### Phase 3: Deep RPG
- [ ] Character classes
- [ ] Skill trees
- [ ] Equipment drops
- [ ] Achievement system

### Phase 4: Apple Watch
- [ ] WatchOS app
- [ ] HealthKit integration
- [ ] Physical task auto-complete
- [ ] Glanceable widgets

### Phase 5: Polish
- [ ] Animations
- [ ] Sound effects
- [ ] Onboarding
- [ ] App Store assets

## Game Mechanics

### EXP Curve
Level progression uses an exponential curve:
```
EXP for level N = 100 × (N-1)^1.5
```

### Stats
| Stat | Improved By | Mission Bonus |
|------|-------------|---------------|
| Strength | Physical tasks | Combat missions |
| Wisdom | Mental tasks | Research missions |
| Endurance | Streaks | Long expeditions |
| Charisma | Social tasks | Negotiations |
| Dexterity | Household tasks | Stealth missions |
| Luck | Random | Rare item drops |

### Task Difficulties
| Difficulty | EXP | Gold |
|------------|-----|------|
| Easy | 10 | 5 |
| Medium | 25 | 15 |
| Hard | 50 | 35 |
| Epic | 100 | 75 |

## License

Private project for personal use.

## Credits
- Damien H.
- Ryan M.
- Built with SwiftUI and a lot of caffeine ☕

