import Foundation

/// Static catalog of all achievements organized by category
struct AchievementDefinitions {
    
    /// Achievement tracking key used to identify achievement type for progress updates
    enum AchievementKey: String {
        // Task Milestones
        case firstSteps = "first_steps"
        case dedicated = "dedicated"
        case centurion = "centurion"
        case legendaryWorker = "legendary_worker"
        
        // Streak Milestones
        case consistent = "consistent"
        case monthlyMaster = "monthly_master"
        case unstoppable = "unstoppable"
        
        // Level Milestones
        case apprentice = "apprentice"
        case journeyman = "journeyman"
        case master = "master"
        case transcendent = "transcendent"
        
        // Dungeon Milestones
        case dungeonDelver = "dungeon_delver"
        case dungeonMaster = "dungeon_master"
        
        // Couples Milestones
        case betterTogether = "better_together"
        case powerCouple = "power_couple"
        
        // Collector Milestones
        case rareFind = "rare_find"
        case legendaryCollector = "legendary_collector"
        
        // Class Milestones
        case specialized = "specialized"
        case skillMaster = "skill_master"
    }
    
    /// All achievement definitions
    static func allAchievements() -> [Achievement] {
        var achievements: [Achievement] = []
        
        // MARK: - Task Milestones
        achievements.append(contentsOf: [
            Achievement(
                name: "First Steps",
                description: "Complete your first task",
                icon: "figure.walk",
                rewardType: .exp,
                rewardAmount: 50,
                trackingKey: AchievementKey.firstSteps.rawValue,
                targetValue: 1
            ),
            Achievement(
                name: "Dedicated",
                description: "Complete 50 tasks",
                icon: "checkmark.seal.fill",
                rewardType: .gold,
                rewardAmount: 500,
                trackingKey: AchievementKey.dedicated.rawValue,
                targetValue: 50
            ),
            Achievement(
                name: "Centurion",
                description: "Complete 100 tasks",
                icon: "star.circle.fill",
                rewardType: .gems,
                rewardAmount: 5,
                trackingKey: AchievementKey.centurion.rawValue,
                targetValue: 100
            ),
            Achievement(
                name: "Legendary Worker",
                description: "Complete 500 tasks",
                icon: "crown.fill",
                rewardType: .gems,
                rewardAmount: 20,
                trackingKey: AchievementKey.legendaryWorker.rawValue,
                targetValue: 500
            )
        ])
        
        // MARK: - Streak Milestones
        achievements.append(contentsOf: [
            Achievement(
                name: "Consistent",
                description: "Maintain a 7-day streak",
                icon: "flame.fill",
                rewardType: .exp,
                rewardAmount: 200,
                trackingKey: AchievementKey.consistent.rawValue,
                targetValue: 7
            ),
            Achievement(
                name: "Monthly Master",
                description: "Maintain a 30-day streak",
                icon: "flame.circle.fill",
                rewardType: .gems,
                rewardAmount: 3,
                trackingKey: AchievementKey.monthlyMaster.rawValue,
                targetValue: 30
            ),
            Achievement(
                name: "Unstoppable",
                description: "Maintain a 100-day streak",
                icon: "bolt.shield.fill",
                rewardType: .gems,
                rewardAmount: 15,
                trackingKey: AchievementKey.unstoppable.rawValue,
                targetValue: 100
            )
        ])
        
        // MARK: - Level Milestones
        achievements.append(contentsOf: [
            Achievement(
                name: "Apprentice",
                description: "Reach Level 10",
                icon: "graduationcap.fill",
                rewardType: .gold,
                rewardAmount: 200,
                trackingKey: AchievementKey.apprentice.rawValue,
                targetValue: 10
            ),
            Achievement(
                name: "Journeyman",
                description: "Reach Level 25",
                icon: "map.fill",
                rewardType: .gold,
                rewardAmount: 500,
                trackingKey: AchievementKey.journeyman.rawValue,
                targetValue: 25
            ),
            Achievement(
                name: "Master",
                description: "Reach Level 50",
                icon: "rosette",
                rewardType: .gems,
                rewardAmount: 10,
                trackingKey: AchievementKey.master.rawValue,
                targetValue: 50
            ),
            Achievement(
                name: "Transcendent",
                description: "Reach Level 100",
                icon: "sparkles",
                rewardType: .gems,
                rewardAmount: 50,
                trackingKey: AchievementKey.transcendent.rawValue,
                targetValue: 100
            )
        ])
        
        // MARK: - Dungeon Milestones
        achievements.append(contentsOf: [
            Achievement(
                name: "Dungeon Delver",
                description: "Complete your first dungeon",
                icon: "shield.lefthalf.filled",
                rewardType: .exp,
                rewardAmount: 150,
                trackingKey: AchievementKey.dungeonDelver.rawValue,
                targetValue: 1
            ),
            Achievement(
                name: "Dungeon Master",
                description: "Complete 10 dungeons",
                icon: "shield.checkered",
                rewardType: .gems,
                rewardAmount: 5,
                trackingKey: AchievementKey.dungeonMaster.rawValue,
                targetValue: 10
            )
        ])
        
        // MARK: - Couples Milestones
        achievements.append(contentsOf: [
            Achievement(
                name: "Better Together",
                description: "Link with your partner",
                icon: "heart.fill",
                rewardType: .exp,
                rewardAmount: 100,
                trackingKey: AchievementKey.betterTogether.rawValue,
                targetValue: 1
            ),
            Achievement(
                name: "Power Couple",
                description: "Complete 10 partner tasks",
                icon: "heart.circle.fill",
                rewardType: .gems,
                rewardAmount: 5,
                trackingKey: AchievementKey.powerCouple.rawValue,
                targetValue: 10
            )
        ])
        
        // MARK: - Collector Milestones
        achievements.append(contentsOf: [
            Achievement(
                name: "Rare Find",
                description: "Obtain a Rare or better item",
                icon: "sparkle",
                rewardType: .gold,
                rewardAmount: 300,
                trackingKey: AchievementKey.rareFind.rawValue,
                targetValue: 1
            ),
            Achievement(
                name: "Legendary Collector",
                description: "Obtain a Legendary item",
                icon: "diamond.fill",
                rewardType: .gems,
                rewardAmount: 10,
                trackingKey: AchievementKey.legendaryCollector.rawValue,
                targetValue: 1
            )
        ])
        
        // MARK: - Class Milestones
        achievements.append(contentsOf: [
            Achievement(
                name: "Specialized",
                description: "Choose your character class",
                icon: "person.crop.circle.badge.checkmark",
                rewardType: .exp,
                rewardAmount: 100,
                trackingKey: AchievementKey.specialized.rawValue,
                targetValue: 1
            ),
            Achievement(
                name: "Skill Master",
                description: "Max out a Tier 3 capstone skill",
                icon: "trophy.fill",
                rewardType: .gems,
                rewardAmount: 15,
                trackingKey: AchievementKey.skillMaster.rawValue,
                targetValue: 1
            )
        ])
        
        return achievements
    }
}
