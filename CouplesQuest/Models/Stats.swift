import Foundation
import SwiftData

/// Core character stats that affect gameplay and AFK missions
@Model
final class Stats {
    /// Physical power - affects combat missions, physical task bonuses
    var strength: Int
    
    /// Mental acuity - affects research missions, mental task bonuses
    var wisdom: Int
    
    /// Kept for SwiftData migration compatibility — now merged into dexterity
    var endurance: Int
    
    /// Social skills - affects negotiation missions, social task bonuses
    var charisma: Int
    
    /// Agility, speed, and stamina — covers movement, cardio, and precision
    var dexterity: Int
    
    /// Fortune favors the bold - affects rare loot, critical successes
    var luck: Int
    
    init(
        strength: Int = 5,
        wisdom: Int = 5,
        endurance: Int = 0,
        charisma: Int = 5,
        dexterity: Int = 5,
        luck: Int = 5
    ) {
        self.strength = strength
        self.wisdom = wisdom
        self.endurance = endurance
        self.charisma = charisma
        self.dexterity = dexterity
        self.luck = luck
    }
    
    /// Total stat points (endurance no longer counted)
    var total: Int {
        strength + wisdom + charisma + dexterity + luck
    }
    
    /// Get stat value by type
    func value(for type: StatType) -> Int {
        switch type {
        case .strength: return strength
        case .wisdom: return wisdom
        case .endurance: return dexterity   // merged into dexterity
        case .charisma: return charisma
        case .dexterity: return dexterity
        case .luck: return luck
        }
    }
    
    /// Increase a stat by amount
    func increase(_ type: StatType, by amount: Int = 1) {
        switch type {
        case .strength: strength += amount
        case .wisdom: wisdom += amount
        case .endurance: dexterity += amount   // merged into dexterity
        case .charisma: charisma += amount
        case .dexterity: dexterity += amount
        case .luck: luck += amount
        }
    }
    
    /// Decrease a stat by amount (won't go below floor, default 1)
    func decrease(_ type: StatType, by amount: Int = 1, floor: Int = 1) {
        switch type {
        case .strength: strength = max(floor, strength - amount)
        case .wisdom: wisdom = max(floor, wisdom - amount)
        case .endurance: dexterity = max(floor, dexterity - amount)   // merged
        case .charisma: charisma = max(floor, charisma - amount)
        case .dexterity: dexterity = max(floor, dexterity - amount)
        case .luck: luck = max(floor, luck - amount)
        }
    }
}

/// Stat type enumeration for referencing stats dynamically.
/// `.endurance` is kept for data compatibility but redirects to dexterity.
enum StatType: String, Codable {
    case strength = "Strength"
    case wisdom = "Wisdom"
    case endurance = "Endurance"   // legacy — decodes to dexterity
    case charisma = "Charisma"
    case dexterity = "Dexterity"
    case luck = "Luck"
    
    /// Active stat cases (excludes legacy endurance)
    static var allCases: [StatType] {
        [.strength, .wisdom, .charisma, .dexterity, .luck]
    }
    
    /// Stats the player can allocate bonus points to during character creation (luck excluded)
    static var allocatable: [StatType] {
        [.strength, .wisdom, .charisma, .dexterity]
    }
    
    var icon: String {
        switch self {
        case .strength: return "figure.strengthtraining.traditional"
        case .wisdom: return "brain.head.profile"
        case .endurance: return "figure.run"      // legacy
        case .charisma: return "person.2.fill"
        case .dexterity: return "figure.run"
        case .luck: return "dice.fill"
        }
    }
    
    var color: String {
        switch self {
        case .strength: return "StatStrength"
        case .wisdom: return "StatWisdom"
        case .endurance: return "StatDexterity"   // legacy maps to dex color
        case .charisma: return "StatCharisma"
        case .dexterity: return "StatDexterity"
        case .luck: return "StatLuck"
        }
    }
    
    var description: String {
        switch self {
        case .strength: return "Raw power from lifting and gym work"
        case .wisdom: return "Knowledge gained from study and focus"
        case .endurance: return "Speed, agility, and stamina from cardio and movement"
        case .charisma: return "Social skill from partner activities"
        case .dexterity: return "Speed, agility, and stamina from cardio and movement"
        case .luck: return "Random fortune that boosts drops and gold"
        }
    }
}

