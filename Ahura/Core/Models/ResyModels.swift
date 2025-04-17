import Foundation

// MARK: - Auth Models
struct ResyAuthResponse: Codable {
    let token: String
    let userId: Int
    let expiresAt: Int
    
    enum CodingKeys: String, CodingKey {
        case token = "token"
        case userId = "id"
        case expiresAt = "date_updated"
    }
}
    

// MARK: - Search Models
struct ResySearchRequest: Codable {
    let lat: Double?
    let long: Double?
    let day: String
    let partySize: Int
    let venue_id: Int?
    
    enum CodingKeys: String, CodingKey {
        case lat, long, day
        case partySize = "party_size"
        case venue_id
    }
}

struct ResySearchResponse: Codable {
    let results: [ResyVenue]
    let total: Int
}

// MARK: - Venue Models
struct ResyVenue: Codable {
    let id: Int
    let name: String
    let type: String
    let location: ResyLocation
    let price: Int
    let rating: Double?
    let description: String?
    let photos: [ResyPhoto]?
    let slots: [ResyTimeSlot]?
}

struct ResyLocation: Codable {
    let address: String
    let city: String
    let state: String
    let postalCode: String
    let lat: Double
    let long: Double
    
    enum CodingKeys: String, CodingKey {
        case address, city, state
        case postalCode = "postal_code"
        case lat, long
    }
}

struct ResyPhoto: Codable {
    let url: String
    let caption: String?
}

struct ResyTimeSlot: Codable {
    let time: String
    let available: Bool
}

// MARK: - Booking Models
struct ResyBookingRequest: Codable {
    let venueId: Int
    let partySize: Int
    let day: String
    let time: String
    
    enum CodingKeys: String, CodingKey {
        case venueId = "venue_id"
        case partySize = "party_size"
        case day, time
    }
}

struct ResyChallengeResponse: Codable {
    let mobileClaim: MobileClaim
    let challenge: Challenge
    
    enum CodingKeys: String, CodingKey {
        case mobileClaim = "mobile_claim"
        case challenge
    }
}

struct MobileClaim: Codable {
    let mobileNumber: String
    let claimToken: String
    let dateExpires: String
    
    enum CodingKeys: String, CodingKey {
        case mobileNumber = "mobile_number"
        case claimToken = "claim_token"
        case dateExpires = "date_expires"
    }
}

struct Challenge: Codable {
    let challengeId: String
    let firstName: String
    let message: String
    let properties: [ChallengeProperty]
    
    enum CodingKeys: String, CodingKey {
        case challengeId = "challenge_id"
        case firstName = "first_name"
        case message
        case properties
    }
}

struct ChallengeProperty: Codable {
    let name: String
    let type: String
    let message: String
} 
