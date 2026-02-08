import SwiftUI
import SwiftData

/// Friendly competition leaderboard between partners
struct CouplesLeaderboardView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var characters: [PlayerCharacter]
    @Query(sort: \GameTask.createdAt, order: .reverse) private var allTasks: [GameTask]
    @Query private var bonds: [Bond]
    
    @State private var selectedPeriod: LeaderboardPeriod = .thisWeek
    
    private var character: PlayerCharacter? { characters.first }
    private var bond: Bond? { bonds.first }
    
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
                        
                        // Score Cards
                        scoreComparison
                        
                        // Category Breakdown
                        categoryBreakdown
                        
                        // Fun Titles
                        funTitles
                    }
                    .padding()
                }
            }
            .navigationTitle("Leaderboard")
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
    
    // MARK: - Score Comparison
    
    private var scoreComparison: some View {
        VStack(spacing: 16) {
            // Header
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
                    name: character?.partnerName ?? "Partner",
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
            
            let physicalMy = myCompletedTasks.filter { $0.category == .physical }.count
            let physicalPartner = partnerCompletedTasks.filter { $0.category == .physical }.count
            let fitnessChamp = physicalMy >= physicalPartner ? (character?.name ?? "You") : (character?.partnerName ?? "Partner")
            
            let mentalMy = myCompletedTasks.filter { $0.category == .mental }.count
            let mentalPartner = partnerCompletedTasks.filter { $0.category == .mental }.count
            let scholarChamp = mentalMy >= mentalPartner ? (character?.name ?? "You") : (character?.partnerName ?? "Partner")
            
            awardRow(icon: "figure.run", title: "Fitness Champion", winner: fitnessChamp, color: Color(TaskCategory.physical.color))
            awardRow(icon: "brain.head.profile", title: "Scholar Champion", winner: scholarChamp, color: Color(TaskCategory.mental.color))
            awardRow(icon: "flame.fill", title: "Streak Master", winner: character?.name ?? "You", color: Color("AccentOrange"))
            
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
}

#Preview {
    CouplesLeaderboardView()
}
