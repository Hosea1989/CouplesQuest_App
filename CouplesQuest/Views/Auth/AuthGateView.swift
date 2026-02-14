import SwiftUI
import SwiftData

/// Root view that checks authentication state and routes accordingly.
/// Flow: Splash → Auth (sign up/in) → Cloud Restore (if needed) → Character Creation (if needed) → Main App
///
/// Navigation is driven by **local SwiftData** for character existence (instant,
/// offline-capable) and **Supabase** for authentication state and cloud restore.
///
/// **Multi-device safeguard**: Before allowing character creation, this view
/// verifies that no `character_data` already exists in the cloud profile.
/// If cloud data exists, it retries the restore instead of creating a duplicate.
struct AuthGateView: View {
    @ObservedObject private var supabase = SupabaseService.shared
    @Query private var characters: [PlayerCharacter]
    @Environment(\.modelContext) private var modelContext
    @State private var isCheckingSession = true
    @State private var isRestoringCharacter = false
    @State private var cloudRestoreAttempted = false
    @State private var cloudRestoreFailed = false
    @State private var cloudRestoreError: String?
    @State private var retryCount = 0
    
    /// Maximum number of automatic retries before showing the error UI.
    private let maxAutoRetries = 2
    
    /// Whether a local character has been created in SwiftData.
    private var hasCharacter: Bool { !characters.isEmpty }
    
    /// Whether the local character belongs to the currently authenticated user.
    private var hasCharacterForCurrentUser: Bool {
        guard let userID = supabase.currentUserID else { return false }
        return characters.contains { $0.supabaseUserID == userID.uuidString }
    }
    
    var body: some View {
        Group {
            if isCheckingSession || isRestoringCharacter {
                // Animated splash screen while restoring session or character
                SplashScreenView()
                    .transition(.opacity)
            } else if !supabase.isAuthenticated {
                // Not signed in — show auth form
                AuthView()
                    .transition(.opacity)
            } else if cloudRestoreFailed {
                // Cloud restore failed — show retry / error screen
                cloudRestoreErrorView
                    .transition(.opacity)
            } else if !hasCharacter {
                // Signed in but no local character yet — mandatory onboarding
                CharacterCreationView(isOnboarding: true)
                    .transition(.opacity)
            } else {
                // Fully set up — enter the app
                ContentView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: isCheckingSession)
        .animation(.easeInOut(duration: 0.4), value: supabase.isAuthenticated)
        .animation(.easeInOut(duration: 0.4), value: hasCharacter)
        .animation(.easeInOut(duration: 0.4), value: isRestoringCharacter)
        .animation(.easeInOut(duration: 0.4), value: cloudRestoreFailed)
        .task {
            // Restore session from keychain (also fetches profile)
            await supabase.restoreSession()
            // Small delay so the splash animation has time to play
            try? await Task.sleep(for: .milliseconds(800))
            
            // Associate the device with the Supabase user in OneSignal
            if supabase.isAuthenticated, let userID = supabase.currentUserID {
                PushNotificationService.shared.login(userID: userID.uuidString)
            }
            
            // If authenticated but no local character for this user, try restoring from cloud
            if supabase.isAuthenticated && !hasCharacterForCurrentUser && !cloudRestoreAttempted {
                cloudRestoreAttempted = true
                await restoreCharacterFromCloud()
            }
            
            withAnimation(.easeInOut(duration: 0.3)) {
                isCheckingSession = false
            }
        }
    }
    
    // MARK: - Cloud Restore Error View
    
    /// Shown when the cloud restore fails, giving the user a chance to retry
    /// instead of silently dumping them into character creation.
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
                
                // Retry button
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
                
                // Create new (with warning)
                Button {
                    // If there's already a local character, claim it for the current user
                    // so the restore loop doesn't repeat on next launch
                    if let existing = characters.first,
                       let userID = supabase.currentUserID {
                        existing.supabaseUserID = userID.uuidString
                        try? modelContext.save()
                        
                        // Sync the claimed character to cloud so it's backed up
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
            }
        }
    }
    
    // MARK: - Cloud Character Restore
    
    /// Attempt to restore a character from the Supabase cloud snapshot.
    /// If character_data exists in the profile, creates a local PlayerCharacter
    /// and pulls equipment from the cloud.
    ///
    /// **Retry behaviour**: Automatically retries up to `maxAutoRetries` times
    /// on failure. After that, sets `cloudRestoreFailed` to show the error UI.
    private func restoreCharacterFromCloud() async {
        isRestoringCharacter = true
        defer {
            withAnimation(.easeInOut(duration: 0.3)) {
                isRestoringCharacter = false
            }
        }
        
        do {
            guard let snapshot = try await supabase.fetchCharacterData() else {
                // No cloud data — user genuinely needs to create a character.
                // This is not an error; it's a first-time user.
                return
            }
            
            // Restore the character from the snapshot
            let character = PlayerCharacter.fromSnapshot(snapshot)
            
            // Stamp the Supabase user ID so we know this character belongs to this account
            character.supabaseUserID = supabase.currentUserID?.uuidString
            
            modelContext.insert(character)
            
            // Restore equipment from the cloud
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
                
                // Re-equip items that were equipped
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
            
            // Reset failure state on success
            cloudRestoreFailed = false
            cloudRestoreError = nil
            retryCount = 0
            
            print("Character restored from cloud: \(character.name) Lv.\(character.level)")
        } catch {
            print("Failed to restore character from cloud (attempt \(retryCount + 1)): \(error)")
            retryCount += 1
            
            if retryCount <= maxAutoRetries {
                // Auto-retry after a short delay
                try? await Task.sleep(for: .seconds(1))
                await restoreCharacterFromCloud()
            } else {
                // Show the error UI so the user can decide what to do
                withAnimation(.easeInOut(duration: 0.3)) {
                    cloudRestoreFailed = true
                    cloudRestoreError = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    AuthGateView()
        .environmentObject(GameEngine())
}
