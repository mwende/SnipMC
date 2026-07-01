import AppKit
import Foundation

enum AnnotationRenderer {

    static func draw(_ item: AnnotationItem, in context: CGContext) {
        context.saveGState()
        context.setStrokeColor(item.color.cgColor)
        context.setFillColor(item.color.cgColor)
        context.setLineWidth(item.lineWidth)
        context.setLineCap(.round)
        context.setLineJoin(.round)

        switch item.kind {
        case .arrow:
            drawArrow(item, in: context)
        case .rectangle:
            drawRectangle(item, in: context)
        case .ellipse:
            drawEllipse(item, in: context)
        case .text:
            drawText(item)
        }

        context.restoreGState()
    }

    static func render(annotations: [AnnotationItem], onto image: NSImage) -> NSImage {
        let size = image.size
        let result = NSImage(size: size)
        result.lockFocus()

        image.draw(in: NSRect(origin: .zero, size: size))

        if let context = NSGraphicsContext.current?.cgContext {
            for item in annotations {
                draw(item, in: context)
            }
        }

        result.unlockFocus()
        return result
    }

    // MARK: - Shape drawing

    private static func drawArrow(_ item: AnnotationItem, in context: CGContext) {
        let start = item.rect.origin
        let end = CGPoint(x: item.rect.maxX, y: item.rect.maxY)

        context.move(to: start)
        context.addLine(to: end)
        context.strokePath()

        let angle = atan2(end.y - start.y, end.x - start.x)
        let headLength = max(item.lineWidth * 4, 14)
        let headAngle: CGFloat = .pi / 6

        let left = CGPoint(
            x: end.x - headLength * cos(angle - headAngle),
            y: end.y - headLength * sin(angle - headAngle)
        )
        let right = CGPoint(
            x: end.x - headLength * cos(angle + headAngle),
            y: end.y - headLength * sin(angle + headAngle)
        )

        context.move(to: end)
        context.addLine(to: left)
        context.addLine(to: right)
        context.closePath()
        context.fillPath()
    }

    private static func drawRectangle(_ item: AnnotationItem, in context: CGContext) {
        context.stroke(item.rect, width: item.lineWidth)
    }

    private static func drawEllipse(_ item: AnnotationItem, in context: CGContext) {
        context.strokeEllipse(in: item.rect)
    }

    private static func drawText(_ item: AnnotationItem) {
        guard let text = item.text, !text.isEmpty else { return }
        let font = NSFont.systemFont(ofSize: item.fontSize, weight: .semibold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: item.color,
        ]
        let string = NSAttributedString(string: text, attributes: attributes)
        string.draw(at: item.rect.origin)
    }

    // MARK: - Hit testing

    static func hitTest(point: CGPoint, item: AnnotationItem, tolerance: CGFloat = 6) -> Bool {
        switch item.kind {
        case .arrow:
            return distanceToLine(point: point,
                                  from: item.rect.origin,
                                  to: CGPoint(x: item.rect.maxX, y: item.rect.maxY)) < tolerance + item.lineWidth
        case .rectangle:
            let outer = item.rect.insetBy(dx: -(tolerance + item.lineWidth),
                                          dy: -(tolerance + item.lineWidth))
            let inner = item.rect.insetBy(dx: tolerance + item.lineWidth,
                                          dy: tolerance + item.lineWidth)
            return outer.contains(point) && !inner.contains(point)
        case .ellipse:
            let center = CGPoint(x: item.rect.midX, y: item.rect.midY)
            let rx = item.rect.width / 2
            let ry = item.rect.height / 2
            guard rx > 0, ry > 0 else { return false }
            let dx = (point.x - center.x) / rx
            let dy = (point.y - center.y) / ry
            let dist = sqrt(dx * dx + dy * dy)
            return abs(dist - 1.0) < (tolerance + item.lineWidth) / min(rx, ry)
        case .text:
            guard let text = item.text, !text.isEmpty else { return false }
            let font = NSFont.systemFont(ofSize: item.fontSize, weight: .semibold)
            let size = (text as NSString).size(withAttributes: [.font: font])
            let textRect = CGRect(origin: item.rect.origin, size: size)
            return textRect.insetBy(dx: -tolerance, dy: -tolerance).contains(point)
        }
    }

    private static func distanceToLine(point: CGPoint, from a: CGPoint, to b: CGPoint) -> CGFloat {
        let dx = b.x - a.x
        let dy = b.y - a.y
        let lengthSq = dx * dx + dy * dy
        guard lengthSq > 0 else { return hypot(point.x - a.x, point.y - a.y) }

        var t = ((point.x - a.x) * dx + (point.y - a.y) * dy) / lengthSq
        t = max(0, min(1, t))

        let projX = a.x + t * dx
        let projY = a.y + t * dy
        return hypot(point.x - projX, point.y - projY)
    }
}
