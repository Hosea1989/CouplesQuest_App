import Foundation

/// Forgekeeper dialogue lines organized by forge context.
/// Prefers server-driven narratives from ContentManager when available,
/// falling back to hardcoded lines.
struct ForgekeeperDialogue {
    
    // MARK: - Server-Driven Helpers
    
    /// Fetch narrative lines for a given context, preferring server data
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
    
    /// Lines shown when entering the Forge
    static let welcomeGreetings: [String] = [
        "Welcome to the Forge, adventurer! Let's craft something mighty.",
        "Ah, a crafter approaches! What shall we forge today?",
        "The anvil is hot and the hammer is ready. Let's get to work!",
        "Step up to the Forge! Every great hero needs great gear.",
        "Good to see you, adventurer. Ready to turn materials into legend?",
    ]
    
    // MARK: - Slot Selection
    
    /// Lines shown when the player is choosing an equipment slot
    static let slotGreetings: [String] = [
        "Choose your equipment type wisely — each serves a different purpose in battle.",
        "Weapons for offense, armor for defense, accessories for that extra edge.",
        "What'll it be? A mighty weapon, sturdy armor, or a clever accessory?",
        "Every piece of equipment tells a story. Let's start writing yours.",
    ]
    
    // MARK: - Tier Selection
    
    /// Lines shown when the player is choosing a forge tier
    static let tierGreetings: [String] = [
        "Higher tiers demand rarer materials, but the results speak for themselves.",
        "Start with Apprentice if you're new, or go bold with Master tier!",
        "The Master Forge has produced some of the finest equipment in the realm.",
        "Choose your tier based on what you've gathered. No shame in starting small!",
    ]
    
    // MARK: - Ready to Forge
    
    /// Lines shown when all selections are made and the player can forge
    static let readyToForgeLines: [String] = [
        "Everything's set! Hit that Forge button and let's see what we create!",
        "Materials ready, slot chosen, tier locked in. Time to forge!",
        "The forge is hungry for those materials. Let's make something special!",
        "All set, adventurer! Swing that hammer and claim your new gear!",
    ]
    
    // MARK: - Forging Success
    
    /// Lines shown after a successful forge
    static let forgingSuccessLines: [String] = [
        "A masterpiece! The forge spirits smile upon you today!",
        "Now THAT is a fine piece of equipment! Well forged, adventurer!",
        "Beautiful work! The materials have taken shape perfectly.",
        "Another legendary craft from this forge! Well done!",
    ]
    
    // MARK: - Currency / Material Explanations
    
    /// Detailed explanation of Essence (shown when tapping for info)
    static let essenceExplanation: String =
        "Essence is the lifeblood of the Forge — earned every time you complete a real-life task. Verified tasks with photos or location give even more. It's the bridge between your real efforts and in-game power!"
    
    /// Detailed explanation of Materials — Ore, Crystal, Hide (shown when tapping for info)
    static let materialsExplanation: String =
        "Materials — Ore, Crystal, and Hide — come from dungeon adventures. Combat rooms drop Ore, puzzles yield Crystal, and traps or bosses give Hide. Explore more dungeons to stock up!"
    
    /// Detailed explanation of Fragments (shown when tapping for info)
    static let fragmentsExplanation: String =
        "Fragments are what remains when you dismantle unwanted equipment. Head to your Inventory, find gear you don't need, and salvage it. Nothing goes to waste in a good forge!"
    
    /// Detailed explanation of Gold in forge context (shown when tapping for info)
    static let goldExplanation: String =
        "Gold fuels the higher-tier recipes. You earn it from completing tasks, clearing dungeons, daily quests, and more. Higher-tier forging costs gold alongside other materials."
    
    /// Detailed explanation of Herbs (shown in the guide section)
    static let herbExplanation: String =
        "Herbs are gathered during AFK Missions. Send your hero on training missions and they'll return with herbs among their rewards. Used in future recipes!"
    
    // MARK: - Tier-Specific Tips
    
    /// Returns a forgekeeper quip about a specific forge tier
    static func tierTip(for tier: Int) -> String {
        switch tier {
        case 1:
            return "Apprentice Forge — the starting point for every crafter. Low cost, Common to Uncommon results. Perfect for building your collection!"
        case 2:
            return "Journeyman Forge — a solid step up. You'll need some Fragments and Gold, but the Uncommon to Rare gear is well worth the investment."
        case 3:
            return "Artisan Forge — now we're talking serious crafting! Rare to Epic gear, but you'll need Uncommon-quality materials to feed the flames."
        case 4:
            return "Master Forge — the pinnacle! Epic to Legendary equipment awaits, but only the most dedicated material gatherers can fuel this fire."
        default:
            return "Choose a tier and let's see what the forge can create!"
        }
    }
    
    // MARK: - Slot-Specific Tips
    
    /// Returns a forgekeeper quip about a specific equipment slot
    static func slotTip(for slot: String) -> String {
        switch slot {
        case "Weapon":
            return "A good weapon is the backbone of any adventurer. Higher attack means faster dungeon clears and better arena runs!"
        case "Armor":
            return "Strong armor keeps you in the fight longer. Defense is the difference between victory and a trip back to town."
        case "Accessory":
            return "Never underestimate a good accessory! They provide unique stat combinations that weapons and armor can't match."
        default:
            return "A fine choice, adventurer!"
        }
    }
    
    // MARK: - Not Enough Materials
    
    /// Lines shown when the player can't afford the selected recipe
    static let cantAffordLines: [String] = [
        "You're a bit short on materials for that tier. Try a lower one, or head out to gather more!",
        "Not quite enough to fuel the forge at that level. Complete more tasks and dungeons to stock up!",
        "The forge needs more to work with. Tasks give Essence, dungeons give Materials, and dismantling gives Fragments.",
        "Almost there! A few more adventures should get you the materials you need.",
    ]
    
    // MARK: - Helpers
    
    /// Pick a random line from an array, optionally personalizing with the character's name.
    /// Checks ContentManager for server-driven overrides based on the array identity.
    @MainActor
    static func random(from lineArray: [String], name: String? = nil) -> String {
        // Map known static arrays to their narrative context keys
        let contextKey: String?
        switch lineArray {
        case welcomeGreetings: contextKey = "forgekeeper_welcome"
        case slotGreetings: contextKey = "forgekeeper_slot"
        case tierGreetings: contextKey = "forgekeeper_tier"
        case readyToForgeLines: contextKey = "forgekeeper_ready"
        case forgingSuccessLines: contextKey = "forgekeeper_success"
        case cantAffordLines: contextKey = "forgekeeper_cant_afford"
        default: contextKey = nil
        }
        
        let pool: [String]
        if let key = contextKey {
            pool = lines(forContext: key, fallback: lineArray)
        } else {
            pool = lineArray
        }
        
        let line = pool.randomElement() ?? "The forge awaits, adventurer!"
        return personalize(line, name: name)
    }
    
    /// Replace "adventurer" with the character's name if provided
    private static func personalize(_ line: String, name: String?) -> String {
        guard let name = name, !name.isEmpty else { return line }
        if let range = line.range(of: "adventurer", options: .caseInsensitive) {
            return line.replacingCharacters(in: range, with: name)
        }
        return line
    }
}
