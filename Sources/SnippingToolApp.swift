import SwiftUI

@main
struct SnippingToolApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Snipping Tool", systemImage: "camera.viewfinder") {
            MenuBarContentView()
                .environmentObject(appDelegate.coordinator)
        }
        .menuBarExtraStyle(.menu)
    }
}
