import SwiftUI
import AppKit

/// Floating indicator window that shows recording status at the top center of the screen
struct FloatingIndicatorView: View {
    @ObservedObject var viewModel: AppViewModel
    
    @State private var pulseAnimation = false
    @State private var processingMessageIndex = 0
    private let processingMessageTimer = Timer.publish(every: 2.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 12) {
            if viewModel.recordingState.isRecording {
                HStack(spacing: 12) {
                    Circle()
                        .fill(indicatorColor)
                        .frame(width: 18, height: 18)
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                        .opacity(pulseAnimation ? 0.7 : 1.0)

                    HStack(spacing: 4) {
                        Text("Recording")
                        Text(formatDuration(viewModel.recordingDuration))
                            .fontWeight(.medium)
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)

                    Button {
                        viewModel.cancelRecording()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color.gray.opacity(0.85))
                            .font(.system(size: 21, weight: .semibold))
                            .frame(width: 18, height: 18, alignment: .center)
                    }
                    .buttonStyle(.plain)
                    .help("Cancel recording")
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.85))
                )
            } else if viewModel.recordingState.isProcessing {
                HStack(spacing: 12) {
                    Circle()
                        .fill(indicatorColor)
                        .frame(width: 18, height: 18)
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                        .opacity(pulseAnimation ? 0.7 : 1.0)

                    Text(currentProcessingMessage)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(width: 18, height: 18, alignment: .center)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.85))
                )
            }
        }
        .frame(width: 260, alignment: .center)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 0.8)
                .repeatForever(autoreverses: true)
            ) {
                pulseAnimation = true
            }
        }
        .onChange(of: viewModel.recordingState) { _ in
            if !pulseAnimation {
                withAnimation(
                    .easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true)
                ) {
                    pulseAnimation = true
                }
            }
            if !viewModel.recordingState.isProcessing {
                processingMessageIndex = 0
            }
        }
        .onReceive(processingMessageTimer) { _ in
            guard viewModel.recordingState.isProcessing else { return }
            let maxIndex = max(0, processingMessages.count - 1)
            if processingMessageIndex < maxIndex {
                processingMessageIndex += 1
            }
        }
    }
    
    private var indicatorColor: Color {
        switch viewModel.recordingState {
        case .recording:
            return .red
        case .processing:
            return .orange
        default:
            return .gray
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var processingMessages: [String] {
        var messages = [
            "Uploading audio...",
            "Listening carefully...",
            "Extracting words..."
        ]

        if settingsUsesCustomPrompt {
            messages.append("Applying the \"\(viewModel.settings.activePrompt.name)\" prompt...")
        }
        
        if settingsUsesTranslation {
            messages.append("Translating to \(viewModel.settings.outputLanguage.name)...")
        }

        messages.append(contentsOf: [
            "Cleaning up text...",
            "Polishing punctuation...",
            "Finalizing response...",
            "Almost there..."
        ])

        return messages
    }

    private var currentProcessingMessage: String {
        let messages = processingMessages
        let index = min(processingMessageIndex, messages.count - 1)
        return messages[index]
    }

    private var settingsUsesCustomPrompt: Bool {
        viewModel.settings.customPromptsEnabled &&
        viewModel.settings.activePrompt.id != TranscriptionPrompt.defaultPrompt.id
    }
    
    private var settingsUsesTranslation: Bool {
        viewModel.settings.customPromptsEnabled &&
        viewModel.settings.translateOutputEnabled
    }
}

// MARK: - Floating Window Controller

/// Manages the floating indicator window
final class FloatingIndicatorWindowController: NSWindowController {
    
    convenience init(viewModel: AppViewModel) {
        let window = FloatingIndicatorWindow()
        self.init(window: window)
        
        let hostingView = NSHostingView(rootView: FloatingIndicatorView(viewModel: viewModel))
        hostingView.frame = NSRect(x: 0, y: 0, width: 260, height: 60)
        
        window.contentView = hostingView
        window.setContentSize(NSSize(width: 260, height: 60))
        
        positionWindow()
    }
    
    func positionWindow() {
        guard let window = window, let screen = NSScreen.main else { return }
        
        let screenFrame = screen.frame
        let windowSize = window.frame.size
        
        // Position at top center, below the notch/menu bar area
        let x = (screenFrame.width - windowSize.width) / 2 + screenFrame.origin.x
        let y = screenFrame.maxY - 60 // Below menu bar
        
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    func show() {
        positionWindow()
        window?.orderFront(nil)
    }
    
    func hide() {
        window?.orderOut(nil)
    }
}

// MARK: - Floating Window

/// A borderless, floating window for the indicator
final class FloatingIndicatorWindow: NSWindow {
    
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 160, height: 40),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Window configuration
        isOpaque = false
        backgroundColor = .clear
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        isMovableByWindowBackground = false
        hasShadow = false
        ignoresMouseEvents = false
    }
}

// MARK: - Preview

#Preview {
    FloatingIndicatorView(viewModel: AppViewModel())
        .padding()
        .background(Color.gray)
}
