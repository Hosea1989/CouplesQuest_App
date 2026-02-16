import SwiftUI

/// Read-only character inspect sheet shown when tapping a party member's avatar.
/// Fetches the latest profile from Supabase on appear, falls back to cached data.
struct PlayerInspectView: View {
    let memberID: UUID
    let cachedMember: CachedPartyMember
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var snapshot: CharacterSnapshot?
    @State private var isLoading = true
    @State private var loadFailed = false
    
    /// Use snapshot data if available, otherwise fall back to cached
    private var displayName: String { snapshot?.name ?? cachedMember.name }
    private var displayLevel: Int { snapshot?.level ?? cachedMember.level }
    private var displayClass: String? { snapshot?.characterClass ?? cachedMember.className }
    private var displayAvatar: String { snapshot?.avatarIcon ?? cachedMember.displayAvatarIcon }
    private var displayFrame: String { snapshot?.avatarFrame ?? cachedMember.avatarFrame ?? "frame_default" }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color("BackgroundTop"), Color("BackgroundBottom")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Drag indicator
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                
                if isLoading {
                    Spacer()
                    ProgressView("Loading profile...")
                        .tint(.white)
                        .foregroundColor(.white)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Header
                            playerHeader
                            
                            // Stats
                            statsSection
                            
                            // Highlights
                            highlightsSection
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .task {
            await loadProfile()
        }
    }
    
    // MARK: - Player Header
    
    private var playerHeader: some View {
        VStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [classColor.opacity(0.4), classColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)
                
                if let uiImage = UIImage(named: displayAvatar) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 76, height: 76)
                        .clipShape(Circle())
                } else {
                    Image(systemName: displayAvatar)
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                }
            }
            
            // Name
            Text(displayName)
                .font(.custom("Avenir-Heavy", size: 24))
                .foregroundColor(.white)
            
            // Level + Class
            HStack(spacing: 12) {
                Text("Level \(displayLevel)")
                    .font(.custom("Avenir-Heavy", size: 15))
                    .foregroundColor(Color("AccentGold"))
                
                if let cls = displayClass {
                    HStack(spacing: 4) {
                        if let charClass = CharacterClass(rawValue: cls) {
                            Image(systemName: charClass.icon)
                                .font(.caption)
                        }
                        Text(cls)
                            .font(.custom("Avenir-Heavy", size: 13))
                    }
                    .foregroundColor(classColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(classColor.opacity(0.15))
                    .clipShape(Capsule())
                }
            }
            
            // Hero Power
            if let power = heroPowerValue {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.caption2)
                    Text("Hero Power: \(power)")
                        .font(.custom("Avenir-Medium", size: 13))
                }
                .foregroundColor(Color("AccentGold").opacity(0.8))
            }
            
            // Paragon badge
            if let paragon = snapshot?.paragonLevel, paragon > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "star.circle.fill")
                        .font(.caption)
                    Text("Paragon \(paragon)")
                        .font(.custom("Avenir-Heavy", size: 12))
                }
                .foregroundColor(.orange)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.15))
                .clipShape(Capsule())
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        VStack(spacing: 12) {
            sectionHeader(title: "STATS", icon: "chart.bar.fill")
            
            VStack(spacing: 8) {
                ForEach(StatType.allCases, id: \.rawValue) { stat in
                    inspectStatRow(stat: stat)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("CardBackground").opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
    }
    
    private func inspectStatRow(stat: StatType) -> some View {
        let value = statValueFor(stat)
        let maxValue = max(value ?? 0, 100) // Scale bar relative to 100 or current if higher
        
        return HStack(spacing: 10) {
            // Stat icon
            Image(systemName: stat.icon)
                .font(.system(size: 14))
                .foregroundColor(Color(stat.color))
                .frame(width: 20)
            
            // Stat name
            Text(stat.shortName)
                .font(.custom("Avenir-Heavy", size: 13))
                .foregroundColor(.white)
                .frame(width: 32, alignment: .leading)
            
            // Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 8)
                    
                    // Fill
                    if let val = value, val > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [Color(stat.color), Color(stat.color).opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(val) / CGFloat(maxValue), height: 8)
                    }
                }
            }
            .frame(height: 8)
            
            // Value
            Text(value != nil ? "\(value!)" : "--")
                .font(.custom("Avenir-Heavy", size: 14))
                .foregroundColor(.white)
                .frame(width: 36, alignment: .trailing)
        }
        .frame(height: 24)
    }
    
    // MARK: - Highlights Section
    
    private var highlightsSection: some View {
        VStack(spacing: 12) {
            sectionHeader(title: "HIGHLIGHTS", icon: "trophy.fill")
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                highlightCard(
                    icon: "checkmark.circle.fill",
                    label: "Tasks Done",
                    value: formatOptional(snapshot?.tasksCompleted ?? cachedMember.tasksCompleted),
                    color: "AccentGreen"
                )
                
                highlightCard(
                    icon: "flame.fill",
                    label: "Streak",
                    value: formatOptional(snapshot?.currentStreak ?? cachedMember.currentStreak),
                    color: "AccentOrange"
                )
                
                highlightCard(
                    icon: "shield.lefthalf.filled",
                    label: "Arena Best",
                    value: formatOptional(snapshot?.arenaBestWave ?? cachedMember.arenaBestWave, suffix: ""),
                    color: "AccentPurple"
                )
                
                highlightCard(
                    icon: "dollarsign.circle.fill",
                    label: "Gold",
                    value: formatOptional(snapshot?.gold ?? cachedMember.gold),
                    color: "AccentGold"
                )
            }
        }
    }
    
    private func highlightCard(icon: String, label: String, value: String, color: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color(color))
            
            Text(value)
                .font(.custom("Avenir-Heavy", size: 20))
                .foregroundColor(.white)
            
            Text(label)
                .font(.custom("Avenir-Medium", size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color("CardBackground").opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color(color).opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Helpers
    
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(Color("AccentGold"))
            Text(title)
                .font(.custom("Avenir-Heavy", size: 13))
                .foregroundColor(Color("AccentGold"))
            Spacer()
        }
    }
    
    private var classColor: Color {
        guard let cls = displayClass,
              let charClass = CharacterClass(rawValue: cls) else {
            return Color("AccentPurple")
        }
        return Color(charClass.primaryStat.color)
    }
    
    private var heroPowerValue: Int? {
        if let s = snapshot {
            let total = s.strength + s.wisdom + s.charisma + s.dexterity + s.luck + s.defense
            return total * 10 + s.level * 5
        }
        return cachedMember.heroPower.map { $0 * 10 + cachedMember.level * 5 }
    }
    
    private func statValueFor(_ stat: StatType) -> Int? {
        // Prefer snapshot, fall back to cached
        if let s = snapshot {
            switch stat {
            case .strength: return s.strength
            case .wisdom: return s.wisdom
            case .charisma: return s.charisma
            case .dexterity, .endurance: return s.dexterity
            case .luck: return s.luck
            case .defense: return s.defense
            }
        }
        return cachedMember.statValue(for: stat)
    }
    
    private func formatOptional(_ value: Int?, suffix: String = "") -> String {
        guard let v = value else { return "--" }
        return "\(v)\(suffix)"
    }
    
    // MARK: - Data Loading
    
    private func loadProfile() async {
        do {
            if let profile = try await SupabaseService.shared.fetchProfile(byID: memberID) {
                snapshot = profile.characterData
            }
        } catch {
            print("Failed to load player profile: \(error)")
            loadFailed = true
        }
        isLoading = false
    }
}
