import Foundation

/// Generates random equipment drops from dungeons and missions
struct LootGenerator {
    
    // MARK: - Main Generation
    
    /// Generate a random piece of equipment based on dungeon tier and player luck
    static func generateEquipment(tier: Int, luck: Int, preferredSlot: EquipmentSlot? = nil) -> Equipment {
        let slot = preferredSlot ?? EquipmentSlot.allCases.randomElement()!
        let rarity = rollRarity(tier: tier, luck: luck)
        let primaryStat = StatType.allCases.randomElement()!
        let primaryBonus = rollStatBonus(rarity: rarity)
        let secondary = rollSecondaryStat(rarity: rarity, excluding: primaryStat)
        let name = generateName(slot: slot, rarity: rarity, primaryStat: primaryStat)
        let description = generateDescription(slot: slot, rarity: rarity)
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
    
    /// Generate multiple loot drops for a completed dungeon
    static func generateDungeonLoot(
        tier: Int,
        luck: Int,
        roomResults: [RoomResult],
        dungeonDifficulty: DungeonDifficulty,
        classLootBonus: Double = 0.0
    ) -> [Equipment] {
        var drops: [Equipment] = []
        
        // Each successful room has a chance to drop loot
        for result in roomResults where result.success {
            let baseChance = 0.15 + (Double(tier) * 0.05) + classLootBonus
            let luckBonus = Double(luck) * 0.005
            let dropChance = min(0.8, baseChance + luckBonus + (result.lootDropped ? 0.3 : 0.0))
            
            if Double.random(in: 0...1) <= dropChance {
                drops.append(generateEquipment(tier: tier, luck: luck))
            }
        }
        
        // Guaranteed drop for completing the dungeon on Hard+
        if dungeonDifficulty != .normal {
            drops.append(generateEquipment(tier: tier + 1, luck: luck))
        }
        
        return drops
    }
    
    // MARK: - Rarity Rolling
    
    /// Roll rarity based on tier and luck
    static func rollRarity(tier: Int, luck: Int) -> ItemRarity {
        let roll = Double.random(in: 0...100)
        let luckBonus = Double(luck) * 0.5
        let tierBonus = Double(tier) * 3.0
        let adjustedRoll = roll + luckBonus + tierBonus
        
        switch adjustedRoll {
        case 95...: return .legendary
        case 82...: return .epic
        case 65...: return .rare
        case 40...: return .uncommon
        default: return .common
        }
    }
    
    // MARK: - Stat Rolling
    
    /// Roll primary stat bonus based on rarity
    static func rollStatBonus(rarity: ItemRarity) -> Int {
        switch rarity {
        case .common: return Int.random(in: 1...3)
        case .uncommon: return Int.random(in: 2...5)
        case .rare: return Int.random(in: 4...8)
        case .epic: return Int.random(in: 7...12)
        case .legendary: return Int.random(in: 10...18)
        }
    }
    
    /// Roll secondary stat (chance depends on rarity)
    static func rollSecondaryStat(rarity: ItemRarity, excluding primary: StatType) -> (stat: StatType, bonus: Int)? {
        let chance: Double
        let bonusRange: ClosedRange<Int>
        
        switch rarity {
        case .common: return nil
        case .uncommon:
            chance = 0.3
            bonusRange = 1...2
        case .rare:
            chance = 0.6
            bonusRange = 2...4
        case .epic:
            chance = 0.8
            bonusRange = 3...6
        case .legendary:
            chance = 1.0
            bonusRange = 5...10
        }
        
        guard Double.random(in: 0...1) <= chance else { return nil }
        
        let availableStats = StatType.allCases.filter { $0 != primary }
        guard let stat = availableStats.randomElement() else { return nil }
        
        return (stat, Int.random(in: bonusRange))
    }
    
    // MARK: - Name Generation
    
    /// Generate a thematic equipment name
    static func generateName(slot: EquipmentSlot, rarity: ItemRarity, primaryStat: StatType) -> String {
        let prefix = prefixes(for: rarity).randomElement() ?? ""
        let base = bases(for: slot).randomElement() ?? slot.rawValue
        let suffix = suffixes(for: primaryStat).randomElement() ?? ""
        
        if rarity == .common {
            return "\(prefix) \(base)"
        }
        return "\(prefix) \(base) \(suffix)"
    }
    
    /// Generate a flavor description
    static func generateDescription(slot: EquipmentSlot, rarity: ItemRarity) -> String {
        let descriptions: [ItemRarity: [String]] = [
            .common: [
                "A simple but functional piece of gear.",
                "Nothing fancy, but it gets the job done.",
                "Basic equipment for any adventurer."
            ],
            .uncommon: [
                "Crafted with care, this gear is a cut above the rest.",
                "Slightly enchanted with a faint magical glow.",
                "Well-made and reliable in tough situations."
            ],
            .rare: [
                "Imbued with powerful enchantments that hum with energy.",
                "A sought-after piece that many adventurers would envy.",
                "Forged with rare materials and ancient techniques."
            ],
            .epic: [
                "A masterwork of magical craftsmanship, radiating power.",
                "Legends speak of gear like this — few ever hold it.",
                "Infused with the essence of fallen champions."
            ],
            .legendary: [
                "An artifact of immense power, spoken of only in whispers.",
                "World-shaping power is contained within this legendary gear.",
                "The gods themselves would covet such a treasure."
            ]
        ]
        return descriptions[rarity]?.randomElement() ?? "A mysterious piece of equipment."
    }
    
    // MARK: - Name Components
    
    private static func prefixes(for rarity: ItemRarity) -> [String] {
        switch rarity {
        case .common: return ["Worn", "Rusty", "Simple", "Basic", "Crude", "Old"]
        case .uncommon: return ["Iron", "Steel", "Sturdy", "Polished", "Fine", "Hardened"]
        case .rare: return ["Enchanted", "Arcane", "Blessed", "Tempered", "Gleaming", "Runic"]
        case .epic: return ["Mythril", "Shadowforged", "Dragonscale", "Celestial", "Void-touched", "Soulbound"]
        case .legendary: return ["Divine", "Abyssal", "Primordial", "Eternal", "Astral", "Godforged"]
        }
    }
    
    private static func bases(for slot: EquipmentSlot) -> [String] {
        switch slot {
        case .weapon: return ["Sword", "Axe", "Staff", "Dagger", "Bow", "Wand", "Mace", "Spear"]
        case .armor: return ["Plate", "Chainmail", "Robes", "Leather Armor", "Breastplate", "Helm", "Gauntlets"]
        case .accessory: return ["Ring", "Amulet", "Cloak", "Bracelet", "Charm", "Pendant", "Belt"]
        }
    }
    
    private static func suffixes(for stat: StatType) -> [String] {
        switch stat {
        case .strength: return ["of Power", "of the Bear", "of Might", "of Valor", "of Fury"]
        case .wisdom: return ["of Insight", "of the Owl", "of Knowledge", "of Clarity", "of the Mind"]
        case .endurance: return ["of Agility", "of the Fox", "of Speed", "of Precision", "of the Wind"]  // legacy — same as dexterity
        case .charisma: return ["of Charm", "of the Siren", "of Grace", "of Allure", "of Leadership"]
        case .dexterity: return ["of Agility", "of the Fox", "of Speed", "of Precision", "of the Wind"]
        case .luck: return ["of Fortune", "of the Rabbit", "of Serendipity", "of Fate", "of the Stars"]
        }
    }
}
