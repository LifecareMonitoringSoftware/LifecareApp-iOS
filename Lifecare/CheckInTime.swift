

import Foundation
import SwiftData

@Model
final class CheckInTime : Comparable {
    private var time: LocalTime
    var isSelected : Bool = false
    static let minimumCheckInSpacingSeconds : Int = 10 * 60 // 10 Minutes = (10 * 60)
    static private let secondsIn_24_hours : Int = (24 * 60 * 60)
    
    var date: Date {
        get {
            time.toDate()
        }
        set {
            time = LocalTime.from(date: newValue)
        }
    }
    
    func getTime() -> LocalTime {
        return time
    }
    
    func setTime(time : LocalTime) {
        self.time = time
    }
    
    func shiftTime(shiftHours: Int, shiftMinutes: Int) -> Void {
        let calendar = Calendar.current
        let startDate = time.toDate()
        let hourAdjustedDate : Date = calendar.date(byAdding: .hour, value: shiftHours, to: startDate)!
        let finalAdjustedDate : Date = calendar.date(byAdding: .minute, value: shiftMinutes, to: hourAdjustedDate)!
        time = LocalTime.from(date: finalAdjustedDate)
    }
    
    func clearSelection() {
        isSelected = false
    }
    
    public var description: String { 
        return time.hour.description + ":" + time.minute.description + ":" + time.second.description
    }
    
    // All parameters are optional. If they are omitted, they will default to zero.
    init(hour: Int = 0, minute: Int = 0, second: Int = 0) {
        self.time = LocalTime(hour: hour, minute: minute, second: second)
    }
    
    init(date: Date) {
        self.time = LocalTime.from(date: date)
    }
    
    init(secondsOfDay: Int) {
        self.time = LocalTime.from(secondsOfDay: secondsOfDay)
    }
    
    init(checkInTime_AsTimeSource: CheckInTime) {
        // This is okay because LocalTime is an immutable, value type.
        self.time = checkInTime_AsTimeSource.time
    }
    
    func isTooCloseToAnotherCheckInTime(checkInTimes: [CheckInTime]) -> Bool {
        let selfSecondsOfDay : Int = self.time.getSecondsOfDay()
        for otherCheckInTime in checkInTimes {
            if (self === otherCheckInTime) {
                continue
            }
            // We will convert all other check in times to be in the past, if they are not already.
            var otherSecondsOfDay_ForcedIntoPast = otherCheckInTime.time.getSecondsOfDay()
            if(otherSecondsOfDay_ForcedIntoPast > selfSecondsOfDay) {
                otherSecondsOfDay_ForcedIntoPast -= CheckInTime.secondsIn_24_hours
            }
            let secondsDifference : Int = selfSecondsOfDay - otherSecondsOfDay_ForcedIntoPast
            if(secondsDifference < CheckInTime.minimumCheckInSpacingSeconds) {
                return true
            }
        } // End: for otherCheckInTime in checkInTimes
        return false
    }
    
    
    static func < (lhs: CheckInTime, rhs: CheckInTime) -> Bool {
        return (lhs.time.getSecondsOfDay() < rhs.time.getSecondsOfDay())
    }
}
