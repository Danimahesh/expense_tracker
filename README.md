<div align="center">

# 💸 Expense Tracker

**A premium offline Flutter expense tracking application with smart
billing-cycle support for credit cards and Amazon Pay Later.**

[![CI](https://github.com/Danimahesh/expense_tracker/actions/workflows/build.yml/badge.svg)](https://github.com/Danimahesh/expense_tracker/actions/workflows/build.yml)
[![Release](https://img.shields.io/github/v/release/Danimahesh/expense_tracker?include_prereleases&sort=semver)](https://github.com/Danimahesh/expense_tracker/releases)
[![Flutter](https://img.shields.io/badge/Flutter-stable-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/platform-Android-3DDC84?logo=android&logoColor=white)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

</div>

---

## 📖 Overview

**Expense Tracker** is a fully offline personal-finance app that solves a problem
generic budgeting apps ignore: **credit cards and pay-later services don't bill on
calendar months.** Its custom billing engine groups every transaction by each
account's *actual* billing cycle, so the totals you see match the statements you
actually pay. All data lives in a local SQLite database — no backend, no accounts,
no tracking.

## ✨ Features

- 📴 **Offline SQLite database** — all data stored locally, zero network access
- 🎨 **Material 3 UI** — clean, modern, responsive design
- 🌙 **Dark Mode** — full light/dark theming
- 📊 **Charts & Reports** — donut, line, weekly, and daily spend visualizations
- 📄 **PDF Export** — share formatted expense reports
- 📑 **Excel Export** — export raw data to `.xlsx`
- 🔁 **Billing Cycle Engine** — credit-card and pay-later cycles, not calendar months
- 💳 **Multiple Payment Methods** — BOB Credit Card, Amazon Pay Later, Cash, UPI
- 💾 **Backup & Restore** — back up and recover the local database

### 🧮 Billing-cycle logic

| Payment Method | Billing Cycle | Due Date |
|----------------|---------------|----------|
| Bank of Baroda Credit Card | 14th → 13th of next month | 30th of closing month |
| Amazon Pay Later | 1st → last day of month | 1st of next month |
| Cash | Calendar month | — |
| UPI | Calendar month | — |

The billing logic is fully unit-tested in [`test/widget_test.dart`](test/widget_test.dart).

## 📸 Screenshots

> Screenshots live in [`assets/screenshots/`](assets/screenshots) — drop your own
> device captures there and they render below.

| Home | Reports | Charts |
|------|---------|--------|
| ![Home](assets/screenshots/home.png) | ![Reports](assets/screenshots/reports.png) | ![Charts](assets/screenshots/charts.png) |

## 🏗️ Architecture

`provider`-based state management over a clean, layered structure:

```
lib/
├── main.dart        # App entry, theme + provider wiring
├── models/          # Domain models (Expense, BillPeriod)
├── database/        # SQLite persistence (sqflite)
├── providers/       # ChangeNotifier state (expenses, settings)
├── services/        # Business logic: BillingEngine, ExportService
├── screens/         # Pages (home, records, charts, reports, settings)
├── widgets/         # Reusable UI components
├── theme/           # Material 3 light/dark theming
└── utils/           # Categories, payment methods, formatters
```

UI screens read from providers; providers persist through `DatabaseHelper`
(sqflite) and bucket expenses via the pure, unit-tested `BillingEngine`.

## 🧰 Tech Stack

- **Flutter** (stable) + **Dart 3**
- **SQLite** via [`sqflite`](https://pub.dev/packages/sqflite)
- **Provider** for state management
- [`fl_chart`](https://pub.dev/packages/fl_chart) for charts & analytics
- [`pdf`](https://pub.dev/packages/pdf) + [`printing`](https://pub.dev/packages/printing) for PDF export
- [`excel`](https://pub.dev/packages/excel) for Excel export
- [`share_plus`](https://pub.dev/packages/share_plus) for native sharing
- **GitHub Actions** CI — analyze, test, build APK, publish releases
- **Gradle 8.10 / AGP 8.7 / Kotlin 1.9 / Java 17** (Android V2 embedding)

## ⬇️ Download

Download the latest signed APK from the
**[Releases page](https://github.com/Danimahesh/expense_tracker/releases/latest)**
and install it on any Android device (enable *Install from unknown sources*).

## 🚀 Run Locally

**Prerequisites:** [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable) and JDK 17.

```bash
git clone https://github.com/Danimahesh/expense_tracker.git
cd expense_tracker
flutter pub get
flutter run
```

## 🔨 Build

```bash
flutter analyze        # static analysis
flutter test           # unit tests
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

> Every push runs the same `analyze → test → build apk` pipeline on GitHub Actions,
> and pushing a `v*` tag publishes a Release with the APK attached.

## 🗺️ Roadmap

- [ ] Cloud backup & multi-device sync (opt-in, encrypted)
- [ ] Budget goals and overspend alerts
- [ ] Recurring / scheduled expenses
- [ ] Home-screen widgets & quick-add shortcuts
- [ ] iOS release build
- [ ] Localization (i18n)

## 📄 License

Released under the **MIT License** — see [LICENSE](LICENSE).

---

<div align="center">
Built with ❤️ and Flutter · © 2026 Danimahesh
</div>
