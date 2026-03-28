import SwiftUI

enum IngestMode { case ocr, manual }

@Observable
final class IngestViewModel {
    var mode: IngestMode = .ocr

    // OCR mode
    var selectedImage: UIImage? = nil
    var freeText: String = ""
    var supplierName: String = ""
    var ocrItems: [OCRItem] = []
    var ocrSourceType: String = "TEXT"
    var ocrFileUrl: String? = nil
    var isProcessingOCR: Bool = false
    var showImagePicker: Bool = false
    var showCamera: Bool = false

    // Manual mode
    var manualProductName: String = ""
    var manualQuantityText: String = ""
    var manualSupplierName: String = ""
    var manualNotes: String = ""
    var manualDeliveryDate: Date = Date()
    var manualQuantity: Int { Int(manualQuantityText) ?? 1 }

    var manualCanSubmit: Bool {
        !manualProductName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && manualQuantity > 0
    }

    // Shared state
    var isSubmitting: Bool = false
    var errorMessage: String? = nil
    var successMessage: String? = nil

    // MARK: - OCR

    @MainActor
    func runOCR() async {
        guard selectedImage != nil || !freeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "写真またはテキストを入力してください"
            return
        }

        isProcessingOCR = true
        errorMessage = nil
        ocrItems = []

        var imageData: Data? = nil
        if let image = selectedImage,
           let jpeg = image.jpegData(compressionQuality: 0.7) {
            imageData = jpeg
        }

        let text = freeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : freeText
        let supplier = supplierName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : supplierName

        do {
            let result = try await NetworkService.shared.ingestOCR(
                imageData: imageData,
                mimeType: "image/jpeg",
                text: text,
                supplierName: supplier
            )
            ocrItems = result.items
            ocrSourceType = result.sourceType
            ocrFileUrl = result.fileUrl
            if let s = result.supplierName, !s.isEmpty {
                supplierName = s
            }
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "OCR処理に失敗しました。再度お試しください。"
        }
        isProcessingOCR = false
    }

    @MainActor
    func saveOCR() async {
        guard !ocrItems.isEmpty else { return }
        isSubmitting = true
        errorMessage = nil
        successMessage = nil

        let supplier = supplierName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : supplierName

        do {
            let result = try await NetworkService.shared.ingestSave(
                items: ocrItems,
                supplierName: supplier,
                sourceType: ocrSourceType,
                sourceUrl: ocrFileUrl
            )
            if result.imported == 0 {
                successMessage = "全て重複のためスキップしました（\(result.skipped)件）"
            } else if result.skipped > 0 {
                successMessage = "\(result.imported)件登録しました（重複\(result.skipped)件スキップ）"
            } else {
                successMessage = "\(result.imported)件の入荷データを登録しました"
            }
            resetOCR()
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "保存に失敗しました。再度お試しください。"
        }
        isSubmitting = false
    }

    func resetOCR() {
        selectedImage = nil
        freeText = ""
        supplierName = ""
        ocrItems = []
        ocrFileUrl = nil
    }

    // MARK: - Manual

    @MainActor
    func submitManual() async {
        guard manualCanSubmit else { return }
        isSubmitting = true
        errorMessage = nil
        successMessage = nil

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: manualDeliveryDate)

        let item = OCRItem(
            productName: manualProductName.trimmingCharacters(in: .whitespacesAndNewlines),
            quantity: manualQuantity,
            deliveryDate: dateStr,
            notes: manualNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : manualNotes
        )
        let supplier = manualSupplierName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : manualSupplierName

        do {
            let result = try await NetworkService.shared.ingestSave(
                items: [item],
                supplierName: supplier,
                sourceType: "TEXT",
                sourceUrl: nil
            )
            if result.imported == 0 {
                successMessage = "既に同じデータが登録されています"
            } else {
                successMessage = "入荷データを登録しました"
            }
            resetManual()
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "登録に失敗しました。再度お試しください。"
        }
        isSubmitting = false
    }

    func resetManual() {
        manualProductName = ""
        manualQuantityText = ""
        manualSupplierName = ""
        manualNotes = ""
        manualDeliveryDate = Date()
    }
}
