import Foundation
import AppKit
import Carbon.HIToolbox

/// Manages global keyboard shortcuts with push-to-talk support
/// Supports both key+modifier combos and modifier-only shortcuts
final class HotkeyService: ObservableObject {
    
    // MARK: - Properties
    
    private var globalKeyDownMonitor: Any?
    private var globalKeyUpMonitor: Any?
    private var globalFlagsMonitor: Any?
    private var localKeyDownMonitor: Any?
    private var localKeyUpMonitor: Any?
    private var localFlagsMonitor: Any?
    private var currentKeyCombo: KeyCombo?
    
    /// Called when the hotkey is pressed down (start recording)
    var onHotkeyDown: (() -> Void)?
    
    /// Called when the hotkey is released (stop recording)
    var onHotkeyUp: (() -> Void)?
    
    @Published private(set) var isListening = false
    @Published private(set) var isKeyHeld = false
    
    // Track previous modifier state for modifier-only shortcuts
    private var previousModifierFlags: NSEvent.ModifierFlags = []
    
    // MARK: - Initialization
    
    init() {}
    
    deinit {
        stopListening()
    }
    
    // MARK: - Public Methods
    
    /// Start listening for the specified key combination (push-to-talk)
    func startListening(for keyCombo: KeyCombo) {
        stopListening()
        
        currentKeyCombo = keyCombo
        previousModifierFlags = []
        
        // Check if we have accessibility permission (required for global monitoring)
        let hasAccessibility = AXIsProcessTrusted()
        
        if hasAccessibility {
            if keyCombo.isModifierOnly {
                // For modifier-only shortcuts, monitor flagsChanged events
                globalFlagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
                    self?.handleFlagsChanged(event)
                }
                print("[HotkeyService] Global flags monitor installed for modifier-only shortcut")
            } else {
                // For key+modifier shortcuts, monitor keyDown/keyUp
                globalKeyDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
                    self?.handleKeyDown(event)
                }
                
                globalKeyUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyUp) { [weak self] event in
                    self?.handleKeyUp(event)
                }
                print("[HotkeyService] Global key monitors installed")
            }
        } else {
            print("[HotkeyService] WARNING: No accessibility permission - global shortcuts won't work!")
        }
        
        // Local monitors (when app is focused)
        if keyCombo.isModifierOnly {
            localFlagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
                self?.handleFlagsChanged(event)
                return event
            }
        } else {
            localKeyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                if self?.handleKeyDown(event) == true {
                    return nil // Consume the event
                }
                return event
            }
            
            localKeyUpMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyUp) { [weak self] event in
                if self?.handleKeyUp(event) == true {
                    return nil // Consume the event
                }
                return event
            }
        }
        
        isListening = true
        print("[HotkeyService] Started listening for push-to-talk: \(keyCombo.displayString) (modifier-only: \(keyCombo.isModifierOnly))")
    }
    
    /// Stop listening for keyboard shortcuts
    func stopListening() {
        if let monitor = globalKeyDownMonitor {
            NSEvent.removeMonitor(monitor)
            globalKeyDownMonitor = nil
        }
        
        if let monitor = globalKeyUpMonitor {
            NSEvent.removeMonitor(monitor)
            globalKeyUpMonitor = nil
        }
        
        if let monitor = globalFlagsMonitor {
            NSEvent.removeMonitor(monitor)
            globalFlagsMonitor = nil
        }
        
        if let monitor = localKeyDownMonitor {
            NSEvent.removeMonitor(monitor)
            localKeyDownMonitor = nil
        }
        
        if let monitor = localKeyUpMonitor {
            NSEvent.removeMonitor(monitor)
            localKeyUpMonitor = nil
        }
        
        if let monitor = localFlagsMonitor {
            NSEvent.removeMonitor(monitor)
            localFlagsMonitor = nil
        }
        
        isListening = false
        isKeyHeld = false
        previousModifierFlags = []
    }
    
    /// Update the key combination being listened for
    func updateKeyCombo(_ keyCombo: KeyCombo) {
        currentKeyCombo = keyCombo
        
        // Re-register monitors with new key combo
        if isListening {
            startListening(for: keyCombo)
        }
    }
    
    /// Re-register monitors (call after accessibility permission is granted)
    func refreshMonitors() {
        if let keyCombo = currentKeyCombo {
            startListening(for: keyCombo)
        }
    }
    
    // MARK: - Private Methods - Key Events
    
    @discardableResult
    private func handleKeyDown(_ event: NSEvent) -> Bool {
        guard let keyCombo = currentKeyCombo, !keyCombo.isModifierOnly else { return false }
        
        // Ignore key repeat events (when key is held down)
        if event.isARepeat {
            return keyCombo.matches(event: event)
        }
        
        if keyCombo.matches(event: event) {
            guard !isKeyHeld else { return true } // Already holding
            
            print("[HotkeyService] Hotkey pressed DOWN - start recording")
            isKeyHeld = true
            DispatchQueue.main.async { [weak self] in
                self?.onHotkeyDown?()
            }
            return true
        }
        
        return false
    }
    
    @discardableResult
    private func handleKeyUp(_ event: NSEvent) -> Bool {
        guard let keyCombo = currentKeyCombo, !keyCombo.isModifierOnly else { return false }
        
        if keyCombo.matchesKeyUp(event: event) {
            guard isKeyHeld else { return true } // Wasn't holding
            
            print("[HotkeyService] Hotkey released UP - stop recording")
            isKeyHeld = false
            DispatchQueue.main.async { [weak self] in
                self?.onHotkeyUp?()
            }
            return true
        }
        
        return false
    }
    
    // MARK: - Private Methods - Modifier Events
    
    private func handleFlagsChanged(_ event: NSEvent) {
        guard let keyCombo = currentKeyCombo, keyCombo.isModifierOnly else { return }
        
        let currentMods = event.modifierFlags.intersection([.control, .option, .shift, .command])
        let targetMods = keyCombo.modifierFlags.intersection([.control, .option, .shift, .command])
        
        let wasPressed = previousModifierFlags.contains(targetMods)
        let isPressed = currentMods.contains(targetMods)
        
        // Update previous state
        previousModifierFlags = currentMods
        
        // Detect press (transition from not pressed to pressed)
        if !wasPressed && isPressed && !isKeyHeld {
            print("[HotkeyService] Modifier pressed DOWN - start recording")
            isKeyHeld = true
            DispatchQueue.main.async { [weak self] in
                self?.onHotkeyDown?()
            }
        }
        
        // Detect release (transition from pressed to not pressed)
        if wasPressed && !isPressed && isKeyHeld {
            print("[HotkeyService] Modifier released UP - stop recording")
            isKeyHeld = false
            DispatchQueue.main.async { [weak self] in
                self?.onHotkeyUp?()
            }
        }
    }
}

// MARK: - Shortcut Recording

extension HotkeyService {
    
    /// Represents a recorded shortcut or a special state
    enum RecordingResult {
        case recorded(KeyCombo)
        case cancelled
        case cleared
    }
    
    /// Helper class for recording new shortcuts
    /// Supports recording both key+modifier and modifier-only shortcuts
    final class ShortcutRecorder: ObservableObject {
        @Published var isRecording = false
        @Published var currentDisplay = ""
        
        private var keyEventMonitor: Any?
        private var flagsEventMonitor: Any?
        private var modifierHoldTimer: Timer?
        private var currentModifiers: NSEvent.ModifierFlags = []
        
        var onRecordComplete: ((RecordingResult) -> Void)?
        
        func startRecording() {
            isRecording = true
            currentDisplay = "Press shortcut..."
            currentModifiers = []
            
            // Monitor key events
            keyEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                self?.handleKeyEvent(event)
                return nil // Consume all events while recording
            }
            
            // Monitor modifier changes (for modifier-only shortcuts)
            flagsEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
                self?.handleFlagsEvent(event)
                return event
            }
        }
        
        func stopRecording() {
            if let monitor = keyEventMonitor {
                NSEvent.removeMonitor(monitor)
                keyEventMonitor = nil
            }
            if let monitor = flagsEventMonitor {
                NSEvent.removeMonitor(monitor)
                flagsEventMonitor = nil
            }
            modifierHoldTimer?.invalidate()
            modifierHoldTimer = nil
            isRecording = false
        }
        
        func cancelRecording() {
            stopRecording()
            onRecordComplete?(.cancelled)
        }
        
        private func handleKeyEvent(_ event: NSEvent) {
            // Cancel any pending modifier-only detection
            modifierHoldTimer?.invalidate()
            modifierHoldTimer = nil
            
            // Escape cancels recording
            if event.keyCode == UInt16(kVK_Escape) {
                stopRecording()
                onRecordComplete?(.cancelled)
                return
            }
            
            // Delete/Backspace clears the shortcut
            if event.keyCode == UInt16(kVK_Delete) || event.keyCode == UInt16(kVK_ForwardDelete) {
                stopRecording()
                onRecordComplete?(.cleared)
                return
            }
            
            // Get modifiers
            let modifiers = event.modifierFlags.intersection([.control, .option, .shift, .command])
            let keyCode = event.keyCode
            
            // Allow function keys without modifiers
            let isFunctionKey = (keyCode >= UInt16(kVK_F1) && keyCode <= UInt16(kVK_F12))
            
            if modifiers.isEmpty && !isFunctionKey {
                currentDisplay = "Add modifier key..."
                return
            }
            
            // Key + modifier combo
            let keyCombo = KeyCombo(keyCode: keyCode, modifierFlags: modifiers)
            currentDisplay = keyCombo.displayString
            
            stopRecording()
            onRecordComplete?(.recorded(keyCombo))
        }
        
        private func handleFlagsEvent(_ event: NSEvent) {
            let mods = event.modifierFlags.intersection([.control, .option, .shift, .command])
            
            if !mods.isEmpty {
                // Modifier pressed - start timer
                currentModifiers = mods
                updateModifierDisplay(mods)
                
                // Cancel previous timer
                modifierHoldTimer?.invalidate()
                
                // Start new timer - if held for 0.5 seconds, use as modifier-only shortcut
                modifierHoldTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                    guard let self = self, self.isRecording else { return }
                    
                    // Check if modifiers are still held
                    let currentFlags = NSEvent.modifierFlags.intersection([.control, .option, .shift, .command])
                    if currentFlags == self.currentModifiers && !self.currentModifiers.isEmpty {
                        // User held modifier for 0.5s without pressing a key - use modifier-only
                        let keyCombo = KeyCombo(modifierOnly: self.currentModifiers)
                        self.currentDisplay = keyCombo.displayString + " (hold)"
                        
                        self.stopRecording()
                        self.onRecordComplete?(.recorded(keyCombo))
                    }
                }
            } else {
                // All modifiers released - cancel timer
                modifierHoldTimer?.invalidate()
                modifierHoldTimer = nil
                currentModifiers = []
                if isRecording {
                    currentDisplay = "Press shortcut..."
                }
            }
        }
        
        private func updateModifierDisplay(_ mods: NSEvent.ModifierFlags) {
            var parts: [String] = []
            if mods.contains(.control) { parts.append("⌃") }
            if mods.contains(.option) { parts.append("⌥") }
            if mods.contains(.shift) { parts.append("⇧") }
            if mods.contains(.command) { parts.append("⌘") }
            
            if !parts.isEmpty {
                currentDisplay = parts.joined() + "... (hold for modifier-only)"
            }
        }
    }
}
