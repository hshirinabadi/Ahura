import Foundation
import AWSCognitoIdentityProvider

protocol AuthServiceProtocol {
    func sendVerificationCode(to phoneNumber: String, completion: @escaping (Result<Void, AuthError>) -> Void)
    func verifyCode(_ code: String, for phoneNumber: String, completion: @escaping (Result<Void, AuthError>) -> Void)
}

class AuthService: AuthServiceProtocol {
    static let shared = AuthService()
    
    private let userPool: AWSCognitoIdentityUserPool
    private let configuration: AWSServiceConfiguration
    
    private init() {
        // Initialize AWS Cognito
        let poolId = "YOUR_POOL_ID" // Get from AWS Console
        let clientId = "YOUR_CLIENT_ID" // Get from AWS Console
        let region = AWSRegionType.USEast1 // Update with your region
        
        configuration = AWSServiceConfiguration(
            region: region,
            credentialsProvider: nil
        )
        
        let poolConfiguration = AWSCognitoIdentityUserPoolConfiguration(
            clientId: clientId,
            clientSecret: nil,
            poolId: poolId
        )
        
        AWSCognitoIdentityUserPool.register(
            with: configuration,
            userPoolConfiguration: poolConfiguration,
            forKey: "UserPool"
        )
        
        userPool = AWSCognitoIdentityUserPool(forKey: "UserPool")
    }
    
    func sendVerificationCode(to phoneNumber: String, completion: @escaping (Result<Void, AuthError>) -> Void) {
        let formattedNumber = formatPhoneNumber(phoneNumber)
        
        let userAttributes = [
            "phone_number": formattedNumber
        ]
        
        userPool.signUp(
            formattedNumber,
            password: generateTempPassword(),
            userAttributes: userAttributes.map { AWSCognitoIdentityUserAttributeType().apply { $0.name = $0; $0.value = $1 } },
            validationData: nil
        ).continueWith { task in
            DispatchQueue.main.async {
                if let error = task.error {
                    print("Sign up error:", error)
                    completion(.failure(.networkError))
                    return
                }
                
                completion(.success(()))
            }
        }
    }
    
    func verifyCode(_ code: String, for phoneNumber: String, completion: @escaping (Result<Void, AuthError>) -> Void) {
        let formattedNumber = formatPhoneNumber(phoneNumber)
        
        guard let user = userPool.getUser(formattedNumber) else {
            completion(.failure(.invalidPhoneNumber))
            return
        }
        
        user.confirmSignUp(code).continueWith { task in
            DispatchQueue.main.async {
                if let error = task.error {
                    print("Verification error:", error)
                    completion(.failure(.invalidCode))
                    return
                }
                
                // After successful verification, sign in the user
                self.signIn(phoneNumber: formattedNumber) { result in
                    switch result {
                    case .success:
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    private func signIn(phoneNumber: String, completion: @escaping (Result<Void, AuthError>) -> Void) {
        guard let user = userPool.getUser(phoneNumber) else {
            completion(.failure(.invalidPhoneNumber))
            return
        }
        
        // Use the same temporary password used during sign up
        user.signIn(generateTempPassword()).continueWith { task in
            DispatchQueue.main.async {
                if let error = task.error {
                    print("Sign in error:", error)
                    completion(.failure(.authenticationError))
                    return
                }
                
                // Get the user's session tokens
                user.getSession().continueWith { sessionTask in
                    if let session = sessionTask.result {
                        // Store the tokens
                        UserDefaults.standard.set(session.idToken?.tokenString, forKey: "id_token")
                        UserDefaults.standard.set(session.accessToken?.tokenString, forKey: "access_token")
                        UserDefaults.standard.set(session.refreshToken?.tokenString, forKey: "refresh_token")
                        
                        // Set the token in ResyService
                        ResyService.shared.setAuthToken(session.accessToken?.tokenString ?? "")
                        
                        completion(.success(()))
                    } else {
                        completion(.failure(.authenticationError))
                    }
                }
            }
        }
    }
    
    private func formatPhoneNumber(_ number: String) -> String {
        // Remove any non-numeric characters
        let digits = number.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        // Ensure the number starts with +1 for US numbers
        if !digits.hasPrefix("1") {
            return "+1" + digits
        }
        return "+" + digits
    }
    
    private func generateTempPassword() -> String {
        // Generate a temporary password that meets Cognito requirements
        // This is used only for initial sign up and first sign in
        return "TempPass123!"
    }
}

private extension NSObject {
    func apply(_ closure: (Self) -> Void) -> Self {
        closure(self)
        return self
    }
} 