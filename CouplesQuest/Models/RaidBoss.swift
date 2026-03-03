import Foundation
import SwiftData

// MARK: - Raid Activity Type

enum RaidActivityType: String, Codable {
    case task
    case habit
    case dungeon
    case mission
    
    var displayName: String {
        switch self {
        case .task: return "Tasks"
        case .habit: return "Habits"
        case .dungeon: return "Dungeons"
        case .mission: return "Missions"
        }
    }
    
    var icon: String {
        switch self {
        case .task: return "checkmark.circle.fill"
        case .habit: return "arrow.trianglehead.2.clockwise.rotate.90"
        case .dungeon: return "shield.lefthalf.filled"
        case .mission: return "clock.fill"
        }
    }
    
    var color: String {
        switch self {
        case .task: return "AccentGold"
        case .habit: return "AccentGreen"
        case .dungeon: return "AccentPurple"
        case .mission: return "AccentPink"
        }
    }
}

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

// MARK: - Raid Boss Phase

enum RaidBossPhase: Int, Codable, CaseIterable {
    case easy = 1
    case medium = 2
    case hard = 3
    
    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }
    
    var hpMultiplier: Double {
        switch self {
        case .easy: return 1.0
        case .medium: return 1.5
        case .hard: return 2.5
        }
    }
    
    var retaliationMultiplier: Double {
        switch self {
        case .easy: return 0.05
        case .medium: return 0.10
        case .hard: return 0.18
        }
    }
    
    var phaseColor: String {
        switch self {
        case .easy: return "AccentGreen"
        case .medium: return "AccentGold"
        case .hard: return "AccentPink"
        }
    }
}

// MARK: - Raid Boss Loot Result

/// What a player receives when the raid boss leaves (defeated or expired), scaled by contribution
struct RaidBossLootResult {
    let baseGold: Int
    let baseExp: Int
    let bonusGold: Int
    let bonusExp: Int
    let bondExp: Int
    let equipmentDropped: Bool
    let uniqueCardID: String?
    let guaranteedConsumable: String?
    let highestPhaseReached: Int
    let contributionPercent: Double
    
    var totalGold: Int { baseGold + bonusGold }
    var totalExp: Int { baseExp + bonusExp }
}

// MARK: - Weekly Raid Boss

/// A weekly raid boss that the entire community chips away at together
@Model
final class WeeklyRaidBoss {
    /// Unique identifier
    var id: UUID
    
    /// Boss name
    var name: String
    
    /// Flavor description
    var bossDescription: String
    
    /// SF Symbol icon (legacy fallback)
    var icon: String
    
    /// Pixel art sprite asset name (e.g. "raidboss-dragon")
    var spriteImage: String
    
    /// Pixel art background asset name (e.g. "raidboss-bg-crystal")
    var backgroundImage: String
    
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
    
    /// Log of all attacks against this boss (local cache of recent attacks)
    var attackLog: [RaidAttack]
    
    /// Whether rewards have been claimed by this player
    var rewardsClaimed: Bool
    
    /// Boss template ID (from content_raids)
    var templateID: String?
    
    /// Boss modifier name
    var modifierName: String?
    
    /// Boss modifier description
    var modifierDescription: String?
    
    /// Party size factor used for HP scaling (stored at generation time)
    var partyScaleFactor: Double
    
    /// Supabase community boss ID for server sync
    var communityBossId: String?
    
    /// Number of unique players who have attacked this boss
    var totalParticipants: Int
    
    /// Whether the local player has opted into this week's raid
    var hasJoinedRaid: Bool
    
    /// Boss element type (e.g. "Fire", "Ice", "Shadow", "Earth")
    var element: String
    
    /// Stat the boss is weak to (e.g. "Wisdom", "Dexterity")
    var weakness: String
    
    /// Current phase (1 = Easy, 2 = Medium, 3 = Hard)
    var currentPhase: Int
    
    /// Max HP for the current phase
    var phaseMaxHP: Int
    
    /// Running total damage dealt across all phases (for contribution %)
    var totalDamageDealt: Int
    
    /// When the next boss will appear (set after this boss leaves)
    var nextBossDate: Date?
    
    /// Number of unique parties participating
    var totalParties: Int
    
    init(
        name: String,
        description: String,
        icon: String,
        spriteImage: String = "",
        backgroundImage: String = "",
        tier: Int,
        weekStartDate: Date,
        weekEndDate: Date,
        partyScaleFactor: Double = 1.0,
        templateID: String? = nil,
        modifierName: String? = nil,
        modifierDescription: String? = nil,
        baseHPPerTier: Int = 30000,
        element: String = "Fire",
        weakness: String = "Wisdom"
    ) {
        self.id = UUID()
        self.name = name
        self.bossDescription = description
        self.icon = icon
        self.spriteImage = spriteImage
        self.backgroundImage = backgroundImage
        self.tier = max(1, tier)
        
        let phase1HP = WeeklyRaidBoss.phaseHP(baseTier: max(1, tier), phase: 1)
        let totalHP = WeeklyRaidBoss.phaseHP(baseTier: max(1, tier), phase: 1)
                     + WeeklyRaidBoss.phaseHP(baseTier: max(1, tier), phase: 2)
                     + WeeklyRaidBoss.phaseHP(baseTier: max(1, tier), phase: 3)
        self.maxHP = totalHP
        self.currentHP = phase1HP
        self.phaseMaxHP = phase1HP
        self.currentPhase = 1
        self.totalDamageDealt = 0
        self.nextBossDate = nil
        self.totalParties = 0
        
        self.weekStartDate = weekStartDate
        self.weekEndDate = weekEndDate
        self.isDefeated = false
        self.attackLog = []
        self.rewardsClaimed = false
        self.templateID = templateID
        self.modifierName = modifierName
        self.modifierDescription = modifierDescription
        self.partyScaleFactor = partyScaleFactor
        self.communityBossId = nil
        self.totalParticipants = 0
        self.hasJoinedRaid = false
        self.element = element
        self.weakness = weakness
    }
    
    /// HP percentage remaining for the current phase (0.0 - 1.0)
    var hpPercentage: Double {
        guard phaseMaxHP > 0 else { return 0 }
        return Double(max(0, currentHP)) / Double(phaseMaxHP)
    }
    
    /// Overall HP percentage across all phases (0.0 - 1.0)
    var overallHPPercentage: Double {
        guard maxHP > 0 else { return 0 }
        var remaining = Double(max(0, currentHP))
        for phase in (currentPhase + 1)...3 {
            remaining += Double(WeeklyRaidBoss.phaseHP(baseTier: tier, phase: phase))
        }
        return remaining / Double(maxHP)
    }
    
    /// Whether all 3 phases have been beaten
    var isFullyDefeated: Bool {
        currentPhase == 3 && currentHP <= 0
    }
    
    /// Current phase as enum
    var phase: RaidBossPhase {
        RaidBossPhase(rawValue: currentPhase) ?? .easy
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
    
    /// Total damage dealt by a specific player across all phases
    func totalPlayerDamage(by playerID: UUID) -> Int {
        attackLog.filter { $0.playerID == playerID }.reduce(0) { $0 + $1.damage }
    }
    
    /// Damage breakdown by activity type for a specific player
    func damageByActivityType(for playerID: UUID) -> [RaidActivityType: Int] {
        var breakdown: [RaidActivityType: Int] = [:]
        for attack in attackLog where attack.playerID == playerID {
            let type = attack.activityType
            breakdown[type, default: 0] += attack.damage
        }
        return breakdown
    }
    
    /// Apply damage to the boss. Returns retaliation damage dealt to the player.
    @discardableResult
    func takeDamage(_ damage: Int, from attack: RaidAttack) -> Int {
        attackLog.append(attack)
        totalDamageDealt += damage
        currentHP = max(0, currentHP - damage)
        
        if currentHP <= 0 && currentPhase < 3 {
            currentPhase += 1
            let newPhaseHP = WeeklyRaidBoss.phaseHP(baseTier: tier, phase: currentPhase)
            phaseMaxHP = newPhaseHP
            currentHP = newPhaseHP
        } else if currentHP <= 0 {
            isDefeated = true
        }
        
        let phaseEnum = RaidBossPhase(rawValue: currentPhase) ?? .easy
        return max(1, Int(Double(damage) * phaseEnum.retaliationMultiplier))
    }
    
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
    
    // MARK: - Phase HP
    
    /// HP for a specific phase based on base tier
    static func phaseHP(baseTier: Int, phase: Int) -> Int {
        let baseHP = 30000 * max(1, baseTier)
        let multiplier: Double
        switch phase {
        case 1: multiplier = 1.0
        case 2: multiplier = 1.5
        case 3: multiplier = 2.5
        default: multiplier = 1.0
        }
        return Int(Double(baseHP) * multiplier)
    }
    
    // MARK: - Rewards
    
    /// EXP reward per tier on defeat
    static func expReward(tier: Int) -> Int { tier * 200 }
    
    /// Gold reward per tier on defeat
    static func goldReward(tier: Int) -> Int {
        let base = 150
        return base + tier * 50
    }
    
    /// Bond EXP reward per tier on defeat
    static func bondExpReward(tier: Int) -> Int { tier * 15 }
    
    /// Contribution-based loot calculation
    static func calculateLoot(
        tier: Int,
        highestPhase: Int,
        playerDamage: Int,
        totalDamage: Int,
        hasPartner: Bool,
        template: RaidBossTemplate? = nil
    ) -> RaidBossLootResult {
        let contribution = totalDamage > 0 ? Double(playerDamage) / Double(totalDamage) : 0
        
        let baseGold = 100 + tier * 30
        let baseExp = 150 + tier * 40
        
        let phaseBonus: Double
        switch highestPhase {
        case 3: phaseBonus = 2.5
        case 2: phaseBonus = 1.5
        default: phaseBonus = 1.0
        }
        
        let scaledGold = Int(Double(tier * 200) * contribution * phaseBonus)
        let scaledExp = Int(Double(tier * 300) * contribution * phaseBonus)
        let bondExp = hasPartner ? Int(Double(tier * 15) * max(0.5, contribution * 2.0)) : 0
        
        let equipChance = min(0.35, 0.10 + contribution * 0.5 + Double(highestPhase - 1) * 0.05)
        let equipDropped = Double.random(in: 0...1) <= equipChance
        
        let t = template
        
        return RaidBossLootResult(
            baseGold: baseGold,
            baseExp: baseExp,
            bonusGold: scaledGold,
            bonusExp: scaledExp,
            bondExp: bondExp,
            equipmentDropped: equipDropped,
            uniqueCardID: t?.uniqueCardID,
            guaranteedConsumable: t?.guaranteedConsumable,
            highestPhaseReached: highestPhase,
            contributionPercent: contribution
        )
    }
    
    // MARK: - Damage Formula
    
    /// Activity-scaled raid damage: harder activities deal more damage
    static func calculateActivityDamage(
        for character: PlayerCharacter,
        activityType: RaidActivityType,
        activityValue: Int
    ) -> Int {
        let levelBonus = character.level
        let base: Int
        switch activityType {
        case .task:
            base = 40 + activityValue / 2
        case .habit:
            base = 25 + activityValue * 3
        case .dungeon:
            base = 80 + activityValue * 15
        case .mission:
            base = 50 + activityValue / 3
        }
        return max(10, base + levelBonus)
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
    
    /// Community boss pool with pixel art sprites, themed backgrounds, elements, and weaknesses
    static let communityBossPool: [(name: String, description: String, icon: String, sprite: String, background: String, element: String, weakness: String)] = [
        ("Pyrax the World Burner", "A primordial beast of flame, scorching all in its path.", "flame.fill", "raidboss-beast", "raidboss-bg-volcano", "Fire", "Wisdom"),
        ("Ironclad Behemoth", "A massive construct of stone and fury, awakened from a forgotten war.", "gearshape.circle.fill", "raidboss-golem", "raidboss-bg-cave", "Earth", "Dexterity"),
        ("Frostweaver Empress", "An ancient dragon whose icy breath can freeze time itself.", "snowflake.circle", "raidboss-dragon", "raidboss-bg-crystal", "Ice", "Strength"),
        ("Gorrath the Undying", "A dark lich whose magic drains the life from all who oppose him.", "moon.circle.fill", "raidboss-lich", "raidboss-bg-cavern", "Shadow", "Charisma"),
    ]
    
    /// SF Symbol for a boss element
    static func elementIcon(for element: String) -> String {
        switch element.lowercased() {
        case "fire": return "flame.fill"
        case "ice": return "snowflake"
        case "earth": return "mountain.2.fill"
        case "shadow": return "moon.stars.fill"
        default: return "sparkles"
        }
    }
    
    /// Generate a new community raid boss from the boss pool
    static func generate(tier: Int, weekStart: Date, weekEnd: Date, partyMemberCount: Int = 1) -> WeeklyRaidBoss {
        let boss = communityBossPool[Int.random(in: 0..<communityBossPool.count)]
        let scaleFactor = partyScaleFactor(memberCount: partyMemberCount)
        
        return WeeklyRaidBoss(
            name: boss.name,
            description: boss.description,
            icon: boss.icon,
            spriteImage: boss.sprite,
            backgroundImage: boss.background,
            tier: tier,
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            partyScaleFactor: scaleFactor,
            element: boss.element,
            weakness: boss.weakness
        )
    }
    
    /// Get the start of the current 2-week raid window (Monday at 00:00)
    static func currentWeekStart() -> Date {
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        components.weekday = 2 // Monday
        return calendar.date(from: components) ?? now
    }
    
    /// Get the end of the current 2-week raid window (14 days after start, minus 1 second)
    static func currentWeekEnd() -> Date {
        let calendar = Calendar.current
        let weekStart = currentWeekStart()
        return calendar.date(byAdding: .day, value: 14, to: weekStart)?.addingTimeInterval(-1) ?? weekStart
    }
    
    /// Random respawn: next boss appears 1-3 days after departure
    static func nextBossAppearDate(after departureDate: Date) -> Date {
        let calendar = Calendar.current
        let randomDays = Int.random(in: 1...3)
        return calendar.date(byAdding: .day, value: randomDays, to: departureDate) ?? departureDate.addingTimeInterval(86400)
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
    var sourceType: String
    
    init(
        playerName: String,
        playerID: UUID,
        damage: Int,
        sourceDescription: String,
        sourceType: RaidActivityType = .task
    ) {
        self.id = UUID()
        self.playerName = playerName
        self.playerID = playerID
        self.damage = damage
        self.timestamp = Date()
        self.sourceDescription = sourceDescription
        self.sourceType = sourceType.rawValue
    }
    
    var activityType: RaidActivityType {
        RaidActivityType(rawValue: sourceType) ?? .task
    }
}

// MARK: - Community Raid Boss DTO

/// Supabase row for the global community raid boss
struct CommunityRaidBossDTO: Codable {
    let id: String
    let name: String
    let description: String
    let spriteImage: String
    let backgroundImage: String
    let tier: Int
    let maxHp: Int
    let currentHp: Int
    let weekStart: String
    let weekEnd: String
    let isDefeated: Bool
    let totalParticipants: Int
    let modifierName: String?
    let modifierDescription: String?
    let currentPhase: Int?
    let phaseMaxHp: Int?
    let totalDamageDealt: Int?
    let totalParties: Int?
    let nextBossDate: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, tier
        case spriteImage = "sprite_image"
        case backgroundImage = "background_image"
        case maxHp = "max_hp"
        case currentHp = "current_hp"
        case weekStart = "week_start"
        case weekEnd = "week_end"
        case isDefeated = "is_defeated"
        case totalParticipants = "total_participants"
        case modifierName = "modifier_name"
        case modifierDescription = "modifier_description"
        case currentPhase = "current_phase"
        case phaseMaxHp = "phase_max_hp"
        case totalDamageDealt = "total_damage_dealt"
        case totalParties = "total_parties"
        case nextBossDate = "next_boss_date"
    }
}

/// Supabase row for a community raid attack
struct CommunityRaidAttackDTO: Codable {
    let id: String?
    let bossId: String
    let userId: String
    let playerName: String
    let damage: Int
    let sourceDescription: String
    let partyId: String?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case bossId = "boss_id"
        case userId = "user_id"
        case playerName = "player_name"
        case damage
        case sourceDescription = "source_description"
        case partyId = "party_id"
        case createdAt = "created_at"
    }
}

/// Result returned by the atomic attack RPC
struct CommunityAttackResult: Codable {
    let newHp: Int
    let bossDefeated: Bool
    let currentPhase: Int
    let phaseMaxHp: Int
    let totalDamageDealt: Int
    
    enum CodingKeys: String, CodingKey {
        case newHp = "new_hp"
        case bossDefeated = "boss_defeated"
        case currentPhase = "current_phase"
        case phaseMaxHp = "phase_max_hp"
        case totalDamageDealt = "total_damage_dealt"
    }
}
