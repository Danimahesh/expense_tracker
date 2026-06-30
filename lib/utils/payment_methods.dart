import 'package:flutter/material.dart';

/// The supported payment method types.
enum PaymentType { bob, amazon, cash, upi }

/// Definition / metadata for a payment method.
class PaymentMethodDef {
  final PaymentType type;
  final String key;
  final String label;
  final String shortLabel;
  final IconData icon;
  final Color color;

  /// Whether this method has a custom (non-calendar) billing cycle.
  final bool hasBillingCycle;

  const PaymentMethodDef({
    required this.type,
    required this.key,
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.color,
    required this.hasBillingCycle,
  });
}

class PaymentMethods {
  PaymentMethods._();

  static const PaymentMethodDef bob = PaymentMethodDef(
    type: PaymentType.bob,
    key: 'bob',
    label: 'Bank of Baroda Credit Card',
    shortLabel: 'BOB Card',
    icon: Icons.credit_card_rounded,
    color: Color(0xFFFF6B6B),
    hasBillingCycle: true,
  );

  static const PaymentMethodDef amazon = PaymentMethodDef(
    type: PaymentType.amazon,
    key: 'amazon',
    label: 'Amazon Pay Later',
    shortLabel: 'Amazon Pay Later',
    icon: Icons.shopping_cart_rounded,
    color: Color(0xFFFFA726),
    hasBillingCycle: true,
  );

  static const PaymentMethodDef cash = PaymentMethodDef(
    type: PaymentType.cash,
    key: 'cash',
    label: 'Cash',
    shortLabel: 'Cash',
    icon: Icons.payments_rounded,
    color: Color(0xFF66BB6A),
    hasBillingCycle: false,
  );

  static const PaymentMethodDef upi = PaymentMethodDef(
    type: PaymentType.upi,
    key: 'upi',
    label: 'UPI',
    shortLabel: 'UPI',
    icon: Icons.qr_code_rounded,
    color: Color(0xFF7E57C2),
    hasBillingCycle: false,
  );

  static const List<PaymentMethodDef> all = [bob, amazon, cash, upi];

  static PaymentMethodDef byKey(String key) {
    return all.firstWhere(
      (m) => m.key == key,
      orElse: () => cash,
    );
  }

  static PaymentMethodDef byType(PaymentType type) {
    return all.firstWhere((m) => m.type == type);
  }
}
