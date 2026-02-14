import Foundation
import SwiftData

/// Crafting materials collected from IRL tasks, dungeons, missions, and dismantling equipment
@Model
final class CraftingMaterial {
    /// Unique identifier
    var id: UUID
    
    /// The type of material
    var materialType: MaterialType
    
    /// Rarity tier of this material stack
    var rarity: ItemRarity
    
    /// Current quantity in this stack
    var quantity: Int
    
    /// Character ID of the owner
    var characterID: UUID
    
    init(
        materialType: MaterialType,
        rarity: ItemRarity,
        quantity: Int = 0,
        characterID: UUID
    ) {
        self.id = UUID()
        self.materialType = materialType
        self.rarity = rarity
        self.quantity = quantity
        self.characterID = characterID
    }
    
    /// Display name combining rarity and type
    var displayName: String {
        if rarity == .common {
            return materialType.displayName
        }
        return "\(rarity.rawValue) \(materialType.displayName)"
    }
    
    /// SF Symbol icon for this material type
    var icon: String {
        materialType.icon
    }
}

// MARK: - Material Type

/// Types of crafting materials and where they come from
enum MaterialType: String, Codable, CaseIterable {
    /// Earned from completing IRL tasks -- the key bridge between real life and the game
    case essence = "Essence"
    
    /// Dropped from dungeon combat encounters
    case ore = "Ore"
    
    /// Dropped from dungeon puzzle encounters
    case crystal = "Crystal"
    
    /// Dropped from dungeon trap/boss encounters
    case hide = "Hide"
    
    /// Earned from completing AFK missions
    case herb = "Herb"
    
    /// Obtained by dismantling equipment
    case fragment = "Fragment"
    
    /// Earned exclusively from AFK missions — used for the Research Tree
    case researchToken = "Research Token"
    
    var displayName: String { rawValue }
    
    var icon: String {
        switch self {
        case .essence: return "sparkle"
        case .ore: return "hammer.fill"
        case .crystal: return "diamond.fill"
        case .hide: return "leaf.fill"
        case .herb: return "laurel.leading"
        case .fragment: return "square.stack.3d.up.fill"
        case .researchToken: return "book.closed.fill"
        }
    }
    
    var color: String {
        switch self {
        case .essence: return "AccentGold"
        case .ore: return "StatStrength"
        case .crystal: return "AccentPurple"
        case .hide: return "StatDexterity"
        case .herb: return "AccentGreen"
        case .fragment: return "StatDexterity"
        case .researchToken: return "AccentPurple"
        }
    }
    
    /// Description of how to obtain this material
    var sourceDescription: String {
        switch self {
        case .essence: return "Earned by completing real-life tasks"
        case .ore: return "Found in dungeon combat rooms"
        case .crystal: return "Found in dungeon puzzle rooms"
        case .hide: return "Found in dungeon trap and boss rooms"
        case .herb: return "Gathered from AFK missions"
        case .fragment: return "Obtained by dismantling equipment"
        case .researchToken: return "Earned exclusively from AFK missions"
        }
    }
}

// MARK: - Forge Recipe

/// Defines the material costs to craft equipment at a given tier
struct ForgeRecipe {
    let tier: Int
    let resultRarityRange: String
    let essenceCost: Int
    let materialCost: Int          // any non-essence, non-fragment materials
    let materialMinRarity: ItemRarity
    let fragmentCost: Int
    let goldCost: Int
    
    /// All available forge recipes by tier
    static let recipes: [ForgeRecipe] = [
        ForgeRecipe(
            tier: 1,
            resultRarityRange: "Common — Uncommon",
            essenceCost: 3,
            materialCost: 2,
            materialMinRarity: .common,
            fragmentCost: 0,
            goldCost: 0
        ),
        ForgeRecipe(
            tier: 2,
            resultRarityRange: "Uncommon — Rare",
            essenceCost: 8,
            materialCost: 5,
            materialMinRarity: .common,
            fragmentCost: 2,
            goldCost: 50
        ),
        ForgeRecipe(
            tier: 3,
            resultRarityRange: "Rare — Epic",
            essenceCost: 15,
            materialCost: 8,
            materialMinRarity: .uncommon,
            fragmentCost: 5,
            goldCost: 200
        ),
        ForgeRecipe(
            tier: 4,
            resultRarityRange: "Epic — Legendary",
            essenceCost: 30,
            materialCost: 15,
            materialMinRarity: .rare,
            fragmentCost: 10,
            goldCost: 500
        )
    ]
    
    static func recipe(forTier tier: Int) -> ForgeRecipe? {
        // Use server-driven recipes when on main thread
        if Thread.isMainThread {
            return MainActor.assumeIsolated { activeRecipes() }.first { $0.tier == tier }
        }
        return recipes.first { $0.tier == tier }
    }
    
    /// Active recipes — server-driven from ContentManager with static fallback.
    @MainActor
    static func activeRecipes() -> [ForgeRecipe] {
        let cm = ContentManager.shared
        if cm.isLoaded && !cm.forgeRecipes.isEmpty {
            return cm.activeForgeRecipes(type: "craft").map { cr in
                ForgeRecipe(
                    tier: cr.tier,
                    resultRarityRange: "\(cr.outputRarityMin.capitalized) — \(cr.outputRarityMax.capitalized)",
                    essenceCost: cr.essenceCost,
                    materialCost: cr.materialCost,
                    materialMinRarity: ItemRarity(rawValue: cr.materialMinRarity.lowercased()) ?? .common,
                    fragmentCost: cr.fragmentCost,
                    goldCost: cr.goldCost
                )
            }
        }
        return recipes
    }
}
