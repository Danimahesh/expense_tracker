import '../models/bill_period.dart';
import '../utils/payment_methods.dart';

/// The custom billing engine.
///
/// Assigns every expense to the correct billing period based on its
/// payment method. Billing cycles are NEVER calendar months for the
/// credit / pay-later methods — each uses its own cycle rules.
///
/// Bank of Baroda Credit Card:
///   * Cycle: 14th of a month  ->  13th of the next month.
///   * Statement date: 14th (day after the cycle closes).
///   * Payment due: 30th of the month in which the cycle closes
///     (clamped to the last day for short months).
///
/// Amazon Pay Later:
///   * Cycle: 1st of a month  ->  last day of the same month.
///   * Payment due: 1st of the next month.
///
/// Cash / UPI:
///   * No billing cycle — grouped by calendar month only.
class BillingEngine {
  BillingEngine._();

  /// Returns the billing period that the given [date] belongs to for [type].
  static BillPeriod periodFor(PaymentType type, DateTime date) {
    switch (type) {
      case PaymentType.bob:
        return _bobPeriod(date);
      case PaymentType.amazon:
        return _amazonPeriod(date);
      case PaymentType.cash:
      case PaymentType.upi:
        return _calendarMonthPeriod(type, date);
    }
  }

  /// Convenience: the billing period that contains "today".
  static BillPeriod currentPeriod(PaymentType type, [DateTime? now]) {
    return periodFor(type, now ?? DateTime.now());
  }

  // ---------------------------------------------------------------------------
  // BOB Credit Card  (14th -> 13th)
  // ---------------------------------------------------------------------------
  static BillPeriod _bobPeriod(DateTime date) {
    late DateTime start;
    late DateTime end;

    if (date.day >= 14) {
      // Cycle opened on the 14th of THIS month.
      start = DateTime(date.year, date.month, 14);
      end = _dateClamped(date.year, date.month + 1, 13);
    } else {
      // Cycle opened on the 14th of the PREVIOUS month.
      start = _dateClamped(date.year, date.month - 1, 14);
      end = DateTime(date.year, date.month, 13);
    }

    // Statement on the 14th (day the cycle closes + 1), due on the 30th.
    final statement = _dateClamped(end.year, end.month, 14);
    final due = _dateClamped(end.year, end.month, 30);

    return BillPeriod(
      type: PaymentType.bob,
      start: start,
      end: end,
      statementDate: statement,
      dueDate: due,
    );
  }

  // ---------------------------------------------------------------------------
  // Amazon Pay Later  (1st -> last day of month)
  // ---------------------------------------------------------------------------
  static BillPeriod _amazonPeriod(DateTime date) {
    final start = DateTime(date.year, date.month, 1);
    final end = _lastDayOfMonth(date.year, date.month);
    // Due on the 1st of the next month.
    final due = DateTime(date.year, date.month + 1, 1);

    return BillPeriod(
      type: PaymentType.amazon,
      start: start,
      end: end,
      statementDate: end,
      dueDate: due,
    );
  }

  // ---------------------------------------------------------------------------
  // Cash / UPI  (calendar month, no due date)
  // ---------------------------------------------------------------------------
  static BillPeriod _calendarMonthPeriod(PaymentType type, DateTime date) {
    final start = DateTime(date.year, date.month, 1);
    final end = _lastDayOfMonth(date.year, date.month);
    return BillPeriod(type: type, start: start, end: end);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Builds a date, clamping the day to the last valid day of the
  /// (possibly overflowing) month so we never produce an invalid date.
  static DateTime _dateClamped(int year, int month, int day) {
    // Normalise month overflow / underflow.
    var y = year;
    var m = month;
    while (m > 12) {
      m -= 12;
      y += 1;
    }
    while (m < 1) {
      m += 12;
      y -= 1;
    }
    final lastDay = _lastDayOfMonth(y, m).day;
    final d = day > lastDay ? lastDay : day;
    return DateTime(y, m, d);
  }

  static DateTime _lastDayOfMonth(int year, int month) {
    // Day 0 of the next month == last day of this month.
    return DateTime(year, month + 1, 0);
  }
}
