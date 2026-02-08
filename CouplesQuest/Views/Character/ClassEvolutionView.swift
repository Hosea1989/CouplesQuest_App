import SwiftUI

struct ClassEvolutionView: View {
    @Bindable var character: PlayerCharacter
    @EnvironmentObject var gameEngine: GameEngine
    @Environment(\.dismiss) private var dismiss
    @State private var evolved = false
    @State private var selectedEvolution: CharacterClass?
    
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
                        
                        // Evolution paths
                        ForEach(evolutionOptions, id: \.self) { advClass in
                            EvolutionPathCard(
                                advancedClass: advClass,
                                character: character,
                                canEvolve: gameEngine.canEvolve(character: character, to: advClass),
                                isSelected: selectedEvolution == advClass,
                                onSelect: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedEvolution = advClass
                                    }
                                }
                            )
                        }
                        
                        // Evolve button
                        if let target = selectedEvolution {
                            let eligible = gameEngine.canEvolve(character: character, to: target)
                            
                            Button(action: {
                                if gameEngine.evolveClass(to: target, for: character) {
                                    evolved = true
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "sparkles")
                                    Text("Evolve to \(target.rawValue)")
                                }
                                .font(.custom("Avenir-Heavy", size: 18))
                                .foregroundColor(eligible ? .black : .secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    LinearGradient(
                                        colors: eligible
                                            ? [Color("AccentGold"), Color("AccentOrange")]
                                            : [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .disabled(!eligible)
                            .padding(.horizontal, 8)
                            
                            if !eligible {
                                if let stat = target.evolutionStat {
                                    let currentVal = character.effectiveStats.value(for: stat)
                                    Text("Requires \(stat.rawValue) >= \(target.evolutionStatThreshold) (current: \(currentVal))")
                                        .font(.custom("Avenir-Medium", size: 13))
                                        .foregroundColor(.red)
                                        .multilineTextAlignment(.center)
                                }
                            }
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
            .alert("Evolution Complete!", isPresented: $evolved) {
                Button("Continue") { dismiss() }
            } message: {
                if let cls = character.characterClass {
                    Text("You have evolved into a \(cls.rawValue)! New skills have been unlocked.")
                }
            }
        }
    }
}

// MARK: - Evolution Path Card

struct EvolutionPathCard: View {
    let advancedClass: CharacterClass
    let character: PlayerCharacter
    let canEvolve: Bool
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    // Class icon
                    ZStack {
                        Circle()
                            .fill(
                                isSelected
                                    ? Color("AccentGold").opacity(0.3)
                                    : Color.secondary.opacity(0.1)
                            )
                            .frame(width: 64, height: 64)
                        
                        if isSelected {
                            Circle()
                                .stroke(Color("AccentGold"), lineWidth: 3)
                                .frame(width: 64, height: 64)
                        }
                        
                        Image(systemName: advancedClass.icon)
                            .font(.system(size: 28))
                            .foregroundColor(isSelected ? Color("AccentGold") : .secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(advancedClass.rawValue)
                                .font(.custom("Avenir-Heavy", size: 20))
                                .foregroundColor(isSelected ? Color("AccentGold") : .primary)
                            
                            if canEvolve {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color("AccentGreen"))
                            }
                        }
                        
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
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color("AccentGold") : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ClassEvolutionView(character: PlayerCharacter(name: "Test Hero"))
        .environmentObject(GameEngine())
}
