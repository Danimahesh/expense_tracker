import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/bill_period.dart';
import '../models/expense.dart';
import '../services/billing_engine.dart';
import '../utils/payment_methods.dart';

/// Quick date-range filters available on the records screen.
enum DateFilter { all, today, yesterday, thisWeek, thisMonth, custom }

/// Central store of expenses + derived data (bills, totals, grouping).
class ExpenseProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Expense> _all = [];
  bool _loading = true;

  // Filter state for the records screen.
  String _searchQuery = '';
  DateFilter _dateFilter = DateFilter.all;
  DateTimeRange? _customRange;
  String? _categoryFilter; // category key
  String? _methodFilter; // payment method key

  bool get loading => _loading;
  List<Expense> get all => List.unmodifiable(_all);

  String get searchQuery => _searchQuery;
  DateFilter get dateFilter => _dateFilter;
  DateTimeRange? get customRange => _customRange;
  String? get categoryFilter => _categoryFilter;
  String? get methodFilter => _methodFilter;

  bool get hasActiveFilters =>
      _dateFilter != DateFilter.all ||
      _categoryFilter != null ||
      _methodFilter != null;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _all = await _db.getAllExpenses();
    _loading = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  Future<void> addExpense(Expense expense) async {
    final id = await _db.insertExpense(expense);
    _all = [expense.copyWith(id: id), ..._all];
    _sort();
    notifyListeners();
  }

  Future<void> updateExpense(Expense expense) async {
    await _db.updateExpense(expense);
    final idx = _all.indexWhere((e) => e.id == expense.id);
    if (idx != -1) _all[idx] = expense;
    _sort();
    notifyListeners();
  }

  Future<void> deleteExpense(int id) async {
    // Remove optimistically so swipe-to-dismiss and the UI update instantly,
    // then persist.
    _all.removeWhere((e) => e.id == id);
    notifyListeners();
    await _db.deleteExpense(id);
  }

  Future<void> resetAll() async {
    await _db.deleteAllExpenses();
    _all = [];
    notifyListeners();
  }

  void _sort() {
    _all.sort((a, b) {
      final c = b.date.compareTo(a.date);
      if (c != 0) return c;
      return (b.id ?? 0).compareTo(a.id ?? 0);
    });
  }

  // ---------------------------------------------------------------------------
  // Filters
  // ---------------------------------------------------------------------------

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setDateFilter(DateFilter f, {DateTimeRange? range}) {
    _dateFilter = f;
    if (f == DateFilter.custom) _customRange = range;
    notifyListeners();
  }

  void setCategoryFilter(String? key) {
    _categoryFilter = key;
    notifyListeners();
  }

  void setMethodFilter(String? key) {
    _methodFilter = key;
    notifyListeners();
  }

  void clearFilters() {
    _dateFilter = DateFilter.all;
    _customRange = null;
    _categoryFilter = null;
    _methodFilter = null;
    _searchQuery = '';
    notifyListeners();
  }

  DateTimeRange? activeDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_dateFilter) {
      case DateFilter.all:
        return null;
      case DateFilter.today:
        return DateTimeRange(
            start: today, end: today.add(const Duration(days: 1)));
      case DateFilter.yesterday:
        final y = today.subtract(const Duration(days: 1));
        return DateTimeRange(start: y, end: today);
      case DateFilter.thisWeek:
        final start = today.subtract(Duration(days: today.weekday - 1));
        return DateTimeRange(
            start: start, end: start.add(const Duration(days: 7)));
      case DateFilter.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 1);
        return DateTimeRange(start: start, end: end);
      case DateFilter.custom:
        if (_customRange == null) return null;
        return DateTimeRange(
          start: DateTime(_customRange!.start.year,
              _customRange!.start.month, _customRange!.start.day),
          end: DateTime(_customRange!.end.year, _customRange!.end.month,
                  _customRange!.end.day)
              .add(const Duration(days: 1)),
        );
    }
  }

  /// The expense list after applying all active filters + search.
  List<Expense> get filtered {
    final range = activeDateRange();
    final q = _searchQuery.trim().toLowerCase();
    return _all.where((e) {
      if (range != null) {
        if (e.date.isBefore(range.start) || !e.date.isBefore(range.end)) {
          return false;
        }
      }
      if (_categoryFilter != null && e.category != _categoryFilter) {
        return false;
      }
      if (_methodFilter != null && e.paymentMethod != _methodFilter) {
        return false;
      }
      if (q.isNotEmpty && !_matchesQuery(e, q)) return false;
      return true;
    }).toList();
  }

  bool _matchesQuery(Expense e, String q) {
    final method = PaymentMethods.byKey(e.paymentMethod).label.toLowerCase();
    final amount = e.amount.toStringAsFixed(2);
    final amountInt = e.amount.toStringAsFixed(0);
    final dateStr =
        '${e.date.day}/${e.date.month}/${e.date.year}'.toLowerCase();
    return e.description.toLowerCase().contains(q) ||
        e.notes.toLowerCase().contains(q) ||
        e.category.toLowerCase().contains(q) ||
        method.contains(q) ||
        amount.contains(q) ||
        amountInt.contains(q) ||
        dateStr.contains(q);
  }

  /// Groups a list of expenses by calendar day (newest first).
  Map<DateTime, List<Expense>> groupByDay(List<Expense> list) {
    final map = <DateTime, List<Expense>>{};
    for (final e in list) {
      final day = DateTime(e.date.year, e.date.month, e.date.day);
      map.putIfAbsent(day, () => []).add(e);
    }
    final sortedKeys = map.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    return {for (final k in sortedKeys) k: map[k]!};
  }

  // ---------------------------------------------------------------------------
  // Bill / total computations
  // ---------------------------------------------------------------------------

  /// Total spent on [type] within the period containing [reference] (now).
  double currentBillTotal(PaymentType type, [DateTime? reference]) {
    final period = BillingEngine.currentPeriod(type, reference);
    return totalInPeriod(type, period);
  }

  double totalInPeriod(PaymentType type, BillPeriod period) {
    final methodKey = PaymentMethods.byType(type).key;
    double sum = 0;
    for (final e in _all) {
      if (e.paymentMethod == methodKey && period.contains(e.date)) {
        sum += e.amount;
      }
    }
    return sum;
  }

  /// Total for cash/upi in the current calendar month.
  double currentMonthTotal(PaymentType type, [DateTime? reference]) {
    final now = reference ?? DateTime.now();
    final methodKey = PaymentMethods.byType(type).key;
    double sum = 0;
    for (final e in _all) {
      if (e.paymentMethod == methodKey &&
          e.date.year == now.year &&
          e.date.month == now.month) {
        sum += e.amount;
      }
    }
    return sum;
  }

  /// Grand total across every recorded expense.
  double get grandTotal =>
      _all.fold(0.0, (sum, e) => sum + e.amount);

  /// Grand total of the "current" bills/months shown on the home screen.
  double currentGrandTotal([DateTime? reference]) {
    return currentBillTotal(PaymentType.bob, reference) +
        currentBillTotal(PaymentType.amazon, reference) +
        currentMonthTotal(PaymentType.cash, reference) +
        currentMonthTotal(PaymentType.upi, reference);
  }
}
