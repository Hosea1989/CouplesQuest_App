import SwiftUI

// MARK: - 2048 Reward Tiers

struct Game2048RewardTier {
    let name: String
    let icon: String
    let color: String
    let gold: Int
    let consumableName: String
    let consumableIcon: String
    let consumableCount: Int
    let wisdomBonus: Int
    
    /// Determine tier based on highest tile reached
    static func tier(for highestTile: Int) -> Game2048RewardTier {
        switch highestTile {
        case 2048...:
            return Game2048RewardTier(
                name: "Legendary Mind",
                icon: "bolt.fill",
                color: "AccentGold",
                gold: 250,
                consumableName: "Ancient Tome",
                consumableIcon: "book.closed.fill",
                consumableCount: 3,
                wisdomBonus: 3
            )
        case 1024..<2048:
            return Game2048RewardTier(
                name: "Strategic Genius",
                icon: "sparkles",
                color: "AccentGreen",
                gold: 175,
                consumableName: "Focus Scroll",
                consumableIcon: "scroll.fill",
                consumableCount: 2,
                wisdomBonus: 2
            )
        case 512..<1024:
            return Game2048RewardTier(
                name: "Sharp Planner",
                icon: "checkmark.seal.fill",
                color: "AccentOrange",
                gold: 100,
                consumableName: "Green Tea",
                consumableIcon: "leaf.fill",
                consumableCount: 1,
                wisdomBonus: 1
            )
        default:
            return Game2048RewardTier(
                name: "Good Effort",
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
        ("Legendary Mind", "Reach 2048", 250, "3× Ancient Tome"),
        ("Strategic Genius", "Reach 1024", 175, "2× Focus Scroll"),
        ("Sharp Planner", "Reach 512", 100, "1× Green Tea"),
        ("Good Effort", "Below 512", 50, "—"),
    ]
}

// MARK: - Tile Model

private struct Tile: Identifiable, Equatable {
    let id: UUID
    var value: Int
    var row: Int
    var col: Int
    var isNew: Bool = false
    var isMerged: Bool = false
}

// MARK: - Move Direction

private enum MoveDirection {
    case up, down, left, right
}

// MARK: - Timer View

private struct Game2048TimerView: View {
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

// MARK: - Game 2048 View

struct Game2048View: View {
    let onComplete: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    
    private let gridSize = 4
    
    @State private var tiles: [Tile] = []
    @State private var score = 0
    @State private var highestTile = 2
    @State private var elapsedSeconds = 0
    @State private var isGameOver = false
    @State private var hasWon = false
    @State private var showOverlay = false
    @State private var keepPlaying = false
    
    private var isEnded: Bool { isGameOver || (hasWon && !keepPlaying) }
    
    private var rewardTier: Game2048RewardTier {
        Game2048RewardTier.tier(for: highestTile)
    }
    
    init(onComplete: @escaping (Int) -> Void) {
        self.onComplete = onComplete
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
                    // Header
                    HStack {
                        Game2048TimerView(elapsedSeconds: $elapsedSeconds, isStopped: isEnded)
                        
                        Spacer()
                        
                        // Score
                        VStack(spacing: 2) {
                            Text("SCORE")
                                .font(.custom("Avenir-Medium", size: 10))
                                .foregroundColor(.secondary)
                            Text("\(score)")
                                .font(.custom("Avenir-Heavy", size: 18))
                                .foregroundColor(Color("AccentGold"))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color("CardBackground"))
                        )
                        
                        // Best tile
                        VStack(spacing: 2) {
                            Text("BEST")
                                .font(.custom("Avenir-Medium", size: 10))
                                .foregroundColor(.secondary)
                            Text("\(highestTile)")
                                .font(.custom("Avenir-Heavy", size: 18))
                                .foregroundColor(tileColor(for: highestTile))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color("CardBackground"))
                        )
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Game grid
                    gameGrid
                        .padding(.horizontal)
                        .gesture(
                            DragGesture(minimumDistance: 30)
                                .onEnded { value in
                                    guard !isEnded else { return }
                                    let h = value.translation.width
                                    let v = value.translation.height
                                    
                                    if abs(h) > abs(v) {
                                        move(h > 0 ? .right : .left)
                                    } else {
                                        move(v > 0 ? .down : .up)
                                    }
                                }
                        )
                    
                    Spacer()
                    
                    // Instructions
                    if !isEnded {
                        Text("Swipe to merge tiles — reach 2048!")
                            .font(.custom("Avenir-Medium", size: 13))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 8)
                    }
                }
                .padding(.top, 8)
                
                // Overlays
                if showOverlay {
                    if hasWon && !keepPlaying {
                        celebrationOverlay
                    } else if isGameOver {
                        gameOverOverlay
                    }
                }
            }
            .navigationTitle("2048")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Color("AccentGold"))
                }
            }
            .onAppear {
                startGame()
            }
        }
    }
    
    // MARK: - Game Grid
    
    private var gameGrid: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 6
            let totalSpacing = spacing * CGFloat(gridSize + 1)
            let cellSize = (min(geo.size.width, geo.size.height) - totalSpacing) / CGFloat(gridSize)
            
            ZStack {
                // Background grid
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.15))
                
                // Empty cell backgrounds
                ForEach(0..<gridSize, id: \.self) { row in
                    ForEach(0..<gridSize, id: \.self) { col in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.08))
                            .frame(width: cellSize, height: cellSize)
                            .position(
                                x: spacing + cellSize / 2 + CGFloat(col) * (cellSize + spacing),
                                y: spacing + cellSize / 2 + CGFloat(row) * (cellSize + spacing)
                            )
                    }
                }
                
                // Tiles
                ForEach(tiles) { tile in
                    TileView(value: tile.value, size: cellSize, isNew: tile.isNew, isMerged: tile.isMerged)
                        .position(
                            x: spacing + cellSize / 2 + CGFloat(tile.col) * (cellSize + spacing),
                            y: spacing + cellSize / 2 + CGFloat(tile.row) * (cellSize + spacing)
                        )
                        .animation(.easeInOut(duration: 0.15), value: tile.row)
                        .animation(.easeInOut(duration: 0.15), value: tile.col)
                }
            }
            .frame(width: min(geo.size.width, geo.size.height), height: min(geo.size.width, geo.size.height))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    // MARK: - Game Logic
    
    private func startGame() {
        tiles = []
        score = 0
        highestTile = 2
        addRandomTile()
        addRandomTile()
    }
    
    private func addRandomTile() {
        var emptyCells: [(Int, Int)] = []
        for r in 0..<gridSize {
            for c in 0..<gridSize {
                if !tiles.contains(where: { $0.row == r && $0.col == c }) {
                    emptyCells.append((r, c))
                }
            }
        }
        
        guard let cell = emptyCells.randomElement() else { return }
        let value = Double.random(in: 0..<1) < 0.9 ? 2 : 4
        tiles.append(Tile(id: UUID(), value: value, row: cell.0, col: cell.1, isNew: true))
        
        // Clear isNew flag after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            for i in tiles.indices {
                tiles[i].isNew = false
            }
        }
    }
    
    private func move(_ direction: MoveDirection) {
        // Clear merge flags
        for i in tiles.indices {
            tiles[i].isMerged = false
        }
        
        var moved = false
        
        switch direction {
        case .left:
            for row in 0..<gridSize {
                moved = processLine(row: row, col: nil, rowDelta: 0, colDelta: -1) || moved
            }
        case .right:
            for row in 0..<gridSize {
                moved = processLine(row: row, col: nil, rowDelta: 0, colDelta: 1) || moved
            }
        case .up:
            for col in 0..<gridSize {
                moved = processLine(row: nil, col: col, rowDelta: -1, colDelta: 0) || moved
            }
        case .down:
            for col in 0..<gridSize {
                moved = processLine(row: nil, col: col, rowDelta: 1, colDelta: 0) || moved
            }
        }
        
        if moved {
            AudioManager.shared.play(.buttonTap)
            addRandomTile()
            updateHighestTile()
            checkGameState()
        }
    }
    
    private func processLine(row: Int?, col: Int?, rowDelta: Int, colDelta: Int) -> Bool {
        var moved = false
        let isHorizontal = rowDelta == 0
        let isPositive = isHorizontal ? colDelta > 0 : rowDelta > 0
        let fixedIndex = isHorizontal ? row! : col!
        
        // Get tiles in this line, sorted from the edge we're moving toward
        var lineTiles = tiles.filter { isHorizontal ? $0.row == fixedIndex : $0.col == fixedIndex }
        lineTiles.sort { isHorizontal ? (isPositive ? $0.col > $1.col : $0.col < $1.col) : (isPositive ? $0.row > $1.row : $0.row < $1.row) }
        
        let start = isPositive ? gridSize - 1 : 0
        let step = isPositive ? -1 : 1
        
        var nextPos = start
        var lastPlacedTileID: UUID? = nil
        
        for lineTile in lineTiles {
            guard let index = tiles.firstIndex(where: { $0.id == lineTile.id }) else { continue }
            
            // Check if we can merge with the last placed tile
            if let lastID = lastPlacedTileID,
               let lastIndex = tiles.firstIndex(where: { $0.id == lastID }),
               tiles[lastIndex].value == tiles[index].value && !tiles[lastIndex].isMerged {
                // Merge with the last placed tile
                let newValue = tiles[index].value * 2
                tiles[lastIndex].value = newValue
                tiles[lastIndex].isMerged = true
                score += newValue
                tiles.remove(at: index)
                moved = true
                lastPlacedTileID = nil // Prevent chain-merging into same tile
            } else {
                // Move to next available position
                let currentPos = isHorizontal ? tiles[index].col : tiles[index].row
                if currentPos != nextPos {
                    if isHorizontal {
                        tiles[index].col = nextPos
                    } else {
                        tiles[index].row = nextPos
                    }
                    moved = true
                }
                lastPlacedTileID = tiles[index].id
                nextPos += step
            }
        }
        
        return moved
    }
    
    private func updateHighestTile() {
        let maxVal = tiles.map(\.value).max() ?? 2
        if maxVal > highestTile {
            highestTile = maxVal
        }
    }
    
    private func checkGameState() {
        // Check for win
        if highestTile >= 2048 && !hasWon {
            hasWon = true
            AudioManager.shared.play(.success)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showOverlay = true
            }
            return
        }
        
        // Check for game over
        if tiles.count == gridSize * gridSize {
            // All cells occupied — check if any merges possible
            for tile in tiles {
                let neighbors = [
                    (tile.row - 1, tile.col),
                    (tile.row + 1, tile.col),
                    (tile.row, tile.col - 1),
                    (tile.row, tile.col + 1),
                ]
                for (r, c) in neighbors {
                    if let neighbor = tiles.first(where: { $0.row == r && $0.col == c }),
                       neighbor.value == tile.value {
                        return // Merge possible, not game over
                    }
                }
            }
            // No merges possible
            isGameOver = true
            AudioManager.shared.play(.error)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showOverlay = true
            }
        }
    }
    
    // MARK: - Tile Colors
    
    private func tileColor(for value: Int) -> Color {
        switch value {
        case 2: return Color.secondary
        case 4: return Color("AccentGreen")
        case 8: return Color("AccentOrange")
        case 16: return Color("AccentOrange")
        case 32: return Color.red
        case 64: return Color.red
        case 128: return Color("AccentGold")
        case 256: return Color("AccentGold")
        case 512: return Color("AccentPurple")
        case 1024: return Color("AccentPurple")
        case 2048: return Color("AccentGold")
        default: return Color("AccentGold")
        }
    }
    
    // MARK: - Time Formatted
    
    private var timeFormatted: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%d:%02d", m, s)
    }
    
    // MARK: - Celebration Overlay (Win or Game Over with rewards)
    
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
                        Text("Score")
                            .font(.custom("Avenir-Medium", size: 12))
                            .foregroundColor(.secondary)
                        Text("\(score)")
                            .font(.custom("Avenir-Heavy", size: 18))
                            .foregroundColor(Color("AccentGold"))
                    }
                    VStack(spacing: 4) {
                        Text("Best Tile")
                            .font(.custom("Avenir-Medium", size: 12))
                            .foregroundColor(.secondary)
                        Text("\(highestTile)")
                            .font(.custom("Avenir-Heavy", size: 18))
                            .foregroundColor(tileColor(for: highestTile))
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
                        Image(systemName: StatType.dexterity.icon)
                            .foregroundColor(Color(StatType.dexterity.color))
                        Text("Dexterity")
                            .font(.custom("Avenir-Medium", size: 15))
                        Spacer()
                        Text("+\(tier.wisdomBonus)")
                            .font(.custom("Avenir-Heavy", size: 17))
                            .foregroundColor(Color(StatType.dexterity.color))
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(tier.color).opacity(0.08))
                )
                
                // Two buttons: Claim or Keep Playing
                VStack(spacing: 8) {
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
                    
                    if hasWon && !isGameOver {
                        Button {
                            keepPlaying = true
                            showOverlay = false
                        } label: {
                            Text("Keep Playing")
                                .font(.custom("Avenir-Heavy", size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
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
        let tier = rewardTier
        
        return ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            
            VStack(spacing: 16) {
                Image(systemName: "flag.checkered")
                    .font(.system(size: 56))
                    .foregroundColor(Color(tier.color))
                    .shadow(color: Color(tier.color).opacity(0.5), radius: 12)
                
                Text("No Moves Left!")
                    .font(.custom("Avenir-Heavy", size: 24))
                
                Text("Highest tile: \(highestTile)  •  Score: \(score)")
                    .font(.custom("Avenir-Medium", size: 15))
                    .foregroundColor(.secondary)
                
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
                        Image(systemName: StatType.dexterity.icon)
                            .foregroundColor(Color(StatType.dexterity.color))
                        Text("Dexterity")
                            .font(.custom("Avenir-Medium", size: 15))
                        Spacer()
                        Text("+\(tier.wisdomBonus)")
                            .font(.custom("Avenir-Heavy", size: 17))
                            .foregroundColor(Color(StatType.dexterity.color))
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
}

// MARK: - Tile View

private struct TileView: View {
    let value: Int
    let size: CGFloat
    let isNew: Bool
    let isMerged: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
            
            Text("\(value)")
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .foregroundColor(textColor)
                .minimumScaleFactor(0.5)
        }
        .frame(width: size, height: size)
        .scaleEffect(isNew ? 0.5 : (isMerged ? 1.15 : 1.0))
        .animation(.easeOut(duration: 0.15), value: isNew)
        .animation(.easeOut(duration: 0.15), value: isMerged)
    }
    
    private var fontSize: CGFloat {
        if value >= 1024 { return size * 0.22 }
        if value >= 128 { return size * 0.28 }
        return size * 0.35
    }
    
    private var backgroundColor: Color {
        switch value {
        case 2: return Color(.systemGray5)
        case 4: return Color(.systemGray4)
        case 8: return Color.orange.opacity(0.7)
        case 16: return Color.orange.opacity(0.85)
        case 32: return Color.red.opacity(0.65)
        case 64: return Color.red.opacity(0.8)
        case 128: return Color.yellow.opacity(0.7)
        case 256: return Color.yellow.opacity(0.8)
        case 512: return Color.purple.opacity(0.6)
        case 1024: return Color.purple.opacity(0.75)
        case 2048: return Color("AccentGold")
        default: return Color("AccentGold").opacity(0.9)
        }
    }
    
    private var textColor: Color {
        switch value {
        case 2, 4: return .primary
        default: return .white
        }
    }
}
