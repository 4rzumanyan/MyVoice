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
    }
    
    // MARK: - Validation
    
    var isApiKeyValid: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var hasValidConfiguration: Bool {
        isApiKeyValid
    }
}
