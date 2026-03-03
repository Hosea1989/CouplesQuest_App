import Foundation

// MARK: - Battle Stance

enum BattleStance: String, Codable, CaseIterable, Identifiable {
    case onslaught = "Onslaught"
    case fortress = "Fortress"
    case precision = "Precision"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .onslaught: return "flame.fill"
        case .fortress: return "shield.fill"
        case .precision: return "scope"
        }
    }
    
    var subtitle: String {
        switch self {
        case .onslaught: return "+20% damage dealt"
        case .fortress: return "-25% damage taken"
        case .precision: return "2x crit rate, 1.75x crit damage"
        }
    }
    
    var color: String {
        switch self {
        case .onslaught: return "StatStrength"
        case .fortress: return "StatDefense"
        case .precision: return "StatLuck"
        }
    }
    
    func beats(_ other: BattleStance) -> Bool {
        switch (self, other) {
        case (.onslaught, .precision): return true
        case (.precision, .fortress): return true
        case (.fortress, .onslaught): return true
        default: return false
        }
    }
}

// MARK: - Stance Matchup

enum StanceMatchup {
    case winning
    case losing
    case mirror
}

// MARK: - Arena Tier

enum ArenaTier: String, Codable, CaseIterable, Identifiable {
    case bronze = "Bronze"
    case silver = "Silver"
    case gold = "Gold"
    case platinum = "Platinum"
    case diamond = "Diamond"
    case champion = "Champion"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .bronze: return "shield.fill"
        case .silver: return "shield.fill"
        case .gold: return "shield.fill"
        case .platinum: return "shield.fill"
        case .diamond: return "diamond.fill"
        case .champion: return "crown.fill"
        }
    }
    
    var color: String {
        switch self {
        case .bronze: return "StatDefense"
        case .silver: return "StatWisdom"
        case .gold: return "AccentGold"
        case .platinum: return "StatCharisma"
        case .diamond: return "StatDexterity"
        case .champion: return "AccentGold"
        }
    }
    
    var ratingRange: ClosedRange<Int> {
        switch self {
        case .bronze: return 0...1199
        case .silver: return 1200...1499
        case .gold: return 1500...1799
        case .platinum: return 1800...2099
        case .diamond: return 2100...2399
        case .champion: return 2400...99999
        }
    }
    
    static func tier(for rating: Int) -> ArenaTier {
        switch rating {
        case 0..<1200: return .bronze
        case 1200..<1500: return .silver
        case 1500..<1800: return .gold
        case 1800..<2100: return .platinum
        case 2100..<2400: return .diamond
        default: return .champion
        }
    }
    
    var seasonRewardArenaPoints: Int {
        switch self {
        case .bronze: return 50
        case .silver: return 150
        case .gold: return 300
        case .platinum: return 500
        case .diamond: return 800
        case .champion: return 1200
        }
    }
    
    var seasonRewardGold: Int {
        switch self {
        case .bronze: return 0
        case .silver: return 500
        case .gold: return 1000
        case .platinum: return 2000
        case .diamond: return 5000
        case .champion: return 10000
        }
    }
}

// MARK: - PVP Fighter Stats

struct PVPFighterStats {
    let atk: Int
    let guard_: Int
    let spd: Int
    let critChance: Double
    let morale: Double
    let hp: Int
    let className: CharacterClass?
    let level: Int
    let heroPower: Int
    let name: String
    
    var maxCritChance: Double { min(0.30, critChance) }
}

// MARK: - PVP Round Event

struct PVPRoundEvent: Codable, Identifiable {
    var id: UUID = UUID()
    let fighterName: String
    let damage: Int
    let isCrit: Bool
    let isDodge: Bool
    let narrativeText: String
    let hpAfter: Int
}

// MARK: - PVP Round Result

struct PVPRoundResult: Codable, Identifiable {
    var id: UUID = UUID()
    let roundNumber: Int
    let roundName: String
    let events: [PVPRoundEvent]
    let attackerHPAfter: Int
    let defenderHPAfter: Int
}

// MARK: - PVP Match Result

struct PVPMatchResult: Codable {
    let rounds: [PVPRoundResult]
    let winnerIsAttacker: Bool
    let attackerTotalDamage: Int
    let defenderTotalDamage: Int
    let attackerFinalHP: Int
    let defenderFinalHP: Int
    let attackerStance: BattleStance
    let defenderStance: BattleStance
    let stanceMatchup: String
}

// MARK: - Fighter Snapshot (for Supabase sync)

struct FighterSnapshot: Codable, Identifiable {
    var id: UUID = UUID()
    var userID: String
    var name: String
    var level: Int
    var className: String?
    var strength: Int
    var wisdom: Int
    var charisma: Int
    var dexterity: Int
    var luck: Int
    var defense: Int
    var weaponPrimaryBonus: Int
    var armorPrimaryBonus: Int
    var heroPower: Int
    var rating: Int
    var tier: String
    var defenseStance: String
    var wins: Int
    var losses: Int
    var streak: Int
    var peakRating: Int
    var recentTrend: String // "up", "down", "neutral"
    var pendingRevengeIDs: [String]
    var arenaPoints: Int
    var hasBond: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, name, level, strength, wisdom, charisma, dexterity, luck, defense
        case heroPower = "hero_power"
        case userID = "user_id"
        case className = "class"
        case weaponPrimaryBonus = "weapon_primary_bonus"
        case armorPrimaryBonus = "armor_primary_bonus"
        case rating, tier, wins, losses, streak
        case defenseStance = "defense_stance"
        case peakRating = "peak_rating"
        case recentTrend = "recent_trend"
        case pendingRevengeIDs = "pending_revenge_ids"
        case arenaPoints = "arena_points"
        case hasBond = "has_bond"
    }
    
    func toPVPStats() -> PVPFighterStats {
        let charClass = CharacterClass(rawValue: className ?? "")
        let atkValue = strength + wisdom + (weaponPrimaryBonus * 2)
        let guardValue = defense + (armorPrimaryBonus * 2)
        let critValue = 0.05 + Double(luck) * 0.005
        let moraleValue = min(0.15, Double(charisma) * 0.003)
        
        let classHP = charClass?.baseHP ?? 100
        let hpPerLvl = charClass?.hpPerLevel ?? 5
        let defHP = defense * 5
        let totalHP = classHP + (level * hpPerLvl) + defHP
        
        return PVPFighterStats(
            atk: atkValue,
            guard_: guardValue,
            spd: dexterity,
            critChance: critValue,
            morale: moraleValue,
            hp: totalHP,
            className: charClass,
            level: level,
            heroPower: heroPower,
            name: name
        )
    }
}

// MARK: - Arena Engine

struct ArenaEngine {
    
    static let defaultRating = 1000
    static let maxDailyFights = 5
    static let extraFightGoldCost = 75
    static let maxRevengeSlots = 3
    static let revengeExpiryHours = 48
    static let revengeBonusMultiplier = 1.5
    
    // MARK: - Derive PVP Stats
    
    static func derivePVPStats(from character: PlayerCharacter, bondBuff: Bool = false) -> PVPFighterStats {
        let stats = character.effectiveStats
        let weapon = character.equipment.weapon
        let armor = character.equipment.armor
        
        let weaponBonus = weapon != nil ? Int(weapon!.effectivePrimaryBonus.rounded()) : 0
        let armorBonus = armor != nil ? Int(armor!.effectivePrimaryBonus.rounded()) : 0
        
        var atkValue = stats.strength + stats.wisdom + (weaponBonus * 2)
        var guardValue = stats.defense + (armorBonus * 2)
        var spdValue = stats.dexterity
        var critBase = 0.05 + Double(stats.luck) * 0.005
        var moraleBase = min(0.15, Double(stats.charisma) * 0.003)
        let hpValue = character.maxHP
        
        if bondBuff {
            atkValue = Int(Double(atkValue) * 1.05)
            guardValue = Int(Double(guardValue) * 1.05)
            spdValue = Int(Double(spdValue) * 1.05)
            critBase *= 1.05
            moraleBase = min(0.15, moraleBase * 1.05)
        }
        
        return PVPFighterStats(
            atk: atkValue,
            guard_: guardValue,
            spd: spdValue,
            critChance: critBase,
            morale: moraleBase,
            hp: hpValue,
            className: character.characterClass,
            level: character.level,
            heroPower: character.heroPower,
            name: character.name
        )
    }
    
    // MARK: - Stance Matchup
    
    static func stanceMatchup(attacker: BattleStance, defender: BattleStance, attackerClass: CharacterClass?) -> StanceMatchup {
        if attacker == defender { return .mirror }
        
        // Trickster: stance matchup is never "losing"
        if attackerClass == .trickster && defender.beats(attacker) {
            return .mirror
        }
        
        if attacker.beats(defender) { return .winning }
        return .losing
    }
    
    // MARK: - Damage Calculation
    
    static func calculateDamage(
        attacker: PVPFighterStats,
        defender: PVPFighterStats,
        attackerStance: BattleStance,
        matchup: StanceMatchup,
        roundNumber: Int,
        attackerCurrentHP: Int,
        defenderCurrentHP: Int,
        defenderGuardReduced: Bool
    ) -> (damage: Int, isCrit: Bool, isDodge: Bool) {
        
        let baseDamage = Double(attacker.atk) * 3.0
        
        var effectiveGuard = Double(defender.guard_)
        if defenderGuardReduced {
            effectiveGuard *= 0.80
        }
        let guardReduce = effectiveGuard / (effectiveGuard + 80.0)
        let moraleReduce = defender.morale
        
        // Dodge check
        var dodgeChance = Double(defender.spd) / (Double(defender.spd) + Double(attacker.spd) + 120.0)
        
        // Archer Quick Draw: +25% dodge in Round 1 (when defending)
        if defender.className == .archer && roundNumber == 1 {
            dodgeChance += 0.25
        }
        // Ranger Evasion Master: +15% dodge all rounds
        if defender.className == .ranger {
            dodgeChance += 0.15
        }
        
        dodgeChance = min(0.60, dodgeChance)
        
        if Double.random(in: 0...1) < dodgeChance {
            return (0, false, true)
        }
        
        var raw = baseDamage * (1.0 - guardReduce) * (1.0 - moraleReduce)
        
        // Stance damage modifier
        switch attackerStance {
        case .onslaught:
            let bonus = matchup == .losing ? 0.08 : 0.20
            raw *= (1.0 + bonus)
        case .fortress:
            break
        case .precision:
            break
        }
        
        // Stance matchup bonus
        if matchup == .winning {
            raw *= 1.10
        }
        
        // Class passives affecting ATK
        if let cls = attacker.className {
            switch cls {
            case .warrior:
                if Double(attackerCurrentHP) / Double(attacker.hp) < 0.50 {
                    raw *= 1.15
                }
            case .berserker:
                if Double(attackerCurrentHP) / Double(attacker.hp) < 0.30 {
                    raw *= 1.25
                }
            default: break
            }
        }
        
        // Round 1: SPD advantage = +5% damage for faster fighter
        if roundNumber == 1 && attacker.spd > defender.spd {
            raw *= 1.05
        }
        
        // Crit check
        var critChance = attacker.maxCritChance
        
        if attackerStance == .precision {
            if matchup == .losing {
                // No doubling when losing stance matchup — weaker crits
            } else {
                critChance = min(0.60, critChance * 2.0)
            }
        }
        
        // Round 3: +50% crit chance for dramatic finisher
        if roundNumber == 3 {
            critChance = min(0.75, critChance * 1.5)
        }
        
        let isCrit = Double.random(in: 0...1) < critChance
        if isCrit {
            var critMultiplier: Double
            switch (attackerStance, matchup) {
            case (.precision, .losing):
                critMultiplier = 1.25
            case (.precision, _):
                critMultiplier = 1.75
            default:
                critMultiplier = 1.50
            }
            // Mage Arcane Surge: +20% crit damage
            if attacker.className == .mage {
                critMultiplier += 0.20
            }
            raw *= critMultiplier
        }
        
        // Fortress damage taken reduction (applied when this fighter is the defender, but
        // here we're calculating damage the attacker deals, so Fortress reduces incoming damage
        // in resolveRound where we apply it to the defender)
        
        // Variance
        let variance = Double.random(in: 0.92...1.08)
        raw *= variance
        
        let finalDamage = max(1, Int(raw.rounded()))
        return (finalDamage, isCrit, false)
    }
    
    // MARK: - Apply Defensive Modifiers
    
    static func applyDefensiveModifiers(
        damage: Int,
        defender: PVPFighterStats,
        defenderStance: BattleStance,
        matchup: StanceMatchup
    ) -> Int {
        var reduced = Double(damage)
        
        // Fortress stance: damage taken reduction
        if defenderStance == .fortress {
            let reduction = matchup == .losing ? 0.10 : 0.25
            reduced *= (1.0 - reduction)
        }
        
        // Paladin Iron Will: flat -15% damage taken
        if defender.className == .paladin {
            reduced *= 0.85
        }
        
        return max(1, Int(reduced.rounded()))
    }
    
    // MARK: - Resolve Full Match
    
    static func resolveMatch(
        attacker: PVPFighterStats,
        defender: PVPFighterStats,
        attackerStance: BattleStance,
        defenderStance: BattleStance
    ) -> PVPMatchResult {
        
        let attackerMatchup = stanceMatchup(attacker: attackerStance, defender: defenderStance, attackerClass: attacker.className)
        let defenderMatchup: StanceMatchup = {
            if attackerMatchup == .winning { return .losing }
            if attackerMatchup == .losing { return .winning }
            return .mirror
        }()
        
        // Trickster check for defender too
        let adjustedDefenderMatchup: StanceMatchup
        if defender.className == .trickster && defenderMatchup == .losing {
            adjustedDefenderMatchup = .mirror
        } else {
            adjustedDefenderMatchup = defenderMatchup
        }
        
        var attackerHP = attacker.hp
        var defenderHP = defender.hp
        var attackerTotalDamage = 0
        var defenderTotalDamage = 0
        var rounds: [PVPRoundResult] = []
        var defenderGuardReduced = false
        
        let roundNames = ["Opening", "Clash", "Decisive"]
        
        for roundNum in 1...3 {
            var events: [PVPRoundEvent] = []
            
            let attackerGoesFirst = roundNum == 1 ? attacker.spd >= defender.spd : true
            
            if attackerGoesFirst {
                // Attacker strikes
                let (atkDmg, atkCrit, atkDodge) = calculateDamage(
                    attacker: attacker, defender: defender,
                    attackerStance: attackerStance, matchup: attackerMatchup,
                    roundNumber: roundNum, attackerCurrentHP: attackerHP,
                    defenderCurrentHP: defenderHP, defenderGuardReduced: false
                )
                
                let finalAtkDmg = atkDodge ? 0 : applyDefensiveModifiers(
                    damage: atkDmg, defender: defender,
                    defenderStance: defenderStance, matchup: adjustedDefenderMatchup
                )
                defenderHP = max(0, defenderHP - finalAtkDmg)
                attackerTotalDamage += finalAtkDmg
                
                // Sorcerer Shatter: crits reduce opponent GUARD by 20%
                if atkCrit && attacker.className == .sorcerer {
                    defenderGuardReduced = true
                }
                
                let atkNarrative = generateNarrative(
                    attackerName: attacker.name, defenderName: defender.name,
                    damage: finalAtkDmg, isCrit: atkCrit, isDodge: atkDodge,
                    attackerClass: attacker.className
                )
                events.append(PVPRoundEvent(
                    fighterName: attacker.name, damage: finalAtkDmg,
                    isCrit: atkCrit, isDodge: atkDodge,
                    narrativeText: atkNarrative, hpAfter: defenderHP
                ))
                
                // Defender strikes back (if alive)
                if defenderHP > 0 {
                    let (defDmg, defCrit, defDodge) = calculateDamage(
                        attacker: defender, defender: attacker,
                        attackerStance: defenderStance, matchup: adjustedDefenderMatchup,
                        roundNumber: roundNum, attackerCurrentHP: defenderHP,
                        defenderCurrentHP: attackerHP, defenderGuardReduced: false
                    )
                    
                    let finalDefDmg = defDodge ? 0 : applyDefensiveModifiers(
                        damage: defDmg, defender: attacker,
                        defenderStance: attackerStance, matchup: attackerMatchup
                    )
                    attackerHP = max(0, attackerHP - finalDefDmg)
                    defenderTotalDamage += finalDefDmg
                    
                    let defNarrative = generateNarrative(
                        attackerName: defender.name, defenderName: attacker.name,
                        damage: finalDefDmg, isCrit: defCrit, isDodge: defDodge,
                        attackerClass: defender.className
                    )
                    events.append(PVPRoundEvent(
                        fighterName: defender.name, damage: finalDefDmg,
                        isCrit: defCrit, isDodge: defDodge,
                        narrativeText: defNarrative, hpAfter: attackerHP
                    ))
                }
            } else {
                // Defender strikes first (only in Round 1 when defender has higher SPD)
                let (defDmg, defCrit, defDodge) = calculateDamage(
                    attacker: defender, defender: attacker,
                    attackerStance: defenderStance, matchup: adjustedDefenderMatchup,
                    roundNumber: roundNum, attackerCurrentHP: defenderHP,
                    defenderCurrentHP: attackerHP, defenderGuardReduced: false
                )
                
                let finalDefDmg = defDodge ? 0 : applyDefensiveModifiers(
                    damage: defDmg, defender: attacker,
                    defenderStance: attackerStance, matchup: attackerMatchup
                )
                attackerHP = max(0, attackerHP - finalDefDmg)
                defenderTotalDamage += finalDefDmg
                
                let defNarrative = generateNarrative(
                    attackerName: defender.name, defenderName: attacker.name,
                    damage: finalDefDmg, isCrit: defCrit, isDodge: defDodge,
                    attackerClass: defender.className
                )
                events.append(PVPRoundEvent(
                    fighterName: defender.name, damage: finalDefDmg,
                    isCrit: defCrit, isDodge: defDodge,
                    narrativeText: defNarrative, hpAfter: attackerHP
                ))
                
                if attackerHP > 0 {
                    let (atkDmg, atkCrit, atkDodge) = calculateDamage(
                        attacker: attacker, defender: defender,
                        attackerStance: attackerStance, matchup: attackerMatchup,
                        roundNumber: roundNum, attackerCurrentHP: attackerHP,
                        defenderCurrentHP: defenderHP, defenderGuardReduced: false
                    )
                    
                    let finalAtkDmg = atkDodge ? 0 : applyDefensiveModifiers(
                        damage: atkDmg, defender: defender,
                        defenderStance: defenderStance, matchup: adjustedDefenderMatchup
                    )
                    defenderHP = max(0, defenderHP - finalAtkDmg)
                    attackerTotalDamage += finalAtkDmg
                    
                    if atkCrit && attacker.className == .sorcerer {
                        defenderGuardReduced = true
                    }
                    
                    let atkNarrative = generateNarrative(
                        attackerName: attacker.name, defenderName: defender.name,
                        damage: finalAtkDmg, isCrit: atkCrit, isDodge: atkDodge,
                        attackerClass: attacker.className
                    )
                    events.append(PVPRoundEvent(
                        fighterName: attacker.name, damage: finalAtkDmg,
                        isCrit: atkCrit, isDodge: atkDodge,
                        narrativeText: atkNarrative, hpAfter: defenderHP
                    ))
                }
            }
            
            // Enchanter Arcane Ward: heal 12% maxHP after Round 2
            if roundNum == 2 {
                if attacker.className == .enchanter {
                    attackerHP = min(attacker.hp, attackerHP + Int(Double(attacker.hp) * 0.12))
                }
                if defender.className == .enchanter {
                    defenderHP = min(defender.hp, defenderHP + Int(Double(defender.hp) * 0.12))
                }
            }
            
            rounds.append(PVPRoundResult(
                roundNumber: roundNum,
                roundName: roundNames[roundNum - 1],
                events: events,
                attackerHPAfter: attackerHP,
                defenderHPAfter: defenderHP
            ))
            
            if attackerHP <= 0 || defenderHP <= 0 { break }
        }
        
        // Determine winner
        let winnerIsAttacker: Bool
        if attackerHP <= 0 && defenderHP <= 0 {
            winnerIsAttacker = attackerTotalDamage >= defenderTotalDamage
        } else if defenderHP <= 0 {
            winnerIsAttacker = true
        } else if attackerHP <= 0 {
            winnerIsAttacker = false
        } else {
            winnerIsAttacker = attackerHP >= defenderHP
        }
        
        let matchupName: String = {
            switch stanceMatchup(attacker: attackerStance, defender: defenderStance, attackerClass: attacker.className) {
            case .winning: return "winning"
            case .losing: return "losing"
            case .mirror: return "mirror"
            }
        }()
        
        return PVPMatchResult(
            rounds: rounds,
            winnerIsAttacker: winnerIsAttacker,
            attackerTotalDamage: attackerTotalDamage,
            defenderTotalDamage: defenderTotalDamage,
            attackerFinalHP: attackerHP,
            defenderFinalHP: defenderHP,
            attackerStance: attackerStance,
            defenderStance: defenderStance,
            stanceMatchup: matchupName
        )
    }
    
    // MARK: - Rating Calculation
    
    static func calculateRatingChange(winnerRating: Int, loserRating: Int) -> (winnerGain: Int, loserLoss: Int) {
        let diff = loserRating - winnerRating
        
        let winnerGain: Int
        if diff > 200 {
            winnerGain = 40 // upset bonus
        } else if diff < -200 {
            winnerGain = 12 // expected win
        } else {
            winnerGain = 25 // standard
        }
        
        let loserLoss: Int
        if diff > 200 {
            loserLoss = 12 // expected loss
        } else if diff < -200 {
            loserLoss = 30 // upset loss
        } else {
            loserLoss = 20 // standard
        }
        
        return (winnerGain, loserLoss)
    }
    
    static func applyStreakBonus(baseGain: Int, streak: Int) -> Int {
        guard streak >= 3 else { return baseGain }
        return baseGain + (streak - 2) * 5
    }
    
    // MARK: - Rewards
    
    static func matchRewards(won: Bool, opponentRating: Int, playerLevel: Int, streak: Int, isRevenge: Bool) -> (arenaPoints: Int, gold: Int, exp: Int) {
        if won {
            var ap = Int.random(in: 15...25)
            let gold = Int.random(in: 50...150)
            let exp = playerLevel * 3
            
            if streak >= 3 {
                ap = Int(Double(ap) * 1.5)
            }
            if isRevenge {
                ap = Int(Double(ap) * ArenaEngine.revengeBonusMultiplier)
            }
            
            return (ap, gold, exp)
        } else {
            let ap = Int.random(in: 3...5)
            let exp = playerLevel * 1
            return (ap, 0, exp)
        }
    }
    
    // MARK: - Narrative Generation
    
    private static func generateNarrative(
        attackerName: String,
        defenderName: String,
        damage: Int,
        isCrit: Bool,
        isDodge: Bool,
        attackerClass: CharacterClass?
    ) -> String {
        if isDodge {
            let dodgeLines = [
                "\(defenderName) sidesteps the blow!",
                "\(defenderName) deftly evades the attack!",
                "\(attackerName) swings wide — \(defenderName) dodges!",
                "\(defenderName) rolls out of the way!",
                "A near miss! \(defenderName) avoids the strike!"
            ]
            return dodgeLines.randomElement()!
        }
        
        let verb: String = {
            switch attackerClass {
            case .warrior, .berserker, .paladin:
                return ["lunges with a heavy strike", "delivers a crushing blow", "slams forward with brute force", "unleashes a powerful swing"].randomElement()!
            case .mage, .sorcerer, .enchanter:
                return ["channels an arcane bolt", "hurls a burst of energy", "casts a searing spell", "releases a wave of magic"].randomElement()!
            case .archer, .ranger, .trickster:
                return ["fires a precise shot", "looses a deadly arrow", "strikes with pinpoint accuracy", "lands a swift hit"].randomElement()!
            case .none:
                return ["attacks", "strikes", "lands a hit"].randomElement()!
            }
        }()
        
        if isCrit {
            return "\(attackerName) \(verb) — CRITICAL HIT! \(damage) damage!"
        }
        return "\(attackerName) \(verb) for \(damage) damage!"
    }
    
    // MARK: - Snapshot Builder
    
    static func buildSnapshot(from character: PlayerCharacter, userID: String) -> FighterSnapshot {
        let stats = character.effectiveStats
        let weapon = character.equipment.weapon
        let armor = character.equipment.armor
        let weaponBonus = weapon != nil ? Int(weapon!.effectivePrimaryBonus.rounded()) : 0
        let armorBonus = armor != nil ? Int(armor!.effectivePrimaryBonus.rounded()) : 0
        
        return FighterSnapshot(
            userID: userID,
            name: character.name,
            level: character.level,
            className: character.characterClass?.rawValue,
            strength: stats.strength,
            wisdom: stats.wisdom,
            charisma: stats.charisma,
            dexterity: stats.dexterity,
            luck: stats.luck,
            defense: stats.defense,
            weaponPrimaryBonus: weaponBonus,
            armorPrimaryBonus: armorBonus,
            heroPower: character.heroPower,
            rating: character.arenaRating,
            tier: ArenaTier.tier(for: character.arenaRating).rawValue,
            defenseStance: character.arenaDefenseStance,
            wins: character.arenaWins,
            losses: character.arenaLosses,
            streak: character.arenaStreak,
            peakRating: character.arenaPeakRating,
            recentTrend: "neutral",
            pendingRevengeIDs: [],
            arenaPoints: character.arenaPoints,
            hasBond: character.partyID != nil
        )
    }
}
