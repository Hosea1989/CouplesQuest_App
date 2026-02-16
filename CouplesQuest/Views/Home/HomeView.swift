import SwiftUI
import SwiftData
import Charts

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var gameEngine: GameEngine
    @Query private var characters: [PlayerCharacter]
    @Query private var allTasks: [GameTask]
    @Query private var missions: [AFKMission]
    @Query(sort: \Goal.createdAt, order: .reverse) private var allGoals: [Goal]
    @Query private var bonds: [Bond]
    
    /// Today's date formatted for the navigation title (e.g. "Monday, Feb 9")
    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }
    
    /// Active duties: user-owned tasks that are NOT on the duty board, not habits, not partner quests, and not finished
    private var activeDuties: [GameTask] {
        allTasks.filter { !$0.isOnDutyBoard && !$0.isDailyDuty && !$0.isFromPartner && !$0.isHabit && $0.status != .completed && $0.status != .expired }
    }
    
    /// Active goals for the current character
    private var activeGoals: [Goal] {
        guard let character = character else { return [] }
        return allGoals.filter { $0.createdBy == character.id && $0.status == .active }
    }
    
    @State private var showCharacterCreation = false
    @State private var showCreateTask = false
    @State private var showMissionCompletionResult = false
    @State private var lastMissionResult: MissionCompletionResult?
    
    // Partner request notifications
    @ObservedObject private var supabase = SupabaseService.shared
    @State private var incomingPartnerRequests: [PartnerRequest] = []
    @State private var requestSenderProfiles: [UUID: Profile] = [:]
    @State private var showCloudPairingSheet = false
    
    // Dungeon invite notifications
    @State private var pendingDungeonInvites: [DungeonInviteWithDetails] = []
    
    // Daily quest celebration (lifted out of ScrollView so overlay covers full screen)
    @State private var showDailyQuestCelebration = false
    @State private var claimedDailyQuest: DailyQuest? = nil
    
    // Card entrance animation
    @State private var cardsVisible: [Bool] = Array(repeating: false, count: 14)
    
    private var character: PlayerCharacter? {
        characters.first
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if let character = character {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Level Up Banner (always visible immediately, no entrance delay)
                            if character.canLevelUp {
                                LevelUpBanner {
                                    gameEngine.levelUp(character: character, context: modelContext)
                                }
                            }
                            
                            // Partner Request Notification
                            if !incomingPartnerRequests.isEmpty {
                                ForEach(incomingPartnerRequests) { request in
                                    PartnerRequestNotificationCard(
                                        request: request,
                                        senderProfile: requestSenderProfiles[request.fromUserID],
                                        onAccept: { acceptPartnerRequest(request) },
                                        onDecline: { declinePartnerRequest(request) }
                                    )
                                }
                            }
                            
                            // Dungeon Invite Notifications
                            if !pendingDungeonInvites.isEmpty {
                                ForEach(pendingDungeonInvites) { invite in
                                    PartyDungeonInviteCard(
                                        invite: invite,
                                        onAccept: { acceptDungeonInvite(invite) },
                                        onDecline: { declineDungeonInvite(invite) }
                                    )
                                }
                            }
                            
                            // 1. Character Summary Card (with avatar — compact)
                            CharacterSummaryCard(character: character)
                                .cardEntrance(visible: cardsVisible[0], delay: 0)
                            
                            // 1.25. Party Bar (shows allies when in a party)
                            if character.isInParty {
                                PartyBarCard(character: character, bond: bonds.first)
                                    .cardEntrance(visible: cardsVisible[13], delay: 0)
                            }
                            
                            // 1.5. Breadcrumb Quest Log (first 7 days only)
                            if character.shouldShowBreadcrumbs {
                                BreadcrumbQuestLogCard(character: character)
                                    .cardEntrance(visible: cardsVisible[0], delay: 0)
                            }
                            
                            // 2. Mood Check-In Card
                            MoodCheckInCard(character: character)
                                .cardEntrance(visible: cardsVisible[1], delay: 1)
                            
                            // 3. Active Duties Card (shows the user's current duties)
                            ActiveDutiesHomeCard(tasks: activeDuties)
                                .cardEntrance(visible: cardsVisible[2], delay: 2)
                            
                            // 3.5 Goals Summary Card (shows active goals with progress)
                            if !activeGoals.isEmpty {
                                GoalsSummaryHomeCard(goals: activeGoals, allTasks: allTasks)
                                    .cardEntrance(visible: cardsVisible[2], delay: 2)
                            }
                            
                            // 4. Productivity Overview Card
                            ProductivityCard(completedTasks: allTasks.filter { $0.status == .completed })
                                .cardEntrance(visible: cardsVisible[3], delay: 3)
                            
                            // 4.5. Weekly Progress Summary Card
                            NavigationLink(destination: TasksView(isEmbedded: true)) {
                                WeeklyProgressCard(allTasks: allTasks, character: character)
                            }
                            .buttonStyle(.plain)
                            .cardEntrance(visible: cardsVisible[10], delay: 3)
                            
                            // 5. Quick Actions Grid (lead with "New Task")
                            QuickActionsGrid(showCreateTask: $showCreateTask)
                                .cardEntrance(visible: cardsVisible[4], delay: 4)
                            
                            // 6. Daily Quests Card
                            DailyQuestsCard(
                                quests: gameEngine.dailyQuests,
                                character: character,
                                gameEngine: gameEngine,
                                modelContext: modelContext,
                                onQuestClaimed: { quest in
                                    claimedDailyQuest = quest
                                    withAnimation { showDailyQuestCelebration = true }
                                }
                            )
                            .cardEntrance(visible: cardsVisible[5], delay: 5)
                            
                            // 7. Meditation Card
                            MeditationHomeCard(character: character)
                                .cardEntrance(visible: cardsVisible[6], delay: 6)
                            
                            // 8. Active Training Card (conditional)
                            if let activeMission = gameEngine.activeMission {
                                ActiveMissionCard(
                                    mission: activeMission,
                                    onClaim: { claimMissionFromHome() }
                                )
                                .cardEntrance(visible: cardsVisible[7], delay: 7)
                            }
                            
                            // 9. Quick Stats
                            QuickStatsGrid(character: character)
                                .cardEntrance(visible: cardsVisible[8], delay: 8)
                            
                            // 9.5. Leaderboard Summary Card
                            NavigationLink(destination: TasksView(isEmbedded: true)) {
                                LeaderboardSummaryCard(allTasks: allTasks, character: character)
                            }
                            .buttonStyle(.plain)
                            .cardEntrance(visible: cardsVisible[11], delay: 8)
                            
                            // 10. Daily Tip
                            DailyTipCard()
                                .cardEntrance(visible: cardsVisible[9], delay: 9)
                        }
                        .padding()
                        .onAppear { triggerCardEntrance() }
                    }
                } else {
                    BeginQuestView(showCharacterCreation: $showCharacterCreation)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                AnimatedHomeBackground()
                    .ignoresSafeArea(.all)
            }
            .navigationTitle(todayDateString)
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showCharacterCreation) {
                CharacterCreationView()
            }
            .sheet(isPresented: $showCreateTask) {
                CreateTaskView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .fullScreenCover(isPresented: $showMissionCompletionResult) {
                if let result = lastMissionResult {
                    MissionCompletionView(result: result)
                }
            }
            .onAppear {
                if let character = character {
                    gameEngine.checkAndRefreshDailyQuests(for: character, context: modelContext)
                    gameEngine.checkRecurringTasks(context: modelContext)
                    
                    // Set up notifications
                    let hasHabits = allTasks.contains { $0.isHabit }
                    let hasStreak = character.currentStreak > 0
                    NotificationService.shared.setupRecurringReminders(hasHabits: hasHabits, hasStreak: hasStreak)
                    NotificationService.shared.scheduleAllDueDateReminders(context: modelContext)
                    
                    // Cache party ID for fire-and-forget party feed posts
                    if let partyID = bonds.first?.supabasePartyID {
                        SupabaseService.shared.cachedPartyID = partyID
                    }
                }
            }
            .task {
                await loadIncomingPartnerRequests()
                await loadPendingDungeonInvites()
            }
            .sheet(isPresented: $showCloudPairingSheet) {
                CloudPairingView()
            }
            .overlay {
                if showDailyQuestCelebration, let quest = claimedDailyQuest {
                    RewardCelebrationOverlay(
                        icon: quest.isBonusQuest ? "gift.fill" : "scroll.fill",
                        iconColor: Color("AccentGold"),
                        title: quest.isBonusQuest ? "Bonus Claimed!" : "Quest Complete!",
                        subtitle: quest.title,
                        rewards: [
                            (icon: "sparkles", label: "EXP Earned", value: "+\(quest.expReward)", color: Color("AccentGold")),
                            (icon: "dollarsign.circle.fill", label: "Gold Earned", value: "+\(quest.goldReward)", color: Color("AccentGold"))
                        ],
                        onDismiss: {
                            withAnimation { showDailyQuestCelebration = false; claimedDailyQuest = nil }
                        }
                    )
                    .transition(.opacity)
                }
            }
        }
    }
    
    // MARK: - Card Entrance Animation
    
    private func triggerCardEntrance() {
        for i in 0..<cardsVisible.count {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(i) * 0.05)) {
                cardsVisible[i] = true
            }
        }
    }
    
    // MARK: - Partner Request Handling
    
    private func loadIncomingPartnerRequests() async {
        do {
            let requests = try await supabase.fetchIncomingRequests()
            incomingPartnerRequests = requests
            // Load sender profiles
            for request in requests {
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
            print("Failed to load partner requests: \(error)")
        }
    }
    
    private func acceptPartnerRequest(_ request: PartnerRequest) {
        Task {
            do {
                try await supabase.acceptPartnerRequest(request.id)
                
                // Update local SwiftData character with partner info
                await linkPartnerLocally(partnerUserID: request.fromUserID)
                
                withAnimation {
                    incomingPartnerRequests.removeAll { $0.id == request.id }
                }
                ToastManager.shared.showSuccess(
                    "Partner Linked!",
                    subtitle: "You're now connected with your partner!"
                )
            } catch {
                ToastManager.shared.showError(
                    "Failed",
                    subtitle: error.localizedDescription
                )
            }
        }
    }
    
    /// After cloud accept, sync partner data into the local SwiftData character + Bond.
    @MainActor
    private func linkPartnerLocally(partnerUserID: UUID) async {
        guard let character = character else { return }
        
        // Fetch the partner's profile to get their character info
        do {
            if let partnerProfile = try await supabase.fetchProfile(byID: partnerUserID) {
                let pairingData = PairingData(
                    characterID: partnerUserID.uuidString,
                    name: partnerProfile.characterName ?? "Adventurer",
                    level: partnerProfile.level ?? 1,
                    characterClass: partnerProfile.characterClass,
                    partyID: nil
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
    
    private func declinePartnerRequest(_ request: PartnerRequest) {
        Task {
            do {
                try await supabase.rejectPartnerRequest(request.id)
                withAnimation {
                    incomingPartnerRequests.removeAll { $0.id == request.id }
                }
            } catch {
                print("Failed to decline request: \(error)")
            }
        }
    }
    
    // MARK: - Dungeon Invite Handling
    
    private func loadPendingDungeonInvites() async {
        do {
            let invites = try await SupabaseService.shared.fetchPendingDungeonInvites()
            withAnimation {
                pendingDungeonInvites = invites
            }
        } catch {
            print("Failed to load dungeon invites: \(error)")
        }
    }
    
    private func acceptDungeonInvite(_ invite: DungeonInviteWithDetails) {
        Task {
            do {
                try await SupabaseService.shared.respondToDungeonInvite(responseID: invite.responseID, accepted: true)
                withAnimation {
                    pendingDungeonInvites.removeAll { $0.id == invite.id }
                }
                ToastManager.shared.showSuccess(
                    "Invite Accepted!",
                    subtitle: "You joined the \(invite.invite.dungeonName) run."
                )
            } catch {
                ToastManager.shared.showError(
                    "Failed",
                    subtitle: error.localizedDescription
                )
            }
        }
    }
    
    private func declineDungeonInvite(_ invite: DungeonInviteWithDetails) {
        Task {
            do {
                try await SupabaseService.shared.respondToDungeonInvite(responseID: invite.responseID, accepted: false)
                withAnimation {
                    pendingDungeonInvites.removeAll { $0.id == invite.id }
                }
            } catch {
                print("Failed to decline dungeon invite: \(error)")
            }
        }
    }
    
    // MARK: - Claim Training from Home
    
    private func claimMissionFromHome() {
        guard let character = character,
              let activeMission = gameEngine.activeMission,
              let mission = missions.first(where: { $0.id == activeMission.missionID }) else { return }
        
        if let result = gameEngine.checkMissionCompletion(mission: mission, character: character) {
            lastMissionResult = result
            showMissionCompletionResult = true
            AudioManager.shared.play(.claimReward)
            
            if result.success {
                gameEngine.awardMaterialsForMission(
                    missionRarity: mission.rarity,
                    character: character,
                    context: modelContext
                )
            }
        }
    }
}

// MARK: - Character Summary Card

struct CharacterSummaryCard: View {
    let character: PlayerCharacter
    
    @ObservedObject private var weatherService = WeatherService.shared
    @State private var levelGlow: Bool = false
    @State private var expShimmer: CGFloat = -0.3
    @State private var expBarAppeared: Bool = false
    @State private var borderRotation: Double = 0
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 14) {
                // Character Avatar
                CharacterAvatarView(character: character, size: 56)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(character.name)
                        .font(.custom("Avenir-Heavy", size: 24))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        Text(character.title)
                            .font(.custom("Avenir-Medium", size: 14))
                            .foregroundColor(Color("AccentGold"))
                        
                        if let characterClass = character.characterClass {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(characterClass.rawValue)
                                .font(.custom("Avenir-Medium", size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // HP indicator
                    HStack(spacing: 6) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12))
                            .foregroundColor(character.hpPercentage > 0.5 ? Color("AccentGreen") : (character.hpPercentage > 0.25 ? Color("AccentGold") : Color("DifficultyHard")))
                        
                        // Compact HP bar
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondary.opacity(0.2))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(character.hpPercentage > 0.5 ? Color("AccentGreen") : (character.hpPercentage > 0.25 ? Color("AccentGold") : Color("DifficultyHard")))
                                .frame(width: max(4, 80 * character.hpPercentage), height: 6)
                        }
                        .frame(width: 80, height: 6)
                        
                        Text(character.hpDisplay)
                            .font(.custom("Avenir-Medium", size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    // Weather indicator
                    if let symbol = weatherService.conditionSymbol,
                       let temp = weatherService.temperature {
                        HStack(spacing: 4) {
                            Image(systemName: symbol)
                                .font(.caption)
                                .symbolRenderingMode(.multicolor)
                            Text(temp)
                                .font(.custom("Avenir-Medium", size: 12))
                            
                            // Weather task suggestion
                            if let suggestion = weatherService.weatherSuggestion {
                                Text("•")
                                    .foregroundColor(.secondary)
                                Text(suggestion)
                                    .font(.custom("Avenir-Medium", size: 12))
                            }
                        }
                        .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Level Badge with pulsing glow
                ZStack {
                    // Outer glow ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color("AccentGold"), Color("AccentOrange")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 64, height: 64)
                        .shadow(color: Color("AccentGold").opacity(levelGlow ? 0.6 : 0.15), radius: levelGlow ? 12 : 4)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color("AccentGold"), Color("AccentOrange")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                    
                    VStack(spacing: 0) {
                        Text("LV")
                            .font(.custom("Avenir-Medium", size: 10))
                        Text("\(character.level)")
                            .font(.custom("Avenir-Heavy", size: 20))
                    }
                    .foregroundColor(.black)
                }
            }
            
            // EXP Progress Bar with shimmer
            VStack(spacing: 8) {
                HStack {
                    Text("EXP")
                        .font(.custom("Avenir-Heavy", size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(character.currentEXP) / \(character.expToNextLevel)")
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.2))
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [Color("AccentGold"), Color("AccentOrange")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            // Shimmer sweep
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        stops: [
                                            .init(color: .clear, location: expShimmer - 0.15),
                                            .init(color: .white.opacity(0.4), location: expShimmer),
                                            .init(color: .clear, location: expShimmer + 0.15)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                        .frame(width: geometry.size.width * (expBarAppeared ? character.levelProgress : 0))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                .frame(height: 8)
            }
            
            // Currency Row
            HStack(spacing: 24) {
                HStack(spacing: 6) {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(Color("AccentGold"))
                    Text("\(character.gold)")
                        .font(.custom("Avenir-Heavy", size: 16))
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(Color("AccentOrange"))
                        .symbolEffect(.pulse, options: character.currentStreak > 0 ? .repeating.speed(0.6) : .nonRepeating)
                    Text("\(character.currentStreak) day streak")
                        .font(.custom("Avenir-Medium", size: 14))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
        .overlay(
            // Animated gold border when unspent stat points
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    AngularGradient(
                        colors: character.unspentStatPoints > 0
                            ? [Color("AccentGold"), Color("AccentOrange"), Color("AccentGold")]
                            : [Color.clear],
                        center: .center,
                        startAngle: .degrees(borderRotation),
                        endAngle: .degrees(borderRotation + 360)
                    ),
                    lineWidth: character.unspentStatPoints > 0 ? 2 : 0
                )
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                levelGlow = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                expBarAppeared = true
            }
            withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                expShimmer = 1.15
            }
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                borderRotation = 360
            }
            weatherService.refreshIfNeeded()
        }
    }
}

// MARK: - Daily Quests Card

struct DailyQuestsCard: View {
    let quests: [DailyQuest]
    let character: PlayerCharacter
    let gameEngine: GameEngine
    let modelContext: ModelContext
    var onQuestClaimed: ((DailyQuest) -> Void)? = nil
    
    private var regularQuests: [DailyQuest] {
        quests.filter { !$0.isBonusQuest }
    }
    
    private var bonusQuest: DailyQuest? {
        quests.first { $0.isBonusQuest }
    }
    
    private var timeUntilReset: String {
        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date())) else {
            return "—"
        }
        let remaining = Int(tomorrow.timeIntervalSince(Date()))
        let hours = remaining / 3600
        let minutes = (remaining % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "scroll.fill")
                    .foregroundColor(Color("AccentGold"))
                Text("Daily Quests")
                    .font(.custom("Avenir-Heavy", size: 18))
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text(timeUntilReset)
                        .font(.custom("Avenir-Medium", size: 12))
                }
                .foregroundColor(.secondary)
            }
            
            if regularQuests.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        ProgressView()
                        Text("Loading quests...")
                            .font(.custom("Avenir-Medium", size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 12)
                    Spacer()
                }
            } else {
                // Quest rows with staggered animation
                ForEach(Array(regularQuests.enumerated()), id: \.element.id) { index, quest in
                    DailyQuestRow(quest: quest, onClaim: {
                        claimQuest(quest)
                    }, animationIndex: index)
                }
                
                // Bonus row
                if let bonus = bonusQuest {
                    Divider()
                    
                    HStack(spacing: 12) {
                        Image(systemName: bonus.isCompleted ? "gift.fill" : "gift")
                            .font(.title3)
                            .foregroundColor(bonus.isCompleted ? Color("AccentGold") : .secondary)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Complete All 3")
                                .font(.custom("Avenir-Heavy", size: 14))
                                .foregroundColor(bonus.isCompleted ? Color("AccentGold") : .primary)
                            Text("+\(bonus.expReward) EXP  +\(bonus.goldReward) Gold")
                                .font(.custom("Avenir-Medium", size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if bonus.isCompleted && !bonus.isClaimed {
                            Button(action: {
                                claimQuest(bonus)
                            }) {
                                Text("Claim")
                                    .font(.custom("Avenir-Heavy", size: 12))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(Color("AccentGold"))
                                    .clipShape(Capsule())
                            }
                        } else if bonus.isClaimed {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color("AccentGreen"))
                        } else {
                            Text("\(bonus.currentValue)/\(bonus.targetValue)")
                                .font(.custom("Avenir-Heavy", size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
    }
    
    private func claimQuest(_ quest: DailyQuest) {
        gameEngine.claimDailyQuestReward(quest, character: character, context: modelContext)
        ToastManager.shared.showReward(
            "Quest Claimed!",
            subtitle: "+\(quest.expReward) EXP, +\(quest.goldReward) Gold"
        )
        onQuestClaimed?(quest)
    }
}

struct DailyQuestRow: View {
    let quest: DailyQuest
    let onClaim: () -> Void
    var animationIndex: Int = 0
    
    @State private var progressAppeared: Bool = false
    @State private var completedGlow: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(quest.isCompleted ? Color("AccentGreen").opacity(0.2) : Color.secondary.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                if quest.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundColor(Color("AccentGreen"))
                } else {
                    Image(systemName: quest.icon)
                        .font(.caption)
                        .foregroundColor(Color("AccentGold"))
                }
            }
            
            // Info + progress
            VStack(alignment: .leading, spacing: 4) {
                Text(quest.title)
                    .font(.custom("Avenir-Heavy", size: 14))
                    .foregroundColor(quest.isCompleted ? .secondary : .primary)
                    .strikethrough(quest.isClaimed)
                
                // Animated Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.secondary.opacity(0.15))
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(quest.isCompleted ? Color("AccentGreen") : Color("AccentGold"))
                            .frame(width: geometry.size.width * (progressAppeared ? quest.progress : 0))
                    }
                }
                .frame(height: 6)
            }
            
            // Counter or claim
            if quest.isCompleted && !quest.isClaimed {
                Button(action: onClaim) {
                    Text("Claim")
                        .font(.custom("Avenir-Heavy", size: 12))
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color("AccentGold"))
                        .clipShape(Capsule())
                }
            } else if quest.isClaimed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color("AccentGreen"))
            } else {
                Text("\(quest.currentValue)/\(quest.targetValue)")
                    .font(.custom("Avenir-Heavy", size: 13))
                    .foregroundColor(.secondary)
                    .frame(minWidth: 36)
            }
        }
        .background(
            quest.isCompleted && completedGlow ?
            RoundedRectangle(cornerRadius: 8)
                .fill(Color("AccentGreen").opacity(0.06))
            : nil
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.1 * Double(animationIndex))) {
                progressAppeared = true
            }
            if quest.isCompleted {
                completedGlow = true
            }
        }
    }
}

// MARK: - Quick Actions Grid (2x3)

struct QuickActionsGrid: View {
    @Binding var showCreateTask: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                // New Task
                Button(action: { showCreateTask = true }) {
                    QuickActionButton(
                        icon: "plus.circle.fill",
                        label: "New Task",
                        color: Color("AccentGreen")
                    )
                }
                .buttonStyle(QuickActionPressStyle())
                
                // Forge
                NavigationLink(destination: ForgeView()) {
                    QuickActionButton(
                        icon: "hammer.fill",
                        label: "Forge",
                        color: Color("ForgeEmber")
                    )
                }
                .buttonStyle(QuickActionPressStyle())
                
                // Store
                NavigationLink(destination: StoreView()) {
                    QuickActionButton(
                        icon: "bag.fill",
                        label: "Store",
                        color: Color("StoreTeal")
                    )
                }
                .buttonStyle(QuickActionPressStyle())
            }
            
            HStack(spacing: 10) {
                // Dungeon
                NavigationLink(destination: DungeonListView(isEmbedded: true)) {
                    QuickActionButton(
                        icon: "shield.lefthalf.filled",
                        label: "Dungeon",
                        color: Color("AccentPurple")
                    )
                }
                .buttonStyle(QuickActionPressStyle())
                
                // Inventory
                NavigationLink(destination: InventoryView()) {
                    QuickActionButton(
                        icon: "shippingbox.fill",
                        label: "Inventory",
                        color: Color("StatDexterity")
                    )
                }
                .buttonStyle(QuickActionPressStyle())
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    
    @State private var borderPhase: CGFloat = 0
    @State private var appeared: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .symbolEffect(.bounce, value: appeared)
            Text(label)
                .font(.custom("Avenir-Heavy", size: 12))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    AngularGradient(
                        colors: [color.opacity(0.5), color.opacity(0.15), color.opacity(0.5)],
                        center: .center,
                        startAngle: .degrees(Double(borderPhase) * 360.0),
                        endAngle: .degrees(Double(borderPhase) * 360.0 + 360.0)
                    ),
                    lineWidth: 1.5
                )
        )
        .onAppear {
            appeared = true
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                borderPhase = 1
            }
        }
    }
}

/// Button style for tactile press feedback on quick actions
struct QuickActionPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Active Training Card

struct ActiveMissionCard: View {
    let mission: ActiveMission
    let onClaim: () -> Void
    
    @State private var shimmerOffset: CGFloat = -1.0
    @State private var glowPulse: Bool = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                if let mType = mission.missionType {
                    Image(mType.thumbnailImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .foregroundColor(Color("AccentGold"))
                        .symbolEffect(.pulse, options: .repeating)
                }
                Text(mission.isComplete ? "Training Complete!" : "Active Training")
                    .font(.custom("Avenir-Heavy", size: 14))
                    .foregroundColor(mission.isComplete ? Color("AccentGreen") : .primary)
                Spacer()
                if mission.isComplete {
                    Text("Ready!")
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(Color("AccentGreen"))
                } else {
                    Text(mission.timeRemainingFormatted)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(Color("AccentGold"))
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [Color("AccentGold"), Color("AccentOrange")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        if !mission.isComplete {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        stops: [
                                            .init(color: .clear, location: shimmerOffset - 0.15),
                                            .init(color: .white.opacity(0.35), location: shimmerOffset),
                                            .init(color: .clear, location: shimmerOffset + 0.15)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                    }
                    .frame(width: geometry.size.width * mission.progress)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            .frame(height: 6)
            
            if mission.isComplete {
                Button(action: onClaim) {
                    HStack {
                        Image(systemName: "gift.fill")
                            .symbolEffect(.bounce, options: .repeating.speed(0.5))
                        Text("Claim Rewards")
                    }
                    .font(.custom("Avenir-Heavy", size: 14))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [Color("AccentGold"), Color("AccentOrange")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .shadow(
                    color: mission.isComplete
                        ? Color("AccentGreen").opacity(0.3)
                        : Color("AccentGold").opacity(glowPulse ? 0.3 : 0.1),
                    radius: glowPulse ? 14 : 8,
                    x: 0, y: 4
                )
        )
        .onAppear {
            guard !mission.isComplete else { return }
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                shimmerOffset = 1.15
            }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }
}

// MARK: - Character Avatar View

struct CharacterAvatarView: View {
    let character: PlayerCharacter
    var size: CGFloat = 56
    
    var body: some View {
        ZStack {
            if let imageData = character.avatarImageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if let avatarIndex = avatarAssetName {
                Image(avatarIndex)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color("AccentGold").opacity(0.3), Color("AccentOrange").opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    .overlay(
                        Image(systemName: character.avatarIcon)
                            .font(.system(size: size * 0.4))
                            .foregroundColor(Color("AccentGold"))
                    )
            }
        }
        .overlay(
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color("AccentGold"), Color("AccentOrange")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.5
                )
        )
    }
    
    /// Check if the avatar icon matches a pixel-art asset name
    private var avatarAssetName: String? {
        let icon = character.avatarIcon
        if icon.hasPrefix("avatar_") {
            return icon
        }
        return nil
    }
}

// MARK: - Level Up Banner

struct LevelUpBanner: View {
    let onLevelUp: () -> Void
    
    @State private var glow: Bool = false
    @State private var shimmerOffset: CGFloat = -0.3
    @State private var iconBounce: Bool = false
    
    var body: some View {
        Button(action: {
            AudioManager.shared.play(.levelUp)
            onLevelUp()
        }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color("AccentGold").opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color("AccentGold"), Color("AccentOrange")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.bounce, options: .repeating.speed(0.4), value: iconBounce)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("LEVEL UP!")
                        .font(.custom("Avenir-Heavy", size: 20))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color("AccentGold"), Color("AccentOrange")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Text("Tap to claim your rewards")
                        .font(.custom("Avenir-Medium", size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.title3.bold())
                    .foregroundColor(Color("AccentGold"))
            }
            .padding(16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color("CardBackground"))
                    
                    // Shimmer sweep
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: shimmerOffset - 0.15),
                                    .init(color: Color("AccentGold").opacity(0.12), location: shimmerOffset),
                                    .init(color: .clear, location: shimmerOffset + 0.15)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [Color("AccentGold"), Color("AccentOrange")],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(
                color: Color("AccentGold").opacity(glow ? 0.4 : 0.15),
                radius: glow ? 16 : 8,
                x: 0, y: 4
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            iconBounce = true
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glow = true
            }
            withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                shimmerOffset = 1.3
            }
        }
    }
}

// MARK: - Quick Stats Grid

struct QuickStatsGrid: View {
    let character: PlayerCharacter
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            StatBadge(
                icon: "checkmark.circle.fill",
                value: "\(character.tasksCompleted)",
                label: "Tasks Done",
                color: Color("AccentGreen")
            )
            
            StatBadge(
                icon: "flame.fill",
                value: "\(character.longestStreak)",
                label: "Best Streak",
                color: Color("AccentOrange")
            )
            
            StatBadge(
                icon: "star.fill",
                value: "\(character.stats.total)",
                label: "Total Stats",
                color: Color("AccentPurple")
            )
        }
    }
}

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    @State private var displayedValue: Int = 0
    @State private var iconGlow: Bool = false
    
    private var targetValue: Int {
        Int(value) ?? 0
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Pulsing glow behind icon
                Circle()
                    .fill(color.opacity(iconGlow ? 0.2 : 0.08))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }
            
            Text("\(displayedValue)")
                .font(.custom("Avenir-Heavy", size: 20))
                .contentTransition(.numericText())
            
            Text(label)
                .font(.custom("Avenir-Medium", size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
        .onAppear {
            // Animate number counting up
            animateCounter()
            // Pulsing icon glow
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                iconGlow = true
            }
        }
    }
    
    private func animateCounter() {
        let target = targetValue
        guard target > 0 else { return }
        let steps = min(target, 20)
        let stepDuration = 0.6 / Double(steps)
        
        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                withAnimation(.easeOut(duration: 0.05)) {
                    displayedValue = Int(Double(target) * Double(i) / Double(steps))
                }
            }
        }
    }
}

// MARK: - Active Duties Home Card

struct ActiveDutiesHomeCard: View {
    let tasks: [GameTask]
    @EnvironmentObject var gameEngine: GameEngine
    @Environment(\.modelContext) private var modelContext
    @Query private var characters: [PlayerCharacter]
    @Query private var bonds: [Bond]
    
    @State private var showCompletionCelebration = false
    @State private var lastCompletionResult: TaskCompletionResult?
    @State private var showSudoku = false
    @State private var sudokuDuty: GameTask?
    @State private var showMemoryMatch = false
    @State private var memoryMatchDuty: GameTask?
    @State private var showMathBlitz = false
    @State private var mathBlitzDuty: GameTask?
    @State private var showWordSearch = false
    @State private var wordSearchDuty: GameTask?
    @State private var show2048 = false
    @State private var game2048Duty: GameTask?
    
    private var character: PlayerCharacter? { characters.first }
    private var bond: Bond? { bonds.first }
    
    private enum MiniGameType {
        case sudoku, memoryMatch, mathBlitz, wordSearch, game2048
    }
    
    private func miniGameType(for task: GameTask) -> MiniGameType? {
        switch task.title {
        case "Sudoku Challenge", "Solve a Puzzle": return .sudoku
        case "Memory Match": return .memoryMatch
        case "Math Blitz": return .mathBlitz
        case "Word Search": return .wordSearch
        case "2048 Challenge": return .game2048
        default: return nil
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .font(.callout)
                    .foregroundColor(Color("AccentOrange"))
                Text("Active Duties")
                    .font(.custom("Avenir-Heavy", size: 18))
                
                if !tasks.isEmpty {
                    Text("\(tasks.count)")
                        .font(.custom("Avenir-Heavy", size: 12))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color("AccentOrange")))
                }
                
                Spacer()
                NavigationLink(destination: TasksView(isEmbedded: true)) {
                    Text("See All")
                        .font(.custom("Avenir-Medium", size: 14))
                        .foregroundColor(Color("AccentGold"))
                }
            }
            
            if tasks.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "scroll")
                            .font(.system(size: 28))
                            .foregroundColor(.secondary)
                        
                        Text("No active duties")
                            .font(.custom("Avenir-Heavy", size: 15))
                            .foregroundColor(.secondary)
                        
                        Text("Head to the Duty Board and pick one!")
                            .font(.custom("Avenir-Medium", size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        NavigationLink(destination: TasksView(isEmbedded: true)) {
                            HStack(spacing: 6) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 12))
                                Text("Go to Duty Board")
                                    .font(.custom("Avenir-Heavy", size: 13))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color("AccentOrange"))
                            .clipShape(Capsule())
                        }
                        .padding(.top, 2)
                    }
                    .padding(.vertical, 16)
                    Spacer()
                }
            } else {
                ForEach(tasks, id: \.id) { task in
                    ActiveDutyRow(task: task, isMiniGame: miniGameType(for: task) != nil, characterLevel: character?.level ?? 1) {
                        if let gameType = miniGameType(for: task) {
                            openMiniGame(task, type: gameType)
                        } else {
                            completeTask(task)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
        .sheet(isPresented: $showCompletionCelebration) {
            if let result = lastCompletionResult {
                TaskCompletionCelebration(result: result)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
        .fullScreenCover(isPresented: $showSudoku) {
            SudokuGameView { elapsedSeconds in
                completeSudokuDuty(elapsedSeconds: elapsedSeconds)
            }
        }
        .fullScreenCover(isPresented: $showMemoryMatch) {
            MemoryMatchGameView { elapsedSeconds in
                completeMiniGameFromHome(
                    task: memoryMatchDuty,
                    tier: MemoryMatchRewardTier.tier(for: elapsedSeconds),
                    gameName: "Memory Match"
                )
                memoryMatchDuty = nil
            }
        }
        .fullScreenCover(isPresented: $showMathBlitz) {
            MathBlitzGameView { elapsedSeconds in
                completeMiniGameFromHome(
                    task: mathBlitzDuty,
                    tier: MathBlitzRewardTier.tier(for: elapsedSeconds),
                    gameName: "Math Blitz"
                )
                mathBlitzDuty = nil
            }
        }
        .fullScreenCover(isPresented: $showWordSearch) {
            WordSearchGameView { elapsedSeconds in
                completeMiniGameFromHome(
                    task: wordSearchDuty,
                    tier: WordSearchRewardTier.tier(for: elapsedSeconds),
                    gameName: "Word Search"
                )
                wordSearchDuty = nil
            }
        }
        .fullScreenCover(isPresented: $show2048) {
            Game2048View { elapsedSeconds in
                let tier = Game2048RewardTier.tier(for: 512)
                completeMiniGameFromHome(
                    task: game2048Duty,
                    tier: tier,
                    gameName: "2048 Challenge"
                )
                game2048Duty = nil
            }
        }
    }
    
    private func openMiniGame(_ task: GameTask, type: MiniGameType) {
        switch type {
        case .sudoku:
            sudokuDuty = task
            showSudoku = true
        case .memoryMatch:
            memoryMatchDuty = task
            showMemoryMatch = true
        case .mathBlitz:
            mathBlitzDuty = task
            showMathBlitz = true
        case .wordSearch:
            wordSearchDuty = task
            showWordSearch = true
        case .game2048:
            game2048Duty = task
            show2048 = true
        }
    }
    
    private func completeTask(_ task: GameTask) {
        guard let character = character else { return }
        if task.startedAt == nil { task.startTask() }
        
        let result = gameEngine.completeTask(task, character: character, bond: bond, context: modelContext)
        lastCompletionResult = result
        showCompletionCelebration = true
        gameEngine.updateStreak(for: character, completedTaskToday: true)
    }
    
    private func completeSudokuDuty(elapsedSeconds: Int) {
        guard let task = sudokuDuty, let character = character else { return }
        task.isVerified = true
        
        let tier = SudokuRewardTier.tier(for: elapsedSeconds)
        character.gold += tier.gold
        character.stats.increase(.wisdom, by: tier.wisdomBonus)
        
        if tier.consumableCount > 0 {
            for _ in 0..<tier.consumableCount {
                let consumable = Consumable(
                    name: tier.consumableName,
                    description: "Earned from Sudoku Challenge — boosts mental focus.",
                    consumableType: .statFood,
                    icon: tier.consumableIcon,
                    effectValue: 2,
                    effectStat: .wisdom,
                    remainingUses: 1,
                    characterID: character.id
                )
                modelContext.insert(consumable)
            }
        }
        
        let result = gameEngine.completeTask(task, character: character, bond: bond, context: modelContext)
        lastCompletionResult = result
        showCompletionCelebration = true
        gameEngine.updateStreak(for: character, completedTaskToday: true)
        sudokuDuty = nil
    }
    
    /// Generic completion handler for mini-games launched from the home screen.
    private func completeMiniGameFromHome<T>(task: GameTask?, tier: T, gameName: String) where T: MiniGameRewardTierProtocol {
        guard let task = task, let character = character else { return }
        task.isVerified = true
        
        character.gold += tier.gold
        character.stats.increase(.wisdom, by: tier.wisdomBonus)
        
        if tier.consumableCount > 0 {
            for _ in 0..<tier.consumableCount {
                let consumable = Consumable(
                    name: tier.consumableName,
                    description: "Earned from \(gameName) — boosts mental focus.",
                    consumableType: .statFood,
                    icon: tier.consumableIcon,
                    effectValue: 2,
                    effectStat: .wisdom,
                    remainingUses: 1,
                    characterID: character.id
                )
                modelContext.insert(consumable)
            }
        }
        
        let result = gameEngine.completeTask(task, character: character, bond: bond, context: modelContext)
        lastCompletionResult = result
        showCompletionCelebration = true
        gameEngine.updateStreak(for: character, completedTaskToday: true)
    }
}

/// Protocol for mini-game reward tiers so we can use them generically.
protocol MiniGameRewardTierProtocol {
    var gold: Int { get }
    var consumableName: String { get }
    var consumableIcon: String { get }
    var consumableCount: Int { get }
    var wisdomBonus: Int { get }
}

extension MemoryMatchRewardTier: MiniGameRewardTierProtocol {}
extension MathBlitzRewardTier: MiniGameRewardTierProtocol {}
extension WordSearchRewardTier: MiniGameRewardTierProtocol {}
extension Game2048RewardTier: MiniGameRewardTierProtocol {}

// MARK: - Active Duty Row (Home Screen)

struct ActiveDutyRow: View {
    let task: GameTask
    var isMiniGame: Bool = false
    var characterLevel: Int = 1
    let onComplete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Complete button
            Button(action: onComplete) {
                ZStack {
                    Circle()
                        .stroke(isMiniGame ? Color("AccentGold") : Color(task.category.color), lineWidth: 2)
                        .frame(width: 28, height: 28)
                    
                    if isMiniGame {
                        Image(systemName: "puzzlepiece.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color("AccentGold"))
                    }
                }
            }
            
            // Task info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(task.title)
                        .font(.custom("Avenir-Heavy", size: 14))
                        .lineLimit(1)
                    
                    if task.isCoopDuty {
                        HStack(spacing: 2) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 8))
                            Text("Co-op")
                                .font(.custom("Avenir-Heavy", size: 9))
                        }
                        .foregroundColor(Color("AccentPink"))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Color("AccentPink").opacity(0.12)))
                    }
                }
                
                HStack(spacing: 8) {
                    HStack(spacing: 3) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 9))
                        Text("+\(task.scaledExpReward(characterLevel: characterLevel)) EXP")
                            .font(.custom("Avenir-Heavy", size: 11))
                    }
                    .foregroundColor(Color("AccentGold"))
                    
                    if task.hasDeadline {
                        HStack(spacing: 3) {
                            Image(systemName: "hourglass")
                                .font(.system(size: 9))
                            Text(task.deadlineFormatted)
                                .font(.custom("Avenir-Medium", size: 11))
                        }
                        .foregroundColor(task.remainingDeadlineSeconds < 3600 ? .red : Color("AccentOrange"))
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: task.category.icon)
                .font(.caption)
                .foregroundColor(Color(task.category.color))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.06))
        )
    }
}

// MARK: - Meditation Home Card

struct MeditationHomeCard: View {
    let character: PlayerCharacter
    @State private var showMeditation = false
    @State private var flamePhase = false
    
    /// Streak tier determines the visual treatment
    private var streakTier: MeditationStreakTier {
        MeditationStreakTier.tier(for: character.meditationStreak)
    }
    
    /// Streak bonus percentage
    private var streakBonusPercent: Int {
        min(50, character.meditationStreak * 5)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Button {
                showMeditation = true
            } label: {
                VStack(spacing: 12) {
                    HStack(spacing: 14) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(
                                    character.hasMeditatedToday ?
                                    Color("AccentGreen").opacity(0.2) :
                                    Color("AccentPurple").opacity(0.2)
                                )
                                .frame(width: 50, height: 50)
                            Image(systemName: "brain.head.profile")
                                .font(.title3)
                                .foregroundColor(
                                    character.hasMeditatedToday ?
                                    Color("AccentGreen") : Color("AccentPurple")
                                )
                        }
                        
                        // Info
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Daily Meditation")
                                .font(.custom("Avenir-Heavy", size: 17))
                            
                            if character.hasMeditatedToday {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color("AccentGreen"))
                                        .font(.caption)
                                    Text("Completed today")
                                        .font(.custom("Avenir-Medium", size: 13))
                                        .foregroundColor(Color("AccentGreen"))
                                }
                            } else {
                                Text("Tap to begin your session")
                                    .font(.custom("Avenir-Medium", size: 13))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // Streak Badge — visual escalation based on streak tier
                        meditationStreakBadge
                    }
                    
                    // Rewards row (only show if not completed today)
                    if !character.hasMeditatedToday {
                        HStack(spacing: 0) {
                            // EXP reward
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 10))
                                Text("+\(character.meditationExpReward) EXP")
                                    .font(.custom("Avenir-Heavy", size: 12))
                            }
                            .foregroundColor(Color("AccentGold"))
                            .frame(maxWidth: .infinity)
                            
                            // Divider
                            Rectangle()
                                .fill(Color.secondary.opacity(0.2))
                                .frame(width: 1, height: 16)
                            
                            // Gold reward
                            HStack(spacing: 4) {
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.system(size: 10))
                                Text("+\(character.meditationGoldReward) Gold")
                                    .font(.custom("Avenir-Heavy", size: 12))
                            }
                            .foregroundColor(Color("AccentGold"))
                            .frame(maxWidth: .infinity)
                            
                            // Streak bonus (if any)
                            if streakBonusPercent > 0 {
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(width: 1, height: 16)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: streakTier.icon)
                                        .font(.system(size: 10))
                                    Text("+\(streakBonusPercent)% bonus")
                                        .font(.custom("Avenir-Heavy", size: 12))
                                }
                                .foregroundColor(Color(streakTier.color))
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color("AccentGold").opacity(0.06))
                        )
                    }
                }
                .padding(16)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color("CardBackground"))
                        
                        // Fire glow effect for 7+ day streaks
                        if streakTier.isOnFire {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color("AccentOrange").opacity(flamePhase ? 0.4 : 0.15),
                                            Color("AccentGold").opacity(flamePhase ? 0.3 : 0.1),
                                            Color("AccentOrange").opacity(flamePhase ? 0.4 : 0.15)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 2
                                )
                        }
                    }
                    .shadow(
                        color: streakTier.isOnFire
                            ? Color("AccentOrange").opacity(flamePhase ? 0.2 : 0.08)
                            : .black.opacity(0.05),
                        radius: streakTier.isOnFire ? 10 : 5,
                        x: 0, y: streakTier.isOnFire ? 2 : 2
                    )
                )
            }
            .buttonStyle(.plain)
        }
        .onAppear {
            if streakTier.isOnFire {
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                    flamePhase = true
                }
            }
        }
        .sheet(isPresented: $showMeditation) {
            NavigationStack {
                MeditationView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Close") {
                                showMeditation = false
                            }
                            .foregroundColor(Color("AccentGold"))
                        }
                    }
            }
        }
    }
    
    // MARK: - Streak Badge
    
    @ViewBuilder
    private var meditationStreakBadge: some View {
        let tier = streakTier
        
        VStack(spacing: 2) {
            // Fire icon for 7+ day streaks
            if tier.isOnFire {
                Image(systemName: "flame.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color("AccentOrange"))
                    .scaleEffect(flamePhase ? 1.15 : 0.95)
            }
            
            Text("\(character.meditationStreak)")
                .font(.custom("Avenir-Heavy", size: tier.isOnFire ? 26 : 22))
                .foregroundColor(Color(tier.color))
            
            Text(tier.label)
                .font(.custom("Avenir-Heavy", size: 9))
                .foregroundColor(Color(tier.color).opacity(0.8))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(tier.color).opacity(tier.isOnFire ? 0.15 : 0.1))
                .overlay(
                    tier.isOnFire ?
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(tier.color).opacity(0.3), lineWidth: 1)
                    : nil
                )
        )
    }
}

// MARK: - Meditation Streak Tier

private struct MeditationStreakTier {
    let label: String
    let icon: String
    let color: String
    let isOnFire: Bool
    
    static func tier(for streak: Int) -> MeditationStreakTier {
        switch streak {
        case 0:
            return MeditationStreakTier(label: "streak", icon: "circle", color: "AccentGold", isOnFire: false)
        case 1...2:
            return MeditationStreakTier(label: "streak", icon: "sparkle", color: "AccentGold", isOnFire: false)
        case 3...6:
            return MeditationStreakTier(label: "growing", icon: "flame", color: "AccentOrange", isOnFire: false)
        case 7...13:
            return MeditationStreakTier(label: "on fire", icon: "flame.fill", color: "AccentOrange", isOnFire: true)
        case 14...29:
            return MeditationStreakTier(label: "blazing", icon: "flame.fill", color: "AccentOrange", isOnFire: true)
        default:
            return MeditationStreakTier(label: "legendary", icon: "flame.fill", color: "AccentGold", isOnFire: true)
        }
    }
}

// MARK: - Mood Check-In Card

struct MoodCheckInCard: View {
    let character: PlayerCharacter
    @EnvironmentObject var gameEngine: GameEngine
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedMood: Int? = nil
    @State private var journalText: String = ""
    @State private var showJournal: Bool = false
    @State private var checkInResult: MoodCheckInResult? = nil
    @State private var showResult: Bool = false
    
    private let moods: [(level: Int, emoji: String, label: String)] = [
        (1, "😞", "Rough"),
        (2, "😔", "Low"),
        (3, "😐", "Okay"),
        (4, "😊", "Good"),
        (5, "😄", "Great")
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "heart.text.square.fill")
                    .foregroundColor(Color("AccentPink"))
                Text("How are you feeling?")
                    .font(.custom("Avenir-Heavy", size: 18))
                Spacer()
                if character.moodStreak > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                        Text("\(character.moodStreak)")
                            .font(.custom("Avenir-Heavy", size: 12))
                    }
                    .foregroundColor(Color("AccentOrange"))
                }
            }
            
            if showResult, let result = checkInResult {
                // Show reward after check-in
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color("AccentGreen"))
                        Text("Mood logged!")
                            .font(.custom("Avenir-Heavy", size: 15))
                            .foregroundColor(Color("AccentGreen"))
                    }
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 10))
                            Text("+\(result.expGained) EXP")
                                .font(.custom("Avenir-Heavy", size: 13))
                        }
                        .foregroundColor(Color("AccentGold"))
                        
                        HStack(spacing: 4) {
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.system(size: 10))
                            Text("+\(result.goldGained) Gold")
                                .font(.custom("Avenir-Heavy", size: 13))
                        }
                        .foregroundColor(Color("AccentGold"))
                    }
                }
            } else if character.hasLoggedMoodToday {
                // Already logged today
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color("AccentGreen"))
                    Text("Mood logged today")
                        .font(.custom("Avenir-Medium", size: 14))
                        .foregroundColor(Color("AccentGreen"))
                    Spacer()
                }
            } else if let mood = selectedMood {
                // Journal step
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Text(moods.first(where: { $0.level == mood })?.emoji ?? "😐")
                            .font(.title2)
                        Text(moods.first(where: { $0.level == mood })?.label ?? "Okay")
                            .font(.custom("Avenir-Heavy", size: 16))
                        Spacer()
                        Button("Change") {
                            withAnimation { selectedMood = nil; showJournal = false }
                        }
                        .font(.custom("Avenir-Medium", size: 13))
                        .foregroundColor(Color("AccentGold"))
                    }
                    
                    // Optional journal
                    TextField("Add a note (optional)...", text: $journalText, axis: .vertical)
                        .font(.custom("Avenir-Medium", size: 14))
                        .lineLimit(1...4)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.secondary.opacity(0.1))
                        )
                    
                    // Save button
                    Button(action: saveMood) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save")
                        }
                        .font(.custom("Avenir-Heavy", size: 15))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color("AccentGold"), Color("AccentOrange")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            } else {
                // Mood emoji picker
                HStack(spacing: 0) {
                    ForEach(moods, id: \.level) { mood in
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                selectedMood = mood.level
                            }
                        }) {
                            VStack(spacing: 4) {
                                Text(mood.emoji)
                                    .font(.system(size: 32))
                                Text(mood.label)
                                    .font(.custom("Avenir-Medium", size: 10))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Reward preview
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 9))
                        Text("+20 EXP")
                            .font(.custom("Avenir-Heavy", size: 11))
                    }
                    .foregroundColor(Color("AccentGold").opacity(0.7))
                    
                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 9))
                        Text("+15 Gold")
                            .font(.custom("Avenir-Heavy", size: 11))
                    }
                    .foregroundColor(Color("AccentGold").opacity(0.7))
                    
                    if character.moodStreak >= 3 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 9))
                            Text("streak bonus!")
                                .font(.custom("Avenir-Heavy", size: 11))
                        }
                        .foregroundColor(Color("AccentOrange").opacity(0.7))
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
    }
    
    private func saveMood() {
        guard let mood = selectedMood else { return }
        let result = gameEngine.logMood(
            character: character,
            moodLevel: mood,
            journal: journalText.isEmpty ? nil : journalText,
            context: modelContext
        )
        checkInResult = result
        if let result = result {
            ToastManager.shared.showSuccess(
                "Mood Logged!",
                subtitle: "+\(result.expGained) EXP, +\(result.goldGained) Gold"
            )
        }
        withAnimation {
            showResult = true
        }
        AudioManager.shared.play(.claimReward)
    }
}

// MARK: - Daily Tip Card

struct DailyTipCard: View {
    private let tips = [
        "Complete tasks consistently to build your streak and earn bonus EXP!",
        "Physical tasks boost your Strength stat over time.",
        "Send your hero on training while you sleep to maximize growth.",
        "Verified tasks give more EXP — use photo or location proof!",
        "Check the duty board for tasks you can claim from your partner.",
        "Complete your 3 daily quests for a bonus reward!",
        "Dungeon rooms test specific stats — level up the right ones before diving in."
    ]
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(Color("AccentGold"))
                .font(.title2)
            
            Text(tips.randomElement() ?? tips[0])
                .font(.custom("Avenir-Medium", size: 14))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground").opacity(0.5))
        )
    }
}

// MARK: - Productivity Overview Card

struct ProductivityCard: View {
    let completedTasks: [GameTask]
    @State private var showAnalytics = false
    
    private var weekDays: [DayData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Calculate start of week (Monday)
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else {
            return []
        }
        
        let dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        
        return (0..<7).map { offset in
            let day = calendar.date(byAdding: .day, value: offset, to: monday)!
            let nextDay = calendar.date(byAdding: .day, value: 1, to: day)!
            let count = completedTasks.filter { task in
                guard let completed = task.completedAt else { return false }
                return completed >= day && completed < nextDay
            }.count
            let isToday = calendar.isDateInToday(day)
            return DayData(label: dayLabels[offset], count: count, isToday: isToday)
        }
    }
    
    private var categoryBreakdown: [(category: TaskCategory, count: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else {
            return []
        }
        
        let thisWeekTasks = completedTasks.filter { task in
            guard let completed = task.completedAt else { return false }
            return completed >= monday
        }
        
        return TaskCategory.allCases.compactMap { cat in
            let count = thisWeekTasks.filter { $0.category == cat }.count
            return count > 0 ? (category: cat, count: count) : nil
        }.sorted { $0.count > $1.count }
    }
    
    private var maxCount: Int {
        max(1, weekDays.map(\.count).max() ?? 1)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(Color("AccentGold"))
                Text("This Week")
                    .font(.custom("Avenir-Heavy", size: 18))
                Spacer()
                let totalThisWeek = weekDays.reduce(0) { $0 + $1.count }
                Text("\(totalThisWeek) tasks")
                    .font(.custom("Avenir-Medium", size: 13))
                    .foregroundColor(.secondary)
                NavigationLink(destination: TaskAnalyticsView()) {
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(Color("AccentGold"))
                }
            }
            
            // 7-day bar chart
            Chart(weekDays, id: \.label) { day in
                BarMark(
                    x: .value("Day", day.label),
                    y: .value("Tasks", day.count)
                )
                .foregroundStyle(
                    day.isToday ?
                    LinearGradient(colors: [Color("AccentGold"), Color("AccentOrange")], startPoint: .bottom, endPoint: .top) :
                    LinearGradient(colors: [Color("AccentGold").opacity(0.4), Color("AccentGold").opacity(0.6)], startPoint: .bottom, endPoint: .top)
                )
                .cornerRadius(4)
            }
            .chartYScale(domain: 0...max(maxCount, 3))
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 3)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Color.secondary.opacity(0.3))
                    AxisValueLabel()
                        .font(.custom("Avenir-Medium", size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .font(.custom("Avenir-Medium", size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 120)
            
            // Category pills
            if !categoryBreakdown.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categoryBreakdown, id: \.category) { item in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color(item.category.color))
                                    .frame(width: 8, height: 8)
                                Text("\(item.category.rawValue) \(item.count)")
                                    .font(.custom("Avenir-Heavy", size: 11))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule().fill(Color(item.category.color).opacity(0.15))
                            )
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
    }
}

/// Data point for the weekly chart
private struct DayData {
    let label: String
    let count: Int
    let isToday: Bool
}

// MARK: - Animated RGB Background

// MARK: - Animated RGB Background (self-contained animation)

struct AnimatedHomeBackground: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [Color("BackgroundTop"), Color("BackgroundBottom")],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Slow-shifting colored orbs — full screen coverage
            Canvas { context, size in
                let w = size.width
                let h = size.height
                
                // Top gold orb (large, drifts right)
                let gold1Center = CGPoint(
                    x: w * (0.15 + 0.25 * phase),
                    y: h * (0.05 + 0.08 * phase)
                )
                let gold1Radius = w * 0.7
                context.drawLayer { ctx in
                    ctx.opacity = 0.35
                    let gradient = Gradient(colors: [Color("AccentGold"), .clear])
                    ctx.fill(
                        Path(ellipseIn: CGRect(
                            x: gold1Center.x - gold1Radius,
                            y: gold1Center.y - gold1Radius,
                            width: gold1Radius * 2,
                            height: gold1Radius * 2
                        )),
                        with: .radialGradient(gradient, center: gold1Center, startRadius: 0, endRadius: gold1Radius)
                    )
                }
                
                // Right purple orb (drifts down)
                let purpleCenter = CGPoint(
                    x: w * (0.9 - 0.2 * phase),
                    y: h * (0.25 + 0.15 * phase)
                )
                let purpleRadius = w * 0.65
                context.drawLayer { ctx in
                    ctx.opacity = 0.3
                    let gradient = Gradient(colors: [Color("AccentPurple"), .clear])
                    ctx.fill(
                        Path(ellipseIn: CGRect(
                            x: purpleCenter.x - purpleRadius,
                            y: purpleCenter.y - purpleRadius,
                            width: purpleRadius * 2,
                            height: purpleRadius * 2
                        )),
                        with: .radialGradient(gradient, center: purpleCenter, startRadius: 0, endRadius: purpleRadius)
                    )
                }
                
                // Center-left orange orb (drifts up-right)
                let orangeCenter = CGPoint(
                    x: w * (0.3 + 0.2 * phase),
                    y: h * (0.55 - 0.1 * phase)
                )
                let orangeRadius = w * 0.6
                context.drawLayer { ctx in
                    ctx.opacity = 0.25
                    let gradient = Gradient(colors: [Color("AccentOrange"), .clear])
                    ctx.fill(
                        Path(ellipseIn: CGRect(
                            x: orangeCenter.x - orangeRadius,
                            y: orangeCenter.y - orangeRadius,
                            width: orangeRadius * 2,
                            height: orangeRadius * 2
                        )),
                        with: .radialGradient(gradient, center: orangeCenter, startRadius: 0, endRadius: orangeRadius)
                    )
                }
                
                // Bottom-left gold orb
                let gold2Center = CGPoint(
                    x: w * (0.15 + 0.15 * phase),
                    y: h * (0.8 - 0.1 * phase)
                )
                let gold2Radius = w * 0.55
                context.drawLayer { ctx in
                    ctx.opacity = 0.25
                    let gradient = Gradient(colors: [Color("AccentGold"), .clear])
                    ctx.fill(
                        Path(ellipseIn: CGRect(
                            x: gold2Center.x - gold2Radius,
                            y: gold2Center.y - gold2Radius,
                            width: gold2Radius * 2,
                            height: gold2Radius * 2
                        )),
                        with: .radialGradient(gradient, center: gold2Center, startRadius: 0, endRadius: gold2Radius)
                    )
                }
                
                // Bottom-right purple orb
                let purple2Center = CGPoint(
                    x: w * (0.8 - 0.15 * phase),
                    y: h * (0.85 + 0.05 * phase)
                )
                let purple2Radius = w * 0.5
                context.drawLayer { ctx in
                    ctx.opacity = 0.2
                    let gradient = Gradient(colors: [Color("AccentPurple"), .clear])
                    ctx.fill(
                        Path(ellipseIn: CGRect(
                            x: purple2Center.x - purple2Radius,
                            y: purple2Center.y - purple2Radius,
                            width: purple2Radius * 2,
                            height: purple2Radius * 2
                        )),
                        with: .radialGradient(gradient, center: purple2Center, startRadius: 0, endRadius: purple2Radius)
                    )
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: true)) {
                phase = 1
            }
        }
    }
}

// MARK: - Begin Quest View (self-contained animation)

struct BeginQuestView: View {
    @Binding var showCharacterCreation: Bool
    
    @State private var sparkleScale: CGFloat = 1.0
    @State private var buttonPulse: CGFloat = 1.0
    @State private var particlePhase: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "sparkles")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color("AccentGold"), Color("AccentOrange")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.variableColor.iterative, options: .repeating)
                .scaleEffect(sparkleScale)
            
            Text("Begin Your Quest")
                .font(.custom("Avenir-Heavy", size: 32))
                .foregroundColor(.primary)
            
            Text("Create your character and start\nearning EXP through real-life tasks")
                .font(.custom("Avenir-Medium", size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { showCharacterCreation = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Character")
                }
                .font(.custom("Avenir-Heavy", size: 18))
                .foregroundColor(.black)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color("AccentGold"), Color("AccentOrange")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color("AccentGold").opacity(0.4), radius: buttonPulse > 1.0 ? 16 : 6)
            }
            .scaleEffect(buttonPulse)
            
            Spacer()
        }
        .padding()
        .background(FloatingParticles())
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                sparkleScale = 1.08
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                buttonPulse = 1.04
            }
        }
    }
}

// MARK: - Floating Particles (self-contained animation)

struct FloatingParticles: View {
    @State private var phase: CGFloat = 0
    private let particleCount = 15
    
    var body: some View {
        Canvas { context, size in
            for i in 0..<particleCount {
                let seed = Double(i)
                let xBase = (seed * 73.0).truncatingRemainder(dividingBy: 100.0) / 100.0
                let dotSize = CGFloat(3 + Int(seed * 17) % 5)
                let speed = 0.4 + (seed * 31).truncatingRemainder(dividingBy: 60) / 100.0
                let delayVal = (seed * 47).truncatingRemainder(dividingBy: 100) / 100.0
                
                let yProgress = (Double(phase) * speed + delayVal).truncatingRemainder(dividingBy: 1.0)
                let x = size.width * xBase
                let y = size.height * (1.0 - yProgress)
                let alpha = 0.3 + 0.5 * sin(.pi * yProgress)
                
                let color: Color = i % 3 == 0 ? Color("AccentGold") :
                                    i % 3 == 1 ? Color("AccentOrange") :
                                    Color("AccentPurple")
                
                context.drawLayer { ctx in
                    ctx.opacity = alpha
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: x - dotSize/2, y: y - dotSize/2, width: dotSize, height: dotSize)),
                        with: .color(color)
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }
}

// MARK: - Card Entrance Animation Modifier

struct CardEntranceModifier: ViewModifier {
    let visible: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 20)
    }
}

extension View {
    func cardEntrance(visible: Bool, delay: Int) -> some View {
        modifier(CardEntranceModifier(visible: visible))
    }
}

// MARK: - Party Bar Card

/// Compact horizontal bar showing party allies on the Home screen.
/// Displays each ally's avatar, name, level, and a quick status indicator.
struct PartyBarCard: View {
    let character: PlayerCharacter
    let bond: Bond?
    
    private static let memberColors: [String] = ["AccentPurple", "AccentOrange", "AccentGreen"]
    
    var body: some View {
        VStack(spacing: 12) {
            // Header row
            HStack {
                Image(systemName: "person.3.fill")
                    .font(.caption)
                    .foregroundColor(Color("AccentPink"))
                Text("Your Party")
                    .font(.custom("Avenir-Heavy", size: 13))
                    .foregroundColor(Color("AccentPink"))
                
                Spacer()
                
                if let streakDays = bond?.partyStreakDays, streakDays > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                        Text("\(streakDays)d streak")
                            .font(.custom("Avenir-Heavy", size: 10))
                    }
                    .foregroundColor(Color("AccentOrange"))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color("AccentOrange").opacity(0.12))
                    .clipShape(Capsule())
                }
            }
            
            // Ally cards
            HStack(spacing: 10) {
                ForEach(Array(character.partyMembers.enumerated()), id: \.element.id) { index, member in
                    allyCell(member: member, color: Self.memberColors[index % Self.memberColors.count])
                }
                
                Spacer(minLength: 0)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)
        )
    }
    
    private func allyCell(member: CachedPartyMember, color: String) -> some View {
        HStack(spacing: 10) {
            // Avatar
            ZStack {
                if UIImage(named: member.displayAvatarIcon) != nil {
                    Image(member.displayAvatarIcon)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color(color).opacity(0.18))
                        .frame(width: 40, height: 40)
                    Image(systemName: member.displayAvatarIcon)
                        .font(.body)
                        .foregroundColor(Color(color))
                }
            }
            
            // Name, level, status
            VStack(alignment: .leading, spacing: 2) {
                Text(member.name)
                    .font(.custom("Avenir-Heavy", size: 13))
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text("Lv.\(member.level)")
                        .font(.custom("Avenir-Medium", size: 11))
                        .foregroundColor(Color(color))
                    
                    if let cls = member.className {
                        Text("·")
                            .font(.custom("Avenir-Medium", size: 11))
                            .foregroundColor(.secondary)
                        Text(cls)
                            .font(.custom("Avenir-Medium", size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(color).opacity(0.06))
        )
    }
}

// MARK: - Partner Request Notification Card

struct PartnerRequestNotificationCard: View {
    let request: PartnerRequest
    let senderProfile: Profile?
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    @State private var glowPulse: Bool = false
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color("AccentPink").opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.title2)
                    .foregroundColor(Color("AccentPink"))
                    .symbolEffect(.pulse, options: .repeating.speed(0.5))
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text("Partner Request!")
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(Color("AccentPink"))
                
                if let profile = senderProfile {
                    Text("\(profile.characterName ?? "An adventurer") wants to pair with you")
                        .font(.custom("Avenir-Medium", size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    if let level = profile.level {
                        Text("Level \(level)")
                            .font(.custom("Avenir-Medium", size: 12))
                            .foregroundColor(Color("AccentGold"))
                    }
                } else {
                    Text("Someone wants to pair with you")
                        .font(.custom("Avenir-Medium", size: 13))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 8) {
                Button(action: onAccept) {
                    Text("Accept")
                        .font(.custom("Avenir-Heavy", size: 12))
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color("AccentGold"))
                        .clipShape(Capsule())
                }
                
                Button(action: onDecline) {
                    Text("Decline")
                        .font(.custom("Avenir-Heavy", size: 11))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .shadow(
                    color: Color("AccentPink").opacity(glowPulse ? 0.25 : 0.1),
                    radius: glowPulse ? 12 : 6,
                    x: 0, y: 4
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [Color("AccentPink").opacity(0.4), Color("AccentPurple").opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1.5
                )
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }
}

// MARK: - Party Dungeon Invite Card

struct PartyDungeonInviteCard: View {
    let invite: DungeonInviteWithDetails
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    @State private var glowPulse: Bool = false
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color("AccentPurple").opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "door.left.hand.open")
                    .font(.title2)
                    .foregroundColor(Color("AccentPurple"))
                    .symbolEffect(.pulse, options: .repeating.speed(0.5))
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text("Party Dungeon Invite!")
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(Color("AccentPurple"))
                
                Text("\(invite.hostName) invites you to run **\(invite.invite.dungeonName)**")
                    .font(.custom("Avenir-Medium", size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 8) {
                Button(action: onAccept) {
                    Text("Accept")
                        .font(.custom("Avenir-Heavy", size: 12))
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color("AccentGold"))
                        .clipShape(Capsule())
                }
                
                Button(action: onDecline) {
                    Text("Decline")
                        .font(.custom("Avenir-Heavy", size: 11))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .shadow(
                    color: Color("AccentPurple").opacity(glowPulse ? 0.25 : 0.1),
                    radius: glowPulse ? 12 : 6,
                    x: 0, y: 4
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [Color("AccentPurple").opacity(0.4), Color("AccentPurple").opacity(0.2)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1.5
                )
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }
}

// MARK: - Goals Summary Home Card

struct GoalsSummaryHomeCard: View {
    let goals: [Goal]
    let allTasks: [GameTask]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flag.fill")
                    .foregroundColor(Color("AccentGold"))
                Text("Active Goals")
                    .font(.custom("Avenir-Heavy", size: 16))
                
                Spacer()
                
                NavigationLink(destination: GoalsView()) {
                    Text("See All")
                        .font(.custom("Avenir-Medium", size: 13))
                        .foregroundColor(Color("AccentGold"))
                }
            }
            
            ForEach(goals.prefix(3)) { goal in
                NavigationLink(destination: GoalDetailView(goal: goal)) {
                    goalRow(goal)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
    }
    
    private func goalRow(_ goal: Goal) -> some View {
        let progress = GameEngine.calculateGoalProgress(goal: goal, tasks: allTasks)
        
        return HStack(spacing: 10) {
            Image(systemName: goal.category.icon)
                .font(.callout)
                .foregroundColor(Color(goal.category.color))
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.title)
                    .font(.custom("Avenir-Medium", size: 14))
                    .lineLimit(1)
                
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
            
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Breadcrumb Quest Log Card

/// Guided "next step" card for the first 7 days after onboarding.
/// Each breadcrumb disappears after the action is taken. All gone after 7 days.
struct BreadcrumbQuestLogCard: View {
    let character: PlayerCharacter
    
    private let breadcrumbs: [(id: String, day: Int, title: String, subtitle: String, icon: String, tab: String)] = [
        ("tryDungeon", 1, "Try Your First Dungeon", "Test your hero's strength in battle!", "map.fill", "Adventures"),
        ("sendMission", 2, "Send Your Hero on a Mission", "AFK training earns rewards while you're away.", "figure.walk", "Adventures"),
        ("inviteFriend", 3, "Invite a Friend to Your Party", "Accountability is better with allies.", "person.2.fill", "Party"),
        ("visitForge", 4, "Visit the Forge", "Craft and enhance your equipment.", "hammer.fill", "Forge"),
        ("checkStore", 5, "Check the Store for Daily Deals", "The shopkeeper has new items every day.", "cart.fill", "Store"),
    ]
    
    /// The next uncompleted breadcrumb to show
    private var currentBreadcrumb: (id: String, day: Int, title: String, subtitle: String, icon: String, tab: String)? {
        let daysSinceCreation = Calendar.current.dateComponents([.day], from: character.createdAt, to: Date()).day ?? 0
        
        return breadcrumbs.first { breadcrumb in
            let isCompleted = character.onboardingBreadcrumbs[breadcrumb.id] ?? false
            return !isCompleted && daysSinceCreation >= (breadcrumb.day - 1)
        }
    }
    
    /// Resolve the destination view for a breadcrumb's tab
    @ViewBuilder
    private func breadcrumbDestination(for tab: String) -> some View {
        switch tab {
        case "Adventures":
            AdventuresHubView()
        case "Party":
            PartnerView()
        case "Forge":
            ForgeView()
        case "Store":
            StoreView()
        default:
            TasksView(isEmbedded: true)
        }
    }
    
    var body: some View {
        if let breadcrumb = currentBreadcrumb {
            NavigationLink(destination: breadcrumbDestination(for: breadcrumb.tab)) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "scroll.fill")
                            .foregroundColor(Color("AccentGold"))
                        Text("Quest Log")
                            .font(.custom("Avenir-Heavy", size: 16))
                        Spacer()
                        
                        // Days remaining indicator
                        let daysLeft = max(0, 7 - (Calendar.current.dateComponents([.day], from: character.createdAt, to: Date()).day ?? 0))
                        if daysLeft > 0 {
                            Text("\(daysLeft)d left")
                                .font(.custom("Avenir-Medium", size: 11))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.secondary.opacity(0.15)))
                        }
                    }
                    
                    HStack(spacing: 14) {
                        Image(systemName: breadcrumb.icon)
                            .font(.system(size: 22))
                            .foregroundColor(Color("AccentGold"))
                            .frame(width: 40, height: 40)
                            .background(Color("AccentGold").opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(breadcrumb.title)
                                .font(.custom("Avenir-Heavy", size: 15))
                            Text(breadcrumb.subtitle)
                                .font(.custom("Avenir-Medium", size: 13))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Progress dots
                    HStack(spacing: 6) {
                        ForEach(breadcrumbs, id: \.id) { bc in
                            let isCompleted = character.onboardingBreadcrumbs[bc.id] ?? false
                            Circle()
                                .fill(isCompleted ? Color("AccentGreen") : Color.secondary.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                        Spacer()
                        
                        Text("+10 Gold each")
                            .font(.custom("Avenir-Medium", size: 11))
                            .foregroundColor(Color("AccentGold"))
                    }
                }
                .padding(16)
                .background(Color("CardBackground"))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [Color("AccentGold").opacity(0.3), Color("AccentOrange").opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Weekly Progress Summary Card

struct WeeklyProgressCard: View {
    let allTasks: [GameTask]
    let character: PlayerCharacter
    
    private var thisWeekTasks: [GameTask] {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return allTasks.filter { task in
            task.status == .completed &&
            task.completedBy == character.id &&
            (task.completedAt ?? .distantPast) >= weekAgo
        }
    }
    
    private var lastWeekTasks: [GameTask] {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        return allTasks.filter { task in
            task.status == .completed &&
            task.completedBy == character.id &&
            (task.completedAt ?? .distantPast) >= twoWeeksAgo &&
            (task.completedAt ?? .distantPast) < weekAgo
        }
    }
    
    private var weekChange: Int {
        thisWeekTasks.count - lastWeekTasks.count
    }
    
    private var bestCategory: TaskCategory? {
        let counts = Dictionary(grouping: thisWeekTasks, by: { $0.category })
        return counts.max(by: { $0.value.count < $1.value.count })?.key
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(Color("AccentGold"))
                Text("Weekly Progress")
                    .font(.custom("Avenir-Heavy", size: 18))
                Spacer()
            }
            
            HStack(spacing: 20) {
                // This Week
                VStack(spacing: 4) {
                    Text("\(thisWeekTasks.count)")
                        .font(.custom("Avenir-Heavy", size: 28))
                        .foregroundColor(Color("AccentGold"))
                    Text("This Week")
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                // Comparison Arrow
                VStack(spacing: 2) {
                    Image(systemName: weekChange >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .foregroundColor(weekChange >= 0 ? Color("AccentGreen") : Color("AccentOrange"))
                        .font(.title3)
                    Text(weekChange >= 0 ? "+\(weekChange)" : "\(weekChange)")
                        .font(.custom("Avenir-Heavy", size: 14))
                        .foregroundColor(weekChange >= 0 ? Color("AccentGreen") : Color("AccentOrange"))
                }
                
                // Last Week
                VStack(spacing: 4) {
                    Text("\(lastWeekTasks.count)")
                        .font(.custom("Avenir-Heavy", size: 28))
                        .foregroundColor(.secondary)
                    Text("Last Week")
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            
            Divider()
            
            // Quick stats row
            HStack(spacing: 16) {
                // Streak
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(Color("AccentOrange"))
                        .font(.caption)
                    Text("\(character.currentStreak)d streak")
                        .font(.custom("Avenir-Medium", size: 13))
                }
                
                Spacer()
                
                // Best category this week
                if let best = bestCategory {
                    HStack(spacing: 4) {
                        Image(systemName: best.icon)
                            .foregroundColor(Color(best.color))
                            .font(.caption)
                        Text("Top: \(best.rawValue)")
                            .font(.custom("Avenir-Medium", size: 13))
                            .foregroundColor(.secondary)
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
}

// MARK: - Leaderboard Summary Card

struct LeaderboardSummaryCard: View {
    let allTasks: [GameTask]
    let character: PlayerCharacter
    
    private var thisWeekCompleted: [GameTask] {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return allTasks.filter { task in
            task.status == .completed &&
            (task.completedAt ?? .distantPast) >= weekAgo
        }
    }
    
    /// For solo players: show personal best week count
    private var isSolo: Bool {
        character.partnerCharacterID == nil
    }
    
    /// My task count this week
    private var myCount: Int {
        thisWeekCompleted.filter { $0.completedBy == character.id }.count
    }
    
    /// Partner task count this week
    private var partnerCount: Int {
        guard let partnerID = character.partnerCharacterID else { return 0 }
        return thisWeekCompleted.filter { $0.completedBy == partnerID }.count
    }
    
    /// Leader name and count
    private var leader: (name: String, count: Int) {
        if isSolo {
            return (character.name, myCount)
        }
        if myCount >= partnerCount {
            return (character.name, myCount)
        } else {
            return (character.partnerName ?? "Ally", partnerCount)
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "trophy.fill")
                    .foregroundColor(Color("AccentGold"))
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    if isSolo {
                        Text("Your Week")
                            .font(.custom("Avenir-Heavy", size: 16))
                        Text("\(myCount) tasks completed this week")
                            .font(.custom("Avenir-Medium", size: 13))
                            .foregroundColor(.secondary)
                    } else {
                        Text("This Week's Leader")
                            .font(.custom("Avenir-Heavy", size: 16))
                        HStack(spacing: 4) {
                            Text(leader.name)
                                .font(.custom("Avenir-Heavy", size: 14))
                                .foregroundColor(Color("AccentGold"))
                            Text("— \(leader.count) tasks")
                                .font(.custom("Avenir-Medium", size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                if !isSolo {
                    // Mini score comparison
                    VStack(spacing: 2) {
                        HStack(spacing: 4) {
                            Text("You")
                                .font(.custom("Avenir-Medium", size: 11))
                            Text("\(myCount)")
                                .font(.custom("Avenir-Heavy", size: 14))
                                .foregroundColor(Color("AccentGold"))
                        }
                        HStack(spacing: 4) {
                            Text("Ally")
                                .font(.custom("Avenir-Medium", size: 11))
                            Text("\(partnerCount)")
                                .font(.custom("Avenir-Heavy", size: 14))
                                .foregroundColor(Color("AccentPurple"))
                        }
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

#Preview {
    HomeView()
        .environmentObject(GameEngine())
}
