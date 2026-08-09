# Expense Tracker — Implementation Summary

**App version:** 1.2.0+3 (`src/pubspec.yaml`)
**Date:** 2026-08-09
**Status:** All 8 planned phases complete and verified on a real Android emulator; §6 Data
Management, §7 App Navigation Drawer and §8 Wealth Tracking added afterwards (analyze/test
verified, not yet exercised on a device).

This document is a handoff snapshot for a future AI agent session (or human) picking up this
project. It captures what exists, how it's built, and what — if anything — remains.

---

## 1. Project layout

```
Expense Tracker/
  docs/
    specs.md                 source-of-truth product spec
    mockup/                  interactive HTML/JS UI prototype (reference only, not shipped code)
    implementation-summary.md   <- this file
  src/                        Flutter project root (all app code lives here)
```

Package name: `expense_tracker`, org `com.expensetracker` → applicationId
`com.expensetracker.expense_tracker`. Android-only target.

## 2. Architecture

- **State management:** Riverpod (`flutter_riverpod`) — `Provider`, `Provider.family`,
  `StateProvider`, `StateNotifierProvider`/`StateNotifier`.
- **Persistence:** Hive (`hive`, `hive_flutter`), codegen via `hive_generator` + `build_runner`.
  Boxes: `settings`, `categories` (`Box<Category>`), `transactions` (`Box<Transaction>`),
  `assets` (`Box<Asset>`), `investments` (`Box<Investment>`), `loans` (`Box<Loan>`),
  `repayments` (`Box<Repayment>`). typeIds 0–5 are taken; **next free typeId is 6**. Every adapter
  registers before any typed box opens, and every box opens before `runApp` — `AppShell`'s
  `IndexedStack` builds all four tabs on the first frame, so an unopened box is a launch crash.
- **Charts:** hand-rolled `CustomPainter` (donut + grouped bar trend chart) — no charting
  package, to match the prototype's SVG chart geometry exactly.
- **Theming:** custom `ThemeExtension<AppColors>` for spec-exact light/dark semantic colors
  (income/expense/primarySoft/etc.) layered on top of Material `ColorScheme`.
- **Testability pattern:** all provider logic that needs unit testing is extracted into pure,
  top-level functions (`calculateBalance`, `calculateMonthSummary`, `selectRecentTransactions`,
  `groupHistoryByDay`, `isValidTransactionInput`, `canDeleteCategory`, `calculateWealthTotals`,
  `loanOutstanding`, `buildLoanSummaries`, `calculateGainLoss`); providers are thin
  wrappers around these. This sidesteps Riverpod's strict `overrideWith` typing on
  `StateNotifierProvider` and keeps the test suite Hive-free.
- **Navigation:** four bottom tabs — Dashboard / History / Reports / Wealth. Categories and Data
  Management are pushed routes reached from `AppDrawer`, so they carry their own `Scaffold` +
  `SafeArea` + back header; the four tab screens do not, because `AppShell` supplies those.

### Directory structure (`src/lib`)

```
lib/
  main.dart                          Hive init, adapter registration, box opening, seeding, ProviderScope
  app.dart                           theme mode provider/notifier, active-tab provider, MaterialApp,
                                     AppShell (bottom nav + top-bar menu icon), AppDrawer
  core/
    format.dart                      fmtBDT, ISO date helpers, label formatters
    theme/app_theme.dart             AppColors extension (light/dark), AppTheme.light/.dark
    widgets/screen_header.dart       shared header (date + title)
    widgets/transaction_row.dart     shared transaction list row
    widgets/wealth_row.dart          shared wealth list row + WealthBadge pill
  data/
    models/category.dart             Hive model (typeId 0) + category.g.dart
    models/transaction.dart          Hive model (typeId 1) + transaction.g.dart
    models/asset.dart                Hive model (typeId 2) + asset.g.dart
    models/investment.dart           Hive model (typeId 3) + investment.g.dart
    models/loan.dart                 Hive model (typeId 4) + loan.g.dart
    models/repayment.dart            Hive model (typeId 5) + repayment.g.dart
    repositories/category_repository.dart      CRUD + default-category seeding + explicit sort order
    repositories/transaction_repository.dart   CRUD + countByCategory + deleteMany (bulk)
    repositories/asset_repository.dart         CRUD (unsorted — sorting lives in pure functions)
    repositories/investment_repository.dart    CRUD
    repositories/loan_repository.dart          CRUD
    repositories/repayment_repository.dart     CRUD + deleteMany (loan-delete cascade)
  features/
    categories/       categories_provider.dart, categories_screen.dart (pushed route)
    transactions/      transactions_provider.dart, transaction_form_screen.dart,
                       history_provider.dart, history_screen.dart
    dashboard/         dashboard_provider.dart, dashboard_screen.dart
    reports/           reports_provider.dart, report_charts.dart, reports_screen.dart
    data_management/   data_management_provider.dart, data_management_screen.dart
    wealth/            wealth_provider.dart, assets_provider.dart, investments_provider.dart,
                       loans_provider.dart, wealth_screen.dart, wealth_form_parts.dart,
                       asset_form_screen.dart, investment_form_screen.dart,
                       loan_form_screen.dart, loan_detail_screen.dart
```

## 3. Feature status — all complete

| Phase | Feature | Status |
|---|---|---|
| 0 | Save UI mockup into `docs/mockup/` | Done |
| 1 | Project scaffolding, theme, app shell, bottom nav | Done |
| 2 | Category management (CRUD, active/hidden toggle, guarded delete) | Done |
| 3 | Transaction management (add/edit/delete, validation) | Done |
| 4 | Dashboard (balance, month summary, recent activity, FAB) | Done |
| 5 | Transaction History (month pager, day grouping, tap-to-edit) | Done |
| 6 | Monthly Reports (donut chart, 6-month trend chart) | Done |
| 7 | Polish: theme toggle both modes, pure-function refactor, tests | Done |
| — | §7 App Navigation Drawer + §6 Data Management (v1.1.0+2) | Done (analyze/test only) |
| — | §8 Wealth Tracking + Categories moved to the drawer (v1.2.0+3) | Done (analyze/test only) |

Phases 0–7 were verified **live on a real Android emulator** (`Pixel_6_API_35`,
device id `emulator-5554`) via `adb`-driven screenshots and taps — not just static analysis.
Data persistence across app restarts was confirmed (real Hive boxes, not mocks). The later
drawer/Data Management work has **not** been exercised on a device yet.

`flutter analyze` is clean. `flutter test` passes **71 tests**
(`test/widget_test.dart` — `fmtBDT`; `test/providers_test.dart` — validation, delete guard,
balance/month-summary calculation, history grouping, Data Management period grouping,
delete-scope selection, the type-DELETE guard, and the Wealth groups: asset/investment/loan/
repayment validation, gain/loss, outstanding and settlement, loan listing order, overdue state,
the delete cascade set, and net worth).

## 4. Notable bugs found and fixed during implementation

- **Hive iteration-order bug:** `Box.values()` iterates by internal key order, not insertion
  order, which surfaced as new categories appearing in the wrong position in the Categories
  list. Fixed with explicit sorting in `CategoryRepository.getAll()` (defaults in canonical
  seed order, then customs alphabetically).
- **Riverpod `overrideWith` type-strictness** blocked testing `StateNotifierProvider`-backed
  logic directly — resolved by extracting pure functions (see Architecture above).

### Wealth design decisions worth not re-litigating (v1.2.0+3)

- **Loan settlement uses a sub-paisa epsilon (`0.005`), not `== 0`.** Repayment amounts are
  doubles, so a 1000 entry repaid as 333.33 + 333.33 + 333.34 leaves a residue around `1e-13` and
  would otherwise look permanently unsettled, with no way for the user to see or fix it.
- **Settled state is derived from outstanding, never stored.** A stored flag drifts the moment a
  repayment is edited or deleted; deriving it is also what makes deleting a repayment reopen a
  settled entry for free.
- **Repayments are a separate box keyed by `loanId`, not a list embedded on `Loan`.** A nested
  `@HiveType` would need its own adapter and typeId anyway, only a top-level `HiveObject` supports
  the app-wide `update(x) => x.save()` idiom, and separate lists keep outstanding/settled testable
  without Hive. The cost is no referential integrity: the cascade runs at the call site in
  `loan_detail_screen.dart` (repayments first), and every read filters on `loanId`, so a stray
  orphan is inert.
- **Lending and borrowing share one `Loan` model** with a `direction` discriminator, the same way
  `Transaction.type` handles income/expense — identical fields, identical operations. Direction is
  fixed after creation, since flipping it would silently reinterpret every repayment logged.
- **No new `AppColors` roles.** Wealth maps onto the existing income/expense semantics (lent and
  gains green, borrowed and losses red, neutral balances `textPrimary`), so `app_theme.dart` and
  the Design System table in `specs.md` were left alone.
- **Assets and Investments are separate models** — an asset carrying an invested/current pair would
  render a phantom gain/loss on a cash balance.

## 5. Remaining work

None from the original plan — all 5 spec features (Transaction Management, Category
Management, Dashboard, Transaction History, Monthly Reports) are implemented and verified
against `docs/specs.md` and the mockup, as are §6 Data Management, §7 App Navigation
Drawer and §8 Wealth Tracking. Nothing is stubbed or partially done. §6/§7/§8 are still owed a
live device pass (everything else has had one). For §8 that pass should specifically cover:
first-launch empty states on all four sections, the drawer route to Categories (it gained its own
`Scaffold` and back arrow when it stopped being a tab), and that deleting a loan really removes
its repayments from Hive across an app restart.

Possible future enhancements (not requested/scoped, listed only as options for a later session):
- iOS target (currently Android-only per spec).
- Data export/backup (Hive boxes are local-only; no cloud sync or file export exists).
- Search/filtering in Transaction History beyond month paging.
- Widget/integration tests beyond the current pure-function unit tests.

## 6. Running the app

From a terminal with Flutter/Android SDK on PATH:

```bash
cd "Expense Tracker/src"
flutter emulators --launch Pixel_6_API_35   # if no emulator is already running
flutter run
```

Press `r` for hot reload, `R` for hot restart, `q` to quit while `flutter run` is active.
