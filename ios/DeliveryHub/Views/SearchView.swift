import SwiftUI

struct SearchView: View {
    @State private var viewModel = SearchViewModel()
    @FocusState private var isInputFocused: Bool
    @State private var scrollID: UUID? = nil

    private let suggestions = ["今週納期の商品は？", "明日の入荷予定", "数量が多い商品は？", "遅延している商品は？"]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "sparkle.magnifyingglass")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "1E90FF"))
                Text("AIチャット")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                if !viewModel.messages.isEmpty {
                    Button {
                        withAnimation { viewModel.messages = [] }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 15))
                            .foregroundStyle(Color(hex: "4A6A8A"))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(hex: "0D1B2A"))

            Divider().background(Color(hex: "1E3A5A"))

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if viewModel.messages.isEmpty {
                            emptyState
                                .padding(.top, 40)
                        }

                        ForEach(viewModel.messages) { msg in
                            MessageBubble(message: msg)
                                .id(msg.id)
                        }

                        if viewModel.isLoading {
                            HStack(alignment: .bottom, spacing: 8) {
                                botAvatar
                                typingIndicator
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .id("loading")
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: "EF4444"))
                                .padding(.horizontal, 20)
                                .id("error")
                        }

                        Color.clear.frame(height: 1).id("bottom")
                    }
                    .padding(.vertical, 12)
                }
                .background(Color(hex: "0A1628"))
                .onChange(of: viewModel.messages.count) {
                    withAnimation { proxy.scrollTo("bottom") }
                }
                .onChange(of: viewModel.isLoading) {
                    withAnimation { proxy.scrollTo("bottom") }
                }
            }

            // Input bar
            HStack(spacing: 10) {
                TextField("メッセージを入力...", text: $viewModel.input)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                    .autocorrectionDisabled()
                    .focused($isInputFocused)
                    .onSubmit {
                        Task { await viewModel.send() }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(hex: "152234"))
                    .clipShape(.rect(cornerRadius: 22))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(isInputFocused ? Color(hex: "1E90FF").opacity(0.6) : Color(hex: "1E3A5A"), lineWidth: 1)
                    )

                Button {
                    isInputFocused = false
                    Task { await viewModel.send() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(
                            viewModel.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading
                                ? Color(hex: "2A4A6B")
                                : Color(hex: "1E90FF")
                        )
                }
                .disabled(viewModel.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(hex: "0D1B2A"))
        }
        .background(Color(hex: "0A1628"))
        .onTapGesture { isInputFocused = false }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: "1E90FF").opacity(0.1))
                    .frame(width: 56, height: 56)
                Image(systemName: "sparkles")
                    .font(.system(size: 24))
                    .foregroundStyle(Color(hex: "1E90FF").opacity(0.6))
            }
            Text("入荷データについて質問してください")
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "4A6A8A"))

            VStack(spacing: 8) {
                ForEach(suggestions, id: \.self) { s in
                    Button {
                        viewModel.input = s
                        Task { await viewModel.send() }
                    } label: {
                        Text(s)
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "7AAAD0"))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color(hex: "152234"))
                            .clipShape(.rect(cornerRadius: 20))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color(hex: "1E3A5A"), lineWidth: 1)
                            )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var botAvatar: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "1E3A5A"))
                .frame(width: 28, height: 28)
            Image(systemName: "sparkles")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "1E90FF"))
        }
    }

    private var typingIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color(hex: "4A6A8A"))
                    .frame(width: 6, height: 6)
                    .offset(y: viewModel.isLoading ? -3 : 0)
                    .animation(
                        .easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.15),
                        value: viewModel.isLoading
                    )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(hex: "152234"))
        .clipShape(.rect(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "1E3A5A"), lineWidth: 1))
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.role == .assistant {
                botIcon
            } else {
                Spacer(minLength: 48)
            }

            Text(message.content)
                .font(.system(size: 15))
                .foregroundStyle(message.role == .user ? .white : Color(hex: "C8E0F8"))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    message.role == .user
                        ? Color(hex: "1E5A9A")
                        : Color(hex: "152234")
                )
                .clipShape(
                    message.role == .user
                        ? .rect(cornerRadii: RectangleCornerRadii(topLeading: 18, bottomLeading: 18, bottomTrailing: 4, topTrailing: 18))
                        : .rect(cornerRadii: RectangleCornerRadii(topLeading: 4, bottomLeading: 18, bottomTrailing: 18, topTrailing: 18))
                )
                .overlay(
                    Group {
                        if message.role == .assistant {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(hex: "1E3A5A"), lineWidth: 1)
                        }
                    }
                )

            if message.role == .user {
                Spacer(minLength: 0)
            } else {
                Spacer(minLength: 48)
            }
        }
        .padding(.horizontal, 12)
    }

    private var botIcon: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "1E3A5A"))
                .frame(width: 28, height: 28)
            Image(systemName: "sparkles")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "1E90FF"))
        }
    }
}
