import Foundation

nonisolated enum DeliveryStatus: String, Codable, CaseIterable {
    case pending = "PENDING"
    case shipped = "SHIPPED"
    case delivered = "DELIVERED"
    case delayed = "DELAYED"
    case cancelled = "CANCELLED"
    case unknown = "UNKNOWN"

    var displayName: String {
        switch self {
        case .pending: return "入荷待ち"
        case .shipped: return "出荷済"
        case .delivered: return "入荷済"
        case .delayed: return "遅延"
        case .cancelled: return "キャンセル"
        case .unknown: return "不明"
        }
    }

    var colorHex: String {
        switch self {
        case .pending: return "F59E0B"
        case .shipped: return "3B82F6"
        case .delivered: return "10B981"
        case .delayed: return "EF4444"
        case .cancelled: return "6B7280"
        case .unknown: return "6B7280"
        }
    }
}

nonisolated struct Delivery: Codable, Identifiable {
    let id: String
    let productName: String
    let quantity: Int
    let deliveryDate: Date
    let supplierName: String?
    let status: DeliveryStatus
    let notes: String?
    let sourceUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, productName, quantity, deliveryDate, supplierName, status, notes, sourceUrl
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        productName = try container.decode(String.self, forKey: .productName)
        quantity = try container.decode(Int.self, forKey: .quantity)
        supplierName = try container.decodeIfPresent(String.self, forKey: .supplierName)
        let statusStr = try container.decodeIfPresent(String.self, forKey: .status) ?? "PENDING"
        status = DeliveryStatus(rawValue: statusStr) ?? .unknown
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        sourceUrl = try container.decodeIfPresent(String.self, forKey: .sourceUrl)

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
