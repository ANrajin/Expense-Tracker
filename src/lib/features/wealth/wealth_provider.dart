import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/asset.dart';
import '../../data/models/investment.dart';
import '../../data/models/loan.dart';
import '../../data/models/repayment.dart';
import 'assets_provider.dart';
import 'investments_provider.dart';
import 'loans_provider.dart';

/// The four figures Net Worth is built from, plus the invested cost, which the
/// Wealth screen shows alongside current value so a gain/loss reads in context.
class WealthTotals {
  const WealthTotals({
    required this.assets,
    required this.investmentValue,
    required this.investedCost,
    required this.lentOutstanding,
    required this.borrowedOutstanding,
  });

  final double assets;
  final double investmentValue;
  final double investedCost;
  final double lentOutstanding;
  final double borrowedOutstanding;

  /// Deliberately independent of the income/expense ledger: `calculateBalance`
  /// and the Dashboard's Total Balance card are untouched by this feature, and
  /// this figure never appears outside the Wealth area (specs.md §3, §8).
  ///
  /// Investments count at their current value, not what they cost. Settled
  /// entries contribute nothing, since their outstanding is zero.
  double get netWorth =>
      assets + investmentValue + lentOutstanding - borrowedOutstanding;

  double get gainLossOnInvestments => investmentValue - investedCost;
}

WealthTotals calculateWealthTotals({
  required List<Asset> assets,
  required List<Investment> investments,
  required List<Loan> loans,
  required List<Repayment> repayments,
}) {
  return WealthTotals(
    assets: totalAssets(assets),
    investmentValue: totalInvestmentValue(investments),
    investedCost: totalInvested(investments),
    lentOutstanding: totalOutstanding(
      buildLoanSummaries(loans, repayments, direction: loanLent),
    ),
    borrowedOutstanding: totalOutstanding(
      buildLoanSummaries(loans, repayments, direction: loanBorrowed),
    ),
  );
}

final wealthTotalsProvider = Provider<WealthTotals>((ref) {
  return calculateWealthTotals(
    assets: ref.watch(assetsProvider),
    investments: ref.watch(investmentsProvider),
    loans: ref.watch(loansProvider),
    repayments: ref.watch(repaymentsProvider),
  );
});
