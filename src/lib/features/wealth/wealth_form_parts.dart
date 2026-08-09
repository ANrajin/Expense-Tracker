import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme/app_theme.dart';

/// The pieces the three wealth forms share, matching the private helpers in
/// `transaction_form_screen.dart` — kept public and in one place here so the
/// asset, investment and lending/borrowing forms don't each re-declare them.

/// Back arrow, title, and a Save action that dims until the form is valid.
class FormHeader extends StatelessWidget {
  const FormHeader({
    super.key,
    required this.title,
    required this.canSave,
    required this.onSave,
  });

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

/// Back arrow and a title, for pushed screens with no save action.
class PlainHeader extends StatelessWidget {
  const PlainHeader({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

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
          ?action,
        ],
      ),
    );
  }
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

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

InputDecoration formInputDecoration(AppColors colors, {required String hint}) {
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

/// Rounded pill for picking one of a short, fixed set of options — the same
/// shape the transaction form uses for categories.
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.accent,
    required this.soft,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final Color soft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
          label,
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

/// Tappable date field. [onClear] adds a clear affordance, for the optional
/// due date.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.date,
    required this.onTap,
    this.placeholder = 'Select date',
    this.onClear,
  });

  final DateTime? date;
  final VoidCallback onTap;
  final String placeholder;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                date != null ? shortDateLabel(date!) : placeholder,
                style: TextStyle(
                  fontSize: 14,
                  color: date != null ? colors.textPrimary : colors.textSecondary,
                ),
              ),
            ),
            if (date != null && onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 4),
                  child: Icon(Icons.close_rounded,
                      size: 16, color: colors.textSecondary),
                ),
              ),
            Icon(Icons.calendar_today_rounded,
                size: 16, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// Full-width outlined destructive action, matching the transaction form's
/// delete button.
class DeleteButton extends StatelessWidget {
  const DeleteButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colors.expense),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: colors.expense,
          ),
        ),
      ),
    );
  }
}

/// Text an amount field starts with — whole taka show without a trailing `.0`.
String trimAmount(double amount) {
  return amount == amount.roundToDouble()
      ? amount.toStringAsFixed(0)
      : amount.toString();
}

/// Plain yes/no confirmation naming what is about to be deleted. Deliberately
/// lighter than Data Management's type-DELETE gate: this destroys one record
/// the user is looking at, not a whole period of history (specs.md §8).
Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final colors = context.colors;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: colors.surface,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
        ),
      ),
      content: Text(
        message,
        style: TextStyle(fontSize: 13.5, color: colors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            'Delete',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colors.expense,
            ),
          ),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
