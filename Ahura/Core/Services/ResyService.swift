import Foundation

protocol ResyServiceProtocol {
    func sendVerificationCode(to phoneNumber: String, completion: @escaping (Result<Void, AppError>) -> Void)
    func verifyCode(_ code: String, for phoneNumber: String, completion: @escaping (Result<ResyAuthResponse, AppError>) -> Void)
    func searchVenues(request: ResySearchRequest, completion: @escaping (Result<ResySearchResponse, AppError>) -> Void)
    func getVenueDetails(id: Int, completion: @escaping (Result<ResyVenue, AppError>) -> Void)
    func bookReservation(request: ResyBookingRequest, completion: @escaping (Result<Bool, AppError>) -> Void)
}

class ResyService: ResyServiceProtocol {
    static let shared = ResyService()
    
    private let baseURL = "https://api.resy.com/3"
    private let apiKey = "VbWk7s3L4KiK5fzlO7JD3Q5EYolJI7n5"
    
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
        
        let deviceToken = generateDeviceToken()
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
        guard let url = URL(string: "\(baseURL)/auth/verification/by_code") else {
            completion(.failure(.invalidRequest))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers()
        
        let body: [String: Any] = [
            "phone_number": phoneNumber,
            "code": code,
            "locale": "en-us",
            "device_type": "ios"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(.invalidRequest))
            return
        }
        
        print("Sending verification request to: \(url)")
        print("Headers: \(headers())")
        print("Body: \(body)")
        
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
}
