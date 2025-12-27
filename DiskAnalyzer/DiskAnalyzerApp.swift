import SwiftUI

@main
struct DiskAnalyzerApp: App {
    var body: some Scene {
        WindowGroup {
            MainWindow()
        }
        .windowStyle(.automatic)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
