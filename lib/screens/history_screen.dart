import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/categories.dart';
import '../utils/formatters.dart';
import '../utils/payment_methods.dart';
import '../widgets/expense_details_sheet.dart';
import '../widgets/expense_tile.dart';
import 'add_expense_screen.dart';

/// The single transaction-history screen: search, filter, date-grouped list,
/// swipe to edit/delete, tap for details.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
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
    final rows = _buildRows(filtered);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            tooltip: 'Filter',
            onPressed: () => _openFilters(provider),
            icon: Badge(
              isLabelVisible: provider.hasActiveFilters,
              child: const Icon(Icons.filter_list_rounded),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onChanged: provider.setSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Search transactions',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: provider.searchQuery.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _searchController.clear();
                            provider.setSearchQuery('');
                          },
                        ),
                ),
              ),
            ),
            Expanded(
              child: provider.loading
                  ? const Center(child: CircularProgressIndicator())
                  : rows.isEmpty
                      ? const _EmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                          itemCount: rows.length,
                          itemBuilder: (context, i) {
                            final row = rows[i];
                            if (row is _HeaderRow) {
                              return _DateHeader(label: row.label);
                            }
                            final e = (row as _ItemRow).expense;
                            return _SwipeableItem(
                              key: ValueKey(e.id),
                              expense: e,
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

  List<_Row> _buildRows(List<Expense> items) {
    final rows = <_Row>[];
    DateTime? lastDay;
    for (final e in items) {
      final day = DateTime(e.date.year, e.date.month, e.date.day);
      if (lastDay == null || day != lastDay) {
        rows.add(_HeaderRow(Formatters.historyHeader(day)));
        lastDay = day;
      }
      rows.add(_ItemRow(e));
    }
    return rows;
  }

  void _openFilters(ExpenseProvider provider) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(provider: provider),
    );
  }
}

// =============================================================================
// Row model
// =============================================================================
sealed class _Row {}

class _HeaderRow extends _Row {
  final String label;
  _HeaderRow(this.label);
}

class _ItemRow extends _Row {
  final Expense expense;
  _ItemRow(this.expense);
}

// =============================================================================
// List pieces
// =============================================================================
class _DateHeader extends StatelessWidget {
  final String label;
  const _DateHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _SwipeableItem extends StatelessWidget {
  final Expense expense;
  final String currency;

  const _SwipeableItem({
    super.key,
    required this.expense,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey('dismiss_${expense.id}'),
      // Swipe right -> edit (snaps back), swipe left -> delete.
      background: _swipeBg(
        color: scheme.primary,
        icon: Icons.edit_rounded,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _swipeBg(
        color: scheme.error,
        icon: Icons.delete_rounded,
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Edit: open the editor and keep the row in place.
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddExpenseScreen(existing: expense),
            ),
          );
          return false;
        }
        return true; // delete
      },
      onDismissed: (_) {
        final messenger = ScaffoldMessenger.of(context);
        final removed = expense;
        context.read<ExpenseProvider>().deleteExpense(removed.id!);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Expense deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                context
                    .read<ExpenseProvider>()
                    .addExpense(removed.copyWith(id: null));
              },
            ),
          ),
        );
      },
      child: ExpenseTile(
        expense: expense,
        currency: currency,
        onTap: () => showExpenseDetails(context, expense, currency),
      ),
    );
  }

  Widget _swipeBg({
    required Color color,
    required IconData icon,
    required Alignment alignment,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      alignment: alignment,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: Colors.white),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_rounded,
              size: 56, color: scheme.onSurfaceVariant),
          const SizedBox(height: 14),
          const Text(
            'No transactions found',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Try adjusting your search or filters.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Filter sheet
// =============================================================================
class _FilterSheet extends StatefulWidget {
  final ExpenseProvider provider;
  const _FilterSheet({required this.provider});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  ExpenseProvider get p => widget.provider;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filters',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            const Text('Date', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _dateChip('All', DateFilter.all),
                _dateChip('Today', DateFilter.today),
                _dateChip('Yesterday', DateFilter.yesterday),
                _dateChip('This Week', DateFilter.thisWeek),
                _dateChip('This Month', DateFilter.thisMonth),
              ],
            ),
            const SizedBox(height: 18),
            const Text('Category',
                style: TextStyle(fontWeight: FontWeight.w600)),
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
            const SizedBox(height: 18),
            const Text('Payment method',
                style: TextStyle(fontWeight: FontWeight.w600)),
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
            const SizedBox(height: 22),
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
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
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
      selected: p.dateFilter == filter,
      onSelected: (_) {
        p.setDateFilter(filter);
        setState(() {});
      },
    );
  }
}
