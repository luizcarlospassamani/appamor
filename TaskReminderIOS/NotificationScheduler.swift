import Foundation
import UserNotifications

final class NotificationScheduler {
    static let shared = NotificationScheduler()

    private let center = UNUserNotificationCenter.current()

    private init() {}

    func currentAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    func requestAuthorizationIfNeeded() async throws -> Bool {
        let status = await currentAuthorizationStatus()

        switch status {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        @unknown default:
            return false
        }
    }

    func scheduleNotification(for task: ReminderTask) async throws {
        let interval = TimeInterval(max(task.intervalMinutes * 60, 60))

        let content = UNMutableNotificationContent()
        content.title = "Lembrete de atividade"
        content.body = task.title
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: true)
        let request = UNNotificationRequest(
            identifier: task.notificationIdentifier,
            content: content,
            trigger: trigger
        )

        center.removePendingNotificationRequests(withIdentifiers: [task.notificationIdentifier])
        try await center.add(request)
    }

    func removeNotification(for task: ReminderTask) {
        center.removePendingNotificationRequests(withIdentifiers: [task.notificationIdentifier])
        center.removeDeliveredNotifications(withIdentifiers: [task.notificationIdentifier])
    }

    func rescheduleNotifications(for tasks: [ReminderTask]) async {
        for task in tasks {
            try? await scheduleNotification(for: task)
        }
    }
}
