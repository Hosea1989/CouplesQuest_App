import SwiftUI

/// A compact shopkeeper banner with portrait and speech bubble
struct ShopkeeperView: View {
    let message: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // Shopkeeper portrait
            Image("shopkeeper")
                .resizable()
                .aspectRatio(contentMode: .fill)
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
            
            // Speech bubble
            SpeechBubbleView(text: message)
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color("CardBackground"))
        )
        .padding(.horizontal)
    }
}

// MARK: - Speech Bubble

/// A rounded speech bubble with a small triangular tail on the left
struct SpeechBubbleView: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Bubble tail pointing left
            BubbleTail()
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
struct BubbleTail: Shape {
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
            ShopkeeperView(message: "Welcome to my shop, adventurer! Take a look around — I've got something for every hero.")
            Spacer()
        }
        .padding(.top, 20)
    }
}
