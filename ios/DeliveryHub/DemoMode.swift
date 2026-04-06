import Foundation

final class DemoMode {
    static let shared = DemoMode()
    private init() {}

    var isActive = false

    static let demoUser = User(
        id: "demo-user-001",
        email: "demo@ai-nouki.com",
        name: "デモ ユーザー",
        role: "ADMIN",
        status: "ACTIVE"
    )

    static let demoCompany = Company(
        id: "demo-company-001",
        name: "デモ商事株式会社"
    )

    static var demoDeliveries: [Delivery] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        func date(offsetDays: Int) -> Date {
            cal.date(byAdding: .day, value: offsetDays, to: today) ?? today
        }

        return [
            Delivery(id: "d1", productName: "鉄筋 D13 (6m)", quantity: 200,
                     deliveryDate: date(offsetDays: 0), status: .pending,
                     supplierName: "山田鉄鋼", notes: nil, sourceUrl: nil),
            Delivery(id: "d2", productName: "コンクリートブロック", quantity: 500,
                     deliveryDate: date(offsetDays: 0), status: .shipped,
                     supplierName: "東京建材", notes: "午後便", sourceUrl: nil),
            Delivery(id: "d3", productName: "型枠合板 12mm", quantity: 100,
                     deliveryDate: date(offsetDays: 1), status: .pending,
                     supplierName: "木材センター", notes: nil, sourceUrl: nil),
            Delivery(id: "d4", productName: "生コンクリート 30N", quantity: 30,
                     deliveryDate: date(offsetDays: 3), status: .pending,
                     supplierName: "近畿生コン", notes: "ミキサー2台", sourceUrl: nil),
            Delivery(id: "d5", productName: "足場資材セット", quantity: 1,
                     deliveryDate: date(offsetDays: -3), status: .delivered,
                     supplierName: "安全足場", notes: nil, sourceUrl: nil),
            Delivery(id: "d6", productName: "電線ケーブル VVF 2.0", quantity: 300,
                     deliveryDate: date(offsetDays: -10), status: .delivered,
                     supplierName: "電材ショップ", notes: nil, sourceUrl: nil),
        ]
    }

    static func demoChatReply(for message: String) -> String {
        let lower = message.lowercased()
        if lower.contains("今日") || lower.contains("本日") {
            return "本日の入荷予定は2件です。\n• 鉄筋 D13 (6m) × 200本（山田鉄鋼）— 未着\n• コンクリートブロック × 500個（東京建材）— 出荷済\n\n準備にご注意ください。"
        } else if lower.contains("明日") {
            return "明日の入荷予定は1件です。\n• 型枠合板 12mm × 100枚（木材センター）— 未着"
        } else if lower.contains("遅延") || lower.contains("delayed") {
            return "現在、遅延している入荷予定はありません。"
        } else if lower.contains("在庫") || lower.contains("stock") {
            return "現在の登録入荷予定：合計4件（本日2件、明日1件、今後1件）\n詳細は入荷予定タブをご確認ください。"
        } else {
            return "ご質問ありがとうございます。現在のデモ環境では、「今日」「明日」「在庫」「遅延」などのキーワードで入荷情報を検索できます。"
        }
    }
}
