import SwiftUI
import SwiftData
import Supabase

/// Lobby screen shown after the host taps "Run with Party."
/// Displays party member status and waits for responses before starting.
struct DungeonLobbyView: View {
    let dungeon: Dungeon
    let character: PlayerCharacter
    let bond: Bond
    let onStart: ([PlayerCharacter]) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    
    @State private var inviteID: UUID?
    @State private var memberStatuses: [UUID: MemberLobbyStatus] = [:]
    @State private var realtimeChannel: RealtimeChannelV2?
    @State private var timeRemaining: TimeInterval = 120  // 2 minutes
    @State private var timerActive = true
    @State private var isCreatingInvite = true
    @State private var hasStarted = false
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    /// All party member IDs (including self)
    private var allMemberIDs: [UUID] {
        bond.memberIDs
    }
    
    /// Party members (excluding self) from cached data
    private var otherMembers: [CachedPartyMember] {
        character.partyMembers
    }
    
    /// Whether the host can start (always true — they can start any time)
    private var canStart: Bool {
        !isCreatingInvite && !hasStarted
    }
    
    /// Count of members who accepted
    private var acceptedCount: Int {
        memberStatuses.values.filter { $0 == .accepted }.count
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color("BackgroundTop"), Color("BackgroundBottom")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Drag indicator
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Dungeon Header
                        dungeonHeader
                        
                        // Timer
                        timerDisplay
                        
                        // Party Members
                        partyMembersList
                        
                        // Status Message
                        statusMessage
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100) // Space for bottom buttons
                }
                
                Spacer()
                
                // Bottom Buttons
                bottomButtons
            }
        }
        .task {
            await createInviteAndNotify()
        }
        .onDisappear {
            cleanUp()
        }
        .onReceive(timer) { _ in
            guard timerActive else { return }
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                // Auto-cancel on expire
                cancelInvite()
            }
        }
    }
    
    // MARK: - Dungeon Header
    
    private var dungeonHeader: some View {
        VStack(spacing: 12) {
            // Dungeon icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color("AccentPurple").opacity(0.6), Color("AccentPurple").opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                
                Image(systemName: dungeon.theme.icon)
                    .font(.system(size: 32))
                    .foregroundColor(Color("AccentGold"))
            }
            
            Text(dungeon.name)
                .font(.custom("Avenir-Heavy", size: 22))
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                Label("Lv.\(dungeon.levelRequirement)+", systemImage: "shield.fill")
                Label(dungeon.difficulty.rawValue.capitalized, systemImage: "flame.fill")
                Label("\(dungeon.roomCount) Rooms", systemImage: "door.left.hand.open")
            }
            .font(.custom("Avenir-Medium", size: 12))
            .foregroundColor(.white.opacity(0.7))
        }
        .padding(.top, 8)
    }
    
    // MARK: - Timer Display
    
    private var timerDisplay: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.fill")
                .foregroundColor(timeRemaining < 30 ? .red : Color("AccentGold"))
            
            Text("Waiting for party... \(formattedTime)")
                .font(.custom("Avenir-Medium", size: 14))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.1))
        )
    }
    
    private var formattedTime: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Party Members List
    
    private var partyMembersList: some View {
        VStack(spacing: 12) {
            Text("PARTY")
                .font(.custom("Avenir-Heavy", size: 13))
                .foregroundColor(Color("AccentGold"))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Host (self) — always ready
            memberRow(
                name: character.name,
                level: character.level,
                className: character.characterClass?.rawValue,
                avatarIcon: character.avatarIcon,
                status: .host
            )
            
            // Other members
            ForEach(otherMembers) { member in
                memberRow(
                    name: member.name,
                    level: member.level,
                    className: member.className,
                    avatarIcon: member.displayAvatarIcon,
                    status: memberStatuses[member.id] ?? .pending
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground").opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color("AccentPurple").opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func memberRow(name: String, level: Int, className: String?, avatarIcon: String, status: MemberLobbyStatus) -> some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color("AccentPurple").opacity(0.3))
                    .frame(width: 44, height: 44)
                
                if let uiImage = UIImage(named: avatarIcon) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                } else {
                    Image(systemName: avatarIcon)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
            }
            
            // Name + details
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.custom("Avenir-Heavy", size: 15))
                    .foregroundColor(.white)
                
                HStack(spacing: 6) {
                    Text("Lv.\(level)")
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.white.opacity(0.6))
                    
                    if let cls = className {
                        Text("•")
                            .foregroundColor(.white.opacity(0.3))
                        Text(cls)
                            .font(.custom("Avenir-Medium", size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            
            Spacer()
            
            // Status badge
            statusBadge(for: status)
        }
        .padding(.vertical, 6)
    }
    
    @ViewBuilder
    private func statusBadge(for status: MemberLobbyStatus) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
            
            Text(status.label)
                .font(.custom("Avenir-Heavy", size: 12))
                .foregroundColor(status.color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(status.color.opacity(0.15))
        )
    }
    
    // MARK: - Status Message
    
    private var statusMessage: some View {
        Group {
            if isCreatingInvite {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(.white)
                    Text("Sending invites...")
                        .font(.custom("Avenir-Medium", size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
            } else {
                Text("\(acceptedCount)/\(allMemberIDs.count) party members ready")
                    .font(.custom("Avenir-Medium", size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    // MARK: - Bottom Buttons
    
    private var bottomButtons: some View {
        VStack(spacing: 10) {
            // Start Dungeon
            Button(action: startDungeon) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start Dungeon")
                }
                .font(.custom("Avenir-Heavy", size: 16))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: canStart
                            ? [Color("AccentPurple"), Color("AccentPurple").opacity(0.7)]
                            : [Color.gray.opacity(0.5), Color.gray.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!canStart)
            
            // Cancel
            Button(action: { cancelInvite() }) {
                Text("Cancel")
                    .font(.custom("Avenir-Medium", size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 24)
        .background(
            LinearGradient(
                colors: [Color("BackgroundBottom").opacity(0), Color("BackgroundBottom")],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
            .allowsHitTesting(false)
        )
    }
    
    // MARK: - Actions
    
    private func createInviteAndNotify() async {
        guard let partyID = bond.supabasePartyID else {
            isCreatingInvite = false
            return
        }
        
        // Initialize statuses
        for member in otherMembers {
            memberStatuses[member.id] = .pending
        }
        
        do {
            // Create the invite + response rows in Supabase
            let id = try await SupabaseService.shared.createDungeonInvite(
                partyID: partyID,
                dungeonID: dungeon.id,
                dungeonName: dungeon.name,
                memberIDs: allMemberIDs
            )
            inviteID = id
            
            // Subscribe to realtime updates on responses
            realtimeChannel = await SupabaseService.shared.subscribeToDungeonInviteResponses(inviteID: id) { row in
                withAnimation(.easeInOut(duration: 0.3)) {
                    memberStatuses[row.userID] = row.response == "accepted" ? .accepted : .declined
                }
            }
            
            // Send push notifications to all party members
            await PushNotificationService.shared.notifyPartyDungeonInvite(
                memberIDs: allMemberIDs,
                fromName: character.name,
                dungeonName: dungeon.name
            )
            
            isCreatingInvite = false
            
        } catch {
            print("❌ Failed to create dungeon invite: \(error)")
            isCreatingInvite = false
        }
    }
    
    private func startDungeon() {
        guard !hasStarted else { return }
        hasStarted = true
        timerActive = false
        
        // Mark invite as started
        if let inviteID = inviteID {
            Task {
                try? await SupabaseService.shared.updateDungeonInviteStatus(inviteID: inviteID, status: "started")
            }
        }
        
        // Build the party: host + accepted members as proxies
        var coopParty: [PlayerCharacter] = [character]
        for member in otherMembers {
            if memberStatuses[member.id] == .accepted || memberStatuses[member.id] == .pending {
                // Use proxy stats for party members (same as existing behavior)
                if let proxy = PartnerProxy.from(character: character) {
                    coopParty.append(proxy)
                }
            }
        }
        
        dismiss()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onStart(coopParty)
        }
    }
    
    private func cancelInvite() {
        timerActive = false
        
        if let inviteID = inviteID {
            Task {
                try? await SupabaseService.shared.updateDungeonInviteStatus(inviteID: inviteID, status: "cancelled")
            }
        }
        
        dismiss()
    }
    
    private func cleanUp() {
        timerActive = false
        if let channel = realtimeChannel {
            Task {
                await SupabaseService.shared.unsubscribeChannel(channel)
            }
        }
    }
}

// MARK: - Member Status

enum MemberLobbyStatus {
    case host
    case pending
    case accepted
    case declined
    
    var label: String {
        switch self {
        case .host: return "Host"
        case .pending: return "Waiting..."
        case .accepted: return "Accepted"
        case .declined: return "Declined"
        }
    }
    
    var color: Color {
        switch self {
        case .host: return Color("AccentGold")
        case .pending: return .orange
        case .accepted: return .green
        case .declined: return .red
        }
    }
}
