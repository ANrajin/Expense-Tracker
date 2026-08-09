import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/models/loan.dart';
import '../../data/models/repayment.dart';
import '../../data/repositories/loan_repository.dart';
import '../../data/repositories/repayment_repository.dart';

/// Money owed to the user.
const loanLent = 'lent';

/// Money the user owes.
const loanBorrowed = 'borrowed';

/// Sub-paisa tolerance for "fully repaid". Repayments are doubles, so a loan of
/// 1000 settled as 333.33 + 333.33 + 333.34 leaves a residue far below one
/// paisa rather than landing exactly on zero. Without this an entry could look
/// permanently unsettled by a rounding artefact the user cannot see or fix.
const _settledEpsilon = 0.005;

/// Spec's save requirement for a lending/borrowing entry: a non-blank person,
/// a positive amount, a date, and — when given — a due date that isn't before
/// the entry's own date. ISO yyyy-MM-dd compares correctly as a string.
bool isValidLoanInput({
  required String personName,
  required double? amount,
  required String? date,
  required String dueDate,
}) {
  if (personName.trim().isEmpty) return false;
  if ((amount ?? 0) <= 0) return false;
  if (date == null) return false;
  if (dueDate.isNotEmpty && dueDate.compareTo(date) < 0) return false;
  return true;
}

/// Spec's save requirement for a repayment: a positive amount that doesn't
/// exceed what is still outstanding, and a date.
bool isValidRepaymentInput({
  required double? amount,
  required String? date,
  required double outstanding,
}) {
  final value = amount ?? 0;
  return value > 0 && date != null && value <= outstanding + _settledEpsilon;
}

/// The repayments logged against [loanId], newest first.
List<Repayment> repaymentsForLoan(List<Repayment> repayments, String loanId) {
  final mine = [
    for (final r in repayments)
      if (r.loanId == loanId) r,
  ];
  mine.sort((a, b) {
    final byDate = b.date.compareTo(a.date);
    if (byDate != 0) return byDate;
    return b.id.compareTo(a.id);
  });
  return mine;
}

/// Ids of every repayment belonging to [loanId] — the exact set the cascade
/// removes when that loan is deleted.
List<String> repaymentIdsForLoan(List<Repayment> repayments, String loanId) {
  return [
    for (final r in repayments)
      if (r.loanId == loanId) r.id,
  ];
}

double totalRepaid(List<Repayment> repayments, String loanId) {
  var total = 0.0;
  for (final r in repayments) {
    if (r.loanId == loanId) total += r.amount;
  }
  return total;
}

/// What is still owed, never negative — over-repayment reads as fully settled
/// rather than as a negative balance that would inflate net worth.
double loanOutstanding(Loan loan, List<Repayment> repayments) {
  final remaining = loan.amount - totalRepaid(repayments, loan.id);
  return remaining > 0 ? remaining : 0;
}

/// Settled is derived, never stored, so it cannot drift when a repayment is
/// edited or deleted.
bool isLoanSettled(Loan loan, List<Repayment> repayments) {
  return loanOutstanding(loan, repayments) < _settledEpsilon;
}

/// A loan with its repayment state resolved — what the list rows and the detail
/// screen both render.
class LoanSummary {
  const LoanSummary({
    required this.loan,
    required this.repaid,
    required this.outstanding,
    required this.settled,
  });

  final Loan loan;
  final double repaid;
  final double outstanding;
  final bool settled;

  /// Share of the original amount repaid so far, 0..1.
  double get progress {
    if (loan.amount <= 0) return 0;
    final value = repaid / loan.amount;
    return value > 1 ? 1 : value;
  }

  /// Past its due date with money still owed. Compared date-only, so an entry
  /// due today is not yet overdue.
  bool isOverdue(DateTime today) {
    final due = loan.dueDateTime;
    if (due == null || settled) return false;
    return due.isBefore(DateTime(today.year, today.month, today.day));
  }
}

LoanSummary buildLoanSummary(Loan loan, List<Repayment> repayments) {
  final outstanding = loanOutstanding(loan, repayments);
  return LoanSummary(
    loan: loan,
    repaid: totalRepaid(repayments, loan.id),
    outstanding: outstanding,
    settled: outstanding < _settledEpsilon,
  );
}

/// Every entry in [direction], active ones first (soonest due date leading, and
/// entries with no due date after those), then settled ones — which the spec
/// keeps visible but listed separately. Newest first within each rank.
List<LoanSummary> buildLoanSummaries(
  List<Loan> loans,
  List<Repayment> repayments, {
  required String direction,
}) {
  final summaries = [
    for (final loan in loans)
      if (loan.direction == direction) buildLoanSummary(loan, repayments),
  ];
  summaries.sort((a, b) {
    if (a.settled != b.settled) return a.settled ? 1 : -1;
    if (!a.settled) {
      final aDue = a.loan.dueDate, bDue = b.loan.dueDate;
      if (aDue.isEmpty != bDue.isEmpty) return aDue.isEmpty ? 1 : -1;
      if (aDue.isNotEmpty) {
        final byDue = aDue.compareTo(bDue);
        if (byDue != 0) return byDue;
      }
    }
    final byDate = b.loan.date.compareTo(a.loan.date);
    if (byDate != 0) return byDate;
    return b.loan.id.compareTo(a.loan.id);
  });
  return summaries;
}

double totalOutstanding(List<LoanSummary> summaries) {
  var total = 0.0;
  for (final s in summaries) {
    total += s.outstanding;
  }
  return total;
}

final loanBoxProvider = Provider<Box<Loan>>((ref) {
  return Hive.box<Loan>(LoanRepository.boxName);
});

final loanRepositoryProvider = Provider<LoanRepository>((ref) {
  return LoanRepository(ref.watch(loanBoxProvider));
});

final loansProvider = StateNotifierProvider<LoansNotifier, List<Loan>>((ref) {
  return LoansNotifier(ref.watch(loanRepositoryProvider));
});

final repaymentBoxProvider = Provider<Box<Repayment>>((ref) {
  return Hive.box<Repayment>(RepaymentRepository.boxName);
});

final repaymentRepositoryProvider = Provider<RepaymentRepository>((ref) {
  return RepaymentRepository(ref.watch(repaymentBoxProvider));
});

final repaymentsProvider =
    StateNotifierProvider<RepaymentsNotifier, List<Repayment>>((ref) {
  return RepaymentsNotifier(ref.watch(repaymentRepositoryProvider));
});

/// Watching both boxes is what makes logging a repayment re-rank the list and
/// move the net worth figure without any manual refresh.
final lentSummariesProvider = Provider<List<LoanSummary>>((ref) {
  return buildLoanSummaries(
    ref.watch(loansProvider),
    ref.watch(repaymentsProvider),
    direction: loanLent,
  );
});

final borrowedSummariesProvider = Provider<List<LoanSummary>>((ref) {
  return buildLoanSummaries(
    ref.watch(loansProvider),
    ref.watch(repaymentsProvider),
    direction: loanBorrowed,
  );
});

/// Null once the loan has been deleted — the detail screen watches this so it
/// can pop instead of rebuilding against a missing record.
final loanSummaryProvider = Provider.family<LoanSummary?, String>((ref, id) {
  final loans = ref.watch(loansProvider);
  final index = loans.indexWhere((l) => l.id == id);
  if (index == -1) return null;
  return buildLoanSummary(loans[index], ref.watch(repaymentsProvider));
});

final repaymentsForLoanProvider =
    Provider.family<List<Repayment>, String>((ref, id) {
  return repaymentsForLoan(ref.watch(repaymentsProvider), id);
});

class LoansNotifier extends StateNotifier<List<Loan>> {
  LoansNotifier(this._repo) : super(_repo.getAll());

  final LoanRepository _repo;
  int _seq = 0;

  Future<bool> addLoan({
    required String direction,
    required String personName,
    required double amount,
    required String? date,
    String dueDate = '',
    String note = '',
  }) async {
    if (!isValidLoanInput(
      personName: personName,
      amount: amount,
      date: date,
      dueDate: dueDate,
    )) {
      return false;
    }
    final loan = Loan(
      id: 'ln${DateTime.now().millisecondsSinceEpoch}_${_seq++}',
      direction: direction,
      personName: personName.trim(),
      amount: amount,
      date: date!,
      dueDate: dueDate,
      note: note,
    );
    await _repo.add(loan);
    state = _repo.getAll();
    return true;
  }

  Future<bool> updateLoan(
    String id, {
    required String personName,
    required double amount,
    required String? date,
    String dueDate = '',
    String note = '',
  }) async {
    if (!isValidLoanInput(
      personName: personName,
      amount: amount,
      date: date,
      dueDate: dueDate,
    )) {
      return false;
    }
    final existing = state.firstWhere((l) => l.id == id);
    existing
      ..personName = personName.trim()
      ..amount = amount
      ..date = date!
      ..dueDate = dueDate
      ..note = note;
    await _repo.update(existing);
    state = _repo.getAll();
    return true;
  }

  Future<void> deleteLoan(String id) async {
    await _repo.delete(id);
    state = _repo.getAll();
  }
}

class RepaymentsNotifier extends StateNotifier<List<Repayment>> {
  RepaymentsNotifier(this._repo) : super(_repo.getAll());

  final RepaymentRepository _repo;
  int _seq = 0;

  Future<bool> addRepayment({
    required String loanId,
    required double amount,
    required String? date,
    required double outstanding,
    String note = '',
  }) async {
    if (!isValidRepaymentInput(
      amount: amount,
      date: date,
      outstanding: outstanding,
    )) {
      return false;
    }
    final repayment = Repayment(
      id: 'rp${DateTime.now().millisecondsSinceEpoch}_${_seq++}',
      loanId: loanId,
      amount: amount,
      date: date!,
      note: note,
    );
    await _repo.add(repayment);
    state = _repo.getAll();
    return true;
  }

  /// Deleting a repayment raises the entry's outstanding amount again, and
  /// reopens it if it had settled — settled being derived is what makes that
  /// fall out for free.
  Future<void> deleteRepayment(String id) async {
    await _repo.delete(id);
    state = _repo.getAll();
  }

  /// The cascade behind deleting a loan.
  Future<void> deleteRepayments(Iterable<String> ids) async {
    if (ids.isEmpty) return;
    await _repo.deleteMany(ids);
    state = _repo.getAll();
  }
}
