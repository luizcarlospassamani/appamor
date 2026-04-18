# TaskReminderIOS

Aplicativo iOS simples, feito em SwiftUI, para cadastrar atividades e receber lembretes recorrentes por notificacoes locais.

## O que o app faz

- Cadastra uma atividade com titulo e intervalo de lembrete
- Solicita permissao para notificacoes
- Agenda alertas locais recorrentes
- Lista atividades salvas no aparelho
- Permite remover uma atividade e cancelar o lembrete correspondente

## Como abrir

1. Abra o arquivo `TaskReminderIOS.xcodeproj` no Xcode
2. Em `Signing & Capabilities`, ajuste o `Team` da sua conta Apple
3. Rode no simulador ou iPhone

## Observacoes

- O app usa `UserDefaults` para persistencia local
- As notificacoes sao locais, sem backend
- O iOS exige intervalo minimo de 60 segundos para notificacoes recorrentes
