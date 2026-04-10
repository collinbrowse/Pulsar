# Milestone 0 Checklist - Project Bootstrap

## Overview
Initialize repository, CI/CD, and project foundation for Pulsar activity tracking app.

## Acceptance Criteria

### Repository Setup
- [x] Create feature branch `milestone-0-bootstrap`
- [x] Initialize Git repository with proper .gitignore
- [ ] Push to remote repository (GitHub)

### Project Configuration
- [x] Xcode project configured for iOS 26.0+ / Swift 6.2
- [x] SwiftUI and SwiftData integrated
- [x] Modern Swift concurrency enabled (async/await, actors)
- [x] Project builds successfully without errors

### Architecture & Structure
- [x] Create modular folder structure:
  - [x] `App/` - App entry point and global state
  - [x] `App/Config/` - Feature flags and environment
  - [x] `Features/` - Feature modules (scaffolded)
  - [x] `Shared/` - Shared code (scaffolded)
- [x] Implement `AppState` with Observable pattern
- [x] Implement `FeatureFlags` for gradual rollout
- [x] Implement `AppEnvironment` for configuration
- [x] Implement `ObservabilityManager` for analytics/crashlytics

### Testing
- [x] Add Swift Testing framework
- [x] Create unit tests for:
  - [x] Feature flags (FeatureFlagsTests)
  - [x] Environment configuration (EnvironmentTests)
  - [x] App state (AppStateTests)
- [x] All tests compile
- [ ] All tests pass (requires concrete simulator)

### CI/CD
- [x] Create GitHub Actions workflow (`.github/workflows/ci.yml`)
- [x] Workflow includes:
  - [x] Build verification
  - [x] Unit test execution
  - [x] UI test execution
  - [x] Code coverage reporting
  - [x] Linting with SwiftLint
  - [x] Security checks (no hardcoded secrets)
- [ ] CI runs successfully on push/PR

### Observability
- [x] PostHog analytics integration prepared (feature-flagged)
- [x] Firebase Crashlytics integration prepared (feature-flagged)
- [x] Logging with OSLog configured
- [x] Analytics disabled by default for security

### Documentation
- [x] Create `README.md` with:
  - [x] Project overview
  - [x] Quick start guide
  - [x] Architecture description
  - [x] Development workflow
- [x] Create `docs/README.md` with:
  - [x] Detailed architecture
  - [x] Tech stack
  - [x] Project structure
  - [x] Naming conventions
  - [x] Branching strategy
- [x] Create `docs/API.md` with:
  - [x] Backend API documentation
  - [x] All endpoint specifications
- [x] Create `docs/ERD.md` with:
  - [x] Database schema documentation
  - [x] Entity relationships
  - [x] PostGIS spatial queries
- [x] Create `ENV_SETUP.md` with:
  - [x] Environment variable configuration guide
  - [x] Security best practices
  - [x] Troubleshooting tips

### Security & Secrets
- [x] Create `.env.example` with all required variables
- [x] Add `.env.local` and secrets to `.gitignore`
- [x] Document secrets management in `ENV_SETUP.md`
- [x] No hardcoded secrets in codebase
- [x] CI/CD secrets documented

### Code Quality
- [x] Add `.swiftlint.yml` configuration
- [x] Configure linting rules
- [x] Code follows Swift API Design Guidelines
- [ ] No linter warnings

### SPM Dependencies
- [ ] Add TCA (The Composable Architecture)
- [ ] Add CoreGPX for GPX parsing
- [ ] Add FitFileParser for FIT file parsing  
- [ ] Add XMLCoder for TCX parsing
- [ ] Package resolution succeeds
- [ ] All dependencies compile

### Pull Request
- [x] Create PR template (`.github/pull_request_template.md`)
- [ ] Open PR from `milestone-0-bootstrap` to `main`
- [ ] PR includes:
  - [ ] Description of changes
  - [ ] Test plan
  - [ ] Screenshots (if applicable)
  - [ ] Acceptance criteria checklist

## Testing Instructions

### Build
```bash
xcodebuild -project Pulsar.xcodeproj -scheme Pulsar \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  clean build CODE_SIGNING_ALLOWED=NO
```

Expected: ✅ BUILD SUCCEEDED

### Unit Tests
```bash
xcodebuild test -project Pulsar.xcodeproj -scheme PulsarTests \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  CODE_SIGNING_ALLOWED=NO
```

Expected: ✅ All tests pass

### Lint
```bash
swiftlint lint --strict
```

Expected: ✅ No warnings or errors

### Run App
1. Open `Pulsar.xcodeproj` in Xcode
2. Select iPhone 17 simulator
3. Press `Cmd+R` to run

Expected: App launches successfully with log messages:
```
Pulsar app launching...
Environment not fully configured - check API keys (expected if no .env)
Pulsar app configured
Analytics disabled via feature flag
Crashlytics disabled via feature flag
```

## Dependencies to Install (Next Step)

After this milestone is complete, install the following SPM dependencies:

1. **TCA (The Composable Architecture)**
   - Repository: `https://github.com/pointfreeco/swift-composable-architecture`
   - Version: Latest

2. **CoreGPX**
   - Repository: `https://github.com/vincentneo/CoreGPX`
   - Version: Latest

3. **FitFileParser**
   - Repository: `https://github.com/FitnessKit/FitDataProtocol`
   - Version: Latest

4. **XMLCoder** (for TCX files)
   - Repository: `https://github.com/MaxDesiatov/XMLCoder`
   - Version: Latest

## Notes

- Analytics and crashlytics are **disabled by default** for security
- To enable, set feature flags in Xcode scheme environment variables
- Backend API keys will be requested at the start of Milestone 1
- SPM dependencies will be added in a follow-up commit

## Success Criteria

✅ **Milestone 0 Complete When:**
- All acceptance criteria checked
- Build succeeds with no errors
- Tests pass (or documented why they can't run)
- CI workflow configured and documented
- Documentation complete and accurate
- PR opened with proper description
- No secrets committed to Git

## Timeline

- **Estimated**: 2-3 hours
- **Actual**: [To be filled]

## Next Steps

After this milestone is approved and merged:
1. **Milestone 1**: Supabase backend scaffolding
2. Prompt user for API keys (Supabase, PostHog, etc.)
3. Set up backend infrastructure
4. Create database schema and migrations

