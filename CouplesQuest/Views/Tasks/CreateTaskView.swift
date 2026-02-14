import SwiftUI
import SwiftData
import MapKit

// MARK: - Task Creation Type

enum TaskCreationType: String, CaseIterable, Identifiable {
    case forMe = "For Me"
    case forPartner = "For Partner"
    case together = "Together"
    case habit = "Habit"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .forMe: return "person.fill"
        case .forPartner: return "paperplane.fill"
        case .together: return "person.2.fill"
        case .habit: return "arrow.trianglehead.2.clockwise"
        }
    }
    
    var subtitle: String {
        switch self {
        case .forMe: return "Personal task"
        case .forPartner: return "Send to partner"
        case .together: return "Both do it"
        case .habit: return "Daily streak"
        }
    }
    
    var color: String {
        switch self {
        case .forMe: return "AccentGold"
        case .forPartner: return "AccentPink"
        case .together: return "AccentPurple"
        case .habit: return "AccentGreen"
        }
    }
}

// MARK: - CreateTaskView

struct CreateTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var gameEngine: GameEngine
    @Query private var characters: [PlayerCharacter]
    @Query private var bonds: [Bond]
    @Query(filter: #Predicate<Goal> { $0.completedAt == nil }) private var activeGoals: [Goal]
    
    /// Optional initial type — used when opened from Partner tab
    var initialType: TaskCreationType?
    
    // MARK: - State
    
    @State private var selectedType: TaskCreationType = .forMe
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var selectedCategory: TaskCategory = .physical
    @State private var selectedVerification: VerificationType = .none
    @State private var partnerMessage: String = ""
    
    // Habit fields
    @State private var hasHabitDueTime: Bool = false
    @State private var habitDueTime: Date = {
        let calendar = Calendar.current
        return calendar.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date()
    }()
    
    // Schedule fields (non-habit)
    @State private var isRecurring: Bool = false
    @State private var recurrencePattern: RecurrencePattern = .daily
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Date().addingTimeInterval(86400)
    
    // Geofence fields
    @State private var hasGeofence: Bool = false
    @State private var geofenceLocationName: String = ""
    @State private var geofenceLatitude: Double = 0
    @State private var geofenceLongitude: Double = 0
    @State private var geofenceRadius: Double = 200
    @State private var geofenceRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    // Goal linking
    @State private var selectedGoalID: UUID?
    
    // MARK: - Computed
    
    private var character: PlayerCharacter? { characters.first }
    private var bond: Bond? { bonds.first }
    
    private var hasPartner: Bool {
        character?.partnerCharacterID != nil && bond != nil
    }
    
    /// Types available based on partner status
    private var availableTypes: [TaskCreationType] {
        if hasPartner {
            return TaskCreationType.allCases
        } else {
            return [.forMe, .habit]
        }
    }
    
    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var previewEXP: Int {
        Int(Double(GameTask.baseEXP) * selectedVerification.rewardMultiplier)
    }
    
    private var previewGold: Int {
        Int(Double(GameTask.baseGold) * selectedVerification.rewardMultiplier)
    }
    
    private var isHabitType: Bool { selectedType == .habit }
    private var involvesPartner: Bool { selectedType == .forPartner || selectedType == .together }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundTop").ignoresSafeArea()
                
                Form {
                    // 1. Type Picker (top of form)
                    typePickerSection
                    
                    // 2. Basic Info
                    basicInfoSection
                    
                    // 3. Category
                    categorySection
                    
                    // 4. Verification
                    verificationSection
                    
                    // 5. Geofence (conditional)
                    if selectedVerification.requiresLocation {
                        geofenceSection
                    }
                    
                    // 6. Partner Message (for partner/together types)
                    if involvesPartner {
                        partnerMessageSection
                    }
                    
                    // 7. Habit Deadline (for habit type)
                    if isHabitType {
                        habitDeadlineSection
                    }
                    
                    // 8. Schedule & Due Date (non-habit types)
                    if !isHabitType {
                        scheduleSection
                    }
                    
                    // 9. Link to Goal
                    if !activeGoals.isEmpty {
                        goalLinkSection
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color("AccentGold"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") { createTask() }
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(isValid ? Color("AccentGold") : .secondary)
                        .disabled(!isValid)
                }
            }
            .sensoryFeedback(.selection, trigger: selectedCategory)
            .sensoryFeedback(.selection, trigger: selectedVerification)
            .sensoryFeedback(.selection, trigger: selectedType)
            .onAppear {
                if let initial = initialType {
                    selectedType = initial
                }
            }
        }
    }
    
    // MARK: - Type Picker Section
    
    private var typePickerSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(availableTypes) { type in
                        Button(action: { withAnimation(.easeInOut(duration: 0.2)) { selectedType = type } }) {
                            VStack(spacing: 6) {
                                Image(systemName: type.icon)
                                    .font(.system(size: 20, weight: .semibold))
                                Text(type.rawValue)
                                    .font(.custom("Avenir-Heavy", size: 12))
                                Text(type.subtitle)
                                    .font(.custom("Avenir-Medium", size: 10))
                                    .foregroundColor(selectedType == type ? Color(type.color) : .secondary)
                            }
                            .frame(width: 85, height: 80)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedType == type ? Color(type.color).opacity(0.15) : Color.secondary.opacity(0.08))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedType == type ? Color(type.color) : Color.clear, lineWidth: 2)
                            )
                            .foregroundColor(selectedType == type ? Color(type.color) : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("What kind of task?")
        }
    }
    
    // MARK: - Basic Info Section
    
    private var basicInfoSection: some View {
        Section {
            TextField("Task Title", text: $title)
                .font(.custom("Avenir-Medium", size: 16))
            
            TextField("Description (optional)", text: $description, axis: .vertical)
                .font(.custom("Avenir-Medium", size: 14))
                .lineLimit(3...6)
        } header: {
            Text("Details")
        }
    }
    
    // MARK: - Category Section
    
    private var categorySection: some View {
        Section {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach(TaskCategory.allCases, id: \.self) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("Category")
        }
    }
    
    // MARK: - Verification Section
    
    private var verificationSection: some View {
        Section {
            ForEach(VerificationType.allCases, id: \.self) { vType in
                Button(action: { selectedVerification = vType }) {
                    HStack(spacing: 12) {
                        Image(systemName: vType.icon)
                            .font(.system(size: 16))
                            .foregroundColor(Color(vType.color))
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(vType.rawValue)
                                .font(.custom("Avenir-Heavy", size: 14))
                            
                            if vType != .none {
                                Text("\(String(format: "%.1f", vType.rewardMultiplier))x rewards")
                                    .font(.custom("Avenir-Medium", size: 11))
                                    .foregroundColor(Color(vType.color))
                            } else {
                                Text("Base rewards")
                                    .font(.custom("Avenir-Medium", size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if selectedVerification == vType {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color("AccentGold"))
                        }
                    }
                    .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
            }
            
            // Reward Preview
            HStack {
                Text("Reward")
                    .font(.custom("Avenir-Medium", size: 14))
                    .foregroundColor(.secondary)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                    Text("+\(previewEXP) EXP")
                }
                .font(.custom("Avenir-Heavy", size: 14))
                .foregroundColor(Color("AccentGold"))
                
                HStack(spacing: 4) {
                    Image(systemName: "dollarsign.circle.fill")
                    Text("+\(previewGold)")
                }
                .font(.custom("Avenir-Heavy", size: 14))
                .foregroundColor(Color("AccentGold"))
            }
        } header: {
            Text("Verification")
        }
    }
    
    // MARK: - Geofence Section
    
    private var geofenceSection: some View {
        Section {
            Toggle(isOn: $hasGeofence) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Set Target Location")
                        .font(.custom("Avenir-Medium", size: 16))
                    Text("Verify completion at a specific place")
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .tint(Color("AccentGreen"))
            
            if hasGeofence {
                TextField("Location Name (e.g. Planet Fitness)", text: $geofenceLocationName)
                    .font(.custom("Avenir-Medium", size: 14))
                
                Map(coordinateRegion: $geofenceRegion, annotationItems: geofenceAnnotations) { item in
                    MapAnnotation(coordinate: item.coordinate) {
                        VStack(spacing: 0) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title)
                                .foregroundColor(Color("AccentGreen"))
                            Circle()
                                .fill(Color("AccentGreen").opacity(0.15))
                                .frame(width: mapCircleSize, height: mapCircleSize)
                        }
                    }
                }
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onChange(of: geofenceRegion.center.latitude) { _, _ in
                    geofenceLatitude = geofenceRegion.center.latitude
                    geofenceLongitude = geofenceRegion.center.longitude
                }
                
                Text("Drag the map to set the target location")
                    .font(.custom("Avenir-Medium", size: 11))
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Radius")
                            .font(.custom("Avenir-Medium", size: 14))
                        Spacer()
                        Text("\(Int(geofenceRadius))m")
                            .font(.custom("Avenir-Heavy", size: 14))
                            .foregroundColor(Color("AccentGreen"))
                    }
                    Slider(value: $geofenceRadius, in: 100...500, step: 50)
                        .tint(Color("AccentGreen"))
                }
            }
        } header: {
            Text("Geofence")
        }
    }
    
    // MARK: - Partner Message Section
    
    private var partnerMessageSection: some View {
        Section {
            TextField("Add a note for your partner... (optional)", text: $partnerMessage, axis: .vertical)
                .font(.custom("Avenir-Medium", size: 14))
                .lineLimit(2...3)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(partnerQuickMessages, id: \.self) { msg in
                        Button(action: { partnerMessage = msg }) {
                            Text(msg)
                                .font(.custom("Avenir-Medium", size: 11))
                                .foregroundColor(Color(selectedType.color))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(Color(selectedType.color).opacity(0.1))
                                )
                        }
                    }
                }
            }
            
            HStack(spacing: 6) {
                Image(systemName: "heart.circle.fill")
                    .foregroundColor(Color(selectedType.color))
                Text("+\(GameEngine.bondEXPForPartnerTask) Bond EXP when completed")
                    .font(.custom("Avenir-Medium", size: 12))
                    .foregroundColor(Color(selectedType.color))
            }
            .padding(.vertical, 4)
        } header: {
            Text("Partner Message")
        }
    }
    
    // MARK: - Habit Deadline Section
    
    private var habitDeadlineSection: some View {
        Section {
            Toggle(isOn: $hasHabitDueTime) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Set Deadline")
                        .font(.custom("Avenir-Medium", size: 16))
                    Text("Lose rewards if not completed by this time")
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .tint(Color("AccentOrange"))
            
            if hasHabitDueTime {
                DatePicker(
                    "Due by",
                    selection: $habitDueTime,
                    displayedComponents: .hourAndMinute
                )
                .font(.custom("Avenir-Medium", size: 16))
                
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundColor(Color("AccentOrange"))
                    Text("If not completed by this time, you'll lose \(GameTask.baseEXP) EXP and \(GameTask.baseGold) Gold!")
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(Color("AccentOrange"))
                }
            }
        } header: {
            Text("Habit Deadline")
        }
    }
    
    // MARK: - Schedule Section (non-habit)
    
    private var scheduleSection: some View {
        Group {
            Section {
                Toggle(isOn: $isRecurring) {
                    Text("Recurring Task")
                        .font(.custom("Avenir-Medium", size: 16))
                }
                .tint(Color("AccentGold"))
                
                if isRecurring {
                    Picker("Repeat", selection: $recurrencePattern) {
                        ForEach([RecurrencePattern.daily, .weekdays, .weekends, .weekly, .biweekly, .monthly], id: \.self) { pattern in
                            Text(pattern.rawValue).tag(pattern)
                        }
                    }
                }
            } header: {
                Text("Schedule")
            }
            
            Section {
                Toggle(isOn: $hasDueDate) {
                    Text("Set Due Date")
                        .font(.custom("Avenir-Medium", size: 16))
                }
                .tint(Color("AccentGold"))
                
                if hasDueDate {
                    DatePicker(
                        "Due Date",
                        selection: $dueDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
            }
        }
    }
    
    // MARK: - Goal Link Section
    
    private var goalLinkSection: some View {
        Section {
            Picker(selection: $selectedGoalID) {
                Text("None")
                    .tag(nil as UUID?)
                ForEach(activeGoals) { goal in
                    HStack(spacing: 6) {
                        Image(systemName: goal.category.icon)
                        Text(goal.title)
                    }
                    .tag(goal.id as UUID?)
                }
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Link to Goal")
                        .font(.custom("Avenir-Medium", size: 16))
                    Text("Completing this contributes to goal progress")
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("Goal")
        }
    }
    
    // MARK: - Quick Messages
    
    private let partnerQuickMessages = [
        "Let's do this together!",
        "You in?",
        "Race you to it!",
        "Team effort!",
        "Double the fun!",
        "Can you handle this?",
        "I believe in you!"
    ]
    
    // MARK: - Geofence Helpers
    
    private var geofenceAnnotations: [GeofenceAnnotation] {
        if hasGeofence {
            return [GeofenceAnnotation(coordinate: geofenceRegion.center)]
        }
        return []
    }
    
    private var mapCircleSize: CGFloat {
        let metersPerDegree = 111_320.0
        let metersVisible = geofenceRegion.span.latitudeDelta * metersPerDegree
        let fraction = geofenceRadius / metersVisible
        return max(30, min(150, CGFloat(fraction * 180)))
    }
    
    // MARK: - Create Task
    
    private func createTask() {
        guard let character = character else { return }
        
        let isHabit = selectedType == .habit
        let isForPartner = selectedType == .forPartner
        let isTogether = selectedType == .together
        
        // Determine assignedTo based on type
        let assignedTo: UUID? = {
            switch selectedType {
            case .forMe, .together, .habit:
                return character.id
            case .forPartner:
                return character.partnerCharacterID
            }
        }()
        
        let task = GameTask(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.isEmpty ? nil : description,
            category: selectedCategory,
            createdBy: character.id,
            assignedTo: assignedTo,
            isOnDutyBoard: false, // Never on duty board from user creation
            isRecurring: isHabit ? true : isRecurring,
            recurrencePattern: isHabit ? .daily : (isRecurring ? recurrencePattern : nil),
            dueDate: (!isHabit && hasDueDate) ? dueDate : nil,
            partnerMessage: involvesPartner ? (partnerMessage.isEmpty ? nil : partnerMessage) : nil,
            isFromPartner: isForPartner,
            verificationType: selectedVerification,
            geofenceLatitude: hasGeofence && selectedVerification.requiresLocation ? geofenceLatitude : nil,
            geofenceLongitude: hasGeofence && selectedVerification.requiresLocation ? geofenceLongitude : nil,
            geofenceRadius: hasGeofence && selectedVerification.requiresLocation ? geofenceRadius : nil,
            geofenceLocationName: hasGeofence && selectedVerification.requiresLocation && !geofenceLocationName.isEmpty ? geofenceLocationName : nil,
            isHabit: isHabit,
            isSharedWithPartner: isTogether,
            goalID: selectedGoalID
        )
        
        // Set habit due time if enabled
        if isHabit && hasHabitDueTime {
            task.habitDueTime = habitDueTime
        }
        
        modelContext.insert(task)
        
        // --- Partner-specific logic ---
        
        if isForPartner {
            // Create interaction record
            if let bond = bond {
                let interaction = PartnerInteraction(
                    type: .taskAssigned,
                    message: "Assigned: \(task.title)",
                    fromCharacterID: character.id
                )
                modelContext.insert(interaction)
                bond.gainBondEXP(2)
            }
            
            // Push to Supabase + notifications
            let taskTitle = task.title
            let characterName = character.name
            Task {
                do {
                    try await SupabaseService.shared.pushPartnerTask(task)
                } catch {
                    print("❌ Failed to push partner task to cloud: \(error)")
                }
                
                await PushNotificationService.shared.notifyPartnerTaskAssigned(
                    fromName: characterName,
                    taskTitle: taskTitle
                )
                
                do {
                    try await SupabaseService.shared.sendInteraction(
                        type: "task_assigned",
                        message: "Assigned: \(taskTitle)"
                    )
                } catch {
                    print("❌ Failed to send task_assigned interaction: \(error)")
                }
            }
        }
        
        if isTogether {
            // Create co-op interaction
            if let bond = bond {
                let interaction = PartnerInteraction(
                    type: .taskInvited,
                    message: partnerMessage.isEmpty ? "Invited you to: \(task.title)" : partnerMessage,
                    fromCharacterID: character.id
                )
                modelContext.insert(interaction)
                bond.gainBondEXP(GameEngine.bondEXPForPartnerTask)
            }
        }
        
        // --- Notifications ---
        
        if task.dueDate != nil {
            NotificationService.shared.scheduleDueDateReminders(for: task)
        }
        if task.isHabit {
            NotificationService.shared.scheduleHabitReminder()
        }
        
        dismiss()
    }
}

// MARK: - Geofence Annotation

struct GeofenceAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Category Button

struct CategoryButton: View {
    let category: TaskCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.title2)
                Text(category.rawValue)
                    .font(.custom("Avenir-Medium", size: 13))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(category.color).opacity(0.2) : Color.secondary.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(category.color) : Color.clear, lineWidth: 2)
            )
            .foregroundColor(isSelected ? Color(category.color) : .secondary)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CreateTaskView()
        .environmentObject(GameEngine())
}
