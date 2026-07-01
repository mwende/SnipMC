import Carbon.HIToolbox

/// A recorded global keyboard shortcut: a virtual key code plus Carbon-style modifier flags.
struct HotKeyCombo: Codable, Equatable {
    var keyCode: UInt32
    var carbonModifiers: UInt32

    var displayString: String {
        var symbol = ""
        if carbonModifiers & UInt32(controlKey) != 0 { symbol += "\u{2303}" }
        if carbonModifiers & UInt32(optionKey) != 0 { symbol += "\u{2325}" }
        if carbonModifiers & UInt32(shiftKey) != 0 { symbol += "\u{21E7}" }
        if carbonModifiers & UInt32(cmdKey) != 0 { symbol += "\u{2318}" }
        symbol += KeyCodeSymbols.symbol(for: keyCode)
        return symbol
    }

    static let defaultModifiers = UInt32(cmdKey) | UInt32(optionKey) | UInt32(shiftKey)

    static let defaultFullScreen = HotKeyCombo(keyCode: UInt32(kVK_ANSI_3), carbonModifiers: defaultModifiers)
    static let defaultWindow = HotKeyCombo(keyCode: UInt32(kVK_ANSI_4), carbonModifiers: defaultModifiers)
    static let defaultRegion = HotKeyCombo(keyCode: UInt32(kVK_ANSI_5), carbonModifiers: defaultModifiers)
}
