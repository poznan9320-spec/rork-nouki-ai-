import Foundation

enum DeliveryStatus: String, Codable {
    case pending = "PENDING"
    case shipped = "SHIPPED"
    case delivered = "DELIVERED"
    case delayed = "DELAYED"
    case cancelled = "CANCELLED"
    case unknown

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = DeliveryStatus(rawValue: raw) ?? .unknown
    }

    var displayName: String {
        switch self {
        case .pending:   return "未着"
        case .shipped:   return "出荷済"
        case .delivered: return "着荷"
        case .delayed:   return "遅延"
        case .cancelled: return "キャンセル"
        case .unknown:   return "不明"
        }
    }
}

nonisolated struct Delivery: Codable, Identifiable {
    let id: String
    let productName: String
    let quantity: Int
    let deliveryDate: Date
    let status: DeliveryStatus
    let supplierName: String?
    let notes: String?
    let sourceUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, productName, quantity, deliveryDate, status, supplierName, notes, sourceUrl
    }

    nonisolated init(id: String, productName: String, quantity: Int, deliveryDate: Date,
                     status: DeliveryStatus, supplierName: String?, notes: String?, sourceUrl: String?) {
        self.id = id
        self.productName = productName
        self.quantity = quantity
        self.deliveryDate = deliveryDate
        self.status = status
        self.supplierName = supplierName
        self.notes = notes
        self.sourceUrl = sourceUrl
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        productName = try container.decode(String.self, forKey: .productName)
        quantity = try container.decode(Int.self, forKey: .quantity)
        status = try container.decodeIfPresent(DeliveryStatus.self, forKey: .status) ?? .pending
        supplierName = try container.decodeIfPresent(String.self, forKey: .supplierName)
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
