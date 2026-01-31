import SwiftUI

/// Settings window view
struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var permissions: PermissionsService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            promptsTab
                .tabItem {
                    Label("Prompts", systemImage: "text.bubble")
                }
            
            outputTab
                .tabItem {
                    Label("Output", systemImage: "doc.on.clipboard")
                }
            
            permissionsTab
                .tabItem {
                    Label("Permissions", systemImage: "lock.shield")
                }
        }
        .frame(width: 480, height: 520)
    }
    
    // MARK: - General Tab
    
    private var generalTab: some View {
        Form {
            Section {
                APIKeyEditorView(apiKey: $settings.apiKey)
            } header: {
                Text("API Configuration")
            }
            
            Section {
                Picker("Model", selection: $settings.geminiModel) {
                    ForEach(GeminiModel.allCases) { model in
                        VStack(alignment: .leading) {
                            Text(model.displayName)
                            Text(model.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .tag(model)
                    }
                }
                .pickerStyle(.radioGroup)
            } header: {
                Text("Gemini Model")
            }
            
            Section {
                HStack {
                    Text("Keyboard Shortcut")
                    Spacer()
                    ShortcutRecorderView(keyCombo: $settings.keyCombo)
                        .frame(width: 180)
                }
            } header: {
                Text("Shortcut")
            }

            Section {
                Picker("Recording Method", selection: $settings.recordingTriggerMode) {
                    ForEach(RecordingTriggerMode.allCases) { mode in
                        VStack(alignment: .leading) {
                            Text(mode.displayName)
                            Text(mode.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .tag(mode)
                    }
                }
                .pickerStyle(.radioGroup)
            } header: {
                Text("Recording Behavior")
            }
            
        }
        .formStyle(.grouped)
        .padding()
    }
    
    // MARK: - Prompts Tab
    
    @State private var showingAddPromptSheet = false
    @State private var editingPrompt: TranscriptionPrompt? = nil
    
    private var promptsTab: some View {
        Form {
            Section {
                Toggle("Enable Custom Prompts", isOn: $settings.customPromptsEnabled)
                
                Text("When enabled, you can choose how the AI processes your speech. When disabled, the app will transcribe exactly what you say.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section {
                ForEach(TranscriptionPrompt.builtInPrompts) { prompt in
                    PromptRow(
                        prompt: prompt,
                        isSelected: settings.selectedPromptId == prompt.id,
                        isEnabled: settings.customPromptsEnabled,
                        onSelect: {
                            settings.selectedPromptId = prompt.id
                        },
                        onEdit: nil,
                        onDelete: nil
                    )
                }
            } header: {
                Text("Built-in Prompts")
            }
            .disabled(!settings.customPromptsEnabled)
            
            Section {
                if settings.customPrompts.isEmpty {
                    Text("No custom prompts yet")
                        .foregroundColor(.secondary)
                        .font(.caption)
                } else {
                    ForEach(settings.customPrompts) { prompt in
                        PromptRow(
                            prompt: prompt,
                            isSelected: settings.selectedPromptId == prompt.id,
                            isEnabled: settings.customPromptsEnabled,
                            onSelect: {
                                settings.selectedPromptId = prompt.id
                            },
                            onEdit: {
                                editingPrompt = prompt
                            },
                            onDelete: {
                                settings.deleteCustomPrompt(id: prompt.id)
                            }
                        )
                    }
                }
                
                Button {
                    showingAddPromptSheet = true
                } label: {
                    Label("Add Custom Prompt", systemImage: "plus.circle")
                }
                .disabled(!settings.customPromptsEnabled)
            } header: {
                Text("Custom Prompts")
            }
            .disabled(!settings.customPromptsEnabled)
        }
        .formStyle(.grouped)
        .padding()
        .sheet(isPresented: $showingAddPromptSheet) {
            PromptEditorSheet(
                mode: .add,
                onSave: { name, promptText in
                    settings.addCustomPrompt(name: name, promptText: promptText)
                }
            )
        }
        .sheet(item: $editingPrompt) { prompt in
            PromptEditorSheet(
                mode: .edit(prompt),
                onSave: { name, promptText in
                    settings.updateCustomPrompt(id: prompt.id, name: name, promptText: promptText)
                }
            )
        }
    }
    
    // MARK: - Output Tab
    
    private var outputTab: some View {
        Form {
            Section {
                Picker("Paste Behavior", selection: $settings.pasteBehavior) {
                    ForEach(PasteBehavior.allCases) { behavior in
                        VStack(alignment: .leading) {
                            Text(behavior.displayName)
                            Text(behavior.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .tag(behavior)
                    }
                }
                .pickerStyle(.radioGroup)
            } header: {
                Text("Output Method")
            }
            
            Section {
                Toggle("Show floating indicator while recording", isOn: $settings.showFloatingIndicator)
                
                Toggle("Show notification when transcription completes", isOn: $settings.showNotification)
            } header: {
                Text("Feedback")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
    
    // MARK: - Permissions Tab
    
    private var permissionsTab: some View {
        Form {
            Section {
                PermissionRow(
                    title: "Microphone",
                    description: "Required to record your voice",
                    status: permissions.microphonePermission,
                    action: {
                        if permissions.microphonePermission == .unknown {
                            permissions.requestMicrophonePermission { _ in }
                        } else {
                            permissions.openMicrophonePreferences()
                        }
                    }
                )
                
                PermissionRow(
                    title: "Accessibility",
                    description: "Required to paste text and use global shortcuts",
                    status: permissions.accessibilityPermission,
                    action: {
                        permissions.requestAccessibilityPermission()
                    }
                )
            } header: {
                Text("Required Permissions")
            }
            
            Section {
                Button("Refresh Permission Status") {
                    permissions.checkPermissions()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - API Key Editor View

struct APIKeyEditorView: View {
    @Binding var apiKey: String
    
    @State private var isEditing = false
    @State private var editingKey = ""
    @State private var isValidating = false
    @State private var validationResult: ValidationResult?
    
    enum ValidationResult {
        case valid
        case invalid(String)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isEditing {
                // Edit mode
                editModeView
            } else {
                // Display mode
                displayModeView
            }
            
            // Help text
            Text("Get your API key from [Google AI Studio](https://aistudio.google.com/app/apikey)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Display Mode
    
    private var displayModeView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Gemini API Key")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    if apiKey.isEmpty {
                        Text("Not configured")
                            .foregroundColor(.red)
                            .font(.system(.body, design: .monospaced))
                    } else {
                        Text(maskedApiKey)
                            .font(.system(.body, design: .monospaced))
                        
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
            }
            
            Spacer()
            
            Button(apiKey.isEmpty ? "Add Key" : "Edit") {
                editingKey = apiKey
                isEditing = true
                validationResult = nil
            }
            .buttonStyle(.bordered)
        }
    }
    
    // MARK: - Edit Mode
    
    private var editModeView: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Gemini API Key")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                SecureField("Enter your API key", text: $editingKey)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
            }
            
            // Validation result
            if let result = validationResult {
                validationResultView(result)
            }
            
            // Buttons
            HStack {
                Button("Cancel") {
                    isEditing = false
                    editingKey = ""
                    validationResult = nil
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Test Connection") {
                    Task {
                        await validateApiKey()
                    }
                }
                .buttonStyle(.bordered)
                .disabled(editingKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isValidating)
                
                Button("Save") {
                    saveApiKey()
                }
                .buttonStyle(.borderedProminent)
                .disabled(editingKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isValidating)
            }
            
            if isValidating {
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Validating API key...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    @ViewBuilder
    private func validationResultView(_ result: ValidationResult) -> some View {
        switch result {
        case .valid:
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("API key is valid!")
                    .foregroundColor(.green)
            }
            .font(.caption)
        case .invalid(let message):
            HStack(alignment: .top) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                Text(message)
                    .foregroundColor(.red)
            }
            .font(.caption)
        }
    }
    
    // MARK: - Computed Properties
    
    private var maskedApiKey: String {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 5 else {
            return String(repeating: "*", count: trimmed.count)
        }
        
        let visibleSuffix = String(trimmed.suffix(5))
        let maskedLength = min(trimmed.count - 5, 20) // Show max 20 asterisks
        let masked = String(repeating: "*", count: maskedLength)
        
        return masked + visibleSuffix
    }
    
    // MARK: - Actions
    
    private func saveApiKey() {
        let trimmed = editingKey.trimmingCharacters(in: .whitespacesAndNewlines)
        apiKey = trimmed
        isEditing = false
        editingKey = ""
        validationResult = nil
    }
    
    private func validateApiKey() async {
        let trimmed = editingKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        isValidating = true
        validationResult = nil
        
        // Test the API key with a simple request
        let result = await testGeminiApiKey(trimmed)
        
        await MainActor.run {
            isValidating = false
            validationResult = result
        }
    }
    
    private func testGeminiApiKey(_ key: String) async -> ValidationResult {
        // Use the models.list endpoint to validate the API key
        // This is a lightweight call that just lists available models
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models?key=\(key)"
        
        guard let url = URL(string: urlString) else {
            return .invalid("Invalid API key format")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200:
                    return .valid
                case 400:
                    // Try to parse error message
                    if let errorInfo = parseGeminiError(from: data) {
                        return .invalid(errorInfo)
                    }
                    return .invalid("Bad request. Please check your API key.")
                case 401, 403:
                    return .invalid("Invalid API key. Please check that you copied the key correctly.")
                case 404:
                    return .invalid("API endpoint not found. The API may have changed.")
                case 429:
                    return .invalid("Rate limited. Your API key is valid but you've exceeded the quota.")
                default:
                    return .invalid("Unexpected error (HTTP \(httpResponse.statusCode))")
                }
            }
            
            return .invalid("Could not validate API key")
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet:
                return .invalid("No internet connection. Please check your network.")
            case .timedOut:
                return .invalid("Connection timed out. Please try again.")
            default:
                return .invalid("Network error: \(error.localizedDescription)")
            }
        } catch {
            return .invalid("Error: \(error.localizedDescription)")
        }
    }
    
    private func parseGeminiError(from data: Data) -> String? {
        struct ErrorResponse: Decodable {
            let error: ErrorDetail
            struct ErrorDetail: Decodable {
                let message: String
            }
        }
        
        if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
            return errorResponse.error.message
        }
        return nil
    }
}

// MARK: - Permission Row

struct PermissionRow: View {
    let title: String
    let description: String
    let status: PermissionsService.PermissionStatus
    let action: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .fontWeight(.medium)
                    
                    statusBadge
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if status != .granted {
                Button(status == .unknown ? "Grant" : "Open Settings") {
                    action()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private var statusBadge: some View {
        switch status {
        case .granted:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .denied, .restricted:
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
        case .unknown:
            Image(systemName: "questionmark.circle.fill")
                .foregroundColor(.orange)
        }
    }
}

// MARK: - Prompt Row

struct PromptRow: View {
    let prompt: TranscriptionPrompt
    let isSelected: Bool
    let isEnabled: Bool
    let onSelect: () -> Void
    let onEdit: (() -> Void)?
    let onDelete: (() -> Void)?
    
    var body: some View {
        HStack {
            Button(action: onSelect) {
                HStack {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(prompt.name)
                            .fontWeight(isSelected ? .medium : .regular)
                        
                        Text(prompt.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            if let onEdit = onEdit {
                Button("Edit") {
                    onEdit()
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }
            
            if let onDelete = onDelete {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 4)
        .opacity(isEnabled ? 1.0 : 0.5)
    }
}

// MARK: - Prompt Editor Sheet

struct PromptEditorSheet: View {
    enum Mode {
        case add
        case edit(TranscriptionPrompt)
    }
    
    let mode: Mode
    let onSave: (String, String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var promptText: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text(isEditing ? "Edit Prompt" : "New Prompt")
                    .font(.headline)
                
                Spacer()
                
                Button("Save") {
                    onSave(name.trimmingCharacters(in: .whitespacesAndNewlines), 
                           promptText.trimmingCharacters(in: .whitespacesAndNewlines))
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
            }
            .padding()
            
            Divider()
            
            // Form
            Form {
                Section {
                    TextField("Prompt Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                } header: {
                    Text("Name")
                } footer: {
                    Text("A short name to identify this prompt")
                }
                
                Section {
                    TextEditor(text: $promptText)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 150)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                } header: {
                    Text("Prompt Text")
                } footer: {
                    Text("Instructions for how the AI should process your speech. The audio will be sent along with this prompt.")
                }
            }
            .formStyle(.grouped)
            .padding()
        }
        .frame(width: 500, height: 400)
        .onAppear {
            if case .edit(let prompt) = mode {
                name = prompt.name
                promptText = prompt.promptText
            }
        }
    }
    
    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }
    
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Preview

#Preview {
    SettingsView(
        settings: AppSettings.shared,
        permissions: PermissionsService.shared
    )
}
