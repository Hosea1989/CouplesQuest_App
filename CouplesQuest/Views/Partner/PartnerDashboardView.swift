import SwiftUI
import SwiftData

/// The connected-state dashboard showing partner info, bond level, and quick actions
struct PartnerDashboardView: View {
    let character: PlayerCharacter
    let bond: Bond
    let onAssignTask: () -> Void
    let onSendNudge: () -> Void
    let onSendKudos: () -> Void
    let onSendChallenge: () -> Void
    let onViewLeaderboard: () -> Void
    let onUnlinkPartner: () -> Void
    
    @State private var showUnlinkConfirm = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Connection Header
            connectionHeader
            
            // Bond Level Card
            bondLevelCard
            
            // Quick Actions Grid
            quickActionsGrid
            
            // Recent Activity / Stats
            partnerStatsCard
            
            // Bond Perks
            bondPerksCard
            
            // Unlink button
            unlinkButton
        }
    }
    
    // MARK: - Connection Header
    
    private var connectionHeader: some View {
        VStack(spacing: 16) {
            // Avatars with connection line
            HStack(spacing: 16) {
                // Your avatar
                VStack(spacing: 6) {
                    ZStack {
                        if let imageData = character.avatarImageData,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 70, height: 70)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color("AccentGold").opacity(0.2))
                                .frame(width: 70, height: 70)
                            
                            Image(systemName: character.avatarIcon)
                                .font(.title)
                                .foregroundColor(Color("AccentGold"))
                        }
                    }
                    
                    Text(character.name)
                        .font(.custom("Avenir-Heavy", size: 13))
                        .lineLimit(1)
                    
                    Text("Lv.\(character.level)")
                        .font(.custom("Avenir-Medium", size: 11))
                        .foregroundColor(Color("AccentGold"))
                }
                .frame(width: 90)
                
                // Connection line with heart
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color("AccentGreen"))
                            .frame(width: 6, height: 6)
                        
                        Rectangle()
                            .fill(Color("AccentGreen"))
                            .frame(height: 2)
                        
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundColor(Color("AccentPink"))
                        
                        Rectangle()
                            .fill(Color("AccentGreen"))
                            .frame(height: 2)
                        
                        Circle()
                            .fill(Color("AccentGreen"))
                            .frame(width: 6, height: 6)
                    }
                    .frame(maxWidth: 80)
                    
                    Text("Connected")
                        .font(.custom("Avenir-Heavy", size: 10))
                        .foregroundColor(Color("AccentGreen"))
                }
                
                // Partner avatar
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(Color("AccentPurple").opacity(0.2))
                            .frame(width: 70, height: 70)
                        
                        Image(systemName: "person.fill")
                            .font(.title)
                            .foregroundColor(Color("AccentPurple"))
                    }
                    
                    Text(character.partnerName ?? "Partner")
                        .font(.custom("Avenir-Heavy", size: 13))
                        .lineLimit(1)
                    
                    if let partnerLevel = character.partnerLevel {
                        Text("Lv.\(partnerLevel)")
                            .font(.custom("Avenir-Medium", size: 11))
                            .foregroundColor(Color("AccentPurple"))
                    }
                }
                .frame(width: 90)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
    }
    
    // MARK: - Bond Level Card
    
    private var bondLevelCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "heart.circle.fill")
                    .foregroundColor(Color("AccentPink"))
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Bond Level \(bond.bondLevel)")
                        .font(.custom("Avenir-Heavy", size: 16))
                    Text(bond.bondTitle)
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(Color("AccentPink"))
                }
                
                Spacer()
                
                // Bond level badge
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color("AccentPink"), Color("AccentPurple")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Text("\(bond.bondLevel)")
                        .font(.custom("Avenir-Heavy", size: 18))
                        .foregroundColor(.white)
                }
            }
            
            // Bond EXP Progress Bar
            VStack(spacing: 6) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.2))
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [Color("AccentPink"), Color("AccentPurple")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * bond.levelProgress)
                    }
                }
                .frame(height: 8)
                
                HStack {
                    Text("\(bond.bondEXP) / \(bond.expToNextLevel) Bond EXP")
                        .font(.custom("Avenir-Medium", size: 11))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let nextPerk = bond.nextPerk {
                        Text("Next: \(nextPerk.rawValue) (Lv.\(nextPerk.requiredLevel))")
                            .font(.custom("Avenir-Medium", size: 11))
                            .foregroundColor(Color("AccentPink"))
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // MARK: - Quick Actions Grid
    
    private var quickActionsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.custom("Avenir-Heavy", size: 16))
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                PartnerActionButton(
                    icon: "plus.circle.fill",
                    label: "Assign Task",
                    color: Color("AccentGold"),
                    action: onAssignTask
                )
                
                PartnerActionButton(
                    icon: "hand.thumbsup.fill",
                    label: "Send Kudos",
                    color: Color("AccentGreen"),
                    action: onSendKudos
                )
                
                PartnerActionButton(
                    icon: "bell.fill",
                    label: "Send Nudge",
                    color: Color("AccentPurple"),
                    action: onSendNudge
                )
                
                PartnerActionButton(
                    icon: "flag.fill",
                    label: "Challenge",
                    color: Color("AccentOrange"),
                    action: onSendChallenge
                )
            }
            
            // Leaderboard button
            Button(action: onViewLeaderboard) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                    Text("View Leaderboard")
                        .font(.custom("Avenir-Heavy", size: 14))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundColor(Color("AccentGold"))
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("AccentGold").opacity(0.1))
                )
            }
        }
    }
    
    // MARK: - Partner Stats Card
    
    private var partnerStatsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bond Stats")
                .font(.custom("Avenir-Heavy", size: 16))
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                BondStatBadge(
                    icon: "paperplane.fill",
                    value: "\(bond.partnerTasksCompleted)",
                    label: "Partner Tasks",
                    color: Color("AccentGold")
                )
                
                BondStatBadge(
                    icon: "rectangle.on.rectangle",
                    value: "\(bond.dutyBoardTasksClaimed)",
                    label: "Board Claims",
                    color: Color("AccentPurple")
                )
                
                BondStatBadge(
                    icon: "hand.thumbsup.fill",
                    value: "\(bond.kudosSent)",
                    label: "Kudos Sent",
                    color: Color("AccentGreen")
                )
            }
            
            // Relationship duration
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.secondary)
                Text("Partners for \(daysSincePaired) days")
                    .font(.custom("Avenir-Medium", size: 13))
                    .foregroundColor(.secondary)
                Spacer()
                Text("Total Bond EXP: \(bond.totalBondEXP)")
                    .font(.custom("Avenir-Medium", size: 13))
                    .foregroundColor(Color("AccentPink"))
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
    }
    
    private var daysSincePaired: Int {
        let days = Calendar.current.dateComponents([.day], from: bond.createdAt, to: Date()).day ?? 0
        return max(1, days)
    }
    
    // MARK: - Bond Perks Card
    
    private var bondPerksCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bond Perks")
                .font(.custom("Avenir-Heavy", size: 16))
            
            ForEach(BondPerk.allCases, id: \.self) { perk in
                HStack(spacing: 12) {
                    Image(systemName: perk.icon)
                        .foregroundColor(perk.requiredLevel <= bond.bondLevel ? Color("AccentGold") : .secondary.opacity(0.4))
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(perk.rawValue)
                            .font(.custom("Avenir-Heavy", size: 14))
                            .foregroundColor(perk.requiredLevel <= bond.bondLevel ? .primary : .secondary.opacity(0.5))
                        Text(perk.description)
                            .font(.custom("Avenir-Medium", size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if perk.requiredLevel <= bond.bondLevel {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color("AccentGreen"))
                    } else {
                        Text("Lv.\(perk.requiredLevel)")
                            .font(.custom("Avenir-Heavy", size: 12))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                }
                
                if perk != BondPerk.allCases.last {
                    Divider()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
    }
    
    // MARK: - Unlink Button
    
    private var unlinkButton: some View {
        Button(action: { showUnlinkConfirm = true }) {
            HStack {
                Image(systemName: "link.badge.plus")
                    .rotationEffect(.degrees(45))
                Text("Unlink Partner")
            }
            .font(.custom("Avenir-Medium", size: 14))
            .foregroundColor(.red.opacity(0.7))
            .padding(.vertical, 12)
        }
        .confirmationDialog(
            "Unlink Partner?",
            isPresented: $showUnlinkConfirm,
            titleVisibility: .visible
        ) {
            Button("Unlink", role: .destructive) {
                onUnlinkPartner()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will disconnect you from your partner. Your bond progress will be preserved if you reconnect.")
        }
    }
}

// MARK: - Partner Action Button

struct PartnerActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(label)
                    .font(.custom("Avenir-Medium", size: 12))
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.12))
            )
        }
    }
}

// MARK: - Bond Stat Badge

struct BondStatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundColor(color)
            
            Text(value)
                .font(.custom("Avenir-Heavy", size: 18))
            
            Text(label)
                .font(.custom("Avenir-Medium", size: 10))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.08))
        )
    }
}

#Preview {
    let character = PlayerCharacter(name: "Hero")
    let bond = Bond(partnerID: UUID())
    
    ScrollView {
        PartnerDashboardView(
            character: character,
            bond: bond,
            onAssignTask: {},
            onSendNudge: {},
            onSendKudos: {},
            onSendChallenge: {},
            onViewLeaderboard: {},
            onUnlinkPartner: {}
        )
        .padding()
    }
    .background(Color("BackgroundTop"))
}
