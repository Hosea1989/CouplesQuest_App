import Foundation

// =============================================================
// ContentManager — Server-Driven Content Pipeline
//
// Central cache for ALL game content. On app launch:
//   1. Load from local JSON cache (instant, offline-safe)
//   2. Check content_version on Supabase (single lightweight query)
//   3. If server version > local → re-fetch all content tables
//   4. If offline → use cache (always works)
//   5. If first run + offline → use bundled fallback JSON
//
// Provides typed access:
//   ContentManager.shared.equipment
//   ContentManager.shared.dungeons
//   ContentManager.shared.dropRate(for: "task", type: "equipment")
//   ContentManager.shared.narratives(for: "shopkeeper_greeting")
// =============================================================


// MARK: - Content Model Types (Codable structs mapping to Supabase tables)

struct ContentEquipment: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let slot: String            // "weapon", "armor", "accessory", "trinket"
    let baseType: String        // "sword", "axe", "plate", "ring", "cloak", etc.
    let rarity: String          // "common" ... "legendary"
    let primaryStat: String     // "strength", "wisdom", etc.
    let statBonus: Int
    let secondaryStat: String?
    let secondaryStatBonus: Int
    let levelRequirement: Int
    let imageName: String?
    let isSetPiece: Bool
    let setId: String?
    let active: Bool
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id, name, description, slot, rarity, active
        case baseType = "base_type"
        case primaryStat = "primary_stat"
        case statBonus = "stat_bonus"
        case secondaryStat = "secondary_stat"
        case secondaryStatBonus = "secondary_stat_bonus"
        case levelRequirement = "level_requirement"
        case imageName = "image_name"
        case isSetPiece = "is_set_piece"
        case setId = "set_id"
        case sortOrder = "sort_order"
    }
}

struct ContentMilestoneGear: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let slot: String
    let baseType: String
    let rarity: String
    let primaryStat: String
    let statBonus: Int
    let secondaryStat: String?
    let secondaryStatBonus: Int
    let levelRequirement: Int
    let characterClass: String
    let goldCost: Int
    let imageName: String?
    let active: Bool
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id, name, description, slot, rarity, active
        case baseType = "base_type"
        case primaryStat = "primary_stat"
        case statBonus = "stat_bonus"
        case secondaryStat = "secondary_stat"
        case secondaryStatBonus = "secondary_stat_bonus"
        case levelRequirement = "level_requirement"
        case characterClass = "character_class"
        case goldCost = "gold_cost"
        case imageName = "image_name"
        case sortOrder = "sort_order"
    }
}

struct ContentGearSet: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let characterClassLine: String
    let piecesRequired: Int
    let bonusStat: String
    let bonusAmount: Int
    let bonusDescription: String
    let bonusType: String       // "flat", "percent", "dungeon_only", etc.
    let bonusValue: Double
    let levelRequirement: Int
    let active: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, description, active
        case characterClassLine = "character_class_line"
        case piecesRequired = "pieces_required"
        case bonusStat = "bonus_stat"
        case bonusAmount = "bonus_amount"
        case bonusDescription = "bonus_description"
        case bonusType = "bonus_type"
        case bonusValue = "bonus_value"
        case levelRequirement = "level_requirement"
    }
}

struct ContentCard: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let theme: String
    let rarity: String
    let bonusType: String       // "exp_percent", "gold_percent", etc.
    let bonusValue: Double
    let sourceType: String      // "dungeon", "arena", "expedition", "raid"
    let sourceName: String
    let dropChance: Double
    let imageName: String?
    let active: Bool
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id, name, description, theme, rarity, active
        case bonusType = "bonus_type"
        case bonusValue = "bonus_value"
        case sourceType = "source_type"
        case sourceName = "source_name"
        case dropChance = "drop_chance"
        case imageName = "image_name"
        case sortOrder = "sort_order"
    }
}

struct ContentDungeonRoom: Codable, Hashable {
    let name: String
    let description: String
    let encounterType: String   // "combat", "puzzle", "trap", "treasure", "boss"
    let primaryStat: String
    let difficultyRating: Int
    let isBossRoom: Bool
    let bonusLootChance: Double

    enum CodingKeys: String, CodingKey {
        case name, description
        case encounterType = "encounter_type"
        case primaryStat = "primary_stat"
        case difficultyRating = "difficulty_rating"
        case isBossRoom = "is_boss_room"
        case bonusLootChance = "bonus_loot_chance"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        encounterType = try container.decode(String.self, forKey: .encounterType)
        primaryStat = try container.decode(String.self, forKey: .primaryStat)
        difficultyRating = try container.decodeIfPresent(Int.self, forKey: .difficultyRating) ?? 1
        isBossRoom = try container.decodeIfPresent(Bool.self, forKey: .isBossRoom) ?? false
        bonusLootChance = try container.decodeIfPresent(Double.self, forKey: .bonusLootChance) ?? 0.0
    }
}

struct ContentDungeonStatReq: Codable, Hashable {
    let stat: String
    let value: Int
}

struct ContentDungeon: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let theme: String
    let difficulty: String      // "normal", "hard", "heroic", "mythic"
    let levelRequirement: Int
    let recommendedStatTotal: Int
    let maxPartySize: Int
    let baseExpReward: Int
    let baseGoldReward: Int
    let lootTier: Int
    let rooms: [ContentDungeonRoom]
    let isPartyOnly: Bool
    let partyBondLevelReq: Int
    let active: Bool
    let sortOrder: Int
    let minHPRequired: Int?
    let statRequirements: [ContentDungeonStatReq]?

    enum CodingKeys: String, CodingKey {
        case id, name, description, theme, difficulty, rooms, active
        case levelRequirement = "level_requirement"
        case recommendedStatTotal = "recommended_stat_total"
        case maxPartySize = "max_party_size"
        case baseExpReward = "base_exp_reward"
        case baseGoldReward = "base_gold_reward"
        case lootTier = "loot_tier"
        case isPartyOnly = "is_party_only"
        case partyBondLevelReq = "party_bond_level_req"
        case sortOrder = "sort_order"
        case minHPRequired = "min_hp_required"
        case statRequirements = "stat_requirements"
    }
}

struct ContentMissionStatReq: Codable, Hashable {
    let stat: String
    let value: Int
}

struct ContentMission: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let missionType: String     // "combat", "exploration", "research", etc.
    let rarity: String
    let durationSeconds: Int
    let statRequirements: [ContentMissionStatReq]
    let levelRequirement: Int
    let baseSuccessRate: Double
    let expReward: Int
    let goldReward: Int
    let canDropEquipment: Bool
    let possibleDrops: [ContentMissionDrop]
    let active: Bool
    let sortOrder: Int
    /// Which class line this training requires: "warrior", "mage", "archer", or nil for universal
    let classRequirement: String?
    /// The stat this training primarily boosts on success (e.g. "Strength", "Wisdom")
    let trainingStat: String?
    /// Whether this is a rank-up training course (class evolution trial)
    let isRankUpTraining: Bool?
    /// The advanced class this rank-up course unlocks on success (e.g. "Berserker")
    let rankUpTargetClass: String?

    enum CodingKeys: String, CodingKey {
        case id, name, description, rarity, active
        case missionType = "mission_type"
        case durationSeconds = "duration_seconds"
        case statRequirements = "stat_requirements"
        case levelRequirement = "level_requirement"
        case baseSuccessRate = "base_success_rate"
        case expReward = "exp_reward"
        case goldReward = "gold_reward"
        case canDropEquipment = "can_drop_equipment"
        case possibleDrops = "possible_drops"
        case sortOrder = "sort_order"
        case classRequirement = "class_requirement"
        case trainingStat = "training_stat"
        case isRankUpTraining = "is_rank_up_training"
        case rankUpTargetClass = "rank_up_target_class"
    }
}

struct ContentMissionDrop: Codable, Hashable {
    let type: String            // "material", "equipment", "consumable"
    let materialType: String?
    let rarity: String?
    let quantityMin: Int?
    let quantityMax: Int?

    enum CodingKeys: String, CodingKey {
        case type, rarity
        case materialType = "material_type"
        case quantityMin = "quantity_min"
        case quantityMax = "quantity_max"
    }
}

struct ContentExpeditionStage: Codable, Hashable {
    let name: String
    let narrativeText: String
    let durationSeconds: Int
    let primaryStat: String
    let difficultyRating: Int
    let possibleRewards: ContentExpeditionRewards

    enum CodingKeys: String, CodingKey {
        case name
        case narrativeText = "narrative_text"
        case durationSeconds = "duration_seconds"
        case primaryStat = "primary_stat"
        case difficultyRating = "difficulty_rating"
        case possibleRewards = "possible_rewards"
    }
}

struct ContentExpeditionRewards: Codable, Hashable {
    let exp: Int
    let gold: Int
    let equipmentChance: Double
    let materialChance: Double
    let cardChance: Double

    enum CodingKeys: String, CodingKey {
        case exp, gold
        case equipmentChance = "equipment_chance"
        case materialChance = "material_chance"
        case cardChance = "card_chance"
    }
}

struct ContentExpedition: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let theme: String
    let totalDurationSeconds: Int
    let levelRequirement: Int
    let statRequirements: [ContentMissionStatReq]
    let isPartyExpedition: Bool
    let stages: [ContentExpeditionStage]
    let exclusiveLootIds: [String]
    let active: Bool
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id, name, description, theme, stages, active
        case totalDurationSeconds = "total_duration_seconds"
        case levelRequirement = "level_requirement"
        case statRequirements = "stat_requirements"
        case isPartyExpedition = "is_party_expedition"
        case exclusiveLootIds = "exclusive_loot_ids"
        case sortOrder = "sort_order"
    }
}

struct ContentAffix: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let affixType: String       // "prefix", "suffix"
    let effectDescription: String
    let bonusType: String
    let minValue: Double
    let maxValue: Double
    let minItemRarity: String
    let category: String
    let active: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, category, active
        case affixType = "affix_type"
        case effectDescription = "effect_description"
        case bonusType = "bonus_type"
        case minValue = "min_value"
        case maxValue = "max_value"
        case minItemRarity = "min_item_rarity"
    }
}

struct ContentConsumable: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let consumableType: String  // "hp_potion", "exp_boost", etc.
    let icon: String
    let effectValue: Int
    let effectStat: String?
    let durationSeconds: Int?
    let goldCost: Int
    let gemCost: Int
    let levelRequirement: Int
    let tier: String
    let isPremium: Bool
    let maxStack: Int
    let active: Bool
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id, name, description, icon, tier, active
        case consumableType = "consumable_type"
        case effectValue = "effect_value"
        case effectStat = "effect_stat"
        case durationSeconds = "duration_seconds"
        case goldCost = "gold_cost"
        case gemCost = "gem_cost"
        case levelRequirement = "level_requirement"
        case isPremium = "is_premium"
        case maxStack = "max_stack"
        case sortOrder = "sort_order"
    }
}

struct ContentForgeRecipe: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let recipeType: String      // "craft", "consumable_craft"
    let tier: Int
    let targetSlot: String?
    let essenceCost: Int
    let materialCost: Int
    let materialMinRarity: String
    let fragmentCost: Int
    let herbCost: Int
    let goldCost: Int
    let gemCost: Int
    let outputRarityMin: String
    let outputRarityMax: String
    let outputConsumableId: String?
    let guaranteedAffixCount: Int
    let description: String
    let isSeasonal: Bool
    let availableFrom: String?
    let availableUntil: String?
    let active: Bool
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id, name, tier, description, active
        case recipeType = "recipe_type"
        case targetSlot = "target_slot"
        case essenceCost = "essence_cost"
        case materialCost = "material_cost"
        case materialMinRarity = "material_min_rarity"
        case fragmentCost = "fragment_cost"
        case herbCost = "herb_cost"
        case goldCost = "gold_cost"
        case gemCost = "gem_cost"
        case outputRarityMin = "output_rarity_min"
        case outputRarityMax = "output_rarity_max"
        case outputConsumableId = "output_consumable_id"
        case guaranteedAffixCount = "guaranteed_affix_count"
        case isSeasonal = "is_seasonal"
        case availableFrom = "available_from"
        case availableUntil = "available_until"
        case sortOrder = "sort_order"
    }
}

struct ContentEnhancementRule: Codable, Identifiable, Hashable {
    let id: String
    let enhancementLevel: Int
    let successRate: Double
    let costMultiplier: Double
    let statGain: Int
    let criticalChance: Double
    let active: Bool

    enum CodingKeys: String, CodingKey {
        case id, active
        case enhancementLevel = "enhancement_level"
        case successRate = "success_rate"
        case costMultiplier = "cost_multiplier"
        case statGain = "stat_gain"
        case criticalChance = "critical_chance"
    }
}

struct ContentSalvageRule: Codable, Identifiable, Hashable {
    let id: String
    let itemRarity: String
    let materialsReturned: Int
    let fragmentsReturned: Int
    let goldReturned: Int
    let affixRecoveryChance: Double
    let active: Bool

    enum CodingKeys: String, CodingKey {
        case id, active
        case itemRarity = "item_rarity"
        case materialsReturned = "materials_returned"
        case fragmentsReturned = "fragments_returned"
        case goldReturned = "gold_returned"
        case affixRecoveryChance = "affix_recovery_chance"
    }
}

struct ContentDropRate: Codable, Identifiable, Hashable {
    let id: String
    let contentSource: String   // "task", "dungeon", "mission", etc.
    let dropType: String        // "equipment", "material", "consumable", "card", "key"
    let baseChance: Double
    let rarityWeights: [String: Double]
    let luckScaling: Double
    let pityThreshold: Int?
    let pityMinRarity: String?
    let notes: String?
    let active: Bool

    enum CodingKeys: String, CodingKey {
        case id, notes, active
        case contentSource = "content_source"
        case dropType = "drop_type"
        case baseChance = "base_chance"
        case rarityWeights = "rarity_weights"
        case luckScaling = "luck_scaling"
        case pityThreshold = "pity_threshold"
        case pityMinRarity = "pity_min_rarity"
    }
}

struct ContentDuty: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let category: String        // "physical", "mental", "social", etc.
    let icon: String?
    let expMultiplier: Double
    let isSeasonal: Bool
    let availableFrom: String?
    let availableUntil: String?
    let active: Bool
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id, title, description, category, icon, active
        case expMultiplier = "exp_multiplier"
        case isSeasonal = "is_seasonal"
        case availableFrom = "available_from"
        case availableUntil = "available_until"
        case sortOrder = "sort_order"
    }
}

struct ContentNarrative: Codable, Identifiable, Hashable {
    let id: String
    let context: String         // "shopkeeper_greeting", "forgekeeper_welcome", etc.
    let text: String
    let theme: String?
    let sortOrder: Int
    let active: Bool

    enum CodingKeys: String, CodingKey {
        case id, context, text, theme, active
        case sortOrder = "sort_order"
    }
}

struct ContentAffixRerollCost: Codable, Identifiable, Hashable {
    let id: String
    let rerollNumber: Int
    let goldCost: Int
    let active: Bool

    enum CodingKeys: String, CodingKey {
        case id, active
        case rerollNumber = "reroll_number"
        case goldCost = "gold_cost"
    }
}

struct ContentCollectionMilestone: Codable, Identifiable, Hashable {
    let id: String
    let collectionType: String
    let threshold: Int
    let rewardType: String
    let rewardBonusType: String?
    let rewardBonusValue: Double?
    let rewardTitle: String?
    let rewardEquipmentId: String?
    let description: String
    let active: Bool

    enum CodingKeys: String, CodingKey {
        case id, threshold, description, active
        case collectionType = "collection_type"
        case rewardType = "reward_type"
        case rewardBonusType = "reward_bonus_type"
        case rewardBonusValue = "reward_bonus_value"
        case rewardTitle = "reward_title"
        case rewardEquipmentId = "reward_equipment_id"
    }
}

struct ContentStoreBundle: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let icon: String?
    let contents: [ContentBundleItem]
    let goldCost: Int
    let gemCost: Int
    let discountPercent: Int
    let levelRequirement: Int
    let isOneTimePurchase: Bool
    let isSeasonal: Bool
    let availableFrom: String?
    let availableUntil: String?
    let active: Bool
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id, name, description, icon, contents, active
        case goldCost = "gold_cost"
        case gemCost = "gem_cost"
        case discountPercent = "discount_percent"
        case levelRequirement = "level_requirement"
        case isOneTimePurchase = "is_one_time_purchase"
        case isSeasonal = "is_seasonal"
        case availableFrom = "available_from"
        case availableUntil = "available_until"
        case sortOrder = "sort_order"
    }
}

struct ContentBundleItem: Codable, Hashable {
    let type: String            // "equipment", "consumable", "material", "gold", "gems"
    let id: String?
    let quantity: Int?
}

struct ContentAchievement: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let category: String        // "tasks", "combat", "social", "collection", "wellness", etc.
    let icon: String
    let trackingType: String    // "count", "streak", "boolean"
    let targetValue: Int
    let rewardType: String      // "title", "gold", "gems", "equipment", "consumable"
    let rewardValue: Int
    let rewardItemId: String?
    let isHidden: Bool
    let sortOrder: Int
    let active: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, description, category, icon, active
        case trackingType = "tracking_type"
        case targetValue = "target_value"
        case rewardType = "reward_type"
        case rewardValue = "reward_value"
        case rewardItemId = "reward_item_id"
        case isHidden = "is_hidden"
        case sortOrder = "sort_order"
    }
}

struct ContentQuest: Codable, Identifiable, Hashable {
    let id: String
    let questType: String       // "completeTasks", "completeCategory", "forgeItem", etc.
    let title: String
    let description: String
    let targetValue: Int
    let targetCategory: String? // for category-specific quests
    let minLevel: Int
    let maxLevel: Int?          // nil = no cap
    let weight: Double          // selection weight (higher = more likely to appear)
    let rewardGold: Int
    let rewardExp: Int
    let rewardGems: Int
    let isBonus: Bool           // bonus quest type
    let active: Bool
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id, title, description, weight, active
        case questType = "quest_type"
        case targetValue = "target_value"
        case targetCategory = "target_category"
        case minLevel = "min_level"
        case maxLevel = "max_level"
        case rewardGold = "reward_gold"
        case rewardExp = "reward_exp"
        case rewardGems = "reward_gems"
        case isBonus = "is_bonus"
        case sortOrder = "sort_order"
    }
}


// MARK: - Content Cache Container

/// Single JSON blob containing all content tables. Saved to disk for offline access.
struct ContentCacheContainer: Codable {
    var version: Int = 0
    var equipment: [ContentEquipment] = []
    var milestoneGear: [ContentMilestoneGear] = []
    var gearSets: [ContentGearSet] = []
    var cards: [ContentCard] = []
    var dungeons: [ContentDungeon] = []
    var missions: [ContentMission] = []
    var expeditions: [ContentExpedition] = []
    var affixes: [ContentAffix] = []
    var consumables: [ContentConsumable] = []
    var forgeRecipes: [ContentForgeRecipe] = []
    var enhancementRules: [ContentEnhancementRule] = []
    var salvageRules: [ContentSalvageRule] = []
    var dropRates: [ContentDropRate] = []
    var duties: [ContentDuty] = []
    var narratives: [ContentNarrative] = []
    var affixRerollCosts: [ContentAffixRerollCost] = []
    var collectionMilestones: [ContentCollectionMilestone] = []
    var storeBundles: [ContentStoreBundle] = []
    var achievements: [ContentAchievement] = []
    var quests: [ContentQuest] = []
}


// MARK: - ContentManager

@MainActor
final class ContentManager: ObservableObject {

    // MARK: Singleton

    static let shared = ContentManager()

    // MARK: Published Content (typed access)

    @Published private(set) var equipment: [ContentEquipment] = []
    @Published private(set) var milestoneGear: [ContentMilestoneGear] = []
    @Published private(set) var gearSets: [ContentGearSet] = []
    @Published private(set) var cards: [ContentCard] = []
    
    /// Card pool with static fallback — use this instead of `cards` directly
    /// to guarantee a non-empty pool even when Supabase data is unavailable.
    var activeCardPool: [ContentCard] {
        cards.isEmpty ? MonsterCardCatalog.all : cards
    }
    @Published private(set) var dungeons: [ContentDungeon] = []
    @Published private(set) var missions: [ContentMission] = []
    @Published private(set) var expeditions: [ContentExpedition] = []
    @Published private(set) var affixes: [ContentAffix] = []
    @Published private(set) var consumables: [ContentConsumable] = []
    @Published private(set) var forgeRecipes: [ContentForgeRecipe] = []
    @Published private(set) var enhancementRules: [ContentEnhancementRule] = []
    @Published private(set) var salvageRules: [ContentSalvageRule] = []
    @Published private(set) var dropRates: [ContentDropRate] = []
    @Published private(set) var duties: [ContentDuty] = []
    @Published private(set) var narratives: [ContentNarrative] = []
    @Published private(set) var affixRerollCosts: [ContentAffixRerollCost] = []
    @Published private(set) var collectionMilestones: [ContentCollectionMilestone] = []
    @Published private(set) var storeBundles: [ContentStoreBundle] = []
    @Published private(set) var achievements: [ContentAchievement] = []
    @Published private(set) var quests: [ContentQuest] = []

    @Published private(set) var isLoaded = false
    @Published private(set) var lastError: String?

    // MARK: Private State

    private var localVersion: Int = 0

    private static let cacheFileName = "content_cache.json"
    private static let fallbackFileName = "content_fallback"  // .json in bundle

    // MARK: - Init

    private init() {}

    // MARK: - Public API

    /// Load content on app launch. Safe to call multiple times.
    /// 1. Load from local disk cache (instant, offline-safe)
    /// 2. Check server version
    /// 3. Re-fetch if version bumped
    /// 4. Fall back to bundled JSON if no cache exists
    func loadContent() async {
        // Step 1: Load from disk cache
        if let cached = loadFromDiskCache() {
            applyCache(cached)
            print("📦 ContentManager: Loaded v\(cached.version) from disk cache (\(cached.equipment.count) equipment, \(cached.dungeons.count) dungeons)")
        } else {
            // No disk cache — try bundled fallback
            if let fallback = loadFromBundledFallback() {
                applyCache(fallback)
                print("📦 ContentManager: Loaded v\(fallback.version) from bundled fallback")
            }
        }

        // Step 2: Check server version and fetch if needed
        do {
            let serverVersion = try await fetchServerVersion()

            if serverVersion > localVersion {
                print("📦 ContentManager: Server v\(serverVersion) > local v\(localVersion), fetching...")
                try await fetchAllContent(version: serverVersion)
                print("📦 ContentManager: Updated to v\(serverVersion) (\(equipment.count) equipment, \(dungeons.count) dungeons)")
            } else {
                print("📦 ContentManager: Up to date at v\(localVersion)")
            }

            lastError = nil
        } catch {
            // Offline or error — use whatever we have cached
            print("⚠️ ContentManager: Server check failed — \(error.localizedDescription). Using cached content.")
            lastError = error.localizedDescription
        }

        isLoaded = true
    }

    /// Force refresh all content from server, ignoring version check.
    func forceRefresh() async {
        do {
            let serverVersion = try await fetchServerVersion()
            try await fetchAllContent(version: serverVersion)
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - Convenience Accessors

    /// Get drop rate config for a specific source + type combination.
    func dropRate(for source: String, type: String) -> ContentDropRate? {
        dropRates.first { $0.contentSource == source && $0.dropType == type && $0.active }
    }

    /// Get all active narratives for a given context (e.g. "shopkeeper_greeting").
    func narratives(for context: String) -> [ContentNarrative] {
        narratives.filter { $0.context == context && $0.active }
    }

    /// Get a random narrative for a given context.
    func randomNarrative(for context: String, theme: String? = nil) -> String? {
        var pool = narratives.filter { $0.context == context && $0.active }
        if let theme = theme {
            let themed = pool.filter { $0.theme == theme }
            if !themed.isEmpty { pool = themed }
        }
        return pool.randomElement()?.text
    }

    /// Get active equipment filtered by slot and/or rarity.
    func equipment(slot: String? = nil, rarity: String? = nil) -> [ContentEquipment] {
        equipment.filter { item in
            item.active
            && (slot == nil || item.slot == slot)
            && (rarity == nil || item.rarity == rarity)
        }
    }

    /// Get a random equipment template matching criteria.
    func randomEquipment(slot: String? = nil, rarity: String? = nil) -> ContentEquipment? {
        equipment(slot: slot, rarity: rarity).randomElement()
    }

    /// Find equipment by catalog ID.
    func equipment(byId id: String) -> ContentEquipment? {
        equipment.first { $0.id == id }
    }

    /// Get milestone gear for a specific class.
    func milestoneGear(forClass characterClass: String) -> [ContentMilestoneGear] {
        milestoneGear.filter { $0.characterClass == characterClass && $0.active }
    }

    /// Get gear sets for a class line.
    func gearSets(forClassLine classLine: String) -> [ContentGearSet] {
        gearSets.filter { $0.characterClassLine == classLine && $0.active }
    }

    /// Get active dungeons sorted by level requirement.
    func activeDungeons() -> [ContentDungeon] {
        dungeons.filter { $0.active }.sorted { $0.levelRequirement < $1.levelRequirement }
    }

    /// Get active missions filtered by rarity.
    func activeMissions(rarity: String? = nil) -> [ContentMission] {
        missions.filter { $0.active && (rarity == nil || $0.rarity == rarity) }
    }

    /// Get active duties filtered by category.
    func activeDuties(category: String? = nil) -> [ContentDuty] {
        duties.filter { $0.active && (category == nil || $0.category == category) }
    }

    /// Get enhancement rule for a specific level.
    func enhancementRule(forLevel level: Int) -> ContentEnhancementRule? {
        enhancementRules.first { $0.enhancementLevel == level && $0.active }
    }

    /// Get salvage rule for a specific rarity.
    func salvageRule(forRarity rarity: String) -> ContentSalvageRule? {
        salvageRules.first { $0.itemRarity == rarity && $0.active }
    }

    /// Get the re-roll cost for a specific re-roll number.
    func affixRerollCost(forReroll number: Int) -> Int {
        affixRerollCosts.first { $0.rerollNumber == number && $0.active }?.goldCost ?? (number * 1000)
    }

    /// Get active consumables separated by gold/gem.
    func goldConsumables() -> [ContentConsumable] {
        consumables.filter { $0.active && !$0.isPremium && $0.goldCost > 0 }
    }

    func gemConsumables() -> [ContentConsumable] {
        consumables.filter { $0.active && ($0.isPremium || $0.gemCost > 0) }
    }

    /// Get active forge recipes filtered by type.
    func activeForgeRecipes(type: String? = nil) -> [ContentForgeRecipe] {
        forgeRecipes.filter { $0.active && (type == nil || $0.recipeType == type) }
    }

    /// Get active store bundles.
    func activeStoreBundles() -> [ContentStoreBundle] {
        storeBundles.filter { $0.active }
    }

    /// Get active quests filtered by type and level range.
    func activeQuests(forLevel level: Int, isBonus: Bool = false) -> [ContentQuest] {
        quests.filter { quest in
            quest.active
            && quest.isBonus == isBonus
            && quest.minLevel <= level
            && (quest.maxLevel == nil || quest.maxLevel! >= level)
        }
    }

    /// Get active achievements filtered by category.
    func activeAchievements(category: String? = nil) -> [ContentAchievement] {
        achievements.filter { $0.active && (category == nil || $0.category == category) }
    }

    // MARK: - Server Communication

    private func fetchServerVersion() async throws -> Int {
        struct VersionRow: Decodable {
            let version: Int
        }
        let rows: [VersionRow] = try await SupabaseService.shared.client
            .from("content_version")
            .select("version")
            .eq("id", value: "current")
            .execute()
            .value
        return rows.first?.version ?? 0
    }

    private func fetchAllContent(version: Int) async throws {
        let client = SupabaseService.shared.client

        // Fetch all tables in parallel using TaskGroup
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { @Sendable in
                let items: [ContentEquipment] = try await client.from("content_equipment").select().eq("active", value: true).execute().value
                await MainActor.run { self.equipment = items }
            }
            group.addTask { @Sendable in
                let items: [ContentMilestoneGear] = try await client.from("content_milestone_gear").select().eq("active", value: true).execute().value
                await MainActor.run { self.milestoneGear = items }
            }
            group.addTask { @Sendable in
                let items: [ContentGearSet] = try await client.from("content_gear_sets").select().eq("active", value: true).execute().value
                await MainActor.run { self.gearSets = items }
            }
            group.addTask { @Sendable in
                let items: [ContentCard] = try await client.from("content_cards").select().eq("active", value: true).execute().value
                await MainActor.run { self.cards = items }
            }
            group.addTask { @Sendable in
                let items: [ContentDungeon] = try await client.from("content_dungeons").select().eq("active", value: true).execute().value
                await MainActor.run { self.dungeons = items }
            }
            group.addTask { @Sendable in
                let items: [ContentMission] = try await client.from("content_missions").select().eq("active", value: true).execute().value
                await MainActor.run { self.missions = items }
            }
            group.addTask { @Sendable in
                let items: [ContentExpedition] = try await client.from("content_expeditions").select().eq("active", value: true).execute().value
                await MainActor.run { self.expeditions = items }
            }
            group.addTask { @Sendable in
                let items: [ContentAffix] = try await client.from("content_affixes").select().eq("active", value: true).execute().value
                await MainActor.run { self.affixes = items }
            }
            group.addTask { @Sendable in
                let items: [ContentConsumable] = try await client.from("content_consumables").select().eq("active", value: true).execute().value
                await MainActor.run { self.consumables = items }
            }
            group.addTask { @Sendable in
                let items: [ContentForgeRecipe] = try await client.from("content_forge_recipes").select().eq("active", value: true).execute().value
                await MainActor.run { self.forgeRecipes = items }
            }
            group.addTask { @Sendable in
                let items: [ContentEnhancementRule] = try await client.from("content_enhancement_rules").select().eq("active", value: true).execute().value
                await MainActor.run { self.enhancementRules = items }
            }
            group.addTask { @Sendable in
                let items: [ContentSalvageRule] = try await client.from("content_salvage_rules").select().eq("active", value: true).execute().value
                await MainActor.run { self.salvageRules = items }
            }
            group.addTask { @Sendable in
                let items: [ContentDropRate] = try await client.from("content_drop_rates").select().eq("active", value: true).execute().value
                await MainActor.run { self.dropRates = items }
            }
            group.addTask { @Sendable in
                let items: [ContentDuty] = try await client.from("content_duties").select().eq("active", value: true).execute().value
                await MainActor.run { self.duties = items }
            }
            group.addTask { @Sendable in
                let items: [ContentNarrative] = try await client.from("content_narratives").select().eq("active", value: true).execute().value
                await MainActor.run { self.narratives = items }
            }
            group.addTask { @Sendable in
                let items: [ContentAffixRerollCost] = try await client.from("content_affix_reroll_costs").select().eq("active", value: true).execute().value
                await MainActor.run { self.affixRerollCosts = items }
            }
            group.addTask { @Sendable in
                let items: [ContentCollectionMilestone] = try await client.from("content_collection_milestones").select().eq("active", value: true).execute().value
                await MainActor.run { self.collectionMilestones = items }
            }
            group.addTask { @Sendable in
                let items: [ContentStoreBundle] = try await client.from("content_store_bundles").select().eq("active", value: true).execute().value
                await MainActor.run { self.storeBundles = items }
            }
            group.addTask { @Sendable in
                let items: [ContentAchievement] = try await client.from("content_achievements").select().eq("active", value: true).execute().value
                await MainActor.run { self.achievements = items }
            }
            group.addTask { @Sendable in
                let items: [ContentQuest] = try await client.from("content_quests").select().eq("active", value: true).execute().value
                await MainActor.run { self.quests = items }
            }

            // Wait for all fetches to complete
            try await group.waitForAll()
        }

        // Update local version and save to disk
        localVersion = version
        saveToDiskCache()
    }

    // MARK: - Disk Cache

    private var cacheFileURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent(Self.cacheFileName)
    }

    private func loadFromDiskCache() -> ContentCacheContainer? {
        guard FileManager.default.fileExists(atPath: cacheFileURL.path) else { return nil }
        do {
            let data = try Data(contentsOf: cacheFileURL)
            let container = try JSONDecoder().decode(ContentCacheContainer.self, from: data)
            return container
        } catch {
            print("⚠️ ContentManager: Failed to load disk cache — \(error.localizedDescription)")
            return nil
        }
    }

    private func saveToDiskCache() {
        let container = buildCacheContainer()
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(container)
            try data.write(to: cacheFileURL, options: .atomic)
            print("💾 ContentManager: Saved v\(container.version) to disk cache")
        } catch {
            print("⚠️ ContentManager: Failed to save disk cache — \(error.localizedDescription)")
        }
    }

    // MARK: - Bundled Fallback

    private func loadFromBundledFallback() -> ContentCacheContainer? {
        guard let url = Bundle.main.url(forResource: Self.fallbackFileName, withExtension: "json") else {
            print("📦 ContentManager: No bundled fallback found")
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            let container = try JSONDecoder().decode(ContentCacheContainer.self, from: data)
            return container
        } catch {
            print("⚠️ ContentManager: Failed to load bundled fallback — \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Helpers

    private func applyCache(_ container: ContentCacheContainer) {
        localVersion = container.version
        equipment = container.equipment
        milestoneGear = container.milestoneGear
        gearSets = container.gearSets
        cards = container.cards
        dungeons = container.dungeons
        missions = container.missions
        expeditions = container.expeditions
        affixes = container.affixes
        consumables = container.consumables
        forgeRecipes = container.forgeRecipes
        enhancementRules = container.enhancementRules
        salvageRules = container.salvageRules
        dropRates = container.dropRates
        duties = container.duties
        narratives = container.narratives
        affixRerollCosts = container.affixRerollCosts
        collectionMilestones = container.collectionMilestones
        storeBundles = container.storeBundles
        achievements = container.achievements
        quests = container.quests
    }

    private func buildCacheContainer() -> ContentCacheContainer {
        ContentCacheContainer(
            version: localVersion,
            equipment: equipment,
            milestoneGear: milestoneGear,
            gearSets: gearSets,
            cards: cards,
            dungeons: dungeons,
            missions: missions,
            expeditions: expeditions,
            affixes: affixes,
            consumables: consumables,
            forgeRecipes: forgeRecipes,
            enhancementRules: enhancementRules,
            salvageRules: salvageRules,
            dropRates: dropRates,
            duties: duties,
            narratives: narratives,
            affixRerollCosts: affixRerollCosts,
            collectionMilestones: collectionMilestones,
            storeBundles: storeBundles,
            achievements: achievements,
            quests: quests
        )
    }
}
