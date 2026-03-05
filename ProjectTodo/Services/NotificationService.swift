import Foundation
import UserNotifications
import SwiftData

/// Centralized notification service for task reminders, habit prompts, and streak alerts
@MainActor
class NotificationService {
    static let shared = NotificationService()
    
    private let center = UNUserNotificationCenter.current()
    
    // MARK: - Permission
    
    /// Request notification permission (call on first task with a due date or first habit)
    func requestPermissionIfNeeded() {
        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                self.center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if let error = error {
                        print("[NotificationService] Permission error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // MARK: - Due Date Reminders
    
    /// Schedule reminders for a task's due date (1 hour before and at due time)
    func scheduleDueDateReminders(for task: GameTask) {
        guard let dueDate = task.dueDate else { return }
        requestPermissionIfNeeded()
        
        let taskID = task.id.uuidString
        
        // 1 hour before
        let oneHourBefore = dueDate.addingTimeInterval(-3600)
        if oneHourBefore > Date() {
            let content = UNMutableNotificationContent()
            content.title = "Task Due Soon"
            content.body = "\"\(task.title)\" is due in 1 hour"
            content.sound = .default
            content.categoryIdentifier = "TASK_REMINDER"
            
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: oneHourBefore)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "task-due-1h-\(taskID)",
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
        
        // At due time
        if dueDate > Date() {
            let content = UNMutableNotificationContent()
            content.title = "Task Due Now"
            content.body = "\"\(task.title)\" is due now!"
            content.sound = .default
            content.categoryIdentifier = "TASK_REMINDER"
            
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "task-due-now-\(taskID)",
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }
    
    /// Cancel due date reminders when a task is completed or deleted
    func cancelDueDateReminders(for task: GameTask) {
        let taskID = task.id.uuidString
        center.removePendingNotificationRequests(withIdentifiers: [
            "task-due-1h-\(taskID)",
            "task-due-now-\(taskID)"
        ])
    }
    
    // MARK: - Daily Habit Reminders
    
    /// Schedule a daily habit reminder at 9 AM
    func scheduleHabitReminder() {
        requestPermissionIfNeeded()
        
        let content = UNMutableNotificationContent()
        content.title = "Daily Habits"
        content.body = "Time to check in on your daily habits!"
        content.sound = .default
        content.categoryIdentifier = "HABIT_REMINDER"
        
        // Every day at 9 AM
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "daily-habit-reminder",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }
    
    /// Schedule a notification 15 minutes before a habit's due time.
    func scheduleHabitDeadlineReminder(habitName: String, habitID: UUID, deadline: Date) {
        PushNotificationService.shared.scheduleHabitDeadline(
            habitName: habitName,
            habitID: habitID.uuidString,
            deadline: deadline
        )
    }
    
    /// Cancel a habit deadline notification.
    func cancelHabitDeadlineReminder(habitID: UUID) {
        PushNotificationService.shared.cancelHabitDeadline(habitID: habitID.uuidString)
    }
    
    /// Cancel the daily habit reminder
    func cancelHabitReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["daily-habit-reminder"])
    }
    
    // MARK: - Streak At Risk
    
    /// Schedule an evening reminder if no tasks have been completed today (8 PM check)
    func scheduleStreakAtRiskReminder(streakDays: Int = 0) {
        requestPermissionIfNeeded()
        
        let content = UNMutableNotificationContent()
        content.title = "Streak at Risk!"
        content.body = streakDays > 0
            ? "Complete a task before midnight to keep your \(streakDays)-day streak!"
            : "You haven't completed any tasks today. Don't break your streak!"
        content.sound = .default
        content.categoryIdentifier = "STREAK_REMINDER"
        
        // Every day at 8 PM
        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "streak-at-risk",
            content: content,
            trigger: trigger
        )
        center.add(request)
        
        // Also schedule via PushNotificationService for richer notification
        PushNotificationService.shared.scheduleStreakAtRisk(streakDays: streakDays)
    }
    
    /// Cancel the streak at risk reminder (call when a task is completed today)
    func cancelStreakAtRiskReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["streak-at-risk"])
        PushNotificationService.shared.cancelStreakAtRisk()
    }
    
    // MARK: - Batch Operations
    
    /// Schedule reminders for all tasks with due dates (call on app launch)
    func scheduleAllDueDateReminders(context: ModelContext) {
        let descriptor = FetchDescriptor<GameTask>(
            predicate: #Predicate<GameTask> { task in
                task.dueDate != nil
            }
        )
        
        guard let tasks = try? context.fetch(descriptor) else { return }
        
        for task in tasks {
            let statusRaw = task.status.rawValue
            if statusRaw != "Completed" && statusRaw != "Expired" {
                scheduleDueDateReminders(for: task)
            }
        }
    }
    
    /// Set up all recurring reminders (habits + streak protection)
    func setupRecurringReminders(hasHabits: Bool, hasStreak: Bool) {
        if hasHabits {
            scheduleHabitReminder()
        } else {
            cancelHabitReminder()
        }
        
        if hasStreak {
            scheduleStreakAtRiskReminder()
        } else {
            cancelStreakAtRiskReminder()
        }
    }
    
    /// Cancel all pending notifications
    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }
}
