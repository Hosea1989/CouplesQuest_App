import SwiftUI

// MARK: - Sudoku Puzzle Generator

struct SudokuPuzzle {
    let solution: [[Int]]
    let puzzle: [[Int]]
    
    static func generate(blanks: Int = 40) -> SudokuPuzzle {
        var board = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        _ = fillBoard(&board)
        let solution = board
        
        var puzzle = board
        var removed = 0
        var positions = (0..<81).map { ($0 / 9, $0 % 9) }
        positions.shuffle()
        
        for (r, c) in positions {
            guard removed < blanks else { break }
            puzzle[r][c] = 0
            removed += 1
        }
        
        return SudokuPuzzle(solution: solution, puzzle: puzzle)
    }
    
    private static func fillBoard(_ board: inout [[Int]]) -> Bool {
        for r in 0..<9 {
            for c in 0..<9 {
                if board[r][c] == 0 {
                    var nums = Array(1...9)
                    nums.shuffle()
                    for n in nums {
                        if isValid(board, row: r, col: c, num: n) {
                            board[r][c] = n
                            if fillBoard(&board) { return true }
                            board[r][c] = 0
                        }
                    }
                    return false
                }
            }
        }
        return true
    }
    
    static func isValid(_ board: [[Int]], row: Int, col: Int, num: Int) -> Bool {
        if board[row].contains(num) { return false }
        if board.map({ $0[col] }).contains(num) { return false }
        let boxR = (row / 3) * 3
        let boxC = (col / 3) * 3
        for r in boxR..<boxR+3 {
            for c in boxC..<boxC+3 {
                if board[r][c] == num { return false }
            }
        }
        return true
    }
    
    /// Check if a 3×3 box is fully and correctly filled.
    func isBoxComplete(_ boxRow: Int, _ boxCol: Int, in grid: [[Int]]) -> Bool {
        let startR = boxRow * 3
        let startC = boxCol * 3
        for r in startR..<startR+3 {
            for c in startC..<startC+3 {
                if grid[r][c] != solution[r][c] { return false }
            }
        }
        return true
    }
}

// MARK: - Cell Position

struct CellPosition: Equatable, Hashable {
    let row: Int
    let col: Int
}

// MARK: - Isolated Timer View

private struct SudokuTimerView: View {
    let isGameOver: Bool
    @State private var elapsedSeconds = 0
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock")
                .foregroundColor(isGameOver ? .secondary : Color("AccentGold"))
            Text(formatted)
                .font(.custom("Avenir-Heavy", size: 16))
                .monospacedDigit()
                .foregroundColor(isGameOver ? .secondary : .primary)
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if !isGameOver {
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

// MARK: - Sudoku Game View

struct SudokuGameView: View {
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var puzzle: SudokuPuzzle
    @State private var grid: [[Int]]
    @State private var givenCells: Set<String>
    @State private var selected: CellPosition?
    @State private var errors: Set<String> = []
    @State private var isSolved = false
    @State private var isGameOver = false
    @State private var showOverlay = false
    @State private var mistakeCount = 0
    
    // Animation state
    @State private var flashingCells: Set<String> = []   // cells in a just-completed box
    @State private var winWaveCells: Set<String> = []     // cells animating on board win
    @State private var completedBoxes: Set<String> = []   // permanently completed boxes "br,bc"
    
    private var isEnded: Bool { isSolved || isGameOver }
    
    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
        let p = SudokuPuzzle.generate(blanks: 38)
        _puzzle = State(initialValue: p)
        _grid = State(initialValue: p.puzzle)
        
        var given = Set<String>()
        for r in 0..<9 {
            for c in 0..<9 {
                if p.puzzle[r][c] != 0 {
                    given.insert("\(r),\(c)")
                }
            }
        }
        _givenCells = State(initialValue: given)
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
                        SudokuTimerView(isGameOver: isEnded)
                        
                        Spacer()
                        
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle")
                                .foregroundColor(mistakeCount >= 3 ? .red : Color("AccentOrange"))
                            Text("Mistakes: \(mistakeCount)/3")
                                .font(.custom("Avenir-Medium", size: 14))
                                .foregroundColor(mistakeCount >= 3 ? .red : .secondary)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Sudoku grid
                    sudokuGrid
                        .padding(.horizontal, 4)
                        .opacity(isGameOver ? 0.4 : 1.0)
                    
                    // Number pad
                    numberPad
                        .padding(.horizontal)
                        .opacity(isEnded ? 0.3 : 1.0)
                    
                    // Erase button
                    Button {
                        eraseSelected()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "eraser.fill")
                            Text("Erase")
                                .font(.custom("Avenir-Heavy", size: 14))
                        }
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color("CardBackground"))
                        )
                    }
                    .disabled(isEnded)
                    .opacity(isEnded ? 0.3 : 1.0)
                    
                    Spacer()
                }
                .padding(.top, 8)
                
                // Overlay (win or game over)
                if showOverlay {
                    if isSolved {
                        celebrationOverlay
                    } else if isGameOver {
                        gameOverOverlay
                    }
                }
            }
            .navigationTitle("Sudoku")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Color("AccentGold"))
                }
            }
        }
    }
    
    // MARK: - Grid
    
    private var sudokuGrid: some View {
        VStack(spacing: 0) {
            ForEach(0..<9, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<9, id: \.self) { col in
                        let key = "\(row),\(col)"
                        SudokuCellView(
                            value: grid[row][col],
                            isGiven: givenCells.contains(key),
                            isSelected: selected?.row == row && selected?.col == col,
                            isError: errors.contains(key),
                            isHighlighted: isCellHighlighted(row: row, col: col),
                            isFlashing: flashingCells.contains(key),
                            isWinWave: winWaveCells.contains(key),
                            isBoxDone: completedBoxes.contains("\(row/3),\(col/3)")
                        ) {
                            if !givenCells.contains(key) && !isEnded {
                                selected = CellPosition(row: row, col: col)
                            }
                        }
                    }
                }
            }
        }
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isGameOver ? Color.red.opacity(0.4) : Color("AccentGold").opacity(0.4), lineWidth: 2)
        )
        .overlay(boxLines)
    }
    
    private func isCellHighlighted(row: Int, col: Int) -> Bool {
        guard let sel = selected else { return false }
        return sel.row == row || sel.col == col || (sel.row / 3 == row / 3 && sel.col / 3 == col / 3)
    }
    
    private var boxLines: some View {
        GeometryReader { geo in
            let cellW = geo.size.width / 9
            let cellH = geo.size.height / 9
            
            Path { path in
                for i in [3, 6] {
                    let x = cellW * CGFloat(i)
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geo.size.height))
                }
                for i in [3, 6] {
                    let y = cellH * CGFloat(i)
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                }
            }
            .stroke(Color("AccentGold").opacity(0.5), lineWidth: 2)
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Number Pad
    
    private var numberPad: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 9), spacing: 8) {
            ForEach(1...9, id: \.self) { num in
                Button {
                    placeNumber(num)
                } label: {
                    Text("\(num)")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(remainingCount(for: num) == 0 ? .secondary.opacity(0.3) : .primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color("CardBackground"))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color("AccentGold").opacity(0.2), lineWidth: 1)
                        )
                }
                .disabled(remainingCount(for: num) == 0 || isEnded)
            }
        }
    }
    
    private func remainingCount(for num: Int) -> Int {
        let placed = grid.flatMap { $0 }.filter { $0 == num }.count
        return 9 - placed
    }
    
    // MARK: - Actions
    
    private func placeNumber(_ num: Int) {
        guard let sel = selected else { return }
        let key = "\(sel.row),\(sel.col)"
        guard !givenCells.contains(key) else { return }
        guard !isEnded else { return }
        
        if puzzle.solution[sel.row][sel.col] == num {
            grid[sel.row][sel.col] = num
            errors.remove(key)
            AudioManager.shared.play(.buttonTap)
            
            // Check if a 3×3 box was just completed
            checkBoxCompletion(row: sel.row, col: sel.col)
            
            // Check full board win
            checkWin()
        } else {
            grid[sel.row][sel.col] = num
            errors.insert(key)
            mistakeCount += 1
            AudioManager.shared.play(.error)
            
            if mistakeCount >= 3 {
                triggerGameOver()
            }
        }
    }
    
    private func eraseSelected() {
        guard let sel = selected else { return }
        let key = "\(sel.row),\(sel.col)"
        guard !givenCells.contains(key) else { return }
        guard !isEnded else { return }
        grid[sel.row][sel.col] = 0
        errors.remove(key)
    }
    
    // MARK: - Box Completion Animation
    
    private func checkBoxCompletion(row: Int, col: Int) {
        let boxR = row / 3
        let boxC = col / 3
        let boxKey = "\(boxR),\(boxC)"
        
        // Skip if already marked complete
        guard !completedBoxes.contains(boxKey) else { return }
        
        guard puzzle.isBoxComplete(boxR, boxC, in: grid) else { return }
        
        // Collect all cells in this box
        var cells = Set<String>()
        let startR = boxR * 3
        let startC = boxC * 3
        for r in startR..<startR+3 {
            for c in startC..<startC+3 {
                cells.insert("\(r),\(c)")
            }
        }
        
        // Mark box as permanently done
        completedBoxes.insert(boxKey)
        
        // Flash animation — stagger the cells
        for (i, cell) in cells.sorted().enumerated() {
            let delay = Double(i) * 0.04
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    _ = flashingCells.insert(cell)
                }
            }
        }
        
        // Clear the flash after it plays
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.3)) {
                flashingCells = []
            }
        }
        
        AudioManager.shared.play(.claimReward)
    }
    
    // MARK: - Win
    
    private func checkWin() {
        for r in 0..<9 {
            for c in 0..<9 {
                if grid[r][c] != puzzle.solution[r][c] {
                    return
                }
            }
        }
        
        // Board solved — play cascading wave then show overlay
        isSolved = true
        selected = nil
        AudioManager.shared.play(.success)
        
        triggerWinWave()
    }
    
    private func triggerWinWave() {
        // Cascade from top-left to bottom-right
        for r in 0..<9 {
            for c in 0..<9 {
                let key = "\(r),\(c)"
                let delay = Double(r + c) * 0.05 // diagonal wave
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        _ = winWaveCells.insert(key)
                    }
                }
                // Remove after brief hold
                DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.3) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        _ = winWaveCells.remove(key)
                    }
                }
            }
        }
        
        // Show celebration overlay after wave finishes
        // Longest delay: (8+8)*0.05 + 0.3 + 0.2 = 1.3s
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showOverlay = true
            }
        }
    }
    
    private func triggerGameOver() {
        isGameOver = true
        selected = nil
        AudioManager.shared.play(.error)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showOverlay = true
        }
    }
    
    // MARK: - Celebration (Win)
    
    private var celebrationOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 64))
                    .foregroundColor(Color("AccentGold"))
                    .shadow(color: Color("AccentGold").opacity(0.5), radius: 12)
                
                Text("Puzzle Solved!")
                    .font(.custom("Avenir-Heavy", size: 28))
                
                HStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Text("Mistakes")
                            .font(.custom("Avenir-Medium", size: 13))
                            .foregroundColor(.secondary)
                        Text("\(mistakeCount)")
                            .font(.custom("Avenir-Heavy", size: 18))
                            .foregroundColor(mistakeCount == 0 ? Color("AccentGreen") : Color("AccentOrange"))
                    }
                }
                
                Button {
                    onComplete()
                    dismiss()
                } label: {
                    Text("Claim Rewards")
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color("AccentGold"))
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
    
    // MARK: - Game Over (Fail)
    
    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "xmark.octagon.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.red)
                    .shadow(color: .red.opacity(0.4), radius: 12)
                
                Text("Game Over")
                    .font(.custom("Avenir-Heavy", size: 28))
                    .foregroundColor(.red)
                
                Text("You made 3 mistakes.\nBetter luck next time!")
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

// MARK: - Individual Cell View

private struct SudokuCellView: View {
    let value: Int
    let isGiven: Bool
    let isSelected: Bool
    let isError: Bool
    let isHighlighted: Bool
    let isFlashing: Bool      // box-complete flash
    let isWinWave: Bool       // board-complete wave
    let isBoxDone: Bool       // permanently completed box
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Rectangle()
                    .fill(backgroundColor)
                
                // Box-complete flash overlay
                if isFlashing {
                    Rectangle()
                        .fill(Color("AccentGold").opacity(0.45))
                }
                
                // Win wave overlay
                if isWinWave {
                    Rectangle()
                        .fill(Color("AccentGold").opacity(0.5))
                }
                
                Rectangle()
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 0.5)
                
                if value != 0 {
                    Text("\(value)")
                        .font(.system(size: 20, weight: isGiven ? .bold : .medium, design: .rounded))
                        .foregroundColor(textColor)
                        .scaleEffect(isFlashing ? 1.2 : (isWinWave ? 1.15 : 1.0))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color("AccentGold").opacity(0.3)
        } else if isError {
            return Color.red.opacity(0.2)
        } else if isHighlighted {
            return Color("AccentGold").opacity(0.08)
        } else if isBoxDone {
            return Color("AccentGold").opacity(0.04)
        } else if isGiven {
            return Color.secondary.opacity(0.06)
        }
        return Color.clear
    }
    
    private var textColor: Color {
        if isFlashing || isWinWave {
            return Color("AccentGold")
        } else if isError {
            return .red
        } else if isGiven {
            return .primary
        }
        return Color("AccentGold")
    }
}
