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
- User reaches Category Management from the app's side navigation drawer (see §7 App Navigation Drawer), which opens it as a full-screen route; it is not one of the bottom navigation tabs.

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
- Net worth, assets, investments, and lent/borrowed money — these are tracked in §8 Wealth Tracking and are never folded into Total Balance, which stays all-time income minus all-time expense

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
- Every action on this screen deletes transactions only — categories (§2) and all wealth entries (§8 Wealth Tracking) survive untouched, including after "Delete all history".
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
- Transaction records only, as the sole data type this screen can delete
- Type-to-confirm ("DELETE") safeguard before any deletion executes
- A new Data Management screen, reached via the app's side navigation drawer (see §7)

**Out-of-scope**
- Deleting an arbitrary/custom date range not aligned to a month or year boundary
- Deleting by category, transaction type, or amount
- Undo, recycle bin, or recovery of deleted transactions
- Exporting or backing up data before deletion (see Data export / Cloud backup in Future Enhancements)
- Deleting individual categories from this screen (category deletion stays in Category Management)
- Deleting wealth entries — assets, investments, and lending/borrowing records (§8) are stored separately and are never removed by any action here

**Assumptions**
- Users may want to prune old history to keep the app lean or for privacy; since there's no cloud backup in v1, deletion is the only way to reduce stored data.
- Wealth entries are excluded because they describe the user's current standing rather than dated history, so period-based bulk deletion would have no meaning for them; they are removed one at a time in §8.
- Because the current month/year can also be deleted, the type-DELETE confirmation is the app's only safeguard against accidental data loss — there is no "protected" period.
- This is the app's first Settings-style surface; a minimal, single-purpose screen is sufficient here — a fuller Settings section (theme, currency, etc.) is not required by this feature.

---

## 7. App Navigation Drawer

**Goal**
Give the user a side drawer for app-wide actions that don't belong in the primary bottom navigation — Category Management, Data Management, and exiting the app.

**Acceptance Criteria**
- A menu icon in the app's top bar opens a side navigation drawer.
- The drawer contains a "Categories" entry that opens the Category Management screen (§2) as a full-screen pushed route, from which the user returns via back navigation to the tab they came from.
- The drawer contains a "Data Management" entry that opens the Data Management screen (§6).
- The drawer contains an "Exit App" entry that closes the app immediately, with no confirmation prompt.
- Exit is implemented via Flutter's `SystemNavigator.pop()` (not a hard process kill like `dart:io`'s `exit()`), so it behaves like backing out from the root screen rather than surfacing as a crash in Android vitals.
- The drawer closes when an entry is tapped, or when the user taps outside it or swipes it away.

**In-scope**
- The drawer itself, opened via a top-bar menu icon
- Three entries: Categories (§2), Data Management (§6), Exit App

**Out-of-scope**
- Moving the top-bar dark-mode toggle into the drawer — it stays exactly where it is today
- Duplicating the bottom navigation tabs (Dashboard/History/Reports/Wealth) as drawer entries — those four surfaces are reached only from the bottom nav
- User profile, account switching, or app info/about entries
- Any confirmation step before exiting the app

**Assumptions**
- The drawer holds surfaces the user visits occasionally rather than constantly; Category Management moved here when the Wealth tab took its bottom-nav slot (§8), since categories are set up once and rarely revisited.
- More app-wide actions may be added here later as new settings-like features are introduced.
- "Exit App" closes the app process outright rather than just navigating to the Dashboard tab — this is distinct from the OS back button/gesture behavior.

---

## 8. Wealth Tracking

**Goal**
Let the user see what they are actually worth — money on hand, money invested, money owed to them, and money they owe — in one place, so their financial picture isn't limited to the month-to-month flow of income and expense.

**Acceptance Criteria**
- The bottom navigation's four tabs are Dashboard, History, Reports, and Wealth; Wealth occupies the slot Category Management previously held, and Category Management is now reached from the navigation drawer (§2, §7).
- The Wealth screen displays a single Net Worth figure, computed as total assets + total investment current value + total outstanding money lent − total outstanding money borrowed.
- Displays the four contributing subtotals (assets, investment current value, outstanding lent, outstanding borrowed) alongside Net Worth, so the user can see how the figure was reached.
- Net Worth is shown in income green when positive and expense red when negative.
- Net Worth and every subtotal update immediately when a wealth entry is added, edited, deleted, or repaid — no manual refresh required.
- All wealth amounts are entered, stored, and displayed in BDT (৳), using the same formatting as the rest of the app (§1).
- Net Worth appears only within the Wealth area; the Dashboard's Total Balance stays all-time income minus all-time expense and never includes any wealth figure (§3).
- Adding, editing, or deleting a wealth entry never creates, changes, or deletes an income or expense transaction, and wealth entries never appear in History (§4) or Monthly Reports (§5).
- On first launch no assets, investments, or loan entries exist; each of the four sections shows an empty state that explains what it holds and offers an action to add the first entry, and Net Worth reads ৳0.
- Assets: user can add an asset with a name, kind (`cash`, `bank`, `mobile wallet`, `other`), an amount, and an optional note.
- Assets: user can edit or delete any asset, and the list displays each asset's name, kind, and amount plus a total across all assets.
- Assets: an asset amount only ever changes when the user edits it — recording an income or expense transaction does not adjust any asset balance.
- Investments: user can add an investment with a name, type (`stock`, `DPS`, `FDR`, `gold`, `crypto`, `other`), amount invested, invested-on date, and a current value.
- Investments: current value defaults to the amount invested when the investment is created, and the user updates it by hand thereafter; nothing in the app changes it automatically.
- Investments: displays gain/loss per investment as both an absolute figure (current value − amount invested) and a percentage of the amount invested, in green when positive and red when negative, and shows ৳0 / 0% when the two values are equal.
- Investments: displays totals across all investments — total invested, total current value, and total gain/loss in ৳ and %.
- Investments: user can edit or delete an investment; amount invested must be a positive number, and current value must be zero or greater.
- Lending & borrowing: user can add an entry with a direction (`lent` — money owed to the user, or `borrowed` — money the user owes), the person's name, an amount, a date, an optional due date, and an optional note.
- Lending & borrowing: user can log a repayment against an entry with an amount and a date, and can log several repayments against the same entry over time.
- Lending & borrowing: each entry displays its original amount, total repaid so far, and outstanding amount (original minus total repaid).
- Lending & borrowing: a repayment cannot be saved for more than the entry's current outstanding amount.
- Lending & borrowing: an entry is marked settled automatically the moment outstanding reaches zero — there is no manual "mark as settled" step.
- Lending & borrowing: settled entries stay visible, listed separately from active ones, and contribute nothing to Net Worth.
- Lending & borrowing: user can delete a logged repayment, which raises the entry's outstanding amount again and reopens it if it was settled.
- Lending & borrowing: an entry with a due date in the past and an outstanding amount above zero is visibly flagged as overdue in the list.
- Lending & borrowing: user can edit or delete an entry; deleting it removes its repayment history with it.
- Deleting any wealth entry shows a confirmation dialog naming the entry, and deletion is permanent — there is no undo or recovery.
- Wealth entries are stored separately from transactions and are untouched by every action on the Data Management screen, including "Delete all history" (§6).

**In-scope**
- A Wealth tab in the bottom navigation, replacing the Categories tab
- Four manually maintained record types: assets, investments, money lent, money borrowed
- A Net Worth figure derived from those four record types, shown only inside the Wealth area
- Manual current-value updates on investments, with app-computed gain/loss in ৳ and %
- Partial repayment logging against a lending or borrowing entry, with automatic settlement at zero outstanding
- Overdue flagging based on an optional due date
- BDT as the sole currency, matching §1

**Out-of-scope**
- Live price feeds, market data, or any automatic valuation of an investment
- Units × price-per-unit tracking (holding quantities, per-unit prices, average cost basis)
- Interest rates, amortization, or repayment schedules on lent or borrowed money
- Currencies other than BDT (see Multi-currency support in Future Enhancements)
- Linking a wealth entry to a ledger transaction, or auto-creating an income/expense transaction from a wealth entry
- Per-asset transaction history, or automatic deduction from an asset when an expense is recorded
- Inclusion of wealth entries in Data Management's bulk delete (§6)
- Wealth figures inside the Dashboard's Total Balance, History, or Monthly Reports (§3, §4, §5)
- Net worth history, trend charts, or snapshots over time
- Reminders or notifications for upcoming or overdue due dates
- Contacts integration or a shared person/counterparty directory across entries

**Assumptions**
- Wealth is a slow-moving, hand-curated picture of standing, while the transaction ledger is a fast-moving event log; keeping them in separate storage means Total Balance keeps meaning exactly what it has always meant and neither view distorts the other.
- The bottom navigation stays at four tabs rather than growing to five; Wealth is consulted far more often than category maintenance, so Categories is the tab that moved to the drawer (§7).
- Investment valuation is manual because the app is fully offline by design — any live price feed would require network access and break that guarantee.
- Gain/loss percentage is always measured against amount invested, which must be positive, so there is no divide-by-zero case to handle.
- Settled loans are kept rather than deleted so the user retains a record of who repaid what and when; excluding them from Net Worth is enough to keep the figure correct.
- Repayments track principal only, with no interest, because the target case is personal lending between family, friends, and colleagues where the amount owed is the only thing being remembered.
- Money lent is presented in income green and money borrowed in expense red, extending the app's existing color convention (green = money coming to you, red = money going out) to wealth without introducing new semantic colors.
- Deleting a single wealth entry uses a plain confirmation dialog rather than the type-DELETE safeguard from §6, because it destroys one record the user is looking at rather than a whole period of history.
- Nothing is seeded on first launch — unlike categories, there is no sensible default set of someone's own assets, investments, or loans.
- Wealth entries carry no month or period semantics: assets and investments describe current state, and loans are grouped by settled/active rather than by month, so the Wealth area needs no month picker.

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
- **Per-wallet transaction attribution** — assign each income/expense transaction to a specific cash, bank, or card account so those balances move automatically (standalone, hand-maintained account balances are already delivered by Assets in §8).
- **Recurring transactions** — auto-log regular items like rent, subscriptions, or salary.
- **Multi-currency support**
- **Data export** — CSV/PDF export of transactions and reports
- **Cloud backup/sync** — optional backup off-device, without changing the offline-first default
