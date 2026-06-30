# Expense Tracker

An offline-first Flutter expense tracker for Android with local SQLite storage,
bill-cycle-aware summaries, charts, exports, and zero backend dependencies.

## Portfolio Highlights

- Built with Flutter and Provider for a responsive multi-screen app flow.
- Stores all user data locally with SQLite for full offline use.
- Uses a custom billing engine so card and pay-later expenses are grouped by
  real billing cycles instead of calendar months.
- Includes reporting, charts, backup/restore, and PDF/Excel export support.
- Ships with the full Android project and Gradle wrapper so GitHub Actions can
  build the APK without running `flutter create`.

## Features

| Area | Details |
|------|---------|
| Home | Current bill cards, monthly cash and UPI totals, and grand total snapshot |
| Add Expense | Amount, category, payment method, description, date, and notes |
| Records | Searchable transaction history with date, category, method, and range filters |
| Charts | Donut, line, weekly, and daily visualizations with time-range switching |
| Reports | Monthly summaries, bill breakdowns, top spend insights, and exports |
| Settings | Dark mode, currency, backup, restore, and reset data |

## Billing Logic

| Payment Method | Billing Cycle | Due Date |
|----------------|---------------|----------|
| Bank of Baroda Credit Card | 14th to 13th of next month | 30th of closing month |
| Amazon Pay Later | 1st to last day of month | 1st of next month |
| Cash | Calendar month tracking | N/A |
| UPI | Calendar month tracking | N/A |

The widget tests cover the billing-period calculations used for these grouped
summaries.

## Tech Stack

- Flutter
- Dart
- Provider
- SQLite via `sqflite`
- `fl_chart` for analytics views
- `pdf`, `printing`, and `excel` for export workflows
- GitHub Actions for APK build automation

## Run Locally

```bash
flutter pub get
flutter run
```

## Build Release APK

```bash
flutter build apk --release
```

Output:
`build/app/outputs/flutter-apk/app-release.apk`

## Project Structure

```text
lib/
  database/
  models/
  providers/
  screens/
  services/
  theme/
  utils/
  widgets/
android/
.github/workflows/build.yml
test/
```

## CI/CD

The repository includes a GitHub Actions workflow at
`.github/workflows/build.yml` that installs Flutter, builds the release APK,
and uploads it as an artifact on push or pull request.
