import SwiftUI

// MARK: - Loot Reveal Overlay

/// Full-screen loot reveal fanfare with starburst, glow pulse, sparkle particles,
/// and a screen flash. Designed to celebrate item drops from dungeons, missions, etc.
///
/// Usage:
/// ```
/// .fullScreenCover(item: $revealItem) { equipment in
///     LootRevealView(equipment: equipment) { revealItem = nil }
/// }
/// ```
struct LootRevealView: View {
    let equipment: Equipment
    let onDismiss: () -> Void
    
    @State private var phase: Int = 0
    @State private var flashOpacity: Double = 0
    @State private var burstRotation: Double = 0
    @State private var glowScale: CGFloat = 0.3
    @State private var glowOpacity: Double = 0
    @State private var itemScale: CGFloat = 0
    @State private var itemOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var sparkleExpanded: CGFloat = 0
    @State private var sparkleFade: Double = 1
    @State private var dismissHintOpacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            burstLayer
            glowLayer
            sparkleLayer
            itemLayer
            textLayer
            Color.white.opacity(flashOpacity).ignoresSafeArea().allowsHitTesting(false)
            hintLayer
        }
        .onAppear(perform: startSequence)
        .onTapGesture(perform: onDismiss)
    }
}

// MARK: - Layers

private extension LootRevealView {
    
    var burstLayer: some View {
        StarburstShape(rayCount: equipment.rarity == .legendary ? 24 : 16)
            .fill(Color(equipment.rarity.color).opacity(0.25))
            .rotationEffect(.degrees(burstRotation))
            .scaleEffect(glowScale * 2.5)
            .opacity(glowOpacity * 0.6)
            .allowsHitTesting(false)
    }
    
    var glowLayer: some View {
        let rc = Color(equipment.rarity.color)
        return ZStack {
            Circle()
                .fill(RadialGradient(
                    colors: [rc.opacity(0.6), rc.opacity(0.2), .clear],
                    center: .center, startRadius: 20, endRadius: 180
                ))
                .frame(width: 360, height: 360)
            Circle()
                .fill(RadialGradient(
                    colors: [Color.white.opacity(0.4), .clear],
                    center: .center, startRadius: 0, endRadius: 80
                ))
                .frame(width: 160, height: 160)
        }
        .scaleEffect(glowScale)
        .opacity(glowOpacity)
        .allowsHitTesting(false)
    }
    
    var sparkleLayer: some View {
        ZStack {
            ForEach(0..<20, id: \.self) { i in
                SparkDiamond(color: sparkleColor(i))
                    .offset(sparkleOffset(index: i))
                    .opacity(sparkleFade)
            }
        }
        .allowsHitTesting(false)
    }
    
    var itemLayer: some View {
        let rc = Color(equipment.rarity.color)
        return ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(rc.opacity(0.15))
                .frame(width: 120, height: 120)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(rc.opacity(0.5), lineWidth: 2))
            EquipmentIconView(item: equipment, slot: equipment.slot, size: 100)
        }
        .scaleEffect(itemScale)
        .opacity(itemOpacity)
        .allowsHitTesting(false)
    }
    
    var textLayer: some View {
        let rc = Color(equipment.rarity.color)
        return VStack(spacing: 8) {
            Spacer().frame(height: UIScreen.main.bounds.height * 0.5 + 80)
            itemNameText(rc)
            rarityBadge(rc)
            statText
        }
        .opacity(textOpacity)
        .allowsHitTesting(false)
    }
    
    func itemNameText(_ rc: Color) -> some View {
        Text(equipment.name)
            .font(.custom("Avenir-Heavy", size: 24))
            .foregroundColor(.white)
            .shadow(color: rc.opacity(0.8), radius: 10)
    }
    
    func rarityBadge(_ rc: Color) -> some View {
        Text(equipment.rarity.rawValue)
            .font(.custom("Avenir-Heavy", size: 16))
            .foregroundColor(rc)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Capsule().fill(rc.opacity(0.2)).overlay(Capsule().stroke(rc.opacity(0.4), lineWidth: 1)))
            .rarityShimmer(equipment.rarity)
    }
    
    @ViewBuilder
    var statText: some View {
        if !equipment.statSummary.isEmpty {
            Text(equipment.statSummary)
                .font(.custom("Avenir-Medium", size: 14))
                .foregroundColor(.white.opacity(0.7))
                .padding(.top, 4)
        }
    }
    
    var hintLayer: some View {
        VStack {
            Spacer()
            Text("Tap to continue")
                .font(.custom("Avenir-Medium", size: 14))
                .foregroundColor(.white.opacity(0.5))
                .padding(.bottom, 50)
        }
        .opacity(dismissHintOpacity)
        .allowsHitTesting(false)
    }
}

// MARK: - Sparkle Helpers

private extension LootRevealView {
    
    static let sparkleAngles: [Double] = (0..<20).map { i in
        Double(i) / 20.0 * .pi * 2 + Double.random(in: -0.15...0.15)
    }
    
    static let sparkleDistances: [CGFloat] = (0..<20).map { _ in
        CGFloat.random(in: 120...260)
    }
    
    func sparkleOffset(index i: Int) -> CGSize {
        let angle: Double = Self.sparkleAngles[i % 20]
        let dist: Double = Double(Self.sparkleDistances[i % 20] * sparkleExpanded)
        let dx: Double = Foundation.cos(angle) * dist
        let dy: Double = Foundation.sin(angle) * dist
        return CGSize(width: dx, height: dy)
    }
    
    func sparkleColor(_ i: Int) -> Color {
        let rc = Color(equipment.rarity.color)
        let palette: [Color] = [.white, rc, .yellow, rc.opacity(0.7)]
        return palette[i % palette.count]
    }
}

// MARK: - Animation Sequence

private extension LootRevealView {
    
    func startSequence() {
        withAnimation(.easeIn(duration: 0.1)) { flashOpacity = 0.9 }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.4)) { flashOpacity = 0 }
            withAnimation(.easeOut(duration: 0.6)) {
                glowScale = 1.0
                glowOpacity = 1.0
            }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                burstRotation = 360
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0)) {
                itemScale = 1.0
                itemOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 1.0)) {
                sparkleExpanded = 1.0
            }
            withAnimation(.easeOut(duration: 1.2).delay(0.3)) {
                sparkleFade = 0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.4)) { textOpacity = 1.0 }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowScale = 1.15
                glowOpacity = 0.7
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                dismissHintOpacity = 1.0
            }
        }
    }
}

// MARK: - Starburst Shape

private struct StarburstShape: Shape {
    let rayCount: Int
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let maxR: CGFloat = max(rect.width, rect.height) * 0.5
        var path = Path()
        
        for i in 0..<rayCount {
            let a1: Double = Double(i) / Double(rayCount) * .pi * 2
            let a2: Double = (Double(i) + 0.3) / Double(rayCount) * .pi * 2
            
            path.move(to: center)
            path.addLine(to: point(center: center, angle: a1, radius: maxR))
            path.addLine(to: point(center: center, angle: a2, radius: maxR))
            path.closeSubpath()
        }
        return path
    }
    
    private func point(center: CGPoint, angle: Double, radius: CGFloat) -> CGPoint {
        let dx: CGFloat = CGFloat(cos(angle)) * radius
        let dy: CGFloat = CGFloat(sin(angle)) * radius
        return CGPoint(x: center.x + dx, y: center.y + dy)
    }
}

// MARK: - Spark Diamond

private struct SparkDiamond: View {
    let color: Color
    private let size: CGFloat = CGFloat.random(in: 6...14)
    
    var body: some View {
        Diamond()
            .fill(color)
            .frame(width: size, height: size)
    }
}

private struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Preview

#Preview("Legendary Drop") {
    LootRevealView(
        equipment: Equipment.previewLegendary,
        onDismiss: {}
    )
}

#Preview("Epic Drop") {
    LootRevealView(
        equipment: Equipment.previewEpic,
        onDismiss: {}
    )
}

private extension Equipment {
    static var previewLegendary: Equipment {
        Equipment(
            name: "Blade of Eternal Dawn",
            description: "A legendary blade forged in starlight.",
            slot: .weapon,
            rarity: .legendary,
            primaryStat: .strength,
            statBonus: 42,
            levelRequirement: 25,
            secondaryStat: .dexterity,
            secondaryStatBonus: 18
        )
    }
    
    static var previewEpic: Equipment {
        Equipment(
            name: "Shadow Veil Cloak",
            description: "A cloak woven from living shadows.",
            slot: .cloak,
            rarity: .epic,
            primaryStat: .wisdom,
            statBonus: 28,
            levelRequirement: 18,
            secondaryStat: .defense,
            secondaryStatBonus: 15
        )
    }
}
