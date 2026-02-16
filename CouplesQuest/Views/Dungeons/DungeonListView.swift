import SwiftUI
import SwiftData

struct DungeonListView: View {
    /// When true, the view is pushed inside an existing NavigationStack and should not create its own.
    var isEmbedded: Bool = false
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var gameEngine: GameEngine
    @Query private var characters: [PlayerCharacter]
    @Query private var dungeons: [Dungeon]
    @Query(sort: \DungeonRun.startedAt, order: .reverse) private var dungeonRuns: [DungeonRun]
    
    @Query private var bonds: [Bond]
    
    @State private var selectedDungeon: Dungeon?
    @State private var showDungeonDetail = false
    @State private var showDungeonRun = false
    @State private var showLobby = false
    @State private var lobbyDungeon: Dungeon?
    @State private var activeDungeonRun: DungeonRun?
    @State private var activeDungeon: Dungeon?
    @State private var timerTick = 0
    
    // Timer that fires every second to refresh active run card
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var character: PlayerCharacter? {
        characters.first
    }
    
    /// Active dungeon run (in progress, not completed/failed/abandoned)
    private var activeRun: DungeonRun? {
        dungeonRuns.first(where: { $0.status == .inProgress })
    }
    
    /// Whether the player currently has an active dungeon run
    private var hasActiveRun: Bool {
        activeRun != nil
    }
    
    private var availableDungeons: [Dungeon] {
        let source = dungeons.isEmpty ? SampleDungeons.all : dungeons.filter { $0.isAvailable }
        return source.sorted { $0.levelRequirement < $1.levelRequirement }
    }
    
    var body: some View {
        if isEmbedded {
            dungeonListContent
        } else {
            NavigationStack {
                dungeonListContent
            }
        }
    }
    
    @ViewBuilder
    private var dungeonListContent: some View {
            ZStack {
                LinearGradient(
                    colors: [Color("BackgroundTop"), Color("BackgroundBottom")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Active Run Card
                        let _ = timerTick // force re-evaluation
                        if let run = activeRun,
                           let dungeon = dungeons.first(where: { $0.id == run.dungeonID }) {
                            ActiveDungeonRunCard(run: run, dungeon: dungeon) {
                                activeDungeon = dungeon
                                activeDungeonRun = run
                                showDungeonRun = true
                            }
                            .padding(.horizontal)
                        }
                        
                        // Dungeons by Difficulty
                        ForEach(DungeonDifficulty.allCases, id: \.self) { difficulty in
                            let filtered = availableDungeons.filter { $0.difficulty == difficulty }
                            if !filtered.isEmpty {
                                DungeonSection(
                                    difficulty: difficulty,
                                    dungeons: filtered,
                                    character: character,
                                    onSelect: { dungeon in
                                        selectedDungeon = dungeon
                                        showDungeonDetail = true
                                    }
                                )
                            }
                        }
                        
                        // Tips
                        DungeonTipsCard()
                            .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Dungeons")
            .navigationBarTitleDisplayMode(.large)
            .onReceive(timer) { _ in
                timerTick += 1
            }
            .fullScreenCover(isPresented: $showDungeonDetail) {
                if let dungeon = selectedDungeon {
                    NavigationStack {
                        DungeonDetailView(
                            dungeon: dungeon,
                            character: character,
                            hasActiveRun: hasActiveRun,
                            hasActiveTraining: gameEngine.isTrainingInProgress,
                            onStartSolo: { party in
                                startDungeon(dungeon, party: party, isCoop: false)
                            },
                            onStartCoop: { _ in
                                // Present lobby instead of immediately starting
                                showDungeonDetail = false
                                lobbyDungeon = dungeon
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    showLobby = true
                                }
                            }
                        )
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button {
                                    showDungeonDetail = false
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
            .fullScreenCover(isPresented: $showDungeonRun) {
                if let run = activeDungeonRun, let dungeon = activeDungeon {
                    DungeonRunView(
                        dungeon: dungeon,
                        run: run,
                        party: characters.filter { run.partyMemberIDs.contains($0.id) }
                    )
                }
            }
            .sheet(isPresented: $showLobby) {
                if let dungeon = lobbyDungeon, let character = character, let bond = bonds.first {
                    DungeonLobbyView(
                        dungeon: dungeon,
                        character: character,
                        bond: bond,
                        onStart: { party in
                            startDungeon(dungeon, party: party, isCoop: true)
                        }
                    )
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
                }
            }
            .onAppear {
                seedDungeonsIfNeeded()
                // Apply passive HP regen when entering dungeon screen
                character?.applyPassiveRegen()
            }
    }
    
    private func startDungeon(_ dungeon: Dungeon, party: [PlayerCharacter], isCoop: Bool) {
        // Deduct HP cost from lead character before entering
        if let lead = party.first {
            lead.takeDamage(dungeon.hpCost)
        }
        
        let run = DungeonRun(dungeon: dungeon, partyMembers: party, isCoop: isCoop)
        modelContext.insert(run)
        activeDungeon = dungeon
        activeDungeonRun = run
        showDungeonDetail = false
        AudioManager.shared.play(.dungeonStart)
        
        // Schedule a push notification for when the dungeon run timer completes
        let completionDate = Date().addingTimeInterval(TimeInterval(dungeon.durationSeconds))
        PushNotificationService.shared.scheduleDungeonComplete(
            dungeonName: dungeon.name,
            completionDate: completionDate
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showDungeonRun = true
        }
    }
    
    private func seedDungeonsIfNeeded() {
        guard dungeons.isEmpty else { return }
        
        // Prefer server-driven dungeon definitions from ContentManager
        let cm = ContentManager.shared
        if cm.isLoaded && !cm.dungeons.isEmpty {
            for cd in cm.activeDungeons() {
                if let dungeon = buildDungeon(from: cd) {
                    modelContext.insert(dungeon)
                }
            }
        } else {
            // Fallback to hardcoded sample dungeons
            for sample in SampleDungeons.all {
                modelContext.insert(sample)
            }
        }
    }
    
    /// Convert a ContentDungeon (server-driven) to a SwiftData Dungeon
    private func buildDungeon(from cd: ContentDungeon) -> Dungeon? {
        let theme = DungeonTheme(rawValue: cd.theme.capitalized) ?? .cave
        let difficulty = DungeonDifficulty(rawValue: cd.difficulty.capitalized) ?? .normal
        
        let rooms = cd.rooms.map { cr in
            let encounterType = EncounterType(rawValue: cr.encounterType.capitalized) ?? .combat
            let primaryStat = StatType(rawValue: cr.primaryStat.capitalized) ?? .strength
            return DungeonRoom(
                name: cr.name,
                description: cr.description,
                encounterType: encounterType,
                primaryStat: primaryStat,
                difficultyRating: cr.difficultyRating,
                isBossRoom: cr.isBossRoom,
                bonusLootChance: cr.bonusLootChance
            )
        }
        
        // Parse stat requirements from server data
        let statReqs: [StatRequirement] = (cd.statRequirements ?? []).compactMap { sr in
            guard let stat = StatType(rawValue: sr.stat.capitalized) else { return nil }
            return StatRequirement(stat: stat, minimum: sr.value)
        }
        
        return Dungeon(
            name: cd.name,
            description: cd.description,
            theme: theme,
            difficulty: difficulty,
            rooms: rooms,
            levelRequirement: cd.levelRequirement,
            recommendedStatTotal: cd.recommendedStatTotal,
            maxPartySize: cd.maxPartySize,
            baseExpReward: cd.baseExpReward,
            baseGoldReward: cd.baseGoldReward,
            lootTier: cd.lootTier,
            minHPRequired: cd.minHPRequired ?? 50,
            statRequirements: statReqs
        )
    }
}

// MARK: - Active Dungeon Run Card

struct ActiveDungeonRunCard: View {
    let run: DungeonRun
    let dungeon: Dungeon
    let onTap: () -> Void
    
    @State private var shimmerOffset: CGFloat = -1.0
    @State private var glowPulse: Bool = false
    @State private var iconBounce: Bool = false
    @State private var particlePhase: Bool = false
    
    /// Whether the dungeon is still actively running (timer not complete)
    private var isRunning: Bool {
        !run.isTimerComplete && !run.isResolved
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Floating particles while running
                if isRunning {
                    ForEach(0..<5, id: \.self) { index in
                        Image(systemName: "sparkle")
                            .font(.system(size: CGFloat.random(in: 6...10)))
                            .foregroundColor(Color("AccentGold").opacity(0.5))
                            .offset(
                                x: dungeonParticleX(index: index),
                                y: particlePhase ? dungeonParticleYEnd(index: index) : dungeonParticleYStart(index: index)
                            )
                            .opacity(particlePhase ? 0.0 : 0.6)
                    }
                }
                
                    VStack(spacing: 14) {
                    HStack {
                        // Dungeon thumbnail in active run card
                        Image(dungeon.theme.thumbnailImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color("AccentGold").opacity(0.4), lineWidth: 1)
                            )
                            .scaleEffect(isRunning && iconBounce ? 1.05 : 1.0)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(run.isTimerComplete && !run.isResolved ? "Results Ready!" : "Dungeon Active")
                                .font(.custom("Avenir-Heavy", size: 14))
                                .foregroundColor(Color("AccentGold"))
                            Text(dungeon.name)
                                .font(.custom("Avenir-Heavy", size: 20))
                        }
                        Spacer()
                        
                        if run.isTimerComplete && !run.isResolved {
                            // Timer done — show claim badge
                            Text("Claim")
                                .font(.custom("Avenir-Heavy", size: 13))
                                .foregroundColor(.black)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(Color("AccentGold"))
                                .clipShape(Capsule())
                        } else if run.isResolved {
                            Text("View")
                                .font(.custom("Avenir-Heavy", size: 13))
                                .foregroundColor(Color("AccentGold"))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(Capsule().stroke(Color("AccentGold"), lineWidth: 1.5))
                        } else {
                            // Timer still running — animated sword icon + timer
                            VStack(alignment: .trailing, spacing: 4) {
                                Image(systemName: "shield.lefthalf.filled")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color("AccentGold"))
                                    .scaleEffect(iconBounce ? 1.15 : 0.95)
                                
                                Text(run.timeRemainingFormatted)
                                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color("AccentGold"))
                                Text("remaining")
                                    .font(.custom("Avenir-Medium", size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Progress Bar with shimmer
                    if !run.isResolved {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.secondary.opacity(0.2))
                                
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color("AccentGold"), Color("AccentOrange")],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                    
                                    // Shimmer overlay
                                    if isRunning {
                                        RoundedRectangle(cornerRadius: 4)
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
                                .frame(width: geometry.size.width * run.timerProgress)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                        .frame(height: 8)
                    }
                    
                    // Party info
                    if run.isCoopRun {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 10))
                            Text(run.partyMemberNames.joined(separator: " & "))
                                .font(.custom("Avenir-Medium", size: 11))
                        }
                        .foregroundColor(Color("AccentPurple"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(20)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color("CardBackground"))
                    .shadow(
                        color: Color("AccentGold").opacity(isRunning && glowPulse ? 0.35 : 0.15),
                        radius: isRunning && glowPulse ? 16 : 10,
                        x: 0, y: 4
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .onAppear {
            startDungeonAnimations()
        }
    }
    
    // MARK: - Animation Setup
    
    private func startDungeonAnimations() {
        guard isRunning else { return }
        
        withAnimation(
            .linear(duration: 2.0)
            .repeatForever(autoreverses: false)
        ) {
            shimmerOffset = 1.15
        }
        
        withAnimation(
            .easeInOut(duration: 1.8)
            .repeatForever(autoreverses: true)
        ) {
            glowPulse = true
        }
        
        withAnimation(
            .easeInOut(duration: 0.8)
            .repeatForever(autoreverses: true)
        ) {
            iconBounce = true
        }
        
        withAnimation(
            .easeOut(duration: 3.0)
            .repeatForever(autoreverses: false)
        ) {
            particlePhase = true
        }
    }
    
    // MARK: - Particle Helpers
    
    private func dungeonParticleX(index: Int) -> CGFloat {
        let positions: [CGFloat] = [-50, -15, 20, 55, -35]
        return positions[index % positions.count]
    }
    
    private func dungeonParticleYStart(index: Int) -> CGFloat {
        let starts: [CGFloat] = [15, 25, 10, 20, 30]
        return starts[index % starts.count]
    }
    
    private func dungeonParticleYEnd(index: Int) -> CGFloat {
        let ends: [CGFloat] = [-45, -65, -35, -55, -75]
        return ends[index % ends.count]
    }
}

// MARK: - Dungeon Section

struct DungeonSection: View {
    let difficulty: DungeonDifficulty
    let dungeons: [Dungeon]
    let character: PlayerCharacter?
    let onSelect: (Dungeon) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: difficulty.icon)
                    .foregroundColor(Color(difficulty.color))
                Text(difficulty.rawValue)
                    .font(.custom("Avenir-Heavy", size: 18))
                
                HStack(spacing: 2) {
                    ForEach(0..<4, id: \.self) { i in
                        Image(systemName: i < dungeons.first!.difficultyStars ? "star.fill" : "star")
                            .font(.system(size: 10))
                            .foregroundColor(Color(difficulty.color))
                    }
                }
            }
            .padding(.horizontal)
            
            ForEach(dungeons, id: \.id) { dungeon in
                DungeonCard(dungeon: dungeon, character: character) {
                    onSelect(dungeon)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Dungeon Card

struct DungeonCard: View {
    let dungeon: Dungeon
    let character: PlayerCharacter?
    let onTap: () -> Void
    
    private var meetsLevel: Bool {
        (character?.level ?? 0) >= dungeon.levelRequirement
    }
    
    private var meetsHP: Bool {
        (character?.currentHP ?? 0) >= dungeon.hpCost
    }
    
    private var canEnter: Bool {
        meetsLevel && meetsHP
    }
    
    private var overallChance: Double {
        guard let character = character else { return 0 }
        return DungeonEngine.overallSuccessEstimate(party: [character], dungeon: dungeon)
    }
    
    private var chanceInfo: (text: String, color: String) {
        DungeonEngine.powerDescription(chance: overallChance)
    }
    
    private var statReadiness: Double {
        guard let character = character else { return 0 }
        return DungeonEngine.calculateStatReadiness(party: [character], dungeon: dungeon)
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Dungeon thumbnail
                Image(dungeon.theme.thumbnailImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(dungeon.difficulty.color).opacity(0.4), lineWidth: 1.5)
                    )
                
                VStack(alignment: .leading, spacing: 5) {
                    // Metadata row
                    HStack(spacing: 5) {
                        Text(dungeon.difficulty.rawValue)
                            .font(.custom("Avenir-Heavy", size: 10))
                            .foregroundColor(Color(dungeon.difficulty.color))
                            .lineLimit(1)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color(dungeon.difficulty.color).opacity(0.2)))
                        
                        Text("Lv.\(dungeon.levelRequirement)+")
                            .font(.custom("Avenir-Medium", size: 10))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        Text("\(dungeon.roomCount) rooms")
                            .font(.custom("Avenir-Medium", size: 10))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        HStack(spacing: 2) {
                            Image(systemName: "clock")
                                .font(.system(size: 8))
                            Text(dungeon.durationFormatted)
                        }
                        .font(.custom("Avenir-Medium", size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    }
                    
                    Text(dungeon.name)
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(meetsLevel ? .primary : .secondary)
                        .lineLimit(1)
                    
                    // Rewards row
                    HStack(spacing: 10) {
                        HStack(spacing: 3) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 10))
                            Text("+\(dungeon.baseExpReward)")
                        }
                        .font(.custom("Avenir-Heavy", size: 11))
                        .foregroundColor(Color("AccentGold"))
                        .lineLimit(1)
                        .fixedSize()
                        
                        HStack(spacing: 3) {
                            Image(systemName: "dollarsign.circle")
                                .font(.system(size: 10))
                            Text("+\(dungeon.baseGoldReward)")
                        }
                        .font(.custom("Avenir-Medium", size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .fixedSize()
                        
                        HStack(spacing: 3) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 10))
                            Text("-\(dungeon.hpCost) HP")
                        }
                        .font(.custom("Avenir-Heavy", size: 11))
                        .foregroundColor(meetsHP ? Color("AccentGreen") : Color("DifficultyHard"))
                        .lineLimit(1)
                        .fixedSize()
                        
                        if dungeon.maxPartySize > 1 {
                            HStack(spacing: 3) {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 10))
                                Text("Co-op")
                            }
                            .font(.custom("Avenir-Medium", size: 11))
                            .foregroundColor(Color("AccentPurple"))
                            .lineLimit(1)
                            .fixedSize()
                        }
                    }
                }
                
                Spacer(minLength: 4)
                
                if !canEnter {
                    VStack(spacing: 2) {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.secondary)
                        if meetsLevel && !meetsHP {
                            Text("Low HP")
                                .font(.custom("Avenir-Heavy", size: 8))
                                .foregroundColor(Color("DifficultyHard"))
                        }
                    }
                } else if character != nil {
                    Text(chanceInfo.text)
                        .font(.custom("Avenir-Heavy", size: 10))
                        .foregroundColor(Color(chanceInfo.color))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color(chanceInfo.color).opacity(0.15)))
                        .fixedSize()
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("CardBackground"))
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
            .opacity(meetsLevel ? 1.0 : 0.6)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onTap()
            } label: {
                Label("View Details", systemImage: "info.circle")
            }
            if meetsLevel {
                Button {
                    onTap()
                } label: {
                    Label("Run Dungeon", systemImage: "play.fill")
                }
            } else {
                Label("Requires Level \(dungeon.levelRequirement)", systemImage: "lock.fill")
            }
        }
    }
}

// MARK: - Dungeon Detail View

struct DungeonDetailView: View {
    let dungeon: Dungeon
    let character: PlayerCharacter?
    let hasActiveRun: Bool
    var hasActiveTraining: Bool = false
    let onStartSolo: ([PlayerCharacter]) -> Void
    let onStartCoop: ([PlayerCharacter]) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var gameEngine: GameEngine
    
    private var meetsLevel: Bool {
        (character?.level ?? 0) >= dungeon.levelRequirement
    }
    
    private var meetsHP: Bool {
        (character?.currentHP ?? 0) >= dungeon.hpCost
    }
    
    private var canStart: Bool {
        meetsLevel && meetsHP && !hasActiveRun && !hasActiveTraining
    }
    
    private var canCoop: Bool {
        guard let character = character else { return false }
        return character.hasPartner && dungeon.maxPartySize >= 2 && canStart
    }
    
    private var overallChance: Double {
        guard let character = character else { return 0 }
        return DungeonEngine.overallSuccessEstimate(party: [character], dungeon: dungeon)
    }
    
    private var chanceInfo: (text: String, color: String) {
        DungeonEngine.powerDescription(chance: overallChance)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundTop").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            Image(dungeon.theme.thumbnailImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color(dungeon.difficulty.color).opacity(0.5), lineWidth: 2)
                                )
                                .shadow(color: Color(dungeon.difficulty.color).opacity(0.3), radius: 12)
                            
                            Text(dungeon.name)
                                .font(.custom("Avenir-Heavy", size: 28))
                            
                            HStack(spacing: 8) {
                                Text(dungeon.difficulty.rawValue)
                                    .font(.custom("Avenir-Heavy", size: 14))
                                    .foregroundColor(Color(dungeon.difficulty.color))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color(dungeon.difficulty.color).opacity(0.2)))
                                
                                HStack(spacing: 2) {
                                    ForEach(0..<4, id: \.self) { i in
                                        Image(systemName: i < dungeon.difficultyStars ? "star.fill" : "star")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color(dungeon.difficulty.color))
                                    }
                                }
                            }
                        }
                        
                        // Description
                        Text(dungeon.dungeonDescription)
                            .font(.custom("Avenir-Medium", size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Stats Card
                        VStack(spacing: 16) {
                            DetailStatRow(icon: "door.left.hand.open", label: "Rooms", value: "\(dungeon.roomCount)")
                            DetailStatRow(icon: "clock.fill", label: "Duration", value: dungeon.durationFormatted,
                                         valueColor: Color("AccentGold"))
                            DetailStatRow(icon: "person.fill", label: "Level Required", value: "\(dungeon.levelRequirement)+",
                                         valueColor: meetsLevel ? Color("AccentGreen") : .red)
                            DetailStatRow(icon: "chart.bar.fill", label: "Recommended Stats", value: "\(dungeon.recommendedStatTotal)")
                            DetailStatRow(icon: "sparkles", label: "EXP Reward", value: "+\(dungeon.baseExpReward)")
                            DetailStatRow(icon: "dollarsign.circle", label: "Gold Reward", value: "+\(dungeon.baseGoldReward)")
                            DetailStatRow(icon: "gift.fill", label: "Loot Tier", value: "Tier \(dungeon.lootTier)")
                            DetailStatRow(icon: "heart.fill", label: "HP Cost", value: "-\(dungeon.hpCost)",
                                         valueColor: meetsHP ? Color("AccentGreen") : .red)
                            if dungeon.maxPartySize >= 2 {
                                DetailStatRow(icon: "person.2.fill", label: "Party Size", value: "Up to \(dungeon.maxPartySize)",
                                             valueColor: Color("AccentPurple"))
                            }
                            
                            Divider()
                            
                            // Overall success estimate
                            if character != nil {
                                HStack {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .foregroundColor(Color(chanceInfo.color))
                                        .frame(width: 24)
                                    Text("Success Estimate")
                                        .font(.custom("Avenir-Medium", size: 14))
                                    Spacer()
                                    Text(chanceInfo.text)
                                        .font(.custom("Avenir-Heavy", size: 16))
                                        .foregroundColor(Color(chanceInfo.color))
                                }
                                
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.secondary.opacity(0.2))
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color(chanceInfo.color))
                                            .frame(width: geometry.size.width * overallChance)
                                    }
                                }
                                .frame(height: 10)
                            }
                        }
                        .padding(20)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color("CardBackground")))
                        .padding(.horizontal)
                        
                        // Encounter overview
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Encounters")
                                .font(.custom("Avenir-Heavy", size: 18))
                            
                            ForEach(Array(dungeon.rooms.enumerated()), id: \.element.id) { index, room in
                                RoomOverviewRow(room: room, index: index)
                            }
                        }
                        .padding(20)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color("CardBackground")))
                        .padding(.horizontal)
                        
                        // Class Ability Tip
                        if let charClass = character?.characterClass {
                            HStack(spacing: 12) {
                                Image(systemName: charClass.icon)
                                    .foregroundColor(Color("AccentPurple"))
                                    .font(.title2)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(charClass.abilityName)
                                        .font(.custom("Avenir-Heavy", size: 14))
                                    Text(charClass.abilityDescription)
                                        .font(.custom("Avenir-Medium", size: 12))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color("AccentPurple").opacity(0.1)))
                            .padding(.horizontal)
                        }
                        
                        // AFK note
                        HStack(spacing: 10) {
                            Image(systemName: "clock.badge.checkmark")
                                .foregroundColor(Color("AccentGold"))
                            Text("Dungeons run in the background. Start a run and come back when the timer completes to see your results.")
                                .font(.custom("Avenir-Medium", size: 13))
                                .foregroundColor(.secondary)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color("AccentGold").opacity(0.08)))
                        .padding(.horizontal)
                        
                        // Active run warning
                        if hasActiveRun {
                            HStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(Color("AccentOrange"))
                                Text("You already have an active dungeon run. Complete or wait for it to finish before starting another.")
                                    .font(.custom("Avenir-Medium", size: 13))
                                    .foregroundColor(Color("AccentOrange"))
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color("AccentOrange").opacity(0.1)))
                            .padding(.horizontal)
                        }
                        
                        // Active training warning
                        if hasActiveTraining {
                            HStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Finish your training session before entering a dungeon.")
                                    .font(.custom("Avenir-Medium", size: 13))
                                    .foregroundColor(.orange)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.orange.opacity(0.1)))
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                    .padding(.bottom, canCoop ? 140 : 80)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Color("AccentGold"))
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 10) {
                    // HP status + Use Potion button
                    if let character = character {
                        HStack(spacing: 12) {
                            // Current HP display
                            HStack(spacing: 4) {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(meetsHP ? Color("AccentGreen") : .red)
                                Text("\(character.currentHP) / \(character.maxHP) HP")
                                    .font(.custom("Avenir-Heavy", size: 14))
                                    .foregroundColor(meetsHP ? .primary : .red)
                            }
                            
                            Spacer()
                            
                            // Use Potion button (inherits gameEngine from environment)
                            UseHPPotionButton(character: character)
                        }
                        .padding(.horizontal, 4)
                    }
                    
                    // Run Dungeon button (solo)
                    Button(action: {
                        if let character = character {
                            onStartSolo([character])
                        }
                    }) {
                        HStack {
                            Image(systemName: canStart ? "play.fill" : (hasActiveRun || hasActiveTraining ? "hourglass" : "lock.fill"))
                            Text(canStart ? "Run Dungeon (\(dungeon.durationFormatted))" :
                                    (hasActiveRun ? "Dungeon In Progress" :
                                        (hasActiveTraining ? "Training In Progress" :
                                            (!meetsLevel ? "Level \(dungeon.levelRequirement) Required" :
                                                "Not Enough HP (\(dungeon.hpCost) needed)"))))
                        }
                        .font(.custom("Avenir-Heavy", size: 18))
                        .foregroundColor(canStart ? .black : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            canStart ?
                            LinearGradient(colors: [Color("AccentGold"), Color("AccentOrange")], startPoint: .leading, endPoint: .trailing) :
                            LinearGradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(!canStart)
                    
                    // Co-op button
                    if canCoop, let character = character {
                        Button(action: {
                            var coopParty: [PlayerCharacter] = [character]
                            if let partner = PartnerProxy.from(character: character) {
                                coopParty.append(partner)
                            }
                            onStartCoop(coopParty)
                        }) {
                            HStack {
                                Image(systemName: "person.2.fill")
                                Text("Run with \(character.partnerName ?? "Partner")")
                            }
                            .font(.custom("Avenir-Heavy", size: 16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [Color("AccentPink"), Color("AccentPurple")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                }
                .padding()
                .background(Color("BackgroundTop"))
            }
        }
    }
}

// MARK: - Room Overview Row (Simplified)

struct RoomOverviewRow: View {
    let room: DungeonRoom
    let index: Int
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(room.isBossRoom ? Color("RarityEpic").opacity(0.2) : Color.secondary.opacity(0.15))
                    .frame(width: 36, height: 36)
                Text("\(index + 1)")
                    .font(.custom("Avenir-Heavy", size: 14))
                    .foregroundColor(room.isBossRoom ? Color("RarityEpic") : .secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: room.encounterType.icon)
                        .font(.caption)
                        .foregroundColor(Color(room.encounterType.color))
                    Text(room.name)
                        .font(.custom("Avenir-Heavy", size: 14))
                    if room.isBossRoom {
                        Text("BOSS")
                            .font(.custom("Avenir-Heavy", size: 9))
                            .foregroundColor(Color("RarityEpic"))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(Color("RarityEpic").opacity(0.2)))
                    }
                }
                
                Text(room.encounterType.rawValue)
                    .font(.custom("Avenir-Medium", size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Helper Views

struct DetailStatRow: View {
    let icon: String
    let label: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
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

struct DungeonTipsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(Color("AccentGold"))
                Text("Dungeon Tips")
                    .font(.custom("Avenir-Heavy", size: 16))
            }
            VStack(alignment: .leading, spacing: 8) {
                DungeonTip(text: "Dungeons run on a timer — start one and come back later!")
                DungeonTip(text: "Your stats and class determine success in each room")
                DungeonTip(text: "Equipment bonuses count — gear up before running!")
                DungeonTip(text: "Failed rooms cost HP — too many failures and you wipe")
                DungeonTip(text: "Boss rooms give double EXP and better loot chances")
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color("CardBackground").opacity(0.5)))
    }
}

struct DungeonTip: View {
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

// MARK: - Use HP Potion Button

struct UseHPPotionButton: View {
    let character: PlayerCharacter
    @EnvironmentObject var gameEngine: GameEngine
    @Environment(\.modelContext) private var modelContext
    @Query private var consumables: [Consumable]
    
    private var hpPotions: [Consumable] {
        consumables.filter {
            $0.consumableType == .hpPotion &&
            $0.characterID == character.id &&
            $0.isUsable
        }
    }
    
    private var bestPotion: Consumable? {
        hpPotions.first
    }
    
    private var isFullHP: Bool {
        character.currentHP >= character.maxHP
    }
    
    var body: some View {
        if let potion = bestPotion, !isFullHP {
            Button {
                if gameEngine.useConsumable(potion, on: character, context: modelContext) {
                    ToastManager.shared.showSuccess("Used \(potion.name)", subtitle: "+\(potion.effectValue) HP")
                    AudioManager.shared.play(.claimReward)
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "cross.vial.fill")
                        .font(.system(size: 12))
                    Text("Use Potion")
                        .font(.custom("Avenir-Heavy", size: 12))
                    Text("(\(hpPotions.count))")
                        .font(.custom("Avenir-Medium", size: 11))
                        .foregroundColor(.secondary)
                }
                .foregroundColor(Color("AccentGreen"))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color("AccentGreen").opacity(0.15))
                )
            }
        }
    }
}

#Preview {
    DungeonListView()
        .environmentObject(GameEngine())
}
