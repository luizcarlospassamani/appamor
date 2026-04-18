import Foundation
import UserNotifications

@MainActor
final class ReminderListViewModel: ObservableObject {
    struct AlertMessage: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    @Published var tasks: [ReminderTask] = []
    @Published var newTaskTitle = ""
    @Published var selectedInterval = 30
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var alertMessage: AlertMessage?

    let intervalOptions = [15, 30, 45, 60, 90, 120, 180, 240]

    private let storageKey = "reminder_tasks_storage"
    private let notificationScheduler = NotificationScheduler.shared
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        loadTasks()

        Task {
            await refreshAuthorizationStatus()

            if authorizationStatus == .authorized || authorizationStatus == .provisional || authorizationStatus == .ephemeral {
                await notificationScheduler.rescheduleNotifications(for: tasks)
            }
        }
    }

    func refreshAuthorizationStatus() async {
        authorizationStatus = await notificationScheduler.currentAuthorizationStatus()
    }

    func requestNotificationPermission() async {
        do {
            let granted = try await notificationScheduler.requestAuthorizationIfNeeded()
            await refreshAuthorizationStatus()

            if granted {
                await notificationScheduler.rescheduleNotifications(for: tasks)
            } else {
                alertMessage = AlertMessage(
                    title: "Notificacoes desativadas",
                    message: "Ative as notificacoes para receber lembretes das atividades."
                )
            }
        } catch {
            alertMessage = AlertMessage(
                title: "Erro ao solicitar permissao",
                message: "Nao foi possivel solicitar acesso a notificacoes."
            )
        }
    }

    func addTask() async {
        let trimmedTitle = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            alertMessage = AlertMessage(
                title: "Atividade vazia",
                message: "Digite o nome da atividade antes de salvar."
            )
            return
        }

        let granted = try? await notificationScheduler.requestAuthorizationIfNeeded()
        await refreshAuthorizationStatus()

        guard granted == true else {
            alertMessage = AlertMessage(
                title: "Permissao necessaria",
                message: "O iPhone precisa permitir notificacoes para criar lembretes recorrentes."
            )
            return
        }

        let task = ReminderTask(title: trimmedTitle, intervalMinutes: selectedInterval)

        do {
            try await notificationScheduler.scheduleNotification(for: task)
            tasks.insert(task, at: 0)
            persistTasks()
            newTaskTitle = ""
        } catch {
            alertMessage = AlertMessage(
                title: "Erro ao agendar lembrete",
                message: "Nao foi possivel criar o alerta local para essa atividade."
            )
        }
    }

    func deleteTasks(at offsets: IndexSet) {
        let tasksToDelete = offsets.map { tasks[$0] }

        for task in tasksToDelete {
            notificationScheduler.removeNotification(for: task)
        }

        tasks.remove(atOffsets: offsets)
        persistTasks()
    }

    func authorizationStatusText() -> String {
        switch authorizationStatus {
        case .authorized:
            return "Notificacoes liberadas"
        case .denied:
            return "Notificacoes bloqueadas"
        case .notDetermined:
            return "Permissao pendente"
        case .provisional:
            return "Permissao provisoria"
        case .ephemeral:
            return "Permissao temporaria"
        @unknown default:
            return "Status desconhecido"
        }
    }

    func intervalDescription(for minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) min"
        }

        if minutes.isMultiple(of: 60) {
            return "\(minutes / 60) h"
        }

        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return "\(hours) h \(remainingMinutes) min"
    }

    private func loadTasks() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let decodedTasks = try? decoder.decode([ReminderTask].self, from: data)
        else {
            return
        }

        tasks = decodedTasks.sorted { $0.createdAt > $1.createdAt }
    }

    private func persistTasks() {
        guard let data = try? encoder.encode(tasks) else {
            return
        }

        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
