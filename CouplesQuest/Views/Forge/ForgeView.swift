import SwiftUI
import SwiftData

struct ForgeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var gameEngine: GameEngine
    @Query private var characters: [PlayerCharacter]
    @Query private var materials: [CraftingMaterial]
    
    @State private var selectedSlot: EquipmentSlot?
    @State private var selectedTier: Int?
    @State private var craftedItem: Equipment?
    @State private var showCraftResult = false
    @State private var isCrafting = false
    @State private var craftTrigger = 0
    
    private var character: PlayerCharacter? {
        characters.first
    }
    
    private var ownedMaterials: [CraftingMaterial] {
        guard let character = character else { return [] }
        return materials.filter { $0.characterID == character.id && $0.quantity > 0 }
    }
    
    private var essenceCount: Int {
        ownedMaterials.filter { $0.materialType == .essence }.reduce(0) { $0 + $1.quantity }
    }
    
    private var fragmentCount: Int {
        ownedMaterials.filter { $0.materialType == .fragment }.reduce(0) { $0 + $1.quantity }
    }
    
    private var generalMaterialCount: Int {
        ownedMaterials.filter {
            $0.materialType == .ore || $0.materialType == .crystal || $0.materialType == .hide
        }.reduce(0) { $0 + $1.quantity }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color("BackgroundTop"), Color("BackgroundBottom")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Material Summary Bar
                    materialSummaryBar
                    
                    // Slot Picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Choose Equipment Type")
                            .font(.custom("Avenir-Heavy", size: 18))
                        
                        HStack(spacing: 12) {
                            ForEach(EquipmentSlot.allCases, id: \.self) { slot in
                                SlotPickerCard(
                                    slot: slot,
                                    isSelected: selectedSlot == slot
                                ) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedSlot = slot
                                        selectedTier = nil
                                    }
                                }
                            }
                        }
                    }
                    
                    // Tier Picker (after slot selected)
                    if selectedSlot != nil {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Choose Crafting Tier")
                                .font(.custom("Avenir-Heavy", size: 18))
                            
                            ForEach(ForgeRecipe.recipes, id: \.tier) { recipe in
                                TierRecipeCard(
                                    recipe: recipe,
                                    isSelected: selectedTier == recipe.tier,
                                    canAfford: character.map {
                                        gameEngine.canAffordRecipe(recipe, character: $0, context: modelContext)
                                    } ?? false,
                                    essenceCount: essenceCount,
                                    fragmentCount: fragmentCount,
                                    generalCount: generalMaterialCount,
                                    gold: character?.gold ?? 0
                                ) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedTier = recipe.tier
                                    }
                                }
                            }
                        }
                    }
                    
                    // Craft Button
                    if let slot = selectedSlot, let tier = selectedTier,
                       let recipe = ForgeRecipe.recipe(forTier: tier),
                       let character = character {
                        
                        let canCraft = gameEngine.canAffordRecipe(recipe, character: character, context: modelContext)
                        
                        Button(action: {
                            craft(slot: slot, recipe: recipe, character: character)
                        }) {
                            HStack(spacing: 10) {
                                if isCrafting {
                                    ProgressView()
                                        .tint(.black)
                                } else {
                                    Image(systemName: "hammer.fill")
                                }
                                Text(isCrafting ? "Forging..." : "Forge Equipment")
                                    .font(.custom("Avenir-Heavy", size: 18))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: canCraft ?
                                        [Color("ForgeEmber"), Color("AccentOrange")] :
                                        [Color.secondary.opacity(0.3), Color.secondary.opacity(0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(!canCraft || isCrafting)
                    }
                    
                    // Material Inventory
                    materialInventorySection
                }
                .padding()
            }
        }
        .navigationTitle("The Forge")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showCraftResult) {
            if let item = craftedItem {
                CraftResultView(item: item) {
                    showCraftResult = false
                    selectedSlot = nil
                    selectedTier = nil
                    craftedItem = nil
                }
            }
        }
        .sensoryFeedback(.success, trigger: craftTrigger)
    }
    
    // MARK: - Material Summary Bar
    
    private var materialSummaryBar: some View {
        HStack(spacing: 0) {
            MaterialPill(icon: "sparkle", label: "Essence", count: essenceCount, color: Color("AccentGold"))
            Spacer()
            MaterialPill(icon: "hammer.fill", label: "Materials", count: generalMaterialCount, color: Color("AccentPurple"))
            Spacer()
            MaterialPill(icon: "square.stack.3d.up.fill", label: "Fragments", count: fragmentCount, color: Color("StatDexterity"))
            Spacer()
            MaterialPill(icon: "dollarsign.circle.fill", label: "Gold", count: character?.gold ?? 0, color: Color("AccentGold"))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
    }
    
    // MARK: - Material Inventory Section
    
    private var materialInventorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Materials")
                .font(.custom("Avenir-Heavy", size: 18))
            
            if ownedMaterials.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "shippingbox")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary)
                        Text("No materials yet")
                            .font(.custom("Avenir-Heavy", size: 15))
                            .foregroundColor(.secondary)
                        Text("Complete tasks, dungeons, and missions to collect materials")
                            .font(.custom("Avenir-Medium", size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(ownedMaterials.sorted(by: { $0.materialType.rawValue < $1.materialType.rawValue }), id: \.id) { mat in
                        HStack(spacing: 10) {
                            Image(systemName: mat.icon)
                                .foregroundColor(Color(mat.materialType.color))
                                .frame(width: 28)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(mat.displayName)
                                    .font(.custom("Avenir-Heavy", size: 12))
                                    .lineLimit(1)
                                Text(mat.materialType.sourceDescription)
                                    .font(.custom("Avenir-Medium", size: 9))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            Text("x\(mat.quantity)")
                                .font(.custom("Avenir-Heavy", size: 14))
                                .foregroundColor(Color(mat.materialType.color))
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color("CardBackground"))
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Craft Action
    
    private func craft(slot: EquipmentSlot, recipe: ForgeRecipe, character: PlayerCharacter) {
        isCrafting = true
        
        // Brief delay for animation feel
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if let item = gameEngine.forgeEquipment(
                slot: slot,
                recipe: recipe,
                character: character,
                context: modelContext
            ) {
                craftedItem = item
                showCraftResult = true
                craftTrigger += 1
            }
            isCrafting = false
        }
    }
}

// MARK: - Supporting Views

struct MaterialPill: View {
    let icon: String
    let label: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            Text("\(count)")
                .font(.custom("Avenir-Heavy", size: 14))
            Text(label)
                .font(.custom("Avenir-Medium", size: 9))
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 60)
    }
}

struct SlotPickerCard: View {
    let slot: EquipmentSlot
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color("ForgeEmber").opacity(0.2) : Color.secondary.opacity(0.1))
                        .frame(width: 56, height: 56)
                    Image(systemName: slot.icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? Color("ForgeEmber") : .secondary)
                }
                Text(slot.rawValue)
                    .font(.custom("Avenir-Heavy", size: 13))
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color("CardBackground"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? Color("ForgeEmber") : .clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct TierRecipeCard: View {
    let recipe: ForgeRecipe
    let isSelected: Bool
    let canAfford: Bool
    let essenceCount: Int
    let fragmentCount: Int
    let generalCount: Int
    let gold: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Tier \(recipe.tier)")
                        .font(.custom("Avenir-Heavy", size: 16))
                    Spacer()
                    Text(recipe.resultRarityRange)
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                }
                
                // Cost breakdown
                HStack(spacing: 16) {
                    CostPill(
                        icon: "sparkle",
                        cost: recipe.essenceCost,
                        have: essenceCount,
                        color: Color("AccentGold")
                    )
                    
                    if recipe.materialCost > 0 {
                        CostPill(
                            icon: "hammer.fill",
                            cost: recipe.materialCost,
                            have: generalCount,
                            color: Color("AccentPurple")
                        )
                    }
                    
                    if recipe.fragmentCost > 0 {
                        CostPill(
                            icon: "square.stack.3d.up.fill",
                            cost: recipe.fragmentCost,
                            have: fragmentCount,
                            color: Color("StatDexterity")
                        )
                    }
                    
                    if recipe.goldCost > 0 {
                        CostPill(
                            icon: "dollarsign.circle.fill",
                            cost: recipe.goldCost,
                            have: gold,
                            color: Color("AccentGold")
                        )
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color("CardBackground"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? Color("ForgeEmber") : .clear, lineWidth: 2)
                    )
            )
            .opacity(canAfford ? 1.0 : 0.6)
        }
        .buttonStyle(.plain)
    }
}

struct CostPill: View {
    let icon: String
    let cost: Int
    let have: Int
    let color: Color
    
    private var sufficient: Bool { have >= cost }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            Text("\(cost)")
                .font(.custom("Avenir-Heavy", size: 12))
                .foregroundColor(sufficient ? .primary : .red)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(sufficient ? color.opacity(0.15) : Color.red.opacity(0.1))
        )
    }
}

// MARK: - Craft Result View

struct CraftResultView: View {
    let item: Equipment
    let onDismiss: () -> Void
    
    @State private var showItem = false
    
    var body: some View {
        ZStack {
            Color("BackgroundTop").ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                Text("Item Forged!")
                    .font(.custom("Avenir-Heavy", size: 28))
                    .foregroundColor(Color("ForgeEmber"))
                
                ZStack {
                    Circle()
                        .fill(Color(item.rarity.color).opacity(0.2))
                        .frame(width: 120, height: 120)
                        .scaleEffect(showItem ? 1.0 : 0.5)
                    
                    Image(systemName: item.slot.icon)
                        .font(.system(size: 50))
                        .foregroundColor(Color(item.rarity.color))
                        .scaleEffect(showItem ? 1.0 : 0.3)
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showItem)
                
                VStack(spacing: 8) {
                    Text(item.name)
                        .font(.custom("Avenir-Heavy", size: 22))
                        .foregroundColor(Color(item.rarity.color))
                    
                    Text(item.rarity.rawValue)
                        .font(.custom("Avenir-Heavy", size: 14))
                        .foregroundColor(Color(item.rarity.color))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color(item.rarity.color).opacity(0.2)))
                    
                    Text(item.statSummary)
                        .font(.custom("Avenir-Medium", size: 16))
                        .foregroundColor(Color("AccentGreen"))
                        .padding(.top, 4)
                    
                    Text("Lv. \(item.levelRequirement) required")
                        .font(.custom("Avenir-Medium", size: 13))
                        .foregroundColor(.secondary)
                }
                
                Text(item.itemDescription)
                    .font(.custom("Avenir-Medium", size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Text("Collect")
                        .font(.custom("Avenir-Heavy", size: 18))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color("ForgeEmber"), Color("AccentOrange")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showItem = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        ForgeView()
            .environmentObject(GameEngine())
    }
}
