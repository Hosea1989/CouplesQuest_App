import Foundation
import SwiftData

// MARK: - Equipment Affix Model

/// An affix (prefix or suffix) that can be applied to equipment to grant bonus effects.
/// Affixes make each drop unique — two Rare swords may have completely different affixes.
///
/// Reads affix definitions from ContentManager (`content_affixes` table).
/// Falls back to a built-in static pool if ContentManager hasn't loaded yet.
@Model
final class EquipmentAffix {
    /// Unique identifier
    var id: UUID
    
    /// Affix display name (e.g. "Blazing", "of Fortune")
    var name: String
    
    /// Whether this is a prefix or suffix
    var affixType: AffixType
    
    /// The type of bonus this affix grants (e.g. "exp_physical_percent", "dungeon_success_percent")
    var bonusType: String
    
    /// The rolled value of the bonus (within the affix's min-max range)
    var bonusValue: Double
    
    /// Human-readable effect description (e.g. "+5% EXP from physical tasks")
    var effectDescription: String
    
    /// The category of this affix (task-specific, idle bonus, economy, meta loot, combat, etc.)
    var category: String
    
    /// Whether this is a "Greater Affix" (1.5x power, only on Legendary)
    var isGreater: Bool
    
    /// Content affix ID for matching back to server definitions
    var contentAffixID: String?
    
    init(
        name: String,
        affixType: AffixType,
        bonusType: String,
        bonusValue: Double,
        effectDescription: String,
        category: String = "",
        isGreater: Bool = false,
        contentAffixID: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.affixType = affixType
        self.bonusType = bonusType
        self.bonusValue = bonusValue
        self.effectDescription = effectDescription
        self.category = category
        self.isGreater = isGreater
        self.contentAffixID = contentAffixID
    }
    
    /// Formatted display string (e.g. "+5.0% EXP from physical tasks")
    var displayText: String {
        let valueStr: String
        if bonusValue == bonusValue.rounded() {
            valueStr = String(format: "%.0f", bonusValue)
        } else {
            valueStr = String(format: "%.1f", bonusValue)
        }
        
        // Build prefix/suffix appropriate display
        if bonusType.contains("percent") || bonusType.contains("chance") || bonusType.contains("speed") {
            return "+\(valueStr)% \(effectDescription)"
        } else if bonusType.contains("flat") || bonusType.contains("defense") {
            return "+\(valueStr) \(effectDescription)"
        } else if bonusType.contains("duration") {
            return "-\(valueStr)% \(effectDescription)"
        } else {
            return "+\(valueStr) \(effectDescription)"
        }
    }
}

// MARK: - Affix Type

enum AffixType: String, Codable, CaseIterable {
    case prefix = "prefix"
    case suffix = "suffix"
}

// MARK: - Affix Roller

/// Handles rolling affixes for newly dropped equipment.
/// Reads from ContentManager when available, falls back to static pool.
struct AffixRoller {
    
    // MARK: - Roll Affixes for Equipment
    
    /// Roll prefix and suffix affixes for a piece of equipment based on its rarity.
    /// Returns (prefix, suffix) — either may be nil depending on rarity and RNG.
    ///
    /// - Parameters:
    ///   - rarity: The equipment's rarity (determines affix chances)
    ///   - characterClass: Optional class for +10% weight on matching stat affixes
    ///   - itemLevel: Level requirement of the item (scales affix values)
    static func rollAffixes(
        rarity: ItemRarity,
        characterClass: CharacterClass? = nil,
        itemLevel: Int = 1
    ) -> (prefix: EquipmentAffix?, suffix: EquipmentAffix?) {
        let prefixChance = prefixChance(for: rarity)
        let suffixChance = suffixChance(for: rarity)
        
        var rolledPrefix: EquipmentAffix? = nil
        var rolledSuffix: EquipmentAffix? = nil
        
        // Roll prefix
        if Double.random(in: 0...1) <= prefixChance {
            rolledPrefix = rollSingleAffix(
                type: .prefix,
                rarity: rarity,
                characterClass: characterClass,
                itemLevel: itemLevel
            )
        }
        
        // Roll suffix
        if Double.random(in: 0...1) <= suffixChance {
            rolledSuffix = rollSingleAffix(
                type: .suffix,
                rarity: rarity,
                characterClass: characterClass,
                itemLevel: itemLevel
            )
        }
        
        return (rolledPrefix, rolledSuffix)
    }
    
    // MARK: - Affix Chances by Rarity
    
    /// Prefix chance per equipment rarity (from GAME_DESIGN.md §8)
    static func prefixChance(for rarity: ItemRarity) -> Double {
        switch rarity {
        case .common:    return 0.0
        case .uncommon:  return 0.20
        case .rare:      return 0.50
        case .epic:      return 0.80
        case .legendary: return 1.00
        }
    }
    
    /// Suffix chance per equipment rarity (from GAME_DESIGN.md §8)
    static func suffixChance(for rarity: ItemRarity) -> Double {
        switch rarity {
        case .common:    return 0.0
        case .uncommon:  return 0.0
        case .rare:      return 0.30
        case .epic:      return 0.60
        case .legendary: return 0.80
        }
    }
    
    // MARK: - Single Affix Roll
    
    /// Roll a single affix of the given type.
    private static func rollSingleAffix(
        type: AffixType,
        rarity: ItemRarity,
        characterClass: CharacterClass?,
        itemLevel: Int
    ) -> EquipmentAffix {
        let pool = affixPool(for: type, characterClass: characterClass)
        let picked = pool.randomElement()!
        
        // Scale value based on item level and rarity
        let levelScale = 1.0 + (Double(itemLevel) * 0.02)
        let rarityScale = rarityValueScale(for: rarity)
        var value = Double.random(in: picked.minValue...picked.maxValue) * levelScale * rarityScale
        
        // Greater Affix chance on Legendary (10% chance, 1.5x power)
        var isGreater = false
        if rarity == .legendary && Double.random(in: 0...1) < 0.10 {
            value *= 1.5
            isGreater = true
        }
        
        // Round to 1 decimal place
        value = (value * 10).rounded() / 10
        
        return EquipmentAffix(
            name: picked.name,
            affixType: type,
            bonusType: picked.bonusType,
            bonusValue: value,
            effectDescription: picked.effectDescription,
            category: picked.category,
            isGreater: isGreater,
            contentAffixID: picked.id
        )
    }
    
    // MARK: - Affix Pool
    
    /// Get the affix pool for a given type, with class preference weighting.
    /// Tries ContentManager first, falls back to static pool.
    private static func affixPool(
        for type: AffixType,
        characterClass: CharacterClass?
    ) -> [AffixDefinition] {
        var pool = getAffixDefinitions(for: type)
        
        // Class affix preference: +10% weight for affixes matching the class's primary stat
        // Implemented by adding extra copies of matching affixes to the pool
        if let charClass = characterClass {
            let matchingStat = charClass.primaryStat
            let matchingAffixes = pool.filter { def in
                affixMatchesStat(def, stat: matchingStat)
            }
            // Add ~10% more copies of matching affixes (1 extra copy for every 10 in the pool)
            let extraCopies = max(1, pool.count / 10)
            for _ in 0..<extraCopies {
                pool.append(contentsOf: matchingAffixes)
            }
        }
        
        return pool
    }
    
    /// Check if an affix definition matches a stat type
    private static func affixMatchesStat(_ affix: AffixDefinition, stat: StatType) -> Bool {
        switch stat {
        case .strength:
            return affix.bonusType.contains("physical") || affix.bonusType.contains("strength")
        case .wisdom:
            return affix.bonusType.contains("mental") || affix.bonusType.contains("wisdom") || affix.bonusType.contains("mission_speed")
        case .dexterity:
            return affix.bonusType.contains("mission_duration") || affix.bonusType.contains("dexterity") || affix.bonusType.contains("haste")
        case .charisma:
            return affix.bonusType.contains("social") || affix.bonusType.contains("charisma") || affix.bonusType.contains("party_bond")
        case .luck:
            return affix.bonusType.contains("loot") || affix.bonusType.contains("luck") || affix.bonusType.contains("drop_chance") || affix.bonusType.contains("fortune")
        case .defense:
            return affix.bonusType.contains("defense") || affix.bonusType.contains("dungeon_success") || affix.bonusType.contains("warding")
        case .endurance:
            return false // legacy
        }
    }
    
    /// Get affix definitions, preferring ContentManager data
    private static func getAffixDefinitions(for type: AffixType) -> [AffixDefinition] {
        // Try ContentManager first (server-driven)
        if Thread.isMainThread {
            let cm = MainActor.assumeIsolated { ContentManager.shared }
            let isLoaded = MainActor.assumeIsolated { cm.isLoaded }
            if isLoaded {
                let serverAffixes = MainActor.assumeIsolated { cm.affixes }
                let filtered = serverAffixes.filter { $0.affixType == type.rawValue && $0.active }
                if !filtered.isEmpty {
                    return filtered.map { contentAffix in
                        AffixDefinition(
                            id: contentAffix.id,
                            name: contentAffix.name,
                            affixType: type,
                            bonusType: contentAffix.bonusType,
                            minValue: contentAffix.minValue,
                            maxValue: contentAffix.maxValue,
                            effectDescription: contentAffix.effectDescription,
                            category: contentAffix.category
                        )
                    }
                }
            }
        }
        
        // Fallback to static pool
        return type == .prefix ? staticPrefixPool : staticSuffixPool
    }
    
    // MARK: - Rarity Value Scaling
    
    private static func rarityValueScale(for rarity: ItemRarity) -> Double {
        switch rarity {
        case .common:    return 0.5
        case .uncommon:  return 0.75
        case .rare:      return 1.0
        case .epic:      return 1.25
        case .legendary: return 1.5
        }
    }
    
    // MARK: - Static Affix Pool (Fallback)
    
    /// Static prefix pool (from GAME_DESIGN.md §8 — Affix Pool table)
    static let staticPrefixPool: [AffixDefinition] = [
        AffixDefinition(id: "affix_blazing",      name: "Blazing",     affixType: .prefix, bonusType: "exp_physical_percent",  minValue: 3, maxValue: 10, effectDescription: "EXP from physical tasks",  category: "task-specific"),
        AffixDefinition(id: "affix_scholarly",     name: "Scholarly",   affixType: .prefix, bonusType: "exp_mental_percent",    minValue: 3, maxValue: 10, effectDescription: "EXP from mental tasks",    category: "task-specific"),
        AffixDefinition(id: "affix_social",        name: "Social",      affixType: .prefix, bonusType: "exp_social_percent",    minValue: 3, maxValue: 10, effectDescription: "EXP from social tasks",    category: "task-specific"),
        AffixDefinition(id: "affix_industrious",   name: "Industrious", affixType: .prefix, bonusType: "exp_household_percent", minValue: 3, maxValue: 10, effectDescription: "EXP from household tasks", category: "task-specific"),
        AffixDefinition(id: "affix_mindful",       name: "Mindful",     affixType: .prefix, bonusType: "exp_wellness_percent",  minValue: 3, maxValue: 10, effectDescription: "EXP from wellness tasks",  category: "task-specific"),
        AffixDefinition(id: "affix_inspired",      name: "Inspired",    affixType: .prefix, bonusType: "exp_creative_percent",  minValue: 3, maxValue: 10, effectDescription: "EXP from creative tasks",  category: "task-specific"),
        AffixDefinition(id: "affix_swift",         name: "Swift",       affixType: .prefix, bonusType: "mission_duration_reduction", minValue: 3, maxValue: 8, effectDescription: "AFK mission duration", category: "idle-bonus"),
        AffixDefinition(id: "affix_prosperous",    name: "Prosperous",  affixType: .prefix, bonusType: "gold_percent",          minValue: 3, maxValue: 8,  effectDescription: "Gold from all sources",    category: "economy"),
        AffixDefinition(id: "affix_lucky",         name: "Lucky",       affixType: .prefix, bonusType: "rare_drop_chance",      minValue: 2, maxValue: 6,  effectDescription: "rare drop chance",         category: "meta-loot"),
        AffixDefinition(id: "affix_resilient",     name: "Resilient",   affixType: .prefix, bonusType: "streak_shield_chance",  minValue: 3, maxValue: 8,  effectDescription: "streak shield chance",     category: "protection"),
    ]
    
    /// Static suffix pool (from GAME_DESIGN.md §8 — Affix Pool table)
    static let staticSuffixPool: [AffixDefinition] = [
        AffixDefinition(id: "affix_vigilant",       name: "Vigilant",          affixType: .suffix, bonusType: "dungeon_success_percent",    minValue: 3, maxValue: 8,  effectDescription: "dungeon success chance",  category: "combat"),
        AffixDefinition(id: "affix_of_fortune",     name: "of Fortune",        affixType: .suffix, bonusType: "loot_drop_chance_percent",   minValue: 2, maxValue: 6,  effectDescription: "loot drop chance",        category: "meta-loot"),
        AffixDefinition(id: "affix_of_scholar",     name: "of the Scholar",    affixType: .suffix, bonusType: "mission_speed_percent",      minValue: 3, maxValue: 8,  effectDescription: "mission speed",           category: "idle-bonus"),
        AffixDefinition(id: "affix_of_devotion",    name: "of Devotion",       affixType: .suffix, bonusType: "party_bond_exp_percent",     minValue: 3, maxValue: 8,  effectDescription: "party bond EXP",          category: "social"),
        AffixDefinition(id: "affix_of_persistence", name: "of Persistence",    affixType: .suffix, bonusType: "habit_streak_bonus_percent", minValue: 3, maxValue: 8,  effectDescription: "habit streak bonus",      category: "habit"),
        AffixDefinition(id: "affix_of_pathfinder",  name: "of the Pathfinder", affixType: .suffix, bonusType: "expedition_reward_percent",  minValue: 3, maxValue: 8,  effectDescription: "expedition rewards",      category: "expedition"),
        AffixDefinition(id: "affix_of_warding",     name: "of Warding",        affixType: .suffix, bonusType: "defense_flat",               minValue: 2, maxValue: 6,  effectDescription: "defense in dungeons",     category: "combat"),
        AffixDefinition(id: "affix_of_haste",       name: "of Haste",          affixType: .suffix, bonusType: "dungeon_room_time_reduction", minValue: 3, maxValue: 8, effectDescription: "dungeon room time",       category: "combat"),
    ]
}

// MARK: - Affix Definition (Template)

/// A template definition for an affix — describes what an affix CAN be.
/// Not persisted. Used for rolling new affixes from the pool.
struct AffixDefinition: Identifiable {
    let id: String
    let name: String
    let affixType: AffixType
    let bonusType: String
    let minValue: Double
    let maxValue: Double
    let effectDescription: String
    let category: String
}
