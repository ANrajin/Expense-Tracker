// Feature-level tests: balance calculation, month filtering (History),
// the category delete guard, transaction form validation, the Data
// Management period grouping / delete confirmation, and Wealth Tracking
// (asset and investment validation, gain/loss, repayment tracking and
// settlement, loan listing order, and the net worth figure). These are
// plain-Dart tests against the pure functions each provider wraps, so no Hive
// or ProviderContainer setup is needed.

import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/data/models/asset.dart';
import 'package:expense_tracker/data/models/investment.dart';
import 'package:expense_tracker/data/models/loan.dart';
import 'package:expense_tracker/data/models/repayment.dart';
import 'package:expense_tracker/data/models/transaction.dart';
import 'package:expense_tracker/features/categories/categories_provider.dart';
import 'package:expense_tracker/features/dashboard/dashboard_provider.dart';
import 'package:expense_tracker/features/data_management/data_management_provider.dart';
import 'package:expense_tracker/features/transactions/history_provider.dart';
import 'package:expense_tracker/features/transactions/transactions_provider.dart';
import 'package:expense_tracker/features/wealth/assets_provider.dart';
import 'package:expense_tracker/features/wealth/investments_provider.dart';
import 'package:expense_tracker/features/wealth/loans_provider.dart';
import 'package:expense_tracker/features/wealth/wealth_provider.dart';

Transaction _tx({
  required String id,
  required String type,
  required String categoryId,
  required double amount,
  required String date,
}) {
  return Transaction(
    id: id,
    type: type,
    categoryId: categoryId,
    amount: amount,
    date: date,
  );
}

Asset _asset({
  required String id,
  required String name,
  required double amount,
  String kind = 'cash',
}) {
  return Asset(
    id: id,
    name: name,
    kind: kind,
    amount: amount,
    asOfDate: '2026-08-09',
  );
}

Investment _investment({
  required String id,
  required String name,
  required double invested,
  required double current,
  String type = 'stock',
  String date = '2026-01-15',
}) {
  return Investment(
    id: id,
    name: name,
    type: type,
    investedAmount: invested,
    currentValue: current,
    date: date,
    valuedDate: date,
  );
}

Loan _loan({
  required String id,
  required String direction,
  required String person,
  required double amount,
  String date = '2026-06-01',
  String dueDate = '',
}) {
  return Loan(
    id: id,
    direction: direction,
    personName: person,
    amount: amount,
    date: date,
    dueDate: dueDate,
  );
}

Repayment _rp({
  required String id,
  required String loanId,
  required double amount,
  String date = '2026-07-01',
}) {
  return Repayment(id: id, loanId: loanId, amount: amount, date: date);
}

void main() {
  group('isValidTransactionInput (form validation)', () {
    test('rejects zero or negative amounts', () {
      expect(
        isValidTransactionInput(amount: 0, categoryId: 'food', date: '2026-08-01'),
        isFalse,
      );
      expect(
        isValidTransactionInput(amount: -5, categoryId: 'food', date: '2026-08-01'),
        isFalse,
      );
    });

    test('rejects missing category or date', () {
      expect(
        isValidTransactionInput(amount: 100, categoryId: null, date: '2026-08-01'),
        isFalse,
      );
      expect(
        isValidTransactionInput(amount: 100, categoryId: 'food', date: null),
        isFalse,
      );
    });

    test('accepts a positive amount with category and date', () {
      expect(
        isValidTransactionInput(amount: 100, categoryId: 'food', date: '2026-08-01'),
        isTrue,
      );
    });
  });

  group('canDeleteCategory (delete guard)', () {
    test('blocks default categories regardless of usage', () {
      expect(canDeleteCategory(isDefault: true, transactionCount: 0), isFalse);
    });

    test('blocks non-default categories that still have transactions', () {
      expect(canDeleteCategory(isDefault: false, transactionCount: 2), isFalse);
    });

    test('allows non-default categories with zero transactions', () {
      expect(canDeleteCategory(isDefault: false, transactionCount: 0), isTrue);
    });
  });

  group('calculateBalance', () {
    test('sums income minus expense across all transactions', () {
      final balance = calculateBalance([
        _tx(id: '1', type: 'income', categoryId: 'salary', amount: 1000, date: '2026-01-01'),
        _tx(id: '2', type: 'expense', categoryId: 'food', amount: 300, date: '2026-01-02'),
        _tx(id: '3', type: 'expense', categoryId: 'food', amount: 50, date: '2026-06-15'),
      ]);
      expect(balance, 650);
    });

    test('an empty list has zero balance', () {
      expect(calculateBalance([]), 0);
    });
  });

  group('calculateMonthSummary', () {
    test('only totals transactions in the given month', () {
      final summary = calculateMonthSummary([
        _tx(id: '1', type: 'income', categoryId: 'salary', amount: 5000, date: '2026-08-01'),
        _tx(id: '2', type: 'expense', categoryId: 'food', amount: 200, date: '2026-08-02'),
        _tx(id: '3', type: 'expense', categoryId: 'food', amount: 999, date: '2026-07-31'),
      ], DateTime(2026, 8));

      expect(summary.income, 5000);
      expect(summary.expense, 200);
    });
  });

  group('groupHistoryByDay (month filtering + day grouping)', () {
    test('filters to the selected month and groups same-day transactions', () {
      final groups = groupHistoryByDay([
        _tx(id: '1', type: 'expense', categoryId: 'food', amount: 100, date: '2026-03-05'),
        _tx(id: '2', type: 'expense', categoryId: 'food', amount: 50, date: '2026-03-05'),
        _tx(id: '3', type: 'income', categoryId: 'salary', amount: 2000, date: '2026-03-10'),
        // Outside the selected month — must not appear.
        _tx(id: '4', type: 'expense', categoryId: 'food', amount: 75, date: '2026-04-01'),
      ], const YearMonth(2026, 3));

      expect(groups, hasLength(2));
      expect(groups.first.date.day, 10); // newest day first
      expect(groups.last.date.day, 5);
      expect(groups.last.transactions, hasLength(2));
      expect(groups.last.transactions.every((t) => t.date == '2026-03-05'), isTrue);
    });

    test('an empty month produces no groups', () {
      expect(groupHistoryByDay([], const YearMonth(2026, 3)), isEmpty);
    });
  });

  group('buildDeletionPeriods (Data Management listing)', () {
    final transactions = [
      _tx(id: '1', type: 'expense', categoryId: 'food', amount: 100, date: '2026-03-05'),
      _tx(id: '2', type: 'expense', categoryId: 'food', amount: 50, date: '2026-03-20'),
      _tx(id: '3', type: 'income', categoryId: 'salary', amount: 2000, date: '2026-01-31'),
      _tx(id: '4', type: 'expense', categoryId: 'food', amount: 75, date: '2025-12-01'),
    ];

    test('lists only years and months that hold transactions, newest first', () {
      final periods = buildDeletionPeriods(transactions);

      expect(periods.map((p) => p.year), [2026, 2025]);
      expect(periods.first.months.map((m) => m.month), [3, 1]);
      expect(periods.last.months.map((m) => m.month), [12]);
    });

    test('counts transactions per month and per year', () {
      final periods = buildDeletionPeriods(transactions);

      expect(periods.first.count, 3);
      expect(periods.first.months.first.count, 2); // March 2026
      expect(periods.first.months.last.count, 1); // January 2026
      expect(periods.last.count, 1);
    });

    test('no transactions means no periods at all', () {
      expect(buildDeletionPeriods([]), isEmpty);
    });
  });

  group('transactionIdsInScope (what a confirmed delete removes)', () {
    final transactions = [
      _tx(id: '1', type: 'expense', categoryId: 'food', amount: 100, date: '2026-03-05'),
      _tx(id: '2', type: 'expense', categoryId: 'food', amount: 50, date: '2026-03-20'),
      _tx(id: '3', type: 'income', categoryId: 'salary', amount: 2000, date: '2026-01-31'),
      _tx(id: '4', type: 'expense', categoryId: 'food', amount: 75, date: '2025-12-01'),
    ];

    test('a month scope covers only that month', () {
      expect(
        transactionIdsInScope(transactions, const DeletionScope.month(2026, 3)),
        ['1', '2'],
      );
    });

    test('a year scope covers every month of that year', () {
      expect(
        transactionIdsInScope(transactions, const DeletionScope.year(2026)),
        ['1', '2', '3'],
      );
    });

    test('the all-history scope covers everything', () {
      expect(
        transactionIdsInScope(transactions, const DeletionScope.allHistory()),
        ['1', '2', '3', '4'],
      );
    });

    test('an empty period yields nothing to delete', () {
      expect(
        transactionIdsInScope(transactions, const DeletionScope.month(2026, 7)),
        isEmpty,
      );
    });

    test('scope labels state the exact period being deleted', () {
      expect(const DeletionScope.month(2026, 3).label, 'March 2026');
      expect(const DeletionScope.year(2026).label, '2026');
      expect(const DeletionScope.allHistory().label, 'all history');
    });
  });

  group('isDeleteConfirmed (type-to-confirm guard)', () {
    test('rejects anything other than DELETE', () {
      expect(isDeleteConfirmed(''), isFalse);
      expect(isDeleteConfirmed('delete'), isFalse);
      expect(isDeleteConfirmed('DELET'), isFalse);
      expect(isDeleteConfirmed('DELETE ALL'), isFalse);
    });

    test('accepts DELETE, ignoring surrounding whitespace', () {
      expect(isDeleteConfirmed('DELETE'), isTrue);
      expect(isDeleteConfirmed('  DELETE  '), isTrue);
    });
  });

  group('isValidAssetInput (asset form validation)', () {
    test('rejects a blank or whitespace-only name', () {
      expect(isValidAssetInput(name: '', amount: 500), isFalse);
      expect(isValidAssetInput(name: '   ', amount: 500), isFalse);
    });

    test('rejects a negative or missing amount', () {
      expect(isValidAssetInput(name: 'Wallet', amount: -1), isFalse);
      expect(isValidAssetInput(name: 'Wallet', amount: null), isFalse);
    });

    test('accepts a zero amount — a drained wallet is still a real balance', () {
      expect(isValidAssetInput(name: 'Wallet', amount: 0), isTrue);
    });

    test('accepts a named asset with a positive amount', () {
      expect(isValidAssetInput(name: 'City Bank', amount: 125000), isTrue);
    });
  });

  group('sortedAssets / totalAssets (assets section)', () {
    final assets = [
      _asset(id: 'a1', name: 'Wallet', amount: 3000),
      _asset(id: 'a2', name: 'City Bank', amount: 125000, kind: 'bank'),
      _asset(id: 'a3', name: 'bKash', amount: 3000, kind: 'mobile'),
    ];

    test('lists the largest balance first, then by name', () {
      expect(
        sortedAssets(assets).map((a) => a.id),
        ['a2', 'a3', 'a1'], // 125000, then the two 3000s as bKash before Wallet
      );
    });

    test('ordering does not depend on the order Hive hands rows back', () {
      final reversed = assets.reversed.toList();
      expect(
        sortedAssets(reversed).map((a) => a.id),
        sortedAssets(assets).map((a) => a.id),
      );
    });

    test('sums every asset, and an empty list totals zero', () {
      expect(totalAssets(assets), 131000);
      expect(totalAssets([]), 0);
    });
  });

  group('calculateGainLoss (investment gain/loss)', () {
    test('reports a gain in taka and percent', () {
      final gain = calculateGainLoss(investedAmount: 100000, currentValue: 130000);
      expect(gain.amount, 30000);
      expect(gain.percent, 30);
      expect(gain.isGain, isTrue);
      expect(gain.isLoss, isFalse);
    });

    test('reports a loss as negative in both figures', () {
      final loss = calculateGainLoss(investedAmount: 50000, currentValue: 40000);
      expect(loss.amount, -10000);
      expect(loss.percent, -20);
      expect(loss.isLoss, isTrue);
    });

    test('break-even is zero and zero percent, neither gain nor loss', () {
      final flat = calculateGainLoss(investedAmount: 50000, currentValue: 50000);
      expect(flat.amount, 0);
      expect(flat.percent, 0);
      expect(flat.isGain, isFalse);
      expect(flat.isLoss, isFalse);
    });

    test('a zero base yields a null percent, never Infinity or NaN', () {
      final none = calculateGainLoss(investedAmount: 0, currentValue: 500);
      expect(none.amount, 500);
      expect(none.percent, isNull);
    });
  });

  group('overallInvestmentGainLoss (investments section totals)', () {
    final investments = [
      _investment(id: 'i1', name: 'DSE fund', invested: 100000, current: 130000),
      _investment(id: 'i2', name: 'Gold', invested: 50000, current: 40000),
    ];

    test('nets gains against losses across every investment', () {
      expect(totalInvested(investments), 150000);
      expect(totalInvestmentValue(investments), 170000);

      final overall = overallInvestmentGainLoss(investments);
      expect(overall.amount, 20000);
      expect(overall.percent, closeTo(13.333, 0.001));
    });

    test('no investments means zero gain and no percent', () {
      final overall = overallInvestmentGainLoss([]);
      expect(overall.amount, 0);
      expect(overall.percent, isNull);
    });
  });

  group('isValidInvestmentInput (investment form validation)', () {
    test('rejects a zero or negative amount invested', () {
      expect(
        isValidInvestmentInput(
            name: 'Gold', investedAmount: 0, currentValue: 100, date: '2026-01-01'),
        isFalse,
      );
      expect(
        isValidInvestmentInput(
            name: 'Gold', investedAmount: -5, currentValue: 100, date: '2026-01-01'),
        isFalse,
      );
    });

    test('rejects a negative current value but accepts zero', () {
      expect(
        isValidInvestmentInput(
            name: 'Gold', investedAmount: 100, currentValue: -1, date: '2026-01-01'),
        isFalse,
      );
      expect(
        isValidInvestmentInput(
            name: 'Gold', investedAmount: 100, currentValue: 0, date: '2026-01-01'),
        isTrue,
      );
    });

    test('rejects a blank name or a missing date', () {
      expect(
        isValidInvestmentInput(
            name: '  ', investedAmount: 100, currentValue: 100, date: '2026-01-01'),
        isFalse,
      );
      expect(
        isValidInvestmentInput(
            name: 'Gold', investedAmount: 100, currentValue: 100, date: null),
        isFalse,
      );
    });
  });

  group('loanOutstanding / isLoanSettled (repayment tracking)', () {
    final loan = _loan(id: 'l1', direction: loanLent, person: 'Rafi', amount: 5000);

    test('with no repayments the full amount is outstanding', () {
      expect(loanOutstanding(loan, []), 5000);
      expect(isLoanSettled(loan, []), isFalse);
    });

    test('partial repayments reduce the outstanding amount but do not settle it', () {
      final repayments = [
        _rp(id: 'r1', loanId: 'l1', amount: 2000),
        _rp(id: 'r2', loanId: 'l1', amount: 2000),
      ];
      expect(totalRepaid(repayments, 'l1'), 4000);
      expect(loanOutstanding(loan, repayments), 1000);
      expect(isLoanSettled(loan, repayments), isFalse);
    });

    test('repayments adding up to the full amount settle the entry', () {
      final repayments = [
        _rp(id: 'r1', loanId: 'l1', amount: 2000),
        _rp(id: 'r2', loanId: 'l1', amount: 3000),
      ];
      expect(loanOutstanding(loan, repayments), 0);
      expect(isLoanSettled(loan, repayments), isTrue);
    });

    test('an uneven split settles despite floating-point residue', () {
      final thousand =
          _loan(id: 'l9', direction: loanLent, person: 'Nabil', amount: 1000);
      final repayments = [
        _rp(id: 'r1', loanId: 'l9', amount: 333.33),
        _rp(id: 'r2', loanId: 'l9', amount: 333.33),
        _rp(id: 'r3', loanId: 'l9', amount: 333.34),
      ];
      expect(isLoanSettled(thousand, repayments), isTrue);
    });

    test('repayments against other entries are ignored', () {
      final repayments = [
        _rp(id: 'r1', loanId: 'l1', amount: 1000),
        _rp(id: 'r2', loanId: 'other', amount: 4000),
      ];
      expect(loanOutstanding(loan, repayments), 4000);
    });

    test('over-repayment clamps at zero rather than going negative', () {
      final repayments = [_rp(id: 'r1', loanId: 'l1', amount: 6000)];
      expect(loanOutstanding(loan, repayments), 0);
      expect(isLoanSettled(loan, repayments), isTrue);
    });
  });

  group('isValidRepaymentInput (repayment guard)', () {
    test('rejects a zero, negative or missing amount', () {
      expect(isValidRepaymentInput(amount: 0, date: '2026-07-01', outstanding: 500),
          isFalse);
      expect(isValidRepaymentInput(amount: -1, date: '2026-07-01', outstanding: 500),
          isFalse);
      expect(isValidRepaymentInput(amount: null, date: '2026-07-01', outstanding: 500),
          isFalse);
    });

    test('rejects a missing date', () {
      expect(
        isValidRepaymentInput(amount: 100, date: null, outstanding: 500),
        isFalse,
      );
    });

    test('rejects more than is still outstanding', () {
      expect(
        isValidRepaymentInput(amount: 501, date: '2026-07-01', outstanding: 500),
        isFalse,
      );
    });

    test('accepts a repayment for exactly the outstanding amount', () {
      expect(
        isValidRepaymentInput(amount: 500, date: '2026-07-01', outstanding: 500),
        isTrue,
      );
    });
  });

  group('buildLoanSummaries (lent vs borrowed sections)', () {
    final loans = [
      _loan(id: 'l1', direction: loanLent, person: 'Rafi', amount: 5000, date: '2026-06-01'),
      _loan(id: 'l2', direction: loanLent, person: 'Nabil', amount: 2000, date: '2026-05-01', dueDate: '2026-09-01'),
      _loan(id: 'l3', direction: loanLent, person: 'Sadia', amount: 1000, date: '2026-04-01', dueDate: '2026-07-15'),
      _loan(id: 'l4', direction: loanBorrowed, person: 'Bank', amount: 20000, date: '2026-03-01'),
    ];
    final repayments = [_rp(id: 'r1', loanId: 'l3', amount: 1000)];

    test('filters strictly by direction', () {
      final lent = buildLoanSummaries(loans, repayments, direction: loanLent);
      final borrowed = buildLoanSummaries(loans, repayments, direction: loanBorrowed);

      expect(lent.map((s) => s.loan.id), containsAll(['l1', 'l2', 'l3']));
      expect(lent.map((s) => s.loan.id), isNot(contains('l4')));
      expect(borrowed.map((s) => s.loan.id), ['l4']);
    });

    test('active entries lead, soonest due date first, undated after them, settled last', () {
      final lent = buildLoanSummaries(loans, repayments, direction: loanLent);
      // l3 is fully repaid, so it drops to the end despite the earliest due date.
      expect(lent.map((s) => s.loan.id), ['l2', 'l1', 'l3']);
    });

    test('each summary carries its own repaid, outstanding and settled state', () {
      final lent = buildLoanSummaries(loans, repayments, direction: loanLent);
      final settled = lent.firstWhere((s) => s.loan.id == 'l3');
      final open = lent.firstWhere((s) => s.loan.id == 'l1');

      expect(settled.repaid, 1000);
      expect(settled.outstanding, 0);
      expect(settled.settled, isTrue);
      expect(settled.progress, 1);

      expect(open.repaid, 0);
      expect(open.outstanding, 5000);
      expect(open.settled, isFalse);
      expect(open.progress, 0);
    });

    test('totalOutstanding counts only what is still owed', () {
      final lent = buildLoanSummaries(loans, repayments, direction: loanLent);
      expect(totalOutstanding(lent), 7000); // 5000 + 2000, settled l3 contributes 0
    });

    test('no entries means no summaries', () {
      expect(buildLoanSummaries([], [], direction: loanLent), isEmpty);
    });
  });

  group('LoanSummary.isOverdue (due-date state)', () {
    final today = DateTime(2026, 8, 9);

    test('past its due date with money still owed is overdue', () {
      final loan = _loan(
          id: 'l1', direction: loanLent, person: 'Rafi', amount: 5000, dueDate: '2026-08-01');
      expect(buildLoanSummary(loan, []).isOverdue(today), isTrue);
    });

    test('past its due date but settled is not overdue', () {
      final loan = _loan(
          id: 'l1', direction: loanLent, person: 'Rafi', amount: 5000, dueDate: '2026-08-01');
      final repayments = [_rp(id: 'r1', loanId: 'l1', amount: 5000)];
      expect(buildLoanSummary(loan, repayments).isOverdue(today), isFalse);
    });

    test('an entry with no due date is never overdue', () {
      final loan = _loan(id: 'l1', direction: loanLent, person: 'Rafi', amount: 5000);
      expect(buildLoanSummary(loan, []).isOverdue(today), isFalse);
    });

    test('due today is not yet overdue', () {
      final loan = _loan(
          id: 'l1', direction: loanLent, person: 'Rafi', amount: 5000, dueDate: '2026-08-09');
      expect(buildLoanSummary(loan, []).isOverdue(today), isFalse);
    });
  });

  group('repaymentIdsForLoan (what deleting an entry removes)', () {
    final repayments = [
      _rp(id: 'r1', loanId: 'l1', amount: 500),
      _rp(id: 'r2', loanId: 'l2', amount: 500),
      _rp(id: 'r3', loanId: 'l1', amount: 500),
    ];

    test('returns only the repayments belonging to that entry', () {
      expect(repaymentIdsForLoan(repayments, 'l1'), ['r1', 'r3']);
    });

    test('an entry with no repayments cascades to nothing', () {
      expect(repaymentIdsForLoan(repayments, 'l9'), isEmpty);
    });
  });

  group('isValidLoanInput (lending/borrowing form validation)', () {
    test('rejects a blank person name', () {
      expect(
        isValidLoanInput(personName: '  ', amount: 500, date: '2026-06-01', dueDate: ''),
        isFalse,
      );
    });

    test('rejects a zero or negative amount', () {
      expect(
        isValidLoanInput(personName: 'Rafi', amount: 0, date: '2026-06-01', dueDate: ''),
        isFalse,
      );
      expect(
        isValidLoanInput(personName: 'Rafi', amount: -5, date: '2026-06-01', dueDate: ''),
        isFalse,
      );
    });

    test('rejects a due date earlier than the entry date', () {
      expect(
        isValidLoanInput(
            personName: 'Rafi', amount: 500, date: '2026-06-01', dueDate: '2026-05-31'),
        isFalse,
      );
    });

    test('accepts an empty due date, or one on or after the entry date', () {
      expect(
        isValidLoanInput(personName: 'Rafi', amount: 500, date: '2026-06-01', dueDate: ''),
        isTrue,
      );
      expect(
        isValidLoanInput(
            personName: 'Rafi', amount: 500, date: '2026-06-01', dueDate: '2026-06-01'),
        isTrue,
      );
    });
  });

  group('calculateWealthTotals (net worth)', () {
    final assets = [
      _asset(id: 'a1', name: 'Wallet', amount: 3000),
      _asset(id: 'a2', name: 'City Bank', amount: 125000, kind: 'bank'),
    ];
    final investments = [
      _investment(id: 'i1', name: 'DSE fund', invested: 100000, current: 130000),
    ];
    final loans = [
      _loan(id: 'l1', direction: loanLent, person: 'Rafi', amount: 5000),
      _loan(id: 'l2', direction: loanBorrowed, person: 'Bank', amount: 20000),
    ];

    test('adds assets, investment value and money lent, then subtracts money owed', () {
      final totals = calculateWealthTotals(
        assets: assets,
        investments: investments,
        loans: loans,
        repayments: [],
      );

      expect(totals.assets, 128000);
      expect(totals.investmentValue, 130000);
      expect(totals.lentOutstanding, 5000);
      expect(totals.borrowedOutstanding, 20000);
      expect(totals.netWorth, 243000); // 128000 + 130000 + 5000 - 20000
    });

    test('investments count at current value, not what they cost', () {
      final totals = calculateWealthTotals(
        assets: [],
        investments: investments,
        loans: [],
        repayments: [],
      );

      expect(totals.investedCost, 100000);
      expect(totals.netWorth, 130000);
    });

    test('a settled entry contributes nothing on either side', () {
      final repayments = [
        _rp(id: 'r1', loanId: 'l1', amount: 5000),
        _rp(id: 'r2', loanId: 'l2', amount: 20000),
      ];
      final totals = calculateWealthTotals(
        assets: assets,
        investments: [],
        loans: loans,
        repayments: repayments,
      );

      expect(totals.lentOutstanding, 0);
      expect(totals.borrowedOutstanding, 0);
      expect(totals.netWorth, 128000);
    });

    test('owing more than you hold gives a negative net worth', () {
      final totals = calculateWealthTotals(
        assets: [_asset(id: 'a1', name: 'Wallet', amount: 1000)],
        investments: [],
        loans: [_loan(id: 'l2', direction: loanBorrowed, person: 'Bank', amount: 20000)],
        repayments: [],
      );

      expect(totals.netWorth, -19000);
    });

    test('a brand-new install has a zero net worth', () {
      final totals = calculateWealthTotals(
        assets: [],
        investments: [],
        loans: [],
        repayments: [],
      );

      expect(totals.netWorth, 0);
    });
  });

  group('calculateBalance (unchanged by wealth)', () {
    test('still nets income against expense over transactions alone', () {
      final transactions = [
        _tx(id: '1', type: 'income', categoryId: 'salary', amount: 50000, date: '2026-08-01'),
        _tx(id: '2', type: 'expense', categoryId: 'food', amount: 12000, date: '2026-08-02'),
      ];
      // Wealth entries exist in their own boxes and cannot reach this function.
      expect(calculateBalance(transactions), 38000);
    });
  });
}
