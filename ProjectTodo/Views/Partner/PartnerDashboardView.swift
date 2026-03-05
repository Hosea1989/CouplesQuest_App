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
    var activeChallenge: PartyChallenge? = nil
    var onSetChallenge: (() -> Void)? = nil
    
    @Query(sort: \Goal.createdAt, order: .reverse) private var allGoals: [Goal]
    @Query private var allTasks: [GameTask]
    
    @State private var showUnlinkConfirm = false
    @State private var memberToRemove: CachedPartyMember?
    @State private var showRemoveMemberConfirm = false
    @State private var inspectedMember: CachedPartyMember?
    @State private var showInspectSheet = false
    
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
            // Party Leaderboard Preview
            leaderboardPreviewCard
            
            // Connection Header
            connectionHeader
            
            // Bond Level Card
            bondLevelCard
            
            // Quick Actions Grid
            quickActionsGrid
            
            // Member Spotlight
            memberSpotlightCard
            
            // Active Party Challenge (or Set Challenge button for leader)
            partyChallengeSection
            
            // Shared Goals (NavigationLink to GoalsView filtered to party goals)
            sharedGoalsCard
            
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
        .confirmationDialog(
            "Remove \(memberToRemove?.name ?? "Member")?",
            isPresented: $showRemoveMemberConfirm,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                if let member = memberToRemove {
                    removeMember(member)
                }
            }
            Button("Cancel", role: .cancel) {
                memberToRemove = nil
            }
        } message: {
            Text("This will remove \(memberToRemove?.name ?? "this member") from your party. They can rejoin later by scanning your QR code.")
        }
        .sheet(isPresented: $showInspectSheet) {
            if let member = inspectedMember {
                PlayerInspectView(memberID: member.id, cachedMember: member)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
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
                Text("Party of \(1 + character.partyMembers.count)")
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
                        icon: character.avatarIcon,
                        isLeader: bond.isLeader(character.id)
                    )
                    
                    // Party member avatars (tap to inspect, long-press for actions)
                    ForEach(Array(character.partyMembers.enumerated()), id: \.element.id) { index, member in
                        partyMemberAvatar(
                            name: member.name,
                            level: member.level,
                            className: member.className,
                            color: Self.memberColors[index % Self.memberColors.count],
                            imageData: nil,
                            icon: member.displayAvatarIcon,
                            isLeader: bond.isLeader(member.id)
                        )
                        .onTapGesture {
                            inspectedMember = member
                            showInspectSheet = true
                        }
                        .contextMenu {
                            // Send Nudge
                            Button {
                                onSendNudge()
                            } label: {
                                Label("Send Nudge", systemImage: "bell.fill")
                            }
                            
                            // Send Kudos
                            Button {
                                onSendKudos()
                            } label: {
                                Label("Send Kudos", systemImage: "hand.thumbsup.fill")
                            }
                            
                            // Send Challenge
                            Button {
                                onSendChallenge()
                            } label: {
                                Label("Challenge", systemImage: "flag.fill")
                            }
                            
                            // Assign Task
                            Button {
                                onAssignTask()
                            } label: {
                                Label("Assign Task", systemImage: "plus.circle.fill")
                            }
                            
                            Divider()
                            
                            // Remove from party (only visible to party leader)
                            if bond.isLeader(character.id) {
                                Button(role: .destructive) {
                                    memberToRemove = member
                                    showRemoveMemberConfirm = true
                                } label: {
                                    Label("Remove from Party", systemImage: "person.badge.minus")
                                }
                            }
                        }
                    }
                    
                    // Invite slots (show empty slots up to max 4)
                    let totalMembers = 1 + character.partyMembers.count
                    let emptySlots = max(0, 4 - totalMembers)
                    if emptySlots > 0 {
                        ForEach(0..<emptySlots, id: \.self) { _ in
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
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
    }
    
    /// Reusable party member avatar cell
    private func partyMemberAvatar(name: String, level: Int, className: String?, color: String, imageData: Data?, icon: String, isLeader: Bool = false) -> some View {
        VStack(spacing: 4) {
            ZStack(alignment: .top) {
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
                
                // Leader crown badge
                if isLeader {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color("AccentGold"))
                        .offset(y: -6)
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
    
    // MARK: - Party Challenge Section
    
    // MARK: - Shared Goals
    
    private var sharedGoalsCard: some View {
        NavigationLink(destination: GoalsView(partyOnly: true)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "target")
                        .font(.title3)
                        .foregroundColor(Color("AccentPink"))
                    
                    Text("Shared Goals")
                        .font(.custom("Avenir-Heavy", size: 16))
                    
                    Spacer()
                    
                    if !sharedPartyGoals.isEmpty {
                        Text("\(sharedPartyGoals.count) active")
                            .font(.custom("Avenir-Medium", size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if sharedPartyGoals.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.dashed")
                            .font(.callout)
                            .foregroundColor(Color("AccentPink").opacity(0.6))
                        Text("Create party goals everyone works toward together")
                            .font(.custom("Avenir-Medium", size: 13))
                            .foregroundColor(.secondary)
                    }
                } else {
                    ForEach(sharedPartyGoals.prefix(2)) { goal in
                        HStack(spacing: 10) {
                            Image(systemName: "person.3.fill")
                                .font(.caption)
                                .foregroundColor(Color("AccentPink"))
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(goal.title)
                                    .font(.custom("Avenir-Medium", size: 13))
                                    .lineLimit(1)
                                    .foregroundColor(.primary)
                                
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Color.secondary.opacity(0.12))
                                            .frame(height: 5)
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Color("AccentPink"))
                                            .frame(width: geo.size.width * CGFloat(goal.partyGoalProgress), height: 5)
                                    }
                                }
                                .frame(height: 5)
                            }
                            
                            Text("\(Int(goal.partyGoalProgress * 100))%")
                                .font(.custom("Avenir-Heavy", size: 12))
                                .foregroundColor(Color("AccentPink"))
                                .frame(width: 32, alignment: .trailing)
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
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var partyChallengeSection: some View {
        if let challenge = activeChallenge, challenge.isActive && !challenge.isExpired {
            activeChallengeCard(challenge)
        } else if bond.isLeader(character.id) {
            // Leader can start a new challenge
            Button {
                onSetChallenge?()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "flag.checkered")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color("AccentGold"), Color("AccentOrange")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Set Party Challenge")
                            .font(.custom("Avenir-Heavy", size: 14))
                        Text("Rally your party toward a shared goal")
                            .font(.custom("Avenir-Medium", size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Color("AccentGold"))
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color("AccentGold").opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color("AccentGold").opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    private func activeChallengeCard(_ challenge: PartyChallenge) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: challenge.challengeType.icon)
                    .foregroundColor(Color(challenge.challengeType.color))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(challenge.title)
                        .font(.custom("Avenir-Heavy", size: 14))
                    Text(challenge.timeRemainingLabel)
                        .font(.custom("Avenir-Medium", size: 11))
                        .foregroundColor(Color("AccentOrange"))
                }
                
                Spacer()
                
                // Overall party progress
                Text("\(Int(challenge.partyProgressFraction * 100))%")
                    .font(.custom("Avenir-Heavy", size: 18))
                    .foregroundColor(Color(challenge.challengeType.color))
            }
            
            // Per-member progress bars
            ForEach(challenge.memberProgress) { member in
                HStack(spacing: 8) {
                    Text(member.memberName)
                        .font(.custom("Avenir-Medium", size: 12))
                        .frame(width: 70, alignment: .leading)
                        .lineLimit(1)
                    
                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondary.opacity(0.15))
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    member.current >= challenge.targetCount
                                    ? Color("AccentGreen")
                                    : Color(challenge.challengeType.color)
                                )
                                .frame(width: geo.size.width * min(1.0, CGFloat(member.current) / CGFloat(max(1, challenge.targetCount))))
                        }
                    }
                    .frame(height: 8)
                    
                    Text("\(member.current)/\(challenge.targetCount)")
                        .font(.custom("Avenir-Heavy", size: 11))
                        .foregroundColor(
                            member.current >= challenge.targetCount
                            ? Color("AccentGreen")
                            : .secondary
                        )
                        .frame(width: 40, alignment: .trailing)
                    
                    if member.current >= challenge.targetCount {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(Color("AccentGreen"))
                    }
                }
            }
            
            // Reward reminder
            HStack(spacing: 4) {
                Image(systemName: "gift.fill")
                    .font(.caption2)
                    .foregroundColor(Color("AccentGold"))
                Text("Reward: +\(challenge.rewardBondEXP) Bond EXP · +\(challenge.rewardGold) Gold per member")
                    .font(.custom("Avenir-Medium", size: 10))
                    .foregroundColor(.secondary)
            }
            
            if challenge.isFullPartyComplete && !challenge.partyBonusAwarded {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(Color("AccentGreen"))
                    Text("All members finished! Party bonus: +\(challenge.partyBonusBondEXP) Bond EXP each")
                        .font(.custom("Avenir-Heavy", size: 10))
                        .foregroundColor(Color("AccentGreen"))
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color("CardBackground"))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color(challenge.challengeType.color).opacity(0.3), lineWidth: 1)
                )
        )
    }
    
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
                    icon: "trophy.fill",
                    value: "\(topStreak)",
                    label: "Top Streak",
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
                    value: "\(1 + character.partyMembers.count)",
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
    
    // MARK: - Remove Member
    
    private func removeMember(_ member: CachedPartyMember) {
        // Remove locally
        character.removePartyMember(member.id)
        
        // Also clear partner_id in Supabase if this was the linked partner
        if character.partnerCharacterID == nil {
            // Partner fields were cleared by removePartyMember, sync to cloud
            Task {
                try? await SupabaseService.shared.unlinkPartner()
            }
        }
        
        // Remove from bond
        bond.removeMember(member.id)
        
        AudioManager.shared.play(.success)
        ToastManager.shared.showInfo(
            "Member Removed",
            subtitle: "\(member.name) has been removed from the party"
        )
        memberToRemove = nil
    }
    
    private var daysSincePaired: Int {
        let days = Calendar.current.dateComponents([.day], from: bond.createdAt, to: Date()).day ?? 0
        return max(1, days)
    }
    
    /// Highest current streak among all party members (including self)
    private var topStreak: Int {
        let myStreak = character.currentStreak
        let memberStreaks = character.partyMembers.compactMap { $0.currentStreak }
        return ([myStreak] + memberStreaks).max() ?? 0
    }
    
    // MARK: - Leaderboard Preview Card
    
    /// Lightweight entry representing a party member for ranking
    private struct LeaderboardEntry: Identifiable {
        let id: UUID
        let name: String
        let tasks: Int
        let level: Int
        let avatarIcon: String
        let color: String
        let isSelf: Bool
    }
    
    /// All party members (including self) sorted by tasks completed descending
    private var leaderboardEntries: [LeaderboardEntry] {
        var entries: [LeaderboardEntry] = []
        
        // Self
        entries.append(LeaderboardEntry(
            id: character.id,
            name: character.name,
            tasks: character.tasksCompleted,
            level: character.level,
            avatarIcon: character.avatarIcon ?? "person.fill",
            color: "AccentGold",
            isSelf: true
        ))
        
        // Party members
        for (index, member) in character.partyMembers.enumerated() {
            entries.append(LeaderboardEntry(
                id: member.id,
                name: member.name,
                tasks: member.tasksCompleted ?? 0,
                level: member.level,
                avatarIcon: member.displayAvatarIcon,
                color: Self.memberColors[index % Self.memberColors.count],
                isSelf: false
            ))
        }
        
        return entries.sorted { $0.tasks > $1.tasks }
    }
    
    private var leaderboardPreviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(Color("AccentGold"))
                Text("Party Leaderboard")
                    .font(.custom("Avenir-Heavy", size: 16))
                Spacer()
            }
            
            ForEach(Array(leaderboardEntries.enumerated()), id: \.element.id) { rank, entry in
                HStack(spacing: 10) {
                    // Rank medal
                    ZStack {
                        Circle()
                            .fill(rankColor(for: rank).opacity(0.15))
                            .frame(width: 26, height: 26)
                        Text(rankLabel(for: rank))
                            .font(.system(size: 13))
                    }
                    
                    // Avatar
                    Image(systemName: entry.avatarIcon)
                        .font(.callout)
                        .foregroundColor(Color(entry.color))
                        .frame(width: 28, height: 28)
                        .background(Color(entry.color).opacity(0.12))
                        .clipShape(Circle())
                    
                    // Name + level
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 4) {
                            Text(entry.name)
                                .font(.custom("Avenir-Heavy", size: 14))
                            if entry.isSelf {
                                Text("(You)")
                                    .font(.custom("Avenir-Medium", size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        Text("Lv.\(entry.level)")
                            .font(.custom("Avenir-Medium", size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Task count + bar
                    let maxTasks = leaderboardEntries.first?.tasks ?? 1
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("\(entry.tasks)")
                            .font(.custom("Avenir-Heavy", size: 16))
                            .foregroundColor(Color(entry.color))
                        
                        GeometryReader { geo in
                            let fraction = maxTasks > 0 ? Double(entry.tasks) / Double(maxTasks) : 0
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(entry.color).opacity(0.25))
                                .frame(width: geo.size.width)
                                .overlay(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color(entry.color))
                                        .frame(width: geo.size.width * fraction)
                                }
                        }
                        .frame(width: 60, height: 4)
                    }
                }
                
                if rank < leaderboardEntries.count - 1 {
                    Divider()
                }
            }
            
            // View Full Leaderboard button
            Button(action: onViewLeaderboard) {
                HStack {
                    Spacer()
                    Text("View Full Leaderboard")
                        .font(.custom("Avenir-Heavy", size: 13))
                        .foregroundColor(Color("AccentGold"))
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Color("AccentGold"))
                    Spacer()
                }
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color("AccentGold").opacity(0.1))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
    }
    
    private func rankColor(for rank: Int) -> Color {
        switch rank {
        case 0: return Color("AccentGold")
        case 1: return Color.gray
        case 2: return Color("AccentOrange")
        default: return Color.secondary
        }
    }
    
    private func rankLabel(for rank: Int) -> String {
        switch rank {
        case 0: return "🥇"
        case 1: return "🥈"
        case 2: return "🥉"
        default: return "#\(rank + 1)"
        }
    }
    
    // MARK: - Member Spotlight Card
    
    /// The party member (or self) spotlighted today — rotates daily deterministically
    private var spotlightEntry: LeaderboardEntry? {
        let entries = leaderboardEntries
        guard !entries.isEmpty else { return nil }
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let index = dayOfYear % entries.count
        return entries[index]
    }
    
    /// Fun tagline for the spotlighted member based on their standout quality
    private func spotlightTagline(for entry: LeaderboardEntry) -> (title: String, icon: String) {
        let allEntries = leaderboardEntries
        
        // Check if they have the highest streak
        let myStreak = character.currentStreak
        let streaks: [(UUID, Int)] = [(character.id, myStreak)] +
            character.partyMembers.map { ($0.id, $0.currentStreak ?? 0) }
        if let topStreaker = streaks.max(by: { $0.1 < $1.1 }), topStreaker.0 == entry.id, topStreaker.1 > 0 {
            return ("Streak Champion", "flame.fill")
        }
        
        // Check if they have the most tasks
        if let topTasker = allEntries.first, topTasker.id == entry.id, topTasker.tasks > 0 {
            return ("Task Machine", "bolt.fill")
        }
        
        // Check if they have the highest level
        if let topLevel = allEntries.max(by: { $0.level < $1.level }), topLevel.id == entry.id {
            return ("Party Veteran", "star.fill")
        }
        
        // Check for highest individual stat
        if entry.isSelf {
            let statValues = [
                ("Strength", character.stats.strength),
                ("Wisdom", character.stats.wisdom),
                ("Charisma", character.stats.charisma),
                ("Dexterity", character.stats.dexterity),
                ("Luck", character.stats.luck),
                ("Defense", character.stats.defense)
            ]
            if let best = statValues.max(by: { $0.1 < $1.1 }), best.1 > 0 {
                return ("\(best.0) Master", "sparkles")
            }
        } else if let member = character.partyMembers.first(where: { $0.id == entry.id }) {
            let stats = [
                ("Strength", member.strength ?? 0),
                ("Wisdom", member.wisdom ?? 0),
                ("Charisma", member.charisma ?? 0),
                ("Dexterity", member.dexterity ?? 0),
                ("Luck", member.luck ?? 0),
                ("Defense", member.defense ?? 0)
            ]
            if let best = stats.max(by: { $0.1 < $1.1 }), best.1 > 0 {
                return ("\(best.0) Master", "sparkles")
            }
        }
        
        return ("Valued Ally", "heart.fill")
    }
    
    /// Get the spotlight stats for a member (streak, tasks, level)
    private func spotlightStats(for entry: LeaderboardEntry) -> (streak: Int, tasks: Int, level: Int) {
        if entry.isSelf {
            return (character.currentStreak, character.tasksCompleted, character.level)
        } else if let member = character.partyMembers.first(where: { $0.id == entry.id }) {
            return (member.currentStreak ?? 0, member.tasksCompleted ?? 0, member.level)
        }
        return (0, entry.tasks, entry.level)
    }
    
    private var memberSpotlightCard: some View {
        Group {
            if let entry = spotlightEntry {
                let tagline = spotlightTagline(for: entry)
                let stats = spotlightStats(for: entry)
                
                VStack(alignment: .leading, spacing: 14) {
                    // Header
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .foregroundColor(Color("AccentGold"))
                        Text("Member Spotlight")
                            .font(.custom("Avenir-Heavy", size: 16))
                        Spacer()
                        Text("Today")
                            .font(.custom("Avenir-Medium", size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    // Spotlighted member
                    HStack(spacing: 14) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(Color(entry.color).opacity(0.15))
                                .frame(width: 52, height: 52)
                            Image(systemName: entry.avatarIcon)
                                .font(.title2)
                                .foregroundColor(Color(entry.color))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(entry.name)
                                    .font(.custom("Avenir-Heavy", size: 18))
                                if entry.isSelf {
                                    Text("(You)")
                                        .font(.custom("Avenir-Medium", size: 12))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // Class + tagline
                            HStack(spacing: 6) {
                                if let member = character.partyMembers.first(where: { $0.id == entry.id }),
                                   let cls = member.characterClass {
                                    Text(cls.rawValue)
                                        .font(.custom("Avenir-Medium", size: 12))
                                        .foregroundColor(.secondary)
                                    Text("·")
                                        .foregroundColor(.secondary)
                                } else if entry.isSelf, let cls = character.characterClass {
                                    Text(cls.rawValue)
                                        .font(.custom("Avenir-Medium", size: 12))
                                        .foregroundColor(.secondary)
                                    Text("·")
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack(spacing: 3) {
                                    Image(systemName: tagline.icon)
                                        .font(.caption2)
                                    Text(tagline.title)
                                        .font(.custom("Avenir-Heavy", size: 12))
                                }
                                .foregroundColor(Color("AccentGold"))
                            }
                        }
                        
                        Spacer()
                    }
                    
                    // Stats row
                    HStack(spacing: 0) {
                        spotlightStatItem(
                            icon: "flame.fill",
                            value: "\(stats.streak)",
                            label: "Streak",
                            color: Color("AccentOrange")
                        )
                        
                        spotlightStatItem(
                            icon: "checkmark.circle.fill",
                            value: "\(stats.tasks)",
                            label: "Tasks",
                            color: Color("AccentGreen")
                        )
                        
                        spotlightStatItem(
                            icon: "arrow.up.circle.fill",
                            value: "\(stats.level)",
                            label: "Level",
                            color: Color("AccentPurple")
                        )
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color("CardBackground"))
                )
            }
        }
    }
    
    private func spotlightStatItem(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundColor(color)
            Text(value)
                .font(.custom("Avenir-Heavy", size: 20))
            Text(label)
                .font(.custom("Avenir-Medium", size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.08))
        )
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
