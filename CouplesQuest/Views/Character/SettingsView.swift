import SwiftUI
import SwiftData

/// Centralized Settings screen accessible from Character tab gear icon.
/// Sections: Account, Audio, Notifications, Meditation, Gameplay, Privacy, About.
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var supabase = SupabaseService.shared
    @ObservedObject private var audioManager = AudioManager.shared
    @ObservedObject private var syncManager = SyncManager.shared
    
    @Query private var characters: [PlayerCharacter]
    @Query private var tasks: [GameTask]
    @Query private var goals: [Goal]
    @Query private var moodEntries: [MoodEntry]
    
    @State private var showDeleteConfirm = false
    @State private var showSignOutConfirm = false
    @State private var deleteConfirmText = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?
    // Export state removed — feature not needed
    
    // Notification preferences
    @AppStorage("notifications_enabled") private var notificationsEnabled = true
    @AppStorage("notifications_quiet_start") private var quietHoursStart = 22 // 10 PM
    @AppStorage("notifications_quiet_end") private var quietHoursEnd = 8 // 8 AM
    
    // Gameplay preferences
    @AppStorage("gameplay_auto_salvage") private var autoSalvageEnabled = false
    @AppStorage("gameplay_confirm_completion") private var confirmTaskCompletion = false
    @AppStorage("gameplay_analytics_optin") private var analyticsOptIn = true
    
    // Privacy preferences
    @AppStorage("privacy_location_enabled") private var locationEnabled = false
    @AppStorage("privacy_healthkit_enabled") private var healthKitEnabled = false
    @AppStorage("privacy_mood_sharing") private var moodSharingEnabled = false
    
    private var character: PlayerCharacter? { characters.first }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color("BackgroundTop"), Color("BackgroundBottom")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Sync Status Indicator
                        if syncManager.hasSyncIssue {
                            syncIssueCard
                        }
                        
                        // Account Section
                        accountSection
                        
                        // Audio Section
                        audioSection
                        
                        // Notifications Section
                        notificationsSection
                        
                        // Meditation Section
                        meditationSection
                        
                        // Gameplay Section
                        gameplaySection
                        
                        // Privacy Section
                        privacySection
                        
                        // About Section
                        aboutSection
                        
                        // Danger Zone
                        dangerZoneSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(Color("AccentGold"))
                }
            }
            .alert("Sign Out?", isPresented: $showSignOutConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) { performSignOut() }
            } message: {
                Text("Your progress is saved to the cloud. You can sign back in to restore it.")
            }
            // Export share sheet removed
        }
    }
    
    // MARK: - Sync Issue Card
    
    private var syncIssueCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.icloud.fill")
                .foregroundColor(Color("AccentOrange"))
            VStack(alignment: .leading, spacing: 2) {
                Text("Sync Issue")
                    .font(.custom("Avenir-Heavy", size: 14))
                    .foregroundColor(Color("AccentOrange"))
                Text("Some changes haven't synced yet. They'll retry automatically.")
                    .font(.custom("Avenir-Medium", size: 12))
                    .foregroundColor(.secondary)
            }
            Spacer()
            if syncManager.pendingCount > 0 {
                Text("\(syncManager.pendingCount)")
                    .font(.custom("Avenir-Heavy", size: 12))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color("AccentOrange").cornerRadius(8))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("AccentOrange").opacity(0.1))
        )
    }
    
    // MARK: - Account Section
    
    private var accountSection: some View {
        settingsCard(title: "Account", icon: "person.circle.fill") {
            VStack(spacing: 16) {
                // Email
                if let email = supabase.currentProfile?.email {
                    settingsRow(label: "Email", value: email)
                }
                
                // Partner Code
                if let code = supabase.currentProfile?.partnerCode {
                    HStack {
                        Text("Partner Code")
                            .font(.custom("Avenir-Medium", size: 14))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(code)
                            .font(.custom("Avenir-Heavy", size: 14))
                            .foregroundColor(Color("AccentGold"))
                        Button {
                            UIPasteboard.general.string = code
                            AudioManager.shared.play(.success)
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 12))
                                .foregroundColor(Color("AccentGold"))
                        }
                    }
                }
                
                // Last Sync
                if let lastSync = character?.lastSyncTimestamp {
                    settingsRow(label: "Last Sync", value: lastSync.formatted(date: .abbreviated, time: .shortened))
                }
                
                Divider().opacity(0.3)
                
                // Sign Out
                Button(action: { showSignOutConfirm = true }) {
                    HStack(spacing: 10) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Sign Out")
                            .font(.custom("Avenir-Heavy", size: 14))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(Color("AccentGold"))
                }
            }
        }
    }
    
    // MARK: - Audio Section
    
    private var audioSection: some View {
        settingsCard(title: "Audio", icon: "speaker.wave.2.fill") {
            VStack(spacing: 16) {
                // Master Mute Toggle
                Toggle(isOn: Binding(
                    get: { !audioManager.isMuted },
                    set: { audioManager.isMuted = !$0 }
                )) {
                    Label {
                        Text("Sound Effects")
                            .font(.custom("Avenir-Medium", size: 14))
                    } icon: {
                        Image(systemName: audioManager.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .foregroundColor(Color("AccentGold"))
                    }
                }
                .tint(Color("AccentGold"))
                
                // Volume Slider
                if !audioManager.isMuted {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Volume")
                            .font(.custom("Avenir-Medium", size: 13))
                            .foregroundColor(.secondary)
                        HStack(spacing: 12) {
                            Image(systemName: "speaker.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Slider(value: $audioManager.volume, in: 0...1)
                                .tint(Color("AccentGold"))
                            Image(systemName: "speaker.wave.3.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Notifications Section
    
    private var notificationsSection: some View {
        settingsCard(title: "Notifications", icon: "bell.fill") {
            VStack(spacing: 16) {
                Toggle(isOn: $notificationsEnabled) {
                    Label {
                        Text("Push Notifications")
                            .font(.custom("Avenir-Medium", size: 14))
                    } icon: {
                        Image(systemName: "bell.badge.fill")
                            .foregroundColor(Color("AccentGold"))
                    }
                }
                .tint(Color("AccentGold"))
                
                if notificationsEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quiet Hours")
                            .font(.custom("Avenir-Medium", size: 13))
                            .foregroundColor(.secondary)
                        HStack {
                            Text("From \(formatHour(quietHoursStart)) to \(formatHour(quietHoursEnd))")
                                .font(.custom("Avenir-Medium", size: 14))
                            Spacer()
                            Text("No notifications")
                                .font(.custom("Avenir-Medium", size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Meditation Section
    
    private var meditationSection: some View {
        settingsCard(title: "Meditation", icon: "leaf.fill") {
            VStack(spacing: 16) {
                // Default Duration
                HStack {
                    Label {
                        Text("Default Duration")
                            .font(.custom("Avenir-Medium", size: 14))
                    } icon: {
                        Image(systemName: "timer")
                            .foregroundColor(Color("AccentGold"))
                    }
                    Spacer()
                    let duration = UserDefaults.standard.integer(forKey: "Meditation_duration")
                    Text("\(duration > 0 ? duration : 5) min")
                        .font(.custom("Avenir-Heavy", size: 14))
                        .foregroundColor(Color("AccentGold"))
                }
                
                // Ending Bell
                HStack {
                    Label {
                        Text("Ending Bell")
                            .font(.custom("Avenir-Medium", size: 14))
                    } icon: {
                        Image(systemName: "bell.fill")
                            .foregroundColor(Color("AccentGold"))
                    }
                    Spacer()
                    Text(AudioManager.MeditationBell.savedEnding.displayName)
                        .font(.custom("Avenir-Medium", size: 14))
                        .foregroundColor(.secondary)
                }
                
                // Ambient Sound
                HStack {
                    Label {
                        Text("Ambient Sound")
                            .font(.custom("Avenir-Medium", size: 14))
                    } icon: {
                        Image(systemName: "waveform")
                            .foregroundColor(Color("AccentGold"))
                    }
                    Spacer()
                    Text(AudioManager.AmbientSound.saved.displayName)
                        .font(.custom("Avenir-Medium", size: 14))
                        .foregroundColor(.secondary)
                }
                
                Text("Adjust these settings from the Meditation screen for a live preview.")
                    .font(.custom("Avenir-Medium", size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Gameplay Section
    
    private var gameplaySection: some View {
        settingsCard(title: "Gameplay", icon: "gamecontroller.fill") {
            VStack(spacing: 16) {
                Toggle(isOn: $autoSalvageEnabled) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Auto-Salvage")
                                .font(.custom("Avenir-Medium", size: 14))
                            Text("Automatically salvage Common items")
                                .font(.custom("Avenir-Medium", size: 11))
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "hammer.fill")
                            .foregroundColor(Color("AccentGold"))
                    }
                }
                .tint(Color("AccentGold"))
                
                Toggle(isOn: $confirmTaskCompletion) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Confirm Task Completion")
                                .font(.custom("Avenir-Medium", size: 14))
                            Text("Ask before marking tasks done")
                                .font(.custom("Avenir-Medium", size: 11))
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color("AccentGold"))
                    }
                }
                .tint(Color("AccentGold"))
                
                Toggle(isOn: $analyticsOptIn) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Analytics")
                                .font(.custom("Avenir-Medium", size: 14))
                            Text("Help improve the app with anonymous data")
                                .font(.custom("Avenir-Medium", size: 11))
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(Color("AccentGold"))
                    }
                }
                .tint(Color("AccentGold"))
            }
        }
    }
    
    // MARK: - Privacy Section
    
    private var privacySection: some View {
        settingsCard(title: "Privacy", icon: "lock.shield.fill") {
            VStack(spacing: 16) {
                Toggle(isOn: $locationEnabled) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Location Services")
                                .font(.custom("Avenir-Medium", size: 14))
                            Text("For location-verified tasks")
                                .font(.custom("Avenir-Medium", size: 11))
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "location.fill")
                            .foregroundColor(Color("AccentGold"))
                    }
                }
                .tint(Color("AccentGold"))
                
                Toggle(isOn: $healthKitEnabled) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("HealthKit Access")
                                .font(.custom("Avenir-Medium", size: 14))
                            Text("Verify physical activity tasks")
                                .font(.custom("Avenir-Medium", size: 11))
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "heart.fill")
                            .foregroundColor(Color("AccentGold"))
                    }
                }
                .tint(Color("AccentGold"))
                
                Toggle(isOn: $moodSharingEnabled) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Mood Sharing")
                                .font(.custom("Avenir-Medium", size: 14))
                            Text("Share mood with party members")
                                .font(.custom("Avenir-Medium", size: 11))
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "face.smiling.fill")
                            .foregroundColor(Color("AccentGold"))
                    }
                }
                .tint(Color("AccentGold"))
            }
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        settingsCard(title: "About", icon: "info.circle.fill") {
            VStack(spacing: 16) {
                settingsRow(
                    label: "Version",
                    value: "\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"))"
                )
                
                settingsRow(label: "Developer", value: "Damien Hosea")
                
                Button(action: {
                    if let url = URL(string: "mailto:support@couplesquest.app") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "envelope.fill")
                        Text("Send Feedback")
                            .font(.custom("Avenir-Heavy", size: 14))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(Color("AccentGold"))
                }
                
                Text("Made with love for couples who quest together.")
                    .font(.custom("Avenir-Medium", size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Danger Zone
    
    private var dangerZoneSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("Danger Zone")
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(.red)
                Spacer()
            }
            
            // Error banner
            if let errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .font(.custom("Avenir-Medium", size: 13))
                        .foregroundColor(.red)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.red.opacity(0.1))
                )
            }
            
            VStack(spacing: 12) {
                Text("Type DELETE to confirm account deletion. This action is immediate and cannot be undone.")
                    .font(.custom("Avenir-Medium", size: 12))
                    .foregroundColor(.secondary)
                
                TextField("Type DELETE", text: $deleteConfirmText)
                    .font(.custom("Avenir-Medium", size: 14))
                    .textInputAutocapitalization(.characters)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color("CardBackground"))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(deleteConfirmText == "DELETE" ? Color.red : Color.clear, lineWidth: 1)
                    )
                
                Button(action: performDeleteAccount) {
                    HStack(spacing: 10) {
                        Image(systemName: "trash.fill")
                        Text("Delete Account Permanently")
                            .font(.custom("Avenir-Heavy", size: 14))
                        Spacer()
                        if isProcessing {
                            ProgressView()
                                .tint(.white)
                        }
                    }
                    .foregroundColor(.white)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(deleteConfirmText == "DELETE" ? Color.red : Color.red.opacity(0.3))
                    )
                }
                .disabled(deleteConfirmText != "DELETE" || isProcessing)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Helper Views
    
    private func settingsCard<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color("AccentGold"))
                Text(title)
                    .font(.custom("Avenir-Heavy", size: 16))
                Spacer()
            }
            
            content()
        }
        .padding(16)
        .background(Color("CardBackground"))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    private func settingsRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.custom("Avenir-Medium", size: 14))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.custom("Avenir-Medium", size: 14))
                .foregroundColor(.primary)
                .lineLimit(1)
        }
    }
    
    private func formatHour(_ hour: Int) -> String {
        let h = hour % 24
        if h == 0 { return "12 AM" }
        if h < 12 { return "\(h) AM" }
        if h == 12 { return "12 PM" }
        return "\(h - 12) PM"
    }
    
    // MARK: - Actions
    
    private func performSignOut() {
        isProcessing = true
        errorMessage = nil
        Task {
            do {
                // Flush sync before signing out
                await SyncManager.shared.flush()
                try await supabase.signOut()
                clearLocalData()
                dismiss()
            } catch {
                errorMessage = "Failed to sign out. Please try again."
                isProcessing = false
            }
        }
    }
    
    private func performDeleteAccount() {
        guard deleteConfirmText == "DELETE" else { return }
        isProcessing = true
        errorMessage = nil
        
        Task {
            do {
                // 1. Delete all player data from Supabase sync tables
                try await supabase.deleteAllPlayerData()
                
                // 2. Delete the auth account (Edge Function)
                try await supabase.deleteAccount()
                
                // 3. Clear all local SwiftData
                clearLocalData()
                
                // 4. Reset SyncManager state
                SyncManager.shared.hasCompletedInitialSync = false
                
                dismiss()
            } catch {
                errorMessage = "Failed to delete account: \(error.localizedDescription)"
                isProcessing = false
            }
        }
    }
    
    /// Remove all local SwiftData objects.
    private func clearLocalData() {
        do {
            try modelContext.delete(model: PlayerCharacter.self)
            try modelContext.delete(model: GameTask.self)
            try modelContext.delete(model: Equipment.self)
            try modelContext.delete(model: EquipmentLoadout.self)
            try modelContext.delete(model: Stats.self)
            try modelContext.delete(model: Achievement.self)
            try modelContext.delete(model: AFKMission.self)
            try modelContext.delete(model: ActiveMission.self)
            try modelContext.delete(model: Dungeon.self)
            try modelContext.delete(model: DungeonRun.self)
            try modelContext.delete(model: DailyQuest.self)
            try modelContext.delete(model: Bond.self)
            try modelContext.delete(model: PartnerInteraction.self)
            try modelContext.delete(model: WeeklyRaidBoss.self)
            try modelContext.delete(model: ArenaRun.self)
            try modelContext.delete(model: CraftingMaterial.self)
            try modelContext.delete(model: Consumable.self)
            try modelContext.delete(model: MoodEntry.self)
            try modelContext.delete(model: Goal.self)
            try modelContext.save()
        } catch {
            print("Failed to clear local data: \(error)")
        }
        ActiveMission.clearPersisted()
    }
}

#Preview {
    SettingsView()
}
