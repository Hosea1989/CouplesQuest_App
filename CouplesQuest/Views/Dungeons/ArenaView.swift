import SwiftUI
import SwiftData

struct ArenaView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var gameEngine: GameEngine
    @Query private var characters: [PlayerCharacter]
    @Query(sort: \ArenaMatch.createdAt, order: .reverse) private var recentMatches: [ArenaMatch]
    
    @State private var opponents: [FighterSnapshot] = []
    @State private var selectedOpponent: FighterSnapshot?
    @State private var selectedStance: BattleStance?
    @State private var showFightView = false
    @State private var showShop = false
    @State private var showStanceSelector = false
    @State private var showDefenseStancePicker = false
    @State private var isLoadingOpponents = false
    @State private var leaderboardEntries: [FighterSnapshot] = []
    @State private var isLoadingLeaderboard = false
    @State private var fightResult: PVPMatchResult?
    @State private var matchRewards: (arenaPoints: Int, gold: Int, exp: Int)?
    @State private var matchRatingChange: Int = 0
    @State private var isRevengeFight = false
    
    private var character: PlayerCharacter? { characters.first }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                profileCard
                
                if let char = character, !char.pendingRevengeIDs.isEmpty {
                    revengeSection
                }
                
                actionArea
                
                leaderboardSection
                
                recentMatchesSection
            }
            .padding(.vertical)
        }
        .fullScreenCover(isPresented: $showFightView) {
            if let opponent = selectedOpponent,
               let stance = selectedStance,
               let character = character {
                ArenaFightView(
                    character: character,
                    opponent: opponent,
                    attackerStance: stance,
                    isRevenge: isRevengeFight,
                    onComplete: { result, rewards, ratingChange in
                        handleFightComplete(result: result, rewards: rewards, ratingChange: ratingChange)
                    }
                )
            }
        }
        .sheet(isPresented: $showShop) {
            if let character = character {
                ArenaShopView(character: character)
            }
        }
        .sheet(isPresented: $showDefenseStancePicker) {
            defenseStanceSheet
        }
        .onAppear {
            character?.checkPVPFightReset()
            loadLeaderboard()
        }
    }
    
    // MARK: - Profile Card
    
    private var profileCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Season \(character?.arenaSeasonNumber ?? 1)")
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                    Text("The Colosseum")
                        .font(.custom("Avenir-Heavy", size: 22))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color("AccentGold"), Color("AccentOrange")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                Spacer()
                
                HStack(spacing: 12) {
                    if let pts = character?.arenaPoints {
                        HStack(spacing: 4) {
                            Image(systemName: "star.circle.fill")
                                .foregroundColor(Color("AccentGold"))
                                .font(.system(size: 14))
                            Text("\(pts)")
                                .font(.custom("Avenir-Heavy", size: 14))
                                .foregroundColor(Color("AccentGold"))
                        }
                    }
                    
                    Button { showShop = true } label: {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color("AccentGold"))
                            .padding(8)
                            .background(Color("CardBackground").opacity(0.8))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal)
            
            // Tier badge & rating
            VStack(spacing: 10) {
                let tier = character?.arenaTier ?? .bronze
                
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(tier.color).opacity(0.3), Color(tier.color).opacity(0.05)],
                                center: .center,
                                startRadius: 5,
                                endRadius: 50
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .stroke(Color(tier.color).opacity(0.4), lineWidth: 2)
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: tier.icon)
                        .font(.system(size: 40))
                        .foregroundColor(Color(tier.color))
                }
                
                Text(tier.rawValue)
                    .font(.custom("Avenir-Heavy", size: 20))
                    .foregroundColor(Color(tier.color))
                
                HStack(spacing: 6) {
                    Text("\(character?.arenaRating ?? 1000)")
                        .font(.custom("Avenir-Heavy", size: 28))
                        .foregroundColor(.primary)
                    
                    trendArrow
                }
                
                Text("Hero Might: \(character?.heroPower ?? 0)")
                    .font(.custom("Avenir-Heavy", size: 15))
                    .foregroundColor(Color("AccentGold"))
                
                if let title = character?.arenaTitle {
                    Text(title)
                        .font(.custom("Avenir-MediumOblique", size: 13))
                        .foregroundColor(.secondary)
                }
            }
            
            // W/L and streak
            HStack(spacing: 24) {
                VStack(spacing: 2) {
                    Text("\(character?.arenaWins ?? 0)W - \(character?.arenaLosses ?? 0)L")
                        .font(.custom("Avenir-Heavy", size: 15))
                        .foregroundColor(.primary)
                    Text("Record")
                        .font(.custom("Avenir-Medium", size: 11))
                        .foregroundColor(.secondary)
                }
                
                if let streak = character?.arenaStreak, streak > 0 {
                    VStack(spacing: 2) {
                        HStack(spacing: 4) {
                            if streak >= 3 {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 13))
                            }
                            Text("\(streak)")
                                .font(.custom("Avenir-Heavy", size: 15))
                                .foregroundColor(streak >= 3 ? .orange : .primary)
                        }
                        Text("Streak")
                            .font(.custom("Avenir-Medium", size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack(spacing: 2) {
                    Text("\(character?.remainingPVPFights ?? 5)/\(ArenaEngine.maxDailyFights)")
                        .font(.custom("Avenir-Heavy", size: 15))
                        .foregroundColor(.primary)
                    Text("Fights Left")
                        .font(.custom("Avenir-Medium", size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            // Defense stance button
            Button { showDefenseStancePicker = true } label: {
                let currentStance = BattleStance(rawValue: character?.arenaDefenseStance ?? "Fortress") ?? .fortress
                HStack(spacing: 8) {
                    Image(systemName: currentStance.icon)
                        .foregroundColor(Color(currentStance.color))
                    Text("Defense: \(currentStance.rawValue)")
                        .font(.custom("Avenir-Medium", size: 13))
                        .foregroundColor(.primary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color("CardBackground"))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color("CardBackground").opacity(0.5))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private var trendArrow: some View {
        Group {
            let last5 = Array(recentMatches.prefix(5))
            let wins = last5.filter { $0.won }.count
            let losses = last5.filter { !$0.won }.count
            
            if wins > losses {
                Image(systemName: "arrow.up")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.green)
            } else if losses > wins {
                Image(systemName: "arrow.down")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.red)
            } else {
                Image(systemName: "minus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Revenge Section
    
    private var revengeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Revenge Available!")
                    .font(.custom("Avenir-Heavy", size: 15))
                    .foregroundColor(.orange)
                
                Spacer()
                
                let count = character?.pendingRevengeIDs.count ?? 0
                if count > 1 {
                    Text("\(count)")
                        .font(.custom("Avenir-Heavy", size: 12))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.orange)
                        .clipShape(Capsule())
                }
            }
            
            Text("Someone defeated you! Challenge them back for +50% Arena Points. Free fight!")
                .font(.custom("Avenir-Medium", size: 12))
                .foregroundColor(.secondary)
            
            Button {
                // TODO: Load revenge opponent from Supabase and start fight
            } label: {
                HStack {
                    Image(systemName: "flame.fill")
                    Text("Seek Revenge")
                        .font(.custom("Avenir-Heavy", size: 14))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color("CardBackground").opacity(0.5))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    // MARK: - Action Area
    
    private var actionArea: some View {
        VStack(spacing: 16) {
            if opponents.isEmpty && !showStanceSelector {
                findOpponentButton
            } else if showStanceSelector, selectedOpponent != nil {
                stanceSelector
            } else {
                opponentPicker
            }
        }
        .padding(.horizontal)
    }
    
    private var findOpponentButton: some View {
        Button {
            findOpponents()
        } label: {
            HStack(spacing: 10) {
                if isLoadingOpponents {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "person.2.fill")
                }
                Text("Find Opponent")
                    .font(.custom("Avenir-Heavy", size: 17))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color("AccentGold"), Color("AccentOrange")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(14)
        }
        .disabled(isLoadingOpponents)
    }
    
    private var opponentPicker: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Choose Your Opponent")
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(.primary)
                Spacer()
                Button("Cancel") {
                    opponents = []
                    selectedOpponent = nil
                }
                .font(.custom("Avenir-Medium", size: 13))
                .foregroundColor(.secondary)
            }
            
            ForEach(opponents) { opponent in
                opponentCard(opponent)
            }
        }
    }
    
    private func opponentCard(_ opponent: FighterSnapshot) -> some View {
        Button {
            selectedOpponent = opponent
            showStanceSelector = true
        } label: {
            HStack(spacing: 12) {
                // Class icon
                let cls = CharacterClass(rawValue: opponent.className ?? "")
                Image(systemName: cls?.icon ?? "person.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color("AccentGold"))
                    .frame(width: 40, height: 40)
                    .background(Color("CardBackground"))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(opponent.name)
                            .font(.custom("Avenir-Heavy", size: 15))
                            .foregroundColor(.primary)
                        
                        Text("Lv.\(opponent.level)")
                            .font(.custom("Avenir-Medium", size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    if let className = opponent.className {
                        Text(className)
                            .font(.custom("Avenir-Medium", size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color("AccentGold"))
                        Text("\(opponent.heroPower)")
                            .font(.custom("Avenir-Heavy", size: 14))
                            .foregroundColor(Color("AccentGold"))
                    }
                    
                    HStack(spacing: 4) {
                        Text("\(opponent.rating)")
                            .font(.custom("Avenir-Medium", size: 12))
                            .foregroundColor(.secondary)
                        
                        trendIcon(for: opponent.recentTrend)
                    }
                }
            }
            .padding(12)
            .background(Color("CardBackground").opacity(0.7))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("AccentGold").opacity(0.15), lineWidth: 1)
            )
        }
    }
    
    private func trendIcon(for trend: String) -> some View {
        Group {
            switch trend {
            case "up":
                Image(systemName: "arrow.up")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.green)
            case "down":
                Image(systemName: "arrow.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.red)
            default:
                Image(systemName: "minus")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Stance Selector
    
    private var stanceSelector: some View {
        VStack(spacing: 14) {
            if let opponent = selectedOpponent {
                HStack {
                    Text("vs \(opponent.name)")
                        .font(.custom("Avenir-Heavy", size: 16))
                    Spacer()
                    Button("Back") {
                        showStanceSelector = false
                        selectedStance = nil
                    }
                    .font(.custom("Avenir-Medium", size: 13))
                    .foregroundColor(.secondary)
                }
            }
            
            Text("Choose Your Battle Stance")
                .font(.custom("Avenir-Heavy", size: 15))
                .foregroundColor(.primary)
            
            // RPS reminder
            HStack(spacing: 4) {
                Image(systemName: "flame.fill").foregroundColor(Color("StatStrength")).font(.system(size: 10))
                Image(systemName: "arrow.right").font(.system(size: 8)).foregroundColor(.secondary)
                Image(systemName: "scope").foregroundColor(Color("StatLuck")).font(.system(size: 10))
                Image(systemName: "arrow.right").font(.system(size: 8)).foregroundColor(.secondary)
                Image(systemName: "shield.fill").foregroundColor(Color("StatDefense")).font(.system(size: 10))
                Image(systemName: "arrow.right").font(.system(size: 8)).foregroundColor(.secondary)
                Image(systemName: "flame.fill").foregroundColor(Color("StatStrength")).font(.system(size: 10))
            }
            .padding(.vertical, 4)
            
            ForEach(BattleStance.allCases) { stance in
                Button {
                    selectedStance = stance
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: stance.icon)
                            .font(.system(size: 22))
                            .foregroundColor(Color(stance.color))
                            .frame(width: 36)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stance.rawValue)
                                .font(.custom("Avenir-Heavy", size: 15))
                                .foregroundColor(.primary)
                            Text(stance.subtitle)
                                .font(.custom("Avenir-Medium", size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedStance == stance {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(stance.color))
                        }
                    }
                    .padding(12)
                    .background(
                        selectedStance == stance
                            ? Color(stance.color).opacity(0.1)
                            : Color("CardBackground").opacity(0.5)
                    )
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                selectedStance == stance ? Color(stance.color).opacity(0.4) : Color.clear,
                                lineWidth: 1.5
                            )
                    )
                }
            }
            
            Button {
                beginFight()
            } label: {
                HStack {
                    Image(systemName: "bolt.fill")
                    Text("Fight!")
                        .font(.custom("Avenir-Heavy", size: 17))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    selectedStance != nil
                        ? LinearGradient(colors: [Color("AccentGold"), Color("AccentOrange")], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(12)
            }
            .disabled(selectedStance == nil)
        }
        .padding()
        .background(Color("CardBackground").opacity(0.3))
        .cornerRadius(14)
    }
    
    // MARK: - Leaderboard Section
    
    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "list.number")
                    .foregroundColor(Color("AccentGold"))
                Text("\(character?.arenaTier.rawValue ?? "Bronze") Leaderboard")
                    .font(.custom("Avenir-Heavy", size: 16))
                Spacer()
                
                if isLoadingLeaderboard {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            .padding(.horizontal)
            
            if leaderboardEntries.isEmpty && !isLoadingLeaderboard {
                Text("No fighters in this tier yet. Be the first!")
                    .font(.custom("Avenir-Medium", size: 13))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(Array(leaderboardEntries.prefix(20).enumerated()), id: \.element.id) { index, entry in
                    leaderboardRow(rank: index + 1, fighter: entry)
                }
            }
        }
        .padding(.vertical, 12)
        .background(Color("CardBackground").opacity(0.3))
        .cornerRadius(14)
        .padding(.horizontal)
    }
    
    private func leaderboardRow(rank: Int, fighter: FighterSnapshot) -> some View {
        let isMe = fighter.userID == character?.supabaseUserID
        
        return HStack(spacing: 10) {
            // Rank
            Group {
                switch rank {
                case 1:
                    Image(systemName: "medal.fill")
                        .foregroundColor(Color("AccentGold"))
                case 2:
                    Image(systemName: "medal.fill")
                        .foregroundColor(Color("StatWisdom"))
                case 3:
                    Image(systemName: "medal.fill")
                        .foregroundColor(Color("StatStrength"))
                default:
                    Text("#\(rank)")
                        .font(.custom("Avenir-Heavy", size: 13))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 28)
            
            // Class icon
            let cls = CharacterClass(rawValue: fighter.className ?? "")
            Image(systemName: cls?.icon ?? "person.fill")
                .font(.system(size: 14))
                .foregroundColor(isMe ? Color("AccentGold") : .secondary)
                .frame(width: 24)
            
            Text(fighter.name)
                .font(.custom(isMe ? "Avenir-Heavy" : "Avenir-Medium", size: 14))
                .foregroundColor(isMe ? Color("AccentGold") : .primary)
                .lineLimit(1)
            
            Spacer()
            
            // Hero Might
            HStack(spacing: 3) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 9))
                    .foregroundColor(Color("AccentGold").opacity(0.7))
                Text("\(fighter.heroPower)")
                    .font(.custom("Avenir-Medium", size: 12))
                    .foregroundColor(.secondary)
            }
            
            Text("\(fighter.rating)")
                .font(.custom("Avenir-Heavy", size: 13))
                .foregroundColor(.primary)
                .frame(width: 44, alignment: .trailing)
            
            trendIcon(for: fighter.recentTrend)
                .frame(width: 14)
            
            if fighter.streak >= 3 {
                Image(systemName: "flame.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(isMe ? Color("AccentGold").opacity(0.08) : Color.clear)
    }
    
    // MARK: - Recent Matches
    
    private var recentMatchesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Fights")
                .font(.custom("Avenir-Heavy", size: 16))
                .padding(.horizontal)
            
            if recentMatches.isEmpty {
                Text("No fights yet. Enter the Arena!")
                    .font(.custom("Avenir-Medium", size: 13))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            } else {
                ForEach(Array(recentMatches.prefix(5))) { match in
                    HStack(spacing: 10) {
                        Image(systemName: match.won ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(match.won ? .green : .red)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("vs \(match.opponentName)")
                                .font(.custom("Avenir-Medium", size: 13))
                                .foregroundColor(.primary)
                            Text("\(match.createdAt, style: .relative) ago")
                                .font(.custom("Avenir-Medium", size: 11))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(match.won ? "+\(match.ratingChange)" : "-\(match.ratingChange)")
                                .font(.custom("Avenir-Heavy", size: 13))
                                .foregroundColor(match.won ? .green : .red)
                            
                            if match.arenaPointsEarned > 0 {
                                Text("+\(match.arenaPointsEarned) AP")
                                    .font(.custom("Avenir-Medium", size: 11))
                                    .foregroundColor(Color("AccentGold"))
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(.vertical, 12)
        .background(Color("CardBackground").opacity(0.3))
        .cornerRadius(14)
        .padding(.horizontal)
    }
    
    // MARK: - Defense Stance Sheet
    
    private var defenseStanceSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Set your Defense Stance")
                    .font(.custom("Avenir-Heavy", size: 18))
                
                Text("This stance is used when other players attack you.")
                    .font(.custom("Avenir-Medium", size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                ForEach(BattleStance.allCases) { stance in
                    let isSelected = character?.arenaDefenseStance == stance.rawValue
                    Button {
                        character?.arenaDefenseStance = stance.rawValue
                        showDefenseStancePicker = false
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: stance.icon)
                                .font(.system(size: 24))
                                .foregroundColor(Color(stance.color))
                                .frame(width: 40)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(stance.rawValue)
                                    .font(.custom("Avenir-Heavy", size: 16))
                                    .foregroundColor(.primary)
                                Text(stance.subtitle)
                                    .font(.custom("Avenir-Medium", size: 12))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(stance.color))
                            }
                        }
                        .padding()
                        .background(isSelected ? Color(stance.color).opacity(0.1) : Color("CardBackground"))
                        .cornerRadius(12)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Defense Stance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showDefenseStancePicker = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    // MARK: - Actions
    
    private func findOpponents() {
        isLoadingOpponents = true
        guard let character = character else { return }
        
        // For now, generate mock opponents. Real implementation will call Supabase RPC.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let rating = character.arenaRating
            let mockNames = ["Valorheart", "Emberstrike", "Nightweaver", "Ironclad", "Stormcaller", "Shadowbane"]
            let mockClasses: [CharacterClass] = [.warrior, .mage, .archer, .berserker, .paladin, .sorcerer, .enchanter, .ranger, .trickster]
            
            self.opponents = (0..<3).map { i in
                let cls = mockClasses.randomElement()!
                let ratingOffset = [-150, -50, 100][i] + Int.random(in: -50...50)
                let opponentRating = max(100, rating + ratingOffset)
                let level = max(6, character.level + Int.random(in: -5...5))
                
                let baseStat = level + Int.random(in: 3...8)
                return FighterSnapshot(
                    userID: UUID().uuidString,
                    name: mockNames.randomElement()!,
                    level: level,
                    className: cls.rawValue,
                    strength: baseStat + (cls.primaryStat == .strength ? 5 : 0),
                    wisdom: baseStat + (cls.primaryStat == .wisdom ? 5 : 0),
                    charisma: baseStat + (cls.primaryStat == .charisma ? 5 : 0),
                    dexterity: baseStat + (cls.primaryStat == .dexterity ? 5 : 0),
                    luck: baseStat + (cls.primaryStat == .luck ? 5 : 0),
                    defense: baseStat + (cls.primaryStat == .defense ? 5 : 0),
                    weaponPrimaryBonus: Int.random(in: 3...10),
                    armorPrimaryBonus: Int.random(in: 2...8),
                    heroPower: Int.random(in: max(100, character.heroPower - 200)...character.heroPower + 200),
                    rating: opponentRating,
                    tier: ArenaTier.tier(for: opponentRating).rawValue,
                    defenseStance: BattleStance.allCases.randomElement()!.rawValue,
                    wins: Int.random(in: 0...50),
                    losses: Int.random(in: 0...40),
                    streak: Int.random(in: 0...5),
                    peakRating: opponentRating + Int.random(in: 0...200),
                    recentTrend: ["up", "down", "neutral"].randomElement()!,
                    pendingRevengeIDs: [],
                    arenaPoints: 0,
                    hasBond: Bool.random()
                )
            }
            self.isLoadingOpponents = false
        }
    }
    
    private func beginFight() {
        guard selectedStance != nil, selectedOpponent != nil else { return }
        showStanceSelector = false
        showFightView = true
    }
    
    private func handleFightComplete(result: PVPMatchResult, rewards: (arenaPoints: Int, gold: Int, exp: Int), ratingChange: Int) {
        guard let character = character, let opponent = selectedOpponent else { return }
        
        let defStance = BattleStance(rawValue: opponent.defenseStance) ?? .fortress
        
        // Record locally
        character.recordPVPFight(won: result.winnerIsAttacker, ratingChange: ratingChange)
        character.arenaPoints += rewards.arenaPoints
        character.gold += rewards.gold
        character.gainEXP(rewards.exp)
        
        // Save match record
        let match = ArenaMatch(
            characterID: character.id,
            opponentUserID: opponent.userID,
            opponentName: opponent.name,
            opponentLevel: opponent.level,
            opponentClass: opponent.className,
            opponentHeroPower: opponent.heroPower,
            opponentRating: opponent.rating,
            attackerStance: selectedStance!,
            defenderStance: defStance,
            result: result,
            ratingChange: ratingChange,
            ratingAfter: character.arenaRating,
            rewards: rewards,
            isRevenge: isRevengeFight
        )
        modelContext.insert(match)
        
        // Reset state
        opponents = []
        selectedOpponent = nil
        selectedStance = nil
        isRevengeFight = false
    }
    
    private func loadLeaderboard() {
        isLoadingLeaderboard = true
        // TODO: Real implementation calls fn_arena_leaderboard via Supabase
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.isLoadingLeaderboard = false
        }
    }
}
