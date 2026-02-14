import SwiftUI
import SwiftData

// MARK: - Bestiary Tab Content

/// 5th pill tab in CharacterView — card collection grid, milestones, and total bonus summary.
struct BestiaryTabContent: View {
    let character: PlayerCharacter
    
    @Environment(\.modelContext) private var modelContext
    @Query private var allCards: [MonsterCard]
    
    /// Cards owned by this character
    private var collectedCards: [MonsterCard] {
        allCards.filter { $0.ownerID == character.id && $0.isCollected }
    }
    
    /// Content definitions from server
    private var allContentCards: [ContentCard] {
        ContentManager.shared.cards.filter { $0.active }
    }
    
    /// Total card bonuses
    private var bonusSummary: CardBonusCalculator.CardBonusSummary {
        CardBonusCalculator.totalBonuses(from: collectedCards)
    }
    
    /// Grouped cards by theme
    private var themes: [String] {
        let allThemes = allContentCards.map { $0.theme }
        return Array(Set(allThemes)).sorted()
    }
    
    @State private var selectedThemeFilter: String? = nil
    @State private var showMilestones = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Card Collector NPC
            CardCollectorNPC(
                collectedCount: collectedCards.count,
                totalCount: allContentCards.count,
                themes: themes,
                collectedCards: collectedCards,
                allContentCards: allContentCards
            )
            
            // Bonus Summary Card
            BonusSummaryCard(
                bonusSummary: bonusSummary,
                collectedCount: collectedCards.count,
                totalCount: allContentCards.count
            )
            
            // Milestones Card
            MilestonesCard(
                collectedCount: collectedCards.count,
                showMilestones: $showMilestones
            )
            
            // Theme filter
            ThemeFilterBar(
                themes: themes,
                selectedTheme: $selectedThemeFilter
            )
            
            // Card Grid
            CardCollectionGrid(
                collectedCards: collectedCards,
                allContentCards: allContentCards,
                themeFilter: selectedThemeFilter
            )
        }
    }
}

// MARK: - Card Collector NPC

struct CardCollectorNPC: View {
    let collectedCount: Int
    let totalCount: Int
    let themes: [String]
    let collectedCards: [MonsterCard]
    let allContentCards: [ContentCard]
    
    private var npcDialogue: String {
        if collectedCount == 0 {
            return "Welcome, adventurer! Defeat monsters to collect their cards. Each card grants a permanent bonus!"
        }
        
        if collectedCount >= totalCount && totalCount > 0 {
            return "Incredible! You've collected every single card! You are a true Monster Scholar!"
        }
        
        // Find the theme closest to completion
        let themeProgress = themes.compactMap { theme -> (String, Int, Int)? in
            let total = allContentCards.filter { $0.theme == theme }.count
            let collected = collectedCards.filter { $0.theme == theme }.count
            guard total > 0 && collected < total else { return nil }
            return (theme.capitalized, collected, total)
        }.sorted { ($0.2 - $0.1) < ($1.2 - $1.1) }
        
        if let closest = themeProgress.first {
            let remaining = closest.2 - closest.1
            return "Only \(remaining) more \(closest.0) card\(remaining == 1 ? "" : "s") to go! Keep exploring those dungeons!"
        }
        
        return "Keep collecting cards! Each one makes you a little bit stronger."
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // NPC avatar
            ZStack {
                Circle()
                    .fill(Color("AccentPurple").opacity(0.2))
                    .frame(width: 48, height: 48)
                Image(systemName: "person.crop.square.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color("AccentPurple"))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Card Collector")
                    .font(.custom("Avenir-Heavy", size: 13))
                    .foregroundColor(Color("AccentPurple"))
                Text(npcDialogue)
                    .font(.custom("Avenir-Medium", size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("AccentPurple").opacity(0.08))
        )
    }
}

// MARK: - Bonus Summary Card

struct BonusSummaryCard: View {
    let bonusSummary: CardBonusCalculator.CardBonusSummary
    let collectedCount: Int
    let totalCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(Color("AccentGold"))
                Text("Card Bonuses")
                    .font(.custom("Avenir-Heavy", size: 16))
                Spacer()
                Text("\(collectedCount)/\(max(totalCount, 50))")
                    .font(.custom("Avenir-Heavy", size: 14))
                    .foregroundColor(Color("AccentGold"))
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color("AccentGold").opacity(0.15))
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color("AccentGold"), Color("AccentOrange")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: max(0, geometry.size.width * CGFloat(collectedCount) / CGFloat(max(totalCount, 50))),
                            height: 8
                        )
                }
            }
            .frame(height: 8)
            
            // Bonus grid (2 columns)
            if collectedCount > 0 {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    if bonusSummary.expPercent > 0 {
                        BonusChip(
                            icon: "star.fill",
                            label: "EXP",
                            value: "+\(String(format: "%.1f", bonusSummary.expPercent * 100))%",
                            color: "AccentGold"
                        )
                    }
                    if bonusSummary.goldPercent > 0 {
                        BonusChip(
                            icon: "dollarsign.circle.fill",
                            label: "Gold",
                            value: "+\(String(format: "%.1f", bonusSummary.goldPercent * 100))%",
                            color: "AccentOrange"
                        )
                    }
                    if bonusSummary.dungeonSuccessPercent > 0 {
                        BonusChip(
                            icon: "shield.checkered",
                            label: "Dungeon",
                            value: "+\(String(format: "%.1f", bonusSummary.dungeonSuccessPercent * 100))%",
                            color: "AccentGreen"
                        )
                    }
                    if bonusSummary.lootChancePercent > 0 {
                        BonusChip(
                            icon: "gift.fill",
                            label: "Loot",
                            value: "+\(String(format: "%.1f", bonusSummary.lootChancePercent * 100))%",
                            color: "AccentPurple"
                        )
                    }
                    if bonusSummary.missionSpeedPercent > 0 {
                        BonusChip(
                            icon: "bolt.fill",
                            label: "Speed",
                            value: "+\(String(format: "%.1f", bonusSummary.missionSpeedPercent * 100))%",
                            color: "AccentPink"
                        )
                    }
                    if bonusSummary.flatDefense > 0 {
                        BonusChip(
                            icon: "shield.fill",
                            label: "DEF",
                            value: "+\(String(format: "%.1f", bonusSummary.flatDefense))",
                            color: "StatDefense"
                        )
                    }
                }
            } else {
                Text("Collect cards to earn permanent bonuses!")
                    .font(.custom("Avenir-Medium", size: 13))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
        .padding(16)
        .background(Color("CardBackground"))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

struct BonusChip: View {
    let icon: String
    let label: String
    let value: String
    let color: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(Color(color))
            Text(label)
                .font(.custom("Avenir-Medium", size: 11))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.custom("Avenir-Heavy", size: 12))
                .foregroundColor(Color(color))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(color).opacity(0.1))
        )
    }
}

// MARK: - Milestones Card

struct MilestonesCard: View {
    let collectedCount: Int
    @Binding var showMilestones: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: { withAnimation(.easeInOut(duration: 0.25)) { showMilestones.toggle() } }) {
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(Color("AccentGold"))
                    Text("Collection Milestones")
                        .font(.custom("Avenir-Heavy", size: 16))
                    Spacer()
                    Image(systemName: showMilestones ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            if showMilestones {
                ForEach(CardCollectionMilestone.allCases, id: \.rawValue) { milestone in
                    MilestoneRow(
                        milestone: milestone,
                        isReached: collectedCount >= milestone.rawValue
                    )
                }
            }
        }
        .padding(16)
        .background(Color("CardBackground"))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

struct MilestoneRow: View {
    let milestone: CardCollectionMilestone
    let isReached: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isReached ? Color(milestone.color).opacity(0.2) : Color.secondary.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                if isReached {
                    Circle()
                        .stroke(Color(milestone.color), lineWidth: 2)
                        .frame(width: 36, height: 36)
                }
                
                Image(systemName: milestone.icon)
                    .font(.system(size: 14))
                    .foregroundColor(isReached ? Color(milestone.color) : .secondary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(milestone.label)
                    .font(.custom("Avenir-Heavy", size: 13))
                    .foregroundColor(isReached ? .primary : .secondary)
                Text(milestone.rewardDescription)
                    .font(.custom("Avenir-Medium", size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isReached {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color("AccentGreen"))
            }
        }
    }
}

// MARK: - Theme Filter Bar

struct ThemeFilterBar: View {
    let themes: [String]
    @Binding var selectedTheme: String?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" button
                BestiaryFilterChip(
                    label: "All",
                    isSelected: selectedTheme == nil,
                    action: { selectedTheme = nil }
                )
                
                ForEach(themes, id: \.self) { theme in
                    BestiaryFilterChip(
                        label: theme.capitalized,
                        isSelected: selectedTheme == theme,
                        action: { selectedTheme = (selectedTheme == theme) ? nil : theme }
                    )
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

struct BestiaryFilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.custom("Avenir-Heavy", size: 12))
                .foregroundColor(isSelected ? .white : .secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? Color("AccentGold") : Color("CardBackground"))
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color.secondary.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Card Collection Grid

struct CardCollectionGrid: View {
    let collectedCards: [MonsterCard]
    let allContentCards: [ContentCard]
    let themeFilter: String?
    
    private var filteredContentCards: [ContentCard] {
        if let filter = themeFilter {
            return allContentCards.filter { $0.theme == filter }
        }
        return allContentCards
    }
    
    private var collectedCardIDs: Set<String> {
        Set(collectedCards.map { $0.cardID })
    }
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        if filteredContentCards.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "rectangle.stack.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.secondary)
                Text("No Cards Available")
                    .font(.custom("Avenir-Heavy", size: 16))
                Text("Cards will appear here as content is loaded from the server.")
                    .font(.custom("Avenir-Medium", size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
            .frame(maxWidth: .infinity)
            .background(Color("CardBackground"))
            .cornerRadius(16)
        } else {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(filteredContentCards, id: \.id) { contentCard in
                    let isCollected = collectedCardIDs.contains(contentCard.id)
                    let monsterCard = collectedCards.first { $0.cardID == contentCard.id }
                    
                    CardTile(
                        contentCard: contentCard,
                        monsterCard: monsterCard,
                        isCollected: isCollected
                    )
                }
            }
            .padding(16)
            .background(Color("CardBackground"))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - Card Tile

struct CardTile: View {
    let contentCard: ContentCard
    let monsterCard: MonsterCard?
    let isCollected: Bool
    
    @State private var showDetail = false
    
    private var rarityColor: String {
        switch contentCard.rarity {
        case "common": return "RarityCommon"
        case "uncommon": return "RarityUncommon"
        case "rare": return "RarityRare"
        case "epic": return "RarityEpic"
        case "legendary": return "RarityLegendary"
        default: return "RarityCommon"
        }
    }
    
    private var themeIcon: String {
        switch contentCard.theme {
        case "cave": return "mountain.2.fill"
        case "ruins": return "building.columns.fill"
        case "forest": return "leaf.fill"
        case "fortress": return "building.fill"
        case "volcano": return "flame.fill"
        case "abyss": return "tornado"
        case "arena": return "figure.fencing"
        case "raid": return "bolt.shield.fill"
        case "expedition": return "map.fill"
        default: return "questionmark.square.fill"
        }
    }
    
    var body: some View {
        Button(action: { if isCollected { showDetail = true } }) {
            VStack(spacing: 6) {
                // Card image area
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isCollected ? Color(rarityColor).opacity(0.15) : Color.secondary.opacity(0.08))
                        .frame(height: 70)
                    
                    if isCollected {
                        // Collected: show theme icon with rarity border
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(rarityColor), lineWidth: 2)
                            .frame(height: 70)
                        
                        Image(systemName: themeIcon)
                            .font(.system(size: 28))
                            .foregroundColor(Color(rarityColor))
                    } else {
                        // Undiscovered: silhouette
                        Image(systemName: "questionmark")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary.opacity(0.3))
                    }
                }
                
                // Card name
                Text(isCollected ? contentCard.name : "???")
                    .font(.custom("Avenir-Heavy", size: 10))
                    .foregroundColor(isCollected ? .primary : .secondary.opacity(0.5))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                // Rarity badge
                if isCollected {
                    Text(contentCard.rarity.capitalized)
                        .font(.custom("Avenir-Heavy", size: 8))
                        .foregroundColor(Color(rarityColor))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color(rarityColor).opacity(0.15))
                        )
                }
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            if let card = monsterCard {
                CardDetailSheet(
                    contentCard: contentCard,
                    monsterCard: card
                )
            }
        }
    }
}

// MARK: - Card Detail Sheet

struct CardDetailSheet: View {
    let contentCard: ContentCard
    let monsterCard: MonsterCard
    @Environment(\.dismiss) private var dismiss
    
    private var rarityColor: String {
        switch contentCard.rarity {
        case "common": return "RarityCommon"
        case "uncommon": return "RarityUncommon"
        case "rare": return "RarityRare"
        case "epic": return "RarityEpic"
        case "legendary": return "RarityLegendary"
        default: return "RarityCommon"
        }
    }
    
    private var themeIcon: String {
        switch contentCard.theme {
        case "cave": return "mountain.2.fill"
        case "ruins": return "building.columns.fill"
        case "forest": return "leaf.fill"
        case "fortress": return "building.fill"
        case "volcano": return "flame.fill"
        case "abyss": return "tornado"
        case "arena": return "figure.fencing"
        case "raid": return "bolt.shield.fill"
        case "expedition": return "map.fill"
        default: return "questionmark.square.fill"
        }
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
                    VStack(spacing: 24) {
                        // Large card display
                        VStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(rarityColor).opacity(0.15))
                                    .frame(width: 160, height: 200)
                                
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(rarityColor), lineWidth: 3)
                                    .frame(width: 160, height: 200)
                                
                                VStack(spacing: 12) {
                                    Image(systemName: themeIcon)
                                        .font(.system(size: 56))
                                        .foregroundColor(Color(rarityColor))
                                    
                                    Text(contentCard.rarity.capitalized)
                                        .font(.custom("Avenir-Heavy", size: 12))
                                        .foregroundColor(Color(rarityColor))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(Color(rarityColor).opacity(0.2))
                                        )
                                }
                            }
                            
                            Text(monsterCard.name)
                                .font(.custom("Avenir-Heavy", size: 24))
                            
                            if !monsterCard.cardDescription.isEmpty {
                                Text(monsterCard.cardDescription)
                                    .font(.custom("Avenir-Medium", size: 14))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                            }
                        }
                        
                        // Bonus info card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: monsterCard.bonusType.icon)
                                    .foregroundColor(Color("AccentGold"))
                                Text("Passive Bonus")
                                    .font(.custom("Avenir-Heavy", size: 16))
                                Spacer()
                            }
                            
                            HStack {
                                Text(monsterCard.bonusType.displayName)
                                    .font(.custom("Avenir-Medium", size: 14))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(monsterCard.bonusType.formatValue(monsterCard.bonusValue))
                                    .font(.custom("Avenir-Heavy", size: 16))
                                    .foregroundColor(Color("AccentGreen"))
                            }
                        }
                        .padding(16)
                        .background(Color("CardBackground"))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                        
                        // Source info card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: monsterCard.sourceType.icon)
                                    .foregroundColor(Color("AccentPurple"))
                                Text("Source")
                                    .font(.custom("Avenir-Heavy", size: 16))
                                Spacer()
                            }
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(monsterCard.sourceType.displayName)
                                        .font(.custom("Avenir-Heavy", size: 14))
                                    if !monsterCard.sourceName.isEmpty {
                                        Text(monsterCard.sourceName)
                                            .font(.custom("Avenir-Medium", size: 13))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                
                                Text("Theme: \(monsterCard.theme.capitalized)")
                                    .font(.custom("Avenir-Medium", size: 12))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color.secondary.opacity(0.1))
                                    )
                            }
                            
                            if let date = monsterCard.collectedAt {
                                HStack {
                                    Text("Collected")
                                        .font(.custom("Avenir-Medium", size: 12))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.custom("Avenir-Medium", size: 12))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color("CardBackground"))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                    }
                    .padding()
                }
            }
            .navigationTitle("Card Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color("AccentGold"))
                }
            }
        }
    }
}
