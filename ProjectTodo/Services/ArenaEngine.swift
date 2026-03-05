import Foundation

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
    let pvpDamageBonus: Double
    let pvpHPRegenPercent: Double
    let bonusAPPercent: Double
    let bonusGoldPercent: Double
    let bonusEXPPercent: Double
    
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
}

// MARK: - Equipment Slot Preview (for opponent gear display)

struct EquipmentSlotPreview: Codable, Identifiable {
    var id: String { slot }
    let slot: String
    let name: String
    let icon: String
    let rarity: String
    let equipmentLevel: Int
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
    var wins: Int
    var losses: Int
    var streak: Int
    var peakRating: Int
    var recentTrend: String
    var pendingRevengeIDs: [String]
    var arenaPoints: Int
    var hasBond: Bool
    var equipmentSlots: [EquipmentSlotPreview]
    var pvpDamageBonus: Double
    var pvpHPRegenPercent: Double
    
    enum CodingKeys: String, CodingKey {
        case id, name, level, strength, wisdom, charisma, dexterity, luck, defense
        case heroPower = "hero_power"
        case userID = "user_id"
        case className = "class"
        case weaponPrimaryBonus = "weapon_primary_bonus"
        case armorPrimaryBonus = "armor_primary_bonus"
        case rating, tier, wins, losses, streak
        case peakRating = "peak_rating"
        case recentTrend = "recent_trend"
        case pendingRevengeIDs = "pending_revenge_ids"
        case arenaPoints = "arena_points"
        case hasBond = "has_bond"
        case equipmentSlots = "equipment_slots"
        case pvpDamageBonus = "pvp_damage_bonus"
        case pvpHPRegenPercent = "pvp_hp_regen_percent"
    }
    
    func toPVPStats() -> PVPFighterStats {
        let charClass = CharacterClass(rawValue: className ?? "")
        let atkValue = Int(Double(strength + wisdom) * 1.5) + (weaponPrimaryBonus * 3)
        let guardValue = defense * 2 + (armorPrimaryBonus * 3)
        let spdValue = Int(Double(dexterity) * 1.5)
        let critValue = 0.05 + Double(luck) * 0.005
        let moraleValue = min(0.15, Double(charisma) * 0.003)
        
        let classHP = charClass?.baseHP ?? 100
        let hpPerLvl = charClass?.hpPerLevel ?? 5
        let defHP = defense * 5
        let totalHP = classHP + (level * hpPerLvl) + defHP
        
        return PVPFighterStats(
            atk: atkValue,
            guard_: guardValue,
            spd: spdValue,
            critChance: critValue,
            morale: moraleValue,
            hp: totalHP,
            className: charClass,
            level: level,
            heroPower: heroPower,
            name: name,
            pvpDamageBonus: pvpDamageBonus,
            pvpHPRegenPercent: pvpHPRegenPercent,
            bonusAPPercent: 0,
            bonusGoldPercent: 0,
            bonusEXPPercent: 0
        )
    }
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

// MARK: - Arena Engine

struct ArenaEngine {
    
    static let defaultRating = 1000
    static let maxDailyFights = 5
    static let extraFightGoldCost = 75
    static let maxRevengeSlots = 3
    static let revengeExpiryHours = 48
    static let revengeBonusMultiplier = 1.5
    
    // MARK: - Derive PVP Stats (Deep Gear Integration)
    
    static func derivePVPStats(from character: PlayerCharacter, bondBuff: Bool = false) -> PVPFighterStats {
        let stats = character.effectiveStats
        let weapon = character.equipment.weapon
        let armor = character.equipment.armor
        
        let weaponBonus = weapon != nil ? Int(weapon!.effectivePrimaryBonus.rounded()) : 0
        let armorBonus = armor != nil ? Int(armor!.effectivePrimaryBonus.rounded()) : 0
        
        var atkValue = Int(Double(stats.strength + stats.wisdom) * 1.5) + (weaponBonus * 3)
        var guardValue = stats.defense * 2 + (armorBonus * 3)
        var spdValue = Int(Double(stats.dexterity) * 1.5)
        var critBase = 0.05 + Double(stats.luck) * 0.005
        var moraleBase = min(0.15, Double(stats.charisma) * 0.003)
        let hpValue = character.maxHP
        
        // Aggregate quirk special effects from all equipment for PVP translation
        let equippedItems = character.equipment.allEquipped
        var pvpDamageBonus: Double = 0
        var pvpHPRegenPercent: Double = 0
        var bonusAPPercent: Double = 0
        var bonusGoldPercent: Double = 0
        var bonusEXPPercent: Double = 0
        
        for item in equippedItems {
            let effects = item.quirkSpecialEffects
            if let dungeonDmg = effects[.dungeonDamage] {
                pvpDamageBonus += dungeonDmg * 0.5
            }
            if let bossDmg = effects[.bossDamage] {
                pvpDamageBonus += bossDmg * 0.25
            }
            if let hpRegen = effects[.hpRegen] {
                pvpHPRegenPercent += hpRegen
            }
            if let lootChance = effects[.lootChance] {
                bonusAPPercent += lootChance
            }
            if let goldPct = effects[.goldPercent] {
                bonusGoldPercent += goldPct
            }
            if let expPct = effects[.expPercent] {
                bonusEXPPercent += expPct
            }
        }
        
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
            name: character.name,
            pvpDamageBonus: pvpDamageBonus,
            pvpHPRegenPercent: pvpHPRegenPercent,
            bonusAPPercent: bonusAPPercent,
            bonusGoldPercent: bonusGoldPercent,
            bonusEXPPercent: bonusEXPPercent
        )
    }
    
    // MARK: - Damage Calculation (Stats + Gear Driven)
    
    static func calculateDamage(
        attacker: PVPFighterStats,
        defender: PVPFighterStats,
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
        
        // Dodge check: DEX-driven
        var dodgeChance = Double(defender.spd) / (Double(defender.spd) + Double(attacker.spd) + 120.0)
        
        // Archer Quick Draw: +25% dodge in Round 1 (when defending)
        if defender.className == .archer && roundNumber == 1 {
            dodgeChance += 0.25
        }
        // Ranger Evasion Master: +15% dodge all rounds
        if defender.className == .ranger {
            dodgeChance += 0.15
        }
        // Enchanter: +10% dodge
        if defender.className == .enchanter {
            dodgeChance += 0.10
        }
        
        dodgeChance = min(0.60, dodgeChance)
        
        if Double.random(in: 0...1) < dodgeChance {
            return (0, false, true)
        }
        
        var raw = baseDamage * (1.0 - guardReduce) * (1.0 - moraleReduce)
        
        // Quirk PVP damage bonus
        if attacker.pvpDamageBonus > 0 {
            raw *= (1.0 + attacker.pvpDamageBonus / 100.0)
        }
        
        // Hero Might differential: every 100 HM above opponent = +1%
        let hmDiff = attacker.heroPower - defender.heroPower
        if hmDiff > 0 {
            let hmBonus = Double(hmDiff / 100) * 0.01
            raw *= (1.0 + min(0.15, hmBonus))
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
            case .mage:
                // Spell Penetration: ignores 15% of guard
                let guardPenBonus = effectiveGuard * 0.15 / (effectiveGuard + 80.0)
                raw *= (1.0 + guardPenBonus)
            default: break
            }
        }
        
        // Round 1: SPD advantage = +5% damage for faster fighter
        if roundNumber == 1 && attacker.spd > defender.spd {
            raw *= 1.05
        }
        
        // Round 3: +5% damage for dramatic finisher
        if roundNumber == 3 {
            raw *= 1.05
        }
        
        // Crit check
        var critChance = attacker.maxCritChance
        
        // Archer: +10% base crit
        if attacker.className == .archer {
            critChance = min(0.40, critChance + 0.10)
        }
        
        // Round 3: +50% crit chance for dramatic finisher
        if roundNumber == 3 {
            critChance = min(0.75, critChance * 1.5)
        }
        
        let isCrit = Double.random(in: 0...1) < critChance
        if isCrit {
            var critMultiplier = 1.50
            // Mage Arcane Surge: +20% crit damage
            if attacker.className == .mage {
                critMultiplier += 0.20
            }
            // Trickster: +20% crit damage
            if attacker.className == .trickster {
                critMultiplier += 0.20
            }
            raw *= critMultiplier
        }
        
        // Variance
        let variance = Double.random(in: 0.92...1.08)
        raw *= variance
        
        let finalDamage = max(1, Int(raw.rounded()))
        return (finalDamage, isCrit, false)
    }
    
    // MARK: - Apply Defensive Modifiers
    
    static func applyDefensiveModifiers(
        damage: Int,
        defender: PVPFighterStats
    ) -> Int {
        var reduced = Double(damage)
        
        // Paladin Iron Will: flat -15% damage taken
        if defender.className == .paladin {
            reduced *= 0.85
        }
        
        // Berserker: takes +10% more damage (tradeoff for massive ATK)
        if defender.className == .berserker {
            reduced *= 1.10
        }
        
        return max(1, Int(reduced.rounded()))
    }
    
    // MARK: - Resolve Full Match
    
    static func resolveMatch(
        attacker: PVPFighterStats,
        defender: PVPFighterStats
    ) -> PVPMatchResult {
        
        var attackerHP = attacker.hp
        var defenderHP = defender.hp
        var attackerTotalDamage = 0
        var defenderTotalDamage = 0
        var rounds: [PVPRoundResult] = []
        var defenderGuardReduced = false
        var attackerGuardReduced = false
        
        let roundNames = ["Opening", "Clash", "Decisive"]
        
        for roundNum in 1...3 {
            var events: [PVPRoundEvent] = []
            
            let attackerGoesFirst = roundNum == 1 ? attacker.spd >= defender.spd : true
            
            if attackerGoesFirst {
                // Attacker strikes
                let (atkDmg, atkCrit, atkDodge) = calculateDamage(
                    attacker: attacker, defender: defender,
                    roundNumber: roundNum, attackerCurrentHP: attackerHP,
                    defenderCurrentHP: defenderHP, defenderGuardReduced: defenderGuardReduced
                )
                
                let finalAtkDmg = atkDodge ? 0 : applyDefensiveModifiers(
                    damage: atkDmg, defender: defender
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
                        roundNumber: roundNum, attackerCurrentHP: defenderHP,
                        defenderCurrentHP: attackerHP, defenderGuardReduced: attackerGuardReduced
                    )
                    
                    let finalDefDmg = defDodge ? 0 : applyDefensiveModifiers(
                        damage: defDmg, defender: attacker
                    )
                    attackerHP = max(0, attackerHP - finalDefDmg)
                    defenderTotalDamage += finalDefDmg
                    
                    if defCrit && defender.className == .sorcerer {
                        attackerGuardReduced = true
                    }
                    
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
                    roundNumber: roundNum, attackerCurrentHP: defenderHP,
                    defenderCurrentHP: attackerHP, defenderGuardReduced: attackerGuardReduced
                )
                
                let finalDefDmg = defDodge ? 0 : applyDefensiveModifiers(
                    damage: defDmg, defender: attacker
                )
                attackerHP = max(0, attackerHP - finalDefDmg)
                defenderTotalDamage += finalDefDmg
                
                if defCrit && defender.className == .sorcerer {
                    attackerGuardReduced = true
                }
                
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
                        roundNumber: roundNum, attackerCurrentHP: attackerHP,
                        defenderCurrentHP: defenderHP, defenderGuardReduced: defenderGuardReduced
                    )
                    
                    let finalAtkDmg = atkDodge ? 0 : applyDefensiveModifiers(
                        damage: atkDmg, defender: defender
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
            // Also apply quirk HP regen after Round 2
            if roundNum == 2 {
                if attacker.className == .enchanter {
                    attackerHP = min(attacker.hp, attackerHP + Int(Double(attacker.hp) * 0.12))
                }
                if defender.className == .enchanter {
                    defenderHP = min(defender.hp, defenderHP + Int(Double(defender.hp) * 0.12))
                }
                if attacker.pvpHPRegenPercent > 0 {
                    attackerHP = min(attacker.hp, attackerHP + Int(Double(attacker.hp) * attacker.pvpHPRegenPercent / 100.0))
                }
                if defender.pvpHPRegenPercent > 0 {
                    defenderHP = min(defender.hp, defenderHP + Int(Double(defender.hp) * defender.pvpHPRegenPercent / 100.0))
                }
            }
            
            // Trickster: 20% chance to nullify opponent's class passive each round
            // (already handled implicitly -- Trickster has crit damage bonus instead)
            
            // Ranger: +10% damage to targets above 70% HP (applied in damage calc via raw modifier)
            
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
        
        return PVPMatchResult(
            rounds: rounds,
            winnerIsAttacker: winnerIsAttacker,
            attackerTotalDamage: attackerTotalDamage,
            defenderTotalDamage: defenderTotalDamage,
            attackerFinalHP: attackerHP,
            defenderFinalHP: defenderHP
        )
    }
    
    // MARK: - Rating Calculation
    
    static func calculateRatingChange(winnerRating: Int, loserRating: Int) -> (winnerGain: Int, loserLoss: Int) {
        let diff = loserRating - winnerRating
        
        let winnerGain: Int
        if diff > 200 {
            winnerGain = 40
        } else if diff < -200 {
            winnerGain = 12
        } else {
            winnerGain = 25
        }
        
        let loserLoss: Int
        if diff > 200 {
            loserLoss = 12
        } else if diff < -200 {
            loserLoss = 30
        } else {
            loserLoss = 20
        }
        
        return (winnerGain, loserLoss)
    }
    
    static func applyStreakBonus(baseGain: Int, streak: Int) -> Int {
        guard streak >= 3 else { return baseGain }
        return baseGain + (streak - 2) * 5
    }
    
    // MARK: - Rewards
    
    static func matchRewards(won: Bool, opponentRating: Int, playerLevel: Int, streak: Int, isRevenge: Bool, bonusAPPercent: Double = 0, bonusGoldPercent: Double = 0, bonusEXPPercent: Double = 0) -> (arenaPoints: Int, gold: Int, exp: Int) {
        if won {
            var ap = Int.random(in: 15...25)
            var gold = Int.random(in: 50...150)
            var exp = playerLevel * 3
            
            if streak >= 3 {
                ap = Int(Double(ap) * 1.5)
            }
            if isRevenge {
                ap = Int(Double(ap) * ArenaEngine.revengeBonusMultiplier)
            }
            
            // Quirk bonuses
            if bonusAPPercent > 0 {
                ap = Int(Double(ap) * (1.0 + bonusAPPercent / 100.0))
            }
            if bonusGoldPercent > 0 {
                gold = Int(Double(gold) * (1.0 + bonusGoldPercent / 100.0))
            }
            if bonusEXPPercent > 0 {
                exp = Int(Double(exp) * (1.0 + bonusEXPPercent / 100.0))
            }
            
            return (ap, gold, exp)
        } else {
            let ap = Int.random(in: 3...5)
            let exp = playerLevel * 1
            return (ap, 0, exp)
        }
    }
    
    // MARK: - Difficulty Assessment
    
    enum OpponentDifficulty: String {
        case easy = "Easy"
        case even = "Even"
        case hard = "Hard"
        
        var color: String {
            switch self {
            case .easy: return "AccentGreen"
            case .even: return "AccentGold"
            case .hard: return "AccentRed"
            }
        }
        
        var icon: String {
            switch self {
            case .easy: return "chevron.down"
            case .even: return "equal"
            case .hard: return "chevron.up"
            }
        }
    }
    
    static func assessDifficulty(playerHeroPower: Int, opponentHeroPower: Int) -> OpponentDifficulty {
        let diff = opponentHeroPower - playerHeroPower
        if diff > 150 { return .hard }
        if diff < -150 { return .easy }
        return .even
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
        
        let equippedItems = character.equipment.allEquipped
        var pvpDamageBonus: Double = 0
        var pvpHPRegenPercent: Double = 0
        
        for item in equippedItems {
            let effects = item.quirkSpecialEffects
            if let dungeonDmg = effects[.dungeonDamage] {
                pvpDamageBonus += dungeonDmg * 0.5
            }
            if let bossDmg = effects[.bossDamage] {
                pvpDamageBonus += bossDmg * 0.25
            }
            if let hpRegen = effects[.hpRegen] {
                pvpHPRegenPercent += hpRegen
            }
        }
        
        // Build equipment slot previews
        let slotPairs: [(String, Equipment?)] = [
            ("Weapon", character.equipment.weapon),
            ("Armor", character.equipment.armor),
            ("Accessory", character.equipment.accessory),
            ("Trinket", character.equipment.trinket),
            ("Cloak", character.equipment.cloak)
        ]
        let equipPreviews: [EquipmentSlotPreview] = slotPairs.compactMap { slotName, item in
            guard let item = item else { return nil }
            return EquipmentSlotPreview(
                slot: slotName,
                name: item.name,
                icon: item.imageName ?? EquipmentSlot(rawValue: slotName)?.icon ?? "questionmark",
                rarity: item.rarity.rawValue,
                equipmentLevel: item.equipmentLevel
            )
        }
        
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
            wins: character.arenaWins,
            losses: character.arenaLosses,
            streak: character.arenaStreak,
            peakRating: character.arenaPeakRating,
            recentTrend: "neutral",
            pendingRevengeIDs: [],
            arenaPoints: character.arenaPoints,
            hasBond: character.partyID != nil,
            equipmentSlots: equipPreviews,
            pvpDamageBonus: pvpDamageBonus,
            pvpHPRegenPercent: pvpHPRegenPercent
        )
    }
}
