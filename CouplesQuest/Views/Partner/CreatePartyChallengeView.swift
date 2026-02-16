import SwiftUI
import SwiftData

/// Sheet for the party leader to create a new party challenge.
struct CreatePartyChallengeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let character: PlayerCharacter
    let bond: Bond
    
    @State private var selectedType: PartyChallengeType = .tasks
    @State private var targetCount: Int = 10
    @State private var duration: ChallengeDuration = .oneWeek
    @State private var isCreating = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Challenge Type Picker
                    challengeTypePicker
                    
                    // Target Count
                    targetCountSection
                    
                    // Duration
                    durationPicker
                    
                    // Reward Preview
                    rewardPreview
                    
                    // Create Button
                    createButton
                }
                .padding()
            }
            .background(Color("BackgroundBottom"))
            .navigationTitle("Set Party Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color("AccentGold"))
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 40))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color("AccentGold"), Color("AccentOrange")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Rally Your Party")
                .font(.custom("Avenir-Heavy", size: 20))
            
            Text("Set a goal for everyone to work toward. All members must hit the target before time runs out!")
                .font(.custom("Avenir-Medium", size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Challenge Type Picker
    
    private var challengeTypePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Challenge Type")
                .font(.custom("Avenir-Heavy", size: 14))
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(PartyChallengeType.allCases) { type in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedType = type
                            // Reset target to first suggested value for new type
                            targetCount = type.suggestedTargets.first ?? 5
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: type.icon)
                                .font(.body)
                            Text(type.rawValue)
                                .font(.custom("Avenir-Heavy", size: 13))
                        }
                        .foregroundColor(selectedType == type ? .white : Color(type.color))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedType == type ? Color(type.color) : Color(type.color).opacity(0.15))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Target Count
    
    private var targetCountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Target")
                    .font(.custom("Avenir-Heavy", size: 14))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(targetCount) \(selectedType.rawValue.lowercased())")
                    .font(.custom("Avenir-Heavy", size: 14))
                    .foregroundColor(Color(selectedType.color))
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(selectedType.suggestedTargets, id: \.self) { target in
                        Button {
                            withAnimation { targetCount = target }
                        } label: {
                            Text("\(target)")
                                .font(.custom("Avenir-Heavy", size: 16))
                                .foregroundColor(targetCount == target ? .white : Color(selectedType.color))
                                .frame(width: 50, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(targetCount == target ? Color(selectedType.color) : Color(selectedType.color).opacity(0.15))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    // MARK: - Duration Picker
    
    private var durationPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Duration")
                .font(.custom("Avenir-Heavy", size: 14))
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                ForEach(ChallengeDuration.allCases) { dur in
                    Button {
                        withAnimation { duration = dur }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption)
                            Text(dur.label)
                                .font(.custom("Avenir-Heavy", size: 12))
                        }
                        .foregroundColor(duration == dur ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(duration == dur ? Color("AccentGold") : Color("CardBackground"))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Reward Preview
    
    private var rewardPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Rewards")
                .font(.custom("Avenir-Heavy", size: 14))
                .foregroundColor(.secondary)
            
            let bondEXP = PartyChallenge.calculateRewardBondEXP(type: selectedType, target: targetCount)
            let gold = PartyChallenge.calculateRewardGold(type: selectedType, target: targetCount)
            let partyBonus = PartyChallenge.calculatePartyBonus(type: selectedType, target: targetCount)
            
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(Color("AccentPink"))
                    Text("Per Member:")
                        .font(.custom("Avenir-Medium", size: 13))
                    Spacer()
                    Text("+\(bondEXP) Bond EXP")
                        .font(.custom("Avenir-Heavy", size: 13))
                        .foregroundColor(Color("AccentPink"))
                    Text("·")
                        .foregroundColor(.secondary)
                    Text("+\(gold) Gold")
                        .font(.custom("Avenir-Heavy", size: 13))
                        .foregroundColor(Color("AccentGold"))
                }
                
                HStack {
                    Image(systemName: "person.3.fill")
                        .foregroundColor(Color("AccentGreen"))
                    Text("Full Party Bonus:")
                        .font(.custom("Avenir-Medium", size: 13))
                    Spacer()
                    Text("+\(partyBonus) Bond EXP each")
                        .font(.custom("Avenir-Heavy", size: 13))
                        .foregroundColor(Color("AccentGreen"))
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("CardBackground"))
            )
        }
    }
    
    // MARK: - Create Button
    
    private var createButton: some View {
        Button {
            createChallenge()
        } label: {
            HStack {
                Image(systemName: "flag.checkered")
                Text("Start Challenge")
                    .font(.custom("Avenir-Heavy", size: 16))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [Color("AccentGold"), Color("AccentOrange")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
        }
        .disabled(isCreating)
        .opacity(isCreating ? 0.6 : 1)
    }
    
    // MARK: - Create Logic
    
    private func createChallenge() {
        isCreating = true
        
        // Build the member list: self + party members
        var members: [(id: UUID, name: String)] = [(id: character.id, name: character.name)]
        for pm in character.partyMembers {
            members.append((id: pm.id, name: pm.name))
        }
        
        let challenge = PartyChallenge(
            challengeType: selectedType,
            targetCount: targetCount,
            durationDays: duration.rawValue,
            createdBy: character.id,
            members: members
        )
        
        modelContext.insert(challenge)
        
        ToastManager.shared.showReward(
            "Challenge Started!",
            subtitle: "\(selectedType.verb) \(targetCount) \(selectedType.rawValue.lowercased()) in \(duration.label.lowercased())",
            icon: "flag.checkered"
        )
        
        dismiss()
    }
}

