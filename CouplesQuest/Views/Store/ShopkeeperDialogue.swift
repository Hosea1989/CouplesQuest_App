import Foundation

/// Shopkeeper dialogue lines organized by store context.
/// Prefers server-driven narratives from ContentManager when available,
/// falling back to hardcoded lines.
struct ShopkeeperDialogue {
    
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
    
    // MARK: - Tab Greetings
    
    /// Lines shown when browsing the Equipment tab
    static let equipmentGreetings: [String] = [
        "Fresh steel and enchanted gear, just for you!",
        "Today's stock won't last — better grab something before it rotates!",
        "I hand-pick every piece myself. Only the finest!",
        "That armor over there? Saved a knight's life last week.",
        "New day, new gear. Take a look, adventurer!",
        "Got some real beauties in stock today. Have a browse!",
        "Legendary gear don't show up every day — keep your eyes peeled.",
        "Weapons, armor, accessories — everything a hero needs to stay ready.",
    ]
    
    /// Lines shown when browsing the Consumables tab
    static let consumableGreetings: [String] = [
        "Potions, boosts, and shields — everything an adventurer needs.",
        "A wise hero stocks up before the dungeon, not after!",
        "These EXP boosts? Best seller in the shop.",
        "Streak about to break? I got just the thing for that.",
        "Never go into battle without a healing draught. Trust me.",
        "That Lucky Coin there brings fortune to anyone who carries it.",
        "A Protein Shake before a quest? Smart move, adventurer.",
        "Stock up now — you'll thank me when you're deep in a dungeon.",
    ]
    
    /// Lines shown when browsing the Premium tab
    static let premiumGreetings: [String] = [
        "Ah, the gem collection. Only the rarest items here.",
        "Gems unlock power you can't buy with gold alone.",
        "That Revive Token has saved many a party from a total wipe.",
        "These are my finest wares. Gem-worthy, every one of 'em.",
        "The Loot Reroll? Turns a common blade into a legendary one.",
        "Instant Mission Scroll — for the adventurer who values their time.",
        "Premium items, premium results. You get what you pay for.",
        "Only the most dedicated adventurers earn enough gems for these.",
    ]
    
    // MARK: - Gem Explanation
    
    /// Detailed explanation of what gems are (shown when tapping for info)
    static let gemExplanation: String =
        "Gems are your premium currency, adventurer. You earn 'em from achievements, special events, and leveling milestones. Spend 'em wisely — these items are powerful!"
    
    // MARK: - Item-Specific Tips
    
    /// Returns a shopkeeper quip about a specific consumable item
    static func itemTip(for template: ConsumableTemplate) -> String {
        switch template.type {
        case .hpPotion:
            if template.effectValue >= 200 {
                return "The Supreme Elixir — legends say it can mend even the gravest wounds. Worth every coin."
            } else if template.effectValue >= 100 {
                return "A Greater Healing Draught. For when things get really rough in those dungeons."
            } else if template.effectValue >= 50 {
                return "Solid healing draught right there. Reliable in any dungeon run."
            } else {
                return "Herbal Tea — gentle but effective. Perfect for a new adventurer starting out."
            }
            
        case .expBoost:
            if template.effectValue >= 8 {
                return "Eight tasks with bonus EXP? That's a serious power boost. Level up fast with this one."
            } else if template.effectValue >= 5 {
                return "Five tasks of boosted EXP. Smart investment for a growing hero."
            } else {
                return "A quick EXP boost to get you moving. Three tasks of extra experience — not bad!"
            }
            
        case .goldBoost:
            if template.effectValue >= 8 {
                return "The Golden Chalice — eight tasks of fortune. Your coin purse will be overflowing!"
            } else if template.effectValue >= 5 {
                return "Fortune Stone. Five tasks of gold bonuses. Invest in yourself, adventurer."
            } else {
                return "Lucky Coin — a little extra gold never hurt anyone. Three tasks' worth!"
            }
            
        case .missionSpeedUp:
            if template.gemCost > 0 {
                return "That scroll? Poof — mission done instantly. Time is the one thing gold can't buy... but gems can."
            } else {
                return "Espresso Shot — cuts your mission time in half. For the adventurer in a hurry."
            }
            
        case .streakShield:
            if template.effectValue >= 3 {
                return "Three days of streak protection. Life happens — this cloak has your back."
            } else {
                return "One day of protection for your streak. A safety net every hero should carry."
            }
            
        case .statFood:
            if let stat = template.effectStat {
                return "A temporary \(stat.rawValue) boost. Eat up before a big dungeon run for the edge you need."
            }
            return "Stat food — gives you a temporary edge. Every point counts in tough battles."
            
        case .dungeonRevive:
            return "The Revive Token — a phoenix feather that brings your whole party back. A true lifesaver."
            
        case .lootReroll:
            return "The Loot Reroll. Got a piece of gear with bad stats? Give it another spin. Could turn trash into treasure."
            
        case .materialMagnet:
            return "The Material Magnet — double your crafting material drops for the next few tasks. Forgers love this one."
            
        case .luckElixir:
            return "Luck Elixir. Shimmering fortune in a bottle. Better drops in your next dungeon, guaranteed."
            
        case .partyBeacon:
            return "The Party Beacon — strengthens bonds between allies. Your party will grow closer, faster."
            
        case .affixScroll:
            return "Affix Scrolls are rare and powerful. Apply one at the Forge to guarantee magical properties on your gear."
            
        case .forgeCatalyst:
            return "Forge Catalyst — volatile but effective. Doubles your enhancement success chance for one attempt. Handle with care!"
            
        case .expeditionCompass:
            return "An Expedition Compass — peer ahead and see what rewards await at the next stage. Knowledge is power, adventurer."
            
        case .regenBuff:
            return "A Regen Buff — your body mends itself over time. Perfect for the long haul between dungeon runs."
        }
    }
    
    // MARK: - Storefront Greetings
    
    /// Lines shown when browsing the Storefront tab
    static let storefrontGreetings: [String] = [
        "Welcome! Check out today's hot deal before it's gone.",
        "The storefront has my finest picks. Don't miss the daily deal!",
        "Looking to gear up? I've got deals, bundles, and class-exclusive items.",
        "Your milestone gear is waiting — level up and claim what's yours!",
        "Bundles save you gold, adventurer. Smart heroes shop smart.",
        "Got a deal of the day that'll make your jaw drop. Take a look!",
        "Class gear sets give you that extra edge. Collect all three pieces!",
        "Welcome to the front of the shop — where the best deals live.",
    ]
    
    /// Lines about the deal of the day
    static let dealLines: [String] = [
        "Today's deal is a steal! Don't sleep on it.",
        "That deal won't last — grab it before midnight!",
        "I barely make any gold on this one. It's all for you, adventurer.",
    ]
    
    /// Lines about milestone gear
    static let milestoneLines: [String] = [
        "Milestone gear is forged for your class. No one else can wield it like you.",
        "Level up and new gear becomes available. That's how legends are made.",
        "Each milestone piece is hand-crafted for your path. Earn it, then buy it.",
    ]
    
    // MARK: - Welcome / Default
    
    /// Generic welcome lines shown on first load
    static let welcomeGreetings: [String] = [
        "Welcome to my shop, adventurer! Take a look around.",
        "Ah, a customer! Browse as long as you like.",
        "Welcome, welcome! I've got something for every hero.",
        "Step right in! The finest goods in the realm, right here.",
        "Good to see you, adventurer. What'll it be today?",
    ]
    
    // MARK: - Helpers
    
    /// Pick a random line from an array, optionally personalizing with the character's name
    static func random(from lines: [String], name: String? = nil) -> String {
        let line = lines.randomElement() ?? "Welcome to my shop!"
        return personalize(line, name: name)
    }
    
    /// Get the appropriate greeting for a store tab, personalized with the character's name.
    /// Uses server-driven narratives from ContentManager when available.
    @MainActor
    static func greeting(for tab: String, name: String? = nil) -> String {
        let line: String
        switch tab {
        case "Storefront":
            line = lines(forContext: "shopkeeper_storefront", fallback: storefrontGreetings).randomElement() ?? ""
        case "Equipment":
            line = lines(forContext: "shopkeeper_equipment", fallback: equipmentGreetings).randomElement() ?? ""
        case "Consumables":
            line = lines(forContext: "shopkeeper_consumable", fallback: consumableGreetings).randomElement() ?? ""
        case "Premium":
            line = lines(forContext: "shopkeeper_premium", fallback: premiumGreetings).randomElement() ?? ""
        default:
            line = lines(forContext: "shopkeeper_welcome", fallback: welcomeGreetings).randomElement() ?? ""
        }
        return personalize(line, name: name)
    }
    
    /// Replace "adventurer" with the character's name if provided
    private static func personalize(_ line: String, name: String?) -> String {
        guard let name = name, !name.isEmpty else { return line }
        // Replace "adventurer" (case-insensitive first occurrence) with the name
        if let range = line.range(of: "adventurer", options: .caseInsensitive) {
            return line.replacingCharacters(in: range, with: name)
        }
        return line
    }
}
