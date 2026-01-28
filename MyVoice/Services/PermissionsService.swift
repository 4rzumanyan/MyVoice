import Foundation
import AVFoundation
import AppKit
import ApplicationServices

/// Manages permission requests and checks for microphone and accessibility
final class PermissionsService: ObservableObject {
    static let shared = PermissionsService()
    
    @Published private(set) var microphonePermission: PermissionStatus = .unknown
    @Published private(set) var accessibilityPermission: PermissionStatus = .unknown
    
    private var permissionCheckTimer: Timer?
    
    enum PermissionStatus: Equatable {
        case unknown
        case granted
        case denied
        case restricted
    }
    
    private init() {
        checkPermissions()
        // Start periodic checking for accessibility permission changes
        startPermissionMonitoring()
    }
    
    deinit {
        permissionCheckTimer?.invalidate()
    }
    
    // MARK: - Permission Monitoring
    
    private func startPermissionMonitoring() {
        // Check permissions every 2 seconds to catch changes
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkPermissions()
        }
    }
    
    // MARK: - Check Permissions
    
    func checkPermissions() {
        checkMicrophonePermission()
        checkAccessibilityPermission()
    }
    
    func checkMicrophonePermission() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            updateMicrophonePermission(.granted)
        case .denied:
            updateMicrophonePermission(.denied)
        case .restricted:
            updateMicrophonePermission(.restricted)
        case .notDetermined:
            updateMicrophonePermission(.unknown)
        @unknown default:
            updateMicrophonePermission(.unknown)
        }
    }
    
    private func updateMicrophonePermission(_ status: PermissionStatus) {
        if microphonePermission != status {
            DispatchQueue.main.async {
                self.microphonePermission = status
            }
        }
    }
    
    func checkAccessibilityPermission() {
        // Check without prompting
        let trusted = AXIsProcessTrusted()
        let newStatus: PermissionStatus = trusted ? .granted : .denied
        
        if accessibilityPermission != newStatus {
            DispatchQueue.main.async {
                self.accessibilityPermission = newStatus
            }
        }
    }
    
    // MARK: - Request Permissions
    
    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            DispatchQueue.main.async {
                self?.microphonePermission = granted ? .granted : .denied
                completion(granted)
            }
        }
    }
    
    func requestAccessibilityPermission() {
        // Prompt the system dialog
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        
        DispatchQueue.main.async {
            self.accessibilityPermission = trusted ? .granted : .denied
        }
        
        if !trusted {
            // Open System Settings to Accessibility pane
            openAccessibilityPreferences()
        }
    }
    
    func openAccessibilityPreferences() {
        // Use the newer URL format for macOS Ventura and later
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func openMicrophonePreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
            NSWorkspace.shared.open(url)
        }
    }
    
    // MARK: - Status Helpers
    
    var allPermissionsGranted: Bool {
        microphonePermission == .granted && accessibilityPermission == .granted
    }
    
    var permissionSummary: String {
        var issues: [String] = []
        
        if microphonePermission != .granted {
            issues.append("Microphone access required")
        }
        if accessibilityPermission != .granted {
            issues.append("Accessibility access required for global shortcuts and auto-paste")
        }
        
        return issues.isEmpty ? "All permissions granted" : issues.joined(separator: "\n")
    }
}
