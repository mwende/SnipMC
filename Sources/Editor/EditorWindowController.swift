import AppKit
import SwiftUI

private final class FlippedContainerView: NSView {
    override var isFlipped: Bool { true }
}

final class EditorWindowController: NSWindowController, NSWindowDelegate {

    private let annotationDoc = AnnotationDocument()
    private let baseImage: NSImage
    private let sourceURL: URL?
    private let completion: (NSImage?) -> Void
    private let canvasView = AnnotationCanvasView()

    init(image: NSImage, sourceURL: URL?, completion: @escaping (NSImage?) -> Void) {
        self.baseImage = image
        self.sourceURL = sourceURL
        self.completion = completion

        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
        let maxWidth = screenFrame.width * 0.8
        let maxHeight = screenFrame.height * 0.8
        let scale = min(maxWidth / image.size.width, maxHeight / image.size.height, 1.0)
        let windowWidth = max(image.size.width * scale, 600)
        let windowHeight = max(image.size.height * scale, 400) + 52

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Bildeditor"
        window.isReleasedWhenClosed = false
        window.center()
        window.minSize = NSSize(width: 500, height: 400)

        super.init(window: window)
        window.delegate = self

        canvasView.baseImage = image
        canvasView.document = annotationDoc
        canvasView.onDocumentChanged = { [weak self] in
            self?.canvasView.needsDisplay = true
        }

        let toolbarHosting = NSHostingView(rootView: EditorToolbarView(
            document: annotationDoc,
            onSave: { [weak self] in self?.save() },
            onCopyToClipboard: { [weak self] in self?.copyToClipboard() },
            onCancel: { [weak self] in self?.cancel() }
        ))
        toolbarHosting.translatesAutoresizingMaskIntoConstraints = false
        canvasView.translatesAutoresizingMaskIntoConstraints = false

        let container = FlippedContainerView()
        container.addSubview(toolbarHosting)
        container.addSubview(canvasView)
        window.contentView = container

        NSLayoutConstraint.activate([
            toolbarHosting.topAnchor.constraint(equalTo: container.topAnchor),
            toolbarHosting.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            toolbarHosting.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            toolbarHosting.heightAnchor.constraint(equalToConstant: 52),

            canvasView.topAnchor.constraint(equalTo: toolbarHosting.bottomAnchor),
            canvasView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            canvasView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            canvasView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func showEditor() {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
        window?.makeFirstResponder(canvasView)
    }

    // MARK: - Actions

    private func renderFinal() -> NSImage {
        AnnotationRenderer.render(annotations: annotationDoc.items, onto: baseImage)
    }

    private func save() {
        let image = renderFinal()
        completion(image)
        close()
    }

    private func copyToClipboard() {
        let image = renderFinal()
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
        close()
    }

    private func cancel() {
        completion(nil)
        close()
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        let visibleWindows = NSApplication.shared.windows.filter { $0.isVisible && $0 != window }
        if visibleWindows.isEmpty {
            NSApplication.shared.setActivationPolicy(.accessory)
        }
    }
}
