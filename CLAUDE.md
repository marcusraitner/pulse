# CLAUDE.md — Pulse

Guidance for AI coding agents (Claude Agent in Xcode, Claude Code, Codex) working in this repository.

## What Pulse is

Pulse is a minimalist iOS micro-journaling app. Users capture short "moments" through the day, rate them on a scale from **−2 to +2**, optionally tag them, reflect in the morning and evening, and review patterns in day/week/month views. Custom metrics (KPIs), reminders, on-device AI insights (Apple Foundation Models), and iCloud sync via CloudKit round it out.

- App Store: `id6759242390` (Pulse – Your Micro Journal)
- License: MIT, public repo, external contributions possible
- Landing page: https://raitner.de/pulse (source in `landing/`)

## Product principles — these are hard constraints, not preferences

1. **Radical minimalism.** Capturing a moment must take seconds. Every feature proposal competes against the simplicity of the app. When in doubt: leave it out.
2. **Privacy is the product.** All data stays on device and in the user's private iCloud. AI runs 100% on-device via Foundation Models.
   - NEVER add analytics, tracking, crash reporters, ad SDKs, or telemetry of any kind.
   - NEVER add network calls other than CloudKit sync and on-device Foundation Models usage.
   - NEVER add third-party dependencies without explicit approval from the maintainer. The project intentionally has none.
3. **No dark patterns.** No streaks, no guilt mechanics, no gamification, no subscription. Free and open source.
4. Reviews praise the app as "schlicht und schnell" (simple and fast). Preserve that. Performance and low friction beat feature richness.

## Environment & targets

- **Deployment target: iOS 26.** There are zero active devices below iOS 26; do not write availability checks or fallbacks for older OS versions.
- Xcode project (`Pulse.xcodeproj`), no SPM workspace at root. Xcode 26.3+, Apple Silicon.
- Stack: SwiftUI, SwiftData, CloudKit, Foundation Models. Prefer the newest stable SwiftUI APIs (e.g. `safeAreaBar`, `scrollEdgeEffectStyle`, `ToolbarSpacer`, `glassEffect`) over legacy patterns; UIKit only as a last resort.

## Repository layout

- `Pulse/` — app source code
- `PulseTests/` — unit tests
- `PulseUITests/` — UI tests
- `App-Store/` — App Store assets and copy (DO NOT modify unless explicitly asked)
- `landing/` — landing page (DO NOT modify unless explicitly asked)

## Build & test

```bash
# Build
xcodebuild build -scheme Pulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Unit tests
xcodebuild test -scheme Pulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:PulseTests

# UI tests
xcodebuild test -scheme Pulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:PulseUITests
```

Always run a build after non-trivial changes; run `PulseTests` after any change to models, persistence, or business logic. UI tests are slow — run them only when the change touches navigation or core flows, or when asked.

## Architecture & conventions

- **SwiftData + CloudKit.** All persistent models must remain CloudKit-compatible:
  - No `@Attribute(.unique)` constraints.
  - All relationships optional; every relationship needs an inverse.
  - Non-optional stored properties need default values.
  - Schema changes must be additive only (new optional properties). Renaming/removing properties or changing types requires an explicit migration plan approved by the maintainer — NEVER do this on your own, it affects real user data syncing through production CloudKit.
- **State:** `@Observable` classes shared via `Environment` for cross-view state (e.g. filter state); no third-party state frameworks.
- **Score semantics:** the −2…+2 scale is the core domain concept. **Orange is used semantically as a rating-scale color** — do not use orange for unrelated accents or highlights.
- **Localization:** the app ships in German and English. Every user-facing string must be localized in both languages (String Catalogs). <!-- TODO(Marcus): confirm .xcstrings vs. legacy .strings -->
- Naming, formatting, and file organization: follow the existing code in `Pulse/` — consistency with the surrounding code beats personal style.

## Known issues & workarounds

- **iOS 27 `scrollEdgeEffectStyle(.soft)` device bug:** the effect renders correctly in Simulator but fails on real devices in some view hierarchies; root cause traced to ZStack subview-chain ordering (also reproducible in system apps). If you touch the timeline header/bottom transitions, preserve the existing subview ordering workaround and verify on device, not only in Simulator.
- Simulator results are necessary but not sufficient for UI work: several past bugs only reproduced on hardware. Flag any change you could not verify on a device.

## Working rules for agents

1. **Never commit to `main`.** Work on a feature branch; leave committing/pushing to the maintainer unless explicitly told otherwise.
2. **Small, reviewable diffs.** This is a learning project — the maintainer reads every diff. Prefer three small focused changes over one sweeping refactor. Explain *why*, not just *what*.
3. **Plan first for anything non-trivial.** Propose a short plan and wait for approval before multi-file changes.
4. **Tests are part of the change.** New logic ships with unit tests in `PulseTests`.
5. **Verify visually.** For UI changes, build and capture Previews/screenshots to check the result before declaring done.
6. **Ask, don't assume,** for: CloudKit schema changes, new dependencies, changes to `App-Store/` or `landing/`, removing features, and anything touching data export/import formats (users rely on the JSON export).
7. Keep the README's build commands in sync if schemes or destinations change.
