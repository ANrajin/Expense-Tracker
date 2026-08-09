import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/wealth_row.dart';
import 'asset_form_screen.dart';
import 'assets_provider.dart';
import 'investment_form_screen.dart';
import 'investments_provider.dart';
import 'loan_detail_screen.dart';
import 'loan_form_screen.dart';
import 'loans_provider.dart';
import 'wealth_provider.dart';

/// Everything the user owns and owes, in one scroll: net worth, then the four
/// sections it is built from. Deliberately not a segmented control — the whole
/// question this screen answers is "where do I stand overall", which wants
/// every figure visible at once.
class WealthScreen extends ConsumerWidget {
  const WealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final totals = ref.watch(wealthTotalsProvider);
    final assets = ref.watch(sortedAssetsProvider);
    final investments = ref.watch(sortedInvestmentsProvider);
    final lent = ref.watch(lentSummariesProvider);
    final borrowed = ref.watch(borrowedSummariesProvider);
    final today = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ScreenHeader(title: 'Wealth'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              _NetWorthCard(totals: totals),
              const SizedBox(height: 18),

              _SectionHeader(
                label: 'Assets',
                total: totals.assets,
                onAdd: () => _push(context, const AssetFormScreen()),
              ),
              if (assets.isEmpty)
                const _EmptySection(
                  message: 'Cash, bank and mobile-wallet balances you keep up '
                      'to date yourself.',
                )
              else
                for (final asset in assets)
                  WealthRow(
                    title: asset.name,
                    subtitle: assetKindLabel(asset.kind),
                    amountLabel: fmtBDT(asset.amount),
                    accent: colors.textPrimary,
                    metaLabel: shortDateLabel(asset.asOfDateTime),
                    onTap: () =>
                        _push(context, AssetFormScreen(asset: asset)),
                  ),
              const SizedBox(height: 20),

              _SectionHeader(
                label: 'Investments',
                total: totals.investmentValue,
                onAdd: () => _push(context, const InvestmentFormScreen()),
              ),
              if (investments.isEmpty)
                const _EmptySection(
                  message: 'Stocks, DPS, FDR, gold or crypto — you set the '
                      'current value, the app works out the gain or loss.',
                )
              else ...[
                for (final investment in investments)
                  Builder(builder: (context) {
                    final gainLoss = investmentGainLoss(investment);
                    final percent = gainLoss.percent;
                    final gainColor =
                        gainLoss.isLoss ? colors.expense : colors.income;
                    final sign = gainLoss.amount > 0 ? '+' : '';
                    return WealthRow(
                      title: investment.name,
                      subtitle:
                          '${investmentTypeLabel(investment.type)} · ${fmtBDT(investment.investedAmount)} invested',
                      amountLabel: fmtBDT(investment.currentValue),
                      accent: colors.textPrimary,
                      leadingBg: gainLoss.isLoss
                          ? colors.expenseSoft
                          : colors.primarySoft,
                      metaLabel: percent == null
                          ? '$sign${fmtBDT(gainLoss.amount)}'
                          : '$sign${fmtBDT(gainLoss.amount)} ($sign${percent.toStringAsFixed(1)}%)',
                      metaColor: gainColor,
                      onTap: () => _push(
                        context,
                        InvestmentFormScreen(investment: investment),
                      ),
                    );
                  }),
                _TotalFootnote(
                  label:
                      '${fmtBDT(totals.investedCost)} invested · ${totals.gainLossOnInvestments >= 0 ? '+' : ''}${fmtBDT(totals.gainLossOnInvestments)} overall',
                  color: totals.gainLossOnInvestments < 0
                      ? colors.expense
                      : colors.income,
                ),
              ],
              const SizedBox(height: 20),

              _SectionHeader(
                label: 'Money lent',
                total: totals.lentOutstanding,
                totalColor: colors.income,
                onAdd: () => _push(
                  context,
                  const LoanFormScreen(direction: loanLent),
                ),
              ),
              if (lent.isEmpty)
                const _EmptySection(
                  message: 'Money owed to you. Log repayments as they come in — '
                      'an entry settles itself once nothing is left.',
                )
              else
                for (final summary in lent)
                  _LoanRow(summary: summary, today: today),
              const SizedBox(height: 20),

              _SectionHeader(
                label: 'Money borrowed',
                total: totals.borrowedOutstanding,
                totalColor: colors.expense,
                onAdd: () => _push(
                  context,
                  const LoanFormScreen(direction: loanBorrowed),
                ),
              ),
              if (borrowed.isEmpty)
                const _EmptySection(
                  message: 'Money you owe. Log repayments as you make them — '
                      'an entry settles itself once nothing is left.',
                )
              else
                for (final summary in borrowed)
                  _LoanRow(summary: summary, today: today),
            ],
          ),
        ),
      ],
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _NetWorthCard extends StatelessWidget {
  const _NetWorthCard({required this.totals});

  final WealthTotals totals;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final negative = totals.netWorth < 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Net Worth',
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            fmtBDT(totals.netWorth),
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: negative ? colors.expense : colors.income,
            ),
          ),
          const SizedBox(height: 2),
          // Names the formula so this can't be mistaken for the Dashboard's
          // Total Balance, which stays all-time income minus expense.
          Text(
            'Assets + investments + money lent − money borrowed',
            style: TextStyle(fontSize: 11, color: colors.textSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Contribution(label: 'Assets', amount: totals.assets),
              _Contribution(label: 'Invested', amount: totals.investmentValue),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Contribution(
                label: 'Lent out',
                amount: totals.lentOutstanding,
                color: colors.income,
              ),
              _Contribution(
                label: 'Owed',
                amount: totals.borrowedOutstanding,
                color: colors.expense,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Contribution extends StatelessWidget {
  const _Contribution({required this.label, required this.amount, this.color});

  final String label;
  final double amount;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: colors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            fmtBDT(amount),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color ?? colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.total,
    required this.onAdd,
    this.totalColor,
  });

  final String label;
  final double total;
  final VoidCallback onAdd;
  final Color? totalColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colors.textSecondary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              fmtBDT(total),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: totalColor ?? colors.textPrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: onAdd,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              '+ Add',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Text(
        message,
        style: TextStyle(fontSize: 13, color: colors.textSecondary),
      ),
    );
  }
}

class _TotalFootnote extends StatelessWidget {
  const _TotalFootnote({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _LoanRow extends StatelessWidget {
  const _LoanRow({required this.summary, required this.today});

  final LoanSummary summary;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final loan = summary.loan;
    final overdue = summary.isOverdue(today);
    final accent = summary.settled
        ? colors.textSecondary
        : (loan.isLent ? colors.income : colors.expense);

    final subtitle = summary.settled
        ? 'Fully repaid · ${fmtBDT(loan.amount)}'
        : summary.repaid > 0
            ? '${fmtBDT(summary.repaid)} of ${fmtBDT(loan.amount)} repaid'
            : fmtBDT(loan.amount);

    return WealthRow(
      title: loan.personName,
      subtitle: subtitle,
      amountLabel: fmtBDT(summary.outstanding),
      accent: accent,
      leadingBg: summary.settled
          ? colors.chipBg
          : (loan.isLent ? colors.primarySoft : colors.expenseSoft),
      metaLabel: loan.hasDueDate
          ? 'Due ${shortDateLabel(loan.dueDateTime!)}'
          : shortDateLabel(loan.dateTime),
      metaColor: overdue ? colors.expense : null,
      trailingBadge: summary.settled
          ? WealthBadge(
              label: 'Settled',
              background: colors.chipBg,
              foreground: colors.textSecondary,
            )
          : overdue
              ? WealthBadge(
                  label: 'Overdue',
                  background: colors.expenseSoft,
                  foreground: colors.expense,
                )
              : null,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LoanDetailScreen(loanId: loan.id)),
      ),
    );
  }
}
