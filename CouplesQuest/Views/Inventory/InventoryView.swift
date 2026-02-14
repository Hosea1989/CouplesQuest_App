import SwiftUI
import SwiftData

enum InventoryTab: String, CaseIterable {
    case equipment = "Equipment"
    case materials = "Materials"
    case consumables = "Consumables"
}

struct InventoryView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var gameEngine: GameEngine
    @Query private var allEquipment: [Equipment]
    @Query private var characters: [PlayerCharacter]
    @Query private var allMaterials: [CraftingMaterial]
    @Query private var allConsumables: [Consumable]
    
    @State private var selectedTab: InventoryTab = .equipment
    @State private var selectedSlotFilter: EquipmentSlot?
    @State private var selectedItem: Equipment?
    @State private var showItemDetail = false
    @State private var equipTrigger = 0
    @State private var discardTrigger = 0
    @State private var dismantleTrigger = 0
    @State private var lastDismantleFragments: Int = 0
    @State private var showDismantleResult = false
    
    private var character: PlayerCharacter? {
        characters.first
    }
    
    /// Crafting materials owned by the current character, sorted by type
    private var ownedMaterials: [CraftingMaterial] {
        guard let character = character else { return [] }
        return allMaterials
            .filter { $0.characterID == character.id && $0.quantity > 0 }
            .sorted { ($0.materialType.rawValue, $0.rarity.rawValue) < ($1.materialType.rawValue, $1.rarity.rawValue) }
    }
    
    private var ownedEquipment: [Equipment] {
        guard let character = character else { return [] }
        return allEquipment.filter { $0.ownerID == character.id }
    }
    
    private var equippedItems: [Equipment] {
        ownedEquipment.filter { $0.isEquipped }
    }
    
    private var unequippedItems: [Equipment] {
        let items = ownedEquipment.filter { !$0.isEquipped }
        if let filter = selectedSlotFilter {
            return items.filter { $0.slot == filter }
        }
        return items.sorted { rarityOrder($0.rarity) > rarityOrder($1.rarity) }
    }
    
    /// Consumables owned by the current character, sorted by type then name
    private var ownedConsumables: [Consumable] {
        guard let character = character else { return [] }
        return allConsumables
            .filter { $0.characterID == character.id && $0.remainingUses > 0 }
            .sorted { ($0.consumableType.rawValue, $0.name) < ($1.consumableType.rawValue, $1.name) }
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
                    // Tab Picker
                    Picker("Inventory", selection: $selectedTab) {
                        ForEach(InventoryTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    if selectedTab == .equipment {
                        equipmentContent
                    } else if selectedTab == .materials {
                        materialsContent
                    } else {
                        consumablesContent
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Inventory")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if (character?.level ?? 0) >= 10 {
                    NavigationLink {
                        ForgeView()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "hammer.fill")
                            Text("Forge")
                                .font(.custom("Avenir-Heavy", size: 13))
                        }
                        .foregroundColor(Color("AccentPurple"))
                    }
                }
            }
        }
        .sheet(isPresented: $showItemDetail) {
            if let item = selectedItem {
                ItemDetailView(
                    item: item,
                    character: character,
                    onEquip: { equipItem(item) },
                    onUnequip: { unequipItem(item) },
                    onDiscard: { discardItem(item) },
                    onDismantle: { dismantleItem(item) }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .sensoryFeedback(.success, trigger: equipTrigger)
        .sensoryFeedback(.impact(weight: .medium), trigger: discardTrigger)
        .sensoryFeedback(.success, trigger: dismantleTrigger)
        .alert("Dismantled!", isPresented: $showDismantleResult) {
            Button("OK") {}
        } message: {
            Text("Received \(lastDismantleFragments) Fragment\(lastDismantleFragments > 1 ? "s" : "")!")
        }
    }
    
    // MARK: - Consumables Content
    
    private var consumablesContent: some View {
        VStack(spacing: 16) {
            if ownedConsumables.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "cross.vial.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No Consumables Yet")
                        .font(.custom("Avenir-Heavy", size: 18))
                        .foregroundColor(.secondary)
                    Text("Buy consumables from the Store or earn them from tasks and dungeons.")
                        .font(.custom("Avenir-Medium", size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Spacer()
                }
                .frame(minHeight: 300)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Consumables")
                        .font(.custom("Avenir-Heavy", size: 20))
                    ForEach(ownedConsumables, id: \.id) { consumable in
                        ConsumableInventoryRow(
                            consumable: consumable,
                            character: character,
                            onUse: { useConsumable(consumable) }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func useConsumable(_ consumable: Consumable) {
        guard let char = character else { return }
        if gameEngine.useConsumable(consumable, on: char, context: modelContext) {
            ToastManager.shared.showSuccess("Used \(consumable.name)", subtitle: consumable.effectSummary)
        }
    }
    
    // MARK: - Materials Content
    
    private var materialsContent: some View {
        VStack(spacing: 16) {
            if ownedMaterials.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "cube.box")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No Materials Yet")
                        .font(.custom("Avenir-Heavy", size: 18))
                        .foregroundColor(.secondary)
                    Text("Complete tasks, dungeons, and training to collect crafting materials.")
                        .font(.custom("Avenir-Medium", size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Spacer()
                }
                .frame(minHeight: 300)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(ownedMaterials, id: \.id) { material in
                        MaterialCard(material: material)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Equipment Content
    
    private var equipmentContent: some View {
        VStack(spacing: 24) {
                    // Currently Equipped Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Equipped")
                            .font(.custom("Avenir-Heavy", size: 20))
                        
                        if let character = character {
                            ForEach(EquipmentSlot.allCases, id: \.self) { slot in
                                let equippedItem = character.equipment.item(for: slot)
                                EquippedSlotCard(slot: slot, equipment: equippedItem) {
                                    if let item = equippedItem {
                                        selectedItem = item
                                        showItemDetail = true
                                    } else {
                                        // Empty slot tapped — auto-filter inventory to that slot
                                        selectedSlotFilter = slot
                                    }
                                }
                                .contextMenu {
                                    if let item = equippedItem {
                                        Button {
                                            unequipItem(item)
                                        } label: {
                                            Label("Unequip", systemImage: "minus.circle")
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Inventory Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Inventory")
                                .font(.custom("Avenir-Heavy", size: 20))
                            Spacer()
                            Text("\(unequippedItems.count) items")
                                .font(.custom("Avenir-Medium", size: 14))
                                .foregroundColor(.secondary)
                        }
                        
                        // Slot Filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                FilterChip(label: "All", isSelected: selectedSlotFilter == nil) {
                                    selectedSlotFilter = nil
                                }
                                ForEach(EquipmentSlot.allCases, id: \.self) { slot in
                                    FilterChip(
                                        label: slot.rawValue,
                                        icon: slot.icon,
                                        isSelected: selectedSlotFilter == slot
                                    ) {
                                        selectedSlotFilter = selectedSlotFilter == slot ? nil : slot
                                    }
                                }
                            }
                        }
                        
                        if unequippedItems.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "shippingbox")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                Text("No items in inventory")
                                    .font(.custom("Avenir-Heavy", size: 16))
                                    .foregroundColor(.secondary)
                                Text("Complete dungeons to earn loot!")
                                    .font(.custom("Avenir-Medium", size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(40)
                        } else {
                            ForEach(unequippedItems, id: \.id) { item in
                                InventoryItemRow(item: item) {
                                    selectedItem = item
                                    showItemDetail = true
                                }
                                .contextMenu {
                                    if let character = character, character.level >= item.levelRequirement {
                                        Button {
                                            equipItem(item)
                                        } label: {
                                            Label("Equip", systemImage: "checkmark.circle.fill")
                                        }
                                    }
                                    
                                    Button {
                                        selectedItem = item
                                        showItemDetail = true
                                    } label: {
                                        Label("View Details", systemImage: "info.circle")
                                    }
                                    
                                    Divider()
                                    
                                    Button {
                                        dismantleItem(item)
                                    } label: {
                                        Label("Dismantle", systemImage: "hammer.fill")
                                    }
                                    
                                    Button(role: .destructive) {
                                        discardItem(item)
                                    } label: {
                                        Label("Discard", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
        }
    }
    
    // MARK: - Actions
    
    private func equipItem(_ item: Equipment) {
        guard let character = character else { return }
        
        // Unequip current item in that slot and sync the old item
        if let current = character.equipment.item(for: item.slot) {
            current.isEquipped = false
            Task { try? await SupabaseService.shared.syncEquipment(current) }
        }
        character.equipment.setItem(item, for: item.slot)
        
        item.isEquipped = true
        Task { try? await SupabaseService.shared.syncEquipment(item) }
        showItemDetail = false
        equipTrigger += 1
        AudioManager.shared.play(.equipItem)
    }
    
    private func unequipItem(_ item: Equipment) {
        guard let character = character else { return }
        
        if character.equipment.item(for: item.slot)?.id == item.id {
            character.equipment.setItem(nil, for: item.slot)
        }
        
        item.isEquipped = false
        Task { try? await SupabaseService.shared.syncEquipment(item) }
        showItemDetail = false
        equipTrigger += 1
    }
    
    private func discardItem(_ item: Equipment) {
        if item.isEquipped {
            unequipItem(item)
        }
        let deletedID = item.id
        modelContext.delete(item)
        Task { try? await SupabaseService.shared.deleteEquipment(id: deletedID) }
        showItemDetail = false
        discardTrigger += 1
    }
    
    private func dismantleItem(_ item: Equipment) {
        guard let character = character else { return }
        let fragments = gameEngine.awardFragmentsForDismantle(
            itemRarity: item.rarity,
            character: character,
            context: modelContext
        )
        
        if item.isEquipped {
            unequipItem(item)
        }
        let deletedID = item.id
        modelContext.delete(item)
        Task { try? await SupabaseService.shared.deleteEquipment(id: deletedID) }
        showItemDetail = false
        lastDismantleFragments = fragments
        showDismantleResult = true
        dismantleTrigger += 1
    }
    
    private func rarityOrder(_ rarity: ItemRarity) -> Int {
        switch rarity {
        case .common: return 0
        case .uncommon: return 1
        case .rare: return 2
        case .epic: return 3
        case .legendary: return 4
        }
    }
}

// MARK: - Equipped Slot Card

struct EquippedSlotCard: View {
    let slot: EquipmentSlot
    let equipment: Equipment?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(equipment != nil ? Color(equipment!.rarity.color).opacity(0.2) : Color.secondary.opacity(0.15))
                        .frame(width: 50, height: 50)
                    EquipmentIconView(item: equipment, slot: slot, size: 50)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(slot.rawValue)
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                    if let equipment = equipment {
                        Text(equipment.name)
                            .font(.custom("Avenir-Heavy", size: 15))
                            .foregroundColor(Color(equipment.rarity.color))
                        Text(equipment.statSummary)
                            .font(.custom("Avenir-Medium", size: 12))
                            .foregroundColor(Color("AccentGreen"))
                        // Show affixes if present
                        if let affixText = equipment.affixSummary {
                            Text(affixText)
                                .font(.custom("Avenir-Medium", size: 11))
                                .foregroundColor(Color("AccentPurple"))
                        }
                    } else {
                        Text("Tap to browse")
                            .font(.custom("Avenir-Medium", size: 15))
                            .foregroundColor(Color("AccentGold").opacity(0.6))
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color("CardBackground")))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Inventory Item Row

struct InventoryItemRow: View {
    let item: Equipment
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(item.rarity.color).opacity(0.2))
                        .frame(width: 46, height: 46)
                    EquipmentIconView(item: item, slot: item.slot, size: 46)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name)
                        .font(.custom("Avenir-Heavy", size: 14))
                        .foregroundColor(Color(item.rarity.color))
                    Text(item.statSummary)
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                    // Show affix summary
                    if let affixText = item.affixSummary {
                        Text(affixText)
                            .font(.custom("Avenir-Medium", size: 11))
                            .foregroundColor(Color("AccentPurple"))
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 3) {
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
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color("CardBackground")))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Consumable Inventory Row

struct ConsumableInventoryRow: View {
    let consumable: Consumable
    let character: PlayerCharacter?
    let onUse: () -> Void
    
    private var isUsableType: Bool {
        consumable.consumableType == .hpPotion || consumable.consumableType == .regenBuff
    }
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(consumable.consumableType.color).opacity(0.2))
                    .frame(width: 46, height: 46)
                Image(systemName: consumable.icon)
                    .font(.title3)
                    .foregroundColor(Color(consumable.consumableType.color))
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(consumable.name)
                    .font(.custom("Avenir-Heavy", size: 14))
                    .foregroundColor(Color(consumable.consumableType.color))
                Text(consumable.effectSummary)
                    .font(.custom("Avenir-Medium", size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isUsableType, character != nil {
                Button {
                    onUse()
                } label: {
                    Text("Use")
                        .font(.custom("Avenir-Heavy", size: 12))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color("AccentGreen")))
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color("CardBackground")))
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    var icon: String? = nil
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(label)
                    .font(.custom("Avenir-Heavy", size: 13))
            }
            .foregroundColor(isSelected ? .black : .secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(isSelected ? Color("AccentGold") : Color("CardBackground"))
            )
        }
    }
}

// MARK: - Material Card

struct MaterialCard: View {
    let material: CraftingMaterial
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: material.icon)
                    .font(.title3)
                    .foregroundColor(Color(material.materialType.color))
                Spacer()
                Text("×\(material.quantity)")
                    .font(.custom("Avenir-Heavy", size: 22))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(material.displayName)
                    .font(.custom("Avenir-Heavy", size: 14))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if material.rarity != .common {
                    Text(material.rarity.rawValue)
                        .font(.custom("Avenir-Heavy", size: 10))
                        .foregroundColor(Color(material.rarity.color))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color(material.rarity.color).opacity(0.2)))
                        .rarityShimmer(material.rarity)
                }
                
                Text(material.materialType.sourceDescription)
                    .font(.custom("Avenir-Medium", size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color("CardBackground"))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(material.materialType.color).opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Item Detail View

struct ItemDetailView: View {
    let item: Equipment
    let character: PlayerCharacter?
    let onEquip: () -> Void
    let onUnequip: () -> Void
    let onDiscard: () -> Void
    var onDismantle: (() -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss
    @State private var showDiscardConfirm = false
    @State private var showDismantleConfirm = false
    
    private var canEquip: Bool {
        guard let character = character else { return false }
        return character.level >= item.levelRequirement && !item.isEquipped
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundTop").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Item Icon
                        ZStack {
                            Circle()
                                .fill(Color(item.rarity.color).opacity(0.2))
                                .frame(width: 100, height: 100)
                            EquipmentIconView(item: item, slot: item.slot, size: 100)
                        }
                        
                        // Name and Rarity
                        VStack(spacing: 8) {
                            Text(item.name)
                                .font(.custom("Avenir-Heavy", size: 24))
                                .foregroundColor(Color(item.rarity.color))
                            
                            HStack(spacing: 8) {
                                Text(item.rarity.rawValue)
                                    .font(.custom("Avenir-Heavy", size: 14))
                                    .foregroundColor(Color(item.rarity.color))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color(item.rarity.color).opacity(0.2)))
                                    .rarityShimmer(item.rarity)
                                
                                Text(item.slot.rawValue)
                                    .font(.custom("Avenir-Medium", size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Description
                        Text(item.itemDescription)
                            .font(.custom("Avenir-Medium", size: 15))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Stats Card
                        VStack(spacing: 16) {
                            Text("Stats")
                                .font(.custom("Avenir-Heavy", size: 16))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Primary Stat
                            HStack {
                                Image(systemName: item.primaryStat.icon)
                                    .foregroundColor(Color(item.primaryStat.color))
                                Text(item.primaryStat.rawValue)
                                    .font(.custom("Avenir-Medium", size: 14))
                                Spacer()
                                Text("+\(item.statBonus)")
                                    .font(.custom("Avenir-Heavy", size: 20))
                                    .foregroundColor(Color("AccentGreen"))
                            }
                            
                            // Secondary Stat
                            if let secondary = item.secondaryStat, item.secondaryStatBonus > 0 {
                                HStack {
                                    Image(systemName: secondary.icon)
                                        .foregroundColor(Color(secondary.color))
                                    Text(secondary.rawValue)
                                        .font(.custom("Avenir-Medium", size: 14))
                                    Spacer()
                                    Text("+\(item.secondaryStatBonus)")
                                        .font(.custom("Avenir-Heavy", size: 20))
                                        .foregroundColor(Color("AccentGreen"))
                                }
                            }
                            
                            // Affixes
                            if item.hasAffixes {
                                Divider()
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Affixes")
                                        .font(.custom("Avenir-Heavy", size: 14))
                                        .foregroundColor(Color("AccentPurple"))
                                    
                                    if let pfx = item.prefix {
                                        HStack(spacing: 8) {
                                            Image(systemName: "sparkle")
                                                .font(.system(size: 12))
                                                .foregroundColor(Color("AccentPurple"))
                                            VStack(alignment: .leading, spacing: 2) {
                                                HStack(spacing: 4) {
                                                    Text(pfx.name)
                                                        .font(.custom("Avenir-Heavy", size: 13))
                                                        .foregroundColor(pfx.isGreater ? Color("AccentGold") : Color("AccentPurple"))
                                                    if pfx.isGreater {
                                                        Text("GREATER")
                                                            .font(.custom("Avenir-Heavy", size: 9))
                                                            .foregroundColor(Color("AccentGold"))
                                                            .padding(.horizontal, 4)
                                                            .padding(.vertical, 1)
                                                            .background(Capsule().fill(Color("AccentGold").opacity(0.2)))
                                                    }
                                                }
                                                Text(pfx.displayText)
                                                    .font(.custom("Avenir-Medium", size: 12))
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                        }
                                    }
                                    
                                    if let sfx = item.suffix {
                                        HStack(spacing: 8) {
                                            Image(systemName: "sparkle")
                                                .font(.system(size: 12))
                                                .foregroundColor(Color("AccentPurple"))
                                            VStack(alignment: .leading, spacing: 2) {
                                                HStack(spacing: 4) {
                                                    Text(sfx.name)
                                                        .font(.custom("Avenir-Heavy", size: 13))
                                                        .foregroundColor(sfx.isGreater ? Color("AccentGold") : Color("AccentPurple"))
                                                    if sfx.isGreater {
                                                        Text("GREATER")
                                                            .font(.custom("Avenir-Heavy", size: 9))
                                                            .foregroundColor(Color("AccentGold"))
                                                            .padding(.horizontal, 4)
                                                            .padding(.vertical, 1)
                                                            .background(Capsule().fill(Color("AccentGold").opacity(0.2)))
                                                    }
                                                }
                                                Text(sfx.displayText)
                                                    .font(.custom("Avenir-Medium", size: 12))
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                        }
                                    }
                                }
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Level Required")
                                    .font(.custom("Avenir-Medium", size: 14))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(item.levelRequirement)")
                                    .font(.custom("Avenir-Heavy", size: 16))
                                    .foregroundColor(
                                        (character?.level ?? 0) >= item.levelRequirement ?
                                        Color("AccentGreen") : .red
                                    )
                            }
                        }
                        .padding(20)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color("CardBackground")))
                        .padding(.horizontal)
                        
                        // Comparison vs Equipped
                        if !item.isEquipped, let character = character {
                            EquipmentComparisonCard(item: item, character: character)
                                .padding(.horizontal)
                        }
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            if item.isEquipped {
                                Button(action: onUnequip) {
                                    Text("Unequip")
                                        .font(.custom("Avenir-Heavy", size: 16))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Color.secondary)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            } else if canEquip {
                                Button(action: onEquip) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("Equip")
                                    }
                                    .font(.custom("Avenir-Heavy", size: 16))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        LinearGradient(colors: [Color("AccentGold"), Color("AccentOrange")], startPoint: .leading, endPoint: .trailing)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            
                            if let onDismantle = onDismantle {
                                Button(action: { showDismantleConfirm = true }) {
                                    HStack {
                                        Image(systemName: "hammer.fill")
                                        Text("Dismantle for Fragments")
                                    }
                                    .font(.custom("Avenir-Heavy", size: 14))
                                    .foregroundColor(Color("ForgeEmber"))
                                }
                                .alert("Dismantle Item?", isPresented: $showDismantleConfirm) {
                                    Button("Cancel", role: .cancel) {}
                                    Button("Dismantle") { onDismantle() }
                                } message: {
                                    Text("Break down \(item.name) into crafting fragments. This cannot be undone.")
                                }
                            }
                            
                            Button(action: { showDiscardConfirm = true }) {
                                Text("Discard")
                                    .font(.custom("Avenir-Heavy", size: 14))
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Color("AccentGold"))
                }
            }
            .alert("Discard Item?", isPresented: $showDiscardConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Discard", role: .destructive) { onDiscard() }
            } message: {
                Text("This will permanently destroy \(item.name). This cannot be undone.")
            }
        }
    }
}

// MARK: - Equipment Icon View

/// Displays an equipment item's pixel-art image if available, falling back to SF Symbol.
struct EquipmentIconView: View {
    let item: Equipment?
    let slot: EquipmentSlot
    let size: CGFloat
    
    init(item: Equipment?, slot: EquipmentSlot, size: CGFloat = 46) {
        self.item = item
        self.slot = slot
        self.size = size
    }
    
    var body: some View {
        if let imageName = item?.imageName, UIImage(named: imageName) != nil {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size * 0.8, height: size * 0.8)
        } else {
            Image(systemName: slot.icon)
                .font(.system(size: size * 0.45))
                .foregroundColor(item != nil ? Color(item!.rarity.color) : .secondary)
        }
    }
}

// MARK: - Equipment Comparison Card

struct EquipmentComparisonCard: View {
    let item: Equipment
    let character: PlayerCharacter
    
    /// The currently equipped item in the same slot
    private var equippedItem: Equipment? {
        character.equipment.item(for: item.slot)
    }
    
    /// Compute stat deltas for all active stat types
    private var statDeltas: [(statType: StatType, delta: Int)] {
        StatType.allCases.compactMap { stat in
            let newBonus = bonusFor(item: item, stat: stat)
            let oldBonus = bonusFor(item: equippedItem, stat: stat)
            let delta = newBonus - oldBonus
            guard delta != 0 else { return nil }
            return (stat, delta)
        }
    }
    
    /// Get stat bonus an item provides for a given stat type
    private func bonusFor(item: Equipment?, stat: StatType) -> Int {
        guard let item = item else { return 0 }
        var total = 0
        if item.primaryStat == stat { total += item.statBonus }
        if item.secondaryStat == stat { total += item.secondaryStatBonus }
        return total
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "arrow.left.arrow.right")
                    .foregroundColor(Color("AccentGold"))
                Text(equippedItem != nil ? "vs. Equipped" : "vs. Empty Slot")
                    .font(.custom("Avenir-Heavy", size: 16))
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
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            if statDeltas.isEmpty {
                Text("No stat difference")
                    .font(.custom("Avenir-Medium", size: 14))
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
                                .font(.custom("Avenir-Heavy", size: 16))
                        }
                        .foregroundColor(entry.delta > 0 ? Color("AccentGreen") : .red)
                    }
                }
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color("CardBackground")))
    }
}

#Preview {
    NavigationStack {
        InventoryView()
            .environmentObject(GameEngine())
    }
}
