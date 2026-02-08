import SwiftUI
import SwiftData
import Charts

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var gameEngine: GameEngine
    @Query private var characters: [PlayerCharacter]
    @Query private var allTasks: [GameTask]
    @Query private var missions: [AFKMission]
    
    private var pendingTasks: [GameTask] {
        allTasks.filter { $0.status == .pending }
    }
    
    @State private var showCharacterCreation = false
    @State private var showCreateTask = false
    @State private var showLevelUpSheet = false
    @State private var showMissionCompletionResult = false
    @State private var lastMissionResult: MissionCompletionResult?
    
    // Card entrance animation
    @State private var cardsVisible: [Bool] = Array(repeating: false, count: 10)
    
    private var character: PlayerCharacter? {
        characters.first
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if let character = character {
                    ScrollView {
                        VStack(spacing: 24) {
                            // 1. Character Summary Card
                            CharacterSummaryCard(character: character)
                                .cardEntrance(visible: cardsVisible[0], delay: 0)
                            
                            // 2. Productivity Overview Card
                            ProductivityCard(completedTasks: allTasks.filter { $0.status == .completed })
                                .cardEntrance(visible: cardsVisible[1], delay: 1)
                            
                            // 3. Daily Quests Card
                            DailyQuestsCard(
                                quests: gameEngine.dailyQuests,
                                character: character,
                                gameEngine: gameEngine,
                                modelContext: modelContext
                            )
                            .cardEntrance(visible: cardsVisible[2], delay: 2)
                            
                            // 4. Meditation Card
                            MeditationHomeCard(character: character)
                                .cardEntrance(visible: cardsVisible[3], delay: 3)
                            
                            // 5. Quick Actions Grid
                            QuickActionsGrid(showCreateTask: $showCreateTask)
                                .cardEntrance(visible: cardsVisible[4], delay: 4)
                            
                            // 6. Active Training Card
                            if let activeMission = gameEngine.activeMission {
                                ActiveMissionCard(
                                    mission: activeMission,
                                    onClaim: { claimMissionFromHome() }
                                )
                                .cardEntrance(visible: cardsVisible[5], delay: 5)
                            }
                            
                            // 7. Next Milestone Card
                            NextMilestoneCard(character: character)
                                .cardEntrance(visible: cardsVisible[6], delay: 6)
                            
                            // 8. Quick Stats
                            QuickStatsGrid(character: character)
                                .cardEntrance(visible: cardsVisible[7], delay: 7)
                            
                            // 9. My Tasks Preview
                            TodaysTasksCard(tasks: Array(pendingTasks.prefix(3)))
                                .cardEntrance(visible: cardsVisible[8], delay: 8)
                            
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
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showCharacterCreation) {
                CharacterCreationView()
            }
            .sheet(isPresented: $showCreateTask) {
                CreateTaskView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .fullScreenCover(isPresented: $showLevelUpSheet) {
                if !gameEngine.pendingLevelUpRewards.isEmpty, let character = character {
                    LevelUpCelebrationView(
                        character: character,
                        rewards: gameEngine.pendingLevelUpRewards,
                        onDismiss: {
                            gameEngine.showLevelUpCelebration = false
                            gameEngine.pendingLevelUpRewards = []
                            showLevelUpSheet = false
                        }
                    )
                }
            }
            .fullScreenCover(isPresented: $showMissionCompletionResult) {
                if let result = lastMissionResult {
                    MissionCompletionView(result: result)
                }
            }
            .onAppear {
                if let character = character {
                    gameEngine.checkAndRefreshDailyQuests(for: character, context: modelContext)
                }
            }
            .onChange(of: gameEngine.showLevelUpCelebration) { _, newValue in
                if newValue {
                    showLevelUpSheet = true
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
    
    @State private var levelGlow: Bool = false
    @State private var expShimmer: CGFloat = -0.3
    @State private var expBarAppeared: Bool = false
    @State private var borderRotation: Double = 0
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
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
        }
    }
}

// MARK: - Daily Quests Card

struct DailyQuestsCard: View {
    let quests: [DailyQuest]
    let character: PlayerCharacter
    let gameEngine: GameEngine
    let modelContext: ModelContext
    
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
                        gameEngine.claimDailyQuestReward(quest, character: character, context: modelContext)
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
                                gameEngine.claimDailyQuestReward(bonus, character: character, context: modelContext)
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
                NavigationLink(destination: DungeonListView()) {
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
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundColor(Color("AccentGold"))
                    .symbolEffect(.pulse, options: .repeating)
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

// MARK: - Next Milestone Card

struct NextMilestoneCard: View {
    let character: PlayerCharacter
    
    @State private var shimmerOffset: CGFloat = -0.3
    @State private var levelPulse: CGFloat = 1.0
    
    private var milestone: (icon: String, title: String, description: String, levelsAway: Int)? {
        let level = character.level
        
        // Class unlock at level 10
        if level < 10 && character.characterClass == nil {
            return ("sparkles", "Class Unlock", "Choose your class at Level 10", 10 - level)
        }
        
        // Next class evolution at level 20
        if level < 20 {
            return ("arrow.up.forward.circle.fill", "Class Evolution", "Evolve your class at Level 20", 20 - level)
        }
        
        return nil
    }
    
    var body: some View {
        if let ms = milestone {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color("AccentGold").opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: ms.icon)
                        .font(.title3)
                        .foregroundColor(Color("AccentGold"))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(ms.title)
                        .font(.custom("Avenir-Heavy", size: 15))
                    Text(ms.description)
                        .font(.custom("Avenir-Medium", size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(spacing: 0) {
                    Text("\(ms.levelsAway)")
                        .font(.custom("Avenir-Heavy", size: 22))
                        .foregroundColor(Color("AccentGold"))
                        .scaleEffect(levelPulse)
                    Text(ms.levelsAway == 1 ? "level" : "levels")
                        .font(.custom("Avenir-Medium", size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color("CardBackground"))
                    
                    // Shimmer sweep over background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: shimmerOffset - 0.15),
                                    .init(color: Color("AccentGold").opacity(0.08), location: shimmerOffset),
                                    .init(color: .clear, location: shimmerOffset + 0.15)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
            .onAppear {
                withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                    shimmerOffset = 1.3
                }
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    levelPulse = 1.1
                }
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

// MARK: - My Tasks Card

struct TodaysTasksCard: View {
    let tasks: [GameTask]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("My Tasks")
                    .font(.custom("Avenir-Heavy", size: 18))
                Spacer()
                NavigationLink(destination: TasksView()) {
                    Text("See All")
                        .font(.custom("Avenir-Medium", size: 14))
                        .foregroundColor(Color("AccentGold"))
                }
            }
            
            if tasks.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.title)
                            .foregroundColor(Color("AccentGreen"))
                        Text("All caught up!")
                            .font(.custom("Avenir-Medium", size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                ForEach(tasks, id: \.id) { task in
                    NavigationLink(destination: TaskDetailView(task: task)) {
                        TaskPreviewRow(task: task)
                    }
                    .buttonStyle(.plain)
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

struct TaskPreviewRow: View {
    let task: GameTask
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: task.category.icon)
                .foregroundColor(Color(task.category.color))
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.custom("Avenir-Medium", size: 14))
                Text("+\(task.expReward) EXP")
                    .font(.custom("Avenir-Medium", size: 12))
                    .foregroundColor(Color("AccentGold"))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.1))
        )
    }
}

// MARK: - Meditation Home Card

struct MeditationHomeCard: View {
    let character: PlayerCharacter
    @State private var showMeditation = false
    
    var body: some View {
        VStack(spacing: 0) {
            Button {
                showMeditation = true
            } label: {
                HStack(spacing: 16) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(
                                character.hasMeditatedToday ?
                                Color("AccentGreen").opacity(0.2) :
                                Color("AccentPurple").opacity(0.2)
                            )
                            .frame(width: 56, height: 56)
                        Image(systemName: "brain.head.profile")
                            .font(.title2)
                            .foregroundColor(
                                character.hasMeditatedToday ?
                                Color("AccentGreen") : Color("AccentPurple")
                            )
                    }
                    
                    // Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Daily Meditation")
                            .font(.custom("Avenir-Heavy", size: 18))
                        
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
                    
                    // Streak Badge
                    VStack(spacing: 2) {
                        Text("\(character.meditationStreak)")
                            .font(.custom("Avenir-Heavy", size: 24))
                            .foregroundColor(Color("AccentGold"))
                        Text("streak")
                            .font(.custom("Avenir-Medium", size: 10))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("AccentGold").opacity(0.1))
                    )
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color("CardBackground"))
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                )
            }
            .buttonStyle(.plain)
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

#Preview {
    HomeView()
        .environmentObject(GameEngine())
}
