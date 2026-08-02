import 'package:flutter/material.dart';

import '../format.dart';
import '../theme/app_theme.dart';
import '../../data/models/transaction.dart';

class TransactionRow extends StatelessWidget {
  const TransactionRow({
    super.key,
    required this.transaction,
    required this.categoryName,
    this.onTap,
    this.dateLabel,
  });

  final Transaction transaction;
  final String categoryName;
  final VoidCallback? onTap;
  final String? dateLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isIncome = transaction.isIncome;
    final accent = isIncome ? colors.income : colors.expense;
    final iconBg = isIncome ? colors.primarySoft : colors.expenseSoft;
    final amountLabel =
        (isIncome ? '+' : '-') + fmtBDT(transaction.amount);
    final initial = categoryName.isNotEmpty ? categoryName[0] : '?';

    final row = Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Text(
            initial,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                categoryName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              if (transaction.note.isNotEmpty)
                Text(
                  transaction.note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              amountLabel,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
            Text(
              dateLabel ?? shortDateLabel(transaction.dateTime),
              style: TextStyle(fontSize: 11, color: colors.textSecondary),
            ),
          ],
        ),
      ],
    );

    final content = Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: row,
    );

    if (onTap == null) return content;
    return InkWell(onTap: onTap, child: content);
  }
}
