import SwiftUI
import SwiftData

struct GoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var characters: [PlayerCharacter]
    @Query(sort: \Goal.createdAt, order: .reverse) private var allGoals: [Goal]
    @Query private var allTasks: [GameTask]
    
    @Query private var bonds: [Bond]
    
    @State private var showCreateGoal = false
    @State private var selectedFilter: GoalFilter = .active
    
    private var character: PlayerCharacter? { characters.first }
    private var bond: Bond? { bonds.first }
    
    /// Whether this view is filtered to show only party goals (set by parent when navigating from Party tab)
    var partyOnly: Bool = false
    
    enum GoalFilter: String, CaseIterable {
        case active = "Active"
        case party = "Party"
        case completed = "Completed"
        case all = "All"
    }
    
    private var filteredGoals: [Goal] {
        switch selectedFilter {
        case .active:
            return allGoals.filter { $0.status == .active && !$0.isPartyGoal }
        case .party:
            return allGoals.filter { $0.isPartyGoal && $0.status == .active }
        case .completed:
            return allGoals.filter { $0.status == .completed }
        case .all:
            return allGoals
        }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color("BackgroundTop"), Color("BackgroundBottom")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if allGoals.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Filter picker
                        Picker("Filter", selection: $selectedFilter) {
                            ForEach(GoalFilter.allCases, id: \.self) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        
                        if filteredGoals.isEmpty {
                            Text("No \(selectedFilter.rawValue.lowercased()) goals")
                                .font(.custom("Avenir-Medium", size: 15))
                                .foregroundColor(.secondary)
                                .padding(.top, 40)
                        } else {
                            ForEach(filteredGoals) { goal in
                                NavigationLink(destination: GoalDetailView(goal: goal)) {
                                    goalCard(goal)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Goals")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showCreateGoal = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Color("AccentGold"))
                        .font(.title2)
                }
            }
        }
        .sheet(isPresented: $showCreateGoal) {
            CreateGoalView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "flag.fill")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color("AccentGold"), Color("AccentOrange")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("No Goals Yet")
                .font(.custom("Avenir-Heavy", size: 22))
            
            Text("Set a goal to work toward. Link tasks and habits to track your progress automatically.")
                .font(.custom("Avenir-Medium", size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: { showCreateGoal = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("Create Your First Goal")
                }
                .font(.custom("Avenir-Heavy", size: 16))
                .foregroundColor(.black)
                .padding(.horizontal, 28)
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
            .padding(.top, 8)
        }
    }
    
    // MARK: - Goal Card
    
    private func goalCard(_ goal: Goal) -> some View {
        let progress = goal.isPartyGoal ? goal.partyGoalProgress : calculateProgress(for: goal)
        let linkedCount = goal.isPartyGoal ? goal.targetCount : linkedTaskCount(for: goal)
        let completedCount = goal.isPartyGoal ? Int(goal.partyGoalProgress * Double(goal.targetCount)) : completedLinkedCount(for: goal)
        
        return VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: goal.isPartyGoal ? "person.3.fill" : goal.category.icon)
                    .font(.title3)
                    .foregroundColor(goal.isPartyGoal ? Color("AccentPink") : Color(goal.category.color))
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill((goal.isPartyGoal ? Color("AccentPink") : Color(goal.category.color)).opacity(0.15))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(goal.title)
                            .font(.custom("Avenir-Heavy", size: 16))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        if goal.isPartyGoal {
                            Text("PARTY")
                                .font(.custom("Avenir-Heavy", size: 9))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color("AccentPink"))
                                .clipShape(Capsule())
                        }
                    }
                    
                    if let target = goal.targetDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                            Text("By \(target, format: .dateTime.month().day().year())")
                                .font(.custom("Avenir-Medium", size: 12))
                        }
                        .foregroundColor(target < Date() && goal.status == .active ? .red : .secondary)
                    }
                }
                
                Spacer()
                
                // Progress percentage
                Text("\(Int(progress * 100))%")
                    .font(.custom("Avenir-Heavy", size: 18))
                    .foregroundColor(Color(goal.category.color))
            }
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color(goal.category.color), Color(goal.category.color).opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(progress), height: 8)
                }
            }
            .frame(height: 8)
            
            // Footer
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: goal.isPartyGoal ? "person.3.fill" : "checkmark.circle")
                        .font(.caption)
                    Text(goal.isPartyGoal ? "Avg \(completedCount)/\(linkedCount)" : "\(completedCount)/\(linkedCount) tasks")
                        .font(.custom("Avenir-Medium", size: 12))
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                // Milestone dots
                HStack(spacing: 6) {
                    ForEach(GoalMilestone.allCases, id: \.rawValue) { milestone in
                        let reached = progress >= Double(milestone.rawValue) / 100.0
                        let claimed = goal.isMilestoneClaimed(milestone)
                        Circle()
                            .fill(claimed ? Color(milestone.color) : (reached ? Color(milestone.color).opacity(0.5) : Color.secondary.opacity(0.2)))
                            .frame(width: 10, height: 10)
                            .overlay(
                                Circle()
                                    .stroke(reached ? Color(milestone.color) : Color.clear, lineWidth: 1)
                            )
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
    }
    
    // MARK: - Progress Helpers
    
    func calculateProgress(for goal: Goal) -> Double {
        let linked = allTasks.filter { $0.goalID == goal.id }
        guard !linked.isEmpty else { return 0 }
        let completed = linked.filter { $0.status == .completed || ($0.isHabit && $0.habitStreak > 0) }.count
        return Double(completed) / Double(linked.count)
    }
    
    func linkedTaskCount(for goal: Goal) -> Int {
        allTasks.filter { $0.goalID == goal.id }.count
    }
    
    func completedLinkedCount(for goal: Goal) -> Int {
        allTasks.filter { $0.goalID == goal.id && ($0.status == .completed || ($0.isHabit && $0.habitStreak > 0)) }.count
    }
}

// MARK: - Create Goal View

struct CreateGoalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var characters: [PlayerCharacter]
    @Query private var bonds: [Bond]
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory: TaskCategory = .physical
    @State private var hasTargetDate = false
    @State private var targetDate = Date().addingTimeInterval(30 * 86400) // 30 days
    @State private var isPartyGoal = false
    @State private var targetCount = 30
    
    private var character: PlayerCharacter? { characters.first }
    private var bond: Bond? { bonds.first }
    
    private var isValid: Bool {
        let hasTitle = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if isPartyGoal {
            return hasTitle && targetCount > 0
        }
        return hasTitle
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundTop").ignoresSafeArea()
                
                Form {
                    Section {
                        TextField("Goal Title", text: $title)
                            .font(.custom("Avenir-Medium", size: 16))
                        
                        TextField("Description (optional)", text: $description, axis: .vertical)
                            .font(.custom("Avenir-Medium", size: 14))
                            .lineLimit(3...6)
                    } header: {
                        Text("What's your goal?")
                    }
                    
                    Section {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 10) {
                            ForEach(TaskCategory.allCases, id: \.self) { category in
                                CategoryButton(
                                    category: category,
                                    isSelected: selectedCategory == category,
                                    action: { selectedCategory = category }
                                )
                            }
                        }
                        .padding(.vertical, 8)
                    } header: {
                        Text("Category")
                    }
                    
                    Section {
                        Toggle(isOn: $hasTargetDate) {
                            Text("Set Target Date")
                                .font(.custom("Avenir-Medium", size: 16))
                        }
                        .tint(Color("AccentGold"))
                        
                        if hasTargetDate {
                            DatePicker(
                                "Target",
                                selection: $targetDate,
                                in: Date()...,
                                displayedComponents: .date
                            )
                        }
                    } header: {
                        Text("Timeline")
                    }
                    
                    // Party Goal Toggle (only if in a party)
                    if let bond = bond, bond.isParty {
                        Section {
                            Toggle(isOn: $isPartyGoal) {
                                HStack(spacing: 8) {
                                    Image(systemName: "person.3.fill")
                                        .foregroundColor(Color("AccentPink"))
                                    Text("Shared Party Goal")
                                        .font(.custom("Avenir-Medium", size: 16))
                                }
                            }
                            .tint(Color("AccentPink"))
                            
                            if isPartyGoal {
                                Stepper("Target per Member: \(targetCount)", value: $targetCount, in: 1...365)
                                    .font(.custom("Avenir-Medium", size: 14))
                                
                                HStack(spacing: 8) {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(Color("AccentPink"))
                                    Text("Each party member tracks progress individually. The party earns a bonus reward when all members reach the target.")
                                        .font(.custom("Avenir-Medium", size: 12))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        } header: {
                            Text("Party")
                        }
                    }
                    
                    // Info card
                    Section {
                        HStack(spacing: 12) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(Color("AccentGold"))
                            Text(isPartyGoal
                                ? "Each party member counts progress individually. Complete the target to earn a shared party reward!"
                                : "After creating your goal, link tasks and habits to it. Your progress updates automatically as you complete them.")
                                .font(.custom("Avenir-Medium", size: 13))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color("AccentGold"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") { createGoal() }
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(isValid ? Color("AccentGold") : .secondary)
                        .disabled(!isValid)
                }
            }
        }
    }
    
    private func createGoal() {
        guard let character = character else { return }
        
        let goal: Goal
        
        if isPartyGoal, let bond = bond, bond.isParty {
            goal = Goal(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.isEmpty ? nil : description,
                category: selectedCategory,
                targetDate: hasTargetDate ? targetDate : nil,
                targetCount: targetCount,
                createdBy: character.id,
                partyID: bond.supabasePartyID ?? bond.id,
                memberIDs: bond.memberIDs
            )
        } else {
            goal = Goal(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.isEmpty ? nil : description,
                category: selectedCategory,
                targetDate: hasTargetDate ? targetDate : nil,
                createdBy: character.id
            )
        }
        
        modelContext.insert(goal)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        GoalsView()
    }
}
