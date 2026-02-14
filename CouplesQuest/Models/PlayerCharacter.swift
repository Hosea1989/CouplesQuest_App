import Foundation
import SwiftData

/// The player's RPG character that levels up through completing real-life tasks
@Model
final class PlayerCharacter {
    /// Unique identifier
    var id: UUID
    
    /// The Supabase auth user ID that owns this character.
    /// Used to enforce one-character-per-account and prevent duplicates on multi-device sign-in.
    var supabaseUserID: String?
    
    /// Character name chosen by player
    var name: String
    
    /// Current level (1-100)
    var level: Int
    
    /// Current experience points
    var currentEXP: Int
    
    /// Character class (chosen at creation)
    var characterClass: CharacterClass?
    
    /// Zodiac sign (chosen at creation, grants +2 to a stat)
    var zodiacSign: ZodiacSign?
    
    /// Base stats
    @Relationship(deleteRule: .cascade)
    var stats: Stats
    
    /// Equipped items
    @Relationship(deleteRule: .cascade)
    var equipment: EquipmentLoadout
    
    /// Earned achievements
    @Relationship(deleteRule: .cascade)
    var achievements: [Achievement]
    
    /// Total tasks completed
    var tasksCompleted: Int
    
    /// Current daily streak
    var currentStreak: Int
    
    /// Longest streak achieved
    var longestStreak: Int
    
    /// In-game currency
    var gold: Int
    
    /// Premium currency (earned rarely)
    var gems: Int
    
    /// Date character was created
    var createdAt: Date
    
    /// Last activity date
    var lastActiveAt: Date
    
    /// Partner's character ID for syncing (legacy — first ally in party)
    var partnerCharacterID: UUID?
    
    /// Cached partner name (for display without CloudKit)
    var partnerName: String?
    
    /// Cached partner level
    var partnerLevel: Int?
    
    /// Cached partner class (stored as raw string)
    var partnerClassName: String?
    
    /// Cached partner stat total (for co-op dungeon simulation)
    var partnerStatTotal: Int?
    
    // MARK: - Party Members (1–4)
    
    /// JSON-encoded array of party member info dicts: [{id, name, level, className, statTotal}]
    /// Includes ALL members except self. Max 3 entries.
    var partyMembersJSON: String
    
    /// Supabase party ID (links to `parties` table)
    var partyID: UUID?
    
    /// Whether party mood sharing is enabled (Settings toggle)
    var partyMoodSharingEnabled: Bool
    
    /// Tasks completed today (resets daily)
    var tasksCompletedToday: Int
    
    /// Duty board tasks completed today (max 3, resets daily)
    var dutiesCompletedToday: Int
    
    /// Date of last daily reset
    var lastDailyReset: Date
    
    /// Unspent stat points available for allocation
    var unspentStatPoints: Int
    
    // unspentSkillPoints removed — skills are now Bond perks
    
    /// Avatar icon SF Symbol name
    var avatarIcon: String
    
    /// Avatar frame style name
    var avatarFrame: String
    
    /// Custom avatar photo data (JPEG). When set, displayed instead of the SF Symbol icon.
    @Attribute(.externalStorage) var avatarImageData: Data?
    
    // MARK: - Meditation
    
    /// Date of last meditation (for daily check)
    var lastMeditationDate: Date?
    
    /// Consecutive days of meditation
    var meditationStreak: Int
    
    // MARK: - Forge
    
    /// Forge shards earned from salvaging equipment
    var forgeShards: Int
    
    // MARK: - Mood Tracking
    
    /// Consecutive days of mood check-ins
    var moodStreak: Int
    
    /// Date of last mood check-in
    var lastMoodDate: Date?
    
    // MARK: - Arena
    
    /// Personal best arena wave reached
    var arenaBestWave: Int
    
    /// Number of arena attempts used today
    var arenaAttemptsToday: Int
    
    /// Date of last arena attempt (for daily reset)
    var lastArenaDate: Date?
    
    // MARK: - Persistent HP
    
    /// Current hit points — persists between sessions, dungeons, and arena runs.
    /// Potions are the only way to heal directly; passive regen ticks 50 HP/hour.
    var currentHP: Int
    
    /// Timestamp of last HP update (for calculating passive regen while offline)
    var lastHPUpdateAt: Date
    
    /// When the regen buff expires (nil = no active buff, base 50 HP/hr only)
    var regenBuffExpiresAt: Date?
    
    // MARK: - Onboarding & Retention
    
    /// Whether the player has completed the post-creation onboarding flow
    var hasCompletedOnboarding: Bool
    
    /// Breadcrumb quest log tracking (key = breadcrumb ID, value = completed)
    /// Used for the first-7-days guided "next step" cards on HomeView
    var onboardingBreadcrumbs: [String: Bool]
    
    /// Current day in the 7-day login reward cycle (1-7)
    var loginStreakDay: Int
    
    /// Date of last claimed daily login reward (prevents double-claiming)
    var lastLoginRewardDate: Date?
    
    /// Whether the comeback gift has been claimed for the current lapse period
    var comebackGiftClaimed: Bool
    
    /// Number of re-engagement notifications sent during the current lapse
    var reengagementNotificationsSent: Int
    
    // MARK: - Category Mastery
    
    /// Number of Physical tasks completed (lifetime)
    var masteryPhysicalCount: Int
    
    /// Number of Mental tasks completed (lifetime)
    var masteryMentalCount: Int
    
    /// Number of Social tasks completed (lifetime)
    var masterySocialCount: Int
    
    /// Number of Household tasks completed (lifetime)
    var masteryHouseholdCount: Int
    
    /// Number of Wellness tasks completed (lifetime)
    var masteryWellnessCount: Int
    
    /// Number of Creative tasks completed (lifetime)
    var masteryCreativeCount: Int
    
    // MARK: - Personal Records
    
    /// Most tasks completed in a single day (all-time)
    var recordMostTasksInDay: Int
    
    /// Date when the daily tasks record was set
    var recordMostTasksDate: Date?
    
    /// Longest streak per category (stored as JSON-encoded dictionary)
    /// Keys are TaskCategory raw values, values are longest streak counts
    var categoryLongestStreaks: String
    
    // MARK: - Meditation Wisdom Buff
    
    /// When the Wisdom buff from meditation expires (nil = no active buff)
    var wisdomBuffExpiresAt: Date?
    
    /// Whether the Wisdom buff is currently active
    var hasActiveWisdomBuff: Bool {
        guard let expiry = wisdomBuffExpiresAt else { return false }
        return Date() < expiry
    }
    
    /// Wisdom buff multiplier (5% when active, 0% otherwise)
    var wisdomBuffMultiplier: Double {
        hasActiveWisdomBuff ? 0.05 : 0.0
    }
    
    // MARK: - Streak Freeze
    
    /// Number of active streak freeze charges (consumed from Streak Shield items)
    var streakFreezeCharges: Int
    
    // MARK: - Pity Counters (Bad Luck Protection)
    
    /// JSON-encoded pity counters per content type: {"tasks": 5, "dungeons": 3, "missions": 2}
    /// Incremented on dry runs (no equipment drop), reset to 0 on any equipment drop.
    var pityCountersJSON: String
    
    // MARK: - Monster Card Bonuses
    
    /// Cached card collection power bonus for hero power calculation.
    /// Updated whenever a new card is collected (avoids expensive query on every heroPower access).
    var cachedCardPowerBonus: Int
    
    /// Cached card EXP bonus (e.g. 0.05 = +5%). Updated on card collection.
    var cachedCardExpBonus: Double
    
    /// Cached card Gold bonus (e.g. 0.03 = +3%). Updated on card collection.
    var cachedCardGoldBonus: Double
    
    /// Cached card Loot Chance bonus (e.g. 0.02 = +2%). Updated on card collection.
    var cachedCardLootBonus: Double
    
    // MARK: - Research Tree
    
    /// JSON-encoded array of completed research node IDs: ["combat_1", "efficiency_1", ...]
    var completedResearchNodeIDs: String
    
    /// ID of the node currently being researched (nil = nothing researching)
    var activeResearchNodeID: String?
    
    /// When the current research was started
    var researchStartDate: Date?
    
    /// When the current research will complete
    var researchCompletionDate: Date?
    
    /// Cached research power bonus for hero power calculation.
    /// Updated whenever a research node is completed.
    var cachedResearchPowerBonus: Int
    
    // MARK: - Prestige / End-Game
    
    /// Paragon level (post-100 infinite progression). 0 means not yet paragon.
    var paragonLevel: Int
    
    /// Number of times the player has performed a Rebirth (prestige reset)
    var rebirthCount: Int
    
    /// JSON-encoded permanent rebirth bonuses: {"expBonus": 0.05, "goldBonus": 0.05, "lootBonus": 0.05, "allStatsBonus": 0.04}
    /// Accumulated across all rebirths. Applied multiplicatively to EXP, Gold, Loot, and Stats.
    var permanentBonusesJSON: String
    
    // MARK: - Sync
    
    /// Timestamp of last successful cloud sync
    var lastSyncTimestamp: Date?
    
    init(
        name: String,
        stats: Stats = Stats(),
        equipment: EquipmentLoadout = EquipmentLoadout()
    ) {
        self.id = UUID()
        self.supabaseUserID = nil
        self.name = name
        self.level = 1
        self.currentEXP = 0
        self.characterClass = nil
        self.zodiacSign = nil
        self.stats = stats
        self.equipment = equipment
        self.achievements = []
        self.tasksCompleted = 0
        self.currentStreak = 0
        self.longestStreak = 0
        self.gold = 0
        self.gems = 0
        self.createdAt = Date()
        self.lastActiveAt = Date()
        self.partnerCharacterID = nil
        self.partnerName = nil
        self.partnerLevel = nil
        self.partnerClassName = nil
        self.partnerStatTotal = nil
        self.partyMembersJSON = "[]"
        self.partyID = nil
        self.partyMoodSharingEnabled = false
        self.tasksCompletedToday = 0
        self.dutiesCompletedToday = 0
        self.lastDailyReset = Date()
        self.unspentStatPoints = 0
        // unspentSkillPoints removed
        self.avatarIcon = "person.fill"
        self.avatarFrame = "default"
        self.avatarImageData = nil
        self.lastMeditationDate = nil
        self.meditationStreak = 0
        self.forgeShards = 0
        self.moodStreak = 0
        self.lastMoodDate = nil
        self.arenaBestWave = 0
        self.arenaAttemptsToday = 0
        self.lastArenaDate = nil
        // Persistent HP — starts at 100 base; recalculated to maxHP once class is chosen
        self.currentHP = 100
        self.lastHPUpdateAt = Date()
        self.regenBuffExpiresAt = nil
        self.hasCompletedOnboarding = false
        self.onboardingBreadcrumbs = [:]
        self.loginStreakDay = 1
        self.lastLoginRewardDate = nil
        self.comebackGiftClaimed = false
        self.reengagementNotificationsSent = 0
        // Category mastery
        self.masteryPhysicalCount = 0
        self.masteryMentalCount = 0
        self.masterySocialCount = 0
        self.masteryHouseholdCount = 0
        self.masteryWellnessCount = 0
        self.masteryCreativeCount = 0
        // Personal records
        self.recordMostTasksInDay = 0
        self.recordMostTasksDate = nil
        self.categoryLongestStreaks = "{}"
        // Meditation wisdom buff
        self.wisdomBuffExpiresAt = nil
        // Streak freeze
        self.streakFreezeCharges = 0
        // Pity counters
        self.pityCountersJSON = "{}"
        // Card bonuses
        self.cachedCardPowerBonus = 0
        self.cachedCardExpBonus = 0
        self.cachedCardGoldBonus = 0
        self.cachedCardLootBonus = 0
        // Research tree
        self.completedResearchNodeIDs = "[]"
        self.activeResearchNodeID = nil
        self.researchStartDate = nil
        self.researchCompletionDate = nil
        self.cachedResearchPowerBonus = 0
        // Prestige
        self.paragonLevel = 0
        self.rebirthCount = 0
        self.permanentBonusesJSON = "{}"
        self.lastSyncTimestamp = nil
    }
    
    // MARK: - Card Bonus Helpers
    
    /// Update the cached card power bonus from the current card collection.
    /// Call this after collecting a new card.
    func updateCachedCardPowerBonus(cards: [MonsterCard]) {
        let summary = CardBonusCalculator.totalBonuses(from: cards)
        cachedCardPowerBonus = summary.powerScoreBonus
        cachedCardExpBonus = summary.expPercent
        cachedCardGoldBonus = summary.goldPercent
        cachedCardLootBonus = summary.lootChancePercent
    }
    
    // MARK: - Research Tree Helpers
    
    /// Decoded list of completed research node IDs
    var completedResearchNodes: [String] {
        get {
            guard let data = completedResearchNodeIDs.data(using: .utf8),
                  let ids = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return ids
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                completedResearchNodeIDs = json
            }
        }
    }
    
    /// Whether a specific research node has been completed
    func hasCompletedResearchNode(_ nodeID: String) -> Bool {
        completedResearchNodes.contains(nodeID)
    }
    
    /// Whether a specific research node is currently being researched
    func isResearching(_ nodeID: String) -> Bool {
        activeResearchNodeID == nodeID
    }
    
    /// Whether any research is currently in progress
    var isResearchActive: Bool {
        activeResearchNodeID != nil && researchCompletionDate != nil
    }
    
    /// Whether the current research has completed (timer expired)
    var isResearchComplete: Bool {
        guard let completionDate = researchCompletionDate else { return false }
        return Date() >= completionDate
    }
    
    /// Time remaining on current research (nil if nothing active)
    var researchTimeRemaining: TimeInterval? {
        guard let completionDate = researchCompletionDate else { return nil }
        let remaining = completionDate.timeIntervalSince(Date())
        return max(0, remaining)
    }
    
    /// Progress of current research (0.0 to 1.0)
    var researchProgress: Double {
        guard let startDate = researchStartDate,
              let completionDate = researchCompletionDate else { return 0 }
        let total = completionDate.timeIntervalSince(startDate)
        let elapsed = Date().timeIntervalSince(startDate)
        guard total > 0 else { return 1.0 }
        return min(1.0, max(0.0, elapsed / total))
    }
    
    /// Whether a node can be unlocked (prerequisites met)
    func canUnlockResearchNode(_ node: ResearchNode) -> Bool {
        // Already completed
        if hasCompletedResearchNode(node.id) { return false }
        // Currently researching something else
        if isResearchActive && !isResearchComplete { return false }
        // Check prerequisite
        if let prereq = node.prerequisiteNodeID {
            if !hasCompletedResearchNode(prereq) { return false }
        }
        return true
    }
    
    /// Start researching a node
    func startResearch(node: ResearchNode) {
        activeResearchNodeID = node.id
        researchStartDate = Date()
        researchCompletionDate = Date().addingTimeInterval(node.researchDurationHours * 3600)
    }
    
    /// Complete the current research and add to completed nodes
    func completeResearch() {
        guard let nodeID = activeResearchNodeID else { return }
        var completed = completedResearchNodes
        if !completed.contains(nodeID) {
            completed.append(nodeID)
            completedResearchNodes = completed
        }
        activeResearchNodeID = nil
        researchStartDate = nil
        researchCompletionDate = nil
        
        // Update cached bonus
        updateCachedResearchPowerBonus()
    }
    
    /// Update the cached research power bonus from completed nodes.
    /// Call this after completing a research node.
    func updateCachedResearchPowerBonus() {
        let summary = ResearchBonusSummary.calculate(from: completedResearchNodes)
        cachedResearchPowerBonus = summary.powerScoreBonus
    }
    
    /// Get the aggregated research bonus summary
    var researchBonuses: ResearchBonusSummary {
        ResearchBonusSummary.calculate(from: completedResearchNodes)
    }
    
    /// Number of completed research nodes
    var completedResearchCount: Int {
        completedResearchNodes.count
    }
    
    /// Total number of research nodes available
    var totalResearchNodes: Int {
        ResearchTree.allNodes.count
    }
    
    // MARK: - Prestige Helpers
    
    /// Decoded permanent rebirth bonuses
    func getPermanentBonuses() -> [String: Double] {
        guard let data = permanentBonusesJSON.data(using: .utf8),
              let dict = try? JSONDecoder().decode([String: Double].self, from: data) else {
            return [:]
        }
        return dict
    }
    
    /// Set permanent rebirth bonuses from a dictionary
    func setPermanentBonuses(_ bonuses: [String: Double]) {
        if let data = try? JSONEncoder().encode(bonuses),
           let json = String(data: data, encoding: .utf8) {
            permanentBonusesJSON = json
        }
    }
    
    /// Permanent EXP bonus from rebirths (e.g. 0.05 = +5%)
    var rebirthEXPBonus: Double {
        getPermanentBonuses()["expBonus"] ?? 0.0
    }
    
    /// Permanent Gold bonus from rebirths (e.g. 0.05 = +5%)
    var rebirthGoldBonus: Double {
        getPermanentBonuses()["goldBonus"] ?? 0.0
    }
    
    /// Permanent Loot drop chance bonus from rebirths (e.g. 0.05 = +5%)
    var rebirthLootBonus: Double {
        getPermanentBonuses()["lootBonus"] ?? 0.0
    }
    
    /// Permanent all-stats bonus from rebirths (e.g. 0.03 = +3%)
    var rebirthAllStatsBonus: Double {
        getPermanentBonuses()["allStatsBonus"] ?? 0.0
    }
    
    /// Whether the player is eligible for Paragon leveling (level 100+)
    var isParagonEligible: Bool {
        level >= 100
    }
    
    /// Whether the player is eligible to perform a Rebirth
    var canRebirth: Bool {
        level >= 100
    }
    
    /// Display-friendly paragon level string (e.g. "Paragon 5")
    var paragonDisplayString: String? {
        guard paragonLevel > 0 else { return nil }
        return "Paragon \(paragonLevel)"
    }
    
    /// The title bestowed by the current rebirth count
    var rebirthTitle: String? {
        switch rebirthCount {
        case 0: return nil
        case 1: return "Reborn"
        case 2: return "Twice-Forged"
        case 3: return "Thrice-Blessed"
        case 4: return "Ascendant"
        default: return "Eternal \(characterClass?.rawValue ?? "Hero")"
        }
    }
    
    /// Apply the bonuses for the next rebirth (called during rebirth process)
    func applyRebirthBonuses() {
        var bonuses = getPermanentBonuses()
        
        switch rebirthCount {
        case 1:
            // 1st rebirth: +5% EXP
            bonuses["expBonus", default: 0.0] += 0.05
        case 2:
            // 2nd rebirth: +5% Gold
            bonuses["goldBonus", default: 0.0] += 0.05
        case 3:
            // 3rd rebirth: +5% Loot drop chance
            bonuses["lootBonus", default: 0.0] += 0.05
        case 4:
            // 4th rebirth: +3% all stats
            bonuses["allStatsBonus", default: 0.0] += 0.03
        default:
            // 5th+ rebirth: +1% all stats per rebirth (stacking)
            bonuses["allStatsBonus", default: 0.0] += 0.01
        }
        
        setPermanentBonuses(bonuses)
    }
    
    /// Perform Paragon level-up: +1 random stat + small gold reward
    /// Returns the stat that was boosted and the gold amount
    func performParagonLevelUp() -> (stat: StatType, gold: Int) {
        paragonLevel += 1
        
        // Random stat boost
        let allStats = StatType.allCases
        let randomStat = allStats[Int.random(in: 0..<allStats.count)]
        stats.increase(randomStat, by: 1)
        
        // Small gold reward scaling with paragon level
        let goldReward = 100 + (paragonLevel * 10)
        gold += goldReward
        
        return (stat: randomStat, gold: goldReward)
    }
    
    /// Perform a full Rebirth: reset level/class, keep gear/cards/achievements, gain permanent bonus
    func performRebirth() {
        // Increment rebirth count FIRST so applyRebirthBonuses uses the correct count
        rebirthCount += 1
        
        // Apply the permanent bonus for this rebirth
        applyRebirthBonuses()
        
        // Reset level to 1
        level = 1
        currentEXP = 0
        paragonLevel = 0
        
        // Reset class to nil (player picks new starter class)
        characterClass = nil
        
        // Reset stat points — keep base stats from level 1, clear allocated points
        // Re-allocate as if starting fresh: base class stats will be re-applied when class is chosen
        unspentStatPoints = 0
        
        // Reset stats to base (level 1 defaults)
        stats.strength = 5
        stats.wisdom = 5
        stats.charisma = 5
        stats.dexterity = 5
        stats.luck = 5
        stats.defense = 5
        
        // Update avatar frame to rebirth star if not already
        if avatarFrame != "rebirth" {
            avatarFrame = "rebirth"
        }
        
        lastActiveAt = Date()
    }
    
    // MARK: - Meditation Helpers
    
    /// Whether the character has meditated today
    var hasMeditatedToday: Bool {
        guard let lastDate = lastMeditationDate else { return false }
        return Calendar.current.isDateInToday(lastDate)
    }
    
    /// Check and update meditation streak
    func checkMeditationStreak() {
        guard let lastDate = lastMeditationDate else { return }
        let calendar = Calendar.current
        let daysDiff = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastDate), to: calendar.startOfDay(for: Date())).day ?? 0
        if daysDiff > 1 {
            meditationStreak = 0
        }
    }
    
    /// Meditation EXP reward (with streak bonus)
    var meditationExpReward: Int {
        checkMeditationStreak()
        let base = level * 8
        let streakMultiplier = 1.0 + min(0.5, Double(meditationStreak) * 0.05)
        return Int(Double(base) * streakMultiplier)
    }
    
    /// Meditation gold reward
    var meditationGoldReward: Int {
        level * 3
    }
    
    // MARK: - Mood Helpers
    
    /// Whether the character has logged mood today
    var hasLoggedMoodToday: Bool {
        guard let lastDate = lastMoodDate else { return false }
        return Calendar.current.isDateInToday(lastDate)
    }
    
    /// Check and update mood streak
    func checkMoodStreak() {
        guard let lastDate = lastMoodDate else { return }
        let calendar = Calendar.current
        let daysDiff = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastDate), to: calendar.startOfDay(for: Date())).day ?? 0
        if daysDiff > 1 {
            moodStreak = 0
        }
    }
    
    // MARK: - Category Mastery Helpers
    
    /// Get mastery count for a category
    func masteryCount(for category: TaskCategory) -> Int {
        switch category {
        case .physical: return masteryPhysicalCount
        case .mental: return masteryMentalCount
        case .social: return masterySocialCount
        case .household: return masteryHouseholdCount
        case .wellness: return masteryWellnessCount
        case .creative: return masteryCreativeCount
        }
    }
    
    /// Increment mastery count for a category
    func incrementMastery(for category: TaskCategory) {
        switch category {
        case .physical: masteryPhysicalCount += 1
        case .mental: masteryMentalCount += 1
        case .social: masterySocialCount += 1
        case .household: masteryHouseholdCount += 1
        case .wellness: masteryWellnessCount += 1
        case .creative: masteryCreativeCount += 1
        }
    }
    
    /// Mastery level for a category (every 25 tasks = 1 level, max 20)
    func masteryLevel(for category: TaskCategory) -> Int {
        min(20, masteryCount(for: category) / 25)
    }
    
    /// Mastery level title
    static func masteryTitle(level: Int) -> String {
        switch level {
        case 0: return "Beginner"
        case 1...3: return "Novice"
        case 4...6: return "Apprentice"
        case 7...9: return "Journeyman"
        case 10...12: return "Adept"
        case 13...15: return "Expert"
        case 16...18: return "Master"
        case 19...20: return "Grandmaster"
        default: return "Unknown"
        }
    }
    
    // MARK: - Personal Records Helpers
    
    /// Update the most-tasks-in-a-day record (call after incrementing tasksCompletedToday)
    func updateDailyTaskRecord() {
        if tasksCompletedToday > recordMostTasksInDay {
            recordMostTasksInDay = tasksCompletedToday
            recordMostTasksDate = Date()
        }
    }
    
    /// Get the decoded category longest streaks dictionary
    func getCategoryLongestStreaks() -> [String: Int] {
        guard let data = categoryLongestStreaks.data(using: .utf8),
              let dict = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return [:]
        }
        return dict
    }
    
    /// Update a category's longest streak if the new value is higher
    func updateCategoryLongestStreak(category: TaskCategory, currentStreak: Int) {
        var streaks = getCategoryLongestStreaks()
        let key = category.rawValue
        if currentStreak > (streaks[key] ?? 0) {
            streaks[key] = currentStreak
            if let data = try? JSONEncoder().encode(streaks),
               let json = String(data: data, encoding: .utf8) {
                categoryLongestStreaks = json
            }
        }
    }
    
    /// Longest streak for a specific category
    func longestStreak(for category: TaskCategory) -> Int {
        getCategoryLongestStreaks()[category.rawValue] ?? 0
    }
    
    // MARK: - Streak Freeze Helpers
    
    /// Consume one streak freeze charge to prevent streak loss
    /// Returns true if a charge was available and consumed
    @discardableResult
    func useStreakFreeze() -> Bool {
        guard streakFreezeCharges > 0 else { return false }
        streakFreezeCharges -= 1
        return true
    }
    
    // MARK: - Class Task Affinity
    
    /// The task category this character's class has affinity with (for bonus EXP)
    var classAffinityCategory: [TaskCategory] {
        guard let charClass = characterClass else { return [] }
        switch charClass {
        case .warrior, .berserker, .paladin:
            return [.physical]
        case .mage, .sorcerer, .enchanter:
            return [.mental]
        case .archer, .ranger, .trickster:
            return [.creative, .social]
        }
    }
    
    /// Whether a task category matches this character's class affinity
    func hasClassAffinity(for category: TaskCategory) -> Bool {
        classAffinityCategory.contains(category)
    }
    
    /// Class affinity EXP bonus multiplier (+15% for single-affinity, +10% for dual-affinity classes)
    func classAffinityBonus(for category: TaskCategory) -> Double {
        guard hasClassAffinity(for: category) else { return 0.0 }
        // Archer line has 2 affinities → +10% each; Warrior/Mage lines have 1 → +15%
        return classAffinityCategory.count > 1 ? 0.10 : 0.15
    }
    
    /// Class-flavored completion message
    var classCompletionMessage: String? {
        guard let charClass = characterClass else { return nil }
        switch charClass {
        case .warrior: return "The Warrior's discipline pays off."
        case .berserker: return "The Berserker's fury drives you forward."
        case .paladin: return "The Paladin's resolve stands strong."
        case .mage: return "The Mage's focus sharpens."
        case .sorcerer: return "The Sorcerer's mastery deepens."
        case .enchanter: return "The Enchanter's magic weaves true."
        case .archer: return "The Archer's keen eye strikes true."
        case .ranger: return "The Ranger's instinct guides the way."
        case .trickster: return "Fortune smiles upon the Trickster."
        }
    }
    
    // MARK: - Pity Counter Helpers
    
    /// Pity thresholds per content type (from GAME_DESIGN.md §8)
    static let pityThresholds: [String: Int] = [
        "tasks": 20,
        "dungeons": 12,
        "missions": 5,
        "expeditions": 3
    ]
    
    /// Minimum rarity guaranteed by pity (from GAME_DESIGN.md §8)
    static let pityMinRarity: [String: ItemRarity] = [
        "tasks": .uncommon,
        "dungeons": .rare,
        "missions": .rare,
        "expeditions": .epic
    ]
    
    /// Get decoded pity counters dictionary
    func getPityCounters() -> [String: Int] {
        guard let data = pityCountersJSON.data(using: .utf8),
              let dict = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return [:]
        }
        return dict
    }
    
    /// Set pity counters from a dictionary
    func setPityCounters(_ counters: [String: Int]) {
        if let data = try? JSONEncoder().encode(counters),
           let json = String(data: data, encoding: .utf8) {
            pityCountersJSON = json
        }
    }
    
    /// Get the pity counter for a specific content type
    func pityCounter(for contentType: String) -> Int {
        getPityCounters()[contentType] ?? 0
    }
    
    /// Increment the pity counter for a content type (called on dry runs)
    func incrementPityCounter(for contentType: String) {
        var counters = getPityCounters()
        counters[contentType, default: 0] += 1
        setPityCounters(counters)
    }
    
    /// Reset the pity counter for a content type (called when equipment drops)
    func resetPityCounter(for contentType: String) {
        var counters = getPityCounters()
        counters[contentType] = 0
        setPityCounters(counters)
    }
    
    /// Check if pity threshold is reached for a content type
    func isPityTriggered(for contentType: String) -> Bool {
        guard let threshold = Self.pityThresholds[contentType] else { return false }
        return pityCounter(for: contentType) >= threshold
    }
    
    // MARK: - Arena Helpers
    
    /// Check and reset daily arena attempts
    func checkArenaReset() {
        if let lastDate = lastArenaDate, !Calendar.current.isDateInToday(lastDate) {
            arenaAttemptsToday = 0
        }
    }
    
    /// Whether the player gets a free arena run today
    var hasFreeArenaAttempt: Bool {
        checkArenaReset()
        return arenaAttemptsToday == 0
    }
    
    // MARK: - Partner Helpers
    
    /// Partner's character class (resolved from cached string)
    var partnerClass: CharacterClass? {
        guard let className = partnerClassName else { return nil }
        return CharacterClass(rawValue: className)
    }
    
    /// Whether this character has a partner linked (or is in a party)
    var hasPartner: Bool {
        partnerCharacterID != nil || !partyMembers.isEmpty
    }
    
    /// Whether this character is in a party (1+ allies)
    var isInParty: Bool {
        !partyMembers.isEmpty
    }
    
    /// Number of party members (excluding self)
    var partyMemberCount: Int {
        partyMembers.count
    }
    
    /// Link with a partner using pairing data (also adds to party members)
    func linkPartner(data: PairingData) {
        guard let partnerUUID = UUID(uuidString: data.characterID) else { return }
        partnerCharacterID = partnerUUID
        partnerName = data.name
        partnerLevel = data.level
        partnerClassName = data.characterClass
        
        // Also add to party members cache
        addPartyMember(CachedPartyMember(
            id: partnerUUID,
            name: data.name,
            level: data.level,
            className: data.characterClass,
            statTotal: nil,
            avatarName: data.avatarName
        ))
        
        // Store Supabase party ID if provided
        if let partyIDStr = data.partyID, let pid = UUID(uuidString: partyIDStr) {
            partyID = pid
        }
    }
    
    /// Unlink partner
    func unlinkPartner() {
        partnerCharacterID = nil
        partnerName = nil
        partnerLevel = nil
        partnerClassName = nil
        partnerStatTotal = nil
    }
    
    /// Leave the party entirely
    func leaveParty() {
        unlinkPartner()
        partyMembersJSON = "[]"
        partyID = nil
    }
    
    // MARK: - Party Member Cache
    
    /// Decoded party members from JSON cache
    var partyMembers: [CachedPartyMember] {
        guard let data = partyMembersJSON.data(using: .utf8),
              let members = try? JSONDecoder().decode([CachedPartyMember].self, from: data) else {
            return []
        }
        return members
    }
    
    /// Update the entire party members cache
    func setPartyMembers(_ members: [CachedPartyMember]) {
        if let data = try? JSONEncoder().encode(members),
           let json = String(data: data, encoding: .utf8) {
            partyMembersJSON = json
        }
    }
    
    /// Add a party member to the cache (max 3 allies = 4 total including self)
    func addPartyMember(_ member: CachedPartyMember) {
        var members = partyMembers
        // Don't add duplicates
        guard !members.contains(where: { $0.id == member.id }) else { return }
        guard members.count < 3 else { return }
        members.append(member)
        setPartyMembers(members)
    }
    
    /// Remove a party member from the cache
    func removePartyMember(_ memberID: UUID) {
        var members = partyMembers
        members.removeAll { $0.id == memberID }
        setPartyMembers(members)
        
        // If the removed member was the legacy partner, clear partner fields too
        if partnerCharacterID == memberID {
            unlinkPartner()
        }
    }
    
    /// All member IDs in the party (including self)
    var allPartyMemberIDs: [UUID] {
        [id] + partyMembers.map(\.id)
    }
    
    /// Reset daily counter if needed
    func checkDailyReset() {
        let calendar = Calendar.current
        if !calendar.isDateInToday(lastDailyReset) {
            tasksCompletedToday = 0
            lastDailyReset = Date()
        }
    }
    
    // MARK: - Onboarding & Retention Helpers
    
    /// Days since last activity (for absence detection)
    var daysSinceLastActive: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: lastActiveAt), to: calendar.startOfDay(for: Date())).day ?? 0
    }
    
    /// Whether the player qualifies for a welcome-back gift (3+ days absent)
    var shouldShowWelcomeBack: Bool {
        daysSinceLastActive >= 3 && !comebackGiftClaimed
    }
    
    /// Whether the player can claim today's daily login reward
    var canClaimDailyLoginReward: Bool {
        guard let lastClaim = lastLoginRewardDate else { return true }
        return !Calendar.current.isDateInToday(lastClaim)
    }
    
    /// Whether the onboarding breadcrumb quest log should show (first 7 days, not all done)
    var shouldShowBreadcrumbs: Bool {
        guard hasCompletedOnboarding else { return false }
        let daysSinceCreation = Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
        guard daysSinceCreation < 7 else { return false }
        // Show if there are breadcrumbs that haven't been completed
        let allCompleted = onboardingBreadcrumbs.values.allSatisfy { $0 }
        return !allCompleted || onboardingBreadcrumbs.isEmpty
    }
    
    /// Claim the daily login reward and advance the cycle
    func claimDailyLoginReward() {
        lastLoginRewardDate = Date()
        if loginStreakDay >= 7 {
            loginStreakDay = 1
        } else {
            loginStreakDay += 1
        }
    }
    
    /// Mark a breadcrumb as completed
    func completeBreadcrumb(_ breadcrumbID: String) {
        onboardingBreadcrumbs[breadcrumbID] = true
    }
    
    /// Reset comeback state when the player returns (after gifts are claimed)
    func markComebackGiftClaimed() {
        comebackGiftClaimed = true
        reengagementNotificationsSent = 0
    }
    
    /// Reset comeback tracking when the player becomes active again
    func resetComebackTracking() {
        comebackGiftClaimed = false
        reengagementNotificationsSent = 0
    }
    
    // MARK: - Computed Properties
    
    /// EXP required to reach next level
    var expToNextLevel: Int {
        GameEngine.expRequired(forLevel: level + 1)
    }
    
    /// Progress to next level (0.0 - 1.0, capped so the bar never overflows)
    var levelProgress: Double {
        let currentLevelExp = GameEngine.expRequired(forLevel: level)
        let nextLevelExp = GameEngine.expRequired(forLevel: level + 1)
        let expIntoLevel = currentEXP - currentLevelExp
        let expNeeded = nextLevelExp - currentLevelExp
        guard expNeeded > 0 else { return 1.0 }
        return min(1.0, Double(expIntoLevel) / Double(expNeeded))
    }
    
    /// Total stats including equipment bonuses and class passive
    var effectiveStats: Stats {
        let effective = Stats(
            strength: stats.strength,
            wisdom: stats.wisdom,
            charisma: stats.charisma,
            dexterity: stats.dexterity,
            luck: stats.luck,
            defense: stats.defense
        )
        
        // Add equipment bonuses (primary + enhancement + secondary) — all 4 slots
        let equippedItems = [equipment.weapon, equipment.armor, equipment.accessory, equipment.trinket].compactMap { $0 }
        for item in equippedItems {
            effective.increase(item.primaryStat, by: item.effectivePrimaryBonus)
            if let secondary = item.secondaryStat {
                effective.increase(secondary, by: item.secondaryStatBonus)
            }
        }
        
        // Class passive: +2 to primary stat
        if let charClass = characterClass {
            effective.increase(charClass.primaryStat, by: 2)
        }
        
        // Zodiac bonus: +2 to zodiac stat
        if let zodiac = zodiacSign {
            effective.increase(zodiac.boostedStat, by: 2)
        }
        
        // Gear set bonus: check if all equipped items complete a set
        let equippedCatalogIDs = Set(equippedItems.compactMap { $0.catalogID })
        if let setBonus = GearSetCatalog.activeSetBonus(equippedCatalogIDs: equippedCatalogIDs) {
            effective.increase(setBonus.stat, by: setBonus.amount)
        }
        
        // Rebirth permanent all-stats bonus (multiplicative on total)
        let allStatsBonus = rebirthAllStatsBonus
        if allStatsBonus > 0 {
            let bonus = { (val: Int) -> Int in Int(Double(val) * allStatsBonus) }
            effective.increase(.strength, by: bonus(effective.strength))
            effective.increase(.wisdom, by: bonus(effective.wisdom))
            effective.increase(.charisma, by: bonus(effective.charisma))
            effective.increase(.dexterity, by: bonus(effective.dexterity))
            effective.increase(.luck, by: bonus(effective.luck))
            effective.increase(.defense, by: bonus(effective.defense))
        }
        
        return effective
    }
    
    // MARK: - HP Calculations
    
    /// Maximum HP based on class, level, and effective Defense stat (uncapped).
    /// Formula: classBaseHP + (level * classHPPerLevel) + (effectiveDefense * 5)
    var maxHP: Int {
        let classHP = characterClass?.baseHP ?? 100
        let hpPerLvl = characterClass?.hpPerLevel ?? 5
        let defenseHP = effectiveStats.defense * 5
        return classHP + (level * hpPerLvl) + defenseHP
    }
    
    /// HP as a percentage (0.0 – 1.0)
    var hpPercentage: Double {
        guard maxHP > 0 else { return 0 }
        return Double(max(0, currentHP)) / Double(maxHP)
    }
    
    /// Whether the regen buff is currently active
    var hasActiveRegenBuff: Bool {
        guard let expiry = regenBuffExpiresAt else { return false }
        return Date() < expiry
    }
    
    /// Current passive HP regen rate per hour (base 50, boosted when buff active)
    var regenRatePerHour: Int {
        hasActiveRegenBuff ? 100 : 50
    }
    
    /// Apply passive HP regeneration based on elapsed time since last update.
    /// Call this on app launch, screen transitions, and before HP checks.
    func applyPassiveRegen() {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastHPUpdateAt)
        guard elapsed > 0 else { return }
        
        let hours = elapsed / 3600.0
        let regenAmount = Int(hours * Double(regenRatePerHour))
        
        if regenAmount > 0 {
            let cap = maxHP
            currentHP = min(cap, currentHP + regenAmount)
            lastHPUpdateAt = now
        }
    }
    
    /// Ensure currentHP doesn't exceed maxHP (call after level-up or stat changes)
    func clampHP() {
        let cap = maxHP
        if currentHP > cap {
            currentHP = cap
        }
    }
    
    /// Initialize HP to maxHP (call on character creation after class is set)
    func initializeHP() {
        currentHP = maxHP
        lastHPUpdateAt = Date()
    }
    
    /// Heal by a fixed amount (e.g. from a potion), capped at maxHP
    func heal(amount: Int) {
        currentHP = min(maxHP, currentHP + amount)
    }
    
    /// Take damage, flooring at 0. Returns actual damage dealt.
    @discardableResult
    func takeDamage(_ amount: Int) -> Int {
        let actual = min(currentHP, max(0, amount))
        currentHP -= actual
        // Auto-revive: if knocked to 0, revive to 1
        if currentHP <= 0 {
            currentHP = 1
        }
        return actual
    }
    
    /// Formatted HP string for UI (e.g. "420 / 695")
    var hpDisplay: String {
        "\(currentHP) / \(maxHP)"
    }
    
    // MARK: - Stat Breakdown
    
    /// Breakdown of where a stat's bonuses come from
    func statBreakdown(for statType: StatType) -> StatBreakdown {
        let base = stats.value(for: statType)
        
        func itemBonus(_ item: Equipment?) -> Int {
            guard let item = item else { return 0 }
            var total = 0
            if item.primaryStat == statType { total += item.statBonus }
            if item.secondaryStat == statType { total += item.secondaryStatBonus }
            return total
        }
        
        let weaponBonus = itemBonus(equipment.weapon)
        let armorBonus = itemBonus(equipment.armor)
        let accessoryBonus = itemBonus(equipment.accessory)
        let trinketBonus = itemBonus(equipment.trinket)
        
        let classBonus: Int = (characterClass?.primaryStat == statType) ? 2 : 0
        let zodiacBonus: Int = (zodiacSign?.boostedStat == statType) ? 2 : 0
        
        return StatBreakdown(
            base: base,
            weaponBonus: weaponBonus,
            weaponName: equipment.weapon?.name,
            armorBonus: armorBonus,
            armorName: equipment.armor?.name,
            accessoryBonus: accessoryBonus,
            accessoryName: equipment.accessory?.name,
            trinketBonus: trinketBonus,
            trinketName: equipment.trinket?.name,
            classBonus: classBonus,
            className: characterClass?.rawValue,
            zodiacBonus: zodiacBonus,
            zodiacName: zodiacSign?.rawValue
        )
    }
    
    /// Aggregate hero power score (all 4 equipment slots + affixes)
    var heroPower: Int {
        let statPower = effectiveStats.total * 10
        let levelPower = level * 5
        
        let equipmentItems = [equipment.weapon, equipment.armor, equipment.accessory, equipment.trinket].compactMap { $0 }
        let equipPower = equipmentItems.reduce(0) { $0 + $1.totalStatBonus } * 8
        
        // Affix power: each affix adds a small bonus to hero power
        let affixPower = equipmentItems.reduce(0) { total, item in
            var bonus = 0
            if item.prefix != nil { bonus += item.prefix!.isGreater ? 15 : 10 }
            if item.suffix != nil { bonus += item.suffix!.isGreater ? 15 : 10 }
            return total + bonus
        }
        
        let achievementPower = achievements.filter { $0.isUnlocked }.count * 20
        
        // Card collection power bonus (cached, updated on card collection)
        let cardPower = cachedCardPowerBonus
        
        // Research tree power bonus (cached, updated on research completion)
        let researchPower = cachedResearchPowerBonus
        
        return statPower + levelPower + equipPower + affixPower + achievementPower + cardPower + researchPower
    }
    
    /// Title based on level (rebirth title takes priority if available)
    var title: String {
        if let rTitle = rebirthTitle {
            return rTitle
        }
        switch level {
        case 1...9: return "Novice"
        case 10...19: return "Apprentice"
        case 20...29: return "Journeyman"
        case 30...39: return "Adept"
        case 40...49: return "Expert"
        case 50...59: return "Master"
        case 60...69: return "Grandmaster"
        case 70...79: return "Legend"
        case 80...89: return "Mythic"
        case 90...99: return "Immortal"
        case 100: return "Transcendent"
        default: return "Unknown"
        }
    }
    
    // MARK: - Methods
    
    /// Whether the character has enough EXP to level up (normal path, capped at 100)
    var canLevelUp: Bool {
        currentEXP >= expToNextLevel && level < 100
    }
    
    /// Whether the character can gain a Paragon level (at level 100+, EXP-based)
    var canParagonLevelUp: Bool {
        guard level >= 100 else { return false }
        return currentEXP >= paragonEXPRequired
    }
    
    /// EXP required for the next Paragon level
    /// Scales linearly: base 5000 + 500 per paragon level
    var paragonEXPRequired: Int {
        let base = GameEngine.expRequired(forLevel: 100)
        return base + 5000 + (paragonLevel * 500)
    }
    
    /// Add EXP (does NOT auto-level — use performLevelUp() to level up manually)
    @discardableResult
    func gainEXP(_ amount: Int) -> [LevelUpReward] {
        // Apply rebirth EXP bonus + card collection EXP bonus
        let bonusMultiplier = 1.0 + rebirthEXPBonus + cachedCardExpBonus
        let adjustedAmount = Int(Double(amount) * bonusMultiplier)
        currentEXP += adjustedAmount
        lastActiveAt = Date()
        return []
    }
    
    /// Add Gold with rebirth bonus + card collection bonus applied
    func gainGold(_ amount: Int) {
        let bonusMultiplier = 1.0 + rebirthGoldBonus + cachedCardGoldBonus
        let adjustedAmount = Int(Double(amount) * bonusMultiplier)
        gold += adjustedAmount
    }
    
    /// Perform a single level-up (call from UI when the player taps Level Up)
    func performLevelUp() -> [LevelUpReward] {
        guard canLevelUp else { return [] }
        level += 1
        let rewards = processLevelUp()
        
        // Sync to cloud after leveling up
        Task {
            do {
                try await SupabaseService.shared.syncCharacterData(self)
                print("✅ Level up synced: Lv.\(self.level)")
            } catch {
                print("❌ Failed to sync level up: \(error)")
            }
        }
        
        return rewards
    }
    
    /// Process rewards for leveling up
    private func processLevelUp() -> [LevelUpReward] {
        var rewards: [LevelUpReward] = []
        
        // Stat point every level
        unspentStatPoints += 1
        rewards.append(.statPoint)
        
        // Gold bonus
        let goldReward = level * 15
        gold += goldReward
        rewards.append(.gold(goldReward))
        
        // Class evolution at level 20
        if level == 20 {
            rewards.append(.classEvolution)
        }
        
        return rewards
    }
    
    // MARK: - Cloud Snapshot
    
    /// Create a serializable snapshot of this character for cloud storage.
    /// Comprehensive — includes ALL fields, daily counters, dates, and trackers.
    func toSnapshot() -> CharacterSnapshot {
        CharacterSnapshot(
            id: id,
            name: name,
            level: level,
            currentEXP: currentEXP,
            characterClass: characterClass?.rawValue,
            zodiacSign: zodiacSign?.rawValue,
            strength: stats.strength,
            wisdom: stats.wisdom,
            charisma: stats.charisma,
            dexterity: stats.dexterity,
            luck: stats.luck,
            defense: stats.defense,
            gold: gold,
            gems: gems,
            forgeShards: forgeShards,
            tasksCompleted: tasksCompleted,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            unspentStatPoints: unspentStatPoints,
            avatarIcon: avatarIcon,
            avatarFrame: avatarFrame,
            moodStreak: moodStreak,
            meditationStreak: meditationStreak,
            arenaBestWave: arenaBestWave,
            createdAt: createdAt,
            // Extended fields — previously local-only
            tasksCompletedToday: tasksCompletedToday,
            dutiesCompletedToday: dutiesCompletedToday,
            arenaAttemptsToday: arenaAttemptsToday,
            lastDailyReset: lastDailyReset,
            lastActiveAt: lastActiveAt,
            lastMeditationDate: lastMeditationDate,
            lastMoodDate: lastMoodDate,
            lastArenaDate: lastArenaDate,
            lastSyncTimestamp: Date(),
            hasCompletedOnboarding: hasCompletedOnboarding,
            loginStreakDay: loginStreakDay,
            lastLoginRewardDate: lastLoginRewardDate,
            comebackGiftClaimed: comebackGiftClaimed,
            reengagementNotificationsSent: reengagementNotificationsSent,
            // Category mastery
            masteryPhysicalCount: masteryPhysicalCount,
            masteryMentalCount: masteryMentalCount,
            masterySocialCount: masterySocialCount,
            masteryHouseholdCount: masteryHouseholdCount,
            masteryWellnessCount: masteryWellnessCount,
            masteryCreativeCount: masteryCreativeCount,
            // Personal records
            recordMostTasksInDay: recordMostTasksInDay,
            categoryLongestStreaks: categoryLongestStreaks,
            // Meditation buff
            wisdomBuffExpiresAt: wisdomBuffExpiresAt,
            // Streak freeze
            streakFreezeCharges: streakFreezeCharges,
            // Pity counters
            pityCountersJSON: pityCountersJSON,
            // Prestige
            paragonLevel: paragonLevel,
            rebirthCount: rebirthCount,
            permanentBonusesJSON: permanentBonusesJSON,
            // Persistent HP
            currentHP: currentHP,
            lastHPUpdateAt: lastHPUpdateAt,
            regenBuffExpiresAt: regenBuffExpiresAt
        )
    }
    
    /// Restore a PlayerCharacter from a cloud snapshot.
    static func fromSnapshot(_ s: CharacterSnapshot) -> PlayerCharacter {
        let restoredStats = Stats(
            strength: s.strength,
            wisdom: s.wisdom,
            charisma: s.charisma,
            dexterity: s.dexterity,
            luck: s.luck,
            defense: s.defense
        )
        let character = PlayerCharacter(name: s.name, stats: restoredStats)
        character.id = s.id
        character.level = s.level
        character.currentEXP = s.currentEXP
        if let cls = s.characterClass { character.characterClass = CharacterClass(rawValue: cls) }
        if let zodiac = s.zodiacSign { character.zodiacSign = ZodiacSign(rawValue: zodiac) }
        character.gold = s.gold
        character.gems = s.gems
        character.forgeShards = s.forgeShards
        character.tasksCompleted = s.tasksCompleted
        character.currentStreak = s.currentStreak
        character.longestStreak = s.longestStreak
        character.unspentStatPoints = s.unspentStatPoints
        character.avatarIcon = s.avatarIcon
        character.avatarFrame = s.avatarFrame
        character.moodStreak = s.moodStreak
        character.meditationStreak = s.meditationStreak
        character.arenaBestWave = s.arenaBestWave
        character.createdAt = s.createdAt
        // Restore extended fields
        if let tasksToday = s.tasksCompletedToday { character.tasksCompletedToday = tasksToday }
        if let dutiesToday = s.dutiesCompletedToday { character.dutiesCompletedToday = dutiesToday }
        if let arenaAttempts = s.arenaAttemptsToday { character.arenaAttemptsToday = arenaAttempts }
        if let lastReset = s.lastDailyReset { character.lastDailyReset = lastReset }
        if let lastActive = s.lastActiveAt { character.lastActiveAt = lastActive }
        character.lastMeditationDate = s.lastMeditationDate
        character.lastMoodDate = s.lastMoodDate
        character.lastArenaDate = s.lastArenaDate
        character.lastSyncTimestamp = s.lastSyncTimestamp
        // Onboarding & Retention
        if let onboarded = s.hasCompletedOnboarding { character.hasCompletedOnboarding = onboarded }
        if let loginDay = s.loginStreakDay { character.loginStreakDay = loginDay }
        character.lastLoginRewardDate = s.lastLoginRewardDate
        if let comebackClaimed = s.comebackGiftClaimed { character.comebackGiftClaimed = comebackClaimed }
        if let reengageCount = s.reengagementNotificationsSent { character.reengagementNotificationsSent = reengageCount }
        // Category mastery
        if let v = s.masteryPhysicalCount { character.masteryPhysicalCount = v }
        if let v = s.masteryMentalCount { character.masteryMentalCount = v }
        if let v = s.masterySocialCount { character.masterySocialCount = v }
        if let v = s.masteryHouseholdCount { character.masteryHouseholdCount = v }
        if let v = s.masteryWellnessCount { character.masteryWellnessCount = v }
        if let v = s.masteryCreativeCount { character.masteryCreativeCount = v }
        // Personal records
        if let v = s.recordMostTasksInDay { character.recordMostTasksInDay = v }
        if let v = s.categoryLongestStreaks { character.categoryLongestStreaks = v }
        // Meditation buff
        character.wisdomBuffExpiresAt = s.wisdomBuffExpiresAt
        // Streak freeze
        if let v = s.streakFreezeCharges { character.streakFreezeCharges = v }
        // Pity counters
        if let v = s.pityCountersJSON { character.pityCountersJSON = v }
        // Prestige
        if let v = s.paragonLevel { character.paragonLevel = v }
        if let v = s.rebirthCount { character.rebirthCount = v }
        if let v = s.permanentBonusesJSON { character.permanentBonusesJSON = v }
        // Persistent HP
        if let v = s.currentHP { character.currentHP = v }
        if let v = s.lastHPUpdateAt { character.lastHPUpdateAt = v }
        character.regenBuffExpiresAt = s.regenBuffExpiresAt
        return character
    }
}

// MARK: - Character Snapshot (Cloud Sync)

/// Comprehensive, Codable representation of a PlayerCharacter for cloud storage.
/// Stored as JSONB in the Supabase `profiles.character_data` column.
/// Includes ALL fields — daily counters, dates, attempt trackers — so no data is lost on reinstall.
struct CharacterSnapshot: Codable {
    // Core identity
    let id: UUID
    let name: String
    let level: Int
    let currentEXP: Int
    let characterClass: String?
    let zodiacSign: String?
    
    // Stats
    let strength: Int
    let wisdom: Int
    let charisma: Int
    let dexterity: Int
    let luck: Int
    let defense: Int
    
    // Currency
    let gold: Int
    let gems: Int
    let forgeShards: Int
    
    // Progression
    let tasksCompleted: Int
    let currentStreak: Int
    let longestStreak: Int
    let unspentStatPoints: Int
    
    // Avatar
    let avatarIcon: String
    let avatarFrame: String
    
    // Streaks
    let moodStreak: Int
    let meditationStreak: Int
    
    // Arena
    let arenaBestWave: Int
    
    // Dates
    let createdAt: Date
    
    // Extended fields (previously local-only, now synced)
    let tasksCompletedToday: Int?
    let dutiesCompletedToday: Int?
    let arenaAttemptsToday: Int?
    let lastDailyReset: Date?
    let lastActiveAt: Date?
    let lastMeditationDate: Date?
    let lastMoodDate: Date?
    let lastArenaDate: Date?
    let lastSyncTimestamp: Date?
    
    // Onboarding & Retention
    let hasCompletedOnboarding: Bool?
    let loginStreakDay: Int?
    let lastLoginRewardDate: Date?
    let comebackGiftClaimed: Bool?
    let reengagementNotificationsSent: Int?
    
    // Category Mastery
    let masteryPhysicalCount: Int?
    let masteryMentalCount: Int?
    let masterySocialCount: Int?
    let masteryHouseholdCount: Int?
    let masteryWellnessCount: Int?
    let masteryCreativeCount: Int?
    
    // Personal Records
    let recordMostTasksInDay: Int?
    let categoryLongestStreaks: String?
    
    // Meditation Buff
    let wisdomBuffExpiresAt: Date?
    
    // Streak Freeze
    let streakFreezeCharges: Int?
    
    // Pity Counters
    let pityCountersJSON: String?
    
    // Prestige / End-Game
    let paragonLevel: Int?
    let rebirthCount: Int?
    let permanentBonusesJSON: String?
    
    // Persistent HP
    let currentHP: Int?
    let lastHPUpdateAt: Date?
    let regenBuffExpiresAt: Date?
}

// MARK: - Supporting Types

/// Class tier: starter (chosen at creation) or advanced (unlocked via evolution)
enum ClassTier: String, Codable {
    case starter
    case advanced
}

/// Character classes -- 3 starters chosen at creation, 6 advanced unlocked through evolution
/// Groups classes into their starter lineage for narrative and gameplay purposes
enum ClassLine: String, Codable {
    case warrior  // Warrior, Berserker, Paladin
    case mage     // Mage, Sorcerer, Enchanter
    case archer   // Archer, Ranger, Trickster
}

enum CharacterClass: String, Codable, CaseIterable {
    // Starters
    case warrior = "Warrior"
    case mage = "Mage"
    case archer = "Archer"
    // Advanced (evolve from starters)
    case berserker = "Berserker"
    case paladin = "Paladin"
    case sorcerer = "Sorcerer"
    case enchanter = "Enchanter"
    case ranger = "Ranger"
    case trickster = "Trickster"
    
    /// The class line this class belongs to (warrior, mage, or archer family)
    var classLine: ClassLine {
        switch self {
        case .warrior, .berserker, .paladin: return .warrior
        case .mage, .sorcerer, .enchanter:  return .mage
        case .archer, .ranger, .trickster:  return .archer
        }
    }
    
    /// Only the 3 starter classes for character creation
    static var starters: [CharacterClass] {
        [.warrior, .mage, .archer]
    }
    
    /// Only the 6 advanced classes
    static var advanced: [CharacterClass] {
        [.berserker, .paladin, .sorcerer, .enchanter, .ranger, .trickster]
    }
    
    var tier: ClassTier {
        switch self {
        case .warrior, .mage, .archer: return .starter
        default: return .advanced
        }
    }
    
    /// Which starter class this advanced class evolves from (nil for starters)
    var evolvesFrom: CharacterClass? {
        switch self {
        case .berserker, .paladin: return .warrior
        case .sorcerer, .enchanter: return .mage
        case .ranger, .trickster: return .archer
        default: return nil
        }
    }
    
    /// The two advanced classes a starter can evolve into
    var evolutionOptions: [CharacterClass] {
        switch self {
        case .warrior: return [.berserker, .paladin]
        case .mage: return [.sorcerer, .enchanter]
        case .archer: return [.ranger, .trickster]
        default: return []
        }
    }
    
    /// Stat required to meet evolution threshold
    var evolutionStat: StatType? {
        switch self {
        case .berserker: return .strength
        case .paladin: return .defense
        case .sorcerer: return .wisdom
        case .enchanter: return .charisma
        case .ranger: return .dexterity
        case .trickster: return .luck
        default: return nil
        }
    }
    
    /// Minimum stat value required for evolution
    var evolutionStatThreshold: Int { 15 }
    
    /// Minimum level required for evolution
    var evolutionLevelRequirement: Int { 20 }
    
    var description: String {
        switch self {
        // Starters
        case .warrior: return "A mighty frontline fighter. High strength and dexterity make them formidable in combat encounters."
        case .mage: return "A wielder of arcane knowledge. High wisdom and luck fuel devastating spells and critical strikes."
        case .archer: return "A swift and precise marksman. High dexterity and luck grant speed and deadly accuracy."
        // Advanced
        case .berserker: return "Unbridled fury incarnate. +40% power on Combat encounters."
        case .paladin: return "An unbreakable shield. Party takes 50% less damage in dungeons."
        case .sorcerer: return "Master of the arcane arts. +40% power on Puzzle encounters."
        case .enchanter: return "Weaver of support magic. +20% power to all party members."
        case .ranger: return "One with the wild. +15% Mission Duration Reduction and trap mastery."
        case .trickster: return "Fortune's favorite. +25% bonus loot from dungeons."
        }
    }
    
    var primaryStat: StatType {
        switch self {
        case .warrior, .berserker: return .strength
        case .mage, .sorcerer: return .wisdom
        case .archer, .ranger: return .dexterity
        case .paladin: return .defense
        case .enchanter: return .charisma
        case .trickster: return .luck
        }
    }
    
    var icon: String {
        switch self {
        case .warrior: return "shield.lefthalf.filled"
        case .mage: return "wand.and.stars"
        case .archer: return "arrow.up.right.circle.fill"
        case .berserker: return "bolt.circle.fill"
        case .paladin: return "shield.checkered"
        case .sorcerer: return "sparkles"
        case .enchanter: return "moon.stars.fill"
        case .ranger: return "leaf.fill"
        case .trickster: return "theatermasks.fill"
        }
    }
    
    /// Base stat spread for starter classes (total 35 points)
    var baseStats: Stats {
        switch self {
        case .warrior: return Stats(strength: 8, wisdom: 3, charisma: 3, dexterity: 10, luck: 4, defense: 7)
        case .mage:    return Stats(strength: 3, wisdom: 8, charisma: 5, dexterity: 7, luck: 7, defense: 5)
        case .archer:  return Stats(strength: 4, wisdom: 4, charisma: 3, dexterity: 12, luck: 7, defense: 5)
        default:       return Stats() // Advanced classes inherit from starter
        }
    }
    
    // MARK: - Dungeon Abilities
    
    var abilityName: String {
        switch self {
        case .warrior: return "Battle Fury"
        case .mage: return "Arcane Bolt"
        case .archer: return "Precision Shot"
        case .berserker: return "Rampage"
        case .paladin: return "Divine Shield"
        case .sorcerer: return "Arcane Mastery"
        case .enchanter: return "Rally Cry"
        case .ranger: return "Pathfinder"
        case .trickster: return "Fortune's Favor"
        }
    }
    
    var abilityDescription: String {
        switch self {
        case .warrior: return "+25% power on Combat encounters"
        case .mage: return "+25% power on Puzzle encounters"
        case .archer: return "+20% power on Trap encounters"
        case .berserker: return "+40% power on Combat encounters"
        case .paladin: return "Party takes 50% less damage from failed rooms"
        case .sorcerer: return "+40% power on Puzzle encounters"
        case .enchanter: return "+20% power to all party members"
        case .ranger: return "+30% power on Trap encounters, -15% mission duration"
        case .trickster: return "+25% loot drop chance in dungeons"
        }
    }
    
    var bonusEncounterType: EncounterType? {
        switch self {
        case .warrior, .berserker: return .combat
        case .mage, .sorcerer: return .puzzle
        case .archer, .ranger: return .trap
        default: return nil
        }
    }
    
    var encounterPowerMultiplier: Double {
        switch self {
        case .warrior: return 0.25
        case .mage: return 0.25
        case .archer: return 0.20
        case .berserker: return 0.40
        case .sorcerer: return 0.40
        case .ranger: return 0.30
        default: return 0.0
        }
    }
    
    var partyPowerMultiplier: Double {
        switch self {
        case .enchanter: return 0.20
        default: return 0.0
        }
    }
    
    var damageReductionMultiplier: Double {
        switch self {
        case .paladin: return 0.50
        default: return 0.0
        }
    }
    
    var lootDropBonus: Double {
        switch self {
        case .trickster: return 0.25
        default: return 0.0
        }
    }
    
    // MARK: - HP Scaling
    
    /// Base HP at level 0 before any level or Defense scaling.
    /// Warrior line is tankiest, Mage line is squishiest.
    var baseHP: Int {
        switch self {
        case .warrior: return 120
        case .berserker: return 130
        case .paladin: return 140
        case .archer: return 100
        case .ranger: return 105
        case .trickster: return 95
        case .mage: return 80
        case .sorcerer: return 75
        case .enchanter: return 90
        }
    }
    
    /// HP gained per character level.
    /// Higher values mean tankier scaling into late game.
    var hpPerLevel: Int {
        switch self {
        case .warrior: return 8
        case .berserker: return 9
        case .paladin: return 10
        case .archer: return 5
        case .ranger: return 6
        case .trickster: return 4
        case .mage: return 3
        case .sorcerer: return 2
        case .enchanter: return 4
        }
    }
}

// MARK: - Zodiac Sign

/// Zodiac signs that grant +2 to a specific stat
enum ZodiacSign: String, Codable, CaseIterable {
    case aries = "Aries"
    case taurus = "Taurus"
    case gemini = "Gemini"
    case cancer = "Cancer"
    case leo = "Leo"
    case virgo = "Virgo"
    case libra = "Libra"
    case scorpio = "Scorpio"
    case sagittarius = "Sagittarius"
    case capricorn = "Capricorn"
    case aquarius = "Aquarius"
    case pisces = "Pisces"
    
    var icon: String {
        switch self {
        case .aries: return "flame"
        case .taurus: return "leaf.circle.fill"
        case .gemini: return "person.2.fill"
        case .cancer: return "moon.fill"
        case .leo: return "sun.max.fill"
        case .virgo: return "sparkle"
        case .libra: return "scale.3d"
        case .scorpio: return "bolt.fill"
        case .sagittarius: return "arrow.up.right"
        case .capricorn: return "mountain.2.fill"
        case .aquarius: return "drop.fill"
        case .pisces: return "water.waves"
        }
    }
    
    var dateRange: String {
        switch self {
        case .aries: return "Mar 21 - Apr 19"
        case .taurus: return "Apr 20 - May 20"
        case .gemini: return "May 21 - Jun 20"
        case .cancer: return "Jun 21 - Jul 22"
        case .leo: return "Jul 23 - Aug 22"
        case .virgo: return "Aug 23 - Sep 22"
        case .libra: return "Sep 23 - Oct 22"
        case .scorpio: return "Oct 23 - Nov 21"
        case .sagittarius: return "Nov 22 - Dec 21"
        case .capricorn: return "Dec 22 - Jan 19"
        case .aquarius: return "Jan 20 - Feb 18"
        case .pisces: return "Feb 19 - Mar 20"
        }
    }
    
    /// The stat this zodiac sign boosts by +2
    var boostedStat: StatType {
        switch self {
        case .aries, .leo: return .strength
        case .taurus: return .defense
        case .capricorn: return .dexterity
        case .gemini, .libra: return .charisma
        case .cancer, .scorpio, .aquarius: return .wisdom
        case .virgo: return .dexterity
        case .sagittarius, .pisces: return .luck
        }
    }
    
    var element: String {
        switch self {
        case .aries, .leo, .sagittarius: return "Fire"
        case .taurus, .virgo, .capricorn: return "Earth"
        case .gemini, .libra, .aquarius: return "Air"
        case .cancer, .scorpio, .pisces: return "Water"
        }
    }
}

/// Rewards given when leveling up
enum LevelUpReward: Equatable {
    case statPoint
    case gold(Int)
    case gems(Int)
    case equipment(String, ItemRarity)       // name, rarity (for display)
    case consumable(String)                  // consumable name
    case craftingMaterial(String, Int)        // display name, quantity
    case classEvolution
    case equipmentSlot
}

/// Detailed stat source breakdown for display
struct StatBreakdown {
    let base: Int
    let weaponBonus: Int
    let weaponName: String?
    let armorBonus: Int
    let armorName: String?
    let accessoryBonus: Int
    let accessoryName: String?
    let trinketBonus: Int
    let trinketName: String?
    let classBonus: Int
    let className: String?
    let zodiacBonus: Int
    let zodiacName: String?
    
    var total: Int {
        base + weaponBonus + armorBonus + accessoryBonus + trinketBonus + classBonus + zodiacBonus
    }
    
    var totalBonus: Int {
        total - base
    }
}

/// Equipment loadout container (4 slots: Weapon, Armor, Accessory, Trinket)
@Model
final class EquipmentLoadout {
    @Relationship(deleteRule: .nullify)
    var weapon: Equipment?
    
    @Relationship(deleteRule: .nullify)
    var armor: Equipment?
    
    @Relationship(deleteRule: .nullify)
    var accessory: Equipment?
    
    @Relationship(deleteRule: .nullify)
    var trinket: Equipment?
    
    init(weapon: Equipment? = nil, armor: Equipment? = nil, accessory: Equipment? = nil, trinket: Equipment? = nil) {
        self.weapon = weapon
        self.armor = armor
        self.accessory = accessory
        self.trinket = trinket
    }
    
    /// Get the equipped item for a given slot
    func item(for slot: EquipmentSlot) -> Equipment? {
        switch slot {
        case .weapon: return weapon
        case .armor: return armor
        case .accessory: return accessory
        case .trinket: return trinket
        }
    }
    
    /// Set the equipped item for a given slot
    func setItem(_ item: Equipment?, for slot: EquipmentSlot) {
        switch slot {
        case .weapon: weapon = item
        case .armor: armor = item
        case .accessory: accessory = item
        case .trinket: trinket = item
        }
    }
    
    /// All equipped items (non-nil)
    var allEquipped: [Equipment] {
        [weapon, armor, accessory, trinket].compactMap { $0 }
    }
}

// MARK: - Cached Party Member

/// Lightweight cached party member data stored as JSON in PlayerCharacter.partyMembersJSON.
/// Used for offline display and co-op dungeon proxy stats.
struct CachedPartyMember: Codable, Identifiable, Equatable {
    let id: UUID
    let name: String
    let level: Int
    let className: String?
    let statTotal: Int?
    /// SF Symbol name for the member's avatar (from their Supabase profile)
    let avatarName: String?
    
    var characterClass: CharacterClass? {
        guard let cls = className else { return nil }
        return CharacterClass(rawValue: cls)
    }
    
    var displayLevel: String {
        "Lv.\(level)"
    }
    
    /// The avatar icon to display — uses the member's chosen avatar or falls back to generic icon
    var displayAvatarIcon: String {
        if let avatar = avatarName, !avatar.isEmpty {
            return avatar
        }
        return "person.fill"
    }
}

