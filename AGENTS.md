# AGENTS.md - MyVoice Development Guide

This document provides guidelines for AI coding agents working on the MyVoice codebase.

## Project Overview

MyVoice is a macOS menu bar application for voice-to-text transcription using Google's Gemini API.
- **Platform:** macOS 13.0+
- **Language:** Swift 5.0
- **UI Framework:** SwiftUI
- **Architecture:** MVVM with Services layer

## Build Commands

```bash
# Build Release
xcodebuild -project MyVoice.xcodeproj -scheme MyVoice -configuration Release build

# Build Debug
xcodebuild -project MyVoice.xcodeproj -scheme MyVoice -configuration Debug build

# Clean and Build
xcodebuild -project MyVoice.xcodeproj -scheme MyVoice -configuration Release clean build

# Install to Applications (after build)
cp -R ~/Library/Developer/Xcode/DerivedData/MyVoice-*/Build/Products/Release/MyVoice.app /Applications/

# Run the app
open /Applications/MyVoice.app
```

## Project Structure

```
MyVoice/
├── MyVoiceApp.swift              # App entry point & AppDelegate
├── Info.plist                    # App configuration & permissions
├── MyVoice.entitlements          # App entitlements
├── Models/                       # Data models and enums
│   ├── RecordingState.swift      # State enum for recording lifecycle
│   ├── GeminiModel.swift         # Available Gemini API models
│   ├── PasteBehavior.swift       # Output behavior options
│   ├── KeyCombo.swift            # Keyboard shortcut model
│   └── AppSettings.swift         # UserDefaults-backed settings
├── Services/                     # Business logic services
│   ├── AudioRecorderService.swift
│   ├── GeminiAPIService.swift
│   ├── HotkeyService.swift
│   ├── PasteService.swift
│   └── PermissionsService.swift
├── ViewModels/
│   └── AppViewModel.swift        # Main app coordinator
├── Views/                        # SwiftUI views
│   ├── MenuBarView.swift
│   ├── SettingsView.swift
│   ├── OnboardingView.swift
│   ├── FloatingIndicatorView.swift
│   └── ShortcutRecorderView.swift
└── Resources/
    └── Assets.xcassets
```

## Code Style Guidelines

### Imports
- Order: Foundation, then Apple frameworks (AppKit, SwiftUI), then project files
- One import per line, no blank lines between imports
```swift
import Foundation
import SwiftUI
import Combine
```

### File Organization
Use `// MARK: -` comments to organize code sections:
```swift
// MARK: - Properties
// MARK: - Initialization
// MARK: - Public Methods
// MARK: - Private Methods
// MARK: - Helpers
```

### Naming Conventions
- **Types:** PascalCase (`RecordingState`, `GeminiAPIService`)
- **Properties/Methods:** camelCase (`apiKey`, `startRecording()`)
- **Constants:** camelCase in context (`maxFileSizeBytes`)
- **Enums:** PascalCase type, camelCase cases (`case idle`, `case recording`)
- **Protocols:** PascalCase, often ending in `-able` or `-ing`

### Type Declarations

**Classes** - Use `final` for services that won't be subclassed:
```swift
final class GeminiAPIService {
    // ...
}
```

**Structs** - Prefer for models and value types:
```swift
struct TranscriptionResult {
    let text: String
    let success: Bool
}
```

**Enums** - Use for finite states and options:
```swift
enum RecordingState: Equatable {
    case idle
    case recording
    case processing
    case error(String)
}
```

### Error Handling

Define errors as nested enums conforming to `LocalizedError`:
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
Use Swift concurrency for async operations:
```swift
func transcribe(audioFileURL: URL) async throws -> TranscriptionResult {
    let (data, response) = try await URLSession.shared.data(for: request)
    // ...
}
```

### SwiftUI Views

- Use `@ObservedObject` for injected observable objects
- Use `@State` for local view state
- Extract subviews as computed properties or separate structs
- Use `@ViewBuilder` for conditional view logic

```swift
struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        // ...
    }
    
    private var generalTab: some View {
        // ...
    }
}
```

### Documentation

Use `///` for public API documentation:
```swift
/// Transcribe audio file using Gemini API
/// - Parameters:
///   - fileURL: URL to the WAV audio file
///   - apiKey: Gemini API key
/// - Returns: TranscriptionResult with the transcribed text
func transcribe(audioFileURL: URL, apiKey: String) async throws -> TranscriptionResult
```

### Access Control
- Default to `private` for implementation details
- Use `internal` (implicit) for module-internal APIs
- Mark `@Published` properties as `private(set)` when only the class should mutate

```swift
@Published private(set) var isRecording = false
```

## Important Patterns

### Singleton Services
Use shared instances for app-wide services:
```swift
final class AppSettings: ObservableObject {
    static let shared = AppSettings()
    private init() { /* ... */ }
}
```

### UserDefaults Storage
Store settings with explicit keys:
```swift
private enum Keys {
    static let apiKey = "geminiApiKey"
}
```

### MainActor
Use `@MainActor` for UI-related classes:
```swift
@MainActor
final class AppViewModel: ObservableObject {
    // ...
}
```

## Testing Notes

Currently no unit tests. When adding tests:
- Place in `MyVoiceTests/` directory
- Run with: `xcodebuild test -project MyVoice.xcodeproj -scheme MyVoice`
- Run single test: `xcodebuild test -project MyVoice.xcodeproj -scheme MyVoice -only-testing:MyVoiceTests/TestClassName/testMethodName`

## Common Tasks

### Adding a New Model
1. Create file in `MyVoice/Models/`
2. Add to Xcode project (update `project.pbxproj`)
3. Use appropriate type (enum for states, struct for data)

### Adding a New Service
1. Create file in `MyVoice/Services/`
2. Use `final class` with singleton if needed
3. Define errors as nested `LocalizedError` enum
4. Add to Xcode project

### Adding a New View
1. Create file in `MyVoice/Views/`
2. Import SwiftUI
3. Add `#Preview` macro for Xcode previews
4. Add to Xcode project

## Permissions Required

The app requires these macOS permissions:
- **Microphone:** For voice recording
- **Accessibility:** For global keyboard shortcuts and auto-paste
