import SwiftUI
import SwiftData

struct DungeonRunView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var gameEngine: GameEngine
    @Query(sort: \WeeklyRaidBoss.weekStartDate, order: .reverse) private var raidBosses: [WeeklyRaidBoss]
    
    let dungeon: Dungeon
    @Bindable var run: DungeonRun
    let party: [PlayerCharacter]
    
    @State private var phase: RunPhase = .waiting
    @State private var completionResult: DungeonCompletionResult?
    @State private var animateIcon = false
    @State private var showFullLog = false
    @State private var hapticSuccess = 0
    @State private var hapticError = 0
    @State private var timerTick = 0 // forces UI refresh
    @State private var collectedCards: [CardDropEngine.CollectResult] = []
    
    // Animated result states
    @State private var showResultProgress = false
    @State private var resultExpProgress: Double = 0
    @State private var resultDisplayedGold: Int = 0
    @State private var resultShowStats = false
    @State private var resultAnimatedStatIndices: Set<Int> = []
    
    // Timer that fires every second to update countdown
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    enum RunPhase {
        case waiting    // AFK timer countdown
        case resolving  // Brief animation while resolving
        case results    // Show victory/defeat + full log
    }
    
    var body: some View {
        ZStack {
            GeometryReader { geo in
                Image(dungeon.theme.thumbnailImage)
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            .ignoresSafeArea()
            
            Color("BackgroundTop").opacity(0.75)
                .ignoresSafeArea()
            
            switch phase {
            case .waiting:
                waitingContent
            case .resolving:
                resolvingContent
            case .results:
                if let result = completionResult {
                    if result.success {
                        CelebrationFloatingParticlesView()
                            .ignoresSafeArea()
                            .opacity(0.3)
                        CelebrationConfettiOverlay()
                            .ignoresSafeArea()
                            .allowsHitTesting(false)
                    } else {
                        DefeatOverlay()
                            .ignoresSafeArea()
                            .allowsHitTesting(false)
                    }
                }
                resultsContent
            }
        }
        .sensoryFeedback(.success, trigger: hapticSuccess)
        .sensoryFeedback(.error, trigger: hapticError)
        .onReceive(timer) { _ in
            timerTick += 1
            // Check if timer just completed while we're on the waiting screen
            if phase == .waiting && run.isTimerComplete && !run.isResolved {
                beginResolve()
            }
        }
        .onAppear {
            determineInitialPhase()
        }
    }
    
    // MARK: - Determine Initial Phase
    
    private func determineInitialPhase() {
        if run.isResolved {
            // Already resolved — rebuild the result and show it
            completionResult = DungeonEngine.processDungeonCompletion(
                dungeon: dungeon,
                run: run,
                party: party
            )
            phase = .results
        } else if run.isTimerComplete {
            // Timer done but not yet resolved — resolve now
            beginResolve()
        } else {
            // Still waiting
            phase = .waiting
        }
    }
    
    // MARK: - Waiting Content (Timer Countdown)
    
    private var waitingContent: some View {
        VStack(spacing: 0) {
            // Close button
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark")
                        Text("Close")
                    }
                    .font(.custom("Avenir-Heavy", size: 14))
                    .foregroundColor(.secondary)
                }
            }
            .padding()
            
            Spacer()
            
            // Dungeon icon with pulse animation
            ZStack {
                // Outer ring showing progress
                Circle()
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 8)
                    .frame(width: 160, height: 160)
                Circle()
                    .trim(from: 0, to: run.timerProgress)
                    .stroke(
                        LinearGradient(
                            colors: [Color("AccentGold"), Color("AccentOrange")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                
                Image(dungeon.theme.thumbnailImage)
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 130, height: 130)
                    .clipShape(Circle())
                    .overlay(
                        Circle().fill(Color(dungeon.difficulty.color).opacity(0.1))
                    )
                    .scaleEffect(animateIcon ? 1.05 : 0.95)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateIcon)
            }
            .onAppear { animateIcon = true }
            
            Spacer().frame(height: 32)
            
            Text(dungeon.name)
                .font(.custom("Avenir-Heavy", size: 26))
            
            Text("Dungeon in progress...")
                .font(.custom("Avenir-Medium", size: 16))
                .foregroundColor(.secondary)
                .padding(.top, 4)
            
            Spacer().frame(height: 32)
            
            // Timer countdown
            let _ = timerTick // force re-evaluation
            Text(run.timeRemainingFormatted)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(Color("AccentGold"))
            
            Text("remaining")
                .font(.custom("Avenir-Medium", size: 14))
                .foregroundColor(.secondary)
            
            Spacer().frame(height: 24)
            
            // Progress bar
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.secondary.opacity(0.2))
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [Color("AccentGold"), Color("AccentOrange")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * run.timerProgress)
                    }
                }
                .frame(height: 10)
                .padding(.horizontal, 40)
                
                Text("\(Int(run.timerProgress * 100))% complete")
                    .font(.custom("Avenir-Medium", size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer().frame(height: 16)
            
            // Party info
            if run.isCoopRun {
                HStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(Color("AccentPurple"))
                    Text(run.partyMemberNames.joined(separator: " & "))
                        .font(.custom("Avenir-Medium", size: 14))
                        .foregroundColor(Color("AccentPurple"))
                }
            }
            
            // Info note
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundColor(.secondary)
                Text("You can close this screen and come back later.")
                    .font(.custom("Avenir-Medium", size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 12)
            
            Spacer()
            Spacer()
        }
    }
    
    // MARK: - Resolving Animation
    
    private var resolvingContent: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                Image(dungeon.theme.thumbnailImage)
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(
                        Circle().fill(Color(dungeon.difficulty.color).opacity(0.15))
                    )
                    .scaleEffect(animateIcon ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: animateIcon)
            }
            
            Text("Resolving encounters...")
                .font(.custom("Avenir-Heavy", size: 20))
                .foregroundColor(.secondary)
            
            ProgressView()
                .tint(Color("AccentGold"))
            
            Spacer()
            Spacer()
        }
    }
    
    // MARK: - Results Content
    
    private var resultsContent: some View {
        VStack(spacing: 0) {
            // Close button at top
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark")
                        Text("Close")
                    }
                    .font(.custom("Avenir-Heavy", size: 14))
                    .foregroundColor(.secondary)
                }
            }
            .padding()
            
            ScrollView {
                VStack(spacing: 24) {
                    if let result = completionResult {
                        resultHeader(result: result)
                        summaryCard(result: result)
                        
                        if resultShowStats && !result.currentStats.isEmpty {
                            dungeonStatsCard(result: result)
                        }
                        
                        if resultShowStats && result.raidDamageDealt > 0 {
                            dungeonRaidDamageCard(result: result)
                        }
                        
                        if result.secretDiscovery {
                            secretDiscoveryCard(result: result)
                        }
                        
                        roomLog(result: result)
                        
                        if !result.lootDrops.isEmpty {
                            lootSection(result: result)
                        }
                        
                        if !collectedCards.isEmpty {
                            cardDropSection
                        }
                        
                        if !run.feedEntries.isEmpty {
                            activityFeedPanel
                        }
                    }
                }
                .padding()
                .padding(.bottom, 100)
            }
            
            // Return button
            VStack {
                Button(action: { dismiss() }) {
                    Text("Return")
                        .font(.custom("Avenir-Heavy", size: 18))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color("AccentGold"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .background(
                LinearGradient(colors: [Color.clear, Color("BackgroundBottom")], startPoint: .top, endPoint: .bottom)
                    .frame(height: 100)
                    .allowsHitTesting(false)
                    .offset(y: -30)
            )
        }
    }
    
    // MARK: - Result Header
    
    private func ratingColor(_ rating: String) -> Color {
        switch rating {
        case "S": return Color("AccentGold")
        case "A": return Color("AccentGreen")
        case "B": return Color("AccentPurple")
        case "C": return .secondary
        case "D": return Color("AccentOrange")
        default: return Color("DifficultyHard")
        }
    }
    
    private func resultHeader(result: DungeonCompletionResult) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [(result.success ? Color("AccentGold") : Color.red).opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                Image(systemName: result.success ? "trophy.fill" : "xmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(result.success ? Color("AccentGold") : .red)
                    .symbolEffect(.bounce)
            }
            
            Text(result.success ? "Dungeon Cleared!" : "Dungeon Failed")
                .font(.custom("Avenir-Heavy", size: 30))
            
            // Performance Rating Badge
            if !result.performanceRating.isEmpty {
                HStack(spacing: 8) {
                    Text("Rating:")
                        .font(.custom("Avenir-Medium", size: 14))
                        .foregroundColor(.secondary)
                    
                    Text(result.performanceRating)
                        .font(.custom("Avenir-Black", size: 24))
                        .foregroundColor(ratingColor(result.performanceRating))
                    
                    if result.lootMultiplier != 1.0 {
                        Text(String(format: "%.0f%% Loot", result.lootMultiplier * 100))
                            .font(.custom("Avenir-Heavy", size: 12))
                            .foregroundColor(result.lootMultiplier > 1.0 ? Color("AccentGreen") : Color("DifficultyHard"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill((result.lootMultiplier > 1.0 ? Color("AccentGreen") : Color("DifficultyHard")).opacity(0.15)))
                    }
                }
            }
            
            Text(dungeon.name)
                .font(.custom("Avenir-Medium", size: 18))
                .foregroundColor(.secondary)
            
            if !result.success {
                Text("Your party's HP reached zero.\nLevel up and gear up before trying again!")
                    .font(.custom("Avenir-Medium", size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Summary Card
    
    private func summaryCard(result: DungeonCompletionResult) -> some View {
        VStack(spacing: 16) {
            // Dungeon Stats
            SummaryRow(icon: "door.left.hand.open", label: "Rooms Cleared", value: "\(result.roomsCleared)/\(result.totalRooms)", color: result.success ? Color("AccentGreen") : .secondary)
            SummaryRow(icon: "heart.fill", label: "HP Remaining", value: "\(result.hpRemaining)/\(result.maxHP)", color: .red)
            
            Divider().overlay(Color.white.opacity(0.05))
            
            // EXP Progress Bar
            VStack(spacing: 8) {
                HStack {
                    HStack(spacing: 4) {
                        ExpGemIcon(size: 14)
                        Text("Lv. \(result.characterLevel)")
                            .font(.custom("Avenir-Heavy", size: 14))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text("+\(result.totalExp) EXP")
                        .font(.custom("Avenir-Heavy", size: 13))
                        .foregroundColor(Color("AccentGold").opacity(0.9))
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.1))
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [Color("AccentGold"), Color("AccentGold").opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, geo.size.width * resultExpProgress))
                    }
                }
                .frame(height: 10)
            }
            
            Divider().overlay(Color.white.opacity(0.05))
            
            // Gold Counter
            HStack {
                HStack(spacing: 6) {
                    GoldPileIcon(size: 24)
                    
                    Text("Gold")
                        .font(.custom("Avenir-Medium", size: 14))
                }
                Spacer()
                
                HStack(spacing: 6) {
                    Text("\(result.goldBefore + resultDisplayedGold)")
                        .font(.custom("Avenir-Heavy", size: 18))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())
                    
                    Text("+\(resultDisplayedGold)")
                        .font(.custom("Avenir-Heavy", size: 14))
                        .foregroundColor(Color("AccentGold"))
                        .contentTransition(.numericText())
                }
            }
            
            // Gem reward
            if result.gemsGained > 0 {
                Divider().overlay(Color.white.opacity(0.05))
                HStack {
                    HStack(spacing: 6) {
                        GemIconView(amount: result.gemsGained, size: 22)
                        Text("Gems")
                            .font(.custom("Avenir-Medium", size: 14))
                    }
                    Spacer()
                    Text("+\(result.gemsGained)")
                        .font(.custom("Avenir-Heavy", size: 18))
                        .foregroundColor(Color("AccentPurple"))
                }
            }
            
            if result.isCoopRun && result.bondExpEarned > 0 {
                Divider().overlay(Color.white.opacity(0.05))
                SummaryRow(icon: "heart.circle.fill", label: "Bond EXP", value: "+\(result.bondExpEarned)", color: Color("AccentPink"))
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color("CardBackground")))
        .onAppear {
            startResultAnimations(result: result)
        }
    }
    
    // MARK: - Character Stats Section (Dungeon)
    
    @ViewBuilder
    private func dungeonRaidDamageCard(result: DungeonCompletionResult) -> some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(Color("DifficultyHard"))
                Text("Raid Boss Damage")
                    .font(.custom("Avenir-Heavy", size: 16))
                Spacer()
            }
            
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("-\(result.raidDamageDealt) HP")
                        .font(.custom("Avenir-Heavy", size: 18))
                        .foregroundColor(Color("DifficultyHard"))
                    Text("Dealt to Boss")
                        .font(.custom("Avenir-Medium", size: 11))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                if result.raidRetaliationTaken > 0 {
                    VStack(spacing: 4) {
                        Text("-\(result.raidRetaliationTaken) HP")
                            .font(.custom("Avenir-Heavy", size: 18))
                            .foregroundColor(Color("AccentOrange"))
                        Text("Boss struck back!")
                            .font(.custom("Avenir-Medium", size: 11))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color("DifficultyHard").opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
    
    private func dungeonStatsCard(result: DungeonCompletionResult) -> some View {
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
                    let isAnimated = resultAnimatedStatIndices.contains(index)
                    
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
                            Text("\(statValue)")
                                .font(.custom("Avenir-Heavy", size: 16))
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.03))
                    )
                    .opacity(isAnimated ? 1 : 0.3)
                    .scaleEffect(isAnimated ? 1 : 0.95)
                }
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color("CardBackground")))
    }
    
    // MARK: - Dungeon Result Animations
    
    private func startResultAnimations(result: DungeonCompletionResult) {
        // EXP bar fill
        resultExpProgress = result.expProgressBefore
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 1.0)) {
                resultExpProgress = result.expProgressAfter
            }
        }
        
        // Gold counter
        let target = result.totalGold
        if target > 0 {
            let steps = min(target, 30)
            let stepDuration = 0.8 / Double(steps)
            for i in 1...steps {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + Double(i) * stepDuration) {
                    withAnimation(.easeOut(duration: 0.05)) {
                        resultDisplayedGold = Int(Double(target) * Double(i) / Double(steps))
                    }
                }
            }
        }
        
        // Stagger stat card items
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            resultShowStats = true
            for index in StatType.allCases.indices {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.08) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        _ = resultAnimatedStatIndices.insert(index)
                    }
                }
            }
        }
    }
    
    // MARK: - Room Log
    
    private func roomLog(result: DungeonCompletionResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "scroll.fill")
                    .foregroundColor(Color("AccentGold"))
                Text("Room-by-Room")
                    .font(.custom("Avenir-Heavy", size: 16))
                Spacer()
            }
            
            ForEach(Array(result.roomResults.enumerated()), id: \.offset) { index, roomResult in
                roomResultRow(index: index, result: roomResult)
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color("CardBackground")))
    }
    
    private func roomResultRow(index: Int, result: RoomResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(result.success ? Color("AccentGreen").opacity(0.2) : Color.red.opacity(0.2))
                        .frame(width: 32, height: 32)
                    Text("\(index + 1)")
                        .font(.custom("Avenir-Heavy", size: 13))
                        .foregroundColor(result.success ? Color("AccentGreen") : .red)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(result.roomName)
                            .font(.custom("Avenir-Heavy", size: 14))
                        Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(result.success ? Color("AccentGreen") : .red)
                    }
                    if !result.approachName.isEmpty {
                        Text("Approach: \(result.approachName)")
                            .font(.custom("Avenir-Medium", size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if result.success {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("+\(result.expEarned) EXP")
                            .font(.custom("Avenir-Heavy", size: 11))
                            .foregroundColor(Color("AccentGold"))
                        Text("+\(result.goldEarned) G")
                            .font(.custom("Avenir-Medium", size: 10))
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("-\(result.hpLost) HP")
                        .font(.custom("Avenir-Heavy", size: 12))
                        .foregroundColor(.red)
                }
            }
            
            Text(result.narrativeText)
                .font(.custom("Avenir-Medium", size: 12))
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            if result.lootDropped {
                HStack(spacing: 4) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 10))
                    Text("Loot found!")
                        .font(.custom("Avenir-Heavy", size: 11))
                }
                .foregroundColor(Color("AccentPurple"))
            }
            
            if index < (completionResult?.roomResults.count ?? 0) - 1 {
                Divider()
            }
        }
    }
    
    // MARK: - Loot Section
    
    private func lootSection(result: DungeonCompletionResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "gift.fill")
                    .foregroundColor(Color("AccentPurple"))
                Text("Loot Drops")
                    .font(.custom("Avenir-Heavy", size: 16))
            }
            ForEach(result.lootDrops, id: \.id) { item in
                LootDropRow(equipment: item)
            }
            
            if !result.materialDrops.isEmpty {
                Divider().overlay(Color.white.opacity(0.1))
                HStack {
                    Image(systemName: "cube.fill")
                        .foregroundColor(Color("AccentOrange"))
                    Text("Materials Gathered")
                        .font(.custom("Avenir-Heavy", size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                ForEach(consolidatedMaterialDrops(result.materialDrops)) { drop in
                    MaterialLootRow(drop: drop, size: 36)
                }
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color("CardBackground")))
    }
    
    private func consolidatedMaterialDrops(_ drops: [MaterialDrop]) -> [MaterialDrop] {
        var grouped: [String: (MaterialType, ItemRarity, Int)] = [:]
        for drop in drops {
            let key = "\(drop.type.rawValue)-\(drop.rarity.rawValue)"
            if let existing = grouped[key] {
                grouped[key] = (existing.0, existing.1, existing.2 + drop.amount)
            } else {
                grouped[key] = (drop.type, drop.rarity, drop.amount)
            }
        }
        return grouped.values.map { MaterialDrop(type: $0.0, rarity: $0.1, amount: $0.2) }
            .sorted { $0.type.rawValue < $1.type.rawValue }
    }
    
    // MARK: - Secret Discovery Card
    
    private func secretDiscoveryCard(result: DungeonCompletionResult) -> some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(Color("AccentGold"))
                    .symbolEffect(.pulse)
                Text("Secret Cache Discovered!")
                    .font(.custom("Avenir-Heavy", size: 18))
                    .foregroundColor(Color("AccentGold"))
            }
            
            if !result.secretNarrative.isEmpty {
                Text(result.secretNarrative)
                    .font(.custom("Avenir-Medium", size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
            
            Divider()
                .overlay(Color("AccentGold").opacity(0.3))
            
            VStack(spacing: 10) {
                if result.secretBonusGold > 0 {
                    HStack(spacing: 8) {
                        GoldCoinIcon(size: 16)
                        Text("Bonus Gold")
                            .font(.custom("Avenir-Medium", size: 14))
                        Spacer()
                        Text("+\(result.secretBonusGold)")
                            .font(.custom("Avenir-Heavy", size: 14))
                            .foregroundColor(Color("AccentGold"))
                    }
                }
                
                if result.secretBonusMaterials > 0 {
                    HStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color("AccentPurple").opacity(0.15))
                                .frame(width: 28, height: 28)
                            MaterialIconView(materialType: .crystal, rarity: .rare, size: 24)
                        }
                        Text("Bonus Materials")
                            .font(.custom("Avenir-Medium", size: 14))
                        Spacer()
                        Text("+\(result.secretBonusMaterials)")
                            .font(.custom("Avenir-Heavy", size: 14))
                            .foregroundColor(Color("AccentPurple"))
                    }
                }
                
                if result.secretEquipmentDrop {
                    HStack(spacing: 8) {
                        Image(systemName: "shield.lefthalf.filled")
                            .foregroundColor(Color("RarityLegendary"))
                        Text("Rare Equipment Found!")
                            .font(.custom("Avenir-Heavy", size: 14))
                            .foregroundColor(Color("RarityLegendary"))
                        Spacer()
                        Image(systemName: "sparkle")
                            .foregroundColor(Color("RarityLegendary"))
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("CardBackground"))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color("AccentGold").opacity(0.4), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Card Drop Section
    
    private var cardDropSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "rectangle.portrait.fill")
                    .foregroundColor(Color("AccentGreen"))
                Text("Cards Discovered")
                    .font(.custom("Avenir-Heavy", size: 16))
                Spacer()
                Text("\(collectedCards.count) card\(collectedCards.count == 1 ? "" : "s")")
                    .font(.custom("Avenir-Medium", size: 12))
                    .foregroundColor(.secondary)
            }
            
            ForEach(Array(collectedCards.enumerated()), id: \.offset) { _, result in
                cardResultRow(result: result)
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color("CardBackground")))
    }
    
    private func cardResultRow(result: CardDropEngine.CollectResult) -> some View {
        let card: MonsterCard
        let isNew: Bool
        let rarityUpgraded: Bool
        
        switch result {
        case .newCard(let c):
            card = c
            isNew = true
            rarityUpgraded = false
        case .duplicateAbsorbed(let c, let upgraded):
            card = c
            isNew = false
            rarityUpgraded = upgraded
        }
        
        return HStack(spacing: 12) {
            // Card icon with rarity color
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(card.rarity.color).opacity(0.2))
                    .frame(width: 40, height: 52)
                Image(systemName: "rectangle.portrait.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(card.rarity.color))
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(card.name)
                        .font(.custom("Avenir-Heavy", size: 14))
                    
                    if isNew {
                        Text("NEW")
                            .font(.custom("Avenir-Heavy", size: 9))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color("AccentGreen"))
                            .clipShape(Capsule())
                    } else if rarityUpgraded {
                        Text("RANK UP!")
                            .font(.custom("Avenir-Heavy", size: 9))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color(card.rarity.color))
                            .clipShape(Capsule())
                    } else {
                        Text("+1 DUP")
                            .font(.custom("Avenir-Heavy", size: 9))
                            .foregroundColor(Color("AccentGold"))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color("AccentGold").opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                
                Text("\(card.rarity.rawValue) · \(card.bonusType.formatValue(card.bonusValue))")
                    .font(.custom("Avenir-Medium", size: 12))
                    .foregroundColor(Color(card.rarity.color))
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Activity Feed
    
    private var activityFeedPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showFullLog.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "text.book.closed.fill")
                        .foregroundColor(Color("AccentGold"))
                    Text("Adventure Log")
                        .font(.custom("Avenir-Heavy", size: 14))
                    Spacer()
                    Text("\(run.feedEntries.count) events")
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                    Image(systemName: showFullLog ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            if showFullLog {
                ForEach(run.feedEntries) { entry in
                    FeedEntryRow(entry: entry)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color("CardBackground").opacity(0.7))
        )
    }
    
    // MARK: - Resolve Logic
    
    private func beginResolve() {
        // Guard: if already resolved, just show results
        guard !run.isResolved else {
            completionResult = DungeonEngine.processDungeonCompletion(
                dungeon: dungeon,
                run: run,
                party: party
            )
            phase = .results
            return
        }
        
        phase = .resolving
        animateIcon = true
        
        // Brief animation, then resolve
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            var result = DungeonEngine.autoRunDungeon(
                dungeon: dungeon,
                run: run,
                party: party,
                cardPool: ContentManager.shared.activeCardPool
            )
            
            // Capture character state BEFORE rewards
            let leadChar = party.first
            let expProgressBefore = leadChar?.levelProgress ?? 0
            let goldBefore = leadChar?.gold ?? 0
            let charLevel = leadChar?.level ?? 1
            
            // Award EXP, gold, and gems to party members
            for member in party {
                if result.totalExp > 0 {
                    member.gainEXP(result.totalExp)
                }
                member.gold += result.totalGold / max(1, party.count)
                if result.gemsGained > 0 {
                    member.gems += result.gemsGained / max(1, party.count)
                }
            }
            
            // Grant equipment EXP per cleared room
            for (index, roomResult) in result.roomResults.enumerated() where roomResult.success {
                let isBoss = index < dungeon.rooms.count && dungeon.rooms[index].isBossRoom
                let roomEquipEXP = GameEngine.equipmentEXPForDungeonRoom(isBoss: isBoss)
                for member in party {
                    gameEngine.grantEquipmentEXP(
                        character: member,
                        amount: roomEquipEXP,
                        context: modelContext
                    )
                }
            }
            
            // Capture character state AFTER rewards
            let expProgressAfter = leadChar?.levelProgress ?? 0
            let goldAfter = leadChar?.gold ?? 0
            var statsSnapshot: [StatType: Int] = [:]
            if let effectiveStats = leadChar?.effectiveStats {
                for statType in StatType.allCases {
                    statsSnapshot[statType] = effectiveStats.value(for: statType)
                }
            }
            
            // Set snapshot data on result
            result.characterLevel = charLevel
            result.expProgressBefore = expProgressBefore
            result.expProgressAfter = expProgressAfter
            result.goldBefore = goldBefore
            result.goldAfter = goldAfter
            result.currentStats = statsSnapshot
            
            completionResult = result
            
            // Insert loot into model context and sync to cloud
            for item in result.lootDrops {
                modelContext.insert(item)
                Task { try? await SupabaseService.shared.syncEquipment(item) }
            }
            
            // Insert consumable drops into model context and sync to cloud
            for consumable in result.consumableDrops {
                modelContext.insert(consumable)
                Task { try? await SupabaseService.shared.syncConsumable(consumable) }
            }
            
            // Collect any dropped cards
            if let firstMember = party.first {
                let cardPool = ContentManager.shared.activeCardPool
                for roomResult in result.roomResults {
                    if let cardID = roomResult.cardDroppedID,
                       let contentCard = cardPool.first(where: { $0.id == cardID }) {
                        if let collectResult = CardDropEngine.collectCard(
                            contentCard: contentCard,
                            character: firstMember,
                            context: modelContext
                        ) {
                            collectedCards.append(collectResult)
                        }
                    }
                }
            }
            
            // Update daily quest progress
            if let firstMember = party.first {
                gameEngine.updateDailyQuestProgressForDungeonRoom(
                    roomCount: result.roomsCleared,
                    expGained: result.totalExp,
                    goldGained: result.totalGold,
                    character: firstMember,
                    context: modelContext
                )
                
                // Award crafting materials for each cleared room
                var collectedMaterials: [MaterialDrop] = []
                for (index, roomResult) in result.roomResults.enumerated() where roomResult.success {
                    if index < dungeon.rooms.count {
                        let drop = gameEngine.awardMaterialsForDungeonRoom(
                            encounterType: dungeon.rooms[index].encounterType,
                            dungeonTier: dungeon.lootTier,
                            character: firstMember,
                            context: modelContext
                        )
                        collectedMaterials.append(drop)
                    }
                }
                result.materialDrops = collectedMaterials
            }
            
            // Apply secret discovery rewards (gold, materials, equipment)
            if result.secretDiscovery, let leader = party.first {
                if result.secretBonusGold > 0 {
                    leader.gold += result.secretBonusGold
                }
                
                if result.secretBonusMaterials > 0 {
                    let materialTypes: [MaterialType] = [.ore, .crystal, .hide]
                    for _ in 0..<result.secretBonusMaterials {
                        let randomType = materialTypes.randomElement() ?? .ore
                        gameEngine.addMaterialPublic(
                            randomType,
                            rarity: .rare,
                            amount: 1,
                            characterID: leader.id,
                            context: modelContext
                        )
                    }
                }
                
                if result.secretEquipmentDrop {
                    let secretItem = LootGenerator.generateEquipment(
                        tier: dungeon.lootTier + 1,
                        luck: leader.effectiveStats.luck,
                        characterClass: leader.characterClass,
                        playerLevel: leader.level
                    )
                    secretItem.ownerID = leader.id
                    modelContext.insert(secretItem)
                    Task { try? await SupabaseService.shared.syncEquipment(secretItem) }
                    result.lootDrops.append(secretItem)
                }
            }
            
            // Write remaining HP back to character's persistent HP
            if let leadCharacter = party.first {
                leadCharacter.currentHP = max(1, run.partyHP) // Revive to 1 if knocked out
                leadCharacter.lastHPUpdateAt = Date()
            }
            
            // Award Expedition Key from Hard+ dungeons
            if result.success {
                let dropped = GameEngine.rollExpeditionKeyDrop(difficulty: dungeon.difficulty)
                if dropped {
                    ExpeditionKeyStore.add(1)
                }
                
                // Update party challenge progress (dungeons type)
                if let leader = party.first {
                    let bonds = (try? modelContext.fetch(FetchDescriptor<Bond>())) ?? []
                    gameEngine.updateChallengeProgress(
                        type: .dungeons,
                        characterID: leader.id,
                        character: leader,
                        bond: bonds.first,
                        context: modelContext
                    )
                }
                
                // Complete the "Try Your First Dungeon" breadcrumb quest
                party.first?.completeBreadcrumb("tryDungeon")
                
                // Post to party feed
                if let leader = party.first {
                    let bonds = (try? modelContext.fetch(FetchDescriptor<Bond>())) ?? []
                    if let partyID = bonds.first?.supabasePartyID,
                       let actorID = SupabaseService.shared.currentUserID {
                        let dungeonName = dungeon.name
                        let expVal = result.totalExp
                        let goldVal = result.totalGold
                        Task {
                            try? await SupabaseService.shared.postPartyFeedEvent(
                                partyID: partyID,
                                actorID: actorID,
                                eventType: "dungeon_loot",
                                message: "\(leader.name) cleared '\(dungeonName)' (+\(expVal) EXP, +\(goldVal) Gold)",
                                metadata: ["dungeon": dungeonName, "exp": "\(expVal)", "gold": "\(goldVal)"]
                            )
                        }
                    }
                }
            }
            
            if result.success, let leader = party.first,
               let boss = raidBosses.first(where: { $0.isActive }) {
                if let raidResult = gameEngine.dealRaidDamage(
                    character: leader,
                    boss: boss,
                    activityType: .dungeon,
                    activityValue: dungeon.lootTier,
                    sourceLabel: "Dungeon: \(dungeon.name)"
                ) {
                    result.raidDamageDealt = raidResult.damage
                    result.raidRetaliationTaken = raidResult.retaliationDamage
                }
            }
            
            if result.success {
                hapticSuccess += 1
                AudioManager.shared.play(.victoryFanfare, maxDuration: 3.5)
            } else {
                hapticError += 1
                AudioManager.shared.play(.defeatSting, maxDuration: 2.5)
            }
            
            withAnimation(.easeInOut(duration: 0.3)) {
                phase = .results
            }
        }
    }
}

// MARK: - Helper Views

struct SummaryRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            if icon == "gold-coin" {
                GoldCoinIcon(size: 18)
                    .frame(width: 24)
            } else {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 24)
            }
            Text(label)
                .font(.custom("Avenir-Medium", size: 14))
            Spacer()
            Text(value)
                .font(.custom("Avenir-Heavy", size: 16))
                .foregroundColor(color)
        }
    }
}

struct LootDropRow: View {
    let equipment: Equipment
    @State private var showTooltip = false
    
    var body: some View {
        Button {
            showTooltip.toggle()
        } label: {
            HStack(spacing: 12) {
                EquipmentIconView(item: equipment, slot: equipment.slot, size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(equipment.name)
                        .font(.custom("Avenir-Heavy", size: 14))
                        .foregroundColor(Color(equipment.rarity.color))
                        .rarityShimmer(equipment.rarity)
                    Text(equipment.statSummary)
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(equipment.rarity.rawValue)
                    .font(.custom("Avenir-Heavy", size: 10))
                    .foregroundColor(Color(equipment.rarity.color))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color(equipment.rarity.color).opacity(0.2)))
                    .rarityShimmer(equipment.rarity)
            }
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showTooltip) {
            VStack(alignment: .leading, spacing: 8) {
                Text(equipment.name)
                    .font(.custom("Avenir-Heavy", size: 15))
                    .foregroundColor(Color(equipment.rarity.color))
                    .rarityShimmer(equipment.rarity)
                Text(equipment.slot.rawValue.capitalized + " • " + equipment.rarity.rawValue)
                    .font(.custom("Avenir-Medium", size: 12))
                    .foregroundColor(.secondary)
                Divider()
                Text(equipment.itemDescription)
                    .font(.custom("Avenir-Medium", size: 13))
                    .foregroundColor(.primary)
                Text(equipment.statSummary)
                    .font(.custom("Avenir-Heavy", size: 13))
                    .foregroundColor(Color(equipment.primaryStat.color))
                if equipment.levelRequirement > 1 {
                    Text("Requires Level \(equipment.levelRequirement)")
                        .font(.custom("Avenir-Medium", size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(width: 260)
            .presentationCompactAdaptation(.popover)
        }
    }
}

// MARK: - Feed Entry Row

struct FeedEntryRow: View {
    let entry: DungeonFeedEntry
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: entry.icon)
                .font(.system(size: 12))
                .foregroundColor(Color(entry.color))
                .frame(width: 20)
            Text(entry.message)
                .font(.custom("Avenir-Medium", size: 12))
                .foregroundColor(.primary.opacity(0.8))
                .lineLimit(2)
            Spacer()
            Text(entry.timestamp, style: .time)
                .font(.custom("Avenir-Medium", size: 10))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
