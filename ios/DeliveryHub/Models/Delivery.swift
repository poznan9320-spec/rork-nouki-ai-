import Foundation

nonisolated enum DeliveryStatus: String, Codable, CaseIterable {
    case pending = "PENDING"
    case confirmed = "CONFIRMED"
    case shipped = "SHIPPED"
    case delivered = "DELIVERED"
    case cancelled = "CANCELLED"
    case unknown = "UNKNOWN"

    var displayName: String {
        switch self {
        case .pending: return "入荷待ち"
        case .confirmed: return "確定"
        case .shipped: return "出荷済"
        case .delivered: return "入荷済"
        case .cancelled: return "キャンセル"
        case .unknown: return "不明"
        }
    }
}

nonisolated struct Delivery: Codable, Identifiable {
    let id: String
    let productName: String
    let quantity: Int
    let deliveryDate: Date
    let manufacturer: String
    let status: DeliveryStatus
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id, productName, quantity, deliveryDate, manufacturer, status, notes
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        productName = try container.decode(String.self, forKey: .productName)
        quantity = try container.decode(Int.self, forKey: .quantity)
        manufacturer = try container.decode(String.self, forKey: .manufacturer)
        let statusStr = try container.decodeIfPresent(String.self, forKey: .status) ?? "PENDING"
        status = DeliveryStatus(rawValue: statusStr) ?? .unknown
        notes = try container.decodeIfPresent(String.self, forKey: .notes)

        let dateStr = try container.decode(String.self, forKey: .deliveryDate)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateStr) {
            deliveryDate = date
        } else {
            formatter.formatOptions = [.withInternetDateTime]
            deliveryDate = formatter.date(from: dateStr) ?? Date()
        }
    }
}

nonisolated struct ChatResponse: Codable {
    let reply: String
}

nonisolated struct ChatRequest: Codable {
    let query: String
}

nonisolated struct OrderRequest: Codable {
    let productName: String
    let quantity: Int
    let memo: String
    let image: String?
}

nonisolated struct OrderResponse: Codable {
    let success: Bool?
    let message: String?
    let id: String?
}
