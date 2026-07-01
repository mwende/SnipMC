import AppKit

/// MenuBarExtra-only apps (no WindowGroup) don't reliably receive SwiftUI's
/// `.onOpenURL` scene events — SwiftUI logs "Cannot use Scene methods for
/// URL... without using SwiftUI Lifecycle" and the handler never fires.
/// The classic AppKit delegate callback works regardless, so URL scheme
/// triggers (from Logitech Options, Shortcuts, Stream Deck, `open`, …) are
/// routed through here instead.
final class AppDelegate: NSObject, NSApplicationDelegate {
    let coordinator = AppCoordinator()

    func application(_ application: NSApplication, open urls: [URL]) {
        urls.forEach { coordinator.handle(url: $0) }
    }
}
