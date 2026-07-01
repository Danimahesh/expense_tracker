import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/categories.dart';
import '../utils/formatters.dart';
import '../utils/payment_methods.dart';

/// Fast add / edit expense. Fields: amount, category, payment method, date,
/// and optional notes — with a large Save button pinned at the bottom.
class AddExpenseScreen extends StatefulWidget {
  final Expense? existing;
  const AddExpenseScreen({super.key, this.existing});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  late String _category;
  late String _method;
  late DateTime _date;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _category = e?.category ?? Categories.all.first.key;
    _method = e?.paymentMethod ?? PaymentMethods.all.first.key;
    _date = e?.date ?? DateTime.now();
    if (e != null) {
      _amountController.text =
          e.amount % 1 == 0 ? e.amount.toStringAsFixed(0) : e.amount.toString();
      _notesController.text = e.notes;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountController.text.replaceAll(',', ''));

    final expense = Expense(
      id: widget.existing?.id,
      amount: amount,
      category: _category,
      paymentMethod: _method,
      description: widget.existing?.description ?? '',
      notes: _notesController.text.trim(),
      date: _date,
    );

    final provider = context.read<ExpenseProvider>();
    if (_isEditing) {
      await provider.updateExpense(expense);
    } else {
      await provider.addExpense(expense);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isEditing ? 'Expense updated' : 'Expense saved')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<SettingsProvider>().currency;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Expense' : 'Add Expense'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  _Label('Amount'),
                  TextFormField(
                    controller: _amountController,
                    autofocus: !_isEditing,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    style: const TextStyle(
                        fontSize: 30, fontWeight: FontWeight.w800),
                    decoration: InputDecoration(
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 8),
                        child: Text(
                          currency,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w800),
                        ),
                      ),
                      prefixIconConstraints:
                          const BoxConstraints(minWidth: 0, minHeight: 0),
                      hintText: '0',
                    ),
                    validator: (v) {
                      final parsed =
                          double.tryParse((v ?? '').replaceAll(',', ''));
                      if (parsed == null || parsed <= 0) {
                        return 'Enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 22),

                  _Label('Category'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: Categories.all.map((c) {
                      final selected = c.key == _category;
                      return ChoiceChip(
                        avatar: Icon(c.icon, size: 18, color: c.color),
                        label: Text(c.label),
                        selected: selected,
                        showCheckmark: false,
                        selectedColor: c.color.withValues(alpha: 0.20),
                        onSelected: (_) => setState(() => _category = c.key),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 22),

                  _Label('Payment method'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: PaymentMethods.all.map((m) {
                      final selected = m.key == _method;
                      return ChoiceChip(
                        avatar: Icon(m.icon, size: 18, color: m.color),
                        label: Text(m.shortLabel),
                        selected: selected,
                        showCheckmark: false,
                        selectedColor: m.color.withValues(alpha: 0.20),
                        onSelected: (_) => setState(() => _method = m.key),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 22),

                  _Label('Date'),
                  Row(
                    children: [
                      _QuickDateChip(
                        label: 'Today',
                        selected: _isSameDay(_date, DateTime.now()),
                        onTap: () => setState(() => _date = DateTime.now()),
                      ),
                      const SizedBox(width: 8),
                      _QuickDateChip(
                        label: 'Yesterday',
                        selected: _isSameDay(_date,
                            DateTime.now().subtract(const Duration(days: 1))),
                        onTap: () => setState(() => _date = DateTime.now()
                            .subtract(const Duration(days: 1))),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_today_rounded,
                              size: 18),
                          label: Text(
                            Formatters.dayMonthYear(_date),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  _Label('Notes (optional)'),
                  TextFormField(
                    controller: _notesController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Add a note',
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: Icon(
                      _isEditing ? Icons.check_rounded : Icons.save_rounded),
                  label: Text(_isEditing ? 'Update Expense' : 'Save Expense'),
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _QuickDateChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _QuickDateChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
    );
  }
}
