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
    
    /// Whether a training mission is actively in progress (timer still running).
    /// A completed-but-unclaimed mission does NOT count as "active training".
    var isTrainingInProgress: Bool {
        guard let mission = activeMission else { return false }
        return !mission.isComplete
    }
    @Published var showLevelUpCelebration: Bool = false
    @Published var showParagonLevelUp: Bool = false
    @Published var paragonLevelUpStat: StatType? = nil
    @Published var paragonLevelUpGold: Int = 0
    @Published var showAchievementCelebration: Bool = false
    @Published var unlockedAchievement: Achievement? = nil
    @Published var dailyQuests: [DailyQuest] = []
    
    // MARK: - Timers
    
    private var missionTimer: Timer?
    
    // MARK: - Initialization
    
    init() {
        // Restore persisted active mission (survives app restarts)
        activeMission = ActiveMission.loadPersisted()
        startMissionTimer()
    }
    
    /// Validate the persisted active mission belongs to the given character.
    /// If the character ID doesn't match (e.g. after a database reset), the
    /// orphaned mission is cleared so the new character starts fresh.
    func validateActiveMission(for characterID: UUID) {
        guard let active = activeMission else { return }
        if active.characterID != characterID {
            activeMission = nil
            ActiveMission.clearPersisted()
        }
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
    
    /// Co-op duty bonus multiplier (1.5× base rewards)
    static let coopDutyBonusMultiplier: Double = 0.5
    
    /// Bond EXP awarded for completing a co-op duty
    static let coopDutyBondEXP: Int = 25
    
    /// Complete a task and award EXP + rewards (with verification, anti-cheat, loot rolls, class affinity, and partner bonuses)
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
        
        // Determine verification tier (new system)
        let tier = VerificationEngine.verificationTier(
            task: task,
            healthKitVerified: task.healthKitVerified,
            partnerConfirmed: task.partnerConfirmed,
            geofenceResult: geofenceResult
        )
        
        // Calculate combined verification multiplier
        let verificationMult = VerificationEngine.totalVerificationMultiplier(
            task: task,
            anomalyFlags: anomalyFlags,
            healthKitVerified: task.healthKitVerified,
            partnerConfirmed: task.partnerConfirmed,
            geofenceResult: geofenceResult
        )
        
        // Base rewards (scaled by character level so tasks stay rewarding at higher levels)
        let levelScale = GameTask.levelScaleFactor(level: character.level)
        var baseEXP = Double(task.expReward) * levelScale
        var baseGold = Double(task.goldReward) * levelScale
        
        // Apply combined verification multiplier
        baseEXP *= verificationMult
        baseGold *= verificationMult
        
        var totalEXP = Int(baseEXP)
        var totalGold = Int(baseGold)
        
        // Class task affinity bonus (+15% EXP for matching category)
        var classAffinityBonusEXP = 0
        let affinityBonus = character.classAffinityBonus(for: task.category)
        if affinityBonus > 0 {
            classAffinityBonusEXP = Int(Double(totalEXP) * affinityBonus)
            totalEXP += classAffinityBonusEXP
        }
        
        // Meditation Wisdom buff (+5% EXP when active)
        if character.hasActiveWisdomBuff {
            totalEXP += Int(Double(totalEXP) * character.wisdomBuffMultiplier)
        }
        
        // Streak bonus (multiplicative — applies to the already-scaled and verified amount)
        if character.currentStreak > 0 {
            let streakBonus = min(character.currentStreak * 5, 50) // Max 50% bonus
            totalEXP += (totalEXP * streakBonus) / 100
            totalGold += (totalGold * streakBonus) / 100
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
        
        // Research tree bonuses (permanent, stacking)
        let researchBonuses = character.researchBonuses
        if researchBonuses.taskEXPBonus > 0 {
            totalEXP += Int(Double(totalEXP) * researchBonuses.taskEXPBonus)
        }
        if researchBonuses.allEXPBonus > 0 {
            totalEXP += Int(Double(totalEXP) * researchBonuses.allEXPBonus)
        }
        if researchBonuses.goldBonus > 0 {
            totalGold += Int(Double(totalGold) * researchBonuses.goldBonus)
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
                anomalyFlags: anomalyFlags,
                verificationTier: tier,
                classAffinityBonusEXP: classAffinityBonusEXP,
                classMessage: character.classCompletionMessage
            )
        }
        
        // Co-op duty bonus: simulate partner completion and award 1.5× rewards + Bond EXP
        var coopBonusEXP = 0
        var coopBonusGold = 0
        var coopBondEXP = 0
        var coopPartnerDone = false
        
        if task.isCoopDuty && !task.coopBonusAwarded {
            // Simulate partner completing the duty (they always pull through)
            task.coopPartnerCompleted = true
            coopPartnerDone = true
            
            // Award co-op bonus: +50% of base rewards
            coopBonusEXP = Int(Double(totalEXP) * GameEngine.coopDutyBonusMultiplier)
            coopBonusGold = Int(Double(totalGold) * GameEngine.coopDutyBonusMultiplier)
            coopBondEXP = GameEngine.coopDutyBondEXP
            
            totalEXP += coopBonusEXP
            totalGold += coopBonusGold
            
            // Award Bond EXP
            if let bond = bond {
                bond.gainBondEXP(coopBondEXP)
            }
            
            // Charisma bonus for teamwork
            character.stats.increase(.charisma, by: 1)
            bonusStatGains.append((.charisma, 1))
            
            task.coopBonusAwarded = true
        }
        
        // --- LOOT ROLL ---
        // Chance-based loot drop on task completion
        // Base rates: 5-8% equipment, 30-40% materials, 15-20% consumables
        var lootDrop: LootDrop? = nil
        if let ctx = context {
            let lootBonus = VerificationEngine.lootChanceBonus(
                task: task,
                healthKitVerified: task.healthKitVerified,
                partnerConfirmed: task.partnerConfirmed,
                geofenceResult: geofenceResult
            )
            let luckBonus = Double(character.effectiveStats.luck) * 0.002 // +0.2% per luck
            lootDrop = GameEngine.rollTaskLoot(
                character: character,
                lootBonus: lootBonus + luckBonus,
                context: ctx
            )
        }
        
        // --- ROUTINE BUNDLE CHECK ---
        var routineBundleCompleted = false
        var routineBonusEXP = 0
        if task.isHabit, let ctx = context {
            let bundleResult = checkRoutineBundleCompletion(
                habitTask: task,
                character: character,
                context: ctx
            )
            routineBundleCompleted = bundleResult.completed
            routineBonusEXP = bundleResult.bonusEXP
            totalEXP += routineBonusEXP
        }
        
        // Award EXP (does not auto-level; player triggers level-up manually)
        let couldLevelBefore = character.canLevelUp
        character.gainEXP(totalEXP)
        
        // Fire a push notification if the player just became eligible to level up
        if !couldLevelBefore && character.canLevelUp {
            PushNotificationService.shared.scheduleLevelUpReady(currentLevel: character.level)
        }
        
        // Award gold (with rebirth bonus)
        character.gainGold(totalGold)
        
        // Update task count + daily count
        character.tasksCompleted += 1
        character.checkDailyReset()
        character.tasksCompletedToday += 1
        
        // Update category mastery
        character.incrementMastery(for: task.category)
        
        // Update personal records (most tasks in a day)
        character.updateDailyTaskRecord()
        
        // Update category longest streak if this is a habit
        if task.isHabit {
            character.updateCategoryLongestStreak(
                category: task.category,
                currentStreak: task.habitStreak
            )
        }
        
        // Check achievements — show celebration for first newly unlocked one
        let newlyUnlocked = AchievementTracker.checkAll(character: character)
        if let first = newlyUnlocked.first {
            // Queue it — shown after the task completion celebration dismisses
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.unlockedAchievement = first
                self.showAchievementCelebration = true
            }
        }
        
        // Sync completion to cloud if this is a partner-assigned task
        if task.isFromPartner && task.cloudID != nil {
            syncTaskCompletionToCloud(task, characterName: character.name)
        }
        
        // Queue character + task + daily state sync via SyncManager
        SyncManager.shared.queueCharacterSync(character)
        SyncManager.shared.queueDailyStateSync(character)
        if let userID = SupabaseService.shared.currentUserID {
            SyncManager.shared.queueTaskSync(task, playerID: userID)
        }
        
        // Also do an immediate character sync for critical data
        let charForSync = character
        Task {
            try? await SupabaseService.shared.syncCharacterData(charForSync)
        }
        
        // Check goal progress if this task is linked to a goal
        if let goalID = task.goalID, let ctx = context {
            checkGoalMilestones(goalID: goalID, character: character, context: ctx)
        }
        
        return TaskCompletionResult(
            expGained: totalEXP,
            goldGained: totalGold,
            bonusStatGains: bonusStatGains,
            verificationMultiplier: verificationMult,
            levelUpRewards: [],
            didLevelUp: false,
            pendingPartnerConfirmation: false,
            anomalyFlags: anomalyFlags,
            isCoopDuty: task.isCoopDuty,
            coopBonusEXP: coopBonusEXP,
            coopBonusGold: coopBonusGold,
            coopBondEXP: coopBondEXP,
            coopPartnerCompleted: coopPartnerDone,
            lootDropped: lootDrop,
            verificationTier: tier,
            classAffinityBonusEXP: classAffinityBonusEXP,
            classMessage: character.classCompletionMessage,
            routineBundleCompleted: routineBundleCompleted,
            routineBonusEXP: routineBonusEXP
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
        
        let levelScale = GameTask.levelScaleFactor(level: character.level)
        var totalEXP = Int(Double(task.expReward) * levelScale * verificationMult)
        var totalGold = Int(Double(task.goldReward) * levelScale * verificationMult)
        
        // Partner co-task bonus
        totalEXP += Int(Double(totalEXP) * GameEngine.partnerBonusMultiplier)
        totalGold += Int(Double(totalGold) * GameEngine.partnerBonusMultiplier)
        
        // Bond bonuses
        if let bond = bond {
            let bonuses = GameEngine.bondBonuses(bond: bond)
            totalEXP += Int(Double(totalEXP) * bonuses.expMultiplier)
            totalGold += Int(Double(totalGold) * bonuses.goldMultiplier)
        }
        
        // Apply rewards (does not auto-level)
        character.gainEXP(totalEXP)
        character.gainGold(totalGold)
        character.tasksCompleted += 1
        
        let newlyUnlocked = AchievementTracker.checkAll(character: character)
        if let first = newlyUnlocked.first {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.unlockedAchievement = first
                self.showAchievementCelebration = true
            }
        }
        
        // Sync confirmation to cloud
        syncTaskConfirmationToCloud(task, confirmed: true, characterName: character.name)
        
        // Queue character + daily state sync via SyncManager
        SyncManager.shared.queueCharacterSync(character)
        SyncManager.shared.queueDailyStateSync(character)
        
        // Also do an immediate character sync
        let charForSync = character
        Task { try? await SupabaseService.shared.syncCharacterData(charForSync) }
    }
    
    /// Dispute a partner's completed task
    func disputePartnerTask(_ task: GameTask, character: PlayerCharacter, reason: String?) {
        task.pendingPartnerConfirmation = false
        task.partnerConfirmed = false
        task.partnerDisputeReason = reason ?? "Partner disputed this completion"
        task.status = .pending
        task.completedAt = nil
        task.completedBy = nil
        
        // Sync dispute to cloud
        syncTaskConfirmationToCloud(task, confirmed: false, characterName: character.name, reason: reason)
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
        
        let result = await HealthKitService.shared.verifyPhysicalActivity(focus: nil)
        task.healthKitVerified = result.verified
        task.healthKitActivitySummary = result.summary
    }
    
    // MARK: - Bond & Party Bonuses
    
    /// Bond bonus multipliers derived from partnership perks + party streak
    struct BondBonuses {
        var expMultiplier: Double = 0.0
        var goldMultiplier: Double = 0.0
        var streakMultiplier: Double = 0.0
        var lootBonusChance: Double = 0.0
    }
    
    /// Calculate cumulative bond bonuses from unlocked perks + party streak tiers
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
        
        // Party streak bonuses (3-day, 7-day, 14-day, 30-day tiers)
        bonuses.expMultiplier += bond.partyStreakEXPBonus
        bonuses.goldMultiplier += bond.partyStreakGoldBonus
        bonuses.lootBonusChance += bond.partyStreakLootBonus
        
        // Legendary bond: +50% all bonuses
        if perks.contains(.legendaryBond) {
            bonuses.expMultiplier *= 1.5
            bonuses.goldMultiplier *= 1.5
            bonuses.streakMultiplier *= 1.5
            bonuses.lootBonusChance *= 1.5
        }
        
        return bonuses
    }
    
    // MARK: - Party Power Scaling
    
    /// Calculate party power multiplier for AFK combat / co-op content.
    /// Uses diminishing returns: solo=1.0, 2=1.5, 3=1.85, 4=2.1
    static func partyPowerMultiplier(memberCount: Int) -> Double {
        switch memberCount {
        case 1: return 1.0
        case 2: return 1.5
        case 3: return 1.85
        case 4: return 2.1
        default: return 1.0
        }
    }
    
    // MARK: - Party Feed Posting
    
    /// Post an event to the party feed on Supabase
    static func postPartyFeedEvent(
        partyID: UUID,
        actorID: UUID,
        eventType: String,
        message: String,
        metadata: [String: String] = [:]
    ) {
        Task {
            do {
                struct FeedInsert: Encodable {
                    let party_id: String
                    let actor_id: String
                    let event_type: String
                    let message: String
                    let metadata: [String: String]
                }
                
                let insert = FeedInsert(
                    party_id: partyID.uuidString,
                    actor_id: actorID.uuidString,
                    event_type: eventType,
                    message: message,
                    metadata: metadata
                )
                
                try await SupabaseService.shared.client
                    .from("party_feed")
                    .insert(insert)
                    .execute()
            } catch {
                print("❌ Failed to post party feed event: \(error)")
            }
        }
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
        
        // Apply research tree mission duration reduction
        let researchBonuses = character.researchBonuses
        if researchBonuses.missionDurationReduction > 0 {
            let originalDuration = newMission.completesAt.timeIntervalSince(newMission.startedAt)
            let reducedDuration = originalDuration * (1.0 - researchBonuses.missionDurationReduction)
            newMission.completesAt = newMission.startedAt.addingTimeInterval(reducedDuration)
        }
        
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
            
            // Apply rewards (with rebirth bonuses)
            character.gainEXP(expReward)
            character.gainGold(goldReward)
            
            // Auto-level-up if eligible (drives the MissionCompletionView animation)
            var levelUpRewards: [LevelUpReward] = []
            while character.canLevelUp {
                let rewards = character.performLevelUp()
                levelUpRewards.append(contentsOf: rewards)
            }
            
            // Capture after state
            let newLevel = character.level
            let expProgressAfter = character.levelProgress
            let statPointsGained = levelUpRewards.filter { $0 == .statPoint }.count
            
            active.earnedEXP = expReward
            active.earnedGold = goldReward
            
            // Stat reward from training — prefer explicit trainingStat, fall back to missionType
            var statGained: (stat: StatType, amount: Int)? = nil
            let primaryStat = mission.trainingStatType ?? mission.missionType.primaryStat
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
                        luck: character.effectiveStats.luck,
                        playerLevel: character.level
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
            
            // Research Token drop (mission-exclusive)
            // Base 25% chance, higher rarity missions give more tokens
            var researchTokensDropped = 0
            let researchTokenChance: Double = {
                switch mission.rarity {
                case .common:    return 0.20
                case .uncommon:  return 0.30
                case .rare:      return 0.45
                case .epic:      return 0.60
                case .legendary: return 0.80
                }
            }()
            if Double.random(in: 0...1) <= researchTokenChance {
                let tokenCount: Int = {
                    switch mission.rarity {
                    case .common:    return 1
                    case .uncommon:  return 1
                    case .rare:      return Int.random(in: 1...2)
                    case .epic:      return Int.random(in: 1...3)
                    case .legendary: return Int.random(in: 2...4)
                    }
                }()
                researchTokensDropped = tokenCount
            }
            
            // Rank-up class evolution (if this was a rank-up training course)
            var rankedUpToClass: CharacterClass? = nil
            if mission.isRankUpTraining, let targetClass = mission.targetClass {
                character.characterClass = targetClass
                rankedUpToClass = targetClass
            }
            
            active.rewardClaimed = true
            
            // Check achievements after mission
            let newlyUnlocked = AchievementTracker.checkAll(character: character)
            if let first = newlyUnlocked.first {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.unlockedAchievement = first
                    self.showAchievementCelebration = true
                }
            }
            
            // NOTE: Don't trigger separate level-up celebration here;
            // the MissionCompletionView handles it inline with animations.
            
            // Queue character sync via SyncManager after mission completion
            SyncManager.shared.queueCharacterSync(character)
            SyncManager.shared.queueDailyStateSync(character)
            
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
                statGained: statGained,
                researchTokensDropped: researchTokensDropped,
                rankedUpToClass: rankedUpToClass
            )
        } else {
            // Mission failed — award consolation rewards (25%) so time isn't wasted
            let consolationEXP = max(5, mission.expReward / 4)
            let consolationGold = max(2, mission.goldReward / 4)
            
            let previousLevel = character.level
            let expProgressBefore = character.levelProgress
            
            character.gainEXP(consolationEXP)
            character.gainGold(consolationGold)
            
            // Auto-level-up if eligible
            var levelUpRewards: [LevelUpReward] = []
            while character.canLevelUp {
                let rewards = character.performLevelUp()
                levelUpRewards.append(contentsOf: rewards)
            }
            
            let newLevel = character.level
            let expProgressAfter = character.levelProgress
            let statPointsGained = levelUpRewards.filter { $0 == .statPoint }.count
            
            active.earnedEXP = consolationEXP
            active.earnedGold = consolationGold
            active.rewardClaimed = true
            activeMission = nil
            ActiveMission.clearPersisted()
            
            return MissionCompletionResult(
                success: false,
                expGained: consolationEXP,
                goldGained: consolationGold,
                itemDropped: nil,
                levelUpRewards: levelUpRewards,
                previousLevel: previousLevel,
                newLevel: newLevel,
                expProgressBefore: expProgressBefore,
                expProgressAfter: expProgressAfter,
                statPointsGained: statPointsGained,
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
    
    /// Update daily streak (with streak freeze support)
    func updateStreak(for character: PlayerCharacter, completedTaskToday: Bool) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastActive = calendar.startOfDay(for: character.lastActiveAt)
        
        let daysDifference = calendar.dateComponents([.day], from: lastActive, to: today).day ?? 0
        
        if completedTaskToday {
            if daysDifference == 0 {
                // Same day — initialize streak to 1 if this is the first completion
                if character.currentStreak == 0 {
                    character.currentStreak = 1
                    character.longestStreak = max(character.longestStreak, 1)
                }
            } else if daysDifference == 1 {
                // Next day, increment streak
                character.currentStreak += 1
                character.longestStreak = max(character.longestStreak, character.currentStreak)
            } else {
                // Gap of more than 1 day — check for streak freeze
                if daysDifference == 2 && applyStreakFreezeIfAvailable(character: character) {
                    // Streak freeze consumed — streak continues as if no gap
                    character.currentStreak += 1
                    character.longestStreak = max(character.longestStreak, character.currentStreak)
                } else {
                    // Streak broken, reset
                    character.currentStreak = 1
                }
            }
        } else if daysDifference > 1 {
            // Missed a day without completing a task
            if daysDifference == 2 && applyStreakFreezeIfAvailable(character: character) {
                // Freeze consumed, streak preserved (not incremented since no task today)
            } else {
                character.currentStreak = 0
            }
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
            luck: baseStats.luck + bonusStats.luck,
            defense: baseStats.defense + bonusStats.defense
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
    
    // MARK: - Manual Level Up
    
    /// Trigger a manual level-up from the UI (player taps "Level Up" button)
    func levelUp(character: PlayerCharacter, context: ModelContext? = nil) {
        let baseRewards = character.performLevelUp()
        guard !baseRewards.isEmpty else { return }
        
        var allRewards = baseRewards
        
        // Generate bonus chest rewards
        let chest = LevelUpChestGenerator.generate(
            level: character.level,
            luck: character.effectiveStats.luck,
            characterID: character.id
        )
        
        // Apply gems directly
        for reward in chest.rewards {
            if case .gems(let amount) = reward {
                character.gems += amount
            }
        }
        
        // Persist equipment drops
        if let ctx = context {
            for item in chest.equipmentDrops {
                ctx.insert(item)
                Task { try? await SupabaseService.shared.syncEquipment(item) }
            }
            for consumable in chest.consumableDrops {
                ctx.insert(consumable)
                Task { try? await SupabaseService.shared.syncConsumable(consumable) }
            }
            // Persist material drops
            for (type, rarity, quantity) in chest.materialDrops {
                addMaterial(type, rarity: rarity, amount: quantity, characterID: character.id, context: ctx)
            }
            try? ctx.save()
        }
        
        allRewards.append(contentsOf: chest.rewards)
        
        pendingLevelUpRewards = allRewards
        showLevelUpCelebration = true
    }
    
    /// Trigger a Paragon level-up (character is level 100+, EXP threshold met)
    func paragonLevelUp(character: PlayerCharacter) {
        guard character.canParagonLevelUp else { return }
        
        let result = character.performParagonLevelUp()
        
        paragonLevelUpStat = result.stat
        paragonLevelUpGold = result.gold
        showParagonLevelUp = true
        
        AudioManager.shared.play(.levelUp)
        
        // Sync to cloud
        Task {
            do {
                try await SupabaseService.shared.syncCharacterData(character)
                print("✅ Paragon level up synced: P\(character.paragonLevel)")
            } catch {
                print("❌ Failed to sync paragon level up: \(error)")
            }
        }
    }
    
    /// Perform a Rebirth for the character. Resets level/class, keeps gear, grants permanent bonus.
    func performRebirth(character: PlayerCharacter, context: ModelContext? = nil) {
        character.performRebirth()
        
        // Check rebirth achievements
        AchievementTracker.checkAll(character: character)
        
        AudioManager.shared.play(.levelUp)
        
        // Sync to cloud
        Task {
            do {
                try await SupabaseService.shared.syncCharacterData(character)
                print("✅ Rebirth synced: Rebirth #\(character.rebirthCount)")
            } catch {
                print("❌ Failed to sync rebirth: \(error)")
            }
        }
    }
    
    // MARK: - Recurring Tasks
    
    /// Check all completed recurring tasks and reset them if their recurrence period has elapsed
    func checkRecurringTasks(context: ModelContext) {
        let descriptor = FetchDescriptor<GameTask>(
            predicate: #Predicate<GameTask> { task in
                task.isRecurring == true
            }
        )
        
        guard let recurringTasks = try? context.fetch(descriptor) else { return }
        
        let calendar = Calendar.current
        let now = Date()
        
        for task in recurringTasks {
            // Only reset completed tasks
            let statusRaw = task.status.rawValue
            guard statusRaw == "Completed" else { continue }
            guard let completedAt = task.completedAt else { continue }
            guard let pattern = task.recurrencePattern else { continue }
            
            let shouldReset: Bool
            switch pattern {
            case .daily:
                shouldReset = !calendar.isDate(completedAt, inSameDayAs: now)
            case .weekdays:
                let weekday = calendar.component(.weekday, from: now)
                let isWeekday = weekday >= 2 && weekday <= 6
                shouldReset = isWeekday && !calendar.isDate(completedAt, inSameDayAs: now)
            case .weekends:
                let weekday = calendar.component(.weekday, from: now)
                let isWeekend = weekday == 1 || weekday == 7
                shouldReset = isWeekend && !calendar.isDate(completedAt, inSameDayAs: now)
            case .weekly:
                let daysSince = calendar.dateComponents([.day], from: completedAt, to: now).day ?? 0
                shouldReset = daysSince >= 7
            case .biweekly:
                let daysSince = calendar.dateComponents([.day], from: completedAt, to: now).day ?? 0
                shouldReset = daysSince >= 14
            case .monthly:
                let monthsSince = calendar.dateComponents([.month], from: completedAt, to: now).month ?? 0
                shouldReset = monthsSince >= 1
            }
            
            if shouldReset {
                task.resetForRecurrence()
            }
        }
        
        try? context.save()
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
        
        character.gainEXP(quest.expReward)
        character.gainGold(quest.goldReward)
        
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
    
    // MARK: - Mood Check-In
    
    /// Log a mood check-in and award small rewards
    func logMood(
        character: PlayerCharacter,
        moodLevel: Int,
        journal: String?,
        context: ModelContext
    ) -> MoodCheckInResult? {
        guard !character.hasLoggedMoodToday else { return nil }
        
        // Check and update mood streak
        character.checkMoodStreak()
        
        // Update streak
        if let lastDate = character.lastMoodDate {
            let daysDiff = Calendar.current.dateComponents(
                [.day],
                from: Calendar.current.startOfDay(for: lastDate),
                to: Calendar.current.startOfDay(for: Date())
            ).day ?? 0
            if daysDiff == 1 {
                character.moodStreak += 1
            } else if daysDiff > 1 {
                character.moodStreak = 1
            }
        } else {
            character.moodStreak = 1
        }
        character.lastMoodDate = Date()
        
        // Calculate rewards (scales with level so mood stays relevant late-game)
        var baseEXP = max(20, character.level * 4)
        var baseGold = max(15, character.level * 2)
        
        // Streak bonus: +25% at 3 days, +50% at 7, +75% at 14, +100% at 30
        let streakMultiplier: Double
        switch character.moodStreak {
        case 30...: streakMultiplier = 2.0
        case 14...: streakMultiplier = 1.75
        case 7...: streakMultiplier = 1.5
        case 3...: streakMultiplier = 1.25
        default: streakMultiplier = 1.0
        }
        
        baseEXP = Int(Double(baseEXP) * streakMultiplier)
        baseGold = Int(Double(baseGold) * streakMultiplier)
        
        // Award rewards (with rebirth bonuses)
        character.gainEXP(baseEXP)
        character.gainGold(baseGold)
        
        // Create mood entry
        let trimmedJournal = journal?.trimmingCharacters(in: .whitespacesAndNewlines)
        let entry = MoodEntry(
            moodLevel: moodLevel,
            journalText: (trimmedJournal?.isEmpty ?? true) ? nil : trimmedJournal,
            ownerID: character.id
        )
        context.insert(entry)
        try? context.save()
        
        // Queue mood + character + daily state sync via SyncManager
        if let userID = SupabaseService.shared.currentUserID {
            SyncManager.shared.queueMoodSync(entry, playerID: userID)
        }
        SyncManager.shared.queueCharacterSync(character)
        SyncManager.shared.queueDailyStateSync(character)
        
        return MoodCheckInResult(
            expGained: baseEXP,
            goldGained: baseGold,
            streak: character.moodStreak,
            streakMultiplier: streakMultiplier
        )
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
        
        // Award rewards (with rebirth bonuses, does not auto-level)
        character.gainEXP(expReward)
        character.gainGold(goldReward)
        
        // Grant Wisdom buff: +5% Wisdom for 24 hours
        grantWisdomBuff(character: character)
        
        return MeditationResult(
            expGained: expReward,
            goldGained: goldReward,
            streak: character.meditationStreak,
            levelUpRewards: [],
            wisdomBuffGranted: true
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
    
    /// Claim raid boss defeat rewards (enhanced with loot table per design doc)
    func claimRaidBossRewards(
        boss: WeeklyRaidBoss,
        character: PlayerCharacter,
        bond: Bond?,
        context: ModelContext
    ) {
        guard boss.isDefeated && !boss.rewardsClaimed else { return }
        
        // Calculate rewards using loot table
        let lootResult = WeeklyRaidBoss.lootResult(tier: boss.tier, template: nil)
        
        // Apply gold and EXP (with rebirth bonuses)
        character.gainEXP(lootResult.exp)
        character.gainGold(lootResult.gold)
        
        // Bond EXP if partnered
        if let bond = bond {
            bond.gainBondEXP(lootResult.bondExp)
        }
        
        // Equipment drop (15-25% rare+ based on template)
        if lootResult.equipmentDropped {
            let loot = LootGenerator.generateEquipment(tier: max(2, boss.tier), luck: character.effectiveStats.luck, playerLevel: character.level)
            loot.ownerID = character.id
            context.insert(loot)
            Task { try? await SupabaseService.shared.syncEquipment(loot) }
        }
        
        // Guaranteed boss-exclusive card drop
        let cardPool = ContentManager.shared.activeCardPool
        if let contentCard = CardDropEngine.raidBossCardDrop(
            bossTemplateName: boss.name,
            cardPool: cardPool
        ) {
            _ = CardDropEngine.collectCard(
                contentCard: contentCard,
                character: character,
                context: context
            )
        }
        
        boss.rewardsClaimed = true
    }
    
    // MARK: - Forge (Redesigned)
    
    /// Result from the new salvage system (materials, fragments, gold, optional affix scroll)
    struct SalvageResult {
        let materialsReturned: Int
        let fragmentsReturned: Int
        let goldReturned: Int
        let recoveredAffixScroll: Bool
    }
    
    /// Salvage an equipment item — returns materials directly (no more Forge Shards).
    /// Uses server-driven salvage rules from ContentManager when available.
    func salvageEquipment(_ item: Equipment, character: PlayerCharacter, context: ModelContext) -> SalvageResult {
        let rarityKey = item.rarity.rawValue.lowercased()
        
        // Read server rules or fall back to defaults
        let cm = ContentManager.shared
        let rule = cm.salvageRule(forRarity: rarityKey)
        
        let materialsBack = rule?.materialsReturned ?? Self.defaultSalvageMaterials(rarity: item.rarity)
        let fragmentsBack = rule?.fragmentsReturned ?? Self.defaultSalvageFragments(rarity: item.rarity)
        let goldBack = rule?.goldReturned ?? Self.defaultSalvageGold(rarity: item.rarity)
        let affixRecoveryChance = rule?.affixRecoveryChance ?? Self.defaultAffixRecovery(rarity: item.rarity)
        
        // Award materials
        if materialsBack > 0 {
            let matTypes: [MaterialType] = [.ore, .crystal, .hide]
            let chosen = matTypes.randomElement() ?? .ore
            addMaterial(chosen, rarity: .common, amount: materialsBack, characterID: character.id, context: context)
        }
        
        // Award fragments
        if fragmentsBack > 0 {
            addMaterial(.fragment, rarity: .common, amount: fragmentsBack, characterID: character.id, context: context)
        }
        
        // Award gold
        character.gold += goldBack
        
        // Affix recovery roll (chance to get an Affix Scroll consumable)
        var recoveredScroll = false
        if affixRecoveryChance > 0 && Double.random(in: 0...1) <= affixRecoveryChance {
            let scroll = Consumable(
                name: "Recovered Affix Scroll",
                description: "An affix scroll recovered from salvaging equipment.",
                consumableType: .affixScroll,
                icon: "scroll.fill",
                effectValue: 1,
                characterID: character.id
            )
            context.insert(scroll)
            Task { try? await SupabaseService.shared.syncConsumable(scroll) }
            recoveredScroll = true
        }
        
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
            case .trinket:
                if character.equipment.trinket?.id == item.id {
                    character.equipment.trinket = nil
                }
            }
        }
        
        let deletedID = item.id
        context.delete(item)
        Task { try? await SupabaseService.shared.deleteEquipment(id: deletedID) }
        
        // Sync character after gold change
        SyncManager.shared.queueCharacterSync(character)
        
        return SalvageResult(
            materialsReturned: materialsBack,
            fragmentsReturned: fragmentsBack,
            goldReturned: goldBack,
            recoveredAffixScroll: recoveredScroll
        )
    }
    
    // MARK: - Default Salvage Values (fallback when ContentManager unavailable)
    
    static func defaultSalvageMaterials(rarity: ItemRarity) -> Int {
        switch rarity {
        case .common: return 0
        case .uncommon: return 2
        case .rare: return 3
        case .epic: return 5
        case .legendary: return 8
        }
    }
    
    static func defaultSalvageFragments(rarity: ItemRarity) -> Int {
        switch rarity {
        case .common: return 1
        case .uncommon: return 0
        case .rare: return 1
        case .epic: return 2
        case .legendary: return 4
        }
    }
    
    static func defaultSalvageGold(rarity: ItemRarity) -> Int {
        switch rarity {
        case .common: return 5
        case .uncommon: return 15
        case .rare: return 40
        case .epic: return 100
        case .legendary: return 250
        }
    }
    
    static func defaultAffixRecovery(rarity: ItemRarity) -> Double {
        switch rarity {
        case .common: return 0.0
        case .uncommon: return 0.10
        case .rare: return 0.20
        case .epic: return 0.30
        case .legendary: return 0.50
        }
    }
    
    /// Legacy shards-for-rarity (kept for backward compatibility / shard conversion)
    nonisolated func shardsForRarity(_ rarity: ItemRarity) -> Int {
        switch rarity {
        case .common: return 1
        case .uncommon: return 2
        case .rare: return 4
        case .epic: return 8
        case .legendary: return 16
        }
    }
    
    /// Legacy shard cost (kept for backward compatibility)
    nonisolated func shardCostForRarity(_ rarity: ItemRarity) -> Int {
        switch rarity {
        case .common: return 3
        case .uncommon: return 8
        case .rare: return 15
        case .epic: return 30
        case .legendary: return 0
        }
    }
    
    /// Convert existing Forge Shards to Gold (1 shard = 10 gold). Call once on upgrade.
    func convertShardsToGold(character: PlayerCharacter) {
        guard character.forgeShards > 0 else { return }
        let goldAmount = character.forgeShards * 10
        character.gold += goldAmount
        character.forgeShards = 0
        SyncManager.shared.queueCharacterSync(character)
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
    
    /// Award Research Tokens from a successful AFK mission
    func awardResearchTokens(
        amount: Int,
        character: PlayerCharacter,
        context: ModelContext
    ) {
        guard amount > 0 else { return }
        addMaterial(.researchToken, rarity: .common, amount: amount, characterID: character.id, context: context)
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
        let finalQuantity: Int
        if let existing = allMats.first(where: { $0.materialType == type && $0.rarity == rarity }) {
            existing.quantity += amount
            finalQuantity = existing.quantity
        } else {
            let newMat = CraftingMaterial(
                materialType: type,
                rarity: rarity,
                quantity: amount,
                characterID: characterID
            )
            context.insert(newMat)
            finalQuantity = amount
        }
        
        // Sync material stack to cloud
        let typeRaw = type.rawValue
        let rarityRaw = rarity.rawValue
        Task { try? await SupabaseService.shared.syncMaterial(type: typeRaw, rarity: rarityRaw, quantity: finalQuantity) }
        
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
            preferredSlot: slot,
            playerLevel: character.level
        )
        item.ownerID = charID
        context.insert(item)
        Task { try? await SupabaseService.shared.syncEquipment(item) }
        
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
            let newQty = existing.quantity
            let typeRaw = type.rawValue
            let rarityRaw = rarity.rawValue
            Task { try? await SupabaseService.shared.syncMaterial(type: typeRaw, rarity: rarityRaw, quantity: newQty) }
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
            // Sync updated stack to cloud
            let newQty = stack.quantity
            let typeRaw = stack.materialType.rawValue
            let rarityRaw = stack.rarity.rawValue
            Task { try? await SupabaseService.shared.syncMaterial(type: typeRaw, rarity: rarityRaw, quantity: newQty) }
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
    
    // MARK: - Equipment Enhancement (Redesigned)
    
    /// Result of an enhancement attempt
    struct EnhancementResult {
        let success: Bool
        let critical: Bool          // Double stat gain if true
        let statGained: Int         // Actual stat points added
        let newLevel: Int           // Enhancement level after attempt
        let goldSpent: Int
        let materialsConsumed: Bool // Materials always consumed on attempt
    }
    
    /// Calculate gold cost to enhance equipment to the next level.
    /// Uses server-driven cost multiplier from ContentManager when available.
    func enhancementCost(for item: Equipment) -> Int {
        let basePrice = Self.enhancementBasePrice(rarity: item.rarity)
        let nextLevel = item.enhancementLevel + 1
        
        // Try server-driven multiplier
        let cm = ContentManager.shared
        if let rule = cm.enhancementRule(forLevel: nextLevel) {
            return Int(Double(basePrice) * rule.costMultiplier)
        }
        
        // Fallback: use default multiplier table
        let multiplier = Self.defaultEnhancementCostMultiplier(level: nextLevel)
        return Int(Double(basePrice) * multiplier)
    }
    
    /// Base gold cost per rarity (from §13 in GAME_DESIGN.md)
    nonisolated static func enhancementBasePrice(rarity: ItemRarity) -> Int {
        switch rarity {
        case .common: return 50
        case .uncommon: return 100
        case .rare: return 200
        case .epic: return 500
        case .legendary: return 1000
        }
    }
    
    /// Success rate for the next enhancement level (server-driven or fallback)
    func enhancementSuccessRate(for item: Equipment, hasCatalyst: Bool = false) -> Double {
        let nextLevel = item.enhancementLevel + 1
        
        let cm = ContentManager.shared
        var rate: Double
        if let rule = cm.enhancementRule(forLevel: nextLevel) {
            rate = rule.successRate
        } else {
            rate = Self.defaultEnhancementSuccessRate(level: nextLevel)
        }
        
        // Forge Catalyst doubles success rate (capped at 1.0)
        if hasCatalyst {
            rate = min(1.0, rate * 2.0)
        }
        
        return rate
    }
    
    /// Stat gain for the next enhancement level
    func enhancementStatGain(forLevel level: Int) -> Int {
        let cm = ContentManager.shared
        if let rule = cm.enhancementRule(forLevel: level) {
            return rule.statGain
        }
        return Self.defaultEnhancementStatGain(level: level)
    }
    
    /// Critical enhancement chance (10% by default — double stat gain)
    func enhancementCriticalChance(forLevel level: Int) -> Double {
        let cm = ContentManager.shared
        if let rule = cm.enhancementRule(forLevel: level) {
            return rule.criticalChance
        }
        return 0.10
    }
    
    /// Attempt to enhance an equipment item.
    /// Now includes failure chance at +4+, critical enhancement, and server-driven rules.
    /// Materials are always consumed. On failure, level stays the same.
    func enhanceEquipment(
        _ item: Equipment,
        character: PlayerCharacter,
        useCatalyst: Bool = false,
        context: ModelContext? = nil
    ) -> EnhancementResult {
        let nextLevel = item.enhancementLevel + 1
        guard nextLevel <= Equipment.maxEnhancementLevel else {
            return EnhancementResult(success: false, critical: false, statGained: 0, newLevel: item.enhancementLevel, goldSpent: 0, materialsConsumed: false)
        }
        
        let cost = enhancementCost(for: item)
        guard character.gold >= cost else {
            return EnhancementResult(success: false, critical: false, statGained: 0, newLevel: item.enhancementLevel, goldSpent: 0, materialsConsumed: false)
        }
        
        // Deduct gold (always consumed)
        character.gold -= cost
        
        // Consume Forge Catalyst if used
        if useCatalyst, let ctx = context {
            consumeForgeCatalyst(characterID: character.id, context: ctx)
        }
        
        // Roll for success
        let successRate = enhancementSuccessRate(for: item, hasCatalyst: useCatalyst)
        let roll = Double.random(in: 0...1)
        let succeeded = roll <= successRate
        
        if succeeded {
            // Roll for critical enhancement (double stat gain)
            let critChance = enhancementCriticalChance(forLevel: nextLevel)
            let critRoll = Double.random(in: 0...1)
            let isCritical = critRoll <= critChance
            
            let baseStatGain = enhancementStatGain(forLevel: nextLevel)
            let actualStatGain = isCritical ? baseStatGain * 2 : baseStatGain
            
            item.enhancementLevel = nextLevel
            item.statBonus += actualStatGain
            
            Task { try? await SupabaseService.shared.syncEquipment(item) }
            SyncManager.shared.queueCharacterSync(character)
            
            return EnhancementResult(
                success: true,
                critical: isCritical,
                statGained: actualStatGain,
                newLevel: nextLevel,
                goldSpent: cost,
                materialsConsumed: true
            )
        } else {
            // Failed — gold consumed, level stays
            SyncManager.shared.queueCharacterSync(character)
            
            return EnhancementResult(
                success: false,
                critical: false,
                statGained: 0,
                newLevel: item.enhancementLevel,
                goldSpent: cost,
                materialsConsumed: true
            )
        }
    }
    
    /// Consume one Forge Catalyst from the character's inventory
    private func consumeForgeCatalyst(characterID: UUID, context: ModelContext) {
        let descriptor = FetchDescriptor<Consumable>(
            predicate: #Predicate<Consumable> { c in
                c.characterID == characterID && c.remainingUses > 0
            }
        )
        guard let consumables = try? context.fetch(descriptor) else { return }
        if let catalyst = consumables.first(where: { $0.consumableType == .forgeCatalyst }) {
            catalyst.remainingUses -= 1
            if catalyst.remainingUses <= 0 {
                context.delete(catalyst)
            }
        }
    }
    
    /// Check if character has a Forge Catalyst available
    func hasForgeCatalyst(characterID: UUID, context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<Consumable>(
            predicate: #Predicate<Consumable> { c in
                c.characterID == characterID && c.remainingUses > 0
            }
        )
        guard let consumables = try? context.fetch(descriptor) else { return false }
        return consumables.contains { $0.consumableType == .forgeCatalyst }
    }
    
    // MARK: - Default Enhancement Values (fallback)
    
    private static func defaultEnhancementSuccessRate(level: Int) -> Double {
        switch level {
        case 1...3: return 1.00
        case 4...6: return 0.80
        case 7...8: return 0.60
        case 9:     return 0.40
        case 10:    return 0.25
        default:    return 0.25
        }
    }
    
    private static func defaultEnhancementCostMultiplier(level: Int) -> Double {
        switch level {
        case 1:  return 1.0
        case 2:  return 1.5
        case 3:  return 2.0
        case 4:  return 3.0
        case 5:  return 4.0
        case 6:  return 5.0
        case 7:  return 8.0
        case 8:  return 12.0
        case 9:  return 20.0
        case 10: return 40.0
        default: return 40.0
        }
    }
    
    private static func defaultEnhancementStatGain(level: Int) -> Int {
        switch level {
        case 1...6: return 1
        case 7...9: return 2
        case 10:    return 3
        default:    return 1
        }
    }
    
    /// Legacy enhance method that returns Bool (backward compatibility for any remaining callers)
    @available(*, deprecated, message: "Use enhanceEquipment(_:character:useCatalyst:context:) instead")
    func enhanceEquipmentLegacy(_ item: Equipment, character: PlayerCharacter) -> Bool {
        let result = enhanceEquipment(item, character: character)
        return result.success
    }
    
    // MARK: - Premium Forge (Gem-based)
    
    /// Gem cost and level requirement for guaranteed-rarity forge crafting
    struct PremiumForgeOption: Identifiable {
        let id = UUID()
        let rarity: ItemRarity
        let gemCost: Int
        let levelRequirement: Int
    }
    
    /// Available premium forge options
    static let premiumForgeOptions: [PremiumForgeOption] = [
        PremiumForgeOption(rarity: .rare, gemCost: 5, levelRequirement: 15),
        PremiumForgeOption(rarity: .epic, gemCost: 10, levelRequirement: 25),
        PremiumForgeOption(rarity: .legendary, gemCost: 25, levelRequirement: 40),
    ]
    
    /// Craft equipment with guaranteed rarity using gems
    func forgePremiumEquipment(
        option: PremiumForgeOption,
        character: PlayerCharacter,
        context: ModelContext
    ) -> Equipment? {
        guard character.level >= option.levelRequirement else { return nil }
        guard character.gems >= option.gemCost else { return nil }
        
        character.gems -= option.gemCost
        
        let tierForRarity: Int
        switch option.rarity {
        case .common: tierForRarity = 1
        case .uncommon: tierForRarity = 2
        case .rare: tierForRarity = 3
        case .epic: tierForRarity = 4
        case .legendary: tierForRarity = 5
        }
        
        let item = LootGenerator.generateEquipment(
            tier: tierForRarity,
            luck: character.effectiveStats.luck,
            forcedRarity: option.rarity,
            playerLevel: character.level
        )
        item.ownerID = character.id
        context.insert(item)
        Task { try? await SupabaseService.shared.syncEquipment(item) }
        try? context.save()
        
        return item
    }
    
    // MARK: - Herb Crafting (Consumable Crafting)
    
    /// A recipe for crafting consumables from Herbs + Gold
    struct HerbRecipe: Identifiable {
        let id: String
        let name: String
        let description: String
        let consumableType: ConsumableType
        let icon: String
        let effectValue: Int
        let effectStat: StatType?
        let herbCost: Int
        let herbRarity: ItemRarity
        let goldCost: Int
        let levelRequirement: Int
    }
    
    /// All available herb crafting recipes (server-driven from ContentManager with fallback)
    static let herbRecipes: [HerbRecipe] = [
        // Common Herbs → Minor consumables
        HerbRecipe(
            id: "herb_minor_hp", name: "Herbal Remedy", description: "A simple potion brewed from common herbs.",
            consumableType: .hpPotion, icon: "cross.vial.fill", effectValue: 15, effectStat: nil,
            herbCost: 3, herbRarity: .common, goldCost: 30, levelRequirement: 5
        ),
        HerbRecipe(
            id: "herb_minor_exp", name: "Focus Tea", description: "A calming blend that sharpens the mind.",
            consumableType: .expBoost, icon: "bolt.fill", effectValue: 2, effectStat: nil,
            herbCost: 3, herbRarity: .common, goldCost: 40, levelRequirement: 5
        ),
        HerbRecipe(
            id: "herb_minor_gold", name: "Prospector's Brew", description: "A brew that attracts gold like a magnet.",
            consumableType: .goldBoost, icon: "dollarsign.circle.fill", effectValue: 2, effectStat: nil,
            herbCost: 3, herbRarity: .common, goldCost: 35, levelRequirement: 5
        ),
        HerbRecipe(
            id: "herb_material_magnet", name: "Lodestone Tonic", description: "Doubles crafting material drops for 5 tasks.",
            consumableType: .materialMagnet, icon: "magnet", effectValue: 5, effectStat: nil,
            herbCost: 4, herbRarity: .common, goldCost: 80, levelRequirement: 10
        ),
        // Uncommon Herbs → Standard consumables
        HerbRecipe(
            id: "herb_luck_elixir", name: "Luck Elixir", description: "A shimmering brew distilled from rare herbs.",
            consumableType: .luckElixir, icon: "sparkles", effectValue: 20, effectStat: nil,
            herbCost: 3, herbRarity: .uncommon, goldCost: 150, levelRequirement: 15
        ),
        HerbRecipe(
            id: "herb_stat_food_str", name: "Warrior's Stew", description: "A hearty meal infused with strength-boosting herbs.",
            consumableType: .statFood, icon: "dumbbell.fill", effectValue: 4, effectStat: .strength,
            herbCost: 3, herbRarity: .uncommon, goldCost: 100, levelRequirement: 12
        ),
        // Rare Herbs → Strong consumables
        HerbRecipe(
            id: "herb_forge_catalyst", name: "Forge Catalyst", description: "Volatile compounds that double enhancement success.",
            consumableType: .forgeCatalyst, icon: "bolt.trianglebadge.exclamationmark.fill", effectValue: 1, effectStat: nil,
            herbCost: 3, herbRarity: .rare, goldCost: 200, levelRequirement: 20
        ),
        HerbRecipe(
            id: "herb_party_beacon", name: "Party Beacon", description: "A radiant concoction that strengthens bonds.",
            consumableType: .partyBeacon, icon: "antenna.radiowaves.left.and.right", effectValue: 25, effectStat: nil,
            herbCost: 3, herbRarity: .rare, goldCost: 250, levelRequirement: 15
        ),
    ]
    
    /// Check if the character can afford a herb recipe
    func canAffordHerbRecipe(_ recipe: HerbRecipe, character: PlayerCharacter, context: ModelContext) -> Bool {
        guard character.level >= recipe.levelRequirement else { return false }
        guard character.gold >= recipe.goldCost else { return false }
        let herbCount = materialCount(.herb, rarity: recipe.herbRarity, characterID: character.id, context: context)
        return herbCount >= recipe.herbCost
    }
    
    /// Craft a consumable from Herbs + Gold
    func craftConsumable(
        recipe: HerbRecipe,
        character: PlayerCharacter,
        context: ModelContext
    ) -> Consumable? {
        guard canAffordHerbRecipe(recipe, character: character, context: context) else { return nil }
        
        // Deduct gold
        character.gold -= recipe.goldCost
        
        // Deduct herbs
        deductMaterial(.herb, rarity: recipe.herbRarity, amount: recipe.herbCost, characterID: character.id, context: context)
        
        // Create consumable
        let consumable = Consumable(
            name: recipe.name,
            description: recipe.description,
            consumableType: recipe.consumableType,
            icon: recipe.icon,
            effectValue: recipe.effectValue,
            effectStat: recipe.effectStat,
            remainingUses: 1,
            characterID: character.id
        )
        context.insert(consumable)
        Task { try? await SupabaseService.shared.syncConsumable(consumable) }
        
        try? context.save()
        SyncManager.shared.queueCharacterSync(character)
        
        return consumable
    }
    
    // MARK: - Auto-Salvage
    
    /// Auto-salvage settings stored in UserDefaults
    static var autoSalvageCommon: Bool {
        get { UserDefaults.standard.bool(forKey: "AutoSalvage_Common") }
        set { UserDefaults.standard.set(newValue, forKey: "AutoSalvage_Common") }
    }
    
    static var autoSalvageBelowRare: Bool {
        get { UserDefaults.standard.bool(forKey: "AutoSalvage_BelowRare") }
        set { UserDefaults.standard.set(newValue, forKey: "AutoSalvage_BelowRare") }
    }
    
    static var neverAutoSalvageAffixed: Bool {
        get {
            // Default to true (safety)
            if UserDefaults.standard.object(forKey: "AutoSalvage_NeverAffixed") == nil { return true }
            return UserDefaults.standard.bool(forKey: "AutoSalvage_NeverAffixed")
        }
        set { UserDefaults.standard.set(newValue, forKey: "AutoSalvage_NeverAffixed") }
    }
    
    /// Check if an item should be auto-salvaged based on user preferences
    static func shouldAutoSalvage(_ item: Equipment) -> Bool {
        if autoSalvageCommon && item.rarity == .common { return true }
        if autoSalvageBelowRare && (item.rarity == .common || item.rarity == .uncommon) { return true }
        return false
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
        Task { try? await SupabaseService.shared.syncEquipment(purchased) }
        try? context.save()
        return true
    }
    
    /// Buy a milestone gear item from the store
    func buyMilestoneGear(_ item: MilestoneItem, character: PlayerCharacter, context: ModelContext) -> Bool {
        guard character.gold >= item.goldCost else { return false }
        guard character.level >= item.levelRequirement else { return false }
        
        character.gold -= item.goldCost
        
        let purchased = item.toEquipment(ownerID: character.id)
        context.insert(purchased)
        Task { try? await SupabaseService.shared.syncEquipment(purchased) }
        try? context.save()
        return true
    }
    
    /// Buy a bundle deal from the store
    func buyBundle(_ bundle: BundleDeal, character: PlayerCharacter, context: ModelContext) -> Bool {
        // Check currency
        if bundle.goldCost > 0 && character.gold < bundle.goldCost { return false }
        if bundle.gemCost > 0 && character.gems < bundle.gemCost { return false }
        guard character.level >= bundle.levelRequirement else { return false }
        
        // Deduct currency
        character.gold -= bundle.goldCost
        character.gems -= bundle.gemCost
        
        // Grant equipment pieces
        for piece in bundle.equipmentPieces {
            if let template = EquipmentCatalog.find(id: piece.catalogID) {
                let equip = template.toEquipment(ownerID: character.id)
                context.insert(equip)
                Task { try? await SupabaseService.shared.syncEquipment(equip) }
            }
        }
        
        // Grant consumables
        for consumableItem in bundle.consumables {
            let allTemplates = ConsumableCatalog.items
            if let template = allTemplates.first(where: { $0.name == consumableItem.templateName }) {
                for _ in 0..<consumableItem.quantity {
                    let consumable = template.toConsumable(characterID: character.id)
                    context.insert(consumable)
                    Task { try? await SupabaseService.shared.syncConsumable(consumable) }
                }
            }
        }
        
        try? context.save()
        return true
    }
    
    /// Maximum number of regen buff consumables a player can hold at once
    static let maxRegenBuffCount = 2
    
    /// Buy a consumable from the store (supports both gold and gem costs)
    func buyConsumable(_ template: ConsumableTemplate, character: PlayerCharacter, context: ModelContext) -> Bool {
        // Check gold cost
        if template.goldCost > 0 && character.gold < template.goldCost { return false }
        // Check gem cost
        if template.gemCost > 0 && character.gems < template.gemCost { return false }
        
        // Enforce regen buff limit (max 2 held at a time)
        if template.type == .regenBuff {
            let ownedCount = Self.regenBuffCount(for: character.id, context: context)
            if ownedCount >= Self.maxRegenBuffCount { return false }
        }
        
        character.gold -= template.goldCost
        character.gems -= template.gemCost
        
        let consumable = template.toConsumable(characterID: character.id)
        context.insert(consumable)
        Task { try? await SupabaseService.shared.syncConsumable(consumable) }
        try? context.save()
        return true
    }
    
    /// Count how many regen buff consumables a character currently owns (with remaining uses)
    static func regenBuffCount(for characterID: UUID, context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<Consumable>()
        let all = (try? context.fetch(descriptor)) ?? []
        return all.filter {
            $0.characterID == characterID &&
            $0.consumableType == .regenBuff &&
            $0.remainingUses > 0
        }.count
    }
    
    // MARK: - Consumable Usage (Persistent HP)
    
    /// Use a consumable on the character. Handles HP potions (heal) and regen buffs.
    /// Returns true if successfully used, false if not applicable.
    func useConsumable(_ consumable: Consumable, on character: PlayerCharacter, context: ModelContext) -> Bool {
        guard consumable.isUsable else { return false }
        
        switch consumable.consumableType {
        case .hpPotion:
            // Heal character's persistent HP
            let oldHP = character.currentHP
            character.heal(amount: consumable.effectValue)
            let healed = character.currentHP - oldHP
            if healed > 0 {
                consumable.remainingUses -= 1
                if consumable.remainingUses <= 0 {
                    context.delete(consumable)
                }
                try? context.save()
                return true
            }
            return false // Already at max HP
            
        case .regenBuff:
            // Apply regen buff — effectValue is the regen rate, duration is tiered by cost
            let durationHours: TimeInterval
            if consumable.effectValue >= 150 {
                durationHours = 12
            } else if consumable.effectValue >= 100 {
                durationHours = 8
            } else {
                durationHours = 4
            }
            character.regenBuffExpiresAt = Date().addingTimeInterval(durationHours * 3600)
            consumable.remainingUses -= 1
            if consumable.remainingUses <= 0 {
                context.delete(consumable)
            }
            try? context.save()
            return true
            
        default:
            // Other consumables handled by their existing systems
            return false
        }
    }
    
    // MARK: - Partner Task Sync
    
    /// Fetch incoming partner tasks from the cloud and create local GameTask entries.
    /// Deduplicates by cloudID so tasks aren't imported twice.
    func fetchIncomingPartnerTasks(context: ModelContext) async {
        guard SupabaseService.shared.isAuthenticated else { return }
        
        do {
            let cloudTasks = try await SupabaseService.shared.fetchIncomingPartnerTasks()
            guard !cloudTasks.isEmpty else { return }
            
            // Fetch all local tasks to check for existing cloudIDs
            let descriptor = FetchDescriptor<GameTask>()
            let localTasks = (try? context.fetch(descriptor)) ?? []
            let existingCloudIDs = Set(localTasks.compactMap { $0.cloudID })
            
            var newCount = 0
            for cloudTask in cloudTasks {
                let cloudIDString = cloudTask.id.uuidString
                
                // Skip if already imported
                guard !existingCloudIDs.contains(cloudIDString) else { continue }
                
                // Convert cloud task to local GameTask
                let localTask = GameEngine.createLocalTask(from: cloudTask)
                context.insert(localTask)
                newCount += 1
            }
            
            if newCount > 0 {
                try? context.save()
                print("✅ Imported \(newCount) incoming partner task(s) from cloud")
            }
        } catch {
            print("❌ Failed to fetch incoming partner tasks: \(error)")
        }
    }
    
    /// Convert a CloudPartnerTask into a local GameTask.
    static func createLocalTask(from cloud: CloudPartnerTask) -> GameTask {
        let category = TaskCategory(rawValue: cloud.category) ?? .household
        let verification = VerificationType(rawValue: cloud.verificationType) ?? .none
        
        let task = GameTask(
            title: cloud.title,
            description: cloud.description,
            category: category,
            createdBy: cloud.createdBy,
            assignedTo: cloud.assignedTo,
            isOnDutyBoard: cloud.isOnDutyBoard,
            dueDate: cloud.dueDate,
            partnerMessage: cloud.partnerMessage,
            isFromPartner: true,
            verificationType: verification,
            cloudID: cloud.id.uuidString
        )
        
        return task
    }
    
    /// Sync task completion status back to the cloud.
    func syncTaskCompletionToCloud(_ task: GameTask, characterName: String) {
        guard let cloudIDString = task.cloudID,
              let cloudID = UUID(uuidString: cloudIDString) else { return }
        
        let taskTitle = task.title
        Task {
            do {
                try await SupabaseService.shared.updatePartnerTaskStatus(
                    taskID: cloudID,
                    status: "completed",
                    completedAt: task.completedAt
                )
                
                // Notify the task creator that their partner completed the task
                await PushNotificationService.shared.notifyPartnerTaskComplete(
                    characterName: characterName,
                    taskTitle: taskTitle
                )
            } catch {
                print("❌ Failed to sync task completion to cloud: \(error)")
            }
        }
    }
    
    /// Sync partner task confirmation to the cloud.
    func syncTaskConfirmationToCloud(_ task: GameTask, confirmed: Bool, characterName: String, reason: String? = nil) {
        guard let cloudIDString = task.cloudID,
              let cloudID = UUID(uuidString: cloudIDString) else { return }
        
        let taskTitle = task.title
        let charName = characterName
        Task {
            do {
                if confirmed {
                    try await SupabaseService.shared.updatePartnerTaskStatus(
                        taskID: cloudID,
                        status: "completed",
                        partnerConfirmed: true
                    )
                    await PushNotificationService.shared.notifyPartnerTaskConfirmed(
                        fromName: charName,
                        taskTitle: taskTitle
                    )
                } else {
                    try await SupabaseService.shared.updatePartnerTaskStatus(
                        taskID: cloudID,
                        status: "pending",
                        partnerConfirmed: false,
                        partnerDisputeReason: reason
                    )
                    await PushNotificationService.shared.notifyPartnerTaskDisputed(
                        fromName: charName,
                        taskTitle: taskTitle
                    )
                }
            } catch {
                print("❌ Failed to sync task confirmation to cloud: \(error)")
            }
        }
    }
    
    // MARK: - Party Progress Sync
    
    /// Refresh cached partner/party member data from the cloud.
    func refreshPartnerData(character: PlayerCharacter) async {
        guard SupabaseService.shared.isAuthenticated,
              character.hasPartner else { return }
        
        do {
            // Legacy single-partner refresh
            if let partnerProfile = try await SupabaseService.shared.fetchPartnerProfile() {
                character.partnerName = partnerProfile.characterName
                character.partnerLevel = partnerProfile.level
                character.partnerClassName = partnerProfile.characterClass
                
                // Calculate partner stat total from snapshot if available
                if let snapshot = partnerProfile.characterData {
                    let total = snapshot.strength + snapshot.wisdom + snapshot.charisma +
                                snapshot.dexterity + snapshot.luck + snapshot.defense
                    character.partnerStatTotal = total
                }
                
                print("✅ Partner data refreshed: \(partnerProfile.characterName ?? "Unknown") Lv.\(partnerProfile.level ?? 0)")
            }
            
            // Also refresh all party members' cached data
            await refreshAllPartyMemberData(character: character)
        } catch {
            print("❌ Failed to refresh partner data: \(error)")
        }
    }
    
    /// Refresh all cached party member data from the Supabase profiles table
    func refreshAllPartyMemberData(character: PlayerCharacter) async {
        guard character.isInParty else { return }
        
        do {
            var updatedMembers: [CachedPartyMember] = []
            for member in character.partyMembers {
                if let profile = try await SupabaseService.shared.fetchProfile(byID: member.id) {
                    var statTotal: Int?
                    if let snapshot = profile.characterData {
                        statTotal = snapshot.strength + snapshot.wisdom + snapshot.charisma +
                                    snapshot.dexterity + snapshot.luck + snapshot.defense
                    }
                    updatedMembers.append(CachedPartyMember(
                        id: member.id,
                        name: profile.characterName ?? member.name,
                        level: profile.level ?? member.level,
                        className: profile.characterClass ?? member.className,
                        statTotal: statTotal ?? member.statTotal,
                        avatarName: profile.avatarName ?? member.avatarName
                    ))
                } else {
                    updatedMembers.append(member)
                }
            }
            character.setPartyMembers(updatedMembers)
            print("✅ Party member data refreshed for \(updatedMembers.count) allies")
        } catch {
            print("❌ Failed to refresh party member data: \(error)")
        }
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
    
    // MARK: - Task Loot Rolls
    
    /// Roll for loot on task completion.
    /// Base rates: 5-8% equipment, 30-40% materials, 15-20% consumables
    static func rollTaskLoot(
        character: PlayerCharacter,
        lootBonus: Double = 0.0,
        context: ModelContext
    ) -> LootDrop? {
        let roll = Double.random(in: 0...1)
        let charID = character.id
        
        // Equipment: 5-8% base (use 6.5% center + loot bonus)
        let equipChance = 0.065 + lootBonus
        if roll < equipChance {
            let tier = max(1, character.level / 10 + 1)
            let equipment = LootGenerator.generateEquipment(
                tier: tier,
                luck: character.effectiveStats.luck,
                playerLevel: character.level
            )
            equipment.ownerID = charID
            context.insert(equipment)
            Task { try? await SupabaseService.shared.syncEquipment(equipment) }
            return LootDrop(type: .equipment(equipment))
        }
        
        // Materials: 30-40% base (use 35% center)
        let materialChance = equipChance + 0.35
        if roll < materialChance {
            let materialTypes: [MaterialType] = [.ore, .crystal, .hide, .herb, .essence]
            let matType = materialTypes.randomElement() ?? .essence
            let rarity: ItemRarity = {
                let r = Double.random(in: 0...1)
                if r < 0.6 { return .common }
                if r < 0.85 { return .uncommon }
                if r < 0.97 { return .rare }
                return .epic
            }()
            let qty = rarity == .common ? Int.random(in: 1...3) : 1
            return LootDrop(type: .material(matType, rarity, qty))
        }
        
        // Consumables: 15-20% base (use 17.5%)
        let consumableChance = materialChance + 0.175
        if roll < consumableChance {
            let consumableNames = ["Herbal Tea", "Energy Bar", "Lucky Coin", "Trail Mix"]
            let name = consumableNames.randomElement() ?? "Herbal Tea"
            return LootDrop(type: .consumable(name))
        }
        
        // No loot (~40% chance)
        return nil
    }
    
    // MARK: - Routine Bundle Completion
    
    /// Check if completing this habit completes a routine bundle, and award bonus EXP if so.
    func checkRoutineBundleCompletion(
        habitTask: GameTask,
        character: PlayerCharacter,
        context: ModelContext
    ) -> (completed: Bool, bonusEXP: Int) {
        let charID = character.id
        let descriptor = FetchDescriptor<RoutineBundle>(
            predicate: #Predicate<RoutineBundle> { bundle in
                bundle.ownerID == charID && bundle.isArchived == false
            }
        )
        
        guard let bundles = try? context.fetch(descriptor), !bundles.isEmpty else {
            return (false, 0)
        }
        
        // Fetch all habits for the character
        let taskDescriptor = FetchDescriptor<GameTask>(
            predicate: #Predicate<GameTask> { task in
                task.isHabit == true && task.createdBy == charID
            }
        )
        let allHabits = (try? context.fetch(taskDescriptor)) ?? []
        
        // Check if any bundle containing this habit just became complete
        for bundle in bundles {
            let habitIDs = bundle.getHabitIDs()
            guard habitIDs.contains(habitTask.id) else { continue }
            
            // Was it already complete before this task?
            let completedBefore = allHabits.filter {
                habitIDs.contains($0.id) && $0.id != habitTask.id && $0.isHabitCompletedToday
            }.count
            
            // If all OTHER habits were already done, this one completes the bundle
            if completedBefore == habitIDs.count - 1 {
                // Calculate routine bonus: +50% of the total EXP from all habits in the bundle
                let baseRoutineEXP = Int(Double(habitTask.expReward) * GameTask.levelScaleFactor(level: character.level))
                let bonusEXP = Int(Double(baseRoutineEXP) * RoutineBundle.completionBonusMultiplier) * habitIDs.count
                return (true, bonusEXP)
            }
        }
        
        return (false, 0)
    }
    
    // MARK: - Meditation Wisdom Buff
    
    /// Grant the Wisdom buff after meditation completion (+5% Wisdom for 24 hours)
    func grantWisdomBuff(character: PlayerCharacter) {
        character.wisdomBuffExpiresAt = Date().addingTimeInterval(24 * 60 * 60) // 24 hours
    }
    
    // MARK: - Streak Freeze
    
    /// Apply a streak freeze when the player misses a day (consumes one charge)
    /// Call this during daily reset check when a streak would normally break
    func applyStreakFreezeIfAvailable(character: PlayerCharacter) -> Bool {
        guard character.streakFreezeCharges > 0 else { return false }
        character.streakFreezeCharges -= 1
        // Streak is preserved — don't reset it
        return true
    }
    
    // MARK: - Opportunity Cost Messaging
    
    /// Generate an opportunity cost message for a missed habit (no punishment, just what they missed)
    static func opportunityCostMessage(
        habit: GameTask,
        character: PlayerCharacter
    ) -> String {
        let potentialEXP = habit.scaledExpReward(characterLevel: character.level)
        let potentialGold = habit.scaledGoldReward(characterLevel: character.level)
        
        if habit.habitStreak > 0 {
            return "Your streak was at \(habit.habitStreak) days. Complete today to keep it going! (Potential: +\(potentialEXP) EXP, +\(potentialGold) Gold)"
        } else {
            return "You could earn +\(potentialEXP) EXP and +\(potentialGold) Gold by completing this today."
        }
    }
    
    // MARK: - Goal Progress
    
    /// Calculate goal progress as a value between 0.0 and 1.0.
    static func calculateGoalProgress(goal: Goal, tasks: [GameTask]) -> Double {
        let linked = tasks.filter { $0.goalID == goal.id }
        guard !linked.isEmpty else { return 0 }
        let completed = linked.filter {
            $0.status == .completed || ($0.isHabit && $0.habitStreak > 0)
        }.count
        return Double(completed) / Double(linked.count)
    }
    
    /// Check and update goal milestones after a task completion.
    /// Call this after completing any task that has a goalID.
    func checkGoalMilestones(goalID: UUID, character: PlayerCharacter, context: ModelContext) {
        let descriptor = FetchDescriptor<Goal>(predicate: #Predicate { $0.id == goalID })
        guard let goal = try? context.fetch(descriptor).first,
              goal.status == .active else { return }
        
        let taskDescriptor = FetchDescriptor<GameTask>()
        let allTasks = (try? context.fetch(taskDescriptor)) ?? []
        let progress = GameEngine.calculateGoalProgress(goal: goal, tasks: allTasks)
        
        // Check each milestone
        for milestone in GoalMilestone.allCases {
            let threshold = Double(milestone.rawValue) / 100.0
            if progress >= threshold && !goal.isMilestoneClaimed(milestone) {
                // Show a toast that the milestone is ready to claim
                ToastManager.shared.showReward(
                    "\(goal.title): \(milestone.label) reached!",
                    subtitle: "Tap to claim your reward"
                )
                break // Only notify for the first unclaimed milestone
            }
        }
        
        // Auto-complete goal when 100% and all milestones claimed
        if progress >= 1.0 && goal.milestone100Claimed && goal.status == .active {
            goal.status = .completed
            goal.completedAt = Date()
        }
        
        // Queue goal sync via SyncManager
        if let userID = SupabaseService.shared.currentUserID {
            SyncManager.shared.queueGoalSync(goal, playerID: userID)
        }
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
    
    /// Co-op duty fields
    let isCoopDuty: Bool
    let coopBonusEXP: Int
    let coopBonusGold: Int
    let coopBondEXP: Int
    let coopPartnerCompleted: Bool
    
    /// Loot roll results
    let lootDropped: LootDrop?
    
    /// Verification tier that was applied
    let verificationTier: VerificationTier
    
    /// Class affinity bonus EXP (included in expGained, shown separately for display)
    let classAffinityBonusEXP: Int
    
    /// Class-flavored completion message
    let classMessage: String?
    
    /// Whether a routine bundle was just completed by this task
    let routineBundleCompleted: Bool
    
    /// Routine completion bonus EXP (included in expGained)
    let routineBonusEXP: Int
    
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
        anomalyFlags: [AnomalyFlag] = [],
        isCoopDuty: Bool = false,
        coopBonusEXP: Int = 0,
        coopBonusGold: Int = 0,
        coopBondEXP: Int = 0,
        coopPartnerCompleted: Bool = false,
        lootDropped: LootDrop? = nil,
        verificationTier: VerificationTier = .quick,
        classAffinityBonusEXP: Int = 0,
        classMessage: String? = nil,
        routineBundleCompleted: Bool = false,
        routineBonusEXP: Int = 0
    ) {
        self.expGained = expGained
        self.goldGained = goldGained
        self.bonusStatGains = bonusStatGains
        self.verificationMultiplier = verificationMultiplier
        self.levelUpRewards = levelUpRewards
        self.didLevelUp = didLevelUp
        self.pendingPartnerConfirmation = pendingPartnerConfirmation
        self.anomalyFlags = anomalyFlags
        self.isCoopDuty = isCoopDuty
        self.coopBonusEXP = coopBonusEXP
        self.coopBonusGold = coopBonusGold
        self.coopBondEXP = coopBondEXP
        self.coopPartnerCompleted = coopPartnerCompleted
        self.lootDropped = lootDropped
        self.verificationTier = verificationTier
        self.classAffinityBonusEXP = classAffinityBonusEXP
        self.classMessage = classMessage
        self.routineBundleCompleted = routineBundleCompleted
        self.routineBonusEXP = routineBonusEXP
    }
}

/// Represents a loot drop from task completion
struct LootDrop {
    enum LootType {
        case equipment(Equipment)
        case material(MaterialType, ItemRarity, Int)   // type, rarity, quantity
        case consumable(String)                        // consumable template name
    }
    
    let type: LootType
    
    var displayName: String {
        switch type {
        case .equipment(let item): return item.name
        case .material(let matType, _, let qty): return "\(qty)x \(matType.rawValue)"
        case .consumable(let name): return name
        }
    }
    
    var icon: String {
        switch type {
        case .equipment(let item): return item.slot.icon
        case .material: return "cube.fill"
        case .consumable: return "cross.vial.fill"
        }
    }
    
    var rarityColor: String {
        switch type {
        case .equipment(let item): return item.rarity.color
        case .material(_, let rarity, _): return rarity.color
        case .consumable: return "RarityUncommon"
        }
    }
}

// MARK: - Expedition Stage Resolution

extension GameEngine {
    
    /// Resolve the current stage of an active expedition.
    /// Calculates success based on character stats vs stage difficulty,
    /// rolls for loot, materials, and cards, then records the result.
    func resolveExpeditionStage(
        active: ActiveExpedition,
        character: PlayerCharacter
    ) -> StageResult {
        let stageIndex = active.currentStageIndex
        
        // Load expedition template to get stage data
        let contentExpeditions = ContentManager.shared.expeditions
        let template = contentExpeditions.first { $0.id == active.expeditionID }
        
        // Get stage data from template or use sensible defaults
        let stagePrimaryStat: StatType
        let stageDifficultyRating: Int
        let stageRewards: StageRewards
        let stageNarrative: String
        
        if let template = template, stageIndex < template.stages.count {
            let contentStage = template.stages[stageIndex]
            stagePrimaryStat = StatType(rawValue: contentStage.primaryStat.capitalized) ?? .strength
            stageDifficultyRating = contentStage.difficultyRating
            stageRewards = StageRewards(
                exp: contentStage.possibleRewards.exp,
                gold: contentStage.possibleRewards.gold,
                equipmentChance: contentStage.possibleRewards.equipmentChance,
                materialChance: contentStage.possibleRewards.materialChance,
                cardChance: contentStage.possibleRewards.cardChance
            )
            stageNarrative = contentStage.narrativeText
        } else {
            // Fallback defaults
            stagePrimaryStat = .strength
            stageDifficultyRating = 5
            stageRewards = StageRewards(exp: 50, gold: 30, equipmentChance: 0.20, materialChance: 0.50, cardChance: 0.15)
            stageNarrative = "The party ventures deeper into the unknown..."
        }
        
        // Calculate success chance per design doc:
        // Success Chance = (Combined Power / Stage Power) × 100, capped at 90%
        let statPower = Double(character.effectiveStats.value(for: stagePrimaryStat))
        let stagePower = Double(stageDifficultyRating)
        let successChance = min(0.90, statPower / max(1, stagePower))
        
        let roll = Double.random(in: 0...1)
        let success = roll <= successChance
        
        // Calculate rewards
        let expEarned: Int
        let goldEarned: Int
        
        if success {
            expEarned = stageRewards.exp
            goldEarned = stageRewards.gold
        } else {
            // Failed stages: reduced rewards but expedition continues
            expEarned = max(5, stageRewards.exp / 3)
            goldEarned = max(2, stageRewards.gold / 3)
        }
        
        // Roll for equipment drop (expedition-exclusive loot table)
        var lootName: String? = nil
        if success && Double.random(in: 0...1) <= stageRewards.equipmentChance {
            let equipment = LootGenerator.generateEquipment(
                tier: 3, // Expedition tier = 3 (Epic+ quality)
                luck: character.effectiveStats.luck,
                characterClass: character.characterClass,
                playerLevel: character.level
            )
            lootName = equipment.name
        }
        
        // Roll for materials
        let materialDropped = success && Double.random(in: 0...1) <= stageRewards.materialChance
        
        // Roll for card
        let cardDropped = success && Double.random(in: 0...1) <= stageRewards.cardChance
        
        // Generate narrative log
        let narrativeLog: String
        if success {
            let successNarratives = [
                "\(stageNarrative) Your party overcame the challenge with skill and determination.",
                "\(stageNarrative) The obstacles fell before your combined might.",
                "\(stageNarrative) Victory! The path forward is clear.",
            ]
            narrativeLog = successNarratives.randomElement() ?? stageNarrative
        } else {
            let failureNarratives = [
                "\(stageNarrative) The challenge proved formidable — your party barely pushed through.",
                "\(stageNarrative) Setbacks slowed your progress, but the expedition continues.",
                "\(stageNarrative) A difficult passage — some rewards were lost in the struggle.",
            ]
            narrativeLog = failureNarratives.randomElement() ?? stageNarrative
        }
        
        let result = StageResult(
            stageIndex: stageIndex,
            success: success,
            narrativeLog: narrativeLog,
            earnedEXP: expEarned,
            earnedGold: goldEarned,
            lootDroppedName: lootName,
            materialDropped: materialDropped,
            cardDropped: cardDropped
        )
        
        // Record the result (advances stage or marks completion)
        active.recordStageResult(result)
        
        // Update pity counter
        if lootName == nil {
            character.incrementPityCounter(for: "expeditions")
        } else {
            character.resetPityCounter(for: "expeditions")
        }
        
        return result
    }
    
    /// Award an Expedition Key after a Hard+ dungeon completion
    static func rollExpeditionKeyDrop(difficulty: DungeonDifficulty) -> Bool {
        switch difficulty {
        case .hard:
            return true  // Guaranteed 1 key from Hard
        case .heroic:
            return true  // Guaranteed 1 key from Heroic
        case .mythic:
            // Mythic drops 1 key guaranteed, bonus 2nd key at 30%
            ExpeditionKeyStore.add(1)
            if Double.random(in: 0...1) <= 0.30 {
                ExpeditionKeyStore.add(1)
            }
            return true
        case .normal:
            return false // Normal difficulty doesn't drop keys
        }
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
    
    /// Number of Research Tokens dropped (mission-exclusive)
    var researchTokensDropped: Int = 0
    
    /// Class the character ranked up to (nil if not a rank-up training)
    var rankedUpToClass: CharacterClass? = nil
}

/// Result of a meditation session
struct MeditationResult {
    let expGained: Int
    let goldGained: Int
    let streak: Int
    let levelUpRewards: [LevelUpReward]
    let wisdomBuffGranted: Bool
    
    init(
        expGained: Int,
        goldGained: Int,
        streak: Int,
        levelUpRewards: [LevelUpReward],
        wisdomBuffGranted: Bool = false
    ) {
        self.expGained = expGained
        self.goldGained = goldGained
        self.streak = streak
        self.levelUpRewards = levelUpRewards
        self.wisdomBuffGranted = wisdomBuffGranted
    }
}

/// Result of attacking a raid boss
struct RaidAttackResult {
    let damage: Int
    let bossDefeated: Bool
    let remainingHP: Int
    let maxHP: Int
}

/// Result of a mood check-in
struct MoodCheckInResult {
    let expGained: Int
    let goldGained: Int
    let streak: Int
    let streakMultiplier: Double
}

