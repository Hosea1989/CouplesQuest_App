import Foundation
import SwiftData

/// A real-life task that can be completed for EXP
@Model
final class GameTask {
    /// Unique identifier
    var id: UUID
    
    /// Cloud ID for partner tasks synced via Supabase (used for deduplication)
    var cloudID: String?
    
    /// Task title
    var title: String
    
    /// Optional description
    var taskDescription: String?
    
    /// Category: Physical or Mental
    var category: TaskCategory
    
    /// Physical activity focus (only for Physical tasks)
    var physicalFocus: PhysicalActivityFocus?
    
    /// Custom EXP override (nil uses base default)
    var customEXP: Int?
    
    /// Who created this task
    var createdBy: UUID
    
    /// Who this task is assigned to (nil = duty board)
    var assignedTo: UUID?
    
    /// Is this task on the shared duty board?
    var isOnDutyBoard: Bool
    
    /// Is this a recurring task?
    var isRecurring: Bool
    
    /// Recurrence pattern if recurring
    var recurrencePattern: RecurrencePattern?
    
    /// Physical activity requirement (for Apple Watch integration)
    var physicalRequirement: PhysicalRequirement?
    
    /// Task status
    var status: TaskStatus
    
    /// When the task was created
    var createdAt: Date
    
    /// When the task should be completed by (optional deadline)
    var dueDate: Date?
    
    /// When the task was completed
    var completedAt: Date?
    
    /// Who completed the task
    var completedBy: UUID?
    
    /// Optional message from partner when assigning task
    var partnerMessage: String?
    
    /// Whether this task was assigned by a partner
    var isFromPartner: Bool
    
    /// Whether this is a system-generated daily duty board task
    var isDailyDuty: Bool
    
    // MARK: - Verification
    
    /// What kind of proof is required for this task
    var verificationType: VerificationType
    
    /// Whether verification has been completed
    var isVerified: Bool
    
    /// Photo proof data (JPEG)
    var verificationPhotoData: Data?
    
    /// Location proof latitude
    var verificationLatitude: Double?
    
    /// Location proof longitude
    var verificationLongitude: Double?
    
    // MARK: - Anti-Cheat Fields
    
    /// When the user started working on this task (for minimum duration check)
    var startedAt: Date?
    
    /// Minimum seconds before completion is allowed (calculated from task type)
    var minimumDurationSeconds: Int = 0
    
    // MARK: - HealthKit Verification
    
    /// Whether HealthKit confirmed matching physical activity
    var healthKitVerified: Bool = false
    
    /// Summary of detected HealthKit activity (e.g. "30 min Strength Training detected")
    var healthKitActivitySummary: String?
    
    // MARK: - Partner Confirmation
    
    /// Whether this task is awaiting partner confirmation
    var pendingPartnerConfirmation: Bool = false
    
    /// Whether the partner has confirmed completion
    var partnerConfirmed: Bool = false
    
    /// When the partner confirmed
    var partnerConfirmedAt: Date?
    
    /// Reason the partner disputed (nil if not disputed)
    var partnerDisputeReason: String?
    
    // MARK: - Geofence Fields
    
    /// Target geofence latitude
    var geofenceLatitude: Double?
    
    /// Target geofence longitude
    var geofenceLongitude: Double?
    
    /// Geofence radius in meters (default 200m)
    var geofenceRadius: Double?
    
    /// Human-readable geofence location name
    var geofenceLocationName: String?
    
    // MARK: - Habit Fields
    
    /// Whether this task is a daily habit (auto-resets each day, tracks its own streak)
    var isHabit: Bool = false
    
    /// Current habit streak (consecutive days completed)
    var habitStreak: Int = 0
    
    /// Longest habit streak ever achieved
    var habitLongestStreak: Int = 0
    
    /// Last date the habit was completed (for streak tracking)
    var habitLastCompletedDate: Date?
    
    /// Optional daily due time for the habit (hour/minute stored as a Date; only time component matters).
    /// If set, the habit must be completed by this time or the player loses rewards.
    var habitDueTime: Date?
    
    /// Whether this habit was marked as failed today (missed deadline)
    var habitFailedToday: Bool = false
    
    /// The date the habit was last failed (to prevent double-penalizing)
    var habitLastFailedDate: Date?
    
    // MARK: - Co-op / Partner Invite Fields
    
    /// Whether this duty was accepted as a co-op duty (partner does it too)
    var isCoopDuty: Bool = false
    
    /// Whether the partner has completed their side of this co-op duty
    var coopPartnerCompleted: Bool = false
    
    /// Whether the co-op bonus has already been awarded for this duty
    var coopBonusAwarded: Bool = false
    
    /// Whether the partner was invited to do this task together
    var isSharedWithPartner: Bool = false
    
    /// Whether the partner has completed their side of the shared task
    var sharedPartnerCompleted: Bool = false
    
    // MARK: - Goal Linking
    
    /// Optional link to a Goal — completing this task/habit contributes to goal progress
    var goalID: UUID?
    
    // MARK: - Routine Bundle
    
    /// Optional link to a RoutineBundle this habit belongs to
    var routineBundleID: UUID?
    
    // MARK: - Enhanced Photo Fields
    
    /// When the verification photo was actually captured
    var photoTakenAt: Date?
    
    /// Whether the device showed physical motion at photo capture time
    var photoHasMotionData: Bool = false
    
    init(
        title: String,
        description: String? = nil,
        category: TaskCategory,
        physicalFocus: PhysicalActivityFocus? = nil,
        createdBy: UUID,
        assignedTo: UUID? = nil,
        isOnDutyBoard: Bool = false,
        isRecurring: Bool = false,
        recurrencePattern: RecurrencePattern? = nil,
        physicalRequirement: PhysicalRequirement? = nil,
        dueDate: Date? = nil,
        partnerMessage: String? = nil,
        isFromPartner: Bool = false,
        isDailyDuty: Bool = false,
        verificationType: VerificationType = .none,
        geofenceLatitude: Double? = nil,
        geofenceLongitude: Double? = nil,
        geofenceRadius: Double? = nil,
        geofenceLocationName: String? = nil,
        isHabit: Bool = false,
        isSharedWithPartner: Bool = false,
        cloudID: String? = nil,
        goalID: UUID? = nil
    ) {
        self.id = UUID()
        self.cloudID = cloudID
        self.title = title
        self.taskDescription = description
        self.category = category
        self.physicalFocus = physicalFocus
        self.customEXP = nil
        self.createdBy = createdBy
        self.assignedTo = assignedTo
        self.isOnDutyBoard = isOnDutyBoard
        // Habits are always daily recurring
        self.isRecurring = isHabit ? true : isRecurring
        self.recurrencePattern = isHabit ? .daily : recurrencePattern
        self.physicalRequirement = physicalRequirement
        self.status = .pending
        self.createdAt = Date()
        self.dueDate = dueDate
        self.completedAt = nil
        self.completedBy = nil
        self.partnerMessage = partnerMessage
        self.isFromPartner = isFromPartner
        self.isDailyDuty = isDailyDuty
        self.verificationType = verificationType
        self.isVerified = false
        self.verificationPhotoData = nil
        self.verificationLatitude = nil
        self.verificationLongitude = nil
        
        // Anti-cheat fields
        self.startedAt = nil
        self.minimumDurationSeconds = 0
        self.healthKitVerified = false
        self.healthKitActivitySummary = nil
        self.pendingPartnerConfirmation = false
        self.partnerConfirmed = false
        self.partnerConfirmedAt = nil
        self.partnerDisputeReason = nil
        self.geofenceLatitude = geofenceLatitude
        self.geofenceLongitude = geofenceLongitude
        self.geofenceRadius = geofenceRadius
        self.geofenceLocationName = geofenceLocationName
        self.photoTakenAt = nil
        self.photoHasMotionData = false
        self.isHabit = isHabit
        self.habitStreak = 0
        self.habitLongestStreak = 0
        self.habitLastCompletedDate = nil
        self.isSharedWithPartner = isSharedWithPartner
        self.sharedPartnerCompleted = false
        self.goalID = goalID
    }
    
    // MARK: - Reward Calculations
    
    /// Base EXP reward (flat, before level scaling and verification multiplier)
    static let baseEXP: Int = 20
    
    /// Base Gold reward (flat, before level scaling and verification multiplier)
    static let baseGold: Int = 10
    
    /// Level scaling factor: +10% per level above 1, so high-level tasks stay rewarding
    /// against the exponential EXP curve.
    /// - Level 1: 1.0x  - Level 10: 1.9x  - Level 20: 2.9x  - Level 50: 5.9x
    static func levelScaleFactor(level: Int) -> Double {
        max(1.0, 1.0 + Double(level - 1) * 0.1)
    }
    
    /// Base EXP reward for this task (before level scaling and verification)
    var expReward: Int {
        customEXP ?? GameTask.baseEXP
    }
    
    /// Base Gold reward for this task (before level scaling and verification)
    var goldReward: Int {
        GameTask.baseGold
    }
    
    /// EXP reward scaled by character level (for display previews)
    func scaledExpReward(characterLevel: Int) -> Int {
        Int(Double(expReward) * GameTask.levelScaleFactor(level: characterLevel))
    }
    
    /// Gold reward scaled by character level (for display previews)
    func scaledGoldReward(characterLevel: Int) -> Int {
        Int(Double(goldReward) * GameTask.levelScaleFactor(level: characterLevel))
    }
    
    /// Verification multiplier using logarithmic curve
    var verificationMultiplier: Double {
        verificationType.rewardMultiplier
    }
    
    /// Stat that gets a small bonus from this task (determined by category)
    var bonusStat: StatType {
        return category.associatedStat
    }
    
    /// Start working on a task (sets startedAt and calculates minimum duration)
    func startTask() {
        guard startedAt == nil else { return } // Already started
        startedAt = Date()
        minimumDurationSeconds = VerificationEngine.minimumDurationSeconds(for: self)
        status = .inProgress
    }
    
    /// Whether this task has met its minimum completion duration
    var hasMetMinimumDuration: Bool {
        guard let started = startedAt else { return true } // Not started = legacy, allow
        return Date().timeIntervalSince(started) >= Double(minimumDurationSeconds)
    }
    
    /// Seconds remaining before minimum duration is met
    var remainingDurationSeconds: Int {
        guard let started = startedAt else { return 0 }
        let elapsed = Date().timeIntervalSince(started)
        return max(0, minimumDurationSeconds - Int(elapsed))
    }
    
    // MARK: - Deadline / Expiration
    
    /// Whether this task has a deadline and has passed it without being completed
    var isDeadlineExpired: Bool {
        guard let due = dueDate else { return false }
        return status != .completed && Date() > due
    }
    
    /// Seconds remaining until the deadline (0 if no deadline or already past)
    var remainingDeadlineSeconds: Int {
        guard let due = dueDate else { return 0 }
        return max(0, Int(due.timeIntervalSince(Date())))
    }
    
    /// Human-readable remaining deadline time (e.g. "5h 23m" or "12m 45s")
    var deadlineFormatted: String {
        let remaining = remainingDeadlineSeconds
        let hours = remaining / 3600
        let minutes = (remaining % 3600) / 60
        let seconds = remaining % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
    
    /// Whether this task has a deadline set
    var hasDeadline: Bool {
        dueDate != nil
    }
    
    /// Expire the task if its deadline has passed
    func expireIfPastDeadline() {
        guard isDeadlineExpired, status != .expired, status != .completed else { return }
        status = .expired
    }
    
    /// Whether this task requires partner confirmation on completion
    var requiresPartnerConfirmation: Bool {
        isFromPartner && !partnerConfirmed
    }
    
    /// Mark task as completed
    func complete(by characterID: UUID) {
        status = .completed
        completedAt = Date()
        completedBy = characterID
    }
    
    /// Mark a habit as completed for today, updating the streak
    func completeHabit(by characterID: UUID) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Check if the last completion was yesterday (continues streak) or earlier (resets)
        if let lastCompleted = habitLastCompletedDate {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            if calendar.isDate(lastCompleted, inSameDayAs: yesterday) {
                habitStreak += 1
            } else if !calendar.isDate(lastCompleted, inSameDayAs: today) {
                // Gap of more than 1 day — streak resets
                habitStreak = 1
            }
            // If completed same day, streak doesn't change (already counted)
        } else {
            habitStreak = 1
        }
        
        habitLongestStreak = max(habitLongestStreak, habitStreak)
        habitLastCompletedDate = today
        complete(by: characterID)
    }
    
    /// Whether this habit has been completed today
    var isHabitCompletedToday: Bool {
        guard isHabit, status == .completed, let completedAt = completedAt else { return false }
        return Calendar.current.isDateInToday(completedAt)
    }
    
    /// Whether this habit has failed today (missed its deadline)
    var isHabitFailedToday: Bool {
        guard isHabit else { return false }
        if let failedDate = habitLastFailedDate {
            return Calendar.current.isDateInToday(failedDate)
        }
        return false
    }
    
    /// The actual deadline for today based on `habitDueTime`.
    /// Returns nil if no due time is set (habit has all day).
    var habitDeadlineToday: Date? {
        guard isHabit, let dueTime = habitDueTime else { return nil }
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: dueTime)
        let minute = calendar.component(.minute, from: dueTime)
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now)
    }
    
    /// Whether the habit deadline has passed today
    var isHabitPastDeadline: Bool {
        guard let deadline = habitDeadlineToday else { return false }
        return Date() > deadline
    }
    
    /// Formatted due time string (e.g. "9:00 AM")
    var habitDueTimeFormatted: String? {
        guard let dueTime = habitDueTime else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: dueTime)
    }
    
    /// Time remaining until the habit deadline
    var habitTimeRemaining: String? {
        guard let deadline = habitDeadlineToday else { return nil }
        let remaining = Int(deadline.timeIntervalSince(Date()))
        guard remaining > 0 else { return nil }
        let hours = remaining / 3600
        let minutes = (remaining % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
    
    /// Mark the habit as failed for today (missed deadline)
    func failHabit() {
        habitFailedToday = true
        habitLastFailedDate = Date()
        // Reset streak on failure
        habitStreak = 0
    }
    
    /// Reset task for recurrence
    func resetForRecurrence() {
        status = .pending
        completedAt = nil
        completedBy = nil
        isVerified = false
        verificationPhotoData = nil
        verificationLatitude = nil
        verificationLongitude = nil
        startedAt = nil
        minimumDurationSeconds = 0
        healthKitVerified = false
        healthKitActivitySummary = nil
        pendingPartnerConfirmation = false
        partnerConfirmed = false
        partnerConfirmedAt = nil
        partnerDisputeReason = nil
        photoTakenAt = nil
        photoHasMotionData = false
        habitFailedToday = false
    }
}

// MARK: - Supporting Types

/// Task categories — each maps to a core stat
enum TaskCategory: String, Codable, CaseIterable {
    case physical = "Physical"
    case mental = "Mental"
    case social = "Social"
    case household = "Household"
    case wellness = "Wellness"
    case creative = "Creative"
    
    var icon: String {
        switch self {
        case .physical: return "figure.run"
        case .mental: return "brain.head.profile"
        case .social: return "person.2.fill"
        case .household: return "house.fill"
        case .wellness: return "heart.fill"
        case .creative: return "paintbrush.fill"
        }
    }
    
    var color: String {
        switch self {
        case .physical: return "CategoryPhysical"
        case .mental: return "CategoryMental"
        case .social: return "CategorySocial"
        case .household: return "CategoryHousehold"
        case .wellness: return "CategoryWellness"
        case .creative: return "CategoryCreative"
        }
    }
    
    /// The stat this category boosts
    var associatedStat: StatType {
        switch self {
        case .physical: return .strength
        case .mental: return .wisdom
        case .social: return .charisma
        case .household: return .defense
        case .wellness: return .luck
        case .creative: return .dexterity
        }
    }
}

/// Physical activity focus determines which stat gets boosted
enum PhysicalActivityFocus: String, Codable, CaseIterable {
    case strength = "Strength"
    case endurance = "Endurance"   // legacy — maps to dexterity
    case dexterity = "Dexterity"
    
    /// Active cases (excludes legacy endurance)
    static var activeCases: [PhysicalActivityFocus] {
        [.strength, .dexterity]
    }
    
    var icon: String {
        switch self {
        case .strength: return "figure.strengthtraining.traditional"
        case .endurance: return "figure.run"
        case .dexterity: return "figure.run"
        }
    }
    
    var subtitle: String {
        switch self {
        case .strength: return "Gym / Lifting"
        case .endurance: return "Cardio / Running / Movement"
        case .dexterity: return "Cardio / Running / Movement"
        }
    }
    
    var color: String {
        switch self {
        case .strength: return "StatStrength"
        case .endurance: return "StatDexterity"
        case .dexterity: return "StatDexterity"
        }
    }
    
    var associatedStat: StatType {
        switch self {
        case .strength: return .strength
        case .endurance: return .dexterity
        case .dexterity: return .dexterity
        }
    }
}

/// Verification type for task proof
enum VerificationType: String, Codable, CaseIterable {
    case none = "None"
    case photo = "Photo Proof"
    case location = "Location Check-in"
    case photoAndLocation = "Photo + Location"
    
    var icon: String {
        switch self {
        case .none: return "questionmark.circle"
        case .photo: return "camera.fill"
        case .location: return "location.fill"
        case .photoAndLocation: return "camera.viewfinder"
        }
    }
    
    var color: String {
        switch self {
        case .none: return "SecondaryText"
        case .photo: return "AccentGold"
        case .location: return "AccentGreen"
        case .photoAndLocation: return "AccentOrange"
        }
    }
    
    /// Logarithmic reward multiplier
    var rewardMultiplier: Double {
        switch self {
        case .none: return 1.0
        case .photo: return 1.0 + 0.5 * log2(2.0)             // 1.5x
        case .location: return 1.0 + 0.5 * log2(3.0)          // ~1.79x
        case .photoAndLocation: return 1.0 + 0.5 * log2(4.0)  // 2.0x
        }
    }
    
    /// Whether this requires a photo
    var requiresPhoto: Bool {
        self == .photo || self == .photoAndLocation
    }
    
    /// Whether this requires location
    var requiresLocation: Bool {
        self == .location || self == .photoAndLocation
    }
}

/// Task completion status
enum TaskStatus: String, Codable {
    case pending = "Pending"
    case inProgress = "In Progress"
    case completed = "Completed"
    case failed = "Failed"
    case expired = "Expired"
}

/// Recurrence pattern for recurring tasks
enum RecurrencePattern: String, Codable {
    case daily = "Daily"
    case weekdays = "Weekdays"
    case weekends = "Weekends"
    case weekly = "Weekly"
    case biweekly = "Biweekly"
    case monthly = "Monthly"
}

/// Physical activity requirement for Apple Watch integration
struct PhysicalRequirement: Codable {
    var type: PhysicalActivityType
    var target: Int
    
    enum PhysicalActivityType: String, Codable {
        case steps = "Steps"
        case activeMinutes = "Active Minutes"
        case calories = "Calories"
        case workoutMinutes = "Workout Minutes"
        case standHours = "Stand Hours"
    }
}

