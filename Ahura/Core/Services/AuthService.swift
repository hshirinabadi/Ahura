import Foundation

protocol AuthServiceProtocol {
    func sendVerificationCode(to phoneNumber: String, completion: @escaping (Result<Void, AppError>) -> Void)
    func verifyCode(_ code: String, for phoneNumber: String, completion: @escaping (Result<ResyAuthResponse, AppError>) -> Void)
    func completeChallenge(challengeId: String, email: String, completion: @escaping (Result<ResyAuthResponse, AppError>) -> Void)
    var isLoggedIn: Bool { get }
    var authToken: String? { get }
}

class AuthService: AuthServiceProtocol {
    static let shared = AuthService()
    
    private let userDefaults = UserDefaults.standard
    private let authTokenKey = "resy_auth_token"
    private let userPhoneKey = "user_phone"
    
    private init() {}
    
    var isLoggedIn: Bool {
        return userDefaults.string(forKey: authTokenKey) != nil
    }
    
    var authToken: String? {
        return userDefaults.string(forKey: authTokenKey)
    }
    
    var userPhone: String? {
        return userDefaults.string(forKey: userPhoneKey)
    }
    
    func sendVerificationCode(to phoneNumber: String, completion: @escaping (Result<Void, AppError>) -> Void) {
        let formattedNumber = PhoneNumberFormatter.format(phoneNumber)
        
        ResyService.shared.sendVerificationCode(to: formattedNumber) { result in
            switch result {
            case .success:
                self.userDefaults.set(formattedNumber, forKey: self.userPhoneKey)
                completion(.success(()))
            case .failure (let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func verifyCode(_ code: String, for phoneNumber: String, completion: @escaping (Result<ResyAuthResponse, AppError>) -> Void) {
        let formattedNumber = PhoneNumberFormatter.format(phoneNumber)
        
        ResyService.shared.verifyCode(code, for: formattedNumber) { result in
            switch result {
            case .success(let response):
                self.userDefaults.set(response.token, forKey: self.authTokenKey)
                self.userDefaults.set(formattedNumber, forKey: self.userPhoneKey)
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func completeChallenge(challengeId: String, email: String, completion: @escaping (Result<ResyAuthResponse, AppError>) -> Void) {
        ResyService.shared.completeChallenge(challengeId: challengeId, email: email) { result in
            switch result {
            case .success(let response):
                self.userDefaults.set(response.token, forKey: self.authTokenKey)
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func logout() {
        userDefaults.removeObject(forKey: authTokenKey)
        userDefaults.removeObject(forKey: userPhoneKey)
    }
} 
