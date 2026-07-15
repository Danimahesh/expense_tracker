import 'package:flutter/material.dart';

import 'add_expense_screen.dart';
import 'charts_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

/// App shell: Home · History · Charts · Reports · Settings.
///
/// Uses an [IndexedStack] so each tab keeps its scroll/search state and there
/// are no page-transition animations. The Add-Expense FAB appears on the Home
/// and History tabs.
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;

  static const _pages = [
    HomeScreen(),
    HistoryScreen(),
    ChartsScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  void _openAddExpense() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showFab = _index == 0 || _index == 1;

    return AppNavigator(
      goToTab: (i) => setState(() => _index = i),
      child: Scaffold(
        body: IndexedStack(index: _index, children: _pages),
        floatingActionButton: showFab
            ? FloatingActionButton(
                onPressed: _openAddExpense,
                tooltip: 'Add expense',
                child: const Icon(Icons.add_rounded),
              )
            : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'History',
            ),
            NavigationDestination(
              icon: Icon(Icons.pie_chart_outline_rounded),
              selectedIcon: Icon(Icons.pie_chart_rounded),
              label: 'Charts',
            ),
            NavigationDestination(
              icon: Icon(Icons.assessment_outlined),
              selectedIcon: Icon(Icons.assessment_rounded),
              label: 'Reports',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

/// Lets descendant screens (e.g. Home's "See all") switch the active tab
/// without pushing a duplicate screen.
class AppNavigator extends InheritedWidget {
  final ValueChanged<int> goToTab;

  const AppNavigator({
    super.key,
    required this.goToTab,
    required super.child,
  });

  static AppNavigator of(BuildContext context) {
    final nav =
        context.dependOnInheritedWidgetOfExactType<AppNavigator>();
    assert(nav != null, 'AppNavigator not found in context');
    return nav!;
  }

  @override
  bool updateShouldNotify(AppNavigator oldWidget) => false;
}
