import Foundation
import SwiftData

// MARK: - Dungeon Template

/// A dungeon that players can enter solo or with friends
@Model
final class Dungeon {
    /// Unique identifier
    var id: UUID
    
    /// Dungeon name
    var name: String
    
    /// Flavor text describing the dungeon
    var dungeonDescription: String
    
    /// Visual theme
    var theme: DungeonTheme
    
    /// Difficulty tier
    var difficulty: DungeonDifficulty
    
    /// Ordered list of rooms/encounters
    var rooms: [DungeonRoom]
    
    /// Minimum level to enter
    var levelRequirement: Int
    
    /// Recommended total stat points
    var recommendedStatTotal: Int
    
    /// Max party size (1 = solo only, 2+ = co-op)
    var maxPartySize: Int
    
    /// Base EXP reward for completion
    var baseExpReward: Int
    
    /// Base gold reward for completion
    var baseGoldReward: Int
    
    /// Determines quality of loot drops (1-5)
    var lootTier: Int
    
    /// Is this dungeon currently available?
    var isAvailable: Bool
    
    init(
        name: String,
        description: String,
        theme: DungeonTheme,
        difficulty: DungeonDifficulty,
        rooms: [DungeonRoom],
        levelRequirement: Int,
        recommendedStatTotal: Int = 30,
        maxPartySize: Int = 2,
        baseExpReward: Int,
        baseGoldReward: Int,
        lootTier: Int = 1,
        isAvailable: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.dungeonDescription = description
        self.theme = theme
        self.difficulty = difficulty
        self.rooms = rooms
        self.levelRequirement = levelRequirement
        self.recommendedStatTotal = recommendedStatTotal
        self.maxPartySize = maxPartySize
        self.baseExpReward = baseExpReward
        self.baseGoldReward = baseGoldReward
        self.lootTier = lootTier
        self.isAvailable = isAvailable
    }
    
    /// Number of rooms
    var roomCount: Int { rooms.count }
    
    /// The boss encounter, if any
    var bossRoom: DungeonRoom? {
        rooms.first(where: { $0.isBossRoom })
    }
    
    /// Total duration for a dungeon run in seconds
    var durationSeconds: Int {
        roomCount * difficulty.secondsPerRoom
    }
    
    /// Duration formatted as string
    var durationFormatted: String {
        let hours = durationSeconds / 3600
        let minutes = (durationSeconds % 3600) / 60
        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
    
    /// Star rating for difficulty display
    var difficultyStars: Int {
        switch difficulty {
        case .normal: return 1
        case .hard: return 2
        case .heroic: return 3
        case .mythic: return 4
        }
    }
}

// MARK: - Room Approach

/// A strategic approach the player can choose when facing a room encounter
struct RoomApproach: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var approachDescription: String
    var icon: String
    var primaryStat: StatType
    var powerModifier: Double   // 1.0 = normal, 1.2 = risky/rewarding
    var riskModifier: Double    // 1.0 = normal, 1.5 = more HP lost on fail
    
    /// Risk level label for UI display
    var riskLabel: String {
        switch riskModifier {
        case ..<1.1: return "Safe"
        case 1.1..<1.4: return "Balanced"
        default: return "Risky"
        }
    }
    
    /// Risk color for UI display
    var riskColor: String {
        switch riskModifier {
        case ..<1.1: return "AccentGreen"
        case 1.1..<1.4: return "AccentGold"
        default: return "DifficultyHard"
        }
    }
    
    init(
        name: String,
        description: String,
        icon: String,
        primaryStat: StatType,
        powerModifier: Double = 1.0,
        riskModifier: Double = 1.0
    ) {
        self.id = UUID()
        self.name = name
        self.approachDescription = description
        self.icon = icon
        self.primaryStat = primaryStat
        self.powerModifier = powerModifier
        self.riskModifier = riskModifier
    }
}

// MARK: - Dungeon Room

/// A single encounter within a dungeon
struct DungeonRoom: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var roomDescription: String
    var encounterType: EncounterType
    var primaryStat: StatType
    var difficultyRating: Int
    var isBossRoom: Bool
    var bonusLootChance: Double
    
    init(
        name: String,
        description: String,
        encounterType: EncounterType,
        primaryStat: StatType,
        difficultyRating: Int,
        isBossRoom: Bool = false,
        bonusLootChance: Double = 0.0
    ) {
        self.id = UUID()
        self.name = name
        self.roomDescription = description
        self.encounterType = encounterType
        self.primaryStat = primaryStat
        self.difficultyRating = difficultyRating
        self.isBossRoom = isBossRoom
        self.bonusLootChance = bonusLootChance
    }
}

// MARK: - Activity Feed Entry

/// Type of activity feed entry during a dungeon run
enum FeedEntryType: String, Codable {
    case roomEntered = "Room Entered"
    case approachChosen = "Approach Chosen"
    case outcomeSuccess = "Success"
    case outcomeFail = "Failure"
    case lootFound = "Loot Found"
    case hpChange = "HP Change"
    case partnerAction = "Partner Action"
    case dungeonComplete = "Dungeon Complete"
    case dungeonFailed = "Dungeon Failed"
    
    var defaultIcon: String {
        switch self {
        case .roomEntered: return "door.left.hand.open"
        case .approachChosen: return "hand.point.right.fill"
        case .outcomeSuccess: return "checkmark.circle.fill"
        case .outcomeFail: return "xmark.circle.fill"
        case .lootFound: return "gift.fill"
        case .hpChange: return "heart.fill"
        case .partnerAction: return "person.2.fill"
        case .dungeonComplete: return "trophy.fill"
        case .dungeonFailed: return "xmark.shield.fill"
        }
    }
    
    var defaultColor: String {
        switch self {
        case .roomEntered: return "AccentGold"
        case .approachChosen: return "StatWisdom"
        case .outcomeSuccess: return "AccentGreen"
        case .outcomeFail: return "DifficultyHard"
        case .lootFound: return "AccentPurple"
        case .hpChange: return "StatDexterity"
        case .partnerAction: return "AccentPink"
        case .dungeonComplete: return "AccentGold"
        case .dungeonFailed: return "DifficultyHard"
        }
    }
}

/// A single entry in the dungeon run activity feed
struct DungeonFeedEntry: Codable, Identifiable {
    var id: UUID
    var timestamp: Date
    var type: FeedEntryType
    var message: String
    var icon: String
    var color: String
    
    init(
        type: FeedEntryType,
        message: String,
        icon: String? = nil,
        color: String? = nil
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.type = type
        self.message = message
        self.icon = icon ?? type.defaultIcon
        self.color = color ?? type.defaultColor
    }
}

// MARK: - Dungeon Run (Active/Completed)

/// Tracks an in-progress or completed dungeon run
@Model
final class DungeonRun {
    var id: UUID
    var dungeonID: UUID
    var dungeonName: String
    var partyMemberIDs: [UUID]
    var partyMemberNames: [String]
    var currentRoomIndex: Int
    var roomResults: [RoomResult]
    var feedEntries: [DungeonFeedEntry]
    var status: DungeonRunStatus
    var startedAt: Date
    var completedAt: Date?
    var partyHP: Int
    var maxPartyHP: Int
    var totalExpEarned: Int
    var totalGoldEarned: Int
    var lootEarnedIDs: [UUID]
    var isCoopRun: Bool
    
    /// When the dungeon run timer completes (AFK timer)
    var completesAt: Date?
    
    /// Whether the dungeon has been resolved (prevents double-resolution)
    var isResolved: Bool = false
    
    /// Duration of the dungeon run in seconds (stored for display)
    var durationSeconds: Int = 0
    
    init(dungeon: Dungeon, partyMembers: [PlayerCharacter], isCoop: Bool = false) {
        self.id = UUID()
        self.dungeonID = dungeon.id
        self.dungeonName = dungeon.name
        self.partyMemberIDs = partyMembers.map { $0.id }
        self.partyMemberNames = partyMembers.map { $0.name }
        self.currentRoomIndex = 0
        self.roomResults = []
        self.feedEntries = []
        self.status = .inProgress
        self.startedAt = Date()
        self.completedAt = nil
        let hp = 100 * partyMembers.count
        self.partyHP = hp
        self.maxPartyHP = hp
        self.totalExpEarned = 0
        self.totalGoldEarned = 0
        self.lootEarnedIDs = []
        self.isCoopRun = isCoop
        self.durationSeconds = dungeon.durationSeconds
        self.completesAt = Date().addingTimeInterval(TimeInterval(dungeon.durationSeconds))
        self.isResolved = false
        
        // Add initial feed entry
        self.feedEntries.append(DungeonFeedEntry(
            type: .roomEntered,
            message: "Entered \(dungeon.name)\(isCoop ? " as a party" : " solo")"
        ))
    }
    
    var isComplete: Bool {
        status == .completed || status == .failed
    }
    
    /// Is the AFK timer complete?
    var isTimerComplete: Bool {
        guard let completesAt = completesAt else { return true }
        return Date() >= completesAt
    }
    
    /// Time remaining in seconds
    var timeRemaining: TimeInterval {
        guard let completesAt = completesAt else { return 0 }
        return max(0, completesAt.timeIntervalSince(Date()))
    }
    
    /// Progress (0.0 - 1.0)
    var timerProgress: Double {
        guard durationSeconds > 0 else { return 1.0 }
        let total = TimeInterval(durationSeconds)
        let elapsed = Date().timeIntervalSince(startedAt)
        return min(1.0, elapsed / total)
    }
    
    /// Time remaining formatted
    var timeRemainingFormatted: String {
        let remaining = Int(timeRemaining)
        let hours = remaining / 3600
        let minutes = (remaining % 3600) / 60
        let seconds = remaining % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    /// Total duration formatted
    var durationFormatted: String {
        let hours = durationSeconds / 3600
        let minutes = (durationSeconds % 3600) / 60
        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
    
    var hpPercentage: Double {
        guard maxPartyHP > 0 else { return 0 }
        return Double(partyHP) / Double(maxPartyHP)
    }
    
    var partySize: Int {
        partyMemberIDs.count
    }
    
    /// Add a feed entry to the activity log
    func addFeedEntry(_ entry: DungeonFeedEntry) {
        feedEntries.append(entry)
    }
    
    /// Add a feed entry with type and message
    func addFeedEntry(type: FeedEntryType, message: String, icon: String? = nil, color: String? = nil) {
        feedEntries.append(DungeonFeedEntry(type: type, message: message, icon: icon, color: color))
    }
}

// MARK: - Room Result

/// Outcome of attempting a single dungeon room
struct RoomResult: Codable, Identifiable {
    var id: UUID
    var roomIndex: Int
    var roomName: String
    var success: Bool
    var playerPower: Int
    var requiredPower: Int
    var expEarned: Int
    var goldEarned: Int
    var hpLost: Int
    var lootDropped: Bool
    var narrativeText: String
    var approachName: String
    
    init(
        roomIndex: Int,
        roomName: String,
        success: Bool,
        playerPower: Int,
        requiredPower: Int,
        expEarned: Int = 0,
        goldEarned: Int = 0,
        hpLost: Int = 0,
        lootDropped: Bool = false,
        narrativeText: String = "",
        approachName: String = ""
    ) {
        self.id = UUID()
        self.roomIndex = roomIndex
        self.roomName = roomName
        self.success = success
        self.playerPower = playerPower
        self.requiredPower = requiredPower
        self.expEarned = expEarned
        self.goldEarned = goldEarned
        self.hpLost = hpLost
        self.lootDropped = lootDropped
        self.narrativeText = narrativeText
        self.approachName = approachName
    }
}

// MARK: - Encounter Type

enum EncounterType: String, Codable, CaseIterable {
    case combat = "Combat"
    case puzzle = "Puzzle"
    case trap = "Trap"
    case treasure = "Treasure"
    case boss = "Boss"
    
    var icon: String {
        switch self {
        case .combat: return "sword.2.crossed"
        case .puzzle: return "puzzlepiece.fill"
        case .trap: return "exclamationmark.triangle.fill"
        case .treasure: return "gift.fill"
        case .boss: return "crown.fill"
        }
    }
    
    var color: String {
        switch self {
        case .combat: return "StatStrength"
        case .puzzle: return "StatWisdom"
        case .trap: return "StatDexterity"
        case .treasure: return "AccentGold"
        case .boss: return "RarityEpic"
        }
    }
    
    /// Available strategic approaches for this encounter type
    var approaches: [RoomApproach] {
        switch self {
        case .combat:
            return [
                RoomApproach(
                    name: "Aggressive Strike",
                    description: "Attack head-on with raw power",
                    icon: "flame.fill",
                    primaryStat: .strength,
                    powerModifier: 1.25,
                    riskModifier: 1.5
                ),
                RoomApproach(
                    name: "Defensive Stance",
                    description: "Hold your ground and outlast the enemy",
                    icon: "shield.fill",
                    primaryStat: .dexterity,
                    powerModifier: 0.9,
                    riskModifier: 0.7
                ),
                RoomApproach(
                    name: "Tactical Maneuver",
                    description: "Outmaneuver the enemy with agility",
                    icon: "arrow.triangle.swap",
                    primaryStat: .dexterity,
                    powerModifier: 1.1,
                    riskModifier: 1.0
                )
            ]
        case .puzzle:
            return [
                RoomApproach(
                    name: "Analyze",
                    description: "Study the puzzle carefully and solve it logically",
                    icon: "magnifyingglass",
                    primaryStat: .wisdom,
                    powerModifier: 1.0,
                    riskModifier: 0.8
                ),
                RoomApproach(
                    name: "Intuition",
                    description: "Trust your gut and take a leap of faith",
                    icon: "sparkles",
                    primaryStat: .luck,
                    powerModifier: 1.3,
                    riskModifier: 1.5
                ),
                RoomApproach(
                    name: "Negotiate",
                    description: "Talk your way through the challenge",
                    icon: "bubble.left.fill",
                    primaryStat: .charisma,
                    powerModifier: 1.05,
                    riskModifier: 1.0
                )
            ]
        case .trap:
            return [
                RoomApproach(
                    name: "Disarm",
                    description: "Carefully disarm the trap mechanism",
                    icon: "wrench.and.screwdriver.fill",
                    primaryStat: .dexterity,
                    powerModifier: 1.1,
                    riskModifier: 1.0
                ),
                RoomApproach(
                    name: "Tank Through",
                    description: "Brace yourself and push through the trap",
                    icon: "figure.run",
                    primaryStat: .dexterity,
                    powerModifier: 0.85,
                    riskModifier: 0.6
                ),
                RoomApproach(
                    name: "Find Alternate Route",
                    description: "Search for a hidden path around the trap",
                    icon: "map.fill",
                    primaryStat: .wisdom,
                    powerModifier: 1.2,
                    riskModifier: 1.3
                )
            ]
        case .treasure:
            return [
                RoomApproach(
                    name: "Open Carefully",
                    description: "Check for traps before opening",
                    icon: "hand.raised.fill",
                    primaryStat: .dexterity,
                    powerModifier: 1.0,
                    riskModifier: 0.7
                ),
                RoomApproach(
                    name: "Detect Magic",
                    description: "Use knowledge to identify magical wards",
                    icon: "wand.and.stars",
                    primaryStat: .wisdom,
                    powerModifier: 1.1,
                    riskModifier: 1.0
                ),
                RoomApproach(
                    name: "Just Grab It",
                    description: "Fortune favors the bold — grab everything!",
                    icon: "hand.thumbsup.fill",
                    primaryStat: .luck,
                    powerModifier: 1.35,
                    riskModifier: 1.6
                )
            ]
        case .boss:
            return [
                RoomApproach(
                    name: "All-Out Assault",
                    description: "Throw everything you have at the boss",
                    icon: "bolt.fill",
                    primaryStat: .strength,
                    powerModifier: 1.3,
                    riskModifier: 1.6
                ),
                RoomApproach(
                    name: "Endurance Battle",
                    description: "Outlast the boss with patience and grit",
                    icon: "shield.lefthalf.filled",
                    primaryStat: .dexterity,
                    powerModifier: 0.95,
                    riskModifier: 0.7
                ),
                RoomApproach(
                    name: "Exploit Weakness",
                    description: "Study the boss and find a vulnerability",
                    icon: "eye.fill",
                    primaryStat: .wisdom,
                    powerModifier: 1.2,
                    riskModifier: 1.2
                )
            ]
        }
    }
    
    /// Get approach-specific success narratives
    func successNarrative(for approach: RoomApproach) -> [String] {
        switch (self, approach.primaryStat) {
        case (.combat, .strength):
            return ["Your raw power shatters their defenses!", "A devastating blow ends the fight swiftly!"]
        case (.combat, .dexterity):
            return ["A swift flanking maneuver catches them off guard!", "Your nimble footwork creates the perfect opening!", "You outlast the enemy — they crumble from exhaustion!"]
        case (.puzzle, .wisdom):
            return ["Careful analysis reveals the solution!", "Every piece falls into place logically."]
        case (.puzzle, .luck):
            return ["A wild guess... and it works! Incredible!", "Your intuition guides you to the answer!"]
        case (.puzzle, .charisma):
            return ["You convince the guardian to reveal the answer!", "Your silver tongue finds a way!"]
        case (.trap, .dexterity):
            return ["Nimble fingers disarm the mechanism!", "The trap is neutralized with surgical precision!", "You push through! Barely a scratch."]
        case (.trap, .wisdom):
            return ["You spot a hidden passage around the trap!", "A clever detour avoids all danger!"]
        case (.boss, .strength):
            return ["An overwhelming assault brings the boss to its knees!", "Pure power topples the mighty foe!"]
        case (.boss, .dexterity):
            return ["A war of attrition — you stand when the boss falls!", "Patience and grit win the day!"]
        case (.boss, .wisdom):
            return ["You exploit a critical weakness — the boss staggers!", "Knowledge is power — a surgical strike ends it!"]
        default:
            return successNarratives
        }
    }
    
    /// Get approach-specific failure narratives
    func failureNarrative(for approach: RoomApproach) -> [String] {
        switch (self, approach.primaryStat) {
        case (.combat, .strength):
            return ["Your aggressive strike leaves you exposed!", "The enemy absorbs your blow and counters hard!"]
        case (.combat, .dexterity):
            return ["Your maneuver is read — they cut you off!", "Too slow! The enemy anticipates your move.", "Your defense holds, but not well enough."]
        case (.puzzle, .luck):
            return ["Your gamble doesn't pay off — a painful backlash!", "Intuition fails you this time!"]
        case (.trap, .wisdom):
            return ["The alternate route was a dead end — the trap triggers!", "Your shortcut leads straight into danger!"]
        case (.boss, .strength):
            return ["Your all-out attack overextends you!", "The boss punishes your recklessness!"]
        default:
            return failureNarratives
        }
    }
    
    var successNarratives: [String] {
        switch self {
        case .combat:
            return [
                "Your blade strikes true! The enemies fall before you.",
                "A fierce battle, but your strength prevails!",
                "The foes scatter as your power overwhelms them."
            ]
        case .puzzle:
            return [
                "The ancient mechanism clicks into place. Brilliant!",
                "Your wisdom guides you through the riddle with ease.",
                "The magical barrier dissolves as you speak the answer."
            ]
        case .trap:
            return [
                "You spot the trap just in time and nimbly avoid it!",
                "Your quick reflexes save you from the hidden danger.",
                "The trap triggers harmlessly as you dance past it."
            ]
        case .treasure:
            return [
                "You discover a hidden cache of treasures!",
                "Fortune smiles upon you — riches await!",
                "A glimmering pile of rewards catches your eye."
            ]
        case .boss:
            return [
                "The boss falls with a thunderous crash! Victory is yours!",
                "An epic battle for the ages — you stand triumphant!",
                "The dungeon lord has been vanquished!"
            ]
        }
    }
    
    var failureNarratives: [String] {
        switch self {
        case .combat:
            return [
                "The enemies land heavy blows. You're forced to retreat!",
                "Outnumbered and outmatched — you barely escape.",
                "The battle goes poorly. You take significant damage."
            ]
        case .puzzle:
            return [
                "The puzzle remains unsolved. A magical backlash stings!",
                "Wrong answer! The mechanism triggers a penalty.",
                "The riddle proves too complex this time."
            ]
        case .trap:
            return [
                "The trap springs! You take a painful hit.",
                "Too slow! The trap catches you off guard.",
                "Hidden spikes find their mark. That's going to leave a mark."
            ]
        case .treasure:
            return [
                "The treasure chest was a mimic! It bites!",
                "A guardian spirit attacks as you reach for the treasure.",
                "The treasures crumble to dust as you touch them."
            ]
        case .boss:
            return [
                "The boss is too powerful! You're sent flying!",
                "A devastating attack overwhelms your defenses.",
                "The dungeon lord laughs as you falter."
            ]
        }
    }
}

// MARK: - Dungeon Difficulty

enum DungeonDifficulty: String, Codable, CaseIterable {
    case normal = "Normal"
    case hard = "Hard"
    case heroic = "Heroic"
    case mythic = "Mythic"
    
    var color: String {
        switch self {
        case .normal: return "DifficultyEasy"
        case .hard: return "DifficultyMedium"
        case .heroic: return "DifficultyHard"
        case .mythic: return "DifficultyEpic"
        }
    }
    
    var rewardMultiplier: Double {
        switch self {
        case .normal: return 1.0
        case .hard: return 1.5
        case .heroic: return 2.5
        case .mythic: return 4.0
        }
    }
    
    /// Seconds per room — determines how long a dungeon run takes
    var secondsPerRoom: Int {
        switch self {
        case .normal: return 600     // 10 min/room
        case .hard: return 900       // 15 min/room
        case .heroic: return 1200    // 20 min/room
        case .mythic: return 1800    // 30 min/room
        }
    }
    
    var icon: String {
        switch self {
        case .normal: return "shield"
        case .hard: return "shield.fill"
        case .heroic: return "shield.lefthalf.filled"
        case .mythic: return "bolt.shield.fill"
        }
    }
}

// MARK: - Dungeon Theme

enum DungeonTheme: String, Codable, CaseIterable {
    case cave = "Cave"
    case ruins = "Ruins"
    case forest = "Forest"
    case fortress = "Fortress"
    case volcano = "Volcano"
    case abyss = "Abyss"
    
    var icon: String {
        switch self {
        case .cave: return "mountain.2.fill"
        case .ruins: return "building.columns.fill"
        case .forest: return "leaf.fill"
        case .fortress: return "building.fill"
        case .volcano: return "flame.fill"
        case .abyss: return "tornado"
        }
    }
}

// MARK: - Dungeon Run Status

enum DungeonRunStatus: String, Codable {
    case inProgress = "In Progress"
    case completed = "Completed"
    case failed = "Failed"
    case abandoned = "Abandoned"
}

// MARK: - Sample Dungeons

struct SampleDungeons {
    static var all: [Dungeon] {
        [goblinCaves, ancientRuins, shadowForest, ironFortress, dragonsPeak, theAbyss]
    }
    
    static var goblinCaves: Dungeon {
        Dungeon(
            name: "Goblin Caves",
            description: "A network of shallow caves infested with goblins. Perfect for aspiring adventurers.",
            theme: .cave,
            difficulty: .normal,
            rooms: [
                DungeonRoom(name: "Cave Entrance", description: "Goblins guard the entrance with crude weapons.", encounterType: .combat, primaryStat: .strength, difficultyRating: 12),
                DungeonRoom(name: "Trapped Corridor", description: "The goblins have rigged the corridor with pit traps.", encounterType: .trap, primaryStat: .dexterity, difficultyRating: 10),
                DungeonRoom(name: "Goblin Chief", description: "The goblin chief awaits with his elite guard!", encounterType: .boss, primaryStat: .strength, difficultyRating: 18, isBossRoom: true, bonusLootChance: 0.3)
            ],
            levelRequirement: 1,
            recommendedStatTotal: 30,
            baseExpReward: 150,
            baseGoldReward: 80,
            lootTier: 1
        )
    }
    
    static var ancientRuins: Dungeon {
        Dungeon(
            name: "Ancient Ruins",
            description: "Crumbling ruins filled with ancient puzzles and forgotten guardians.",
            theme: .ruins,
            difficulty: .normal,
            rooms: [
                DungeonRoom(name: "The Entry Hall", description: "Faded murals line the walls. A puzzle blocks the path.", encounterType: .puzzle, primaryStat: .wisdom, difficultyRating: 14),
                DungeonRoom(name: "Guardian Chamber", description: "Stone golems awaken as you enter!", encounterType: .combat, primaryStat: .strength, difficultyRating: 16),
                DungeonRoom(name: "Treasure Vault", description: "A hidden vault glimmers with ancient riches.", encounterType: .treasure, primaryStat: .luck, difficultyRating: 10, bonusLootChance: 0.5),
                DungeonRoom(name: "The Sealed Door", description: "An ancient mechanism guards the final chamber.", encounterType: .puzzle, primaryStat: .wisdom, difficultyRating: 20, isBossRoom: true, bonusLootChance: 0.35)
            ],
            levelRequirement: 5,
            recommendedStatTotal: 45,
            baseExpReward: 350,
            baseGoldReward: 200,
            lootTier: 2
        )
    }
    
    static var shadowForest: Dungeon {
        Dungeon(
            name: "Shadow Forest",
            description: "An enchanted forest where shadows are alive. Stealth and agility are key.",
            theme: .forest,
            difficulty: .hard,
            rooms: [
                DungeonRoom(name: "Whispering Path", description: "The trees seem to watch your every move...", encounterType: .trap, primaryStat: .dexterity, difficultyRating: 20),
                DungeonRoom(name: "Spider's Nest", description: "Giant spiders descend from the canopy!", encounterType: .combat, primaryStat: .dexterity, difficultyRating: 22),
                DungeonRoom(name: "The Riddle Tree", description: "An ancient treant blocks the path with a riddle.", encounterType: .puzzle, primaryStat: .wisdom, difficultyRating: 24),
                DungeonRoom(name: "Shadow Ambush", description: "Living shadows attack from every direction!", encounterType: .combat, primaryStat: .dexterity, difficultyRating: 26),
                DungeonRoom(name: "The Forest Heart", description: "The corrupted heart of the forest pulses with dark energy.", encounterType: .boss, primaryStat: .charisma, difficultyRating: 30, isBossRoom: true, bonusLootChance: 0.4)
            ],
            levelRequirement: 10,
            recommendedStatTotal: 60,
            baseExpReward: 750,
            baseGoldReward: 400,
            lootTier: 3
        )
    }
    
    static var ironFortress: Dungeon {
        Dungeon(
            name: "Iron Fortress",
            description: "A heavily fortified stronghold. Brute strength alone won't get you through.",
            theme: .fortress,
            difficulty: .hard,
            rooms: [
                DungeonRoom(name: "The Gates", description: "Massive iron gates block the entrance. Find a way in.", encounterType: .puzzle, primaryStat: .wisdom, difficultyRating: 25),
                DungeonRoom(name: "Guard Barracks", description: "Alert guards rush to stop you!", encounterType: .combat, primaryStat: .strength, difficultyRating: 28),
                DungeonRoom(name: "Trapped Armory", description: "The armory is rigged with explosive traps!", encounterType: .trap, primaryStat: .dexterity, difficultyRating: 26),
                DungeonRoom(name: "The War Room", description: "The commander can be defeated by blade or by words.", encounterType: .combat, primaryStat: .charisma, difficultyRating: 30),
                DungeonRoom(name: "Fortress Vault", description: "The fortress's legendary vault lies before you.", encounterType: .treasure, primaryStat: .luck, difficultyRating: 20, bonusLootChance: 0.6),
                DungeonRoom(name: "The Iron Warden", description: "A massive construct of iron and magic guards the depths!", encounterType: .boss, primaryStat: .strength, difficultyRating: 35, isBossRoom: true, bonusLootChance: 0.45)
            ],
            levelRequirement: 15,
            recommendedStatTotal: 80,
            baseExpReward: 1200,
            baseGoldReward: 650,
            lootTier: 3
        )
    }
    
    static var dragonsPeak: Dungeon {
        Dungeon(
            name: "Dragon's Peak",
            description: "Scale the volcanic peak where an ancient dragon hoards untold riches. Only the worthy survive.",
            theme: .volcano,
            difficulty: .heroic,
            rooms: [
                DungeonRoom(name: "Lava Fields", description: "Molten rivers block the path. Dexterity is tested.", encounterType: .trap, primaryStat: .dexterity, difficultyRating: 32),
                DungeonRoom(name: "Fire Elementals", description: "Creatures of pure flame block your ascent!", encounterType: .combat, primaryStat: .strength, difficultyRating: 35),
                DungeonRoom(name: "The Dragon's Riddle", description: "Ancient draconic runes must be deciphered.", encounterType: .puzzle, primaryStat: .wisdom, difficultyRating: 38),
                DungeonRoom(name: "Wyvern Ambush", description: "Lesser dragons swoop down from above!", encounterType: .combat, primaryStat: .dexterity, difficultyRating: 36),
                DungeonRoom(name: "Dragon's Hoard", description: "Mountains of gold and rare artifacts!", encounterType: .treasure, primaryStat: .luck, difficultyRating: 25, bonusLootChance: 0.7),
                DungeonRoom(name: "Atherion the Ancient", description: "The ancient dragon awakens. The ultimate test of valor!", encounterType: .boss, primaryStat: .dexterity, difficultyRating: 45, isBossRoom: true, bonusLootChance: 0.6)
            ],
            levelRequirement: 25,
            recommendedStatTotal: 100,
            baseExpReward: 2500,
            baseGoldReward: 1500,
            lootTier: 4
        )
    }
    
    static var theAbyss: Dungeon {
        Dungeon(
            name: "The Abyss",
            description: "The deepest, darkest dungeon known to exist. Every stat will be pushed to its absolute limit.",
            theme: .abyss,
            difficulty: .mythic,
            rooms: [
                DungeonRoom(name: "The Void Gate", description: "Reality itself bends as you step through.", encounterType: .puzzle, primaryStat: .wisdom, difficultyRating: 42),
                DungeonRoom(name: "Hall of Shadows", description: "Your shadow detaches and attacks!", encounterType: .combat, primaryStat: .strength, difficultyRating: 45),
                DungeonRoom(name: "Labyrinth of Madness", description: "The walls shift. Trust nothing.", encounterType: .trap, primaryStat: .dexterity, difficultyRating: 44),
                DungeonRoom(name: "The Negotiator", description: "A demon offers a deal. Choose wisely.", encounterType: .puzzle, primaryStat: .charisma, difficultyRating: 46),
                DungeonRoom(name: "Stamina Trial", description: "An endless corridor that saps your will.", encounterType: .trap, primaryStat: .dexterity, difficultyRating: 48),
                DungeonRoom(name: "Fortune's Edge", description: "A chamber of pure chaos. Only luck can save you.", encounterType: .treasure, primaryStat: .luck, difficultyRating: 40, bonusLootChance: 0.8),
                DungeonRoom(name: "The Abyssal Lord", description: "The ruler of the Abyss. Total annihilation or absolute glory.", encounterType: .boss, primaryStat: .strength, difficultyRating: 55, isBossRoom: true, bonusLootChance: 0.75)
            ],
            levelRequirement: 40,
            recommendedStatTotal: 140,
            baseExpReward: 5000,
            baseGoldReward: 3000,
            lootTier: 5
        )
    }
}
