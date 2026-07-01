import Foundation

enum OutputAction: String, CaseIterable, Identifiable, Codable {
    case saveOnly
    case clipboardOnly
    case both

    var id: String { rawValue }

    var label: String {
        switch self {
        case .saveOnly: return "Nur speichern"
        case .clipboardOnly: return "Nur in Zwischenablage kopieren"
        case .both: return "Speichern und in Zwischenablage kopieren"
        }
    }

    var savesToFile: Bool { self == .saveOnly || self == .both }
    var copiesToClipboard: Bool { self == .clipboardOnly || self == .both }
}
