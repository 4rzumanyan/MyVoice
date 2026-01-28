import Foundation

/// Available Gemini models for transcription
enum GeminiModel: String, CaseIterable, Identifiable {
    case flash3 = "gemini-3-flash-preview"
    case pro3 = "gemini-2.5-pro-preview-06-05"
    case flash25 = "gemini-2.5-flash-preview-05-20"
    case pro25 = "gemini-2.5-pro-preview-05-06"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .flash3:
            return "Gemini 3 Flash"
        case .pro3:
            return "Gemini 3 Pro"
        case .flash25:
            return "Gemini 2.5 Flash"
        case .pro25:
            return "Gemini 2.5 Pro"
        }
    }
    
    var description: String {
        switch self {
        case .flash3:
            return "Latest flash model, fast with improved quality"
        case .pro3:
            return "Latest pro model with advanced capabilities"
        case .flash25:
            return "Fast and efficient, good for most transcriptions"
        case .pro25:
            return "High quality transcription, more accurate"
        }
    }
    
    /// The API model identifier to use in requests
    var apiModelId: String {
        return rawValue
    }
}
