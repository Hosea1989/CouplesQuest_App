import SwiftUI
import SwiftData

struct StoreView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var gameEngine: GameEngine
    @Query private var characters: [PlayerCharacter]
    
    @State private var selectedTab: StoreTab = .equipment
    @State private var dailyStock: [Equipment] = []
    @State private var selectedEquipment: Equipment?
    @State private var selectedConsumable: ConsumableTemplate?
    @State private var showBuyConfirm = false
    @State private var showConsumableBuyConfirm = false
    @State private var purchaseTrigger = 0
    @State private var purchasedEquipmentIDs: Set<UUID> = []
    
    enum StoreTab: String, CaseIterable {
        case equipment = "Equipment"
        case consumables = "Consumables"
    }
    
    private var character: PlayerCharacter? {
        characters.first
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
                        case .equipment:
                            equipmentSection
                        case .consumables:
                            consumablesSection
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
                    onDismiss: { showBuyConfirm = false }
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
                    onDismiss: { showConsumableBuyConfirm = false }
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
            
            ForEach(ConsumableCatalog.items) { template in
                let meetsLevel = (character?.level ?? 1) >= template.levelRequirement
                let canAffordGold = template.goldCost == 0 || (character?.gold ?? 0) >= template.goldCost
                let canBuy = meetsLevel && canAffordGold
                
                ShopConsumableCard(
                    template: template,
                    canBuy: canBuy,
                    meetsLevel: meetsLevel
                ) {
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
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(item.rarity.color).opacity(0.2))
                        .frame(width: 50, height: 50)
                    Image(systemName: item.slot.icon)
                        .font(.title3)
                        .foregroundColor(Color(item.rarity.color))
                }
                
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
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if template.goldCost > 0 {
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
                ZStack {
                    Circle()
                        .fill(Color(item.rarity.color).opacity(0.2))
                        .frame(width: 80, height: 80)
                    Image(systemName: item.slot.icon)
                        .font(.system(size: 36))
                        .foregroundColor(Color(item.rarity.color))
                }
                
                VStack(spacing: 6) {
                    Text(item.name)
                        .font(.custom("Avenir-Heavy", size: 20))
                        .foregroundColor(Color(item.rarity.color))
                    Text(item.rarity.rawValue + " " + item.slot.rawValue)
                        .font(.custom("Avenir-Medium", size: 14))
                        .foregroundColor(.secondary)
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
        return character.level >= template.levelRequirement
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
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(Color("AccentGold"))
                        Text("Buy for \(template.goldCost) Gold")
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
        case .hpPotion: return "Restore \(template.effectValue) HP in dungeons"
        case .expBoost: return "+50% EXP for \(template.effectValue) tasks"
        case .goldBoost: return "+50% Gold for \(template.effectValue) tasks"
        case .missionSpeedUp: return "Halve remaining mission time"
        case .streakShield: return "Protect streak for 1 day"
        case .statFood:
            if let stat = template.effectStat {
                return "+\(template.effectValue) \(stat.rawValue) (temporary)"
            }
            return "+\(template.effectValue) to a stat"
        }
    }
}

#Preview {
    NavigationStack {
        StoreView()
            .environmentObject(GameEngine())
    }
}
