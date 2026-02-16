import SwiftUI
import SwiftData

/// Post-character-creation onboarding flow.
/// Guides new users through: First Task → Reward Demo → Quick Tour → Starter Gift → Habit Setup.
/// Total time: under 2 minutes.
struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var gameEngine: GameEngine
    let character: PlayerCharacter
    let onComplete: () -> Void
    
    @State private var currentStep: OnboardingStep = .firstTask
    @State private var selectedTaskTitle: String? = nil
    @State private var customTaskTitle: String = ""
    @State private var showRewardAnimation = false
    @State private var earnedEXP: Int = 25
    @State private var earnedGold: Int = 10
    @State private var tooltipIndex: Int = 0
    @State private var showStarterGift = false
    @State private var selectedHabits: Set<String> = []
    @State private var animateReward = false
    
    enum OnboardingStep: Int, CaseIterable {
        case firstTask = 0
        case completeTask = 1
        case quickTour = 2
        case starterGift = 3
        case habitSetup = 4
    }
    
    // MARK: - Pre-filled task suggestions
    
    private let taskSuggestions: [(title: String, category: TaskCategory, icon: String)] = [
        ("Go for a walk", .physical, "figure.walk"),
        ("Read for 15 minutes", .mental, "book.fill"),
        ("Text a friend", .social, "message.fill"),
        ("Clean your desk", .household, "sparkles"),
        ("Take 5 deep breaths", .wellness, "wind"),
        ("Draw or write something", .creative, "paintbrush.fill")
    ]
    
    // MARK: - Habit suggestions for setup
    
    private let habitSuggestions: [(title: String, category: TaskCategory, icon: String, group: String)] = [
        ("Morning stretch", .physical, "figure.flexibility", "Morning Routine"),
        ("Drink a glass of water", .wellness, "drop.fill", "Morning Routine"),
        ("Make your bed", .household, "bed.double.fill", "Morning Routine"),
        ("Exercise for 20 min", .physical, "figure.run", "Exercise"),
        ("Go for a walk", .physical, "figure.walk", "Exercise"),
        ("Read for 15 min", .mental, "book.fill", "Learning"),
        ("Journal for 5 min", .creative, "pencil.and.scribble", "Learning"),
        ("Meditate", .wellness, "brain.head.profile", "Wellness"),
        ("Log your mood", .wellness, "face.smiling", "Wellness"),
        ("Text a friend", .social, "message.fill", "Social"),
    ]
    
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
                // Progress indicator
                OnboardingProgressBar(currentStep: currentStep.rawValue, totalSteps: OnboardingStep.allCases.count)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                
                // Step content
                switch currentStep {
                case .firstTask:
                    firstTaskStep
                case .completeTask:
                    completeTaskStep
                case .quickTour:
                    quickTourStep
                case .starterGift:
                    starterGiftStep
                case .habitSetup:
                    habitSetupStep
                }
            }
        }
    }
    
    // MARK: - Step 1: First Task
    
    private var firstTaskStep: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "sparkle")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color("AccentGold"), Color("AccentOrange")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Every hero starts somewhere.")
                .font(.custom("Avenir-Heavy", size: 24))
                .multilineTextAlignment(.center)
            
            Text("What's one thing you want to do today?")
                .font(.custom("Avenir-Medium", size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Task suggestions grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(taskSuggestions, id: \.title) { suggestion in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedTaskTitle = suggestion.title
                            customTaskTitle = ""
                        }
                        AudioManager.shared.play(.buttonTap)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: suggestion.icon)
                                .font(.system(size: 14))
                                .foregroundColor(Color(suggestion.category.color))
                            Text(suggestion.title)
                                .font(.custom("Avenir-Medium", size: 13))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedTaskTitle == suggestion.title
                                      ? Color("AccentGold").opacity(0.2)
                                      : Color("CardBackground"))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedTaskTitle == suggestion.title
                                        ? Color("AccentGold")
                                        : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            
            // Custom task input
            HStack(spacing: 12) {
                Image(systemName: "pencil")
                    .foregroundColor(.secondary)
                TextField("Or type your own...", text: $customTaskTitle)
                    .font(.custom("Avenir-Medium", size: 15))
                    .onChange(of: customTaskTitle) { _, newValue in
                        if !newValue.isEmpty {
                            selectedTaskTitle = nil
                        }
                    }
            }
            .padding(14)
            .background(Color("CardBackground"))
            .cornerRadius(12)
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Continue button
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep = .completeTask
                }
                AudioManager.shared.play(.buttonTap)
            } label: {
                Text("Continue")
                    .font(.custom("Avenir-Heavy", size: 16))
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
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(selectedTaskTitle == nil && customTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity((selectedTaskTitle != nil || !customTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? 1.0 : 0.5)
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
    
    // MARK: - Step 2: Complete Task (Reward Demo)
    
    private var completeTaskStep: some View {
        VStack(spacing: 24) {
            Spacer()
            
            if showRewardAnimation {
                // Reward celebration
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(Color("AccentGreen"))
                        .scaleEffect(animateReward ? 1.0 : 0.3)
                        .opacity(animateReward ? 1.0 : 0.0)
                    
                    Text("Quest Complete!")
                        .font(.custom("Avenir-Heavy", size: 28))
                        .opacity(animateReward ? 1.0 : 0.0)
                    
                    // Reward counters
                    HStack(spacing: 32) {
                        VStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 24))
                                .foregroundColor(Color("AccentGold"))
                            Text("+\(earnedEXP) EXP")
                                .font(.custom("Avenir-Heavy", size: 18))
                                .foregroundColor(Color("AccentGold"))
                        }
                        .scaleEffect(animateReward ? 1.0 : 0.5)
                        
                        VStack(spacing: 4) {
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Color("AccentGold"))
                            Text("+\(earnedGold) Gold")
                                .font(.custom("Avenir-Heavy", size: 18))
                                .foregroundColor(Color("AccentGold"))
                        }
                        .scaleEffect(animateReward ? 1.0 : 0.5)
                    }
                    .opacity(animateReward ? 1.0 : 0.0)
                    
                    Text("Every task you complete makes your character stronger.")
                        .font(.custom("Avenir-Medium", size: 15))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .opacity(animateReward ? 1.0 : 0.0)
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animateReward)
            } else {
                // Pre-completion state
                VStack(spacing: 16) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color("AccentGold"), Color("AccentOrange")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Complete your first quest!")
                        .font(.custom("Avenir-Heavy", size: 24))
                        .multilineTextAlignment(.center)
                    
                    Text("Tap the button below to earn your first rewards.")
                        .font(.custom("Avenir-Medium", size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    // Task card preview
                    let taskTitle = selectedTaskTitle ?? customTaskTitle
                    HStack(spacing: 12) {
                        Image(systemName: "circle")
                            .font(.system(size: 22))
                            .foregroundColor(Color("AccentGold"))
                        Text(taskTitle)
                            .font(.custom("Avenir-Medium", size: 16))
                        Spacer()
                    }
                    .padding(16)
                    .background(Color("CardBackground"))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 32)
                }
            }
            
            Spacer()
            
            if showRewardAnimation {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep = .quickTour
                    }
                    AudioManager.shared.play(.buttonTap)
                } label: {
                    Text("Continue")
                        .font(.custom("Avenir-Heavy", size: 16))
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
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            } else {
                Button {
                    completeOnboardingTask()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Complete Quest")
                    }
                    .font(.custom("Avenir-Heavy", size: 16))
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
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
    }
    
    // MARK: - Step 3: Quick Tour
    
    private let tourSteps: [(icon: String, tab: String, description: String)] = [
        ("person.fill", "Character", "This is your hero. Complete tasks to level up."),
        ("map.fill", "Adventures", "Run dungeons and AFK missions to earn loot."),
        ("heart.fill", "Party", "Invite up to 3 friends to keep each other accountable.")
    ]
    
    private var quickTourStep: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("Your Adventure Awaits")
                .font(.custom("Avenir-Heavy", size: 24))
                .multilineTextAlignment(.center)
            
            // Tour tooltip cards
            VStack(spacing: 16) {
                ForEach(Array(tourSteps.enumerated()), id: \.offset) { index, step in
                    HStack(spacing: 16) {
                        Image(systemName: step.icon)
                            .font(.system(size: 28))
                            .foregroundColor(Color("AccentGold"))
                            .frame(width: 44, height: 44)
                            .background(Color("AccentGold").opacity(0.15))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(step.tab)
                                .font(.custom("Avenir-Heavy", size: 16))
                            Text(step.description)
                                .font(.custom("Avenir-Medium", size: 13))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(Color("CardBackground"))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                    .opacity(tooltipIndex >= index ? 1.0 : 0.3)
                    .offset(y: tooltipIndex >= index ? 0 : 10)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.3), value: tooltipIndex)
                }
            }
            .padding(.horizontal, 24)
            .onAppear {
                // Animate tooltips appearing one by one
                for i in 0..<tourSteps.count {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.4) {
                        withAnimation {
                            tooltipIndex = i
                        }
                    }
                }
            }
            
            Spacer()
            
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep = .starterGift
                }
                AudioManager.shared.play(.buttonTap)
            } label: {
                Text("Continue")
                    .font(.custom("Avenir-Heavy", size: 16))
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
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
    
    // MARK: - Step 4: Starter Gift
    
    private var starterGiftStep: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "gift.fill")
                .font(.system(size: 56))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color("AccentGold"), Color("AccentOrange")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(showStarterGift ? 1.0 : 0.5)
                .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showStarterGift)
            
            Text("Starter Equipment!")
                .font(.custom("Avenir-Heavy", size: 24))
                .multilineTextAlignment(.center)
            
            Text("Equip your gear to boost your stats.")
                .font(.custom("Avenir-Medium", size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Show starter equipment cards
            if showStarterGift {
                VStack(spacing: 12) {
                    starterEquipmentCard(
                        name: starterWeaponName,
                        slot: "Weapon",
                        icon: "bolt.fill",
                        stat: "+3 \(character.characterClass?.primaryStat.rawValue ?? "Strength")"
                    )
                    
                    starterEquipmentCard(
                        name: starterArmorName,
                        slot: "Armor",
                        icon: "shield.fill",
                        stat: "+2 Defense"
                    )
                }
                .padding(.horizontal, 32)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            
            Spacer()
            
            Button {
                grantStarterEquipment()
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep = .habitSetup
                }
                AudioManager.shared.play(.claimReward)
            } label: {
                Text("Claim & Equip")
                    .font(.custom("Avenir-Heavy", size: 16))
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
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    showStarterGift = true
                }
            }
        }
    }
    
    // MARK: - Step 5: Habit Setup (Optional)
    
    private var habitSetupStep: some View {
        VStack(spacing: 20) {
            Text("Set Up Daily Habits")
                .font(.custom("Avenir-Heavy", size: 24))
                .multilineTextAlignment(.center)
                .padding(.top, 24)
            
            Text("Pick habits you want to build. You can always change these later.")
                .font(.custom("Avenir-Medium", size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            ScrollView {
                let groups = Dictionary(grouping: habitSuggestions, by: { $0.group })
                let sortedKeys = ["Morning Routine", "Exercise", "Learning", "Wellness", "Social"]
                
                VStack(spacing: 20) {
                    ForEach(sortedKeys, id: \.self) { group in
                        if let habits = groups[group] {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(group)
                                    .font(.custom("Avenir-Heavy", size: 14))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 4)
                                
                                ForEach(habits, id: \.title) { habit in
                                    Button {
                                        withAnimation(.spring(response: 0.3)) {
                                            if selectedHabits.contains(habit.title) {
                                                selectedHabits.remove(habit.title)
                                            } else {
                                                selectedHabits.insert(habit.title)
                                            }
                                        }
                                        AudioManager.shared.play(.buttonTap)
                                    } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: selectedHabits.contains(habit.title) ? "checkmark.circle.fill" : "circle")
                                                .font(.system(size: 22))
                                                .foregroundColor(selectedHabits.contains(habit.title) ? Color("AccentGreen") : .secondary)
                                            
                                            Image(systemName: habit.icon)
                                                .font(.system(size: 16))
                                                .foregroundColor(Color(habit.category.color))
                                                .frame(width: 28)
                                            
                                            Text(habit.title)
                                                .font(.custom("Avenir-Medium", size: 15))
                                            
                                            Spacer()
                                            
                                            Text(habit.category.rawValue)
                                                .font(.custom("Avenir-Medium", size: 11))
                                                .foregroundColor(.secondary)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color(habit.category.color).opacity(0.15))
                                                .clipShape(Capsule())
                                        }
                                        .padding(12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(selectedHabits.contains(habit.title)
                                                      ? Color("AccentGreen").opacity(0.1)
                                                      : Color("CardBackground"))
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            
            // Buttons
            VStack(spacing: 12) {
                Button {
                    createSelectedHabits()
                    finishOnboarding()
                } label: {
                    Text(selectedHabits.isEmpty ? "Skip for Now" : "Set \(selectedHabits.count) Habit\(selectedHabits.count == 1 ? "" : "s")")
                        .font(.custom("Avenir-Heavy", size: 16))
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
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                
                if !selectedHabits.isEmpty {
                    Button {
                        finishOnboarding()
                    } label: {
                        Text("Skip")
                            .font(.custom("Avenir-Medium", size: 14))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
    
    // MARK: - Helper Views
    
    private func starterEquipmentCard(name: String, slot: String, icon: String, stat: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color("RarityCommon"))
                .frame(width: 44, height: 44)
                .background(Color("RarityCommon").opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.custom("Avenir-Heavy", size: 15))
                Text(slot)
                    .font(.custom("Avenir-Medium", size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(stat)
                .font(.custom("Avenir-Heavy", size: 14))
                .foregroundColor(Color("AccentGreen"))
        }
        .padding(16)
        .background(Color("CardBackground"))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Starter Equipment Names
    
    private var starterWeaponName: String {
        switch character.characterClass {
        case .warrior, .berserker, .paladin: return "Recruit's Sword"
        case .mage, .sorcerer, .enchanter: return "Apprentice's Staff"
        case .archer, .ranger, .trickster: return "Training Bow"
        default: return "Recruit's Sword"
        }
    }
    
    private var starterArmorName: String {
        switch character.characterClass {
        case .warrior, .berserker, .paladin: return "Iron Chestplate"
        case .mage, .sorcerer, .enchanter: return "Cloth Robe"
        case .archer, .ranger, .trickster: return "Leather Vest"
        default: return "Iron Chestplate"
        }
    }
    
    // MARK: - Actions
    
    /// Create and complete the onboarding task — this is a real GameTask
    private func completeOnboardingTask() {
        let taskTitle = selectedTaskTitle ?? customTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !taskTitle.isEmpty else { return }
        
        // Determine category from selection
        let category: TaskCategory = taskSuggestions.first(where: { $0.title == taskTitle })?.category ?? .wellness
        
        // Create a real GameTask
        let task = GameTask(
            title: taskTitle,
            description: "Your first quest!",
            category: category,
            createdBy: character.id,
            verificationType: .none
        )
        task.status = .completed
        task.completedAt = Date()
        task.completedBy = character.id
        modelContext.insert(task)
        
        // Award real rewards
        character.gainEXP(earnedEXP)
        character.gold += earnedGold
        character.tasksCompleted += 1
        character.tasksCompletedToday += 1
        character.lastActiveAt = Date()
        
        try? modelContext.save()
        
        // Haptic + sound
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        AudioManager.shared.play(.success)
        
        // Show reward animation
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showRewardAnimation = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animateReward = true
            }
        }
    }
    
    /// Grant starter equipment for the character's class
    private func grantStarterEquipment() {
        let primaryStat = character.characterClass?.primaryStat ?? .strength
        
        // Starter weapon
        let weapon = Equipment(
            name: starterWeaponName,
            description: "A trusty weapon for a new adventurer.",
            slot: .weapon,
            rarity: .common,
            primaryStat: primaryStat,
            statBonus: 3,
            levelRequirement: 1,
            ownerID: character.id
        )
        modelContext.insert(weapon)
        character.equipment.weapon = weapon
        weapon.isEquipped = true
        
        // Starter armor
        let armor = Equipment(
            name: starterArmorName,
            description: "Basic protection for a budding hero.",
            slot: .armor,
            rarity: .common,
            primaryStat: .defense,
            statBonus: 2,
            levelRequirement: 1,
            ownerID: character.id
        )
        modelContext.insert(armor)
        character.equipment.armor = armor
        armor.isEquipped = true
        
        try? modelContext.save()
    }
    
    /// Create habits from the user's selections
    private func createSelectedHabits() {
        guard !selectedHabits.isEmpty else { return }
        
        for habitTitle in selectedHabits {
            if let suggestion = habitSuggestions.first(where: { $0.title == habitTitle }) {
                let habit = GameTask(
                    title: suggestion.title,
                    category: suggestion.category,
                    createdBy: character.id,
                    isHabit: true
                )
                modelContext.insert(habit)
            }
        }
        try? modelContext.save()
    }
    
    /// Mark onboarding as complete and set up breadcrumbs
    private func finishOnboarding() {
        character.hasCompletedOnboarding = true
        
        // Set up breadcrumb quest log for the first week
        character.onboardingBreadcrumbs = [
            "tryDungeon": false,
            "sendMission": false,
            "inviteFriend": false,
            "visitForge": false,
            "checkStore": false
        ]
        
        // Reset comeback tracking since this is a new user
        character.resetComebackTracking()
        character.lastActiveAt = Date()
        
        try? modelContext.save()
        
        AudioManager.shared.play(.success)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        onComplete()
    }
}

// MARK: - Onboarding Progress Bar

struct OnboardingProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Capsule()
                    .fill(
                        step <= currentStep
                            ? Color("AccentGold")
                            : Color.secondary.opacity(0.3)
                    )
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
    }
}

#Preview {
    OnboardingView(
        character: PlayerCharacter(name: "Test Hero"),
        onComplete: {}
    )
    .environmentObject(GameEngine())
}
