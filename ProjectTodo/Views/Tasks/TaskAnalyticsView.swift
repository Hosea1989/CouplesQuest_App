import SwiftUI
import SwiftData
import Charts

/// Dedicated analytics screen for task productivity insights
struct TaskAnalyticsView: View {
    @Query private var allTasks: [GameTask]
    @Query private var characters: [PlayerCharacter]
    
    private var character: PlayerCharacter? { characters.first }
    
    private var completedTasks: [GameTask] {
        allTasks.filter { $0.status == .completed }
    }
    
    private var thisWeekTasks: [GameTask] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else { return [] }
        return completedTasks.filter { ($0.completedAt ?? .distantPast) >= monday }
    }
    
    private var thisMonthTasks: [GameTask] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: Date())
        guard let startOfMonth = calendar.date(from: components) else { return [] }
        return completedTasks.filter { ($0.completedAt ?? .distantPast) >= startOfMonth }
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
                VStack(spacing: 20) {
                    completionRateCard
                    categoryBreakdownCard
                    weeklyTrendCard
                    streakCard
                    statGainsCard
                    timeOfDayCard
                }
                .padding()
            }
        }
        .navigationTitle("Task Analytics")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Completion Rate
    
    private var completionRateCard: some View {
        let totalCreated = allTasks.count
        let totalCompleted = completedTasks.count
        let rate = totalCreated > 0 ? Double(totalCompleted) / Double(totalCreated) : 0
        
        let weekCreated = allTasks.filter {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let weekday = calendar.component(.weekday, from: today)
            let daysFromMonday = (weekday + 5) % 7
            guard let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else { return false }
            return $0.createdAt >= monday
        }.count
        let weekCompleted = thisWeekTasks.count
        let weekRate = weekCreated > 0 ? Double(weekCompleted) / Double(weekCreated) : 0
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(Color("AccentGold"))
                Text("Completion Rate")
                    .font(.custom("Avenir-Heavy", size: 18))
            }
            
            HStack(spacing: 24) {
                // Overall ring
                CompletionRing(rate: rate, label: "All Time", color: Color("AccentGold"))
                
                // This week ring
                CompletionRing(rate: weekRate, label: "This Week", color: Color("AccentGreen"))
            }
            .frame(maxWidth: .infinity)
            
            HStack {
                StatPill(label: "Total Created", value: "\(totalCreated)")
                StatPill(label: "Completed", value: "\(totalCompleted)")
                StatPill(label: "This Week", value: "\(weekCompleted)")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
    }
    
    // MARK: - Category Breakdown
    
    private var categoryBreakdownCard: some View {
        let breakdown = TaskCategory.allCases.map { cat in
            (category: cat, count: completedTasks.filter { $0.category == cat }.count)
        }.filter { $0.count > 0 }
        
        let total = max(1, breakdown.reduce(0) { $0 + $1.count })
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "square.grid.2x2.fill")
                    .foregroundColor(Color("AccentPurple"))
                Text("Category Breakdown")
                    .font(.custom("Avenir-Heavy", size: 18))
            }
            
            if breakdown.isEmpty {
                Text("Complete some tasks to see your breakdown!")
                    .font(.custom("Avenir-Medium", size: 14))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 12)
            } else {
                // Horizontal stacked bar
                GeometryReader { geometry in
                    HStack(spacing: 2) {
                        ForEach(breakdown, id: \.category) { item in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(item.category.color))
                                .frame(width: max(4, geometry.size.width * CGFloat(item.count) / CGFloat(total)))
                        }
                    }
                }
                .frame(height: 12)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                
                // Legend
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(breakdown, id: \.category) { item in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color(item.category.color))
                                .frame(width: 10, height: 10)
                            Text(item.category.rawValue)
                                .font(.custom("Avenir-Medium", size: 13))
                            Spacer()
                            Text("\(item.count)")
                                .font(.custom("Avenir-Heavy", size: 13))
                                .foregroundColor(Color(item.category.color))
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
    }
    
    // MARK: - Weekly Trend
    
    private var weeklyTrendCard: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Last 4 weeks of data
        let weeks: [(label: String, count: Int)] = (0..<4).reversed().map { weeksAgo in
            let weekStart = calendar.date(byAdding: .day, value: -(weeksAgo * 7), to: today)!
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
            let count = completedTasks.filter {
                guard let completed = $0.completedAt else { return false }
                return completed >= weekStart && completed < weekEnd
            }.count
            let label = weeksAgo == 0 ? "This Week" : "\(weeksAgo)w ago"
            return (label: label, count: count)
        }
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(Color("AccentGreen"))
                Text("Weekly Trend")
                    .font(.custom("Avenir-Heavy", size: 18))
            }
            
            Chart(weeks, id: \.label) { week in
                LineMark(
                    x: .value("Week", week.label),
                    y: .value("Tasks", week.count)
                )
                .foregroundStyle(Color("AccentGreen"))
                .interpolationMethod(.catmullRom)
                
                PointMark(
                    x: .value("Week", week.label),
                    y: .value("Tasks", week.count)
                )
                .foregroundStyle(Color("AccentGreen"))
                
                AreaMark(
                    x: .value("Week", week.label),
                    y: .value("Tasks", week.count)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color("AccentGreen").opacity(0.3), Color("AccentGreen").opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 3)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Color.secondary.opacity(0.3))
                    AxisValueLabel()
                        .font(.custom("Avenir-Medium", size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .font(.custom("Avenir-Medium", size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 140)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
    }
    
    // MARK: - Streak Card
    
    private var streakCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(Color("AccentOrange"))
                Text("Streaks")
                    .font(.custom("Avenir-Heavy", size: 18))
            }
            
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("\(character?.currentStreak ?? 0)")
                        .font(.custom("Avenir-Heavy", size: 32))
                        .foregroundColor(Color("AccentOrange"))
                    Text("Current")
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 1, height: 40)
                
                VStack(spacing: 4) {
                    Text("\(character?.longestStreak ?? 0)")
                        .font(.custom("Avenir-Heavy", size: 32))
                        .foregroundColor(Color("AccentGold"))
                    Text("Best")
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 1, height: 40)
                
                VStack(spacing: 4) {
                    Text("\(character?.tasksCompletedToday ?? 0)")
                        .font(.custom("Avenir-Heavy", size: 32))
                        .foregroundColor(Color("AccentGreen"))
                    Text("Today")
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            
            // Visual streak calendar (last 28 days)
            streakCalendar
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
    }
    
    private var streakCalendar: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let days: [(date: Date, count: Int)] = (0..<28).reversed().map { daysAgo in
            let day = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let nextDay = calendar.date(byAdding: .day, value: 1, to: day)!
            let count = completedTasks.filter {
                guard let completed = $0.completedAt else { return false }
                return completed >= day && completed < nextDay
            }.count
            return (date: day, count: count)
        }
        
        let maxDayCount = max(1, days.map(\.count).max() ?? 1)
        
        return VStack(alignment: .leading, spacing: 4) {
            Text("Last 28 Days")
                .font(.custom("Avenir-Medium", size: 12))
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 7), spacing: 3) {
                ForEach(days, id: \.date) { day in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(day.count == 0
                              ? Color.secondary.opacity(0.1)
                              : Color("AccentGreen").opacity(0.2 + 0.8 * Double(day.count) / Double(maxDayCount))
                        )
                        .frame(height: 16)
                }
            }
        }
    }
    
    // MARK: - Stat Gains
    
    private var statGainsCard: some View {
        let statCounts: [(stat: StatType, count: Int)] = StatType.allCases.map { stat in
            let count = completedTasks.filter { $0.bonusStat == stat }.count
            return (stat: stat, count: count)
        }.filter { $0.count > 0 }.sorted { $0.count > $1.count }
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "arrow.up.right")
                    .foregroundColor(Color("AccentGold"))
                Text("Stat Gains from Tasks")
                    .font(.custom("Avenir-Heavy", size: 18))
            }
            
            if statCounts.isEmpty {
                Text("Complete tasks to see which stats grew the most!")
                    .font(.custom("Avenir-Medium", size: 14))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 12)
            } else {
                ForEach(statCounts, id: \.stat) { item in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Color(statColorName(item.stat)))
                            .frame(width: 10, height: 10)
                        
                        Text(item.stat.rawValue)
                            .font(.custom("Avenir-Heavy", size: 14))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("\(item.count)")
                            .font(.custom("Avenir-Heavy", size: 14))
                            .foregroundColor(Color(statColorName(item.stat)))
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
    }
    
    // MARK: - Time of Day
    
    private var timeOfDayCard: some View {
        let calendar = Calendar.current
        
        struct TimeSlot: Identifiable {
            let id = UUID()
            let label: String
            let icon: String
            let count: Int
        }
        
        let morningCount = completedTasks.filter {
            guard let completed = $0.completedAt else { return false }
            let hour = calendar.component(.hour, from: completed)
            return hour >= 5 && hour < 12
        }.count
        
        let afternoonCount = completedTasks.filter {
            guard let completed = $0.completedAt else { return false }
            let hour = calendar.component(.hour, from: completed)
            return hour >= 12 && hour < 17
        }.count
        
        let eveningCount = completedTasks.filter {
            guard let completed = $0.completedAt else { return false }
            let hour = calendar.component(.hour, from: completed)
            return hour >= 17 || hour < 5
        }.count
        
        let slots = [
            TimeSlot(label: "Morning", icon: "sunrise.fill", count: morningCount),
            TimeSlot(label: "Afternoon", icon: "sun.max.fill", count: afternoonCount),
            TimeSlot(label: "Evening", icon: "moon.stars.fill", count: eveningCount),
        ]
        
        let bestSlot = slots.max(by: { $0.count < $1.count })
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(Color("AccentPurple"))
                Text("Peak Productivity")
                    .font(.custom("Avenir-Heavy", size: 18))
            }
            
            HStack(spacing: 12) {
                ForEach(slots) { slot in
                    VStack(spacing: 6) {
                        Image(systemName: slot.icon)
                            .font(.title2)
                            .foregroundColor(slot.label == bestSlot?.label ? Color("AccentGold") : .secondary)
                        
                        Text("\(slot.count)")
                            .font(.custom("Avenir-Heavy", size: 20))
                            .foregroundColor(slot.label == bestSlot?.label ? Color("AccentGold") : .primary)
                        
                        Text(slot.label)
                            .font(.custom("Avenir-Medium", size: 12))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(slot.label == bestSlot?.label
                                  ? Color("AccentGold").opacity(0.1)
                                  : Color.secondary.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(slot.label == bestSlot?.label
                                    ? Color("AccentGold").opacity(0.3)
                                    : Color.clear, lineWidth: 1)
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
    }
    
    // MARK: - Helpers
    
    private func statColorName(_ stat: StatType) -> String {
        switch stat {
        case .strength: return "StatStrength"
        case .dexterity, .endurance: return "StatDexterity"
        case .wisdom: return "StatWisdom"
        case .charisma: return "StatCharisma"
        case .defense: return "StatDefense"
        case .luck: return "StatLuck"
        }
    }
}

// MARK: - Completion Ring

private struct CompletionRing: View {
    let rate: Double
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 8)
                    .frame(width: 64, height: 64)
                
                Circle()
                    .trim(from: 0, to: rate)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(rate * 100))%")
                    .font(.custom("Avenir-Heavy", size: 16))
            }
            
            Text(label)
                .font(.custom("Avenir-Medium", size: 12))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Stat Pill

private struct StatPill: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.custom("Avenir-Heavy", size: 16))
            Text(label)
                .font(.custom("Avenir-Medium", size: 10))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.secondary.opacity(0.06))
        )
    }
}
