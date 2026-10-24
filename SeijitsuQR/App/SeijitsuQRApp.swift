import OSLog
import SwiftData
import SwiftUI

@main
struct SeijitsuQRApp: App {
    private let modelContainer: ModelContainer
    @State private var settings = AppSettings()

    init() {
        do {
            modelContainer = try HistoryContainer.make()
        } catch {
            // Never delete or overwrite the user's store. Run without saving this session instead.
            Logger(subsystem: "SeijitsuQR", category: "App").fault("Failed to open the history store: \(error.localizedDescription, privacy: .public)")
            do {
                modelContainer = try HistoryContainer.make(inMemory: true)
            } catch {
                fatalError("Failed to create an in-memory store: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
        }
        .modelContainer(modelContainer)
    }
}
