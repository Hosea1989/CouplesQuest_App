import SwiftUI
import SwiftData

struct ForgeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var gameEngine: GameEngine
    @Query private var characters: [PlayerCharacter]
    @Query private var allEquipment: [Equipment]
    
    @State private var selectedTab: ForgeTab = .salvage
    @State private var selectedItem: Equipment?
    @State private var showSalvageConfirm = false
    @State private var showCraftConfirm = false
    @State private var selectedCraftRarity: ItemRarity?
    @State private var lastSalvageShards: Int?
    @State private var lastCraftedItem: Equipment?
    @State private var showCraftResult = false
    @State private var forgeTrigger = 0
    
    enum ForgeTab: String, CaseIterable {
        case salvage = "Salvage"
        case craft = "Craft"
    }
    
    private var character: PlayerCharacter? {
        characters.first
    }
    
    private var salvageableItems: [Equipment] {
        guard let character = character else { return [] }
        return allEquipment.filter { $0.ownerID == character.id && !$0.isEquipped }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color("BackgroundTop"), Color("BackgroundBottom")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if let character = character, character.level >= 10 {
                VStack(spacing: 0) {
                    // Shard Balance
                    shardBalanceBar(character: character)
                    
                    // Tab Picker
                    Picker("Forge Tab", selection: $selectedTab) {
                        ForEach(ForgeTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    // Content
                    ScrollView {
                        switch selectedTab {
                        case .salvage:
                            salvageContent(character: character)
                        case .craft:
                            craftContent(character: character)
                        }
                    }
                }
            } else {
                lockedView
            }
        }
        .navigationTitle("Forge")
        .navigationBarTitleDisplayMode(.large)
        .alert("Salvage Item?", isPresented: $showSalvageConfirm) {
            Button("Cancel", role: .cancel) { selectedItem = nil }
            Button("Salvage", role: .destructive) {
                if let item = selectedItem {
                    performSalvage(item: item)
                }
            }
        } message: {
            if let item = selectedItem {
                Text("Destroy \(item.name) for \(gameEngine.shardsForRarity(item.rarity)) Forge Shards? This cannot be undone.")
            }
        }
        .alert("Craft Equipment?", isPresented: $showCraftConfirm) {
            Button("Cancel", role: .cancel) { selectedCraftRarity = nil }
            Button("Craft") {
                if let rarity = selectedCraftRarity {
                    performCraft(rarity: rarity)
                }
            }
        } message: {
            if let rarity = selectedCraftRarity {
                Text("Spend \(gameEngine.shardCostForRarity(rarity)) Forge Shards to craft a random \(rarity.rawValue) item?")
            }
        }
        .overlay {
            if showCraftResult, let item = lastCraftedItem {
                craftResultOverlay(item: item)
            }
        }
        .sensoryFeedback(.success, trigger: forgeTrigger)
    }
    
    // MARK: - Shard Balance
    
    @ViewBuilder
    private func shardBalanceBar(character: PlayerCharacter) -> some View {
        HStack {
            Image(systemName: "diamond.fill")
                .foregroundColor(Color("AccentPurple"))
            Text("Forge Shards")
                .font(.custom("Avenir-Heavy", size: 14))
            Spacer()
            Text("\(character.forgeShards)")
                .font(.custom("Avenir-Heavy", size: 20))
                .foregroundColor(Color("AccentPurple"))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color("CardBackground"))
    }
    
    // MARK: - Salvage Content
    
    @ViewBuilder
    private func salvageContent(character: PlayerCharacter) -> some View {
        VStack(spacing: 16) {
            if salvageableItems.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No items to salvage")
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.secondary)
                    Text("Unequipped items will appear here for salvaging.")
                        .font(.custom("Avenir-Medium", size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
            } else {
                ForEach(salvageableItems, id: \.id) { item in
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(item.rarity.color).opacity(0.2))
                                .frame(width: 46, height: 46)
                            Image(systemName: item.slot.icon)
                                .foregroundColor(Color(item.rarity.color))
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.name)
                                .font(.custom("Avenir-Heavy", size: 14))
                                .foregroundColor(Color(item.rarity.color))
                            Text(item.statSummary)
                                .font(.custom("Avenir-Medium", size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button {
                            selectedItem = item
                            showSalvageConfirm = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "diamond.fill")
                                    .font(.caption)
                                Text("+\(gameEngine.shardsForRarity(item.rarity))")
                                    .font(.custom("Avenir-Heavy", size: 13))
                            }
                            .foregroundColor(Color("AccentPurple"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().fill(Color("AccentPurple").opacity(0.15))
                            )
                        }
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color("CardBackground")))
                }
            }
        }
        .padding()
    }
    
    // MARK: - Craft Content
    
    @ViewBuilder
    private func craftContent(character: PlayerCharacter) -> some View {
        VStack(spacing: 16) {
            Text("Choose a rarity to craft")
                .font(.custom("Avenir-Heavy", size: 18))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            let craftableRarities: [ItemRarity] = [.common, .uncommon, .rare, .epic]
            
            ForEach(craftableRarities, id: \.self) { rarity in
                let cost = gameEngine.shardCostForRarity(rarity)
                let canAfford = character.forgeShards >= cost
                
                Button {
                    selectedCraftRarity = rarity
                    showCraftConfirm = true
                } label: {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(rarity.color).opacity(0.2))
                                .frame(width: 50, height: 50)
                            Image(systemName: "wand.and.stars")
                                .font(.title3)
                                .foregroundColor(Color(rarity.color))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(rarity.rawValue)
                                .font(.custom("Avenir-Heavy", size: 16))
                                .foregroundColor(Color(rarity.color))
                            Text("Random \(rarity.rawValue) equipment")
                                .font(.custom("Avenir-Medium", size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "diamond.fill")
                                .font(.caption)
                            Text("\(cost)")
                                .font(.custom("Avenir-Heavy", size: 16))
                        }
                        .foregroundColor(canAfford ? Color("AccentPurple") : .red)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color("CardBackground"))
                    )
                    .opacity(canAfford ? 1.0 : 0.6)
                }
                .buttonStyle(.plain)
                .disabled(!canAfford)
            }
            
            // Legendary note
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundColor(.secondary)
                Text("Legendary items cannot be crafted — they can only be found as rare drops.")
                    .font(.custom("Avenir-Medium", size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color("CardBackground").opacity(0.5)))
        }
        .padding()
    }
    
    // MARK: - Locked View
    
    private var lockedView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "lock.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)
            }
            
            Text("Forge Locked")
                .font(.custom("Avenir-Heavy", size: 24))
            
            Text("Reach Level 10 to unlock the Forge.\nSalvage items for shards, then craft new gear!")
                .font(.custom("Avenir-Medium", size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // MARK: - Craft Result Overlay
    
    @ViewBuilder
    private func craftResultOverlay(item: Equipment) -> some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation { showCraftResult = false }
                }
            
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color(item.rarity.color).opacity(0.2))
                        .frame(width: 80, height: 80)
                    Image(systemName: item.slot.icon)
                        .font(.system(size: 36))
                        .foregroundColor(Color(item.rarity.color))
                }
                
                Text("Item Crafted!")
                    .font(.custom("Avenir-Heavy", size: 24))
                
                Text(item.name)
                    .font(.custom("Avenir-Heavy", size: 18))
                    .foregroundColor(Color(item.rarity.color))
                
                Text(item.rarity.rawValue)
                    .font(.custom("Avenir-Heavy", size: 12))
                    .foregroundColor(Color(item.rarity.color))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color(item.rarity.color).opacity(0.2)))
                
                Text(item.statSummary)
                    .font(.custom("Avenir-Medium", size: 14))
                    .foregroundColor(Color("AccentGreen"))
                
                Button {
                    withAnimation { showCraftResult = false }
                } label: {
                    Text("Awesome!")
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.black)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(colors: [Color("AccentGold"), Color("AccentOrange")], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color("BackgroundTop"))
            )
            .padding(40)
        }
        .transition(.opacity)
    }
    
    // MARK: - Actions
    
    private func performSalvage(item: Equipment) {
        guard let character = character else { return }
        let shards = gameEngine.salvageEquipment(item, character: character, context: modelContext)
        lastSalvageShards = shards
        forgeTrigger += 1
        selectedItem = nil
    }
    
    private func performCraft(rarity: ItemRarity) {
        guard let character = character else { return }
        if let item = gameEngine.craftEquipment(rarity: rarity, character: character, context: modelContext) {
            lastCraftedItem = item
            forgeTrigger += 1
            withAnimation {
                showCraftResult = true
            }
        }
        selectedCraftRarity = nil
    }
}

#Preview {
    NavigationStack {
        ForgeView()
            .environmentObject(GameEngine())
    }
}
