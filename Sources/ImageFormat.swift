import Foundation

enum ImageFormat: String, CaseIterable, Identifiable, Codable {
    case png
    case jpg

    var id: String { rawValue }
    var label: String { rawValue.uppercased() }
    var fileExtension: String { rawValue }
}
