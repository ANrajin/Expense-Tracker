// Feature-level tests: balance calculation, month filtering (History),
// the category delete guard, and transaction form validation. These are
// plain-Dart tests against the pure functions each provider wraps, so no
// Hive or ProviderContainer setup is needed.

import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/data/models/transaction.dart';
import 'package:expense_tracker/features/categories/categories_provider.dart';
import 'package:expense_tracker/features/dashboard/dashboard_provider.dart';
import 'package:expense_tracker/features/transactions/history_provider.dart';
import 'package:expense_tracker/features/transactions/transactions_provider.dart';

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
}
