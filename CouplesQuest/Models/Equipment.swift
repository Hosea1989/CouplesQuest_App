import Foundation
import SwiftData
import SwiftUI
import UIKit

/// Equipment items that provide stat bonuses
@Model
final class Equipment {
    /// Unique identifier
    var id: UUID
    
    /// Item name
    var name: String
    
    /// Item description
    var itemDescription: String
    
    /// Equipment slot
    var slot: EquipmentSlot
    
    /// Item rarity
    var rarity: ItemRarity
    
    /// Primary stat this item boosts
    var primaryStat: StatType
    
    /// Amount of stat bonus (Double for precise quirk/affix stacking)
    var statBonus: Double
    
    /// Level required to equip
    var levelRequirement: Int
    
    /// Secondary stat this item boosts (optional)
    var secondaryStat: StatType?
    
    /// Amount of secondary stat bonus (Double for precise quirk/affix stacking)
    var secondaryStatBonus: Double
    
    /// Character ID of the owner (nil = unowned)
    var ownerID: UUID?
    
    /// Is this item equipped?
    var isEquipped: Bool
    
    /// When this item was acquired
    var acquiredAt: Date
    
    /// Enhancement level (0 = base, max 10). Each level adds +1 primary stat bonus.
    var enhancementLevel: Int = 0
    
    /// Catalog ID for matching gear sets and milestone items (nil for procedurally generated gear)
    var catalogID: String?
    
    /// Explicit base type for sprite resolution (e.g. "sword", "leather armor"). Overrides keyword matching.
    var baseType: String?
    
    // MARK: - Affixes
    
    /// Prefix affix (e.g. "Blazing" — +X% EXP from physical tasks)
    @Relationship(deleteRule: .cascade)
    var prefix: EquipmentAffix?
    
    /// Suffix affix (e.g. "of Fortune" — +X% loot drop chance)
    @Relationship(deleteRule: .cascade)
    var suffix: EquipmentAffix?
    
    // MARK: - Equipment Leveling
    
    /// Equipment experience points (earned by using the item in activities)
    var equipmentEXP: Int = 0
    
    /// Equipment level (1-5). Gains a quirk at each level-up (2, 3, 4, 5).
    var equipmentLevel: Int = 1
    
    /// Quirks gained through leveling — random traits with positive, negative, or mixed effects
    @Relationship(deleteRule: .cascade)
    var quirks: [EquipmentQuirk] = []
    
    /// Maximum equipment level
    static let maxEquipmentLevel = 5
    
    /// Maximum enhancement level (legacy, will be removed)
    static let maxEnhancementLevel = 10
    
    init(
        name: String,
        description: String,
        slot: EquipmentSlot,
        rarity: ItemRarity,
        primaryStat: StatType,
        statBonus: Double,
        levelRequirement: Int = 1,
        secondaryStat: StatType? = nil,
        secondaryStatBonus: Double = 0,
        ownerID: UUID? = nil,
        baseType: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.itemDescription = description
        self.slot = slot
        self.rarity = rarity
        self.primaryStat = primaryStat
        self.statBonus = statBonus
        self.levelRequirement = levelRequirement
        self.secondaryStat = secondaryStat
        self.secondaryStatBonus = secondaryStatBonus
        self.ownerID = ownerID
        self.isEquipped = false
        self.acquiredAt = Date()
        self.enhancementLevel = 0
        self.equipmentEXP = 0
        self.equipmentLevel = 1
        self.quirks = []
        self.prefix = nil
        self.suffix = nil
        self.baseType = baseType
    }
    
    /// Primary stat bonus including enhancements
    var effectivePrimaryBonus: Double {
        statBonus + Double(enhancementLevel)
    }
    
    /// Total stat bonus (primary + enhancement + secondary)
    var totalStatBonus: Double {
        effectivePrimaryBonus + secondaryStatBonus
    }
    
    /// Rounded display value for primary bonus
    var effectivePrimaryBonusDisplay: Int {
        Int(effectivePrimaryBonus.rounded())
    }
    
    /// Rounded display value for total bonus
    var totalStatBonusDisplay: Int {
        Int(totalStatBonus.rounded())
    }
    
    /// Rounded display value for base stat bonus
    var statBonusDisplay: Int {
        Int(statBonus.rounded())
    }
    
    /// Rounded display value for secondary stat bonus
    var secondaryStatBonusDisplay: Int {
        Int(secondaryStatBonus.rounded())
    }
    
    // MARK: - Equipment Leveling
    
    /// EXP required to reach a given equipment level
    static func expRequired(forLevel level: Int) -> Int {
        switch level {
        case 2: return 100
        case 3: return 350
        case 4: return 750
        case 5: return 1500
        default: return 0
        }
    }
    
    /// EXP needed to reach the next level from current level (0 if maxed)
    var expToNextLevel: Int {
        guard equipmentLevel < Equipment.maxEquipmentLevel else { return 0 }
        return Equipment.expRequired(forLevel: equipmentLevel + 1)
    }
    
    /// Progress toward next level as 0.0-1.0
    var levelProgress: Double {
        guard expToNextLevel > 0 else { return 1.0 }
        return min(1.0, Double(equipmentEXP) / Double(expToNextLevel))
    }
    
    /// Whether this item can still level up
    var canLevelUp: Bool {
        equipmentLevel < Equipment.maxEquipmentLevel
    }
    
    /// Grant EXP to this item. Returns true if a level-up occurred.
    @discardableResult
    func grantEXP(_ amount: Int) -> Bool {
        guard canLevelUp else { return false }
        equipmentEXP += amount
        
        if equipmentEXP >= expToNextLevel {
            equipmentEXP -= expToNextLevel
            equipmentLevel += 1
            return true
        }
        return false
    }
    
    /// Aggregate quirk stat bonuses with diminishing returns
    var quirkBonuses: [StatType: Double] {
        QuirkRoller.aggregateQuirkBonuses(quirks)
    }
    
    /// Aggregate quirk special effects
    var quirkSpecialEffects: [SpecialEffectType: Double] {
        QuirkRoller.aggregateSpecialEffects(quirks)
    }
    
    /// Detect the base type keyword from the item name for quirk pool lookups
    var detectedBaseType: String {
        if let bt = baseType { return bt.lowercased() }
        let lower = name.lowercased()
        let keywords = [
            "sword", "axe", "staff", "dagger", "bow", "orb", "wand", "mace",
            "spear", "shield", "crossbow", "tome", "halberd",
            "plate", "chainmail", "robes", "leather armor", "breastplate",
            "heavy helm", "helm", "heavy gauntlets", "gauntlets",
            "heavy boots", "boots", "greaves", "pauldrons", "cape", "mantle",
            "ring", "amulet", "pendant", "earring", "brooch", "talisman",
            "cloak", "bracelet", "charm", "belt"
        ]
        return keywords.first(where: { lower.contains($0) }) ?? "sword"
    }
    
    /// Armor weight class derived from the item's base type
    var armorWeight: ArmorWeight {
        guard slot == .armor else { return .universal }
        let base = detectedBaseType
        switch base {
        case "plate", "chainmail", "breastplate", "pauldrons",
             "heavy helm", "heavy gauntlets", "heavy boots":
            return .heavy
        case "robes", "leather armor", "helm", "gauntlets",
             "boots", "greaves":
            return .light
        default:
            return .universal
        }
    }
    
    /// Maps this equipment to a rarity-tinted image asset in Equipment.xcassets.
    /// Returns e.g. "equip-sword-rare" for a rare sword item.
    /// Falls back to the base (un-tinted) asset, then nil if no match exists.
    var imageName: String? {
        guard let base = baseImageName else { return nil }
        
        // Prefer the rarity-tinted variant (e.g. "equip-sword-epic")
        let raritySuffix = rarity.rawValue.lowercased()
        let tinted = "\(base)-\(raritySuffix)"
        if UIImage(named: tinted) != nil { return tinted }
        
        // Fall back to base (un-tinted) image
        return base
    }
    
    /// The base equipment type image key (without rarity suffix).
    private var baseImageName: String? {
        if let bt = baseType {
            return "equip-\(bt.lowercased().replacingOccurrences(of: " ", with: "-"))"
        }
        
        let lowerName = name.lowercased()
        
        // Weapon base types
        let weaponMap: [(keyword: String, asset: String)] = [
            ("sword", "equip-sword"),
            ("axe", "equip-axe"),
            ("staff", "equip-staff"),
            ("dagger", "equip-dagger"),
            ("bow", "equip-bow"),
            ("orb", "equip-wand"),
            ("wand", "equip-wand"),
            ("mace", "equip-mace"),
            ("spear", "equip-spear"),
            ("halberd", "equip-halberd"),
            ("shield", "equip-shield"),
            ("crossbow", "equip-crossbow"),
            ("tome", "equip-tome"),
        ]
        
        // Armor base types (heavy-specific keywords must come before generic ones)
        let armorMap: [(keyword: String, asset: String)] = [
            ("plate", "equip-plate"),
            ("chainmail", "equip-chainmail"),
            ("breastplate", "equip-breastplate"),
            ("robes", "equip-robes"),
            ("leather armor", "equip-leather-armor"),
            ("heavy helm", "equip-heavy-helm"),
            ("helm", "equip-helm"),
            ("heavy gauntlets", "equip-heavy-gauntlets"),
            ("gauntlets", "equip-gauntlets"),
            ("heavy boots", "equip-heavy-boots"),
            ("boots", "equip-boots"),
            ("greaves", "equip-boots"),
            ("sandals", "equip-boots"),
            ("pauldrons", "equip-pauldrons"),
        ]
        
        // Accessory base types (Rings, Amulets, Pendants, Earrings, Brooches, Talismans)
        let accessoryMap: [(keyword: String, asset: String)] = [
            ("ring", "equip-ring"),
            ("amulet", "equip-amulet"),
            ("pendant", "equip-pendant"),
            ("brooch", "equip-brooch"),
            ("earring", "equip-earring"),
            ("stud", "equip-earring"),
            ("talisman", "equip-talisman"),
        ]
        
        // Trinket base types (Belts, Charms, Bracelets)
        let trinketMap: [(keyword: String, asset: String)] = [
            ("charm", "equip-charm"),
            ("bracelet", "equip-bracelet"),
            ("belt", "equip-belt"),
        ]
        
        // Cloak base types
        let cloakMap: [(keyword: String, asset: String)] = [
            ("cloak", "equip-cloak"),
            ("cape", "equip-cape"),
            ("mantle", "equip-cloak"),
            ("shroud", "equip-cloak"),
        ]
        
        let maps: [[(keyword: String, asset: String)]]
        switch slot {
        case .weapon: maps = [weaponMap]
        case .armor: maps = [armorMap]
        case .accessory: maps = [accessoryMap]
        case .trinket: maps = [trinketMap]
        case .cloak: maps = [cloakMap]
        }
        
        for map in maps {
            for entry in map {
                if lowerName.contains(entry.keyword) {
                    return entry.asset
                }
            }
        }
        
        return nil
    }
    
    /// Whether this item has any affixes
    var hasAffixes: Bool {
        prefix != nil || suffix != nil
    }
    
    /// Number of affixes on this item (0-2)
    var affixCount: Int {
        (prefix != nil ? 1 : 0) + (suffix != nil ? 1 : 0)
    }
    
    /// Display name with affix decorations (e.g. "Blazing Steel Sword of Fortune")
    var displayName: String {
        var parts: [String] = []
        if let pfx = prefix { parts.append(pfx.name) }
        parts.append(name)
        if let sfx = suffix { parts.append(sfx.name) }
        return parts.joined(separator: " ")
    }
    
    /// Summary of all stat bonuses (includes enhancement)
    var statSummary: String {
        var primaryText = "+\(effectivePrimaryBonusDisplay) \(primaryStat.rawValue)"
        if enhancementLevel > 0 {
            primaryText += " [+\(enhancementLevel)]"
        }
        var parts = [primaryText]
        if let secondary = secondaryStat, secondaryStatBonus > 0 {
            parts.append("+\(secondaryStatBonusDisplay) \(secondary.rawValue)")
        }
        return parts.joined(separator: ", ")
    }
    
    /// Short affix summary for display on cards (e.g. "Blazing · of Fortune")
    var affixSummary: String? {
        let affixNames = [prefix?.name, suffix?.name].compactMap { $0 }
        guard !affixNames.isEmpty else { return nil }
        return affixNames.joined(separator: " · ")
    }
}

// MARK: - Supporting Types

/// Armor weight class — determines which classes can equip a piece
enum ArmorWeight: String, Codable, CaseIterable {
    case light = "Light"
    case heavy = "Heavy"
    case universal = "Universal"
    
    var label: String {
        switch self {
        case .light: return "Light Armor"
        case .heavy: return "Heavy Armor"
        case .universal: return ""
        }
    }
}

/// Equipment slot types (5 slots: Weapon, Armor, Accessory, Trinket, Cloak)
enum EquipmentSlot: String, Codable, CaseIterable {
    case weapon = "Weapon"
    case armor = "Armor"
    case accessory = "Accessory"
    case trinket = "Trinket"
    case cloak = "Cloak"
    
    var icon: String {
        switch self {
        case .weapon: return "wand.and.stars"
        case .armor: return "shield.fill"
        case .accessory: return "sparkle"
        case .trinket: return "tag.fill"
        case .cloak: return "wind"
        }
    }
}

/// Item rarity
enum ItemRarity: String, Codable, CaseIterable, Comparable {
    case common = "Common"
    case uncommon = "Uncommon"
    case rare = "Rare"
    case epic = "Epic"
    case legendary = "Legendary"
    
    private var sortOrder: Int {
        switch self {
        case .common: return 0
        case .uncommon: return 1
        case .rare: return 2
        case .epic: return 3
        case .legendary: return 4
        }
    }
    
    static func < (lhs: ItemRarity, rhs: ItemRarity) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
    
    var color: String {
        switch self {
        case .common: return "RarityCommon"
        case .uncommon: return "RarityUncommon"
        case .rare: return "RarityRare"
        case .epic: return "RarityEpic"
        case .legendary: return "RarityLegendary"
        }
    }
}

// MARK: - Legendary Rainbow Shimmer

/// Animated rainbow gradient for Legendary-rarity text.
/// Works as an overlay mask so existing font/size modifiers are preserved.
/// Usage: `Text("Legendary").legendaryShimmer()` or conditionally via the rarity helper.
struct LegendaryShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = 0
    
    private let rainbowColors: [Color] = [
        .red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink, .red
    ]
    
    func body(content: Content) -> some View {
        if isActive {
            content
                .hidden()
                .overlay(
                    LinearGradient(
                        colors: rainbowColors,
                        startPoint: UnitPoint(x: phase - 0.5, y: 0.5),
                        endPoint: UnitPoint(x: phase + 0.5, y: 0.5)
                    )
                    .mask(content)
                )
                .onAppear {
                    withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                        phase = 2.0
                    }
                }
        } else {
            content
        }
    }
}

extension View {
    /// Apply animated rainbow shimmer. Defaults to always active.
    func legendaryShimmer(isActive: Bool = true) -> some View {
        modifier(LegendaryShimmerModifier(isActive: isActive))
    }
    
    /// Apply legendary shimmer based on ItemRarity.
    func rarityShimmer(_ rarity: ItemRarity) -> some View {
        modifier(LegendaryShimmerModifier(isActive: rarity == .legendary))
    }
    
    /// Apply legendary shimmer based on MissionRarity.
    func rarityShimmer(_ rarity: MissionRarity) -> some View {
        modifier(LegendaryShimmerModifier(isActive: rarity == .legendary))
    }
}

// MARK: - Achievement Model

/// Achievements that players can unlock
@Model
final class Achievement {
    /// Unique identifier
    var id: UUID
    
    /// Achievement name
    var name: String
    
    /// Achievement description
    var achievementDescription: String
    
    /// Icon name
    var icon: String
    
    /// Is this achievement unlocked?
    var isUnlocked: Bool
    
    /// When was it unlocked?
    var unlockedAt: Date?
    
    /// Progress toward unlocking (0.0 - 1.0)
    var progress: Double
    
    /// Reward type
    var rewardType: AchievementRewardType
    
    /// Reward amount
    var rewardAmount: Int
    
    /// Tracking key to identify which metric this achievement tracks
    var trackingKey: String
    
    /// Target value needed to unlock (e.g., 100 tasks, level 50)
    var targetValue: Int
    
    /// Current tracked value (raw count, not progress percentage)
    var currentValue: Int
    
    init(
        name: String,
        description: String,
        icon: String,
        rewardType: AchievementRewardType,
        rewardAmount: Int,
        trackingKey: String = "",
        targetValue: Int = 1
    ) {
        self.id = UUID()
        self.name = name
        self.achievementDescription = description
        self.icon = icon
        self.isUnlocked = false
        self.unlockedAt = nil
        self.progress = 0.0
        self.rewardType = rewardType
        self.rewardAmount = rewardAmount
        self.trackingKey = trackingKey
        self.targetValue = targetValue
        self.currentValue = 0
    }
    
    /// Update progress based on current and target values
    func updateProgress(currentValue newValue: Int) {
        currentValue = newValue
        if targetValue > 0 {
            progress = min(1.0, Double(newValue) / Double(targetValue))
        }
        if newValue >= targetValue && !isUnlocked {
            unlock()
        }
    }
    
    /// Unlock the achievement
    func unlock() {
        isUnlocked = true
        unlockedAt = Date()
        progress = 1.0
    }
}

/// Achievement reward types
enum AchievementRewardType: String, Codable {
    case exp = "EXP"
    case gold = "Gold"
    case gems = "Gems"
    case title = "Title"
    case equipment = "Equipment"
}

