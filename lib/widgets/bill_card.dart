import 'package:flutter/material.dart';

import '../models/bill_period.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/payment_methods.dart';
import 'app_card.dart';

/// Compact billing-cycle card: current bill, due date, days remaining and a
/// thin billing-progress bar. Deliberately low-profile (about 40% shorter than
/// a full summary card).
class BillCard extends StatelessWidget {
  final PaymentMethodDef method;
  final BillPeriod period;
  final double total;
  final String currency;

  const BillCard({
    super.key,
    required this.method,
    required this.period,
    required this.total,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final daysLeft = period.daysRemaining();
    final overdue = daysLeft != null && daysLeft < 0;
    final progress = _progress();

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.credit_card_rounded,
                    color: AppColors.cyan, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  method.shortLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (period.dueDate != null)
                Flexible(
                  child: Text(
                    'Due ${Formatters.dayMonth(period.dueDate!)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current bill',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        Formatters.money(total, symbol: currency),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (daysLeft != null)
                Flexible(
                  child: Text(
                    overdue
                        ? '${daysLeft.abs()}d overdue'
                        : '$daysLeft days left',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          overdue ? AppColors.danger : AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: AppColors.surface2,
              valueColor: AlwaysStoppedAnimation(
                overdue ? AppColors.danger : AppColors.cyan,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _progress() {
    final now = DateTime.now();
    final start = period.start.millisecondsSinceEpoch;
    final end = period.end.millisecondsSinceEpoch;
    if (end <= start) return 0;
    final frac = (now.millisecondsSinceEpoch - start) / (end - start);
    return frac.clamp(0.0, 1.0);
  }
}
