import Foundation

enum CaptureMode: String, CaseIterable {
    case fullScreen
    case window
    case region

    /// Stable id used to register/unregister the matching global hot key.
    var hotKeyID: UInt32 {
        switch self {
        case .fullScreen: return 1
        case .window: return 2
        case .region: return 3
        }
    }

    /// Extra arguments passed to /usr/sbin/screencapture for this mode.
    var screencaptureArguments: [String] {
        switch self {
        case .fullScreen: return []
        case .window: return ["-i", "-W"]
        case .region: return ["-i", "-s"]
        }
    }
}
