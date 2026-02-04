# Pulsar - Activity Tracking & Social Fitness App

## Overview

Pulsar is a production-quality iOS app for activity tracking and social fitness, inspired by Strava but built without in-app GPS recording. Users sync and import activities from various sources (GPX/TCX/FIT files, HealthKit, partner APIs) to power a rich social experience with feeds, segments, leaderboards, analytics, routes, clubs, challenges, and privacy controls.

## Tech Stack

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

### File Parsing
- **CoreGPX**: GPX file parsing
- **FitFileParser**: FIT file parsing
- **CoreTCX/XMLCoder**: TCX file parsing

## Project Structure

```
Pulsar/
├── App/
│   ├── PulsarApp.swift          # Main app entry point
│   ├── AppState.swift            # Global TCA state
│   └── Config/
│       ├── FeatureFlags.swift    # Feature flag management
│       └── Environment.swift     # Environment configuration
├── Features/
│   ├── Onboarding/              # Auth & profile creation
│   ├── Import/                   # Activity file import
│   ├── Feed/                     # Social feed & interactions
│   ├── Segments/                 # Segments & leaderboards
│   ├── Analytics/                # Dashboard & goals
│   ├── Routes/                   # Route discovery & export
│   ├── Clubs/                    # Clubs & challenges
│   ├── Privacy/                  # Privacy controls
│   └── Premium/                  # Subscription & paywall
├── Shared/
│   ├── Models/                   # SwiftData models
│   ├── Networking/               # API client
│   ├── Parsers/                  # File parsers
│   └── UI/                       # Shared UI components
└── Resources/
    └── Assets.xcassets/
```

## Architecture

### TCA (The Composable Architecture)

Each feature is structured as a TCA module with:
- **State**: Immutable state container
- **Action**: User actions and side effects
- **Reducer**: Pure state transformation logic
- **Environment**: Dependencies (API client, parsers, etc.)

### SwiftData Models

Local persistence layer mirrors backend schema:
- `Profile`: User profile and settings
- `Activity`: Imported workout/activity
- `Segment`: Known route segments
- `Route`: Saved/discovered routes
- `Club`: User clubs
- `Challenge`: Club challenges
- `Goal`: User-defined goals

## Core Features

1. **Activity Import** (NO live GPS recording)
   - Manual file upload (GPX/TCX/FIT)
   - HealthKit sync (read-only)
   - Partner API integrations

2. **Social Feed**
   - Activity cards with stats and maps
   - Kudos and comments
   - Follow/unfollow users

3. **Segments & Leaderboards**
   - Auto-matching via PostGIS
   - Filtered leaderboards (age, gender, weight)
   - Personal records

4. **Analytics & Goals**
   - Weekly/monthly/yearly aggregates
   - Trend graphs and charts
   - Goal tracking with progress notifications

5. **Routes & Discovery**
   - Search and filter routes
   - Route popularity ranking
   - Export to GPX

6. **Clubs & Challenges**
   - Create/join clubs
   - Group challenges with leaderboards
   - Club activity feeds

7. **Privacy Controls**
   - Activity visibility (public/followers/private)
   - Privacy zones (blur start/end locations)

8. **Premium Tier**
   - Advanced analytics
   - Personal heatmaps
   - Full leaderboard access
   - Route planning tools

## Branching Strategy

- `main`: Production-ready code
- `milestone-N-feature-name`: Feature branches for each milestone
- PRs must include:
  - Description of changes
  - Test plan
  - Screenshot(s) of UI changes
  - Checklist of acceptance criteria

## Naming Conventions

### Swift Code
- **Types**: PascalCase (e.g., `ActivityImportView`, `ProfileState`)
- **Functions/Variables**: camelCase (e.g., `fetchProfile`, `activityCount`)
- **Constants**: camelCase (e.g., `maxActivitySize`, `defaultTimeout`)
- **Enums**: PascalCase with lowercase cases (e.g., `ActivityType.run`)

### Files
- **Views**: `*View.swift` (e.g., `FeedView.swift`)
- **Reducers**: `*Reducer.swift` (e.g., `FeedReducer.swift`)
- **Models**: `*Model.swift` or plain noun (e.g., `Activity.swift`)
- **Tests**: `*Tests.swift` (e.g., `FeedReducerTests.swift`)

## Development Workflow

### Setup
1. Clone the repository
2. Copy `.env.example` to `.env.local` and fill in credentials
3. Open `Pulsar.xcodeproj` in Xcode 26
4. Build and run on simulator or device

### Running Tests
```bash
# Swift Testing (unit tests)
xcodebuild test -scheme Pulsar -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# UI Tests (XCTest)
xcodebuild test -scheme PulsarUITests -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

### CI/CD
GitHub Actions workflows automatically:
- Build the project on every push/PR
- Run all tests
- Check code coverage (target: 80%+)
- Deploy to TestFlight on version tags (`v*`)

## API Documentation

See [API.md](./API.md) for backend endpoint specifications.

## Database Schema

See [ERD.png](./ERD.png) for entity-relationship diagram.

## Security & Privacy

- **No secrets in code**: All API keys and tokens stored in `.env` (not committed)
- **Keychain**: iOS app uses Keychain for sensitive data
- **CI/CD**: Secrets managed via GitHub Actions secrets
- **Privacy**: GDPR/CCPA compliant with data export/deletion

## Performance Considerations

- Value types preferred for performance
- `Sendable` conformance for thread-safe data
- Actors for shared mutable state
- Measure critical paths (activity parsing, map rendering)

## License

Proprietary - All rights reserved

## Contact

For questions or support, contact: [your-email@example.com]

