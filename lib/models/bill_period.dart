import '../utils/payment_methods.dart';

/// Represents one billing period for a payment method.
///
/// For methods with a real billing cycle (BOB, Amazon Pay Later) the
/// [start] / [end] describe the custom cycle. For calendar-based methods
/// (Cash, UPI) the period simply spans one calendar month.
class BillPeriod {
  final PaymentType type;
  final DateTime start;
  final DateTime end;
  final DateTime? statementDate;
  final DateTime? dueDate;

  const BillPeriod({
    required this.type,
    required this.start,
    required this.end,
    this.statementDate,
    this.dueDate,
  });

  /// A stable key identifying this period (used for grouping).
  String get key =>
      '${type.name}_${start.year}-${start.month}-${start.day}';

  /// Whether the given date falls inside this period (inclusive).
  bool contains(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return !d.isBefore(s) && !d.isAfter(e);
  }

  /// Days remaining until the due date from [from] (default now).
  /// Returns null when there is no due date.
  int? daysRemaining([DateTime? from]) {
    if (dueDate == null) return null;
    final ref = from ?? DateTime.now();
    final today = DateTime(ref.year, ref.month, ref.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return due.difference(today).inDays;
  }
}
