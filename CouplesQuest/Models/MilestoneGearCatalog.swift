import Foundation

// MARK: - Milestone Item

/// A class-specific equipment item that unlocks at a level milestone
struct MilestoneItem: Identifiable {
    let id: String                    // unique key, e.g. "ms_warrior_lv5"
    let name: String
    let description: String
    let slot: EquipmentSlot
    let rarity: ItemRarity
    let primaryStat: StatType
    let statBonus: Int
    let secondaryStat: StatType?
    let secondaryStatBonus: Int
    let levelRequirement: Int
    let characterClass: CharacterClass
    let goldCost: Int
    let baseType: String              // for image mapping ("sword", "staff", etc.)
    
    /// Create an Equipment instance from this milestone item
    func toEquipment(ownerID: UUID) -> Equipment {
        let equip = Equipment(
            name: name,
            description: description,
            slot: slot,
            rarity: rarity,
            primaryStat: primaryStat,
            statBonus: statBonus,
            levelRequirement: levelRequirement,
            secondaryStat: secondaryStat,
            secondaryStatBonus: secondaryStatBonus,
            ownerID: ownerID
        )
        equip.catalogID = id
        return equip
    }
}

// MARK: - Milestone Gear Catalog

/// Static catalog of class-specific gear that unlocks at level milestones
struct MilestoneGearCatalog {
    
    // MARK: - Public API
    
    /// Get milestone items for a specific class (includes starter class items for advanced classes)
    static func items(for characterClass: CharacterClass) -> [MilestoneItem] {
        switch characterClass {
        // Starters
        case .warrior: return warriorItems
        case .mage: return mageItems
        case .archer: return archerItems
        // Advanced — include parent starter items + advanced items
        case .berserker: return warriorItems + berserkerItems
        case .paladin: return warriorItems + paladinItems
        case .sorcerer: return mageItems + sorcererItems
        case .enchanter: return mageItems + enchanterItems
        case .ranger: return archerItems + rangerItems
        case .trickster: return archerItems + tricksterItems
        }
    }
    
    /// Get only the unlocked (purchasable) items for a character's level and class
    static func unlockedItems(for characterClass: CharacterClass, level: Int) -> [MilestoneItem] {
        items(for: characterClass).filter { $0.levelRequirement <= level }
    }
    
    // MARK: - Warrior Milestones (Lv5, 10, 15, 20)
    
    static let warriorItems: [MilestoneItem] = [
        MilestoneItem(
            id: "ms_warrior_lv5",
            name: "Warrior's Faithful Blade",
            description: "A sturdy sword forged for those who prove their strength on the battlefield.",
            slot: .weapon, rarity: .uncommon,
            primaryStat: .strength, statBonus: 4,
            secondaryStat: .defense, secondaryStatBonus: 1,
            levelRequirement: 5, characterClass: .warrior,
            goldCost: 80, baseType: "sword"
        ),
        MilestoneItem(
            id: "ms_warrior_lv10",
            name: "Guardian's Iron Plate",
            description: "Battle-hardened armor worn by those who stand between danger and the defenseless.",
            slot: .armor, rarity: .rare,
            primaryStat: .defense, statBonus: 6,
            secondaryStat: .strength, secondaryStatBonus: 2,
            levelRequirement: 10, characterClass: .warrior,
            goldCost: 200, baseType: "plate"
        ),
        MilestoneItem(
            id: "ms_warrior_lv15",
            name: "Warcry Pendant",
            description: "A medallion that amplifies the wearer's battle cry, inspiring allies and striking fear in foes.",
            slot: .accessory, rarity: .rare,
            primaryStat: .strength, statBonus: 5,
            secondaryStat: .charisma, secondaryStatBonus: 3,
            levelRequirement: 15, characterClass: .warrior,
            goldCost: 320, baseType: "pendant"
        ),
        MilestoneItem(
            id: "ms_warrior_lv20",
            name: "Champion's Greatsword",
            description: "A legendary two-handed blade awarded to warriors who have proven their mastery in every trial.",
            slot: .weapon, rarity: .epic,
            primaryStat: .strength, statBonus: 9,
            secondaryStat: .dexterity, secondaryStatBonus: 4,
            levelRequirement: 20, characterClass: .warrior,
            goldCost: 600, baseType: "sword"
        ),
    ]
    
    // MARK: - Mage Milestones (Lv5, 10, 15, 20)
    
    static let mageItems: [MilestoneItem] = [
        MilestoneItem(
            id: "ms_mage_lv5",
            name: "Apprentice's Focus Staff",
            description: "A crystalline-tipped staff that helps channel raw magical energy with precision.",
            slot: .weapon, rarity: .uncommon,
            primaryStat: .wisdom, statBonus: 4,
            secondaryStat: .luck, secondaryStatBonus: 1,
            levelRequirement: 5, characterClass: .mage,
            goldCost: 80, baseType: "staff"
        ),
        MilestoneItem(
            id: "ms_mage_lv10",
            name: "Arcane Silk Robes",
            description: "Woven from threads infused with mana, these robes offer both protection and power amplification.",
            slot: .armor, rarity: .rare,
            primaryStat: .wisdom, statBonus: 6,
            secondaryStat: .defense, secondaryStatBonus: 2,
            levelRequirement: 10, characterClass: .mage,
            goldCost: 200, baseType: "robes"
        ),
        MilestoneItem(
            id: "ms_mage_lv15",
            name: "Mystic Charm",
            description: "A shimmering charm that hums with arcane resonance, sharpening the wearer's magical intuition.",
            slot: .accessory, rarity: .rare,
            primaryStat: .wisdom, statBonus: 5,
            secondaryStat: .luck, secondaryStatBonus: 3,
            levelRequirement: 15, characterClass: .mage,
            goldCost: 320, baseType: "charm"
        ),
        MilestoneItem(
            id: "ms_mage_lv20",
            name: "Sorcerer's Orb Staff",
            description: "An ancient staff topped with a floating orb of pure mana, radiating overwhelming arcane force.",
            slot: .weapon, rarity: .epic,
            primaryStat: .wisdom, statBonus: 9,
            secondaryStat: .charisma, secondaryStatBonus: 4,
            levelRequirement: 20, characterClass: .mage,
            goldCost: 600, baseType: "wand"
        ),
    ]
    
    // MARK: - Archer Milestones (Lv5, 10, 15, 20)
    
    static let archerItems: [MilestoneItem] = [
        MilestoneItem(
            id: "ms_archer_lv5",
            name: "Scout's Shortbow",
            description: "A lightweight, fast-draw bow favored by scouts and skirmishers.",
            slot: .weapon, rarity: .uncommon,
            primaryStat: .dexterity, statBonus: 4,
            secondaryStat: .luck, secondaryStatBonus: 1,
            levelRequirement: 5, characterClass: .archer,
            goldCost: 80, baseType: "bow"
        ),
        MilestoneItem(
            id: "ms_archer_lv10",
            name: "Ranger's Leather Armor",
            description: "Supple leather armor treated with oils for silence and flexibility in the field.",
            slot: .armor, rarity: .rare,
            primaryStat: .dexterity, statBonus: 6,
            secondaryStat: .defense, secondaryStatBonus: 2,
            levelRequirement: 10, characterClass: .archer,
            goldCost: 200, baseType: "leather armor"
        ),
        MilestoneItem(
            id: "ms_archer_lv15",
            name: "Eagle-Eye Ring",
            description: "A ring enchanted to sharpen the wearer's sight far beyond mortal limits.",
            slot: .accessory, rarity: .rare,
            primaryStat: .dexterity, statBonus: 5,
            secondaryStat: .luck, secondaryStatBonus: 3,
            levelRequirement: 15, characterClass: .archer,
            goldCost: 320, baseType: "ring"
        ),
        MilestoneItem(
            id: "ms_archer_lv20",
            name: "Windrunner's Longbow",
            description: "A masterwork bow that fires arrows with the speed and precision of the wind itself.",
            slot: .weapon, rarity: .epic,
            primaryStat: .dexterity, statBonus: 9,
            secondaryStat: .strength, secondaryStatBonus: 4,
            levelRequirement: 20, characterClass: .archer,
            goldCost: 600, baseType: "bow"
        ),
    ]
    
    // MARK: - Advanced Class Milestones (Lv25, 30, 40, 50)
    
    static let berserkerItems: [MilestoneItem] = [
        MilestoneItem(
            id: "ms_berserker_lv25", name: "Rage-Forged Axe",
            description: "An axe tempered in fury, its edge grows sharper with each swing.",
            slot: .weapon, rarity: .epic,
            primaryStat: .strength, statBonus: 10, secondaryStat: .dexterity, secondaryStatBonus: 4,
            levelRequirement: 25, characterClass: .berserker, goldCost: 750, baseType: "axe"
        ),
        MilestoneItem(
            id: "ms_berserker_lv30", name: "Berserker's War Plate",
            description: "Spiked armor that channels the wearer's rage into devastating counterattacks.",
            slot: .armor, rarity: .epic,
            primaryStat: .strength, statBonus: 8, secondaryStat: .defense, secondaryStatBonus: 5,
            levelRequirement: 30, characterClass: .berserker, goldCost: 900, baseType: "plate"
        ),
        MilestoneItem(
            id: "ms_berserker_lv40", name: "Blood Fury Bracelet",
            description: "A crimson-stained bracelet that pulses with primal energy.",
            slot: .accessory, rarity: .legendary,
            primaryStat: .strength, statBonus: 14, secondaryStat: .dexterity, secondaryStatBonus: 6,
            levelRequirement: 40, characterClass: .berserker, goldCost: 1500, baseType: "bracelet"
        ),
        MilestoneItem(
            id: "ms_berserker_lv50", name: "Worldsplitter",
            description: "A legendary axe said to cleave mountains. Its weight is immense, but so is its power.",
            slot: .weapon, rarity: .legendary,
            primaryStat: .strength, statBonus: 16, secondaryStat: .defense, secondaryStatBonus: 8,
            levelRequirement: 50, characterClass: .berserker, goldCost: 2500, baseType: "axe"
        ),
    ]
    
    static let paladinItems: [MilestoneItem] = [
        MilestoneItem(
            id: "ms_paladin_lv25", name: "Oathkeeper Mace",
            description: "A holy mace that glows brighter when evil is near.",
            slot: .weapon, rarity: .epic,
            primaryStat: .defense, statBonus: 10, secondaryStat: .strength, secondaryStatBonus: 4,
            levelRequirement: 25, characterClass: .paladin, goldCost: 750, baseType: "mace"
        ),
        MilestoneItem(
            id: "ms_paladin_lv30", name: "Sanctified Shield Plate",
            description: "Blessed plate armor that absorbs blows and heals the wearer's resolve.",
            slot: .armor, rarity: .epic,
            primaryStat: .defense, statBonus: 9, secondaryStat: .wisdom, secondaryStatBonus: 4,
            levelRequirement: 30, characterClass: .paladin, goldCost: 900, baseType: "plate"
        ),
        MilestoneItem(
            id: "ms_paladin_lv40", name: "Amulet of Devotion",
            description: "An ancient relic that shields the faithful from harm.",
            slot: .accessory, rarity: .legendary,
            primaryStat: .defense, statBonus: 14, secondaryStat: .charisma, secondaryStatBonus: 6,
            levelRequirement: 40, characterClass: .paladin, goldCost: 1500, baseType: "amulet"
        ),
        MilestoneItem(
            id: "ms_paladin_lv50", name: "Dawn's Embrace",
            description: "Legendary armor forged from crystallized sunlight. Impervious to darkness.",
            slot: .armor, rarity: .legendary,
            primaryStat: .defense, statBonus: 16, secondaryStat: .strength, secondaryStatBonus: 8,
            levelRequirement: 50, characterClass: .paladin, goldCost: 2500, baseType: "plate"
        ),
    ]
    
    static let sorcererItems: [MilestoneItem] = [
        MilestoneItem(
            id: "ms_sorcerer_lv25", name: "Voidweaver Staff",
            description: "A staff that draws power from the void between worlds.",
            slot: .weapon, rarity: .epic,
            primaryStat: .wisdom, statBonus: 10, secondaryStat: .luck, secondaryStatBonus: 4,
            levelRequirement: 25, characterClass: .sorcerer, goldCost: 750, baseType: "staff"
        ),
        MilestoneItem(
            id: "ms_sorcerer_lv30", name: "Astral Silk Vestment",
            description: "Robes sewn from starlight threads that amplify arcane channeling.",
            slot: .armor, rarity: .epic,
            primaryStat: .wisdom, statBonus: 8, secondaryStat: .defense, secondaryStatBonus: 5,
            levelRequirement: 30, characterClass: .sorcerer, goldCost: 900, baseType: "robes"
        ),
        MilestoneItem(
            id: "ms_sorcerer_lv40", name: "Infinity Loop Ring",
            description: "A ring that bends mana in a perpetual cycle, granting seemingly limitless power.",
            slot: .accessory, rarity: .legendary,
            primaryStat: .wisdom, statBonus: 14, secondaryStat: .luck, secondaryStatBonus: 6,
            levelRequirement: 40, characterClass: .sorcerer, goldCost: 1500, baseType: "ring"
        ),
        MilestoneItem(
            id: "ms_sorcerer_lv50", name: "Archmage's Epoch Staff",
            description: "The legendary staff of an archmage who transcended mortality through pure knowledge.",
            slot: .weapon, rarity: .legendary,
            primaryStat: .wisdom, statBonus: 16, secondaryStat: .charisma, secondaryStatBonus: 8,
            levelRequirement: 50, characterClass: .sorcerer, goldCost: 2500, baseType: "staff"
        ),
    ]
    
    static let enchanterItems: [MilestoneItem] = [
        MilestoneItem(
            id: "ms_enchanter_lv25", name: "Harmonist's Wand",
            description: "A wand that resonates with the emotions of allies, amplifying their potential.",
            slot: .weapon, rarity: .epic,
            primaryStat: .charisma, statBonus: 10, secondaryStat: .wisdom, secondaryStatBonus: 4,
            levelRequirement: 25, characterClass: .enchanter, goldCost: 750, baseType: "wand"
        ),
        MilestoneItem(
            id: "ms_enchanter_lv30", name: "Moonshadow Robes",
            description: "Enchanted robes that shimmer under moonlight, weaving protective wards around the wearer.",
            slot: .armor, rarity: .epic,
            primaryStat: .charisma, statBonus: 8, secondaryStat: .defense, secondaryStatBonus: 5,
            levelRequirement: 30, characterClass: .enchanter, goldCost: 900, baseType: "robes"
        ),
        MilestoneItem(
            id: "ms_enchanter_lv40", name: "Crown of Whispers",
            description: "A delicate circlet that lets the wearer hear the unspoken needs of allies.",
            slot: .accessory, rarity: .legendary,
            primaryStat: .charisma, statBonus: 14, secondaryStat: .wisdom, secondaryStatBonus: 6,
            levelRequirement: 40, characterClass: .enchanter, goldCost: 1500, baseType: "charm"
        ),
        MilestoneItem(
            id: "ms_enchanter_lv50", name: "Eternal Harmony Staff",
            description: "A legendary staff that binds the spirits of allies together, creating an unbreakable bond.",
            slot: .weapon, rarity: .legendary,
            primaryStat: .charisma, statBonus: 16, secondaryStat: .wisdom, secondaryStatBonus: 8,
            levelRequirement: 50, characterClass: .enchanter, goldCost: 2500, baseType: "wand"
        ),
    ]
    
    static let rangerItems: [MilestoneItem] = [
        MilestoneItem(
            id: "ms_ranger_lv25", name: "Galeforce Bow",
            description: "A bow strung with wind-enchanted sinew, firing arrows faster than the eye can follow.",
            slot: .weapon, rarity: .epic,
            primaryStat: .dexterity, statBonus: 10, secondaryStat: .luck, secondaryStatBonus: 4,
            levelRequirement: 25, characterClass: .ranger, goldCost: 750, baseType: "bow"
        ),
        MilestoneItem(
            id: "ms_ranger_lv30", name: "Forestwalker Armor",
            description: "Living armor grown from enchanted bark, offering protection without sacrificing agility.",
            slot: .armor, rarity: .epic,
            primaryStat: .dexterity, statBonus: 8, secondaryStat: .defense, secondaryStatBonus: 5,
            levelRequirement: 30, characterClass: .ranger, goldCost: 900, baseType: "leather armor"
        ),
        MilestoneItem(
            id: "ms_ranger_lv40", name: "Hawk's Talon Bracelet",
            description: "A bracelet carved from the claw of a great hawk, granting supernatural reflexes.",
            slot: .accessory, rarity: .legendary,
            primaryStat: .dexterity, statBonus: 14, secondaryStat: .luck, secondaryStatBonus: 6,
            levelRequirement: 40, characterClass: .ranger, goldCost: 1500, baseType: "bracelet"
        ),
        MilestoneItem(
            id: "ms_ranger_lv50", name: "Skypierce, the Eternal Bow",
            description: "A legendary bow said to have been wielded by the first ranger who walked the wilds.",
            slot: .weapon, rarity: .legendary,
            primaryStat: .dexterity, statBonus: 16, secondaryStat: .strength, secondaryStatBonus: 8,
            levelRequirement: 50, characterClass: .ranger, goldCost: 2500, baseType: "bow"
        ),
    ]
    
    static let tricksterItems: [MilestoneItem] = [
        MilestoneItem(
            id: "ms_trickster_lv25", name: "Fate's Edge Dagger",
            description: "A dagger that seems to guide itself toward weak points, as if destiny wills it.",
            slot: .weapon, rarity: .epic,
            primaryStat: .luck, statBonus: 10, secondaryStat: .dexterity, secondaryStatBonus: 4,
            levelRequirement: 25, characterClass: .trickster, goldCost: 750, baseType: "dagger"
        ),
        MilestoneItem(
            id: "ms_trickster_lv30", name: "Phantom Cloak",
            description: "A cloak woven from shadow that lets the wearer slip between moments unnoticed.",
            slot: .armor, rarity: .epic,
            primaryStat: .luck, statBonus: 8, secondaryStat: .dexterity, secondaryStatBonus: 5,
            levelRequirement: 30, characterClass: .trickster, goldCost: 900, baseType: "cloak"
        ),
        MilestoneItem(
            id: "ms_trickster_lv40", name: "Gambler's Loaded Dice",
            description: "An enchanted charm that bends probability in the wielder's favor.",
            slot: .accessory, rarity: .legendary,
            primaryStat: .luck, statBonus: 14, secondaryStat: .charisma, secondaryStatBonus: 6,
            levelRequirement: 40, characterClass: .trickster, goldCost: 1500, baseType: "charm"
        ),
        MilestoneItem(
            id: "ms_trickster_lv50", name: "Whisper of Chaos",
            description: "A legendary dagger that exists in multiple timelines at once. Its strikes are inevitable.",
            slot: .weapon, rarity: .legendary,
            primaryStat: .luck, statBonus: 16, secondaryStat: .dexterity, secondaryStatBonus: 8,
            levelRequirement: 50, characterClass: .trickster, goldCost: 2500, baseType: "dagger"
        ),
    ]
}
