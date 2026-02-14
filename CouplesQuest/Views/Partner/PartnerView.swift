import SwiftUI
import SwiftData
import Supabase

struct PartnerView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var gameEngine: GameEngine
    @Query private var characters: [PlayerCharacter]
    @Query private var bonds: [Bond]
    @Query(sort: \PartnerInteraction.createdAt, order: .reverse) private var interactions: [PartnerInteraction]
    
    @ObservedObject private var supabase = SupabaseService.shared
    
    @State private var showPairingSheet = false
    @State private var showCloudPairingSheet = false
    @State private var showAssignTaskSheet = false
    @State private var showLeaderboardSheet = false
    @State private var showNudgeConfirm = false
    @State private var showKudosConfirm = false
    @State private var showChallengeConfirm = false
    @State private var showInteractionSuccess = false
    @State private var interactionSuccessMessage = ""
    @State private var showDutyCelebration = false
    @State private var claimedDutyTask: GameTask? = nil
    @State private var claimedDutyBondEXP: Int = 0
    @State private var myCodeCopied = false
    @State private var ownProfileChannel: RealtimeChannelV2?
    @State private var pollingTimer: Timer?
    @Query(filter: #Predicate<GameTask> { task in
        task.pendingPartnerConfirmation == true
    }) private var allPendingTasks: [GameTask]
    
    /// Number of tasks pending confirmation from us (partner's completed tasks)
    private var pendingConfirmationCount: Int {
        guard let character = character else { return 0 }
        return allPendingTasks.filter { $0.completedBy != nil && $0.completedBy != character.id }.count
    }
    
    private var character: PlayerCharacter? {
        characters.first
    }
    
    private var bond: Bond? {
        bonds.first
    }
    
    private var isPartnerLinked: Bool {
        character?.hasPartner ?? false
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color("BackgroundTop"),
                        Color("BackgroundBottom")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Always show my partner code at the top
                        myPartnerCodeCard
                        
                        if isPartnerLinked, let character = character, let bond = bond {
                            // Partner Connected - Full Dashboard
                            PartnerDashboardView(
                                character: character,
                                bond: bond,
                                onAssignTask: { showAssignTaskSheet = true },
                                onSendNudge: { showNudgeConfirm = true },
                                onSendKudos: { showKudosConfirm = true },
                                onSendChallenge: { showChallengeConfirm = true },
                                onViewLeaderboard: { showLeaderboardSheet = true },
                                onUnlinkPartner: { unlinkPartner() },
                                onInviteMember: { showPairingSheet = true }
                            )
                            
                            // Pending Confirmations
                            if pendingConfirmationCount > 0 {
                                NavigationLink(destination: PendingConfirmationsView()) {
                                    HStack(spacing: 12) {
                                        ZStack(alignment: .topTrailing) {
                                            Image(systemName: "checkmark.seal.fill")
                                                .font(.title2)
                                                .foregroundColor(Color("AccentGold"))
                                            
                                            Text("\(pendingConfirmationCount)")
                                                .font(.custom("Avenir-Heavy", size: 11))
                                                .foregroundColor(.white)
                                                .padding(4)
                                                .background(Circle().fill(.red))
                                                .offset(x: 6, y: -4)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Pending Confirmations")
                                                .font(.custom("Avenir-Heavy", size: 15))
                                                .foregroundColor(.primary)
                                            Text("\(pendingConfirmationCount) task\(pendingConfirmationCount == 1 ? "" : "s") awaiting your review")
                                                .font(.custom("Avenir-Medium", size: 12))
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color("CardBackground"))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color("AccentGold").opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                            
                            // Recent Interactions
                            if !interactions.isEmpty {
                                recentInteractionsCard
                            }
                            
                            // Duty Board Preview
                            dutyBoardPreview
                            
                        } else {
                            // Not Connected View — QR pairing
                            PartnerNotConnectedView(
                                onPair: { showPairingSheet = true }
                            )
                            
                            // Partner Features Info
                            PartnerFeaturesCard()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Party")
            .navigationBarTitleDisplayMode(.large)
            .task {
                // Refresh profile to ensure partner code is loaded
                await SupabaseService.shared.fetchProfile()
                
                // Check if our profile now has a partner_id (e.g. request was accepted while we were away)
                await checkAndLinkPartnerIfNeeded()
                
                // Subscribe to own profile changes for instant partner_id detection
                if !isPartnerLinked && ownProfileChannel == nil {
                    ownProfileChannel = await SupabaseService.shared.subscribeToOwnProfile { updatedProfile in
                        if updatedProfile.partnerID != nil && !isPartnerLinked {
                            Task { await checkAndLinkPartnerIfNeeded() }
                        }
                    }
                }
                
                // Start polling while not connected (fallback for realtime issues)
                startPollingIfNeeded()
            }
            .onDisappear {
                stopPolling()
            }
            .onChange(of: isPartnerLinked) { _, linked in
                if linked {
                    // Stop polling and tear down own-profile subscription once linked
                    stopPolling()
                    if let channel = ownProfileChannel {
                        Task { await SupabaseService.shared.unsubscribeChannel(channel) }
                        ownProfileChannel = nil
                    }
                }
            }
            .sheet(isPresented: $showPairingSheet) {
                QRPairingView()
            }
            .sheet(isPresented: $showCloudPairingSheet) {
                CloudPairingView()
            }
            .sheet(isPresented: $showAssignTaskSheet) {
                CreateTaskView(initialType: .forPartner)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showLeaderboardSheet) {
                CouplesLeaderboardView()
            }
            .alert("Send Nudge", isPresented: $showNudgeConfirm) {
                Button("Send") { sendNudge() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Remind your ally that their quest log awaits!")
            }
            .alert("Send Kudos", isPresented: $showKudosConfirm) {
                Button("Send") { sendKudos() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Give your ally a thumbs up for their hard work!")
            }
            .alert("Send Challenge", isPresented: $showChallengeConfirm) {
                Button("Send") { sendChallenge() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Challenge your allies to complete 3 tasks today!")
            }
            .alert("Sent!", isPresented: $showInteractionSuccess) {
                Button("OK") {}
            } message: {
                Text(interactionSuccessMessage)
            }
            .overlay {
                if showDutyCelebration, let task = claimedDutyTask {
                    RewardCelebrationOverlay(
                        icon: "rectangle.on.rectangle.angled",
                        iconColor: Color("AccentPurple"),
                        title: "Duty Claimed!",
                        subtitle: task.title,
                        rewards: [
                            (icon: "heart.fill", label: "Bond EXP", value: "+\(claimedDutyBondEXP)", color: Color("AccentPink")),
                            (icon: "sparkles", label: "EXP on completion", value: "+\(task.scaledExpReward(characterLevel: character?.level ?? 1))", color: Color("AccentGold"))
                        ],
                        onDismiss: {
                            withAnimation { showDutyCelebration = false; claimedDutyTask = nil }
                        }
                    )
                    .transition(.opacity)
                }
            }
        }
    }
    
    // MARK: - My Party Code Card
    
    private var myPartnerCodeCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.text.rectangle.fill")
                .font(.title3)
                .foregroundColor(Color("AccentGold"))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("My Party Code")
                    .font(.custom("Avenir-Medium", size: 12))
                    .foregroundColor(.secondary)
                
                if let myCode = supabase.currentProfile?.partnerCode {
                    Text(myCode)
                        .font(.custom("Avenir-Heavy", size: 22))
                        .tracking(4)
                        .foregroundColor(Color("AccentGold"))
                } else if supabase.isAuthenticated {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Loading...")
                            .font(.custom("Avenir-Medium", size: 14))
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Sign in to get your code")
                        .font(.custom("Avenir-Medium", size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let myCode = supabase.currentProfile?.partnerCode {
                Button(action: {
                    UIPasteboard.general.string = myCode
                    withAnimation { myCodeCopied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { myCodeCopied = false }
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: myCodeCopied ? "checkmark" : "doc.on.doc")
                            .font(.caption)
                        Text(myCodeCopied ? "Copied!" : "Copy")
                            .font(.custom("Avenir-Heavy", size: 13))
                    }
                    .foregroundColor(myCodeCopied ? Color("AccentGreen") : Color("AccentGold"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color("AccentGold").opacity(0.12))
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
    }
    
    // MARK: - Recent Interactions Card
    
    private var recentInteractionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.custom("Avenir-Heavy", size: 16))
            
            ForEach(Array(interactions.prefix(5)), id: \.id) { interaction in
                HStack(spacing: 12) {
                    Image(systemName: interaction.type.icon)
                        .foregroundColor(Color(interaction.type.color))
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(interaction.type.rawValue)
                            .font(.custom("Avenir-Heavy", size: 14))
                        
                        if let message = interaction.message {
                            Text(message)
                                .font(.custom("Avenir-Medium", size: 12))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    Text(interaction.createdAt.timeAgoDisplay())
                        .font(.custom("Avenir-Medium", size: 11))
                        .foregroundColor(.secondary)
                }
                
                if interaction.id != interactions.prefix(5).last?.id {
                    Divider()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
    }
    
    // MARK: - Duty Board Preview
    
    @Query(filter: #Predicate<GameTask> { task in
        task.isOnDutyBoard == true
    }, sort: \GameTask.createdAt, order: .reverse) private var dutyBoardTasks: [GameTask]
    
    private var pendingDutyBoardTasks: [GameTask] {
        dutyBoardTasks.filter { $0.status != .completed }
    }
    
    private var dutyBoardPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "rectangle.on.rectangle")
                    .foregroundColor(Color("AccentPurple"))
                Text("Duty Board")
                    .font(.custom("Avenir-Heavy", size: 16))
                Spacer()
                Text("\(pendingDutyBoardTasks.count) tasks")
                    .font(.custom("Avenir-Medium", size: 13))
                    .foregroundColor(.secondary)
            }
            
            if pendingDutyBoardTasks.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "tray")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("No tasks on the board")
                            .font(.custom("Avenir-Medium", size: 13))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 16)
                    Spacer()
                }
            } else {
                ForEach(Array(pendingDutyBoardTasks.prefix(3)), id: \.id) { task in
                    HStack(spacing: 12) {
                        Image(systemName: task.category.icon)
                            .foregroundColor(Color(task.category.color))
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title)
                                .font(.custom("Avenir-Heavy", size: 14))
                            
                            HStack(spacing: 8) {
                                HStack(spacing: 4) {
                                    Image(systemName: "sparkles")
                                        .font(.caption2)
                                    Text("+\(task.scaledExpReward(characterLevel: character?.level ?? 1)) EXP")
                                        .font(.custom("Avenir-Medium", size: 11))
                                }
                                .foregroundColor(Color("AccentGold"))
                                
                                Text(task.category.rawValue)
                                    .font(.custom("Avenir-Medium", size: 11))
                                    .foregroundColor(Color(task.category.color))
                            }
                        }
                        
                        Spacer()
                        
                        // Claim button
                        Button(action: { claimDutyBoardTask(task) }) {
                            Text("Claim")
                                .font(.custom("Avenir-Heavy", size: 12))
                                .foregroundColor(Color("AccentGold"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color("AccentGold").opacity(0.15))
                                )
                        }
                    }
                    
                    if task.id != pendingDutyBoardTasks.prefix(3).last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
    }
    
    // MARK: - Actions
    
    private func sendNudge() {
        guard let character = character, let bond = bond else { return }
        let interaction = gameEngine.sendNudge(from: character, bond: bond, message: nil)
        modelContext.insert(interaction)
        interactionSuccessMessage = "Nudge sent to \(character.partnerName ?? "your ally")!"
        showInteractionSuccess = true
        ToastManager.shared.showInfo(
            "Nudge Sent!",
            subtitle: character.partnerName.map { "Sent to \($0)" },
            icon: "bell.badge.fill"
        )
        // Push notification to ally
        Task { await PushNotificationService.shared.notifyPartnerNudge(fromName: character.name) }
    }
    
    private func sendKudos() {
        guard let character = character, let bond = bond else { return }
        let interaction = gameEngine.sendKudos(from: character, bond: bond, message: nil)
        modelContext.insert(interaction)
        interactionSuccessMessage = "Kudos sent! +\(GameEngine.bondEXPForKudos) Bond EXP"
        showInteractionSuccess = true
        ToastManager.shared.showReward(
            "Kudos Sent!",
            subtitle: "+\(GameEngine.bondEXPForKudos) Bond EXP",
            icon: "hands.clap.fill"
        )
        // Push notification to partner
        Task { await PushNotificationService.shared.notifyPartnerKudos(fromName: character.name, bondEXP: GameEngine.bondEXPForKudos) }
    }
    
    private func sendChallenge() {
        guard let character = character, let bond = bond else { return }
        let interaction = gameEngine.sendChallenge(from: character, bond: bond, message: nil)
        modelContext.insert(interaction)
        interactionSuccessMessage = "Challenge sent to \(character.partnerName ?? "your ally")!"
        showInteractionSuccess = true
        ToastManager.shared.showInfo(
            "Challenge Sent!",
            subtitle: character.partnerName.map { "Sent to \($0)" },
            icon: "flag.fill"
        )
        // Push notification to partner
        Task { await PushNotificationService.shared.notifyPartnerChallenge(fromName: character.name) }
    }
    
    private func claimDutyBoardTask(_ task: GameTask) {
        guard let character = character, let bond = bond else { return }
        
        // Calculate bond EXP before claiming for display
        var bondEXP = GameEngine.bondEXPForDutyBoardTask
        if bond.unlockedPerks.contains(.bondEXPBoost) {
            bondEXP = Int(Double(bondEXP) * 1.1)
        }
        
        gameEngine.claimDutyBoardTask(task, character: character, bond: bond)
        
        ToastManager.shared.showSuccess(
            "Duty Claimed!",
            subtitle: "+\(bondEXP) Bond EXP"
        )
        
        claimedDutyTask = task
        claimedDutyBondEXP = bondEXP
        withAnimation { showDutyCelebration = true }
    }
    
    private func unlinkPartner() {
        character?.unlinkPartner()
        // Keep the bond for history, but could delete if preferred
    }
    
    // MARK: - Partner Detection (for request sender)
    
    /// Check if our Supabase profile now has a partner_id and link locally if so.
    /// This is the key fix: when our request is accepted by the other person,
    /// they set partner_id on our profile in Supabase, but our local SwiftData
    /// doesn't know about it until we check.
    @MainActor
    private func checkAndLinkPartnerIfNeeded() async {
        guard let character = character, !isPartnerLinked else { return }
        guard SupabaseService.shared.isAuthenticated else { return }
        
        // Re-fetch our profile from Supabase to get the latest partner_id
        await SupabaseService.shared.fetchProfile()
        
        guard let partnerID = SupabaseService.shared.currentProfile?.partnerID else { return }
        
        // Our profile now has a partner_id — link them locally
        do {
            if let partnerProfile = try await SupabaseService.shared.fetchProfile(byID: partnerID) {
                let pairingData = PairingData(
                    characterID: partnerID.uuidString,
                    name: partnerProfile.characterName ?? "Adventurer",
                    level: partnerProfile.level ?? 1,
                    characterClass: partnerProfile.characterClass,
                    partyID: nil,
                    avatarName: partnerProfile.avatarName
                )
                character.linkPartner(data: pairingData)
                
                // Create a Bond if one doesn't exist
                if bonds.isEmpty {
                    let newBond = Bond(memberIDs: [character.id, partnerID])
                    modelContext.insert(newBond)
                } else if let existingBond = bonds.first {
                    existingBond.addMember(partnerID)
                }
                
                try? modelContext.save()
                print("✅ Partner linked locally after detecting accepted request (partner: \(partnerProfile.characterName ?? "unknown"))")
            }
        } catch {
            print("❌ Failed to link partner locally after detection: \(error)")
        }
    }
    
    /// Start a polling timer that checks for partner_id changes every 5 seconds while not connected.
    private func startPollingIfNeeded() {
        guard !isPartnerLinked else { return }
        stopPolling()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            Task { @MainActor in
                guard !isPartnerLinked else {
                    stopPolling()
                    return
                }
                await checkAndLinkPartnerIfNeeded()
            }
        }
    }
    
    /// Stop the polling timer.
    private func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }
}

// MARK: - Partner Not Connected View

struct PartnerNotConnectedView: View {
    let onPair: () -> Void
    
    @ObservedObject private var supabase = SupabaseService.shared
    @State private var showManualEntry = false
    @State private var partnerCode = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showRequestSent = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Illustration
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color("AccentPink").opacity(0.2), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                
                HStack(spacing: -20) {
                    ZStack {
                        Circle()
                            .fill(Color("AccentGold").opacity(0.3))
                            .frame(width: 80, height: 80)
                        Image(systemName: "person.fill")
                            .font(.largeTitle)
                            .foregroundColor(Color("AccentGold"))
                    }
                    
                    ZStack {
                        Circle()
                            .fill(Color("AccentPurple").opacity(0.3))
                            .frame(width: 80, height: 80)
                        Image(systemName: "person.fill.questionmark")
                            .font(.largeTitle)
                            .foregroundColor(Color("AccentPurple"))
                    }
                }
            }
            
            VStack(spacing: 8) {
                Text("Find Your Party")
                    .font(.custom("Avenir-Heavy", size: 24))
                
                Text("Invite up to 3 allies to share tasks,\ncompete on the leaderboard, and quest together!")
                    .font(.custom("Avenir-Medium", size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // QR Pairing Button
            Button(action: onPair) {
                HStack {
                    Image(systemName: "qrcode")
                    Text("Pair with QR Code")
                }
                .font(.custom("Avenir-Heavy", size: 16))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color("AccentPink"), Color("AccentPurple")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
            }
            
            // Divider with "or"
            HStack {
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 1)
                Text("or")
                    .font(.custom("Avenir-Medium", size: 13))
                    .foregroundColor(.secondary)
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 1)
            }
            
            // Manual Code Entry
            VStack(spacing: 12) {
                Text("Enter Ally's Code")
                    .font(.custom("Avenir-Heavy", size: 15))
                
                HStack(spacing: 10) {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(Color("AccentPurple"))
                        .frame(width: 20)
                    
                    TextField("e.g. ABC123", text: $partnerCode)
                        .font(.custom("Avenir-Heavy", size: 18))
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                        .onChange(of: partnerCode) { _, newValue in
                            partnerCode = String(newValue.prefix(6)).uppercased()
                        }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color("AccentPurple").opacity(0.3), lineWidth: 1)
                )
                
                if let errorMessage {
                    Text(errorMessage)
                        .font(.custom("Avenir-Medium", size: 13))
                        .foregroundColor(.red)
                }
                
                Button(action: sendPartnerRequest) {
                    HStack(spacing: 8) {
                        if isLoading {
                            ProgressView().tint(.black)
                        } else {
                            Image(systemName: "paperplane.fill")
                            Text("Send Party Invite")
                        }
                    }
                    .font(.custom("Avenir-Heavy", size: 15))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color("AccentGold"), Color("AccentOrange")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                }
                .disabled(partnerCode.count < 6 || isLoading)
                .opacity(partnerCode.count < 6 ? 0.5 : 1)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
        .alert("Invite Sent!", isPresented: $showRequestSent) {
            Button("OK") {}
        } message: {
            Text("Your party invite has been sent. They'll need to accept it on their device.")
        }
    }
    
    private func sendPartnerRequest() {
        errorMessage = nil
        isLoading = true
        Task {
            do {
                try await supabase.sendPartnerRequest(toCode: partnerCode)
                showRequestSent = true
                partnerCode = ""
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

// MARK: - Partner Features Card

struct PartnerFeaturesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Party Features")
                .font(.custom("Avenir-Heavy", size: 18))
            
            FeatureRow(
                icon: "qrcode.viewfinder",
                title: "QR Code Pairing",
                description: "Scan or share a QR code to invite allies"
            )
            
            FeatureRow(
                icon: "heart.circle.fill",
                title: "Bond Level System",
                description: "Grow your bond together and unlock perks"
            )
            
            FeatureRow(
                icon: "paperplane.fill",
                title: "Assign Tasks",
                description: "Send tasks directly to any party member"
            )
            
            FeatureRow(
                icon: "rectangle.on.rectangle",
                title: "Shared Duty Board",
                description: "All members can claim tasks from a shared pool"
            )
            
            FeatureRow(
                icon: "chart.bar.fill",
                title: "Party Leaderboard",
                description: "Friendly competition to stay motivated"
            )
            
            FeatureRow(
                icon: "flame.fill",
                title: "Party Streak",
                description: "Bonus EXP when all members stay active daily"
            )
            
            FeatureRow(
                icon: "hand.thumbsup.fill",
                title: "Kudos & Nudges",
                description: "Encourage and motivate each other"
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color("AccentGold"))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("Avenir-Heavy", size: 14))
                Text(description)
                    .font(.custom("Avenir-Medium", size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Date Extension

extension Date {
    func timeAgoDisplay() -> String {
        let seconds = -self.timeIntervalSinceNow
        
        if seconds < 60 {
            return "Just now"
        } else if seconds < 3600 {
            let minutes = Int(seconds / 60)
            return "\(minutes)m ago"
        } else if seconds < 86400 {
            let hours = Int(seconds / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(seconds / 86400)
            return "\(days)d ago"
        }
    }
}

// MARK: - Cloud Pairing View

struct CloudPairingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var supabase = SupabaseService.shared
    @Query private var characters: [PlayerCharacter]
    @Query private var bonds: [Bond]
    
    @State private var partnerCode = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showRequestSent = false
    @State private var incomingRequests: [PartnerRequest] = []
    @State private var requestSenderProfiles: [UUID: Profile] = [:]
    
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
                        // My Party Code
                        if let code = supabase.currentProfile?.partnerCode {
                            VStack(spacing: 8) {
                                Text("Your Party Code")
                                    .font(.custom("Avenir-Heavy", size: 16))
                                    .foregroundColor(.secondary)
                                
                                Text(code)
                                    .font(.custom("Avenir-Heavy", size: 40))
                                    .tracking(6)
                                    .foregroundColor(Color("AccentGold"))
                                
                                Text("Share this code with allies to form a party")
                                    .font(.custom("Avenir-Medium", size: 13))
                                    .foregroundColor(.secondary)
                            }
                            .padding(24)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color("CardBackground"))
                            )
                        }
                        
                        // Enter Ally's Code
                        VStack(spacing: 16) {
                            Text("Enter Ally's Code")
                                .font(.custom("Avenir-Heavy", size: 16))
                            
                            HStack(spacing: 10) {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(Color("AccentPurple"))
                                    .frame(width: 20)
                                
                                TextField("e.g. ABC123", text: $partnerCode)
                                    .font(.custom("Avenir-Heavy", size: 18))
                                    .autocapitalization(.allCharacters)
                                    .disableAutocorrection(true)
                                    .onChange(of: partnerCode) { _, newValue in
                                        partnerCode = String(newValue.prefix(6)).uppercased()
                                    }
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color("CardBackground"))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color("AccentPurple").opacity(0.3), lineWidth: 1)
                            )
                            
                            if let errorMessage {
                                Text(errorMessage)
                                    .font(.custom("Avenir-Medium", size: 13))
                                    .foregroundColor(.red)
                            }
                            
                            Button(action: sendRequest) {
                                HStack(spacing: 8) {
                                    if isLoading {
                                        ProgressView().tint(.black)
                                    } else {
                                        Image(systemName: "paperplane.fill")
                                        Text("Send Party Invite")
                                    }
                                }
                                .font(.custom("Avenir-Heavy", size: 15))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        colors: [Color("AccentPink"), Color("AccentPurple")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .disabled(partnerCode.count < 6 || isLoading)
                            .opacity(partnerCode.count < 6 ? 0.5 : 1)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color("CardBackground"))
                        )
                        
                        // Incoming Requests
                        if !incomingRequests.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Incoming Requests")
                                    .font(.custom("Avenir-Heavy", size: 16))
                                
                                ForEach(incomingRequests) { request in
                                    HStack(spacing: 12) {
                                        Image(systemName: "person.crop.circle.badge.plus")
                                            .font(.title2)
                                            .foregroundColor(Color("AccentPink"))
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            if let profile = requestSenderProfiles[request.fromUserID] {
                                                Text(profile.characterName ?? profile.email ?? "Adventurer")
                                                    .font(.custom("Avenir-Heavy", size: 14))
                                                if let level = profile.level {
                                                    Text("Level \(level)")
                                                        .font(.custom("Avenir-Medium", size: 12))
                                                        .foregroundColor(.secondary)
                                                }
                                            } else {
                                                Text("Adventurer")
                                                    .font(.custom("Avenir-Heavy", size: 14))
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Button(action: { acceptRequest(request) }) {
                                            Text("Accept")
                                                .font(.custom("Avenir-Heavy", size: 12))
                                                .foregroundColor(.black)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 7)
                                                .background(Color("AccentGold"))
                                                .clipShape(Capsule())
                                        }
                                        
                                        Button(action: { rejectRequest(request) }) {
                                            Image(systemName: "xmark")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .padding(7)
                                                .background(Circle().fill(Color("CardBackground")))
                                        }
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color("CardBackground").opacity(0.6))
                                    )
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color("CardBackground"))
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Join Party")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Invite Sent!", isPresented: $showRequestSent) {
                Button("OK") { dismiss() }
            } message: {
                Text("Your party invite has been sent. They'll need to accept it on their device.")
            }
            .task {
                await loadIncomingRequests()
            }
        }
    }
    
    // MARK: - Actions
    
    private func sendRequest() {
        errorMessage = nil
        isLoading = true
        Task {
            do {
                try await supabase.sendPartnerRequest(toCode: partnerCode)
                showRequestSent = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    private func loadIncomingRequests() async {
        do {
            incomingRequests = try await supabase.fetchIncomingRequests()
            // Load sender profiles
            for request in incomingRequests {
                let profiles: [Profile] = try await supabase.client
                    .from("profiles")
                    .select()
                    .eq("id", value: request.fromUserID.uuidString)
                    .execute()
                    .value
                if let profile = profiles.first {
                    requestSenderProfiles[request.fromUserID] = profile
                }
            }
        } catch {
            print("Failed to load requests: \(error)")
        }
    }
    
    private func acceptRequest(_ request: PartnerRequest) {
        Task {
            do {
                try await supabase.acceptPartnerRequest(request.id)
                
                // Update local SwiftData character with partner info
                await linkPartnerLocally(partnerUserID: request.fromUserID)
                
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    /// After cloud accept, sync partner data into the local SwiftData character + Bond.
    @MainActor
    private func linkPartnerLocally(partnerUserID: UUID) async {
        guard let character = character else { return }
        
        do {
            if let partnerProfile = try await supabase.fetchProfile(byID: partnerUserID) {
                let pairingData = PairingData(
                    characterID: partnerUserID.uuidString,
                    name: partnerProfile.characterName ?? "Adventurer",
                    level: partnerProfile.level ?? 1,
                    characterClass: partnerProfile.characterClass,
                    partyID: nil,
                    avatarName: partnerProfile.avatarName
                )
                character.linkPartner(data: pairingData)
                
                // Create a Bond if one doesn't exist
                if bonds.isEmpty {
                    let newBond = Bond(memberIDs: [character.id, partnerUserID])
                    modelContext.insert(newBond)
                } else if let existingBond = bonds.first {
                    existingBond.addMember(partnerUserID)
                }
                
                try? modelContext.save()
            }
        } catch {
            print("Failed to fetch partner profile for local link: \(error)")
        }
    }
    
    private func rejectRequest(_ request: PartnerRequest) {
        Task {
            do {
                try await supabase.rejectPartnerRequest(request.id)
                incomingRequests.removeAll { $0.id == request.id }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    PartnerView()
        .environmentObject(GameEngine())
}
