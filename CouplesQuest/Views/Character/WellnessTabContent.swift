import SwiftUI
import SwiftData

struct WellnessTabContent: View {
    let character: PlayerCharacter
    @Environment(\.modelContext) private var modelContext
    @Query private var allMoodEntries: [MoodEntry]
    @Query private var allAchievements: [Achievement]
    
    /// Wellness-specific achievements (Inner Peace, Self-Aware, Zen Master)
    private var wellnessAchievements: [Achievement] {
        let wellnessKeys: Set<String> = [
            AchievementDefinitions.AchievementKey.innerPeace.rawValue,
            AchievementDefinitions.AchievementKey.selfAware.rawValue,
            AchievementDefinitions.AchievementKey.zenMaster.rawValue
        ]
        return allAchievements.filter { wellnessKeys.contains($0.trackingKey) }
    }
    
    /// Mood entries belonging to this character, sorted newest first
    private var moodEntries: [MoodEntry] {
        allMoodEntries
            .filter { $0.ownerID == character.id }
            .sorted { $0.date > $1.date }
    }
    
    /// Last 7 days of mood data for the chart
    private var weeklyMoodData: [DailyMoodPoint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return (0..<7).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            let nextDay = calendar.date(byAdding: .day, value: 1, to: day)!
            let entry = moodEntries.first { $0.date >= day && $0.date < nextDay }
            let dayLabel = offset == 0 ? "Today" : dayAbbreviation(for: day)
            return DailyMoodPoint(
                label: dayLabel,
                moodLevel: entry?.moodLevel,
                emoji: entry?.moodEmoji ?? "—"
            )
        }
    }
    
    /// Journal entries only
    private var journalEntries: [MoodEntry] {
        moodEntries.filter { $0.hasJournal }
    }
    
    /// Average mood score
    private var averageMood: Double? {
        guard !moodEntries.isEmpty else { return nil }
        let total = moodEntries.reduce(0) { $0 + $1.moodLevel }
        return Double(total) / Double(moodEntries.count)
    }
    
    /// Most common mood level
    private var mostCommonMood: Int? {
        guard !moodEntries.isEmpty else { return nil }
        let counts = Dictionary(grouping: moodEntries, by: \.moodLevel)
        return counts.max(by: { $0.value.count < $1.value.count })?.key
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Mood History Chart
            moodHistoryCard
            
            // Streaks Row
            streaksCard
            
            // Quick Stats
            if !moodEntries.isEmpty {
                moodStatsCard
            }
            
            // Journal Entries
            if !journalEntries.isEmpty {
                journalCard
            }
            
            // Meditation Info
            meditationCard
            
            // Wisdom Buff Status
            if character.hasActiveWisdomBuff {
                wisdomBuffCard
            }
            
            // Wellness Achievements
            if !wellnessAchievements.isEmpty {
                wellnessAchievementsCard
            }
        }
    }
    
    // MARK: - Mood History Chart
    
    private var moodHistoryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(Color("AccentPink"))
                Text("Mood History")
                    .font(.custom("Avenir-Heavy", size: 16))
                Spacer()
                Text("Last 7 Days")
                    .font(.custom("Avenir-Medium", size: 12))
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 0) {
                ForEach(weeklyMoodData, id: \.label) { point in
                    VStack(spacing: 8) {
                        // Mood dot / emoji
                        if let level = point.moodLevel {
                            Text(point.emoji)
                                .font(.title3)
                            
                            // Mood bar
                            RoundedRectangle(cornerRadius: 3)
                                .fill(moodColor(for: level))
                                .frame(width: 8, height: CGFloat(level) * 10)
                        } else {
                            Text("—")
                                .font(.title3)
                                .foregroundColor(.secondary)
                            
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.secondary.opacity(0.2))
                                .frame(width: 8, height: 10)
                        }
                        
                        Text(point.label)
                            .font(.custom("Avenir-Medium", size: 10))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 110)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
    }
    
    // MARK: - Streaks Card
    
    private var streaksCard: some View {
        HStack(spacing: 16) {
            // Mood streak
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundColor(Color("AccentPink"))
                    Text("Mood Streak")
                        .font(.custom("Avenir-Heavy", size: 12))
                        .foregroundColor(.secondary)
                }
                Text("\(character.moodStreak)")
                    .font(.custom("Avenir-Heavy", size: 28))
                    .foregroundColor(Color("AccentPink"))
                Text("day\(character.moodStreak == 1 ? "" : "s")")
                    .font(.custom("Avenir-Medium", size: 11))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color("CardBackground"))
            )
            
            // Meditation streak
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "brain.head.profile")
                        .font(.caption)
                        .foregroundColor(Color("AccentPurple"))
                    Text("Meditation")
                        .font(.custom("Avenir-Heavy", size: 12))
                        .foregroundColor(.secondary)
                }
                Text("\(character.meditationStreak)")
                    .font(.custom("Avenir-Heavy", size: 28))
                    .foregroundColor(Color("AccentPurple"))
                Text("day\(character.meditationStreak == 1 ? "" : "s")")
                    .font(.custom("Avenir-Medium", size: 11))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color("CardBackground"))
            )
        }
    }
    
    // MARK: - Mood Stats
    
    private var moodStatsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(Color("AccentGold"))
                Text("Mood Stats")
                    .font(.custom("Avenir-Heavy", size: 16))
                Spacer()
            }
            
            HStack(spacing: 0) {
                // Days tracked
                VStack(spacing: 4) {
                    Text("\(moodEntries.count)")
                        .font(.custom("Avenir-Heavy", size: 20))
                    Text("Days Tracked")
                        .font(.custom("Avenir-Medium", size: 10))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                // Average mood
                if let avg = averageMood {
                    VStack(spacing: 4) {
                        Text(String(format: "%.1f", avg))
                            .font(.custom("Avenir-Heavy", size: 20))
                        Text("Avg Mood")
                            .font(.custom("Avenir-Medium", size: 10))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Most common
                if let common = mostCommonMood {
                    VStack(spacing: 4) {
                        Text(moodEmoji(for: common))
                            .font(.title3)
                        Text("Most Common")
                            .font(.custom("Avenir-Medium", size: 10))
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
        )
    }
    
    // MARK: - Journal Card
    
    private var journalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "book.fill")
                    .foregroundColor(Color("AccentGold"))
                Text("Journal Entries")
                    .font(.custom("Avenir-Heavy", size: 16))
                Spacer()
            }
            
            ForEach(journalEntries.prefix(10), id: \.id) { entry in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(entry.moodEmoji)
                            .font(.callout)
                        Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.custom("Avenir-Heavy", size: 12))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(entry.moodLabel)
                            .font(.custom("Avenir-Heavy", size: 11))
                            .foregroundColor(moodColor(for: entry.moodLevel))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(moodColor(for: entry.moodLevel).opacity(0.2))
                            )
                    }
                    
                    if let text = entry.journalText {
                        Text(text)
                            .font(.custom("Avenir-Medium", size: 14))
                            .foregroundColor(.primary)
                            .lineLimit(3)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(0.06))
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
    }
    
    // MARK: - Meditation Card
    
    private var meditationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(Color("AccentPurple"))
                Text("Meditation")
                    .font(.custom("Avenir-Heavy", size: 16))
                Spacer()
            }
            
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("\(character.meditationStreak)")
                        .font(.custom("Avenir-Heavy", size: 22))
                        .foregroundColor(Color("AccentPurple"))
                    Text("Current Streak")
                        .font(.custom("Avenir-Medium", size: 11))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                VStack(spacing: 4) {
                    Image(systemName: character.hasMeditatedToday ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(character.hasMeditatedToday ? Color("AccentGreen") : .secondary)
                    Text(character.hasMeditatedToday ? "Done Today" : "Not Yet")
                        .font(.custom("Avenir-Medium", size: 11))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
    }
    
    // MARK: - Wisdom Buff Card
    
    private var wisdomBuffCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.title2)
                .foregroundColor(Color("AccentPurple"))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Wisdom Buff Active")
                    .font(.custom("Avenir-Heavy", size: 14))
                    .foregroundColor(Color("AccentPurple"))
                
                if let expires = character.wisdomBuffExpiresAt {
                    let remaining = expires.timeIntervalSinceNow
                    let hours = Int(remaining / 3600)
                    let minutes = Int((remaining.truncatingRemainder(dividingBy: 3600)) / 60)
                    Text("+5% Wisdom • \(hours)h \(minutes)m remaining")
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                } else {
                    Text("+5% Wisdom boost from meditation")
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color("AccentPurple").opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color("AccentPurple").opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Wellness Achievements Card
    
    private var wellnessAchievementsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "medal.fill")
                    .foregroundColor(Color("AccentGold"))
                Text("Wellness Achievements")
                    .font(.custom("Avenir-Heavy", size: 16))
                Spacer()
            }
            
            ForEach(wellnessAchievements, id: \.id) { achievement in
                HStack(spacing: 12) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(achievement.isUnlocked ? Color("AccentGold").opacity(0.2) : Color.secondary.opacity(0.1))
                            .frame(width: 40, height: 40)
                        Image(systemName: achievement.icon)
                            .font(.system(size: 18))
                            .foregroundColor(achievement.isUnlocked ? Color("AccentGold") : .secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(achievement.name)
                                .font(.custom("Avenir-Heavy", size: 14))
                                .foregroundColor(achievement.isUnlocked ? .primary : .secondary)
                            
                            if achievement.isUnlocked {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(Color("AccentGreen"))
                            }
                        }
                        
                        Text(achievement.achievementDescription)
                            .font(.custom("Avenir-Medium", size: 12))
                            .foregroundColor(.secondary)
                        
                        // Progress bar
                        if !achievement.isUnlocked {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.secondary.opacity(0.2))
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color("AccentGold"), Color("AccentOrange")],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * achievement.progress)
                                }
                            }
                            .frame(height: 6)
                            
                            Text("\(achievement.currentValue)/\(achievement.targetValue)")
                                .font(.custom("Avenir-Medium", size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Reward badge
                    VStack(spacing: 2) {
                        Image(systemName: achievement.rewardType == .exp ? "sparkles" : achievement.rewardType == .gold ? "dollarsign.circle.fill" : "diamond.fill")
                            .font(.caption)
                            .foregroundColor(Color("AccentGold"))
                        Text("+\(achievement.rewardAmount)")
                            .font(.custom("Avenir-Heavy", size: 11))
                            .foregroundColor(Color("AccentGold"))
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(achievement.isUnlocked ? Color("AccentGold").opacity(0.05) : Color.secondary.opacity(0.04))
                )
                
                if achievement.id != wellnessAchievements.last?.id {
                    Divider()
                        .padding(.horizontal, 4)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
    }
    
    // MARK: - Helpers
    
    private func moodColor(for level: Int) -> Color {
        switch level {
        case 1: return .red
        case 2: return Color("AccentOrange")
        case 3: return Color("AccentGold")
        case 4: return Color("AccentGreen")
        case 5: return Color("AccentPink")
        default: return .secondary
        }
    }
    
    private func moodEmoji(for level: Int) -> String {
        switch level {
        case 1: return "😞"
        case 2: return "😔"
        case 3: return "😐"
        case 4: return "😊"
        case 5: return "😄"
        default: return "😐"
        }
    }
    
    private func dayAbbreviation(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Types

struct DailyMoodPoint {
    let label: String
    let moodLevel: Int?
    let emoji: String
}
