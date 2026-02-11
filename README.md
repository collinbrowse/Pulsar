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

**All documentation is now inside the Xcode project for easy access:**

### 📖 Open in Xcode
Navigate to: **`Pulsar/Documentation/README.md`**

Or browse the documentation folders:
- **Setup/** - Environment setup, dependencies, getting started
- **Development/** - API docs, error tracking, bug fixes, test coverage
- **Testing/** - UI testing guide
- **Infrastructure/** - Supabase backend setup
- **Milestones/** - Project progress and business reports
- **Business/** - Business-oriented milestone reports

### 📂 Quick Links
- [Main Documentation](Pulsar/Documentation/README.md)
- [Setup Guide](Pulsar/Documentation/Setup/GETTING_STARTED.md)
- [Milestones Summary](Pulsar/Documentation/Milestones/MILESTONES_SUMMARY.md)
- [Development Metrics](Pulsar/Documentation/METRICS.md)

---

## 🏗️ Tech Stack

- **iOS**: Swift 6.2, SwiftUI, SwiftData
- **Backend**: Supabase (PostgreSQL + PostGIS)
- **Testing**: Swift Testing + XCTest
- **Analytics**: PostHog
- **Crash Reporting**: Firebase Crashlytics

---

## ✅ Progress

- [x] M0: Foundation (CI/CD, project setup)
- [x] M1: Backend scaffolding (Supabase, database)
- [x] M2: Authentication & profiles
- [x] M3: Activity import (GPX/TCX/FIT)
- [x] M4: Social feed basics
- [ ] M5: Segments & leaderboards
- [ ] M6: Analytics & goals
- [ ] M7-10: Routes, clubs, privacy, premium

**See:** [Milestones Summary](Pulsar/Documentation/Milestones/MILESTONES_SUMMARY.md) for details.

---

## 🧪 Testing

```bash
# Run all tests
xcodebuild test -project Pulsar.xcodeproj -scheme Pulsar

# Or in Xcode
Cmd+U
```

**Current Status:**
- ✅ 59 unit tests passing
- ✅ 15+ UI tests passing
- ✅ >80% test coverage

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

GitHub Actions runs on every push:
- ✅ Build verification
- ✅ All tests (unit + UI)
- ✅ SwiftLint checks
- ✅ Code coverage

---

## 📄 License

Proprietary - All rights reserved

---

## 🆘 Support

**For detailed documentation, open the project in Xcode and navigate to:**

```
Pulsar/Documentation/
```

**All guides, setup instructions, and API docs are there! 📖**
