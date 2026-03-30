import Foundation

nonisolated struct Delivery: Codable, Identifiable {
    let id: String
    let productName: String
    let quantity: Int
    let deliveryDate: Date
    let supplierName: String?
    let notes: String?
    let sourceUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, productName, quantity, deliveryDate, supplierName, notes, sourceUrl
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        productName = try container.decode(String.self, forKey: .productName)
        quantity = try container.decode(Int.self, forKey: .quantity)
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
