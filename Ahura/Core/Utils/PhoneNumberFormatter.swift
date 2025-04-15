import Foundation

enum PhoneNumberFormatter {
    /// Formats a phone number as +1XXXXXXXXXX and validates it
    static func format(_ number: String) -> String {
        // Remove any non-numeric characters
        var formatted = number.replacingOccurrences(of: "-", with: "")
        formatted = formatted.replacingOccurrences(of: " ", with: "")
        
        // Ensure it starts with +1
        if !formatted.hasPrefix("+1") {
            if formatted.hasPrefix("1") {
                formatted = "+" + formatted
            } else {
                formatted = "+1" + formatted
            }
        }
        return formatted
    }
    
    static func isValid(_ number: String) -> Bool {
        let formatted = format(number)
        return formatted.hasPrefix("+1") && formatted.count == 12
    }
} 
