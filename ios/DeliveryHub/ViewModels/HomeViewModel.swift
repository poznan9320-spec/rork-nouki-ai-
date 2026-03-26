import SwiftUI

enum DateFilter: Int, CaseIterable {
    case today = 0
    case tomorrow = 1
    case week = 2

    var title: String {
        switch self {
        case .today: return "今日"
        case .tomorrow: return "明日"
        case .week: return "1週間"
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
        return deliveries.filter { delivery in
            switch selectedFilter {
            case .today:
                return calendar.isDateInToday(delivery.deliveryDate)
            case .tomorrow:
                return calendar.isDateInTomorrow(delivery.deliveryDate)
            case .week:
                let weekEnd = calendar.date(byAdding: .day, value: 7, to: now) ?? now
                return delivery.deliveryDate >= now && delivery.deliveryDate <= weekEnd
            }
        }
    }

    @MainActor
    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            deliveries = try await NetworkService.shared.fetchDeliveries()
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "データの取得に失敗しました。"
        }
        isLoading = false
    }
}
