import SwiftUI

struct ContentView: View {
    @State private var authViewModel = AuthViewModel()
    @State private var selectedTab: Int = 0

    private var isAdmin: Bool {
        authViewModel.user?.role == "ADMIN" || authViewModel.user?.role == "OWNER"
    }

    var body: some View {
        if authViewModel.isLoggedIn {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem { Label("入荷予定", systemImage: "shippingbox.fill") }
                    .tag(0)

                SearchView()
                    .tabItem { Label("AI 検索", systemImage: "sparkle.magnifyingglass") }
                    .tag(1)

                RequestView()
                    .tabItem { Label("発注依頼", systemImage: "doc.badge.plus") }
                    .tag(2)

                if isAdmin {
                    IngestView()
                        .tabItem { Label("入荷登録", systemImage: "doc.text.viewfinder") }
                        .tag(3)
                }

                SettingsView(authViewModel: authViewModel)
                    .tabItem { Label("設定", systemImage: "gearshape.fill") }
                    .tag(isAdmin ? 4 : 3)
            }
            .tint(Color(hex: "1E90FF"))
            .preferredColorScheme(.dark)
        } else {
            LoginView(authViewModel: authViewModel)
                .preferredColorScheme(.dark)
        }
    }
}
