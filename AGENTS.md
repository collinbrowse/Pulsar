# Project Overview
Pulsar is an iOS app focused on activity, segments, and profile insights. It uses SwiftUI with shared flows for networking, analytics, and app state.

**Delivery status (milestones, CI):** see the root `README.md` and `Pulsar/Documentation/Milestones/MILESTONES_SUMMARY.md` — not duplicated here.

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

# Xcode MCP Integration
- Cursor is configured to connect to Xcode via Apple's Model Context Protocol (MCP) server.
- **Setup required in Xcode:** Enable Xcode → Settings → Intelligence → Model Context Protocol → **Xcode Tools** (toggle ON).
- **Usage:** Keep your project open in Xcode when using Cursor's agent. Xcode will alert you when the external agent connects and is active.
- The agent can access Xcode capabilities like building, testing, and project structure through the MCP bridge (`xcrun mcpbridge`).
- **Configuration:** In `~/.cursor/mcp.json`, the `Xcode_26.3` server runs `scripts/xcode-mcp-proxy.js` (not `xcrun mcpbridge` directly). The proxy forwards all traffic to mcpbridge and strips `outputSchema` from tool definitions so Cursor does not require `structuredContent` from tools like BuildProject that declare a schema but do not return it—avoiding the error "Tool X has an output schema but did not return structured content". Restart Cursor or reconnect MCP after changing `mcp.json`.

# Quirks and Gotchas
- Product bundles are checked in under `Products/` for convenience but should not be edited by hand.
