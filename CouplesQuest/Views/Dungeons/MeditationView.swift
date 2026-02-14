import SwiftUI
import SwiftData
import Combine

struct MeditationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var gameEngine: GameEngine
    @Query private var characters: [PlayerCharacter]
    
    // MARK: - External Configuration
    
    /// When set, the meditation was launched from a duty board task.
    /// On completion the task will be marked done.
    var dutyTask: GameTask? = nil
    
    /// Optional callback fired after a successful meditation completion
    /// (used by TasksView to finalize the duty board task).
    var onMeditationComplete: (() -> Void)? = nil
    
    // MARK: - Phase State
    
    enum MeditationPhase: Equatable {
        case setup
        case warmUp
        case active
        case paused
        case completed
    }
    
    @State private var phase: MeditationPhase = .setup
    
    // MARK: - Timer Settings
    
    @State private var selectedMinutes: Int = UserDefaults.standard.object(forKey: "Meditation_minutes") as? Int ?? 5
    @State private var selectedSeconds: Int = UserDefaults.standard.object(forKey: "Meditation_seconds") as? Int ?? 0
    @State private var selectedStartingBell: AudioManager.MeditationBell = .savedStarting
    @State private var selectedEndingBell: AudioManager.MeditationBell = .savedEnding
    @State private var selectedAmbientSound: AudioManager.AmbientSound = .saved
    @State private var selectedIntervalBell: AudioManager.IntervalBellOption = .saved
    
    // MARK: - Picker Sheets
    
    @State private var showDurationPicker = false
    @State private var showStartingBellPicker = false
    @State private var showEndingBellPicker = false
    @State private var showAmbientSoundPicker = false
    @State private var showIntervalBellPicker = false
    
    // MARK: - Timer State
    
    @State private var totalDuration: Int = 0
    @State private var remainingSeconds: Int = 0
    @State private var warmUpRemaining: Int = 5
    @State private var elapsedSinceLastIntervalBell: Int = 0
    @State private var timerSubscription: AnyCancellable?
    
    // MARK: - Result State
    
    @State private var showResult = false
    @State private var meditationResult: MeditationResult?
    @State private var meditateTrigger = 0
    
    private var character: PlayerCharacter? {
        characters.first
    }
    
    /// Formatted countdown string (MM:SS)
    private var countdownText: String {
        let mins = remainingSeconds / 60
        let secs = remainingSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    /// Formatted warm-up string
    private var warmUpText: String {
        let mins = warmUpRemaining / 60
        let secs = warmUpRemaining % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    /// Formatted duration display for the setup row
    private var durationDisplayText: String {
        let mins = selectedMinutes
        let secs = selectedSeconds
        if secs == 0 {
            return "Meditation \(mins):00"
        }
        return "Meditation \(mins):\(String(format: "%02d", secs))"
    }
    
    /// Number of interval bells remaining in the session
    private var intervalBellsRemaining: Int {
        guard selectedIntervalBell.intervalSeconds > 0 else { return 0 }
        let interval = selectedIntervalBell.intervalSeconds
        return max(0, remainingSeconds / interval)
    }
    
    /// Whether the begin button should be enabled
    private var canStart: Bool {
        let hasDuration = selectedMinutes > 0 || selectedSeconds > 0
        // If launched from duty board, always allow (ignore daily limit)
        if dutyTask != nil { return hasDuration }
        return hasDuration && !(character?.hasMeditatedToday ?? true)
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            switch phase {
            case .setup:
                setupScreen
            case .warmUp, .active, .paused:
                immersiveScreen
            case .completed:
                setupScreen // Shows completed state within the setup layout
            }
        }
        .overlay {
            if showResult, let result = meditationResult {
                meditationResultOverlay(result: result)
            }
        }
        .sensoryFeedback(.success, trigger: meditateTrigger)
        .onAppear {
            // If already meditated today (and not from duty board), jump to completed
            if dutyTask == nil && character?.hasMeditatedToday == true {
                phase = .completed
            }
            // If launched from duty, pre-set 5 minutes
            if dutyTask != nil {
                selectedMinutes = 5
                selectedSeconds = 0
            }
        }
        .onDisappear {
            timerSubscription?.cancel()
            AudioManager.shared.stopAmbientSound()
        }
    }
    
    // MARK: - Setup Screen
    
    private var setupScreen: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color("BackgroundTop"), Color("BackgroundBottom")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Scrollable content
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        setupHeader
                        
                        if let character = character {
                            // Streak + rewards (compact)
                            streakCard(character: character)
                            
                            if phase == .completed {
                                completedCard
                            } else {
                                // Rewards preview
                                rewardsPreview(character: character)
                            }
                            
                            // Settings rows
                            if phase != .completed {
                                settingsSection
                            }
                            
                            // Milestones
                            milestonesCard(character: character)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 120) // Space for the start button
                }
                
                // Fixed bottom: Start button
                if phase != .completed {
                    startButtonSection
                }
            }
        }
        .sheet(isPresented: $showDurationPicker) { durationPickerSheet }
        .sheet(isPresented: $showStartingBellPicker) { bellPickerSheet(title: "Starting Bell", selection: $selectedStartingBell) }
        .sheet(isPresented: $showEndingBellPicker) { bellPickerSheet(title: "Ending Bell", selection: $selectedEndingBell) }
        .sheet(isPresented: $showAmbientSoundPicker) { ambientSoundPickerSheet }
        .sheet(isPresented: $showIntervalBellPicker) { intervalBellPickerSheet }
    }
    
    // MARK: - Setup Header
    
    private var setupHeader: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color("AccentPurple").opacity(0.15))
                    .frame(width: 70, height: 70)
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 32))
                    .foregroundColor(Color("AccentPurple"))
            }
            
            Text("Meditation")
                .font(.custom("Avenir-Heavy", size: 24))
            
            Text("Center your mind. Build a streak for bonus EXP.")
                .font(.custom("Avenir-Medium", size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Settings Section
    
    private var settingsSection: some View {
        VStack(spacing: 2) {
            // Starting Bell
            settingsRow(
                label: "Starting bell",
                value: selectedStartingBell.displayName,
                icon: selectedStartingBell.icon
            ) {
                showStartingBellPicker = true
            }
            
            dividerLine
            
            // Duration
            settingsRow(
                label: "Duration",
                value: durationDisplayText,
                icon: "clock.fill"
            ) {
                showDurationPicker = true
            }
            
            dividerLine
            
            // Interval Bells
            settingsRow(
                label: "Interval bells",
                value: selectedIntervalBell.displayName,
                icon: "bell.badge.fill"
            ) {
                showIntervalBellPicker = true
            }
            
            dividerLine
            
            // Ambient Sound
            settingsRow(
                label: "Ambient sound",
                value: selectedAmbientSound.displayName,
                icon: selectedAmbientSound.icon
            ) {
                showAmbientSoundPicker = true
            }
            
            dividerLine
            
            // Ending Bell
            settingsRow(
                label: "Ending bell",
                value: selectedEndingBell.displayName,
                icon: selectedEndingBell.icon
            ) {
                showEndingBellPicker = true
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
        .padding(.horizontal)
    }
    
    // MARK: - Settings Row
    
    private func settingsRow(label: String, value: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.custom("Avenir-Medium", size: 16))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(value)
                    .font(.custom("Avenir-Medium", size: 15))
                    .foregroundColor(.secondary)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
    }
    
    private var dividerLine: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.1))
            .frame(height: 1)
            .padding(.leading, 20)
    }
    
    // MARK: - Start Button
    
    private var startButtonSection: some View {
        VStack(spacing: 12) {
            Button {
                if let character = character {
                    beginMeditation(character: character)
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            canStart
                            ? LinearGradient(colors: [Color("AccentPurple"), Color("AccentPink")], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color.secondary.opacity(0.3), Color.secondary.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: canStart ? Color("AccentPurple").opacity(0.4) : .clear, radius: 12)
                    
                    Text("Start")
                        .font(.custom("Avenir-Heavy", size: 18))
                        .foregroundColor(.white)
                }
            }
            .disabled(!canStart)
        }
        .padding(.bottom, 30)
    }
    
    // MARK: - Completed Card
    
    private var completedCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(Color("AccentGreen"))
            Text("Meditation Complete")
                .font(.custom("Avenir-Heavy", size: 18))
                .foregroundColor(Color("AccentGreen"))
            Text("Come back tomorrow to continue your streak!")
                .font(.custom("Avenir-Medium", size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
        .padding(.horizontal)
    }
    
    // MARK: - Streak Card
    
    @ViewBuilder
    private func streakCard(character: PlayerCharacter) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Meditation Streak")
                    .font(.custom("Avenir-Heavy", size: 16))
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(character.meditationStreak > 0 ? Color("AccentOrange") : .secondary)
                    Text("\(character.meditationStreak) day\(character.meditationStreak == 1 ? "" : "s")")
                        .font(.custom("Avenir-Heavy", size: 20))
                        .foregroundColor(character.meditationStreak > 0 ? Color("AccentOrange") : .secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Streak Bonus")
                    .font(.custom("Avenir-Medium", size: 12))
                    .foregroundColor(.secondary)
                let bonus = min(50, character.meditationStreak * 5)
                Text("+\(bonus)% EXP")
                    .font(.custom("Avenir-Heavy", size: 18))
                    .foregroundColor(bonus > 0 ? Color("AccentGreen") : .secondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
        .padding(.horizontal)
    }
    
    // MARK: - Rewards Preview
    
    @ViewBuilder
    private func rewardsPreview(character: PlayerCharacter) -> some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundColor(Color("AccentGold"))
                Text("+\(character.meditationExpReward)")
                    .font(.custom("Avenir-Heavy", size: 18))
                Text("EXP")
                    .font(.custom("Avenir-Medium", size: 11))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            
            VStack(spacing: 4) {
                Image(systemName: "dollarsign.circle")
                    .font(.title3)
                    .foregroundColor(Color("AccentGold"))
                Text("+\(character.meditationGoldReward)")
                    .font(.custom("Avenir-Heavy", size: 18))
                Text("Gold")
                    .font(.custom("Avenir-Medium", size: 11))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            
            VStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.title3)
                    .foregroundColor(Color("AccentOrange"))
                Text("+1")
                    .font(.custom("Avenir-Heavy", size: 18))
                Text("Streak")
                    .font(.custom("Avenir-Medium", size: 11))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
        .padding(.horizontal)
    }
    
    // MARK: - Milestones
    
    @ViewBuilder
    private func milestonesCard(character: PlayerCharacter) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Streak Milestones")
                .font(.custom("Avenir-Heavy", size: 18))
            
            let milestones: [(days: Int, bonus: String)] = [
                (3, "+15% EXP"),
                (7, "+35% EXP"),
                (10, "+50% EXP (Max)"),
            ]
            
            ForEach(milestones, id: \.days) { milestone in
                HStack(spacing: 12) {
                    Image(systemName: character.meditationStreak >= milestone.days ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(character.meditationStreak >= milestone.days ? Color("AccentGreen") : .secondary)
                    
                    Text("\(milestone.days)-Day Streak")
                        .font(.custom("Avenir-Heavy", size: 14))
                    
                    Spacer()
                    
                    Text(milestone.bonus)
                        .font(.custom("Avenir-Heavy", size: 12))
                        .foregroundColor(Color("AccentGold"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color("AccentGold").opacity(0.15)))
                }
                .padding(.vertical, 2)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
        .padding(.horizontal)
    }
    
    // MARK: - ===================== IMMERSIVE SCREEN =====================
    
    private var immersiveScreen: some View {
        ZStack {
            // Full-screen background gradient (night sky / fantasy)
            immersiveBackground
            
            VStack(spacing: 0) {
                // Top label
                Text("Meditation")
                    .font(.custom("Avenir-Medium", size: 16))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.top, 60)
                
                Spacer()
                
                // Central content
                VStack(spacing: 12) {
                    if phase == .warmUp {
                        Text("Warm Up")
                            .font(.custom("Avenir-Medium", size: 18))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text(warmUpText)
                            .font(.system(size: 64, weight: .thin, design: .default))
                            .foregroundColor(.white)
                            .contentTransition(.numericText())
                            .monospacedDigit()
                    } else if phase == .paused {
                        Text("Paused")
                            .font(.custom("Avenir-Medium", size: 18))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text(countdownText)
                            .font(.system(size: 64, weight: .thin, design: .default))
                            .foregroundColor(.white)
                            .monospacedDigit()
                        
                        if intervalBellsRemaining > 0 {
                            Text("\(intervalBellsRemaining) bell\(intervalBellsRemaining == 1 ? "" : "s") remaining")
                                .font(.custom("Avenir-Medium", size: 14))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    } else {
                        // Active
                        Text(countdownText)
                            .font(.system(size: 64, weight: .thin, design: .default))
                            .foregroundColor(.white)
                            .contentTransition(.numericText())
                            .monospacedDigit()
                        
                        if intervalBellsRemaining > 0 {
                            Text("\(intervalBellsRemaining) bell\(intervalBellsRemaining == 1 ? "" : "s") remaining")
                                .font(.custom("Avenir-Medium", size: 14))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                
                Spacer()
                
                // Bottom controls
                if phase == .paused {
                    pausedControls
                } else {
                    // Play/Pause button
                    Button {
                        if phase == .warmUp || phase == .active {
                            pauseSession()
                        }
                    } label: {
                        Image(systemName: "pause")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.bottom, 60)
                }
            }
        }
        .statusBarHidden(true)
    }
    
    // MARK: - Immersive Background
    
    private var immersiveBackground: some View {
        ZStack {
            // Deep night sky gradient
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.05, blue: 0.15),  // very dark navy
                    Color(red: 0.05, green: 0.12, blue: 0.25),  // deep blue
                    Color(red: 0.08, green: 0.18, blue: 0.30),  // midnight teal
                    Color(red: 0.05, green: 0.15, blue: 0.22),  // dark teal
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Subtle aurora / glow at the horizon
            VStack {
                Spacer()
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.1, green: 0.35, blue: 0.4).opacity(0.5),
                                Color(red: 0.05, green: 0.2, blue: 0.3).opacity(0.2),
                                .clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 300
                        )
                    )
                    .frame(width: 600, height: 200)
                    .offset(y: 60)
            }
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Paused Controls
    
    private var pausedControls: some View {
        VStack(spacing: 16) {
            // Resume button (play icon)
            Button {
                resumeSession()
            } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 12)
            
            // Finish button (complete early with rewards)
            Button {
                if let character = character {
                    finishEarly(character: character)
                }
            } label: {
                Text("Finish")
                    .font(.custom("Avenir-Heavy", size: 18))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.white)
                    )
            }
            .padding(.horizontal, 24)
            
            // Discard session
            Button {
                discardSession()
            } label: {
                Text("Discard session")
                    .font(.custom("Avenir-Medium", size: 15))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Result Overlay
    
    @ViewBuilder
    private func meditationResultOverlay(result: MeditationResult) -> some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation { showResult = false }
                    dismiss()
                }
            
            VStack(spacing: 20) {
                Image(systemName: "sparkles")
                    .font(.system(size: 50))
                    .foregroundColor(Color("AccentPurple"))
                
                Text("Mind Refreshed!")
                    .font(.custom("Avenir-Heavy", size: 24))
                
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("+\(result.expGained) EXP")
                    }
                    .font(.custom("Avenir-Heavy", size: 18))
                    .foregroundColor(Color("AccentGold"))
                    
                    HStack {
                        Image(systemName: "dollarsign.circle")
                        Text("+\(result.goldGained) Gold")
                    }
                    .font(.custom("Avenir-Medium", size: 16))
                    .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "flame.fill")
                        Text("\(result.streak)-day streak!")
                    }
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(Color("AccentOrange"))
                }
                
                Button {
                    withAnimation { showResult = false }
                    onMeditationComplete?()
                    dismiss()
                } label: {
                    Text("Continue")
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.black)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(colors: [Color("AccentGold"), Color("AccentOrange")], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color("BackgroundTop"))
            )
            .padding(40)
        }
        .transition(.opacity)
    }
    
    // MARK: - ===================== PICKER SHEETS =====================
    
    // MARK: Duration Picker Sheet
    
    private var durationPickerSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Picker("Minutes", selection: $selectedMinutes) {
                        ForEach(0...60, id: \.self) { min in
                            Text("\(min) min").tag(min)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    
                    Picker("Seconds", selection: $selectedSeconds) {
                        ForEach(Array(stride(from: 0, through: 55, by: 5)), id: \.self) { sec in
                            Text("\(sec) sec").tag(sec)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .clipped()
                }
                .frame(height: 200)
                .padding()
                
                Spacer()
            }
            .navigationTitle("Duration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showDurationPicker = false }
                        .foregroundColor(Color("AccentGold"))
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    // MARK: Bell Picker Sheet
    
    private func bellPickerSheet(title: String, selection: Binding<AudioManager.MeditationBell>) -> some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(AudioManager.MeditationBell.allCases) { bell in
                        Button {
                            selection.wrappedValue = bell
                            AudioManager.shared.previewBell(bell)
                        } label: {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(selection.wrappedValue == bell
                                              ? Color("AccentPurple").opacity(0.25)
                                              : Color.secondary.opacity(0.1))
                                        .frame(width: 56, height: 56)
                                    
                                    if selection.wrappedValue == bell {
                                        Circle()
                                            .stroke(Color("AccentPurple"), lineWidth: 2)
                                            .frame(width: 56, height: 56)
                                    }
                                    
                                    Image(systemName: bell.icon)
                                        .font(.system(size: 22))
                                        .foregroundColor(selection.wrappedValue == bell
                                                         ? Color("AccentPurple")
                                                         : .secondary)
                                }
                                
                                Text(bell.displayName)
                                    .font(.custom("Avenir-Medium", size: 12))
                                    .foregroundColor(selection.wrappedValue == bell ? Color("AccentPurple") : .secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showStartingBellPicker = false
                        showEndingBellPicker = false
                    }
                    .foregroundColor(Color("AccentGold"))
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    // MARK: Ambient Sound Picker Sheet
    
    private var ambientSoundPickerSheet: some View {
        NavigationStack {
            List {
                ForEach(AudioManager.AmbientSound.allCases) { sound in
                    Button {
                        selectedAmbientSound = sound
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: sound.icon)
                                .font(.title3)
                                .foregroundColor(selectedAmbientSound == sound ? Color("AccentPurple") : .secondary)
                                .frame(width: 30)
                            
                            Text(sound.displayName)
                                .font(.custom("Avenir-Medium", size: 16))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedAmbientSound == sound {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color("AccentPurple"))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Ambient Sound")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showAmbientSoundPicker = false }
                        .foregroundColor(Color("AccentGold"))
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    // MARK: Interval Bell Picker Sheet
    
    private var intervalBellPickerSheet: some View {
        NavigationStack {
            List {
                ForEach(AudioManager.IntervalBellOption.allCases) { option in
                    Button {
                        selectedIntervalBell = option
                    } label: {
                        HStack {
                            Text(option.displayName)
                                .font(.custom("Avenir-Medium", size: 16))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedIntervalBell == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color("AccentPurple"))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Interval Bells")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showIntervalBellPicker = false }
                        .foregroundColor(Color("AccentGold"))
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    // MARK: - ===================== TIMER ACTIONS =====================
    
    private func beginMeditation(character: PlayerCharacter) {
        // Persist preferences
        UserDefaults.standard.set(selectedMinutes, forKey: "Meditation_minutes")
        UserDefaults.standard.set(selectedSeconds, forKey: "Meditation_seconds")
        selectedStartingBell.saveAsStarting()
        selectedEndingBell.saveAsEnding()
        selectedAmbientSound.save()
        selectedIntervalBell.save()
        
        // Calculate total duration
        totalDuration = selectedMinutes * 60 + selectedSeconds
        remainingSeconds = totalDuration
        elapsedSinceLastIntervalBell = 0
        
        guard totalDuration > 0 else { return }
        
        // Start warm-up phase
        warmUpRemaining = 5
        withAnimation(.easeInOut(duration: 0.3)) {
            phase = .warmUp
        }
        
        // Start ambient sound
        AudioManager.shared.playAmbientSound(selectedAmbientSound)
        
        // Start warm-up countdown
        timerSubscription = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [self] _ in
                if phase == .warmUp {
                    if warmUpRemaining > 0 {
                        warmUpRemaining -= 1
                    } else {
                        // Warm-up done — play starting bell and begin main timer
                        AudioManager.shared.playBell(selectedStartingBell)
                        withAnimation(.easeInOut(duration: 0.3)) {
                            phase = .active
                        }
                    }
                } else if phase == .active {
                    if remainingSeconds > 0 {
                        remainingSeconds -= 1
                        elapsedSinceLastIntervalBell += 1
                        
                        // Check interval bell
                        let interval = selectedIntervalBell.intervalSeconds
                        if interval > 0 && elapsedSinceLastIntervalBell >= interval && remainingSeconds > 0 {
                            AudioManager.shared.playBell(selectedEndingBell)
                            elapsedSinceLastIntervalBell = 0
                        }
                    } else {
                        completeMeditation(character: character)
                    }
                }
                // If paused, do nothing (timer ticks but we ignore)
            }
    }
    
    private func pauseSession() {
        withAnimation(.easeInOut(duration: 0.2)) {
            phase = .paused
        }
    }
    
    private func resumeSession() {
        withAnimation(.easeInOut(duration: 0.2)) {
            phase = .active
        }
    }
    
    private func finishEarly(character: PlayerCharacter) {
        completeMeditation(character: character)
    }
    
    private func discardSession() {
        timerSubscription?.cancel()
        timerSubscription = nil
        AudioManager.shared.stopAmbientSound()
        
        withAnimation(.easeInOut(duration: 0.3)) {
            phase = .setup
        }
    }
    
    private func completeMeditation(character: PlayerCharacter) {
        // Stop the timer
        timerSubscription?.cancel()
        timerSubscription = nil
        
        // Play the ending bell
        AudioManager.shared.playBell(selectedEndingBell)
        
        // Stop ambient sound (fade out)
        AudioManager.shared.stopAmbientSound()
        
        // Award meditation rewards (only if not already meditated today, unless from duty)
        if !character.hasMeditatedToday {
            if let result = gameEngine.meditate(character: character) {
                meditationResult = result
                meditateTrigger += 1
                
                var subtitle = "+\(result.expGained) EXP, +\(result.goldGained) Gold"
                if result.wisdomBuffGranted {
                    subtitle += "\n🧠 +5% Wisdom buff for 24hr!"
                }
                
                ToastManager.shared.showSuccess(
                    "Meditation Complete!",
                    subtitle: subtitle
                )
            }
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            phase = .completed
        }
        
        if meditationResult != nil {
            withAnimation {
                showResult = true
            }
        } else {
            // If already meditated today (duty board repeat), still notify completion
            onMeditationComplete?()
            dismiss()
        }
    }
}

#Preview {
    MeditationView()
        .environmentObject(GameEngine())
}
