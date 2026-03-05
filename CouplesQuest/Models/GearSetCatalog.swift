import Foundation
import UIKit

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
    let statBonus: Double
    let secondaryStat: StatType?
    let secondaryStatBonus: Double
    let goldCost: Int
    let baseType: String
    
    /// Rounded display value for base stat bonus
    var statBonusDisplay: Int { Int(statBonus.rounded()) }
    /// Rounded display value for secondary stat bonus
    var secondaryStatBonusDisplay: Int { Int(secondaryStatBonus.rounded()) }
    
    /// Resolved image asset name based on baseType and rarity (e.g. "equip-bow-epic")
    var imageName: String? {
        let base = "equip-\(baseType.lowercased().replacingOccurrences(of: " ", with: "-"))"
        let tinted = "\(base)-\(rarity.rawValue.lowercased())"
        if UIImage(named: tinted) != nil { return tinted }
        if UIImage(named: base) != nil { return base }
        return nil
    }
    
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
            ownerID: ownerID,
            baseType: baseType
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
        description: "The official uniform of people who solve problems by standing in front of them. Equip any 2 pieces for +10% Defense in dungeons.",
        characterClass: .warrior,
        weapon: GearSetPiece(
            id: "set_warrior_weapon",
            name: "Vanguard Broadsword",
            description: "So broad it's basically a shield that got confused about its career path.",
            slot: .weapon, rarity: .epic,
            primaryStat: .strength, statBonus: 8,
            secondaryStat: .defense, secondaryStatBonus: 3,
            goldCost: 1200, baseType: "sword"
        ),
        armor: GearSetPiece(
            id: "set_warrior_armor",
            name: "Vanguard War Plate",
            description: "Comes pre-dented for authenticity. The crest on the front says 'vanguard,' which is medieval for 'hit me first.'",
            slot: .armor, rarity: .epic,
            primaryStat: .defense, statBonus: 8,
            secondaryStat: .strength, secondaryStatBonus: 3,
            goldCost: 1200, baseType: "plate"
        ),
        accessory: GearSetPiece(
            id: "set_warrior_accessory",
            name: "Vanguard's Oath Amulet",
            description: "Every member of the vanguard wears one. Losing it voids your warranty and your dental plan.",
            slot: .accessory, rarity: .epic,
            primaryStat: .defense, statBonus: 7,
            secondaryStat: .charisma, secondaryStatBonus: 2,
            goldCost: 800, baseType: "amulet"
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
        description: "Robes that hug you with pure arcane energy. It's not weird, it's magical. Equip any 2 pieces for -10% AFK mission time.",
        characterClass: .mage,
        weapon: GearSetPiece(
            id: "set_mage_weapon",
            name: "Arcanum Focus Staff",
            description: "Carved from crystallized mana by someone who never heard of ergonomic design. Your wrist will hate you, but your spells will slap.",
            slot: .weapon, rarity: .epic,
            primaryStat: .wisdom, statBonus: 8,
            secondaryStat: .luck, secondaryStatBonus: 3,
            goldCost: 1200, baseType: "staff"
        ),
        armor: GearSetPiece(
            id: "set_mage_armor",
            name: "Arcanum Silk Vestment",
            description: "Amplifies your spells at the minor cost of looking like a haunted curtain. Fashion is subjective.",
            slot: .armor, rarity: .epic,
            primaryStat: .wisdom, statBonus: 8,
            secondaryStat: .defense, secondaryStatBonus: 3,
            goldCost: 1200, baseType: "robes"
        ),
        accessory: GearSetPiece(
            id: "set_mage_accessory",
            name: "Arcanum Resonance Charm",
            description: "Vibrates at the frequency of raw mana. Also pairs with most Bluetooth speakers, if you're curious.",
            slot: .accessory, rarity: .epic,
            primaryStat: .wisdom, statBonus: 7,
            secondaryStat: .luck, secondaryStatBonus: 2,
            goldCost: 800, baseType: "charm"
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
        description: "For archers who want to look fast while standing completely still. Equip any 2 pieces for +10% loot drop chance.",
        characterClass: .archer,
        weapon: GearSetPiece(
            id: "set_archer_weapon",
            name: "Windstrider Longbow",
            description: "Engineered for speed and silence. The arrows make a dramatic whistling sound because the designer had a flair for theater.",
            slot: .weapon, rarity: .epic,
            primaryStat: .dexterity, statBonus: 8,
            secondaryStat: .luck, secondaryStatBonus: 3,
            goldCost: 1200, baseType: "bow"
        ),
        armor: GearSetPiece(
            id: "set_archer_armor",
            name: "Windstrider Leather",
            description: "So featherlight you'll forget you're wearing armor. You'll remember when something hits you, though.",
            slot: .armor, rarity: .epic,
            primaryStat: .dexterity, statBonus: 8,
            secondaryStat: .defense, secondaryStatBonus: 3,
            goldCost: 1200, baseType: "leather armor"
        ),
        accessory: GearSetPiece(
            id: "set_archer_accessory",
            name: "Windstrider's Signet Ring",
            description: "Bears the mark of an elite archer order that mostly argues about what counts as a 'fair shot.'",
            slot: .accessory, rarity: .epic,
            primaryStat: .dexterity, statBonus: 7,
            secondaryStat: .luck, secondaryStatBonus: 2,
            goldCost: 800, baseType: "ring"
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
        description: "For those who think anger management is a stat build. Equip any 2 pieces for +15% EXP from Physical tasks.",
        characterClass: .berserker,
        weapon: GearSetPiece(
            id: "set_berserker_weapon",
            name: "Bloodrage Cleaver",
            description: "Channels your rage into devastating blows. Therapy was considered as an alternative but tested poorly in focus groups.",
            slot: .weapon, rarity: .epic,
            primaryStat: .strength, statBonus: 10,
            secondaryStat: .dexterity, secondaryStatBonus: 4,
            goldCost: 8000, baseType: "axe"
        ),
        armor: GearSetPiece(
            id: "set_berserker_armor",
            name: "Bloodrage Warplate",
            description: "Gets lighter the angrier you become, which raises some unsettling questions about physics that nobody wants to ask.",
            slot: .armor, rarity: .epic,
            primaryStat: .strength, statBonus: 9,
            secondaryStat: .defense, secondaryStatBonus: 5,
            goldCost: 7000, baseType: "plate"
        ),
        accessory: GearSetPiece(
            id: "set_berserker_accessory",
            name: "Bloodrage Band",
            description: "Pulses with your heartbeat. Your doctor says that's concerning. Your damage output says otherwise.",
            slot: .accessory, rarity: .epic,
            primaryStat: .strength, statBonus: 8,
            secondaryStat: .luck, secondaryStatBonus: 3,
            goldCost: 5000, baseType: "ring"
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
        description: "Blessed armor for people who took 'protect and serve' way too literally. Equip any 2 pieces for -20% party damage in dungeons.",
        characterClass: .paladin,
        weapon: GearSetPiece(
            id: "set_paladin_weapon",
            name: "Oathkeeper Mace",
            description: "Blazes brighter when defending allies. Burns calories at a frankly irresponsible rate. Pack snacks.",
            slot: .weapon, rarity: .epic,
            primaryStat: .strength, statBonus: 9,
            secondaryStat: .charisma, secondaryStatBonus: 5,
            goldCost: 8000, baseType: "mace"
        ),
        armor: GearSetPiece(
            id: "set_paladin_armor",
            name: "Oathkeeper Plate",
            description: "Inscribed with so many binding oaths that returning it to the shop requires a team of lawyers.",
            slot: .armor, rarity: .epic,
            primaryStat: .defense, statBonus: 11,
            secondaryStat: .strength, secondaryStatBonus: 4,
            goldCost: 7000, baseType: "plate"
        ),
        accessory: GearSetPiece(
            id: "set_paladin_accessory",
            name: "Oathkeeper Seal",
            description: "The official ring of the sworn protectors. Flashing it gets you 10% off at most taverns and zero respect from rogues.",
            slot: .accessory, rarity: .epic,
            primaryStat: .defense, statBonus: 8,
            secondaryStat: .charisma, secondaryStatBonus: 4,
            goldCost: 5000, baseType: "ring"
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
        description: "Woven from the fabric between dimensions by a tailor who really needs to talk about boundaries. Equip any 2 pieces for +15% EXP from Mental tasks.",
        characterClass: .sorcerer,
        weapon: GearSetPiece(
            id: "set_sorcerer_weapon",
            name: "Voidweave Staff",
            description: "Spells cast through it arrive before they're spoken, which makes trash talk completely obsolete.",
            slot: .weapon, rarity: .epic,
            primaryStat: .wisdom, statBonus: 10,
            secondaryStat: .dexterity, secondaryStatBonus: 4,
            goldCost: 8000, baseType: "staff"
        ),
        armor: GearSetPiece(
            id: "set_sorcerer_armor",
            name: "Voidweave Robes",
            description: "Exist in multiple dimensions simultaneously, which makes doing laundry a cross-dimensional logistics problem.",
            slot: .armor, rarity: .epic,
            primaryStat: .wisdom, statBonus: 10,
            secondaryStat: .defense, secondaryStatBonus: 4,
            goldCost: 7000, baseType: "robes"
        ),
        accessory: GearSetPiece(
            id: "set_sorcerer_accessory",
            name: "Voidweave Ring",
            description: "Amplifies magical resonance tenfold. Side effects include mild omniscience and an overwhelming urge to correct people.",
            slot: .accessory, rarity: .epic,
            primaryStat: .wisdom, statBonus: 8,
            secondaryStat: .luck, secondaryStatBonus: 4,
            goldCost: 5000, baseType: "ring"
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
        description: "Clothes that literally vibrate with friendship. Your party loves you. They have no choice. Equip any 2 pieces for +20% party bond EXP.",
        characterClass: .enchanter,
        weapon: GearSetPiece(
            id: "set_enchanter_weapon",
            name: "Resonance Wand",
            description: "Amplifies everyone's potential whether they asked for it or not. The fantasy equivalent of a motivational speaker with a weapon.",
            slot: .weapon, rarity: .epic,
            primaryStat: .charisma, statBonus: 10,
            secondaryStat: .wisdom, secondaryStatBonus: 4,
            goldCost: 8000, baseType: "wand"
        ),
        armor: GearSetPiece(
            id: "set_enchanter_armor",
            name: "Resonance Vestments",
            description: "Vibrate at the frequency of friendship, which turns out to be a low B-flat. Musicians find this deeply unsettling.",
            slot: .armor, rarity: .epic,
            primaryStat: .charisma, statBonus: 9,
            secondaryStat: .defense, secondaryStatBonus: 5,
            goldCost: 7000, baseType: "robes"
        ),
        accessory: GearSetPiece(
            id: "set_enchanter_accessory",
            name: "Resonance Amulet",
            description: "Glows brighter with each nearby ally. Alone in your room at 2 AM? Complete darkness. It knows.",
            slot: .accessory, rarity: .epic,
            primaryStat: .charisma, statBonus: 8,
            secondaryStat: .luck, secondaryStatBonus: 4,
            goldCost: 5000, baseType: "amulet"
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
        description: "Silent hunter's gear, perfected by someone who took 'personal space' as a challenge. Equip any 2 pieces for -15% AFK mission time.",
        characterClass: .ranger,
        weapon: GearSetPiece(
            id: "set_ranger_weapon",
            name: "Stalker Bow",
            description: "Makes absolutely no sound when drawn. Your target's last thought will be 'huh, that's weird' and honestly that's the dream.",
            slot: .weapon, rarity: .epic,
            primaryStat: .dexterity, statBonus: 10,
            secondaryStat: .luck, secondaryStatBonus: 4,
            goldCost: 8000, baseType: "bow"
        ),
        armor: GearSetPiece(
            id: "set_ranger_armor",
            name: "Stalker Leather",
            description: "Blends with any terrain so effectively that your own party will lose you during bathroom breaks.",
            slot: .armor, rarity: .epic,
            primaryStat: .dexterity, statBonus: 9,
            secondaryStat: .defense, secondaryStatBonus: 5,
            goldCost: 7000, baseType: "leather armor"
        ),
        accessory: GearSetPiece(
            id: "set_ranger_trinket",
            name: "Stalker Charm",
            description: "Carved from the heartwood of an ancient forest. The forest filed a complaint, but no court has jurisdiction over charm-carving.",
            slot: .trinket, rarity: .epic,
            primaryStat: .dexterity, statBonus: 8,
            secondaryStat: .luck, secondaryStatBonus: 3,
            goldCost: 5000, baseType: "charm"
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
        description: "For the discerning rogue who believes fairness is a spectrum. Equip any 2 pieces for +15% loot drop chance.",
        characterClass: .trickster,
        weapon: GearSetPiece(
            id: "set_trickster_weapon",
            name: "Shadow Gambit Dagger",
            description: "Flickers between shadows mid-stab. Your enemies will call it cheap. You'll call it tactical.",
            slot: .weapon, rarity: .epic,
            primaryStat: .luck, statBonus: 10,
            secondaryStat: .dexterity, secondaryStatBonus: 4,
            goldCost: 8000, baseType: "dagger"
        ),
        armor: GearSetPiece(
            id: "set_trickster_armor",
            name: "Shadow Gambit Cloak",
            description: "Shifts probability so that attacks somehow miss. The cloak insists this is skill, not luck. The stats say otherwise.",
            slot: .cloak, rarity: .epic,
            primaryStat: .luck, statBonus: 9,
            secondaryStat: .dexterity, secondaryStatBonus: 5,
            goldCost: 7000, baseType: "cloak"
        ),
        accessory: GearSetPiece(
            id: "set_trickster_accessory",
            name: "Shadow Gambit Ring",
            description: "Whispers the odds of everything. Yes, everything. You can't turn it off. You learn to live with it.",
            slot: .accessory, rarity: .epic,
            primaryStat: .luck, statBonus: 8,
            secondaryStat: .charisma, secondaryStatBonus: 4,
            goldCost: 5000, baseType: "ring"
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
            BundleConsumableItem(templateName: "Minor Healing Potion", quantity: 2),
            BundleConsumableItem(templateName: "Arcane Star", quantity: 1),
        ],
        goldCost: 250,
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
            BundleConsumableItem(templateName: "Guardian Flask", quantity: 1),
        ],
        goldCost: 750,
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
            BundleConsumableItem(templateName: "Arcane Star", quantity: 1),
        ],
        goldCost: 1500,
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
            BundleConsumableItem(templateName: "Revival Elixir", quantity: 1),
            BundleConsumableItem(templateName: "Fate Idol", quantity: 1),
        ],
        goldCost: 0,
        gemCost: 6,
        originalValue: 8,
        levelRequirement: 10
    )
}
