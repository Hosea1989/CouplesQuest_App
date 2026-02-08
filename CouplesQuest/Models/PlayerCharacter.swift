import Foundation
import SwiftData

/// The player's RPG character that levels up through completing real-life tasks
@Model
final class PlayerCharacter {
    /// Unique identifier
    var id: UUID
    
    /// Character name chosen by player
    var name: String
    
    /// Current level (1-100)
    var level: Int
    
    /// Current experience points
    var currentEXP: Int
    
    /// Character class (chosen at creation)
    var characterClass: CharacterClass?
    
    /// Zodiac sign (chosen at creation, grants +2 to a stat)
    var zodiacSign: ZodiacSign?
    
    /// Base stats
    @Relationship(deleteRule: .cascade)
    var stats: Stats
    
    /// Equipped items
    @Relationship(deleteRule: .cascade)
    var equipment: EquipmentLoadout
    
    /// Earned achievements
    @Relationship(deleteRule: .cascade)
    var achievements: [Achievement]
    
    /// Total tasks completed
    var tasksCompleted: Int
    
    /// Current daily streak
    var currentStreak: Int
    
    /// Longest streak achieved
    var longestStreak: Int
    
    /// In-game currency
    var gold: Int
    
    /// Premium currency (earned rarely)
    var gems: Int
    
    /// Date character was created
    var createdAt: Date
    
    /// Last activity date
    var lastActiveAt: Date
    
    /// Partner's character ID for syncing
    var partnerCharacterID: UUID?
    
    /// Cached partner name (for display without CloudKit)
    var partnerName: String?
    
    /// Cached partner level
    var partnerLevel: Int?
    
    /// Cached partner class (stored as raw string)
    var partnerClassName: String?
    
    /// Cached partner stat total (for co-op dungeon simulation)
    var partnerStatTotal: Int?
    
    /// Tasks completed today (resets daily)
    var tasksCompletedToday: Int
    
    /// Duty board tasks completed today (max 3, resets daily)
    var dutiesCompletedToday: Int
    
    /// Date of last daily reset
    var lastDailyReset: Date
    
    /// Unspent stat points available for allocation
    var unspentStatPoints: Int
    
    // unspentSkillPoints removed — skills are now Bond perks
    
    /// Avatar icon SF Symbol name
    var avatarIcon: String
    
    /// Avatar frame style name
    var avatarFrame: String
    
    /// Custom avatar photo data (JPEG). When set, displayed instead of the SF Symbol icon.
    @Attribute(.externalStorage) var avatarImageData: Data?
    
    // MARK: - Meditation
    
    /// Date of last meditation (for daily check)
    var lastMeditationDate: Date?
    
    /// Consecutive days of meditation
    var meditationStreak: Int
    
    // MARK: - Forge
    
    /// Forge shards earned from salvaging equipment
    var forgeShards: Int
    
    // MARK: - Arena
    
    /// Personal best arena wave reached
    var arenaBestWave: Int
    
    /// Number of arena attempts used today
    var arenaAttemptsToday: Int
    
    /// Date of last arena attempt (for daily reset)
    var lastArenaDate: Date?
    
    init(
        name: String,
        stats: Stats = Stats(),
        equipment: EquipmentLoadout = EquipmentLoadout()
    ) {
        self.id = UUID()
        self.name = name
        self.level = 1
        self.currentEXP = 0
        self.characterClass = nil
        self.zodiacSign = nil
        self.stats = stats
        self.equipment = equipment
        self.achievements = []
        self.tasksCompleted = 0
        self.currentStreak = 0
        self.longestStreak = 0
        self.gold = 0
        self.gems = 0
        self.createdAt = Date()
        self.lastActiveAt = Date()
        self.partnerCharacterID = nil
        self.partnerName = nil
        self.partnerLevel = nil
        self.partnerClassName = nil
        self.partnerStatTotal = nil
        self.tasksCompletedToday = 0
        self.dutiesCompletedToday = 0
        self.lastDailyReset = Date()
        self.unspentStatPoints = 0
        // unspentSkillPoints removed
        self.avatarIcon = "person.fill"
        self.avatarFrame = "default"
        self.avatarImageData = nil
        self.lastMeditationDate = nil
        self.meditationStreak = 0
        self.forgeShards = 0
        self.arenaBestWave = 0
        self.arenaAttemptsToday = 0
        self.lastArenaDate = nil
    }
    
    // MARK: - Meditation Helpers
    
    /// Whether the character has meditated today
    var hasMeditatedToday: Bool {
        guard let lastDate = lastMeditationDate else { return false }
        return Calendar.current.isDateInToday(lastDate)
    }
    
    /// Check and update meditation streak
    func checkMeditationStreak() {
        guard let lastDate = lastMeditationDate else { return }
        let calendar = Calendar.current
        let daysDiff = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastDate), to: calendar.startOfDay(for: Date())).day ?? 0
        if daysDiff > 1 {
            meditationStreak = 0
        }
    }
    
    /// Meditation EXP reward (with streak bonus)
    var meditationExpReward: Int {
        checkMeditationStreak()
        let base = level * 8
        let streakMultiplier = 1.0 + min(0.5, Double(meditationStreak) * 0.05)
        return Int(Double(base) * streakMultiplier)
    }
    
    /// Meditation gold reward
    var meditationGoldReward: Int {
        level * 3
    }
    
    // MARK: - Arena Helpers
    
    /// Check and reset daily arena attempts
    func checkArenaReset() {
        if let lastDate = lastArenaDate, !Calendar.current.isDateInToday(lastDate) {
            arenaAttemptsToday = 0
        }
    }
    
    /// Whether the player gets a free arena run today
    var hasFreeArenaAttempt: Bool {
        checkArenaReset()
        return arenaAttemptsToday == 0
    }
    
    // MARK: - Partner Helpers
    
    /// Partner's character class (resolved from cached string)
    var partnerClass: CharacterClass? {
        guard let className = partnerClassName else { return nil }
        return CharacterClass(rawValue: className)
    }
    
    /// Whether this character has a partner linked
    var hasPartner: Bool {
        partnerCharacterID != nil
    }
    
    /// Link with a partner using pairing data
    func linkPartner(data: PairingData) {
        guard let partnerUUID = UUID(uuidString: data.characterID) else { return }
        partnerCharacterID = partnerUUID
        partnerName = data.name
        partnerLevel = data.level
        partnerClassName = data.characterClass
    }
    
    /// Unlink partner
    func unlinkPartner() {
        partnerCharacterID = nil
        partnerName = nil
        partnerLevel = nil
        partnerClassName = nil
        partnerStatTotal = nil
    }
    
    /// Reset daily counter if needed
    func checkDailyReset() {
        let calendar = Calendar.current
        if !calendar.isDateInToday(lastDailyReset) {
            tasksCompletedToday = 0
            lastDailyReset = Date()
        }
    }
    
    // MARK: - Computed Properties
    
    /// EXP required to reach next level
    var expToNextLevel: Int {
        GameEngine.expRequired(forLevel: level + 1)
    }
    
    /// Progress to next level (0.0 - 1.0)
    var levelProgress: Double {
        let currentLevelExp = GameEngine.expRequired(forLevel: level)
        let nextLevelExp = GameEngine.expRequired(forLevel: level + 1)
        let expIntoLevel = currentEXP - currentLevelExp
        let expNeeded = nextLevelExp - currentLevelExp
        return Double(expIntoLevel) / Double(expNeeded)
    }
    
    /// Total stats including equipment bonuses and class passive
    var effectiveStats: Stats {
        let effective = Stats(
            strength: stats.strength,
            wisdom: stats.wisdom,
            charisma: stats.charisma,
            dexterity: stats.dexterity,
            luck: stats.luck
        )
        
        // Add equipment bonuses (primary + secondary)
        let equippedItems = [equipment.weapon, equipment.armor, equipment.accessory].compactMap { $0 }
        for item in equippedItems {
            effective.increase(item.primaryStat, by: item.statBonus)
            if let secondary = item.secondaryStat {
                effective.increase(secondary, by: item.secondaryStatBonus)
            }
        }
        
        // Class passive: +2 to primary stat
        if let charClass = characterClass {
            effective.increase(charClass.primaryStat, by: 2)
        }
        
        // Zodiac bonus: +2 to zodiac stat
        if let zodiac = zodiacSign {
            effective.increase(zodiac.boostedStat, by: 2)
        }
        
        return effective
    }
    
    /// Aggregate hero power score
    var heroPower: Int {
        let statPower = effectiveStats.total * 10
        let levelPower = level * 5
        
        let equipmentItems = [equipment.weapon, equipment.armor, equipment.accessory].compactMap { $0 }
        let equipPower = equipmentItems.reduce(0) { $0 + $1.totalStatBonus } * 8
        
        let achievementPower = achievements.filter { $0.isUnlocked }.count * 20
        
        return statPower + levelPower + equipPower + achievementPower
    }
    
    /// Title based on level
    var title: String {
        switch level {
        case 1...9: return "Novice"
        case 10...19: return "Apprentice"
        case 20...29: return "Journeyman"
        case 30...39: return "Adept"
        case 40...49: return "Expert"
        case 50...59: return "Master"
        case 60...69: return "Grandmaster"
        case 70...79: return "Legend"
        case 80...89: return "Mythic"
        case 90...99: return "Immortal"
        case 100: return "Transcendent"
        default: return "Unknown"
        }
    }
    
    // MARK: - Methods
    
    /// Add EXP and handle level ups
    @discardableResult
    func gainEXP(_ amount: Int) -> [LevelUpReward] {
        currentEXP += amount
        var rewards: [LevelUpReward] = []
        
        while currentEXP >= expToNextLevel && level < 100 {
            level += 1
            rewards.append(contentsOf: processLevelUp())
        }
        
        lastActiveAt = Date()
        return rewards
    }
    
    /// Process rewards for leveling up
    private func processLevelUp() -> [LevelUpReward] {
        var rewards: [LevelUpReward] = []
        
        // Stat point every level
        unspentStatPoints += 1
        rewards.append(.statPoint)
        
        // Gold bonus
        let goldReward = level * 10
        gold += goldReward
        rewards.append(.gold(goldReward))
        
        // Class evolution at level 20
        if level == 20 {
            rewards.append(.classEvolution)
        }
        
        return rewards
    }
}

// MARK: - Supporting Types

/// Class tier: starter (chosen at creation) or advanced (unlocked via evolution)
enum ClassTier: String, Codable {
    case starter
    case advanced
}

/// Character classes -- 3 starters chosen at creation, 6 advanced unlocked through evolution
enum CharacterClass: String, Codable, CaseIterable {
    // Starters
    case warrior = "Warrior"
    case mage = "Mage"
    case archer = "Archer"
    // Advanced (evolve from starters)
    case berserker = "Berserker"
    case paladin = "Paladin"
    case sorcerer = "Sorcerer"
    case enchanter = "Enchanter"
    case ranger = "Ranger"
    case trickster = "Trickster"
    
    /// Only the 3 starter classes for character creation
    static var starters: [CharacterClass] {
        [.warrior, .mage, .archer]
    }
    
    /// Only the 6 advanced classes
    static var advanced: [CharacterClass] {
        [.berserker, .paladin, .sorcerer, .enchanter, .ranger, .trickster]
    }
    
    var tier: ClassTier {
        switch self {
        case .warrior, .mage, .archer: return .starter
        default: return .advanced
        }
    }
    
    /// Which starter class this advanced class evolves from (nil for starters)
    var evolvesFrom: CharacterClass? {
        switch self {
        case .berserker, .paladin: return .warrior
        case .sorcerer, .enchanter: return .mage
        case .ranger, .trickster: return .archer
        default: return nil
        }
    }
    
    /// The two advanced classes a starter can evolve into
    var evolutionOptions: [CharacterClass] {
        switch self {
        case .warrior: return [.berserker, .paladin]
        case .mage: return [.sorcerer, .enchanter]
        case .archer: return [.ranger, .trickster]
        default: return []
        }
    }
    
    /// Stat required to meet evolution threshold
    var evolutionStat: StatType? {
        switch self {
        case .berserker: return .strength
        case .paladin: return .dexterity
        case .sorcerer: return .wisdom
        case .enchanter: return .charisma
        case .ranger: return .dexterity
        case .trickster: return .luck
        default: return nil
        }
    }
    
    /// Minimum stat value required for evolution
    var evolutionStatThreshold: Int { 15 }
    
    /// Minimum level required for evolution
    var evolutionLevelRequirement: Int { 20 }
    
    var description: String {
        switch self {
        // Starters
        case .warrior: return "A mighty frontline fighter. High strength and dexterity make them formidable in combat encounters."
        case .mage: return "A wielder of arcane knowledge. High wisdom and luck fuel devastating spells and critical strikes."
        case .archer: return "A swift and precise marksman. High dexterity and luck grant speed and deadly accuracy."
        // Advanced
        case .berserker: return "Unbridled fury incarnate. +40% power on Combat encounters."
        case .paladin: return "An unbreakable shield. Party takes 50% less damage in dungeons."
        case .sorcerer: return "Master of the arcane arts. +40% power on Puzzle encounters."
        case .enchanter: return "Weaver of support magic. +20% power to all party members."
        case .ranger: return "One with the wild. +15% Mission Duration Reduction and trap mastery."
        case .trickster: return "Fortune's favorite. +25% bonus loot from dungeons."
        }
    }
    
    var primaryStat: StatType {
        switch self {
        case .warrior, .berserker: return .strength
        case .mage, .sorcerer: return .wisdom
        case .archer, .ranger: return .dexterity
        case .paladin: return .dexterity
        case .enchanter: return .charisma
        case .trickster: return .luck
        }
    }
    
    var icon: String {
        switch self {
        case .warrior: return "shield.lefthalf.filled"
        case .mage: return "wand.and.stars"
        case .archer: return "arrow.up.right.circle.fill"
        case .berserker: return "bolt.circle.fill"
        case .paladin: return "shield.checkered"
        case .sorcerer: return "sparkles"
        case .enchanter: return "moon.stars.fill"
        case .ranger: return "leaf.fill"
        case .trickster: return "theatermasks.fill"
        }
    }
    
    /// Base stat spread for starter classes (total 30 points)
    var baseStats: Stats {
        switch self {
        case .warrior: return Stats(strength: 8, wisdom: 3, charisma: 3, dexterity: 10, luck: 4)
        case .mage:    return Stats(strength: 3, wisdom: 8, charisma: 5, dexterity: 7, luck: 7)
        case .archer:  return Stats(strength: 4, wisdom: 4, charisma: 3, dexterity: 12, luck: 7)
        default:       return Stats() // Advanced classes inherit from starter
        }
    }
    
    // MARK: - Dungeon Abilities
    
    var abilityName: String {
        switch self {
        case .warrior: return "Battle Fury"
        case .mage: return "Arcane Bolt"
        case .archer: return "Precision Shot"
        case .berserker: return "Rampage"
        case .paladin: return "Divine Shield"
        case .sorcerer: return "Arcane Mastery"
        case .enchanter: return "Rally Cry"
        case .ranger: return "Pathfinder"
        case .trickster: return "Fortune's Favor"
        }
    }
    
    var abilityDescription: String {
        switch self {
        case .warrior: return "+25% power on Combat encounters"
        case .mage: return "+25% power on Puzzle encounters"
        case .archer: return "+20% power on Trap encounters"
        case .berserker: return "+40% power on Combat encounters"
        case .paladin: return "Party takes 50% less damage from failed rooms"
        case .sorcerer: return "+40% power on Puzzle encounters"
        case .enchanter: return "+20% power to all party members"
        case .ranger: return "+30% power on Trap encounters, -15% mission duration"
        case .trickster: return "+25% loot drop chance in dungeons"
        }
    }
    
    var bonusEncounterType: EncounterType? {
        switch self {
        case .warrior, .berserker: return .combat
        case .mage, .sorcerer: return .puzzle
        case .archer, .ranger: return .trap
        default: return nil
        }
    }
    
    var encounterPowerMultiplier: Double {
        switch self {
        case .warrior: return 0.25
        case .mage: return 0.25
        case .archer: return 0.20
        case .berserker: return 0.40
        case .sorcerer: return 0.40
        case .ranger: return 0.30
        default: return 0.0
        }
    }
    
    var partyPowerMultiplier: Double {
        switch self {
        case .enchanter: return 0.20
        default: return 0.0
        }
    }
    
    var damageReductionMultiplier: Double {
        switch self {
        case .paladin: return 0.50
        default: return 0.0
        }
    }
    
    var lootDropBonus: Double {
        switch self {
        case .trickster: return 0.25
        default: return 0.0
        }
    }
}

// MARK: - Zodiac Sign

/// Zodiac signs that grant +2 to a specific stat
enum ZodiacSign: String, Codable, CaseIterable {
    case aries = "Aries"
    case taurus = "Taurus"
    case gemini = "Gemini"
    case cancer = "Cancer"
    case leo = "Leo"
    case virgo = "Virgo"
    case libra = "Libra"
    case scorpio = "Scorpio"
    case sagittarius = "Sagittarius"
    case capricorn = "Capricorn"
    case aquarius = "Aquarius"
    case pisces = "Pisces"
    
    var icon: String {
        switch self {
        case .aries: return "flame"
        case .taurus: return "leaf.circle.fill"
        case .gemini: return "person.2.fill"
        case .cancer: return "moon.fill"
        case .leo: return "sun.max.fill"
        case .virgo: return "sparkle"
        case .libra: return "scale.3d"
        case .scorpio: return "bolt.fill"
        case .sagittarius: return "arrow.up.right"
        case .capricorn: return "mountain.2.fill"
        case .aquarius: return "drop.fill"
        case .pisces: return "water.waves"
        }
    }
    
    var dateRange: String {
        switch self {
        case .aries: return "Mar 21 - Apr 19"
        case .taurus: return "Apr 20 - May 20"
        case .gemini: return "May 21 - Jun 20"
        case .cancer: return "Jun 21 - Jul 22"
        case .leo: return "Jul 23 - Aug 22"
        case .virgo: return "Aug 23 - Sep 22"
        case .libra: return "Sep 23 - Oct 22"
        case .scorpio: return "Oct 23 - Nov 21"
        case .sagittarius: return "Nov 22 - Dec 21"
        case .capricorn: return "Dec 22 - Jan 19"
        case .aquarius: return "Jan 20 - Feb 18"
        case .pisces: return "Feb 19 - Mar 20"
        }
    }
    
    /// The stat this zodiac sign boosts by +2
    var boostedStat: StatType {
        switch self {
        case .aries, .leo: return .strength
        case .taurus, .capricorn: return .dexterity
        case .gemini, .libra: return .charisma
        case .cancer, .scorpio, .aquarius: return .wisdom
        case .virgo: return .dexterity
        case .sagittarius, .pisces: return .luck
        }
    }
    
    var element: String {
        switch self {
        case .aries, .leo, .sagittarius: return "Fire"
        case .taurus, .virgo, .capricorn: return "Earth"
        case .gemini, .libra, .aquarius: return "Air"
        case .cancer, .scorpio, .pisces: return "Water"
        }
    }
}

/// Rewards given when leveling up
enum LevelUpReward: Equatable {
    case statPoint
    case gold(Int)
    case classEvolution
    case equipmentSlot
}

/// Equipment loadout container
@Model
final class EquipmentLoadout {
    @Relationship(deleteRule: .nullify)
    var weapon: Equipment?
    
    @Relationship(deleteRule: .nullify)
    var armor: Equipment?
    
    @Relationship(deleteRule: .nullify)
    var accessory: Equipment?
    
    init(weapon: Equipment? = nil, armor: Equipment? = nil, accessory: Equipment? = nil) {
        self.weapon = weapon
        self.armor = armor
        self.accessory = accessory
    }
}

