# Changelog

Agent-context history of what shipped, in which app version, and when. This is not user-facing
release notes — for current feature behavior see `docs/specs.md`; for architecture and handoff
notes see `docs/implementation-summary.md`. Every entry here corresponds to a version bump in
`src/pubspec.yaml`, and is added by the `mobile-engineer` agent once a spec'd feature is
implemented and verified (`flutter analyze` clean, `flutter test` passing).

---

## v1.0.0+1 — 2026-08-02

Initial MVP release. All five v1 spec features shipped:

- §1 Transaction Management — add/edit/delete transactions, BDT formatting, validation
- §2 Category Management — CRUD categories, guarded delete, default seed set
- §3 Dashboard — balance, current-month summary, recent activity, add-transaction FAB
- §4 Transaction History — month-paged, day-grouped transaction list
- §5 Monthly Reports — per-month category donut chart, 6-month income/expense trend chart

Verified live on Android emulator (`Pixel_6_API_35`). `flutter analyze` clean, `flutter test` 14/14 passing.
