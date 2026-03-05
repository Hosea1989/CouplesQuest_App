import SwiftUI
import SwiftData

private enum TaskTab: String, CaseIterable {
    case duties, habits, goals, party
    
    var label: String {
        switch self {
        case .duties: "Duties"
        case .habits: "Habits"
        case .goals: "Goals"
        case .party: "Party"
        }
    }
    
    var icon: String {
        switch self {
        case .duties: "checklist"
        case .habits: "repeat.circle.fill"
        case .goals: "flag.fill"
        case .party: "person.2.fill"
        }
    }
}

struct TasksView: View {
    /// When true, the view is pushed inside an existing NavigationStack and should not create its own.
    var isEmbedded: Bool = false
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var gameEngine: GameEngine
    @Query(sort: \GameTask.createdAt, order: .reverse) private var allTasks: [GameTask]
    @Query private var characters: [PlayerCharacter]
    @Query private var bonds: [Bond]
    @Query(sort: \WeeklyRaidBoss.weekStartDate, order: .reverse) private var raidBosses: [WeeklyRaidBoss]
    
    @State private var showCreateTask = false
    @State private var showCompletionCelebration = false
    @State private var lastCompletionResult: TaskCompletionResult?
    @State private var deleteTrigger = 0
    @State private var dailyDuties: [GameTask] = []
    @State private var showVerification = false
    @State private var taskPendingVerification: GameTask?
    @State private var showTimerAlert = false
    @State private var timerAlertMessage = ""
    @State private var timerTick = 0 // triggers UI refresh for timer countdown
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
    @State private var miniGameFailCounts: [UUID: Int] = [:]
    @State private var showMeditationSession = false
    @State private var meditationDuty: GameTask?
    @State private var showCoopChoice = false
    @State private var dutyPendingCoopChoice: GameTask?
    @State private var showRefreshConfirm = false
    @State private var refreshRotation: Double = 0
    @State private var selectedTaskTab: TaskTab = .duties
    @State private var showCompletedHistory = false
    @State private var showCreateGoal = false
    
    private var character: PlayerCharacter? {
        characters.first
    }
    
    private var bond: Bond? {
        bonds.first
    }
    
    private var activeRaidBoss: WeeklyRaidBoss? {
        raidBosses.first(where: { $0.isActive })
    }
    
    /// Partner quests: tasks from partner that aren't completed
    private var partnerQuests: [GameTask] {
        allTasks.filter { $0.isFromPartner && $0.status != .completed && !$0.isDailyDuty && !$0.isHabit }
    }
    
    /// Active duties: tasks that aren't on the duty board, daily board slots, habits, or from partner, and aren't done/expired
    private var myTasks: [GameTask] {
        allTasks.filter { !$0.isOnDutyBoard && !$0.isDailyDuty && !$0.isFromPartner && !$0.isHabit && $0.status != .completed && $0.status != .expired }
    }
    
    /// Habits (always shown, tap to mark done)
    private var habits: [GameTask] {
        allTasks.filter { $0.isHabit }
    }
    
    /// Completed tasks (all types)
    private var completedTasks: [GameTask] {
        allTasks.filter { $0.status == .completed }
    }
    
    /// Time until daily duty reset
    private var timeUntilReset: String {
        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date())) else {
            return "--"
        }
        let remaining = Int(tomorrow.timeIntervalSince(Date()))
        let hours = remaining / 3600
        let minutes = (remaining % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
    
    /// How many daily duties are completed
    private var dutiesCompletedCount: Int {
        dailyDuties.filter { $0.status == .completed }.count
    }
    
    /// How many daily duties have been accepted (in progress) or completed
    private var dutiesAcceptedCount: Int {
        dailyDuties.filter { $0.status == .inProgress }.count
    }
    
    /// How many duties the player has claimed today (persisted in UserDefaults)
    private var dutiesClaimedToday: Int {
        DutyBoardGenerator.dutiesClaimedToday
    }
    
    /// Whether the player has reached the daily duty selection limit (persisted)
    private var reachedDailyDutyLimit: Bool {
        DutyBoardGenerator.reachedDailyDutyLimit
    }
    
    var body: some View {
        if isEmbedded {
            tasksListContent
        } else {
            NavigationStack {
                tasksListContent
            }
        }
    }
    
    @ViewBuilder
    private var tasksListContent: some View {
            ZStack {
                LinearGradient(
                    colors: [
                        Color("BackgroundTop"),
                        Color("BackgroundBottom")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    taskTabPicker
                    
                    switch selectedTaskTab {
                    case .duties:
                        dutiesTabContent
                    case .habits:
                        habitsTabContent
                    case .goals:
                        goalsTabContent
                    case .party:
                        partyTabContent
                    }
                }
            }
            .navigationTitle("Daily Tasks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        switch selectedTaskTab {
                        case .goals:
                            showCreateGoal = true
                        default:
                            showCreateTask = true
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color("AccentGold"))
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showCreateTask) {
                CreateTaskView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showCreateGoal) {
                CreateGoalView()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showCompletedHistory) {
                completedHistorySheet
            }
            .sheet(isPresented: $showCompletionCelebration) {
                if let result = lastCompletionResult {
                    TaskCompletionCelebration(result: result)
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                }
            }
            .sheet(isPresented: $showVerification) {
                if let task = taskPendingVerification {
                    TaskVerificationView(task: task) {
                        finalizeTaskCompletion(task)
                    }
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                }
            }
            .fullScreenCover(isPresented: $showSudoku) {
                SudokuGameView(
                    onComplete: { elapsedSeconds in
                        completeSudokuDuty(elapsedSeconds: elapsedSeconds)
                    },
                    onFail: { handleMiniGameFail(for: sudokuDuty); sudokuDuty = nil }
                )
            }
            .fullScreenCover(isPresented: $showMemoryMatch) {
                MemoryMatchGameView(
                    onComplete: { elapsedSeconds in
                        let tier = MemoryMatchRewardTier.tier(for: elapsedSeconds)
                        completeMiniGameDuty(
                            task: memoryMatchDuty,
                            elapsedSeconds: elapsedSeconds,
                            gold: tier.gold,
                            statBonus: tier.wisdomBonus,
                            bonusStat: .luck,
                            consumableName: tier.consumableName,
                            consumableIcon: tier.consumableIcon,
                            consumableCount: tier.consumableCount,
                            gameName: "Memory Match"
                        )
                        memoryMatchDuty = nil
                    },
                    onFail: { handleMiniGameFail(for: memoryMatchDuty); memoryMatchDuty = nil }
                )
            }
            .fullScreenCover(isPresented: $showMathBlitz) {
                MathBlitzGameView(
                    onComplete: { elapsedSeconds in
                        let tier = MathBlitzRewardTier.tier(for: elapsedSeconds)
                        completeMiniGameDuty(
                            task: mathBlitzDuty,
                            elapsedSeconds: elapsedSeconds,
                            gold: tier.gold,
                            statBonus: tier.wisdomBonus,
                            bonusStat: .wisdom,
                            consumableName: tier.consumableName,
                            consumableIcon: tier.consumableIcon,
                            consumableCount: tier.consumableCount,
                            gameName: "Math Blitz"
                        )
                        mathBlitzDuty = nil
                    },
                    onFail: { handleMiniGameFail(for: mathBlitzDuty); mathBlitzDuty = nil }
                )
            }
            .fullScreenCover(isPresented: $showWordSearch) {
                WordSearchGameView { elapsedSeconds in
                    let tier = WordSearchRewardTier.tier(for: elapsedSeconds)
                    completeMiniGameDuty(
                        task: wordSearchDuty,
                        elapsedSeconds: elapsedSeconds,
                        gold: tier.gold,
                        statBonus: tier.wisdomBonus,
                        bonusStat: .charisma,
                        consumableName: tier.consumableName,
                        consumableIcon: tier.consumableIcon,
                        consumableCount: tier.consumableCount,
                        gameName: "Word Search"
                    )
                    wordSearchDuty = nil
                }
            }
            .fullScreenCover(isPresented: $show2048) {
                Game2048View { elapsedSeconds in
                    complete2048Duty(elapsedSeconds: elapsedSeconds)
                }
            }
            .fullScreenCover(isPresented: $showMeditationSession) {
                NavigationStack {
                    MeditationView(
                        dutyTask: meditationDuty,
                        onMeditationComplete: {
                            completeMeditationDuty()
                        }
                    )
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Close") {
                                showMeditationSession = false
                            }
                            .foregroundColor(Color("AccentGold"))
                        }
                    }
                }
            }
            .alert("Not Yet!", isPresented: $showTimerAlert) {
                Button("OK") {}
            } message: {
                Text(timerAlertMessage)
            }
            .confirmationDialog(
                "Do this duty together?",
                isPresented: $showCoopChoice,
                titleVisibility: .visible
            ) {
                Button("Solo") {
                    if let task = dutyPendingCoopChoice {
                        finalizeDutyAccept(task, asCoop: false)
                        dutyPendingCoopChoice = nil
                    }
                }
                Button("Co-op with \(character?.partnerName ?? "Partner")") {
                    if let task = dutyPendingCoopChoice {
                        finalizeDutyAccept(task, asCoop: true)
                        dutyPendingCoopChoice = nil
                    }
                }
                Button("Cancel", role: .cancel) {
                    dutyPendingCoopChoice = nil
                }
            } message: {
                Text("Co-op duties give 1.5× rewards and Bond EXP when you both complete it!")
            }
            .alert("Shuffle Duty Board?", isPresented: $showRefreshConfirm) {
                Button("Shuffle", role: .destructive) {
                    refreshDutyBoard()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Get 4 new duties from different categories. You can shuffle once per day.")
            }
            .sensoryFeedback(.success, trigger: showCompletionCelebration) { _, newValue in
                newValue
            }
            .sensoryFeedback(.impact(weight: .medium), trigger: deleteTrigger)
            .onAppear {
                loadDailyDuties()
            }
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                timerTick += 1
                expireOverdueTasks()
                checkHabitDeadlines()
            }
    }
    
    // MARK: - Tab Picker
    
    private func tabCount(for tab: TaskTab) -> Int {
        switch tab {
        case .duties:
            return dailyDuties.filter { $0.status == .pending }.count + myTasks.count
        case .habits:
            return habits.count
        case .goals:
            return 0
        case .party:
            return partnerQuests.count
        }
    }
    
    private var visibleTabs: [TaskTab] {
        var tabs: [TaskTab] = [.duties, .habits, .goals]
        if character?.hasPartner == true || !partnerQuests.isEmpty {
            tabs.append(.party)
        }
        return tabs
    }
    
    private var taskTabPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(visibleTabs, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTaskTab = tab
                        }
                        AudioManager.shared.play(.tabSwitch)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 12))
                            Text(tab.label)
                                .font(.custom("Avenir-Heavy", size: 13))
                            
                            let count = tabCount(for: tab)
                            if count > 0 {
                                Text("\(count)")
                                    .font(.custom("Avenir-Heavy", size: 11))
                                    .foregroundColor(selectedTaskTab == tab ? Color("AccentGold") : .secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule().fill(
                                            selectedTaskTab == tab
                                                ? Color.black.opacity(0.15)
                                                : Color.secondary.opacity(0.12)
                                        )
                                    )
                            }
                        }
                        .foregroundColor(selectedTaskTab == tab ? .black : .secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule().fill(
                                selectedTaskTab == tab
                                    ? Color("AccentGold")
                                    : Color("CardBackground")
                            )
                        )
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Duties Tab (Board + Active)
    
    private var dutiesTabContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                dutyBoardSection
                myTasksSection
            }
            .padding()
        }
    }
    
    // MARK: - Habits Tab
    
    private var habitsTabContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                if habits.isEmpty {
                    VStack(spacing: 12) {
                        Spacer().frame(height: 60)
                        
                        Image(systemName: "repeat.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.4))
                        
                        Text("No Habits Yet")
                            .font(.custom("Avenir-Heavy", size: 17))
                            .foregroundColor(.secondary)
                        
                        Text("Create a habit to build daily streaks and earn bonus rewards.")
                            .font(.custom("Avenir-Medium", size: 14))
                            .foregroundColor(.secondary.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    dailyHabitsSection
                }
                
                if !completedTasks.isEmpty {
                    Button {
                        showCompletedHistory = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 14))
                            Text("View Completed (\(completedTasks.count))")
                                .font(.custom("Avenir-Heavy", size: 14))
                        }
                        .foregroundColor(.secondary)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color("CardBackground"))
                        )
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Goals Tab
    
    private var goalsTabContent: some View {
        GoalsView(isEmbedded: true)
    }
    
    // MARK: - Party Tab
    
    private var partyTabContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                partnerQuestsSection
            }
            .padding()
        }
    }
    
    // MARK: - Completed History Sheet
    
    private var completedHistorySheet: some View {
        NavigationStack {
            ScrollView {
                if completedTasks.isEmpty {
                    VStack(spacing: 12) {
                        Spacer().frame(height: 60)
                        
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.4))
                        
                        Text("No Completed Tasks")
                            .font(.custom("Avenir-Heavy", size: 17))
                            .foregroundColor(.secondary)
                        
                        Text("Tasks you complete will appear here.")
                            .font(.custom("Avenir-Medium", size: 14))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    VStack(spacing: 8) {
                        ForEach(completedTasks, id: \.id) { task in
                            CompletedTaskRow(task: task, characterLevel: character?.level ?? 1)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color("CardBackground"))
                                )
                        }
                    }
                    .padding()
                }
            }
            .background(
                LinearGradient(
                    colors: [Color("BackgroundTop"), Color("BackgroundBottom")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Completed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showCompletedHistory = false }
                        .foregroundColor(Color("AccentGold"))
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Daily Habits Section
    
    private var dailyHabitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "repeat.circle.fill")
                    .font(.title3)
                    .foregroundColor(Color("AccentGreen"))
                
                Text("Daily Habits")
                    .font(.custom("Avenir-Heavy", size: 18))
                
                Spacer()
                
                let doneCount = habits.filter { $0.isHabitCompletedToday }.count
                Text("\(doneCount)/\(habits.count)")
                    .font(.custom("Avenir-Heavy", size: 14))
                    .foregroundColor(doneCount == habits.count ? Color("AccentGreen") : .secondary)
            }
            
            ForEach(habits, id: \.id) { habit in
                HabitRow(
                    habit: habit,
                    onComplete: { completeHabitTask(habit) },
                    onDelete: { deleteTask(habit) },
                    timerTick: timerTick,
                    characterLevel: character?.level ?? 1
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
    
    private func completeHabitTask(_ habit: GameTask) {
        guard let character = character else { return }
        guard !habit.isHabitCompletedToday else { return }
        
        // Update habit streak before gameEngine completes it
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        if let lastCompleted = habit.habitLastCompletedDate {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            if calendar.isDate(lastCompleted, inSameDayAs: yesterday) {
                habit.habitStreak += 1
            } else if !calendar.isDate(lastCompleted, inSameDayAs: today) {
                habit.habitStreak = 1
            }
        } else {
            habit.habitStreak = 1
        }
        habit.habitLongestStreak = max(habit.habitLongestStreak, habit.habitStreak)
        habit.habitLastCompletedDate = today
        
        // Use GameEngine's completeTask for proper EXP/reward flow
        var result = gameEngine.completeTask(habit, character: character, context: modelContext)
        
        // Update daily quest progress and materials
        gameEngine.updateStreak(for: character, completedTaskToday: true)
        gameEngine.updateDailyQuestProgress(
            task: habit,
            expGained: result.expGained,
            goldGained: result.goldGained,
            character: character,
            context: modelContext
        )
        let matDrops = gameEngine.awardMaterialsForTask(
            task: habit,
            character: character,
            context: modelContext
        )
        result.materialDrops = matDrops
        
        if let boss = activeRaidBoss {
            if let raidResult = gameEngine.dealRaidDamage(
                character: character,
                boss: boss,
                activityType: .habit,
                activityValue: habit.habitStreak,
                sourceLabel: "Habit: \(habit.title)"
            ) {
                result.raidDamageDealt = raidResult.damage
                result.raidRetaliationTaken = raidResult.retaliationDamage
            }
        }
        
        lastCompletionResult = result
        showCompletionCelebration = true
    }
    
    // MARK: - Duty Board Section
    
    private var dutyBoardSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .font(.title3)
                    .foregroundColor(Color("AccentOrange"))
                
                Text("Duty Board")
                    .font(.custom("Avenir-Heavy", size: 20))
                
                Spacer()
                
                // Refresh button
                Button(action: { showRefreshConfirm = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 13, weight: .semibold))
                            .rotationEffect(.degrees(refreshRotation))
                        Text("Shuffle")
                            .font(.custom("Avenir-Heavy", size: 12))
                    }
                    .foregroundColor(DutyBoardGenerator.canRefreshToday ? Color("AccentOrange") : .secondary.opacity(0.5))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(DutyBoardGenerator.canRefreshToday
                                  ? Color("AccentOrange").opacity(0.15)
                                  : Color.secondary.opacity(0.08))
                    )
                    .overlay(
                        Capsule()
                            .stroke(DutyBoardGenerator.canRefreshToday
                                    ? Color("AccentOrange").opacity(0.3)
                                    : Color.clear, lineWidth: 1)
                    )
                }
                .disabled(!DutyBoardGenerator.canRefreshToday || reachedDailyDutyLimit)
                
                // Progress + timer
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(dutiesClaimedToday)/\(DutyBoardGenerator.maxDutySelectionsPerDay)")
                        .font(.custom("Avenir-Heavy", size: 14))
                        .foregroundColor(Color("AccentGold"))
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 9))
                        Text(timeUntilReset)
                            .font(.custom("Avenir-Medium", size: 11))
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 0) {
                Text("Pick 1 duty per day — complete it for EXP and gold!")
                    .font(.custom("Avenir-Medium", size: 13))
                    .foregroundColor(.secondary)
                
                if !DutyBoardGenerator.canRefreshToday {
                    Spacer()
                    Text("Shuffled today")
                        .font(.custom("Avenir-Medium", size: 11))
                        .foregroundColor(.secondary.opacity(0.6))
                        .italic()
                }
            }
            
            // Duty notes grid (2 columns)
            if dailyDuties.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        ProgressView()
                        Text("Loading duties...")
                            .font(.custom("Avenir-Medium", size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(dailyDuties.filter { $0.status == .pending }, id: \.id) { duty in
                        DutyNoteCard(
                            task: duty,
                            isLocked: reachedDailyDutyLimit || DutyBoardGenerator.isAtActiveDutyCap(context: modelContext),
                            characterLevel: character?.level ?? 1,
                            onAccept: { acceptDuty(duty) }
                        )
                    }
                }
            }
        }
        .padding(18)
        .background(
            ZStack {
                // Base card
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color("CardBackground"))
                
                // Warm cork-like overlay
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color("AccentOrange").opacity(0.04),
                                Color("AccentGold").opacity(0.06),
                                Color("AccentOrange").opacity(0.03)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Subtle border
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color("AccentOrange").opacity(0.15), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Partner Quests Section
    
    private var partnerQuestsSection: some View {
        Group {
            if character?.hasPartner == true || !partnerQuests.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    // Header
                    HStack {
                        Image(systemName: "paperplane.fill")
                            .font(.callout)
                            .foregroundColor(Color("AccentPink"))
                        
                        Text("Partner Quests")
                            .font(.custom("Avenir-Heavy", size: 18))
                        
                        if let name = character?.partnerName {
                            Text("from \(name)")
                                .font(.custom("Avenir-Medium", size: 13))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if let bond = bond {
                            HStack(spacing: 4) {
                                Image(systemName: "heart.fill")
                                    .font(.caption2)
                                Text("Lv.\(bond.bondLevel)")
                                    .font(.custom("Avenir-Heavy", size: 12))
                            }
                            .foregroundColor(Color("AccentPink"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color("AccentPink").opacity(0.12))
                            )
                        }
                    }
                    
                    if partnerQuests.isEmpty {
                        // Empty state
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "tray")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                
                                Text(character?.hasPartner == true
                                     ? "No quests from your partner yet"
                                     : "Link with a partner to receive quests")
                                    .font(.custom("Avenir-Medium", size: 14))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 16)
                            Spacer()
                        }
                    } else {
                        ForEach(partnerQuests, id: \.id) { task in
                            NavigationLink(destination: TaskDetailView(task: task)) {
                                PartnerQuestCard(
                                    task: task,
                                    partnerName: character?.partnerName,
                                    characterLevel: character?.level ?? 1,
                                    onComplete: { completeTask(task) }
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color("CardBackground"))
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                )
            }
        }
    }
    
    // MARK: - Active Duties Section
    
    private var myTasksSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Image(systemName: "checklist")
                    .font(.callout)
                    .foregroundColor(Color("AccentGold"))
                
                Text("Active Duties")
                    .font(.custom("Avenir-Heavy", size: 18))
                
                Spacer()
                
                Text("\(myTasks.count)/\(DutyBoardGenerator.maxActiveDuties)")
                    .font(.custom("Avenir-Heavy", size: 14))
                    .foregroundColor(myTasks.count >= DutyBoardGenerator.maxActiveDuties ? Color("AccentOrange") : .secondary)
            }
            
            if myTasks.isEmpty {
                // Empty state — direct user to the duty board
                VStack(spacing: 10) {
                    Image(systemName: "scroll")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    
                    Text("No active duties")
                        .font(.custom("Avenir-Heavy", size: 15))
                        .foregroundColor(.secondary)
                    
                    Text("Pick a duty from the Duty Board above to get started!")
                        .font(.custom("Avenir-Medium", size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 11, weight: .bold))
                        Text("Scroll up to Duty Board")
                            .font(.custom("Avenir-Heavy", size: 13))
                    }
                    .foregroundColor(Color("AccentOrange"))
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                ForEach(myTasks, id: \.id) { task in
                    if isMeditationDuty(task) && !task.isDeadlineExpired && task.status != .expired {
                        // Meditation task — tapping opens the meditation session
                        Button {
                            meditationDuty = task
                            showMeditationSession = true
                        } label: {
                            TaskCard(
                                task: task,
                                onComplete: {
                                    meditationDuty = task
                                    showMeditationSession = true
                                },
                                onDelete: { deleteTask(task) },
                                timerTick: timerTick,
                                isMiniGame: true,
                                characterLevel: character?.level ?? 1
                            )
                        }
                        .buttonStyle(.plain)
                    } else if miniGameType(for: task) != nil && !task.isDeadlineExpired && task.status != .expired {
                        // Mini-game task — tapping opens the game
                        Button {
                            openMiniGame(for: task)
                        } label: {
                            TaskCard(
                                task: task,
                                onComplete: { openMiniGame(for: task) },
                                onDelete: { deleteTask(task) },
                                timerTick: timerTick,
                                isMiniGame: true,
                                characterLevel: character?.level ?? 1
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        NavigationLink(destination: TaskDetailView(task: task)) {
                            TaskCard(
                                task: task,
                                onComplete: { startAndComplete(task) },
                                onDelete: { deleteTask(task) },
                                timerTick: timerTick,
                                characterLevel: character?.level ?? 1
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // MARK: - Actions
    
    private func loadDailyDuties() {
        guard let character = character else { return }
        
        let expiredIDs = DutyBoardGenerator.expireOldDuties(context: modelContext)
        for id in expiredIDs {
            Task { try? await SupabaseService.shared.deleteTask(localID: id) }
        }
        
        dailyDuties = DutyBoardGenerator.ensureTodaysDuties(
            characterID: character.id,
            context: modelContext
        )
    }
    
    private func refreshDutyBoard() {
        guard let character = character else { return }
        // Spin the icon
        withAnimation(.easeInOut(duration: 0.5)) {
            refreshRotation += 360
        }
        // Regenerate duties with a new seed
        dailyDuties = DutyBoardGenerator.refreshDutyBoard(
            characterID: character.id,
            context: modelContext
        )
        AudioManager.shared.play(.dutyBoardShuffle)
    }
    
    /// Identifies which mini-game (if any) a task corresponds to.
    private enum MiniGameType {
        case sudoku
        case memoryMatch
        case mathBlitz
        case wordSearch
        case game2048
    }
    
    private func miniGameType(for task: GameTask) -> MiniGameType? {
        switch task.title {
        case "Sudoku Challenge", "Solve a Puzzle":
            return .sudoku
        case "Memory Match":
            return .memoryMatch
        case "Math Blitz":
            return .mathBlitz
        case "Word Search":
            return .wordSearch
        case "2048 Challenge":
            return .game2048
        default:
            return nil
        }
    }
    
    /// Legacy helper — kept for backward compatibility
    private func isSudokuDuty(_ task: GameTask) -> Bool {
        miniGameType(for: task) != nil
    }
    
    /// Whether this task is the meditation duty
    private func isMeditationDuty(_ task: GameTask) -> Bool {
        task.title == "Meditate for 5 Minutes"
    }
    
    private func acceptDuty(_ task: GameTask) {
        guard task.status == .pending else { return }
        guard let character = character else { return }
        guard !reachedDailyDutyLimit else { return }
        
        // Special handling: meditation duty opens the meditation experience directly
        if isMeditationDuty(task) {
            // Accept the duty (move it to active)
            finalizeDutyAccept(task, asCoop: false)
            // Then immediately open the meditation session
            meditationDuty = task
            showMeditationSession = true
            return
        }
        
        // If the player has a partner, show co-op choice
        if character.hasPartner {
            dutyPendingCoopChoice = task
            showCoopChoice = true
        } else {
            finalizeDutyAccept(task, asCoop: false)
        }
    }
    
    /// Finalize accepting a duty, optionally as co-op with partner
    private func finalizeDutyAccept(_ task: GameTask, asCoop: Bool) {
        guard let character = character else { return }
        
        if DutyBoardGenerator.isAtActiveDutyCap(context: modelContext) {
            ToastManager.shared.showError(
                "Active Duties Full",
                subtitle: "Complete or abandon a duty first (\(DutyBoardGenerator.maxActiveDuties)/\(DutyBoardGenerator.maxActiveDuties))"
            )
            return
        }
        
        // Record the claim in persistent storage (survives view reloads)
        DutyBoardGenerator.recordDutyClaim()
        
        // Move the duty to Active Duties
        task.assignedTo = character.id
        task.isOnDutyBoard = false
        task.isDailyDuty = false
        task.isCoopDuty = asCoop
        
        task.status = .inProgress
        AudioManager.shared.play(.dutyAccept)
    }
    
    /// Handle a mini-game failure. After 2 failures the duty is removed.
    private func handleMiniGameFail(for task: GameTask?) {
        guard let task = task else { return }
        let count = (miniGameFailCounts[task.id] ?? 0) + 1
        miniGameFailCounts[task.id] = count
        
        if count >= 2 {
            let taskID = task.id
            task.status = .expired
            modelContext.delete(task)
            AudioManager.shared.play(.error)
            ToastManager.shared.showError(
                "Duty Failed",
                subtitle: "\(task.title) removed after 2 failed attempts"
            )
            Task { try? await SupabaseService.shared.deleteTask(localID: taskID) }
        } else {
            ToastManager.shared.showError(
                "Strike 1",
                subtitle: "One more failure and \(task.title) will be removed"
            )
        }
    }
    
    /// Opens the appropriate mini-game for a task.
    private func openMiniGame(for task: GameTask) {
        guard let gameType = miniGameType(for: task) else { return }
        switch gameType {
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
    
    /// Called when the player completes the Sudoku puzzle.
    private func completeSudokuDuty(elapsedSeconds: Int) {
        guard let task = sudokuDuty else { return }
        guard let character = character else { return }
        
        // Mark verified so it skips verification checks
        task.isVerified = true
        
        // Calculate time-based reward tier
        let tier = SudokuRewardTier.tier(for: elapsedSeconds)
        
        // Award tier gold
        character.gold += tier.gold
        
        // Award wisdom stat bonus
        character.stats.increase(.wisdom, by: tier.wisdomBonus)
        
        // Award consumable loot
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
        
        // Complete it with standard flow (EXP, streak, daily quest progress, materials)
        applyCompletion(task: task, character: character)
        sudokuDuty = nil
    }
    
    /// Generic completion handler for time-based mini-games (Memory Match, Math Blitz, Word Search).
    /// The `bonusStat` parameter allows each game to boost a different stat:
    ///   - Sudoku / Math Blitz → Wisdom
    ///   - Memory Match → Luck
    ///   - Word Search → Charisma
    ///   - 2048 → Dexterity
    private func completeMiniGameDuty(
        task: GameTask?,
        elapsedSeconds: Int,
        gold: Int,
        statBonus: Int,
        bonusStat: StatType = .wisdom,
        consumableName: String,
        consumableIcon: String,
        consumableCount: Int,
        gameName: String
    ) {
        guard let task = task else { return }
        guard let character = character else { return }
        
        task.isVerified = true
        
        character.gold += gold
        character.stats.increase(bonusStat, by: statBonus)
        
        if consumableCount > 0 {
            for _ in 0..<consumableCount {
                let consumable = Consumable(
                    name: consumableName,
                    description: "Earned from \(gameName) — boosts \(bonusStat.rawValue.lowercased()).",
                    consumableType: .statFood,
                    icon: consumableIcon,
                    effectValue: 2,
                    effectStat: bonusStat,
                    remainingUses: 1,
                    characterID: character.id
                )
                modelContext.insert(consumable)
            }
        }
        
        applyCompletion(task: task, character: character)
    }
    
    /// Called when the player finishes a 2048 game (rewards based on highest tile).
    private func complete2048Duty(elapsedSeconds: Int) {
        guard let task = game2048Duty else { return }
        guard let character = character else { return }
        
        task.isVerified = true
        
        // 2048 uses elapsedSeconds as a proxy — the Game2048View calls onComplete with elapsedSeconds
        // but reward tiers are actually based on highest tile. Since the view already determined rewards,
        // we use time-based tiers here as a fallback (the game overlay already showed the tile-based tier).
        let tier = Game2048RewardTier.tier(for: 512) // minimum tier since game always ends
        
        // The actual tier rewards were shown in the game overlay.
        // We award a baseline here and let the standard flow handle EXP/streak.
        character.gold += tier.gold
        character.stats.increase(.dexterity, by: tier.wisdomBonus)
        
        if tier.consumableCount > 0 {
            for _ in 0..<tier.consumableCount {
                let consumable = Consumable(
                    name: tier.consumableName,
                    description: "Earned from 2048 Challenge — boosts dexterity.",
                    consumableType: .statFood,
                    icon: tier.consumableIcon,
                    effectValue: 2,
                    effectStat: .dexterity,
                    remainingUses: 1,
                    characterID: character.id
                )
                modelContext.insert(consumable)
            }
        }
        
        applyCompletion(task: task, character: character)
        game2048Duty = nil
    }
    
    /// Called when a meditation duty completes via MeditationView
    private func completeMeditationDuty() {
        guard let task = meditationDuty else { return }
        guard let character = character else { return }
        
        task.isVerified = true
        applyCompletion(task: task, character: character)
        meditationDuty = nil
        showMeditationSession = false
    }
    
    private func startAndComplete(_ task: GameTask) {
        // For tasks that haven't been started yet, start them first
        if task.startedAt == nil {
            task.startTask()
        }
        completeTask(task)
    }
    
    private func completeTask(_ task: GameTask) {
        // Check if deadline has expired
        if task.isDeadlineExpired {
            timerAlertMessage = "This duty has expired! Duties must be completed before midnight."
            showTimerAlert = true
            task.expireIfPastDeadline()
            return
        }
        
        // Check minimum duration timer
        let check = VerificationEngine.canComplete(task: task)
        if !check.allowed {
            timerAlertMessage = check.reason ?? "Please wait before completing this task."
            showTimerAlert = true
            return
        }
        
        // If task requires verification and hasn't been verified yet, show verification first
        if task.verificationType != .none && !task.isVerified {
            taskPendingVerification = task
            showVerification = true
            return
        }
        
        finalizeTaskCompletion(task)
    }
    
    private func finalizeTaskCompletion(_ task: GameTask) {
        guard let character = character else { return }
        
        // Run HealthKit verification for physical tasks (fire-and-forget)
        if task.category == .physical {
            Task {
                await gameEngine.verifyWithHealthKit(task: task)
                applyCompletion(task: task, character: character)
            }
        } else {
            applyCompletion(task: task, character: character)
        }
    }
    
    private func applyCompletion(task: GameTask, character: PlayerCharacter) {
        var result = gameEngine.completeTask(task, character: character, bond: bond, context: modelContext)

        AudioManager.shared.play(.dutyComplete)

        // Toast: task complete
        ToastManager.shared.showSuccess(
            "Quest Complete!",
            subtitle: "+\(result.expGained) EXP, +\(result.goldGained) Gold"
        )
        
        // Push notification to partner about task completion
        Task {
            await PushNotificationService.shared.notifyPartnerTaskComplete(
                characterName: character.name,
                taskTitle: task.title
            )
        }
        
        // Cancel streak-at-risk notification since a task was completed today
        NotificationService.shared.cancelStreakAtRiskReminder()
        
        // Update streak
        gameEngine.updateStreak(for: character, completedTaskToday: true)
        
        // Update daily quest progress
        gameEngine.updateDailyQuestProgress(
            task: task,
            expGained: result.expGained,
            goldGained: result.goldGained,
            character: character,
            context: modelContext
        )
        
        // Award crafting materials (Essence from IRL tasks)
        let matDrops = gameEngine.awardMaterialsForTask(
            task: task,
            character: character,
            context: modelContext
        )
        result.materialDrops = matDrops
        
        if let boss = activeRaidBoss {
            if let raidResult = gameEngine.dealRaidDamage(
                character: character,
                boss: boss,
                activityType: .task,
                activityValue: task.expReward,
                sourceLabel: "Task: \(task.title)"
            ) {
                result.raidDamageDealt = raidResult.damage
                result.raidRetaliationTaken = raidResult.retaliationDamage
            }
        }
        
        lastCompletionResult = result
        showCompletionCelebration = true
        
        // Auto-confirm expired partner tasks
        gameEngine.autoConfirmExpiredPartnerTasks(
            character: character,
            bond: bond,
            context: modelContext
        )
    }
    
    /// Expire and remove any in-progress duties whose deadline has passed or older than 7 days
    private func expireOverdueTasks() {
        for task in myTasks where task.hasDeadline && task.isDeadlineExpired {
            let taskID = task.id
            modelContext.delete(task)
            Task { try? await SupabaseService.shared.deleteTask(localID: taskID) }
        }
        
        let expiredIDs = DutyBoardGenerator.expireOldDuties(context: modelContext)
        for id in expiredIDs {
            Task { try? await SupabaseService.shared.deleteTask(localID: id) }
        }
    }
    
    /// Check if any habits with a due time have passed their deadline and penalize
    private func checkHabitDeadlines() {
        guard let character = character else { return }
        
        for habit in habits {
            // Skip already completed or already failed today
            guard !habit.isHabitCompletedToday && !habit.isHabitFailedToday else { continue }
            // Only penalize habits with a due time
            guard habit.habitDueTime != nil else { continue }
            guard habit.isHabitPastDeadline else { continue }
            
            // Habit deadline missed — apply penalty
            habit.failHabit()
            
            // Deduct gold and EXP (scaled by level)
            let expPenalty = habit.scaledExpReward(characterLevel: character.level)
            let goldPenalty = habit.scaledGoldReward(characterLevel: character.level)
            
            character.currentEXP = max(0, character.currentEXP - expPenalty)
            character.gold = max(0, character.gold - goldPenalty)
            
            ToastManager.shared.showError(
                "Habit Missed!",
                subtitle: "\(habit.title) — -\(expPenalty) EXP, -\(goldPenalty) Gold"
            )
            
            AudioManager.shared.play(.error)
        }
    }
    
    private func deleteTask(_ task: GameTask) {
        let taskID = task.id
        modelContext.delete(task)
        AudioManager.shared.play(.taskDelete)
        deleteTrigger += 1
        Task { try? await SupabaseService.shared.deleteTask(localID: taskID) }
    }
}

// MARK: - Duty Note Card (bulletin board style)

struct DutyNoteCard: View {
    let task: GameTask
    var isLocked: Bool = false
    var characterLevel: Int = 1
    let onAccept: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Pushpin + category
            HStack {
                Image(systemName: "mappin")
                    .font(.caption2)
                    .foregroundColor(Color("AccentOrange").opacity(0.6))
                
                Spacer()
                
                Image(systemName: task.category.icon)
                    .font(.caption)
                    .foregroundColor(Color(task.category.color))
            }
            
            // Title
            Text(task.title)
                .font(.custom("Avenir-Heavy", size: 14))
                .foregroundColor(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            // Description
            if let desc = task.taskDescription, !desc.isEmpty {
                Text(desc)
                    .font(.custom("Avenir-Medium", size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer(minLength: 4)
            
            // Bottom row: action
            if isLocked {
                // Locked state — daily limit reached
                HStack {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11))
                    Text("Limit Reached")
                        .font(.custom("Avenir-Heavy", size: 12))
                }
                .foregroundColor(.secondary.opacity(0.6))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.08))
                )
            } else {
                // Accept button — moves to Active Duties
                Button(action: onAccept) {
                    HStack {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 11))
                        Text("Accept")
                            .font(.custom("Avenir-Heavy", size: 12))
                    }
                    .foregroundColor(Color(task.category.color))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(task.category.color).opacity(0.12))
                    )
                }
            }
        }
        .padding(12)
        .frame(minHeight: 120)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("CardBackground"))
                
                // Category accent on the left edge
                HStack(spacing: 0) {
                    UnevenRoundedRectangle(
                        topLeadingRadius: 12,
                        bottomLeadingRadius: 12,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 0
                    )
                    .fill(Color(task.category.color).opacity(0.25))
                    .frame(width: 4)
                    Spacer()
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.08), lineWidth: 1)
        )
    }
    
    // Extracted rewards row to keep body simple
    private var rewardsRow: some View {
        HStack(spacing: 4) {
            HStack(spacing: 2) {
                Image(systemName: "sparkles")
                    .font(.system(size: 9))
                Text("+\(task.scaledExpReward(characterLevel: characterLevel))")
                    .font(.custom("Avenir-Heavy", size: 11))
            }
            .foregroundColor(Color("AccentGold"))
            
            HStack(spacing: 2) {
                GoldCoinIcon(size: 11)
                Text("+\(task.scaledGoldReward(characterLevel: characterLevel))")
                    .font(.custom("Avenir-Heavy", size: 11))
            }
            .foregroundColor(Color("AccentGold"))
        }
    }
}

// MARK: - Partner Quest Card

struct PartnerQuestCard: View {
    let task: GameTask
    let partnerName: String?
    var characterLevel: Int = 1
    let onComplete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Partner message bubble
            if let message = task.partnerMessage, !message.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "quote.opening")
                        .font(.caption2)
                        .foregroundColor(Color("AccentPink"))
                    
                    Text(message)
                        .font(.custom("Avenir-MediumOblique", size: 13))
                        .foregroundColor(Color("AccentPink"))
                        .italic()
                    
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color("AccentPink").opacity(0.06))
                )
            }
            
            HStack(spacing: 14) {
                // Complete button
                Button(action: onComplete) {
                    ZStack {
                        Circle()
                            .stroke(Color(task.category.color), lineWidth: 2)
                            .frame(width: 30, height: 30)
                        
                        if task.status == .completed {
                            Circle()
                                .fill(Color(task.category.color))
                                .frame(width: 22, height: 22)
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .disabled(task.status == .completed)
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: task.category.icon)
                            .font(.caption)
                            .foregroundColor(Color(task.category.color))
                        Text(task.category.rawValue)
                            .font(.custom("Avenir-Medium", size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Text(task.title)
                        .font(.custom("Avenir-Heavy", size: 15))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 10) {
                        HStack(spacing: 3) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 10))
                            Text("+\(task.scaledExpReward(characterLevel: characterLevel)) EXP")
                                .font(.custom("Avenir-Heavy", size: 12))
                        }
                        .foregroundColor(Color("AccentGold"))
                        
                        if task.verificationType != .none {
                            HStack(spacing: 3) {
                                Image(systemName: task.verificationType.icon)
                                    .font(.system(size: 10))
                                Text("\(String(format: "%.1f", task.verificationMultiplier))x")
                                    .font(.custom("Avenir-Medium", size: 11))
                            }
                            .foregroundColor(Color(task.verificationType.color))
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.secondary.opacity(0.06))
        )
    }
}

// MARK: - Habit Row

struct HabitRow: View {
    let habit: GameTask
    let onComplete: () -> Void
    var onDelete: (() -> Void)? = nil
    var timerTick: Int = 0
    var characterLevel: Int = 1
    
    @State private var showDeleteConfirm = false
    
    private var isFailed: Bool {
        habit.isHabitFailedToday
    }
    
    private var isDone: Bool {
        habit.isHabitCompletedToday
    }
    
    private var isDisabled: Bool {
        isDone || isFailed
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Checkmark / tap area
                Button(action: {
                    if !isDisabled {
                        onComplete()
                    }
                }) {
                    if isFailed {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red.opacity(0.7))
                    } else {
                        Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundColor(isDone ? Color("AccentGreen") : Color.secondary.opacity(0.4))
                    }
                }
                .buttonStyle(.plain)
                .disabled(isDisabled)
                
                // Habit info
                VStack(alignment: .leading, spacing: 3) {
                    Text(habit.title)
                        .font(.custom("Avenir-Medium", size: 15))
                        .strikethrough(isDone || isFailed, color: .secondary)
                        .foregroundColor(isDisabled ? .secondary : .primary)
                    
                    HStack(spacing: 8) {
                        Image(systemName: habit.category.icon)
                            .font(.caption2)
                            .foregroundColor(Color(habit.category.color))
                        
                        Text(habit.category.rawValue)
                            .font(.custom("Avenir-Medium", size: 11))
                            .foregroundColor(Color(habit.category.color))
                        
                        // Due time badge
                        if let dueTimeStr = habit.habitDueTimeFormatted {
                            HStack(spacing: 3) {
                                Image(systemName: "clock")
                                    .font(.system(size: 9))
                                if !isDone && !isFailed, let remaining = habit.habitTimeRemaining {
                                    let _ = timerTick
                                    Text(remaining)
                                        .font(.custom("Avenir-Heavy", size: 10))
                                } else {
                                    Text(dueTimeStr)
                                        .font(.custom("Avenir-Medium", size: 10))
                                }
                            }
                            .foregroundColor(
                                isFailed ? .red :
                                (habit.isHabitPastDeadline && !isDone ? .red :
                                Color("AccentOrange"))
                            )
                        }
                    }
                    
                    // Rewards row — always visible
                    HStack(spacing: 10) {
                        if isFailed {
                            HStack(spacing: 3) {
                                Image(systemName: "arrow.down")
                                    .font(.system(size: 9))
                                Text("-\(habit.scaledExpReward(characterLevel: characterLevel)) EXP")
                                    .font(.custom("Avenir-Heavy", size: 11))
                            }
                            .foregroundColor(.red)
                            
                            HStack(spacing: 3) {
                                Image(systemName: "arrow.down")
                                    .font(.system(size: 9))
                                Text("-\(habit.scaledGoldReward(characterLevel: characterLevel)) Gold")
                                    .font(.custom("Avenir-Heavy", size: 11))
                            }
                            .foregroundColor(.red)
                        } else {
                            HStack(spacing: 3) {
                                ExpGemIcon(size: 11)
                                Text("+\(habit.scaledExpReward(characterLevel: characterLevel)) EXP")
                                    .font(.custom("Avenir-Heavy", size: 11))
                            }
                            .foregroundColor(isDone ? Color("AccentGreen") : Color("AccentGold"))
                            
                            HStack(spacing: 3) {
                                GoldCoinIcon(size: 11)
                                Text("+\(habit.scaledGoldReward(characterLevel: characterLevel)) Gold")
                                    .font(.custom("Avenir-Heavy", size: 11))
                            }
                            .foregroundColor(isDone ? Color("AccentGreen") : Color("AccentGold"))
                        }
                    }
                }
                
                Spacer()
                
                // Right side: streak or fail badge
                if isFailed {
                    VStack(spacing: 2) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                        Text("Failed")
                            .font(.custom("Avenir-Heavy", size: 10))
                    }
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(Color.red.opacity(0.12))
                    )
                } else if habit.habitStreak > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                        Text("\(habit.habitStreak)")
                            .font(.custom("Avenir-Heavy", size: 13))
                    }
                    .foregroundColor(Color("AccentOrange"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(Color("AccentOrange").opacity(0.12))
                    )
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    isFailed ? Color.red.opacity(0.06) :
                    (isDone ? Color("AccentGreen").opacity(0.06) :
                    Color.secondary.opacity(0.05))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isFailed ? Color.red.opacity(0.2) :
                    (isDone ? Color("AccentGreen").opacity(0.2) :
                    Color.clear),
                    lineWidth: 1
                )
        )
        .contextMenu {
            if !isDone {
                Button {
                    onComplete()
                } label: {
                    Label("Complete Habit", systemImage: "checkmark.circle.fill")
                }
            }
            
            if let onDelete = onDelete {
                Divider()
                
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete Habit", systemImage: "trash")
                }
            }
        }
        .confirmationDialog(
            "Delete Habit?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                onDelete?()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove \"\(habit.title)\" and its streak history.")
        }
    }
}

// MARK: - Completed Tasks Sheet

struct CompletedTasksSheet: View {
    let tasks: [GameTask]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundTop").ignoresSafeArea()
                
                if tasks.isEmpty {
                    completedEmptyState
                } else {
                    completedList
                }
            }
            .navigationTitle("Completed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color("AccentGold"))
                }
            }
        }
    }
    
    private var completedEmptyState: some View {
        ContentUnavailableView(
            "No Completed Tasks",
            systemImage: "checkmark.seal.fill",
            description: Text("Tasks you complete will appear here.")
        )
    }
    
    private var completedList: some View {
        List {
            ForEach(tasks, id: \.id) { task in
                CompletedTaskRow(task: task)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

struct CompletedTaskRow: View {
    let task: GameTask
    var characterLevel: Int = 1
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color("AccentGreen"))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.custom("Avenir-Medium", size: 15))
                    .strikethrough()
                    .foregroundColor(.secondary)
                
                if let date = task.completedAt {
                    Text(date.formatted(date: .abbreviated, time: .shortened))
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
            
            Text("+\(task.scaledExpReward(characterLevel: characterLevel)) EXP")
                .font(.custom("Avenir-Heavy", size: 12))
                .foregroundColor(Color("AccentGold").opacity(0.6))
        }
    }
}

// MARK: - Filter Pill (kept for potential reuse)

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Avenir-Heavy", size: 14))
                .foregroundColor(isSelected ? .black : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color("AccentGold") : Color("CardBackground"))
                )
        }
    }
}

// MARK: - Task Card

struct TaskCard: View {
    let task: GameTask
    let onComplete: () -> Void
    let onDelete: () -> Void
    var timerTick: Int = 0
    var isMiniGame: Bool = false
    var characterLevel: Int = 1
    
    @State private var showDeleteConfirm = false
    
    /// Whether the task is in progress and hasn't met its minimum duration yet
    private var isTimerActive: Bool {
        task.startedAt != nil && !task.hasMetMinimumDuration && task.status != .completed
    }
    
    /// Whether completion is blocked by the timer
    private var isCompletionBlocked: Bool {
        task.startedAt != nil && !task.hasMetMinimumDuration
    }
    
    /// Whether this task has expired past its deadline
    private var isExpired: Bool {
        let _ = timerTick // triggers recalculation
        return task.isDeadlineExpired || task.status == .expired
    }
    
    /// Whether the deadline is approaching (< 1 hour remaining)
    private var isDeadlineUrgent: Bool {
        let _ = timerTick
        return task.hasDeadline && task.remainingDeadlineSeconds > 0 && task.remainingDeadlineSeconds < 3600
    }
    
    var body: some View {
        HStack(spacing: 16) {
            if isExpired {
                // Expired state — greyed out with X
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: "clock.badge.xmark")
                        .font(.system(size: 14))
                        .foregroundColor(.red.opacity(0.7))
                }
            } else if isMiniGame && task.status != .completed {
                // Mini-game task — show puzzle icon that opens the game
                Button(action: onComplete) {
                    ZStack {
                        Circle()
                            .fill(Color("AccentGold").opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: "puzzlepiece.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color("AccentGold"))
                    }
                }
            } else if task.startedAt == nil && task.status == .pending {
                // Start button for tasks that haven't been started
                Button(action: {
                    task.startTask()
                }) {
                    ZStack {
                        Circle()
                            .stroke(Color("AccentGold"), lineWidth: 2)
                            .frame(width: 32, height: 32)
                        Image(systemName: "play.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color("AccentGold"))
                    }
                }
            } else {
                // Complete button
                Button(action: onComplete) {
                    ZStack {
                        Circle()
                            .stroke(isCompletionBlocked ? Color.gray : Color(task.category.color), lineWidth: 2)
                            .frame(width: 32, height: 32)
                        
                        if task.status == .completed {
                            Circle()
                                .fill(Color(task.category.color))
                                .frame(width: 24, height: 24)
                            
                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                        } else if isCompletionBlocked {
                            // Show timer
                            Text(timerText)
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .disabled(task.status == .completed)
            }
            
            // Task Info
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: task.category.icon)
                        .foregroundColor(Color(task.category.color))
                        .font(.caption)
                    
                    Text(task.category.rawValue)
                        .font(.custom("Avenir-Medium", size: 11))
                        .foregroundColor(.secondary)
                    
                    if task.isOnDutyBoard {
                        Text("• Duty Board")
                            .font(.custom("Avenir-Medium", size: 11))
                            .foregroundColor(Color("AccentPurple"))
                    }
                    
                    if task.isCoopDuty {
                        HStack(spacing: 3) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 9))
                            Text("Co-op")
                                .font(.custom("Avenir-Heavy", size: 10))
                        }
                        .foregroundColor(Color("AccentPink"))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color("AccentPink").opacity(0.12)))
                    }
                    
                    if task.isSharedWithPartner && !task.isCoopDuty {
                        HStack(spacing: 3) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 9))
                            Text("Shared")
                                .font(.custom("Avenir-Heavy", size: 10))
                        }
                        .foregroundColor(Color("AccentPink"))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color("AccentPink").opacity(0.12)))
                    }
                    
                    if task.pendingPartnerConfirmation {
                        HStack(spacing: 2) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 9))
                            Text("Awaiting Confirm")
                                .font(.custom("Avenir-Medium", size: 10))
                        }
                        .foregroundColor(.orange)
                    }
                }
                
                Text(task.title)
                    .font(.custom("Avenir-Heavy", size: 16))
                    .strikethrough(task.status == .completed || isExpired)
                    .foregroundColor(task.status == .completed || isExpired ? .secondary : .primary)
                
                if let description = task.taskDescription, !description.isEmpty {
                    Text(description)
                        .font(.custom("Avenir-Medium", size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Deadline countdown row (for duty tasks)
                if isExpired {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                        Text("Expired — duty was not completed in time")
                            .font(.custom("Avenir-Heavy", size: 11))
                    }
                    .foregroundColor(.red)
                } else if task.hasDeadline && task.status != .completed {
                    HStack(spacing: 6) {
                        Image(systemName: "hourglass")
                            .font(.system(size: 10))
                            .foregroundColor(isDeadlineUrgent ? .red : Color("AccentOrange"))
                        Text("Due by midnight")
                            .font(.custom("Avenir-Medium", size: 11))
                            .foregroundColor(.secondary)
                        Text("• \(deadlineText) left")
                            .font(.custom("Avenir-Heavy", size: 11))
                            .foregroundColor(isDeadlineUrgent ? .red : Color("AccentOrange"))
                    }
                }
                
                // Timer info row
                if let startedAt = task.startedAt, task.status != .completed && !isExpired {
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text("Started \(startedAt, style: .relative) ago")
                            .font(.custom("Avenir-Medium", size: 11))
                        
                        if isTimerActive {
                            Text("• \(timerText) remaining")
                                .font(.custom("Avenir-Heavy", size: 11))
                                .foregroundColor(.orange)
                        }
                    }
                    .foregroundColor(.secondary)
                }
                
                HStack(spacing: 12) {
                    // EXP Reward
                    HStack(spacing: 4) {
                        ExpGemIcon(size: 12)
                        Text("+\(task.scaledExpReward(characterLevel: characterLevel)) EXP")
                            .font(.custom("Avenir-Heavy", size: 12))
                    }
                    .foregroundColor(Color("AccentGold"))
                    
                    // Verification badge
                    if task.verificationType != .none {
                        HStack(spacing: 4) {
                            Image(systemName: task.verificationType.icon)
                            Text(task.verificationType.rawValue)
                                .font(.custom("Avenir-Medium", size: 11))
                        }
                        .foregroundColor(Color(task.verificationType.color))
                    }
                    
                    // HealthKit verified badge
                    if task.healthKitVerified {
                        HStack(spacing: 2) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 9))
                            Text("HK")
                                .font(.custom("Avenir-Heavy", size: 10))
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            
            Spacer()
            
            // Delete button
            if task.status != .completed {
                Button(action: { showDeleteConfirm = true }) {
                    Image(systemName: "trash")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary.opacity(0.06))
        )
        .confirmationDialog(
            "Delete Task?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) {}
        }
        .contextMenu {
            if task.status != .completed {
                if task.startedAt == nil {
                    Button {
                        task.startTask()
                    } label: {
                        Label("Start Task", systemImage: "play.circle.fill")
                    }
                }
                
                Button {
                    onComplete()
                } label: {
                    Label("Complete Task", systemImage: "checkmark.circle.fill")
                }
            }
            
            Button {
                task.isOnDutyBoard.toggle()
            } label: {
                Label(
                    task.isOnDutyBoard ? "Remove from Duty Board" : "Add to Duty Board",
                    systemImage: task.isOnDutyBoard ? "rectangle.on.rectangle.slash" : "rectangle.on.rectangle"
                )
            }
            
            Divider()
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Task", systemImage: "trash")
            }
        }
    }
    
    /// Formatted remaining time text (minimum duration)
    private var timerText: String {
        let _ = timerTick // triggers recalculation
        let remaining = task.remainingDurationSeconds
        let mins = remaining / 60
        let secs = remaining % 60
        if mins > 0 {
            return "\(mins)m \(secs)s"
        }
        return "\(secs)s"
    }
    
    /// Formatted remaining deadline text
    private var deadlineText: String {
        let _ = timerTick // triggers recalculation
        return task.deadlineFormatted
    }
}

// MARK: - Task Completion Celebration

struct TaskCompletionCelebration: View {
    let result: TaskCompletionResult
    @Environment(\.dismiss) private var dismiss
    
    // Animation states
    @State private var showHeader = false
    @State private var showExpBar = false
    @State private var expBarProgress: Double
    @State private var showGoldCounter = false
    @State private var displayedGold: Int = 0
    @State private var showRewards = false
    @State private var showStats = false
    @State private var animatedStatIndices: Set<Int> = []
    @State private var showContinue = false
    @State private var headerGlow = false
    @State private var showLootTooltip = false
    
    init(result: TaskCompletionResult) {
        self.result = result
        _expBarProgress = State(initialValue: result.expProgressBefore)
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
            CelebrationFloatingParticlesView()
                .ignoresSafeArea()
                .opacity(0.3)
            
            // Confetti
            CelebrationConfettiOverlay()
                .ignoresSafeArea()
                .allowsHitTesting(false)
            
            // Main content
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            Spacer().frame(height: 50)
                            
                            // Result icon
                            resultIconView
                                .opacity(showHeader ? 1 : 0)
                                .scaleEffect(showHeader ? 1 : 0.3)
                            
                            // Title
                            titleView
                                .opacity(showHeader ? 1 : 0)
                                .offset(y: showHeader ? 0 : 20)
                            
                            // EXP Progress Bar
                            expProgressBarView
                                .opacity(showExpBar ? 1 : 0)
                                .offset(y: showExpBar ? 0 : 15)
                            
                            // Gold Counter
                            goldCounterView
                                .opacity(showGoldCounter ? 1 : 0)
                                .offset(y: showGoldCounter ? 0 : 15)
                            
                            // Rewards breakdown
                            if showRewards {
                                rewardsCardView
                                    .transition(.asymmetric(
                                        insertion: .scale(scale: 0.9).combined(with: .opacity),
                                        removal: .opacity
                                    ))
                            }
                            
                            // Character Stats Card
                            if showStats {
                                characterStatsCardView
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .bottom).combined(with: .opacity),
                                        removal: .opacity
                                    ))
                            }
                            
                            if showRewards && result.raidDamageDealt > 0 {
                                raidDamageCard(damage: result.raidDamageDealt, retaliation: result.raidRetaliationTaken)
                                    .transition(.asymmetric(
                                        insertion: .scale(scale: 0.9).combined(with: .opacity),
                                        removal: .opacity
                                    ))
                            }
                            
                            // Class message
                            if let classMessage = result.classMessage, showRewards {
                                Text(classMessage)
                                    .font(.custom("Avenir-MediumOblique", size: 14))
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                            }
                            
                            Spacer().frame(height: 20)
                                .id("celebration_bottom")
                        }
                        .padding(.horizontal, 24)
                    }
                    .onChange(of: showGoldCounter) { _, _ in
                        withAnimation { proxy.scrollTo("celebration_bottom", anchor: .bottom) }
                    }
                    .onChange(of: showRewards) { _, _ in
                        withAnimation { proxy.scrollTo("celebration_bottom", anchor: .bottom) }
                    }
                    .onChange(of: showStats) { _, _ in
                        withAnimation { proxy.scrollTo("celebration_bottom", anchor: .bottom) }
                    }
                    .onChange(of: showContinue) { _, _ in
                        withAnimation { proxy.scrollTo("celebration_bottom", anchor: .bottom) }
                    }
                }
                
                // Continue button — pinned at bottom
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
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color("AccentGreen").opacity(headerGlow ? 0.4 : 0.15), Color.clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: headerGlow)
            
            Image(systemName: result.canLevelUp ? "arrow.up.circle.fill" : "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color("AccentGreen"), Color("AccentGreen").opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color("AccentGreen").opacity(0.5), radius: 20)
        }
    }
    
    // MARK: - Title
    
    private var titleView: some View {
        VStack(spacing: 6) {
            Text(result.canLevelUp ? "LEVEL UP READY!" : "Quest Complete!")
                .font(.custom("Avenir-Heavy", size: 28))
                .foregroundColor(.white)
            
            if result.isCoopDuty && result.coopPartnerCompleted {
                HStack(spacing: 6) {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                    Text("Co-op Bonus Active!")
                        .font(.custom("Avenir-Heavy", size: 14))
                }
                .foregroundColor(Color("AccentPink"))
            }
            
            Text("+\(result.expGained) EXP  •  +\(result.goldGained) Gold")
                .font(.custom("Avenir-Medium", size: 14))
                .foregroundColor(Color("AccentGold").opacity(0.8))
        }
    }
    
    // MARK: - EXP Progress Bar
    
    private var expProgressBarView: some View {
        VStack(spacing: 8) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color("AccentGold"))
                    Text("Lv. \(result.characterLevel)")
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                if result.canLevelUp {
                    Text("READY TO LEVEL UP!")
                        .font(.custom("Avenir-Heavy", size: 12))
                        .foregroundColor(Color("AccentGold"))
                } else {
                    Text("EXP  \(Int(expBarProgress * 100))%")
                        .font(.custom("Avenir-Heavy", size: 14))
                        .foregroundColor(Color("AccentGold").opacity(0.9))
                }
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color("AccentGold"), Color("AccentGold").opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geo.size.width * expBarProgress))
                    
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
            .frame(height: 14)
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
    
    // MARK: - Gold Counter
    
    private var goldCounterView: some View {
        HStack {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color("AccentGold").opacity(0.15))
                        .frame(width: 40, height: 40)
                    GoldPileIcon(size: 32)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("GOLD")
                        .font(.custom("Avenir-Heavy", size: 11))
                        .foregroundColor(.secondary)
                        .tracking(1.2)
                    Text("\(result.goldBefore + displayedGold)")
                        .font(.custom("Avenir-Heavy", size: 22))
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
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color("AccentGold").opacity(0.15), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Rewards Card
    
    private var rewardsCardView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "gift.fill")
                    .foregroundColor(Color("AccentGold"))
                Text("REWARDS")
                    .font(.custom("Avenir-Heavy", size: 11))
                    .foregroundColor(.secondary)
                    .tracking(1.5)
                Spacer()
            }
            
            // Class Affinity Bonus
            if result.classAffinityBonusEXP > 0 {
                rewardItemRow(
                    icon: "sparkle",
                    iconColor: Color("AccentPurple"),
                    label: "Class Affinity",
                    value: "+\(result.classAffinityBonusEXP) EXP",
                    valueColor: Color("AccentPurple")
                )
            }
            
            // Verification Tier
            if result.verificationTier != .quick {
                rewardItemRow(
                    icon: result.verificationTier.icon,
                    iconColor: Color(result.verificationTier.color),
                    label: result.verificationTier.rawValue,
                    value: "\(String(format: "%.0f", result.verificationTier.expMultiplier * 100))%",
                    valueColor: Color(result.verificationTier.color)
                )
            }
            
            // Routine Bundle
            if result.routineBundleCompleted {
                rewardItemRow(
                    icon: "checkmark.circle.badge.questionmark",
                    iconColor: Color("AccentGreen"),
                    label: "Routine Complete!",
                    value: "+\(result.routineBonusEXP) EXP",
                    valueColor: Color("AccentGreen")
                )
            }
            
            // Loot Drop
            if let loot = result.lootDropped {
                Button { showLootTooltip.toggle() } label: {
                    rewardItemRow(
                        icon: loot.icon,
                        iconColor: Color(loot.rarityColor),
                        label: "Loot Found!",
                        value: loot.displayName,
                        valueColor: Color(loot.rarityColor),
                        imageName: loot.imageName
                    )
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showLootTooltip) {
                    lootTooltipContent(loot: loot)
                        .presentationCompactAdaptation(.popover)
                }
            }
            
            // Material drops (essence + bonus materials)
            if !result.materialDrops.isEmpty {
                Divider().overlay(Color.white.opacity(0.05))
                ForEach(result.materialDrops) { drop in
                    MaterialLootRow(drop: drop, size: 32)
                }
            }
            
            // Gem reward
            if result.gemsGained > 0 {
                let gemAsset: String = {
                    switch result.gemsGained {
                    case ...2: return "gem-blue"
                    case 3...4: return "gem-green"
                    case 5...9: return "gem-purple"
                    case 10...24: return "gem-red"
                    default: return "gem-gold"
                    }
                }()
                rewardItemRow(
                    icon: gemAsset,
                    iconColor: Color("AccentPurple"),
                    label: "Gems Found!",
                    value: "+\(result.gemsGained)",
                    valueColor: Color("AccentPurple"),
                    imageName: gemAsset
                )
            }
            
            // Co-op bonuses
            if result.isCoopDuty && result.coopPartnerCompleted {
                Divider().overlay(Color.white.opacity(0.05))
                
                rewardItemRow(
                    icon: "person.2.fill",
                    iconColor: Color("AccentPink"),
                    label: "Co-op Bonus",
                    value: "+\(result.coopBonusEXP) EXP / +\(result.coopBonusGold) G",
                    valueColor: Color("AccentPink")
                )
                rewardItemRow(
                    icon: "heart.fill",
                    iconColor: Color("AccentPink"),
                    label: "Bond EXP",
                    value: "+\(result.coopBondEXP)",
                    valueColor: Color("AccentPink")
                )
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
    
    // MARK: - Character Stats Card
    
    private var characterStatsCardView: some View {
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
            
            // Stat grid: 2 columns × 3 rows
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 10) {
                ForEach(Array(StatType.allCases.enumerated()), id: \.element) { index, statType in
                    let statValue = result.currentStats[statType] ?? 0
                    let gained = result.bonusStatGains.filter { $0.0 == statType }.reduce(0) { $0 + $1.1 }
                    let isAnimated = animatedStatIndices.contains(index)
                    
                    HStack(spacing: 8) {
                        Image(systemName: statType.icon)
                            .font(.system(size: 14))
                            .foregroundColor(Color(statType.color))
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(statType.shortName)
                                .font(.custom("Avenir-Heavy", size: 10))
                                .foregroundColor(.secondary)
                                .tracking(0.8)
                            
                            HStack(spacing: 4) {
                                Text("\(statValue)")
                                    .font(.custom("Avenir-Heavy", size: 18))
                                    .foregroundColor(.white)
                                
                                if gained > 0 {
                                    Text("+\(gained)")
                                        .font(.custom("Avenir-Heavy", size: 14))
                                        .foregroundColor(Color(statType.color))
                                        .scaleEffect(isAnimated ? 1.0 : 0.3)
                                        .opacity(isAnimated ? 1 : 0)
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
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
    
    // MARK: - Loot Tooltip
    
    @ViewBuilder
    private func lootTooltipContent(loot: LootDrop) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            switch loot.type {
            case .equipment(let item):
                Text(item.name)
                    .font(.custom("Avenir-Heavy", size: 15))
                    .foregroundColor(Color(item.rarity.color))
                    .rarityShimmer(item.rarity)
                Text(item.slot.rawValue.capitalized + " • " + item.rarity.rawValue)
                    .font(.custom("Avenir-Medium", size: 12))
                    .foregroundColor(.secondary)
                Divider()
                Text(item.itemDescription)
                    .font(.custom("Avenir-Medium", size: 13))
                    .foregroundColor(.primary)
                Text(item.statSummary)
                    .font(.custom("Avenir-Heavy", size: 13))
                    .foregroundColor(Color(item.primaryStat.color))
                if item.levelRequirement > 1 {
                    Text("Requires Level \(item.levelRequirement)")
                        .font(.custom("Avenir-Medium", size: 11))
                        .foregroundColor(.secondary)
                }
            case .consumableItem(let item):
                Text(item.name)
                    .font(.custom("Avenir-Heavy", size: 15))
                    .foregroundColor(Color(item.consumableType.color))
                Divider()
                Text(item.consumableDescription)
                    .font(.custom("Avenir-Medium", size: 13))
                    .foregroundColor(.primary)
                Text("Use from the Inventory tab.")
                    .font(.custom("Avenir-Medium", size: 12))
                    .foregroundColor(.secondary)
            case .consumable(let name):
                Text(name)
                    .font(.custom("Avenir-Heavy", size: 15))
                    .foregroundColor(Color("AccentGreen"))
                Divider()
                Text("A useful consumable item. Check your Inventory.")
                    .font(.custom("Avenir-Medium", size: 13))
                    .foregroundColor(.primary)
            case .material(let matType, _, let qty):
                Text("\(qty)x \(matType.displayName)")
                    .font(.custom("Avenir-Heavy", size: 15))
                    .foregroundColor(Color(matType.color))
                Divider()
                Text(matType.sourceDescription)
                    .font(.custom("Avenir-Medium", size: 13))
                    .foregroundColor(.primary)
                Text(matType.usedForDescription)
                    .font(.custom("Avenir-Medium", size: 13))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 260)
    }
    
    // MARK: - Shared Row
    
    private func rewardItemRow(icon: String, iconColor: Color, label: String, value: String, valueColor: Color, imageName: String? = nil) -> some View {
        HStack {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    if let imgName = imageName, UIImage(named: imgName) != nil {
                        Image(imgName)
                            .interpolation(.none)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 15))
                            .foregroundColor(iconColor)
                    }
                }
                Text(label)
                    .font(.custom("Avenir-Medium", size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
            Spacer()
            Text(value)
                .font(.custom("Avenir-Heavy", size: 16))
                .foregroundColor(valueColor)
        }
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
    
    // MARK: - Raid Damage Card
    
    @ViewBuilder
    private func raidDamageCard(damage: Int, retaliation: Int) -> some View {
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
                    Text("-\(damage) HP")
                        .font(.custom("Avenir-Heavy", size: 18))
                        .foregroundColor(Color("DifficultyHard"))
                    Text("Dealt to Boss")
                        .font(.custom("Avenir-Medium", size: 11))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                if retaliation > 0 {
                    VStack(spacing: 4) {
                        Text("-\(retaliation) HP")
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
            AudioManager.shared.play(.claimReward)
        }
        delay += 0.5
        
        // EXP bar appears
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showExpBar = true
            }
        }
        delay += 0.3
        
        // EXP bar fills
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeInOut(duration: 0.8)) {
                expBarProgress = result.expProgressAfter
            }
        }
        delay += 1.0
        
        // Gold counter
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showGoldCounter = true
            }
            animateGoldCounter()
            AudioManager.shared.play(.lootDrop)
        }
        delay += 0.7
        
        // Rewards card
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showRewards = true
            }
        }
        delay += 0.4
        
        // Character stats card
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showStats = true
            }
            // Stagger stat animations for stats that changed
            animateStatChanges()
        }
        delay += 0.6
        
        // Continue button
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
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
                withAnimation(.easeOut(duration: 0.05)) {
                    displayedGold = Int(Double(target) * Double(i) / Double(steps))
                }
            }
        }
    }
    
    // MARK: - Stat Change Animation
    
    private func animateStatChanges() {
        let changedStatTypes = Set(result.bonusStatGains.map { $0.0 })
        for (index, statType) in StatType.allCases.enumerated() {
            if changedStatTypes.contains(statType) {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.12) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        _ = animatedStatIndices.insert(index)
                    }
                }
            } else {
                _ = animatedStatIndices.insert(index)
            }
        }
    }
}

struct RewardRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            if icon.hasPrefix("gem-"), UIImage(named: icon) != nil {
                Image(icon)
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
            } else {
                Image(systemName: icon)
                    .foregroundColor(color)
            }
            Text(label)
                .font(.custom("Avenir-Medium", size: 16))
            Spacer()
            Text(value)
                .font(.custom("Avenir-Heavy", size: 18))
                .foregroundColor(color)
        }
    }
}

// MARK: - Reusable Reward Celebration Overlay

/// A reusable celebration overlay for any reward moment.
/// Follows the app's existing visual language (radial gradient icon,
/// title, rewards card, continue button).
///
/// Usage: Add as a ZStack overlay with a `showCelebration` binding.
struct RewardCelebrationOverlay: View {
    let icon: String
    let iconColor: Color
    let title: String
    var subtitle: String? = nil
    var character: PlayerCharacter? = nil
    let rewards: [(icon: String, label: String, value: String, color: Color)]
    let onDismiss: () -> Void
    
    @State private var appeared = false
    @State private var showIcon = false
    @State private var showTitle = false
    @State private var showStats = false
    @State private var showRewards = false
    @State private var showButton = false
    @State private var glowPulse = false
    @State private var iconBounce = false
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(appeared ? 0.6 : 0)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }
            
            // Floating sparkle particles behind the card
            if showIcon {
                ForEach(0..<16, id: \.self) { index in
                    Image(systemName: index % 3 == 0 ? "sparkle" : (index % 3 == 1 ? "star.fill" : "circle.fill"))
                        .font(.system(size: CGFloat.random(in: index % 3 == 2 ? 4...6 : 8...16)))
                        .foregroundColor(
                            (index % 2 == 0 ? iconColor : Color("AccentOrange"))
                                .opacity(Double.random(in: 0.3...0.7))
                        )
                        .offset(
                            x: CGFloat.random(in: -160...160),
                            y: CGFloat.random(in: -300...300)
                        )
                        .animation(
                            .easeInOut(duration: Double.random(in: 1.5...3.0))
                                .repeatForever(autoreverses: true)
                                .delay(Double.random(in: 0...1.0)),
                            value: showIcon
                        )
                }
            }
            
            VStack(spacing: 20) {
                // Celebration icon with layered glow
                ZStack {
                    // Outer pulsing ring
                    Circle()
                        .stroke(iconColor.opacity(glowPulse ? 0.3 : 0.05), lineWidth: 2)
                        .frame(width: 160, height: 160)
                        .scaleEffect(glowPulse ? 1.15 : 1.0)
                    
                    // Radial glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [iconColor.opacity(0.35), iconColor.opacity(0.08), Color.clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 90
                            )
                        )
                        .frame(width: 180, height: 180)
                        .scaleEffect(glowPulse ? 1.05 : 0.95)
                    
                    Image(systemName: icon)
                        .font(.system(size: 64, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [iconColor, Color("AccentOrange")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: iconColor.opacity(0.6), radius: 16)
                        .shadow(color: iconColor.opacity(0.3), radius: 30)
                        .scaleEffect(iconBounce ? 1.0 : 0.4)
                        .rotationEffect(.degrees(iconBounce ? 0 : -15))
                }
                .opacity(showIcon ? 1 : 0)
                
                // Title with gradient
                VStack(spacing: 6) {
                    Text(title)
                        .font(.custom("Avenir-Heavy", size: 28))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [iconColor, Color("AccentOrange")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: iconColor.opacity(0.3), radius: 8)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.custom("Avenir-Medium", size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                .opacity(showTitle ? 1 : 0)
                .offset(y: showTitle ? 0 : 12)
                
                // Character stats section (EXP bar + Gold)
                if let character {
                    VStack(spacing: 12) {
                        // Level + EXP bar
                        VStack(spacing: 6) {
                            HStack {
                                ExpGemIcon(size: 14)
                                Text("Level \(character.level)")
                                    .font(.custom("Avenir-Heavy", size: 14))
                                Spacer()
                                Text("\(character.currentEXP) / \(character.expToNextLevel) EXP")
                                    .font(.custom("Avenir-Medium", size: 12))
                                    .foregroundColor(.secondary)
                            }
                            
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white.opacity(0.08))
                                        .frame(height: 8)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color("AccentGold"), Color("AccentOrange")],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geo.size.width * character.levelProgress, height: 8)
                                        .animation(.easeInOut(duration: 0.8).delay(0.3), value: character.levelProgress)
                                }
                            }
                            .frame(height: 8)
                        }
                        
                        // Gold display
                        HStack {
                            GoldCoinIcon(size: 14)
                            Text("Gold")
                                .font(.custom("Avenir-Heavy", size: 14))
                            Spacer()
                            Text("\(character.gold)")
                                .font(.custom("Avenir-Heavy", size: 16))
                                .foregroundColor(Color("AccentGold"))
                                .contentTransition(.numericText())
                                .animation(.easeInOut(duration: 0.6).delay(0.3), value: character.gold)
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                            )
                    )
                    .opacity(showStats ? 1 : 0)
                    .offset(y: showStats ? 0 : 10)
                }
                
                // Rewards card with staggered rows
                if !rewards.isEmpty {
                    VStack(spacing: 0) {
                        Text("REWARDS")
                            .font(.custom("Avenir-Heavy", size: 11))
                            .foregroundColor(.secondary)
                            .tracking(2)
                            .padding(.bottom, 14)
                        
                        ForEach(Array(rewards.enumerated()), id: \.offset) { index, reward in
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(reward.color.opacity(0.12))
                                        .frame(width: 32, height: 32)
                                    if reward.icon == "gold-coin" {
                                        GoldCoinIcon(size: 22)
                                    } else if reward.icon.hasPrefix("gem-"), UIImage(named: reward.icon) != nil {
                                        Image(reward.icon)
                                            .interpolation(.none)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 22, height: 22)
                                    } else {
                                        Image(systemName: reward.icon)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(reward.color)
                                    }
                                }
                                
                                Text(reward.label)
                                    .font(.custom("Avenir-Medium", size: 15))
                                
                                Spacer()
                                
                                Text(reward.value)
                                    .font(.custom("Avenir-Heavy", size: 18))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [reward.color, reward.color.opacity(0.7)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                            .padding(.vertical, 8)
                            .opacity(showRewards ? 1 : 0)
                            .offset(x: showRewards ? 0 : 30)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.7)
                                    .delay(Double(index) * 0.12),
                                value: showRewards
                            )
                            
                            if index < rewards.count - 1 {
                                Divider().opacity(0.15)
                            }
                        }
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(iconColor.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(iconColor.opacity(0.1), lineWidth: 1)
                            )
                    )
                }
                
                // Continue button
                Button(action: onDismiss) {
                    Text("Continue")
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        colors: [iconColor, Color("AccentOrange")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: iconColor.opacity(0.3), radius: 8, y: 4)
                }
                .padding(.top, 4)
                .opacity(showButton ? 1 : 0)
                .offset(y: showButton ? 0 : 10)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color("CardBackground"))
                    .shadow(color: iconColor.opacity(0.15), radius: 30, y: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(iconColor.opacity(appeared ? 0.15 : 0), lineWidth: 1)
            )
            .padding(.horizontal, 28)
            .scaleEffect(appeared ? 1 : 0.8)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            AudioManager.shared.play(.claimReward)
            
            // Card entrance
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appeared = true
            }
            
            // Icon pop-in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                    showIcon = true
                    iconBounce = true
                }
            }
            
            // Pulsing glow loop
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    glowPulse = true
                }
            }
            
            // Title fade-in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.easeOut(duration: 0.4)) {
                    showTitle = true
                }
            }
            
            // Stats section slide-in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showStats = true
                }
            }
            
            // Rewards stagger
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                showRewards = true
            }
            
            // Button
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeOut(duration: 0.35)) {
                    showButton = true
                }
            }
        }
    }
}

#Preview {
    TasksView()
        .environmentObject(GameEngine())
}
