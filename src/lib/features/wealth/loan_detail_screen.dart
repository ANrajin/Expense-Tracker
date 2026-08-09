import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/wealth_row.dart';
import '../../data/models/repayment.dart';
import 'loan_form_screen.dart';
import 'loans_provider.dart';
import 'wealth_form_parts.dart';

/// One lending or borrowing entry: what is still owed, the repayments logged
/// against it, and the actions to log another, edit, or delete.
class LoanDetailScreen extends ConsumerWidget {
  const LoanDetailScreen({super.key, required this.loanId});

  final String loanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final summary = ref.watch(loanSummaryProvider(loanId));

    // The entry has been deleted from under us (the delete action pops, but a
    // rebuild can land first) — render nothing rather than crash.
    if (summary == null) return Scaffold(backgroundColor: colors.background);

    final loan = summary.loan;
    final repayments = ref.watch(repaymentsForLoanProvider(loanId));
    final isLent = loan.isLent;
    final accent = isLent ? colors.income : colors.expense;
    final overdue = summary.isOverdue(DateTime.now());

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            PlainHeader(
              title: isLent ? 'Money Lent' : 'Money Borrowed',
              action: IconButton(
                tooltip: 'Edit',
                icon: Icon(Icons.edit_rounded, size: 20, color: colors.textPrimary),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => LoanFormScreen(loan: loan)),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      color: summary.settled
                          ? colors.chipBg
                          : (isLent ? colors.primarySoft : colors.expenseSoft),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                loan.personName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                            if (summary.settled)
                              WealthBadge(
                                label: 'Settled',
                                background: colors.surface,
                                foreground: colors.textSecondary,
                              )
                            else if (overdue)
                              WealthBadge(
                                label: 'Overdue',
                                background: colors.expenseSoft,
                                foreground: colors.expense,
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          summary.settled ? 'Nothing outstanding' : 'Outstanding',
                          style: TextStyle(
                              fontSize: 12, color: colors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          fmtBDT(summary.outstanding),
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: summary.settled
                                ? colors.textSecondary
                                : accent,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _Stat(
                              label: isLent ? 'Lent' : 'Borrowed',
                              value: fmtBDT(loan.amount),
                            ),
                            const SizedBox(width: 24),
                            _Stat(
                              label: 'Repaid',
                              value: fmtBDT(summary.repaid),
                            ),
                            const SizedBox(width: 24),
                            _Stat(
                              label: 'Date',
                              value: shortDateLabel(loan.dateTime),
                            ),
                          ],
                        ),
                        if (loan.hasDueDate) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Due ${shortDateLabel(loan.dueDateTime!)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: overdue
                                  ? colors.expense
                                  : colors.textSecondary,
                            ),
                          ),
                        ],
                        if (loan.note.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            loan.note,
                            style: TextStyle(
                                fontSize: 12.5, color: colors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (!summary.settled)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _logRepayment(
                          context,
                          ref,
                          loanId: loanId,
                          outstanding: summary.outstanding,
                        ),
                        child: const Text(
                          'Log repayment',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        border: Border.all(color: colors.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Fully repaid. Delete a repayment below to reopen this '
                        'entry.',
                        style: TextStyle(
                            fontSize: 12.5, color: colors.textSecondary),
                      ),
                    ),
                  const SizedBox(height: 18),
                  Text(
                    'REPAYMENTS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (repayments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No repayments logged yet.',
                        style: TextStyle(
                            fontSize: 13, color: colors.textSecondary),
                      ),
                    )
                  else
                    for (final repayment in repayments)
                      _RepaymentRow(repayment: repayment),
                  const SizedBox(height: 20),
                  DeleteButton(
                    label: isLent ? 'Delete Entry' : 'Delete Entry',
                    onPressed: () => _deleteLoan(
                      context,
                      ref,
                      loanId: loanId,
                      personName: loan.personName,
                      repaymentCount: repayments.length,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Deletes the entry and its repayment history. The cascade lives here rather
/// than inside a notifier so neither notifier has to hold a `Ref` to the other;
/// repayments go first, so an interruption leaves an entry with a stale
/// repayment rather than orphan rows with no entry.
Future<void> _deleteLoan(
  BuildContext context,
  WidgetRef ref, {
  required String loanId,
  required String personName,
  required int repaymentCount,
}) async {
  final confirmed = await confirmDelete(
    context,
    title: 'Delete entry',
    message: repaymentCount == 0
        ? 'Delete the entry for $personName? This is permanent — there is no '
            'undo.'
        : 'Delete the entry for $personName and its $repaymentCount logged '
            'repayment${repaymentCount == 1 ? '' : 's'}? This is permanent — '
            'there is no undo.',
  );
  if (!confirmed) return;

  final ids = repaymentIdsForLoan(ref.read(repaymentsProvider), loanId);
  await ref.read(repaymentsProvider.notifier).deleteRepayments(ids);
  await ref.read(loansProvider.notifier).deleteLoan(loanId);
  if (context.mounted) Navigator.of(context).pop();
}

Future<void> _logRepayment(
  BuildContext context,
  WidgetRef ref, {
  required String loanId,
  required double outstanding,
}) async {
  final result = await showDialog<_RepaymentDraft>(
    context: context,
    builder: (_) => _RepaymentDialog(outstanding: outstanding),
  );
  if (result == null) return;

  await ref.read(repaymentsProvider.notifier).addRepayment(
        loanId: loanId,
        amount: result.amount,
        date: toIsoDate(result.date),
        outstanding: outstanding,
      );
}

class _RepaymentDraft {
  const _RepaymentDraft({required this.amount, required this.date});

  final double amount;
  final DateTime date;
}

class _RepaymentDialog extends StatefulWidget {
  const _RepaymentDialog({required this.outstanding});

  final double outstanding;

  @override
  State<_RepaymentDialog> createState() => _RepaymentDialogState();
}

class _RepaymentDialogState extends State<_RepaymentDialog> {
  final _amountController = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double? get _parsedAmount => double.tryParse(_amountController.text);

  bool get _canSave => isValidRepaymentInput(
        amount: _parsedAmount,
        date: toIsoDate(_date),
        outstanding: widget.outstanding,
      );

  bool get _exceedsOutstanding =>
      _parsedAmount != null && _parsedAmount! > widget.outstanding;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AlertDialog(
      backgroundColor: colors.surface,
      title: Text(
        'Log repayment',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${fmtBDT(widget.outstanding)} still outstanding.',
            style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
          ),
          const SizedBox(height: 14),
          const FieldLabel('Amount (৳)'),
          const SizedBox(height: 6),
          TextField(
            controller: _amountController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
            decoration: formInputDecoration(
              colors,
              hint: trimAmount(widget.outstanding),
            ),
          ),
          if (_exceedsOutstanding) ...[
            const SizedBox(height: 6),
            Text(
              'More than is outstanding.',
              style: TextStyle(fontSize: 11.5, color: colors.expense),
            ),
          ],
          const SizedBox(height: 14),
          const FieldLabel('Date'),
          const SizedBox(height: 6),
          DateField(date: _date, onTap: _pickDate),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
        ),
        TextButton(
          onPressed: _canSave
              ? () => Navigator.of(context).pop(
                    _RepaymentDraft(amount: _parsedAmount!, date: _date),
                  )
              : null,
          child: Opacity(
            opacity: _canSave ? 1 : 0.4,
            child: Text(
              'Save',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RepaymentRow extends ConsumerWidget {
  const _RepaymentRow({required this.repayment});

  final Repayment repayment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              fmtBDT(repayment.amount),
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ),
          Text(
            shortDateLabel(repayment.dateTime),
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          IconButton(
            tooltip: 'Delete repayment',
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close_rounded, size: 18, color: colors.textSecondary),
            onPressed: () async {
              final confirmed = await confirmDelete(
                context,
                title: 'Delete repayment',
                message:
                    'Remove this ${fmtBDT(repayment.amount)} repayment? The '
                    'outstanding amount goes back up.',
              );
              if (!confirmed) return;
              await ref
                  .read(repaymentsProvider.notifier)
                  .deleteRepayment(repayment.id);
            },
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: colors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
