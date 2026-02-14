import Foundation
import SwiftData

// MARK: - Raid Boss Template

/// Server-driven raid boss template (loaded from content_raids via ContentManager)
struct RaidBossTemplate: Codable, Identifiable {
    var id: String
    var name: String
    var description: String
    var icon: String
    var theme: String
    var modifierName: String
    var modifierDescription: String
    var modifierStatPenalty: String?
    var modifierPenaltyValue: Double
    var modifierStatBonus: String?
    var modifierBonusValue: Double
    var baseHPPerTier: Int
    var goldRewardPerTier: Int
    var expRewardPerTier: Int
    var guaranteedConsumable: String?
    var equipDropChance: Double
    var uniqueCardID: String?
    
    /// Apply boss modifier to a damage value based on stat type
    func modifiedDamage(_ baseDamage: Int, statType: String?) -> Int {
        guard let stat = statType else { return baseDamage }
        var multiplier = 1.0
        if let penalty = modifierStatPenalty, penalty == stat {
            multiplier -= modifierPenaltyValue
        }
        if let bonus = modifierStatBonus, bonus == stat {
            multiplier += modifierBonusValue
        }
        return max(1, Int(Double(baseDamage) * multiplier))
    }
}

// MARK: - Raid Boss Loot Result

/// What a player receives on raid boss defeat
struct RaidBossLootResult {
    let gold: Int
    let exp: Int
    let bondExp: Int
    let guaranteedConsumable: String?
    let equipmentDropped: Bool
    let uniqueCardID: String?
}

// MARK: - Weekly Raid Boss

/// A weekly raid boss that party members chip away at by completing tasks
@Model
final class WeeklyRaidBoss {
    /// Unique identifier
    var id: UUID
    
    /// Boss name
    var name: String
    
    /// Flavor description
    var bossDescription: String
    
    /// SF Symbol icon
    var icon: String
    
    /// Boss tier (infinite: tier = ceil(avg party level / 10))
    var tier: Int
    
    /// Maximum hit points
    var maxHP: Int
    
    /// Current hit points remaining
    var currentHP: Int
    
    /// Start of the boss week (Monday)
    var weekStartDate: Date
    
    /// End of the boss week (Sunday 23:59)
    var weekEndDate: Date
    
    /// Whether the boss has been defeated
    var isDefeated: Bool
    
    /// Log of all attacks against this boss
    var attackLog: [RaidAttack]
    
    /// Whether rewards have been claimed
    var rewardsClaimed: Bool
    
    /// Boss template ID (from content_raids)
    var templateID: String?
    
    /// Boss modifier name
    var modifierName: String?
    
    /// Boss modifier description
    var modifierDescription: String?
    
    /// Party size factor used for HP scaling (stored at generation time)
    var partyScaleFactor: Double
    
    init(
        name: String,
        description: String,
        icon: String,
        tier: Int,
        weekStartDate: Date,
        weekEndDate: Date,
        partyScaleFactor: Double = 1.0,
        templateID: String? = nil,
        modifierName: String? = nil,
        modifierDescription: String? = nil,
        baseHPPerTier: Int = 3000
    ) {
        self.id = UUID()
        self.name = name
        self.bossDescription = description
        self.icon = icon
        self.tier = max(1, tier)
        // HP = base_hp × tier × party_factor
        let scaledHP = Int(Double(baseHPPerTier * max(1, tier)) * partyScaleFactor)
        self.maxHP = scaledHP
        self.currentHP = scaledHP
        self.weekStartDate = weekStartDate
        self.weekEndDate = weekEndDate
        self.isDefeated = false
        self.attackLog = []
        self.rewardsClaimed = false
        self.templateID = templateID
        self.modifierName = modifierName
        self.modifierDescription = modifierDescription
        self.partyScaleFactor = partyScaleFactor
    }
    
    /// HP percentage remaining (0.0 - 1.0)
    var hpPercentage: Double {
        guard maxHP > 0 else { return 0 }
        return Double(max(0, currentHP)) / Double(maxHP)
    }
    
    /// Whether this boss's week has expired
    var isExpired: Bool {
        Date() > weekEndDate
    }
    
    /// Whether the boss is still active (not defeated and not expired)
    var isActive: Bool {
        !isDefeated && !isExpired
    }
    
    /// Time remaining until the boss expires
    var timeRemaining: TimeInterval {
        max(0, weekEndDate.timeIntervalSince(Date()))
    }
    
    /// Total damage dealt by a specific player today
    func attacksToday(by playerID: UUID) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return attackLog.filter { attack in
            attack.playerID == playerID && calendar.isDate(attack.timestamp, inSameDayAs: today)
        }.count
    }
    
    /// Whether a player has reached their daily attack cap
    func hasReachedDailyCap(playerID: UUID) -> Bool {
        attacksToday(by: playerID) >= WeeklyRaidBoss.dailyAttackCap
    }
    
    /// Apply damage to the boss
    func takeDamage(_ damage: Int, from attack: RaidAttack) {
        attackLog.append(attack)
        currentHP = max(0, currentHP - damage)
        if currentHP <= 0 {
            isDefeated = true
        }
    }
    
    // MARK: - Constants
    
    /// Maximum attacks per player per day
    static let dailyAttackCap: Int = 5
    
    /// Party HP scaling factors (sublinear: solo=1x, 2=1.8x, 3=2.4x, 4=3.0x)
    static func partyScaleFactor(memberCount: Int) -> Double {
        switch max(1, memberCount) {
        case 1: return 1.0
        case 2: return 1.8
        case 3: return 2.4
        case 4: return 3.0
        default: return 3.0
        }
    }
    
    // MARK: - Rewards
    
    /// EXP reward per tier on defeat
    static func expReward(tier: Int) -> Int { tier * 200 }
    
    /// Gold reward per tier on defeat (scales: 200-500 by tier per design doc)
    static func goldReward(tier: Int) -> Int {
        let base = 150
        return base + tier * 50
    }
    
    /// Bond EXP reward per tier on defeat
    static func bondExpReward(tier: Int) -> Int { tier * 15 }
    
    /// Calculate loot for boss defeat using template
    static func lootResult(tier: Int, template: RaidBossTemplate?) -> RaidBossLootResult {
        let t = template ?? RaidBossTemplate(
            id: "default", name: "", description: "", icon: "",
            theme: "general", modifierName: "", modifierDescription: "",
            modifierPenaltyValue: 0, modifierBonusValue: 0,
            baseHPPerTier: 3000, goldRewardPerTier: 150,
            expRewardPerTier: 200, equipDropChance: 0.20
        )
        
        let gold = t.goldRewardPerTier * tier
        let exp = t.expRewardPerTier * tier
        let bondExp = tier * 15
        let equipDropped = Double.random(in: 0...1) <= t.equipDropChance
        
        return RaidBossLootResult(
            gold: gold,
            exp: exp,
            bondExp: bondExp,
            guaranteedConsumable: t.guaranteedConsumable,
            equipmentDropped: equipDropped,
            uniqueCardID: t.uniqueCardID
        )
    }
    
    // MARK: - Damage Formula
    
    /// Calculate raid attack damage from a character
    /// Formula: max(10, level * 2 + effectiveStats.total)
    static func calculateDamage(for character: PlayerCharacter) -> Int {
        let level = character.level
        let statTotal = character.effectiveStats.total
        return max(10, level * 2 + statTotal)
    }
    
    // MARK: - Boss Generation
    
    /// Generate a new weekly raid boss from a server template
    static func generateFromTemplate(
        _ template: RaidBossTemplate,
        tier: Int,
        weekStart: Date,
        weekEnd: Date,
        partyMemberCount: Int = 1
    ) -> WeeklyRaidBoss {
        let scaleFactor = partyScaleFactor(memberCount: partyMemberCount)
        
        return WeeklyRaidBoss(
            name: template.name,
            description: template.description,
            icon: template.icon,
            tier: tier,
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            partyScaleFactor: scaleFactor,
            templateID: template.id,
            modifierName: template.modifierName,
            modifierDescription: template.modifierDescription,
            baseHPPerTier: template.baseHPPerTier
        )
    }
    
    /// Generate a new weekly raid boss from the hardcoded fallback pool
    static func generate(tier: Int, weekStart: Date, weekEnd: Date, partyMemberCount: Int = 1) -> WeeklyRaidBoss {
        let bosses: [(name: String, description: String, icon: String)] = [
            ("Gorrath the Undying", "An ancient lich whose dark magic drains the life from all who oppose him.", "flame.circle.fill"),
            ("Vexara, Queen of Thorns", "A corrupted nature spirit whose venomous thorns spread across the land.", "leaf.circle.fill"),
            ("Ironclad Behemoth", "A massive construct of steel and fury, awakened from a forgotten war.", "gearshape.circle.fill"),
            ("Shadowmaw", "A draconic beast born from pure darkness, consuming light itself.", "moon.circle.fill"),
            ("The Crimson Herald", "A demonic commander who heralds the end of an age.", "bolt.circle.fill"),
            ("Frostweaver Empress", "An ice sorceress whose blizzards can freeze time itself.", "snowflake.circle"),
            ("Abyssal Titan", "A colossal entity from the deep, whose mere presence warps reality.", "tornado.circle.fill"),
            ("Pyrax the World Burner", "A primordial dragon of flame, scorching all in its path.", "flame.fill"),
        ]
        
        let boss = bosses[Int.random(in: 0..<bosses.count)]
        let scaleFactor = partyScaleFactor(memberCount: partyMemberCount)
        
        return WeeklyRaidBoss(
            name: boss.name,
            description: boss.description,
            icon: boss.icon,
            tier: tier,
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            partyScaleFactor: scaleFactor
        )
    }
    
    /// Get the start of the current week (Monday at 00:00)
    static func currentWeekStart() -> Date {
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        components.weekday = 2 // Monday
        return calendar.date(from: components) ?? now
    }
    
    /// Get the end of the current week (Sunday at 23:59:59)
    static func currentWeekEnd() -> Date {
        let calendar = Calendar.current
        let weekStart = currentWeekStart()
        return calendar.date(byAdding: .day, value: 7, to: weekStart)?.addingTimeInterval(-1) ?? weekStart
    }
    
    /// Calculate boss tier from average party level (infinite: tier = ceil(avgLevel / 10))
    static func tierForLevel(_ averageLevel: Int) -> Int {
        max(1, Int(ceil(Double(averageLevel) / 10.0)))
    }
}

// MARK: - Raid Attack

/// A single attack against a raid boss
struct RaidAttack: Codable, Identifiable {
    var id: UUID
    var playerName: String
    var playerID: UUID
    var damage: Int
    var timestamp: Date
    var sourceDescription: String
    
    init(
        playerName: String,
        playerID: UUID,
        damage: Int,
        sourceDescription: String
    ) {
        self.id = UUID()
        self.playerName = playerName
        self.playerID = playerID
        self.damage = damage
        self.timestamp = Date()
        self.sourceDescription = sourceDescription
    }
}
