import Foundation

/// Scholar dialogue lines organized by research context.
/// Prefers server-driven narratives from ContentManager when available,
/// falling back to hardcoded lines.
struct ScholarDialogue {
    
    // MARK: - Server-Driven Helpers
    
    @MainActor
    private static func lines(forContext context: String, fallback: [String]) -> [String] {
        let cm = ContentManager.shared
        if cm.isLoaded && !cm.narratives.isEmpty {
            let serverLines = cm.narratives
                .filter { $0.active && $0.context == context }
                .sorted { $0.sortOrder < $1.sortOrder }
                .map { $0.text }
            if !serverLines.isEmpty { return serverLines }
        }
        return fallback
    }
    
    // MARK: - Welcome Greetings
    
    static let welcomeGreetings: [String] = [
        "Welcome to the Study, adventurer! Knowledge is the truest power.",
        "Ah, a seeker of wisdom! Let us unlock the secrets of the ancients.",
        "The tomes are ready and the ink is fresh. What shall we study?",
        "Every great hero invests in knowledge. You're wise to visit.",
        "Step into the Study! Power earned through patience lasts forever.",
    ]
    
    // MARK: - Branch Greetings
    
    static let combatBranchLines: [String] = [
        "The Combat branch sharpens your blade through the mind. Dungeon success starts here.",
        "Ancient battle tomes await your study. Each node brings lasting strength.",
        "Warriors who study fight twice as hard. Let's hone your combat instincts.",
    ]
    
    static let efficiencyBranchLines: [String] = [
        "Efficiency research optimizes everything you do. Time is your greatest ally.",
        "Faster missions, richer task rewards — the Efficiency branch covers it all.",
        "A scholar of efficiency wastes nothing. Every action becomes more rewarding.",
    ]
    
    static let fortuneBranchLines: [String] = [
        "Fortune favors the prepared, and the Fortune branch makes sure of it.",
        "Gold, rare drops, powerful enchantments — the Fortune path enriches all.",
        "Luck is not random for a scholar. It's a skill you can research.",
    ]
    
    // MARK: - Research Actions
    
    static let researchStartLines: [String] = [
        "Excellent choice! The research has begun. Return when the hourglass runs out.",
        "A fine node to invest in. The scholars are at work — patience, adventurer.",
        "Research started! The ancient tomes are being studied as we speak.",
        "Your tomes are well spent. This knowledge will serve you permanently.",
    ]
    
    static let researchCompleteLines: [String] = [
        "The research is complete! A permanent bonus is now yours. Well earned!",
        "Magnificent! Another node mastered. Your power grows with each discovery.",
        "Knowledge claimed! This bonus will serve you for the rest of your journey.",
        "A scholar's reward — permanent power. On to the next discovery!",
    ]
    
    static let activeResearchLines: [String] = [
        "Patience, adventurer. The scholars are still poring over those tomes.",
        "Research takes time, but the rewards are permanent. Worth the wait!",
        "Your active research progresses steadily. Check back soon.",
    ]
    
    // MARK: - Currency Explanations
    
    static let tomeExplanation: String =
        "Tomes are ancient texts earned from AFK training missions. Send your hero on missions and they'll return with tomes among their rewards. Each research node requires tomes to begin."
    
    static let goldExplanation: String =
        "Gold fuels the research process alongside tomes. You earn it from completing tasks, clearing dungeons, daily quests, and more."
    
    // MARK: - Cant Afford
    
    static let cantAffordLines: [String] = [
        "You're a bit short on resources for that node. Run some missions to earn more tomes!",
        "Not quite enough to begin that research. Complete tasks and missions to stock up!",
        "Almost there! A few more adventures should get you the tomes and gold you need.",
        "The knowledge awaits, but the coffers need filling first. Gather more resources!",
    ]
    
    // MARK: - Helpers
    
    @MainActor
    static func random(from lineArray: [String], name: String? = nil) -> String {
        let contextKey: String?
        switch lineArray {
        case welcomeGreetings: contextKey = "scholar_welcome"
        case combatBranchLines: contextKey = "scholar_combat"
        case efficiencyBranchLines: contextKey = "scholar_efficiency"
        case fortuneBranchLines: contextKey = "scholar_fortune"
        case researchStartLines: contextKey = "scholar_start"
        case researchCompleteLines: contextKey = "scholar_complete"
        case cantAffordLines: contextKey = "scholar_cant_afford"
        default: contextKey = nil
        }
        
        let pool: [String]
        if let key = contextKey {
            pool = lines(forContext: key, fallback: lineArray)
        } else {
            pool = lineArray
        }
        
        let line = pool.randomElement() ?? "The Study awaits, adventurer!"
        return personalize(line, name: name)
    }
    
    @MainActor
    static func branchGreeting(for branch: ResearchBranch, name: String? = nil) -> String {
        let lines: [String]
        switch branch {
        case .combat: lines = combatBranchLines
        case .efficiency: lines = efficiencyBranchLines
        case .fortune: lines = fortuneBranchLines
        }
        return random(from: lines, name: name)
    }
    
    private static func personalize(_ line: String, name: String?) -> String {
        guard let name = name, !name.isEmpty else { return line }
        if let range = line.range(of: "adventurer", options: .caseInsensitive) {
            return line.replacingCharacters(in: range, with: name)
        }
        return line
    }
}
