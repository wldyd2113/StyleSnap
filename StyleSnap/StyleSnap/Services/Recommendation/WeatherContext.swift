import Foundation

enum Season: String {
    case spring = "봄", summer = "여름", autumn = "가을", winter = "겨울"
}

enum TimeOfDay {
    case morning, afternoon, evening, night
}

struct WeatherContext {
    static var currentSeason: Season {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5: return .spring
        case 6...8: return .summer
        case 9...11: return .autumn
        default: return .winter
        }
    }
    
    static var currentTime: TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6...11: return .morning
        case 12...17: return .afternoon
        case 18...21: return .evening
        default: return .night
        }
    }
}
