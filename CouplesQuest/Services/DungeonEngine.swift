import Foundation

/// Handles all dungeon encounter resolution, stat calculations, and loot rolling
struct DungeonEngine {
    
    // MARK: - Party Power Calculation
    
    /// Calculate total party power for a specific room encounter (uses room's default primary stat)
    static func calculatePartyPower(
        party: [PlayerCharacter],
        room: DungeonRoom
    ) -> Int {
        return calculatePartyPower(party: party, room: room, statOverride: nil)
    }
    
    /// Calculate total party power with an optional stat override (from chosen approach)
    static func calculatePartyPower(
        party: [PlayerCharacter],
        room: DungeonRoom,
        statOverride: StatType?
    ) -> Int {
        let effectiveStat = statOverride ?? room.primaryStat
        var totalPower = 0
        
        for member in party {
            let stat = member.effectiveStats.value(for: effectiveStat)
            var memberPower = stat
            
            // Class encounter bonus (Warrior/Scholar/Artisan)
            if let charClass = member.characterClass,
               let bonusType = charClass.bonusEncounterType,
               bonusType == room.encounterType || (room.encounterType == .boss && charClass == .warrior) {
                memberPower += Int(Double(stat) * charClass.encounterPowerMultiplier)
            }
            
            totalPower += memberPower
        }
        
        // Enchanter party buff: +20% to total party power
        if party.contains(where: { $0.characterClass == .enchanter }) {
            totalPower += Int(Double(totalPower) * CharacterClass.enchanter.partyPowerMultiplier)
        }
        
        return totalPower
    }
    
    /// Calculate success chance for a room (0.0 - 1.0)
    static func calculateSuccessChance(
        party: [PlayerCharacter],
        room: DungeonRoom
    ) -> Double {
        return calculateSuccessChance(party: party, room: room, approach: nil)
    }
    
    /// Calculate success chance with an optional approach modifier
    static func calculateSuccessChance(
        party: [PlayerCharacter],
        room: DungeonRoom,
        approach: RoomApproach?
    ) -> Double {
        let power = calculatePartyPower(party: party, room: room, statOverride: approach?.primaryStat)
        let modifiedPower = Double(power) * (approach?.powerModifier ?? 1.0)
        
        // Difficulty scales with party size (but not linearly — co-op is advantageous)
        let scaledDifficulty = Double(room.difficultyRating) * (1.0 + 0.5 * Double(party.count - 1))
        
        // Success chance = power / difficulty, clamped between 5% and 95%
        let chance = modifiedPower / scaledDifficulty
        return min(0.95, max(0.05, chance))
    }
    
    // MARK: - Room Resolution
    
    /// Resolve a single room encounter with a chosen approach
    static func resolveRoom(
        room: DungeonRoom,
        roomIndex: Int,
        party: [PlayerCharacter],
        dungeon: Dungeon,
        run: DungeonRun,
        approach: RoomApproach? = nil
    ) -> RoomResult {
        let effectiveApproach = approach
        let power = calculatePartyPower(party: party, room: room, statOverride: effectiveApproach?.primaryStat)
        let modifiedPower = Int(Double(power) * (effectiveApproach?.powerModifier ?? 1.0))
        let scaledDifficulty = Int(Double(room.difficultyRating) * (1.0 + 0.5 * Double(party.count - 1)))
        let successChance = calculateSuccessChance(party: party, room: room, approach: effectiveApproach)
        
        // Roll for success
        let roll = Double.random(in: 0...1)
        let success = roll <= successChance
        
        // Calculate rewards or penalties
        var expEarned = 0
        var goldEarned = 0
        var hpLost = 0
        var lootDropped = false
        
        if success {
            // EXP and gold per room (portion of dungeon total)
            let roomShare = 1.0 / Double(dungeon.roomCount)
            expEarned = Int(Double(dungeon.baseExpReward) * roomShare * dungeon.difficulty.rewardMultiplier)
            goldEarned = Int(Double(dungeon.baseGoldReward) * roomShare * dungeon.difficulty.rewardMultiplier)
            
            // Boss rooms give double
            if room.isBossRoom {
                expEarned *= 2
                goldEarned *= 2
            }
            
            // Risky approaches that succeed get a bonus reward multiplier
            if let approach = effectiveApproach, approach.powerModifier > 1.1 {
                let bonusMultiplier = 1.0 + (approach.powerModifier - 1.0) * 0.5
                expEarned = Int(Double(expEarned) * bonusMultiplier)
                goldEarned = Int(Double(goldEarned) * bonusMultiplier)
            }
            
            // Check for bonus loot from this room
            let baseLootChance = room.bonusLootChance
            let tricksterBonus = party.compactMap({ $0.characterClass }).contains(.trickster)
                ? CharacterClass.trickster.lootDropBonus : 0.0
            lootDropped = Double.random(in: 0...1) <= (baseLootChance + tricksterBonus)
        } else {
            // Failed room deals damage — apply approach risk modifier
            let baseDamage = max(5, min(25, scaledDifficulty - modifiedPower))
            let riskMultiplier = effectiveApproach?.riskModifier ?? 1.0
            let riskedDamage = Int(Double(baseDamage) * riskMultiplier)
            
            // Ranger damage reduction
            let hasRanger = party.contains(where: { $0.characterClass == .ranger })
            let damageReduction = hasRanger ? CharacterClass.ranger.damageReductionMultiplier : 0.0
            hpLost = Int(Double(riskedDamage) * (1.0 - damageReduction))
            
            // Still earn a small amount of EXP for attempting
            expEarned = Int(Double(dungeon.baseExpReward) * 0.02)
        }
        
        // Pick narrative text — use approach-specific narratives if available
        let narrativeText: String
        if let approach = effectiveApproach {
            let narratives = success
                ? room.encounterType.successNarrative(for: approach)
                : room.encounterType.failureNarrative(for: approach)
            narrativeText = narratives.randomElement() ?? (success ? "Success!" : "Failed!")
        } else {
            let narratives = success ? room.encounterType.successNarratives : room.encounterType.failureNarratives
            narrativeText = narratives.randomElement() ?? (success ? "Success!" : "Failed!")
        }
        
        return RoomResult(
            roomIndex: roomIndex,
            roomName: room.name,
            success: success,
            playerPower: modifiedPower,
            requiredPower: scaledDifficulty,
            expEarned: expEarned,
            goldEarned: goldEarned,
            hpLost: hpLost,
            lootDropped: lootDropped,
            narrativeText: narrativeText,
            approachName: effectiveApproach?.name ?? ""
        )
    }
    
    // MARK: - Auto-Run (AFK Dungeon)
    
    /// Automatically select the best approach for a room based on party stats
    static func autoSelectBestApproach(
        party: [PlayerCharacter],
        room: DungeonRoom
    ) -> RoomApproach {
        let approaches = room.encounterType.approaches
        guard !approaches.isEmpty else {
            // Fallback: create a default approach using the room's primary stat
            return RoomApproach(
                name: "Direct",
                description: "A straightforward attempt",
                icon: "bolt.fill",
                primaryStat: room.primaryStat
            )
        }
        
        // Evaluate each approach: pick the one that maximizes effective power
        // effective power = sum of party stat values for approach.primaryStat * powerModifier
        var bestApproach = approaches[0]
        var bestEffectivePower = 0.0
        
        for approach in approaches {
            let power = calculatePartyPower(party: party, room: room, statOverride: approach.primaryStat)
            let effectivePower = Double(power) * approach.powerModifier
            if effectivePower > bestEffectivePower {
                bestEffectivePower = effectivePower
                bestApproach = approach
            }
        }
        
        return bestApproach
    }
    
    /// Calculate an overall success estimate for a dungeon (average across all rooms)
    static func overallSuccessEstimate(
        party: [PlayerCharacter],
        dungeon: Dungeon
    ) -> Double {
        guard !dungeon.rooms.isEmpty else { return 0 }
        let total = dungeon.rooms.reduce(0.0) { sum, room in
            let bestApproach = autoSelectBestApproach(party: party, room: room)
            return sum + calculateSuccessChance(party: party, room: room, approach: bestApproach)
        }
        return total / Double(dungeon.rooms.count)
    }
    
    /// Auto-run an entire dungeon: resolve all rooms automatically and return the completion result
    static func autoRunDungeon(
        dungeon: Dungeon,
        run: DungeonRun,
        party: [PlayerCharacter]
    ) -> DungeonCompletionResult {
        // Guard: prevent double-resolution
        guard !run.isResolved else {
            return processDungeonCompletion(dungeon: dungeon, run: run, party: party)
        }
        run.isResolved = true
        
        // Resolve each room in sequence
        for (index, room) in dungeon.rooms.enumerated() {
            guard run.partyHP > 0 else { break }
            
            // Auto-select the best approach
            let approach = autoSelectBestApproach(party: party, room: room)
            
            // Feed: entering room
            run.addFeedEntry(
                type: .roomEntered,
                message: "Room \(index + 1): \(room.name)",
                icon: room.encounterType.icon,
                color: room.encounterType.color
            )
            
            // Feed: approach chosen
            run.addFeedEntry(
                type: .approachChosen,
                message: "Used \(approach.name) — \(approach.primaryStat.rawValue)",
                icon: approach.icon,
                color: approach.primaryStat.color
            )
            
            // Resolve the room
            let result = resolveRoom(
                room: room,
                roomIndex: index,
                party: party,
                dungeon: dungeon,
                run: run,
                approach: approach
            )
            
            // Update run state
            run.roomResults.append(result)
            run.totalExpEarned += result.expEarned
            run.totalGoldEarned += result.goldEarned
            run.partyHP = max(0, run.partyHP - result.hpLost)
            run.currentRoomIndex = index + 1
            
            // Feed: outcome
            if result.success {
                run.addFeedEntry(
                    type: .outcomeSuccess,
                    message: "Success! +\(result.expEarned) EXP, +\(result.goldEarned) Gold"
                )
                if result.lootDropped {
                    run.addFeedEntry(
                        type: .lootFound,
                        message: "Loot found in \(room.name)!"
                    )
                }
            } else {
                run.addFeedEntry(
                    type: .outcomeFail,
                    message: "Failed! Lost \(result.hpLost) HP"
                )
            }
            
            // Co-op partner flavor
            if run.isCoopRun, let partnerName = run.partyMemberNames.last, run.partyMemberNames.count > 1 {
                let partnerActions = [
                    "\(partnerName) backed you up!",
                    "\(partnerName) covered your flank!",
                    "\(partnerName) provided support!",
                    "\(partnerName) combined their strength with yours!"
                ]
                run.addFeedEntry(
                    type: .partnerAction,
                    message: partnerActions.randomElement() ?? "\(partnerName) helped!"
                )
            }
            
            // Check for party wipe
            if run.partyHP <= 0 {
                run.status = .failed
                run.completedAt = Date()
                run.addFeedEntry(type: .dungeonFailed, message: "Party HP reached zero. Dungeon failed!")
                break
            }
        }
        
        // If we cleared all rooms, mark as completed
        if run.partyHP > 0 {
            run.status = .completed
            run.completedAt = Date()
            run.addFeedEntry(
                type: .dungeonComplete,
                message: "Dungeon cleared! +\(run.totalExpEarned) EXP, +\(run.totalGoldEarned) Gold"
            )
        }
        
        return processDungeonCompletion(dungeon: dungeon, run: run, party: party)
    }
    
    // MARK: - Dungeon Completion
    
    /// Process dungeon completion and generate final rewards
    static func processDungeonCompletion(
        dungeon: Dungeon,
        run: DungeonRun,
        party: [PlayerCharacter]
    ) -> DungeonCompletionResult {
        let success = run.status == .completed
        let luck = party.map { $0.effectiveStats.luck }.max() ?? 0
        
        // Calculate class loot bonus
        let classLootBonus = party.compactMap({ $0.characterClass?.lootDropBonus }).max() ?? 0.0
        
        // Generate loot drops
        var loot: [Equipment] = []
        if success {
            loot = LootGenerator.generateDungeonLoot(
                tier: dungeon.lootTier,
                luck: luck,
                roomResults: run.roomResults,
                dungeonDifficulty: dungeon.difficulty,
                classLootBonus: classLootBonus
            )
            
            // Assign loot to first party member (can be distributed later)
            for item in loot {
                item.ownerID = party.first?.id
            }
        }
        
        // Co-op bond EXP
        let bondExp = (run.isCoopRun && success) ? GameEngine.bondEXPForCoopDungeon : 0
        
        return DungeonCompletionResult(
            success: success,
            dungeonName: dungeon.name,
            totalExp: run.totalExpEarned,
            totalGold: run.totalGoldEarned,
            roomsCleared: run.roomResults.filter({ $0.success }).count,
            totalRooms: dungeon.roomCount,
            hpRemaining: run.partyHP,
            maxHP: run.maxPartyHP,
            lootDrops: loot,
            roomResults: run.roomResults,
            isCoopRun: run.isCoopRun,
            bondExpEarned: bondExp
        )
    }
    
    /// Get a power level description for UI display
    static func powerDescription(chance: Double) -> (text: String, color: String) {
        switch chance {
        case 0.8...: return ("Very High", "AccentGreen")
        case 0.6...: return ("High", "AccentGreen")
        case 0.4...: return ("Medium", "AccentGold")
        case 0.2...: return ("Low", "AccentOrange")
        default: return ("Very Low", "DifficultyHard")
        }
    }
}

// MARK: - Partner Proxy

/// A lightweight simulated partner character for co-op dungeons,
/// built from cached partner data on the player's character.
enum PartnerProxy {
    /// Create a simulated partner from cached data on the player character
    static func from(character: PlayerCharacter) -> PlayerCharacter? {
        guard character.hasPartner,
              let partnerName = character.partnerName,
              let partnerLevel = character.partnerLevel else {
            return nil
        }
        
        let partnerClass = character.partnerClass
        let statTotal = character.partnerStatTotal ?? (partnerLevel * 5 + 25)
        
        // Distribute stats based on class primary stat weighting
        let baseStat = statTotal / 6
        let remainder = statTotal - (baseStat * 6)
        
        let stats = Stats(
            strength: baseStat,
            wisdom: baseStat,
            charisma: baseStat,
            dexterity: baseStat,
            luck: baseStat
        )
        
        // Give extra points to primary stat
        if let primaryStat = partnerClass?.primaryStat {
            stats.increase(primaryStat, by: remainder + 2)
        } else {
            stats.increase(.strength, by: remainder)
        }
        
        let partner = PlayerCharacter(name: partnerName, stats: stats)
        partner.level = partnerLevel
        partner.characterClass = partnerClass
        
        // Give partner a synthetic ID matching the cached partner ID
        if let partnerID = character.partnerCharacterID {
            partner.id = partnerID
        }
        
        return partner
    }
}

// MARK: - Result Types

/// Final result of completing (or failing) a dungeon
struct DungeonCompletionResult {
    let success: Bool
    let dungeonName: String
    let totalExp: Int
    let totalGold: Int
    let roomsCleared: Int
    let totalRooms: Int
    let hpRemaining: Int
    let maxHP: Int
    let lootDrops: [Equipment]
    let roomResults: [RoomResult]
    let isCoopRun: Bool
    let bondExpEarned: Int
    
    init(
        success: Bool,
        dungeonName: String,
        totalExp: Int,
        totalGold: Int,
        roomsCleared: Int,
        totalRooms: Int,
        hpRemaining: Int,
        maxHP: Int,
        lootDrops: [Equipment],
        roomResults: [RoomResult],
        isCoopRun: Bool = false,
        bondExpEarned: Int = 0
    ) {
        self.success = success
        self.dungeonName = dungeonName
        self.totalExp = totalExp
        self.totalGold = totalGold
        self.roomsCleared = roomsCleared
        self.totalRooms = totalRooms
        self.hpRemaining = hpRemaining
        self.maxHP = maxHP
        self.lootDrops = lootDrops
        self.roomResults = roomResults
        self.isCoopRun = isCoopRun
        self.bondExpEarned = bondExpEarned
    }
    
    var clearPercentage: Double {
        guard totalRooms > 0 else { return 0 }
        return Double(roomsCleared) / Double(totalRooms)
    }
}
