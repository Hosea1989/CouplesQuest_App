import SwiftUI
import SwiftData

struct ArenaView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var gameEngine: GameEngine
    @Query private var characters: [PlayerCharacter]
    @Query(sort: \ArenaRun.startedAt, order: .reverse) private var arenaRuns: [ArenaRun]
    
    @State private var showArenaRun = false
    @State private var activeRun: ArenaRun?
    @State private var weeklyModifier: ArenaModifier = .standard
    @State private var selectedDuration: ArenaDuration = .oneHour
    
    private var character: PlayerCharacter? {
        characters.first
    }
    
    private var activeInProgressRun: ArenaRun? {
        arenaRuns.first(where: { $0.status == .inProgress })
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Arena Header
                arenaHeader
                
                // Weekly Modifier Badge
                if weeklyModifier.id != "none" {
                    modifierBadge
                }
                
                // Active Run
                if let run = activeInProgressRun {
                    activeRunCard(run: run)
                }
                
                // Start / Continue
                if activeInProgressRun == nil, let character = character {
                    startSection(character: character)
                }
                
                // Milestone Preview
                milestonePreview
                
                // Personal Records
                recordsSection
                
                // Recent Runs
                recentRunsSection
            }
            .padding(.vertical)
        }
        .fullScreenCover(isPresented: $showArenaRun) {
            if let run = activeRun, let character = character {
                ArenaRunView(run: run, character: character)
            }
        }
        .onAppear {
            loadWeeklyModifier()
        }
    }
    
    // MARK: - Arena Header
    
    private var arenaHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color("AccentGold").opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "trophy.fill")
                    .font(.system(size: 36))
                    .foregroundColor(Color("AccentGold"))
            }
            
            Text("The Arena")
                .font(.custom("Avenir-Heavy", size: 24))
            
            Text("Face infinite waves of escalating combat. How far can you go?")
                .font(.custom("Avenir-Medium", size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Weekly Modifier Badge
    
    private var modifierBadge: some View {
        HStack(spacing: 10) {
            Image(systemName: weeklyModifier.icon)
                .font(.system(size: 16))
                .foregroundColor(Color("AccentPurple"))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("This Week: \(weeklyModifier.name)")
                    .font(.custom("Avenir-Heavy", size: 14))
                    .foregroundColor(Color("AccentPurple"))
                Text(weeklyModifier.modifierDescription)
                    .font(.custom("Avenir-Medium", size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("AccentPurple").opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color("AccentPurple").opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
    
    // MARK: - Active Run Card
    
    @ViewBuilder
    private func activeRunCard(run: ArenaRun) -> some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(Color("AccentGold"))
                        Text("Active Arena Run")
                            .font(.custom("Avenir-Heavy", size: 14))
                            .foregroundColor(Color("AccentGold"))
                    }
                    Text("Wave \(run.currentDisplayWave) of \(run.waveResults.count)")
                        .font(.custom("Avenir-Heavy", size: 20))
                    if run.isTimerComplete {
                        Text("Run complete — tap to view results")
                            .font(.custom("Avenir-Medium", size: 11))
                            .foregroundColor(Color("AccentGreen"))
                    } else {
                        Text(run.timeRemainingFormatted + " remaining")
                            .font(.custom("Avenir-Medium", size: 11))
                            .foregroundColor(Color("AccentGold"))
                    }
                }
                Spacer()
                Text("\(run.displayHP) HP")
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(.red)
            }
            
            // Timer progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color("AccentGold"), Color("AccentOrange")],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * run.timerProgress)
                }
            }
            .frame(height: 8)
            
            Button {
                activeRun = run
                showArenaRun = true
            } label: {
                HStack {
                    Image(systemName: run.isTimerComplete ? "trophy.fill" : "eye.fill")
                    Text(run.isTimerComplete ? "View Results" : "Watch Arena")
                }
                .font(.custom("Avenir-Heavy", size: 14))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color("AccentGold"), Color("AccentOrange")],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal)
    }
    
    // MARK: - Start Section
    
    @ViewBuilder
    private func startSection(character: PlayerCharacter) -> some View {
        let isFree = character.hasFreeArenaAttempt
        
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Enter the Arena")
                        .font(.custom("Avenir-Heavy", size: 18))
                    Text(isFree ? "Free attempt available!" : "Cost: \(ArenaRun.additionalAttemptCost) Gold")
                        .font(.custom("Avenir-Medium", size: 13))
                        .foregroundColor(isFree ? Color("AccentGreen") : .secondary)
                }
                Spacer()
            }
            
            // Duration Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Choose Duration")
                    .font(.custom("Avenir-Heavy", size: 14))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 10) {
                    ForEach(ArenaDuration.allCases) { duration in
                        Button {
                            selectedDuration = duration
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: duration.icon)
                                    .font(.system(size: 18))
                                Text(duration.shortLabel)
                                    .font(.custom("Avenir-Heavy", size: 16))
                                Text(duration.subtitle)
                                    .font(.custom("Avenir-Medium", size: 11))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedDuration == duration ? Color("AccentGold").opacity(0.15) : Color.secondary.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                selectedDuration == duration ? Color("AccentGold") : Color.clear,
                                                lineWidth: 2
                                            )
                                    )
                            )
                            .foregroundColor(selectedDuration == duration ? Color("AccentGold") : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Button {
                startArenaRun(character: character)
            } label: {
                HStack {
                    Image(systemName: "flame.fill")
                    Text("Begin Arena Run")
                }
                .font(.custom("Avenir-Heavy", size: 16))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(colors: [Color("AccentGold"), Color("AccentOrange")], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!isFree && character.gold < ArenaRun.additionalAttemptCost)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
        .padding(.horizontal)
    }
    
    // MARK: - Milestone Preview
    
    private var milestonePreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(Color("AccentGold"))
                Text("Milestone Rewards")
                    .font(.custom("Avenir-Heavy", size: 16))
                Spacer()
            }
            
            let bestWave = character?.arenaBestWave ?? 0
            let milestones: [(wave: Int, label: String)] = [
                (5, "Gold + consumable"),
                (10, "Gold + uncommon consumable"),
                (15, "Gold + rare consumable + card chance"),
                (20, "Gold + guaranteed rare+ equipment"),
                (25, "Gold + epic consumable + card chance"),
            ]
            
            ForEach(milestones, id: \.wave) { milestone in
                HStack(spacing: 10) {
                    Image(systemName: bestWave >= milestone.wave ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(bestWave >= milestone.wave ? Color("AccentGreen") : .secondary.opacity(0.4))
                        .font(.system(size: 14))
                    
                    Text("Wave \(milestone.wave)")
                        .font(.custom("Avenir-Heavy", size: 13))
                        .foregroundColor(bestWave >= milestone.wave ? .primary : .secondary)
                        .frame(width: 60, alignment: .leading)
                    
                    Text(milestone.label)
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            
            Text("+ escalating rewards every 10 waves after 25")
                .font(.custom("Avenir-Medium", size: 11))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
        .padding(.horizontal)
    }
    
    // MARK: - Records
    
    private var recordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personal Records")
                .font(.custom("Avenir-Heavy", size: 18))
            
            HStack(spacing: 16) {
                recordStat(icon: "trophy.fill", label: "Best Wave", value: "\(character?.arenaBestWave ?? 0)", color: "AccentGold")
                recordStat(icon: "flame.fill", label: "Total Runs", value: "\(arenaRuns.count)", color: "DifficultyHard")
                recordStat(icon: "bolt.fill", label: "Avg Wave", value: avgWave, color: "AccentPurple")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
        .padding(.horizontal)
    }
    
    private var avgWave: String {
        let completed = arenaRuns.filter { $0.status != .inProgress }
        guard !completed.isEmpty else { return "—" }
        let total = completed.reduce(0) { $0 + $1.maxWaveReached }
        return "\(total / completed.count)"
    }
    
    @ViewBuilder
    private func recordStat(icon: String, label: String, value: String, color: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color(color))
            Text(value)
                .font(.custom("Avenir-Heavy", size: 18))
            Text(label)
                .font(.custom("Avenir-Medium", size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Recent Runs
    
    @ViewBuilder
    private var recentRunsSection: some View {
        if !arenaRuns.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Runs")
                    .font(.custom("Avenir-Heavy", size: 18))
                
                ForEach(arenaRuns.prefix(5)) { run in
                    HStack {
                        Image(systemName: run.status == .completed ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(run.status == .completed ? Color("AccentGreen") : Color("DifficultyHard"))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Wave \(run.maxWaveReached)")
                                .font(.custom("Avenir-Heavy", size: 14))
                            Text(run.startedAt, style: .relative)
                                .font(.custom("Avenir-Medium", size: 11))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("+\(run.totalExpEarned) EXP")
                                .font(.custom("Avenir-Heavy", size: 12))
                                .foregroundColor(Color("AccentGold"))
                            Text("+\(run.totalGoldEarned) Gold")
                                .font(.custom("Avenir-Medium", size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("CardBackground"))
            )
            .padding(.horizontal)
        }
    }
    
    // MARK: - Actions
    
    private func startArenaRun(character: PlayerCharacter) {
        character.checkArenaReset()
        
        if !character.hasFreeArenaAttempt {
            guard character.gold >= ArenaRun.additionalAttemptCost else { return }
            character.gold -= ArenaRun.additionalAttemptCost
        }
        
        character.arenaAttemptsToday += 1
        character.lastArenaDate = Date()
        
        let run = ArenaRun(characterID: character.id, characterHP: character.currentHP, characterMaxHP: character.maxHP, duration: selectedDuration, modifier: weeklyModifier)
        
        // Pre-simulate all waves immediately
        ArenaRun.autoResolveArena(run: run, character: character)
        
        // Collect cards from arena milestones that have card drop chances
        let cardPool = ContentManager.shared.activeCardPool
        for milestone in run.milestoneRewards where milestone.cardDropChance > 0 {
            if Double.random(in: 0...1) <= milestone.cardDropChance {
                if let contentCard = CardDropEngine.rollArenaCardDrop(
                    waveNumber: milestone.wave,
                    cardPool: cardPool
                ) {
                    _ = CardDropEngine.collectCard(
                        contentCard: contentCard,
                        character: character,
                        context: modelContext
                    )
                }
            }
        }
        
        // Write remaining HP back to character's persistent HP (revive to 1 if knocked out)
        character.currentHP = max(1, run.currentHP)
        character.lastHPUpdateAt = Date()
        
        modelContext.insert(run)
        activeRun = run
        
        AudioManager.shared.play(.dungeonStart)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showArenaRun = true
        }
    }
    
    private func loadWeeklyModifier() {
        // TODO: Load from ContentManager when available
        // For now, use standard modifier as fallback
        weeklyModifier = .standard
    }
}

// MARK: - Arena Run View (Full Screen AFK)

struct ArenaRunView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var gameEngine: GameEngine
    
    let run: ArenaRun
    let character: PlayerCharacter
    
    @State private var phase: RunPhase = .waiting
    @State private var animateIcon = false
    @State private var timerTick = 0
    @State private var showFullLog = false
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    enum RunPhase {
        case waiting    // AFK timer countdown with live feed
        case results    // Show final summary
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color("BackgroundTop"), Color("BackgroundBottom")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            switch phase {
            case .waiting:
                waitingContent
            case .results:
                resultsContent
            }
        }
        .onReceive(timer) { _ in
            timerTick += 1
            if phase == .waiting && run.isTimerComplete {
                withAnimation(.easeInOut(duration: 0.3)) {
                    phase = .results
                }
                // Play completion audio
                if run.status == .completed {
                    AudioManager.shared.play(.dungeonComplete)
                } else {
                    AudioManager.shared.play(.error)
                }
            }
        }
        .onAppear {
            if run.isTimerComplete {
                phase = .results
            } else {
                phase = .waiting
            }
        }
    }
    
    // MARK: - Waiting Content (AFK Countdown + Live Feed)
    
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
            
            ScrollView {
                VStack(spacing: 24) {
                    // Arena icon with progress ring
                    ZStack {
                        Circle()
                            .stroke(Color.secondary.opacity(0.15), lineWidth: 8)
                            .frame(width: 140, height: 140)
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
                            .frame(width: 140, height: 140)
                            .rotationEffect(.degrees(-90))
                        
                        Circle()
                            .fill(Color("AccentGold").opacity(0.1))
                            .frame(width: 110, height: 110)
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 40))
                            .foregroundColor(Color("AccentGold"))
                            .scaleEffect(animateIcon ? 1.05 : 0.95)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateIcon)
                    }
                    .onAppear { animateIcon = true }
                    
                    Text("The Arena")
                        .font(.custom("Avenir-Heavy", size: 24))
                    
                    Text("Your champion is fighting...")
                        .font(.custom("Avenir-Medium", size: 16))
                        .foregroundColor(.secondary)
                    
                    // Timer countdown
                    let _ = timerTick
                    Text(run.timeRemainingFormatted)
                        .font(.system(size: 40, weight: .bold, design: .monospaced))
                        .foregroundColor(Color("AccentGold"))
                    
                    Text("remaining")
                        .font(.custom("Avenir-Medium", size: 14))
                        .foregroundColor(.secondary)
                    
                    // Wave progress + HP
                    HStack(spacing: 20) {
                        VStack(spacing: 4) {
                            Text("Wave")
                                .font(.custom("Avenir-Medium", size: 12))
                                .foregroundColor(.secondary)
                            Text("\(run.currentDisplayWave)/\(run.waveResults.count)")
                                .font(.custom("Avenir-Heavy", size: 20))
                        }
                        
                        VStack(spacing: 4) {
                            Text("HP")
                                .font(.custom("Avenir-Medium", size: 12))
                                .foregroundColor(.secondary)
                            Text("\(run.displayHP)/\(run.maxHP)")
                                .font(.custom("Avenir-Heavy", size: 20))
                                .foregroundColor(.red)
                        }
                        
                        VStack(spacing: 4) {
                            Text("Duration")
                                .font(.custom("Avenir-Medium", size: 12))
                                .foregroundColor(.secondary)
                            Text(run.durationTier.shortLabel)
                                .font(.custom("Avenir-Heavy", size: 20))
                        }
                    }
                    .padding(.horizontal)
                    
                    // HP Bar
                    HStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 12))
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.secondary.opacity(0.2))
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(run.displayHPPercentage > 0.3 ? Color.red : Color.red.opacity(0.5))
                                    .frame(width: geometry.size.width * run.displayHPPercentage)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(.horizontal, 32)
                    
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
                    
                    // Info text
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.secondary)
                        Text("You can close this screen and come back later.")
                            .font(.custom("Avenir-Medium", size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                    
                    // Live wave feed
                    liveFeedSection
                }
                .padding(.vertical)
            }
        }
    }
    
    // MARK: - Live Feed Section
    
    private var liveFeedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "text.book.closed.fill")
                    .foregroundColor(Color("AccentGold"))
                Text("Battle Log")
                    .font(.custom("Avenir-Heavy", size: 16))
                Spacer()
                let visible = run.visibleWaveResults
                Text("\(visible.count) of \(run.waveResults.count) waves")
                    .font(.custom("Avenir-Medium", size: 12))
                    .foregroundColor(.secondary)
            }
            
            let visible = run.visibleWaveResults
            if visible.isEmpty {
                HStack {
                    ProgressView()
                        .tint(Color("AccentGold"))
                    Text("Preparing for Wave 1...")
                        .font(.custom("Avenir-Medium", size: 13))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            } else {
                ForEach(Array(visible.reversed().enumerated()), id: \.element.id) { _, result in
                    waveResultRow(result: result)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
        .padding(.horizontal)
    }
    
    // MARK: - Wave Result Row (for feed)
    
    private func waveResultRow(result: ArenaWaveResult) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(result.success ? Color("AccentGreen").opacity(0.2) : Color("DifficultyHard").opacity(0.2))
                        .frame(width: 28, height: 28)
                    Text("\(result.wave)")
                        .font(.custom("Avenir-Heavy", size: 12))
                        .foregroundColor(result.success ? Color("AccentGreen") : Color("DifficultyHard"))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Wave \(result.wave)")
                            .font(.custom("Avenir-Heavy", size: 13))
                        Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(result.success ? Color("AccentGreen") : Color("DifficultyHard"))
                        if result.isMilestoneWave {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(Color("AccentGold"))
                        }
                    }
                    if !result.approachName.isEmpty {
                        Text(result.approachName)
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
                .font(.custom("Avenir-Medium", size: 11))
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Results Content (Final Summary)
    
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
                    // Result Header
                    resultHeader
                    
                    // Summary Card
                    summaryCard
                    
                    // Milestones
                    if !run.milestoneRewards.isEmpty {
                        milestonesCard
                    }
                    
                    // Wave-by-Wave Log
                    waveLogCard
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
    
    private var resultHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [(run.status == .completed ? Color("AccentGold") : Color.red).opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                Image(systemName: run.status == .completed ? "trophy.fill" : "shield.slash.fill")
                    .font(.system(size: 80))
                    .foregroundColor(run.status == .completed ? Color("AccentGold") : .red)
                    .symbolEffect(.bounce)
            }
            
            Text(run.status == .completed ? "Arena Conquered!" : "Defeated at Wave \(run.maxWaveReached)")
                .font(.custom("Avenir-Heavy", size: 28))
            
            Text(run.status == .completed
                 ? "You survived all \(run.maxWaves) waves!"
                 : "Your champion fell after reaching wave \(run.maxWaveReached).")
                .font(.custom("Avenir-Medium", size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Summary Card
    
    private var summaryCard: some View {
        VStack(spacing: 16) {
            SummaryRow(icon: "trophy.fill", label: "Waves Cleared", value: "\(run.waveResults.filter { $0.success }.count)/\(run.waveResults.count)", color: Color("AccentGold"))
            SummaryRow(icon: "heart.fill", label: "HP Remaining", value: "\(run.currentHP)/\(run.maxHP)", color: .red)
            
            Divider()
            
            SummaryRow(icon: "sparkles", label: "Total EXP", value: "+\(run.totalExpEarned)", color: Color("AccentGold"))
            SummaryRow(icon: "dollarsign.circle.fill", label: "Total Gold", value: "+\(run.totalGoldEarned)", color: Color("AccentGold"))
            
            if !run.milestoneRewards.isEmpty {
                SummaryRow(icon: "star.fill", label: "Milestones", value: "\(run.milestoneRewards.count) reached", color: Color("AccentPurple"))
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color("CardBackground")))
    }
    
    // MARK: - Milestones Card
    
    private var milestonesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(Color("AccentGold"))
                Text("Milestones Reached")
                    .font(.custom("Avenir-Heavy", size: 16))
                Spacer()
            }
            
            ForEach(run.milestoneRewards) { milestone in
                HStack(spacing: 10) {
                    Image(systemName: "star.circle.fill")
                        .foregroundColor(Color("AccentGold"))
                        .font(.system(size: 14))
                    
                    Text("Wave \(milestone.wave)")
                        .font(.custom("Avenir-Heavy", size: 13))
                        .frame(width: 60, alignment: .leading)
                    
                    Text("+\(milestone.goldReward) Gold")
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(milestone.consumableRarity.capitalized)
                        .font(.custom("Avenir-Heavy", size: 10))
                        .foregroundColor(Color("AccentPurple"))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color("AccentPurple").opacity(0.15)))
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color("CardBackground")))
    }
    
    // MARK: - Wave Log Card
    
    private var waveLogCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showFullLog.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "scroll.fill")
                        .foregroundColor(Color("AccentGold"))
                    Text("Wave-by-Wave")
                        .font(.custom("Avenir-Heavy", size: 16))
                    Spacer()
                    Text("\(run.waveResults.count) waves")
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                    Image(systemName: showFullLog ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            if showFullLog {
                ForEach(run.waveResults) { result in
                    waveResultRow(result: result)
                    if result.id != run.waveResults.last?.id {
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
}

#Preview {
    ArenaView()
        .environmentObject(GameEngine())
}
