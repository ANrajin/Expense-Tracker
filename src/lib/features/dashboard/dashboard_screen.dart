import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/transaction_row.dart';
import '../categories/categories_provider.dart';
import '../transactions/transaction_form_screen.dart';
import 'dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final balance = ref.watch(balanceProvider);
    final month = ref.watch(monthSummaryProvider);
    final recent = ref.watch(recentTransactionsProvider);
    final categories = ref.watch(categoriesProvider);

    String categoryNameFor(String id) {
      for (final c in categories) {
        if (c.id == id) return c.name;
      }
      return 'Other';
    }

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ScreenHeader(title: 'Overview'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      color: colors.primarySoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Balance',
                          style: TextStyle(
                              fontSize: 12, color: colors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          fmtBDT(balance),
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          label: 'Income (month)',
                          amount: month.income,
                          dotColor: colors.income,
                          textColor: colors.income,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SummaryCard(
                          label: 'Expense (month)',
                          amount: month.expense,
                          dotColor: colors.expense,
                          textColor: colors.expense,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Activity',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            ref.read(activeTabProvider.notifier).state = 1,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'View all',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (recent.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No transactions yet.',
                        style:
                            TextStyle(fontSize: 13, color: colors.textSecondary),
                      ),
                    )
                  else
                    for (final tx in recent)
                      TransactionRow(
                        transaction: tx,
                        categoryName: categoryNameFor(tx.categoryId),
                      ),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          right: 18,
          bottom: 16,
          child: FloatingActionButton(
            backgroundColor: colors.primary,
            foregroundColor: Colors.white,
            elevation: 4,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TransactionFormScreen()),
            ),
            child: const Icon(Icons.add_rounded, size: 28),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.dotColor,
    required this.textColor,
  });

  final String label;
  final double amount;
  final Color dotColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 11, color: colors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            fmtBDT(amount),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
