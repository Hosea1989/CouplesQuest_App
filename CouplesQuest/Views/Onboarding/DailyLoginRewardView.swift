import SwiftUI
import SwiftData

/// 7-day cycle daily login reward calendar.
/// Displayed as a modal overlay on first app open each day.
/// Cycle: Day 1-7 with escalating rewards, resets after Day 7.
struct DailyLoginRewardView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var gameEngine: GameEngine
    let character: PlayerCharacter
    let onClaim: () -> Void
    
    @State private var claimed = false
    @State private var claimAnimating = false
    
    /// The reward definitions for each day of the 7-day cycle
    private let rewards: [DailyReward] = [
        DailyReward(day: 1, icon: "dollarsign.circle.fill", label: "50 Gold", gold: 50, color: "AccentGold"),
        DailyReward(day: 2, icon: "cross.vial.fill", label: "Consumable", gold: 0, color: "AccentGreen", consumableType: .hpPotion),
        DailyReward(day: 3, icon: "dollarsign.circle.fill", label: "100 Gold", gold: 100, color: "AccentGold"),
        DailyReward(day: 4, icon: "hammer.fill", label: "Material", gold: 0, color: "AccentOrange", grantsMaterial: true),
        DailyReward(day: 5, icon: "dollarsign.circle.fill", label: "150 Gold + Potion", gold: 150, color: "AccentGold", consumableType: .expBoost),
        DailyReward(day: 6, icon: "hammer.fill", label: "2 Materials", gold: 0, color: "AccentOrange", grantsMaterial: true, materialCount: 2),
        DailyReward(day: 7, icon: "star.fill", label: "250 Gold + Loot Roll", gold: 250, color: "AccentPurple", isBonus: true),
    ]
    
    /// Current day in the cycle (1-based)
    private var currentDay: Int {
        character.loginStreakDay
    }
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { } // Prevent dismissal by tapping background
            
            // Card content
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 44))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color("AccentGold"), Color("AccentOrange")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Daily Login Reward")
                        .font(.custom("Avenir-Heavy", size: 24))
                    
                    HStack(spacing: 6) {
                        Text("Day \(currentDay) of 7")
                            .font(.custom("Avenir-Medium", size: 15))
                            .foregroundColor(.secondary)
                        
                        if character.currentStreak > 0 {
                            Text("•")
                                .foregroundColor(.secondary)
                            Image(systemName: "flame.fill")
                                .font(.system(size: 13))
                                .foregroundColor(Color("AccentOrange"))
                            Text("\(character.currentStreak) day streak")
                                .font(.custom("Avenir-Heavy", size: 15))
                                .foregroundColor(Color("AccentOrange"))
                        }
                    }
                }
                
                // 7-day calendar grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 14) {
                    ForEach(rewards, id: \.day) { reward in
                        DayRewardCell(
                            reward: reward,
                            isToday: reward.day == currentDay,
                            isClaimed: reward.day < currentDay || (reward.day == currentDay && claimed),
                            isFuture: reward.day > currentDay
                        )
                    }
                }
                .padding(.horizontal, 4)
                
                // Today's reward highlight
                if let todayReward = rewards.first(where: { $0.day == currentDay }) {
                    VStack(spacing: 10) {
                        Text("Today's Reward")
                            .font(.custom("Avenir-Heavy", size: 15))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 14) {
                            Image(systemName: todayReward.icon)
                                .font(.system(size: 28))
                                .foregroundColor(Color(todayReward.color))
                            
                            Text(todayReward.label)
                                .font(.custom("Avenir-Heavy", size: 20))
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(todayReward.color).opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color(todayReward.color).opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
                
                // Claim button
                Button {
                    claimReward()
                } label: {
                    HStack(spacing: 8) {
                        if claimAnimating {
                            ProgressView()
                                .tint(.black)
                        } else {
                            Image(systemName: claimed ? "checkmark.circle.fill" : "gift.fill")
                            Text(claimed ? "Claimed!" : "Claim Reward")
                        }
                    }
                    .font(.custom("Avenir-Heavy", size: 18))
                    .foregroundColor(claimed ? Color("AccentGreen") : .black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        claimed
                        ? AnyShapeStyle(Color("AccentGreen").opacity(0.2))
                        : AnyShapeStyle(LinearGradient(
                            colors: [Color("AccentGold"), Color("AccentOrange")],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(claimed)
            }
            .padding(28)
            .background(Color("CardBackground"))
            .cornerRadius(28)
            .shadow(color: .black.opacity(0.3), radius: 24, x: 0, y: 12)
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Claim Logic
    
    private func claimReward() {
        guard !claimed else { return }
        claimAnimating = true
        
        let todayReward = rewards.first(where: { $0.day == currentDay })
        
        // Grant gold
        if let gold = todayReward?.gold, gold > 0 {
            character.gold += gold
        }
        
        // Grant consumable if applicable
        if let consumableType = todayReward?.consumableType {
            let consumable = Consumable(
                name: consumableType.rawValue,
                description: "Claimed from daily login reward.",
                consumableType: consumableType,
                icon: consumableType.icon,
                effectValue: defaultEffectValue(for: consumableType),
                characterID: character.id
            )
            modelContext.insert(consumable)
        }
        
        // Grant crafting material if applicable
        if let todayReward, todayReward.grantsMaterial {
            let count = todayReward.materialCount
            for _ in 0..<count {
                let material = CraftingMaterial(
                    materialType: .ore,
                    rarity: .common,
                    quantity: 1,
                    characterID: character.id
                )
                modelContext.insert(material)
            }
        }
        
        // Day 7 bonus: extra gold already granted above, the "loot roll" is just extra flavor
        // (Agent 1 handles the actual loot roll system)
        
        // Advance the login cycle
        character.claimDailyLoginReward()
        
        do {
            try modelContext.save()
        } catch {
            print("❌ DailyLoginRewardView: Failed to save after claim: \(error)")
        }
        
        // Haptics + sound
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        AudioManager.shared.play(.claimReward)
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            claimed = true
            claimAnimating = false
        }
        
        // Auto-dismiss after a brief moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            onClaim()
        }
    }
    
    private func defaultEffectValue(for type: ConsumableType) -> Int {
        switch type {
        case .hpPotion: return 50
        case .expBoost: return 15
        case .goldBoost: return 20
        case .streakShield: return 1
        default: return 10
        }
    }
}

// MARK: - Daily Reward Model

struct DailyReward {
    let day: Int
    let icon: String
    let label: String
    let gold: Int
    let color: String
    var consumableType: ConsumableType? = nil
    var grantsMaterial: Bool = false
    var materialCount: Int = 1
    var isBonus: Bool = false
}

// MARK: - Day Reward Cell

struct DayRewardCell: View {
    let reward: DailyReward
    let isToday: Bool
    let isClaimed: Bool
    let isFuture: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Day \(reward.day)")
                .font(.custom("Avenir-Heavy", size: 12))
                .foregroundColor(isToday ? Color("AccentGold") : .secondary)
            
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .frame(width: 62, height: 62)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isToday ? Color("AccentGold") : Color.clear, lineWidth: 2)
                    )
                
                if isClaimed {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(Color("AccentGreen"))
                } else {
                    Image(systemName: reward.icon)
                        .font(.system(size: 24))
                        .foregroundColor(isFuture ? .secondary.opacity(0.5) : Color(reward.color))
                }
            }
        }
        .opacity(isFuture ? 0.6 : 1.0)
        .scaleEffect(isToday ? 1.1 : 1.0)
        .animation(.spring(response: 0.3), value: isToday)
    }
    
    private var backgroundColor: Color {
        if isToday {
            return Color("AccentGold").opacity(0.15)
        } else if isClaimed {
            return Color("AccentGreen").opacity(0.1)
        } else {
            return Color("CardBackground")
        }
    }
}

#Preview {
    ZStack {
        Color("BackgroundTop").ignoresSafeArea()
        DailyLoginRewardView(
            character: PlayerCharacter(name: "Test"),
            onClaim: {}
        )
        .environmentObject(GameEngine())
    }
}
