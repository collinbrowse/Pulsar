# Milestones summary (current)

**Last aligned with codebase:** April 2026  
**Source of truth for the checklist:** repository root [`README.md`](../../../README.md).

This file expands the same milestone definitions with a bit more detail. Historical write-ups for **M0** and **M1** remain in [`MILESTONE_0_SUMMARY.md`](../../../MILESTONE_0_SUMMARY.md) and [`MILESTONE_1_SUMMARY.md`](../../../MILESTONE_1_SUMMARY.md).

| # | Milestone | Status | Notes |
|---|-----------|--------|--------|
| 0 | Foundation | Done | CI, structure, docs bootstrap |
| 1 | Supabase backend | Done | Schema, RLS, Edge Functions (see M1 summary) |
| 2 | Auth & profiles | Done | Onboarding, session persistence, profile flows |
| 3 | Activity import | Done | File import (e.g. GPX), parsers and UI |
| 4 | Social feed | Done | Feed, interaction with backend DTOs |
| 5 | Segments & leaderboards | Done | Segments tab, Supabase-backed segment list, detail with leaderboard-style UI |
| 6 | Analytics & goals | **Partial** | Profile aggregates / time filtering; goals, charts, notifications not shipped |
| 7 | Routes & discovery | **Partial** | Route geometry previews; no standalone routes product |
| 8 | Clubs & challenges | **Not shipped** | No dedicated feature module |
| 9 | Privacy controls | **Partial** | Activity visibility surfaced in UI; privacy zones / full controls not shipped |
| 10 | Premium | **Partial** | Feature flags and observability hooks; no StoreKit paywall |

**Docs vs code:** [`docs/README.md`](../../../docs/README.md) describes the **target** Strava-style surface area. The table above reflects **what is implemented today**.
