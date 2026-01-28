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
            
            outputTab
                .tabItem {
                    Label("Output", systemImage: "doc.on.clipboard")
                }
            
            permissionsTab
                .tabItem {
                    Label("Permissions", systemImage: "lock.shield")
                }
        }
        .frame(width: 480, height: 360)
    }
    
    // MARK: - General Tab
    
    private var generalTab: some View {
        Form {
            Section {
                SecureField("Gemini API Key", text: $settings.apiKey)
                    .textFieldStyle(.roundedBorder)
                
                Text("Get your API key from [Google AI Studio](https://aistudio.google.com/app/apikey)")
                    .font(.caption)
                    .foregroundColor(.secondary)
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
                
                Text("Hold the shortcut to record, release to transcribe")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Push-to-Talk Shortcut")
            }
        }
        .formStyle(.grouped)
        .padding()
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

// MARK: - Preview

#Preview {
    SettingsView(
        settings: AppSettings.shared,
        permissions: PermissionsService.shared
    )
}
