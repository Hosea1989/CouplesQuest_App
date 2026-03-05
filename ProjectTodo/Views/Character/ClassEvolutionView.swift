import SwiftUI

struct ClassEvolutionView: View {
    @Bindable var character: PlayerCharacter
    @EnvironmentObject var gameEngine: GameEngine
    @Environment(\.dismiss) private var dismiss
    
    private var currentClass: CharacterClass? {
        character.characterClass
    }
    
    private var evolutionOptions: [CharacterClass] {
        currentClass?.evolutionOptions ?? []
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
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "arrow.up.forward.circle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color("AccentGold"), Color("AccentOrange")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("Class Evolution")
                                .font(.custom("Avenir-Heavy", size: 28))
                            
                            if let cls = currentClass {
                                Text("Your \(cls.rawValue) has reached new heights!")
                                    .font(.custom("Avenir-Medium", size: 16))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, 20)
                        
                        // Instruction banner
                        VStack(spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color("AccentGold"))
                                Text("Complete a Rank-Up Training Course")
                                    .font(.custom("Avenir-Heavy", size: 15))
                                    .foregroundColor(Color("AccentGold"))
                            }
                            
                            Text("Go to Training in the Adventures tab and complete a rank-up course to evolve your class.")
                                .font(.custom("Avenir-Medium", size: 13))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color("AccentGold").opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color("AccentGold").opacity(0.3), lineWidth: 1)
                                )
                        )
                        
                        // Evolution paths (read-only preview)
                        ForEach(evolutionOptions, id: \.self) { advClass in
                            EvolutionPathCard(
                                advancedClass: advClass,
                                character: character
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color("AccentGold"))
                }
            }
        }
    }
}

// MARK: - Evolution Path Card (read-only preview showing requirements)

struct EvolutionPathCard: View {
    let advancedClass: CharacterClass
    let character: PlayerCharacter
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Class icon
                ZStack {
                    Circle()
                        .fill(Color.secondary.opacity(0.1))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: advancedClass.icon)
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(advancedClass.rawValue)
                        .font(.custom("Avenir-Heavy", size: 20))
                        .foregroundColor(.primary)
                    
                    Text(advancedClass.description)
                        .font(.custom("Avenir-Medium", size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                
                Spacer()
            }
            
            // Requirements
            if let stat = advancedClass.evolutionStat {
                let currentVal = character.effectiveStats.value(for: stat)
                let threshold = advancedClass.evolutionStatThreshold
                let met = currentVal >= threshold
                
                HStack(spacing: 16) {
                    // Level requirement
                    HStack(spacing: 4) {
                        Image(systemName: character.level >= 20 ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(character.level >= 20 ? Color("AccentGreen") : .red)
                        Text("Level 20+")
                            .font(.custom("Avenir-Medium", size: 13))
                            .foregroundColor(character.level >= 20 ? Color("AccentGreen") : .secondary)
                    }
                    
                    // Stat requirement
                    HStack(spacing: 4) {
                        Image(systemName: met ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(met ? Color("AccentGreen") : .red)
                        Image(systemName: stat.icon)
                            .font(.system(size: 12))
                            .foregroundColor(Color(stat.color))
                        Text("\(stat.rawValue) \(currentVal)/\(threshold)")
                            .font(.custom("Avenir-Medium", size: 13))
                            .foregroundColor(met ? Color("AccentGreen") : .secondary)
                    }
                }
            }
            
            // Ability preview
            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 11))
                    .foregroundColor(Color("AccentPurple"))
                Text(advancedClass.abilityName)
                    .font(.custom("Avenir-Heavy", size: 12))
                    .foregroundColor(Color("AccentPurple"))
                Text("- \(advancedClass.abilityDescription)")
                    .font(.custom("Avenir-Medium", size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
    }
}

#Preview {
    ClassEvolutionView(character: PlayerCharacter(name: "Test Hero"))
        .environmentObject(GameEngine())
}
