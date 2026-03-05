import SwiftUI

struct ArenaFightView: View {
    let character: PlayerCharacter
    let opponent: FighterSnapshot
    let isRevenge: Bool
    let onComplete: (PVPMatchResult, (arenaPoints: Int, gold: Int, exp: Int), Int) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var matchResult: PVPMatchResult?
    @State private var currentRoundIndex = -1
    @State private var currentEventIndex = -1
    @State private var visibleEvents: [PVPRoundEvent] = []
    @State private var attackerHP: Double = 1.0
    @State private var defenderHP: Double = 1.0
    @State private var attackerMaxHP: Int = 0
    @State private var defenderMaxHP: Int = 0
    @State private var showResult = false
    @State private var ratingChange: Int = 0
    @State private var rewards: (arenaPoints: Int, gold: Int, exp: Int) = (0, 0, 0)
    @State private var roundLabel = ""
    @State private var shakeAttacker = false
    @State private var shakeDefender = false
    @State private var showCritFlash = false
    
    var body: some View {
        ZStack {
            ZStack {
                Image("arena_desert")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
            }
            
            VStack(spacing: 0) {
                HStack {
                    Text("Arena Fight")
                        .font(.custom("Avenir-Heavy", size: 18))
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 12)
                
                fighterDisplay
                    .padding(.top, 16)
                
                if !roundLabel.isEmpty {
                    Text(roundLabel)
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(Color("AccentGold"))
                        .padding(.vertical, 8)
                        .transition(.opacity)
                }
                
                gearComparisonRow
                    .padding(.vertical, 8)
                
                battleFeed
                
                Spacer()
            }
            
            if showCritFlash {
                Color.yellow.opacity(0.15)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            
            if showResult, let result = matchResult {
                resultOverlay(result: result)
            }
        }
        .onAppear {
            resolveFight()
        }
    }
    
    // MARK: - Fighter Display
    
    private var fighterDisplay: some View {
        HStack(spacing: 0) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color("AccentGold").opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    let cls = character.characterClass
                    Image(systemName: cls?.icon ?? "person.fill")
                        .font(.system(size: 26))
                        .foregroundColor(Color("AccentGold"))
                }
                .offset(x: shakeAttacker ? -6 : 0)
                
                Text(character.name)
                    .font(.custom("Avenir-Heavy", size: 13))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text("Lv.\(character.level)")
                    .font(.custom("Avenir-Medium", size: 11))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 3) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 9))
                        .foregroundColor(Color("AccentGold"))
                    Text("\(character.heroPower)")
                        .font(.custom("Avenir-Heavy", size: 11))
                        .foregroundColor(Color("AccentGold"))
                }
                
                hpBar(percentage: attackerHP, color: .green, label: "\(Int(attackerHP * Double(attackerMaxHP)))/\(attackerMaxHP)")
            }
            .frame(maxWidth: .infinity)
            
            VStack(spacing: 4) {
                Text("VS")
                    .font(.custom("Avenir-Heavy", size: 22))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("AccentGold"), Color("AccentOrange")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .frame(width: 50)
            
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    let cls = CharacterClass(rawValue: opponent.className ?? "")
                    Image(systemName: cls?.icon ?? "person.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.red)
                }
                .offset(x: shakeDefender ? 6 : 0)
                
                Text(opponent.name)
                    .font(.custom("Avenir-Heavy", size: 13))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text("Lv.\(opponent.level)")
                    .font(.custom("Avenir-Medium", size: 11))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 3) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 9))
                        .foregroundColor(Color("AccentGold"))
                    Text("\(opponent.heroPower)")
                        .font(.custom("Avenir-Heavy", size: 11))
                        .foregroundColor(Color("AccentGold"))
                }
                
                hpBar(percentage: defenderHP, color: .red, label: "\(Int(defenderHP * Double(defenderMaxHP)))/\(defenderMaxHP)")
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal)
    }
    
    private func hpBar(percentage: Double, color: Color, label: String) -> some View {
        VStack(spacing: 3) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            percentage > 0.5 ? color :
                            percentage > 0.25 ? Color.orange : Color.red
                        )
                        .frame(width: max(0, geo.size.width * percentage), height: 8)
                        .animation(.easeInOut(duration: 0.4), value: percentage)
                }
            }
            .frame(height: 8)
            
            Text(label)
                .font(.custom("Avenir-Medium", size: 10))
                .foregroundColor(.secondary)
        }
        .frame(width: 120)
    }
    
    // MARK: - Gear Comparison Row
    
    private var gearComparisonRow: some View {
        HStack(spacing: 6) {
            // Player gear (from character's equipped items)
            let playerSlots = playerEquipmentPreviews()
            HStack(spacing: 3) {
                ForEach(playerSlots) { slot in
                    miniGearIcon(slot)
                }
            }
            
            Text("vs")
                .font(.custom("Avenir-Medium", size: 11))
                .foregroundColor(.secondary)
            
            // Opponent gear
            HStack(spacing: 3) {
                ForEach(opponent.equipmentSlots) { slot in
                    miniGearIcon(slot)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color("CardBackground").opacity(0.5))
        .cornerRadius(8)
    }
    
    private func miniGearIcon(_ slot: EquipmentSlotPreview) -> some View {
        let rarityColor = rarityColorName(slot.rarity)
        let slotEnum = EquipmentSlot(rawValue: slot.slot)
        return ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(rarityColor).opacity(0.15))
                .frame(width: 22, height: 22)
            RoundedRectangle(cornerRadius: 3)
                .stroke(Color(rarityColor).opacity(0.5), lineWidth: 1)
                .frame(width: 22, height: 22)
            Image(systemName: slotEnum?.icon ?? "questionmark")
                .font(.system(size: 10))
                .foregroundColor(Color(rarityColor))
        }
    }
    
    private func playerEquipmentPreviews() -> [EquipmentSlotPreview] {
        let slots: [(String, Equipment?)] = [
            ("Weapon", character.equipment.weapon),
            ("Armor", character.equipment.armor),
            ("Accessory", character.equipment.accessory),
            ("Trinket", character.equipment.trinket),
            ("Cloak", character.equipment.cloak)
        ]
        return slots.compactMap { slotName, item in
            guard let item = item else { return nil }
            return EquipmentSlotPreview(
                slot: slotName,
                name: item.name,
                icon: item.imageName ?? EquipmentSlot(rawValue: slotName)?.icon ?? "questionmark",
                rarity: item.rarity.rawValue,
                equipmentLevel: item.equipmentLevel
            )
        }
    }
    
    private func rarityColorName(_ rarity: String) -> String {
        switch rarity {
        case "Common": return "RarityCommon"
        case "Uncommon": return "RarityUncommon"
        case "Rare": return "RarityRare"
        case "Epic": return "RarityEpic"
        case "Legendary": return "RarityLegendary"
        default: return "RarityCommon"
        }
    }
    
    // MARK: - Battle Feed
    
    private var battleFeed: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(visibleEvents) { event in
                        eventRow(event)
                            .id(event.id)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .onChange(of: visibleEvents.count) { _, _ in
                if let lastEvent = visibleEvents.last {
                    withAnimation {
                        proxy.scrollTo(lastEvent.id, anchor: .bottom)
                    }
                }
            }
        }
        .frame(maxHeight: 280)
        .background(Color("CardBackground").opacity(0.2))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func eventRow(_ event: PVPRoundEvent) -> some View {
        HStack(alignment: .top, spacing: 8) {
            let isAttackerEvent = event.fighterName == character.name
            
            Circle()
                .fill(isAttackerEvent ? Color("AccentGold").opacity(0.2) : Color.red.opacity(0.2))
                .frame(width: 8, height: 8)
                .padding(.top, 5)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(event.narrativeText)
                    .font(.custom("Avenir-Medium", size: 13))
                    .foregroundColor(.primary)
                
                if event.isCrit {
                    Text("CRITICAL HIT!")
                        .font(.custom("Avenir-Heavy", size: 11))
                        .foregroundColor(.orange)
                }
                if event.isDodge {
                    Text("DODGED!")
                        .font(.custom("Avenir-Heavy", size: 11))
                        .foregroundColor(Color("StatDexterity"))
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Result Overlay
    
    private func resultOverlay(result: PVPMatchResult) -> some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Spacer()
                
                if result.winnerIsAttacker {
                    VStack(spacing: 8) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Color("AccentGold"))
                        Text("VICTORY!")
                            .font(.custom("Avenir-Heavy", size: 32))
                            .foregroundColor(Color("AccentGold"))
                    }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "xmark.shield.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                        Text("DEFEAT")
                            .font(.custom("Avenir-Heavy", size: 32))
                            .foregroundColor(.red)
                    }
                }
                
                VStack(spacing: 4) {
                    let changeText = result.winnerIsAttacker ? "+\(ratingChange)" : "-\(ratingChange)"
                    let changeColor: Color = result.winnerIsAttacker ? .green : .red
                    
                    Text(changeText)
                        .font(.custom("Avenir-Heavy", size: 28))
                        .foregroundColor(changeColor)
                    Text("Rating")
                        .font(.custom("Avenir-Medium", size: 13))
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 8) {
                    HStack(spacing: 20) {
                        rewardPill(icon: "star.circle.fill", value: "\(rewards.arenaPoints) AP", color: Color("AccentGold"))
                        if rewards.gold > 0 {
                            rewardPill(icon: "dollarsign.circle.fill", value: "\(rewards.gold) Gold", color: .yellow)
                        }
                        rewardPill(icon: "sparkles", value: "\(rewards.exp) EXP", color: .purple)
                    }
                    
                    if isRevenge && result.winnerIsAttacker {
                        Text("Revenge Bonus! +50% AP")
                            .font(.custom("Avenir-Heavy", size: 13))
                            .foregroundColor(.orange)
                    }
                }
                .padding(.top, 8)
                
                Spacer()
                
                Button {
                    onComplete(result, rewards, ratingChange)
                    dismiss()
                } label: {
                    Text("Return to Arena")
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color("AccentGold"), Color("AccentOrange")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .transition(.opacity)
    }
    
    private func rewardPill(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
            Text(value)
                .font(.custom("Avenir-Heavy", size: 13))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color("CardBackground"))
        .cornerRadius(8)
    }
    
    // MARK: - Fight Resolution
    
    private func resolveFight() {
        let bondBuff = character.partyID != nil
        let attackerStats = ArenaEngine.derivePVPStats(from: character, bondBuff: bondBuff)
        let defenderStats = opponent.toPVPStats()
        
        attackerMaxHP = attackerStats.hp
        defenderMaxHP = defenderStats.hp
        
        let result = ArenaEngine.resolveMatch(
            attacker: attackerStats,
            defender: defenderStats
        )
        
        self.matchResult = result
        
        let (winGain, loseLoss) = ArenaEngine.calculateRatingChange(
            winnerRating: result.winnerIsAttacker ? character.arenaRating : opponent.rating,
            loserRating: result.winnerIsAttacker ? opponent.rating : character.arenaRating
        )
        
        if result.winnerIsAttacker {
            self.ratingChange = ArenaEngine.applyStreakBonus(baseGain: winGain, streak: character.arenaStreak + 1)
        } else {
            self.ratingChange = loseLoss
        }
        
        self.rewards = ArenaEngine.matchRewards(
            won: result.winnerIsAttacker,
            opponentRating: opponent.rating,
            playerLevel: character.level,
            streak: result.winnerIsAttacker ? character.arenaStreak + 1 : 0,
            isRevenge: isRevenge,
            bonusAPPercent: attackerStats.bonusAPPercent,
            bonusGoldPercent: attackerStats.bonusGoldPercent,
            bonusEXPPercent: attackerStats.bonusEXPPercent
        )
        
        animateRounds(result.rounds)
    }
    
    private func animateRounds(_ rounds: [PVPRoundResult]) {
        var delay: Double = 0.5
        
        for (rIdx, round) in rounds.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.roundLabel = "Round \(round.roundNumber) — \(round.roundName)"
                    self.currentRoundIndex = rIdx
                }
            }
            delay += 0.8
            
            for event in round.events {
                let eventDelay = delay
                DispatchQueue.main.asyncAfter(deadline: .now() + eventDelay) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.visibleEvents.append(event)
                    }
                    
                    let isAttackerHit = event.fighterName != character.name
                    if !event.isDodge && event.damage > 0 {
                        if isAttackerHit {
                            withAnimation(.default) {
                                self.shakeAttacker = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                self.shakeAttacker = false
                            }
                        } else {
                            withAnimation(.default) {
                                self.shakeDefender = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                self.shakeDefender = false
                            }
                        }
                    }
                    
                    if event.isCrit {
                        withAnimation(.easeOut(duration: 0.1)) { self.showCritFlash = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(.easeIn(duration: 0.15)) { self.showCritFlash = false }
                        }
                    }
                    
                    withAnimation(.easeInOut(duration: 0.4)) {
                        self.attackerHP = Double(max(0, round.attackerHPAfter)) / Double(attackerMaxHP)
                        self.defenderHP = Double(max(0, round.defenderHPAfter)) / Double(defenderMaxHP)
                    }
                }
                delay += 1.2
            }
            
            delay += 0.5
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.5) {
            withAnimation(.easeInOut(duration: 0.4)) {
                self.showResult = true
            }
        }
    }
}
