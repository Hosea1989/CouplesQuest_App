import SwiftUI
import SwiftData

struct MeditationView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var gameEngine: GameEngine
    @Query private var characters: [PlayerCharacter]
    
    @State private var showResult = false
    @State private var meditationResult: MeditationResult?
    @State private var isMeditating = false
    @State private var meditationProgress: Double = 0
    @State private var meditateTrigger = 0
    
    private var character: PlayerCharacter? {
        characters.first
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                meditationHeader
                
                if let character = character {
                    // Streak Card
                    streakCard(character: character)
                    
                    // Meditation Action
                    meditationActionCard(character: character)
                    
                    // Rewards Preview
                    rewardsPreview(character: character)
                    
                    // Streak Milestones
                    milestonesCard(character: character)
                }
            }
            .padding(.vertical)
        }
        .overlay {
            if showResult, let result = meditationResult {
                meditationResultOverlay(result: result)
            }
        }
        .sensoryFeedback(.success, trigger: meditateTrigger)
    }
    
    // MARK: - Header
    
    private var meditationHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color("AccentPurple").opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 36))
                    .foregroundColor(Color("AccentPurple"))
            }
            
            Text("Meditation")
                .font(.custom("Avenir-Heavy", size: 24))
            
            Text("Center your mind once daily. Build a streak for bonus EXP.")
                .font(.custom("Avenir-Medium", size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Streak Card
    
    @ViewBuilder
    private func streakCard(character: PlayerCharacter) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Meditation Streak")
                    .font(.custom("Avenir-Heavy", size: 16))
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(character.meditationStreak > 0 ? Color("AccentOrange") : .secondary)
                    Text("\(character.meditationStreak) day\(character.meditationStreak == 1 ? "" : "s")")
                        .font(.custom("Avenir-Heavy", size: 20))
                        .foregroundColor(character.meditationStreak > 0 ? Color("AccentOrange") : .secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Streak Bonus")
                    .font(.custom("Avenir-Medium", size: 12))
                    .foregroundColor(.secondary)
                let bonus = min(50, character.meditationStreak * 5)
                Text("+\(bonus)% EXP")
                    .font(.custom("Avenir-Heavy", size: 18))
                    .foregroundColor(bonus > 0 ? Color("AccentGreen") : .secondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
        .padding(.horizontal)
    }
    
    // MARK: - Meditation Action
    
    @ViewBuilder
    private func meditationActionCard(character: PlayerCharacter) -> some View {
        let alreadyMeditated = character.hasMeditatedToday
        
        VStack(spacing: 16) {
            if isMeditating {
                // Meditation animation
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(Color("AccentPurple").opacity(0.2), lineWidth: 6)
                            .frame(width: 120, height: 120)
                        Circle()
                            .trim(from: 0, to: meditationProgress)
                            .stroke(Color("AccentPurple"), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 40))
                            .foregroundColor(Color("AccentPurple"))
                    }
                    
                    Text("Meditating...")
                        .font(.custom("Avenir-Heavy", size: 18))
                        .foregroundColor(Color("AccentPurple"))
                }
            } else if alreadyMeditated {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color("AccentGreen"))
                    Text("Meditation Complete")
                        .font(.custom("Avenir-Heavy", size: 18))
                        .foregroundColor(Color("AccentGreen"))
                    Text("Come back tomorrow to continue your streak!")
                        .font(.custom("Avenir-Medium", size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else {
                Button {
                    startMeditation(character: character)
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Begin Meditation")
                    }
                    .font(.custom("Avenir-Heavy", size: 18))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color("AccentPurple"), Color("AccentPink")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
        .padding(.horizontal)
    }
    
    // MARK: - Rewards Preview
    
    @ViewBuilder
    private func rewardsPreview(character: PlayerCharacter) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Rewards")
                .font(.custom("Avenir-Heavy", size: 18))
            
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundColor(Color("AccentGold"))
                    Text("+\(character.meditationExpReward)")
                        .font(.custom("Avenir-Heavy", size: 18))
                    Text("EXP")
                        .font(.custom("Avenir-Medium", size: 11))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                VStack(spacing: 4) {
                    Image(systemName: "dollarsign.circle")
                        .font(.title3)
                        .foregroundColor(Color("AccentGold"))
                    Text("+\(character.meditationGoldReward)")
                        .font(.custom("Avenir-Heavy", size: 18))
                    Text("Gold")
                        .font(.custom("Avenir-Medium", size: 11))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                VStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.title3)
                        .foregroundColor(Color("AccentOrange"))
                    Text("+1")
                        .font(.custom("Avenir-Heavy", size: 18))
                    Text("Streak")
                        .font(.custom("Avenir-Medium", size: 11))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
        .padding(.horizontal)
    }
    
    // MARK: - Milestones
    
    @ViewBuilder
    private func milestonesCard(character: PlayerCharacter) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Streak Milestones")
                .font(.custom("Avenir-Heavy", size: 18))
            
            let milestones: [(days: Int, bonus: String)] = [
                (3, "+15% EXP"),
                (7, "+35% EXP"),
                (10, "+50% EXP (Max)"),
            ]
            
            ForEach(milestones, id: \.days) { milestone in
                HStack(spacing: 12) {
                    Image(systemName: character.meditationStreak >= milestone.days ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(character.meditationStreak >= milestone.days ? Color("AccentGreen") : .secondary)
                    
                    Text("\(milestone.days)-Day Streak")
                        .font(.custom("Avenir-Heavy", size: 14))
                    
                    Spacer()
                    
                    Text(milestone.bonus)
                        .font(.custom("Avenir-Heavy", size: 12))
                        .foregroundColor(Color("AccentGold"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color("AccentGold").opacity(0.15)))
                }
                .padding(.vertical, 2)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
        .padding(.horizontal)
    }
    
    // MARK: - Result Overlay
    
    @ViewBuilder
    private func meditationResultOverlay(result: MeditationResult) -> some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation { showResult = false }
                }
            
            VStack(spacing: 20) {
                Image(systemName: "sparkles")
                    .font(.system(size: 50))
                    .foregroundColor(Color("AccentPurple"))
                
                Text("Mind Refreshed!")
                    .font(.custom("Avenir-Heavy", size: 24))
                
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("+\(result.expGained) EXP")
                    }
                    .font(.custom("Avenir-Heavy", size: 18))
                    .foregroundColor(Color("AccentGold"))
                    
                    HStack {
                        Image(systemName: "dollarsign.circle")
                        Text("+\(result.goldGained) Gold")
                    }
                    .font(.custom("Avenir-Medium", size: 16))
                    .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "flame.fill")
                        Text("\(result.streak)-day streak!")
                    }
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(Color("AccentOrange"))
                }
                
                Button {
                    withAnimation { showResult = false }
                } label: {
                    Text("Continue")
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.black)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(colors: [Color("AccentGold"), Color("AccentOrange")], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color("BackgroundTop"))
            )
            .padding(40)
        }
        .transition(.opacity)
    }
    
    // MARK: - Actions
    
    private func startMeditation(character: PlayerCharacter) {
        isMeditating = true
        meditationProgress = 0
        
        // Animate the meditation circle
        withAnimation(.easeInOut(duration: 2.0)) {
            meditationProgress = 1.0
        }
        
        // Complete after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isMeditating = false
            
            if let result = gameEngine.meditate(character: character) {
                meditationResult = result
                meditateTrigger += 1
                withAnimation {
                    showResult = true
                }
            }
        }
    }
}

#Preview {
    MeditationView()
        .environmentObject(GameEngine())
}
