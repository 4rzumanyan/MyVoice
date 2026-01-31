import Foundation
import SwiftUI
import Combine
import UserNotifications

/// Main view model that coordinates all app functionality
@MainActor
final class AppViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var recordingState: RecordingState = .idle
    @Published var lastTranscription: String = ""
    @Published var showingSettings = false
    @Published var showingError = false
    @Published var errorMessage = ""
    @Published var recordingDuration: TimeInterval = 0.0
    
    // MARK: - Services
    
    let settings = AppSettings.shared
    let permissions = PermissionsService.shared
    let audioRecorder = AudioRecorderService()
    let hotkeyService = HotkeyService()
    let pasteService = PasteService()
    let geminiService = GeminiAPIService()
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private var currentRecordingURL: URL?
    private var previousAccessibilityState = false
    
    // MARK: - Initialization
    
    init() {
        setupBindings()
        setupHotkey()
        requestNotificationPermission()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Update hotkey when settings change
        settings.$keyCombo
            .sink { [weak self] keyCombo in
                self?.hotkeyService.updateKeyCombo(keyCombo)
            }
            .store(in: &cancellables)
        
        // Watch for accessibility permission changes and refresh hotkey monitors
        permissions.$accessibilityPermission
            .sink { [weak self] status in
                guard let self = self else { return }
                let isGranted = (status == .granted)
                
                // If permission was just granted, refresh the hotkey monitors
                if isGranted && !self.previousAccessibilityState {
                    print("[AppViewModel] Accessibility permission granted - refreshing hotkey monitors")
                    self.hotkeyService.refreshMonitors()
                }
                self.previousAccessibilityState = isGranted
            }
            .store(in: &cancellables)

        audioRecorder.$recordingDuration
            .receive(on: DispatchQueue.main)
            .sink { [weak self] duration in
                self?.recordingDuration = duration
            }
            .store(in: &cancellables)
    }
    
    private func setupHotkey() {
        // Push-to-talk: key down starts recording
        hotkeyService.onHotkeyDown = { [weak self] in
            Task { @MainActor in
                self?.handleHotkeyDown()
            }
        }
        
        // Push-to-talk: key up stops recording and transcribes
        hotkeyService.onHotkeyUp = { [weak self] in
            Task { @MainActor in
                await self?.handleHotkeyUp()
            }
        }
        
        hotkeyService.startListening(for: settings.keyCombo)
        
        // Store initial accessibility state
        previousAccessibilityState = (permissions.accessibilityPermission == .granted)
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
    
    // MARK: - Public Actions
    
    /// Called when hotkey is pressed down - start recording
    func handleHotkeyDown() {
        switch settings.recordingTriggerMode {
        case .holdToRecord:
            switch recordingState {
            case .idle, .error:
                startRecording()
            case .recording, .processing:
                break
            }
        case .tapToToggle:
            switch recordingState {
            case .idle, .error:
                startRecording()
            case .recording:
                Task { @MainActor in
                    await stopRecordingAndTranscribe()
                }
            case .processing:
                break
            }
        }
    }
    
    /// Called when hotkey is released - stop recording and transcribe
    func handleHotkeyUp() async {
        guard settings.recordingTriggerMode == .holdToRecord else { return }
        switch recordingState {
        case .recording:
            await stopRecordingAndTranscribe()
        case .idle, .error, .processing:
            break
        }
    }
    
    func startRecording() {
        // Check permissions first
        permissions.checkPermissions()
        
        guard permissions.microphonePermission == .granted else {
            if permissions.microphonePermission == .unknown {
                permissions.requestMicrophonePermission { [weak self] granted in
                    if granted {
                        self?.startRecording()
                    } else {
                        self?.showError("Microphone permission is required")
                    }
                }
            } else {
                showError("Microphone permission is required. Please enable it in System Settings.")
                permissions.openMicrophonePreferences()
            }
            return
        }
        
        // Check API key
        guard settings.isApiKeyValid else {
            showError("Please configure your Gemini API key in Settings")
            showingSettings = true
            return
        }
        
        do {
            currentRecordingURL = try audioRecorder.startRecording()
            recordingState = .recording
        } catch {
            showError("Failed to start recording: \(error.localizedDescription)")
        }
    }
    
    func stopRecordingAndTranscribe() async {
        guard recordingState == .recording else { return }
        
        // Stop recording
        guard let fileURL = audioRecorder.stopRecording() else {
            showError("No recording to process")
            recordingState = .idle
            return
        }
        
        recordingState = .processing
        
        // Transcribe
        do {
            let result = try await geminiService.transcribe(
                audioFileURL: fileURL,
                apiKey: settings.apiKey,
                model: settings.geminiModel,
                prompt: settings.finalPrompt
            )
            
            // Delete the temporary file
            audioRecorder.deleteRecordingFile()
            
            if result.text.isEmpty {
                showError("No speech detected in the recording")
                recordingState = .idle
                return
            }
            
            lastTranscription = result.text
            
            // Check if we need accessibility for paste
            if settings.pasteBehavior.shouldAutoPaste {
                permissions.checkAccessibilityPermission()
                if permissions.accessibilityPermission != .granted {
                    // Fall back to clipboard only and warn the user
                    pasteService.copyToClipboard(result.text)
                    showError("Accessibility permission required for auto-paste. Text copied to clipboard instead.")
                    recordingState = .idle
                    return
                }
            }
            
            // Output the text based on settings
            do {
                try pasteService.outputText(result.text, behavior: settings.pasteBehavior)
            } catch {
                // If paste fails, at least copy to clipboard
                pasteService.copyToClipboard(result.text)
                showError("Paste failed: \(error.localizedDescription). Text copied to clipboard.")
            }
            
            // Show notification if enabled
            if settings.showNotification {
                showTranscriptionNotification(text: result.text)
            }
            
            recordingState = .idle
            
        } catch {
            // Clean up on error
            audioRecorder.deleteRecordingFile()
            showError(error.localizedDescription)
            recordingState = .idle
        }
    }
    
    func cancelRecording() {
        _ = audioRecorder.stopRecording()
        audioRecorder.deleteRecordingFile()
        recordingState = .idle
    }
    
    func openSettings() {
        showingSettings = true
    }
    
    func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - Error Handling
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
        recordingState = .error(message)
        
        // Auto-dismiss error state after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            if case .error = self?.recordingState {
                self?.recordingState = .idle
            }
        }
    }
    
    // MARK: - Notifications
    
    private func showTranscriptionNotification(text: String) {
        let content = UNMutableNotificationContent()
        content.title = "Transcription Complete"
        content.body = text.count > 100 ? String(text.prefix(100)) + "..." : text
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}
