import SwiftUI

struct EditorToolbarView: View {
    @Bindable var document: AnnotationDocument
    var onSave: () -> Void
    var onCopyToClipboard: () -> Void
    var onCancel: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            toolButtons
            Divider().frame(height: 24)
            colorPicker
            lineWidthPicker
            Divider().frame(height: 24)
            undoRedoButtons
            Spacer()
            actionButtons
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private var toolButtons: some View {
        HStack(spacing: 4) {
            toolButton(.arrow, icon: "arrow.up.right", label: "Pfeil")
            toolButton(.rectangle, icon: "rectangle", label: "Rechteck")
            toolButton(.ellipse, icon: "circle", label: "Ellipse")
            toolButton(.text, icon: "textformat", label: "Text")
        }
    }

    private func toolButton(_ kind: AnnotationKind, icon: String, label: String) -> some View {
        Button {
            document.currentTool = kind
        } label: {
            Image(systemName: icon)
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.bordered)
        .tint(document.currentTool == kind ? .accentColor : nil)
        .help(label)
    }

    private var colorPicker: some View {
        HStack(spacing: 4) {
            ForEach(presetColors, id: \.self) { color in
                Circle()
                    .fill(Color(nsColor: color))
                    .frame(width: 20, height: 20)
                    .overlay {
                        if document.currentColor == color {
                            Circle().strokeBorder(.white, lineWidth: 2)
                        }
                    }
                    .shadow(radius: document.currentColor == color ? 2 : 0)
                    .onTapGesture { document.currentColor = color }
            }

            ColorPicker("", selection: Binding(
                get: { Color(nsColor: document.currentColor) },
                set: { document.currentColor = NSColor($0) }
            ))
            .labelsHidden()
            .frame(width: 28)
        }
    }

    private var presetColors: [NSColor] {
        [.systemRed, .systemBlue, .systemGreen, .systemYellow, .black, .white]
    }

    private var lineWidthPicker: some View {
        Picker("", selection: $document.currentLineWidth) {
            Text("Dünn").tag(CGFloat(2))
            Text("Mittel").tag(CGFloat(3))
            Text("Dick").tag(CGFloat(5))
        }
        .pickerStyle(.segmented)
        .frame(width: 160)
        .labelsHidden()
    }

    private var undoRedoButtons: some View {
        HStack(spacing: 4) {
            Button {
                document.undo()
            } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            .disabled(!document.canUndo)
            .help("Widerrufen (⌘Z)")

            Button {
                document.redo()
            } label: {
                Image(systemName: "arrow.uturn.forward")
            }
            .disabled(!document.canRedo)
            .help("Wiederholen (⌘⇧Z)")
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 8) {
            Button("Abbrechen", role: .cancel) { onCancel() }
                .keyboardShortcut(.escape)
            Button("In Zwischenablage") { onCopyToClipboard() }
            Button("Speichern") { onSave() }
                .keyboardShortcut("s")
                .buttonStyle(.borderedProminent)
        }
    }
}
