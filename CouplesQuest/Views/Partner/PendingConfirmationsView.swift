import SwiftUI
import SwiftData

/// View showing partner's completed tasks awaiting confirmation
struct PendingConfirmationsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var gameEngine: GameEngine
    @Query private var characters: [PlayerCharacter]
    @Query private var bonds: [Bond]
    
    @State private var showDisputeAlert = false
    @State private var disputeReason = ""
    @State private var selectedTask: GameTask?
    @State private var showConfirmedToast = false
    @State private var confirmedTaskTitle = ""
    
    private var character: PlayerCharacter? { characters.first }
    private var bond: Bond? { bonds.first }
    
    /// Fetch all tasks pending partner confirmation that were created by the current user's partner
    private var pendingTasks: [GameTask] {
        guard let character = character else { return [] }
        let characterID = character.id
        
        // Fetch tasks where pendingPartnerConfirmation is true
        // and the task was NOT completed by this character (it's the partner's task)
        let descriptor = FetchDescriptor<GameTask>(
            predicate: #Predicate<GameTask> { task in
                task.pendingPartnerConfirmation == true
            },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        
        let tasks = (try? modelContext.fetch(descriptor)) ?? []
        // Filter: only show tasks where the completer is NOT us (i.e., we're the confirmer)
        return tasks.filter { $0.completedBy != nil && $0.completedBy != characterID }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color("BackgroundTop"), Color("BackgroundBottom")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if pendingTasks.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        headerSection
                        
                        ForEach(pendingTasks, id: \.id) { task in
                            pendingTaskCard(task)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Pending Confirmations")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Dispute Task", isPresented: $showDisputeAlert) {
            TextField("Reason (optional)", text: $disputeReason)
            Button("Dispute", role: .destructive) {
                if let task = selectedTask {
                    gameEngine.disputePartnerTask(task, reason: disputeReason.isEmpty ? nil : disputeReason)
                    disputeReason = ""
                }
            }
            Button("Cancel", role: .cancel) {
                disputeReason = ""
            }
        } message: {
            Text("Are you sure you want to dispute this task? It will revert to pending and no rewards will be given.")
        }
        .overlay(alignment: .top) {
            if showConfirmedToast {
                confirmedToast
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { showConfirmedToast = false }
                        }
                    }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundColor(Color("AccentGreen"))
            
            Text("All Clear!")
                .font(.custom("Avenir-Heavy", size: 22))
            
            Text("No tasks awaiting your confirmation")
                .font(.custom("Avenir-Medium", size: 15))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "person.2.circle.fill")
                    .font(.title2)
                    .foregroundColor(Color("AccentGold"))
                Text("Partner's Completed Tasks")
                    .font(.custom("Avenir-Heavy", size: 18))
            }
            
            Text("Review and confirm your partner's task completions")
                .font(.custom("Avenir-Medium", size: 13))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
    }
    
    // MARK: - Task Card
    
    private func pendingTaskCard(_ task: GameTask) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title and time
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.custom("Avenir-Heavy", size: 16))
                    
                    if let completedAt = task.completedAt {
                        Text("Completed \(completedAt, style: .relative) ago")
                            .font(.custom("Avenir-Medium", size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Category badge
                HStack(spacing: 4) {
                    Image(systemName: task.category.icon)
                    Text(task.category.rawValue)
                }
                .font(.custom("Avenir-Medium", size: 11))
                .foregroundColor(Color(task.category.color))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(task.category.color).opacity(0.15))
                .clipShape(Capsule())
            }
            
            // Proof thumbnail (if photo verification)
            if task.verificationType.requiresPhoto, let photoData = task.verificationPhotoData,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            // Location info
            if task.verificationType.requiresLocation, let lat = task.verificationLatitude, let lon = task.verificationLongitude {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(Color("AccentGreen"))
                    Text("\(String(format: "%.4f", lat)), \(String(format: "%.4f", lon))")
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                    
                    if let name = task.geofenceLocationName {
                        Text("(\(name))")
                            .font(.custom("Avenir-Medium", size: 12))
                            .foregroundColor(Color("AccentGreen"))
                    }
                }
            }
            
            // HealthKit status
            if task.healthKitVerified, let summary = task.healthKitActivitySummary {
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text(summary)
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            // Auto-confirm timer
            if let completedAt = task.completedAt {
                let autoConfirmAt = completedAt.addingTimeInterval(86400) // 24 hours
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.orange)
                    Text("Auto-confirms \(autoConfirmAt, style: .relative)")
                        .font(.custom("Avenir-Medium", size: 11))
                        .foregroundColor(.orange)
                }
            }
            
            Divider()
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: {
                    confirmTask(task)
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Confirm")
                    }
                    .font(.custom("Avenir-Heavy", size: 15))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color("AccentGold"), Color("AccentOrange")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                Button(action: {
                    selectedTask = task
                    showDisputeAlert = true
                }) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Dispute")
                    }
                    .font(.custom("Avenir-Heavy", size: 15))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
    }
    
    // MARK: - Confirmed Toast
    
    private var confirmedToast: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color("AccentGreen"))
            Text("Confirmed: \(confirmedTaskTitle)")
                .font(.custom("Avenir-Heavy", size: 14))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("CardBackground"))
                .shadow(radius: 10)
        )
        .padding(.top, 8)
    }
    
    // MARK: - Actions
    
    private func confirmTask(_ task: GameTask) {
        guard let character = character else { return }
        gameEngine.confirmPartnerTask(task, character: character, bond: bond)
        confirmedTaskTitle = task.title
        withAnimation { showConfirmedToast = true }
    }
}
