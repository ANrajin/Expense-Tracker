import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../categories/categories_provider.dart';
import '../transactions/history_provider.dart';
import '../transactions/transactions_provider.dart';

final reportMonthProvider = StateProvider<YearMonth>((ref) {
  final now = DateTime.now();
  return YearMonth(now.year, now.month);
});

class ReportTotals {
  const ReportTotals({required this.income, required this.expense});

  final double income;
  final double expense;

  double get net => income - expense;
}

final reportTotalsProvider = Provider<ReportTotals>((ref) {
  final ym = ref.watch(reportMonthProvider);
  final txs = ref.watch(transactionsProvider);
  var income = 0.0, expense = 0.0;
  for (final t in txs) {
    final d = t.dateTime;
    if (d.year == ym.year && d.month == ym.month) {
      if (t.isIncome) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }
  }
  return ReportTotals(income: income, expense: expense);
});

class CategoryBreakdown {
  const CategoryBreakdown({
    required this.name,
    required this.amount,
    required this.fraction,
  });

  final String name;
  final double amount;
  final double fraction;

  String get percentLabel => '${(fraction * 100).round()}%';
}

String _categoryName(List categories, String id) {
  for (final c in categories) {
    if (c.id == id) return c.name as String;
  }
  return 'Other';
}

final expenseBreakdownProvider = Provider<List<CategoryBreakdown>>((ref) {
  final ym = ref.watch(reportMonthProvider);
  final txs = ref.watch(transactionsProvider);
  final categories = ref.watch(categoriesProvider);

  final byCategory = <String, double>{};
  var total = 0.0;
  for (final t in txs) {
    final d = t.dateTime;
    if (d.year == ym.year && d.month == ym.month && t.isExpense) {
      byCategory[t.categoryId] = (byCategory[t.categoryId] ?? 0) + t.amount;
      total += t.amount;
    }
  }

  final entries = byCategory.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return [
    for (final e in entries)
      CategoryBreakdown(
        name: _categoryName(categories, e.key),
        amount: e.value,
        fraction: total > 0 ? e.value / total : 0,
      ),
  ];
});

class TrendMonth {
  const TrendMonth({
    required this.label,
    required this.income,
    required this.expense,
  });

  final String label;
  final double income;
  final double expense;
}

/// The 6 months ending at the selected report month.
final trendProvider = Provider<List<TrendMonth>>((ref) {
  final ym = ref.watch(reportMonthProvider);
  final txs = ref.watch(transactionsProvider);

  final months = <TrendMonth>[];
  for (var i = 5; i >= 0; i--) {
    var mm = ym.month - i, yy = ym.year;
    while (mm < 1) {
      mm += 12;
      yy--;
    }
    var income = 0.0, expense = 0.0;
    for (final t in txs) {
      final d = t.dateTime;
      if (d.year == yy && d.month == mm) {
        if (t.isIncome) {
          income += t.amount;
        } else {
          expense += t.amount;
        }
      }
    }
    months.add(TrendMonth(
      label: shortMonthLabel(yy, mm),
      income: income,
      expense: expense,
    ));
  }
  return months;
});
