import SwiftUI
import SwiftData

// MARK: - Research Tab Content (Embedded in CharacterView)

struct ResearchTabContent: View {
    @Bindable var character: PlayerCharacter
    @EnvironmentObject var gameEngine: GameEngine
    @Environment(\.modelContext) private var modelContext
    @Query private var materials: [CraftingMaterial]
    
    @State private var selectedBranch: ResearchBranch = .combat
    @State private var selectedNode: ResearchNode? = nil
    @State private var showNodeDetail = false
    @State private var researchTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var showCompletionCelebration = false
    @State private var completedNodeName: String = ""
    
    var body: some View {
        VStack(spacing: 16) {
            // Active Research Banner
            if character.isResearchActive {
                activeResearchCard
            }
            
            // Research Progress Overview
            researchProgressCard
            
            // Branch Selector
            branchSelector
            
            // Branch Description
            branchDescriptionCard
            
            // Node List for Selected Branch
            nodeListCard
            
            // Active Bonuses Summary
            if character.completedResearchCount > 0 {
                activeBonusesCard
            }
        }
        .sheet(isPresented: $showNodeDetail) {
            if let node = selectedNode {
                ResearchNodeDetailSheet(
                    node: node,
                    character: character,
                    materials: materials,
                    onStartResearch: { startResearch(node: node) }
                )
            }
        }
        .overlay {
            if showCompletionCelebration {
                researchCompletionOverlay
            }
        }
        .onReceive(researchTimer) { _ in
            checkResearchCompletion()
        }
    }
    
    // MARK: - Active Research Card
    
    private var activeResearchCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "hourglass")
                    .foregroundColor(Color("AccentPurple"))
                    .symbolEffect(.pulse, options: .repeating)
                Text("Active Research")
                    .font(.custom("Avenir-Heavy", size: 16))
                Spacer()
                
                if character.isResearchComplete {
                    Button(action: claimResearch) {
                        Text("Claim")
                            .font(.custom("Avenir-Heavy", size: 14))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(
                                    colors: [Color("AccentGold"), Color("AccentOrange")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(8)
                    }
                }
            }
            
            if let nodeID = character.activeResearchNodeID,
               let node = ResearchTree.node(withID: nodeID) {
                HStack(spacing: 12) {
                    // Branch icon
                    Image(systemName: node.branch.icon)
                        .font(.title2)
                        .foregroundColor(Color(node.branch.color))
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color(node.branch.color).opacity(0.15))
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(node.name)
                            .font(.custom("Avenir-Heavy", size: 14))
                        
                        Text(node.formattedBonus)
                            .font(.custom("Avenir-Medium", size: 12))
                            .foregroundColor(Color(node.branch.color))
                    }
                    
                    Spacer()
                    
                    // Timer
                    if character.isResearchComplete {
                        Text("Complete!")
                            .font(.custom("Avenir-Heavy", size: 14))
                            .foregroundColor(Color("AccentGreen"))
                    } else if let remaining = character.researchTimeRemaining {
                        Text(formatTimeRemaining(remaining))
                            .font(.custom("Avenir-Heavy", size: 14))
                            .foregroundColor(Color("AccentGold"))
                            .monospacedDigit()
                    }
                }
                
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.15))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [Color(node.branch.color), Color(node.branch.color).opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * character.researchProgress, height: 8)
                            .animation(.easeInOut(duration: 0.4), value: character.researchProgress)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(16)
        .background(Color("CardBackground"))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Research Progress Card
    
    private var researchProgressCard: some View {
        HStack(spacing: 16) {
            // Nodes completed
            VStack(spacing: 4) {
                Text("\(character.completedResearchCount)")
                    .font(.custom("Avenir-Heavy", size: 24))
                    .foregroundColor(Color("AccentGold"))
                Text("Nodes")
                    .font(.custom("Avenir-Medium", size: 11))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .frame(height: 40)
            
            // Research Tokens
            VStack(spacing: 4) {
                Text("\(researchTokenCount)")
                    .font(.custom("Avenir-Heavy", size: 24))
                    .foregroundColor(Color("AccentPurple"))
                Text("Tokens")
                    .font(.custom("Avenir-Medium", size: 11))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .frame(height: 40)
            
            // Power bonus
            VStack(spacing: 4) {
                Text("+\(character.cachedResearchPowerBonus)")
                    .font(.custom("Avenir-Heavy", size: 24))
                    .foregroundColor(Color("AccentGreen"))
                Text("Power")
                    .font(.custom("Avenir-Medium", size: 11))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(Color("CardBackground"))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Branch Selector
    
    private var branchSelector: some View {
        HStack(spacing: 0) {
            ForEach(ResearchBranch.allCases, id: \.self) { branch in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedBranch = branch
                    }
                    AudioManager.shared.play(.tabSwitch)
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: branch.icon)
                            .font(.system(size: 16))
                        Text(branch.displayName)
                            .font(.custom("Avenir-Heavy", size: 12))
                            .lineLimit(1)
                    }
                    .foregroundColor(selectedBranch == branch ? Color(branch.color) : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        selectedBranch == branch ?
                        Color(branch.color).opacity(0.15) :
                        Color.clear
                    )
                }
            }
        }
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Branch Description Card
    
    private var branchDescriptionCard: some View {
        HStack(spacing: 12) {
            Image(systemName: selectedBranch.icon)
                .font(.title2)
                .foregroundColor(Color(selectedBranch.color))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(selectedBranch.displayName)
                    .font(.custom("Avenir-Heavy", size: 16))
                Text(selectedBranch.description)
                    .font(.custom("Avenir-Medium", size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Branch progress
            let branchNodes = ResearchTree.nodes(for: selectedBranch)
            let completed = branchNodes.filter { character.hasCompletedResearchNode($0.id) }.count
            Text("\(completed)/\(branchNodes.count)")
                .font(.custom("Avenir-Heavy", size: 14))
                .foregroundColor(Color(selectedBranch.color))
        }
        .padding(16)
        .background(Color("CardBackground"))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Node List Card
    
    private var nodeListCard: some View {
        VStack(spacing: 0) {
            let nodes = ResearchTree.nodes(for: selectedBranch)
            ForEach(Array(nodes.enumerated()), id: \.element.id) { index, node in
                ResearchNodeRow(
                    node: node,
                    character: character,
                    isLast: index == nodes.count - 1,
                    onTap: {
                        selectedNode = node
                        showNodeDetail = true
                        AudioManager.shared.play(.buttonTap)
                    }
                )
            }
        }
        .background(Color("CardBackground"))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Active Bonuses Card
    
    private var activeBonusesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(Color("AccentGreen"))
                Text("Active Research Bonuses")
                    .font(.custom("Avenir-Heavy", size: 16))
                Spacer()
            }
            
            let bonuses = character.researchBonuses
            
            if bonuses.dungeonSuccessBonus > 0 {
                bonusRow(icon: "flame.fill", label: "Dungeon Success", value: "+\(Int(bonuses.dungeonSuccessBonus * 100))%", color: "StatStrength")
            }
            if bonuses.bossDamageBonus > 0 {
                bonusRow(icon: "bolt.circle.fill", label: "Boss Damage", value: "+\(Int(bonuses.bossDamageBonus * 100))%", color: "StatStrength")
            }
            if bonuses.critChanceBonus > 0 {
                bonusRow(icon: "scope", label: "Crit Chance", value: "+\(Int(bonuses.critChanceBonus * 100))%", color: "StatStrength")
            }
            if bonuses.combatPowerBonus > 0 {
                bonusRow(icon: "shield.fill", label: "Combat Power", value: "+\(Int(bonuses.combatPowerBonus * 100))%", color: "StatStrength")
            }
            if bonuses.missionDurationReduction > 0 {
                bonusRow(icon: "clock.arrow.circlepath", label: "Mission Speed", value: "-\(Int(bonuses.missionDurationReduction * 100))%", color: "AccentGreen")
            }
            if bonuses.taskEXPBonus > 0 {
                bonusRow(icon: "star.fill", label: "Task EXP", value: "+\(Int(bonuses.taskEXPBonus * 100))%", color: "AccentGreen")
            }
            if bonuses.materialDropRateBonus > 0 {
                bonusRow(icon: "square.stack.3d.up.fill", label: "Material Drops", value: "+\(Int(bonuses.materialDropRateBonus * 100))%", color: "AccentGreen")
            }
            if bonuses.allEXPBonus > 0 {
                bonusRow(icon: "arrow.up.circle.fill", label: "All EXP", value: "+\(Int(bonuses.allEXPBonus * 100))%", color: "AccentGreen")
            }
            if bonuses.rareDropChanceBonus > 0 {
                bonusRow(icon: "sparkles", label: "Rare Drops", value: "+\(Int(bonuses.rareDropChanceBonus * 100))%", color: "AccentGold")
            }
            if bonuses.goldBonus > 0 {
                bonusRow(icon: "dollarsign.circle.fill", label: "Gold Bonus", value: "+\(Int(bonuses.goldBonus * 100))%", color: "AccentGold")
            }
            if bonuses.affixChanceBonus > 0 {
                bonusRow(icon: "wand.and.stars", label: "Affix Chance", value: "+\(Int(bonuses.affixChanceBonus * 100))%", color: "AccentGold")
            }
            if bonuses.allLootBonus > 0 {
                bonusRow(icon: "gift.fill", label: "All Loot", value: "+\(Int(bonuses.allLootBonus * 100))%", color: "AccentGold")
            }
        }
        .padding(16)
        .background(Color("CardBackground"))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    @ViewBuilder
    private func bonusRow(icon: String, label: String, value: String, color: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color(color))
                .frame(width: 20)
            Text(label)
                .font(.custom("Avenir-Medium", size: 13))
            Spacer()
            Text(value)
                .font(.custom("Avenir-Heavy", size: 13))
                .foregroundColor(Color(color))
        }
    }
    
    // MARK: - Completion Celebration Overlay
    
    private var researchCompletionOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showCompletionCelebration = false
                    }
                }
            
            VStack(spacing: 20) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color("AccentGold"))
                    .symbolEffect(.bounce, value: showCompletionCelebration)
                
                Text("Research Complete!")
                    .font(.custom("Avenir-Heavy", size: 24))
                
                Text(completedNodeName)
                    .font(.custom("Avenir-Medium", size: 16))
                    .foregroundColor(.secondary)
                
                Text("Bonus permanently applied")
                    .font(.custom("Avenir-Medium", size: 14))
                    .foregroundColor(Color("AccentGreen"))
                
                Button(action: {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showCompletionCelebration = false
                    }
                }) {
                    Text("Continue")
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color("AccentGold"), Color("AccentOrange")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
            }
            .padding(32)
            .background(Color("CardBackground"))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 32)
        }
        .transition(.opacity)
    }
    
    // MARK: - Helpers
    
    private var researchTokenCount: Int {
        materials.filter { $0.materialType == .researchToken && $0.characterID == character.id }
            .reduce(0) { $0 + $1.quantity }
    }
    
    private func formatTimeRemaining(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%dh %02dm %02ds", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%dm %02ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
    
    private func startResearch(node: ResearchNode) {
        // Deduct costs
        character.gold -= node.goldCost
        
        // Deduct Research Tokens
        deductResearchTokens(count: node.researchTokenCost)
        
        // Deduct materials
        for cost in node.materialCosts {
            deductMaterial(type: cost.materialType, rarity: cost.rarity, quantity: cost.quantity)
        }
        
        // Start research
        character.startResearch(node: node)
        
        // Audio + Haptics
        AudioManager.shared.play(.researchStart)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        showNodeDetail = false
        
        // Sync
        SyncManager.shared.queueCharacterSync(character)
    }
    
    private func claimResearch() {
        guard let nodeID = character.activeResearchNodeID,
              let node = ResearchTree.node(withID: nodeID) else { return }
        
        completedNodeName = node.name
        character.completeResearch()
        
        // Audio + Haptics
        AudioManager.shared.play(.researchNodeUnlock)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Show celebration
        withAnimation(.easeIn(duration: 0.3)) {
            showCompletionCelebration = true
        }
        
        // Sync
        SyncManager.shared.queueCharacterSync(character)
    }
    
    private func checkResearchCompletion() {
        // Only used for UI updates — actual claiming is manual
    }
    
    private func deductResearchTokens(count: Int) {
        var remaining = count
        let tokens = materials.filter { $0.materialType == .researchToken && $0.characterID == character.id }
            .sorted { $0.quantity > $1.quantity }
        
        for token in tokens {
            guard remaining > 0 else { break }
            let deduct = min(token.quantity, remaining)
            token.quantity -= deduct
            remaining -= deduct
            if token.quantity <= 0 {
                modelContext.delete(token)
            }
        }
    }
    
    private func deductMaterial(type: String, rarity: String, quantity: Int) {
        var remaining = quantity
        let matchingMaterials = materials.filter {
            $0.materialType.rawValue == type &&
            $0.rarity.rawValue.lowercased() == rarity.lowercased() &&
            $0.characterID == character.id
        }.sorted { $0.quantity > $1.quantity }
        
        for mat in matchingMaterials {
            guard remaining > 0 else { break }
            let deduct = min(mat.quantity, remaining)
            mat.quantity -= deduct
            remaining -= deduct
            if mat.quantity <= 0 {
                modelContext.delete(mat)
            }
        }
    }
}

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
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Connection line + Node circle
                ZStack {
                    // Vertical connector line
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
                    
                    // Node circle
                    ZStack {
                        Circle()
                            .fill(nodeBackgroundColor)
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: nodeIcon)
                            .font(.system(size: 16))
                            .foregroundColor(nodeIconColor)
                    }
                }
                .frame(width: 40)
                
                // Node info
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
                
                // Status indicator
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
                        // Node Header
                        nodeHeader
                        
                        // Description
                        descriptionCard
                        
                        // Status
                        statusCard
                        
                        // Cost Breakdown
                        if !isCompleted && !isResearching {
                            costCard
                        }
                        
                        // Action Button
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
                    .frame(width: 80, height: 80)
                
                Image(systemName: node.branch.icon)
                    .font(.system(size: 32))
                    .foregroundColor(.white)
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
            
            // Gold
            costRow(
                icon: "dollarsign.circle.fill",
                label: "Gold",
                required: node.goldCost,
                available: character.gold,
                color: "AccentGold"
            )
            
            // Research Tokens
            costRow(
                icon: "book.closed.fill",
                label: "Research Tokens",
                required: node.researchTokenCost,
                available: researchTokenCount,
                color: "AccentPurple"
            )
            
            // Materials
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

// MARK: - Preview

#Preview {
    NavigationStack {
        ScrollView {
            ResearchTabContent(
                character: PlayerCharacter(name: "Test Hero")
            )
            .padding()
        }
        .background(
            LinearGradient(
                colors: [Color("BackgroundTop"), Color("BackgroundBottom")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    .environmentObject(GameEngine())
}
