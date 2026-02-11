# Project Overview
Pulsar is an iOS app focused on activity, segments, and profile insights. It uses SwiftUI with shared flows for networking, analytics, and app state.

# Architecture Decisions
- SwiftUI-first UI with small feature views per domain (Activity, Feed, Onboarding, Profile, Segments).
- Shared logic lives in `Shared/Logic` for flows that coordinate models and networking.
- Shared models and DTOs are isolated in `Shared/Models` and `Shared/Networking`.
- App-level state is centralized in `AppState` and referenced by Root and tabs.

# Conventions and Patterns
- SwiftUI view structs conform to `View` and render UI in `body`.
- Use async/await for networking and background work.
- Avoid force unwraps; prefer explicit optional handling.
- Keep feature-specific logic near the feature folder.

# Build and Run
- Build using the Xcode scheme for `Pulsar`.
- Run on iOS Simulator or device.

# Quirks and Gotchas
- Product bundles are checked in under `Products/` for convenience but should not be edited by hand.
