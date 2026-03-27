import SwiftUI

struct SettingsView: View {
    @Bindable var authViewModel: AuthViewModel

    @State private var notifEnabled: Bool = true
    @State private var todayHour: Int = 7
    @State private var tomorrowHour: Int = 18
    @State private var loadingNotif: Bool = true
    @State private var savingNotif: Bool = false

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

                    // 通知設定
                    Section(header: Text("通知").foregroundColor(.white.opacity(0.4))) {
                        if loadingNotif {
                            HStack {
                                Spacer()
                                ProgressView().tint(Color(hex: "1E90FF"))
                                Spacer()
                            }
                        } else {
                            // 有効/無効トグル
                            Toggle(isOn: $notifEnabled) {
                                Label("通知を有効にする", systemImage: "bell.fill")
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .tint(Color(hex: "1E90FF"))

                            if notifEnabled {
                                // 本日納品の通知時刻
                                HStack {
                                    Label("本日納品", systemImage: "clock.fill")
                                        .foregroundColor(.white.opacity(0.7))
                                    Spacer()
                                    Picker("", selection: $todayHour) {
                                        ForEach(0..<24) { h in
                                            Text(String(format: "%02d:00", h)).tag(h)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(Color(hex: "1E90FF"))
                                }

                                // 明日納品の通知時刻
                                HStack {
                                    Label("明日納品", systemImage: "clock")
                                        .foregroundColor(.white.opacity(0.7))
                                    Spacer()
                                    Picker("", selection: $tomorrowHour) {
                                        ForEach(0..<24) { h in
                                            Text(String(format: "%02d:00", h)).tag(h)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(Color(hex: "1E90FF"))
                                }
                            }

                            // 保存ボタン
                            Button {
                                Task { await saveNotifSettings() }
                            } label: {
                                HStack {
                                    Spacer()
                                    if savingNotif {
                                        ProgressView().tint(.white).scaleEffect(0.8)
                                        Text("保存中...").foregroundColor(.white.opacity(0.6))
                                    } else {
                                        Text("保存")
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                    }
                                    Spacer()
                                }
                            }
                            .disabled(savingNotif)
                            .listRowBackground(Color(hex: "1E90FF").opacity(0.8))
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
            .task { await loadNotifSettings() }
        }
    }

    private var initials: String {
        if let name = authViewModel.user?.name, !name.isEmpty {
            return String(name.prefix(2)).uppercased()
        }
        return String(authViewModel.user?.email.prefix(1) ?? "?").uppercased()
    }

    @MainActor
    private func loadNotifSettings() async {
        loadingNotif = true
        do {
            let s = try await NetworkService.shared.fetchNotificationSettings()
            todayHour = s.todayHour
            tomorrowHour = s.tomorrowHour
            notifEnabled = s.enabled
            UserDefaults.standard.set(s.todayHour, forKey: "notifTodayHour")
            UserDefaults.standard.set(s.tomorrowHour, forKey: "notifTomorrowHour")
        } catch {
            // Use defaults silently
        }
        loadingNotif = false
    }

    @MainActor
    private func saveNotifSettings() async {
        savingNotif = true
        do {
            let s = try await NetworkService.shared.updateNotificationSettings(
                NotificationSettings(todayHour: todayHour, tomorrowHour: tomorrowHour, enabled: notifEnabled)
            )
            todayHour = s.todayHour
            tomorrowHour = s.tomorrowHour
            notifEnabled = s.enabled
            // ローカル通知にも反映
            UserDefaults.standard.set(s.todayHour, forKey: "notifTodayHour")
            UserDefaults.standard.set(s.tomorrowHour, forKey: "notifTomorrowHour")
        } catch {
            // Ignore silently; user can retry
        }
        savingNotif = false
    }
}
