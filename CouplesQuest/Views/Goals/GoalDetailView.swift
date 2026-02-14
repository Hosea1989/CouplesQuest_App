import SwiftUI
import SwiftData

struct GoalDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var gameEngine: GameEngine
    @Query private var characters: [PlayerCharacter]
    @Query private var allTasks: [GameTask]
    
    let goal: Goal
    
    @State private var showAbandonConfirm = false
    @State private var showCreateTask = false
    
    private var character: PlayerCharacter? { characters.first }
    
    private var linkedTasks: [GameTask] {
        allTasks.filter { $0.goalID == goal.id && !$0.isHabit }
    }
    
    private var linkedHabits: [GameTask] {
        allTasks.filter { $0.goalID == goal.id && $0.isHabit }
    }
    
    private var allLinked: [GameTask] {
        allTasks.filter { $0.goalID == goal.id }
    }
    
    private var progress: Double {
        guard !allLinked.isEmpty else { return 0 }
        let completed = allLinked.filter { $0.status == .completed || ($0.isHabit && $0.habitStreak > 0) }.count
        return Double(completed) / Double(allLinked.count)
    }
    
    private var progressPercent: Int {
        Int(progress * 100)
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color("BackgroundTop"), Color("BackgroundBottom")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Progress Ring
                    progressCard
                    
                    // Milestones
                    milestonesCard
                    
                    // Linked Tasks
                    if !linkedTasks.isEmpty {
                        linkedSection(title: "Tasks", icon: "checklist", items: linkedTasks)
                    }
                    
                    // Linked Habits
                    if !linkedHabits.isEmpty {
                        linkedSection(title: "Habits", icon: "arrow.trianglehead.2.clockwise", items: linkedHabits)
                    }
                    
                    // Empty state if nothing linked
                    if allLinked.isEmpty {
                        noLinkedItemsCard
                    }
                    
                    // Actions
                    actionsCard
                }
                .padding()
            }
        }
        .navigationTitle(goal.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showCreateTask = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Color("AccentGold"))
                }
            }
        }
        .sheet(isPresented: $showCreateTask) {
            CreateTaskView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .alert("Abandon Goal?", isPresented: $showAbandonConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Abandon", role: .destructive) {
                goal.status = .abandoned
            }
        } message: {
            Text("This goal will be marked as abandoned. Linked tasks and habits won't be affected.")
        }
    }
    
    // MARK: - Progress Card
    
    private var progressCard: some View {
        VStack(spacing: 16) {
            // Category + description
            HStack(spacing: 10) {
                Image(systemName: goal.category.icon)
                    .font(.title2)
                    .foregroundColor(Color(goal.category.color))
                    .frame(width: 40, height: 40)
                    .background(
                        Circle().fill(Color(goal.category.color).opacity(0.15))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.category.rawValue)
                        .font(.custom("Avenir-Heavy", size: 14))
                        .foregroundColor(Color(goal.category.color))
                    
                    if let desc = goal.goalDescription, !desc.isEmpty {
                        Text(desc)
                            .font(.custom("Avenir-Medium", size: 13))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
            }
            
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 10)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(
                        LinearGradient(
                            colors: [Color(goal.category.color), Color(goal.category.color).opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.6), value: progress)
                
                VStack(spacing: 2) {
                    Text("\(progressPercent)%")
                        .font(.custom("Avenir-Heavy", size: 28))
                        .foregroundColor(Color(goal.category.color))
                    Text("Complete")
                        .font(.custom("Avenir-Medium", size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            // Stats row
            HStack(spacing: 24) {
                statBadge(icon: "list.bullet", label: "Linked", value: "\(allLinked.count)")
                statBadge(icon: "checkmark.circle", label: "Done", value: "\(allLinked.filter { $0.status == .completed }.count)")
                
                if let target = goal.targetDate {
                    let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: target).day ?? 0
                    statBadge(
                        icon: "calendar",
                        label: daysLeft >= 0 ? "Days Left" : "Overdue",
                        value: "\(abs(daysLeft))"
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
    }
    
    private func statBadge(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.custom("Avenir-Heavy", size: 18))
            Text(label)
                .font(.custom("Avenir-Medium", size: 11))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Milestones Card
    
    private var milestonesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Milestones")
                .font(.custom("Avenir-Heavy", size: 16))
            
            ForEach(GoalMilestone.allCases, id: \.rawValue) { milestone in
                let reached = progress >= Double(milestone.rawValue) / 100.0
                let claimed = goal.isMilestoneClaimed(milestone)
                let canClaim = reached && !claimed
                
                HStack(spacing: 12) {
                    // Icon
                    Image(systemName: milestone.icon)
                        .font(.system(size: 18))
                        .foregroundColor(reached ? Color(milestone.color) : .secondary.opacity(0.4))
                        .frame(width: 28)
                    
                    // Info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(milestone.label)
                            .font(.custom("Avenir-Heavy", size: 14))
                            .foregroundColor(reached ? .primary : .secondary)
                        
                        HStack(spacing: 8) {
                            HStack(spacing: 3) {
                                Image(systemName: "sparkles")
                                    .font(.caption2)
                                Text("+\(milestone.expReward) EXP")
                                    .font(.custom("Avenir-Medium", size: 11))
                            }
                            HStack(spacing: 3) {
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.caption2)
                                Text("+\(milestone.goldReward)")
                                    .font(.custom("Avenir-Medium", size: 11))
                            }
                        }
                        .foregroundColor(reached ? Color(milestone.color) : .secondary.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    if claimed {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(Color(milestone.color))
                    } else if canClaim {
                        Button(action: { claimMilestone(milestone) }) {
                            Text("Claim")
                                .font(.custom("Avenir-Heavy", size: 13))
                                .foregroundColor(.black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color(milestone.color))
                                )
                        }
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.3))
                    }
                }
                .padding(.vertical, 4)
                
                if milestone != .complete {
                    Divider()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
    }
    
    // MARK: - Linked Items Section
    
    private func linkedSection(title: String, icon: String, items: [GameTask]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(Color("AccentGold"))
                Text(title)
                    .font(.custom("Avenir-Heavy", size: 16))
                
                Spacer()
                
                Text("\(items.filter { $0.status == .completed }.count)/\(items.count)")
                    .font(.custom("Avenir-Medium", size: 13))
                    .foregroundColor(.secondary)
            }
            
            ForEach(items) { task in
                HStack(spacing: 10) {
                    Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(task.status == .completed ? Color("AccentGreen") : .secondary.opacity(0.4))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.title)
                            .font(.custom("Avenir-Medium", size: 14))
                            .strikethrough(task.status == .completed)
                            .foregroundColor(task.status == .completed ? .secondary : .primary)
                        
                        if task.isHabit {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.caption2)
                                    .foregroundColor(Color("AccentOrange"))
                                Text("\(task.habitStreak) day streak")
                                    .font(.custom("Avenir-Medium", size: 11))
                                    .foregroundColor(Color("AccentOrange"))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: task.category.icon)
                        .font(.caption)
                        .foregroundColor(Color(task.category.color))
                }
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
    }
    
    // MARK: - No Linked Items
    
    private var noLinkedItemsCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "link.badge.plus")
                .font(.system(size: 32))
                .foregroundColor(Color("AccentGold").opacity(0.6))
            
            Text("No linked tasks or habits yet")
                .font(.custom("Avenir-Heavy", size: 15))
            
            Text("Create a task or habit and select this goal in the \"Link to Goal\" picker to start tracking progress.")
                .font(.custom("Avenir-Medium", size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { showCreateTask = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("Add a Task")
                }
                .font(.custom("Avenir-Heavy", size: 14))
                .foregroundColor(Color("AccentGold"))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color("AccentGold").opacity(0.12))
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
    }
    
    // MARK: - Actions Card
    
    private var actionsCard: some View {
        VStack(spacing: 12) {
            if goal.status == .active {
                if progressPercent >= 100 {
                    Button(action: { completeGoal() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                            Text("Mark Goal Complete")
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
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                
                Button(action: { showAbandonConfirm = true }) {
                    Text("Abandon Goal")
                        .font(.custom("Avenir-Medium", size: 14))
                        .foregroundColor(.red.opacity(0.7))
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: goal.status == .completed ? "checkmark.seal.fill" : "xmark.circle.fill")
                    Text(goal.status == .completed ? "Goal Completed" : "Goal Abandoned")
                }
                .font(.custom("Avenir-Heavy", size: 15))
                .foregroundColor(goal.status == .completed ? Color("AccentGreen") : .secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
    }
    
    // MARK: - Actions
    
    private func claimMilestone(_ milestone: GoalMilestone) {
        guard let character = character else { return }
        goal.claimMilestone(milestone)
        character.gainEXP(milestone.expReward)
        character.gold += milestone.goldReward
        ToastManager.shared.showReward(
            "+\(milestone.expReward) EXP",
            subtitle: "\(milestone.label) milestone claimed!"
        )
    }
    
    private func completeGoal() {
        goal.status = .completed
        goal.completedAt = Date()
        ToastManager.shared.showSuccess(
            "Goal Complete!",
            subtitle: goal.title
        )
    }
}

#Preview {
    NavigationStack {
        GoalDetailView(
            goal: Goal(title: "Run a 5K", description: "Train up to run a full 5K race", category: .physical, targetDate: Date().addingTimeInterval(60*86400), createdBy: UUID())
        )
        .environmentObject(GameEngine())
    }
}
