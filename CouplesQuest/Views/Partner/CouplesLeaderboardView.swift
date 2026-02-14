import SwiftUI
import SwiftData

/// Party Leaderboard — ranked list of 1-4 members with fun titles, period filters,
/// and a solo fallback that shows personal records when party size = 1.
struct PartyLeaderboardView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var characters: [PlayerCharacter]
    @Query(sort: \GameTask.createdAt, order: .reverse) private var allTasks: [GameTask]
    @Query private var bonds: [Bond]
    
    @State private var selectedPeriod: LeaderboardPeriod = .thisWeek
    
    private var character: PlayerCharacter? { characters.first }
    private var bond: Bond? { bonds.first }
    
    /// Whether the player has no allies (solo mode)
    private var isSolo: Bool {
        guard let character = character else { return true }
        return !character.isInParty && character.partnerCharacterID == nil
    }
    
    enum LeaderboardPeriod: String, CaseIterable {
        case today = "Today"
        case thisWeek = "This Week"
        case allTime = "All Time"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color("BackgroundTop"), Color("BackgroundBottom")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Period Selector
                        periodSelector
                        
                        if isSolo {
                            // Solo fallback: personal records board
                            soloPersonalRecords
                        } else {
                            // Party mode: score comparison + category breakdown + awards
                            scoreComparison
                            categoryBreakdown
                            funTitles
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Party Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color("AccentGold"))
                }
            }
        }
    }
    
    // MARK: - Period Selector
    
    private var periodSelector: some View {
        HStack(spacing: 0) {
            ForEach(LeaderboardPeriod.allCases, id: \.self) { period in
                Button(action: { selectedPeriod = period }) {
                    Text(period.rawValue)
                        .font(.custom("Avenir-Heavy", size: 14))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selectedPeriod == period ? Color("AccentGold").opacity(0.2) : Color.clear)
                        .foregroundColor(selectedPeriod == period ? Color("AccentGold") : .secondary)
                }
            }
        }
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Solo Personal Records
    
    private var soloPersonalRecords: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "medal.fill")
                    .foregroundColor(Color("AccentGold"))
                Text("Personal Records")
                    .font(.custom("Avenir-Heavy", size: 18))
                Spacer()
            }
            
            // Best Week
            recordRow(
                icon: "calendar.badge.checkmark",
                title: "Best Week",
                value: "\(bestWeekCount) tasks",
                color: Color("AccentGold")
            )
            
            Divider()
            
            // Best Day
            recordRow(
                icon: "sun.max.fill",
                title: "Best Day",
                value: "\(character?.recordMostTasksInDay ?? 0) tasks",
                color: Color("AccentOrange")
            )
            
            Divider()
            
            // Longest Streak
            recordRow(
                icon: "flame.fill",
                title: "Longest Streak",
                value: "\(character?.longestStreak ?? 0) days",
                color: Color("AccentOrange")
            )
            
            Divider()
            
            // Total Tasks Completed
            recordRow(
                icon: "checkmark.circle.fill",
                title: "Total Completed",
                value: "\(myAllTimeCompleted.count) tasks",
                color: Color("AccentGreen")
            )
            
            Divider()
            
            // Strongest Category
            if let strongest = strongestCategory {
                recordRow(
                    icon: strongest.category.icon,
                    title: "Strongest Category",
                    value: "\(strongest.category.rawValue) (\(strongest.count))",
                    color: Color(strongest.category.color)
                )
            }
            
            Divider()
            
            // Current period stats
            VStack(alignment: .leading, spacing: 8) {
                Text("This Period")
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("\(myCompletedTasks.count)")
                            .font(.custom("Avenir-Heavy", size: 28))
                            .foregroundColor(Color("AccentGold"))
                        Text("Tasks Done")
                            .font(.custom("Avenir-Medium", size: 12))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack(spacing: 4) {
                        Text("\(myTotalEXP)")
                            .font(.custom("Avenir-Heavy", size: 28))
                            .foregroundColor(Color("AccentGold"))
                        Text("EXP Earned")
                            .font(.custom("Avenir-Medium", size: 12))
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
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    private func recordRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(.custom("Avenir-Heavy", size: 14))
            
            Spacer()
            
            Text(value)
                .font(.custom("Avenir-Heavy", size: 14))
                .foregroundColor(color)
        }
    }
    
    // MARK: - Score Comparison (Party Mode)
    
    private var scoreComparison: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Score Comparison")
                    .font(.custom("Avenir-Heavy", size: 18))
                Spacer()
            }
            
            HStack(spacing: 16) {
                // Your score
                scoreCard(
                    name: character?.name ?? "You",
                    tasksCompleted: myCompletedTasks.count,
                    totalEXP: myTotalEXP,
                    color: Color("AccentGold"),
                    isLeading: myCompletedTasks.count >= partnerCompletedTasks.count
                )
                
                // VS
                VStack {
                    Text("VS")
                        .font(.custom("Avenir-Heavy", size: 20))
                        .foregroundColor(.secondary)
                }
                
                // Partner score
                scoreCard(
                    name: character?.partnerName ?? "Ally",
                    tasksCompleted: partnerCompletedTasks.count,
                    totalEXP: partnerTotalEXP,
                    color: Color("AccentPurple"),
                    isLeading: partnerCompletedTasks.count > myCompletedTasks.count
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    private func scoreCard(name: String, tasksCompleted: Int, totalEXP: Int, color: Color, isLeading: Bool) -> some View {
        VStack(spacing: 10) {
            if isLeading {
                Image(systemName: "crown.fill")
                    .foregroundColor(Color("AccentGold"))
                    .font(.caption)
            } else {
                Image(systemName: "crown.fill")
                    .foregroundColor(.clear)
                    .font(.caption)
            }
            
            Text(name)
                .font(.custom("Avenir-Heavy", size: 14))
                .lineLimit(1)
            
            Text("\(tasksCompleted)")
                .font(.custom("Avenir-Heavy", size: 32))
                .foregroundColor(color)
            
            Text("tasks done")
                .font(.custom("Avenir-Medium", size: 11))
                .foregroundColor(.secondary)
            
            Divider()
            
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.caption2)
                Text("\(totalEXP) EXP")
                    .font(.custom("Avenir-Heavy", size: 12))
            }
            .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(color.opacity(0.08))
        )
    }
    
    // MARK: - Category Breakdown
    
    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Champions")
                .font(.custom("Avenir-Heavy", size: 18))
            
            ForEach(TaskCategory.allCases, id: \.self) { category in
                let myCount = myCompletedTasks.filter { $0.category == category }.count
                let partnerCount = partnerCompletedTasks.filter { $0.category == category }.count
                let total = max(myCount + partnerCount, 1)
                
                VStack(spacing: 6) {
                    HStack {
                        Image(systemName: category.icon)
                            .foregroundColor(Color(category.color))
                            .frame(width: 20)
                        
                        Text(category.rawValue)
                            .font(.custom("Avenir-Heavy", size: 14))
                        
                        Spacer()
                        
                        Text("\(myCount)")
                            .font(.custom("Avenir-Heavy", size: 14))
                            .foregroundColor(Color("AccentGold"))
                        
                        Text("vs")
                            .font(.custom("Avenir-Medium", size: 12))
                            .foregroundColor(.secondary)
                        
                        Text("\(partnerCount)")
                            .font(.custom("Avenir-Heavy", size: 14))
                            .foregroundColor(Color("AccentPurple"))
                    }
                    
                    // Bar comparison
                    GeometryReader { geometry in
                        HStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color("AccentGold"))
                                .frame(width: geometry.size.width * CGFloat(myCount) / CGFloat(total))
                            
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color("AccentPurple"))
                                .frame(width: geometry.size.width * CGFloat(partnerCount) / CGFloat(total))
                        }
                    }
                    .frame(height: 6)
                }
                
                if category != TaskCategory.allCases.last {
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
    
    // MARK: - Fun Titles
    
    private var funTitles: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Awards")
                .font(.custom("Avenir-Heavy", size: 18))
            
            // Task Machine — highest count overall
            let overallWinner = myCompletedTasks.count >= partnerCompletedTasks.count
                ? (character?.name ?? "You")
                : (character?.partnerName ?? "Ally")
            awardRow(icon: "bolt.fill", title: "Task Machine", winner: overallWinner, color: Color("AccentGold"))
            
            // EXP Hunter — highest EXP
            let expWinner = myTotalEXP >= partnerTotalEXP
                ? (character?.name ?? "You")
                : (character?.partnerName ?? "Ally")
            awardRow(icon: "sparkles", title: "EXP Hunter", winner: expWinner, color: Color("AccentGold"))
            
            // Streak Lord — best streak
            awardRow(icon: "flame.fill", title: "Streak Lord", winner: character?.name ?? "You", color: Color("AccentOrange"))
            
            // Category champions
            let categoryAwards: [(icon: String, title: String, category: TaskCategory)] = [
                ("figure.run", "Gym Warrior", .physical),
                ("brain.head.profile", "Scholar", .mental),
                ("person.2.fill", "Social Butterfly", .social),
                ("house.fill", "Homekeeper", .household),
                ("heart.fill", "Wellness Guru", .wellness),
                ("paintbrush.fill", "Creative Mind", .creative),
            ]
            
            ForEach(categoryAwards, id: \.title) { award in
                let myCount = myCompletedTasks.filter { $0.category == award.category }.count
                let pCount = partnerCompletedTasks.filter { $0.category == award.category }.count
                let winner = myCount >= pCount ? (character?.name ?? "You") : (character?.partnerName ?? "Ally")
                awardRow(icon: award.icon, title: award.title, winner: winner, color: Color(award.category.color))
            }
            
            // Jack of All Trades — most categories with completions
            let myCategoryCount = Set(myCompletedTasks.map { $0.category }).count
            let partnerCategoryCount = Set(partnerCompletedTasks.map { $0.category }).count
            let jackWinner = myCategoryCount >= partnerCategoryCount
                ? (character?.name ?? "You")
                : (character?.partnerName ?? "Ally")
            awardRow(icon: "star.fill", title: "Jack of All Trades", winner: jackWinner, color: Color("AccentPurple"))
            
            if let bond = bond {
                awardRow(icon: "heart.circle.fill", title: "Most Kudos Given", winner: bond.kudosSent > 0 ? (character?.name ?? "You") : "No one yet", color: Color("AccentPink"))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
    }
    
    private func awardRow(icon: String, title: String, winner: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("Avenir-Heavy", size: 14))
                Text(winner)
                    .font(.custom("Avenir-Medium", size: 12))
                    .foregroundColor(color)
            }
            
            Spacer()
            
            Image(systemName: "trophy.fill")
                .foregroundColor(Color("AccentGold"))
                .font(.caption)
        }
    }
    
    // MARK: - Data Helpers
    
    private var filteredTasks: [GameTask] {
        let completedStatus = TaskStatus.completed.rawValue
        let completed = allTasks.filter { $0.status.rawValue == completedStatus }
        
        switch selectedPeriod {
        case .today:
            return completed.filter { task in
                guard let completedAt = task.completedAt else { return false }
                return Calendar.current.isDateInToday(completedAt)
            }
        case .thisWeek:
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            return completed.filter { task in
                guard let completedAt = task.completedAt else { return false }
                return completedAt >= weekAgo
            }
        case .allTime:
            return completed
        }
    }
    
    private var myCompletedTasks: [GameTask] {
        guard let characterID = character?.id else { return [] }
        return filteredTasks.filter { $0.completedBy == characterID }
    }
    
    private var partnerCompletedTasks: [GameTask] {
        guard let partnerID = character?.partnerCharacterID else { return [] }
        return filteredTasks.filter { $0.completedBy == partnerID }
    }
    
    private var myTotalEXP: Int {
        myCompletedTasks.reduce(0) { $0 + $1.expReward }
    }
    
    private var partnerTotalEXP: Int {
        partnerCompletedTasks.reduce(0) { $0 + $1.expReward }
    }
    
    private var myAllTimeCompleted: [GameTask] {
        guard let characterID = character?.id else { return [] }
        let completedStatus = TaskStatus.completed.rawValue
        return allTasks.filter { $0.status.rawValue == completedStatus && $0.completedBy == characterID }
    }
    
    /// Best week task count (simple approximation: check rolling 7-day windows)
    private var bestWeekCount: Int {
        guard let characterID = character?.id else { return 0 }
        let completedStatus = TaskStatus.completed.rawValue
        let completed = allTasks.filter { $0.status.rawValue == completedStatus && $0.completedBy == characterID }
        
        // Simple approach: group by calendar week
        let calendar = Calendar.current
        let weekCounts = Dictionary(grouping: completed) { task -> Int in
            guard let date = task.completedAt else { return 0 }
            return calendar.component(.weekOfYear, from: date) + calendar.component(.year, from: date) * 100
        }
        return weekCounts.values.map(\.count).max() ?? 0
    }
    
    /// Strongest category across all time
    private var strongestCategory: (category: TaskCategory, count: Int)? {
        let counts = Dictionary(grouping: myAllTimeCompleted, by: { $0.category })
        guard let best = counts.max(by: { $0.value.count < $1.value.count }) else { return nil }
        return (best.key, best.value.count)
    }
}

/// Backwards-compatible typealias for existing call sites
typealias CouplesLeaderboardView = PartyLeaderboardView

#Preview {
    PartyLeaderboardView()
}
