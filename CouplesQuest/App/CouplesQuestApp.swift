import SwiftUI
import SwiftData
import OneSignalFramework
import Supabase

// MARK: - AppDelegate for OneSignal Initialization + Notification Tap Handling
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Read the OneSignal App ID from Info.plist (set via Secrets.xcconfig)
        let appId = Bundle.main.object(forInfoDictionaryKey: "OneSignalAppId") as? String ?? ""
        
        // Initialize OneSignal with verbose logging for debug builds
        #if DEBUG
        OneSignal.Debug.setLogLevel(.LL_VERBOSE)
        #endif
        
        OneSignal.initialize(appId, withLaunchOptions: launchOptions)
        
        // Request push permission (will show the system prompt once)
        OneSignal.Notifications.requestPermission({ accepted in
            print("📬 Push permission accepted: \(accepted)")
        }, fallbackToSettings: true)
        
        // Set ourselves as the notification center delegate to handle taps
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // OneSignal handles this automatically, but we keep the callback for completeness
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    /// Called when the user taps a notification (app was in background or terminated)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        if let deepLink = userInfo[PushNotificationService.deepLinkKey] as? String {
            let destination: DeepLinkDestination? = {
                switch deepLink {
                case "characterLevelUp": return .characterLevelUp
                case "dungeons": return .dungeons
                case "training": return .training
                case "expeditions": return .expeditions
                case "home": return .home
                case "tasks": return .tasks
                case "party": return .party
                default: return nil
                }
            }()
            
            if let destination {
                // Small delay to ensure the app UI is ready before navigating
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    DeepLinkRouter.shared.pendingDestination = destination
                }
            }
        }
        
        completionHandler()
    }
    
    /// Called when a notification arrives while the app is in the foreground.
    /// Show it as a banner so the user can tap it.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}

@main
struct SwordsAndChoresApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let modelContainer: ModelContainer
    
    init() {
        let schema = Schema([
            PlayerCharacter.self,
            Stats.self,
            EquipmentLoadout.self,
            GameTask.self,
            AFKMission.self,
            ActiveMission.self,
            Equipment.self,
            Achievement.self,
            Dungeon.self,
            DungeonRun.self,
            DailyQuest.self,
            Bond.self,
            PartnerInteraction.self,
            WeeklyRaidBoss.self,
            ArenaRun.self,
            CraftingMaterial.self,
            Consumable.self,
            MoodEntry.self,
            Goal.self,
            MonsterCard.self,
            PartyChallenge.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            // Schema migration failed — delete old store and retry
            // This only happens during development when model fields change
            print("⚠️ ModelContainer failed, resetting database: \(error)")
            let url = modelConfiguration.url
            let fileManager = FileManager.default
            let storePath = url.path(percentEncoded: false)
            
            // Clear any UserDefaults-persisted state that references old models
            // (e.g. ActiveMission timer from a now-deleted character)
            ActiveMission.clearPersisted()
            
            // Remove the main store file and all related side-car files
            for suffix in ["", "-shm", "-wal"] {
                let filePath = storePath + suffix
                if fileManager.fileExists(atPath: filePath) {
                    try? fileManager.removeItem(atPath: filePath)
                }
            }
            
            // Also remove the containing directory's .store files if present
            let storeDir = url.deletingLastPathComponent()
            if let contents = try? fileManager.contentsOfDirectory(
                at: storeDir,
                includingPropertiesForKeys: nil
            ) {
                for file in contents where file.lastPathComponent.contains("default.store") {
                    try? fileManager.removeItem(at: file)
                }
            }
            
            do {
                modelContainer = try ModelContainer(
                    for: schema,
                    configurations: [modelConfiguration]
                )
            } catch {
                fatalError("Could not initialize ModelContainer after reset: \(error)")
            }
        }
    }
    
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var gameEngine = GameEngine()
    
    /// Realtime channels for partner sync (kept alive while app is open)
    @State private var partnerTaskChannel: RealtimeChannelV2?
    @State private var partnerProfileChannel: RealtimeChannelV2?
    
    var body: some Scene {
        WindowGroup {
            AuthGateView()
                .environmentObject(gameEngine)
                .preferredColorScheme(.dark)
                .onAppear {
                    // Daily reset notification removed — it's noise, not useful (§21)
                    PushNotificationService.shared.cancelDailyReset()
                    
                    // Load server-driven content (public read — no auth required)
                    Task {
                        await ContentManager.shared.loadContent()
                    }
                }
        }
        .modelContainer(modelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                onAppBecameActive()
            case .background, .inactive:
                syncCharacterToCloud()
            @unknown default:
                break
            }
        }
    }
    
    /// Called when the app returns to the foreground.
    /// Cancels re-engagement notifications, fetches incoming partner tasks,
    /// refreshes partner data, and triggers cloud sync.
    private func onAppBecameActive() {
        // Cancel any pending re-engagement notifications — user is back!
        PushNotificationService.shared.cancelReengagementNotifications()
        
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<PlayerCharacter>()
        guard let character = try? context.fetch(descriptor).first else { return }
        guard SupabaseService.shared.isAuthenticated else { return }
        
        // NOTE: Do NOT update lastActiveAt here — it must stay as the last
        // streak-checked date so updateStreak() can detect day boundaries.
        // updateStreak() sets lastActiveAt after the streak logic runs.
        
        Task {
            // 0. Pull from cloud and merge with local on launch
            await SyncManager.shared.pullAndMerge(context: context)
            
            // 0.5. One-time bulk upload for existing users who haven't synced yet
            if !SyncManager.shared.hasCompletedInitialSync {
                let taskDescriptor = FetchDescriptor<GameTask>()
                let goalDescriptor = FetchDescriptor<Goal>()
                let moodDescriptor = FetchDescriptor<MoodEntry>()
                let bondDescriptor = FetchDescriptor<Bond>()
                
                let tasks = (try? context.fetch(taskDescriptor)) ?? []
                let goals = (try? context.fetch(goalDescriptor)) ?? []
                let moods = (try? context.fetch(moodDescriptor)) ?? []
                let bonds = (try? context.fetch(bondDescriptor)) ?? []
                
                await SyncManager.shared.performInitialSync(
                    character: character,
                    tasks: tasks,
                    goals: goals,
                    moodEntries: moods,
                    bonds: bonds
                )
            }
            
            // 1. Re-fetch own profile to detect partner_id changes (e.g. accepted request)
            await SupabaseService.shared.fetchProfile()
            if !character.hasPartner, let partnerID = SupabaseService.shared.currentProfile?.partnerID {
                // Our request was accepted while app was in background — link locally
                if let partnerProfile = try? await SupabaseService.shared.fetchProfile(byID: partnerID) {
                    let pairingData = PairingData(
                        characterID: partnerID.uuidString,
                        name: partnerProfile.characterName ?? "Adventurer",
                        level: partnerProfile.level ?? 1,
                        characterClass: partnerProfile.characterClass,
                        partyID: nil,
                        avatarName: partnerProfile.avatarName
                    )
                    character.linkPartner(data: pairingData)
                    
                    let bondDescriptor = FetchDescriptor<Bond>()
                    let bonds = (try? context.fetch(bondDescriptor)) ?? []
                    if bonds.isEmpty {
                        let newBond = Bond(memberIDs: [character.id, partnerID])
                        context.insert(newBond)
                    } else if let existingBond = bonds.first {
                        existingBond.addMember(partnerID)
                    }
                    try? context.save()
                    print("✅ Partner linked on app foreground (partner: \(partnerProfile.characterName ?? "unknown"))")
                }
            }
            
            // 2. Fetch incoming partner tasks from cloud → create local GameTasks
            await gameEngine.fetchIncomingPartnerTasks(context: context)
            
            // 3. Refresh cached partner profile data (level, stats, class)
            await gameEngine.refreshPartnerData(character: character)
            
            // 4. Set up Realtime subscriptions if not already active
            await setupRealtimeSubscriptions(context: context)
        }
    }
    
    /// Set up Realtime subscriptions for instant partner task delivery and profile updates.
    private func setupRealtimeSubscriptions(context: ModelContext) async {
        // Only set up if not already subscribed
        if partnerTaskChannel == nil {
            partnerTaskChannel = await SupabaseService.shared.subscribeToPartnerTasks { cloudTask in
                // Check for duplicates before inserting
                let descriptor = FetchDescriptor<GameTask>()
                let localTasks = (try? context.fetch(descriptor)) ?? []
                let existingCloudIDs = Set(localTasks.compactMap { $0.cloudID })
                
                let cloudIDString = cloudTask.id.uuidString
                guard !existingCloudIDs.contains(cloudIDString) else { return }
                
                let localTask = GameEngine.createLocalTask(from: cloudTask)
                context.insert(localTask)
                try? context.save()
                print("📡 Realtime: Received partner task '\(cloudTask.title)'")
            }
        }
        
        if partnerProfileChannel == nil {
            let descriptor = FetchDescriptor<PlayerCharacter>()
            guard let character = try? context.fetch(descriptor).first else { return }
            
            partnerProfileChannel = await SupabaseService.shared.subscribeToPartnerProfile { profile in
                character.partnerName = profile.characterName
                    ?? profile.email?.components(separatedBy: "@").first
                    ?? "Partner"
                character.partnerLevel = profile.level
                character.partnerClassName = profile.characterClass
                
                if let snapshot = profile.characterData {
                    let total = snapshot.strength + snapshot.wisdom + snapshot.charisma +
                                snapshot.dexterity + snapshot.luck + snapshot.defense
                    character.partnerStatTotal = total
                }
                print("📡 Realtime: Partner profile updated — \(profile.characterName ?? "?") Lv.\(profile.level ?? 0)")
            }
        }
    }
    
    /// Sync the local character to the cloud when the app goes to background.
    /// Wraps async work in a UIKit background task so iOS grants ~30 seconds
    /// of execution time instead of suspending the process immediately.
    private func syncCharacterToCloud() {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<PlayerCharacter>()
        guard let character = try? context.fetch(descriptor).first else {
            print("⚠️ syncCharacterToCloud: No local character found")
            return
        }
        guard SupabaseService.shared.isAuthenticated else {
            print("⚠️ syncCharacterToCloud: Not authenticated, skipping sync")
            return
        }
        
        // Schedule re-engagement notifications (will fire if user doesn't come back)
        PushNotificationService.shared.scheduleReengagementNotifications(
            characterName: character.name,
            notificationsSentThisLapse: character.reengagementNotificationsSent
        )
        
        // Request background execution time from iOS (~30 seconds)
        var bgTaskID: UIBackgroundTaskIdentifier = .invalid
        bgTaskID = UIApplication.shared.beginBackgroundTask(withName: "CloudSync") {
            // Expiration handler — clean up if we run out of time
            print("⚠️ Background sync time expired")
            UIApplication.shared.endBackgroundTask(bgTaskID)
            bgTaskID = .invalid
        }
        
        // Guard against failure to start background task
        guard bgTaskID != .invalid else {
            print("⚠️ Could not start background task for cloud sync")
            return
        }
        
        Task {
            defer {
                UIApplication.shared.endBackgroundTask(bgTaskID)
                bgTaskID = .invalid
            }
            
            // 1. Flush the SyncManager queue (achievements, tasks, goals, mood, etc.)
            await SyncManager.shared.flush()
            
            // 2. Comprehensive character data sync
            do {
                try await SupabaseService.shared.syncCharacterData(character)
                try await SupabaseService.shared.syncDailyState(character)
                character.lastSyncTimestamp = Date()
                print("✅ Character synced to cloud: \(character.name) Lv.\(character.level)")
            } catch {
                print("❌ Failed to sync character to cloud: \(error)")
            }
        }
    }
}

