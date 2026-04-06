import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    enum Role { case user, assistant }
    let role: Role
    let content: String
}

@Observable
final class SearchViewModel {
    var messages: [ChatMessage] = []
    var input: String = ""
    var isLoading: Bool = false
    var errorMessage: String? = nil

    @MainActor
    func send() async {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        messages.append(ChatMessage(role: .user, content: trimmed))
        input = ""

        if DemoMode.shared.isActive {
            isLoading = true
            try? await Task.sleep(nanoseconds: 800_000_000) // simulate network delay
            messages.append(ChatMessage(role: .assistant, content: DemoMode.demoChatReply(for: trimmed)))
            isLoading = false
            return
        }

        isLoading = true
        errorMessage = nil
        do {
            let reply = try await NetworkService.shared.sendChat(message: trimmed)
            messages.append(ChatMessage(role: .assistant, content: reply))
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "送信に失敗しました。"
        }
        isLoading = false
    }
}
