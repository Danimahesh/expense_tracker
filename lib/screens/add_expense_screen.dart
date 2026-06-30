import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../utils/categories.dart';
import '../utils/formatters.dart';
import '../utils/payment_methods.dart';

/// Add or edit an expense. Pass [existing] to edit.
class AddExpenseScreen extends StatefulWidget {
  final Expense? existing;
  const AddExpenseScreen({super.key, this.existing});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  String _category = Categories.all.first.key;
  String _method = PaymentMethods.all.first.key;
  DateTime _date = DateTime.now();

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _amountController.text =
          e.amount % 1 == 0 ? e.amount.toStringAsFixed(0) : e.amount.toString();
      _descriptionController.text = e.description;
      _notesController.text = e.notes;
      _category = e.category;
      _method = e.paymentMethod;
      _date = e.date;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
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
      setState(() => _date = DateTime(
            picked.year,
            picked.month,
            picked.day,
            _date.hour,
            _date.minute,
          ));
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
      description: _descriptionController.text.trim(),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Expense' : 'Add Expense'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
          children: [
            // Amount
            _label('Amount'),
            TextFormField(
              controller: _amountController,
              autofocus: !_isEditing,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 18, right: 8),
                  child: Text(
                    currency,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 0, minHeight: 0),
                hintText: '0',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter an amount';
                final parsed = double.tryParse(v.replaceAll(',', ''));
                if (parsed == null || parsed <= 0) {
                  return 'Enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 22),

            // Category
            _label('Category'),
            _CategoryGrid(
              selected: _category,
              onSelect: (k) => setState(() => _category = k),
            ),
            const SizedBox(height: 22),

            // Payment method
            _label('Payment Method'),
            _MethodSelector(
              selected: _method,
              onSelect: (k) => setState(() => _method = k),
            ),
            const SizedBox(height: 22),

            // Description
            _label('Description'),
            TextFormField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'e.g. Lunch at cafe',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 18),

            // Date
            _label('Date'),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                decoration: BoxDecoration(
                  color: Theme.of(context).inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 20),
                    const SizedBox(width: 14),
                    Text(
                      Formatters.dayMonthYear(_date),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Optional notes
            _label('Optional Notes'),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Add a note (optional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: Icon(_isEditing
                    ? Icons.check_rounded
                    : Icons.save_rounded),
                label: Text(_isEditing ? 'Update Expense' : 'Save Expense'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 2),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      );
}

class _CategoryGrid extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _CategoryGrid({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: Categories.all.map((c) {
        final isSelected = c.key == selected;
        return GestureDetector(
          onTap: () => onSelect(c.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? c.color.withOpacity(0.20)
                  : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? c.color : Colors.transparent,
                width: 1.6,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(c.icon, size: 18, color: c.color),
                const SizedBox(width: 8),
                Text(
                  c.label,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MethodSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _MethodSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: PaymentMethods.all.map((m) {
        final isSelected = m.key == selected;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => onSelect(m.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected
                    ? m.color.withOpacity(0.16)
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? m.color : Colors.transparent,
                  width: 1.6,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: m.color.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(m.icon, color: m.color, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          m.hasBillingCycle
                              ? 'Custom billing cycle'
                              : 'Monthly total',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  AnimatedScale(
                    scale: isSelected ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(Icons.check_circle_rounded,
                        color: m.color == AppTheme.accent
                            ? AppTheme.accent
                            : m.color),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
