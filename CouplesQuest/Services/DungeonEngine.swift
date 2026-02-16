import Foundation

/// Handles all dungeon encounter resolution, stat calculations, and loot rolling
struct DungeonEngine {
    
    // MARK: - Room Pool Selection
    
    /// Select rooms from a dungeon's room pool for a single run.
    /// Picks 5-7 rooms from the full pool (8-10 defined), shuffled each run.
    /// Boss rooms are always included. Bonus rooms have a chance to appear.
    /// Class-gated rooms only appear if the party qualifies.
    static func selectRoomsForRun(
        from allRooms: [DungeonRoom],
        party: [PlayerCharacter],
        targetRoomCount: Int? = nil
    ) -> [DungeonRoom] {
        // Separate boss rooms (always included) from regular and bonus rooms
        var bossRooms = allRooms.filter { $0.isBossRoom }
        var bonusRooms = allRooms.filter { $0.isBonusRoom && !$0.isBossRoom }
        var regularRooms = allRooms.filter { !$0.isBossRoom && !$0.isBonusRoom }
        
        // Filter class-gated rooms: only include if party qualifies
        bonusRooms = bonusRooms.filter { $0.canEnter(party: party) }
        regularRooms = regularRooms.filter { $0.canEnter(party: party) }
        
        // Determine target count: default 5-7 based on pool size
        let target = targetRoomCount ?? min(7, max(5, allRooms.count - 2))
        
        // Start with boss rooms (always included)
        var selectedRooms: [DungeonRoom] = bossRooms
        
        // Roll for bonus room inclusion (30% chance per bonus room)
        for bonus in bonusRooms.shuffled() {
            if Double.random(in: 0...1) <= 0.30 {
                selectedRooms.append(bonus)
            }
        }
        
        // Fill remaining slots with shuffled regular rooms
        let remainingSlots = max(0, target - selectedRooms.count)
        let shuffledRegular = regularRooms.shuffled()
        selectedRooms.append(contentsOf: shuffledRegular.prefix(remainingSlots))
        
        // Sort: regular rooms first (shuffled order), boss at end
        let nonBoss = selectedRooms.filter { !$0.isBossRoom }.shuffled()
        let boss = selectedRooms.filter { $0.isBossRoom }
        
        return nonBoss + boss
    }
    
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
        return calculateSuccessChance(party: party, room: room, approach: approach, dungeon: nil)
    }
    
    /// Calculate success chance with optional approach modifier and dungeon context for stat penalties
    static func calculateSuccessChance(
        party: [PlayerCharacter],
        room: DungeonRoom,
        approach: RoomApproach?,
        dungeon: Dungeon?
    ) -> Double {
        let power = calculatePartyPower(party: party, room: room, statOverride: approach?.primaryStat)
        let modifiedPower = Double(power) * (approach?.powerModifier ?? 1.0)
        
        // Difficulty scales with party size (but not linearly — co-op is advantageous)
        let scaledDifficulty = Double(room.difficultyRating) * (1.0 + 0.5 * Double(max(1, party.count) - 1))
        
        // Success chance = power / difficulty, clamped between 5% and 95%
        var chance = modifiedPower / scaledDifficulty
        
        // Research tree dungeon success bonus (additive — from all party members, averaged)
        let avgDungeonBonus = party.reduce(0.0) { $0 + $1.researchBonuses.dungeonSuccessBonus } / max(1.0, Double(party.count))
        chance += avgDungeonBonus
        
        // Stat deficit penalty — if the dungeon has stat requirements, penalize for unmet stats
        if let dungeon = dungeon {
            let readiness = calculateStatReadiness(party: party, dungeon: dungeon)
            if readiness < 1.0 {
                // Scale penalty: 0% readiness = -40% chance, 50% readiness = -20% chance
                let penalty = (1.0 - readiness) * 0.40
                chance -= penalty
            }
        }
        
        // Apply difficulty-specific floor (Mythic has a lower minimum than Normal)
        let floor = dungeon?.difficulty.successFloor ?? 0.05
        return min(0.95, max(floor, chance))
    }
    
    // MARK: - Stat Readiness
    
    /// Calculate how "ready" a party is for a dungeon's stat requirements (0.0 – 1.0).
    /// 1.0 = all requirements met, 0.0 = severely underprepared.
    static func calculateStatReadiness(
        party: [PlayerCharacter],
        dungeon: Dungeon
    ) -> Double {
        guard !dungeon.statRequirements.isEmpty else { return 1.0 }
        
        var totalReadiness = 0.0
        for req in dungeon.statRequirements {
            // Use the best stat value from any party member
            let bestStat = party.map { $0.effectiveStats.value(for: req.stat) }.max() ?? 0
            let ratio = Double(bestStat) / Double(max(1, req.minimum))
            totalReadiness += min(1.0, ratio) // Cap at 1.0 per stat
        }
        
        return totalReadiness / Double(dungeon.statRequirements.count)
    }
    
    // MARK: - Room Resolution
    
    /// Resolve a single room encounter with a chosen approach
    static func resolveRoom(
        room: DungeonRoom,
        roomIndex: Int,
        party: [PlayerCharacter],
        dungeon: Dungeon,
        run: DungeonRun,
        approach: RoomApproach? = nil,
        cardPool: [ContentCard] = []
    ) -> RoomResult {
        let effectiveApproach = approach
        let power = calculatePartyPower(party: party, room: room, statOverride: effectiveApproach?.primaryStat)
        let modifiedPower = Int(Double(power) * (effectiveApproach?.powerModifier ?? 1.0))
        let scaledDifficulty = Int(Double(room.difficultyRating) * (1.0 + 0.5 * Double(max(1, party.count) - 1)))
        let successChance = calculateSuccessChance(party: party, room: room, approach: effectiveApproach, dungeon: dungeon)
        
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
            let roomShare = dungeon.roomCount > 0 ? 1.0 / Double(dungeon.roomCount) : 1.0
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
            // Failed room deals damage — UNCAPPED, scales with difficulty tier
            let baseDamage = max(5, scaledDifficulty - modifiedPower)
            let riskMultiplier = effectiveApproach?.riskModifier ?? 1.0
            let tierMultiplier = dungeon.difficulty.damageMultiplier
            let riskedDamage = Int(Double(baseDamage) * riskMultiplier * tierMultiplier)
            
            // Ranger damage reduction
            let hasRanger = party.contains(where: { $0.characterClass == .ranger })
            let damageReduction = hasRanger ? CharacterClass.ranger.damageReductionMultiplier : 0.0
            // Paladin damage reduction (party-wide)
            let hasPaladin = party.contains(where: { $0.characterClass == .paladin })
            let paladinReduction = hasPaladin ? CharacterClass.paladin.damageReductionMultiplier : 0.0
            let totalReduction = min(0.75, damageReduction + paladinReduction) // Cap at 75% reduction
            hpLost = max(1, Int(Double(riskedDamage) * (1.0 - totalReduction)))
            
            // Still earn a small amount of EXP for attempting
            expEarned = Int(Double(dungeon.baseExpReward) * 0.02)
        }
        
        // Pick narrative text — use class-line-aware narratives when available
        let classLine = party.first?.characterClass?.classLine
        let narrativeText: String
        
        // In co-op, ~60% chance to use a party-aware narrative that mentions an ally
        let allies = Array(party.dropFirst())
        let usePartyNarrative = !allies.isEmpty && Double.random(in: 0...1) < 0.6
        
        if usePartyNarrative, let ally = allies.randomElement(),
           let partyText = room.encounterType.partyNarrative(
               success: success,
               approach: effectiveApproach,
               leadClassLine: classLine,
               allyName: ally.name,
               allyClassLine: ally.characterClass?.classLine
           ) {
            narrativeText = partyText
        } else if let approach = effectiveApproach {
            let narratives = success
                ? room.encounterType.successNarrative(for: approach, classLine: classLine)
                : room.encounterType.failureNarrative(for: approach, classLine: classLine)
            narrativeText = narratives.randomElement() ?? (success ? "Success!" : "Failed!")
        } else {
            let narratives = success
                ? room.encounterType.successNarratives(for: classLine)
                : room.encounterType.failureNarratives(for: classLine)
            narrativeText = narratives.randomElement() ?? (success ? "Success!" : "Failed!")
        }
        
        // Roll for card drop on successful rooms
        var cardDroppedID: String? = nil
        var cardDroppedName: String? = nil
        if success {
            let dungeonTheme = dungeon.theme.rawValue.lowercased()
            // Card pool is passed from the caller to avoid MainActor isolation
            if let droppedCard = CardDropEngine.rollDungeonCardDrop(
                dungeonTheme: dungeonTheme,
                roomEncounterType: room.encounterType.rawValue.lowercased(),
                isBossRoom: room.isBossRoom,
                cardPool: cardPool
            ) {
                cardDroppedID = droppedCard.id
                cardDroppedName = droppedCard.name
            }
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
            approachName: effectiveApproach?.name ?? "",
            cardDroppedID: cardDroppedID,
            cardDroppedName: cardDroppedName
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
    
    /// Calculate an overall success estimate for a dungeon (average across accessible rooms)
    static func overallSuccessEstimate(
        party: [PlayerCharacter],
        dungeon: Dungeon
    ) -> Double {
        // Estimate using accessible non-bonus rooms for a more stable reading
        let accessibleRooms = dungeon.rooms.filter { room in
            !room.isBonusRoom && room.canEnter(party: party)
        }
        guard !accessibleRooms.isEmpty else { return 0 }
        let total = accessibleRooms.reduce(0.0) { sum, room in
            let bestApproach = autoSelectBestApproach(party: party, room: room)
            return sum + calculateSuccessChance(party: party, room: room, approach: bestApproach)
        }
        return total / Double(accessibleRooms.count)
    }
    
    /// Auto-run an entire dungeon: resolve all rooms automatically and return the completion result
    static func autoRunDungeon(
        dungeon: Dungeon,
        run: DungeonRun,
        party: [PlayerCharacter],
        cardPool: [ContentCard] = []
    ) -> DungeonCompletionResult {
        // Guard: prevent double-resolution
        guard !run.isResolved else {
            return processDungeonCompletion(dungeon: dungeon, run: run, party: party)
        }
        run.isResolved = true
        
        // Select rooms from pool (shuffle on each run for variety)
        let selectedRooms = selectRoomsForRun(from: dungeon.rooms, party: party)
        
        // Resolve each room in sequence
        for (index, room) in selectedRooms.enumerated() {
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
                approach: approach,
                cardPool: cardPool
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
                if let cardName = result.cardDroppedName {
                    run.addFeedEntry(
                        type: .lootFound,
                        message: "Monster Card discovered: \(cardName)!"
                    )
                }
            } else {
                run.addFeedEntry(
                    type: .outcomeFail,
                    message: "Failed! Lost \(result.hpLost) HP"
                )
            }
            
            // Co-op partner flavor — context-aware based on encounter type, outcome, and ally class
            if run.isCoopRun, run.partyMemberNames.count > 1 {
                let allyIndex = Int.random(in: 1..<party.count)
                let allyName = party[allyIndex].name
                let allyClass = party[allyIndex].characterClass
                let encounter = room.encounterType
                
                let partnerMessage: String
                if result.success {
                    switch encounter {
                    case .combat:
                        let options: [String] = {
                            switch allyClass?.classLine {
                            case .warrior:
                                return [
                                    "\(allyName) charged in alongside you!",
                                    "\(allyName) landed a crushing blow from the flank!",
                                    "\(allyName) held the line while you struck!",
                                ]
                            case .mage:
                                return [
                                    "\(allyName) provided magical support from the rear!",
                                    "\(allyName) enchanted your weapon mid-fight!",
                                    "\(allyName) blasted the enemy with arcane fire!",
                                ]
                            case .archer:
                                return [
                                    "\(allyName) provided deadly covering fire!",
                                    "\(allyName) picked off stragglers from the shadows!",
                                    "\(allyName) called out the enemy's weak point!",
                                ]
                            case nil:
                                return ["\(allyName) fought bravely at your side!"]
                            }
                        }()
                        partnerMessage = options.randomElement()!
                    case .puzzle:
                        partnerMessage = [
                            "\(allyName) pointed out a clue you missed!",
                            "\(allyName)'s knowledge filled in the gaps!",
                            "\(allyName) worked the other half of the mechanism!",
                        ].randomElement()!
                    case .trap:
                        partnerMessage = [
                            "\(allyName) pulled you back from the trigger just in time!",
                            "\(allyName) spotted the mechanism first!",
                            "\(allyName) disarmed the secondary trap you didn't see!",
                        ].randomElement()!
                    case .boss:
                        partnerMessage = [
                            "\(allyName) drew the boss's attention while you struck!",
                            "\(allyName) and you combined for a devastating combo!",
                            "\(allyName) kept the pressure on from the other side!",
                        ].randomElement()!
                    case .treasure:
                        partnerMessage = [
                            "\(allyName) helped you haul the loot!",
                            "\(allyName) found a hidden compartment with more treasure!",
                        ].randomElement()!
                    }
                } else {
                    partnerMessage = [
                        "\(allyName) tried to help but the \(encounter.rawValue) was too much.",
                        "Even \(allyName)'s support wasn't enough this time.",
                        "\(allyName) took the hit alongside you. Regroup and try again.",
                    ].randomElement()!
                }
                
                run.addFeedEntry(
                    type: .partnerAction,
                    message: partnerMessage
                )
                
                // Class synergy callouts — only when the synergy actually mattered
                let enchanterMember = party.first(where: { $0.characterClass == .enchanter })
                if let enchanter = enchanterMember, result.success {
                    run.addFeedEntry(
                        type: .partnerAction,
                        message: "\(enchanter.name)'s enchantments amplified the party's power!",
                        icon: "sparkles",
                        color: "AccentPurple"
                    )
                }
                
                if !result.success {
                    let rangerMember = party.first(where: { $0.characterClass == .ranger })
                    let paladinMember = party.first(where: { $0.characterClass == .paladin })
                    if let ranger = rangerMember {
                        run.addFeedEntry(
                            type: .partnerAction,
                            message: "\(ranger.name)'s Ranger instincts softened the blow.",
                            icon: "shield.lefthalf.filled",
                            color: "AccentGreen"
                        )
                    }
                    if let paladin = paladinMember {
                        run.addFeedEntry(
                            type: .partnerAction,
                            message: "\(paladin.name)'s Paladin aura shielded the party from the worst of it.",
                            icon: "shield.checkered",
                            color: "AccentGold"
                        )
                    }
                }
                
                if result.lootDropped {
                    let tricksterMember = party.first(where: { $0.characterClass == .trickster })
                    if let trickster = tricksterMember {
                        run.addFeedEntry(
                            type: .partnerAction,
                            message: "\(trickster.name)'s Trickster luck shook loose bonus loot!",
                            icon: "wand.and.stars",
                            color: "AccentOrange"
                        )
                    }
                }
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
        
        // Calculate class loot bonus + card collection loot bonus
        let classLootBonus = party.compactMap({ $0.characterClass?.lootDropBonus }).max() ?? 0.0
        let cardLootBonus = party.first?.cachedCardLootBonus ?? 0.0
        
        // Generate loot drops
        var loot: [Equipment] = []
        if success {
            loot = LootGenerator.generateDungeonLoot(
                tier: dungeon.lootTier,
                luck: luck,
                roomResults: run.roomResults,
                dungeonDifficulty: dungeon.difficulty,
                classLootBonus: classLootBonus,
                cardLootBonus: cardLootBonus,
                playerLevel: party.first?.level
            )
            
            // Assign loot to first party member (can be distributed later)
            for item in loot {
                item.ownerID = party.first?.id
            }
        }
        
        // Co-op bond EXP
        let bondExp = (run.isCoopRun && success) ? GameEngine.bondEXPForCoopDungeon : 0
        
        // Calculate performance rating
        let performance = calculatePerformanceRating(run: run, dungeon: dungeon, party: party)
        run.performanceRating = performance.letter
        run.performanceScore = performance.score
        
        // Secret discovery roll — Luck-gated, once per completed dungeon
        var secretDiscovery = false
        var secretBonusGold = 0
        var secretBonusMaterials = 0
        var secretEquipmentDrop = false
        var secretNarrative = ""
        
        if success {
            let maxLuck = party.map { $0.effectiveStats.luck }.max() ?? 0
            let baseChance = 0.03  // 3% base
            let luckBonus = Double(maxLuck) * 0.002  // +0.2% per Luck point
            let discoveryChance = min(baseChance + luckBonus, 0.15)  // Hard cap at 15%
            
            if Double.random(in: 0...1) <= discoveryChance {
                secretDiscovery = true
                
                // Bonus gold scales with dungeon difficulty
                secretBonusGold = Int(Double(dungeon.baseGoldReward) * 2.0 * dungeon.difficulty.rewardMultiplier)
                
                // 2-3 bonus crafting materials
                secretBonusMaterials = Int.random(in: 2...3)
                
                // 25% chance at a bonus rare equipment drop
                secretEquipmentDrop = Double.random(in: 0...1) <= 0.25
                
                // Class-flavored discovery narrative
                secretNarrative = "Your keen senses uncovered a hidden treasure cache!"
                
                run.addFeedEntry(
                    type: .secretDiscovery,
                    message: "A hidden cache was discovered! Your luck revealed secret treasure!"
                )
            }
        }
        
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
            bondExpEarned: bondExp,
            performanceRating: performance.letter,
            lootMultiplier: performance.lootMultiplier,
            secretDiscovery: secretDiscovery,
            secretBonusGold: secretBonusGold,
            secretBonusMaterials: secretBonusMaterials,
            secretEquipmentDrop: secretEquipmentDrop,
            secretNarrative: secretNarrative
        )
    }
    
    // MARK: - Performance Rating
    
    /// Calculate a performance rating for a completed dungeon run.
    /// Factors: rooms cleared %, HP remaining %, stat readiness.
    /// Returns (letter: String, score: Double, lootMultiplier: Double)
    static func calculatePerformanceRating(
        run: DungeonRun,
        dungeon: Dungeon,
        party: [PlayerCharacter]
    ) -> (letter: String, score: Double, lootMultiplier: Double) {
        let roomsClearedRatio = dungeon.roomCount > 0
            ? Double(run.roomResults.filter { $0.success }.count) / Double(dungeon.roomCount)
            : 0.0
        
        let hpRatio = run.maxPartyHP > 0
            ? Double(max(0, run.partyHP)) / Double(run.maxPartyHP)
            : 0.0
        
        let statReadiness = calculateStatReadiness(party: party, dungeon: dungeon)
        
        // Weighted score: 50% rooms cleared, 30% HP remaining, 20% stat readiness
        let score = roomsClearedRatio * 0.50 + hpRatio * 0.30 + statReadiness * 0.20
        
        let letter: String
        let lootMultiplier: Double
        switch score {
        case 0.95...:
            letter = "S"
            lootMultiplier = 1.50
        case 0.85...:
            letter = "A"
            lootMultiplier = 1.25
        case 0.70...:
            letter = "B"
            lootMultiplier = 1.10
        case 0.50...:
            letter = "C"
            lootMultiplier = 1.00
        case 0.30...:
            letter = "D"
            lootMultiplier = 0.80
        default:
            letter = "F"
            lootMultiplier = 0.50
        }
        
        return (letter, score, lootMultiplier)
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

// MARK: - Party Proxy

/// Generates lightweight simulated party member characters for co-op dungeons,
/// built from cached party member data on the player's character.
/// Supports 1-3 ally proxies (2-4 member party).
enum PartnerProxy {
    /// Create a simulated partner from legacy cached data on the player character
    static func from(character: PlayerCharacter) -> PlayerCharacter? {
        guard character.hasPartner,
              let partnerName = character.partnerName,
              let partnerLevel = character.partnerLevel else {
            return nil
        }
        
        return buildProxy(
            name: partnerName,
            level: partnerLevel,
            characterClass: character.partnerClass,
            statTotal: character.partnerStatTotal,
            memberID: character.partnerCharacterID
        )
    }
    
    /// Create proxy characters for ALL party members (excluding self).
    /// Returns 0-3 proxies depending on party size.
    static func allPartyProxies(for character: PlayerCharacter) -> [PlayerCharacter] {
        let members = character.partyMembers
        guard !members.isEmpty else {
            // Legacy single-partner fallback
            if let partner = from(character: character) {
                return [partner]
            }
            return []
        }
        
        return members.compactMap { member in
            buildProxy(
                name: member.name,
                level: member.level,
                characterClass: member.characterClass,
                statTotal: member.statTotal,
                memberID: member.id
            )
        }
    }
    
    /// Build a single proxy character from member data
    private static func buildProxy(
        name: String,
        level: Int,
        characterClass: CharacterClass?,
        statTotal: Int?,
        memberID: UUID?
    ) -> PlayerCharacter {
        let totalStats = statTotal ?? (level * 5 + 25)
        
        // Distribute stats based on class primary stat weighting
        let baseStat = totalStats / 7
        let remainder = totalStats - (baseStat * 7)
        
        let stats = Stats(
            strength: baseStat,
            wisdom: baseStat,
            charisma: baseStat,
            dexterity: baseStat,
            luck: baseStat,
            defense: baseStat
        )
        
        // Give extra points to primary stat
        if let primaryStat = characterClass?.primaryStat {
            stats.increase(primaryStat, by: remainder + 2)
        } else {
            stats.increase(.strength, by: remainder)
        }
        
        let proxy = PlayerCharacter(name: name, stats: stats)
        proxy.level = level
        proxy.characterClass = characterClass
        
        // Give proxy a synthetic ID matching the cached member ID
        if let memberID = memberID {
            proxy.id = memberID
        }
        
        return proxy
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
    let performanceRating: String
    let lootMultiplier: Double
    
    // Secret discovery (Luck-gated)
    let secretDiscovery: Bool
    let secretBonusGold: Int
    let secretBonusMaterials: Int
    let secretEquipmentDrop: Bool
    let secretNarrative: String
    
    // MARK: - Character Progress Snapshot (set by the view after reward application)
    
    /// Character level before rewards
    var characterLevel: Int = 1
    
    /// EXP bar progress before rewards (0.0–1.0)
    var expProgressBefore: Double = 0
    
    /// EXP bar progress after rewards (0.0–1.0)
    var expProgressAfter: Double = 0
    
    /// Gold total before rewards
    var goldBefore: Int = 0
    
    /// Gold total after rewards
    var goldAfter: Int = 0
    
    /// All character effective stats after rewards
    var currentStats: [StatType: Int] = [:]
    
    /// Content card IDs that dropped during this dungeon run
    var cardDropIDs: [String] {
        roomResults.compactMap { $0.cardDroppedID }
    }
    
    /// Card names that dropped during this dungeon run
    var cardDropNames: [String] {
        roomResults.compactMap { $0.cardDroppedName }
    }
    
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
        bondExpEarned: Int = 0,
        performanceRating: String = "C",
        lootMultiplier: Double = 1.0,
        secretDiscovery: Bool = false,
        secretBonusGold: Int = 0,
        secretBonusMaterials: Int = 0,
        secretEquipmentDrop: Bool = false,
        secretNarrative: String = ""
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
        self.performanceRating = performanceRating
        self.lootMultiplier = lootMultiplier
        self.secretDiscovery = secretDiscovery
        self.secretBonusGold = secretBonusGold
        self.secretBonusMaterials = secretBonusMaterials
        self.secretEquipmentDrop = secretEquipmentDrop
        self.secretNarrative = secretNarrative
    }
    
    var clearPercentage: Double {
        guard totalRooms > 0 else { return 0 }
        return Double(roomsCleared) / Double(totalRooms)
    }
}

// MARK: - Secret Discovery Narratives

/// Generates flavored narrative text for the Luck-gated secret discovery
enum SecretDiscoveryNarratives {
    
    /// Get a random narrative for the secret discovery based on dungeon theme and class line
    static func random(for theme: DungeonTheme, classLine: ClassLine?) -> String {
        let pool = narratives(for: theme, classLine: classLine)
        return pool.randomElement() ?? "A hidden cache of treasure glimmers in the shadows!"
    }
    
    private static func narratives(for theme: DungeonTheme, classLine: ClassLine?) -> [String] {
        // Theme-specific discovery flavor
        let themeNarrative: [String]
        switch theme {
        case .cave:
            themeNarrative = [
                "Behind a loose boulder, a secret alcove glitters with forgotten treasure!",
                "Your torchlight catches something hidden deep in a crack — a secret cache!"
            ]
        case .ruins:
            themeNarrative = [
                "An ancient vault, sealed for centuries, opens to reveal its secrets!",
                "A crumbling wall reveals a hidden chamber filled with relics of a lost age!"
            ]
        case .forest:
            themeNarrative = [
                "Beneath the roots of an ancient tree, a woodland cache sparkles with treasure!",
                "A hollow trunk conceals a stash left by forest spirits — luck led you here!"
            ]
        case .fortress:
            themeNarrative = [
                "A false floor in the commander's quarters reveals a hidden war chest!",
                "Behind a banner on the wall, a secret compartment holds the fortress's true treasure!"
            ]
        case .volcano:
            themeNarrative = [
                "Cooling lava reveals an obsidian chest, its contents preserved by fire magic!",
                "In a pocket of cooled magma, crystallized treasure waits for a lucky soul!"
            ]
        case .abyss:
            themeNarrative = [
                "A rift in reality opens briefly — beyond it, treasure from another plane!",
                "The void whispers your name and offers a fragment of its infinite hoard!"
            ]
        }
        
        // Class-line-specific discovery flavor
        guard let classLine = classLine else { return themeNarrative }
        
        let classNarrative: [String]
        switch classLine {
        case .warrior:
            classNarrative = [
                "Your battle-hardened instincts guided you to a hidden cache most would walk right past!",
                "A warrior's eye for tactical ground reveals a secret stash concealed in the shadows!",
                "Years of clearing battlefields taught you to spot treasure where others see rubble!"
            ]
        case .mage:
            classNarrative = [
                "Your arcane sensitivity detects a magical disturbance — a cloaked treasure cache!",
                "Faint magical resonance, invisible to the untrained, reveals a hidden fortune!",
                "Your mystic attunement uncovers treasure warded from mundane eyes!"
            ]
        case .archer:
            classNarrative = [
                "Your keen eyes catch a subtle glint others would miss — treasure hidden in plain sight!",
                "A tracker's instinct notices disturbed ground — beneath it, a secret hoard!",
                "Sharp observation reveals a camouflaged cache that would fool anyone less perceptive!"
            ]
        }
        
        return themeNarrative + classNarrative
    }
}
