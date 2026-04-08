import SwiftUI
import UIKit
import UserNotifications

struct SettingsView: View {
    @Bindable var authViewModel: AuthViewModel
    @Environment(\.openURL) private var openURL

    @State private var notifEnabled: Bool = true
    @State private var todayHour: Int = 7
    @State private var tomorrowHour: Int = 18
    @State private var loadingNotif: Bool = true
    @State private var savingNotif: Bool = false
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var feedback: SettingsFeedback?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0D1B2A").ignoresSafeArea()

                HStack(spacing: 0) {
                    List {
                        if let feedback {
                            Section {
                                feedbackRow(feedback)
                            }
                            .listRowBackground(feedback.kind.backgroundColor)
                        }

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

                        Section(header: Text("通知").foregroundColor(.white.opacity(0.4))) {
                            if loadingNotif {
                                HStack {
                                    Spacer()
                                    ProgressView().tint(Color(hex: "1E90FF"))
                                    Spacer()
                                }
                            } else {
                                Toggle(isOn: $notifEnabled) {
                                    Label("通知を有効にする", systemImage: "bell.fill")
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .tint(Color(hex: "1E90FF"))

                                if notifEnabled {
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

                                if notificationStatus == .denied {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Label("通知がシステム設定でオフになっています", systemImage: "bell.slash.fill")
                                            .font(.footnote)
                                            .foregroundColor(Color(hex: "F59E0B"))
                                        Button("設定アプリを開く", action: openSystemSettings)
                                            .font(.footnote.weight(.semibold))
                                            .foregroundColor(Color(hex: "1E90FF"))
                                    }
                                    .padding(.vertical, 4)
                                }

                                Button(action: saveNotifButtonTapped) {
                                    HStack {
                                        Spacer()
                                        if savingNotif {
                                            ProgressView().tint(.white).scaleEffect(0.8)
                                            Text("保存中...")
                                                .foregroundColor(.white.opacity(0.6))
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
                    .frame(maxWidth: AdaptiveLayout.settingsWidth)
                }
                .frame(maxWidth: .infinity)
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

    private func feedbackRow(_ feedback: SettingsFeedback) -> some View {
        HStack(spacing: 8) {
            Image(systemName: feedback.kind.icon)
            Text(feedback.message)
                .font(.footnote)
        }
        .foregroundStyle(feedback.kind.foregroundColor)
        .padding(.vertical, 4)
    }

    private func saveNotifButtonTapped() {
        Task { await saveNotifSettings() }
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }

    @MainActor
    private func loadNotifSettings() async {
        loadingNotif = true
        feedback = nil
        do {
            let settings = try await NetworkService.shared.fetchNotificationSettings()
            NotificationService.shared.cacheSettings(settings)
            applyNotificationSettings(settings)
        } catch {
            let cached = NotificationService.shared.cachedSettings()
            applyNotificationSettings(cached)
            feedback = SettingsFeedback(
                message: "通知設定を読み込めなかったため、前回の設定を表示しています。",
                kind: .info
            )
        }
        notificationStatus = await NotificationService.shared.authorizationStatus()
        loadingNotif = false
    }

    @MainActor
    private func saveNotifSettings() async {
        savingNotif = true
        feedback = nil

        if notifEnabled {
            let granted = await NotificationService.shared.requestPermissionIfNeeded()
            notificationStatus = await NotificationService.shared.authorizationStatus()
            guard granted else {
                notifEnabled = false
                feedback = SettingsFeedback(
                    message: "通知を有効にするには、iPhone/iPad の設定で通知を許可してください。",
                    kind: .error
                )
                savingNotif = false
                return
            }
        }

        do {
            let settings = try await NetworkService.shared.updateNotificationSettings(
                NotificationSettings(todayHour: todayHour, tomorrowHour: tomorrowHour, enabled: notifEnabled)
            )
            NotificationService.shared.cacheSettings(settings)
            applyNotificationSettings(settings)
            notificationStatus = await NotificationService.shared.authorizationStatus()

            if settings.enabled {
                do {
                    let deliveries = try await NetworkService.shared.fetchDeliveries()
                    await NotificationService.shared.scheduleDeliveryNotifications(
                        deliveries: deliveries,
                        settings: settings
                    )
                    feedback = SettingsFeedback(
                        message: "通知設定を保存しました。次回通知もこの時刻で配信されます。",
                        kind: .success
                    )
                } catch {
                    feedback = SettingsFeedback(
                        message: "通知設定を保存しました。入荷一覧の次回更新時に通知へ反映されます。",
                        kind: .info
                    )
                }
            } else {
                await NotificationService.shared.scheduleDeliveryNotifications(
                    deliveries: [],
                    settings: settings
                )
                feedback = SettingsFeedback(message: "通知をオフにしました。", kind: .success)
            }
        } catch {
            feedback = SettingsFeedback(
                message: "通知設定の保存に失敗しました。再度お試しください。",
                kind: .error
            )
        }

        savingNotif = false
    }

    private func applyNotificationSettings(_ settings: NotificationSettings) {
        todayHour = settings.todayHour
        tomorrowHour = settings.tomorrowHour
        notifEnabled = settings.enabled
    }
}

private struct SettingsFeedback {
    let message: String
    let kind: SettingsFeedbackKind
}

private enum SettingsFeedbackKind {
    case success
    case error
    case info

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }

    var foregroundColor: Color {
        switch self {
        case .success: return .green
        case .error: return Color(hex: "FCA5A5")
        case .info: return Color(hex: "BFDBFE")
        }
    }

    var backgroundColor: Color {
        switch self {
        case .success: return Color.green.opacity(0.12)
        case .error: return Color(hex: "7F1D1D").opacity(0.5)
        case .info: return Color(hex: "172554").opacity(0.6)
        }
    }
}
