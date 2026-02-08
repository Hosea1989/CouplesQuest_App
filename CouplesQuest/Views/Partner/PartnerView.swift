import SwiftUI
import SwiftData

struct PartnerView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var gameEngine: GameEngine
    @Query private var characters: [PlayerCharacter]
    @Query private var bonds: [Bond]
    @Query(sort: \PartnerInteraction.createdAt, order: .reverse) private var interactions: [PartnerInteraction]
    
    @State private var showPairingSheet = false
    @State private var showAssignTaskSheet = false
    @State private var showLeaderboardSheet = false
    @State private var showNudgeConfirm = false
    @State private var showKudosConfirm = false
    @State private var showChallengeConfirm = false
    @State private var showInteractionSuccess = false
    @State private var interactionSuccessMessage = ""
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
                                onUnlinkPartner: { unlinkPartner() }
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
                            // Not Connected View
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
            .navigationTitle("Partner")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showPairingSheet) {
                QRPairingView()
            }
            .sheet(isPresented: $showAssignTaskSheet) {
                AssignTaskView()
            }
            .sheet(isPresented: $showLeaderboardSheet) {
                CouplesLeaderboardView()
            }
            .alert("Send Nudge", isPresented: $showNudgeConfirm) {
                Button("Send") { sendNudge() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Remind your partner that their quest log awaits!")
            }
            .alert("Send Kudos", isPresented: $showKudosConfirm) {
                Button("Send") { sendKudos() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Give your partner a thumbs up for their hard work!")
            }
            .alert("Send Challenge", isPresented: $showChallengeConfirm) {
                Button("Send") { sendChallenge() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Challenge your partner to complete 3 tasks today!")
            }
            .alert("Sent!", isPresented: $showInteractionSuccess) {
                Button("OK") {}
            } message: {
                Text(interactionSuccessMessage)
            }
        }
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
                                    Text("+\(task.expReward) EXP")
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
        interactionSuccessMessage = "Nudge sent to \(character.partnerName ?? "your partner")!"
        showInteractionSuccess = true
    }
    
    private func sendKudos() {
        guard let character = character, let bond = bond else { return }
        let interaction = gameEngine.sendKudos(from: character, bond: bond, message: nil)
        modelContext.insert(interaction)
        interactionSuccessMessage = "Kudos sent! +\(GameEngine.bondEXPForKudos) Bond EXP"
        showInteractionSuccess = true
    }
    
    private func sendChallenge() {
        guard let character = character, let bond = bond else { return }
        let interaction = gameEngine.sendChallenge(from: character, bond: bond, message: nil)
        modelContext.insert(interaction)
        interactionSuccessMessage = "Challenge sent to \(character.partnerName ?? "your partner")!"
        showInteractionSuccess = true
    }
    
    private func claimDutyBoardTask(_ task: GameTask) {
        guard let character = character, let bond = bond else { return }
        gameEngine.claimDutyBoardTask(task, character: character, bond: bond)
    }
    
    private func unlinkPartner() {
        character?.unlinkPartner()
        // Keep the bond for history, but could delete if preferred
    }
}

// MARK: - Partner Not Connected View

struct PartnerNotConnectedView: View {
    let onPair: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
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
                Text("Connect with Partner")
                    .font(.custom("Avenir-Heavy", size: 24))
                
                Text("Link with your partner to share tasks,\ncompete on the leaderboard, and quest together!")
                    .font(.custom("Avenir-Medium", size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onPair) {
                HStack {
                    Image(systemName: "qrcode.viewfinder")
                    Text("Pair with Partner")
                }
                .font(.custom("Avenir-Heavy", size: 16))
                .foregroundColor(.black)
                .padding(.horizontal, 32)
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
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
    }
}

// MARK: - Partner Features Card

struct PartnerFeaturesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Partner Features")
                .font(.custom("Avenir-Heavy", size: 18))
            
            FeatureRow(
                icon: "qrcode.viewfinder",
                title: "QR Code Pairing",
                description: "Scan to instantly connect with your partner"
            )
            
            FeatureRow(
                icon: "heart.circle.fill",
                title: "Bond Level System",
                description: "Grow your bond together and unlock perks"
            )
            
            FeatureRow(
                icon: "paperplane.fill",
                title: "Assign Tasks",
                description: "Send tasks directly to your partner"
            )
            
            FeatureRow(
                icon: "rectangle.on.rectangle",
                title: "Shared Duty Board",
                description: "Both can claim tasks from a shared pool"
            )
            
            FeatureRow(
                icon: "chart.bar.fill",
                title: "Leaderboard",
                description: "Friendly competition to stay motivated"
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

#Preview {
    PartnerView()
        .environmentObject(GameEngine())
}
