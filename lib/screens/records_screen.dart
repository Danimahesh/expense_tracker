import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/categories.dart';
import '../utils/formatters.dart';
import '../utils/payment_methods.dart';
import '../widgets/expense_tile.dart';
import 'add_expense_screen.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final currency = context.watch<SettingsProvider>().currency;
    final filtered = provider.filtered;
    final grouped = provider.groupByDay(filtered);
    final total = filtered.fold<double>(0, (s, e) => s + e.amount);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Records',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  _FilterButton(
                    active: provider.hasActiveFilters,
                    onTap: () => _openFilterSheet(context, provider),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: TextField(
                controller: _searchController,
                onChanged: provider.setSearchQuery,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search description, amount, category…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: provider.searchQuery.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            provider.setSearchQuery('');
                          },
                        ),
                ),
              ),
            ),
            if (provider.hasActiveFilters)
              _ActiveFilterBar(provider: provider),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${filtered.length} transactions',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    Formatters.money(total, symbol: currency),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Expanded(
              child: provider.loading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? const _EmptyState()
                      : ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(18, 4, 18, 130),
                          itemCount: grouped.length,
                          itemBuilder: (context, index) {
                            final day = grouped.keys.elementAt(index);
                            final items = grouped[day]!;
                            return _DayGroup(
                              day: day,
                              items: items,
                              currency: currency,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFilterSheet(BuildContext context, ExpenseProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(provider: provider),
    );
  }
}

class _DayGroup extends StatelessWidget {
  final DateTime day;
  final List<Expense> items;
  final String currency;

  const _DayGroup({
    required this.day,
    required this.items,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final dayTotal = items.fold<double>(0, (s, e) => s + e.amount);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Formatters.relativeHeader(day),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '-${Formatters.money(dayTotal, symbol: currency)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 18),
          ...List.generate(items.length, (i) {
            final e = items[i];
            return Column(
              children: [
                ExpenseTile(
                  expense: e,
                  currency: currency,
                  onTap: () => _openActions(context, e),
                ),
                if (i != items.length - 1)
                  Divider(
                    height: 6,
                    color: Theme.of(context)
                        .dividerColor
                        .withOpacity(0.4),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  void _openActions(BuildContext context, Expense expense) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        final cat = Categories.byKey(expense.category);
        final method = PaymentMethods.byKey(expense.paymentMethod);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: cat.color.withOpacity(0.2),
                      child: Icon(cat.icon, color: cat.color),
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
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${method.shortLabel} • ${Formatters.dayMonthYear(expense.date)}',
                            style:
                                Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      Formatters.money(expense.amount, symbol: currency),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                if (expense.notes.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(expense.notes,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddExpenseScreen(existing: expense),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                        onPressed: () async {
                          Navigator.pop(sheetContext);
                          await context
                              .read<ExpenseProvider>()
                              .deleteExpense(expense.id!);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Expense deleted')),
                            );
                          }
                        },
                        icon: const Icon(Icons.delete_rounded),
                        label: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FilterButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _FilterButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: active
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          Icons.tune_rounded,
          color: active ? Colors.white : null,
        ),
      ),
    );
  }
}

class _ActiveFilterBar extends StatelessWidget {
  final ExpenseProvider provider;
  const _ActiveFilterBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    final chips = <String>[];
    if (provider.dateFilter != DateFilter.all) {
      chips.add(_dateLabel(provider.dateFilter));
    }
    if (provider.categoryFilter != null) {
      chips.add(Categories.byKey(provider.categoryFilter!).label);
    }
    if (provider.methodFilter != null) {
      chips.add(PaymentMethods.byKey(provider.methodFilter!).shortLabel);
    }

    return Container(
      height: 44,
      margin: const EdgeInsets.only(top: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        children: [
          ...chips.map((c) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text(c),
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.18),
                ),
              )),
          ActionChip(
            avatar: const Icon(Icons.close_rounded, size: 16),
            label: const Text('Clear'),
            onPressed: provider.clearFilters,
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateFilter f) {
    switch (f) {
      case DateFilter.today:
        return 'Today';
      case DateFilter.yesterday:
        return 'Yesterday';
      case DateFilter.thisWeek:
        return 'This Week';
      case DateFilter.thisMonth:
        return 'This Month';
      case DateFilter.custom:
        return 'Custom Range';
      case DateFilter.all:
        return 'All';
    }
  }
}

class _FilterSheet extends StatefulWidget {
  final ExpenseProvider provider;
  const _FilterSheet({required this.provider});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Filters',
                style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 18),
            const Text('Date',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _dateChip('Today', DateFilter.today),
                _dateChip('Yesterday', DateFilter.yesterday),
                _dateChip('This Week', DateFilter.thisWeek),
                _dateChip('This Month', DateFilter.thisMonth),
                _customChip(),
                _dateChip('All', DateFilter.all),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Category',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: p.categoryFilter == null,
                  onSelected: (_) {
                    p.setCategoryFilter(null);
                    setState(() {});
                  },
                ),
                ...Categories.all.map((c) => ChoiceChip(
                      avatar: Icon(c.icon, size: 16, color: c.color),
                      label: Text(c.label),
                      selected: p.categoryFilter == c.key,
                      onSelected: (_) {
                        p.setCategoryFilter(
                            p.categoryFilter == c.key ? null : c.key);
                        setState(() {});
                      },
                    )),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Payment Method',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: p.methodFilter == null,
                  onSelected: (_) {
                    p.setMethodFilter(null);
                    setState(() {});
                  },
                ),
                ...PaymentMethods.all.map((m) => ChoiceChip(
                      avatar: Icon(m.icon, size: 16, color: m.color),
                      label: Text(m.shortLabel),
                      selected: p.methodFilter == m.key,
                      onSelected: (_) {
                        p.setMethodFilter(
                            p.methodFilter == m.key ? null : m.key);
                        setState(() {});
                      },
                    )),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      p.clearFilters();
                      setState(() {});
                    },
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateChip(String label, DateFilter filter) {
    return ChoiceChip(
      label: Text(label),
      selected: widget.provider.dateFilter == filter,
      onSelected: (_) {
        widget.provider.setDateFilter(filter);
        setState(() {});
      },
    );
  }

  Widget _customChip() {
    final selected = widget.provider.dateFilter == DateFilter.custom;
    return ChoiceChip(
      avatar: const Icon(Icons.date_range_rounded, size: 16),
      label: Text(
        selected && widget.provider.customRange != null
            ? '${Formatters.dayMonth(widget.provider.customRange!.start)} - ${Formatters.dayMonth(widget.provider.customRange!.end)}'
            : 'Custom Range',
      ),
      selected: selected,
      onSelected: (_) async {
        final now = DateTime.now();
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2015),
          lastDate: now.add(const Duration(days: 1)),
          initialDateRange: widget.provider.customRange ??
              DateTimeRange(
                start: now.subtract(const Duration(days: 7)),
                end: now,
              ),
        );
        if (range != null) {
          widget.provider.setDateFilter(DateFilter.custom, range: range);
          setState(() {});
        }
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_rounded,
              size: 64,
              color: Theme.of(context).dividerColor),
          const SizedBox(height: 16),
          const Text(
            'No expenses yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap the + button to add your first expense.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
