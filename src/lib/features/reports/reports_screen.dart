import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/screen_header.dart';
import 'report_charts.dart';
import 'reports_provider.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final ym = ref.watch(reportMonthProvider);
    final totals = ref.watch(reportTotalsProvider);
    final breakdown = ref.watch(expenseBreakdownProvider);
    final trend = ref.watch(trendProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ScreenHeader(title: 'Reports'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              Container(
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
                      onPressed: () =>
                          ref.read(reportMonthProvider.notifier).state =
                              ym.shift(-1),
                      icon: Icon(Icons.chevron_left_rounded,
                          color: colors.textPrimary),
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
                      onPressed: () =>
                          ref.read(reportMonthProvider.notifier).state =
                              ym.shift(1),
                      icon: Icon(Icons.chevron_right_rounded,
                          color: colors.textPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Income',
                      value: fmtBDT(totals.income),
                      valueColor: colors.income,
                      background: colors.surface,
                      border: colors.border,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      label: 'Expense',
                      value: fmtBDT(totals.expense),
                      valueColor: colors.expense,
                      background: colors.surface,
                      border: colors.border,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      label: 'Net',
                      value: fmtBDT(totals.net),
                      valueColor: colors.textPrimary,
                      background: colors.primarySoft,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Expense by Category',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              if (breakdown.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No expenses recorded this month.',
                    style: TextStyle(fontSize: 13, color: colors.textSecondary),
                  ),
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    DonutChart(segments: breakdown),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < breakdown.length; i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3.5),
                              child: Row(
                                children: [
                                  Container(
                                    width: 9,
                                    height: 9,
                                    decoration: BoxDecoration(
                                      color:
                                          donutPalette[i % donutPalette.length],
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      breakdown[i].name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 12, color: colors.textPrimary),
                                    ),
                                  ),
                                  Text(
                                    breakdown[i].percentLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              Text(
                'Income vs. Expense Trend',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TrendChart(
                months: trend,
                incomeColor: colors.income,
                expenseColor: colors.expense,
                labelColor: colors.textSecondary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.background,
    this.border,
  });

  final String label;
  final String value;
  final Color valueColor;
  final Color background;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: background,
        border: border != null ? Border.all(color: border!) : null,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10.5, color: colors.textSecondary),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
