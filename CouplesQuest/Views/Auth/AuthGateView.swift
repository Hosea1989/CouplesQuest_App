import SwiftUI
import SwiftData

/// Root view that checks authentication state and routes accordingly.
/// Flow: Splash → Auth (sign up/in) → Cloud Restore (if needed) → Character Creation (if needed) → Main App
///
/// **CRITICAL**: This view does NOT use @ObservedObject for SupabaseService.
/// SupabaseService publishes rapid changes during startup (token refresh,
/// session restore, profile fetch). Each change causes a body re-evaluation,
/// which recreates child views and deadlocks the main thread on physical devices.
/// Instead, we check Supabase state explicitly and mirror it in @State.
struct AuthGateView: View {
    // Access Supabase WITHOUT observation — prevents body re-renders from
    // background token refreshes, profile fetches, etc.
    private let supabase = SupabaseService.shared
    
    @Query private var characters: [PlayerCharacter]
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Routing State (all @State — we control when these change)
    @State private var isCheckingSession = true
    @State private var isAuthenticated = false
    @State private var isRestoringCharacter = false
    @State private var cloudRestoreAttempted = false
    @State private var cloudRestoreFailed = false
    @State private var cloudRestoreError: String?
    @State private var retryCount = 0
    @State private var appLaunched = false
    
    private let maxAutoRetries = 2
    
    private var hasCharacter: Bool { !characters.isEmpty }
    
    private var hasCharacterForCurrentUser: Bool {
        guard let userID = supabase.currentUserID else { return false }
        return characters.contains { $0.supabaseUserID == userID.uuidString }
    }
    
    var body: some View {
        // #region agent log
        let _ = _debugLog("AuthGateView.body: appLaunched=\(appLaunched) isCheckingSession=\(isCheckingSession) isAuth=\(isAuthenticated) hasChar=\(hasCharacter)", hyp: "H-A")
        // #endregion
        Group {
            if appLaunched {
                ContentView()
            } else if isCheckingSession || isRestoringCharacter {
                SplashScreenView()
            } else if !isAuthenticated {
                AuthView()
            } else if cloudRestoreFailed {
                cloudRestoreErrorView
            } else if !hasCharacter {
                CharacterCreationView(isOnboarding: true)
            } else {
                Color("BackgroundTop")
                    .ignoresSafeArea()
                    .task {
                        // #region agent log
                        _debugLog("AuthGateView: setting appLaunched=true", hyp: "H-A")
                        // #endregion
                        appLaunched = true
                    }
            }
        }
        .task {
            // #region agent log
            _debugLog("AuthGateView .task: calling restoreSession()", hyp: "H-A")
            // #endregion
            await supabase.restoreSession()
            // #region agent log
            _debugLog("AuthGateView .task: restoreSession() done, isAuth=\(supabase.isAuthenticated)", hyp: "H-A")
            // #endregion
            isAuthenticated = supabase.isAuthenticated
            
            try? await Task.sleep(for: .milliseconds(300))
            
            if isAuthenticated, let userID = supabase.currentUserID {
                PushNotificationService.shared.login(userID: userID.uuidString)
            }
            
            if isAuthenticated && !hasCharacterForCurrentUser && !cloudRestoreAttempted {
                cloudRestoreAttempted = true
                await restoreCharacterFromCloud()
            }
            
            if isAuthenticated && hasCharacter && !cloudRestoreFailed {
                // #region agent log
                _debugLog("AuthGateView .task: setting appLaunched=true (authed + has char)", hyp: "H-A")
                // #endregion
                appLaunched = true
            }
            
            isCheckingSession = false
            // #region agent log
            _debugLog("AuthGateView .task: DONE, isCheckingSession=false", hyp: "H-A")
            // #endregion
        }
        // Listen for auth changes (sign-in/sign-out) ONLY before the app launches.
        // After launch, all Supabase changes are ignored to prevent re-renders.
        // NOTE: objectWillChange fires BEFORE the property changes, so we defer
        // the read to the next run-loop iteration when the value has actually updated.
        .onReceive(supabase.objectWillChange) { _ in
            guard !appLaunched else { return }
            DispatchQueue.main.async {
                let newAuth = supabase.isAuthenticated
                if newAuth != isAuthenticated {
                    isAuthenticated = newAuth
                }
            }
        }
    }
    
    // MARK: - Cloud Restore Error View
    
    private var cloudRestoreErrorView: some View {
        ZStack {
            LinearGradient(
                colors: [Color("BackgroundTop"), Color("BackgroundBottom")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.icloud")
                    .font(.system(size: 56))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("AccentGold"), Color("AccentOrange")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Couldn't Restore Your Character")
                    .font(.custom("Avenir-Heavy", size: 22))
                    .multilineTextAlignment(.center)
                
                Text("We found character data in the cloud but couldn't load it on this device. This can happen due to a network hiccup.")
                    .font(.custom("Avenir-Medium", size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                
                if let errorMsg = cloudRestoreError {
                    Text(errorMsg)
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.red.opacity(0.8))
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.red.opacity(0.1))
                        )
                        .padding(.horizontal, 24)
                }
                
                Button {
                    Task {
                        cloudRestoreFailed = false
                        cloudRestoreError = nil
                        await restoreCharacterFromCloud()
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isRestoringCharacter {
                            ProgressView()
                                .tint(.black)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Try Again")
                    }
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color("AccentGold"), Color("AccentOrange")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isRestoringCharacter)
                .padding(.horizontal, 32)
                
                Button {
                    if let existing = characters.first,
                       let userID = supabase.currentUserID {
                        existing.supabaseUserID = userID.uuidString
                        try? modelContext.save()
                        
                        Task {
                            do {
                                try await supabase.syncCharacterData(existing)
                                print("✅ Claimed existing character and synced to cloud")
                            } catch {
                                print("⚠️ Failed to sync claimed character: \(error)")
                            }
                        }
                    }
                    withAnimation(.easeInOut(duration: 0.3)) {
                        cloudRestoreFailed = false
                        cloudRestoreError = nil
                    }
                } label: {
                    Text("Create New Character Instead")
                        .font(.custom("Avenir-Heavy", size: 14))
                        .foregroundColor(Color("AccentGold"))
                }
                .padding(.top, 8)
                
                Text("Warning: Creating a new character will overwrite any existing cloud save.")
                    .font(.custom("Avenir-Medium", size: 11))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Divider()
                    .padding(.horizontal, 48)
                    .padding(.vertical, 4)
                
                Button {
                    Task {
                        try? await supabase.signOut()
                        isAuthenticated = false
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Sign Out")
                    }
                    .font(.custom("Avenir-Heavy", size: 14))
                    .foregroundColor(.red.opacity(0.8))
                }
            }
        }
    }
    
    // MARK: - Cloud Character Restore
    
    private func restoreCharacterFromCloud() async {
        isRestoringCharacter = true
        defer {
            isRestoringCharacter = false
        }
        
        do {
            guard let snapshot = try await supabase.fetchCharacterData() else {
                return
            }
            
            let character = PlayerCharacter.fromSnapshot(snapshot)
            character.supabaseUserID = supabase.currentUserID?.uuidString
            modelContext.insert(character)
            
            let cloudEquipment = try await supabase.fetchOwnEquipment()
            for cloudItem in cloudEquipment {
                let item = Equipment(
                    name: cloudItem.name,
                    description: cloudItem.description,
                    slot: EquipmentSlot(rawValue: cloudItem.slot) ?? .weapon,
                    rarity: ItemRarity(rawValue: cloudItem.rarity) ?? .common,
                    primaryStat: StatType(rawValue: cloudItem.primaryStat) ?? .strength,
                    statBonus: cloudItem.statBonus,
                    levelRequirement: cloudItem.levelRequirement
                )
                item.id = cloudItem.id
                if let secondary = cloudItem.secondaryStat {
                    item.secondaryStat = StatType(rawValue: secondary)
                    item.secondaryStatBonus = cloudItem.secondaryStatBonus
                }
                item.enhancementLevel = cloudItem.enhancementLevel
                item.catalogID = cloudItem.catalogID
                modelContext.insert(item)
                
                if cloudItem.isEquipped {
                    switch item.slot {
                    case .weapon: character.equipment.weapon = item
                    case .armor: character.equipment.armor = item
                    case .accessory: character.equipment.accessory = item
                    case .trinket: character.equipment.trinket = item
                    }
                    item.isEquipped = true
                }
            }
            
            try modelContext.save()
            
            cloudRestoreFailed = false
            cloudRestoreError = nil
            retryCount = 0
            
            print("Character restored from cloud: \(character.name) Lv.\(character.level)")
        } catch {
            print("Failed to restore character from cloud (attempt \(retryCount + 1)): \(error)")
            retryCount += 1
            
            if retryCount <= maxAutoRetries {
                try? await Task.sleep(for: .seconds(1))
                await restoreCharacterFromCloud()
            } else {
                cloudRestoreFailed = true
                cloudRestoreError = error.localizedDescription
            }
        }
    }
}

#Preview {
    AuthGateView()
        .environmentObject(GameEngine())
}
