import SwiftUI

@main
struct SnipMCApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("SnipMC", systemImage: "camera.viewfinder") {
            MenuBarContentView()
                .environmentObject(appDelegate.coordinator)
        }
        .menuBarExtraStyle(.menu)
    }
}
