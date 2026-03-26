import SwiftUI

@Observable
final class RequestViewModel {
    var productName: String = ""
    var quantityText: String = ""
    var memo: String = ""
    var selectedImage: UIImage? = nil
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var successMessage: String? = nil
    var showImagePicker: Bool = false
    var showCamera: Bool = false

    var quantity: Int { Int(quantityText) ?? 0 }

    var canSubmit: Bool {
        !productName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && quantity > 0
    }

    @MainActor
    func submit() async {
        guard canSubmit else { return }
        isLoading = true
        errorMessage = nil
        successMessage = nil

        var imageBase64: String? = nil
        if let image = selectedImage,
           let imageData = image.jpegData(compressionQuality: 0.5) {
            imageBase64 = imageData.base64EncodedString()
        }

        do {
            try await NetworkService.shared.sendOrderRequest(
                productName: productName.trimmingCharacters(in: .whitespacesAndNewlines),
                quantity: quantity,
                memo: memo.trimmingCharacters(in: .whitespacesAndNewlines),
                imageBase64: imageBase64
            )
            successMessage = "発注依頼を送信しました。"
            reset()
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "送信に失敗しました。再度お試しください。"
        }
        isLoading = false
    }

    func reset() {
        productName = ""
        quantityText = ""
        memo = ""
        selectedImage = nil
    }
}
