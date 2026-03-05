import Foundation
import SwiftData

// MARK: - Goal Status

enum GoalStatus: String, Codable, CaseIterable {
    case active
    case completed
    case abandoned
    
    var label: String {
        switch self {
        case .active: return "Active"
        case .completed: return "Completed"
        case .abandoned: return "Abandoned"
        }
    }
    
    var icon: String {
        switch self {
        case .active: return "flag.fill"
        case .completed: return "checkmark.seal.fill"
        case .abandoned: return "xmark.circle.fill"
        }
    }
}

// MARK: - Goal Milestone

enum GoalMilestone: Int, CaseIterable {
    case quarter = 25
    case half = 50
    case threeQuarter = 75
    case complete = 100
    
    var label: String {
        switch self {
        case .quarter: return "25%"
        case .half: return "50%"
        case .threeQuarter: return "75%"
        case .complete: return "100%"
        }
    }
    
    var expReward: Int {
        switch self {
        case .quarter: return 50
        case .half: return 100
        case .threeQuarter: return 200
        case .complete: return 500
        }
    }
    
    var goldReward: Int {
        switch self {
        case .quarter: return 25
        case .half: return 50
        case .threeQuarter: return 100
        case .complete: return 250
        }
    }
    
    var icon: String {
        switch self {
        case .quarter: return "star.leadinghalf.filled"
        case .half: return "star.fill"
        case .threeQuarter: return "star.circle.fill"
        case .complete: return "crown.fill"
        }
    }
    
    var color: String {
        switch self {
        case .quarter: return "AccentGreen"
        case .half: return "AccentGold"
        case .threeQuarter: return "AccentOrange"
        case .complete: return "AccentPurple"
        }
    }
}

// MARK: - Goal Model

/// A long-term objective that tasks and habits feed into.
/// Progress is tracked automatically by counting completed linked items.
/// Supports both personal goals (createdBy = character) and shared party goals (isPartyGoal = true).
@Model
final class Goal {
    /// Unique identifier
    var id: UUID
    
    /// Goal title (e.g. "Run a 5K by June")
    var title: String
    
    /// Optional longer description
    var goalDescription: String?
    
    /// Category matching the task categories
    var category: TaskCategory
    
    /// Target completion date (optional)
    var targetDate: Date?
    
    /// Character who owns this goal (or who created the party goal)
    var createdBy: UUID
    
    /// Current status
    var status: GoalStatus
    
    /// When the goal was created
    var createdAt: Date
    
    /// When the goal was completed (if ever)
    var completedAt: Date?
    
    // MARK: - Party Goal Fields
    
    /// Whether this is a shared party goal (all members tracked individually)
    var isPartyGoal: Bool
    
    /// The party ID this goal belongs to (nil for personal goals)
    var partyID: UUID?
    
    /// Target count for each member (e.g., 30 for "Everyone meditate 30 times")
    var targetCount: Int
    
    /// JSON-encoded per-member progress: { "uuid-string": currentCount }
    /// Only used for party goals. Personal goals use task linking.
    var memberProgressJSON: String
    
    // MARK: - Milestone Tracking
    
    /// Whether the 25% milestone reward has been claimed
    var milestone25Claimed: Bool
    
    /// Whether the 50% milestone reward has been claimed
    var milestone50Claimed: Bool
    
    /// Whether the 75% milestone reward has been claimed
    var milestone75Claimed: Bool
    
    /// Whether the 100% milestone reward has been claimed
    var milestone100Claimed: Bool
    
    /// Personal goal init (backwards compatible)
    init(
        title: String,
        description: String? = nil,
        category: TaskCategory = .physical,
        targetDate: Date? = nil,
        createdBy: UUID
    ) {
        self.id = UUID()
        self.title = title
        self.goalDescription = description
        self.category = category
        self.targetDate = targetDate
        self.createdBy = createdBy
        self.status = .active
        self.createdAt = Date()
        self.completedAt = nil
        self.isPartyGoal = false
        self.partyID = nil
        self.targetCount = 0
        self.memberProgressJSON = "{}"
        self.milestone25Claimed = false
        self.milestone50Claimed = false
        self.milestone75Claimed = false
        self.milestone100Claimed = false
    }
    
    /// Shared party goal init
    init(
        title: String,
        description: String? = nil,
        category: TaskCategory = .physical,
        targetDate: Date? = nil,
        targetCount: Int,
        createdBy: UUID,
        partyID: UUID,
        memberIDs: [UUID]
    ) {
        self.id = UUID()
        self.title = title
        self.goalDescription = description
        self.category = category
        self.targetDate = targetDate
        self.createdBy = createdBy
        self.status = .active
        self.createdAt = Date()
        self.completedAt = nil
        self.isPartyGoal = true
        self.partyID = partyID
        self.targetCount = targetCount
        // Initialize progress for each member at 0
        var progress: [String: Int] = [:]
        for memberID in memberIDs {
            progress[memberID.uuidString] = 0
        }
        self.memberProgressJSON = (try? String(data: JSONEncoder().encode(progress), encoding: .utf8)) ?? "{}"
        self.milestone25Claimed = false
        self.milestone50Claimed = false
        self.milestone75Claimed = false
        self.milestone100Claimed = false
    }
    
    // MARK: - Milestone Helpers
    
    /// Check if a specific milestone has been claimed.
    func isMilestoneClaimed(_ milestone: GoalMilestone) -> Bool {
        switch milestone {
        case .quarter: return milestone25Claimed
        case .half: return milestone50Claimed
        case .threeQuarter: return milestone75Claimed
        case .complete: return milestone100Claimed
        }
    }
    
    /// Mark a milestone as claimed.
    func claimMilestone(_ milestone: GoalMilestone) {
        switch milestone {
        case .quarter: milestone25Claimed = true
        case .half: milestone50Claimed = true
        case .threeQuarter: milestone75Claimed = true
        case .complete: milestone100Claimed = true
        }
    }
    
    // MARK: - Party Goal Helpers
    
    /// Get the decoded member progress dictionary (memberID string -> count)
    func getMemberProgress() -> [String: Int] {
        guard isPartyGoal,
              let data = memberProgressJSON.data(using: .utf8),
              let dict = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return [:]
        }
        return dict
    }
    
    /// Update a member's progress count
    func updateMemberProgress(memberID: UUID, count: Int) {
        var progress = getMemberProgress()
        progress[memberID.uuidString] = count
        if let data = try? JSONEncoder().encode(progress),
           let json = String(data: data, encoding: .utf8) {
            memberProgressJSON = json
        }
    }
    
    /// Increment a member's progress by 1
    func incrementMemberProgress(memberID: UUID) {
        let progress = getMemberProgress()
        let current = progress[memberID.uuidString] ?? 0
        updateMemberProgress(memberID: memberID, count: current + 1)
    }
    
    /// Get a specific member's progress count
    func memberProgress(for memberID: UUID) -> Int {
        getMemberProgress()[memberID.uuidString] ?? 0
    }
    
    /// Overall party goal progress (average of all members, 0.0-1.0)
    var partyGoalProgress: Double {
        guard isPartyGoal, targetCount > 0 else { return 0 }
        let progress = getMemberProgress()
        guard !progress.isEmpty else { return 0 }
        let total = progress.values.reduce(0, +)
        let average = Double(total) / Double(progress.count)
        return min(1.0, average / Double(targetCount))
    }
    
    /// Whether ALL party members have hit the target
    var isPartyGoalComplete: Bool {
        guard isPartyGoal, targetCount > 0 else { return false }
        let progress = getMemberProgress()
        return progress.values.allSatisfy { $0 >= targetCount }
    }
}
