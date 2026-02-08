import Foundation
import SwiftData

/// Generates daily rotating duty board tasks from a pool of templates
struct DutyBoardGenerator {
    
    // MARK: - Template Definition
    
    struct DutyTemplate {
        let title: String
        let description: String
        let category: TaskCategory
        let physicalFocus: PhysicalActivityFocus?
    }
    
    // MARK: - Task Pool (Physical and Mental categories)
    
    static let taskPool: [DutyTemplate] = [
        // Physical - Strength focus
        DutyTemplate(title: "Do 20 Push-ups", description: "Drop and give me 20!", category: .physical, physicalFocus: .strength),
        DutyTemplate(title: "30-Minute Workout", description: "Any exercise — gym, run, or home workout", category: .physical, physicalFocus: .strength),
        DutyTemplate(title: "Plank for 1 Minute", description: "Hold a plank — build that core!", category: .physical, physicalFocus: .strength),
        DutyTemplate(title: "Bodyweight Circuit", description: "Squats, push-ups, lunges — 3 rounds", category: .physical, physicalFocus: .strength),
        
        // Physical - Dexterity focus (cardio/movement)
        DutyTemplate(title: "Go for a Run", description: "Run for at least 15 minutes", category: .physical, physicalFocus: .dexterity),
        DutyTemplate(title: "Jump Rope 5 Minutes", description: "Get that heart rate up!", category: .physical, physicalFocus: .dexterity),
        DutyTemplate(title: "Take the Stairs", description: "Use stairs instead of elevators all day", category: .physical, physicalFocus: .dexterity),
        DutyTemplate(title: "Dance to 3 Songs", description: "Put on music and move your body", category: .physical, physicalFocus: .dexterity),
        
        // Physical - Dexterity focus
        DutyTemplate(title: "10-Minute Stretch", description: "Full body stretch to start or end the day", category: .physical, physicalFocus: .dexterity),
        DutyTemplate(title: "Go for a Walk", description: "Walk outside for at least 15 minutes", category: .physical, physicalFocus: .dexterity),
        DutyTemplate(title: "Yoga Session", description: "15 minutes of yoga flow", category: .physical, physicalFocus: .dexterity),
        DutyTemplate(title: "Balance Practice", description: "Single-leg stands, stretches, coordination drills", category: .physical, physicalFocus: .dexterity),
        
        // Mental
        DutyTemplate(title: "Read for 15 Minutes", description: "A book, article, or anything that inspires you", category: .mental, physicalFocus: nil),
        DutyTemplate(title: "Solve a Puzzle", description: "Complete a Sudoku puzzle in-app!", category: .mental, physicalFocus: nil),
        DutyTemplate(title: "Learn Something New", description: "Watch a tutorial or read about a new topic", category: .mental, physicalFocus: nil),
        DutyTemplate(title: "Journal for 10 Minutes", description: "Write about your day, goals, or gratitude", category: .mental, physicalFocus: nil),
        DutyTemplate(title: "Plan Tomorrow", description: "Write out your schedule and priorities", category: .mental, physicalFocus: nil),
        DutyTemplate(title: "Listen to a Podcast", description: "Pick something educational or inspiring", category: .mental, physicalFocus: nil),
        DutyTemplate(title: "Meditate for 5 Minutes", description: "Find a quiet spot and breathe deeply", category: .mental, physicalFocus: nil),
        DutyTemplate(title: "No Phone for 1 Hour", description: "Put the phone down and be present", category: .mental, physicalFocus: nil),
        DutyTemplate(title: "Drink 8 Glasses of Water", description: "Stay hydrated throughout the day", category: .mental, physicalFocus: nil),
    ]
    
    /// Number of duties to show on the board per day
    static let dailyDutyCount = 4
    
    /// Maximum number of duties a player can accept per day
    static let maxDutySelectionsPerDay = 1
    
    // MARK: - Daily Selection
    
    /// Select today's duties deterministically using the date as a seed.
    /// Same 4 all day, different 4 tomorrow.
    static func todaysTemplates() -> [DutyTemplate] {
        let today = Calendar.current.startOfDay(for: Date())
        // Create a deterministic seed from the date
        let daysSinceEpoch = Int(today.timeIntervalSince1970 / 86400)
        var rng = SeededRandomNumberGenerator(seed: UInt64(daysSinceEpoch))
        
        // Shuffle the pool with the seeded RNG and take the first N
        var pool = taskPool
        pool.shuffle(using: &rng)
        return Array(pool.prefix(dailyDutyCount))
    }
    
    // MARK: - SwiftData Integration
    
    /// Check if today's duty board tasks exist. If not, clear old ones and generate new ones.
    /// Returns the current day's duty tasks.
    @MainActor
    static func ensureTodaysDuties(characterID: UUID, context: ModelContext) -> [GameTask] {
        let today = Calendar.current.startOfDay(for: Date())
        
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
            let templates = todaysTemplates()
            let claimedTitles = Set(claimedToday.map { $0.title })
            let newTemplates = templates.filter { !claimedTitles.contains($0.title) }
            var newDuties = claimedToday
            for template in newTemplates.prefix(remaining) {
                let task = GameTask(
                    title: template.title,
                    description: template.description,
                    category: template.category,
                    physicalFocus: template.physicalFocus,
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
        let templates = todaysTemplates()
        var newDuties: [GameTask] = []
        
        for template in templates {
            let task = GameTask(
                title: template.title,
                description: template.description,
                category: template.category,
                physicalFocus: template.physicalFocus,
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
}

// NOTE: Uses SeededRandomNumberGenerator defined in Consumable.swift
