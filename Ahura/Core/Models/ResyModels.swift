import Foundation

// MARK: - Auth Models
struct ResyAuthResponse: Codable {
    let token: String
    let userId: String
    let expiresAt: String
    
    enum CodingKeys: String, CodingKey {
        case token = "auth_token"
        case userId = "user_id"
        case expiresAt = "expires_at"
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
