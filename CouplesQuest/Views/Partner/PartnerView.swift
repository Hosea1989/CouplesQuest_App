import SwiftUI
import SwiftData
import Supabase

struct PartnerView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var gameEngine: GameEngine
    @Query private var characters: [PlayerCharacter]
    @Query private var bonds: [Bond]
    @Query(sort: \PartnerInteraction.createdAt, order: .reverse) private var interactions: [PartnerInteraction]
    
    @ObservedObject private var supabase = SupabaseService.shared
    
    @State private var showCreatePartySheet = false
    @State private var showJoinPartySheet = false
    @State private var showInviteSheet = false
    @State private var showCloudPairingSheet = false
    @State private var showAssignTaskSheet = false
    @State private var showLeaderboardSheet = false
    @State private var showNudgeConfirm = false
    @State private var showKudosConfirm = false
    @State private var showChallengeConfirm = false
    @State private var showPartyChallengeSheet = false
    @State private var showInteractionSuccess = false
    @State private var interactionSuccessMessage = ""
    
    
    @State private var ownProfileChannel: RealtimeChannelV2?
    @State private var interactionChannel: RealtimeChannelV2?
    @State private var partyFeedChannel: RealtimeChannelV2?
    @State private var pollingTimer: Timer?
    @State private var incomingRequests: [PartnerRequest] = []
    @State private var requestSenderProfiles: [UUID: Profile] = [:]
    @State private var partyFeedEvents: [PartyFeedEvent] = []
    @State private var memberNames: [UUID: String] = [:]
    @State private var showAllActivity = false
    @Query(filter: #Predicate<GameTask> { task in
        task.pendingPartnerConfirmation == true
    }) private var allPendingTasks: [GameTask]
    @Query(sort: \PartyChallenge.createdAt, order: .reverse) private var allPartyChallenges: [PartyChallenge]
    
    /// Number of tasks pending confirmation from us (partner's completed tasks)
    private var pendingConfirmationCount: Int {
        guard let character = character else { return 0 }
        return allPendingTasks.filter { $0.completedBy != nil && $0.completedBy != character.id }.count
    }
    
    private var character: PlayerCharacter? {
        characters.first
    }
    
    private var bond: Bond? {
        bonds.first
    }
    
    private var isPartnerLinked: Bool {
        character?.hasPartner ?? false
    }
    
    /// The currently active, non-expired party challenge (if any)
    private var activeChallenge: PartyChallenge? {
        allPartyChallenges.first(where: { $0.isActive && !$0.isExpired })
    }
    
    /// Unified activity items merging local interactions and remote party feed events
    private var unifiedActivityItems: [PartyActivityItem] {
        var items: [PartyActivityItem] = []
        let myID = SupabaseService.shared.currentUserID
        
        // Remote party feed events
        for event in partyFeedEvents {
            let name = memberNames[event.actorID] ?? "Ally"
            items.append(PartyActivityItem(feedEvent: event, actorName: name))
        }
        
        // Local interactions
        let feedIDs = Set(items.map(\.id))
        for interaction in interactions {
            guard !feedIDs.contains(interaction.id) else { continue }
            let isFromMe = interaction.fromCharacterID == myID
            let name = isFromMe ? "You" : (memberNames[interaction.fromCharacterID] ?? "Ally")
            items.append(PartyActivityItem(interaction: interaction, actorName: name))
        }
        
        return items.sorted { $0.timestamp > $1.timestamp }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color("BackgroundTop"),
                        Color("BackgroundBottom")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        if isPartnerLinked, let character = character, let bond = bond {
                            // Partner Connected - Full Dashboard
                            PartnerDashboardView(
                                character: character,
                                bond: bond,
                                onAssignTask: { showAssignTaskSheet = true },
                                onSendNudge: { showNudgeConfirm = true },
                                onSendKudos: { showKudosConfirm = true },
                                onSendChallenge: { showChallengeConfirm = true },
                                onViewLeaderboard: { showLeaderboardSheet = true },
                                onUnlinkPartner: { unlinkPartner() },
                                onInviteMember: { showInviteSheet = true },
                                activeChallenge: activeChallenge,
                                onSetChallenge: { showPartyChallengeSheet = true }
                            )
                            
                            // Incoming party requests (visible when party has room)
                            if !incomingRequests.isEmpty && bond.canAddMember {
                                incomingRequestsSection
                            }
                            
                            // Pending Confirmations
                            if pendingConfirmationCount > 0 {
                                NavigationLink(destination: PendingConfirmationsView()) {
                                    HStack(spacing: 12) {
                                        ZStack(alignment: .topTrailing) {
                                            Image(systemName: "checkmark.seal.fill")
                                                .font(.title2)
                                                .foregroundColor(Color("AccentGold"))
                                            
                                            Text("\(pendingConfirmationCount)")
                                                .font(.custom("Avenir-Heavy", size: 11))
                                                .foregroundColor(.white)
                                                .padding(4)
                                                .background(Circle().fill(.red))
                                                .offset(x: 6, y: -4)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Pending Confirmations")
                                                .font(.custom("Avenir-Heavy", size: 15))
                                                .foregroundColor(.primary)
                                            Text("\(pendingConfirmationCount) task\(pendingConfirmationCount == 1 ? "" : "s") awaiting your review")
                                                .font(.custom("Avenir-Medium", size: 12))
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color("CardBackground"))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color("AccentGold").opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                            
                            // Party Activity Feed (Tavern Board)
                            PartyTavernBoardCard(
                                items: unifiedActivityItems,
                                onSeeAll: { showAllActivity = true }
                            )
                            
                            
                        } else {
                            // Not Connected View — Create or Join a party
                            PartnerNotConnectedView(
                                onCreateParty: { showCreatePartySheet = true },
                                onJoinParty: { showJoinPartySheet = true }
                            )
                            
                            // Incoming party requests
                            if !incomingRequests.isEmpty {
                                incomingRequestsSection
                            }
                            
                            // Partner Features Info
                            PartnerFeaturesCard()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Party")
            .navigationBarTitleDisplayMode(.large)
            .task {
                // Refresh profile to ensure partner code is loaded
                await SupabaseService.shared.fetchProfile()
                
                // Load incoming party requests
                await loadIncomingRequests()
                
                // Check if our profile now has a partner_id (e.g. request was accepted while we were away)
                await checkAndLinkPartnerIfNeeded()
                
                // Subscribe to own profile changes for instant partner_id detection
                if !isPartnerLinked && ownProfileChannel == nil {
                    ownProfileChannel = await SupabaseService.shared.subscribeToOwnProfile { updatedProfile in
                        if updatedProfile.partnerID != nil && !isPartnerLinked {
                            Task { await checkAndLinkPartnerIfNeeded() }
                        }
                    }
                }
                
                // Start polling while not connected (fallback for realtime issues)
                startPollingIfNeeded()
                
                // Cache the party ID for fire-and-forget feed posts from other screens
                if isPartnerLinked, let bond = bond {
                    SupabaseService.shared.cachedPartyID = bond.supabasePartyID
                }
                
                // Subscribe to incoming interactions (kudos, nudges, challenges)
                if isPartnerLinked && interactionChannel == nil {
                    interactionChannel = await SupabaseService.shared.subscribeToInteractions { cloudInteraction in
                        handleIncomingInteraction(cloudInteraction)
                    }
                }
                
                // Also fetch any interactions we missed while offline
                if isPartnerLinked {
                    await fetchMissedInteractions()
                }
                
                // Load party feed and subscribe to realtime events
                if isPartnerLinked, let partyID = bond?.supabasePartyID {
                    await loadPartyFeed(partyID: partyID)
                    await loadMemberNames()
                    
                    if partyFeedChannel == nil {
                        partyFeedChannel = await SupabaseService.shared.subscribeToPartyFeed(partyID: partyID) { newEvent in
                            handleIncomingFeedEvent(newEvent)
                        }
                    }
                }
            }
            .onAppear {
                // Re-check every time the view appears (e.g. after dismissing QR sheet or tab switch)
                Task {
                    await checkAndLinkPartnerIfNeeded()
                    await loadIncomingRequests()
                    
                    // Refresh partner/party member data so dashboard stats are up to date
                    if isPartnerLinked, let character = character {
                        await gameEngine.refreshPartnerData(character: character)
                    }
                    
                    // Re-subscribe to interactions if linked but no channel
                    if isPartnerLinked && interactionChannel == nil {
                        interactionChannel = await SupabaseService.shared.subscribeToInteractions { cloudInteraction in
                            handleIncomingInteraction(cloudInteraction)
                        }
                    }
                }
            }
            .onDisappear {
                stopPolling()
            }
            .onChange(of: isPartnerLinked) { _, linked in
                if linked {
                    // Stop polling and tear down own-profile subscription once linked
                    stopPolling()
                    if let channel = ownProfileChannel {
                        Task { await SupabaseService.shared.unsubscribeChannel(channel) }
                        ownProfileChannel = nil
                    }
                    // Start listening for incoming interactions now that we're linked
                    if interactionChannel == nil {
                        Task {
                            interactionChannel = await SupabaseService.shared.subscribeToInteractions { cloudInteraction in
                                handleIncomingInteraction(cloudInteraction)
                            }
                            await fetchMissedInteractions()
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreatePartySheet) {
                JoinPartySheet(mode: .create)
            }
            .sheet(isPresented: $showJoinPartySheet) {
                CreatePartySheet()
            }
            .sheet(isPresented: $showInviteSheet) {
                JoinPartySheet(mode: .invite)
            }
            .sheet(isPresented: $showCloudPairingSheet) {
                CloudPairingView()
            }
            .sheet(isPresented: $showAssignTaskSheet) {
                CreateTaskView(initialType: .forPartner)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showLeaderboardSheet) {
                CouplesLeaderboardView()
            }
            .sheet(isPresented: $showAllActivity) {
                PartyActivityFullView(
                    partyID: bond?.supabasePartyID,
                    localInteractions: Array(interactions),
                    partyFeedEvents: partyFeedEvents,
                    memberNames: memberNames
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showPartyChallengeSheet) {
                if let character = character, let bond = bond {
                    CreatePartyChallengeView(character: character, bond: bond)
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                }
            }
            .alert("Send Nudge", isPresented: $showNudgeConfirm) {
                Button("Send") { sendNudge() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Remind your ally that their quest log awaits!")
            }
            .alert("Send Kudos", isPresented: $showKudosConfirm) {
                Button("Send") { sendKudos() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Give your ally a thumbs up for their hard work!")
            }
            .alert("Send Challenge", isPresented: $showChallengeConfirm) {
                Button("Send") { sendChallenge() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Challenge your allies to complete 3 tasks today!")
            }
            .alert("Sent!", isPresented: $showInteractionSuccess) {
                Button("OK") {}
            } message: {
                Text(interactionSuccessMessage)
            }
            
        }
    }
    
    // MARK: - Actions
    
    private func sendNudge() {
        guard let character = character, let bond = bond else { return }
        guard let interaction = gameEngine.sendNudge(from: character, bond: bond, message: nil) else {
            ToastManager.shared.showInfo(
                "Daily Limit Reached",
                subtitle: "You can send \(Bond.maxInteractionsPerType) nudges per day",
                icon: "clock.fill"
            )
            return
        }
        modelContext.insert(interaction)
        let remaining = bond.nudgesRemainingToday
        interactionSuccessMessage = "Nudge sent to \(character.partnerName ?? "your ally")!"
        showInteractionSuccess = true
        ToastManager.shared.showInfo(
            "Nudge Sent!",
            subtitle: remaining > 0 ? "\(remaining) remaining today" : "No more nudges today",
            icon: "bell.badge.fill"
        )
        // Sync to Supabase + push notification
        Task {
            try? await SupabaseService.shared.sendInteraction(type: "nudge", message: InteractionType.nudge.defaultMessage)
            await PushNotificationService.shared.notifyPartnerNudge(fromName: character.name)
        }
    }
    
    private func sendKudos() {
        guard let character = character, let bond = bond else { return }
        guard let interaction = gameEngine.sendKudos(from: character, bond: bond, message: nil) else {
            ToastManager.shared.showInfo(
                "Daily Limit Reached",
                subtitle: "You can send \(Bond.maxInteractionsPerType) kudos per day",
                icon: "clock.fill"
            )
            return
        }
        modelContext.insert(interaction)
        let remaining = bond.kudosRemainingToday
        interactionSuccessMessage = "Kudos sent! +\(GameEngine.bondEXPForKudos) Bond EXP"
        showInteractionSuccess = true
        ToastManager.shared.showReward(
            "Kudos Sent!",
            subtitle: remaining > 0 ? "+\(GameEngine.bondEXPForKudos) Bond EXP · \(remaining) remaining today" : "+\(GameEngine.bondEXPForKudos) Bond EXP · No more today",
            icon: "hands.clap.fill"
        )
        // Sync to Supabase + push notification
        Task {
            try? await SupabaseService.shared.sendInteraction(type: "kudos", message: InteractionType.kudos.defaultMessage)
            await PushNotificationService.shared.notifyPartnerKudos(fromName: character.name, bondEXP: GameEngine.bondEXPForKudos)
        }
    }
    
    private func sendChallenge() {
        guard let character = character, let bond = bond else { return }
        guard let interaction = gameEngine.sendChallenge(from: character, bond: bond, message: nil) else {
            ToastManager.shared.showInfo(
                "Daily Limit Reached",
                subtitle: "You can send \(Bond.maxInteractionsPerType) challenges per day",
                icon: "clock.fill"
            )
            return
        }
        modelContext.insert(interaction)
        let remaining = bond.challengesRemainingToday
        interactionSuccessMessage = "Challenge sent to \(character.partnerName ?? "your ally")!"
        showInteractionSuccess = true
        ToastManager.shared.showInfo(
            "Challenge Sent!",
            subtitle: remaining > 0 ? "\(remaining) remaining today" : "No more challenges today",
            icon: "flag.fill"
        )
        // Sync to Supabase + push notification
        Task {
            try? await SupabaseService.shared.sendInteraction(type: "challenge", message: InteractionType.challenge.defaultMessage)
            await PushNotificationService.shared.notifyPartnerChallenge(fromName: character.name)
        }
    }
    
    
    
    // MARK: - Incoming Interactions (Kudos / Nudges / Challenges)
    
    /// Handle a realtime incoming interaction from a party member.
    private func handleIncomingInteraction(_ cloud: CloudInteraction) {
        guard let character = character else { return }
        // Don't re-insert if we sent it ourselves
        guard cloud.fromUserID != SupabaseService.shared.currentUserID else { return }
        
        // Check if we already have this interaction locally (avoid duplicates)
        let existingIDs = interactions.map(\.id)
        guard !existingIDs.contains(cloud.id) else { return }
        
        // Map cloud type string to local InteractionType
        let interactionType: InteractionType
        switch cloud.type.lowercased() {
        case "nudge": interactionType = .nudge
        case "kudos": interactionType = .kudos
        case "challenge": interactionType = .challenge
        case "task_assigned": interactionType = .taskAssigned
        default: interactionType = .nudge // fallback
        }
        
        // Find the sender name from party members
        let senderName = character.partyMembers.first(where: { $0.id == cloud.fromUserID })?.name ?? "Your ally"
        
        // Create local PartnerInteraction
        let localInteraction = PartnerInteraction(
            type: interactionType,
            message: cloud.message ?? interactionType.defaultMessage,
            fromCharacterID: cloud.fromUserID,
            toCharacterID: character.id
        )
        localInteraction.id = cloud.id  // use the same ID to prevent duplicates
        localInteraction.createdAt = cloud.createdAt
        modelContext.insert(localInteraction)
        
        // Show an enhanced toast to the receiving user
        switch interactionType {
        case .kudos:
            ToastManager.shared.showKudos(
                from: senderName,
                message: cloud.message
            )
        case .nudge:
            ToastManager.shared.showNudge(
                from: senderName,
                message: cloud.message
            )
        case .challenge:
            ToastManager.shared.showChallenge(
                from: senderName,
                message: cloud.message
            )
        default:
            ToastManager.shared.showInfo(
                "\(interactionType.rawValue) from \(senderName)",
                subtitle: cloud.message,
                icon: interactionType.icon
            )
        }
        
        // Award Bond EXP for receiving
        if let bond = bond {
            bond.gainBondEXP(1)
        }
    }
    
    /// Fetch interactions we may have missed while the app was closed.
    private func fetchMissedInteractions() async {
        guard let character = character else { return }
        do {
            let cloudInteractions = try await SupabaseService.shared.fetchInteractions(limit: 20)
            let existingIDs = Set(interactions.map(\.id))
            let myID = SupabaseService.shared.currentUserID
            
            for cloud in cloudInteractions {
                // Only process interactions sent TO us (not ones we sent)
                guard cloud.toUserID == myID else { continue }
                // Skip already-imported ones
                guard !existingIDs.contains(cloud.id) else { continue }
                
                let interactionType: InteractionType
                switch cloud.type.lowercased() {
                case "nudge": interactionType = .nudge
                case "kudos": interactionType = .kudos
                case "challenge": interactionType = .challenge
                case "task_assigned": interactionType = .taskAssigned
                default: continue
                }
                
                let localInteraction = PartnerInteraction(
                    type: interactionType,
                    message: cloud.message ?? interactionType.defaultMessage,
                    fromCharacterID: cloud.fromUserID,
                    toCharacterID: character.id
                )
                localInteraction.id = cloud.id
                localInteraction.createdAt = cloud.createdAt
                localInteraction.isRead = cloud.isRead
                modelContext.insert(localInteraction)
            }
        } catch {
            print("⚠️ Failed to fetch missed interactions: \(error)")
        }
    }
    
    // MARK: - Party Feed
    
    /// Load the party feed from Supabase.
    private func loadPartyFeed(partyID: UUID) async {
        do {
            partyFeedEvents = try await SupabaseService.shared.fetchPartyFeed(partyID: partyID, limit: 50)
        } catch {
            print("⚠️ Failed to load party feed: \(error)")
        }
    }
    
    /// Load member names for display in the activity feed.
    private func loadMemberNames() async {
        guard let character = character else { return }
        
        // Add self
        if let myID = SupabaseService.shared.currentUserID {
            memberNames[myID] = character.name
        }
        
        // Add party members
        for member in character.partyMembers {
            memberNames[member.id] = member.name
        }
        
        // Fetch any names we're missing from the feed events
        let knownIDs = Set(memberNames.keys)
        let missingIDs = Set(partyFeedEvents.map(\.actorID)).subtracting(knownIDs)
        
        for actorID in missingIDs {
            do {
                let profiles: [ProfileName] = try await SupabaseService.shared.client
                    .from("profiles")
                    .select("id, character_name")
                    .eq("id", value: actorID.uuidString)
                    .execute()
                    .value
                if let profile = profiles.first {
                    memberNames[actorID] = profile.characterName ?? "Ally"
                }
            } catch {
                print("⚠️ Failed to fetch name for \(actorID): \(error)")
            }
        }
    }
    
    /// Handle a new party feed event arriving via realtime subscription.
    private func handleIncomingFeedEvent(_ event: PartyFeedEvent) {
        // Don't add if it's our own event (we already see our own actions)
        guard event.actorID != SupabaseService.shared.currentUserID else { return }
        
        // Avoid duplicates
        guard !partyFeedEvents.contains(where: { $0.id == event.id }) else { return }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            partyFeedEvents.insert(event, at: 0)
        }
        
        let actorName = memberNames[event.actorID] ?? "Your ally"
        
        // Show a toast for notable events
        switch event.eventType {
        case "level_up":
            ToastManager.shared.showReward(
                "\(actorName) leveled up!",
                subtitle: event.message,
                icon: "arrow.up.circle.fill"
            )
        case "dungeon_loot":
            ToastManager.shared.showReward(
                "\(actorName) cleared a dungeon!",
                subtitle: event.message,
                icon: "gift.fill"
            )
        case "streak_milestone":
            ToastManager.shared.showReward(
                "Streak milestone!",
                subtitle: event.message,
                icon: "flame.fill"
            )
        case "task_completed":
            ToastManager.shared.showInfo(
                "\(actorName) completed a quest",
                subtitle: event.message,
                icon: "checkmark.circle.fill"
            )
        default:
            break
        }
    }
    
    private func unlinkPartner() {
        guard let character = character else { return }
        
        // 1. Leave the party locally (clears partner fields + party members)
        character.leaveParty()
        
        // 2. Remove self from the Bond's member list
        if let bond = bond {
            bond.removeMember(character.id)
        }
        
        // 3. Clear partner_id in Supabase (both sides)
        Task {
            try? await SupabaseService.shared.unlinkPartner()
        }
    }
    
    // MARK: - Partner Detection (for request sender)
    
    // MARK: - Incoming Requests
    
    private var incomingRequestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "envelope.badge.fill")
                    .foregroundColor(Color("AccentPink"))
                Text("Incoming Party Requests")
                    .font(.custom("Avenir-Heavy", size: 16))
                Spacer()
                Text("\(incomingRequests.count)")
                    .font(.custom("Avenir-Heavy", size: 14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color("AccentPink")))
            }
            
            ForEach(incomingRequests) { request in
                HStack(spacing: 12) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(Color("AccentPurple").opacity(0.2))
                            .frame(width: 44, height: 44)
                        if let profile = requestSenderProfiles[request.fromUserID],
                           let avatarName = profile.avatarName {
                            Image(avatarName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.title2)
                                .foregroundColor(Color("AccentPurple"))
                        }
                    }
                    
                    // Name + Level
                    VStack(alignment: .leading, spacing: 2) {
                        if let profile = requestSenderProfiles[request.fromUserID] {
                            Text(profile.characterName ?? "Adventurer")
                                .font(.custom("Avenir-Heavy", size: 14))
                            if let level = profile.level {
                                Text("Level \(level)")
                                    .font(.custom("Avenir-Medium", size: 12))
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Text("Adventurer")
                                .font(.custom("Avenir-Heavy", size: 14))
                        }
                    }
                    
                    Spacer()
                    
                    // Accept button
                    Button(action: { acceptIncomingRequest(request) }) {
                        Text("Accept")
                            .font(.custom("Avenir-Heavy", size: 12))
                            .foregroundColor(.black)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Color("AccentGold"))
                            .clipShape(Capsule())
                    }
                    
                    // Decline button
                    Button(action: { rejectIncomingRequest(request) }) {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(7)
                            .background(Circle().fill(Color("CardBackground")))
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("CardBackground").opacity(0.6))
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
    }
    
    private func loadIncomingRequests() async {
        do {
            incomingRequests = try await supabase.fetchIncomingRequests()
            for request in incomingRequests {
                let profiles: [Profile] = try await supabase.client
                    .from("profiles")
                    .select()
                    .eq("id", value: request.fromUserID.uuidString)
                    .execute()
                    .value
                if let profile = profiles.first {
                    requestSenderProfiles[request.fromUserID] = profile
                }
            }
        } catch {
            print("Failed to load incoming requests: \(error)")
        }
    }
    
    private func acceptIncomingRequest(_ request: PartnerRequest) {
        Task {
            do {
                try await supabase.acceptPartnerRequest(request.id)
                
                // Link partner locally after cloud acceptance
                await linkAcceptedPartnerLocally(partnerUserID: request.fromUserID)
                
                // Remove from list
                await MainActor.run {
                    incomingRequests.removeAll { $0.id == request.id }
                }
            } catch {
                print("Failed to accept request: \(error)")
            }
        }
    }
    
    private func rejectIncomingRequest(_ request: PartnerRequest) {
        Task {
            do {
                try await supabase.rejectPartnerRequest(request.id)
                await MainActor.run {
                    incomingRequests.removeAll { $0.id == request.id }
                }
            } catch {
                print("Failed to reject request: \(error)")
            }
        }
    }
    
    /// After accepting a request, sync partner data into local SwiftData character + Bond.
    /// Handles both initial pairing (solo → 2) and adding new members to existing party (2 → 3 → 4).
    @MainActor
    private func linkAcceptedPartnerLocally(partnerUserID: UUID) async {
        guard let character = character else { return }
        
        do {
            if let partnerProfile = try await supabase.fetchProfile(byID: partnerUserID) {
                let pairingData = PairingData(
                    characterID: partnerUserID.uuidString,
                    name: partnerProfile.characterName ?? "Adventurer",
                    level: partnerProfile.level ?? 1,
                    characterClass: partnerProfile.characterClass,
                    partyID: nil,
                    avatarName: partnerProfile.avatarName
                )
                character.linkPartner(data: pairingData)
                
                // Create a Bond if one doesn't exist, or add to existing party
                if bonds.isEmpty {
                    let newBond = Bond(memberIDs: [character.id, partnerUserID])
                    modelContext.insert(newBond)
                } else if let existingBond = bonds.first {
                    existingBond.addMember(partnerUserID)
                }
                
                try? modelContext.save()
                AudioManager.shared.play(.partnerPaired)
                
                // Sync updated party to Supabase so all members see the new roster
                if let bond = bonds.first {
                    try? await SupabaseService.shared.syncBondToParty(bond, playerID: character.id)
                }
            }
        } catch {
            print("Failed to fetch partner profile for local link: \(error)")
        }
    }
    
    /// Check if our Supabase profile now has a partner_id and link locally if so.
    /// This is the key fix: when our request is accepted by the other person,
    /// they set partner_id on our profile in Supabase, but our local SwiftData
    /// doesn't know about it until we check.
    @MainActor
    private func checkAndLinkPartnerIfNeeded() async {
        guard let character = character, !isPartnerLinked else { return }
        guard SupabaseService.shared.isAuthenticated else { return }
        
        // Re-fetch our profile from Supabase to get the latest partner_id
        await SupabaseService.shared.fetchProfile()
        
        guard let partnerID = SupabaseService.shared.currentProfile?.partnerID else { return }
        
        // Our profile now has a partner_id — link them locally
        do {
            if let partnerProfile = try await SupabaseService.shared.fetchProfile(byID: partnerID) {
                let pairingData = PairingData(
                    characterID: partnerID.uuidString,
                    name: partnerProfile.characterName ?? "Adventurer",
                    level: partnerProfile.level ?? 1,
                    characterClass: partnerProfile.characterClass,
                    partyID: nil,
                    avatarName: partnerProfile.avatarName
                )
                character.linkPartner(data: pairingData)
                
                // Create a Bond if one doesn't exist
                if bonds.isEmpty {
                    let newBond = Bond(memberIDs: [character.id, partnerID])
                    modelContext.insert(newBond)
                } else if let existingBond = bonds.first {
                    existingBond.addMember(partnerID)
                }
                
                try? modelContext.save()
                print("✅ Partner linked locally after detecting accepted request (partner: \(partnerProfile.characterName ?? "unknown"))")
            }
        } catch {
            print("❌ Failed to link partner locally after detection: \(error)")
        }
    }
    
    /// Start a polling timer that checks for partner_id changes every 5 seconds while not connected.
    private func startPollingIfNeeded() {
        guard !isPartnerLinked else { return }
        stopPolling()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            Task { @MainActor in
                guard !isPartnerLinked else {
                    stopPolling()
                    return
                }
                await checkAndLinkPartnerIfNeeded()
            }
        }
    }
    
    /// Stop the polling timer.
    private func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }
}

// MARK: - Partner Not Connected View

struct PartnerNotConnectedView: View {
    let onCreateParty: () -> Void
    let onJoinParty: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Illustration
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color("AccentPink").opacity(0.2), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                
                HStack(spacing: -20) {
                    ZStack {
                        Circle()
                            .fill(Color("AccentGold").opacity(0.3))
                            .frame(width: 80, height: 80)
                        Image(systemName: "person.fill")
                            .font(.largeTitle)
                            .foregroundColor(Color("AccentGold"))
                    }
                    
                    ZStack {
                        Circle()
                            .fill(Color("AccentPurple").opacity(0.3))
                            .frame(width: 80, height: 80)
                        Image(systemName: "person.fill.questionmark")
                            .font(.largeTitle)
                            .foregroundColor(Color("AccentPurple"))
                    }
                }
            }
            
            VStack(spacing: 8) {
                Text("Find Your Party")
                    .font(.custom("Avenir-Heavy", size: 24))
                
                Text("Invite up to 3 allies to share tasks,\ncompete on the leaderboard, and quest together!")
                    .font(.custom("Avenir-Medium", size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Two-card layout: Create / Join
            VStack(spacing: 12) {
                // Create a Party card
                Button(action: onCreateParty) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color("AccentGold").opacity(0.15))
                                .frame(width: 48, height: 48)
                            Image(systemName: "person.3.fill")
                                .font(.title3)
                                .foregroundColor(Color("AccentGold"))
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Create a Party")
                                .font(.custom("Avenir-Heavy", size: 16))
                                .foregroundColor(.primary)
                            Text("Scan or enter an ally's code to invite them")
                                .font(.custom("Avenir-Medium", size: 12))
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Color("AccentGold"))
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color("CardBackground"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color("AccentGold").opacity(0.25), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                
                // Join a Party card
                Button(action: onJoinParty) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color("AccentPurple").opacity(0.15))
                                .frame(width: 48, height: 48)
                            Image(systemName: "person.badge.plus")
                                .font(.title3)
                                .foregroundColor(Color("AccentPurple"))
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Join a Party")
                                .font(.custom("Avenir-Heavy", size: 16))
                                .foregroundColor(.primary)
                            Text("Show your code so a party leader can invite you")
                                .font(.custom("Avenir-Medium", size: 12))
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Color("AccentPurple"))
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color("CardBackground"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color("AccentPurple").opacity(0.25), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
    }
}

// MARK: - Partner Features Card

struct PartnerFeaturesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Party Features")
                .font(.custom("Avenir-Heavy", size: 18))
            
            FeatureRow(
                icon: "qrcode.viewfinder",
                title: "QR Code Pairing",
                description: "Scan or share a QR code to invite allies"
            )
            
            FeatureRow(
                icon: "heart.circle.fill",
                title: "Bond Level System",
                description: "Grow your bond together and unlock perks"
            )
            
            FeatureRow(
                icon: "paperplane.fill",
                title: "Assign Tasks",
                description: "Send tasks directly to any party member"
            )
            
            FeatureRow(
                icon: "rectangle.on.rectangle",
                title: "Shared Duty Board",
                description: "All members can claim tasks from a shared pool"
            )
            
            FeatureRow(
                icon: "chart.bar.fill",
                title: "Party Leaderboard",
                description: "Friendly competition to stay motivated"
            )
            
            FeatureRow(
                icon: "flame.fill",
                title: "Party Streak",
                description: "Bonus EXP when all members stay active daily"
            )
            
            FeatureRow(
                icon: "hand.thumbsup.fill",
                title: "Kudos & Nudges",
                description: "Encourage and motivate each other"
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color("AccentGold"))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("Avenir-Heavy", size: 14))
                Text(description)
                    .font(.custom("Avenir-Medium", size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Date Extension

extension Date {
    func timeAgoDisplay() -> String {
        let seconds = -self.timeIntervalSinceNow
        
        if seconds < 60 {
            return "Just now"
        } else if seconds < 3600 {
            let minutes = Int(seconds / 60)
            return "\(minutes)m ago"
        } else if seconds < 86400 {
            let hours = Int(seconds / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(seconds / 86400)
            return "\(days)d ago"
        }
    }
}

// MARK: - Cloud Pairing View

struct CloudPairingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var supabase = SupabaseService.shared
    @Query private var characters: [PlayerCharacter]
    @Query private var bonds: [Bond]
    
    @State private var partnerCode = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showRequestSent = false
    @State private var incomingRequests: [PartnerRequest] = []
    @State private var requestSenderProfiles: [UUID: Profile] = [:]
    
    private var character: PlayerCharacter? { characters.first }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color("BackgroundTop"), Color("BackgroundBottom")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // My Party Code
                        if let code = supabase.currentProfile?.partnerCode {
                            VStack(spacing: 8) {
                                Text("Your Party Code")
                                    .font(.custom("Avenir-Heavy", size: 16))
                                    .foregroundColor(.secondary)
                                
                                Text(code)
                                    .font(.custom("Avenir-Heavy", size: 40))
                                    .tracking(6)
                                    .foregroundColor(Color("AccentGold"))
                                
                                Text("Share this code with allies to form a party")
                                    .font(.custom("Avenir-Medium", size: 13))
                                    .foregroundColor(.secondary)
                            }
                            .padding(24)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color("CardBackground"))
                            )
                        }
                        
                        // Enter Ally's Code
                        VStack(spacing: 16) {
                            Text("Enter Ally's Code")
                                .font(.custom("Avenir-Heavy", size: 16))
                            
                            HStack(spacing: 10) {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(Color("AccentPurple"))
                                    .frame(width: 20)
                                
                                TextField("e.g. ABC123", text: $partnerCode)
                                    .font(.custom("Avenir-Heavy", size: 18))
                                    .autocapitalization(.allCharacters)
                                    .disableAutocorrection(true)
                                    .onChange(of: partnerCode) { _, newValue in
                                        partnerCode = String(newValue.prefix(6)).uppercased()
                                    }
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color("CardBackground"))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color("AccentPurple").opacity(0.3), lineWidth: 1)
                            )
                            
                            if let errorMessage {
                                Text(errorMessage)
                                    .font(.custom("Avenir-Medium", size: 13))
                                    .foregroundColor(.red)
                            }
                            
                            Button(action: sendRequest) {
                                HStack(spacing: 8) {
                                    if isLoading {
                                        ProgressView().tint(.black)
                                    } else {
                                        Image(systemName: "paperplane.fill")
                                        Text("Send Party Invite")
                                    }
                                }
                                .font(.custom("Avenir-Heavy", size: 15))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        colors: [Color("AccentPink"), Color("AccentPurple")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .disabled(partnerCode.count < 6 || isLoading)
                            .opacity(partnerCode.count < 6 ? 0.5 : 1)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color("CardBackground"))
                        )
                        
                        // Incoming Requests
                        if !incomingRequests.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Incoming Requests")
                                    .font(.custom("Avenir-Heavy", size: 16))
                                
                                ForEach(incomingRequests) { request in
                                    HStack(spacing: 12) {
                                        Image(systemName: "person.crop.circle.badge.plus")
                                            .font(.title2)
                                            .foregroundColor(Color("AccentPink"))
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            if let profile = requestSenderProfiles[request.fromUserID] {
                                                Text(profile.characterName ?? profile.email ?? "Adventurer")
                                                    .font(.custom("Avenir-Heavy", size: 14))
                                                if let level = profile.level {
                                                    Text("Level \(level)")
                                                        .font(.custom("Avenir-Medium", size: 12))
                                                        .foregroundColor(.secondary)
                                                }
                                            } else {
                                                Text("Adventurer")
                                                    .font(.custom("Avenir-Heavy", size: 14))
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Button(action: { acceptRequest(request) }) {
                                            Text("Accept")
                                                .font(.custom("Avenir-Heavy", size: 12))
                                                .foregroundColor(.black)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 7)
                                                .background(Color("AccentGold"))
                                                .clipShape(Capsule())
                                        }
                                        
                                        Button(action: { rejectRequest(request) }) {
                                            Image(systemName: "xmark")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .padding(7)
                                                .background(Circle().fill(Color("CardBackground")))
                                        }
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color("CardBackground").opacity(0.6))
                                    )
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color("CardBackground"))
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Join Party")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Invite Sent!", isPresented: $showRequestSent) {
                Button("OK") { dismiss() }
            } message: {
                Text("Your party invite has been sent. They'll need to accept it on their device.")
            }
            .task {
                await loadIncomingRequests()
            }
        }
    }
    
    // MARK: - Actions
    
    private func sendRequest() {
        errorMessage = nil
        isLoading = true
        Task {
            do {
                try await supabase.sendPartnerRequest(toCode: partnerCode)
                await MainActor.run {
                    character?.completeBreadcrumb("inviteFriend")
                    showRequestSent = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func loadIncomingRequests() async {
        do {
            incomingRequests = try await supabase.fetchIncomingRequests()
            // Load sender profiles
            for request in incomingRequests {
                let profiles: [Profile] = try await supabase.client
                    .from("profiles")
                    .select()
                    .eq("id", value: request.fromUserID.uuidString)
                    .execute()
                    .value
                if let profile = profiles.first {
                    requestSenderProfiles[request.fromUserID] = profile
                }
            }
        } catch {
            print("Failed to load requests: \(error)")
        }
    }
    
    private func acceptRequest(_ request: PartnerRequest) {
        Task {
            do {
                try await supabase.acceptPartnerRequest(request.id)
                
                // Update local SwiftData character with partner info
                await linkPartnerLocally(partnerUserID: request.fromUserID)
                
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    /// After cloud accept, sync partner data into the local SwiftData character + Bond.
    @MainActor
    private func linkPartnerLocally(partnerUserID: UUID) async {
        guard let character = character else { return }
        
        do {
            if let partnerProfile = try await supabase.fetchProfile(byID: partnerUserID) {
                let pairingData = PairingData(
                    characterID: partnerUserID.uuidString,
                    name: partnerProfile.characterName ?? "Adventurer",
                    level: partnerProfile.level ?? 1,
                    characterClass: partnerProfile.characterClass,
                    partyID: nil,
                    avatarName: partnerProfile.avatarName
                )
                character.linkPartner(data: pairingData)
                
                // Create a Bond if one doesn't exist
                if bonds.isEmpty {
                    let newBond = Bond(memberIDs: [character.id, partnerUserID])
                    modelContext.insert(newBond)
                } else if let existingBond = bonds.first {
                    existingBond.addMember(partnerUserID)
                }
                
                try? modelContext.save()
            }
        } catch {
            print("Failed to fetch partner profile for local link: \(error)")
        }
    }
    
    private func rejectRequest(_ request: PartnerRequest) {
        Task {
            do {
                try await supabase.rejectPartnerRequest(request.id)
                incomingRequests.removeAll { $0.id == request.id }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    PartnerView()
        .environmentObject(GameEngine())
}
