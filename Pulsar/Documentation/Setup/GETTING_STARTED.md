# 🚀 Getting Started with Pulsar

Welcome to the Pulsar activity tracking app! This guide will help you get up and running quickly.

## ✅ Milestone 0 Complete!

The project foundation is ready. All core infrastructure, documentation, and architecture are in place.

---

## Quick Start (5 minutes)

### 1. Open the Project

```bash
cd /Users/collinbrowse/Documents/After\ College/Freelance/Pulsar
open Pulsar.xcodeproj
```

### 2. Add SPM Dependencies

In Xcode:
1. **File → Add Package Dependencies...**
2. Add these packages (follow `SPM_DEPENDENCIES.md` for details):
   - `https://github.com/pointfreeco/swift-composable-architecture`
   - `https://github.com/vincentneo/CoreGPX`
   - `https://github.com/FitnessKit/FitDataProtocol`
   - `https://github.com/MaxDesiatov/XMLCoder`

### 3. Build and Run

1. Select **iPhone 16 Pro** simulator
2. Press `Cmd+R`
3. App should launch successfully! 🎉

You'll see console logs:
```
Pulsar app launching...
Environment not fully configured - check API keys
Pulsar app configured
Analytics disabled via feature flag
Crashlytics disabled via feature flag
```

This is expected - we haven't configured API keys yet.

**Simulator-only console messages** you can ignore when running in the simulator:
- `CHHapticPattern` / `hapticpatternlibrary.plist` – haptic feedback isn’t available in the simulator.
- `UIKeyboardLayoutStar` / `Unable to simultaneously satisfy constraints` involving `_UIRemoteKeyboardPlaceholderView` – system keyboard layout in simulator.
- `nano zone abandoned` / `malloc` – common simulator memory allocator message.
- `Failed to send CA Event for app launch measurements` – Core Animation metrics in simulator.
- `CoreData: error:` (long dumps) – when SwiftData migration fails, the framework logs these before the app recovers. Use `[Pulsar]` lines to follow app behavior.

**Quieter console (optional)**  
To hide system and Core Data verbose logs and only see `[Pulsar]` and your code: **Edit Scheme → Run → Arguments → Environment Variables** → add `OS_ACTIVITY_MODE` = `disable`. This turns off all `os_log` output (including frameworks), so use it when you need a clean console to trace app flow.

---

## Project Status

### ✅ Completed (Milestone 0)

| Component | Status | Details |
|-----------|--------|---------|
| Project Structure | ✅ | Modular folders (App/Features/Shared) |
| Swift Testing | ✅ | 3 test suites, 5 tests |
| CI/CD Pipeline | ✅ | GitHub Actions configured |
| Documentation | ✅ | 7+ comprehensive docs |
| Feature Flags | ✅ | Analytics, Crashlytics, Mapbox |
| Security | ✅ | No secrets in code |
| Build System | ✅ | Xcode 26, iOS 26, Swift 6.2 |
| Architecture | ✅ | TCA-ready, Observable, SwiftData |

### 📋 Next Steps (Milestone 1)

- [ ] Install SPM dependencies
- [ ] Get Supabase API keys
- [ ] Set up Supabase backend
- [ ] Create database schema
- [ ] Build Edge Functions

---

## File Overview

### Documentation 📚

| File | Purpose |
|------|---------|
| `README.md` | Quick start & overview |
| `docs/README.md` | Detailed architecture |
| `docs/API.md` | Backend API specification |
| `docs/ERD.md` | Database schema |
| `ENV_SETUP.md` | Environment configuration |
| `SPM_DEPENDENCIES.md` | Package installation guide |
| `MILESTONE_0_CHECKLIST.md` | Completion tracking |
| `MILESTONE_0_SUMMARY.md` | What was accomplished |
| `GETTING_STARTED.md` | This file! |

### Configuration ⚙️

| File | Purpose |
|------|---------|
| `.env.example` | API key template |
| `.gitignore` | Secrets protection |
| `.swiftlint.yml` | Code quality rules |
| `.github/workflows/ci.yml` | CI/CD automation |
| `.github/pull_request_template.md` | PR structure |

### Source Code 💻

| Location | Purpose |
|----------|---------|
| `Pulsar/App/` | App entry & global state |
| `Pulsar/App/Config/` | Feature flags, environment |
| `Pulsar/Features/` | Feature modules (scaffolded) |
| `Pulsar/Shared/` | Shared code (scaffolded) |
| `PulsarTests/` | Unit tests (Swift Testing) |

---

## Common Tasks

### Run Tests

```bash
# In Xcode: Cmd+U
# Or command line:
xcodebuild test -scheme PulsarTests -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

### Swift 6 Compliance

The codebase is written for **Swift 6** with strict concurrency:

- **Language mode**: In Xcode, set **Build Settings → Swift Language Version** to **Swift 6** (or leave default when using Xcode 16+).
- **Strict concurrency**: With Swift 6, full concurrency checking is on by default. The project uses:
  - `@MainActor` for UI and app state (`AppState`, `SupabaseClient`, `ObservabilityManager`, `FeatureFlags`)
  - `Sendable` for types that cross isolation boundaries (models, errors, enums)
  - No `[String: Any]` in public APIs; use `[String: String]` or `Data`/`Encodable` for Sendable safety
- If you use an older Xcode with Swift 5, enable **Build Settings → Other Swift Flags**: `-strict-concurrency=complete` (warnings) to prepare for Swift 6.

### Run Linter

```bash
# Install SwiftLint (if not already installed)
brew install swiftlint

# Run linter
swiftlint lint

# Auto-fix issues
swiftlint --fix
```

### View Git History

```bash
git log --oneline --graph --decorate --all
```

Current commits:
```
* 13eb3f9 docs: Complete Milestone 0 summary and status report
* 618f58f docs: Add SPM dependencies guide and .env.example
* 71026c6 docs: Add Milestone 0 completion checklist  
* b91b1ea feat: Initial project bootstrap for Milestone 0
* 4fe32a7 Initial Commit
```

### Create Pull Request

When ready to merge to `main`:

```bash
# Push branch (if not already pushed)
git push origin milestone-0-bootstrap

# Then create PR on GitHub with the template
```

---

## Environment Configuration

### For Development (Local Testing)

1. **Edit Xcode Scheme**:
   - **Product → Scheme → Edit Scheme**
   - **Run → Arguments → Environment Variables**
   - Add:
     ```
     SUPABASE_URL = https://your-project.supabase.co
     SUPABASE_ANON_KEY = your-key-here
     ENABLE_ANALYTICS = false
     ENABLE_CRASHLYTICS = false
     ```

### For Production (CI/CD)

Set secrets in GitHub:
- **Settings → Secrets and variables → Actions**
- Add required secrets

See `ENV_SETUP.md` for detailed instructions.

---

## Architecture Overview

```
┌─────────────────────────────────────────────┐
│              Pulsar App                      │
│  (SwiftUI + TCA + SwiftData + Swift 6.2)    │
└─────────────────────────────────────────────┘
                      │
        ┌─────────────┼─────────────┐
        │             │             │
   ┌────▼───┐   ┌────▼───┐   ┌────▼───┐
   │  App   │   │Features│   │ Shared │
   │ State  │   │ Modules│   │  Code  │
   └────┬───┘   └────┬───┘   └────┬───┘
        │            │            │
        └────────────┼────────────┘
                     │
        ┌────────────▼────────────┐
        │   Supabase Backend      │
        │ (Postgres + PostGIS +   │
        │  Auth + Storage)        │
        └─────────────────────────┘
```

### Key Technologies

- **SwiftUI**: Declarative UI
- **TCA**: Unidirectional data flow
- **SwiftData**: Local persistence
- **Observation**: Reactive state management
- **Swift Concurrency**: async/await, actors
- **Swift Testing**: Modern unit testing

---

## Feature Flags

Control feature availability at runtime:

| Flag | Default | Purpose |
|------|---------|---------|
| `ENABLE_ANALYTICS` | `false` | PostHog analytics |
| `ENABLE_CRASHLYTICS` | `false` | Firebase crash reporting |
| `USE_MAPBOX` | `false` | Mapbox instead of MapKit |

Set via environment variables or Xcode scheme.

---

## Troubleshooting

### Build Fails

```bash
# Clean build folder
Cmd+Shift+K

# Delete derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Rebuild
Cmd+B
```

### SPM Dependencies Won't Resolve

```bash
# In Xcode:
File → Packages → Reset Package Caches
File → Packages → Resolve Package Versions
```

### Tests Fail

Ensure you're running on a concrete simulator (not "Any iOS Simulator").

### Environment Not Configured

This is normal if you haven't set API keys yet. The app will still run, just with limited backend functionality.

---

## What's Next?

### Immediate Actions (You)

1. ✅ Review this guide
2. ✅ Open Xcode and verify build succeeds
3. ✅ Install SPM dependencies
4. ✅ Review documentation
5. ✅ Provide API keys when ready for Milestone 1

### Next Milestone (Milestone 1)

**Supabase Backend Scaffolding**

1. Install Supabase CLI
2. Initialize Supabase project
3. Create database migrations
4. Build Edge Functions for:
   - Activity ingestion
   - Segment matching
   - Leaderboards
5. Set up authentication

---

## Resources

- **Project Docs**: `docs/README.md`
- **API Docs**: `docs/API.md`
- **Database Schema**: `docs/ERD.md`
- **Environment Setup**: `ENV_SETUP.md`
- **SPM Packages**: `SPM_DEPENDENCIES.md`

---

## Support

Questions or issues? Check:
1. Documentation in `docs/`
2. Inline code comments
3. Commit history for context

---

## Success! 🎉

**Milestone 0 is complete!** The Pulsar app is ready for feature development.

**What we built**:
- ✅ Production-quality architecture
- ✅ Modern Swift 6.2 codebase
- ✅ Automated CI/CD pipeline
- ✅ Comprehensive documentation
- ✅ Security-first configuration
- ✅ Scalable feature structure

**Ready for Milestone 1**: Backend integration with Supabase!

---

**Last Updated**: October 27, 2025  
**Status**: ✅ Milestone 0 Complete

