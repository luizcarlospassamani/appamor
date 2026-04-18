import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ReminderListViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Lembretes de atividades")
                            .font(.title2.bold())

                        Text("Cadastre uma atividade e escolha o intervalo para receber alertas recorrentes no iPhone.")
                            .foregroundStyle(.secondary)

                        HStack {
                            Image(systemName: statusIconName)
                                .foregroundStyle(statusColor)

                            Text(viewModel.authorizationStatusText())
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(statusColor)
                        }

                        Button("Ativar notificacoes") {
                            Task {
                                await viewModel.requestNotificationPermission()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical, 8)
                }

                Section("Nova atividade") {
                    TextField("Ex.: Beber agua, alongar, revisar tarefas", text: $viewModel.newTaskTitle)

                    Picker("Intervalo do lembrete", selection: $viewModel.selectedInterval) {
                        ForEach(viewModel.intervalOptions, id: \.self) { interval in
                            Text(viewModel.intervalDescription(for: interval)).tag(interval)
                        }
                    }

                    Button("Salvar atividade") {
                        Task {
                            await viewModel.addTask()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity, alignment: .center)
                }

                Section("Atividades salvas") {
                    if viewModel.tasks.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nenhuma atividade cadastrada")
                                .font(.headline)

                            Text("Crie a primeira atividade acima para comecar a receber lembretes.")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                    } else {
                        ForEach(viewModel.tasks) { task in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(task.title)
                                    .font(.headline)

                                Label(
                                    "A cada \(viewModel.intervalDescription(for: task.intervalMinutes))",
                                    systemImage: "bell.badge"
                                )
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: viewModel.deleteTasks)
                    }
                }
            }
            .navigationTitle("Atividades")
            .alert(item: $viewModel.alertMessage) { message in
                Alert(
                    title: Text(message.title),
                    message: Text(message.message),
                    dismissButton: .default(Text("OK"))
                )
            }
            .task {
                await viewModel.refreshAuthorizationStatus()
            }
        }
    }

    private var statusIconName: String {
        switch viewModel.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return "checkmark.circle.fill"
        case .denied:
            return "xmark.circle.fill"
        case .notDetermined:
            return "bell.badge"
        @unknown default:
            return "questionmark.circle.fill"
        }
    }

    private var statusColor: Color {
        switch viewModel.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return .green
        case .denied:
            return .red
        case .notDetermined:
            return .orange
        @unknown default:
            return .gray
        }
    }
}

#Preview {
    ContentView()
}
