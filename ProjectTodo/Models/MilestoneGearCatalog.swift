import Foundation
import UIKit

// MARK: - Milestone Item

/// A class-specific equipment item that unlocks at a level milestone
struct MilestoneItem: Identifiable {
    let id: String                    // unique key, e.g. "ms_warrior_lv5"
    let name: String
    let description: String
    let slot: EquipmentSlot
    let rarity: ItemRarity
    let primaryStat: StatType
    let statBonus: Double
    let secondaryStat: StatType?
    let secondaryStatBonus: Double
    let levelRequirement: Int
    let characterClass: CharacterClass
    let goldCost: Int
    let baseType: String              // for image mapping ("sword", "staff", etc.)
    
    /// Resolved image asset name based on baseType and rarity (e.g. "equip-sword-epic")
    var imageName: String? {
        let base = "equip-\(baseType.lowercased().replacingOccurrences(of: " ", with: "-"))"
        let tinted = "\(base)-\(rarity.rawValue.lowercased())"
        if UIImage(named: tinted) != nil { return tinted }
        if UIImage(named: base) != nil { return base }
        return nil
    }
    
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
            ownerID: ownerID,
            baseType: baseType
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
            description: "Technically just a sword, but the merchant who sold it insists the loyalty is built-in.",
            slot: .weapon, rarity: .uncommon,
            primaryStat: .strength, statBonus: 4,
            secondaryStat: .defense, secondaryStatBonus: 1,
            levelRequirement: 5, characterClass: .warrior,
            goldCost: 250, baseType: "sword"
        ),
        MilestoneItem(
            id: "ms_warrior_lv10",
            name: "Guardian's Iron Plate",
            description: "Commissioned by a knight who was tired of dying. The blacksmith added extra iron where the complaints were loudest.",
            slot: .armor, rarity: .rare,
            primaryStat: .defense, statBonus: 6,
            secondaryStat: .strength, secondaryStatBonus: 2,
            levelRequirement: 10, characterClass: .warrior,
            goldCost: 700, baseType: "plate"
        ),
        MilestoneItem(
            id: "ms_warrior_lv15",
            name: "Warcry Pendant",
            description: "Originally a dinner bell from a very angry chef. Turns out screaming at people is transferable technology.",
            slot: .accessory, rarity: .rare,
            primaryStat: .strength, statBonus: 5,
            secondaryStat: .charisma, secondaryStatBonus: 3,
            levelRequirement: 15, characterClass: .warrior,
            goldCost: 1500, baseType: "amulet"
        ),
        MilestoneItem(
            id: "ms_warrior_lv20",
            name: "Champion's Greatsword",
            description: "Wielded by a champion who defeated 10,000 foes, then retired to open a bakery. The sword did not approve.",
            slot: .weapon, rarity: .epic,
            primaryStat: .strength, statBonus: 9,
            secondaryStat: .dexterity, secondaryStatBonus: 4,
            levelRequirement: 20, characterClass: .warrior,
            goldCost: 3000, baseType: "sword"
        ),
    ]
    
    // MARK: - Mage Milestones (Lv5, 10, 15, 20)
    
    static let mageItems: [MilestoneItem] = [
        MilestoneItem(
            id: "ms_mage_lv5",
            name: "Apprentice's Focus Staff",
            description: "Helps you focus your magic. Also works as a walking stick, which honestly sees more use.",
            slot: .weapon, rarity: .uncommon,
            primaryStat: .wisdom, statBonus: 4,
            secondaryStat: .luck, secondaryStatBonus: 1,
            levelRequirement: 5, characterClass: .mage,
            goldCost: 250, baseType: "staff"
        ),
        MilestoneItem(
            id: "ms_mage_lv10",
            name: "Arcane Silk Robes",
            description: "Woven by spiders who minored in thaumaturgy. They still send invoices.",
            slot: .armor, rarity: .rare,
            primaryStat: .wisdom, statBonus: 6,
            secondaryStat: .defense, secondaryStatBonus: 2,
            levelRequirement: 10, characterClass: .mage,
            goldCost: 700, baseType: "robes"
        ),
        MilestoneItem(
            id: "ms_mage_lv15",
            name: "Mystic Charm",
            description: "Found in a wizard's junk drawer labeled 'miscellaneous power.' Nobody knows what it does, but the stats don't lie.",
            slot: .accessory, rarity: .rare,
            primaryStat: .wisdom, statBonus: 5,
            secondaryStat: .luck, secondaryStatBonus: 3,
            levelRequirement: 15, characterClass: .mage,
            goldCost: 1500, baseType: "charm"
        ),
        MilestoneItem(
            id: "ms_mage_lv20",
            name: "Sorcerer's Orb Staff",
            description: "The orb floats menacingly. The staff is just there for emotional support. Together, they make your enemies deeply uncomfortable.",
            slot: .weapon, rarity: .epic,
            primaryStat: .wisdom, statBonus: 9,
            secondaryStat: .charisma, secondaryStatBonus: 4,
            levelRequirement: 20, characterClass: .mage,
            goldCost: 3000, baseType: "staff"
        ),
    ]
    
    // MARK: - Archer Milestones (Lv5, 10, 15, 20)
    
    static let archerItems: [MilestoneItem] = [
        MilestoneItem(
            id: "ms_archer_lv5",
            name: "Scout's Shortbow",
            description: "Light enough that you'll forget you're carrying it. You'll also forget to reload, but that's a you problem.",
            slot: .weapon, rarity: .uncommon,
            primaryStat: .dexterity, statBonus: 4,
            secondaryStat: .luck, secondaryStatBonus: 1,
            levelRequirement: 5, characterClass: .archer,
            goldCost: 250, baseType: "bow"
        ),
        MilestoneItem(
            id: "ms_archer_lv10",
            name: "Ranger's Leather Armor",
            description: "Crafted by a tanner who was also a ninja. It's silent because the tanner refuses to tell anyone his secrets.",
            slot: .armor, rarity: .rare,
            primaryStat: .dexterity, statBonus: 6,
            secondaryStat: .defense, secondaryStatBonus: 2,
            levelRequirement: 10, characterClass: .archer,
            goldCost: 700, baseType: "leather armor"
        ),
        MilestoneItem(
            id: "ms_archer_lv15",
            name: "Eagle-Eye Ring",
            description: "Enchanted by an optometrist who got lost on the way to a wizarding convention. You can read signs from three kingdoms away.",
            slot: .accessory, rarity: .rare,
            primaryStat: .dexterity, statBonus: 5,
            secondaryStat: .luck, secondaryStatBonus: 3,
            levelRequirement: 15, characterClass: .archer,
            goldCost: 1500, baseType: "ring"
        ),
        MilestoneItem(
            id: "ms_archer_lv20",
            name: "Windrunner's Longbow",
            description: "Arrows arrive before the archer finishes their dramatic one-liner. Very inconsiderate.",
            slot: .weapon, rarity: .epic,
            primaryStat: .dexterity, statBonus: 9,
            secondaryStat: .strength, secondaryStatBonus: 4,
            levelRequirement: 20, characterClass: .archer,
            goldCost: 3000, baseType: "bow"
        ),
    ]
    
    // MARK: - Advanced Class Milestones (Lv25, 30, 40, 50)
    
    static let berserkerItems: [MilestoneItem] = [
        MilestoneItem(
            id: "ms_berserker_lv25", name: "Rage-Forged Axe",
            description: "The blacksmith was having a really bad day. Like, a historically bad day. Anyway, the axe turned out great.",
            slot: .weapon, rarity: .epic,
            primaryStat: .strength, statBonus: 10, secondaryStat: .dexterity, secondaryStatBonus: 4,
            levelRequirement: 25, characterClass: .berserker, goldCost: 5000, baseType: "axe"
        ),
        MilestoneItem(
            id: "ms_berserker_lv30", name: "Berserker's War Plate",
            description: "The spikes are decorative. The rage is structural. Enemies don't know the difference, and that's the whole point.",
            slot: .armor, rarity: .epic,
            primaryStat: .strength, statBonus: 8, secondaryStat: .defense, secondaryStatBonus: 5,
            levelRequirement: 30, characterClass: .berserker, goldCost: 7500, baseType: "plate"
        ),
        MilestoneItem(
            id: "ms_berserker_lv40", name: "Blood Fury Ring",
            description: "Forged in the heart of a dying star by an ancient being of unfathomable power. He was also running late for dinner, so the craftsmanship is a bit uneven.",
            slot: .accessory, rarity: .legendary,
            primaryStat: .strength, statBonus: 14, secondaryStat: .dexterity, secondaryStatBonus: 6,
            levelRequirement: 40, characterClass: .berserker, goldCost: 12000, baseType: "ring"
        ),
        MilestoneItem(
            id: "ms_berserker_lv50", name: "Worldsplitter",
            description: "Prophesied to cleave the world in two. It hasn't yet, but everyone's too afraid to ask if it's even trying.",
            slot: .weapon, rarity: .legendary,
            primaryStat: .strength, statBonus: 16, secondaryStat: .defense, secondaryStatBonus: 8,
            levelRequirement: 50, characterClass: .berserker, goldCost: 20000, baseType: "axe"
        ),
    ]
    
    static let paladinItems: [MilestoneItem] = [
        MilestoneItem(
            id: "ms_paladin_lv25", name: "Oathkeeper Mace",
            description: "Glows when evil is near, which is convenient. Also glows near expired milk, which is less heroic but arguably more useful.",
            slot: .weapon, rarity: .epic,
            primaryStat: .defense, statBonus: 10, secondaryStat: .strength, secondaryStatBonus: 4,
            levelRequirement: 25, characterClass: .paladin, goldCost: 5000, baseType: "mace"
        ),
        MilestoneItem(
            id: "ms_paladin_lv30", name: "Sanctified Shield Plate",
            description: "Blessed by seventeen different clerics as a precaution. Fourteen of those blessings are redundant, but nobody wants to say so.",
            slot: .armor, rarity: .epic,
            primaryStat: .defense, statBonus: 9, secondaryStat: .wisdom, secondaryStatBonus: 4,
            levelRequirement: 30, characterClass: .paladin, goldCost: 7500, baseType: "plate"
        ),
        MilestoneItem(
            id: "ms_paladin_lv40", name: "Amulet of Devotion",
            description: "Handed down through generations of paladins, each adding their own prayer. The last one accidentally added a grocery list, but the amulet accepted it anyway.",
            slot: .accessory, rarity: .legendary,
            primaryStat: .defense, statBonus: 14, secondaryStat: .charisma, secondaryStatBonus: 6,
            levelRequirement: 40, characterClass: .paladin, goldCost: 12000, baseType: "amulet"
        ),
        MilestoneItem(
            id: "ms_paladin_lv50", name: "Dawn's Embrace",
            description: "Forged from crystallized sunlight by an angel on a deadline. Impervious to darkness, criticism, and mild staining.",
            slot: .armor, rarity: .legendary,
            primaryStat: .defense, statBonus: 16, secondaryStat: .strength, secondaryStatBonus: 8,
            levelRequirement: 50, characterClass: .paladin, goldCost: 20000, baseType: "plate"
        ),
    ]
    
    static let sorcererItems: [MilestoneItem] = [
        MilestoneItem(
            id: "ms_sorcerer_lv25", name: "Voidweaver Staff",
            description: "Draws power from the void between worlds. The void didn't agree to this arrangement, but what's it going to do? It's a void.",
            slot: .weapon, rarity: .epic,
            primaryStat: .wisdom, statBonus: 10, secondaryStat: .luck, secondaryStatBonus: 4,
            levelRequirement: 25, characterClass: .sorcerer, goldCost: 5000, baseType: "staff"
        ),
        MilestoneItem(
            id: "ms_sorcerer_lv30", name: "Astral Silk Vestment",
            description: "Sewn from actual starlight, which was a logistical nightmare. The tailor charged triple and honestly deserved more.",
            slot: .armor, rarity: .epic,
            primaryStat: .wisdom, statBonus: 8, secondaryStat: .defense, secondaryStatBonus: 5,
            levelRequirement: 30, characterClass: .sorcerer, goldCost: 7500, baseType: "robes"
        ),
        MilestoneItem(
            id: "ms_sorcerer_lv40", name: "Infinity Loop Ring",
            description: "Bends mana in a perpetual cycle, granting limitless power. The ring's terms of service are 400 pages long and nobody has read them.",
            slot: .accessory, rarity: .legendary,
            primaryStat: .wisdom, statBonus: 14, secondaryStat: .luck, secondaryStatBonus: 6,
            levelRequirement: 40, characterClass: .sorcerer, goldCost: 12000, baseType: "ring"
        ),
        MilestoneItem(
            id: "ms_sorcerer_lv50", name: "Archmage's Epoch Staff",
            description: "Its creator transcended mortality through pure knowledge. He's still out there somewhere, refusing to answer questions about the warranty.",
            slot: .weapon, rarity: .legendary,
            primaryStat: .wisdom, statBonus: 16, secondaryStat: .charisma, secondaryStatBonus: 8,
            levelRequirement: 50, characterClass: .sorcerer, goldCost: 20000, baseType: "staff"
        ),
    ]
    
    static let enchanterItems: [MilestoneItem] = [
        MilestoneItem(
            id: "ms_enchanter_lv25", name: "Harmonist's Wand",
            description: "Resonates with the emotions of allies. Unfortunately, this includes when they're annoyed at you for standing in the fire.",
            slot: .weapon, rarity: .epic,
            primaryStat: .charisma, statBonus: 10, secondaryStat: .wisdom, secondaryStatBonus: 4,
            levelRequirement: 25, characterClass: .enchanter, goldCost: 5000, baseType: "wand"
        ),
        MilestoneItem(
            id: "ms_enchanter_lv30", name: "Moonshadow Robes",
            description: "Shimmer beautifully under moonlight. Under fluorescent lighting, they just look like a bathrobe. Choose your battles wisely.",
            slot: .armor, rarity: .epic,
            primaryStat: .charisma, statBonus: 8, secondaryStat: .defense, secondaryStatBonus: 5,
            levelRequirement: 30, characterClass: .enchanter, goldCost: 7500, baseType: "robes"
        ),
        MilestoneItem(
            id: "ms_enchanter_lv40", name: "Crown of Whispers",
            description: "Lets the wearer hear the unspoken needs of allies. Mostly it's snacks. The unspoken need is almost always snacks.",
            slot: .accessory, rarity: .legendary,
            primaryStat: .charisma, statBonus: 14, secondaryStat: .wisdom, secondaryStatBonus: 6,
            levelRequirement: 40, characterClass: .enchanter, goldCost: 12000, baseType: "charm"
        ),
        MilestoneItem(
            id: "ms_enchanter_lv50", name: "Eternal Harmony Wand",
            description: "Binds the spirits of allies into an unbreakable bond. Previous owners report a strong urge to start a book club. There is no known cure.",
            slot: .weapon, rarity: .legendary,
            primaryStat: .charisma, statBonus: 16, secondaryStat: .wisdom, secondaryStatBonus: 8,
            levelRequirement: 50, characterClass: .enchanter, goldCost: 20000, baseType: "wand"
        ),
    ]
    
    static let rangerItems: [MilestoneItem] = [
        MilestoneItem(
            id: "ms_ranger_lv25", name: "Galeforce Bow",
            description: "Fires arrows faster than the eye can follow, which makes showing off to your friends completely pointless.",
            slot: .weapon, rarity: .epic,
            primaryStat: .dexterity, statBonus: 10, secondaryStat: .luck, secondaryStatBonus: 4,
            levelRequirement: 25, characterClass: .ranger, goldCost: 5000, baseType: "bow"
        ),
        MilestoneItem(
            id: "ms_ranger_lv30", name: "Forestwalker Armor",
            description: "Grown from enchanted bark that's technically still alive. It judges your posture silently but constantly.",
            slot: .armor, rarity: .epic,
            primaryStat: .dexterity, statBonus: 8, secondaryStat: .defense, secondaryStatBonus: 5,
            levelRequirement: 30, characterClass: .ranger, goldCost: 7500, baseType: "leather armor"
        ),
        MilestoneItem(
            id: "ms_ranger_lv40", name: "Hawk's Talon Ring",
            description: "Carved from the claw of a great hawk who reportedly gave it willingly. The hawk's lawyer tells a different story.",
            slot: .accessory, rarity: .legendary,
            primaryStat: .dexterity, statBonus: 14, secondaryStat: .luck, secondaryStatBonus: 6,
            levelRequirement: 40, characterClass: .ranger, goldCost: 12000, baseType: "ring"
        ),
        MilestoneItem(
            id: "ms_ranger_lv50", name: "Skypierce, the Eternal Bow",
            description: "Wielded by the first ranger who ever walked the wilds. She later trademarked the word 'nature' and this bow is the receipt.",
            slot: .weapon, rarity: .legendary,
            primaryStat: .dexterity, statBonus: 16, secondaryStat: .strength, secondaryStatBonus: 8,
            levelRequirement: 50, characterClass: .ranger, goldCost: 20000, baseType: "bow"
        ),
    ]
    
    static let tricksterItems: [MilestoneItem] = [
        MilestoneItem(
            id: "ms_trickster_lv25", name: "Fate's Edge Dagger",
            description: "Guides itself toward weak points, as if destiny wills it. Destiny is apparently very passive-aggressive.",
            slot: .weapon, rarity: .epic,
            primaryStat: .luck, statBonus: 10, secondaryStat: .dexterity, secondaryStatBonus: 4,
            levelRequirement: 25, characterClass: .trickster, goldCost: 5000, baseType: "dagger"
        ),
        MilestoneItem(
            id: "ms_trickster_lv30", name: "Phantom Cloak",
            description: "Woven from shadow itself, which was surprisingly cooperative once you offered it health insurance.",
            slot: .cloak, rarity: .epic,
            primaryStat: .luck, statBonus: 8, secondaryStat: .dexterity, secondaryStatBonus: 5,
            levelRequirement: 30, characterClass: .trickster, goldCost: 7500, baseType: "cloak"
        ),
        MilestoneItem(
            id: "ms_trickster_lv40", name: "Gambler's Loaded Dice",
            description: "Bends probability in your favor, which technically isn't cheating because nobody wrote a rule against magical dice. Yet.",
            slot: .accessory, rarity: .legendary,
            primaryStat: .luck, statBonus: 14, secondaryStat: .charisma, secondaryStatBonus: 6,
            levelRequirement: 40, characterClass: .trickster, goldCost: 12000, baseType: "charm"
        ),
        MilestoneItem(
            id: "ms_trickster_lv50", name: "Whisper of Chaos",
            description: "Exists in multiple timelines simultaneously. In three of them, you already won. In one, you're a duck. Best not to think about it.",
            slot: .weapon, rarity: .legendary,
            primaryStat: .luck, statBonus: 16, secondaryStat: .dexterity, secondaryStatBonus: 8,
            levelRequirement: 50, characterClass: .trickster, goldCost: 20000, baseType: "dagger"
        ),
    ]
}
