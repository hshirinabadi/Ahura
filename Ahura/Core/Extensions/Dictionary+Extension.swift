import Foundation

extension Dictionary where Key == String, Value == String {
    func asFormURLEncoded() -> String {
        map { key, value in
            let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            return "\(encodedKey)=\(encodedValue)"
        }
        .joined(separator: "&")
    }
}

private extension CharacterSet {
    /// RFC 3986 for `application/x-www-form-urlencoded` (excluding `+`, `&`, `=` etc.)
    static let urlQueryValueAllowed: CharacterSet = {
        var set = CharacterSet.urlQueryAllowed
        set.remove(charactersIn: "+&=")
        return set
    }()
}
