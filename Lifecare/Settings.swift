

import Foundation
import SwiftData

@Model
// NOTE: Structs can be compound members of a Model, but not classes.
// Otherwise, you may get an error "unexpected type in compund value".
// However, structs can be mutable so that prerequisite is probably okay.
final class Settings {
    
    var enableCheckIns: Bool = false
    var shouldPauseCheckIns: Bool = false
    var dateTimeToResumeCheckInsAfterPause : Date = Date()
    var weekdaysForCheckIns : WeekdaySelections = WeekdaySelections(allSelections : true)
    
    init() {
    }
}
