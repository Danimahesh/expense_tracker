import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/expense_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/main_navigation.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider()..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => ExpenseProvider()..load(),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          SystemChrome.setSystemUIOverlayStyle(
              AppTheme.overlay(settings.darkTheme));
          return MaterialApp(
            title: 'Expense Tracker',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: settings.themeMode,
            home: const MainNavigation(),
          );
        },
      ),
    );
  }
}
