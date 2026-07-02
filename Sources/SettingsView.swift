import AppKit
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Form {
            Section("Allgemein") {
                Toggle("Mit dem System starten", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            launchAtLogin = SMAppService.mainApp.status == .enabled
                        }
                    }
            }

            Section("Nach der Aufnahme") {
                Picker("Aktion:", selection: $coordinator.outputAction) {
                    ForEach(OutputAction.allCases) { action in
                        Text(action.label).tag(action)
                    }
                }
                .pickerStyle(.radioGroup)

                Picker("Format:", selection: $coordinator.imageFormat) {
                    ForEach(ImageFormat.allCases) { format in
                        Text(format.label).tag(format)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 160)

                HStack {
                    Text("Speicherort:")
                    Text(coordinator.saveFolder.path)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Button("Ändern…") { chooseFolder() }
                }
            }

            Section("Tastenkürzel") {
                HotKeyRecorderView(title: "Ganzer Bildschirm", combo: $coordinator.hotKeyFullScreen)
                HotKeyRecorderView(title: "Fenster", combo: $coordinator.hotKeyWindow)
                HotKeyRecorderView(title: "Bereich auswählen", combo: $coordinator.hotKeyRegion)
            }
        }
        .padding(20)
        .frame(width: 440)
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = coordinator.saveFolder
        panel.prompt = "Auswählen"

        if panel.runModal() == .OK, let url = panel.url {
            coordinator.saveFolder = url
        }
    }
}
