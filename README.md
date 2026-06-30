<div align="center">

# 💸 Expense Tracker

**A premium, offline-first expense tracker for Android — built with Flutter.**

Track spending across cash, UPI, and credit / pay-later accounts with
*real billing-cycle awareness*, rich charts, and one-tap PDF / Excel exports —
all stored locally with zero backend and zero tracking.

[![CI](https://github.com/Danimahesh/expense_tracker/actions/workflows/build.yml/badge.svg)](https://github.com/Danimahesh/expense_tracker/actions/workflows/build.yml)
[![Release](https://img.shields.io/github/v/release/Danimahesh/expense_tracker?include_prereleases&sort=semver)](https://github.com/Danimahesh/expense_tracker/releases)
[![Flutter](https://img.shields.io/badge/Flutter-stable-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/platform-Android-3DDC84?logo=android&logoColor=white)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

</div>

---

## 📖 Overview

**Expense Tracker** is a fully offline personal-finance app that solves a problem
generic budgeting apps ignore: **credit cards and pay-later services don't bill
on calendar months.** Instead of forcing every transaction into a Jan–Feb–Mar
bucket, this app groups spending by each account's *actual* billing cycle, so the
totals you see match the statements you actually pay.

Everything lives in a local SQLite database inside the app's private storage. The
app requests **no permissions** — no internet, no location, no external storage —
making it genuinely private by design.

## ✨ Features

| Area | Details |
|------|---------|
| **Home** | Live bill-cycle cards, monthly cash & UPI totals, and a grand-total snapshot |
| **Add Expense** | Amount, category, payment method, description, date, and notes |
| **Records** | Searchable transaction history with date, category, method, and range filters |
| **Charts** | Donut, line, weekly, and daily visualizations with switchable time ranges |
| **Reports** | Monthly summaries, per-bill breakdowns, top-spend insights, and exports |
| **Settings** | Dark mode, currency selection, backup, restore, and reset |
| **Exports** | One-tap PDF & Excel export and native share-sheet integration |
| **Privacy** | 100% offline, permission-free, no analytics, no accounts |

### 🧮 Billing-cycle intelligence

The core differentiator is a custom **billing engine** that assigns every expense
to the correct period for its payment method:

| Payment Method | Billing Cycle | Due Date |
|----------------|---------------|----------|
| Bank of Baroda Credit Card | 14th → 13th of next month | 30th of closing month |
| Amazon Pay Later | 1st → last day of month | 1st of next month |
| Cash | Calendar month | — |
| UPI | Calendar month | — |

The billing logic is fully unit-tested (see [`test/widget_test.dart`](test/widget_test.dart)).

## 📸 Screenshots

> Screenshots live in [`assets/screenshots/`](assets/screenshots). Drop your own
> device captures there and they will render below.

| Home | Charts | Reports | Add Expense |
|------|--------|---------|-------------|
| ![Home](assets/screenshots/home.png) | ![Charts](assets/screenshots/charts.png) | ![Reports](assets/screenshots/reports.png) | ![Add](assets/screenshots/add.png) |

## 🏗️ Architecture

The app follows a clean, layered structure with `provider` for state management:

```
lib/
├── main.dart              # App entry, theme + provider wiring
├── models/                # Plain domain models (Expense, BillPeriod)
├── database/              # SQLite persistence (sqflite) — the storage layer
├── providers/             # ChangeNotifier state (expenses, settings)
├── services/              # Business logic: BillingEngine, ExportService
├── screens/               # Top-level pages (home, records, charts, reports…)
├── widgets/               # Reusable UI (bill_card, expense_tile, summary_card)
├── theme/                 # Light/dark Material 3 theming
└── utils/                 # Categories, payment methods, formatters
```

**Data flow:** UI screens read from `ExpenseProvider` / `SettingsProvider`
(`ChangeNotifier`s). Providers call the `DatabaseHelper` (sqflite) for
persistence and the `BillingEngine` to bucket expenses into billing periods.
Pure functions in `services/` keep the business logic testable and UI-free.

```
┌────────────┐   reads/writes   ┌──────────────┐   queries   ┌────────────┐
│  Screens   │ ───────────────▶ │  Providers   │ ──────────▶ │  SQLite DB │
│ (widgets)  │ ◀─────────────── │ (ChangeNotif)│ ◀────────── │ (sqflite)  │
└────────────┘   notifyListeners└──────┬───────┘             └────────────┘
                                       │ uses
                                ┌──────▼───────┐
                                │ BillingEngine │  (pure, unit-tested)
                                └──────────────┘
```

## 🧰 Technologies Used

- **[Flutter](https://flutter.dev)** (stable) + **Dart 3**
- **[provider](https://pub.dev/packages/provider)** — state management
- **[sqflite](https://pub.dev/packages/sqflite)** + **path_provider** — offline SQLite storage
- **[fl_chart](https://pub.dev/packages/fl_chart)** — charts & analytics
- **[pdf](https://pub.dev/packages/pdf)** / **[printing](https://pub.dev/packages/printing)** / **[excel](https://pub.dev/packages/excel)** — exports
- **[share_plus](https://pub.dev/packages/share_plus)** — native sharing
- **[intl](https://pub.dev/packages/intl)** — number & date formatting
- **Material 3** theming with light & dark modes
- **GitHub Actions** — CI: analyze, test, build APK, and publish releases
- **Gradle 8.10 / AGP 8.7 / Kotlin 1.9 / Java 17** — modern Android toolchain (V2 embedding)

## 🚀 Installation

### Download the APK

Grab the latest signed APK from the
**[Releases page](https://github.com/Danimahesh/expense_tracker/releases/latest)**
and install it on any Android device (enable *Install from unknown sources*).

### Build from source

**Prerequisites:** [Flutter SDK](https://docs.flutter.dev/get-started/install)
(stable channel) and JDK 17.

```bash
git clone https://github.com/Danimahesh/expense_tracker.git
cd expense_tracker
flutter pub get
flutter run            # run on a connected device / emulator
```

## 🔨 Build Instructions

```bash
# Static analysis
flutter analyze

# Unit tests
flutter test

# Release APK
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

> Every push to GitHub runs the same `analyze → test → build apk` pipeline via
> GitHub Actions, and pushing a `v*` tag publishes a Release with the APK attached.

## 🗺️ Future Roadmap

- [ ] Cloud backup & multi-device sync (opt-in, end-to-end encrypted)
- [ ] Budget goals and overspend alerts
- [ ] Recurring / scheduled expenses
- [ ] Multi-currency support with live FX
- [ ] Home-screen widgets & quick-add shortcuts
- [ ] iOS release build
- [ ] Localization (i18n)
- [ ] Biometric app lock

## 🤝 Contributing

Contributions are welcome! Open an issue to discuss a feature or bug, then submit
a pull request. Please run `flutter analyze` and `flutter test` before pushing.

## 📄 License

Released under the **MIT License** — see [LICENSE](LICENSE) for details.

---

<div align="center">
Built with ❤️ and Flutter · © 2026 Danimahesh
</div>
