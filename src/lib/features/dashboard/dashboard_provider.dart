import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/transaction.dart';
import '../transactions/transactions_provider.dart';

class MonthSummary {
  const MonthSummary({required this.income, required this.expense});

  final double income;
  final double expense;
}

double calculateBalance(List<Transaction> transactions) {
  var balance = 0.0;
  for (final t in transactions) {
    balance += t.isIncome ? t.amount : -t.amount;
  }
  return balance;
}

MonthSummary calculateMonthSummary(List<Transaction> transactions, DateTime month) {
  var income = 0.0, expense = 0.0;
  for (final t in transactions) {
    final d = t.dateTime;
    if (d.year == month.year && d.month == month.month) {
      if (t.isIncome) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }
  }
  return MonthSummary(income: income, expense: expense);
}

/// The [limit] most recent transactions, newest first.
List<Transaction> selectRecentTransactions(
  List<Transaction> transactions, {
  int limit = 5,
}) {
  final sorted = [...transactions];
  sorted.sort((a, b) {
    final byDate = b.date.compareTo(a.date);
    if (byDate != 0) return byDate;
    return b.id.compareTo(a.id);
  });
  return sorted.take(limit).toList();
}

final balanceProvider = Provider<double>((ref) {
  return calculateBalance(ref.watch(transactionsProvider));
});

final monthSummaryProvider = Provider<MonthSummary>((ref) {
  return calculateMonthSummary(ref.watch(transactionsProvider), DateTime.now());
});

final recentTransactionsProvider = Provider<List<Transaction>>((ref) {
  return selectRecentTransactions(ref.watch(transactionsProvider));
});
