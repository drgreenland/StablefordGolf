import SwiftUI

@main
struct StablefordGolfApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(DataManager.shared)
        }
    }
}
