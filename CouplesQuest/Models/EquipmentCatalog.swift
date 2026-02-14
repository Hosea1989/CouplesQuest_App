import Foundation

// MARK: - Equipment Template

/// A blueprint for a curated base-game item. Not persisted — used to stamp out Equipment instances.
struct EquipmentTemplate: Identifiable {
    let id: String                    // unique catalog key, e.g. "wep_sword_legendary_01"
    let name: String
    let description: String
    let slot: EquipmentSlot
    let rarity: ItemRarity
    let primaryStat: StatType
    let statBonus: Int
    let secondaryStat: StatType?
    let secondaryStatBonus: Int
    let levelRequirement: Int
    let baseType: String              // keyword for image mapping ("sword", "axe", etc.)
    
    /// Stamp out a real Equipment instance from this template
    func toEquipment(ownerID: UUID? = nil) -> Equipment {
        Equipment(
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
    }
}

// MARK: - Equipment Catalog

/// Master catalog of all curated base-game equipment.
/// The loot system draws from this catalog so players discover recognisable, hand-crafted items.
struct EquipmentCatalog {
    
    // MARK: - Public API
    
    /// Every item in the game
    static let all: [EquipmentTemplate] = weapons + armor + accessories + trinkets
    
    /// Filter by slot
    static func items(for slot: EquipmentSlot) -> [EquipmentTemplate] {
        all.filter { $0.slot == slot }
    }
    
    /// Filter by rarity
    static func items(for rarity: ItemRarity) -> [EquipmentTemplate] {
        all.filter { $0.rarity == rarity }
    }
    
    /// Filter by slot AND rarity
    static func items(slot: EquipmentSlot, rarity: ItemRarity) -> [EquipmentTemplate] {
        all.filter { $0.slot == slot && $0.rarity == rarity }
    }
    
    /// Pick a random catalog item matching the given criteria.
    /// When `maxLevel` is provided, only items with `levelRequirement <= maxLevel` are considered.
    static func random(slot: EquipmentSlot? = nil, rarity: ItemRarity? = nil, maxLevel: Int? = nil) -> EquipmentTemplate? {
        var pool = all
        if let slot = slot { pool = pool.filter { $0.slot == slot } }
        if let rarity = rarity { pool = pool.filter { $0.rarity == rarity } }
        if let maxLevel = maxLevel { pool = pool.filter { $0.levelRequirement <= maxLevel } }
        return pool.randomElement()
    }
    
    /// Look up a specific item by its catalog ID
    static func find(id: String) -> EquipmentTemplate? {
        all.first { $0.id == id }
    }
    
    // =========================================================================
    // MARK: - WEAPONS  (60 items: 12 base types × 5 rarities)
    // =========================================================================
    
    static let weapons: [EquipmentTemplate] = swords + axes + staves + daggers + bows + wands + maces + spears + shields + crossbows + tomes + halberds
    
    // MARK: Swords
    
    static let swords: [EquipmentTemplate] = [
        // Common
        EquipmentTemplate(
            id: "wep_sword_common_01",
            name: "Worn Training Sword",
            description: "A dull practice blade handed to every new adventurer. It's seen better days, but it still cuts.",
            slot: .weapon, rarity: .common,
            primaryStat: .strength, statBonus: 2,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "sword"
        ),
        // Uncommon
        EquipmentTemplate(
            id: "wep_sword_uncommon_01",
            name: "Steel Longsword",
            description: "A reliable blade forged from quality steel. The grip is wrapped in dark leather for a sure hold.",
            slot: .weapon, rarity: .uncommon,
            primaryStat: .strength, statBonus: 4,
            secondaryStat: .defense, secondaryStatBonus: 1,
            levelRequirement: 5, baseType: "sword"
        ),
        // Rare
        EquipmentTemplate(
            id: "wep_sword_rare_01",
            name: "Runic Claymore",
            description: "Ancient glyphs run down the blade, pulsing faintly when enemies are near. Forged in the old tongue.",
            slot: .weapon, rarity: .rare,
            primaryStat: .strength, statBonus: 6,
            secondaryStat: .wisdom, secondaryStatBonus: 3,
            levelRequirement: 12, baseType: "sword"
        ),
        // Epic
        EquipmentTemplate(
            id: "wep_sword_epic_01",
            name: "Dragonbane Greatsword",
            description: "Quenched in dragonfire and tempered with starlight. Its edge can split scale like parchment.",
            slot: .weapon, rarity: .epic,
            primaryStat: .strength, statBonus: 10,
            secondaryStat: .dexterity, secondaryStatBonus: 4,
            levelRequirement: 22, baseType: "sword"
        ),
        // Legendary
        EquipmentTemplate(
            id: "wep_sword_legendary_01",
            name: "Excalibur, Blade of Dawn",
            description: "The fabled sword said to choose its wielder. When drawn, it bathes the battlefield in golden light.",
            slot: .weapon, rarity: .legendary,
            primaryStat: .strength, statBonus: 15,
            secondaryStat: .charisma, secondaryStatBonus: 8,
            levelRequirement: 35, baseType: "sword"
        ),
    ]
    
    // MARK: Axes
    
    static let axes: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "wep_axe_common_01",
            name: "Rusty Hatchet",
            description: "More suited for firewood than combat, but the weight behind each swing still packs a punch.",
            slot: .weapon, rarity: .common,
            primaryStat: .strength, statBonus: 3,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "axe"
        ),
        EquipmentTemplate(
            id: "wep_axe_uncommon_01",
            name: "Ironclad Battleaxe",
            description: "A double-headed war axe banded with iron. Its balance favors devastating overhead strikes.",
            slot: .weapon, rarity: .uncommon,
            primaryStat: .strength, statBonus: 5,
            secondaryStat: .defense, secondaryStatBonus: 1,
            levelRequirement: 6, baseType: "axe"
        ),
        EquipmentTemplate(
            id: "wep_axe_rare_01",
            name: "Frostbite Cleaver",
            description: "Ice crystals form along the blade's edge. Each strike sends a chill deep into the bone.",
            slot: .weapon, rarity: .rare,
            primaryStat: .strength, statBonus: 7,
            secondaryStat: .dexterity, secondaryStatBonus: 3,
            levelRequirement: 14, baseType: "axe"
        ),
        EquipmentTemplate(
            id: "wep_axe_epic_01",
            name: "Worldsplitter",
            description: "Legends say this axe once cleaved a mountain in two. The haft vibrates with barely-contained power.",
            slot: .weapon, rarity: .epic,
            primaryStat: .strength, statBonus: 11,
            secondaryStat: .defense, secondaryStatBonus: 5,
            levelRequirement: 25, baseType: "axe"
        ),
        EquipmentTemplate(
            id: "wep_axe_legendary_01",
            name: "Ragnarok, the End of Ages",
            description: "Forged in the heart of a dying star. It hums with the promise of endings and new beginnings.",
            slot: .weapon, rarity: .legendary,
            primaryStat: .strength, statBonus: 16,
            secondaryStat: .luck, secondaryStatBonus: 7,
            levelRequirement: 38, baseType: "axe"
        ),
    ]
    
    // MARK: Staves
    
    static let staves: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "wep_staff_common_01",
            name: "Gnarled Walking Stick",
            description: "A crooked branch that's been whittled into something resembling a staff. It channels... a little.",
            slot: .weapon, rarity: .common,
            primaryStat: .wisdom, statBonus: 2,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "staff"
        ),
        EquipmentTemplate(
            id: "wep_staff_uncommon_01",
            name: "Oak Channeling Staff",
            description: "Cut from an ancient oak grove, this staff hums with natural energy. The wood is warm to the touch.",
            slot: .weapon, rarity: .uncommon,
            primaryStat: .wisdom, statBonus: 4,
            secondaryStat: .charisma, secondaryStatBonus: 2,
            levelRequirement: 5, baseType: "staff"
        ),
        EquipmentTemplate(
            id: "wep_staff_rare_01",
            name: "Stormcaller's Crook",
            description: "Lightning arcs between the forked prongs at its crown. Thunderheads gather when it's raised.",
            slot: .weapon, rarity: .rare,
            primaryStat: .wisdom, statBonus: 7,
            secondaryStat: .strength, secondaryStatBonus: 2,
            levelRequirement: 13, baseType: "staff"
        ),
        EquipmentTemplate(
            id: "wep_staff_epic_01",
            name: "Archmage's Scepter",
            description: "Crystallised mana forms the headpiece. Entire spell libraries have been inscribed along its length.",
            slot: .weapon, rarity: .epic,
            primaryStat: .wisdom, statBonus: 11,
            secondaryStat: .luck, secondaryStatBonus: 4,
            levelRequirement: 24, baseType: "staff"
        ),
        EquipmentTemplate(
            id: "wep_staff_legendary_01",
            name: "Yggdrasil's Root",
            description: "A living branch from the World Tree itself. Reality bends around its wielder like water.",
            slot: .weapon, rarity: .legendary,
            primaryStat: .wisdom, statBonus: 17,
            secondaryStat: .defense, secondaryStatBonus: 7,
            levelRequirement: 40, baseType: "staff"
        ),
    ]
    
    // MARK: Daggers
    
    static let daggers: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "wep_dagger_common_01",
            name: "Chipped Shiv",
            description: "A crude blade that's more intimidating than effective. Good for cutting rope, at least.",
            slot: .weapon, rarity: .common,
            primaryStat: .dexterity, statBonus: 2,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "dagger"
        ),
        EquipmentTemplate(
            id: "wep_dagger_uncommon_01",
            name: "Viper Fang Stiletto",
            description: "Thin, wickedly sharp, and coated with a subtle toxin. Perfect for those who prefer precision.",
            slot: .weapon, rarity: .uncommon,
            primaryStat: .dexterity, statBonus: 4,
            secondaryStat: .luck, secondaryStatBonus: 2,
            levelRequirement: 4, baseType: "dagger"
        ),
        EquipmentTemplate(
            id: "wep_dagger_rare_01",
            name: "Shadowstep Kris",
            description: "The wavy blade seems to flicker between dimensions. Strikes land before the eye can follow.",
            slot: .weapon, rarity: .rare,
            primaryStat: .dexterity, statBonus: 6,
            secondaryStat: .strength, secondaryStatBonus: 3,
            levelRequirement: 11, baseType: "dagger"
        ),
        EquipmentTemplate(
            id: "wep_dagger_epic_01",
            name: "Nightwhisper",
            description: "A blade forged from condensed shadow. Its wielder moves in perfect silence.",
            slot: .weapon, rarity: .epic,
            primaryStat: .dexterity, statBonus: 10,
            secondaryStat: .luck, secondaryStatBonus: 5,
            levelRequirement: 20, baseType: "dagger"
        ),
        EquipmentTemplate(
            id: "wep_dagger_legendary_01",
            name: "Oblivion's Kiss",
            description: "They say this dagger can sever fate itself. One scratch rewrites destiny.",
            slot: .weapon, rarity: .legendary,
            primaryStat: .dexterity, statBonus: 14,
            secondaryStat: .charisma, secondaryStatBonus: 9,
            levelRequirement: 34, baseType: "dagger"
        ),
    ]
    
    // MARK: Bows
    
    static let bows: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "wep_bow_common_01",
            name: "Frayed Shortbow",
            description: "The string needs replacing and the limbs creak, but it still sends arrows roughly forward.",
            slot: .weapon, rarity: .common,
            primaryStat: .dexterity, statBonus: 2,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "bow"
        ),
        EquipmentTemplate(
            id: "wep_bow_uncommon_01",
            name: "Hunter's Recurve",
            description: "A compact, powerful bow designed for tracking game through dense forest. Smooth draw, clean release.",
            slot: .weapon, rarity: .uncommon,
            primaryStat: .dexterity, statBonus: 4,
            secondaryStat: .strength, secondaryStatBonus: 1,
            levelRequirement: 5, baseType: "bow"
        ),
        EquipmentTemplate(
            id: "wep_bow_rare_01",
            name: "Windrunner Longbow",
            description: "Arrows fired from this bow ride the wind, bending around obstacles to find their mark.",
            slot: .weapon, rarity: .rare,
            primaryStat: .dexterity, statBonus: 7,
            secondaryStat: .luck, secondaryStatBonus: 3,
            levelRequirement: 13, baseType: "bow"
        ),
        EquipmentTemplate(
            id: "wep_bow_epic_01",
            name: "Celestial Warbow",
            description: "Strung with a thread of captured starlight. Each arrow trails a comet's tail.",
            slot: .weapon, rarity: .epic,
            primaryStat: .dexterity, statBonus: 10,
            secondaryStat: .wisdom, secondaryStatBonus: 5,
            levelRequirement: 23, baseType: "bow"
        ),
        EquipmentTemplate(
            id: "wep_bow_legendary_01",
            name: "Artemis, the Moonlit Arc",
            description: "Blessed by the goddess of the hunt. Under moonlight, every shot finds its target unerringly.",
            slot: .weapon, rarity: .legendary,
            primaryStat: .dexterity, statBonus: 15,
            secondaryStat: .luck, secondaryStatBonus: 10,
            levelRequirement: 36, baseType: "bow"
        ),
    ]
    
    // MARK: Wands
    
    static let wands: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "wep_wand_common_01",
            name: "Splintered Wand",
            description: "A brittle twig that occasionally sparks. It's the thought that counts.",
            slot: .weapon, rarity: .common,
            primaryStat: .wisdom, statBonus: 2,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "wand"
        ),
        EquipmentTemplate(
            id: "wep_wand_uncommon_01",
            name: "Ember Wand",
            description: "A wand carved from fire-hardened birch. The tip glows like a dying ember, always warm.",
            slot: .weapon, rarity: .uncommon,
            primaryStat: .wisdom, statBonus: 4,
            secondaryStat: .luck, secondaryStatBonus: 1,
            levelRequirement: 4, baseType: "wand"
        ),
        EquipmentTemplate(
            id: "wep_wand_rare_01",
            name: "Prismatic Focus",
            description: "A crystalline wand that splits magic into a rainbow spectrum. Each color carries a different power.",
            slot: .weapon, rarity: .rare,
            primaryStat: .wisdom, statBonus: 6,
            secondaryStat: .charisma, secondaryStatBonus: 3,
            levelRequirement: 12, baseType: "wand"
        ),
        EquipmentTemplate(
            id: "wep_wand_epic_01",
            name: "Void Siphon",
            description: "This wand drinks in ambient magic and channels it as pure destructive force. Handle with care.",
            slot: .weapon, rarity: .epic,
            primaryStat: .wisdom, statBonus: 10,
            secondaryStat: .dexterity, secondaryStatBonus: 4,
            levelRequirement: 21, baseType: "wand"
        ),
        EquipmentTemplate(
            id: "wep_wand_legendary_01",
            name: "Merlin's Last Word",
            description: "The final creation of the greatest mage who ever lived. It thinks. It remembers. It judges.",
            slot: .weapon, rarity: .legendary,
            primaryStat: .wisdom, statBonus: 16,
            secondaryStat: .luck, secondaryStatBonus: 8,
            levelRequirement: 38, baseType: "wand"
        ),
    ]
    
    // MARK: Maces
    
    static let maces: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "wep_mace_common_01",
            name: "Bent Cudgel",
            description: "A heavy lump of wood and metal. Crude, but it gets the point across. Literally.",
            slot: .weapon, rarity: .common,
            primaryStat: .strength, statBonus: 2,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "mace"
        ),
        EquipmentTemplate(
            id: "wep_mace_uncommon_01",
            name: "Flanged War Mace",
            description: "Reinforced flanges concentrate impact force. Armor means nothing to this weapon.",
            slot: .weapon, rarity: .uncommon,
            primaryStat: .strength, statBonus: 4,
            secondaryStat: .defense, secondaryStatBonus: 2,
            levelRequirement: 6, baseType: "mace"
        ),
        EquipmentTemplate(
            id: "wep_mace_rare_01",
            name: "Thundering Maul",
            description: "A seismic impact accompanies every blow. The ground cracks in a web pattern beneath the strike.",
            slot: .weapon, rarity: .rare,
            primaryStat: .strength, statBonus: 7,
            secondaryStat: .defense, secondaryStatBonus: 3,
            levelRequirement: 14, baseType: "mace"
        ),
        EquipmentTemplate(
            id: "wep_mace_epic_01",
            name: "Dawnbreaker",
            description: "A holy mace that blazes with solar fire. Undead crumble and shadows flee before its light.",
            slot: .weapon, rarity: .epic,
            primaryStat: .strength, statBonus: 10,
            secondaryStat: .charisma, secondaryStatBonus: 5,
            levelRequirement: 24, baseType: "mace"
        ),
        EquipmentTemplate(
            id: "wep_mace_legendary_01",
            name: "Mjolnir, the Stormhammer",
            description: "Only the worthy may lift it. Storms answer its call, and lightning bows to its swing.",
            slot: .weapon, rarity: .legendary,
            primaryStat: .strength, statBonus: 17,
            secondaryStat: .defense, secondaryStatBonus: 8,
            levelRequirement: 40, baseType: "mace"
        ),
    ]
    
    // MARK: Spears
    
    static let spears: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "wep_spear_common_01",
            name: "Wooden Pike",
            description: "A sharpened stick with delusions of grandeur. But reach is reach.",
            slot: .weapon, rarity: .common,
            primaryStat: .dexterity, statBonus: 2,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "spear"
        ),
        EquipmentTemplate(
            id: "wep_spear_uncommon_01",
            name: "Bronze Partisan",
            description: "A wide-bladed spear designed for both thrusting and sweeping. The bronze gleams proudly.",
            slot: .weapon, rarity: .uncommon,
            primaryStat: .dexterity, statBonus: 4,
            secondaryStat: .strength, secondaryStatBonus: 2,
            levelRequirement: 5, baseType: "spear"
        ),
        EquipmentTemplate(
            id: "wep_spear_rare_01",
            name: "Tidecaller Trident",
            description: "Three prongs of sea-forged steel that shimmer like sunlight on waves. Water bends to its will.",
            slot: .weapon, rarity: .rare,
            primaryStat: .dexterity, statBonus: 6,
            secondaryStat: .wisdom, secondaryStatBonus: 3,
            levelRequirement: 13, baseType: "spear"
        ),
        EquipmentTemplate(
            id: "wep_spear_epic_01",
            name: "Skypierce Lance",
            description: "So perfectly balanced it feels weightless. Thrown, it can punch through castle walls.",
            slot: .weapon, rarity: .epic,
            primaryStat: .dexterity, statBonus: 10,
            secondaryStat: .strength, secondaryStatBonus: 5,
            levelRequirement: 23, baseType: "spear"
        ),
        EquipmentTemplate(
            id: "wep_spear_legendary_01",
            name: "Gungnir, the Allfather's Reach",
            description: "Once thrown, it never misses. The spear that pierced the veil between worlds.",
            slot: .weapon, rarity: .legendary,
            primaryStat: .dexterity, statBonus: 15,
            secondaryStat: .wisdom, secondaryStatBonus: 9,
            levelRequirement: 37, baseType: "spear"
        ),
    ]
    
    // =========================================================================
    // MARK: - ARMOR  (50 items: 10 base types × 5 rarities)
    // =========================================================================
    
    static let armor: [EquipmentTemplate] = plates + chainmails + robes + leatherArmors + breastplates + helms + gauntlets + boots + pauldrons + capes
    
    // MARK: Plate
    
    static let plates: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "arm_plate_common_01",
            name: "Dented Iron Plate",
            description: "Heavy, uncomfortable, and has a suspicious dent over the heart. But hey, it's plate armor.",
            slot: .armor, rarity: .common,
            primaryStat: .defense, statBonus: 3,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "plate"
        ),
        EquipmentTemplate(
            id: "arm_plate_uncommon_01",
            name: "Steel Guardian Plate",
            description: "Well-fitted plate armor that distributes weight evenly. You can actually run in this one.",
            slot: .armor, rarity: .uncommon,
            primaryStat: .defense, statBonus: 5,
            secondaryStat: .strength, secondaryStatBonus: 1,
            levelRequirement: 7, baseType: "plate"
        ),
        EquipmentTemplate(
            id: "arm_plate_rare_01",
            name: "Warden's Bulwark",
            description: "Enchanted plate that hardens on impact. The harder you hit it, the stronger it becomes.",
            slot: .armor, rarity: .rare,
            primaryStat: .defense, statBonus: 7,
            secondaryStat: .strength, secondaryStatBonus: 3,
            levelRequirement: 15, baseType: "plate"
        ),
        EquipmentTemplate(
            id: "arm_plate_epic_01",
            name: "Titanforge Warplate",
            description: "Forged from an alloy that doesn't exist in nature. Blades shatter against its surface.",
            slot: .armor, rarity: .epic,
            primaryStat: .defense, statBonus: 11,
            secondaryStat: .strength, secondaryStatBonus: 5,
            levelRequirement: 26, baseType: "plate"
        ),
        EquipmentTemplate(
            id: "arm_plate_legendary_01",
            name: "Aegis of the Immortal",
            description: "Worn by the last of the eternal guardians. No mortal weapon has ever breached its protection.",
            slot: .armor, rarity: .legendary,
            primaryStat: .defense, statBonus: 18,
            secondaryStat: .charisma, secondaryStatBonus: 7,
            levelRequirement: 40, baseType: "plate"
        ),
    ]
    
    // MARK: Chainmail
    
    static let chainmails: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "arm_chain_common_01",
            name: "Loose Chain Shirt",
            description: "The links are uneven and some are missing, but it turns a blade better than bare skin.",
            slot: .armor, rarity: .common,
            primaryStat: .defense, statBonus: 2,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "chainmail"
        ),
        EquipmentTemplate(
            id: "arm_chain_uncommon_01",
            name: "Riveted Hauberk",
            description: "Each ring is individually riveted for maximum protection. A soldier's best friend.",
            slot: .armor, rarity: .uncommon,
            primaryStat: .defense, statBonus: 4,
            secondaryStat: .dexterity, secondaryStatBonus: 2,
            levelRequirement: 6, baseType: "chainmail"
        ),
        EquipmentTemplate(
            id: "arm_chain_rare_01",
            name: "Mithril Weave",
            description: "Impossibly light chainmail woven from mithril threads. Moves like silk, protects like steel.",
            slot: .armor, rarity: .rare,
            primaryStat: .defense, statBonus: 6,
            secondaryStat: .dexterity, secondaryStatBonus: 4,
            levelRequirement: 14, baseType: "chainmail"
        ),
        EquipmentTemplate(
            id: "arm_chain_epic_01",
            name: "Dragonlink Coat",
            description: "Each link is a miniature dragon scale. Fire washes over it harmlessly.",
            slot: .armor, rarity: .epic,
            primaryStat: .defense, statBonus: 9,
            secondaryStat: .dexterity, secondaryStatBonus: 5,
            levelRequirement: 24, baseType: "chainmail"
        ),
        EquipmentTemplate(
            id: "arm_chain_legendary_01",
            name: "Veil of the Valkyrie",
            description: "Woven by warrior-angels from threads of valor. Its wearer cannot fall in dishonor.",
            slot: .armor, rarity: .legendary,
            primaryStat: .defense, statBonus: 15,
            secondaryStat: .luck, secondaryStatBonus: 8,
            levelRequirement: 37, baseType: "chainmail"
        ),
    ]
    
    // MARK: Robes
    
    static let robes: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "arm_robes_common_01",
            name: "Threadbare Apprentice Robes",
            description: "Patched and re-patched, these robes smell faintly of old parchment and failure.",
            slot: .armor, rarity: .common,
            primaryStat: .wisdom, statBonus: 2,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "robes"
        ),
        EquipmentTemplate(
            id: "arm_robes_uncommon_01",
            name: "Scholar's Vestments",
            description: "Clean, well-tailored robes with protective runes stitched into the hems.",
            slot: .armor, rarity: .uncommon,
            primaryStat: .wisdom, statBonus: 4,
            secondaryStat: .charisma, secondaryStatBonus: 2,
            levelRequirement: 5, baseType: "robes"
        ),
        EquipmentTemplate(
            id: "arm_robes_rare_01",
            name: "Astral Silkweave",
            description: "Woven from threads that shimmer with starlight. The fabric exists partially in another dimension.",
            slot: .armor, rarity: .rare,
            primaryStat: .wisdom, statBonus: 7,
            secondaryStat: .defense, secondaryStatBonus: 2,
            levelRequirement: 13, baseType: "robes"
        ),
        EquipmentTemplate(
            id: "arm_robes_epic_01",
            name: "Mantle of the Archmage",
            description: "Spells weave themselves into the fabric. The robes actively deflect hostile magic.",
            slot: .armor, rarity: .epic,
            primaryStat: .wisdom, statBonus: 10,
            secondaryStat: .defense, secondaryStatBonus: 5,
            levelRequirement: 24, baseType: "robes"
        ),
        EquipmentTemplate(
            id: "arm_robes_legendary_01",
            name: "Cosmos Regalia",
            description: "The universe itself is woven into this garment. Galaxies swirl across its surface.",
            slot: .armor, rarity: .legendary,
            primaryStat: .wisdom, statBonus: 16,
            secondaryStat: .luck, secondaryStatBonus: 9,
            levelRequirement: 38, baseType: "robes"
        ),
    ]
    
    // MARK: Leather Armor
    
    static let leatherArmors: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "arm_leather_common_01",
            name: "Patched Hide Vest",
            description: "A vest stitched together from various animal hides. Fashion-forward it is not.",
            slot: .armor, rarity: .common,
            primaryStat: .dexterity, statBonus: 2,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "leather armor"
        ),
        EquipmentTemplate(
            id: "arm_leather_uncommon_01",
            name: "Ranger's Jerkin",
            description: "Supple, dyed-green leather that allows full range of motion. Perfect for skulking.",
            slot: .armor, rarity: .uncommon,
            primaryStat: .dexterity, statBonus: 4,
            secondaryStat: .defense, secondaryStatBonus: 1,
            levelRequirement: 5, baseType: "leather armor"
        ),
        EquipmentTemplate(
            id: "arm_leather_rare_01",
            name: "Shadowskin Cuirass",
            description: "Treated with shadow-essence, this armor blends with darkness. Rogues' favorite.",
            slot: .armor, rarity: .rare,
            primaryStat: .dexterity, statBonus: 6,
            secondaryStat: .luck, secondaryStatBonus: 3,
            levelRequirement: 12, baseType: "leather armor"
        ),
        EquipmentTemplate(
            id: "arm_leather_epic_01",
            name: "Wyrmhide Armor",
            description: "Tanned from the hide of an elder wyrm. Lighter than cloth but harder than steel.",
            slot: .armor, rarity: .epic,
            primaryStat: .dexterity, statBonus: 10,
            secondaryStat: .defense, secondaryStatBonus: 4,
            levelRequirement: 22, baseType: "leather armor"
        ),
        EquipmentTemplate(
            id: "arm_leather_legendary_01",
            name: "Phantom Shroud",
            description: "Not truly leather — it's woven from the echoes of a thousand whispered secrets.",
            slot: .armor, rarity: .legendary,
            primaryStat: .dexterity, statBonus: 14,
            secondaryStat: .charisma, secondaryStatBonus: 8,
            levelRequirement: 35, baseType: "leather armor"
        ),
    ]
    
    // MARK: Breastplate
    
    static let breastplates: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "arm_breast_common_01",
            name: "Tarnished Breastplate",
            description: "The engraving has worn away to nothing. It still stops a blade, mostly.",
            slot: .armor, rarity: .common,
            primaryStat: .defense, statBonus: 2,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "breastplate"
        ),
        EquipmentTemplate(
            id: "arm_breast_uncommon_01",
            name: "Knight's Cuirass",
            description: "A polished breastplate bearing the crest of a fallen order. Still carries their honor.",
            slot: .armor, rarity: .uncommon,
            primaryStat: .defense, statBonus: 4,
            secondaryStat: .charisma, secondaryStatBonus: 1,
            levelRequirement: 6, baseType: "breastplate"
        ),
        EquipmentTemplate(
            id: "arm_breast_rare_01",
            name: "Emberheart Guard",
            description: "The metal is perpetually warm, as if a fire burns within. Cold attacks dissipate on contact.",
            slot: .armor, rarity: .rare,
            primaryStat: .defense, statBonus: 6,
            secondaryStat: .strength, secondaryStatBonus: 3,
            levelRequirement: 14, baseType: "breastplate"
        ),
        EquipmentTemplate(
            id: "arm_breast_epic_01",
            name: "Oathkeeper's Aegis",
            description: "Engraved with binding oaths of protection. It grows stronger when defending allies.",
            slot: .armor, rarity: .epic,
            primaryStat: .defense, statBonus: 10,
            secondaryStat: .charisma, secondaryStatBonus: 5,
            levelRequirement: 25, baseType: "breastplate"
        ),
        EquipmentTemplate(
            id: "arm_breast_legendary_01",
            name: "Soulforged Vestment",
            description: "Bound to its wearer's soul. It heals itself, grows with its bearer, and mourns when they fall.",
            slot: .armor, rarity: .legendary,
            primaryStat: .defense, statBonus: 16,
            secondaryStat: .wisdom, secondaryStatBonus: 7,
            levelRequirement: 38, baseType: "breastplate"
        ),
    ]
    
    // MARK: Helms
    
    static let helms: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "arm_helm_common_01",
            name: "Battered Tin Helm",
            description: "It's basically a bucket with eye holes. But it does prevent head injuries. Mostly.",
            slot: .armor, rarity: .common,
            primaryStat: .defense, statBonus: 1,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "helm"
        ),
        EquipmentTemplate(
            id: "arm_helm_uncommon_01",
            name: "Steel Barbute",
            description: "A well-crafted helm with a T-shaped visor. Classic protection with decent visibility.",
            slot: .armor, rarity: .uncommon,
            primaryStat: .defense, statBonus: 3,
            secondaryStat: .wisdom, secondaryStatBonus: 2,
            levelRequirement: 5, baseType: "helm"
        ),
        EquipmentTemplate(
            id: "arm_helm_rare_01",
            name: "Crown of the Vigilant",
            description: "An open-faced helm with a glowing eye motif. Grants awareness of unseen threats.",
            slot: .armor, rarity: .rare,
            primaryStat: .defense, statBonus: 5,
            secondaryStat: .wisdom, secondaryStatBonus: 4,
            levelRequirement: 13, baseType: "helm"
        ),
        EquipmentTemplate(
            id: "arm_helm_epic_01",
            name: "Dread Visage",
            description: "A terrifying horned helm that projects fear into enemies. Even dragons hesitate.",
            slot: .armor, rarity: .epic,
            primaryStat: .defense, statBonus: 8,
            secondaryStat: .charisma, secondaryStatBonus: 6,
            levelRequirement: 23, baseType: "helm"
        ),
        EquipmentTemplate(
            id: "arm_helm_legendary_01",
            name: "Crown of the Conqueror",
            description: "Worn by the one who united all kingdoms. It amplifies the will of a true leader.",
            slot: .armor, rarity: .legendary,
            primaryStat: .defense, statBonus: 13,
            secondaryStat: .charisma, secondaryStatBonus: 10,
            levelRequirement: 36, baseType: "helm"
        ),
    ]
    
    // MARK: Gauntlets
    
    static let gauntlets: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "arm_gauntlets_common_01",
            name: "Cracked Leather Gloves",
            description: "They barely qualify as gauntlets. At least they prevent blisters.",
            slot: .armor, rarity: .common,
            primaryStat: .strength, statBonus: 1,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "gauntlets"
        ),
        EquipmentTemplate(
            id: "arm_gauntlets_uncommon_01",
            name: "Iron Grip Gauntlets",
            description: "Reinforced knuckles and articulated fingers. A firm handshake becomes a weapon.",
            slot: .armor, rarity: .uncommon,
            primaryStat: .strength, statBonus: 3,
            secondaryStat: .defense, secondaryStatBonus: 2,
            levelRequirement: 5, baseType: "gauntlets"
        ),
        EquipmentTemplate(
            id: "arm_gauntlets_rare_01",
            name: "Flameguard Gauntlets",
            description: "Enchanted to be fireproof. The wearer can pluck objects from open flame without a mark.",
            slot: .armor, rarity: .rare,
            primaryStat: .strength, statBonus: 5,
            secondaryStat: .defense, secondaryStatBonus: 4,
            levelRequirement: 12, baseType: "gauntlets"
        ),
        EquipmentTemplate(
            id: "arm_gauntlets_epic_01",
            name: "Titan's Grasp",
            description: "Once you grab something, nothing short of divine intervention will make you let go.",
            slot: .armor, rarity: .epic,
            primaryStat: .strength, statBonus: 9,
            secondaryStat: .defense, secondaryStatBonus: 5,
            levelRequirement: 22, baseType: "gauntlets"
        ),
        EquipmentTemplate(
            id: "arm_gauntlets_legendary_01",
            name: "Hands of Creation",
            description: "Said to be replicas of the hands that shaped the world. What they hold, they can reshape.",
            slot: .armor, rarity: .legendary,
            primaryStat: .strength, statBonus: 14,
            secondaryStat: .wisdom, secondaryStatBonus: 8,
            levelRequirement: 37, baseType: "gauntlets"
        ),
    ]
    
    // =========================================================================
    // MARK: - ACCESSORIES  (30 items: 6 base types × 5 rarities)
    // =========================================================================
    
    static let accessories: [EquipmentTemplate] = rings + amulets + pendants + earrings + brooches + talismans
    
    // MARK: Rings
    
    static let rings: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "acc_ring_common_01",
            name: "Tarnished Copper Band",
            description: "A thin ring that's turned your finger green. It might be enchanted. Might just be cheap.",
            slot: .accessory, rarity: .common,
            primaryStat: .luck, statBonus: 1,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "ring"
        ),
        EquipmentTemplate(
            id: "acc_ring_uncommon_01",
            name: "Silver Promise Ring",
            description: "A simple silver band etched with interlocking hearts. Stronger together.",
            slot: .accessory, rarity: .uncommon,
            primaryStat: .charisma, statBonus: 3,
            secondaryStat: .luck, secondaryStatBonus: 2,
            levelRequirement: 4, baseType: "ring"
        ),
        EquipmentTemplate(
            id: "acc_ring_rare_01",
            name: "Ring of Shared Strength",
            description: "When two who share a bond wear matching rings, both grow stronger. Love is power.",
            slot: .accessory, rarity: .rare,
            primaryStat: .strength, statBonus: 5,
            secondaryStat: .charisma, secondaryStatBonus: 4,
            levelRequirement: 11, baseType: "ring"
        ),
        EquipmentTemplate(
            id: "acc_ring_epic_01",
            name: "Eclipse Band",
            description: "A ring of intertwined sun and moon metals. Day and night dance along its surface.",
            slot: .accessory, rarity: .epic,
            primaryStat: .luck, statBonus: 8,
            secondaryStat: .wisdom, secondaryStatBonus: 5,
            levelRequirement: 20, baseType: "ring"
        ),
        EquipmentTemplate(
            id: "acc_ring_legendary_01",
            name: "The Eternal Vow",
            description: "A ring forged from a promise that transcends time itself. Its power grows with devotion.",
            slot: .accessory, rarity: .legendary,
            primaryStat: .charisma, statBonus: 14,
            secondaryStat: .luck, secondaryStatBonus: 10,
            levelRequirement: 35, baseType: "ring"
        ),
    ]
    
    // MARK: Amulets
    
    static let amulets: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "acc_amulet_common_01",
            name: "Wooden Totem Necklace",
            description: "A carved animal token on a hemp cord. It's a lucky charm — or so you keep telling yourself.",
            slot: .accessory, rarity: .common,
            primaryStat: .luck, statBonus: 2,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "amulet"
        ),
        EquipmentTemplate(
            id: "acc_amulet_uncommon_01",
            name: "Jade Guardian Amulet",
            description: "A polished jade stone that wards off minor hexes and keeps its wearer calm under pressure.",
            slot: .accessory, rarity: .uncommon,
            primaryStat: .defense, statBonus: 3,
            secondaryStat: .wisdom, secondaryStatBonus: 2,
            levelRequirement: 5, baseType: "amulet"
        ),
        EquipmentTemplate(
            id: "acc_amulet_rare_01",
            name: "Phoenix Feather Talisman",
            description: "A genuine phoenix plume encased in crystal. It pulses with warmth and stubborn vitality.",
            slot: .accessory, rarity: .rare,
            primaryStat: .wisdom, statBonus: 5,
            secondaryStat: .luck, secondaryStatBonus: 4,
            levelRequirement: 12, baseType: "amulet"
        ),
        EquipmentTemplate(
            id: "acc_amulet_epic_01",
            name: "Eye of the Storm",
            description: "A sapphire that contains a miniature thunderstorm. Chaos swirls within, but the center is calm.",
            slot: .accessory, rarity: .epic,
            primaryStat: .wisdom, statBonus: 9,
            secondaryStat: .defense, secondaryStatBonus: 5,
            levelRequirement: 22, baseType: "amulet"
        ),
        EquipmentTemplate(
            id: "acc_amulet_legendary_01",
            name: "Heart of the World Tree",
            description: "A seed of pure life force from Yggdrasil. It beats like a heart and makes the impossible possible.",
            slot: .accessory, rarity: .legendary,
            primaryStat: .wisdom, statBonus: 15,
            secondaryStat: .luck, secondaryStatBonus: 9,
            levelRequirement: 38, baseType: "amulet"
        ),
    ]
    
    // MARK: Cloaks
    
    static let cloaks: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "trk_cloak_common_01",
            name: "Moth-Eaten Travel Cape",
            description: "It keeps the rain off. Some of the rain. Okay, a little of the rain.",
            slot: .trinket, rarity: .common,
            primaryStat: .defense, statBonus: 1,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "cloak"
        ),
        EquipmentTemplate(
            id: "trk_cloak_uncommon_01",
            name: "Twilight Mantle",
            description: "A deep-blue cloak that seems to absorb light. Perfect for blending into evening shadows.",
            slot: .trinket, rarity: .uncommon,
            primaryStat: .dexterity, statBonus: 3,
            secondaryStat: .defense, secondaryStatBonus: 1,
            levelRequirement: 5, baseType: "cloak"
        ),
        EquipmentTemplate(
            id: "trk_cloak_rare_01",
            name: "Windweaver's Shroud",
            description: "The air itself moves around this cloak, making its wearer lighter and faster.",
            slot: .trinket, rarity: .rare,
            primaryStat: .dexterity, statBonus: 5,
            secondaryStat: .luck, secondaryStatBonus: 3,
            levelRequirement: 13, baseType: "cloak"
        ),
        EquipmentTemplate(
            id: "trk_cloak_epic_01",
            name: "Cloak of Many Stars",
            description: "The interior shows a different constellation each night. It whispers star-charts to its wearer.",
            slot: .trinket, rarity: .epic,
            primaryStat: .wisdom, statBonus: 8,
            secondaryStat: .dexterity, secondaryStatBonus: 5,
            levelRequirement: 21, baseType: "cloak"
        ),
        EquipmentTemplate(
            id: "trk_cloak_legendary_01",
            name: "Mantle of the Unseen",
            description: "Woven from pure possibility. Its wearer can be anywhere and nowhere simultaneously.",
            slot: .trinket, rarity: .legendary,
            primaryStat: .dexterity, statBonus: 13,
            secondaryStat: .luck, secondaryStatBonus: 10,
            levelRequirement: 36, baseType: "cloak"
        ),
    ]
    
    // MARK: Bracelets
    
    static let bracelets: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "trk_bracelet_common_01",
            name: "Woven Friendship Band",
            description: "A colorful thread bracelet. Its magic comes from the love put into making it.",
            slot: .trinket, rarity: .common,
            primaryStat: .charisma, statBonus: 1,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "bracelet"
        ),
        EquipmentTemplate(
            id: "trk_bracelet_uncommon_01",
            name: "Iron Willpower Cuff",
            description: "A heavy cuff inscribed with discipline mantras. It keeps you focused when willpower wavers.",
            slot: .trinket, rarity: .uncommon,
            primaryStat: .strength, statBonus: 3,
            secondaryStat: .defense, secondaryStatBonus: 1,
            levelRequirement: 4, baseType: "bracelet"
        ),
        EquipmentTemplate(
            id: "trk_bracelet_rare_01",
            name: "Oathbound Bangle",
            description: "One of a bonded pair. When your ally is near, the gems glow bright.",
            slot: .trinket, rarity: .rare,
            primaryStat: .charisma, statBonus: 5,
            secondaryStat: .luck, secondaryStatBonus: 4,
            levelRequirement: 11, baseType: "bracelet"
        ),
        EquipmentTemplate(
            id: "trk_bracelet_epic_01",
            name: "Temporal Armlet",
            description: "A bracelet that exists slightly out of sync with time. Reactions feel... anticipated.",
            slot: .trinket, rarity: .epic,
            primaryStat: .dexterity, statBonus: 8,
            secondaryStat: .wisdom, secondaryStatBonus: 5,
            levelRequirement: 21, baseType: "bracelet"
        ),
        EquipmentTemplate(
            id: "trk_bracelet_legendary_01",
            name: "Infinity Loop",
            description: "A bracelet with no beginning and no end. Time, space, and limits mean nothing to its wearer.",
            slot: .trinket, rarity: .legendary,
            primaryStat: .luck, statBonus: 14,
            secondaryStat: .dexterity, secondaryStatBonus: 9,
            levelRequirement: 37, baseType: "bracelet"
        ),
    ]
    
    // MARK: Charms
    
    static let charms: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "trk_charm_common_01",
            name: "Lucky Penny Charm",
            description: "It was heads-up when you found it. That counts for something, right?",
            slot: .trinket, rarity: .common,
            primaryStat: .luck, statBonus: 2,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "charm"
        ),
        EquipmentTemplate(
            id: "trk_charm_uncommon_01",
            name: "Four-Leaf Crystal",
            description: "A four-leaf clover preserved perfectly in amber crystal. Fortune follows where it goes.",
            slot: .trinket, rarity: .uncommon,
            primaryStat: .luck, statBonus: 4,
            secondaryStat: .charisma, secondaryStatBonus: 1,
            levelRequirement: 4, baseType: "charm"
        ),
        EquipmentTemplate(
            id: "trk_charm_rare_01",
            name: "Heartstone Charm",
            description: "A warm, rose-colored stone that resonates with emotional bonds. Allies feel its pulse.",
            slot: .trinket, rarity: .rare,
            primaryStat: .charisma, statBonus: 6,
            secondaryStat: .luck, secondaryStatBonus: 3,
            levelRequirement: 12, baseType: "charm"
        ),
        EquipmentTemplate(
            id: "trk_charm_epic_01",
            name: "Dragon's Eye Charm",
            description: "A slitted gemstone that sees through illusions and into the hearts of others.",
            slot: .trinket, rarity: .epic,
            primaryStat: .wisdom, statBonus: 8,
            secondaryStat: .luck, secondaryStatBonus: 6,
            levelRequirement: 20, baseType: "charm"
        ),
        EquipmentTemplate(
            id: "trk_charm_legendary_01",
            name: "Wishing Star Fragment",
            description: "A piece of a fallen star that still burns with the wishes of a thousand dreamers.",
            slot: .trinket, rarity: .legendary,
            primaryStat: .luck, statBonus: 15,
            secondaryStat: .charisma, secondaryStatBonus: 8,
            levelRequirement: 34, baseType: "charm"
        ),
    ]
    
    // MARK: Pendants
    
    static let pendants: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "acc_pendant_common_01",
            name: "Polished Stone Pendant",
            description: "A smooth river stone on a leather thong. Simple and grounding.",
            slot: .accessory, rarity: .common,
            primaryStat: .defense, statBonus: 1,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "pendant"
        ),
        EquipmentTemplate(
            id: "acc_pendant_uncommon_01",
            name: "Moonstone Pendant",
            description: "A pendant that glows softly in darkness. It brings peaceful dreams and steady nerves.",
            slot: .accessory, rarity: .uncommon,
            primaryStat: .wisdom, statBonus: 3,
            secondaryStat: .defense, secondaryStatBonus: 1,
            levelRequirement: 5, baseType: "pendant"
        ),
        EquipmentTemplate(
            id: "acc_pendant_rare_01",
            name: "Locket of Memories",
            description: "This locket replays cherished memories when opened. The nostalgia strengthens resolve.",
            slot: .accessory, rarity: .rare,
            primaryStat: .charisma, statBonus: 5,
            secondaryStat: .wisdom, secondaryStatBonus: 3,
            levelRequirement: 12, baseType: "pendant"
        ),
        EquipmentTemplate(
            id: "acc_pendant_epic_01",
            name: "Soulbinder's Locket",
            description: "Contains a fragment of a bonded partner's essence. Distance cannot weaken this connection.",
            slot: .accessory, rarity: .epic,
            primaryStat: .charisma, statBonus: 9,
            secondaryStat: .strength, secondaryStatBonus: 4,
            levelRequirement: 22, baseType: "pendant"
        ),
        EquipmentTemplate(
            id: "acc_pendant_legendary_01",
            name: "Aether Heart",
            description: "A pendant containing a miniature universe. Its wearer commands the fundamental forces.",
            slot: .accessory, rarity: .legendary,
            primaryStat: .wisdom, statBonus: 14,
            secondaryStat: .charisma, secondaryStatBonus: 10,
            levelRequirement: 38, baseType: "pendant"
        ),
    ]
    
    // =========================================================================
    // MARK: - TRINKETS  (20 items: 4 base types × 5 rarities)
    // =========================================================================
    
    static let trinkets: [EquipmentTemplate] = cloaks + bracelets + charms + belts
    
    // MARK: Belts
    
    static let belts: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "trk_belt_common_01",
            name: "Rope Sash",
            description: "A length of rope tied around the waist. It holds your pants up and your potions close.",
            slot: .trinket, rarity: .common,
            primaryStat: .strength, statBonus: 1,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "belt"
        ),
        EquipmentTemplate(
            id: "trk_belt_uncommon_01",
            name: "Adventurer's Utility Belt",
            description: "Pockets, loops, and pouches for everything. Organization is the real superpower.",
            slot: .trinket, rarity: .uncommon,
            primaryStat: .dexterity, statBonus: 3,
            secondaryStat: .strength, secondaryStatBonus: 1,
            levelRequirement: 4, baseType: "belt"
        ),
        EquipmentTemplate(
            id: "trk_belt_rare_01",
            name: "Belt of the Marathon",
            description: "Enchanted to redistribute weight perfectly. Long journeys feel like morning strolls.",
            slot: .trinket, rarity: .rare,
            primaryStat: .dexterity, statBonus: 5,
            secondaryStat: .strength, secondaryStatBonus: 3,
            levelRequirement: 11, baseType: "belt"
        ),
        EquipmentTemplate(
            id: "trk_belt_epic_01",
            name: "Champion's War Girdle",
            description: "Won by defeating a hundred challengers. It magnifies physical prowess and fighting spirit.",
            slot: .trinket, rarity: .epic,
            primaryStat: .strength, statBonus: 8,
            secondaryStat: .defense, secondaryStatBonus: 5,
            levelRequirement: 22, baseType: "belt"
        ),
        EquipmentTemplate(
            id: "trk_belt_legendary_01",
            name: "Girdle of World-Bearing",
            description: "Replicated from the belt of the titan who holds up the sky. Limitless endurance flows through it.",
            slot: .trinket, rarity: .legendary,
            primaryStat: .strength, statBonus: 14,
            secondaryStat: .defense, secondaryStatBonus: 9,
            levelRequirement: 36, baseType: "belt"
        ),
    ]
    
    // =========================================================================
    // MARK: - NEW WEAPONS  (20 items: 4 base types × 5 rarities)
    // =========================================================================
    
    // MARK: Shields
    
    static let shields: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "wep_shield_common_01",
            name: "Splintered Buckler",
            description: "A small wooden shield with more cracks than confidence. Better than nothing.",
            slot: .weapon, rarity: .common,
            primaryStat: .defense, statBonus: 2,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "shield"
        ),
        EquipmentTemplate(
            id: "wep_shield_uncommon_01",
            name: "Iron Kite Shield",
            description: "A sturdy iron shield shaped like a kite. Reliable protection for the disciplined warrior.",
            slot: .weapon, rarity: .uncommon,
            primaryStat: .defense, statBonus: 4,
            secondaryStat: .strength, secondaryStatBonus: 2,
            levelRequirement: 6, baseType: "shield"
        ),
        EquipmentTemplate(
            id: "wep_shield_rare_01",
            name: "Tower Shield of the Vanguard",
            description: "A massive wall of reinforced steel. Arrows bounce off it like rain off stone.",
            slot: .weapon, rarity: .rare,
            primaryStat: .defense, statBonus: 7,
            secondaryStat: .strength, secondaryStatBonus: 3,
            levelRequirement: 14, baseType: "shield"
        ),
        EquipmentTemplate(
            id: "wep_shield_epic_01",
            name: "Dragon Scale Aegis",
            description: "Forged from overlapping dragon scales. Fire washes over it harmlessly, and blades slide away.",
            slot: .weapon, rarity: .epic,
            primaryStat: .defense, statBonus: 11,
            secondaryStat: .strength, secondaryStatBonus: 5,
            levelRequirement: 25, baseType: "shield"
        ),
        EquipmentTemplate(
            id: "wep_shield_legendary_01",
            name: "Aegis of Ages",
            description: "This shield has witnessed every war in recorded history. It remembers, and it will not yield.",
            slot: .weapon, rarity: .legendary,
            primaryStat: .defense, statBonus: 17,
            secondaryStat: .charisma, secondaryStatBonus: 8,
            levelRequirement: 40, baseType: "shield"
        ),
    ]
    
    // MARK: Crossbows
    
    static let crossbows: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "wep_crossbow_common_01",
            name: "Light Crossbow",
            description: "Simple to operate and easy to aim. Point, squeeze, hope for the best.",
            slot: .weapon, rarity: .common,
            primaryStat: .dexterity, statBonus: 2,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "crossbow"
        ),
        EquipmentTemplate(
            id: "wep_crossbow_uncommon_01",
            name: "Repeating Crossbow",
            description: "A clever mechanism feeds bolts automatically. Volume of fire makes up for accuracy.",
            slot: .weapon, rarity: .uncommon,
            primaryStat: .dexterity, statBonus: 4,
            secondaryStat: .strength, secondaryStatBonus: 2,
            levelRequirement: 5, baseType: "crossbow"
        ),
        EquipmentTemplate(
            id: "wep_crossbow_rare_01",
            name: "Heavy Arbalest",
            description: "A massive crossbow with a winch-crank draw. Each bolt hits like a battering ram.",
            slot: .weapon, rarity: .rare,
            primaryStat: .dexterity, statBonus: 7,
            secondaryStat: .strength, secondaryStatBonus: 3,
            levelRequirement: 13, baseType: "crossbow"
        ),
        EquipmentTemplate(
            id: "wep_crossbow_epic_01",
            name: "Siege Crossbow",
            description: "Originally designed to breach castle walls. Overkill for most situations, but gloriously so.",
            slot: .weapon, rarity: .epic,
            primaryStat: .dexterity, statBonus: 10,
            secondaryStat: .defense, secondaryStatBonus: 5,
            levelRequirement: 23, baseType: "crossbow"
        ),
        EquipmentTemplate(
            id: "wep_crossbow_legendary_01",
            name: "Arbalest of Ruin",
            description: "Its bolts pierce through dimensions. What it hits stops existing in a very permanent way.",
            slot: .weapon, rarity: .legendary,
            primaryStat: .dexterity, statBonus: 16,
            secondaryStat: .luck, secondaryStatBonus: 8,
            levelRequirement: 37, baseType: "crossbow"
        ),
    ]
    
    // MARK: Tomes
    
    static let tomes: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "wep_tome_common_01",
            name: "Worn Tome",
            description: "A battered book of basic incantations. Half the pages are missing, but the spells still work. Mostly.",
            slot: .weapon, rarity: .common,
            primaryStat: .wisdom, statBonus: 2,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "tome"
        ),
        EquipmentTemplate(
            id: "wep_tome_uncommon_01",
            name: "Scholar's Tome",
            description: "A well-organized grimoire with detailed annotations. Knowledge is the sharpest weapon.",
            slot: .weapon, rarity: .uncommon,
            primaryStat: .wisdom, statBonus: 5,
            secondaryStat: .charisma, secondaryStatBonus: 1,
            levelRequirement: 5, baseType: "tome"
        ),
        EquipmentTemplate(
            id: "wep_tome_rare_01",
            name: "Arcane Grimoire",
            description: "Its pages rewrite themselves to match the reader's deepest questions. The answers are always cryptic.",
            slot: .weapon, rarity: .rare,
            primaryStat: .wisdom, statBonus: 7,
            secondaryStat: .luck, secondaryStatBonus: 3,
            levelRequirement: 13, baseType: "tome"
        ),
        EquipmentTemplate(
            id: "wep_tome_epic_01",
            name: "Eldritch Codex",
            description: "Bound in shadow-leather, written in a language that hurts to read. Understanding it changes you.",
            slot: .weapon, rarity: .epic,
            primaryStat: .wisdom, statBonus: 11,
            secondaryStat: .defense, secondaryStatBonus: 4,
            levelRequirement: 24, baseType: "tome"
        ),
        EquipmentTemplate(
            id: "wep_tome_legendary_01",
            name: "Tome of Infinite Wisdom",
            description: "A book with no last page. Every answer leads to a deeper question. Enlightenment is the journey, not the destination.",
            slot: .weapon, rarity: .legendary,
            primaryStat: .wisdom, statBonus: 17,
            secondaryStat: .charisma, secondaryStatBonus: 9,
            levelRequirement: 40, baseType: "tome"
        ),
    ]
    
    // MARK: Halberds
    
    static let halberds: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "wep_halberd_common_01",
            name: "Rusty Halberd",
            description: "Part axe, part spear, entirely unreliable. The head wobbles with every swing.",
            slot: .weapon, rarity: .common,
            primaryStat: .strength, statBonus: 3,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "halberd"
        ),
        EquipmentTemplate(
            id: "wep_halberd_uncommon_01",
            name: "Steel Halberd",
            description: "A properly forged polearm with a keen edge. Reach and power in one elegant package.",
            slot: .weapon, rarity: .uncommon,
            primaryStat: .strength, statBonus: 5,
            secondaryStat: .dexterity, secondaryStatBonus: 2,
            levelRequirement: 6, baseType: "halberd"
        ),
        EquipmentTemplate(
            id: "wep_halberd_rare_01",
            name: "War Halberd",
            description: "Battle-tested and blood-stained. Its sweeping strikes can hold an entire corridor alone.",
            slot: .weapon, rarity: .rare,
            primaryStat: .strength, statBonus: 7,
            secondaryStat: .defense, secondaryStatBonus: 3,
            levelRequirement: 14, baseType: "halberd"
        ),
        EquipmentTemplate(
            id: "wep_halberd_epic_01",
            name: "Runic Halberd",
            description: "Ancient runes spiral up the haft, empowering every strike with elemental fury.",
            slot: .weapon, rarity: .epic,
            primaryStat: .strength, statBonus: 11,
            secondaryStat: .wisdom, secondaryStatBonus: 5,
            levelRequirement: 25, baseType: "halberd"
        ),
        EquipmentTemplate(
            id: "wep_halberd_legendary_01",
            name: "Worldsplitter Halberd",
            description: "The weapon of the titan who carved the continents apart. Each swing reshapes the land beneath it.",
            slot: .weapon, rarity: .legendary,
            primaryStat: .strength, statBonus: 17,
            secondaryStat: .dexterity, secondaryStatBonus: 8,
            levelRequirement: 39, baseType: "halberd"
        ),
    ]
    
    // =========================================================================
    // MARK: - NEW ARMOR  (15 items: 3 base types × 5 rarities)
    // =========================================================================
    
    // MARK: Boots
    
    static let boots: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "arm_boots_common_01",
            name: "Worn Sandals",
            description: "Flimsy footwear that barely qualifies as protection. At least they're breathable.",
            slot: .armor, rarity: .common,
            primaryStat: .dexterity, statBonus: 1,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "boots"
        ),
        EquipmentTemplate(
            id: "arm_boots_uncommon_01",
            name: "Leather Boots",
            description: "Sturdy boots with good ankle support. A traveler's essential companion on any road.",
            slot: .armor, rarity: .uncommon,
            primaryStat: .dexterity, statBonus: 3,
            secondaryStat: .defense, secondaryStatBonus: 1,
            levelRequirement: 5, baseType: "boots"
        ),
        EquipmentTemplate(
            id: "arm_boots_rare_01",
            name: "Plated Greaves",
            description: "Steel-plated boots that protect from knee to toe. Heavy but formidable.",
            slot: .armor, rarity: .rare,
            primaryStat: .dexterity, statBonus: 5,
            secondaryStat: .defense, secondaryStatBonus: 3,
            levelRequirement: 12, baseType: "boots"
        ),
        EquipmentTemplate(
            id: "arm_boots_epic_01",
            name: "Enchanted Greaves",
            description: "These boots lighten with every step. Sprint at full speed in full plate without breaking a sweat.",
            slot: .armor, rarity: .epic,
            primaryStat: .dexterity, statBonus: 9,
            secondaryStat: .defense, secondaryStatBonus: 4,
            levelRequirement: 22, baseType: "boots"
        ),
        EquipmentTemplate(
            id: "arm_boots_legendary_01",
            name: "Stormstrider Boots",
            description: "Each step crackles with lightning. The wearer moves at the speed of thought.",
            slot: .armor, rarity: .legendary,
            primaryStat: .dexterity, statBonus: 14,
            secondaryStat: .luck, secondaryStatBonus: 8,
            levelRequirement: 36, baseType: "boots"
        ),
    ]
    
    // MARK: Pauldrons
    
    static let pauldrons: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "arm_pauldrons_common_01",
            name: "Cloth Pauldrons",
            description: "Padded shoulder wraps that offer minimal protection. At least they look intentional.",
            slot: .armor, rarity: .common,
            primaryStat: .defense, statBonus: 1,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "pauldrons"
        ),
        EquipmentTemplate(
            id: "arm_pauldrons_uncommon_01",
            name: "Iron Pauldrons",
            description: "Solid iron shoulder guards that deflect glancing blows. The mark of a proper soldier.",
            slot: .armor, rarity: .uncommon,
            primaryStat: .defense, statBonus: 3,
            secondaryStat: .strength, secondaryStatBonus: 2,
            levelRequirement: 6, baseType: "pauldrons"
        ),
        EquipmentTemplate(
            id: "arm_pauldrons_rare_01",
            name: "Steel Pauldrons",
            description: "Mirror-polished steel that intimidates before it protects. Arrows glance off harmlessly.",
            slot: .armor, rarity: .rare,
            primaryStat: .defense, statBonus: 5,
            secondaryStat: .strength, secondaryStatBonus: 4,
            levelRequirement: 13, baseType: "pauldrons"
        ),
        EquipmentTemplate(
            id: "arm_pauldrons_epic_01",
            name: "Dragonbone Pauldrons",
            description: "Carved from the shoulder bones of an ancient dragon. They radiate primal power.",
            slot: .armor, rarity: .epic,
            primaryStat: .defense, statBonus: 8,
            secondaryStat: .strength, secondaryStatBonus: 6,
            levelRequirement: 24, baseType: "pauldrons"
        ),
        EquipmentTemplate(
            id: "arm_pauldrons_legendary_01",
            name: "Titan Pauldrons",
            description: "Forged from the armor of a fallen titan. The weight of the world rests easily on these shoulders.",
            slot: .armor, rarity: .legendary,
            primaryStat: .defense, statBonus: 13,
            secondaryStat: .strength, secondaryStatBonus: 10,
            levelRequirement: 38, baseType: "pauldrons"
        ),
    ]
    
    // MARK: Capes
    
    static let capes: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "arm_cape_common_01",
            name: "Traveler's Cape",
            description: "A simple travel cape that keeps the wind at bay. It billows dramatically in doorways.",
            slot: .armor, rarity: .common,
            primaryStat: .charisma, statBonus: 1,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "cape"
        ),
        EquipmentTemplate(
            id: "arm_cape_uncommon_01",
            name: "Silk Cape",
            description: "Fine silk dyed in rich colors. It commands attention and respect in equal measure.",
            slot: .armor, rarity: .uncommon,
            primaryStat: .charisma, statBonus: 3,
            secondaryStat: .defense, secondaryStatBonus: 1,
            levelRequirement: 5, baseType: "cape"
        ),
        EquipmentTemplate(
            id: "arm_cape_rare_01",
            name: "Battle Cape",
            description: "Reinforced with chain links, this cape deflects strikes aimed at the back while looking magnificent.",
            slot: .armor, rarity: .rare,
            primaryStat: .charisma, statBonus: 5,
            secondaryStat: .defense, secondaryStatBonus: 3,
            levelRequirement: 12, baseType: "cape"
        ),
        EquipmentTemplate(
            id: "arm_cape_epic_01",
            name: "Royal Cape",
            description: "Trimmed with ermine and enchanted with authority. People instinctively step aside.",
            slot: .armor, rarity: .epic,
            primaryStat: .charisma, statBonus: 9,
            secondaryStat: .wisdom, secondaryStatBonus: 5,
            levelRequirement: 23, baseType: "cape"
        ),
        EquipmentTemplate(
            id: "arm_cape_legendary_01",
            name: "Sovereign's Mantle",
            description: "The cape of the last true sovereign. It grants the bearing of a born ruler and the will to match.",
            slot: .armor, rarity: .legendary,
            primaryStat: .charisma, statBonus: 14,
            secondaryStat: .wisdom, secondaryStatBonus: 9,
            levelRequirement: 37, baseType: "cape"
        ),
    ]
    
    // =========================================================================
    // MARK: - NEW ACCESSORIES  (15 items: 3 base types × 5 rarities)
    // =========================================================================
    
    // MARK: Earrings
    
    static let earrings: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "acc_earring_common_01",
            name: "Copper Stud",
            description: "A tiny copper earring that catches the light. Simple, but it makes you feel lucky.",
            slot: .accessory, rarity: .common,
            primaryStat: .luck, statBonus: 1,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "earring"
        ),
        EquipmentTemplate(
            id: "acc_earring_uncommon_01",
            name: "Silver Earring",
            description: "A polished silver hoop that glints when fortune is near. Old superstition, but it works.",
            slot: .accessory, rarity: .uncommon,
            primaryStat: .luck, statBonus: 3,
            secondaryStat: .charisma, secondaryStatBonus: 2,
            levelRequirement: 4, baseType: "earring"
        ),
        EquipmentTemplate(
            id: "acc_earring_rare_01",
            name: "Gold Earring",
            description: "Pure gold with an embedded opal that shifts color. Opportunities seem to find its wearer.",
            slot: .accessory, rarity: .rare,
            primaryStat: .luck, statBonus: 6,
            secondaryStat: .charisma, secondaryStatBonus: 3,
            levelRequirement: 12, baseType: "earring"
        ),
        EquipmentTemplate(
            id: "acc_earring_epic_01",
            name: "Gemmed Earring",
            description: "A perfect ruby set in enchanted platinum. Its wearer hears whispers of probability bending.",
            slot: .accessory, rarity: .epic,
            primaryStat: .luck, statBonus: 9,
            secondaryStat: .wisdom, secondaryStatBonus: 5,
            levelRequirement: 21, baseType: "earring"
        ),
        EquipmentTemplate(
            id: "acc_earring_legendary_01",
            name: "Earring of Fate",
            description: "Said to be crafted from a fragment of destiny's loom. The universe conspires in its wearer's favor.",
            slot: .accessory, rarity: .legendary,
            primaryStat: .luck, statBonus: 15,
            secondaryStat: .charisma, secondaryStatBonus: 9,
            levelRequirement: 36, baseType: "earring"
        ),
    ]
    
    // MARK: Brooches
    
    static let brooches: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "acc_brooch_common_01",
            name: "Plain Brooch",
            description: "A simple metal pin that holds your cloak in place. Functional, unremarkable, dependable.",
            slot: .accessory, rarity: .common,
            primaryStat: .charisma, statBonus: 1,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "brooch"
        ),
        EquipmentTemplate(
            id: "acc_brooch_uncommon_01",
            name: "Ornate Brooch",
            description: "Filigree silver work shaped like a blooming rose. It marks its wearer as someone of taste.",
            slot: .accessory, rarity: .uncommon,
            primaryStat: .charisma, statBonus: 3,
            secondaryStat: .defense, secondaryStatBonus: 1,
            levelRequirement: 5, baseType: "brooch"
        ),
        EquipmentTemplate(
            id: "acc_brooch_rare_01",
            name: "Crystal Brooch",
            description: "A brooch housing a living crystal that refracts light into mesmerizing patterns. Hard to look away.",
            slot: .accessory, rarity: .rare,
            primaryStat: .charisma, statBonus: 6,
            secondaryStat: .wisdom, secondaryStatBonus: 3,
            levelRequirement: 12, baseType: "brooch"
        ),
        EquipmentTemplate(
            id: "acc_brooch_epic_01",
            name: "Royal Brooch",
            description: "Bearing the crest of a dynasty long passed. Its authority transcends time and lineage.",
            slot: .accessory, rarity: .epic,
            primaryStat: .charisma, statBonus: 9,
            secondaryStat: .luck, secondaryStatBonus: 5,
            levelRequirement: 22, baseType: "brooch"
        ),
        EquipmentTemplate(
            id: "acc_brooch_legendary_01",
            name: "Brooch of the Eternal Court",
            description: "Worn by the immortal emissaries of the fey court. Mortals bow without knowing why.",
            slot: .accessory, rarity: .legendary,
            primaryStat: .charisma, statBonus: 15,
            secondaryStat: .luck, secondaryStatBonus: 10,
            levelRequirement: 38, baseType: "brooch"
        ),
    ]
    
    // MARK: Talismans
    
    static let talismans: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "acc_talisman_common_01",
            name: "Wooden Talisman",
            description: "A hand-carved token from a sacred tree. It hums faintly with old forest magic.",
            slot: .accessory, rarity: .common,
            primaryStat: .wisdom, statBonus: 1,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "talisman"
        ),
        EquipmentTemplate(
            id: "acc_talisman_uncommon_01",
            name: "Carved Talisman",
            description: "Intricate runes cover every surface. The carver's intent is clear: protection and insight.",
            slot: .accessory, rarity: .uncommon,
            primaryStat: .wisdom, statBonus: 3,
            secondaryStat: .defense, secondaryStatBonus: 2,
            levelRequirement: 5, baseType: "talisman"
        ),
        EquipmentTemplate(
            id: "acc_talisman_rare_01",
            name: "Enchanted Talisman",
            description: "A talisman that glows with inner light. It responds to its bearer's thoughts and sharpens focus.",
            slot: .accessory, rarity: .rare,
            primaryStat: .wisdom, statBonus: 5,
            secondaryStat: .luck, secondaryStatBonus: 4,
            levelRequirement: 12, baseType: "talisman"
        ),
        EquipmentTemplate(
            id: "acc_talisman_epic_01",
            name: "Ancient Talisman",
            description: "Pre-dates recorded history. The knowledge of civilizations long forgotten is sealed within.",
            slot: .accessory, rarity: .epic,
            primaryStat: .wisdom, statBonus: 9,
            secondaryStat: .defense, secondaryStatBonus: 5,
            levelRequirement: 22, baseType: "talisman"
        ),
        EquipmentTemplate(
            id: "acc_talisman_legendary_01",
            name: "Talisman of the Void",
            description: "Contains a pocket of pure nothingness. From nothing, all things are possible.",
            slot: .accessory, rarity: .legendary,
            primaryStat: .wisdom, statBonus: 14,
            secondaryStat: .luck, secondaryStatBonus: 10,
            levelRequirement: 38, baseType: "talisman"
        ),
    ]
}
