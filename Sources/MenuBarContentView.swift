import AppKit
import SwiftUI

struct MenuBarContentView: View {
    @EnvironmentObject var coordinator: AppCoordinator

    var body: some View {
        Button("Ganzer Bildschirm") { coordinator.capture(mode: .fullScreen) }
        Button("Fenster") { coordinator.capture(mode: .window) }
        Button("Bereich auswählen") { coordinator.capture(mode: .region) }

        Divider()

        Button("Letzte Aufnahme bearbeiten…") {
            coordinator.openEditorForLastCapture()
        }
        .disabled(coordinator.lastCapturedURL == nil)

        Button("Bild bearbeiten…") {
            coordinator.openEditorForFile()
        }

        Divider()

        Button("Einstellungen…") {
            SettingsWindowController.shared.show(coordinator: coordinator)
        }
        .keyboardShortcut(",")

        Divider()

        Button("Beenden") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
