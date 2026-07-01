import AppKit
import SwiftUI

final class AboutWindowController: NSWindowController, NSWindowDelegate {
    static let shared = AboutWindowController()

    private convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 280),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Über Snipping Tool"
        window.isReleasedWhenClosed = false
        window.center()
        self.init(window: window)
        window.delegate = self
    }

    func show() {
        window?.contentView = NSHostingView(rootView: AboutView())
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        let otherVisible = NSApplication.shared.windows.filter { $0.isVisible && $0 != window }
        if otherVisible.isEmpty {
            NSApplication.shared.setActivationPolicy(.accessory)
        }
    }
}

struct AboutView: View {
    private let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    private let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"

    var body: some View {
        VStack(spacing: 16) {
            if let appIcon = NSImage(named: NSImage.applicationIconName) {
                Image(nsImage: appIcon)
                    .resizable()
                    .frame(width: 80, height: 80)
            }

            Text("Snipping Tool")
                .font(.title.bold())

            Text("Version \(version) (\(build))")
                .foregroundStyle(.secondary)
                .font(.callout)

            Text("Freeware")
                .font(.callout)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(.quaternary)
                .clipShape(Capsule())

            VStack(spacing: 4) {
                Text("Marco Wende — Wende.IT")
                    .font(.body)

                Link("wende.it", destination: URL(string: "https://wende.it")!)
                    .font(.body)
            }
        }
        .padding(30)
        .frame(width: 320, height: 280)
    }
}
