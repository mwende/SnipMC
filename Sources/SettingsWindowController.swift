import AppKit
import SwiftUI

/// Manages the settings window manually instead of relying on SwiftUI's
/// `Settings` scene, which is unreliable for LSUIElement (menu bar-only,
/// no dock icon) apps: there's no existing window for the app to focus,
/// so the scene sometimes never becomes key.
final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    static let shared = SettingsWindowController()

    private convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 420),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Einstellungen"
        window.isReleasedWhenClosed = false
        window.center()
        self.init(window: window)
        window.delegate = self
    }

    func show(coordinator: AppCoordinator) {
        window?.contentView = NSHostingView(
            rootView: SettingsView().environmentObject(coordinator)
        )
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        // Menu bar-only apps should not keep a Dock icon after the window closes.
        NSApplication.shared.setActivationPolicy(.accessory)
    }
}
