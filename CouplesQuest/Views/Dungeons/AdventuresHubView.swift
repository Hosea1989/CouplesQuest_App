import SwiftUI
import SwiftData

// MARK: - Adventure Category

enum AdventureCategory: String, CaseIterable {
    case training = "Training"
    case dungeons = "Dungeons"
    case arena = "Arena"
    case raidBoss = "Raid Boss"
    case expeditions = "Expeditions"
    
    var icon: String {
        switch self {
        case .training: return "figure.strengthtraining.traditional"
        case .dungeons: return "shield.lefthalf.filled"
        case .arena: return "trophy.fill"
        case .raidBoss: return "flame.circle.fill"
        case .expeditions: return "compass.drawing"
        }
    }
    
    var levelRequirement: Int {
        switch self {
        case .training: return 1    // Always available — first activity
        case .dungeons: return 1    // Available from the start (individual dungeons have their own level gates)
        case .arena: return 6       // Mid progression
        case .raidBoss: return 10   // Endgame content
        case .expeditions: return 15 // Long-duration content for experienced players
        }
    }
    
    var unlockDescription: String {
        switch self {
        case .training: return "Train your class skills to boost stats and earn EXP."
        case .dungeons: return "Run dungeons that auto-resolve based on your stats and class."
        case .arena: return "Test your strength in endless arena waves for glory and loot."
        case .raidBoss: return "Take on powerful weekly raid bosses for epic rewards."
        case .expeditions: return "Embark on long expeditions with multiple stages, narrative logs, and exclusive loot."
        }
    }
}

// MARK: - Adventures Hub View

struct AdventuresHubView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var gameEngine: GameEngine
    @Query private var characters: [PlayerCharacter]
    
    @State private var selectedCategory: AdventureCategory = .training
    @State private var showCharacterCreation = false
    @State private var questGiverDismissed = false
    
    private var character: PlayerCharacter? {
        characters.first
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
                
                if let character = character {
                    VStack(spacing: 0) {
                        // Quest Giver NPC
                        questGiverNPC(character: character)
                        
                        // Category Picker
                        categoryPicker(character: character)
                        
                        // Content — each tab checks its level requirement
                        switch selectedCategory {
                        case .training:
                            if character.level >= AdventureCategory.training.levelRequirement {
                                MissionsView(isEmbedded: true)
                            } else {
                                lockedView(category: .training)
                            }
                        case .dungeons:
                            if character.level >= AdventureCategory.dungeons.levelRequirement {
                                DungeonListView(isEmbedded: true)
                            } else {
                                lockedView(category: .dungeons)
                            }
                        case .arena:
                            if character.level >= AdventureCategory.arena.levelRequirement {
                                ArenaView()
                            } else {
                                lockedView(category: .arena)
                            }
                        case .raidBoss:
                            if character.level >= AdventureCategory.raidBoss.levelRequirement {
                                RaidBossView()
                            } else {
                                lockedView(category: .raidBoss)
                            }
                        case .expeditions:
                            if character.level >= AdventureCategory.expeditions.levelRequirement {
                                ExpeditionView()
                            } else {
                                lockedView(category: .expeditions)
                            }
                        }
                    }
                } else {
                    noCharacterView
                }
            }
            .navigationTitle("Adventures")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showCharacterCreation) {
                CharacterCreationView()
            }
        }
    }
    
    // MARK: - Quest Giver NPC
    
    @ViewBuilder
    private func questGiverNPC(character: PlayerCharacter) -> some View {
        if !questGiverDismissed {
            let dialogue = questGiverDialogue(for: character, category: selectedCategory)
            
            HStack(spacing: 12) {
                // NPC portrait
                Image("quest_giver")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color("AccentGold").opacity(0.4), lineWidth: 2))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Quest Giver")
                        .font(.custom("Avenir-Heavy", size: 12))
                        .foregroundColor(Color("AccentGold"))
                    Text(dialogue)
                        .font(.custom("Avenir-Medium", size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        questGiverDismissed = true
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary.opacity(0.5))
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("CardBackground"))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
            .padding(.horizontal)
            .padding(.top, 4)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
    
    /// Generate contextual Quest Giver dialogue based on character state and active tab
    private func questGiverDialogue(for character: PlayerCharacter, category: AdventureCategory) -> String {
        let level = character.level
        
        // Tab-specific dialogue takes priority when the category is unlocked
        if level >= category.levelRequirement {
            switch category {
            case .training:
                let lines = [
                    "Training sharpens the blade and the mind. Practice your class skills.",
                    "Even legends started with simple drills. Choose your training, adventurer.",
                    "Stat growth comes to those who train. Pick a session and get stronger.",
                    "Consistent training is the quiet path to power. Don't underestimate it.",
                ]
                return lines[level % lines.count]
                
            case .dungeons:
                if level < 15 {
                    return "I've heard rumors of a sunken temple beneath the eastern lake..."
                } else if level < 30 {
                    return "Spirits walk the halls of the Phantom Citadel. Steel your resolve."
                } else if level < 60 {
                    return "Crystal caverns hum with ancient power. Great rewards await within."
                } else {
                    let lines = [
                        "Deeper dungeons hold greater treasures. Choose wisely.",
                        "The Necropolis stirs. Shadows grow deeper with each passing day.",
                        "I've mapped new chambers in the ancient ruins. Ready?",
                    ]
                    return lines[level % lines.count]
                }
                
            case .arena:
                let lines = [
                    "The arena has no ceiling. How high can you climb?",
                    "Each wave is harder than the last. But so are the rewards.",
                    "Champions are forged in the arena, not born. Step in.",
                    "Your arena record speaks for itself. Push it further.",
                ]
                return lines[level % lines.count]
                
            case .raidBoss:
                let lines = [
                    "The raid boss stirs... gather your strength and strike together.",
                    "Only the combined might of a party can topple this beast.",
                    "Every hit counts against the raid boss. Don't hold back.",
                    "Legendary rewards await those brave enough to challenge the boss.",
                ]
                return lines[level % lines.count]
                
            case .expeditions:
                let lines = [
                    "Expeditions are long journeys. Pack wisely and expect the unexpected.",
                    "I've mapped a route through the ancient ruins. Ready for an expedition?",
                    "The farther you travel, the richer the discoveries. Embark now.",
                    "Expedition keys are burning a hole in your pack. Use them wisely.",
                ]
                return lines[level % lines.count]
            }
        }
        
        // Fallback: level-based general dialogue for locked content
        if level < 6 {
            return "Keep training, adventurer. The arena awaits those who prove themselves."
        } else if level < 10 {
            return "You're growing stronger. The arena is open — test your mettle!"
        } else if level < 15 {
            return "New horizons are opening up. Keep pushing your limits."
        } else {
            return "Greater challenges await you. Keep leveling to unlock them all."
        }
    }
    
    // MARK: - Category Picker
    
    @ViewBuilder
    private func categoryPicker(character: PlayerCharacter) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AdventureCategory.allCases, id: \.self) { category in
                    let isLocked = character.level < category.levelRequirement
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = category
                        }
                        AudioManager.shared.play(.tabSwitch)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: isLocked ? "lock.fill" : category.icon)
                                .font(.system(size: 12))
                            Text(isLocked ? "\(category.rawValue) (Lv.\(category.levelRequirement))" : category.rawValue)
                                .font(.custom("Avenir-Heavy", size: 13))
                        }
                        .foregroundColor(
                            selectedCategory == category
                                ? (isLocked ? .white : .black)
                                : (isLocked ? .secondary.opacity(0.5) : .secondary)
                        )
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule().fill(
                                selectedCategory == category
                                    ? (isLocked ? Color.secondary.opacity(0.3) : Color("AccentGold"))
                                    : Color("CardBackground")
                            )
                        )
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Locked View
    
    @ViewBuilder
    private func lockedView(category: AdventureCategory) -> some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 120, height: 120)
                VStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Image(systemName: category.icon)
                        .font(.system(size: 18))
                        .foregroundColor(.secondary.opacity(0.5))
                }
            }
            
            Text("\(category.rawValue) Locked")
                .font(.custom("Avenir-Heavy", size: 24))
            
            Text("Reach Level \(category.levelRequirement) to unlock.")
                .font(.custom("Avenir-Heavy", size: 16))
                .foregroundColor(Color("AccentGold"))
            
            Text(category.unlockDescription)
                .font(.custom("Avenir-Medium", size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            if let character = character {
                // Progress toward unlock
                let progress = min(1.0, Double(character.level) / Double(category.levelRequirement))
                VStack(spacing: 8) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.secondary.opacity(0.15))
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color("AccentGold"))
                                .frame(width: geometry.size.width * progress)
                        }
                    }
                    .frame(height: 10)
                    .padding(.horizontal, 60)
                    
                    Text("Level \(character.level) / \(category.levelRequirement)")
                        .font(.custom("Avenir-Medium", size: 13))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
            
            Spacer()
        }
    }
    
    // MARK: - No Character View
    
    private var noCharacterView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color("AccentGold").opacity(0.15))
                    .frame(width: 120, height: 120)
                Image(systemName: "map.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color("AccentGold"))
            }
            
            Text("Adventures Await")
                .font(.custom("Avenir-Heavy", size: 28))
            
            Text("Create a character to begin your journey through dungeons, arenas, and more.")
                .font(.custom("Avenir-Medium", size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                showCharacterCreation = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Character")
                }
                .font(.custom("Avenir-Heavy", size: 18))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color("AccentGold"), Color("AccentOrange")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

#Preview {
    AdventuresHubView()
        .environmentObject(GameEngine())
}
