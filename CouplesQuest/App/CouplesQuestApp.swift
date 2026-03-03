import SwiftUI
import SwiftData
import OneSignalFramework
import Supabase
import os.log

private let startupLog = OSLog(subsystem: "com.damienhosea.DuoCraft", category: "Startup")
private let appStartTime = CFAbsoluteTimeGetCurrent()

// #region agent log
func _debugLog(_ msg: String, hyp: String = "", file: String = #fileID, line: Int = #line) {
    let loc = "\(file):\(line)"
    let elapsed = Int((CFAbsoluteTimeGetCurrent() - appStartTime) * 1000)
    print("[DBG|\(hyp) +\(elapsed)ms] \(loc) — \(msg)")
}
// #endregion

// MARK: - AppDelegate for OneSignal Initialization + Notification Tap Handling
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let appId = Bundle.main.object(forInfoDictionaryKey: "OneSignalAppId") as? String ?? ""
        
        #if DEBUG
        OneSignal.Debug.setLogLevel(.LL_WARN)
        #endif
        
        OneSignal.initialize(appId, withLaunchOptions: launchOptions)
        
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
        os_log(.fault, log: startupLog, "⏱ App init START (+%.0fms)", (CFAbsoluteTimeGetCurrent() - appStartTime) * 1000)
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
            PartyChallenge.self,
            EquipmentQuirk.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            let t0 = CFAbsoluteTimeGetCurrent()
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            os_log(.fault, log: startupLog, "⏱ ModelContainer created OK (+%.0fms, took %.0fms)", (CFAbsoluteTimeGetCurrent() - appStartTime) * 1000, (CFAbsoluteTimeGetCurrent() - t0) * 1000)
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
                // Last resort: use an in-memory container so the app doesn't crash.
                // User will lose local data, but cloud restore will recover it.
                print("🚨 ModelContainer failed even after reset: \(error). Falling back to in-memory store.")
                let inMemoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                do {
                    modelContainer = try ModelContainer(for: schema, configurations: [inMemoryConfig])
                } catch {
                    fatalError("Could not initialize even an in-memory ModelContainer: \(error)")
                }
            }
        }
    }
    
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var gameEngine = GameEngine()
    
    /// Realtime channels for partner sync (kept alive while app is open)
    @State private var partnerTaskChannel: RealtimeChannelV2?
    @State private var partnerProfileChannel: RealtimeChannelV2?
    
    /// Guards against overlapping onAppBecameActive Tasks
    @State private var isActiveSyncRunning = false
    
    /// Whether pullAndMerge has already run this app session
    @State private var hasPulledThisSession = false
    
    var body: some Scene {
        WindowGroup {
            AuthGateView()
                .environmentObject(gameEngine)
                .preferredColorScheme(.dark)
                .onAppear {
                    os_log(.fault, log: startupLog, "⏱ AuthGateView.onAppear (+%.0fms)", (CFAbsoluteTimeGetCurrent() - appStartTime) * 1000)
                    PushNotificationService.shared.cancelDailyReset()
                    
                    gameEngine.migrateEnhancementsToEquipmentEXP(context: modelContainer.mainContext)
                    
                    // #region agent log
                    _debugLog("onAppear: about to call loadContent()", hyp: "A")
                    // #endregion
                    Task {
                        await ContentManager.shared.loadContent()
                        // #region agent log
                        _debugLog("onAppear: loadContent() returned", hyp: "A")
                        // #endregion
                    }
                }
        }
        .modelContainer(modelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            // #region agent log
            _debugLog("scenePhase changed to \(newPhase)", hyp: "H-E")
            // #endregion
            switch newPhase {
            case .active:
                // #region agent log
                _debugLog("scenePhase .active — calling onAppBecameActive", hyp: "H-E")
                // #endregion
                onAppBecameActive()
            case .background:
                syncCharacterToCloud()
            case .inactive:
                break
            @unknown default:
                break
            }
        }
    }
    
    /// Called when the app returns to the foreground.
    /// Heavy sync work is broken into small chunks with explicit yields
    /// so the main run loop can process UI frames between operations.
    private func onAppBecameActive() {
        // #region agent log
        _debugLog("onAppBecameActive ENTER, isActiveSyncRunning=\(isActiveSyncRunning)", hyp: "H-A")
        // #endregion
        guard !isActiveSyncRunning else { return }
        isActiveSyncRunning = true
        
        PushNotificationService.shared.cancelReengagementNotifications()
        
        Task {
            defer { isActiveSyncRunning = false }
            
            // #region agent log
            _debugLog("onAppBecameActive: starting 5s sleep", hyp: "H-A")
            // #endregion
            try? await Task.sleep(for: .seconds(5))
            await Task.yield()
            // #region agent log
            _debugLog("onAppBecameActive: 5s sleep done, starting sync work", hyp: "H-A")
            // #endregion
            
            let context = modelContainer.mainContext
            let descriptor = FetchDescriptor<PlayerCharacter>()
            guard let character = try? context.fetch(descriptor).first else { return }
            guard SupabaseService.shared.isAuthenticated else { return }
            
            // Pull from cloud only ONCE per app session (not on every foreground)
            if !hasPulledThisSession {
                hasPulledThisSession = true
                await SyncManager.shared.pullAndMerge(context: context)
                try? await Task.sleep(for: .milliseconds(500))
                await Task.yield()
            }
            
            // One-time bulk upload for existing users who haven't synced yet
            if !SyncManager.shared.hasCompletedInitialSync {
                let tasks = (try? context.fetch(FetchDescriptor<GameTask>())) ?? []
                await Task.yield()
                let goals = (try? context.fetch(FetchDescriptor<Goal>())) ?? []
                await Task.yield()
                let moods = (try? context.fetch(FetchDescriptor<MoodEntry>())) ?? []
                let bonds = (try? context.fetch(FetchDescriptor<Bond>())) ?? []
                await Task.yield()
                
                await SyncManager.shared.performInitialSync(
                    character: character,
                    tasks: tasks,
                    goals: goals,
                    moodEntries: moods,
                    bonds: bonds
                )
                try? await Task.sleep(for: .milliseconds(300))
                await Task.yield()
            }
            
            // Profile + partner linking (lightweight network calls)
            await SupabaseService.shared.fetchProfile()
            await Task.yield()
            
            if !character.hasPartner, let partnerID = SupabaseService.shared.currentProfile?.partnerID {
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
                }
            }
            
            await Task.yield()
            await gameEngine.fetchIncomingPartnerTasks(context: context)
            await Task.yield()
            await gameEngine.refreshPartnerData(character: character)
            await Task.yield()
            
            // Realtime subscriptions last (WebSocket connect can be slow)
            try? await Task.sleep(for: .seconds(1))
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

