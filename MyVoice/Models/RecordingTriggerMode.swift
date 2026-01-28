import Foundation

/// How recording is triggered via the shortcut
enum RecordingTriggerMode: String, CaseIterable, Identifiable {
    case holdToRecord
    case tapToToggle

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .holdToRecord:
            return "Hold to Record"
        case .tapToToggle:
            return "Tap to Toggle"
        }
    }

    var description: String {
        switch self {
        case .holdToRecord:
            return "Hold the shortcut to record, release to transcribe"
        case .tapToToggle:
            return "Press once to start, press again to stop and transcribe"
        }
    }
}
