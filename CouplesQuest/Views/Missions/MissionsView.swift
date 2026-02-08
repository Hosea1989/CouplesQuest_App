import SwiftUI
import SwiftData

struct MissionsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var gameEngine: GameEngine
    @Query private var characters: [PlayerCharacter]
    @Query private var missions: [AFKMission]
    @Query(sort: \DungeonRun.startedAt, order: .reverse) private var dungeonRuns: [DungeonRun]
    
    @State private var showCompletionResult = false
    @State private var lastMissionResult: MissionCompletionResult?
    @State private var missionStartTrigger = 0
    @State private var claimTrigger = 0
    
    private var character: PlayerCharacter? {
        characters.first
    }
    
    /// Whether there is an active (in-progress) dungeon run
    private var hasActiveDungeonRun: Bool {
        dungeonRuns.contains { $0.status == .inProgress }
    }
    
    private var displayedMissions: [AFKMission] {
        if missions.isEmpty {
            return SampleMissions.all
        } else {
            return missions.filter { $0.isAvailable }
        }
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
                        // Active Mission Card
                        if let activeMission = gameEngine.activeMission,
                           let mission = missions.first(where: { $0.id == activeMission.missionID }) {
                            ActiveMissionDetailCard(
                                activeMission: activeMission,
                                mission: mission,
                                onClaim: {
                                    claimMissionRewards(mission: mission)
                                }
                            )
                        }
                        
                        // Available Training Sessions
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Available Training")
                                .font(.custom("Avenir-Heavy", size: 20))
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                ForEach(displayedMissions, id: \.id) { mission in
                                    NavigationLink(destination: TrainingDetailView(
                                        mission: mission,
                                        character: character,
                                        hasActiveDungeonRun: hasActiveDungeonRun,
                                        onStart: { startMission(mission) }
                                    )
                                    .environmentObject(gameEngine)
                                    ) {
                                        MissionCardContent(
                                            mission: mission,
                                            character: character,
                                            isActive: gameEngine.activeMission?.missionID == mission.id
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(gameEngine.activeMission?.missionID == mission.id)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Dungeon active warning
                        if hasActiveDungeonRun {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("You cannot train while exploring a dungeon.")
                                    .font(.custom("Avenir-Medium", size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.orange.opacity(0.1))
                            )
                            .padding(.horizontal)
                        }
                        
                        // Training Tips
                        TrainingTipsCard()
                            .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Training")
            .navigationBarTitleDisplayMode(.large)
            .fullScreenCover(isPresented: $showCompletionResult) {
                if let result = lastMissionResult {
                    MissionCompletionView(result: result)
                }
            }
            .sensoryFeedback(.success, trigger: missionStartTrigger)
            .sensoryFeedback(.success, trigger: claimTrigger)
            .onAppear {
                seedSampleMissionsIfNeeded()
            }
        }
    }
    
    private func startMission(_ mission: AFKMission) {
        guard let character = character else { return }
        
        if gameEngine.startMission(mission, character: character, hasActiveDungeonRun: hasActiveDungeonRun) {
            missionStartTrigger += 1
            AudioManager.shared.play(.trainingStart)
            
            // Update daily quest progress
            gameEngine.updateDailyQuestProgressForMission(
                character: character,
                context: modelContext
            )
        }
    }
    
    private func claimMissionRewards(mission: AFKMission) {
        guard let character = character else { return }
        
        if let result = gameEngine.checkMissionCompletion(mission: mission, character: character) {
            lastMissionResult = result
            showCompletionResult = true
            claimTrigger += 1
            AudioManager.shared.play(.claimReward)
            
            // Award crafting materials (Herbs from missions) on success
            if result.success {
                gameEngine.awardMaterialsForMission(
                    missionRarity: mission.rarity,
                    character: character,
                    context: modelContext
                )
            }
        }
    }
    
    private func seedSampleMissionsIfNeeded() {
        guard missions.isEmpty else { return }
        
        for sample in SampleMissions.all {
            modelContext.insert(sample)
        }
    }
}

// MARK: - Active Mission Detail Card

struct ActiveMissionDetailCard: View {
    let activeMission: ActiveMission
    let mission: AFKMission
    let onClaim: () -> Void
    
    @State private var shimmerOffset: CGFloat = -1.0
    @State private var glowPulse: Bool = false
    @State private var particlePhase: Bool = false
    @State private var trainingBounce: Bool = false
    
    var body: some View {
        ZStack {
            // Floating sparkle particles (while training is in progress)
            if !activeMission.isComplete {
                ForEach(0..<6, id: \.self) { index in
                    Circle()
                        .fill(Color("AccentGold").opacity(0.5))
                        .frame(width: CGFloat.random(in: 3...6), height: CGFloat.random(in: 3...6))
                        .offset(
                            x: particleXOffset(index: index),
                            y: particlePhase ? particleYEnd(index: index) : particleYStart(index: index)
                        )
                        .opacity(particlePhase ? 0.0 : 0.7)
                }
            }
            
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: mission.missionType.icon)
                                .foregroundColor(Color("AccentGold"))
                                .symbolEffect(.pulse, options: .repeating)
                            Text("Active Training")
                                .font(.custom("Avenir-Heavy", size: 14))
                                .foregroundColor(Color("AccentGold"))
                        }
                        
                        Text(mission.name)
                            .font(.custom("Avenir-Heavy", size: 20))
                    }
                    
                    Spacer()
                    
                    if activeMission.isComplete {
                        // Completion badge
                        VStack(alignment: .trailing) {
                            Text("Complete!")
                                .font(.custom("Avenir-Heavy", size: 24))
                                .foregroundColor(Color("AccentGreen"))
                        }
                    } else {
                        // Animated training figure + timer
                        VStack(alignment: .trailing, spacing: 4) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 28))
                                .foregroundColor(Color("AccentGold"))
                                .scaleEffect(trainingBounce ? 1.1 : 0.95)
                                .offset(y: trainingBounce ? -2 : 2)
                            
                            Text(activeMission.timeRemainingFormatted)
                                .font(.system(size: 20, weight: .bold, design: .monospaced))
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                // Progress Bar with shimmer
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.secondary.opacity(0.2))
                        
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [Color("AccentGold"), Color("AccentOrange")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            // Shimmer overlay
                            if !activeMission.isComplete {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        LinearGradient(
                                            stops: [
                                                .init(color: .clear, location: shimmerOffset - 0.15),
                                                .init(color: .white.opacity(0.4), location: shimmerOffset),
                                                .init(color: .clear, location: shimmerOffset + 0.15)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                        }
                        .frame(width: geometry.size.width * activeMission.progress)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
                .frame(height: 10)
                
                // Claim Button (if complete)
                if activeMission.isComplete {
                    Button(action: {
                        AudioManager.shared.play(.claimReward)
                        onClaim()
                    }) {
                        HStack {
                            Image(systemName: "gift.fill")
                                .symbolEffect(.bounce, options: .repeating.speed(0.5))
                            Text("Claim Rewards")
                        }
                        .font(.custom("Avenir-Heavy", size: 16))
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
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(20)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("CardBackground"))
                .shadow(
                    color: activeMission.isComplete
                        ? Color("AccentGreen").opacity(0.3)
                        : Color("AccentGold").opacity(glowPulse ? 0.35 : 0.1),
                    radius: glowPulse ? 16 : 8,
                    x: 0, y: 4
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Animation Setup
    
    private func startAnimations() {
        guard !activeMission.isComplete else { return }
        
        // Shimmer sweep — repeats every 2s
        withAnimation(
            .linear(duration: 2.0)
            .repeatForever(autoreverses: false)
        ) {
            shimmerOffset = 1.15
        }
        
        // Breathing glow
        withAnimation(
            .easeInOut(duration: 1.8)
            .repeatForever(autoreverses: true)
        ) {
            glowPulse = true
        }
        
        // Particle float upward
        withAnimation(
            .easeOut(duration: 2.5)
            .repeatForever(autoreverses: false)
        ) {
            particlePhase = true
        }
        
        // Training figure bounce
        withAnimation(
            .easeInOut(duration: 0.6)
            .repeatForever(autoreverses: true)
        ) {
            trainingBounce = true
        }
    }
    
    // MARK: - Particle Helpers
    
    private func particleXOffset(index: Int) -> CGFloat {
        let positions: [CGFloat] = [-60, -20, 15, 50, -40, 30]
        return positions[index % positions.count]
    }
    
    private func particleYStart(index: Int) -> CGFloat {
        let starts: [CGFloat] = [20, 30, 15, 25, 35, 10]
        return starts[index % starts.count]
    }
    
    private func particleYEnd(index: Int) -> CGFloat {
        let ends: [CGFloat] = [-50, -70, -40, -60, -80, -45]
        return ends[index % ends.count]
    }
}

// MARK: - Mission Card Content (for NavigationLink)

struct MissionCardContent: View {
    let mission: AFKMission
    let character: PlayerCharacter?
    let isActive: Bool
    
    private var meetsRequirements: Bool {
        guard let character = character else { return false }
        return mission.meetsRequirements(character: character)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Mission Type Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(mission.rarity.color).opacity(0.2))
                    .frame(width: 56, height: 56)
                
                Image(systemName: mission.missionType.icon)
                    .font(.title2)
                    .foregroundColor(Color(mission.rarity.color))
            }
            
            // Mission Info
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(mission.rarity.rawValue)
                        .font(.custom("Avenir-Heavy", size: 10))
                        .foregroundColor(Color(mission.rarity.color))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color(mission.rarity.color).opacity(0.2))
                        )
                    
                    Text("Lv.\(mission.levelRequirement)+")
                        .font(.custom("Avenir-Medium", size: 10))
                        .foregroundColor(.secondary)
                }
                
                Text(mission.name)
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(meetsRequirements ? .primary : .secondary)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                        Text(mission.durationFormatted)
                    }
                    .font(.custom("Avenir-Medium", size: 12))
                    .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                        Text("+\(mission.expReward)")
                    }
                    .font(.custom("Avenir-Heavy", size: 12))
                    .foregroundColor(Color("AccentGold"))
                }
            }
            
            Spacer()
            
            // Status indicator
            if isActive {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(Color("AccentGreen"))
            } else if !meetsRequirements {
                Image(systemName: "lock.fill")
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .opacity(meetsRequirements || isActive ? 1.0 : 0.6)
    }
}

// MARK: - Training Detail View (Full Screen)

struct TrainingDetailView: View {
    let mission: AFKMission
    let character: PlayerCharacter?
    let hasActiveDungeonRun: Bool
    let onStart: () -> Void
    
    @EnvironmentObject var gameEngine: GameEngine
    @Environment(\.dismiss) private var dismiss
    
    private var meetsRequirements: Bool {
        guard let character = character else { return false }
        return mission.meetsRequirements(character: character)
    }
    
    private var canStart: Bool {
        meetsRequirements && gameEngine.activeMission == nil && !hasActiveDungeonRun
    }
    
    private var successRate: Double {
        guard let character = character else { return mission.baseSuccessRate }
        return mission.calculateSuccessRate(with: character.effectiveStats)
    }
    
    private var calculatedDropChance: Double {
        guard let character = character else { return mission.itemDropChance(luck: 5) }
        return mission.itemDropChance(luck: character.effectiveStats.luck)
    }
    
    /// Rarity range label for possible equipment drops
    private var dropRarityLabel: String {
        switch mission.rarity {
        case .common: return "Common"
        case .uncommon: return "Common – Uncommon"
        case .rare: return "Common – Rare"
        case .epic: return "Uncommon – Epic"
        case .legendary: return "Rare – Legendary"
        }
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
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Description
                    Text(mission.missionDescription)
                        .font(.custom("Avenir-Medium", size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Rewards Card
                    rewardsCard
                    
                    // Possible Loot Section
                    possibleLootCard
                    
                    // Requirements Card
                    requirementsCard
                    
                    // Spacer for bottom button
                    Spacer().frame(height: 80)
                }
                .padding(.vertical)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            startButton
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(mission.rarity.color).opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Image(systemName: mission.missionType.icon)
                    .font(.system(size: 50))
                    .foregroundColor(Color(mission.rarity.color))
            }
            
            Text(mission.name)
                .font(.custom("Avenir-Heavy", size: 28))
            
            HStack(spacing: 8) {
                Text(mission.rarity.rawValue)
                    .font(.custom("Avenir-Heavy", size: 12))
                    .foregroundColor(Color(mission.rarity.color))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(mission.rarity.color).opacity(0.2))
                    )
                
                Text(mission.missionType.rawValue)
                    .font(.custom("Avenir-Heavy", size: 12))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.secondary.opacity(0.15))
                    )
            }
        }
    }
    
    // MARK: - Rewards Card
    
    private var rewardsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rewards")
                .font(.custom("Avenir-Heavy", size: 18))
            
            // Duration
            TrainingStatRow(
                icon: "clock",
                iconColor: .secondary,
                label: "Duration",
                value: mission.durationFormatted
            )
            
            // EXP
            TrainingStatRow(
                icon: "sparkles",
                iconColor: Color("AccentGold"),
                label: "EXP Reward",
                value: "+\(mission.expReward)",
                valueColor: Color("AccentGold")
            )
            
            // Gold
            TrainingStatRow(
                icon: "dollarsign.circle.fill",
                iconColor: Color("AccentGold"),
                label: "Gold Reward",
                value: "+\(mission.goldReward)",
                valueColor: Color("AccentGold")
            )
            
            // Success Rate
            TrainingStatRow(
                icon: "percent",
                iconColor: successRate > 0.8 ? Color("AccentGreen") : (successRate > 0.5 ? Color("AccentGold") : .red),
                label: "Success Rate",
                value: "\(Int(successRate * 100))%",
                valueColor: successRate > 0.8 ? Color("AccentGreen") : (successRate > 0.5 ? Color("AccentGold") : .red)
            )
            
            Divider().opacity(0.3)
            
            // Stat Reward (NEW)
            let primaryStat = mission.missionType.primaryStat
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(primaryStat.color).opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: primaryStat.icon)
                        .font(.system(size: 16))
                        .foregroundColor(Color(primaryStat.color))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Trains: \(primaryStat.rawValue)")
                        .font(.custom("Avenir-Heavy", size: 14))
                        .foregroundColor(Color(primaryStat.color))
                    Text("\(Int(mission.statRewardChance * 100))% chance of +1 on success")
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("+1")
                    .font(.custom("Avenir-Heavy", size: 18))
                    .foregroundColor(Color(primaryStat.color))
            }
            
            // Item Drop Chance (NEW)
            if mission.canDropEquipment {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color("AccentPurple").opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: "gift.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color("AccentPurple"))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Equipment Drop")
                            .font(.custom("Avenir-Heavy", size: 14))
                            .foregroundColor(Color("AccentPurple"))
                        Text("10% base + 1% per Luck point")
                            .font(.custom("Avenir-Medium", size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(Int(calculatedDropChance * 100))%")
                        .font(.custom("Avenir-Heavy", size: 18))
                        .foregroundColor(Color("AccentPurple"))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
        .padding(.horizontal)
    }
    
    // MARK: - Possible Loot Card
    
    private var possibleLootCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Possible Loot")
                .font(.custom("Avenir-Heavy", size: 18))
            
            if mission.canDropEquipment {
                HStack(spacing: 16) {
                    // Slot icons (weapon, armor, accessory)
                    ForEach(["sword.2.crossed", "shield.lefthalf.filled", "sparkles"], id: \.self) { iconName in
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(mission.rarity.color).opacity(0.1))
                                .frame(width: 48, height: 48)
                            Image(systemName: iconName)
                                .font(.system(size: 20))
                                .foregroundColor(Color(mission.rarity.color))
                        }
                    }
                    
                    Spacer()
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "diamond.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color(mission.rarity.color))
                    Text("Rarity: \(dropRarityLabel)")
                        .font(.custom("Avenir-Medium", size: 13))
                        .foregroundColor(.secondary)
                }
                
                Text("Equipment is generated randomly based on training tier and your Luck stat.")
                    .font(.custom("Avenir-Medium", size: 12))
                    .foregroundColor(.secondary.opacity(0.7))
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No equipment drops from this training")
                        .font(.custom("Avenir-Medium", size: 14))
                        .foregroundColor(.secondary.opacity(0.5))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
        .padding(.horizontal)
    }
    
    // MARK: - Requirements Card
    
    private var requirementsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Requirements")
                .font(.custom("Avenir-Heavy", size: 18))
            
            // Level
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(Color("AccentGold"))
                    .frame(width: 24)
                Text("Level \(mission.levelRequirement)+")
                    .font(.custom("Avenir-Medium", size: 14))
                Spacer()
                Image(systemName: (character?.level ?? 0) >= mission.levelRequirement ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor((character?.level ?? 0) >= mission.levelRequirement ? Color("AccentGreen") : .red)
            }
            
            // Stat requirements
            if !mission.statRequirements.isEmpty {
                ForEach(mission.statRequirements, id: \.stat) { req in
                    HStack {
                        Image(systemName: req.stat.icon)
                            .foregroundColor(Color(req.stat.color))
                            .frame(width: 24)
                        Text("\(req.stat.rawValue) \(req.minimum)+")
                            .font(.custom("Avenir-Medium", size: 14))
                        Spacer()
                        
                        let currentValue = character?.effectiveStats.value(for: req.stat) ?? 0
                        Text("\(currentValue)")
                            .font(.custom("Avenir-Heavy", size: 14))
                            .foregroundColor(currentValue >= req.minimum ? Color("AccentGreen") : .red)
                        
                        Image(systemName: currentValue >= req.minimum ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(currentValue >= req.minimum ? Color("AccentGreen") : .red)
                    }
                }
            }
            
            if mission.statRequirements.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(Color("AccentGreen"))
                    Text("No stat requirements")
                        .font(.custom("Avenir-Medium", size: 14))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
        .padding(.horizontal)
    }
    
    // MARK: - Start Button
    
    private var startButton: some View {
        VStack(spacing: 0) {
            if hasActiveDungeonRun {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                    Text("Cannot train while in a dungeon")
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.orange)
                }
                .padding(.bottom, 8)
            } else if gameEngine.activeMission != nil {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                    Text("Another training is already in progress")
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.orange)
                }
                .padding(.bottom, 8)
            }
            
            Button(action: {
                onStart()
                dismiss()
            }) {
                HStack {
                    Image(systemName: canStart ? "play.fill" : "lock.fill")
                    Text(canStart ? "Start Training" : "Requirements Not Met")
                }
                .font(.custom("Avenir-Heavy", size: 18))
                .foregroundColor(canStart ? .black : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    canStart ?
                    LinearGradient(
                        colors: [Color("AccentGold"), Color("AccentOrange")],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) :
                    LinearGradient(
                        colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(!canStart)
        }
        .padding()
        .background(Color("BackgroundTop"))
    }
}

// MARK: - Training Stat Row

struct TrainingStatRow: View {
    let icon: String
    var iconColor: Color = .secondary
    let label: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)
            Text(label)
                .font(.custom("Avenir-Medium", size: 14))
            Spacer()
            Text(value)
                .font(.custom("Avenir-Heavy", size: 16))
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - Mission Completion View

struct MissionCompletionView: View {
    let result: MissionCompletionResult
    @Environment(\.dismiss) private var dismiss
    
    // Animation states
    @State private var showHeader = false
    @State private var showExpBar = false
    @State private var expBarProgress: Double
    @State private var displayLevel: Int
    @State private var showGoldRow = false
    @State private var displayedGold: Int = 0
    @State private var showStatGain = false
    @State private var showStatPoints = false
    @State private var showLevelUp = false
    @State private var showItemDrop = false
    @State private var showContinue = false
    @State private var showConfetti = false
    @State private var headerGlow = false
    
    private var didLevelUp: Bool { result.newLevel > result.previousLevel }
    
    init(result: MissionCompletionResult) {
        self.result = result
        _expBarProgress = State(initialValue: result.success ? result.expProgressBefore : 0)
        _displayLevel = State(initialValue: result.previousLevel)
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
            
            // Ambient particles
            if result.success {
                RewardFloatingParticlesView()
                    .ignoresSafeArea()
                    .opacity(0.4)
            }
            
            // Confetti
            if showConfetti {
                RewardConfettiOverlay()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            
            // Main content
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        Spacer().frame(height: 60)
                        
                        // Result Icon
                        resultIconView
                            .opacity(showHeader ? 1 : 0)
                            .scaleEffect(showHeader ? 1 : 0.3)
                        
                        // Title
                        titleView
                            .opacity(showHeader ? 1 : 0)
                            .offset(y: showHeader ? 0 : 20)
                        
                        if result.success {
                            // EXP Bar
                            expBarView
                                .opacity(showExpBar ? 1 : 0)
                                .offset(y: showExpBar ? 0 : 15)
                            
                            // Level Up Banner
                            if showLevelUp {
                                levelUpBannerView
                                    .transition(.asymmetric(
                                        insertion: .scale(scale: 0.5).combined(with: .opacity),
                                        removal: .opacity
                                    ))
                            }
                            
                            // Rewards Card
                            rewardsCardView
                            
                        } else {
                            failureView
                                .opacity(showHeader ? 1 : 0)
                        }
                        
                        Spacer().frame(height: 20)
                    }
                    .padding(.horizontal, 24)
                }
                
                // Continue Button - pinned at bottom
                if showContinue {
                    continueButtonView
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            startAnimationSequence()
        }
    }
    
    // MARK: - Result Icon
    
    private var resultIconView: some View {
        ZStack {
            // Glow ring
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            (result.success ? Color("AccentGold") : Color.red).opacity(headerGlow ? 0.4 : 0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: headerGlow)
            
            Image(systemName: result.success ? "trophy.fill" : "xmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(
                    result.success
                    ? LinearGradient(colors: [Color("AccentGold"), Color("AccentGold").opacity(0.7)], startPoint: .top, endPoint: .bottom)
                    : LinearGradient(colors: [.red, .red.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: (result.success ? Color("AccentGold") : .red).opacity(0.5), radius: 20)
        }
    }
    
    // MARK: - Title
    
    private var titleView: some View {
        VStack(spacing: 6) {
            Text(result.success ? "Training Complete!" : "Training Failed")
                .font(.custom("Avenir-Heavy", size: 28))
                .foregroundColor(.white)
            
            if result.success {
                Text("+\(result.expGained) EXP  •  +\(result.goldGained) Gold")
                    .font(.custom("Avenir-Medium", size: 14))
                    .foregroundColor(Color("AccentGold").opacity(0.8))
            }
        }
    }
    
    // MARK: - EXP Bar
    
    private var expBarView: some View {
        VStack(spacing: 8) {
            HStack {
                // Level badge
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color("AccentGold"))
                    Text("Lv. \(displayLevel)")
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text("EXP  \(Int(expBarProgress * 100))%")
                    .font(.custom("Avenir-Heavy", size: 14))
                    .foregroundColor(Color("AccentGold").opacity(0.9))
            }
            
            // Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                    
                    // Fill
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color("AccentGold"), Color("AccentGold").opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geo.size.width * expBarProgress))
                    
                    // Shimmer overlay on fill
                    if expBarProgress > 0.01 {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [.clear, .white.opacity(0.25), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, geo.size.width * expBarProgress))
                    }
                }
            }
            .frame(height: 16)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color("AccentGold").opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Level Up Banner
    
    private var levelUpBannerView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color("AccentGold"))
                
                Text("LEVEL UP!")
                    .font(.custom("Avenir-Heavy", size: 24))
                    .foregroundColor(Color("AccentGold"))
            }
            
            Text("Level \(result.previousLevel) → Level \(result.newLevel)")
                .font(.custom("Avenir-Heavy", size: 18))
                .foregroundColor(.white)
            
            if result.statPointsGained > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Color("AccentGreen"))
                    Text("\(result.statPointsGained) Stat Point\(result.statPointsGained > 1 ? "s" : "") Available")
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(Color("AccentGreen"))
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("AccentGold").opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color("AccentGold").opacity(0.4), lineWidth: 1.5)
                )
        )
    }
    
    // MARK: - Rewards Card
    
    private var rewardsCardView: some View {
        VStack(spacing: 16) {
            // Gold row
            if showGoldRow {
                rewardItemRow(
                    icon: "dollarsign.circle.fill",
                    iconColor: Color("AccentGold"),
                    label: "Gold Earned",
                    value: "+\(displayedGold)",
                    valueColor: Color("AccentGold")
                )
                .transition(.asymmetric(insertion: .push(from: .trailing).combined(with: .opacity), removal: .opacity))
            }
            
            // Stat gain row (from training)
            if showStatGain, let gained = result.statGained {
                rewardItemRow(
                    icon: gained.stat.icon,
                    iconColor: Color(gained.stat.color),
                    label: "\(gained.stat.rawValue) Gained",
                    value: "+\(gained.amount)",
                    valueColor: Color(gained.stat.color)
                )
                .transition(.asymmetric(insertion: .scale(scale: 0.5).combined(with: .opacity), removal: .opacity))
            }
            
            // Stat points row
            if showStatPoints && result.statPointsGained > 0 {
                rewardItemRow(
                    icon: "arrow.up.forward.circle.fill",
                    iconColor: Color("AccentGreen"),
                    label: "Stat Points",
                    value: "+\(result.statPointsGained)",
                    valueColor: Color("AccentGreen")
                )
                .transition(.asymmetric(insertion: .scale(scale: 0.5).combined(with: .opacity), removal: .opacity))
            }
            
            // Item drop row
            if showItemDrop, let itemName = result.itemDropped {
                rewardItemRow(
                    icon: "gift.fill",
                    iconColor: Color("AccentPurple"),
                    label: "Item Found!",
                    value: itemName,
                    valueColor: Color("AccentPurple")
                )
                .transition(.asymmetric(insertion: .scale(scale: 0.5).combined(with: .opacity), removal: .opacity))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }
    
    private func rewardItemRow(icon: String, iconColor: Color, label: String, value: String, valueColor: Color) -> some View {
        HStack {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(iconColor)
                }
                Text(label)
                    .font(.custom("Avenir-Medium", size: 16))
                    .foregroundColor(.white.opacity(0.8))
            }
            Spacer()
            Text(value)
                .font(.custom("Avenir-Heavy", size: 20))
                .foregroundColor(valueColor)
        }
    }
    
    // MARK: - Failure View
    
    private var failureView: some View {
        VStack(spacing: 12) {
            Text("Training was unsuccessful.")
                .font(.custom("Avenir-Medium", size: 16))
                .foregroundColor(.secondary)
            Text("Try again with higher stats!")
                .font(.custom("Avenir-Medium", size: 14))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
    }
    
    // MARK: - Continue Button
    
    private var continueButtonView: some View {
        Button(action: { dismiss() }) {
            HStack(spacing: 8) {
                Text("Continue")
                    .font(.custom("Avenir-Heavy", size: 18))
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [Color("AccentGold"), Color("AccentGold").opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color("AccentGold").opacity(0.3), radius: 10, y: 5)
        }
    }
    
    // MARK: - Animation Sequence
    
    private func startAnimationSequence() {
        var delay: Double = 0
        
        // Header + icon
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showHeader = true
            }
            headerGlow = true
            if result.success {
                AudioManager.shared.play(.trainingComplete)
            } else {
                AudioManager.shared.play(.error)
            }
        }
        delay += 0.5
        
        guard result.success else {
            // Show continue for failure
            DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showContinue = true
                }
            }
            return
        }
        
        // EXP bar appears
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showExpBar = true
            }
        }
        delay += 0.4
        
        // EXP bar animation
        if didLevelUp {
            // Fill bar to 100%
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 0.9)) {
                    expBarProgress = 1.0
                }
            }
            delay += 1.1
            
            // Level up celebration
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    displayLevel = result.newLevel
                    showLevelUp = true
                }
                showConfetti = true
                AudioManager.shared.play(.levelUp)
            }
            delay += 0.8
            
            // Reset bar and fill to new progress
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                expBarProgress = 0
                withAnimation(.easeInOut(duration: 0.7)) {
                    expBarProgress = result.expProgressAfter
                }
            }
            delay += 0.9
        } else {
            // Simple fill from before to after
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 1.0)) {
                    expBarProgress = result.expProgressAfter
                }
            }
            delay += 1.2
        }
        
        // Gold counter
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showGoldRow = true
            }
            animateGoldCounter()
            AudioManager.shared.play(.lootDrop)
        }
        delay += 0.5
        
        // Stat gain from training
        if result.statGained != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    showStatGain = true
                }
            }
            delay += 0.4
        }
        
        // Stat points
        if result.statPointsGained > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    showStatPoints = true
                }
            }
            delay += 0.4
        }
        
        // Item drop
        if result.itemDropped != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    showItemDrop = true
                }
                AudioManager.shared.play(.lootDrop)
            }
            delay += 0.5
        }
        
        // Continue button
        DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.3) {
            withAnimation(.easeOut(duration: 0.3)) {
                showContinue = true
            }
        }
    }
    
    // MARK: - Gold Counter Animation
    
    private func animateGoldCounter() {
        let target = result.goldGained
        guard target > 0 else {
            displayedGold = 0
            return
        }
        let steps = min(target, 30)
        let stepDuration = 0.6 / Double(steps)
        
        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * stepDuration) {
                displayedGold = Int(Double(target) * Double(i) / Double(steps))
            }
        }
    }
}

// MARK: - Confetti Overlay

private struct RewardConfettiData: Identifiable {
    let id: Int
    let color: Color
    let startX: CGFloat
    let endX: CGFloat
    let endY: CGFloat
    let rotation: Double
    let delay: Double
    let duration: Double
    let width: CGFloat
    let height: CGFloat
}

private struct RewardConfettiOverlay: View {
    @State private var pieces: [RewardConfettiData]
    
    init() {
        let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink, .mint]
        var p: [RewardConfettiData] = []
        for i in 0..<80 {
            p.append(RewardConfettiData(
                id: i,
                color: colors[i % colors.count],
                startX: CGFloat.random(in: -30...30),
                endX: CGFloat.random(in: -200...200),
                endY: CGFloat.random(in: 300...900),
                rotation: Double.random(in: -720...720),
                delay: Double(i) * 0.015,
                duration: Double.random(in: 2.5...4.0),
                width: CGFloat.random(in: 5...10),
                height: CGFloat.random(in: 8...18)
            ))
        }
        _pieces = State(initialValue: p)
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { piece in
                    RewardConfettiPieceView(piece: piece)
                        .position(x: geo.size.width / 2, y: 0)
                }
            }
        }
    }
}

private struct RewardConfettiPieceView: View {
    let piece: RewardConfettiData
    @State private var animate = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(piece.color)
            .frame(width: piece.width, height: piece.height)
            .offset(
                x: animate ? piece.endX : piece.startX,
                y: animate ? piece.endY : -50
            )
            .rotationEffect(.degrees(animate ? piece.rotation : 0))
            .opacity(animate ? 0 : 1)
            .onAppear {
                withAnimation(
                    .easeOut(duration: piece.duration)
                    .delay(piece.delay)
                ) {
                    animate = true
                }
            }
    }
}

// MARK: - Floating Particles

private struct RewardFloatingParticleData: Identifiable {
    let id: Int
    let xFraction: CGFloat  // 0.0–1.0 fraction of width
    let startYFraction: CGFloat
    let size: CGFloat
    let particleOpacity: Double
    let duration: Double
}

private struct RewardFloatingParticlesView: View {
    @State private var particles: [RewardFloatingParticleData]
    
    init() {
        var p: [RewardFloatingParticleData] = []
        for i in 0..<15 {
            p.append(RewardFloatingParticleData(
                id: i,
                xFraction: CGFloat.random(in: 0...1),
                startYFraction: CGFloat.random(in: 0.2...1.0),
                size: CGFloat.random(in: 2...6),
                particleOpacity: Double.random(in: 0.2...0.5),
                duration: Double.random(in: 3...6)
            ))
        }
        _particles = State(initialValue: p)
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    RewardFloatingParticleItemView(particle: particle, geoSize: geo.size)
                }
            }
        }
    }
}

private struct RewardFloatingParticleItemView: View {
    let particle: RewardFloatingParticleData
    let geoSize: CGSize
    @State private var animate = false
    
    var body: some View {
        Circle()
            .fill(Color("AccentGold"))
            .frame(width: particle.size, height: particle.size)
            .opacity(particle.particleOpacity)
            .position(
                x: geoSize.width * particle.xFraction,
                y: animate ? -20 : geoSize.height * particle.startYFraction
            )
            .onAppear {
                withAnimation(
                    .easeInOut(duration: particle.duration)
                    .repeatForever(autoreverses: false)
                ) {
                    animate = true
                }
            }
    }
}

// MARK: - Training Tips Card

struct TrainingTipsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(Color("AccentGold"))
                Text("Training Tips")
                    .font(.custom("Avenir-Heavy", size: 16))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                TipRow(text: "Higher stats increase your success rate")
                TipRow(text: "Longer training gives better rewards")
                TipRow(text: "Luck affects rare item drop chances")
                TipRow(text: "You can only run one training at a time")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground").opacity(0.5))
        )
    }
}

struct TipRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "circle.fill")
                .font(.system(size: 4))
                .foregroundColor(.secondary)
                .padding(.top, 6)
            Text(text)
                .font(.custom("Avenir-Medium", size: 13))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Sample Missions

struct SampleMissions {
    static var all: [AFKMission] {
        [
            AFKMission(
                name: "Forest Patrol",
                description: "Scout the nearby forest for any signs of trouble. A simple task for beginners.",
                missionType: .exploration,
                rarity: .common,
                durationSeconds: 3600, // 1 hour
                statRequirements: [],
                levelRequirement: 1,
                baseSuccessRate: 0.9,
                expReward: 50,
                goldReward: 25
            ),
            AFKMission(
                name: "Goblin Skirmish",
                description: "A small group of goblins has been spotted. Clear them out!",
                missionType: .combat,
                rarity: .common,
                durationSeconds: 7200, // 2 hours
                statRequirements: [StatRequirement(stat: .strength, minimum: 8)],
                levelRequirement: 3,
                baseSuccessRate: 0.8,
                expReward: 100,
                goldReward: 60
            ),
            AFKMission(
                name: "Ancient Library Research",
                description: "Study the ancient tomes in the library to uncover forgotten knowledge.",
                missionType: .research,
                rarity: .uncommon,
                durationSeconds: 14400, // 4 hours
                statRequirements: [StatRequirement(stat: .wisdom, minimum: 12)],
                levelRequirement: 5,
                baseSuccessRate: 0.75,
                expReward: 200,
                goldReward: 100,
                canDropEquipment: true
            ),
            AFKMission(
                name: "Merchant Negotiations",
                description: "Negotiate a trade deal with traveling merchants for the village.",
                missionType: .negotiation,
                rarity: .uncommon,
                durationSeconds: 10800, // 3 hours
                statRequirements: [StatRequirement(stat: .charisma, minimum: 10)],
                levelRequirement: 5,
                baseSuccessRate: 0.7,
                expReward: 150,
                goldReward: 150,
                canDropEquipment: true
            ),
            AFKMission(
                name: "Dragon's Lair Expedition",
                description: "Venture into the dragon's lair to recover ancient treasures. Extremely dangerous!",
                missionType: .exploration,
                rarity: .epic,
                durationSeconds: 28800, // 8 hours
                statRequirements: [
                    StatRequirement(stat: .strength, minimum: 20),
                    StatRequirement(stat: .dexterity, minimum: 18)
                ],
                levelRequirement: 15,
                baseSuccessRate: 0.5,
                expReward: 1000,
                goldReward: 500,
                canDropEquipment: true
            )
        ]
    }
}

#Preview {
    MissionsView()
        .environmentObject(GameEngine())
}

