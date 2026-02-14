import SwiftUI

// MARK: - Sparkle Model

private struct SplashSparkle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let targetX: CGFloat
    let targetY: CGFloat
    let size: CGFloat
    var opacity: Double
}

/// Animated splash screen shown on app launch while checking session state.
/// "Sword-strike" entrance with impact flash, shockwave, sparkle burst,
/// shimmer title, and rotating loading messages.
struct SplashScreenView: View {
    // MARK: - Animation State
    
    // Icon entrance (sword-strike slam)
    @State private var iconScale: CGFloat = 2.2
    @State private var iconOpacity: Double = 0
    @State private var iconOffsetY: CGFloat = -80
    
    // Impact effects
    @State private var impactFlash: Double = 0
    @State private var shockwaveScale: CGFloat = 0.2
    @State private var shockwaveOpacity: Double = 0
    
    // Glow
    @State private var glowOpacity: Double = 0
    @State private var glowPulse: Bool = false
    
    // Title
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 15
    @State private var taglineOpacity: Double = 0
    
    // Shimmer
    @State private var shimmerOffset: CGFloat = -300
    
    // Loading
    @State private var loadingOpacity: Double = 0
    @State private var loadingMessageIndex = 0
    
    // Sparkle particles
    @State private var sparkles: [SplashSparkle] = []
    
    // Floating background particles
    @State private var floatingOpacity: Double = 0
    
    private let loadingMessages = [
        "Sharpening swords...",
        "Mopping the dungeon...",
        "Rolling for initiative...",
        "Folding enchanted laundry...",
        "Polishing armor...",
        "Sweeping the throne room...",
        "Feeding the quest board...",
        "Buffing party stats..."
    ]
    
    private let messageTimer = Timer.publish(every: 2.2, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color("BackgroundTop"),
                    Color("BackgroundBottom")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Floating diamond/sparkle particles
            floatingDiamonds
            
            // Impact flash overlay
            Color("AccentGold")
                .opacity(impactFlash)
                .ignoresSafeArea()
            
            // Shockwave ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color("AccentGold").opacity(0.6),
                            Color("AccentPink").opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: 200, height: 200)
                .scaleEffect(shockwaveScale)
                .opacity(shockwaveOpacity)
            
            // Sparkle burst particles
            ForEach(sparkles) { sparkle in
                Image(systemName: "sparkle")
                    .font(.system(size: sparkle.size))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("AccentGold"), Color("AccentPink")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .position(x: sparkle.x, y: sparkle.y)
                    .opacity(sparkle.opacity)
            }
            
            VStack(spacing: 28) {
                Spacer()
                
                // MARK: Hero — "S & C" Monogram
                ZStack {
                    // Outer glow ring
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color("AccentGold").opacity(0.35),
                                    Color("AccentPink").opacity(0.12),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 130
                            )
                        )
                        .frame(width: 260, height: 260)
                        .scaleEffect(glowPulse ? 1.12 : 0.92)
                        .opacity(glowOpacity)
                    
                    // Inner glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color("AccentGold").opacity(0.25),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 70
                            )
                        )
                        .frame(width: 160, height: 160)
                        .opacity(glowOpacity)
                    
                    // "S & C" monogram
                    HStack(spacing: 2) {
                        Text("S")
                            .font(.system(size: 72, weight: .bold, design: .serif))
                        
                        Text("&")
                            .font(.system(size: 48, weight: .bold, design: .serif))
                            .offset(y: 5)
                        
                        Text("C")
                            .font(.system(size: 72, weight: .bold, design: .serif))
                    }
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.85, blue: 0.4),
                                Color("AccentGold"),
                                Color(red: 0.82, green: 0.62, blue: 0.18)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color("AccentGold").opacity(0.6), radius: 20, x: 0, y: 0)
                    .shadow(color: Color("AccentGold").opacity(0.25), radius: 40, x: 0, y: 5)
                }
                .scaleEffect(iconScale)
                .opacity(iconOpacity)
                .offset(y: iconOffsetY)
                
                // MARK: Title Area
                VStack(spacing: 10) {
                    // "SWORDS & CHORES" with shimmer sweep
                    Text("SWORDS  &  CHORES")
                        .font(.custom("Avenir-Heavy", size: 18))
                        .tracking(5)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color.white.opacity(0.85)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    Color("AccentGold").opacity(0.7),
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: 60)
                            .offset(x: shimmerOffset)
                            .mask(
                                Text("SWORDS  &  CHORES")
                                    .font(.custom("Avenir-Heavy", size: 18))
                                    .tracking(5)
                            )
                        )
                        .clipped()
                    
                    // Tagline
                    Text("Slay your to-do list")
                        .font(.custom("Avenir-MediumOblique", size: 15))
                        .foregroundColor(Color("AccentGold").opacity(0.65))
                        .opacity(taglineOpacity)
                }
                .opacity(titleOpacity)
                .offset(y: titleOffset)
                
                Spacer()
                
                // MARK: Loading Area
                VStack(spacing: 14) {
                    // Bouncing dots
                    HStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { i in
                            BouncingDot(delay: Double(i) * 0.15, isActive: loadingOpacity > 0)
                        }
                    }
                    
                    // Rotating messages
                    Text(loadingMessages[loadingMessageIndex])
                        .font(.custom("Avenir-Medium", size: 13))
                        .foregroundColor(.secondary.opacity(0.6))
                        .contentTransition(.opacity)
                        .animation(.easeInOut(duration: 0.4), value: loadingMessageIndex)
                }
                .opacity(loadingOpacity)
                .padding(.bottom, 60)
                .onReceive(messageTimer) { _ in
                    withAnimation {
                        loadingMessageIndex = (loadingMessageIndex + 1) % loadingMessages.count
                    }
                }
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Floating Diamond Particles
    
    private var floatingDiamonds: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<12, id: \.self) { index in
                    Image(systemName: index % 3 == 0 ? "diamond.fill" : "sparkle")
                        .font(.system(size: particleSize(index: index)))
                        .foregroundColor(
                            index % 2 == 0
                                ? Color("AccentGold").opacity(0.12)
                                : Color("AccentPink").opacity(0.08)
                        )
                        .position(
                            x: particleX(index: index, width: geo.size.width),
                            y: particleY(index: index, height: geo.size.height)
                        )
                        .opacity(floatingOpacity)
                }
            }
        }
    }
    
    private func particleSize(index: Int) -> CGFloat {
        let sizes: [CGFloat] = [4, 6, 3, 8, 5, 3, 7, 4, 6, 3, 5, 7]
        return sizes[index % sizes.count]
    }
    
    private func particleX(index: Int, width: CGFloat) -> CGFloat {
        let positions: [CGFloat] = [0.1, 0.88, 0.22, 0.72, 0.05, 0.95, 0.38, 0.62, 0.48, 0.82, 0.16, 0.55]
        return width * positions[index % positions.count]
    }
    
    private func particleY(index: Int, height: CGFloat) -> CGFloat {
        let positions: [CGFloat] = [0.12, 0.28, 0.58, 0.42, 0.78, 0.08, 0.68, 0.32, 0.88, 0.22, 0.52, 0.72]
        return height * positions[index % positions.count]
    }
    
    // MARK: - Sparkle Burst
    
    private func generateSparkles() {
        let screenMidX = UIScreen.main.bounds.width / 2
        let screenMidY = UIScreen.main.bounds.height * 0.36
        
        var newSparkles: [SplashSparkle] = []
        for _ in 0..<12 {
            let angle = Double.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 80...180)
            let sparkle = SplashSparkle(
                x: screenMidX,
                y: screenMidY,
                targetX: screenMidX + cos(angle) * distance,
                targetY: screenMidY + sin(angle) * distance,
                size: CGFloat.random(in: 8...16),
                opacity: 1.0
            )
            newSparkles.append(sparkle)
        }
        sparkles = newSparkles
        
        // Animate sparkles outward and fade
        withAnimation(.easeOut(duration: 0.9)) {
            for i in sparkles.indices {
                sparkles[i].x = sparkles[i].targetX
                sparkles[i].y = sparkles[i].targetY
                sparkles[i].opacity = 0
            }
        }
    }
    
    // MARK: - Animation Sequence
    
    private func startAnimations() {
        // 1. Icon SLAMS in — drops from above, scales down, spring bounce
        withAnimation(.spring(response: 0.45, dampingFraction: 0.5).delay(0.15)) {
            iconScale = 1.0
            iconOpacity = 1.0
            iconOffsetY = 0
        }
        
        // 2. Impact flash — brief gold flash across screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
            withAnimation(.easeOut(duration: 0.06)) {
                impactFlash = 0.2
            }
            withAnimation(.easeOut(duration: 0.25).delay(0.06)) {
                impactFlash = 0
            }
        }
        
        // 3. Shockwave ring expands outward
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            shockwaveOpacity = 0.6
            withAnimation(.easeOut(duration: 0.8)) {
                shockwaveScale = 3.5
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.15)) {
                shockwaveOpacity = 0
            }
        }
        
        // 4. Sparkle burst scatters from center
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            generateSparkles()
        }
        
        // 5. Glow fades in around monogram
        withAnimation(.easeOut(duration: 0.9).delay(0.5)) {
            glowOpacity = 1.0
        }
        
        // 6. Glow pulse loop
        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true).delay(1.0)) {
            glowPulse = true
        }
        
        // 7. Floating particles appear
        withAnimation(.easeOut(duration: 1.0).delay(0.6)) {
            floatingOpacity = 1.0
        }
        
        // 8. Title slides up and fades in
        withAnimation(.easeOut(duration: 0.6).delay(0.7)) {
            titleOpacity = 1.0
            titleOffset = 0
        }
        
        // 9. Tagline fades in
        withAnimation(.easeOut(duration: 0.5).delay(1.0)) {
            taglineOpacity = 1.0
        }
        
        // 10. Shimmer sweep across title
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeInOut(duration: 0.8)) {
                shimmerOffset = 300
            }
        }
        
        // Repeat shimmer periodically
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            shimmerLoop()
        }
        
        // 11. Loading messages fade in
        withAnimation(.easeOut(duration: 0.4).delay(1.3)) {
            loadingOpacity = 1.0
        }
    }
    
    private func shimmerLoop() {
        shimmerOffset = -300
        withAnimation(.easeInOut(duration: 0.8)) {
            shimmerOffset = 300
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            shimmerLoop()
        }
    }
}

// MARK: - Bouncing Dot

private struct BouncingDot: View {
    let delay: Double
    let isActive: Bool
    
    @State private var animating = false
    
    var body: some View {
        Circle()
            .fill(Color("AccentGold").opacity(0.8))
            .frame(width: 6, height: 6)
            .offset(y: animating ? -6 : 2)
            .animation(
                .easeInOut(duration: 0.5)
                .repeatForever(autoreverses: true)
                .delay(delay),
                value: animating
            )
            .onAppear {
                animating = true
            }
    }
}

// MARK: - Preview

#Preview {
    SplashScreenView()
}
