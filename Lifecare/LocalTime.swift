

import Foundation

// Immutable. Value Type. (And other classes depend on this fact.)
// If you need to use this in a model, the model class has to be a class.
// Swift data does not yet and support inheritance, so either create a variable in your model class with this type, or
// you could copy this class body into your model class if you want your entire model class to be a local time instance.
struct LocalTime : Codable {
    let hour: Int // 0-23
    let minute: Int // 0-59
    let second: Int // 0-59
    
    // All parameters are optional. If they are omitted, they will default to zero.
    init(hour: Int = 0, minute: Int = 0, second: Int = 0) {
        self.hour = hour
        self.minute = minute
        self.second = second
    }
    
    func getSecondsOfDay() -> Int {
        return second + (minute * 60) + (hour * 60 * 60);
    }
    
    func toDate() -> Date {
        let calendar = Calendar(identifier: .gregorian)
        let components =  DateComponents(
            year: 2000, month: 1, day: 1, hour: hour, minute: minute, second: second)
        let date : Date = calendar.date(from: components)!
        return date
    }
    
    static func from(secondsOfDay: Int) -> LocalTime {
        let second = secondsOfDay % 60
        let minuteWithOverflow = secondsOfDay / 60
        let minute = minuteWithOverflow % 60
        let hour = minuteWithOverflow / 60
        let localTime :LocalTime = LocalTime(hour: hour, minute: minute, second : second)
        return localTime
    }
    
    static func from(date: Date) -> LocalTime {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let second = calendar.component(.second, from: date)
        let localTime :LocalTime = LocalTime(hour: hour, minute: minute, second : second)
        return localTime
    }
}
