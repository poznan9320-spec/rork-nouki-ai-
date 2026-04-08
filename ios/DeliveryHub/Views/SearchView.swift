import SwiftUI

struct SearchView: View {
    @State private var viewModel = SearchViewModel()
    @FocusState private var isInputFocused: Bool
    @State private var scrollID: UUID? = nil

    private let suggestions = ["今日・明日の入荷は？", "今週納期の商品は？", "数量が多い商品は？", "来月の入荷予定は？"]

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
            .frame(maxWidth: AdaptiveLayout.contentWidth)
            .frame(maxWidth: .infinity)
            .background(Color(hex: "0D1B2A"))

            Divider().background(Color(hex: "1E3A5A"))

            // Messages
            GeometryReader { geo in
                HStack(spacing: 0) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                if viewModel.messages.isEmpty {
                                    emptyState
                                } else {
                                    // 上部の余白：メッセージを下に寄せる
                                    Color.clear.frame(height: 1).id("top")
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
                                    .padding(.horizontal, 14)
                                    .id("loading")
                                }

                                if let error = viewModel.errorMessage {
                                    HStack(spacing: 6) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .font(.system(size: 13))
                                        Text(error)
                                            .font(.system(size: 13))
                                    }
                                    .foregroundStyle(Color(hex: "EF4444"))
                                    .padding(.horizontal, 20)
                                    .id("error")
                                }

                                Color.clear.frame(height: 1).id("bottom")
                            }
                            .padding(.vertical, 14)
                            .frame(minHeight: geo.size.height, alignment: .bottom)
                        }
                        .background(Color(hex: "0A1628"))
                        .defaultScrollAnchor(.bottom)
                        .onChange(of: viewModel.messages.count) {
                            withAnimation { proxy.scrollTo("bottom") }
                        }
                        .onChange(of: viewModel.isLoading) {
                            withAnimation { proxy.scrollTo("bottom") }
                        }
                    }
                    .frame(maxWidth: AdaptiveLayout.contentWidth)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Input bar
            HStack(spacing: 10) {
                TextField("メッセージを入力...", text: $viewModel.input, axis: .vertical)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                    .lineLimit(1...4)
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
            .frame(maxWidth: AdaptiveLayout.contentWidth)
            .frame(maxWidth: .infinity)
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
        if message.role == .user {
            userBubble
        } else {
            assistantCard
        }
    }

    // ユーザー: 右揃えシンプルバブル
    private var userBubble: some View {
        HStack(alignment: .bottom, spacing: 0) {
            Spacer(minLength: 60)
            Text(message.content)
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(hex: "1A5CA8"))
                .clipShape(.rect(cornerRadii: RectangleCornerRadii(topLeading: 18, bottomLeading: 18, bottomTrailing: 4, topTrailing: 18)))
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, 14)
    }

    // アシスタント: 全幅カード・markdown対応
    private var assistantCard: some View {
        HStack(alignment: .top, spacing: 10) {
            // アバター
            ZStack {
                Circle()
                    .fill(Color(hex: "1E3A5A"))
                    .frame(width: 30, height: 30)
                Image(systemName: "sparkles")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "1E90FF"))
            }
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 0) {
                // コンテンツを行ごとに分割してレンダリング
                ForEach(parsedLines, id: \.id) { line in
                    lineView(line)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(hex: "111E30"))
            .clipShape(.rect(cornerRadii: RectangleCornerRadii(topLeading: 4, bottomLeading: 16, bottomTrailing: 16, topTrailing: 16)))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(hex: "1E3A5A"), lineWidth: 1)
            )
        }
        .padding(.horizontal, 14)
    }

    // 行ごとのビュー
    @ViewBuilder
    private func lineView(_ line: ParsedLine) -> some View {
        switch line.type {
        case .bullet:
            HStack(alignment: .top, spacing: 8) {
                Circle()
                    .fill(Color(hex: "1E90FF"))
                    .frame(width: 5, height: 5)
                    .padding(.top, 7)
                Text(.init(line.text))
                    .font(.system(size: 14.5))
                    .foregroundStyle(Color(hex: "D0E8FF"))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, 5)
        case .heading:
            Text(.init(line.text))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(hex: "7AAAD0"))
                .padding(.top, line.id == parsedLines.first?.id ? 0 : 8)
                .padding(.bottom, 4)
        case .divider:
            Divider()
                .background(Color(hex: "1E3A5A"))
                .padding(.vertical, 6)
        case .empty:
            Color.clear.frame(height: 4)
        case .normal:
            Text(.init(line.text))
                .font(.system(size: 14.5))
                .foregroundStyle(Color(hex: "C8E0F8"))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 3)
        }
    }

    // テキストを行に分解してタイプを判定
    private var parsedLines: [ParsedLine] {
        let raw = message.content
        let rawLines = raw.components(separatedBy: "\n")
        var result: [ParsedLine] = []
        for (i, line) in rawLines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                if i > 0 && i < rawLines.count - 1 {
                    result.append(ParsedLine(type: .empty, text: ""))
                }
            } else if trimmed == "---" || trimmed == "—--" {
                result.append(ParsedLine(type: .divider, text: ""))
            } else if trimmed.hasPrefix("### ") {
                result.append(ParsedLine(type: .heading, text: String(trimmed.dropFirst(4))))
            } else if trimmed.hasPrefix("## ") {
                result.append(ParsedLine(type: .heading, text: String(trimmed.dropFirst(3))))
            } else if trimmed.hasPrefix("# ") {
                result.append(ParsedLine(type: .heading, text: String(trimmed.dropFirst(2))))
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("• ") || trimmed.hasPrefix("・") {
                let text = trimmed.hasPrefix("・")
                    ? String(trimmed.dropFirst(1)).trimmingCharacters(in: .whitespaces)
                    : String(trimmed.dropFirst(2))
                result.append(ParsedLine(type: .bullet, text: text))
            } else if trimmed.first?.isNumber == true && trimmed.contains(". ") {
                // 番号付きリスト "1. xxx"
                if let dotRange = trimmed.range(of: ". ") {
                    result.append(ParsedLine(type: .bullet, text: String(trimmed[dotRange.upperBound...])))
                } else {
                    result.append(ParsedLine(type: .normal, text: trimmed))
                }
            } else {
                result.append(ParsedLine(type: .normal, text: trimmed))
            }
        }
        // 末尾の空行を除去
        while result.last?.type == .empty { result.removeLast() }
        return result
    }
}

private struct ParsedLine: Identifiable {
    enum LineType { case normal, bullet, heading, divider, empty }
    let id = UUID()
    let type: LineType
    let text: String
}
