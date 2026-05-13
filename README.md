# Pulse

Pulse is an iOS micro-journaling app built with SwiftUI and SwiftData.

It helps you capture moments through the day, rate them from -2 to +2, reflect each evening, and review patterns across day, week, and month views.

## Key features

- Fast daily logging with score tracking
- Daily reflection with summary notes
- Week and month overviews
- Custom metrics (KPIs)
- Custom tags for moments
- Reminders
- AI Insights (Foundation Models)
- iCloud sync via CloudKit

## Tech stack

- SwiftUI
- SwiftData
- CloudKit
- Xcode project (`Pulse.xcodeproj`)

## Build and test

```bash
# Build
xcodebuild build -scheme Pulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Unit tests
xcodebuild test -scheme Pulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:PulseTests

# UI tests
xcodebuild test -scheme Pulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:PulseUITests
```

## Repository structure

- `Pulse/` - App source code
- `PulseTests/` - Unit tests
- `PulseUITests/` - UI tests
- `landing/` - Landing page
- `App-Store/` - App Store assets and copy

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

## Security

Please report vulnerabilities privately as described in [SECURITY.md](SECURITY.md).

## License

This project is licensed under the [MIT License](LICENSE).
