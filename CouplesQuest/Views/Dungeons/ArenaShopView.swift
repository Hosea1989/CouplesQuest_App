import SwiftUI

struct ArenaShopView: View {
    let character: PlayerCharacter
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedCategory: ArenaShopItem.ArenaShopCategory = .equipment
    @State private var showPurchaseConfirm = false
    @State private var itemToPurchase: ArenaShopItem?
    @State private var purchaseMessage = ""
    
    private var filteredItems: [ArenaShopItem] {
        ArenaShopItem.allItems.filter { $0.category == selectedCategory }
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
                
                VStack(spacing: 0) {
                    // Balance header
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "star.circle.fill")
                                .foregroundColor(Color("AccentGold"))
                            Text("\(character.arenaPoints) Arena Points")
                                .font(.custom("Avenir-Heavy", size: 15))
                                .foregroundColor(Color("AccentGold"))
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    // Category picker
                    HStack(spacing: 0) {
                        ForEach(ArenaShopItem.ArenaShopCategory.allCases, id: \.rawValue) { cat in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedCategory = cat
                                }
                            } label: {
                                Text(cat.rawValue)
                                    .font(.custom("Avenir-Heavy", size: 13))
                                    .foregroundColor(selectedCategory == cat ? Color("AccentGold") : .secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        selectedCategory == cat
                                            ? Color("AccentGold").opacity(0.12)
                                            : Color.clear
                                    )
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    
                    // Items list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredItems) { item in
                                shopItemCard(item)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Arena Shop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Purchase", isPresented: $showPurchaseConfirm) {
                Button("Buy", role: .destructive) {
                    if let item = itemToPurchase {
                        purchaseItem(item)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                if let item = itemToPurchase {
                    Text("Buy \(item.name) for \(item.cost) Arena Points?")
                }
            }
            .overlay {
                if !purchaseMessage.isEmpty {
                    VStack {
                        Spacer()
                        Text(purchaseMessage)
                            .font(.custom("Avenir-Heavy", size: 14))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color("AccentGold").opacity(0.9))
                            .cornerRadius(10)
                            .padding(.bottom, 40)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
        }
    }
    
    private func shopItemCard(_ item: ArenaShopItem) -> some View {
        let canAfford = character.arenaPoints >= item.cost
        
        return HStack(spacing: 12) {
            // Icon
            if item.category == .equipment, let rarity = item.rarity {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(rarityColor(rarity).opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(item.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                }
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color("AccentGold").opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: item.icon)
                        .font(.system(size: 22))
                        .foregroundColor(Color("AccentGold"))
                }
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(.custom("Avenir-Heavy", size: 14))
                        .foregroundColor(.primary)
                    
                    if let rarity = item.rarity {
                        Text(rarity.capitalized)
                            .font(.custom("Avenir-Heavy", size: 10))
                            .foregroundColor(rarityColor(rarity))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(rarityColor(rarity).opacity(0.15))
                            .cornerRadius(4)
                    }
                }
                
                Text(item.itemDescription)
                    .font(.custom("Avenir-Medium", size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button {
                itemToPurchase = item
                showPurchaseConfirm = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 11))
                    Text("\(item.cost)")
                        .font(.custom("Avenir-Heavy", size: 13))
                }
                .foregroundColor(canAfford ? .white : .gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    canAfford
                        ? AnyShapeStyle(LinearGradient(colors: [Color("AccentGold"), Color("AccentOrange")], startPoint: .leading, endPoint: .trailing))
                        : AnyShapeStyle(Color.gray.opacity(0.3))
                )
                .cornerRadius(8)
            }
            .disabled(!canAfford)
        }
        .padding(12)
        .background(Color("CardBackground").opacity(0.5))
        .cornerRadius(12)
    }
    
    private func rarityColor(_ rarity: String) -> Color {
        switch rarity.lowercased() {
        case "rare": return .blue
        case "epic": return .purple
        case "legendary": return .orange
        default: return .gray
        }
    }
    
    private func purchaseItem(_ item: ArenaShopItem) {
        guard character.arenaPoints >= item.cost else { return }
        character.arenaPoints -= item.cost
        
        switch item.category {
        case .equipment:
            if let slot = item.equipmentSlot, let rarity = item.rarity {
                let itemRarity: ItemRarity
                switch rarity.lowercased() {
                case "rare": itemRarity = .rare
                case "epic": itemRarity = .epic
                case "legendary": itemRarity = .legendary
                default: itemRarity = .rare
                }
                
                let primaryStat: StatType = slot == .weapon ? .strength : (slot == .accessory ? .charisma : .defense)
                let baseBonus: Double = {
                    switch itemRarity {
                    case .rare: return 6
                    case .epic: return 10
                    case .legendary: return 15
                    default: return 4
                    }
                }()
                
                let equip = Equipment(
                    name: item.name,
                    description: item.itemDescription,
                    slot: slot,
                    rarity: itemRarity,
                    primaryStat: primaryStat,
                    statBonus: baseBonus,
                    levelRequirement: 6,
                    baseType: item.equipmentBaseType
                )
                equip.ownerID = character.id
                modelContext.insert(equip)
            }
            
        case .titles:
            character.arenaTitle = item.name
            
        case .consumables:
            // TODO: Apply consumable effect
            break
        }
        
        showPurchaseToast("\(item.name) purchased!")
    }
    
    private func showPurchaseToast(_ message: String) {
        withAnimation { purchaseMessage = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { purchaseMessage = "" }
        }
    }
}
