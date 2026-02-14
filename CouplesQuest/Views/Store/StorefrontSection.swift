import SwiftUI
import SwiftData

/// The Storefront tab content: Deal of the Day, Milestone Gear, Class Sets, and Bundle Deals
struct StorefrontSection: View {
    let character: PlayerCharacter?
    let dealItem: Equipment?
    let onBuyDeal: () -> Void
    let onBuyMilestone: (MilestoneItem) -> Void
    let onBuySetPiece: (GearSetPiece) -> Void
    let onBuyBundle: (BundleDeal) -> Void
    let purchasedDealID: UUID?
    let purchasedMilestoneIDs: Set<String>
    let purchasedSetPieceIDs: Set<String>
    let purchasedBundleIDs: Set<String>
    
    var body: some View {
        VStack(spacing: 20) {
            dealOfTheDaySection
            milestoneGearSection
            classGearSetSection
            bundleDealsSection
        }
    }
    
    // MARK: - Deal of the Day
    
    private var dealOfTheDaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("Deal of the Day")
                    .font(.custom("Avenir-Heavy", size: 18))
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text(ShopGenerator.timeUntilRefresh)
                        .font(.custom("Avenir-Medium", size: 11))
                }
                .foregroundColor(.secondary)
            }
            
            if let item = dealItem {
                let originalPrice = ShopGenerator.priceForEquipment(item)
                let salePrice = ShopGenerator.dealPrice(for: item)
                let discount = ShopGenerator.dealDiscount()
                let isPurchased = purchasedDealID == item.id
                let canAfford = (character?.gold ?? 0) >= salePrice
                
                Button {
                    onBuyDeal()
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(item.rarity.color).opacity(0.2))
                                .frame(width: 56, height: 56)
                            Image(systemName: item.slot.icon)
                                .font(.title2)
                                .foregroundColor(Color(item.rarity.color))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name)
                                .font(.custom("Avenir-Heavy", size: 15))
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
                                Text("-\(discount)% OFF")
                                    .font(.custom("Avenir-Heavy", size: 10))
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.orange.opacity(0.2)))
                            }
                        }
                        
                        Spacer()
                        
                        if isPurchased {
                            Text("Sold")
                                .font(.custom("Avenir-Heavy", size: 13))
                                .foregroundColor(.secondary)
                        } else {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(originalPrice)")
                                    .font(.custom("Avenir-Medium", size: 11))
                                    .strikethrough()
                                    .foregroundColor(.secondary)
                                HStack(spacing: 4) {
                                    Image(systemName: "dollarsign.circle.fill")
                                        .foregroundColor(Color("AccentGold"))
                                        .font(.caption)
                                    Text("\(salePrice)")
                                        .font(.custom("Avenir-Heavy", size: 16))
                                        .foregroundColor(canAfford ? Color("AccentGold") : .red)
                                }
                            }
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color("CardBackground"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .opacity(isPurchased ? 0.6 : 1.0)
                }
                .buttonStyle(.plain)
                .disabled(isPurchased)
            } else {
                Text("No deal available today.")
                    .font(.custom("Avenir-Medium", size: 13))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }
        }
    }
    
    // MARK: - Milestone Gear
    
    private var milestoneGearSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.circle.fill")
                    .foregroundColor(Color("AccentGold"))
                Text("Milestone Gear")
                    .font(.custom("Avenir-Heavy", size: 18))
                Spacer()
            }
            
            Text("Class-exclusive gear that unlocks as you level up.")
                .font(.custom("Avenir-Medium", size: 12))
                .foregroundColor(.secondary)
            
            if let charClass = character?.characterClass {
                let items = MilestoneGearCatalog.items(for: charClass)
                
                ForEach(items) { item in
                    let isUnlocked = (character?.level ?? 1) >= item.levelRequirement
                    let isPurchased = purchasedMilestoneIDs.contains(item.id)
                    let canAfford = (character?.gold ?? 0) >= item.goldCost
                    
                    Button {
                        if isUnlocked && !isPurchased {
                            onBuyMilestone(item)
                        }
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isUnlocked ? Color(item.rarity.color).opacity(0.2) : Color.gray.opacity(0.1))
                                    .frame(width: 50, height: 50)
                                if isUnlocked {
                                    Image(systemName: item.slot.icon)
                                        .font(.title3)
                                        .foregroundColor(Color(item.rarity.color))
                                } else {
                                    Image(systemName: "lock.fill")
                                        .font(.title3)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.name)
                                    .font(.custom("Avenir-Heavy", size: 14))
                                    .foregroundColor(isUnlocked ? Color(item.rarity.color) : .gray)
                                if isUnlocked {
                                    Text("+\(item.statBonus) \(item.primaryStat.rawValue)" +
                                         (item.secondaryStat != nil ? ", +\(item.secondaryStatBonus) \(item.secondaryStat!.rawValue)" : ""))
                                        .font(.custom("Avenir-Medium", size: 12))
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Reach Lv.\(item.levelRequirement) to unlock")
                                        .font(.custom("Avenir-Medium", size: 12))
                                        .foregroundColor(.gray)
                                }
                                HStack(spacing: 6) {
                                    Text(item.rarity.rawValue)
                                        .font(.custom("Avenir-Heavy", size: 10))
                                        .foregroundColor(isUnlocked ? Color(item.rarity.color) : .gray)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill((isUnlocked ? Color(item.rarity.color) : .gray).opacity(0.2)))
                                        .rarityShimmer(item.rarity)
                                    Text("Lv.\(item.levelRequirement)")
                                        .font(.custom("Avenir-Medium", size: 10))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if isPurchased {
                                Text("Owned")
                                    .font(.custom("Avenir-Heavy", size: 13))
                                    .foregroundColor(.secondary)
                            } else if isUnlocked {
                                HStack(spacing: 4) {
                                    Image(systemName: "dollarsign.circle.fill")
                                        .foregroundColor(Color("AccentGold"))
                                        .font(.caption)
                                    Text("\(item.goldCost)")
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
                        .opacity(isPurchased ? 0.6 : (isUnlocked ? 1.0 : 0.5))
                    }
                    .buttonStyle(.plain)
                    .disabled(!isUnlocked || isPurchased)
                }
            } else {
                Text("Choose a class to see milestone gear.")
                    .font(.custom("Avenir-Medium", size: 13))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 12)
            }
        }
    }
    
    // MARK: - Class Gear Set
    
    private var classGearSetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "square.grid.3x3.fill")
                    .foregroundColor(Color("StoreTeal"))
                Text("Class Gear Set")
                    .font(.custom("Avenir-Heavy", size: 18))
                Spacer()
            }
            
            if let charClass = character?.characterClass,
               let gearSet = GearSetCatalog.gearSet(for: charClass) {
                
                VStack(alignment: .leading, spacing: 10) {
                    // Set header
                    HStack {
                        Text(gearSet.name)
                            .font(.custom("Avenir-Heavy", size: 16))
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundColor(Color("AccentGold"))
                            Text("Set Bonus: +\(gearSet.bonusAmount) \(gearSet.bonusStat.rawValue)")
                                .font(.custom("Avenir-Heavy", size: 11))
                                .foregroundColor(Color("AccentGold"))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color("AccentGold").opacity(0.15)))
                    }
                    
                    Text(gearSet.description)
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                    
                    // Set pieces
                    ForEach(gearSet.pieces) { piece in
                        let isPurchased = purchasedSetPieceIDs.contains(piece.id)
                        let canAfford = (character?.gold ?? 0) >= piece.goldCost
                        
                        Button {
                            if !isPurchased {
                                onBuySetPiece(piece)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(piece.rarity.color).opacity(0.2))
                                        .frame(width: 42, height: 42)
                                    if isPurchased {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title3)
                                            .foregroundColor(Color("AccentGreen"))
                                    } else {
                                        Image(systemName: piece.slot.icon)
                                            .font(.callout)
                                            .foregroundColor(Color(piece.rarity.color))
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(piece.name)
                                        .font(.custom("Avenir-Heavy", size: 13))
                                        .foregroundColor(Color(piece.rarity.color))
                                    Text("+\(piece.statBonus) \(piece.primaryStat.rawValue)" +
                                         (piece.secondaryStat != nil ? ", +\(piece.secondaryStatBonus) \(piece.secondaryStat!.rawValue)" : ""))
                                        .font(.custom("Avenir-Medium", size: 11))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if isPurchased {
                                    Text("Owned")
                                        .font(.custom("Avenir-Heavy", size: 12))
                                        .foregroundColor(Color("AccentGreen"))
                                } else {
                                    HStack(spacing: 3) {
                                        Image(systemName: "dollarsign.circle.fill")
                                            .foregroundColor(Color("AccentGold"))
                                            .font(.caption2)
                                        Text("\(piece.goldCost)")
                                            .font(.custom("Avenir-Heavy", size: 14))
                                            .foregroundColor(canAfford ? Color("AccentGold") : .red)
                                    }
                                }
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color("CardBackground").opacity(0.6))
                            )
                            .opacity(isPurchased ? 0.7 : 1.0)
                        }
                        .buttonStyle(.plain)
                        .disabled(isPurchased)
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color("CardBackground"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color("StoreTeal").opacity(0.3), lineWidth: 1)
                        )
                )
            } else {
                Text("Choose a class to see your gear set.")
                    .font(.custom("Avenir-Medium", size: 13))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 12)
            }
        }
    }
    
    // MARK: - Bundle Deals
    
    private var bundleDealsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "gift.fill")
                    .foregroundColor(Color("AccentPurple"))
                Text("Bundle Deals")
                    .font(.custom("Avenir-Heavy", size: 18))
                Spacer()
            }
            
            Text("Curated packs at a discount. More bang for your gold!")
                .font(.custom("Avenir-Medium", size: 12))
                .foregroundColor(.secondary)
            
            let bundles = BundleCatalog.availableBundles(level: character?.level ?? 1)
            
            ForEach(bundles) { bundle in
                let isPurchased = purchasedBundleIDs.contains(bundle.id)
                let isGemBundle = bundle.gemCost > 0
                let canAfford = isGemBundle
                    ? (character?.gems ?? 0) >= bundle.gemCost
                    : (character?.gold ?? 0) >= bundle.goldCost
                
                Button {
                    if !isPurchased {
                        onBuyBundle(bundle)
                    }
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isGemBundle ? Color("AccentPurple").opacity(0.2) : Color("AccentGold").opacity(0.2))
                                .frame(width: 50, height: 50)
                            Image(systemName: bundle.icon)
                                .font(.title3)
                                .foregroundColor(isGemBundle ? Color("AccentPurple") : Color("AccentGold"))
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(bundle.name)
                                .font(.custom("Avenir-Heavy", size: 14))
                            Text(bundle.description)
                                .font(.custom("Avenir-Medium", size: 11))
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                            HStack(spacing: 6) {
                                Text("\(bundle.itemCount) items")
                                    .font(.custom("Avenir-Medium", size: 10))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.secondary.opacity(0.15)))
                                if bundle.savingsPercent > 0 {
                                    Text("Save \(bundle.savingsPercent)%")
                                        .font(.custom("Avenir-Heavy", size: 10))
                                        .foregroundColor(Color("AccentGreen"))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(Color("AccentGreen").opacity(0.15)))
                                }
                            }
                        }
                        
                        Spacer()
                        
                        if isPurchased {
                            Text("Purchased")
                                .font(.custom("Avenir-Heavy", size: 12))
                                .foregroundColor(.secondary)
                        } else {
                            HStack(spacing: 3) {
                                if isGemBundle {
                                    Image(systemName: "diamond.fill")
                                        .foregroundColor(Color("AccentPurple"))
                                        .font(.caption2)
                                    Text("\(bundle.gemCost)")
                                        .font(.custom("Avenir-Heavy", size: 15))
                                        .foregroundColor(canAfford ? Color("AccentPurple") : .red)
                                } else {
                                    Image(systemName: "dollarsign.circle.fill")
                                        .foregroundColor(Color("AccentGold"))
                                        .font(.caption2)
                                    Text("\(bundle.goldCost)")
                                        .font(.custom("Avenir-Heavy", size: 15))
                                        .foregroundColor(canAfford ? Color("AccentGold") : .red)
                                }
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
    }
}
