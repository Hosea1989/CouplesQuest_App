import SwiftUI
import SwiftData

struct CharacterView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var characters: [PlayerCharacter]
    
    @State private var selectedTab: CharacterTab = .stats
    
    private var character: PlayerCharacter? {
        characters.first
    }
    
    enum CharacterTab: String, CaseIterable {
        case stats = "Stats"
        case equipment = "Equipment"
        case achievements = "Achievements"
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
                
                if let character = character {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Character Header
                            CharacterHeader(character: character)
                            
                            // Tab Selector
                            CharacterTabSelector(selectedTab: $selectedTab)
                            
                            // Tab Content
                            switch selectedTab {
                            case .stats:
                                StatsTabContent(character: character)
                            case .equipment:
                                EquipmentTabContent(character: character)
                            case .achievements:
                                AchievementsTabContent(character: character)
                            }
                        }
                        .padding()
                    }
                } else {
                    ContentUnavailableView(
                        "No Character",
                        systemImage: "person.fill.questionmark",
                        description: Text("Create a character from the Home tab to get started.")
                    )
                }
            }
            .navigationTitle("Character")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Character Header

struct CharacterHeader: View {
    @Bindable var character: PlayerCharacter
    @State private var showAvatarPicker = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Avatar (tappable)
            Button(action: { showAvatarPicker = true }) {
                AvatarPreview(
                    icon: character.avatarIcon,
                    frame: character.avatarFrame,
                    size: 100,
                    character: character
                )
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showAvatarPicker) {
                AvatarPickerView(character: character)
            }
            
            VStack(spacing: 4) {
                Text(character.name)
                    .font(.custom("Avenir-Heavy", size: 28))
                
                HStack(spacing: 8) {
                    Text("Level \(character.level)")
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(Color("AccentGold"))
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(character.title)
                        .font(.custom("Avenir-Medium", size: 16))
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 3) {
                        Image(systemName: "bolt.shield.fill")
                            .font(.system(size: 12))
                        Text("\(character.heroPower)")
                            .font(.custom("Avenir-Heavy", size: 14))
                    }
                    .foregroundColor(Color("AccentOrange"))
                }
                
                if let characterClass = character.characterClass {
                    HStack(spacing: 6) {
                        Image(systemName: characterClass.icon)
                        Text(characterClass.rawValue)
                    }
                    .font(.custom("Avenir-Medium", size: 14))
                    .foregroundColor(Color("AccentPurple"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color("AccentPurple").opacity(0.2))
                    )
                }
            }
            
            // EXP Progress Bar
            VStack(spacing: 6) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Track
                        Capsule()
                            .fill(Color("CardBackground"))
                            .frame(height: 10)
                        
                        // Fill
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color("AccentGold"), Color("AccentOrange")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, geometry.size.width * CGFloat(character.levelProgress)), height: 10)
                            .animation(.easeInOut(duration: 0.5), value: character.levelProgress)
                    }
                }
                .frame(height: 10)
                
                let currentLevelExp = GameEngine.expRequired(forLevel: character.level)
                let nextLevelExp = GameEngine.expRequired(forLevel: character.level + 1)
                let expIntoLevel = character.currentEXP - currentLevelExp
                let expNeeded = nextLevelExp - currentLevelExp
                
                Text("EXP: \(expIntoLevel) / \(expNeeded)")
                    .font(.custom("Avenir-Medium", size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Tab Selector

struct CharacterTabSelector: View {
    @Binding var selectedTab: CharacterView.CharacterTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(CharacterView.CharacterTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    Text(tab.rawValue)
                        .font(.custom("Avenir-Heavy", size: 14))
                        .foregroundColor(selectedTab == tab ? Color("AccentGold") : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selectedTab == tab ?
                            Color("AccentGold").opacity(0.15) :
                            Color.clear
                        )
                }
            }
        }
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Stats Tab

struct StatsTabContent: View {
    @Bindable var character: PlayerCharacter
    @EnvironmentObject var gameEngine: GameEngine
    @State private var showEvolution = false
    
    private var canShowEvolution: Bool {
        guard let charClass = character.characterClass, charClass.tier == .starter else { return false }
        return character.level >= 20
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Class Evolution Banner
            if canShowEvolution {
                Button(action: { showEvolution = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.forward.circle.fill")
                            .foregroundColor(Color("AccentOrange"))
                        Text("Class Evolution Available!")
                            .font(.custom("Avenir-Heavy", size: 14))
                            .foregroundColor(Color("AccentOrange"))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(Color("AccentOrange"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("AccentOrange").opacity(0.15))
                    )
                }
                .buttonStyle(.plain)
            }
            
            // Stat points banner
            if character.unspentStatPoints > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundColor(Color("AccentGold"))
                    Text("You have \(character.unspentStatPoints) stat point\(character.unspentStatPoints == 1 ? "" : "s") to allocate!")
                        .font(.custom("Avenir-Heavy", size: 14))
                        .foregroundColor(Color("AccentGold"))
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("AccentGold").opacity(0.15))
                )
            }
            
            ForEach(StatType.allCases, id: \.self) { statType in
                StatBarRow(
                    character: character,
                    statType: statType,
                    value: character.stats.value(for: statType),
                    effectiveValue: character.effectiveStats.value(for: statType),
                    canAllocate: character.unspentStatPoints > 0
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
        .sheet(isPresented: $showEvolution) {
            ClassEvolutionView(character: character)
                .environmentObject(gameEngine)
        }
    }
}

struct StatBarRow: View {
    @Bindable var character: PlayerCharacter
    let statType: StatType
    let value: Int
    let effectiveValue: Int
    let canAllocate: Bool
    
    /// Reasonable max for the bar display
    private let barMax: Int = 50
    
    @State private var justAllocated: Bool = false
    
    var bonusValue: Int {
        effectiveValue - value
    }
    
    var barProgress: Double {
        min(1.0, Double(effectiveValue) / Double(barMax))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Top row: icon, name, value, allocate button
            HStack(spacing: 10) {
                Image(systemName: statType.icon)
                    .font(.system(size: 18))
                    .foregroundColor(Color(statType.color))
                    .frame(width: 24)
                    .symbolEffect(.bounce, value: effectiveValue)
                
                Text(statType.rawValue)
                    .font(.custom("Avenir-Heavy", size: 15))
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("\(effectiveValue)")
                        .font(.custom("Avenir-Heavy", size: 20))
                        .foregroundColor(Color(statType.color))
                        .scaleEffect(justAllocated ? 1.3 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: justAllocated)
                    
                    if bonusValue > 0 {
                        Text("+\(bonusValue)")
                            .font(.custom("Avenir-Medium", size: 11))
                            .foregroundColor(Color("AccentGreen"))
                    }
                }
                
                if canAllocate {
                    Button(action: allocatePoint) {
                        ZStack {
                            Circle()
                                .fill(Color("AccentGold").opacity(0.2))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color("AccentGold"))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Horizontal bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(Color(statType.color).opacity(0.15))
                        .frame(height: 10)
                    
                    // Fill
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(statType.color).opacity(0.7), Color(statType.color)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geometry.size.width * CGFloat(barProgress)), height: 10)
                        .animation(.easeInOut(duration: 0.4), value: barProgress)
                }
            }
            .frame(height: 10)
            
            // Description
            Text(statType.description)
                .font(.custom("Avenir-Medium", size: 11))
                .foregroundColor(.secondary)
        }
    }
    
    private func allocatePoint() {
        character.stats.increase(statType, by: 1)
        character.unspentStatPoints -= 1
        justAllocated = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            justAllocated = false
        }
    }
}

// MARK: - Equipment Tab

struct EquipmentTabContent: View {
    let character: PlayerCharacter
    
    var body: some View {
        VStack(spacing: 16) {
            EquipmentSlotRow(
                slot: .weapon,
                equipment: character.equipment.weapon
            )
            
            EquipmentSlotRow(
                slot: .armor,
                equipment: character.equipment.armor
            )
            
            EquipmentSlotRow(
                slot: .accessory,
                equipment: character.equipment.accessory
            )
            
            NavigationLink(destination: InventoryView()) {
                HStack {
                    Image(systemName: "bag.fill")
                        .foregroundColor(Color("AccentGold"))
                    Text("View Full Inventory")
                        .font(.custom("Avenir-Heavy", size: 14))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("AccentGold").opacity(0.1))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
    }
}

struct EquipmentSlotRow: View {
    let slot: EquipmentSlot
    let equipment: Equipment?
    
    var body: some View {
        HStack(spacing: 16) {
            // Slot icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 56, height: 56)
                
                EquipmentIconView(item: equipment, slot: slot, size: 56)
            }
            
            // Equipment info
            VStack(alignment: .leading, spacing: 4) {
                Text(slot.rawValue)
                    .font(.custom("Avenir-Heavy", size: 14))
                    .foregroundColor(.secondary)
                
                if let equipment = equipment {
                    Text(equipment.name)
                        .font(.custom("Avenir-Heavy", size: 16))
                    Text(equipment.statSummary)
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(Color("AccentGreen"))
                } else {
                    Text("Empty Slot")
                        .font(.custom("Avenir-Medium", size: 16))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let equipment = equipment {
                Text(equipment.rarity.rawValue)
                    .font(.custom("Avenir-Heavy", size: 11))
                    .foregroundColor(Color(equipment.rarity.color))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(equipment.rarity.color).opacity(0.2))
                    )
            }
        }
    }
}

// MARK: - Achievements Tab

struct AchievementsTabContent: View {
    var character: PlayerCharacter
    
    /// Sorted achievements: unlocked first (by date), then closest-to-complete, then locked
    private var sortedAchievements: [Achievement] {
        character.achievements.sorted { a, b in
            if a.isUnlocked && !b.isUnlocked { return true }
            if !a.isUnlocked && b.isUnlocked { return false }
            if a.isUnlocked && b.isUnlocked {
                return (a.unlockedAt ?? .distantPast) > (b.unlockedAt ?? .distantPast)
            }
            return a.progress > b.progress
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if character.achievements.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("No Achievements Yet")
                        .font(.custom("Avenir-Heavy", size: 18))
                    
                    Text("Complete tasks and missions to earn achievements!")
                        .font(.custom("Avenir-Medium", size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(40)
            } else {
                // Summary
                let unlockedCount = character.achievements.filter { $0.isUnlocked }.count
                let totalCount = character.achievements.count
                
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(Color("AccentGold"))
                    Text("\(unlockedCount) / \(totalCount) Achievements")
                        .font(.custom("Avenir-Heavy", size: 14))
                        .foregroundColor(Color("AccentGold"))
                    Spacer()
                }
                
                ForEach(sortedAchievements, id: \.id) { achievement in
                    AchievementRow(achievement: achievement)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
    }
}

struct AchievementRow: View {
    var achievement: Achievement
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon with gold border when unlocked
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? Color("AccentGold").opacity(0.2) : Color.secondary.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                if achievement.isUnlocked {
                    Circle()
                        .stroke(Color("AccentGold"), lineWidth: 2)
                        .frame(width: 44, height: 44)
                }
                
                Image(systemName: achievement.icon)
                    .foregroundColor(achievement.isUnlocked ? Color("AccentGold") : .secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.name)
                    .font(.custom("Avenir-Heavy", size: 14))
                    .foregroundColor(achievement.isUnlocked ? .primary : .secondary)
                
                Text(achievement.achievementDescription)
                    .font(.custom("Avenir-Medium", size: 12))
                    .foregroundColor(.secondary)
                
                // Progress bar for locked achievements
                if !achievement.isUnlocked {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.secondary.opacity(0.2))
                                .frame(height: 6)
                            
                            Capsule()
                                .fill(Color("AccentGold"))
                                .frame(width: max(0, geometry.size.width * CGFloat(achievement.progress)), height: 6)
                        }
                    }
                    .frame(height: 6)
                    
                    Text("\(achievement.currentValue) / \(achievement.targetValue)")
                        .font(.custom("Avenir-Medium", size: 10))
                        .foregroundColor(.secondary)
                }
                
                // Unlock date for completed achievements
                if achievement.isUnlocked, let date = achievement.unlockedAt {
                    Text("Unlocked \(date.formatted(date: .abbreviated, time: .omitted))")
                        .font(.custom("Avenir-Medium", size: 10))
                        .foregroundColor(Color("AccentGold").opacity(0.7))
                }
            }
            
            Spacer()
            
            if achievement.isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color("AccentGreen"))
                    .font(.title3)
            } else {
                // Reward preview
                VStack(spacing: 2) {
                    Text("\(achievement.rewardAmount)")
                        .font(.custom("Avenir-Heavy", size: 12))
                    Text(achievement.rewardType.rawValue)
                        .font(.custom("Avenir-Medium", size: 9))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

#Preview {
    CharacterView()
        .environmentObject(GameEngine())
}

