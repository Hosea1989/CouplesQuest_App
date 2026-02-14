import SwiftUI
import SwiftData

struct TaskDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var gameEngine: GameEngine
    @Query private var characters: [PlayerCharacter]
    
    @Bindable var task: GameTask
    
    @State private var showDeleteConfirm = false
    @State private var showCompletionCelebration = false
    @State private var lastCompletionResult: TaskCompletionResult?
    @State private var showTimer = false
    @State private var showEditTask = false
    
    private var character: PlayerCharacter? {
        characters.first
    }
    
    private var isCompleted: Bool {
        task.status == .completed
    }
    
    var body: some View {
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
                VStack(spacing: 20) {
                    // Status Banner
                    statusBanner
                    
                    // Due Date Urgency (if applicable)
                    if let dueDate = task.dueDate, task.status != .completed {
                        dueDateCard(dueDate: dueDate)
                    }
                    
                    // Task Info Card
                    taskInfoCard
                    
                    // Rewards Card
                    rewardsCard
                    
                    // Details Card
                    detailsCard
                    
                    // Action Buttons
                    if !isCompleted {
                        actionButtons
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isCompleted {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showEditTask = true
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundColor(Color("AccentGold"))
                    }
                }
            }
        }
        .sheet(isPresented: $showEditTask) {
            EditTaskView(task: task)
        }
        .sheet(isPresented: $showCompletionCelebration) {
            if let result = lastCompletionResult {
                TaskCompletionCelebration(result: result)
            }
        }
        .fullScreenCover(isPresented: $showTimer) {
            TaskTimerView(task: task, onComplete: {
                completeTask()
                showTimer = false
            })
        }
        .confirmationDialog(
            "Delete Task?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                modelContext.delete(task)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    // MARK: - Status Banner
    
    private var statusBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: statusIcon)
                .font(.title3)
                .foregroundColor(statusColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.status.rawValue)
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(statusColor)
                
                if isCompleted, let completedAt = task.completedAt {
                    Text("Completed \(completedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                } else if task.status == .inProgress {
                    Text("In progress — you've got this!")
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // MARK: - Due Date Card
    
    private func dueDateCard(dueDate: Date) -> some View {
        let urgency = dueDateUrgency(dueDate)
        
        return HStack(spacing: 12) {
            Image(systemName: urgency.icon)
                .font(.title3)
                .foregroundColor(urgency.color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(urgency.label)
                    .font(.custom("Avenir-Heavy", size: 14))
                    .foregroundColor(urgency.color)
                
                Text(dueDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.custom("Avenir-Medium", size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(urgency.timeRemaining)
                .font(.custom("Avenir-Heavy", size: 14))
                .foregroundColor(urgency.color)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(urgency.color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(urgency.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Task Info Card
    
    private var taskInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Category & Verification Row
            HStack(spacing: 8) {
                // Category tag
                HStack(spacing: 6) {
                    Image(systemName: task.category.icon)
                        .font(.caption)
                    Text(task.category.rawValue)
                        .font(.custom("Avenir-Heavy", size: 12))
                }
                .foregroundColor(Color(task.category.color))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color(task.category.color).opacity(0.15))
                )
                
                // Verification tag
                if task.verificationType != .none {
                    HStack(spacing: 6) {
                        Image(systemName: task.verificationType.icon)
                            .font(.caption)
                        Text(task.verificationType.rawValue)
                            .font(.custom("Avenir-Heavy", size: 12))
                    }
                    .foregroundColor(Color(task.verificationType.color))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color(task.verificationType.color).opacity(0.15))
                    )
                }
                
                if task.isOnDutyBoard {
                    HStack(spacing: 4) {
                        Image(systemName: "rectangle.on.rectangle")
                            .font(.caption)
                        Text("Duty Board")
                            .font(.custom("Avenir-Heavy", size: 12))
                    }
                    .foregroundColor(Color("AccentPurple"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color("AccentPurple").opacity(0.15))
                    )
                }
                
                Spacer()
            }
            
            // Title
            Text(task.title)
                .font(.custom("Avenir-Heavy", size: 24))
                .foregroundColor(.primary)
            
            // Description
            if let description = task.taskDescription, !description.isEmpty {
                Text(description)
                    .font(.custom("Avenir-Medium", size: 16))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Recurring indicator
            if task.isRecurring, let pattern = task.recurrencePattern {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.trianglehead.2.counterclockwise.rotate.90")
                        .font(.caption)
                        .foregroundColor(Color("AccentGold"))
                    
                    Text("Repeats \(pattern.rawValue)")
                        .font(.custom("Avenir-Medium", size: 14))
                        .foregroundColor(Color("AccentGold"))
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // MARK: - Rewards Card
    
    private var rewardsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rewards")
                .font(.custom("Avenir-Heavy", size: 18))
            
            HStack(spacing: 0) {
                // EXP
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color("AccentGold").opacity(0.15))
                            .frame(width: 48, height: 48)
                        Image(systemName: "sparkles")
                            .font(.title3)
                            .foregroundColor(Color("AccentGold"))
                    }
                    Text("+\(task.scaledExpReward(characterLevel: character?.level ?? 1))")
                        .font(.custom("Avenir-Heavy", size: 18))
                        .foregroundColor(Color("AccentGold"))
                    Text("EXP")
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                // Divider
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 1, height: 60)
                
                // Gold
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color("AccentGold").opacity(0.15))
                            .frame(width: 48, height: 48)
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.title3)
                            .foregroundColor(Color("AccentGold"))
                    }
                    Text("+\(task.scaledGoldReward(characterLevel: character?.level ?? 1))")
                        .font(.custom("Avenir-Heavy", size: 18))
                        .foregroundColor(Color("AccentGold"))
                    Text("Gold")
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                // Divider
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 1, height: 60)
                
                // Bonus Stat
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color(task.bonusStat.color).opacity(0.15))
                            .frame(width: 48, height: 48)
                        Image(systemName: task.bonusStat.icon)
                            .font(.title3)
                            .foregroundColor(Color(task.bonusStat.color))
                    }
                    Text("10%")
                        .font(.custom("Avenir-Heavy", size: 18))
                        .foregroundColor(Color(task.bonusStat.color))
                    Text(task.bonusStat.rawValue)
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // MARK: - Details Card
    
    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Details")
                .font(.custom("Avenir-Heavy", size: 18))
            
            DetailRow(
                icon: "calendar",
                label: "Created",
                value: task.createdAt.formatted(date: .abbreviated, time: .shortened)
            )
            
            if let dueDate = task.dueDate {
                DetailRow(
                    icon: "clock",
                    label: "Due",
                    value: dueDate.formatted(date: .abbreviated, time: .shortened)
                )
            }
            
            DetailRow(
                icon: task.category.icon,
                label: "Category",
                value: task.category.rawValue
            )
            
            DetailRow(
                icon: task.verificationType.icon,
                label: "Verification",
                value: task.verificationType.rawValue
            )
            
            if task.isOnDutyBoard {
                DetailRow(
                    icon: "rectangle.on.rectangle",
                    label: "Assignment",
                    value: "Duty Board (anyone can claim)"
                )
            } else {
                DetailRow(
                    icon: "person.fill",
                    label: "Assignment",
                    value: "Personal Task"
                )
            }
            
            if task.isSharedWithPartner {
                DetailRow(
                    icon: "person.2.fill",
                    label: "Shared With",
                    value: "Partner Invited",
                    valueColor: Color("AccentPink")
                )
                
                if let message = task.partnerMessage, !message.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "quote.opening")
                            .font(.caption2)
                            .foregroundColor(Color("AccentPink").opacity(0.6))
                        Text(message)
                            .font(.custom("Avenir-Medium", size: 13))
                            .foregroundColor(Color("AccentPink"))
                            .italic()
                    }
                    .padding(.leading, 34)
                }
            }
            
            if task.isRecurring, let pattern = task.recurrencePattern {
                DetailRow(
                    icon: "arrow.trianglehead.2.counterclockwise.rotate.90",
                    label: "Recurrence",
                    value: pattern.rawValue
                )
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Ready? Button — opens the task timer
            Button(action: { showTimer = true }) {
                HStack(spacing: 10) {
                    Image(systemName: "clock.fill")
                        .font(.title3)
                    Text("Ready?")
                        .font(.custom("Avenir-Heavy", size: 20))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [Color("AccentGold"), Color("AccentOrange")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            // Delete Button
            Button(action: { showDeleteConfirm = true }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Task")
                }
                .font(.custom("Avenir-Heavy", size: 16))
                .foregroundColor(.red.opacity(0.8))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Helpers
    
    private var statusIcon: String {
        switch task.status {
        case .pending: return "circle"
        case .inProgress: return "arrow.forward.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .expired: return "clock.badge.exclamationmark"
        }
    }
    
    private var statusColor: Color {
        switch task.status {
        case .pending: return .secondary
        case .inProgress: return Color("AccentGold")
        case .completed: return Color("AccentGreen")
        case .failed: return .red
        case .expired: return .orange
        }
    }
    
    private func completeTask() {
        guard let character = character else { return }
        
        // Haptic feedback on task completion
        let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
        impactHeavy.impactOccurred()
        
        // Play success sound
        AudioManager.shared.play(.success)
        
        let result = gameEngine.completeTask(
            task,
            character: character,
            context: modelContext
        )
        lastCompletionResult = result
        
        // Delayed celebration haptic (after card animates in)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        }
        
        // Play loot drop sound if loot was found
        if result.lootDropped != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                AudioManager.shared.play(.lootDrop)
            }
        }
        
        showCompletionCelebration = true
        
        gameEngine.updateStreak(for: character, completedTaskToday: true)
        
        // Award crafting materials
        gameEngine.awardMaterialsForTask(task: task, character: character, context: modelContext)
    }
    
    // MARK: - Due Date Urgency
    
    private struct DueDateUrgency {
        let label: String
        let icon: String
        let color: Color
        let timeRemaining: String
    }
    
    private func dueDateUrgency(_ dueDate: Date) -> DueDateUrgency {
        let now = Date()
        let interval = dueDate.timeIntervalSince(now)
        
        if interval < 0 {
            // Overdue
            let overdue = abs(interval)
            let hours = Int(overdue / 3600)
            let days = hours / 24
            let timeText = days > 0 ? "\(days)d overdue" : "\(hours)h overdue"
            return DueDateUrgency(
                label: "Overdue!",
                icon: "exclamationmark.triangle.fill",
                color: .red,
                timeRemaining: timeText
            )
        } else if interval < 3600 {
            // Less than 1 hour
            let minutes = max(1, Int(interval / 60))
            return DueDateUrgency(
                label: "Due very soon",
                icon: "exclamationmark.triangle.fill",
                color: .red,
                timeRemaining: "\(minutes)m left"
            )
        } else if interval < 86400 {
            // Less than 24 hours
            let hours = Int(interval / 3600)
            return DueDateUrgency(
                label: "Due today",
                icon: "clock.badge.exclamationmark",
                color: .orange,
                timeRemaining: "\(hours)h left"
            )
        } else if interval < 172800 {
            // Less than 48 hours
            return DueDateUrgency(
                label: "Due tomorrow",
                icon: "clock",
                color: Color("AccentGold"),
                timeRemaining: "1d left"
            )
        } else {
            // More than 2 days
            let days = Int(interval / 86400)
            return DueDateUrgency(
                label: "Upcoming",
                icon: "calendar",
                color: Color("AccentGreen"),
                timeRemaining: "\(days)d left"
            )
        }
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    var valueColor: Color? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            Text(label)
                .font(.custom("Avenir-Medium", size: 14))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.custom("Avenir-Medium", size: 14))
                .foregroundColor(valueColor ?? .primary)
        }
    }
}

#Preview {
    NavigationStack {
        TaskDetailView(
            task: GameTask(
                title: "Go for a run",
                description: "Run at least 2 miles around the neighborhood together",
                category: .physical,
                createdBy: UUID(),
                isOnDutyBoard: true,
                isRecurring: true,
                recurrencePattern: .weekdays,
                dueDate: Date().addingTimeInterval(3600 * 5),
                verificationType: .location
            )
        )
        .environmentObject(GameEngine())
    }
}
