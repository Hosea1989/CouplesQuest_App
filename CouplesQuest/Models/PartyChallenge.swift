import Foundation
import SwiftData

// MARK: - Challenge Type

/// The kind of activity the party must complete.
enum PartyChallengeType: String, Codable, CaseIterable, Identifiable {
    case tasks       = "Tasks"
    case duties      = "Duty Board"
    case dungeons    = "Dungeons"
    case dailyQuests = "Daily Quests"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .tasks:       return "checkmark.circle.fill"
        case .duties:      return "list.clipboard.fill"
        case .dungeons:    return "shield.lefthalf.filled"
        case .dailyQuests: return "star.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .tasks:       return "AccentGreen"
        case .duties:      return "AccentGold"
        case .dungeons:    return "AccentPurple"
        case .dailyQuests: return "AccentPink"
        }
    }
    
    var verb: String {
        switch self {
        case .tasks:       return "Complete"
        case .duties:      return "Claim"
        case .dungeons:    return "Clear"
        case .dailyQuests: return "Finish"
        }
    }
    
    /// Suggested target counts the leader can pick from
    var suggestedTargets: [Int] {
        switch self {
        case .tasks:       return [5, 10, 15, 20, 25]
        case .duties:      return [3, 5, 8, 10, 15]
        case .dungeons:    return [2, 3, 5, 7, 10]
        case .dailyQuests: return [5, 10, 15, 20, 25]
        }
    }
}

// MARK: - Challenge Duration

enum ChallengeDuration: Int, CaseIterable, Identifiable {
    case threeDays = 3
    case oneWeek   = 7
    case twoWeeks  = 14
    
    var id: Int { rawValue }
    
    var label: String {
        switch self {
        case .threeDays: return "3 Days"
        case .oneWeek:   return "1 Week"
        case .twoWeeks:  return "2 Weeks"
        }
    }
}

// MARK: - Per-Member Progress

struct ChallengeMemberProgress: Codable, Identifiable {
    let memberID: UUID
    var memberName: String
    var current: Int
    
    var id: UUID { memberID }
}

// MARK: - Party Challenge Model

/// A party-wide challenge set by the leader. All members work toward the same goal.
@Model
final class PartyChallenge {
    var id: UUID
    
    /// The type of activity to complete
    var challengeTypeRaw: String
    
    /// Target count each member must hit
    var targetCount: Int
    
    /// Custom title (auto-generated if nil)
    var title: String
    
    /// When the challenge was created
    var createdAt: Date
    
    /// When the challenge expires
    var deadline: Date
    
    /// Character ID of the leader who created it
    var createdBy: UUID
    
    /// Whether the challenge is currently active
    var isActive: Bool
    
    /// Per-member progress stored as JSON
    var memberProgressJSON: String
    
    /// Bond EXP reward per member on individual completion
    var rewardBondEXP: Int
    
    /// Gold reward per member on individual completion
    var rewardGold: Int
    
    /// Bonus Bond EXP if ALL members complete it
    var partyBonusBondEXP: Int
    
    /// Whether the party bonus has been awarded
    var partyBonusAwarded: Bool
    
    // MARK: - Computed Properties
    
    var challengeType: PartyChallengeType {
        get { PartyChallengeType(rawValue: challengeTypeRaw) ?? .tasks }
        set { challengeTypeRaw = newValue.rawValue }
    }
    
    var memberProgress: [ChallengeMemberProgress] {
        get {
            guard let data = memberProgressJSON.data(using: .utf8),
                  let progress = try? JSONDecoder().decode([ChallengeMemberProgress].self, from: data) else {
                return []
            }
            return progress
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                memberProgressJSON = json
            }
        }
    }
    
    /// Whether the challenge deadline has passed
    var isExpired: Bool {
        Date() > deadline
    }
    
    /// Time remaining as a human-readable string
    var timeRemainingLabel: String {
        let now = Date()
        guard deadline > now else { return "Expired" }
        let components = Calendar.current.dateComponents([.day, .hour], from: now, to: deadline)
        if let days = components.day, days > 0 {
            return "\(days)d \(components.hour ?? 0)h left"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)h left"
        }
        return "< 1h left"
    }
    
    /// Progress for a specific member
    func progress(for memberID: UUID) -> Int {
        memberProgress.first(where: { $0.memberID == memberID })?.current ?? 0
    }
    
    /// Whether a specific member has completed the challenge
    func isMemberComplete(_ memberID: UUID) -> Bool {
        progress(for: memberID) >= targetCount
    }
    
    /// Whether ALL members have completed the challenge
    var isFullPartyComplete: Bool {
        guard !memberProgress.isEmpty else { return false }
        return memberProgress.allSatisfy { $0.current >= targetCount }
    }
    
    /// Overall party progress (average across members)
    var partyProgressFraction: Double {
        guard !memberProgress.isEmpty else { return 0 }
        let total = memberProgress.reduce(0.0) { $0 + min(Double($1.current) / Double(max(1, targetCount)), 1.0) }
        return total / Double(memberProgress.count)
    }
    
    /// Increment progress for a member. Returns true if they just completed the target.
    @discardableResult
    func incrementProgress(for memberID: UUID, by amount: Int = 1) -> Bool {
        var progress = memberProgress
        if let index = progress.firstIndex(where: { $0.memberID == memberID }) {
            let wasBelowTarget = progress[index].current < targetCount
            progress[index].current += amount
            memberProgress = progress
            return wasBelowTarget && progress[index].current >= targetCount
        }
        return false
    }
    
    // MARK: - Init
    
    init(
        challengeType: PartyChallengeType,
        targetCount: Int,
        durationDays: Int,
        createdBy: UUID,
        members: [(id: UUID, name: String)]
    ) {
        self.id = UUID()
        self.challengeTypeRaw = challengeType.rawValue
        self.targetCount = targetCount
        self.title = "\(challengeType.verb) \(targetCount) \(challengeType.rawValue)"
        self.createdAt = Date()
        self.deadline = Calendar.current.date(byAdding: .day, value: durationDays, to: Date()) ?? Date()
        self.createdBy = createdBy
        self.isActive = true
        self.rewardBondEXP = Self.calculateRewardBondEXP(type: challengeType, target: targetCount)
        self.rewardGold = Self.calculateRewardGold(type: challengeType, target: targetCount)
        self.partyBonusBondEXP = Self.calculatePartyBonus(type: challengeType, target: targetCount)
        self.partyBonusAwarded = false
        
        let initialProgress = members.map { ChallengeMemberProgress(memberID: $0.id, memberName: $0.name, current: 0) }
        if let data = try? JSONEncoder().encode(initialProgress),
           let json = String(data: data, encoding: .utf8) {
            self.memberProgressJSON = json
        } else {
            self.memberProgressJSON = "[]"
        }
    }
    
    // MARK: - Reward Calculation
    
    static func calculateRewardBondEXP(type: PartyChallengeType, target: Int) -> Int {
        switch type {
        case .tasks:       return max(5, target * 2)
        case .duties:      return max(5, target * 3)
        case .dungeons:    return max(8, target * 5)
        case .dailyQuests: return max(5, target * 2)
        }
    }
    
    static func calculateRewardGold(type: PartyChallengeType, target: Int) -> Int {
        switch type {
        case .tasks:       return max(20, target * 5)
        case .duties:      return max(25, target * 8)
        case .dungeons:    return max(40, target * 15)
        case .dailyQuests: return max(20, target * 5)
        }
    }
    
    static func calculatePartyBonus(type: PartyChallengeType, target: Int) -> Int {
        // Bonus if the whole party finishes = 50% of individual reward
        let individual = calculateRewardBondEXP(type: type, target: target)
        return max(5, individual / 2)
    }
}
