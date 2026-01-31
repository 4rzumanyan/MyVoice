import Foundation
import Carbon.HIToolbox
import AppKit

/// Represents a keyboard shortcut combination
/// Supports both key+modifier combos (e.g., ⌘+Space) and modifier-only (e.g., just ⌘)
struct KeyCombo: Codable, Equatable {
    /// Key code (0xFFFF means modifier-only shortcut)
    var keyCode: UInt16
    var modifiers: UInt
    
    /// Special key code indicating this is a modifier-only shortcut
    static let modifierOnlyKeyCode: UInt16 = 0xFFFF
    
    /// Default shortcut: Control + Option + Command (modifier-only)
    static let defaultCombo = KeyCombo(
        keyCode: modifierOnlyKeyCode,
        modifiers: NSEvent.ModifierFlags([.control, .option, .command]).rawValue
    )
    
    /// Command-only shortcut
    static let commandOnly = KeyCombo(keyCode: modifierOnlyKeyCode, modifiers: NSEvent.ModifierFlags.command.rawValue)
    
    /// Option-only shortcut
    static let optionOnly = KeyCombo(keyCode: modifierOnlyKeyCode, modifiers: NSEvent.ModifierFlags.option.rawValue)
    
    init(keyCode: UInt16, modifiers: UInt) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }
    
    init(keyCode: UInt16, modifierFlags: NSEvent.ModifierFlags) {
        self.keyCode = keyCode
        self.modifiers = modifierFlags.rawValue
    }
    
    /// Create a modifier-only shortcut
    init(modifierOnly: NSEvent.ModifierFlags) {
        self.keyCode = KeyCombo.modifierOnlyKeyCode
        self.modifiers = modifierOnly.rawValue
    }
    
    var modifierFlags: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: modifiers)
    }
    
    /// Whether this is a modifier-only shortcut (no key, just modifier)
    var isModifierOnly: Bool {
        keyCode == KeyCombo.modifierOnlyKeyCode
    }
    
    /// Human-readable display string for the shortcut
    var displayString: String {
        var parts: [String] = []
        
        let flags = modifierFlags
        if flags.contains(.control) { parts.append("⌃") }
        if flags.contains(.option) { parts.append("⌥") }
        if flags.contains(.shift) { parts.append("⇧") }
        if flags.contains(.command) { parts.append("⌘") }
        
        // Only add key name if not modifier-only
        if !isModifierOnly {
            parts.append(keyCodeToString(keyCode))
        }
        
        return parts.joined()
    }
    
    /// Check if an NSEvent matches this key combo (for key down)
    func matches(event: NSEvent) -> Bool {
        // Modifier-only shortcuts don't match key events
        if isModifierOnly { return false }
        
        guard event.keyCode == keyCode else { return false }
        
        let eventMods = event.modifierFlags.intersection([.control, .option, .shift, .command])
        let targetMods = modifierFlags.intersection([.control, .option, .shift, .command])
        
        return eventMods == targetMods
    }
    
    /// Check if a key up event matches this key combo
    /// Note: On key up, modifiers may already be released, so we only check keyCode
    func matchesKeyUp(event: NSEvent) -> Bool {
        // Modifier-only shortcuts don't match key events
        if isModifierOnly { return false }
        
        return event.keyCode == keyCode
    }
    
    /// Check if a flagsChanged event represents this modifier being pressed
    func matchesModifierDown(event: NSEvent) -> Bool {
        guard isModifierOnly else { return false }
        
        let eventMods = event.modifierFlags.intersection([.control, .option, .shift, .command])
        let targetMods = modifierFlags.intersection([.control, .option, .shift, .command])
        
        // Check if our target modifiers are now pressed
        return eventMods == targetMods && !targetMods.isEmpty
    }
    
    /// Check if a flagsChanged event represents this modifier being released
    func matchesModifierUp(event: NSEvent) -> Bool {
        guard isModifierOnly else { return false }
        
        let eventMods = event.modifierFlags.intersection([.control, .option, .shift, .command])
        let targetMods = modifierFlags.intersection([.control, .option, .shift, .command])
        
        // Check if our target modifiers are no longer pressed
        // We need to check if the modifier we care about was released
        return !eventMods.contains(targetMods)
    }
    
    private func keyCodeToString(_ keyCode: UInt16) -> String {
        switch Int(keyCode) {
        case kVK_Space: return "Space"
        case kVK_Return: return "↩"
        case kVK_Tab: return "⇥"
        case kVK_Delete: return "⌫"
        case kVK_Escape: return "⎋"
        case kVK_F1: return "F1"
        case kVK_F2: return "F2"
        case kVK_F3: return "F3"
        case kVK_F4: return "F4"
        case kVK_F5: return "F5"
        case kVK_F6: return "F6"
        case kVK_F7: return "F7"
        case kVK_F8: return "F8"
        case kVK_F9: return "F9"
        case kVK_F10: return "F10"
        case kVK_F11: return "F11"
        case kVK_F12: return "F12"
        case kVK_UpArrow: return "↑"
        case kVK_DownArrow: return "↓"
        case kVK_LeftArrow: return "←"
        case kVK_RightArrow: return "→"
        default:
            // Try to get character from key code
            if let char = characterFromKeyCode(keyCode) {
                return char.uppercased()
            }
            return "Key\(keyCode)"
        }
    }
    
    private func characterFromKeyCode(_ keyCode: UInt16) -> String? {
        let source = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
        guard let layoutData = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else {
            return nil
        }
        
        let dataRef = unsafeBitCast(layoutData, to: CFData.self)
        let keyboardLayout = unsafeBitCast(CFDataGetBytePtr(dataRef), to: UnsafePointer<UCKeyboardLayout>.self)
        
        var deadKeyState: UInt32 = 0
        var chars = [UniChar](repeating: 0, count: 4)
        var length: Int = 0
        
        let status = UCKeyTranslate(
            keyboardLayout,
            keyCode,
            UInt16(kUCKeyActionDisplay),
            0,
            UInt32(LMGetKbdType()),
            OptionBits(kUCKeyTranslateNoDeadKeysBit),
            &deadKeyState,
            4,
            &length,
            &chars
        )
        
        guard status == noErr, length > 0 else { return nil }
        return String(utf16CodeUnits: chars, count: length)
    }
}

// MARK: - UserDefaults Storage
extension KeyCombo {
    static func load(from defaults: UserDefaults, key: String) -> KeyCombo {
        guard let data = defaults.data(forKey: key),
              let combo = try? JSONDecoder().decode(KeyCombo.self, from: data) else {
            return .defaultCombo
        }
        return combo
    }
    
    func save(to defaults: UserDefaults, key: String) {
        if let data = try? JSONEncoder().encode(self) {
            defaults.set(data, forKey: key)
        }
    }
}
