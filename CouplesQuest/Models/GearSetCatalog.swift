import Foundation

// MARK: - Gear Set Definition

/// A 3-piece class gear set (weapon + armor + accessory) with a 2-piece activation bonus.
/// Redesigned: wear any 2 of the set's 3 pieces to get the bonus.
/// Set pieces are Epic rarity to stay relevant longer.
struct GearSetDefinition: Identifiable {
    let id: String
    let name: String
    let description: String
    let characterClass: CharacterClass
    let weapon: GearSetPiece
    let armor: GearSetPiece
    let accessory: GearSetPiece
    let bonusStat: StatType
    let bonusAmount: Int
    /// How many pieces required for the bonus (default: 2 for 2-piece activation)
    let piecesRequired: Int
    let levelRequirement: Int
    
    var pieces: [GearSetPiece] { [weapon, armor, accessory] }
    
    /// Total gold cost if buying all pieces
    var totalCost: Int {
        weapon.goldCost + armor.goldCost + accessory.goldCost
    }
}

/// A single piece of a gear set
struct GearSetPiece: Identifiable {
    let id: String          // catalogID for matching
    let name: String
    let description: String
    let slot: EquipmentSlot
    let rarity: ItemRarity
    let primaryStat: StatType
    let statBonus: Int
    let secondaryStat: StatType?
    let secondaryStatBonus: Int
    let goldCost: Int
    let baseType: String
    
    /// Create an Equipment instance from this set piece
    func toEquipment(ownerID: UUID) -> Equipment {
        let equip = Equipment(
            name: name,
            description: description,
            slot: slot,
            rarity: rarity,
            primaryStat: primaryStat,
            statBonus: statBonus,
            levelRequirement: 1,
            secondaryStat: secondaryStat,
            secondaryStatBonus: secondaryStatBonus,
            ownerID: ownerID
        )
        equip.catalogID = id
        return equip
    }
}

// MARK: - Gear Set Catalog

struct GearSetCatalog {
    
    /// All defined gear sets (3 starter + 6 advanced class sets)
    static let allSets: [GearSetDefinition] = [
        warriorSet, mageSet, archerSet,
        berserkerSet, paladinSet, sorcererSet, enchanterSet, rangerSet, tricksterSet
    ]
    
    /// Get the gear set for a character class (starter set for starter classes, advanced set for advanced)
    static func gearSet(for characterClass: CharacterClass) -> GearSetDefinition? {
        switch characterClass {
        case .warrior: return warriorSet
        case .mage: return mageSet
        case .archer: return archerSet
        case .berserker: return berserkerSet
        case .paladin: return paladinSet
        case .sorcerer: return sorcererSet
        case .enchanter: return enchanterSet
        case .ranger: return rangerSet
        case .trickster: return tricksterSet
        }
    }
    
    /// Get all gear sets a character class can use (starter + advanced if applicable)
    static func availableSets(for characterClass: CharacterClass) -> [GearSetDefinition] {
        switch characterClass {
        case .warrior: return [warriorSet]
        case .mage: return [mageSet]
        case .archer: return [archerSet]
        case .berserker: return [warriorSet, berserkerSet]
        case .paladin: return [warriorSet, paladinSet]
        case .sorcerer: return [mageSet, sorcererSet]
        case .enchanter: return [mageSet, enchanterSet]
        case .ranger: return [archerSet, rangerSet]
        case .trickster: return [archerSet, tricksterSet]
        }
    }
    
    /// Check if a character has the set bonus active.
    /// Redesigned: 2-piece activation — wear any 2 of the set's 3 pieces to get the bonus.
    /// Returns the first matching set bonus, or nil if no set is active.
    static func activeSetBonus(equippedCatalogIDs: Set<String>) -> (stat: StatType, amount: Int)? {
        for gearSet in allSets {
            let setPieceIDs = Set(gearSet.pieces.map { $0.id })
            let matchCount = setPieceIDs.intersection(equippedCatalogIDs).count
            if matchCount >= gearSet.piecesRequired {
                return (gearSet.bonusStat, gearSet.bonusAmount)
            }
        }
        return nil
    }
    
    /// Get the active gear set definition (if any) for a set of equipped catalog IDs.
    /// Useful for UI display of set bonus info.
    static func activeGearSet(equippedCatalogIDs: Set<String>) -> GearSetDefinition? {
        for gearSet in allSets {
            let setPieceIDs = Set(gearSet.pieces.map { $0.id })
            let matchCount = setPieceIDs.intersection(equippedCatalogIDs).count
            if matchCount >= gearSet.piecesRequired {
                return gearSet
            }
        }
        return nil
    }
    
    /// Count how many pieces of each set are currently equipped
    static func equippedSetPieceCounts(equippedCatalogIDs: Set<String>) -> [(set: GearSetDefinition, count: Int)] {
        allSets.compactMap { gearSet in
            let setPieceIDs = Set(gearSet.pieces.map { $0.id })
            let count = setPieceIDs.intersection(equippedCatalogIDs).count
            guard count > 0 else { return nil }
            return (gearSet, count)
        }
    }
    
    // MARK: - Warrior Set: Vanguard's Resolve
    
    static let warriorSet = GearSetDefinition(
        id: "set_warrior",
        name: "Vanguard's Resolve",
        description: "The armor of frontline champions. Equip any 2 pieces for +10% Defense in dungeons.",
        characterClass: .warrior,
        weapon: GearSetPiece(
            id: "set_warrior_weapon",
            name: "Vanguard Broadsword",
            description: "A broad, heavy blade forged for those who lead the charge.",
            slot: .weapon, rarity: .epic,
            primaryStat: .strength, statBonus: 8,
            secondaryStat: .defense, secondaryStatBonus: 3,
            goldCost: 400, baseType: "sword"
        ),
        armor: GearSetPiece(
            id: "set_warrior_armor",
            name: "Vanguard War Plate",
            description: "Thick plated armor bearing the crest of the vanguard.",
            slot: .armor, rarity: .epic,
            primaryStat: .defense, statBonus: 8,
            secondaryStat: .strength, secondaryStatBonus: 3,
            goldCost: 400, baseType: "plate"
        ),
        accessory: GearSetPiece(
            id: "set_warrior_accessory",
            name: "Vanguard's Oath Amulet",
            description: "A sworn amulet of protection carried by every member of the vanguard.",
            slot: .accessory, rarity: .epic,
            primaryStat: .defense, statBonus: 7,
            secondaryStat: .charisma, secondaryStatBonus: 2,
            goldCost: 350, baseType: "amulet"
        ),
        bonusStat: .defense,
        bonusAmount: 7,
        piecesRequired: 2,
        levelRequirement: 8
    )
    
    // MARK: - Mage Set: Arcanum's Embrace
    
    static let mageSet = GearSetDefinition(
        id: "set_mage",
        name: "Arcanum's Embrace",
        description: "Garments of pure arcane energy. Equip any 2 pieces for -10% AFK mission time.",
        characterClass: .mage,
        weapon: GearSetPiece(
            id: "set_mage_weapon",
            name: "Arcanum Focus Staff",
            description: "A staff carved from crystallized mana, pulsing with ancient knowledge.",
            slot: .weapon, rarity: .epic,
            primaryStat: .wisdom, statBonus: 8,
            secondaryStat: .luck, secondaryStatBonus: 3,
            goldCost: 400, baseType: "staff"
        ),
        armor: GearSetPiece(
            id: "set_mage_armor",
            name: "Arcanum Silk Vestment",
            description: "Robes threaded with arcane filaments that amplify the wearer's spells.",
            slot: .armor, rarity: .epic,
            primaryStat: .wisdom, statBonus: 8,
            secondaryStat: .defense, secondaryStatBonus: 3,
            goldCost: 400, baseType: "robes"
        ),
        accessory: GearSetPiece(
            id: "set_mage_accessory",
            name: "Arcanum Resonance Charm",
            description: "A charm that vibrates at the frequency of raw mana.",
            slot: .accessory, rarity: .epic,
            primaryStat: .wisdom, statBonus: 7,
            secondaryStat: .luck, secondaryStatBonus: 2,
            goldCost: 350, baseType: "charm"
        ),
        bonusStat: .wisdom,
        bonusAmount: 7,
        piecesRequired: 2,
        levelRequirement: 8
    )
    
    // MARK: - Archer Set: Windstrider's Mark
    
    static let archerSet = GearSetDefinition(
        id: "set_archer",
        name: "Windstrider's Mark",
        description: "Gear of the swift and silent. Equip any 2 pieces for +10% loot drop chance.",
        characterClass: .archer,
        weapon: GearSetPiece(
            id: "set_archer_weapon",
            name: "Windstrider Longbow",
            description: "A sleek bow engineered for speed. Arrows fly true even in storms.",
            slot: .weapon, rarity: .epic,
            primaryStat: .dexterity, statBonus: 8,
            secondaryStat: .luck, secondaryStatBonus: 3,
            goldCost: 400, baseType: "bow"
        ),
        armor: GearSetPiece(
            id: "set_archer_armor",
            name: "Windstrider Leather",
            description: "Featherlight leather armor treated for maximum mobility.",
            slot: .armor, rarity: .epic,
            primaryStat: .dexterity, statBonus: 8,
            secondaryStat: .defense, secondaryStatBonus: 3,
            goldCost: 400, baseType: "leather armor"
        ),
        accessory: GearSetPiece(
            id: "set_archer_accessory",
            name: "Windstrider's Signet Ring",
            description: "A ring bearing the mark of the windstriders — an elite order of archers.",
            slot: .accessory, rarity: .epic,
            primaryStat: .dexterity, statBonus: 7,
            secondaryStat: .luck, secondaryStatBonus: 2,
            goldCost: 350, baseType: "ring"
        ),
        bonusStat: .dexterity,
        bonusAmount: 7,
        piecesRequired: 2,
        levelRequirement: 8
    )
    
    // =========================================================================
    // MARK: - Advanced Class Sets (6 sets, level 25 requirement)
    // =========================================================================
    
    // MARK: - Berserker Set: Bloodrage
    
    static let berserkerSet = GearSetDefinition(
        id: "set_berserker",
        name: "Bloodrage",
        description: "Forged in fury and tempered by wrath. Equip any 2 pieces for +15% EXP from Physical tasks.",
        characterClass: .berserker,
        weapon: GearSetPiece(
            id: "set_berserker_weapon",
            name: "Bloodrage Cleaver",
            description: "A massive axe that drinks in the wielder's rage and channels it into devastating blows.",
            slot: .weapon, rarity: .epic,
            primaryStat: .strength, statBonus: 10,
            secondaryStat: .dexterity, secondaryStatBonus: 4,
            goldCost: 600, baseType: "axe"
        ),
        armor: GearSetPiece(
            id: "set_berserker_armor",
            name: "Bloodrage Warplate",
            description: "Scarred plate armor that grows lighter the angrier its wearer becomes.",
            slot: .armor, rarity: .epic,
            primaryStat: .strength, statBonus: 9,
            secondaryStat: .defense, secondaryStatBonus: 5,
            goldCost: 600, baseType: "plate"
        ),
        accessory: GearSetPiece(
            id: "set_berserker_accessory",
            name: "Bloodrage Band",
            description: "A crimson band that pulses in time with its wearer's heartbeat. Faster when fighting.",
            slot: .accessory, rarity: .epic,
            primaryStat: .strength, statBonus: 8,
            secondaryStat: .luck, secondaryStatBonus: 3,
            goldCost: 500, baseType: "ring"
        ),
        bonusStat: .strength,
        bonusAmount: 10,
        piecesRequired: 2,
        levelRequirement: 25
    )
    
    // MARK: - Paladin Set: Oathkeeper
    
    static let paladinSet = GearSetDefinition(
        id: "set_paladin",
        name: "Oathkeeper",
        description: "Blessed armor of the sworn protectors. Equip any 2 pieces for -20% party damage in dungeons.",
        characterClass: .paladin,
        weapon: GearSetPiece(
            id: "set_paladin_weapon",
            name: "Oathkeeper Mace",
            description: "A holy mace that blazes brighter when defending allies. Justice incarnate.",
            slot: .weapon, rarity: .epic,
            primaryStat: .strength, statBonus: 9,
            secondaryStat: .charisma, secondaryStatBonus: 5,
            goldCost: 600, baseType: "mace"
        ),
        armor: GearSetPiece(
            id: "set_paladin_armor",
            name: "Oathkeeper Plate",
            description: "Consecrated plate inscribed with binding oaths. It absorbs blows meant for others.",
            slot: .armor, rarity: .epic,
            primaryStat: .defense, statBonus: 11,
            secondaryStat: .strength, secondaryStatBonus: 4,
            goldCost: 600, baseType: "plate"
        ),
        accessory: GearSetPiece(
            id: "set_paladin_accessory",
            name: "Oathkeeper Seal",
            description: "A signet ring bearing the seal of the sworn protectors. Its light shields allies.",
            slot: .accessory, rarity: .epic,
            primaryStat: .defense, statBonus: 8,
            secondaryStat: .charisma, secondaryStatBonus: 4,
            goldCost: 500, baseType: "ring"
        ),
        bonusStat: .defense,
        bonusAmount: 10,
        piecesRequired: 2,
        levelRequirement: 25
    )
    
    // MARK: - Sorcerer Set: Voidweave
    
    static let sorcererSet = GearSetDefinition(
        id: "set_sorcerer",
        name: "Voidweave",
        description: "Woven from the threads between dimensions. Equip any 2 pieces for +15% EXP from Mental tasks.",
        characterClass: .sorcerer,
        weapon: GearSetPiece(
            id: "set_sorcerer_weapon",
            name: "Voidweave Staff",
            description: "A staff that bends reality around its tip. Spells cast through it arrive before they're spoken.",
            slot: .weapon, rarity: .epic,
            primaryStat: .wisdom, statBonus: 10,
            secondaryStat: .dexterity, secondaryStatBonus: 4,
            goldCost: 600, baseType: "staff"
        ),
        armor: GearSetPiece(
            id: "set_sorcerer_armor",
            name: "Voidweave Robes",
            description: "Robes that exist in multiple dimensions simultaneously. Magic flows through them unimpeded.",
            slot: .armor, rarity: .epic,
            primaryStat: .wisdom, statBonus: 10,
            secondaryStat: .defense, secondaryStatBonus: 4,
            goldCost: 600, baseType: "robes"
        ),
        accessory: GearSetPiece(
            id: "set_sorcerer_accessory",
            name: "Voidweave Ring",
            description: "A ring of condensed void-matter. It amplifies magical resonance tenfold.",
            slot: .accessory, rarity: .epic,
            primaryStat: .wisdom, statBonus: 8,
            secondaryStat: .luck, secondaryStatBonus: 4,
            goldCost: 500, baseType: "ring"
        ),
        bonusStat: .wisdom,
        bonusAmount: 10,
        piecesRequired: 2,
        levelRequirement: 25
    )
    
    // MARK: - Enchanter Set: Resonance Threads
    
    static let enchanterSet = GearSetDefinition(
        id: "set_enchanter",
        name: "Resonance Threads",
        description: "Harmonic attire of the support master. Equip any 2 pieces for +20% party bond EXP.",
        characterClass: .enchanter,
        weapon: GearSetPiece(
            id: "set_enchanter_weapon",
            name: "Resonance Wand",
            description: "A wand that harmonizes with nearby allies, amplifying everyone's potential.",
            slot: .weapon, rarity: .epic,
            primaryStat: .charisma, statBonus: 10,
            secondaryStat: .wisdom, secondaryStatBonus: 4,
            goldCost: 600, baseType: "wand"
        ),
        armor: GearSetPiece(
            id: "set_enchanter_armor",
            name: "Resonance Vestments",
            description: "Robes that vibrate at the frequency of friendship. Bonds strengthen in their presence.",
            slot: .armor, rarity: .epic,
            primaryStat: .charisma, statBonus: 9,
            secondaryStat: .defense, secondaryStatBonus: 5,
            goldCost: 600, baseType: "robes"
        ),
        accessory: GearSetPiece(
            id: "set_enchanter_accessory",
            name: "Resonance Pendant",
            description: "A pendant that glows brighter with each ally nearby. Isolation dims it completely.",
            slot: .accessory, rarity: .epic,
            primaryStat: .charisma, statBonus: 8,
            secondaryStat: .luck, secondaryStatBonus: 4,
            goldCost: 500, baseType: "pendant"
        ),
        bonusStat: .charisma,
        bonusAmount: 10,
        piecesRequired: 2,
        levelRequirement: 25
    )
    
    // MARK: - Ranger Set: Stalker
    
    static let rangerSet = GearSetDefinition(
        id: "set_ranger",
        name: "Stalker",
        description: "Silent hunter's gear, perfected over centuries. Equip any 2 pieces for -15% AFK mission time.",
        characterClass: .ranger,
        weapon: GearSetPiece(
            id: "set_ranger_weapon",
            name: "Stalker Bow",
            description: "A bow that makes no sound when drawn. Its arrows are heard only by the target.",
            slot: .weapon, rarity: .epic,
            primaryStat: .dexterity, statBonus: 10,
            secondaryStat: .luck, secondaryStatBonus: 4,
            goldCost: 600, baseType: "bow"
        ),
        armor: GearSetPiece(
            id: "set_ranger_armor",
            name: "Stalker Leather",
            description: "Leather treated to blend with any terrain. The wearer becomes part of the landscape.",
            slot: .armor, rarity: .epic,
            primaryStat: .dexterity, statBonus: 9,
            secondaryStat: .defense, secondaryStatBonus: 5,
            goldCost: 600, baseType: "leather armor"
        ),
        accessory: GearSetPiece(
            id: "set_ranger_trinket",
            name: "Stalker Charm",
            description: "A charm carved from the heartwood of an ancient forest. Nature conceals its bearer.",
            slot: .trinket, rarity: .epic,
            primaryStat: .dexterity, statBonus: 8,
            secondaryStat: .luck, secondaryStatBonus: 3,
            goldCost: 500, baseType: "charm"
        ),
        bonusStat: .dexterity,
        bonusAmount: 10,
        piecesRequired: 2,
        levelRequirement: 25
    )
    
    // MARK: - Trickster Set: Shadow Gambit
    
    static let tricksterSet = GearSetDefinition(
        id: "set_trickster",
        name: "Shadow Gambit",
        description: "Gear of chance and misdirection. Equip any 2 pieces for +15% loot drop chance.",
        characterClass: .trickster,
        weapon: GearSetPiece(
            id: "set_trickster_weapon",
            name: "Shadow Gambit Dagger",
            description: "A dagger that flickers between shadows. Each strike is a roll of the dice.",
            slot: .weapon, rarity: .epic,
            primaryStat: .luck, statBonus: 10,
            secondaryStat: .dexterity, secondaryStatBonus: 4,
            goldCost: 600, baseType: "dagger"
        ),
        armor: GearSetPiece(
            id: "set_trickster_armor",
            name: "Shadow Gambit Cloak",
            description: "A cloak that shifts probability. Blows meant to connect somehow miss.",
            slot: .trinket, rarity: .epic,
            primaryStat: .luck, statBonus: 9,
            secondaryStat: .dexterity, secondaryStatBonus: 5,
            goldCost: 600, baseType: "cloak"
        ),
        accessory: GearSetPiece(
            id: "set_trickster_accessory",
            name: "Shadow Gambit Ring",
            description: "A ring that whispers odds. Its wearer always knows when to hold and when to fold.",
            slot: .accessory, rarity: .epic,
            primaryStat: .luck, statBonus: 8,
            secondaryStat: .charisma, secondaryStatBonus: 4,
            goldCost: 500, baseType: "ring"
        ),
        bonusStat: .luck,
        bonusAmount: 10,
        piecesRequired: 2,
        levelRequirement: 25
    )
}

// MARK: - Bundle Deal

/// A curated bundle of equipment + consumables at a discount
struct BundleDeal: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let equipmentPieces: [BundleEquipmentItem]
    let consumables: [BundleConsumableItem]
    let goldCost: Int               // 0 if gem bundle
    let gemCost: Int                // 0 if gold bundle
    let originalValue: Int          // sum of individual prices (for "save X%" display)
    let levelRequirement: Int
    
    var savingsPercent: Int {
        guard originalValue > 0 else { return 0 }
        let totalCost = goldCost > 0 ? goldCost : gemCost
        return Int(round(Double(originalValue - totalCost) / Double(originalValue) * 100))
    }
    
    var itemCount: Int {
        equipmentPieces.count + consumables.count
    }
}

/// Equipment item inside a bundle
struct BundleEquipmentItem {
    let catalogID: String           // references EquipmentCatalog.find(id:)
    let name: String
    let slot: EquipmentSlot
    let rarity: ItemRarity
}

/// Consumable item inside a bundle
struct BundleConsumableItem {
    let templateName: String        // matches ConsumableCatalog item by name
    let quantity: Int
}

// MARK: - Bundle Catalog

struct BundleCatalog {
    
    static let allBundles: [BundleDeal] = [starterPack, dungeonKit, championBundle, gemStarterPack]
    
    /// Bundles available for a given character level
    static func availableBundles(level: Int) -> [BundleDeal] {
        allBundles.filter { $0.levelRequirement <= level }
    }
    
    // MARK: - Bundles
    
    static let starterPack = BundleDeal(
        id: "bundle_starter",
        name: "Adventurer's Starter Pack",
        description: "Everything a new hero needs to begin their journey.",
        icon: "bag.fill",
        equipmentPieces: [
            BundleEquipmentItem(catalogID: "wep_sword_common_01", name: "Worn Training Sword", slot: .weapon, rarity: .common),
        ],
        consumables: [
            BundleConsumableItem(templateName: "Herbal Tea", quantity: 2),
            BundleConsumableItem(templateName: "Energy Bar", quantity: 1),
        ],
        goldCost: 80,
        gemCost: 0,
        originalValue: 120,
        levelRequirement: 1
    )
    
    static let dungeonKit = BundleDeal(
        id: "bundle_dungeon",
        name: "Dungeon Prep Kit",
        description: "Gear up before descending into the depths.",
        icon: "door.left.hand.open",
        equipmentPieces: [
            BundleEquipmentItem(catalogID: "wep_sword_uncommon_01", name: "Steel Longsword", slot: .weapon, rarity: .uncommon),
        ],
        consumables: [
            BundleConsumableItem(templateName: "Healing Draught", quantity: 2),
            BundleConsumableItem(templateName: "Cozy Blanket", quantity: 1),
        ],
        goldCost: 200,
        gemCost: 0,
        originalValue: 300,
        levelRequirement: 5
    )
    
    static let championBundle = BundleDeal(
        id: "bundle_champion",
        name: "Champion's Bundle",
        description: "Premium gear for the seasoned warrior.",
        icon: "crown.fill",
        equipmentPieces: [
            BundleEquipmentItem(catalogID: "wep_sword_rare_01", name: "Runic Claymore", slot: .weapon, rarity: .rare),
        ],
        consumables: [
            BundleConsumableItem(templateName: "Greater Healing Draught", quantity: 1),
            BundleConsumableItem(templateName: "Power Bar", quantity: 1),
        ],
        goldCost: 400,
        gemCost: 0,
        originalValue: 530,
        levelRequirement: 15
    )
    
    static let gemStarterPack = BundleDeal(
        id: "bundle_gem_starter",
        name: "Gem Starter Pack",
        description: "Essential premium items to give you the edge.",
        icon: "diamond.fill",
        equipmentPieces: [],
        consumables: [
            BundleConsumableItem(templateName: "Revive Token", quantity: 1),
            BundleConsumableItem(templateName: "Loot Reroll", quantity: 1),
        ],
        goldCost: 0,
        gemCost: 6,
        originalValue: 8,
        levelRequirement: 10
    )
}
