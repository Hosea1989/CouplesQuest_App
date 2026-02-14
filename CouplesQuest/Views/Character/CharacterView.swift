import SwiftUI
import SwiftData

struct CharacterView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var characters: [PlayerCharacter]
    
    @State private var selectedTab: CharacterTab = .stats
    @State private var showAccountSheet = false
    
    private var character: PlayerCharacter? {
        characters.first
    }
    
    enum CharacterTab: String, CaseIterable {
        case stats = "Stats"
        case equipment = "Equipment"
        case achievements = "Achievements"
        case wellness = "Wellness"
        case bestiary = "Bestiary"
        case research = "Research"
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
                            case .wellness:
                                WellnessTabContent(character: character)
                            case .bestiary:
                                BestiaryTabContent(character: character)
                            case .research:
                                ResearchTabContent(character: character)
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAccountSheet = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(Color("AccentGold"))
                    }
                }
            }
            .sheet(isPresented: $showAccountSheet) {
                SettingsView()
            }
        }
    }
}

// MARK: - Account Settings

struct AccountSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var supabase = SupabaseService.shared
    
    @State private var showSignOutConfirm = false
    @State private var showDeleteConfirm = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    
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
                    VStack(spacing: 24) {
                        // Account Info
                        VStack(spacing: 12) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(Color("AccentGold"))
                            
                            if let email = supabase.currentProfile?.email {
                                Text(email)
                                    .font(.custom("Avenir-Medium", size: 16))
                                    .foregroundColor(.secondary)
                            }
                            
                            if let code = supabase.currentProfile?.partnerCode {
                                HStack(spacing: 6) {
                                    Text("Partner Code:")
                                        .font(.custom("Avenir-Medium", size: 13))
                                        .foregroundColor(.secondary)
                                    Text(code)
                                        .font(.custom("Avenir-Heavy", size: 13))
                                        .foregroundColor(Color("AccentGold"))
                                }
                            }
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color("CardBackground"))
                        )
                        
                        // Error banner
                        if let errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(errorMessage)
                                    .font(.custom("Avenir-Medium", size: 13))
                                    .foregroundColor(.red)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.red.opacity(0.1))
                            )
                        }
                        
                        // Sign Out
                        Button(action: { showSignOutConfirm = true }) {
                            HStack(spacing: 10) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Sign Out")
                                    .font(.custom("Avenir-Heavy", size: 16))
                                Spacer()
                                if isProcessing {
                                    ProgressView()
                                }
                            }
                            .foregroundColor(Color("AccentGold"))
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color("CardBackground"))
                            )
                        }
                        .disabled(isProcessing)
                        
                        // Delete Account
                        Button(action: { showDeleteConfirm = true }) {
                            HStack(spacing: 10) {
                                Image(systemName: "trash.fill")
                                Text("Delete Account")
                                    .font(.custom("Avenir-Heavy", size: 16))
                                Spacer()
                            }
                            .foregroundColor(.red)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.red.opacity(0.1))
                            )
                        }
                        .disabled(isProcessing)
                        
                        Text("Deleting your account will permanently remove all your data. This cannot be undone.")
                            .font(.custom("Avenir-Medium", size: 12))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                }
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color("AccentGold"))
                }
            }
            .alert("Sign Out?", isPresented: $showSignOutConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) { performSignOut() }
            } message: {
                Text("You will be signed out and your local character data will be cleared from this device.")
            }
            .alert("Delete Account?", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Forever", role: .destructive) { performDeleteAccount() }
            } message: {
                Text("This will permanently delete your account and all associated data. This action cannot be undone.")
            }
        }
    }
    
    private func performSignOut() {
        isProcessing = true
        errorMessage = nil
        Task {
            do {
                try await supabase.signOut()
                clearLocalData()
                dismiss()
            } catch {
                errorMessage = "Failed to sign out. Please try again."
                isProcessing = false
            }
        }
    }
    
    private func performDeleteAccount() {
        isProcessing = true
        errorMessage = nil
        Task {
            do {
                try await supabase.deleteAccount()
                clearLocalData()
                dismiss()
            } catch {
                errorMessage = "Failed to delete account. Please try again."
                isProcessing = false
            }
        }
    }
    
    /// Remove all local SwiftData objects so the next sign-in starts fresh.
    private func clearLocalData() {
        do {
            try modelContext.delete(model: PlayerCharacter.self)
            try modelContext.delete(model: GameTask.self)
            try modelContext.delete(model: Equipment.self)
            try modelContext.delete(model: EquipmentLoadout.self)
            try modelContext.delete(model: Stats.self)
            try modelContext.delete(model: Achievement.self)
            try modelContext.delete(model: AFKMission.self)
            try modelContext.delete(model: ActiveMission.self)
            try modelContext.delete(model: Dungeon.self)
            try modelContext.delete(model: DungeonRun.self)
            try modelContext.delete(model: DailyQuest.self)
            try modelContext.delete(model: Bond.self)
            try modelContext.delete(model: PartnerInteraction.self)
            try modelContext.delete(model: WeeklyRaidBoss.self)
            try modelContext.delete(model: ArenaRun.self)
            try modelContext.delete(model: CraftingMaterial.self)
            try modelContext.delete(model: Consumable.self)
            try modelContext.delete(model: MoodEntry.self)
            try modelContext.delete(model: MonsterCard.self)
            try modelContext.save()
        } catch {
            print("Failed to clear local data: \(error)")
        }
        ActiveMission.clearPersisted()
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
                    // Show paragon level alongside normal level when applicable
                    if let paragon = character.paragonDisplayString {
                        Text("Lv.100")
                            .font(.custom("Avenir-Heavy", size: 16))
                            .foregroundColor(Color("AccentGold"))
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(paragon)
                            .font(.custom("Avenir-Heavy", size: 16))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color("AccentGold"), Color("AccentPurple")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    } else {
                        Text("Level \(character.level)")
                            .font(.custom("Avenir-Heavy", size: 16))
                            .foregroundColor(Color("AccentGold"))
                    }
                    
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
                if character.level >= 100 {
                    // Paragon EXP bar (gold-to-purple gradient)
                    let paragonProgress: Double = {
                        let required = character.paragonEXPRequired
                        let base = GameEngine.expRequired(forLevel: 100)
                        let current = character.currentEXP - base
                        let needed = required - base
                        guard needed > 0 else { return 1.0 }
                        return min(1.0, Double(current) / Double(needed))
                    }()
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color("CardBackground"))
                                .frame(height: 10)
                            
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color("AccentGold"), Color("AccentPurple")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(0, geometry.size.width * CGFloat(paragonProgress)), height: 10)
                                .animation(.easeInOut(duration: 0.5), value: paragonProgress)
                        }
                    }
                    .frame(height: 10)
                    
                    let base = GameEngine.expRequired(forLevel: 100)
                    let expIntoParagon = character.currentEXP - base
                    let expNeeded = character.paragonEXPRequired - base
                    
                    Text("Paragon EXP: \(expIntoParagon) / \(expNeeded)")
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                } else {
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
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Tab Selector

struct CharacterTabSelector: View {
    @Binding var selectedTab: CharacterView.CharacterTab
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(CharacterView.CharacterTab.allCases, id: \.self) { tab in
                    Button(action: {
                        selectedTab = tab
                        AudioManager.shared.play(.tabSwitch)
                    }) {
                        Text(tab.rawValue)
                            .font(.custom("Avenir-Heavy", size: 12))
                            .lineLimit(1)
                            .foregroundColor(selectedTab == tab ? Color("AccentGold") : .secondary)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 12)
                            .background(
                                selectedTab == tab ?
                                Color("AccentGold").opacity(0.15) :
                                Color.clear
                            )
                    }
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
    @State private var showRebirth = false
    
    private var canShowEvolution: Bool {
        guard let charClass = character.characterClass, charClass.tier == .starter else { return false }
        return character.level >= 20
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Rebirth Banner (level 100+ only)
            if character.canRebirth {
                Button(action: { showRebirth = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.trianglehead.2.counterclockwise.rotate.90")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color("AccentGold"), Color("AccentPurple")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Rebirth Available!")
                                .font(.custom("Avenir-Heavy", size: 14))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color("AccentGold"), Color("AccentPurple")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            Text("Reset your journey for permanent power")
                                .font(.custom("Avenir-Medium", size: 11))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(Color("AccentPurple"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [Color("AccentGold").opacity(0.1), Color("AccentPurple").opacity(0.1)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
                .buttonStyle(.plain)
            }
            
            // Paragon Level Up Banner
            if character.canParagonLevelUp {
                Button(action: {
                    gameEngine.paragonLevelUp(character: character)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundColor(Color("AccentPurple"))
                        Text("Paragon Level Up!")
                            .font(.custom("Avenir-Heavy", size: 14))
                            .foregroundColor(Color("AccentPurple"))
                        Spacer()
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(Color("AccentPurple"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("AccentPurple").opacity(0.15))
                    )
                }
                .buttonStyle(.plain)
            }
            
            // Class Evolution Banner
            if canShowEvolution {
                Button(action: { showEvolution = true }) {
                    VStack(alignment: .leading, spacing: 4) {
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
                        Text("Complete a Rank-Up Course in Training to evolve")
                            .font(.custom("Avenir-Medium", size: 11))
                            .foregroundColor(.secondary)
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
            
            // Rebirth permanent bonuses summary
            if character.rebirthCount > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color("AccentGold"), Color("AccentPurple")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Text("Rebirth Bonuses (\(character.rebirthCount)x)")
                            .font(.custom("Avenir-Heavy", size: 14))
                            .foregroundColor(Color("AccentPurple"))
                    }
                    
                    let bonuses = character.getPermanentBonuses()
                    if let expBonus = bonuses["expBonus"], expBonus > 0 {
                        rebirthBonusRow(label: "EXP Bonus", value: "+\(Int(expBonus * 100))%", icon: "arrow.up.circle.fill")
                    }
                    if let goldBonus = bonuses["goldBonus"], goldBonus > 0 {
                        rebirthBonusRow(label: "Gold Bonus", value: "+\(Int(goldBonus * 100))%", icon: "dollarsign.circle.fill")
                    }
                    if let lootBonus = bonuses["lootBonus"], lootBonus > 0 {
                        rebirthBonusRow(label: "Loot Drop Bonus", value: "+\(Int(lootBonus * 100))%", icon: "gift.fill")
                    }
                    if let statsBonus = bonuses["allStatsBonus"], statsBonus > 0 {
                        rebirthBonusRow(label: "All Stats Bonus", value: "+\(Int(statsBonus * 100))%", icon: "chart.bar.fill")
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("AccentPurple").opacity(0.08))
                )
            }
            
            // HP Section
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(Color("DifficultyHard"))
                    Text("HP")
                        .font(.custom("Avenir-Heavy", size: 14))
                    Spacer()
                    Text(character.hpDisplay)
                        .font(.custom("Avenir-Heavy", size: 14))
                        .foregroundColor(.primary)
                }
                
                // HP progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 10)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(hpBarColor(character.hpPercentage))
                            .frame(width: geometry.size.width * character.hpPercentage, height: 10)
                    }
                }
                .frame(height: 10)
                
                // Regen info
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.heart.fill")
                        .font(.system(size: 10))
                    Text("+\(character.regenRatePerHour) HP/hr")
                        .font(.custom("Avenir-Medium", size: 11))
                    if character.hasActiveRegenBuff {
                        Text("BUFFED")
                            .font(.custom("Avenir-Heavy", size: 9))
                            .foregroundColor(Color("AccentGreen"))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(Color("AccentGreen").opacity(0.2)))
                    }
                }
                .foregroundColor(.secondary)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color("CardBackground")))
            
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
        .sheet(isPresented: $showRebirth) {
            RebirthView(character: character)
                .environmentObject(gameEngine)
        }
    }
    
    private func hpBarColor(_ percentage: Double) -> Color {
        switch percentage {
        case 0.6...: return Color("AccentGreen")
        case 0.3...: return Color("AccentGold")
        default: return Color("DifficultyHard")
        }
    }
    
    @ViewBuilder
    private func rebirthBonusRow(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(Color("AccentGold"))
                .frame(width: 16)
            Text(label)
                .font(.custom("Avenir-Medium", size: 12))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.custom("Avenir-Heavy", size: 13))
                .foregroundColor(Color("AccentGreen"))
        }
    }
}

struct StatBarRow: View {
    @Bindable var character: PlayerCharacter
    let statType: StatType
    let value: Int
    let effectiveValue: Int
    let canAllocate: Bool
    
    @State private var justAllocated: Bool = false
    @State private var showBreakdown: Bool = false
    
    var bonusValue: Int {
        effectiveValue - value
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
                
                // Disclosure chevron to hint tappability
                Image(systemName: showBreakdown ? "chevron.up" : "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.6))
                
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
            
            // Expandable source breakdown
            if showBreakdown {
                StatSourceBreakdown(breakdown: character.statBreakdown(for: statType))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Description
            Text(statType.description)
                .font(.custom("Avenir-Medium", size: 11))
                .foregroundColor(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.25)) {
                showBreakdown.toggle()
            }
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

// MARK: - Stat Source Breakdown

struct StatSourceBreakdown: View {
    let breakdown: StatBreakdown
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            breakdownRow(label: "Base", value: breakdown.base, isBase: true)
            
            if breakdown.weaponBonus > 0, let name = breakdown.weaponName {
                breakdownRow(label: "Weapon (\(name))", value: breakdown.weaponBonus)
            }
            if breakdown.armorBonus > 0, let name = breakdown.armorName {
                breakdownRow(label: "Armor (\(name))", value: breakdown.armorBonus)
            }
            if breakdown.accessoryBonus > 0, let name = breakdown.accessoryName {
                breakdownRow(label: "Accessory (\(name))", value: breakdown.accessoryBonus)
            }
            if breakdown.trinketBonus > 0, let name = breakdown.trinketName {
                breakdownRow(label: "Trinket (\(name))", value: breakdown.trinketBonus)
            }
            if breakdown.classBonus > 0, let name = breakdown.className {
                breakdownRow(label: "Class (\(name))", value: breakdown.classBonus)
            }
            if breakdown.zodiacBonus > 0, let name = breakdown.zodiacName {
                breakdownRow(label: "Zodiac (\(name))", value: breakdown.zodiacBonus)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.secondary.opacity(0.08))
        )
    }
    
    @ViewBuilder
    private func breakdownRow(label: String, value: Int, isBase: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.custom("Avenir-Medium", size: 12))
                .foregroundColor(.secondary)
                .lineLimit(1)
            Spacer()
            Text(isBase ? "\(value)" : "+\(value)")
                .font(.custom("Avenir-Heavy", size: 13))
                .foregroundColor(isBase ? .primary : Color("AccentGreen"))
        }
    }
}

// MARK: - Equipment Tab

struct EquipmentTabContent: View {
    let character: PlayerCharacter
    @Environment(\.modelContext) private var modelContext
    @Query private var allEquipment: [Equipment]
    
    @State private var selectedSlot: EquipmentSlot?
    @State private var showSlotPicker = false
    @State private var equipFeedback = 0
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(EquipmentSlot.allCases, id: \.self) { slot in
                EquipmentSlotRow(
                    slot: slot,
                    equipment: character.equipment.item(for: slot),
                    onTap: {
                        selectedSlot = slot
                        showSlotPicker = true
                    }
                )
            }
            
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
        .sheet(isPresented: $showSlotPicker) {
            if let slot = selectedSlot {
                EquipmentSlotPickerView(
                    slot: slot,
                    character: character,
                    allEquipment: allEquipment,
                    onEquip: { item in equipItem(item) },
                    onUnequip: { item in unequipItem(item) }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .sensoryFeedback(.success, trigger: equipFeedback)
    }
    
    private func equipItem(_ item: Equipment) {
        // Unequip current item in that slot
        if let current = character.equipment.item(for: item.slot) {
            current.isEquipped = false
            Task { try? await SupabaseService.shared.syncEquipment(current) }
        }
        character.equipment.setItem(item, for: item.slot)
        item.isEquipped = true
        Task { try? await SupabaseService.shared.syncEquipment(item) }
        equipFeedback += 1
        AudioManager.shared.play(.equipItem)
        showSlotPicker = false
    }
    
    private func unequipItem(_ item: Equipment) {
        if character.equipment.item(for: item.slot)?.id == item.id {
            character.equipment.setItem(nil, for: item.slot)
        }
        item.isEquipped = false
        Task { try? await SupabaseService.shared.syncEquipment(item) }
        equipFeedback += 1
    }
}

struct EquipmentSlotRow: View {
    let slot: EquipmentSlot
    let equipment: Equipment?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Slot icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(equipment != nil ?
                              Color(equipment!.rarity.color).opacity(0.15) :
                              Color("AccentGold").opacity(0.08))
                        .frame(width: 56, height: 56)
                    
                    if equipment == nil {
                        // Dashed border hint for empty slots
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color("AccentGold").opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                            .frame(width: 56, height: 56)
                    }
                    
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
                        // Show affixes
                        if let affixText = equipment.affixSummary {
                            Text(affixText)
                                .font(.custom("Avenir-Medium", size: 11))
                                .foregroundColor(Color("AccentPurple"))
                        }
                    } else {
                        Text("Tap to equip")
                            .font(.custom("Avenir-Medium", size: 15))
                            .foregroundColor(Color("AccentGold").opacity(0.6))
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
                        .rarityShimmer(equipment.rarity)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.5))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Equipment Slot Picker

struct EquipmentSlotPickerView: View {
    let slot: EquipmentSlot
    let character: PlayerCharacter
    let allEquipment: [Equipment]
    let onEquip: (Equipment) -> Void
    let onUnequip: (Equipment) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    /// Currently equipped item in this slot
    private var equippedItem: Equipment? {
        character.equipment.item(for: slot)
    }
    
    /// All unequipped items the player owns for this slot, sorted by rarity (best first)
    private var availableItems: [Equipment] {
        allEquipment
            .filter { $0.ownerID == character.id && !$0.isEquipped && $0.slot == slot }
            .sorted { rarityOrder($0.rarity) > rarityOrder($1.rarity) }
    }
    
    /// Whether the player meets the level requirement for an item
    private func canEquip(_ item: Equipment) -> Bool {
        character.level >= item.levelRequirement
    }
    
    /// Stat delta between a candidate item and the currently equipped item
    private func statDelta(for item: Equipment, stat: StatType) -> Int {
        let newBonus = bonusFor(item: item, stat: stat)
        let oldBonus = bonusFor(item: equippedItem, stat: stat)
        return newBonus - oldBonus
    }
    
    private func bonusFor(item: Equipment?, stat: StatType) -> Int {
        guard let item = item else { return 0 }
        var total = 0
        if item.primaryStat == stat { total += item.statBonus }
        if item.secondaryStat == stat { total += item.secondaryStatBonus }
        return total
    }
    
    /// Key stat deltas for display (only non-zero ones)
    private func keyDeltas(for item: Equipment) -> [(stat: StatType, delta: Int)] {
        StatType.allCases.compactMap { stat in
            let d = statDelta(for: item, stat: stat)
            guard d != 0 else { return nil }
            return (stat, d)
        }
    }
    
    private func rarityOrder(_ rarity: ItemRarity) -> Int {
        switch rarity {
        case .common: return 0
        case .uncommon: return 1
        case .rare: return 2
        case .epic: return 3
        case .legendary: return 4
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundTop").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Slot Header
                        slotHeader
                        
                        // Currently Equipped
                        if let equipped = equippedItem {
                            equippedSection(equipped)
                        }
                        
                        // Available Items
                        availableItemsSection
                    }
                    .padding()
                }
            }
            .navigationTitle(slot.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color("AccentGold"))
                }
            }
        }
    }
    
    // MARK: - Slot Header
    
    private var slotHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color("AccentGold").opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: slot.icon)
                    .font(.system(size: 22))
                    .foregroundColor(Color("AccentGold"))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(slot.rawValue) Slot")
                    .font(.custom("Avenir-Heavy", size: 18))
                Text("\(availableItems.count) item\(availableItems.count == 1 ? "" : "s") available")
                    .font(.custom("Avenir-Medium", size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Equipped Section
    
    @ViewBuilder
    private func equippedSection(_ equipped: Equipment) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CURRENTLY EQUIPPED")
                .font(.custom("Avenir-Heavy", size: 11))
                .foregroundColor(.secondary)
                .tracking(1)
            
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(equipped.rarity.color).opacity(0.15))
                        .frame(width: 52, height: 52)
                    EquipmentIconView(item: equipped, slot: slot, size: 52)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(equipped.name)
                        .font(.custom("Avenir-Heavy", size: 15))
                        .foregroundColor(Color(equipped.rarity.color))
                    Text(equipped.statSummary)
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(Color("AccentGreen"))
                    if let affix = equipped.affixSummary {
                        Text(affix)
                            .font(.custom("Avenir-Medium", size: 11))
                            .foregroundColor(Color("AccentPurple"))
                    }
                }
                
                Spacer()
                
                Button(action: { onUnequip(equipped) }) {
                    Text("Unequip")
                        .font(.custom("Avenir-Heavy", size: 12))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.secondary.opacity(0.15))
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color("CardBackground"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(equipped.rarity.color).opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Available Items
    
    private var availableItemsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AVAILABLE GEAR")
                .font(.custom("Avenir-Heavy", size: 11))
                .foregroundColor(.secondary)
                .tracking(1)
            
            if availableItems.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No items for this slot")
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.secondary)
                    Text("Complete dungeons and quests to earn loot!")
                        .font(.custom("Avenir-Medium", size: 13))
                        .foregroundColor(.secondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                ForEach(availableItems, id: \.id) { item in
                    availableItemRow(item)
                }
            }
        }
    }
    
    @ViewBuilder
    private func availableItemRow(_ item: Equipment) -> some View {
        let meetsLevel = canEquip(item)
        let deltas = keyDeltas(for: item)
        
        Button(action: {
            if meetsLevel {
                onEquip(item)
            }
        }) {
            HStack(spacing: 14) {
                // Item icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(item.rarity.color).opacity(meetsLevel ? 0.15 : 0.05))
                        .frame(width: 48, height: 48)
                    EquipmentIconView(item: item, slot: slot, size: 48)
                        .opacity(meetsLevel ? 1 : 0.4)
                }
                
                // Item info + inline delta
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name)
                        .font(.custom("Avenir-Heavy", size: 14))
                        .foregroundColor(meetsLevel ? Color(item.rarity.color) : .secondary)
                    
                    Text(item.statSummary)
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(meetsLevel ? .secondary : .secondary.opacity(0.5))
                    
                    if let affix = item.affixSummary {
                        Text(affix)
                            .font(.custom("Avenir-Medium", size: 11))
                            .foregroundColor(meetsLevel ? Color("AccentPurple") : .secondary.opacity(0.4))
                    }
                    
                    if !meetsLevel {
                        Text("Requires Lv.\(item.levelRequirement)")
                            .font(.custom("Avenir-Heavy", size: 11))
                            .foregroundColor(.red.opacity(0.7))
                    }
                }
                
                Spacer()
                
                // Stat delta indicators
                if meetsLevel && !deltas.isEmpty {
                    VStack(alignment: .trailing, spacing: 2) {
                        ForEach(deltas.prefix(3), id: \.stat) { entry in
                            HStack(spacing: 3) {
                                Image(systemName: entry.delta > 0 ? "arrow.up" : "arrow.down")
                                    .font(.system(size: 8, weight: .bold))
                                Text("\(abs(entry.delta)) \(entry.stat.shortName)")
                                    .font(.custom("Avenir-Heavy", size: 11))
                            }
                            .foregroundColor(entry.delta > 0 ? Color("AccentGreen") : .red)
                        }
                    }
                }
                
                // Rarity badge
                Text(item.rarity.rawValue.prefix(1))
                    .font(.custom("Avenir-Heavy", size: 10))
                    .foregroundColor(Color(item.rarity.color))
                    .frame(width: 22, height: 22)
                    .background(
                        Circle().fill(Color(item.rarity.color).opacity(0.15))
                    )
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color("CardBackground"))
            )
            .opacity(meetsLevel ? 1 : 0.6)
        }
        .buttonStyle(.plain)
        .disabled(!meetsLevel)
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

