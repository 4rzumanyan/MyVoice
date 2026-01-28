import SwiftUI
import AppKit

/// Floating indicator window that shows recording status at the top center of the screen
struct FloatingIndicatorView: View {
    @ObservedObject var viewModel: AppViewModel
    
    @State private var pulseAnimation = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Pulsing indicator dot
            Circle()
                .fill(indicatorColor)
                .frame(width: 10, height: 10)
                .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                .opacity(pulseAnimation ? 0.7 : 1.0)
            
            // Status text
            Group {
                if viewModel.recordingState.isRecording {
                    HStack(spacing: 4) {
                        Text("Recording")
                        Text(formatDuration(viewModel.audioRecorder.recordingDuration))
                            .fontWeight(.medium)
                    }
                } else if viewModel.recordingState.isProcessing {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.6)
                        Text("Transcribing...")
                    }
                }
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.8))
        )
        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 0.8)
                .repeatForever(autoreverses: true)
            ) {
                pulseAnimation = true
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
}

// MARK: - Floating Window Controller

/// Manages the floating indicator window
final class FloatingIndicatorWindowController: NSWindowController {
    
    convenience init(viewModel: AppViewModel) {
        let window = FloatingIndicatorWindow()
        self.init(window: window)
        
        let hostingView = NSHostingView(rootView: FloatingIndicatorView(viewModel: viewModel))
        hostingView.frame = NSRect(x: 0, y: 0, width: 160, height: 40)
        
        window.contentView = hostingView
        window.setContentSize(hostingView.fittingSize)
        
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
        ignoresMouseEvents = true // Click-through
    }
}

// MARK: - Preview

#Preview {
    FloatingIndicatorView(viewModel: AppViewModel())
        .padding()
        .background(Color.gray)
}
