import Foundation

nonisolated enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case serverError(Int, String)
    case unauthorized
    case networkUnavailable
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "URLが無効です。"
        case .noData: return "データが取得できませんでした。"
        case .decodingError: return "データの解析に失敗しました。"
        case .serverError(let code, let msg): return "サーバーエラー (\(code)): \(msg)"
        case .unauthorized: return "ログインが必要です。再度ログインしてください。"
        case .networkUnavailable: return "ネットワークに接続できません。電波の良い場所で再試行してください。"
        case .unknown(let e): return "エラーが発生しました: \(e.localizedDescription)"
        }
    }
}

nonisolated final class NetworkService: Sendable {
    static let shared = NetworkService()
    private let baseURL = Config.apiBaseURL

    private func makeRequest(path: String, method: String = "GET", body: Data? = nil) throws -> URLRequest {
        guard let url = URL(string: baseURL + path) else { throw NetworkError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = KeychainService.loadToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = body
        return request
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw NetworkError.noData }

            if http.statusCode == 401 || http.statusCode == 403 {
                NotificationCenter.default.post(name: .unauthorized, object: nil)
                throw NetworkError.unauthorized
            }
            guard (200..<300).contains(http.statusCode) else {
                let msg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String
                    ?? String(data: data, encoding: .utf8) ?? "サーバーエラー"
                throw NetworkError.serverError(http.statusCode, msg)
            }
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                throw NetworkError.decodingError(error)
            }
        } catch let error as NetworkError {
            throw error
        } catch let error as URLError {
            if error.code == .notConnectedToInternet || error.code == .networkConnectionLost {
                throw NetworkError.networkUnavailable
            }
            throw NetworkError.unknown(error)
        } catch {
            throw NetworkError.unknown(error)
        }
    }

    func login(email: String, password: String) async throws -> LoginResponse {
        let body = try JSONEncoder().encode(["email": email, "password": password])
        let request = try makeRequest(path: "/api/mobile/login", method: "POST", body: body)
        return try await perform(request)
    }

    func fetchDeliveries() async throws -> [Delivery] {
        let request = try makeRequest(path: "/api/mobile/deliveries")
        return try await perform(request)
    }

    func sendChat(message: String) async throws -> String {
        struct ChatReq: Codable { let message: String }
        struct ChatRes: Codable { let response: String }
        let body = try JSONEncoder().encode(ChatReq(message: message))
        // AIチャットは /api/admin/chat を使用（/api/mobile/chat はチームメッセージ用）
        let request = try makeRequest(path: "/api/admin/chat", method: "POST", body: body)
        let res: ChatRes = try await perform(request)
        return res.response
    }

    func sendOrderRequest(productName: String, quantity: Int, details: String?, imageBase64: String?) async throws {
        struct OrderReq: Codable {
            let productName: String
            let quantity: Int
            let details: String?
        }
        let body = try JSONEncoder().encode(OrderReq(productName: productName, quantity: quantity, details: details))
        let request = try makeRequest(path: "/api/mobile/request", method: "POST", body: body)
        struct Empty: Codable {}
        let _: Empty = try await perform(request)
    }
}
