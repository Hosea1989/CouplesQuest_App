import Foundation
import SwiftData
import UIKit

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
    
    /// Resolved image asset name, using tiered/variant images when available
    var imageName: String? {
        consumableType.imageName(effectValue: effectValue, effectStat: effectStat)
    }
    
    /// Whether this consumable has uses left
    var isUsable: Bool {
        remainingUses > 0
    }
    
    /// Short effect summary for UI display
    var effectSummary: String {
        switch consumableType {
        case .hpPotion:
            return "Restore \(effectValue) HP"
        case .expBoost:
            return "+50% EXP for \(effectValue) tasks"
        case .goldBoost:
            return "+50% Gold for \(effectValue) tasks"
        case .missionSpeedUp:
            return "Halve remaining mission time"
        case .streakShield:
            let days = effectValue > 1 ? "\(effectValue) days" : "1 day"
            return "Protect streak for \(days)"
        case .statFood:
            if let stat = effectStat {
                return "+\(effectValue) \(stat.rawValue) (temporary)"
            }
            return "+\(effectValue) to a stat"
        case .regenBuff:
            return "Boost HP regen to \(effectValue) HP/hr"
        case .dungeonRevive:
            return "Revive party in a failed dungeon"
        case .lootReroll:
            return "Re-roll stats on one equipment piece"
        case .materialMagnet:
            return "Double material drops for \(effectValue) tasks"
        case .luckElixir:
            return "+20% rare drop chance for next dungeon"
        case .partyBeacon:
            return "+25% party bond EXP for 1 hour"
        case .affixScroll:
            return "Guarantees at least 1 affix on next equip drop"
        case .dutyScroll:
            return "Grants a random active duty from the pool"
        case .forgeCatalyst:
            return "Double enhancement success chance for 1 attempt"
        case .expeditionCompass:
            return "Reveals next expedition stage rewards"
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
    case dungeonRevive = "Dungeon Revive"
    case lootReroll = "Loot Reroll"
    case materialMagnet = "Material Magnet"
    case luckElixir = "Luck Elixir"
    case partyBeacon = "Party Beacon"
    case affixScroll = "Affix Scroll"
    case dutyScroll = "Duty Scroll"
    case forgeCatalyst = "Forge Catalyst"
    case expeditionCompass = "Expedition Compass"
    case regenBuff = "Regen Buff"
    
    var icon: String {
        switch self {
        case .hpPotion: return "cross.vial.fill"
        case .expBoost: return "arrow.up.circle.fill"
        case .goldBoost: return "dollarsign.circle.fill"
        case .missionSpeedUp: return "hare.fill"
        case .streakShield: return "shield.checkered"
        case .statFood: return "fork.knife"
        case .dungeonRevive: return "arrow.counterclockwise.circle.fill"
        case .lootReroll: return "dice.fill"
        case .materialMagnet: return "magnet"
        case .luckElixir: return "sparkles"
        case .partyBeacon: return "antenna.radiowaves.left.and.right"
        case .affixScroll: return "scroll.fill"
        case .dutyScroll: return "scroll"
        case .forgeCatalyst: return "bolt.trianglebadge.exclamationmark.fill"
        case .expeditionCompass: return "safari.fill"
        case .regenBuff: return "heart.circle.fill"
        }
    }
    
    /// Base image name without variant suffix
    var baseImageName: String {
        switch self {
        case .hpPotion: return "consumable-hpPotion"
        case .expBoost: return "consumable-expBoost"
        case .goldBoost: return "consumable-goldBoost"
        case .missionSpeedUp: return "consumable-missionSpeedUp"
        case .streakShield: return "consumable-streakShield"
        case .statFood: return "consumable-statFood"
        case .regenBuff: return "consumable-regenBuff"
        case .dungeonRevive: return "consumable-dungeonRevive"
        case .lootReroll: return "consumable-lootReroll"
        case .materialMagnet: return "consumable-materialMagnet"
        case .luckElixir: return "consumable-luckElixir"
        case .partyBeacon: return "consumable-partyBeacon"
        case .affixScroll: return "consumable-affixScroll"
        case .dutyScroll: return "consumable-dutyScroll"
        case .forgeCatalyst: return "consumable-forgeCatalyst"
        case .expeditionCompass: return "consumable-expeditionCompass"
        }
    }
    
    /// Simple image name (base only, no variant). Used when no context is available.
    var imageName: String? {
        let base = baseImageName
        if UIImage(named: base) != nil { return base }
        return nil
    }
    
    /// Variant-aware image name that picks tiered HP potion or stat-specific food images when available.
    func imageName(effectValue: Int, effectStat: StatType?) -> String? {
        let base = baseImageName
        
        // HP Potions: map effectValue to tier 1-4
        if self == .hpPotion {
            let tier: Int
            switch effectValue {
            case ...25: tier = 1
            case 26...75: tier = 2
            case 76...150: tier = 3
            default: tier = 4
            }
            let tiered = "\(base)-\(tier)"
            if UIImage(named: tiered) != nil { return tiered }
        }
        
        // Stat Food: map effectStat to variant
        if self == .statFood, let stat = effectStat {
            let variant = "\(base)-\(stat.rawValue.lowercased())"
            if UIImage(named: variant) != nil { return variant }
        }
        
        if UIImage(named: base) != nil { return base }
        return nil
    }
    
    var color: String {
        switch self {
        case .hpPotion: return "StatDexterity"
        case .expBoost: return "AccentPurple"
        case .goldBoost: return "AccentGold"
        case .missionSpeedUp: return "AccentGreen"
        case .streakShield: return "AccentOrange"
        case .statFood: return "StatStrength"
        case .dungeonRevive: return "DifficultyHard"
        case .lootReroll: return "AccentPurple"
        case .materialMagnet: return "AccentPurple"
        case .luckElixir: return "AccentGreen"
        case .partyBeacon: return "AccentPink"
        case .affixScroll: return "AccentGold"
        case .dutyScroll: return "AccentOrange"
        case .forgeCatalyst: return "ForgeEmber"
        case .expeditionCompass: return "AccentGreen"
        case .regenBuff: return "AccentPink"
        }
    }
    
    /// Whether this consumable type is a premium (gem-only) item
    var isPremium: Bool {
        switch self {
        case .dungeonRevive, .lootReroll: return true
        default: return false
        }
    }
}

// MARK: - Shop Catalog

/// Defines the fixed consumable catalog for the store.
/// Prefers server-driven consumable definitions from ContentManager when available.
struct ConsumableCatalog {
    
    // MARK: - Server-Driven Accessors (with static fallback)
    
    /// Gold-purchasable consumables — server-driven or static fallback
    @MainActor
    static var activeGoldItems: [ConsumableTemplate] {
        let cm = ContentManager.shared
        if cm.isLoaded && !cm.consumables.isEmpty {
            return cm.goldConsumables().map { mapToTemplate($0) }
        }
        return goldItems + newForgeItems
    }
    
    /// Gem-purchasable consumables — server-driven or static fallback
    @MainActor
    static var activeGemItems: [ConsumableTemplate] {
        let cm = ContentManager.shared
        if cm.isLoaded && !cm.consumables.isEmpty {
            return cm.gemConsumables().map { mapToTemplate($0) }
        }
        return gemItems
    }
    
    /// Map a ContentConsumable to a ConsumableTemplate
    private static func mapToTemplate(_ cc: ContentConsumable) -> ConsumableTemplate {
        let type = consumableTypeFrom(cc.consumableType) ?? .hpPotion
        let stat = cc.effectStat.flatMap { StatType(rawValue: $0.capitalized) }
        return ConsumableTemplate(
            name: cc.name,
            description: cc.description,
            type: type,
            icon: cc.icon,
            effectValue: cc.effectValue,
            effectStat: stat,
            goldCost: cc.goldCost,
            gemCost: cc.gemCost,
            levelRequirement: cc.levelRequirement
        )
    }
    
    /// Map server consumable_type string to local enum
    private static func consumableTypeFrom(_ raw: String) -> ConsumableType? {
        switch raw {
        case "hp_potion": return .hpPotion
        case "exp_boost": return .expBoost
        case "gold_boost": return .goldBoost
        case "mission_speed_up": return .missionSpeedUp
        case "streak_shield": return .streakShield
        case "stat_food": return .statFood
        case "dungeon_revive": return .dungeonRevive
        case "loot_reroll": return .lootReroll
        case "material_magnet": return .materialMagnet
        case "luck_elixir": return .luckElixir
        case "party_beacon": return .partyBeacon
        case "affix_scroll": return .affixScroll
        case "duty_scroll": return .dutyScroll
        case "forge_catalyst": return .forgeCatalyst
        case "expedition_compass": return .expeditionCompass
        case "regen_buff": return .regenBuff
        default: return nil
        }
    }
    
    // MARK: - Static Fallback Data
    
    /// Gold-purchasable consumable templates (1 item per unique sprite)
    static let goldItems: [ConsumableTemplate] = [
        // HP Potions — 4 tiers, each with unique sprite (hpPotion-1 through -4)
        ConsumableTemplate(
            name: "Minor Healing Potion",
            description: "A small vial of restorative red liquid.",
            type: .hpPotion,
            icon: "cross.vial.fill",
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
        ConsumableTemplate(
            name: "Greater Healing Draught",
            description: "A masterfully brewed elixir of powerful restoration.",
            type: .hpPotion,
            icon: "cross.vial.fill",
            effectValue: 100,
            effectStat: nil,
            goldCost: 200,
            gemCost: 0,
            levelRequirement: 15
        ),
        ConsumableTemplate(
            name: "Supreme Elixir",
            description: "A legendary potion that can mend even the gravest wounds.",
            type: .hpPotion,
            icon: "cross.vial.fill",
            effectValue: 200,
            effectStat: nil,
            goldCost: 500,
            gemCost: 0,
            levelRequirement: 30
        ),
        // EXP Boost — 1 sprite
        ConsumableTemplate(
            name: "Arcane Star",
            description: "A mystical star charm that amplifies experience gained. +50% EXP for 3 tasks.",
            type: .expBoost,
            icon: "star.fill",
            effectValue: 3,
            effectStat: nil,
            goldCost: 60,
            gemCost: 0,
            levelRequirement: 3
        ),
        // Gold Boost — 1 sprite
        ConsumableTemplate(
            name: "Fortune Tonic",
            description: "A shimmering golden brew that attracts wealth. +50% Gold for 3 tasks.",
            type: .goldBoost,
            icon: "dollarsign.circle.fill",
            effectValue: 3,
            effectStat: nil,
            goldCost: 50,
            gemCost: 0,
            levelRequirement: 3
        ),
        // Mission Speed-Up — 1 sprite
        ConsumableTemplate(
            name: "Swiftness Potion",
            description: "A vibrant elixir that accelerates everything around you.",
            type: .missionSpeedUp,
            icon: "hare.fill",
            effectValue: 1,
            effectStat: nil,
            goldCost: 40,
            gemCost: 0,
            levelRequirement: 5
        ),
        // Streak Shield — 1 sprite
        ConsumableTemplate(
            name: "Guardian Flask",
            description: "A calming blue potion that shields your daily streak for a day.",
            type: .streakShield,
            icon: "shield.checkered",
            effectValue: 1,
            effectStat: nil,
            goldCost: 100,
            gemCost: 0,
            levelRequirement: 5
        ),
        // Stat Foods — 3 sprites (1 per stat variant)
        ConsumableTemplate(
            name: "Hearty Steak",
            description: "A thick, juicy cut of meat that fuels raw strength.",
            type: .statFood,
            icon: "flame.fill",
            effectValue: 3,
            effectStat: .strength,
            goldCost: 45,
            gemCost: 0,
            levelRequirement: 3
        ),
        ConsumableTemplate(
            name: "Mystic Mushroom",
            description: "An enchanted mushroom that sharpens the mind.",
            type: .statFood,
            icon: "sparkle",
            effectValue: 3,
            effectStat: .wisdom,
            goldCost: 45,
            gemCost: 0,
            levelRequirement: 3
        ),
        ConsumableTemplate(
            name: "Swift Apple",
            description: "A crisp, enchanted apple that quickens reflexes.",
            type: .statFood,
            icon: "leaf.fill",
            effectValue: 3,
            effectStat: .dexterity,
            goldCost: 45,
            gemCost: 0,
            levelRequirement: 3
        ),
    ]
    
    // MARK: - New Consumable Types (Forge & Economy Update)
    
    /// Enchantment Elixir — guarantees an affix on next equipment drop
    static let affixScrollItem = ConsumableTemplate(
        name: "Enchantment Elixir",
        description: "A mystical purple elixir that guarantees at least one affix on your next equipment drop.",
        type: .affixScroll,
        icon: "wand.and.stars",
        effectValue: 1,
        effectStat: nil,
        goldCost: 800,
        gemCost: 0,
        levelRequirement: 20
    )
    
    /// Duty Scroll — grants a random active duty when used
    static let dutyScrollItem = ConsumableTemplate(
        name: "Duty Scroll",
        description: "An ancient scroll that reveals a hidden duty. Use to add a random duty to your active list.",
        type: .dutyScroll,
        icon: "scroll",
        effectValue: 1,
        effectStat: nil,
        goldCost: 0,
        gemCost: 0,
        levelRequirement: 1
    )
    
    /// Forge Tonic — doubles enhancement success for 1 attempt
    static let forgeCatalystItem = ConsumableTemplate(
        name: "Forge Tonic",
        description: "A volatile crimson brew that doubles enhancement success chance for one attempt.",
        type: .forgeCatalyst,
        icon: "bolt.trianglebadge.exclamationmark.fill",
        effectValue: 1,
        effectStat: nil,
        goldCost: 500,
        gemCost: 0,
        levelRequirement: 15
    )
    
    /// Lodestone Crystal — double material drops for 5 tasks
    static let materialMagnetItem = ConsumableTemplate(
        name: "Lodestone Crystal",
        description: "A crystallized lodestone that attracts crafting materials. Double drops for 5 tasks.",
        type: .materialMagnet,
        icon: "diamond.fill",
        effectValue: 5,
        effectStat: nil,
        goldCost: 200,
        gemCost: 0,
        levelRequirement: 10
    )
    
    /// Luck Elixir — +20% rare drop chance for next dungeon
    static let luckElixirItem = ConsumableTemplate(
        name: "Luck Elixir",
        description: "A shimmering potion that attracts fortune. +20% rare drop chance for your next dungeon.",
        type: .luckElixir,
        icon: "sparkles",
        effectValue: 20,
        effectStat: nil,
        goldCost: 350,
        gemCost: 0,
        levelRequirement: 15
    )
    
    /// Bond Totem — +25% bond EXP for 1 hour
    static let partyBeaconItem = ConsumableTemplate(
        name: "Bond Totem",
        description: "A radiant totem that strengthens party bonds. +25% bond EXP for 1 hour.",
        type: .partyBeacon,
        icon: "antenna.radiowaves.left.and.right",
        effectValue: 25,
        effectStat: nil,
        goldCost: 400,
        gemCost: 0,
        levelRequirement: 10
    )
    
    /// Wayfinder Vial — reveals next expedition stage rewards
    static let expeditionCompassItem = ConsumableTemplate(
        name: "Wayfinder Vial",
        description: "A mystical blue potion that reveals what lies ahead. Shows the next expedition stage rewards.",
        type: .expeditionCompass,
        icon: "safari.fill",
        effectValue: 1,
        effectStat: nil,
        goldCost: 500,
        gemCost: 0,
        levelRequirement: 15
    )
    
    /// Premium gem-only consumable templates
    static let gemItems: [ConsumableTemplate] = [
        ConsumableTemplate(
            name: "Revival Elixir",
            description: "A golden elixir with phoenix essence that can revive a fallen dungeon party.",
            type: .dungeonRevive,
            icon: "arrow.counterclockwise.circle.fill",
            effectValue: 1,
            effectStat: nil,
            goldCost: 0,
            gemCost: 5,
            levelRequirement: 10
        ),
        ConsumableTemplate(
            name: "Fate Idol",
            description: "A magical idol that reshapes an equipment piece's stats.",
            type: .lootReroll,
            icon: "dice.fill",
            effectValue: 1,
            effectStat: nil,
            goldCost: 0,
            gemCost: 3,
            levelRequirement: 10
        ),
    ]
    
    /// All purchasable consumable templates (gold + gem + new types combined for legacy compatibility)
    static let items: [ConsumableTemplate] = goldItems + newForgeItems + gemItems
    
    /// Level-scaled store price for a gold-purchasable consumable.
    /// Base prices stay affordable early; higher-level players pay more to keep consumables meaningful.
    static func storePrice(template: ConsumableTemplate, playerLevel: Int) -> Int {
        guard template.goldCost > 0 else { return template.goldCost }
        let multiplier = max(1.0, 1.0 + Double(playerLevel - 5) * 0.04)
        return max(template.goldCost, Int(Double(template.goldCost) * multiplier))
    }
    
    /// New forge/economy consumable items available for gold
    static let newForgeItems: [ConsumableTemplate] = [
        affixScrollItem,
        forgeCatalystItem,
        materialMagnetItem,
        luckElixirItem,
        partyBeaconItem,
        expeditionCompassItem,
        regenItem,
    ]
    
    // MARK: - Regen Buff Item
    
    /// Vitality Elixir — 100 HP/hr for 8 hours
    static let regenItem = ConsumableTemplate(
        name: "Vitality Elixir",
        description: "A potent heart-shaped elixir that significantly boosts recovery. 100 HP/hr for 8 hours.",
        type: .regenBuff,
        icon: "heart.circle.fill",
        effectValue: 100,
        effectStat: nil,
        goldCost: 400,
        gemCost: 0,
        levelRequirement: 15
    )
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
    
    /// Resolved image asset name, using tiered/variant images when available
    var imageName: String? {
        type.imageName(effectValue: effectValue, effectStat: effectStat)
    }
    
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
    
    /// Generate 10 daily rotating equipment items using a date-seeded RNG
    static func dailyEquipment(characterLevel: Int, date: Date = Date()) -> [Equipment] {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        let seed = UInt64(year * 10000 + month * 100 + day)
        
        var rng = SeededRandomNumberGenerator(seed: seed)
        
        // Guarantee at least one item per slot, then fill remaining with random slots
        var items: [Equipment] = []
        let allSlots: [EquipmentSlot] = EquipmentSlot.allCases
        
        for slot in allSlots {
            let tier = max(1, (characterLevel / 10) + 1)
            let luck = Int.random(in: 5...15, using: &rng)
            let item = generateShopEquipment(slot: slot, tier: tier, luck: luck, rng: &rng)
            items.append(item)
        }
        
        // Fill to 10 with random slots
        for _ in items.count..<10 {
            let slot = allSlots[Int(rng.next() % UInt64(allSlots.count))]
            let tier = max(1, (characterLevel / 10) + 1)
            let luck = Int.random(in: 5...15, using: &rng)
            let item = generateShopEquipment(slot: slot, tier: tier, luck: luck, rng: &rng)
            items.append(item)
        }
        
        return items
    }
    
    /// Price for an equipment item in gold
    static func priceForEquipment(_ item: Equipment) -> Int {
        let rarityBase: Int
        switch item.rarity {
        case .common: rarityBase = 75
        case .uncommon: rarityBase = 200
        case .rare: rarityBase = 600
        case .epic: rarityBase = 2500
        case .legendary: rarityBase = 6000
        }
        let statMultiplier = Int(item.totalStatBonus.rounded()) * 15
        let levelScale = 1.0 + Double(item.levelRequirement) * 0.12
        let basePrice = Double(rarityBase + statMultiplier) * levelScale
        return max(rarityBase, Int(basePrice.rounded()))
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
    
    // MARK: - Deal of the Day
    
    /// Generate a deterministic daily deal item from the equipment catalog.
    /// Prefers ContentManager's server-driven equipment when available.
    @MainActor
    static func dailyDeal(characterLevel: Int, date: Date = Date()) -> Equipment? {
        // Build the catalog: server-driven first, then static fallback
        let cm = ContentManager.shared
        var catalog = EquipmentCatalog.all
        if cm.isLoaded && !cm.equipment.isEmpty {
            // Build EquipmentTemplate-compatible entries from server data for selection
            let serverTemplates: [EquipmentTemplate] = cm.equipment.filter { $0.active }.map { ce in
                EquipmentTemplate(
                    id: ce.id,
                    name: ce.name,
                    description: ce.description,
                    slot: EquipmentSlot(rawValue: ce.slot.lowercased()) ?? .weapon,
                    rarity: ItemRarity(rawValue: ce.rarity.lowercased()) ?? .common,
                    primaryStat: StatType(rawValue: ce.primaryStat.capitalized) ?? .strength,
                    statBonus: ce.statBonus,
                    secondaryStat: ce.secondaryStat.flatMap { StatType(rawValue: $0.capitalized) },
                    secondaryStatBonus: ce.secondaryStatBonus,
                    levelRequirement: ce.levelRequirement,
                    baseType: ce.baseType
                )
            }
            if !serverTemplates.isEmpty {
                catalog = serverTemplates
            }
        }
        guard !catalog.isEmpty else { return nil }
        
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        // Use a different seed offset than daily equipment so they don't overlap
        let seed = UInt64(year * 10000 + month * 100 + day) &+ 9999
        
        var rng = SeededRandomNumberGenerator(seed: seed)
        
        // Filter to items the character could reasonably use (within 5 levels), cap at epic
        let eligible = catalog.filter { $0.levelRequirement <= characterLevel + 5 && $0.rarity <= .epic }
        guard !eligible.isEmpty else { return nil }
        
        let index = Int(rng.next() % UInt64(eligible.count))
        let template = eligible[index]
        return template.toEquipment()
    }
    
    /// Deterministic base discount percentage for today's deal (25-40%)
    static func dealDiscount(date: Date = Date()) -> Int {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        let seed = UInt64(year * 10000 + month * 100 + day) &+ 7777
        
        var rng = SeededRandomNumberGenerator(seed: seed)
        return Int(rng.next() % 16) + 25  // 25-40%
    }
    
    /// Rarity-adjusted discount: common/uncommon get the full range, higher rarities get less
    static func adjustedDealDiscount(for item: Equipment, date: Date = Date()) -> Int {
        let base = dealDiscount(date: date)
        switch item.rarity {
        case .common: return base
        case .uncommon: return max(20, base - 3)
        case .rare: return max(15, base - 8)
        case .epic: return max(10, base - 13)
        case .legendary: return max(8, base - 18)
        }
    }
    
    /// The discounted price for the deal of the day (rarity-scaled)
    static func dealPrice(for item: Equipment, date: Date = Date()) -> Int {
        let original = priceForEquipment(item)
        let discount = adjustedDealDiscount(for: item, date: date)
        return original - (original * discount / 100)
    }
    
    // MARK: - Private
    
    private static func generateShopEquipment(
        slot: EquipmentSlot,
        tier: Int,
        luck: Int,
        rng: inout SeededRandomNumberGenerator
    ) -> Equipment {
        let rolledRarity = LootGenerator.rollRarity(tier: tier, luck: luck)
        let rarity = min(rolledRarity, .epic)
        let primaryStat = StatType.allCases.randomElement()!
        let primaryBonus = LootGenerator.rollStatBonus(rarity: rarity)
        let secondary = LootGenerator.rollSecondaryStat(rarity: rarity, excluding: primaryStat)
        let generated = LootGenerator.generateNameAndBase(slot: slot, rarity: rarity, primaryStat: primaryStat)
        let description = LootGenerator.generateDescription(slot: slot, rarity: rarity)
        let levelReq = max(1, (tier - 1) * 5 + Int(primaryBonus / 2.0))
        
        return Equipment(
            name: generated.name,
            description: description,
            slot: slot,
            rarity: rarity,
            primaryStat: primaryStat,
            statBonus: primaryBonus,
            levelRequirement: levelReq,
            secondaryStat: secondary?.stat,
            secondaryStatBonus: secondary?.bonus ?? 0.0,
            baseType: generated.baseType
        )
    }
}

// MARK: - Consumable Drop Table

/// Centralized drop tables for distributing consumables across all game systems.
/// All drop chances and item pools are defined here for easy balancing.
struct ConsumableDropTable {
    
    // MARK: - Drop Rate Configuration
    
    struct DropRates {
        /// Task completion consumable drop chance (base, before loot bonuses)
        static let taskConsumableBase: Double = 0.20
        
        /// Dungeon per-room consumable drop chance (added to equipment chance)
        static let dungeonConsumablePerRoom: Double = 0.16
        
        /// Dungeon boss room guaranteed consumable on Hard+
        static let dungeonBossConsumableHardPlus: Double = 1.0
        
        /// Mission consumable drop chance by rarity
        static func missionConsumableChance(rarity: MissionRarity) -> Double {
            switch rarity {
            case .common:    return 0.10
            case .uncommon:  return 0.18
            case .rare:      return 0.30
            case .epic:      return 0.45
            case .legendary: return 0.60
            }
        }
        
        /// Streak milestone days that award consumable rewards
        static let streakMilestones: [Int] = [3, 7, 14, 21, 30, 50, 75, 100]
        
        /// Partner co-op dungeon consumable drop chance
        static let partnerCoopDungeonDrop: Double = 0.25
        
        /// Partner task confirmation consumable drop chance
        static let partnerTaskConfirmDrop: Double = 0.15
    }
    
    // MARK: - Task Completion Drops
    
    /// Consumable templates eligible to drop from task completion.
    /// Weighted toward common, low-tier items. Level-gated.
    static func taskDropPool(level: Int) -> [(template: ConsumableTemplate, weight: Int)] {
        var pool: [(ConsumableTemplate, Int)] = []
        
        pool.append((ConsumableCatalog.goldItems[0], 30))  // Minor Healing Potion
        pool.append((ConsumableCatalog.goldItems[4], 20))  // Arcane Star
        pool.append((ConsumableCatalog.goldItems[5], 20))  // Fortune Tonic
        
        if level >= 3 {
            pool.append((ConsumableCatalog.goldItems[8], 12))  // Hearty Steak
            pool.append((ConsumableCatalog.goldItems[9], 12))  // Mystic Mushroom
            pool.append((ConsumableCatalog.goldItems[10], 12)) // Swift Apple
        }
        
        if level >= 5 {
            pool.append((ConsumableCatalog.goldItems[1], 10))  // Healing Draught
            pool.append((ConsumableCatalog.goldItems[6], 8))   // Swiftness Potion
            pool.append((ConsumableCatalog.goldItems[7], 6))   // Guardian Flask
            pool.append((ConsumableCatalog.regenItem, 6))      // Vitality Elixir
        }
        
        if level >= 10 {
            pool.append((ConsumableCatalog.materialMagnetItem, 5))
        }
        
        if level >= 15 {
            pool.append((ConsumableCatalog.goldItems[2], 4))   // Greater Healing Draught
            pool.append((ConsumableCatalog.luckElixirItem, 3))
        }
        
        return pool
    }
    
    /// Roll a consumable drop for task completion. Returns nil if no drop.
    static func rollTaskDrop(level: Int, characterID: UUID) -> Consumable? {
        let pool = taskDropPool(level: level)
        guard !pool.isEmpty else { return nil }
        return weightedRoll(pool: pool, characterID: characterID)
    }
    
    // MARK: - Dungeon Loot Drops
    
    /// Consumable templates eligible to drop from dungeon rooms, tiered by dungeon tier.
    static func dungeonDropPool(tier: Int, level: Int) -> [(template: ConsumableTemplate, weight: Int)] {
        var pool: [(ConsumableTemplate, Int)] = []
        
        pool.append((ConsumableCatalog.goldItems[0], 25))  // Minor Healing Potion
        pool.append((ConsumableCatalog.goldItems[4], 15))  // Arcane Star
        pool.append((ConsumableCatalog.goldItems[5], 15))  // Fortune Tonic
        
        if tier >= 2 {
            pool.append((ConsumableCatalog.goldItems[1], 18))   // Healing Draught
            pool.append((ConsumableCatalog.goldItems[8], 12))   // Hearty Steak
            pool.append((ConsumableCatalog.goldItems[9], 12))   // Mystic Mushroom
            pool.append((ConsumableCatalog.materialMagnetItem, 8))
            pool.append((ConsumableCatalog.regenItem, 8))       // Vitality Elixir
            pool.append((ConsumableCatalog.dutyScrollItem, 8))  // Duty Scroll
        }
        
        if tier >= 3 {
            pool.append((ConsumableCatalog.goldItems[2], 10))   // Greater Healing Draught
            pool.append((ConsumableCatalog.luckElixirItem, 6))
            pool.append((ConsumableCatalog.forgeCatalystItem, 5))
            pool.append((ConsumableCatalog.goldItems[6], 5))    // Swiftness Potion
        }
        
        if tier >= 4 {
            pool.append((ConsumableCatalog.goldItems[3], 6))    // Supreme Elixir
            pool.append((ConsumableCatalog.goldItems[7], 5))    // Guardian Flask
            pool.append((ConsumableCatalog.affixScrollItem, 3))
            pool.append((ConsumableCatalog.expeditionCompassItem, 3))
        }
        
        return pool
    }
    
    /// Roll consumable drops for a completed dungeon.
    /// Returns an array because dungeons can yield multiple consumables.
    static func rollDungeonDrops(
        tier: Int,
        level: Int,
        roomResults: [RoomResult],
        difficulty: DungeonDifficulty,
        characterID: UUID
    ) -> [Consumable] {
        var drops: [Consumable] = []
        let pool = dungeonDropPool(tier: tier, level: level)
        guard !pool.isEmpty else { return drops }
        
        let difficultyCap: Double = {
            switch difficulty {
            case .normal: return 0.30
            case .hard: return 0.50
            case .heroic: return 0.65
            case .mythic: return 0.80
            }
        }()
        
        for result in roomResults where result.success {
            let dropChance = min(difficultyCap, DropRates.dungeonConsumablePerRoom + Double(tier) * 0.02)
            if Double.random(in: 0...1) <= dropChance {
                if let item = weightedRoll(pool: pool, characterID: characterID) {
                    drops.append(item)
                }
            }
        }
        
        // Guarantee at least one consumable from every completed dungeon
        if drops.isEmpty {
            if let item = weightedRoll(pool: pool, characterID: characterID) {
                drops.append(item)
            }
        }
        
        return drops
    }
    
    // MARK: - Mission Reward Drops
    
    /// Consumable templates eligible as mission rewards, based on mission rarity.
    static func missionDropPool(rarity: MissionRarity, level: Int) -> [(template: ConsumableTemplate, weight: Int)] {
        var pool: [(ConsumableTemplate, Int)] = []
        
        switch rarity {
        case .common:
            pool.append((ConsumableCatalog.goldItems[0], 30))  // Minor Healing Potion
            pool.append((ConsumableCatalog.goldItems[4], 20))  // Arcane Star
            pool.append((ConsumableCatalog.goldItems[5], 20))  // Fortune Tonic
            if level >= 5 {
                pool.append((ConsumableCatalog.regenItem, 10))  // Vitality Elixir
            }
            
        case .uncommon:
            pool.append((ConsumableCatalog.goldItems[1], 20))  // Healing Draught
            pool.append((ConsumableCatalog.goldItems[4], 15))  // Arcane Star
            pool.append((ConsumableCatalog.goldItems[5], 15))  // Fortune Tonic
            pool.append((ConsumableCatalog.materialMagnetItem, 10))
            if level >= 10 {
                pool.append((ConsumableCatalog.goldItems[6], 8))   // Swiftness Potion
            }
            
        case .rare:
            pool.append((ConsumableCatalog.goldItems[2], 15))   // Greater Healing Draught
            pool.append((ConsumableCatalog.goldItems[4], 12))   // Arcane Star
            pool.append((ConsumableCatalog.goldItems[5], 12))   // Fortune Tonic
            pool.append((ConsumableCatalog.luckElixirItem, 8))
            pool.append((ConsumableCatalog.forgeCatalystItem, 6))
            pool.append((ConsumableCatalog.goldItems[7], 5))    // Guardian Flask
            
        case .epic:
            pool.append((ConsumableCatalog.goldItems[3], 10))   // Supreme Elixir
            pool.append((ConsumableCatalog.goldItems[4], 8))    // Arcane Star
            pool.append((ConsumableCatalog.goldItems[7], 7))    // Guardian Flask
            pool.append((ConsumableCatalog.affixScrollItem, 6))
            pool.append((ConsumableCatalog.luckElixirItem, 8))
            pool.append((ConsumableCatalog.regenItem, 5))       // Vitality Elixir
            
        case .legendary:
            pool.append((ConsumableCatalog.goldItems[3], 8))    // Supreme Elixir
            pool.append((ConsumableCatalog.goldItems[7], 6))    // Guardian Flask
            pool.append((ConsumableCatalog.affixScrollItem, 8))
            pool.append((ConsumableCatalog.goldItems[4], 6))    // Arcane Star
            pool.append((ConsumableCatalog.regenItem, 5))       // Vitality Elixir
            pool.append((ConsumableCatalog.expeditionCompassItem, 4))
        }
        
        return pool
    }
    
    /// Roll a consumable drop for mission completion. Returns nil if no drop.
    static func rollMissionDrop(rarity: MissionRarity, level: Int, characterID: UUID) -> Consumable? {
        let chance = DropRates.missionConsumableChance(rarity: rarity)
        guard Double.random(in: 0...1) <= chance else { return nil }
        
        let pool = missionDropPool(rarity: rarity, level: level)
        guard !pool.isEmpty else { return nil }
        return weightedRoll(pool: pool, characterID: characterID)
    }
    
    // MARK: - Level-Up Milestone Rewards
    
    /// Guaranteed consumable rewards at milestone levels.
    /// Returns nil for non-milestone levels.
    static func milestoneReward(level: Int, characterID: UUID) -> [Consumable] {
        var rewards: [Consumable] = []
        
        switch level {
        case 5:
            rewards.append(ConsumableCatalog.goldItems[7].toConsumable(characterID: characterID))  // Guardian Flask
            rewards.append(ConsumableCatalog.goldItems[4].toConsumable(characterID: characterID))  // Arcane Star
            
        case 10:
            rewards.append(ConsumableCatalog.materialMagnetItem.toConsumable(characterID: characterID))
            rewards.append(ConsumableCatalog.goldItems[1].toConsumable(characterID: characterID))   // Healing Draught
            rewards.append(ConsumableCatalog.goldItems[5].toConsumable(characterID: characterID))   // Fortune Tonic
            
        case 15:
            rewards.append(ConsumableCatalog.luckElixirItem.toConsumable(characterID: characterID))
            rewards.append(ConsumableCatalog.forgeCatalystItem.toConsumable(characterID: characterID))
            rewards.append(ConsumableCatalog.goldItems[7].toConsumable(characterID: characterID))   // Guardian Flask
            
        case 20:
            rewards.append(ConsumableCatalog.affixScrollItem.toConsumable(characterID: characterID))
            rewards.append(ConsumableCatalog.goldItems[2].toConsumable(characterID: characterID))   // Greater Healing Draught
            rewards.append(ConsumableCatalog.goldItems[4].toConsumable(characterID: characterID))   // Arcane Star
            
        case 25:
            rewards.append(ConsumableCatalog.affixScrollItem.toConsumable(characterID: characterID))
            rewards.append(ConsumableCatalog.luckElixirItem.toConsumable(characterID: characterID))
            rewards.append(ConsumableCatalog.regenItem.toConsumable(characterID: characterID))
            
        case 30:
            rewards.append(ConsumableCatalog.goldItems[3].toConsumable(characterID: characterID))   // Supreme Elixir
            rewards.append(ConsumableCatalog.goldItems[4].toConsumable(characterID: characterID))   // Arcane Star
            rewards.append(ConsumableCatalog.goldItems[5].toConsumable(characterID: characterID))   // Fortune Tonic
            rewards.append(ConsumableCatalog.affixScrollItem.toConsumable(characterID: characterID))
            
        case 40:
            rewards.append(ConsumableCatalog.regenItem.toConsumable(characterID: characterID))
            rewards.append(ConsumableCatalog.affixScrollItem.toConsumable(characterID: characterID))
            rewards.append(ConsumableCatalog.goldItems[3].toConsumable(characterID: characterID))   // Supreme Elixir
            rewards.append(ConsumableCatalog.expeditionCompassItem.toConsumable(characterID: characterID))
            
        case 50:
            rewards.append(ConsumableCatalog.goldItems[3].toConsumable(characterID: characterID))   // Supreme Elixir x2
            rewards.append(ConsumableCatalog.goldItems[3].toConsumable(characterID: characterID))
            rewards.append(ConsumableCatalog.affixScrollItem.toConsumable(characterID: characterID))
            rewards.append(ConsumableCatalog.regenItem.toConsumable(characterID: characterID))
            rewards.append(ConsumableCatalog.luckElixirItem.toConsumable(characterID: characterID))
            rewards.append(ConsumableCatalog.expeditionCompassItem.toConsumable(characterID: characterID))
            
        default:
            break
        }
        
        return rewards
    }
    
    // MARK: - Streak Milestone Rewards
    
    /// Consumable rewards for maintaining daily login streaks.
    /// Returns nil if the streak day isn't a milestone.
    static func streakReward(streakDay: Int, level: Int, characterID: UUID) -> [Consumable] {
        var rewards: [Consumable] = []
        
        switch streakDay {
        case 3:
            rewards.append(ConsumableCatalog.goldItems[7].toConsumable(characterID: characterID))   // Guardian Flask
            
        case 7:
            rewards.append(ConsumableCatalog.goldItems[7].toConsumable(characterID: characterID))   // Guardian Flask
            rewards.append(ConsumableCatalog.goldItems[4].toConsumable(characterID: characterID))   // Arcane Star
            
        case 14:
            rewards.append(ConsumableCatalog.goldItems[7].toConsumable(characterID: characterID))   // Guardian Flask
            rewards.append(ConsumableCatalog.luckElixirItem.toConsumable(characterID: characterID))
            
        case 21:
            rewards.append(ConsumableCatalog.goldItems[7].toConsumable(characterID: characterID))   // Guardian Flask
            rewards.append(ConsumableCatalog.materialMagnetItem.toConsumable(characterID: characterID))
            rewards.append(ConsumableCatalog.goldItems[4].toConsumable(characterID: characterID))   // Arcane Star
            
        case 30:
            rewards.append(ConsumableCatalog.goldItems[7].toConsumable(characterID: characterID))   // Guardian Flask
            rewards.append(ConsumableCatalog.luckElixirItem.toConsumable(characterID: characterID))
            rewards.append(ConsumableCatalog.affixScrollItem.toConsumable(characterID: characterID))
            rewards.append(ConsumableCatalog.goldItems[2].toConsumable(characterID: characterID))   // Greater Healing Draught
            
        case 50:
            rewards.append(ConsumableCatalog.goldItems[7].toConsumable(characterID: characterID))   // Guardian Flask
            rewards.append(ConsumableCatalog.luckElixirItem.toConsumable(characterID: characterID))
            rewards.append(ConsumableCatalog.affixScrollItem.toConsumable(characterID: characterID))
            rewards.append(ConsumableCatalog.forgeCatalystItem.toConsumable(characterID: characterID))
            
        case 75:
            rewards.append(ConsumableCatalog.affixScrollItem.toConsumable(characterID: characterID))
            rewards.append(ConsumableCatalog.luckElixirItem.toConsumable(characterID: characterID))
            rewards.append(ConsumableCatalog.regenItem.toConsumable(characterID: characterID))
            rewards.append(ConsumableCatalog.goldItems[3].toConsumable(characterID: characterID))   // Supreme Elixir
            
        case 100:
            rewards.append(ConsumableCatalog.affixScrollItem.toConsumable(characterID: characterID))
            rewards.append(ConsumableCatalog.affixScrollItem.toConsumable(characterID: characterID))
            rewards.append(ConsumableCatalog.luckElixirItem.toConsumable(characterID: characterID))
            rewards.append(ConsumableCatalog.regenItem.toConsumable(characterID: characterID))
            rewards.append(ConsumableCatalog.goldItems[3].toConsumable(characterID: characterID))
            rewards.append(ConsumableCatalog.expeditionCompassItem.toConsumable(characterID: characterID))
            
        default:
            break
        }
        
        return rewards
    }
    
    // MARK: - Partner / Couples Bonus Drops
    
    /// Consumable drop pool for partner activities (co-op dungeons, task confirmations, etc.)
    static func partnerDropPool(bondLevel: Int, level: Int) -> [(template: ConsumableTemplate, weight: Int)] {
        var pool: [(ConsumableTemplate, Int)] = []
        
        pool.append((ConsumableCatalog.partyBeaconItem, 25))
        pool.append((ConsumableCatalog.goldItems[0], 20))   // Minor Healing Potion
        pool.append((ConsumableCatalog.goldItems[4], 15))   // Arcane Star
        pool.append((ConsumableCatalog.goldItems[5], 15))   // Fortune Tonic
        
        if bondLevel >= 3 {
            pool.append((ConsumableCatalog.goldItems[8], 10))   // Hearty Steak
            pool.append((ConsumableCatalog.goldItems[9], 10))   // Mystic Mushroom
        }
        
        if bondLevel >= 5 {
            pool.append((ConsumableCatalog.materialMagnetItem, 8))
            pool.append((ConsumableCatalog.goldItems[7], 6))    // Guardian Flask
        }
        
        if bondLevel >= 8 {
            pool.append((ConsumableCatalog.luckElixirItem, 5))
            pool.append((ConsumableCatalog.forgeCatalystItem, 4))
        }
        
        if bondLevel >= 10 {
            pool.append((ConsumableCatalog.affixScrollItem, 3))
        }
        
        return pool
    }
    
    /// Roll a consumable for partner activity reward.
    static func rollPartnerDrop(bondLevel: Int, level: Int, characterID: UUID) -> Consumable? {
        let pool = partnerDropPool(bondLevel: bondLevel, level: level)
        guard !pool.isEmpty else { return nil }
        return weightedRoll(pool: pool, characterID: characterID)
    }
    
    /// Bond level-up milestone consumables (awarded when bond reaches a new level).
    static func bondLevelUpReward(bondLevel: Int, characterID: UUID) -> [Consumable] {
        var rewards: [Consumable] = []
        
        switch bondLevel {
        case 2:
            rewards.append(ConsumableCatalog.partyBeaconItem.toConsumable(characterID: characterID))
        case 3:
            rewards.append(ConsumableCatalog.partyBeaconItem.toConsumable(characterID: characterID))
            rewards.append(ConsumableCatalog.goldItems[4].toConsumable(characterID: characterID))
        case 5:
            rewards.append(ConsumableCatalog.partyBeaconItem.toConsumable(characterID: characterID))
            rewards.append(ConsumableCatalog.luckElixirItem.toConsumable(characterID: characterID))
            rewards.append(ConsumableCatalog.goldItems[7].toConsumable(characterID: characterID))
        case 7:
            rewards.append(ConsumableCatalog.partyBeaconItem.toConsumable(characterID: characterID))
            rewards.append(ConsumableCatalog.affixScrollItem.toConsumable(characterID: characterID))
            rewards.append(ConsumableCatalog.materialMagnetItem.toConsumable(characterID: characterID))
        case 10:
            rewards.append(ConsumableCatalog.partyBeaconItem.toConsumable(characterID: characterID))
            rewards.append(ConsumableCatalog.partyBeaconItem.toConsumable(characterID: characterID))
            rewards.append(ConsumableCatalog.affixScrollItem.toConsumable(characterID: characterID))
            rewards.append(ConsumableCatalog.luckElixirItem.toConsumable(characterID: characterID))
            rewards.append(ConsumableCatalog.regenItem.toConsumable(characterID: characterID))
        default:
            break
        }
        
        return rewards
    }
    
    /// Party streak milestone consumables.
    static func partyStreakReward(streakDays: Int, characterID: UUID) -> [Consumable] {
        var rewards: [Consumable] = []
        
        switch streakDays {
        case 7:
            rewards.append(ConsumableCatalog.partyBeaconItem.toConsumable(characterID: characterID))
        case 14:
            rewards.append(ConsumableCatalog.partyBeaconItem.toConsumable(characterID: characterID))
            rewards.append(ConsumableCatalog.goldItems[7].toConsumable(characterID: characterID))
        case 30:
            rewards.append(ConsumableCatalog.partyBeaconItem.toConsumable(characterID: characterID))
            rewards.append(ConsumableCatalog.luckElixirItem.toConsumable(characterID: characterID))
            rewards.append(ConsumableCatalog.goldItems[7].toConsumable(characterID: characterID))
        default:
            break
        }
        
        return rewards
    }
    
    // MARK: - Shop Rotation
    
    /// Generate a daily featured consumable deal with a discount.
    /// Uses a date-seeded RNG for deterministic daily rotation.
    static func dailyFeaturedConsumable(characterLevel: Int, date: Date = Date()) -> (template: ConsumableTemplate, discount: Int)? {
        let eligible = ConsumableCatalog.goldItems.filter { $0.levelRequirement <= characterLevel }
        guard !eligible.isEmpty else { return nil }
        
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        let seed = UInt64(year * 10000 + month * 100 + day) &+ 4321
        
        var rng = SeededRandomNumberGenerator(seed: seed)
        let index = Int(rng.next() % UInt64(eligible.count))
        let discount = Int(rng.next() % 21) + 20  // 20-40% off
        
        return (eligible[index], discount)
    }
    
    /// Generate a weekly premium consumable rotation (gem items that rotate weekly).
    static func weeklyPremiumRotation(date: Date = Date()) -> [ConsumableTemplate] {
        let calendar = Calendar.current
        let weekOfYear = calendar.component(.weekOfYear, from: date)
        let year = calendar.component(.year, from: date)
        let seed = UInt64(year * 100 + weekOfYear) &+ 8765
        
        var rng = SeededRandomNumberGenerator(seed: seed)
        var allGemItems = ConsumableCatalog.gemItems
        
        // Shuffle deterministically and take 2
        for i in stride(from: allGemItems.count - 1, through: 1, by: -1) {
            let j = Int(rng.next() % UInt64(i + 1))
            allGemItems.swapAt(i, j)
        }
        
        return Array(allGemItems.prefix(2))
    }
    
    // MARK: - Weighted Random Selection
    
    private static func weightedRoll(pool: [(template: ConsumableTemplate, weight: Int)], characterID: UUID) -> Consumable? {
        let totalWeight = pool.reduce(0) { $0 + $1.weight }
        guard totalWeight > 0 else { return nil }
        
        var roll = Int.random(in: 0..<totalWeight)
        for entry in pool {
            roll -= entry.weight
            if roll < 0 {
                return entry.template.toConsumable(characterID: characterID)
            }
        }
        
        return pool.last?.template.toConsumable(characterID: characterID)
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
