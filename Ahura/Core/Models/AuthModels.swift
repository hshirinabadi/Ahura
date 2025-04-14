import Foundation

struct PhoneAuthRequest {
    let phoneNumber: String
    
    var formattedNumber: String {
        // TODO: Implement proper phone formatting
        return phoneNumber
    }
}

struct VerificationRequest {
    let phoneNumber: String
    let code: String
}

enum AuthError: Error {
    case invalidPhoneNumber
    case invalidCode
    case networkError
    case unknown
    
    var message: String {
        switch self {
        case .invalidPhoneNumber:
            return "Please enter a valid phone number"
        case .invalidCode:
            return "Please enter a valid verification code"
        case .networkError:
            return "Network error occurred. Please try again"
        case .unknown:
            return "An unknown error occurred"
        }
    }
} 