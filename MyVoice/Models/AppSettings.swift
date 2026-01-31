import Foundation
import SwiftUI
import Combine

/// Central settings manager for the app using UserDefaults
final class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    private let defaults = UserDefaults.standard
    
    // MARK: - Keys
    private enum Keys {
        static let apiKey = "geminiApiKey"
        static let geminiModel = "geminiModel"
        static let keyCombo = "keyboardShortcut"
        static let recordingTriggerMode = "recordingTriggerMode"
        static let pasteBehavior = "pasteBehavior"
        static let showFloatingIndicator = "showFloatingIndicator"
        static let showNotification = "showNotification"
        static let customPromptsEnabled = "customPromptsEnabled"
        static let selectedPromptId = "selectedPromptId"
        static let customPrompts = "customPrompts"
    }
    
    // MARK: - Published Properties
    
    /// Gemini API Key
    @Published var apiKey: String {
        didSet {
            defaults.set(apiKey, forKey: Keys.apiKey)
        }
    }
    
    /// Selected Gemini model for transcription
    @Published var geminiModel: GeminiModel {
        didSet {
            defaults.set(geminiModel.rawValue, forKey: Keys.geminiModel)
        }
    }
    
    /// Keyboard shortcut for triggering recording
    @Published var keyCombo: KeyCombo {
        didSet {
            keyCombo.save(to: defaults, key: Keys.keyCombo)
        }
    }

    /// How recording is triggered via the shortcut
    @Published var recordingTriggerMode: RecordingTriggerMode {
        didSet {
            defaults.set(recordingTriggerMode.rawValue, forKey: Keys.recordingTriggerMode)
        }
    }
    
    /// How transcribed text should be output
    @Published var pasteBehavior: PasteBehavior {
        didSet {
            defaults.set(pasteBehavior.rawValue, forKey: Keys.pasteBehavior)
        }
    }
    
    /// Whether to show the floating recording indicator
    @Published var showFloatingIndicator: Bool {
        didSet {
            defaults.set(showFloatingIndicator, forKey: Keys.showFloatingIndicator)
        }
    }
    
    /// Whether to show a notification when transcription is complete
    @Published var showNotification: Bool {
        didSet {
            defaults.set(showNotification, forKey: Keys.showNotification)
        }
    }
    
    /// Whether custom prompts feature is enabled
    @Published var customPromptsEnabled: Bool {
        didSet {
            defaults.set(customPromptsEnabled, forKey: Keys.customPromptsEnabled)
        }
    }
    
    /// Currently selected prompt ID
    @Published var selectedPromptId: UUID {
        didSet {
            defaults.set(selectedPromptId.uuidString, forKey: Keys.selectedPromptId)
        }
    }
    
    /// User-created custom prompts
    @Published var customPrompts: [TranscriptionPrompt] {
        didSet {
            if let data = try? JSONEncoder().encode(customPrompts) {
                defaults.set(data, forKey: Keys.customPrompts)
            }
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        // Load saved values or use defaults
        self.apiKey = defaults.string(forKey: Keys.apiKey) ?? ""
        
        // Load Gemini model
        if let modelRaw = defaults.string(forKey: Keys.geminiModel),
           let model = GeminiModel(rawValue: modelRaw) {
            self.geminiModel = model
        } else {
            self.geminiModel = .flash3
        }
        
        self.keyCombo = KeyCombo.load(from: defaults, key: Keys.keyCombo)

        if let modeRaw = defaults.string(forKey: Keys.recordingTriggerMode),
           let mode = RecordingTriggerMode(rawValue: modeRaw) {
            self.recordingTriggerMode = mode
        } else {
            self.recordingTriggerMode = .tapToToggle
        }
        
        if let pasteBehaviorRaw = defaults.string(forKey: Keys.pasteBehavior),
           let behavior = PasteBehavior(rawValue: pasteBehaviorRaw) {
            self.pasteBehavior = behavior
        } else {
            self.pasteBehavior = .autoPaste
        }
        
        // Default to true for boolean settings if not set
        if defaults.object(forKey: Keys.showFloatingIndicator) == nil {
            defaults.set(true, forKey: Keys.showFloatingIndicator)
        }
        self.showFloatingIndicator = defaults.bool(forKey: Keys.showFloatingIndicator)
        
        if defaults.object(forKey: Keys.showNotification) == nil {
            defaults.set(false, forKey: Keys.showNotification)
        }
        self.showNotification = defaults.bool(forKey: Keys.showNotification)
        
        // Custom prompts settings - default to disabled
        self.customPromptsEnabled = defaults.bool(forKey: Keys.customPromptsEnabled)
        
        // Load selected prompt ID
        if let idString = defaults.string(forKey: Keys.selectedPromptId),
           let id = UUID(uuidString: idString) {
            self.selectedPromptId = id
        } else {
            self.selectedPromptId = TranscriptionPrompt.defaultPrompt.id
        }
        
        // Load custom prompts
        if let data = defaults.data(forKey: Keys.customPrompts),
           let prompts = try? JSONDecoder().decode([TranscriptionPrompt].self, from: data) {
            self.customPrompts = prompts
        } else {
            self.customPrompts = []
        }
    }
    
    // MARK: - Validation
    
    var isApiKeyValid: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var hasValidConfiguration: Bool {
        isApiKeyValid
    }
    
    // MARK: - Prompt Helpers
    
    /// Get all available prompts (built-in + custom)
    var allPrompts: [TranscriptionPrompt] {
        TranscriptionPrompt.builtInPrompts + customPrompts
    }
    
    /// Get the currently active prompt based on settings
    var activePrompt: TranscriptionPrompt {
        guard customPromptsEnabled else {
            return TranscriptionPrompt.defaultPrompt
        }
        
        // Find the selected prompt from all available prompts
        if let prompt = allPrompts.first(where: { $0.id == selectedPromptId }) {
            return prompt
        }
        
        // Fallback to default if selected prompt not found
        return TranscriptionPrompt.defaultPrompt
    }
    
    /// Add a new custom prompt
    func addCustomPrompt(name: String, promptText: String) {
        let newPrompt = TranscriptionPrompt.createCustom(name: name, promptText: promptText)
        customPrompts.append(newPrompt)
    }
    
    /// Delete a custom prompt
    func deleteCustomPrompt(id: UUID) {
        customPrompts.removeAll { $0.id == id }
        // If deleted prompt was selected, reset to default
        if selectedPromptId == id {
            selectedPromptId = TranscriptionPrompt.defaultPrompt.id
        }
    }
    
    /// Update a custom prompt
    func updateCustomPrompt(id: UUID, name: String, promptText: String) {
        if let index = customPrompts.firstIndex(where: { $0.id == id }) {
            customPrompts[index].name = name
            customPrompts[index].promptText = promptText
        }
    }
}
