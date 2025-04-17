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
            return "Network error occurred"
        case .invalidRequest:
            return "Invalid request"
        case .serverError:
            return "Server error occurred"
            
        // API Errors
        case .invalidResponse:
            return "Invalid response from server"
        case .noAvailability:
            return "No availability for selected time"
        case .bookingFailed:
            return "Failed to book reservation"
            
        // General Errors
        case .unknown:
            return "An unknown error occurred"
            
        case .challengeRequired:
            return "Additional verification required. Please enter your email address."
        }
    }
} 
