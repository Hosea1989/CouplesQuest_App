import SwiftUI
import SwiftData

// Research content has been moved to Views/Research/ResearchStoreView.swift.
// ResearchNodeRow and ResearchNodeDetailSheet remain here as shared components.

// MARK: - Research Node Row

struct ResearchNodeRow: View {
    let node: ResearchNode
    let character: PlayerCharacter
    let isLast: Bool
    let onTap: () -> Void
    
    private var status: NodeStatus {
        if character.hasCompletedResearchNode(node.id) {
            return .completed
        } else if character.isResearching(node.id) {
            return .researching
        } else if character.canUnlockResearchNode(node) {
            return .available
        } else {
            return .locked
        }
    }
    
    private enum NodeStatus {
        case completed, researching, available, locked
    }
    
    private var nodeRarity: ItemRarity {
        switch node.tier {
        case 1: return .common
        case 2: return .uncommon
        case 3: return .rare
        case 4: return .epic
        default: return .legendary
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    if !isLast {
                        VStack {
                            Spacer()
                            Rectangle()
                                .fill(status == .completed ? Color(node.branch.color).opacity(0.5) : Color.secondary.opacity(0.2))
                                .frame(width: 2, height: 20)
                        }
                        .frame(height: 56)
                        .offset(y: 18)
                    }
                    
                    ZStack {
                        Circle()
                            .fill(nodeBackgroundColor)
                            .frame(width: 40, height: 40)
                        
                        if status == .available || status == .completed {
                            TomeIconView(rarity: nodeRarity, size: 32)
                        } else {
                            Image(systemName: nodeIcon)
                                .font(.system(size: 16))
                                .foregroundColor(nodeIconColor)
                        }
                    }
                }
                .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(node.name)
                            .font(.custom("Avenir-Heavy", size: 14))
                            .foregroundColor(status == .locked ? .secondary : .primary)
                        
                        if status == .researching {
                            Text("IN PROGRESS")
                                .font(.custom("Avenir-Heavy", size: 9))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color("AccentPurple"))
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(node.formattedBonus)
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(status == .locked ? .secondary.opacity(0.6) : Color(node.branch.color))
                }
                
                Spacer()
                
                switch status {
                case .completed:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color("AccentGreen"))
                case .researching:
                    if let remaining = character.researchTimeRemaining, remaining > 0 {
                        Image(systemName: "hourglass")
                            .foregroundColor(Color("AccentPurple"))
                            .symbolEffect(.pulse, options: .repeating)
                    } else {
                        Text("Ready!")
                            .font(.custom("Avenir-Heavy", size: 12))
                            .foregroundColor(Color("AccentGreen"))
                    }
                case .available:
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color(node.branch.color))
                case .locked:
                    Image(systemName: "lock.fill")
                        .foregroundColor(.secondary.opacity(0.5))
                        .font(.system(size: 12))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        
        if !isLast {
            Divider()
                .padding(.leading, 68)
        }
    }
    
    private var nodeBackgroundColor: Color {
        switch status {
        case .completed:
            return Color(node.branch.color).opacity(0.2)
        case .researching:
            return Color("AccentPurple").opacity(0.2)
        case .available:
            return Color(node.branch.color).opacity(0.1)
        case .locked:
            return Color.secondary.opacity(0.08)
        }
    }
    
    private var nodeIcon: String {
        switch status {
        case .completed:
            return "checkmark"
        case .researching:
            return "hourglass"
        case .available:
            return node.branch.icon
        case .locked:
            return "lock.fill"
        }
    }
    
    private var nodeIconColor: Color {
        switch status {
        case .completed:
            return Color("AccentGreen")
        case .researching:
            return Color("AccentPurple")
        case .available:
            return Color(node.branch.color)
        case .locked:
            return .secondary.opacity(0.5)
        }
    }
}

// MARK: - Research Node Detail Sheet

struct ResearchNodeDetailSheet: View {
    let node: ResearchNode
    let character: PlayerCharacter
    let materials: [CraftingMaterial]
    let onStartResearch: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    private var isCompleted: Bool {
        character.hasCompletedResearchNode(node.id)
    }
    
    private var isResearching: Bool {
        character.isResearching(node.id)
    }
    
    private var canAfford: Bool {
        guard character.gold >= node.goldCost else { return false }
        guard researchTokenCount >= node.researchTokenCost else { return false }
        for cost in node.materialCosts {
            if materialCount(type: cost.materialType, rarity: cost.rarity) < cost.quantity {
                return false
            }
        }
        return true
    }
    
    private var canStart: Bool {
        character.canUnlockResearchNode(node) && canAfford
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
                    VStack(spacing: 20) {
                        nodeHeader
                        descriptionCard
                        statusCard
                        
                        if !isCompleted && !isResearching {
                            costCard
                        }
                        
                        if !isCompleted && !isResearching {
                            actionButton
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Research Node")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(Color("AccentGold"))
                }
            }
        }
    }
    
    // MARK: - Node Header
    
    private var tomeRarity: ItemRarity {
        switch node.tier {
        case 1: return .common
        case 2: return .uncommon
        case 3: return .rare
        case 4: return .epic
        default: return .legendary
        }
    }
    
    private var nodeHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(node.branch.color), Color(node.branch.color).opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)
                
                TomeIconView(rarity: tomeRarity, size: 70)
            }
            
            Text(node.name)
                .font(.custom("Avenir-Heavy", size: 22))
            
            HStack(spacing: 8) {
                Text(node.branch.displayName)
                    .font(.custom("Avenir-Medium", size: 13))
                    .foregroundColor(Color(node.branch.color))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(node.branch.color).opacity(0.15))
                    .cornerRadius(8)
                
                Text("Tier \(node.tier)")
                    .font(.custom("Avenir-Medium", size: 13))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color("CardBackground"))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Description Card
    
    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "text.book.closed.fill")
                    .foregroundColor(Color("AccentGold"))
                Text("Effect")
                    .font(.custom("Avenir-Heavy", size: 16))
                Spacer()
            }
            
            Text(node.nodeDescription)
                .font(.custom("Avenir-Medium", size: 14))
                .foregroundColor(.secondary)
            
            HStack {
                Text("Bonus:")
                    .font(.custom("Avenir-Medium", size: 14))
                Text(node.formattedBonus)
                    .font(.custom("Avenir-Heavy", size: 14))
                    .foregroundColor(Color(node.branch.color))
            }
            
            if isCompleted {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color("AccentGreen"))
                    Text("This bonus is permanently active")
                        .font(.custom("Avenir-Medium", size: 13))
                        .foregroundColor(Color("AccentGreen"))
                }
            }
        }
        .padding(16)
        .background(Color("CardBackground"))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Status Card
    
    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(Color("AccentGold"))
                Text("Status")
                    .font(.custom("Avenir-Heavy", size: 16))
                Spacer()
            }
            
            if isCompleted {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(Color("AccentGreen"))
                    Text("Completed")
                        .font(.custom("Avenir-Heavy", size: 14))
                        .foregroundColor(Color("AccentGreen"))
                }
            } else if isResearching {
                HStack {
                    Image(systemName: "hourglass")
                        .foregroundColor(Color("AccentPurple"))
                        .symbolEffect(.pulse, options: .repeating)
                    Text("In Progress")
                        .font(.custom("Avenir-Heavy", size: 14))
                        .foregroundColor(Color("AccentPurple"))
                }
            } else if let prereq = node.prerequisiteNodeID,
                      !character.hasCompletedResearchNode(prereq),
                      let prereqNode = ResearchTree.node(withID: prereq) {
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.secondary)
                    Text("Requires: \(prereqNode.name)")
                        .font(.custom("Avenir-Medium", size: 14))
                        .foregroundColor(.secondary)
                }
            } else if character.isResearchActive && !character.isResearchComplete {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.secondary)
                    Text("Another research is in progress")
                        .font(.custom("Avenir-Medium", size: 14))
                        .foregroundColor(.secondary)
                }
            } else {
                HStack {
                    Image(systemName: "play.circle.fill")
                        .foregroundColor(Color(node.branch.color))
                    Text("Available to research")
                        .font(.custom("Avenir-Heavy", size: 14))
                        .foregroundColor(Color(node.branch.color))
                }
            }
            
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.secondary)
                Text("Research time: \(node.formattedDuration)")
                    .font(.custom("Avenir-Medium", size: 13))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color("CardBackground"))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Cost Card
    
    private var costCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bag.fill")
                    .foregroundColor(Color("AccentGold"))
                Text("Cost")
                    .font(.custom("Avenir-Heavy", size: 16))
                Spacer()
            }
            
            costRow(
                icon: "dollarsign.circle.fill",
                label: "Gold",
                required: node.goldCost,
                available: character.gold,
                color: "AccentGold"
            )
            
            tomeCostRow(
                required: node.researchTokenCost,
                available: researchTokenCount
            )
            
            ForEach(Array(node.materialCosts.enumerated()), id: \.offset) { _, cost in
                costRow(
                    icon: (MaterialType(rawValue: cost.materialType) ?? .essence).icon,
                    label: "\(cost.rarity.capitalized) \(cost.materialType)",
                    required: cost.quantity,
                    available: materialCount(type: cost.materialType, rarity: cost.rarity),
                    color: (MaterialType(rawValue: cost.materialType) ?? .essence).color
                )
            }
        }
        .padding(16)
        .background(Color("CardBackground"))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    @ViewBuilder
    private func costRow(icon: String, label: String, required: Int, available: Int, color: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color(color))
                .frame(width: 20)
            Text(label)
                .font(.custom("Avenir-Medium", size: 13))
            Spacer()
            Text("\(available)")
                .font(.custom("Avenir-Heavy", size: 13))
                .foregroundColor(available >= required ? Color("AccentGreen") : Color("AccentOrange"))
            Text("/")
                .font(.custom("Avenir-Medium", size: 13))
                .foregroundColor(.secondary)
            Text("\(required)")
                .font(.custom("Avenir-Heavy", size: 13))
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private func tomeCostRow(required: Int, available: Int) -> some View {
        HStack {
            TomeIconView(rarity: tomeRarity, size: 24)
                .frame(width: 20, height: 20)
            Text("Tomes")
                .font(.custom("Avenir-Medium", size: 13))
            Spacer()
            Text("\(available)")
                .font(.custom("Avenir-Heavy", size: 13))
                .foregroundColor(available >= required ? Color("AccentGreen") : Color("AccentOrange"))
            Text("/")
                .font(.custom("Avenir-Medium", size: 13))
                .foregroundColor(.secondary)
            Text("\(required)")
                .font(.custom("Avenir-Heavy", size: 13))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Action Button
    
    private var actionButton: some View {
        Button(action: {
            onStartResearch()
        }) {
            HStack {
                Image(systemName: "play.fill")
                Text("Begin Research")
                    .font(.custom("Avenir-Heavy", size: 16))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                canStart ?
                LinearGradient(
                    colors: [Color(node.branch.color), Color(node.branch.color).opacity(0.7)],
                    startPoint: .leading,
                    endPoint: .trailing
                ) :
                LinearGradient(
                    colors: [Color.secondary.opacity(0.3), Color.secondary.opacity(0.2)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .disabled(!canStart)
    }
    
    // MARK: - Helpers
    
    private var researchTokenCount: Int {
        materials.filter { $0.materialType == .researchToken && $0.characterID == character.id }
            .reduce(0) { $0 + $1.quantity }
    }
    
    private func materialCount(type: String, rarity: String) -> Int {
        materials.filter {
            $0.materialType.rawValue == type &&
            $0.rarity.rawValue.lowercased() == rarity.lowercased() &&
            $0.characterID == character.id
        }.reduce(0) { $0 + $1.quantity }
    }
}
