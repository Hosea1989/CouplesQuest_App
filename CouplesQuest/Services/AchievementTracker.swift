import Foundation

/// Service that checks and updates achievement progress based on character state
struct AchievementTracker {
    
    /// Initialize achievements for a new character
    static func initializeAchievements(for character: PlayerCharacter) {
        guard character.achievements.isEmpty else { return }
        character.achievements = AchievementDefinitions.allAchievements()
    }
    
    /// Check all achievements and update progress based on current character state
    static func checkAll(character: PlayerCharacter) {
        for achievement in character.achievements where !achievement.isUnlocked {
            let currentValue = getCurrentValue(
                for: achievement.trackingKey,
                character: character
            )
            achievement.updateProgress(currentValue: currentValue)
        }
    }
    
    /// Get the current value for a tracking key based on character state
    private static func getCurrentValue(for trackingKey: String, character: PlayerCharacter) -> Int {
        guard let key = AchievementDefinitions.AchievementKey(rawValue: trackingKey) else { return 0 }
        
        switch key {
        // Task Milestones
        case .firstSteps, .dedicated, .centurion, .legendaryWorker:
            return character.tasksCompleted
            
        // Streak Milestones
        case .consistent, .monthlyMaster, .unstoppable:
            return character.longestStreak
            
        // Level Milestones
        case .apprentice, .journeyman, .master, .transcendent:
            return character.level
            
        // Dungeon Milestones
        case .dungeonDelver, .dungeonMaster:
            // Track via a separate counter if available; for now use achievements already unlocked
            return character.achievements
                .first(where: { $0.trackingKey == trackingKey })?.currentValue ?? 0
            
        // Couples Milestones
        case .betterTogether:
            return character.partnerCharacterID != nil ? 1 : 0
            
        case .powerCouple:
            // Track via existing counter on the achievement
            return character.achievements
                .first(where: { $0.trackingKey == trackingKey })?.currentValue ?? 0
            
        // Collector Milestones
        case .rareFind, .legendaryCollector:
            return character.achievements
                .first(where: { $0.trackingKey == trackingKey })?.currentValue ?? 0
            
        // Class Milestones
        case .specialized:
            return character.characterClass != nil ? 1 : 0
            
        case .skillMaster:
            // Skills have been migrated to Bond perks — this achievement is retired
            return 0
        }
    }
    
    /// Increment a specific achievement's tracked value (for events that can't be derived from character state)
    static func incrementAchievement(
        key: AchievementDefinitions.AchievementKey,
        by amount: Int = 1,
        character: PlayerCharacter
    ) {
        guard let achievement = character.achievements.first(where: { $0.trackingKey == key.rawValue }),
              !achievement.isUnlocked else { return }
        
        achievement.updateProgress(currentValue: achievement.currentValue + amount)
    }
}
