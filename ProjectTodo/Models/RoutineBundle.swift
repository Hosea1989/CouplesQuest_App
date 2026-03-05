import Foundation
import SwiftData

/// A named group of 3–6 habits that can be completed as a batch.
/// Completing all habits in the routine triggers a +50% EXP completion bonus.
@Model
final class RoutineBundle {
    /// Unique identifier
    var id: UUID
    
    /// Display name (e.g. "Morning Quest", "Workout Quest", "Evening Quest")
    var name: String
    
    /// Optional description / flavor text
    var routineDescription: String?
    
    /// Time of day this routine is intended for
    var timeOfDay: RoutineTimeOfDay
    
    /// SF Symbol icon for display
    var icon: String
    
    /// Character ID of the owner
    var ownerID: UUID
    
    /// IDs of the habits (GameTask) included in this routine
    /// Stored as JSON array of UUID strings for SwiftData compatibility
    var habitIDs: String
    
    /// When this routine was created
    var createdAt: Date
    
    /// Whether this routine is archived (hidden but not deleted)
    var isArchived: Bool
    
    init(
        name: String,
        description: String? = nil,
        timeOfDay: RoutineTimeOfDay = .morning,
        icon: String = "sunrise.fill",
        ownerID: UUID,
        habitIDs: [UUID] = []
    ) {
        self.id = UUID()
        self.name = name
        self.routineDescription = description
        self.timeOfDay = timeOfDay
        self.icon = icon
        self.ownerID = ownerID
        self.habitIDs = RoutineBundle.encodeIDs(habitIDs)
        self.createdAt = Date()
        self.isArchived = false
    }
    
    // MARK: - Habit ID Management
    
    /// Decode the stored habit IDs
    func getHabitIDs() -> [UUID] {
        guard let data = habitIDs.data(using: .utf8),
              let strings = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return strings.compactMap { UUID(uuidString: $0) }
    }
    
    /// Set the habit IDs
    func setHabitIDs(_ ids: [UUID]) {
        habitIDs = RoutineBundle.encodeIDs(ids)
    }
    
    /// Add a habit to the routine (max 6)
    func addHabit(id: UUID) -> Bool {
        var ids = getHabitIDs()
        guard ids.count < RoutineBundle.maxHabits else { return false }
        guard !ids.contains(id) else { return false }
        ids.append(id)
        setHabitIDs(ids)
        return true
    }
    
    /// Remove a habit from the routine
    func removeHabit(id: UUID) {
        var ids = getHabitIDs()
        ids.removeAll { $0 == id }
        setHabitIDs(ids)
    }
    
    /// Number of habits in this routine
    var habitCount: Int {
        getHabitIDs().count
    }
    
    /// Whether this routine has enough habits (minimum 3)
    var isValid: Bool {
        let count = habitCount
        return count >= RoutineBundle.minHabits && count <= RoutineBundle.maxHabits
    }
    
    // MARK: - Completion Logic
    
    /// Check how many habits in this routine are completed today
    func completedCount(tasks: [GameTask]) -> Int {
        let ids = Set(getHabitIDs())
        return tasks.filter { ids.contains($0.id) && $0.isHabitCompletedToday }.count
    }
    
    /// Whether all habits in this routine are completed today
    func isCompleteToday(tasks: [GameTask]) -> Bool {
        let total = habitCount
        guard total > 0 else { return false }
        return completedCount(tasks: tasks) >= total
    }
    
    /// Progress toward completion (0.0–1.0)
    func progress(tasks: [GameTask]) -> Double {
        let total = habitCount
        guard total > 0 else { return 0 }
        return Double(completedCount(tasks: tasks)) / Double(total)
    }
    
    // MARK: - Constants
    
    /// Minimum habits per routine
    static let minHabits = 3
    
    /// Maximum habits per routine
    static let maxHabits = 6
    
    /// EXP bonus multiplier when all habits in a routine are completed (+50%)
    static let completionBonusMultiplier: Double = 0.50
    
    // MARK: - Helpers
    
    /// Encode UUID array to JSON string
    static func encodeIDs(_ ids: [UUID]) -> String {
        let strings = ids.map { $0.uuidString }
        guard let data = try? JSONEncoder().encode(strings),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }
}

// MARK: - Time of Day

/// When a routine is intended to be performed
enum RoutineTimeOfDay: String, Codable, CaseIterable {
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"
    case anytime = "Anytime"
    
    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening: return "moon.stars.fill"
        case .anytime: return "clock.fill"
        }
    }
    
    var color: String {
        switch self {
        case .morning: return "AccentGold"
        case .afternoon: return "AccentOrange"
        case .evening: return "AccentPurple"
        case .anytime: return "AccentGreen"
        }
    }
}
