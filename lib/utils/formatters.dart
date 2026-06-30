import 'package:intl/intl.dart';

/// Helpers for formatting money and dates consistently across the app.
class Formatters {
  Formatters._();

  /// Formats an amount with the given currency symbol and thousands separators.
  static String money(num value, {String symbol = '₹'}) {
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: value % 1 == 0 ? 0 : 2,
      locale: 'en_IN',
    );
    return formatter.format(value);
  }

  /// Compact money for tight spaces, e.g. ₹1.2K.
  static String compactMoney(num value, {String symbol = '₹'}) {
    if (value.abs() < 1000) return money(value, symbol: symbol);
    final formatter = NumberFormat.compactCurrency(
      symbol: symbol,
      decimalDigits: 1,
      locale: 'en_IN',
    );
    return formatter.format(value);
  }

  static String dayMonth(DateTime date) => DateFormat('d MMM').format(date);

  static String dayMonthYear(DateTime date) =>
      DateFormat('d MMM yyyy').format(date);

  static String fullDate(DateTime date) =>
      DateFormat('EEEE, d MMMM yyyy').format(date);

  static String monthYear(DateTime date) =>
      DateFormat('MMMM yyyy').format(date);

  static String weekday(DateTime date) => DateFormat('EEE').format(date);

  /// Friendly date header used in the records list.
  static String relativeHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('EEEE, d MMM').format(date);
  }
}
