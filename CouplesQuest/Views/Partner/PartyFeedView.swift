import SwiftUI
import SwiftData

/// Activity feed showing party member events via Supabase Realtime subscription.
/// Events: task completions, loot drops, card discoveries, level ups, achievements, streaks.
struct PartyFeedView: View {
    let partyID: UUID
    
    @State private var feedEvents: [PartyFeedEvent] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var memberNames: [UUID: String] = [:]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundColor(Color("AccentPink"))
                Text("Party Feed")
                    .font(.custom("Avenir-Heavy", size: 16))
                Spacer()
                
                if !feedEvents.isEmpty {
                    Text("\(feedEvents.count) events")
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding(.vertical, 20)
                    Spacer()
                }
            } else if feedEvents.isEmpty {
                emptyFeedState
            } else {
                feedList
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
        .task {
            await loadFeed()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyFeedState: some View {
        VStack(spacing: 8) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.title2)
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("No activity yet")
                .font(.custom("Avenir-Medium", size: 14))
                .foregroundColor(.secondary)
            
            Text("Complete tasks, run dungeons, or discover cards to see activity here!")
                .font(.custom("Avenir-Medium", size: 12))
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Feed List
    
    private var feedList: some View {
        VStack(spacing: 10) {
            ForEach(Array(feedEvents.prefix(20)), id: \.id) { event in
                feedEventRow(event)
                
                if event.id != feedEvents.prefix(20).last?.id {
                    Divider()
                }
            }
        }
    }
    
    private func feedEventRow(_ event: PartyFeedEvent) -> some View {
        HStack(alignment: .top, spacing: 10) {
            // Event icon
            Image(systemName: event.eventIcon)
                .foregroundColor(Color(event.eventColor))
                .font(.callout)
                .frame(width: 24)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 3) {
                // Actor name + event
                HStack(spacing: 4) {
                    Text(memberNames[event.actorID] ?? "Ally")
                        .font(.custom("Avenir-Heavy", size: 13))
                        .foregroundColor(Color("AccentPink"))
                    
                    Text(event.message)
                        .font(.custom("Avenir-Medium", size: 13))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }
                
                // Metadata (optional details)
                if let detail = event.metadata["detail"] {
                    Text(detail)
                        .font(.custom("Avenir-Medium", size: 11))
                        .foregroundColor(.secondary)
                }
                
                // Timestamp
                Text(event.createdAt, style: .relative)
                    .font(.custom("Avenir-Medium", size: 10))
                    .foregroundColor(.secondary.opacity(0.7))
            }
            
            Spacer()
        }
    }
    
    // MARK: - Data Loading
    
    private func loadFeed() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Fetch recent feed events from Supabase
            let events: [SupabasePartyFeedRow] = try await SupabaseService.shared.client
                .from("party_feed")
                .select()
                .eq("party_id", value: partyID.uuidString)
                .order("created_at", ascending: false)
                .limit(30)
                .execute()
                .value
            
            feedEvents = events.map { row in
                PartyFeedEvent(
                    id: row.id,
                    partyID: row.partyID,
                    actorID: row.actorID,
                    eventType: row.eventType,
                    message: row.message,
                    metadata: row.metadata,
                    createdAt: row.createdAt
                )
            }
            
            // Build member name map
            let uniqueActorIDs = Set(feedEvents.map(\.actorID))
            for actorID in uniqueActorIDs {
                if memberNames[actorID] == nil {
                    // Try to load from Supabase profiles
                    if let profiles: [ProfileName] = try? await SupabaseService.shared.client
                        .from("profiles")
                        .select("id, character_name")
                        .eq("id", value: actorID.uuidString)
                        .execute()
                        .value,
                       let profile = profiles.first {
                        memberNames[actorID] = profile.characterName ?? "Ally"
                    }
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Supabase Row Models

/// Maps to the party_feed table row
private struct SupabasePartyFeedRow: Codable {
    let id: UUID
    let partyID: UUID
    let actorID: UUID
    let eventType: String
    let message: String
    let metadata: [String: String]
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case partyID = "party_id"
        case actorID = "actor_id"
        case eventType = "event_type"
        case message
        case metadata
        case createdAt = "created_at"
    }
}

/// Lightweight profile for name lookup
private struct ProfileName: Codable {
    let id: UUID
    let characterName: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case characterName = "character_name"
    }
}

// MARK: - Inline Party Feed Card (for embedding in PartyView)

/// A compact party feed card for embedding in the main Party dashboard
struct PartyFeedCard: View {
    let partyID: UUID?
    @Query(sort: \PartnerInteraction.createdAt, order: .reverse) private var localInteractions: [PartnerInteraction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundColor(Color("AccentPink"))
                Text("Party Feed")
                    .font(.custom("Avenir-Heavy", size: 16))
                Spacer()
            }
            
            if let partyID = partyID {
                // Live feed from Supabase
                PartyFeedView(partyID: partyID)
                    .padding(-16) // Negate the parent padding for seamless nesting
            } else {
                // Fallback to local interactions
                localFeedFallback
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
    }
    
    private var localFeedFallback: some View {
        VStack(spacing: 8) {
            if localInteractions.isEmpty {
                Text("No recent activity")
                    .font(.custom("Avenir-Medium", size: 13))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 12)
            } else {
                ForEach(Array(localInteractions.prefix(5)), id: \.id) { interaction in
                    HStack(spacing: 10) {
                        Image(systemName: interaction.type.icon)
                            .foregroundColor(Color(interaction.type.color))
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(interaction.type.rawValue)
                                .font(.custom("Avenir-Heavy", size: 13))
                            if let message = interaction.message {
                                Text(message)
                                    .font(.custom("Avenir-Medium", size: 11))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                        
                        Text(interaction.createdAt, style: .relative)
                            .font(.custom("Avenir-Medium", size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    if interaction.id != localInteractions.prefix(5).last?.id {
                        Divider()
                    }
                }
            }
        }
    }
}
