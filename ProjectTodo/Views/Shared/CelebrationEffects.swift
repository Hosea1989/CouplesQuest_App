import SwiftUI

// MARK: - Confetti Data Model

struct CelebrationConfettiData: Identifiable {
    let id: Int
    let color: Color
    let startX: CGFloat
    let endX: CGFloat
    let endY: CGFloat
    let rotation: Double
    let delay: Double
    let duration: Double
    let width: CGFloat
    let height: CGFloat
}

// MARK: - Confetti Overlay

struct CelebrationConfettiOverlay: View {
    @State private var pieces: [CelebrationConfettiData]
    
    init() {
        let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink, .mint]
        var p: [CelebrationConfettiData] = []
        for i in 0..<80 {
            p.append(CelebrationConfettiData(
                id: i,
                color: colors[i % colors.count],
                startX: CGFloat.random(in: -30...30),
                endX: CGFloat.random(in: -200...200),
                endY: CGFloat.random(in: 300...900),
                rotation: Double.random(in: -720...720),
                delay: Double(i) * 0.015,
                duration: Double.random(in: 2.5...4.0),
                width: CGFloat.random(in: 5...10),
                height: CGFloat.random(in: 8...18)
            ))
        }
        _pieces = State(initialValue: p)
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { piece in
                    CelebrationConfettiPieceView(piece: piece)
                        .position(x: geo.size.width / 2, y: 0)
                }
            }
        }
    }
}

struct CelebrationConfettiPieceView: View {
    let piece: CelebrationConfettiData
    @State private var animate = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(piece.color)
            .frame(width: piece.width, height: piece.height)
            .offset(
                x: animate ? piece.endX : piece.startX,
                y: animate ? piece.endY : -50
            )
            .rotationEffect(.degrees(animate ? piece.rotation : 0))
            .opacity(animate ? 0 : 1)
            .onAppear {
                withAnimation(
                    .easeOut(duration: piece.duration)
                    .delay(piece.delay)
                ) {
                    animate = true
                }
            }
    }
}

// MARK: - Floating Particles

struct CelebrationFloatingParticleData: Identifiable {
    let id: Int
    let xFraction: CGFloat
    let startYFraction: CGFloat
    let size: CGFloat
    let particleOpacity: Double
    let duration: Double
}

struct CelebrationFloatingParticlesView: View {
    let color: Color
    
    @State private var particles: [CelebrationFloatingParticleData]
    
    init(color: Color = Color("AccentGold")) {
        self.color = color
        var p: [CelebrationFloatingParticleData] = []
        for i in 0..<15 {
            p.append(CelebrationFloatingParticleData(
                id: i,
                xFraction: CGFloat.random(in: 0...1),
                startYFraction: CGFloat.random(in: 0.2...1.0),
                size: CGFloat.random(in: 2...6),
                particleOpacity: Double.random(in: 0.2...0.5),
                duration: Double.random(in: 3...6)
            ))
        }
        _particles = State(initialValue: p)
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    CelebrationFloatingParticleItemView(
                        particle: particle,
                        geoSize: geo.size,
                        color: color
                    )
                }
            }
        }
    }
}

struct CelebrationFloatingParticleItemView: View {
    let particle: CelebrationFloatingParticleData
    let geoSize: CGSize
    let color: Color
    @State private var animate = false
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: particle.size, height: particle.size)
            .opacity(particle.particleOpacity)
            .position(
                x: geoSize.width * particle.xFraction,
                y: animate ? -20 : geoSize.height * particle.startYFraction
            )
            .onAppear {
                withAnimation(
                    .easeInOut(duration: particle.duration)
                    .repeatForever(autoreverses: false)
                ) {
                    animate = true
                }
            }
    }
}

// MARK: - Defeat Overlay (red/dark particles drifting downward)

struct DefeatParticleData: Identifiable {
    let id: Int
    let xFraction: CGFloat
    let startYFraction: CGFloat
    let size: CGFloat
    let particleOpacity: Double
    let duration: Double
}

struct DefeatOverlay: View {
    @State private var particles: [DefeatParticleData]
    
    init() {
        var p: [DefeatParticleData] = []
        for i in 0..<20 {
            p.append(DefeatParticleData(
                id: i,
                xFraction: CGFloat.random(in: 0...1),
                startYFraction: CGFloat.random(in: -0.1...0.3),
                size: CGFloat.random(in: 3...8),
                particleOpacity: Double.random(in: 0.15...0.4),
                duration: Double.random(in: 4...8)
            ))
        }
        _particles = State(initialValue: p)
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    DefeatParticleItemView(particle: particle, geoSize: geo.size)
                }
            }
        }
    }
}

struct DefeatParticleItemView: View {
    let particle: DefeatParticleData
    let geoSize: CGSize
    @State private var animate = false
    
    var body: some View {
        Circle()
            .fill(Color.red.opacity(0.6))
            .frame(width: particle.size, height: particle.size)
            .opacity(particle.particleOpacity)
            .blur(radius: 1)
            .position(
                x: geoSize.width * particle.xFraction,
                y: animate ? geoSize.height + 20 : geoSize.height * particle.startYFraction
            )
            .onAppear {
                withAnimation(
                    .easeIn(duration: particle.duration)
                    .repeatForever(autoreverses: false)
                ) {
                    animate = true
                }
            }
    }
}

// MARK: - Victory Banner (reusable radial glow + icon + title + subtitle)

struct VictoryBanner: View {
    let success: Bool
    let title: String
    var subtitle: String? = nil
    var iconName: String? = nil
    var iconSize: CGFloat = 80
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                (success ? Color("AccentGold") : Color.red).opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                
                Image(systemName: iconName ?? (success ? "trophy.fill" : "xmark.circle.fill"))
                    .font(.system(size: iconSize))
                    .foregroundColor(success ? Color("AccentGold") : .red)
                    .symbolEffect(.bounce)
            }
            
            Text(title)
                .font(.custom("Avenir-Heavy", size: 30))
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.custom("Avenir-Medium", size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
    }
}
