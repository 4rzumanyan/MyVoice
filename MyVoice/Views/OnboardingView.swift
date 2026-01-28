import SwiftUI

/// Onboarding view that guides users through granting required permissions
struct OnboardingView: View {
    @ObservedObject var permissions: PermissionsService
    var onComplete: () -> Void
    
    @State private var isCheckingPermissions = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "mic.badge.xmark")
                    .font(.system(size: 64))
                    .foregroundColor(.accentColor)
                
                Text("Welcome to MyVoice")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Voice-to-text transcription with push-to-talk")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)
            
            Divider()
                .padding(.horizontal, 40)
            
            // Permissions section
            VStack(alignment: .leading, spacing: 20) {
                Text("Required Permissions")
                    .font(.headline)
                
                // Microphone permission
                PermissionItemView(
                    icon: "mic.fill",
                    title: "Microphone Access",
                    description: "Required to record your voice for transcription",
                    status: permissions.microphonePermission,
                    actionTitle: permissions.microphonePermission == .unknown ? "Grant Access" : "Open Settings",
                    action: {
                        if permissions.microphonePermission == .unknown {
                            permissions.requestMicrophonePermission { _ in }
                        } else {
                            permissions.openMicrophonePreferences()
                        }
                    }
                )
                
                // Accessibility permission
                PermissionItemView(
                    icon: "accessibility",
                    title: "Accessibility Access",
                    description: "Required for global keyboard shortcuts to work anywhere on your Mac",
                    status: permissions.accessibilityPermission,
                    actionTitle: "Open System Settings",
                    action: {
                        permissions.requestAccessibilityPermission()
                    },
                    isRequired: true
                )
            }
            .padding(.horizontal, 30)
            
            Spacer()
            
            // Status message
            statusMessage
            
            // Continue button
            VStack(spacing: 12) {
                Button(action: {
                    if allRequiredPermissionsGranted {
                        onComplete()
                    } else {
                        isCheckingPermissions = true
                        permissions.checkPermissions()
                        
                        // Reset after a moment
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            isCheckingPermissions = false
                        }
                    }
                }) {
                    HStack {
                        if isCheckingPermissions {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 16, height: 16)
                        }
                        Text(allRequiredPermissionsGranted ? "Get Started" : "Check Permissions")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isCheckingPermissions)
                
                if !allRequiredPermissionsGranted {
                    Button("Skip for Now") {
                        onComplete()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .font(.caption)
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 24)
        }
        .frame(width: 450, height: 550)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private var allRequiredPermissionsGranted: Bool {
        permissions.microphonePermission == .granted &&
        permissions.accessibilityPermission == .granted
    }
    
    @ViewBuilder
    private var statusMessage: some View {
        if allRequiredPermissionsGranted {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("All permissions granted! You're ready to go.")
                    .foregroundColor(.green)
            }
            .font(.subheadline)
            .padding(.horizontal, 30)
        } else {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Please grant the required permissions above")
                    .foregroundColor(.secondary)
            }
            .font(.subheadline)
            .padding(.horizontal, 30)
        }
    }
}

// MARK: - Permission Item View

struct PermissionItemView: View {
    let icon: String
    let title: String
    let description: String
    let status: PermissionsService.PermissionStatus
    var actionTitle: String = "Grant"
    let action: () -> Void
    var isRequired: Bool = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(statusColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.headline)
                    
                    if isRequired {
                        Text("Required")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.15))
                            .foregroundColor(.red)
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    statusBadge
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                if status != .granted {
                    Button(actionTitle) {
                        action()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch status {
        case .granted:
            return .green
        case .denied, .restricted:
            return .red
        case .unknown:
            return .orange
        }
    }
    
    @ViewBuilder
    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: statusIcon)
            Text(statusText)
        }
        .font(.caption)
        .foregroundColor(statusColor)
    }
    
    private var statusIcon: String {
        switch status {
        case .granted:
            return "checkmark.circle.fill"
        case .denied, .restricted:
            return "xmark.circle.fill"
        case .unknown:
            return "questionmark.circle.fill"
        }
    }
    
    private var statusText: String {
        switch status {
        case .granted:
            return "Granted"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        case .unknown:
            return "Not Set"
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(permissions: PermissionsService.shared) {
        print("Onboarding complete")
    }
}
