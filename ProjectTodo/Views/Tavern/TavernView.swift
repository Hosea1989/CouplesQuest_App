import SwiftUI

struct TavernView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "fork.knife")
                .font(.system(size: 64))
                .foregroundStyle(Color("TavernAmber"))

            Text("Tavern")
                .font(.custom("Avenir-Heavy", size: 28))
                .foregroundColor(.primary)

            Text("The hearth is warming up.\nCome back soon!")
                .font(.custom("Avenir-Medium", size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("BackgroundTop"))
        .navigationTitle("Tavern")
        .navigationBarTitleDisplayMode(.large)
    }
}
