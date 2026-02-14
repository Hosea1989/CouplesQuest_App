import SwiftUI
import SwiftData
import MapKit

/// View for editing an existing task — reuses CreateTaskView layout with pre-populated data
struct EditTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var task: GameTask
    @Query private var characters: [PlayerCharacter]
    @Query private var bonds: [Bond]
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var selectedCategory: TaskCategory = .physical
    @State private var selectedVerification: VerificationType = .none
    @State private var isOnDutyBoard: Bool = false
    @State private var invitePartner: Bool = false
    @State private var partnerMessage: String = ""
    @State private var isHabit: Bool = false
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
    
    private var character: PlayerCharacter? {
        characters.first
    }
    
    private var bond: Bond? {
        bonds.first
    }
    
    private var hasPartner: Bool {
        character?.partnerCharacterID != nil && bond != nil
    }
    
    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Computed reward preview with verification multiplier
    private var previewEXP: Int {
        Int(Double(GameTask.baseEXP) * selectedVerification.rewardMultiplier)
    }
    
    private var previewGold: Int {
        Int(Double(GameTask.baseGold) * selectedVerification.rewardMultiplier)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundTop").ignoresSafeArea()
                
                Form {
                    // Basic Info
                    Section {
                        TextField("Task Title", text: $title)
                            .font(.custom("Avenir-Medium", size: 16))
                        
                        TextField("Description (optional)", text: $description, axis: .vertical)
                            .font(.custom("Avenir-Medium", size: 14))
                            .lineLimit(3...6)
                    } header: {
                        Text("Task Details")
                    }
                    
                    // Category Selection (2x3 grid)
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
                    
                    // Verification
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
                    
                    // Geofence Location (when location verification is selected)
                    if selectedVerification.requiresLocation {
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
                    
                    // Assignment
                    Section {
                        Toggle(isOn: $isOnDutyBoard) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Add to Duty Board")
                                    .font(.custom("Avenir-Medium", size: 16))
                                Text("Anyone can claim this task")
                                    .font(.custom("Avenir-Medium", size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .tint(Color("AccentGold"))
                    } header: {
                        Text("Assignment")
                    }
                    
                    // Invite Partner
                    if hasPartner {
                        Section {
                            Toggle(isOn: $invitePartner) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "person.2.fill")
                                            .foregroundColor(Color("AccentPink"))
                                            .font(.callout)
                                        Text("Invite Partner")
                                            .font(.custom("Avenir-Medium", size: 16))
                                    }
                                    Text("Both of you do this task together")
                                        .font(.custom("Avenir-Medium", size: 12))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .tint(Color("AccentPink"))
                            
                            if invitePartner {
                                TextField("Add a note for your partner... (optional)", text: $partnerMessage, axis: .vertical)
                                    .font(.custom("Avenir-Medium", size: 14))
                                    .lineLimit(2...3)
                                
                                // Bonus info
                                HStack(spacing: 6) {
                                    Image(systemName: "heart.circle.fill")
                                        .foregroundColor(Color("AccentPink"))
                                    Text("+\(GameEngine.bondEXPForPartnerTask) Bond EXP when completed")
                                        .font(.custom("Avenir-Medium", size: 12))
                                        .foregroundColor(Color("AccentPink"))
                                }
                                .padding(.vertical, 4)
                            }
                        } header: {
                            Text("Partner")
                        }
                    }
                    
                    // Habit
                    Section {
                        Toggle(isOn: $isHabit) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Daily Habit")
                                    .font(.custom("Avenir-Medium", size: 16))
                                Text("Repeats every day, tracks streaks")
                                    .font(.custom("Avenir-Medium", size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .tint(Color("AccentGreen"))
                        .onChange(of: isHabit) { _, newValue in
                            if newValue {
                                isRecurring = false
                                hasDueDate = false
                            }
                        }
                    } header: {
                        Text("Type")
                    }
                    
                    // Recurring (hidden when Habit is on)
                    if !isHabit {
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
                        
                        // Due Date
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
                    
                    // Info
                    Section {
                        HStack {
                            Text("Created")
                                .font(.custom("Avenir-Medium", size: 14))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(task.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.custom("Avenir-Medium", size: 14))
                        }
                    } header: {
                        Text("Info")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color("AccentGold"))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(isValid ? Color("AccentGold") : .secondary)
                    .disabled(!isValid)
                }
            }
            .sensoryFeedback(.selection, trigger: selectedCategory)
            .sensoryFeedback(.selection, trigger: selectedVerification)
        }
        .onAppear {
            populateFromTask()
        }
    }
    
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
    
    // MARK: - Pre-populate from existing task
    
    private func populateFromTask() {
        title = task.title
        description = task.taskDescription ?? ""
        selectedCategory = task.category
        selectedVerification = task.verificationType
        isOnDutyBoard = task.isOnDutyBoard
        invitePartner = task.isSharedWithPartner
        partnerMessage = task.partnerMessage ?? ""
        isHabit = task.isHabit
        isRecurring = task.isRecurring
        recurrencePattern = task.recurrencePattern ?? .daily
        hasDueDate = task.dueDate != nil
        dueDate = task.dueDate ?? Date().addingTimeInterval(86400)
        
        // Geofence
        if let lat = task.geofenceLatitude, let lon = task.geofenceLongitude {
            hasGeofence = true
            geofenceLatitude = lat
            geofenceLongitude = lon
            geofenceRadius = task.geofenceRadius ?? 200
            geofenceLocationName = task.geofenceLocationName ?? ""
            geofenceRegion = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }
    
    // MARK: - Save Changes
    
    private func saveChanges() {
        let wasSharedBefore = task.isSharedWithPartner
        
        task.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        task.taskDescription = description.isEmpty ? nil : description
        task.category = selectedCategory
        task.verificationType = selectedVerification
        task.isOnDutyBoard = isOnDutyBoard
        task.isSharedWithPartner = invitePartner && hasPartner
        task.partnerMessage = (invitePartner && !partnerMessage.isEmpty) ? partnerMessage : nil
        task.isHabit = isHabit
        task.isRecurring = isHabit ? true : isRecurring
        task.recurrencePattern = isHabit ? .daily : (isRecurring ? recurrencePattern : nil)
        task.dueDate = isHabit ? nil : (hasDueDate ? dueDate : nil)
        
        // Geofence
        if hasGeofence && selectedVerification.requiresLocation {
            task.geofenceLatitude = geofenceLatitude
            task.geofenceLongitude = geofenceLongitude
            task.geofenceRadius = geofenceRadius
            task.geofenceLocationName = geofenceLocationName.isEmpty ? nil : geofenceLocationName
        } else {
            task.geofenceLatitude = nil
            task.geofenceLongitude = nil
            task.geofenceRadius = nil
            task.geofenceLocationName = nil
        }
        
        // Create partner interaction if newly invited
        if invitePartner && hasPartner && !wasSharedBefore {
            if let character = character, let bond = bond {
                let interaction = PartnerInteraction(
                    type: .taskInvited,
                    message: partnerMessage.isEmpty ? "Invited you to: \(task.title)" : partnerMessage,
                    fromCharacterID: character.id
                )
                modelContext.insert(interaction)
                bond.gainBondEXP(GameEngine.bondEXPForPartnerTask)
            }
        }
        
        // If partner was un-invited, reset shared fields
        if !invitePartner && wasSharedBefore {
            task.sharedPartnerCompleted = false
        }
        
        dismiss()
    }
}
