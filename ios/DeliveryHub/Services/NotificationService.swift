import UserNotifications
import Foundation

final class NotificationService: @unchecked Sendable {
    static let shared = NotificationService()

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .authorized { return true }
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    func scheduleDeliveryNotifications(deliveries: [Delivery]) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized else { return }

        // 既存の納期通知を削除
        center.removePendingNotificationRequests(withIdentifiers: [
            "today_delivery", "tomorrow_delivery"
        ])

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) else { return }

        let todayItems = deliveries.filter { calendar.isDate($0.deliveryDate, inSameDayAs: today) }
        let tomorrowItems = deliveries.filter { calendar.isDate($0.deliveryDate, inSameDayAs: tomorrow) }

        // 本日の入荷 → 朝7時に通知
        if !todayItems.isEmpty {
            var components = calendar.dateComponents([.year, .month, .day], from: today)
            components.hour = 7
            components.minute = 0

            let content = UNMutableNotificationContent()
            content.title = "📦 本日の入荷予定"
            let names = todayItems.prefix(3).map { $0.productName }.joined(separator: "、")
            let suffix = todayItems.count > 3 ? " 他\(todayItems.count - 3)件" : ""
            content.body = "\(todayItems.count)件の入荷があります：\(names)\(suffix)"
            content.sound = .default
            content.badge = NSNumber(value: todayItems.count)

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: "today_delivery", content: content, trigger: trigger)
            try? await center.add(request)
        }

        // 明日の入荷 → 当日の夕方18時に通知
        if !tomorrowItems.isEmpty {
            var components = calendar.dateComponents([.year, .month, .day], from: today)
            components.hour = 18
            components.minute = 0

            let content = UNMutableNotificationContent()
            content.title = "🚚 明日の入荷予定"
            let names = tomorrowItems.prefix(3).map { $0.productName }.joined(separator: "、")
            let suffix = tomorrowItems.count > 3 ? " 他\(tomorrowItems.count - 3)件" : ""
            content.body = "明日 \(tomorrowItems.count)件の入荷があります：\(names)\(suffix)"
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: "tomorrow_delivery", content: content, trigger: trigger)
            try? await center.add(request)
        }
    }
}
