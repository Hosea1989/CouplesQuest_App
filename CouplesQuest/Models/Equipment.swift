import Foundation
import SwiftData

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
    }
    
    /// Total stat bonus (primary + secondary)
    var totalStatBonus: Int {
        statBonus + secondaryStatBonus
    }
    
    /// Maps this equipment's base type to an image asset name in Equipment.xcassets.
    /// Falls back to nil if no matching image exists.
    var imageName: String? {
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
        ]
        
        // Accessory base types
        let accessoryMap: [(keyword: String, asset: String)] = [
            ("ring", "equip-ring"),
            ("amulet", "equip-amulet"),
            ("cloak", "equip-cloak"),
            ("bracelet", "equip-bracelet"),
            ("charm", "equip-charm"),
            ("pendant", "equip-pendant"),
            ("belt", "equip-belt"),
        ]
        
        let maps: [[(keyword: String, asset: String)]]
        switch slot {
        case .weapon: maps = [weaponMap]
        case .armor: maps = [armorMap]
        case .accessory: maps = [accessoryMap]
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
    
    /// Summary of all stat bonuses
    var statSummary: String {
        var parts = ["+\(statBonus) \(primaryStat.rawValue)"]
        if let secondary = secondaryStat, secondaryStatBonus > 0 {
            parts.append("+\(secondaryStatBonus) \(secondary.rawValue)")
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Supporting Types

/// Equipment slot types
enum EquipmentSlot: String, Codable, CaseIterable {
    case weapon = "Weapon"
    case armor = "Armor"
    case accessory = "Accessory"
    
    var icon: String {
        switch self {
        case .weapon: return "wand.and.stars"
        case .armor: return "shield.fill"
        case .accessory: return "sparkle"
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

