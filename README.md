# 📱 Pulsar - Activity Tracking & Social Fitness

**Production-Quality iOS Application**  
iOS 26+ | Swift 6.2 | SwiftUI | Supabase

---

## 🎯 Quick Start

### Prerequisites
- Xcode 26+
- iOS 26.0 SDK
- macOS 15 (Sonoma)+

### Setup & Run
```bash
git clone https://github.com/your-username/pulsar.git
cd pulsar
cp .env.example .env.local
# Edit .env.local with your API keys
open Pulsar.xcodeproj
# Press Cmd+R to run
```

---

## 📚 Documentation

**Index inside Xcode:** [`Pulsar/Documentation/README.md`](Pulsar/Documentation/README.md) (links out to the rest of the repo).

### 📂 Quick links
- [Documentation index](Pulsar/Documentation/README.md)
- [Getting started](GETTING_STARTED.md) (repo root)
- [Milestones summary](Pulsar/Documentation/Milestones/MILESTONES_SUMMARY.md)
- [Development metrics](Pulsar/Documentation/METRICS.md)
- [Product / architecture spec](docs/README.md)
- [API](docs/API.md)
- [Supabase setup](infra/SUPABASE_SETUP.md)

---

## 🏗️ Tech Stack

- **iOS**: Swift 6.2, SwiftUI, SwiftData
- **Backend**: Supabase (PostgreSQL + PostGIS)
- **Testing**: Swift Testing + XCTest
- **Analytics**: PostHog
- **Crash Reporting**: Firebase Crashlytics

---

## ✅ Progress

Status below matches the **current codebase and recent commits** (verified April 2026).

- [x] M0: Foundation (CI/CD, project setup)
- [x] M1: Backend scaffolding (Supabase, database)
- [x] M2: Authentication & profiles
- [x] M3: Activity import (GPX/TCX/FIT)
- [x] M4: Social feed basics
- [x] M5: Segments & leaderboards (segments tab, Supabase-backed list, segment detail with leaderboard UI)
- [ ] M6: Analytics & goals (**partial:** profile aggregates and time filters; goals, charts, and notifications not shipped)
- [ ] M7: Routes & discovery (**partial:** route previews and coordinates on activities/segments; no dedicated routes product)
- [ ] M8: Clubs & challenges (not shipped)
- [ ] M9: Privacy controls (**partial:** visibility on activities; privacy zones and full settings not shipped)
- [ ] M10: Premium tier (**partial:** feature flags / observability hooks; no StoreKit paywall)

**See:** [Milestones Summary](Pulsar/Documentation/Milestones/MILESTONES_SUMMARY.md) for details.

---

## 🧪 Testing

```bash
# Run all tests
xcodebuild test -project Pulsar.xcodeproj -scheme Pulsar

# Or in Xcode
Cmd+U
```

**Current status (approximate from sources):**
- ✅ On the order of **100+** Swift Testing `@Test` cases across `PulsarTests` (run **Cmd+U** / `xcodebuild test` for the exact count and pass state).
- ✅ **~19** UI test methods in `PulsarUITests`.
- Coverage percentage is **not** produced in CI; treat **80%+** as a **goal** when running coverage locally.

---

**Production readiness (run before release)**

1. **Unit tests**: `xcodebuild test -scheme PulsarTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` (or your simulator)
2. **UI tests**: `xcodebuild test -scheme PulsarUITests -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
3. **Build**: `xcodebuild -scheme Pulsar -destination 'generic/platform=iOS Simulator' build`
4. **Lint**: `swiftlint lint`
5. **Security**: No `.env` or `.env.local` committed; no hardcoded `sk_live_`, `pk_live_`, `ghp_`, or `gho_` in Swift files.

CI runs lint, security checks, and code-structure verification on push/PR. Full build and tests require local Xcode with iOS SDK.

## Architecture

## 🚀 CI/CD

**Git:** day-to-day work merges to **`develop`**; **`main`** is updated when promoting a release. Details: [Branching strategy](docs/README.md#branching-strategy).

GitHub Actions runs on pushes and PRs to `main` and `develop` (see `.github/workflows/ci.yml`):

- ✅ SwiftLint (macOS runner; warnings allowed)
- ✅ Security checks (no committed `.env`, no hardcoded live keys in Swift)
- ✅ Code structure verification (Swift file count, test dirs, core folders, key docs)

Full **build, unit tests, and UI tests** require **local Xcode 26** with the iOS 26 SDK (not available on the current CI runners).

---

## 📄 License

Proprietary - All rights reserved

---

## 🆘 Support

Start from [`Pulsar/Documentation/README.md`](Pulsar/Documentation/README.md) for an index of all guides (setup, API, infra, milestones).
