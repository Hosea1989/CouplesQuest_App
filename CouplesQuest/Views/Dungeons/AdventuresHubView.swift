import SwiftUI
import SwiftData

// MARK: - Adventure Category

enum AdventureCategory: String, CaseIterable {
    case training = "Training"
    case dungeons = "Dungeons"
    case arena = "Arena"
    case raidBoss = "Raid Boss"
    
    var icon: String {
        switch self {
        case .training: return "figure.strengthtraining.traditional"
        case .dungeons: return "shield.lefthalf.filled"
        case .arena: return "trophy.fill"
        case .raidBoss: return "flame.circle.fill"
        }
    }
    
    var levelRequirement: Int {
        switch self {
        case .training: return 1    // Always available — first activity
        case .dungeons: return 3    // Unlocks early
        case .arena: return 6       // Mid progression
        case .raidBoss: return 10   // Endgame content
        }
    }
    
    var unlockDescription: String {
        switch self {
        case .training: return "Send your character on AFK training missions to earn EXP and rewards."
        case .dungeons: return "Run dungeons that auto-resolve based on your stats and class."
        case .arena: return "Test your strength in endless arena waves for glory and loot."
        case .raidBoss: return "Take on powerful weekly raid bosses for epic rewards."
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
                        // Category Picker
                        categoryPicker(character: character)
                        
                        // Content — each tab checks its level requirement
                        switch selectedCategory {
                        case .training:
                            if character.level >= AdventureCategory.training.levelRequirement {
                                MissionsView()
                            } else {
                                lockedView(category: .training)
                            }
                        case .dungeons:
                            if character.level >= AdventureCategory.dungeons.levelRequirement {
                                DungeonListView()
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
                            Text(category.rawValue)
                                .font(.custom("Avenir-Heavy", size: 13))
                        }
                        .foregroundColor(
                            selectedCategory == category ? .black :
                            isLocked ? .secondary.opacity(0.5) : .secondary
                        )
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule().fill(
                                selectedCategory == category ?
                                Color("AccentGold") :
                                Color("CardBackground")
                            )
                        )
                    }
                    .disabled(isLocked)
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
