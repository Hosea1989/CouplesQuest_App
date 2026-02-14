import SwiftUI

struct TaskTimerView: View {
    let task: GameTask
    var characterLevel: Int = 1
    let onComplete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    // Timer state
    @State private var timeRemaining: Int = 300  // 5 minutes in seconds
    @State private var timerActive: Bool = false
    @State private var timerFinished: Bool = false
    @State private var timer: Timer? = nil
    
    // Animation state
    @State private var ringPulse: Bool = false
    @State private var turnInScale: CGFloat = 1.0
    
    private let totalTime: Int = 300  // 5 minutes
    
    private var progress: CGFloat {
        1.0 - CGFloat(timeRemaining) / CGFloat(totalTime)
    }
    
    private var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color("BackgroundTop"), Color("BackgroundBottom")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Close button
                HStack {
                    Button(action: {
                        stopTimer()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Task name
                VStack(spacing: 8) {
                    Text(task.title)
                        .font(.custom("Avenir-Heavy", size: 24))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    if !timerFinished {
                        Text(timerActive ? "Tap \"I'm Done\" when you finish!" : "Tap Start when you're ready")
                            .font(.custom("Avenir-Medium", size: 16))
                            .foregroundColor(.secondary)
                    } else {
                        Text("Great work!")
                            .font(.custom("Avenir-Heavy", size: 18))
                            .foregroundColor(Color("AccentGreen"))
                    }
                }
                
                // Timer ring
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 12)
                        .frame(width: 240, height: 240)
                    
                    // Progress ring
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            timerFinished
                                ? AngularGradient(
                                    colors: [Color("AccentGreen"), Color("AccentGreen").opacity(0.7)],
                                    center: .center
                                )
                                : AngularGradient(
                                    colors: [Color("AccentGold"), Color("AccentOrange"), Color("AccentGold")],
                                    center: .center
                                ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 240, height: 240)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: progress)
                    
                    // Outer glow
                    Circle()
                        .stroke(
                            timerFinished ? Color("AccentGreen").opacity(0.2) : Color("AccentGold").opacity(ringPulse ? 0.2 : 0.05),
                            lineWidth: 20
                        )
                        .frame(width: 260, height: 260)
                        .blur(radius: 8)
                    
                    // Time display
                    VStack(spacing: 4) {
                        if timerFinished {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(Color("AccentGreen"))
                        } else {
                            Text(formattedTime)
                                .font(.system(size: 56, weight: .bold, design: .monospaced))
                                .foregroundColor(.primary)
                                .contentTransition(.numericText())
                            
                            Text("remaining")
                                .font(.custom("Avenir-Medium", size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Action button
                if timerFinished {
                    // Turn In button
                    Button(action: {
                        onComplete()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "gift.fill")
                                .font(.title3)
                            Text("Turn In")
                                .font(.custom("Avenir-Heavy", size: 20))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            LinearGradient(
                                colors: [Color("AccentGold"), Color("AccentOrange")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: Color("AccentGold").opacity(0.4), radius: turnInScale > 1.0 ? 16 : 8)
                    }
                    .scaleEffect(turnInScale)
                    .padding(.horizontal, 24)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                            turnInScale = 1.03
                        }
                    }
                    
                    // Reward preview
                    HStack(spacing: 20) {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .foregroundColor(Color("AccentGold"))
                            Text("+\(task.scaledExpReward(characterLevel: characterLevel)) EXP")
                                .font(.custom("Avenir-Heavy", size: 14))
                                .foregroundColor(Color("AccentGold"))
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "dollarsign.circle.fill")
                                .foregroundColor(Color("AccentGold"))
                            Text("+\(task.scaledGoldReward(characterLevel: characterLevel)) Gold")
                                .font(.custom("Avenir-Heavy", size: 14))
                                .foregroundColor(Color("AccentGold"))
                        }
                    }
                    .padding(.top, 8)
                } else if timerActive {
                    VStack(spacing: 12) {
                        // "I'm Done" button — complete early
                        Button(action: finishTimer) {
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                Text("I'm Done")
                                    .font(.custom("Avenir-Heavy", size: 20))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    colors: [Color("AccentGreen"), Color("AccentGreen").opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                        
                        // Pause button
                        Button(action: pauseTimer) {
                            HStack(spacing: 10) {
                                Image(systemName: "pause.fill")
                                    .font(.callout)
                                Text("Pause")
                                    .font(.custom("Avenir-Heavy", size: 16))
                            }
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color("CardBackground"))
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                } else {
                    // Start button
                    Button(action: startTimer) {
                        HStack(spacing: 10) {
                            Image(systemName: "play.fill")
                                .font(.title3)
                            Text(timeRemaining < totalTime ? "Resume" : "Start")
                                .font(.custom("Avenir-Heavy", size: 20))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            LinearGradient(
                                colors: [Color("AccentGold"), Color("AccentOrange")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer()
                    .frame(height: 40)
            }
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    // MARK: - Timer Controls
    
    private func startTimer() {
        timerActive = true
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            ringPulse = true
        }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                finishTimer()
            }
        }
    }
    
    private func pauseTimer() {
        timerActive = false
        ringPulse = false
        timer?.invalidate()
        timer = nil
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func finishTimer() {
        stopTimer()
        timerActive = false
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            timerFinished = true
        }
        ringPulse = false
    }
}

#Preview {
    TaskTimerView(
        task: GameTask(
            title: "Jumping Rope",
            description: "Do 5 minutes of jumping rope",
            category: .physical,
            createdBy: UUID()
        ),
        onComplete: {}
    )
}
