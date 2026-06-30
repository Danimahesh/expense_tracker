import 'package:expense_tracker/services/billing_engine.dart';
import 'package:expense_tracker/utils/payment_methods.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BillingEngine - BOB credit card (14th -> 13th)', () {
    test('15 June belongs to 14 Jun -> 13 Jul', () {
      final p = BillingEngine.periodFor(PaymentType.bob, DateTime(2026, 6, 15));
      expect(p.start, DateTime(2026, 6, 14));
      expect(p.end, DateTime(2026, 7, 13));
    });

    test('10 July still belongs to 14 Jun -> 13 Jul', () {
      final p = BillingEngine.periodFor(PaymentType.bob, DateTime(2026, 7, 10));
      expect(p.start, DateTime(2026, 6, 14));
      expect(p.end, DateTime(2026, 7, 13));
    });

    test('14 July starts a new bill (14 Jul -> 13 Aug)', () {
      final p = BillingEngine.periodFor(PaymentType.bob, DateTime(2026, 7, 14));
      expect(p.start, DateTime(2026, 7, 14));
      expect(p.end, DateTime(2026, 8, 13));
    });

    test('due date is the 30th of the closing month', () {
      final p = BillingEngine.periodFor(PaymentType.bob, DateTime(2026, 6, 15));
      expect(p.dueDate, DateTime(2026, 7, 30));
    });
  });

  group('BillingEngine - Amazon Pay Later (1st -> last day)', () {
    test('5 June belongs to 1 Jun -> 30 Jun', () {
      final p =
          BillingEngine.periodFor(PaymentType.amazon, DateTime(2026, 6, 5));
      expect(p.start, DateTime(2026, 6, 1));
      expect(p.end, DateTime(2026, 6, 30));
    });

    test('29 June belongs to 1 Jun -> 30 Jun', () {
      final p =
          BillingEngine.periodFor(PaymentType.amazon, DateTime(2026, 6, 29));
      expect(p.start, DateTime(2026, 6, 1));
      expect(p.end, DateTime(2026, 6, 30));
    });

    test('1 July starts the next bill', () {
      final p =
          BillingEngine.periodFor(PaymentType.amazon, DateTime(2026, 7, 1));
      expect(p.start, DateTime(2026, 7, 1));
      expect(p.end, DateTime(2026, 7, 31));
    });

    test('due date is the 1st of the next month', () {
      final p =
          BillingEngine.periodFor(PaymentType.amazon, DateTime(2026, 6, 5));
      expect(p.dueDate, DateTime(2026, 7, 1));
    });
  });

  group('BillingEngine - Cash / UPI (calendar month)', () {
    test('Cash uses the calendar month', () {
      final p =
          BillingEngine.periodFor(PaymentType.cash, DateTime(2026, 2, 10));
      expect(p.start, DateTime(2026, 2, 1));
      expect(p.end, DateTime(2026, 2, 28));
      expect(p.dueDate, isNull);
    });
  });
}
