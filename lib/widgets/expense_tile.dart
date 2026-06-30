import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../utils/categories.dart';
import '../utils/formatters.dart';
import '../utils/payment_methods.dart';

/// A single transaction row used in the records list.
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
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: cat.color.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(cat.icon, color: cat.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.description.isEmpty
                          ? cat.label
                          : expense.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(method.icon,
                            size: 13,
                            color: theme.textTheme.bodyMedium?.color),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            '${method.shortLabel} • ${cat.label}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '- ${Formatters.money(expense.amount, symbol: currency)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
