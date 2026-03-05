import Foundation
import HealthKit

/// Service that silently cross-references HealthKit data to verify physical task completion
@MainActor
class HealthKitService {
    
    static let shared = HealthKitService()
    
    private let healthStore = HKHealthStore()
    private var isAuthorized = false
    
    /// Check if HealthKit is available on this device
    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    // MARK: - Authorization
    
    /// Request HealthKit read authorization for verification-relevant data types
    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        
        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.workoutType()
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Verification Queries
    
    /// Verify a physical task by checking HealthKit for matching activity in the last 2 hours
    /// Returns a summary string if activity is found, nil otherwise
    func verifyPhysicalActivity(focus: PhysicalActivityFocus?) async -> HealthKitVerificationResult {
        guard isAvailable else {
            return HealthKitVerificationResult(verified: false, summary: nil)
        }
        
        // Ensure authorization
        if !isAuthorized {
            let authorized = await requestAuthorization()
            if !authorized {
                return HealthKitVerificationResult(verified: false, summary: nil)
            }
        }
        
        let twoHoursAgo = Date().addingTimeInterval(-7200) // 2 hours
        
        switch focus {
        case .strength:
            return await verifyStrengthActivity(since: twoHoursAgo)
        case .endurance:
            return await verifyDexterityActivity(since: twoHoursAgo)
        case .dexterity:
            return await verifyDexterityActivity(since: twoHoursAgo)
        case nil:
            // Generic physical task -- check for any workout or steps
            return await verifyAnyPhysicalActivity(since: twoHoursAgo)
        }
    }
    
    // MARK: - Strength Verification
    
    /// Look for strength training workouts
    private func verifyStrengthActivity(since startDate: Date) async -> HealthKitVerificationResult {
        let strengthTypes: [HKWorkoutActivityType] = [
            .traditionalStrengthTraining,
            .functionalStrengthTraining,
            .crossTraining
        ]
        
        if let workout = await findWorkout(types: strengthTypes, since: startDate) {
            let minutes = Int(workout.duration / 60)
            return HealthKitVerificationResult(
                verified: true,
                summary: "\(minutes) min Strength Training detected"
            )
        }
        
        return HealthKitVerificationResult(verified: false, summary: nil)
    }
    
    // MARK: - Endurance Verification
    
    /// Look for cardio workouts or high step count
    private func verifyEnduranceActivity(since startDate: Date) async -> HealthKitVerificationResult {
        let cardioTypes: [HKWorkoutActivityType] = [
            .running, .cycling, .swimming, .elliptical,
            .rowing, .stairClimbing, .highIntensityIntervalTraining
        ]
        
        if let workout = await findWorkout(types: cardioTypes, since: startDate) {
            let minutes = Int(workout.duration / 60)
            let typeName = workoutName(workout.workoutActivityType)
            return HealthKitVerificationResult(
                verified: true,
                summary: "\(minutes) min \(typeName) detected"
            )
        }
        
        // Fall back to step count
        let steps = await queryStepCount(since: startDate)
        if steps >= 2000 {
            return HealthKitVerificationResult(
                verified: true,
                summary: "\(Int(steps)) steps in last 2 hours"
            )
        }
        
        return HealthKitVerificationResult(verified: false, summary: nil)
    }
    
    // MARK: - Dexterity Verification
    
    /// Look for walking/yoga workouts or moderate step count
    private func verifyDexterityActivity(since startDate: Date) async -> HealthKitVerificationResult {
        let dexTypes: [HKWorkoutActivityType] = [
            .walking, .yoga, .pilates, .flexibility,
            .mindAndBody, .dance
        ]
        
        if let workout = await findWorkout(types: dexTypes, since: startDate) {
            let minutes = Int(workout.duration / 60)
            let typeName = workoutName(workout.workoutActivityType)
            return HealthKitVerificationResult(
                verified: true,
                summary: "\(minutes) min \(typeName) detected"
            )
        }
        
        // Fall back to step count
        let steps = await queryStepCount(since: startDate)
        if steps >= 1000 {
            return HealthKitVerificationResult(
                verified: true,
                summary: "\(Int(steps)) steps in last 2 hours"
            )
        }
        
        return HealthKitVerificationResult(verified: false, summary: nil)
    }
    
    // MARK: - Generic Physical Verification
    
    /// Check for any workout or significant step count
    private func verifyAnyPhysicalActivity(since startDate: Date) async -> HealthKitVerificationResult {
        // Check for any workout
        if let workout = await findAnyWorkout(since: startDate) {
            let minutes = Int(workout.duration / 60)
            let typeName = workoutName(workout.workoutActivityType)
            return HealthKitVerificationResult(
                verified: true,
                summary: "\(minutes) min \(typeName) detected"
            )
        }
        
        // Fall back to step count
        let steps = await queryStepCount(since: startDate)
        if steps >= 1000 {
            return HealthKitVerificationResult(
                verified: true,
                summary: "\(Int(steps)) steps in last 2 hours"
            )
        }
        
        return HealthKitVerificationResult(verified: false, summary: nil)
    }
    
    // MARK: - HealthKit Queries
    
    /// Find a workout of specific types since a given date
    private func findWorkout(types: [HKWorkoutActivityType], since startDate: Date) async -> HKWorkout? {
        let predicate = HKQuery.predicateForWorkouts(with: .greaterThanOrEqualTo, duration: 300) // At least 5 min
        let timePredicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        let compound = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, timePredicate])
        
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.workout(compound)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: 10
        )
        
        do {
            let workouts = try await descriptor.result(for: healthStore)
            return workouts.first(where: { types.contains($0.workoutActivityType) })
        } catch {
            return nil
        }
    }
    
    /// Find any workout since a given date
    private func findAnyWorkout(since startDate: Date) async -> HKWorkout? {
        let timePredicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.workout(timePredicate)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: 1
        )
        
        do {
            let workouts = try await descriptor.result(for: healthStore)
            return workouts.first
        } catch {
            return nil
        }
    }
    
    /// Query total step count since a given date
    private func queryStepCount(since startDate: Date) async -> Double {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return 0 }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, _ in
                let steps = statistics?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                continuation.resume(returning: steps)
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - Helpers
    
    /// Human-readable workout type name
    private func workoutName(_ type: HKWorkoutActivityType) -> String {
        switch type {
        case .traditionalStrengthTraining: return "Strength Training"
        case .functionalStrengthTraining: return "Functional Training"
        case .crossTraining: return "Cross Training"
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .elliptical: return "Elliptical"
        case .rowing: return "Rowing"
        case .stairClimbing: return "Stair Climbing"
        case .highIntensityIntervalTraining: return "HIIT"
        case .walking: return "Walking"
        case .yoga: return "Yoga"
        case .pilates: return "Pilates"
        case .flexibility: return "Flexibility"
        case .mindAndBody: return "Mind & Body"
        case .dance: return "Dance"
        default: return "Workout"
        }
    }
}

// MARK: - Result Type

/// Result of a HealthKit verification check
struct HealthKitVerificationResult {
    let verified: Bool
    let summary: String?
}
