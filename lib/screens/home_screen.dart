import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../services/billing_engine.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/payment_methods.dart';
import '../widgets/app_card.dart';
import '../widgets/bill_card.dart';
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
    final avgDaily = monthTotal / now.day;
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
                  const SectionTitle('Active Bills'),
                  BillCard(
                    method: PaymentMethods.amazon,
                    period: BillingEngine.currentPeriod(PaymentType.amazon),
                    total: provider.currentBillTotal(PaymentType.amazon),
                    currency: currency,
                  ),
                  const SizedBox(height: 10),
                  BillCard(
                    method: PaymentMethods.bob,
                    period: BillingEngine.currentPeriod(PaymentType.bob),
                    total: provider.currentBillTotal(PaymentType.bob),
                    currency: currency,
                  ),
                  const SizedBox(height: 20),

                  const SectionTitle('This Month'),
                  _MonthCard(
                    total: monthTotal,
                    count: monthExpenses.length,
                    avgDaily: avgDaily,
                    currency: currency,
                  ),
                  const SizedBox(height: 20),

                  SectionTitle(
                    'Recent Transactions',
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
                          child: Text(
                            'No transactions yet.\nTap + to record one.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    )
                  else
                    AppCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 2),
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
}

class _MonthCard extends StatelessWidget {
  final double total;
  final int count;
  final double avgDaily;
  final String currency;

  const _MonthCard({
    required this.total,
    required this.count,
    required this.avgDaily,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total spent',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Formatters.money(total, symbol: currency),
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Transactions',
                  value: '$count',
                ),
              ),
              Container(width: 1, height: 30, color: AppColors.divider),
              Expanded(
                child: _Stat(
                  label: 'Avg / day',
                  value: Formatters.money(avgDaily, symbol: currency),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
