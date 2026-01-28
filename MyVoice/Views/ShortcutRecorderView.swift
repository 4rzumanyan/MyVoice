import SwiftUI

/// A view for recording keyboard shortcuts
struct ShortcutRecorderView: View {
    @Binding var keyCombo: KeyCombo
    @StateObject private var recorder = HotkeyService.ShortcutRecorder()
    @State private var isHovering = false
    
    var body: some View {
        Button(action: toggleRecording) {
            HStack {
                if recorder.isRecording {
                    Text(recorder.currentDisplay)
                        .foregroundColor(.secondary)
                } else {
                    Text(keyCombo.displayString)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                if recorder.isRecording {
                    Text("ESC to cancel")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else if isHovering {
                    Text("Click to record")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(recorder.isRecording ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(recorder.isRecording ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .onAppear {
            recorder.onRecordComplete = { result in
                switch result {
                case .recorded(let newCombo):
                    keyCombo = newCombo
                case .cancelled:
                    break
                case .cleared:
                    keyCombo = .defaultCombo
                }
            }
        }
    }
    
    private func toggleRecording() {
        if recorder.isRecording {
            recorder.cancelRecording()
        } else {
            recorder.startRecording()
        }
    }
}

// MARK: - Preview

#Preview {
    ShortcutRecorderView(keyCombo: .constant(.defaultCombo))
        .padding()
        .frame(width: 300)
}
