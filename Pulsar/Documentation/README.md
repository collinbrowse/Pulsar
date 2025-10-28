# 📱 Pulsar - Activity Tracking & Social Fitness App

**Production-Quality iOS Application**  
Version 1.0.0 | iOS 26+ | Swift 6.2 | SwiftUI

---

## 🎯 Overview

Pulsar is a Strava-inspired iOS app for activity tracking and social fitness, built **without in-app GPS recording**. Users sync and import activities from various sources (GPX/TCX/FIT files, HealthKit, partner APIs) to power a rich social experience with feeds, segments, leaderboards, analytics, routes, clubs, challenges, and privacy controls.

**Key Differentiator:** Import-first approach - no live GPS capture, focus on social and analytics.

---

## 🚀 Quick Start

### Prerequisites

- **Xcode 26** or later
- **iOS 26.0 SDK**
- **macOS 15** (Sonoma) or later
- **Swift 6.2**

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

---

## 📚 Documentation Index

### Setup & Getting Started
- [Environment Setup](Setup/ENV_SETUP.md) - Configure environment variables and API keys
- [Getting Started](Setup/GETTING_STARTED.md) - Comprehensive setup guide
- [SPM Dependencies](Setup/SPM_DEPENDENCIES.md) - Swift Package Manager dependencies

### Development
- [Error Tracking](Development/ERROR_TRACKING.md) - PostHog integration and error analytics
- [API Documentation](Development/API.md) - Backend API specifications
- [Database Schema](Development/ERD.md) - Entity-relationship diagram
- [Bug Fix Sessions](Development/BUGFIX_SESSION.md) - Detailed bug fix documentation
- [Test Coverage Analysis](Development/TEST_COVERAGE_ANALYSIS.md) - Testing strategy and coverage

### Testing
- [UI Testing Guide](Testing/UI_TESTING_GUIDE.md) - How to write and run UI tests

### Infrastructure
- [Supabase Setup](Infrastructure/SUPABASE_SETUP.md) - Backend configuration guide

### Milestones
- [All Milestones](Milestones/MILESTONES_SUMMARY.md) - Consolidated milestone tracking
- Business reports for each milestone available in `Milestones/Business/`

### Metrics
- [Development Metrics](METRICS.md) - Build times, LOC, development velocity

---

## 🏗️ Tech Stack

### iOS App
- **Platform**: iOS 26+ (Xcode 26, Swift 6.2)
- **UI Framework**: SwiftUI (latest APIs)
- **State Management**: TCA (The Composable Architecture)
- **Persistence**: SwiftData
- **Concurrency**: Swift Concurrency (async/await, actors, Sendable)
- **Testing**: Swift Testing framework (unit), XCTest (UI)

### Backend
- **Backend-as-a-Service**: Supabase
  - PostgreSQL + PostGIS for geospatial data
  - Supabase Auth (email/password + Sign in with Apple)
  - Supabase Storage for activity files
  - Edge Functions (Deno/TypeScript) for business logic
- **Maps**: Apple MapKit (primary), Mapbox (optional, feature-flagged)
- **Crash Reporting**: Firebase Crashlytics
- **Product Analytics**: PostHog

### File Parsing (SPM)
- **CoreGPX**: GPX file parsing
- **FitFileParser**: FIT file parsing
- **XMLCoder**: TCX file parsing

---

## 📂 Project Structure

```
Pulsar/
├── App/
│   ├── PulsarApp.swift          # Main app entry point
│   ├── AppState.swift            # Global observable state
│   └── Config/
│       ├── FeatureFlags.swift    # Feature flag management
│       ├── Environment.swift     # Environment configuration
│       └── ObservabilityManager.swift # Analytics & error tracking
├── Features/
│   ├── Onboarding/              # Auth & profile creation ✅
│   ├── Activities/              # Activity upload & list ✅
│   ├── Feed/                    # Social feed & interactions ✅
│   ├── Import/                  # Activity file import
│   ├── Segments/                # Segments & leaderboards
│   ├── Analytics/               # Dashboard & goals
│   ├── Routes/                  # Route discovery & export
│   ├── Clubs/                   # Clubs & challenges
│   ├── Privacy/                 # Privacy controls
│   └── Premium/                 # Subscription & paywall
├── Shared/
│   ├── Models/                  # SwiftData models
│   │   ├── Profile.swift        # User profiles ✅
│   │   ├── Activity.swift       # Activities ✅
│   │   └── Social.swift         # Social features ✅
│   ├── Networking/              # API clients
│   │   ├── SupabaseClient.swift      # Supabase REST client ✅
│   │   └── AuthenticationService.swift # Auth service ✅
│   ├── Services/                # Business logic
│   │   ├── ActivityService.swift     # Activity parsing ✅
│   │   └── SocialService.swift       # Social interactions ✅
│   ├── Parsers/                 # File parsers
│   ├── Utilities/               # Helpers
│   │   └── ErrorManager.swift   # Centralized error handling ✅
│   └── UI/                      # Shared UI components
├── Documentation/               # All documentation (this folder) ✅
└── Resources/
    └── Assets.xcassets/

PulsarTests/                    # Unit tests (Swift Testing) ✅
PulsarUITests/                  # UI tests (XCTest) ✅
```

---

## 🎯 Core Features

### 1. Activity Import (NO Live GPS Recording)
- ✅ Manual file upload (GPX/TCX/FIT)
- ⏳ HealthKit sync (read-only)
- ⏳ Partner API integrations

### 2. Social Feed
- ✅ Basic feed structure
- ⏳ Activity cards with stats and maps
- ⏳ Kudos and comments
- ⏳ Follow/unfollow users

### 3. Segments & Leaderboards
- ⏳ Auto-matching via PostGIS
- ⏳ Filtered leaderboards (age, gender, weight)
- ⏳ Personal records

### 4. Analytics & Goals
- ⏳ Weekly/monthly/yearly aggregates
- ⏳ Trend graphs and charts
- ⏳ Goal tracking with progress notifications

### 5. Routes & Discovery
- ⏳ Search and filter routes
- ⏳ Route popularity ranking
- ⏳ Export to GPX

### 6. Clubs & Challenges
- ⏳ Create/join clubs
- ⏳ Group challenges with leaderboards
- ⏳ Club activity feeds

### 7. Privacy Controls
- ⏳ Activity visibility (public/followers/private)
- ⏳ Privacy zones (blur start/end locations)

### 8. Premium Tier
- ⏳ Advanced analytics
- ⏳ Personal heatmaps
- ⏳ Full leaderboard access
- ⏳ Route planning tools

---

## 🧪 Testing

### Run Unit Tests
```bash
xcodebuild test \
  -project Pulsar.xcodeproj \
  -scheme Pulsar \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

### Run UI Tests
```bash
xcodebuild test \
  -project Pulsar.xcodeproj \
  -scheme Pulsar \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:PulsarUITests
```

Or simply press `Cmd+U` in Xcode to run all tests.

**Current Test Coverage:**
- ✅ 59 unit tests passing
- ✅ UI tests for onboarding flow
- ✅ Error handling tests
- ✅ Authentication flow tests

---

## 🏗️ Architecture

### State Management (TCA-like with @Observable)
- **AppState**: Global observable state (authentication, user ID)
- **Feature Modules**: Self-contained feature implementations
- **Services**: Business logic and API interactions
- **Models**: SwiftData models for persistence

### SwiftData Models

Local persistence layer mirrors backend schema:
- `Profile` - User profile and settings ✅
- `Activity` - Imported workout/activity ✅
- `TrackPoint` - GPS track points ✅
- `Follow`, `Kudo`, `Comment` - Social features ✅
- `Segment` - Known route segments (planned)
- `Route` - Saved/discovered routes (planned)
- `Club` - User clubs (planned)
- `Challenge` - Club challenges (planned)
- `Goal` - User-defined goals (planned)

---

## 🔧 Development

### Branching Strategy

- `main` - Production-ready code
- `milestone-N-feature` - Feature branches for each milestone
- Create PRs with description, test plan, and screenshots

### Code Style

- Follow Swift API Design Guidelines
- Run SwiftLint before committing: `swiftlint lint`
- Format code consistently (use Xcode's default formatting)

### Naming Conventions

**Swift Code:**
- **Types**: PascalCase (e.g., `ActivityImportView`, `ProfileState`)
- **Functions/Variables**: camelCase (e.g., `fetchProfile`, `activityCount`)
- **Constants**: camelCase (e.g., `maxActivitySize`, `defaultTimeout`)
- **Enums**: PascalCase with lowercase cases (e.g., `ActivityType.run`)

**Files:**
- **Views**: `*View.swift` (e.g., `FeedView.swift`)
- **Models**: `*.swift` or plain noun (e.g., `Activity.swift`)
- **Services**: `*Service.swift` (e.g., `AuthenticationService.swift`)
- **Tests**: `*Tests.swift` (e.g., `ProfileTests.swift`)

---

## 🔄 Continuous Integration

GitHub Actions automatically runs on every push and PR:
- ✅ Build verification
- ✅ Unit tests
- ✅ UI tests
- ✅ Code coverage reporting
- ✅ Linting with SwiftLint
- ✅ Security checks

---

## 🚩 Feature Flags

The app uses feature flags for gradual rollout:

- `ENABLE_ANALYTICS` - PostHog analytics (default: false)
- `ENABLE_CRASHLYTICS` - Firebase Crashlytics (default: false)
- `USE_MAPBOX` - Mapbox instead of MapKit (default: false)

Set these in your `.env.local` file or via Xcode scheme environment variables.

---

## 📊 Milestones

- [x] **Milestone 0**: Repository, CI, project bootstrap ✅
- [x] **Milestone 1**: Supabase backend scaffolding ✅
- [x] **Milestone 2**: Auth & user profiles ✅
- [x] **Milestone 3**: Activity import pipeline ✅
- [x] **Milestone 4**: Feed & social (basic) ✅
- [ ] **Milestone 5**: Segments & leaderboards
- [ ] **Milestone 6**: Analytics & goals
- [ ] **Milestone 7**: Routes & discovery
- [ ] **Milestone 8**: Clubs & challenges
- [ ] **Milestone 9**: Privacy & data controls
- [ ] **Milestone 10**: Premium tier & monetization

See [Milestones Summary](Milestones/MILESTONES_SUMMARY.md) for detailed progress.

---

## 🔐 Security & Privacy

- **No secrets in code**: All API keys and tokens stored in `.env` (not committed)
- **Keychain**: iOS app uses Keychain for sensitive data
- **CI/CD**: Secrets managed via GitHub Actions secrets
- **Privacy**: GDPR/CCPA compliant with data export/deletion
- **Row-Level Security**: Database access controlled via RLS policies

---

## ⚡ Performance Considerations

- Value types preferred for performance
- `Sendable` conformance for thread-safe data
- Actors for shared mutable state
- Measure critical paths (activity parsing, map rendering)
- Build times tracked in `METRICS.md`

---

## 📄 License

Proprietary - All rights reserved

---

## 🆘 Support

**For questions or issues:**
- Development: See feature-specific documentation in subfolders
- Bug reports: Create GitHub issue
- Feature requests: Discuss with product team

**Key Contacts:**
- Engineering: [Contact info]
- Product Team: [Contact info]
- Analytics Team: [Contact info]

---

**Last Updated:** October 28, 2025  
**Document Version:** 2.0 (Consolidated)

