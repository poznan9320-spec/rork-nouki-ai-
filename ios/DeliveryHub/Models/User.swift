import Foundation

nonisolated struct User: Codable {
    let id: String
    let email: String
    let name: String?
    let role: String
    let status: String?
}

nonisolated struct Company: Codable {
    let id: String
    let name: String
}

nonisolated struct LoginResponse: Codable {
    let token: String
    let user: User
    let company: Company
}
