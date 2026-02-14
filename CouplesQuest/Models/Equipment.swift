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
    
    /// Amount of stat bonus
    var statBonus: Int
    
    /// Level required to equip
    var levelRequirement: Int
    
    /// Secondary stat this item boosts (optional)
    var secondaryStat: StatType?
    
    /// Amount of secondary stat bonus
    var secondaryStatBonus: Int
    
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
    
    // MARK: - Affixes
    
    /// Prefix affix (e.g. "Blazing" — +X% EXP from physical tasks)
    @Relationship(deleteRule: .cascade)
    var prefix: EquipmentAffix?
    
    /// Suffix affix (e.g. "of Fortune" — +X% loot drop chance)
    @Relationship(deleteRule: .cascade)
    var suffix: EquipmentAffix?
    
    /// Maximum enhancement level
    static let maxEnhancementLevel = 10
    
    init(
        name: String,
        description: String,
        slot: EquipmentSlot,
        rarity: ItemRarity,
        primaryStat: StatType,
        statBonus: Int,
        levelRequirement: Int = 1,
        secondaryStat: StatType? = nil,
        secondaryStatBonus: Int = 0,
        ownerID: UUID? = nil
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
        self.prefix = nil
        self.suffix = nil
    }
    
    /// Primary stat bonus including enhancements
    var effectivePrimaryBonus: Int {
        statBonus + enhancementLevel
    }
    
    /// Total stat bonus (primary + enhancement + secondary)
    var totalStatBonus: Int {
        effectivePrimaryBonus + secondaryStatBonus
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
        let lowerName = name.lowercased()
        
        // Weapon base types
        let weaponMap: [(keyword: String, asset: String)] = [
            ("sword", "equip-sword"),
            ("axe", "equip-axe"),
            ("staff", "equip-staff"),
            ("dagger", "equip-dagger"),
            ("bow", "equip-bow"),
            ("wand", "equip-wand"),
            ("mace", "equip-mace"),
            ("spear", "equip-spear"),
            ("shield", "equip-shield"),
            ("crossbow", "equip-crossbow"),
            ("tome", "equip-tome"),
            ("halberd", "equip-halberd"),
        ]
        
        // Armor base types
        let armorMap: [(keyword: String, asset: String)] = [
            ("plate", "equip-plate"),
            ("chainmail", "equip-chainmail"),
            ("robes", "equip-robes"),
            ("leather armor", "equip-leather-armor"),
            ("breastplate", "equip-breastplate"),
            ("helm", "equip-helm"),
            ("gauntlets", "equip-gauntlets"),
            ("boots", "equip-boots"),
            ("greaves", "equip-boots"),
            ("sandals", "equip-boots"),
            ("pauldrons", "equip-pauldrons"),
            ("cape", "equip-cape"),
            ("mantle", "equip-cape"),
        ]
        
        // Accessory base types (Rings, Amulets, Pendants, Earrings, Brooches, Talismans)
        let accessoryMap: [(keyword: String, asset: String)] = [
            ("ring", "equip-ring"),
            ("amulet", "equip-amulet"),
            ("pendant", "equip-pendant"),
            ("earring", "equip-earring"),
            ("stud", "equip-earring"),
            ("brooch", "equip-brooch"),
            ("talisman", "equip-talisman"),
        ]
        
        // Trinket base types (Cloaks, Belts, Charms, Bracelets — moved from Accessory)
        let trinketMap: [(keyword: String, asset: String)] = [
            ("cloak", "equip-cloak"),
            ("bracelet", "equip-bracelet"),
            ("charm", "equip-charm"),
            ("belt", "equip-belt"),
        ]
        
        let maps: [[(keyword: String, asset: String)]]
        switch slot {
        case .weapon: maps = [weaponMap]
        case .armor: maps = [armorMap]
        case .accessory: maps = [accessoryMap]
        case .trinket: maps = [trinketMap]
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
        var primaryText = "+\(effectivePrimaryBonus) \(primaryStat.rawValue)"
        if enhancementLevel > 0 {
            primaryText += " [+\(enhancementLevel)]"
        }
        var parts = [primaryText]
        if let secondary = secondaryStat, secondaryStatBonus > 0 {
            parts.append("+\(secondaryStatBonus) \(secondary.rawValue)")
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

/// Equipment slot types (4 slots: Weapon, Armor, Accessory, Trinket)
enum EquipmentSlot: String, Codable, CaseIterable {
    case weapon = "Weapon"
    case armor = "Armor"
    case accessory = "Accessory"
    case trinket = "Trinket"
    
    var icon: String {
        switch self {
        case .weapon: return "wand.and.stars"
        case .armor: return "shield.fill"
        case .accessory: return "sparkle"
        case .trinket: return "tag.fill"
        }
    }
}

/// Item rarity
enum ItemRarity: String, Codable, CaseIterable {
    case common = "Common"
    case uncommon = "Uncommon"
    case rare = "Rare"
    case epic = "Epic"
    case legendary = "Legendary"
    
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

