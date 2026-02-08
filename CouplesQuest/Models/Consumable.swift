import Foundation
import SwiftData

/// Consumable items that provide temporary buffs, themed as real-world foods and items
@Model
final class Consumable {
    /// Unique identifier
    var id: UUID
    
    /// Display name
    var name: String
    
    /// Flavor description
    var consumableDescription: String
    
    /// Type of consumable effect
    var consumableType: ConsumableType
    
    /// SF Symbol icon name
    var icon: String
    
    /// Effect magnitude (HP restored, multiplier percentage, stat points, etc.)
    var effectValue: Int
    
    /// Optional stat type for stat-boosting food
    var effectStat: StatType?
    
    /// Number of uses remaining
    var remainingUses: Int
    
    /// Character ID of the owner
    var characterID: UUID
    
    init(
        name: String,
        description: String,
        consumableType: ConsumableType,
        icon: String,
        effectValue: Int,
        effectStat: StatType? = nil,
        remainingUses: Int = 1,
        characterID: UUID
    ) {
        self.id = UUID()
        self.name = name
        self.consumableDescription = description
        self.consumableType = consumableType
        self.icon = icon
        self.effectValue = effectValue
        self.effectStat = effectStat
        self.remainingUses = remainingUses
        self.characterID = characterID
    }
    
    /// Whether this consumable has uses left
    var isUsable: Bool {
        remainingUses > 0
    }
    
    /// Short effect summary for UI display
    var effectSummary: String {
        switch consumableType {
        case .hpPotion:
            return "Restore \(effectValue) HP in dungeons"
        case .expBoost:
            return "+50% EXP for \(effectValue) tasks"
        case .goldBoost:
            return "+50% Gold for \(effectValue) tasks"
        case .missionSpeedUp:
            return "Halve remaining mission time"
        case .streakShield:
            return "Protect streak for 1 day"
        case .statFood:
            if let stat = effectStat {
                return "+\(effectValue) \(stat.rawValue) (temporary)"
            }
            return "+\(effectValue) to a stat"
        }
    }
}

// MARK: - Consumable Type

enum ConsumableType: String, Codable, CaseIterable {
    case hpPotion = "HP Potion"
    case expBoost = "EXP Boost"
    case goldBoost = "Gold Boost"
    case missionSpeedUp = "Mission Speed-Up"
    case streakShield = "Streak Shield"
    case statFood = "Stat Food"
    
    var icon: String {
        switch self {
        case .hpPotion: return "cross.vial.fill"
        case .expBoost: return "arrow.up.circle.fill"
        case .goldBoost: return "dollarsign.circle.fill"
        case .missionSpeedUp: return "hare.fill"
        case .streakShield: return "shield.checkered"
        case .statFood: return "fork.knife"
        }
    }
    
    var color: String {
        switch self {
        case .hpPotion: return "StatDexterity"
        case .expBoost: return "AccentPurple"
        case .goldBoost: return "AccentGold"
        case .missionSpeedUp: return "AccentGreen"
        case .streakShield: return "AccentOrange"
        case .statFood: return "StatStrength"
        }
    }
}

// MARK: - Shop Catalog

/// Defines the fixed consumable catalog for the store
struct ConsumableCatalog {
    
    /// All purchasable consumable templates
    static let items: [ConsumableTemplate] = [
        // HP Potions
        ConsumableTemplate(
            name: "Herbal Tea",
            description: "A warm, soothing blend that restores vitality.",
            type: .hpPotion,
            icon: "cup.and.saucer.fill",
            effectValue: 20,
            effectStat: nil,
            goldCost: 30,
            gemCost: 0,
            levelRequirement: 1
        ),
        ConsumableTemplate(
            name: "Healing Draught",
            description: "A potent medicinal brew for deep restoration.",
            type: .hpPotion,
            icon: "cross.vial.fill",
            effectValue: 50,
            effectStat: nil,
            goldCost: 80,
            gemCost: 0,
            levelRequirement: 5
        ),
        // EXP Boost
        ConsumableTemplate(
            name: "Energy Bar",
            description: "A packed snack that sharpens your focus. +50% EXP for 3 tasks.",
            type: .expBoost,
            icon: "bolt.fill",
            effectValue: 3,
            effectStat: nil,
            goldCost: 60,
            gemCost: 0,
            levelRequirement: 3
        ),
        // Gold Boost
        ConsumableTemplate(
            name: "Lucky Coin",
            description: "A glimmering coin that attracts fortune. +50% Gold for 3 tasks.",
            type: .goldBoost,
            icon: "dollarsign.circle.fill",
            effectValue: 3,
            effectStat: nil,
            goldCost: 50,
            gemCost: 0,
            levelRequirement: 3
        ),
        // Mission Speed-Up
        ConsumableTemplate(
            name: "Espresso Shot",
            description: "A jolt of energy that speeds everything up.",
            type: .missionSpeedUp,
            icon: "cup.and.saucer.fill",
            effectValue: 1,
            effectStat: nil,
            goldCost: 40,
            gemCost: 0,
            levelRequirement: 5
        ),
        // Streak Shield
        ConsumableTemplate(
            name: "Cozy Blanket",
            description: "Wraps you in comfort, protecting your streak for a day.",
            type: .streakShield,
            icon: "shield.checkered",
            effectValue: 1,
            effectStat: nil,
            goldCost: 100,
            gemCost: 0,
            levelRequirement: 5
        ),
        // Stat Foods
        ConsumableTemplate(
            name: "Protein Shake",
            description: "A thick, creamy shake packed with muscle fuel.",
            type: .statFood,
            icon: "dumbbell.fill",
            effectValue: 3,
            effectStat: .strength,
            goldCost: 45,
            gemCost: 0,
            levelRequirement: 3
        ),
        ConsumableTemplate(
            name: "Green Tea",
            description: "A calming brew that clears the mind.",
            type: .statFood,
            icon: "leaf.fill",
            effectValue: 3,
            effectStat: .wisdom,
            goldCost: 45,
            gemCost: 0,
            levelRequirement: 3
        ),
        ConsumableTemplate(
            name: "Trail Mix",
            description: "A hearty snack of nuts and dried fruit for agility.",
            type: .statFood,
            icon: "carrot.fill",
            effectValue: 3,
            effectStat: .dexterity,
            goldCost: 45,
            gemCost: 0,
            levelRequirement: 3
        )
    ]
}

/// Template for a purchasable consumable (not persisted — used for shop display)
struct ConsumableTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let type: ConsumableType
    let icon: String
    let effectValue: Int
    let effectStat: StatType?
    let goldCost: Int
    let gemCost: Int
    let levelRequirement: Int
    
    /// Create a Consumable instance from this template
    func toConsumable(characterID: UUID) -> Consumable {
        Consumable(
            name: name,
            description: description,
            consumableType: type,
            icon: icon,
            effectValue: effectValue,
            effectStat: effectStat,
            remainingUses: 1,
            characterID: characterID
        )
    }
}

// MARK: - Shop Generator

/// Generates daily rotating equipment stock for the store
struct ShopGenerator {
    
    /// Generate 4 daily rotating equipment items using a date-seeded RNG
    static func dailyEquipment(characterLevel: Int, date: Date = Date()) -> [Equipment] {
        // Create deterministic seed from date
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        let seed = UInt64(year * 10000 + month * 100 + day)
        
        var rng = SeededRandomNumberGenerator(seed: seed)
        
        var items: [Equipment] = []
        let slots: [EquipmentSlot] = [.weapon, .armor, .accessory, .weapon]
        
        for i in 0..<4 {
            let tier = max(1, (characterLevel / 10) + 1)
            let luck = Int.random(in: 5...15, using: &rng)
            let item = generateShopEquipment(
                slot: slots[i],
                tier: tier,
                luck: luck,
                rng: &rng
            )
            items.append(item)
        }
        
        return items
    }
    
    /// Price for an equipment item in gold
    static func priceForEquipment(_ item: Equipment) -> Int {
        let rarityBase: Int
        switch item.rarity {
        case .common: rarityBase = 25
        case .uncommon: rarityBase = 60
        case .rare: rarityBase = 150
        case .epic: rarityBase = 400
        case .legendary: rarityBase = 1000
        }
        let statMultiplier = item.totalStatBonus * 8
        return rarityBase + statMultiplier
    }
    
    /// Time until next stock refresh
    static var timeUntilRefresh: String {
        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date())) else {
            return "—"
        }
        let remaining = Int(tomorrow.timeIntervalSince(Date()))
        let hours = remaining / 3600
        let minutes = (remaining % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
    
    // MARK: - Private
    
    private static func generateShopEquipment(
        slot: EquipmentSlot,
        tier: Int,
        luck: Int,
        rng: inout SeededRandomNumberGenerator
    ) -> Equipment {
        let rarity = LootGenerator.rollRarity(tier: tier, luck: luck)
        let primaryStat = StatType.allCases.randomElement()!
        let primaryBonus = LootGenerator.rollStatBonus(rarity: rarity)
        let secondary = LootGenerator.rollSecondaryStat(rarity: rarity, excluding: primaryStat)
        let name = LootGenerator.generateName(slot: slot, rarity: rarity, primaryStat: primaryStat)
        let description = LootGenerator.generateDescription(slot: slot, rarity: rarity)
        let levelReq = max(1, (tier - 1) * 5 + primaryBonus / 2)
        
        return Equipment(
            name: name,
            description: description,
            slot: slot,
            rarity: rarity,
            primaryStat: primaryStat,
            statBonus: primaryBonus,
            levelRequirement: levelReq,
            secondaryStat: secondary?.stat,
            secondaryStatBonus: secondary?.bonus ?? 0
        )
    }
}

// MARK: - Seeded RNG

/// A simple seeded random number generator for deterministic daily shop stock
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: UInt64) {
        self.state = seed
    }
    
    mutating func next() -> UInt64 {
        // xorshift64
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
