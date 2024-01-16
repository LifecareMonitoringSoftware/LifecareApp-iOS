

import SwiftUI
import SwiftData

struct PausedCheckInView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var config: [Settings]
    let showForPreview : Bool
    
    init(showForPreview : Bool = false) {
        self.showForPreview = showForPreview
    }
    
    var body: some View {
        if(showForPreview ||
           (config[0].enableCheckIns && config[0].shouldPauseCheckIns)) {
            Text(getPausedCheckInMessage())
        }
    }
    
    
    private func getPausedCheckInMessage() -> String {
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "MMM d"
        let timeFormat = DateFormatter()
        timeFormat.dateFormat = "h:mm a"
        let resumeDatePortion = dateFormat.string(from: config[0].dateTimeToResumeCheckInsAfterPause)
        let resumeTime = timeFormat.string(from: config[0].dateTimeToResumeCheckInsAfterPause).lowercased()
        return "PAUSED until: " + resumeDatePortion + ", " +
        resumeTime + "."
    }
}



#Preview {
    PausedCheckInView(showForPreview: true)
        .modelContainer(ModelContainerProvider.getContainer(
            useMemoryOnlyData: true))
}
