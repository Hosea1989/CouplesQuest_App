import Foundation
import UserNotifications
import OneSignalFramework

/// Centralized push notification service for Swords & Chores.
/// Handles both personal (local) and partner (cross-device) notifications.
@MainActor
final class PushNotificationService {
    
    // MARK: - Singleton
    
    static let shared = PushNotificationService()
    
    private let center = UNUserNotificationCenter.current()
    
    private init() {}
    
    // MARK: - Lifecycle
    
    /// Associate the current device with the Supabase user ID in OneSignal.
    /// Call after successful sign-in / session restore.
    func login(userID: String) {
        OneSignal.login(userID)
        print("📬 OneSignal login: \(userID)")
    }
    
    /// Disassociate the device from the user on sign-out.
    func logout() {
        OneSignal.logout()
        print("📬 OneSignal logout")
    }
    
    // MARK: - Personal Notifications (Local)
    
    /// Schedule a push for when an AFK training / mission timer completes.
    func scheduleTrainingComplete(missionName: String, completionDate: Date) {
        let interval = completionDate.timeIntervalSinceNow
        guard interval > 0 else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Mission Complete!"
        content.body = "Your hero has returned from \(missionName). Claim your rewards!"
        content.sound = .default
        content.categoryIdentifier = "MISSION_COMPLETE"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(
            identifier: "mission-complete-\(missionName.hashValue)",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }
    
    /// Cancel a previously scheduled training-complete notification.
    func cancelTrainingComplete(missionName: String) {
        center.removePendingNotificationRequests(withIdentifiers: [
            "mission-complete-\(missionName.hashValue)"
        ])
    }
    
    /// Schedule a push for when a dungeon run finishes.
    func scheduleDungeonComplete(dungeonName: String, completionDate: Date) {
        let interval = completionDate.timeIntervalSinceNow
        guard interval > 0 else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Dungeon Cleared!"
        content.body = "Claim your rewards from \(dungeonName)."
        content.sound = .default
        content.categoryIdentifier = "DUNGEON_COMPLETE"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(
            identifier: "dungeon-complete-\(dungeonName.hashValue)",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }
    
    // MARK: - Expedition Notifications
    
    /// Schedule a push notification for when an expedition stage completes.
    func scheduleExpeditionStageComplete(expeditionName: String, stageName: String, completionDate: Date) {
        let interval = completionDate.timeIntervalSinceNow
        guard interval > 0 else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Expedition Stage Complete!"
        content.body = "Your party reached \(stageName) in \(expeditionName). Open to see results and claim rewards!"
        content.sound = .default
        content.categoryIdentifier = "EXPEDITION_STAGE"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(
            identifier: "expedition-stage-\(expeditionName.hashValue)-\(stageName.hashValue)",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }
    
    /// Cancel all pending expedition stage notifications for a given expedition.
    func cancelExpeditionNotifications(expeditionName: String) {
        // Remove all with the expedition prefix
        center.getPendingNotificationRequests { requests in
            let ids = requests
                .map { $0.identifier }
                .filter { $0.hasPrefix("expedition-stage-\(expeditionName.hashValue)") }
            self.center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }
    
    /// Fire an immediate push when the player has enough EXP to level up.
    func scheduleLevelUpReady(currentLevel: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Level Up Available!"
        content.body = "You have enough EXP to reach Level \(currentLevel + 1). Open the app to level up!"
        content.sound = .default
        content.categoryIdentifier = "LEVEL_UP_READY"
        
        // Fire in 1 second (immediate-ish, required for time interval triggers)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "level-up-ready",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }
    
    /// Schedule a "Streak at Risk" notification at 8 PM daily.
    /// Replaces the existing one each time it's called.
    func scheduleStreakAtRisk(streakDays: Int) {
        // Remove any existing streak-at-risk notification first
        center.removePendingNotificationRequests(withIdentifiers: ["streak-at-risk-push"])
        
        let content = UNMutableNotificationContent()
        content.title = "Streak at Risk!"
        content.body = "Complete a task before midnight to keep your \(streakDays)-day streak!"
        content.sound = .default
        content.categoryIdentifier = "STREAK_RISK"
        
        // Every day at 8 PM
        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "streak-at-risk-push",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }
    
    /// Cancel the streak-at-risk notification (call when a task is completed today).
    func cancelStreakAtRisk() {
        center.removePendingNotificationRequests(withIdentifiers: ["streak-at-risk-push"])
    }
    
    /// Schedule a notification 15 minutes before a habit deadline.
    func scheduleHabitDeadline(habitName: String, habitID: String, deadline: Date) {
        let fireDate = deadline.addingTimeInterval(-15 * 60) // 15 min before
        guard fireDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Habit Deadline!"
        content.body = "\(habitName) is due in 15 minutes."
        content.sound = .default
        content.categoryIdentifier = "HABIT_DEADLINE"
        
        let interval = fireDate.timeIntervalSinceNow
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(
            identifier: "habit-deadline-\(habitID)",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }
    
    /// Cancel a habit deadline notification.
    func cancelHabitDeadline(habitID: String) {
        center.removePendingNotificationRequests(withIdentifiers: ["habit-deadline-\(habitID)"])
    }
    
    /// Cancel the daily reset notification (removed — it's noise, not useful §21).
    func cancelDailyReset() {
        center.removePendingNotificationRequests(withIdentifiers: ["daily-reset-push"])
    }
    
    // MARK: - Re-engagement Notifications
    
    /// Schedule re-engagement push notifications for when the user doesn't return.
    /// Called when the app goes to background. Notifications fire at 2d, 5d, and 14d.
    /// Max 3 total per lapse period. Cancelled on foreground.
    func scheduleReengagementNotifications(characterName: String, notificationsSentThisLapse: Int) {
        // Don't schedule more than 3 per lapse period
        guard notificationsSentThisLapse < 3 else { return }
        
        // Cancel any existing re-engagement notifications first
        cancelReengagementNotifications()
        
        let remaining = 3 - notificationsSentThisLapse
        
        let messages: [(days: Int, title: String, body: String, id: String)] = [
            (2, "Your party misses you!", "\(characterName) is resting at camp. Your allies completed tasks while you were away.", "reengage-2d"),
            (5, "Your character is resting at camp.", "Come back to claim your rewards, \(characterName).", "reengage-5d"),
            (14, "New adventures await!", "New content has been added since you left. Your adventurer awaits.", "reengage-14d"),
        ]
        
        for (index, msg) in messages.prefix(remaining).enumerated() {
            let content = UNMutableNotificationContent()
            content.title = msg.title
            content.body = msg.body
            content.sound = .default
            content.categoryIdentifier = "REENGAGEMENT"
            
            // Schedule at 10 AM local time, N days from now
            let fireDate = Calendar.current.date(byAdding: .day, value: msg.days, to: Date()) ?? Date()
            var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: fireDate)
            dateComponents.hour = 10
            dateComponents.minute = 0
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(
                identifier: msg.id,
                content: content,
                trigger: trigger
            )
            center.add(request)
            _ = index // suppress warning
        }
    }
    
    /// Cancel all pending re-engagement notifications (called when app returns to foreground).
    func cancelReengagementNotifications() {
        center.removePendingNotificationRequests(withIdentifiers: [
            "reengage-2d", "reengage-5d", "reengage-14d"
        ])
    }
    
    // MARK: - Evening Batch Summary
    
    /// Schedule an evening batch summary notification for party activity.
    /// Fires at 7 PM if there's party activity to report. One per day.
    func scheduleEveningBatchSummary(partyActivityCount: Int) {
        guard partyActivityCount > 0 else { return }
        
        center.removePendingNotificationRequests(withIdentifiers: ["evening-batch-summary"])
        
        let content = UNMutableNotificationContent()
        content.title = "Party Activity Today"
        content.body = "Your party members completed \(partyActivityCount) task\(partyActivityCount == 1 ? "" : "s") today. Check in to see what they've been up to!"
        content.sound = .default
        content.categoryIdentifier = "EVENING_SUMMARY"
        
        // 7 PM today (or tomorrow if past 7 PM)
        var dateComponents = DateComponents()
        dateComponents.hour = 19
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: "evening-batch-summary",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }
    
    // MARK: - Daily Login Reward Reminder
    
    /// Schedule a morning reminder if the user hasn't opened the app.
    /// Fires at 9 AM. Cancelled when the app opens.
    func scheduleDailyLoginReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["daily-login-reminder"])
        
        let content = UNMutableNotificationContent()
        content.title = "Daily Reward Waiting!"
        content.body = "Open the app to claim today's login reward."
        content.sound = .default
        content.categoryIdentifier = "DAILY_LOGIN"
        
        // Tomorrow at 9 AM
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow)
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: "daily-login-reminder",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }
    
    /// Cancel the daily login reminder (called when the app opens).
    func cancelDailyLoginReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["daily-login-reminder"])
    }
    
    // MARK: - Frequency Cap
    
    /// Maximum push notifications per day across all types.
    /// Rule: never more than 2 push notifications per day (§21).
    static let maxDailyNotifications = 2
    
    /// Check if we can send a notification without exceeding the daily cap.
    /// Uses UserDefaults to track daily notification count.
    func canSendNotification() -> Bool {
        let key = "pushNotificationCount_\(todayDateString)"
        let count = UserDefaults.standard.integer(forKey: key)
        return count < Self.maxDailyNotifications
    }
    
    /// Increment the daily notification counter after sending.
    func recordNotificationSent() {
        let key = "pushNotificationCount_\(todayDateString)"
        let count = UserDefaults.standard.integer(forKey: key)
        UserDefaults.standard.set(count + 1, forKey: key)
    }
    
    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    /// Fire a notification when a new raid boss appears.
    func scheduleRaidBossAvailable() {
        let content = UNMutableNotificationContent()
        content.title = "Raid Boss Appeared!"
        content.body = "A new challenge awaits. Rally your partner and fight!"
        content.sound = .default
        content.categoryIdentifier = "RAID_BOSS"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "raid-boss-available",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }
    
    // MARK: - Partner Notifications (Cross-Device via Edge Function)
    
    /// Encodable payload for the send-push Edge Function
    private struct PushPayload: Encodable {
        let targetUserID: String
        let title: String
        let body: String
        let type: String
    }
    
    /// Send a push notification to the partner's device via the Supabase Edge Function.
    /// - Parameters:
    ///   - type: Notification type key (e.g. "nudge", "kudos", "challenge", "task_complete", "pair_request", "streak_risk")
    ///   - title: Notification title
    ///   - body: Notification body text
    ///   - data: Optional extra data payload
    func notifyPartner(type: String, title: String, body: String, data: [String: String]? = nil) async {
        guard let partnerID = SupabaseService.shared.currentProfile?.partnerID else {
            print("📬 No partner linked — skipping partner push")
            return
        }
        
        let payload = PushPayload(
            targetUserID: partnerID.uuidString,
            title: title,
            body: body,
            type: type
        )
        
        do {
            try await SupabaseService.shared.client.functions.invoke(
                "send-push",
                options: .init(body: payload)
            )
            print("📬 Partner push sent: \(type)")
        } catch {
            print("📬 Partner push failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Party-Wide Notifications (Cross-Device)
    
    /// Send a push notification to a specific user by their UUID.
    func notifyUser(userID: UUID, type: String, title: String, body: String) async {
        let payload = PushPayload(
            targetUserID: userID.uuidString,
            title: title,
            body: body,
            type: type
        )
        
        do {
            try await SupabaseService.shared.client.functions.invoke(
                "send-push",
                options: .init(body: payload)
            )
            print("📬 Push sent to \(userID.uuidString.prefix(8)): \(type)")
        } catch {
            print("📬 Push to \(userID.uuidString.prefix(8)) failed: \(error.localizedDescription)")
        }
    }
    
    /// Send a push notification to all party members (excluding self).
    func notifyPartyMembers(memberIDs: [UUID], type: String, title: String, body: String) async {
        guard let selfID = SupabaseService.shared.currentUserID else { return }
        
        for memberID in memberIDs where memberID != selfID {
            await notifyUser(userID: memberID, type: type, title: title, body: body)
        }
    }
    
    /// Convenience: notify all party members about a dungeon invite.
    func notifyPartyDungeonInvite(memberIDs: [UUID], fromName: String, dungeonName: String) async {
        await notifyPartyMembers(
            memberIDs: memberIDs,
            type: "dungeon_invite",
            title: "Party Dungeon Invite!",
            body: "\(fromName) invites you to run \(dungeonName) together!"
        )
    }
    
    // MARK: - Convenience Partner Methods
    
    func notifyPartnerNudge(fromName: String) async {
        await notifyPartner(
            type: "nudge",
            title: "Nudge!",
            body: "\(fromName) sent you a nudge! Time to get questing!"
        )
    }
    
    func notifyPartnerKudos(fromName: String, bondEXP: Int) async {
        await notifyPartner(
            type: "kudos",
            title: "Kudos!",
            body: "\(fromName) sent you kudos! +\(bondEXP) Bond EXP"
        )
    }
    
    func notifyPartnerChallenge(fromName: String) async {
        await notifyPartner(
            type: "challenge",
            title: "Challenge!",
            body: "\(fromName) challenged you! Open the app to respond."
        )
    }
    
    func notifyPartnerTaskAssigned(fromName: String, taskTitle: String) async {
        await notifyPartner(
            type: "task_assigned",
            title: "New Quest from \(fromName)!",
            body: "\"\(taskTitle)\" — tap to view"
        )
    }
    
    func notifyPartnerTaskComplete(characterName: String, taskTitle: String) async {
        await notifyPartner(
            type: "task_complete",
            title: "Quest Completed!",
            body: "\(characterName) completed \"\(taskTitle)\""
        )
    }
    
    func notifyPartnerTaskConfirmed(fromName: String, taskTitle: String) async {
        await notifyPartner(
            type: "task_confirmed",
            title: "Quest Confirmed!",
            body: "\(fromName) confirmed your completion of \"\(taskTitle)\""
        )
    }
    
    func notifyPartnerTaskDisputed(fromName: String, taskTitle: String) async {
        await notifyPartner(
            type: "task_disputed",
            title: "Quest Disputed",
            body: "\(fromName) disputed your completion of \"\(taskTitle)\""
        )
    }
    
    func notifyPartnerPairRequest(fromName: String) async {
        // This targets a specific user, not necessarily the current partner
        // The Edge Function handles the targeting
        await notifyPartner(
            type: "pair_request",
            title: "Partner Request!",
            body: "\(fromName) wants to pair with you in Swords & Chores!"
        )
    }
    
    func notifyPartnerStreakAtRisk(partnerName: String) async {
        await notifyPartner(
            type: "streak_risk",
            title: "Partner Streak at Risk!",
            body: "Your partner \(partnerName)'s streak is at risk! Send them a nudge."
        )
    }
}
