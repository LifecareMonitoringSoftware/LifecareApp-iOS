

import Foundation
import SwiftData


// Our internal enumeration is nonstandard, but the internal enumeration is
// not exposed outside the class.
// Internal: 0 Mon to 6 Sun.
//
// These other enumerations are used elsewhere in swift:
// let currentWeekday : Int = calendar.component(.weekday, from: date) // 1 Sun to 7 Sat.
// let weekdaySymbols : [String] = calendar.weekdaySymbols // 0 Sun to 6 Sat.

struct WeekdaySelections : Codable {
    
    // This is our selection data array.
    // This exists to keep this class separate from SwiftData. (This class was causing fatal errors.)
    // The data uses scheme 0 Mon to 6 Sun. (In swift, this is not a standard enumeration scheme.)
    private var selections : [Bool] = [false, false, false, false, false, false, false]
    
    // This was originally created because there was concern that swiftdata might crash when an enum
    // has explicit integers associated with the values.
    // This was kept because it prevents exposure of our nonstandard enumeration scheme outside this class.
    private static let weekdayToIndexMap : [Weekday:Int] =
    [Weekday.Mon:0, Weekday.Tue:1, Weekday.Wed:2, Weekday.Thu:3, Weekday.Fri:4, Weekday.Sat:5, Weekday.Sun:6]
    // This exist because swiftdata crashes when an enum has explicit integers associated with the values.
    private static let indexToWeekdayArray : [Weekday] =
    [Weekday.Mon, Weekday.Tue, Weekday.Wed, Weekday.Thu, Weekday.Fri, Weekday.Sat, Weekday.Sun]
    
    
    init(allSelections : Bool) {
        selections = [allSelections, allSelections, allSelections, allSelections,
                      allSelections, allSelections, allSelections]
    }
    
    init(mon : Bool = true, tue : Bool = true, wed : Bool = true, thu : Bool = true,
         fri : Bool = true, sat : Bool = true, sun : Bool = true) {
        selections = [mon, tue, wed, thu, fri, sat, sun]
    }
    
    public var description: String {
        return "Mon: \(selections[0]), Tue: \(selections[1]), Wed: \(selections[2]), " +
        "Thu: \(selections[3]), Fri: \(selections[4]), Sat: \(selections[5]), " +
        "Sun: \(selections[6])."
    }
    
    public func getAllSelectedWeekdays() -> [Weekday] {
        var allSelectedWeekdays : [Weekday] = []
        for index in 0..<selections.endIndex {
            if(selections[index] == true) {
                allSelectedWeekdays.append(WeekdaySelections.indexToWeekdayArray[index])
            }
        }
        return allSelectedWeekdays
    }
    
    
    // hasSingleMultidaySubsetSelection
    // This returns true if and only if:
    // - The number of selected weekdays is between 2 and 6, inclusive.
    // - The selected weekdays are all contiguous with each other.
    // (Wrapping over the Sun/Mon boundary is NOT allowed.)
    private func hasSingleMultidaySubsetSelection() -> Bool {
        let selectedWeekdayCount = getSelectedWeekdayCount()
        if(selectedWeekdayCount < 2 || selectedWeekdayCount == 7) {
            return false
        }
        let firstTrueSequenceCount_NoWrapping =
        getFirstContiguousSequenceOfInterestCount_NoWrapping(valueOfInterest : true)
        return (firstTrueSequenceCount_NoWrapping == selectedWeekdayCount)
    }
    
    // getSingleMultidaySubsetEndpointsOrNil
    // If (hasSingleMultidaySubsetSelection() == true), this will return the subset endpoints.
    // (Wrapping over the Sun/Mon boundary is NOT allowed.)
    // If (hasSingleMultidaySubsetSelection() == false), this will return nil.
    func getSingleMultidaySubsetEndpointsOrNil() -> (firstWeekday: Weekday, lastWeekday: Weekday)? {
        if(!hasSingleMultidaySubsetSelection()) {
            return nil
        }
        let firstSelectionIndex = selections.firstIndex(of: true)!
        let lastSelectionIndex = selections.lastIndex(of: true)!
        let firstWeekday : Weekday = WeekdaySelections.indexToWeekdayArray[firstSelectionIndex]
        let lastWeekday : Weekday = WeekdaySelections.indexToWeekdayArray[lastSelectionIndex]
        return (firstWeekday, lastWeekday)
    }
    
    func getSelectedWeekdayCount() -> Int {
        var count : Int = 0
        for selection in selections {
            if(selection == true){
                count += 1
            }
        }
        return count
    }
    
    private func getFirstContiguousSequenceOfInterestCount_NoWrapping(valueOfInterest : Bool) -> Int {
        var length : Int = 0
        for selection in selections {
            if(selection == valueOfInterest){
                // Selection matches the value of interest.
                length += 1
            } else {
                // Selection does not match the value of interest.
                // On the first mismatch after we have counted at least one item, stop counting.
                if(length > 0){
                    break
                }
            }
        }
        return length
    }
    
    mutating func setSelected(weekday : Weekday, selection : Bool) {
        selections[WeekdaySelections.weekdayToIndexMap[weekday]!] = selection
    }
    
    func isWeekdaySelected(weekday : Weekday) -> Bool {
        return selections[WeekdaySelections.weekdayToIndexMap[weekday]!]
    }
    
    func isDateSelected(date : Date) -> Bool {
        let calendar = Calendar.current
        // The Date Scheme is 1 Sun to 7 Sat.
        let dateOrdinal : Int = calendar.component(.weekday, from: date)
        // The Internal Scheme is 0 Mon to 6 Sun.
        let internalOrdinal = convertDateOrdinal_ToInternalOrdinal(dateOrdinal: dateOrdinal)
        return selections[internalOrdinal]
    }
    
    func areAllDays_Selected() -> Bool {
        return selections.allSatisfy { $0 == true }
    }
    
    func areAllDays_NotSelected() -> Bool {
        return selections.allSatisfy { $0 == false }
    }
    
    // This converts from (Date scheme: 1 Sun to 7 Sat) to (Internal Scheme:  0 Mon to 6 Sun).
    func convertDateOrdinal_ToInternalOrdinal(dateOrdinal : Int) -> Int {
        // Visual explanation: 1->6, 2->0, 3->1, 4->2, 5->3, 6->4, 7->5.
        if(dateOrdinal == 1) {
            return 6
        }
        return (dateOrdinal - 2)
    }
    
    // This converts from (Internal Scheme:  0 Mon to 6 Sun) to (Date scheme: 1 Sun to 7 Sat).
    func convertDateOrdinal_FromInternalOrdinal(internalOrdinal : Int) -> Int {
        // Visual explanation: 6->1, 0->2, 1->3, 2->4, 3->5, 4->6, 5->7.
        if(internalOrdinal == 6) {
            return 1
        }
        return (internalOrdinal + 2)
    }
}
