import AppKit
import Foundation

/// Central state + logic for the app: persisted settings, hot key
/// registration, and running screencapture to save/copy screenshots.
final class AppCoordinator: ObservableObject {
    private enum Keys {
        static let outputAction = "outputAction"
        static let imageFormat = "imageFormat"
        static let saveFolder = "saveFolder"
        static func hotKeyCode(_ mode: CaptureMode) -> String { "hotkey.\(mode.rawValue).keyCode" }
        static func hotKeyMods(_ mode: CaptureMode) -> String { "hotkey.\(mode.rawValue).modifiers" }
    }

    @Published var outputAction: OutputAction {
        didSet { UserDefaults.standard.set(outputAction.rawValue, forKey: Keys.outputAction) }
    }

    @Published var imageFormat: ImageFormat {
        didSet { UserDefaults.standard.set(imageFormat.rawValue, forKey: Keys.imageFormat) }
    }

    @Published var saveFolder: URL {
        didSet { UserDefaults.standard.set(saveFolder.path, forKey: Keys.saveFolder) }
    }

    @Published var hotKeyFullScreen: HotKeyCombo {
        didSet { persistAndRegister(mode: .fullScreen, combo: hotKeyFullScreen) }
    }

    @Published var hotKeyWindow: HotKeyCombo {
        didSet { persistAndRegister(mode: .window, combo: hotKeyWindow) }
    }

    @Published var hotKeyRegion: HotKeyCombo {
        didSet { persistAndRegister(mode: .region, combo: hotKeyRegion) }
    }

    init() {
        let defaults = UserDefaults.standard

        outputAction = OutputAction(rawValue: defaults.string(forKey: Keys.outputAction) ?? "") ?? .both
        imageFormat = ImageFormat(rawValue: defaults.string(forKey: Keys.imageFormat) ?? "") ?? .png

        if let path = defaults.string(forKey: Keys.saveFolder) {
            saveFolder = URL(fileURLWithPath: path)
        } else {
            saveFolder = Self.defaultSaveFolder()
        }

        hotKeyFullScreen = Self.loadCombo(mode: .fullScreen, default: .defaultFullScreen)
        hotKeyWindow = Self.loadCombo(mode: .window, default: .defaultWindow)
        hotKeyRegion = Self.loadCombo(mode: .region, default: .defaultRegion)

        registerHotKey(mode: .fullScreen, combo: hotKeyFullScreen)
        registerHotKey(mode: .window, combo: hotKeyWindow)
        registerHotKey(mode: .region, combo: hotKeyRegion)
    }

    private static func defaultSaveFolder() -> URL {
        let pictures = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
        return pictures.appendingPathComponent("Screenshots", isDirectory: true)
    }

    private static func loadCombo(mode: CaptureMode, default defaultValue: HotKeyCombo) -> HotKeyCombo {
        let defaults = UserDefaults.standard
        let codeKey = Keys.hotKeyCode(mode)
        let modsKey = Keys.hotKeyMods(mode)
        guard defaults.object(forKey: codeKey) != nil, defaults.object(forKey: modsKey) != nil else {
            return defaultValue
        }
        let code = UInt32(defaults.integer(forKey: codeKey))
        let mods = UInt32(defaults.integer(forKey: modsKey))
        return HotKeyCombo(keyCode: code, carbonModifiers: mods)
    }

    private func persistAndRegister(mode: CaptureMode, combo: HotKeyCombo) {
        let defaults = UserDefaults.standard
        defaults.set(Int(combo.keyCode), forKey: Keys.hotKeyCode(mode))
        defaults.set(Int(combo.carbonModifiers), forKey: Keys.hotKeyMods(mode))
        registerHotKey(mode: mode, combo: combo)
    }

    private func registerHotKey(mode: CaptureMode, combo: HotKeyCombo) {
        HotKeyManager.shared.register(
            id: mode.hotKeyID,
            keyCode: combo.keyCode,
            modifiers: combo.carbonModifiers
        ) { [weak self] in
            self?.capture(mode: mode)
        }
    }

    // MARK: - External triggers (URL scheme)

    /// Handles `snippingtool://<mode>` URLs so external tools (Logitech
    /// Options, Shortcuts, Stream Deck, `open` from the command line, …)
    /// can trigger a specific capture mode instead of just launching the app.
    /// Accepts the mode either as the host (`snippingtool://region`) or as
    /// a query item (`snippingtool://capture?mode=region`).
    func handle(url: URL) {
        guard url.scheme?.caseInsensitiveCompare("snippingtool") == .orderedSame else { return }

        let modeString = url.host?.lowercased()
            ?? URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?
                .first(where: { $0.name.caseInsensitiveCompare("mode") == .orderedSame })?
                .value?
                .lowercased()

        switch modeString {
        case "fullscreen", "full", "full-screen", "screen":
            capture(mode: .fullScreen)
        case "window":
            capture(mode: .window)
        case "region", "area", "selection":
            capture(mode: .region)
        default:
            NSLog("SnippingTool: unrecognized URL trigger \(url.absoluteString)")
        }
    }

    // MARK: - Capture

    func capture(mode: CaptureMode) {
        let saves = outputAction.savesToFile
        let copies = outputAction.copiesToClipboard
        let ext = imageFormat.fileExtension

        let targetURL: URL
        if saves {
            try? FileManager.default.createDirectory(at: saveFolder, withIntermediateDirectories: true)
            targetURL = saveFolder.appendingPathComponent(Self.filename(ext: ext))
        } else {
            targetURL = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent(Self.filename(ext: ext))
        }

        var arguments = mode.screencaptureArguments
        arguments += ["-t", imageFormat.rawValue, targetURL.path]

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = arguments
        process.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                self?.handleCaptured(at: targetURL, saves: saves, copies: copies)
            }
        }

        do {
            try process.run()
        } catch {
            NSLog("SnippingTool: failed to launch screencapture: \(error)")
        }
    }

    private func handleCaptured(at url: URL, saves: Bool, copies: Bool) {
        guard FileManager.default.fileExists(atPath: url.path) else {
            // User cancelled the interactive capture (Esc).
            return
        }

        if copies, let image = NSImage(contentsOf: url) {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.writeObjects([image])
        }

        if !saves {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private static func filename(ext: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd 'um' HH.mm.ss"
        return "Bildschirmfoto \(formatter.string(from: Date())).\(ext)"
    }
}
