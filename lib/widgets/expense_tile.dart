import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../utils/categories.dart';
import '../utils/formatters.dart';
import '../utils/payment_methods.dart';

/// A compact transaction row: category icon, title, payment method, date,
/// and amount. Used by both the history list and the home "recent" section.
class ExpenseTile extends StatelessWidget {
  final Expense expense;
  final String currency;
  final VoidCallback? onTap;

  const ExpenseTile({
    super.key,
    required this.expense,
    required this.currency,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cat = Categories.byKey(expense.category);
    final method = PaymentMethods.byKey(expense.paymentMethod);
    final scheme = Theme.of(context).colorScheme;
    final title =
        expense.description.isEmpty ? cat.label : expense.description;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cat.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(cat.icon, color: cat.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${method.shortLabel} · ${Formatters.historyHeader(expense.date)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              Formatters.money(expense.amount, symbol: currency),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
