# AGENTS.md - MyVoice Development Guide

Guidelines for AI coding agents working on the MyVoice codebase.

## Project Overview

MyVoice is a macOS menu bar app for voice-to-text transcription using Google's Gemini API.
- **Platform:** macOS 13.0+ | **Language:** Swift 5.0 | **UI:** SwiftUI | **Architecture:** MVVM + Services

## Build Commands

```bash
# Build Debug
xcodebuild -project MyVoice.xcodeproj -scheme MyVoice -configuration Debug build

# Build Release
xcodebuild -project MyVoice.xcodeproj -scheme MyVoice -configuration Release build

# Clean Build
xcodebuild -project MyVoice.xcodeproj -scheme MyVoice clean build
```

## Test Commands

```bash
# Run all tests
xcodebuild test -project MyVoice.xcodeproj -scheme MyVoice

# Run single test class
xcodebuild test -project MyVoice.xcodeproj -scheme MyVoice -only-testing:MyVoiceTests/TestClassName

# Run single test method
xcodebuild test -project MyVoice.xcodeproj -scheme MyVoice -only-testing:MyVoiceTests/TestClassName/testMethodName
```

Note: Tests directory is `MyVoiceTests/`. Currently no tests exist.

## Project Structure

```
MyVoice/
├── MyVoiceApp.swift           # App entry point & AppDelegate
├── Info.plist                 # App config & permissions
├── Models/                    # Data models and enums
│   ├── RecordingState.swift   # Recording lifecycle state
│   ├── GeminiModel.swift      # API model options
│   ├── AppSettings.swift      # UserDefaults-backed settings
│   └── KeyCombo.swift         # Keyboard shortcut model
├── Services/                  # Business logic
│   ├── AudioRecorderService.swift
│   ├── GeminiAPIService.swift
│   ├── HotkeyService.swift
│   └── PasteService.swift
├── ViewModels/
│   └── AppViewModel.swift     # Main coordinator
└── Views/                     # SwiftUI views
    ├── MenuBarView.swift
    ├── SettingsView.swift
    └── FloatingIndicatorView.swift
```

## Code Style

### Imports
Order: Foundation first, then Apple frameworks, then Combine. One per line:
```swift
import Foundation
import SwiftUI
import Combine
```

### File Organization
Use `// MARK: -` to organize sections:
```swift
// MARK: - Properties
// MARK: - Initialization  
// MARK: - Public Methods
// MARK: - Private Methods
```

### Naming Conventions
- **Types:** PascalCase (`RecordingState`, `GeminiAPIService`)
- **Properties/Methods:** camelCase (`apiKey`, `startRecording()`)
- **Enums:** PascalCase type, camelCase cases (`case idle`, `case recording`)

### Type Patterns

**Services** - Use `final class`:
```swift
final class GeminiAPIService {
    // ...
}
```

**Models** - Prefer `struct`:
```swift
struct TranscriptionResult {
    let text: String
    let success: Bool
}
```

**State Enums** - Include computed properties:
```swift
enum RecordingState: Equatable {
    case idle
    case recording
    case error(String)
    
    var isRecording: Bool {
        if case .recording = self { return true }
        return false
    }
}
```

### Error Handling
Define as nested `LocalizedError` enums within services:
```swift
enum GeminiError: LocalizedError {
    case invalidAPIKey(String?)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey(let details):
            return "Invalid API key: \(details ?? "unknown")"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
```

### Async/Await
Use Swift concurrency for all async operations:
```swift
func transcribe(audioFileURL: URL) async throws -> TranscriptionResult {
    let (data, response) = try await URLSession.shared.data(for: request)
    // ...
}
```

### Access Control
- Default to `private` for implementation details
- Use `private(set)` for read-only published properties:
```swift
@Published private(set) var isRecording = false
```

### MainActor
Use `@MainActor` for UI-related classes:
```swift
@MainActor
final class AppViewModel: ObservableObject {
    // ...
}
```

### Singletons
Use for app-wide services:
```swift
final class AppSettings: ObservableObject {
    static let shared = AppSettings()
    private init() { }
}
```

### UserDefaults Keys
Use a private enum:
```swift
private enum Keys {
    static let apiKey = "geminiApiKey"
}
```

### SwiftUI Views
- `@ObservedObject` for injected observables
- `@State` for local view state
- Extract subviews as private computed properties
- Add `#Preview` macro for Xcode previews

## Adding New Files

When creating new files, you must also update `project.pbxproj` to include them in the Xcode project.

**New Model:** Create in `MyVoice/Models/`, use struct or enum
**New Service:** Create in `MyVoice/Services/`, use `final class` with nested error enum
**New View:** Create in `MyVoice/Views/`, import SwiftUI, add `#Preview`

## Permissions

The app requires:
- **Microphone:** For voice recording
- **Accessibility:** For global hotkeys and auto-paste
