import Foundation
import SwiftData

/// Tracks the bond between two partnered characters
@Model
final class Bond {
    /// Unique identifier
    var id: UUID
    
    /// Partner's character ID
    var partnerID: UUID
    
    /// Current bond level (1-50)
    var bondLevel: Int
    
    /// Current bond EXP
    var bondEXP: Int
    
    /// Total bond EXP ever earned
    var totalBondEXP: Int
    
    /// Tasks completed that were assigned by partner
    var partnerTasksCompleted: Int
    
    /// Duty board tasks claimed
    var dutyBoardTasksClaimed: Int
    
    /// Co-op dungeons completed together
    var coopDungeonsCompleted: Int
    
    /// Days both partners had active streaks
    var dualStreakDays: Int
    
    /// Kudos sent to partner
    var kudosSent: Int
    
    /// Nudges sent to partner
    var nudgesSent: Int
    
    /// When the bond was created
    var createdAt: Date
    
    /// Last bond interaction
    var lastInteractionAt: Date
    
    init(partnerID: UUID) {
        self.id = UUID()
        self.partnerID = partnerID
        self.bondLevel = 1
        self.bondEXP = 0
        self.totalBondEXP = 0
        self.partnerTasksCompleted = 0
        self.dutyBoardTasksClaimed = 0
        self.coopDungeonsCompleted = 0
        self.dualStreakDays = 0
        self.kudosSent = 0
        self.nudgesSent = 0
        self.createdAt = Date()
        self.lastInteractionAt = Date()
    }
    
    // MARK: - Bond Level Calculations
    
    /// EXP required to reach a specific bond level
    static func expRequired(forLevel level: Int) -> Int {
        guard level > 1 else { return 0 }
        return Int(50 * pow(Double(level - 1), 1.3))
    }
    
    /// EXP needed for next level
    var expToNextLevel: Int {
        Bond.expRequired(forLevel: bondLevel + 1)
    }
    
    /// Progress to next bond level (0.0 - 1.0)
    var levelProgress: Double {
        let currentLevelExp = Bond.expRequired(forLevel: bondLevel)
        let nextLevelExp = Bond.expRequired(forLevel: bondLevel + 1)
        let expIntoLevel = bondEXP - currentLevelExp
        let expNeeded = nextLevelExp - currentLevelExp
        guard expNeeded > 0 else { return 0 }
        return min(1.0, max(0.0, Double(expIntoLevel) / Double(expNeeded)))
    }
    
    /// Title based on bond level
    var bondTitle: String {
        switch bondLevel {
        case 1...4: return "Acquaintances"
        case 5...9: return "Companions"
        case 10...14: return "Trusted Allies"
        case 15...19: return "Battle Partners"
        case 20...29: return "Soulbound"
        case 30...39: return "Dynamic Duo"
        case 40...49: return "Power Couple"
        case 50: return "Legendary Bond"
        default: return "Acquaintances"
        }
    }
    
    // MARK: - Bond Perks
    
    /// Perks unlocked at current bond level
    var unlockedPerks: [BondPerk] {
        BondPerk.allCases.filter { $0.requiredLevel <= bondLevel }
    }
    
    /// Next perk to unlock
    var nextPerk: BondPerk? {
        BondPerk.allCases.first { $0.requiredLevel > bondLevel }
    }
    
    // MARK: - Methods
    
    /// Add bond EXP and handle level ups. Returns true if leveled up.
    @discardableResult
    func gainBondEXP(_ amount: Int) -> Bool {
        bondEXP += amount
        totalBondEXP += amount
        lastInteractionAt = Date()
        
        var didLevelUp = false
        while bondEXP >= expToNextLevel && bondLevel < 50 {
            bondLevel += 1
            didLevelUp = true
        }
        return didLevelUp
    }
}

// MARK: - Bond Perks

/// Perks unlocked at specific bond levels
enum BondPerk: String, CaseIterable, Codable {
    case sharedDutyBoard = "Shared Duty Board"
    case taskAssignment = "Task Assignment"
    case quickLearner = "Quick Learner"
    case bondEXPBoost = "Bond EXP Boost"
    case fortuneSeeker = "Fortune Seeker"
    case dualStreakBonus = "Dual Streak Bonus"
    case relentless = "Relentless"
    case coopDungeons = "Co-op Dungeons"
    case sharedLoot = "Shared Loot Pool"
    case couplesAchievements = "Couples Achievements"
    case legendaryBond = "Legendary Bond"
    
    var requiredLevel: Int {
        switch self {
        case .sharedDutyBoard: return 1
        case .taskAssignment: return 2
        case .quickLearner: return 3
        case .bondEXPBoost: return 5
        case .fortuneSeeker: return 7
        case .dualStreakBonus: return 10
        case .relentless: return 12
        case .coopDungeons: return 15
        case .sharedLoot: return 20
        case .couplesAchievements: return 25
        case .legendaryBond: return 50
        }
    }
    
    var icon: String {
        switch self {
        case .sharedDutyBoard: return "rectangle.on.rectangle"
        case .taskAssignment: return "paperplane.fill"
        case .quickLearner: return "book.fill"
        case .bondEXPBoost: return "bolt.fill"
        case .fortuneSeeker: return "dollarsign.circle.fill"
        case .dualStreakBonus: return "flame.fill"
        case .relentless: return "arrow.trianglehead.counterclockwise"
        case .coopDungeons: return "shield.lefthalf.filled"
        case .sharedLoot: return "gift.fill"
        case .couplesAchievements: return "trophy.fill"
        case .legendaryBond: return "crown.fill"
        }
    }
    
    var description: String {
        switch self {
        case .sharedDutyBoard: return "Both partners can post and claim tasks"
        case .taskAssignment: return "Assign tasks directly to your partner"
        case .quickLearner: return "+5% EXP from all activities (scales with bond)"
        case .bondEXPBoost: return "+10% Bond EXP from all activities"
        case .fortuneSeeker: return "+5% Gold from all activities (scales with bond)"
        case .dualStreakBonus: return "+25% EXP when both have active streaks"
        case .relentless: return "+2% Streak Bonus (scales with bond)"
        case .coopDungeons: return "Unlock couples-only dungeons"
        case .sharedLoot: return "Share loot drops from dungeon runs"
        case .couplesAchievements: return "Unlock couples achievement track"
        case .legendaryBond: return "+50% all bonuses, legendary title"
        }
    }
}

// MARK: - Partner Interaction

/// A nudge, kudos, or challenge sent between partners
@Model
final class PartnerInteraction {
    /// Unique identifier
    var id: UUID
    
    /// Type of interaction
    var type: InteractionType
    
    /// Optional message
    var message: String?
    
    /// Who sent this
    var fromCharacterID: UUID
    
    /// When it was sent
    var createdAt: Date
    
    /// Has the recipient seen this?
    var isRead: Bool
    
    init(type: InteractionType, message: String? = nil, fromCharacterID: UUID) {
        self.id = UUID()
        self.type = type
        self.message = message
        self.fromCharacterID = fromCharacterID
        self.createdAt = Date()
        self.isRead = false
    }
}

/// Types of partner interactions
enum InteractionType: String, Codable {
    case nudge = "Nudge"
    case kudos = "Kudos"
    case challenge = "Challenge"
    case taskAssigned = "Task Assigned"
    case taskCompleted = "Task Completed"
    
    var icon: String {
        switch self {
        case .nudge: return "bell.fill"
        case .kudos: return "hand.thumbsup.fill"
        case .challenge: return "flag.fill"
        case .taskAssigned: return "paperplane.fill"
        case .taskCompleted: return "checkmark.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .nudge: return "AccentPurple"
        case .kudos: return "AccentGreen"
        case .challenge: return "AccentGold"
        case .taskAssigned: return "AccentGold"
        case .taskCompleted: return "AccentGreen"
        }
    }
    
    var defaultMessage: String {
        switch self {
        case .nudge: return "Your quest log awaits, adventurer!"
        case .kudos: return "Great job completing that task!"
        case .challenge: return "I challenge you to complete 3 tasks today!"
        case .taskAssigned: return "You've been assigned a new task!"
        case .taskCompleted: return "Your partner completed a task!"
        }
    }
}

// MARK: - QR Pairing Data

/// Data encoded in the QR code for pairing
struct PairingData: Codable {
    let version: Int
    let characterID: String
    let name: String
    let level: Int
    let characterClass: String?
    
    init(character: PlayerCharacter) {
        self.version = 1
        self.characterID = character.id.uuidString
        self.name = character.name
        self.level = character.level
        self.characterClass = character.characterClass?.rawValue
    }
    
    /// Encode to JSON string for QR code
    func toJSON() -> String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    /// Decode from JSON string scanned from QR code
    static func fromJSON(_ string: String) -> PairingData? {
        guard let data = string.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(PairingData.self, from: data)
    }
}
