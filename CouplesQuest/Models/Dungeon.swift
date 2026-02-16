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
    
    /// Minimum character HP required to enter this dungeon
    var minHPRequired: Int
    
    /// Stat requirements — soft gates that penalise success chance when not met
    var statRequirements: [StatRequirement]
    
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
        isAvailable: Bool = true,
        minHPRequired: Int = 50,
        statRequirements: [StatRequirement] = []
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
        self.minHPRequired = minHPRequired
        self.statRequirements = statRequirements
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
    
    /// HP cost to start this dungeon run (1 HP per minute of duration)
    var hpCost: Int {
        max(10, durationSeconds / 60)
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
    /// Whether this room is a bonus room (rare spawn, better loot)
    var isBonusRoom: Bool
    /// Class gate: only parties with this class line can enter. nil = open to all.
    /// Values: "warrior" (Warrior/Berserker/Paladin), "mage" (Mage/Sorcerer/Enchanter), "archer" (Archer/Ranger/Trickster)
    var classGate: String?
    
    init(
        name: String,
        description: String,
        encounterType: EncounterType,
        primaryStat: StatType,
        difficultyRating: Int,
        isBossRoom: Bool = false,
        bonusLootChance: Double = 0.0,
        isBonusRoom: Bool = false,
        classGate: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.roomDescription = description
        self.encounterType = encounterType
        self.primaryStat = primaryStat
        self.difficultyRating = difficultyRating
        self.isBossRoom = isBossRoom
        self.bonusLootChance = bonusLootChance
        self.isBonusRoom = isBonusRoom
        self.classGate = classGate
    }
    
    /// Check if a party can enter this room (class gate check)
    func canEnter(party: [PlayerCharacter]) -> Bool {
        guard let gate = classGate else { return true }
        return party.contains { member in
            guard let charClass = member.characterClass else { return false }
            switch gate {
            case "warrior":
                return charClass == .warrior || charClass == .berserker || charClass == .paladin
            case "mage":
                return charClass == .mage || charClass == .sorcerer || charClass == .enchanter
            case "archer":
                return charClass == .archer || charClass == .ranger || charClass == .trickster
            default:
                return false
            }
        }
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
    case secretDiscovery = "Secret Discovery"
    case irlTaskHeal = "IRL Task Heal"
    
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
        case .secretDiscovery: return "sparkles"
        case .irlTaskHeal: return "cross.vial.fill"
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
        case .secretDiscovery: return "RarityLegendary"
        case .irlTaskHeal: return "AccentGreen"
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
    var partyMemberClasses: [String]
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
    
    /// Performance rating letter (S/A/B/C/D/F) — set after completion
    var performanceRating: String = ""
    
    /// Performance score (0.0 – 1.0) — set after completion
    var performanceScore: Double = 0.0
    
    init(dungeon: Dungeon, partyMembers: [PlayerCharacter], isCoop: Bool = false) {
        self.id = UUID()
        self.dungeonID = dungeon.id
        self.dungeonName = dungeon.name
        self.partyMemberIDs = partyMembers.map { $0.id }
        self.partyMemberNames = partyMembers.map { $0.name }
        self.partyMemberClasses = partyMembers.map { $0.characterClass?.rawValue ?? "Adventurer" }
        self.currentRoomIndex = 0
        self.roomResults = []
        self.feedEntries = []
        self.status = .inProgress
        self.startedAt = Date()
        self.completedAt = nil
        // Use the lead character's persistent HP instead of flat 100
        let leadHP = partyMembers.first?.currentHP ?? 100
        self.partyHP = leadHP
        self.maxPartyHP = partyMembers.first?.maxHP ?? 100
        self.totalExpEarned = 0
        self.totalGoldEarned = 0
        self.lootEarnedIDs = []
        self.isCoopRun = isCoop
        self.durationSeconds = dungeon.durationSeconds
        self.completesAt = Date().addingTimeInterval(TimeInterval(dungeon.durationSeconds))
        self.isResolved = false
        self.performanceRating = ""
        self.performanceScore = 0.0
        
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
    
    /// Content card ID that dropped from this room (nil if no card dropped)
    var cardDroppedID: String?
    
    /// Card name for display (nil if no card dropped)
    var cardDroppedName: String?
    
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
        approachName: String = "",
        cardDroppedID: String? = nil,
        cardDroppedName: String? = nil
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
        self.cardDroppedID = cardDroppedID
        self.cardDroppedName = cardDroppedName
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
                    primaryStat: .defense,
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
                    icon: "shield.lefthalf.filled",
                    primaryStat: .defense,
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
                    primaryStat: .defense,
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
    
    // MARK: - Class-Line Aware Narratives
    
    /// Get class-line-aware approach-specific success narratives. Falls back to generic if no class line provided.
    func successNarrative(for approach: RoomApproach, classLine: ClassLine?) -> [String] {
        guard let classLine = classLine else { return successNarrative(for: approach) }
        
        switch (self, approach.primaryStat, classLine) {
        // ── Combat + Strength ──
        case (.combat, .strength, .warrior):
            return ["Your relentless training pays off — one mighty swing shatters their guard!", "Years of drills fuel a crushing blow that ends the fight!"]
        case (.combat, .strength, .mage):
            return ["You channel raw arcane force into your strike — the shockwave sends them flying!", "Magical energy amplifies your blow beyond what muscle alone could achieve!"]
        case (.combat, .strength, .archer):
            return ["A powerful draw launches an arrow clean through their armor — your strength is building!", "You wrestle the foe down with surprising force. The training is paying off!"]
            
        // ── Combat + Dexterity ──
        case (.combat, .dexterity, .warrior):
            return ["Battle footwork carries you past their swing — a clean counter follows!", "Your disciplined agility catches them flat-footed!"]
        case (.combat, .dexterity, .mage):
            return ["You weave between attacks with spell-enhanced reflexes!", "A blur of arcane-quickened movement leaves the enemy striking air!"]
        case (.combat, .dexterity, .archer):
            return ["Your quick reflexes are razor-sharp — you dodge and fire in one fluid motion!", "Nimble as the wind, you outpace every swing and land your shots!"]
            
        // ── Combat + Defense ──
        case (.combat, .defense, .warrior):
            return ["Your iron stance holds firm — the enemy wears out against your shield!", "Unyielding toughness built from endurance training outlasts their assault!"]
        case (.combat, .defense, .mage):
            return ["A shimmering ward absorbs every blow — your resilience fuels the barrier!", "Your mental fortitude holds the shield spell steady under heavy fire!"]
        case (.combat, .defense, .archer):
            return ["You hold your ground and weather the storm — toughness you've been building shows!", "Strategic positioning and grit keep you standing when others would fall!"]
            
        // ── Puzzle + Wisdom ──
        case (.puzzle, .wisdom, .warrior):
            return ["Battle strategy translates to puzzle-solving — your tactical mind cracks it!", "Your disciplined focus cuts through the noise and finds the solution!"]
        case (.puzzle, .wisdom, .mage):
            return ["Your hours of study and mental focus illuminate the answer instantly!", "Ancient knowledge flows through you — the puzzle was designed for minds like yours!"]
        case (.puzzle, .wisdom, .archer):
            return ["Patient observation reveals the pattern — your keen analytical eye wins!", "You read the puzzle like you read the wind. Focus and study pay off!"]
            
        // ── Puzzle + Luck ──
        case (.puzzle, .luck, .warrior):
            return ["You punch the mechanism in frustration — it clicks open! Fortune favors the bold!", "A lucky guess guided by warrior's instinct somehow works!"]
        case (.puzzle, .luck, .mage):
            return ["Your wild magical experimentation triggers the right combination!", "Arcane intuition — or sheer luck — guides your hand to the answer!"]
        case (.puzzle, .luck, .archer):
            return ["A coin flip. Heads. The door opens. Sometimes fortune is all you need!", "Your gambler's instinct picks the right path — lucky as always!"]
            
        // ── Puzzle + Charisma ──
        case (.puzzle, .charisma, .warrior):
            return ["You rally the spirits of fallen warriors to reveal the answer!", "Your commanding presence intimidates the puzzle guardian into submission!"]
        case (.puzzle, .charisma, .mage):
            return ["You charm the enchanted sentinel into whispering the solution!", "Your silver tongue and social grace persuade even magical constructs!"]
        case (.puzzle, .charisma, .archer):
            return ["A quick wit and disarming smile convince the guardian to step aside!", "Your way with words finds the loophole — social skills win again!"]
            
        // ── Trap + Dexterity ──
        case (.trap, .dexterity, .warrior):
            return ["Battle-honed reflexes let you sidestep the mechanism just in time!", "Your combat agility serves you well — the trap barely grazes you!"]
        case (.trap, .dexterity, .mage):
            return ["Spell-quickened fingers disarm the mechanism with surgical precision!", "Your practiced hand movements for spellcasting make short work of this trap!"]
        case (.trap, .dexterity, .archer):
            return ["Nimble fingers trained by years of bowstring work disarm it effortlessly!", "Your agility and speed training shines — the trap never had a chance!"]
            
        // ── Trap + Wisdom ──
        case (.trap, .wisdom, .warrior):
            return ["You recognize this trap from battle manuals — a careful detour avoids it!", "Tactical awareness guides you around the danger zone!"]
        case (.trap, .wisdom, .mage):
            return ["Your study of ancient mechanisms reveals the hidden safe path!", "Knowledge of arcane wards lets you sense and avoid the trigger!"]
        case (.trap, .wisdom, .archer):
            return ["You spot the telltale signs from your wilderness training — easy bypass!", "Your keen observational skills catch what others would miss!"]
            
        // ── Trap + Defense ──
        case (.trap, .defense, .warrior):
            return ["You brace behind your shield — the trap bounces off your resilience!", "Built tough from endurance training, you shrug off the impact!"]
        case (.trap, .defense, .mage):
            return ["A quick barrier spell absorbs the trap's force — your resilience holds!", "Your mental toughness powers a ward that takes the hit for you!"]
        case (.trap, .defense, .archer):
            return ["You tuck and roll through the trap — your conditioning absorbs the blow!", "Gritting through the impact, your built-up toughness saves the day!"]
            
        // ── Boss + Strength ──
        case (.boss, .strength, .warrior):
            return ["Your training culminates in a devastating blow — the boss crumbles!", "Raw power forged through discipline topples the mighty foe!"]
        case (.boss, .strength, .mage):
            return ["You pour every ounce of arcane force into one cataclysmic blast!", "Magical might amplified by growing strength overwhelms the boss!"]
        case (.boss, .strength, .archer):
            return ["Every arrow hits with bone-shattering force — the boss staggers and falls!", "Your growing power drives an arrow straight through the boss's defenses!"]
            
        // ── Boss + Defense ──
        case (.boss, .defense, .warrior):
            return ["An unbreakable wall of endurance — the boss tires before you do!", "Your shield never wavers. Patience and resilience win the war of attrition!"]
        case (.boss, .defense, .mage):
            return ["Layer upon layer of wards absorb every boss attack — you outlast the onslaught!", "Your mental resilience powers shields that never crack!"]
        case (.boss, .defense, .archer):
            return ["Dodging and enduring, you weather the storm until the opening comes!", "Built-up toughness keeps you standing through punishment that would fell others!"]
            
        // ── Boss + Wisdom ──
        case (.boss, .wisdom, .warrior):
            return ["You study the boss mid-fight and exploit a gap in its stance!", "Tactical awareness learned from study reveals the critical weakness!"]
        case (.boss, .wisdom, .mage):
            return ["Deep arcane knowledge exposes the boss's vulnerability — a surgical strike!", "Your dedication to learning uncovers the flaw that ends the fight!"]
        case (.boss, .wisdom, .archer):
            return ["Patient observation reveals the pattern — one perfectly timed shot ends it!", "You read the boss's movements like a book. Knowledge is the ultimate weapon!"]
            
        default:
            return successNarratives(for: classLine)
        }
    }
    
    /// Get class-line-aware approach-specific failure narratives. Falls back to generic if no class line provided.
    func failureNarrative(for approach: RoomApproach, classLine: ClassLine?) -> [String] {
        guard let classLine = classLine else { return failureNarrative(for: approach) }
        
        switch (self, approach.primaryStat, classLine) {
        // ── Combat + Strength ──
        case (.combat, .strength, .warrior):
            return ["Your strike lacks the force to break through. More physical training would change this.", "The blow glances off — your strength isn't quite there yet."]
        case (.combat, .strength, .mage):
            return ["Your arcane blast fizzles against their armor. Building raw power could tip the balance.", "Magical force alone isn't enough here — more physical strength would help."]
        case (.combat, .strength, .archer):
            return ["The arrow bounces off harmlessly — more power behind the draw would help next time.", "Not enough force to penetrate. Strength training would make the difference."]
            
        // ── Combat + Dexterity ──
        case (.combat, .dexterity, .warrior):
            return ["Too slow in your armor — they read your move. Working on agility could help.", "Your footwork betrays you. More movement training would sharpen those reflexes."]
        case (.combat, .dexterity, .mage):
            return ["Your spell-quick dodge isn't fast enough — they clip you hard. More agility training needed.", "The arcane boost to your speed falls short. Building natural quickness would help."]
        case (.combat, .dexterity, .archer):
            return ["They anticipate your dodge — not quick enough this time. Keep training that agility!", "Your reflexes aren't quite sharp enough. More cardio and movement work would help."]
            
        // ── Combat + Defense ──
        case (.combat, .defense, .warrior):
            return ["They break through your guard — more endurance training would shore up your defense.", "Your stance crumbles under pressure. Building resilience could make you unbreakable."]
        case (.combat, .defense, .mage):
            return ["Your ward shatters under the assault. Fortifying your resilience would strengthen it.", "The shield spell fails — more mental and physical toughness would hold it together."]
        case (.combat, .defense, .archer):
            return ["You can't weather the onslaught. Building up your toughness would make a difference.", "Not tough enough to tank through. Working on your resilience would help."]
            
        // ── Puzzle + Wisdom ──
        case (.puzzle, .wisdom, .warrior):
            return ["The runes mean nothing to you. Sharpening your mind with study could unlock these secrets.", "Brute force can't solve this. More mental focus and learning would open this door."]
        case (.puzzle, .wisdom, .mage):
            return ["Even your arcane knowledge falls short here. Deeper focus and learning would serve you well.", "The puzzle outsmarts you — more study and mental training would bridge the gap."]
        case (.puzzle, .wisdom, .archer):
            return ["The puzzle's logic escapes you. Some time with books might sharpen more than your aim.", "This challenge needs brains, not arrows. Building your knowledge would help."]
            
        // ── Puzzle + Luck ──
        case (.puzzle, .luck, .warrior):
            return ["Your warrior's gamble doesn't pay off this time. Luck wasn't on your side.", "A bold guess falls flat — fortune favors the prepared, not just the brave."]
        case (.puzzle, .luck, .mage):
            return ["Your arcane intuition misfires — the backlash stings. Luck wasn't with you.", "Even magical intuition can't always beat pure chance. Not your lucky day."]
        case (.puzzle, .luck, .archer):
            return ["The coin lands wrong — your gambler's instinct fails this time.", "Bad luck. Sometimes the odds just aren't in your favor."]
            
        // ── Puzzle + Charisma ──
        case (.puzzle, .charisma, .warrior):
            return ["Your commanding tone falls flat — the guardian is unimpressed. Building connections would help.", "Intimidation doesn't work on enchanted constructs. More social skill would help."]
        case (.puzzle, .charisma, .mage):
            return ["Your persuasion lacks conviction. Stronger social bonds could sharpen your silver tongue.", "The charm falls short — building your interpersonal skills would make a difference."]
        case (.puzzle, .charisma, .archer):
            return ["Your wit isn't sharp enough to talk your way through. More social practice would help.", "The guardian sees through your bluff. Strengthening your social skills would help."]
            
        // ── Trap + Dexterity ──
        case (.trap, .dexterity, .warrior):
            return ["Too bulky to dodge in time — more agility training would make you faster.", "Your hands fumble the mechanism. Working on speed and precision would help."]
        case (.trap, .dexterity, .mage):
            return ["Your spell-quickened reflexes aren't fast enough. More movement training needed.", "Fingers too slow on the mechanism. Building natural agility would help."]
        case (.trap, .dexterity, .archer):
            return ["Not quick enough — the trap catches you. Keep working on those reflexes!", "Your speed falls just short. More agility and cardio work would sharpen your edge."]
            
        // ── Trap + Wisdom ──
        case (.trap, .wisdom, .warrior):
            return ["You walk straight into the trap — more study of dungeon lore would help you spot these.", "The hidden danger catches you off guard. Building knowledge would prevent this."]
        case (.trap, .wisdom, .mage):
            return ["Your alternate route was a dead end. Deeper study of these mechanisms is needed.", "The trap's design outwits you — more research and focus would help."]
        case (.trap, .wisdom, .archer):
            return ["You miss the warning signs. Sharpening your analytical mind would catch these traps.", "The telltale signs escaped you. More study and observation practice would help."]
            
        // ── Trap + Defense ──
        case (.trap, .defense, .warrior):
            return ["The trap hits harder than your guard can handle. More endurance training would toughen you.", "Even bracing isn't enough — building more resilience could absorb this."]
        case (.trap, .defense, .mage):
            return ["Your ward crumbles under the trap's force. Fortifying your toughness would strengthen it.", "The barrier isn't strong enough. More resilience training would shore up your defenses."]
        case (.trap, .defense, .archer):
            return ["The impact is too much to shrug off. Building toughness would help you tank through.", "Not resilient enough to absorb this. Working on your endurance would make a difference."]
            
        // ── Boss + Strength ──
        case (.boss, .strength, .warrior):
            return ["Your assault overextends you — the boss is too strong. More physical training would close the gap.", "Not enough power to bring down a foe this mighty. Keep building that strength."]
        case (.boss, .strength, .mage):
            return ["Your arcane blast barely scratches the boss. Raw power needs building.", "The magical strike isn't enough — more force is needed. Strength training would help."]
        case (.boss, .strength, .archer):
            return ["Your arrows lack the punch to pierce the boss's hide. More strength behind the draw needed.", "Not enough power in your shots. Building physical strength could change this fight."]
            
        // ── Boss + Defense ──
        case (.boss, .defense, .warrior):
            return ["The boss wears down your shield over time. More resilience training would let you hold.", "Your endurance fails before the boss does. Building toughness is the answer."]
        case (.boss, .defense, .mage):
            return ["Ward after ward crumbles. Your mental resilience needs strengthening for fights like this.", "The boss overwhelms your barriers. More endurance and toughness would sustain them."]
        case (.boss, .defense, .archer):
            return ["You can't outlast the boss's assault. Building resilience would let you survive longer.", "The punishment is too much. Working on toughness and endurance would make a difference."]
            
        // ── Boss + Wisdom ──
        case (.boss, .wisdom, .warrior):
            return ["You can't find the weakness — more study and focus would reveal it.", "The boss's pattern eludes you. Sharpening your mind could expose the vulnerability."]
        case (.boss, .wisdom, .mage):
            return ["Even your arcane insight can't crack this one. Deeper knowledge is needed.", "The boss's defenses are beyond your current understanding. More learning would help."]
        case (.boss, .wisdom, .archer):
            return ["You can't read the boss's movements in time. More patience and study would reveal the pattern.", "The opening never comes because you can't see it. Building focus and knowledge would help."]
            
        default:
            return failureNarratives(for: classLine)
        }
    }
    
    // MARK: - Legacy Narrative Methods (Fallback)
    
    /// Get approach-specific success narratives (no class awareness — used as fallback)
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
        case (.combat, .defense):
            return ["Your iron defense outlasts the enemy — they crumble from exhaustion!", "You hold the line and wear them down!"]
        case (.trap, .defense):
            return ["You brace yourself and push through! Barely a scratch.", "Your toughness absorbs the brunt of the trap!"]
        case (.boss, .defense):
            return ["A war of attrition — you stand when the boss falls!", "Patience and grit win the day!"]
        case (.boss, .wisdom):
            return ["You exploit a critical weakness — the boss staggers!", "Knowledge is power — a surgical strike ends it!"]
        default:
            return successNarratives
        }
    }
    
    /// Get approach-specific failure narratives (no class awareness — used as fallback)
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
        case (.combat, .defense):
            return ["Your defense holds, but not well enough — they break through!", "You're overwhelmed despite digging in!"]
        case (.trap, .defense):
            return ["The trap hits harder than expected — your guard buckles!", "Even bracing wasn't enough for this one!"]
        case (.boss, .defense):
            return ["The boss wears down your defenses over time!", "Your endurance fails before the boss does!"]
        case (.boss, .strength):
            return ["Your all-out attack overextends you!", "The boss punishes your recklessness!"]
        default:
            return failureNarratives
        }
    }
    
    // MARK: - Class-Line Generic Narratives
    
    /// Class-line-aware generic success narratives (when no approach is specified)
    func successNarratives(for classLine: ClassLine?) -> [String] {
        guard let classLine = classLine else { return successNarratives }
        switch (self, classLine) {
        case (.combat, .warrior):
            return ["Your martial discipline carries the day — steel meets flesh and you prevail!", "A warrior's instinct guides every strike. The enemy never stood a chance."]
        case (.combat, .mage):
            return ["Arcane bolts tear through the opposition — your magical power is growing!", "Spells fly faster than swords. Your studies have made you formidable in combat."]
        case (.combat, .archer):
            return ["A volley of perfectly placed arrows ends the fight before it truly begins!", "Speed and precision — the hallmarks of your training — win the day."]
        case (.puzzle, .warrior):
            return ["Battle strategy translates surprisingly well to riddles. Your mind is sharper than you think!", "Discipline and focus crack the code — a warrior's patience prevails."]
        case (.puzzle, .mage):
            return ["Ancient knowledge flows through you. This puzzle was made for minds like yours!", "Your dedication to learning makes quick work of the challenge."]
        case (.puzzle, .archer):
            return ["Keen observation spots what others miss — the answer was there all along!", "Patience and a sharp eye solve what brute force never could."]
        case (.trap, .warrior):
            return ["Combat reflexes kick in — you react just in time!", "A soldier's awareness keeps you one step ahead of danger."]
        case (.trap, .mage):
            return ["Arcane senses tingle a warning — you avoid the trap with magical precision!", "Your trained awareness of magical energies reveals the hidden mechanism."]
        case (.trap, .archer):
            return ["You spot the trap from a mile away — nothing escapes those keen eyes!", "Quick reflexes and sharp instincts — the trap never had a chance."]
        case (.treasure, .warrior):
            return ["Your instincts lead you to a warrior's bounty — treasure well earned!", "A soldier's nose for loot uncovers riches hidden from lesser eyes."]
        case (.treasure, .mage):
            return ["Magical senses guide you to the cache — knowledge leads to treasure!", "Your arcane attunement reveals riches invisible to mundane eyes."]
        case (.treasure, .archer):
            return ["Sharp eyes catch the glint of gold — fortune favors the observant!", "You spot the hidden cache instantly. Nothing escapes your gaze."]
        case (.boss, .warrior):
            return ["A warrior born and bred — the boss falls to your martial might!", "Discipline, strength, and grit. The boss never stood a chance against a true warrior."]
        case (.boss, .mage):
            return ["Arcane devastation! The boss crumbles under your magical onslaught!", "Your growing magical power proves too much for even the dungeon's master."]
        case (.boss, .archer):
            return ["A final, perfectly placed shot brings the boss down!", "Speed, precision, and cunning — the boss falls to your relentless accuracy."]
        }
    }
    
    /// Class-line-aware generic failure narratives (when no approach is specified)
    func failureNarratives(for classLine: ClassLine?) -> [String] {
        guard let classLine = classLine else { return failureNarratives }
        switch (self, classLine) {
        case (.combat, .warrior):
            return ["The enemy overwhelms your guard. More combat training would shore up your technique.", "Your martial skill isn't quite enough. Keep pushing your physical limits."]
        case (.combat, .mage):
            return ["Your spells lack the force needed. Deeper study and practice would strengthen them.", "The arcane arts demand more focus. Building your knowledge would turn this around."]
        case (.combat, .archer):
            return ["Your shots miss the mark under pressure. More practice with speed and precision would help.", "Not quick or accurate enough this time. Keep honing those reflexes."]
        case (.puzzle, .warrior):
            return ["The puzzle defeats brawn. Sharpening your mind could reveal what strength cannot.", "This challenge needs more than muscle. Building your knowledge would open this door."]
        case (.puzzle, .mage):
            return ["Even your arcane mind struggles here. More study and focus would bridge the gap.", "The riddle remains unsolved. Deeper learning would give you the edge next time."]
        case (.puzzle, .archer):
            return ["The answer eludes your keen eye. More mental training would sharpen your analytical skills.", "Observation alone isn't enough here. Building wisdom and focus would help."]
        case (.trap, .warrior):
            return ["The trap catches you despite your reflexes. More agility training would make you faster.", "Too slow to dodge. Working on speed and movement would help avoid these."]
        case (.trap, .mage):
            return ["Your arcane senses miss the trap. Sharpening your awareness would catch these dangers.", "The mechanism triggers before you can react. More focus and study would help."]
        case (.trap, .archer):
            return ["Even your sharp eyes miss this one. More training would catch what slipped through.", "The trap catches you — keep working on your reflexes and awareness."]
        case (.treasure, .warrior):
            return ["The treasure was a trap! Your guard wasn't up. Stay resilient.", "A mimic! Your defenses need work to handle surprises like this."]
        case (.treasure, .mage):
            return ["A magical ward bites back. More arcane knowledge would have detected it.", "The treasure fights back. Deeper study would reveal these wards."]
        case (.treasure, .archer):
            return ["A hidden guardian strikes! Sharper eyes would have spotted the danger.", "The treasure was guarded. More careful observation would prevent this."]
        case (.boss, .warrior):
            return ["The boss overpowers you. More strength and resilience training would close the gap.", "Your martial skills aren't enough yet. Keep building your combat prowess."]
        case (.boss, .mage):
            return ["The boss shrugs off your spells. More magical study and power is needed.", "Your arcane arsenal falls short. Deeper knowledge and focus would make the difference."]
        case (.boss, .archer):
            return ["The boss is too tough for your arrows. Building power and precision would change this fight.", "Speed alone can't win here. Keep training to find the boss's weakness."]
        }
    }
    
    // MARK: - Non-Class Generic Narratives (Original)
    
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
    
    // MARK: - Party-Aware Narratives
    
    /// Generate a narrative line that weaves a party member into the story.
    /// Returns nil if no suitable template exists, allowing the caller to fall back to solo narrative.
    func partyNarrative(
        success: Bool,
        approach: RoomApproach?,
        leadClassLine: ClassLine?,
        allyName: String,
        allyClassLine: ClassLine?
    ) -> String? {
        let allyTitle: String = {
            switch allyClassLine {
            case .warrior: return "\(allyName) the Warrior"
            case .mage: return "\(allyName) the Mage"
            case .archer: return "\(allyName) the Archer"
            case nil: return allyName
            }
        }()
        
        if success {
            return partySuccessNarrative(allyName: allyName, allyTitle: allyTitle, allyClassLine: allyClassLine, approach: approach)
        } else {
            return partyFailureNarrative(allyName: allyName, allyTitle: allyTitle, allyClassLine: allyClassLine, approach: approach)
        }
    }
    
    private func partySuccessNarrative(allyName: String, allyTitle: String, allyClassLine: ClassLine?, approach: RoomApproach?) -> String? {
        let templates: [String]
        
        switch (self, allyClassLine) {
        // ── Combat ──
        case (.combat, .warrior):
            templates = [
                "\(allyTitle) charges in beside you — together you overwhelm the enemy!",
                "Your strike opens a gap and \(allyName) drives through it with a devastating follow-up!",
                "\(allyName) draws their attention with a battle cry while you land the finishing blow!",
                "Back to back with \(allyName), you cut through the opposition like a well-oiled machine!",
                "\(allyName) shields you from a counter-attack, giving you the opening you needed!",
            ]
        case (.combat, .mage):
            templates = [
                "\(allyTitle) unleashes a blast of arcane energy while you close the distance — a perfect combo!",
                "\(allyName)'s barrier absorbs the counter-strike, keeping you safe to press the attack!",
                "A burst of magical fire from \(allyName) scatters the enemy formation — you mop up the rest!",
                "\(allyName) enchants your weapon mid-swing — the amplified strike shatters their defenses!",
                "Your assault falters for a moment, but \(allyName)'s spell turns the tide!",
            ]
        case (.combat, .archer):
            templates = [
                "\(allyTitle) pins the enemy with covering fire while you move in for the kill!",
                "An arrow from \(allyName) takes out the flanker you didn't see coming!",
                "\(allyName)'s precise shots keep the enemy pinned — you finish the job up close!",
                "You draw their attention and \(allyName) picks them off from the shadows!",
                "\(allyName) calls out the weak point — your strike lands exactly where it counts!",
            ]
        case (.combat, nil):
            templates = [
                "\(allyName) rushes in alongside you — the combined assault overwhelms the enemy!",
                "With \(allyName) at your side, the fight is over before it truly begins!",
                "\(allyName) covers your blind spot just when you need it most!",
            ]
            
        // ── Puzzle ──
        case (.puzzle, .warrior):
            templates = [
                "\(allyName) notices a structural weakness in the mechanism — brute force meets brains!",
                "While you study the runes, \(allyName) keeps watch and spots a hidden clue on the wall!",
                "\(allyName) accidentally leans on the right pressure plate. Sometimes muscle is the answer!",
            ]
        case (.puzzle, .mage):
            templates = [
                "\(allyTitle) recognizes the arcane script — together you piece the answer together!",
                "\(allyName) senses the magical frequency of the lock and guides your hand to the solution!",
                "Your hunch and \(allyName)'s knowledge combine to crack the puzzle in record time!",
                "\(allyName) translates the ancient text while you work the mechanism — perfect teamwork!",
            ]
        case (.puzzle, .archer):
            templates = [
                "\(allyName) spots a pattern you missed from across the room — keen eyes save the day!",
                "\(allyTitle) notices the hidden sequence carved into the ceiling — you'd never have looked up!",
                "\(allyName) points out the odd tile and you both work the solution together!",
            ]
        case (.puzzle, nil):
            templates = [
                "\(allyName) points out a detail you missed — together you crack the puzzle!",
                "Two minds are better than one — \(allyName) fills in the gap you couldn't see!",
            ]
            
        // ── Trap ──
        case (.trap, .warrior):
            templates = [
                "\(allyName) yanks you back just as the trap fires — those reflexes are no joke!",
                "\(allyTitle) throws up a shield and absorbs the worst of it for you!",
                "\(allyName) smashes the trigger mechanism before it fully activates!",
            ]
        case (.trap, .mage):
            templates = [
                "\(allyTitle) senses the magical tripwire and throws up a ward — crisis averted!",
                "\(allyName) dispels the enchantment on the trap before it can spring!",
                "A quick barrier from \(allyName) catches the projectile that would've hit you!",
            ]
        case (.trap, .archer):
            templates = [
                "\(allyTitle) spots the nearly-invisible wire and calls out a warning just in time!",
                "\(allyName) shoots the trigger mechanism from across the room — disarmed from a distance!",
                "\(allyName) grabs your arm and pulls you onto the safe path — those eyes miss nothing!",
            ]
        case (.trap, nil):
            templates = [
                "\(allyName) spots the danger and pulls you clear just in time!",
                "Thanks to \(allyName)'s quick warning, you sidestep the trap entirely!",
            ]
            
        // ── Boss ──
        case (.boss, .warrior):
            templates = [
                "\(allyTitle) draws the boss's fury while you strike from behind — a devastating combo!",
                "You and \(allyName) trade off tanking the boss's attacks — together you outlast it!",
                "\(allyName) locks blades with the boss and creates the opening for your finishing blow!",
                "The boss staggers from \(allyName)'s relentless assault — you deliver the final strike!",
            ]
        case (.boss, .mage):
            templates = [
                "\(allyTitle) channels a massive spell while you keep the boss distracted — it crumbles!",
                "\(allyName)'s enchantments strengthen your weapon just when you need it most — the boss falls!",
                "A combined assault — your steel and \(allyName)'s arcane power — topples the dungeon master!",
                "\(allyName) reveals the boss's magical weakness and you exploit it without mercy!",
            ]
        case (.boss, .archer):
            templates = [
                "\(allyTitle) lands a critical shot on the boss's weak point — you capitalize and finish it!",
                "A relentless barrage from \(allyName) keeps the boss off-balance while you close in!",
                "The boss turns toward \(allyName), and you seize the moment for a devastating backstrike!",
                "\(allyName)'s arrows pin the boss in place — your final blow ends the fight!",
            ]
        case (.boss, nil):
            templates = [
                "Together with \(allyName), you overwhelm the dungeon boss with a coordinated assault!",
                "\(allyName) creates the opening you need — the boss falls to your combined might!",
            ]
            
        // ── Treasure ──
        case (.treasure, _):
            templates = [
                "\(allyName) spots the glint of gold before you do — you split the haul!",
                "You and \(allyName) uncover a hidden cache together — more loot for everyone!",
                "\(allyName) keeps watch while you crack the treasure chest — a smooth operation!",
            ]
        }
        
        return templates.randomElement()
    }
    
    private func partyFailureNarrative(allyName: String, allyTitle: String, allyClassLine: ClassLine?, approach: RoomApproach?) -> String? {
        let templates: [String]
        
        switch (self, allyClassLine) {
        // ── Combat ──
        case (.combat, .warrior):
            templates = [
                "Even with \(allyName) fighting alongside you, the enemy overwhelms your position.",
                "\(allyName) tries to shield you, but the assault breaks through both your guards.",
                "You and \(allyName) are pushed back — more strength training would change this outcome.",
            ]
        case (.combat, .mage):
            templates = [
                "\(allyName)'s barrier flickers and fails under the onslaught — you're both caught in the blast.",
                "Even \(allyName)'s spells aren't enough this time — the enemy shrugs off the magic and hits hard.",
                "\(allyName) tries to enchant your weapon but the enemy strikes before the spell completes.",
            ]
        case (.combat, .archer):
            templates = [
                "\(allyName)'s arrows bounce off the enemy's armor — you're both in trouble.",
                "\(allyName) tries to provide cover fire, but the enemy closes the distance too fast.",
                "You and \(allyName) get separated in the chaos — divided, you fall.",
            ]
        case (.combat, nil):
            templates = [
                "Even fighting together, you and \(allyName) can't break through.",
                "\(allyName) fights bravely at your side, but the enemy is too strong this time.",
            ]
            
        // ── Puzzle ──
        case (.puzzle, _):
            templates = [
                "You and \(allyName) stare at the puzzle, equally stumped. Two confused heads aren't better than one.",
                "\(allyName) suggests a solution — it triggers the penalty instead. Back to the drawing board.",
                "Between the two of you, nobody can crack this one. The mechanism punishes your failed attempt.",
            ]
            
        // ── Trap ──
        case (.trap, .warrior):
            templates = [
                "\(allyName) tries to block the trap but it catches you both off guard.",
                "\(allyName) pushes you aside but takes the hit instead — the trap was a two-parter.",
            ]
        case (.trap, .mage):
            templates = [
                "\(allyName)'s ward shatters under the trap's force — you both feel the impact.",
                "The trap overwhelms \(allyName)'s dispel attempt and fires anyway.",
            ]
        case (.trap, .archer):
            templates = [
                "\(allyName) spots it too late — the trap catches you both mid-stride.",
                "Even \(allyName)'s sharp eyes couldn't detect this one in time.",
            ]
        case (.trap, nil):
            templates = [
                "\(allyName) shouts a warning but it's too late — the trap springs on both of you.",
                "Neither you nor \(allyName) saw it coming. The trap catches you both.",
            ]
            
        // ── Boss ──
        case (.boss, .warrior):
            templates = [
                "The boss swats \(allyName) aside and turns on you — its power is overwhelming.",
                "\(allyName) holds the line as long as possible, but the boss is simply too strong.",
                "You and \(allyName) coordinate your attack, but the boss punishes every opening.",
            ]
        case (.boss, .mage):
            templates = [
                "\(allyName) pours everything into a massive spell, but the boss absorbs it and counters.",
                "The boss shatters \(allyName)'s barriers like glass and catches you both exposed.",
                "\(allyName)'s enchantments fade under the boss's anti-magic aura.",
            ]
        case (.boss, .archer):
            templates = [
                "\(allyName)'s arrows find their mark but the boss barely flinches — it's too powerful.",
                "The boss corners \(allyName) and forces you to choose between helping and attacking.",
                "\(allyName) tries to kite the boss but it closes the distance impossibly fast.",
            ]
        case (.boss, nil):
            templates = [
                "The boss overpowers both you and \(allyName). You'll need to come back stronger.",
                "Even together, you and \(allyName) can't match the boss's devastating power.",
            ]
            
        // ── Treasure ──
        case (.treasure, _):
            templates = [
                "You and \(allyName) trigger the guardian together — it attacks you both.",
                "The chest was a trap and \(allyName)'s attempt to grab the loot makes it worse.",
            ]
        }
        
        return templates.randomElement()
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
    
    /// Maximum per-room equipment drop chance for this difficulty tier
    var dropChanceCap: Double {
        switch self {
        case .normal: return 0.40
        case .hard: return 0.55
        case .heroic: return 0.70
        case .mythic: return 0.80
        }
    }
    
    /// Damage multiplier applied on failed rooms — higher tiers hit MUCH harder
    var damageMultiplier: Double {
        switch self {
        case .normal: return 1.0
        case .hard: return 1.5
        case .heroic: return 2.5
        case .mythic: return 4.0
        }
    }
    
    /// Minimum success chance floor — even underpowered parties have a slim chance
    var successFloor: Double {
        switch self {
        case .normal: return 0.25
        case .hard: return 0.15
        case .heroic: return 0.10
        case .mythic: return 0.05
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
    
    /// Asset name for the dungeon thumbnail image
    var thumbnailImage: String {
        switch self {
        case .cave: return "dungeon_cave"
        case .ruins: return "dungeon_ruins"
        case .forest: return "dungeon_forest"
        case .fortress: return "dungeon_fortress"
        case .volcano: return "dungeon_volcano"
        case .abyss: return "dungeon_abyss"
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
            lootTier: 1,
            minHPRequired: 50,
            statRequirements: [
                StatRequirement(stat: .strength, minimum: 5),
                StatRequirement(stat: .dexterity, minimum: 3)
            ]
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
            baseExpReward: 300,
            baseGoldReward: 175,
            lootTier: 2,
            minHPRequired: 75,
            statRequirements: [
                StatRequirement(stat: .wisdom, minimum: 8),
                StatRequirement(stat: .strength, minimum: 6)
            ]
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
            baseExpReward: 500,
            baseGoldReward: 300,
            lootTier: 3,
            minHPRequired: 150,
            statRequirements: [
                StatRequirement(stat: .dexterity, minimum: 12),
                StatRequirement(stat: .wisdom, minimum: 8),
                StatRequirement(stat: .charisma, minimum: 6)
            ]
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
            baseExpReward: 700,
            baseGoldReward: 425,
            lootTier: 3,
            minHPRequired: 200,
            statRequirements: [
                StatRequirement(stat: .strength, minimum: 15),
                StatRequirement(stat: .wisdom, minimum: 10),
                StatRequirement(stat: .dexterity, minimum: 10)
            ]
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
            baseExpReward: 1400,
            baseGoldReward: 850,
            lootTier: 4,
            minHPRequired: 350,
            statRequirements: [
                StatRequirement(stat: .dexterity, minimum: 18),
                StatRequirement(stat: .strength, minimum: 15),
                StatRequirement(stat: .wisdom, minimum: 12)
            ]
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
            baseExpReward: 2800,
            baseGoldReward: 1700,
            lootTier: 5,
            minHPRequired: 500,
            statRequirements: [
                StatRequirement(stat: .strength, minimum: 22),
                StatRequirement(stat: .wisdom, minimum: 20),
                StatRequirement(stat: .dexterity, minimum: 18),
                StatRequirement(stat: .charisma, minimum: 15),
                StatRequirement(stat: .luck, minimum: 12),
                StatRequirement(stat: .defense, minimum: 15)
            ]
        )
    }
}
