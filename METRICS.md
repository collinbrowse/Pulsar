# Pulsar — development metrics

**Project start:** October 27, 2025  
**Last updated:** April 10, 2026  
**Status:** Active development — **M0–M5 delivered in app**; M6–M10 partial or not shipped (see root `README.md`).

---

## Executive summary

| Area | Snapshot |
|------|-----------|
| **Milestones (code-aligned)** | M0–M5 done; M6–M10 partial / not shipped |
| **App Swift files** | ~40 under `Pulsar/` (varies with branches) |
| **Unit test files** | ~14 under `PulsarTests/` |
| **UI test files** | 2 under `PulsarUITests/` |
| **Backend** | Supabase: PostgreSQL + PostGIS, RLS, Edge Functions (see `MILESTONE_1_SUMMARY.md`) |
| **CI (GitHub Actions)** | SwiftLint, secret / structure checks — **not** full iOS build (needs Xcode 26 + iOS SDK locally) |

---

## Milestone status (verified against repo)

| # | Milestone | Status |
|---|-----------|--------|
| 0 | Project bootstrap | Done |
| 1 | Supabase backend | Done |
| 2 | Auth & profiles | Done |
| 3 | Activity import | Done |
| 4 | Feed & social | Done |
| 5 | Segments & leaderboards | Done |
| 6 | Analytics & goals | Partial (profile stats / filters; no goals product) |
| 7 | Routes & discovery | Partial (route previews; no routes hub) |
| 8 | Clubs & challenges | Not shipped |
| 9 | Privacy controls | Partial (visibility; no privacy zones) |
| 10 | Premium | Partial (flags / plumbing; no StoreKit paywall) |

---

## Testing

- **Swift Testing** is used heavily in `PulsarTests` (`@Test`). Exact count changes with commits — run **Cmd+U** or `xcodebuild test` for truth.
- **XCTest** UI tests live in `PulsarUITests`.
- **Coverage** is not produced in CI; treat percentage targets as local-only.

---

## Architecture notes

- **UI:** SwiftUI with shared `AppState` (`@Observable`) — see `AGENTS.md`.
- **docs/README.md** describes a **target** architecture (including TCA). The **shipping app** does not import The Composable Architecture today; treat that doc as product vision, not as a description of every file.

---

## Recent commit themes (indicative)

- Supabase RPCs / DTOs for feed, profile, segments  
- GPX import and parser tests  
- Auth persistence and onboarding UX  
- Swift 6 build settings and test hardening  

---

## Future work

See **Future Roadmap** in root `README.md` and `docs/README.md` for planned features (HealthKit sync, push, offline, widgets, StoreKit, clubs, etc.).
