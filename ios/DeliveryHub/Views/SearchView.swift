import SwiftUI

struct SearchView: View {
    @State private var viewModel = SearchViewModel()
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0D1B2A").ignoresSafeArea()

                VStack(spacing: 0) {
                    searchInputBar
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                    if viewModel.isLoading {
                        loadingCard
                            .padding(.horizontal, 16)
                            .padding(.top, 20)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    } else if let reply = viewModel.currentReply {
                        answerCard(reply: reply)
                            .padding(.horizontal, 16)
                            .padding(.top, 20)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            ))
                    } else if let error = viewModel.errorMessage {
                        errorCard(message: error)
                            .padding(.horizontal, 16)
                            .padding(.top, 20)
                            .transition(.opacity)
                    } else {
                        hintCard
                            .padding(.horizontal, 16)
                            .padding(.top, 20)
                    }

                    if !viewModel.history.isEmpty {
                        historySection
                            .padding(.top, 20)
                    }

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkle.magnifyingglass")
                            .foregroundStyle(Color(hex: "1E90FF"))
                            .font(.system(size: 18, weight: .bold))
                        Text("AI 検索")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.currentReply != nil || viewModel.errorMessage != nil {
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                viewModel.clear()
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color(hex: "4A6A8A"))
                                .font(.system(size: 18))
                        }
                    }
                }
            }
            .onTapGesture { isInputFocused = false }
        }
    }

    private var searchInputBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color(hex: "4A7AAA"))
                    .font(.system(size: 18, weight: .medium))

                TextField("例: 明日入荷の商品はある？", text: $viewModel.query)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .autocorrectionDisabled()
                    .focused($isInputFocused)
                    .onSubmit {
                        Task { await viewModel.search() }
                    }

                if !viewModel.query.isEmpty {
                    Button {
                        viewModel.query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color(hex: "4A6A8A"))
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color(hex: "152234"))
            .clipShape(.rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isInputFocused ? Color(hex: "1E90FF") : Color(hex: "1E3A5A"), lineWidth: isInputFocused ? 2 : 1)
            )
            .animation(.easeInOut(duration: 0.2), value: isInputFocused)

            Button {
                isInputFocused = false
                Task { await viewModel.search() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? Color(hex: "2A4A6B")
                            : Color(hex: "1E90FF")
                    )
            }
            .disabled(viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
            .animation(.easeInOut(duration: 0.2), value: viewModel.query.isEmpty)
        }
    }

    private func answerCard(reply: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(hex: "1E90FF"))
                Text("AI 回答")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(hex: "1E90FF"))
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.green)
            }

            Text(reply)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(6)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color(hex: "0E2A4A"), Color(hex: "0A1E36")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(hex: "1E5A9A"), lineWidth: 1.5)
        )
        .shadow(color: Color(hex: "1E90FF").opacity(0.2), radius: 20, x: 0, y: 8)
    }

    private var loadingCard: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(Color(hex: "1E90FF"))
                .scaleEffect(1.4)
            Text("AIが回答中...")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(hex: "7A9ABF"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .background(Color(hex: "152234"))
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(hex: "1E3A5A"), lineWidth: 1)
        )
    }

    private func errorCard(message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 28))
                .foregroundStyle(.orange)
            Text(message)
                .font(.system(size: 15))
                .foregroundStyle(Color(hex: "C0D8F0"))
                .multilineTextAlignment(.center)
            Button {
                Task { await viewModel.search() }
            } label: {
                Text("再試行")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color(hex: "1E90FF"))
                    .clipShape(.rect(cornerRadius: 10))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
        .background(Color(hex: "152234"))
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.orange.opacity(0.4), lineWidth: 1)
        )
    }

    private var hintCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.bubble.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color(hex: "2A5A8A"))

            Text("在庫・入荷を即座に確認")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color(hex: "5A8ABF"))

            VStack(alignment: .leading, spacing: 10) {
                ForEach(["「明日入荷の商品はある？」", "「商品Aの在庫数は？」", "「今週の入荷予定を教えて」"], id: \.self) { hint in
                    Button {
                        viewModel.query = hint.replacingOccurrences(of: "「", with: "").replacingOccurrences(of: "」", with: "")
                        Task { await viewModel.search() }
                    } label: {
                        HStack {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color(hex: "1E90FF"))
                            Text(hint)
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "7AAAD0"))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(Color(hex: "0E1E30"))
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(hex: "1E3A5A"), lineWidth: 1)
        )
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("検索履歴")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "4A6A8A"))
                Spacer()
                Button {
                    withAnimation { viewModel.history.removeAll() }
                } label: {
                    Text("クリア")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "4A6A8A"))
                }
            }
            .padding(.horizontal, 16)

            ScrollView {
                VStack(spacing: 6) {
                    ForEach(viewModel.history) { item in
                        Button {
                            viewModel.query = item.query
                            withAnimation(.spring(response: 0.4)) {
                                viewModel.currentReply = item.reply
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(hex: "4A6A8A"))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.query)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(Color(hex: "8ABADF"))
                                        .lineLimit(1)
                                    Text(item.reply)
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color(hex: "4A6A8A"))
                                        .lineLimit(1)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color(hex: "2A4A6B"))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color(hex: "0E1E30"))
                            .clipShape(.rect(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(maxHeight: 220)
        }
    }
}
