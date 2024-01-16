

import Foundation

// Weekday enum
public enum Weekday : Int, Codable {
    case Mon = 0, Tue, Wed, Thu, Fri, Sat, Sun
    
    var threeLetterDescription : String {
        switch self {
            // Future note: Use Internationalization, as appropriate.
        case .Mon: return "Mon"
        case .Tue: return "Tue"
        case .Wed: return "Wed"
        case .Thu: return "Thu"
        case .Fri: return "Fri"
        case .Sat: return "Sat"
        case .Sun: return "Sun"
        }
    }
    
    var twoLetterDescription : String {
        switch self {
            // Future note: Use Internationalization, as appropriate.
        case .Mon: return "Mo"
        case .Tue: return "Tu"
        case .Wed: return "We"
        case .Thu: return "Th"
        case .Fri: return "Fr"
        case .Sat: return "Sa"
        case .Sun: return "Su"
        }
    }
}
