import 'package:flutter/material.dart';

import '../models/bill_period.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/payment_methods.dart';

/// Premium gradient card showing a billing-cycle summary (BOB / Amazon).
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

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            method.color.withOpacity(0.95),
            Color.lerp(method.color, Colors.black, 0.45)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: method.color.withOpacity(0.30),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(method.icon, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            method.shortLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Current Bill',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _periodChip(),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  'Current Bill Total',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.money(total, symbol: currency),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 30,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _footerItem(
                        'Due Date',
                        period.dueDate != null
                            ? Formatters.dayMonth(period.dueDate!)
                            : '—',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 34,
                      color: Colors.white.withOpacity(0.18),
                    ),
                    Expanded(
                      child: _footerItem(
                        'Days Remaining',
                        daysLeft == null
                            ? '—'
                            : overdue
                                ? '${daysLeft.abs()}d overdue'
                                : '$daysLeft days',
                        highlight: overdue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _periodChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            Formatters.dayMonth(period.start),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const Icon(Icons.arrow_downward_rounded,
              color: Colors.white70, size: 12),
          Text(
            Formatters.dayMonth(period.end),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerItem(String label, String value, {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.70),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: highlight ? const Color(0xFFFFE082) : Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
