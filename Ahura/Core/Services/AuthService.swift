import Foundation

protocol AuthServiceProtocol {
    func sendVerificationCode(to phoneNumber: String, completion: @escaping (Result<Void, AuthError>) -> Void)
    func verifyCode(_ code: String, for phoneNumber: String, completion: @escaping (Result<Void, AuthError>) -> Void)
}

class AuthService: AuthServiceProtocol {
    static let shared = AuthService()
    
    private init() {}
    
    func sendVerificationCode(to phoneNumber: String, completion: @escaping (Result<Void, AuthError>) -> Void) {
        // TODO: Implement actual API call to send verification code
        // For now, simulate API call with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(.success(()))
        }
    }
    
    func verifyCode(_ code: String, for phoneNumber: String, completion: @escaping (Result<Void, AuthError>) -> Void) {
        // TODO: Implement actual API call to verify code
        // For now, simulate API call with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if code == "1234" { // For testing purposes
                completion(.success(()))
            } else {
                completion(.failure(.invalidCode))
            }
        }
    }
} 