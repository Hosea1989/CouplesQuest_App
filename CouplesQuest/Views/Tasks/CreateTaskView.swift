import SwiftUI
import SwiftData
import MapKit

struct CreateTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var characters: [PlayerCharacter]
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var selectedCategory: TaskCategory = .physical
    @State private var selectedPhysicalFocus: PhysicalActivityFocus = .strength
    @State private var selectedVerification: VerificationType = .none
    @State private var isOnDutyBoard: Bool = true
    @State private var isRecurring: Bool = false
    @State private var recurrencePattern: RecurrencePattern = .daily
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Date().addingTimeInterval(86400) // Tomorrow
    
    // Geofence fields
    @State private var hasGeofence: Bool = false
    @State private var geofenceLocationName: String = ""
    @State private var geofenceLatitude: Double = 0
    @State private var geofenceLongitude: Double = 0
    @State private var geofenceRadius: Double = 200
    @State private var showLocationPicker = false
    @State private var geofenceRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    private var character: PlayerCharacter? {
        characters.first
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
                    
                    // Category Selection (2 categories)
                    Section {
                        HStack(spacing: 12) {
                            ForEach(TaskCategory.allCases, id: \.self) { category in
                                CategoryButton(
                                    category: category,
                                    isSelected: selectedCategory == category,
                                    action: { selectedCategory = category }
                                )
                            }
                        }
                        .padding(.vertical, 8)
                        
                        // Physical Focus picker (only for Physical)
                        if selectedCategory == .physical {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Focus")
                                    .font(.custom("Avenir-Heavy", size: 13))
                                    .foregroundColor(.secondary)
                                
                                ForEach(PhysicalActivityFocus.activeCases, id: \.self) { focus in
                                    Button(action: { selectedPhysicalFocus = focus }) {
                                        HStack(spacing: 12) {
                                            Image(systemName: focus.icon)
                                                .font(.system(size: 18))
                                                .frame(width: 28)
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(focus.rawValue)
                                                    .font(.custom("Avenir-Heavy", size: 14))
                                                Text(focus.subtitle)
                                                    .font(.custom("Avenir-Medium", size: 11))
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            if selectedPhysicalFocus == focus {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(Color(focus.color))
                                            }
                                        }
                                        .padding(10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(selectedPhysicalFocus == focus
                                                      ? Color(focus.color).opacity(0.15)
                                                      : Color.secondary.opacity(0.08))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(selectedPhysicalFocus == focus
                                                        ? Color(focus.color)
                                                        : Color.clear, lineWidth: 1.5)
                                        )
                                        .foregroundColor(.primary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
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
                                
                                // Map preview
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
                                
                                // Radius slider
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
                    
                    // Recurring
                    Section {
                        Toggle(isOn: $isRecurring) {
                            Text("Recurring Task")
                                .font(.custom("Avenir-Medium", size: 16))
                        }
                        .tint(Color("AccentGold"))
                        
                        if isRecurring {
                            Picker("Repeat", selection: $recurrencePattern) {
                                ForEach([RecurrencePattern.daily, .weekdays, .weekends, .weekly], id: \.self) { pattern in
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
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color("AccentGold"))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createTask()
                    }
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(isValid ? Color("AccentGold") : .secondary)
                    .disabled(!isValid)
                }
            }
            .sensoryFeedback(.selection, trigger: selectedCategory)
            .sensoryFeedback(.selection, trigger: selectedVerification)
        }
    }
    
    // MARK: - Geofence Helpers
    
    private var geofenceAnnotations: [GeofenceAnnotation] {
        if hasGeofence {
            return [GeofenceAnnotation(coordinate: geofenceRegion.center)]
        }
        return []
    }
    
    /// Approximate circle size on map based on radius and zoom level
    private var mapCircleSize: CGFloat {
        let metersPerDegree = 111_320.0
        let metersVisible = geofenceRegion.span.latitudeDelta * metersPerDegree
        let fraction = geofenceRadius / metersVisible
        return max(30, min(150, CGFloat(fraction * 180)))
    }
    
    private func createTask() {
        guard let character = character else { return }
        
        let task = GameTask(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.isEmpty ? nil : description,
            category: selectedCategory,
            physicalFocus: selectedCategory == .physical ? selectedPhysicalFocus : nil,
            createdBy: character.id,
            assignedTo: isOnDutyBoard ? nil : character.id,
            isOnDutyBoard: isOnDutyBoard,
            isRecurring: isRecurring,
            recurrencePattern: isRecurring ? recurrencePattern : nil,
            dueDate: hasDueDate ? dueDate : nil,
            verificationType: selectedVerification,
            geofenceLatitude: hasGeofence && selectedVerification.requiresLocation ? geofenceLatitude : nil,
            geofenceLongitude: hasGeofence && selectedVerification.requiresLocation ? geofenceLongitude : nil,
            geofenceRadius: hasGeofence && selectedVerification.requiresLocation ? geofenceRadius : nil,
            geofenceLocationName: hasGeofence && selectedVerification.requiresLocation && !geofenceLocationName.isEmpty ? geofenceLocationName : nil
        )
        
        modelContext.insert(task)
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
}

