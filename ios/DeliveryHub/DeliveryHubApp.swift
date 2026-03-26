import SwiftUI

@main
struct DeliveryHubApp: App {
    init() {
        Task {
            await NotificationService.shared.requestPermission()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
