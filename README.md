# Pulsar - Activity Tracking & Social Fitness

A production-quality iOS app for activity tracking and social fitness, built with Swift 6.2, SwiftUI, and TCA.

## Quick Start

### Prerequisites

- **Xcode 26** or later
- **iOS 26.0** SDK
- **macOS 15** (Sonoma) or later

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/pulsar.git
   cd pulsar
   ```

2. **Configure environment variables**
   
   Copy `.env.example` to create your local environment file:
   ```bash
   cp .env.example .env.local
   ```
   
   Edit `.env.local` and add your API keys:
   ```bash
   # Required for backend functionality
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key-here
   
   # Optional: Analytics and observability
   POSTHOG_API_KEY=your-posthog-api-key
   ENABLE_ANALYTICS=false
   ENABLE_CRASHLYTICS=false
   
   # Optional: Mapbox (feature-flagged)
   MAPBOX_TOKEN=your-mapbox-token-here
   USE_MAPBOX=false
   ```

3. **Open the project**
   ```bash
   open Pulsar.xcodeproj
   ```

4. **Build and run**
   - Select a simulator or device
   - Press `Cmd+R` to build and run

### Running Tests

**Swift Testing (Unit Tests)**
```bash
xcodebuild test \
  -project Pulsar.xcodeproj \
  -scheme PulsarTests \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

**XCTest (UI Tests)**
```bash
xcodebuild test \
  -project Pulsar.xcodeproj \
  -scheme PulsarUITests \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

Or simply press `Cmd+U` in Xcode to run all tests.

**Production readiness (run before release)**

1. **Unit tests**: `xcodebuild test -scheme PulsarTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` (or your simulator)
2. **UI tests**: `xcodebuild test -scheme PulsarUITests -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
3. **Build**: `xcodebuild -scheme Pulsar -destination 'generic/platform=iOS Simulator' build`
4. **Lint**: `swiftlint lint`
5. **Security**: No `.env` or `.env.local` committed; no hardcoded `sk_live_`, `pk_live_`, `ghp_`, or `gho_` in Swift files.

CI runs lint, security checks, and code-structure verification on push/PR. Full build and tests require local Xcode with iOS SDK.

## Architecture

- **State Management**: TCA (The Composable Architecture)
- **Persistence**: SwiftData
- **Networking**: URLSession with async/await
- **UI**: SwiftUI
- **Testing**: Swift Testing framework

See [docs/README.md](docs/README.md) for detailed architecture documentation.

## Project Structure

```
Pulsar/
├── App/                    # App entry point and global state
├── Features/               # Feature modules (Onboarding, Feed, etc.)
├── Shared/                 # Shared models, networking, UI components
└── Resources/              # Assets and resources

PulsarTests/               # Unit tests (Swift Testing)
PulsarUITests/             # UI tests (XCTest)
docs/                      # Documentation
```

## Development

### Branching Strategy

- `main` - Production-ready code
- `milestone-N-feature` - Feature branches for each milestone
- Create PRs with description, test plan, and screenshots

### Code Style

- Follow Swift API Design Guidelines
- Run SwiftLint before committing: `swiftlint lint`
- Format code consistently (use Xcode's default formatting)

### Continuous Integration

GitHub Actions automatically runs on every push and PR:
- ✅ Build verification
- ✅ Unit tests
- ✅ UI tests
- ✅ Code coverage reporting
- ✅ Linting with SwiftLint
- ✅ Security checks

## Feature Flags

The app uses feature flags for gradual rollout:

- `ENABLE_ANALYTICS` - PostHog analytics (default: false)
- `ENABLE_CRASHLYTICS` - Firebase Crashlytics (default: false)
- `USE_MAPBOX` - Mapbox instead of MapKit (default: false)

Set these in your `.env.local` file or via Xcode scheme environment variables.

## Backend

The app uses **Supabase** for backend services:
- PostgreSQL + PostGIS for geospatial data
- Supabase Auth for authentication
- Supabase Storage for activity files
- Edge Functions for business logic

See [docs/API.md](docs/API.md) for API documentation.

## Milestones

- [x] **Milestone 0**: Repository, CI, project bootstrap
- [ ] **Milestone 1**: Supabase backend scaffolding
- [ ] **Milestone 2**: Auth & user profiles
- [ ] **Milestone 3**: Activity import pipeline
- [ ] **Milestone 4**: Feed & social
- [ ] **Milestone 5**: Segments & leaderboards
- [ ] **Milestone 6**: Analytics & goals
- [ ] **Milestone 7**: Routes & discovery
- [ ] **Milestone 8**: Clubs & challenges
- [ ] **Milestone 9**: Privacy & data controls
- [ ] **Milestone 10**: Premium tier & monetization

## License

Proprietary - All rights reserved

## Support

For questions or issues, please open a GitHub issue or contact the development team.

