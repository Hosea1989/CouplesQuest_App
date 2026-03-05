import SwiftUI

/// A compact scholar banner with portrait and speech bubble — mirrors ForgekeeperView / ShopkeeperView
struct ScholarView: View {
    let message: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Group {
                if UIImage(named: "scholar") != nil {
                    Image("scholar")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        LinearGradient(
                            colors: [Color("AccentPurple").opacity(0.3), Color("AccentGold").opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        
                        VStack(spacing: 4) {
                            Image(systemName: "book.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color("AccentPurple"), Color("AccentGold")],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            Text("The\nScholar")
                                .font(.custom("Avenir-Heavy", size: 9))
                                .foregroundColor(Color("AccentPurple"))
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
            
            ScholarSpeechBubbleView(text: message)
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color("CardBackground"))
        )
        .padding(.horizontal)
    }
}

// MARK: - Scholar Speech Bubble

private struct ScholarSpeechBubbleView: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ScholarBubbleTail()
                .fill(Color("CardBackground").opacity(0.85))
                .frame(width: 10, height: 16)
                .offset(x: 1, y: 18)
            
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

private struct ScholarBubbleTail: Shape {
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
            ScholarView(message: "Welcome to the Study, adventurer! Knowledge is the truest power.")
            Spacer()
        }
        .padding(.top, 20)
    }
}
