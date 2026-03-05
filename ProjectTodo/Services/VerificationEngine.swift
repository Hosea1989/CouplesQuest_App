import Foundation
import SwiftData
import CoreLocation

/// Centralized anti-cheat service for task verification
struct VerificationEngine {
    
    // MARK: - Minimum Duration
    
    /// Check whether a task has met its minimum completion time
    static func canComplete(task: GameTask) -> (allowed: Bool, reason: String?, remainingSeconds: Int) {
        guard let startedAt = task.startedAt else {
            // Task was never started -- allow (backward compatibility)
            return (true, nil, 0)
        }
        
        let minimumDuration = minimumDurationSeconds(for: task)
        let elapsed = Date().timeIntervalSince(startedAt)
        let remaining = max(0, Double(minimumDuration) - elapsed)
        
        if remaining > 0 {
            let mins = Int(remaining) / 60
            let secs = Int(remaining) % 60
            let timeStr = mins > 0 ? "\(mins)m \(secs)s" : "\(secs)s"
            return (false, "Please wait \(timeStr) before completing this task.", Int(remaining))
        }
        
        return (true, nil, 0)
    }
    
    /// Calculate minimum duration in seconds for a task
    /// Only enforced for verified tasks (honor system for unverified)
    static func minimumDurationSeconds(for task: GameTask) -> Int {
        // No minimum duration for self-reported (unverified) tasks
        if task.verificationType == .none {
            return 0
        }
        
        // Photo verification tasks already require interaction, shorter minimum
        if task.verificationType.requiresPhoto {
            return 60 // 1 minute
        }
        
        // Location-only verification
        switch task.category {
        case .physical:
            return 300 // 5 minutes
        case .mental, .creative:
            return 120 // 2 minutes
        case .social, .household, .wellness:
            return 60  // 1 minute
        }
    }
    
    // MARK: - Anomaly Detection
    
    /// Scan recent task completions for suspicious patterns
    static func detectAnomalies(characterID: UUID, context: ModelContext) -> [AnomalyFlag] {
        var flags: [AnomalyFlag] = []
        
        // Fetch tasks completed in the last 24 hours
        let oneDayAgo = Date().addingTimeInterval(-86400)
        let descriptor = FetchDescriptor<GameTask>(
            predicate: #Predicate<GameTask> { task in
                task.completedBy == characterID && task.completedAt != nil
            },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        
        guard let recentTasks = try? context.fetch(descriptor) else { return flags }
        
        // Filter to last 24 hours in memory (safer than complex predicate)
        let todaysTasks = recentTasks.filter { ($0.completedAt ?? .distantPast) > oneDayAgo }
        
        // Rule 1: More than 5 tasks completed within 10 minutes
        let tenMinutesAgo = Date().addingTimeInterval(-600)
        let rapidTasks = todaysTasks.filter { ($0.completedAt ?? .distantPast) > tenMinutesAgo }
        if rapidTasks.count > 5 {
            flags.append(.rapidCompletion(count: rapidTasks.count, windowMinutes: 10))
        }
        
        // Rule 2: Tasks completed between 2 AM - 5 AM (soft flag)
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: Date())
        if currentHour >= 2 && currentHour < 5 {
            flags.append(.lateNightActivity(hour: currentHour))
        }
        
        // Rule 3: Extremely high daily count
        if todaysTasks.count > 20 {
            flags.append(.excessiveDailyCount(count: todaysTasks.count))
        }
        
        return flags
    }
    
    /// Calculate the anomaly penalty multiplier (1.0 = no penalty, 0.5 = flagged)
    static func anomalyMultiplier(flags: [AnomalyFlag]) -> Double {
        if flags.isEmpty { return 1.0 }
        
        var multiplier = 1.0
        for flag in flags {
            switch flag {
            case .rapidCompletion:
                multiplier *= 0.5
            case .lateNightActivity:
                multiplier *= 0.85 // Soft penalty
            case .excessiveDailyCount:
                multiplier *= 0.6
            }
        }
        
        return max(0.25, multiplier) // Never go below 25%
    }
    
    // MARK: - Geofence Verification
    
    /// Check whether the user's current location is within the task's geofence
    static func verifyGeofence(
        task: GameTask,
        userLatitude: Double,
        userLongitude: Double
    ) -> GeofenceResult {
        guard let geoLat = task.geofenceLatitude,
              let geoLon = task.geofenceLongitude,
              let geoRadius = task.geofenceRadius else {
            // No geofence set -- treat as in-range
            return GeofenceResult(inRange: true, distance: 0, radius: 0)
        }
        
        let taskLocation = CLLocation(latitude: geoLat, longitude: geoLon)
        let userLocation = CLLocation(latitude: userLatitude, longitude: userLongitude)
        let distance = userLocation.distance(from: taskLocation)
        
        return GeofenceResult(
            inRange: distance <= geoRadius,
            distance: distance,
            radius: geoRadius
        )
    }
    
    // MARK: - Photo Timestamp Validation
    
    /// Check whether a photo was taken within the allowed time window
    static func isPhotoTimestampValid(photoTakenAt: Date?, maxAgeSeconds: TimeInterval = 300) -> Bool {
        guard let taken = photoTakenAt else { return true } // No timestamp = legacy, allow
        return Date().timeIntervalSince(taken) <= maxAgeSeconds
    }
    
    // MARK: - Verification Tier System
    
    /// Determine the verification tier for a completed task.
    /// Tiers: Quick (1.0x) → Standard (1.15x) → Verified (1.3x) → Party-verified (1.5x)
    static func verificationTier(
        task: GameTask,
        healthKitVerified: Bool = false,
        partnerConfirmed: Bool = false,
        geofenceResult: GeofenceResult? = nil
    ) -> VerificationTier {
        // Party-verified: ally confirmed completion
        if partnerConfirmed {
            return .partyVerified
        }
        
        // Verified: photo, location, or HealthKit proof
        let hasPhotoProof = task.verificationType.requiresPhoto && task.verificationPhotoData != nil
        let hasLocationProof: Bool = {
            if let geo = geofenceResult { return geo.inRange }
            return task.verificationType.requiresLocation && task.verificationLatitude != nil
        }()
        if hasPhotoProof || hasLocationProof || healthKitVerified {
            return .verified
        }
        
        // Standard: minimum duration met (task was started and timer completed)
        if let started = task.startedAt {
            let elapsed = (task.completedAt ?? Date()).timeIntervalSince(started)
            if elapsed >= Double(minimumDurationSeconds(for: task)) && minimumDurationSeconds(for: task) > 0 {
                return .standard
            }
        }
        
        // Quick: one-tap completion, no proof
        return .quick
    }
    
    // MARK: - Combined Verification Multiplier
    
    /// Calculate the total verification multiplier including all anti-cheat layers.
    /// Now uses the tier system: Quick 1.0x → Standard 1.15x → Verified 1.3x → Party-verified 1.5x
    static func totalVerificationMultiplier(
        task: GameTask,
        anomalyFlags: [AnomalyFlag],
        healthKitVerified: Bool,
        partnerConfirmed: Bool,
        geofenceResult: GeofenceResult?
    ) -> Double {
        let tier = verificationTier(
            task: task,
            healthKitVerified: healthKitVerified,
            partnerConfirmed: partnerConfirmed,
            geofenceResult: geofenceResult
        )
        
        var multiplier = tier.expMultiplier
        
        // Anomaly penalty
        multiplier *= anomalyMultiplier(flags: anomalyFlags)
        
        return max(1.0, multiplier)
    }
    
    /// Calculate the loot chance bonus from the verification tier
    static func lootChanceBonus(
        task: GameTask,
        healthKitVerified: Bool = false,
        partnerConfirmed: Bool = false,
        geofenceResult: GeofenceResult? = nil
    ) -> Double {
        let tier = verificationTier(
            task: task,
            healthKitVerified: healthKitVerified,
            partnerConfirmed: partnerConfirmed,
            geofenceResult: geofenceResult
        )
        return tier.lootChanceBonus
    }
}

// MARK: - Verification Tier

/// The four verification tiers with escalating rewards.
/// Higher tiers incentivize proof through better rewards (not punishment).
enum VerificationTier: String, Codable {
    case quick = "Quick"
    case standard = "Standard"
    case verified = "Verified"
    case partyVerified = "Party Verified"
    
    /// EXP/Gold multiplier for this tier
    var expMultiplier: Double {
        switch self {
        case .quick: return 1.0
        case .standard: return 1.15
        case .verified: return 1.3
        case .partyVerified: return 1.5
        }
    }
    
    /// Bonus loot drop chance for this tier
    var lootChanceBonus: Double {
        switch self {
        case .quick: return 0.0
        case .standard: return 0.02
        case .verified: return 0.05
        case .partyVerified: return 0.08
        }
    }
    
    /// Display color name
    var color: String {
        switch self {
        case .quick: return "SecondaryText"
        case .standard: return "AccentGreen"
        case .verified: return "AccentGold"
        case .partyVerified: return "AccentPurple"
        }
    }
    
    /// SF Symbol icon
    var icon: String {
        switch self {
        case .quick: return "hand.tap.fill"
        case .standard: return "timer"
        case .verified: return "checkmark.shield.fill"
        case .partyVerified: return "person.2.circle.fill"
        }
    }
    
    /// Short description for UI
    var subtitle: String {
        switch self {
        case .quick: return "One-tap completion"
        case .standard: return "Duration verified"
        case .verified: return "Photo or location proof"
        case .partyVerified: return "Ally confirmed"
        }
    }
}

// MARK: - Supporting Types

/// Types of detected anomalies
enum AnomalyFlag {
    case rapidCompletion(count: Int, windowMinutes: Int)
    case lateNightActivity(hour: Int)
    case excessiveDailyCount(count: Int)
    
    var description: String {
        switch self {
        case .rapidCompletion(let count, let window):
            return "\(count) tasks in \(window) minutes"
        case .lateNightActivity(let hour):
            return "Active at \(hour):00 AM"
        case .excessiveDailyCount(let count):
            return "\(count) tasks today"
        }
    }
}

/// Result of a geofence verification check
struct GeofenceResult {
    let inRange: Bool
    let distance: Double  // meters
    let radius: Double    // meters
    
    var distanceText: String {
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
}
