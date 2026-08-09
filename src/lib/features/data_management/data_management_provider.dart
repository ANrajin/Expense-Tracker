import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../data/models/transaction.dart';
import '../transactions/transactions_provider.dart';

/// What a pending deletion covers: one month, one full year, or all history.
class DeletionScope {
  const DeletionScope._({this.year, this.month});

  const DeletionScope.month(int year, int month) : this._(year: year, month: month);

  const DeletionScope.year(int year) : this._(year: year);

  const DeletionScope.allHistory() : this._();

  final int? year;
  final int? month;

  /// The exact wording the confirmation dialog states as the delete scope.
  String get label {
    if (year == null) return 'all history';
    if (month == null) return '$year';
    return monthLabel(year!, month!);
  }

  bool covers(Transaction transaction) {
    if (year == null) return true;
    final d = transaction.dateTime;
    if (d.year != year) return false;
    return month == null || d.month == month;
  }
}

/// One month that holds at least one transaction.
class MonthPeriod {
  const MonthPeriod({
    required this.year,
    required this.month,
    required this.count,
  });

  final int year;
  final int month;
  final int count;

  String get label => monthLabel(year, month);

  DeletionScope get scope => DeletionScope.month(year, month);
}

/// One year that holds at least one transaction, plus its populated months.
class YearPeriod {
  const YearPeriod({
    required this.year,
    required this.months,
    required this.count,
  });

  final int year;
  final List<MonthPeriod> months;
  final int count;

  String get label => '$year';

  DeletionScope get scope => DeletionScope.year(year);
}

/// Groups [transactions] into years, and the months within each year, that
/// contain at least one transaction — newest first. Empty periods are never
/// produced, which is how their delete action stays unavailable.
List<YearPeriod> buildDeletionPeriods(List<Transaction> transactions) {
  final counts = <int, Map<int, int>>{};
  for (final t in transactions) {
    final d = t.dateTime;
    final byMonth = counts.putIfAbsent(d.year, () => <int, int>{});
    byMonth[d.month] = (byMonth[d.month] ?? 0) + 1;
  }

  final years = counts.keys.toList()..sort((a, b) => b.compareTo(a));
  final periods = <YearPeriod>[];
  for (final year in years) {
    final byMonth = counts[year]!;
    final months = byMonth.keys.toList()..sort((a, b) => b.compareTo(a));
    periods.add(YearPeriod(
      year: year,
      months: [
        for (final month in months)
          MonthPeriod(year: year, month: month, count: byMonth[month]!),
      ],
      count: byMonth.values.fold(0, (sum, c) => sum + c),
    ));
  }
  return periods;
}

/// Ids of the transactions inside [scope] — the exact set a confirmed delete
/// removes, and the count the confirmation dialog states.
List<String> transactionIdsInScope(
  List<Transaction> transactions,
  DeletionScope scope,
) {
  return [
    for (final t in transactions)
      if (scope.covers(t)) t.id,
  ];
}

/// Type-to-confirm safeguard: the delete action only enables on an exact
/// "DELETE" match (surrounding whitespace ignored).
bool isDeleteConfirmed(String input) => input.trim() == 'DELETE';

final deletionPeriodsProvider = Provider<List<YearPeriod>>((ref) {
  return buildDeletionPeriods(ref.watch(transactionsProvider));
});

final transactionCountProvider = Provider<int>((ref) {
  return ref.watch(transactionsProvider).length;
});
