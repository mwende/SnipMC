import AppKit
import SwiftUI

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
        let windowHeight = max(image.size.height * scale, 400) + 52 // toolbar height

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
        canvasView.autoresizingMask = [.width, .height]

        let toolbarHosting = NSHostingView(rootView: EditorToolbarView(
            document: annotationDoc,
            onSave: { [weak self] in self?.save() },
            onCopyToClipboard: { [weak self] in self?.copyToClipboard() },
            onCancel: { [weak self] in self?.cancel() }
        ))
        toolbarHosting.translatesAutoresizingMaskIntoConstraints = true

        let container = NSView(frame: window.contentRect(forFrameRect: window.frame))
        container.autoresizingMask = [.width, .height]

        toolbarHosting.frame = NSRect(x: 0, y: container.bounds.height - 52,
                                       width: container.bounds.width, height: 52)
        toolbarHosting.autoresizingMask = [.width, .minYMargin]

        canvasView.frame = NSRect(x: 0, y: 0,
                                   width: container.bounds.width,
                                   height: container.bounds.height - 52)
        canvasView.autoresizingMask = [.width, .height]

        container.addSubview(toolbarHosting)
        container.addSubview(canvasView)
        window.contentView = container
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
