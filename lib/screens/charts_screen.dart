import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/categories.dart';
import '../utils/formatters.dart';
import '../utils/payment_methods.dart';
import '../widgets/app_card.dart';

class ChartsScreen extends StatelessWidget {
  const ChartsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final currency = context.watch<SettingsProvider>().currency;
    final now = DateTime.now();

    final monthExpenses = provider.all
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Charts')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
          children: [
            SectionTitle('${Formatters.monthYear(now)} by category'),
            AppCard(
              child: _PieBreakdown(
                slices: _byCategory(monthExpenses),
                currency: currency,
              ),
            ),
            const SizedBox(height: 22),

            SectionTitle('${Formatters.monthYear(now)} by payment method'),
            AppCard(
              child: _PieBreakdown(
                slices: _byMethod(monthExpenses),
                currency: currency,
              ),
            ),
            const SizedBox(height: 22),

            const SectionTitle('Monthly trend'),
            AppCard(
              child: _TrendLine(
                points: _monthlyTotals(provider.all, 6),
                currency: currency,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_Slice> _byCategory(List<Expense> list) {
    final map = <String, double>{};
    for (final e in list) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    final slices = <_Slice>[];
    for (final c in Categories.all) {
      final v = map[c.key] ?? 0;
      if (v > 0) slices.add(_Slice(c.label, v, c.color));
    }
    slices.sort((a, b) => b.value.compareTo(a.value));
    return slices;
  }

  List<_Slice> _byMethod(List<Expense> list) {
    final map = <String, double>{};
    for (final e in list) {
      map[e.paymentMethod] = (map[e.paymentMethod] ?? 0) + e.amount;
    }
    final slices = <_Slice>[];
    for (final m in PaymentMethods.all) {
      final v = map[m.key] ?? 0;
      if (v > 0) slices.add(_Slice(m.shortLabel, v, m.color));
    }
    slices.sort((a, b) => b.value.compareTo(a.value));
    return slices;
  }

  List<_Point> _monthlyTotals(List<Expense> list, int months) {
    final now = DateTime.now();
    final result = <_Point>[];
    for (var i = months - 1; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final total = list
          .where((e) =>
              e.date.year == month.year && e.date.month == month.month)
          .fold<double>(0, (s, e) => s + e.amount);
      result.add(_Point(DateFormat('MMM').format(month), total));
    }
    return result;
  }
}

class _Slice {
  final String label;
  final double value;
  final Color color;
  const _Slice(this.label, this.value, this.color);
}

class _Point {
  final String label;
  final double value;
  const _Point(this.label, this.value);
}

class _PieBreakdown extends StatelessWidget {
  final List<_Slice> slices;
  final String currency;

  const _PieBreakdown({required this.slices, required this.currency});

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) return const _NoData();
    final total = slices.fold<double>(0, (s, d) => s + d.value);

    return Column(
      children: [
        SizedBox(
          height: 190,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 56,
                  sections: [
                    for (final s in slices)
                      PieChartSectionData(
                        value: s.value,
                        color: s.color,
                        radius: 26,
                        showTitle: false,
                      ),
                  ],
                ),
                duration: Duration.zero,
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Total',
                      style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12)),
                  Text(
                    Formatters.compactMoney(total, symbol: currency),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            for (final s in slices)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: s.color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${total == 0 ? 0 : (s.value / total * 100).round()}%',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        Formatters.money(s.value, symbol: currency),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _TrendLine extends StatelessWidget {
  final List<_Point> points;
  final String currency;

  const _TrendLine({required this.points, required this.currency});

  @override
  Widget build(BuildContext context) {
    final hasData = points.any((p) => p.value > 0);
    if (!hasData) return const _NoData();

    final scheme = Theme.of(context).colorScheme;
    final maxY =
        points.map((p) => p.value).fold<double>(0, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY == 0 ? 10 : maxY * 1.2,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) => FlLine(
              color: scheme.outlineVariant.withValues(alpha: 0.4),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (value, meta) => Text(
                  Formatters.compactMoney(value, symbol: currency),
                  style: const TextStyle(fontSize: 9),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(points[idx].label,
                        style: const TextStyle(fontSize: 11)),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), points[i].value),
              ],
              isCurved: true,
              curveSmoothness: 0.3,
              barWidth: 3,
              color: scheme.primary,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: scheme.primary.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
        duration: Duration.zero,
      ),
    );
  }
}

class _NoData extends StatelessWidget {
  const _NoData();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 140,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded,
                size: 40, color: scheme.onSurfaceVariant),
            const SizedBox(height: 8),
            Text('No data for this month',
                style: TextStyle(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
