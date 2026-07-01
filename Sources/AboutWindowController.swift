import AppKit
import SwiftUI

final class AboutWindowController: NSWindowController, NSWindowDelegate {
    static let shared = AboutWindowController()

    private convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 520),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "SnipMC"
        window.isReleasedWhenClosed = false
        window.center()
        self.init(window: window)
        window.delegate = self
    }

    func show() {
        window?.contentView = NSHostingView(rootView: AboutAndHelpView())
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

struct AboutAndHelpView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            AboutTab()
                .tabItem { Label("Info", systemImage: "info.circle") }
                .tag(0)
            HelpTab()
                .tabItem { Label("Dokumentation", systemImage: "book") }
                .tag(1)
        }
        .frame(width: 480, height: 500)
    }
}

struct AboutTab: View {
    private let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    private let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            if let appIcon = NSImage(named: NSImage.applicationIconName) {
                Image(nsImage: appIcon)
                    .resizable()
                    .frame(width: 80, height: 80)
            }

            Text("SnipMC")
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
                Text("Marco Wende \u{2014} Wende.IT")
                    .font(.body)
                Link("wende.it", destination: URL(string: "https://wende.it")!)
                    .font(.body)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct HelpTab: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                helpSection("Aufnahme-Modi") {
                    helpRow("Ganzer Bildschirm", "Nimmt den gesamten Bildschirm auf")
                    helpRow("Fenster", "Klicke auf ein Fenster, um es aufzunehmen")
                    helpRow("Bereich", "Ziehe einen Rahmen um den gew\u{00fc}nschten Bereich")
                }

                helpSection("Bildeditor") {
                    helpRow("Pfeil", "Linie mit Pfeilspitze zeichnen")
                    helpRow("Rechteck", "Rahmen um einen Bereich zeichnen")
                    helpRow("Ellipse", "Kreis oder Oval zeichnen")
                    helpRow("Text", "Klicke auf eine Stelle und tippe Text ein")
                    helpRow("\u{2318}Z / \u{2318}\u{21e7}Z", "R\u{00fc}ckg\u{00e4}ngig / Wiederholen")
                    helpRow("\u{232b} / Entf", "Ausgew\u{00e4}hlte Annotation l\u{00f6}schen")
                }

                helpSection("URL-Schema") {
                    Text("Zum Ausl\u{00f6}sen per Logitech Options+, Kurzb efehle, Stream Deck o.\u{202f}\u{00e4}.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 4)
                    urlRow("snipmc://fullscreen", "Vollbild-Screenshot")
                    urlRow("snipmc://window", "Fenster-Screenshot")
                    urlRow("snipmc://region", "Bereich-Screenshot")
                    urlRow("snipmc://region?edit=true", "Bereich + Editor")
                    urlRow("snipmc://fullscreen?edit=true", "Vollbild + Editor")
                    urlRow("snipmc://edit", "Bild aus Datei bearbeiten")
                    urlRow("snipmc://editlast", "Letzten Screenshot bearbeiten")
                    urlRow("snipmc://clipboard", "Zwischenablage bearbeiten")
                }

                helpSection("Einrichtung in Logitech Options+") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("1. Logi Options+ \u{00f6}ffnen und Ger\u{00e4}t w\u{00e4}hlen")
                        Text("2. Taste zuweisen: Aktion = URL \u{00f6}ffnen")
                        Text("3. URL eintragen, z.\u{202f}B.:")
                        Text("   snipmc://region?edit=true")
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    .font(.callout)
                }

                helpSection("Hinweise") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\u{2022} Berechtigung Bildschirmaufnahme erforderlich (Systemeinstellungen \u{2192} Datenschutz & Sicherheit)")
                        Text("\u{2022} Speicherort: ~/Bilder/Screenshots (\u{00e4}nderbar in Einstellungen)")
                        Text("\u{2022} Tastenk\u{00fc}rzel frei konfigurierbar in den Einstellungen")
                    }
                    .font(.callout)
                }
            }
            .padding(20)
        }
    }

    private func helpSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            content()
        }
    }

    private func helpRow(_ label: String, _ description: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .fontWeight(.medium)
                .frame(width: 120, alignment: .leading)
            Text(description)
                .foregroundStyle(.secondary)
        }
        .font(.callout)
    }

    private func urlRow(_ url: String, _ description: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(url)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .frame(width: 260, alignment: .leading)
            Text(description)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}
