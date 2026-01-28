import SwiftUI

/// Onboarding view that guides users through granting required permissions
struct OnboardingView: View {
    @ObservedObject var permissions: PermissionsService
    var onComplete: () -> Void

    @State private var isCheckingPermissions = false

    var body: some View {
        VStack(spacing: 24) {
            header

            infoBanner

            VStack(alignment: .leading, spacing: 16) {
                Text("Enable Permissions")
                    .font(.headline)

                PermissionStepView(
                    step: "1",
                    icon: "mic.fill",
                    title: "Microphone",
                    description: "Allows MyVoice to record your voice for transcription.",
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

                PermissionStepView(
                    step: "2",
                    icon: "accessibility",
                    title: "Accessibility",
                    description: "Enables global shortcuts and auto‑paste into other apps.",
                    status: permissions.accessibilityPermission,
                    actionTitle: "Open System Settings",
                    action: {
                        permissions.requestAccessibilityPermission()
                    },
                    isRequired: true
                )
            }
            .padding(.horizontal, 28)

            Spacer()

            statusMessage

            actions
        }
        .frame(width: 520, height: 560)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var header: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 64, height: 64)
                Image(systemName: "mic.waveform")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.accentColor)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Welcome to MyVoice")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Grant permissions to start recording with global shortcuts.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.top, 18)
        .padding(.horizontal, 28)
    }

    private var infoBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.accentColor)
            Text("You can change permissions later in Settings → Privacy & Security.")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 28)
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button(action: {
                if allRequiredPermissionsGranted {
                    onComplete()
                } else {
                    isCheckingPermissions = true
                    permissions.checkPermissions()

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
                    Text(allRequiredPermissionsGranted ? "Start Using MyVoice" : "Check Permissions")
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
        .padding(.horizontal, 28)
        .padding(.bottom, 24)
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
                Text("All set. You can start recording now.")
                    .foregroundColor(.green)
            }
            .font(.subheadline)
            .padding(.horizontal, 28)
        } else {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Permissions are required for global shortcuts to work.")
                    .foregroundColor(.secondary)
            }
            .font(.subheadline)
            .padding(.horizontal, 28)
        }
    }
}

// MARK: - Permission Step View

struct PermissionStepView: View {
    let step: String
    let icon: String
    let title: String
    let description: String
    let status: PermissionsService.PermissionStatus
    var actionTitle: String = "Grant"
    let action: () -> Void
    var isRequired: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(statusColor)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("Step \(step)")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.15))
                        .foregroundColor(.secondary)
                        .cornerRadius(4)

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
