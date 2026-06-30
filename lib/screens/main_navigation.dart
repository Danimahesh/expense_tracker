import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'add_expense_screen.dart';
import 'charts_screen.dart';
import 'home_screen.dart';
import 'records_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

/// Bottom-navigation shell: Records · Charts · (+) · Reports · Settings.
/// The home dashboard is reachable from the Records tab's app bar action and
/// is also the first screen shown.
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;

  // Tabs: 0 Home, 1 Records, 2 Charts, 3 Reports, 4 Settings.
  final List<Widget> _pages = const [
    HomeScreen(),
    RecordsScreen(),
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
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.02),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(_index),
          child: _pages[_index],
        ),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _AddFab(onTap: _openAddExpense),
      bottomNavigationBar: _BottomBar(
        index: _index,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _AddFab extends StatelessWidget {
  final VoidCallback onTap;
  const _AddFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      width: 62,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.accent, AppTheme.accentAlt],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accent.withOpacity(0.45),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _BottomBar({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <_NavItem>[
      const _NavItem(Icons.home_rounded, 'Home', 0),
      const _NavItem(Icons.receipt_long_rounded, 'Records', 1),
      const _NavItem(Icons.pie_chart_rounded, 'Charts', 2),
      const _NavItem(Icons.insights_rounded, 'Reports', 3),
      const _NavItem(Icons.settings_rounded, 'Settings', 4),
    ];

    return BottomAppBar(
      color: theme.cardColor,
      elevation: 12,
      shadowColor: Colors.black,
      shape: const CircularNotchedRectangle(),
      notchMargin: 9,
      height: 72,
      padding: EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTab(context, items[0]), // Home
          _buildTab(context, items[1]), // Records
          const SizedBox(width: 56), // gap for the FAB notch (Add)
          _buildTab(context, items[2]), // Charts
          _buildTab(context, items[3]), // Reports
          _buildTab(context, items[4]), // Settings
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, _NavItem item) {
    final selected = index == item.index;
    final color = selected
        ? AppTheme.accent
        : Theme.of(context).textTheme.bodyMedium?.color;
    return Expanded(
      child: InkWell(
        onTap: () => onChanged(item.index),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: selected ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(item.icon, color: color, size: 24),
              ),
              const SizedBox(height: 3),
              Text(
                item.label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final int index;
  const _NavItem(this.icon, this.label, this.index);
}
