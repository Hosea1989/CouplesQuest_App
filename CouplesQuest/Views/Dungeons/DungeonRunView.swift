import SwiftUI
import SwiftData

struct DungeonRunView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var gameEngine: GameEngine
    
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
    
    // Timer that fires every second to update countdown
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    enum RunPhase {
        case waiting    // AFK timer countdown
        case resolving  // Brief animation while resolving
        case results    // Show victory/defeat + full log
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
            case .resolving:
                resolvingContent
            case .results:
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
                
                Circle()
                    .fill(Color(dungeon.difficulty.color).opacity(0.1))
                    .frame(width: 130, height: 130)
                Image(systemName: dungeon.theme.icon)
                    .font(.system(size: 50))
                    .foregroundColor(Color(dungeon.difficulty.color))
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
                Circle()
                    .fill(Color(dungeon.difficulty.color).opacity(0.15))
                    .frame(width: 120, height: 120)
                Image(systemName: dungeon.theme.icon)
                    .font(.system(size: 56))
                    .foregroundColor(Color(dungeon.difficulty.color))
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
                        roomLog(result: result)
                        
                        if !result.lootDrops.isEmpty {
                            lootSection(result: result)
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
            SummaryRow(icon: "door.left.hand.open", label: "Rooms Cleared", value: "\(result.roomsCleared)/\(result.totalRooms)", color: result.success ? Color("AccentGreen") : .secondary)
            SummaryRow(icon: "heart.fill", label: "HP Remaining", value: "\(result.hpRemaining)/\(result.maxHP)", color: .red)
            
            Divider()
            
            SummaryRow(icon: "sparkles", label: "Total EXP", value: "+\(result.totalExp)", color: Color("AccentGold"))
            SummaryRow(icon: "dollarsign.circle.fill", label: "Total Gold", value: "+\(result.totalGold)", color: Color("AccentGold"))
            
            if result.isCoopRun && result.bondExpEarned > 0 {
                Divider()
                SummaryRow(icon: "heart.circle.fill", label: "Bond EXP", value: "+\(result.bondExpEarned)", color: Color("AccentPink"))
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color("CardBackground")))
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
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color("CardBackground")))
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
            let result = DungeonEngine.autoRunDungeon(
                dungeon: dungeon,
                run: run,
                party: party
            )
            
            completionResult = result
            
            // Award EXP and gold to party members
            for member in party {
                if result.totalExp > 0 {
                    member.gainEXP(result.totalExp)
                }
                member.gold += result.totalGold / max(1, party.count)
            }
            
            // Insert loot into model context
            for item in result.lootDrops {
                modelContext.insert(item)
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
                for (index, roomResult) in result.roomResults.enumerated() where roomResult.success {
                    if index < dungeon.rooms.count {
                        gameEngine.awardMaterialsForDungeonRoom(
                            encounterType: dungeon.rooms[index].encounterType,
                            dungeonTier: dungeon.lootTier,
                            character: firstMember,
                            context: modelContext
                        )
                    }
                }
            }
            
            // Haptic + audio feedback
            if result.success {
                hapticSuccess += 1
                AudioManager.shared.play(.dungeonComplete)
            } else {
                hapticError += 1
                AudioManager.shared.play(.error)
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
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
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
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(equipment.rarity.color).opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: equipment.slot.icon)
                    .foregroundColor(Color(equipment.rarity.color))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(equipment.name)
                    .font(.custom("Avenir-Heavy", size: 14))
                    .foregroundColor(Color(equipment.rarity.color))
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
