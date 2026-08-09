import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/format.dart';
import '../../data/models/investment.dart';
import '../../data/repositories/investment_repository.dart';

/// The investment types the form offers, in the order it offers them.
const investmentTypes = <String>[
  'stock',
  'dps',
  'fdr',
  'gold',
  'crypto',
  'other',
];

String investmentTypeLabel(String type) {
  return switch (type) {
    'stock' => 'Stock',
    'dps' => 'DPS',
    'fdr' => 'FDR',
    'gold' => 'Gold',
    'crypto' => 'Crypto',
    _ => 'Other',
  };
}

/// How an investment has moved since it was bought.
class GainLoss {
  const GainLoss({required this.amount, required this.percent});

  /// Current value minus amount invested — negative on a loss.
  final double amount;

  /// [amount] as a share of the amount invested, or null when there is no
  /// meaningful base to measure against (nothing invested). Kept nullable as a
  /// guard so a zero base can never surface as Infinity or NaN, even though the
  /// form requires a positive amount invested.
  final double? percent;

  bool get isGain => amount > 0;
  bool get isLoss => amount < 0;
}

GainLoss calculateGainLoss({
  required double investedAmount,
  required double currentValue,
}) {
  final amount = currentValue - investedAmount;
  return GainLoss(
    amount: amount,
    percent: investedAmount > 0 ? amount / investedAmount * 100 : null,
  );
}

GainLoss investmentGainLoss(Investment investment) {
  return calculateGainLoss(
    investedAmount: investment.investedAmount,
    currentValue: investment.currentValue,
  );
}

/// Spec's save requirement for an investment: a non-blank name, a positive
/// amount invested (it is the base the gain/loss percentage is measured
/// against), a current value of zero or more, and a date.
bool isValidInvestmentInput({
  required String name,
  required double? investedAmount,
  required double? currentValue,
  required String? date,
}) {
  return name.trim().isNotEmpty &&
      (investedAmount ?? 0) > 0 &&
      (currentValue ?? -1) >= 0 &&
      date != null;
}

/// Newest investment first, tie-broken by id like the transaction listings, so
/// the order doesn't depend on the key order `Box.values` iterates in.
List<Investment> sortedInvestments(List<Investment> investments) {
  final sorted = [...investments];
  sorted.sort((a, b) {
    final byDate = b.date.compareTo(a.date);
    if (byDate != 0) return byDate;
    return b.id.compareTo(a.id);
  });
  return sorted;
}

double totalInvested(List<Investment> investments) {
  var total = 0.0;
  for (final i in investments) {
    total += i.investedAmount;
  }
  return total;
}

double totalInvestmentValue(List<Investment> investments) {
  var total = 0.0;
  for (final i in investments) {
    total += i.currentValue;
  }
  return total;
}

GainLoss overallInvestmentGainLoss(List<Investment> investments) {
  return calculateGainLoss(
    investedAmount: totalInvested(investments),
    currentValue: totalInvestmentValue(investments),
  );
}

final investmentBoxProvider = Provider<Box<Investment>>((ref) {
  return Hive.box<Investment>(InvestmentRepository.boxName);
});

final investmentRepositoryProvider = Provider<InvestmentRepository>((ref) {
  return InvestmentRepository(ref.watch(investmentBoxProvider));
});

final investmentsProvider =
    StateNotifierProvider<InvestmentsNotifier, List<Investment>>((ref) {
  return InvestmentsNotifier(ref.watch(investmentRepositoryProvider));
});

final sortedInvestmentsProvider = Provider<List<Investment>>((ref) {
  return sortedInvestments(ref.watch(investmentsProvider));
});

final totalInvestmentValueProvider = Provider<double>((ref) {
  return totalInvestmentValue(ref.watch(investmentsProvider));
});

final totalInvestedProvider = Provider<double>((ref) {
  return totalInvested(ref.watch(investmentsProvider));
});

final overallGainLossProvider = Provider<GainLoss>((ref) {
  return overallInvestmentGainLoss(ref.watch(investmentsProvider));
});

class InvestmentsNotifier extends StateNotifier<List<Investment>> {
  InvestmentsNotifier(this._repo) : super(_repo.getAll());

  final InvestmentRepository _repo;
  int _seq = 0;

  Future<bool> addInvestment({
    required String name,
    required String type,
    required double investedAmount,
    required double currentValue,
    required String? date,
    String note = '',
  }) async {
    if (!isValidInvestmentInput(
      name: name,
      investedAmount: investedAmount,
      currentValue: currentValue,
      date: date,
    )) {
      return false;
    }
    final investment = Investment(
      id: 'inv${DateTime.now().millisecondsSinceEpoch}_${_seq++}',
      name: name.trim(),
      type: type,
      investedAmount: investedAmount,
      currentValue: currentValue,
      date: date!,
      valuedDate: toIsoDate(DateTime.now()),
      note: note,
    );
    await _repo.add(investment);
    state = _repo.getAll();
    return true;
  }

  /// [valuedDate] moves only when the current value actually changes, so the
  /// "valued on" line keeps meaning "when the user last re-valued this".
  Future<bool> updateInvestment(
    String id, {
    required String name,
    required String type,
    required double investedAmount,
    required double currentValue,
    required String? date,
    String note = '',
  }) async {
    if (!isValidInvestmentInput(
      name: name,
      investedAmount: investedAmount,
      currentValue: currentValue,
      date: date,
    )) {
      return false;
    }
    final existing = state.firstWhere((i) => i.id == id);
    final revalued = existing.currentValue != currentValue;
    existing
      ..name = name.trim()
      ..type = type
      ..investedAmount = investedAmount
      ..currentValue = currentValue
      ..date = date!
      ..note = note;
    if (revalued) existing.valuedDate = toIsoDate(DateTime.now());
    await _repo.update(existing);
    state = _repo.getAll();
    return true;
  }

  Future<void> deleteInvestment(String id) async {
    await _repo.delete(id);
    state = _repo.getAll();
  }
}
