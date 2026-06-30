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

enum ChartRange { week, month, year }

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  ChartRange _range = ChartRange.month;

  DateTime get _rangeStart {
    final now = DateTime.now();
    switch (_range) {
      case ChartRange.week:
        final start = now.subtract(Duration(days: now.weekday - 1));
        return DateTime(start.year, start.month, start.day);
      case ChartRange.month:
        return DateTime(now.year, now.month, 1);
      case ChartRange.year:
        return DateTime(now.year, 1, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final currency = context.watch<SettingsProvider>().currency;

    final start = _rangeStart;
    final inRange = provider.all
        .where((e) => !e.date.isBefore(start))
        .toList();
    final rangeTotal = inRange.fold<double>(0, (s, e) => s + e.amount);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 130),
          children: [
            const Text(
              'Charts',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 14),
            _RangeSelector(
              range: _range,
              onChanged: (r) => setState(() => _range = r),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '${_rangeLabel()} total: ${Formatters.money(rangeTotal, symbol: currency)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),

            _ChartCard(
              title: 'Payment Method Breakdown',
              child: _DonutChart(
                data: _breakdownByMethod(inRange),
                currency: currency,
              ),
            ),
            const SizedBox(height: 16),

            _ChartCard(
              title: 'Category Breakdown',
              child: _DonutChart(
                data: _breakdownByCategory(inRange),
                currency: currency,
              ),
            ),
            const SizedBox(height: 16),

            _ChartCard(
              title: 'Monthly Spending Trend',
              child: _MonthlyLineChart(
                points: _monthlyTotals(provider.all, 6),
                currency: currency,
              ),
            ),
            const SizedBox(height: 16),

            _ChartCard(
              title: 'Weekly Spending',
              child: _BarSeriesChart(
                bars: _weeklyTotals(provider.all, 6),
                currency: currency,
                color: const Color(0xFF00E0B8),
              ),
            ),
            const SizedBox(height: 16),

            _ChartCard(
              title: 'Daily Spending',
              child: _BarSeriesChart(
                bars: _dailyTotals(provider.all, 7),
                currency: currency,
                color: const Color(0xFF7C5CFC),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _rangeLabel() {
    switch (_range) {
      case ChartRange.week:
        return 'This week';
      case ChartRange.month:
        return 'This month';
      case ChartRange.year:
        return 'This year';
    }
  }

  // --- Data builders --------------------------------------------------------

  List<_Slice> _breakdownByMethod(List<Expense> list) {
    final map = <String, double>{};
    for (final e in list) {
      map[e.paymentMethod] = (map[e.paymentMethod] ?? 0) + e.amount;
    }
    final slices = <_Slice>[];
    for (final m in PaymentMethods.all) {
      final v = map[m.key] ?? 0;
      if (v > 0) {
        slices.add(_Slice(m.shortLabel, v, m.color));
      }
    }
    slices.sort((a, b) => b.value.compareTo(a.value));
    return slices;
  }

  List<_Slice> _breakdownByCategory(List<Expense> list) {
    final map = <String, double>{};
    for (final e in list) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    final slices = <_Slice>[];
    for (final c in Categories.all) {
      final v = map[c.key] ?? 0;
      if (v > 0) {
        slices.add(_Slice(c.label, v, c.color));
      }
    }
    slices.sort((a, b) => b.value.compareTo(a.value));
    return slices;
  }

  List<_LabeledValue> _monthlyTotals(List<Expense> list, int months) {
    final now = DateTime.now();
    final result = <_LabeledValue>[];
    for (var i = months - 1; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final total = list
          .where((e) =>
              e.date.year == month.year && e.date.month == month.month)
          .fold<double>(0, (s, e) => s + e.amount);
      result.add(_LabeledValue(DateFormat('MMM').format(month), total));
    }
    return result;
  }

  List<_LabeledValue> _weeklyTotals(List<Expense> list, int weeks) {
    final now = DateTime.now();
    final startOfThisWeek =
        DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final result = <_LabeledValue>[];
    for (var i = weeks - 1; i >= 0; i--) {
      final weekStart = startOfThisWeek.subtract(Duration(days: 7 * i));
      final weekEnd = weekStart.add(const Duration(days: 7));
      final total = list
          .where((e) =>
              !e.date.isBefore(weekStart) && e.date.isBefore(weekEnd))
          .fold<double>(0, (s, e) => s + e.amount);
      result.add(_LabeledValue(DateFormat('d/M').format(weekStart), total));
    }
    return result;
  }

  List<_LabeledValue> _dailyTotals(List<Expense> list, int days) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final result = <_LabeledValue>[];
    for (var i = days - 1; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final total = list
          .where((e) =>
              e.date.year == day.year &&
              e.date.month == day.month &&
              e.date.day == day.day)
          .fold<double>(0, (s, e) => s + e.amount);
      result.add(_LabeledValue(DateFormat('E').format(day), total));
    }
    return result;
  }
}

// =============================================================================
// Models for chart data
// =============================================================================
class _Slice {
  final String label;
  final double value;
  final Color color;
  const _Slice(this.label, this.value, this.color);
}

class _LabeledValue {
  final String label;
  final double value;
  const _LabeledValue(this.label, this.value);
}

// =============================================================================
// Reusable card + range selector
// =============================================================================
class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  final ChartRange range;
  final ValueChanged<ChartRange> onChanged;

  const _RangeSelector({required this.range, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = {
      ChartRange.week: 'Week',
      ChartRange.month: 'Month',
      ChartRange.year: 'Year',
    };
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: options.entries.map((entry) {
          final selected = entry.key == range;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  entry.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// =============================================================================
// Donut chart
// =============================================================================
class _DonutChart extends StatefulWidget {
  final List<_Slice> data;
  final String currency;
  const _DonutChart({required this.data, required this.currency});

  @override
  State<_DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<_DonutChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const _NoData();
    }
    final total = widget.data.fold<double>(0, (s, d) => s + d.value);

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 58,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            response == null ||
                            response.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex =
                            response.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  sections: List.generate(widget.data.length, (i) {
                    final slice = widget.data[i];
                    final isTouched = i == _touchedIndex;
                    final pct = total == 0 ? 0 : (slice.value / total) * 100;
                    return PieChartSectionData(
                      value: slice.value,
                      color: slice.color,
                      radius: isTouched ? 32 : 26,
                      title: pct >= 7 ? '${pct.toStringAsFixed(0)}%' : '',
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    );
                  }),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    Formatters.compactMoney(total, symbol: widget.currency),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 14,
          runSpacing: 8,
          children: widget.data.map((slice) {
            final pct = total == 0 ? 0 : (slice.value / total) * 100;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: slice.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${slice.label} (${pct.toStringAsFixed(0)}%)',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

// =============================================================================
// Monthly line chart
// =============================================================================
class _MonthlyLineChart extends StatelessWidget {
  final List<_LabeledValue> points;
  final String currency;
  const _MonthlyLineChart({required this.points, required this.currency});

  @override
  Widget build(BuildContext context) {
    final hasData = points.any((p) => p.value > 0);
    if (!hasData) return const _NoData();

    final maxY = points.map((p) => p.value).fold<double>(0, (a, b) => a > b ? a : b);
    final interval = _niceInterval(maxY);

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY == 0 ? 10 : maxY * 1.2,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Theme.of(context).dividerColor.withOpacity(0.4),
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
                reservedSize: 42,
                interval: interval,
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
              spots: List.generate(
                points.length,
                (i) => FlSpot(i.toDouble(), points[i].value),
              ),
              isCurved: true,
              curveSmoothness: 0.32,
              barWidth: 3.5,
              color: const Color(0xFF7C5CFC),
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF7C5CFC).withOpacity(0.35),
                    const Color(0xFF7C5CFC).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Generic bar chart (weekly / daily)
// =============================================================================
class _BarSeriesChart extends StatelessWidget {
  final List<_LabeledValue> bars;
  final String currency;
  final Color color;

  const _BarSeriesChart({
    required this.bars,
    required this.currency,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = bars.any((b) => b.value > 0);
    if (!hasData) return const _NoData();

    final maxY = bars.map((b) => b.value).fold<double>(0, (a, b) => a > b ? a : b);
    final interval = _niceInterval(maxY);

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: maxY == 0 ? 10 : maxY * 1.2,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Theme.of(context).dividerColor.withOpacity(0.4),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => color,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  Formatters.money(rod.toY, symbol: currency),
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                interval: interval,
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
                  if (idx < 0 || idx >= bars.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(bars[idx].label,
                        style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(bars.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: bars[i].value,
                  width: 16,
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      color.withOpacity(0.55),
                      color,
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _NoData extends StatelessWidget {
  const _NoData();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded,
                size: 40, color: Theme.of(context).dividerColor),
            const SizedBox(height: 8),
            Text('No data for this period',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

/// Picks a "nice" round axis interval so labels don't overlap.
double _niceInterval(double maxY) {
  if (maxY <= 0) return 5;
  final raw = maxY / 4;
  final magnitude =
      (raw <= 0) ? 1 : (raw.toString().split('.').first.length);
  final base = [1, 2, 5, 10];
  final scale = (magnitude - 1).clamp(0, 12).toInt();
  final unit = _pow10(scale);
  for (final b in base) {
    final candidate = b * unit;
    if (candidate >= raw) return candidate.toDouble();
  }
  return (10 * unit).toDouble();
}

double _pow10(int exp) {
  var v = 1.0;
  for (var i = 0; i < exp; i++) {
    v *= 10;
  }
  return v;
}
