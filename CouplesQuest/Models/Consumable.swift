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
        case .forgeCatalyst: return "bolt.trianglebadge.exclamationmark.fill"
        case .expeditionCompass: return "safari.fill"
        case .regenBuff: return "heart.circle.fill"
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
        case .dungeonRevive: return "DifficultyHard"
        case .lootReroll: return "AccentPurple"
        case .materialMagnet: return "AccentPurple"
        case .luckElixir: return "AccentGreen"
        case .partyBeacon: return "AccentPink"
        case .affixScroll: return "AccentGold"
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
        case "forge_catalyst": return .forgeCatalyst
        case "expedition_compass": return .expeditionCompass
        case "regen_buff": return .regenBuff
        default: return nil
        }
    }
    
    // MARK: - Static Fallback Data
    
    /// Gold-purchasable consumable templates
    static let goldItems: [ConsumableTemplate] = [
        // HP Potions (tiered)
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
        // EXP Boosts (tiered)
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
        ConsumableTemplate(
            name: "Power Bar",
            description: "A premium energy snack for sustained focus. +50% EXP for 5 tasks.",
            type: .expBoost,
            icon: "bolt.fill",
            effectValue: 5,
            effectStat: nil,
            goldCost: 150,
            gemCost: 0,
            levelRequirement: 12
        ),
        ConsumableTemplate(
            name: "Mega Energy Bar",
            description: "An elite performance fuel. +50% EXP for 8 tasks.",
            type: .expBoost,
            icon: "bolt.circle.fill",
            effectValue: 8,
            effectStat: nil,
            goldCost: 300,
            gemCost: 0,
            levelRequirement: 20
        ),
        // Gold Boosts (tiered)
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
        ConsumableTemplate(
            name: "Fortune Stone",
            description: "A polished gem that radiates prosperity. +50% Gold for 5 tasks.",
            type: .goldBoost,
            icon: "dollarsign.circle.fill",
            effectValue: 5,
            effectStat: nil,
            goldCost: 120,
            gemCost: 0,
            levelRequirement: 12
        ),
        ConsumableTemplate(
            name: "Golden Chalice",
            description: "An enchanted chalice overflowing with fortune. +50% Gold for 8 tasks.",
            type: .goldBoost,
            icon: "cup.and.saucer.fill",
            effectValue: 8,
            effectStat: nil,
            goldCost: 280,
            gemCost: 0,
            levelRequirement: 20
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
        // Streak Shields (tiered)
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
        ConsumableTemplate(
            name: "Enchanted Cloak",
            description: "A magically woven cloak that shields your streak for 3 days.",
            type: .streakShield,
            icon: "shield.checkered",
            effectValue: 3,
            effectStat: nil,
            goldCost: 350,
            gemCost: 0,
            levelRequirement: 15
        ),
        // Stat Foods — Tier 1 (Lv3)
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
        ),
        // Stat Foods — Tier 2 (Lv15)
        ConsumableTemplate(
            name: "Power Meal",
            description: "A champion's feast that surges with raw strength.",
            type: .statFood,
            icon: "dumbbell.fill",
            effectValue: 5,
            effectStat: .strength,
            goldCost: 150,
            gemCost: 0,
            levelRequirement: 15
        ),
        ConsumableTemplate(
            name: "Sage Tea",
            description: "A rare herbal infusion brewed by scholars.",
            type: .statFood,
            icon: "leaf.fill",
            effectValue: 5,
            effectStat: .wisdom,
            goldCost: 150,
            gemCost: 0,
            levelRequirement: 15
        ),
        ConsumableTemplate(
            name: "Swift Berries",
            description: "Enchanted berries that quicken reflexes.",
            type: .statFood,
            icon: "carrot.fill",
            effectValue: 5,
            effectStat: .dexterity,
            goldCost: 150,
            gemCost: 0,
            levelRequirement: 15
        ),
    ]
    
    // MARK: - New Consumable Types (Forge & Economy Update)
    
    /// Affix Scrolls available for gold in the store
    static let affixScrollItem = ConsumableTemplate(
        name: "Affix Scroll",
        description: "A mystical scroll that guarantees at least one affix on your next equipment drop.",
        type: .affixScroll,
        icon: "scroll.fill",
        effectValue: 1,
        effectStat: nil,
        goldCost: 800,
        gemCost: 0,
        levelRequirement: 20
    )
    
    /// Forge Catalyst — doubles enhancement success for 1 attempt
    static let forgeCatalystItem = ConsumableTemplate(
        name: "Forge Catalyst",
        description: "A volatile alchemical compound that doubles enhancement success chance for one attempt.",
        type: .forgeCatalyst,
        icon: "bolt.trianglebadge.exclamationmark.fill",
        effectValue: 1,
        effectStat: nil,
        goldCost: 500,
        gemCost: 0,
        levelRequirement: 15
    )
    
    /// Material Magnet — double material drops for 5 tasks
    static let materialMagnetItem = ConsumableTemplate(
        name: "Material Magnet",
        description: "A lodestone enchanted to attract crafting materials. Double drops for 5 tasks.",
        type: .materialMagnet,
        icon: "magnet",
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
    
    /// Party Beacon — +25% bond EXP for 1 hour
    static let partyBeaconItem = ConsumableTemplate(
        name: "Party Beacon",
        description: "A radiant signal flare that strengthens party bonds. +25% bond EXP for 1 hour.",
        type: .partyBeacon,
        icon: "antenna.radiowaves.left.and.right",
        effectValue: 25,
        effectStat: nil,
        goldCost: 400,
        gemCost: 0,
        levelRequirement: 10
    )
    
    /// Expedition Compass — reveals next expedition stage rewards
    static let expeditionCompassItem = ConsumableTemplate(
        name: "Expedition Compass",
        description: "A mystical compass that reveals what lies ahead. Shows the next expedition stage rewards before completion.",
        type: .expeditionCompass,
        icon: "safari.fill",
        effectValue: 1,
        effectStat: nil,
        goldCost: 500,
        gemCost: 0,
        levelRequirement: 15
    )
    
    /// Minor EXP Boost — +25% EXP for 1 task (common tier, designed to drop from tasks)
    static let minorExpBoostItem = ConsumableTemplate(
        name: "Minor EXP Boost",
        description: "A small burst of motivational energy. +25% EXP on your next task completion.",
        type: .expBoost,
        icon: "arrow.up.circle",
        effectValue: 25,
        effectStat: nil,
        goldCost: 25,
        gemCost: 0,
        levelRequirement: 1
    )
    
    /// Minor Gold Boost — +25% Gold for 1 task (common tier, designed to drop from tasks)
    static let minorGoldBoostItem = ConsumableTemplate(
        name: "Minor Gold Boost",
        description: "A glint of fortune's favor. +25% Gold on your next task completion.",
        type: .goldBoost,
        icon: "dollarsign.circle",
        effectValue: 25,
        effectStat: nil,
        goldCost: 25,
        gemCost: 0,
        levelRequirement: 1
    )
    
    /// Premium gem-only consumable templates
    static let gemItems: [ConsumableTemplate] = [
        ConsumableTemplate(
            name: "Revive Token",
            description: "A phoenix feather that can revive a fallen dungeon party.",
            type: .dungeonRevive,
            icon: "arrow.counterclockwise.circle.fill",
            effectValue: 1,
            effectStat: nil,
            goldCost: 0,
            gemCost: 5,
            levelRequirement: 10
        ),
        ConsumableTemplate(
            name: "Loot Reroll",
            description: "A magical die that reshapes an equipment piece's stats.",
            type: .lootReroll,
            icon: "dice.fill",
            effectValue: 1,
            effectStat: nil,
            goldCost: 0,
            gemCost: 3,
            levelRequirement: 10
        ),
        ConsumableTemplate(
            name: "Instant Mission Scroll",
            description: "A scroll of haste that instantly completes an AFK mission.",
            type: .missionSpeedUp,
            icon: "bolt.circle.fill",
            effectValue: 1,
            effectStat: nil,
            goldCost: 0,
            gemCost: 5,
            levelRequirement: 10
        ),
    ]
    
    /// All purchasable consumable templates (gold + gem + new types combined for legacy compatibility)
    static let items: [ConsumableTemplate] = goldItems + newForgeItems + gemItems
    
    /// New forge/economy consumable items available for gold
    static let newForgeItems: [ConsumableTemplate] = [
        affixScrollItem,
        forgeCatalystItem,
        materialMagnetItem,
        luckElixirItem,
        partyBeaconItem,
        expeditionCompassItem,
        minorExpBoostItem,
        minorGoldBoostItem,
        minorRegenItem,
        regenItem,
        greaterRegenItem,
    ]
    
    // MARK: - Regen Buff Items
    
    /// Minor Vitality Incense — 75 HP/hr for 4 hours
    static let minorRegenItem = ConsumableTemplate(
        name: "Minor Vitality Incense",
        description: "A fragrant incense that gently accelerates natural healing. 75 HP/hr for 4 hours.",
        type: .regenBuff,
        icon: "heart.circle.fill",
        effectValue: 75,
        effectStat: nil,
        goldCost: 150,
        gemCost: 0,
        levelRequirement: 5
    )
    
    /// Vitality Incense — 100 HP/hr for 8 hours
    static let regenItem = ConsumableTemplate(
        name: "Vitality Incense",
        description: "A potent aromatic blend that significantly boosts recovery. 100 HP/hr for 8 hours.",
        type: .regenBuff,
        icon: "heart.circle.fill",
        effectValue: 100,
        effectStat: nil,
        goldCost: 400,
        gemCost: 0,
        levelRequirement: 15
    )
    
    /// Greater Vitality Incense — 150 HP/hr for 12 hours
    static let greaterRegenItem = ConsumableTemplate(
        name: "Greater Vitality Incense",
        description: "A legendary incense of extraordinary healing power. 150 HP/hr for 12 hours.",
        type: .regenBuff,
        icon: "heart.circle.fill",
        effectValue: 150,
        effectStat: nil,
        goldCost: 800,
        gemCost: 0,
        levelRequirement: 25
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
        
        // Filter to items the character could reasonably use (within 5 levels)
        let eligible = catalog.filter { $0.levelRequirement <= characterLevel + 5 }
        guard !eligible.isEmpty else { return nil }
        
        let index = Int(rng.next() % UInt64(eligible.count))
        let template = eligible[index]
        return template.toEquipment()
    }
    
    /// Deterministic discount percentage for today's deal (25-40%)
    static func dealDiscount(date: Date = Date()) -> Int {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        let seed = UInt64(year * 10000 + month * 100 + day) &+ 7777
        
        var rng = SeededRandomNumberGenerator(seed: seed)
        return Int(rng.next() % 16) + 25  // 25-40%
    }
    
    /// The discounted price for the deal of the day
    static func dealPrice(for item: Equipment, date: Date = Date()) -> Int {
        let original = priceForEquipment(item)
        let discount = dealDiscount(date: date)
        return original - (original * discount / 100)
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
