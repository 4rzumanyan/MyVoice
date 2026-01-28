import Foundation

/// Handles communication with Google's Gemini API for audio transcription
final class GeminiAPIService {
    
    // MARK: - Types
    
    struct TranscriptionResult {
        let text: String
        let success: Bool
        let error: Error?
    }
    
    enum GeminiError: LocalizedError {
        case invalidAPIKey
        case invalidAudioFile
        case networkError(Error)
        case invalidResponse
        case apiError(String)
        case rateLimited
        case fileTooLarge
        
        var errorDescription: String? {
            switch self {
            case .invalidAPIKey:
                return "Invalid or missing API key. Please check your settings."
            case .invalidAudioFile:
                return "Could not read the audio file."
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .invalidResponse:
                return "Invalid response from Gemini API."
            case .apiError(let message):
                return "API error: \(message)"
            case .rateLimited:
                return "Rate limited. Please try again later."
            case .fileTooLarge:
                return "Audio file is too large. Try a shorter recording."
            }
        }
    }
    
    // MARK: - API Configuration
    
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"
    private let maxFileSizeBytes = 20 * 1024 * 1024 // 20MB limit
    
    // MARK: - Public Methods
    
    /// Transcribe audio file using Gemini API
    /// - Parameters:
    ///   - fileURL: URL to the WAV audio file
    ///   - apiKey: Gemini API key
    ///   - model: The Gemini model to use for transcription
    /// - Returns: TranscriptionResult with the transcribed text
    func transcribe(audioFileURL: URL, apiKey: String, model: GeminiModel) async throws -> TranscriptionResult {
        // Validate API key
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw GeminiError.invalidAPIKey
        }
        
        // Read audio file
        let audioData: Data
        do {
            audioData = try Data(contentsOf: audioFileURL)
        } catch {
            throw GeminiError.invalidAudioFile
        }
        
        // Check file size
        guard audioData.count <= maxFileSizeBytes else {
            throw GeminiError.fileTooLarge
        }
        
        // Encode to base64
        let base64Audio = audioData.base64EncodedString()
        
        // Build request
        let endpoint = "\(baseURL)/\(model.apiModelId):generateContent?key=\(apiKey)"
        guard let url = URL(string: endpoint) else {
            throw GeminiError.invalidAPIKey
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Build request body
        let requestBody = GeminiRequest(
            contents: [
                GeminiContent(
                    parts: [
                        GeminiPart(
                            inlineData: GeminiInlineData(
                                mimeType: "audio/wav",
                                data: base64Audio
                            ),
                            text: nil
                        ),
                        GeminiPart(
                            inlineData: nil,
                            text: "Transcribe this audio exactly as spoken. Return only the transcription text, nothing else. If the audio is empty or unclear, return an empty string."
                        )
                    ]
                )
            ]
        )
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(requestBody)
        
        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check HTTP status
        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 200:
                break // Success
            case 429:
                throw GeminiError.rateLimited
            case 400...499:
                if let errorResponse = try? JSONDecoder().decode(GeminiErrorResponse.self, from: data) {
                    throw GeminiError.apiError(errorResponse.error.message)
                }
                throw GeminiError.apiError("Client error: \(httpResponse.statusCode)")
            case 500...599:
                throw GeminiError.apiError("Server error: \(httpResponse.statusCode)")
            default:
                throw GeminiError.invalidResponse
            }
        }
        
        // Parse response
        let decoder = JSONDecoder()
        let geminiResponse: GeminiResponse
        do {
            geminiResponse = try decoder.decode(GeminiResponse.self, from: data)
        } catch {
            print("Failed to decode response: \(String(data: data, encoding: .utf8) ?? "nil")")
            throw GeminiError.invalidResponse
        }
        
        // Extract transcription text
        guard let candidate = geminiResponse.candidates?.first,
              let part = candidate.content?.parts?.first,
              let text = part.text else {
            throw GeminiError.invalidResponse
        }
        
        return TranscriptionResult(
            text: text.trimmingCharacters(in: .whitespacesAndNewlines),
            success: true,
            error: nil
        )
    }
}

// MARK: - API Models

private struct GeminiRequest: Encodable {
    let contents: [GeminiContent]
}

private struct GeminiContent: Encodable {
    let parts: [GeminiPart]
}

private struct GeminiPart: Encodable {
    let inlineData: GeminiInlineData?
    let text: String?
    
    enum CodingKeys: String, CodingKey {
        case inlineData = "inline_data"
        case text
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let inlineData = inlineData {
            try container.encode(inlineData, forKey: .inlineData)
        }
        if let text = text {
            try container.encode(text, forKey: .text)
        }
    }
}

private struct GeminiInlineData: Encodable {
    let mimeType: String
    let data: String
    
    enum CodingKeys: String, CodingKey {
        case mimeType = "mime_type"
        case data
    }
}

// MARK: - Response Models

private struct GeminiResponse: Decodable {
    let candidates: [GeminiCandidate]?
}

private struct GeminiCandidate: Decodable {
    let content: GeminiResponseContent?
}

private struct GeminiResponseContent: Decodable {
    let parts: [GeminiResponsePart]?
}

private struct GeminiResponsePart: Decodable {
    let text: String?
}

private struct GeminiErrorResponse: Decodable {
    let error: GeminiAPIError
}

private struct GeminiAPIError: Decodable {
    let code: Int
    let message: String
    let status: String?
}
