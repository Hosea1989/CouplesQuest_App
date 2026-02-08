import SwiftUI
import SwiftData

struct ArenaView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var gameEngine: GameEngine
    @Query private var characters: [PlayerCharacter]
    @Query(sort: \ArenaRun.startedAt, order: .reverse) private var arenaRuns: [ArenaRun]
    
    @State private var showArenaRun = false
    @State private var activeRun: ArenaRun?
    
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
                
                // Active Run
                if let run = activeInProgressRun {
                    activeRunCard(run: run)
                }
                
                // Start / Continue
                if activeInProgressRun == nil, let character = character {
                    startSection(character: character)
                }
                
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
            
            Text("Face 10 waves of escalating combat. How far can you go?")
                .font(.custom("Avenir-Medium", size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
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
                    Text("Wave \(run.currentWave)/\(ArenaRun.maxWaves)")
                        .font(.custom("Avenir-Heavy", size: 20))
                }
                Spacer()
                Text("\(run.currentHP) HP")
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(.red)
            }
            
            // HP Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(run.hpPercentage > 0.3 ? Color.red : Color.red.opacity(0.5))
                        .frame(width: geometry.size.width * run.hpPercentage)
                }
            }
            .frame(height: 8)
            
            Button {
                activeRun = run
                showArenaRun = true
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Continue Arena")
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
        
        VStack(spacing: 12) {
            
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
    
    // MARK: - Records
    
    private var recordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personal Records")
                .font(.custom("Avenir-Heavy", size: 18))
            
            HStack(spacing: 16) {
                recordStat(icon: "trophy.fill", label: "Best Wave", value: "\(character?.arenaBestWave ?? 0)/\(ArenaRun.maxWaves)", color: "AccentGold")
                recordStat(icon: "flame.fill", label: "Total Runs", value: "\(arenaRuns.count)", color: "DifficultyHard")
                recordStat(icon: "checkmark.circle.fill", label: "Wins", value: "\(arenaRuns.filter { $0.status == .completed }.count)", color: "AccentGreen")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
        .padding(.horizontal)
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
                            Text("Wave \(run.maxWaveReached)/\(ArenaRun.maxWaves)")
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
        
        let run = ArenaRun(characterID: character.id)
        modelContext.insert(run)
        activeRun = run
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showArenaRun = true
        }
    }
}

// MARK: - Arena Run View (Full Screen)

struct ArenaRunView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var gameEngine: GameEngine
    
    let run: ArenaRun
    let character: PlayerCharacter
    
    @State private var currentRoom: DungeonRoom?
    @State private var selectedApproach: RoomApproach?
    @State private var waveResult: ArenaWaveResult?
    @State private var showResult = false
    @State private var isComplete = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color("BackgroundTop"), Color("BackgroundBottom")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if isComplete {
                    completionContent
                } else if showResult, let result = waveResult {
                    resultContent(result: result)
                } else {
                    waveContent
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Flee") {
                        run.status = .failed
                        run.completedAt = Date()
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
                ToolbarItem(placement: .principal) {
                    Text("Wave \(run.currentWave)/\(ArenaRun.maxWaves)")
                        .font(.custom("Avenir-Heavy", size: 16))
                }
            }
            .onAppear {
                currentRoom = ArenaRun.waveRoom(wave: run.currentWave)
            }
        }
    }
    
    // MARK: - Wave Content
    
    private var waveContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // HP Bar
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4).fill(Color.secondary.opacity(0.2))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(run.hpPercentage > 0.3 ? Color.red : Color.red.opacity(0.5))
                                .frame(width: geometry.size.width * run.hpPercentage)
                        }
                    }
                    .frame(height: 8)
                    Text("\(run.currentHP)/\(run.maxHP)")
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                if let room = currentRoom {
                    // Enemy Card
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(room.encounterType.color).opacity(0.2))
                                .frame(width: 80, height: 80)
                            Image(systemName: room.encounterType.icon)
                                .font(.system(size: 36))
                                .foregroundColor(Color(room.encounterType.color))
                        }
                        
                        Text(room.name)
                            .font(.custom("Avenir-Heavy", size: 22))
                        
                        Text(room.roomDescription)
                            .font(.custom("Avenir-Medium", size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        if room.isBossRoom {
                            Text("BOSS WAVE")
                                .font(.custom("Avenir-Heavy", size: 12))
                                .foregroundColor(Color("RarityEpic"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color("RarityEpic").opacity(0.2)))
                        }
                    }
                    .padding(.horizontal)
                    
                    // Approach Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Choose Your Approach")
                            .font(.custom("Avenir-Heavy", size: 16))
                            .padding(.horizontal)
                        
                        ForEach(room.encounterType.approaches) { approach in
                            Button {
                                selectedApproach = approach
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: approach.icon)
                                        .font(.title3)
                                        .foregroundColor(Color(approach.primaryStat.color))
                                        .frame(width: 36)
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(approach.name)
                                            .font(.custom("Avenir-Heavy", size: 14))
                                        Text(approach.approachDescription)
                                            .font(.custom("Avenir-Medium", size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(approach.riskLabel)
                                        .font(.custom("Avenir-Heavy", size: 11))
                                        .foregroundColor(Color(approach.riskColor))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Capsule().fill(Color(approach.riskColor).opacity(0.15)))
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color("CardBackground"))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(
                                                    selectedApproach?.id == approach.id ?
                                                    Color("AccentGold") : Color.clear,
                                                    lineWidth: 2
                                                )
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                        }
                    }
                    
                    // Fight Button
                    Button {
                        resolveWave(room: room)
                    } label: {
                        HStack {
                            Image(systemName: "bolt.fill")
                            Text("Fight!")
                        }
                        .font(.custom("Avenir-Heavy", size: 18))
                        .foregroundColor(selectedApproach != nil ? .black : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            selectedApproach != nil ?
                            LinearGradient(colors: [Color("AccentGold"), Color("AccentOrange")], startPoint: .leading, endPoint: .trailing) :
                            LinearGradient(colors: [Color.gray, Color.gray], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(selectedApproach == nil)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Result Content
    
    @ViewBuilder
    private func resultContent(result: ArenaWaveResult) -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(result.success ? Color("AccentGreen").opacity(0.2) : Color("DifficultyHard").opacity(0.2))
                    .frame(width: 100, height: 100)
                Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(result.success ? Color("AccentGreen") : Color("DifficultyHard"))
            }
            
            Text(result.success ? "Wave Cleared!" : "Defeated!")
                .font(.custom("Avenir-Heavy", size: 28))
            
            Text(result.narrativeText)
                .font(.custom("Avenir-Medium", size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            if result.success {
                HStack(spacing: 20) {
                    VStack {
                        Text("+\(result.expEarned)")
                            .font(.custom("Avenir-Heavy", size: 20))
                            .foregroundColor(Color("AccentGold"))
                        Text("EXP")
                            .font(.custom("Avenir-Medium", size: 12))
                            .foregroundColor(.secondary)
                    }
                    VStack {
                        Text("+\(result.goldEarned)")
                            .font(.custom("Avenir-Heavy", size: 20))
                        Text("Gold")
                            .font(.custom("Avenir-Medium", size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Button {
                if result.success {
                    advanceWave()
                } else {
                    finishRun()
                }
            } label: {
                Text(result.success ? "Next Wave" : "Leave Arena")
                    .font(.custom("Avenir-Heavy", size: 18))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(colors: [Color("AccentGold"), Color("AccentOrange")], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
    
    // MARK: - Completion Content
    
    private var completionContent: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "trophy.fill")
                .font(.system(size: 60))
                .foregroundColor(Color("AccentGold"))
            
            Text("Arena Complete!")
                .font(.custom("Avenir-Heavy", size: 28))
            
            Text("You conquered all \(ArenaRun.maxWaves) waves!")
                .font(.custom("Avenir-Medium", size: 16))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("+\(run.totalExpEarned) EXP")
                    .font(.custom("Avenir-Heavy", size: 20))
                    .foregroundColor(Color("AccentGold"))
                Text("+\(run.totalGoldEarned) Gold")
                    .font(.custom("Avenir-Medium", size: 16))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Text("Return to Adventures")
                    .font(.custom("Avenir-Heavy", size: 18))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(colors: [Color("AccentGold"), Color("AccentOrange")], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
    
    // MARK: - Actions
    
    private func resolveWave(room: DungeonRoom) {
        let approach = selectedApproach
        let power = DungeonEngine.calculatePartyPower(party: [character], room: room, statOverride: approach?.primaryStat)
        let modifiedPower = Int(Double(power) * (approach?.powerModifier ?? 1.0))
        let difficulty = room.difficultyRating
        let successChance = DungeonEngine.calculateSuccessChance(party: [character], room: room, approach: approach)
        
        let roll = Double.random(in: 0...1)
        let success = roll <= successChance
        
        var expEarned = 0
        var goldEarned = 0
        var hpLost = 0
        
        if success {
            expEarned = ArenaRun.expReward(wave: run.currentWave)
            goldEarned = ArenaRun.goldReward(wave: run.currentWave)
            
            // Risky approach bonus
            if let approach = approach, approach.powerModifier > 1.1 {
                let bonus = 1.0 + (approach.powerModifier - 1.0) * 0.5
                expEarned = Int(Double(expEarned) * bonus)
                goldEarned = Int(Double(goldEarned) * bonus)
            }
            
            character.gainEXP(expEarned)
            character.gold += goldEarned
            run.totalExpEarned += expEarned
            run.totalGoldEarned += goldEarned
        } else {
            let baseDamage = max(5, min(25, difficulty - modifiedPower))
            let riskMultiplier = approach?.riskModifier ?? 1.0
            hpLost = Int(Double(baseDamage) * riskMultiplier)
            run.currentHP = max(0, run.currentHP - hpLost)
        }
        
        let narratives = success ? room.encounterType.successNarratives : room.encounterType.failureNarratives
        let narrative = narratives.randomElement() ?? (success ? "Success!" : "Failed!")
        
        let result = ArenaWaveResult(
            wave: run.currentWave,
            success: success,
            playerPower: modifiedPower,
            requiredPower: difficulty,
            expEarned: expEarned,
            goldEarned: goldEarned,
            hpLost: hpLost,
            narrativeText: narrative,
            approachName: approach?.name ?? ""
        )
        
        run.waveResults.append(result)
        run.maxWaveReached = max(run.maxWaveReached, run.currentWave)
        
        if !success && run.currentHP <= 0 {
            run.status = .failed
            run.completedAt = Date()
            character.arenaBestWave = max(character.arenaBestWave, run.maxWaveReached)
        }
        
        waveResult = result
        withAnimation {
            showResult = true
        }
    }
    
    private func advanceWave() {
        if run.currentWave >= ArenaRun.maxWaves {
            run.status = .completed
            run.completedAt = Date()
            character.arenaBestWave = max(character.arenaBestWave, run.maxWaveReached)
            withAnimation {
                isComplete = true
                showResult = false
            }
        } else {
            run.currentWave += 1
            selectedApproach = nil
            waveResult = nil
            currentRoom = ArenaRun.waveRoom(wave: run.currentWave)
            withAnimation {
                showResult = false
            }
        }
    }
    
    private func finishRun() {
        character.arenaBestWave = max(character.arenaBestWave, run.maxWaveReached)
        dismiss()
    }
}

#Preview {
    ArenaView()
        .environmentObject(GameEngine())
}
