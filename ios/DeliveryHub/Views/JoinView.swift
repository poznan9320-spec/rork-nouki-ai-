import SwiftUI

struct JoinView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var joinCode: String = ""
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showQRScanner: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var registrationDone: Bool = false
    @FocusState private var focused: Field?

    enum Field { case joinCode, name, email, password, confirmPassword }

    var body: some View {
        ZStack {
            Color(hex: "0D1B2A").ignoresSafeArea()

            if registrationDone {
                pendingView
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "1E90FF").opacity(0.15))
                                    .frame(width: 72, height: 72)
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 32))
                                    .foregroundStyle(Color(hex: "1E90FF"))
                            }
                            Text("会社に参加")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.white)
                            Text("会社コードを入力してアカウントを作成")
                                .font(.subheadline)
                                .foregroundStyle(Color(hex: "7A9ABF"))
                        }
                        .padding(.top, 48)
                        .padding(.bottom, 36)

                        VStack(spacing: 16) {
                            // Join code + QR button
                            VStack(alignment: .leading, spacing: 6) {
                                Text("会社コード *")
                                    .fieldLabel()
                                HStack(spacing: 10) {
                                    TextField("例: AB12345", text: $joinCode)
                                        .autocapitalization(.allCharacters)
                                        .autocorrectionDisabled()
                                        .focused($focused, equals: .joinCode)
                                        .submitLabel(.next)
                                        .onSubmit { focused = .name }
                                        .joinFieldStyle()
                                    Button {
                                        showQRScanner = true
                                    } label: {
                                        Image(systemName: "qrcode.viewfinder")
                                            .font(.system(size: 22))
                                            .foregroundStyle(Color(hex: "1E90FF"))
                                            .frame(width: 52, height: 52)
                                            .background(Color(hex: "152234"))
                                            .clipShape(.rect(cornerRadius: 10))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color(hex: "1E3A5A"), lineWidth: 1)
                                            )
                                    }
                                }
                            }

                            formField("名前 *", placeholder: "田中 太郎", text: $name, field: .name, next: .email)
                            formField("メールアドレス *", placeholder: "example@company.com", text: $email, field: .email, next: .password, keyboard: .emailAddress)
                            secureFormField("パスワード *", text: $password, field: .password, next: .confirmPassword)
                            secureFormField("パスワード（確認）*", text: $confirmPassword, field: .confirmPassword, next: nil)

                            if let error = errorMessage {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.circle.fill").font(.caption)
                                    Text(error).font(.caption)
                                }
                                .foregroundStyle(Color(hex: "EF4444"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 4)
                            }

                            Button {
                                focused = nil
                                Task { await register() }
                            } label: {
                                ZStack {
                                    if isLoading {
                                        ProgressView().tint(.white)
                                    } else {
                                        Text("アカウントを作成")
                                            .font(.headline)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(canSubmit && !isLoading ? Color(hex: "1E90FF") : Color(hex: "1E90FF").opacity(0.4))
                                .foregroundStyle(.white)
                                .clipShape(.rect(cornerRadius: 14))
                            }
                            .disabled(!canSubmit || isLoading)

                            Button("キャンセル") { dismiss() }
                                .font(.subheadline)
                                .foregroundStyle(Color(hex: "7A9ABF"))
                                .padding(.top, 4)
                        }
                        .padding(.horizontal, 28)
                        .padding(.bottom, 40)
                    }
                    .frame(maxWidth: AdaptiveLayout.formWidth)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
                }
            }
        }
        .fullScreenCover(isPresented: $showQRScanner) {
            ZStack(alignment: .topLeading) {
                QRScannerView { value in
                    // Extract join code from URL (?join=XXXX) or use value directly
                    if let url = URL(string: value),
                       let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                       let joinParam = components.queryItems?.first(where: { $0.name == "join" })?.value {
                        joinCode = joinParam
                    } else {
                        joinCode = value
                    }
                    showQRScanner = false
                } onCancel: {
                    showQRScanner = false
                }
                .ignoresSafeArea()

                Button {
                    showQRScanner = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.top, 60)
                        .padding(.leading, 20)
                }
            }
        }
    }

    // MARK: - Pending approval view

    private var pendingView: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 96, height: 96)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)
            }
            Text("登録が完了しました")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
            Text("管理者による承認後にログインできます。\nしばらくお待ちください。")
                .font(.subheadline)
                .foregroundStyle(Color(hex: "7A9ABF"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("閉じる") { dismiss() }
                .font(.headline)
                .frame(width: 160, height: 48)
                .background(Color(hex: "1E90FF"))
                .foregroundStyle(.white)
                .clipShape(.rect(cornerRadius: 12))
            Spacer()
        }
    }

    // MARK: - Validation

    private var canSubmit: Bool {
        !joinCode.trimmingCharacters(in: .whitespaces).isEmpty
        && !name.trimmingCharacters(in: .whitespaces).isEmpty
        && !email.trimmingCharacters(in: .whitespaces).isEmpty
        && password.count >= 6
        && password == confirmPassword
    }

    // MARK: - Registration

    @MainActor
    private func register() async {
        guard canSubmit else {
            if password != confirmPassword {
                errorMessage = "パスワードが一致しません"
            } else if password.count < 6 {
                errorMessage = "パスワードは6文字以上で入力してください"
            }
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await NetworkService.shared.registerEmployee(
                name: name.trimmingCharacters(in: .whitespaces),
                email: email.trimmingCharacters(in: .whitespaces).lowercased(),
                password: password,
                joinCode: joinCode.trimmingCharacters(in: .whitespaces).uppercased()
            )
            registrationDone = true
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "登録に失敗しました。再度お試しください。"
        }
        isLoading = false
    }

    // MARK: - Helper builders

    private func formField(
        _ label: String,
        placeholder: String,
        text: Binding<String>,
        field: Field,
        next: Field?,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).fieldLabel()
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .autocapitalization(keyboard == .emailAddress ? .none : .words)
                .autocorrectionDisabled()
                .focused($focused, equals: field)
                .submitLabel(next == nil ? .done : .next)
                .onSubmit { focused = next }
                .joinFieldStyle()
        }
    }

    private func secureFormField(_ label: String, text: Binding<String>, field: Field, next: Field?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).fieldLabel()
            SecureField("••••••", text: text)
                .focused($focused, equals: field)
                .submitLabel(next == nil ? .done : .next)
                .onSubmit { focused = next }
                .joinFieldStyle()
        }
    }
}

// MARK: - Style helpers

private extension Text {
    func fieldLabel() -> some View {
        self.font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(Color(hex: "7A9ABF"))
    }
}

private struct JoinFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(Color(hex: "152234"))
            .clipShape(.rect(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "1E3A5A"), lineWidth: 1))
            .foregroundStyle(.white)
    }
}

private extension View {
    func joinFieldStyle() -> some View { modifier(JoinFieldStyle()) }
}
