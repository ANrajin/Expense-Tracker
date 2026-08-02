import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/transaction.dart';
import 'transactions_provider.dart';

class YearMonth {
  const YearMonth(this.year, this.month);

  final int year;
  final int month;

  YearMonth shift(int delta) {
    var y = year, m = month + delta;
    while (m < 1) {
      m += 12;
      y--;
    }
    while (m > 12) {
      m -= 12;
      y++;
    }
    return YearMonth(y, m);
  }

  @override
  bool operator ==(Object other) =>
      other is YearMonth && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);
}

final historyMonthProvider = StateProvider<YearMonth>((ref) {
  final now = DateTime.now();
  return YearMonth(now.year, now.month);
});

class HistoryDayGroup {
  const HistoryDayGroup({required this.date, required this.transactions});

  final DateTime date;
  final List<Transaction> transactions;
}

/// Filters [transactions] to [ym] and groups same-day entries together,
/// newest day first.
List<HistoryDayGroup> groupHistoryByDay(
  List<Transaction> transactions,
  YearMonth ym,
) {
  final txs = transactions
      .where((t) {
        final d = t.dateTime;
        return d.year == ym.year && d.month == ym.month;
      })
      .toList()
    ..sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      if (byDate != 0) return byDate;
      return b.id.compareTo(a.id);
    });

  final groups = <HistoryDayGroup>[];
  for (final t in txs) {
    final d = t.dateTime;
    if (groups.isNotEmpty &&
        groups.last.date.year == d.year &&
        groups.last.date.month == d.month &&
        groups.last.date.day == d.day) {
      groups.last.transactions.add(t);
    } else {
      groups.add(HistoryDayGroup(date: d, transactions: [t]));
    }
  }
  return groups;
}

final historyGroupsProvider = Provider<List<HistoryDayGroup>>((ref) {
  final ym = ref.watch(historyMonthProvider);
  return groupHistoryByDay(ref.watch(transactionsProvider), ym);
});
