import SwiftUI

struct LoginView: View {
    @Bindable var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @FocusState private var focusedField: Field?
    @State private var showJoin: Bool = false

    private let webLoginURL = URL(string: "https://ai-nouki2.vercel.app/login")

    enum Field { case email, password }

    var body: some View {
        ZStack {
            Color(hex: "0D1B2A").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // ロゴ
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "1E90FF").opacity(0.15))
                                .frame(width: 88, height: 88)
                            Image(systemName: "shippingbox.fill")
                                .font(.system(size: 40))
                                .foregroundColor(Color(hex: "1E90FF"))
                        }
                        Text("AI納期管理")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Text("B2B配送・納期管理システム")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.5))
                        Text("Web版と同じアカウントでログインできます")
                            .font(.caption)
                            .foregroundColor(Color(hex: "7A9ABF"))
                    }
                    .padding(.top, 80)
                    .padding(.bottom, 48)

                    // フォーム
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("メールアドレス")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.7))
                            TextField("example@company.com", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .email)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .password }
                                .padding(14)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(focusedField == .email ? Color(hex: "1E90FF") : Color.clear, lineWidth: 1.5)
                                )
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("パスワード")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.7))
                            SecureField("パスワード", text: $password)
                                .focused($focusedField, equals: .password)
                                .submitLabel(.done)
                                .onSubmit {
                                    Task { await authViewModel.login(email: email, password: password) }
                                }
                                .padding(14)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(focusedField == .password ? Color(hex: "1E90FF") : Color.clear, lineWidth: 1.5)
                                )
                        }

                        if let error = authViewModel.errorMessage {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.caption)
                                Text(error)
                                    .font(.caption)
                            }
                            .foregroundColor(Color(hex: "EF4444"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                        }

                        Button {
                            focusedField = nil
                            Task { await authViewModel.login(email: email, password: password) }
                        } label: {
                            ZStack {
                                if authViewModel.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("ログイン")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                (email.isEmpty || password.isEmpty || authViewModel.isLoading)
                                    ? Color(hex: "1E90FF").opacity(0.4)
                                    : Color(hex: "1E90FF")
                            )
                            .cornerRadius(14)
                            .foregroundColor(.white)
                        }
                        .disabled(email.isEmpty || password.isEmpty || authViewModel.isLoading)
                    }
                    .padding(.horizontal, 28)

                    Spacer().frame(height: 32)

                    if let webLoginURL {
                        Link(destination: webLoginURL) {
                            HStack(spacing: 6) {
                                Image(systemName: "safari")
                                    .font(.system(size: 14))
                                Text("Web版ログインを開く")
                                    .font(.subheadline)
                            }
                            .foregroundColor(.white.opacity(0.75))
                        }

                        Spacer().frame(height: 12)
                    }

                    Button {
                        showJoin = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "qrcode")
                                .font(.system(size: 14))
                            Text("会社に参加（新規登録）")
                                .font(.subheadline)
                        }
                        .foregroundColor(Color(hex: "1E90FF"))
                    }

                    Spacer().frame(height: 40)
                }
                .frame(maxWidth: AdaptiveLayout.formWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
            }
        }
        .fullScreenCover(isPresented: $showJoin) {
            JoinView()
                .preferredColorScheme(.dark)
        }
    }
}
