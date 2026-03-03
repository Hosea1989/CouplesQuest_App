import Foundation
import SwiftData

// MARK: - Quirk Category

enum QuirkCategory: String, Codable, CaseIterable {
    case positive = "Positive"
    case negative = "Negative"
    case mixed = "Mixed"
    case legendary = "Legendary"

    var color: String {
        switch self {
        case .positive: return "AccentGreen"
        case .negative: return "AccentRed"
        case .mixed: return "AccentOrange"
        case .legendary: return "RarityLegendary"
        }
    }

    var icon: String {
        switch self {
        case .positive: return "arrow.up.circle.fill"
        case .negative: return "arrow.down.circle.fill"
        case .mixed: return "arrow.up.arrow.down.circle.fill"
        case .legendary: return "star.circle.fill"
        }
    }
}

// MARK: - Special Effect Type

enum SpecialEffectType: String, Codable, CaseIterable {
    case none = "None"
    case goldPercent = "Gold%"
    case expPercent = "EXP%"
    case bossDamage = "BossDmg%"
    case lootChance = "Loot%"
    case hpRegen = "HPRegen%"
    case missionSpeed = "MissionSpd%"
    case dungeonDamage = "DungeonDmg%"
}

// MARK: - Equipment Quirk Model

@Model
final class EquipmentQuirk {
    var id: UUID
    var name: String
    var quirkDescription: String
    var category: QuirkCategory

    var statType: StatType?
    var statValue: Double

    var secondaryStatType: StatType?
    var secondaryStatValue: Double

    var specialEffect: SpecialEffectType
    var specialEffectValue: Double

    /// Which equipment level this quirk was rolled at (2-5)
    var levelGained: Int

    init(
        name: String,
        description: String,
        category: QuirkCategory,
        statType: StatType? = nil,
        statValue: Double = 0,
        secondaryStatType: StatType? = nil,
        secondaryStatValue: Double = 0,
        specialEffect: SpecialEffectType = .none,
        specialEffectValue: Double = 0,
        levelGained: Int = 2
    ) {
        self.id = UUID()
        self.name = name
        self.quirkDescription = description
        self.category = category
        self.statType = statType
        self.statValue = statValue
        self.secondaryStatType = secondaryStatType
        self.secondaryStatValue = secondaryStatValue
        self.specialEffect = specialEffect
        self.specialEffectValue = specialEffectValue
        self.levelGained = levelGained
    }

    var displayText: String {
        var parts: [String] = []

        if let stat = statType, statValue != 0 {
            let sign = statValue > 0 ? "+" : ""
            parts.append("\(sign)\(Int(statValue.rounded())) \(stat.rawValue)")
        }

        if let stat2 = secondaryStatType, secondaryStatValue != 0 {
            let sign = secondaryStatValue > 0 ? "+" : ""
            parts.append("\(sign)\(Int(secondaryStatValue.rounded())) \(stat2.rawValue)")
        }

        if specialEffect != .none, specialEffectValue != 0 {
            let sign = specialEffectValue > 0 ? "+" : ""
            let valStr = specialEffectValue == specialEffectValue.rounded()
                ? String(format: "%.0f", specialEffectValue)
                : String(format: "%.1f", specialEffectValue)
            parts.append("\(sign)\(valStr)% \(specialEffect.rawValue)")
        }

        return parts.joined(separator: ", ")
    }
}

// MARK: - Quirk Definition (non-persisted blueprint for rolling)

struct QuirkDefinition {
    let name: String
    let description: String
    let category: QuirkCategory
    let statType: StatType?
    let statRange: ClosedRange<Double>?
    let secondaryStatType: StatType?
    let secondaryStatRange: ClosedRange<Double>?
    let specialEffect: SpecialEffectType
    let specialEffectRange: ClosedRange<Double>?
    let minLevel: Int
    let legendaryOnly: Bool

    init(
        name: String,
        description: String,
        category: QuirkCategory,
        statType: StatType? = nil,
        statRange: ClosedRange<Double>? = nil,
        secondaryStatType: StatType? = nil,
        secondaryStatRange: ClosedRange<Double>? = nil,
        specialEffect: SpecialEffectType = .none,
        specialEffectRange: ClosedRange<Double>? = nil,
        minLevel: Int = 2,
        legendaryOnly: Bool = false
    ) {
        self.name = name
        self.description = description
        self.category = category
        self.statType = statType
        self.statRange = statRange
        self.secondaryStatType = secondaryStatType
        self.secondaryStatRange = secondaryStatRange
        self.specialEffect = specialEffect
        self.specialEffectRange = specialEffectRange
        self.minLevel = minLevel
        self.legendaryOnly = legendaryOnly
    }

    func roll(atLevel level: Int) -> EquipmentQuirk {
        let scale = 1.0 + Double(level - 2) * 0.25
        let primaryVal: Double = statRange.map { Double.random(in: $0) * scale } ?? 0
        let secondaryVal: Double = secondaryStatRange.map { Double.random(in: $0) * scale } ?? 0
        let effectVal: Double = specialEffectRange.map { Double.random(in: $0) * scale } ?? 0

        return EquipmentQuirk(
            name: name,
            description: description,
            category: category,
            statType: statType,
            statValue: primaryVal,
            secondaryStatType: secondaryStatType,
            secondaryStatValue: secondaryVal,
            specialEffect: specialEffect,
            specialEffectValue: effectVal,
            levelGained: level
        )
    }
}

// MARK: - Type-Based Quirk Pools

struct QuirkPool {

    /// Allowed stat types for quirk rolls based on equipment base type keyword
    static func allowedStats(for baseType: String) -> [StatType] {
        let key = baseType.lowercased()
        switch key {
        case "sword", "axe", "mace", "halberd", "spear":
            return [.strength, .dexterity, .defense]
        case "staff", "wand", "tome":
            return [.wisdom, .charisma, .luck]
        case "bow", "crossbow":
            return [.dexterity, .luck, .strength]
        case "dagger":
            return [.dexterity, .luck, .charisma]
        case "shield":
            return [.defense, .strength, .wisdom]
        case "plate", "chainmail", "breastplate", "helm", "gauntlets", "pauldrons":
            return [.defense, .strength]
        case "robes", "cape", "mantle":
            return [.wisdom, .charisma]
        case "leather armor", "boots", "greaves", "sandals":
            return [.dexterity, .defense]
        case "ring":
            return StatType.allCases
        case "amulet", "pendant":
            return [.wisdom, .charisma, .luck]
        case "earring", "brooch", "stud":
            return [.charisma, .luck]
        case "talisman":
            return [.wisdom, .luck]
        case "cloak":
            return [.dexterity, .defense]
        case "belt":
            return [.strength, .defense]
        case "bracelet", "charm":
            return [.luck, .charisma]
        default:
            return [.strength, .wisdom, .dexterity]
        }
    }

    // MARK: Positive

    static let positiveStatQuirks: [(name: String, description: String, stat: StatType)] = [
        ("Keen Edge", "Sharpened to perfection", .strength),
        ("Iron Will", "Unyielding mental fortitude", .wisdom),
        ("Charming Glow", "Radiates an enchanting aura", .charisma),
        ("True Aim", "Guided by unseen precision", .dexterity),
        ("Lucky Strike", "Fortune favors the bold", .luck),
        ("Stalwart", "Solid as a mountain", .defense),
    ]

    static let positiveSpecialQuirks: [QuirkDefinition] = [
        QuirkDefinition(name: "Battle Focus", description: "Heightened combat instincts", category: .positive,
                        specialEffect: .dungeonDamage, specialEffectRange: 2.0...6.0),
        QuirkDefinition(name: "Scholar's Touch", description: "Knowledge flows freely", category: .positive,
                        specialEffect: .expPercent, specialEffectRange: 2.0...6.0),
        QuirkDefinition(name: "Prospector", description: "Gold glints in every shadow", category: .positive,
                        specialEffect: .goldPercent, specialEffectRange: 2.0...6.0),
        QuirkDefinition(name: "Treasure Sense", description: "Attuned to hidden riches", category: .positive,
                        specialEffect: .lootChance, specialEffectRange: 1.5...5.0, minLevel: 3),
        QuirkDefinition(name: "Expedition Haste", description: "Missions complete swiftly", category: .positive,
                        specialEffect: .missionSpeed, specialEffectRange: 3.0...8.0, minLevel: 3),
    ]

    // MARK: Negative

    static let negativeStatQuirks: [(name: String, description: String, stat: StatType)] = [
        ("Heavy", "Weighs down movement", .dexterity),
        ("Fragile", "Cracks under pressure", .defense),
        ("Unwieldy", "Awkward to handle", .strength),
        ("Dull Aura", "Lacks presence", .charisma),
        ("Clouded", "Obscures clear thought", .wisdom),
        ("Jinxed", "Cursed with misfortune", .luck),
    ]

    static let negativeSpecialQuirks: [QuirkDefinition] = [
        QuirkDefinition(name: "Cursed Aura", description: "Gold slips through your fingers", category: .negative,
                        specialEffect: .goldPercent, specialEffectRange: (-5.0)...(-1.5)),
        QuirkDefinition(name: "Draining", description: "Saps your learning", category: .negative,
                        specialEffect: .expPercent, specialEffectRange: (-5.0)...(-1.5)),
    ]

    // MARK: Mixed

    static let mixedQuirks: [(name: String, description: String, positiveStat: StatType, negativeStat: StatType)] = [
        ("Berserker's Edge", "Power at the cost of protection", .strength, .defense),
        ("Glass Cannon", "Arcane might, brittle form", .wisdom, .defense),
        ("Fortune's Gamble", "Lucky but reckless", .luck, .wisdom),
        ("Swift but Fragile", "Fast but breakable", .dexterity, .strength),
        ("Intimidating Presence", "Commands fear, repels fortune", .charisma, .luck),
        ("Reckless Charge", "Hits hard, leaves openings", .strength, .dexterity),
        ("Mystic Trance", "Deep insight, slow reflexes", .wisdom, .dexterity),
        ("Silver Tongue", "Charming but physically weak", .charisma, .strength),
    ]

    // MARK: Legendary

    /// Universal legendary quirks (any equipment type)
    static let legendaryQuirksUniversal: [QuirkDefinition] = [
        QuirkDefinition(name: "Champion's Aura", description: "Radiates power in all forms", category: .legendary,
                        minLevel: 5, legendaryOnly: true),
        QuirkDefinition(name: "Fate's Favor", description: "Destiny bends to your will", category: .legendary,
                        statType: .luck, statRange: 5.0...8.0,
                        specialEffect: .lootChance, specialEffectRange: 15.0...25.0,
                        minLevel: 5, legendaryOnly: true),
    ]
    
    /// Weapon-specific legendary quirks
    static let legendaryQuirksWeapon: [QuirkDefinition] = [
        QuirkDefinition(name: "Dragonslayer's Fury", description: "Forged in dragon fire, hungering for ancient blood", category: .legendary,
                        statType: .strength, statRange: 5.0...8.0,
                        specialEffect: .bossDamage, specialEffectRange: 10.0...15.0,
                        minLevel: 5, legendaryOnly: true),
        QuirkDefinition(name: "Vorpal Edge", description: "Cuts through reality itself", category: .legendary,
                        statType: .dexterity, statRange: 4.0...7.0,
                        specialEffect: .dungeonDamage, specialEffectRange: 8.0...12.0,
                        minLevel: 5, legendaryOnly: true),
        QuirkDefinition(name: "Soul Harvest", description: "Each strike siphons life force", category: .legendary,
                        statType: .strength, statRange: 3.0...6.0,
                        specialEffect: .hpRegen, specialEffectRange: 2.0...4.0,
                        minLevel: 5, legendaryOnly: true),
    ]
    
    /// Armor-specific legendary quirks
    static let legendaryQuirksArmor: [QuirkDefinition] = [
        QuirkDefinition(name: "Eternal Guardian", description: "An ancient protector's blessing woven into the metal", category: .legendary,
                        statType: .defense, statRange: 6.0...10.0,
                        specialEffect: .hpRegen, specialEffectRange: 1.5...3.0,
                        minLevel: 5, legendaryOnly: true),
        QuirkDefinition(name: "Titan's Bulwark", description: "Forged from the bones of a fallen titan", category: .legendary,
                        statType: .defense, statRange: 8.0...12.0,
                        specialEffect: .bossDamage, specialEffectRange: 5.0...8.0,
                        minLevel: 5, legendaryOnly: true),
    ]
    
    /// Accessory-specific legendary quirks
    static let legendaryQuirksAccessory: [QuirkDefinition] = [
        QuirkDefinition(name: "Abyssal Whisper", description: "Echoes of forbidden knowledge from the deep", category: .legendary,
                        statType: .wisdom, statRange: 5.0...8.0,
                        specialEffect: .expPercent, specialEffectRange: 5.0...8.0,
                        minLevel: 5, legendaryOnly: true),
        QuirkDefinition(name: "Midas Touch", description: "Everything you touch turns to gold", category: .legendary,
                        statType: .charisma, statRange: 4.0...7.0,
                        specialEffect: .goldPercent, specialEffectRange: 10.0...18.0,
                        minLevel: 5, legendaryOnly: true),
    ]
    
    /// Trinket-specific legendary quirks
    static let legendaryQuirksTrinket: [QuirkDefinition] = [
        QuirkDefinition(name: "Chrono Shard", description: "A fragment of frozen time", category: .legendary,
                        statType: .wisdom, statRange: 4.0...7.0,
                        specialEffect: .missionSpeed, specialEffectRange: 15.0...25.0,
                        minLevel: 5, legendaryOnly: true),
        QuirkDefinition(name: "Philosopher's Core", description: "Contains the distilled essence of all knowledge", category: .legendary,
                        statType: .wisdom, statRange: 6.0...9.0,
                        specialEffect: .expPercent, specialEffectRange: 6.0...10.0,
                        minLevel: 5, legendaryOnly: true),
    ]
    
    /// Cloak-specific legendary quirks
    static let legendaryQuirksCloak: [QuirkDefinition] = [
        QuirkDefinition(name: "Shadow Sovereign", description: "The darkness obeys your command", category: .legendary,
                        statType: .dexterity, statRange: 5.0...8.0,
                        specialEffect: .dungeonDamage, specialEffectRange: 6.0...10.0,
                        minLevel: 5, legendaryOnly: true),
        QuirkDefinition(name: "Windwalker's Mantle", description: "Woven from captured breezes", category: .legendary,
                        statType: .dexterity, statRange: 4.0...7.0,
                        specialEffect: .missionSpeed, specialEffectRange: 10.0...18.0,
                        minLevel: 5, legendaryOnly: true),
    ]
    
    /// Get the legendary quirk pool for a given base type
    static func legendaryQuirks(for baseType: String) -> [QuirkDefinition] {
        let lower = baseType.lowercased()
        var pool: [QuirkDefinition] = legendaryQuirksUniversal
        
        let weaponTypes = ["sword", "axe", "bow", "staff", "dagger", "mace", "wand", "spear", "greatsword", "blade"]
        let armorTypes = ["armor", "plate", "robe", "chainmail", "vest", "tunic", "mail"]
        let accessoryTypes = ["amulet", "ring", "necklace", "pendant", "bracelet"]
        let trinketTypes = ["trinket", "charm", "relic", "totem", "orb"]
        let cloakTypes = ["cloak", "cape", "mantle", "shroud"]
        
        if weaponTypes.contains(where: { lower.contains($0) }) {
            pool.append(contentsOf: legendaryQuirksWeapon)
        } else if armorTypes.contains(where: { lower.contains($0) }) {
            pool.append(contentsOf: legendaryQuirksArmor)
        } else if accessoryTypes.contains(where: { lower.contains($0) }) {
            pool.append(contentsOf: legendaryQuirksAccessory)
        } else if trinketTypes.contains(where: { lower.contains($0) }) {
            pool.append(contentsOf: legendaryQuirksTrinket)
        } else if cloakTypes.contains(where: { lower.contains($0) }) {
            pool.append(contentsOf: legendaryQuirksCloak)
        } else {
            pool.append(contentsOf: legendaryQuirksWeapon)
        }
        
        return pool
    }
}

// MARK: - Quirk Roller

struct QuirkRoller {

    /// Category probability weights adjusted by equipment level and item rarity
    static func categoryWeights(equipmentLevel: Int, rarity: ItemRarity) -> (positive: Double, mixed: Double, negative: Double) {
        var pos: Double
        var mix: Double
        var neg: Double

        switch equipmentLevel {
        case 2:  pos = 0.50; mix = 0.30; neg = 0.20
        case 3:  pos = 0.55; mix = 0.30; neg = 0.15
        case 4:  pos = 0.60; mix = 0.30; neg = 0.10
        default: pos = 0.65; mix = 0.30; neg = 0.05
        }

        let shift: Double
        switch rarity {
        case .common:    shift = 0
        case .uncommon:  shift = 0.05
        case .rare:      shift = 0.10
        case .epic:      shift = 0.15
        case .legendary: shift = 0.20
        }

        pos = min(pos + shift, 0.95)
        neg = max(neg - shift, 0.0)
        mix = 1.0 - pos - neg

        return (pos, mix, neg)
    }

    /// Roll a single quirk for equipment at a given level
    static func rollQuirk(
        equipmentLevel: Int,
        itemRarity: ItemRarity,
        baseType: String,
        existingQuirks: [EquipmentQuirk] = []
    ) -> EquipmentQuirk {
        let allowed = QuirkPool.allowedStats(for: baseType)
        let w = categoryWeights(equipmentLevel: equipmentLevel, rarity: itemRarity)

        if itemRarity == .legendary && equipmentLevel >= 5 {
            if Double.random(in: 0...1) < 0.40 {
                let pool = QuirkPool.legendaryQuirks(for: baseType)
                let avail = pool.filter { d in
                    !existingQuirks.contains(where: { $0.name == d.name })
                }
                if let def = avail.randomElement() {
                    if def.name == "Champion's Aura" {
                        return rollChampionsAura(atLevel: equipmentLevel)
                    }
                    return def.roll(atLevel: equipmentLevel)
                }
            }
        }

        let roll = Double.random(in: 0...1)
        if roll < w.positive {
            return rollPositive(level: equipmentLevel, allowed: allowed, existing: existingQuirks)
        } else if roll < w.positive + w.mixed {
            return rollMixed(level: equipmentLevel, allowed: allowed, existing: existingQuirks)
        } else {
            return rollNegative(level: equipmentLevel, allowed: allowed, existing: existingQuirks)
        }
    }

    // MARK: - Private

    private static func rollPositive(level: Int, allowed: [StatType], existing: [EquipmentQuirk]) -> EquipmentQuirk {
        if Double.random(in: 0...1) < 0.3 {
            let avail = QuirkPool.positiveSpecialQuirks.filter { def in
                def.minLevel <= level && !existing.contains(where: { $0.name == def.name })
            }
            if let def = avail.randomElement() { return def.roll(atLevel: level) }
        }

        let matching = QuirkPool.positiveStatQuirks.filter { allowed.contains($0.stat) }
        let avail = matching.filter { e in !existing.contains(where: { $0.name == e.name }) }
        let pick = (avail.isEmpty ? matching : avail).randomElement()
            ?? (name: "Empowered", description: "A surge of raw power", stat: allowed.randomElement() ?? .strength)

        let range = statRange(for: .positive, level: level)
        return EquipmentQuirk(
            name: pick.name, description: pick.description, category: .positive,
            statType: pick.stat, statValue: Double.random(in: range), levelGained: level
        )
    }

    private static func rollNegative(level: Int, allowed: [StatType], existing: [EquipmentQuirk]) -> EquipmentQuirk {
        if Double.random(in: 0...1) < 0.25 {
            let avail = QuirkPool.negativeSpecialQuirks.filter { def in
                !existing.contains(where: { $0.name == def.name })
            }
            if let def = avail.randomElement() { return def.roll(atLevel: level) }
        }

        let matching = QuirkPool.negativeStatQuirks.filter { allowed.contains($0.stat) }
        let avail = matching.filter { e in !existing.contains(where: { $0.name == e.name }) }
        let pick = (avail.isEmpty ? matching : avail).randomElement()
            ?? (name: "Worn", description: "Showing signs of wear", stat: allowed.randomElement() ?? .defense)

        let range = statRange(for: .negative, level: level)
        return EquipmentQuirk(
            name: pick.name, description: pick.description, category: .negative,
            statType: pick.stat, statValue: -Double.random(in: range), levelGained: level
        )
    }

    private static func rollMixed(level: Int, allowed: [StatType], existing: [EquipmentQuirk]) -> EquipmentQuirk {
        let matching = QuirkPool.mixedQuirks.filter {
            allowed.contains($0.positiveStat) || allowed.contains($0.negativeStat)
        }
        let avail = matching.filter { e in !existing.contains(where: { $0.name == e.name }) }

        guard let pick = (avail.isEmpty ? matching : avail).randomElement() else {
            let s = allowed.count >= 2 ? Array(allowed.shuffled().prefix(2)) : [allowed.first ?? .strength, .defense]
            let sc = levelScale(level)
            return EquipmentQuirk(
                name: "Volatile", description: "Unstable energies within", category: .mixed,
                statType: s[0], statValue: Double.random(in: 2.0...4.0) * sc,
                secondaryStatType: s[1], secondaryStatValue: -Double.random(in: 1.0...2.5) * sc,
                levelGained: level
            )
        }

        let posR = statRange(for: .positive, level: level)
        let negR = statRange(for: .negative, level: level)
        return EquipmentQuirk(
            name: pick.name, description: pick.description, category: .mixed,
            statType: pick.positiveStat, statValue: Double.random(in: posR) * 1.2,
            secondaryStatType: pick.negativeStat, secondaryStatValue: -Double.random(in: negR) * 0.8,
            levelGained: level
        )
    }

    private static func rollChampionsAura(atLevel level: Int) -> EquipmentQuirk {
        let v = Double.random(in: 2.0...4.0) * levelScale(level)
        return EquipmentQuirk(
            name: "Champion's Aura", description: "Radiates power in all forms", category: .legendary,
            statType: .strength, statValue: v,
            secondaryStatType: .wisdom, secondaryStatValue: v,
            levelGained: level
        )
    }

    // MARK: - Helpers

    private static func statRange(for category: QuirkCategory, level: Int) -> ClosedRange<Double> {
        let sc = levelScale(level)
        switch category {
        case .positive, .legendary: return (1.0 * sc)...(3.5 * sc)
        case .negative:             return (0.5 * sc)...(2.0 * sc)
        case .mixed:                return (1.5 * sc)...(3.0 * sc)
        }
    }

    private static func levelScale(_ level: Int) -> Double {
        1.0 + Double(level - 2) * 0.25
    }

    // MARK: - Diminishing Returns

    /// Stacking the same stat from multiple quirks yields progressively less.
    /// 1st source: 100%, 2nd: 90%, 3rd: 75%, 4th+: 60%
    static func applyDiminishingReturns(_ bonuses: [Double]) -> Double {
        let sorted = bonuses.sorted(by: { abs($0) > abs($1) })
        let mults: [Double] = [1.0, 0.9, 0.75, 0.6]
        var total = 0.0
        for (i, b) in sorted.enumerated() {
            total += b * (i < mults.count ? mults[i] : 0.5)
        }
        return total
    }

    /// Aggregate all quirk stat bonuses with diminishing returns per stat type.
    static func aggregateQuirkBonuses(_ quirks: [EquipmentQuirk]) -> [StatType: Double] {
        var raw: [StatType: [Double]] = [:]
        for q in quirks {
            if let s = q.statType, q.statValue != 0 { raw[s, default: []].append(q.statValue) }
            if let s = q.secondaryStatType, q.secondaryStatValue != 0 { raw[s, default: []].append(q.secondaryStatValue) }
        }
        var result: [StatType: Double] = [:]
        for (stat, vals) in raw { result[stat] = applyDiminishingReturns(vals) }
        return result
    }

    /// Aggregate special effect percentages (additive, no diminishing returns).
    static func aggregateSpecialEffects(_ quirks: [EquipmentQuirk]) -> [SpecialEffectType: Double] {
        var result: [SpecialEffectType: Double] = [:]
        for q in quirks where q.specialEffect != .none {
            result[q.specialEffect, default: 0] += q.specialEffectValue
        }
        return result
    }
}
