import Foundation
import SwiftData

/// A daily objective that resets each day — 3 generated per day
@Model
final class DailyQuest {
    /// Unique identifier
    var id: UUID
    
    /// Quest title displayed in the UI
    var title: String
    
    /// Short description of what to do
    var questDescription: String
    
    /// SF Symbol icon name
    var icon: String
    
    /// The type of objective
    var questType: DailyQuestType
    
    /// Optional parameter for the quest type (e.g. category name, difficulty name)
    var questParam: String?
    
    /// How many times the objective must be met
    var targetValue: Int
    
    /// Current progress toward the target
    var currentValue: Int
    
    /// EXP reward for completing this quest
    var expReward: Int
    
    /// Gold reward for completing this quest
    var goldReward: Int
    
    /// Whether this quest has been completed (currentValue >= targetValue)
    var isCompleted: Bool
    
    /// Whether the reward has been claimed
    var isClaimed: Bool
    
    /// Whether this is the bonus quest for completing all 3
    var isBonusQuest: Bool
    
    /// The date this quest was generated (start of day)
    var generatedDate: Date
    
    /// The character this quest belongs to
    var characterID: UUID
    
    init(
        title: String,
        description: String,
        icon: String,
        questType: DailyQuestType,
        questParam: String? = nil,
        targetValue: Int,
        expReward: Int,
        goldReward: Int,
        isBonusQuest: Bool = false,
        characterID: UUID
    ) {
        self.id = UUID()
        self.title = title
        self.questDescription = description
        self.icon = icon
        self.questType = questType
        self.questParam = questParam
        self.targetValue = targetValue
        self.currentValue = 0
        self.expReward = expReward
        self.goldReward = goldReward
        self.isCompleted = false
        self.isClaimed = false
        self.isBonusQuest = isBonusQuest
        self.generatedDate = Calendar.current.startOfDay(for: Date())
        self.characterID = characterID
    }
    
    /// Progress as a fraction (0.0 - 1.0)
    var progress: Double {
        guard targetValue > 0 else { return 0 }
        return min(1.0, Double(currentValue) / Double(targetValue))
    }
    
    /// Increment progress and auto-complete if target reached
    func incrementProgress(by amount: Int = 1) {
        currentValue = min(currentValue + amount, targetValue)
        if currentValue >= targetValue && !isCompleted {
            isCompleted = true
        }
    }
}

// MARK: - Quest Type

/// Types of daily quest objectives (no associated values for SwiftData compatibility)
enum DailyQuestType: String, Codable {
    /// Complete N tasks of any kind
    case completeTasks = "Complete Tasks"
    /// Complete N tasks of a specific category (param = category rawValue)
    case completeCategory = "Complete Category"
    /// Start N AFK training sessions
    case startMission = "Start Training"
    /// Clear N dungeon rooms
    case clearDungeonRooms = "Clear Rooms"
    /// Earn N total EXP (from any source)
    case earnEXP = "Earn EXP"
    /// Earn N total gold (from any source)
    case earnGold = "Earn Gold"
    /// Have an active streak of N days
    case maintainStreak = "Maintain Streak"
    // --- 7 New Quest Types (§27) ---
    /// Forge or enhance an item
    case forgeItem = "Forge Item"
    /// Use a consumable item
    case useConsumable = "Use Consumable"
    /// Reach wave N in the Arena
    case completeArenaWave = "Arena Wave"
    /// Log your mood today
    case checkMood = "Check Mood"
    /// Complete a duty board task
    case completeDuty = "Complete Duty"
    /// Complete a task within 1 hour of a party member
    case partyTaskSync = "Party Sync"
    /// Attempt content that can drop a card (dungeon/arena/raid)
    case attemptCardContent = "Card Content"
    
    /// Map from server quest_type string to local enum
    static func from(serverType: String) -> DailyQuestType? {
        switch serverType {
        case "completeTasks": return .completeTasks
        case "completeCategory": return .completeCategory
        case "startTraining": return .startMission
        case "clearDungeonRooms": return .clearDungeonRooms
        case "earnExp": return .earnEXP
        case "earnGold": return .earnGold
        case "maintainStreak": return .maintainStreak
        case "forgeItem": return .forgeItem
        case "useConsumable": return .useConsumable
        case "completeArenaWave": return .completeArenaWave
        case "checkMood": return .checkMood
        case "completeDuty": return .completeDuty
        case "partyTaskSync": return .partyTaskSync
        case "attemptCardContent": return .attemptCardContent
        default: return nil
        }
    }
}

// MARK: - Quest Pool / Templates

/// Generates daily quests scaled by character level.
/// Prefers server-driven templates from ContentManager (content_quests table)
/// and falls back to hardcoded templates if ContentManager hasn't loaded.
struct DailyQuestPool {
    
    /// Generate 3 quests + 1 bonus quest for a character
    @MainActor
    static func generateQuests(for character: PlayerCharacter) -> [DailyQuest] {
        let level = character.level
        let pool = availableTemplates(for: level)
        
        // Pick 3 unique quest types
        var selected: [QuestTemplate] = []
        var usedTypes: Set<DailyQuestType> = []
        var shuffled = pool.shuffled()
        
        while selected.count < 3 && !shuffled.isEmpty {
            let template = shuffled.removeFirst()
            if !usedTypes.contains(template.type) {
                selected.append(template)
                usedTypes.insert(template.type)
            }
        }
        
        // Fallback: if we couldn't get 3 unique types, just take what we have
        while selected.count < 3 && !shuffled.isEmpty {
            selected.append(shuffled.removeFirst())
        }
        
        // Apply level multiplier to rewards
        let lvlMult = max(1, level / 10 + 1)
        
        var quests = selected.map { template in
            DailyQuest(
                title: template.title,
                description: template.description,
                icon: template.icon,
                questType: template.type,
                questParam: template.param,
                targetValue: template.target,
                expReward: template.expReward * lvlMult,
                goldReward: template.goldReward * lvlMult,
                characterID: character.id
            )
        }
        
        // Add bonus quest (all 3 complete)
        let bonusExp = quests.reduce(0) { $0 + $1.expReward } / 2
        let bonusGold = quests.reduce(0) { $0 + $1.goldReward } / 2
        let bonus = DailyQuest(
            title: "Daily Bonus",
            description: "Complete all 3 daily quests",
            icon: "gift.fill",
            questType: .completeTasks, // placeholder type, tracked manually
            questParam: nil,
            targetValue: 3,
            expReward: max(bonusExp, 25),
            goldReward: max(bonusGold, 15),
            isBonusQuest: true,
            characterID: character.id
        )
        quests.append(bonus)
        
        return quests
    }
    
    // MARK: - Template Pool
    
    private struct QuestTemplate {
        let title: String
        let description: String
        let icon: String
        let type: DailyQuestType
        let param: String?
        let target: Int
        let expReward: Int
        let goldReward: Int
    }
    
    /// Build template pool — server-driven (ContentManager) with hardcoded fallback.
    @MainActor
    private static func availableTemplates(for level: Int) -> [QuestTemplate] {
        let cm = ContentManager.shared
        
        // Try server-driven quest definitions first
        if cm.isLoaded && !cm.quests.isEmpty {
            return serverDrivenTemplates(for: level, from: cm)
        }
        
        // Fallback to hardcoded templates
        return hardcodedTemplates(for: level)
    }
    
    /// Build templates from ContentManager's server-driven quest definitions.
    @MainActor
    private static func serverDrivenTemplates(for level: Int, from cm: ContentManager) -> [QuestTemplate] {
        let regular = cm.activeQuests(forLevel: level, isBonus: false)
        
        // Weighted random selection — higher weight = more likely
        return regular.compactMap { quest in
            guard let type = DailyQuestType.from(serverType: quest.questType) else { return nil }
            let icon = iconFor(questType: type, category: quest.targetCategory)
            return QuestTemplate(
                title: quest.title,
                description: quest.description,
                icon: icon,
                type: type,
                param: quest.targetCategory,
                target: quest.targetValue,
                expReward: quest.rewardExp,
                goldReward: quest.rewardGold
            )
        }
    }
    
    /// Icon mapping for quest types
    private static func iconFor(questType: DailyQuestType, category: String?) -> String {
        switch questType {
        case .completeTasks: return "checkmark.circle.fill"
        case .completeCategory:
            if let cat = category, let tc = TaskCategory(rawValue: cat.capitalized) {
                return tc.icon
            }
            return "list.bullet"
        case .startMission: return "figure.strengthtraining.traditional"
        case .clearDungeonRooms: return "shield.lefthalf.filled"
        case .earnEXP: return "sparkles"
        case .earnGold: return "dollarsign.circle.fill"
        case .maintainStreak: return "flame.fill"
        case .forgeItem: return "hammer.fill"
        case .useConsumable: return "cross.vial.fill"
        case .completeArenaWave: return "figure.fencing"
        case .checkMood: return "heart.text.square.fill"
        case .completeDuty: return "clipboard.fill"
        case .partyTaskSync: return "person.2.fill"
        case .attemptCardContent: return "rectangle.stack.fill"
        }
    }
    
    /// Hardcoded template fallback (original implementation).
    private static func hardcodedTemplates(for level: Int) -> [QuestTemplate] {
        var templates: [QuestTemplate] = []
        
        let taskCount = level < 6 ? 2 : (level < 16 ? 3 : 5)
        templates.append(QuestTemplate(
            title: "Task Warrior",
            description: "Complete \(taskCount) tasks",
            icon: "checkmark.circle.fill",
            type: .completeTasks,
            param: nil,
            target: taskCount,
            expReward: taskCount * 15,
            goldReward: taskCount * 8
        ))
        
        let category = TaskCategory.allCases.randomElement()!
        templates.append(QuestTemplate(
            title: "\(category.rawValue) Focus",
            description: "Complete a \(category.rawValue.lowercased()) task",
            icon: category.icon,
            type: .completeCategory,
            param: category.rawValue,
            target: 1,
            expReward: 20,
            goldReward: 10
        ))
        
        let expTarget = level < 6 ? 50 : (level < 16 ? 100 : 200)
        templates.append(QuestTemplate(
            title: "EXP Hunter",
            description: "Earn \(expTarget) EXP today",
            icon: "sparkles",
            type: .earnEXP,
            param: nil,
            target: expTarget,
            expReward: 25,
            goldReward: 15
        ))
        
        let goldTarget = level < 6 ? 25 : (level < 16 ? 60 : 120)
        templates.append(QuestTemplate(
            title: "Gold Rush",
            description: "Earn \(goldTarget) gold today",
            icon: "dollarsign.circle.fill",
            type: .earnGold,
            param: nil,
            target: goldTarget,
            expReward: 20,
            goldReward: 20
        ))
        
        if level >= 3 {
            templates.append(QuestTemplate(
                title: "Streak Keeper",
                description: "Maintain your daily streak",
                icon: "flame.fill",
                type: .maintainStreak,
                param: nil,
                target: 1,
                expReward: 15,
                goldReward: 10
            ))
            templates.append(QuestTemplate(
                title: "Training Session",
                description: "Start an AFK training session",
                icon: "figure.strengthtraining.traditional",
                type: .startMission,
                param: nil,
                target: 1,
                expReward: 20,
                goldReward: 15
            ))
        }
        
        if level >= 5 {
            let roomCount = level < 16 ? 1 : 2
            templates.append(QuestTemplate(
                title: "Dungeon Delver",
                description: "Clear \(roomCount) dungeon room\(roomCount > 1 ? "s" : "")",
                icon: "shield.lefthalf.filled",
                type: .clearDungeonRooms,
                param: nil,
                target: roomCount,
                expReward: roomCount * 25,
                goldReward: roomCount * 15
            ))
            templates.append(QuestTemplate(
                title: "Forge Ahead",
                description: "Forge or enhance 1 item",
                icon: "hammer.fill",
                type: .forgeItem,
                param: nil,
                target: 1,
                expReward: 30,
                goldReward: 20
            ))
            templates.append(QuestTemplate(
                title: "How Are You?",
                description: "Log your mood today",
                icon: "heart.text.square.fill",
                type: .checkMood,
                param: nil,
                target: 1,
                expReward: 15,
                goldReward: 10
            ))
            templates.append(QuestTemplate(
                title: "Duty Bound",
                description: "Complete a duty board task",
                icon: "clipboard.fill",
                type: .completeDuty,
                param: nil,
                target: 1,
                expReward: 20,
                goldReward: 15
            ))
        }
        
        if level >= 10 {
            templates.append(QuestTemplate(
                title: "Arena Warm-Up",
                description: "Reach wave 3 in the Arena",
                icon: "figure.fencing",
                type: .completeArenaWave,
                param: nil,
                target: 3,
                expReward: 30,
                goldReward: 25
            ))
            templates.append(QuestTemplate(
                title: "Card Hunter",
                description: "Attempt content that can drop a card",
                icon: "rectangle.stack.fill",
                type: .attemptCardContent,
                param: nil,
                target: 1,
                expReward: 25,
                goldReward: 20
            ))
        }
        
        return templates
    }
    
    // MARK: - Weekly Bonus Quest
    
    /// Check if the player qualifies for the weekly bonus quest reward.
    /// Requires completing all 3 daily quests on 5 out of the last 7 days.
    /// Returns true if the weekly bonus should be awarded.
    static func checkWeeklyBonusEligibility(completedDays: Int) -> Bool {
        return completedDays >= 5
    }
    
    /// Weekly bonus rewards: gold + consumable + chance at rare equipment
    static func weeklyBonusRewards(level: Int) -> (gold: Int, exp: Int) {
        let lvlMult = max(1, level / 10 + 1)
        return (gold: 200 * lvlMult, exp: 300 * lvlMult)
    }
}
