import SwiftUI
import SwiftData

// MARK: - Unified Activity Item

/// Merges local PartnerInteraction and remote PartyFeedEvent into a single timeline.
struct PartyActivityItem: Identifiable {
    let id: UUID
    let actorID: UUID
    let actorName: String
    let eventType: String
    let message: String
    let icon: String
    let color: String
    let timestamp: Date
    
    /// Create from a remote PartyFeedEvent
    init(feedEvent: PartyFeedEvent, actorName: String) {
        self.id = feedEvent.id
        self.actorID = feedEvent.actorID
        self.actorName = actorName
        self.eventType = feedEvent.eventType
        self.message = feedEvent.message
        self.icon = feedEvent.eventIcon
        self.color = feedEvent.eventColor
        self.timestamp = feedEvent.createdAt
    }
    
    /// Create from a local PartnerInteraction
    init(interaction: PartnerInteraction, actorName: String) {
        self.id = interaction.id
        self.actorID = interaction.fromCharacterID
        self.actorName = actorName
        self.eventType = interaction.type.rawValue.lowercased().replacingOccurrences(of: " ", with: "_")
        self.message = interaction.message ?? interaction.type.defaultMessage
        self.icon = interaction.type.icon
        self.color = interaction.type.color
        self.timestamp = interaction.createdAt
    }
    
    /// Themed display title (creative phrasing)
    var themedTitle: String {
        switch eventType {
        case "kudos":
            return "\(actorName) cheered for you!"
        case "nudge":
            return "\(actorName) poked you!"
        case "challenge":
            return "\(actorName) issued a challenge!"
        case "task_completed":
            return message
        case "dungeon_loot":
            return message
        case "level_up":
            return message
        case "streak_milestone":
            return message
        case "card_discovered":
            return "\(actorName) discovered a new card!"
        case "achievement":
            return "\(actorName) earned an achievement!"
        case "enhancement_success":
            return "\(actorName) enhanced their gear!"
        default:
            return message
        }
    }
    
    /// Themed subtitle (flavor text)
    var themedSubtitle: String? {
        switch eventType {
        case "kudos":
            return message == InteractionType.kudos.defaultMessage ? "Keep up the great work!" : message
        case "nudge":
            return message == InteractionType.nudge.defaultMessage ? "Get questing, adventurer!" : message
        case "challenge":
            return message
        case "level_up":
            return "A new milestone on the adventure!"
        case "streak_milestone":
            return "Consistency is the real superpower."
        case "dungeon_loot":
            return "The dungeon has been conquered!"
        default:
            return nil
        }
    }
    
    /// Background gradient colors for themed card
    var cardGradientColors: [Color] {
        switch eventType {
        case "kudos":
            return [Color("AccentGreen").opacity(0.12), Color("AccentGreen").opacity(0.04)]
        case "nudge":
            return [Color("AccentPurple").opacity(0.12), Color("AccentPurple").opacity(0.04)]
        case "task_completed":
            return [Color("AccentGreen").opacity(0.08), Color("AccentGreen").opacity(0.02)]
        case "dungeon_loot":
            return [Color("AccentGold").opacity(0.12), Color("AccentGold").opacity(0.04)]
        case "level_up":
            return [Color("AccentGold").opacity(0.15), Color("AccentOrange").opacity(0.05)]
        case "streak_milestone":
            return [Color("AccentOrange").opacity(0.12), Color("AccentOrange").opacity(0.04)]
        case "challenge":
            return [Color("AccentGold").opacity(0.10), Color("AccentGold").opacity(0.03)]
        default:
            return [Color("CardBackground"), Color("CardBackground")]
        }
    }
}

// MARK: - Themed Activity Event Row

/// A single activity event row with creative themed styling per event type.
struct PartyActivityEventRow: View {
    let item: PartyActivityItem
    let isCompact: Bool
    
    init(item: PartyActivityItem, isCompact: Bool = false) {
        self.item = item
        self.isCompact = isCompact
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Themed icon with colored background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: item.cardGradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: isCompact ? 34 : 38, height: isCompact ? 34 : 38)
                
                Image(systemName: item.icon)
                    .font(.system(size: isCompact ? 14 : 16))
                    .foregroundColor(Color(item.color))
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(item.themedTitle)
                    .font(.custom("Avenir-Heavy", size: isCompact ? 13 : 14))
                    .lineLimit(2)
                
                if !isCompact, let subtitle = item.themedSubtitle {
                    Text(subtitle)
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Text(item.timestamp.timeAgoDisplay())
                    .font(.custom("Avenir-Medium", size: 11))
                    .foregroundColor(.secondary.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(.vertical, isCompact ? 6 : 8)
        .padding(.horizontal, isCompact ? 8 : 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: item.cardGradientColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
    }
}

// MARK: - Party Tavern Board Card (Preview Card)

/// The main activity feed card on the party screen. Shows 3 most recent events
/// with a "See All" button that navigates to the full activity list.
struct PartyTavernBoardCard: View {
    let items: [PartyActivityItem]
    let onSeeAll: () -> Void
    
    @State private var entranceVisible = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Image(systemName: "scroll.fill")
                    .foregroundColor(Color("AccentGold"))
                Text("Tavern Board")
                    .font(.custom("Avenir-Heavy", size: 16))
                
                Spacer()
                
                Button(action: onSeeAll) {
                    HStack(spacing: 4) {
                        Text("See All")
                            .font(.custom("Avenir-Heavy", size: 13))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(Color("AccentGold"))
                }
            }
            
            if items.isEmpty {
                // Empty state
                VStack(spacing: 10) {
                    Image(systemName: "scroll")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary.opacity(0.4))
                    
                    Text("The tavern board is quiet...")
                        .font(.custom("Avenir-Heavy", size: 14))
                        .foregroundColor(.secondary)
                    
                    Text("Go make some noise! Complete tasks, run dungeons, or cheer on your allies.")
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(items.prefix(3).enumerated()), id: \.element.id) { index, item in
                        PartyActivityEventRow(item: item, isCompact: true)
                            .opacity(entranceVisible ? 1 : 0)
                            .offset(y: entranceVisible ? 0 : 10)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.1), value: entranceVisible)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [Color("AccentGold").opacity(0.15), Color("AccentOrange").opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .onAppear {
            withAnimation {
                entranceVisible = true
            }
        }
    }
}

// MARK: - Full Activity Screen

/// Full-screen view showing all party activity, grouped by day.
struct PartyActivityFullView: View {
    let partyID: UUID?
    let localInteractions: [PartnerInteraction]
    let partyFeedEvents: [PartyFeedEvent]
    let memberNames: [UUID: String]
    
    @Environment(\.dismiss) private var dismiss
    @State private var allItems: [PartyActivityItem] = []
    @State private var isRefreshing = false
    @State private var refreshedFeedEvents: [PartyFeedEvent]?
    
    private var currentFeedEvents: [PartyFeedEvent] {
        refreshedFeedEvents ?? partyFeedEvents
    }
    
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
                    LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                        ForEach(groupedByDay, id: \.key) { group in
                            Section {
                                VStack(spacing: 8) {
                                    ForEach(group.items) { item in
                                        PartyActivityEventRow(item: item)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 16)
                            } header: {
                                HStack {
                                    Text(group.key)
                                        .font(.custom("Avenir-Heavy", size: 13))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    LinearGradient(
                                        colors: [Color("BackgroundTop"), Color("BackgroundTop").opacity(0.9)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            }
                        }
                        
                        if allItems.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "scroll")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary.opacity(0.3))
                                
                                Text("No activity yet")
                                    .font(.custom("Avenir-Heavy", size: 18))
                                    .foregroundColor(.secondary)
                                
                                Text("When you or your party members complete tasks, run dungeons, or send kudos, it will all show up here.")
                                    .font(.custom("Avenir-Medium", size: 14))
                                    .foregroundColor(.secondary.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            .padding(.top, 60)
                        }
                    }
                }
                .refreshable {
                    await refreshFeed()
                }
            }
            .navigationTitle("Party Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.custom("Avenir-Heavy", size: 15))
                        .foregroundColor(Color("AccentGold"))
                }
            }
            .onAppear {
                buildUnifiedFeed()
            }
        }
    }
    
    // MARK: - Day Grouping
    
    private struct DayGroup: Identifiable {
        let key: String
        let items: [PartyActivityItem]
        var id: String { key }
    }
    
    private var groupedByDay: [DayGroup] {
        let calendar = Calendar.current
        let now = Date()
        
        let grouped = Dictionary(grouping: allItems) { item -> String in
            if calendar.isDateInToday(item.timestamp) {
                return "Today"
            } else if calendar.isDateInYesterday(item.timestamp) {
                return "Yesterday"
            } else {
                let daysAgo = calendar.dateComponents([.day], from: item.timestamp, to: now).day ?? 0
                if daysAgo < 7 {
                    return "This Week"
                } else if daysAgo < 30 {
                    return "This Month"
                } else {
                    return "Earlier"
                }
            }
        }
        
        let order = ["Today", "Yesterday", "This Week", "This Month", "Earlier"]
        return order.compactMap { key in
            guard let items = grouped[key], !items.isEmpty else { return nil }
            return DayGroup(key: key, items: items)
        }
    }
    
    // MARK: - Build Feed
    
    private func buildUnifiedFeed() {
        var items: [PartyActivityItem] = []
        let myID = SupabaseService.shared.currentUserID
        
        // Add remote party feed events
        for event in currentFeedEvents {
            let name = memberNames[event.actorID] ?? "Ally"
            items.append(PartyActivityItem(feedEvent: event, actorName: name))
        }
        
        // Add local interactions (avoid duplicating events that may appear in both feeds)
        let feedIDs = Set(items.map(\.id))
        for interaction in localInteractions {
            guard !feedIDs.contains(interaction.id) else { continue }
            let isFromMe = interaction.fromCharacterID == myID
            let name = isFromMe ? "You" : (memberNames[interaction.fromCharacterID] ?? "Ally")
            items.append(PartyActivityItem(interaction: interaction, actorName: name))
        }
        
        // Sort newest first
        allItems = items.sorted { $0.timestamp > $1.timestamp }
    }
    
    private func refreshFeed() async {
        guard let partyID = partyID else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        
        do {
            refreshedFeedEvents = try await SupabaseService.shared.fetchPartyFeed(partyID: partyID, limit: 50)
            buildUnifiedFeed()
        } catch {
            print("⚠️ Failed to refresh party feed: \(error)")
        }
    }
}

// MARK: - Lightweight Profile Name (for actor name lookups)

struct ProfileName: Codable {
    let id: UUID
    let characterName: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case characterName = "character_name"
    }
}
