# Expense Tracker

A fully offline personal finance app for Android, built with Flutter. All data is stored locally on-device (Hive) — no backend, no account, no sync.

## Features

- **Transactions** — record income and expenses with amount, category, date, and an optional note; edit or delete anytime. All amounts are in BDT (৳).
- **Categories** — a default set of common income/expense categories out of the box, plus custom categories you can add, edit, or delete.
- **Dashboard** — at-a-glance overall balance, this month's income/expense totals, and recent transactions.
- **History** — full transaction history, browsable and filterable.
- **Reports** — monthly income/expense breakdowns and trends via hand-drawn charts (donut + grouped bar).
- **Wealth Tracking** — track assets, investments, and loans (with repayments) alongside day-to-day spending.
- **Data Management** — manage the app's local data from a dedicated screen off the navigation drawer.

See [docs/specs.md](docs/specs.md) for the full product spec and [docs/implementation-summary.md](docs/implementation-summary.md) for architectural notes.

## Commands

Run all commands from this directory (`src/`).

- Install deps: `flutter pub get`
- Run the app on a connected device/emulator: `flutter run`
- Static analysis (should stay clean): `flutter analyze`
- Run the full test suite: `flutter test`
- Run a single test file: `flutter test test/providers_test.dart`
- Regenerate Hive adapters after changing a model in `lib/data/models/`: `dart run build_runner build --delete-conflicting-outputs`
- Launch the reference emulator if none is running: `flutter emulators --launch Pixel_6_API_35`

## Building a release APK

```bash
flutter build apk --release
```

The APK name is set in [`android/app/build.gradle.kts`](android/app/build.gradle.kts) as `ExpenseTracker-v<version>-<buildType>.apk`, where `<version>` comes from the `version:` field in `pubspec.yaml`.

- Renamed output (use this one): `build/app/outputs/apk/release/ExpenseTracker-v<version>-release.apk`
- Flutter also copies the same APK to a fixed filename (Flutter Gradle plugin behavior, not affected by the rename): `build/app/outputs/flutter-apk/app-release.apk`

To bump the version before a release, edit `version: x.y.z+n` in `pubspec.yaml`.
