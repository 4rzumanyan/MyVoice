import Foundation

/// Defines how the transcribed text should be output
enum PasteBehavior: String, CaseIterable, Identifiable {
    case autoPaste = "autoPaste"
    case clipboardOnly = "clipboardOnly"
    case both = "both"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .autoPaste:
            return "Auto-paste"
        case .clipboardOnly:
            return "Copy to clipboard only"
        case .both:
            return "Both (copy and paste)"
        }
    }
    
    var description: String {
        switch self {
        case .autoPaste:
            return "Automatically paste into the active text field"
        case .clipboardOnly:
            return "Only copy to clipboard, paste manually with ⌘V"
        case .both:
            return "Copy to clipboard and automatically paste"
        }
    }
    
    var shouldCopyToClipboard: Bool {
        switch self {
        case .clipboardOnly, .both:
            return true
        case .autoPaste:
            return false
        }
    }
    
    var shouldAutoPaste: Bool {
        switch self {
        case .autoPaste, .both:
            return true
        case .clipboardOnly:
            return false
        }
    }
}
