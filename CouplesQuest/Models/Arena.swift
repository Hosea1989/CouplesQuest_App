import Foundation
import SwiftData

// MARK: - Arena Modifier

/// Weekly arena modifier that changes the meta
struct ArenaModifier: Codable, Identifiable {
    var id: String
    var name: String
    var modifierDescription: String
    var icon: String
    var damageDealMultiplier: Double
    var damageTakenMultiplier: Double
    var startingHPOverride: Int?
    var hpRegenPerWave: Int
    var goldMultiplier: Double
    var expMultiplier: Double
    var allBossWaves: Bool
    var statFocus: String?
    var statFocusMultiplier: Double
    
    init(
        id: String = "none",
        name: String = "Standard",
        modifierDescription: String = "No modifier active.",
        icon: String = "trophy.fill",
        damageDealMultiplier: Double = 1.0,
        damageTakenMultiplier: Double = 1.0,
        startingHPOverride: Int? = nil,
        hpRegenPerWave: Int = 0,
        goldMultiplier: Double = 1.0,
        expMultiplier: Double = 1.0,
        allBossWaves: Bool = false,
        statFocus: String? = nil,
        statFocusMultiplier: Double = 1.0
    ) {
        self.id = id
        self.name = name
        self.modifierDescription = modifierDescription
        self.icon = icon
        self.damageDealMultiplier = damageDealMultiplier
        self.damageTakenMultiplier = damageTakenMultiplier
        self.startingHPOverride = startingHPOverride
        self.hpRegenPerWave = hpRegenPerWave
        self.goldMultiplier = goldMultiplier
        self.expMultiplier = expMultiplier
        self.allBossWaves = allBossWaves
        self.statFocus = statFocus
        self.statFocusMultiplier = statFocusMultiplier
    }
    
    // Map to original JSON key for backward compatibility with existing serialized data
    enum CodingKeys: String, CodingKey {
        case id, name, icon
        case modifierDescription = "description"
        case damageDealMultiplier, damageTakenMultiplier, startingHPOverride
        case hpRegenPerWave, goldMultiplier, expMultiplier
        case allBossWaves, statFocus, statFocusMultiplier
    }
    
    /// Default modifier (no effects)
    static let standard = ArenaModifier()
}

// MARK: - Arena Milestone Reward

/// Reward earned at specific wave milestones
struct ArenaMilestoneReward: Codable, Identifiable {
    var id: UUID
    var wave: Int
    var goldReward: Int
    var consumableRarity: String     // "common", "uncommon", "rare", "epic"
    var equipDropChance: Double      // 0.0 - 1.0
    var equipMinRarity: String       // minimum rarity if equipment drops
    var cardDropChance: Double       // 0.0 - 1.0
    var claimed: Bool
    
    init(wave: Int, goldReward: Int, consumableRarity: String, equipDropChance: Double = 0.0, equipMinRarity: String = "rare", cardDropChance: Double = 0.0) {
        self.id = UUID()
        self.wave = wave
        self.goldReward = goldReward
        self.consumableRarity = consumableRarity
        self.equipDropChance = equipDropChance
        self.equipMinRarity = equipMinRarity
        self.cardDropChance = cardDropChance
        self.claimed = false
    }
    
    /// Generate milestone rewards for a given wave number
    static func milestoneForWave(_ wave: Int) -> ArenaMilestoneReward? {
        switch wave {
        case 5:
            return ArenaMilestoneReward(wave: 5, goldReward: 150, consumableRarity: "common")
        case 10:
            return ArenaMilestoneReward(wave: 10, goldReward: 350, consumableRarity: "uncommon")
        case 15:
            return ArenaMilestoneReward(wave: 15, goldReward: 600, consumableRarity: "rare", cardDropChance: 0.10)
        case 20:
            return ArenaMilestoneReward(wave: 20, goldReward: 1000, consumableRarity: "rare", equipDropChance: 1.0, equipMinRarity: "rare")
        case 25:
            return ArenaMilestoneReward(wave: 25, goldReward: 1500, consumableRarity: "epic", cardDropChance: 0.25)
        default:
            // Every 10 waves after 25: escalating rewards
            if wave > 25 && wave % 10 == 0 {
                let tier = (wave - 25) / 10
                return ArenaMilestoneReward(
                    wave: wave,
                    goldReward: 1000 + tier * 300,
                    consumableRarity: "epic",
                    equipDropChance: min(0.5, 0.2 + Double(tier) * 0.05),
                    equipMinRarity: "rare",
                    cardDropChance: min(0.5, 0.25 + Double(tier) * 0.05)
                )
            }
            return nil
        }
    }
    
    /// Get all milestone waves up to a given wave
    static func allMilestoneWaves(upTo maxWave: Int) -> [Int] {
        var waves: [Int] = [5, 10, 15, 20, 25]
        var next = 30
        while next <= maxWave {
            if next % 10 == 0 {
                waves.append(next)
            }
            next += 5
        }
        return waves.filter { $0 <= maxWave }
    }
    
    /// Check if a given wave is a milestone wave
    static func isMilestoneWave(_ wave: Int) -> Bool {
        if wave <= 25 { return wave % 5 == 0 }
        return wave % 10 == 0
    }
}

// MARK: - Arena Duration

/// How long the player commits to an arena run
enum ArenaDuration: String, Codable, CaseIterable, Identifiable {
    case oneHour = "1 Hour"
    case twoHours = "2 Hours"
    case threeHours = "3 Hours"
    
    var id: String { rawValue }
    
    /// Maximum number of waves for this duration
    var maxWaves: Int {
        switch self {
        case .oneHour: return 12
        case .twoHours: return 24
        case .threeHours: return 36
        }
    }
    
    /// Seconds each wave takes in real time
    var secondsPerWave: Int { 300 } // 5 minutes
    
    /// Total duration in seconds if all waves are completed
    var totalSeconds: Int { maxWaves * secondsPerWave }
    
    /// Display label
    var label: String { rawValue }
    
    /// Short label for picker
    var shortLabel: String {
        switch self {
        case .oneHour: return "1h"
        case .twoHours: return "2h"
        case .threeHours: return "3h"
        }
    }
    
    /// Description for the UI
    var subtitle: String {
        "\(maxWaves) waves"
    }
    
    /// Icon
    var icon: String {
        switch self {
        case .oneHour: return "clock"
        case .twoHours: return "clock.badge"
        case .threeHours: return "clock.badge.fill"
        }
    }
}

// MARK: - Arena Run

/// Tracks an active or completed arena run with escalating waves
@Model
final class ArenaRun {
    /// Unique identifier
    var id: UUID
    
    /// Character who started this run
    var characterID: UUID
    
    /// Current wave (1-based) — used during pre-simulation
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
    
    /// Active modifier for this run (serialized)
    var activeModifier: ArenaModifier
    
    /// Milestone rewards earned during this run
    var milestoneRewards: [ArenaMilestoneReward]
    
    /// Maximum waves for this run (12/24/36)
    var maxWaves: Int
    
    /// Seconds per wave (300 = 5 minutes)
    var secondsPerWave: Int
    
    /// Total run duration in seconds (wavesResolved * secondsPerWave)
    var durationSeconds: Int
    
    /// When the AFK timer completes
    var completesAt: Date?
    
    /// Whether the run has been resolved (prevents double-resolution)
    var isResolved: Bool
    
    /// The chosen duration tier
    var durationTier: ArenaDuration
    
    init(characterID: UUID, characterHP: Int, characterMaxHP: Int, duration: ArenaDuration = .oneHour, modifier: ArenaModifier = .standard) {
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
        self.activeModifier = modifier
        self.milestoneRewards = []
        self.maxWaves = duration.maxWaves
        self.secondsPerWave = duration.secondsPerWave
        self.durationSeconds = 0 // Set after pre-simulation
        self.completesAt = nil   // Set after pre-simulation
        self.isResolved = false
        self.durationTier = duration
        
        // Use character's persistent HP (modifier can still override for special events)
        let startHP = modifier.startingHPOverride ?? characterHP
        self.currentHP = startHP
        self.maxHP = modifier.startingHPOverride ?? characterMaxHP
    }
    
    // MARK: - AFK Timer Properties
    
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
            return String(format: "%dh %02dm %02ds", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%dm %02ds", minutes, seconds)
        } else {
            return "\(seconds)s"
        }
    }
    
    /// Which wave should currently be visible based on elapsed time (1-based)
    var currentDisplayWave: Int {
        guard secondsPerWave > 0 else { return waveResults.count }
        let elapsed = Date().timeIntervalSince(startedAt)
        let waveIndex = Int(elapsed / Double(secondsPerWave)) + 1
        return min(waveIndex, waveResults.count)
    }
    
    /// Wave results that should be visible based on elapsed time
    var visibleWaveResults: [ArenaWaveResult] {
        let count = currentDisplayWave
        return Array(waveResults.prefix(count))
    }
    
    /// HP at the point of the currently displayed wave
    var displayHP: Int {
        let visible = visibleWaveResults
        guard !visible.isEmpty else { return maxHP }
        // Start from maxHP and subtract all HP lost so far
        let totalLost = visible.reduce(0) { $0 + $1.hpLost }
        return max(0, maxHP - totalLost)
    }
    
    /// HP percentage at the current display point
    var displayHPPercentage: Double {
        guard maxHP > 0 else { return 0 }
        return Double(max(0, displayHP)) / Double(maxHP)
    }
    
    /// HP percentage (0.0 - 1.0) — final state
    var hpPercentage: Double {
        guard maxHP > 0 else { return 0 }
        return Double(max(0, currentHP)) / Double(maxHP)
    }
    
    /// Whether the run is still active
    var isActive: Bool {
        status == .inProgress
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
    
    // MARK: - Wave Generation
    
    /// Generate a DungeonRoom for the given wave number (infinite scaling)
    static func waveRoom(wave: Int, modifier: ArenaModifier = .standard) -> DungeonRoom {
        // Difficulty scales: base 20, +5 per wave, +8-10% compounding after wave 10
        let baseDifficulty: Double
        if wave <= 10 {
            baseDifficulty = Double(15 + wave * 5)
        } else {
            // Beyond wave 10: exponential scaling (~8-10% per wave)
            let base10 = Double(15 + 10 * 5) // = 65
            baseDifficulty = base10 * pow(1.09, Double(wave - 10))
        }
        let difficulty = Int(baseDifficulty)
        
        // Encounter types cycle; boss waves at 5, 10, 15, 20, 25, then every 10
        let isBossWave: Bool
        if modifier.allBossWaves {
            isBossWave = true
        } else if wave <= 25 {
            isBossWave = wave % 5 == 0
        } else {
            isBossWave = wave % 10 == 0
        }
        
        let encounterTypes: [EncounterType] = [.combat, .combat, .combat, .puzzle, .trap]
        let encounterType = isBossWave ? .boss : encounterTypes[wave % encounterTypes.count]
        
        let stats = StatType.allCases
        let primaryStat: StatType
        if let focusStat = modifier.statFocus, let stat = StatType(rawValue: focusStat) {
            primaryStat = stat
        } else {
            primaryStat = stats[wave % stats.count]
        }
        
        let waveNames: [String] = [
            "Arena Challenger", "Pit Fighter", "War Beast",
            "Mystic Duelist", "Trap Master", "Shadow Striker",
            "Iron Guardian", "Blade Dancer", "Arcane Sentinel",
            "Arena Champion"
        ]
        
        let name: String
        if isBossWave {
            let bossNames = ["Arena Champion", "Grand Gladiator", "Pit Overlord", "Eternal Warrior", "Death Dealer"]
            name = wave <= 25 ? bossNames[min(wave / 5, bossNames.count) - 1] : "Wave \(wave) — \(bossNames[wave % bossNames.count])"
        } else if wave <= waveNames.count {
            name = waveNames[wave - 1]
        } else {
            name = "Wave \(wave) Challenger"
        }
        
        return DungeonRoom(
            name: name,
            description: "Arena Wave \(wave)" + (isBossWave ? " — BOSS WAVE" : ""),
            encounterType: encounterType,
            primaryStat: primaryStat,
            difficultyRating: difficulty,
            isBossRoom: isBossWave,
            bonusLootChance: isBossWave ? 0.5 : 0.1
        )
    }
    
    /// EXP reward for completing a wave (with modifier scaling)
    static func expReward(wave: Int, modifier: ArenaModifier = .standard) -> Int {
        let base = wave * 15
        return Int(Double(base) * modifier.expMultiplier)
    }
    
    /// Gold reward for completing a wave (with modifier scaling)
    static func goldReward(wave: Int, modifier: ArenaModifier = .standard) -> Int {
        let base = wave * 20
        return Int(Double(base) * modifier.goldMultiplier)
    }
    
    /// Apply HP regen between waves (from modifier)
    func applyWaveRegen() {
        if activeModifier.hpRegenPerWave > 0 {
            currentHP = min(maxHP, currentHP + activeModifier.hpRegenPerWave)
        }
    }
    
    /// Gold cost for additional arena attempts (first is free)
    static let additionalAttemptCost: Int = 50
    
    /// Next milestone wave relative to current progress
    func nextMilestoneWave() -> Int? {
        let milestones = ArenaMilestoneReward.allMilestoneWaves(upTo: currentWave + 50)
        return milestones.first(where: { $0 > maxWaveReached })
    }
    
    // MARK: - AFK Auto-Resolution
    
    /// Pre-simulate all arena waves at once. Call immediately after init.
    /// This resolves all waves, stores results, and sets the timer based on waves survived.
    static func autoResolveArena(
        run: ArenaRun,
        character: PlayerCharacter
    ) {
        let modifier = run.activeModifier
        var hp = run.currentHP
        let maxHP = run.maxHP
        
        for wave in 1...run.maxWaves {
            run.currentWave = wave
            
            // Generate the wave room
            let room = ArenaRun.waveRoom(wave: wave, modifier: modifier)
            
            // Auto-pick the best approach: choose the one whose primaryStat the character is strongest in
            let approaches = room.encounterType.approaches
            let bestApproach = approaches.max(by: { a, b in
                character.effectiveStats.value(for: a.primaryStat) < character.effectiveStats.value(for: b.primaryStat)
            })
            
            // Calculate power and success chance
            let power = DungeonEngine.calculatePartyPower(party: [character], room: room, statOverride: bestApproach?.primaryStat)
            let modifiedPower = Int(Double(power) * (bestApproach?.powerModifier ?? 1.0) * modifier.damageDealMultiplier)
            let difficulty = room.difficultyRating
            let successChance = DungeonEngine.calculateSuccessChance(party: [character], room: room, approach: bestApproach)
            
            let roll = Double.random(in: 0...1)
            let success = roll <= successChance
            
            var expEarned = 0
            var goldEarned = 0
            var hpLost = 0
            
            if success {
                expEarned = ArenaRun.expReward(wave: wave, modifier: modifier)
                goldEarned = ArenaRun.goldReward(wave: wave, modifier: modifier)
                
                // Risky approach bonus
                if let approach = bestApproach, approach.powerModifier > 1.1 {
                    let bonus = 1.0 + (approach.powerModifier - 1.0) * 0.5
                    expEarned = Int(Double(expEarned) * bonus)
                    goldEarned = Int(Double(goldEarned) * bonus)
                }
                
                // Award to character
                character.gainEXP(expEarned)
                character.gold += goldEarned
                run.totalExpEarned += expEarned
                run.totalGoldEarned += goldEarned
                
                // Grant equipment EXP to all equipped gear
                let arenaEquipEXP = GameEngine.equipmentEXPForArenaWave()
                for item in character.equipment.allEquipped where item.canLevelUp {
                    let didLevel = item.grantEXP(arenaEquipEXP)
                    if didLevel {
                        let quirk = QuirkRoller.rollQuirk(
                            equipmentLevel: item.equipmentLevel,
                            itemRarity: item.rarity,
                            baseType: item.detectedBaseType,
                            existingQuirks: item.quirks
                        )
                        item.quirks.append(quirk)
                    }
                }
                
                // Check for milestone
                let isMilestone = ArenaMilestoneReward.isMilestoneWave(wave)
                if isMilestone, let milestone = ArenaMilestoneReward.milestoneForWave(wave) {
                    // Claim milestone gold
                    character.gold += milestone.goldReward
                    run.totalGoldEarned += milestone.goldReward
                    
                    var claimed = milestone
                    claimed.claimed = true
                    run.milestoneRewards.append(claimed)
                }
                
                let narratives = room.encounterType.successNarratives
                let narrative = narratives.randomElement() ?? "Success!"
                
                let result = ArenaWaveResult(
                    wave: wave,
                    success: true,
                    playerPower: modifiedPower,
                    requiredPower: difficulty,
                    expEarned: expEarned,
                    goldEarned: goldEarned,
                    hpLost: 0,
                    narrativeText: narrative,
                    approachName: bestApproach?.name ?? "",
                    isMilestoneWave: isMilestone
                )
                run.waveResults.append(result)
                run.maxWaveReached = wave
                
                // Apply between-wave HP regen
                run.applyWaveRegen()
                hp = run.currentHP
                
            } else {
                // Failed wave — take damage (uncapped — scales with wave difficulty)
                let baseDamage = max(5, difficulty - modifiedPower)
                let riskMultiplier = bestApproach?.riskModifier ?? 1.0
                // Arena waves scale damage with wave number (later waves hit harder)
                let waveScaling = 1.0 + Double(wave - 1) * 0.05 // +5% per wave
                let damageTaken = Int(Double(baseDamage) * riskMultiplier * modifier.damageTakenMultiplier * waveScaling)
                hpLost = damageTaken
                hp = max(0, hp - hpLost)
                run.currentHP = hp
                
                let narratives = room.encounterType.failureNarratives
                let narrative = narratives.randomElement() ?? "Failed!"
                
                let isMilestone = false // Can't reach milestone on a failed wave
                
                let result = ArenaWaveResult(
                    wave: wave,
                    success: false,
                    playerPower: modifiedPower,
                    requiredPower: difficulty,
                    expEarned: 0,
                    goldEarned: 0,
                    hpLost: hpLost,
                    narrativeText: narrative,
                    approachName: bestApproach?.name ?? "",
                    isMilestoneWave: isMilestone
                )
                run.waveResults.append(result)
                run.maxWaveReached = max(run.maxWaveReached, wave)
                
                // Check if defeated
                if hp <= 0 {
                    run.status = .failed
                    run.completedAt = run.startedAt.addingTimeInterval(TimeInterval(wave * run.secondsPerWave))
                    character.arenaBestWave = max(character.arenaBestWave, run.maxWaveReached)
                    break
                }
                
                // Apply between-wave HP regen even after a failed (but non-lethal) wave
                run.applyWaveRegen()
                hp = run.currentHP
            }
        }
        
        // If survived all waves — mark as completed
        if run.status == .inProgress {
            run.status = .completed
            run.completedAt = run.startedAt.addingTimeInterval(TimeInterval(run.maxWaves * run.secondsPerWave))
            character.arenaBestWave = max(character.arenaBestWave, run.maxWaveReached)
        }
        
        // Set AFK timer based on waves resolved
        let wavesResolved = run.waveResults.count
        run.durationSeconds = wavesResolved * run.secondsPerWave
        run.completesAt = run.startedAt.addingTimeInterval(TimeInterval(run.durationSeconds))
        run.isResolved = true
    }
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
    var isMilestoneWave: Bool
    
    init(
        wave: Int,
        success: Bool,
        playerPower: Int,
        requiredPower: Int,
        expEarned: Int = 0,
        goldEarned: Int = 0,
        hpLost: Int = 0,
        narrativeText: String = "",
        approachName: String = "",
        isMilestoneWave: Bool = false
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
        self.isMilestoneWave = isMilestoneWave
    }
}

// MARK: - Arena Status (Legacy)

enum ArenaStatus: String, Codable {
    case inProgress = "In Progress"
    case completed = "Completed"
    case failed = "Failed"
}

// MARK: - Arena PVP Match

/// Local record of a PVP arena match
@Model
final class ArenaMatch {
    var id: UUID
    var characterID: UUID
    var opponentUserID: String
    var opponentName: String
    var opponentLevel: Int
    var opponentClass: String?
    var opponentHeroPower: Int
    var opponentRating: Int
    var attackerStance: String
    var defenderStance: String
    var roundsJSON: String
    var won: Bool
    var ratingChange: Int
    var ratingAfter: Int
    var arenaPointsEarned: Int
    var goldEarned: Int
    var expEarned: Int
    var isRevenge: Bool
    var stanceMatchup: String
    var createdAt: Date
    
    init(
        characterID: UUID,
        opponentUserID: String,
        opponentName: String,
        opponentLevel: Int,
        opponentClass: String?,
        opponentHeroPower: Int,
        opponentRating: Int,
        result: PVPMatchResult,
        ratingChange: Int,
        ratingAfter: Int,
        rewards: (arenaPoints: Int, gold: Int, exp: Int),
        isRevenge: Bool
    ) {
        self.id = UUID()
        self.characterID = characterID
        self.opponentUserID = opponentUserID
        self.opponentName = opponentName
        self.opponentLevel = opponentLevel
        self.opponentClass = opponentClass
        self.opponentHeroPower = opponentHeroPower
        self.opponentRating = opponentRating
        self.attackerStance = "none"
        self.defenderStance = "none"
        self.won = result.winnerIsAttacker
        self.ratingChange = ratingChange
        self.ratingAfter = ratingAfter
        self.arenaPointsEarned = rewards.arenaPoints
        self.goldEarned = rewards.gold
        self.expEarned = rewards.exp
        self.isRevenge = isRevenge
        self.stanceMatchup = "none"
        self.createdAt = Date()
        
        if let data = try? JSONEncoder().encode(result.rounds),
           let json = String(data: data, encoding: .utf8) {
            self.roundsJSON = json
        } else {
            self.roundsJSON = "[]"
        }
    }
    
    var decodedRounds: [PVPRoundResult] {
        guard let data = roundsJSON.data(using: .utf8),
              let rounds = try? JSONDecoder().decode([PVPRoundResult].self, from: data) else {
            return []
        }
        return rounds
    }
}

// MARK: - Arena Shop Item

struct ArenaShopItem: Identifiable {
    var id: String
    var name: String
    var itemDescription: String
    var category: ArenaShopCategory
    var cost: Int
    var icon: String
    var rarity: String?
    var equipmentBaseType: String?
    var equipmentSlot: EquipmentSlot?
    var isAvailable: Bool = true
    
    enum ArenaShopCategory: String, CaseIterable {
        case equipment = "Equipment"
        case consumables = "Consumables"
        case titles = "Titles"
    }
    
    static let allItems: [ArenaShopItem] = [
        // Equipment — Cape (Cloak)
        ArenaShopItem(id: "cape-rare", name: "Gladiator's Cape", itemDescription: "A battle-worn cape forged in the Arena. +5% crit damage in PVP.", category: .equipment, cost: 200, icon: "equip-cape-rare", rarity: "rare", equipmentBaseType: "cape", equipmentSlot: .cloak),
        ArenaShopItem(id: "cape-epic", name: "Gladiator's Cape", itemDescription: "An imposing cape earned through Arena glory. +5% crit damage in PVP.", category: .equipment, cost: 500, icon: "equip-cape-epic", rarity: "epic", equipmentBaseType: "cape", equipmentSlot: .cloak),
        ArenaShopItem(id: "cape-legendary", name: "Gladiator's Cape", itemDescription: "A legendary cape that strikes fear into all opponents.", category: .equipment, cost: 1200, icon: "equip-cape-legendary", rarity: "legendary", equipmentBaseType: "cape", equipmentSlot: .cloak),
        // Equipment — Brooch (Accessory)
        ArenaShopItem(id: "brooch-rare", name: "Champion's Brooch", itemDescription: "A brooch worn by Arena champions. Bolsters composure under pressure.", category: .equipment, cost: 200, icon: "equip-brooch-rare", rarity: "rare", equipmentBaseType: "brooch", equipmentSlot: .accessory),
        ArenaShopItem(id: "brooch-epic", name: "Champion's Brooch", itemDescription: "An ornate brooch that radiates Arena prestige.", category: .equipment, cost: 500, icon: "equip-brooch-epic", rarity: "epic", equipmentBaseType: "brooch", equipmentSlot: .accessory),
        ArenaShopItem(id: "brooch-legendary", name: "Champion's Brooch", itemDescription: "A legendary brooch coveted by the greatest fighters.", category: .equipment, cost: 1200, icon: "equip-brooch-legendary", rarity: "legendary", equipmentBaseType: "brooch", equipmentSlot: .accessory),
        // Equipment — Halberd (Weapon)
        ArenaShopItem(id: "halberd-rare", name: "Colosseum Halberd", itemDescription: "A fearsome polearm from the Arena armory.", category: .equipment, cost: 200, icon: "equip-halberd-rare", rarity: "rare", equipmentBaseType: "halberd", equipmentSlot: .weapon),
        ArenaShopItem(id: "halberd-epic", name: "Colosseum Halberd", itemDescription: "An imposing halberd that has felled countless Arena challengers.", category: .equipment, cost: 500, icon: "equip-halberd-epic", rarity: "epic", equipmentBaseType: "halberd", equipmentSlot: .weapon),
        ArenaShopItem(id: "halberd-legendary", name: "Colosseum Halberd", itemDescription: "A legendary weapon that carries the weight of a thousand victories.", category: .equipment, cost: 1200, icon: "equip-halberd-legendary", rarity: "legendary", equipmentBaseType: "halberd", equipmentSlot: .weapon),
        // Consumables
        ArenaShopItem(id: "arena-elixir", name: "Arena Elixir", itemDescription: "+10% ATK for your next 3 fights.", category: .consumables, cost: 50, icon: "flame.fill"),
        ArenaShopItem(id: "iron-tonic", name: "Iron Tonic", itemDescription: "+10% GUARD for your next 3 fights.", category: .consumables, cost: 50, icon: "shield.fill"),
        ArenaShopItem(id: "scouts-eye", name: "Scout's Eye", itemDescription: "Reveals opponent's full gear and quirks before you fight.", category: .consumables, cost: 75, icon: "eye.fill"),
        ArenaShopItem(id: "second-wind", name: "Second Wind", itemDescription: "+1 bonus daily Arena fight.", category: .consumables, cost: 100, icon: "wind"),
        // Titles
        ArenaShopItem(id: "title-gladiator", name: "Gladiator", itemDescription: "Display \"Gladiator\" as your Arena title.", category: .titles, cost: 100, icon: "text.badge.star"),
        ArenaShopItem(id: "title-veteran", name: "Arena Veteran", itemDescription: "Display \"Arena Veteran\" as your Arena title.", category: .titles, cost: 300, icon: "text.badge.star"),
        ArenaShopItem(id: "title-champion", name: "Pit Champion", itemDescription: "Display \"Pit Champion\" as your Arena title.", category: .titles, cost: 500, icon: "text.badge.star"),
        ArenaShopItem(id: "title-unbreakable", name: "The Unbreakable", itemDescription: "Display \"The Unbreakable\" as your Arena title.", category: .titles, cost: 1000, icon: "text.badge.star"),
    ]
}
