import SwiftUI

// MARK: - Memory Match Reward Tiers

struct MemoryMatchRewardTier {
    let name: String
    let icon: String
    let color: String
    let gold: Int
    let consumableName: String
    let consumableIcon: String
    let consumableCount: Int
    let wisdomBonus: Int
    
    static func tier(for elapsedSeconds: Int) -> MemoryMatchRewardTier {
        let minutes = elapsedSeconds / 60
        switch minutes {
        case ..<1:
            return MemoryMatchRewardTier(
                name: "Perfect Recall",
                icon: "bolt.fill",
                color: "AccentGold",
                gold: 200,
                consumableName: "Memory Tonic",
                consumableIcon: "brain.head.profile.fill",
                consumableCount: 3,
                wisdomBonus: 2
            )
        case 1..<2:
            return MemoryMatchRewardTier(
                name: "Sharp Memory",
                icon: "sparkles",
                color: "AccentGreen",
                gold: 150,
                consumableName: "Green Tea",
                consumableIcon: "leaf.fill",
                consumableCount: 2,
                wisdomBonus: 1
            )
        case 2..<3:
            return MemoryMatchRewardTier(
                name: "Steady Recall",
                icon: "checkmark.seal.fill",
                color: "AccentOrange",
                gold: 100,
                consumableName: "Apple Juice",
                consumableIcon: "cup.and.saucer.fill",
                consumableCount: 1,
                wisdomBonus: 1
            )
        default:
            return MemoryMatchRewardTier(
                name: "Completed",
                icon: "checkmark.circle.fill",
                color: "StatWisdom",
                gold: 50,
                consumableName: "Apple Juice",
                consumableIcon: "cup.and.saucer.fill",
                consumableCount: 0,
                wisdomBonus: 1
            )
        }
    }
    
    static let allTiers: [(label: String, threshold: String, gold: Int, loot: String)] = [
        ("Perfect Recall", "< 1 min", 200, "3× Memory Tonic"),
        ("Sharp Memory", "1–2 min", 150, "2× Green Tea"),
        ("Steady Recall", "2–3 min", 100, "1× Apple Juice"),
        ("Completed", "> 3 min", 50, "—"),
    ]
}

// MARK: - Card Model

private struct MemoryCard: Identifiable {
    let id: Int
    let symbol: String
    let symbolColor: Color
    var isFaceUp: Bool = false
    var isMatched: Bool = false
}

// MARK: - Timer View

private struct MemoryTimerView: View {
    @Binding var elapsedSeconds: Int
    let isStopped: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock")
                .foregroundColor(isStopped ? .secondary : Color("AccentGold"))
            Text(formatted)
                .font(.custom("Avenir-Heavy", size: 16))
                .monospacedDigit()
                .foregroundColor(isStopped ? .secondary : .primary)
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if !isStopped {
                elapsedSeconds += 1
            }
        }
    }
    
    var formatted: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Memory Match Game View

struct MemoryMatchGameView: View {
    let onComplete: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    
    // Card symbols — 8 RPG-themed pairs
    private static let symbolPool: [(String, Color)] = [
        ("shield.fill", Color("AccentGold")),
        ("wand.and.stars", Color("AccentPurple")),
        ("flame.fill", Color("AccentOrange")),
        ("leaf.fill", Color("AccentGreen")),
        ("bolt.fill", Color.yellow),
        ("heart.fill", Color("AccentPink")),
        ("star.fill", Color("AccentGold")),
        ("crown.fill", Color.yellow),
    ]
    
    @State private var cards: [MemoryCard] = []
    @State private var firstFlippedIndex: Int?
    @State private var secondFlippedIndex: Int?
    @State private var mistakeCount = 0
    @State private var matchedPairs = 0
    @State private var elapsedSeconds = 0
    @State private var isSolved = false
    @State private var isGameOver = false
    @State private var showOverlay = false
    @State private var isProcessing = false // prevents tapping during flip animation
    @State private var isPreviewPhase = true // show cards briefly at start
    
    private let maxMistakes = 8
    private let totalPairs = 8
    private var isEnded: Bool { isSolved || isGameOver }
    
    private var rewardTier: MemoryMatchRewardTier {
        MemoryMatchRewardTier.tier(for: elapsedSeconds)
    }
    
    init(onComplete: @escaping (Int) -> Void) {
        self.onComplete = onComplete
        // Build and shuffle cards — start face-up for preview phase
        var deck: [MemoryCard] = []
        for (i, sym) in Self.symbolPool.enumerated() {
            deck.append(MemoryCard(id: i * 2, symbol: sym.0, symbolColor: sym.1, isFaceUp: true))
            deck.append(MemoryCard(id: i * 2 + 1, symbol: sym.0, symbolColor: sym.1, isFaceUp: true))
        }
        deck.shuffle()
        _cards = State(initialValue: deck)
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
                
                VStack(spacing: 16) {
                    // Timer + mistakes
                    HStack {
                        MemoryTimerView(elapsedSeconds: $elapsedSeconds, isStopped: isEnded || isPreviewPhase)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Text("Pairs: \(matchedPairs)/\(totalPairs)")
                                .font(.custom("Avenir-Heavy", size: 14))
                                .foregroundColor(Color("AccentGold"))
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle")
                                .foregroundColor(mistakeCount >= maxMistakes ? .red : Color("AccentOrange"))
                            Text("\(mistakeCount)/\(maxMistakes)")
                                .font(.custom("Avenir-Medium", size: 14))
                                .foregroundColor(mistakeCount >= maxMistakes ? .red : .secondary)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Preview phase banner
                    if isPreviewPhase {
                        HStack(spacing: 8) {
                            Image(systemName: "eye.fill")
                                .foregroundColor(Color("AccentGold"))
                            Text("Memorize the cards!")
                                .font(.custom("Avenir-Heavy", size: 16))
                                .foregroundColor(Color("AccentGold"))
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color("AccentGold").opacity(0.12))
                        )
                        .transition(.opacity)
                    }
                    
                    // 4x4 Card Grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                        ForEach(cards.indices, id: \.self) { index in
                            CardView(
                                card: cards[index],
                                onTap: { tapCard(at: index) }
                            )
                            .aspectRatio(0.7, contentMode: .fit)
                        }
                    }
                    .padding(.horizontal)
                    .opacity(isGameOver ? 0.4 : 1.0)
                    
                    Spacer()
                }
                .padding(.top, 8)
                .onAppear {
                    // After 2 seconds, flip all cards face-down and begin the game
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            for index in cards.indices {
                                cards[index].isFaceUp = false
                            }
                            isPreviewPhase = false
                        }
                    }
                }
                
                // Overlay
                if showOverlay {
                    if isSolved {
                        celebrationOverlay
                    } else if isGameOver {
                        gameOverOverlay
                    }
                }
            }
            .navigationTitle("Memory Match")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Color("AccentGold"))
                }
            }
        }
    }
    
    // MARK: - Card Tap Logic
    
    private func tapCard(at index: Int) {
        guard !isEnded, !isProcessing, !isPreviewPhase else { return }
        guard !cards[index].isFaceUp, !cards[index].isMatched else { return }
        
        // Flip the card face up
        withAnimation(.easeInOut(duration: 0.3)) {
            cards[index].isFaceUp = true
        }
        
        if firstFlippedIndex == nil {
            // First card of the pair
            firstFlippedIndex = index
        } else if secondFlippedIndex == nil {
            // Second card of the pair
            secondFlippedIndex = index
            isProcessing = true
            
            let first = firstFlippedIndex!
            let second = index
            
            if cards[first].symbol == cards[second].symbol {
                // Match found
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        cards[first].isMatched = true
                        cards[second].isMatched = true
                    }
                    matchedPairs += 1
                    AudioManager.shared.play(.claimReward)
                    resetSelection()
                    
                    if matchedPairs == totalPairs {
                        triggerWin()
                    }
                }
            } else {
                // No match — flip back
                mistakeCount += 1
                AudioManager.shared.play(.mismatch)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        cards[first].isFaceUp = false
                        cards[second].isFaceUp = false
                    }
                    resetSelection()
                    
                    if mistakeCount >= maxMistakes {
                        triggerGameOver()
                    }
                }
            }
        }
    }
    
    private func resetSelection() {
        firstFlippedIndex = nil
        secondFlippedIndex = nil
        isProcessing = false
    }
    
    private func triggerWin() {
        isSolved = true
        AudioManager.shared.play(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showOverlay = true
            }
        }
    }
    
    private func triggerGameOver() {
        isGameOver = true
        AudioManager.shared.play(.error)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showOverlay = true
        }
    }
    
    // MARK: - Time Formatted
    
    private var timeFormatted: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%d:%02d", m, s)
    }
    
    // MARK: - Celebration Overlay
    
    private var celebrationOverlay: some View {
        let tier = rewardTier
        
        return ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            
            VStack(spacing: 16) {
                Image(systemName: tier.icon)
                    .font(.system(size: 56))
                    .foregroundColor(Color(tier.color))
                    .shadow(color: Color(tier.color).opacity(0.5), radius: 12)
                
                Text(tier.name)
                    .font(.custom("Avenir-Heavy", size: 26))
                
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("Time")
                            .font(.custom("Avenir-Medium", size: 12))
                            .foregroundColor(.secondary)
                        Text(timeFormatted)
                            .font(.custom("Avenir-Heavy", size: 18))
                            .monospacedDigit()
                            .foregroundColor(Color(tier.color))
                    }
                    VStack(spacing: 4) {
                        Text("Mistakes")
                            .font(.custom("Avenir-Medium", size: 12))
                            .foregroundColor(.secondary)
                        Text("\(mistakeCount)")
                            .font(.custom("Avenir-Heavy", size: 18))
                            .foregroundColor(mistakeCount == 0 ? Color("AccentGreen") : Color("AccentOrange"))
                    }
                }
                
                VStack(spacing: 10) {
                    Text("REWARDS")
                        .font(.custom("Avenir-Heavy", size: 11))
                        .foregroundColor(.secondary)
                        .tracking(1.5)
                    
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(Color("AccentGold"))
                        Text("Gold")
                            .font(.custom("Avenir-Medium", size: 15))
                        Spacer()
                        Text("+\(tier.gold)")
                            .font(.custom("Avenir-Heavy", size: 17))
                            .foregroundColor(Color("AccentGold"))
                    }
                    
                    if tier.consumableCount > 0 {
                        HStack {
                            Image(systemName: tier.consumableIcon)
                                .foregroundColor(Color("AccentGreen"))
                            Text(tier.consumableName)
                                .font(.custom("Avenir-Medium", size: 15))
                            Spacer()
                            Text("×\(tier.consumableCount)")
                                .font(.custom("Avenir-Heavy", size: 17))
                                .foregroundColor(Color("AccentGreen"))
                        }
                    }
                    
                    HStack {
                        Image(systemName: StatType.luck.icon)
                            .foregroundColor(Color(StatType.luck.color))
                        Text("Luck")
                            .font(.custom("Avenir-Medium", size: 15))
                        Spacer()
                        Text("+\(tier.wisdomBonus)")
                            .font(.custom("Avenir-Heavy", size: 17))
                            .foregroundColor(Color(StatType.luck.color))
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(tier.color).opacity(0.08))
                )
                
                Button {
                    onComplete(elapsedSeconds)
                    dismiss()
                } label: {
                    Text("Claim Rewards")
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(tier.color))
                        )
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color("CardBackground"))
            )
            .padding(.horizontal, 28)
            .transition(.scale.combined(with: .opacity))
        }
    }
    
    // MARK: - Game Over Overlay
    
    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "xmark.octagon.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.red)
                    .shadow(color: .red.opacity(0.4), radius: 12)
                
                Text("Game Over")
                    .font(.custom("Avenir-Heavy", size: 28))
                    .foregroundColor(.red)
                
                Text("Too many wrong guesses!\nBetter luck next time!")
                    .font(.custom("Avenir-Medium", size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button {
                    dismiss()
                } label: {
                    Text("Close")
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.red.opacity(0.8))
                        )
                }
                .padding(.horizontal, 40)
                .padding(.top, 8)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color("CardBackground"))
            )
            .padding(.horizontal, 32)
            .transition(.scale.combined(with: .opacity))
        }
    }
}

// MARK: - Individual Card View

private struct CardView: View {
    let card: MemoryCard
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                if card.isFaceUp || card.isMatched {
                    // Face up
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("CardBackground"))
                    
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(card.isMatched ? Color("AccentGreen").opacity(0.6) : Color("AccentGold").opacity(0.3), lineWidth: 2)
                    
                    Image(systemName: card.symbol)
                        .font(.system(size: 28))
                        .foregroundColor(card.isMatched ? card.symbolColor.opacity(0.5) : card.symbolColor)
                } else {
                    // Face down
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color("AccentGold").opacity(0.2), Color("AccentGold").opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color("AccentGold").opacity(0.3), lineWidth: 1.5)
                    
                    Image(systemName: "questionmark")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color("AccentGold").opacity(0.4))
                }
            }
            .opacity(card.isMatched ? 0.5 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(card.isFaceUp || card.isMatched)
        .rotation3DEffect(
            .degrees(card.isFaceUp || card.isMatched ? 0 : 180),
            axis: (x: 0, y: 1, z: 0)
        )
        .animation(.easeInOut(duration: 0.3), value: card.isFaceUp)
    }
}
