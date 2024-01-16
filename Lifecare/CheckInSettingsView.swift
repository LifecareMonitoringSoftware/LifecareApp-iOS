

import SwiftUI
import SwiftData


// Start a TB board for Swift.
// Task: Add the ability to pause Check Ins until a specified time or date.
// Task: Add the ability to swipe to unpause.
// Task: Disable the other control buttons when one of the special control
// sections is open.
// Decided to only show delete all button for developer. (only needed for development.)
// Will not limit check ins to less than 30 per day. (I can't fully predict what people may need.)
struct CheckInSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var checkInTimes: [CheckInTime]
    @Query private var config: [Settings]
    @State private var editMode : EditMode = EditMode.inactive
    @State private var showBulkEditControls : Bool = false
    @State private var showWeeklyEditControls : Bool = false
    @State private var showPauseControls : Bool = false
    @State private var showUndoBulkEditsButton : Bool = false
    @State private var bulkShiftHours : Int = 0
    @State private var bulkShiftMinutes : Int = 0
    @State private var showCheckInLimitReachedAlert = false
    @State private var savedCheckIns_SecondsOfDayList_ForBulkUndo: [Int] = []
    let maximumCheckInsPerDay : Int = 30
    let thirtyMinutesInSeconds : Int = (30 * 60)
    let useDevMode : Bool = true
    let showDevClearButton : Bool = false
    
    var body: some View {
        
        ScrollView(.vertical) {
            VStack{
                Toggle(isOn: Bindable(config[0]).enableCheckIns) {
                    Text("Enable Check In System")
                }
                .onTapGesture(perform: {
                    if(useDevMode) {
                        config[0].enableCheckIns.toggle()
                    }
                })
                .onChange(of: config[0].enableCheckIns) {
                    oldValue, newValue in
                    if(newValue == false) {
                        editMode = EditMode.inactive
                        showBulkEditControls = false
                    }
                }
                if(!showPauseControls && config[0].shouldPauseCheckIns) {
                    HStack{
                        PausedCheckInView()
                            .bold()
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
                HStack{
                    Text("Check In Times")
                        .padding(.top)
                        .font(.title2)
                    Spacer()
                }
                HStack{
                    if(showDevClearButton) {
                        Button(action: deleteAllCheckIns) {
                            Text("Clear")
                                .bold()
                        }
                    }
                    if(areCheckInTimesOutOfOrder()) {
                        Button(action: sortCheckInTimeList) {
                            Text("Sort List?")
                                .bold()
                        }
                    }
                    Spacer()
                    if(editMode == EditMode.active) {
                        Button(action: deleteSelectedCheckInsAction) {
                            Text("[Delete Selected]")
                                .bold()
                        }
                        .padding(.trailing , 10)
                    }
                    Button(action: addCheckInTime) {
                        Label("", systemImage: "plus").bold()
                    }
                    .alert("Can not create more than \(maximumCheckInsPerDay) Check Ins per day.", isPresented: $showCheckInLimitReachedAlert) {
                        Button("OK", role: .cancel) { }
                    }
                    EditButton()
                        .bold()
                        .disabled(editMode == EditMode.inactive && checkInTimes.isEmpty)
                }
                .disabled(config[0].enableCheckIns == false)
                
                Divider()
                
                VStack {
                    
                    if(config[0].enableCheckIns == false) {
                        HStack{
                            Text("The check in system is currently disabled.\n"
                                 + "You can enable it if desired.")
                            Spacer()
                        }
                        
                    } else if(checkInTimes.isEmpty) {
                        HStack{
                            Text("No check in times exist.\n" +
                                 "Click '+' if you would like to add one.")
                            Spacer()
                        }
                    } else {
                        HStack{
                            Text(getWeeklyRepeatMessage())
                            Spacer()
                        }
                        
                        Divider()
                        ForEach(checkInTimes) { checkInTime in
                            HStack{
                                if(editMode == EditMode.active) {
                                    Button(action: {checkInTime.isSelected = !checkInTime.isSelected}
                                           , label: {
                                        Image(systemName:  checkInTime.isSelected ? "checkmark.square" : "square")
                                            .imageScale(.large)
                                            .padding(.top , 1)
                                    })
                                    .foregroundColor(.black)
                                }
                                let isTooClose = checkInTime.isTooCloseToAnotherCheckInTime(
                                    checkInTimes: checkInTimes)
                                if(isTooClose) {
                                    Text("CHOOSE TIME:\n(Must be at least 10 mins apart.)").foregroundColor(.red)
                                } else {
                                    Text("Check In:")
                                }
                                DatePicker("", selection: Bindable(checkInTime).date, displayedComponents: .hourAndMinute)
                            }
                        }
                        
                        Divider()
                    }
                }
                .padding(.top,2)
                
                HStack{
                    Button(action: showBulkEditsAction) {
                        if(showBulkEditControls == false) {
                            Text("Bulk Edits")
                        } else {
                            Text("Done Bulk Editing")
                        }
                    }
                    .buttonStyle(.ghost)
                    .padding(.bottom, 8)
                    .disabled(showBulkEditControls == false &&
                              (config[0].enableCheckIns == false ||
                               checkInTimes.isEmpty))
                    Spacer()
                    if(showUndoBulkEditsButton) {
                        Button(action: undoAllBulkEditsAction) {
                            Text("(Undo Bulk Edits?)")
                        }
                        .buttonStyle(.ghost)
                        .padding(.bottom, 8)
                    }
                } // End: HStack
                
                if(showBulkEditControls) {
                    Section{
                        HStack{
                            Text("Shift All Check In Times By:")
                            Spacer()
                        }
                        HStack{
                            Picker(selection: $bulkShiftHours, label: Text(""))
                            {
                                ForEach(-23...23, id: \.self) { hours in
                                    Text("\(hours)")
                                }
                            }
                            Text("hours")
                            Picker(selection: $bulkShiftMinutes, label: Text(""))
                            {
                                ForEach(-59...59, id: \.self) { minutes in
                                    Text("\(minutes)")
                                }
                            }
                            Text("minutes")
                            Spacer()
                            Button(action: shiftAllCheckInsAction) {
                                Text("Shift All")
                            }
                            .buttonStyle(.ghost)
                            .disabled(checkInTimes.isEmpty)
                        } // End: HStack
                    } // End: Section
                }
                HStack{
                    Button(action: setWeeklyScheduleAction) {
                        if(showWeeklyEditControls == false) {
                            Text("Custom Weekdays")
                        } else {
                            Text("Done Choosing Weekdays")
                        }
                    }
                    .buttonStyle(.ghost)
                    .padding(.bottom, 8)
                    .disabled(showWeeklyEditControls == false &&
                              (config[0].enableCheckIns == false ||
                               checkInTimes.isEmpty))
                    Spacer()
                } // End: HStack
                
                if(showWeeklyEditControls) {
                    VStack {
                        HStack{
                            Text("Choose weekdays for your Check Ins.")
                            Spacer()
                        }
                        WeekdaySelectorView(shouldPreventEmptyList: true)
                            .padding(.top , 6)
                            .padding(.leading , 12)
                        Text(" ")
                    } // End: VStack
                    
                } // End: if(showWeeklyEditControls)
                
                HStack{
                    Button(action: usePauseControlsAction) {
                        if(showPauseControls == false) {
                            Text("Pause Check Ins")
                        } else {
                            Text("Done With Pause Controls")
                        }
                    }
                    .buttonStyle(.ghost)
                    .padding(.bottom, 8)
                    .disabled(showPauseControls == false &&
                              (config[0].enableCheckIns == false ||
                               checkInTimes.isEmpty))
                    Spacer()
                } // End: HStack
                
                if(showPauseControls) {
                    VStack (alignment: .leading) {
                        Divider()
                        HStack {
                            Button(action: {
                                pauseCheckInsUntil_HourOfDay(targetHour: 7) }) {
                                    Text(" Pause until 7am ")
                                }
                                .buttonStyle(.ghost)
                                .padding(.bottom, 8)
                            
                            Spacer()
                            Button(action: {
                                pauseCheckInsUntil_Days(daysToPause: 1) }) {
                                    Text(" Pause 1 day ")
                                }
                                .buttonStyle(.ghost)
                                .padding(.bottom, 8)
                        }
                        .padding(.top , 10)
                        
                        HStack {
                            Button(action: {
                                pauseCheckInsUntil_Days(daysToPause: 2) }) {
                                    Text(" Pause 2 days ")
                                }
                                .buttonStyle(.ghost)
                                .padding(.bottom, 8)
                            
                            Spacer()
                            Button(action: {
                                pauseCheckInsUntil_Days(daysToPause: 3) }) {
                                    Text(" Pause 3 days ")
                                }
                                .buttonStyle(.ghost)
                                .padding(.bottom, 8)
                        }
                        .padding(.top , 10)
                        
                        HStack {
                            Toggle(isOn: Bindable(config[0]).shouldPauseCheckIns) {
                                Text("Pause until a selected date and time.")
                            }
                            .onTapGesture(perform: {
                                if(useDevMode) {
                                    config[0].shouldPauseCheckIns.toggle()
                                }
                            })
                        }
                        .padding(.top , 15)
                        
                        if(config[0].shouldPauseCheckIns) {
                            HStack {
                                DatePicker(
                                    "",
                                    selection: Bindable( config[0]).dateTimeToResumeCheckInsAfterPause,
                                    in: getAllowedRangeForPausedCheckIns())
                                .labelsHidden()
                                Spacer()
                            }
                            PausedCheckInView()
                                .padding(.top, 6)
                        }
                        Text(" ")
                    } // End: VStack
                    
                } // End: if(showPauseControls)
                
                Text(" ")
                Text(" ")
            } // End: VStack (main one)
            .padding(.horizontal)
            .onAppear(perform : sortCheckInTimeList)
            .navigationTitle("Check In Settings")
            // Note: Binding the edit mode MUST be done near the end of the view
            // or it can make the red "delete circles" fail to appear when editing.
            // See: https://stackoverflow.com/questions/67256115
            .environment(\.editMode, $editMode)
        }
    }
    
    private func getAllowedRangeForPausedCheckIns() -> ClosedRange<Date>{
        var allowedDateRange: ClosedRange<Date> {
            let min = Date()
            let max = Calendar.current.date(byAdding: .day, value: (40), to: Date())!
            return min...max
        }
        return allowedDateRange
    }
    
    private func pauseCheckInsUntil_HourOfDay(targetHour : Int) {
        config[0].shouldPauseCheckIns = true
        let gregorianCalendar = Calendar(identifier: .gregorian)
        let nextHourComponents = DateComponents(hour: targetHour)
        let nextDateTime_MatchingHour = gregorianCalendar.nextDate(
            after: Date(), matching: nextHourComponents,
            matchingPolicy: .nextTime )!
        config[0].dateTimeToResumeCheckInsAfterPause =
        nextDateTime_MatchingHour
    }
    
    private func pauseCheckInsUntil_Days(daysToPause : Int) {
        config[0].shouldPauseCheckIns = true
        let gregorianCalendar = Calendar(identifier: .gregorian)
        var targetDateTime = gregorianCalendar.date(
            byAdding: .day, value: daysToPause, to: Date())!
        // Round date to nearest future hour.
        let components = gregorianCalendar.dateComponents(
            [.hour], from: targetDateTime)
        let hour = components.hour ?? 0
        let nextHourComponents = DateComponents(hour: (hour + 1))
        targetDateTime = gregorianCalendar.nextDate(
            after: targetDateTime, matching: nextHourComponents, matchingPolicy: .nextTime)!
        config[0].dateTimeToResumeCheckInsAfterPause = targetDateTime
    }
    
    private func usePauseControlsAction() {
        showPauseControls = !showPauseControls
    }
    
    private func getWeeklyRepeatMessage() -> String {
        let selectionsInstance : WeekdaySelections = config[0].weekdaysForCheckIns
        if(selectionsInstance.areAllDays_Selected()) {
            return "The Check Ins will repeat daily."
        }
        let selectionCount = selectionsInstance.getSelectedWeekdayCount()
        let selectedWeekdays = selectionsInstance.getAllSelectedWeekdays()
        if(selectionCount == 1) {
            return "The Check Ins will repeat every " +
            "\(selectedWeekdays[0])."
        }
        if(selectionCount == 2) {
            return "The Check Ins will repeat on " +
            "\(selectedWeekdays[0]) and \(selectedWeekdays[1])."
        }
        let weekdayEndpoints = selectionsInstance.getSingleMultidaySubsetEndpointsOrNil()
        if(weekdayEndpoints != nil) {
            return "The Check Ins will repeat " + "\(weekdayEndpoints!.firstWeekday)-" + "\(weekdayEndpoints!.lastWeekday)."
        }
        var messageWithList = "The Check Ins will repeat on:\n"
        let lastValidIndex = (selectedWeekdays.endIndex - 1)
        for index in 0..<selectedWeekdays.endIndex {
            let currentWeekday = selectedWeekdays[index]
            if(index != lastValidIndex) {
                messageWithList += "\(currentWeekday), "
            } else {
                messageWithList += "and \(currentWeekday)."
            }
        }
        return messageWithList
    } // End: getWeeklyRepeatMessage()
    
    private func undoAllBulkEditsAction() {
        let undoListCount = savedCheckIns_SecondsOfDayList_ForBulkUndo.count
        while(checkInTimes.count < undoListCount) {
            modelContext.insert(CheckInTime(date: Date()))
            modelContext.processPendingChanges()
        }
        while(checkInTimes.count > undoListCount) {
            modelContext.delete(checkInTimes[checkInTimes.endIndex - 1])
            modelContext.processPendingChanges()
        }
        for index in savedCheckIns_SecondsOfDayList_ForBulkUndo.indices {
            let secondsOfDayForUndo = savedCheckIns_SecondsOfDayList_ForBulkUndo[index]
            let localTimeForUndo = LocalTime.from(secondsOfDay: secondsOfDayForUndo)
            checkInTimes[index].setTime(time: localTimeForUndo)
            checkInTimes[index].clearSelection()
        }
        showUndoBulkEditsButton = false
    }
    
    private func getEarliestCheckInTime_OrNil() -> CheckInTime? {
        var earliestCheckInTime_OrNil : CheckInTime? = nil
        for currentCheckInTime in checkInTimes {
            if(earliestCheckInTime_OrNil == nil) {
                earliestCheckInTime_OrNil = currentCheckInTime
                continue
            }
            if(currentCheckInTime < earliestCheckInTime_OrNil!) {
                earliestCheckInTime_OrNil = currentCheckInTime
            }
        }
        return earliestCheckInTime_OrNil
    }
    
    private func getLatestCheckInTime_OrNil() -> CheckInTime? {
        var latestCheckInTime_OrNil : CheckInTime? = nil
        for currentCheckInTime in checkInTimes {
            if(latestCheckInTime_OrNil == nil) {
                latestCheckInTime_OrNil = currentCheckInTime
                continue
            }
            if(currentCheckInTime > latestCheckInTime_OrNil!) {
                latestCheckInTime_OrNil = currentCheckInTime
            }
        }
        return latestCheckInTime_OrNil
    }
    
    private func setWeeklyScheduleAction() {
        showWeeklyEditControls = !showWeeklyEditControls
    }
    
    private func showBulkEditsAction() {
        showBulkEditControls = !showBulkEditControls
        showUndoBulkEditsButton = false
        bulkShiftHours = 0
        bulkShiftMinutes = 0
        if(showBulkEditControls) {
            // Clear and save the bulk undo data, for possible future use.
            savedCheckIns_SecondsOfDayList_ForBulkUndo.removeAll()
            checkInTimes.forEach{ checkInTime in
                savedCheckIns_SecondsOfDayList_ForBulkUndo.append(
                    checkInTime.getTime().getSecondsOfDay())
            }
        }
    }
    
    private func shiftAllCheckInsAction() {
        if(checkInTimes.isEmpty) {
            return
        }
        if(bulkShiftHours == 0 && bulkShiftMinutes == 0) {
            return
        }
        checkInTimes.forEach{ checkInTime in
            checkInTime.shiftTime(
                shiftHours: bulkShiftHours, shiftMinutes: bulkShiftMinutes)
        }
        showUndoBulkEditsButton = true
    }
    
    private func addCheckInTime() {
        if(checkInTimes.count >= maximumCheckInsPerDay) {
            showCheckInLimitReachedAlert = true
            return
        }
        var newCheckInTime : CheckInTime
        if(checkInTimes.isEmpty) {
            newCheckInTime = CheckInTime(hour:13) // 13 is 1pm.
        } else {
            let latestCheckInTime : CheckInTime = getLatestCheckInTime_OrNil()!
            newCheckInTime = CheckInTime(checkInTime_AsTimeSource: latestCheckInTime)
            if(latestCheckInTime.getTime().hour < 17) { // 17 is 5pm.
                newCheckInTime.shiftTime(shiftHours: 1, shiftMinutes: 0)
            } else {
                newCheckInTime.shiftTime(shiftHours: 0, shiftMinutes: 1)
            }
        }
        // Note: Since this is a new check in time, we won't need to clear the selection value.
        modelContext.insert(newCheckInTime)
    }
    
    private func deleteAllCheckIns() {
        for index in checkInTimes.indices {
            modelContext.delete(checkInTimes[index])
        }
    }
    
    private func deleteSelectedCheckInsAction() {
        for index in checkInTimes.indices {
            if(checkInTimes[index].isSelected){
                modelContext.delete(checkInTimes[index])
            }
        }
        editMode = EditMode.inactive
    }
    
    private func deleteCheckInTime(allIndexesToDelete: IndexSet) {
        for index in allIndexesToDelete {
            modelContext.delete(checkInTimes[index])
        }
    }
    
    private func sortCheckInTimeList() {
        var savedCheckIns_SecondsInDayList : [Int] = []
        checkInTimes.forEach{ checkInTime in
            savedCheckIns_SecondsInDayList.append(
                checkInTime.getTime().getSecondsOfDay())
        }
        savedCheckIns_SecondsInDayList.sort()
        for index in checkInTimes.indices {
            let savedLocalTime = LocalTime.from(secondsOfDay: savedCheckIns_SecondsInDayList[index])
            checkInTimes[index].setTime(time: savedLocalTime)
            checkInTimes[index].clearSelection()
        }
    }
    
    private func areCheckInTimesOutOfOrder() -> Bool {
        var previousSecondsOfDay : Int = -1
        for checkInTime in checkInTimes {
            let currentSecondsOfDay =
            checkInTime.getTime().getSecondsOfDay()
            if(previousSecondsOfDay > currentSecondsOfDay) {
                return true
            }
            previousSecondsOfDay = currentSecondsOfDay
        }
        return false
    }
    
}



#Preview {
    return NavigationStack {
        CheckInSettingsView()
    }
    .modelContainer(ModelContainerProvider.getContainer(
        useMemoryOnlyData: true))
}
