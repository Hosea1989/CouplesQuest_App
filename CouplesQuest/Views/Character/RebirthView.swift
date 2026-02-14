import SwiftUI

/// Prestige confirmation screen showing what you keep, what resets, and what you gain.
/// Presented as a sheet from CharacterView when the player is level 100+.
struct RebirthView: View {
    @Bindable var character: PlayerCharacter
    @EnvironmentObject var gameEngine: GameEngine
    @Environment(\.dismiss) private var dismiss
    
    @State private var showConfirmation = false
    @State private var isProcessing = false
    @State private var showSuccess = false
    @State private var selectedStarterClass: CharacterClass? = nil
    
    /// The bonus this rebirth will grant
    private var nextBonus: (label: String, detail: String) {
        let nextCount = character.rebirthCount + 1
        switch nextCount {
        case 1:
            return ("EXP Bonus", "+5% EXP from all sources forever")
        case 2:
            return ("Gold Bonus", "+5% Gold from all sources forever")
        case 3:
            return ("Loot Bonus", "+5% Loot drop chance forever")
        case 4:
            return ("Stats Bonus", "+3% all stats forever")
        default:
            return ("Stats Bonus", "+1% all stats forever (stacking)")
        }
    }
    
    /// The title this rebirth will grant
    private var nextTitle: String {
        let nextCount = character.rebirthCount + 1
        switch nextCount {
        case 1: return "Reborn"
        case 2: return "Twice-Forged"
        case 3: return "Thrice-Blessed"
        case 4: return "Ascendant"
        default: return "Eternal \(character.characterClass?.rawValue ?? "Hero")"
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color("BackgroundTop"), Color("BackgroundBottom")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if showSuccess {
                    rebirthSuccessView
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Header
                            rebirthHeader
                            
                            // What You Keep
                            keepSection
                            
                            // What Resets
                            resetSection
                            
                            // What You Gain
                            gainSection
                            
                            // Current rebirth bonuses (if any)
                            if character.rebirthCount > 0 {
                                currentBonusesSection
                            }
                            
                            // Class selection for rebirth
                            classSelectionSection
                            
                            // Rebirth button
                            rebirthButton
                            
                            // Safety note
                            Text("Rebirth is permanent. You cannot undo this action.")
                                .font(.custom("Avenir-Medium", size: 12))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .padding(.bottom, 24)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Rebirth")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color("AccentGold"))
                }
            }
            .alert("Confirm Rebirth", isPresented: $showConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Rebirth", role: .destructive) {
                    performRebirth()
                }
            } message: {
                Text("Your level and class will reset to 1. You will keep all equipment, cards, achievements, and currency. You'll gain: \(nextBonus.detail). This cannot be undone.")
            }
        }
    }
    
    // MARK: - Header
    
    private var rebirthHeader: some View {
        VStack(spacing: 12) {
            // Rebirth icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color("AccentGold").opacity(0.2), Color("AccentPurple").opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "arrow.trianglehead.2.counterclockwise.rotate.90")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("AccentGold"), Color("AccentPurple")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            
            Text("Rebirth #\(character.rebirthCount + 1)")
                .font(.custom("Avenir-Heavy", size: 24))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color("AccentGold"), Color("AccentPurple")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text("Begin your journey anew, stronger than before")
                .font(.custom("Avenir-Medium", size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Keep Section
    
    private var keepSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(Color("AccentGreen"))
                Text("What You Keep")
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(Color("AccentGreen"))
            }
            
            keepRow(icon: "shield.fill", text: "All equipment & inventory")
            keepRow(icon: "rectangle.stack.fill", text: "Monster card collection")
            keepRow(icon: "trophy.fill", text: "All achievements")
            keepRow(icon: "dollarsign.circle.fill", text: "\(character.gold) Gold")
            keepRow(icon: "diamond.fill", text: "\(character.gems) Gems")
            keepRow(icon: "heart.fill", text: "Party & bond progress")
            keepRow(icon: "star.fill", text: "Permanent rebirth bonuses")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Reset Section
    
    private var resetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.counterclockwise")
                    .foregroundColor(Color("AccentOrange"))
                Text("What Resets")
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(Color("AccentOrange"))
            }
            
            resetRow(icon: "arrow.up.circle", text: "Level \(character.level) → Level 1")
            resetRow(icon: "person.crop.circle", text: "Class resets (choose new starter)")
            resetRow(icon: "chart.bar", text: "Stat points re-allocated on level-up")
            if character.paragonLevel > 0 {
                resetRow(icon: "sparkles", text: "Paragon Level \(character.paragonLevel) → 0")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Gain Section
    
    private var gainSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "gift.fill")
                    .foregroundColor(Color("AccentPurple"))
                Text("What You Gain")
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(Color("AccentPurple"))
            }
            
            // Permanent bonus
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color("AccentPurple").opacity(0.2))
                        .frame(width: 36, height: 36)
                    Image(systemName: "bolt.fill")
                        .foregroundColor(Color("AccentPurple"))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(nextBonus.label)
                        .font(.custom("Avenir-Heavy", size: 14))
                    Text(nextBonus.detail)
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            // Title
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color("AccentGold").opacity(0.2))
                        .frame(width: 36, height: 36)
                    Image(systemName: "crown.fill")
                        .foregroundColor(Color("AccentGold"))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Title: \"\(nextTitle)\"")
                        .font(.custom("Avenir-Heavy", size: 14))
                    Text("Visible to party members and on leaderboards")
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            // Rebirth Star
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color("AccentGold").opacity(0.2), Color("AccentPurple").opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                    Image(systemName: "star.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color("AccentGold"), Color("AccentPurple")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rebirth Star Frame")
                        .font(.custom("Avenir-Heavy", size: 14))
                    Text("A special avatar frame marking your prestige")
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            // Faster leveling
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color("AccentGreen").opacity(0.2))
                        .frame(width: 36, height: 36)
                    Image(systemName: "hare.fill")
                        .foregroundColor(Color("AccentGreen"))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Faster Re-leveling")
                        .font(.custom("Avenir-Heavy", size: 14))
                    Text("Your kept equipment makes leveling much faster")
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Current Bonuses Section
    
    private var currentBonusesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "star.circle.fill")
                    .foregroundColor(Color("AccentGold"))
                Text("Current Rebirth Bonuses")
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(Color("AccentGold"))
            }
            
            let bonuses = character.getPermanentBonuses()
            if let v = bonuses["expBonus"], v > 0 {
                bonusDisplayRow(label: "EXP Bonus", value: "+\(Int(v * 100))%")
            }
            if let v = bonuses["goldBonus"], v > 0 {
                bonusDisplayRow(label: "Gold Bonus", value: "+\(Int(v * 100))%")
            }
            if let v = bonuses["lootBonus"], v > 0 {
                bonusDisplayRow(label: "Loot Bonus", value: "+\(Int(v * 100))%")
            }
            if let v = bonuses["allStatsBonus"], v > 0 {
                bonusDisplayRow(label: "All Stats", value: "+\(Int(v * 100))%")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Class Selection
    
    private var classSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .foregroundColor(Color("AccentPurple"))
                Text("Choose New Starter Class")
                    .font(.custom("Avenir-Heavy", size: 16))
            }
            
            Text("After Rebirth, you'll start with a new class and can evolve along a different path at level 20.")
                .font(.custom("Avenir-Medium", size: 13))
                .foregroundColor(.secondary)
            
            ForEach(CharacterClass.starters, id: \.self) { starterClass in
                Button(action: {
                    selectedStarterClass = starterClass
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: starterClass.icon)
                            .font(.system(size: 20))
                            .foregroundColor(selectedStarterClass == starterClass ? Color("AccentPurple") : .secondary)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(starterClass.rawValue)
                                .font(.custom("Avenir-Heavy", size: 14))
                                .foregroundColor(selectedStarterClass == starterClass ? .primary : .secondary)
                            Text("Evolves into: \(starterClass.evolutionOptions.map(\.rawValue).joined(separator: " or "))")
                                .font(.custom("Avenir-Medium", size: 11))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedStarterClass == starterClass {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color("AccentPurple"))
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedStarterClass == starterClass
                                  ? Color("AccentPurple").opacity(0.1)
                                  : Color.secondary.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedStarterClass == starterClass
                                    ? Color("AccentPurple").opacity(0.3)
                                    : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Rebirth Button
    
    private var rebirthButton: some View {
        Button(action: {
            showConfirmation = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.trianglehead.2.counterclockwise.rotate.90")
                Text("Begin Rebirth")
            }
            .font(.custom("Avenir-Heavy", size: 18))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                selectedStarterClass != nil
                ? LinearGradient(
                    colors: [Color("AccentGold"), Color("AccentPurple")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                : LinearGradient(
                    colors: [Color.secondary.opacity(0.3), Color.secondary.opacity(0.3)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(selectedStarterClass == nil || isProcessing)
        .padding(.horizontal)
    }
    
    // MARK: - Success View
    
    private var rebirthSuccessView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Animated rebirth icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color("AccentGold").opacity(0.3), Color("AccentPurple").opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "star.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("AccentGold"), Color("AccentPurple")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            
            VStack(spacing: 8) {
                Text("REBORN!")
                    .font(.custom("Avenir-Heavy", size: 36))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("AccentGold"), Color("AccentPurple")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                if let title = character.rebirthTitle {
                    Text("Title: \"\(title)\"")
                        .font(.custom("Avenir-Heavy", size: 18))
                        .foregroundColor(Color("AccentGold"))
                }
                
                Text("Your permanent bonus has been applied.")
                    .font(.custom("Avenir-Medium", size: 14))
                    .foregroundColor(.secondary)
                
                Text(nextBonus.detail)
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(Color("AccentPurple"))
            }
            
            Spacer()
            
            Button(action: { dismiss() }) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.right.circle.fill")
                    Text("Begin New Journey")
                }
                .font(.custom("Avenir-Heavy", size: 18))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [Color("AccentGold"), Color("AccentPurple")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }
    
    // MARK: - Actions
    
    private func performRebirth() {
        isProcessing = true
        
        // Perform the rebirth through GameEngine
        gameEngine.performRebirth(character: character)
        
        // Apply the selected starter class after rebirth
        if let starterClass = selectedStarterClass {
            character.characterClass = starterClass
            // Apply starter class base stats
            let baseStats = starterClass.baseStats
            character.stats.strength = baseStats.strength
            character.stats.wisdom = baseStats.wisdom
            character.stats.charisma = baseStats.charisma
            character.stats.dexterity = baseStats.dexterity
            character.stats.luck = baseStats.luck
            character.stats.defense = baseStats.defense
        }
        
        isProcessing = false
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            showSuccess = true
        }
    }
    
    // MARK: - Helper Rows
    
    @ViewBuilder
    private func keepRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color("AccentGreen"))
                .frame(width: 16)
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color("AccentGreen").opacity(0.7))
                .frame(width: 20)
            Text(text)
                .font(.custom("Avenir-Medium", size: 13))
        }
    }
    
    @ViewBuilder
    private func resetRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.counterclockwise")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color("AccentOrange"))
                .frame(width: 16)
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color("AccentOrange").opacity(0.7))
                .frame(width: 20)
            Text(text)
                .font(.custom("Avenir-Medium", size: 13))
        }
    }
    
    @ViewBuilder
    private func bonusDisplayRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.custom("Avenir-Medium", size: 13))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.custom("Avenir-Heavy", size: 14))
                .foregroundColor(Color("AccentGreen"))
        }
    }
}

#Preview {
    let character = PlayerCharacter(name: "Test Hero")
    character.level = 100
    return RebirthView(character: character)
        .environmentObject(GameEngine())
}
