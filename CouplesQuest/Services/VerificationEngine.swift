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
    static func minimumDurationSeconds(for task: GameTask) -> Int {
        // Photo verification tasks already require interaction, shorter minimum
        if task.verificationType.requiresPhoto {
            return 60 // 1 minute
        }
        
        switch task.category {
        case .physical:
            return 300 // 5 minutes
        case .mental:
            return 120 // 2 minutes
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
    
    // MARK: - Combined Verification Multiplier
    
    /// Calculate the total verification multiplier including all anti-cheat layers
    static func totalVerificationMultiplier(
        task: GameTask,
        anomalyFlags: [AnomalyFlag],
        healthKitVerified: Bool,
        partnerConfirmed: Bool,
        geofenceResult: GeofenceResult?
    ) -> Double {
        var multiplier = task.verificationType.rewardMultiplier
        
        // HealthKit bonus: 1.25x
        if healthKitVerified {
            multiplier *= 1.25
        }
        
        // Partner confirmation bonus: 1.15x
        if partnerConfirmed {
            multiplier *= 1.15
        }
        
        // Geofence: if location verification is required but user is outside geofence
        if let geo = geofenceResult, !geo.inRange && task.verificationType.requiresLocation {
            // Reduce location portion of multiplier (apply 0.5x to the location bonus only)
            let locationBonus = task.verificationType.rewardMultiplier - 1.0
            let reduction = locationBonus * 0.5
            multiplier -= reduction
        }
        
        // Anomaly penalty
        multiplier *= anomalyMultiplier(flags: anomalyFlags)
        
        return max(1.0, multiplier)
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
