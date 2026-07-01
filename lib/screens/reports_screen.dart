import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../services/export_service.dart';
import '../utils/categories.dart';
import '../utils/formatters.dart';
import '../utils/payment_methods.dart';
import '../widgets/app_card.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
          children: [
            // Total spent
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total spent · ${Formatters.monthYear(now)}',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      Formatters.money(monthTotal, symbol: currency),
                      style: const TextStyle(
                          fontSize: 34, fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text('${monthExpenses.length} transactions',
                      style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(height: 22),

            const SectionTitle('Category breakdown'),
            AppCard(
              child: _Breakdown(
                rows: _categoryRows(monthExpenses),
                total: monthTotal,
                currency: currency,
              ),
            ),
            const SizedBox(height: 22),

            const SectionTitle('Payment method breakdown'),
            AppCard(
              child: _Breakdown(
                rows: _methodRows(monthExpenses),
                total: monthTotal,
                currency: currency,
              ),
            ),
            const SizedBox(height: 22),

            const SectionTitle('Export'),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _export(
                      context,
                      () => ExportService.exportPdf(provider.all,
                          currency: currency),
                    ),
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    label: const Text('PDF'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _export(
                      context,
                      () => ExportService.exportExcel(provider.all,
                          currency: currency),
                    ),
                    icon: const Icon(Icons.table_chart_rounded),
                    label: const Text('Excel'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<_BreakdownRow> _categoryRows(List<Expense> list) {
    final map = <String, double>{};
    for (final e in list) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    final rows = <_BreakdownRow>[];
    for (final entry in map.entries) {
      final cat = Categories.byKey(entry.key);
      rows.add(_BreakdownRow(cat.label, cat.icon, cat.color, entry.value));
    }
    rows.sort((a, b) => b.amount.compareTo(a.amount));
    return rows;
  }

  List<_BreakdownRow> _methodRows(List<Expense> list) {
    final rows = <_BreakdownRow>[];
    for (final m in PaymentMethods.all) {
      final sum = list
          .where((e) => e.paymentMethod == m.key)
          .fold<double>(0, (s, e) => s + e.amount);
      if (sum > 0) {
        rows.add(_BreakdownRow(m.shortLabel, m.icon, m.color, sum));
      }
    }
    rows.sort((a, b) => b.amount.compareTo(a.amount));
    return rows;
  }

  Future<void> _export(
      BuildContext context, Future<void> Function() task) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await task();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }
}

class _BreakdownRow {
  final String label;
  final IconData icon;
  final Color color;
  final double amount;
  const _BreakdownRow(this.label, this.icon, this.color, this.amount);
}

class _Breakdown extends StatelessWidget {
  final List<_BreakdownRow> rows;
  final double total;
  final String currency;

  const _Breakdown({
    required this.rows,
    required this.total,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: Text('No expenses this month',
              style: TextStyle(color: scheme.onSurfaceVariant)),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          Column(
            children: [
              Row(
                children: [
                  Icon(rows[i].icon, size: 18, color: rows[i].color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      rows[i].label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    Formatters.money(rows[i].amount, symbol: currency),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : rows[i].amount / total,
                  minHeight: 6,
                  backgroundColor: scheme.surfaceContainerHighest,
                  color: rows[i].color,
                ),
              ),
            ],
          ),
          if (i != rows.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }
}
