import Foundation

// MARK: - Research Branch

/// The three research branches a player can invest in
enum ResearchBranch: String, Codable, CaseIterable {
    case combat = "Combat"
    case efficiency = "Efficiency"
    case fortune = "Fortune"
    
    var displayName: String { rawValue }
    
    var icon: String {
        switch self {
        case .combat: return "flame.fill"
        case .efficiency: return "bolt.fill"
        case .fortune: return "sparkles"
        }
    }
    
    var color: String {
        switch self {
        case .combat: return "StatStrength"
        case .efficiency: return "AccentGreen"
        case .fortune: return "AccentGold"
        }
    }
    
    var description: String {
        switch self {
        case .combat: return "Dungeon & expedition bonuses"
        case .efficiency: return "Mission & task bonuses"
        case .fortune: return "Loot & economy bonuses"
        }
    }
}

// MARK: - Research Bonus Type

/// Types of bonuses a research node can grant
enum ResearchBonusType: String, Codable {
    // Combat branch
    case dungeonSuccess          // +X% dungeon success chance
    case bossDamage              // +X% boss damage
    case critChance              // +X% crit chance
    case combatPower             // +X% all combat power
    
    // Efficiency branch
    case missionDuration         // -X% mission duration (negative = faster)
    case taskEXP                 // +X% task EXP
    case materialDropRate        // +X% material drop rate
    case allEXP                  // +X% all EXP
    
    // Fortune branch
    case rareDropChance          // +X% rare drop chance
    case goldBonus               // +X% gold from all sources
    case affixChance             // +X% affix roll chance
    case allLootBonus            // +X% all loot bonuses
    
    var displayName: String {
        switch self {
        case .dungeonSuccess:    return "Dungeon Success"
        case .bossDamage:        return "Boss Damage"
        case .critChance:        return "Critical Chance"
        case .combatPower:       return "Combat Power"
        case .missionDuration:   return "Mission Speed"
        case .taskEXP:           return "Task Experience"
        case .materialDropRate:  return "Material Drops"
        case .allEXP:            return "All Experience"
        case .rareDropChance:    return "Rare Drops"
        case .goldBonus:         return "Gold Bonus"
        case .affixChance:       return "Affix Chance"
        case .allLootBonus:      return "All Loot"
        }
    }
    
    /// Format the bonus value for display (e.g., "+2%" or "-5%")
    func formattedBonus(_ value: Double) -> String {
        let percent = Int(value * 100)
        switch self {
        case .missionDuration:
            return "-\(percent)% duration"
        default:
            return "+\(percent)%"
        }
    }
}

// MARK: - Material Cost

/// A single material cost entry for a research node
struct ResearchMaterialCost: Codable, Equatable {
    let materialType: String   // MaterialType raw value
    let rarity: String         // ItemRarity raw value
    let quantity: Int
}

// MARK: - Research Node

/// A single node in the research tree
struct ResearchNode: Identifiable, Codable, Equatable {
    /// Unique identifier (e.g., "combat_1", "efficiency_3")
    let id: String
    
    /// Display name
    let name: String
    
    /// Flavor description
    let nodeDescription: String
    
    /// Which branch this node belongs to
    let branch: ResearchBranch
    
    /// Tier within the branch (1-5, determines unlock order)
    let tier: Int
    
    /// What type of bonus this node grants
    let bonusType: ResearchBonusType
    
    /// Bonus value (e.g., 0.02 = 2%)
    let bonusValue: Double
    
    /// ID of the prerequisite node (nil for tier 1 nodes)
    let prerequisiteNodeID: String?
    
    /// Crafting materials required
    let materialCosts: [ResearchMaterialCost]
    
    /// Research Tokens required
    let researchTokenCost: Int
    
    /// Gold required
    let goldCost: Int
    
    /// Time to research in hours
    let researchDurationHours: Double
    
    /// Formatted duration for display
    var formattedDuration: String {
        let hours = Int(researchDurationHours)
        if hours == 1 {
            return "1 hour"
        }
        return "\(hours) hours"
    }
    
    /// Formatted bonus for display
    var formattedBonus: String {
        bonusType.formattedBonus(bonusValue)
    }
}

// MARK: - Research Tree Definition

/// Central definition of the research tree — all 15 nodes across 3 branches.
/// Static data (eventually server-driven via ContentManager).
struct ResearchTree {
    
    /// All nodes in the tree
    static let allNodes: [ResearchNode] = combatNodes + efficiencyNodes + fortuneNodes
    
    /// Get all nodes for a specific branch
    static func nodes(for branch: ResearchBranch) -> [ResearchNode] {
        allNodes.filter { $0.branch == branch }.sorted { $0.tier < $1.tier }
    }
    
    /// Get a specific node by ID
    static func node(withID id: String) -> ResearchNode? {
        allNodes.first { $0.id == id }
    }
    
    // MARK: - Combat Branch (5 Nodes)
    
    static let combatNodes: [ResearchNode] = [
        ResearchNode(
            id: "combat_1",
            name: "Battle Training I",
            nodeDescription: "Hone your combat instincts through rigorous study of ancient battle tactics.",
            branch: .combat,
            tier: 1,
            bonusType: .dungeonSuccess,
            bonusValue: 0.02,
            prerequisiteNodeID: nil,
            materialCosts: [
                ResearchMaterialCost(materialType: "Essence", rarity: "common", quantity: 3)
            ],
            researchTokenCost: 1,
            goldCost: 50,
            researchDurationHours: 1
        ),
        ResearchNode(
            id: "combat_2",
            name: "War Tactics",
            nodeDescription: "Study the weaknesses of powerful foes to strike harder where it counts.",
            branch: .combat,
            tier: 2,
            bonusType: .bossDamage,
            bonusValue: 0.05,
            prerequisiteNodeID: "combat_1",
            materialCosts: [
                ResearchMaterialCost(materialType: "Ore", rarity: "common", quantity: 5)
            ],
            researchTokenCost: 2,
            goldCost: 100,
            researchDurationHours: 2
        ),
        ResearchNode(
            id: "combat_3",
            name: "Critical Eye",
            nodeDescription: "Train your perception to find the perfect moment to strike a devastating blow.",
            branch: .combat,
            tier: 3,
            bonusType: .critChance,
            bonusValue: 0.01,
            prerequisiteNodeID: "combat_2",
            materialCosts: [
                ResearchMaterialCost(materialType: "Crystal", rarity: "uncommon", quantity: 5)
            ],
            researchTokenCost: 3,
            goldCost: 200,
            researchDurationHours: 4
        ),
        ResearchNode(
            id: "combat_4",
            name: "Battle Training II",
            nodeDescription: "Advanced combat techniques that push your dungeon prowess even further.",
            branch: .combat,
            tier: 4,
            bonusType: .dungeonSuccess,
            bonusValue: 0.04,
            prerequisiteNodeID: "combat_3",
            materialCosts: [
                ResearchMaterialCost(materialType: "Essence", rarity: "uncommon", quantity: 10)
            ],
            researchTokenCost: 5,
            goldCost: 400,
            researchDurationHours: 6
        ),
        ResearchNode(
            id: "combat_5",
            name: "Combat Mastery",
            nodeDescription: "The pinnacle of martial research — all combat becomes second nature.",
            branch: .combat,
            tier: 5,
            bonusType: .combatPower,
            bonusValue: 0.03,
            prerequisiteNodeID: "combat_4",
            materialCosts: [
                ResearchMaterialCost(materialType: "Ore", rarity: "rare", quantity: 8),
                ResearchMaterialCost(materialType: "Crystal", rarity: "rare", quantity: 8)
            ],
            researchTokenCost: 8,
            goldCost: 800,
            researchDurationHours: 8
        )
    ]
    
    // MARK: - Efficiency Branch (5 Nodes)
    
    static let efficiencyNodes: [ResearchNode] = [
        ResearchNode(
            id: "efficiency_1",
            name: "Swift Training I",
            nodeDescription: "Optimize your training routines to complete missions more quickly.",
            branch: .efficiency,
            tier: 1,
            bonusType: .missionDuration,
            bonusValue: 0.05,
            prerequisiteNodeID: nil,
            materialCosts: [
                ResearchMaterialCost(materialType: "Herb", rarity: "common", quantity: 3)
            ],
            researchTokenCost: 1,
            goldCost: 50,
            researchDurationHours: 1
        ),
        ResearchNode(
            id: "efficiency_2",
            name: "Scholarly Focus",
            nodeDescription: "Deepen your ability to learn from every task you undertake.",
            branch: .efficiency,
            tier: 2,
            bonusType: .taskEXP,
            bonusValue: 0.03,
            prerequisiteNodeID: "efficiency_1",
            materialCosts: [
                ResearchMaterialCost(materialType: "Essence", rarity: "common", quantity: 5)
            ],
            researchTokenCost: 2,
            goldCost: 100,
            researchDurationHours: 2
        ),
        ResearchNode(
            id: "efficiency_3",
            name: "Material Mastery",
            nodeDescription: "Attune yourself to the world around you, finding materials others miss.",
            branch: .efficiency,
            tier: 3,
            bonusType: .materialDropRate,
            bonusValue: 0.02,
            prerequisiteNodeID: "efficiency_2",
            materialCosts: [
                ResearchMaterialCost(materialType: "Fragment", rarity: "uncommon", quantity: 5)
            ],
            researchTokenCost: 3,
            goldCost: 200,
            researchDurationHours: 4
        ),
        ResearchNode(
            id: "efficiency_4",
            name: "Swift Training II",
            nodeDescription: "Advanced training methods that dramatically reduce mission time.",
            branch: .efficiency,
            tier: 4,
            bonusType: .missionDuration,
            bonusValue: 0.08,
            prerequisiteNodeID: "efficiency_3",
            materialCosts: [
                ResearchMaterialCost(materialType: "Herb", rarity: "uncommon", quantity: 10)
            ],
            researchTokenCost: 5,
            goldCost: 400,
            researchDurationHours: 6
        ),
        ResearchNode(
            id: "efficiency_5",
            name: "Efficiency Expert",
            nodeDescription: "The ultimate optimization — every action yields greater rewards.",
            branch: .efficiency,
            tier: 5,
            bonusType: .allEXP,
            bonusValue: 0.05,
            prerequisiteNodeID: "efficiency_4",
            materialCosts: [
                ResearchMaterialCost(materialType: "Essence", rarity: "rare", quantity: 8),
                ResearchMaterialCost(materialType: "Herb", rarity: "rare", quantity: 8)
            ],
            researchTokenCost: 8,
            goldCost: 800,
            researchDurationHours: 8
        )
    ]
    
    // MARK: - Fortune Branch (5 Nodes)
    
    static let fortuneNodes: [ResearchNode] = [
        ResearchNode(
            id: "fortune_1",
            name: "Lucky Find I",
            nodeDescription: "Fortune favors the prepared — learn to spot rare treasures more often.",
            branch: .fortune,
            tier: 1,
            bonusType: .rareDropChance,
            bonusValue: 0.02,
            prerequisiteNodeID: nil,
            materialCosts: [
                ResearchMaterialCost(materialType: "Crystal", rarity: "common", quantity: 3)
            ],
            researchTokenCost: 1,
            goldCost: 50,
            researchDurationHours: 1
        ),
        ResearchNode(
            id: "fortune_2",
            name: "Gold Rush",
            nodeDescription: "Develop a keen eye for profit, earning more gold from every venture.",
            branch: .fortune,
            tier: 2,
            bonusType: .goldBonus,
            bonusValue: 0.05,
            prerequisiteNodeID: "fortune_1",
            materialCosts: [
                ResearchMaterialCost(materialType: "Ore", rarity: "common", quantity: 5)
            ],
            researchTokenCost: 2,
            goldCost: 100,
            researchDurationHours: 2
        ),
        ResearchNode(
            id: "fortune_3",
            name: "Affix Sense",
            nodeDescription: "Attune your magical perception to draw out stronger enchantments.",
            branch: .fortune,
            tier: 3,
            bonusType: .affixChance,
            bonusValue: 0.01,
            prerequisiteNodeID: "fortune_2",
            materialCosts: [
                ResearchMaterialCost(materialType: "Hide", rarity: "uncommon", quantity: 5)
            ],
            researchTokenCost: 3,
            goldCost: 200,
            researchDurationHours: 4
        ),
        ResearchNode(
            id: "fortune_4",
            name: "Lucky Find II",
            nodeDescription: "Mastery over fortune — rare discoveries become commonplace.",
            branch: .fortune,
            tier: 4,
            bonusType: .rareDropChance,
            bonusValue: 0.04,
            prerequisiteNodeID: "fortune_3",
            materialCosts: [
                ResearchMaterialCost(materialType: "Crystal", rarity: "uncommon", quantity: 10)
            ],
            researchTokenCost: 5,
            goldCost: 400,
            researchDurationHours: 6
        ),
        ResearchNode(
            id: "fortune_5",
            name: "Fortune's Favor",
            nodeDescription: "The ultimate blessing — fate itself conspires to reward you.",
            branch: .fortune,
            tier: 5,
            bonusType: .allLootBonus,
            bonusValue: 0.03,
            prerequisiteNodeID: "fortune_4",
            materialCosts: [
                ResearchMaterialCost(materialType: "Hide", rarity: "rare", quantity: 8),
                ResearchMaterialCost(materialType: "Crystal", rarity: "rare", quantity: 8)
            ],
            researchTokenCost: 8,
            goldCost: 800,
            researchDurationHours: 8
        )
    ]
}

// MARK: - Research Bonus Summary

/// Aggregated bonuses from all completed research nodes
struct ResearchBonusSummary {
    var dungeonSuccessBonus: Double = 0       // +% dungeon success
    var bossDamageBonus: Double = 0           // +% boss damage
    var critChanceBonus: Double = 0           // +% crit chance
    var combatPowerBonus: Double = 0          // +% all combat power
    var missionDurationReduction: Double = 0  // -% mission duration
    var taskEXPBonus: Double = 0              // +% task EXP
    var materialDropRateBonus: Double = 0     // +% material drop rate
    var allEXPBonus: Double = 0              // +% all EXP
    var rareDropChanceBonus: Double = 0       // +% rare drop chance
    var goldBonus: Double = 0                // +% gold
    var affixChanceBonus: Double = 0         // +% affix chance
    var allLootBonus: Double = 0             // +% all loot
    
    /// Total power score contribution from research
    var powerScoreBonus: Int {
        // Each percentage point of combat-related research adds to power score
        let combatValue = (dungeonSuccessBonus + bossDamageBonus + critChanceBonus + combatPowerBonus) * 100
        let efficiencyValue = (taskEXPBonus + allEXPBonus + missionDurationReduction) * 50
        let fortuneValue = (rareDropChanceBonus + goldBonus + affixChanceBonus + allLootBonus) * 50
        return Int(combatValue + efficiencyValue + fortuneValue)
    }
    
    /// Calculate summary from a list of completed node IDs
    static func calculate(from completedNodeIDs: [String]) -> ResearchBonusSummary {
        var summary = ResearchBonusSummary()
        
        for nodeID in completedNodeIDs {
            guard let node = ResearchTree.node(withID: nodeID) else { continue }
            
            switch node.bonusType {
            case .dungeonSuccess:
                summary.dungeonSuccessBonus += node.bonusValue
            case .bossDamage:
                summary.bossDamageBonus += node.bonusValue
            case .critChance:
                summary.critChanceBonus += node.bonusValue
            case .combatPower:
                summary.combatPowerBonus += node.bonusValue
            case .missionDuration:
                summary.missionDurationReduction += node.bonusValue
            case .taskEXP:
                summary.taskEXPBonus += node.bonusValue
            case .materialDropRate:
                summary.materialDropRateBonus += node.bonusValue
            case .allEXP:
                summary.allEXPBonus += node.bonusValue
            case .rareDropChance:
                summary.rareDropChanceBonus += node.bonusValue
            case .goldBonus:
                summary.goldBonus += node.bonusValue
            case .affixChance:
                summary.affixChanceBonus += node.bonusValue
            case .allLootBonus:
                summary.allLootBonus += node.bonusValue
            }
        }
        
        return summary
    }
}
