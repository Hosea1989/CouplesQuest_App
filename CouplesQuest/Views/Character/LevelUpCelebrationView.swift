import SwiftUI

struct LevelUpCelebrationView: View {
    @EnvironmentObject var gameEngine: GameEngine
    let character: PlayerCharacter
    let rewards: [LevelUpReward]
    let onDismiss: () -> Void
    
    @State private var showTitle = false
    @State private var showLevel = false
    @State private var showRewards = false
    @State private var showButton = false
    @State private var sparkleOffsets: [CGSize] = (0..<12).map { _ in
        CGSize(
            width: CGFloat.random(in: -150...150),
            height: CGFloat.random(in: -200...200)
        )
    }
    @State private var sparkleOpacities: [Double] = Array(repeating: 0, count: 12)
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            // Sparkle particles
            ForEach(0..<12, id: \.self) { index in
                Image(systemName: "sparkle")
                    .font(.system(size: CGFloat.random(in: 10...24)))
                    .foregroundColor(Color("AccentGold"))
                    .offset(sparkleOffsets[index])
                    .opacity(sparkleOpacities[index])
            }
            
            // Main content
            VStack(spacing: 32) {
                Spacer()
                
                // Level Up title
                VStack(spacing: 8) {
                    Text("LEVEL UP!")
                        .font(.custom("Avenir-Heavy", size: 44))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color("AccentGold"), Color("AccentOrange")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .scaleEffect(showTitle ? 1.0 : 0.3)
                        .opacity(showTitle ? 1 : 0)
                    
                    // Level number
                    Text("Level \(character.level)")
                        .font(.custom("Avenir-Heavy", size: 28))
                        .foregroundColor(.white)
                        .opacity(showLevel ? 1 : 0)
                        .offset(y: showLevel ? 0 : 20)
                    
                    // Title change
                    Text(character.title)
                        .font(.custom("Avenir-Medium", size: 18))
                        .foregroundColor(Color("AccentGold").opacity(0.8))
                        .opacity(showLevel ? 1 : 0)
                        .offset(y: showLevel ? 0 : 20)
                }
                
                // Rewards list
                VStack(spacing: 12) {
                    Text("Rewards")
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.white.opacity(0.7))
                    
                    ForEach(Array(consolidatedRewards.enumerated()), id: \.offset) { index, reward in
                        LevelUpRewardRow(reward: reward)
                            .opacity(showRewards ? 1 : 0)
                            .offset(y: showRewards ? 0 : 20)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.7)
                                    .delay(Double(index) * 0.1),
                                value: showRewards
                            )
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.1))
                )
                .padding(.horizontal, 32)
                .opacity(showRewards ? 1 : 0)
                
                Spacer()
                
                // Continue button
                Button(action: onDismiss) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Continue")
                    }
                    .font(.custom("Avenir-Heavy", size: 18))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [Color("AccentGold"), Color("AccentOrange")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
                .opacity(showButton ? 1 : 0)
                .offset(y: showButton ? 0 : 30)
            }
        }
        .onAppear {
            animateEntrance()
        }
    }
    
    /// Consolidate rewards for display (e.g., combine multiple stat points)
    private var consolidatedRewards: [RewardDisplay] {
        var displays: [RewardDisplay] = []
        
        let statPoints = rewards.filter { $0 == .statPoint }.count
        if statPoints > 0 {
            displays.append(RewardDisplay(
                icon: "arrow.up.circle.fill",
                text: "+\(statPoints) Stat Point\(statPoints == 1 ? "" : "s")",
                color: "AccentGold"
            ))
        }
        
        let totalGold = rewards.compactMap { reward -> Int? in
            if case .gold(let amount) = reward { return amount }
            return nil
        }.reduce(0, +)
        if totalGold > 0 {
            displays.append(RewardDisplay(
                icon: "dollarsign.circle.fill",
                text: "+\(totalGold) Gold",
                color: "AccentGold"
            ))
        }
        
        if rewards.contains(.classEvolution) {
            displays.append(RewardDisplay(
                icon: "arrow.up.forward.circle.fill",
                text: "Class Evolution Available!",
                color: "AccentGold"
            ))
        }
        
        return displays
    }
    
    private func animateEntrance() {
        AudioManager.shared.play(.levelUp)
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            showTitle = true
        }
        
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            showLevel = true
        }
        
        withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
            showRewards = true
        }
        
        withAnimation(.easeOut(duration: 0.5).delay(1.0)) {
            showButton = true
        }
        
        // Animate sparkles
        for i in 0..<12 {
            let delay = Double.random(in: 0.1...0.8)
            withAnimation(.easeOut(duration: 1.0).delay(delay)) {
                sparkleOpacities[i] = Double.random(in: 0.3...1.0)
            }
            withAnimation(.easeOut(duration: 2.0).delay(delay + 1.0)) {
                sparkleOpacities[i] = 0
                sparkleOffsets[i] = CGSize(
                    width: sparkleOffsets[i].width * 1.5,
                    height: sparkleOffsets[i].height * 1.5
                )
            }
        }
    }
}

// MARK: - Supporting Types

struct RewardDisplay {
    let icon: String
    let text: String
    let color: String
}

struct LevelUpRewardRow: View {
    let reward: RewardDisplay
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: reward.icon)
                .font(.title3)
                .foregroundColor(Color(reward.color))
            
            Text(reward.text)
                .font(.custom("Avenir-Heavy", size: 16))
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

#Preview {
    LevelUpCelebrationView(
        character: PlayerCharacter(name: "Test Hero"),
        rewards: [.statPoint, .gold(50), .classEvolution],
        onDismiss: {}
    )
    .environmentObject(GameEngine())
}
