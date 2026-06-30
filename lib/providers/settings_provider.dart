import 'package:flutter/material.dart';

import '../database/database_helper.dart';

/// Holds user settings (theme, currency) backed by the settings table.
class SettingsProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  bool _darkTheme = true;
  String _currency = '₹';
  bool _loaded = false;

  bool get darkTheme => _darkTheme;
  String get currency => _currency;
  bool get loaded => _loaded;

  ThemeMode get themeMode => _darkTheme ? ThemeMode.dark : ThemeMode.light;

  /// Common currency choices presented in settings.
  static const List<MapEntry<String, String>> currencyOptions = [
    MapEntry('₹', 'Indian Rupee (₹)'),
    MapEntry('\$', 'US Dollar (\$)'),
    MapEntry('€', 'Euro (€)'),
    MapEntry('£', 'British Pound (£)'),
    MapEntry('¥', 'Yen (¥)'),
    MapEntry('AED', 'UAE Dirham (AED)'),
  ];

  Future<void> load() async {
    final settings = await _db.getSettings();
    _darkTheme = (settings['dark_theme'] ?? 'true') == 'true';
    _currency = settings['currency'] ?? '₹';
    _loaded = true;
    notifyListeners();
  }

  Future<void> setDarkTheme(bool value) async {
    _darkTheme = value;
    notifyListeners();
    await _db.setSetting('dark_theme', value.toString());
  }

  Future<void> setCurrency(String value) async {
    _currency = value;
    notifyListeners();
    await _db.setSetting('currency', value);
  }

  /// Reload from DB (used after a database restore).
  Future<void> refresh() => load();
}
