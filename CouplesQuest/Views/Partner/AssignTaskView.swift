import SwiftUI
import SwiftData

/// View for assigning a task to your partner
struct AssignTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var gameEngine: GameEngine
    @Query private var characters: [PlayerCharacter]
    @Query private var bonds: [Bond]
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var partnerMessage: String = ""
    @State private var selectedCategory: TaskCategory = .physical
    @State private var selectedPhysicalFocus: PhysicalActivityFocus = .strength
    @State private var selectedVerification: VerificationType = .none
    @State private var isOnDutyBoard: Bool = false
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Date().addingTimeInterval(86400)
    @State private var showSuccessToast = false
    
    private var character: PlayerCharacter? { characters.first }
    private var bond: Bond? { bonds.first }
    
    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // Quick task templates for common partner tasks
    private let quickTemplates: [(title: String, desc: String, category: TaskCategory, focus: PhysicalActivityFocus?)] = [
        ("Go for a Walk", "30 minutes, fresh air!", .physical, .dexterity),
        ("Workout Together", "Let's get those gains!", .physical, .strength),
        ("Run Together", "Cardio day!", .physical, .dexterity),
        ("Read a Chapter", "Feed that wisdom stat!", .mental, nil),
        ("Study Session", "Knowledge is power!", .mental, nil),
        ("Yoga Together", "Stretch and breathe", .physical, .dexterity),
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundTop").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Quick Templates
                        quickTemplatesSection
                        
                        // Custom Task Form
                        customTaskSection
                        
                        // Partner Message
                        partnerMessageSection
                        
                        // Assignment Options
                        assignmentSection
                        
                        // Create Button
                        createButton
                    }
                    .padding()
                }
            }
            .navigationTitle("Assign to Partner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color("AccentGold"))
                }
            }
            .onAppear { }
        }
    }
    
    // MARK: - Quick Templates
    
    private var quickTemplatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Assign")
                .font(.custom("Avenir-Heavy", size: 16))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(quickTemplates, id: \.title) { template in
                        Button(action: {
                            title = template.title
                            description = template.desc
                            selectedCategory = template.category
                            if let focus = template.focus {
                                selectedPhysicalFocus = focus
                            }
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Image(systemName: template.category.icon)
                                    .foregroundColor(Color(template.category.color))
                                    .font(.callout)
                                
                                Text(template.title)
                                    .font(.custom("Avenir-Heavy", size: 13))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                
                                Text(template.category.rawValue)
                                    .font(.custom("Avenir-Medium", size: 11))
                                    .foregroundColor(Color(template.category.color))
                            }
                            .padding(12)
                            .frame(width: 130, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color("CardBackground"))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        title == template.title ? Color(template.category.color) : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    // MARK: - Custom Task
    
    private var customTaskSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Task Details")
                .font(.custom("Avenir-Heavy", size: 16))
            
            VStack(spacing: 12) {
                TextField("Task Title", text: $title)
                    .font(.custom("Avenir-Medium", size: 16))
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.secondary.opacity(0.1))
                    )
                
                TextField("Description (optional)", text: $description, axis: .vertical)
                    .font(.custom("Avenir-Medium", size: 14))
                    .lineLimit(2...4)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.secondary.opacity(0.1))
                    )
                
                // Category Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category")
                        .font(.custom("Avenir-Medium", size: 13))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        ForEach(TaskCategory.allCases, id: \.self) { category in
                            CategoryButton(
                                category: category,
                                isSelected: selectedCategory == category,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                    
                    if selectedCategory == .physical {
                        Text("Focus")
                            .font(.custom("Avenir-Medium", size: 13))
                            .foregroundColor(.secondary)
                        
                        Picker("Focus", selection: $selectedPhysicalFocus) {
                            ForEach(PhysicalActivityFocus.activeCases, id: \.self) { focus in
                                Text(focus.rawValue).tag(focus)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                
                // Reward preview
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                        Text("+\(GameTask.baseEXP) EXP")
                    }
                    .font(.custom("Avenir-Heavy", size: 13))
                    .foregroundColor(Color("AccentGold"))
                    
                    Text("+")
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "heart.circle.fill")
                        Text("+\(GameEngine.bondEXPForPartnerTask) Bond EXP")
                    }
                    .font(.custom("Avenir-Heavy", size: 13))
                    .foregroundColor(Color("AccentPink"))
                    
                    Text("+ CHA")
                        .font(.custom("Avenir-Heavy", size: 13))
                        .foregroundColor(Color("StatCharisma"))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("CardBackground"))
            )
        }
    }
    
    // MARK: - Partner Message
    
    private var partnerMessageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "message.fill")
                    .foregroundColor(Color("AccentPurple"))
                Text("Message for Partner")
                    .font(.custom("Avenir-Heavy", size: 16))
            }
            
            TextField("Add a fun note... (optional)", text: $partnerMessage, axis: .vertical)
                .font(.custom("Avenir-Medium", size: 14))
                .lineLimit(2...3)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("CardBackground"))
                )
            
            // Quick message suggestions
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(quickMessages, id: \.self) { msg in
                        Button(action: { partnerMessage = msg }) {
                            Text(msg)
                                .font(.custom("Avenir-Medium", size: 12))
                                .foregroundColor(Color("AccentPurple"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color("AccentPurple").opacity(0.1))
                                )
                        }
                    }
                }
            }
        }
    }
    
    private let quickMessages = [
        "Pretty please?",
        "You're the best!",
        "I believe in you!",
        "Tag, you're it!",
        "Your quest awaits!",
        "For bonus EXP!"
    ]
    
    // MARK: - Assignment Section
    
    private var assignmentSection: some View {
        VStack(spacing: 12) {
            Toggle(isOn: $isOnDutyBoard) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Also add to Duty Board")
                        .font(.custom("Avenir-Medium", size: 14))
                    Text("Either of you can complete this task")
                        .font(.custom("Avenir-Medium", size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .tint(Color("AccentGold"))
            
            Toggle(isOn: $hasDueDate) {
                Text("Set Due Date")
                    .font(.custom("Avenir-Medium", size: 14))
            }
            .tint(Color("AccentGold"))
            
            if hasDueDate {
                DatePicker(
                    "Due Date",
                    selection: $dueDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .font(.custom("Avenir-Medium", size: 14))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
    }
    
    // MARK: - Create Button
    
    private var createButton: some View {
        Button(action: createAndAssignTask) {
            HStack {
                Image(systemName: "paperplane.fill")
                Text("Send to Partner")
            }
            .font(.custom("Avenir-Heavy", size: 16))
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isValid ?
                LinearGradient(
                    colors: [Color("AccentPink"), Color("AccentPurple")],
                    startPoint: .leading,
                    endPoint: .trailing
                ) :
                LinearGradient(
                    colors: [Color.gray, Color.gray],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!isValid)
    }
    
    // MARK: - Create Task
    
    private func createAndAssignTask() {
        guard let character = character else { return }
        
        let task = GameTask(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.isEmpty ? nil : description,
            category: selectedCategory,
            physicalFocus: selectedCategory == .physical ? selectedPhysicalFocus : nil,
            createdBy: character.id,
            assignedTo: character.partnerCharacterID,
            isOnDutyBoard: isOnDutyBoard,
            dueDate: hasDueDate ? dueDate : nil,
            partnerMessage: partnerMessage.isEmpty ? nil : partnerMessage,
            isFromPartner: true,
            verificationType: selectedVerification
        )
        
        modelContext.insert(task)
        
        // Create interaction record
        if let bond = bond {
            let interaction = PartnerInteraction(
                type: .taskAssigned,
                message: "Assigned: \(task.title)",
                fromCharacterID: character.id
            )
            modelContext.insert(interaction)
            bond.gainBondEXP(2) // Small bond EXP for assigning
        }
        
        dismiss()
    }
}

#Preview {
    AssignTaskView()
        .environmentObject(GameEngine())
}
