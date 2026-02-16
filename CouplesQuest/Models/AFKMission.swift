import Foundation
import SwiftData

/// An AFK/idle mission that runs in the background
@Model
final class AFKMission {
    /// Unique identifier
    var id: UUID
    
    /// Mission name
    var name: String
    
    /// Mission description/story
    var missionDescription: String
    
    /// Mission type affects rewards and requirements
    var missionType: MissionType
    
    /// Rarity affects rewards
    var rarity: MissionRarity
    
    /// Duration in seconds
    var durationSeconds: Int
    
    /// Minimum stat requirements
    var statRequirements: [StatRequirement]
    
    /// Minimum level required
    var levelRequirement: Int
    
    /// Base success rate (0.0 - 1.0)
    var baseSuccessRate: Double
    
    /// EXP reward on success
    var expReward: Int
    
    /// Gold reward on success
    var goldReward: Int
    
    /// Possible item drops (stored as JSON string for SwiftData compatibility)
    var possibleDropsJSON: String
    
    /// Whether this training can drop equipment on success
    var canDropEquipment: Bool
    
    /// Is this mission currently available?
    var isAvailable: Bool
    
    /// When does this mission expire (rotating missions)
    var expiresAt: Date?
    
    /// Which class line this training is for: "warrior", "mage", "archer", or nil for universal.
    /// Warrior line = Warrior, Berserker, Paladin. Mage line = Mage, Sorcerer, Enchanter. Archer line = Archer, Ranger, Trickster.
    var classRequirement: String?
    
    /// The stat that this training primarily boosts on success
    var trainingStat: String?
    
    /// Whether this is a rank-up training course (class evolution trial)
    var isRankUpTraining: Bool
    
    /// The advanced class this rank-up course unlocks on success (e.g. "Berserker", "Sorcerer")
    var rankUpTargetClass: String?
    
    init(
        name: String,
        description: String,
        missionType: MissionType,
        rarity: MissionRarity,
        durationSeconds: Int,
        statRequirements: [StatRequirement] = [],
        levelRequirement: Int = 1,
        baseSuccessRate: Double = 0.8,
        expReward: Int,
        goldReward: Int,
        possibleDrops: [String] = [],
        canDropEquipment: Bool = false,
        isAvailable: Bool = true,
        expiresAt: Date? = nil,
        classRequirement: String? = nil,
        trainingStat: String? = nil,
        isRankUpTraining: Bool = false,
        rankUpTargetClass: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.missionDescription = description
        self.missionType = missionType
        self.rarity = rarity
        self.durationSeconds = durationSeconds
        self.statRequirements = statRequirements
        self.levelRequirement = levelRequirement
        self.baseSuccessRate = baseSuccessRate
        self.expReward = expReward
        self.goldReward = goldReward
        self.possibleDropsJSON = (try? String(data: JSONEncoder().encode(possibleDrops), encoding: .utf8)) ?? "[]"
        self.canDropEquipment = canDropEquipment
        self.isAvailable = isAvailable
        self.expiresAt = expiresAt
        self.classRequirement = classRequirement
        self.trainingStat = trainingStat
        self.isRankUpTraining = isRankUpTraining
        self.rankUpTargetClass = rankUpTargetClass
    }
    
    /// Decoded possible drops array
    var possibleDrops: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: Data(possibleDropsJSON.utf8))) ?? []
        }
        set {
            possibleDropsJSON = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]"
        }
    }
    
    /// Equipment loot tier based on rarity (used with LootGenerator)
    var dropTier: Int {
        switch rarity {
        case .common: return 1
        case .uncommon: return 1
        case .rare: return 2
        case .epic: return 3
        case .legendary: return 4
        }
    }
    
    /// Chance of gaining +1 to the primary stat on success
    var statRewardChance: Double {
        switch rarity {
        case .common: return 0.50
        case .uncommon: return 0.60
        case .rare: return 0.70
        case .epic: return 0.80
        case .legendary: return 0.90
        }
    }
    
    /// Item drop chance for a given luck value
    func itemDropChance(luck: Int) -> Double {
        guard canDropEquipment else { return 0 }
        return min(0.10 + (Double(luck) * 0.01), 0.50) // cap at 50%
    }
    
    /// HP cost to start this training session (1 HP per minute of duration)
    var hpCost: Int {
        max(10, durationSeconds / 60)
    }
    
    /// Duration formatted as string
    var durationFormatted: String {
        let hours = durationSeconds / 3600
        let minutes = (durationSeconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    /// Calculate actual success rate based on character stats
    func calculateSuccessRate(with stats: Stats) -> Double {
        var rate = baseSuccessRate
        
        // Bonus for exceeding stat requirements
        for requirement in statRequirements {
            let charStat = stats.value(for: requirement.stat)
            let excess = charStat - requirement.minimum
            if excess > 0 {
                rate += Double(excess) * 0.01 // 1% per point above minimum
            }
        }
        
        // Luck bonus
        rate += Double(stats.luck) * 0.005 // 0.5% per luck point
        
        return min(rate, 0.99) // Cap at 99%
    }
    
    /// The StatType this training boosts (derived from trainingStat string)
    var trainingStatType: StatType? {
        guard let raw = trainingStat else { return nil }
        return StatType(rawValue: raw.capitalized) ?? StatType(rawValue: raw)
    }
    
    /// The CharacterClass this rank-up course unlocks (derived from rankUpTargetClass string)
    var targetClass: CharacterClass? {
        guard let raw = rankUpTargetClass else { return nil }
        return CharacterClass(rawValue: raw)
    }
    
    /// Check if character meets requirements (level, stats, and class)
    func meetsRequirements(character: PlayerCharacter) -> Bool {
        // Check level
        if character.level < levelRequirement {
            return false
        }
        
        // Check class requirement
        if let required = classRequirement, let charClass = character.characterClass {
            if charClass.classLine.rawValue != required {
                return false
            }
        }
        
        // Check stats
        let effectiveStats = character.effectiveStats
        for requirement in statRequirements {
            if effectiveStats.value(for: requirement.stat) < requirement.minimum {
                return false
            }
        }
        
        return true
    }
}

// MARK: - Active Mission Tracking

/// Tracks an in-progress AFK mission
@Model
final class ActiveMission: Codable {
    /// Unique identifier
    var id: UUID
    
    /// Reference to the mission template
    var missionID: UUID
    
    /// Character running this mission
    var characterID: UUID
    
    /// When the mission started
    var startedAt: Date
    
    /// When the mission will complete
    var completesAt: Date
    
    /// Type of mission (for thumbnail display)
    var missionType: MissionType?
    
    /// Has the reward been claimed?
    var rewardClaimed: Bool
    
    /// Was the mission successful? (determined at completion)
    var wasSuccessful: Bool?
    
    /// Actual rewards earned
    var earnedEXP: Int?
    var earnedGold: Int?
    var earnedItemID: String?
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id, missionID, characterID, startedAt, completesAt
        case rewardClaimed, wasSuccessful, earnedEXP, earnedGold, earnedItemID
        case missionType
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        missionID = try container.decode(UUID.self, forKey: .missionID)
        characterID = try container.decode(UUID.self, forKey: .characterID)
        missionType = try container.decodeIfPresent(MissionType.self, forKey: .missionType)
        startedAt = try container.decode(Date.self, forKey: .startedAt)
        completesAt = try container.decode(Date.self, forKey: .completesAt)
        rewardClaimed = try container.decode(Bool.self, forKey: .rewardClaimed)
        wasSuccessful = try container.decodeIfPresent(Bool.self, forKey: .wasSuccessful)
        earnedEXP = try container.decodeIfPresent(Int.self, forKey: .earnedEXP)
        earnedGold = try container.decodeIfPresent(Int.self, forKey: .earnedGold)
        earnedItemID = try container.decodeIfPresent(String.self, forKey: .earnedItemID)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(missionID, forKey: .missionID)
        try container.encode(characterID, forKey: .characterID)
        try container.encodeIfPresent(missionType, forKey: .missionType)
        try container.encode(startedAt, forKey: .startedAt)
        try container.encode(completesAt, forKey: .completesAt)
        try container.encode(rewardClaimed, forKey: .rewardClaimed)
        try container.encodeIfPresent(wasSuccessful, forKey: .wasSuccessful)
        try container.encodeIfPresent(earnedEXP, forKey: .earnedEXP)
        try container.encodeIfPresent(earnedGold, forKey: .earnedGold)
        try container.encodeIfPresent(earnedItemID, forKey: .earnedItemID)
    }
    
    // MARK: - Init
    
    init(mission: AFKMission, characterID: UUID) {
        self.id = UUID()
        self.missionID = mission.id
        self.characterID = characterID
        self.missionType = mission.missionType
        self.startedAt = Date()
        self.completesAt = Date().addingTimeInterval(TimeInterval(mission.durationSeconds))
        self.rewardClaimed = false
        self.wasSuccessful = nil
        self.earnedEXP = nil
        self.earnedGold = nil
        self.earnedItemID = nil
    }
    
    /// Is the mission complete?
    var isComplete: Bool {
        Date() >= completesAt
    }
    
    /// Time remaining in seconds
    var timeRemaining: TimeInterval {
        max(0, completesAt.timeIntervalSince(Date()))
    }
    
    /// Progress (0.0 - 1.0)
    var progress: Double {
        let total = completesAt.timeIntervalSince(startedAt)
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
    
    // MARK: - Persistence
    
    private static let storageKey = "ActiveMission_data"
    
    /// Save this active mission to UserDefaults so it survives app restarts.
    func persist() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
    
    /// Load a previously saved active mission from UserDefaults.
    static func loadPersisted() -> ActiveMission? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(ActiveMission.self, from: data)
    }
    
    /// Remove persisted active mission data.
    static func clearPersisted() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}

// MARK: - Supporting Types

/// Mission types
enum MissionType: String, Codable, CaseIterable {
    case combat = "Combat"
    case exploration = "Exploration"
    case research = "Research"
    case negotiation = "Negotiation"
    case stealth = "Stealth"
    case gathering = "Gathering"
    
    var icon: String {
        switch self {
        case .combat: return "sword.2.crossed"
        case .exploration: return "map.fill"
        case .research: return "books.vertical.fill"
        case .negotiation: return "bubble.left.and.bubble.right.fill"
        case .stealth: return "eye.slash.fill"
        case .gathering: return "leaf.fill"
        }
    }
    
    /// AI-generated thumbnail image asset name
    var thumbnailImage: String {
        switch self {
        case .combat: return "mission_combat"
        case .exploration: return "mission_exploration"
        case .research: return "mission_research"
        case .negotiation: return "mission_negotiation"
        case .stealth: return "mission_stealth"
        case .gathering: return "mission_gathering"
        }
    }
    
    /// Primary stat for this mission type
    var primaryStat: StatType {
        switch self {
        case .combat: return .strength
        case .exploration: return .dexterity
        case .research: return .wisdom
        case .negotiation: return .charisma
        case .stealth: return .dexterity
        case .gathering: return .luck
        }
    }
}

/// Mission rarity
enum MissionRarity: String, Codable, CaseIterable {
    case common = "Common"
    case uncommon = "Uncommon"
    case rare = "Rare"
    case epic = "Epic"
    case legendary = "Legendary"
    
    var color: String {
        switch self {
        case .common: return "RarityCommon"
        case .uncommon: return "RarityUncommon"
        case .rare: return "RarityRare"
        case .epic: return "RarityEpic"
        case .legendary: return "RarityLegendary"
        }
    }
    
    /// Reward multiplier
    var rewardMultiplier: Double {
        switch self {
        case .common: return 1.0
        case .uncommon: return 1.5
        case .rare: return 2.0
        case .epic: return 3.0
        case .legendary: return 5.0
        }
    }
    
    /// Numeric order for sorting (lower = easier / earlier in progression)
    var sortOrder: Int {
        switch self {
        case .common: return 0
        case .uncommon: return 1
        case .rare: return 2
        case .epic: return 3
        case .legendary: return 4
        }
    }
}

/// Stat requirement for missions
struct StatRequirement: Codable, Hashable {
    var stat: StatType
    var minimum: Int
}

