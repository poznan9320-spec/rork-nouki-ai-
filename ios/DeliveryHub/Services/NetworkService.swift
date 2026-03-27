import Foundation
import UIKit

extension UIImage {
    func resizedForOCR(maxSide: CGFloat) -> UIImage {
        let size = self.size
        guard size.width > maxSide || size.height > maxSide else { return self }
        let scale = maxSide / max(size.width, size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in self.draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}

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

// nonisolated to avoid @MainActor inference
// (project uses SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor)
nonisolated struct OCRItem: Codable, Identifiable {
    var id: String = UUID().uuidString
    var productName: String
    var quantity: Int
    var deliveryDate: String  // YYYY-MM-DD
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case productName, quantity, deliveryDate, notes
    }
}

nonisolated struct OCRResponse: Codable {
    let items: [OCRItem]
    let sourceType: String
    let supplierName: String?
    let fileUrl: String?
}

nonisolated struct SaveResponse: Codable {
    let imported: Int
    let skipped: Int
}

nonisolated struct NotificationSettings: Codable {
    var todayHour: Int
    var tomorrowHour: Int
    var enabled: Bool
}

nonisolated final class NetworkService: Sendable {
    static let shared = NetworkService()
    // URL inlined directly to avoid naming conflict with RORK-generated Config type
    private let baseURL = "https://ai-nouki2.vercel.app"

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

    func fetchCurrentUser() async throws -> (user: User, company: Company) {
        struct MeResponse: Codable { let user: User; let company: Company }
        let request = try makeRequest(path: "/api/auth/me")
        let res: MeResponse = try await perform(request)
        return (res.user, res.company)
    }

    func fetchDeliveries() async throws -> [Delivery] {
        let request = try makeRequest(path: "/api/mobile/deliveries")
        return try await perform(request)
    }

    func sendChat(message: String) async throws -> String {
        struct ChatReq: Codable { let message: String }
        struct ChatRes: Codable { let response: String }
        let body = try JSONEncoder().encode(ChatReq(message: message))
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

    // MARK: - OCR Ingest

    func ingestOCR(imageData: Data?, mimeType: String = "image/jpeg", text: String?, supplierName: String?) async throws -> OCRResponse {
        guard let url = URL(string: baseURL + "/api/ingest/ocr") else { throw NetworkError.invalidURL }

        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()

        func append(_ string: String) {
            body.append(Data(string.utf8))
        }

        if let imageData = imageData {
            append("--\(boundary)\r\n")
            append("Content-Disposition: form-data; name=\"file\"; filename=\"photo.jpg\"\r\n")
            append("Content-Type: \(mimeType)\r\n\r\n")
            body.append(imageData)
            append("\r\n")
        }

        if let text = text, !text.isEmpty {
            append("--\(boundary)\r\n")
            append("Content-Disposition: form-data; name=\"text\"\r\n\r\n")
            append(text)
            append("\r\n")
        }

        if let supplierName = supplierName, !supplierName.isEmpty {
            append("--\(boundary)\r\n")
            append("Content-Disposition: form-data; name=\"supplierName\"\r\n\r\n")
            append(supplierName)
            append("\r\n")
        }

        append("--\(boundary)--\r\n")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if let token = KeychainService.loadToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = body

        return try await perform(request)
    }

    func ingestSave(items: [OCRItem], supplierName: String?, sourceType: String, sourceUrl: String?) async throws -> SaveResponse {
        struct SaveReq: Codable {
            let items: [OCRItem]
            let supplierName: String?
            let sourceType: String
            let sourceUrl: String?
        }
        let body = try JSONEncoder().encode(SaveReq(items: items, supplierName: supplierName, sourceType: sourceType, sourceUrl: sourceUrl))
        let request = try makeRequest(path: "/api/ingest/save", method: "POST", body: body)
        return try await perform(request)
    }

    func fetchNotificationSettings() async throws -> NotificationSettings {
        let request = try makeRequest(path: "/api/mobile/notification-settings")
        return try await perform(request)
    }

    func updateNotificationSettings(_ settings: NotificationSettings) async throws -> NotificationSettings {
        let body = try JSONEncoder().encode(settings)
        let request = try makeRequest(path: "/api/mobile/notification-settings", method: "PUT", body: body)
        return try await perform(request)
    }

    func registerEmployee(name: String, email: String, password: String, joinCode: String) async throws {
        struct RegReq: Codable {
            let name: String
            let email: String
            let password: String
            let joinCode: String
        }
        let body = try JSONEncoder().encode(RegReq(name: name, email: email, password: password, joinCode: joinCode))
        let request = try makeRequest(path: "/api/mobile/register-employee", method: "POST", body: body)
        struct Empty: Codable {}
        let _: Empty = try await perform(request)
    }
}
