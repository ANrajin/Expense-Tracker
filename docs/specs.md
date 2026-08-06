# Expense Tracker — Product Spec

**Platform:** Android (Flutter)
**Data:** Fully offline, local storage only
**Status:** v1 (MVP) in planning

This document is the single source of truth for the product. Every feature is documented here before or as it's built. When a feature is added, changed, or its scope shifts, this spec is updated to match — it should always reflect the current, real state of the product, not just the original plan.

---

## 1. Transaction Management

**Goal**
Let the user record every income and expense as it happens, so their financial picture stays accurate and up to date with minimal friction.

**Acceptance Criteria**
- User can add a transaction with: amount, type (income or expense), category, date, and an optional note.
- User can edit any field of an existing transaction.
- User can delete a transaction.
- Amount must be a positive number; transaction cannot be saved without amount, type, category, and date.
- All amounts are entered, stored, and displayed in BDT (৳), formatted per standard Bangladeshi grouping conventions.
- A newly added or edited transaction is immediately reflected in the Dashboard, History, and Reports.

**In-scope**
- Single transaction entry at a time
- Income and expense types
- Manual date selection (defaults to today)
- Free-text optional note
- BDT as the app's sole currency

**Out-of-scope**
- Recurring/scheduled transactions
- Attachments or receipt photos
- Splitting a transaction across multiple categories
- Multi-currency entry or currency conversion

**Assumptions**
- All transactions belong to a single implicit "wallet" — there is no concept of separate accounts in v1.
- The user is the only person entering data; there's no multi-user or shared-ledger scenario.
- BDT is fixed as the only currency for v1; multi-currency support is a future enhancement, not a v1 concern.

---

## 2. Category Management

**Goal**
Give the user a way to classify transactions so spending patterns are visible in reports, without forcing rigid or limited categories.

**Acceptance Criteria**
- App ships with a default set of common income and expense categories on first launch.
- User can add a custom category with a name and type (income or expense).
- User can edit or delete a custom category.
- Default categories cannot be deleted, only hidden/deactivated if not in use.
- A category cannot be deleted if transactions are currently assigned to it (user must reassign or delete those transactions first).

**In-scope**
- Flat list of categories (no subcategories)
- Category type restricted to income or expense (matches transaction type)

**Out-of-scope**
- Subcategories or nested category hierarchies
- Category-level budgets or spending limits
- Shared/synced category sets across devices

**Assumptions**
- A reasonable default category list (e.g. Food, Transport, Bills, Shopping, Salary) is sufficient for most users at first launch.

---

## 3. Dashboard

**Goal**
Give the user an at-a-glance answer to "where do I stand right now" the moment they open the app.

**Acceptance Criteria**
- Displays current overall balance (all-time income minus all-time expense).
- Displays current month's total income and total expense.
- Displays the most recent transactions (a short list, not the full history).
- Provides a clearly visible action to add a new transaction from this screen.
- Updates automatically when a transaction is added, edited, or deleted — no manual refresh required.

**In-scope**
- Summary totals for the current month only
- A short, recent-activity list (not paginated)

**Out-of-scope**
- Custom date range selection on the dashboard
- Charts/graphs on the dashboard (charts live in Reports)
- Widgets or home-screen shortcuts

**Assumptions**
- "Current month" is based on the device's local calendar month.

---

## 4. Transaction History

**Goal**
Let the user browse, review, and manage every transaction they've ever recorded, not just recent activity.

**Acceptance Criteria**
- Displays all transactions, grouped by day.
- User can select a specific month to view only that month's transactions.
- User can open any transaction from the list to edit or delete it.
- List remains usable and responsive as the number of transactions grows over months/years of use.

**In-scope**
- Month-based filtering
- Grouping by day within a month

**Out-of-scope**
- Full-text search across notes
- Filtering by category or amount range
- Custom/arbitrary date range filtering

**Assumptions**
- Month-by-month browsing is sufficient for a personal-scale dataset; more advanced filtering isn't needed until usage patterns prove otherwise.

---

## 5. Monthly Reports

**Goal**
Help the user understand their financial behavior over a month — not just what happened, but where their money went — so they can reflect and adjust.

**Acceptance Criteria**
- User can select a month and view: total income, total expense, and net remaining (income minus expense) for that month.
- Displays a breakdown of expenses by category for the selected month (e.g. as a pie/donut chart).
- Displays a trend of income vs. expense across recent months (e.g. as a bar chart).
- Report reflects only finalized transaction data for the selected month — no estimates or projections.

**In-scope**
- Per-month totals and category breakdown
- Multi-month trend view (last several months)

**Out-of-scope**
- Exporting reports (PDF/CSV)
- Year-over-year or custom date range reports
- Forecasting or predictive spending insights
- Budget-vs-actual comparisons (depends on Budgeting, which is out-of-scope for v1)

**Assumptions**
- A rolling window of recent months (rather than full historical range) is sufficient for the trend view in v1.

---

## 6. Data Management

**Goal**
Let the user permanently remove transaction history they no longer need, by month, by year, or all at once, so they aren't forced to retain data indefinitely on a fully offline device with no cloud backup.

**Acceptance Criteria**
- User can reach the Data Management screen from the app's side navigation drawer (see §7 App Navigation Drawer).
- The screen lists the years (and months within each year) that contain at least one transaction.
- User can select a single month and delete every transaction dated within that month.
- User can select a single year and delete every transaction dated within that year, in one action.
- User can trigger a "Delete all history" action that removes every transaction in the app, regardless of period.
- Before any deletion runs, the app shows a confirmation dialog stating the exact scope (the period label, or "all history") and the number of transactions that will be permanently deleted.
- The confirmation dialog requires the user to type the word "DELETE" before the delete action becomes enabled.
- Deletion is permanent — there is no undo, recovery, or trash/archive step.
- Categories referenced only by deleted transactions are not themselves deleted; once no transactions reference them, they become deletable under the existing rule in Category Management.
- Dashboard, History, and Reports immediately reflect the reduced data set after deletion completes, with no manual refresh required.
- A period (or "all history") with zero transactions has its delete action unavailable.

**In-scope**
- Deleting all transactions within one selected month
- Deleting all transactions within one selected year
- Deleting all transactions across all history in a single action
- Type-to-confirm ("DELETE") safeguard before any deletion executes
- A new Data Management screen, reached via the app's side navigation drawer (see §7)

**Out-of-scope**
- Deleting an arbitrary/custom date range not aligned to a month or year boundary
- Deleting by category, transaction type, or amount
- Undo, recycle bin, or recovery of deleted transactions
- Exporting or backing up data before deletion (see Data export / Cloud backup in Future Enhancements)
- Deleting individual categories from this screen (category deletion stays in Category Management)

**Assumptions**
- Users may want to prune old history to keep the app lean or for privacy; since there's no cloud backup in v1, deletion is the only way to reduce stored data.
- Because the current month/year can also be deleted, the type-DELETE confirmation is the app's only safeguard against accidental data loss — there is no "protected" period.
- This is the app's first Settings-style surface; a minimal, single-purpose screen is sufficient here — a fuller Settings section (theme, currency, etc.) is not required by this feature.

---

## 7. App Navigation Drawer

**Goal**
Give the user a side drawer for app-wide actions that don't belong in the primary bottom navigation — starting with Data Management and exiting the app.

**Acceptance Criteria**
- A menu icon in the app's top bar opens a side navigation drawer.
- The drawer contains a "Data Management" entry that opens the Data Management screen (§6).
- The drawer contains an "Exit App" entry that closes the app immediately, with no confirmation prompt.
- Exit is implemented via Flutter's `SystemNavigator.pop()` (not a hard process kill like `dart:io`'s `exit()`), so it behaves like backing out from the root screen rather than surfacing as a crash in Android vitals.
- The drawer closes when an entry is tapped, or when the user taps outside it or swipes it away.

**In-scope**
- The drawer itself, opened via a top-bar menu icon
- Two entries for v1: Data Management, Exit App

**Out-of-scope**
- Moving existing navigation into the drawer — the bottom nav (Dashboard/History/Reports/Categories) and the top-bar dark-mode toggle stay exactly where they are today
- User profile, account switching, or app info/about entries
- Any confirmation step before exiting the app

**Assumptions**
- Two entries are enough to justify the drawer for v1; more app-wide actions may be added here later as new settings-like features are introduced.
- "Exit App" closes the app process outright rather than just navigating to the Dashboard tab — this is distinct from the OS back button/gesture behavior.

---

## Design System — Color Scheme

**Mood:** Fresh & energetic, green-based primary palette.
**Modes:** Both light and dark mode supported from v1.
**Convention:** Green = income, red = expense (standard, unambiguous at a glance).

| Role | Purpose | Light mode | Dark mode |
|---|---|---|---|
| Primary / Brand | Buttons, active states, FAB, highlights | Fresh green (e.g. `#2E7D32`–`#43A047` range) | Same hue, lightened for contrast on dark surface |
| Income | Income amounts, income category icons | Green (matches brand or a distinct emerald) | Lightened green, same hue family |
| Expense | Expense amounts, expense category icons | Red (e.g. `#D32F2F` range) | Lightened red, same hue family |
| Background | Page/app background | Off-white / very light gray | Near-black / dark charcoal |
| Surface | Cards, sheets, dialogs | White | Dark gray, one step lighter than background |
| Text primary | Main text (balances, titles) | Near-black | Near-white |
| Text secondary | Labels, captions, muted text | Mid gray | Light gray |
| Border | Dividers, card outlines | Light gray hairline | Subtle light-on-dark hairline |

**Notes**
- Income and expense colors stay consistent across both modes (same hue family, adjusted for contrast) so the user's visual muscle memory doesn't break when switching themes.
- The app should respect the device's system theme setting by default, with light/dark held as the only two states (no separate "auto" logic needed beyond following the OS).

---

## Future Enhancements

Features intentionally excluded from v1, to be spec'd in full (with their own feature entries above) when prioritized:

- **Budgeting** — set monthly spending limits per category, with progress/alerts.
- **Multiple accounts/wallets** — track cash, bank, and card balances separately.
- **Recurring transactions** — auto-log regular items like rent, subscriptions, or salary.
- **Multi-currency support**
- **Data export** — CSV/PDF export of transactions and reports
- **Cloud backup/sync** — optional backup off-device, without changing the offline-first default
