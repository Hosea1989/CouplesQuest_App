import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject var gameEngine: GameEngine
    @Query private var characters: [PlayerCharacter]
    @State private var selectedTab: Tab = .home
    
    private var character: PlayerCharacter? {
        characters.first
    }
    
    enum Tab: String, CaseIterable {
        case home = "Home"
        case tasks = "Tasks"
        case adventures = "Adventures"
        case character = "Character"
        case partner = "Partner"
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .tasks: return "checklist"
            case .adventures: return "map.fill"
            case .character: return "person.fill"
            case .partner: return "heart.fill"
            }
        }
        
        /// Fallback icon for symbols that may not exist
        var safeIcon: String {
            return icon
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label(Tab.home.rawValue, systemImage: Tab.home.icon)
                }
                .tag(Tab.home)
            
            TasksView()
                .tabItem {
                    Label(Tab.tasks.rawValue, systemImage: Tab.tasks.icon)
                }
                .tag(Tab.tasks)
            
            AdventuresHubView()
                .tabItem {
                    Label(Tab.adventures.rawValue, systemImage: Tab.adventures.icon)
                }
                .tag(Tab.adventures)
            
            CharacterView()
                .tabItem {
                    Label(Tab.character.rawValue, systemImage: Tab.character.icon)
                }
                .tag(Tab.character)
            
            PartnerView()
                .tabItem {
                    Label(Tab.partner.rawValue, systemImage: Tab.partner.icon)
                }
                .tag(Tab.partner)
        }
        .tint(Color("AccentGold"))
        .sensoryFeedback(.selection, trigger: selectedTab)
        .onChange(of: selectedTab) { _, _ in
            AudioManager.shared.play(.tabSwitch)
        }
        .overlay {
            if gameEngine.showLevelUpCelebration,
               let character = character {
                LevelUpCelebrationView(
                    character: character,
                    rewards: gameEngine.pendingLevelUpRewards,
                    onDismiss: {
                        gameEngine.showLevelUpCelebration = false
                        gameEngine.pendingLevelUpRewards = []
                        // Navigate to character tab if stat points pending
                        if character.unspentStatPoints > 0 {
                            selectedTab = .character
                        }
                    }
                )
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: gameEngine.showLevelUpCelebration)
    }
}

#Preview {
    ContentView()
        .environmentObject(GameEngine())
}
