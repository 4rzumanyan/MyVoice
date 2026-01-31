import Foundation

/// Represents a prompt template for transcription processing
struct TranscriptionPrompt: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var promptText: String
    let isBuiltIn: Bool
    
    // MARK: - Built-in Prompts
    
    /// Default transcription - raw output as spoken
    static let transcribe = TranscriptionPrompt(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        name: "Transcribe",
        promptText: "Transcribe this audio exactly as spoken. Return only the transcription text, nothing else. If the audio is empty or unclear, return an empty string.",
        isBuiltIn: true
    )
    
    /// Professional tone - formal business communication
    static let professional = TranscriptionPrompt(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        name: "Professional",
        promptText: "Listen to this audio and convert it to professional, formal written text suitable for business communication. Fix grammar and add proper punctuation. Output ONLY the final professional text - do not include headers, labels, the original transcription, or any explanations. If the audio is empty or unclear, return an empty string.",
        isBuiltIn: true
    )
    
    /// All built-in prompts
    static let builtInPrompts: [TranscriptionPrompt] = [transcribe, professional]
    
    /// The default prompt used when custom prompts are disabled
    static let defaultPrompt = transcribe
    
    // MARK: - Initialization
    
    /// Create a new custom prompt
    static func createCustom(name: String, promptText: String) -> TranscriptionPrompt {
        TranscriptionPrompt(
            id: UUID(),
            name: name,
            promptText: promptText,
            isBuiltIn: false
        )
    }
}

// MARK: - Description

extension TranscriptionPrompt {
    /// Short description for UI display
    var description: String {
        switch id.uuidString {
        case "00000000-0000-0000-0000-000000000001":
            return "Raw transcription as spoken"
        case "00000000-0000-0000-0000-000000000002":
            return "Formal business tone"
        default:
            return "Custom prompt"
        }
    }
}
