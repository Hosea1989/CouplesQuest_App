import SwiftUI
import SwiftData

struct RaidBossView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var gameEngine: GameEngine
    @Query private var characters: [PlayerCharacter]
    @Query(sort: \WeeklyRaidBoss.weekStartDate, order: .reverse) private var bosses: [WeeklyRaidBoss]
    @Query private var bonds: [Bond]
    
    @State private var showAttackAnimation = false
    @State private var shakeOffset: CGFloat = 0
    @State private var lastAttackDamage: Int?
    @State private var timerTick = 0
    @State private var communityAttacks: [CommunityRaidAttackDTO] = []
    @State private var isLoadingCommunity = false
    @State private var showVictoryFlash = false
    @State private var showJoinTooltip = false
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var character: PlayerCharacter? { characters.first }
    private var bond: Bond? { bonds.first }
    
    private var currentBoss: WeeklyRaidBoss? {
        bosses.first(where: { !$0.isExpired || $0.isDefeated })
    }
    
    private var mostRecentBoss: WeeklyRaidBoss? {
        bosses.first
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    if let boss = currentBoss {
                        bossScene(boss: boss)
                        
                        VStack(spacing: 16) {
                            bossInfoCard(boss: boss)
                            
                            if let modName = boss.modifierName, !modName.isEmpty {
                                modifierCard(name: modName, description: boss.modifierDescription ?? "")
                            }
                            
                            if boss.isDefeated {
                                victorySection(boss: boss)
                            } else if boss.isExpired {
                                expiredSection(boss: boss)
                            }
                            
                            contributionCard(boss: boss)
                            
                            if !boss.isDefeated && !boss.isExpired {
                                lootPreviewCard(boss: boss)
                            }
                            
                            attackLogSection(boss: boss)
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                    } else {
                        noBossView
                    }
                }
            }
            
            if currentBoss?.isDefeated == true {
                CelebrationFloatingParticlesView()
                    .ignoresSafeArea()
                    .opacity(0.25)
                    .allowsHitTesting(false)
                CelebrationConfettiOverlay()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea(.container, edges: .top)
        .onAppear {
            ensureBossExists()
            loadCommunityData()
        }
        .onReceive(timer) { _ in
            timerTick += 1
        }
    }
    
    // MARK: - Boss Scene (Background + Sprite + HP Bar)
    
    @ViewBuilder
    private func bossScene(boss: WeeklyRaidBoss) -> some View {
        let bgName = boss.backgroundImage.isEmpty ? "raidboss-bg-volcano" : boss.backgroundImage
        let spriteName = boss.spriteImage.isEmpty ? "raidboss-beast" : boss.spriteImage
        
        ZStack(alignment: .bottom) {
            GeometryReader { geo in
                Image(bgName)
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            
            LinearGradient(
                colors: [.clear, .clear, Color("CardBackground").opacity(0.6), Color("CardBackground")],
                startPoint: .top,
                endPoint: .bottom
            )
            
            VStack(spacing: 8) {
                Spacer()
                
                VStack(spacing: 4) {
                    Text(boss.name)
                        .font(.custom("Avenir-Heavy", size: 24))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.8), radius: 6, x: 0, y: 2)
                    
                    HStack(spacing: 6) {
                        Image(systemName: WeeklyRaidBoss.elementIcon(for: boss.element))
                            .font(.system(size: 12))
                        Text(boss.element)
                            .font(.custom("Avenir-Heavy", size: 12))
                    }
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.black.opacity(0.4)))
                }
                
                Image(spriteName)
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 180, height: 180)
                    .shadow(color: boss.isDefeated ? Color("AccentGreen").opacity(0.6) : Color("DifficultyHard").opacity(0.4), radius: 20)
                    .offset(x: shakeOffset)
                    .opacity(boss.isDefeated ? 0.5 : 1.0)
                    .overlay {
                        if boss.isDefeated {
                            Image(systemName: "xmark")
                                .font(.system(size: 60, weight: .bold))
                                .foregroundColor(Color("AccentGreen"))
                                .shadow(color: .black, radius: 4)
                        }
                    }
                
                phaseIndicator(boss: boss)
                    .padding(.horizontal, 30)
                
                communityHPBar(boss: boss)
                    .padding(.horizontal, 20)
                
                if !boss.hasJoinedRaid && boss.isActive {
                    joinRaidButton(boss: boss)
                        .padding(.horizontal, 40)
                } else if boss.hasJoinedRaid && boss.isActive {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 10))
                        Text("Joined")
                            .font(.custom("Avenir-Heavy", size: 11))
                    }
                    .foregroundColor(Color("AccentGreen"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color("AccentGreen").opacity(0.15)))
                }
                
                Spacer().frame(height: 12)
            }
            
            if let damage = lastAttackDamage {
                Text("-\(damage)")
                    .font(.custom("Avenir-Heavy", size: 36))
                    .foregroundColor(.red)
                    .shadow(color: .black, radius: 3)
                    .offset(y: -160)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            if showVictoryFlash {
                Color("AccentGold").opacity(0.3)
                    .transition(.opacity)
            }
        }
        .frame(height: 440)
        .clipped()
    }
    
    // MARK: - Community HP Bar
    
    @ViewBuilder
    private func communityHPBar(boss: WeeklyRaidBoss) -> some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.5))
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(hpGradient(percentage: boss.hpPercentage))
                        .frame(width: geometry.size.width * boss.hpPercentage)
                        .animation(.easeInOut(duration: 0.4), value: boss.hpPercentage)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    
                    HStack {
                        Text("\(boss.phase.displayName) PHASE")
                            .font(.custom("Avenir-Heavy", size: 10))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Spacer()
                        
                        Text(boss.isDefeated ? "DEFEATED" : "\(formatNumber(boss.currentHP)) / \(formatNumber(boss.phaseMaxHP))")
                            .font(.custom("Avenir-Heavy", size: 11))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 10)
                }
            }
            .frame(height: 24)
            
            HStack {
                if !boss.isDefeated && !boss.isExpired {
                    let _ = timerTick
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10))
                        Text(formatTimeRemaining(boss.timeRemaining))
                            .font(.custom("Avenir-Medium", size: 11))
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Text("\(Int(boss.hpPercentage * 100))%")
                    .font(.custom("Avenir-Heavy", size: 12))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
    
    private func hpGradient(percentage: Double) -> LinearGradient {
        let colors: [Color]
        if percentage > 0.6 {
            colors = [Color.green, Color.green.opacity(0.8)]
        } else if percentage > 0.3 {
            colors = [Color.yellow, Color.orange]
        } else {
            colors = [Color.red, Color.red.opacity(0.7)]
        }
        return LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
    }
    
    // MARK: - Boss Info Card
    
    @ViewBuilder
    private func bossInfoCard(boss: WeeklyRaidBoss) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Text("Tier \(boss.tier)")
                    .font(.custom("Avenir-Heavy", size: 13))
                    .foregroundColor(Color("DifficultyHard"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color("DifficultyHard").opacity(0.2)))
                
                Text("Community Raid Boss")
                    .font(.custom("Avenir-Medium", size: 13))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 8) {
                    if boss.totalParticipants > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 10))
                            Text("\(boss.totalParticipants)")
                                .font(.custom("Avenir-Heavy", size: 11))
                        }
                        .foregroundColor(Color("AccentPink"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color("AccentPink").opacity(0.15)))
                    }
                    
                    if boss.totalParties > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 10))
                            Text("\(boss.totalParties)")
                                .font(.custom("Avenir-Heavy", size: 11))
                        }
                        .foregroundColor(Color("AccentPurple"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color("AccentPurple").opacity(0.15)))
                    }
                }
            }
            
            Text(boss.bossDescription)
                .font(.custom("Avenir-Medium", size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider().opacity(0.3)
            
            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Image(systemName: WeeklyRaidBoss.elementIcon(for: boss.element))
                        .font(.system(size: 16))
                        .foregroundColor(Color("AccentOrange"))
                    Text(boss.element)
                        .font(.custom("Avenir-Heavy", size: 14))
                    Text("Element")
                        .font(.custom("Avenir-Medium", size: 10))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 1, height: 40)
                
                VStack(spacing: 4) {
                    Image(systemName: "target")
                        .font(.system(size: 16))
                        .foregroundColor(Color("AccentGreen"))
                    Text(boss.weakness)
                        .font(.custom("Avenir-Heavy", size: 14))
                    Text("Weakness")
                        .font(.custom("Avenir-Medium", size: 10))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 1, height: 40)
                
                VStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color("DifficultyHard"))
                    Text(formatNumber(boss.maxHP))
                        .font(.custom("Avenir-Heavy", size: 14))
                    Text("Total HP")
                        .font(.custom("Avenir-Medium", size: 10))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            
            Divider().opacity(0.3)
            
            HStack(spacing: 0) {
                let _ = timerTick
                VStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color("AccentGold"))
                    Text(boss.isDefeated ? "Defeated" : (boss.isExpired ? "Expired" : formatTimeRemaining(boss.timeRemaining)))
                        .font(.custom("Avenir-Heavy", size: 14))
                    Text("Time Left")
                        .font(.custom("Avenir-Medium", size: 10))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 1, height: 40)
                
                VStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color("AccentPurple"))
                    Text(formatNumber(boss.totalDamageDealt))
                        .font(.custom("Avenir-Heavy", size: 14))
                    Text("Total Damage")
                        .font(.custom("Avenir-Medium", size: 10))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 1, height: 40)
                
                VStack(spacing: 4) {
                    Image(systemName: "heart.slash.fill")
                        .font(.system(size: 16))
                        .foregroundColor(boss.hpPercentage > 0.3 ? Color("AccentGreen") : Color("DifficultyHard"))
                    Text(formatNumber(max(0, boss.currentHP)))
                        .font(.custom("Avenir-Heavy", size: 14))
                    Text("Phase HP")
                        .font(.custom("Avenir-Medium", size: 10))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
        .padding(.horizontal)
    }
    
    // MARK: - Modifier Card
    
    @ViewBuilder
    private func modifierCard(name: String, description: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundColor(Color("AccentOrange"))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Boss Modifier: \(name)")
                    .font(.custom("Avenir-Heavy", size: 13))
                    .foregroundColor(Color("AccentOrange"))
                Text(description)
                    .font(.custom("Avenir-Medium", size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("AccentOrange").opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color("AccentOrange").opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
    
    // MARK: - Your Contribution
    
    @ViewBuilder
    private func contributionCard(boss: WeeklyRaidBoss) -> some View {
        if let character = character {
            let myDamage = boss.totalPlayerDamage(by: character.id)
            let contribution = boss.totalDamageDealt > 0 ? Double(myDamage) / Double(boss.totalDamageDealt) * 100 : 0
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(Color("AccentGold"))
                    Text("Your Contribution")
                        .font(.custom("Avenir-Heavy", size: 16))
                    Spacer()
                    Text(String(format: "%.1f%%", contribution))
                        .font(.custom("Avenir-Heavy", size: 14))
                        .foregroundColor(Color("AccentGold"))
                }
                
                HStack(spacing: 12) {
                    statBubble(
                        icon: "flame.fill",
                        value: formatNumber(myDamage),
                        label: "Your Damage",
                        color: "AccentOrange"
                    )
                    statBubble(
                        icon: "person.3.fill",
                        value: "\(boss.totalParticipants)",
                        label: "Warriors",
                        color: "AccentPink"
                    )
                }
                
                let myAttacks = boss.attackLog.filter { $0.playerID == character.id }
                if !myAttacks.isEmpty {
                    Divider().opacity(0.3)
                    
                    Text("Damage Breakdown")
                        .font(.custom("Avenir-Heavy", size: 13))
                        .foregroundColor(.secondary)
                    
                    let grouped = Dictionary(grouping: myAttacks, by: { $0.sourceType })
                    ForEach([RaidActivityType.task, .habit, .dungeon, .mission], id: \.rawValue) { type in
                        let attacks = grouped[type.rawValue] ?? []
                        if !attacks.isEmpty {
                            let dmg = attacks.reduce(0) { $0 + $1.damage }
                            HStack(spacing: 10) {
                                Image(systemName: type.icon)
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(type.color))
                                    .frame(width: 20)
                                
                                Text(type.displayName)
                                    .font(.custom("Avenir-Medium", size: 13))
                                
                                Spacer()
                                
                                Text("\(attacks.count) hits")
                                    .font(.custom("Avenir-Medium", size: 11))
                                    .foregroundColor(.secondary)
                                
                                Text("\(formatNumber(dmg)) dmg")
                                    .font(.custom("Avenir-Heavy", size: 13))
                                    .foregroundColor(Color(type.color))
                                    .frame(width: 70, alignment: .trailing)
                            }
                        }
                    }
                }
                
                if !communityAttacks.isEmpty {
                    Divider().opacity(0.3)
                    
                    Text("Top Attackers")
                        .font(.custom("Avenir-Heavy", size: 13))
                        .foregroundColor(.secondary)
                    
                    let topAttackers = aggregateTopAttackers(from: communityAttacks, limit: 5)
                    ForEach(Array(topAttackers.enumerated()), id: \.offset) { index, attacker in
                        HStack(spacing: 8) {
                            Text("#\(index + 1)")
                                .font(.custom("Avenir-Heavy", size: 12))
                                .foregroundColor(index == 0 ? Color("AccentGold") : .secondary)
                                .frame(width: 24)
                            
                            Text(attacker.name)
                                .font(.custom("Avenir-Medium", size: 13))
                            
                            Spacer()
                            
                            Text("\(formatNumber(attacker.totalDamage)) dmg")
                                .font(.custom("Avenir-Heavy", size: 12))
                                .foregroundColor(Color("DifficultyHard"))
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("CardBackground"))
            )
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private func statBubble(icon: String, value: String, label: String, color: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color(color))
            Text(value)
                .font(.custom("Avenir-Heavy", size: 16))
            Text(label)
                .font(.custom("Avenir-Medium", size: 10))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(color).opacity(0.08)))
    }
    
    // MARK: - Loot Preview Card
    
    @ViewBuilder
    private func lootPreviewCard(boss: WeeklyRaidBoss) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "gift.fill")
                    .foregroundColor(Color("AccentGold"))
                Text("Raid Rewards")
                    .font(.custom("Avenir-Heavy", size: 16))
                Spacer()
                Text("Contribution-based")
                    .font(.custom("Avenir-Medium", size: 11))
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Participation (Everyone)")
                    .font(.custom("Avenir-Heavy", size: 12))
                    .foregroundColor(.secondary)
                HStack(spacing: 16) {
                    lootItem(icon: "sparkles", label: "Base EXP", color: "AccentGold")
                    lootItemGold(label: "Base Gold")
                    lootItem(icon: "cross.vial.fill", label: "Consumable", color: "AccentGreen")
                }
            }
            
            Divider().opacity(0.3)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Contribution Bonus (Scaled)")
                    .font(.custom("Avenir-Heavy", size: 12))
                    .foregroundColor(.secondary)
                HStack(spacing: 16) {
                    lootItem(icon: "sparkles", label: "Bonus EXP", color: "AccentGold")
                    lootItemGold(label: "Bonus Gold")
                }
                HStack(spacing: 16) {
                    lootItem(icon: "shield.fill", label: "Equipment chance", color: "RarityRare")
                    lootItem(icon: "rectangle.portrait.fill", label: "Boss card", color: "AccentPurple")
                }
                if character?.hasPartner == true {
                    lootItem(icon: "heart.fill", label: "Bond EXP", color: "AccentPink")
                }
            }
            
            Divider().opacity(0.3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Phase Bonus")
                    .font(.custom("Avenir-Heavy", size: 12))
                    .foregroundColor(.secondary)
                HStack(spacing: 12) {
                    ForEach(RaidBossPhase.allCases, id: \.rawValue) { phase in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(phase.phaseColor).opacity(boss.currentPhase >= phase.rawValue ? 1.0 : 0.3))
                                .frame(width: 8, height: 8)
                            Text("\(phase.displayName): x\(String(format: "%.1f", phase.hpMultiplier))")
                                .font(.custom("Avenir-Medium", size: 11))
                                .foregroundColor(boss.currentPhase >= phase.rawValue ? Color(phase.phaseColor) : .secondary.opacity(0.5))
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func lootItem(icon: String, label: String, color: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(Color(color))
            Text(label)
                .font(.custom("Avenir-Medium", size: 12))
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private func lootItemGold(label: String) -> some View {
        HStack(spacing: 6) {
            GoldCoinIcon(size: 14)
            Text(label)
                .font(.custom("Avenir-Medium", size: 12))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Phase Indicator
    
    @ViewBuilder
    private func phaseIndicator(boss: WeeklyRaidBoss) -> some View {
        HStack(spacing: 0) {
            ForEach(RaidBossPhase.allCases, id: \.rawValue) { phase in
                let isCompleted = boss.currentPhase > phase.rawValue || (boss.currentPhase == phase.rawValue && boss.currentHP <= 0 && phase.rawValue == 3)
                let isActive = boss.currentPhase == phase.rawValue && !boss.isDefeated
                let isLocked = boss.currentPhase < phase.rawValue
                
                HStack(spacing: 4) {
                    if isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(phase.phaseColor))
                    } else if isActive {
                        Circle()
                            .fill(Color(phase.phaseColor))
                            .frame(width: 8, height: 8)
                            .shadow(color: Color(phase.phaseColor).opacity(0.8), radius: 4)
                    } else {
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                    
                    Text(phase.displayName)
                        .font(.custom("Avenir-Heavy", size: 11))
                        .foregroundColor(isLocked ? .white.opacity(0.3) : .white.opacity(0.9))
                }
                .frame(maxWidth: .infinity)
                
                if phase.rawValue < 3 {
                    Rectangle()
                        .fill(boss.currentPhase > phase.rawValue ? Color(phase.phaseColor).opacity(0.6) : Color.white.opacity(0.2))
                        .frame(height: 2)
                        .frame(maxWidth: 20)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.4))
        )
    }
    
    // MARK: - Join Raid Button (Inline)
    
    @ViewBuilder
    private func joinRaidButton(boss: WeeklyRaidBoss) -> some View {
        VStack(spacing: 4) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    boss.hasJoinedRaid = true
                }
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                AudioManager.shared.play(.dutyComplete)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                    Text("Join Raid")
                    
                    Button {
                        showJoinTooltip.toggle()
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 12))
                    }
                }
                .font(.custom("Avenir-Heavy", size: 14))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [Color("AccentGold"), Color("AccentOrange")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .overlay(alignment: .top) {
                if showJoinTooltip {
                    Text("Once you join, completing tasks, habits, dungeons, and missions will passively deal damage to the boss.")
                        .font(.custom("Avenir-Medium", size: 11))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.6)))
                        .transition(.scale.combined(with: .opacity))
                        .offset(y: -50)
                }
            }
        }
    }
    
    // MARK: - Victory Section
    
    @ViewBuilder
    private func victorySection(boss: WeeklyRaidBoss) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color("AccentGold").opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 15,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                
                Image(systemName: "trophy.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color("AccentGold"))
                    .symbolEffect(.bounce)
            }
            
            Text("Victory!")
                .font(.custom("Avenir-Heavy", size: 28))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color("AccentGold"), Color("AccentOrange")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text("The community defeated \(boss.name) at Phase \(boss.currentPhase)!")
                .font(.custom("Avenir-Medium", size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let character = character {
                let myDamage = boss.totalPlayerDamage(by: character.id)
                let contribution = boss.totalDamageDealt > 0 ? Double(myDamage) / Double(boss.totalDamageDealt) : 0
                
                VStack(spacing: 8) {
                    Text("Your Contribution: \(String(format: "%.1f%%", contribution * 100))")
                        .font(.custom("Avenir-Heavy", size: 14))
                        .foregroundColor(Color("AccentGold"))
                    
                    HStack(spacing: 16) {
                        lootItem(icon: "sparkles", label: "EXP + Bonus", color: "AccentGold")
                        lootItemGold(label: "Gold + Bonus")
                    }
                    
                    HStack(spacing: 16) {
                        lootItem(icon: "shield.fill", label: "Equipment chance", color: "RarityRare")
                        lootItem(icon: "rectangle.portrait.fill", label: "Boss card", color: "AccentPurple")
                    }
                    
                    if bond != nil {
                        lootItem(icon: "heart.fill", label: "Bond EXP", color: "AccentPink")
                    }
                }
            }
            
            claimRewardsButton(boss: boss)
            
            nextBossCountdown(boss: boss)
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
            
            Text("The boss has retreated to its den.")
                .font(.custom("Avenir-Heavy", size: 20))
                .multilineTextAlignment(.center)
            
            Text("Time ran out at Phase \(boss.currentPhase). You can still claim participation rewards.")
                .font(.custom("Avenir-Medium", size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if boss.hasJoinedRaid {
                claimRewardsButton(boss: boss)
            }
            
            nextBossCountdown(boss: boss)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
        .padding(.horizontal)
    }
    
    // MARK: - Claim Rewards Button (Shared)
    
    @ViewBuilder
    private func claimRewardsButton(boss: WeeklyRaidBoss) -> some View {
        if !boss.rewardsClaimed, let character = character, boss.hasJoinedRaid {
            Button {
                gameEngine.claimRaidBossRewards(
                    boss: boss,
                    character: character,
                    bond: bond,
                    context: modelContext
                )
                AudioManager.shared.play(.claimReward)
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
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
        } else if boss.rewardsClaimed {
            Text("Rewards Claimed")
                .font(.custom("Avenir-Medium", size: 13))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Next Boss Countdown
    
    @ViewBuilder
    private func nextBossCountdown(boss: WeeklyRaidBoss) -> some View {
        let _ = timerTick
        if let nextDate = boss.nextBossDate {
            let remaining = nextDate.timeIntervalSince(Date())
            if remaining > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "hourglass")
                        .font(.system(size: 12))
                    Text("Next raid boss appears in \(formatTimeRemaining(remaining))")
                        .font(.custom("Avenir-Medium", size: 13))
                }
                .foregroundColor(Color("AccentGold"))
                .padding(.top, 4)
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                    Text("A new raid boss is available!")
                        .font(.custom("Avenir-Medium", size: 13))
                }
                .foregroundColor(Color("AccentGreen"))
                .padding(.top, 4)
            }
        }
    }
    
    // MARK: - Attack Log
    
    @ViewBuilder
    private func attackLogSection(boss: WeeklyRaidBoss) -> some View {
        let attacks = communityAttacks.isEmpty ? boss.attackLog.suffix(10).reversed().map { attack in
            CommunityRaidAttackDTO(
                id: attack.id.uuidString,
                bossId: boss.id.uuidString,
                userId: attack.playerID.uuidString,
                playerName: attack.playerName,
                damage: attack.damage,
                sourceDescription: attack.sourceDescription,
                partyId: nil,
                createdAt: ISO8601DateFormatter().string(from: attack.timestamp)
            )
        } : Array(communityAttacks.prefix(15))
        
        if !attacks.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "bolt.horizontal.fill")
                        .foregroundColor(Color("DifficultyHard"))
                    Text("Live Attack Feed")
                        .font(.custom("Avenir-Heavy", size: 18))
                    Spacer()
                }
                
                ForEach(attacks, id: \.id) { attack in
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
                        
                        if let dateStr = attack.createdAt,
                           let date = ISO8601DateFormatter().date(from: dateStr) {
                            Text(date, style: .relative)
                                .font(.custom("Avenir-Medium", size: 10))
                                .foregroundColor(.secondary)
                        }
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
                .frame(height: 100)
            Image(systemName: "flame.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No Raid Boss Active")
                .font(.custom("Avenir-Heavy", size: 20))
            
            if let recent = mostRecentBoss, let nextDate = recent.nextBossDate {
                let _ = timerTick
                let remaining = nextDate.timeIntervalSince(Date())
                if remaining > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "hourglass")
                        Text("Next boss appears in \(formatTimeRemaining(remaining))")
                            .font(.custom("Avenir-Medium", size: 14))
                    }
                    .foregroundColor(Color("AccentGold"))
                } else {
                    Text("A new raid boss should appear any moment now!")
                        .font(.custom("Avenir-Medium", size: 14))
                        .foregroundColor(Color("AccentGreen"))
                }
            } else {
                Text("A new community raid boss will appear soon.")
                    .font(.custom("Avenir-Medium", size: 14))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
    
    // MARK: - Actions
    
    private func ensureBossExists() {
        guard let character = character else { return }
        
        let activeBoss = bosses.first(where: { !$0.isExpired && !$0.isDefeated })
        if activeBoss != nil { return }
        
        if let recent = bosses.first {
            if let nextDate = recent.nextBossDate, Date() < nextDate {
                return
            }
            if !recent.isExpired && !recent.isDefeated {
                return
            }
            if recent.nextBossDate == nil && (recent.isDefeated || recent.isExpired) {
                recent.nextBossDate = WeeklyRaidBoss.nextBossAppearDate(after: recent.weekEndDate)
                if Date() < recent.nextBossDate! { return }
            }
        }
        
        let avgLevel = character.level
        let tier = WeeklyRaidBoss.tierForLevel(avgLevel)
        let weekStart = Date()
        let calendar = Calendar.current
        let weekEnd = calendar.date(byAdding: .day, value: 14, to: weekStart)?.addingTimeInterval(-1) ?? weekStart
        let partyCount = max(1, (character.partyMembers.count > 0 ? character.partyMembers.count + 1 : (character.hasPartner ? 2 : 1)))
        
        let newBoss = WeeklyRaidBoss.generate(tier: tier, weekStart: weekStart, weekEnd: weekEnd, partyMemberCount: partyCount)
        modelContext.insert(newBoss)
    }
    
    private func loadCommunityData() {
        guard let boss = currentBoss, let bossId = boss.communityBossId else { return }
        isLoadingCommunity = true
        
        Task {
            do {
                let attacks = try await SupabaseService.shared.fetchCommunityAttackLog(bossId: bossId)
                await MainActor.run {
                    communityAttacks = attacks
                    isLoadingCommunity = false
                }
                
                if let serverBoss = try await SupabaseService.shared.fetchCommunityRaidBoss() {
                    await MainActor.run {
                        boss.currentHP = Int(serverBoss.currentHp)
                        boss.maxHP = Int(serverBoss.maxHp)
                        boss.isDefeated = serverBoss.isDefeated
                        boss.totalParticipants = serverBoss.totalParticipants
                        if let phase = serverBoss.currentPhase {
                            boss.currentPhase = phase
                        }
                        if let phaseHP = serverBoss.phaseMaxHp {
                            boss.phaseMaxHP = phaseHP
                        }
                        if let totalDmg = serverBoss.totalDamageDealt {
                            boss.totalDamageDealt = totalDmg
                        }
                        if let parties = serverBoss.totalParties {
                            boss.totalParties = parties
                        }
                    }
                }
            } catch {
                await MainActor.run { isLoadingCommunity = false }
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
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1_000_000 {
            return String(format: "%.1fM", Double(number) / 1_000_000)
        } else if number >= 1_000 {
            return String(format: "%.1fK", Double(number) / 1_000)
        }
        return "\(number)"
    }
    
    private struct TopAttacker {
        let name: String
        let totalDamage: Int
    }
    
    private func aggregateTopAttackers(from attacks: [CommunityRaidAttackDTO], limit: Int) -> [TopAttacker] {
        var damageByPlayer: [String: (name: String, damage: Int)] = [:]
        for attack in attacks {
            let existing = damageByPlayer[attack.userId] ?? (name: attack.playerName, damage: 0)
            damageByPlayer[attack.userId] = (name: existing.name, damage: existing.damage + attack.damage)
        }
        return damageByPlayer.values
            .map { TopAttacker(name: $0.name, totalDamage: $0.damage) }
            .sorted { $0.totalDamage > $1.totalDamage }
            .prefix(limit)
            .map { $0 }
    }
}

#Preview {
    RaidBossView()
        .environmentObject(GameEngine())
}
