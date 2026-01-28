import SwiftUI

/// The menu that appears when clicking the menu bar icon
struct MenuBarView: View {
    @ObservedObject var viewModel: AppViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Status header
            statusHeader
            
            Divider()
                .padding(.vertical, 4)
            
            // Actions
            actionButtons
            
            Divider()
                .padding(.vertical, 4)
            
            // Last transcription preview
            if !viewModel.lastTranscription.isEmpty {
                lastTranscriptionSection
                
                Divider()
                    .padding(.vertical, 4)
            }
            
            // Settings and Quit
            bottomButtons
        }
        .padding(8)
        .frame(width: 280)
    }
    
    // MARK: - Subviews
    
    private var statusHeader: some View {
        HStack {
            Image(systemName: viewModel.recordingState.iconName)
                .foregroundColor(iconColor)
                .font(.system(size: 16, weight: .medium))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("MyVoice")
                    .font(.headline)
                
                Text(viewModel.recordingState.statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if viewModel.recordingState.isRecording {
                recordingDuration
            }
        }
        .padding(.vertical, 4)
    }
    
    private var recordingDuration: some View {
        Text(formatDuration(viewModel.audioRecorder.recordingDuration))
            .font(.system(.caption, design: .monospaced))
            .foregroundColor(.red)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.red.opacity(0.1))
            .cornerRadius(4)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 4) {
            if viewModel.recordingState.isRecording {
                MenuButton(
                    title: "Cancel Recording",
                    icon: "stop.fill",
                    shortcut: "Release \(viewModel.settings.keyCombo.displayString)"
                ) {
                    viewModel.cancelRecording()
                }
                .foregroundColor(.red)
                
                Text("Release shortcut to transcribe")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            } else if viewModel.recordingState.isProcessing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Transcribing...")
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            } else {
                MenuButton(
                    title: "Start Recording",
                    icon: "mic.fill",
                    shortcut: viewModel.settings.keyCombo.displayString
                ) {
                    viewModel.startRecording()
                }
            }
        }
    }
    
    private var lastTranscriptionSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Last Transcription")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(viewModel.lastTranscription)
                .font(.subheadline)
                .lineLimit(3)
                .truncationMode(.tail)
            
            Button("Copy to Clipboard") {
                viewModel.pasteService.copyToClipboard(viewModel.lastTranscription)
            }
            .font(.caption)
            .buttonStyle(.link)
        }
        .padding(.vertical, 4)
    }
    
    private var bottomButtons: some View {
        VStack(spacing: 4) {
            MenuButton(title: "Settings...", icon: "gear") {
                viewModel.openSettings()
            }
            
            MenuButton(title: "Quit MyVoice", icon: "power") {
                viewModel.quitApp()
            }
        }
    }
    
    // MARK: - Helpers
    
    private var iconColor: Color {
        switch viewModel.recordingState {
        case .idle:
            return .primary
        case .recording:
            return .red
        case .processing:
            return .orange
        case .error:
            return .red
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Menu Button

struct MenuButton: View {
    let title: String
    let icon: String
    var shortcut: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 20)
                
                Text(title)
                
                Spacer()
                
                if let shortcut = shortcut {
                    Text(shortcut)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.primary.opacity(0.001)) // For hit testing
        .cornerRadius(4)
    }
}
