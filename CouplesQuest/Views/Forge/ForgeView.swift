import SwiftUI
import SwiftData

// MARK: - Forge Station Tab

enum ForgeStation: String, CaseIterable {
    case craft = "Craft"
    case enhance = "Enhance"
    case salvage = "Salvage"
    case affix = "Affix"
    
    var icon: String {
        switch self {
        case .craft: return "hammer.fill"
        case .enhance: return "arrow.up.forward.circle.fill"
        case .salvage: return "scissors"
        case .affix: return "scroll.fill"
        }
    }
}

// MARK: - Main Forge View (Unified 4-Station)

struct ForgeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var gameEngine: GameEngine
    @Query private var characters: [PlayerCharacter]
    @Query private var materials: [CraftingMaterial]
    @Query private var allEquipment: [Equipment]
    @Query private var allConsumables: [Consumable]
    
    @State private var selectedStation: ForgeStation = .craft
    
    // Craft state
    @State private var selectedSlot: EquipmentSlot?
    @State private var selectedTier: Int?
    @State private var craftedItem: Equipment?
    @State private var showCraftResult = false
    @State private var isCrafting = false
    @State private var craftTrigger = 0
    
    // Enhance state
    @State private var selectedEnhanceItem: Equipment?
    @State private var showEnhanceConfirm = false
    @State private var useCatalyst = false
    @State private var enhanceResult: GameEngine.EnhancementResult?
    @State private var showEnhanceResult = false
    
    // Salvage state
    @State private var selectedSalvageItem: Equipment?
    @State private var showSalvageConfirm = false
    @State private var lastSalvageResult: GameEngine.SalvageResult?
    
    // Herb crafting state
    @State private var showHerbCraft = false
    @State private var craftedConsumable: Consumable?
    
    // Forgekeeper dialogue state
    @State private var forgekeeperMessage: String = ForgekeeperDialogue.random(from: ForgekeeperDialogue.welcomeGreetings)
    @State private var forgekeeperTip: String?
    
    // Animation
    @State private var forgeGlow = false
    
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
    
    private var herbCount: Int {
        ownedMaterials.filter { $0.materialType == .herb }.reduce(0) { $0 + $1.quantity }
    }
    
    private var canForge: Bool {
        guard let _ = selectedSlot,
              let tier = selectedTier,
              let recipe = ForgeRecipe.recipe(forTier: tier),
              let character = character else { return false }
        return gameEngine.canAffordRecipe(recipe, character: character, context: modelContext)
    }
    
    private var salvageableItems: [Equipment] {
        guard let character = character else { return [] }
        return allEquipment.filter { $0.ownerID == character.id && !$0.isEquipped }
    }
    
    private var enhanceableItems: [Equipment] {
        guard let character = character else { return [] }
        return allEquipment.filter { $0.ownerID == character.id && $0.enhancementLevel < Equipment.maxEnhancementLevel }
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color("BackgroundTop"), Color("BackgroundBottom")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Forgekeeper Banner
                ForgekeeperView(message: forgekeeperTip ?? forgekeeperMessage)
                    .padding(.top, 4)
                    .padding(.bottom, 4)
                    .animation(.easeInOut(duration: 0.3), value: forgekeeperMessage)
                    .animation(.easeInOut(duration: 0.3), value: forgekeeperTip)
                
                // Station Tabs (4 tabs)
                stationPicker
                
                // Currency Bar
                currencyBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                
                // Station Content
                ScrollView {
                    VStack(spacing: 20) {
                        switch selectedStation {
                        case .craft:
                            craftStationContent
                        case .enhance:
                            enhanceStationContent
                        case .salvage:
                            salvageStationContent
                        case .affix:
                            affixStationContent
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                    .padding(.top, 12)
                }
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
                    forgekeeperTip = nil
                    forgekeeperMessage = ForgekeeperDialogue.random(from: ForgekeeperDialogue.forgingSuccessLines, name: character?.name)
                }
            }
        }
        .alert("Salvage Item?", isPresented: $showSalvageConfirm) {
            Button("Cancel", role: .cancel) { selectedSalvageItem = nil }
            Button("Salvage", role: .destructive) {
                if let item = selectedSalvageItem {
                    performSalvage(item: item)
                }
            }
        } message: {
            if let item = selectedSalvageItem {
                let goldBack = GameEngine.defaultSalvageGold(rarity: item.rarity)
                let matsBack = GameEngine.defaultSalvageMaterials(rarity: item.rarity)
                Text("Salvage \(item.name) for ~\(goldBack)g + \(matsBack) materials? This cannot be undone.")
            }
        }
        .sensoryFeedback(.success, trigger: craftTrigger)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                forgeGlow = true
            }
            forgekeeperMessage = ForgekeeperDialogue.random(from: ForgekeeperDialogue.welcomeGreetings, name: character?.name)
            character?.completeBreadcrumb("visitForge")
            
            // Auto-convert shards to gold on first visit after update
            if let character = character, character.forgeShards > 0 {
                gameEngine.convertShardsToGold(character: character)
                forgekeeperTip = "I've converted your \(character.forgeShards) Forge Shards into gold! The forge has been upgraded."
            }
        }
    }
    
    // MARK: - Station Picker
    
    private var stationPicker: some View {
        HStack(spacing: 0) {
            ForEach(ForgeStation.allCases, id: \.self) { station in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedStation = station
                        forgekeeperTip = nil
                        updateForgekeeperForStation(station)
                    }
                    AudioManager.shared.play(.buttonTap)
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: station.icon)
                            .font(.system(size: 16))
                        Text(station.rawValue)
                            .font(.custom("Avenir-Heavy", size: 11))
                    }
                    .foregroundColor(selectedStation == station ? Color("ForgeEmber") : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        selectedStation == station
                            ? Color("ForgeEmber").opacity(0.12)
                            : Color.clear
                    )
                    .overlay(alignment: .bottom) {
                        if selectedStation == station {
                            Rectangle()
                                .fill(Color("ForgeEmber"))
                                .frame(height: 2)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color("CardBackground"))
    }
    
    // MARK: - Currency Bar
    
    private var currencyBar: some View {
        HStack(spacing: 0) {
            ForgeCurrencyPill(icon: "sparkle", label: "Essence", count: essenceCount, color: Color("AccentGold"), hasInfo: true) {
                forgekeeperTip = ForgekeeperDialogue.essenceExplanation
            }
            Spacer()
            ForgeCurrencyPill(icon: "cube.fill", label: "Materials", count: generalMaterialCount, color: Color("AccentPurple"), hasInfo: true) {
                forgekeeperTip = ForgekeeperDialogue.materialsExplanation
            }
            Spacer()
            ForgeCurrencyPill(icon: "square.stack.3d.up.fill", label: "Fragments", count: fragmentCount, color: Color("StatDexterity"), hasInfo: true) {
                forgekeeperTip = ForgekeeperDialogue.fragmentsExplanation
            }
            Spacer()
            ForgeCurrencyPill(icon: "laurel.leading", label: "Herbs", count: herbCount, color: Color("AccentGreen"))
            Spacer()
            ForgeCurrencyPill(icon: "dollarsign.circle.fill", label: "Gold", count: character?.gold ?? 0, color: Color("AccentGold"))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Craft Station
    
    private var craftStationContent: some View {
        VStack(spacing: 20) {
            // Equipment Crafting
            slotPickerSection
            
            if selectedSlot != nil {
                tierPickerSection
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
            
            if selectedSlot != nil && selectedTier != nil {
                forgeButton
                    .transition(.scale.combined(with: .opacity))
            }
            
            Divider().padding(.vertical, 4)
            
            // Herb Crafting Section
            herbCraftingSection
            
            // Material Inventory
            materialInventorySection
        }
    }
    
    // MARK: - Slot Picker
    
    private var slotPickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "hammer.fill")
                    .foregroundColor(Color("ForgeEmber"))
                    .font(.title3)
                Text("Equipment Crafting")
                    .font(.custom("Avenir-Heavy", size: 18))
            }
            
            HStack(spacing: 12) {
                ForEach(EquipmentSlot.allCases, id: \.self) { slot in
                    ForgeSlotCard(slot: slot, isSelected: selectedSlot == slot) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            selectedSlot = slot
                            selectedTier = nil
                            forgekeeperTip = nil
                            forgekeeperMessage = ForgekeeperDialogue.slotTip(for: slot.rawValue)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Tier Picker
    
    private var tierPickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose Forge Tier")
                .font(.custom("Avenir-Heavy", size: 16))
            
            Text("Higher tiers need rarer materials but produce stronger equipment.")
                .font(.custom("Avenir-Medium", size: 13))
                .foregroundColor(.secondary)
            
            ForEach(ForgeRecipe.activeRecipes(), id: \.tier) { recipe in
                let canAfford = character.map {
                    gameEngine.canAffordRecipe(recipe, character: $0, context: modelContext)
                } ?? false
                
                ForgeTierCard(
                    recipe: recipe,
                    isSelected: selectedTier == recipe.tier,
                    canAfford: canAfford,
                    essenceHave: essenceCount,
                    fragmentHave: fragmentCount,
                    materialHave: generalMaterialCount,
                    goldHave: character?.gold ?? 0
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedTier = recipe.tier
                        forgekeeperTip = nil
                        forgekeeperMessage = ForgekeeperDialogue.tierTip(for: recipe.tier)
                    }
                    if !canAfford {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            forgekeeperTip = ForgekeeperDialogue.random(from: ForgekeeperDialogue.cantAffordLines, name: character?.name)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Forge Button
    
    private var forgeButton: some View {
        VStack(spacing: 8) {
            Button(action: {
                guard let slot = selectedSlot,
                      let tier = selectedTier,
                      let recipe = ForgeRecipe.recipe(forTier: tier),
                      let character = character else { return }
                forgekeeperTip = nil
                forgekeeperMessage = ForgekeeperDialogue.random(from: ForgekeeperDialogue.readyToForgeLines, name: character.name)
                AudioManager.shared.play(.forgeHammer)
                craft(slot: slot, recipe: recipe, character: character)
            }) {
                ZStack {
                    if canForge {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color("ForgeEmber").opacity(0.2))
                            .blur(radius: 8)
                            .scaleEffect(forgeGlow ? 1.04 : 0.98)
                    }
                    
                    HStack(spacing: 12) {
                        if isCrafting {
                            ProgressView().tint(.black)
                        } else {
                            Image(systemName: "flame.fill").font(.title3)
                        }
                        Text(isCrafting ? "Forging..." : "Forge Equipment")
                            .font(.custom("Avenir-Heavy", size: 18))
                    }
                    .foregroundColor(canForge ? .black : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: canForge
                                ? [Color("ForgeEmber"), Color("AccentOrange")]
                                : [Color.secondary.opacity(0.2), Color.secondary.opacity(0.2)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(
                        color: canForge ? Color("ForgeEmber").opacity(0.4) : .clear,
                        radius: 12, x: 0, y: 6
                    )
                }
            }
            .disabled(!canForge || isCrafting)
        }
    }
    
    // MARK: - Herb Crafting Section
    
    private var herbCraftingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "laurel.leading")
                    .foregroundColor(Color("AccentGreen"))
                    .font(.title3)
                Text("Herb Crafting")
                    .font(.custom("Avenir-Heavy", size: 18))
                Spacer()
                Text("\(herbCount) Herbs")
                    .font(.custom("Avenir-Medium", size: 13))
                    .foregroundColor(Color("AccentGreen"))
            }
            
            Text("Craft consumables from herbs gathered on AFK missions.")
                .font(.custom("Avenir-Medium", size: 13))
                .foregroundColor(.secondary)
            
            ForEach(GameEngine.herbRecipes) { recipe in
                let canAfford = character.map {
                    gameEngine.canAffordHerbRecipe(recipe, character: $0, context: modelContext)
                } ?? false
                
                herbRecipeRow(recipe: recipe, canAfford: canAfford)
            }
        }
    }
    
    private func herbRecipeRow(recipe: GameEngine.HerbRecipe, canAfford: Bool) -> some View {
        Button {
            guard let character = character else { return }
            AudioManager.shared.play(.forgeMagicSwirl)
            if let consumable = gameEngine.craftConsumable(recipe: recipe, character: character, context: modelContext) {
                craftedConsumable = consumable
                craftTrigger += 1
                ToastManager.shared.showReward("Crafted: \(consumable.name)", subtitle: consumable.effectSummary, icon: recipe.icon)
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(recipe.consumableType.color).opacity(0.15))
                        .frame(width: 42, height: 42)
                    Image(systemName: recipe.icon)
                        .font(.system(size: 18))
                        .foregroundColor(Color(recipe.consumableType.color))
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(recipe.name)
                        .font(.custom("Avenir-Heavy", size: 14))
                        .foregroundColor(.primary)
                    Text(recipe.description)
                        .font(.custom("Avenir-Medium", size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 2) {
                        Image(systemName: "laurel.leading")
                            .font(.system(size: 9))
                            .foregroundColor(Color("AccentGreen"))
                        Text("\(recipe.herbCost)")
                            .font(.custom("Avenir-Heavy", size: 12))
                            .foregroundColor(canAfford ? Color("AccentGreen") : .red)
                    }
                    HStack(spacing: 2) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 9))
                            .foregroundColor(Color("AccentGold"))
                        Text("\(recipe.goldCost)")
                            .font(.custom("Avenir-Heavy", size: 12))
                            .foregroundColor((character?.gold ?? 0) >= recipe.goldCost ? Color("AccentGold") : .red)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color("CardBackground"))
            )
            .opacity(canAfford ? 1.0 : 0.6)
        }
        .buttonStyle(.plain)
        .disabled(!canAfford)
    }
    
    // MARK: - Enhance Station
    
    private var enhanceStationContent: some View {
        VStack(spacing: 16) {
            // Info card
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.forward.circle.fill")
                        .foregroundColor(Color("ForgeEmber"))
                    Text("Enhancement Station")
                        .font(.custom("Avenir-Heavy", size: 18))
                }
                
                Text("Boost your equipment's stats. Higher levels risk failure but grant bigger bonuses. 10% chance for a critical enhancement (double stats)!")
                    .font(.custom("Avenir-Medium", size: 13))
                    .foregroundColor(.secondary)
                
                // Enhancement tier legend
                HStack(spacing: 16) {
                    enhanceLegendPill(text: "+1–3: 100%", color: Color("AccentGreen"))
                    enhanceLegendPill(text: "+4–6: 80%", color: Color("AccentGold"))
                    enhanceLegendPill(text: "+7–8: 60%", color: Color("AccentOrange"))
                }
                HStack(spacing: 16) {
                    enhanceLegendPill(text: "+9: 40%", color: Color("DifficultyHard"))
                    enhanceLegendPill(text: "+10: 25%", color: Color("RarityLegendary"))
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color("CardBackground")))
            
            if enhanceableItems.isEmpty {
                emptyStateView(icon: "hammer.fill", title: "No items to enhance", subtitle: "Acquire equipment from dungeons, missions, or the forge to enhance it here.")
            } else {
                ForEach(enhanceableItems, id: \.id) { item in
                    enhanceItemRow(item: item)
                }
            }
        }
    }
    
    private func enhanceLegendPill(text: String, color: Color) -> some View {
        Text(text)
            .font(.custom("Avenir-Heavy", size: 10))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(color.opacity(0.12)))
    }
    
    private func enhanceItemRow(item: Equipment) -> some View {
        let cost = gameEngine.enhancementCost(for: item)
        let canAfford = (character?.gold ?? 0) >= cost
        let isMaxed = item.enhancementLevel >= Equipment.maxEnhancementLevel
        let successRate = gameEngine.enhancementSuccessRate(for: item)
        let hasCatalyst = character.map { gameEngine.hasForgeCatalyst(characterID: $0.id, context: modelContext) } ?? false
        
        return VStack(spacing: 0) {
            HStack(spacing: 14) {
                EquipmentIconView(item: item, slot: item.slot, size: 46)
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(item.name)
                            .font(.custom("Avenir-Heavy", size: 14))
                            .foregroundColor(Color(item.rarity.color))
                        if item.enhancementLevel > 0 {
                            Text("+\(item.enhancementLevel)")
                                .font(.custom("Avenir-Heavy", size: 11))
                                .foregroundColor(Color("AccentGreen"))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color("AccentGreen").opacity(0.2)))
                        }
                    }
                    Text(item.statSummary)
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                    
                    if !isMaxed {
                        HStack(spacing: 6) {
                            Text("Success: \(Int(successRate * 100))%")
                                .font(.custom("Avenir-Medium", size: 11))
                                .foregroundColor(successRate >= 0.8 ? Color("AccentGreen") : successRate >= 0.5 ? Color("AccentOrange") : .red)
                            Text("•")
                                .foregroundColor(.secondary)
                            Text("+\(gameEngine.enhancementStatGain(forLevel: item.enhancementLevel + 1)) stat")
                                .font(.custom("Avenir-Medium", size: 11))
                                .foregroundColor(Color("AccentGold"))
                        }
                    }
                }
                
                Spacer()
                
                if isMaxed {
                    Text("PERFECTED")
                        .font(.custom("Avenir-Heavy", size: 11))
                        .foregroundColor(Color("AccentGold"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color("AccentGold").opacity(0.15)))
                } else {
                    Button {
                        selectedEnhanceItem = item
                        useCatalyst = false
                        performEnhance(item: item, withCatalyst: false)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "dollarsign.circle.fill").font(.caption)
                            Text("\(cost)")
                                .font(.custom("Avenir-Heavy", size: 13))
                        }
                        .foregroundColor(canAfford ? Color("AccentGold") : .red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(Color("AccentGold").opacity(canAfford ? 0.15 : 0.05))
                        )
                    }
                    .disabled(!canAfford)
                }
            }
            
            // Catalyst button (if available and item is enhanceable)
            if !isMaxed && hasCatalyst {
                Button {
                    performEnhance(item: item, withCatalyst: true)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.trianglebadge.exclamationmark.fill")
                            .font(.system(size: 11))
                        Text("Use Forge Catalyst (2x success)")
                            .font(.custom("Avenir-Heavy", size: 11))
                    }
                    .foregroundColor(Color("ForgeEmber"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color("ForgeEmber").opacity(0.08))
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color("CardBackground")))
    }
    
    // MARK: - Salvage Station
    
    private var salvageStationContent: some View {
        VStack(spacing: 16) {
            // Info
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "scissors")
                        .foregroundColor(Color("ForgeEmber"))
                    Text("Salvage Station")
                        .font(.custom("Avenir-Heavy", size: 18))
                }
                Text("Break down unwanted equipment into crafting materials, fragments, and gold. Higher rarity items yield more resources. Items with affixes have a chance to recover an Affix Scroll!")
                    .font(.custom("Avenir-Medium", size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color("CardBackground")))
            
            // Auto-salvage toggles
            autoSalvageToggles
            
            if salvageableItems.isEmpty {
                emptyStateView(icon: "shippingbox", title: "No items to salvage", subtitle: "Unequipped items will appear here for salvaging.")
            } else {
                ForEach(salvageableItems, id: \.id) { item in
                    salvageItemRow(item: item)
                }
            }
        }
    }
    
    private var autoSalvageToggles: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Auto-Salvage Rules")
                .font(.custom("Avenir-Heavy", size: 14))
                .foregroundColor(.secondary)
            
            Toggle(isOn: Binding(
                get: { GameEngine.autoSalvageCommon },
                set: { GameEngine.autoSalvageCommon = $0 }
            )) {
                Text("Auto-salvage Common items")
                    .font(.custom("Avenir-Medium", size: 13))
            }
            .tint(Color("ForgeEmber"))
            
            Toggle(isOn: Binding(
                get: { GameEngine.autoSalvageBelowRare },
                set: { GameEngine.autoSalvageBelowRare = $0 }
            )) {
                Text("Auto-salvage below Rare")
                    .font(.custom("Avenir-Medium", size: 13))
            }
            .tint(Color("ForgeEmber"))
            
            Toggle(isOn: Binding(
                get: { GameEngine.neverAutoSalvageAffixed },
                set: { GameEngine.neverAutoSalvageAffixed = $0 }
            )) {
                Text("Never auto-salvage items with affixes")
                    .font(.custom("Avenir-Medium", size: 13))
            }
            .tint(Color("AccentGreen"))
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color("CardBackground")))
    }
    
    private func salvageItemRow(item: Equipment) -> some View {
        let goldBack = GameEngine.defaultSalvageGold(rarity: item.rarity)
        let matsBack = GameEngine.defaultSalvageMaterials(rarity: item.rarity)
        let fragsBack = GameEngine.defaultSalvageFragments(rarity: item.rarity)
        
        return HStack(spacing: 14) {
            EquipmentIconView(item: item, slot: item.slot, size: 46)
            
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
                selectedSalvageItem = item
                showSalvageConfirm = true
            } label: {
                VStack(spacing: 2) {
                    HStack(spacing: 3) {
                        if matsBack > 0 {
                            Image(systemName: "cube.fill").font(.system(size: 8)).foregroundColor(Color("AccentPurple"))
                            Text("\(matsBack)").font(.custom("Avenir-Heavy", size: 11)).foregroundColor(Color("AccentPurple"))
                        }
                        if fragsBack > 0 {
                            Image(systemName: "square.stack.3d.up.fill").font(.system(size: 8)).foregroundColor(Color("StatDexterity"))
                            Text("\(fragsBack)").font(.custom("Avenir-Heavy", size: 11)).foregroundColor(Color("StatDexterity"))
                        }
                    }
                    HStack(spacing: 3) {
                        Image(systemName: "dollarsign.circle.fill").font(.system(size: 8)).foregroundColor(Color("AccentGold"))
                        Text("\(goldBack)g").font(.custom("Avenir-Heavy", size: 11)).foregroundColor(Color("AccentGold"))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color("AccentOrange").opacity(0.12)))
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color("CardBackground")))
    }
    
    // MARK: - Affix Station
    
    private var affixStationContent: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "scroll.fill")
                        .foregroundColor(Color("AccentGold"))
                    Text("Affix Station")
                        .font(.custom("Avenir-Heavy", size: 18))
                }
                Text("Apply Affix Scrolls to add magical properties to your equipment, or spend gold to re-roll existing affixes. The endgame gold sink for perfectionists.")
                    .font(.custom("Avenir-Medium", size: 13))
                    .foregroundColor(.secondary)
                
                // Show affix scroll count
                let scrollCount = affixScrollCount
                HStack(spacing: 6) {
                    Image(systemName: "scroll.fill")
                        .font(.caption)
                        .foregroundColor(Color("AccentGold"))
                    Text("\(scrollCount) Affix Scroll\(scrollCount == 1 ? "" : "s") available")
                        .font(.custom("Avenir-Heavy", size: 13))
                        .foregroundColor(scrollCount > 0 ? Color("AccentGold") : .secondary)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color("AccentGold").opacity(0.08)))
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color("CardBackground")))
            
            // Coming soon message (Affix system depends on Agent 3's EquipmentAffix model)
            VStack(spacing: 12) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 40))
                    .foregroundColor(Color("AccentGold").opacity(0.5))
                Text("Affix application and re-rolling will activate once the affix system is fully online.")
                    .font(.custom("Avenir-Medium", size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Text("Collect Affix Scrolls from salvaging or expeditions in the meantime!")
                    .font(.custom("Avenir-Medium", size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color("CardBackground")))
            
            // Re-roll cost preview
            affixRerollCostPreview
        }
    }
    
    private var affixScrollCount: Int {
        guard let character = character else { return 0 }
        return allConsumables.filter {
            $0.characterID == character.id && $0.consumableType == .affixScroll && $0.remainingUses > 0
        }.count
    }
    
    private var affixRerollCostPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Re-roll Cost Curve")
                .font(.custom("Avenir-Heavy", size: 14))
            
            let costs = (1...5).map { n in
                (n, ContentManager.shared.affixRerollCost(forReroll: n))
            }
            
            HStack(spacing: 8) {
                ForEach(costs, id: \.0) { (num, cost) in
                    VStack(spacing: 2) {
                        Text("#\(num)")
                            .font(.custom("Avenir-Heavy", size: 11))
                            .foregroundColor(.secondary)
                        Text("\(cost)g")
                            .font(.custom("Avenir-Heavy", size: 12))
                            .foregroundColor(Color("AccentGold"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color("AccentGold").opacity(0.06)))
                }
            }
            
            Text("Cost escalates with each re-roll on the same item")
                .font(.custom("Avenir-Medium", size: 11))
                .foregroundColor(.secondary)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color("CardBackground")))
    }
    
    // MARK: - Material Inventory Section
    
    private var materialInventorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Materials")
                .font(.custom("Avenir-Heavy", size: 18))
            
            if ownedMaterials.isEmpty {
                emptyStateView(icon: "shippingbox", title: "No materials yet", subtitle: "Complete tasks, dungeons, and missions\nto start collecting materials.")
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(ownedMaterials.sorted(by: {
                        $0.materialType.rawValue < $1.materialType.rawValue
                    }), id: \.id) { mat in
                        ForgeMaterialCard(material: mat)
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private func emptyStateView(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundColor(.secondary)
            Text(title)
                .font(.custom("Avenir-Heavy", size: 15))
                .foregroundColor(.secondary)
            Text(subtitle)
                .font(.custom("Avenir-Medium", size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
    
    // MARK: - Actions
    
    private func craft(slot: EquipmentSlot, recipe: ForgeRecipe, character: PlayerCharacter) {
        isCrafting = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if let item = gameEngine.forgeEquipment(
                slot: slot,
                recipe: recipe,
                character: character,
                context: modelContext
            ) {
                craftedItem = item
                showCraftResult = true
                craftTrigger += 1
                AudioManager.shared.play(.forgeAnvilRing)
                let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                impactFeedback.impactOccurred()
                ToastManager.shared.showLoot("Forged: \(item.name)", rarity: item.rarity.rawValue)
            }
            isCrafting = false
        }
    }
    
    private func performSalvage(item: Equipment) {
        guard let character = character else { return }
        let result = gameEngine.salvageEquipment(item, character: character, context: modelContext)
        lastSalvageResult = result
        craftTrigger += 1
        selectedSalvageItem = nil
        
        AudioManager.shared.play(.forgeSalvage)
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        var subtitle = "+\(result.goldReturned)g"
        if result.materialsReturned > 0 { subtitle += " +\(result.materialsReturned) materials" }
        if result.fragmentsReturned > 0 { subtitle += " +\(result.fragmentsReturned) fragments" }
        if result.recoveredAffixScroll { subtitle += " +Affix Scroll!" }
        ToastManager.shared.showReward("Salvaged!", subtitle: subtitle, icon: "scissors")
    }
    
    private func performEnhance(item: Equipment, withCatalyst: Bool) {
        guard let character = character else { return }
        let result = gameEngine.enhanceEquipment(
            item,
            character: character,
            useCatalyst: withCatalyst,
            context: modelContext
        )
        enhanceResult = result
        craftTrigger += 1
        
        if result.success {
            if result.critical {
                AudioManager.shared.play(.forgeCritical)
                let feedback = UINotificationFeedbackGenerator()
                feedback.notificationOccurred(.success)
                ToastManager.shared.showLoot("CRITICAL! \(item.name) +\(result.newLevel) (+\(result.statGained) stats!)", rarity: item.rarity.rawValue)
                forgekeeperMessage = "By the flames! A critical enhancement! The stars aligned for that one!"
            } else {
                AudioManager.shared.play(.forgeEnhance)
                let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                impactFeedback.impactOccurred()
                ToastManager.shared.showLoot("Enhanced: \(item.name) +\(result.newLevel)", rarity: item.rarity.rawValue)
                forgekeeperMessage = "Enhancement successful! Your \(item.name) grows stronger."
            }
        } else {
            AudioManager.shared.play(.forgeEnhanceFail)
            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.error)
            ToastManager.shared.showReward("Enhancement Failed", subtitle: "-\(result.goldSpent) gold consumed", icon: "xmark.circle.fill")
            forgekeeperMessage = "The enhancement failed... the materials were consumed, but your item is unharmed. Try again!"
        }
    }
    
    private func updateForgekeeperForStation(_ station: ForgeStation) {
        switch station {
        case .craft:
            forgekeeperMessage = "Ready to forge something new? Pick a slot and tier!"
        case .enhance:
            forgekeeperMessage = "Enhancement is an art of patience. Higher levels carry risk, but the reward is immense."
        case .salvage:
            forgekeeperMessage = "Every item has value — even the ones you don't need. Salvage returns materials directly now!"
        case .affix:
            forgekeeperMessage = "Affixes are the mark of a true craftsman. Apply scrolls or re-roll for the perfect stats."
        }
    }
}

// MARK: - Step Badge

private struct ForgeStepBadge: View {
    let number: Int
    let label: String
    let isActive: Bool
    let isComplete: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(
                        isComplete
                            ? Color("ForgeEmber")
                            : isActive
                                ? Color("ForgeEmber").opacity(0.25)
                                : Color.secondary.opacity(0.15)
                    )
                    .frame(width: 32, height: 32)
                
                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                } else {
                    Text("\(number)")
                        .font(.custom("Avenir-Heavy", size: 14))
                        .foregroundColor(isActive ? Color("ForgeEmber") : .secondary)
                }
            }
            
            Text(label)
                .font(.custom("Avenir-Heavy", size: 11))
                .foregroundColor(isActive ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Currency Pill (with optional info tap)

private struct ForgeCurrencyPill: View {
    let icon: String
    let label: String
    let count: Int
    let color: Color
    var hasInfo: Bool = false
    var onInfoTap: (() -> Void)? = nil
    
    var body: some View {
        Button {
            onInfoTap?()
        } label: {
            VStack(spacing: 4) {
                HStack(spacing: 2) {
                    Image(systemName: icon)
                        .font(.system(size: 13))
                        .foregroundColor(color)
                    if hasInfo {
                        Image(systemName: "info.circle")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                }
                Text("\(count)")
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(.primary)
                Text(label)
                    .font(.custom("Avenir-Medium", size: 9))
                    .foregroundColor(.secondary)
            }
            .frame(minWidth: 50)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Slot Card

private struct ForgeSlotCard: View {
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
                    if isSelected {
                        Circle()
                            .stroke(Color("ForgeEmber").opacity(0.4), lineWidth: 2)
                            .frame(width: 56, height: 56)
                    }
                    Image(systemName: slot.icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? Color("ForgeEmber") : .secondary)
                        .scaleEffect(isSelected ? 1.1 : 1.0)
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
                    .shadow(color: isSelected ? Color("ForgeEmber").opacity(0.2) : .clear, radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Forge Tier Card

private struct ForgeTierCard: View {
    let recipe: ForgeRecipe
    let isSelected: Bool
    let canAfford: Bool
    let essenceHave: Int
    let fragmentHave: Int
    let materialHave: Int
    let goldHave: Int
    let onTap: () -> Void
    
    private var tierName: String {
        switch recipe.tier {
        case 1: return "Apprentice Forge"
        case 2: return "Journeyman Forge"
        case 3: return "Artisan Forge"
        case 4: return "Master Forge"
        default: return "Tier \(recipe.tier)"
        }
    }
    
    private var tierDescription: String {
        switch recipe.tier {
        case 1: return "Basic crafting for starter gear"
        case 2: return "Solid equipment for adventurers"
        case 3: return "Premium gear with guaranteed affixes"
        case 4: return "Legendary-potential masterworks"
        default: return ""
        }
    }
    
    private var tierIcon: String {
        switch recipe.tier {
        case 1: return "flame"
        case 2: return "flame.fill"
        case 3: return "bolt.fill"
        case 4: return "crown.fill"
        default: return "hammer.fill"
        }
    }
    
    private var rarityColors: [Color] {
        switch recipe.tier {
        case 1: return [Color("RarityCommon"), Color("RarityUncommon")]
        case 2: return [Color("RarityUncommon"), Color("RarityRare")]
        case 3: return [Color("RarityRare"), Color("RarityEpic")]
        case 4: return [Color("RarityEpic"), Color("RarityLegendary")]
        default: return [Color("RarityCommon")]
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: tierIcon)
                                .font(.system(size: 14))
                                .foregroundStyle(
                                    LinearGradient(colors: rarityColors, startPoint: .top, endPoint: .bottom)
                                )
                            Text(tierName)
                                .font(.custom("Avenir-Heavy", size: 16))
                                .foregroundColor(.primary)
                        }
                        Text(tierDescription)
                            .font(.custom("Avenir-Medium", size: 12))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(recipe.resultRarityRange)
                        .font(.custom("Avenir-Heavy", size: 11))
                        .foregroundStyle(
                            LinearGradient(colors: rarityColors, startPoint: .leading, endPoint: .trailing)
                        )
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(rarityColors.first!.opacity(0.12))
                                .overlay(Capsule().stroke(rarityColors.first!.opacity(0.25), lineWidth: 1))
                        )
                }
                
                HStack(spacing: 10) {
                    ForgeCostIndicator(icon: "sparkle", label: "Essence", need: recipe.essenceCost, have: essenceHave, color: Color("AccentGold"))
                    if recipe.materialCost > 0 {
                        ForgeCostIndicator(icon: "cube.fill", label: "Materials", need: recipe.materialCost, have: materialHave, color: Color("AccentPurple"))
                    }
                    if recipe.fragmentCost > 0 {
                        ForgeCostIndicator(icon: "square.stack.3d.up.fill", label: "Fragments", need: recipe.fragmentCost, have: fragmentHave, color: Color("StatDexterity"))
                    }
                    if recipe.goldCost > 0 {
                        ForgeCostIndicator(icon: "dollarsign.circle.fill", label: "Gold", need: recipe.goldCost, have: goldHave, color: Color("AccentGold"))
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("CardBackground"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color("ForgeEmber") : .clear, lineWidth: 2)
                    )
                    .shadow(color: isSelected ? Color("ForgeEmber").opacity(0.15) : .clear, radius: 8, x: 0, y: 4)
            )
            .opacity(canAfford ? 1.0 : 0.65)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Cost Indicator (Have / Need)

private struct ForgeCostIndicator: View {
    let icon: String
    let label: String
    let need: Int
    let have: Int
    let color: Color
    
    private var sufficient: Bool { have >= need }
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(color)
            HStack(spacing: 0) {
                Text("\(min(have, need))")
                    .font(.custom("Avenir-Heavy", size: 12))
                    .foregroundColor(sufficient ? Color("AccentGreen") : .red)
                Text("/\(need)")
                    .font(.custom("Avenir-Heavy", size: 12))
                    .foregroundColor(.secondary)
            }
            Text(label)
                .font(.custom("Avenir-Medium", size: 8))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(sufficient ? color.opacity(0.08) : Color.red.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(sufficient ? color.opacity(0.2) : Color.red.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Forge Material Card

private struct ForgeMaterialCard: View {
    let material: CraftingMaterial
    
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(material.materialType.color).opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: material.icon)
                    .font(.system(size: 15))
                    .foregroundColor(Color(material.materialType.color))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(material.displayName)
                    .font(.custom("Avenir-Heavy", size: 12))
                    .lineLimit(1)
                Text(material.materialType.sourceDescription)
                    .font(.custom("Avenir-Medium", size: 9))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text("×\(material.quantity)")
                .font(.custom("Avenir-Heavy", size: 15))
                .foregroundColor(Color(material.materialType.color))
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("CardBackground"))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(material.materialType.color).opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Craft Result View

struct CraftResultView: View {
    let item: Equipment
    let onDismiss: () -> Void
    
    @State private var showItem = false
    @State private var showDetails = false
    @State private var glowPulse = false
    @State private var ringScale: CGFloat = 0.3
    @State private var sparkleRotation: Double = 0
    
    private var rarityColor: Color {
        Color(item.rarity.color)
    }
    
    var body: some View {
        ZStack {
            Color("BackgroundTop").ignoresSafeArea()
            
            RadialGradient(
                colors: [rarityColor.opacity(0.15), Color.clear],
                center: .center,
                startRadius: 10,
                endRadius: 300
            )
            .ignoresSafeArea()
            .opacity(showItem ? 1 : 0)
            
            VStack(spacing: 0) {
                Spacer()
                
                Text("Item Forged!")
                    .font(.custom("Avenir-Heavy", size: 28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("ForgeEmber"), Color("AccentOrange")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(showItem ? 1 : 0)
                    .offset(y: showItem ? 0 : 20)
                    .padding(.bottom, 24)
                
                ZStack {
                    Circle()
                        .stroke(rarityColor.opacity(0.1), lineWidth: 1)
                        .frame(width: 160, height: 160)
                        .scaleEffect(ringScale)
                    Circle()
                        .fill(rarityColor.opacity(glowPulse ? 0.12 : 0.06))
                        .frame(width: 130, height: 130)
                        .scaleEffect(showItem ? 1.0 : 0.5)
                    Circle()
                        .fill(rarityColor.opacity(0.18))
                        .frame(width: 100, height: 100)
                        .scaleEffect(showItem ? 1.0 : 0.3)
                    EquipmentIconView(item: item, slot: item.slot, size: 80)
                        .scaleEffect(showItem ? 1.0 : 0.2)
                    ForEach(0..<4, id: \.self) { i in
                        Image(systemName: "sparkle")
                            .font(.system(size: 12))
                            .foregroundColor(rarityColor.opacity(0.6))
                            .offset(
                                x: cos(Double(i) * .pi / 2 + sparkleRotation) * 72,
                                y: sin(Double(i) * .pi / 2 + sparkleRotation) * 72
                            )
                            .opacity(showItem ? 1 : 0)
                    }
                }
                .animation(.spring(response: 0.7, dampingFraction: 0.65), value: showItem)
                .padding(.bottom, 28)
                
                VStack(spacing: 10) {
                    Text(item.name)
                        .font(.custom("Avenir-Heavy", size: 24))
                        .foregroundColor(rarityColor)
                    
                    Text(item.rarity.rawValue)
                        .font(.custom("Avenir-Heavy", size: 13))
                        .foregroundColor(rarityColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(rarityColor.opacity(0.15))
                                .overlay(Capsule().stroke(rarityColor.opacity(0.3), lineWidth: 1))
                        )
                        .rarityShimmer(item.rarity)
                    
                    HStack(spacing: 4) {
                        Image(systemName: item.primaryStat.icon)
                            .font(.caption)
                            .foregroundColor(Color(item.primaryStat.color))
                        Text(item.statSummary)
                            .font(.custom("Avenir-Medium", size: 16))
                            .foregroundColor(Color("AccentGreen"))
                    }
                    .padding(.top, 4)
                    
                    HStack(spacing: 16) {
                        Label(item.slot.rawValue, systemImage: item.slot.icon)
                            .font(.custom("Avenir-Medium", size: 13))
                            .foregroundColor(.secondary)
                        Text("Lv. \(item.levelRequirement)")
                            .font(.custom("Avenir-Medium", size: 13))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 2)
                }
                .opacity(showDetails ? 1 : 0)
                .offset(y: showDetails ? 0 : 15)
                
                if !item.itemDescription.isEmpty {
                    Text(item.itemDescription)
                        .font(.custom("Avenir-Medium", size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 12)
                        .opacity(showDetails ? 1 : 0)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Text("Collect")
                        .font(.custom("Avenir-Heavy", size: 18))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [Color("ForgeEmber"), Color("AccentOrange")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color("ForgeEmber").opacity(0.3), radius: 10, x: 0, y: 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
                .opacity(showDetails ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                showItem = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.5)) {
                ringScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
                showDetails = true
            }
            withAnimation(.easeInOut(duration: 2.0).delay(0.8).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                sparkleRotation = .pi * 2
            }
        }
    }
}

// MARK: - RGB Shimmer Text (Legendary Effect)

private struct RGBShimmerText: View {
    let text: String
    let font: Font
    @State private var phase: CGFloat = 0
    
    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        .red, .orange, .yellow, .green,
                        .cyan, .blue, .purple, .pink, .red
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .hueRotation(.degrees(phase))
            .shadow(color: .purple.opacity(0.3), radius: 4, x: 0, y: 0)
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    phase = 360
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
