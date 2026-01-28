import Foundation

/// Represents the current state of the voice recording and transcription process
enum RecordingState: Equatable {
    case idle
    case recording
    case processing
    case error(String)
    
    var isRecording: Bool {
        if case .recording = self { return true }
        return false
    }
    
    var isProcessing: Bool {
        if case .processing = self { return true }
        return false
    }
    
    var isBusy: Bool {
        switch self {
        case .recording, .processing:
            return true
        default:
            return false
        }
    }
    
    var statusText: String {
        switch self {
        case .idle:
            return "Ready"
        case .recording:
            return "Recording..."
        case .processing:
            return "Transcribing..."
        case .error(let message):
            return "Error: \(message)"
        }
    }
    
    var iconName: String {
        switch self {
        case .idle:
            return "mic"
        case .recording:
            return "mic.fill"
        case .processing:
            return "ellipsis.circle"
        case .error:
            return "exclamationmark.triangle"
        }
    }
}
