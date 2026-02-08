import Foundation
import SwiftData

// MARK: - Weekly Raid Boss

/// A weekly raid boss that partners chip away at by completing tasks
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
    
    /// Boss tier (1-5), scales with average partner level
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
    
    init(
        name: String,
        description: String,
        icon: String,
        tier: Int,
        weekStartDate: Date,
        weekEndDate: Date
    ) {
        self.id = UUID()
        self.name = name
        self.bossDescription = description
        self.icon = icon
        let clampedTier = max(1, min(5, tier))
        self.tier = clampedTier
        self.maxHP = 3000 * clampedTier
        self.currentHP = 3000 * clampedTier
        self.weekStartDate = weekStartDate
        self.weekEndDate = weekEndDate
        self.isDefeated = false
        self.attackLog = []
        self.rewardsClaimed = false
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
    
    /// EXP reward per tier on defeat
    static func expReward(tier: Int) -> Int { tier * 200 }
    
    /// Gold reward per tier on defeat
    static func goldReward(tier: Int) -> Int { tier * 150 }
    
    /// Bond EXP reward per tier on defeat
    static func bondExpReward(tier: Int) -> Int { tier * 15 }
    
    // MARK: - Damage Formula
    
    /// Calculate raid attack damage from a character
    /// Formula: max(10, level * 2 + effectiveStats.total)
    static func calculateDamage(for character: PlayerCharacter) -> Int {
        let level = character.level
        let statTotal = character.effectiveStats.total
        return max(10, level * 2 + statTotal)
    }
    
    // MARK: - Boss Generation
    
    /// Generate a new weekly raid boss for the given tier
    static func generate(tier: Int, weekStart: Date, weekEnd: Date) -> WeeklyRaidBoss {
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
        
        return WeeklyRaidBoss(
            name: boss.name,
            description: boss.description,
            icon: boss.icon,
            tier: tier,
            weekStartDate: weekStart,
            weekEndDate: weekEnd
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
    
    /// Calculate boss tier from partner levels
    static func tierForLevel(_ averageLevel: Int) -> Int {
        max(1, min(5, averageLevel / 10))
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
