import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/loan.dart';
import 'loans_provider.dart';
import 'wealth_form_parts.dart';

/// Add/edit a lending or borrowing entry. Pass [loan] to edit an existing one,
/// or [direction] to create a new one — direction is fixed once created, since
/// flipping it would silently reinterpret every repayment logged against it.
class LoanFormScreen extends ConsumerStatefulWidget {
  const LoanFormScreen({super.key, this.loan, this.direction});

  final Loan? loan;
  final String? direction;

  @override
  ConsumerState<LoanFormScreen> createState() => _LoanFormScreenState();
}

class _LoanFormScreenState extends ConsumerState<LoanFormScreen> {
  late String _direction;
  late final TextEditingController _personController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  DateTime? _date;
  DateTime? _dueDate;

  bool get _isEditing => widget.loan != null;

  @override
  void initState() {
    super.initState();
    final loan = widget.loan;
    _direction = loan?.direction ?? widget.direction ?? loanLent;
    _personController = TextEditingController(text: loan?.personName ?? '');
    _amountController = TextEditingController(
      text: loan != null ? trimAmount(loan.amount) : '',
    );
    _noteController = TextEditingController(text: loan?.note ?? '');
    _date = loan != null ? DateTime.parse(loan.date) : DateTime.now();
    _dueDate = loan?.dueDateTime;
  }

  @override
  void dispose() {
    _personController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _isLent => _direction == loanLent;

  double? get _parsedAmount => double.tryParse(_amountController.text);

  String get _dueDateIso => _dueDate != null ? toIsoDate(_dueDate!) : '';

  bool get _canSave => isValidLoanInput(
        personName: _personController.text,
        amount: _parsedAmount,
        date: _date != null ? toIsoDate(_date!) : null,
        dueDate: _dueDateIso,
      );

  Future<void> _pickDate({required bool isDueDate}) async {
    final initial = isDueDate ? (_dueDate ?? _date ?? DateTime.now()) : (_date ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isDueDate) {
        _dueDate = picked;
      } else {
        _date = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final notifier = ref.read(loansProvider.notifier);
    final dateIso = toIsoDate(_date!);
    final ok = _isEditing
        ? await notifier.updateLoan(
            widget.loan!.id,
            personName: _personController.text,
            amount: _parsedAmount!,
            date: dateIso,
            dueDate: _dueDateIso,
            note: _noteController.text,
          )
        : await notifier.addLoan(
            direction: _direction,
            personName: _personController.text,
            amount: _parsedAmount!,
            date: dateIso,
            dueDate: _dueDateIso,
            note: _noteController.text,
          );
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = _isLent ? colors.income : colors.expense;
    final title = _isEditing
        ? (_isLent ? 'Edit Money Lent' : 'Edit Money Borrowed')
        : (_isLent ? 'Lend Money' : 'Borrow Money');
    final dueBeforeDate = _dueDate != null &&
        _date != null &&
        _dueDateIso.compareTo(toIsoDate(_date!)) < 0;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            FormHeader(title: title, canSave: _canSave, onSave: _save),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Direction is only choosable while creating — see the class
                    // doc comment.
                    if (!_isEditing) ...[
                      _DirectionToggle(
                        direction: _direction,
                        onChanged: (d) => setState(() => _direction = d),
                      ),
                      const SizedBox(height: 18),
                    ],
                    FieldLabel(_isLent ? 'Lent to' : 'Borrowed from'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _personController,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(fontSize: 14, color: colors.textPrimary),
                      decoration: formInputDecoration(
                        colors,
                        hint: "Person's name",
                      ),
                    ),
                    const SizedBox(height: 18),
                    const FieldLabel('Amount (৳)'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                      decoration: formInputDecoration(colors, hint: '0'),
                    ),
                    const SizedBox(height: 18),
                    const FieldLabel('Date'),
                    const SizedBox(height: 6),
                    DateField(
                      date: _date,
                      onTap: () => _pickDate(isDueDate: false),
                    ),
                    const SizedBox(height: 18),
                    const FieldLabel('Due date (optional)'),
                    const SizedBox(height: 6),
                    DateField(
                      date: _dueDate,
                      placeholder: 'No due date',
                      onTap: () => _pickDate(isDueDate: true),
                      onClear: () => setState(() => _dueDate = null),
                    ),
                    if (dueBeforeDate) ...[
                      const SizedBox(height: 6),
                      Text(
                        'The due date cannot be before the date the money '
                        'changed hands.',
                        style: TextStyle(fontSize: 11.5, color: colors.expense),
                      ),
                    ],
                    const SizedBox(height: 18),
                    const FieldLabel('Note (optional)'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _noteController,
                      style: TextStyle(fontSize: 14, color: colors.textPrimary),
                      decoration:
                          formInputDecoration(colors, hint: 'Add a note'),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Repayments are logged from the entry itself, once saved.',
                      style: TextStyle(
                          fontSize: 11.5, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectionToggle extends StatelessWidget {
  const _DirectionToggle({required this.direction, required this.onChanged});

  final String direction;
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
              label: 'I lent',
              selected: direction == loanLent,
              selectedBg: colors.primarySoft,
              selectedColor: colors.income,
              onTap: () => onChanged(loanLent),
            ),
          ),
          Expanded(
            child: _segment(
              context,
              label: 'I borrowed',
              selected: direction == loanBorrowed,
              selectedBg: colors.expenseSoft,
              selectedColor: colors.expense,
              onTap: () => onChanged(loanBorrowed),
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
