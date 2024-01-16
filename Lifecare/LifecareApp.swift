

import SwiftUI
import SwiftData

let shouldForceResetAllStoredData = false
let alwaysUseMemoryOnlyData = false

@MainActor
struct ModelContainerProvider {
    
    static func getContainer(useMemoryOnlyData : Bool = true) -> ModelContainer {
        let schema = Schema([
            CheckInTime.self,
            Settings.self
        ])
        let useMemoryOnlyDataFinal = (useMemoryOnlyData || alwaysUseMemoryOnlyData)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: useMemoryOnlyDataFinal)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Make sure the persistent store has settings. If so, return the existing container.
            var fetchDescriptor = FetchDescriptor<Settings>()
            fetchDescriptor.fetchLimit = 1
            let settingsCount = try container.mainContext.fetch(fetchDescriptor).count
            
            if(settingsCount >= 1 && !shouldForceResetAllStoredData)  {
                // Data exists and a reset has not been requested.
                // So return the existing data.
                return container
            }
            
            // We need new data. Delete any data that exists and insert needed default data instances.
            try container.mainContext.delete(model: CheckInTime.self)
            try container.mainContext.delete(model: Settings.self)
            container.mainContext.processPendingChanges()
            
            // Insert a singleton settings instance with default values.
            let settings = Settings()
            container.mainContext.insert(settings)
            
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
}

@main
struct LifecareApp: App {
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                CheckInSettingsView()
            }
        }
        .modelContainer(ModelContainerProvider.getContainer(useMemoryOnlyData: false))
    }
    
    init() {
        test()
    }
}


func test() {
    
}
