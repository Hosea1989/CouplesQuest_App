import SwiftUI
import SwiftData

/// The connected-state dashboard showing party info, bond level, and quick actions
struct PartnerDashboardView: View {
    let character: PlayerCharacter
    let bond: Bond
    let onAssignTask: () -> Void
    let onSendNudge: () -> Void
    let onSendKudos: () -> Void
    let onSendChallenge: () -> Void
    let onViewLeaderboard: () -> Void
    let onUnlinkPartner: () -> Void
    var onInviteMember: (() -> Void)? = nil
    
    @Query(sort: \Goal.createdAt, order: .reverse) private var allGoals: [Goal]
    @Query private var allTasks: [GameTask]
    
    @State private var showUnlinkConfirm = false
    
    /// Party members' active goals (goals created by any party member, not self)
    private var partnerGoals: [Goal] {
        let memberIDs = Set(character.partyMembers.map(\.id))
        guard !memberIDs.isEmpty else {
            // Fallback to legacy single-partner
            guard let partnerID = character.partnerCharacterID else { return [] }
            return allGoals.filter { $0.createdBy == partnerID && $0.status == .active }
        }
        return allGoals.filter { memberIDs.contains($0.createdBy) && $0.status == .active }
    }
    
    /// Shared party goals
    private var sharedPartyGoals: [Goal] {
        allGoals.filter { $0.isPartyGoal && $0.status == .active }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Connection Header
            connectionHeader
            
            // Bond Level Card
            bondLevelCard
            
            // Quick Actions Grid
            quickActionsGrid
            
            // Partner's Goals (if any)
            if !partnerGoals.isEmpty {
                partnerGoalsCard
            }
            
            // Recent Activity / Stats
            partnerStatsCard
            
            // Bond Perks
            bondPerksCard
            
            // Unlink button
            unlinkButton
        }
    }
    
    /// Accent colors for party member avatars (cycling)
    private static let memberColors: [String] = ["AccentPurple", "AccentOrange", "AccentGreen"]
    
    // MARK: - Connection Header
    
    private var connectionHeader: some View {
        VStack(spacing: 16) {
            // Party header label
            HStack(spacing: 8) {
                Image(systemName: "person.3.fill")
                    .foregroundColor(Color("AccentPink"))
                Text("Party of \(bond.partySize)")
                    .font(.custom("Avenir-Heavy", size: 14))
                    .foregroundColor(Color("AccentPink"))
                
                if let streakLabel = bond.partyStreakTierLabel {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                        Text(streakLabel)
                            .font(.custom("Avenir-Heavy", size: 11))
                    }
                    .foregroundColor(Color("AccentOrange"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color("AccentOrange").opacity(0.15))
                    .clipShape(Capsule())
                }
            }
            
            // Member avatars in horizontal layout
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    // Self avatar
                    partyMemberAvatar(
                        name: character.name,
                        level: character.level,
                        className: character.characterClass?.rawValue,
                        color: "AccentGold",
                        imageData: character.avatarImageData,
                        icon: character.avatarIcon
                    )
                    
                    // Party member avatars
                    ForEach(Array(character.partyMembers.enumerated()), id: \.element.id) { index, member in
                        partyMemberAvatar(
                            name: member.name,
                            level: member.level,
                            className: member.className,
                            color: Self.memberColors[index % Self.memberColors.count],
                            imageData: nil,
                            icon: member.displayAvatarIcon
                        )
                    }
                    
                    // Invite slot (if room)
                    if bond.canAddMember {
                        Button(action: { onInviteMember?() }) {
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                                        .foregroundColor(Color("AccentGold").opacity(0.4))
                                        .frame(width: 56, height: 56)
                                    
                                    Image(systemName: "plus")
                                        .font(.title3)
                                        .foregroundColor(Color("AccentGold").opacity(0.7))
                                }
                                
                                Text("Invite")
                                    .font(.custom("Avenir-Medium", size: 11))
                                    .foregroundColor(Color("AccentGold").opacity(0.7))
                                
                                Text(" ")
                                    .font(.custom("Avenir-Medium", size: 10))
                            }
                            .frame(width: 70)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
    }
    
    /// Reusable party member avatar cell
    private func partyMemberAvatar(name: String, level: Int, className: String?, color: String, imageData: Data?, icon: String) -> some View {
        VStack(spacing: 4) {
            ZStack {
                if let imageData = imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(Circle())
                } else if UIImage(named: icon) != nil {
                    // Asset catalog avatar (e.g. "avatar_04")
                    Image(icon)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color(color).opacity(0.2))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(Color(color))
                }
            }
            
            Text(name)
                .font(.custom("Avenir-Heavy", size: 12))
                .lineLimit(1)
            
            Text("Lv.\(level)")
                .font(.custom("Avenir-Medium", size: 10))
                .foregroundColor(Color(color))
            
            if let cls = className {
                Text(cls)
                    .font(.custom("Avenir-Medium", size: 9))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(width: 70)
    }
    
    // MARK: - Bond Level Card
    
    private var bondLevelCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "heart.circle.fill")
                    .foregroundColor(Color("AccentPink"))
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Bond Level \(bond.bondLevel)")
                        .font(.custom("Avenir-Heavy", size: 16))
                    Text(bond.bondTitle)
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(Color("AccentPink"))
                }
                
                Spacer()
                
                // Bond level badge
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color("AccentPink"), Color("AccentPurple")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Text("\(bond.bondLevel)")
                        .font(.custom("Avenir-Heavy", size: 18))
                        .foregroundColor(.white)
                }
            }
            
            // Bond EXP Progress Bar
            VStack(spacing: 6) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.2))
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [Color("AccentPink"), Color("AccentPurple")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * bond.levelProgress)
                    }
                }
                .frame(height: 8)
                
                HStack {
                    Text("\(bond.bondEXP) / \(bond.expToNextLevel) Bond EXP")
                        .font(.custom("Avenir-Medium", size: 11))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let nextPerk = bond.nextPerk {
                        Text("Next: \(nextPerk.rawValue) (Lv.\(nextPerk.requiredLevel))")
                            .font(.custom("Avenir-Medium", size: 11))
                            .foregroundColor(Color("AccentPink"))
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // MARK: - Quick Actions Grid
    
    private var quickActionsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.custom("Avenir-Heavy", size: 16))
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                PartnerActionButton(
                    icon: "plus.circle.fill",
                    label: "Assign Task",
                    color: Color("AccentGold"),
                    action: onAssignTask
                )
                
                PartnerActionButton(
                    icon: "hand.thumbsup.fill",
                    label: "Send Kudos",
                    color: Color("AccentGreen"),
                    action: onSendKudos
                )
                
                PartnerActionButton(
                    icon: "bell.fill",
                    label: "Send Nudge",
                    color: Color("AccentPurple"),
                    action: onSendNudge
                )
                
                PartnerActionButton(
                    icon: "flag.fill",
                    label: "Challenge",
                    color: Color("AccentOrange"),
                    action: onSendChallenge
                )
            }
            
            // Leaderboard button
            Button(action: onViewLeaderboard) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                    Text("View Leaderboard")
                        .font(.custom("Avenir-Heavy", size: 14))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundColor(Color("AccentGold"))
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("AccentGold").opacity(0.1))
                )
            }
        }
    }
    
    // MARK: - Partner Stats Card
    
    private var partnerStatsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Party Stats")
                .font(.custom("Avenir-Heavy", size: 16))
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                BondStatBadge(
                    icon: "paperplane.fill",
                    value: "\(bond.partnerTasksCompleted)",
                    label: "Party Tasks",
                    color: Color("AccentGold")
                )
                
                BondStatBadge(
                    icon: "rectangle.on.rectangle",
                    value: "\(bond.dutyBoardTasksClaimed)",
                    label: "Board Claims",
                    color: Color("AccentPurple")
                )
                
                BondStatBadge(
                    icon: "flame.fill",
                    value: "\(bond.partyStreakDays)",
                    label: "Party Streak",
                    color: Color("AccentOrange")
                )
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                BondStatBadge(
                    icon: "hand.thumbsup.fill",
                    value: "\(bond.kudosSent)",
                    label: "Kudos Sent",
                    color: Color("AccentGreen")
                )
                
                BondStatBadge(
                    icon: "shield.lefthalf.filled",
                    value: "\(bond.coopDungeonsCompleted)",
                    label: "Co-op Runs",
                    color: Color("AccentPurple")
                )
                
                BondStatBadge(
                    icon: "person.3.fill",
                    value: "\(bond.partySize)",
                    label: "Members",
                    color: Color("AccentPink")
                )
            }
            
            // Party duration
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.secondary)
                Text("Party for \(daysSincePaired) days")
                    .font(.custom("Avenir-Medium", size: 13))
                    .foregroundColor(.secondary)
                Spacer()
                Text("Total Bond EXP: \(bond.totalBondEXP)")
                    .font(.custom("Avenir-Medium", size: 13))
                    .foregroundColor(Color("AccentPink"))
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
    }
    
    private var daysSincePaired: Int {
        let days = Calendar.current.dateComponents([.day], from: bond.createdAt, to: Date()).day ?? 0
        return max(1, days)
    }
    
    // MARK: - Partner Goals Card
    
    private var partnerGoalsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flag.fill")
                    .foregroundColor(Color("AccentGold"))
                Text("Party Goals")
                    .font(.custom("Avenir-Heavy", size: 16))
                Spacer()
            }
            
            ForEach(partnerGoals.prefix(3)) { goal in
                let progress = goalProgress(for: goal)
                
                HStack(spacing: 12) {
                    Image(systemName: goal.category.icon)
                        .font(.callout)
                        .foregroundColor(Color(goal.category.color))
                        .frame(width: 28)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(goal.title)
                            .font(.custom("Avenir-Medium", size: 14))
                            .lineLimit(1)
                        
                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.secondary.opacity(0.15))
                                    .frame(height: 6)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color(goal.category.color))
                                    .frame(width: geo.size.width * CGFloat(progress), height: 6)
                            }
                        }
                        .frame(height: 6)
                    }
                    
                    Text("\(Int(progress * 100))%")
                        .font(.custom("Avenir-Heavy", size: 13))
                        .foregroundColor(Color(goal.category.color))
                        .frame(width: 36, alignment: .trailing)
                    
                    // Quick action: send a task to help
                    Button(action: onAssignTask) {
                        Image(systemName: "paperplane.fill")
                            .font(.caption)
                            .foregroundColor(Color("AccentPink"))
                            .padding(6)
                            .background(Circle().fill(Color("AccentPink").opacity(0.12)))
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
    
    private func goalProgress(for goal: Goal) -> Double {
        GameEngine.calculateGoalProgress(goal: goal, tasks: allTasks)
    }
    
    // MARK: - Bond Perks Card
    
    private var bondPerksCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bond Perks")
                .font(.custom("Avenir-Heavy", size: 16))
            
            ForEach(BondPerk.allCases, id: \.self) { perk in
                HStack(spacing: 12) {
                    Image(systemName: perk.icon)
                        .foregroundColor(perk.requiredLevel <= bond.bondLevel ? Color("AccentGold") : .secondary.opacity(0.4))
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(perk.rawValue)
                            .font(.custom("Avenir-Heavy", size: 14))
                            .foregroundColor(perk.requiredLevel <= bond.bondLevel ? .primary : .secondary.opacity(0.5))
                        Text(perk.description)
                            .font(.custom("Avenir-Medium", size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if perk.requiredLevel <= bond.bondLevel {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color("AccentGreen"))
                    } else {
                        Text("Lv.\(perk.requiredLevel)")
                            .font(.custom("Avenir-Heavy", size: 12))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                }
                
                if perk != BondPerk.allCases.last {
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
    
    // MARK: - Unlink Button
    
    private var unlinkButton: some View {
        Button(action: { showUnlinkConfirm = true }) {
            HStack {
                Image(systemName: "link.badge.plus")
                    .rotationEffect(.degrees(45))
                Text("Leave Party")
            }
            .font(.custom("Avenir-Medium", size: 14))
            .foregroundColor(.red.opacity(0.7))
            .padding(.vertical, 12)
        }
        .confirmationDialog(
            "Leave Party?",
            isPresented: $showUnlinkConfirm,
            titleVisibility: .visible
        ) {
            Button("Leave", role: .destructive) {
                onUnlinkPartner()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove you from the party. Your bond progress will be preserved if you rejoin.")
        }
    }
}

// MARK: - Partner Action Button

struct PartnerActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(label)
                    .font(.custom("Avenir-Medium", size: 12))
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.12))
            )
        }
    }
}

// MARK: - Bond Stat Badge

struct BondStatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundColor(color)
            
            Text(value)
                .font(.custom("Avenir-Heavy", size: 18))
            
            Text(label)
                .font(.custom("Avenir-Medium", size: 10))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.08))
        )
    }
}

#Preview {
    let character = PlayerCharacter(name: "Hero")
    let bond = Bond(partnerID: UUID())
    
    ScrollView {
        PartnerDashboardView(
            character: character,
            bond: bond,
            onAssignTask: {},
            onSendNudge: {},
            onSendKudos: {},
            onSendChallenge: {},
            onViewLeaderboard: {},
            onUnlinkPartner: {},
            onInviteMember: {}
        )
        .padding()
    }
    .background(Color("BackgroundTop"))
}
