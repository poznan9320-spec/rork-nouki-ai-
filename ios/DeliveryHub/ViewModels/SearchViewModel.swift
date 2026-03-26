import SwiftUI

struct SearchHistoryItem: Identifiable {
    let id: UUID = UUID()
    let query: String
    let reply: String
    let date: Date
}

@Observable
final class SearchViewModel {
    var query: String = ""
    var currentReply: String? = nil
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var history: [SearchHistoryItem] = []

    @MainActor
    func search() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        currentReply = nil
        do {
            let reply = try await NetworkService.shared.sendChat(message: trimmed)
            currentReply = reply
            history.insert(SearchHistoryItem(query: trimmed, reply: reply, date: Date()), at: 0)
            if history.count > 20 { history = Array(history.prefix(20)) }
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "検索に失敗しました。"
        }
        isLoading = false
    }

    func clear() {
        query = ""
        currentReply = nil
        errorMessage = nil
    }
}
