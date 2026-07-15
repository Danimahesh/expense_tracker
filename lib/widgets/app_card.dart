import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A dark surface card with a thin cyan outline and a very subtle glow.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? glow;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.glow,
  });

  @override
  Widget build(BuildContext context) {
    final accent = glow ?? AppColors.cyan;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.05),
            blurRadius: 16,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// A terminal-style Orbitron section label (e.g. "THIS MONTH").
class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.heading(
                size: 12.5,
                weight: FontWeight.w600,
                color: AppColors.textSecondary,
                spacing: 1.8,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
