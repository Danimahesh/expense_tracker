import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Compact rounded card for a single total (Cash, UPI, Grand Total).
class SummaryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double amount;
  final IconData icon;
  final Color color;
  final String currency;
  final bool emphasize;

  const SummaryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
    required this.color,
    required this.currency,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        gradient: emphasize
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.accent,
                  Color.lerp(AppTheme.accent, AppTheme.accentAlt, 0.6)!,
                ],
              )
            : null,
        color: emphasize ? null : theme.cardColor,
        boxShadow: emphasize
            ? [
                BoxShadow(
                  color: AppTheme.accent.withOpacity(0.3),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: emphasize
                  ? Colors.white.withOpacity(0.18)
                  : color.withOpacity(0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon,
                color: emphasize ? Colors.white : color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: emphasize ? Colors.white : null,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: emphasize
                        ? Colors.white.withOpacity(0.8)
                        : theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
          Text(
            Formatters.money(amount, symbol: currency),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              letterSpacing: -0.4,
              color: emphasize ? Colors.white : null,
            ),
          ),
        ],
      ),
    );
  }
}
