import Foundation
import SwiftData

/// A real-life task that can be completed for EXP
@Model
final class GameTask {
    /// Unique identifier
    var id: UUID
    
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
        geofenceLocationName: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.taskDescription = description
        self.category = category
        self.physicalFocus = physicalFocus
        self.customEXP = nil
        self.createdBy = createdBy
        self.assignedTo = assignedTo
        self.isOnDutyBoard = isOnDutyBoard
        self.isRecurring = isRecurring
        self.recurrencePattern = recurrencePattern
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
    }
    
    // MARK: - Reward Calculations
    
    /// Base EXP reward (flat, before verification multiplier)
    static let baseEXP: Int = 20
    
    /// Base Gold reward (flat, before verification multiplier)
    static let baseGold: Int = 10
    
    /// EXP reward for completing this task (before verification multiplier)
    var expReward: Int {
        customEXP ?? GameTask.baseEXP
    }
    
    /// Gold reward for completing this task (before verification multiplier)
    var goldReward: Int {
        GameTask.baseGold
    }
    
    /// Verification multiplier using logarithmic curve
    var verificationMultiplier: Double {
        verificationType.rewardMultiplier
    }
    
    /// Stat that gets a small bonus from this task
    var bonusStat: StatType {
        if category == .physical, let focus = physicalFocus {
            return focus.associatedStat
        }
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
    }
}

// MARK: - Supporting Types

/// Task categories: Physical or Mental
enum TaskCategory: String, Codable, CaseIterable {
    case physical = "Physical"
    case mental = "Mental"
    
    var icon: String {
        switch self {
        case .physical: return "figure.run"
        case .mental: return "brain.head.profile"
        }
    }
    
    var color: String {
        switch self {
        case .physical: return "CategoryPhysical"
        case .mental: return "CategoryMental"
        }
    }
    
    /// Default stat bonus for this category (Physical defaults to STR, Mental to WIS)
    var associatedStat: StatType {
        switch self {
        case .physical: return .strength
        case .mental: return .wisdom
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

