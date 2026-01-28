import SwiftUI
import AppKit
import Combine

/// Main application entry point
@main
struct MyVoiceApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Settings window - using WindowGroup for better control
        WindowGroup("Settings", id: "settings") {
            SettingsView(
                settings: AppSettings.shared,
                permissions: PermissionsService.shared
            )
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}

// MARK: - App Delegate

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var floatingWindowController: FloatingIndicatorWindowController?
    private var settingsWindowController: NSWindowController?
    private var onboardingWindowController: NSWindowController?
    
    private var viewModel: AppViewModel!
    private var cancellables = Set<AnyCancellable>()
    
    
    nonisolated func applicationDidFinishLaunching(_ notification: Notification) {
        Task { @MainActor in
            await setupApp()
        }
    }
    
    private func setupApp() async {
        viewModel = AppViewModel()
        setupStatusItem()
        setupPopover()
        setupFloatingIndicator()
        observeState()
        
        // Hide dock icon (we're a menu bar app)
        NSApp.setActivationPolicy(.accessory)
        
        // Close any windows that might have opened at launch
        for window in NSApp.windows {
            if window.title == "Settings" || window.identifier?.rawValue == "settings" {
                window.close()
            }
        }

        // Show onboarding if permissions are missing
        checkAndShowOnboardingIfNeeded()
    }

    // MARK: - Onboarding

    private func checkAndShowOnboardingIfNeeded() {
        let permissions = PermissionsService.shared
        if permissions.microphonePermission != .granted || permissions.accessibilityPermission != .granted {
            showOnboarding()
        }
    }

    private func showOnboarding() {
        if onboardingWindowController == nil {
            let onboardingView = OnboardingView(permissions: PermissionsService.shared) { [weak self] in
                self?.dismissOnboarding()
            }
            let hostingController = NSHostingController(rootView: onboardingView)

            let window = NSWindow(contentViewController: hostingController)
            window.title = "Welcome to MyVoice"
            window.styleMask = [.titled, .closable]
            window.setContentSize(NSSize(width: 520, height: 560))
            window.center()
            window.isReleasedWhenClosed = false
            window.level = .floating

            onboardingWindowController = NSWindowController(window: window)
        }

        onboardingWindowController?.showWindow(nil)
        onboardingWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func dismissOnboarding() {
        onboardingWindowController?.close()
        viewModel.hotkeyService.refreshMonitors()
    }
    
    // MARK: - Setup
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "mic", accessibilityDescription: "MyVoice")
            button.action = #selector(togglePopover)
            button.target = self
        }
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 300)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView(viewModel: viewModel)
        )
    }
    
    private func setupFloatingIndicator() {
        floatingWindowController = FloatingIndicatorWindowController(viewModel: viewModel)
    }
    
    // MARK: - State Observation
    
    private func observeState() {
        // Update menu bar icon based on state
        viewModel.$recordingState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateStatusIcon(for: state)
                self?.updateFloatingIndicator(for: state)
            }
            .store(in: &cancellables)
        
        // Open settings window when requested
        viewModel.$showingSettings
            .receive(on: DispatchQueue.main)
            .sink { [weak self] showing in
                if showing {
                    self?.openSettings()
                    self?.viewModel.showingSettings = false
                }
            }
            .store(in: &cancellables)
        
        // Show error alert when needed
        viewModel.$showingError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] showing in
                guard let self = self, showing else { return }
                self.showErrorAlert(message: self.viewModel.errorMessage)
                self.viewModel.showingError = false
            }
            .store(in: &cancellables)
        
        // Watch for accessibility permission changes to refresh hotkey monitors
        PermissionsService.shared.$accessibilityPermission
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                if status == .granted {
                    self?.viewModel.hotkeyService.refreshMonitors()
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateStatusIcon(for state: RecordingState) {
        guard let button = statusItem.button else { return }
        
        let iconName = state.iconName
        var config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        
        switch state {
        case .recording:
            config = config.applying(.init(paletteColors: [.systemRed]))
        case .processing:
            config = config.applying(.init(paletteColors: [.systemOrange]))
        case .error:
            config = config.applying(.init(paletteColors: [.systemRed]))
        case .idle:
            break
        }
        
        button.image = NSImage(systemSymbolName: iconName, accessibilityDescription: "MyVoice")?
            .withSymbolConfiguration(config)
    }
    
    private func updateFloatingIndicator(for state: RecordingState) {
        guard viewModel.settings.showFloatingIndicator else {
            floatingWindowController?.hide()
            return
        }
        
        switch state {
        case .recording, .processing:
            floatingWindowController?.show()
        case .idle, .error:
            floatingWindowController?.hide()
        }
    }
    
    // MARK: - Actions
    
    @objc private func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                
                // Make popover key window so it can receive keyboard input
                popover.contentViewController?.view.window?.makeKey()
            }
        }
    }
    
    private func openSettings() {
        // Close popover first
        popover.performClose(nil)
        
        // Create settings window if needed
        if settingsWindowController == nil {
            let settingsView = SettingsView(
                settings: AppSettings.shared,
                permissions: PermissionsService.shared
            )
            let hostingController = NSHostingController(rootView: settingsView)
            
            let window = NSWindow(contentViewController: hostingController)
            window.title = "MyVoice Settings"
            window.styleMask = [.titled, .closable]
            window.setContentSize(NSSize(width: 500, height: 400))
            window.center()
            
            settingsWindowController = NSWindowController(window: window)
        }
        
        // Show the window
        settingsWindowController?.showWindow(nil)
        settingsWindowController?.window?.makeKeyAndOrderFront(nil)
        
        // Activate app to bring window to front
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func showErrorAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "MyVoice Error"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        
        // Check if there's an API key issue
        if message.lowercased().contains("api key") {
            alert.addButton(withTitle: "Open Settings")
        }
        
        let response = alert.runModal()
        
        if response == .alertSecondButtonReturn {
            openSettings()
        }
    }
}
