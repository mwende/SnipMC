import AppKit
import Foundation

final class AnnotationCanvasView: NSView {

    var baseImage: NSImage? { didSet { needsDisplay = true } }
    var document: AnnotationDocument? { didSet { needsDisplay = true } }
    var onDocumentChanged: (() -> Void)?

    private enum Interaction {
        case idle
        case creating(AnnotationKind, startPoint: CGPoint)
        case dragging(UUID, lastPoint: CGPoint)
    }

    private var interaction: Interaction = .idle
    private var inProgressItem: AnnotationItem?
    private var textField: NSTextField?

    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }

    // MARK: - Coordinate transform

    private var imageRect: CGRect {
        guard let image = baseImage else { return bounds }
        let imageSize = image.size
        let scale = min(bounds.width / imageSize.width, bounds.height / imageSize.height)
        let scaledSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        return CGRect(
            x: (bounds.width - scaledSize.width) / 2,
            y: (bounds.height - scaledSize.height) / 2,
            width: scaledSize.width,
            height: scaledSize.height
        )
    }

    private var viewToImageScale: CGFloat {
        guard let image = baseImage else { return 1 }
        return image.size.width / imageRect.width
    }

    private func viewToImage(_ point: CGPoint) -> CGPoint {
        let rect = imageRect
        let scale = viewToImageScale
        return CGPoint(
            x: (point.x - rect.origin.x) * scale,
            y: (point.y - rect.origin.y) * scale
        )
    }

    private func imageToView(_ point: CGPoint) -> CGPoint {
        let rect = imageRect
        let scale = viewToImageScale
        return CGPoint(
            x: point.x / scale + rect.origin.x,
            y: point.y / scale + rect.origin.y
        )
    }

    private func imageRectToView(_ r: CGRect) -> CGRect {
        let origin = imageToView(r.origin)
        let scale = viewToImageScale
        return CGRect(x: origin.x, y: origin.y,
                      width: r.width / scale, height: r.height / scale)
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        let bgColor: CGColor = NSColor.windowBackgroundColor.cgColor
        context.setFillColor(bgColor)
        context.fill(bounds)

        guard let image = baseImage else { return }

        let imgRect = imageRect
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: imgRect, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)

        context.saveGState()
        context.translateBy(x: imgRect.origin.x, y: imgRect.origin.y)
        let scale = 1.0 / viewToImageScale
        context.scaleBy(x: scale, y: scale)

        guard let doc = document else {
            context.restoreGState()
            return
        }

        for item in doc.items {
            AnnotationRenderer.draw(item, in: context)

            if item.id == doc.selectedItemID {
                drawSelectionIndicator(for: item, in: context)
            }
        }

        if let inProgress = inProgressItem {
            AnnotationRenderer.draw(inProgress, in: context)
        }

        context.restoreGState()
    }

    private func drawSelectionIndicator(for item: AnnotationItem, in context: CGContext) {
        let handleRect: CGRect
        if item.kind == .arrow {
            let start = item.rect.origin
            let end = CGPoint(x: item.rect.origin.x + item.rect.size.width,
                              y: item.rect.origin.y + item.rect.size.height)
            handleRect = CGRect(x: min(start.x, end.x), y: min(start.y, end.y),
                                width: abs(end.x - start.x), height: abs(end.y - start.y))
        } else if item.kind == .text {
            guard let text = item.text, !text.isEmpty else { return }
            let font = NSFont.systemFont(ofSize: item.fontSize, weight: .semibold)
            let size = (text as NSString).size(withAttributes: [.font: font])
            handleRect = CGRect(origin: item.rect.origin, size: size)
        } else {
            handleRect = item.rect
        }

        context.saveGState()
        let dashPattern: [CGFloat] = [6, 4]
        context.setLineDash(phase: 0, lengths: dashPattern)
        context.setStrokeColor(NSColor.controlAccentColor.cgColor)
        context.setLineWidth(1.5)
        context.stroke(handleRect.insetBy(dx: -4, dy: -4))
        context.restoreGState()
    }

    // MARK: - Mouse events

    override func mouseDown(with event: NSEvent) {
        commitTextField()
        window?.makeFirstResponder(self)

        let viewPoint = convert(event.locationInWindow, from: nil)
        let imgPoint = viewToImage(viewPoint)
        guard let doc = document else { return }

        // Hit-test existing items (reverse order = topmost first)
        for item in doc.items.reversed() {
            if AnnotationRenderer.hitTest(point: imgPoint, item: item) {
                doc.selectedItemID = item.id
                interaction = .dragging(item.id, lastPoint: imgPoint)
                needsDisplay = true
                return
            }
        }

        doc.selectedItemID = nil
        interaction = .creating(doc.currentTool, startPoint: imgPoint)
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        let viewPoint = convert(event.locationInWindow, from: nil)
        let imgPoint = viewToImage(viewPoint)
        guard let doc = document else { return }

        switch interaction {
        case .creating(let kind, let start):
            if kind == .text { return }
            let rect = CGRect(x: start.x, y: start.y,
                              width: imgPoint.x - start.x,
                              height: imgPoint.y - start.y)
            inProgressItem = AnnotationItem(
                kind: kind,
                rect: rect,
                color: doc.currentColor,
                lineWidth: doc.currentLineWidth
            )
            needsDisplay = true

        case .dragging(let id, let lastPoint):
            let delta = CGSize(width: imgPoint.x - lastPoint.x,
                               height: imgPoint.y - lastPoint.y)
            doc.moveSelected(by: delta)
            interaction = .dragging(id, lastPoint: imgPoint)
            needsDisplay = true

        case .idle:
            break
        }
    }

    override func mouseUp(with event: NSEvent) {
        let viewPoint = convert(event.locationInWindow, from: nil)
        let imgPoint = viewToImage(viewPoint)
        guard let doc = document else { return }

        switch interaction {
        case .creating(let kind, let start):
            if kind == .text {
                showTextField(at: viewPoint, imagePoint: imgPoint)
            } else if let item = inProgressItem {
                let dx = abs(item.rect.width)
                let dy = abs(item.rect.height)
                if dx > 4 || dy > 4 {
                    let normalized = normalizedRect(from: start, to: imgPoint, kind: kind)
                    var finalItem = item
                    finalItem.rect = normalized
                    doc.addItem(finalItem)
                    onDocumentChanged?()
                }
            }
            inProgressItem = nil

        case .dragging(_, _):
            doc.pushUndo()
            onDocumentChanged?()

        case .idle:
            break
        }

        interaction = .idle
        needsDisplay = true
    }

    private func normalizedRect(from start: CGPoint, to end: CGPoint, kind: AnnotationKind) -> CGRect {
        if kind == .arrow {
            return CGRect(x: start.x, y: start.y,
                          width: end.x - start.x, height: end.y - start.y)
        }
        return CGRect(
            x: min(start.x, end.x), y: min(start.y, end.y),
            width: abs(end.x - start.x), height: abs(end.y - start.y)
        )
    }

    // MARK: - Text editing

    private func showTextField(at viewPoint: CGPoint, imagePoint: CGPoint) {
        let field = NSTextField(frame: NSRect(x: viewPoint.x, y: viewPoint.y, width: 200, height: 30))
        field.font = .systemFont(ofSize: 16, weight: .semibold)
        field.textColor = document?.currentColor ?? .systemRed
        field.backgroundColor = .white.withAlphaComponent(0.9)
        field.isBordered = true
        field.focusRingType = .exterior
        field.placeholderString = "Text eingeben…"
        field.target = self
        field.action = #selector(textFieldCommitted(_:))
        field.tag = Int(imagePoint.x) // store image coordinates in tag
        addSubview(field)
        window?.makeFirstResponder(field)

        // Store image Y in field's identifier
        field.identifier = NSUserInterfaceItemIdentifier("\(imagePoint.x),\(imagePoint.y)")
        textField = field
    }

    @objc private func textFieldCommitted(_ sender: NSTextField) {
        commitTextField()
    }

    private func commitTextField() {
        guard let field = textField, let doc = document else { return }
        let text = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)

        if !text.isEmpty, let identifier = field.identifier?.rawValue {
            let parts = identifier.split(separator: ",")
            if parts.count == 2,
               let x = Double(parts[0]),
               let y = Double(parts[1]) {
                let item = AnnotationItem(
                    kind: .text,
                    rect: CGRect(x: x, y: y, width: 0, height: 0),
                    color: doc.currentColor,
                    lineWidth: doc.currentLineWidth,
                    text: text,
                    fontSize: 24 * viewToImageScale
                )
                doc.addItem(item)
                onDocumentChanged?()
                needsDisplay = true
            }
        }

        field.removeFromSuperview()
        textField = nil
    }

    // MARK: - Keyboard

    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command) {
            if event.charactersIgnoringModifiers == "z" {
                if event.modifierFlags.contains(.shift) {
                    document?.redo()
                } else {
                    document?.undo()
                }
                needsDisplay = true
                onDocumentChanged?()
                return
            }
        }

        if event.keyCode == 51 || event.keyCode == 117 { // Backspace or Delete
            document?.deleteSelected()
            needsDisplay = true
            onDocumentChanged?()
            return
        }

        super.keyDown(with: event)
    }
}
