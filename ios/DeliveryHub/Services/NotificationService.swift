import UserNotifications
import Foundation

final class NotificationService: @unchecked Sendable {
    static let shared = NotificationService()
    private let settingsKey = "delivery_notification_settings"

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let currentStatus = await center.notificationSettings().authorizationStatus
        if currentStatus == .authorized || currentStatus == .provisional || currentStatus == .ephemeral {
            return true
        }

        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        let center = UNUserNotificationCenter.current()
        return await center.notificationSettings().authorizationStatus
    }

    func requestPermissionIfNeeded() async -> Bool {
        switch await authorizationStatus() {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return await requestPermission()
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    func cachedSettings() -> NotificationSettings {
        guard let data = UserDefaults.standard.data(forKey: settingsKey),
              let settings = try? JSONDecoder().decode(NotificationSettings.self, from: data) else {
            return NotificationSettings(todayHour: 7, tomorrowHour: 18, enabled: true)
        }
        return settings
    }

    func cacheSettings(_ settings: NotificationSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: settingsKey)
    }

    func scheduleDeliveryNotifications(deliveries: [Delivery], settings: NotificationSettings) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [
            "today_delivery", "tomorrow_delivery"
        ])

        let authorization = await center.notificationSettings().authorizationStatus
        guard authorization == .authorized || authorization == .provisional || authorization == .ephemeral else {
            return
        }

        guard settings.enabled else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) else { return }

        let todayItems = deliveries.filter { calendar.isDate($0.deliveryDate, inSameDayAs: today) }
        let tomorrowItems = deliveries.filter { calendar.isDate($0.deliveryDate, inSameDayAs: tomorrow) }

        if !todayItems.isEmpty {
            var components = calendar.dateComponents([.year, .month, .day], from: today)
            components.hour = settings.todayHour
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

        if !tomorrowItems.isEmpty {
            var components = calendar.dateComponents([.year, .month, .day], from: today)
            components.hour = settings.tomorrowHour
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
