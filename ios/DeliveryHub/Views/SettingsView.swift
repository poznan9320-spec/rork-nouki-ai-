import SwiftUI

struct SettingsView: View {
    @Bindable var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0D1B2A").ignoresSafeArea()

                List {
                    // アカウント情報
                    Section {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "1E90FF").opacity(0.2))
                                    .frame(width: 52, height: 52)
                                Text(initials)
                                    .font(.title3.bold())
                                    .foregroundColor(Color(hex: "1E90FF"))
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(authViewModel.user?.name ?? authViewModel.user?.email ?? "—")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(authViewModel.user?.email ?? "")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.55))
                                Text(["ADMIN", "OWNER"].contains(authViewModel.user?.role ?? "") ? "管理者" : "従業員")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color(hex: "1E90FF").opacity(0.2))
                                    .foregroundColor(Color(hex: "1E90FF"))
                                    .cornerRadius(4)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .listRowBackground(Color.white.opacity(0.06))

                    // 会社情報
                    Section(header: Text("会社").foregroundColor(.white.opacity(0.4))) {
                        HStack {
                            Label("会社名", systemImage: "building.2.fill")
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text(authViewModel.company?.name ?? "—")
                                .foregroundColor(.white)
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.06))

                    // アプリ情報
                    Section(header: Text("アプリ").foregroundColor(.white.opacity(0.4))) {
                        HStack {
                            Label("バージョン", systemImage: "info.circle.fill")
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.06))

                    // ログアウト
                    Section {
                        Button(role: .destructive) {
                            authViewModel.logout()
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("ログアウト")
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(Color(hex: "EF4444"))
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.06))
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var initials: String {
        if let name = authViewModel.user?.name, !name.isEmpty {
            return String(name.prefix(2)).uppercased()
        }
        return String(authViewModel.user?.email?.prefix(1) ?? "?").uppercased()
    }
}
