import Foundation

nonisolated enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case serverError(Int, String)
    case networkUnavailable
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "URLが無効です。"
        case .noData: return "データが取得できませんでした。"
        case .decodingError: return "データの解析に失敗しました。"
        case .serverError(let code, let msg): return "サーバーエラー (\(code)): \(msg)"
        case .networkUnavailable: return "ネットワークに接続できません。電波の良い場所で再試行してください。"
        case .unknown(let e): return "エラーが発生しました: \(e.localizedDescription)"
        }
    }
}

nonisolated final class NetworkService: Sendable {
    static let shared = NetworkService()

    private let baseURL = "https://ce199d0aa29ce8.lhr.life"
    private let companyID = "c063417b"

    private var defaultHeaders: [String: String] {
        [
            "X-Company-ID": companyID,
            "Content-Type": "application/json"
        ]
    }

    private func makeRequest(path: String, method: String = "GET", body: Data? = nil) throws -> URLRequest {
        guard let url = URL(string: baseURL + path) else { throw NetworkError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 30
        defaultHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        request.httpBody = body
        return request
    }

    func fetchDeliveries() async throws -> [Delivery] {
        let request = try makeRequest(path: "/api/mobile/deliveries")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                let msg = String(data: data, encoding: .utf8) ?? "不明なエラー"
                throw NetworkError.serverError(httpResponse.statusCode, msg)
            }
            let decoder = JSONDecoder()
            return try decoder.decode([Delivery].self, from: data)
        } catch let error as NetworkError {
            throw error
        } catch let error as URLError {
            if error.code == .notConnectedToInternet || error.code == .networkConnectionLost {
                throw NetworkError.networkUnavailable
            }
            throw NetworkError.unknown(error)
        } catch let error as DecodingError {
            throw NetworkError.decodingError(error)
        } catch {
            throw NetworkError.unknown(error)
        }
    }

    func sendChat(query: String) async throws -> String {
        let body = try JSONEncoder().encode(ChatRequest(query: query))
        let request = try makeRequest(path: "/api/mobile/chat", method: "POST", body: body)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                let msg = String(data: data, encoding: .utf8) ?? "不明なエラー"
                throw NetworkError.serverError(httpResponse.statusCode, msg)
            }
            let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
            return decoded.reply
        } catch let error as NetworkError {
            throw error
        } catch let error as URLError {
            if error.code == .notConnectedToInternet || error.code == .networkConnectionLost {
                throw NetworkError.networkUnavailable
            }
            throw NetworkError.unknown(error)
        } catch let error as DecodingError {
            throw NetworkError.decodingError(error)
        } catch {
            throw NetworkError.unknown(error)
        }
    }

    func sendOrderRequest(productName: String, quantity: Int, memo: String, imageBase64: String?) async throws {
        let orderRequest = OrderRequest(productName: productName, quantity: quantity, memo: memo, image: imageBase64)
        let body = try JSONEncoder().encode(orderRequest)
        let request = try makeRequest(path: "/api/mobile/request", method: "POST", body: body)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                let msg = String(data: data, encoding: .utf8) ?? "不明なエラー"
                throw NetworkError.serverError(httpResponse.statusCode, msg)
            }
            _ = data
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
}
