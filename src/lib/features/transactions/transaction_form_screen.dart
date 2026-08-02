import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction.dart';
import '../categories/categories_provider.dart';
import 'transactions_provider.dart';

/// Add/edit transaction screen. Pass [transaction] to edit an existing one;
/// omit it to create a new transaction.
class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({super.key, this.transaction});

  final Transaction? transaction;

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  late String _type;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  String? _categoryId;
  DateTime? _date;

  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _type = tx?.type ?? 'expense';
    _amountController =
        TextEditingController(text: tx != null ? _trimAmount(tx.amount) : '');
    _noteController = TextEditingController(text: tx?.note ?? '');
    _categoryId = tx?.categoryId;
    _date = tx != null ? DateTime.parse(tx.date) : DateTime.now();
  }

  static String _trimAmount(double amount) {
    return amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double? get _parsedAmount => double.tryParse(_amountController.text);

  bool get _canSave => isValidTransactionInput(
        amount: _parsedAmount,
        categoryId: _categoryId,
        date: _date?.toIso8601String(),
      );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final notifier = ref.read(transactionsProvider.notifier);
    final dateIso = toIsoDate(_date!);
    final ok = _isEditing
        ? await notifier.updateTransaction(
            widget.transaction!.id,
            type: _type,
            categoryId: _categoryId,
            amount: _parsedAmount!,
            date: dateIso,
            note: _noteController.text,
          )
        : await notifier.addTransaction(
            type: _type,
            categoryId: _categoryId,
            amount: _parsedAmount!,
            date: dateIso,
            note: _noteController.text,
          );
    if (ok && mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await ref
        .read(transactionsProvider.notifier)
        .deleteTransaction(widget.transaction!.id);
    if (mounted) Navigator.of(context).pop();
  }

  void _setType(String type) {
    if (_type == type) return;
    setState(() {
      _type = type;
      _categoryId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final categories = ref.watch(categoriesProvider);
    final formCategories =
        categories.where((c) => c.type == _type && c.active).toList();

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: _isEditing ? 'Edit Transaction' : 'Add Transaction',
              canSave: _canSave,
              onSave: _save,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TypeToggle(type: _type, onChanged: _setType),
                    const SizedBox(height: 18),
                    _FieldLabel('Amount (৳)'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                      decoration: _inputDecoration(colors, hint: '0.00'),
                    ),
                    const SizedBox(height: 18),
                    _FieldLabel('Category'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final c in formCategories)
                          _CategoryChip(
                            category: c,
                            selected: c.id == _categoryId,
                            type: _type,
                            onTap: () => setState(() => _categoryId = c.id),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _FieldLabel('Date'),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          border: Border.all(color: colors.border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _date != null
                                    ? shortDateLabel(_date!)
                                    : 'Select date',
                                style: TextStyle(
                                    fontSize: 14, color: colors.textPrimary),
                              ),
                            ),
                            Icon(Icons.calendar_today_rounded,
                                size: 16, color: colors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _FieldLabel('Note (optional)'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _noteController,
                      style: TextStyle(fontSize: 14, color: colors.textPrimary),
                      decoration: _inputDecoration(colors, hint: 'Add a note'),
                    ),
                    if (_isEditing) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _delete,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: colors.expense),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Delete Transaction',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: colors.expense,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(AppColors colors, {required String hint}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colors.border),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colors.textSecondary),
      filled: true,
      fillColor: colors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: colors.primary),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.canSave, required this.onSave});

  final String title;
  final bool canSave;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          ),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: canSave ? onSave : null,
            child: Opacity(
              opacity: canSave ? 1 : 0.4,
              child: Text(
                'Save',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: context.colors.textSecondary,
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.type, required this.onChanged});

  final String type;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.chipBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _segment(
              context,
              label: 'Expense',
              selected: type == 'expense',
              selectedBg: colors.expenseSoft,
              selectedColor: colors.expense,
              onTap: () => onChanged('expense'),
            ),
          ),
          Expanded(
            child: _segment(
              context,
              label: 'Income',
              selected: type == 'income',
              selectedBg: colors.primarySoft,
              selectedColor: colors.income,
              onTap: () => onChanged('income'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _segment(
    BuildContext context, {
    required String label,
    required bool selected,
    required Color selectedBg,
    required Color selectedColor,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? selectedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? selectedColor : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.type,
    required this.onTap,
  });

  final Category category;
  final bool selected;
  final String type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = type == 'income' ? colors.income : colors.expense;
    final soft = type == 'income' ? colors.primarySoft : colors.expenseSoft;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? soft : colors.surface,
          border: Border.all(color: selected ? accent : colors.border),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          category.name,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: selected ? accent : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
