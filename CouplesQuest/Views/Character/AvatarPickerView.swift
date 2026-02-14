import SwiftUI
import PhotosUI

struct AvatarPickerView: View {
    @Bindable var character: PlayerCharacter
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isLoadingPhoto = false
    
    // MARK: - Pixel Art Portraits
    
    static let pixelArtAvatars: [AvatarIcon] = [
        AvatarIcon(symbol: "avatar_01", name: "Amara", requiredLevel: 1, isPixelArt: true),
        AvatarIcon(symbol: "avatar_02", name: "Bjorn", requiredLevel: 1, isPixelArt: true),
        AvatarIcon(symbol: "avatar_03", name: "Mei", requiredLevel: 1, isPixelArt: true),
        AvatarIcon(symbol: "avatar_04", name: "Carlos", requiredLevel: 1, isPixelArt: true),
        AvatarIcon(symbol: "avatar_05", name: "Malik", requiredLevel: 1, isPixelArt: true),
        AvatarIcon(symbol: "avatar_06", name: "Elara", requiredLevel: 1, isPixelArt: true),
        AvatarIcon(symbol: "avatar_07", name: "Arjun", requiredLevel: 1, isPixelArt: true),
        AvatarIcon(symbol: "avatar_08", name: "Zara", requiredLevel: 1, isPixelArt: true),
        AvatarIcon(symbol: "avatar_09", name: "Jin", requiredLevel: 1, isPixelArt: true),
        AvatarIcon(symbol: "avatar_10", name: "Nia", requiredLevel: 1, isPixelArt: true),
        AvatarIcon(symbol: "avatar_11", name: "Liam", requiredLevel: 1, isPixelArt: true),
        AvatarIcon(symbol: "avatar_12", name: "Rosa", requiredLevel: 1, isPixelArt: true),
        AvatarIcon(symbol: "avatar_13", name: "Koda", requiredLevel: 1, isPixelArt: true),
        AvatarIcon(symbol: "avatar_14", name: "Yuki", requiredLevel: 1, isPixelArt: true),
        AvatarIcon(symbol: "avatar_15", name: "Elder", requiredLevel: 1, isPixelArt: true),
        AvatarIcon(symbol: "avatar_16", name: "Diego", requiredLevel: 1, isPixelArt: true),
        AvatarIcon(symbol: "avatar_17", name: "Layla", requiredLevel: 1, isPixelArt: true),
        AvatarIcon(symbol: "avatar_18", name: "Takeshi", requiredLevel: 1, isPixelArt: true),
        AvatarIcon(symbol: "avatar_19", name: "Adira", requiredLevel: 1, isPixelArt: true),
        AvatarIcon(symbol: "avatar_20", name: "Cael", requiredLevel: 1, isPixelArt: true),
        AvatarIcon(symbol: "avatar_21", name: "Priya", requiredLevel: 1, isPixelArt: true),
    ]
    
    // MARK: - SF Symbol Icons
    
    static let allAvatarIcons: [AvatarIcon] = [
        // Universal (available to all classes)
        AvatarIcon(symbol: "person.fill", name: "Adventurer", requiredLevel: 1),
        AvatarIcon(symbol: "figure.walk", name: "Wanderer", requiredLevel: 1),
        AvatarIcon(symbol: "crown.fill", name: "Royalty", requiredLevel: 1),
        AvatarIcon(symbol: "figure.hiking", name: "Explorer", requiredLevel: 1),
        // Warrior icons
        AvatarIcon(symbol: "shield.lefthalf.filled", name: "Guardian", requiredLevel: 1, classAffinity: .warrior),
        AvatarIcon(symbol: "figure.martial.arts", name: "Fighter", requiredLevel: 1, classAffinity: .warrior),
        AvatarIcon(symbol: "flame.fill", name: "Inferno", requiredLevel: 1, classAffinity: .warrior),
        AvatarIcon(symbol: "bolt.fill", name: "Thunder", requiredLevel: 1, classAffinity: .warrior),
        // Mage icons
        AvatarIcon(symbol: "wand.and.stars", name: "Sorcerer", requiredLevel: 1, classAffinity: .mage),
        AvatarIcon(symbol: "sparkles", name: "Arcane", requiredLevel: 1, classAffinity: .mage),
        AvatarIcon(symbol: "moon.stars.fill", name: "Stargazer", requiredLevel: 1, classAffinity: .mage),
        AvatarIcon(symbol: "book.closed.fill", name: "Scholar", requiredLevel: 1, classAffinity: .mage),
        // Archer icons
        AvatarIcon(symbol: "arrow.up.right.circle.fill", name: "Marksman", requiredLevel: 1, classAffinity: .archer),
        AvatarIcon(symbol: "scope", name: "Sniper", requiredLevel: 1, classAffinity: .archer),
        AvatarIcon(symbol: "leaf.fill", name: "Ranger", requiredLevel: 1, classAffinity: .archer),
        AvatarIcon(symbol: "wind", name: "Gale", requiredLevel: 1, classAffinity: .archer),
    ]
    
    /// Filter icons for a specific class (returns class-specific + universal)
    static func icons(for characterClass: CharacterClass?) -> [AvatarIcon] {
        guard let charClass = characterClass else { return allAvatarIcons }
        return allAvatarIcons.filter { $0.classAffinity == nil || $0.classAffinity == charClass }
    }
    
    /// Check if an icon string refers to a pixel art asset
    static func isPixelArt(_ iconName: String) -> Bool {
        iconName.hasPrefix("avatar_")
    }
    
    // MARK: - Avatar Frames
    
    static let allAvatarFrames: [AvatarFrame] = [
        AvatarFrame(id: "default", name: "Default", requiredLevel: 1, colors: [.secondary.opacity(0.3)]),
        AvatarFrame(id: "bronze", name: "Bronze Ring", requiredLevel: 10, colors: [Color("AccentOrange").opacity(0.6)]),
        AvatarFrame(id: "silver", name: "Silver Ring", requiredLevel: 25, colors: [Color.gray]),
        AvatarFrame(id: "gold", name: "Gold Ring", requiredLevel: 50, colors: [Color("AccentGold")]),
        AvatarFrame(id: "rebirth", name: "Rebirth Star", requiredLevel: 100, colors: [Color("AccentGold"), Color("AccentPurple")]),
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color("BackgroundTop"), Color("BackgroundBottom")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Preview
                        AvatarPreview(
                            icon: character.avatarIcon,
                            frame: character.avatarFrame,
                            size: 120,
                            character: character
                        )
                        .padding(.top, 20)
                        
                        // Upload Photo Section
                        VStack(spacing: 12) {
                            Text("Use Your Photo")
                                .font(.custom("Avenir-Heavy", size: 18))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 16) {
                                PhotosPicker(
                                    selection: $selectedPhotoItem,
                                    matching: .images,
                                    photoLibrary: .shared()
                                ) {
                                    HStack(spacing: 8) {
                                        if isLoadingPhoto {
                                            ProgressView()
                                                .tint(Color("AccentGold"))
                                        } else {
                                            Image(systemName: "photo.on.rectangle.angled")
                                        }
                                        Text(character.avatarImageData != nil ? "Change Photo" : "Upload Photo")
                                            .font(.custom("Avenir-Heavy", size: 14))
                                    }
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(
                                        LinearGradient(
                                            colors: [Color("AccentGold"), Color("AccentOrange")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .clipShape(Capsule())
                                }
                                
                                if character.avatarImageData != nil {
                                    Button {
                                        character.avatarImageData = nil
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "xmark.circle.fill")
                                            Text("Remove")
                                                .font(.custom("Avenir-Heavy", size: 14))
                                        }
                                        .foregroundColor(.red)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            Capsule()
                                                .fill(Color.red.opacity(0.1))
                                        )
                                    }
                                }
                                
                                Spacer()
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color("CardBackground"))
                        )
                        .onChange(of: selectedPhotoItem) { _, newItem in
                            guard let newItem else { return }
                            isLoadingPhoto = true
                            Task {
                                if let data = try? await newItem.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data) {
                                    // Compress and resize to a reasonable avatar size
                                    let resized = resizeImage(uiImage, maxDimension: 512)
                                    if let jpegData = resized.jpegData(compressionQuality: 0.8) {
                                        character.avatarImageData = jpegData
                                    }
                                }
                                isLoadingPhoto = false
                                selectedPhotoItem = nil
                            }
                        }
                        
                        // Pixel Art Portraits
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Choose Portrait")
                                .font(.custom("Avenir-Heavy", size: 18))
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                ForEach(Self.pixelArtAvatars, id: \.symbol) { avatar in
                                    let isSelected = character.avatarIcon == avatar.symbol && character.avatarImageData == nil
                                    
                                    Button(action: {
                                        character.avatarIcon = avatar.symbol
                                        character.avatarImageData = nil
                                    }) {
                                        ZStack {
                                            Image(avatar.symbol)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 80, height: 80)
                                                .clipShape(Circle())
                                            
                                            if isSelected {
                                                Circle()
                                                    .stroke(Color("AccentGold"), lineWidth: 3)
                                                    .frame(width: 84, height: 84)
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
                                .fill(Color("CardBackground"))
                        )
                        
                        // Icon Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Choose Icon")
                                .font(.custom("Avenir-Heavy", size: 18))
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                ForEach(Self.allAvatarIcons, id: \.symbol) { avatarIcon in
                                    let isUnlocked = character.level >= avatarIcon.requiredLevel
                                    let isSelected = character.avatarIcon == avatarIcon.symbol && character.avatarImageData == nil
                                    
                                    Button(action: {
                                        if isUnlocked {
                                            character.avatarIcon = avatarIcon.symbol
                                            character.avatarImageData = nil // Clear photo when picking an icon
                                        }
                                    }) {
                                        VStack(spacing: 4) {
                                            ZStack {
                                                Circle()
                                                    .fill(
                                                        isSelected
                                                            ? Color("AccentGold").opacity(0.3)
                                                            : Color.secondary.opacity(0.1)
                                                    )
                                                    .frame(width: 60, height: 60)
                                                
                                                if isSelected {
                                                    Circle()
                                                        .stroke(Color("AccentGold"), lineWidth: 3)
                                                        .frame(width: 60, height: 60)
                                                }
                                                
                                                if isUnlocked {
                                                    Image(systemName: avatarIcon.symbol)
                                                        .font(.system(size: 28))
                                                        .foregroundColor(
                                                            isSelected ? Color("AccentGold") : .primary
                                                        )
                                                } else {
                                                    Image(systemName: "lock.fill")
                                                        .font(.system(size: 20))
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            
                                            Text(avatarIcon.name)
                                                .font(.custom("Avenir-Medium", size: 10))
                                                .foregroundColor(isUnlocked ? .primary : .secondary)
                                            
                                            if !isUnlocked {
                                                Text("Lv\(avatarIcon.requiredLevel)")
                                                    .font(.custom("Avenir-Medium", size: 9))
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .opacity(isUnlocked ? 1.0 : 0.5)
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color("CardBackground"))
                        )
                        
                        // Frame Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Choose Frame")
                                .font(.custom("Avenir-Heavy", size: 18))
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                ForEach(Self.allAvatarFrames, id: \.id) { frame in
                                    // Rebirth frame requires at least 1 rebirth; others use level
                                    let isUnlocked = frame.id == "rebirth"
                                        ? character.rebirthCount > 0
                                        : character.level >= frame.requiredLevel
                                    let isSelected = character.avatarFrame == frame.id
                                    
                                    Button(action: {
                                        if isUnlocked {
                                            character.avatarFrame = frame.id
                                        }
                                    }) {
                                        VStack(spacing: 4) {
                                            ZStack {
                                                Circle()
                                                    .stroke(
                                                        isUnlocked ? frame.colors.first! : Color.secondary.opacity(0.3),
                                                        lineWidth: isSelected ? 4 : 2
                                                    )
                                                    .frame(width: 60, height: 60)
                                                
                                                if isSelected {
                                                    Circle()
                                                        .fill(Color("AccentGold").opacity(0.1))
                                                        .frame(width: 56, height: 56)
                                                    
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 20, weight: .bold))
                                                        .foregroundColor(Color("AccentGold"))
                                                }
                                                
                                                if !isUnlocked {
                                                    Image(systemName: "lock.fill")
                                                        .font(.system(size: 16))
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            
                                            Text(frame.name)
                                                .font(.custom("Avenir-Medium", size: 10))
                                                .foregroundColor(isUnlocked ? .primary : .secondary)
                                            
                                            if !isUnlocked {
                                                Text("Lv\(frame.requiredLevel)")
                                                    .font(.custom("Avenir-Medium", size: 9))
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .opacity(isUnlocked ? 1.0 : 0.5)
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color("CardBackground"))
                        )
                    }
                    .padding()
                }
            }
            .navigationTitle("Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color("AccentGold"))
                }
            }
        }
    }
}

// MARK: - Avatar Preview

struct AvatarPreview: View {
    let icon: String
    let frame: String
    let size: CGFloat
    let character: PlayerCharacter
    /// Optional override for photo data (used during creation before data is saved to model)
    var overrideImageData: Data? = nil
    
    private var frameColor: Color {
        switch frame {
        case "bronze": return Color("AccentOrange").opacity(0.8)
        case "silver": return .gray
        case "gold": return Color("AccentGold")
        case "rebirth": return Color("AccentGold") // fallback; rebirth uses gradient
        default: return .clear
        }
    }
    
    private var hasFrame: Bool {
        frame != "default"
    }
    
    private var isRebirthFrame: Bool {
        frame == "rebirth"
    }
    
    /// Resolve which image data to use: override first, then character's stored data
    private var resolvedImageData: Data? {
        overrideImageData ?? character.avatarImageData
    }
    
    var body: some View {
        ZStack {
            // Frame ring
            if isRebirthFrame {
                // Rebirth Star frame: gold-to-purple gradient ring
                Circle()
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color("AccentGold"),
                                Color("AccentPurple"),
                                Color("AccentGold"),
                                Color("AccentOrange"),
                                Color("AccentGold")
                            ]),
                            center: .center
                        ),
                        lineWidth: 4
                    )
                    .frame(width: size + 8, height: size + 8)
                
                // Rebirth star indicator (small star at top-right)
                if character.rebirthCount > 0 {
                    ZStack {
                        Circle()
                            .fill(Color("CardBackground"))
                            .frame(width: size * 0.28, height: size * 0.28)
                        
                        Image(systemName: "star.fill")
                            .font(.system(size: size * 0.14))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color("AccentGold"), Color("AccentOrange")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        // Rebirth count badge (if > 1)
                        if character.rebirthCount > 1 {
                            Text("\(character.rebirthCount)")
                                .font(.custom("Avenir-Heavy", size: size * 0.08))
                                .foregroundColor(.white)
                                .offset(y: size * 0.06)
                        }
                    }
                    .offset(x: (size + 8) * 0.35, y: -(size + 8) * 0.35)
                }
            } else if hasFrame {
                Circle()
                    .stroke(frameColor, lineWidth: 4)
                    .frame(width: size + 8, height: size + 8)
            }
            
            if let imageData = resolvedImageData,
               let uiImage = UIImage(data: imageData) {
                // Custom photo avatar
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if AvatarPickerView.isPixelArt(icon) {
                // Pixel art portrait avatar
                Image(icon)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                // SF Symbol icon avatar
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color("AccentGold").opacity(0.3), Color("AccentPurple").opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                
                Image(systemName: icon)
                    .font(.system(size: size * 0.5))
                    .foregroundColor(Color("AccentGold"))
            }
        }
    }
}

// MARK: - Image Helpers

/// Resize a UIImage so its longest side is at most maxDimension, preserving aspect ratio.
private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
    let size = image.size
    let maxSide = max(size.width, size.height)
    guard maxSide > maxDimension else { return image }
    
    let scale = maxDimension / maxSide
    let newSize = CGSize(width: size.width * scale, height: size.height * scale)
    
    let renderer = UIGraphicsImageRenderer(size: newSize)
    return renderer.image { _ in
        image.draw(in: CGRect(origin: .zero, size: newSize))
    }
}

// MARK: - Supporting Types

struct AvatarIcon {
    let symbol: String
    let name: String
    let requiredLevel: Int
    let classAffinity: CharacterClass?  // nil = universal
    let isPixelArt: Bool
    
    init(symbol: String, name: String, requiredLevel: Int, classAffinity: CharacterClass? = nil, isPixelArt: Bool = false) {
        self.symbol = symbol
        self.name = name
        self.requiredLevel = requiredLevel
        self.classAffinity = classAffinity
        self.isPixelArt = isPixelArt
    }
}

struct AvatarFrame {
    let id: String
    let name: String
    let requiredLevel: Int
    let colors: [Color]
}

#Preview {
    AvatarPickerView(character: PlayerCharacter(name: "Test"))
}
