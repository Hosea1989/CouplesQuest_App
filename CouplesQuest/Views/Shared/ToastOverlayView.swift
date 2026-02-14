import SwiftUI

/// A floating toast notification that appears at the top of the screen.
/// Attach this once at the root level (ContentView) via `.overlay { ToastOverlayView() }`.
struct ToastOverlayView: View {
    @ObservedObject private var toastManager = ToastManager.shared
    
    var body: some View {
        VStack {
            if let toast = toastManager.currentToast {
                toastCard(toast)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                    .gesture(
                        DragGesture(minimumDistance: 10)
                            .onEnded { value in
                                if value.translation.height < -10 {
                                    toastManager.dismiss()
                                }
                            }
                    )
                    .onTapGesture {
                        toastManager.dismiss()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }
            
            Spacer()
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: toastManager.currentToast)
        .allowsHitTesting(toastManager.currentToast != nil)
    }
    
    // MARK: - Toast Card
    
    private func toastCard(_ toast: Toast) -> some View {
        let darkText = toast.style.usesDarkText
        let textColor: Color = darkText ? .black : .white
        let subtitleColor: Color = darkText ? .black.opacity(0.7) : .white.opacity(0.85)
        let iconBgColor: Color = darkText ? .black.opacity(0.15) : .white.opacity(0.2)
        let iconFgColor: Color = darkText ? .black.opacity(0.85) : .white
        
        return HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconBgColor)
                    .frame(width: 36, height: 36)
                
                Image(systemName: toast.icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(iconFgColor)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(toast.title)
                    .font(.custom("Avenir-Heavy", size: 14))
                    .foregroundColor(textColor)
                    .lineLimit(2)
                
                if let subtitle = toast.subtitle {
                    Text(subtitle)
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(subtitleColor)
                        .lineLimit(2)
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: toast.style.gradient,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)
        )
    }
}

#Preview {
    ZStack {
        Color("BackgroundTop").ignoresSafeArea()
        ToastOverlayView()
            .onAppear {
                ToastManager.shared.showReward("+120 EXP", subtitle: "Quest completed!")
            }
    }
}
