import SwiftUI

// MARK: - Word Search Reward Tiers

struct WordSearchRewardTier {
    let name: String
    let icon: String
    let color: String
    let gold: Int
    let consumableName: String
    let consumableIcon: String
    let consumableCount: Int
    let wisdomBonus: Int
    
    static func tier(for elapsedSeconds: Int) -> WordSearchRewardTier {
        let minutes = elapsedSeconds / 60
        switch minutes {
        case ..<2:
            return WordSearchRewardTier(
                name: "Eagle Eye",
                icon: "bolt.fill",
                color: "AccentGold",
                gold: 200,
                consumableName: "Hawk Potion",
                consumableIcon: "eye.fill",
                consumableCount: 3,
                wisdomBonus: 2
            )
        case 2..<4:
            return WordSearchRewardTier(
                name: "Sharp Scout",
                icon: "sparkles",
                color: "AccentGreen",
                gold: 150,
                consumableName: "Green Tea",
                consumableIcon: "leaf.fill",
                consumableCount: 2,
                wisdomBonus: 1
            )
        case 4..<6:
            return WordSearchRewardTier(
                name: "Steady Search",
                icon: "checkmark.seal.fill",
                color: "AccentOrange",
                gold: 100,
                consumableName: "Apple Juice",
                consumableIcon: "cup.and.saucer.fill",
                consumableCount: 1,
                wisdomBonus: 1
            )
        default:
            return WordSearchRewardTier(
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
        ("Eagle Eye", "< 2 min", 200, "3× Hawk Potion"),
        ("Sharp Scout", "2–4 min", 150, "2× Green Tea"),
        ("Steady Search", "4–6 min", 100, "1× Apple Juice"),
        ("Completed", "> 6 min", 50, "—"),
    ]
}

// MARK: - Grid Position

private struct GridPos: Hashable {
    let row: Int
    let col: Int
}

// MARK: - Placed Word

private struct PlacedWord {
    let word: String
    let positions: [GridPos]
}

// MARK: - Word Search Puzzle Generator

private struct WordSearchPuzzle {
    let grid: [[Character]]
    let words: [PlacedWord]
    let size: Int
    
    static let wordPool = [
        "SWORD", "QUEST", "ARMOR", "SHIELD", "MAGIC",
        "ROGUE", "FLAME", "POTION", "DRAGON", "KNIGHT",
        "SPELL", "CROWN", "TOWER", "BLADE", "MANA",
        "STAFF", "CLOAK", "FORGE", "RUNE", "BEAST",
    ]
    
    static func generate(gridSize: Int = 10, wordCount: Int = 6) -> WordSearchPuzzle {
        var grid = Array(repeating: Array(repeating: Character(" "), count: gridSize), count: gridSize)
        let shuffled = wordPool.shuffled()
        var placed: [PlacedWord] = []
        
        // Directions: right, down, diagonal-down-right, diagonal-down-left
        let directions: [(Int, Int)] = [(0, 1), (1, 0), (1, 1), (1, -1)]
        
        for word in shuffled {
            if placed.count >= wordCount { break }
            
            let chars = Array(word)
            var didPlace = false
            
            // Try random placements up to 100 times
            for _ in 0..<100 {
                let dir = directions.randomElement()!
                let startRow = Int.random(in: 0..<gridSize)
                let startCol = Int.random(in: 0..<gridSize)
                
                // Check if word fits
                let endRow = startRow + dir.0 * (chars.count - 1)
                let endCol = startCol + dir.1 * (chars.count - 1)
                
                guard endRow >= 0, endRow < gridSize, endCol >= 0, endCol < gridSize else { continue }
                
                // Check for conflicts
                var positions: [GridPos] = []
                var conflict = false
                for i in 0..<chars.count {
                    let r = startRow + dir.0 * i
                    let c = startCol + dir.1 * i
                    let existing = grid[r][c]
                    if existing != " " && existing != chars[i] {
                        conflict = true
                        break
                    }
                    positions.append(GridPos(row: r, col: c))
                }
                
                if conflict { continue }
                
                // Place the word
                for i in 0..<chars.count {
                    grid[positions[i].row][positions[i].col] = chars[i]
                }
                placed.append(PlacedWord(word: word, positions: positions))
                didPlace = true
                break
            }
            
            if !didPlace { continue }
        }
        
        // Fill remaining blanks with random letters
        let letters: [Character] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        for r in 0..<gridSize {
            for c in 0..<gridSize {
                if grid[r][c] == " " {
                    grid[r][c] = letters.randomElement()!
                }
            }
        }
        
        return WordSearchPuzzle(grid: grid, words: placed, size: gridSize)
    }
}

// MARK: - Timer View

private struct WordSearchTimerView: View {
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

// MARK: - Word Search Game View

struct WordSearchGameView: View {
    let onComplete: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var puzzle: WordSearchPuzzle
    @State private var foundWords: Set<String> = []
    @State private var selectedCells: [GridPos] = []
    @State private var highlightedCells: [String: Color] = [:] // "r,c" -> color
    @State private var elapsedSeconds = 0
    @State private var isSolved = false
    @State private var showOverlay = false
    @State private var isDragging = false
    
    private var isEnded: Bool { isSolved }
    
    private var rewardTier: WordSearchRewardTier {
        WordSearchRewardTier.tier(for: elapsedSeconds)
    }
    
    private let wordColors: [Color] = [
        Color("AccentGold"),
        Color("AccentGreen"),
        Color("AccentOrange"),
        Color("AccentPurple"),
        Color("AccentPink"),
        Color.cyan,
    ]
    
    init(onComplete: @escaping (Int) -> Void) {
        self.onComplete = onComplete
        _puzzle = State(initialValue: WordSearchPuzzle.generate())
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
                
                VStack(spacing: 12) {
                    // Timer + progress
                    HStack {
                        WordSearchTimerView(elapsedSeconds: $elapsedSeconds, isStopped: isEnded)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(Color("AccentGold"))
                            Text("\(foundWords.count)/\(puzzle.words.count)")
                                .font(.custom("Avenir-Heavy", size: 14))
                                .foregroundColor(Color("AccentGold"))
                        }
                    }
                    .padding(.horizontal)
                    
                    // Word list
                    wordListView
                        .padding(.horizontal)
                    
                    // Grid
                    gridView
                        .padding(.horizontal, 4)
                    
                    // Instructions
                    if !isEnded {
                        Text("Tap the first and last letter of a word to select it")
                            .font(.custom("Avenir-Medium", size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.top, 8)
                
                // Overlay
                if showOverlay && isSolved {
                    celebrationOverlay
                }
            }
            .navigationTitle("Word Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Color("AccentGold"))
                }
            }
        }
    }
    
    // MARK: - Word List
    
    private var wordListView: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 3)
        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(Array(puzzle.words.enumerated()), id: \.element.word) { index, placed in
                let found = foundWords.contains(placed.word)
                Text(placed.word)
                    .font(.custom("Avenir-Heavy", size: 13))
                    .strikethrough(found)
                    .foregroundColor(found ? wordColors[index % wordColors.count].opacity(0.5) : .primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(found ? wordColors[index % wordColors.count].opacity(0.1) : Color.secondary.opacity(0.08))
                    )
            }
        }
    }
    
    // MARK: - Grid View
    
    private var gridView: some View {
        VStack(spacing: 0) {
            ForEach(0..<puzzle.size, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<puzzle.size, id: \.self) { col in
                        let key = "\(row),\(col)"
                        let pos = GridPos(row: row, col: col)
                        let isSelected = selectedCells.contains(where: { $0.row == row && $0.col == col })
                        let highlightColor = highlightedCells[key]
                        
                        Button {
                            tapCell(pos)
                        } label: {
                            Text(String(puzzle.grid[row][col]))
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundColor(cellTextColor(isSelected: isSelected, highlight: highlightColor))
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                                .background(cellBackground(isSelected: isSelected, highlight: highlightColor))
                        }
                        .buttonStyle(.plain)
                        .disabled(isEnded)
                    }
                }
            }
        }
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color("AccentGold").opacity(0.3), lineWidth: 2)
        )
    }
    
    private func cellTextColor(isSelected: Bool, highlight: Color?) -> Color {
        if isSelected { return Color("AccentGold") }
        if highlight != nil { return .white }
        return .primary
    }
    
    private func cellBackground(isSelected: Bool, highlight: Color?) -> Color {
        if isSelected { return Color("AccentGold").opacity(0.25) }
        if let color = highlight { return color.opacity(0.4) }
        return Color.clear
    }
    
    // MARK: - Tap Logic
    
    private func tapCell(_ pos: GridPos) {
        if selectedCells.isEmpty {
            // First tap — select start cell
            selectedCells = [pos]
        } else if selectedCells.count == 1 {
            // Second tap — try to form a word
            let start = selectedCells[0]
            let end = pos
            
            // Check if this start-end pair matches any word
            if let match = findMatchingWord(from: start, to: end) {
                // Found a word
                let colorIndex = foundWords.count % wordColors.count
                let color = wordColors[colorIndex]
                
                for p in match.positions {
                    highlightedCells["\(p.row),\(p.col)"] = color
                }
                
                foundWords.insert(match.word)
                AudioManager.shared.play(.claimReward)
                selectedCells = []
                
                // Check if all words found
                if foundWords.count == puzzle.words.count {
                    triggerWin()
                }
            } else {
                // No match — reset
                selectedCells = []
                AudioManager.shared.play(.buttonTap)
            }
        }
    }
    
    private func findMatchingWord(from start: GridPos, to end: GridPos) -> PlacedWord? {
        for placed in puzzle.words {
            guard !foundWords.contains(placed.word) else { continue }
            guard let first = placed.positions.first, let last = placed.positions.last else { continue }
            
            // Check both directions (start->end or end->start)
            if (first.row == start.row && first.col == start.col &&
                last.row == end.row && last.col == end.col) ||
               (first.row == end.row && first.col == end.col &&
                last.row == start.row && last.col == start.col) {
                return placed
            }
        }
        return nil
    }
    
    // MARK: - Win
    
    private func triggerWin() {
        isSolved = true
        AudioManager.shared.play(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showOverlay = true
            }
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
                        Text("Words Found")
                            .font(.custom("Avenir-Medium", size: 12))
                            .foregroundColor(.secondary)
                        Text("\(foundWords.count)/\(puzzle.words.count)")
                            .font(.custom("Avenir-Heavy", size: 18))
                            .foregroundColor(Color("AccentGreen"))
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
                        Image(systemName: StatType.charisma.icon)
                            .foregroundColor(Color(StatType.charisma.color))
                        Text("Charisma")
                            .font(.custom("Avenir-Medium", size: 15))
                        Spacer()
                        Text("+\(tier.wisdomBonus)")
                            .font(.custom("Avenir-Heavy", size: 17))
                            .foregroundColor(Color(StatType.charisma.color))
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
