import SwiftUI

@main
struct SnippingToolApp: App {
    @StateObject private var coordinator = AppCoordinator()

    var body: some Scene {
        MenuBarExtra("Snipping Tool", systemImage: "camera.viewfinder") {
            MenuBarContentView()
                .environmentObject(coordinator)
        }
        .menuBarExtraStyle(.menu)
    }
}
