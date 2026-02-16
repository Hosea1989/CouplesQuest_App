import SwiftUI

// MARK: - Math Blitz Reward Tiers

struct MathBlitzRewardTier {
    let name: String
    let icon: String
    let color: String
    let gold: Int
    let consumableName: String
    let consumableIcon: String
    let consumableCount: Int
    let wisdomBonus: Int
    
    static func tier(for elapsedSeconds: Int) -> MathBlitzRewardTier {
        let minutes = elapsedSeconds / 60
        switch minutes {
        case ..<1:
            return MathBlitzRewardTier(
                name: "Lightning Calculator",
                icon: "bolt.fill",
                color: "AccentGold",
                gold: 200,
                consumableName: "Focus Scroll",
                consumableIcon: "scroll.fill",
                consumableCount: 3,
                wisdomBonus: 2
            )
        case 1..<2:
            return MathBlitzRewardTier(
                name: "Quick Thinker",
                icon: "sparkles",
                color: "AccentGreen",
                gold: 150,
                consumableName: "Green Tea",
                consumableIcon: "leaf.fill",
                consumableCount: 2,
                wisdomBonus: 1
            )
        case 2..<3:
            return MathBlitzRewardTier(
                name: "Steady Mind",
                icon: "checkmark.seal.fill",
                color: "AccentOrange",
                gold: 100,
                consumableName: "Apple Juice",
                consumableIcon: "cup.and.saucer.fill",
                consumableCount: 1,
                wisdomBonus: 1
            )
        default:
            return MathBlitzRewardTier(
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
        ("Lightning Calculator", "< 1 min", 200, "3× Focus Scroll"),
        ("Quick Thinker", "1–2 min", 150, "2× Green Tea"),
        ("Steady Mind", "2–3 min", 100, "1× Apple Juice"),
        ("Completed", "> 3 min", 50, "—"),
    ]
}

// MARK: - Math Problem

private struct MathProblem {
    let question: String
    let correctAnswer: Int
    let choices: [Int]
    
    static func generate(difficulty: Difficulty) -> MathProblem {
        let a: Int
        let b: Int
        let op: String
        let answer: Int
        
        switch difficulty {
        case .easy:
            // Single digit addition/subtraction
            a = Int.random(in: 2...9)
            b = Int.random(in: 2...9)
            if Bool.random() {
                op = "+"
                answer = a + b
            } else {
                let big = max(a, b)
                let small = min(a, b)
                op = "−"
                answer = big - small
                return makeProblem(a: big, op: op, b: small, answer: answer)
            }
        case .medium:
            // Double digit operations
            a = Int.random(in: 10...50)
            b = Int.random(in: 2...20)
            let roll = Int.random(in: 0..<3)
            if roll == 0 {
                op = "+"
                answer = a + b
            } else if roll == 1 {
                // Ensure larger number comes first so answer is never negative
                let big = max(a, b)
                let small = min(a, b)
                op = "−"
                answer = big - small
                return makeProblem(a: big, op: op, b: small, answer: answer)
            } else {
                let x = Int.random(in: 2...12)
                let y = Int.random(in: 2...9)
                return makeProblem(a: x, op: "×", b: y, answer: x * y)
            }
        case .hard:
            // Larger numbers, mixed operations
            let roll = Int.random(in: 0..<4)
            if roll == 0 {
                a = Int.random(in: 20...99)
                b = Int.random(in: 10...50)
                op = "+"
                answer = a + b
            } else if roll == 1 {
                // Ensure larger number comes first so answer is never negative
                let x = Int.random(in: 30...99)
                let y = Int.random(in: 10...40)
                let big = max(x, y)
                let small = min(x, y)
                op = "−"
                return makeProblem(a: big, op: op, b: small, answer: big - small)
            } else if roll == 2 {
                a = Int.random(in: 6...15)
                b = Int.random(in: 6...12)
                op = "×"
                answer = a * b
            } else {
                // Division
                b = Int.random(in: 2...12)
                answer = Int.random(in: 2...12)
                a = b * answer
                return makeProblem(a: a, op: "÷", b: b, answer: answer)
            }
        }
        
        return makeProblem(a: a, op: op, b: b, answer: answer)
    }
    
    private static func makeProblem(a: Int, op: String, b: Int, answer: Int) -> MathProblem {
        var choices = Set<Int>()
        choices.insert(answer)
        
        // Generate 3 wrong answers that are close to the correct answer
        var attempts = 0
        while choices.count < 4 {
            attempts += 1
            let offset = Int.random(in: 1...max(5, abs(answer / 3) + 1))
            let wrong = Bool.random() ? answer + offset : answer - offset
            if wrong != answer && wrong >= 0 {
                choices.insert(wrong)
            }
            // Safety: if too many attempts, widen the search to avoid infinite loop
            if attempts > 50 {
                let fallback = answer + choices.count + Int.random(in: 1...10)
                if fallback != answer {
                    choices.insert(fallback)
                }
            }
        }
        
        return MathProblem(
            question: "\(a) \(op) \(b)",
            correctAnswer: answer,
            choices: Array(choices).shuffled()
        )
    }
    
    enum Difficulty {
        case easy, medium, hard
    }
}

// MARK: - Timer View

private struct MathTimerView: View {
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

// MARK: - Math Blitz Game View

struct MathBlitzGameView: View {
    let onComplete: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    
    private let totalProblems = 20
    private let maxMistakes = 5
    
    @State private var problems: [MathProblem] = []
    @State private var currentIndex = 0
    @State private var mistakeCount = 0
    @State private var correctCount = 0
    @State private var elapsedSeconds = 0
    @State private var isSolved = false
    @State private var isGameOver = false
    @State private var showOverlay = false
    @State private var answerFeedback: AnswerFeedback?
    @State private var shakeOffset: CGFloat = 0
    
    private var isEnded: Bool { isSolved || isGameOver }
    
    private var rewardTier: MathBlitzRewardTier {
        MathBlitzRewardTier.tier(for: elapsedSeconds)
    }
    
    private var currentProblem: MathProblem? {
        guard currentIndex < problems.count else { return nil }
        return problems[currentIndex]
    }
    
    private var progress: Double {
        Double(currentIndex) / Double(totalProblems)
    }
    
    init(onComplete: @escaping (Int) -> Void) {
        self.onComplete = onComplete
        // Generate 20 problems with scaling difficulty
        var generated: [MathProblem] = []
        for i in 0..<20 {
            let difficulty: MathProblem.Difficulty
            if i < 7 {
                difficulty = .easy
            } else if i < 14 {
                difficulty = .medium
            } else {
                difficulty = .hard
            }
            generated.append(MathProblem.generate(difficulty: difficulty))
        }
        _problems = State(initialValue: generated)
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
                
                VStack(spacing: 20) {
                    // Header: timer + mistakes
                    HStack {
                        MathTimerView(elapsedSeconds: $elapsedSeconds, isStopped: isEnded)
                        
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
                    
                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondary.opacity(0.15))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color("AccentGold"))
                                .frame(width: geo.size.width * progress, height: 8)
                                .animation(.easeInOut(duration: 0.3), value: progress)
                        }
                    }
                    .frame(height: 8)
                    .padding(.horizontal)
                    
                    // Question counter
                    Text("Question \(min(currentIndex + 1, totalProblems)) of \(totalProblems)")
                        .font(.custom("Avenir-Medium", size: 14))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Problem display
                    if let problem = currentProblem, !isEnded {
                        VStack(spacing: 24) {
                            // Difficulty badge
                            HStack {
                                let diffLabel = currentIndex < 7 ? "Easy" : (currentIndex < 14 ? "Medium" : "Hard")
                                let diffColor = currentIndex < 7 ? "AccentGreen" : (currentIndex < 14 ? "AccentOrange" : "AccentPurple")
                                
                                Text(diffLabel)
                                    .font(.custom("Avenir-Heavy", size: 12))
                                    .foregroundColor(Color(diffColor))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color(diffColor).opacity(0.15)))
                            }
                            
                            // Question
                            Text(problem.question)
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .offset(x: shakeOffset)
                            
                            // Answer choices
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                                ForEach(problem.choices, id: \.self) { choice in
                                    Button {
                                        submitAnswer(choice)
                                    } label: {
                                        Text("\(choice)")
                                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                                            .foregroundColor(choiceColor(for: choice))
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 64)
                                            .background(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .fill(choiceBackground(for: choice))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .stroke(choiceBorder(for: choice), lineWidth: 2)
                                            )
                                    }
                                    .disabled(answerFeedback != nil)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.top, 8)
                
                // Overlay
                if showOverlay {
                    if isSolved {
                        celebrationOverlay
                    } else if isGameOver {
                        gameOverOverlay
                    }
                }
            }
            .navigationTitle("Math Blitz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Color("AccentGold"))
                }
            }
        }
    }
    
    // MARK: - Answer Feedback
    
    private enum AnswerFeedback {
        case correct
        case wrong(selected: Int)
    }
    
    private func choiceColor(for choice: Int) -> Color {
        guard let feedback = answerFeedback, let problem = currentProblem else {
            return .primary
        }
        if choice == problem.correctAnswer {
            return .white
        }
        if case .wrong(let sel) = feedback, sel == choice {
            return .white
        }
        return .primary
    }
    
    private func choiceBackground(for choice: Int) -> Color {
        guard let feedback = answerFeedback, let problem = currentProblem else {
            return Color("CardBackground")
        }
        if choice == problem.correctAnswer {
            return Color("AccentGreen")
        }
        if case .wrong(let sel) = feedback, sel == choice {
            return Color.red
        }
        return Color("CardBackground")
    }
    
    private func choiceBorder(for choice: Int) -> Color {
        guard let feedback = answerFeedback, let problem = currentProblem else {
            return Color("AccentGold").opacity(0.2)
        }
        if choice == problem.correctAnswer {
            return Color("AccentGreen")
        }
        if case .wrong(let sel) = feedback, sel == choice {
            return Color.red
        }
        return Color("AccentGold").opacity(0.2)
    }
    
    // MARK: - Submit Answer
    
    private func submitAnswer(_ choice: Int) {
        guard let problem = currentProblem else { return }
        guard answerFeedback == nil else { return }
        
        if choice == problem.correctAnswer {
            answerFeedback = .correct
            correctCount += 1
            AudioManager.shared.play(.buttonTap)
        } else {
            answerFeedback = .wrong(selected: choice)
            mistakeCount += 1
            AudioManager.shared.play(.error)
            
            // Shake animation
            withAnimation(.default) {
                shakeOffset = -10
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                withAnimation(.default) { shakeOffset = 10 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                withAnimation(.default) { shakeOffset = -6 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
                withAnimation(.default) { shakeOffset = 0 }
            }
        }
        
        // Advance after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            answerFeedback = nil
            
            if mistakeCount >= maxMistakes {
                triggerGameOver()
                return
            }
            
            currentIndex += 1
            if currentIndex >= totalProblems {
                triggerWin()
            }
        }
    }
    
    private func triggerWin() {
        isSolved = true
        AudioManager.shared.play(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
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
                        Text("Correct")
                            .font(.custom("Avenir-Medium", size: 12))
                            .foregroundColor(.secondary)
                        Text("\(correctCount)/\(totalProblems)")
                            .font(.custom("Avenir-Heavy", size: 18))
                            .foregroundColor(Color("AccentGreen"))
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
                        Image(systemName: StatType.wisdom.icon)
                            .foregroundColor(Color(StatType.wisdom.color))
                        Text("Wisdom")
                            .font(.custom("Avenir-Medium", size: 15))
                        Spacer()
                        Text("+\(tier.wisdomBonus)")
                            .font(.custom("Avenir-Heavy", size: 17))
                            .foregroundColor(Color(StatType.wisdom.color))
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
                
                Text("Too many wrong answers!\nYou got \(correctCount) of \(totalProblems) correct.")
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
