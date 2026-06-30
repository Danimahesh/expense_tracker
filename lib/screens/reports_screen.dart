import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../services/billing_engine.dart';
import '../services/export_service.dart';
import '../utils/categories.dart';
import '../utils/formatters.dart';
import '../utils/payment_methods.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final currency = context.watch<SettingsProvider>().currency;
    final now = DateTime.now();

    final monthExpenses = provider.all
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .toList();
    final monthTotal = monthExpenses.fold<double>(0, (s, e) => s + e.amount);

    final bobTotal = provider.currentBillTotal(PaymentType.bob);
    final amazonTotal = provider.currentBillTotal(PaymentType.amazon);
    final bobPeriod = BillingEngine.currentPeriod(PaymentType.bob);
    final amazonPeriod = BillingEngine.currentPeriod(PaymentType.amazon);

    final categoryTotals = _categoryTotals(monthExpenses);
    final highest = _highestExpense(monthExpenses);
    final avgDaily = monthTotal / now.day;
    final largestCategory =
        categoryTotals.isEmpty ? null : categoryTotals.first;
    final mostUsedMethod = _mostUsedMethod(monthExpenses);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 130),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Reports',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _showExportSheet(context, provider),
                  icon: const Icon(Icons.ios_share_rounded),
                  tooltip: 'Export',
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Monthly summary header card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF7C5CFC), Color(0xFF00E0B8)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Formatters.monthYear(now),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    Formatters.money(monthTotal, symbol: currency),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Spent this month',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stat grid
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Avg. Daily Spend',
                    value: Formatters.money(avgDaily, symbol: currency),
                    icon: Icons.today_rounded,
                    color: const Color(0xFF42A5F5),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    label: 'Total Transactions',
                    value: '${monthExpenses.length}',
                    icon: Icons.receipt_rounded,
                    color: const Color(0xFF66BB6A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Largest Category',
                    value: largestCategory?.label ?? '—',
                    sub: largestCategory == null
                        ? null
                        : Formatters.money(largestCategory.total,
                            symbol: currency),
                    icon: largestCategory == null
                        ? Icons.category_rounded
                        : Categories.byKey(largestCategory.key).icon,
                    color: const Color(0xFFEC407A),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    label: 'Most Used Method',
                    value: mostUsedMethod?.shortLabel ?? '—',
                    icon: mostUsedMethod?.icon ?? Icons.payment_rounded,
                    color: const Color(0xFFFFA726),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Highest expense
            _Section(
              title: 'Highest Expense',
              child: highest == null
                  ? _emptyRow(context, 'No expenses this month')
                  : Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Categories.byKey(highest.category)
                              .color
                              .withOpacity(0.2),
                          child: Icon(
                            Categories.byKey(highest.category).icon,
                            color: Categories.byKey(highest.category).color,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                highest.description.isEmpty
                                    ? Categories.byKey(highest.category).label
                                    : highest.description,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                              Text(
                                Formatters.dayMonthYear(highest.date),
                                style:
                                    Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          Formatters.money(highest.amount, symbol: currency),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),

            // Current bills
            _Section(
              title: 'Current Bills',
              child: Column(
                children: [
                  _billRow(
                    context,
                    PaymentMethods.bob.shortLabel,
                    '${Formatters.dayMonth(bobPeriod.start)} - ${Formatters.dayMonth(bobPeriod.end)}',
                    bobTotal,
                    currency,
                    PaymentMethods.bob.color,
                    due: bobPeriod.dueDate,
                  ),
                  const Divider(height: 22),
                  _billRow(
                    context,
                    PaymentMethods.amazon.shortLabel,
                    '${Formatters.dayMonth(amazonPeriod.start)} - ${Formatters.dayMonth(amazonPeriod.end)}',
                    amazonTotal,
                    currency,
                    PaymentMethods.amazon.color,
                    due: amazonPeriod.dueDate,
                  ),
                  const Divider(height: 22),
                  _billRow(
                    context,
                    PaymentMethods.cash.shortLabel,
                    Formatters.monthYear(now),
                    provider.currentMonthTotal(PaymentType.cash),
                    currency,
                    PaymentMethods.cash.color,
                  ),
                  const Divider(height: 22),
                  _billRow(
                    context,
                    PaymentMethods.upi.shortLabel,
                    Formatters.monthYear(now),
                    provider.currentMonthTotal(PaymentType.upi),
                    currency,
                    PaymentMethods.upi.color,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Category totals
            _Section(
              title: 'Category Totals',
              child: categoryTotals.isEmpty
                  ? _emptyRow(context, 'No expenses this month')
                  : Column(
                      children: categoryTotals.map((c) {
                        final cat = Categories.byKey(c.key);
                        final pct =
                            monthTotal == 0 ? 0.0 : c.total / monthTotal;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(cat.icon, size: 18, color: cat.color),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(cat.label,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                  ),
                                  Text(
                                    Formatters.money(c.total,
                                        symbol: currency),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 6,
                                  backgroundColor: Theme.of(context)
                                      .dividerColor
                                      .withOpacity(0.3),
                                  color: cat.color,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // --- helpers --------------------------------------------------------------

  List<_CategoryTotal> _categoryTotals(List<Expense> list) {
    final map = <String, double>{};
    for (final e in list) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    final totals = map.entries
        .map((e) => _CategoryTotal(e.key, Categories.byKey(e.key).label, e.value))
        .toList();
    totals.sort((a, b) => b.total.compareTo(a.total));
    return totals;
  }

  Expense? _highestExpense(List<Expense> list) {
    if (list.isEmpty) return null;
    return list.reduce((a, b) => a.amount >= b.amount ? a : b);
  }

  PaymentMethodDef? _mostUsedMethod(List<Expense> list) {
    if (list.isEmpty) return null;
    final counts = <String, int>{};
    for (final e in list) {
      counts[e.paymentMethod] = (counts[e.paymentMethod] ?? 0) + 1;
    }
    final top = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return PaymentMethods.byKey(top.key);
  }

  Widget _billRow(
    BuildContext context,
    String name,
    String period,
    double amount,
    String currency,
    Color color, {
    DateTime? due,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                due != null
                    ? '$period • Due ${Formatters.dayMonth(due)}'
                    : period,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        Text(
          Formatters.money(amount, symbol: currency),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _emptyRow(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }

  void _showExportSheet(BuildContext context, ExpenseProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        final currency = sheetContext.read<SettingsProvider>().currency;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Export Data',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Export all ${provider.all.length} transactions.',
                    style: Theme.of(sheetContext).textTheme.bodyMedium),
                const SizedBox(height: 18),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEF5350),
                    child: Icon(Icons.picture_as_pdf_rounded,
                        color: Colors.white),
                  ),
                  title: const Text('Export to PDF'),
                  subtitle: const Text('Formatted report document'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _runExport(
                      context,
                      () => ExportService.exportPdf(provider.all,
                          currency: currency),
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF66BB6A),
                    child: Icon(Icons.table_chart_rounded,
                        color: Colors.white),
                  ),
                  title: const Text('Export to Excel'),
                  subtitle: const Text('Spreadsheet (.xlsx)'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _runExport(
                      context,
                      () => ExportService.exportExcel(provider.all,
                          currency: currency),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _runExport(
      BuildContext context, Future<void> Function() task) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await task();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }
}

class _CategoryTotal {
  final String key;
  final String label;
  final double total;
  const _CategoryTotal(this.key, this.label, this.total);
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (sub != null)
            Text(sub!, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
