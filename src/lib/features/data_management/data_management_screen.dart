import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../transactions/transactions_provider.dart';
import 'data_management_provider.dart';

String _countLabel(int count) =>
    '$count transaction${count == 1 ? '' : 's'}';

/// Permanent deletion of transaction history by month, by year, or all at
/// once. Reached from the app's navigation drawer.
class DataManagementScreen extends ConsumerWidget {
  const DataManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final periods = ref.watch(deletionPeriodsProvider);
    final total = ref.watch(transactionCountProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                children: [
                  Text(
                    'Deleting history is permanent — there is no undo, and no '
                    'backup exists on the device. Only transactions are removed '
                    'here: categories and everything on the Wealth tab are left '
                    'untouched.',
                    style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  _AllHistoryCard(total: total),
                  const SizedBox(height: 18),
                  if (periods.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No transactions to manage.',
                        style:
                            TextStyle(fontSize: 13, color: colors.textSecondary),
                      ),
                    )
                  else
                    for (final period in periods) _YearCard(period: period),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

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
              'Data Management',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllHistoryCard extends ConsumerWidget {
  const _AllHistoryCard({required this.total});

  final int total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All history',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  _countLabel(total),
                  style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          _DeleteButton(
            label: 'Delete all',
            enabled: total > 0,
            onPressed: () => _confirmAndDelete(
              context,
              ref,
              const DeletionScope.allHistory(),
            ),
          ),
        ],
      ),
    );
  }
}

class _YearCard extends ConsumerWidget {
  const _YearCard({required this.period});

  final YearPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      period.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      _countLabel(period.count),
                      style: TextStyle(
                          fontSize: 11.5, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              _DeleteButton(
                label: 'Delete year',
                enabled: period.count > 0,
                onPressed: () =>
                    _confirmAndDelete(context, ref, period.scope),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final month in period.months) _MonthRow(month: month),
        ],
      ),
    );
  }
}

class _MonthRow extends ConsumerWidget {
  const _MonthRow({required this.month});

  final MonthPeriod month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  month.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  _countLabel(month.count),
                  style: TextStyle(fontSize: 11, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: month.count > 0
                ? () => _confirmAndDelete(context, ref, month.scope)
                : null,
            tooltip: 'Delete ${month.label}',
            icon: Icon(Icons.delete_outline_rounded,
                color: colors.expense, size: 20),
            constraints: const BoxConstraints(),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: enabled ? colors.expense : colors.border,
        ),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: enabled ? colors.expense : colors.textSecondary,
        ),
      ),
    );
  }
}

/// Confirms [scope] with the type-DELETE dialog, then permanently removes the
/// transactions it covers. The count shown is resolved when the dialog opens.
Future<void> _confirmAndDelete(
  BuildContext context,
  WidgetRef ref,
  DeletionScope scope,
) async {
  final ids = transactionIdsInScope(ref.read(transactionsProvider), scope);
  if (ids.isEmpty) return;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => _ConfirmDeleteDialog(scope: scope, count: ids.length),
  );
  if (confirmed != true) return;

  await ref.read(transactionsProvider.notifier).deleteTransactions(ids);
}

class _ConfirmDeleteDialog extends StatefulWidget {
  const _ConfirmDeleteDialog({required this.scope, required this.count});

  final DeletionScope scope;
  final int count;

  @override
  State<_ConfirmDeleteDialog> createState() => _ConfirmDeleteDialogState();
}

class _ConfirmDeleteDialogState extends State<_ConfirmDeleteDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final canDelete = isDeleteConfirmed(_controller.text);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: colors.border),
    );

    return AlertDialog(
      backgroundColor: colors.surface,
      title: Text(
        'Delete ${widget.scope.label}?',
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
            'This permanently deletes ${_countLabel(widget.count)} in '
            '${widget.scope.label}. There is no undo.',
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
          const SizedBox(height: 14),
          Text(
            'Type DELETE to confirm',
            style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _controller,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            style: TextStyle(fontSize: 14, color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: 'DELETE',
              hintStyle: TextStyle(color: colors.textSecondary),
              filled: true,
              fillColor: colors.background,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: border,
              enabledBorder: border,
              focusedBorder: border.copyWith(
                borderSide: BorderSide(color: colors.expense),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: canDelete ? () => Navigator.of(context).pop(true) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.expense,
            disabledBackgroundColor: colors.expense.withValues(alpha: 0.35),
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Delete',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
