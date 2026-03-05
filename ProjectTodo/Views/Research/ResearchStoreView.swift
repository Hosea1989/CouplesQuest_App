import SwiftUI
import SwiftData

// MARK: - Standalone Research Storefront

struct ResearchStoreView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var gameEngine: GameEngine
    @Query private var characters: [PlayerCharacter]
    @Query private var materials: [CraftingMaterial]
    
    @State private var selectedBranch: ResearchBranch = .combat
    @State private var selectedNode: ResearchNode? = nil
    @State private var researchTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var showCompletionCelebration = false
    @State private var completedNodeName: String = ""
    
    @State private var scholarMessage: String = ScholarDialogue.random(from: ScholarDialogue.welcomeGreetings)
    @State private var scholarTip: String?
    
    private var character: PlayerCharacter? { characters.first }
    
    private var researchTokenCount: Int {
        guard let character else { return 0 }
        return materials.filter { $0.materialType == .researchToken && $0.characterID == character.id }
            .reduce(0) { $0 + $1.quantity }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color("BackgroundTop"), Color("BackgroundBottom")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if let character {
                VStack(spacing: 0) {
                    ScholarView(message: scholarTip ?? scholarMessage)
                        .padding(.top, 4)
                        .padding(.bottom, 4)
                        .animation(.easeInOut(duration: 0.3), value: scholarMessage)
                        .animation(.easeInOut(duration: 0.3), value: scholarTip)
                    
                    currencyBar(character: character)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 16) {
                            if character.isResearchActive {
                                activeResearchCard(character: character)
                            }
                            
                            researchProgressCard(character: character)
                            branchSelector
                            branchDescriptionCard(character: character)
                            nodeListCard(character: character)
                            
                            if character.completedResearchCount > 0 {
                                activeBonusesCard(character: character)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)
                        .padding(.top, 12)
                    }
                }
                .overlay {
                    if showCompletionCelebration {
                        researchCompletionOverlay
                    }
                }
            } else {
                ContentUnavailableView(
                    "No Character",
                    systemImage: "person.fill.questionmark",
                    description: Text("Create a character from the Home tab to get started.")
                )
            }
        }
        .navigationTitle("Scholar's Study")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedNode) { node in
            if let character {
                ResearchNodeDetailSheet(
                    node: node,
                    character: character,
                    materials: materials,
                    onStartResearch: { startResearch(node: node, character: character) }
                )
            }
        }
        .onReceive(researchTimer) { _ in
            checkResearchCompletion()
        }
        .onAppear {
            scholarMessage = ScholarDialogue.random(from: ScholarDialogue.welcomeGreetings, name: character?.name)
        }
    }
    
    // MARK: - Currency Bar
    
    private func currencyBar(character: PlayerCharacter) -> some View {
        HStack(spacing: 0) {
            ResearchCurrencyPill(
                icon: "book.closed.fill",
                label: "Tomes",
                count: researchTokenCount,
                color: Color("AccentPurple"),
                hasInfo: true,
                pixelImage: "equip-tome"
            ) {
                scholarTip = ScholarDialogue.tomeExplanation
            }
            
            Spacer()
            
            ResearchCurrencyPill(
                icon: "dollarsign.circle.fill",
                label: "Gold",
                count: character.gold,
                color: Color("AccentGold"),
                hasInfo: true
            ) {
                scholarTip = ScholarDialogue.goldExplanation
            }
            
            Spacer()
            
            ResearchCurrencyPill(
                icon: "checkmark.seal.fill",
                label: "Nodes",
                count: character.completedResearchCount,
                color: Color("AccentGreen")
            )
            
            Spacer()
            
            ResearchCurrencyPill(
                icon: "bolt.fill",
                label: "Power",
                count: character.cachedResearchPowerBonus,
                color: Color("AccentOrange"),
                prefix: "+"
            )
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("CardBackground"))
        )
    }
    
    // MARK: - Active Research Card
    
    private func activeResearchCard(character: PlayerCharacter) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "hourglass")
                    .foregroundColor(Color("AccentPurple"))
                    .symbolEffect(.pulse, options: .repeating)
                Text("Active Research")
                    .font(.custom("Avenir-Heavy", size: 16))
                Spacer()
                
                if character.isResearchComplete {
                    Button(action: { claimResearch(character: character) }) {
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
    
    private func researchProgressCard(character: PlayerCharacter) -> some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("\(character.completedResearchCount)")
                    .font(.custom("Avenir-Heavy", size: 24))
                    .foregroundColor(Color("AccentGold"))
                Text("Nodes")
                    .font(.custom("Avenir-Medium", size: 11))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            
            Divider().frame(height: 40)
            
            VStack(spacing: 4) {
                Text("\(researchTokenCount)")
                    .font(.custom("Avenir-Heavy", size: 24))
                    .foregroundColor(Color("AccentPurple"))
                Text("Tomes")
                    .font(.custom("Avenir-Medium", size: 11))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            
            Divider().frame(height: 40)
            
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
                    scholarTip = nil
                    scholarMessage = ScholarDialogue.branchGreeting(for: branch, name: character?.name)
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
    
    private func branchDescriptionCard(character: PlayerCharacter) -> some View {
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
    
    private func nodeListCard(character: PlayerCharacter) -> some View {
        VStack(spacing: 0) {
            let nodes = ResearchTree.nodes(for: selectedBranch)
            ForEach(Array(nodes.enumerated()), id: \.element.id) { index, node in
                ResearchNodeRow(
                    node: node,
                    character: character,
                    isLast: index == nodes.count - 1,
                    onTap: {
                        selectedNode = node
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
    
    private func activeBonusesCard(character: PlayerCharacter) -> some View {
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
    
    private func startResearch(node: ResearchNode, character: PlayerCharacter) {
        character.gold -= node.goldCost
        deductResearchTokens(count: node.researchTokenCost, character: character)
        
        for cost in node.materialCosts {
            deductMaterial(type: cost.materialType, rarity: cost.rarity, quantity: cost.quantity, character: character)
        }
        
        character.startResearch(node: node)
        
        AudioManager.shared.play(.researchStart)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        selectedNode = nil
        scholarTip = nil
        scholarMessage = ScholarDialogue.random(from: ScholarDialogue.researchStartLines, name: character.name)
        
        SyncManager.shared.queueCharacterSync(character)
    }
    
    private func claimResearch(character: PlayerCharacter) {
        guard let nodeID = character.activeResearchNodeID,
              let node = ResearchTree.node(withID: nodeID) else { return }
        
        completedNodeName = node.name
        character.completeResearch()
        
        AudioManager.shared.play(.researchNodeUnlock)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        scholarTip = nil
        scholarMessage = ScholarDialogue.random(from: ScholarDialogue.researchCompleteLines, name: character.name)
        
        withAnimation(.easeIn(duration: 0.3)) {
            showCompletionCelebration = true
        }
        
        SyncManager.shared.queueCharacterSync(character)
    }
    
    private func checkResearchCompletion() {}
    
    private func deductResearchTokens(count: Int, character: PlayerCharacter) {
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
    
    private func deductMaterial(type: String, rarity: String, quantity: Int, character: PlayerCharacter) {
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

// MARK: - Research Currency Pill

struct ResearchCurrencyPill: View {
    let icon: String
    let label: String
    let count: Int
    let color: Color
    var hasInfo: Bool = false
    var prefix: String = ""
    var pixelImage: String? = nil
    var onInfoTap: (() -> Void)? = nil
    
    var body: some View {
        Button(action: { onInfoTap?() }) {
            VStack(spacing: 2) {
                HStack(spacing: 3) {
                    if let pixelImage, UIImage(named: pixelImage) != nil {
                        Image(pixelImage)
                            .interpolation(.none)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 10))
                            .foregroundColor(color)
                    }
                    Text("\(prefix)\(count)")
                        .font(.custom("Avenir-Heavy", size: 13))
                        .foregroundColor(color)
                        .monospacedDigit()
                    if hasInfo {
                        Image(systemName: "info.circle")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                }
                Text(label)
                    .font(.custom("Avenir-Medium", size: 9))
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
        .disabled(onInfoTap == nil)
    }
}

// MARK: - Tome Icon View

struct TomeIconView: View {
    let rarity: ItemRarity
    let size: CGFloat
    
    init(rarity: ItemRarity = .common, size: CGFloat = 46) {
        self.rarity = rarity
        self.size = size
    }
    
    private var resolvedImage: String? {
        let tinted = "equip-tome-\(rarity.rawValue.lowercased())"
        if UIImage(named: tinted) != nil { return tinted }
        if UIImage(named: "equip-tome") != nil { return "equip-tome" }
        return nil
    }
    
    var body: some View {
        if let imgName = resolvedImage {
            Image(imgName)
                .interpolation(.none)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size * 0.8, height: size * 0.8)
        } else {
            Image(systemName: "book.closed.fill")
                .font(.system(size: size * 0.45))
                .foregroundColor(Color("AccentPurple"))
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ResearchStoreView()
    }
    .environmentObject(GameEngine())
}
