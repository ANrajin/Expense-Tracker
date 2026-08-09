# Changelog

Agent-context history of what shipped, in which app version, and when. This is not user-facing
release notes — for current feature behavior see `docs/specs.md`; for architecture and handoff
notes see `docs/implementation-summary.md`. Every entry here corresponds to a version bump in
`src/pubspec.yaml`, and is added by the `mobile-engineer` agent once a spec'd feature is
implemented and verified (`flutter analyze` clean, `flutter test` passing).

---

## v1.2.0+3 — 2026-08-09

- §8 Wealth Tracking — new Wealth tab covering assets (name/kind/amount, hand-maintained),
  investments (manual current value with app-computed gain/loss in ৳ and %), and lending/borrowing
  (one `Loan` model discriminated by `direction`, partial repayments logged against it, settled
  derived from outstanding rather than stored), plus a Net Worth figure = assets + investment
  current value + outstanding lent − outstanding borrowed; four new Hive boxes (`assets`,
  `investments`, `loans`, `repayments`; typeIds 2–5, next free is 6), entirely separate from the
  transaction ledger — `calculateBalance` and the Dashboard's Total Balance are untouched
- §2 Category Management / §7 App Navigation Drawer — Wealth replaces Categories in the bottom nav
  (Dashboard/History/Reports/Wealth); Categories moved into the drawer as a pushed route beside Data
  Management, and gained its own `Scaffold`/`SafeArea`/back header since `AppShell` no longer wraps it
- §6 Data Management — body copy now states that only transactions are deleted there; categories and
  wealth entries are left untouched

Two implementation notes worth carrying forward: repayments live in their own box keyed by `loanId`
rather than embedded on the loan (a nested `@HiveType` needs its own adapter anyway, and only a
top-level `HiveObject` supports the app-wide `update(x) => x.save()` idiom), and settlement uses a
sub-paisa epsilon (`0.005`) so a 1000 loan repaid as 333.33 + 333.33 + 333.34 actually settles
instead of hanging on a rounding residue. The loan-delete cascade is orchestrated at the call site
in `loan_detail_screen.dart`, so neither notifier holds a `Ref` to the other.

`flutter analyze` clean, `flutter test` 71/71 passing (47 new tests for `isValidAssetInput`,
`sortedAssets`/`totalAssets`, `calculateGainLoss`, `overallInvestmentGainLoss`,
`isValidInvestmentInput`, `loanOutstanding`/`isLoanSettled`, `isValidRepaymentInput`,
`buildLoanSummaries`, `LoanSummary.isOverdue`, `repaymentIdsForLoan`, `isValidLoanInput`,
`calculateWealthTotals`, plus a regression group pinning `calculateBalance` as unchanged).
Live-on-device verification not performed this session.

## v1.1.0+2 — 2026-08-06

- §7 App Navigation Drawer — top-bar menu icon opens a side drawer with "Data Management" and
  "Exit App" (`SystemNavigator.pop()`, no confirmation); bottom nav and dark-mode toggle unchanged
- §6 Data Management — new screen listing years/months that hold transactions, with per-month,
  per-year and all-history permanent delete behind a type-DELETE confirmation stating the scope
  label and exact transaction count; bulk delete added to `TransactionRepository.deleteMany`

`flutter analyze` clean, `flutter test` 24/24 passing (10 new tests for `buildDeletionPeriods`,
`transactionIdsInScope`, `isDeleteConfirmed`). Live-on-device verification not performed this
session; provider propagation to Dashboard/History/Reports was verified via a throwaway
Hive-backed `ProviderContainer` harness (listeners fired once, values reduced, no manual refresh).

## v1.0.0+1 — 2026-08-02

Initial MVP release. All five v1 spec features shipped:

- §1 Transaction Management — add/edit/delete transactions, BDT formatting, validation
- §2 Category Management — CRUD categories, guarded delete, default seed set
- §3 Dashboard — balance, current-month summary, recent activity, add-transaction FAB
- §4 Transaction History — month-paged, day-grouped transaction list
- §5 Monthly Reports — per-month category donut chart, 6-month income/expense trend chart

Verified live on Android emulator (`Pixel_6_API_35`). `flutter analyze` clean, `flutter test` 14/14 passing.
