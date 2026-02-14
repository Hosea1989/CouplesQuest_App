import SwiftUI
import Combine

// MARK: - Toast Model

/// A single toast notification to display in-app.
struct Toast: Identifiable, Equatable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let style: ToastStyle
    /// How long the toast stays visible (seconds).
    var duration: Double = 2.5
    
    static func == (lhs: Toast, rhs: Toast) -> Bool {
        lhs.id == rhs.id
    }
}

/// Visual style presets that map to the game's color palette.
enum ToastStyle {
    /// Gold sparkle — EXP, gold, general rewards
    case reward
    /// Purple shimmer — equipment, gems, rare drops
    case loot
    /// Green check — task complete, quest claimed
    case success
    /// Red warning — streak broken, sync failed
    case error
    /// Blue info — partner events, cloud sync, general info
    case info
    /// Orange fire — streaks, combos, milestones
    case streak
    
    var gradient: [Color] {
        switch self {
        case .reward:  return [Color("AccentGold"), Color("AccentOrange")]
        case .loot:    return [Color("AccentPurple"), Color("AccentPurple").opacity(0.9)]
        case .success: return [Color("AccentGreen"), Color("AccentGreen").opacity(0.9)]
        case .error:   return [Color.red, Color.red.opacity(0.85)]
        case .info:    return [Color.blue, Color.blue.opacity(0.85)]
        case .streak:  return [Color("AccentOrange"), Color("AccentGold")]
        }
    }
    
    /// Whether this style needs dark text for readability (light backgrounds).
    var usesDarkText: Bool {
        switch self {
        case .reward, .streak: return true
        default: return false
        }
    }
}

// MARK: - Toast Manager

/// Central manager that queues and displays in-app toast notifications.
/// Injected into the environment so any view can trigger a toast.
@MainActor
final class ToastManager: ObservableObject {
    
    static let shared = ToastManager()
    
    /// The currently visible toast (nil = nothing showing).
    @Published var currentToast: Toast?
    
    /// FIFO queue of pending toasts.
    private var queue: [Toast] = []
    
    /// Whether a toast is currently being displayed.
    private var isPresenting = false
    
    private init() {}
    
    // MARK: - Public API
    
    /// Enqueue a fully-customised toast.
    func show(_ toast: Toast) {
        queue.append(toast)
        presentNextIfNeeded()
    }
    
    // MARK: - Convenience Factories
    
    /// Generic reward toast (EXP, gold, etc.)
    func showReward(_ title: String, subtitle: String? = nil, icon: String = "sparkles") {
        show(Toast(icon: icon, iconColor: Color("AccentGold"), title: title, subtitle: subtitle, style: .reward))
    }
    
    /// Equipment / loot drop toast.
    func showLoot(_ itemName: String, rarity: String? = nil) {
        let sub = rarity.map { "\($0) item" }
        show(Toast(icon: "shield.fill", iconColor: Color("AccentPurple"), title: itemName, subtitle: sub, style: .loot))
    }
    
    /// Task / quest success toast.
    func showSuccess(_ title: String, subtitle: String? = nil) {
        show(Toast(icon: "checkmark.circle.fill", iconColor: Color("AccentGreen"), title: title, subtitle: subtitle, style: .success))
    }
    
    /// Error / warning toast.
    func showError(_ title: String, subtitle: String? = nil) {
        show(Toast(icon: "exclamationmark.triangle.fill", iconColor: .red, title: title, subtitle: subtitle, style: .error, duration: 3.5))
    }
    
    /// Informational toast (partner events, sync, etc.)
    func showInfo(_ title: String, subtitle: String? = nil, icon: String = "info.circle.fill") {
        show(Toast(icon: icon, iconColor: .blue, title: title, subtitle: subtitle, style: .info))
    }
    
    /// Streak / milestone toast.
    func showStreak(_ title: String, subtitle: String? = nil) {
        show(Toast(icon: "flame.fill", iconColor: Color("AccentOrange"), title: title, subtitle: subtitle, style: .streak))
    }
    
    // MARK: - Queue Logic
    
    /// Dismiss the current toast immediately and show the next one if queued.
    func dismiss() {
        withAnimation(.easeOut(duration: 0.25)) {
            currentToast = nil
        }
        isPresenting = false
        // Small delay before showing next toast so they don't stack
        Task {
            try? await Task.sleep(for: .milliseconds(200))
            presentNextIfNeeded()
        }
    }
    
    private func presentNextIfNeeded() {
        guard !isPresenting, !queue.isEmpty else { return }
        isPresenting = true
        let next = queue.removeFirst()
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            currentToast = next
        }
        
        // Auto-dismiss after duration
        Task {
            try? await Task.sleep(for: .seconds(next.duration))
            // Only dismiss if this toast is still showing (user may have swiped it away)
            if currentToast?.id == next.id {
                dismiss()
            }
        }
    }
}
