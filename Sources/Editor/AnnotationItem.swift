import AppKit
import Foundation

enum AnnotationKind: String, CaseIterable, Codable {
    case arrow
    case rectangle
    case ellipse
    case text
}

struct AnnotationItem: Identifiable {
    let id: UUID
    var kind: AnnotationKind
    var rect: CGRect
    var color: NSColor
    var lineWidth: CGFloat
    var text: String?
    var fontSize: CGFloat

    init(
        kind: AnnotationKind,
        rect: CGRect,
        color: NSColor = .systemRed,
        lineWidth: CGFloat = 3,
        text: String? = nil,
        fontSize: CGFloat = 24
    ) {
        self.id = UUID()
        self.kind = kind
        self.rect = rect
        self.color = color
        self.lineWidth = lineWidth
        self.text = text
        self.fontSize = fontSize
    }
}
