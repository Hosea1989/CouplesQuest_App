import Foundation
import SwiftData

// MARK: - Card Bonus Type

/// Types of passive bonuses a monster card can grant
enum CardBonusType: String, Codable, CaseIterable {
    case expPercent = "exp_percent"
    case goldPercent = "gold_percent"
    case dungeonSuccess = "dungeon_success"
    case lootChance = "loot_chance"
    case missionSpeed = "mission_speed"
    case flatDefense = "flat_defense"
    
    var displayName: String {
        switch self {
        case .expPercent: return "EXP Bonus"
        case .goldPercent: return "Gold Bonus"
        case .dungeonSuccess: return "Dungeon Success"
        case .lootChance: return "Loot Chance"
        case .missionSpeed: return "Mission Speed"
        case .flatDefense: return "Defense"
        }
    }
    
    var icon: String {
        switch self {
        case .expPercent: return "star.fill"
        case .goldPercent: return "dollarsign.circle.fill"
        case .dungeonSuccess: return "shield.checkered"
        case .lootChance: return "gift.fill"
        case .missionSpeed: return "bolt.fill"
        case .flatDefense: return "shield.fill"
        }
    }
    
    /// Format the bonus value for display
    func formatValue(_ value: Double) -> String {
        switch self {
        case .flatDefense:
            return "+\(String(format: "%.1f", value)) DEF"
        default:
            return "+\(String(format: "%.1f", value * 100))%"
        }
    }
}

/// Source type where a card can drop from
enum CardSourceType: String, Codable, CaseIterable {
    case dungeon = "dungeon"
    case arena = "arena"
    case expedition = "expedition"
    case raid = "raid"
    
    var displayName: String {
        switch self {
        case .dungeon: return "Dungeon"
        case .arena: return "Arena"
        case .expedition: return "Expedition"
        case .raid: return "Raid Boss"
        }
    }
    
    var icon: String {
        switch self {
        case .dungeon: return "door.left.hand.open"
        case .arena: return "figure.fencing"
        case .expedition: return "map.fill"
        case .raid: return "bolt.shield.fill"
        }
    }
}

// MARK: - Monster Card Model (SwiftData)

/// A collected monster card that grants a permanent passive bonus.
/// Duplicate finds upgrade the card — increasing bonus value and eventually rarity.
@Model
final class MonsterCard {
    /// Unique local identifier
    var id: UUID
    
    /// Content card ID (matches `content_cards.id` in Supabase)
    var cardID: String
    
    /// Card display name (e.g. "Shadow Lurker")
    var name: String
    
    /// Card flavor text / description
    var cardDescription: String
    
    /// Dungeon theme this card belongs to (e.g. "cave", "forest")
    var theme: String
    
    /// Card rarity (can be upgraded via duplicates)
    var rarity: ItemRarity
    
    /// Type of passive bonus this card grants
    var bonusType: CardBonusType
    
    /// Value of the bonus (e.g. 0.005 for +0.5%). Increases with each duplicate.
    var bonusValue: Double
    
    /// The original base bonus value (before any duplicate upgrades)
    var baseBonusValue: Double
    
    /// Where this card drops from
    var sourceType: CardSourceType
    
    /// Specific source name (e.g. "Dungeon: Shadow Crypt", "Arena Wave 15")
    var sourceName: String
    
    /// Whether this card has been collected
    var isCollected: Bool
    
    /// When the card was collected (nil if not yet collected)
    var collectedAt: Date?
    
    /// Owner's character ID
    var ownerID: UUID
    
    /// How many times this card has been found again (duplicates absorbed)
    var duplicateCount: Int
    
    /// How many rarity upgrades have been earned from duplicates
    var upgradeLevel: Int
    
    init(
        cardID: String,
        name: String,
        cardDescription: String = "",
        theme: String,
        rarity: ItemRarity,
        bonusType: CardBonusType,
        bonusValue: Double,
        sourceType: CardSourceType,
        sourceName: String = "",
        ownerID: UUID
    ) {
        self.id = UUID()
        self.cardID = cardID
        self.name = name
        self.cardDescription = cardDescription
        self.theme = theme
        self.rarity = rarity
        self.bonusType = bonusType
        self.bonusValue = bonusValue
        self.baseBonusValue = bonusValue
        self.sourceType = sourceType
        self.sourceName = sourceName
        self.isCollected = true
        self.collectedAt = Date()
        self.ownerID = ownerID
        self.duplicateCount = 0
        self.upgradeLevel = 0
    }
    
    // MARK: - Duplicate Upgrade Logic
    
    /// Thresholds at which the card's rarity upgrades to the next tier.
    /// At 3 dupes: first upgrade, 7: second, 12: third, 18: fourth (max legendary).
    static let rarityUpgradeThresholds: [Int] = [3, 7, 12, 18]
    
    /// The rarity tier this card should be at given its duplicate count and original rarity.
    var targetUpgradeLevel: Int {
        var level = 0
        for threshold in Self.rarityUpgradeThresholds {
            if duplicateCount >= threshold { level += 1 }
        }
        return level
    }
    
    /// The next rarity tier above the given one, capping at legendary.
    static func nextRarity(from rarity: ItemRarity) -> ItemRarity? {
        switch rarity {
        case .common: return .uncommon
        case .uncommon: return .rare
        case .rare: return .epic
        case .epic: return .legendary
        case .legendary: return nil
        }
    }
    
    /// Absorb a duplicate find: increase bonus, possibly upgrade rarity.
    /// Returns true if a rarity upgrade occurred.
    @discardableResult
    func absorbDuplicate() -> Bool {
        duplicateCount += 1
        
        // Increase bonus by 25% of base per duplicate
        bonusValue = baseBonusValue * (1.0 + 0.25 * Double(duplicateCount))
        
        // Check for rarity upgrade
        let target = targetUpgradeLevel
        if target > upgradeLevel {
            // Upgrade rarity once per threshold crossed
            if let next = Self.nextRarity(from: rarity) {
                rarity = next
                upgradeLevel = target
                return true
            }
        }
        
        return false
    }
}

// MARK: - Card Drop Engine

/// Handles card drop logic for all content types.
/// All roll methods accept a pre-fetched card pool so they are isolation-agnostic.
struct CardDropEngine {
    
    /// Roll for a card drop after a successful dungeon room.
    /// Uses per-card `dropChance` from server when > 0, otherwise hardcoded fallback.
    /// - Parameter cardPool: All active ContentCards (fetch via ContentManager.shared.activeCardPool).
    /// Returns the ContentCard if one drops, nil otherwise.
    static func rollDungeonCardDrop(
        dungeonTheme: String,
        roomEncounterType: String,
        isBossRoom: Bool,
        cardPool: [ContentCard]
    ) -> ContentCard? {
        let themeCards = cardPool.filter {
            $0.active && $0.sourceType == "dungeon" && $0.theme.lowercased() == dungeonTheme.lowercased()
        }
        guard !themeCards.isEmpty else { return nil }
        
        // Hardcoded fallback: 10% normal rooms, 15% boss rooms
        let fallbackChance = isBossRoom ? 0.15 : 0.10
        
        // Use per-pool average server dropChance if available, else fallback
        let avgServerChance = themeCards.reduce(0.0) { $0 + $1.dropChance } / Double(themeCards.count)
        let dropChance = avgServerChance > 0 ? avgServerChance : fallbackChance
        
        let roll = Double.random(in: 0...1)
        guard roll <= dropChance else { return nil }
        
        // Pick a random card from the theme pool (weighted by rarity)
        return weightedRandomCard(from: themeCards)
    }
    
    /// Roll for a card drop at an arena milestone wave.
    /// Uses per-card `dropChance` when > 0, otherwise 20% fallback.
    /// - Parameter cardPool: All active ContentCards.
    /// Returns the ContentCard if one drops, nil otherwise.
    static func rollArenaCardDrop(waveNumber: Int, cardPool: [ContentCard]) -> ContentCard? {
        // Only drop at milestone waves: 15, 25, 35, 45, ...
        guard waveNumber >= 15 && (waveNumber % 10 == 5 || waveNumber == 15 || waveNumber == 25) else {
            return nil
        }
        
        let arenaCards = cardPool.filter {
            $0.active && $0.sourceType == "arena"
        }
        guard !arenaCards.isEmpty else { return nil }
        
        // Use server dropChance or fallback to 20%
        let avgServerChance = arenaCards.reduce(0.0) { $0 + $1.dropChance } / Double(arenaCards.count)
        let dropChance = avgServerChance > 0 ? avgServerChance : 0.20
        
        let roll = Double.random(in: 0...1)
        guard roll <= dropChance else { return nil }
        
        return weightedRandomCard(from: arenaCards)
    }
    
    /// Guaranteed card drop from a raid boss.
    /// - Parameter cardPool: All active ContentCards.
    /// Returns the boss-exclusive card (always drops).
    static func raidBossCardDrop(bossTemplateName: String, cardPool: [ContentCard]) -> ContentCard? {
        let raidCards = cardPool.filter {
            $0.active && $0.sourceType == "raid"
        }
        
        // Try to find a card matching this boss template
        if let bossCard = raidCards.first(where: {
            $0.sourceName.lowercased().contains(bossTemplateName.lowercased())
        }) {
            return bossCard
        }
        
        // Fallback: any raid card
        return raidCards.randomElement()
    }
    
    /// Roll for a card drop from an expedition stage.
    /// Uses per-card `dropChance` when > 0, otherwise 15% fallback.
    /// - Parameter cardPool: All active ContentCards.
    /// Returns the ContentCard if one drops, nil otherwise.
    static func rollExpeditionCardDrop(expeditionTheme: String, cardPool: [ContentCard]) -> ContentCard? {
        let expeditionCards = cardPool.filter {
            $0.active && $0.sourceType == "expedition"
        }
        guard !expeditionCards.isEmpty else { return nil }
        
        // Use server dropChance or fallback to 15%
        let avgServerChance = expeditionCards.reduce(0.0) { $0 + $1.dropChance } / Double(expeditionCards.count)
        let dropChance = avgServerChance > 0 ? avgServerChance : 0.15
        
        let roll = Double.random(in: 0...1)
        guard roll <= dropChance else { return nil }
        
        return weightedRandomCard(from: expeditionCards)
    }
    
    /// Pick a weighted random card from a pool. Lower rarity = more likely.
    private static func weightedRandomCard(from cards: [ContentCard]) -> ContentCard? {
        guard !cards.isEmpty else { return nil }
        
        // Weight by rarity (common more likely, legendary very rare)
        let weightedPool: [(card: ContentCard, weight: Double)] = cards.map { card in
            let weight: Double
            switch card.rarity {
            case "common": weight = 5.0
            case "uncommon": weight = 3.0
            case "rare": weight = 1.5
            case "epic": weight = 0.5
            case "legendary": weight = 0.1
            default: weight = 1.0
            }
            return (card, weight)
        }
        
        let totalWeight = weightedPool.reduce(0.0) { $0 + $1.weight }
        var roll = Double.random(in: 0..<totalWeight)
        
        for entry in weightedPool {
            roll -= entry.weight
            if roll <= 0 {
                return entry.card
            }
        }
        
        return cards.first
    }
    
    /// Result type returned by collectCard
    enum CollectResult {
        /// Brand-new card collected
        case newCard(MonsterCard)
        /// Duplicate absorbed — card upgraded. Bool is true if rarity also upgraded.
        case duplicateAbsorbed(MonsterCard, rarityUpgraded: Bool)
    }
    
    /// Collect a card for a character. If already owned, absorb as duplicate (upgrades bonus + possibly rarity).
    /// Returns the collect result, or nil only if something truly fails.
    @MainActor
    static func collectCard(
        contentCard: ContentCard,
        character: PlayerCharacter,
        context: ModelContext
    ) -> CollectResult? {
        let charID = character.id
        let contentID = contentCard.id
        
        // Check if already collected
        let descriptor = FetchDescriptor<MonsterCard>(
            predicate: #Predicate<MonsterCard> { card in
                card.ownerID == charID && card.cardID == contentID
            }
        )
        
        if let existing = try? context.fetch(descriptor), let card = existing.first {
            // --- Duplicate: absorb and upgrade ---
            let rarityUpgraded = card.absorbDuplicate()
            try? context.save()
            
            // Update cached card power bonus
            let allCardsDescriptor = FetchDescriptor<MonsterCard>(
                predicate: #Predicate<MonsterCard> { $0.ownerID == charID && $0.isCollected == true }
            )
            if let allCards = try? context.fetch(allCardsDescriptor) {
                character.updateCachedCardPowerBonus(cards: allCards)
            }
            
            // Sync to Supabase
            SyncManager.shared.queueCardSync(cardID: contentCard.id, playerID: charID)
            
            // Post party feed event for upgrades
            if let partyID = character.partyID {
                if rarityUpgraded {
                    GameEngine.postPartyFeedEvent(
                        partyID: partyID,
                        actorID: charID,
                        eventType: "card_upgraded",
                        message: "\(character.name)'s \(card.name) upgraded to \(card.rarity.rawValue)!",
                        metadata: [
                            "card_id": contentCard.id,
                            "card_name": card.name,
                            "new_rarity": card.rarity.rawValue,
                            "duplicate_count": "\(card.duplicateCount)"
                        ]
                    )
                } else {
                    GameEngine.postPartyFeedEvent(
                        partyID: partyID,
                        actorID: charID,
                        eventType: "card_duplicate",
                        message: "\(character.name) found another \(card.name) (+\(card.duplicateCount) dupes)",
                        metadata: [
                            "card_id": contentCard.id,
                            "card_name": card.name,
                            "duplicate_count": "\(card.duplicateCount)"
                        ]
                    )
                }
            }
            
            // Sound: use cardReveal for rarity upgrade, cardCollect otherwise
            AudioManager.shared.play(rarityUpgraded ? .cardReveal : .cardCollect)
            
            return .duplicateAbsorbed(card, rarityUpgraded: rarityUpgraded)
        }
        
        // --- Brand-new card ---
        
        // Parse rarity
        let rarity: ItemRarity
        switch contentCard.rarity {
        case "common": rarity = .common
        case "uncommon": rarity = .uncommon
        case "rare": rarity = .rare
        case "epic": rarity = .epic
        case "legendary": rarity = .legendary
        default: rarity = .common
        }
        
        // Parse bonus type
        let bonusType: CardBonusType
        switch contentCard.bonusType {
        case "exp_percent": bonusType = .expPercent
        case "gold_percent": bonusType = .goldPercent
        case "dungeon_success": bonusType = .dungeonSuccess
        case "loot_chance": bonusType = .lootChance
        case "mission_speed": bonusType = .missionSpeed
        case "flat_defense": bonusType = .flatDefense
        default: bonusType = .expPercent
        }
        
        // Parse source type
        let sourceType: CardSourceType
        switch contentCard.sourceType {
        case "dungeon": sourceType = .dungeon
        case "arena": sourceType = .arena
        case "expedition": sourceType = .expedition
        case "raid": sourceType = .raid
        default: sourceType = .dungeon
        }
        
        let newCard = MonsterCard(
            cardID: contentCard.id,
            name: contentCard.name,
            cardDescription: contentCard.description,
            theme: contentCard.theme,
            rarity: rarity,
            bonusType: bonusType,
            bonusValue: contentCard.bonusValue,
            sourceType: sourceType,
            sourceName: contentCard.sourceName,
            ownerID: charID
        )
        
        context.insert(newCard)
        try? context.save()
        
        // Update cached card power bonus on the character
        let allCardsDescriptor = FetchDescriptor<MonsterCard>(
            predicate: #Predicate<MonsterCard> { $0.ownerID == charID && $0.isCollected == true }
        )
        if let allCards = try? context.fetch(allCardsDescriptor) {
            character.updateCachedCardPowerBonus(cards: allCards)
        }
        
        // Sync to Supabase via SyncManager
        SyncManager.shared.queueCardSync(cardID: contentCard.id, playerID: charID)
        
        // Post to party feed
        if let partyID = character.partyID {
            let totalCards = (try? context.fetchCount(FetchDescriptor<MonsterCard>(
                predicate: #Predicate { $0.ownerID == charID }
            ))) ?? 0
            
            GameEngine.postPartyFeedEvent(
                partyID: partyID,
                actorID: charID,
                eventType: "card_discovered",
                message: "\(character.name) discovered \(contentCard.name)! (\(totalCards)/50 collected)",
                metadata: [
                    "card_id": contentCard.id,
                    "card_name": contentCard.name,
                    "rarity": contentCard.rarity,
                    "theme": contentCard.theme
                ]
            )
        }
        
        // Play card collection sound + haptic
        AudioManager.shared.play(.cardCollect)
        
        return .newCard(newCard)
    }
}

// MARK: - Card Collection Bonuses

/// Calculate total passive bonuses from collected cards
struct CardBonusCalculator {
    
    /// Summary of all card bonuses for a character
    struct CardBonusSummary {
        var expPercent: Double = 0
        var goldPercent: Double = 0
        var dungeonSuccessPercent: Double = 0
        var lootChancePercent: Double = 0
        var missionSpeedPercent: Double = 0
        var flatDefense: Double = 0
        
        /// Total bonus to add to Power Score calculation
        var powerScoreBonus: Int {
            let percentBonus = (expPercent + goldPercent + dungeonSuccessPercent + lootChancePercent + missionSpeedPercent) * 100
            let defenseBonus = flatDefense * 5
            return Int(percentBonus + defenseBonus)
        }
    }
    
    /// Calculate total bonuses from all collected cards for a character
    @MainActor
    static func totalBonuses(characterID: UUID, context: ModelContext) -> CardBonusSummary {
        let descriptor = FetchDescriptor<MonsterCard>(
            predicate: #Predicate<MonsterCard> { card in
                card.ownerID == characterID && card.isCollected == true
            }
        )
        
        guard let cards = try? context.fetch(descriptor) else {
            return CardBonusSummary()
        }
        
        return totalBonuses(from: cards)
    }
    
    /// Calculate total bonuses from a given set of cards
    static func totalBonuses(from cards: [MonsterCard]) -> CardBonusSummary {
        var summary = CardBonusSummary()
        
        for card in cards {
            switch card.bonusType {
            case .expPercent: summary.expPercent += card.bonusValue
            case .goldPercent: summary.goldPercent += card.bonusValue
            case .dungeonSuccess: summary.dungeonSuccessPercent += card.bonusValue
            case .lootChance: summary.lootChancePercent += card.bonusValue
            case .missionSpeed: summary.missionSpeedPercent += card.bonusValue
            case .flatDefense: summary.flatDefense += card.bonusValue
            }
        }
        
        return summary
    }
    
    /// Check collection milestones and return unclaimed rewards
    @MainActor
    static func collectedCardCount(characterID: UUID, context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<MonsterCard>(
            predicate: #Predicate<MonsterCard> { card in
                card.ownerID == characterID && card.isCollected == true
            }
        )
        return (try? context.fetchCount(descriptor)) ?? 0
    }
}

// MARK: - Collection Milestones

/// Card collection milestones with rewards
enum CardCollectionMilestone: Int, CaseIterable {
    case ten = 10
    case twentyFive = 25
    case fifty = 50
    case seventyFive = 75
    case hundred = 100
    
    var label: String {
        switch self {
        case .ten: return "10 Cards"
        case .twentyFive: return "25 Cards"
        case .fifty: return "50 Cards"
        case .seventyFive: return "75 Cards"
        case .hundred: return "100 Cards"
        }
    }
    
    var rewardDescription: String {
        switch self {
        case .ten: return "+2% EXP from all sources"
        case .twentyFive: return "+2% Gold from all sources"
        case .fifty: return "+3% loot drop chance"
        case .seventyFive: return "+3% dungeon success"
        case .hundred: return "Title: \"Monster Scholar\" + unique equipment"
        }
    }
    
    var icon: String {
        switch self {
        case .ten: return "star.fill"
        case .twentyFive: return "dollarsign.circle.fill"
        case .fifty: return "gift.fill"
        case .seventyFive: return "shield.checkered"
        case .hundred: return "crown.fill"
        }
    }
    
    var color: String {
        switch self {
        case .ten: return "RarityUncommon"
        case .twentyFive: return "AccentGold"
        case .fifty: return "RarityRare"
        case .seventyFive: return "RarityEpic"
        case .hundred: return "RarityLegendary"
        }
    }
    
    /// Bonus type and value for milestone
    var bonusType: CardBonusType {
        switch self {
        case .ten: return .expPercent
        case .twentyFive: return .goldPercent
        case .fifty: return .lootChance
        case .seventyFive: return .dungeonSuccess
        case .hundred: return .expPercent
        }
    }
    
    var bonusValue: Double {
        switch self {
        case .ten: return 0.02
        case .twentyFive: return 0.02
        case .fifty: return 0.03
        case .seventyFive: return 0.03
        case .hundred: return 0.05
        }
    }
}
