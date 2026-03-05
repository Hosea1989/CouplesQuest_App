import SwiftUI

/// A compact forgekeeper banner with portrait and speech bubble — mirrors ShopkeeperView
struct ForgekeeperView: View {
    let message: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // Forgekeeper portrait
            Group {
                if UIImage(named: "forgekeeper") != nil {
                    Image("forgekeeper")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    // Fallback when asset hasn't been added yet
                    ZStack {
                        LinearGradient(
                            colors: [Color("ForgeEmber").opacity(0.3), Color("AccentOrange").opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        
                        VStack(spacing: 4) {
                            Image(systemName: "hammer.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color("ForgeEmber"), Color("AccentOrange")],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            Text("Forge\nKeeper")
                                .font(.custom("Avenir-Heavy", size: 9))
                                .foregroundColor(Color("ForgeEmber"))
                                .multilineTextAlignment(.center)
                        }
                    }
                }
            }
            .frame(width: 90, height: 110)
            .clipped()
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 14,
                    bottomLeadingRadius: 14,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 0
                )
            )
            
            // Speech bubble (reusing the same SpeechBubbleView from ShopkeeperView)
            ForgeSpeechBubbleView(text: message)
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color("CardBackground"))
        )
        .padding(.horizontal)
    }
}

// MARK: - Forge Speech Bubble

/// A rounded speech bubble with a small triangular tail on the left
private struct ForgeSpeechBubbleView: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Bubble tail pointing left
            ForgeBubbleTail()
                .fill(Color("CardBackground").opacity(0.85))
                .frame(width: 10, height: 16)
                .offset(x: 1, y: 18)
            
            // Bubble content
            Text(text)
                .font(.custom("Avenir-Medium", size: 13))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(4)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("CardBackground").opacity(0.85))
                )
        }
        .padding(.trailing, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - Bubble Tail Shape

/// A small triangular tail for the speech bubble
private struct ForgeBubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color("BackgroundTop"), Color("BackgroundBottom")],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        
        VStack {
            ForgekeeperView(message: "Welcome to the Forge, adventurer! Let's craft something mighty.")
            Spacer()
        }
        .padding(.top, 20)
    }
}
