import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/transaction_row.dart';
import '../categories/categories_provider.dart';
import 'history_provider.dart';
import 'transaction_form_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final ym = ref.watch(historyMonthProvider);
    final groups = ref.watch(historyGroupsProvider);
    final categories = ref.watch(categoriesProvider);

    String categoryNameFor(String id) {
      for (final c in categories) {
        if (c.id == id) return c.name;
      }
      return 'Other';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ScreenHeader(title: 'History'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => ref.read(historyMonthProvider.notifier).state =
                      ym.shift(-1),
                  icon: Icon(Icons.chevron_left_rounded, color: colors.textPrimary),
                ),
                Text(
                  monthLabel(ym.year, ym.month),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => ref.read(historyMonthProvider.notifier).state =
                      ym.shift(1),
                  icon: Icon(Icons.chevron_right_rounded, color: colors.textPrimary),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: groups.isEmpty
              ? Center(
                  child: Text(
                    'No transactions this month.',
                    style: TextStyle(fontSize: 13, color: colors.textSecondary),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                  children: [
                    for (final group in groups) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          dayGroupLabel(group.date),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colors.textSecondary,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      for (final tx in group.transactions)
                        TransactionRow(
                          transaction: tx,
                          categoryName: categoryNameFor(tx.categoryId),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  TransactionFormScreen(transaction: tx),
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}
