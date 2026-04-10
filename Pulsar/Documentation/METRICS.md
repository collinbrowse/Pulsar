# Pulsar — development metrics & status

**Project start:** October 27, 2025  
**Last updated:** April 10, 2026  
**Developer:** Collin Browse  

This file was **reset for accuracy** in April 2026. Older versions claimed all milestones complete and App Store readiness; that did **not** match the repository. Use this document together with the root [`README.md`](../../README.md) checklist.

---

## Executive summary

| Metric | Value / note |
|--------|----------------|
| **Shipped milestone core** | M0–M5 implemented in code (through segments / leaderboard-style UI) |
| **Later milestones** | M6–M10: partial or not shipped — see table below |
| **App Swift sources** | On the order of **40** files under `Pulsar/` (branch-dependent) |
| **Test layout** | ~14 unit test files, 2 UI test files |
| **Backend** | Supabase (Postgres + PostGIS, RLS, Edge Functions) — see [`MILESTONE_1_SUMMARY.md`](../../MILESTONE_1_SUMMARY.md) |
| **CI** | Lint + security + structure only — full build/tests need **local Xcode 26** |

---

## Milestone status (code-aligned)

| # | Milestone | Status | Delivered in repo (high level) |
|---|-----------|--------|--------------------------------|
| 0 | Project bootstrap | Done | CI wiring, layout, docs |
| 1 | Supabase backend | Done | Migrations, functions, schema |
| 2 | Auth & profiles | Done | Onboarding, session, profile surfaces |
| 3 | Activity import | Done | Import UI + GPX (and related parsers/tests) |
| 4 | Feed & social | Done | Feed with backend DTOs |
| 5 | Segments & leaderboards | Done | Segments tab, `segments` fetch, detail + leaderboard UI |
| 6 | Analytics & goals | Partial | `ProfileAnalytics`, time filters; no goals / charts product |
| 7 | Routes & discovery | Partial | `RoutePreview`, route fields on models; no routes feature area |
| 8 | Clubs & challenges | Not shipped | — |
| 9 | Privacy controls | Partial | Activity visibility; no privacy zones |
| 10 | Premium | Partial | `FeatureFlags` / observability; no StoreKit paywall |

---

## Quality & stack (honest)

- **Swift / SwiftUI:** Swift 6–oriented settings, async/await networking, `@Observable` app state.
- **TCA:** Described in [`docs/README.md`](../../docs/README.md) as part of the **target** design; **not** a current app dependency — verify with `import ComposableArchitecture` before claiming TCA in resumes.
- **Tests:** Broad `PulsarTests` coverage of models, flows, networking, GPX; UI tests cover main tabs. Pass counts and coverage are **local** metrics.
- **Security:** No secrets in repo; RLS on backend (see infra docs).

---

## Roadmap

For backlog items (HealthKit sync, push, offline, widgets, clubs, premium, etc.), see:

- Root [`README.md`](../../README.md)  
- [`docs/README.md`](../../docs/README.md) (full product vision)

---

## Historical note

Earlier revisions of this file mixed **aspirational resume copy** with **factual status**. Those claims (e.g. “10/10 milestones”, “production ready” for the full Strava-style scope) are **deprecated**. Use the tables above and git history for factual reporting.
