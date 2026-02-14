import Foundation
import SwiftData

// MARK: - Level-Up Chest Generator

/// Generates randomised level-up chest contents (bonus rewards beyond stat point & gold)
struct LevelUpChestGenerator {

    /// Result of generating a level-up chest
    struct ChestContents {
        /// Display-only reward descriptors (shown in celebration view)
        var rewards: [LevelUpReward] = []
        /// Equipment objects that need to be inserted into SwiftData
        var equipmentDrops: [Equipment] = []
        /// Consumable objects that need to be inserted into SwiftData
        var consumableDrops: [Consumable] = []
        /// Material drops: (type, rarity, quantity)
        var materialDrops: [(MaterialType, ItemRarity, Int)] = []
    }

    /// Generate bonus chest rewards for a given level and luck stat
    static func generate(level: Int, luck: Int, characterID: UUID) -> ChestContents {
        var contents = ChestContents()
        let tier = max(1, (level / 10) + 1)

        // --- Milestone every 10: guaranteed gems bonus ---
        if level % 10 == 0 {
            let gemAmount = level / 2
            contents.rewards.append(.gems(gemAmount))
        }

        // --- Milestone every 5: guaranteed equipment drop ---
        if level % 5 == 0 {
            let adjustedTier = level % 10 == 0 ? tier + 1 : tier
            let item = LootGenerator.generateEquipment(tier: adjustedTier, luck: luck, playerLevel: level)
            item.ownerID = characterID
            contents.rewards.append(.equipment(item.name, item.rarity))
            contents.equipmentDrops.append(item)
        }

        // --- 1-2 random bonus picks from weighted pool ---
        let pickCount = level % 10 == 0 ? 2 : 1
        for _ in 0..<pickCount {
            let roll = Double.random(in: 0...100)
            switch roll {
            case 0..<10:
                // 10% chance: equipment (rare)
                let item = LootGenerator.generateEquipment(tier: tier, luck: luck, playerLevel: level)
                item.ownerID = characterID
                contents.rewards.append(.equipment(item.name, item.rarity))
                contents.equipmentDrops.append(item)
            case 10..<30:
                // 20% chance: gems
                let gemAmount = max(1, level / 5)
                contents.rewards.append(.gems(gemAmount))
            case 30..<55:
                // 25% chance: consumable
                let template = randomConsumableTemplate(level: level)
                let consumable = template.toConsumable(characterID: characterID)
                contents.rewards.append(.consumable(consumable.name))
                contents.consumableDrops.append(consumable)
            default:
                // 45% chance: crafting material
                let mat = randomMaterialDrop(tier: tier)
                contents.rewards.append(.craftingMaterial(mat.displayName, mat.quantity))
                contents.materialDrops.append((mat.type, mat.rarity, mat.quantity))
            }
        }

        return contents
    }

    // MARK: - Private Helpers

    /// Pick a random consumable template appropriate for the player's level
    private static func randomConsumableTemplate(level: Int) -> ConsumableTemplate {
        let eligible = ConsumableCatalog.items.filter { $0.levelRequirement <= level }
        return eligible.randomElement() ?? ConsumableCatalog.items[0]
    }

    /// Generate a random material drop scaled to dungeon tier
    private static func randomMaterialDrop(tier: Int) -> (type: MaterialType, rarity: ItemRarity, quantity: Int, displayName: String) {
        let types: [MaterialType] = [.essence, .ore, .crystal, .hide, .herb]
        let type = types.randomElement() ?? .essence
        let rarity = materialRarity(for: tier)
        let quantity = Int.random(in: 1...max(1, tier))
        let name = rarity == .common ? type.displayName : "\(rarity.rawValue) \(type.displayName)"
        return (type, rarity, quantity, name)
    }

    private static func materialRarity(for tier: Int) -> ItemRarity {
        switch tier {
        case 1: return .common
        case 2: return .uncommon
        case 3: return .rare
        case 4: return .epic
        default: return tier >= 5 ? .legendary : .common
        }
    }
}

/// Generates random equipment drops from dungeons and missions.
/// Draws from the curated `EquipmentCatalog` when a matching item exists,
/// falling back to procedural generation for variety.
///
/// Supports:
/// - Pity system (bad luck protection per content type)
/// - Affix rolling (prefix/suffix based on rarity)
/// - Class affix preference (+10% weight for matching stat)
/// - Content-specific drop tables
/// - All 4 equipment slots (Weapon, Armor, Accessory, Trinket)
struct LootGenerator {
    
    // MARK: - Main Generation
    
    /// Generate a random piece of equipment based on dungeon tier and player luck.
    /// Prefers server-driven ContentManager items (80% chance) so players discover
    /// recognisable, hand-crafted loot. Falls back to static EquipmentCatalog if
    /// ContentManager hasn't loaded yet.
    ///
    /// Automatically rolls affixes based on rarity. Pass characterClass for +10% affix preference.
    ///
    /// - Parameter playerLevel: When provided, catalog items are filtered to
    ///   `levelRequirement <= playerLevel + 5` and procedural items are capped
    ///   to the same range. This ensures drops are equippable within a few levels.
    static func generateEquipment(
        tier: Int,
        luck: Int,
        preferredSlot: EquipmentSlot? = nil,
        forcedRarity: ItemRarity? = nil,
        characterClass: CharacterClass? = nil,
        playerLevel: Int? = nil
    ) -> Equipment {
        let slot = preferredSlot ?? EquipmentSlot.allCases.randomElement()!
        let rarity = forcedRarity ?? rollRarity(tier: tier, luck: luck)
        
        // Maximum level requirement for drops when player level is known
        let maxLevelReq = playerLevel.map { $0 + 5 }
        
        var item: Equipment
        
        // 80% chance: pull a curated item from server-driven content or static catalog
        if Double.random(in: 0...1) < 0.8 {
            let slotStr = slot.rawValue.lowercased()
            let rarityStr = rarity.rawValue.lowercased()
            
            // Try ContentManager first (server-driven) — only when on main thread
            if Thread.isMainThread {
                let cm = MainActor.assumeIsolated { ContentManager.shared }
                let isLoaded = MainActor.assumeIsolated { cm.isLoaded }
                if isLoaded {
                    var candidates = MainActor.assumeIsolated { cm.equipment(slot: slotStr, rarity: rarityStr) }
                    
                    // Filter by player level range when known
                    if let cap = maxLevelReq {
                        candidates = candidates.filter { $0.levelRequirement <= cap }
                    }
                    
                    if let pick = candidates.randomElement() {
                        item = Equipment(
                            name: pick.name,
                            description: pick.description,
                            slot: slot,
                            rarity: rarity,
                            primaryStat: StatType(rawValue: pick.primaryStat.capitalized) ?? .strength,
                            statBonus: pick.statBonus,
                            levelRequirement: pick.levelRequirement,
                            secondaryStat: pick.secondaryStat.flatMap { StatType(rawValue: $0.capitalized) },
                            secondaryStatBonus: pick.secondaryStatBonus
                        )
                        // Roll affixes
                        rollAndApplyAffixes(to: item, characterClass: characterClass)
                        return item
                    }
                }
            }
            
            // Fallback to static catalog
            if let template = EquipmentCatalog.random(slot: slot, rarity: rarity, maxLevel: maxLevelReq) {
                item = template.toEquipment()
                rollAndApplyAffixes(to: item, characterClass: characterClass)
                return item
            }
        }
        
        // 20% fallback: procedural generation for extra variety
        let primaryStat = StatType.allCases.randomElement()!
        let primaryBonus = rollStatBonus(rarity: rarity)
        let secondary = rollSecondaryStat(rarity: rarity, excluding: primaryStat)
        let name = generateName(slot: slot, rarity: rarity, primaryStat: primaryStat)
        let description = generateDescription(slot: slot, rarity: rarity)
        var levelReq = max(1, (tier - 1) * 5 + primaryBonus / 2)
        
        // Cap level requirement to player level + 5 when known
        if let cap = maxLevelReq {
            levelReq = min(levelReq, cap)
        }
        
        item = Equipment(
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
        
        // Roll affixes
        rollAndApplyAffixes(to: item, characterClass: characterClass)
        
        return item
    }
    
    /// Roll and apply affixes to an equipment item based on its rarity
    static func rollAndApplyAffixes(to item: Equipment, characterClass: CharacterClass? = nil) {
        let (prefix, suffix) = AffixRoller.rollAffixes(
            rarity: item.rarity,
            characterClass: characterClass,
            itemLevel: item.levelRequirement
        )
        item.prefix = prefix
        item.suffix = suffix
    }
    
    // MARK: - Pity-Aware Drop Check
    
    /// Check if equipment should drop, considering pity counter.
    /// Returns (shouldDrop, forcedMinRarity) — if pity triggers, forcedMinRarity is set.
    static func shouldDropEquipment(
        baseChance: Double,
        luck: Int,
        character: PlayerCharacter,
        contentType: String
    ) -> (shouldDrop: Bool, forcedMinRarity: ItemRarity?) {
        let luckBonus = Double(luck) * 0.003
        let adjustedChance = baseChance + luckBonus
        
        // Check pity first
        if character.isPityTriggered(for: contentType) {
            let minRarity = PlayerCharacter.pityMinRarity[contentType] ?? .uncommon
            character.resetPityCounter(for: contentType)
            return (true, minRarity)
        }
        
        // Normal roll
        if Double.random(in: 0...1) <= adjustedChance {
            character.resetPityCounter(for: contentType)
            return (true, nil)
        }
        
        // Dry run — increment pity
        character.incrementPityCounter(for: contentType)
        return (false, nil)
    }
    
    /// Generate multiple loot drops for a completed dungeon
    static func generateDungeonLoot(
        tier: Int,
        luck: Int,
        roomResults: [RoomResult],
        dungeonDifficulty: DungeonDifficulty,
        classLootBonus: Double = 0.0,
        cardLootBonus: Double = 0.0,
        characterClass: CharacterClass? = nil,
        playerLevel: Int? = nil
    ) -> [Equipment] {
        var drops: [Equipment] = []
        
        // Each successful room has a chance to drop loot (capped by difficulty)
        let difficultyCap = dungeonDifficulty.dropChanceCap
        for result in roomResults where result.success {
            let baseChance = 0.15 + (Double(tier) * 0.05) + classLootBonus + cardLootBonus
            let luckBonus = Double(luck) * 0.005
            let dropChance = min(difficultyCap, baseChance + luckBonus + (result.lootDropped ? 0.3 : 0.0))
            
            if Double.random(in: 0...1) <= dropChance {
                drops.append(generateEquipment(tier: tier, luck: luck, characterClass: characterClass, playerLevel: playerLevel))
            }
        }
        
        // Guaranteed drop for completing the dungeon on Hard+
        if dungeonDifficulty != .normal {
            drops.append(generateEquipment(tier: tier + 1, luck: luck, characterClass: characterClass, playerLevel: playerLevel))
        }
        
        return drops
    }
    
    // MARK: - Rarity Rolling
    
    /// Roll rarity based on tier and luck.
    ///
    /// Two layers of gating prevent low-tier content from dropping endgame gear:
    /// - **Hard cap**: Legendary is locked behind tier 4+ (level 25+ dungeons).
    /// - **Soft cap**: Epic at tiers 1-2 requires a secondary luck-based roll.
    ///   Luck stat directly boosts the chance of keeping an epic drop.
    static func rollRarity(tier: Int, luck: Int) -> ItemRarity {
        let roll = Double.random(in: 0...100)
        let luckBonus = Double(luck) * 0.5
        let tierBonus = Double(tier) * 3.0
        let adjustedRoll = roll + luckBonus + tierBonus
        
        var rarity: ItemRarity
        switch adjustedRoll {
        case 95...: rarity = .legendary
        case 82...: rarity = .epic
        case 65...: rarity = .rare
        case 40...: rarity = .uncommon
        default: rarity = .common
        }
        
        // Hard cap: Legendary requires tier 4+ (level 25+ dungeons)
        if rarity == .legendary && tier < 4 {
            rarity = .epic
        }
        
        // Soft cap: Epic at low tiers requires a luck check
        if rarity == .epic && tier < 3 {
            let epicKeepChance: Double
            switch tier {
            case 1:
                // ~2% base + 0.3% per luck point (luck 5 ≈ 3.5%, luck 20 ≈ 8%)
                epicKeepChance = 0.02 + Double(luck) * 0.003
            case 2:
                // ~5% base + 0.5% per luck point (luck 5 ≈ 7.5%, luck 20 ≈ 15%)
                epicKeepChance = 0.05 + Double(luck) * 0.005
            default:
                epicKeepChance = 1.0
            }
            
            if Double.random(in: 0...1) > epicKeepChance {
                // Failed luck check — downgrade to tier's guaranteed max
                rarity = tier >= 2 ? .rare : .uncommon
            }
        }
        
        return rarity
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
        case .weapon: return ["Sword", "Axe", "Staff", "Dagger", "Bow", "Wand", "Mace", "Spear", "Shield", "Crossbow", "Tome", "Halberd"]
        case .armor: return ["Plate", "Chainmail", "Robes", "Leather Armor", "Breastplate", "Helm", "Gauntlets", "Boots", "Pauldrons", "Cape"]
        case .accessory: return ["Ring", "Amulet", "Pendant", "Earring", "Brooch", "Talisman"]
        case .trinket: return ["Cloak", "Bracelet", "Charm", "Belt"]
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
        case .defense: return ["of the Bulwark", "of the Turtle", "of Warding", "of Iron Will", "of Shielding"]
        }
    }
}
