# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Role

This repo defines two subagents in `.claude/agents/` — dispatch to the matching one rather than doing the work directly, and don't blend the two roles into one response:

- **`product-owner`** — requirement analysis and spec changes: any new feature, scope change, or anything that touches `docs/specs.md`. Clarifies ambiguous or incomplete requirements with the user before writing anything, then owns writing the spec entry (Goal / Acceptance Criteria / In-scope / Out-of-scope / Assumptions). Never writes app code.
- **`mobile-engineer`** — feature implementation: writing or changing app code, bug fixes, refactors, tests. Builds against `docs/specs.md` as binding requirements — never edits it, never reinterprets it. If implementation reveals the spec is wrong or incomplete, it halts and reports back rather than improvising, which is a return trip to `product-owner`.

For a request that needs both — a feature that isn't spec'd yet — run `product-owner` first and only move to `mobile-engineer` once the spec entry is settled. Full definitions, including exactly what each does and refuses to do, are in their respective files under `.claude/agents/`.

## Project layout

Repo root:
```
Expense Tracker/
  docs/    product spec, implementation history, UI mockup, app icons
  src/     Flutter project root — all app code lives here
```

`docs/specs.md` is the single source of truth for product features (Goal / Acceptance Criteria / In-scope / Out-of-scope / Assumptions per feature). Update it whenever a feature is added or its scope changes — it must always reflect the current, real state of the app. `docs/implementation-summary.md` is a handoff snapshot of what was built and how; consult it for prior architectural decisions and known issues. `docs/CHANGELOG.md` is the version-by-version release history — agent context only, not user-facing — recording when each spec'd feature actually shipped, tied to `pubspec.yaml` version bumps; `mobile-engineer` appends to it after each verified feature (see that agent's definition for the exact workflow).

All commands below are run from `src/`.

## Commands

- Install deps: `flutter pub get`
- Run the app on a connected device/emulator: `flutter run`
- Static analysis (should stay clean): `flutter analyze`
- Run the full test suite: `flutter test`
- Run a single test file: `flutter test test/providers_test.dart`
- Regenerate Hive adapters after changing a model in `lib/data/models/`: `dart run build_runner build --delete-conflicting-outputs`
- Launch the reference emulator if none is running: `flutter emulators --launch Pixel_6_API_35`

Package: `expense_tracker`, applicationId `com.expensetracker.expense_tracker`. Android-only target (no iOS).

## Architecture

- **State management:** Riverpod (`flutter_riverpod`) — `Provider`, `Provider.family`, `StateProvider`, `StateNotifierProvider`/`StateNotifier`.
- **Persistence:** Hive (`hive`, `hive_flutter`), fully offline/local, no backend. Boxes: `settings`, `categories` (`Box<Category>`), `transactions` (`Box<Transaction>`), `assets` (`Box<Asset>`), `investments` (`Box<Investment>`), `loans` (`Box<Loan>`), `repayments` (`Box<Repayment>`). typeIds 0–5 are in use — **next free is 6**. Models live in `lib/data/models/` with generated `*.g.dart` adapters; repositories in `lib/data/repositories/` wrap each box with CRUD.
- **Testability pattern:** provider logic that needs unit testing is extracted into pure, top-level functions (e.g. `calculateBalance`, `calculateMonthSummary`, `groupHistoryByDay`, `isValidTransactionInput`, `canDeleteCategory`, `calculateWealthTotals`, `loanOutstanding`) — providers are thin wrappers around these. This sidesteps Riverpod's strict `overrideWith` typing on `StateNotifierProvider` and keeps tests Hive-free. Follow this pattern for new business logic instead of putting it directly in a `StateNotifier`.
- **Charts:** hand-rolled `CustomPainter` (donut + grouped bar trend chart) in `lib/features/reports/report_charts.dart` — intentionally no charting package, to match the original prototype's SVG geometry exactly.
- **Theming:** `ThemeExtension<AppColors>` (`lib/core/theme/app_theme.dart`) carries spec-exact semantic colors (income/expense/primarySoft/etc.) on top of Material's `ColorScheme`; income = green, expense = red, consistent across light and dark mode.
- **Navigation:** bottom `NavigationBar` for the four primary tabs (Dashboard/History/Reports/Wealth), defined in `AppShell` (`lib/app.dart`) as three index-aligned static lists. Categories and Data Management are pushed routes reached from `AppDrawer` — pushed screens carry their own `Scaffold` + `SafeArea` + back header; tab screens don't, because `AppShell` supplies those.

### Directory structure (`src/lib`)

```
main.dart      Hive init, adapter registration, box opening, seeding, ProviderScope
app.dart       theme mode provider/notifier, active-tab provider, MaterialApp, AppShell
core/          formatting helpers, theme, shared widgets
data/          Hive models + repositories
features/      one folder per feature area (categories, transactions, dashboard, reports,
               data_management, wealth), each with its provider(s) and screen(s)
```

## Known gotchas

- `Box.values()` in Hive iterates by internal key order, not insertion order — `CategoryRepository.getAll()` applies explicit sorting (defaults in canonical seed order, then customs alphabetically) to compensate. The Wealth repositories instead return unsorted and let pure functions (`sortedAssets`, `sortedInvestments`, `buildLoanSummaries`) do the ordering, so the rules stay testable without Hive. Either approach is fine for a new listing — just don't rely on `Box.values` order.
- Every Hive adapter must be registered *before* any typed box is opened, and every box opened before `runApp` — `AppShell`'s `IndexedStack` builds all four tabs on the first frame, so a box left unopened is a launch crash rather than a lazy failure.
- `@HiveField` indices are permanent. A field added to an existing model after first install must be declared with `@HiveField(n, defaultValue: …)`, or the generated cast throws when reading records written before the field existed.
