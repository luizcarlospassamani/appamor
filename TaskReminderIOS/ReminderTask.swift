import Foundation

struct ReminderTask: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var intervalMinutes: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        intervalMinutes: Int,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.intervalMinutes = intervalMinutes
        self.createdAt = createdAt
    }

    var notificationIdentifier: String {
        id.uuidString
    }
}
