import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0D1B2A").ignoresSafeArea()

                VStack(spacing: 0) {
                    filterPicker
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 8)

                    if viewModel.isLoading {
                        skeletonList
                    } else if let error = viewModel.errorMessage {
                        errorView(message: error)
                    } else if viewModel.filteredDeliveries.isEmpty {
                        emptyView
                    } else {
                        deliveryList
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "shippingbox.fill")
                            .foregroundStyle(Color(hex: "1E90FF"))
                            .font(.system(size: 18, weight: .bold))
                        Text("入荷予定")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.load() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(Color(hex: "1E90FF"))
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
        }
        .task { await viewModel.load() }
    }

    private var filterPicker: some View {
        HStack(spacing: 0) {
            ForEach(DateFilter.allCases, id: \.rawValue) { filter in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.selectedFilter = filter
                    }
                } label: {
                    Text(filter.title)
                        .font(.system(size: 15, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(viewModel.selectedFilter == filter ? .white : Color(hex: "7A9ABF"))
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(viewModel.selectedFilter == filter ? Color(hex: "1E90FF") : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(Color(hex: "152234"))
        .clipShape(.rect(cornerRadius: 14))
    }

    private var deliveryList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredDeliveries) { delivery in
                    DeliveryCardView(delivery: delivery)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .refreshable { await viewModel.load() }
    }

    private var skeletonList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(0..<5, id: \.self) { _ in
                    SkeletonCardView()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "tray.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color(hex: "2A4A6B"))
            Text("入荷予定なし")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color(hex: "7A9ABF"))
            Text("選択した期間に入荷予定がありません")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "4A6A8A"))
            Spacer()
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.orange)
            Text("接続エラー")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "7A9ABF"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                Task { await viewModel.load() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("再試行")
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(Color(hex: "1E90FF"))
                .clipShape(.rect(cornerRadius: 12))
            }
            Spacer()
        }
    }
}

struct DeliveryCardView: View {
    let delivery: Delivery
    @State private var isExpanded: Bool = false

    private var statusColor: Color {
        switch delivery.status {
        case .pending: return .orange
        case .shipped: return Color(hex: "00BCD4")
        case .delivered: return .green
        case .delayed: return .red
        case .cancelled: return Color(hex: "7A9ABF")
        case .unknown: return Color(hex: "7A9ABF")
        }
    }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(statusColor)
                        .frame(width: 4)
                        .clipShape(.rect(cornerRadius: 2))

                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(delivery.productName)
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundStyle(.white)
                                    .lineLimit(isExpanded ? nil : 1)
                                if let supplier = delivery.supplierName {
                                    Text(supplier)
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color(hex: "7A9ABF"))
                                }
                            }
                            Spacer()
                            StatusBadge(status: delivery.status, color: statusColor)
                        }

                        HStack(spacing: 16) {
                            InfoChip(icon: "shippingbox", value: "\(delivery.quantity)個")
                            InfoChip(icon: "calendar", value: delivery.deliveryDate.formatted(.dateTime.month().day().hour().minute()))
                        }

                        if isExpanded, let notes = delivery.notes, !notes.isEmpty {
                            Divider()
                                .background(Color(hex: "2A4A6B"))
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "note.text")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(hex: "7A9ABF"))
                                    .padding(.top, 1)
                                Text(notes)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color(hex: "A0C0E0"))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                }
            }
            .background(Color(hex: "152234"))
            .clipShape(.rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(hex: "1E3A5A"), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

struct StatusBadge: View {
    let status: DeliveryStatus
    let color: Color

    var body: some View {
        Text(status.displayName)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .clipShape(.rect(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color.opacity(0.4), lineWidth: 1)
            )
    }
}

struct InfoChip: View {
    let icon: String
    let value: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: "1E90FF"))
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(hex: "C8E0F8"))
        }
    }
}

struct SkeletonCardView: View {
    @State private var shimmer: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Color(hex: "2A4A6B"))
                .frame(width: 4)
                .clipShape(.rect(cornerRadius: 2))

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(shimmerGradient)
                        .frame(width: 160, height: 18)
                    Spacer()
                    RoundedRectangle(cornerRadius: 8)
                        .fill(shimmerGradient)
                        .frame(width: 56, height: 24)
                }
                RoundedRectangle(cornerRadius: 4)
                    .fill(shimmerGradient)
                    .frame(width: 100, height: 13)
                HStack(spacing: 16) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(shimmerGradient)
                        .frame(width: 60, height: 13)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(shimmerGradient)
                        .frame(width: 110, height: 13)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
        .background(Color(hex: "152234"))
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: "1E3A5A"), lineWidth: 1)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                shimmer = true
            }
        }
    }

    private var shimmerGradient: LinearGradient {
        LinearGradient(
            colors: shimmer
                ? [Color(hex: "1E3A5A"), Color(hex: "2A5A8A"), Color(hex: "1E3A5A")]
                : [Color(hex: "152234"), Color(hex: "1E3A5A"), Color(hex: "152234")],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
