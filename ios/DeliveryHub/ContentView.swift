import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("入荷予定", systemImage: "shippingbox.fill")
                }
                .tag(0)

            SearchView()
                .tabItem {
                    Label("AI 検索", systemImage: "sparkle.magnifyingglass")
                }
                .tag(1)

            RequestView()
                .tabItem {
                    Label("発注依頼", systemImage: "doc.badge.plus")
                }
                .tag(2)
        }
        .tint(Color(hex: "1E90FF"))
        .preferredColorScheme(.dark)
    }
}
