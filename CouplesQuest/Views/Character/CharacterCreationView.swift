import SwiftUI
import SwiftData
import PhotosUI

struct CharacterCreationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var gameEngine: GameEngine
    
    /// When true, the view is presented as mandatory onboarding (no Cancel button,
    /// syncs character to Supabase profile on completion).
    var isOnboarding: Bool = false
    
    // MARK: - State
    
    @State private var currentStep: CreationStep = .chooseClass
    @State private var selectedClass: CharacterClass?
    @State private var selectedZodiac: ZodiacSign?
    @State private var bonusPoints: [StatType: Int] = [:]
    @State private var remainingBonusPoints: Int = 5
    @State private var characterName: String = ""
    @State private var selectedAvatarIcon: String = "person.fill"
    @State private var selectedAvatarImageData: Data?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isLoadingPhoto: Bool = false
    @State private var isCreating: Bool = false
    @State private var showError: Bool = false
    @State private var showOverwriteWarning: Bool = false
    
    enum CreationStep: Int, CaseIterable {
        case chooseClass = 0
        case chooseZodiac = 1
        case allocateStats = 2
        case nameAvatar = 3
        case review = 4
        
        var title: String {
            switch self {
            case .chooseClass: return "Choose Your Class"
            case .chooseZodiac: return "Choose Your Sign"
            case .allocateStats: return "Allocate Stats"
            case .nameAvatar: return "Name & Avatar"
            case .review: return "Review"
            }
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case .chooseClass: return selectedClass != nil
        case .chooseZodiac: return selectedZodiac != nil
        case .allocateStats: return remainingBonusPoints == 0
        case .nameAvatar:
            let trimmed = characterName.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.count >= 2 && trimmed.count <= 20
        case .review: return true
        }
    }
    
    // MARK: - Computed Stats
    
    private func statValue(for type: StatType) -> Int {
        let base = selectedClass?.baseStats.value(for: type) ?? 5
        let zodiacBonus = (selectedZodiac?.boostedStat == type) ? 2 : 0
        let bonus = bonusPoints[type] ?? 0
        return base + zodiacBonus + bonus
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color("BackgroundTop"), Color("BackgroundBottom")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress indicator
                    StepProgressBar(
                        currentStep: currentStep.rawValue,
                        totalSteps: CreationStep.allCases.count
                    )
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
                    
                    // Step title
                    VStack(spacing: 4) {
                        if isOnboarding && currentStep == .chooseClass {
                            Text("Welcome, Adventurer!")
                                .font(.custom("Avenir-Medium", size: 14))
                                .foregroundColor(Color("AccentGold"))
                        }
                        Text(currentStep.title)
                            .font(.custom("Avenir-Heavy", size: 28))
                    }
                    .padding(.top, 16)
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 24) {
                            switch currentStep {
                            case .chooseClass:
                                classSelectionStep
                            case .chooseZodiac:
                                zodiacSelectionStep
                            case .allocateStats:
                                statAllocationStep
                            case .nameAvatar:
                                nameAvatarStep
                            case .review:
                                reviewStep
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                    }
                    
                    Spacer(minLength: 0)
                    
                    // Navigation buttons
                    navigationButtons
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isOnboarding {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { dismiss() }
                            .foregroundColor(Color("AccentGold"))
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Failed to create character. Please try again.")
            }
            .alert("Character Already Exists", isPresented: $showOverwriteWarning) {
                Button("Overwrite", role: .destructive) {
                    if let charClass = selectedClass, let zodiac = selectedZodiac {
                        isCreating = true
                        finalizeCharacterCreation(charClass: charClass, zodiac: zodiac, overwriteCloud: true)
                    }
                }
                Button("Cancel", role: .cancel) {
                    isCreating = false
                }
            } message: {
                Text("A character already exists on your account. Creating a new one will overwrite your cloud save. Are you sure?")
            }
        }
    }
    
    // MARK: - Step 1: Class Selection
    
    private var classSelectionStep: some View {
        VStack(spacing: 16) {
            Text("Every great quest begins with a calling")
                .font(.custom("Avenir-Medium", size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            ForEach(CharacterClass.starters, id: \.self) { charClass in
                ClassCard(
                    characterClass: charClass,
                    isSelected: selectedClass == charClass,
                    onSelect: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedClass = charClass
                            // Reset avatar to first class icon
                            if let firstIcon = AvatarPickerView.icons(for: charClass).first(where: { $0.classAffinity == charClass }) {
                                selectedAvatarIcon = firstIcon.symbol
                            }
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - Step 2: Zodiac Selection
    
    private var zodiacSelectionStep: some View {
        VStack(spacing: 16) {
            Text("The stars shape your destiny")
                .font(.custom("Avenir-Medium", size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(ZodiacSign.allCases, id: \.self) { sign in
                    ZodiacCard(
                        sign: sign,
                        isSelected: selectedZodiac == sign,
                        onSelect: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedZodiac = sign
                            }
                        }
                    )
                }
            }
            
            // Selected zodiac detail
            if let zodiac = selectedZodiac {
                VStack(spacing: 8) {
                    Text(zodiac.rawValue)
                        .font(.custom("Avenir-Heavy", size: 20))
                    
                    Text(zodiac.dateRange)
                        .font(.custom("Avenir-Medium", size: 14))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: zodiac.boostedStat.icon)
                            .foregroundColor(Color(zodiac.boostedStat.color))
                        Text("+2 \(zodiac.boostedStat.rawValue)")
                            .font(.custom("Avenir-Heavy", size: 16))
                            .foregroundColor(Color(zodiac.boostedStat.color))
                    }
                    
                    Text("Element: \(zodiac.element)")
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color("CardBackground"))
                )
            }
        }
    }
    
    // MARK: - Step 3: Stat Allocation
    
    private var statAllocationStep: some View {
        VStack(spacing: 16) {
            Text("Distribute 5 bonus points to customize your hero")
                .font(.custom("Avenir-Medium", size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Remaining points
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundColor(Color("AccentGold"))
                Text("\(remainingBonusPoints) point\(remainingBonusPoints == 1 ? "" : "s") remaining")
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(remainingBonusPoints > 0 ? Color("AccentGold") : Color("AccentGreen"))
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        remainingBonusPoints > 0
                            ? Color("AccentGold").opacity(0.15)
                            : Color("AccentGreen").opacity(0.15)
                    )
            )
            
            ForEach(StatType.allocatable, id: \.self) { statType in
                StatAllocationRow(
                    statType: statType,
                    baseValue: selectedClass?.baseStats.value(for: statType) ?? 5,
                    zodiacBonus: (selectedZodiac?.boostedStat == statType) ? 2 : 0,
                    bonusPoints: bonusPoints[statType] ?? 0,
                    canAdd: remainingBonusPoints > 0 && (bonusPoints[statType] ?? 0) < 3,
                    canRemove: (bonusPoints[statType] ?? 0) > 0,
                    onAdd: {
                        bonusPoints[statType, default: 0] += 1
                        remainingBonusPoints -= 1
                    },
                    onRemove: {
                        bonusPoints[statType, default: 0] -= 1
                        remainingBonusPoints += 1
                    }
                )
            }
            
            // Luck shown as read-only
            if let selectedClass = selectedClass {
                HStack(spacing: 12) {
                    Image(systemName: StatType.luck.icon)
                        .foregroundColor(Color(StatType.luck.color))
                        .frame(width: 24)
                    
                    Text(StatType.luck.rawValue)
                        .font(.custom("Avenir-Heavy", size: 15))
                        .frame(width: 80, alignment: .leading)
                    
                    Text("\(selectedClass.baseStats.value(for: .luck))")
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(Color(StatType.luck.color))
                    
                    Spacer()
                    
                    Text("Raised through gameplay")
                        .font(.custom("Avenir-Medium", size: 11))
                        .foregroundColor(.secondary)
                        .italic()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(StatType.luck.color).opacity(0.08))
                )
            }
            
            Text("Max +3 bonus to any single stat")
                .font(.custom("Avenir-Medium", size: 12))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Step 4: Name & Avatar
    
    private var nameAvatarStep: some View {
        VStack(spacing: 24) {
            // Avatar Preview
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color("AccentGold").opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                
                if let imageData = selectedAvatarImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else if AvatarPickerView.isPixelArt(selectedAvatarIcon) {
                    Image(selectedAvatarIcon)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color("AccentGold").opacity(0.3), Color("AccentPurple").opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: selectedAvatarIcon)
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color("AccentGold"), Color("AccentOrange")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            
            // Upload Photo
            VStack(spacing: 12) {
                Text("Use Your Photo")
                    .font(.custom("Avenir-Heavy", size: 14))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    PhotosPicker(
                        selection: $selectedPhotoItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        HStack(spacing: 6) {
                            if isLoadingPhoto {
                                ProgressView()
                                    .tint(.black)
                            } else {
                                Image(systemName: "photo.on.rectangle.angled")
                            }
                            Text(selectedAvatarImageData != nil ? "Change Photo" : "Upload Photo")
                                .font(.custom("Avenir-Heavy", size: 14))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [Color("AccentGold"), Color("AccentOrange")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                    }
                    
                    if selectedAvatarImageData != nil {
                        Button {
                            selectedAvatarImageData = nil
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark.circle.fill")
                                Text("Remove")
                                    .font(.custom("Avenir-Heavy", size: 14))
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                isLoadingPhoto = true
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        let maxDim: CGFloat = 512
                        let size = uiImage.size
                        let maxSide = max(size.width, size.height)
                        let resized: UIImage
                        if maxSide > maxDim {
                            let scale = maxDim / maxSide
                            let newSize = CGSize(width: size.width * scale, height: size.height * scale)
                            let renderer = UIGraphicsImageRenderer(size: newSize)
                            resized = renderer.image { _ in
                                uiImage.draw(in: CGRect(origin: .zero, size: newSize))
                            }
                        } else {
                            resized = uiImage
                        }
                        if let jpegData = resized.jpegData(compressionQuality: 0.8) {
                            selectedAvatarImageData = jpegData
                        }
                    }
                    isLoadingPhoto = false
                    selectedPhotoItem = nil
                }
            }
            
            // Pixel Art Portrait Selection
            VStack(spacing: 12) {
                Text("Or Choose a Portrait")
                    .font(.custom("Avenir-Heavy", size: 14))
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(AvatarPickerView.pixelArtAvatars, id: \.symbol) { avatar in
                        let isSelected = selectedAvatarIcon == avatar.symbol && selectedAvatarImageData == nil
                        Button(action: {
                            selectedAvatarIcon = avatar.symbol
                            selectedAvatarImageData = nil
                        }) {
                            ZStack {
                                Image(avatar.symbol)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 64, height: 64)
                                    .clipShape(Circle())
                                
                                if isSelected {
                                    Circle()
                                        .stroke(Color("AccentGold"), lineWidth: 3)
                                        .frame(width: 68, height: 68)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("CardBackground").opacity(0.5))
            )
            
            // Avatar Icon Selection
            VStack(spacing: 12) {
                Text("Or Choose an Icon")
                    .font(.custom("Avenir-Heavy", size: 14))
                    .foregroundColor(.secondary)
                
                let filteredIcons = AvatarPickerView.icons(for: selectedClass)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(filteredIcons, id: \.symbol) { avatarIcon in
                        Button(action: {
                            selectedAvatarIcon = avatarIcon.symbol
                            selectedAvatarImageData = nil // Clear photo when picking an icon
                        }) {
                            ZStack {
                                Circle()
                                    .fill(
                                        selectedAvatarIcon == avatarIcon.symbol && selectedAvatarImageData == nil
                                            ? Color("AccentGold").opacity(0.3)
                                            : Color("CardBackground")
                                    )
                                    .frame(width: 56, height: 56)
                                
                                if selectedAvatarIcon == avatarIcon.symbol && selectedAvatarImageData == nil {
                                    Circle()
                                        .stroke(Color("AccentGold"), lineWidth: 2)
                                        .frame(width: 56, height: 56)
                                }
                                
                                Image(systemName: avatarIcon.symbol)
                                    .font(.system(size: 24))
                                    .foregroundColor(
                                        selectedAvatarIcon == avatarIcon.symbol && selectedAvatarImageData == nil
                                            ? Color("AccentGold")
                                            : .secondary
                                    )
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("CardBackground").opacity(0.5))
            )
            
            // Name Input
            VStack(spacing: 12) {
                TextField("Enter your name...", text: $characterName)
                    .font(.custom("Avenir-Medium", size: 20))
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color("CardBackground"))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                characterName.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
                                    ? Color("AccentGold") : Color.clear,
                                lineWidth: 2
                            )
                    )
                    .onChange(of: characterName) { _, newValue in
                        // Enforce max length
                        if newValue.count > 20 {
                            characterName = String(newValue.prefix(20))
                        }
                    }
                
                HStack {
                    if !characterName.isEmpty && characterName.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 {
                        Text("Name must be at least 2 characters")
                            .font(.custom("Avenir-Medium", size: 12))
                            .foregroundColor(.red)
                    }
                    Spacer()
                    Text("\(characterName.count)/20")
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(characterName.count >= 20 ? Color("AccentOrange") : .secondary)
                }
            }
        }
    }
    
    // MARK: - Step 5: Review
    
    private var reviewStep: some View {
        VStack(spacing: 20) {
            // Character preview
            VStack(spacing: 12) {
                ZStack {
                    if AvatarPickerView.isPixelArt(selectedAvatarIcon) {
                        Image(selectedAvatarIcon)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color("AccentGold").opacity(0.3), Color("AccentPurple").opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: selectedAvatarIcon)
                            .font(.system(size: 50))
                            .foregroundColor(Color("AccentGold"))
                    }
                }
                
                Text(characterName)
                    .font(.custom("Avenir-Heavy", size: 24))
                
                if let charClass = selectedClass {
                    HStack(spacing: 6) {
                        Image(systemName: charClass.icon)
                        Text(charClass.rawValue)
                    }
                    .font(.custom("Avenir-Medium", size: 16))
                    .foregroundColor(Color("AccentPurple"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color("AccentPurple").opacity(0.2))
                    )
                }
                
                if let zodiac = selectedZodiac {
                    HStack(spacing: 6) {
                        Image(systemName: zodiac.icon)
                        Text(zodiac.rawValue)
                        Text("(\(zodiac.element))")
                            .foregroundColor(.secondary)
                    }
                    .font(.custom("Avenir-Medium", size: 14))
                    .foregroundColor(Color("AccentGold"))
                }
            }
            
            // Final stats
            VStack(spacing: 12) {
                Text("Final Stats")
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(StatType.allCases, id: \.self) { stat in
                        VStack(spacing: 4) {
                            Image(systemName: stat.icon)
                                .foregroundColor(Color(stat.color))
                            Text("\(statValue(for: stat))")
                                .font(.custom("Avenir-Heavy", size: 20))
                            Text(stat.rawValue)
                                .font(.custom("Avenir-Medium", size: 11))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color("CardBackground").opacity(0.5))
                        )
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("CardBackground"))
            )
        }
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            // Back button
            if currentStep.rawValue > 0 {
                Button(action: goBack) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(Color("AccentGold"))
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color("AccentGold"), lineWidth: 2)
                    )
                }
            }
            
            // Next / Create button
            Button(action: {
                if currentStep == .review {
                    createCharacter()
                } else {
                    goForward()
                }
            }) {
                HStack(spacing: 8) {
                    if isCreating {
                        ProgressView()
                            .tint(.black)
                    } else if currentStep == .review {
                        Image(systemName: "sparkles")
                        Text(isOnboarding ? "Start Your Adventure" : "Begin Your Quest")
                    } else {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                }
                .font(.custom("Avenir-Heavy", size: 16))
                .foregroundColor(canProceed ? .black : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: canProceed
                            ? [Color("AccentGold"), Color("AccentOrange")]
                            : [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!canProceed || isCreating)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
        .padding(.top, 8)
        .background(
            LinearGradient(
                colors: [Color("BackgroundBottom").opacity(0), Color("BackgroundBottom")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
    
    // MARK: - Actions
    
    private func goForward() {
        guard let nextStep = CreationStep(rawValue: currentStep.rawValue + 1) else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = nextStep
        }
    }
    
    private func goBack() {
        guard let prevStep = CreationStep(rawValue: currentStep.rawValue - 1) else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = prevStep
        }
    }
    
    private func createCharacter() {
        guard let charClass = selectedClass,
              let zodiac = selectedZodiac else { return }
        
        isCreating = true
        
        if isOnboarding {
            // Safety check: verify no cloud character exists before creating a new one.
            // This prevents the "signed in on second device → accidentally overwrote my save" scenario.
            Task {
                do {
                    if let existingSnapshot = try await SupabaseService.shared.fetchCharacterData() {
                        // Cloud data exists! Warn the user before overwriting.
                        print("Cloud character already exists: \(existingSnapshot.name) Lv.\(existingSnapshot.level)")
                        isCreating = false
                        showOverwriteWarning = true
                        return
                    }
                } catch {
                    // Network error — proceed with creation anyway (first-time user or offline)
                    print("Could not check cloud for existing character: \(error)")
                }
                
                // No cloud data found (or check failed) — safe to create
                finalizeCharacterCreation(charClass: charClass, zodiac: zodiac)
            }
        } else {
            // Not onboarding (e.g. re-roll) — no cloud check needed
            finalizeCharacterCreation(charClass: charClass, zodiac: zodiac)
        }
    }
    
    /// Actually build and save the character after all safety checks pass.
    private func finalizeCharacterCreation(charClass: CharacterClass, zodiac: ZodiacSign, overwriteCloud: Bool = false) {
        let trimmedName = characterName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Build bonus stats object (luck cannot be allocated manually)
        let bonus = Stats(
            strength: bonusPoints[.strength] ?? 0,
            wisdom: bonusPoints[.wisdom] ?? 0,
            charisma: bonusPoints[.charisma] ?? 0,
            dexterity: bonusPoints[.dexterity] ?? 0,
            luck: 0,
            defense: bonusPoints[.defense] ?? 0
        )
        
        let character = gameEngine.createCharacter(
            name: trimmedName,
            characterClass: charClass,
            zodiacSign: zodiac,
            bonusStats: bonus,
            avatarIcon: selectedAvatarIcon,
            avatarImageData: selectedAvatarImageData
        )
        
        // Stamp the Supabase user ID so this character is tied to this account
        character.supabaseUserID = SupabaseService.shared.currentUserID?.uuidString
        
        modelContext.insert(character)
        
        do {
            try modelContext.save()
            
            if isOnboarding {
                // Sync full character snapshot to Supabase so
                // the character can be restored on another device.
                // Navigation is handled by AuthGateView's @Query detecting
                // the new local character — no dismiss needed.
                Task {
                    do {
                        try await SupabaseService.shared.syncCharacterData(character)
                        print("✅ New character synced to cloud: \(character.name)")
                    } catch {
                        print("❌ Failed to sync new character to cloud: \(error)")
                        // Retry with updateProfile as fallback to ensure character_name reaches Supabase
                        try? await Task.sleep(for: .seconds(2))
                        try? await SupabaseService.shared.updateProfile(
                            characterName: character.name,
                            characterClass: character.characterClass?.rawValue,
                            level: character.level,
                            avatarName: character.avatarIcon
                        )
                    }
                }
            } else {
                dismiss()
            }
        } catch {
            showError = true
            isCreating = false
        }
    }
}

// MARK: - Step Progress Bar

struct StepProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Capsule()
                    .fill(
                        step <= currentStep
                            ? Color("AccentGold")
                            : Color.secondary.opacity(0.3)
                    )
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
    }
}

// MARK: - Class Card

struct ClassCard: View {
    let characterClass: CharacterClass
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Class icon
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                                ? Color("AccentGold").opacity(0.3)
                                : Color.secondary.opacity(0.1)
                        )
                        .frame(width: 64, height: 64)
                    
                    if isSelected {
                        Circle()
                            .stroke(Color("AccentGold"), lineWidth: 3)
                            .frame(width: 64, height: 64)
                    }
                    
                    Image(systemName: characterClass.icon)
                        .font(.system(size: 28))
                        .foregroundColor(isSelected ? Color("AccentGold") : .secondary)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(characterClass.rawValue)
                        .font(.custom("Avenir-Heavy", size: 20))
                        .foregroundColor(isSelected ? Color("AccentGold") : .primary)
                    
                    Text(characterClass.description)
                        .font(.custom("Avenir-Medium", size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    // Base stat preview
                    HStack(spacing: 8) {
                        ForEach(StatType.allCases, id: \.self) { stat in
                            HStack(spacing: 2) {
                                Image(systemName: stat.icon)
                                    .font(.system(size: 10))
                                    .foregroundColor(Color(stat.color))
                                Text("\(characterClass.baseStats.value(for: stat))")
                                    .font(.custom("Avenir-Heavy", size: 11))
                                    .foregroundColor(Color(stat.color))
                            }
                        }
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color("AccentGold"))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("CardBackground"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color("AccentGold") : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Zodiac Card

struct ZodiacCard: View {
    let sign: ZodiacSign
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                                ? Color("AccentGold").opacity(0.3)
                                : Color.secondary.opacity(0.1)
                        )
                        .frame(width: 52, height: 52)
                    
                    if isSelected {
                        Circle()
                            .stroke(Color("AccentGold"), lineWidth: 2)
                            .frame(width: 52, height: 52)
                    }
                    
                    Image(systemName: sign.icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? Color("AccentGold") : .secondary)
                }
                
                Text(sign.rawValue)
                    .font(.custom("Avenir-Heavy", size: 11))
                    .foregroundColor(isSelected ? Color("AccentGold") : .primary)
                
                HStack(spacing: 2) {
                    Image(systemName: sign.boostedStat.icon)
                        .font(.system(size: 8))
                    Text("+2")
                        .font(.custom("Avenir-Heavy", size: 9))
                }
                .foregroundColor(Color(sign.boostedStat.color))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("CardBackground").opacity(isSelected ? 0.8 : 0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color("AccentGold") : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stat Allocation Row

struct StatAllocationRow: View {
    let statType: StatType
    let baseValue: Int
    let zodiacBonus: Int
    let bonusPoints: Int
    let canAdd: Bool
    let canRemove: Bool
    let onAdd: () -> Void
    let onRemove: () -> Void
    
    private var totalValue: Int {
        baseValue + zodiacBonus + bonusPoints
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(statType.color).opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: statType.icon)
                    .foregroundColor(Color(statType.color))
            }
            
            // Name
            VStack(alignment: .leading, spacing: 2) {
                Text(statType.rawValue)
                    .font(.custom("Avenir-Heavy", size: 15))
                
                HStack(spacing: 4) {
                    Text("Base: \(baseValue)")
                        .font(.custom("Avenir-Medium", size: 11))
                        .foregroundColor(.secondary)
                    
                    if zodiacBonus > 0 {
                        Text("+\(zodiacBonus)⭐")
                            .font(.custom("Avenir-Medium", size: 11))
                            .foregroundColor(Color("AccentGold"))
                    }
                    
                    if bonusPoints > 0 {
                        Text("+\(bonusPoints)")
                            .font(.custom("Avenir-Heavy", size: 11))
                            .foregroundColor(Color("AccentGreen"))
                    }
                }
            }
            
            Spacer()
            
            // Total
            Text("\(totalValue)")
                .font(.custom("Avenir-Heavy", size: 22))
                .foregroundColor(Color(statType.color))
                .frame(width: 36)
            
            // +/- buttons
            HStack(spacing: 8) {
                Button(action: onRemove) {
                    ZStack {
                        Circle()
                            .fill(canRemove ? Color.red.opacity(0.2) : Color.secondary.opacity(0.1))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "minus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(canRemove ? .red : .secondary.opacity(0.5))
                    }
                }
                .buttonStyle(.plain)
                .disabled(!canRemove)
                
                Button(action: onAdd) {
                    ZStack {
                        Circle()
                            .fill(canAdd ? Color("AccentGold").opacity(0.2) : Color.secondary.opacity(0.1))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(canAdd ? Color("AccentGold") : .secondary.opacity(0.5))
                    }
                }
                .buttonStyle(.plain)
                .disabled(!canAdd)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("CardBackground"))
        )
    }
}

#Preview {
    CharacterCreationView()
        .environmentObject(GameEngine())
}
