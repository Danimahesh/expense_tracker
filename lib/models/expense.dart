/// A single recorded expense.
class Expense {
  final int? id;
  final double amount;
  final String category; // category key
  final String paymentMethod; // payment method key
  final String description;
  final String notes;
  final DateTime date;

  const Expense({
    this.id,
    required this.amount,
    required this.category,
    required this.paymentMethod,
    required this.description,
    this.notes = '',
    required this.date,
  });

  Expense copyWith({
    int? id,
    double? amount,
    String? category,
    String? paymentMethod,
    String? description,
    String? notes,
    DateTime? date,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'payment_method': paymentMethod,
      'description': description,
      'notes': notes,
      'date': date.millisecondsSinceEpoch,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      paymentMethod: map['payment_method'] as String,
      description: (map['description'] as String?) ?? '',
      notes: (map['notes'] as String?) ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
    );
  }
}
