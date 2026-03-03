import SwiftUI
import SwiftData

// MARK: - Shop Filter & Sort Types

enum ConsumableShopCategory: String, CaseIterable {
    case all = "All"
    case potions = "Potions"
    case boosts = "Boosts"
    case food = "Food"
    case dungeon = "Dungeon"
    case crafting = "Crafting"
    
    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .potions: return "cross.vial.fill"
        case .boosts: return "bolt.fill"
        case .food: return "fork.knife"
        case .dungeon: return "shield.lefthalf.filled"
        case .crafting: return "hammer.fill"
        }
    }
    
    var matchingTypes: [ConsumableType] {
        switch self {
        case .all: return ConsumableType.allCases
        case .potions: return [.hpPotion, .regenBuff]
        case .boosts: return [.expBoost, .goldBoost, .missionSpeedUp, .streakShield]
        case .food: return [.statFood]
        case .dungeon: return [.dungeonRevive, .lootReroll, .luckElixir]
        case .crafting: return [.materialMagnet, .affixScroll, .forgeCatalyst, .dutyScroll, .expeditionCompass, .partyBeacon]
        }
    }
}

enum ShopSortOption: String, CaseIterable {
    case `default` = "Default"
    case priceLow = "Price: Low → High"
    case priceHigh = "Price: High → Low"
    case level = "Level Required"
}

enum EquipmentSortOption: String, CaseIterable {
    case `default` = "Default"
    case priceLow = "Price: Low → High"
    case priceHigh = "Price: High → Low"
    case rarityHigh = "Rarity: Best First"
}

struct StoreView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var gameEngine: GameEngine
    @Query private var characters: [PlayerCharacter]
    
    @State private var selectedTab: StoreTab = .storefront
    @State private var dailyStock: [Equipment] = []
    @State private var selectedEquipment: Equipment?
    @State private var selectedConsumable: ConsumableTemplate?
    @State private var showBuyConfirm = false
    @State private var showConsumableBuyConfirm = false
    @State private var purchaseTrigger = 0
    @State private var purchasedEquipmentIDs: Set<UUID> = []
    @State private var shopkeeperMessage: String = ShopkeeperDialogue.random(from: ShopkeeperDialogue.welcomeGreetings)
    @State private var shopkeeperItemTip: String?
    
    // Filter & sort state
    @State private var consumableCategory: ConsumableShopCategory = .all
    @State private var consumableSort: ShopSortOption = .default
    @State private var equipmentSort: EquipmentSortOption = .default
    @State private var equipmentSlotFilter: EquipmentSlot? = nil
    
    // Storefront state
    @State private var dealItem: Equipment?
    @State private var purchasedDealID: UUID?
    @State private var purchasedMilestoneIDs: Set<String> = []
    @State private var purchasedSetPieceIDs: Set<String> = []
    @State private var purchasedBundleIDs: Set<String> = []
    
    enum StoreTab: String, CaseIterable {
        case storefront = "Storefront"
        case equipment = "Equipment"
        case consumables = "Consumables"
        case premium = "Premium"
    }
    
    private var character: PlayerCharacter? {
        characters.first
    }
    
    /// Number of regen buff consumables the player currently owns
    private var regenBuffOwnedCount: Int {
        guard let charID = character?.id else { return 0 }
        return GameEngine.regenBuffCount(for: charID, context: modelContext)
    }
    
    private var filteredSortedConsumables: [ConsumableTemplate] {
        let playerLevel = character?.level ?? 1
        var items = ConsumableCatalog.activeGoldItems
        
        if consumableCategory != .all {
            items = items.filter { consumableCategory.matchingTypes.contains($0.type) }
        }
        
        switch consumableSort {
        case .default, .priceLow:
            items.sort { ConsumableCatalog.storePrice(template: $0, playerLevel: playerLevel) < ConsumableCatalog.storePrice(template: $1, playerLevel: playerLevel) }
        case .priceHigh:
            items.sort { ConsumableCatalog.storePrice(template: $0, playerLevel: playerLevel) > ConsumableCatalog.storePrice(template: $1, playerLevel: playerLevel) }
        case .level:
            items.sort { $0.levelRequirement < $1.levelRequirement }
        }
        
        return items
    }
    
    private var sortedEquipment: [Equipment] {
        var items = dailyStock
        if let slotFilter = equipmentSlotFilter {
            items = items.filter { $0.slot == slotFilter }
        }
        switch equipmentSort {
        case .default, .priceLow:
            items.sort { ShopGenerator.priceForEquipment($0) < ShopGenerator.priceForEquipment($1) }
        case .priceHigh:
            items.sort { ShopGenerator.priceForEquipment($0) > ShopGenerator.priceForEquipment($1) }
        case .rarityHigh:
            items.sort { $0.rarity > $1.rarity }
        }
        return items
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color("BackgroundTop"), Color("BackgroundBottom")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Shopkeeper banner
                ShopkeeperView(message: shopkeeperItemTip ?? shopkeeperMessage)
                    .padding(.top, 4)
                    .padding(.bottom, 4)
                    .animation(.easeInOut(duration: 0.3), value: shopkeeperMessage)
                    .animation(.easeInOut(duration: 0.3), value: shopkeeperItemTip)
                
                // Currency display
                currencyBar
                
                // Tab picker
                Picker("Store Section", selection: $selectedTab) {
                    ForEach(StoreTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 12)
                
                // Content
                ScrollView {
                    VStack(spacing: 16) {
                        switch selectedTab {
                        case .storefront:
                            StorefrontSection(
                                character: character,
                                dealItem: dealItem,
                                onBuyDeal: { buyDealItem() },
                                onBuyMilestone: { item in buyMilestoneItem(item) },
                                onBuySetPiece: { piece in buySetPiece(piece) },
                                onBuyBundle: { bundle in buyBundle(bundle) },
                                purchasedDealID: purchasedDealID,
                                purchasedMilestoneIDs: purchasedMilestoneIDs,
                                purchasedSetPieceIDs: purchasedSetPieceIDs,
                                purchasedBundleIDs: purchasedBundleIDs
                            )
                        case .equipment:
                            equipmentSection
                        case .consumables:
                            consumablesSection
                        case .premium:
                            premiumSection
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Merchant's Shop")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            generateDailyStock()
            generateDailyDeal()
            shopkeeperMessage = ShopkeeperDialogue.random(from: ShopkeeperDialogue.welcomeGreetings, name: character?.name)
            character?.completeBreadcrumb("checkStore")
            AudioManager.shared.play(.storeEnter)
        }
        .onChange(of: selectedTab) { _, newTab in
            shopkeeperItemTip = nil
            shopkeeperMessage = ShopkeeperDialogue.greeting(for: newTab.rawValue, name: character?.name)
        }
        .sheet(isPresented: $showBuyConfirm) {
            if let item = selectedEquipment {
                EquipmentBuySheet(
                    item: item,
                    character: character,
                    price: ShopGenerator.priceForEquipment(item),
                    canAfford: (character?.gold ?? 0) >= ShopGenerator.priceForEquipment(item),
                    alreadyPurchased: purchasedEquipmentIDs.contains(item.id),
                    onBuy: {
                        buyEquipment(item)
                    },
                    onDismiss: {
                        showBuyConfirm = false
                        shopkeeperItemTip = nil
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showConsumableBuyConfirm) {
            if let template = selectedConsumable {
                ConsumableBuySheet(
                    template: template,
                    character: character,
                    onBuy: { quantity in
                        buyConsumable(template, quantity: quantity)
                    },
                    onDismiss: {
                        showConsumableBuyConfirm = false
                        shopkeeperItemTip = nil
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
        .sensoryFeedback(.success, trigger: purchaseTrigger)
    }
    
    // MARK: - Currency Bar
    
    private var currencyBar: some View {
        HStack(spacing: 24) {
            HStack(spacing: 6) {
                GoldCoinIcon(size: 20)
                Text("\(character?.gold ?? 0)")
                    .font(.custom("Avenir-Heavy", size: 18))
            }
            
            Button {
                shopkeeperItemTip = ShopkeeperDialogue.gemExplanation
            } label: {
                HStack(spacing: 6) {
                    GemCurrencyIcon(size: 22)
                    Text("\(character?.gems ?? 0)")
                        .font(.custom("Avenir-Heavy", size: 18))
                    Image(systemName: "info.circle")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption)
                Text("New stock: \(ShopGenerator.timeUntilRefresh)")
                    .font(.custom("Avenir-Medium", size: 11))
            }
            .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    // MARK: - Equipment Section
    
    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "shield.lefthalf.filled")
                    .foregroundColor(Color("StoreTeal"))
                Text("Daily Equipment")
                    .font(.custom("Avenir-Heavy", size: 18))
                Spacer()
                Menu {
                    ForEach(EquipmentSortOption.allCases, id: \.self) { option in
                        Button {
                            equipmentSort = option
                        } label: {
                            if equipmentSort == option {
                                Label(option.rawValue, systemImage: "checkmark")
                            } else {
                                Text(option.rawValue)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.caption)
                        Text("Sort")
                            .font(.custom("Avenir-Medium", size: 12))
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            // Slot filter pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ShopFilterPill(label: "All", icon: "square.grid.2x2", isSelected: equipmentSlotFilter == nil) {
                        equipmentSlotFilter = nil
                    }
                    ForEach(EquipmentSlot.allCases, id: \.self) { slot in
                        ShopFilterPill(label: slot.rawValue, icon: slot.icon, isSelected: equipmentSlotFilter == slot) {
                            equipmentSlotFilter = slot
                        }
                    }
                }
            }
            
            if dailyStock.isEmpty {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Loading stock...")
                        .font(.custom("Avenir-Medium", size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else if sortedEquipment.isEmpty {
                Text("No items match this filter.")
                    .font(.custom("Avenir-Medium", size: 14))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
            } else {
                ForEach(sortedEquipment, id: \.id) { item in
                    ShopEquipmentCard(
                        item: item,
                        price: ShopGenerator.priceForEquipment(item),
                        canAfford: (character?.gold ?? 0) >= ShopGenerator.priceForEquipment(item),
                        isPurchased: purchasedEquipmentIDs.contains(item.id)
                    ) {
                        selectedEquipment = item
                        showBuyConfirm = true
                    }
                }
            }
        }
    }
    
    // MARK: - Consumables Section
    
    private var consumablesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bag.fill")
                    .foregroundColor(Color("StoreTeal"))
                Text("Consumables")
                    .font(.custom("Avenir-Heavy", size: 18))
                Spacer()
                Menu {
                    ForEach(ShopSortOption.allCases, id: \.self) { option in
                        Button {
                            consumableSort = option
                        } label: {
                            if consumableSort == option {
                                Label(option.rawValue, systemImage: "checkmark")
                            } else {
                                Text(option.rawValue)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.caption)
                        Text("Sort")
                            .font(.custom("Avenir-Medium", size: 12))
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ConsumableShopCategory.allCases, id: \.self) { category in
                        ShopFilterPill(label: category.rawValue, icon: category.icon, isSelected: consumableCategory == category) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                consumableCategory = category
                            }
                        }
                    }
                }
            }
            
            // Daily Featured Deal
            if let (dealTemplate, discount) = ConsumableDropTable.dailyFeaturedConsumable(
                characterLevel: character?.level ?? 1
            ), consumableCategory == .all || consumableCategory.matchingTypes.contains(dealTemplate.type) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "sparkle")
                            .foregroundColor(Color("AccentGold"))
                        Text("Daily Deal")
                            .font(.custom("Avenir-Heavy", size: 15))
                            .foregroundColor(Color("AccentGold"))
                        Spacer()
                        Text("Refreshes: \(ShopGenerator.timeUntilRefresh)")
                            .font(.custom("Avenir-Medium", size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    let scaledBase = ConsumableCatalog.storePrice(template: dealTemplate, playerLevel: character?.level ?? 1)
                    let discountedCost = scaledBase - (scaledBase * discount / 100)
                    let canAfford = (character?.gold ?? 0) >= discountedCost
                    
                    ShopConsumableCard(
                        template: ConsumableTemplate(
                            name: "\(dealTemplate.name) (-\(discount)%)",
                            description: dealTemplate.description,
                            type: dealTemplate.type,
                            icon: dealTemplate.icon,
                            effectValue: dealTemplate.effectValue,
                            effectStat: dealTemplate.effectStat,
                            goldCost: discountedCost,
                            gemCost: 0,
                            levelRequirement: dealTemplate.levelRequirement
                        ),
                        canBuy: canAfford,
                        meetsLevel: true,
                        limitText: nil
                    ) {
                        shopkeeperItemTip = "A special deal, just for you today!"
                        selectedConsumable = ConsumableTemplate(
                            name: dealTemplate.name,
                            description: dealTemplate.description,
                            type: dealTemplate.type,
                            icon: dealTemplate.icon,
                            effectValue: dealTemplate.effectValue,
                            effectStat: dealTemplate.effectStat,
                            goldCost: discountedCost,
                            gemCost: 0,
                            levelRequirement: dealTemplate.levelRequirement
                        )
                        showConsumableBuyConfirm = true
                    }
                }
                .padding(.bottom, 4)
            }
            
            if filteredSortedConsumables.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("No items in this category")
                        .font(.custom("Avenir-Medium", size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ForEach(filteredSortedConsumables) { template in
                    let playerLevel = character?.level ?? 1
                    let scaledPrice = ConsumableCatalog.storePrice(template: template, playerLevel: playerLevel)
                    let meetsLevel = playerLevel >= template.levelRequirement
                    let canAffordGold = template.goldCost == 0 || (character?.gold ?? 0) >= scaledPrice
                    let regenAtCap = template.type == .regenBuff && regenBuffOwnedCount >= GameEngine.maxRegenBuffCount
                    let canBuy = meetsLevel && canAffordGold && !regenAtCap
                    
                    ShopConsumableCard(
                        template: template,
                        canBuy: canBuy,
                        meetsLevel: meetsLevel,
                        limitText: regenAtCap ? "\(regenBuffOwnedCount)/\(GameEngine.maxRegenBuffCount) Owned" : nil,
                        displayPrice: scaledPrice
                    ) {
                        shopkeeperItemTip = ShopkeeperDialogue.itemTip(for: template)
                        selectedConsumable = ConsumableTemplate(
                            name: template.name,
                            description: template.description,
                            type: template.type,
                            icon: template.icon,
                            effectValue: template.effectValue,
                            effectStat: template.effectStat,
                            goldCost: scaledPrice,
                            gemCost: template.gemCost,
                            levelRequirement: template.levelRequirement
                        )
                        showConsumableBuyConfirm = true
                    }
                }
            }
        }
    }
    
    // MARK: - Premium Section
    
    private var premiumSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                GemCurrencyIcon(size: 20)
                Text("Premium Items")
                    .font(.custom("Avenir-Heavy", size: 18))
                Spacer()
            }
            
            Text("Spend gems on rare and powerful items.")
                .font(.custom("Avenir-Medium", size: 13))
                .foregroundColor(.secondary)
            
            ForEach(ConsumableCatalog.activeGemItems.sorted { $0.gemCost < $1.gemCost }) { template in
                let meetsLevel = (character?.level ?? 1) >= template.levelRequirement
                let canAffordGems = template.gemCost == 0 || (character?.gems ?? 0) >= template.gemCost
                let regenAtCap = template.type == .regenBuff && regenBuffOwnedCount >= GameEngine.maxRegenBuffCount
                let canBuy = meetsLevel && canAffordGems && !regenAtCap
                
                ShopConsumableCard(
                    template: template,
                    canBuy: canBuy,
                    meetsLevel: meetsLevel,
                    limitText: regenAtCap ? "\(regenBuffOwnedCount)/\(GameEngine.maxRegenBuffCount) Owned" : nil
                ) {
                    shopkeeperItemTip = ShopkeeperDialogue.itemTip(for: template)
                    selectedConsumable = template
                    showConsumableBuyConfirm = true
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func generateDailyStock() {
        guard let character = character else { return }
        dailyStock = ShopGenerator.dailyEquipment(characterLevel: character.level)
    }
    
    private func buyEquipment(_ item: Equipment) {
        guard let character = character else { return }
        if gameEngine.buyEquipment(item, character: character, context: modelContext) {
            AudioManager.shared.play(.storePurchase)
            purchasedEquipmentIDs.insert(item.id)
            purchaseTrigger += 1
            showBuyConfirm = false
            shopkeeperItemTip = ShopkeeperDialogue.random(from: ShopkeeperDialogue.equipmentPurchaseReactions, name: character.name)
        }
    }
    
    private func buyConsumable(_ template: ConsumableTemplate, quantity: Int = 1) {
        guard let character = character else { return }
        var purchased = 0
        for _ in 0..<quantity {
            if gameEngine.buyConsumable(template, character: character, context: modelContext) {
                purchased += 1
            } else {
                break
            }
        }
        guard purchased > 0 else { return }
        AudioManager.shared.play(.storePurchase)
        purchaseTrigger += 1
        showConsumableBuyConfirm = false
        let totalCost = template.goldCost > 0 ? template.goldCost * purchased : template.gemCost * purchased
        let currency = template.goldCost > 0 ? "Gold" : "Gems"
        let subtitle = purchased > 1 ? "\(purchased)x — -\(totalCost) \(currency)" : "-\(totalCost) \(currency)"
        ToastManager.shared.showSuccess("Purchased: \(template.name)", subtitle: subtitle)
        let reactions = purchased > 1 ? ShopkeeperDialogue.bulkPurchaseReactions : ShopkeeperDialogue.consumablePurchaseReactions
        shopkeeperItemTip = ShopkeeperDialogue.random(from: reactions, name: character.name)
    }
    
    // MARK: - Storefront Actions
    
    private func generateDailyDeal() {
        guard let character = character else { return }
        dealItem = ShopGenerator.dailyDeal(characterLevel: character.level)
    }
    
    private func buyDealItem() {
        guard let character = character, let item = dealItem else { return }
        let price = ShopGenerator.dealPrice(for: item)
        guard character.gold >= price else { return }
        
        character.gold -= price
        let purchased = Equipment(
            name: item.name,
            description: item.itemDescription,
            slot: item.slot,
            rarity: item.rarity,
            primaryStat: item.primaryStat,
            statBonus: item.statBonus,
            levelRequirement: item.levelRequirement,
            secondaryStat: item.secondaryStat,
            secondaryStatBonus: item.secondaryStatBonus,
            ownerID: character.id,
            baseType: item.baseType
        )
        modelContext.insert(purchased)
        do {
            try modelContext.save()
        } catch {
            print("[Store] Deal purchase save failed: \(error). Rolling back gold.")
            character.gold += price
            modelContext.delete(purchased)
            return
        }
        Task { try? await SupabaseService.shared.syncEquipment(purchased) }
        AudioManager.shared.play(.storePurchase)
        purchasedDealID = item.id
        purchaseTrigger += 1
        shopkeeperItemTip = "Wise choice! That deal won't come around again."
        ToastManager.shared.showLoot("Purchased: \(item.name)", rarity: item.rarity.rawValue)
    }
    
    private func buyMilestoneItem(_ item: MilestoneItem) {
        guard let character = character else { return }
        if gameEngine.buyMilestoneGear(item, character: character, context: modelContext) {
            AudioManager.shared.play(.storePurchase)
            purchasedMilestoneIDs.insert(item.id)
            purchaseTrigger += 1
            shopkeeperItemTip = "A fine milestone piece! You've earned it, adventurer."
            ToastManager.shared.showLoot("Milestone Gear: \(item.name)", rarity: item.rarity.rawValue)
        }
    }
    
    private func buySetPiece(_ piece: GearSetPiece) {
        guard let character = character else { return }
        guard character.gold >= piece.goldCost else { return }
        
        character.gold -= piece.goldCost
        let purchased = piece.toEquipment(ownerID: character.id)
        modelContext.insert(purchased)
        do {
            try modelContext.save()
        } catch {
            print("[Store] Set piece save failed: \(error). Rolling back gold.")
            character.gold += piece.goldCost
            modelContext.delete(purchased)
            return
        }
        Task { try? await SupabaseService.shared.syncEquipment(purchased) }
        AudioManager.shared.play(.storePurchase)
        purchasedSetPieceIDs.insert(piece.id)
        purchaseTrigger += 1
        
        // Check if full set is now owned
        if let charClass = character.characterClass,
           let gearSet = GearSetCatalog.gearSet(for: charClass) {
            let allPieceIDs = Set(gearSet.pieces.map { $0.id })
            if allPieceIDs.isSubset(of: purchasedSetPieceIDs) {
                shopkeeperItemTip = "The full \(gearSet.name) set! That bonus is going to serve you well."
                ToastManager.shared.showLoot("Set Complete: \(gearSet.name)!", rarity: "Legendary")
            } else {
                shopkeeperItemTip = "One step closer to completing the set!"
                ToastManager.shared.showLoot("Set Piece: \(piece.name)", rarity: piece.rarity.rawValue)
            }
        }
    }
    
    private func buyBundle(_ bundle: BundleDeal) {
        guard let character = character else { return }
        if gameEngine.buyBundle(bundle, character: character, context: modelContext) {
            AudioManager.shared.play(.storePurchase)
            purchasedBundleIDs.insert(bundle.id)
            purchaseTrigger += 1
            shopkeeperItemTip = "Great bundle! You saved a nice chunk of gold on that one."
            ToastManager.shared.showReward("Bundle Purchased!", subtitle: bundle.name, icon: "gift.fill")
        }
    }
}

// MARK: - Shop Equipment Card

struct ShopEquipmentCard: View {
    let item: Equipment
    let price: Int
    let canAfford: Bool
    let isPurchased: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                EquipmentIconView(item: item, slot: item.slot, size: 50)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name)
                        .font(.custom("Avenir-Heavy", size: 14))
                        .foregroundColor(Color(item.rarity.color))
                    Text(item.statSummary)
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                    HStack(spacing: 6) {
                        Text(item.rarity.rawValue)
                            .font(.custom("Avenir-Heavy", size: 10))
                            .foregroundColor(Color(item.rarity.color))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color(item.rarity.color).opacity(0.2)))
                            .rarityShimmer(item.rarity)
                        Text("Lv.\(item.levelRequirement)")
                            .font(.custom("Avenir-Medium", size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isPurchased {
                    Text("Sold")
                        .font(.custom("Avenir-Heavy", size: 13))
                        .foregroundColor(.secondary)
                } else {
                    HStack(spacing: 4) {
                        GoldCoinIcon(size: 14)
                        Text("\(price)")
                            .font(.custom("Avenir-Heavy", size: 15))
                            .foregroundColor(canAfford ? Color("AccentGold") : .red)
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color("CardBackground"))
            )
            .opacity(isPurchased ? 0.6 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isPurchased)
    }
}

// MARK: - Shop Consumable Card

struct ShopConsumableCard: View {
    let template: ConsumableTemplate
    let canBuy: Bool
    let meetsLevel: Bool
    var limitText: String? = nil
    var displayPrice: Int? = nil
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(template.type.color).opacity(0.2))
                        .frame(width: 50, height: 50)
                    ConsumableIconView(consumableType: template.type, size: 50, imageName: template.imageName)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(template.name)
                        .font(.custom("Avenir-Heavy", size: 14))
                    Text(template.description)
                        .font(.custom("Avenir-Medium", size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    if !meetsLevel {
                        Text("Requires Lv.\(template.levelRequirement)")
                            .font(.custom("Avenir-Medium", size: 10))
                            .foregroundColor(.red)
                    }
                    if let limitText = limitText {
                        Text(limitText)
                            .font(.custom("Avenir-Heavy", size: 10))
                            .foregroundColor(Color("DifficultyHard"))
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if template.gemCost > 0 {
                        HStack(spacing: 3) {
                            GemCurrencyIcon(size: 14)
                            Text("\(template.gemCost)")
                                .font(.custom("Avenir-Heavy", size: 13))
                                .foregroundColor(Color("AccentPurple"))
                        }
                    } else if template.goldCost > 0 {
                        HStack(spacing: 3) {
                            GoldCoinIcon(size: 12)
                            Text("\(displayPrice ?? template.goldCost)")
                                .font(.custom("Avenir-Heavy", size: 13))
                                .foregroundColor(Color("AccentGold"))
                        }
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color("CardBackground"))
            )
            .opacity(canBuy ? 1.0 : 0.6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Equipment Buy Sheet

struct EquipmentBuySheet: View {
    let item: Equipment
    let character: PlayerCharacter?
    let price: Int
    let canAfford: Bool
    let alreadyPurchased: Bool
    let onBuy: () -> Void
    let onDismiss: () -> Void
    
    private var equippedItem: Equipment? {
        character?.equipment.item(for: item.slot)
    }
    
    private var canClassEquip: Bool {
        guard let charClass = character?.characterClass else { return true }
        return charClass.canEquip(item)
    }
    
    private var statDeltas: [(statType: StatType, delta: Int)] {
        StatType.allCases.compactMap { stat in
            let newBonus = bonusFor(item: item, stat: stat)
            let oldBonus = bonusFor(item: equippedItem, stat: stat)
            let delta = newBonus - oldBonus
            guard delta != 0 else { return nil }
            return (stat, delta)
        }
    }
    
    private func bonusFor(item: Equipment?, stat: StatType) -> Int {
        guard let item = item else { return 0 }
        var total = 0
        if item.primaryStat == stat { total += Int(item.statBonus.rounded()) }
        if item.secondaryStat == stat { total += Int(item.secondaryStatBonus.rounded()) }
        return total
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header: icon + name + tags
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color(item.rarity.color).opacity(0.15))
                                .frame(width: 88, height: 88)
                            EquipmentIconView(item: item, slot: item.slot, size: 72)
                        }
                        
                        Text(item.name)
                            .font(.custom("Avenir-Heavy", size: 20))
                            .foregroundColor(Color(item.rarity.color))
                            .multilineTextAlignment(.center)
                        
                        // Tag row: rarity, slot, base type, level, armor weight
                        WrappingHStack(spacing: 6) {
                            ShopInfoTag(text: item.rarity.rawValue, color: Color(item.rarity.color), shimmer: true, rarity: item.rarity)
                            ShopInfoTag(text: item.slot.rawValue, icon: item.slot.icon, color: Color("StoreTeal"))
                            ShopInfoTag(text: item.detectedBaseType.capitalized, color: .secondary)
                            ShopInfoTag(text: "Lv.\(item.levelRequirement)", icon: "arrow.up.circle", color: .secondary)
                            if item.slot == .armor && item.armorWeight != .universal {
                                ShopInfoTag(text: item.armorWeight.label, icon: item.armorWeight == .heavy ? "shield.fill" : "wind", color: item.armorWeight == .heavy ? .orange : Color("StoreTeal"))
                            }
                        }
                    }
                    .padding(.bottom, 4)
                    
                    // Description
                    if !item.itemDescription.isEmpty {
                        Text(item.itemDescription)
                            .font(.custom("Avenir-Medium", size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 8)
                    }
                    
                    // Stats
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(Color("AccentGold"))
                                .font(.caption)
                            Text("Stats")
                                .font(.custom("Avenir-Heavy", size: 14))
                            Spacer()
                        }
                        
                        HStack {
                            Image(systemName: item.primaryStat.icon)
                                .font(.caption)
                                .foregroundColor(Color(item.primaryStat.color))
                                .frame(width: 20)
                            Text(item.primaryStat.rawValue)
                                .font(.custom("Avenir-Medium", size: 14))
                            Spacer()
                            Text("+\(item.statBonusDisplay)")
                                .font(.custom("Avenir-Heavy", size: 16))
                                .foregroundColor(Color("AccentGreen"))
                        }
                        if let secondary = item.secondaryStat, item.secondaryStatBonus > 0 {
                            HStack {
                                Image(systemName: secondary.icon)
                                    .font(.caption)
                                    .foregroundColor(Color(secondary.color))
                                    .frame(width: 20)
                                Text(secondary.rawValue)
                                    .font(.custom("Avenir-Medium", size: 14))
                                Spacer()
                                Text("+\(item.secondaryStatBonusDisplay)")
                                    .font(.custom("Avenir-Heavy", size: 16))
                                    .foregroundColor(Color("AccentGreen"))
                            }
                        }
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color("CardBackground")))
                    
                    // Stat comparison vs equipped
                    if character != nil {
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "arrow.left.arrow.right")
                                    .foregroundColor(Color("AccentGold"))
                                    .font(.caption)
                                Text(equippedItem != nil ? "vs. Equipped" : "vs. Empty Slot")
                                    .font(.custom("Avenir-Heavy", size: 14))
                                Spacer()
                            }
                            
                            if let equipped = equippedItem {
                                HStack(spacing: 6) {
                                    Text("Current:")
                                        .font(.custom("Avenir-Medium", size: 12))
                                        .foregroundColor(.secondary)
                                    Text(equipped.name)
                                        .font(.custom("Avenir-Heavy", size: 12))
                                        .foregroundColor(Color(equipped.rarity.color))
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            if statDeltas.isEmpty {
                                Text("No stat difference")
                                    .font(.custom("Avenir-Medium", size: 13))
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(statDeltas, id: \.statType) { entry in
                                    HStack {
                                        Image(systemName: entry.statType.icon)
                                            .font(.caption)
                                            .foregroundColor(Color(entry.statType.color))
                                            .frame(width: 20)
                                        Text(entry.statType.rawValue)
                                            .font(.custom("Avenir-Medium", size: 14))
                                        Spacer()
                                        HStack(spacing: 4) {
                                            Image(systemName: entry.delta > 0 ? "arrow.up" : "arrow.down")
                                                .font(.system(size: 10, weight: .bold))
                                            Text("\(abs(entry.delta))")
                                                .font(.custom("Avenir-Heavy", size: 15))
                                        }
                                        .foregroundColor(entry.delta > 0 ? Color("AccentGreen") : .red)
                                    }
                                }
                            }
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color("CardBackground")))
                    }
                    
                    // Class equippability (only relevant for armor)
                    if item.slot == .armor {
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "person.3.fill")
                                    .foregroundColor(Color("AccentGold"))
                                    .font(.caption)
                                Text("Who Can Equip")
                                    .font(.custom("Avenir-Heavy", size: 14))
                                Spacer()
                            }
                            
                            HStack(spacing: 12) {
                                ForEach([ClassLine.warrior, .mage, .archer], id: \.self) { line in
                                    let starterClass = starterForLine(line)
                                    let canWear = starterClass.armorProficiency.contains(item.armorWeight)
                                    let isPlayerLine = character?.characterClass?.classLine == line
                                    
                                    VStack(spacing: 4) {
                                        Image(systemName: starterClass.icon)
                                            .font(.system(size: 18))
                                            .foregroundColor(canWear ? (isPlayerLine ? Color("AccentGold") : .primary) : .secondary.opacity(0.4))
                                        Text(line.rawValue.capitalized)
                                            .font(.custom("Avenir-Heavy", size: 11))
                                            .foregroundColor(canWear ? (isPlayerLine ? Color("AccentGold") : .primary) : .secondary.opacity(0.4))
                                        Image(systemName: canWear ? "checkmark.circle.fill" : "xmark.circle")
                                            .font(.system(size: 12))
                                            .foregroundColor(canWear ? Color("AccentGreen") : .red.opacity(0.6))
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color("CardBackground")))
                    }
                }
                .padding(20)
            }
            
            // Buy button pinned at bottom
            VStack(spacing: 0) {
                Divider()
                
                if alreadyPurchased {
                    Text("Already Purchased")
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 16)
                } else {
                    VStack(spacing: 6) {
                        if !canClassEquip {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                Text("Your class cannot equip this item")
                                    .font(.custom("Avenir-Medium", size: 12))
                            }
                            .foregroundColor(.orange)
                        }
                        
                        Button(action: onBuy) {
                            HStack {
                                GoldCoinIcon(size: 16)
                                Text("Buy for \(price) Gold")
                            }
                            .font(.custom("Avenir-Heavy", size: 16))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                canAfford ?
                                AnyShapeStyle(LinearGradient(colors: [Color("StoreTeal"), Color("AccentGreen")], startPoint: .leading, endPoint: .trailing)) :
                                AnyShapeStyle(Color.secondary.opacity(0.3))
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(!canAfford)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { onDismiss() }
                        .foregroundColor(Color("AccentGold"))
                }
            }
        }
    }
    
    private func starterForLine(_ line: ClassLine) -> CharacterClass {
        switch line {
        case .warrior: return .warrior
        case .mage: return .mage
        case .archer: return .archer
        }
    }
}

// MARK: - Shop Info Tag

struct ShopInfoTag: View {
    let text: String
    var icon: String? = nil
    let color: Color
    var shimmer: Bool = false
    var rarity: ItemRarity? = nil
    
    var body: some View {
        HStack(spacing: 3) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 9))
            }
            Text(text)
                .font(.custom("Avenir-Heavy", size: 10))
        }
        .foregroundColor(color)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Capsule().fill(color.opacity(0.15)))
        .modifier(OptionalRarityShimmer(rarity: shimmer ? rarity : nil))
    }
}

struct OptionalRarityShimmer: ViewModifier {
    let rarity: ItemRarity?
    
    func body(content: Content) -> some View {
        if let rarity = rarity {
            content.rarityShimmer(rarity)
        } else {
            content
        }
    }
}

// MARK: - Wrapping HStack

struct WrappingHStack: Layout {
    var spacing: CGFloat = 6
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: ProposedViewSize(width: bounds.width, height: nil), subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalWidth = max(totalWidth, x - spacing)
            totalHeight = y + rowHeight
        }
        return (CGSize(width: totalWidth, height: totalHeight), positions)
    }
}

// MARK: - Consumable Buy Sheet

struct ConsumableBuySheet: View {
    let template: ConsumableTemplate
    let character: PlayerCharacter?
    let onBuy: (Int) -> Void
    let onDismiss: () -> Void
    
    @State private var quantity: Int = 1
    
    private var unitCost: Int {
        template.goldCost > 0 ? template.goldCost : template.gemCost
    }
    
    private var totalCost: Int {
        unitCost * quantity
    }
    
    private var isGemPurchase: Bool {
        template.gemCost > 0
    }
    
    private var maxAffordable: Int {
        guard let character = character, unitCost > 0 else { return 0 }
        let balance = isGemPurchase ? character.gems : character.gold
        return max(0, balance / unitCost)
    }
    
    private var canAfford: Bool {
        guard let character = character else { return false }
        guard character.level >= template.levelRequirement else { return false }
        return maxAffordable >= quantity
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color(template.type.color).opacity(0.2))
                        .frame(width: 80, height: 80)
                    ConsumableIconView(consumableType: template.type, size: 80, imageName: template.imageName)
                }
                
                VStack(spacing: 6) {
                    Text(template.name)
                        .font(.custom("Avenir-Heavy", size: 20))
                    Text(template.description)
                        .font(.custom("Avenir-Medium", size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Effect
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(Color(template.type.color))
                    Text(effectSummary)
                        .font(.custom("Avenir-Medium", size: 14))
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color("CardBackground")))
                
                // Quantity selector
                VStack(spacing: 8) {
                    Text("QUANTITY")
                        .font(.custom("Avenir-Heavy", size: 12))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 20) {
                        Button {
                            if quantity > 1 { quantity -= 1 }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(quantity > 1 ? Color("AccentGold") : .secondary.opacity(0.3))
                        }
                        .disabled(quantity <= 1)
                        
                        Text("\(quantity)")
                            .font(.custom("Avenir-Heavy", size: 28))
                            .frame(minWidth: 44)
                        
                        Button {
                            if quantity < min(10, maxAffordable) { quantity += 1 }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(quantity < min(10, maxAffordable) ? Color("AccentGold") : .secondary.opacity(0.3))
                        }
                        .disabled(quantity >= min(10, maxAffordable))
                    }
                }
                .padding(.vertical, 8)
                
                Spacer()
                
                // Buy button
                Button(action: { onBuy(quantity) }) {
                    HStack {
                        if isGemPurchase {
                            GemCurrencyIcon(size: 18)
                            Text(quantity > 1 ? "Buy \(quantity) for \(totalCost) Gems" : "Buy for \(totalCost) Gems")
                        } else {
                            GoldCoinIcon(size: 16)
                            Text(quantity > 1 ? "Buy \(quantity) for \(totalCost) Gold" : "Buy for \(totalCost) Gold")
                        }
                    }
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        canAfford ?
                        AnyShapeStyle(
                            isGemPurchase ?
                            LinearGradient(colors: [Color("AccentPurple"), Color("AccentPurple").opacity(0.7)], startPoint: .leading, endPoint: .trailing) :
                            LinearGradient(colors: [Color("StoreTeal"), Color("AccentGreen")], startPoint: .leading, endPoint: .trailing)
                        ) :
                        AnyShapeStyle(Color.secondary.opacity(0.3))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!canAfford)
            }
            .padding(24)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { onDismiss() }
                        .foregroundColor(Color("AccentGold"))
                }
            }
        }
    }
    
    private var effectSummary: String {
        switch template.type {
        case .hpPotion: return "Restore \(template.effectValue) HP"
        case .expBoost: return "+50% EXP for \(template.effectValue) tasks"
        case .goldBoost: return "+50% Gold for \(template.effectValue) tasks"
        case .missionSpeedUp: return "Halve remaining mission time"
        case .streakShield:
            let days = template.effectValue > 1 ? "\(template.effectValue) days" : "1 day"
            return "Protect streak for \(days)"
        case .statFood:
            if let stat = template.effectStat {
                return "+\(template.effectValue) \(stat.rawValue) (temporary)"
            }
            return "+\(template.effectValue) to a stat"
        case .dungeonRevive: return "Revive party in a failed dungeon"
        case .lootReroll: return "Re-roll stats on one equipment piece"
        case .materialMagnet: return "Double material drops for \(template.effectValue) tasks"
        case .luckElixir: return "+20% rare drop chance for next dungeon"
        case .partyBeacon: return "+25% party bond EXP for 1 hour"
        case .affixScroll: return "Guarantees at least 1 affix on next equip drop"
        case .dutyScroll: return "Grants a random active duty from the pool"
        case .forgeCatalyst: return "Double enhancement success chance for 1 attempt"
        case .expeditionCompass: return "Reveal hidden expedition paths"
        case .regenBuff: return "Boost HP regen to \(template.effectValue) HP/hr"
        }
    }
}

// MARK: - Shop Filter Pill

struct ShopFilterPill: View {
    let label: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                }
                Text(label)
                    .font(.custom("Avenir-Heavy", size: 12))
            }
            .foregroundColor(isSelected ? .black : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(isSelected ? Color("StoreTeal") : Color("CardBackground"))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        StoreView()
            .environmentObject(GameEngine())
    }
}
