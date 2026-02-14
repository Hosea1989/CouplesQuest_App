import Foundation

// MARK: - Monster Card Catalog (Static Fallback)

/// Static fallback catalog of monster cards used when Supabase `content_cards` data is unavailable.
/// Organized by source type and theme. Each entry is a `ContentCard`-compatible struct.
struct MonsterCardCatalog {
    
    /// All static fallback cards (~50 entries)
    static let all: [ContentCard] = caveCards + ruinsCards + forestCards + fortressCards + volcanoCards + abyssCards + arenaCards + expeditionCards + raidCards
    
    // MARK: - Dungeon Theme: Cave (8 cards)
    
    static let caveCards: [ContentCard] = [
        ContentCard(id: "card_cave_01", name: "Cave Crawler", description: "A skittering beast from the deepest caverns.", theme: "Cave", rarity: "common", bonusType: "exp_percent", bonusValue: 0.005, sourceType: "dungeon", sourceName: "Dungeon: Crystal Caverns", dropChance: 0.10, imageName: nil, active: true, sortOrder: 1),
        ContentCard(id: "card_cave_02", name: "Stalactite Horror", description: "Drops from the ceiling when prey draws near.", theme: "Cave", rarity: "common", bonusType: "flat_defense", bonusValue: 1.0, sourceType: "dungeon", sourceName: "Dungeon: Crystal Caverns", dropChance: 0.10, imageName: nil, active: true, sortOrder: 2),
        ContentCard(id: "card_cave_03", name: "Glowworm Swarm", description: "Bioluminescent parasites that drain life slowly.", theme: "Cave", rarity: "uncommon", bonusType: "gold_percent", bonusValue: 0.008, sourceType: "dungeon", sourceName: "Dungeon: Crystal Caverns", dropChance: 0.08, imageName: nil, active: true, sortOrder: 3),
        ContentCard(id: "card_cave_04", name: "Crystal Golem", description: "A lumbering construct of living gemstone.", theme: "Cave", rarity: "uncommon", bonusType: "dungeon_success", bonusValue: 0.008, sourceType: "dungeon", sourceName: "Dungeon: Gemstone Depths", dropChance: 0.08, imageName: nil, active: true, sortOrder: 4),
        ContentCard(id: "card_cave_05", name: "Blind Basilisk", description: "It sees through vibrations in the stone.", theme: "Cave", rarity: "rare", bonusType: "loot_chance", bonusValue: 0.010, sourceType: "dungeon", sourceName: "Dungeon: Gemstone Depths", dropChance: 0.05, imageName: nil, active: true, sortOrder: 5),
        ContentCard(id: "card_cave_06", name: "Mushroom Shaman", description: "Fungal magic twists the mind of intruders.", theme: "Cave", rarity: "common", bonusType: "mission_speed", bonusValue: 0.005, sourceType: "dungeon", sourceName: "Dungeon: Spore Hollow", dropChance: 0.10, imageName: nil, active: true, sortOrder: 6),
        ContentCard(id: "card_cave_07", name: "Deeprock Wyrm", description: "An ancient serpent that burrows through solid granite.", theme: "Cave", rarity: "epic", bonusType: "exp_percent", bonusValue: 0.015, sourceType: "dungeon", sourceName: "Dungeon: Spore Hollow", dropChance: 0.03, imageName: nil, active: true, sortOrder: 7),
        ContentCard(id: "card_cave_08", name: "Echo Phantom", description: "A spirit born from the echoes of the lost.", theme: "Cave", rarity: "rare", bonusType: "dungeon_success", bonusValue: 0.012, sourceType: "dungeon", sourceName: "Dungeon: Crystal Caverns", dropChance: 0.05, imageName: nil, active: true, sortOrder: 8),
    ]
    
    // MARK: - Dungeon Theme: Ruins (8 cards)
    
    static let ruinsCards: [ContentCard] = [
        ContentCard(id: "card_ruins_01", name: "Temple Guardian", description: "A stone sentinel protecting forgotten altars.", theme: "Ruins", rarity: "common", bonusType: "flat_defense", bonusValue: 1.5, sourceType: "dungeon", sourceName: "Dungeon: Sunken Temple", dropChance: 0.10, imageName: nil, active: true, sortOrder: 9),
        ContentCard(id: "card_ruins_02", name: "Sand Wraith", description: "Whispers of the desert dead.", theme: "Ruins", rarity: "common", bonusType: "exp_percent", bonusValue: 0.005, sourceType: "dungeon", sourceName: "Dungeon: Sunken Temple", dropChance: 0.10, imageName: nil, active: true, sortOrder: 10),
        ContentCard(id: "card_ruins_03", name: "Cursed Pharaoh", description: "Eternally entombed, eternally angry.", theme: "Ruins", rarity: "uncommon", bonusType: "gold_percent", bonusValue: 0.010, sourceType: "dungeon", sourceName: "Dungeon: Sunken Temple", dropChance: 0.08, imageName: nil, active: true, sortOrder: 11),
        ContentCard(id: "card_ruins_04", name: "Hieroglyph Sprite", description: "The symbols on the walls come alive at night.", theme: "Ruins", rarity: "common", bonusType: "mission_speed", bonusValue: 0.005, sourceType: "dungeon", sourceName: "Dungeon: Ancient Archives", dropChance: 0.10, imageName: nil, active: true, sortOrder: 12),
        ContentCard(id: "card_ruins_05", name: "Obelisk Sentinel", description: "Its gaze turns intruders to stone.", theme: "Ruins", rarity: "uncommon", bonusType: "dungeon_success", bonusValue: 0.008, sourceType: "dungeon", sourceName: "Dungeon: Ancient Archives", dropChance: 0.08, imageName: nil, active: true, sortOrder: 13),
        ContentCard(id: "card_ruins_06", name: "Relic Devourer", description: "It feeds on the magic trapped in old artifacts.", theme: "Ruins", rarity: "rare", bonusType: "loot_chance", bonusValue: 0.012, sourceType: "dungeon", sourceName: "Dungeon: Ancient Archives", dropChance: 0.05, imageName: nil, active: true, sortOrder: 14),
        ContentCard(id: "card_ruins_07", name: "Timeworn Colossus", description: "A crumbling giant that still packs a punch.", theme: "Ruins", rarity: "epic", bonusType: "flat_defense", bonusValue: 3.0, sourceType: "dungeon", sourceName: "Dungeon: Sunken Temple", dropChance: 0.03, imageName: nil, active: true, sortOrder: 15),
        ContentCard(id: "card_ruins_08", name: "Mummy Lord", description: "Wrapped in ancient linen and dark sorcery.", theme: "Ruins", rarity: "rare", bonusType: "exp_percent", bonusValue: 0.012, sourceType: "dungeon", sourceName: "Dungeon: Ancient Archives", dropChance: 0.05, imageName: nil, active: true, sortOrder: 16),
    ]
    
    // MARK: - Dungeon Theme: Forest (8 cards)
    
    static let forestCards: [ContentCard] = [
        ContentCard(id: "card_forest_01", name: "Thornback Wolf", description: "Its fur is made of razor-sharp thorns.", theme: "Forest", rarity: "common", bonusType: "exp_percent", bonusValue: 0.005, sourceType: "dungeon", sourceName: "Dungeon: Whispering Woods", dropChance: 0.10, imageName: nil, active: true, sortOrder: 17),
        ContentCard(id: "card_forest_02", name: "Venomous Treant", description: "An ancient tree corrupted by poison.", theme: "Forest", rarity: "common", bonusType: "flat_defense", bonusValue: 1.0, sourceType: "dungeon", sourceName: "Dungeon: Whispering Woods", dropChance: 0.10, imageName: nil, active: true, sortOrder: 18),
        ContentCard(id: "card_forest_03", name: "Fae Trickster", description: "Leads travelers astray with illusions.", theme: "Forest", rarity: "uncommon", bonusType: "gold_percent", bonusValue: 0.008, sourceType: "dungeon", sourceName: "Dungeon: Whispering Woods", dropChance: 0.08, imageName: nil, active: true, sortOrder: 19),
        ContentCard(id: "card_forest_04", name: "Elder Stag", description: "A majestic creature of immense spiritual power.", theme: "Forest", rarity: "uncommon", bonusType: "mission_speed", bonusValue: 0.008, sourceType: "dungeon", sourceName: "Dungeon: Verdant Maze", dropChance: 0.08, imageName: nil, active: true, sortOrder: 20),
        ContentCard(id: "card_forest_05", name: "Moss Golem", description: "Born from centuries of decay on the forest floor.", theme: "Forest", rarity: "rare", bonusType: "dungeon_success", bonusValue: 0.010, sourceType: "dungeon", sourceName: "Dungeon: Verdant Maze", dropChance: 0.05, imageName: nil, active: true, sortOrder: 21),
        ContentCard(id: "card_forest_06", name: "Spore Mother", description: "Her children blanket the forest in toxic fog.", theme: "Forest", rarity: "rare", bonusType: "loot_chance", bonusValue: 0.010, sourceType: "dungeon", sourceName: "Dungeon: Verdant Maze", dropChance: 0.05, imageName: nil, active: true, sortOrder: 22),
        ContentCard(id: "card_forest_07", name: "Shadow Panther", description: "Invisible in the underbrush until it strikes.", theme: "Forest", rarity: "common", bonusType: "gold_percent", bonusValue: 0.005, sourceType: "dungeon", sourceName: "Dungeon: Whispering Woods", dropChance: 0.10, imageName: nil, active: true, sortOrder: 23),
        ContentCard(id: "card_forest_08", name: "Ancient Dryad", description: "The forest itself rises to defend her.", theme: "Forest", rarity: "epic", bonusType: "exp_percent", bonusValue: 0.018, sourceType: "dungeon", sourceName: "Dungeon: Verdant Maze", dropChance: 0.03, imageName: nil, active: true, sortOrder: 24),
    ]
    
    // MARK: - Dungeon Theme: Fortress (6 cards)
    
    static let fortressCards: [ContentCard] = [
        ContentCard(id: "card_fort_01", name: "Iron Sentinel", description: "A suit of armor animated by dark magic.", theme: "Fortress", rarity: "common", bonusType: "flat_defense", bonusValue: 1.5, sourceType: "dungeon", sourceName: "Dungeon: Iron Bastion", dropChance: 0.10, imageName: nil, active: true, sortOrder: 25),
        ContentCard(id: "card_fort_02", name: "War Hound", description: "Trained to hunt intruders through stone corridors.", theme: "Fortress", rarity: "common", bonusType: "exp_percent", bonusValue: 0.005, sourceType: "dungeon", sourceName: "Dungeon: Iron Bastion", dropChance: 0.10, imageName: nil, active: true, sortOrder: 26),
        ContentCard(id: "card_fort_03", name: "Siege Breaker", description: "Wields a battering ram with one hand.", theme: "Fortress", rarity: "uncommon", bonusType: "dungeon_success", bonusValue: 0.010, sourceType: "dungeon", sourceName: "Dungeon: Iron Bastion", dropChance: 0.08, imageName: nil, active: true, sortOrder: 27),
        ContentCard(id: "card_fort_04", name: "Ghost Knight", description: "The fallen commander patrols the battlements forever.", theme: "Fortress", rarity: "rare", bonusType: "gold_percent", bonusValue: 0.012, sourceType: "dungeon", sourceName: "Dungeon: Fallen Keep", dropChance: 0.05, imageName: nil, active: true, sortOrder: 28),
        ContentCard(id: "card_fort_05", name: "Ballistae Construct", description: "A mechanical crossbow that never misses.", theme: "Fortress", rarity: "uncommon", bonusType: "loot_chance", bonusValue: 0.008, sourceType: "dungeon", sourceName: "Dungeon: Fallen Keep", dropChance: 0.08, imageName: nil, active: true, sortOrder: 29),
        ContentCard(id: "card_fort_06", name: "Warden of the Gate", description: "None pass without answering the riddle.", theme: "Fortress", rarity: "epic", bonusType: "dungeon_success", bonusValue: 0.015, sourceType: "dungeon", sourceName: "Dungeon: Fallen Keep", dropChance: 0.03, imageName: nil, active: true, sortOrder: 30),
    ]
    
    // MARK: - Dungeon Theme: Volcano (5 cards)
    
    static let volcanoCards: [ContentCard] = [
        ContentCard(id: "card_volc_01", name: "Magma Slime", description: "A bubbling mass of molten rock.", theme: "Volcano", rarity: "common", bonusType: "exp_percent", bonusValue: 0.005, sourceType: "dungeon", sourceName: "Dungeon: Molten Core", dropChance: 0.10, imageName: nil, active: true, sortOrder: 31),
        ContentCard(id: "card_volc_02", name: "Ember Salamander", description: "Its skin ignites anything it touches.", theme: "Volcano", rarity: "uncommon", bonusType: "gold_percent", bonusValue: 0.010, sourceType: "dungeon", sourceName: "Dungeon: Molten Core", dropChance: 0.08, imageName: nil, active: true, sortOrder: 32),
        ContentCard(id: "card_volc_03", name: "Obsidian Drake", description: "A dragon forged from volcanic glass.", theme: "Volcano", rarity: "rare", bonusType: "loot_chance", bonusValue: 0.012, sourceType: "dungeon", sourceName: "Dungeon: Molten Core", dropChance: 0.05, imageName: nil, active: true, sortOrder: 33),
        ContentCard(id: "card_volc_04", name: "Ash Revenant", description: "Born from the ashes of the last eruption.", theme: "Volcano", rarity: "uncommon", bonusType: "mission_speed", bonusValue: 0.008, sourceType: "dungeon", sourceName: "Dungeon: Cinder Pit", dropChance: 0.08, imageName: nil, active: true, sortOrder: 34),
        ContentCard(id: "card_volc_05", name: "Inferno Lord", description: "Rules the heart of the mountain with fists of fire.", theme: "Volcano", rarity: "epic", bonusType: "flat_defense", bonusValue: 3.5, sourceType: "dungeon", sourceName: "Dungeon: Cinder Pit", dropChance: 0.03, imageName: nil, active: true, sortOrder: 35),
    ]
    
    // MARK: - Dungeon Theme: Abyss (5 cards)
    
    static let abyssCards: [ContentCard] = [
        ContentCard(id: "card_abyss_01", name: "Void Tendril", description: "Reaches from the darkness between worlds.", theme: "Abyss", rarity: "uncommon", bonusType: "exp_percent", bonusValue: 0.008, sourceType: "dungeon", sourceName: "Dungeon: The Rift", dropChance: 0.08, imageName: nil, active: true, sortOrder: 36),
        ContentCard(id: "card_abyss_02", name: "Chaos Imp", description: "A mischievous demon from the outer planes.", theme: "Abyss", rarity: "common", bonusType: "gold_percent", bonusValue: 0.005, sourceType: "dungeon", sourceName: "Dungeon: The Rift", dropChance: 0.10, imageName: nil, active: true, sortOrder: 37),
        ContentCard(id: "card_abyss_03", name: "Abyssal Leviathan", description: "A colossal horror sleeping in the void.", theme: "Abyss", rarity: "epic", bonusType: "loot_chance", bonusValue: 0.015, sourceType: "dungeon", sourceName: "Dungeon: The Rift", dropChance: 0.03, imageName: nil, active: true, sortOrder: 38),
        ContentCard(id: "card_abyss_04", name: "Shadow Weaver", description: "Spins webs of pure darkness.", theme: "Abyss", rarity: "rare", bonusType: "dungeon_success", bonusValue: 0.012, sourceType: "dungeon", sourceName: "Dungeon: Twilight Chasm", dropChance: 0.05, imageName: nil, active: true, sortOrder: 39),
        ContentCard(id: "card_abyss_05", name: "Nightmare Herald", description: "It brings visions of what awaits beyond death.", theme: "Abyss", rarity: "rare", bonusType: "mission_speed", bonusValue: 0.010, sourceType: "dungeon", sourceName: "Dungeon: Twilight Chasm", dropChance: 0.05, imageName: nil, active: true, sortOrder: 40),
    ]
    
    // MARK: - Arena Cards (6 cards)
    
    static let arenaCards: [ContentCard] = [
        ContentCard(id: "card_arena_01", name: "Gladiator's Spirit", description: "The crowd roars with every strike.", theme: "arena", rarity: "common", bonusType: "exp_percent", bonusValue: 0.005, sourceType: "arena", sourceName: "Arena Wave 15", dropChance: 0.20, imageName: nil, active: true, sortOrder: 41),
        ContentCard(id: "card_arena_02", name: "Pit Champion", description: "Undefeated in a hundred bouts.", theme: "arena", rarity: "uncommon", bonusType: "dungeon_success", bonusValue: 0.010, sourceType: "arena", sourceName: "Arena Wave 25", dropChance: 0.20, imageName: nil, active: true, sortOrder: 42),
        ContentCard(id: "card_arena_03", name: "Blood Berserker", description: "Grows stronger with every wound received.", theme: "arena", rarity: "uncommon", bonusType: "flat_defense", bonusValue: 2.0, sourceType: "arena", sourceName: "Arena Wave 25", dropChance: 0.20, imageName: nil, active: true, sortOrder: 43),
        ContentCard(id: "card_arena_04", name: "Arena Warlord", description: "Commands respect from fighters and monsters alike.", theme: "arena", rarity: "rare", bonusType: "gold_percent", bonusValue: 0.012, sourceType: "arena", sourceName: "Arena Wave 35", dropChance: 0.15, imageName: nil, active: true, sortOrder: 44),
        ContentCard(id: "card_arena_05", name: "Crowd Favorite", description: "The audience showers gold upon the victor.", theme: "arena", rarity: "rare", bonusType: "loot_chance", bonusValue: 0.010, sourceType: "arena", sourceName: "Arena Wave 35", dropChance: 0.15, imageName: nil, active: true, sortOrder: 45),
        ContentCard(id: "card_arena_06", name: "Immortal Duelist", description: "No blade has ever drawn their blood.", theme: "arena", rarity: "epic", bonusType: "exp_percent", bonusValue: 0.018, sourceType: "arena", sourceName: "Arena Wave 45", dropChance: 0.10, imageName: nil, active: true, sortOrder: 46),
    ]
    
    // MARK: - Expedition Cards (6 cards)
    
    static let expeditionCards: [ContentCard] = [
        ContentCard(id: "card_exped_01", name: "Trailblazer Hawk", description: "Scouts the path ahead from high above.", theme: "expedition", rarity: "common", bonusType: "mission_speed", bonusValue: 0.005, sourceType: "expedition", sourceName: "Expedition: The Long Road", dropChance: 0.15, imageName: nil, active: true, sortOrder: 47),
        ContentCard(id: "card_exped_02", name: "Caravan Guard", description: "A sturdy protector of merchants and adventurers.", theme: "expedition", rarity: "common", bonusType: "flat_defense", bonusValue: 1.0, sourceType: "expedition", sourceName: "Expedition: The Long Road", dropChance: 0.15, imageName: nil, active: true, sortOrder: 48),
        ContentCard(id: "card_exped_03", name: "Desert Mirage", description: "Not everything you see on the horizon is real.", theme: "expedition", rarity: "uncommon", bonusType: "gold_percent", bonusValue: 0.008, sourceType: "expedition", sourceName: "Expedition: Sands of Time", dropChance: 0.12, imageName: nil, active: true, sortOrder: 49),
        ContentCard(id: "card_exped_04", name: "Mountain Yeti", description: "A towering beast cloaked in snow and fury.", theme: "expedition", rarity: "uncommon", bonusType: "dungeon_success", bonusValue: 0.008, sourceType: "expedition", sourceName: "Expedition: Frozen Summit", dropChance: 0.12, imageName: nil, active: true, sortOrder: 50),
        ContentCard(id: "card_exped_05", name: "Treasure Hunter", description: "Has a nose for gold and a talent for traps.", theme: "expedition", rarity: "rare", bonusType: "loot_chance", bonusValue: 0.012, sourceType: "expedition", sourceName: "Expedition: Sands of Time", dropChance: 0.08, imageName: nil, active: true, sortOrder: 51),
        ContentCard(id: "card_exped_06", name: "Storm Elemental", description: "Born from lightning strikes on the open plains.", theme: "expedition", rarity: "epic", bonusType: "exp_percent", bonusValue: 0.015, sourceType: "expedition", sourceName: "Expedition: Frozen Summit", dropChance: 0.05, imageName: nil, active: true, sortOrder: 52),
    ]
    
    // MARK: - Raid Boss Cards (5 cards)
    
    static let raidCards: [ContentCard] = [
        ContentCard(id: "card_raid_01", name: "Gorethane the Undying", description: "Death is merely an inconvenience for this titan.", theme: "raid", rarity: "epic", bonusType: "flat_defense", bonusValue: 4.0, sourceType: "raid", sourceName: "Raid: Gorethane", dropChance: 1.0, imageName: nil, active: true, sortOrder: 53),
        ContentCard(id: "card_raid_02", name: "Queen Venomara", description: "Her venom melts steel and shatters resolve.", theme: "raid", rarity: "epic", bonusType: "exp_percent", bonusValue: 0.020, sourceType: "raid", sourceName: "Raid: Venomara", dropChance: 1.0, imageName: nil, active: true, sortOrder: 54),
        ContentCard(id: "card_raid_03", name: "Frostlord Kaelthas", description: "An eternal blizzard follows in his wake.", theme: "raid", rarity: "epic", bonusType: "dungeon_success", bonusValue: 0.020, sourceType: "raid", sourceName: "Raid: Kaelthas", dropChance: 1.0, imageName: nil, active: true, sortOrder: 55),
        ContentCard(id: "card_raid_04", name: "The Crimson Wyrm", description: "Its roar shakes mountains and boils rivers.", theme: "raid", rarity: "legendary", bonusType: "loot_chance", bonusValue: 0.025, sourceType: "raid", sourceName: "Raid: Crimson Wyrm", dropChance: 1.0, imageName: nil, active: true, sortOrder: 56),
        ContentCard(id: "card_raid_05", name: "Shadowlord Malachar", description: "The architect of darkness, master of the void.", theme: "raid", rarity: "legendary", bonusType: "exp_percent", bonusValue: 0.030, sourceType: "raid", sourceName: "Raid: Malachar", dropChance: 1.0, imageName: nil, active: true, sortOrder: 57),
    ]
}
