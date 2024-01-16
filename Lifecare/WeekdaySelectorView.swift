

import SwiftUI
import SwiftData

struct WeekdaySelectorView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query private var config: [Settings]
    @State private var showEmptyListMessage : Bool = false
    private let shouldPreventEmptyList : Bool
    private let emptyListInstructionMessage : String
    
    init(shouldPreventEmptyList : Bool, 
         emptyListInstructionMessage : String =
         "The custom weekdays list cannot be empty.") {
        self.shouldPreventEmptyList = shouldPreventEmptyList
        self.emptyListInstructionMessage = emptyListInstructionMessage
    }
    
    var body: some View {
        HStack{
            VStack(alignment: .leading, spacing: 15){
                ForEach(0..<7) { index in
                    
                    Button(action: {weekdayCheckBoxAction(index: index)},
                           label: {
                        Image(systemName:  config[0].weekdaysForCheckIns.isWeekdaySelected(
                            weekday: Weekday(rawValue: index)!) ? "checkmark.square" : "square")
                        .imageScale(.large)
                            .padding(.leading, -1)
                            .padding(.trailing, -10)
                                 
                        Text(Weekday(rawValue: index)!
                            .threeLetterDescription +  "  ")
                        
                        }) // End: Button
                        .foregroundColor(.black)
                        .padding(.zero)
                }
            }
            Spacer()
            if(showEmptyListMessage) {
                Text(emptyListInstructionMessage)
                    .padding(5)
                    .overlay(RoundedRectangle(cornerRadius: 4)
                        .stroke(.red, lineWidth: 2))
            }
        }
        
        
    }
    
    func weekdayCheckBoxAction(index : Int) -> Void {
        let weekdayName = Weekday(rawValue: index)!
        let previousState : Bool =
        config[0].weekdaysForCheckIns.isWeekdaySelected(weekday: weekdayName)
        let previousSelectionCount : Int =
        config[0].weekdaysForCheckIns.getSelectedWeekdayCount()
        if(shouldPreventEmptyList && previousSelectionCount <= 1 &&
           previousState == true
           ) {
            showEmptyListMessage = true
            return
        }
        config[0].weekdaysForCheckIns.setSelected(weekday: weekdayName, selection: (!previousState))
        showEmptyListMessage = false
    }
    
}

#Preview {
    WeekdaySelectorView(shouldPreventEmptyList: true)
        .modelContainer(ModelContainerProvider.getContainer(
            useMemoryOnlyData: true))
}
