import SwiftUI
import SwiftData

struct TasksView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var gameEngine: GameEngine
    @Query(sort: \GameTask.createdAt, order: .reverse) private var allTasks: [GameTask]
    @Query private var characters: [PlayerCharacter]
    @Query private var bonds: [Bond]
    
    @State private var showCreateTask = false
    @State private var showCompletionCelebration = false
    @State private var lastCompletionResult: TaskCompletionResult?
    @State private var deleteTrigger = 0
    @State private var showCompleted = false
    @State private var dailyDuties: [GameTask] = []
    @State private var showVerification = false
    @State private var taskPendingVerification: GameTask?
    @State private var showTimerAlert = false
    @State private var timerAlertMessage = ""
    @State private var timerTick = 0 // triggers UI refresh for timer countdown
    @State private var showSudoku = false
    @State private var sudokuDuty: GameTask?
    
    private var character: PlayerCharacter? {
        characters.first
    }
    
    private var bond: Bond? {
        bonds.first
    }
    
    /// Partner quests: tasks from partner that aren't completed
    private var partnerQuests: [GameTask] {
        allTasks.filter { $0.isFromPartner && $0.status != .completed && !$0.isDailyDuty }
    }
    
    /// My tasks: user-created tasks that aren't daily duties or from partner
    private var myTasks: [GameTask] {
        allTasks.filter { !$0.isDailyDuty && !$0.isFromPartner && $0.status != .completed }
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
    
    /// How many duties the player has claimed today (accepted + completed)
    private var dutiesClaimedToday: Int {
        dailyDuties.filter { $0.status == .inProgress || $0.status == .completed }.count
    }
    
    /// Whether the player has reached the daily duty selection limit
    private var reachedDailyDutyLimit: Bool {
        dutiesClaimedToday >= DutyBoardGenerator.maxDutySelectionsPerDay
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
                        // 1. Duty Board (front and center)
                        dutyBoardSection
                        
                        // 2. Partner Quests (if any or if partnered)
                        partnerQuestsSection
                        
                        // 3. My Tasks
                        myTasksSection
                        
                        // 4. View Completed
                        viewCompletedButton
                    }
                    .padding()
                }
            }
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreateTask = true }) {
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
            .sheet(isPresented: $showCompletionCelebration) {
                if let result = lastCompletionResult {
                    TaskCompletionCelebration(result: result)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                }
            }
            .sheet(isPresented: $showCompleted) {
                CompletedTasksSheet(tasks: completedTasks)
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
                SudokuGameView {
                    completeSudokuDuty()
                }
            }
            .alert("Not Yet!", isPresented: $showTimerAlert) {
                Button("OK") {}
            } message: {
                Text(timerAlertMessage)
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
            }
        }
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
            
            Text("Pick 1 duty per day — complete it for EXP and gold!")
                .font(.custom("Avenir-Medium", size: 13))
                .foregroundColor(.secondary)
            
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
                            isLocked: reachedDailyDutyLimit,
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
    
    // MARK: - My Tasks Section
    
    private var myTasksSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Image(systemName: "checklist")
                    .font(.callout)
                    .foregroundColor(Color("AccentGold"))
                
                Text("My Tasks")
                    .font(.custom("Avenir-Heavy", size: 18))
                
                Spacer()
                
                Text("\(myTasks.count)")
                    .font(.custom("Avenir-Heavy", size: 14))
                    .foregroundColor(.secondary)
            }
            
            if myTasks.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "plus.square.dashed")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    
                    Text("No tasks yet — create your first!")
                        .font(.custom("Avenir-Medium", size: 14))
                        .foregroundColor(.secondary)
                    
                    Button(action: { showCreateTask = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Create Task")
                        }
                        .font(.custom("Avenir-Heavy", size: 14))
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color("AccentGold"))
                        .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                ForEach(myTasks, id: \.id) { task in
                    if isSudokuDuty(task) {
                        // Sudoku task — tapping opens the game
                        Button {
                            openSudoku(for: task)
                        } label: {
                            TaskCard(
                                task: task,
                                onComplete: { openSudoku(for: task) },
                                onDelete: { deleteTask(task) },
                                timerTick: timerTick,
                                isSudoku: true
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        NavigationLink(destination: TaskDetailView(task: task)) {
                            TaskCard(
                                task: task,
                                onComplete: { startAndComplete(task) },
                                onDelete: { deleteTask(task) },
                                timerTick: timerTick
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
    
    // MARK: - View Completed Button
    
    private var viewCompletedButton: some View {
        Group {
            if !completedTasks.isEmpty {
                Button(action: { showCompleted = true }) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.secondary)
                        Text("View \(completedTasks.count) Completed")
                            .font(.custom("Avenir-Medium", size: 14))
                            .foregroundColor(.secondary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("CardBackground").opacity(0.5))
                    )
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func loadDailyDuties() {
        guard let character = character else { return }
        dailyDuties = DutyBoardGenerator.ensureTodaysDuties(
            characterID: character.id,
            context: modelContext
        )
    }
    
    /// Whether this task has an in-app mini-game (Sudoku).
    private func isSudokuDuty(_ task: GameTask) -> Bool {
        task.title == "Solve a Puzzle"
    }
    
    private func acceptDuty(_ task: GameTask) {
        guard task.status == .pending else { return }
        guard let character = character else { return }
        guard !reachedDailyDutyLimit else { return }
        
        // Move the duty to My Tasks
        task.assignedTo = character.id
        task.isOnDutyBoard = false
        task.isDailyDuty = false
        task.startTask() // Starts timer and sets to inProgress
    }
    
    /// Opens the Sudoku game for a task from My Tasks.
    private func openSudoku(for task: GameTask) {
        sudokuDuty = task
        showSudoku = true
    }
    
    /// Called when the player completes the Sudoku puzzle.
    private func completeSudokuDuty() {
        guard let task = sudokuDuty else { return }
        guard let character = character else { return }
        
        // Mark verified so it skips verification checks
        task.isVerified = true
        
        // Complete it immediately
        applyCompletion(task: task, character: character)
        sudokuDuty = nil
    }
    
    private func startAndComplete(_ task: GameTask) {
        // For tasks that haven't been started yet, start them first
        if task.startedAt == nil {
            task.startTask()
        }
        completeTask(task)
    }
    
    private func completeTask(_ task: GameTask) {
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
        let result = gameEngine.completeTask(task, character: character, bond: bond, context: modelContext)
        lastCompletionResult = result
        showCompletionCelebration = true
        
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
        gameEngine.awardMaterialsForTask(
            task: task,
            character: character,
            context: modelContext
        )
        
        // Auto-confirm expired partner tasks
        gameEngine.autoConfirmExpiredPartnerTasks(
            character: character,
            bond: bond,
            context: modelContext
        )
    }
    
    private func deleteTask(_ task: GameTask) {
        modelContext.delete(task)
        deleteTrigger += 1
    }
}

// MARK: - Duty Note Card (bulletin board style)

struct DutyNoteCard: View {
    let task: GameTask
    var isLocked: Bool = false
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
                // Accept button — moves to My Tasks
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
                Text("+\(task.expReward)")
                    .font(.custom("Avenir-Heavy", size: 11))
            }
            .foregroundColor(Color("AccentGold"))
            
            HStack(spacing: 2) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 9))
                Text("+\(task.goldReward)")
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
                            Text("+\(task.expReward) EXP")
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
            
            Text("+\(task.expReward) EXP")
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
    var isSudoku: Bool = false
    
    @State private var showDeleteConfirm = false
    
    /// Whether the task is in progress and hasn't met its minimum duration yet
    private var isTimerActive: Bool {
        task.startedAt != nil && !task.hasMetMinimumDuration && task.status != .completed
    }
    
    /// Whether completion is blocked by the timer
    private var isCompletionBlocked: Bool {
        task.startedAt != nil && !task.hasMetMinimumDuration
    }
    
    var body: some View {
        HStack(spacing: 16) {
            if isSudoku && task.status != .completed {
                // Sudoku task — show puzzle icon that opens the game
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
                    .strikethrough(task.status == .completed)
                    .foregroundColor(task.status == .completed ? .secondary : .primary)
                
                if let description = task.taskDescription, !description.isEmpty {
                    Text(description)
                        .font(.custom("Avenir-Medium", size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Timer info row
                if let startedAt = task.startedAt, task.status != .completed {
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
                        Image(systemName: "sparkles")
                            .font(.caption)
                        Text("+\(task.expReward) EXP")
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
    
    /// Formatted remaining time text
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
}

// MARK: - Task Completion Celebration

struct TaskCompletionCelebration: View {
    let result: TaskCompletionResult
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Celebration icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color("AccentGold").opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                
                Image(systemName: result.didLevelUp ? "arrow.up.circle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color("AccentGreen"))
                    .symbolEffect(.bounce)
            }
            
            // Title
            Text(result.didLevelUp ? "LEVEL UP!" : "Quest Complete!")
                .font(.custom("Avenir-Heavy", size: 32))
            
            // Rewards
            VStack(spacing: 16) {
                RewardRow(icon: "sparkles", label: "EXP Earned", value: "+\(result.expGained)", color: Color("AccentGold"))
                RewardRow(icon: "dollarsign.circle.fill", label: "Gold Earned", value: "+\(result.goldGained)", color: Color("AccentGold"))
                
                ForEach(Array(result.bonusStatGains.enumerated()), id: \.offset) { _, bonus in
                    RewardRow(
                        icon: bonus.0.icon,
                        label: "\(bonus.0.rawValue) Bonus",
                        value: "+\(bonus.1)",
                        color: Color(bonus.0.color)
                    )
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color("CardBackground"))
            )
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Continue Button
            Button(action: { dismiss() }) {
                Text("Continue")
                    .font(.custom("Avenir-Heavy", size: 18))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color("AccentGold"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .background(
            LinearGradient(
                colors: [Color("BackgroundTop"), Color("BackgroundBottom")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}

struct RewardRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(label)
                .font(.custom("Avenir-Medium", size: 16))
            Spacer()
            Text(value)
                .font(.custom("Avenir-Heavy", size: 18))
                .foregroundColor(color)
        }
    }
}

#Preview {
    TasksView()
        .environmentObject(GameEngine())
}
