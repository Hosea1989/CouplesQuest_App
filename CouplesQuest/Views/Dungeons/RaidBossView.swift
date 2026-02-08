import SwiftUI
import SwiftData

struct RaidBossView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var gameEngine: GameEngine
    @Query private var characters: [PlayerCharacter]
    @Query(sort: \WeeklyRaidBoss.weekStartDate, order: .reverse) private var bosses: [WeeklyRaidBoss]
    @Query private var bonds: [Bond]
    
    @State private var showAttackAnimation = false
    @State private var lastAttackDamage: Int?
    @State private var timerTick = 0
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var character: PlayerCharacter? {
        characters.first
    }
    
    private var bond: Bond? {
        bonds.first
    }
    
    private var currentBoss: WeeklyRaidBoss? {
        bosses.first(where: { !$0.isExpired || $0.isDefeated })
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let boss = currentBoss {
                    bossCard(boss: boss)
                    
                    if boss.isDefeated {
                        victorySection(boss: boss)
                    } else if boss.isExpired {
                        expiredSection(boss: boss)
                    } else {
                        attackSection(boss: boss)
                    }
                    
                    attackLogSection(boss: boss)
                } else {
                    noBossView
                }
            }
            .padding(.vertical)
        }
        .onAppear {
            ensureBossExists()
        }
        .onReceive(timer) { _ in
            timerTick += 1
        }
    }
    
    // MARK: - Boss Card
    
    @ViewBuilder
    private func bossCard(boss: WeeklyRaidBoss) -> some View {
        VStack(spacing: 16) {
            // Boss Icon
            ZStack {
                Circle()
                    .fill(
                        boss.isDefeated ?
                        Color("AccentGreen").opacity(0.2) :
                        Color("DifficultyHard").opacity(0.2)
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: boss.icon)
                    .font(.system(size: 45))
                    .foregroundColor(boss.isDefeated ? Color("AccentGreen") : Color("DifficultyHard"))
                    .scaleEffect(showAttackAnimation ? 0.85 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: showAttackAnimation)
            }
            
            // Boss Name & Tier
            VStack(spacing: 6) {
                Text(boss.name)
                    .font(.custom("Avenir-Heavy", size: 24))
                
                HStack(spacing: 6) {
                    Text("Tier \(boss.tier)")
                        .font(.custom("Avenir-Heavy", size: 12))
                        .foregroundColor(Color("DifficultyHard"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color("DifficultyHard").opacity(0.2)))
                    
                    Text("Weekly Raid Boss")
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            // Description
            Text(boss.bossDescription)
                .font(.custom("Avenir-Medium", size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // HP Bar
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(boss.isDefeated ? Color("AccentGreen") : .red)
                        .font(.caption)
                    Text(boss.isDefeated ? "DEFEATED" : "\(boss.currentHP) / \(boss.maxHP) HP")
                        .font(.custom("Avenir-Heavy", size: 14))
                        .foregroundColor(boss.isDefeated ? Color("AccentGreen") : .primary)
                    Spacer()
                    Text("\(Int(boss.hpPercentage * 100))%")
                        .font(.custom("Avenir-Heavy", size: 14))
                        .foregroundColor(.secondary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.secondary.opacity(0.2))
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                boss.isDefeated ?
                                Color("AccentGreen") :
                                (boss.hpPercentage > 0.5 ? Color.red : Color.red.opacity(0.7))
                            )
                            .frame(width: geometry.size.width * boss.hpPercentage)
                    }
                }
                .frame(height: 12)
            }
            .padding(.horizontal)
            
            // Timer
            if !boss.isDefeated && !boss.isExpired {
                let _ = timerTick // Force refresh
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                        .foregroundColor(Color("AccentGold"))
                    Text("Time Remaining: \(formatTimeRemaining(boss.timeRemaining))")
                        .font(.custom("Avenir-Medium", size: 13))
                        .foregroundColor(.secondary)
                }
            }
            
            // Damage popup
            if let damage = lastAttackDamage {
                Text("-\(damage) DMG")
                    .font(.custom("Avenir-Heavy", size: 20))
                    .foregroundColor(Color("DifficultyHard"))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal)
    }
    
    // MARK: - Attack Section
    
    @ViewBuilder
    private func attackSection(boss: WeeklyRaidBoss) -> some View {
        if let character = character {
            let hasPartner = character.hasPartner
            let attacksToday = boss.attacksToday(by: character.id)
            let atCap = boss.hasReachedDailyCap(playerID: character.id)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Your Attacks")
                        .font(.custom("Avenir-Heavy", size: 18))
                    Spacer()
                    Text("\(attacksToday)/\(WeeklyRaidBoss.dailyAttackCap) today")
                        .font(.custom("Avenir-Medium", size: 14))
                        .foregroundColor(atCap ? .red : .secondary)
                }
                
                if !hasPartner {
                    HStack(spacing: 8) {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(Color("AccentPink"))
                        Text("Link a partner to team up against the raid boss!")
                            .font(.custom("Avenir-Medium", size: 13))
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color("AccentPink").opacity(0.1)))
                }
                
                let damage = WeeklyRaidBoss.calculateDamage(for: character)
                
                HStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text("Your Power")
                            .font(.custom("Avenir-Medium", size: 12))
                            .foregroundColor(.secondary)
                        Text("\(damage)")
                            .font(.custom("Avenir-Heavy", size: 24))
                            .foregroundColor(Color("AccentGold"))
                    }
                    
                    Spacer()
                    
                    Button {
                        performAttack(boss: boss, character: character, damage: damage)
                    } label: {
                        HStack {
                            Image(systemName: "bolt.fill")
                            Text(atCap ? "Daily Limit Reached" : "Attack!")
                        }
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(atCap ? .secondary : .black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(
                            atCap ?
                            LinearGradient(colors: [Color.gray, Color.gray], startPoint: .leading, endPoint: .trailing) :
                            LinearGradient(colors: [Color("AccentGold"), Color("AccentOrange")], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(atCap)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("CardBackground"))
            )
            .padding(.horizontal)
        }
    }
    
    // MARK: - Victory Section
    
    @ViewBuilder
    private func victorySection(boss: WeeklyRaidBoss) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 40))
                .foregroundColor(Color("AccentGold"))
            
            Text("Victory!")
                .font(.custom("Avenir-Heavy", size: 24))
                .foregroundColor(Color("AccentGold"))
            
            Text("\(boss.name) has been defeated!")
                .font(.custom("Avenir-Medium", size: 16))
                .foregroundColor(.secondary)
            
            // Rewards
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("+\(WeeklyRaidBoss.expReward(tier: boss.tier)) EXP")
                }
                .font(.custom("Avenir-Heavy", size: 16))
                .foregroundColor(Color("AccentGold"))
                
                HStack {
                    Image(systemName: "dollarsign.circle")
                    Text("+\(WeeklyRaidBoss.goldReward(tier: boss.tier)) Gold")
                }
                .font(.custom("Avenir-Medium", size: 14))
                .foregroundColor(.secondary)
                
                if character?.hasPartner == true {
                    HStack {
                        Image(systemName: "heart.fill")
                        Text("+\(WeeklyRaidBoss.bondExpReward(tier: boss.tier)) Bond EXP")
                    }
                    .font(.custom("Avenir-Medium", size: 14))
                    .foregroundColor(Color("AccentPink"))
                }
            }
            
            if !boss.rewardsClaimed, let character = character {
                Button {
                    gameEngine.claimRaidBossRewards(
                        boss: boss,
                        character: character,
                        bond: bond,
                        context: modelContext
                    )
                } label: {
                    HStack {
                        Image(systemName: "gift.fill")
                        Text("Claim Rewards")
                    }
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(colors: [Color("AccentGold"), Color("AccentOrange")], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            } else {
                Text("Rewards Claimed — New boss arrives Monday!")
                    .font(.custom("Avenir-Medium", size: 13))
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
        .padding(.horizontal)
    }
    
    // MARK: - Expired Section
    
    @ViewBuilder
    private func expiredSection(boss: WeeklyRaidBoss) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "xmark.shield.fill")
                .font(.system(size: 36))
                .foregroundColor(.secondary)
            
            Text("The boss escaped!")
                .font(.custom("Avenir-Heavy", size: 20))
            
            Text("Time ran out. A new raid boss will appear next Monday.")
                .font(.custom("Avenir-Medium", size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
        .padding(.horizontal)
    }
    
    // MARK: - Attack Log
    
    @ViewBuilder
    private func attackLogSection(boss: WeeklyRaidBoss) -> some View {
        if !boss.attackLog.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Attack Log")
                    .font(.custom("Avenir-Heavy", size: 18))
                
                ForEach(boss.attackLog.suffix(10).reversed()) { attack in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color("DifficultyHard").opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "bolt.fill")
                                .font(.caption)
                                .foregroundColor(Color("DifficultyHard"))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(attack.playerName) dealt \(attack.damage) damage")
                                .font(.custom("Avenir-Heavy", size: 13))
                            Text(attack.sourceDescription)
                                .font(.custom("Avenir-Medium", size: 11))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(attack.timestamp, style: .relative)
                            .font(.custom("Avenir-Medium", size: 10))
                            .foregroundColor(.secondary)
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
    }
    
    // MARK: - No Boss View
    
    private var noBossView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "flame.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No Raid Boss Active")
                .font(.custom("Avenir-Heavy", size: 20))
            Text("A new raid boss will appear soon.")
                .font(.custom("Avenir-Medium", size: 14))
                .foregroundColor(.secondary)
            Spacer()
        }
    }
    
    // MARK: - Actions
    
    private func ensureBossExists() {
        guard let character = character else { return }
        
        let weekStart = WeeklyRaidBoss.currentWeekStart()
        
        // Check if we already have a boss for this week
        let existingBoss = bosses.first(where: { boss in
            Calendar.current.isDate(boss.weekStartDate, inSameDayAs: weekStart)
        })
        
        if existingBoss == nil {
            let avgLevel = character.level
            let tier = WeeklyRaidBoss.tierForLevel(avgLevel)
            let weekEnd = WeeklyRaidBoss.currentWeekEnd()
            let newBoss = WeeklyRaidBoss.generate(tier: tier, weekStart: weekStart, weekEnd: weekEnd)
            modelContext.insert(newBoss)
        }
    }
    
    private func performAttack(boss: WeeklyRaidBoss, character: PlayerCharacter, damage: Int) {
        let result = gameEngine.attackRaidBoss(
            boss: boss,
            character: character,
            taskDescription: "Manual raid attack"
        )
        
        if let result = result {
            withAnimation(.easeInOut(duration: 0.15)) {
                showAttackAnimation = true
                lastAttackDamage = result.damage
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    showAttackAnimation = false
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    lastAttackDamage = nil
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func formatTimeRemaining(_ interval: TimeInterval) -> String {
        let days = Int(interval) / 86400
        let hours = (Int(interval) % 86400) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

#Preview {
    RaidBossView()
        .environmentObject(GameEngine())
}
