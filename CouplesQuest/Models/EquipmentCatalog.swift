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
    let statBonus: Double
    let secondaryStat: StatType?
    let secondaryStatBonus: Double
    let levelRequirement: Int
    let baseType: String              // keyword for image mapping ("sword", "axe", etc.)
    
    /// Armor weight derived from base type
    var armorWeight: ArmorWeight {
        switch baseType {
        case "plate", "chainmail", "breastplate", "pauldrons",
             "heavy helm", "heavy gauntlets", "heavy boots":
            return .heavy
        case "tunic", "leather armor", "helm", "gauntlets", "boots":
            return .light
        default:
            return .universal
        }
    }
    
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
            ownerID: ownerID,
            baseType: baseType
        )
    }
}

// MARK: - Equipment Catalog

/// Master catalog of all curated base-game equipment.
/// The loot system draws from this catalog so players discover recognisable, hand-crafted items.
struct EquipmentCatalog {
    
    // MARK: - Public API
    
    /// Every item in the game
    static let all: [EquipmentTemplate] = weapons + armor + accessories + trinkets + cloaks
    
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
    /// When `allowedWeights` is provided, only armor matching those weights is included.
    /// When `allowedBaseTypes` is provided, only items with matching base types are included.
    static func random(slot: EquipmentSlot? = nil, rarity: ItemRarity? = nil, maxLevel: Int? = nil, allowedWeights: Set<ArmorWeight>? = nil, allowedBaseTypes: Set<String>? = nil) -> EquipmentTemplate? {
        var pool = all
        if let slot = slot { pool = pool.filter { $0.slot == slot } }
        if let rarity = rarity { pool = pool.filter { $0.rarity == rarity } }
        if let maxLevel = maxLevel { pool = pool.filter { $0.levelRequirement <= maxLevel } }
        if let weights = allowedWeights { pool = pool.filter { weights.contains($0.armorWeight) } }
        if let bases = allowedBaseTypes { pool = pool.filter { bases.contains($0.baseType.lowercased()) } }
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
            description: "A blade so dull it apologizes before each swing. You are technically armed.",
            slot: .weapon, rarity: .common,
            primaryStat: .strength, statBonus: 2,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "sword"
        ),
        // Uncommon
        EquipmentTemplate(
            id: "wep_sword_uncommon_01",
            name: "Steel Longsword",
            description: "Does exactly what it says on the tin. No frills, no magic, just competent steel and a quiet sense of superiority.",
            slot: .weapon, rarity: .uncommon,
            primaryStat: .strength, statBonus: 4,
            secondaryStat: .defense, secondaryStatBonus: 1,
            levelRequirement: 5, baseType: "sword"
        ),
        // Rare
        EquipmentTemplate(
            id: "wep_sword_rare_01",
            name: "Runic Claymore",
            description: "Found in a lake by a confused fisherman who was just trying to catch bass. The runes translate to 'Return to Sender.'",
            slot: .weapon, rarity: .rare,
            primaryStat: .strength, statBonus: 6,
            secondaryStat: .wisdom, secondaryStatBonus: 3,
            levelRequirement: 12, baseType: "sword"
        ),
        // Epic
        EquipmentTemplate(
            id: "wep_sword_epic_01",
            name: "Dragonbane Greatsword",
            description: "Tempered in dragonfire, quenched in the tears of a weeping god, and polished with DRAMA. It's a lot.",
            slot: .weapon, rarity: .epic,
            primaryStat: .strength, statBonus: 10,
            secondaryStat: .dexterity, secondaryStatBonus: 4,
            levelRequirement: 22, baseType: "sword"
        ),
        // Legendary
        EquipmentTemplate(
            id: "wep_sword_legendary_01",
            name: "Excalibur, Blade of Dawn",
            description: "The legendary sword that chooses its wielder through a sacred ritual of destiny and fate. It chose you, which raises concerns about its judgment.",
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
            description: "This axe has killed more firewood than monsters. Your enemies will die of tetanus before blood loss.",
            slot: .weapon, rarity: .common,
            primaryStat: .strength, statBonus: 3,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "axe"
        ),
        EquipmentTemplate(
            id: "wep_axe_uncommon_01",
            name: "Ironclad Battleaxe",
            description: "Heavy enough to solve most problems. The problems it can't solve weren't worth solving.",
            slot: .weapon, rarity: .uncommon,
            primaryStat: .strength, statBonus: 5,
            secondaryStat: .defense, secondaryStatBonus: 1,
            levelRequirement: 6, baseType: "axe"
        ),
        EquipmentTemplate(
            id: "wep_axe_rare_01",
            name: "Frostbite Cleaver",
            description: "Accidentally left in a glacier by a forgetful frost giant for three thousand years. He wants it back, by the way.",
            slot: .weapon, rarity: .rare,
            primaryStat: .strength, statBonus: 7,
            secondaryStat: .dexterity, secondaryStatBonus: 3,
            levelRequirement: 14, baseType: "axe"
        ),
        EquipmentTemplate(
            id: "wep_axe_epic_01",
            name: "Worldsplitter",
            description: "They say this axe once cleaved a mountain in two. The mountain's therapist says it's still working through it.",
            slot: .weapon, rarity: .epic,
            primaryStat: .strength, statBonus: 11,
            secondaryStat: .defense, secondaryStatBonus: 5,
            levelRequirement: 25, baseType: "axe"
        ),
        EquipmentTemplate(
            id: "wep_axe_legendary_01",
            name: "Ragnarok, the End of Ages",
            description: "Forged in the heart of a dying star by a blacksmith with anger issues. The universe trembled. The blacksmith's Yelp review was 3 stars.",
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
            description: "It's a stick. You're holding a stick. Somewhere, a dog is very jealous.",
            slot: .weapon, rarity: .common,
            primaryStat: .wisdom, statBonus: 2,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "staff"
        ),
        EquipmentTemplate(
            id: "wep_staff_uncommon_01",
            name: "Oak Channeling Staff",
            description: "Channels magic about as well as a garden hose channels Niagara Falls. But it tries, and that's what matters.",
            slot: .weapon, rarity: .uncommon,
            primaryStat: .wisdom, statBonus: 4,
            secondaryStat: .charisma, secondaryStatBonus: 2,
            levelRequirement: 5, baseType: "staff"
        ),
        EquipmentTemplate(
            id: "wep_staff_rare_01",
            name: "Stormcaller's Crook",
            description: "Carved by a shepherd who got REALLY tired of wolves. The local weather service has filed multiple complaints.",
            slot: .weapon, rarity: .rare,
            primaryStat: .wisdom, statBonus: 7,
            secondaryStat: .strength, secondaryStatBonus: 2,
            levelRequirement: 13, baseType: "staff"
        ),
        EquipmentTemplate(
            id: "wep_staff_epic_01",
            name: "Archmage's Scepter",
            description: "Contains the accumulated wisdom of seventeen archmages, all of whom are backseat-casting from beyond the grave. Shut up, Aldric.",
            slot: .weapon, rarity: .epic,
            primaryStat: .wisdom, statBonus: 11,
            secondaryStat: .luck, secondaryStatBonus: 4,
            levelRequirement: 24, baseType: "staff"
        ),
        EquipmentTemplate(
            id: "wep_staff_legendary_01",
            name: "Yggdrasil's Root",
            description: "A living branch from the World Tree itself. It has opinions about your spellcasting. It is not impressed.",
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
            description: "Looks like it was forged by someone who heard a description of a knife but never actually saw one. Still pointy though.",
            slot: .weapon, rarity: .common,
            primaryStat: .dexterity, statBonus: 2,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "dagger"
        ),
        EquipmentTemplate(
            id: "wep_dagger_uncommon_01",
            name: "Viper Fang Stiletto",
            description: "Wickedly sharp, subtle, and sophisticated. Everything you're not, but at least you're holding it.",
            slot: .weapon, rarity: .uncommon,
            primaryStat: .dexterity, statBonus: 4,
            secondaryStat: .luck, secondaryStatBonus: 2,
            levelRequirement: 4, baseType: "dagger"
        ),
        EquipmentTemplate(
            id: "wep_dagger_rare_01",
            name: "Shadowstep Kris",
            description: "Won in a poker game against a shadow demon who, it turns out, has a terrible poker face. Well, no face.",
            slot: .weapon, rarity: .rare,
            primaryStat: .dexterity, statBonus: 6,
            secondaryStat: .strength, secondaryStatBonus: 3,
            levelRequirement: 11, baseType: "dagger"
        ),
        EquipmentTemplate(
            id: "wep_dagger_epic_01",
            name: "Nightwhisper",
            description: "A blade so silent it once snuck up on ITSELF. The resulting paradox destroyed two taverns and a philosophy department.",
            slot: .weapon, rarity: .epic,
            primaryStat: .dexterity, statBonus: 10,
            secondaryStat: .luck, secondaryStatBonus: 5,
            levelRequirement: 20, baseType: "dagger"
        ),
        EquipmentTemplate(
            id: "wep_dagger_legendary_01",
            name: "Oblivion's Kiss",
            description: "They say this dagger can sever fate itself. One scratch rewrites destiny. The warranty, however, is non-transferable.",
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
            description: "Fires arrows in the general direction of 'over there.' Your accuracy is a you problem, not a bow problem.",
            slot: .weapon, rarity: .common,
            primaryStat: .dexterity, statBonus: 2,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "bow"
        ),
        EquipmentTemplate(
            id: "wep_bow_uncommon_01",
            name: "Hunter's Recurve",
            description: "It doesn't miss often, and when it does, it has the decency to look embarrassed about it.",
            slot: .weapon, rarity: .uncommon,
            primaryStat: .dexterity, statBonus: 4,
            secondaryStat: .strength, secondaryStatBonus: 1,
            levelRequirement: 5, baseType: "bow"
        ),
        EquipmentTemplate(
            id: "wep_bow_rare_01",
            name: "Windrunner Longbow",
            description: "Originally owned by an elf who got lost, fired an arrow for directions, and accidentally founded an archery school.",
            slot: .weapon, rarity: .rare,
            primaryStat: .dexterity, statBonus: 7,
            secondaryStat: .luck, secondaryStatBonus: 3,
            levelRequirement: 13, baseType: "bow"
        ),
        EquipmentTemplate(
            id: "wep_bow_epic_01",
            name: "Celestial Warbow",
            description: "Each arrow trails a comet's tail across the sky, which is breathtaking, beautiful, and absolutely RUINS any attempt at stealth.",
            slot: .weapon, rarity: .epic,
            primaryStat: .dexterity, statBonus: 10,
            secondaryStat: .wisdom, secondaryStatBonus: 5,
            levelRequirement: 23, baseType: "bow"
        ),
        EquipmentTemplate(
            id: "wep_bow_legendary_01",
            name: "Artemis, the Moonlit Arc",
            description: "Blessed by the goddess of the hunt herself. Under moonlight, every shot hits. Under fluorescent lighting, no promises.",
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
            description: "It's basically a sparkler with a self-esteem problem. Wave it around and hope the enemy is impressed. They won't be.",
            slot: .weapon, rarity: .common,
            primaryStat: .wisdom, statBonus: 2,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "wand"
        ),
        EquipmentTemplate(
            id: "wep_wand_uncommon_01",
            name: "Ember Wand",
            description: "Perpetually warm, like a cup of tea you forgot about but can still technically drink. Casts spells the same way.",
            slot: .weapon, rarity: .uncommon,
            primaryStat: .wisdom, statBonus: 4,
            secondaryStat: .luck, secondaryStatBonus: 1,
            levelRequirement: 4, baseType: "wand"
        ),
        EquipmentTemplate(
            id: "wep_wand_rare_01",
            name: "Prismatic Focus",
            description: "Invented by a color-blind wizard who just wanted to see a rainbow. He saw one. Then it exploded. He's fine.",
            slot: .weapon, rarity: .rare,
            primaryStat: .wisdom, statBonus: 6,
            secondaryStat: .charisma, secondaryStatBonus: 3,
            levelRequirement: 12, baseType: "wand"
        ),
        EquipmentTemplate(
            id: "wep_wand_epic_01",
            name: "Void Siphon",
            description: "Drinks magic from the air like a dehydrated camel at an oasis. The raw destructive output is terrifying. The slurping sound is worse.",
            slot: .weapon, rarity: .epic,
            primaryStat: .wisdom, statBonus: 10,
            secondaryStat: .dexterity, secondaryStatBonus: 4,
            levelRequirement: 21, baseType: "wand"
        ),
        EquipmentTemplate(
            id: "wep_wand_legendary_01",
            name: "Merlin's Last Word",
            description: "The final creation of the greatest mage who ever lived. It thinks, it judges, and it will NOT stop giving unsolicited career advice.",
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
            description: "A lump of metal on a stick. This is where weapon design starts and ambition ends. You're welcome.",
            slot: .weapon, rarity: .common,
            primaryStat: .strength, statBonus: 2,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "mace"
        ),
        EquipmentTemplate(
            id: "wep_mace_uncommon_01",
            name: "Flanged War Mace",
            description: "Armor is merely a suggestion to this weapon. The suggestion is 'crumple.'",
            slot: .weapon, rarity: .uncommon,
            primaryStat: .strength, statBonus: 4,
            secondaryStat: .defense, secondaryStatBonus: 2,
            levelRequirement: 6, baseType: "mace"
        ),
        EquipmentTemplate(
            id: "wep_mace_rare_01",
            name: "Thundering Maul",
            description: "Fell off the back of a thunder god's chariot during a particularly nasty pothole. Nobody's come to claim it.",
            slot: .weapon, rarity: .rare,
            primaryStat: .strength, statBonus: 7,
            secondaryStat: .defense, secondaryStatBonus: 3,
            levelRequirement: 14, baseType: "mace"
        ),
        EquipmentTemplate(
            id: "wep_mace_epic_01",
            name: "Dawnbreaker",
            description: "A holy mace that blazes with the fury of a thousand suns. The undead flee. Your eyebrows also flee. Worth it.",
            slot: .weapon, rarity: .epic,
            primaryStat: .strength, statBonus: 10,
            secondaryStat: .charisma, secondaryStatBonus: 5,
            levelRequirement: 24, baseType: "mace"
        ),
        EquipmentTemplate(
            id: "wep_mace_legendary_01",
            name: "Mjolnir, the Stormhammer",
            description: "Only the worthy may lift it. So far the 'worthy' includes two heroes, a golden retriever, and one very determined toddler.",
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
            description: "A sharp stick that got promoted way above its pay grade. It has impostor syndrome and, honestly, valid.",
            slot: .weapon, rarity: .common,
            primaryStat: .dexterity, statBonus: 2,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "spear"
        ),
        EquipmentTemplate(
            id: "wep_spear_uncommon_01",
            name: "Bronze Partisan",
            description: "Perfectly adequate for both thrusting and sweeping. Also makes a surprisingly good coat rack in a pinch.",
            slot: .weapon, rarity: .uncommon,
            primaryStat: .dexterity, statBonus: 4,
            secondaryStat: .strength, secondaryStatBonus: 2,
            levelRequirement: 5, baseType: "spear"
        ),
        EquipmentTemplate(
            id: "wep_spear_rare_01",
            name: "Tidecaller Trident",
            description: "Pulled from the ocean by a fisherman who immediately quit his job and became an adventurer. His wife is still furious.",
            slot: .weapon, rarity: .rare,
            primaryStat: .dexterity, statBonus: 6,
            secondaryStat: .wisdom, secondaryStatBonus: 3,
            levelRequirement: 13, baseType: "spear"
        ),
        EquipmentTemplate(
            id: "wep_spear_epic_01",
            name: "Skypierce Lance",
            description: "So perfectly balanced it feels weightless. Thrown, it can punch through castle walls. The HOA is going to be livid.",
            slot: .weapon, rarity: .epic,
            primaryStat: .dexterity, statBonus: 10,
            secondaryStat: .strength, secondaryStatBonus: 5,
            levelRequirement: 23, baseType: "spear"
        ),
        EquipmentTemplate(
            id: "wep_spear_legendary_01",
            name: "Gungnir, the Allfather's Reach",
            description: "Once thrown, it never misses. NEVER. The Allfather threw it once as a test and it's been awkward at family dinners ever since.",
            slot: .weapon, rarity: .legendary,
            primaryStat: .dexterity, statBonus: 15,
            secondaryStat: .wisdom, secondaryStatBonus: 9,
            levelRequirement: 37, baseType: "spear"
        ),
    ]
    
    // =========================================================================
    // MARK: - ARMOR  (50 items: 10 base types × 5 rarities)
    // =========================================================================
    
    static let armor: [EquipmentTemplate] = plates + chainmails + leatherArmors + breastplates + helms + gauntlets + boots + pauldrons + heavyHelms + heavyGauntlets + heavyBoots + tunics
    
    // MARK: Plate
    
    static let plates: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "arm_plate_common_01",
            name: "Dented Iron Plate",
            description: "Offers the protection of a tin can and roughly the same comfort. Your starter armor, because the game had to give you something.",
            slot: .armor, rarity: .common,
            primaryStat: .defense, statBonus: 3,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "plate"
        ),
        EquipmentTemplate(
            id: "arm_plate_uncommon_01",
            name: "Steel Guardian Plate",
            description: "Properly fitted and only slightly crushing your organs. A solid upgrade for those who enjoy breathing occasionally.",
            slot: .armor, rarity: .uncommon,
            primaryStat: .defense, statBonus: 5,
            secondaryStat: .strength, secondaryStatBonus: 1,
            levelRequirement: 7, baseType: "plate"
        ),
        EquipmentTemplate(
            id: "arm_plate_rare_01",
            name: "Warden's Bulwark",
            description: "Enchanted by a wizard who got hit one too many times and said 'never again.' The harder you hit it, the more offended it gets.",
            slot: .armor, rarity: .rare,
            primaryStat: .defense, statBonus: 7,
            secondaryStat: .strength, secondaryStatBonus: 3,
            levelRequirement: 15, baseType: "plate"
        ),
        EquipmentTemplate(
            id: "arm_plate_epic_01",
            name: "Titanforge Warplate",
            description: "Forged from an alloy so rare the periodic table filed a restraining order. Blades don't just bounce off — they apologize.",
            slot: .armor, rarity: .epic,
            primaryStat: .defense, statBonus: 11,
            secondaryStat: .strength, secondaryStatBonus: 5,
            levelRequirement: 26, baseType: "plate"
        ),
        EquipmentTemplate(
            id: "arm_plate_legendary_01",
            name: "Aegis of the Immortal",
            description: "The last eternal guardian wore this into a thousand battles and zero funerals. Dry cleaning it requires a permit from three different gods.",
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
            description: "Sounds like a wind chime in combat. Enemies hear you coming from three rooms away, but at least you're jingly.",
            slot: .armor, rarity: .common,
            primaryStat: .defense, statBonus: 2,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "chainmail"
        ),
        EquipmentTemplate(
            id: "arm_chain_uncommon_01",
            name: "Riveted Hauberk",
            description: "Each ring individually riveted by someone with incredible patience and questionable life choices.",
            slot: .armor, rarity: .uncommon,
            primaryStat: .defense, statBonus: 4,
            secondaryStat: .dexterity, secondaryStatBonus: 2,
            levelRequirement: 6, baseType: "chainmail"
        ),
        EquipmentTemplate(
            id: "arm_chain_rare_01",
            name: "Mithril Weave",
            description: "Won in a poker game against an elf who swore it was 'just regular chainmail.' That elf doesn't play poker anymore.",
            slot: .armor, rarity: .rare,
            primaryStat: .defense, statBonus: 6,
            secondaryStat: .dexterity, secondaryStatBonus: 4,
            levelRequirement: 14, baseType: "chainmail"
        ),
        EquipmentTemplate(
            id: "arm_chain_epic_01",
            name: "Dragonlink Coat",
            description: "Each link is a miniature dragon scale. The dragons are furious about the unauthorized merchandise.",
            slot: .armor, rarity: .epic,
            primaryStat: .defense, statBonus: 9,
            secondaryStat: .dexterity, secondaryStatBonus: 5,
            levelRequirement: 24, baseType: "chainmail"
        ),
        EquipmentTemplate(
            id: "arm_chain_legendary_01",
            name: "Veil of the Valkyrie",
            description: "Woven by warrior-angels from threads of pure valor. The return policy requires dying honorably in battle.",
            slot: .armor, rarity: .legendary,
            primaryStat: .defense, statBonus: 15,
            secondaryStat: .luck, secondaryStatBonus: 8,
            levelRequirement: 37, baseType: "chainmail"
        ),
    ]
    
    // MARK: Robes (moved to cloak slot — mage-line cloaks)
    
    static let robes: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "arm_robes_common_01",
            name: "Threadbare Apprentice Robes",
            description: "Smells like old parchment and shattered academic dreams. The previous owner was expelled for 'creative spell interpretation.'",
            slot: .cloak, rarity: .common,
            primaryStat: .wisdom, statBonus: 2,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "robes"
        ),
        EquipmentTemplate(
            id: "arm_robes_uncommon_01",
            name: "Scholar's Vestments",
            description: "Clean, pressed, and covered in runes that roughly translate to 'please don't hit me.'",
            slot: .cloak, rarity: .uncommon,
            primaryStat: .wisdom, statBonus: 4,
            secondaryStat: .charisma, secondaryStatBonus: 2,
            levelRequirement: 5, baseType: "robes"
        ),
        EquipmentTemplate(
            id: "arm_robes_rare_01",
            name: "Astral Silkweave",
            description: "Woven by spiders from a dimension where fashion is the highest form of magic. Dry clean only — in that dimension.",
            slot: .cloak, rarity: .rare,
            primaryStat: .wisdom, statBonus: 7,
            secondaryStat: .defense, secondaryStatBonus: 2,
            levelRequirement: 13, baseType: "robes"
        ),
        EquipmentTemplate(
            id: "arm_robes_epic_01",
            name: "Mantle of the Archmage",
            description: "Spells weave themselves into the fabric. The robes actively deflect hostile magic.",
            slot: .cloak, rarity: .epic,
            primaryStat: .wisdom, statBonus: 10,
            secondaryStat: .defense, secondaryStatBonus: 5,
            levelRequirement: 24, baseType: "robes"
        ),
        EquipmentTemplate(
            id: "arm_robes_legendary_01",
            name: "Cosmos Regalia",
            description: "Woven from the dreams of a thousand sleeping wizards. Smells like lavender and existential dread.",
            slot: .cloak, rarity: .legendary,
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
            description: "Stitched from the hides of animals who probably weren't using them anymore. At least, you hope they weren't.",
            slot: .armor, rarity: .common,
            primaryStat: .dexterity, statBonus: 2,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "leather armor"
        ),
        EquipmentTemplate(
            id: "arm_leather_uncommon_01",
            name: "Ranger's Jerkin",
            description: "Dyed green for forest stealth. Unfortunately, you're rarely in a forest and now you just look like an asparagus.",
            slot: .armor, rarity: .uncommon,
            primaryStat: .dexterity, statBonus: 4,
            secondaryStat: .defense, secondaryStatBonus: 1,
            levelRequirement: 5, baseType: "leather armor"
        ),
        EquipmentTemplate(
            id: "arm_leather_rare_01",
            name: "Shadowskin Cuirass",
            description: "Treated with shadow-essence by a rogue who charged triple because 'you can't see me working.' Nobody could argue.",
            slot: .armor, rarity: .rare,
            primaryStat: .dexterity, statBonus: 6,
            secondaryStat: .luck, secondaryStatBonus: 3,
            levelRequirement: 12, baseType: "leather armor"
        ),
        EquipmentTemplate(
            id: "arm_leather_epic_01",
            name: "Wyrmhide Armor",
            description: "Tanned from an elder wyrm's hide. The wyrm was already dead. Probably. Look, don't ask follow-up questions.",
            slot: .armor, rarity: .epic,
            primaryStat: .dexterity, statBonus: 10,
            secondaryStat: .defense, secondaryStatBonus: 4,
            levelRequirement: 22, baseType: "leather armor"
        ),
        EquipmentTemplate(
            id: "arm_leather_legendary_01",
            name: "Phantom Shroud",
            description: "Woven from the echoes of a thousand whispered secrets. Most of them are just gossip, but the defense stats are real.",
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
            description: "The engraving wore off so long ago nobody knows whose crest it was. Including the breastplate.",
            slot: .armor, rarity: .common,
            primaryStat: .defense, statBonus: 2,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "breastplate"
        ),
        EquipmentTemplate(
            id: "arm_breast_uncommon_01",
            name: "Knight's Cuirass",
            description: "Bears the crest of a fallen order. They fell because they kept polishing their armor instead of fighting.",
            slot: .armor, rarity: .uncommon,
            primaryStat: .defense, statBonus: 4,
            secondaryStat: .charisma, secondaryStatBonus: 1,
            levelRequirement: 6, baseType: "breastplate"
        ),
        EquipmentTemplate(
            id: "arm_breast_rare_01",
            name: "Emberheart Guard",
            description: "Forged by a blacksmith who fell into his own furnace and emerged 'enlightened.' Perpetually warm and slightly unhinged.",
            slot: .armor, rarity: .rare,
            primaryStat: .defense, statBonus: 6,
            secondaryStat: .strength, secondaryStatBonus: 3,
            levelRequirement: 14, baseType: "breastplate"
        ),
        EquipmentTemplate(
            id: "arm_breast_epic_01",
            name: "Oathkeeper's Aegis",
            description: "Engraved with binding oaths of protection so lengthy, enemies fall asleep reading them. Technically a feature.",
            slot: .armor, rarity: .epic,
            primaryStat: .defense, statBonus: 10,
            secondaryStat: .charisma, secondaryStatBonus: 5,
            levelRequirement: 25, baseType: "breastplate"
        ),
        EquipmentTemplate(
            id: "arm_breast_legendary_01",
            name: "Soulforged Vestment",
            description: "Bound to its wearer's soul. It heals itself, grows with its bearer, and gets really passive-aggressive when you look at other armor.",
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
            description: "It's basically a bucket with eye holes. You'll look ridiculous, but head injuries don't care about fashion.",
            slot: .armor, rarity: .common,
            primaryStat: .defense, statBonus: 1,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "helm"
        ),
        EquipmentTemplate(
            id: "arm_helm_uncommon_01",
            name: "Steel Barbute",
            description: "A well-crafted helm with a T-shaped visor. Excellent protection. Terrible for eating soup.",
            slot: .armor, rarity: .uncommon,
            primaryStat: .defense, statBonus: 3,
            secondaryStat: .wisdom, secondaryStatBonus: 2,
            levelRequirement: 5, baseType: "helm"
        ),
        EquipmentTemplate(
            id: "arm_helm_rare_01",
            name: "Crown of the Vigilant",
            description: "Forged by an insomniac king who demanded to see everything at all times. He saw too much. He doesn't talk about it.",
            slot: .armor, rarity: .rare,
            primaryStat: .defense, statBonus: 5,
            secondaryStat: .wisdom, secondaryStatBonus: 4,
            levelRequirement: 13, baseType: "helm"
        ),
        EquipmentTemplate(
            id: "arm_helm_epic_01",
            name: "Dread Visage",
            description: "A terrifying horned helm that makes enemies flee in terror. Also makes doorways your mortal enemy.",
            slot: .armor, rarity: .epic,
            primaryStat: .defense, statBonus: 8,
            secondaryStat: .charisma, secondaryStatBonus: 6,
            levelRequirement: 23, baseType: "helm"
        ),
        EquipmentTemplate(
            id: "arm_helm_legendary_01",
            name: "Crown of the Conqueror",
            description: "Worn by the one who united all kingdoms. Mostly because nobody wanted to tell him the horns looked silly.",
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
            description: "They barely qualify as gauntlets. They barely qualify as gloves. But your hands are slightly less naked now.",
            slot: .armor, rarity: .common,
            primaryStat: .strength, statBonus: 1,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "gauntlets"
        ),
        EquipmentTemplate(
            id: "arm_gauntlets_uncommon_01",
            name: "Iron Grip Gauntlets",
            description: "Reinforced knuckles for a firm handshake that doubles as a threat. Networking has never been so aggressive.",
            slot: .armor, rarity: .uncommon,
            primaryStat: .strength, statBonus: 3,
            secondaryStat: .defense, secondaryStatBonus: 2,
            levelRequirement: 5, baseType: "gauntlets"
        ),
        EquipmentTemplate(
            id: "arm_gauntlets_rare_01",
            name: "Flameguard Gauntlets",
            description: "Enchanted by a wizard who kept burning his toast. Fireproof from fingertip to elbow. The toast issue remains unsolved.",
            slot: .armor, rarity: .rare,
            primaryStat: .strength, statBonus: 5,
            secondaryStat: .defense, secondaryStatBonus: 4,
            levelRequirement: 12, baseType: "gauntlets"
        ),
        EquipmentTemplate(
            id: "arm_gauntlets_epic_01",
            name: "Titan's Grasp",
            description: "Once you grab something, divine intervention is required to let go. Terrible for first dates. Incredible for battle.",
            slot: .armor, rarity: .epic,
            primaryStat: .strength, statBonus: 9,
            secondaryStat: .defense, secondaryStatBonus: 5,
            levelRequirement: 22, baseType: "gauntlets"
        ),
        EquipmentTemplate(
            id: "arm_gauntlets_legendary_01",
            name: "Hands of Creation",
            description: "Said to be replicas of the hands that shaped the world. Also excellent for opening stubborn pickle jars.",
            slot: .armor, rarity: .legendary,
            primaryStat: .strength, statBonus: 14,
            secondaryStat: .wisdom, secondaryStatBonus: 8,
            levelRequirement: 37, baseType: "gauntlets"
        ),
    ]
    
    // MARK: Tunics (mage light armor — replaces robes in the armor slot)
    
    static let tunics: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "arm_tunic_common_01",
            name: "Moth-Eaten Tunic",
            description: "More holes than fabric. The moths left a one-star review.",
            slot: .armor, rarity: .common,
            primaryStat: .wisdom, statBonus: 1,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "tunic"
        ),
        EquipmentTemplate(
            id: "arm_tunic_uncommon_01",
            name: "Apprentice's Vestment",
            description: "Comes pre-stained with potion residue. The previous owner 'graduated' abruptly.",
            slot: .armor, rarity: .uncommon,
            primaryStat: .wisdom, statBonus: 3,
            secondaryStat: .defense, secondaryStatBonus: 1,
            levelRequirement: 5, baseType: "tunic"
        ),
        EquipmentTemplate(
            id: "arm_tunic_rare_01",
            name: "Runewoven Vestment",
            description: "Protective runes stitched by someone who clearly ran out of thread halfway through.",
            slot: .armor, rarity: .rare,
            primaryStat: .wisdom, statBonus: 6,
            secondaryStat: .defense, secondaryStatBonus: 3,
            levelRequirement: 13, baseType: "tunic"
        ),
        EquipmentTemplate(
            id: "arm_tunic_epic_01",
            name: "Arcane-Threaded Vestment",
            description: "Each thread is a tiny spell. Dry cleaning costs more than most castles.",
            slot: .armor, rarity: .epic,
            primaryStat: .wisdom, statBonus: 9,
            secondaryStat: .defense, secondaryStatBonus: 5,
            levelRequirement: 24, baseType: "tunic"
        ),
        EquipmentTemplate(
            id: "arm_tunic_legendary_01",
            name: "Vestment of the Infinite",
            description: "Woven from the fabric of reality itself. Ironically, it wrinkles if you look at it wrong.",
            slot: .armor, rarity: .legendary,
            primaryStat: .wisdom, statBonus: 14,
            secondaryStat: .luck, secondaryStatBonus: 8,
            levelRequirement: 38, baseType: "tunic"
        ),
    ]
    
    // =========================================================================
    // MARK: - ACCESSORIES  (30+ items)
    // =========================================================================
    
    static let accessories: [EquipmentTemplate] = rings + amulets + earrings + talismans + pendants + brooches
    
    // MARK: Rings
    
    static let rings: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "acc_ring_common_01",
            name: "Tarnished Copper Band",
            description: "It's technically jewelry in the same way a participation trophy is technically an award.",
            slot: .accessory, rarity: .common,
            primaryStat: .luck, statBonus: 1,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "ring"
        ),
        EquipmentTemplate(
            id: "acc_ring_uncommon_01",
            name: "Silver Promise Ring",
            description: "Promises were made. Whether they'll be kept is above this ring's pay grade.",
            slot: .accessory, rarity: .uncommon,
            primaryStat: .charisma, statBonus: 3,
            secondaryStat: .luck, secondaryStatBonus: 2,
            levelRequirement: 4, baseType: "ring"
        ),
        EquipmentTemplate(
            id: "acc_ring_rare_01",
            name: "Ring of Shared Strength",
            description: "Forged by a blacksmith couple who argued over the design for eleven years. The tension made it stronger.",
            slot: .accessory, rarity: .rare,
            primaryStat: .strength, statBonus: 5,
            secondaryStat: .charisma, secondaryStatBonus: 4,
            levelRequirement: 11, baseType: "ring"
        ),
        EquipmentTemplate(
            id: "acc_ring_epic_01",
            name: "Eclipse Band",
            description: "The sun and moon metals were sworn enemies until a jeweler forced them into couples therapy. Now they dance.",
            slot: .accessory, rarity: .epic,
            primaryStat: .luck, statBonus: 8,
            secondaryStat: .wisdom, secondaryStatBonus: 5,
            levelRequirement: 20, baseType: "ring"
        ),
        EquipmentTemplate(
            id: "acc_ring_legendary_01",
            name: "The Eternal Vow",
            description: "Forged in the heart of a dying star by an immortal who just really didn't want to be single anymore. Commitment issues: solved.",
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
            description: "A carved token on a hemp cord. You tell people it's enchanted. They smile politely.",
            slot: .accessory, rarity: .common,
            primaryStat: .luck, statBonus: 2,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "amulet"
        ),
        EquipmentTemplate(
            id: "acc_amulet_uncommon_01",
            name: "Jade Guardian Amulet",
            description: "Wards off minor hexes and major conversations. Introverts swear by it.",
            slot: .accessory, rarity: .uncommon,
            primaryStat: .defense, statBonus: 3,
            secondaryStat: .wisdom, secondaryStatBonus: 2,
            levelRequirement: 5, baseType: "amulet"
        ),
        EquipmentTemplate(
            id: "acc_amulet_rare_01",
            name: "Phoenix Feather Talisman",
            description: "Plucked from a phoenix mid-sneeze. The bird was furious, but what's it gonna do — die?",
            slot: .accessory, rarity: .rare,
            primaryStat: .wisdom, statBonus: 5,
            secondaryStat: .luck, secondaryStatBonus: 4,
            levelRequirement: 12, baseType: "amulet"
        ),
        EquipmentTemplate(
            id: "acc_amulet_epic_01",
            name: "Eye of the Storm",
            description: "Houses a genuine tiny thunderstorm. The HOA inside is livid about the property damage.",
            slot: .accessory, rarity: .epic,
            primaryStat: .wisdom, statBonus: 9,
            secondaryStat: .defense, secondaryStatBonus: 5,
            levelRequirement: 22, baseType: "amulet"
        ),
        EquipmentTemplate(
            id: "acc_amulet_legendary_01",
            name: "Heart of the World Tree",
            description: "Yggdrasil's actual beating heart, donated willingly. Just kidding — someone stole it. The tree is still upset.",
            slot: .accessory, rarity: .legendary,
            primaryStat: .wisdom, statBonus: 15,
            secondaryStat: .luck, secondaryStatBonus: 9,
            levelRequirement: 38, baseType: "amulet"
        ),
    ]
    
    // MARK: Cloaks (includes robes, standard cloaks, capes, mantles)
    
    static let cloaks: [EquipmentTemplate] = robes + standardCloaks + mantles + capes
    
    static let standardCloaks: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "trk_cloak_common_01",
            name: "Moth-Eaten Travel Cape",
            description: "The moths ate most of it. The remaining fabric stays out of loyalty. Or maybe habit.",
            slot: .cloak, rarity: .common,
            primaryStat: .defense, statBonus: 1,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "cloak"
        ),
        EquipmentTemplate(
            id: "trk_cloak_uncommon_01",
            name: "Twilight Mantle",
            description: "Absorbs light so well you once lost it in your own shadow. Finding it required a torch and emotional support.",
            slot: .cloak, rarity: .uncommon,
            primaryStat: .dexterity, statBonus: 3,
            secondaryStat: .defense, secondaryStatBonus: 1,
            levelRequirement: 5, baseType: "cloak"
        ),
        EquipmentTemplate(
            id: "trk_cloak_rare_01",
            name: "Windweaver's Shroud",
            description: "Woven by a tailor who got struck by lightning mid-stitch. The static cling is permanent but so is the speed boost.",
            slot: .cloak, rarity: .rare,
            primaryStat: .dexterity, statBonus: 5,
            secondaryStat: .luck, secondaryStatBonus: 3,
            levelRequirement: 13, baseType: "cloak"
        ),
        EquipmentTemplate(
            id: "trk_cloak_epic_01",
            name: "Cloak of Many Stars",
            description: "Shows a different constellation each night. Last Tuesday it showed one that spelled out 'WASH ME.'",
            slot: .cloak, rarity: .epic,
            primaryStat: .wisdom, statBonus: 8,
            secondaryStat: .dexterity, secondaryStatBonus: 5,
            levelRequirement: 21, baseType: "cloak"
        ),
        EquipmentTemplate(
            id: "trk_cloak_legendary_01",
            name: "Mantle of the Unseen",
            description: "Woven from pure possibility. You can be anywhere and nowhere at once — mostly nowhere, because you forgot where you left it.",
            slot: .cloak, rarity: .legendary,
            primaryStat: .dexterity, statBonus: 13,
            secondaryStat: .luck, secondaryStatBonus: 10,
            levelRequirement: 36, baseType: "cloak"
        ),
    ]
    
    // MARK: Charms
    
    static let charms: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "trk_charm_common_01",
            name: "Lucky Penny Charm",
            description: "Found heads-up in a puddle. Your luck stat says +2 but your dignity says -10.",
            slot: .trinket, rarity: .common,
            primaryStat: .luck, statBonus: 2,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "charm"
        ),
        EquipmentTemplate(
            id: "trk_charm_uncommon_01",
            name: "Four-Leaf Crystal",
            description: "Statistically, you'd find a four-leaf clover faster than a good party member. This one skips both problems.",
            slot: .trinket, rarity: .uncommon,
            primaryStat: .luck, statBonus: 4,
            secondaryStat: .charisma, secondaryStatBonus: 1,
            levelRequirement: 4, baseType: "charm"
        ),
        EquipmentTemplate(
            id: "trk_charm_rare_01",
            name: "Heartstone Charm",
            description: "Fell out of a love god's pocket during a particularly messy breakup. Resonates with emotional chaos.",
            slot: .trinket, rarity: .rare,
            primaryStat: .charisma, statBonus: 6,
            secondaryStat: .luck, secondaryStatBonus: 3,
            levelRequirement: 12, baseType: "charm"
        ),
        EquipmentTemplate(
            id: "trk_charm_epic_01",
            name: "Dragon's Eye Charm",
            description: "Sees through illusions, lies, and excuses for not doing the dishes. Terrifyingly perceptive.",
            slot: .trinket, rarity: .epic,
            primaryStat: .wisdom, statBonus: 8,
            secondaryStat: .luck, secondaryStatBonus: 6,
            levelRequirement: 20, baseType: "charm"
        ),
        EquipmentTemplate(
            id: "trk_charm_legendary_01",
            name: "Wishing Star Fragment",
            description: "A piece of a star that granted exactly one wish before crash-landing. The wish was for 'better loot drops.' Respect.",
            slot: .trinket, rarity: .legendary,
            primaryStat: .luck, statBonus: 15,
            secondaryStat: .charisma, secondaryStatBonus: 8,
            levelRequirement: 34, baseType: "charm"
        ),
    ]
    
    // =========================================================================
    // MARK: - TRINKETS  (20 items: 4 base types × 5 rarities)
    // =========================================================================
    
    static let trinkets: [EquipmentTemplate] = charms + belts + orbs + bracelets
    
    // MARK: Belts
    
    static let belts: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "trk_belt_common_01",
            name: "Rope Sash",
            description: "It holds your pants up. In a world of dragons and demons, that's honestly the most important job.",
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
            description: "Enchanted by a wizard who cast a marathon spell on himself, then forgot the finish line was optional. He's still running.",
            slot: .trinket, rarity: .rare,
            primaryStat: .dexterity, statBonus: 5,
            secondaryStat: .strength, secondaryStatBonus: 3,
            levelRequirement: 11, baseType: "belt"
        ),
        EquipmentTemplate(
            id: "trk_belt_epic_01",
            name: "Champion's War Girdle",
            description: "Forged from the accumulated ego of a hundred defeated challengers. It's heavy, but mostly from the drama.",
            slot: .trinket, rarity: .epic,
            primaryStat: .strength, statBonus: 8,
            secondaryStat: .defense, secondaryStatBonus: 5,
            levelRequirement: 22, baseType: "belt"
        ),
        EquipmentTemplate(
            id: "trk_belt_legendary_01",
            name: "Girdle of World-Bearing",
            description: "Modeled after the belt of the titan who holds up the sky. He asked for royalties. Nobody called him back.",
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
            description: "More splinter than shield at this point. Blocks attacks the way a screen door blocks rain.",
            slot: .weapon, rarity: .common,
            primaryStat: .defense, statBonus: 2,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "shield"
        ),
        EquipmentTemplate(
            id: "wep_shield_uncommon_01",
            name: "Iron Kite Shield",
            description: "It's called a kite shield but it absolutely cannot fly. Several adventurers have tested this. From cliffs.",
            slot: .weapon, rarity: .uncommon,
            primaryStat: .defense, statBonus: 4,
            secondaryStat: .strength, secondaryStatBonus: 2,
            levelRequirement: 6, baseType: "shield"
        ),
        EquipmentTemplate(
            id: "wep_shield_rare_01",
            name: "Tower Shield of the Vanguard",
            description: "Commissioned by a knight who was allergic to getting hit. The blacksmith made it the size of a door. The knight was 4'11\".",
            slot: .weapon, rarity: .rare,
            primaryStat: .defense, statBonus: 7,
            secondaryStat: .strength, secondaryStatBonus: 3,
            levelRequirement: 14, baseType: "shield"
        ),
        EquipmentTemplate(
            id: "wep_shield_epic_01",
            name: "Dragon Scale Aegis",
            description: "Forged from real dragon scales, which the dragon did NOT consent to donating. Legal proceedings are ongoing.",
            slot: .weapon, rarity: .epic,
            primaryStat: .defense, statBonus: 11,
            secondaryStat: .strength, secondaryStatBonus: 5,
            levelRequirement: 25, baseType: "shield"
        ),
        EquipmentTemplate(
            id: "wep_shield_legendary_01",
            name: "Aegis of Ages",
            description: "This shield has witnessed every war in recorded history and it is TIRED. Blocks attacks out of sheer spite at this point.",
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
            description: "Point the dangerous end away from your face. That's it. That's the whole instruction manual.",
            slot: .weapon, rarity: .common,
            primaryStat: .dexterity, statBonus: 2,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "crossbow"
        ),
        EquipmentTemplate(
            id: "wep_crossbow_uncommon_01",
            name: "Repeating Crossbow",
            description: "Fires bolts faster than you can aim. Accuracy is a state of mind, and that state is 'optimistic.'",
            slot: .weapon, rarity: .uncommon,
            primaryStat: .dexterity, statBonus: 4,
            secondaryStat: .strength, secondaryStatBonus: 2,
            levelRequirement: 5, baseType: "crossbow"
        ),
        EquipmentTemplate(
            id: "wep_crossbow_rare_01",
            name: "Heavy Arbalest",
            description: "Built by a dwarf who was told crossbows couldn't be 'too much.' He took that personally.",
            slot: .weapon, rarity: .rare,
            primaryStat: .dexterity, statBonus: 7,
            secondaryStat: .strength, secondaryStatBonus: 3,
            levelRequirement: 13, baseType: "crossbow"
        ),
        EquipmentTemplate(
            id: "wep_crossbow_epic_01",
            name: "Siege Crossbow",
            description: "Designed to breach castle walls, which is wildly excessive for dungeon crawling. You'll use it anyway because you have no chill.",
            slot: .weapon, rarity: .epic,
            primaryStat: .dexterity, statBonus: 10,
            secondaryStat: .defense, secondaryStatBonus: 5,
            levelRequirement: 23, baseType: "crossbow"
        ),
        EquipmentTemplate(
            id: "wep_crossbow_legendary_01",
            name: "Arbalest of Ruin",
            description: "Its bolts pierce through dimensions. The last person who fired it accidentally sent a bolt into next Tuesday. Tuesday was not happy.",
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
            description: "Half the pages are missing, the rest are sticky, and chapter three is just someone's grocery list. Still technically a spellbook.",
            slot: .weapon, rarity: .common,
            primaryStat: .wisdom, statBonus: 2,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "tome"
        ),
        EquipmentTemplate(
            id: "wep_tome_uncommon_01",
            name: "Scholar's Tome",
            description: "Well-organized, thoroughly annotated, and deeply passive-aggressive in the margins. 'See, THIS is how you cast fireball.'",
            slot: .weapon, rarity: .uncommon,
            primaryStat: .wisdom, statBonus: 5,
            secondaryStat: .charisma, secondaryStatBonus: 1,
            levelRequirement: 5, baseType: "tome"
        ),
        EquipmentTemplate(
            id: "wep_tome_rare_01",
            name: "Arcane Grimoire",
            description: "Written by a wizard who couldn't decide on a font, so every page is in a different one. Chapter 7 is in Wingdings.",
            slot: .weapon, rarity: .rare,
            primaryStat: .wisdom, statBonus: 7,
            secondaryStat: .luck, secondaryStatBonus: 3,
            levelRequirement: 13, baseType: "tome"
        ),
        EquipmentTemplate(
            id: "wep_tome_epic_01",
            name: "Eldritch Codex",
            description: "Bound in shadow-leather, written in a language that makes your eyes water. Reading it aloud summons a migraine and, occasionally, eldritch power.",
            slot: .weapon, rarity: .epic,
            primaryStat: .wisdom, statBonus: 11,
            secondaryStat: .defense, secondaryStatBonus: 4,
            levelRequirement: 24, baseType: "tome"
        ),
        EquipmentTemplate(
            id: "wep_tome_legendary_01",
            name: "Tome of Infinite Wisdom",
            description: "A book with no last page. It knows everything, including what you did last summer. It's not angry, just disappointed.",
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
            description: "A polearm that can't decide if it's an axe or a spear. Identity crisis on a stick.",
            slot: .weapon, rarity: .common,
            primaryStat: .strength, statBonus: 3,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "halberd"
        ),
        EquipmentTemplate(
            id: "wep_halberd_uncommon_01",
            name: "Footman's Halberd",
            description: "Standard issue for guards who wanted a sword AND a spear but only had one equipment slot.",
            slot: .weapon, rarity: .uncommon,
            primaryStat: .strength, statBonus: 5,
            secondaryStat: .defense, secondaryStatBonus: 2,
            levelRequirement: 6, baseType: "halberd"
        ),
        EquipmentTemplate(
            id: "wep_halberd_rare_01",
            name: "Wyvern's Beak Halberd",
            description: "Forged to resemble a wyvern's beak. The wyvern was not consulted and is reportedly furious.",
            slot: .weapon, rarity: .rare,
            primaryStat: .strength, statBonus: 8,
            secondaryStat: .dexterity, secondaryStatBonus: 3,
            levelRequirement: 14, baseType: "halberd"
        ),
        EquipmentTemplate(
            id: "wep_halberd_epic_01",
            name: "Siegebreaker Halberd",
            description: "Designed to breach castle gates. Slightly overkill for dungeon rats, but style points matter.",
            slot: .weapon, rarity: .epic,
            primaryStat: .strength, statBonus: 12,
            secondaryStat: .defense, secondaryStatBonus: 5,
            levelRequirement: 25, baseType: "halberd"
        ),
        EquipmentTemplate(
            id: "wep_halberd_legendary_01",
            name: "Worldsplitter Halberd",
            description: "Legend says one swing split a continent in half. Geologists disagree but they weren't there.",
            slot: .weapon, rarity: .legendary,
            primaryStat: .strength, statBonus: 17,
            secondaryStat: .luck, secondaryStatBonus: 8,
            levelRequirement: 38, baseType: "halberd"
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
            description: "Technically footwear the same way a napkin is technically a blanket. Your toes have filed a formal complaint.",
            slot: .armor, rarity: .common,
            primaryStat: .dexterity, statBonus: 1,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "boots"
        ),
        EquipmentTemplate(
            id: "arm_boots_uncommon_01",
            name: "Leather Boots",
            description: "Sturdy, reliable, and completely unremarkable. The sensible sedan of adventuring footwear.",
            slot: .armor, rarity: .uncommon,
            primaryStat: .dexterity, statBonus: 3,
            secondaryStat: .defense, secondaryStatBonus: 1,
            levelRequirement: 5, baseType: "boots"
        ),
        EquipmentTemplate(
            id: "arm_boots_rare_01",
            name: "Plated Greaves",
            description: "Forged after a hero stubbed his toe on a treasure chest and demanded justice. One awkward injury, one legendary innovation.",
            slot: .armor, rarity: .rare,
            primaryStat: .dexterity, statBonus: 5,
            secondaryStat: .defense, secondaryStatBonus: 3,
            levelRequirement: 12, baseType: "boots"
        ),
        EquipmentTemplate(
            id: "arm_boots_epic_01",
            name: "Enchanted Greaves",
            description: "Defy physics by getting lighter the faster you run. Isaac Newton's ghost filed a bug report.",
            slot: .armor, rarity: .epic,
            primaryStat: .dexterity, statBonus: 9,
            secondaryStat: .defense, secondaryStatBonus: 4,
            levelRequirement: 22, baseType: "boots"
        ),
        EquipmentTemplate(
            id: "arm_boots_legendary_01",
            name: "Stormstrider Boots",
            description: "Each step crackles with lightning. You move at the speed of thought — mostly the thought 'I should not have worn these indoors.'",
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
            description: "Padded shoulder wraps that say 'I'm trying' without saying 'I'm succeeding.'",
            slot: .armor, rarity: .common,
            primaryStat: .defense, statBonus: 1,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "pauldrons"
        ),
        EquipmentTemplate(
            id: "arm_pauldrons_uncommon_01",
            name: "Iron Pauldrons",
            description: "Solid iron shoulder guards. Your shrugs now deal bludgeoning damage.",
            slot: .armor, rarity: .uncommon,
            primaryStat: .defense, statBonus: 3,
            secondaryStat: .strength, secondaryStatBonus: 2,
            levelRequirement: 6, baseType: "pauldrons"
        ),
        EquipmentTemplate(
            id: "arm_pauldrons_rare_01",
            name: "Steel Pauldrons",
            description: "Mirror-polished to blind enemies. Invented by a blacksmith tired of being stabbed in the shoulders specifically.",
            slot: .armor, rarity: .rare,
            primaryStat: .defense, statBonus: 5,
            secondaryStat: .strength, secondaryStatBonus: 4,
            levelRequirement: 13, baseType: "pauldrons"
        ),
        EquipmentTemplate(
            id: "arm_pauldrons_epic_01",
            name: "Dragonbone Pauldrons",
            description: "Carved from a dragon's shoulder bones. The dragon's estate formally requests you stop wearing its grandma.",
            slot: .armor, rarity: .epic,
            primaryStat: .defense, statBonus: 8,
            secondaryStat: .strength, secondaryStatBonus: 6,
            levelRequirement: 24, baseType: "pauldrons"
        ),
        EquipmentTemplate(
            id: "arm_pauldrons_legendary_01",
            name: "Titan Pauldrons",
            description: "Forged from a fallen titan's armor. Your shoulders are now wider than most doorways and all of your social plans.",
            slot: .armor, rarity: .legendary,
            primaryStat: .defense, statBonus: 13,
            secondaryStat: .strength, secondaryStatBonus: 10,
            levelRequirement: 38, baseType: "pauldrons"
        ),
    ]
    
    // MARK: Heavy Helms
    
    static let heavyHelms: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "arm_hhhelm_common_01",
            name: "Dented Heavy Helm",
            description: "Limited visibility, questionable ventilation, and a mysterious smell inside. Welcome to the tank life.",
            slot: .armor, rarity: .common,
            primaryStat: .defense, statBonus: 2,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 3, baseType: "heavy helm"
        ),
        EquipmentTemplate(
            id: "arm_hhhelm_uncommon_01",
            name: "Iron Heavy Helm",
            description: "A solid iron greathelm for when you want to cosplay as a very angry mailbox.",
            slot: .armor, rarity: .uncommon,
            primaryStat: .defense, statBonus: 4,
            secondaryStat: .strength, secondaryStatBonus: 2,
            levelRequirement: 8, baseType: "heavy helm"
        ),
        EquipmentTemplate(
            id: "arm_hhhelm_rare_01",
            name: "Steel Heavy Helm",
            description: "Commissioned by a knight who headbutted a dragon and wanted to try again. Swords bounce off it like suggestions.",
            slot: .armor, rarity: .rare,
            primaryStat: .defense, statBonus: 6,
            secondaryStat: .strength, secondaryStatBonus: 4,
            levelRequirement: 15, baseType: "heavy helm"
        ),
        EquipmentTemplate(
            id: "arm_hhhelm_epic_01",
            name: "Warlord's Heavy Helm",
            description: "A crowned greathelm etched with battle runes. Its wearer commands respect on any battlefield.",
            slot: .armor, rarity: .epic,
            primaryStat: .defense, statBonus: 9,
            secondaryStat: .charisma, secondaryStatBonus: 6,
            levelRequirement: 25, baseType: "heavy helm"
        ),
        EquipmentTemplate(
            id: "arm_hhhelm_legendary_01",
            name: "Helm of the Immortal",
            description: "No warrior wearing this has ever fallen in battle. Mainly because the weight keeps them firmly planted on the ground.",
            slot: .armor, rarity: .legendary,
            primaryStat: .defense, statBonus: 14,
            secondaryStat: .strength, secondaryStatBonus: 10,
            levelRequirement: 38, baseType: "heavy helm"
        ),
    ]
    
    // MARK: Heavy Gauntlets
    
    static let heavyGauntlets: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "arm_hgauntlets_common_01",
            name: "Rusty Heavy Gauntlets",
            description: "Your fists are now legally classified as blunt weapons. Also, good luck picking up coins.",
            slot: .armor, rarity: .common,
            primaryStat: .strength, statBonus: 2,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 3, baseType: "heavy gauntlets"
        ),
        EquipmentTemplate(
            id: "arm_hgauntlets_uncommon_01",
            name: "Plated Heavy Gauntlets",
            description: "Articulated steel plates over chainmail. Each finger moves like a tiny, deeply committed battering ram.",
            slot: .armor, rarity: .uncommon,
            primaryStat: .strength, statBonus: 4,
            secondaryStat: .defense, secondaryStatBonus: 2,
            levelRequirement: 8, baseType: "heavy gauntlets"
        ),
        EquipmentTemplate(
            id: "arm_hgauntlets_rare_01",
            name: "Forgemaster's Heavy Gauntlets",
            description: "Invented after the 'bare hands incident' at the dragon-fire forge that nobody discusses. Fireproof, trauma-proof.",
            slot: .armor, rarity: .rare,
            primaryStat: .strength, statBonus: 6,
            secondaryStat: .defense, secondaryStatBonus: 4,
            levelRequirement: 14, baseType: "heavy gauntlets"
        ),
        EquipmentTemplate(
            id: "arm_hgauntlets_epic_01",
            name: "Siegebreaker Heavy Gauntlets",
            description: "Enchanted to amplify grip strength tenfold. Opening a jar of pickles with these constitutes a war crime.",
            slot: .armor, rarity: .epic,
            primaryStat: .strength, statBonus: 10,
            secondaryStat: .defense, secondaryStatBonus: 6,
            levelRequirement: 24, baseType: "heavy gauntlets"
        ),
        EquipmentTemplate(
            id: "arm_hgauntlets_legendary_01",
            name: "Fists of the Mountain King",
            description: "Carved from living stone and bound with adamantine. One punch reshapes the landscape. One high-five reshapes your friend.",
            slot: .armor, rarity: .legendary,
            primaryStat: .strength, statBonus: 15,
            secondaryStat: .defense, secondaryStatBonus: 10,
            levelRequirement: 38, baseType: "heavy gauntlets"
        ),
    ]
    
    // MARK: Heavy Boots
    
    static let heavyBoots: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "arm_hboots_common_01",
            name: "Iron Heavy Boots",
            description: "Clunky, loud, and guaranteed to ruin every wooden floor you walk on. Stealth is no longer an option.",
            slot: .armor, rarity: .common,
            primaryStat: .defense, statBonus: 2,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 3, baseType: "heavy boots"
        ),
        EquipmentTemplate(
            id: "arm_hboots_uncommon_01",
            name: "Steel Heavy Boots",
            description: "Every step sounds like a war drum. Enemies know you're coming. So does everyone in a three-mile radius.",
            slot: .armor, rarity: .uncommon,
            primaryStat: .defense, statBonus: 4,
            secondaryStat: .dexterity, secondaryStatBonus: 1,
            levelRequirement: 8, baseType: "heavy boots"
        ),
        EquipmentTemplate(
            id: "arm_hboots_rare_01",
            name: "Warplate Heavy Boots",
            description: "Enchanted to grip any surface. Invented after one too many embarrassing deaths by slippery dungeon floors.",
            slot: .armor, rarity: .rare,
            primaryStat: .defense, statBonus: 6,
            secondaryStat: .dexterity, secondaryStatBonus: 3,
            levelRequirement: 14, baseType: "heavy boots"
        ),
        EquipmentTemplate(
            id: "arm_hboots_epic_01",
            name: "Earthshaker Heavy Boots",
            description: "Each stomp sends tremors through the ground. Your upstairs neighbors filed a formal complaint with the Guild.",
            slot: .armor, rarity: .epic,
            primaryStat: .defense, statBonus: 9,
            secondaryStat: .strength, secondaryStatBonus: 5,
            levelRequirement: 24, baseType: "heavy boots"
        ),
        EquipmentTemplate(
            id: "arm_hboots_legendary_01",
            name: "Colossus Treads",
            description: "Forged from the same metal as the ancient war colossus. The ground bows beneath them, mostly because it has no choice.",
            slot: .armor, rarity: .legendary,
            primaryStat: .defense, statBonus: 14,
            secondaryStat: .strength, secondaryStatBonus: 9,
            levelRequirement: 38, baseType: "heavy boots"
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
            description: "Your ear turns green, your stats go up by one. The math checks out if you don't think about it.",
            slot: .accessory, rarity: .common,
            primaryStat: .luck, statBonus: 1,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "earring"
        ),
        EquipmentTemplate(
            id: "acc_earring_uncommon_01",
            name: "Silver Earring",
            description: "Glints suggestively when fortune is nearby. Won't warn you about misfortune, though. Bit of a one-trick pony.",
            slot: .accessory, rarity: .uncommon,
            primaryStat: .luck, statBonus: 3,
            secondaryStat: .charisma, secondaryStatBonus: 2,
            levelRequirement: 4, baseType: "earring"
        ),
        EquipmentTemplate(
            id: "acc_earring_rare_01",
            name: "Gold Earring",
            description: "Won by a pirate in a card game against Lady Luck herself. She let him win. She always lets them win.",
            slot: .accessory, rarity: .rare,
            primaryStat: .luck, statBonus: 6,
            secondaryStat: .charisma, secondaryStatBonus: 3,
            levelRequirement: 12, baseType: "earring"
        ),
        EquipmentTemplate(
            id: "acc_earring_epic_01",
            name: "Gemmed Earring",
            description: "A perfect ruby that whispers probability equations directly into your ear canal. Unsettling, but statistically significant.",
            slot: .accessory, rarity: .epic,
            primaryStat: .luck, statBonus: 9,
            secondaryStat: .wisdom, secondaryStatBonus: 5,
            levelRequirement: 21, baseType: "earring"
        ),
        EquipmentTemplate(
            id: "acc_earring_legendary_01",
            name: "Earring of Fate",
            description: "Woven from a literal thread of destiny. The Fates sent a cease-and-desist, but it got lost in the mail. Convenient.",
            slot: .accessory, rarity: .legendary,
            primaryStat: .luck, statBonus: 15,
            secondaryStat: .charisma, secondaryStatBonus: 9,
            levelRequirement: 36, baseType: "earring"
        ),
    ]
    
    // MARK: Talismans
    
    static let talismans: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "acc_talisman_common_01",
            name: "Wooden Talisman",
            description: "Hand-carved from a sacred tree that was, honestly, just a regular tree with good PR.",
            slot: .accessory, rarity: .common,
            primaryStat: .wisdom, statBonus: 1,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "talisman"
        ),
        EquipmentTemplate(
            id: "acc_talisman_uncommon_01",
            name: "Carved Talisman",
            description: "Covered in runes that roughly translate to 'please work please work please work.'",
            slot: .accessory, rarity: .uncommon,
            primaryStat: .wisdom, statBonus: 3,
            secondaryStat: .defense, secondaryStatBonus: 2,
            levelRequirement: 5, baseType: "talisman"
        ),
        EquipmentTemplate(
            id: "acc_talisman_rare_01",
            name: "Enchanted Talisman",
            description: "A monk meditated for forty years to enchant this. Halfway through he forgot why. The confusion somehow made it stronger.",
            slot: .accessory, rarity: .rare,
            primaryStat: .wisdom, statBonus: 5,
            secondaryStat: .luck, secondaryStatBonus: 4,
            levelRequirement: 12, baseType: "talisman"
        ),
        EquipmentTemplate(
            id: "acc_talisman_epic_01",
            name: "Ancient Talisman",
            description: "Pre-dates recorded history, which is just a fancy way of saying nobody kept the receipt.",
            slot: .accessory, rarity: .epic,
            primaryStat: .wisdom, statBonus: 9,
            secondaryStat: .defense, secondaryStatBonus: 5,
            levelRequirement: 22, baseType: "talisman"
        ),
        EquipmentTemplate(
            id: "acc_talisman_legendary_01",
            name: "Talisman of the Void",
            description: "Contains a pocket of pure nothingness. Existentially terrifying. Excellent stats though, so you learn to cope.",
            slot: .accessory, rarity: .legendary,
            primaryStat: .wisdom, statBonus: 14,
            secondaryStat: .luck, secondaryStatBonus: 10,
            levelRequirement: 38, baseType: "talisman"
        ),
    ]
    
    // MARK: Pendants
    
    static let pendants: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "acc_pendant_common_01",
            name: "Tarnished Pendant",
            description: "It's either bronze or really committed copper. Nobody's brave enough to polish it and find out.",
            slot: .accessory, rarity: .common,
            primaryStat: .charisma, statBonus: 1,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "pendant"
        ),
        EquipmentTemplate(
            id: "acc_pendant_uncommon_01",
            name: "Moonstone Pendant",
            description: "Glows faintly at night. Mostly useful for finding the bathroom without stubbing your toe.",
            slot: .accessory, rarity: .uncommon,
            primaryStat: .charisma, statBonus: 3,
            secondaryStat: .wisdom, secondaryStatBonus: 1,
            levelRequirement: 5, baseType: "pendant"
        ),
        EquipmentTemplate(
            id: "acc_pendant_rare_01",
            name: "Serpent's Eye Pendant",
            description: "The gemstone follows your gaze. Creepy? Yes. Fashionable? Also yes.",
            slot: .accessory, rarity: .rare,
            primaryStat: .charisma, statBonus: 6,
            secondaryStat: .dexterity, secondaryStatBonus: 3,
            levelRequirement: 12, baseType: "pendant"
        ),
        EquipmentTemplate(
            id: "acc_pendant_epic_01",
            name: "Heartstone Pendant",
            description: "Pulses in sync with its wearer's heartbeat. Cardiology wizards are deeply conflicted about this.",
            slot: .accessory, rarity: .epic,
            primaryStat: .charisma, statBonus: 10,
            secondaryStat: .luck, secondaryStatBonus: 4,
            levelRequirement: 22, baseType: "pendant"
        ),
        EquipmentTemplate(
            id: "acc_pendant_legendary_01",
            name: "Pendant of the Eternal Flame",
            description: "Houses a flame that has burned since before time. Great conversation starter. Terrible pillow.",
            slot: .accessory, rarity: .legendary,
            primaryStat: .charisma, statBonus: 15,
            secondaryStat: .wisdom, secondaryStatBonus: 8,
            levelRequirement: 36, baseType: "pendant"
        ),
    ]
    
    // MARK: Brooches
    
    static let brooches: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "acc_brooch_common_01",
            name: "Bent Pin Brooch",
            description: "Technically jewelry. Technically.",
            slot: .accessory, rarity: .common,
            primaryStat: .defense, statBonus: 1,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "brooch"
        ),
        EquipmentTemplate(
            id: "acc_brooch_uncommon_01",
            name: "Silver Leaf Brooch",
            description: "Shaped like an autumn leaf. The silversmith was 'going through a nature phase.'",
            slot: .accessory, rarity: .uncommon,
            primaryStat: .defense, statBonus: 3,
            secondaryStat: .charisma, secondaryStatBonus: 1,
            levelRequirement: 5, baseType: "brooch"
        ),
        EquipmentTemplate(
            id: "acc_brooch_rare_01",
            name: "Phoenix Feather Brooch",
            description: "Warm to the touch and occasionally catches fire. Dry clean only.",
            slot: .accessory, rarity: .rare,
            primaryStat: .defense, statBonus: 6,
            secondaryStat: .luck, secondaryStatBonus: 3,
            levelRequirement: 12, baseType: "brooch"
        ),
        EquipmentTemplate(
            id: "acc_brooch_epic_01",
            name: "Dragon's Crest Brooch",
            description: "Grants the wearer an air of authority. Also makes you smell faintly of sulfur.",
            slot: .accessory, rarity: .epic,
            primaryStat: .defense, statBonus: 9,
            secondaryStat: .strength, secondaryStatBonus: 5,
            levelRequirement: 22, baseType: "brooch"
        ),
        EquipmentTemplate(
            id: "acc_brooch_legendary_01",
            name: "Brooch of the First King",
            description: "Worn by the first king of the realm. He lost it in a bet. Kings are terrible gamblers.",
            slot: .accessory, rarity: .legendary,
            primaryStat: .defense, statBonus: 14,
            secondaryStat: .charisma, secondaryStatBonus: 9,
            levelRequirement: 36, baseType: "brooch"
        ),
    ]
    
    // MARK: Orb Trinkets (mage-line only)
    
    static let orbs: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "trk_orb_common_01",
            name: "Cloudy Glass Orb",
            description: "Predicts the future with all the accuracy of a coin flip. Less useful, more aesthetic.",
            slot: .trinket, rarity: .common,
            primaryStat: .wisdom, statBonus: 2,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "orb"
        ),
        EquipmentTemplate(
            id: "trk_orb_uncommon_01",
            name: "Mana-Spun Orb",
            description: "Swirling with blue energy. Touching it feels like licking a battery, but for your soul.",
            slot: .trinket, rarity: .uncommon,
            primaryStat: .wisdom, statBonus: 4,
            secondaryStat: .charisma, secondaryStatBonus: 2,
            levelRequirement: 5, baseType: "orb"
        ),
        EquipmentTemplate(
            id: "trk_orb_rare_01",
            name: "Void-Touched Orb",
            description: "Stare into the void. The void stares back. Then the void blinks first. You win.",
            slot: .trinket, rarity: .rare,
            primaryStat: .wisdom, statBonus: 7,
            secondaryStat: .luck, secondaryStatBonus: 3,
            levelRequirement: 13, baseType: "orb"
        ),
        EquipmentTemplate(
            id: "trk_orb_epic_01",
            name: "Orb of Shattered Realities",
            description: "Shows glimpses of parallel worlds. In most of them, you still forgot to buy milk.",
            slot: .trinket, rarity: .epic,
            primaryStat: .wisdom, statBonus: 11,
            secondaryStat: .charisma, secondaryStatBonus: 5,
            levelRequirement: 24, baseType: "orb"
        ),
        EquipmentTemplate(
            id: "trk_orb_legendary_01",
            name: "Orb of the Cosmic Architect",
            description: "Contains the blueprint for all of creation. The fine print is in a language nobody speaks.",
            slot: .trinket, rarity: .legendary,
            primaryStat: .wisdom, statBonus: 16,
            secondaryStat: .luck, secondaryStatBonus: 9,
            levelRequirement: 38, baseType: "orb"
        ),
    ]
    
    // MARK: Bracelets (trinkets)
    
    static let bracelets: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "trk_bracelet_common_01",
            name: "Frayed Friendship Bracelet",
            description: "The friend who made this moved away. The bracelet stayed. It's complicated.",
            slot: .trinket, rarity: .common,
            primaryStat: .charisma, statBonus: 1,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "bracelet"
        ),
        EquipmentTemplate(
            id: "trk_bracelet_uncommon_01",
            name: "Copper Chain Bracelet",
            description: "Turns your wrist green but boosts your stats. Fashion is sacrifice.",
            slot: .trinket, rarity: .uncommon,
            primaryStat: .charisma, statBonus: 3,
            secondaryStat: .dexterity, secondaryStatBonus: 1,
            levelRequirement: 5, baseType: "bracelet"
        ),
        EquipmentTemplate(
            id: "trk_bracelet_rare_01",
            name: "Serpentine Bracelet",
            description: "Wraps around your wrist like a tiny snake. It's not alive. Probably.",
            slot: .trinket, rarity: .rare,
            primaryStat: .charisma, statBonus: 5,
            secondaryStat: .luck, secondaryStatBonus: 3,
            levelRequirement: 12, baseType: "bracelet"
        ),
        EquipmentTemplate(
            id: "trk_bracelet_epic_01",
            name: "Stormforged Bracelet",
            description: "Crackles with static electricity. High-fives have never been more exciting.",
            slot: .trinket, rarity: .epic,
            primaryStat: .charisma, statBonus: 9,
            secondaryStat: .strength, secondaryStatBonus: 4,
            levelRequirement: 22, baseType: "bracelet"
        ),
        EquipmentTemplate(
            id: "trk_bracelet_legendary_01",
            name: "Bracelet of Unbroken Bonds",
            description: "Forged from the chains of a love that transcended death. Heavy on the wrist, heavier on the feelings.",
            slot: .trinket, rarity: .legendary,
            primaryStat: .charisma, statBonus: 14,
            secondaryStat: .luck, secondaryStatBonus: 8,
            levelRequirement: 36, baseType: "bracelet"
        ),
    ]
    
    // MARK: Mantles (warrior-line cloaks)
    
    static let mantles: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "clk_mantle_common_01",
            name: "Tattered War Mantle",
            description: "Survived more battles than its owner. Currently winning on pure stubbornness.",
            slot: .cloak, rarity: .common,
            primaryStat: .defense, statBonus: 2,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "mantle"
        ),
        EquipmentTemplate(
            id: "clk_mantle_uncommon_01",
            name: "Iron-Trimmed Mantle",
            description: "The iron trim makes it defensive. The weight makes stairs your new nemesis.",
            slot: .cloak, rarity: .uncommon,
            primaryStat: .defense, statBonus: 4,
            secondaryStat: .strength, secondaryStatBonus: 2,
            levelRequirement: 5, baseType: "mantle"
        ),
        EquipmentTemplate(
            id: "clk_mantle_rare_01",
            name: "Warlord's Mantle",
            description: "Worn by a warlord who conquered twelve kingdoms. He's retired now. Runs a bakery.",
            slot: .cloak, rarity: .rare,
            primaryStat: .defense, statBonus: 7,
            secondaryStat: .strength, secondaryStatBonus: 3,
            levelRequirement: 13, baseType: "mantle"
        ),
        EquipmentTemplate(
            id: "clk_mantle_epic_01",
            name: "Titan's Mantle",
            description: "Sized for a titan, tailored for a human. The alterations alone cost a small fortune.",
            slot: .cloak, rarity: .epic,
            primaryStat: .defense, statBonus: 11,
            secondaryStat: .strength, secondaryStatBonus: 5,
            levelRequirement: 24, baseType: "mantle"
        ),
        EquipmentTemplate(
            id: "clk_mantle_legendary_01",
            name: "Mantle of the Mountain King",
            description: "Carved from living granite. Literally rock-solid defense. Dry cleaners refuse it on sight.",
            slot: .cloak, rarity: .legendary,
            primaryStat: .defense, statBonus: 16,
            secondaryStat: .luck, secondaryStatBonus: 8,
            levelRequirement: 38, baseType: "mantle"
        ),
    ]
    
    // MARK: Capes (archer-line cloaks)
    
    static let capes: [EquipmentTemplate] = [
        EquipmentTemplate(
            id: "clk_cape_common_01",
            name: "Dusty Traveler's Cape",
            description: "Collects dust, memories, and an unreasonable number of burrs.",
            slot: .cloak, rarity: .common,
            primaryStat: .dexterity, statBonus: 2,
            secondaryStat: nil, secondaryStatBonus: 0,
            levelRequirement: 1, baseType: "cape"
        ),
        EquipmentTemplate(
            id: "clk_cape_uncommon_01",
            name: "Woodland Cape",
            description: "Dyed forest green. Perfect camouflage if you stand perfectly still. Forever.",
            slot: .cloak, rarity: .uncommon,
            primaryStat: .dexterity, statBonus: 4,
            secondaryStat: .luck, secondaryStatBonus: 2,
            levelRequirement: 5, baseType: "cape"
        ),
        EquipmentTemplate(
            id: "clk_cape_rare_01",
            name: "Windrunner's Cape",
            description: "Aerodynamically designed for maximum dramatic billowing. Function follows fashion.",
            slot: .cloak, rarity: .rare,
            primaryStat: .dexterity, statBonus: 7,
            secondaryStat: .luck, secondaryStatBonus: 3,
            levelRequirement: 13, baseType: "cape"
        ),
        EquipmentTemplate(
            id: "clk_cape_epic_01",
            name: "Shadowstep Cape",
            description: "Lets you melt into shadows. Terrible at parties. Incredible at leaving them unnoticed.",
            slot: .cloak, rarity: .epic,
            primaryStat: .dexterity, statBonus: 11,
            secondaryStat: .luck, secondaryStatBonus: 5,
            levelRequirement: 24, baseType: "cape"
        ),
        EquipmentTemplate(
            id: "clk_cape_legendary_01",
            name: "Cape of the Phantom Archer",
            description: "Grants near-invisibility. Your arrows arrive before your enemies know you exist.",
            slot: .cloak, rarity: .legendary,
            primaryStat: .dexterity, statBonus: 16,
            secondaryStat: .luck, secondaryStatBonus: 9,
            levelRequirement: 38, baseType: "cape"
        ),
    ]
}
