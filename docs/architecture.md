# Architecture Overview

This document provides a high-level overview of the Pulsar iOS application architecture.

## System Architecture

### High-Level Overview

Pulsar follows a **hybrid architecture** that balances SwiftUI's declarative nature with testability:

- **Default Pattern**: SwiftUI + Services + SwiftData (for simple views)
- **Optional Pattern**: MVVM with ViewModels (for complex screens)

### Architecture Layers

```
┌─────────────────────────────────────┐
│         SwiftUI Views               │
│  (Root Views + Content Views)      │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      ViewModels (Optional)          │
│  (For complex screens only)         │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│         Services Layer               │
│  (Business Logic)                    │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      Networking Layer                │
│  (API Clients)                       │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      Data Layer                      │
│  (SwiftData Models)                  │
└──────────────────────────────────────┘
```

## Component Details

### Views Layer

#### Root Views
- Coordinate data fetching and state management
- Use `@Query` for SwiftData reactive data binding
- Call Services directly for business logic
- Handle navigation and async operations
- Pass simple data types to content views

**Examples**: `ActivitiesView`, `FeedView`, `ActivityDetailView`

#### Content Views
- Pure UI presentation components
- Accept simple data types (String, Int, Double, Date, etc.)
- No dependencies on Services, ViewModels, or SwiftData
- Highly reusable and testable

**Examples**: `StatCard`, `DetailRow`, `ActivityHeaderView`

### ViewModels (Optional)

ViewModels are used only when complexity justifies them:
- 3+ data sources
- Complex state management
- Extensive unit testing needs

**Characteristics**:
- Use `@Observable` macro
- Conform to `DynamicProperty` to use `@Query`
- Mark with `@MainActor` for UI-related code
- Call Services for business logic

### Services Layer

Services contain business logic and are marked with `@MainActor`:

- **ActivityService**: Activity parsing, storage, synchronization
- **SocialService**: Feed, follows, kudos, comments
- **AuthenticationService**: Sign in, sign up, session management

**Pattern**: Singleton with `static let shared`

### Networking Layer

API clients for backend communication:

- **SupabaseClient**: Supabase backend API client
- Handles authentication, data fetching, real-time subscriptions

### Data Layer

SwiftData models for local persistence:

- **Activity**: Imported activities with track points
- **Profile**: User profiles and settings
- **Social**: Feed items, follows, kudos, comments
- **TrackPoint**: GPS coordinates for activities

## Data Flow

### Reading Data

1. **SwiftUI Views** use `@Query` for reactive data fetching
2. **SwiftData** automatically updates views when data changes
3. **No manual state synchronization** needed

### Writing Data

1. **Views** call **Services** for business logic
2. **Services** update **SwiftData** models
3. **Services** sync to **Backend** (Supabase)
4. **SwiftData** automatically notifies **Views** of changes

## State Management

### Global State

**AppState** (`@Observable`):
- Authentication state
- Current user ID
- Global app configuration

### Local State

**Views** use `@State` for:
- UI-specific state (loading, errors, form inputs)
- Temporary state that doesn't need persistence

### Persistent State

**SwiftData** handles:
- User profiles
- Activities
- Social data
- All app data that needs persistence

## Concurrency

### Async/Await

All networking and async operations use Swift 6's async/await:
- Services use `async throws` for operations that can fail
- Views use `.task { }` modifier for async work tied to lifecycle

### MainActor

- Services marked with `@MainActor` for UI-related code
- SwiftUI views automatically run on `@MainActor`
- Use `await MainActor.run { }` when needed

## Error Handling

### Error Types

Services define specific error types:
```swift
enum ActivityServiceError: Error, LocalizedError {
    case unsupportedFileFormat(String)
    case invalidFileData
    case parsingFailed(String)
    // ...
}
```

### Error Propagation

- Services throw errors
- Views handle errors and display to users
- Use `try?` for non-critical operations

## Testing Strategy

### Unit Tests

- Test Services independently
- Mock networking layer
- Test business logic in isolation

### UI Tests

- Test user flows end-to-end
- Verify UI interactions
- Capture screenshots for visual regression

### Test Organization

- **PulsarTests/**: Unit tests (Swift Testing + XCTest)
- **PulsarUITests/**: UI tests (XCUITest)
- **Test Plans**: Organized test execution

## Dependencies

### Swift Packages

- **CoreGPX**: GPX file parsing
- **XMLCoder**: XML parsing for TCX files
- **FitDataProtocol**: FIT file parsing
- **PostHog**: Analytics and observability

### External Services

- **Supabase**: Backend (PostgreSQL + PostGIS)
- **PostHog**: Analytics (optional)
- **Firebase Crashlytics**: Crash reporting (optional)

## Configuration

### Environment Variables

Loaded from `.env.local`:
- `SUPABASE_URL`: Backend URL
- `SUPABASE_ANON_KEY`: Backend API key
- `POSTHOG_API_KEY`: Analytics key (optional)

### Feature Flags

Controlled via `FeatureFlags`:
- `ENABLE_ANALYTICS`: PostHog analytics
- `ENABLE_CRASHLYTICS`: Firebase Crashlytics
- `USE_MAPBOX`: Mapbox instead of MapKit

## Related Documentation

- [CI Overview](ci_overview.md) - CI/CD setup
- [Testing Guide](testing.md) - Testing documentation
- [Style Guide](style_guide.md) - Code style rules
- [Team Workflow](TEAM_WORKFLOW.md) - Development workflow
