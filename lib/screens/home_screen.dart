import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/formatters.dart';
import '../utils/payment_methods.dart';
import '../widgets/app_card.dart';
import '../widgets/expense_details_sheet.dart';
import '../widgets/expense_tile.dart';
import 'main_navigation.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final currency = context.watch<SettingsProvider>().currency;
    final now = DateTime.now();

    final monthExpenses = provider.all
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .toList();
    final monthTotal = monthExpenses.fold<double>(0, (s, e) => s + e.amount);
    final todayTotal = monthExpenses
        .where((e) => e.date.day == now.day)
        .fold<double>(0, (s, e) => s + e.amount);

    final byMethod = _byMethod(monthExpenses);
    final recent = provider.all.take(5).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: SafeArea(
        top: false,
        child: provider.loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                children: [
                  _SummaryCard(
                    monthLabel: Formatters.monthYear(now),
                    total: monthTotal,
                    todayTotal: todayTotal,
                    count: monthExpenses.length,
                    currency: currency,
                  ),
                  const SizedBox(height: 22),

                  const SectionTitle('Spending by payment method'),
                  _MethodBreakdown(
                    data: byMethod,
                    total: monthTotal,
                    currency: currency,
                  ),
                  const SizedBox(height: 22),

                  SectionTitle(
                    'Recent transactions',
                    trailing: recent.isEmpty
                        ? null
                        : TextButton(
                            onPressed: () =>
                                AppNavigator.of(context).goToTab(1),
                            child: const Text('See all'),
                          ),
                  ),
                  if (recent.isEmpty)
                    const AppCard(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text('No transactions yet.\nTap “Add” to record one.',
                              textAlign: TextAlign.center),
                        ),
                      ),
                    )
                  else
                    AppCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: Column(
                        children: [
                          for (var i = 0; i < recent.length; i++) ...[
                            ExpenseTile(
                              expense: recent[i],
                              currency: currency,
                              onTap: () => showExpenseDetails(
                                  context, recent[i], currency),
                            ),
                            if (i != recent.length - 1)
                              const Divider(height: 1),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  List<_MethodTotal> _byMethod(List<Expense> list) {
    final totals = <_MethodTotal>[];
    for (final m in PaymentMethods.all) {
      final sum = list
          .where((e) => e.paymentMethod == m.key)
          .fold<double>(0, (s, e) => s + e.amount);
      if (sum > 0) totals.add(_MethodTotal(m, sum));
    }
    totals.sort((a, b) => b.amount.compareTo(a.amount));
    return totals;
  }
}

class _MethodTotal {
  final PaymentMethodDef method;
  final double amount;
  const _MethodTotal(this.method, this.amount);
}

class _SummaryCard extends StatelessWidget {
  final String monthLabel;
  final double total;
  final double todayTotal;
  final int count;
  final String currency;

  const _SummaryCard({
    required this.monthLabel,
    required this.total,
    required this.todayTotal,
    required this.count,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spent in $monthLabel',
            style: TextStyle(
              color: scheme.onPrimary.withValues(alpha: 0.85),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Formatters.money(total, symbol: currency),
              style: TextStyle(
                color: scheme.onPrimary,
                fontSize: 38,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Transactions',
                  value: '$count',
                  onColor: scheme.onPrimary,
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: scheme.onPrimary.withValues(alpha: 0.25),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Today',
                  value: Formatters.money(todayTotal, symbol: currency),
                  onColor: scheme.onPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color onColor;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.onColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              color: onColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: onColor.withValues(alpha: 0.85),
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }
}

class _MethodBreakdown extends StatelessWidget {
  final List<_MethodTotal> data;
  final double total;
  final String currency;

  const _MethodBreakdown({
    required this.data,
    required this.total,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (data.isEmpty) {
      return const AppCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: Center(child: Text('No spending this month yet.')),
        ),
      );
    }

    return AppCard(
      child: Column(
        children: [
          for (var i = 0; i < data.length; i++) ...[
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: data[i].method.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(data[i].method.icon,
                      color: data[i].method.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data[i].method.shortLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: total == 0 ? 0 : data[i].amount / total,
                          minHeight: 6,
                          backgroundColor:
                              scheme.surfaceContainerHighest,
                          color: data[i].method.color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  Formatters.money(data[i].amount, symbol: currency),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            if (i != data.length - 1) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
