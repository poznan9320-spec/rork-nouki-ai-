import SwiftUI
import PhotosUI

struct IngestView: View {
    @State private var viewModel = IngestViewModel()
    @State private var photosPickerItem: PhotosPickerItem? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0D1B2A").ignoresSafeArea()

                VStack(spacing: 0) {
                    // Mode Picker
                    modePicker
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 4)

                    ScrollView {
                        VStack(spacing: 16) {
                            // Status messages
                            if let error = viewModel.errorMessage {
                                messageRow(text: error, color: Color(hex: "EF4444"), icon: "exclamationmark.circle.fill")
                            }
                            if let success = viewModel.successMessage {
                                messageRow(text: success, color: .green, icon: "checkmark.circle.fill")
                            }

                            if viewModel.mode == .ocr {
                                ocrSection
                            } else {
                                manualSection
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text.viewfinder")
                            .foregroundStyle(Color(hex: "1E90FF"))
                            .font(.system(size: 16, weight: .bold))
                        Text("入荷登録")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .photosPicker(isPresented: $viewModel.showImagePicker,
                          selection: $photosPickerItem,
                          matching: .images)
            .onChange(of: photosPickerItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        viewModel.selectedImage = image
                    }
                }
            }
            .fullScreenCover(isPresented: $viewModel.showCamera) {
                CameraView { image in
                    viewModel.selectedImage = image
                    viewModel.showCamera = false
                }
                .ignoresSafeArea()
            }
        }
    }

    // MARK: - Mode Picker

    private var modePicker: some View {
        HStack(spacing: 0) {
            modeTab(title: "AI OCR", icon: "doc.text.viewfinder", mode: .ocr)
            modeTab(title: "手動入力", icon: "square.and.pencil", mode: .manual)
        }
        .padding(4)
        .background(Color(hex: "152234"))
        .clipShape(.rect(cornerRadius: 14))
    }

    private func modeTab(title: String, icon: String, mode: IngestMode) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.mode = mode
                viewModel.errorMessage = nil
                viewModel.successMessage = nil
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 13, weight: .semibold))
                Text(title).font(.system(size: 14, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .foregroundStyle(viewModel.mode == mode ? .white : Color(hex: "7A9ABF"))
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(viewModel.mode == mode ? Color(hex: "1E90FF") : Color.clear)
            )
        }
    }

    // MARK: - OCR Section

    private var ocrSection: some View {
        VStack(spacing: 16) {
            // Image picker
            card {
                VStack(spacing: 12) {
                    if let image = viewModel.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 160)
                            .clipped()
                            .clipShape(.rect(cornerRadius: 10))
                    }

                    HStack(spacing: 10) {
                        photoButton(icon: "camera.fill", title: "カメラ撮影") {
                            viewModel.showCamera = true
                        }
                        photoButton(icon: "photo.on.rectangle", title: "フォトから選択") {
                            viewModel.showImagePicker = true
                        }
                    }

                    if viewModel.selectedImage != nil {
                        Button(role: .destructive) {
                            viewModel.selectedImage = nil
                        } label: {
                            Label("写真を削除", systemImage: "trash")
                                .font(.caption)
                                .foregroundStyle(Color(hex: "EF4444"))
                        }
                    }
                }
            }

            // Free text input
            card {
                VStack(alignment: .leading, spacing: 8) {
                    Text("または テキスト入力")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color(hex: "7A9ABF"))
                    TextEditor(text: $viewModel.freeText)
                        .scrollContentBackground(.hidden)
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                        .frame(minHeight: 80)
                        .background(Color.clear)
                        .overlay(
                            Group {
                                if viewModel.freeText.isEmpty {
                                    Text("発注書の内容を貼り付けてください…")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color(hex: "4A6A8A"))
                                        .allowsHitTesting(false)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                }
                            }
                        )
                }
            }

            // Supplier
            card {
                ingestField("仕入先（任意）", placeholder: "例：〇〇商事", text: $viewModel.supplierName)
            }

            // OCR button
            Button {
                Task { await viewModel.runOCR() }
            } label: {
                ZStack {
                    if viewModel.isProcessingOCR {
                        HStack(spacing: 10) {
                            ProgressView().tint(.white)
                            Text("AI解析中...").font(.headline)
                        }
                    } else {
                        Label("AIで解析する", systemImage: "sparkles")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color(hex: "1E90FF"))
                .foregroundStyle(.white)
                .clipShape(.rect(cornerRadius: 14))
            }
            .disabled(viewModel.isProcessingOCR || viewModel.isSubmitting)

            // Extracted items
            if !viewModel.ocrItems.isEmpty {
                ocrResultSection
            }
        }
    }

    private var ocrResultSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("抽出結果 (\(viewModel.ocrItems.count)件)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Text("タップで編集")
                    .font(.caption)
                    .foregroundStyle(Color(hex: "7A9ABF"))
            }

            ForEach($viewModel.ocrItems) { $item in
                OCRItemCard(item: $item, onDelete: {
                    viewModel.ocrItems.removeAll { $0.id == item.id }
                })
            }

            Button {
                Task { await viewModel.saveOCR() }
            } label: {
                ZStack {
                    if viewModel.isSubmitting {
                        ProgressView().tint(.white)
                    } else {
                        Label("\(viewModel.ocrItems.count)件を保存", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(.green)
                .foregroundStyle(.white)
                .clipShape(.rect(cornerRadius: 14))
            }
            .disabled(viewModel.isSubmitting || viewModel.ocrItems.isEmpty)
        }
    }

    // MARK: - Manual Section

    private var manualSection: some View {
        VStack(spacing: 14) {
            card {
                VStack(spacing: 14) {
                    ingestField("商品名 *", placeholder: "商品名を入力", text: $viewModel.manualProductName)

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            fieldLabel("数量 *")
                            TextField("1", text: $viewModel.manualQuantityText)
                                .keyboardType(.numberPad)
                                .ingestFieldStyle()
                        }
                        .frame(maxWidth: 100)

                        VStack(alignment: .leading, spacing: 6) {
                            fieldLabel("入荷予定日 *")
                            DatePicker("", selection: $viewModel.manualDeliveryDate, displayedComponents: .date)
                                .labelsHidden()
                                .tint(Color(hex: "1E90FF"))
                                .colorScheme(.dark)
                        }
                    }

                    ingestField("仕入先（任意）", placeholder: "例：〇〇商事", text: $viewModel.manualSupplierName)

                    VStack(alignment: .leading, spacing: 6) {
                        fieldLabel("備考（任意）")
                        TextEditor(text: $viewModel.manualNotes)
                            .scrollContentBackground(.hidden)
                            .font(.system(size: 15))
                            .foregroundStyle(.white)
                            .frame(minHeight: 70)
                            .background(Color.clear)
                            .padding(10)
                            .background(Color(hex: "0D1B2A"))
                            .clipShape(.rect(cornerRadius: 8))
                    }
                }
            }

            Button {
                Task { await viewModel.submitManual() }
            } label: {
                ZStack {
                    if viewModel.isSubmitting {
                        ProgressView().tint(.white)
                    } else {
                        Label("入荷データを登録", systemImage: "plus.circle.fill")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(viewModel.manualCanSubmit && !viewModel.isSubmitting
                            ? Color(hex: "1E90FF")
                            : Color(hex: "1E90FF").opacity(0.4))
                .foregroundStyle(.white)
                .clipShape(.rect(cornerRadius: 14))
            }
            .disabled(!viewModel.manualCanSubmit || viewModel.isSubmitting)
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack { content() }
            .padding(14)
            .background(Color(hex: "152234"))
            .clipShape(.rect(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "1E3A5A"), lineWidth: 1))
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(Color(hex: "7A9ABF"))
    }

    private func ingestField(_ label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel(label)
            TextField(placeholder, text: text)
                .ingestFieldStyle()
        }
    }

    private func photoButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 13, weight: .semibold))
                Text(title).font(.system(size: 13, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(Color(hex: "0D1B2A"))
            .foregroundStyle(Color(hex: "1E90FF"))
            .clipShape(.rect(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "1E3A5A"), lineWidth: 1))
        }
    }

    private func messageRow(text: String, color: Color, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.caption)
            Text(text).font(.caption)
        }
        .foregroundStyle(color)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }
}

// MARK: - OCR Item Card

struct OCRItemCard: View {
    @Binding var item: OCRItem
    let onDelete: () -> Void
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.productName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                        Text("\(item.quantity)個 · \(item.deliveryDate)")
                            .font(.caption)
                            .foregroundStyle(Color(hex: "7A9ABF"))
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(Color(hex: "7A9ABF"))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider().background(Color(hex: "1E3A5A"))
                VStack(spacing: 10) {
                    editRow("商品名", text: $item.productName)
                    editRow("数量", text: Binding(
                        get: { String(item.quantity) },
                        set: { item.quantity = Int($0) ?? item.quantity }
                    ), keyboard: .numberPad)
                    editRow("入荷日 (YYYY-MM-DD)", text: $item.deliveryDate, keyboard: .numbersAndPunctuation)
                    if let notes = item.notes {
                        editRow("備考", text: Binding(
                            get: { notes },
                            set: { item.notes = $0.isEmpty ? nil : $0 }
                        ))
                    }
                    Button(role: .destructive, action: onDelete) {
                        Label("この行を削除", systemImage: "trash")
                            .font(.caption)
                            .foregroundStyle(Color(hex: "EF4444"))
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(12)
            }
        }
        .background(Color(hex: "152234"))
        .clipShape(.rect(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "1E3A5A"), lineWidth: 1))
    }

    private func editRow(_ label: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color(hex: "7A9ABF"))
            TextField(label, text: text)
                .keyboardType(keyboard)
                .font(.system(size: 14))
                .padding(8)
                .background(Color(hex: "0D1B2A"))
                .clipShape(.rect(cornerRadius: 8))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - TextField Style

private struct IngestFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(Color(hex: "0D1B2A"))
            .clipShape(.rect(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "1E3A5A"), lineWidth: 1))
            .foregroundStyle(.white)
            .font(.system(size: 15))
    }
}

private extension View {
    func ingestFieldStyle() -> some View { modifier(IngestFieldStyle()) }
}

// MARK: - Camera View

struct CameraView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(onCapture: onCapture) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage) -> Void
        init(onCapture: @escaping (UIImage) -> Void) { self.onCapture = onCapture }

        nonisolated func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage
            guard let image else { return }
            let capture = onCapture
            Task { @MainActor in
                capture(image)
                picker.dismiss(animated: true)
            }
        }

        nonisolated func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            Task { @MainActor in picker.dismiss(animated: true) }
        }
    }
}
