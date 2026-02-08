import Foundation
import SwiftUI
import SwiftData
import Combine

/// Core game logic engine
@MainActor
class GameEngine: ObservableObject {
    // MARK: - Published State
    
    @Published var currentCharacter: PlayerCharacter?
    @Published var activeMission: ActiveMission?
    @Published var pendingLevelUpRewards: [LevelUpReward] = []
    @Published var showLevelUpCelebration: Bool = false
    @Published var dailyQuests: [DailyQuest] = []
    
    // MARK: - Timers
    
    private var missionTimer: Timer?
    
    // MARK: - Initialization
    
    init() {
        // Restore persisted active mission (survives app restarts)
        activeMission = ActiveMission.loadPersisted()
        startMissionTimer()
    }
    
    deinit {
        missionTimer?.invalidate()
    }
    
    // MARK: - EXP Calculations
    
    /// Calculate EXP required to reach a specific level
    /// Uses exponential curve: base * (level ^ exponent)
    nonisolated static func expRequired(forLevel level: Int) -> Int {
        guard level > 1 else { return 0 }
        let base: Double = 100
        let exponent: Double = 1.5
        return Int(base * pow(Double(level - 1), exponent))
    }
    
    /// Calculate total EXP from level 1 to target level
    nonisolated static func totalExpToLevel(_ level: Int) -> Int {
        (1...level).reduce(0) { $0 + expRequired(forLevel: $1) }
    }
    
    // MARK: - Task Completion
    
    /// Partner co-task bonus multiplier (+15%)
    static let partnerBonusMultiplier: Double = 0.15
    
    /// Complete a task and award EXP + rewards (with verification, anti-cheat, and partner bonuses)
    func completeTask(
        _ task: GameTask,
        character: PlayerCharacter,
        bond: Bond? = nil,
        context: ModelContext? = nil,
        geofenceResult: GeofenceResult? = nil
    ) -> TaskCompletionResult {
        // Anti-cheat: check minimum timer
        let timerCheck = VerificationEngine.canComplete(task: task)
        
        // Anti-cheat: detect anomalies
        var anomalyFlags: [AnomalyFlag] = []
        if let ctx = context {
            anomalyFlags = VerificationEngine.detectAnomalies(characterID: character.id, context: ctx)
        }
        
        // If partner task, set pending confirmation (rewards held in escrow)
        if task.isFromPartner && bond != nil && !task.partnerConfirmed {
            task.pendingPartnerConfirmation = true
        }
        
        // Mark task complete
        task.complete(by: character.id)
        
        // Calculate combined verification multiplier
        let verificationMult = VerificationEngine.totalVerificationMultiplier(
            task: task,
            anomalyFlags: anomalyFlags,
            healthKitVerified: task.healthKitVerified,
            partnerConfirmed: task.partnerConfirmed,
            geofenceResult: geofenceResult
        )
        
        // Base rewards
        var baseEXP = Double(task.expReward)
        var baseGold = Double(task.goldReward)
        
        // Apply combined verification multiplier
        baseEXP *= verificationMult
        baseGold *= verificationMult
        
        var totalEXP = Int(baseEXP)
        var totalGold = Int(baseGold)
        
        // Streak bonus
        if character.currentStreak > 0 {
            let streakBonus = min(character.currentStreak * 5, 50) // Max 50% bonus
            totalEXP += (task.expReward * streakBonus) / 100
        }
        
        // Partner co-task bonus: +15% EXP/Gold + always +1 CHA
        var bonusStatGains: [(StatType, Int)] = []
        if task.isFromPartner {
            totalEXP += Int(Double(totalEXP) * GameEngine.partnerBonusMultiplier)
            totalGold += Int(Double(totalGold) * GameEngine.partnerBonusMultiplier)
            character.stats.increase(.charisma, by: 1)
            bonusStatGains.append((.charisma, 1))
        }
        
        // 10% chance for stat point gain from task category/focus
        if Int.random(in: 1...10) == 1 {
            let stat = task.bonusStat
            character.stats.increase(stat, by: 1)
            bonusStatGains.append((stat, 1))
        }
        
        // 5% RNG Luck roll: any task can award +1 Luck
        if Int.random(in: 1...20) == 1 {
            character.stats.increase(.luck, by: 1)
            bonusStatGains.append((.luck, 1))
        }
        
        // Bond bonuses (EXP/Gold multipliers from partnership perks)
        if let bond = bond {
            let bonuses = GameEngine.bondBonuses(bond: bond)
            totalEXP += Int(Double(totalEXP) * bonuses.expMultiplier)
            totalGold += Int(Double(totalGold) * bonuses.goldMultiplier)
        }
        
        // If pending partner confirmation, hold rewards in escrow (don't apply yet)
        if task.pendingPartnerConfirmation {
            return TaskCompletionResult(
                expGained: totalEXP,
                goldGained: totalGold,
                bonusStatGains: bonusStatGains,
                verificationMultiplier: verificationMult,
                levelUpRewards: [],
                didLevelUp: false,
                pendingPartnerConfirmation: true,
                anomalyFlags: anomalyFlags
            )
        }
        
        // Award EXP and handle level ups
        let levelUpRewards = character.gainEXP(totalEXP)
        
        // Award gold
        character.gold += totalGold
        
        // Update task count
        character.tasksCompleted += 1
        
        // Check achievements
        AchievementTracker.checkAll(character: character)
        
        // Check for level up celebration
        if !levelUpRewards.isEmpty {
            pendingLevelUpRewards = levelUpRewards
            showLevelUpCelebration = true
        }
        
        return TaskCompletionResult(
            expGained: totalEXP,
            goldGained: totalGold,
            bonusStatGains: bonusStatGains,
            verificationMultiplier: verificationMult,
            levelUpRewards: levelUpRewards,
            didLevelUp: !levelUpRewards.isEmpty,
            pendingPartnerConfirmation: false,
            anomalyFlags: anomalyFlags
        )
    }
    
    // MARK: - Partner Task Confirmation
    
    /// Confirm a partner's completed task and apply escrowed rewards
    func confirmPartnerTask(_ task: GameTask, character: PlayerCharacter, bond: Bond?) {
        guard task.pendingPartnerConfirmation else { return }
        
        task.pendingPartnerConfirmation = false
        task.partnerConfirmed = true
        task.partnerConfirmedAt = Date()
        
        // Recalculate rewards with partner confirmation bonus
        let verificationMult = VerificationEngine.totalVerificationMultiplier(
            task: task,
            anomalyFlags: [],
            healthKitVerified: task.healthKitVerified,
            partnerConfirmed: true,
            geofenceResult: nil
        )
        
        var totalEXP = Int(Double(task.expReward) * verificationMult)
        var totalGold = Int(Double(task.goldReward) * verificationMult)
        
        // Partner co-task bonus
        totalEXP += Int(Double(totalEXP) * GameEngine.partnerBonusMultiplier)
        totalGold += Int(Double(totalGold) * GameEngine.partnerBonusMultiplier)
        
        // Bond bonuses
        if let bond = bond {
            let bonuses = GameEngine.bondBonuses(bond: bond)
            totalEXP += Int(Double(totalEXP) * bonuses.expMultiplier)
            totalGold += Int(Double(totalGold) * bonuses.goldMultiplier)
        }
        
        // Apply rewards
        let levelUpRewards = character.gainEXP(totalEXP)
        character.gold += totalGold
        character.tasksCompleted += 1
        
        AchievementTracker.checkAll(character: character)
        
        if !levelUpRewards.isEmpty {
            pendingLevelUpRewards = levelUpRewards
            showLevelUpCelebration = true
        }
    }
    
    /// Dispute a partner's completed task
    func disputePartnerTask(_ task: GameTask, reason: String?) {
        task.pendingPartnerConfirmation = false
        task.partnerConfirmed = false
        task.partnerDisputeReason = reason ?? "Partner disputed this completion"
        task.status = .pending
        task.completedAt = nil
        task.completedBy = nil
    }
    
    /// Auto-confirm partner tasks that have been pending for more than 24 hours
    func autoConfirmExpiredPartnerTasks(character: PlayerCharacter, bond: Bond?, context: ModelContext) {
        let characterID = character.id
        let descriptor = FetchDescriptor<GameTask>(
            predicate: #Predicate<GameTask> { task in
                task.pendingPartnerConfirmation == true && task.completedBy == characterID
            }
        )
        
        guard let pendingTasks = try? context.fetch(descriptor) else { return }
        
        let twentyFourHoursAgo = Date().addingTimeInterval(-86400)
        for task in pendingTasks {
            if let completedAt = task.completedAt, completedAt < twentyFourHoursAgo {
                confirmPartnerTask(task, character: character, bond: bond)
            }
        }
    }
    
    // MARK: - HealthKit Integration
    
    /// Run HealthKit verification for a physical task
    func verifyWithHealthKit(task: GameTask) async {
        guard task.category == .physical else { return }
        
        let result = await HealthKitService.shared.verifyPhysicalActivity(focus: task.physicalFocus)
        task.healthKitVerified = result.verified
        task.healthKitActivitySummary = result.summary
    }
    
    // MARK: - Bond Bonuses
    
    /// Bond bonus multipliers derived from partnership perks
    struct BondBonuses {
        var expMultiplier: Double = 0.0
        var goldMultiplier: Double = 0.0
        var streakMultiplier: Double = 0.0
    }
    
    /// Calculate cumulative bond bonuses from unlocked perks
    static func bondBonuses(bond: Bond) -> BondBonuses {
        var bonuses = BondBonuses()
        let perks = bond.unlockedPerks
        
        if perks.contains(.quickLearner) {
            bonuses.expMultiplier += 0.05 * Double(bond.bondLevel / 5 + 1) // scales with level
        }
        if perks.contains(.fortuneSeeker) {
            bonuses.goldMultiplier += 0.05 * Double(bond.bondLevel / 5 + 1)
        }
        if perks.contains(.relentless) {
            bonuses.streakMultiplier += 0.02 * Double(bond.bondLevel / 5 + 1)
        }
        
        // Legendary bond: +50% all bonuses
        if perks.contains(.legendaryBond) {
            bonuses.expMultiplier *= 1.5
            bonuses.goldMultiplier *= 1.5
            bonuses.streakMultiplier *= 1.5
        }
        
        return bonuses
    }
    
    // MARK: - Mission Management
    
    /// Start an AFK training session (formerly mission)
    func startMission(_ mission: AFKMission, character: PlayerCharacter, hasActiveDungeonRun: Bool = false) -> Bool {
        guard mission.meetsRequirements(character: character) else {
            return false
        }
        
        guard activeMission == nil else {
            return false // Already have active training
        }
        
        guard !hasActiveDungeonRun else {
            return false // Cannot train while in a dungeon
        }
        
        let newMission = ActiveMission(mission: mission, characterID: character.id)
        activeMission = newMission
        newMission.persist()
        return true
    }
    
    /// Check and complete missions
    func checkMissionCompletion(mission: AFKMission, character: PlayerCharacter) -> MissionCompletionResult? {
        guard let active = activeMission,
              active.isComplete,
              !active.rewardClaimed else {
            return nil
        }
        
        // Calculate success
        let successRate = mission.calculateSuccessRate(with: character.effectiveStats)
        let roll = Double.random(in: 0...1)
        let success = roll <= successRate
        
        active.wasSuccessful = success
        
        if success {
            // Capture before state for animated reward screen
            let previousLevel = character.level
            let expProgressBefore = character.levelProgress
            
            // Calculate rewards
            let expReward = mission.expReward
            let goldReward = mission.goldReward
            
            // Apply rewards
            let levelUpRewards = character.gainEXP(expReward)
            character.gold += goldReward
            
            // Capture after state
            let newLevel = character.level
            let expProgressAfter = character.levelProgress
            let statPointsGained = levelUpRewards.filter { $0 == .statPoint }.count
            
            active.earnedEXP = expReward
            active.earnedGold = goldReward
            
            // Stat reward from training type
            var statGained: (stat: StatType, amount: Int)? = nil
            let primaryStat = mission.missionType.primaryStat
            if Double.random(in: 0...1) <= mission.statRewardChance {
                // Award +1 to the training's primary stat
                character.stats.increase(primaryStat, by: 1)
                statGained = (stat: primaryStat, amount: 1)
            }
            
            // Check for equipment drop
            var droppedItemName: String? = nil
            if mission.canDropEquipment {
                let dropChance = mission.itemDropChance(luck: character.effectiveStats.luck)
                if Double.random(in: 0...1) <= dropChance {
                    let equipment = LootGenerator.generateEquipment(
                        tier: mission.dropTier,
                        luck: character.effectiveStats.luck
                    )
                    droppedItemName = equipment.name
                    active.earnedItemID = equipment.name
                }
            } else if !mission.possibleDrops.isEmpty {
                // Legacy drop logic for string-based drops
                let dropChance = 0.1 + (Double(character.effectiveStats.luck) * 0.01)
                if Double.random(in: 0...1) <= dropChance {
                    droppedItemName = mission.possibleDrops.randomElement()
                    active.earnedItemID = droppedItemName
                }
            }
            
            active.rewardClaimed = true
            
            // Check achievements after mission
            AchievementTracker.checkAll(character: character)
            
            // NOTE: Don't trigger separate level-up celebration here;
            // the MissionCompletionView handles it inline with animations.
            
            // Clear active mission and persisted data
            activeMission = nil
            ActiveMission.clearPersisted()
            
            return MissionCompletionResult(
                success: true,
                expGained: expReward,
                goldGained: goldReward,
                itemDropped: droppedItemName,
                levelUpRewards: levelUpRewards,
                previousLevel: previousLevel,
                newLevel: newLevel,
                expProgressBefore: expProgressBefore,
                expProgressAfter: expProgressAfter,
                statPointsGained: statPointsGained,
                statGained: statGained
            )
        } else {
            // Mission failed
            active.rewardClaimed = true
            activeMission = nil
            ActiveMission.clearPersisted()
            
            return MissionCompletionResult(
                success: false,
                expGained: 0,
                goldGained: 0,
                itemDropped: nil,
                levelUpRewards: [],
                previousLevel: character.level,
                newLevel: character.level,
                expProgressBefore: character.levelProgress,
                expProgressAfter: character.levelProgress,
                statPointsGained: 0,
                statGained: nil
            )
        }
    }
    
    /// Start timer to check mission completion
    private func startMissionTimer() {
        missionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.objectWillChange.send()
            }
        }
    }
    
    // MARK: - Streak Management
    
    /// Update daily streak
    func updateStreak(for character: PlayerCharacter, completedTaskToday: Bool) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastActive = calendar.startOfDay(for: character.lastActiveAt)
        
        let daysDifference = calendar.dateComponents([.day], from: lastActive, to: today).day ?? 0
        
        if completedTaskToday {
            if daysDifference == 0 {
                // Same day, streak continues
            } else if daysDifference == 1 {
                // Next day, increment streak
                character.currentStreak += 1
                character.longestStreak = max(character.longestStreak, character.currentStreak)
            } else {
                // Streak broken, reset
                character.currentStreak = 1
            }
        } else if daysDifference > 1 {
            // Missed a day, reset streak
            character.currentStreak = 0
        }
        
        character.lastActiveAt = Date()
    }
    
    // MARK: - Character Creation
    
    /// Create a new character with class, zodiac, and stat allocation
    func createCharacter(
        name: String,
        characterClass: CharacterClass,
        zodiacSign: ZodiacSign,
        bonusStats: Stats,
        avatarIcon: String,
        avatarImageData: Data? = nil
    ) -> PlayerCharacter {
        // Start with the class base stats + bonus allocation
        let baseStats = characterClass.baseStats
        let finalStats = Stats(
            strength: baseStats.strength + bonusStats.strength,
            wisdom: baseStats.wisdom + bonusStats.wisdom,
            charisma: baseStats.charisma + bonusStats.charisma,
            dexterity: baseStats.dexterity + bonusStats.dexterity,
            luck: baseStats.luck + bonusStats.luck
        )
        
        let character = PlayerCharacter(name: name, stats: finalStats)
        character.characterClass = characterClass
        character.zodiacSign = zodiacSign
        character.avatarIcon = avatarIcon
        character.avatarImageData = avatarImageData
        
        // Initialize achievements
        AchievementTracker.initializeAchievements(for: character)
        
        currentCharacter = character
        return character
    }
    
    // MARK: - Class Evolution
    
    /// Check if a character is eligible for class evolution
    func canEvolve(character: PlayerCharacter, to advancedClass: CharacterClass) -> Bool {
        guard advancedClass.tier == .advanced else { return false }
        guard character.characterClass == advancedClass.evolvesFrom else { return false }
        guard character.level >= advancedClass.evolutionLevelRequirement else { return false }
        
        if let requiredStat = advancedClass.evolutionStat {
            return character.effectiveStats.value(for: requiredStat) >= advancedClass.evolutionStatThreshold
        }
        return true
    }
    
    /// Evolve a character to an advanced class
    func evolveClass(to advancedClass: CharacterClass, for character: PlayerCharacter) -> Bool {
        guard canEvolve(character: character, to: advancedClass) else { return false }
        
        // Update class
        character.characterClass = advancedClass
        
        return true
    }
    
    // MARK: - Daily Quests
    
    /// Check if daily quests need refreshing and generate new ones if needed
    func checkAndRefreshDailyQuests(for character: PlayerCharacter, context: ModelContext) {
        let today = Calendar.current.startOfDay(for: Date())
        let characterID = character.id
        
        // Fetch existing quests for today using a computed filter (no bare enum in #Predicate)
        let descriptor = FetchDescriptor<DailyQuest>(
            predicate: #Predicate<DailyQuest> { quest in
                quest.characterID == characterID && quest.generatedDate == today
            }
        )
        
        if let existing = try? context.fetch(descriptor), !existing.isEmpty {
            dailyQuests = existing
            return
        }
        
        // Delete old quests
        let oldDescriptor = FetchDescriptor<DailyQuest>(
            predicate: #Predicate<DailyQuest> { quest in
                quest.characterID == characterID
            }
        )
        if let oldQuests = try? context.fetch(oldDescriptor) {
            for old in oldQuests {
                context.delete(old)
            }
        }
        
        // Generate new quests
        let newQuests = DailyQuestPool.generateQuests(for: character)
        for quest in newQuests {
            context.insert(quest)
        }
        
        // Check streak quest auto-completion
        if character.currentStreak > 0 {
            for quest in newQuests where quest.questType == .maintainStreak && !quest.isBonusQuest {
                quest.incrementProgress(by: 1)
            }
        }
        
        dailyQuests = newQuests
        try? context.save()
    }
    
    /// Update daily quest progress after a task is completed
    func updateDailyQuestProgress(
        task: GameTask,
        expGained: Int,
        goldGained: Int,
        character: PlayerCharacter,
        context: ModelContext
    ) {
        let today = Calendar.current.startOfDay(for: Date())
        let characterID = character.id
        
        let descriptor = FetchDescriptor<DailyQuest>(
            predicate: #Predicate<DailyQuest> { quest in
                quest.characterID == characterID && quest.generatedDate == today
            }
        )
        
        guard let quests = try? context.fetch(descriptor) else { return }
        
        for quest in quests where !quest.isBonusQuest && !quest.isCompleted {
            switch quest.questType {
            case .completeTasks:
                quest.incrementProgress()
            case .completeCategory:
                if quest.questParam == task.category.rawValue {
                    quest.incrementProgress()
                }
            case .earnEXP:
                quest.incrementProgress(by: expGained)
            case .earnGold:
                quest.incrementProgress(by: goldGained)
            case .maintainStreak:
                if character.currentStreak > 0 {
                    quest.incrementProgress()
                }
            default:
                break
            }
        }
        
        // Check bonus quest
        updateBonusQuest(quests: quests)
        
        dailyQuests = quests
        try? context.save()
    }
    
    /// Update daily quest progress after starting a mission
    func updateDailyQuestProgressForMission(character: PlayerCharacter, context: ModelContext) {
        let today = Calendar.current.startOfDay(for: Date())
        let characterID = character.id
        
        let descriptor = FetchDescriptor<DailyQuest>(
            predicate: #Predicate<DailyQuest> { quest in
                quest.characterID == characterID && quest.generatedDate == today
            }
        )
        
        guard let quests = try? context.fetch(descriptor) else { return }
        
        for quest in quests where !quest.isBonusQuest && !quest.isCompleted {
            if quest.questType == .startMission {
                quest.incrementProgress()
            }
        }
        
        updateBonusQuest(quests: quests)
        dailyQuests = quests
        try? context.save()
    }
    
    /// Update daily quest progress after clearing dungeon rooms
    func updateDailyQuestProgressForDungeonRoom(
        roomCount: Int,
        expGained: Int,
        goldGained: Int,
        character: PlayerCharacter,
        context: ModelContext
    ) {
        let today = Calendar.current.startOfDay(for: Date())
        let characterID = character.id
        
        let descriptor = FetchDescriptor<DailyQuest>(
            predicate: #Predicate<DailyQuest> { quest in
                quest.characterID == characterID && quest.generatedDate == today
            }
        )
        
        guard let quests = try? context.fetch(descriptor) else { return }
        
        for quest in quests where !quest.isBonusQuest && !quest.isCompleted {
            switch quest.questType {
            case .clearDungeonRooms:
                quest.incrementProgress(by: roomCount)
            case .earnEXP:
                quest.incrementProgress(by: expGained)
            case .earnGold:
                quest.incrementProgress(by: goldGained)
            default:
                break
            }
        }
        
        updateBonusQuest(quests: quests)
        dailyQuests = quests
        try? context.save()
    }
    
    /// Claim reward for a completed daily quest
    func claimDailyQuestReward(_ quest: DailyQuest, character: PlayerCharacter, context: ModelContext) {
        guard quest.isCompleted && !quest.isClaimed else { return }
        
        quest.isClaimed = true
        
        let levelUpRewards = character.gainEXP(quest.expReward)
        character.gold += quest.goldReward
        
        if !levelUpRewards.isEmpty {
            pendingLevelUpRewards = levelUpRewards
            showLevelUpCelebration = true
        }
        
        // Update EXP/Gold quests with the quest reward itself
        let today = Calendar.current.startOfDay(for: Date())
        let characterID = character.id
        
        let descriptor = FetchDescriptor<DailyQuest>(
            predicate: #Predicate<DailyQuest> { q in
                q.characterID == characterID && q.generatedDate == today
            }
        )
        
        if let quests = try? context.fetch(descriptor) {
            for q in quests where !q.isBonusQuest && !q.isCompleted && q.id != quest.id {
                if q.questType == .earnEXP {
                    q.incrementProgress(by: quest.expReward)
                } else if q.questType == .earnGold {
                    q.incrementProgress(by: quest.goldReward)
                }
            }
            updateBonusQuest(quests: quests)
            dailyQuests = quests
        }
        
        try? context.save()
    }
    
    /// Check if all 3 regular quests are complete and update bonus quest
    private func updateBonusQuest(quests: [DailyQuest]) {
        let regularQuests = quests.filter { !$0.isBonusQuest }
        let completedCount = regularQuests.filter { $0.isCompleted }.count
        
        if let bonus = quests.first(where: { $0.isBonusQuest }) {
            bonus.currentValue = completedCount
            if completedCount >= 3 && !bonus.isCompleted {
                bonus.isCompleted = true
            }
        }
    }
    
    // MARK: - Bond System
    
    /// Bond EXP awarded for completing a partner-assigned task
    static let bondEXPForPartnerTask: Int = 15
    
    /// Bond EXP awarded for completing a duty board task
    static let bondEXPForDutyBoardTask: Int = 8
    
    /// Bond EXP awarded for sending kudos
    static let bondEXPForKudos: Int = 3
    
    /// Bond EXP awarded for sending a nudge
    static let bondEXPForNudge: Int = 1
    
    /// Bond EXP awarded for co-op dungeon completion
    static let bondEXPForCoopDungeon: Int = 25
    
    /// Bond EXP awarded for dual streak day
    static let bondEXPForDualStreak: Int = 10
    
    /// Complete a partner-assigned task and award bond EXP
    func completePartnerTask(_ task: GameTask, character: PlayerCharacter, bond: Bond) -> TaskCompletionResult {
        let result = completeTask(task, character: character, bond: bond)
        
        // Award bond EXP
        var bondEXP = GameEngine.bondEXPForPartnerTask
        
        // Bond EXP Boost perk (+10%)
        if bond.unlockedPerks.contains(.bondEXPBoost) {
            bondEXP = Int(Double(bondEXP) * 1.1)
        }
        
        bond.gainBondEXP(bondEXP)
        bond.partnerTasksCompleted += 1
        
        // Track daily tasks
        character.checkDailyReset()
        character.tasksCompletedToday += 1
        
        return result
    }
    
    /// Claim a duty board task and award bond EXP
    func claimDutyBoardTask(_ task: GameTask, character: PlayerCharacter, bond: Bond) {
        task.assignedTo = character.id
        task.isOnDutyBoard = false
        
        var bondEXP = GameEngine.bondEXPForDutyBoardTask
        if bond.unlockedPerks.contains(.bondEXPBoost) {
            bondEXP = Int(Double(bondEXP) * 1.1)
        }
        
        bond.gainBondEXP(bondEXP)
        bond.dutyBoardTasksClaimed += 1
    }
    
    /// Send a kudos interaction
    func sendKudos(from character: PlayerCharacter, bond: Bond, message: String?) -> PartnerInteraction {
        let interaction = PartnerInteraction(
            type: .kudos,
            message: message ?? InteractionType.kudos.defaultMessage,
            fromCharacterID: character.id
        )
        
        var bondEXP = GameEngine.bondEXPForKudos
        if bond.unlockedPerks.contains(.bondEXPBoost) {
            bondEXP = Int(Double(bondEXP) * 1.1)
        }
        
        bond.gainBondEXP(bondEXP)
        bond.kudosSent += 1
        
        return interaction
    }
    
    /// Send a nudge interaction
    func sendNudge(from character: PlayerCharacter, bond: Bond, message: String?) -> PartnerInteraction {
        let interaction = PartnerInteraction(
            type: .nudge,
            message: message ?? InteractionType.nudge.defaultMessage,
            fromCharacterID: character.id
        )
        
        var bondEXP = GameEngine.bondEXPForNudge
        if bond.unlockedPerks.contains(.bondEXPBoost) {
            bondEXP = Int(Double(bondEXP) * 1.1)
        }
        
        bond.gainBondEXP(bondEXP)
        bond.nudgesSent += 1
        
        return interaction
    }
    
    // MARK: - Meditation
    
    /// Perform daily meditation for EXP and gold
    func meditate(character: PlayerCharacter) -> MeditationResult? {
        guard !character.hasMeditatedToday else { return nil }
        
        character.checkMeditationStreak()
        
        let expReward = character.meditationExpReward
        let goldReward = character.meditationGoldReward
        
        // Update streak
        if let lastDate = character.lastMeditationDate {
            let daysDiff = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: lastDate), to: Calendar.current.startOfDay(for: Date())).day ?? 0
            if daysDiff == 1 {
                character.meditationStreak += 1
            } else if daysDiff > 1 {
                character.meditationStreak = 1
            }
        } else {
            character.meditationStreak = 1
        }
        
        character.lastMeditationDate = Date()
        
        // Award rewards
        let levelUpRewards = character.gainEXP(expReward)
        character.gold += goldReward
        
        if !levelUpRewards.isEmpty {
            pendingLevelUpRewards = levelUpRewards
            showLevelUpCelebration = true
        }
        
        return MeditationResult(
            expGained: expReward,
            goldGained: goldReward,
            streak: character.meditationStreak,
            levelUpRewards: levelUpRewards
        )
    }
    
    // MARK: - Raid Boss
    
    /// Attack the raid boss after completing a task
    func attackRaidBoss(
        boss: WeeklyRaidBoss,
        character: PlayerCharacter,
        taskDescription: String
    ) -> RaidAttackResult? {
        guard boss.isActive else { return nil }
        guard !boss.hasReachedDailyCap(playerID: character.id) else { return nil }
        
        let damage = WeeklyRaidBoss.calculateDamage(for: character)
        
        let attack = RaidAttack(
            playerName: character.name,
            playerID: character.id,
            damage: damage,
            sourceDescription: taskDescription
        )
        
        boss.takeDamage(damage, from: attack)
        
        return RaidAttackResult(
            damage: damage,
            bossDefeated: boss.isDefeated,
            remainingHP: boss.currentHP,
            maxHP: boss.maxHP
        )
    }
    
    /// Claim raid boss defeat rewards
    func claimRaidBossRewards(
        boss: WeeklyRaidBoss,
        character: PlayerCharacter,
        bond: Bond?,
        context: ModelContext
    ) {
        guard boss.isDefeated && !boss.rewardsClaimed else { return }
        
        let expReward = WeeklyRaidBoss.expReward(tier: boss.tier)
        let goldReward = WeeklyRaidBoss.goldReward(tier: boss.tier)
        let bondExpReward = WeeklyRaidBoss.bondExpReward(tier: boss.tier)
        
        let levelUpRewards = character.gainEXP(expReward)
        character.gold += goldReward
        
        // Bond EXP if partnered
        if let bond = bond {
            bond.gainBondEXP(bondExpReward)
        }
        
        // Chance for equipment drop based on tier
        let dropChance = 0.3 + Double(boss.tier) * 0.1
        if Double.random(in: 0...1) <= dropChance {
            let loot = LootGenerator.generateEquipment(tier: boss.tier, luck: character.effectiveStats.luck)
            loot.ownerID = character.id
            context.insert(loot)
        }
        
        boss.rewardsClaimed = true
        
        if !levelUpRewards.isEmpty {
            pendingLevelUpRewards = levelUpRewards
            showLevelUpCelebration = true
        }
    }
    
    // MARK: - Forge
    
    /// Salvage an equipment item for forge shards
    func salvageEquipment(_ item: Equipment, character: PlayerCharacter, context: ModelContext) -> Int {
        let shards = shardsForRarity(item.rarity)
        character.forgeShards += shards
        
        // Unequip if needed
        if item.isEquipped {
            switch item.slot {
            case .weapon:
                if character.equipment.weapon?.id == item.id {
                    character.equipment.weapon = nil
                }
            case .armor:
                if character.equipment.armor?.id == item.id {
                    character.equipment.armor = nil
                }
            case .accessory:
                if character.equipment.accessory?.id == item.id {
                    character.equipment.accessory = nil
                }
            }
        }
        
        context.delete(item)
        return shards
    }
    
    /// Craft a random equipment of the given rarity
    func craftEquipment(rarity: ItemRarity, character: PlayerCharacter, context: ModelContext) -> Equipment? {
        guard character.level >= 10 else { return nil }
        
        let cost = shardCostForRarity(rarity)
        guard character.forgeShards >= cost else { return nil }
        
        character.forgeShards -= cost
        
        // Generate equipment at the rarity level
        let tierForRarity: Int
        switch rarity {
        case .common: tierForRarity = 1
        case .uncommon: tierForRarity = 2
        case .rare: tierForRarity = 3
        case .epic: tierForRarity = 4
        case .legendary: tierForRarity = 5
        }
        
        let item = LootGenerator.generateEquipment(tier: tierForRarity, luck: character.effectiveStats.luck)
        // Force the desired rarity
        item.ownerID = character.id
        context.insert(item)
        
        return item
    }
    
    /// Shards gained from salvaging an item
    nonisolated func shardsForRarity(_ rarity: ItemRarity) -> Int {
        switch rarity {
        case .common: return 1
        case .uncommon: return 2
        case .rare: return 4
        case .epic: return 8
        case .legendary: return 16
        }
    }
    
    /// Shards cost to craft at a rarity
    nonisolated func shardCostForRarity(_ rarity: ItemRarity) -> Int {
        switch rarity {
        case .common: return 3
        case .uncommon: return 8
        case .rare: return 15
        case .epic: return 30
        case .legendary: return 0 // Cannot craft legendary
        }
    }
    
    // MARK: - Material Drops
    
    /// Award crafting materials after completing an IRL task
    /// This is the key bridge: real-life tasks earn Essence + chance of bonus material
    func awardMaterialsForTask(
        task: GameTask,
        character: PlayerCharacter,
        context: ModelContext
    ) {
        let characterID = character.id
        
        // Essence scales with verification type (verified tasks give more)
        let essenceAmount: Int
        switch task.verificationType {
        case .none: essenceAmount = 1
        case .photo: essenceAmount = 2
        case .location: essenceAmount = 2
        case .photoAndLocation: essenceAmount = 3
        }
        
        addMaterial(.essence, rarity: .common, amount: essenceAmount, characterID: characterID, context: context)
        
        // 20% chance of a random common material
        if Int.random(in: 1...5) == 1 {
            let bonusTypes: [MaterialType] = [.ore, .crystal, .hide, .herb]
            if let bonusType = bonusTypes.randomElement() {
                addMaterial(bonusType, rarity: .common, amount: 1, characterID: characterID, context: context)
            }
        }
    }
    
    /// Award crafting materials after clearing a dungeon room
    func awardMaterialsForDungeonRoom(
        encounterType: EncounterType,
        dungeonTier: Int,
        character: PlayerCharacter,
        context: ModelContext
    ) {
        let characterID = character.id
        let rarity = rarityForDungeonTier(dungeonTier)
        
        let materialType: MaterialType
        switch encounterType {
        case .combat:
            materialType = .ore
        case .puzzle:
            materialType = .crystal
        case .trap, .boss:
            materialType = .hide
        case .treasure:
            // Treasure rooms give a random material
            materialType = [MaterialType.ore, .crystal, .hide].randomElement() ?? .ore
        }
        
        let amount = encounterType == .boss ? 2 : 1
        addMaterial(materialType, rarity: rarity, amount: amount, characterID: characterID, context: context)
    }
    
    /// Award crafting materials after completing a mission
    func awardMaterialsForMission(
        missionRarity: MissionRarity,
        character: PlayerCharacter,
        context: ModelContext
    ) {
        let characterID = character.id
        let amount: Int
        let itemRarity: ItemRarity
        
        switch missionRarity {
        case .common:
            amount = 1
            itemRarity = .common
        case .uncommon:
            amount = 1
            itemRarity = .uncommon
        case .rare:
            amount = 2
            itemRarity = .rare
        case .epic:
            amount = 3
            itemRarity = .rare  // cap at rare for herbs
        case .legendary:
            amount = 5
            itemRarity = .rare  // cap at rare for herbs
        }
        
        addMaterial(.herb, rarity: itemRarity, amount: amount, characterID: characterID, context: context)
    }
    
    /// Award fragments from dismantling equipment
    func awardFragmentsForDismantle(
        itemRarity: ItemRarity,
        character: PlayerCharacter,
        context: ModelContext
    ) -> Int {
        let amount: Int
        switch itemRarity {
        case .common: amount = 1
        case .uncommon: amount = 2
        case .rare: amount = 4
        case .epic: amount = 8
        case .legendary: amount = 15
        }
        
        addMaterial(.fragment, rarity: .common, amount: amount, characterID: character.id, context: context)
        return amount
    }
    
    // MARK: - Material Helpers
    
    /// Add a quantity of a material to the character's stash (creates or increments)
    private func addMaterial(
        _ type: MaterialType,
        rarity: ItemRarity,
        amount: Int,
        characterID: UUID,
        context: ModelContext
    ) {
        // Fetch all materials for this character, then filter in memory
        // (avoid .rawValue keypath inside #Predicate — it can hang SwiftData)
        let descriptor = FetchDescriptor<CraftingMaterial>(
            predicate: #Predicate<CraftingMaterial> { mat in
                mat.characterID == characterID
            }
        )
        
        let allMats = (try? context.fetch(descriptor)) ?? []
        if let existing = allMats.first(where: { $0.materialType == type && $0.rarity == rarity }) {
            existing.quantity += amount
        } else {
            let newMat = CraftingMaterial(
                materialType: type,
                rarity: rarity,
                quantity: amount,
                characterID: characterID
            )
            context.insert(newMat)
        }
        
        try? context.save()
    }
    
    /// Get current material count for a character
    func materialCount(
        _ type: MaterialType,
        rarity: ItemRarity? = nil,
        characterID: UUID,
        context: ModelContext
    ) -> Int {
        // Fetch all materials for this character, then filter in memory
        // (avoid .rawValue keypath inside #Predicate — it can hang SwiftData)
        let descriptor = FetchDescriptor<CraftingMaterial>(
            predicate: #Predicate<CraftingMaterial> { mat in
                mat.characterID == characterID
            }
        )
        
        guard let allMats = try? context.fetch(descriptor) else { return 0 }
        let filtered: [CraftingMaterial]
        if let rarity = rarity {
            filtered = allMats.filter { $0.materialType == type && $0.rarity == rarity }
        } else {
            filtered = allMats.filter { $0.materialType == type }
        }
        return filtered.reduce(0) { $0 + $1.quantity }
    }
    
    /// Get all materials for a character
    func allMaterials(characterID: UUID, context: ModelContext) -> [CraftingMaterial] {
        let descriptor = FetchDescriptor<CraftingMaterial>(
            predicate: #Predicate<CraftingMaterial> { mat in
                mat.characterID == characterID
            }
        )
        return (try? context.fetch(descriptor)) ?? []
    }
    
    /// Map dungeon tier to material rarity
    private func rarityForDungeonTier(_ tier: Int) -> ItemRarity {
        switch tier {
        case 1: return .common
        case 2: return .uncommon
        case 3: return .rare
        case 4: return .epic
        default: return tier >= 5 ? .legendary : .common
        }
    }
    
    /// Helper to clamp rarity (Codable enum doesn't have Comparable)
    private func lowerRarity(_ a: ItemRarity, _ b: ItemRarity) -> ItemRarity {
        let order: [ItemRarity] = [.common, .uncommon, .rare, .epic, .legendary]
        let aIdx = order.firstIndex(of: a) ?? 0
        let bIdx = order.firstIndex(of: b) ?? 0
        return order[Swift.min(aIdx, bIdx)]
    }
    
    // MARK: - Forge Crafting (Enhanced)
    
    /// Check if the character has enough materials for a forge recipe
    func canAffordRecipe(_ recipe: ForgeRecipe, character: PlayerCharacter, context: ModelContext) -> Bool {
        let charID = character.id
        
        // Check gold
        if character.gold < recipe.goldCost { return false }
        
        // Check essence
        let essenceCount = materialCount(.essence, characterID: charID, context: context)
        if essenceCount < recipe.essenceCost { return false }
        
        // Check fragments
        if recipe.fragmentCost > 0 {
            let fragmentCount = materialCount(.fragment, characterID: charID, context: context)
            if fragmentCount < recipe.fragmentCost { return false }
        }
        
        // Check general materials (ore + crystal + hide combined, at minimum rarity)
        let generalCount = countGeneralMaterials(
            minRarity: recipe.materialMinRarity,
            characterID: charID,
            context: context
        )
        if generalCount < recipe.materialCost { return false }
        
        return true
    }
    
    /// Consume materials for a forge recipe and craft a piece of equipment
    func forgeEquipment(
        slot: EquipmentSlot,
        recipe: ForgeRecipe,
        character: PlayerCharacter,
        context: ModelContext
    ) -> Equipment? {
        guard canAffordRecipe(recipe, character: character, context: context) else { return nil }
        
        let charID = character.id
        
        // Deduct gold
        character.gold -= recipe.goldCost
        
        // Deduct essence
        deductMaterial(.essence, amount: recipe.essenceCost, characterID: charID, context: context)
        
        // Deduct fragments
        if recipe.fragmentCost > 0 {
            deductMaterial(.fragment, amount: recipe.fragmentCost, characterID: charID, context: context)
        }
        
        // Deduct general materials
        deductGeneralMaterials(
            amount: recipe.materialCost,
            minRarity: recipe.materialMinRarity,
            characterID: charID,
            context: context
        )
        
        // Generate the equipment
        let item = LootGenerator.generateEquipment(
            tier: recipe.tier,
            luck: character.effectiveStats.luck,
            preferredSlot: slot
        )
        item.ownerID = charID
        context.insert(item)
        
        try? context.save()
        return item
    }
    
    /// Count general materials (ore + crystal + hide) at or above a minimum rarity
    private func countGeneralMaterials(
        minRarity: ItemRarity,
        characterID: UUID,
        context: ModelContext
    ) -> Int {
        let generalTypes: [MaterialType] = [.ore, .crystal, .hide]
        let validRarities = validRaritiesAtOrAbove(minRarity)
        
        var total = 0
        for type in generalTypes {
            for rarity in validRarities {
                total += materialCount(type, rarity: rarity, characterID: characterID, context: context)
            }
        }
        return total
    }
    
    /// Deduct general materials, spending lowest rarity first
    private func deductGeneralMaterials(
        amount: Int,
        minRarity: ItemRarity,
        characterID: UUID,
        context: ModelContext
    ) {
        let generalTypes: [MaterialType] = [.ore, .crystal, .hide]
        let validRarities = validRaritiesAtOrAbove(minRarity)
        var remaining = amount
        
        for rarity in validRarities {
            for type in generalTypes {
                if remaining <= 0 { return }
                let available = materialCount(type, rarity: rarity, characterID: characterID, context: context)
                if available > 0 {
                    let toDeduct = Swift.min(available, remaining)
                    deductMaterial(type, rarity: rarity, amount: toDeduct, characterID: characterID, context: context)
                    remaining -= toDeduct
                }
            }
        }
    }
    
    /// Deduct a specific material by type (common rarity default)
    private func deductMaterial(
        _ type: MaterialType,
        rarity: ItemRarity = .common,
        amount: Int,
        characterID: UUID,
        context: ModelContext
    ) {
        // Fetch all materials for this character, then filter in memory
        // (avoid .rawValue keypath inside #Predicate — it can hang SwiftData)
        let descriptor = FetchDescriptor<CraftingMaterial>(
            predicate: #Predicate<CraftingMaterial> { mat in
                mat.characterID == characterID
            }
        )
        
        let allMats = (try? context.fetch(descriptor)) ?? []
        if let existing = allMats.first(where: { $0.materialType == type && $0.rarity == rarity }) {
            existing.quantity = max(0, existing.quantity - amount)
        }
    }
    
    /// Deduct a specific material (any rarity)
    private func deductMaterial(
        _ type: MaterialType,
        amount: Int,
        characterID: UUID,
        context: ModelContext
    ) {
        // Fetch all materials for this character, then filter in memory
        // (avoid .rawValue keypath inside #Predicate — it can hang SwiftData)
        let descriptor = FetchDescriptor<CraftingMaterial>(
            predicate: #Predicate<CraftingMaterial> { mat in
                mat.characterID == characterID
            }
        )
        
        guard let stacks = try? context.fetch(descriptor) else { return }
        let filtered = stacks.filter { $0.materialType == type }
        var remaining = amount
        for stack in filtered.sorted(by: { rarityOrder($0.rarity) < rarityOrder($1.rarity) }) {
            if remaining <= 0 { break }
            let toDeduct = Swift.min(stack.quantity, remaining)
            stack.quantity -= toDeduct
            remaining -= toDeduct
        }
    }
    
    /// Rarity ordering for spending lowest first
    private nonisolated func rarityOrder(_ rarity: ItemRarity) -> Int {
        switch rarity {
        case .common: return 0
        case .uncommon: return 1
        case .rare: return 2
        case .epic: return 3
        case .legendary: return 4
        }
    }
    
    /// Valid rarities at or above a minimum
    private func validRaritiesAtOrAbove(_ minRarity: ItemRarity) -> [ItemRarity] {
        let all: [ItemRarity] = [.common, .uncommon, .rare, .epic, .legendary]
        let minIdx = all.firstIndex(of: minRarity) ?? 0
        return Array(all[minIdx...])
    }
    
    // MARK: - Store Purchase
    
    /// Buy equipment from the store
    func buyEquipment(_ item: Equipment, character: PlayerCharacter, context: ModelContext) -> Bool {
        let price = ShopGenerator.priceForEquipment(item)
        guard character.gold >= price else { return false }
        
        character.gold -= price
        
        // Create a copy for the character's inventory
        let purchased = Equipment(
            name: item.name,
            description: item.itemDescription,
            slot: item.slot,
            rarity: item.rarity,
            primaryStat: item.primaryStat,
            statBonus: item.statBonus,
            levelRequirement: item.levelRequirement,
            secondaryStat: item.secondaryStat,
            secondaryStatBonus: item.secondaryStatBonus,
            ownerID: character.id
        )
        context.insert(purchased)
        try? context.save()
        return true
    }
    
    /// Buy a consumable from the store
    func buyConsumable(_ template: ConsumableTemplate, character: PlayerCharacter, context: ModelContext) -> Bool {
        // Check gold cost
        if template.goldCost > 0 && character.gold < template.goldCost { return false }
        
        character.gold -= template.goldCost
        
        let consumable = template.toConsumable(characterID: character.id)
        context.insert(consumable)
        try? context.save()
        return true
    }
    
    /// Send a challenge interaction
    func sendChallenge(from character: PlayerCharacter, bond: Bond, message: String?) -> PartnerInteraction {
        let interaction = PartnerInteraction(
            type: .challenge,
            message: message ?? InteractionType.challenge.defaultMessage,
            fromCharacterID: character.id
        )
        
        bond.gainBondEXP(GameEngine.bondEXPForKudos)
        
        return interaction
    }
}

// MARK: - Result Types

/// Result of completing a task
struct TaskCompletionResult {
    let expGained: Int
    let goldGained: Int
    let bonusStatGains: [(StatType, Int)]
    let verificationMultiplier: Double
    let levelUpRewards: [LevelUpReward]
    let didLevelUp: Bool
    let pendingPartnerConfirmation: Bool
    let anomalyFlags: [AnomalyFlag]
    
    /// Convenience: first bonus stat gain (for backward-compatible display)
    var bonusStatGain: (StatType, Int)? {
        bonusStatGains.first
    }
    
    init(
        expGained: Int,
        goldGained: Int,
        bonusStatGains: [(StatType, Int)],
        verificationMultiplier: Double,
        levelUpRewards: [LevelUpReward],
        didLevelUp: Bool,
        pendingPartnerConfirmation: Bool = false,
        anomalyFlags: [AnomalyFlag] = []
    ) {
        self.expGained = expGained
        self.goldGained = goldGained
        self.bonusStatGains = bonusStatGains
        self.verificationMultiplier = verificationMultiplier
        self.levelUpRewards = levelUpRewards
        self.didLevelUp = didLevelUp
        self.pendingPartnerConfirmation = pendingPartnerConfirmation
        self.anomalyFlags = anomalyFlags
    }
}

/// Result of completing a mission
struct MissionCompletionResult {
    let success: Bool
    let expGained: Int
    let goldGained: Int
    let itemDropped: String?
    let levelUpRewards: [LevelUpReward]
    
    // Snapshot data for animated reward screen
    let previousLevel: Int
    let newLevel: Int
    let expProgressBefore: Double   // 0.0–1.0
    let expProgressAfter: Double    // 0.0–1.0
    let statPointsGained: Int
    
    /// Stat gained from training (nil if none)
    let statGained: (stat: StatType, amount: Int)?
}

/// Result of a meditation session
struct MeditationResult {
    let expGained: Int
    let goldGained: Int
    let streak: Int
    let levelUpRewards: [LevelUpReward]
}

/// Result of attacking a raid boss
struct RaidAttackResult {
    let damage: Int
    let bossDefeated: Bool
    let remainingHP: Int
    let maxHP: Int
}

