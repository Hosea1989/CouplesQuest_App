import SwiftUI
import SwiftData

struct MissionsView: View {
    /// When true, the view is pushed inside an existing NavigationStack and should not create its own.
    var isEmbedded: Bool = false
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var gameEngine: GameEngine
    @Query private var characters: [PlayerCharacter]
    @Query private var missions: [AFKMission]
    @Query(sort: \DungeonRun.startedAt, order: .reverse) private var dungeonRuns: [DungeonRun]
    
    @State private var showCompletionResult = false
    @State private var lastMissionResult: MissionCompletionResult?
    @State private var missionStartTrigger = 0
    @State private var claimTrigger = 0
    @State private var selectedMission: AFKMission?
    @State private var showMissionDetail = false
    
    private var character: PlayerCharacter? {
        characters.first
    }
    
    /// Whether there is an active (in-progress) dungeon run
    private var hasActiveDungeonRun: Bool {
        dungeonRuns.contains { $0.status == .inProgress }
    }
    
    private var displayedMissions: [AFKMission] {
        var base: [AFKMission]
        if missions.isEmpty {
            base = SampleMissions.all
        } else {
            base = missions.filter { $0.isAvailable }
        }
        
        // Include rank-up training when eligible (level 20+, still a starter class)
        if let char = character,
           let charClass = char.characterClass,
           charClass.tier == .starter,
           char.level >= 20 {
            let rankUps: [AFKMission]
            if missions.isEmpty {
                rankUps = SampleMissions.allRankUpTraining
            } else {
                rankUps = base.filter { $0.isRankUpTraining }
            }
            // Add rank-up missions if not already in base
            let existingIDs = Set(base.map { $0.id })
            for ru in rankUps {
                if !existingIDs.contains(ru.id) {
                    base.append(ru)
                }
            }
        }
        
        // Filter to show only training for the player's class line (exclude old universal ones)
        let classLineRaw = character?.characterClass?.classLine.rawValue
        let filtered = base.filter { mission in
            guard let req = mission.classRequirement else {
                // Only allow rank-up missions with nil classRequirement through
                return mission.isRankUpTraining
            }
            return req == classLineRaw
        }
        
        // Sort: by level requirement, then by rarity (progression)
        return filtered.sorted { lhs, rhs in
            if lhs.levelRequirement != rhs.levelRequirement {
                return lhs.levelRequirement < rhs.levelRequirement
            }
            return lhs.rarity.sortOrder < rhs.rarity.sortOrder
        }
    }
    
    /// Training tier definition for section headers
    private struct TrainingTier: Identifiable {
        let id: String
        let title: String
        let subtitle: String
        let icon: String
        let missions: [AFKMission]
    }
    
    /// Group displayed missions into progression tiers for section headers
    private var groupedTraining: [TrainingTier] {
        let allMissions = displayedMissions
        var tiers: [TrainingTier] = []
        
        // Class Evolution (rank-up) at top when available
        let rankUps = allMissions.filter { $0.isRankUpTraining }
        if !rankUps.isEmpty {
            tiers.append(TrainingTier(
                id: "evolution",
                title: "Class Evolution",
                subtitle: "Lv. 20+ — Evolve into an advanced class",
                icon: "sparkles",
                missions: rankUps
            ))
        }
        
        let regular = allMissions.filter { !$0.isRankUpTraining }
        
        // Tier I: Novice (Lv 1-2)
        let novice = regular.filter { $0.levelRequirement <= 2 }
        if !novice.isEmpty {
            tiers.append(TrainingTier(
                id: "novice",
                title: "Tier I — Novice",
                subtitle: "Lv. 1+ — Foundational exercises",
                icon: "figure.walk",
                missions: novice
            ))
        }
        
        // Tier II: Apprentice (Lv 3-7)
        let apprentice = regular.filter { $0.levelRequirement >= 3 && $0.levelRequirement <= 7 }
        if !apprentice.isEmpty {
            tiers.append(TrainingTier(
                id: "apprentice",
                title: "Tier II — Apprentice",
                subtitle: "Lv. 3+ — Focused skill building",
                icon: "figure.run",
                missions: apprentice
            ))
        }
        
        // Tier III: Journeyman (Lv 8-14)
        let journeyman = regular.filter { $0.levelRequirement >= 8 && $0.levelRequirement <= 14 }
        if !journeyman.isEmpty {
            tiers.append(TrainingTier(
                id: "journeyman",
                title: "Tier III — Journeyman",
                subtitle: "Lv. 8+ — Intermediate challenges",
                icon: "figure.martial.arts",
                missions: journeyman
            ))
        }
        
        // Tier IV: Expert (Lv 15-24)
        let expert = regular.filter { $0.levelRequirement >= 15 && $0.levelRequirement <= 24 }
        if !expert.isEmpty {
            tiers.append(TrainingTier(
                id: "expert",
                title: "Tier IV — Expert",
                subtitle: "Lv. 15+ — Advanced endurance training",
                icon: "flame.fill",
                missions: expert
            ))
        }
        
        // Tier V: Master (Lv 25+)
        let master = regular.filter { $0.levelRequirement >= 25 }
        if !master.isEmpty {
            tiers.append(TrainingTier(
                id: "master",
                title: "Tier V — Master",
                subtitle: "Lv. 25+ — Elite training for legends",
                icon: "crown.fill",
                missions: master
            ))
        }
        
        return tiers
    }
    
    var body: some View {
        if isEmbedded {
            missionsContent
        } else {
            NavigationStack {
                missionsContent
            }
        }
    }
    
    @ViewBuilder
    private var missionsContent: some View {
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
                        
                        // Available Training Sessions — grouped by tier
                        ForEach(groupedTraining) { tier in
                            VStack(alignment: .leading, spacing: 12) {
                                // Tier Section Header
                                HStack(spacing: 8) {
                                    Image(systemName: tier.icon)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(
                                            tier.id == "evolution" ? Color("AccentPurple") :
                                            tier.id == "master" ? Color("RarityRare") :
                                            Color("AccentGold")
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(tier.title)
                                            .font(.custom("Avenir-Heavy", size: 18))
                                            .foregroundColor(
                                                tier.id == "evolution" ? Color("AccentPurple") : .primary
                                            )
                                        
                                        Text(tier.subtitle)
                                            .font(.custom("Avenir-Medium", size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal)
                                
                                // Missions in this tier
                                VStack(spacing: 10) {
                                    ForEach(tier.missions, id: \.id) { mission in
                                        Button {
                                            selectedMission = mission
                                            showMissionDetail = true
                                        } label: {
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
            .fullScreenCover(isPresented: $showMissionDetail) {
                if let mission = selectedMission, let character = character {
                    NavigationStack {
                        TrainingDetailView(
                            mission: mission,
                            character: character,
                            hasActiveDungeonRun: hasActiveDungeonRun,
                            onStart: { startMission(mission) }
                        )
                        .environmentObject(gameEngine)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button {
                                    showMissionDetail = false
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                        .font(.title2)
                                }
                            }
                        }
                    }
                }
            }
            .sensoryFeedback(.success, trigger: missionStartTrigger)
            .sensoryFeedback(.success, trigger: claimTrigger)
            .onAppear {
                seedSampleMissionsIfNeeded()
            }
    }
    
    private func startMission(_ mission: AFKMission) {
        guard let character = character else { return }
        
        if gameEngine.startMission(mission, character: character, hasActiveDungeonRun: hasActiveDungeonRun) {
            character.completeBreadcrumb("sendMission")
            missionStartTrigger += 1
            ToastManager.shared.showInfo("Mission Started!", subtitle: mission.name, icon: "figure.walk")
            AudioManager.shared.play(.trainingStart)
            
            // Schedule a push notification for when the mission completes
            let completionDate = Date().addingTimeInterval(TimeInterval(mission.durationSeconds))
            PushNotificationService.shared.scheduleTrainingComplete(
                missionName: mission.name,
                completionDate: completionDate
            )
            
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
            
            if result.success {
                var subtitle = "+\(result.expGained) EXP, +\(result.goldGained) Gold"
                if result.researchTokensDropped > 0 {
                    subtitle += ", +\(result.researchTokensDropped) Research Token\(result.researchTokensDropped > 1 ? "s" : "")"
                }
                let title: String
                if let newClass = result.rankedUpToClass {
                    title = "Ranked Up to \(newClass.rawValue)!"
                } else {
                    title = "Training Complete!"
                }
                ToastManager.shared.showSuccess(
                    title,
                    subtitle: subtitle
                )
                // Award crafting materials (Herbs from missions) on success
                gameEngine.awardMaterialsForMission(
                    missionRarity: mission.rarity,
                    character: character,
                    context: modelContext
                )
                // Award Research Tokens (mission-exclusive drop)
                if result.researchTokensDropped > 0 {
                    gameEngine.awardResearchTokens(
                        amount: result.researchTokensDropped,
                        character: character,
                        context: modelContext
                    )
                }
                // Post to party feed
                let bonds = (try? modelContext.fetch(FetchDescriptor<Bond>())) ?? []
                if let partyID = bonds.first?.supabasePartyID,
                   let actorID = SupabaseService.shared.currentUserID {
                    let missionName = mission.name
                    let expVal = result.expGained
                    Task {
                        try? await SupabaseService.shared.postPartyFeedEvent(
                            partyID: partyID,
                            actorID: actorID,
                            eventType: "task_completed",
                            message: "\(character.name) completed mission '\(missionName)' (+\(expVal) EXP)",
                            metadata: ["mission_name": missionName, "exp": "\(expVal)"]
                        )
                    }
                }
            } else {
                ToastManager.shared.showError(
                    "Mission Failed",
                    subtitle: "Consolation: +\(result.expGained) EXP"
                )
            }
        }
    }
    
    /// Old training names that signal a re-seed is needed (replaced in v2 naming pass)
    private static let legacyTrainingNames: Set<String> = [
        "Strength Training", "Sparring Practice", "Shield Wall Drills",
        "Endurance March", "Battle Conditioning",
        "Study Magic", "Arcane Research", "Enchantment Practice",
        "Elemental Attunement", "Deep Meditation",
        "Target Practice", "Agility Drills", "Stealth Training",
        "Precision Focus"
    ]
    
    private func seedSampleMissionsIfNeeded() {
        // Check if missions need refresh:
        // - empty
        // - missing class-specific training
        // - still has old universal (non-class) trainings that should be removed
        // - still uses legacy generic names (v1 naming)
        let hasClassTraining = missions.contains { $0.classRequirement != nil }
        let hasRankUpTraining = missions.contains { $0.isRankUpTraining }
        let hasOldUniversal = missions.contains { $0.classRequirement == nil && !$0.isRankUpTraining }
        let hasLegacyNames = missions.contains { Self.legacyTrainingNames.contains($0.name) }
        
        let needsRefresh = missions.isEmpty
            || (!hasClassTraining && !hasRankUpTraining)
            || hasOldUniversal
            || hasLegacyNames
        
        guard needsRefresh else { return }
        
        // Clear old missions before re-seeding, but preserve any currently active mission
        let activeMissionID = gameEngine.activeMission?.missionID
        for mission in missions where mission.id != activeMissionID {
            modelContext.delete(mission)
        }
        
        // Prefer server-driven mission definitions from ContentManager
        let cm = ContentManager.shared
        if cm.isLoaded && !cm.missions.isEmpty {
            for cm_mission in cm.missions.filter({ $0.active }) {
                if let mission = buildMission(from: cm_mission) {
                    modelContext.insert(mission)
                }
            }
        } else {
            for sample in SampleMissions.all {
                modelContext.insert(sample)
            }
            // Also seed rank-up training courses
            for rankUp in SampleMissions.allRankUpTraining {
                modelContext.insert(rankUp)
            }
        }
    }
    
    /// Convert a ContentMission (server-driven) to a SwiftData AFKMission
    private func buildMission(from cm: ContentMission) -> AFKMission? {
        let missionType = MissionType(rawValue: cm.missionType.capitalized) ?? .exploration
        let rarity = MissionRarity(rawValue: cm.rarity.capitalized) ?? .common
        let statReqs = cm.statRequirements.compactMap { req -> StatRequirement? in
            guard let stat = StatType(rawValue: req.stat.capitalized) else { return nil }
            return StatRequirement(stat: stat, minimum: req.value)
        }
        
        return AFKMission(
            name: cm.name,
            description: cm.description,
            missionType: missionType,
            rarity: rarity,
            durationSeconds: cm.durationSeconds,
            statRequirements: statReqs,
            levelRequirement: cm.levelRequirement,
            baseSuccessRate: cm.baseSuccessRate,
            expReward: cm.expReward,
            goldReward: cm.goldReward,
            canDropEquipment: cm.canDropEquipment,
            classRequirement: cm.classRequirement,
            trainingStat: cm.trainingStat,
            isRankUpTraining: cm.isRankUpTraining ?? false,
            rankUpTargetClass: cm.rankUpTargetClass
        )
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
                    Image(mission.missionType.thumbnailImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color("AccentGold").opacity(0.4), lineWidth: 1)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
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
            // Mission Thumbnail
            Image(mission.missionType.thumbnailImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(mission.rarity.color).opacity(0.4), lineWidth: 1.5)
                )
            
            // Mission Info
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    if mission.isRankUpTraining {
                        Text("RANK UP")
                            .font(.custom("Avenir-Heavy", size: 10))
                            .foregroundColor(Color("AccentPurple"))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color("AccentPurple").opacity(0.2))
                            )
                    }
                    
                    Text(mission.rarity.rawValue)
                        .font(.custom("Avenir-Heavy", size: 10))
                        .foregroundColor(Color(mission.rarity.color))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color(mission.rarity.color).opacity(0.2))
                        )
                        .rarityShimmer(mission.rarity)
                    
                    Text("Lv.\(mission.levelRequirement)+")
                        .font(.custom("Avenir-Medium", size: 10))
                        .foregroundColor(.secondary)
                }
                
                Text(mission.name)
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(meetsRequirements ? (mission.isRankUpTraining ? Color("AccentPurple") : .primary) : .secondary)
                
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
        .overlay(
            mission.isRankUpTraining
            ? RoundedRectangle(cornerRadius: 16)
                .stroke(Color("AccentPurple").opacity(0.4), lineWidth: 1.5)
            : nil
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
    
    private var meetsHP: Bool {
        (character?.currentHP ?? 0) >= mission.hpCost
    }
    
    private var canStart: Bool {
        meetsRequirements && meetsHP && gameEngine.activeMission == nil && !hasActiveDungeonRun
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
            Image(mission.missionType.thumbnailImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color(mission.rarity.color).opacity(0.5), lineWidth: 2)
                )
                .shadow(color: Color(mission.rarity.color).opacity(0.3), radius: 8, x: 0, y: 4)
            
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
                    .rarityShimmer(mission.rarity)
                
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
            
            // HP Cost
            TrainingStatRow(
                icon: "heart.fill",
                iconColor: meetsHP ? Color("AccentGreen") : .red,
                label: "HP Cost",
                value: "-\(mission.hpCost)",
                valueColor: meetsHP ? Color("AccentGreen") : .red
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
            
            // Stat Reward — prefer explicit trainingStat, fall back to missionType primaryStat
            let primaryStat = mission.trainingStatType ?? mission.missionType.primaryStat
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
            // HP status + Use Potion
            if let character = character {
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(meetsHP ? Color("AccentGreen") : .red)
                        Text("\(character.currentHP) / \(character.maxHP) HP")
                            .font(.custom("Avenir-Heavy", size: 14))
                            .foregroundColor(meetsHP ? .primary : .red)
                    }
                    
                    Spacer()
                    
                    UseHPPotionButton(character: character)
                        .environmentObject(gameEngine)
                }
                .padding(.bottom, 8)
            }
            
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
            } else if !meetsHP && meetsRequirements {
                HStack(spacing: 6) {
                    Image(systemName: "heart.slash.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                    Text("Not enough HP (\(mission.hpCost) needed)")
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.red)
                }
                .padding(.bottom, 8)
            }
            
            Button(action: {
                onStart()
                dismiss()
            }) {
                HStack {
                    Image(systemName: canStart ? "play.fill" : "lock.fill")
                    Text(canStart ? "Start Training" :
                            (!meetsRequirements ? "Requirements Not Met" :
                                (!meetsHP ? "Not Enough HP" : "Cannot Start")))
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
    @State private var showCharacterStats = false
    @State private var missionAnimatedStatIndices: Set<Int> = []
    
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
                            
                            // Rank-Up Banner
                            if let newClass = result.rankedUpToClass {
                                rankUpBannerView(newClass: newClass)
                                    .transition(.asymmetric(
                                        insertion: .scale(scale: 0.5).combined(with: .opacity),
                                        removal: .opacity
                                    ))
                            }
                            
                            // Rewards Card
                            rewardsCardView
                            
                            // Character Stats Card
                            if showCharacterStats && !result.currentStats.isEmpty {
                                missionStatsCardView
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .bottom).combined(with: .opacity),
                                        removal: .opacity
                                    ))
                            }
                            
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
            if result.rankedUpToClass != nil && result.success {
                Text("Rank-Up Complete!")
                    .font(.custom("Avenir-Heavy", size: 28))
                    .foregroundColor(.white)
            } else {
                Text(result.success ? "Training Complete!" : "Training Failed")
                    .font(.custom("Avenir-Heavy", size: 28))
                    .foregroundColor(.white)
            }
            
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
    
    // MARK: - Rank-Up Banner
    
    private func rankUpBannerView(newClass: CharacterClass) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 24))
                    .foregroundColor(Color("AccentPurple"))
                
                Text("CLASS RANK UP!")
                    .font(.custom("Avenir-Heavy", size: 24))
                    .foregroundColor(Color("AccentPurple"))
            }
            
            HStack(spacing: 8) {
                Image(systemName: newClass.icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color("AccentGold"))
                Text("You are now a \(newClass.rawValue)!")
                    .font(.custom("Avenir-Heavy", size: 18))
                    .foregroundColor(.white)
            }
            
            Text(newClass.description)
                .font(.custom("Avenir-Medium", size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("AccentPurple").opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color("AccentPurple").opacity(0.4), lineWidth: 1.5)
                )
        )
    }
    
    // MARK: - Rewards Card
    
    private var rewardsCardView: some View {
        VStack(spacing: 16) {
            // Gold row — shows total and earned
            if showGoldRow {
                HStack {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color("AccentGold").opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color("AccentGold"))
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text("GOLD")
                                .font(.custom("Avenir-Heavy", size: 10))
                                .foregroundColor(.secondary)
                                .tracking(1)
                            Text("\(result.goldBefore + displayedGold)")
                                .font(.custom("Avenir-Heavy", size: 18))
                                .foregroundColor(.white)
                                .contentTransition(.numericText())
                        }
                    }
                    Spacer()
                    Text("+\(displayedGold)")
                        .font(.custom("Avenir-Heavy", size: 20))
                        .foregroundColor(Color("AccentGold"))
                        .contentTransition(.numericText())
                }
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
            
            // Research Token drop row
            if result.researchTokensDropped > 0 {
                rewardItemRow(
                    icon: "book.closed.fill",
                    iconColor: Color("AccentPurple"),
                    label: "Research Token\(result.researchTokensDropped > 1 ? "s" : "")",
                    value: "+\(result.researchTokensDropped)",
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
    
    // MARK: - Character Stats Card (Mission)
    
    private var missionStatsCardView: some View {
        VStack(spacing: 14) {
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(Color("AccentGold"))
                Text("CHARACTER STATS")
                    .font(.custom("Avenir-Heavy", size: 11))
                    .foregroundColor(.secondary)
                    .tracking(1.5)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 10) {
                ForEach(Array(StatType.allCases.enumerated()), id: \.element) { index, statType in
                    let statValue = result.currentStats[statType] ?? 0
                    let gained: Int = {
                        if let sg = result.statGained, sg.stat == statType { return sg.amount }
                        return 0
                    }()
                    let isAnimated = missionAnimatedStatIndices.contains(index)
                    
                    HStack(spacing: 8) {
                        Image(systemName: statType.icon)
                            .font(.system(size: 13))
                            .foregroundColor(Color(statType.color))
                            .frame(width: 18)
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(statType.shortName)
                                .font(.custom("Avenir-Heavy", size: 10))
                                .foregroundColor(.secondary)
                                .tracking(0.8)
                            
                            HStack(spacing: 4) {
                                Text("\(statValue)")
                                    .font(.custom("Avenir-Heavy", size: 16))
                                    .foregroundColor(.white)
                                
                                if gained > 0 {
                                    Text("+\(gained)")
                                        .font(.custom("Avenir-Heavy", size: 13))
                                        .foregroundColor(Color(statType.color))
                                        .scaleEffect(isAnimated ? 1.0 : 0.3)
                                        .opacity(isAnimated ? 1 : 0)
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(gained > 0 && isAnimated
                                  ? Color(statType.color).opacity(0.1)
                                  : Color.white.opacity(0.03))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(gained > 0 && isAnimated
                                    ? Color(statType.color).opacity(0.3)
                                    : Color.clear, lineWidth: 1)
                    )
                    .opacity(isAnimated ? 1 : 0.3)
                    .scaleEffect(isAnimated ? 1 : 0.95)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
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
        
        // Character stats card
        if !result.currentStats.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showCharacterStats = true
                }
                // Stagger stat animations
                for index in StatType.allCases.indices {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.08) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            _ = missionAnimatedStatIndices.insert(index)
                        }
                    }
                }
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

struct RewardFloatingParticleData: Identifiable {
    let id: Int
    let xFraction: CGFloat  // 0.0–1.0 fraction of width
    let startYFraction: CGFloat
    let size: CGFloat
    let particleOpacity: Double
    let duration: Double
}

struct RewardFloatingParticlesView: View {
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

struct RewardFloatingParticleItemView: View {
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
        warriorTraining + mageTraining + archerTraining
    }
    
    /// Filter training for a specific class line
    static func forClassLine(_ classLine: String) -> [AFKMission] {
        switch classLine {
        case "warrior": return warriorTraining
        case "mage": return mageTraining
        case "archer": return archerTraining
        default: return []
        }
    }
    
    // MARK: - Warrior Line (Warrior / Berserker / Paladin)
    
    static var warriorTraining: [AFKMission] {
        [
            AFKMission(
                name: "Iron Foundations",
                description: "Begin your warrior's path by lifting heavy stones and swinging weighted weapons to build raw power.",
                missionType: .combat,
                rarity: .common,
                durationSeconds: 1800, // 30 min
                levelRequirement: 1,
                baseSuccessRate: 0.95,
                expReward: 20,
                goldReward: 5,
                classRequirement: "warrior",
                trainingStat: "Strength"
            ),
            AFKMission(
                name: "Sparring Gauntlet",
                description: "Test your combat reflexes against the training arena's toughest dummies and sparring partners.",
                missionType: .combat,
                rarity: .common,
                durationSeconds: 3600, // 1 hour
                statRequirements: [StatRequirement(stat: .strength, minimum: 6)],
                levelRequirement: 3,
                baseSuccessRate: 0.90,
                expReward: 40,
                goldReward: 10,
                classRequirement: "warrior",
                trainingStat: "Strength"
            ),
            AFKMission(
                name: "Bulwark Trials",
                description: "Endure relentless shield impacts to forge an unbreakable defense. Only the steadfast prevail.",
                missionType: .combat,
                rarity: .uncommon,
                durationSeconds: 7200, // 2 hours
                statRequirements: [StatRequirement(stat: .defense, minimum: 8)],
                levelRequirement: 8,
                baseSuccessRate: 0.85,
                expReward: 80,
                goldReward: 20,
                classRequirement: "warrior",
                trainingStat: "Defense"
            ),
            AFKMission(
                name: "Ironclad March",
                description: "A grueling long-distance march in full armor across hostile terrain. Only the strongest endure.",
                missionType: .combat,
                rarity: .uncommon,
                durationSeconds: 14400, // 4 hours
                statRequirements: [StatRequirement(stat: .strength, minimum: 12)],
                levelRequirement: 15,
                baseSuccessRate: 0.80,
                expReward: 150,
                goldReward: 40,
                classRequirement: "warrior",
                trainingStat: "Strength"
            ),
            AFKMission(
                name: "Crucible of War",
                description: "An extreme combat regimen that separates warriors from legends. Push your body to its absolute limit.",
                missionType: .combat,
                rarity: .rare,
                durationSeconds: 28800, // 8 hours
                statRequirements: [
                    StatRequirement(stat: .strength, minimum: 18),
                    StatRequirement(stat: .defense, minimum: 14)
                ],
                levelRequirement: 25,
                baseSuccessRate: 0.70,
                expReward: 300,
                goldReward: 80,
                classRequirement: "warrior",
                trainingStat: "Strength"
            )
        ]
    }
    
    // MARK: - Mage Line (Mage / Sorcerer / Enchanter)
    
    static var mageTraining: [AFKMission] {
        [
            AFKMission(
                name: "Cantrip Studies",
                description: "Learn the fundamental incantations every mage must master before wielding true power.",
                missionType: .research,
                rarity: .common,
                durationSeconds: 1800, // 30 min
                levelRequirement: 1,
                baseSuccessRate: 0.95,
                expReward: 20,
                goldReward: 5,
                classRequirement: "mage",
                trainingStat: "Wisdom"
            ),
            AFKMission(
                name: "Rune Scribing",
                description: "Study ancient scrolls and practice drawing runes of power to deepen your arcane knowledge.",
                missionType: .research,
                rarity: .common,
                durationSeconds: 3600, // 1 hour
                statRequirements: [StatRequirement(stat: .wisdom, minimum: 6)],
                levelRequirement: 3,
                baseSuccessRate: 0.90,
                expReward: 40,
                goldReward: 10,
                classRequirement: "mage",
                trainingStat: "Wisdom"
            ),
            AFKMission(
                name: "Enchantment Weaving",
                description: "Practice weaving enchantments into objects, strengthening your force of will and personality.",
                missionType: .research,
                rarity: .uncommon,
                durationSeconds: 7200, // 2 hours
                statRequirements: [StatRequirement(stat: .charisma, minimum: 8)],
                levelRequirement: 8,
                baseSuccessRate: 0.85,
                expReward: 80,
                goldReward: 20,
                classRequirement: "mage",
                trainingStat: "Charisma"
            ),
            AFKMission(
                name: "Elemental Communion",
                description: "Meditate on the primal forces of nature to attune your mind to deeper, more volatile magic.",
                missionType: .research,
                rarity: .uncommon,
                durationSeconds: 14400, // 4 hours
                statRequirements: [StatRequirement(stat: .wisdom, minimum: 12)],
                levelRequirement: 15,
                baseSuccessRate: 0.80,
                expReward: 150,
                goldReward: 40,
                classRequirement: "mage",
                trainingStat: "Wisdom"
            ),
            AFKMission(
                name: "Astral Sanctum",
                description: "Enter a trance at the boundary of realms, pushing your intellect beyond mortal limits.",
                missionType: .research,
                rarity: .rare,
                durationSeconds: 28800, // 8 hours
                statRequirements: [
                    StatRequirement(stat: .wisdom, minimum: 18),
                    StatRequirement(stat: .charisma, minimum: 14)
                ],
                levelRequirement: 25,
                baseSuccessRate: 0.70,
                expReward: 300,
                goldReward: 80,
                classRequirement: "mage",
                trainingStat: "Wisdom"
            )
        ]
    }
    
    // MARK: - Archer Line (Archer / Ranger / Trickster)
    
    static var archerTraining: [AFKMission] {
        [
            AFKMission(
                name: "Steady Aim",
                description: "Fire arrows at targets from increasing distances to sharpen your aim and focus.",
                missionType: .stealth,
                rarity: .common,
                durationSeconds: 1800, // 30 min
                levelRequirement: 1,
                baseSuccessRate: 0.95,
                expReward: 20,
                goldReward: 5,
                classRequirement: "archer",
                trainingStat: "Dexterity"
            ),
            AFKMission(
                name: "Windrunner Drills",
                description: "Sprint, dodge, and roll through an obstacle course designed to push your reflexes to the limit.",
                missionType: .stealth,
                rarity: .common,
                durationSeconds: 3600, // 1 hour
                statRequirements: [StatRequirement(stat: .dexterity, minimum: 6)],
                levelRequirement: 3,
                baseSuccessRate: 0.90,
                expReward: 40,
                goldReward: 10,
                classRequirement: "archer",
                trainingStat: "Dexterity"
            ),
            AFKMission(
                name: "Shadowstep Training",
                description: "Move unseen through dense terrain, sharpening both agility and battlefield awareness.",
                missionType: .stealth,
                rarity: .uncommon,
                durationSeconds: 7200, // 2 hours
                statRequirements: [StatRequirement(stat: .dexterity, minimum: 8)],
                levelRequirement: 8,
                baseSuccessRate: 0.85,
                expReward: 80,
                goldReward: 20,
                classRequirement: "archer",
                trainingStat: "Dexterity"
            ),
            AFKMission(
                name: "Hawk's Eye Trial",
                description: "An exhaustive regimen of trick shots and reaction drills. Only the elite marksmen survive.",
                missionType: .stealth,
                rarity: .rare,
                durationSeconds: 28800, // 8 hours
                statRequirements: [
                    StatRequirement(stat: .dexterity, minimum: 18),
                    StatRequirement(stat: .luck, minimum: 14)
                ],
                levelRequirement: 25,
                baseSuccessRate: 0.70,
                expReward: 300,
                goldReward: 80,
                classRequirement: "archer",
                trainingStat: "Dexterity"
            )
        ]
    }
    
    // MARK: - Rank-Up Training Courses (Class Evolution Trials)
    
    static var allRankUpTraining: [AFKMission] {
        warriorRankUp + mageRankUp + archerRankUp
    }
    
    static var warriorRankUp: [AFKMission] {
        [
            AFKMission(
                name: "Trial of Fury",
                description: "Channel your rage through a brutal gauntlet of combat. Only those with overwhelming strength and speed may walk the path of the Berserker.",
                missionType: .combat,
                rarity: .epic,
                durationSeconds: 14400, // 4 hours
                statRequirements: [
                    StatRequirement(stat: .strength, minimum: 15),
                    StatRequirement(stat: .dexterity, minimum: 12)
                ],
                levelRequirement: 20,
                baseSuccessRate: 0.65,
                expReward: 500,
                goldReward: 100,
                classRequirement: "warrior",
                trainingStat: "Strength",
                isRankUpTraining: true,
                rankUpTargetClass: "Berserker"
            ),
            AFKMission(
                name: "Trial of the Shield",
                description: "Endure an endless onslaught without breaking. Only those with iron defense and raw power earn the title of Paladin.",
                missionType: .combat,
                rarity: .epic,
                durationSeconds: 14400, // 4 hours
                statRequirements: [
                    StatRequirement(stat: .defense, minimum: 15),
                    StatRequirement(stat: .strength, minimum: 12)
                ],
                levelRequirement: 20,
                baseSuccessRate: 0.65,
                expReward: 500,
                goldReward: 100,
                classRequirement: "warrior",
                trainingStat: "Defense",
                isRankUpTraining: true,
                rankUpTargetClass: "Paladin"
            )
        ]
    }
    
    static var mageRankUp: [AFKMission] {
        [
            AFKMission(
                name: "Arcane Ascension Trial",
                description: "Unravel the deepest mysteries of arcane power. Only a mind of extraordinary wisdom and fortune's favor may ascend to Sorcerer.",
                missionType: .research,
                rarity: .epic,
                durationSeconds: 14400, // 4 hours
                statRequirements: [
                    StatRequirement(stat: .wisdom, minimum: 15),
                    StatRequirement(stat: .luck, minimum: 12)
                ],
                levelRequirement: 20,
                baseSuccessRate: 0.65,
                expReward: 500,
                goldReward: 100,
                classRequirement: "mage",
                trainingStat: "Wisdom",
                isRankUpTraining: true,
                rankUpTargetClass: "Sorcerer"
            ),
            AFKMission(
                name: "Enchanter's Exam",
                description: "Weave intricate enchantments under immense pressure. Only those with magnetic charisma and deep knowledge become Enchanters.",
                missionType: .research,
                rarity: .epic,
                durationSeconds: 14400, // 4 hours
                statRequirements: [
                    StatRequirement(stat: .charisma, minimum: 15),
                    StatRequirement(stat: .wisdom, minimum: 12)
                ],
                levelRequirement: 20,
                baseSuccessRate: 0.65,
                expReward: 500,
                goldReward: 100,
                classRequirement: "mage",
                trainingStat: "Charisma",
                isRankUpTraining: true,
                rankUpTargetClass: "Enchanter"
            )
        ]
    }
    
    static var archerRankUp: [AFKMission] {
        [
            AFKMission(
                name: "Ranger's Rite",
                description: "Survive alone in the deepest wilderness using only your reflexes and instinct. The ultimate test for a Ranger.",
                missionType: .stealth,
                rarity: .epic,
                durationSeconds: 14400, // 4 hours
                statRequirements: [
                    StatRequirement(stat: .dexterity, minimum: 15),
                    StatRequirement(stat: .luck, minimum: 12)
                ],
                levelRequirement: 20,
                baseSuccessRate: 0.65,
                expReward: 500,
                goldReward: 100,
                classRequirement: "archer",
                trainingStat: "Dexterity",
                isRankUpTraining: true,
                rankUpTargetClass: "Ranger"
            ),
            AFKMission(
                name: "Trickster's Trial",
                description: "Outsmart a gauntlet of traps and riddles. Only the luckiest and most nimble earn the title of Trickster.",
                missionType: .stealth,
                rarity: .epic,
                durationSeconds: 14400, // 4 hours
                statRequirements: [
                    StatRequirement(stat: .luck, minimum: 15),
                    StatRequirement(stat: .dexterity, minimum: 12)
                ],
                levelRequirement: 20,
                baseSuccessRate: 0.65,
                expReward: 500,
                goldReward: 100,
                classRequirement: "archer",
                trainingStat: "Luck",
                isRankUpTraining: true,
                rankUpTargetClass: "Trickster"
            )
        ]
    }
}

#Preview {
    MissionsView()
        .environmentObject(GameEngine())
}

