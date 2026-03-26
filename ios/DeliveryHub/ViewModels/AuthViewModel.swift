import Foundation

@Observable
final class AuthViewModel {
    var isLoggedIn: Bool = false
    var user: User?
    var company: Company?
    var isLoading = false
    var errorMessage: String?

    init() {
        isLoggedIn = KeychainService.loadToken() != nil
    }

    @MainActor
    func login(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "メールアドレスとパスワードを入力してください"
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let response = try await NetworkService.shared.login(email: email, password: password)
            KeychainService.saveToken(response.token)
            user = response.user
            company = response.company
            isLoggedIn = true
        } catch let error as NetworkError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func logout() {
        KeychainService.deleteToken()
        isLoggedIn = false
        user = nil
        company = nil
    }
}
