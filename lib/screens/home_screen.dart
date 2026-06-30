import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../services/billing_engine.dart';
import '../utils/formatters.dart';
import '../utils/payment_methods.dart';
import '../widgets/bill_card.dart';
import '../widgets/summary_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpenseProvider>();
    final settings = context.watch<SettingsProvider>();
    final currency = settings.currency;

    final bobPeriod = BillingEngine.currentPeriod(PaymentType.bob);
    final amazonPeriod = BillingEngine.currentPeriod(PaymentType.amazon);

    final bobTotal = expenses.currentBillTotal(PaymentType.bob);
    final amazonTotal = expenses.currentBillTotal(PaymentType.amazon);
    final cashTotal = expenses.currentMonthTotal(PaymentType.cash);
    final upiTotal = expenses.currentMonthTotal(PaymentType.upi);
    final currentGrand = expenses.currentGrandTotal();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => context.read<ExpenseProvider>().load(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 120),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good ${_greeting()},',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const Text(
                          'Your Money',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              SummaryCard(
                title: 'Grand Total',
                subtitle: 'Current cycle across all methods',
                amount: currentGrand,
                icon: Icons.account_balance_rounded,
                color: Colors.white,
                currency: currency,
                emphasize: true,
              ),
              const SizedBox(height: 18),

              _sectionLabel(context, 'Credit & Pay Later Bills'),
              const SizedBox(height: 12),
              BillCard(
                method: PaymentMethods.bob,
                period: bobPeriod,
                total: bobTotal,
                currency: currency,
              ),
              const SizedBox(height: 14),
              BillCard(
                method: PaymentMethods.amazon,
                period: amazonPeriod,
                total: amazonTotal,
                currency: currency,
              ),
              const SizedBox(height: 18),

              _sectionLabel(context, 'This Month'),
              const SizedBox(height: 12),
              SummaryCard(
                title: 'Cash',
                subtitle: Formatters.monthYear(DateTime.now()),
                amount: cashTotal,
                icon: PaymentMethods.cash.icon,
                color: PaymentMethods.cash.color,
                currency: currency,
              ),
              const SizedBox(height: 12),
              SummaryCard(
                title: 'UPI',
                subtitle: Formatters.monthYear(DateTime.now()),
                amount: upiTotal,
                icon: PaymentMethods.upi.icon,
                color: PaymentMethods.upi.color,
                currency: currency,
              ),
              const SizedBox(height: 18),

              _sectionLabel(context, 'Overall'),
              const SizedBox(height: 12),
              SummaryCard(
                title: 'All-Time Total',
                subtitle: '${expenses.all.length} transactions recorded',
                amount: expenses.grandTotal,
                icon: Icons.summarize_rounded,
                color: Theme.of(context).colorScheme.secondary,
                currency: currency,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }
}
