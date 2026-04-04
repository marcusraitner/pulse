# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
# Build the app
xcodebuild build -scheme Pulse -destination 'platform=iOS Simulator,name=iPhone 16'

# Run unit tests
xcodebuild test -scheme Pulse -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:PulseTests

# Run a single test suite
xcodebuild test -scheme Pulse -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:PulseTests/AverageScoreTests

# Run UI tests
xcodebuild test -scheme Pulse -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:PulseUITests
```

## Architecture Overview

**Pulse** is an iOS daily journaling app built with SwiftUI + SwiftData + CloudKit.

### Data Layer

`DailyEntry` and `DailyLogEntry` are the two core SwiftData models. The schema uses a versioned migration system (V1 → V1.1.0 → V1.2.0) defined in `Pulse/Model/DailyEntry.swift`. Always use the typealias (`DailyEntry` = latest schema version) when writing new code. CloudKit sync is enabled automatically via the `ModelContainer` in `PulseApp.swift`.

### View Architecture

Views use `@Query` to fetch directly from SwiftData — there are no separate view models. State is managed via `@State`, `@AppStorage`, and `@Binding`. `ContentView.swift` is the root container that orchestrates sheet presentations for the major feature areas: timeline, log entries, reflection, and settings.

### iOS 26 Compatibility

`Pulse/Helpers/Compatibility.swift` centralizes all `#available(iOS 26, *)` guards. Glass materials, `MKMapItem` API changes, and toolbar button roles are all abstracted here. Use `FeatureFlags.iOS26` (from `Pulse/Helpers/FeatureFlags.swift`) as the runtime check — do not add raw `#available` checks scattered across views.

### Key Helpers

- `ScoreStyleHelper` — maps scores (−2 to +2) to colors and gradients
- `LocationManager` — wraps CoreLocation permission and coordinate capture
- `ReviewService` — rate-limited App Store review requests (`@Observable`)
- `DateFormatHelper` — shared date formatting utilities
- `NotificationScheduler` — schedules and manages local notifications (`Pulse/Services/`)
- `AppStorageKeys` — centralised `UserDefaults`/`@AppStorage` key constants (`Pulse/Helpers/Constants.swift`); always use these, never raw strings

### Conventions

- **Saving**: use `context.saveOrLog(_:logger:)` (defined in `Pulse/Helpers/ModelContext+Save.swift`) instead of inline `do { try context.save() } catch` blocks.
- **UserDefaults keys**: always use `AppStorageKeys.*` constants — never inline string literals.
- **Computed properties in versioned schemas**: computed properties (e.g. `averageScore`, `formattedTimestamp`) are safe to change in old schema versions — SwiftData only tracks stored properties for migration.

### Testing

Unit tests use Swift's `Testing` framework (not XCTest). UI tests use XCTest with accessibility identifiers embedded in views. Debug launch arguments `--remove-today-on-inactive` and `--disable-animations` put the app in a deterministic state for UI tests.

### Deep Links

`pulseapp://log` and `pulseapp://reflect` are handled in `ContentView` via `.onOpenURL`.

## Code Changes

After any refactoring or deletion, always verify there are no dangling references to removed functions, closures, or variables before committing.

## Git Operations

When asked to commit and push, do so immediately without running extra build verification steps unless explicitly requested.

## Content Generation

Never hallucinate or assume features exist in the app. Only reference features you have verified in the codebase when writing marketing copy, App Store descriptions, or release notes.

## Data Analysis

When working with Excel/data files, always inspect the actual column layout of each file before applying transformations. Never assume two files share the same column structure.
