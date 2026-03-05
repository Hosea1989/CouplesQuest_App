import SwiftUI
import SwiftData

/// "Welcome Back" overlay shown when a player returns after 3+ days of absence.
/// Gifts scale with absence duration. Tone: never guilt, always celebration.
/// "Here's what's waiting for you" — not "you lost X."
struct WelcomeBackView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var gameEngine: GameEngine
    let character: PlayerCharacter
    let onDismiss: () -> Void
    
    @State private var showGifts = false
    @State private var claimed = false
    
    /// Calculate the absence tier and gifts
    private var absenceDays: Int {
        character.daysSinceLastActive
    }
    
    private var tier: ComebackTier {
        switch absenceDays {
        case 3...6: return .short
        case 7...13: return .medium
        case 14...29: return .long
        default: return .veryLong
        }
    }
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color("AccentGold"), Color("AccentOrange")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Welcome Back!")
                        .font(.custom("Avenir-Heavy", size: 26))
                    
                    Text("You were away for \(absenceDays) day\(absenceDays == 1 ? "" : "s"). Your character rested and recovered.")
                        .font(.custom("Avenir-Medium", size: 15))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                
                // Gift cards
                if showGifts {
                    VStack(spacing: 12) {
                        ForEach(tier.gifts, id: \.label) { gift in
                            HStack(spacing: 14) {
                                Image(systemName: gift.icon)
                                    .font(.system(size: 22))
                                    .foregroundColor(Color(gift.color))
                                    .frame(width: 40, height: 40)
                                    .background(Color(gift.color).opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(gift.label)
                                        .font(.custom("Avenir-Heavy", size: 15))
                                    Text(gift.description)
                                        .font(.custom("Avenir-Medium", size: 12))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(12)
                            .background(Color("CardBackground").opacity(0.8))
                            .cornerRadius(12)
                        }
                        
                        // Streak recovery offer
                        if character.currentStreak == 0 && absenceDays >= 3 {
                            HStack(spacing: 14) {
                                Image(systemName: "shield.checkered")
                                    .font(.system(size: 22))
                                    .foregroundColor(Color("AccentOrange"))
                                    .frame(width: 40, height: 40)
                                    .background(Color("AccentOrange").opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Free Streak Armor")
                                        .font(.custom("Avenir-Heavy", size: 15))
                                    Text("Complete 3 tasks today to start a new streak!")
                                        .font(.custom("Avenir-Medium", size: 12))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(12)
                            .background(Color("AccentOrange").opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color("AccentOrange").opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                
                // Claim button
                Button {
                    claimComebackGifts()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: claimed ? "checkmark.circle.fill" : "gift.fill")
                        Text(claimed ? "Claimed!" : "Claim Gifts")
                    }
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(claimed ? Color("AccentGreen") : .black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        claimed
                        ? AnyShapeStyle(Color("AccentGreen").opacity(0.2))
                        : AnyShapeStyle(LinearGradient(
                            colors: [Color("AccentGold"), Color("AccentOrange")],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(claimed)
            }
            .padding(24)
            .background(Color("CardBackground"))
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 24)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showGifts = true
                }
            }
        }
    }
    
    // MARK: - Claim Logic
    
    private func claimComebackGifts() {
        guard !claimed else { return }
        
        // Grant gold
        character.gold += tier.goldAmount
        
        // Grant consumable for medium+ tiers
        if let consumableType = tier.consumable {
            let consumable = Consumable(
                name: consumableType.rawValue,
                description: "Welcome back gift!",
                consumableType: consumableType,
                icon: consumableType.icon,
                effectValue: 15,
                characterID: character.id
            )
            modelContext.insert(consumable)
        }
        
        // Grant streak shield for streak recovery
        if character.currentStreak == 0 && absenceDays >= 3 {
            let streakArmor = Consumable(
                name: "Streak Shield",
                description: "Protects your streak from breaking for one day.",
                consumableType: .streakShield,
                icon: "shield.checkered",
                effectValue: 1,
                characterID: character.id
            )
            modelContext.insert(streakArmor)
        }
        
        // Grant EXP boost for very long absence
        if tier == .veryLong {
            // 24-hour EXP boost represented as a consumable
            let expBoost = Consumable(
                name: "Welcome Back Boost",
                description: "24-hour EXP boost! +25% EXP from all sources.",
                consumableType: .expBoost,
                icon: "arrow.up.circle.fill",
                effectValue: 25,
                characterID: character.id
            )
            modelContext.insert(expBoost)
        }
        
        // Mark comeback as claimed
        character.markComebackGiftClaimed()
        character.lastActiveAt = Date()
        
        try? modelContext.save()
        
        // Haptics + sound
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        AudioManager.shared.play(.claimReward)
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            claimed = true
        }
        
        // Auto-dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            onDismiss()
        }
    }
}

// MARK: - Comeback Tier

enum ComebackTier: Equatable {
    case short      // 3-6 days: 200 Gold + 1 random consumable
    case medium     // 7-13 days: 500 Gold + 1 Uncommon+ equipment
    case long       // 14-29 days: 1000 Gold + 1 Rare+ equipment + "Welcome Back" title
    case veryLong   // 30+ days: All above + 24-hour EXP boost
    
    var goldAmount: Int {
        switch self {
        case .short: return 200
        case .medium: return 500
        case .long: return 1000
        case .veryLong: return 1000
        }
    }
    
    var consumable: ConsumableType? {
        switch self {
        case .short: return .hpPotion
        case .medium: return .expBoost
        case .long: return .expBoost
        case .veryLong: return .expBoost
        }
    }
    
    struct Gift {
        let icon: String
        let label: String
        let description: String
        let color: String
    }
    
    var gifts: [Gift] {
        var result: [Gift] = []
        
        result.append(Gift(
            icon: "dollarsign.circle.fill",
            label: "\(goldAmount) Gold",
            description: "A warm welcome back.",
            color: "AccentGold"
        ))
        
        switch self {
        case .short:
            result.append(Gift(
                icon: "cross.vial.fill",
                label: "HP Potion",
                description: "A random consumable to get you started.",
                color: "AccentGreen"
            ))
        case .medium:
            result.append(Gift(
                icon: "arrow.up.circle.fill",
                label: "EXP Boost",
                description: "An Uncommon consumable to speed up your return.",
                color: "AccentPurple"
            ))
        case .long:
            result.append(Gift(
                icon: "arrow.up.circle.fill",
                label: "EXP Boost",
                description: "A Rare consumable to welcome you back.",
                color: "AccentPurple"
            ))
            result.append(Gift(
                icon: "textformat",
                label: "\"Welcome Back\" Title",
                description: "A badge of honor for returning adventurers.",
                color: "AccentPink"
            ))
        case .veryLong:
            result.append(Gift(
                icon: "arrow.up.circle.fill",
                label: "EXP Boost",
                description: "A Rare consumable to welcome you back.",
                color: "AccentPurple"
            ))
            result.append(Gift(
                icon: "textformat",
                label: "\"Welcome Back\" Title",
                description: "A badge of honor for returning adventurers.",
                color: "AccentPink"
            ))
            result.append(Gift(
                icon: "sparkles",
                label: "24-Hour EXP Boost",
                description: "+25% EXP from all sources for 24 hours.",
                color: "AccentGold"
            ))
        }
        
        return result
    }
}

#Preview {
    ZStack {
        Color("BackgroundTop").ignoresSafeArea()
        WelcomeBackView(
            character: {
                let c = PlayerCharacter(name: "Test Hero")
                c.lastActiveAt = Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date()
                return c
            }(),
            onDismiss: {}
        )
        .environmentObject(GameEngine())
    }
}
