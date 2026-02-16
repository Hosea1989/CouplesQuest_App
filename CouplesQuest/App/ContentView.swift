import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject var gameEngine: GameEngine
    @Query private var characters: [PlayerCharacter]
    @State private var selectedTab: Tab = .home
    
    /// Observes deep link navigation requests from notification taps
    @ObservedObject private var deepLinkRouter = DeepLinkRouter.shared
    
    // MARK: - Onboarding & Retention State
    @State private var showOnboarding = false
    @State private var showWelcomeBack = false
    @State private var showDailyLoginReward = false
    @State private var retentionChecked = false
    
    private var character: PlayerCharacter? {
        characters.first
    }
    
    enum Tab: String, CaseIterable {
        case home = "Home"
        case tasks = "Daily Tasks"
        case adventures = "Adventures"
        case character = "Character"
        case partner = "Party"
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .tasks: return "checklist"
            case .adventures: return "map.fill"
            case .character: return "person.fill"
            case .partner: return "person.2.fill"
            }
        }
        
        /// Fallback icon for symbols that may not exist
        var safeIcon: String {
            return icon
        }
    }
    
    var body: some View {
        ZStack {
            // Main app TabView
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
                
                PartnerView()
                    .tabItem {
                        Label(Tab.partner.rawValue, systemImage: Tab.partner.icon)
                    }
                    .tag(Tab.partner)
                
                CharacterView()
                    .tabItem {
                        Label(Tab.character.rawValue, systemImage: Tab.character.icon)
                    }
                    .tag(Tab.character)
            }
            .tint(Color("AccentGold"))
            .modifier(TabBarOnlyStyleModifier())
            .sensoryFeedback(.selection, trigger: selectedTab)
            .onChange(of: selectedTab) { _, _ in
                AudioManager.shared.play(.tabSwitch)
            }
            .overlay {
                ToastOverlayView()
                    .zIndex(200)
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
                
                if gameEngine.showAchievementCelebration,
                   let achievement = gameEngine.unlockedAchievement {
                    RewardCelebrationOverlay(
                        icon: "trophy.fill",
                        iconColor: Color("AccentGold"),
                        title: "Achievement Unlocked!",
                        subtitle: achievement.name,
                        rewards: achievementRewards(for: achievement),
                        onDismiss: {
                            withAnimation {
                                gameEngine.showAchievementCelebration = false
                                gameEngine.unlockedAchievement = nil
                            }
                        }
                    )
                    .transition(.opacity)
                    .zIndex(99)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: gameEngine.showLevelUpCelebration)
            .animation(.easeInOut(duration: 0.3), value: gameEngine.showAchievementCelebration)
            
            // MARK: - Onboarding Overlay (fullscreen, blocks main app)
            if showOnboarding, let character = character {
                OnboardingView(
                    character: character,
                    onComplete: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showOnboarding = false
                        }
                        // After onboarding, check if daily login should show
                        checkDailyLoginReward()
                    }
                )
                .transition(.opacity)
                .zIndex(300)
            }
            
            // MARK: - Welcome Back Overlay
            if showWelcomeBack, let character = character {
                WelcomeBackView(
                    character: character,
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showWelcomeBack = false
                        }
                        // After welcome back, check daily login
                        checkDailyLoginReward()
                    }
                )
                .transition(.opacity)
                .zIndex(250)
            }
            
            // MARK: - Daily Login Reward Overlay
            if showDailyLoginReward, let character = character {
                DailyLoginRewardView(
                    character: character,
                    onClaim: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showDailyLoginReward = false
                        }
                    }
                )
                .transition(.opacity)
                .zIndex(240)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showOnboarding)
        .animation(.easeInOut(duration: 0.3), value: showWelcomeBack)
        .animation(.easeInOut(duration: 0.3), value: showDailyLoginReward)
        .onAppear {
            // Validate the persisted training mission belongs to the current
            // character. After a database reset the old character's mission
            // would otherwise keep running forever.
            if let character = character {
                gameEngine.validateActiveMission(for: character.id)
                // Apply passive HP regen based on time since last update
                character.applyPassiveRegen()
            } else if gameEngine.activeMission != nil {
                // No character at all — clear the orphaned mission
                gameEngine.activeMission = nil
                ActiveMission.clearPersisted()
            }
            
            // Run retention checks once on appear
            if !retentionChecked {
                retentionChecked = true
                checkRetentionFlows()
            }
        }
        .onChange(of: character?.id) { _, newID in
            if let newID {
                gameEngine.validateActiveMission(for: newID)
            } else if gameEngine.activeMission != nil {
                gameEngine.activeMission = nil
                ActiveMission.clearPersisted()
            }
        }
        // MARK: - Deep Link Navigation
        .onChange(of: deepLinkRouter.pendingDestination) { _, destination in
            guard let destination else { return }
            handleDeepLink(destination)
        }
    }
    
    /// Navigate to the correct tab (and sub-screen) based on a notification deep link.
    private func handleDeepLink(_ destination: DeepLinkDestination) {
        switch destination {
        case .characterLevelUp:
            selectedTab = .character
            // Clear after tab switch; character tab handles the rest
            deepLinkRouter.pendingDestination = nil
        case .dungeons, .training, .expeditions:
            // Switch to adventures tab; AdventuresHubView observes the router
            // and clears the destination after switching its sub-category
            selectedTab = .adventures
        case .home:
            selectedTab = .home
            deepLinkRouter.pendingDestination = nil
        case .tasks:
            selectedTab = .tasks
            deepLinkRouter.pendingDestination = nil
        case .party:
            selectedTab = .partner
            deepLinkRouter.pendingDestination = nil
        }
    }
    
    // MARK: - Retention Flow Logic
    
    /// Check and trigger the appropriate retention flow in priority order:
    /// 1. Onboarding (if not completed)
    /// 2. Welcome Back (if 3+ days absent)
    /// 3. Daily Login Reward (if not claimed today)
    private func checkRetentionFlows() {
        guard let character = character else { return }
        
        // Priority 1: Onboarding for new users
        if !character.hasCompletedOnboarding {
            // Slight delay for the main UI to settle
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    showOnboarding = true
                }
            }
            return
        }
        
        // Priority 2: Welcome back for lapsed users (3+ days absent)
        if character.shouldShowWelcomeBack {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    showWelcomeBack = true
                }
            }
            return
        }
        
        // Priority 3: Daily login reward
        checkDailyLoginReward()
        
        // Check if the streak should be broken (missed daily reward claim for 2+ days)
        gameEngine.updateStreak(for: character, completedTaskToday: false)
        
        // Reset comeback tracking for active users (they're here, so they're active)
        if character.daysSinceLastActive <= 1 && character.comebackGiftClaimed {
            character.resetComebackTracking()
        }
    }
    
    /// Show the daily login reward if not claimed today
    private func checkDailyLoginReward() {
        guard let character = character else { return }
        
        if character.canClaimDailyLoginReward {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    showDailyLoginReward = true
                }
            }
        }
    }
    
    // MARK: - Achievement Rewards
    
    /// Build reward display rows for an unlocked achievement.
    private func achievementRewards(for achievement: Achievement) -> [(icon: String, label: String, value: String, color: Color)] {
        var rewards: [(icon: String, label: String, value: String, color: Color)] = []
        
        switch achievement.rewardType {
        case .exp:
            rewards.append((icon: "sparkles", label: "EXP", value: "+\(achievement.rewardAmount)", color: Color("AccentGold")))
        case .gold:
            rewards.append((icon: "dollarsign.circle.fill", label: "Gold", value: "+\(achievement.rewardAmount)", color: Color("AccentGold")))
        case .gems:
            rewards.append((icon: "diamond.fill", label: "Gems", value: "+\(achievement.rewardAmount)", color: Color("AccentPurple")))
        case .title:
            rewards.append((icon: "textformat", label: "New Title", value: "Unlocked", color: Color("AccentGreen")))
        case .equipment:
            rewards.append((icon: "shield.fill", label: "Equipment", value: "Unlocked", color: Color("AccentOrange")))
        }
        
        return rewards
    }
}

// MARK: - Disable Tab Swiping (iOS 18+)

/// iOS 18 introduced swipe-to-switch on the default TabView style.
/// This modifier applies `.tabBarOnly` on iOS 18+ to prevent accidental
/// horizontal swiping between tabs, which causes the content to shift.
private struct TabBarOnlyStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.tabViewStyle(.tabBarOnly)
        } else {
            content
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(GameEngine())
}
