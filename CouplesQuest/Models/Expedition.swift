import Foundation
import SwiftData

// MARK: - Expedition Theme

/// Visual theme for expedition environments
enum ExpeditionTheme: String, Codable, CaseIterable {
    case ruins = "Ruins"
    case wilderness = "Wilderness"
    case ocean = "Ocean"
    case mountains = "Mountains"
    case underworld = "Underworld"
    
    var icon: String {
        switch self {
        case .ruins: return "building.columns.fill"
        case .wilderness: return "tree.fill"
        case .ocean: return "water.waves"
        case .mountains: return "mountain.2.fill"
        case .underworld: return "flame.fill"
        }
    }
    
    var color: String {
        switch self {
        case .ruins: return "AccentGold"
        case .wilderness: return "AccentGreen"
        case .ocean: return "AccentPurple"
        case .mountains: return "AccentOrange"
        case .underworld: return "AccentPink"
        }
    }
}

// MARK: - Expedition Status

enum ExpeditionStatus: String, Codable {
    case inProgress = "in_progress"
    case completed = "completed"
    case failed = "failed"
}

// MARK: - Expedition Stage

/// A single stage within an expedition
struct ExpeditionStage: Codable, Identifiable, Hashable {
    var id: String { name }
    let name: String
    let narrativeText: String
    let durationSeconds: Int
    let primaryStat: StatType
    let difficultyRating: Int
    let possibleRewards: StageRewards
    
    /// Duration formatted as human-readable string
    var durationFormatted: String {
        let hours = durationSeconds / 3600
        let minutes = (durationSeconds % 3600) / 60
        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }
}

// MARK: - Stage Rewards

/// Possible rewards for completing an expedition stage
struct StageRewards: Codable, Hashable {
    let exp: Int
    let gold: Int
    let equipmentChance: Double   // 0.0–1.0
    let materialChance: Double    // 0.0–1.0
    let cardChance: Double        // 0.0–1.0
}

// MARK: - Stage Result

/// The outcome of a completed expedition stage
struct StageResult: Codable, Identifiable, Hashable {
    var id: Int { stageIndex }
    let stageIndex: Int
    let success: Bool
    let narrativeLog: String
    let earnedEXP: Int
    let earnedGold: Int
    let lootDroppedName: String?
    let materialDropped: Bool
    let cardDropped: Bool
}

// MARK: - Expedition (Template)

/// An expedition template loaded from ContentManager/Supabase
struct Expedition: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let theme: ExpeditionTheme
    let stages: [ExpeditionStage]
    let totalDurationSeconds: Int
    let levelRequirement: Int
    let statRequirements: [StatRequirement]
    let isPartyExpedition: Bool
    let exclusiveLootIDs: [String]
    
    /// Number of stages
    var stageCount: Int { stages.count }
    
    /// Total duration formatted
    var totalDurationFormatted: String {
        let hours = totalDurationSeconds / 3600
        let minutes = (totalDurationSeconds % 3600) / 60
        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }
    
    /// Check if a character meets the requirements
    func meetsRequirements(character: PlayerCharacter) -> Bool {
        if character.level < levelRequirement {
            return false
        }
        let effectiveStats = character.effectiveStats
        for requirement in statRequirements {
            if effectiveStats.value(for: requirement.stat) < requirement.minimum {
                return false
            }
        }
        return true
    }
    
    /// Initialize from ContentManager's ContentExpedition
    init(from content: ContentExpedition) {
        self.id = content.id
        self.name = content.name
        self.description = content.description
        self.theme = ExpeditionTheme(rawValue: content.theme.capitalized) ?? .ruins
        self.totalDurationSeconds = content.totalDurationSeconds
        self.levelRequirement = content.levelRequirement
        self.isPartyExpedition = content.isPartyExpedition
        self.exclusiveLootIDs = content.exclusiveLootIds
        
        // Convert stat requirements
        self.statRequirements = content.statRequirements.map { req in
            StatRequirement(
                stat: StatType(rawValue: req.stat.capitalized) ?? .strength,
                minimum: req.value
            )
        }
        
        // Convert stages
        self.stages = content.stages.map { stage in
            ExpeditionStage(
                name: stage.name,
                narrativeText: stage.narrativeText,
                durationSeconds: stage.durationSeconds,
                primaryStat: StatType(rawValue: stage.primaryStat.capitalized) ?? .strength,
                difficultyRating: stage.difficultyRating,
                possibleRewards: StageRewards(
                    exp: stage.possibleRewards.exp,
                    gold: stage.possibleRewards.gold,
                    equipmentChance: stage.possibleRewards.equipmentChance,
                    materialChance: stage.possibleRewards.materialChance,
                    cardChance: stage.possibleRewards.cardChance
                )
            )
        }
    }
}

// MARK: - Active Expedition

/// Tracks an in-progress expedition. Persisted via UserDefaults to survive app restarts.
final class ActiveExpedition: Codable, Identifiable {
    var id: UUID
    let expeditionID: String
    let expeditionName: String
    let expeditionTheme: ExpeditionTheme
    let characterID: UUID
    var partyMemberIDs: [UUID]
    var currentStageIndex: Int
    var stageResults: [StageResult]
    var startedAt: Date
    var nextStageCompletesAt: Date
    var status: ExpeditionStatus
    
    /// Total number of stages in this expedition
    let totalStages: Int
    
    /// Stage names for display
    let stageNames: [String]
    
    /// Stage durations for timer calculations
    let stageDurations: [Int]
    
    /// Whether rewards have been claimed
    var rewardsClaimed: Bool
    
    // MARK: - Init
    
    init(
        expedition: Expedition,
        characterID: UUID,
        partyMemberIDs: [UUID] = []
    ) {
        self.id = UUID()
        self.expeditionID = expedition.id
        self.expeditionName = expedition.name
        self.expeditionTheme = expedition.theme
        self.characterID = characterID
        self.partyMemberIDs = partyMemberIDs
        self.currentStageIndex = 0
        self.stageResults = []
        self.startedAt = Date()
        self.totalStages = expedition.stages.count
        self.stageNames = expedition.stages.map { $0.name }
        self.stageDurations = expedition.stages.map { $0.durationSeconds }
        self.status = .inProgress
        self.rewardsClaimed = false
        
        // First stage completes after its duration
        if let firstStage = expedition.stages.first {
            self.nextStageCompletesAt = Date().addingTimeInterval(TimeInterval(firstStage.durationSeconds))
        } else {
            self.nextStageCompletesAt = Date()
        }
    }
    
    // MARK: - Computed Properties
    
    /// Is the current stage complete?
    var isCurrentStageComplete: Bool {
        Date() >= nextStageCompletesAt
    }
    
    /// Is the entire expedition complete? (All stages resolved)
    var isFullyComplete: Bool {
        status == .completed || status == .failed
    }
    
    /// Number of stages that have been resolved
    var completedStageCount: Int {
        stageResults.count
    }
    
    /// How many stages still need to be resolved
    var remainingStages: Int {
        max(0, totalStages - stageResults.count)
    }
    
    /// Overall progress (0.0–1.0) based on resolved stages
    var overallProgress: Double {
        guard totalStages > 0 else { return 1.0 }
        return Double(stageResults.count) / Double(totalStages)
    }
    
    /// Time remaining for current stage
    var timeRemainingForCurrentStage: TimeInterval {
        max(0, nextStageCompletesAt.timeIntervalSince(Date()))
    }
    
    /// Time remaining formatted
    var timeRemainingFormatted: String {
        let remaining = Int(timeRemainingForCurrentStage)
        let hours = remaining / 3600
        let minutes = (remaining % 3600) / 60
        let seconds = remaining % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Current stage progress (0.0–1.0) based on elapsed time
    var currentStageProgress: Double {
        guard currentStageIndex < stageDurations.count else { return 1.0 }
        let duration = TimeInterval(stageDurations[currentStageIndex])
        guard duration > 0 else { return 1.0 }
        let elapsed = Date().timeIntervalSince(nextStageCompletesAt.addingTimeInterval(-duration))
        return min(1.0, max(0.0, elapsed / duration))
    }
    
    /// Name of the current stage
    var currentStageName: String {
        guard currentStageIndex < stageNames.count else { return "Final" }
        return stageNames[currentStageIndex]
    }
    
    /// Total EXP earned across all completed stages
    var totalEXPEarned: Int {
        stageResults.reduce(0) { $0 + $1.earnedEXP }
    }
    
    /// Total gold earned across all completed stages
    var totalGoldEarned: Int {
        stageResults.reduce(0) { $0 + $1.earnedGold }
    }
    
    /// Number of stages that succeeded
    var successfulStageCount: Int {
        stageResults.filter { $0.success }.count
    }
    
    /// Any equipment dropped across stages
    var equipmentDropped: [String] {
        stageResults.compactMap { $0.lootDroppedName }
    }
    
    // MARK: - Stage Advancement
    
    /// Record a stage result and advance to the next stage
    func recordStageResult(_ result: StageResult) {
        stageResults.append(result)
        currentStageIndex = stageResults.count
        
        if currentStageIndex >= totalStages {
            // All stages complete
            status = .completed
        } else {
            // Set timer for next stage
            let nextDuration = stageDurations[currentStageIndex]
            nextStageCompletesAt = Date().addingTimeInterval(TimeInterval(nextDuration))
        }
    }
    
    // MARK: - Persistence
    
    private static let storageKey = "ActiveExpedition_data"
    
    /// Save this active expedition to UserDefaults for persistence across app restarts
    func persist() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
    
    /// Load a previously saved active expedition from UserDefaults
    static func loadPersisted() -> ActiveExpedition? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(ActiveExpedition.self, from: data)
    }
    
    /// Remove persisted active expedition data
    static func clearPersisted() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}

// MARK: - Expedition Key Tracking

/// Tracks expedition keys in PlayerCharacter via UserDefaults (simple integer count)
struct ExpeditionKeyStore {
    private static let storageKey = "ExpeditionKeys_count"
    
    /// Get current expedition key count
    static var count: Int {
        UserDefaults.standard.integer(forKey: storageKey)
    }
    
    /// Add keys
    static func add(_ amount: Int = 1) {
        let current = count
        UserDefaults.standard.set(current + amount, forKey: storageKey)
    }
    
    /// Use a key (returns false if none available)
    @discardableResult
    static func use() -> Bool {
        let current = count
        guard current > 0 else { return false }
        UserDefaults.standard.set(current - 1, forKey: storageKey)
        return true
    }
}
