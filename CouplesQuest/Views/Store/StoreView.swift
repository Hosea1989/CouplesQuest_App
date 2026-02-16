import SwiftUI
import SwiftData

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
        }
        .onChange(of: selectedTab) { _, newTab in
            shopkeeperItemTip = nil
            shopkeeperMessage = ShopkeeperDialogue.greeting(for: newTab.rawValue, name: character?.name)
        }
        .sheet(isPresented: $showBuyConfirm) {
            if let item = selectedEquipment {
                EquipmentBuySheet(
                    item: item,
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
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showConsumableBuyConfirm) {
            if let template = selectedConsumable {
                ConsumableBuySheet(
                    template: template,
                    character: character,
                    onBuy: {
                        buyConsumable(template)
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
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(Color("AccentGold"))
                Text("\(character?.gold ?? 0)")
                    .font(.custom("Avenir-Heavy", size: 18))
            }
            
            Button {
                shopkeeperItemTip = ShopkeeperDialogue.gemExplanation
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "diamond.fill")
                        .foregroundColor(Color("AccentPurple"))
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
            } else {
                ForEach(dailyStock, id: \.id) { item in
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
            }
            
            ForEach(ConsumableCatalog.activeGoldItems) { template in
                let meetsLevel = (character?.level ?? 1) >= template.levelRequirement
                let canAffordGold = template.goldCost == 0 || (character?.gold ?? 0) >= template.goldCost
                let regenAtCap = template.type == .regenBuff && regenBuffOwnedCount >= GameEngine.maxRegenBuffCount
                let canBuy = meetsLevel && canAffordGold && !regenAtCap
                
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
    
    // MARK: - Premium Section
    
    private var premiumSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "diamond.fill")
                    .foregroundColor(Color("AccentPurple"))
                Text("Premium Items")
                    .font(.custom("Avenir-Heavy", size: 18))
                Spacer()
            }
            
            Text("Spend gems on rare and powerful items.")
                .font(.custom("Avenir-Medium", size: 13))
                .foregroundColor(.secondary)
            
            ForEach(ConsumableCatalog.activeGemItems) { template in
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
            purchasedEquipmentIDs.insert(item.id)
            purchaseTrigger += 1
            showBuyConfirm = false
        }
    }
    
    private func buyConsumable(_ template: ConsumableTemplate) {
        guard let character = character else { return }
        if gameEngine.buyConsumable(template, character: character, context: modelContext) {
            purchaseTrigger += 1
            showConsumableBuyConfirm = false
            ToastManager.shared.showSuccess("Purchased: \(template.name)", subtitle: "-\(template.goldCost) Gold")
        }
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
            ownerID: character.id
        )
        modelContext.insert(purchased)
        Task { try? await SupabaseService.shared.syncEquipment(purchased) }
        try? modelContext.save()
        purchasedDealID = item.id
        purchaseTrigger += 1
        shopkeeperItemTip = "Wise choice! That deal won't come around again."
        ToastManager.shared.showLoot("Purchased: \(item.name)", rarity: item.rarity.rawValue)
    }
    
    private func buyMilestoneItem(_ item: MilestoneItem) {
        guard let character = character else { return }
        if gameEngine.buyMilestoneGear(item, character: character, context: modelContext) {
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
        Task { try? await SupabaseService.shared.syncEquipment(purchased) }
        try? modelContext.save()
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
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(Color("AccentGold"))
                            .font(.caption)
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
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(template.type.color).opacity(0.2))
                        .frame(width: 50, height: 50)
                    Image(systemName: template.icon)
                        .font(.title3)
                        .foregroundColor(Color(template.type.color))
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
                            Image(systemName: "diamond.fill")
                                .foregroundColor(Color("AccentPurple"))
                                .font(.caption2)
                            Text("\(template.gemCost)")
                                .font(.custom("Avenir-Heavy", size: 13))
                                .foregroundColor(Color("AccentPurple"))
                        }
                    } else if template.goldCost > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "dollarsign.circle.fill")
                                .foregroundColor(Color("AccentGold"))
                                .font(.caption2)
                            Text("\(template.goldCost)")
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
    let price: Int
    let canAfford: Bool
    let alreadyPurchased: Bool
    let onBuy: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Item Preview
                EquipmentIconView(item: item, slot: item.slot, size: 64)
                
                VStack(spacing: 6) {
                    Text(item.name)
                        .font(.custom("Avenir-Heavy", size: 20))
                        .foregroundColor(Color(item.rarity.color))
                    Text(item.rarity.rawValue + " " + item.slot.rawValue)
                        .font(.custom("Avenir-Medium", size: 14))
                        .foregroundColor(.secondary)
                        .rarityShimmer(item.rarity)
                }
                
                // Stats
                VStack(spacing: 8) {
                    HStack {
                        Text(item.primaryStat.rawValue)
                            .font(.custom("Avenir-Medium", size: 14))
                        Spacer()
                        Text("+\(item.statBonus)")
                            .font(.custom("Avenir-Heavy", size: 16))
                            .foregroundColor(Color("AccentGreen"))
                    }
                    if let secondary = item.secondaryStat, item.secondaryStatBonus > 0 {
                        HStack {
                            Text(secondary.rawValue)
                                .font(.custom("Avenir-Medium", size: 14))
                            Spacer()
                            Text("+\(item.secondaryStatBonus)")
                                .font(.custom("Avenir-Heavy", size: 16))
                                .foregroundColor(Color("AccentGreen"))
                        }
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color("CardBackground")))
                
                Spacer()
                
                // Buy button
                if alreadyPurchased {
                    Text("Already Purchased")
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.secondary)
                } else {
                    Button(action: onBuy) {
                        HStack {
                            Image(systemName: "dollarsign.circle.fill")
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
}

// MARK: - Consumable Buy Sheet

struct ConsumableBuySheet: View {
    let template: ConsumableTemplate
    let character: PlayerCharacter?
    let onBuy: () -> Void
    let onDismiss: () -> Void
    
    private var canAfford: Bool {
        guard let character = character else { return false }
        if template.goldCost > 0 && character.gold < template.goldCost { return false }
        if template.gemCost > 0 && character.gems < template.gemCost { return false }
        return character.level >= template.levelRequirement
    }
    
    private var isGemPurchase: Bool {
        template.gemCost > 0
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color(template.type.color).opacity(0.2))
                        .frame(width: 80, height: 80)
                    Image(systemName: template.icon)
                        .font(.system(size: 36))
                        .foregroundColor(Color(template.type.color))
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
                
                Spacer()
                
                // Buy button
                Button(action: onBuy) {
                    HStack {
                        if isGemPurchase {
                            Image(systemName: "diamond.fill")
                                .foregroundColor(Color("AccentPurple"))
                            Text("Buy for \(template.gemCost) Gems")
                        } else {
                            Image(systemName: "dollarsign.circle.fill")
                                .foregroundColor(Color("AccentGold"))
                            Text("Buy for \(template.goldCost) Gold")
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
        case .forgeCatalyst: return "Double enhancement success chance for 1 attempt"
        case .expeditionCompass: return "Reveal hidden expedition paths"
        case .regenBuff: return "Boost HP regen to \(template.effectValue) HP/hr"
        }
    }
}

#Preview {
    NavigationStack {
        StoreView()
            .environmentObject(GameEngine())
    }
}
