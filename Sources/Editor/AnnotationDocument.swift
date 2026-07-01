import AppKit
import Foundation

@Observable
final class AnnotationDocument {
    var items: [AnnotationItem] = []
    var selectedItemID: UUID?
    var currentTool: AnnotationKind = .arrow
    var currentColor: NSColor = .systemRed
    var currentLineWidth: CGFloat = 3

    private var undoStack: [[AnnotationItem]] = []
    private var redoStack: [[AnnotationItem]] = []

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    func pushUndo() {
        undoStack.append(items)
        redoStack.removeAll()
    }

    func undo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(items)
        items = previous
        selectedItemID = nil
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(items)
        items = next
        selectedItemID = nil
    }

    func addItem(_ item: AnnotationItem) {
        pushUndo()
        items.append(item)
        selectedItemID = item.id
    }

    func deleteSelected() {
        guard let id = selectedItemID else { return }
        pushUndo()
        items.removeAll { $0.id == id }
        selectedItemID = nil
    }

    func moveSelected(by delta: CGSize) {
        guard let id = selectedItemID,
              let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].rect.origin.x += delta.width
        items[index].rect.origin.y += delta.height
    }
}
