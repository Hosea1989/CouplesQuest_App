import Foundation
import SwiftData
import Combine

/// Centralized sync manager that queues local writes for async cloud push.
/// - Flushes every 30 seconds + on app background
/// - Retries with exponential backoff on failure
/// - Timestamp-based last-write-wins conflict resolution
/// - Subtle "sync pending" state after 3 consecutive failures
@MainActor
final class SyncManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = SyncManager()
    
    // MARK: - Published State
    
    /// Whether a sync is currently in progress
    @Published var isSyncing = false
    
    /// Whether sync has failed 3+ consecutive times (show subtle indicator)
    @Published var hasSyncIssue = false
    
    /// Number of pending operations in the queue
    @Published var pendingCount = 0
    
    // MARK: - Private State
    
    /// Queue of sync operations waiting to be flushed
    private var syncQueue: [SyncOperation] = []
    
    /// Timer for periodic flush (every 30 seconds)
    private var flushTimer: Timer?
    
    /// Consecutive failure count (resets on success)
    private var consecutiveFailures = 0
    
    /// Maximum consecutive failures before showing sync issue indicator
    private let maxConsecutiveFailures = 3
    
    /// Current backoff delay in seconds
    private var backoffDelay: TimeInterval = 1.0
    
    /// Maximum backoff delay
    private let maxBackoffDelay: TimeInterval = 60.0
    
    /// Whether initial bulk upload has been completed
    var hasCompletedInitialSync: Bool {
        get { UserDefaults.standard.bool(forKey: "SyncManager_initialSyncComplete") }
        set { UserDefaults.standard.set(newValue, forKey: "SyncManager_initialSyncComplete") }
    }
    
    // MARK: - Init
    
    private init() {
        startFlushTimer()
    }
    
    // MARK: - Public API
    
    /// Queue a sync operation for async cloud push.
    /// Call this after every local SwiftData write.
    func queue(_ operation: SyncOperation) {
        // Deduplicate: if same type + key already in queue, replace it
        if let existingIndex = syncQueue.firstIndex(where: {
            $0.type == operation.type && $0.key == operation.key
        }) {
            syncQueue[existingIndex] = operation
        } else {
            syncQueue.append(operation)
        }
        pendingCount = syncQueue.count
    }
    
    /// Queue a character data sync (most common operation).
    func queueCharacterSync(_ character: PlayerCharacter) {
        queue(SyncOperation(
            type: .characterData,
            key: character.id.uuidString,
            timestamp: Date(),
            payload: .character(character.toSnapshot())
        ))
    }
    
    /// Queue an achievement sync.
    func queueAchievementSync(_ achievement: Achievement, playerID: UUID) {
        queue(SyncOperation(
            type: .achievement,
            key: "\(playerID.uuidString)_\(achievement.trackingKey)",
            timestamp: Date(),
            payload: .achievement(AchievementSyncData(
                playerID: playerID,
                trackingKey: achievement.trackingKey,
                name: achievement.name,
                description: achievement.achievementDescription,
                icon: achievement.icon,
                targetValue: achievement.targetValue,
                currentValue: achievement.currentValue,
                isUnlocked: achievement.isUnlocked,
                unlockedAt: achievement.unlockedAt,
                rewardType: achievement.rewardType.rawValue,
                rewardAmount: achievement.rewardAmount
            ))
        ))
    }
    
    /// Queue a task sync.
    func queueTaskSync(_ task: GameTask, playerID: UUID) {
        queue(SyncOperation(
            type: .task,
            key: "\(playerID.uuidString)_\(task.id.uuidString)",
            timestamp: Date(),
            payload: .task(TaskSyncData(
                playerID: playerID,
                localID: task.id,
                title: task.title,
                description: task.taskDescription,
                category: task.category.rawValue,
                status: task.status.rawValue,
                isHabit: task.isHabit,
                isRecurring: task.isRecurring,
                recurrencePattern: task.recurrencePattern?.rawValue,
                habitStreak: task.habitStreak,
                habitLongestStreak: task.habitLongestStreak,
                isFromPartner: task.isFromPartner,
                assignedTo: task.assignedTo,
                createdBy: task.createdBy,
                verificationType: task.verificationType.rawValue,
                isVerified: task.isVerified,
                dueDate: task.dueDate,
                completedAt: task.completedAt,
                goalID: task.goalID,
                customEXP: task.customEXP
            ))
        ))
    }
    
    /// Queue a goal sync.
    func queueGoalSync(_ goal: Goal, playerID: UUID) {
        queue(SyncOperation(
            type: .goal,
            key: "\(playerID.uuidString)_\(goal.id.uuidString)",
            timestamp: Date(),
            payload: .goal(GoalSyncData(
                playerID: playerID,
                localID: goal.id,
                title: goal.title,
                description: goal.goalDescription,
                category: goal.category.rawValue,
                status: goal.status.rawValue,
                targetDate: goal.targetDate,
                milestone25Claimed: goal.milestone25Claimed,
                milestone50Claimed: goal.milestone50Claimed,
                milestone75Claimed: goal.milestone75Claimed,
                milestone100Claimed: goal.milestone100Claimed,
                completedAt: goal.completedAt
            ))
        ))
    }
    
    /// Queue a mood entry sync.
    func queueMoodSync(_ entry: MoodEntry, playerID: UUID) {
        queue(SyncOperation(
            type: .moodEntry,
            key: "\(playerID.uuidString)_\(entry.id.uuidString)",
            timestamp: Date(),
            payload: .mood(MoodSyncData(
                playerID: playerID,
                localID: entry.id,
                moodLevel: entry.moodLevel,
                journalText: entry.journalText,
                date: entry.date
            ))
        ))
    }
    
    /// Queue a card collection sync.
    func queueCardSync(cardID: String, playerID: UUID) {
        queue(SyncOperation(
            type: .cardCollection,
            key: "\(playerID.uuidString)_\(cardID)",
            timestamp: Date(),
            payload: .cardCollection(CardSyncData(
                playerID: playerID,
                cardID: cardID
            ))
        ))
    }
    
    /// Queue a daily state sync.
    func queueDailyStateSync(_ character: PlayerCharacter) {
        guard let userID = SupabaseService.shared.currentUserID else { return }
        queue(SyncOperation(
            type: .dailyState,
            key: userID.uuidString,
            timestamp: Date(),
            payload: .dailyState(DailyStateSyncData(
                playerID: userID,
                tasksCompletedToday: character.tasksCompletedToday,
                dutiesCompletedToday: character.dutiesCompletedToday,
                arenaAttemptsToday: character.arenaAttemptsToday,
                lastDailyReset: character.lastDailyReset,
                lastActiveAt: character.lastActiveAt,
                lastMeditationDate: character.lastMeditationDate,
                lastMoodDate: character.lastMoodDate,
                lastArenaDate: character.lastArenaDate,
                currentStreak: character.currentStreak,
                longestStreak: character.longestStreak,
                moodStreak: character.moodStreak,
                meditationStreak: character.meditationStreak
            ))
        ))
    }
    
    /// Flush all queued operations to the cloud immediately.
    /// Called on timer, on app background, and manually after critical operations.
    func flush() async {
        guard !syncQueue.isEmpty else { return }
        guard SupabaseService.shared.isAuthenticated else { return }
        
        isSyncing = true
        let operations = syncQueue
        syncQueue.removeAll()
        pendingCount = 0
        
        var failedOps: [SyncOperation] = []
        
        for operation in operations {
            do {
                try await execute(operation)
            } catch {
                print("⚠️ SyncManager: Failed to sync \(operation.type.rawValue) [\(operation.key.prefix(8))]: \(error.localizedDescription)")
                failedOps.append(operation)
            }
        }
        
        if failedOps.isEmpty {
            // All succeeded — reset failure state
            consecutiveFailures = 0
            backoffDelay = 1.0
            hasSyncIssue = false
        } else {
            // Re-queue failed operations
            syncQueue.append(contentsOf: failedOps)
            pendingCount = syncQueue.count
            consecutiveFailures += 1
            
            if consecutiveFailures >= maxConsecutiveFailures {
                hasSyncIssue = true
            }
            
            // Exponential backoff for retries
            backoffDelay = min(backoffDelay * 2, maxBackoffDelay)
            
            // Schedule retry
            Task {
                try? await Task.sleep(for: .seconds(backoffDelay))
                await flush()
            }
        }
        
        isSyncing = false
    }
    
    /// Perform the initial bulk upload of all local data to cloud.
    /// Shows a one-time "Backing up your progress..." screen.
    func performInitialSync(
        character: PlayerCharacter,
        tasks: [GameTask],
        goals: [Goal],
        moodEntries: [MoodEntry],
        bonds: [Bond]
    ) async {
        guard let userID = SupabaseService.shared.currentUserID else { return }
        
        isSyncing = true
        
        do {
            // 1. Sync comprehensive character snapshot
            try await SupabaseService.shared.syncCharacterData(character)
            
            // 2. Sync daily state
            try await SupabaseService.shared.syncDailyState(character)
            
            // 3. Sync all achievements
            for achievement in character.achievements {
                try await SupabaseService.shared.syncAchievement(
                    AchievementSyncData(
                        playerID: userID,
                        trackingKey: achievement.trackingKey,
                        name: achievement.name,
                        description: achievement.achievementDescription,
                        icon: achievement.icon,
                        targetValue: achievement.targetValue,
                        currentValue: achievement.currentValue,
                        isUnlocked: achievement.isUnlocked,
                        unlockedAt: achievement.unlockedAt,
                        rewardType: achievement.rewardType.rawValue,
                        rewardAmount: achievement.rewardAmount
                    )
                )
            }
            
            // 4. Sync all tasks
            for task in tasks {
                try await SupabaseService.shared.syncTask(
                    TaskSyncData(
                        playerID: userID,
                        localID: task.id,
                        title: task.title,
                        description: task.taskDescription,
                        category: task.category.rawValue,
                        status: task.status.rawValue,
                        isHabit: task.isHabit,
                        isRecurring: task.isRecurring,
                        recurrencePattern: task.recurrencePattern?.rawValue,
                        habitStreak: task.habitStreak,
                        habitLongestStreak: task.habitLongestStreak,
                        isFromPartner: task.isFromPartner,
                        assignedTo: task.assignedTo,
                        createdBy: task.createdBy,
                        verificationType: task.verificationType.rawValue,
                        isVerified: task.isVerified,
                        dueDate: task.dueDate,
                        completedAt: task.completedAt,
                        goalID: task.goalID,
                        customEXP: task.customEXP
                    )
                )
            }
            
            // 5. Sync all goals
            for goal in goals {
                try await SupabaseService.shared.syncGoal(
                    GoalSyncData(
                        playerID: userID,
                        localID: goal.id,
                        title: goal.title,
                        description: goal.goalDescription,
                        category: goal.category.rawValue,
                        status: goal.status.rawValue,
                        targetDate: goal.targetDate,
                        milestone25Claimed: goal.milestone25Claimed,
                        milestone50Claimed: goal.milestone50Claimed,
                        milestone75Claimed: goal.milestone75Claimed,
                        milestone100Claimed: goal.milestone100Claimed,
                        completedAt: goal.completedAt
                    )
                )
            }
            
            // 6. Sync all mood entries
            for entry in moodEntries {
                try await SupabaseService.shared.syncMoodEntry(
                    MoodSyncData(
                        playerID: userID,
                        localID: entry.id,
                        moodLevel: entry.moodLevel,
                        journalText: entry.journalText,
                        date: entry.date
                    )
                )
            }
            
            // 7. Sync bond data to parties table
            if let bond = bonds.first {
                try await SupabaseService.shared.syncBondToParty(bond, playerID: userID)
            }
            
            hasCompletedInitialSync = true
            print("✅ SyncManager: Initial bulk upload complete")
            
        } catch {
            print("❌ SyncManager: Initial sync failed: \(error.localizedDescription)")
            // Don't mark as complete — will retry next launch
        }
        
        isSyncing = false
    }
    
    /// Pull data from cloud and merge with local SwiftData on app launch.
    func pullAndMerge(context: ModelContext) async {
        guard SupabaseService.shared.isAuthenticated else { return }
        guard let userID = SupabaseService.shared.currentUserID else { return }
        
        do {
            // 1. Pull character snapshot
            if let snapshot = try await SupabaseService.shared.fetchCharacterData() {
                let descriptor = FetchDescriptor<PlayerCharacter>()
                let localCharacters = (try? context.fetch(descriptor)) ?? []
                
                if let localChar = localCharacters.first {
                    // Merge: cloud wins if it has a more recent timestamp
                    // For now, cloud data supplements local (local is always fresher for active player)
                    // Only restore from cloud if local is empty/default
                    if localChar.level <= 1 && localChar.tasksCompleted == 0 {
                        // Local is fresh install — restore from cloud
                        mergeSnapshotIntoCharacter(snapshot, character: localChar)
                        print("✅ SyncManager: Restored character from cloud snapshot")
                    }
                } else {
                    // No local character — create from cloud
                    let restoredChar = PlayerCharacter.fromSnapshot(snapshot)
                    restoredChar.supabaseUserID = userID.uuidString
                    context.insert(restoredChar)
                    AchievementTracker.initializeAchievements(for: restoredChar)
                    
                    // Pull achievements from cloud
                    let cloudAchievements = try await SupabaseService.shared.fetchAchievements()
                    for cloudAch in cloudAchievements {
                        if let localAch = restoredChar.achievements.first(where: { $0.trackingKey == cloudAch.trackingKey }) {
                            localAch.currentValue = max(localAch.currentValue, cloudAch.currentValue)
                            if cloudAch.isUnlocked {
                                localAch.isUnlocked = true
                                localAch.unlockedAt = cloudAch.unlockedAt
                            }
                        }
                    }
                    
                    try? context.save()
                    print("✅ SyncManager: Created character from cloud data")
                }
            }
            
            // 2. Pull daily state
            if let dailyState = try await SupabaseService.shared.fetchDailyState() {
                let descriptor = FetchDescriptor<PlayerCharacter>()
                let localCharacters = (try? context.fetch(descriptor)) ?? []
                if let localChar = localCharacters.first {
                    // Only merge if cloud is more recent
                    if dailyState.lastActiveAt ?? Date.distantPast > localChar.lastActiveAt {
                        localChar.currentStreak = max(localChar.currentStreak, dailyState.currentStreak)
                        localChar.longestStreak = max(localChar.longestStreak, dailyState.longestStreak)
                        localChar.moodStreak = max(localChar.moodStreak, dailyState.moodStreak)
                        localChar.meditationStreak = max(localChar.meditationStreak, dailyState.meditationStreak)
                    }
                }
            }
            
        } catch {
            print("⚠️ SyncManager: Pull & merge failed: \(error.localizedDescription)")
        }
    }
    
    /// Export all player data as a JSON dictionary for data export.
    func exportAllData(
        character: PlayerCharacter,
        tasks: [GameTask],
        goals: [Goal],
        moodEntries: [MoodEntry]
    ) -> Data? {
        let export = DataExport(
            exportDate: Date(),
            character: CharacterExport(
                name: character.name,
                level: character.level,
                characterClass: character.characterClass?.rawValue,
                gold: character.gold,
                gems: character.gems,
                tasksCompleted: character.tasksCompleted,
                currentStreak: character.currentStreak,
                longestStreak: character.longestStreak,
                createdAt: character.createdAt
            ),
            achievements: character.achievements.map { ach in
                AchievementExport(
                    name: ach.name,
                    description: ach.achievementDescription,
                    isUnlocked: ach.isUnlocked,
                    unlockedAt: ach.unlockedAt,
                    progress: "\(ach.currentValue)/\(ach.targetValue)"
                )
            },
            tasks: tasks.map { task in
                TaskExport(
                    title: task.title,
                    category: task.category.rawValue,
                    status: task.status.rawValue,
                    isHabit: task.isHabit,
                    habitStreak: task.habitStreak,
                    createdAt: task.createdAt,
                    completedAt: task.completedAt
                )
            },
            goals: goals.map { goal in
                GoalExport(
                    title: goal.title,
                    category: goal.category.rawValue,
                    status: goal.status.rawValue,
                    createdAt: goal.createdAt,
                    completedAt: goal.completedAt
                )
            },
            moodEntries: moodEntries.map { entry in
                MoodExport(
                    date: entry.date,
                    moodLevel: entry.moodLevel,
                    journal: entry.journalText
                )
            }
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(export)
    }
    
    // MARK: - Private Methods
    
    private func startFlushTimer() {
        flushTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.flush()
            }
        }
    }
    
    /// Execute a single sync operation against Supabase.
    private func execute(_ operation: SyncOperation) async throws {
        switch operation.payload {
        case .character(let snapshot):
            // Build a temporary PlayerCharacter-like object to call syncCharacterData
            // We pass the snapshot directly through a new method
            try await SupabaseService.shared.syncCharacterSnapshot(snapshot)
            
        case .achievement(let data):
            try await SupabaseService.shared.syncAchievement(data)
            
        case .task(let data):
            try await SupabaseService.shared.syncTask(data)
            
        case .goal(let data):
            try await SupabaseService.shared.syncGoal(data)
            
        case .mood(let data):
            try await SupabaseService.shared.syncMoodEntry(data)
            
        case .dailyState(let data):
            try await SupabaseService.shared.syncDailyStateData(data)
            
        case .arenaRun(let data):
            try await SupabaseService.shared.syncArenaRun(data)
            
        case .dungeonRun(let data):
            try await SupabaseService.shared.syncDungeonRun(data)
            
        case .missionHistory(let data):
            try await SupabaseService.shared.syncMissionHistory(data)
        case .cardCollection(let data):
            try await SupabaseService.shared.syncPlayerCard(cardID: data.cardID)
        }
    }
    
    /// Merge a cloud snapshot into an existing local character (last-write-wins per field).
    private func mergeSnapshotIntoCharacter(_ snapshot: CharacterSnapshot, character: PlayerCharacter) {
        // Cloud wins for progression values (take the higher value)
        character.level = max(character.level, snapshot.level)
        character.currentEXP = max(character.currentEXP, snapshot.currentEXP)
        character.gold = max(character.gold, snapshot.gold)
        character.gems = max(character.gems, snapshot.gems)
        character.forgeShards = max(character.forgeShards, snapshot.forgeShards)
        character.tasksCompleted = max(character.tasksCompleted, snapshot.tasksCompleted)
        character.currentStreak = max(character.currentStreak, snapshot.currentStreak)
        character.longestStreak = max(character.longestStreak, snapshot.longestStreak)
        character.unspentStatPoints = max(character.unspentStatPoints, snapshot.unspentStatPoints)
        character.moodStreak = max(character.moodStreak, snapshot.moodStreak)
        character.meditationStreak = max(character.meditationStreak, snapshot.meditationStreak)
        character.arenaBestWave = max(character.arenaBestWave, snapshot.arenaBestWave)
        
        // Stats: take higher values
        character.stats.strength = max(character.stats.strength, snapshot.strength)
        character.stats.wisdom = max(character.stats.wisdom, snapshot.wisdom)
        character.stats.charisma = max(character.stats.charisma, snapshot.charisma)
        character.stats.dexterity = max(character.stats.dexterity, snapshot.dexterity)
        character.stats.luck = max(character.stats.luck, snapshot.luck)
        character.stats.defense = max(character.stats.defense, snapshot.defense)
        
        // Identity: cloud wins
        if let cls = snapshot.characterClass {
            character.characterClass = CharacterClass(rawValue: cls)
        }
        if let zodiac = snapshot.zodiacSign {
            character.zodiacSign = ZodiacSign(rawValue: zodiac)
        }
        character.avatarIcon = snapshot.avatarIcon
        character.avatarFrame = snapshot.avatarFrame
        
        // Extended fields from comprehensive snapshot
        if let tasksToday = snapshot.tasksCompletedToday {
            character.tasksCompletedToday = tasksToday
        }
        if let dutiesToday = snapshot.dutiesCompletedToday {
            character.dutiesCompletedToday = dutiesToday
        }
        if let arenaAttempts = snapshot.arenaAttemptsToday {
            character.arenaAttemptsToday = arenaAttempts
        }
        if let lastReset = snapshot.lastDailyReset {
            character.lastDailyReset = lastReset
        }
        if let lastActive = snapshot.lastActiveAt {
            character.lastActiveAt = lastActive
        }
        if let lastMed = snapshot.lastMeditationDate {
            character.lastMeditationDate = lastMed
        }
        if let lastMood = snapshot.lastMoodDate {
            character.lastMoodDate = lastMood
        }
        if let lastArena = snapshot.lastArenaDate {
            character.lastArenaDate = lastArena
        }
    }
    
    deinit {
        flushTimer?.invalidate()
    }
}

// MARK: - Sync Operation Model

/// A queued sync operation waiting to be flushed to the cloud.
struct SyncOperation {
    let type: SyncOperationType
    let key: String
    let timestamp: Date
    let payload: SyncPayload
}

enum SyncOperationType: String {
    case characterData
    case achievement
    case task
    case goal
    case moodEntry
    case dailyState
    case arenaRun
    case dungeonRun
    case missionHistory
    case cardCollection
}

enum SyncPayload {
    case character(CharacterSnapshot)
    case achievement(AchievementSyncData)
    case task(TaskSyncData)
    case goal(GoalSyncData)
    case mood(MoodSyncData)
    case dailyState(DailyStateSyncData)
    case arenaRun(ArenaRunSyncData)
    case dungeonRun(DungeonRunSyncData)
    case missionHistory(MissionHistorySyncData)
    case cardCollection(CardSyncData)
}

// MARK: - Sync Data Models

struct AchievementSyncData: Encodable {
    let playerID: UUID
    let trackingKey: String
    let name: String
    let description: String
    let icon: String
    let targetValue: Int
    let currentValue: Int
    let isUnlocked: Bool
    let unlockedAt: Date?
    let rewardType: String
    let rewardAmount: Int
    
    enum CodingKeys: String, CodingKey {
        case playerID = "player_id"
        case trackingKey = "tracking_key"
        case name, description, icon
        case targetValue = "target_value"
        case currentValue = "current_value"
        case isUnlocked = "is_unlocked"
        case unlockedAt = "unlocked_at"
        case rewardType = "reward_type"
        case rewardAmount = "reward_amount"
    }
}

struct TaskSyncData: Encodable {
    let playerID: UUID
    let localID: UUID
    let title: String
    let description: String?
    let category: String
    let status: String
    let isHabit: Bool
    let isRecurring: Bool
    let recurrencePattern: String?
    let habitStreak: Int
    let habitLongestStreak: Int
    let isFromPartner: Bool
    let assignedTo: UUID?
    let createdBy: UUID
    let verificationType: String
    let isVerified: Bool
    let dueDate: Date?
    let completedAt: Date?
    let goalID: UUID?
    let customEXP: Int?
    
    enum CodingKeys: String, CodingKey {
        case playerID = "player_id"
        case localID = "local_id"
        case title, description, category, status
        case isHabit = "is_habit"
        case isRecurring = "is_recurring"
        case recurrencePattern = "recurrence_pattern"
        case habitStreak = "habit_streak"
        case habitLongestStreak = "habit_longest_streak"
        case isFromPartner = "is_from_partner"
        case assignedTo = "assigned_to"
        case createdBy = "created_by"
        case verificationType = "verification_type"
        case isVerified = "is_verified"
        case dueDate = "due_date"
        case completedAt = "completed_at"
        case goalID = "goal_id"
        case customEXP = "custom_exp"
    }
}

struct GoalSyncData: Encodable {
    let playerID: UUID
    let localID: UUID
    let title: String
    let description: String?
    let category: String
    let status: String
    let targetDate: Date?
    let milestone25Claimed: Bool
    let milestone50Claimed: Bool
    let milestone75Claimed: Bool
    let milestone100Claimed: Bool
    let completedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case playerID = "player_id"
        case localID = "local_id"
        case title, description, category, status
        case targetDate = "target_date"
        case milestone25Claimed = "milestone_25_claimed"
        case milestone50Claimed = "milestone_50_claimed"
        case milestone75Claimed = "milestone_75_claimed"
        case milestone100Claimed = "milestone_100_claimed"
        case completedAt = "completed_at"
    }
}

struct MoodSyncData: Encodable {
    let playerID: UUID
    let localID: UUID
    let moodLevel: Int
    let journalText: String?
    let date: Date
    
    enum CodingKeys: String, CodingKey {
        case playerID = "player_id"
        case localID = "local_id"
        case moodLevel = "mood_level"
        case journalText = "journal_text"
        case date
    }
}

struct DailyStateSyncData: Encodable {
    let playerID: UUID
    let tasksCompletedToday: Int
    let dutiesCompletedToday: Int
    let arenaAttemptsToday: Int
    let lastDailyReset: Date
    let lastActiveAt: Date
    let lastMeditationDate: Date?
    let lastMoodDate: Date?
    let lastArenaDate: Date?
    let currentStreak: Int
    let longestStreak: Int
    let moodStreak: Int
    let meditationStreak: Int
    
    enum CodingKeys: String, CodingKey {
        case playerID = "player_id"
        case tasksCompletedToday = "tasks_completed_today"
        case dutiesCompletedToday = "duties_completed_today"
        case arenaAttemptsToday = "arena_attempts_today"
        case lastDailyReset = "last_daily_reset"
        case lastActiveAt = "last_active_at"
        case lastMeditationDate = "last_meditation_date"
        case lastMoodDate = "last_mood_date"
        case lastArenaDate = "last_arena_date"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case moodStreak = "mood_streak"
        case meditationStreak = "meditation_streak"
    }
}

struct ArenaRunSyncData: Encodable {
    let playerID: UUID
    let bestWave: Int
    let wavesCleared: Int
    let score: Int
    let characterLevel: Int
    let characterClass: String?
    
    enum CodingKeys: String, CodingKey {
        case playerID = "player_id"
        case bestWave = "best_wave"
        case wavesCleared = "waves_cleared"
        case score
        case characterLevel = "character_level"
        case characterClass = "character_class"
    }
}

struct DungeonRunSyncData: Encodable {
    let playerID: UUID
    let dungeonName: String
    let difficulty: String
    let roomsCleared: Int
    let totalRooms: Int
    let wasSuccessful: Bool
    let expEarned: Int
    let goldEarned: Int
    let characterLevel: Int
    let characterClass: String?
    
    enum CodingKeys: String, CodingKey {
        case playerID = "player_id"
        case dungeonName = "dungeon_name"
        case difficulty
        case roomsCleared = "rooms_cleared"
        case totalRooms = "total_rooms"
        case wasSuccessful = "was_successful"
        case expEarned = "exp_earned"
        case goldEarned = "gold_earned"
        case characterLevel = "character_level"
        case characterClass = "character_class"
    }
}

struct MissionHistorySyncData: Encodable {
    let playerID: UUID
    let missionName: String
    let missionType: String
    let rarity: String
    let wasSuccessful: Bool
    let durationSeconds: Int
    let expEarned: Int
    let goldEarned: Int
    let characterLevel: Int
    
    enum CodingKeys: String, CodingKey {
        case playerID = "player_id"
        case missionName = "mission_name"
        case missionType = "mission_type"
        case rarity
        case wasSuccessful = "was_successful"
        case durationSeconds = "duration_seconds"
        case expEarned = "exp_earned"
        case goldEarned = "gold_earned"
        case characterLevel = "character_level"
    }
}

struct CardSyncData: Encodable {
    let playerID: UUID
    let cardID: String
    
    enum CodingKeys: String, CodingKey {
        case playerID = "owner_id"
        case cardID = "card_id"
    }
}

// MARK: - Data Export Models

struct DataExport: Encodable {
    let exportDate: Date
    let character: CharacterExport
    let achievements: [AchievementExport]
    let tasks: [TaskExport]
    let goals: [GoalExport]
    let moodEntries: [MoodExport]
}

struct CharacterExport: Encodable {
    let name: String
    let level: Int
    let characterClass: String?
    let gold: Int
    let gems: Int
    let tasksCompleted: Int
    let currentStreak: Int
    let longestStreak: Int
    let createdAt: Date
}

struct AchievementExport: Encodable {
    let name: String
    let description: String
    let isUnlocked: Bool
    let unlockedAt: Date?
    let progress: String
}

struct TaskExport: Encodable {
    let title: String
    let category: String
    let status: String
    let isHabit: Bool
    let habitStreak: Int
    let createdAt: Date
    let completedAt: Date?
}

struct GoalExport: Encodable {
    let title: String
    let category: String
    let status: String
    let createdAt: Date
    let completedAt: Date?
}

struct MoodExport: Encodable {
    let date: Date
    let moodLevel: Int
    let journal: String?
}

// MARK: - Cloud Achievement DTO (for pull)

struct CloudAchievement: Codable {
    let trackingKey: String
    let currentValue: Int
    let isUnlocked: Bool
    let unlockedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case trackingKey = "tracking_key"
        case currentValue = "current_value"
        case isUnlocked = "is_unlocked"
        case unlockedAt = "unlocked_at"
    }
}

struct CloudDailyState: Codable {
    let tasksCompletedToday: Int
    let dutiesCompletedToday: Int
    let arenaAttemptsToday: Int
    let lastActiveAt: Date?
    let currentStreak: Int
    let longestStreak: Int
    let moodStreak: Int
    let meditationStreak: Int
    
    enum CodingKeys: String, CodingKey {
        case tasksCompletedToday = "tasks_completed_today"
        case dutiesCompletedToday = "duties_completed_today"
        case arenaAttemptsToday = "arena_attempts_today"
        case lastActiveAt = "last_active_at"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case moodStreak = "mood_streak"
        case meditationStreak = "meditation_streak"
    }
}
