import Foundation
import SwiftData

/// Tracks the bond between party members (1–4 members).
/// Evolved from the original 2-person Bond model to support full party play.
@Model
final class Bond {
    /// Unique identifier
    var id: UUID
    
    /// Legacy single-partner ID (kept for backwards compatibility during migration)
    var partnerID: UUID
    
    /// All party member IDs stored as JSON string (SwiftData can't store [UUID] directly)
    var memberIDsJSON: String
    
    /// All party member IDs (max 4, includes the owner). Empty array = solo.
    var memberIDs: [UUID] {
        get {
            (try? JSONDecoder().decode([UUID].self, from: Data(memberIDsJSON.utf8))) ?? []
        }
        set {
            memberIDsJSON = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]"
        }
    }
    
    /// Current bond level (1-50)
    var bondLevel: Int
    
    /// Current bond EXP
    var bondEXP: Int
    
    /// Total bond EXP ever earned
    var totalBondEXP: Int
    
    /// Tasks completed that were assigned by a party member
    var partnerTasksCompleted: Int
    
    /// Duty board tasks claimed
    var dutyBoardTasksClaimed: Int
    
    /// Co-op dungeons completed together
    var coopDungeonsCompleted: Int
    
    /// Days ALL party members had active streaks (party streak)
    var dualStreakDays: Int
    
    /// Kudos sent to any party member
    var kudosSent: Int
    
    /// Nudges sent to any party member
    var nudgesSent: Int
    
    /// When the bond was created
    var createdAt: Date
    
    /// Last bond interaction
    var lastInteractionAt: Date
    
    /// Supabase party UUID (links to `parties` table)
    var supabasePartyID: UUID?
    
    /// The party leader's character UUID (the person who scanned the QR / initiated the party).
    /// Only the leader can kick members; others can only leave.
    var leaderID: UUID?
    
    /// Daily interaction counters (reset each calendar day)
    var kudosSentToday: Int
    var nudgesSentToday: Int
    var challengesSentToday: Int
    var interactionCounterDate: Date?
    
    /// Current party streak day count (all members completing 1+ task/day)
    var partyStreakDays: Int
    
    /// Date of last party streak tick
    var partyStreakLastDate: Date?
    
    /// Convenience: create with a single partner (legacy path)
    init(partnerID: UUID) {
        self.id = UUID()
        self.partnerID = partnerID
        self.memberIDsJSON = (try? String(data: JSONEncoder().encode([partnerID]), encoding: .utf8)) ?? "[]"
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
        self.supabasePartyID = nil
        self.kudosSentToday = 0
        self.nudgesSentToday = 0
        self.challengesSentToday = 0
        self.interactionCounterDate = nil
        self.partyStreakDays = 0
        self.partyStreakLastDate = nil
    }
    
    /// Create a party bond with multiple member IDs
    init(memberIDs: [UUID], supabasePartyID: UUID? = nil) {
        self.id = UUID()
        self.partnerID = memberIDs.first ?? UUID()
        self.memberIDsJSON = (try? String(data: JSONEncoder().encode(memberIDs), encoding: .utf8)) ?? "[]"
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
        self.supabasePartyID = supabasePartyID
        self.kudosSentToday = 0
        self.nudgesSentToday = 0
        self.challengesSentToday = 0
        self.interactionCounterDate = nil
        self.partyStreakDays = 0
        self.partyStreakLastDate = nil
    }
    
    // MARK: - Daily Interaction Limits
    
    /// Maximum kudos/nudges/challenges per day
    static let maxInteractionsPerType = 2
    
    /// Reset daily counters if the stored date is not today.
    func resetDailyCountersIfNeeded() {
        let calendar = Calendar.current
        if let lastDate = interactionCounterDate, calendar.isDateInToday(lastDate) {
            return // already today, nothing to reset
        }
        kudosSentToday = 0
        nudgesSentToday = 0
        challengesSentToday = 0
        interactionCounterDate = Date()
    }
    
    /// Whether the user can send more kudos today.
    var canSendKudos: Bool {
        resetDailyCountersIfNeeded()
        return kudosSentToday < Bond.maxInteractionsPerType
    }
    
    /// Whether the user can send more nudges today.
    var canSendNudge: Bool {
        resetDailyCountersIfNeeded()
        return nudgesSentToday < Bond.maxInteractionsPerType
    }
    
    /// Whether the user can send more challenges today.
    var canSendChallenge: Bool {
        resetDailyCountersIfNeeded()
        return challengesSentToday < Bond.maxInteractionsPerType
    }
    
    /// Remaining kudos the user can send today.
    var kudosRemainingToday: Int {
        resetDailyCountersIfNeeded()
        return max(0, Bond.maxInteractionsPerType - kudosSentToday)
    }
    
    /// Remaining nudges the user can send today.
    var nudgesRemainingToday: Int {
        resetDailyCountersIfNeeded()
        return max(0, Bond.maxInteractionsPerType - nudgesSentToday)
    }
    
    /// Remaining challenges the user can send today.
    var challengesRemainingToday: Int {
        resetDailyCountersIfNeeded()
        return max(0, Bond.maxInteractionsPerType - challengesSentToday)
    }
    
    // MARK: - Party Helpers
    
    /// Number of members in the party
    var partySize: Int {
        max(1, memberIDs.count)
    }
    
    /// Whether this is a multi-member party
    var isParty: Bool {
        memberIDs.count > 1
    }
    
    /// Whether the party has room for more members (max 4)
    var canAddMember: Bool {
        memberIDs.count < 4
    }
    
    /// Add a member to the party. Returns false if already at max (4).
    @discardableResult
    func addMember(_ memberID: UUID) -> Bool {
        guard canAddMember, !memberIDs.contains(memberID) else { return false }
        memberIDs.append(memberID)
        return true
    }
    
    /// Remove a member from the party
    func removeMember(_ memberID: UUID) {
        memberIDs.removeAll { $0 == memberID }
    }
    
    /// Check if a given UUID is a member of this party
    func isMember(_ memberID: UUID) -> Bool {
        memberIDs.contains(memberID)
    }
    
    /// Whether the given player is the party leader
    func isLeader(_ playerID: UUID) -> Bool {
        leaderID == playerID
    }
    
    /// Get all member IDs except the given one (useful for "other members")
    func otherMembers(excluding memberID: UUID) -> [UUID] {
        memberIDs.filter { $0 != memberID }
    }
    
    // MARK: - Party Power Scaling (Diminishing Returns)
    
    /// Power multiplier based on party size.
    /// Solo=1.0, 2=1.5, 3=1.85, 4=2.1
    var partyPowerMultiplier: Double {
        switch partySize {
        case 1: return 1.0
        case 2: return 1.5
        case 3: return 1.85
        case 4: return 2.1
        default: return 1.0
        }
    }
    
    // MARK: - Party Streak Bonuses
    
    /// EXP bonus multiplier from party streak tier
    var partyStreakEXPBonus: Double {
        switch partyStreakDays {
        case 30...: return 0.25
        case 14...: return 0.20
        case 7...: return 0.15
        case 3...: return 0.10
        default: return 0.0
        }
    }
    
    /// Gold bonus multiplier from party streak tier
    var partyStreakGoldBonus: Double {
        switch partyStreakDays {
        case 30...: return 0.20
        case 14...: return 0.15
        case 7...: return 0.10
        default: return 0.0
        }
    }
    
    /// Loot chance bonus from party streak tier
    var partyStreakLootBonus: Double {
        switch partyStreakDays {
        case 30...: return 0.10
        case 14...: return 0.05
        default: return 0.0
        }
    }
    
    /// Human-readable party streak tier label
    var partyStreakTierLabel: String? {
        switch partyStreakDays {
        case 30...: return "Legendary Streak"
        case 14...: return "Epic Streak"
        case 7...: return "Strong Streak"
        case 3...: return "Streak Active"
        default: return nil
        }
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
    
    /// Title based on bond level (updated from couples to party-neutral naming)
    var bondTitle: String {
        switch bondLevel {
        case 1...4: return "Acquaintances"
        case 5...9: return "Companions"
        case 10...14: return "Trusted Allies"
        case 15...19: return "Battle Forged"
        case 20...29: return "Ironbound"
        case 30...39: return "Oathsworn"
        case 40...49: return "Legends"
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
    
    /// Tick the party streak. Call when ALL members have completed 1+ task today.
    func tickPartyStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        if let lastDate = partyStreakLastDate,
           Calendar.current.isDate(lastDate, inSameDayAs: today) {
            return // Already ticked today
        }
        
        if let lastDate = partyStreakLastDate {
            let daysDiff = Calendar.current.dateComponents([.day], from: lastDate, to: today).day ?? 0
            if daysDiff == 1 {
                partyStreakDays += 1
            } else if daysDiff > 1 {
                partyStreakDays = 1 // Streak broken, restart
            }
        } else {
            partyStreakDays = 1
        }
        partyStreakLastDate = today
    }
    
    /// Break the party streak (called when a member misses a day)
    func breakPartyStreak() {
        partyStreakDays = 0
        partyStreakLastDate = nil
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
    case partyStreakBonus = "Party Streak Bonus"
    case relentless = "Relentless"
    case coopDungeons = "Co-op Dungeons"
    case sharedLoot = "Shared Loot Pool"
    case partyAchievements = "Party Achievements"
    case legendaryBond = "Legendary Bond"
    
    var requiredLevel: Int {
        switch self {
        case .sharedDutyBoard: return 1
        case .taskAssignment: return 2
        case .quickLearner: return 3
        case .bondEXPBoost: return 5
        case .fortuneSeeker: return 7
        case .partyStreakBonus: return 10
        case .relentless: return 12
        case .coopDungeons: return 15
        case .sharedLoot: return 20
        case .partyAchievements: return 25
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
        case .partyStreakBonus: return "flame.fill"
        case .relentless: return "arrow.trianglehead.counterclockwise"
        case .coopDungeons: return "shield.lefthalf.filled"
        case .sharedLoot: return "gift.fill"
        case .partyAchievements: return "trophy.fill"
        case .legendaryBond: return "crown.fill"
        }
    }
    
    var description: String {
        switch self {
        case .sharedDutyBoard: return "All party members can post and claim tasks"
        case .taskAssignment: return "Assign tasks directly to any ally"
        case .quickLearner: return "+5% EXP from all activities (scales with bond)"
        case .bondEXPBoost: return "+10% Bond EXP from all activities"
        case .fortuneSeeker: return "+5% Gold from all activities (scales with bond)"
        case .partyStreakBonus: return "+25% EXP when all members have active streaks"
        case .relentless: return "+2% Streak Bonus (scales with bond)"
        case .coopDungeons: return "Unlock party-only dungeons"
        case .sharedLoot: return "Share loot drops from dungeon runs"
        case .partyAchievements: return "Unlock party achievement track"
        case .legendaryBond: return "+50% all bonuses, legendary title"
        }
    }
}

/// Backwards-compatible aliases for renamed perks
extension BondPerk {
    /// Legacy alias — use `partyStreakBonus` instead
    static var dualStreakBonus: BondPerk { .partyStreakBonus }
    /// Legacy alias — use `partyAchievements` instead
    static var couplesAchievements: BondPerk { .partyAchievements }
}

// MARK: - Party Interaction

/// A nudge, kudos, or challenge sent between party members
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
    
    /// Who this targets (nil = broadcast to entire party)
    var toCharacterID: UUID?
    
    /// When it was sent
    var createdAt: Date
    
    /// Has the recipient seen this?
    var isRead: Bool
    
    init(type: InteractionType, message: String? = nil, fromCharacterID: UUID, toCharacterID: UUID? = nil) {
        self.id = UUID()
        self.type = type
        self.message = message
        self.fromCharacterID = fromCharacterID
        self.toCharacterID = toCharacterID
        self.createdAt = Date()
        self.isRead = false
    }
}

/// Types of party interactions
enum InteractionType: String, Codable {
    case nudge = "Nudge"
    case kudos = "Kudos"
    case challenge = "Challenge"
    case taskAssigned = "Task Assigned"
    case taskCompleted = "Task Completed"
    case taskInvited = "Task Invited"
    case memberJoined = "Member Joined"
    
    var icon: String {
        switch self {
        case .nudge: return "bell.fill"
        case .kudos: return "hand.thumbsup.fill"
        case .challenge: return "flag.fill"
        case .taskAssigned: return "paperplane.fill"
        case .taskCompleted: return "checkmark.circle.fill"
        case .taskInvited: return "person.2.badge.plus"
        case .memberJoined: return "person.badge.plus"
        }
    }
    
    var color: String {
        switch self {
        case .nudge: return "AccentPurple"
        case .kudos: return "AccentGreen"
        case .challenge: return "AccentGold"
        case .taskAssigned: return "AccentGold"
        case .taskCompleted: return "AccentGreen"
        case .taskInvited: return "AccentPink"
        case .memberJoined: return "AccentPink"
        }
    }
    
    var defaultMessage: String {
        switch self {
        case .nudge: return "Your quest log awaits, adventurer!"
        case .kudos: return "Great job completing that task!"
        case .challenge: return "I challenge you to complete 3 tasks today!"
        case .taskAssigned: return "You've been assigned a new task!"
        case .taskCompleted: return "Your ally completed a task!"
        case .taskInvited: return "Your ally invited you to a task!"
        case .memberJoined: return "A new ally has joined the party!"
        }
    }
}

// MARK: - QR Pairing Data

/// Data encoded in the QR code for party pairing
struct PairingData: Codable {
    let version: Int
    let characterID: String
    let name: String
    let level: Int
    let characterClass: String?
    /// The Supabase party ID to join (nil = create new party on pair)
    let partyID: String?
    /// SF Symbol name for the member's avatar
    let avatarName: String?
    /// The Supabase auth user ID (needed for cloud-side partner linking)
    let supabaseUserID: String?
    
    init(character: PlayerCharacter, partyID: UUID? = nil) {
        self.version = 2
        self.characterID = character.id.uuidString
        self.name = character.name
        self.level = character.level
        self.characterClass = character.characterClass?.rawValue
        self.partyID = partyID?.uuidString
        self.avatarName = character.avatarIcon
        self.supabaseUserID = character.supabaseUserID
    }
    
    /// Convenience init from raw values (used after cloud pairing acceptance)
    init(characterID: String, name: String, level: Int, characterClass: String?, partyID: String? = nil, avatarName: String? = nil, supabaseUserID: String? = nil) {
        self.version = 2
        self.characterID = characterID
        self.name = name
        self.level = level
        self.characterClass = characterClass
        self.partyID = partyID
        self.avatarName = avatarName
        self.supabaseUserID = supabaseUserID
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

// MARK: - Party Feed Event

/// A lightweight event for the party feed (maps to Supabase party_feed table)
struct PartyFeedEvent: Codable, Identifiable {
    let id: UUID
    let partyID: UUID
    let actorID: UUID
    let eventType: String
    let message: String
    let metadata: [String: String]
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case partyID = "party_id"
        case actorID = "actor_id"
        case eventType = "event_type"
        case message
        case metadata
        case createdAt = "created_at"
    }
    
    /// Display name mapping for event types
    var eventIcon: String {
        switch eventType {
        case "task_completed": return "checkmark.circle.fill"
        case "dungeon_loot": return "gift.fill"
        case "card_discovered": return "rectangle.stack.fill"
        case "level_up": return "arrow.up.circle.fill"
        case "achievement": return "trophy.fill"
        case "expedition_stage": return "map.fill"
        case "enhancement_success": return "hammer.fill"
        case "streak_milestone": return "flame.fill"
        case "nudge": return "bell.fill"
        case "kudos": return "hand.thumbsup.fill"
        default: return "star.fill"
        }
    }
    
    var eventColor: String {
        switch eventType {
        case "task_completed": return "AccentGreen"
        case "dungeon_loot": return "AccentGold"
        case "card_discovered": return "AccentPurple"
        case "level_up": return "AccentGold"
        case "achievement": return "AccentGold"
        case "streak_milestone": return "AccentOrange"
        case "nudge": return "AccentPurple"
        case "kudos": return "AccentGreen"
        default: return "AccentGold"
        }
    }
}

// MARK: - Party Member Info

/// Lightweight party member info for display (fetched from Supabase profiles)
struct PartyMemberInfo: Codable, Identifiable {
    let id: UUID
    let name: String
    let level: Int
    let characterClass: String?
    let avatarIcon: String?
    let tasksCompletedToday: Int
    let isOnline: Bool
    
    /// Display text for quick status
    var statusText: String {
        if isOnline {
            return tasksCompletedToday > 0 ? "Completed \(tasksCompletedToday) tasks today" : "Online"
        }
        return "Offline"
    }
}
