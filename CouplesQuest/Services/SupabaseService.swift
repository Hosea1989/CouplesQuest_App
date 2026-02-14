import Foundation
import Supabase

/// Centralized Supabase client and service methods for Swords & Chores.
/// Reads credentials from Info.plist (injected via Secrets.xcconfig at build time).
@MainActor
final class SupabaseService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = SupabaseService()
    
    // MARK: - Client
    
    let client: SupabaseClient
    
    // MARK: - Published State
    
    @Published var isAuthenticated = false
    @Published var currentUserID: UUID?
    @Published var currentProfile: Profile?
    
    // MARK: - Init
    
    private init() {
        guard let urlString = Bundle.main.infoDictionary?["SupabaseURL"] as? String,
              let url = URL(string: urlString),
              let anonKey = Bundle.main.infoDictionary?["SupabaseAnonKey"] as? String else {
            fatalError("Missing Supabase credentials in Info.plist. Ensure Secrets.xcconfig is configured.")
        }
        
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: anonKey,
            options: .init(
                auth: .init(
                    flowType: .pkce,
                    autoRefreshToken: true,
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
        // Session restore is driven by AuthGateView.task — not here —
        // to avoid a race between two concurrent restoreSession() calls.
    }
    
    // MARK: - Auth
    
    /// Restore session from keychain on app launch.
    func restoreSession() async {
        do {
            let session = try await client.auth.session
            self.currentUserID = session.user.id
            self.isAuthenticated = true
            await fetchProfile()
        } catch {
            self.isAuthenticated = false
            self.currentUserID = nil
        }
    }
    
    /// Sign up with email and password.
    /// Returns `true` if the user can proceed immediately (no email verification),
    /// or `false` if email confirmation is required first.
    @discardableResult
    func signUp(email: String, password: String) async throws -> Bool {
        let response = try await client.auth.signUp(email: email, password: password)
        
        // If the user already has a confirmed email, they can proceed.
        // Otherwise Supabase email-confirmation is enabled — tell the UI.
        if response.user.confirmedAt != nil {
            self.currentUserID = response.user.id
            self.isAuthenticated = true
            // Profile is auto-created by the database trigger
            // Give the trigger a moment to run, then fetch
            try? await Task.sleep(for: .milliseconds(500))
            await fetchProfile()
            return true
        } else {
            // Email confirmation pending — do NOT mark authenticated yet.
            return false
        }
    }
    
    /// Sign in with email and password.
    func signIn(email: String, password: String) async throws {
        let session = try await client.auth.signIn(email: email, password: password)
        self.currentUserID = session.user.id
        self.isAuthenticated = true
        await fetchProfile()
    }
    
    /// Sign in with Apple using an identity token from ASAuthorization.
    func signInWithApple(idToken: String, nonce: String) async throws {
        let session = try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
        self.currentUserID = session.user.id
        self.isAuthenticated = true
        // Give the database trigger a moment to create the profile row
        try? await Task.sleep(for: .milliseconds(500))
        await fetchProfile()
    }
    
    /// Sign out and clear all local state.
    func signOut() async throws {
        // Disassociate the device from the user in OneSignal
        PushNotificationService.shared.logout()
        
        try await client.auth.signOut()
        self.isAuthenticated = false
        self.currentUserID = nil
        self.currentProfile = nil
    }
    
    /// Send a password-reset email to the given address.
    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }
    
    /// Delete the current user's account.
    /// This calls a Supabase Edge Function `delete-user` that uses the service
    /// role to remove the auth user (and cascades to profiles / equipment / etc.).
    /// If no Edge Function is deployed yet, it falls back to signing out only.
    func deleteAccount() async throws {
        guard let userID = currentUserID else { return }
        
        do {
            // Attempt to invoke the Edge Function
            try await client.functions.invoke(
                "delete-user",
                options: .init(body: ["user_id": userID.uuidString])
            )
        } catch {
            // If the Edge Function is not deployed, log and continue.
            // The user's Supabase auth row will remain but local data is wiped.
            print("delete-user Edge Function unavailable, signing out only: \(error)")
        }
        
        // Clear auth session
        try await client.auth.signOut()
        self.isAuthenticated = false
        self.currentUserID = nil
        self.currentProfile = nil
    }
    
    // MARK: - Profile
    
    /// Fetch the current user's profile.
    /// If no profile row exists (e.g. trigger didn't fire, or account was
    /// deleted and re-created), we create one automatically.
    func fetchProfile() async {
        guard let userID = currentUserID else {
            print("⚠️ fetchProfile: No currentUserID, skipping")
            return
        }
        do {
            let rows: [Profile] = try await client
                .from("profiles")
                .select()
                .eq("id", value: userID.uuidString)
                .execute()
                .value
            
            if let profile = rows.first {
                self.currentProfile = profile
                print("✅ fetchProfile: \(profile.characterName ?? "no name"), partnerCode=\(profile.partnerCode ?? "nil"), partnerID=\(profile.partnerID?.uuidString.prefix(8) ?? "nil")")
            } else {
                // No profile row — create one with a generated partner code
                print("⚠️ fetchProfile: No profile row found, creating one...")
                try await ensureProfileExists(userID: userID)
            }
        } catch {
            print("❌ fetchProfile failed: \(error)")
        }
    }
    
    /// Create a profile row for the current user if one doesn't exist.
    /// Generates a random 6-character partner code (matching the DB trigger logic).
    private func ensureProfileExists(userID: UUID) async throws {
        // Get the user's email from the auth session
        let email = try? await client.auth.session.user.email
        
        // Generate a 6-char uppercase hex code (same logic as the SQL trigger)
        let code = generatePartnerCode()
        
        struct ProfileInsert: Codable {
            let id: String
            let email: String?
            let partner_code: String
        }
        
        let insert = ProfileInsert(
            id: userID.uuidString,
            email: email,
            partner_code: code
        )
        
        try await client
            .from("profiles")
            .insert(insert)
            .execute()
        
        print("✅ ensureProfileExists: Created profile with partner_code=\(code)")
        
        // Now fetch the newly created profile
        let rows: [Profile] = try await client
            .from("profiles")
            .select()
            .eq("id", value: userID.uuidString)
            .execute()
            .value
        
        if let profile = rows.first {
            self.currentProfile = profile
            print("✅ fetchProfile (after create): partnerCode=\(profile.partnerCode ?? "nil")")
        }
    }
    
    /// Generate a random 6-character uppercase alphanumeric partner code.
    private func generatePartnerCode() -> String {
        let chars = "ABCDEF0123456789"
        return String((0..<6).map { _ in chars.randomElement()! })
    }
    
    /// Update the current user's character info in the cloud profile.
    func updateProfile(characterName: String?, characterClass: String?, level: Int?, avatarName: String?) async throws {
        guard let userID = currentUserID else { return }
        
        var updates: [String: AnyJSON] = [:]
        if let name = characterName { updates["character_name"] = .string(name) }
        if let cls = characterClass { updates["character_class"] = .string(cls) }
        if let lvl = level { updates["level"] = .integer(lvl) }
        if let avatar = avatarName { updates["avatar_name"] = .string(avatar) }
        
        guard !updates.isEmpty else { return }
        
        try await client
            .from("profiles")
            .update(updates)
            .eq("id", value: userID.uuidString)
            .execute()
        
        await fetchProfile()
    }
    
    // MARK: - Character Data Sync
    
    /// Push the full character snapshot to the cloud as JSONB.
    func syncCharacterData(_ character: PlayerCharacter) async throws {
        guard let userID = currentUserID else {
            print("⚠️ syncCharacterData: No currentUserID, skipping")
            return
        }
        
        let snapshot = character.toSnapshot()
        let payload = CharacterSyncPayload(
            characterName: character.name,
            characterClass: character.characterClass?.rawValue,
            level: character.level,
            avatarName: character.avatarIcon,
            characterData: snapshot
        )
        
        print("📡 Syncing character to cloud: \(character.name) Lv.\(character.level) for user \(userID.uuidString.prefix(8))…")
        
        try await client
            .from("profiles")
            .update(payload)
            .eq("id", value: userID.uuidString)
            .execute()
        
        print("✅ syncCharacterData succeeded")
    }
    
    /// Fetch the character snapshot from the cloud profile.
    /// Returns nil if no character data has been synced yet.
    func fetchCharacterData() async throws -> CharacterSnapshot? {
        guard let userID = currentUserID else { return nil }
        
        let row: CharacterDataRow = try await client
            .from("profiles")
            .select("character_data")
            .eq("id", value: userID.uuidString)
            .single()
            .execute()
            .value
        
        return row.characterData
    }
    
    // MARK: - Character Snapshot Sync (from SyncManager)
    
    /// Push a CharacterSnapshot directly to cloud (used by SyncManager queue).
    func syncCharacterSnapshot(_ snapshot: CharacterSnapshot) async throws {
        guard let userID = currentUserID else { return }
        
        struct SnapshotPayload: Encodable {
            let characterName: String
            let characterClass: String?
            let level: Int
            let avatarName: String
            let characterData: CharacterSnapshot
            
            enum CodingKeys: String, CodingKey {
                case characterName = "character_name"
                case characterClass = "character_class"
                case level
                case avatarName = "avatar_name"
                case characterData = "character_data"
            }
        }
        
        let payload = SnapshotPayload(
            characterName: snapshot.name,
            characterClass: snapshot.characterClass,
            level: snapshot.level,
            avatarName: snapshot.avatarIcon,
            characterData: snapshot
        )
        
        try await client
            .from("profiles")
            .update(payload)
            .eq("id", value: userID.uuidString)
            .execute()
    }
    
    // MARK: - Player Achievements Sync
    
    /// Upsert an achievement to the cloud.
    func syncAchievement(_ data: AchievementSyncData) async throws {
        try await client
            .from("player_achievements")
            .upsert(data, onConflict: "player_id,tracking_key")
            .execute()
    }
    
    /// Fetch all achievements for the current user from the cloud.
    func fetchAchievements() async throws -> [CloudAchievement] {
        guard let userID = currentUserID else { return [] }
        return try await client
            .from("player_achievements")
            .select("tracking_key,current_value,is_unlocked,unlocked_at")
            .eq("player_id", value: userID.uuidString)
            .execute()
            .value
    }
    
    // MARK: - Player Tasks Sync
    
    /// Upsert a task to the cloud.
    func syncTask(_ data: TaskSyncData) async throws {
        try await client
            .from("player_tasks")
            .upsert(data, onConflict: "player_id,local_id")
            .execute()
    }
    
    // MARK: - Player Goals Sync
    
    /// Upsert a goal to the cloud.
    func syncGoal(_ data: GoalSyncData) async throws {
        try await client
            .from("player_goals")
            .upsert(data, onConflict: "player_id,local_id")
            .execute()
    }
    
    // MARK: - Player Mood Entries Sync
    
    /// Upsert a mood entry to the cloud.
    func syncMoodEntry(_ data: MoodSyncData) async throws {
        try await client
            .from("player_mood_entries")
            .upsert(data, onConflict: "player_id,local_id")
            .execute()
    }
    
    // MARK: - Player Daily State Sync
    
    /// Sync a character's daily state to the cloud.
    func syncDailyState(_ character: PlayerCharacter) async throws {
        guard let userID = currentUserID else { return }
        let data = DailyStateSyncData(
            playerID: userID,
            tasksCompletedToday: character.tasksCompletedToday,
            dutiesCompletedToday: character.dutiesCompletedToday,
            arenaAttemptsToday: character.arenaAttemptsToday,
            lastDailyReset: character.lastDailyReset,
            lastActiveAt: character.lastActiveAt,
            lastMeditationDate: character.lastMeditationDate,
            lastMoodDate: character.lastMoodDate,
            lastArenaDate: character.lastArenaDate,
            currentStreak: character.currentStreak,
            longestStreak: character.longestStreak,
            moodStreak: character.moodStreak,
            meditationStreak: character.meditationStreak
        )
        try await syncDailyStateData(data)
    }
    
    /// Upsert daily state data to the cloud (used by SyncManager).
    func syncDailyStateData(_ data: DailyStateSyncData) async throws {
        try await client
            .from("player_daily_state")
            .upsert(data, onConflict: "player_id")
            .execute()
    }
    
    /// Fetch daily state from cloud.
    func fetchDailyState() async throws -> CloudDailyState? {
        guard let userID = currentUserID else { return nil }
        let rows: [CloudDailyState] = try await client
            .from("player_daily_state")
            .select()
            .eq("player_id", value: userID.uuidString)
            .execute()
            .value
        return rows.first
    }
    
    // MARK: - Arena / Dungeon / Mission History Sync
    
    /// Insert an arena run record.
    func syncArenaRun(_ data: ArenaRunSyncData) async throws {
        try await client
            .from("player_arena_runs")
            .insert(data)
            .execute()
    }
    
    /// Insert a dungeon run record.
    func syncDungeonRun(_ data: DungeonRunSyncData) async throws {
        try await client
            .from("player_dungeon_runs")
            .insert(data)
            .execute()
    }
    
    /// Insert a mission history record.
    func syncMissionHistory(_ data: MissionHistorySyncData) async throws {
        try await client
            .from("player_mission_history")
            .insert(data)
            .execute()
    }
    
    // MARK: - Bond → Party Sync
    
    /// Sync a Bond to the Supabase parties table (supports 1-4 members).
    func syncBondToParty(_ bond: Bond, playerID: UUID) async throws {
        struct PartyUpsert: Encodable {
            let createdBy: UUID
            let memberIDs: [UUID]
            let bondLevel: Int
            let bondExp: Int
            let partyStreakDays: Int
            
            enum CodingKeys: String, CodingKey {
                case createdBy = "created_by"
                case memberIDs = "member_ids"
                case bondLevel = "bond_level"
                case bondExp = "bond_exp"
                case partyStreakDays = "party_streak_days"
            }
        }
        
        // Use the full memberIDs array from bond (1-4 members)
        let memberIDs = bond.memberIDs.isEmpty ? [playerID, bond.partnerID] : bond.memberIDs
        let upsert = PartyUpsert(
            createdBy: playerID,
            memberIDs: memberIDs,
            bondLevel: bond.bondLevel,
            bondExp: bond.bondEXP,
            partyStreakDays: bond.partyStreakDays
        )
        
        if let existingPartyID = bond.supabasePartyID {
            // Update existing party row
            try await client
                .from("parties")
                .update(upsert)
                .eq("id", value: existingPartyID.uuidString)
                .execute()
        } else {
            // Insert new party row
            let result = try await client
                .from("parties")
                .insert(upsert)
                .select()
                .single()
                .execute()
            
            // Save the returned party ID back to the bond
            if let row = try? JSONDecoder().decode(PartyRow.self, from: result.data) {
                bond.supabasePartyID = row.id
            }
        }
    }
    
    /// Post an event to the party_feed table
    func postPartyFeedEvent(partyID: UUID, actorID: UUID, eventType: String, message: String, metadata: [String: String] = [:]) async throws {
        struct FeedInsert: Encodable {
            let partyID: UUID
            let actorID: UUID
            let eventType: String
            let message: String
            let metadata: [String: String]
            
            enum CodingKeys: String, CodingKey {
                case partyID = "party_id"
                case actorID = "actor_id"
                case eventType = "event_type"
                case message
                case metadata
            }
        }
        
        let insert = FeedInsert(
            partyID: partyID,
            actorID: actorID,
            eventType: eventType,
            message: message,
            metadata: metadata
        )
        
        try await client
            .from("party_feed")
            .insert(insert)
            .execute()
    }
    
    /// Lightweight decoder for the party row response
    private struct PartyRow: Decodable {
        let id: UUID
    }
    
    // MARK: - Account Data Deletion (Enhanced)
    
    /// Delete all player data from sync tables (for account deletion).
    func deleteAllPlayerData() async throws {
        guard let userID = currentUserID else { return }
        let uid = userID.uuidString
        
        // Delete from all player sync tables
        try await client.from("player_achievements").delete().eq("player_id", value: uid).execute()
        try await client.from("player_tasks").delete().eq("player_id", value: uid).execute()
        try await client.from("player_goals").delete().eq("player_id", value: uid).execute()
        try await client.from("player_daily_state").delete().eq("player_id", value: uid).execute()
        try await client.from("player_mood_entries").delete().eq("player_id", value: uid).execute()
        try await client.from("player_arena_runs").delete().eq("player_id", value: uid).execute()
        try await client.from("player_dungeon_runs").delete().eq("player_id", value: uid).execute()
        try await client.from("player_mission_history").delete().eq("player_id", value: uid).execute()
        
        // Delete from existing tables
        try await client.from("equipment").delete().eq("owner_id", value: uid).execute()
        try await client.from("consumables").delete().eq("owner_id", value: uid).execute()
        try await client.from("crafting_materials").delete().eq("owner_id", value: uid).execute()
        try await client.from("partner_tasks").delete().eq("created_by", value: uid).execute()
        try await client.from("partner_tasks").delete().eq("assigned_to", value: uid).execute()
        
        print("✅ All player data deleted from Supabase")
    }
    
    // MARK: - Partner Pairing
    
    /// Find a user by their partner code.
    func findPartnerByCode(_ code: String) async throws -> Profile? {
        let profiles: [Profile] = try await client
            .from("profiles")
            .select()
            .eq("partner_code", value: code.uppercased())
            .execute()
            .value
        return profiles.first
    }
    
    /// Send a partner request to the user with the given partner code.
    func sendPartnerRequest(toCode code: String) async throws {
        guard let myID = currentUserID else { return }
        
        // Look up who this code belongs to
        guard let targetProfile = try await findPartnerByCode(code) else {
            throw SupabaseServiceError.partnerNotFound
        }
        
        guard targetProfile.id != myID else {
            throw SupabaseServiceError.cannotPairWithSelf
        }
        
        // Insert the request
        let request = PartnerRequestInsert(
            fromUserID: myID,
            toUserID: targetProfile.id
        )
        
        try await client
            .from("partner_requests")
            .insert(request)
            .execute()
        
        // Send a push notification to the target user about the partner request
        let senderName = currentProfile?.characterName ?? "Someone"
        await PushNotificationService.shared.notifyPartner(
            type: "pair_request",
            title: "Partner Request!",
            body: "\(senderName) wants to pair with you in Swords & Chores!"
        )
    }
    
    /// Fetch incoming partner requests for the current user.
    func fetchIncomingRequests() async throws -> [PartnerRequest] {
        guard let userID = currentUserID else { return [] }
        return try await client
            .from("partner_requests")
            .select()
            .eq("to_user_id", value: userID.uuidString)
            .eq("status", value: "pending")
            .execute()
            .value
    }
    
    /// Fetch outgoing partner requests for the current user.
    func fetchOutgoingRequests() async throws -> [PartnerRequest] {
        guard let userID = currentUserID else { return [] }
        return try await client
            .from("partner_requests")
            .select()
            .eq("from_user_id", value: userID.uuidString)
            .eq("status", value: "pending")
            .execute()
            .value
    }
    
    /// Accept a partner request — links both profiles.
    func acceptPartnerRequest(_ requestID: UUID) async throws {
        guard let myID = currentUserID else { return }
        
        // Update request status
        let requests: [PartnerRequest] = try await client
            .from("partner_requests")
            .update(["status": "accepted"])
            .eq("id", value: requestID.uuidString)
            .select()
            .execute()
            .value
        
        guard let request = requests.first else { return }
        
        // Link both profiles
        try await client
            .from("profiles")
            .update(["partner_id": AnyJSON.string(request.fromUserID.uuidString)])
            .eq("id", value: myID.uuidString)
            .execute()
        
        try await client
            .from("profiles")
            .update(["partner_id": AnyJSON.string(myID.uuidString)])
            .eq("id", value: request.fromUserID.uuidString)
            .execute()
        
        await fetchProfile()
    }
    
    /// Reject a partner request.
    func rejectPartnerRequest(_ requestID: UUID) async throws {
        try await client
            .from("partner_requests")
            .update(["status": "rejected"])
            .eq("id", value: requestID.uuidString)
            .execute()
    }
    
    /// Unlink from current partner.
    func unlinkPartner() async throws {
        guard let myID = currentUserID,
              let partnerID = currentProfile?.partnerID else { return }
        
        // Clear both sides
        try await client
            .from("profiles")
            .update(["partner_id": AnyJSON.null])
            .eq("id", value: myID.uuidString)
            .execute()
        
        try await client
            .from("profiles")
            .update(["partner_id": AnyJSON.null])
            .eq("id", value: partnerID.uuidString)
            .execute()
        
        await fetchProfile()
    }
    
    // MARK: - Partner Interactions
    
    /// Send an interaction (nudge, kudos, challenge, etc.) to partner.
    func sendInteraction(type: String, message: String?) async throws {
        guard let myID = currentUserID,
              let partnerID = currentProfile?.partnerID else { return }
        
        let interaction = InteractionInsert(
            fromUserID: myID,
            toUserID: partnerID,
            type: type,
            message: message
        )
        
        try await client
            .from("partner_interactions")
            .insert(interaction)
            .execute()
    }
    
    /// Fetch recent interactions for the current user (sent + received).
    func fetchInteractions(limit: Int = 20) async throws -> [CloudInteraction] {
        guard let userID = currentUserID else { return [] }
        
        let sent: [CloudInteraction] = try await client
            .from("partner_interactions")
            .select()
            .eq("from_user_id", value: userID.uuidString)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        
        let received: [CloudInteraction] = try await client
            .from("partner_interactions")
            .select()
            .eq("to_user_id", value: userID.uuidString)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        
        return (sent + received).sorted { $0.createdAt > $1.createdAt }
    }
    
    /// Fetch the partner's profile (legacy single-partner path).
    func fetchPartnerProfile() async throws -> Profile? {
        guard let partnerID = currentProfile?.partnerID else { return nil }
        let profile: Profile = try await client
            .from("profiles")
            .select()
            .eq("id", value: partnerID.uuidString)
            .single()
            .execute()
            .value
        return profile
    }
    
    /// Fetch any profile by UUID (used for party member data refresh).
    func fetchProfile(byID profileID: UUID) async throws -> Profile? {
        let profile: Profile = try await client
            .from("profiles")
            .select()
            .eq("id", value: profileID.uuidString)
            .single()
            .execute()
            .value
        return profile
    }
    
    // MARK: - Partner Task Sync
    
    /// Push a partner-assigned task to the cloud.
    func pushPartnerTask(_ task: GameTask) async throws {
        guard let userID = currentUserID,
              let partnerID = currentProfile?.partnerID else { return }
        
        let row = CloudPartnerTaskInsert(
            createdBy: userID,
            assignedTo: partnerID,
            title: task.title,
            description: task.taskDescription,
            category: task.category.rawValue,
            partnerMessage: task.partnerMessage,
            verificationType: task.verificationType.rawValue,
            isOnDutyBoard: task.isOnDutyBoard,
            dueDate: task.dueDate,
            status: task.status.rawValue
        )
        
        // Insert and get back the generated cloud ID
        let inserted: [CloudPartnerTask] = try await client
            .from("partner_tasks")
            .insert(row)
            .select()
            .execute()
            .value
        
        // Store the cloud ID on the local task for future sync
        if let cloudRow = inserted.first {
            task.cloudID = cloudRow.id.uuidString
        }
        
        print("✅ Partner task pushed to cloud: \(task.title)")
    }
    
    /// Fetch incoming partner tasks assigned to the current user.
    /// Returns tasks that are still pending (not yet pulled into local SwiftData).
    func fetchIncomingPartnerTasks() async throws -> [CloudPartnerTask] {
        guard let userID = currentUserID else { return [] }
        
        return try await client
            .from("partner_tasks")
            .select()
            .eq("assigned_to", value: userID.uuidString)
            .in("status", values: ["pending", "in_progress"])
            .order("created_at", ascending: false)
            .execute()
            .value
    }
    
    /// Fetch all partner tasks created by the current user (to see completions/confirmations).
    func fetchOutgoingPartnerTasks() async throws -> [CloudPartnerTask] {
        guard let userID = currentUserID else { return [] }
        
        return try await client
            .from("partner_tasks")
            .select()
            .eq("created_by", value: userID.uuidString)
            .order("created_at", ascending: false)
            .limit(50)
            .execute()
            .value
    }
    
    /// Update a partner task's status in the cloud.
    func updatePartnerTaskStatus(
        taskID: UUID,
        status: String,
        completedAt: Date? = nil,
        partnerConfirmed: Bool? = nil,
        partnerDisputeReason: String? = nil
    ) async throws {
        var updates: [String: AnyJSON] = [
            "status": .string(status)
        ]
        
        if let completedAt = completedAt {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            updates["completed_at"] = .string(formatter.string(from: completedAt))
        }
        
        if let confirmed = partnerConfirmed {
            updates["partner_confirmed"] = .bool(confirmed)
        }
        
        if let reason = partnerDisputeReason {
            updates["partner_dispute_reason"] = .string(reason)
        }
        
        try await client
            .from("partner_tasks")
            .update(updates)
            .eq("id", value: taskID.uuidString)
            .execute()
        
        print("✅ Partner task status updated: \(taskID.uuidString.prefix(8)) → \(status)")
    }
    
    // MARK: - Realtime Subscriptions
    
    /// Subscribe to new partner tasks assigned to the current user.
    /// Returns a Realtime channel that can be removed later.
    func subscribeToPartnerTasks(onInsert: @escaping (CloudPartnerTask) -> Void) async -> RealtimeChannelV2? {
        guard let userID = currentUserID else { return nil }
        
        let channel = client.realtimeV2.channel("partner-tasks-\(userID.uuidString.prefix(8))")
        
        let insertions = await channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "partner_tasks",
            filter: "assigned_to=eq.\(userID.uuidString)"
        )
        
        await channel.subscribe()
        
        Task {
            for await insertion in insertions {
                do {
                    let task = try insertion.decodeRecord(as: CloudPartnerTask.self, decoder: JSONDecoder.supabaseDecoder)
                    await MainActor.run {
                        onInsert(task)
                    }
                } catch {
                    print("⚠️ Failed to decode realtime partner task: \(error)")
                }
            }
        }
        
        print("📡 Subscribed to partner_tasks realtime for user \(userID.uuidString.prefix(8))")
        return channel
    }
    
    /// Subscribe to changes on the partner's profile (level ups, stats, etc.).
    func subscribeToPartnerProfile(onUpdate: @escaping (Profile) -> Void) async -> RealtimeChannelV2? {
        guard let partnerID = currentProfile?.partnerID else { return nil }
        
        let channel = client.realtimeV2.channel("partner-profile-\(partnerID.uuidString.prefix(8))")
        
        let updates = await channel.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "profiles",
            filter: "id=eq.\(partnerID.uuidString)"
        )
        
        await channel.subscribe()
        
        Task {
            for await update in updates {
                do {
                    let profile = try update.decodeRecord(as: Profile.self, decoder: JSONDecoder.supabaseDecoder)
                    await MainActor.run {
                        onUpdate(profile)
                    }
                } catch {
                    print("⚠️ Failed to decode realtime partner profile: \(error)")
                }
            }
        }
        
        print("📡 Subscribed to partner profile realtime for partner \(partnerID.uuidString.prefix(8))")
        return channel
    }
    
    /// Subscribe to changes on the current user's own profile (detects partner_id changes).
    /// This is critical for the request sender — when their request is accepted,
    /// their profile's partner_id gets set by the accepter, and this subscription fires.
    func subscribeToOwnProfile(onUpdate: @escaping (Profile) -> Void) async -> RealtimeChannelV2? {
        guard let userID = currentUserID else { return nil }
        
        let channel = client.realtimeV2.channel("own-profile-\(userID.uuidString.prefix(8))")
        
        let updates = await channel.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "profiles",
            filter: "id=eq.\(userID.uuidString)"
        )
        
        await channel.subscribe()
        
        Task {
            for await update in updates {
                do {
                    let profile = try update.decodeRecord(as: Profile.self, decoder: JSONDecoder.supabaseDecoder)
                    await MainActor.run {
                        self.currentProfile = profile
                        onUpdate(profile)
                    }
                } catch {
                    print("⚠️ Failed to decode realtime own profile update: \(error)")
                }
            }
        }
        
        print("📡 Subscribed to own profile realtime for user \(userID.uuidString.prefix(8))")
        return channel
    }
    
    /// Unsubscribe from a realtime channel.
    func unsubscribeChannel(_ channel: RealtimeChannelV2?) async {
        guard let channel = channel else { return }
        await channel.unsubscribe()
    }
    
    // MARK: - Dungeon Invites
    
    /// Create a dungeon invite and a response row for every party member.
    /// Returns the newly created invite ID.
    func createDungeonInvite(partyID: UUID, dungeonID: UUID, dungeonName: String, memberIDs: [UUID]) async throws -> UUID {
        guard let hostID = currentUserID else { throw SupabaseDungeonInviteError.notAuthenticated }
        
        // 1. Insert the invite
        let invite = DungeonInviteInsert(
            partyID: partyID,
            hostUserID: hostID,
            dungeonID: dungeonID,
            dungeonName: dungeonName,
            status: "waiting"
        )
        
        let result = try await client
            .from("dungeon_invites")
            .insert(invite)
            .select()
            .single()
            .execute()
        
        let row = try JSONDecoder.supabaseDecoder.decode(DungeonInviteRow.self, from: result.data)
        let inviteID = row.id
        
        // 2. Insert a response row for every member (host = auto-accepted)
        var responses: [DungeonInviteResponseInsert] = []
        for memberID in memberIDs {
            let isHost = memberID == hostID
            responses.append(DungeonInviteResponseInsert(
                inviteID: inviteID,
                userID: memberID,
                response: isHost ? "accepted" : "pending",
                respondedAt: isHost ? Date() : nil
            ))
        }
        
        try await client
            .from("dungeon_invite_responses")
            .insert(responses)
            .execute()
        
        print("🏰 Dungeon invite created: \(inviteID.uuidString.prefix(8)) for dungeon \(dungeonName)")
        return inviteID
    }
    
    /// Fetch pending dungeon invites for the current user (invites where the user has a "pending" response).
    func fetchPendingDungeonInvites() async throws -> [DungeonInviteWithDetails] {
        guard let userID = currentUserID else { return [] }
        
        // Get response rows where this user has a "pending" response
        let responseRows: [DungeonInviteResponseRow] = try await client
            .from("dungeon_invite_responses")
            .select()
            .eq("user_id", value: userID.uuidString)
            .eq("response", value: "pending")
            .execute()
            .value
        
        guard !responseRows.isEmpty else { return [] }
        
        // Fetch corresponding invite details for each pending response
        var results: [DungeonInviteWithDetails] = []
        for resp in responseRows {
            let invites: [DungeonInviteRow] = try await client
                .from("dungeon_invites")
                .select()
                .eq("id", value: resp.inviteID.uuidString)
                .eq("status", value: "waiting")
                .execute()
                .value
            
            if let invite = invites.first {
                // Fetch host profile for display
                let hostProfile = try? await fetchProfile(byID: invite.hostUserID)
                results.append(DungeonInviteWithDetails(
                    invite: invite,
                    responseID: resp.id,
                    hostName: hostProfile?.characterName ?? "Adventurer"
                ))
            }
        }
        
        return results
    }
    
    /// Respond to a dungeon invite (accept or decline).
    func respondToDungeonInvite(responseID: UUID, accepted: Bool) async throws {
        try await client
            .from("dungeon_invite_responses")
            .update(["response": accepted ? "accepted" : "declined",
                      "responded_at": ISO8601DateFormatter().string(from: Date())])
            .eq("id", value: responseID.uuidString)
            .execute()
        
        print("🏰 Dungeon invite response: \(accepted ? "accepted" : "declined") (\(responseID.uuidString.prefix(8)))")
    }
    
    /// Update the invite status (e.g. "started", "cancelled").
    func updateDungeonInviteStatus(inviteID: UUID, status: String) async throws {
        try await client
            .from("dungeon_invites")
            .update(["status": status])
            .eq("id", value: inviteID.uuidString)
            .execute()
        
        print("🏰 Dungeon invite status → \(status) (\(inviteID.uuidString.prefix(8)))")
    }
    
    /// Subscribe to dungeon invite response changes (for the lobby view).
    func subscribeToDungeonInviteResponses(inviteID: UUID, onUpdate: @escaping (DungeonInviteResponseRow) -> Void) async -> RealtimeChannelV2? {
        let channel = client.realtimeV2.channel("dungeon-invite-\(inviteID.uuidString.prefix(8))")
        
        let updates = await channel.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "dungeon_invite_responses",
            filter: "invite_id=eq.\(inviteID.uuidString)"
        )
        
        await channel.subscribe()
        
        Task {
            for await update in updates {
                do {
                    let row = try update.decodeRecord(as: DungeonInviteResponseRow.self, decoder: JSONDecoder.supabaseDecoder)
                    await MainActor.run {
                        onUpdate(row)
                    }
                } catch {
                    print("⚠️ Failed to decode realtime dungeon invite response: \(error)")
                }
            }
        }
        
        print("📡 Subscribed to dungeon invite responses for invite \(inviteID.uuidString.prefix(8))")
        return channel
    }
    
    // MARK: - Inventory Sync — Equipment
    
    /// Push a single equipment item to the cloud (insert or update).
    func syncEquipment(_ item: Equipment) async throws {
        guard let userID = currentUserID else { return }
        
        let row = CloudEquipmentUpsert(
            id: item.id,
            ownerID: userID,
            catalogID: nil,
            name: item.name,
            description: item.itemDescription,
            slot: item.slot.rawValue,
            rarity: item.rarity.rawValue,
            primaryStat: item.primaryStat.rawValue,
            statBonus: item.statBonus,
            secondaryStat: item.secondaryStat?.rawValue,
            secondaryStatBonus: item.secondaryStatBonus,
            levelRequirement: item.levelRequirement,
            enhancementLevel: item.enhancementLevel,
            isEquipped: item.isEquipped
        )
        
        try await client
            .from("equipment")
            .upsert(row)
            .execute()
    }
    
    /// Remove an equipment item from the cloud.
    func deleteEquipment(id: UUID) async throws {
        try await client
            .from("equipment")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    /// Pull all of the current user's equipment from the cloud.
    func fetchOwnEquipment() async throws -> [CloudEquipment] {
        guard let userID = currentUserID else { return [] }
        return try await client
            .from("equipment")
            .select()
            .eq("owner_id", value: userID.uuidString)
            .execute()
            .value
    }
    
    /// Pull the partner's equipment (read-only).
    func fetchPartnerEquipment() async throws -> [CloudEquipment] {
        guard let partnerID = currentProfile?.partnerID else { return [] }
        return try await client
            .from("equipment")
            .select()
            .eq("owner_id", value: partnerID.uuidString)
            .execute()
            .value
    }
    
    // MARK: - Inventory Sync — Consumables
    
    /// Push a consumable to the cloud (insert or update).
    func syncConsumable(_ item: Consumable) async throws {
        guard let userID = currentUserID else { return }
        
        let row = CloudConsumableUpsert(
            id: item.id,
            ownerID: userID,
            name: item.name,
            description: item.consumableDescription,
            consumableType: item.consumableType.rawValue,
            icon: item.icon,
            effectValue: item.effectValue,
            effectStat: item.effectStat?.rawValue,
            remainingUses: item.remainingUses
        )
        
        try await client
            .from("consumables")
            .upsert(row)
            .execute()
    }
    
    /// Remove a consumable from the cloud.
    func deleteConsumable(id: UUID) async throws {
        try await client
            .from("consumables")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    /// Pull the partner's consumables (read-only).
    func fetchPartnerConsumables() async throws -> [CloudConsumable] {
        guard let partnerID = currentProfile?.partnerID else { return [] }
        return try await client
            .from("consumables")
            .select()
            .eq("owner_id", value: partnerID.uuidString)
            .execute()
            .value
    }
    
    // MARK: - Inventory Sync — Crafting Materials
    
    /// Upsert a material stack to the cloud.
    /// Uses the unique (owner_id, material_type, rarity) constraint.
    func syncMaterial(type: String, rarity: String, quantity: Int) async throws {
        guard let userID = currentUserID else { return }
        
        let row = CloudCraftingMaterialUpsert(
            ownerID: userID,
            materialType: type,
            rarity: rarity,
            quantity: quantity
        )
        
        try await client
            .from("crafting_materials")
            .upsert(row, onConflict: "owner_id,material_type,rarity")
            .execute()
    }
    
    /// Pull the partner's crafting materials (read-only).
    func fetchPartnerMaterials() async throws -> [CloudCraftingMaterial] {
        guard let partnerID = currentProfile?.partnerID else { return [] }
        return try await client
            .from("crafting_materials")
            .select()
            .eq("owner_id", value: partnerID.uuidString)
            .execute()
            .value
    }
    
    // MARK: - Monster Card Sync
    
    /// Sync a collected card to the player_cards table in Supabase.
    func syncPlayerCard(cardID: String) async throws {
        guard let userID = currentUserID else { return }
        
        struct PlayerCardInsert: Encodable {
            let owner_id: String
            let card_id: String
        }
        
        let row = PlayerCardInsert(
            owner_id: userID.uuidString,
            card_id: cardID
        )
        
        // Upsert to avoid duplicate errors (UNIQUE constraint on owner_id, card_id)
        try await client
            .from("player_cards")
            .upsert(row, onConflict: "owner_id,card_id")
            .execute()
    }
    
    /// Fetch all card IDs collected by the current user.
    func fetchOwnCards() async throws -> [String] {
        guard let userID = currentUserID else { return [] }
        
        struct PlayerCardRow: Decodable {
            let card_id: String
        }
        
        let rows: [PlayerCardRow] = try await client
            .from("player_cards")
            .select("card_id")
            .eq("owner_id", value: userID.uuidString)
            .execute()
            .value
        
        return rows.map { $0.card_id }
    }
}

// MARK: - Errors

enum SupabaseServiceError: LocalizedError {
    case partnerNotFound
    case cannotPairWithSelf
    
    var errorDescription: String? {
        switch self {
        case .partnerNotFound:
            return "No adventurer found with that partner code."
        case .cannotPairWithSelf:
            return "You can't pair with yourself!"
        }
    }
}

// MARK: - Codable Models for Supabase

/// Cloud profile fetched from the `profiles` table.
struct Profile: Codable, Identifiable {
    let id: UUID
    let email: String?
    let characterName: String?
    let characterClass: String?
    let level: Int?
    let avatarName: String?
    let characterData: CharacterSnapshot?
    let partnerID: UUID?
    let partnerCode: String?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case characterName = "character_name"
        case characterClass = "character_class"
        case level
        case avatarName = "avatar_name"
        case characterData = "character_data"
        case partnerID = "partner_id"
        case partnerCode = "partner_code"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Helper for fetching only the character_data column.
struct CharacterDataRow: Codable {
    let characterData: CharacterSnapshot?
    
    enum CodingKeys: String, CodingKey {
        case characterData = "character_data"
    }
}

/// Payload for syncing character data to the cloud profile.
struct CharacterSyncPayload: Encodable {
    let characterName: String
    let characterClass: String?
    let level: Int
    let avatarName: String
    let characterData: CharacterSnapshot
    
    enum CodingKeys: String, CodingKey {
        case characterName = "character_name"
        case characterClass = "character_class"
        case level
        case avatarName = "avatar_name"
        case characterData = "character_data"
    }
}

/// Partner request from the `partner_requests` table.
struct PartnerRequest: Codable, Identifiable {
    let id: UUID
    let fromUserID: UUID
    let toUserID: UUID
    let status: String
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case fromUserID = "from_user_id"
        case toUserID = "to_user_id"
        case status
        case createdAt = "created_at"
    }
}

/// Insert model for partner requests.
struct PartnerRequestInsert: Encodable {
    let fromUserID: UUID
    let toUserID: UUID
    
    enum CodingKeys: String, CodingKey {
        case fromUserID = "from_user_id"
        case toUserID = "to_user_id"
    }
}

/// Insert model for interactions.
struct InteractionInsert: Encodable {
    let fromUserID: UUID
    let toUserID: UUID
    let type: String
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case fromUserID = "from_user_id"
        case toUserID = "to_user_id"
        case type
        case message
    }
}

/// Cloud interaction from the `partner_interactions` table.
struct CloudInteraction: Codable, Identifiable {
    let id: UUID
    let fromUserID: UUID
    let toUserID: UUID
    let type: String
    let message: String?
    let isRead: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case fromUserID = "from_user_id"
        case toUserID = "to_user_id"
        case type
        case message
        case isRead = "is_read"
        case createdAt = "created_at"
    }
}

// MARK: - Inventory Cloud DTOs

/// Equipment row read from the `equipment` table.
struct CloudEquipment: Codable, Identifiable {
    let id: UUID
    let ownerID: UUID
    let catalogID: String?
    let name: String
    let description: String
    let slot: String
    let rarity: String
    let primaryStat: String
    let statBonus: Int
    let secondaryStat: String?
    let secondaryStatBonus: Int
    let levelRequirement: Int
    let enhancementLevel: Int
    let isEquipped: Bool
    let acquiredAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case ownerID = "owner_id"
        case catalogID = "catalog_id"
        case name, description, slot, rarity
        case primaryStat = "primary_stat"
        case statBonus = "stat_bonus"
        case secondaryStat = "secondary_stat"
        case secondaryStatBonus = "secondary_stat_bonus"
        case levelRequirement = "level_requirement"
        case enhancementLevel = "enhancement_level"
        case isEquipped = "is_equipped"
        case acquiredAt = "acquired_at"
        case updatedAt = "updated_at"
    }
}

/// Equipment upsert payload (includes id so we can insert-or-update).
struct CloudEquipmentUpsert: Encodable {
    let id: UUID
    let ownerID: UUID
    let catalogID: String?
    let name: String
    let description: String
    let slot: String
    let rarity: String
    let primaryStat: String
    let statBonus: Int
    let secondaryStat: String?
    let secondaryStatBonus: Int
    let levelRequirement: Int
    let enhancementLevel: Int
    let isEquipped: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case ownerID = "owner_id"
        case catalogID = "catalog_id"
        case name, description, slot, rarity
        case primaryStat = "primary_stat"
        case statBonus = "stat_bonus"
        case secondaryStat = "secondary_stat"
        case secondaryStatBonus = "secondary_stat_bonus"
        case levelRequirement = "level_requirement"
        case enhancementLevel = "enhancement_level"
        case isEquipped = "is_equipped"
    }
}

/// Consumable row read from the `consumables` table.
struct CloudConsumable: Codable, Identifiable {
    let id: UUID
    let ownerID: UUID
    let name: String
    let description: String
    let consumableType: String
    let icon: String
    let effectValue: Int
    let effectStat: String?
    let remainingUses: Int
    let acquiredAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case ownerID = "owner_id"
        case name, description
        case consumableType = "consumable_type"
        case icon
        case effectValue = "effect_value"
        case effectStat = "effect_stat"
        case remainingUses = "remaining_uses"
        case acquiredAt = "acquired_at"
    }
}

/// Consumable upsert payload.
struct CloudConsumableUpsert: Encodable {
    let id: UUID
    let ownerID: UUID
    let name: String
    let description: String
    let consumableType: String
    let icon: String
    let effectValue: Int
    let effectStat: String?
    let remainingUses: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case ownerID = "owner_id"
        case name, description
        case consumableType = "consumable_type"
        case icon
        case effectValue = "effect_value"
        case effectStat = "effect_stat"
        case remainingUses = "remaining_uses"
    }
}

/// Crafting material row read from the `crafting_materials` table.
struct CloudCraftingMaterial: Codable, Identifiable {
    let id: UUID
    let ownerID: UUID
    let materialType: String
    let rarity: String
    let quantity: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case ownerID = "owner_id"
        case materialType = "material_type"
        case rarity, quantity
    }
}

/// Crafting material upsert payload (no id — uses unique constraint for conflict resolution).
struct CloudCraftingMaterialUpsert: Encodable {
    let ownerID: UUID
    let materialType: String
    let rarity: String
    let quantity: Int
    
    enum CodingKeys: String, CodingKey {
        case ownerID = "owner_id"
        case materialType = "material_type"
        case rarity, quantity
    }
}

// MARK: - Partner Task Cloud DTOs

/// Partner task row read from the `partner_tasks` table.
struct CloudPartnerTask: Codable, Identifiable {
    let id: UUID
    let createdBy: UUID
    let assignedTo: UUID
    let title: String
    let description: String?
    let category: String
    let partnerMessage: String?
    let verificationType: String
    let isOnDutyBoard: Bool
    let dueDate: Date?
    let status: String
    let completedAt: Date?
    let partnerConfirmed: Bool
    let partnerDisputeReason: String?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdBy = "created_by"
        case assignedTo = "assigned_to"
        case title, description, category
        case partnerMessage = "partner_message"
        case verificationType = "verification_type"
        case isOnDutyBoard = "is_on_duty_board"
        case dueDate = "due_date"
        case status
        case completedAt = "completed_at"
        case partnerConfirmed = "partner_confirmed"
        case partnerDisputeReason = "partner_dispute_reason"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Partner task insert payload.
struct CloudPartnerTaskInsert: Encodable {
    let createdBy: UUID
    let assignedTo: UUID
    let title: String
    let description: String?
    let category: String
    let partnerMessage: String?
    let verificationType: String
    let isOnDutyBoard: Bool
    let dueDate: Date?
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case createdBy = "created_by"
        case assignedTo = "assigned_to"
        case title, description, category
        case partnerMessage = "partner_message"
        case verificationType = "verification_type"
        case isOnDutyBoard = "is_on_duty_board"
        case dueDate = "due_date"
        case status
    }
}

// MARK: - Dungeon Invite DTOs

enum SupabaseDungeonInviteError: Error {
    case notAuthenticated
}

struct DungeonInviteInsert: Encodable {
    let partyID: UUID
    let hostUserID: UUID
    let dungeonID: UUID
    let dungeonName: String
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case partyID = "party_id"
        case hostUserID = "host_user_id"
        case dungeonID = "dungeon_id"
        case dungeonName = "dungeon_name"
        case status
    }
}

struct DungeonInviteRow: Decodable, Identifiable {
    let id: UUID
    let partyID: UUID?
    let hostUserID: UUID
    let dungeonID: UUID
    let dungeonName: String
    let status: String
    let createdAt: Date?
    let expiresAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case partyID = "party_id"
        case hostUserID = "host_user_id"
        case dungeonID = "dungeon_id"
        case dungeonName = "dungeon_name"
        case status
        case createdAt = "created_at"
        case expiresAt = "expires_at"
    }
}

struct DungeonInviteResponseInsert: Encodable {
    let inviteID: UUID
    let userID: UUID
    let response: String
    let respondedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case inviteID = "invite_id"
        case userID = "user_id"
        case response
        case respondedAt = "responded_at"
    }
}

struct DungeonInviteResponseRow: Decodable, Identifiable {
    let id: UUID
    let inviteID: UUID
    let userID: UUID
    let response: String
    let respondedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case inviteID = "invite_id"
        case userID = "user_id"
        case response
        case respondedAt = "responded_at"
    }
}

/// Convenience wrapper combining an invite + the current user's response ID + host name for display.
struct DungeonInviteWithDetails: Identifiable {
    let invite: DungeonInviteRow
    let responseID: UUID
    let hostName: String
    
    var id: UUID { invite.id }
}

// MARK: - JSON Decoder Extension

extension JSONDecoder {
    /// A decoder configured for Supabase's date formats.
    static var supabaseDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoFallback = ISO8601DateFormatter()
        isoFallback.formatOptions = [.withInternetDateTime]
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            if let date = isoFormatter.date(from: dateString) { return date }
            if let date = isoFallback.date(from: dateString) { return date }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date: \(dateString)"
            )
        }
        return decoder
    }
}
