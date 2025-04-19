import Foundation

enum AppError: Error {
    // Auth Errors
    case invalidPhoneNumber
    case invalidCode
    case authenticationError
    case tooManyRequests
    
    // Network Errors
    case networkError
    case invalidRequest
    case serverError
    
    // API Errors
    case invalidResponse
    case noAvailability
    case bookingFailed
    
    // General Errors
    case unknown
    
    case challengeRequired(ResyChallengeResponse)
    
    var message: String {
        switch self {
        // Auth Errors
        case .invalidPhoneNumber:
            return "Invalid phone number"
        case .invalidCode:
            return "Invalid verification code"
        case .authenticationError:
            return "Authentication failed"
        case .tooManyRequests:
            return "Too many attempts. Please try again later"
            
        // Network Errors
        case .networkError:
            return "Network connection error. Please check your internet connection and try again."
        case .invalidRequest:
            return "Invalid request. Please try again."
        case .serverError:
            return "Server error. Please try again later."
            
        // API Errors
        case .invalidResponse:
            return "Invalid response from server. Please try again."
        case .noAvailability:
            return "No availability for selected time"
        case .bookingFailed:
            return "Failed to book reservation"
            
        // General Errors
        case .unknown:
            return "An unknown error occurred. Please try again."
            
        case .challengeRequired:
            return "Additional verification required. Please enter your email address."
        }
    }
}

enum Result<Success, Failure: Error> {
    case success(Success)
    case failure(Failure)
} 
