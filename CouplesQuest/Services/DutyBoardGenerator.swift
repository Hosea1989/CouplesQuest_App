import Foundation
import SwiftData

/// Generates daily rotating duty board tasks from a pool of templates
struct DutyBoardGenerator {
    
    // MARK: - Template Definition
    
    struct DutyTemplate {
        let title: String
        let description: String
        let category: TaskCategory
    }
    
    // MARK: - Task Pool (all 6 categories)
    
    static let taskPool: [DutyTemplate] = [
        // Physical (→ Strength)
        DutyTemplate(title: "Do 20 Push-ups", description: "Drop and give me 20!", category: .physical),
        DutyTemplate(title: "30-Minute Workout", description: "Any exercise — gym, run, or home workout", category: .physical),
        DutyTemplate(title: "Plank for 1 Minute", description: "Hold a plank — build that core!", category: .physical),
        DutyTemplate(title: "Go for a Run", description: "Run for at least 15 minutes", category: .physical),
        DutyTemplate(title: "Go for a Walk", description: "Walk outside for at least 15 minutes", category: .physical),
        DutyTemplate(title: "Yoga Session", description: "15 minutes of yoga flow", category: .physical),
        
        // Mental (→ Wisdom)
        DutyTemplate(title: "Read for 15 Minutes", description: "A book, article, or anything that inspires you", category: .mental),
        DutyTemplate(title: "Sudoku Challenge", description: "Solve a Sudoku puzzle — faster times earn bigger rewards!", category: .mental),
        DutyTemplate(title: "Memory Match", description: "Match all pairs — faster matches earn bigger rewards!", category: .mental),
        DutyTemplate(title: "Math Blitz", description: "Solve 20 math problems as fast as you can!", category: .mental),
        DutyTemplate(title: "Word Search", description: "Find all hidden words in the grid!", category: .mental),
        DutyTemplate(title: "2048 Challenge", description: "Merge tiles to reach 2048 — higher tiles earn better rewards!", category: .mental),
        DutyTemplate(title: "Learn Something New", description: "Watch a tutorial or read about a new topic", category: .mental),
        DutyTemplate(title: "Journal for 10 Minutes", description: "Write about your day, goals, or gratitude", category: .mental),
        DutyTemplate(title: "Listen to a Podcast", description: "Pick something educational or inspiring", category: .mental),
        
        // Social (→ Charisma)
        DutyTemplate(title: "Call a Friend or Family", description: "Catch up with someone you care about", category: .social),
        DutyTemplate(title: "Compliment 3 People", description: "Brighten someone's day with kind words", category: .social),
        DutyTemplate(title: "Have a Real Conversation", description: "Put the phone away and connect face-to-face", category: .social),
        DutyTemplate(title: "Write a Thank You", description: "Send a message of gratitude to someone", category: .social),
        
        // Household (→ Defense)
        DutyTemplate(title: "Clean the Kitchen", description: "Dishes, counters, and all — fortify your castle!", category: .household),
        DutyTemplate(title: "Do the Laundry", description: "Wash, dry, fold — the full cycle", category: .household),
        DutyTemplate(title: "Organize a Drawer", description: "Pick one drawer or shelf and tidy it up", category: .household),
        DutyTemplate(title: "Take Out the Trash", description: "Quick win — take it out and replace the bag", category: .household),
        DutyTemplate(title: "Vacuum or Sweep", description: "Give the floors some love", category: .household),
        
        // Wellness (→ Luck)
        DutyTemplate(title: "Drink 8 Glasses of Water", description: "Stay hydrated throughout the day", category: .wellness),
        DutyTemplate(title: "Meditate for 5 Minutes", description: "Find a quiet spot and breathe deeply", category: .wellness),
        DutyTemplate(title: "No Phone for 1 Hour", description: "Put the phone down and be present", category: .wellness),
        DutyTemplate(title: "Get 8 Hours of Sleep", description: "Prioritize rest tonight", category: .wellness),
        DutyTemplate(title: "10-Minute Stretch", description: "Full body stretch to start or end the day", category: .wellness),
        
        // Creative (→ Dexterity)
        DutyTemplate(title: "Sketch or Doodle", description: "Draw anything — no judgment, just create", category: .creative),
        DutyTemplate(title: "Write for 15 Minutes", description: "Story, poem, blog — let the words flow", category: .creative),
        DutyTemplate(title: "Play an Instrument", description: "Practice for at least 10 minutes", category: .creative),
        DutyTemplate(title: "Cook Something New", description: "Try a recipe you've never made before", category: .creative),
        DutyTemplate(title: "Take a Photo", description: "Capture something beautiful or interesting", category: .creative),
    ]
    
    /// Number of regular duties to show on the board per day
    static let dailyDutyCount = 4
    
    /// Maximum number of duties a player can accept per day
    static let maxDutySelectionsPerDay = 1
    
    /// Cost in gold for a paid refresh (after the 1 free daily refresh)
    static let paidRefreshCost = 50
    
    /// Whether the player needs to pay for the next refresh
    static var requiresPaidRefresh: Bool {
        refreshCount >= 1
    }
    
    // MARK: - Claim Tracking (UserDefaults — persists across view reloads)
    
    private static let claimedCountKey = "DutyBoard_ClaimedCount"
    private static let claimedDateKey = "DutyBoard_ClaimedDate"
    
    /// How many duties the player has claimed today (persisted in UserDefaults).
    static var dutiesClaimedToday: Int {
        get {
            if let date = UserDefaults.standard.object(forKey: claimedDateKey) as? Date,
               Calendar.current.isDateInToday(date) {
                return UserDefaults.standard.integer(forKey: claimedCountKey)
            }
            return 0
        }
        set {
            UserDefaults.standard.set(newValue, forKey: claimedCountKey)
            UserDefaults.standard.set(Date(), forKey: claimedDateKey)
        }
    }
    
    /// Record that the player has claimed a duty today.
    static func recordDutyClaim() {
        dutiesClaimedToday += 1
    }
    
    /// Whether the player has reached the daily duty selection limit (persisted check).
    static var reachedDailyDutyLimit: Bool {
        dutiesClaimedToday >= maxDutySelectionsPerDay
    }
    
    // MARK: - Refresh Tracking (UserDefaults)
    
    private static let refreshDateKey = "DutyBoard_LastRefreshDate"
    private static let refreshCountKey = "DutyBoard_RefreshCount"
    
    /// The date of the last refresh, or nil if never refreshed.
    static var lastRefreshDate: Date? {
        get { UserDefaults.standard.object(forKey: refreshDateKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: refreshDateKey) }
    }
    
    /// How many times the user has refreshed today (0 = hasn't refreshed yet).
    static var refreshCount: Int {
        get {
            // Reset count automatically if the stored date is not today
            if let date = lastRefreshDate, Calendar.current.isDateInToday(date) {
                return UserDefaults.standard.integer(forKey: refreshCountKey)
            }
            return 0
        }
        set {
            UserDefaults.standard.set(newValue, forKey: refreshCountKey)
        }
    }
    
    /// Whether the player has a free refresh available today
    static var hasFreeRefresh: Bool {
        return refreshCount < 1
    }
    
    /// Whether the player can refresh (free or paid)
    static var canRefreshToday: Bool {
        return true // Always available — first is free, subsequent cost gold
    }
    
    // MARK: - Content Pool (server-driven with static fallback)
    
    /// Get the active duty pool, preferring server-driven content from ContentManager.
    /// Falls back to the static `taskPool` if ContentManager hasn't loaded yet.
    @MainActor
    private static func activePool() -> [DutyTemplate] {
        let cm = ContentManager.shared
        if cm.isLoaded && !cm.duties.isEmpty {
            return cm.duties.map { duty in
                let cat = TaskCategory(rawValue: duty.category.capitalized) ?? .mental
                return DutyTemplate(title: duty.title, description: duty.description, category: cat)
            }
        }
        return taskPool
    }
    
    // MARK: - Daily Selection
    
    /// Select today's duties, guaranteeing 4 different categories.
    /// The `refreshOffset` shifts the seed so reshuffles produce different results.
    @MainActor
    static func todaysTemplates(refreshOffset: Int = 0) -> [DutyTemplate] {
        let today = Calendar.current.startOfDay(for: Date())
        let daysSinceEpoch = Int(today.timeIntervalSince1970 / 86400)
        // Mix in the refresh offset with a prime multiplier for good distribution
        var rng = SeededRandomNumberGenerator(seed: UInt64(bitPattern: Int64(daysSinceEpoch &+ refreshOffset &* 7919)))
        
        // Use server-driven content pool (or static fallback)
        let pool = activePool()
        
        // Group all templates by category
        let grouped = Dictionary(grouping: pool, by: { $0.category })
        
        // Shuffle available categories and pick 4 distinct ones
        var categories = Array(grouped.keys)
        categories.shuffle(using: &rng)
        let selectedCategories = Array(categories.prefix(dailyDutyCount))
        
        // Pick one random template from each selected category
        var result: [DutyTemplate] = []
        for category in selectedCategories {
            var pool = grouped[category] ?? []
            pool.shuffle(using: &rng)
            if let template = pool.first {
                result.append(template)
            }
        }
        
        return result
    }
    
    // MARK: - SwiftData Integration
    
    /// Check if today's duty board tasks exist. If not, clear old ones and generate new ones.
    /// Returns the current day's duty tasks.
    @MainActor
    static func ensureTodaysDuties(characterID: UUID, context: ModelContext) -> [GameTask] {
        let today = Calendar.current.startOfDay(for: Date())
        let offset = refreshCount
        
        // Fetch all daily duty tasks
        let descriptor = FetchDescriptor<GameTask>(
            predicate: #Predicate<GameTask> { task in
                task.isDailyDuty == true
            }
        )
        
        let existingDuties = (try? context.fetch(descriptor)) ?? []
        
        // Check if we have the correct number of duties created today
        let todaysDuties = existingDuties.filter {
            Calendar.current.isDate($0.createdAt, inSameDayAs: today)
        }
        
        // Only reuse if the count matches the expected daily count
        let pendingToday = todaysDuties.filter { $0.status == .pending }
        let claimedToday = todaysDuties.filter { $0.status != .pending }
        if !todaysDuties.isEmpty && (pendingToday.count + claimedToday.count) == dailyDutyCount {
            return todaysDuties
        }
        
        // Clear all stale duties (wrong count or from previous days)
        for old in existingDuties {
            // Keep duties that were already accepted/completed today
            if Calendar.current.isDate(old.createdAt, inSameDayAs: today) && old.status != .pending {
                continue
            }
            context.delete(old)
        }
        
        // If we already have claimed duties today, only generate remaining slots
        if !claimedToday.isEmpty {
            let remaining = dailyDutyCount - claimedToday.count
            if remaining <= 0 { return claimedToday }
            let templates = todaysTemplates(refreshOffset: offset)
            let claimedTitles = Set(claimedToday.map { $0.title })
            let newTemplates = templates.filter { !claimedTitles.contains($0.title) }
            var newDuties = claimedToday
            for template in newTemplates.prefix(remaining) {
                let task = GameTask(
                    title: template.title,
                    description: template.description,
                    category: template.category,
                    createdBy: characterID,
                    isOnDutyBoard: true,
                    isDailyDuty: true
                )
                context.insert(task)
                newDuties.append(task)
            }
            try? context.save()
            return newDuties
        }
        
        // Generate new duties from today's templates
        let templates = todaysTemplates(refreshOffset: offset)
        var newDuties: [GameTask] = []
        
        for template in templates {
            let task = GameTask(
                title: template.title,
                description: template.description,
                category: template.category,
                createdBy: characterID,
                isOnDutyBoard: true,
                isDailyDuty: true
            )
            context.insert(task)
            newDuties.append(task)
        }
        
        try? context.save()
        return newDuties
    }
    
    /// Refresh the duty board: delete all unclaimed duties and regenerate with a new seed.
    /// Returns the new set of duties. Call only if `canRefreshToday` is true.
    @MainActor
    static func refreshDutyBoard(characterID: UUID, context: ModelContext) -> [GameTask] {
        // Record the refresh
        refreshCount += 1
        lastRefreshDate = Date()
        
        let today = Calendar.current.startOfDay(for: Date())
        
        // Fetch all daily duties
        let descriptor = FetchDescriptor<GameTask>(
            predicate: #Predicate<GameTask> { task in
                task.isDailyDuty == true
            }
        )
        
        let existingDuties = (try? context.fetch(descriptor)) ?? []
        
        // Delete only pending (unclaimed) duties from today — keep accepted/completed ones
        var claimedToday: [GameTask] = []
        for duty in existingDuties {
            if Calendar.current.isDate(duty.createdAt, inSameDayAs: today) && duty.status != .pending {
                claimedToday.append(duty)
            } else {
                context.delete(duty)
            }
        }
        
        // Generate new duties with the new offset
        let remaining = dailyDutyCount - claimedToday.count
        if remaining <= 0 {
            try? context.save()
            return claimedToday
        }
        
        let templates = todaysTemplates(refreshOffset: refreshCount)
        let claimedTitles = Set(claimedToday.map { $0.title })
        let freshTemplates = templates.filter { !claimedTitles.contains($0.title) }
        
        var newDuties = claimedToday
        for template in freshTemplates.prefix(remaining) {
            let task = GameTask(
                title: template.title,
                description: template.description,
                category: template.category,
                createdBy: characterID,
                isOnDutyBoard: true,
                isDailyDuty: true
            )
            context.insert(task)
            newDuties.append(task)
        }
        
        try? context.save()
        return newDuties
    }
    // MARK: - 5th Bonus Duty
    
    /// Generate a bonus duty that unlocks after completing all 4 regular duties.
    /// The bonus duty is from a different category than the 4 regular ones, and gives enhanced rewards.
    @MainActor
    static func generateBonusDuty(characterID: UUID, completedDuties: [GameTask], context: ModelContext) -> GameTask? {
        // Only unlock if all 4 regular duties are completed
        let completedCount = completedDuties.filter { $0.status == .completed }.count
        guard completedCount >= dailyDutyCount else { return nil }
        
        // Pick a category not already represented in today's completed duties
        let usedCategories = Set(completedDuties.map { $0.category })
        let availableCategories = TaskCategory.allCases.filter { !usedCategories.contains($0) }
        
        // Pick from available pool
        let targetCategory = availableCategories.randomElement() ?? TaskCategory.allCases.randomElement()!
        let categoryTemplates = taskPool.filter { $0.category == targetCategory }
        let template = categoryTemplates.randomElement() ?? taskPool.randomElement()!
        
        let bonusTask = GameTask(
            title: "⭐ " + template.title,
            description: "Bonus Duty! " + template.description,
            category: template.category,
            createdBy: characterID,
            isOnDutyBoard: true,
            isDailyDuty: true
        )
        context.insert(bonusTask)
        try? context.save()
        return bonusTask
    }
    
    // MARK: - Paid Refresh
    
    /// Attempt a paid refresh: deducts gold from character, refreshes the board.
    /// Returns the new duties, or nil if the character can't afford it.
    @MainActor
    static func paidRefresh(characterID: UUID, character: PlayerCharacter, context: ModelContext) -> [GameTask]? {
        guard character.gold >= paidRefreshCost else { return nil }
        character.gold -= paidRefreshCost
        return refreshDutyBoard(characterID: characterID, context: context)
    }
}

// NOTE: Uses SeededRandomNumberGenerator defined in Consumable.swift
