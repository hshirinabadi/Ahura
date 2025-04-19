import Foundation

protocol ResyServiceProtocol {
    func sendVerificationCode(to phoneNumber: String, completion: @escaping (Result<Void, AppError>) -> Void)
    func verifyCode(_ code: String, for phoneNumber: String, completion: @escaping (Result<ResyAuthResponse, AppError>) -> Void)
    func completeChallenge(challengeId: String, email: String, completion: @escaping (Result<ResyAuthResponse, AppError>) -> Void)
    func searchVenues(request: ResySearchRequest, completion: @escaping (Result<ResySearchResponse, AppError>) -> Void)
    func getVenueDetails(id: Int, completion: @escaping (Result<ResyVenue, AppError>) -> Void)
    func bookReservation(request: ResyBookingRequest, completion: @escaping (Result<Bool, AppError>) -> Void)
    func getReservations(completion: @escaping (Result<ReservationsResponse, AppError>) -> Void)
    func getPastReservations(completion: @escaping (Result<ReservationsResponse, AppError>) -> Void)
    func getUpcomingReservations(completion: @escaping (Result<ReservationsResponse, AppError>) -> Void)
}

class ResyService: ResyServiceProtocol {
    static let shared = ResyService()
    
    private let baseURL = "https://api.resy.com/3"
    private let apiKey = "VbWk7s3L4KiK5fzlO7JD3Q5EYolJI7n5"
    private var deviceToken: String = ""
    
    private let awsBaseURL = "https://hrh6f7kaoh.execute-api.us-east-2.amazonaws.com/dev"
    
    private init() {}
    
    private func generateDeviceToken() -> String {
        return UUID().uuidString.lowercased()
    }
    
    private func headers() -> [String: String] {
        return [
            "Content-Type": "application/x-www-form-urlencoded",
            "Accept": "application/json, text/plain, */*",
            "Authorization": "ResyAPI api_key=\"\(apiKey)\"",
            "Origin": "https://resy.com",
            "Referer": "https://resy.com/",
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15",
            "X-Origin": "https://resy.com"
        ]
    }
    
    private func awsHeaders() -> [String: String] {
        var headers = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        
        // Add Resy auth token if available
        if let authToken = AuthService.shared.authToken {
            headers["x-resy-auth-token"] = authToken
            print("🔑 Using Resy auth token: \(authToken)")
        } else {
            print("⚠️ No Resy auth token available")
        }
        
        return headers
    }
    
    func sendVerificationCode(to phoneNumber: String, completion: @escaping (Result<Void, AppError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/auth/mobile") else {
            completion(.failure(.invalidRequest))
            return
        }
        let formattedNumber = PhoneNumberFormatter.format(phoneNumber)
        guard PhoneNumberFormatter.isValid(formattedNumber) else {
            completion(.failure(.invalidPhoneNumber))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers()
        
        deviceToken = generateDeviceToken()
        let params: [String: String] = [
            "mobile_number": phoneNumber,
            "method": "sms",
            "device_type_id": "3",
            "device_token": deviceToken
        ]
        let encodedParams = params.asFormURLEncoded()
        request.httpBody = encodedParams.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error: \(error)")
                completion(.failure(.networkError))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response type")
                completion(.failure(.networkError))
                return
            }
            
            print("Response status code: \(httpResponse.statusCode)")
            
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("Response data: \(responseString)")
            }
            
            switch httpResponse.statusCode {
            case 200, 201:
                completion(.success(()))
            case 400:
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = (json["data"] as? [String: String])?["mobile_number"] {
                    print("Validation error: \(message)")
                }
                completion(.failure(.invalidPhoneNumber))
            case 401, 419:
                completion(.failure(.authenticationError))
            case 429:
                completion(.failure(.tooManyRequests))
            case 500...599:
                completion(.failure(.serverError))
            default:
                completion(.failure(.unknown))
            }
        }.resume()
    }
    
    func verifyCode(_ code: String, for phoneNumber: String, completion: @escaping (Result<ResyAuthResponse, AppError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/auth/mobile") else {
            completion(.failure(.invalidRequest))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers()
        
        let params: [String: String] = [
            "mobile_number": phoneNumber,
            "code": code,
            "device_type_id": "3",
            "device_token": deviceToken
        ]
        let encodedParams = params.asFormURLEncoded()
        request.httpBody = encodedParams.data(using: .utf8)
        
        print("Sending verification request to: \(url)")
        print("Headers: \(headers())")
        print("Body: \(encodedParams)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error: \(error)")
                completion(.failure(.networkError))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.networkError))
                return
            }
            
            if let data = data {
                print("Response status: \(httpResponse.statusCode)")
                print("Response data: \(String(data: data, encoding: .utf8) ?? "No data")")
                
                do {
                    // First try to decode as a challenge response
                    if let challengeResponse = try? JSONDecoder().decode(ResyChallengeResponse.self, from: data) {
                        // If we get a challenge, we need to complete it
                        completion(.failure(.challengeRequired(challengeResponse)))
                        return
                    }
                    
                    // If not a challenge, try to decode as auth response
                    let response = try JSONDecoder().decode(ResyAuthResponse.self, from: data)
                    completion(.success(response))
                } catch {
                    print("Decoding error: \(error)")
                    completion(.failure(.invalidResponse))
                }
            } else {
                completion(.failure(.invalidResponse))
            }
        }.resume()
    }
    
    func completeChallenge(challengeId: String, email: String, completion: @escaping (Result<ResyAuthResponse, AppError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/auth/challenge") else {
            completion(.failure(.invalidRequest))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers()
        
        let params: [String: String] = [
            "challenge_id": challengeId,
            "em_address": email,
            "device_token": deviceToken,
            "device_type_id": "3"
        ]
        let encodedParams = params.asFormURLEncoded()
        request.httpBody = encodedParams.data(using: .utf8)
        
        print("Completing challenge request to: \(url)")
        print("Headers: \(headers())")
        print("Body: \(encodedParams)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error: \(error)")
                completion(.failure(.networkError))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.networkError))
                return
            }
            
            if let data = data {
                print("Response status: \(httpResponse.statusCode)")
                print("Response data: \(String(data: data, encoding: .utf8) ?? "No data")")
                
                do {
                    let response = try JSONDecoder().decode(ResyAuthResponse.self, from: data)
                    completion(.success(response))
                } catch {
                    print("Decoding error: \(error)")
                    completion(.failure(.invalidResponse))
                }
            } else {
                completion(.failure(.invalidResponse))
            }
        }.resume()
    }
    
    func searchVenues(request: ResySearchRequest, completion: @escaping (Result<ResySearchResponse, AppError>) -> Void) {
        
    }
    
    func getVenueDetails(id: Int, completion: @escaping (Result<ResyVenue, AppError>) -> Void) {
        
    }
    
    func bookReservation(request: ResyBookingRequest, completion: @escaping (Result<Bool, AppError>) -> Void) {
        
    }
    
    func getReservations(completion: @escaping (Result<ReservationsResponse, AppError>) -> Void) {
        guard let url = URL(string: "\(awsBaseURL)/reservations") else {
            print("❌ Invalid AWS URL: \(awsBaseURL)/reservations")
            completion(.failure(.invalidRequest))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = awsHeaders()
        
        print("🌐 Fetching reservations from AWS: \(url)")
        print("📋 Headers: \(awsHeaders())")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                completion(.failure(.networkError))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                completion(.failure(.networkError))
                return
            }
            
            print("📥 Response status code: \(httpResponse.statusCode)")
            
            if let data = data {
                print("📦 Response data: \(String(data: data, encoding: .utf8) ?? "No data")")
                
                switch httpResponse.statusCode {
                case 200:
                    do {
                        let response = try JSONDecoder().decode(ReservationsResponse.self, from: data)
                        completion(.success(response))
                    } catch {
                        print("❌ Decoding error: \(error)")
                        completion(.failure(.invalidResponse))
                    }
                case 401:
                    print("❌ Unauthorized - Invalid or expired token")
                    completion(.failure(.authenticationError))
                default:
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        print("❌ Server error: \(errorResponse.message)")
                        completion(.failure(.serverError))
                    } else {
                        print("❌ Unexpected error")
                        completion(.failure(.unknown))
                    }
                }
            } else {
                completion(.failure(.invalidResponse))
            }
        }.resume()
    }
    
    func getPastReservations(completion: @escaping (Result<ReservationsResponse, AppError>) -> Void) {
        guard let url = URL(string: "\(awsBaseURL)/reservations/past") else {
            completion(.failure(.invalidRequest))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = awsHeaders()
        
        print("🌐 Fetching past reservations from: \(url)")
        print("📋 Headers: \(awsHeaders())")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Network error: \(error)")
                completion(.failure(.networkError))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.networkError))
                return
            }
            
            if let data = data {
                print("📥 Response status: \(httpResponse.statusCode)")
                print("📦 Response data: \(String(data: data, encoding: .utf8) ?? "No data")")
                
                switch httpResponse.statusCode {
                case 200:
                    do {
                        let response = try JSONDecoder().decode(ReservationsResponse.self, from: data)
                        completion(.success(response))
                    } catch {
                        print("❌ Decoding error: \(error)")
                        completion(.failure(.invalidResponse))
                    }
                case 401:
                    print("❌ Unauthorized - Invalid or expired token")
                    completion(.failure(.authenticationError))
                default:
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        print("❌ Server error: \(errorResponse.message)")
                        completion(.failure(.serverError))
                    } else {
                        print("❌ Unexpected error")
                        completion(.failure(.unknown))
                    }
                }
            } else {
                completion(.failure(.invalidResponse))
            }
        }.resume()
    }
    
    func getUpcomingReservations(completion: @escaping (Result<ReservationsResponse, AppError>) -> Void) {
        guard let url = URL(string: "\(awsBaseURL)/reservations/upcoming") else {
            completion(.failure(.invalidRequest))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = awsHeaders()
        
        print("🌐 Fetching upcoming reservations from: \(url)")
        print("📋 Headers: \(awsHeaders())")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Network error: \(error)")
                completion(.failure(.networkError))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.networkError))
                return
            }
            
            if let data = data {
                print("📥 Response status: \(httpResponse.statusCode)")
                print("📦 Response data: \(String(data: data, encoding: .utf8) ?? "No data")")
                
                switch httpResponse.statusCode {
                case 200:
                    do {
                        let response = try JSONDecoder().decode(ReservationsResponse.self, from: data)
                        completion(.success(response))
                    } catch {
                        print("❌ Decoding error: \(error)")
                        completion(.failure(.invalidResponse))
                    }
                case 401:
                    print("❌ Unauthorized - Invalid or expired token")
                    completion(.failure(.authenticationError))
                default:
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        print("❌ Server error: \(errorResponse.message)")
                        completion(.failure(.serverError))
                    } else {
                        print("❌ Unexpected error")
                        completion(.failure(.unknown))
                    }
                }
            } else {
                completion(.failure(.invalidResponse))
            }
        }.resume()
    }
}

// MARK: - Reservation Methods
extension ResyService {
    // Remove duplicate methods - they are already declared in the main class
}
