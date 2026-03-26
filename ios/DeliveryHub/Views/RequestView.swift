import SwiftUI

struct RequestView: View {
    @State private var viewModel = RequestViewModel()
    @State private var showToast: Bool = false
    @State private var showImageOptions: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0D1B2A").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        headerCard
                        formCard
                        photoCard
                        submitButton
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.badge.plus")
                            .foregroundStyle(Color(hex: "1E90FF"))
                            .font(.system(size: 18, weight: .bold))
                        Text("発注依頼")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .overlay(alignment: .bottom) {
            if showToast {
                ToastView(message: viewModel.successMessage ?? "送信しました")
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 32)
            }
        }
        .onChange(of: viewModel.successMessage) { _, newValue in
            if newValue != nil {
                withAnimation(.spring(response: 0.4)) { showToast = true }
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    withAnimation { showToast = false }
                    viewModel.successMessage = nil
                }
            }
        }
        .sheet(isPresented: $viewModel.showCamera) {
            CameraPickerView(image: $viewModel.selectedImage, sourceType: .camera)
        }
        .sheet(isPresented: $viewModel.showImagePicker) {
            CameraPickerView(image: $viewModel.selectedImage, sourceType: .photoLibrary)
        }
    }

    private var headerCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 22))
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 3) {
                Text("欠品・補充依頼")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                Text("現場から直接発注依頼を送信できます")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "7A9ABF"))
            }
            Spacer()
        }
        .padding(16)
        .background(Color.orange.opacity(0.1))
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.orange.opacity(0.35), lineWidth: 1)
        )
    }

    private var formCard: some View {
        VStack(spacing: 0) {
            FieldRow(
                icon: "tag.fill",
                label: "商品名",
                isRequired: true
            ) {
                TextField("例: 商品A-100", text: $viewModel.productName)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .autocorrectionDisabled()
            }

            Divider().background(Color(hex: "1E3A5A"))

            FieldRow(
                icon: "number.square.fill",
                label: "数量",
                isRequired: true
            ) {
                TextField("例: 50", text: $viewModel.quantityText)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .keyboardType(.numberPad)
            }

            Divider().background(Color(hex: "1E3A5A"))

            FieldRow(
                icon: "text.quote",
                label: "メモ",
                isRequired: false
            ) {
                TextField("緊急度・補足情報など（任意）", text: $viewModel.memo, axis: .vertical)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .lineLimit(3...6)
            }
        }
        .background(Color(hex: "152234"))
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "1E3A5A"), lineWidth: 1)
        )
    }

    private var photoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "camera.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "1E90FF"))
                Text("現場写真（任意）")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "7A9ABF"))
            }

            if let image = viewModel.selectedImage {
                ZStack(alignment: .topTrailing) {
                    Color(hex: "152234")
                        .frame(height: 200)
                        .overlay {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .allowsHitTesting(false)
                        }
                        .clipShape(.rect(cornerRadius: 12))

                    Button {
                        viewModel.selectedImage = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(.white)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .padding(10)
                }
            } else {
                HStack(spacing: 12) {
                    CameraButton(icon: "camera.fill", label: "カメラ") {
                        viewModel.showCamera = true
                    }
                    CameraButton(icon: "photo.on.rectangle", label: "ライブラリ") {
                        viewModel.showImagePicker = true
                    }
                }
            }
        }
        .padding(16)
        .background(Color(hex: "152234"))
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "1E3A5A"), lineWidth: 1)
        )
    }

    private var submitButton: some View {
        Button {
            Task { await viewModel.submit() }
        } label: {
            ZStack {
                if viewModel.isLoading {
                    HStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                        Text("送信中...")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                    }
                } else {
                    HStack(spacing: 10) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text("発注依頼を送信")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: viewModel.canSubmit
                        ? [Color(hex: "1E90FF"), Color(hex: "005FCC")]
                        : [Color(hex: "2A4A6B"), Color(hex: "1E3A5A")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(.rect(cornerRadius: 16))
            .shadow(
                color: viewModel.canSubmit ? Color(hex: "1E90FF").opacity(0.4) : .clear,
                radius: 12, x: 0, y: 6
            )
        }
        .disabled(!viewModel.canSubmit || viewModel.isLoading)
        .animation(.easeInOut(duration: 0.2), value: viewModel.canSubmit)

        .overlay(alignment: .top) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    .offset(y: -44)
            }
        }
    }
}

struct FieldRow<Content: View>: View {
    let icon: String
    let label: String
    let isRequired: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color(hex: "1E90FF"))
                .frame(width: 24)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text(label)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(hex: "7A9ABF"))
                    if isRequired {
                        Text("必須")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.orange)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15))
                            .clipShape(.rect(cornerRadius: 4))
                    }
                }
                content()
            }
            .padding(.vertical, 14)
        }
        .padding(.horizontal, 16)
    }
}

struct CameraButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(Color(hex: "1E90FF"))
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "7A9ABF"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color(hex: "0E1E30"))
            .clipShape(.rect(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "1E3A5A").opacity(0.8), lineWidth: 1)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
            )
        }
    }
}

struct ToastView: View {
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(.green)
            Text(message)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 14))
        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
    }
}

struct CameraPickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView
        init(_ parent: CameraPickerView) { self.parent = parent }

        nonisolated func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let image = info[.originalImage] as? UIImage
            Task { @MainActor in
                self.parent.image = image
                picker.dismiss(animated: true)
            }
        }

        nonisolated func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            Task { @MainActor in
                picker.dismiss(animated: true)
            }
        }
    }
}
