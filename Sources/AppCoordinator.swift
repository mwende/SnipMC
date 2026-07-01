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

    @Published var lastCapturedURL: URL?
    private var editorController: EditorWindowController?

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

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []

        let modeString = url.host?.lowercased()
            ?? queryItems.first(where: { $0.name.caseInsensitiveCompare("mode") == .orderedSame })?
                .value?.lowercased()

        let wantsEditor = queryItems.first(where: { $0.name.caseInsensitiveCompare("edit") == .orderedSame })?
            .value?.lowercased() ?? "false"
        let openEditor = ["true", "1", "yes"].contains(wantsEditor)

        if modeString == "edit" {
            openEditorForFile()
            return
        }

        if modeString == "editlast" || modeString == "edit-last" || modeString == "lastedit" {
            openEditorForLastCapture()
            return
        }

        if modeString == "paste" || modeString == "clipboard" || modeString == "editclipboard" {
            openEditorFromClipboard()
            return
        }

        let mode: CaptureMode?
        switch modeString {
        case "fullscreen", "full", "full-screen", "screen":
            mode = .fullScreen
        case "window":
            mode = .window
        case "region", "area", "selection":
            mode = .region
        default:
            mode = nil
            NSLog("SnippingTool: unrecognized URL trigger \(url.absoluteString)")
        }

        if let mode {
            capture(mode: mode, openEditor: openEditor)
        }
    }

    // MARK: - Capture

    func capture(mode: CaptureMode, openEditor: Bool = false) {
        let saves = outputAction.savesToFile
        let copies = outputAction.copiesToClipboard
        let ext = imageFormat.fileExtension

        let targetURL: URL
        if saves || openEditor {
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
                self?.handleCaptured(at: targetURL, saves: saves, copies: copies, openEditor: openEditor)
            }
        }

        do {
            try process.run()
        } catch {
            NSLog("SnippingTool: failed to launch screencapture: \(error)")
        }
    }

    private func handleCaptured(at url: URL, saves: Bool, copies: Bool, openEditor: Bool = false) {
        guard FileManager.default.fileExists(atPath: url.path) else { return }

        lastCapturedURL = url

        if openEditor, let image = NSImage(contentsOf: url) {
            self.openEditor(image: image, sourceURL: url)
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

    // MARK: - Editor

    func openEditorForLastCapture() {
        guard let url = lastCapturedURL,
              FileManager.default.fileExists(atPath: url.path),
              let image = NSImage(contentsOf: url) else { return }
        DispatchQueue.main.async {
            self.openEditor(image: image, sourceURL: url)
        }
    }

    func openEditorFromClipboard() {
        guard let pasteboard = NSPasteboard.general.readObjects(forClasses: [NSImage.self], options: nil),
              let image = pasteboard.first as? NSImage else { return }
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(Self.filename(ext: imageFormat.fileExtension))
        DispatchQueue.main.async {
            self.openEditor(image: image, sourceURL: tempURL)
        }
    }

    func openEditorForFile() {
        DispatchQueue.main.async {
            NSApplication.shared.setActivationPolicy(.regular)
            NSApplication.shared.activate(ignoringOtherApps: true)

            let panel = NSOpenPanel()
            panel.allowedContentTypes = [.png, .jpeg, .tiff, .bmp]
            panel.canChooseDirectories = false
            panel.allowsMultipleSelection = false
            if panel.runModal() == .OK, let url = panel.url,
               let image = NSImage(contentsOf: url) {
                self.openEditor(image: image, sourceURL: url)
            } else {
                NSApplication.shared.setActivationPolicy(.accessory)
            }
        }
    }

    private func openEditor(image: NSImage, sourceURL: URL) {
        let controller = EditorWindowController(image: image, sourceURL: sourceURL) { [weak self] annotatedImage in
            guard let self, let annotatedImage else { return }
            self.saveAnnotatedImage(annotatedImage, replacingFileAt: sourceURL)
        }
        editorController = controller
        controller.showEditor()
    }

    private func saveAnnotatedImage(_ image: NSImage, replacingFileAt url: URL) {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return }

        let fileType: NSBitmapImageRep.FileType = imageFormat == .jpg ? .jpeg : .png
        let properties: [NSBitmapImageRep.PropertyKey: Any] = fileType == .jpeg
            ? [.compressionFactor: 0.9] : [:]

        guard let data = bitmap.representation(using: fileType, properties: properties) else { return }

        do {
            try data.write(to: url, options: .atomic)
        } catch {
            NSLog("SnippingTool: failed to save annotated image: \(error)")
        }

        if outputAction.copiesToClipboard {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.writeObjects([image])
        }
    }

    private static func filename(ext: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd 'um' HH.mm.ss"
        return "Bildschirmfoto \(formatter.string(from: Date())).\(ext)"
    }
}
