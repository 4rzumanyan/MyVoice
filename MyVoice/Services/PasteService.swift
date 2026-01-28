import Foundation
import AppKit
import Carbon.HIToolbox

/// Handles clipboard operations and simulated paste
final class PasteService {
    
    enum PasteError: LocalizedError {
        case accessibilityNotGranted
        case eventCreationFailed
        case emptyText
        
        var errorDescription: String? {
            switch self {
            case .accessibilityNotGranted:
                return "Accessibility permission is required to paste text. Please enable it in System Settings."
            case .eventCreationFailed:
                return "Failed to create keyboard event for pasting."
            case .emptyText:
                return "No text to paste."
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Copy text to the system clipboard
    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    /// Simulate pressing Cmd+V to paste
    /// Note: Requires accessibility permissions
    func simulatePaste() throws {
        // Check accessibility permission
        guard AXIsProcessTrusted() else {
            throw PasteError.accessibilityNotGranted
        }
        
        // Create key down event for 'V' with Command modifier
        guard let keyDownEvent = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true) else {
            throw PasteError.eventCreationFailed
        }
        keyDownEvent.flags = .maskCommand
        
        // Create key up event
        guard let keyUpEvent = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false) else {
            throw PasteError.eventCreationFailed
        }
        keyUpEvent.flags = .maskCommand
        
        // Post events
        keyDownEvent.post(tap: .cghidEventTap)
        keyUpEvent.post(tap: .cghidEventTap)
    }
    
    /// Copy text and optionally paste it based on behavior setting
    func outputText(_ text: String, behavior: PasteBehavior) throws {
        guard !text.isEmpty else {
            throw PasteError.emptyText
        }
        
        // Copy to clipboard if needed
        if behavior.shouldCopyToClipboard || behavior.shouldAutoPaste {
            // Always copy first if we're going to paste
            copyToClipboard(text)
        }
        
        // Simulate paste if needed
        if behavior.shouldAutoPaste {
            // Small delay to ensure clipboard is ready
            Thread.sleep(forTimeInterval: 0.05)
            try simulatePaste()
        }
    }
    
    /// Get current clipboard text
    func getClipboardText() -> String? {
        return NSPasteboard.general.string(forType: .string)
    }
}
