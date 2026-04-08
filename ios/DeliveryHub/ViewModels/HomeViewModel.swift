import SwiftUI

enum DateFilter: Int, CaseIterable {
    case today = 0
    case tomorrow = 1
    case week = 2
    case all = 3
    case past = 4

    var title: String {
        switch self {
        case .today: return "今日"
        case .tomorrow: return "明日"
        case .week: return "今週"
        case .all: return "全期間"
        case .past: return "過去"
        }
    }
}

@Observable
final class HomeViewModel {
    var deliveries: [Delivery] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var selectedFilter: DateFilter = .today

    var filteredDeliveries: [Delivery] {
        let calendar = Calendar.current
        let now = Date()
        let todayStart = calendar.startOfDay(for: now)
        return deliveries.filter { delivery in
            switch selectedFilter {
            case .today:
                return calendar.isDateInToday(delivery.deliveryDate)
            case .tomorrow:
                return calendar.isDateInTomorrow(delivery.deliveryDate)
            case .week:
                let weekEnd = calendar.date(byAdding: .day, value: 7, to: todayStart) ?? now
                return delivery.deliveryDate >= todayStart && delivery.deliveryDate <= weekEnd
            case .all:
                return delivery.deliveryDate >= todayStart
            case .past:
                let twoMonthsAgo = calendar.date(byAdding: .month, value: -2, to: todayStart) ?? todayStart
                return delivery.deliveryDate >= twoMonthsAgo && delivery.deliveryDate < todayStart
            }
        }
    }

    @MainActor
    func load() async {
        if DemoMode.shared.isActive {
            deliveries = DemoMode.demoDeliveries
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            deliveries = try await NetworkService.shared.fetchDeliveries()
            let notificationSettings = await currentNotificationSettings()
            await NotificationService.shared.scheduleDeliveryNotifications(
                deliveries: deliveries,
                settings: notificationSettings
            )
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "データの取得に失敗しました。"
        }
        isLoading = false
    }

    private func currentNotificationSettings() async -> NotificationSettings {
        if let remoteSettings = try? await NetworkService.shared.fetchNotificationSettings() {
            NotificationService.shared.cacheSettings(remoteSettings)
            return remoteSettings
        }
        return NotificationService.shared.cachedSettings()
    }
}
