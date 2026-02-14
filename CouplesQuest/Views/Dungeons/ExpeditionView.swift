import SwiftUI
import SwiftData

// MARK: - Expedition View

struct ExpeditionView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var gameEngine: GameEngine
    @Query private var characters: [PlayerCharacter]
    
    @State private var availableExpeditions: [Expedition] = []
    @State private var activeExpedition: ActiveExpedition? = nil
    @State private var showLaunchConfirm = false
    @State private var selectedExpedition: Expedition? = nil
    @State private var showStageResults = false
    @State private var latestStageResult: StageResult? = nil
    @State private var showFinalRewards = false
    @State private var expeditionTimer: Timer? = nil
    @State private var timerTick = 0
    
    private var character: PlayerCharacter? {
        characters.first
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
            
            if let character = character {
                ScrollView {
                    VStack(spacing: 24) {
                        if let active = activeExpedition {
                            // Active expedition — show progress
                            activeExpeditionCard(active: active, character: character)
                            stageProgressList(active: active)
                            narrativeLogCard(active: active)
                        } else {
                            // No active expedition — show available
                            expeditionKeyCard
                            availableExpeditionsList(character: character)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
            } else {
                noCharacterPlaceholder
            }
        }
        .onAppear {
            loadExpeditions()
            activeExpedition = ActiveExpedition.loadPersisted()
            startTimer()
        }
        .onDisappear {
            expeditionTimer?.invalidate()
        }
        .confirmationDialog(
            "Launch Expedition",
            isPresented: $showLaunchConfirm,
            titleVisibility: .visible
        ) {
            if let expedition = selectedExpedition {
                Button("Launch (\(expedition.totalDurationFormatted))") {
                    launchExpedition(expedition)
                }
                Button("Cancel", role: .cancel) {}
            }
        } message: {
            if let expedition = selectedExpedition {
                Text("This will use 1 Expedition Key and take \(expedition.totalDurationFormatted). You'll receive push notifications as each stage completes.")
            }
        }
        .sheet(isPresented: $showStageResults) {
            if let result = latestStageResult, let active = activeExpedition {
                stageResultSheet(result: result, active: active)
            }
        }
        .sheet(isPresented: $showFinalRewards) {
            if let active = activeExpedition {
                finalRewardsSheet(active: active)
            }
        }
    }
    
    // MARK: - Expedition Key Card
    
    private var expeditionKeyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "key.fill")
                    .foregroundColor(Color("AccentGold"))
                Text("Expedition Keys")
                    .font(.custom("Avenir-Heavy", size: 16))
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color("AccentGold"))
                    Text("\(ExpeditionKeyStore.count)")
                        .font(.custom("Avenir-Heavy", size: 18))
                        .foregroundColor(Color("AccentGold"))
                }
            }
            
            Text("Expedition Keys drop from Hard+ dungeon completions. Each expedition requires 1 key to launch.")
                .font(.custom("Avenir-Medium", size: 13))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color("CardBackground"))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Available Expeditions List
    
    @ViewBuilder
    private func availableExpeditionsList(character: PlayerCharacter) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "compass.drawing")
                    .foregroundColor(Color("AccentGold"))
                Text("Available Expeditions")
                    .font(.custom("Avenir-Heavy", size: 18))
                Spacer()
            }
            
            if availableExpeditions.isEmpty {
                emptyExpeditionsCard
            } else {
                ForEach(availableExpeditions) { expedition in
                    expeditionTemplateCard(
                        expedition: expedition,
                        character: character
                    )
                }
            }
        }
    }
    
    private var emptyExpeditionsCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "map.fill")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.4))
            Text("No expeditions available")
                .font(.custom("Avenir-Heavy", size: 16))
                .foregroundColor(.secondary)
            Text("Check back later — the expedition pool rotates regularly.")
                .font(.custom("Avenir-Medium", size: 13))
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color("CardBackground"))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Expedition Template Card
    
    @ViewBuilder
    private func expeditionTemplateCard(expedition: Expedition, character: PlayerCharacter) -> some View {
        let meetsReqs = expedition.meetsRequirements(character: character)
        let hasKey = ExpeditionKeyStore.count > 0
        let canLaunch = meetsReqs && hasKey
        
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color(expedition.theme.color).opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: expedition.theme.icon)
                        .font(.system(size: 18))
                        .foregroundColor(Color(expedition.theme.color))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(expedition.name)
                        .font(.custom("Avenir-Heavy", size: 16))
                    HStack(spacing: 8) {
                        Label("\(expedition.stageCount) stages", systemImage: "flag.fill")
                            .font(.custom("Avenir-Medium", size: 12))
                            .foregroundColor(.secondary)
                        Label(expedition.totalDurationFormatted, systemImage: "clock.fill")
                            .font(.custom("Avenir-Medium", size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Level badge
                Text("Lv.\(expedition.levelRequirement)")
                    .font(.custom("Avenir-Heavy", size: 12))
                    .foregroundColor(meetsReqs ? Color("AccentGold") : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill((meetsReqs ? Color("AccentGold") : Color.secondary).opacity(0.15))
                    )
            }
            
            // Description
            Text(expedition.description)
                .font(.custom("Avenir-Medium", size: 13))
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Stat requirements
            if !expedition.statRequirements.isEmpty {
                HStack(spacing: 8) {
                    ForEach(expedition.statRequirements, id: \.stat) { req in
                        let charStat = character.effectiveStats.value(for: req.stat)
                        let met = charStat >= req.minimum
                        HStack(spacing: 3) {
                            Image(systemName: req.stat.icon)
                                .font(.system(size: 10))
                            Text("\(req.stat.rawValue) \(req.minimum)")
                                .font(.custom("Avenir-Medium", size: 11))
                        }
                        .foregroundColor(met ? Color("AccentGreen") : Color("AccentOrange"))
                    }
                    Spacer()
                }
            }
            
            // Stage preview
            HStack(spacing: 4) {
                ForEach(0..<expedition.stageCount, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(expedition.theme.color).opacity(0.3 + Double(i) * 0.15))
                        .frame(height: 6)
                }
            }
            
            // Party badge
            if expedition.isPartyExpedition {
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 11))
                    Text("Party Expedition — combined stats")
                        .font(.custom("Avenir-Medium", size: 12))
                }
                .foregroundColor(Color("AccentPink"))
            }
            
            // Launch button
            Button {
                selectedExpedition = expedition
                showLaunchConfirm = true
            } label: {
                HStack {
                    Image(systemName: "paperplane.fill")
                    Text(canLaunch ? "Launch Expedition" : (!hasKey ? "No Keys" : "Requirements Not Met"))
                }
                .font(.custom("Avenir-Heavy", size: 15))
                .foregroundColor(canLaunch ? .black : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    canLaunch
                        ? LinearGradient(colors: [Color("AccentGold"), Color("AccentOrange")], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [Color.secondary.opacity(0.2), Color.secondary.opacity(0.2)], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(!canLaunch)
        }
        .padding(16)
        .background(Color("CardBackground"))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Active Expedition Card
    
    @ViewBuilder
    private func activeExpeditionCard(active: ActiveExpedition, character: PlayerCharacter) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color(active.expeditionTheme.color).opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: active.expeditionTheme.icon)
                        .font(.system(size: 20))
                        .foregroundColor(Color(active.expeditionTheme.color))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(active.expeditionName)
                        .font(.custom("Avenir-Heavy", size: 18))
                    Text(active.isFullyComplete ? "Expedition Complete!" : "Stage \(active.completedStageCount + 1) of \(active.totalStages): \(active.currentStageName)")
                        .font(.custom("Avenir-Medium", size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Overall progress bar
            VStack(spacing: 6) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.secondary.opacity(0.15))
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [Color(active.expeditionTheme.color), Color("AccentGold")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * active.overallProgress)
                            .animation(.easeInOut(duration: 0.3), value: active.overallProgress)
                    }
                }
                .frame(height: 10)
                
                HStack {
                    Text("\(active.completedStageCount)/\(active.totalStages) stages complete")
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(active.overallProgress * 100))%")
                        .font(.custom("Avenir-Heavy", size: 12))
                        .foregroundColor(Color(active.expeditionTheme.color))
                }
            }
            
            // Current stage timer or completion button
            if active.isFullyComplete {
                // Claim rewards button
                Button {
                    showFinalRewards = true
                } label: {
                    HStack {
                        Image(systemName: "gift.fill")
                        Text("Claim Expedition Rewards")
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
            } else if active.isCurrentStageComplete {
                // Stage ready to resolve
                Button {
                    resolveCurrentStage(active: active, character: character)
                } label: {
                    HStack {
                        Image(systemName: "flag.checkered")
                        Text("Resolve Stage: \(active.currentStageName)")
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
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            } else {
                // Timer for current stage
                HStack {
                    Image(systemName: "hourglass")
                        .foregroundColor(Color(active.expeditionTheme.color))
                    Text("Next stage completes in:")
                        .font(.custom("Avenir-Medium", size: 14))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(active.timeRemainingFormatted)
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(Color(active.expeditionTheme.color))
                        .monospacedDigit()
                }
                
                // Current stage progress
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.1))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(active.expeditionTheme.color).opacity(0.5))
                            .frame(width: geometry.size.width * active.currentStageProgress)
                    }
                }
                .frame(height: 6)
            }
            
            // Running totals
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color("AccentPurple"))
                    Text("+\(active.totalEXPEarned) EXP")
                        .font(.custom("Avenir-Heavy", size: 13))
                        .foregroundColor(Color("AccentPurple"))
                }
                HStack(spacing: 4) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color("AccentGold"))
                    Text("+\(active.totalGoldEarned) Gold")
                        .font(.custom("Avenir-Heavy", size: 13))
                        .foregroundColor(Color("AccentGold"))
                }
                if !active.equipmentDropped.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color("AccentOrange"))
                        Text("\(active.equipmentDropped.count) loot")
                            .font(.custom("Avenir-Heavy", size: 13))
                            .foregroundColor(Color("AccentOrange"))
                    }
                }
                Spacer()
            }
        }
        .padding(16)
        .background(Color("CardBackground"))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Stage Progress List
    
    @ViewBuilder
    private func stageProgressList(active: ActiveExpedition) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet")
                    .foregroundColor(Color("AccentGold"))
                Text("Stage Progress")
                    .font(.custom("Avenir-Heavy", size: 16))
                Spacer()
            }
            
            ForEach(0..<active.totalStages, id: \.self) { index in
                HStack(spacing: 12) {
                    // Status icon
                    ZStack {
                        Circle()
                            .fill(stageStatusColor(for: index, active: active).opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: stageStatusIcon(for: index, active: active))
                            .font(.system(size: 14))
                            .foregroundColor(stageStatusColor(for: index, active: active))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(active.stageNames[index])
                            .font(.custom("Avenir-Heavy", size: 14))
                            .foregroundColor(index <= active.completedStageCount ? .primary : .secondary)
                        
                        if index < active.stageResults.count {
                            let result = active.stageResults[index]
                            Text(result.success ? "+\(result.earnedEXP) EXP, +\(result.earnedGold) Gold" : "Reduced rewards")
                                .font(.custom("Avenir-Medium", size: 11))
                                .foregroundColor(result.success ? Color("AccentGreen") : Color("AccentOrange"))
                        } else if index == active.currentStageIndex && !active.isFullyComplete {
                            Text("In progress...")
                                .font(.custom("Avenir-Medium", size: 11))
                                .foregroundColor(Color(active.expeditionTheme.color))
                        } else {
                            Text("Pending")
                                .font(.custom("Avenir-Medium", size: 11))
                                .foregroundColor(.secondary.opacity(0.5))
                        }
                    }
                    
                    Spacer()
                    
                    // Loot indicators
                    if index < active.stageResults.count {
                        let result = active.stageResults[index]
                        HStack(spacing: 4) {
                            if result.lootDroppedName != nil {
                                Image(systemName: "shield.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color("AccentOrange"))
                            }
                            if result.materialDropped {
                                Image(systemName: "cube.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color("AccentPurple"))
                            }
                            if result.cardDropped {
                                Image(systemName: "rectangle.portrait.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color("AccentGreen"))
                            }
                        }
                    }
                }
                
                if index < active.totalStages - 1 {
                    // Connector line
                    HStack {
                        Rectangle()
                            .fill(index < active.completedStageCount ? Color(active.expeditionTheme.color).opacity(0.3) : Color.secondary.opacity(0.1))
                            .frame(width: 2, height: 12)
                            .padding(.leading, 15)
                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .background(Color("CardBackground"))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Narrative Log Card
    
    @ViewBuilder
    private func narrativeLogCard(active: ActiveExpedition) -> some View {
        if !active.stageResults.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "book.fill")
                        .foregroundColor(Color("AccentGold"))
                    Text("Expedition Log")
                        .font(.custom("Avenir-Heavy", size: 16))
                    Spacer()
                }
                
                ForEach(active.stageResults) { result in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: result.success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(result.success ? Color("AccentGreen") : Color("AccentOrange"))
                            Text("Stage \(result.stageIndex + 1)")
                                .font(.custom("Avenir-Heavy", size: 13))
                        }
                        Text(result.narrativeLog)
                            .font(.custom("Avenir-Medium", size: 13))
                            .foregroundColor(.secondary)
                            .italic()
                    }
                    
                    if result.stageIndex < active.stageResults.count - 1 {
                        Divider()
                    }
                }
            }
            .padding(16)
            .background(Color("CardBackground"))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        }
    }
    
    // MARK: - Stage Result Sheet
    
    @ViewBuilder
    private func stageResultSheet(result: StageResult, active: ActiveExpedition) -> some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color("BackgroundTop"), Color("BackgroundBottom")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Result header
                    ZStack {
                        Circle()
                            .fill((result.success ? Color("AccentGreen") : Color("AccentOrange")).opacity(0.15))
                            .frame(width: 80, height: 80)
                        Image(systemName: result.success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(result.success ? Color("AccentGreen") : Color("AccentOrange"))
                    }
                    .padding(.top, 20)
                    
                    Text(result.success ? "Stage Complete!" : "Stage Struggled")
                        .font(.custom("Avenir-Heavy", size: 24))
                    
                    // Narrative
                    Text(result.narrativeLog)
                        .font(.custom("Avenir-Medium", size: 15))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .italic()
                    
                    // Rewards
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(Color("AccentPurple"))
                            Text("+\(result.earnedEXP) EXP")
                                .font(.custom("Avenir-Heavy", size: 16))
                            Spacer()
                        }
                        HStack {
                            Image(systemName: "dollarsign.circle.fill")
                                .foregroundColor(Color("AccentGold"))
                            Text("+\(result.earnedGold) Gold")
                                .font(.custom("Avenir-Heavy", size: 16))
                            Spacer()
                        }
                        if let loot = result.lootDroppedName {
                            HStack {
                                Image(systemName: "shield.fill")
                                    .foregroundColor(Color("AccentOrange"))
                                Text(loot)
                                    .font(.custom("Avenir-Heavy", size: 16))
                                Spacer()
                            }
                        }
                        if result.materialDropped {
                            HStack {
                                Image(systemName: "cube.fill")
                                    .foregroundColor(Color("AccentPurple"))
                                Text("Crafting Materials")
                                    .font(.custom("Avenir-Heavy", size: 16))
                                Spacer()
                            }
                        }
                        if result.cardDropped {
                            HStack {
                                Image(systemName: "rectangle.portrait.fill")
                                    .foregroundColor(Color("AccentGreen"))
                                Text("Monster Card Discovered!")
                                    .font(.custom("Avenir-Heavy", size: 16))
                                Spacer()
                            }
                        }
                    }
                    .padding(16)
                    .background(Color("CardBackground"))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 16)
                    
                    // Remaining stages
                    if active.remainingStages > 0 {
                        Text("\(active.remainingStages) stage\(active.remainingStages == 1 ? "" : "s") remaining")
                            .font(.custom("Avenir-Medium", size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        showStageResults = false
                    } label: {
                        Text("Continue")
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
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large])
    }
    
    // MARK: - Final Rewards Sheet
    
    @ViewBuilder
    private func finalRewardsSheet(active: ActiveExpedition) -> some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color("BackgroundTop"), Color("BackgroundBottom")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Trophy icon
                    ZStack {
                        Circle()
                            .fill(Color("AccentGold").opacity(0.15))
                            .frame(width: 90, height: 90)
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 40))
                            .foregroundColor(Color("AccentGold"))
                    }
                    .padding(.top, 20)
                    
                    Text("Expedition Complete!")
                        .font(.custom("Avenir-Heavy", size: 26))
                    
                    Text(active.expeditionName)
                        .font(.custom("Avenir-Medium", size: 16))
                        .foregroundColor(.secondary)
                    
                    // Summary stats
                    HStack(spacing: 20) {
                        VStack(spacing: 4) {
                            Text("\(active.successfulStageCount)/\(active.totalStages)")
                                .font(.custom("Avenir-Heavy", size: 22))
                                .foregroundColor(Color("AccentGreen"))
                            Text("Stages")
                                .font(.custom("Avenir-Medium", size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Divider().frame(height: 40)
                        
                        VStack(spacing: 4) {
                            Text("+\(active.totalEXPEarned)")
                                .font(.custom("Avenir-Heavy", size: 22))
                                .foregroundColor(Color("AccentPurple"))
                            Text("EXP")
                                .font(.custom("Avenir-Medium", size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Divider().frame(height: 40)
                        
                        VStack(spacing: 4) {
                            Text("+\(active.totalGoldEarned)")
                                .font(.custom("Avenir-Heavy", size: 22))
                                .foregroundColor(Color("AccentGold"))
                            Text("Gold")
                                .font(.custom("Avenir-Medium", size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(16)
                    .background(Color("CardBackground"))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 16)
                    
                    // Equipment drops
                    if !active.equipmentDropped.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "shield.fill")
                                    .foregroundColor(Color("AccentOrange"))
                                Text("Equipment Found")
                                    .font(.custom("Avenir-Heavy", size: 16))
                                Spacer()
                            }
                            ForEach(active.equipmentDropped, id: \.self) { item in
                                HStack {
                                    Image(systemName: "sparkle")
                                        .font(.system(size: 10))
                                        .foregroundColor(Color("AccentGold"))
                                    Text(item)
                                        .font(.custom("Avenir-Medium", size: 14))
                                    Spacer()
                                }
                            }
                        }
                        .padding(16)
                        .background(Color("CardBackground"))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                        .padding(.horizontal, 16)
                    }
                    
                    Spacer()
                    
                    // Claim button
                    Button {
                        claimFinalRewards()
                    } label: {
                        HStack {
                            Image(systemName: "gift.fill")
                            Text("Claim All Rewards")
                        }
                        .font(.custom("Avenir-Heavy", size: 17))
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
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large])
    }
    
    // MARK: - No Character Placeholder
    
    private var noCharacterPlaceholder: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "compass.drawing")
                .font(.system(size: 50))
                .foregroundColor(.secondary.opacity(0.4))
            Text("Create a character to begin expeditions.")
                .font(.custom("Avenir-Medium", size: 16))
                .foregroundColor(.secondary)
            Spacer()
        }
    }
    
    // MARK: - Helpers
    
    private func stageStatusIcon(for index: Int, active: ActiveExpedition) -> String {
        if index < active.stageResults.count {
            return active.stageResults[index].success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
        } else if index == active.currentStageIndex && !active.isFullyComplete {
            return "hourglass"
        }
        return "circle"
    }
    
    private func stageStatusColor(for index: Int, active: ActiveExpedition) -> Color {
        if index < active.stageResults.count {
            return active.stageResults[index].success ? Color("AccentGreen") : Color("AccentOrange")
        } else if index == active.currentStageIndex && !active.isFullyComplete {
            return Color(active.expeditionTheme.color)
        }
        return .secondary.opacity(0.4)
    }
    
    // MARK: - Actions
    
    private func loadExpeditions() {
        let contentExpeditions = ContentManager.shared.expeditions.filter { $0.active }
        availableExpeditions = contentExpeditions.map { Expedition(from: $0) }
    }
    
    private func launchExpedition(_ expedition: Expedition) {
        guard let character = character else { return }
        guard ExpeditionKeyStore.use() else { return }
        
        let active = ActiveExpedition(
            expedition: expedition,
            characterID: character.id
        )
        activeExpedition = active
        active.persist()
        
        // Play departure sound + haptic
        AudioManager.shared.play(.expeditionDepart)
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        // Schedule push notification for first stage completion
        PushNotificationService.shared.scheduleExpeditionStageComplete(
            expeditionName: expedition.name,
            stageName: expedition.stages.first?.name ?? "Stage 1",
            completionDate: active.nextStageCompletesAt
        )
    }
    
    private func resolveCurrentStage(active: ActiveExpedition, character: PlayerCharacter) {
        guard active.currentStageIndex < active.totalStages else { return }
        
        let result = gameEngine.resolveExpeditionStage(
            active: active,
            character: character
        )
        
        latestStageResult = result
        
        // Collect card if one dropped
        if result.cardDropped {
            let cardPool = ContentManager.shared.activeCardPool
            if let contentCard = CardDropEngine.rollExpeditionCardDrop(
                expeditionTheme: active.expeditionTheme.rawValue,
                cardPool: cardPool
            ) {
                _ = CardDropEngine.collectCard(
                    contentCard: contentCard,
                    character: character,
                    context: modelContext
                )
            }
        }
        
        // Play stage complete sound + haptic
        AudioManager.shared.play(.expeditionStageComplete)
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(result.success ? .success : .warning)
        
        // If there are more stages, schedule next push notification
        if active.currentStageIndex < active.totalStages {
            let nextStageName = active.currentStageIndex < active.stageNames.count
                ? active.stageNames[active.currentStageIndex]
                : "Stage \(active.currentStageIndex + 1)"
            PushNotificationService.shared.scheduleExpeditionStageComplete(
                expeditionName: active.expeditionName,
                stageName: nextStageName,
                completionDate: active.nextStageCompletesAt
            )
        }
        
        // If expedition is now fully complete, play treasure sound
        if active.isFullyComplete {
            AudioManager.shared.play(.expeditionTreasure)
            let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
            heavyImpact.impactOccurred()
        }
        
        active.persist()
        showStageResults = true
    }
    
    private func claimFinalRewards() {
        guard let character = character, let active = activeExpedition else { return }
        
        // Apply total rewards to character
        character.gainEXP(active.totalEXPEarned)
        character.gold += active.totalGoldEarned
        
        // Auto-level-up if eligible
        while character.canLevelUp {
            _ = character.performLevelUp()
        }
        
        // Play treasure sound + haptic
        AudioManager.shared.play(.claimReward)
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        
        // Sync
        SyncManager.shared.queueCharacterSync(character)
        SyncManager.shared.queueDailyStateSync(character)
        
        // Check achievements
        let newlyUnlocked = AchievementTracker.checkAll(character: character)
        if let first = newlyUnlocked.first {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                gameEngine.unlockedAchievement = first
                gameEngine.showAchievementCelebration = true
            }
        }
        
        // Clear active expedition
        showFinalRewards = false
        activeExpedition = nil
        ActiveExpedition.clearPersisted()
    }
    
    private func startTimer() {
        expeditionTimer?.invalidate()
        expeditionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                timerTick += 1
            }
        }
    }
}

#Preview {
    ExpeditionView()
        .environmentObject(GameEngine())
}
