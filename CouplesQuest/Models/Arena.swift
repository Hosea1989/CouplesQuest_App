import Foundation
import SwiftData

// MARK: - Arena Run

/// Tracks an active or completed arena run with escalating waves
@Model
final class ArenaRun {
    /// Unique identifier
    var id: UUID
    
    /// Character who started this run
    var characterID: UUID
    
    /// Current wave (1-based)
    var currentWave: Int
    
    /// Highest wave reached in this run
    var maxWaveReached: Int
    
    /// Run status
    var status: ArenaStatus
    
    /// When the run started
    var startedAt: Date
    
    /// When the run ended
    var completedAt: Date?
    
    /// Total EXP earned during the run
    var totalExpEarned: Int
    
    /// Total gold earned during the run
    var totalGoldEarned: Int
    
    /// Results for each wave attempted
    var waveResults: [ArenaWaveResult]
    
    /// Current HP (starts at 100, carries between waves)
    var currentHP: Int
    
    /// Max HP
    var maxHP: Int
    
    init(characterID: UUID) {
        self.id = UUID()
        self.characterID = characterID
        self.currentWave = 1
        self.maxWaveReached = 1
        self.status = .inProgress
        self.startedAt = Date()
        self.completedAt = nil
        self.totalExpEarned = 0
        self.totalGoldEarned = 0
        self.waveResults = []
        self.currentHP = 100
        self.maxHP = 100
    }
    
    /// HP percentage (0.0 - 1.0)
    var hpPercentage: Double {
        guard maxHP > 0 else { return 0 }
        return Double(max(0, currentHP)) / Double(maxHP)
    }
    
    /// Whether the run is still active
    var isActive: Bool {
        status == .inProgress
    }
    
    // MARK: - Wave Generation
    
    /// Generate a DungeonRoom for the given wave number
    static func waveRoom(wave: Int) -> DungeonRoom {
        let difficulty = 15 + wave * 5
        let encounterTypes: [EncounterType] = [.combat, .combat, .combat, .puzzle, .trap]
        let encounterType = wave == 10 ? .boss : (wave == 5 ? .boss : encounterTypes[wave % encounterTypes.count])
        let stats = StatType.allCases
        let primaryStat = stats[wave % stats.count]
        let isBoss = wave == 5 || wave == 10
        
        let names: [String] = [
            "Arena Challenger", "Pit Fighter", "War Beast",
            "Mystic Duelist", "Trap Master", "Shadow Striker",
            "Iron Guardian", "Blade Dancer", "Arcane Sentinel",
            "Arena Champion"
        ]
        let name = wave <= names.count ? names[wave - 1] : "Wave \(wave) Champion"
        
        return DungeonRoom(
            name: name,
            description: "Arena Wave \(wave)" + (isBoss ? " — BOSS WAVE" : ""),
            encounterType: encounterType,
            primaryStat: primaryStat,
            difficultyRating: difficulty,
            isBossRoom: isBoss,
            bonusLootChance: isBoss ? 0.5 : 0.1
        )
    }
    
    /// EXP reward for completing a wave
    static func expReward(wave: Int) -> Int {
        wave * 15
    }
    
    /// Gold reward for completing a wave
    static func goldReward(wave: Int) -> Int {
        wave * 10
    }
    
    /// Gold cost for additional arena attempts (first is free)
    static let additionalAttemptCost: Int = 50
    
    /// Max waves in an arena run
    static let maxWaves: Int = 10
}

// MARK: - Arena Wave Result

/// Result of a single arena wave
struct ArenaWaveResult: Codable, Identifiable {
    var id: UUID
    var wave: Int
    var success: Bool
    var playerPower: Int
    var requiredPower: Int
    var expEarned: Int
    var goldEarned: Int
    var hpLost: Int
    var narrativeText: String
    var approachName: String
    
    init(
        wave: Int,
        success: Bool,
        playerPower: Int,
        requiredPower: Int,
        expEarned: Int = 0,
        goldEarned: Int = 0,
        hpLost: Int = 0,
        narrativeText: String = "",
        approachName: String = ""
    ) {
        self.id = UUID()
        self.wave = wave
        self.success = success
        self.playerPower = playerPower
        self.requiredPower = requiredPower
        self.expEarned = expEarned
        self.goldEarned = goldEarned
        self.hpLost = hpLost
        self.narrativeText = narrativeText
        self.approachName = approachName
    }
}

// MARK: - Arena Status

enum ArenaStatus: String, Codable {
    case inProgress = "In Progress"
    case completed = "Completed"
    case failed = "Failed"
}
